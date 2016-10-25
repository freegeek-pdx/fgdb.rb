require 'prawn'

class TransactionController < ApplicationController
  layout :check_for_receipt

  helper :raw_receipt

  before_filter :set_defaults
  before_filter :be_a_thing

  include RawReceiptHelper

  def raw_receipt
    printer = (params[:receipt] ? params[:receipt][:printer] : "")
    render :update do |page|
      raise unless params[:controller] == 'sales'
      s = Sale.find_by_id(params[:id])
      receipt_printer_set_default(printer)
      handle_java_print(page, generate_raw_receipt(printer) {|limit| s.text_receipt_lines(limit)}, {:alert => s.storecredit_alert_text, :loading => "raw_receipt_loading_indicator_id"})
    end
  end

  protected

  before_filter :set_transaction_contact_context, :only => ["search"]
  def set_transaction_contact_context
    set_contact_context(@gizmo_context.model.new.send(:required_contact_type))
  end

  def set_defaults
    @action_name=action_name
    @return_to_search = "false"
  end

  def be_a_thing
    set_transaction_type((controller_name()).singularize)
  end


  def check_for_receipt
    case action_name
    when /(receipt|mail_pdf)/ then "receipt_invoice.html.erb"
    else                "with_sidebar.html.erb"
    end
  end

  public

  def get_system_pricing
    result = nil
    sp = StorePricing.find_by_barcode(params[:barcode].to_s.strip)
    if sp
      result = sp.pricing_data
    end
    render :update do |page|
      page << "system_pricing_cache[#{params[:barcode].to_json}] = #{result.to_json};"
      page << "ge_done();"
    end
  end

  def get_system_contract
    s = nil
    if params[:system_id].to_s == params[:system_id].to_i.to_s
      s = System.find_by_id(params[:system_id])
    end
    v = (s ? s.contract_id : -1)
    v2 = (s ? s.covered : nil)

    render :update do |page|
      page << "internal_system_contract_id = #{v.to_s.to_json}";
      page << "system_covered_cache[#{params[:system_id].to_json}] = #{v2.inspect.to_json}";
      page << "ge_done();"
    end
  end

  def get_storecredit_amount
    s = nil
    begin
      scid = StoreChecksum.new_from_checksum(params[:id]).result
      s = StoreCredit.find_by_id(scid)
    rescue StoreChecksumException
    end # else below..
    msg = nil
    v = -1
    if s
      if s.spent?
        msg = "This store credit has already been spent"
      else
        v = s.amount_cents
        if !s.still_valid?
          msg = "This store credit is expired. It expired on #{s.expire_date.strftime("%D")}. This software will allow it anyway, but you possibly should not."
        end
      end
    else
      msg = "That store credit hash is not valid or doesn't exist"
    end
    v = (s && !s.spent? ? s.amount_cents : -1)
    render :update do |page|
      page << "internal_storecredit_amount = #{v.to_s.to_json};";
      page << "storecredit_errors_cache[#{params[:id].to_json}] = #{msg.to_json};"
      page.hide     params[:loading] # loading_indicator_id("payment_line_item")
    end
  end

  def get_sale_exists
    s = Sale.find_by_id(params[:id].to_i)
    s = !! s
    render :update do |page|
      page << "internal_sale_exists = #{s.to_json};";
      page.hide loading_indicator_id("line_item")
    end
  end

  def get_disbursement_exists
    s = Disbursement.find_by_id(params[:id].to_i)
    s = !! s
    render :update do |page|
      page << "internal_disbursement_exists = #{s.to_json};";
      page.hide loading_indicator_id("line_item")
    end
  end

  def update_stuff
    @show_wrapper = false
    params[:continue] = false
  end

  def component_update
    update_stuff
    search
  end

  def search
    @show_wrapper = true if @show_wrapper.nil?
    @conditions = Conditions.new
    @model = model
    if params[:dont_show_wrapper]
      update_stuff
    end

    if params[:continue] && !session[:search_bookmark].nil?
      params[:conditions] = session[:search_bookmark][:conditions]
      params[:page] = session[:search_bookmark][:page]
    end

    if params[:conditions] == nil
      params[:conditions] = {}
      @transactions = nil
      session[:search_bookmark] = nil
    else
      @sort_sql = @model.default_sort_sql
      @conditions.apply_conditions(params[:conditions])

      @per_page = determine_per_page
      search_options = {
        :order => @sort_sql,
        :per_page => @per_page,
        :include => [:gizmo_events],
        :conditions => @conditions.conditions(@model),
        :page => params[:page]
      }

      if @model.new.respond_to?( :payments )
        search_options[:include] << :payments
      end

      session[:search_bookmark] = {
        :conditions => params[:conditions],
        :page => params[:page]
      }
      @transactions = @model.paginate( search_options )
    end

    @return_to_search = "true"

    render :action => "search", :layout => @show_wrapper
  end

  def index
    new
    render :action => 'new'
  end

  private
  def new_trans_init_hook
  end
  public

  def new
    @transaction ||= model.new(params[@gizmo_context.name.to_sym])
    new_trans_init_hook
    @successful ||= true

    @conditions = Conditions.new
    @conditions.apply_conditions((default_condition + "_enabled") => "true")
    @conditions.apply_conditions((default_condition + "_date") => Date.today.to_s)
    @transactions = model.find(:all, :conditions => @conditions.conditions(model), :limit => 15, :order => default_condition + " DESC")
  end

  def create
      @transaction = model.new(params[@transaction_type])
      _apply_line_item_data(@transaction)
      @successful =  @transaction.valid? && @transaction.save

    render :action => 'create.rjs'
  end

  def create_without_ajax
      @transaction = model.new(params[@transaction_type])
      _apply_line_item_data(@transaction)
      @successful =  @transaction.valid? && @transaction.save

    if @successful
      if @transaction_type == "sale" or (@transaction_type == "donation" and @transaction.contact_type != "dumped")
        @receipt = @transaction.id
      end
      @transaction = model.new
    end
    new
    render :action => 'new'
  end

  def edit
      @transaction = model.find(params[:id])
      @successful = !@transaction.nil?
      @initial_page_load = true

    @return_to_search = params[:return_to_search] == "true"

    @conditions = Conditions.new
    @conditions.apply_conditions((default_condition + "_enabled") => "true")
    @transactions = model.find(:all, :conditions => @conditions.conditions(model), :limit => 15, :order => default_condition + " DESC")
    if !@successful
      render :action => "new"
      @successful = true
    end
  end

  def update
      @transaction = model.find(params[:id])
      @transaction.attributes = params[@transaction_type]
      _apply_line_item_data(@transaction)
      @successful =  @transaction.valid? && @transaction.save

    if @transaction
      render :action => 'update.rjs'
    else
      flash[:error] = "Error: Record has was already deleted, Failed to save: " + flash[:error]
      render :update do |page|
        page.redirect_to :action => "new"
      end
    end
  end

  def update_without_ajax
      @transaction = model.find(params[:id])
      @transaction.attributes = params[@transaction_type]
      _apply_line_item_data(@transaction)
      @successful =  @transaction.valid? && @transaction.save

    if @successful
      if @transaction_type == "sale" or (@transaction_type == "donation" and @transaction.contact_type != "dumped")
        @receipt = @transaction.id
      end
      @transaction = model.new
    end

    new
    render :action => 'new'
  end

  def destroy
    @transaction = model.find(params[:id])
    @successful = !! @transaction
    unless @transaction.user_is_bean_counter? || !@successful
      list = []
      if (@transaction.till_is_locked? && @transaction.till_hash.length > 0)
        list << 'till'
      end
      if (@transaction.inventory_is_locked? && @transaction.inventory_hash.length > 0)
        list << 'inventory'
      end
      if list.length > 0
        flash[:error] = "This transaction cannot be removed because it includes locked #{list.join(" and ")} values without privileges"
        @successful = false
      end
