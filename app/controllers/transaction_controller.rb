class TransactionController < ApplicationController
  include DatalistFor

  layout :check_for_receipt

  protected

  def check_for_receipt
    case action_name
    when /receipt/ then "receipt_invoice.rhtml"
    else                "with_sidebar.rhtml"
    end
  end

  def authorized_only
    requires_role(:ROLE_ADMIN)
  end

  def store_or_get_from_session(id_key, value_key)
    session[id_key][value_key] = params[value_key] if !params[value_key].nil?
    params[value_key] ||= session[id_key][value_key]
  end

  public

  def component_update
    @show_wrapper = false # don't show the outer wrapper elements if we are just updating
    component
  end

  def component
    @show_wrapper = true if @show_wrapper.nil?
    @model = model
    @sort_sql = @model.default_sort_sql
    @conditions = Conditions.new
    @conditions.apply_conditions(params[:conditions])
    @conditions
    search_options = {
      :order => @sort_sql,
      :per_page => default_per_page,
      :include => [:gizmo_events],
      :conditions => @conditions.conditions(@model)
    }
    if @model.new.respond_to?( :payments )
      search_options[:include] << :payments
      search_options[:joins] = "JOIN payments ON payments.#{@transaction_type}_id = #{@model.table_name}.id"
    end
    search_options[:page] = params[:page]
    @transactions = @model.paginate( search_options )

    render :action => "component", :layout => false
  end

  def new
    @transaction = model.new
    @successful = true
    @initial_page_load = true

    return render(:action => 'new.rjs')
  end

  def create
    begin
      @transaction = model.new(params[@transaction_type])
      @successful = _save
    rescue
      flash[:error], @successful = $!.to_s + "<hr />" + $!.backtrace.join("<br />").to_s, false
    end

    render :action => 'create.rjs'
  end

  def edit
    begin
      @transaction = model.find(params[:id])
      @successful = !@transaction.nil?
      @initial_page_load = true
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    return render(:action => 'edit.rjs')
  end

  def update
    begin
      @transaction = model.find(params[:id])
      @transaction.attributes = params[@transaction_type]
      @successful = _save
    rescue
      flash[:error], @successful  = $!.to_s + "<hr />" + $!.backtrace.join("<br />").to_s, false #, false #
    end

    render :action => 'update.rjs'
  end

  def destroy
    begin
      @successful = model.find(params[:id]).destroy
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    return render(:action => 'destroy.rjs')
  end

  def needs_attention
    begin
      @transaction = model.find(params[:id])
      @transaction.comments += "\nATTN: #{params[:comment]}"
      @transaction.needs_attention = true
      @successful = @transaction.save
    rescue
      flash[:error], @successful = $!.to_s, false
    end
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

  # For gizmo_events embedded in a form
  def add_attrs_to_form
    if params[:gizmo_type_id]
      @gizmo_context = GizmoContext.find(params[:gizmo_context_id])
      @gizmo_type = GizmoType.find(params[:gizmo_type_id])
      if ! @gizmo_type.relevant_attrs(@gizmo_context).empty?
        render :update do |page|
          page.replace_html(params[:div_id],
                            :partial => 'gizmo_event_attr_form',
                            :locals => { :params => params })
          page << "trigger_change_on($('#{params[:div_id]}'));"
        end
        return true
      end
    end
    render :update do |page|
    end
  end

  def automatic_datalist_row
    events = datalist_objects( gizmo_events_tag, gizmo_event_defaults )
    if( events.empty? or
          events.find {|ev| (! ev.valid?) or ev.mostly_empty? } ) # the datalist form is not filled in completely
      render :text => ''
    else
      # :MC: doctor the params for datalist_add_row
      # :TODO: rewrite datalist
      params[:tag] = gizmo_events_tag
      params[:datalist_id] = params["datalist_#{gizmo_events_tag}_id"]
      datalist_add_row
    end
  end

  def receipt
    @txn = @transaction = model.find(params[:id])
    @context = @transaction_type
  end

  def update_totals
    @transaction = model.new(params[@transaction_type])
    _apply_datalist_data(@transaction)
    render :action => 'update_totals.rjs'
  end

  #######
  private
  #######

  def default_per_page
    20
  end

  def set_transaction_type(type)
    @transaction_type = type
    @gizmo_context = GizmoContext.send(@transaction_type)
  end

  def totals_id(params)
    @transaction_type + '_totals_div'
  end

  def gizmo_event_defaults
    @event_defaults ||= {
      :gizmo_context_id => @gizmo_context.id
    }
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
    else
      raise "UNKNOWN TX-TYPE #{@transaction_type}"
    end
  end

  def gizmo_events_tag
    @transaction_type + '_gizmo_events'
  end

  def payments_tag
    @transaction_type + '_payments'
  end

  def _apply_datalist_data(transaction)
    if transaction.respond_to? :payments
      apply_datalist_to_collection(payments_tag, transaction.payments)
      transaction.payments.delete_if {|pmt| pmt.mostly_empty?}
    end
    apply_datalist_to_collection(gizmo_events_tag, transaction.gizmo_events, gizmo_event_defaults)
    transaction.gizmo_events.delete_if {|gizmo| gizmo.mostly_empty?}
  end

  # common save logic
  def _save
    _apply_datalist_data(@transaction)

    if @transaction.respond_to?(:payments)
      if @transaction.invoiced?
        @transaction.txn_complete = false
        @transaction.txn_completed_at = nil
      else
        @transaction.txn_complete = true
        @transaction.txn_completed_at = Time.now
      end
    end

    case @transaction_type
    when 'sale'
      @transaction.reported_amount_due_cents = @transaction.calculated_total_cents
      @transaction.reported_discount_amount_cents = @transaction.calculated_discount_cents
    when 'donation'
      @transaction.reported_required_fee_cents = @transaction.calculated_required_fee_cents
      @transaction.reported_suggested_fee_cents = @transaction.calculated_suggested_fee_cents
    end

    success = @transaction.save
    if success
      @transaction.payments.each {|payment| payment.save} if @transaction.respond_to?( :payments )
      @transaction.gizmo_events.each {|gizmo| gizmo.save}
    end
    return success
  end

end
