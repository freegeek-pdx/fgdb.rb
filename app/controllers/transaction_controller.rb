class TransactionController < ApplicationController
  layout :check_for_receipt

  before_filter :set_defaults
  before_filter :be_a_thing

  def set_defaults
    @action_name=action_name
    @return_to_search = "false"
  end

  def be_a_thing
    set_transaction_type((controller_name()).singularize)
  end

  protected

  def check_for_receipt
    case action_name
    when /receipt/ then "receipt_invoice.html.erb"
    else                "with_sidebar.html.erb"
    end
  end

  def authorized_only
    requires_role(:ADMIN)
  end

  public

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

      search_options = {
        :order => @sort_sql,
        :per_page => 20,
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

  def new
    @transaction ||= model.new
    @successful ||= true

    @conditions = Conditions.new
    @conditions.apply_conditions((default_condition + "_enabled") => "true")
    @transactions = model.find(:all, :conditions => @conditions.conditions(model), :limit => 15, :order => default_condition + " DESC")
  end

  def create
    begin
      @transaction = model.new(params[@transaction_type])
      _apply_line_item_data(@transaction)
      @successful =  @transaction.save
    rescue
      flash[:error], @successful = $!.to_s + "<hr />" + $!.backtrace.join("<br />").to_s, false
    end

    render :action => 'create.rjs'
  end

  def create_without_ajax
    begin
      @transaction = model.new(params[@transaction_type])
      _apply_line_item_data(@transaction)
      @successful =  @transaction.save
    rescue
      flash[:error], @successful = $!.to_s + "<hr />" + $!.backtrace.join("<br />").to_s, false
    end
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
    begin
      @transaction = model.find(params[:id])
      @successful = !@transaction.nil?
      @initial_page_load = true
    rescue
      flash[:error], @successful = $!.to_s, false
    end

    @return_to_search = params[:return_to_search] == "true"

    @conditions = Conditions.new
    @conditions.apply_conditions((default_condition + "_enabled") => "true")
    @transactions = model.find(:all, :conditions => @conditions.conditions(model), :limit => 15, :order => default_condition + " DESC")
  end

  def update
    begin
      @transaction = model.find(params[:id])
      @transaction.attributes = params[@transaction_type]
      _apply_line_item_data(@transaction)
      @successful =  @transaction.save
    rescue
      flash[:error], @successful  = $!.to_s + "<hr />" + $!.backtrace.join("<br />").to_s, false #, false #
    end

    render :action => 'update.rjs'
  end

  def update_without_ajax
    begin
      @transaction = model.find(params[:id])
      @transaction.attributes = params[@transaction_type]
      _apply_line_item_data(@transaction)
      @successful =  @transaction.save
    rescue
      flash[:error], @successful  = $!.to_s + "<hr />" + $!.backtrace.join("<br />").to_s, false #, false #
    end

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
    begin
      @successful = model.find(params[:id]).destroy
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
    if request.env["HTTP_REFERER"]
      redirect_to :back
    else
      redirect_to :action => "index"
    end
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

  def receipt
    @txn = @transaction = model.find(params[:id])
    @context = @transaction_type
  end

  #######
  private
  #######

  def set_transaction_type(type)
    @transaction_type = type
    @gizmo_context = GizmoContext.send(@transaction_type)
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
    else
      raise "UNKNOWN TX-TYPE #{@transaction_type}"
    end
  end

  def _apply_line_item_data(transaction)
    if transaction.respond_to?(:payments) && params[:payments]
      @payments = []
      for payment in params[:payments].values
        p = Payment.new(payment)
        @payments << p
      end
      @transaction.payments = @payments
      transaction.payments.delete_if {|pmt| pmt.mostly_empty?}
    end

    if params[:line]
      lines = params[:line]
      @lines = []
      for line in lines.values
        @lines << GizmoEvent.new(line.merge({:gizmo_context => @gizmo_context}))
      end
      @transaction.gizmo_events = @lines
    end
    transaction.gizmo_events.delete_if {|gizmo| gizmo.mostly_empty?}
  end
end
