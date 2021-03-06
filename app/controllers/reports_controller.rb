require_dependency RAILS_ROOT + '/app/controllers/graphic_reports_controller.rb'

class ReportsController < ApplicationController

  layout :with_sidebar
  protected

  # fgss stuff, ignore it please
  # added so that rocky can be gotten rid of
  MINIMUM_COMPAT_VERSION=2
  def check_compat
    if !params[:version] || params[:version].empty? || params[:version].to_i < MINIMUM_COMPAT_VERSION
      render :xml => {:compat => false, :your_version => params[:version].to_i, :minimum_version => MINIMUM_COMPAT_VERSION, :message => "You need to update your version of printme\nTo do that, go to System, then Administration, then Update Manager. When update manager comes up, click Check and then click Install Updates.\nAfter that finishes, run printme again."}
    else
      render :xml => {:compat => false, :your_version => params[:version].to_i, :minimum_version => 0, :message => "Something went wrong.\nYou have the printme version that should be talking to the new database,\nand yet it's still connecting to the old one.\nTry upgrading freegeek-extras...\nIf that doesn't work, go and yell at Ryan."}
      #     render :xml => {:compat => true}
    end
  end

  protected
  def _suggested_query(conds, having)
    DB.exec("SELECT count(*), SUM(reported_suggested_fee_cents) AS suggested_fee_cents, SUM(contribution_cents) AS contribution_cents FROM (SELECT donations.id,
reported_suggested_fee_cents, reported_required_fee_cents, CASE WHEN ((CASE WHEN SUM(payments.amount_cents) IS NULL THEN 0 ELSE SUM(payments.amount_cents) END) - reported_required_fee_cents) > 0 THEN ((CASE WHEN SUM(payments.amount_cents) IS NULL THEN 0 ELSE SUM(payments.amount_cents) END) - reported_required_fee_cents) ELSE 0 END AS contribution_cents, SUM(payments.amount_cents) AS
payment_cents FROM donations LEFT OUTER JOIN payments ON payments.donation_id = donations.id
WHERE #{Donation.send(:sanitize_sql_for_conditions, conds)} AND donations.adjustment = 'f' GROUP BY 1, 2, 3 #{having}) AS r;")
  end

  private
  def run_graphic_report(klass, args)
    report = klass.new
    report.set_conditions(args)
    report.generate_report_data
    return report.data[0]
  end

  public

  def monthly_reports
    @target = OpenStruct.new
    @departments = ['production', 'operations', 'public-services']
    if params[:target].nil?
      @target.target = Date.today
    else
      @mode = mode = params[:dept_id]
      @target.target_year = params[:target][:target_year]
      @target.target_month = params[:target][:target_month]
      @target.target = Date.parse("01/#{@target.target_month}/#{@target.target_year}")

      if mode == 'production'
        base_args = {:start_date => @target.target.to_s, :end_date => @target.target.to_s, :breakdown_type => "Monthly", :report_type => "Total Sales Amount By Gizmo Type", "gizmo_type_id_enabled" => "true"}


        data = run_graphic_report(TotalSalesAmountByGizmoTypesTrend, base_args.merge({"gizmo_type_id" => GizmoType.find_by_name("system").id}))
        @sale_systems = data[:amount].first

        data = run_graphic_report(TotalSalesAmountByGizmoTypesTrend, base_args.merge({"gizmo_type_id" => GizmoType.find_by_name("system").id, :start_date => (@target.target-1.year).to_s, :end_date => (@target.target-1.year).to_s}))
        @sale_systems_lastyear = data[:amount].first

        data = run_graphic_report(TotalSalesAmountByGizmoTypesTrend, base_args.merge({"gizmo_type_id" => GizmoType.find_by_name("laptop").id}))
        @sale_laptops = data[:amount].first

        data = run_graphic_report(TotalSalesAmountByGizmoTypesTrend, base_args.merge({"gizmo_type_id" => GizmoType.find_by_name("laptop").id, :start_date => (@target.target-1.year).to_s, :end_date => (@target.target-1.year).to_s}))
        @sale_laptops_lastyear = data[:amount].first

        data = run_graphic_report(SalesGizmoCountByTypesTrend, base_args.merge({:report_type => "Sales Gizmo Count By Type", "gizmo_type_id" => GizmoType.find_by_name("system").id}))
        @sales_system_count = data[:count].first

        data = run_graphic_report(SalesGizmoCountByTypesTrend, base_args.merge({:report_type => "Sales Gizmo Count By Type", "gizmo_type_id" => GizmoType.find_by_name("system").id, :start_date => (@target.target-1.year).to_s, :end_date => (@target.target-1.year).to_s}))
        @sales_system_count_lastyear = data[:count].first

        data = run_graphic_report(SalesGizmoCountByTypesTrend, base_args.merge({:report_type => "Sales Gizmo Count By Type", "gizmo_type_id" => GizmoType.find_by_name("laptop").id}))
        @sales_laptop_count = data[:count].first

        data = run_graphic_report(SalesGizmoCountByTypesTrend, base_args.merge({:report_type => "Sales Gizmo Count By Type", "gizmo_type_id" => GizmoType.find_by_name("laptop").id, :start_date => (@target.target-1.year).to_s, :end_date => (@target.target-1.year).to_s}))
        @sales_laptop_count_lastyear = data[:count].first

        data = run_graphic_report(DisbursementGizmoCountByTypesTrend, base_args.merge({:report_type => "Disbursements Gizmo Count By Type", "gizmo_type_id" => GizmoType.find_by_name("system").id}))
        @systems_granted = data.values.map{|x| x.first.to_i}.inject(0){|t, x| t+= x}

  data = run_graphic_report(DisbursementGizmoCountByTypesTrend, base_args.merge({:report_type => "Disbursements Gizmo Count By Type", "gizmo_type_id" => GizmoType.find_by_name("system").id, :start_date => (@target.target-1.year).to_s, :end_date => (@target.target-1.year).to_s}))
        @systems_granted_lastyear = data.values.map{|x| x.first.to_i}.inject(0){|t, x| t+= x}

        data = run_graphic_report(DisbursementGizmoCountByTypesTrend, base_args.merge({:report_type => "Disbursements Gizmo Count By Type", "gizmo_type_id" => GizmoType.find_by_name("laptop").id}))
        @laptops_granted = data.values.map{|x| x.first.to_i}.inject(0){|t, x| t+= x}

        data = run_graphic_report(DisbursementGizmoCountByTypesTrend, base_args.merge({:report_type => "Disbursements Gizmo Count By Type", "gizmo_type_id" => GizmoType.find_by_name("laptop").id, :start_date => (@target.target-1.year).to_s, :end_date => (@target.target-1.year).to_s}))
        @laptops_granted_lastyear = data.values.map{|x| x.first.to_i}.inject(0){|t, x| t+= x}


        data = run_graphic_report(AverageUnitPriceByGizmoTypesTrend, base_args.merge({:report_type => "Average unit price by gizmo type", "gizmo_type_id" => GizmoType.find_by_name("system").id}))
        @system_price = data.values.first.first.to_f if data.values.first

        data = run_graphic_report(AverageUnitPriceByGizmoTypesTrend, base_args.merge({:report_type => "Average unit price by gizmo type", "gizmo_type_id" => GizmoType.find_by_name("system").id, :start_date => (@target.target-1.year).to_s, :end_date => (@target.target-1.year).to_s}))
        @system_price_lastyear = data.values.first.first.to_f if data.values.first

        data = run_graphic_report(AverageUnitPriceByGizmoTypesTrend, base_args.merge({:report_type => "Average unit price by gizmo type", "gizmo_type_id" => GizmoType.find_by_name("laptop").id}))
        @laptop_price = data.values.first.first.to_f if data.values.first

        data = run_graphic_report(AverageUnitPriceByGizmoTypesTrend, base_args.merge({:report_type => "Average unit price by gizmo type", "gizmo_type_id" => GizmoType.find_by_name("laptop").id, :start_date => (@target.target-1.year).to_s, :end_date => (@target.target-1.year).to_s}))
        @laptop_price_lastyear = data.values.first.first.to_f if data.values.first



      elsif mode == 'public-services'
        @conditions = Conditions.new
        @conditions.apply_conditions({})
        @conditions.sked_enabled = true
        @conditions.sked_id = Sked.find_by_name_and_category_type("Classes", "Front Desk Checkin").id
        @conditions.date_enabled = true
        @conditions.date_date_type = "monthly"
        @conditions.date_month = @target.target.month
        @conditions.date_year = @target.target.year

        _run_vol_sched_report(true)
        @volskedj = @result["attending"]

        report = DisbursementGizmoCountByTypesTrend.new
        base_disburse = {:start_date => (@target.target - 1.year).to_s, :end_date => @target.target.to_s, :breakdown_type => "Monthly", :report_type => "Disbursement Gizmo Count By Type", "gizmo_type_group_id_enabled" => "true"}
        report.set_conditions(base_disburse.merge({"gizmo_type_group_id" => GizmoTypeGroup.find_by_name("All Systems").id}))
        report.generate_report_data
        @disburse_systems = report.data[0]["Hardware Grants"]
        report.set_conditions(base_disburse.merge({"gizmo_type_group_id" => GizmoTypeGroup.find_by_name("All Laptops").id}))
        report.generate_report_data
        @disburse_laptops = report.data[0]["Hardware Grants"]
        report.set_conditions(base_disburse.merge({"gizmo_type_group_id" => GizmoTypeGroup.find_by_name("Peripherals").id}))
        report.generate_report_data
        @disburse_peripherals = report.data[0]["Hardware Grants"]

        @past_year_labels = report.x_axis

        @disburse_table = [["Month", "Laptops", "Systems", "Peripherals"]]
        @past_year_labels.each_with_index {|x, i|
          @disburse_table << [x, @disburse_laptops[i], @disburse_systems[i], @disburse_peripherals[i]]
        }
        
        r = ReportsController.new
        income = r.income_report({"created_at_enabled" => "true", "created_at_date_type" => "monthly", "created_at_month" => @target.target.month, "created_at_year" => @target.target.year})
        @bulk = income[:thrift_store]["real total"]["Bulk sales"][:total] / 100.0

        last_income = r.income_report({"created_at_enabled" => "true", "created_at_date_type" => "monthly", "created_at_month" => @target.target.month, "created_at_year" => @target.target.year - 1})
        @ts = income[:thrift_store]["real total"]["Retail"][:total] / 100.0
        @ts_last_year = last_income[:thrift_store]["real total"]["Retail"][:total] / 100.0

        @dd_suggested = income[:donor_desk]["register total"]["gizmo contributions"][:total] / 100.0
        @dd_suggested_count = income[:donor_desk]["register total"]["gizmo contributions"][:count]
        @dd_last_suggested = last_income[:donor_desk]["register total"]["gizmo contributions"][:total] / 100.0
        @dd_last_suggested_count = last_income[:donor_desk]["register total"]["gizmo contributions"][:count]

        # TODO: YTD / donations
        year_income = r.income_report({"created_at_enabled" => "true", "created_at_date_type" => "arbitrary", "created_at_start_date" => "01/01/#{@target.target_year}", "created_at_end_date" => (@target.target + 1.month - 1).to_s})
        last_year_income = r.income_report({"created_at_enabled" => "true", "created_at_date_type" => "arbitrary", "created_at_start_date" => "01/01/#{(@target.target.year - 1)}", "created_at_end_date" => (@target.target - 1.year + 1.month - 1).to_s})

        # FIXME: dates from last DOM
        @active = DB.exec("SELECT COUNT(*) AS vol_count FROM (SELECT xxx.contact_id
      FROM volunteer_tasks AS xxx
      WHERE xxx.date_performed BETWEEN
        ?::date AND ?::date
      GROUP BY xxx.contact_id
      HAVING SUM(xxx.duration) > #{Default['hours_for_discount'].to_f}) AS v", @target.target - Default['days_for_discount'].to_f, @target.target).first["vol_count"]

        @last_active = DB.exec("SELECT COUNT(*) AS vol_count FROM (SELECT xxx.contact_id
      FROM volunteer_tasks AS xxx
      WHERE xxx.date_performed BETWEEN
        ?::date AND ?::date
      GROUP BY xxx.contact_id
      HAVING SUM(xxx.duration) > #{Default['hours_for_discount'].to_f}) AS v", @target.target - 1.year - Default['days_for_discount'].to_f, @target.target - 1.year).first["vol_count"]

        @ts_head = [""]
        @ts_vol = ["Volunteer Hours"]
        @ts_staff = ["Staff Hours"]
        (0..3).to_a.reverse.each do |x|
          @ts_head << (@target.target - x.month).strftime("%b") + " " + @target.target.year.to_s
          @ts_vol << VolunteerTask.sum('duration', :conditions => ["date_performed >= ? AND date_performed <= ? AND volunteer_task_type_id IN (SELECT id FROM volunteer_task_types WHERE description ILIKE 'Tech Support%')", @target.target - x.month, @target.target + 1.month - 1 - x.month]).to_f
          @ts_staff << WorkedShift.sum('duration', :conditions => ["date_performed >= ? AND date_performed <= ? AND job_id IN (SELECT id FROM jobs WHERE name ILIKE 'Tech Support%')", @target.target - x.month, @target.target + 1.month - 1 - x.month]).to_f
        end


      elsif mode == 'operations'

      report = DonationsCountsTrend.new
      report2 = DonationsGizmoCountByTypesTrend.new
      base_donations = {:start_date => (@target.target - 2.months).to_s, :end_date => @target.target.to_s, :breakdown_type => "Monthly", :report_type => "Report of number of donations"}
      base_donations_lastyear = {:start_date => (@target.target - 1.year - 2.months).to_s, :end_date => (@target.target - 1.year).to_s, :breakdown_type => "Monthly", :report_type => "Report of number of donations"}
      report.set_conditions(base_donations)
      report.generate_report_data
      @donations_thisyear = report.data[0][:count]
      report2.set_conditions(base_donations.merge(:report_type => "Donations Gizmo Count By Type"))
      report2.generate_report_data
        @gizmos_thisyear = report2.data[0][:count]
      report.set_conditions(base_donations_lastyear)
      report.generate_report_data
      @donations_lastyear = report.data[0][:count]

      end

      @results = "You will see results here."
    end
  end

  def cashier_contributions
    @conditions = Conditions.new
  end

  def cashier_contributions_report
    @conditions = Conditions.new
    @conditions.apply_conditions(params[:conditions])
    sql = DB.send(:sanitize_sql_for_conditions, @conditions.conditions(Donation))
    @results = DB.exec("SELECT
COALESCE(contacts.first_name || ' ' || contacts.surname, 'NO CASHIER') AS name,
users.contact_id, users.login, COUNT(donations.id) AS donation_count,
trim(to_char(SUM(reported_suggested_fee_cents)/100,'99999999999999999D99')) AS total_suggested,
trim(to_char((SUM(payments.amount_cents) - SUM(reported_required_fee_cents))/100,'99999999999999999D99')) AS total_contributions,
CASE WHEN SUM(reported_suggested_fee_cents) = 0 THEN '0' ELSE 100 * (SUM(payments.amount_cents) - SUM(reported_required_fee_cents)) / SUM(reported_suggested_fee_cents) END as percentage,
trim(to_char((SUM(payments.amount_cents) - SUM(reported_required_fee_cents) - SUM(reported_suggested_fee_cents))/100, '99999999999999999D99')) as difference
FROM users
LEFT JOIN donations ON donations.cashier_created_by = users.id
LEFT JOIN contacts ON users.contact_id = contacts.id
LEFT JOIN payments ON donations.id = payments.donation_id
WHERE #{sql}
AND donations.adjustment = 'f'
GROUP BY 1, 2, 3;").to_a
  end

  def volunteer_schedule
    @conditions = Conditions.new
  end

  def volunteer_schedule_report
    @conditions = Conditions.new
    @conditions.apply_conditions(params[:conditions])
    _run_vol_sched_report
  end
  private
  def _run_vol_sched_report(skip = false)
    if @conditions.valid?
      @records =  DB.exec("SELECT
               COALESCE(
                 volunteer_task_types.description,
                 'attending')
               AS volunteer_type,
               rosters.name AS roster,
               COALESCE(attendance_types.name, 'not checked in') AS attendance_type,
               (EXTRACT(HOURS FROM assignments.end_time - assignments.start_time) + EXTRACT(MINUTES FROM assignments.end_time - assignments.start_time)/60) AS hours,
               volunteer_events.description AS event_name,
               volunteer_events.date AS event_date,
               contact_id
               FROM assignments
               JOIN volunteer_shifts ON volunteer_shift_id = volunteer_shifts.id
               JOIN volunteer_events ON volunteer_event_id = volunteer_events.id
               JOIN contacts ON contact_id = contacts.id
               LEFT OUTER JOIN volunteer_task_types ON volunteer_task_type_id = volunteer_task_types.id
               LEFT OUTER JOIN rosters ON roster_id = rosters.id
               LEFT OUTER JOIN attendance_types ON attendance_type_id = attendance_types.id
               WHERE #{DB.send(:sanitize_sql_for_conditions, @conditions.conditions(Assignment))}")
      @result = {}
      @contacts = {}
      @records.to_a.each do |l|
        unless @result[l["volunteer_type"]]
          @result[l["volunteer_type"]] = {"classes" => {}, "rosters" => {}, "rosters_total" => {"total" => 0, "total_hours" => 0.0}, "attendance_types" => [], "name" => l["volunteer_type"]}
        end
        # FIXME: somewhere we should return if skip, only need some things here
        result = @result[l["volunteer_type"]]
        class_name = "#{l["event_date"]}, #{l["event_name"]}"
        result["attendance_types"] << l["attendance_type"] unless result["attendance_types"].include?(l["attendance_type"])
        roster = l['roster']
        unless result["rosters"][roster]
          result["rosters"][roster] = {"total" => 0, "total_hours" => 0.0}
        end
        result["rosters"][roster]["total"] += 1
        result["rosters"][roster][l["attendance_type"]] ||= 0
        result["rosters"][roster][l["attendance_type"]] += 1
        result["rosters"][roster]["total_hours"] += l["hours"].to_f
        result["rosters_total"]["total"] += 1
        result["rosters_total"][l["attendance_type"]] ||= 0
        result["rosters_total"][l["attendance_type"]] += 1
        result["rosters_total"]["total_hours"] += l["hours"].to_f
        result["classes"][class_name] ||= {}
        result["classes"][class_name][l["attendance_type"]] ||= []
        result["classes"][class_name][l["attendance_type"]] << l["contact_id"]
        unless @contacts[l["contact_id"]]
          @contacts[l["contact_id"]] = Contact.find_by_id(l["contact_id"])
        end
      end
    end
  end
  public
  def suggested_contributions
    @conditions = Conditions.new
  end

  def suggested_contributions_report
    @conditions = Conditions.new
    @conditions.apply_conditions(params[:conditions])
    @conditions.d_yuck_flag = true
    conds = @conditions.conditions(Donation)
    contributed = "HAVING SUM(payments.amount_cents) > reported_required_fee_cents"
    not_contributed = "HAVING SUM(payments.amount_cents) IS NULL OR SUM(payments.amount_cents) <= reported_required_fee_cents"
    @with = _suggested_query(conds, contributed).to_a.first
    @without = _suggested_query(conds, not_contributed).to_a.first
  end

  def staff_hours_summary
    # opts: date, worker, job (by title)
    @_col = {"worker" => "worker_id", "job" => "job_id", "date_performed" => "date_performed"}

    # Table for each date "date_performed"
    @table_breakdown = "date_performed"
    # row for each worker, jobs across top then, subtotals on all corners
    @row_breakdown = "worker"

    @conditions = Conditions.new
    @conditions.apply_conditions("date_performed_enabled" => "true", "worker_enabled" => "true")

    @multi_enabled = true
    @col_options = @_col.keys.sort
  end

  private
  def _to_s_or_d(input)
    input.class == Date ?
      input.strftime("%A, %D") :
      input.to_s
  end
  public

  def staff_hours_summary_report
    # columns related
    staff_hours_summary
    @tables = []
    if params[:conditions]
      @conditions = Conditions.new
      @conditions.apply_conditions(params[:conditions])
    end
    @table_breakdown = params[:table_breakdown] || @table_breakdown
    @row_breakdown = params[:row_breakdown] || @row_breakdown
    # col, chosen automatically
    left = (@_col.keys - [@table_breakdown, @row_breakdown])
    @col_breakdown = left.first
    unless @conditions.valid? and left.length == 1
      @report_error = "Invalid report options."
      return
    end
    @report_title = @conditions.to_s
    @worked_shifts = WorkedShift.find(:all, :conditions => @conditions.conditions(WorkedShift), :order => "#{@_col[@table_breakdown]}, #{@_col[@row_breakdown]}", :include => [:job, :worker])
    table_data = {}
    summary_table = {}
    @worked_shifts.each do |shift|
      if shift.duration != 0.0
        table_name = shift.send(@table_breakdown)
        row_name = shift.send(@row_breakdown)
        col_name = shift.send(@col_breakdown)

        table_data[table_name] ||= {}
        table_data[table_name][row_name] ||= {}
        table_data[table_name][row_name][col_name] ||= 0.0
        table_data[table_name][row_name][col_name] += shift.duration

        summary_table[row_name] ||= {}
        summary_table[row_name][col_name] ||= 0.0
        summary_table[row_name][col_name] += shift.duration
      end
    end
    total_title = "Total of all #{@table_breakdown.titleize.pluralize.gsub(/Date Performeds/, "Dates Performed")}"
    last = nil
    table_data[total_title] = summary_table if table_data.length > 1
    table_data.keys.sort_by(&:to_s).each{|table|
      this_table = []
      cols = table_data[table].values.map{|h| h.keys}.flatten.uniq.sort_by(&:to_s)
      if table != total_title and @col_breakdown == "date_performed" and @table_breakdown == "worker"
        col_titles = cols.map{|col| _wrap_link(col, table, _to_s_or_d(col))}
      elsif table != total_title and @table_breakdown == "date_performed" and @col_breakdown == "worker"
        col_titles = cols.map{|col| _wrap_link(table, col, _to_s_or_d(col))}
      else
        col_titles = cols.map{|x| _to_s_or_d(x)}
      end
      this_table << [@row_breakdown.titleize] + col_titles
      this_table[0] << "#{@row_breakdown} subtotals".titleize if this_table[0].length > 2
      col_totals = (1..(cols.length)).to_a.map{|x| 0.0}
      table_data[table].keys.sort_by{|x| s = x.to_s.downcase; s == "total of all workers" ? "zzz #{s}" : s}.each{|row|
        row_total = 0.0
        this_row = []
        if table != total_title and @row_breakdown == "date_performed" and @table_breakdown == "worker"
          this_row << _wrap_link(row, table, _to_s_or_d(row))
        elsif table != total_title and @table_breakdown == "date_performed" and @row_breakdown == "worker"
          this_row << _wrap_link(table, row, _to_s_or_d(row))
        else
          this_row << _to_s_or_d(row)
        end
        cols.each_with_index{|col,i|
          val = table_data[table][row][col]
          if val
            if table != total_title and @col_breakdown == "date_performed" and @row_breakdown == "worker"
              this_row << _wrap_link(col, row, val)
            elsif table != total_title and @row_breakdown == "date_performed" and @col_breakdown == "worker"
              this_row << _wrap_link(row, col, val)
            else
              this_row << val
            end
            col_totals[i] += val
            row_total += val
          else
            this_row << ""
          end
        }
        this_row << row_total if this_row.length > 2
        this_table << this_row
      }
      this_table << ["#{@col_breakdown} subtotals".titleize, col_totals, col_totals.inject(0.0){|t,x| t+=x}].flatten if this_table.length > 2
      if total_title == table
        last = [_to_s_or_d(table), this_table]
      else
        @tables << [_to_s_or_d(table), this_table]
      end
    }
    @tables << last if last
  end


  private
  def _wrap_link(date, worker, value)
    return value unless worker.contact_id
    return value if worker == "Total of all Workers"
    [:a, {:action => "index", :controller => "worked_shifts", :worked_shift => {:contact_id => worker.contact_id, :date_performed => date}}, value]
  end
  public

  def donation_zip_areas
    @report = OpenStruct.new
    @report.min_limit = 10
    @report.by_full_zip = false
    @conditions = Conditions.new
    @conditions.occurred_at_date_type = "yearly"
  end

  def donation_zip_areas_report
    donation_zip_areas
    @report = OpenStruct.new(params[:report])
    @report.by_full_zip = (@report.by_full_zip == "1")
    @report.min_limit = @report.min_limit.to_i
    @conditions.apply_conditions(params[:conditions])
    group_by = "CASE COALESCE(COALESCE(contacts.postal_code, donations.postal_code), 'N/A') WHEN '00000' THEN 'N/A' WHEN '0' THEN 'N/A' ELSE COALESCE(COALESCE(contacts.postal_code, donations.postal_code), 'N/A') END"
    group_by = "SUBSTR(" + group_by + ", 0, 4)" unless @report.by_full_zip
    a = []
    Donation.connection.execute("SELECT #{group_by} AS postal_code, count(*) AS count FROM donations LEFT OUTER JOIN contacts ON donations.contact_id = contacts.id WHERE #{DB.prepare_sql(@conditions.conditions(Donation))} GROUP BY 1;").to_a.each{|x|
      a << [x["postal_code"], x["count"].to_i]
    }
    add_them = a.select{|x| x.last < @report.min_limit && x.first != 'N/A'}
    a = a - add_them
    a << ["Misc", add_them.inject(0){|t,x| t+=x.last}] if add_them.length > 0
    a = a.sort_by(&:last).reverse
    total = a.inject(0){|t,x| t+=x.last}
    append = (@report.by_full_zip ? "" : " Area")
    a = [["Zip Code" + append, "Donation Receipt Count"]] + a + [["TOTAL", total]]
    @title = "Report of Donation Zip Code" + append + "s" + @conditions.to_s
    @result = a
  end

  def top_donations
    @conditions = Conditions.new
    @report = OpenStruct.new
    @report.amount = 5000
    @report.limit = 100
    @conditions = Conditions.new
    @conditions.occurred_at_date_type = "yearly"
  end

  def top_donations_report
    conds = Conditions.new
    if params[:report]
      @report = OpenStruct.new(params[:report])
      conds.apply_conditions(params[:conditions])
      limit = params[:report][:amount]
      number = params[:report][:limit].to_i
    else
      @report = OpenStruct.new
      @report.amount = 5000
      @report.report_type = "contributions"
    end
    @conditions = conds
    type_name = ""
    if @report.report_type == "contributions"
      @title = "Top contributors" + conds.to_s
    else
      if @report.gizmo_type != "all"
        g_id = @report.gizmo_type.sub(/^./, "").to_i
        type_name = " "
        if @report.gizmo_type[0..0] == "c"
          conds.gizmo_category_id_enabled = true
          conds.gizmo_category_id = g_id
          type_name += GizmoCategory.find_by_id(g_id).description
        elsif @report.gizmo_type[0..0] == "t"
          conds.gizmo_type_id_enabled = true
          conds.gizmo_type_id = g_id
          type_name += GizmoType.find_by_id(g_id).description
        elsif @report.gizmo_type[0..0] == "g"
          conds.gizmo_type_group_id_enabled = true
          conds.gizmo_type_group_id = g_id
          type_name += GizmoTypeGroup.find_by_id(g_id).name
        end
      end
      @title = "Top#{type_name} gizmo donors" + conds.to_s
    end
    if conds.valid?
      limit = (limit.to_i * 100)
      if @report.report_type == "contributions"
        result = DB.exec("SELECT contact_id,SUM(amount_cents) as total FROM payments JOIN donations ON payments.donation_id = donations.id WHERE donation_id IS NOT NULL AND contact_id IS NOT NULL AND #{DB.prepare_sql(conds.conditions(Donation))} GROUP BY contact_id HAVING SUM(amount_cents) >= #{limit.to_s} ORDER BY SUM(amount_cents) DESC;").to_a
        @result = [["Contact ID", "Contact Name", "Total Contribution"]]
      else
        result = DB.exec("SELECT contact_id,SUM(gizmo_count) as total FROM gizmo_events JOIN donations ON gizmo_events.donation_id = donations.id WHERE donation_id IS NOT NULL AND contact_id IS NOT NULL AND #{DB.prepare_sql(conds.conditions(GizmoEvent))} GROUP BY contact_id ORDER BY SUM(gizmo_count) DESC LIMIT #{number.to_s};").to_a
        @result = [["Contact ID", "Contact Name", "Total#{type_name} Gizmos Donated"]]
      end
      result.map{|x|
        cid = x["contact_id"]
        cdisp = Contact.find_by_id(cid).display_name
        total = x["total"].to_i
        if @report.report_type == "contributions"
          total = total.to_dollars
        end
        @result << [cid, cdisp, total]
      }
    end
  end

  #####################
  ### Gizmos report ###
  #####################

  public

  def gizmos
    @defaults = Conditions.new
    @defaults.occurred_at_enabled = true
  end

  def gizmos_report
    @defaults = Conditions.new
    @defaults.apply_conditions(params[:defaults])
    @date_range_string = @defaults.to_s
    if @defaults.valid?
      gizmos_report_init
      gizmo_ids = []
      GizmoEvent.totals(@defaults.conditions(GizmoEvent)).each do |summation|
        add_gizmo_to_data(summation, @gizmo_data)
      end
    end
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
#    @gizmo_income_data = {}

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
    (id == GizmoContext.donation.id || id == GizmoContext.gizmo_return.id) ? 1 : -1
  end

  def add_gizmo_to_data(summation, data)
    category_id, type_id, context_id, disbursement_type_id, count = summation['gizmo_category_id'], summation['gizmo_type_id'].to_i, summation['gizmo_context_id'].to_i, summation['disbursement_type_id'].to_i, summation['count'].to_i
    type = GizmoType.find(type_id)
    category = GizmoCategory.find(category_id)
    count *= plus_or_minus(context_id)
    if context_id == GizmoContext.disbursement.id
      tuple = disbursement_tuple(disbursement_type_id)
      data[type][tuple] += count
      data[category][tuple] += count
      data[:total][tuple] += count
    end
    tuple = context_tuple(context_id)
    data[category][tuple] += count
    data[type][tuple] += count
    data[:total][tuple] += count
    data[type][[nil, :total]] += count
    data[category][[nil, :total]] += count
    data[:total][[nil, :total]] += count
  end

  #####################
  ### Income report ###
  #####################

  public

  def income
    @defaults = Conditions.new
  end

  def income_report(thing = nil)
    @defaults = Conditions.new
    thing = thing || params[:defaults]
    if thing.nil?
      flash[:error] = "Select report conditions"
      redirect_to :action => "income"
      return
    end
    @defaults.apply_conditions(thing)
    @income_data = {}
    income_report_init #:MC: modifies @income_data
    @date_range_string = @defaults.to_s
    ranges = {:thrift_store => {:min => 1<<64, :max => 0},
      :donor_desk => {:min => 1<<64, :max => 0}
    }
    Donation.totals(@defaults.conditions(Donation)).each do |summation|
      add_donation_summation_to_data(summation, @income_data, ranges)
    end
    Sale.totals(@defaults.conditions(Sale)).each do |summation|
      add_sale_summation_to_data(summation, @income_data, ranges)
    end

    @ranges = {}
    [:thrift_store, :donor_desk].each do |x|
      @ranges[x] = "#{ranges[x][:min]}..#{ranges[x][:max]}"
    end

    # cleanup :written_off_invoices if its empty
    h = @income_data[:written_off_invoices]['total']
    h.each{|k,v|
      if v[:total] == 0.0
        h.delete(k)
        @rows[:written_off_invoices].delete(k)
      end
    }
    if h.length == 0
      @income_data.delete(:written_off_invoices)
      @sections.delete(:written_off_invoices)
    end

    @income_data
  end

  ACCT_SETTINGS = {"pickup_fee_class" => "230 Pickups",
    "tech_support_fee_class" => "430 Technical Support",
    "education_fee_class" => "420 Education",
    "recycling_fee_class" => "210 Receiving",
    "donor_desk_class" => "700 Fundraising Activities",
    "retail_class" => "310 Thrift Store",
    "bulk_sales_class" => "320 Bulk Sales",
    "online_sales_class" => "330 Online Sales",
    "gizmo_contribution_account" => "Donor Desk Contributions",
    "other_contribution_account" => "Other Cash Contributions",
    "fee_account" => "Program service sales fees",
    "misc_revenue_account" => "Misc revenue",
    "refunds_account" => "Refunds",
    "cash_transfer_account" => "Safe",
    "credit_transfer_account" => "Payroll First Tech 4817"}

  def export_income_report
    my_income_report = income_report
    transfers = []

    for payment in [["cash", "cash_transfer_account"], ["credit", "credit_transfer_account"]]
      pt = payment.first
      transfer_account = ACCT_SETTINGS[payment.last]

      splits = []
      target_account = ACCT_SETTINGS["fee_account"]
      generic_class = nil
      for st in ["Retail", "Bulk sales", "Online sales"]
        reported = my_income_report[:thrift_store][pt][st][:total] / 100.0
        target_class = ACCT_SETTINGS[st.downcase.gsub(" ", "_") + "_class"] || raise
        generic_class ||= target_class
        splits << [target_account, target_class, reported] if reported > 0.0
      end
      for i in [["Other", "misc_revenue_account"], ["refunds", "refunds_account"]]
        line_name = i.first
        this_target_account = ACCT_SETTINGS[i.last]
        reported = my_income_report[:thrift_store][pt][line_name][:total] / 100.0
        splits << [this_target_account, generic_class, reported] if reported > 0.0
      end
      total_reported = my_income_report[:thrift_store][pt]["subtotals"][:total] / 100.0
      splits.insert(0, [transfer_account, nil, total_reported])
      transfers << splits if total_reported > 0.0

      splits = []
      for ft in ["Recycling", "Pickup", "Tech Support", "Education", "Other"]
        lc = ft.downcase.gsub(" ", "_")
        acct_class = ACCT_SETTINGS[lc + "_fee_class"]
        reported = my_income_report[:donor_desk][pt][lc + "_fees"][:total] / 100.0
        splits << [target_account, acct_class, reported] if reported > 0.0
      end
      generic_class = ACCT_SETTINGS["donor_desk_class"]
      for i in [["gizmo contributions", "gizmo_contribution_account"], ["other contributions", "other_contribution_account"]]
        line_name = i.first
        this_account = ACCT_SETTINGS[i.last]
        reported = my_income_report[:donor_desk][pt][line_name][:total] / 100.0
        splits << [this_account, generic_class, reported] if reported > 0.0
      end
      total_reported = my_income_report[:donor_desk][pt]["subtotals"][:total] / 100.0
      splits.insert(0, [transfer_account, nil, total_reported])
      transfers << splits if total_reported > 0.0
    end
    @transfers = transfers
    @date = @defaults.occurred_at_date
    @TRNSTYPE = "GENJRNL"

    render :partial => "reports/iif.text.erb"
  end



  protected

  def income_report_init
    @columns = PaymentMethod.till_methods.map(&:description) + ['till total'] +
      PaymentMethod.register_non_till_methods.map(&:description) + ['register total'] +
      PaymentMethod.real_non_register_methods.map(&:description) + ['real total'] +
      PaymentMethod.non_register_methods.select{|x| x != PaymentMethod.written_off_invoice}.map(&:description) + ['total']
    @width = @columns.length
    @rows = {}
    @rows[:donor_desk] = ['recycling_fees', 'pickup_fees', 'tech_support_fees', 'education_fees', 'other_fees', 'gizmo contributions', 'other contributions', 'subtotals']
    r_name = SaleType.find_by_name("retail")
    @rows[:thrift_store] = SaleType.all.map(&:description).sort + ['refunds', 'subtotals']
    if r_name and @rows[:thrift_store].include?(r_name.description)
      @rows[:thrift_store] = [r_name.description] + (@rows[:thrift_store] - [r_name.description])
    end
    @rows[:grand_totals] = ['total']
    @rows[:written_off_invoices] = ['donations', 'sales', 'total']
    @sections = [:donor_desk, :thrift_store, :grand_totals, :written_off_invoices]

    @income_data = {}
    @income_data[:donor_desk] = {}
    @income_data[:thrift_store] = {}
    @income_data[:grand_totals] = {}
    @income_data[:written_off_invoices] = {}

    @sections.each do |section|
      @columns.each do |method|
        @income_data[section][method] = {}
        @rows[section].each do |row|
          @income_data[section][method][row] = {:total => 0.0, :count => 0}
        end
      end
    end
  end

  def min(a,b)
    return a < b ? a : b
  end

  def max(a,b)
    return a > b ? a : b
  end

  def add_donation_summation_to_data(summation, income_data, ranges)
    gizmoless_cents, payment_method_id, amount_cents, tech_support_cents, education_cents, pickup_cents, recycling_cents, other_cents, suggested_cents, count, mn, mx = summation['gizmoless_cents'], summation['payment_method_id'].to_i, summation['amount'].to_i, summation['tech_support_fees'].to_i, summation['education_fees'].to_i, summation['pickup_fees'].to_i, summation['recycling_fees'].to_i, summation['other_fees'].to_i, summation['suggested'].to_i, summation['count'].to_i, summation['min'].to_i, summation['max'].to_i
    return unless payment_method_id and payment_method_id != 0

    ranges[:donor_desk][:min] = min(ranges[:donor_desk][:min], mn)
    ranges[:donor_desk][:max] = max(ranges[:donor_desk][:max], mx)

    payment_method = PaymentMethod.descriptions[payment_method_id]
    grand_totals = income_data[:grand_totals]

    column = income_data[:donor_desk][payment_method]

    # the suggested that's passed into us is really bogus, so we compute that here
    # "suggested" is the wrong terminology, it should really be "donation"

    contribution_cents = gizmoless_cents
    tech_support_cents = min(amount_cents - gizmoless_cents, tech_support_cents)
    pickup_cents = min(amount_cents - tech_support_cents - gizmoless_cents, pickup_cents)
    recycling_cents = min(amount_cents - tech_support_cents - pickup_cents - gizmoless_cents, recycling_cents)
    education_cents = min(amount_cents - tech_support_cents - pickup_cents - recycling_cents - gizmoless_cents, education_cents)
    other_cents = min(amount_cents - tech_support_cents - pickup_cents - recycling_cents - education_cents - gizmoless_cents, other_cents)
    suggested_cents = max(amount_cents - (tech_support_cents + education_cents + pickup_cents + recycling_cents + other_cents + gizmoless_cents), 0)

    if PaymentMethod.is_money_method?(payment_method_id)
      total_real = income_data[:donor_desk]['register total']

      update_totals(total_real['tech_support_fees'], tech_support_cents, count)
      update_totals(total_real['education_fees'], education_cents, count)
      update_totals(total_real['other_fees'], other_cents, count)
      update_totals(total_real['recycling_fees'], recycling_cents, count)
      update_totals(total_real['pickup_fees'], pickup_cents, count)
      update_totals(total_real['gizmo contributions'], suggested_cents, count)
      update_totals(total_real['other contributions'], gizmoless_cents, count)
      update_totals(total_real['subtotals'], amount_cents, count)
      update_totals(grand_totals['register total']['total'], amount_cents, count)
    end

    if PaymentMethod.is_real_method?(payment_method_id)
      total_real = income_data[:donor_desk]['real total']

      update_totals(total_real['tech_support_fees'], tech_support_cents, count)
      update_totals(total_real['education_fees'], education_cents, count)
      update_totals(total_real['other_fees'], other_cents, count)
      update_totals(total_real['recycling_fees'], recycling_cents, count)
      update_totals(total_real['pickup_fees'], pickup_cents, count)
      update_totals(total_real['gizmo contributions'], suggested_cents, count)
      update_totals(total_real['other contributions'], gizmoless_cents, count)
      update_totals(total_real['subtotals'], amount_cents, count)
      update_totals(grand_totals['real total']['total'], amount_cents, count)
    end

    if PaymentMethod.is_till_method?(payment_method_id)
      till_total = income_data[:donor_desk]['till total']

      update_totals(till_total['tech_support_fees'], tech_support_cents, count)
      update_totals(till_total['education_fees'], education_cents, count)
      update_totals(till_total['other_fees'], other_cents, count)
      update_totals(till_total['recycling_fees'], recycling_cents, count)
      update_totals(till_total['pickup_fees'], pickup_cents, count)
      update_totals(till_total['gizmo contributions'], suggested_cents, count)
      update_totals(till_total['other contributions'], gizmoless_cents, count)
      update_totals(till_total['subtotals'], amount_cents, count)
      update_totals(grand_totals['till total']['total'], amount_cents, count)
    end

    totals = income_data[:donor_desk]['total']

    update_totals(totals['tech_support_fees'], tech_support_cents, count)
    update_totals(totals['education_fees'], education_cents, count)
    update_totals(totals['other_fees'], other_cents, count)
    update_totals(totals['recycling_fees'], recycling_cents, count)
    update_totals(totals['pickup_fees'], pickup_cents, count)
    update_totals(totals['gizmo contributions'], suggested_cents, count)
    update_totals(totals['other contributions'], gizmoless_cents, count)
    update_totals(totals['subtotals'], amount_cents, count)
    update_totals(column['tech_support_fees'], tech_support_cents, count)
    update_totals(column['education_fees'], education_cents, count)
    update_totals(column['other_fees'], other_cents, count)
    update_totals(column['recycling_fees'], recycling_cents, count)
    update_totals(column['pickup_fees'], pickup_cents, count)
    update_totals(column['gizmo contributions'], suggested_cents, count)
    update_totals(column['other contributions'], gizmoless_cents, count)
    update_totals(column['subtotals'], amount_cents, count)
    update_totals(grand_totals[payment_method]['total'], amount_cents, count)
    update_totals(grand_totals['total']['total'], amount_cents, count)
    if PaymentMethod.written_off_invoice.id == payment_method_id
      update_totals(income_data[:written_off_invoices]['total']['donations'], amount_cents, count)
      update_totals(income_data[:written_off_invoices]['total']['total'], amount_cents, count)
    end
  end

  def add_sale_summation_to_data(summation, income_data, ranges)
    payment_method_id, sale_type, amount_cents, count, mn, mx = summation['payment_method_id'].to_i, summation['sale_type'], summation['amount'].to_i, summation['count'].to_i, summation['min'].to_i, summation['max'].to_i
    return unless payment_method_id and payment_method_id != 0

    ranges[:thrift_store][:min] = [ranges[:thrift_store][:min], mn].min
    ranges[:thrift_store][:max] = [ranges[:thrift_store][:max], mx].max

    payment_method = PaymentMethod.descriptions[payment_method_id]

    grand_totals = income_data[:grand_totals]
    column = income_data[:thrift_store][payment_method]
    update_totals(column[sale_type], amount_cents, count)
    update_totals(column['subtotals'], amount_cents, count)
    if PaymentMethod.is_real_method?(payment_method_id)
      total_real = income_data[:thrift_store]['real total']
      update_totals(total_real[sale_type], amount_cents, count)
      update_totals(total_real['subtotals'], amount_cents, count)
      update_totals(grand_totals['real total']['total'], amount_cents, count)
    end
    if PaymentMethod.is_money_method?(payment_method_id)
      total_real = income_data[:thrift_store]['register total']
      update_totals(total_real[sale_type], amount_cents, count)
      update_totals(total_real['subtotals'], amount_cents, count)
      update_totals(grand_totals['register total']['total'], amount_cents, count)
    end
    if PaymentMethod.is_till_method?(payment_method_id)
      till_total = income_data[:thrift_store]['till total']
      update_totals(till_total[sale_type], amount_cents, count)
      update_totals(till_total['subtotals'], amount_cents, count)
      update_totals(grand_totals['till total']['total'], amount_cents, count)
    end
    totals = income_data[:thrift_store]['total']
    update_totals(totals[sale_type], amount_cents, count)
    update_totals(totals['subtotals'], amount_cents, count)
    update_totals(grand_totals['total']['total'], amount_cents, count)
    update_totals(grand_totals[payment_method]['total'], amount_cents, count)
    if PaymentMethod.written_off_invoice.id == payment_method_id
      update_totals(income_data[:written_off_invoices]['total']['sales'], amount_cents, count)
      update_totals(income_data[:written_off_invoices]['total']['total'], amount_cents, count)
    end
  end

  def update_totals(totals, amount, count)
    totals[:total] += amount
    totals[:count] += count
  end

  ########################
  ### Volunteer report ###
  ########################

  protected

  def common_hours
    if !params[:action].match(/_report/)
      @defaults = Conditions.new
      @defaults.contact_enabled = "true"
    end
    render :action => "volunteers"
  end

  def pre_common_hours_report
    @defaults = Conditions.new
    if params[:contact] || params[:contact_id]
      contact_id = (params[:contact_id] || params[:contact][:id])
      params[:defaults] ||= {:contact_enabled=>"true"}
      params[:defaults][:contact_id] = contact_id
    end

    @defaults.apply_conditions(params[:defaults])
    @contact = @defaults.contact
    @date_range_string = @defaults.to_s
  end

  def common_hours_report
    pre_common_hours_report

    if @defaults.valid?
      @tasks = @klass.find_by_conditions(@defaults.conditions(@klass))
      @data = volunteer_report_for(@tasks, @sections)
    end
    render :action => "volunteers_report"
  end


  public

  def staff_hours
    @title = "Jobs report"
    if has_required_privileges('/worker_condition')
      @filters = ['worker', 'worker_type']
    end
    common_hours
  end

  def volunteers
    @title = "Volunteers task types report"
    @filters = ['program_id', 'contact_type']
    if has_required_privileges('/contact_condition')
      @filters << 'contact'
    end
    common_hours
  end

  def staff_hours_report
    @sections = [:job, :income_stream, :wc_category, :program]
    @hours_type = "staff"
    @klass = WorkedShift
    if has_required_privileges('/worker_condition')
      @filters = ['worker', 'worker_type']
    end
    common_hours_report
  end

  def volunteers_report
    @sections = [:community_service_type, :volunteer_task_types]
    @hours_type = "volunteer"
    @klass = VolunteerTask
    @filters = ['program_id', 'contact_type']
    if has_required_privileges('/contact_condition')
      @filters << 'contact'
    end
    common_hours_report
  end

  protected

  def volunteer_report_for(tasks, sections)
    data = {}
    sections.each {|section|
      data[section] = {}
      eval((section).to_s.classify).find(:all).each {|type|
        data[section][type.to_s] = 0.0
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
    sections.each do |section|
      data[section][(task[section.to_s] || '(none)')] += task['duration'].to_f
      data[section]["Total"] ||= 0.0
      data[section]["Total"] += task['duration'].to_f
    end
  end

  public

  def hours
    if has_required_privileges('/contact_condition')
      @filters = ['contact']
    end
    common_hours
  end

  def hours_report
    pre_common_hours_report
    # if this is too slow, replace it with straight sql
    @tasks = VolunteerTask.find(:all,
                                :conditions => @defaults.conditions(VolunteerTask),
                                :order => "date_performed desc")

  end
end
