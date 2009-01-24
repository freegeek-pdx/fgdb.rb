module ConditionsHelper
  def conditions_html(params_key = "conditions", these_things = nil)
    hash = {}
    Conditions::CONDS.select{|x| these_things.include?(x)}.each{|x|
      if Conditions::DATES.include?(x)
        hash[x] = date_or_date_range_picker(params_key, x)
      else
        hash[x] = eval("html_for_" + x + "_condition(params_key)")
      end
    }
    multiselect_of_form_elements(params_key, hash)
  end

  def html_for_id_condition(params_key)
    text_field(params_key, 'id')
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

  def html_for_payment_method_condition(params_key)
    render( :partial => 'transaction/payment_method_select',
            :locals => {:field_id_prefix => params_key,
              :field_name_prefix => params_key,
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

  def html_for_gizmo_type_id_condition(params_key)
    select(params_key, 'gizmo_type_id', GizmoType.find(:all).sort_by(&:description).collect(){|x|[x.description, x.id]})
  end

  def html_for_covered_condition(params_key)
    check_box(params_key, 'covered')
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

  def html_for_contact_condition(params_key)
    if has_role?('CONTACT_MANAGER', 'VOLUNTEER_MANAGER', 'FRONT_DESK')
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
                      :contact => eval("@" + params_key).contact
                    } )
    elsif is_logged_in() && @current_user.contact_id
      "Me" + hidden_field('defaults', 'contact_id', :value => @current_user.contact_id)
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
    collection_select(params_key, "created_by", [User.new, User.find(:all)].flatten, "id", "login")
  end

  def html_for_cashier_created_by_condition(params_key)
    collection_select(params_key, "cashier_created_by", [User.new, User.find(:all)].flatten, "id", "login")
  end
end
