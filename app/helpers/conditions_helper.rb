module ConditionsHelper
  include ConditionsBaseHelper

  private

  def html_for_organization_name_condition(params_key)
    text_field(params_key, 'organization_name')
  end

  def html_for_processor_product_condition(params_key)
    text_field(params_key, 'processor_product')
  end

  def html_for_worker_type_condition(params_key)
    select(params_key, "worker_type_id", WorkerType.find(:all).sort_by(&:name).collect {|p| [ p.name, p.id ] })
  end

  def html_for_sale_type_condition(params_key)
    select(params_key, "sale_type_id", SaleType.find(:all).sort_by(&:description).collect {|p| [ p.description, p.id ] })
  end

  def html_for_program_id_condition(params_key)
    select(params_key, "program_id", Program.find_all_by_volunteer(true).sort_by(&:description).collect {|p| [ p.description, p.id ] })
  end

  def html_for_finalized_condition(params_key)
    ""
  end

  def html_for_assigned_condition(params_key)
    ""
  end

  def html_for_needs_checkin_condition(params_key)
    ""
  end

  def html_for_store_credit_redeemed_condition(params_key)
    ""
  end

  def html_for_cancelled_condition(params_key)
    "<div style=\"display: inline-block;\">Show cancelled shifts: " + check_box(params_key, "cancelled") + "</div>"
  end

  def html_for_schedule_condition(params_key)
    (select params_key, :schedule_id, Schedule.find(:all, :order => "generate_from != 't', name").collect {|c| [c.full_name, c.id] })
  end

  attr_accessor :multi_enabled

  def html_for_worker_condition(params_key)
    show_all = false
    if @conditions_internal_date_range and !show_all
      workers = Worker.effective_in_range(*@conditions_internal_date_range)
    else
      workers = Worker.find(:all).select{|x| show_all or x.effective_now?}
    end
    select(params_key, "worker_id", workers.sort_by(&:name).collect {|p| [ p.name, p.id ] }, {}, _multi_html_opts.merge(:onkeyup => "magic_onkeyscroll(event);"))
  end

  def _multi_html_opts
    @multi_enabled ? {:multiple=> (!!@multi_enabled), :size => 7} : {}
  end

  def html_for_job_condition(params_key)
    show_all = false
    if @conditions_internal_date_range and !show_all
      jobs = Job.effective_in_range(*@conditions_internal_date_range)
    else
      if show_all
        jobs = Job.find(:all)
      else
        jobs = Job.effective_on(Date.today)
      end
    end
    select(params_key, "job_id", jobs.sort_by(&:name).collect {|p| [ p.name, p.id ] }, {}, _multi_html_opts.merge(:onkeyup => "magic_onkeyscroll(event);"))
  end

  def html_for_form_factor_condition(params_key)
    form_factors = ['Other', '2.5"', '3.5"']
    select(params_key, "form_factor", form_factors.collect {|p| [ p, p ] })
  end

  def html_for_attendance_type_condition(params_key)
    select(params_key, "attendance_type_id", AttendanceType.find(:all).sort_by(&:name).collect {|p| [ p.name, p.id ] })
  end

  def html_for_weekday_condition(params_key)
    return Weekday.find(:all).sort_by(&:id).collect{|p| [p.name, p.id]}.map{|x| '<div style="padding: 10px; display: inline-block; float: left;' + (x.last == 0 ? " clear: left;" : "") + '">' + label(params_key, "weekday_id[#{x.last}]", x.first) + check_box(params_key, "weekday_id", {:id => params_key + "_weekday_id[#{x.last}]"}, x.last, "") + '</div>'}.join("")
    select(params_key, "weekday_id", Weekday.find(:all).sort_by(&:id).collect{|p| [p.name, p.id]}, {}, _multi_html_opts)
  end

  def html_for_roster_condition(params_key)
    select(params_key, "roster_id", Roster.find(:all).sort_by(&:name).collect{|p| [ p.name, p.id ]}, {}, _multi_html_opts)
  end

  def html_for_sked_condition(params_key)
    select(params_key, "sked_id", Sked.find(:all).sort_by(&:name).collect{|p| [ p.to_s, p.id ]})
  end

  def html_for_volunteer_task_type_condition(params_key)
    select(params_key, "volunteer_task_type_id", VolunteerTaskType.find(:all).sort_by(&:name).collect {|p| [ p.description, p.id ] }, {}, _multi_html_opts)
  end

  def html_for_can_login_condition(params_key)
    ""
  end

  def html_for_empty_condition(params_key)
    ""
  end

  def html_for_contribution_condition(params_key)
    ""
  end

  def html_for_role_condition(params_key)
    collection_select(params_key, "role", Role.find(:all), "id", "name")
  end

  def html_for_action_condition(params_key)
    collection_select(params_key, "action", Action.find(:all), "id", "description")
  end

  def html_for_type_condition(params_key)
    collection_select(params_key, "type_id", Type.find(:all), "id", "description")
  end

  def html_for_volunteered_hours_in_days_condition(params_key)
    label(params_key, 'volunteer_hours_minimum', "Minimum number of hours volunteered (enter 0 for any):") +
    text_field(params_key, 'volunteer_hours_minimum') +
    label(params_key, 'volunteer_hours_minimum', "Within number of days:") +
    text_field(params_key, 'volunteer_hours_days')
  end

  def html_for_volunteered_non_court_hours_in_days_condition(params_key)
    label(params_key, 'volunteer_non_court_hours_minimum', "Minimum number of non-court hours volunteered (enter 0 for any):") +
    text_field(params_key, 'volunteer_non_court_hours_minimum') +
    label(params_key, 'volunteer_non_court_hours_minimum', "Within number of days:") +
    text_field(params_key, 'volunteer_non_court_hours_days')
  end

  def html_for_id_condition(params_key)
    text_field(params_key, 'id')
  end

  def html_for_serial_number_condition(params_key)
    text_field(params_key, 'serial_number')
  end

  def html_for_contact_type_condition(params_key)
    collection_select(params_key, "contact_type", ContactType.find(:all), "id", "description")
  end

  def html_for_needs_attention_condition(params_key)
    ""
  end

  def html_for_anonymous_condition(params_key)
    ""
  end

  def html_for_unresolved_invoices_condition(params_key)
    ""
  end

  def html_for_unresolved_shipment_condition(params_key)
    ""
  end

  def html_for_payment_method_condition(params_key)
    render( :partial => 'transaction/payment_method_select',
            :locals => {:field_id_prefix => params_key,
              :field_name_prefix => params_key,
              :hide_empty => true,
              :show_label => false,
              :paid_object => eval("@" + params_key)} )
  end

  def html_for_payment_amount_condition(params_key)
    select_visibility(
                      params_key,
                      'payment_amount_type',
                      [['exact', text_field(params_key, 'payment_amount_exact')],
                       ['between', "%s to %s" % [text_field(params_key, 'payment_amount_low'),
                                                 text_field(params_key, 'payment_amount_high')]],
                       ['>=', text_field(params_key, 'payment_amount_ge')],
                       ['<=', text_field(params_key, 'payment_amount_le')],
                      ])
  end

  def html_for_payment_total_condition(params_key)
    select_visibility(
                      params_key,
                      'payment_total_type',
                      [['exact', text_field(params_key, 'payment_total_exact')],
                       ['between', "%s to %s" % [text_field(params_key, 'payment_total_low'),
                                                 text_field(params_key, 'payment_total_high')]],
                       ['>=', text_field(params_key, 'payment_total_ge')],
                       ['<=', text_field(params_key, 'payment_total_le')],
                      ])
  end

  def html_for_gizmo_type_id_condition(params_key)
    select(params_key, 'gizmo_type_id', GizmoType.find(:all).sort_by(&:description).collect(){|x|[x.description, x.id]}, {}, _multi_html_opts)
  end

  def html_for_gizmo_context_id_condition(params_key)
    select(params_key, 'gizmo_context_id', GizmoContext.find(:all).select(&:has_system?).sort_by(&:description).collect(){|x|[x.description, x.id]}, {})
  end

  def html_for_gizmo_type_group_id_condition(params_key)
    select(params_key, 'gizmo_type_group_id', GizmoTypeGroup.find(:all).sort_by(&:name).collect(){|x|[x.name + " (" + x.gizmo_type_list + ")", x.id]}, {}, _multi_html_opts)
  end

  def html_for_gizmo_category_id_condition(params_key)
    select(params_key, 'gizmo_category_id', GizmoCategory.find(:all).sort_by(&:description).collect(){|x|[x.description, x.id]})
  end

  def html_for_disbursement_type_id_condition(params_key)
    select(params_key, 'disbursement_type_id', DisbursementType.find(:all).sort_by(&:description).collect(){|x|[x.description, x.id]}, {}, _multi_html_opts)
  end

  def html_for_store_credit_id_condition(params_key)
    text_field(params_key, 'store_credit_id')
  end

  def html_for_covered_condition(params_key)
    ""
  end

  def html_for_postal_code_condition(params_key)
    text_field(params_key, 'postal_code')
  end

  def html_for_city_condition(params_key)
    text_field(params_key, 'city')
  end

  def html_for_phone_number_condition(params_key)
    text_field(params_key, 'phone_number')
  end

  def html_for_organization_condition(params_key)
    ""
  end

  def html_for_logged_in_within_condition(params_key)
    text_field(params_key, 'logged_in_within', :size => 3) + " month(s)"
  end

  def html_for_is_pickup_condition(params_key)
    ""
  end

  def html_for_contact_condition(params_key)
    if has_required_privileges('/contact_condition_everybody')
      contact_field('@' + params_key, 'contact_id',
                    :locals => {:options =>
                      {
                        :object_name => params_key,
                        :field_name => 'contact_id',
                        :element_prefix => 'filter_contact',
                        :display_edit => false,
                        :display_create => false,
                        :show_label => false,
                      },
                      :contact => eval("@" + params_key).nil? ? nil : eval("@" + params_key).contact
                    } )
    elsif has_privileges("has_contact")
      "Me" + hidden_field(params_key, 'contact_id', :value => @current_user.contact_id)
    else
      raise
    end
  end

  def html_for_volunteer_hours_condition(params_key)
    select_visibility(
                      params_key,
                      'volunteer_hours_type',
                      [['exact', text_field(params_key, 'volunteer_hours_exact')],
                       ['between', "%s to %s" % [text_field(params_key, 'volunteer_hours_low'),
                                                 text_field(params_key, 'volunteer_hours_high')]],
                       ['>=', text_field(params_key, 'volunteer_hours_ge')],
                       ['<=', text_field(params_key, 'volunteer_hours_le')],
                      ])
  end

  def html_for_megabytes_size_condition(params_key)
    select_visibility(
                      params_key,
                      'megabytes_size_type',
                      [['exact', text_field(params_key, 'megabytes_size_exact')],
                       ['between', "%s to %s" % [text_field(params_key, 'megabytes_size_low'),
                                                 text_field(params_key, 'megabytes_size_high')]],
                       ['>=', text_field(params_key, 'megabytes_size_ge')],
                       ['<=', text_field(params_key, 'megabytes_size_le')],
                      ]) +
      select(params_key, "megabytes_size_units", Conditions::MEGABYTES_UNITS.to_a.sort_by(&:last).collect {|p| [ p.first, p.first ] })
  end

  def html_for_hard_drive_serial_number_condition(params_key)
    text_field(params_key, 'hard_drive_serial_number')
  end

  def html_for_result_condition(params_key)
    collection_select(params_key, "result", ['PASSED', 'FAILED', 'ABORTED', 'STOPPED', 'UNTESTED'].sort, "to_s", "to_s")
  end

  def html_for_interface_type_condition(params_key)
    collection_select(params_key, "interface_type", ['IDE', 'SATA', 'SCSI'], "to_s", "to_s")
  end

  def html_for_vendor_condition(params_key)
    text_field(params_key, 'vendor')
  end

  def html_for_model_condition(params_key)
    text_field(params_key, 'model')
  end

  def html_for_email_condition(params_key)
    text_field(params_key, 'email')
  end

  def html_for_flagged_condition(params_key)
    ""
  end

  def html_for_system_condition(params_key)
    text_field(params_key, 'system_id')
  end

  def html_for_contract_condition(params_key)
    collection_select(params_key, "contract_id", Contract.usable, "id", "description")
  end

  def html_for_created_by_condition(params_key)
    collection_select(params_key, "created_by", [User.new, User.find(:all).sort_by(&:login)].flatten, "id", "login")
  end

  def html_for_signed_off_by_condition(params_key)
    collection_select(params_key, "signed_off_by", [User.new, (Privilege.find_by_name('sign_off_spec_sheets').roles + Role.find_by_name('ADMIN').to_a).collect{|x| x.users}.flatten.uniq.select{|x| x.can_login}.sort_by{|x| x.contact_display_name.downcase}].flatten, "id", "contact_display_name")
  end

  def html_for_shift_type_condition(params_key)
    collection_select(params_key, "shift_type", ['StandardShift', 'Meeting', 'Unavailability'], "to_s", "to_s")
  end

  def html_for_updated_by_condition(params_key)
    collection_select(params_key, "updated_by", [User.new, User.find(:all).sort_by(&:login)].flatten, "id", "login")
  end

  def html_for_cashier_updated_by_condition(params_key)
    collection_select(params_key, "cashier_updated_by", [User.new, User.find(:all).sort_by(&:login)].flatten, "id", "login")
  end

  def html_for_cashier_created_by_condition(params_key)
    collection_select(params_key, "cashier_created_by", [User.new, User.find(:all).sort_by(&:login)].flatten, "id", "login")
  end
end
