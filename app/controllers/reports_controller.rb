class ReportsController < ApplicationController

  layout :report_layout_choice
  def report_layout_choice
    case action_name
    when /report$/ then with_sidebar
    else                'reports_form.html.erb'
    end
  end

  #####################
  ### Gizmos report ###
  #####################

  def gizmos
    @defaults = Conditions.new
  end

  def gizmos_report
    @defaults = Conditions.new
    @defaults.apply_conditions(params[:defaults])
    @date_range_string = @defaults.to_s
    gizmos_report_init
    gizmo_ids = []
    GizmoEvent.totals(@defaults.conditions(GizmoEvent)).each do |summation|
      add_gizmo_to_data(summation, @gizmo_data)
    end
    GizmoEvent.category_totals(@defaults.conditions(GizmoEvent)).each do |summation|
      add_gizmo_category_to_data(summation, @gizmo_data)
    end
    GizmoEvent.income_totals(@defaults.conditions(GizmoEvent)).each{|k,v|
      @gizmo_income_data[k.to_i] = v 
    }
  end

  protected

  def gizmos_report_init
    @columns = DisbursementType.find(:all).map {|type| [DisbursementType, type.id]}
    ctxs = GizmoContext.find(:all).map {|context| [GizmoContext, context.id]}
    ctxs.insert(0, ctxs.delete([GizmoContext, GizmoContext.disbursement.id]))
    @columns += ctxs
    @columns.insert(0, @columns.delete([GizmoContext, GizmoContext.donation.id]))
    @columns << [nil,:total]

    @rows = []
    GizmoCategory.find(:all).sort_by{|gc|gc.description}.each do |gc|
      @rows << gc
      GizmoType.find(:all, :conditions => ["gizmo_category_id=?", gc.id]).sort_by{|gt|gt.description}.each do |gt|
        @rows << gt
      end
    end
    @rows << :total
    @gizmo_data = {}
    @rows.each {|type| @gizmo_data[type] = Hash.new(0)}
    @gizmo_income_data = {}

    @row_types = GizmoType.find(:all).sort_by{|type| type.description}
    @row_types << "total flow"
  end

  def category_tuple(id)
    [GizmoCategory, id]
  end

  def context_tuple(id)
    [GizmoContext, id]
  end

  def disbursement_tuple(id)
    [DisbursementType, id]
  end

  def plus_or_minus(id)
    # donations come in.  sales, recycling and disbursements go out.
    id == GizmoContext.donation.id ? 1 : -1
  end

  def add_gizmo_to_data(summation, data)
    type_id, context_id, disbursement_type_id, count = summation.map {|x| x.to_i}
    type = GizmoType.find(type_id)
    count *= plus_or_minus(context_id)
    if context_id == GizmoContext.disbursement.id
      tuple = disbursement_tuple(disbursement_type_id)
      data[type][tuple] += count
      data[:total][tuple] += count
    end
    tuple = context_tuple(context_id)
    data[type][tuple] += count
    data[:total][tuple] += count
    data[type][[nil, :total]] += count
    data[:total][[nil, :total]] += count
  end

  def add_gizmo_category_to_data(summation, data)
    category_id, context_id, count = summation.map {|x| x.to_i}
    category = GizmoCategory.find(category_id)
    count *= plus_or_minus(context_id)
    tuple = context_tuple(context_id)
    data[category][tuple] += count
    data[category][[nil, :total]] += count
  end

  #####################
  ### Income report ###
  #####################

  public

  def income
    @defaults = Conditions.new
  end

  def income_report
    @defaults = Conditions.new
    @defaults.apply_conditions(params[:defaults])
    @income_data = {}
    income_report_init #:MC: modifies @income_data
    @date_range_string = @defaults.to_s
    ranges = {:sales => {:min => 1<<64, :max => 0},
               :donations => {:min => 1<<64, :max => 0}
    }
    Donation.totals(@defaults.conditions(Donation)).each do |summation|
      add_donation_summation_to_data(summation, @income_data, ranges)
    end
    Sale.totals(@defaults.conditions(Sale)).each do |summation|
      add_sale_summation_to_data(summation, @income_data, ranges)
    end

    @ranges = {}
    [:sales, :donations].each do |x|
      @ranges[x] = "#{ranges[x][:min]}..#{ranges[x][:max]}"
    end
  end

  protected

  def income_report_init
    methods = PaymentMethod.find(:all)
    method_names = methods.map {|m| m.description}
    @columns = Hash.new( method_names.insert(2, 'till total').insert(-3, 'total real').insert(-1, 'total') )
    @width = @columns[nil].length
    @rows = {}
    @rows[:donations] = ['fees', 'suggested', 'subtotals']
    discount_types = DiscountSchedule.find(:all).map {|d_s| d_s.name}.sort
    @rows[:sales] = discount_types << 'subtotals'
    @rows[:grand_totals] = ['total']
    @sections = [:donations, :sales, :grand_totals]

    @income_data = {}
    @income_data[:donations] = {}
    @income_data[:sales] = {}
    @income_data[:grand_totals] = {}

    @sections.each do |section|
      @columns[section].each do |method|
        @income_data[section][method] = {}
        @rows[section].each do |row|
          @income_data[section][method][row] = {:total => 0.0, :count => 0}
        end
      end
    end
  end

  def add_donation_summation_to_data(summation, income_data, ranges)
    payment_method_id, amount_cents, required_cents, suggested_cents, count, mn, mx =
      summation[0..6].map {|c| c.to_i}
    return unless payment_method_id and payment_method_id != 0

    ranges[:donations][:min] = [ranges[:donations][:min], mn].min
    ranges[:donations][:max] = [ranges[:donations][:max], mx].max

    payment_method = PaymentMethod.descriptions[payment_method_id]
    grand_totals = income_data[:grand_totals]

    column = income_data[:donations][payment_method]
    fees_cents = 0
    suggested_cents = 0
    if required_cents <= 0
      suggested_cents = amount_cents
    elsif required_cents > amount_cents
      required_cents -= amount_cents
      fees_cents = amount_cents
    else
      fees_cents = required_cents
      required_cents = 0
      suggested_cents = amount_cents - fees_cents
    end

    if payment_method_id != PaymentMethod.invoice.id
      total_real = income_data[:donations]['total real']

      update_totals(total_real['fees'], fees_cents, count)
      update_totals(total_real['suggested'], suggested_cents, count)
      update_totals(total_real['subtotals'], amount_cents, count)
      update_totals(grand_totals['total real']['total'], amount_cents, count)
    end

    if( (payment_method_id == PaymentMethod.cash.id) ||
        (payment_method_id == PaymentMethod.check.id) )
      till_total = income_data[:donations]['till total']

      update_totals(till_total['fees'], fees_cents, count)
      update_totals(till_total['suggested'], suggested_cents, count)
      update_totals(till_total['subtotals'], amount_cents, count)
      update_totals(grand_totals['till total']['total'], amount_cents, count)
    end

    totals = income_data[:donations]['total']

    update_totals(totals['fees'], fees_cents, count)
    update_totals(totals['suggested'], suggested_cents, count)
    update_totals(totals['subtotals'], amount_cents, count)
    update_totals(column['fees'], fees_cents, count)
    update_totals(column['suggested'], suggested_cents, count)
    update_totals(column['subtotals'], amount_cents, count)
    update_totals(grand_totals[payment_method]['total'], amount_cents, count)
    update_totals(grand_totals['total']['total'], amount_cents, count)
  end

  def add_sale_summation_to_data(summation, income_data, ranges)
    payment_method_id, discount_schedule_id, amount_cents, count, mn, mx =
      summation[0..5].map {|c| c.to_i}
    return unless payment_method_id and payment_method_id != 0

    discount_schedule = DiscountSchedule.find(discount_schedule_id)

    ranges[:sales][:min] = [ranges[:sales][:min], mn].min
    ranges[:sales][:max] = [ranges[:sales][:max], mx].max
      
    payment_method = PaymentMethod.descriptions[payment_method_id]

    grand_totals = income_data[:grand_totals]
    column = income_data[:sales][payment_method]
    update_totals(column[discount_schedule.name], amount_cents, count)
    update_totals(column['subtotals'], amount_cents, count)
    if PaymentMethod.is_money_method?(payment_method_id)
      total_real = income_data[:sales]['total real']
      update_totals(total_real[discount_schedule.name], amount_cents, count)
      update_totals(total_real['subtotals'], amount_cents, count)
      update_totals(grand_totals['total real']['total'], amount_cents, count)
    end
    if PaymentMethod.is_till_method?(payment_method_id)
      till_total = income_data[:sales]['till total']
      update_totals(till_total[discount_schedule.name], amount_cents, count)
      update_totals(till_total['subtotals'], amount_cents, count)
      update_totals(grand_totals['till total']['total'], amount_cents, count)
    end
    totals = income_data[:sales]['total']
    update_totals(totals[discount_schedule.name], amount_cents, count)
    update_totals(totals['subtotals'], amount_cents, count)
    update_totals(grand_totals['total']['total'], amount_cents, count)
    update_totals(grand_totals[payment_method]['total'], amount_cents, count)
  end

  def update_totals(totals, amount, count)
    totals[:total] += amount
    totals[:count] += count
  end

  ########################
  ### Volunteer report ###
  ########################

  public

  def volunteers
    @defaults = Conditions.new
    @defaults.contact_enabled = "true"
  end

  def volunteers_report
    @defaults = Conditions.new
    if params[:contact]
      params[:defaults][:contact_id] = params[:contact][:id]
      @contact = Contact.find_by_id(params[:contact][:id])
    else
      @contact = nil
    end
   
    @defaults.apply_conditions(params[:defaults])
    @date_range_string = @defaults.to_s
    @tasks = VolunteerTask.find_by_conditions(@defaults.conditions(VolunteerTask))
    @sections = [:community_service_type, :volunteer_task_type]
    @data = volunteer_report_for(@tasks, @sections)
  end

  protected

  def volunteer_report_for(tasks, sections)
    data = {}
    sections.each {|section|
      data[section] = {}
      eval(Inflector.classify(section)).find(:all).each {|type|
        data[section][type.description] = 0.0
      }
      data[section]['Total'] = 0.0
      data[section]['(none)'] = 0.0
    }
    tasks.each {|task|
      add_task_to_data(task, sections, data)
    }
    return data
  end

  def add_task_to_data(task, sections, data)
    i=1
    sections.each do |section|
      data[section][(task[i] || '(none)')] += task[0].to_f
      data[section]["Total"] ||= 0.0
      data[section]["Total"] += task[0].to_f
      i += 1
    end
  end

  public 

  def hours
    @defaults = Conditions.new
    @defaults.contact_enabled = "true"
  end

  def hours_report
    @defaults = Conditions.new
    if params[:contact] || params[:contact_id]
      contact_id = (params[:contact_id] || params[:contact][:id])
      params[:defaults] ||= {:contact_enabled=>"true"}
      params[:defaults][:contact_id] = contact_id
      @contact = Contact.find_by_id(contact_id)
    else
      @contact = nil
    end
    @defaults.apply_conditions(params[:defaults])
    @date_range_string = @defaults.to_s
    # if this is too slow, replace it with straight sql
    @tasks = VolunteerTask.find(:all, 
                                :conditions => @defaults.conditions(VolunteerTask),
                                :order => "date_performed desc")
    
  end
end
