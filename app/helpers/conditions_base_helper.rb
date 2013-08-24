module ConditionsBaseHelper
  def conditions_html(params_key = "conditions", these_things = [], klass = Conditions, multiselect_mode = "auto", date_range = nil, enable_advanced = false, hide_end_text = false)
    @conditions_internal_date_range = date_range
    hash = {}
    obj = eval("@#{params_key}") || klass.new
    end_text = hide_end_text ? "" : simple_end_text
    these_things.each{|x|
      if klass::DATES.include?(x)
        hash[x] = date_or_date_range_picker(params_key, x)
      elsif klass::CONDS.include?(x)
        hash[x] = ""
        hash[x] = eval("html_for_" + x + "_condition(params_key)")
      else
        raise "Unknown condition: #{x}"
      end
      hash[x] = "<div style=\"display: inline-block; float: left;\">" + label_tag("#{params_key}[#{x}_excluded]", "Exclude?") + check_box_tag("#{params_key}[#{x}_excluded]", "#{x}_excluded", obj.send("#{x}_excluded")) + "</div>" + hash[x] unless Conditions::CHECKBOXES.include?(x) or x == "empty" or multiselect_mode == "force"
    }
    if enable_advanced
      return multiselect_of_form_elements(params_key, hash, multiselect_mode) + conditions_radio_button(params_key, obj, these_things, multiselect_mode) + hide_forced_conds(params_key, obj, these_things, multiselect_mode) + end_text
    else
      return multiselect_of_form_elements(params_key, hash, multiselect_mode) + hide_forced_conds(params_key, obj, these_things, multiselect_mode) + end_text
    end
  end

  def simple_end_text
'<div>
[Note: % can be used as a wildcard for most text-based search conditions, for example "Test%" finds anything begining with Test.]
</div>
'
  end

  def hide_forced_conds(params_key, obj, these_things, mmode)
    return "" unless mmode == 'force' or these_things.length <= 1
    these_things.map do |thing|
      "<input name=\"#{params_key}[forced_list][#{thing}]\" type=\"hidden\" value=\"1\" />"
    end.join("")
  end

  def conditions_radio_button(params_key, obj, these_things, mmode)
    return "" if mmode == 'force' or these_things.length <= 1
    mode = obj.send('mode')
    "<div style=\"padding: 5px; float: left; clear: left;\">Show results matching: "+ label_tag("#f{params_key}_mode_and", "all conditions", {:style => "display: inline-block;"})  + radio_button_tag("#{params_key}[mode]", "AND", mode != "OR")  + label_tag("#{params_key}_mode_or", "at least one condition", {:style => "display: inline-block;"})+ radio_button_tag("#{params_key}[mode]", "OR", mode == "OR") + "</div>"
  end
end
