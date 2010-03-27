module HtmlHelper
  # due to prototype suckness, 'extend' may not be used as a choice name.
  def select_visibility(obj_name, method_name, choices = [])
    #:TODO: scrub this first
    obj = eval( "@#{obj_name}" )

    # type choice
    display = %Q{ <div class="form-element"> %s %s </div> } %
      [ select( obj_name, method_name, choices.map {|k,v| [k.to_s.gsub(/_/, ' '), k.to_s]} ),
        observe_field( "#{obj_name}_#{method_name}",
                       :function => "select_visibility('#{obj_name}', '#{method_name}', new Array(\"#{choices.map {|k,v| k.to_s }.join('", "')}\"), value);",
                       :with => method_name )]

    this_choice = obj.send(method_name)
    choices.each {|choice, content|
      if this_choice.to_s == choice.to_s
        visibility = ''
      else
        visibility = 'style="display:none;"'
      end
      display += %Q{ <div id="%s_%s_choice" class="form-element" %s>%s</div> } % [ obj_name, choice.to_s, visibility, content ]
    }

    display += javascript_tag("select_visibility('#{obj_name}', '#{method_name}', new Array(\"#{choices.map {|k,v| k.to_s}.join('", "')}\"), $('#{obj_name}_#{method_name}').value);")
    return display
  end

  def multiselect_of_form_elements(obj_name, choices = {})
    html = "<div id='#{obj_name}_container' class='conditions'>"
    for condition in choices.keys do
      html += hidden_field(obj_name, condition + "_enabled")
    end
    if choices.length > 1
      choice_names = { }
      choices.each {|k,v| choice_names[k] = (k).titleize}
      js = update_page do |page|
        page << "list_of_conditions = $H(#{choices.to_json});"
        page << "condition_display_names = $H(#{choice_names.to_json});"
        page.insert_html(:bottom, obj_name + "_container",
                         :partial => 'helpers/multiselection_header',
                         :locals => {:obj_name => obj_name})
        for condition in choices.keys do
          page.insert_html(:bottom, obj_name + "_adder",
                           '<option id="%s_%s_option" value="%s">%s</option>' %
                           [obj_name, condition, condition, (condition).titleize])
          page << "if($('#{obj_name}_#{condition}_enabled').value == 'true'){add_condition('#{obj_name}', '#{condition}');}"
        end
      end
      js += "$('#{obj_name}_nil').selected = true;"
    elsif choices.length == 1
      html += choices.values.first
      js = "$('#{obj_name}_#{choices.keys.first}_enabled').value = 'true'"
    else
      html += ""
      js = ""
    end
    html += "</div>"
    return html + javascript_tag(js)
  end

  # the object named "@#{obj_name}" must be able to respond to all the
  # fields listed below, or you should provide alternate fieldnames.
  def date_or_date_range_picker(obj_name, field_name)
    date_types = []
    obj = eval( "@#{obj_name}" )

    # daily
    date_types << ['daily', calendar_box(obj_name, field_name + '_date',{},{:showOthers => true})]
    # monthly
    date_types << ['monthly', select_month(obj.send(field_name + '_month'), :field_name => field_name + '_month', :prefix => obj_name) +
                   select_year(obj.send(field_name + '_year'), :prefix => obj_name, :field_name => field_name + '_year', :start_year => 2000, :end_year => Date.today.year)]
    # arbitrary
    date_types << ['arbitrary', "From: %s To: %s" %
                   [ calendar_box(obj_name, field_name + '_start_date',{},{:showOthers => true}),
                     calendar_box(obj_name, field_name + '_end_date',{},{:showOthers => true}) ]]

    return select_visibility(obj_name, field_name + '_date_type', date_types)
  end
end
