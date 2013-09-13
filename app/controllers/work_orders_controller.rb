class WorkOrdersController < ApplicationController
  layout :with_sidebar

  protected
  before_filter :ensure_metadata
  def ensure_metadata
    @@rt_metadata ||= _parse_metadata_wo
    @rt_metadata = @@rt_metadata
  end
  public

  def index
    @work_orders = [OpenStruct.new]
  end

  def new
    if params[:open_struct]
      @work_order = OpenStruct.new(params[:open_struct])
      @work_order.issues = params[:open_struct][:issue].to_a.select{|x| x.first == x.last}.map{|x| x.first}
      parse_data
#      @work_order.issue = nil
    else
      @work_order = OpenStruct.new
      @work_order.errors = ActiveRecord::Errors.new(@work_order)
    end
    if params[:mode]
      @work_order.mode = params[:mode]
    end
  end

  def show(showid = nil)
    showid ||= params[:id]
    if showid
      json = `#{RAILS_ROOT}/script/fetch_ts_data.pl #{showid.to_i}`
      begin
        @data = JSON.parse(json)
      rescue
        @data = nil
      end
      if @data.nil? || @data["ID"].to_i != showid.to_i
        @data = nil
        @error = "The provided ticket number does not exist."
        return
      end
      if @data && @data["Queue"] != "TechSupport"
        @data = nil
        @error = "The provided ticket number does not reference a valid TechSupport ticket."
        return
      end
      if @data && @data["System ID"]
        @system = System.find_by_id(@data["System ID"].to_i)
      end
    end
  end


  def invoice
    show
    if params[:donation]
      @invoice = Donation.new(params[:donation])
      # TODO: apply line item data
      @invoice.gizmo_events.each do |ge|
        orig = ge.description
        ge.description = "Ticket ##{@data["ID"]}"
        ge.description += " - #{orig}" if orig.length > 0
      end
      @invoice.payments = [Payment.new(:payment_method => PaymentMethod.invoice, :amount_cents => @invoice.reported_required_fee_cents)]
      Thread.current['cashier'] = Thread.current['user'] # FIXME FIXME FIXME: PIN for updated_by
      @invoice.save!
    else
      service_charge = 10 # TODO: defaults
      service_charge = 0 if @data["Warranty"].match("In")
      @invoice = Donation.new(:contact_id => @data["Adopter ID"].to_i)
      @invoice.contact_type = 'anonymous' unless @invoice.contact
      @ts_fee_type = GizmoType.find_by_name("service_fee_tech_support")
      ge_base = {:gizmo_type_id => @ts_fee_type.id, :donation => @invoice, :gizmo_context_id => GizmoContext.donation, :gizmo_count => 1}
      #GizmoEvent.new(ge_base.merge({:description => ge_base[:description] + " - Parts", :unit_price_cents => 0}))
      #GizmoEvent.new(ge_base.merge({:description => ge_base[:description] + " - Service Charge", :unit_price_cents => service_charge * 100}))
      if service_charge > 0
        @invoice.gizmo_events << GizmoEvent.new(ge_base.merge({:description => "Service Charge", :unit_price_cents => service_charge * 100}))
      end
      # TODO: sum as invoice?
    end
  end

  def show_invoice
    @invoice = Donation.find_by_id(params[:id])
    @ts_fee_type = GizmoType.find_by_name("service_fee_tech_support")
    @invoice.gizmo_events.select{|x| x.gizmo_type == @ts_fee_type}.map{|x| x.description}.join(" ").match(/Ticket #([0-9]+)/)
    matchid = $1
    show(matchid) if matchid
    render :action => "invoice"
  end

  OS_OPTIONS = ['Linux', 'Mac', 'Windows']

  protected

  def parse_data
    @work_order = OpenStruct.new(params[:open_struct])
    if params[:mode]
      @work_order.mode = params[:mode]
    end
    @work_order.issues = params[:open_struct][:issue] if params[:open_struct] #.to_a.select{|x| x.first == x.last}.map{|x| x.first}
#    @work_order.issue = nil

    @errors = @work_order.errors = ActiveRecord::Errors.new(@work_order)
    @warnings = []

    phone_number = @work_order.phone_number = [@work_order.phone_number1, @work_order.phone_number2, @work_order.phone_number3].map{|x| x.to_s.strip}.select{|x| x.length > 0}.join("-")
    sale_date = @work_order.sale_date = [@work_order.sale_date1, @work_order.sale_date2].map{|x| x.to_s.strip}.select{|x| x.length > 0}.join("/")

    pull_system_info
    pull_warranty_info

    @data = {}
    @data["Issues"] = @work_order.issues #.join(", ")
    @data["Name"] = @work_order.customer_name || ""
    @data["Summary"] = @work_order.summary || ""
    @data["Subject"] = @data["Name"] + " - " + @data["Summary"]
    @errors.add("customer_name", "is mandatory information") if @data["Name"].to_s.length == 0
    @data["ID"] = " not yet created"
    @data["Ticket Source"] = @work_order.ticket_source
    @data["Phone"] = @work_order.phone_number
    @data["Email"] = @work_order.email
    if @data["Email"].to_s.length == 0 && phone_number.length == 0
      @errors.add("phone_number", "must be provided#{@work_order.mode == 'phone' ? "" : " if an email address is not"}")
      @errors.add("email", "must be provided if a phone number is not") unless @work_order.mode == 'phone'
    end
    @errors.add("phone_number", "must be a valid phone number in the form XXX-XXX-XXXX") if phone_number.length > 0 && !phone_number.match(/\d{3}-\d{3}-\d{4}/)
    @errors.add("email", "must be a valid email address in the form XXX@XXXX.XXX") if @data["Email"].to_s.length > 0 && !@data["Email"].to_s.match(/^.+@[^.]+\..+$/)
    @errors.add("ticket_source", "must be chosen") if @data["Ticket Source"].to_s.length == 0
    if @work_order.mode == 'ts'
      @data["Adopter Name"] = @work_order.adopter_name
      @data["OS"] = @work_order.os
      @data["Type of Box"] = @work_order.box_type
      @errors.add("box_type", "is mandatory information") if @data["Type of Box"].to_s.length == 0
      @errors.add("box_type", "is set to external, but external systems are only accepted for data backups prior to donation") if @data["Type of Box"] && @data["Issues"] && @data["Type of Box"] == "External" && @data["Issues"] != "Data Backup"
      @data["Box Source"] = @work_order.box_source
      @errors.add("box_source", "is mandatory information (unless you provide a system ID that allows it to be determined from past records)") if @work_order.box_type.to_s.match(/(Server|Desktop|Laptop)/) && @data["Box Source"].to_s.length == 0
      @data["Warranty"] = @work_order.warranty
      @data["Adopter ID"] = @work_order.adopter_id
      @data["System ID"] = @work_order.system_id
      @data["Transaction Date"] = @work_order.sale_date
      @errors.add("sale_date", "must be a valid month in the form MM/YYYY") if sale_date.length > 0 && !sale_date.match(/\d{2,}\/\d{4,}/)
      @data["Transaction ID"] = @work_order.sale_id
    end
    @data["Initial Content"] = @work_order.comment.to_s
    @errors.add("summary", "is mandatory") if @data["Summary"].to_s.length == 0
    @errors.add("comment", "in description is mandatory") if @data["Initial Content"].to_s.length == 0
    ic = []
    if !@work_order.additional_items.to_s.empty?
      ic << "Additional items left with tech support: " + @work_order.additional_items
    end
    ic = ic.join("\n")
    @data["Initial Content"] = ic + "\n\n" + @data["Initial Content"] if ic.length > 0
    tech_contact = current_user.shared ? User.find_by_cashier_code(@work_order.pin.to_i) : current_user
    @data["Technician ID"] = tech_contact.contact_id.to_s if tech_contact
    @errors.add("pin", "is required when logged in as a shared database user (#{current_user.login})") if tech_contact.nil?
#    if !(@contact = Contact.find_by_id(@work_order.receiver_contact_id.to_i))
#      @work_order.errors.add("receiver_contact_id", "doesn't exist.")
#    else
#      @data["Technician ID"] = @contact.id.to_s
#      if (!@contact.user) or (!(@contact.user.privileges.include?("techsupport_workorders") or @contact.user.grantable_roles.include?(Role.find_by_name('ADMIN'))))
#        @work_order.errors.add("receiver_contact_id", "doesn't have the tech support role.")
#      end
#    end
    @warnings << "Now would be a great time to remind the user we recycle unclaimed hardware after 45 days! Are you sure you do not want to provide a phone number?" if @data["Phone"].to_s.strip.length == 0
  end

  def pull_system_info
    if @work_order.system_id && @work_order.system_id.to_s.strip.length > 0
      @system = System.find_by_id(@work_order.system_id.to_i)
    else
      return
    end
      if @system
        if (ge = @system.last_gizmo_event)
          trans = ge.my_transaction
          @work_order.sale_id = trans.id.to_s
          @work_order.sale_date = ge.occurred_at.to_date.to_s
          if trans.contact
            @work_order.adopter_name = trans.contact.display_name
            @work_order.adopter_id = trans.contact_id.to_s
#            @work_order.phone_number = trans.contact.phone_number.to_s if @work_order.phone_number.to_s.strip.length == 0
#            @work_order.email = trans.contact.mailing_list_email.to_s if @work_order.email.to_s.strip.length == 0

          desc = ge.gizmo_type.description
          b_type = nil
          if desc.match(/Mac/)
            if desc.match(/Laptop/)
              b_type = "Mac Laptop"
            else
              b_type = "Mac"
            end
          elsif desc.match(/Laptop/)
            b_type = "Laptop"
          elsif desc.match(/Server/)
            b_type = "Server"
          elsif desc.match(/System/)
            b_type = "Desktop"
          end
            if b_type && @work_order.box_type && b_type != @work_order.box_type
              @warnings << "The selected gizmo type (#{@work_order.box_type}) does not match the type this gizmo went out as (#{desc})"
            end
          end
          source = trans.class == Sale ? "Store" : trans.disbursement_type.description
          @work_order.box_source = source
        end
    end
  end

  def pull_warranty_info
    date = nil
    unless @system and @system.last_gizmo_event
      @work_order.warranty = "TBD"
      return
    end
    if @work_order.sale_date && @work_order.sale_date.to_s.strip.length > 0
      date = @work_order.sale_date
      begin
        date = Date.parse(date)
      rescue
        date = nil
      end
    end
    unless date
      @work_order.warranty = "TBD"
      return
    end
    b_type = @work_order.box_type
    source = @work_order.box_source
    os = @work_order.os
    wl = WarrantyLength.find_warranty_for(date, b_type, source, os)
    if wl && wl.eval_length
      ret = wl.is_in_warranty(date)
      @work_order.warranty = (ret ? "In Warranty" : "Out of Warranty" )
    else
      @work_order.warranty = "TBD"
    end
  end

  public
  def create
    parse_data
    if params[:mode]
      @work_order.mode = params[:mode]
    end
    @data = nil if @work_order.errors.length > 0
#    if @work_order.save
#      flash[:notice] = 'OpenStruct was successfully created.'
#      redirect_to({:action => "show", :id => @work_order.id})
#    else
#      render :action => "new"
#    end
  end

  def submit
    parse_data

    unless @error

    @data["Requestor"] = @data["Email"].to_s

    tempfile = `mktemp -p #{File.join(RAILS_ROOT, "tmp", "tmp")}`.chomp 
    f = File.open(tempfile, 'w+')
    json = @data.to_json
    f.write(json)
    f.close

    t_id = `#{RAILS_ROOT}/script/create_work_order.pl #{tempfile} 2>&1`
    File.delete(tempfile)
    t_id.gsub!(/Use of uninitialized value .+ line \d+./, "")
    if t_id.to_i != 0
      redirect_to :action => :show, :id => t_id.strip
    else
      redirect_to :action => :show, :error => t_id
    end
    end
  end

  def update
    @work_order = OpenStruct.new

    if @work_order.update_attributes(params[:open_struct])
      flash[:notice] = 'OpenStruct was successfully updated.'
      redirect_to({:action => "show", :id => @work_order.id})
    else
      render :action => "edit"
    end
  end

  def destroy
    @work_order = OpenStruct.new
    @work_order.destroy

    redirect_to({:action => "index"})
  end
end