# RT #37169
#      if @transaction.has_returns?
#        flash[:error] = "This transaction cannot be removed because it has items which been returned in Return #{@transactions.returns.to_sentence}"
#        @successful = false
#      end
    end
    @successful = @transaction.destroy if @successful
    render :action => "destroy.rjs"
  end

  def needs_attention
      @transaction = model.find(params[:id])
      @transaction.comments += "\nATTN: #{params[:comment]}"
      @transaction.needs_attention = true
      @successful =  @transaction.valid? && @transaction.save
  end

  def cancel
    @successful = true

    return render(:action => 'cancel.rjs')
  end

  def update_discount_schedule
    if params[@transaction_type][:contact_id]
      default_discount_schedule = Contact.find(params[@transaction_type][:contact_id]).default_discount_schedule
    else
      default_discount_schedule = DiscountSchedule.no_discount
    end
    render :update do |page|
      page << "set_new_val($('#{@transaction_type}_discount_schedule_id'), '#{default_discount_schedule.id}');"
    end
  end

  def mail_pdf
    pdf = gen_pdf
    data = pdf.render
    type = @txn.invoiced? ? "invoice" : "receipt"
    filename = "donation_#{type}_#{params[:id]}.pdf"
    address = nil
    if params[:address_choice].nil?
      redirect_to :action => "receipt", :id => params[:id]
      return
    elsif params[:address_choice] == 'other'
      address = params[:address]
    else
      address = params[:address_choice]
    end
    if address.match(/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i)
      if params[:address_choice] == 'other'&& params[:save]
        ContactMethod.new(:contact_id => @txn.contact_id, :contact_method_type_id => params[:contact_method_type_id], :value => address, :ok => true).save!
      end
      if params[:subscribe] == "1"
        if @txn.contact && !@txn.contact.is_subscribed
          c = @txn.contact
          c.contact_types << ContactType.newsletter
          c.save
        end
      end
      Notifier.deliver_donation_pdf(address, data, filename, type)
      @message = "Sent to #{address}"
    else
      @message = "ERROR: invalid email address: #{address}"
      @is_err = true
    end
    receipt
    render :action => 'receipt'
  end

  protected
  include ActionView::Helpers::NumberHelper
  def gen_pdf_header(pdf, show_suggested, receipt_type, font_size = 12)
    w = 540/4.0
    pdf.table([[{:image => RAILS_ROOT + "/public/images/freegeeklogo.png", :position => :left}, {:image => RAILS_ROOT + "/public/images/hdr-address.png", :position => :left, :scale => 1}, {:border_width => 0, :content => ""}, {:content => ([@txn.contact_information, @txn.hidable_contact_information].flatten).map{|x| x || ""}.join("\n")}]], :column_widths => [w, w, w, w], :cell_style => {:border_width => 0})
    pdf.y -= 5     # - moves down.. coordinate system is confusing, starts bottom left

    pdf.stroke_horizontal_rule

    w = 540/3.0
    show_context = @txn.class != Donation || (receipt_type == 'receipt' && (@txn.find_lines(:is_gizmo_line?).length > 0 || @txn.cash_donation_paid_cents > 0))
    pdf.table(    [[{:content => "#{(@txn.invoiced? && receipt_type == 'invoice') ? "Invoice" : show_context ? "Donation Receipt" : "Invoice Receipt"}"}, {:content => ""}, {:content => Default["tax id"], :align => :right}],
     [{:content => "Created by ##{User.find_by_id(@transaction.cashier_created_by).contact_id}"}],
                   [{:content => "Date: #{@txn.occurred_at.strftime("%m/%d/%Y")}"}, {:content => "#{show_context ? "Donation" : "Invoice"} ##{@txn.id}"}, {:content => @txn.invoiced? ? "Due: #{@transaction.created_at.+(60*60*24*30).strftime("%m/%d/%Y")}" : "", :align => :right}]], :column_widths => [w, w, w], :cell_style => {:border_width => 0, :padding => 0})

    if show_suggested and @txn.reported_suggested_fee_cents > 0
      pdf.text "There is a suggested tax deductible contribution of $#{@txn.reported_suggested_fee} for these items.", :font_size => font_size
      pdf.y -= 3
    end
  end

  include ApplicationHelper

  def gen_pdf
    @txn = @transaction = model.find(params[:id])
    show_suggested = (params[:show_suggested].to_s == "true")
    @context = @transaction_type
    raise unless @context == 'donation'

    font_size = 12

    pdf = Prawn::Document.new

    pdf.font("Helvetica")

    count = 1

    @txn.receipt_types.each do |receipt_type|
      est_value = "Amount:"

      pdf.start_new_page unless count == 1
      count += 1

      gen_pdf_header(pdf, show_suggested && (receipt_type == 'invoice' || @txn.receipt_types.length == 1), receipt_type, font_size)

      ge = @txn.find_lines(:is_gizmo_line?)
      show_est = receipt_type == 'receipt' && ge.length > 0

      data = []
      if show_est
      est_value = "Est Value:"
        data += @txn.gizmo_events.map{|x| {"qty" => x.gizmo_count, "desc" => x.attry_description, "val" => "______"}}
      data.unshift({"desc" => "Items Donated", "bold" => true})
      data << {"desc" => "Total Estimated Value (tax deductible):", "val" =>  "_________"}
      data << {"desc" => " "}
      end

      if receipt_type == 'receipt'
        fees_ge = @txn.find_lines(:is_fee_line?)
        if fees_ge.length > 0
          data << {"desc" => "Required Fees", "bold" => true}
          data += fees_ge.map{|x| {"qty" => x.gizmo_count, "desc" => x.attry_processing_description, "val" => my_number_to_currency(x.gizmo_count * x.unit_price_cents)}}
          data << {"desc" => "Total Required Fees (NOT tax deductible):", "val" => my_number_to_currency(@txn.calculated_required_fee_cents)}
          data << {"desc" => " "}
        end
      end

      data << {"desc" => "Summary", "bold" => true}

      payments = @txn.payments

      if receipt_type == 'receipt'
        payments.select{|x| x.payment_method.description.downcase != "invoice"}.each do |payment|
          data << {"desc" => (payment.payment_method.description).titleize + (payment.payment_method.description.match("invoice") ? " Total" : " Paid"), "val" => my_number_to_currency(payment.amount_cents)}
        end

      if @txn.required_fee_owed_cents.nonzero? or @txn.required_fee_paid_cents.nonzero?
        data << {"desc" => "Required Fees (NOT tax deductible):", "val" => my_number_to_currency(-1 * (@txn.required_fee_paid_cents + @txn.required_fee_owed_cents))}
      end

      if (@txn.cash_donation_paid_cents.nonzero? or (@txn.calculated_required_fee_cents.nonzero? && !@txn.invoiced?)) && receipt_type == 'receipt'
        data << {"desc" => "Total Contribution Paid (tax deductible):", "val" => my_number_to_currency(@txn.cash_donation_paid_cents)}
      end
      end

      if @txn.invoiced?
        data << {"desc" => "Amount Still Due:", "val" => my_number_to_currency(@txn.amount_invoiced_cents)}
      end

      unless receipt_type != 'receipt' || ge.length == 0 || @txn.cash_donation_paid_cents == 0
        data << {"desc" => "Total Tax Deductible Contribution:\n(Estimated Value + Contribution Paid)", "val" =>  "_________"}
      end

      a = %w(qty desc val)
      headers = []
      arranged_data = [["Quantity:", "Description:", est_value]]
      count = 1
      data.each do |x|
        newarr = []
        a.each_with_index do |y,i|
          if i == 1 and x["bold"]
            headers << count
          end
          newarr[i] = x[y]
        end
        arranged_data << newarr
        count += 1
      end

    w = 540/9.0
      table = pdf.make_table(arranged_data, :column_widths => [2*w, 5*w, 2*w], :cell_style => {:padding => 1}, :row_colors => ["B0B0B0", "FFFFFF"])
      for i in headers
        table.row(i).column(1).font_style = :bold
      end
      table.draw

    pdf.text @txn.comments.to_s

    pdf.stroke_horizontal_rule
    pdf.y -= 5
      if receipt_type == 'receipt'
        pdf.text "We affirm that no goods or services were provided in return for the contribution amounts listed above (required fees excepted).", :font_size => font_size
        pdf.y -= 5
        pdf.y -= 5
        pdf.text "Retain this receipt for your taxes.", :font_size => font_size
      else
        pdf.text "Please return a copy of this invoice with payment."
      end
      if receipt_type == 'invoice' || @txn.receipt_types.length == 1
        if Default["contribution_blurb"] and show_suggested
          pdf.y -= 5
          pdf.y -= 5
          pdf.text Default["contribution_blurb"]
        end
      end
    end

    return pdf
  end
  public
  def pdf
    pdf = gen_pdf
    type = @txn.invoiced? ? "invoice" : "receipt"
    filename = "donation_#{type}_#{params[:id]}.pdf"
    sdata = pdf.render
    sdata.force_encoding('BINARY')
    send_data sdata, :filename => filename,
                    :type => "application/pdf"
  end

  def receipt
    @txn = @transaction = model.find(params[:id])
    @context = @transaction_type
  end

  #######
  private
  #######

  def set_transaction_type(type)
    @transaction_type = type
    @gizmo_context = GizmoContext.send(@transaction_type) or raise "UGH"
  end

  def totals_id(params)
    @transaction_type + '_totals_div'
  end

  def model
    case @transaction_type
    when 'donation'
      Donation
    when 'sale'
      Sale
    when 'disbursement'
      Disbursement
    when 'recycling'
      Recycling
    when 'gizmo_return'
      GizmoReturn
    else
      raise "UNKNOWN TX-TYPE #{@transaction_type}"
    end
  end

  def _apply_line_item_data(transaction)
    if transaction.respond_to?(:payments)
      @payments = my_apply_line_item_data(transaction, :payments)
      transaction.payments.select{|pmt| pmt.mostly_empty?}.each{|x| x.mark_for_destruction}
    end
    if transaction.respond_to?(:gizmo_events)
      if params[:gizmo_events]
        params[:gizmo_events].values.each{|x|
          x[:gizmo_count] ||= 1 if @gizmo_context == GizmoContext.gizmo_return
          x[:gizmo_context] = @gizmo_context
          # TODO: move this processing to entire db?
          for k in x.keys
            if x[k] == "undefined"
              x[k] = nil
            end
          end
        }
      end
      @lines = my_apply_line_item_data(transaction, :gizmo_events)
      transaction.gizmo_events.select {|gizmo| gizmo.mostly_empty?}.each{|x| x.mark_for_destruction}
    end
  end
end
