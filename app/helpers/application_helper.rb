# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  class Column
    def initialize(klass, opts)
      raise "bad constructor: needs a name" unless opts.has_key? :name
      @klass = klass
      @opts = opts
    end

    def eval
      @opts[:eval] || "#{Inflector.underscore(@klass)}.#{@opts[:name]}"
    end

    def name
      @opts[:name]
    end

    def class_name
      @klass.to_s
    end

    def sanitize?
      true
    end

    def sortable?
      @opts[:sortable] || false
    end

    def label
      @opts[:label] || Inflector.titleize(@opts[:name])
    end
  end

  def num_columns
    columns.length + 1
  end

  def contact_field(obj_name, field_name, options = {})
    options[:locals] ||= {}
    options[:locals][:options] ||= {}
    obj = instance_variable_get(obj_name)
    if(obj && obj.respond_to?(field_name))
      options[:locals][:contact] = obj.send(field_name)
    end
    render(options.merge({:partial => 'contacts/search'}))
  end

  def contact_object_name(options)
    options[:object_name] || "contact"
  end

  def contact_field_name(options)
    options[:field_name] || "id"
  end

  def contact_messages_id(options)
    contact_element_prefix(options) + '_contact_messages_id'
  end

  def contact_new_contact_link(options)
    contact_element_prefix(options) + "_new_contact_link"
  end

  def contact_searchbox_id(options)
    "#{@transaction_type||'foo'}_contact_searchbox"
  end

  def searchbox_display_id(options)
    contact_element_prefix(options) + '_searchbox_display_id'
  end

  def content_id(o = {})
    'content'
  end

  def component_id(o = {})
    'component'
  end

  def form_tbody_id(options)
    "#{@transaction_type||'foo'}_form_tbody"
  end

  # due to prototype suckness, 'extend' may not be used as a choice name.
  def select_visibility(obj_name, method_name, choices = {})
    #:TODO: scrub this first
    obj = eval( "@#{obj_name}" )

    js_observe_fuct = 'var choices = new Array("%s");' % choices.keys.map {|k| k.to_s}.join('", "')
    js_observe_fuct += "for( var i = 0; i < choices.length; i++)"
    js_observe_fuct += "{var choice = choices[i]; if(choice == 'extend') {}"
    js_observe_fuct += "else if(choice == value) {$('#{obj_name}_' + choice + '_choice').show();}"
    js_observe_fuct += "else {$('#{obj_name}_' + choice + '_choice').hide();} }"

    # type choice
    display = %Q{ <div class="form-element"> %s %s </div> } %
      [ select( obj_name, method_name, choices.keys.map {|k| [k.to_s.gsub(/_/, ' '), k.to_s]} ),
        observe_field( "#{obj_name}_#{method_name}",
                       :function => js_observe_fuct,
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

    return display
  end

  def multiselect_of_form_elements(obj_name, choices = {})
    html = "<div id='#{obj_name}_container' class='conditions'>"
    for condition in choices.keys do
      html += hidden_field(obj_name, condition + "_enabled")
    end
    if choices.length > 1
      choice_names = { }
      choices.each {|k,v| choice_names[k] = Inflector.titleize(k)}
      js = update_page do |page|
        page << "list_of_conditions = $H(#{choices.to_json});"
        page << "condition_display_names = $H(#{choice_names.to_json});"
        page.insert_html(:bottom, obj_name + "_container",
                         :partial => 'helpers/multiselection_header',
                         :locals => {:obj_name => obj_name})
        for condition in choices.keys do
          page.insert_html(:bottom, obj_name + "_adder",
                           '<option id="%s_%s_option" value="%s">%s</option>' %
                             [obj_name, condition, condition, Inflector.titleize(condition)])
          page << "if($('#{obj_name}_#{condition}_enabled').value == 'true'){add_condition('#{obj_name}', '#{condition}');}"
        end
      end
    else
      html += choices.values.first
      js = "$('#{obj_name}_#{choices.keys.first}_enabled').value = 'true'"
    end
    html += "</div>"
    return html + javascript_tag(js)
  end

  # the object named "@#{obj_name}" must be able to respond to all the
  # fields listed below, or you should provide alternate fieldnames.
  def date_or_date_range_picker(obj_name, fields = {})
    date_types = {}
    obj = eval( "@#{obj_name}" )
    fields = { :date => 'date',
      :start_date => 'start_date', :end_date => 'end_date',
      :month => 'month', :year => 'year',
      :date_type => 'date_type' }.merge(fields)

    # daily
    date_types['daily'] = calendar_box(obj_name, fields[:date],{},{:showOthers => true})
    date_types['monthly'] = select_month(obj.send(fields[:month]), :prefix => obj_name) +
      select_year(obj.send(fields[:year]), :prefix => obj_name)
    # arbitrary
    date_types['arbitrary'] = "From: %s To: %s" %
      [ calendar_box(obj_name, fields[:start_date],{},{:showOthers => true}),
        calendar_box(obj_name, fields[:end_date],{},{:showOthers => true}) ]

    return select_visibility(obj_name, fields[:date_type], date_types)
  end

  def time_or_time_range_picker(obj_name, fields)
    #:TODO: ?
  end

  def my_lightwindow_tag(options, html_options = {})
    %Q[<a href="#{url_for(options[:url])}" class="#{html_options[:class]} lightwindow" onclick="return false"
          id="#{options[:id]}" params="lightwindow_type=#{options[:type] || 'page'}">
         #{options[:content]}
       </a>] +
      javascript_tag("if(myLightWindow) {myLightWindow._processLink($('#{options[:id]}'))};")
  end

  def contact_element_prefix(options)
    options[:element_prefix] or 'contact'
  end

  def contact_query_id(options)
    options[:contact_query_id] ||
      (
        contact_object_name(options) + "_" + contact_field_name(options)
      )
  end

  def contact_edit_link_id(options)
    contact_element_prefix(options) + "_edit_link"
  end

  def search_results_id(options)
    contact_element_prefix(options) + '_search_results_id'
  end

  def messages_id(options)
    "#{@transaction_type||'foo'}-messages"
  end

  def empty_message_id(options)
    "#{@transaction_type||'foo'}-empty-message"
  end

  def formated_value(value, sanitize = true)
    if value_empty?(value)
      empty_text
    elsif value.instance_of? Time
        format_time(value)
    elsif value.instance_of? Date
      format_date(value)
    else
      sanitize ? h(value.to_s) : value.to_s
    end
  end

    def value_empty?(value)
      value.nil? || (value.empty? rescue false)
    end

    def empty_text
      "-"
    end

  def column_sort_direction(column_name, params)
    if column_name && column_name == current_sort(params)
      current_sort_direction(params) == "asc" ? "desc" : "asc"
    else
      "asc"
    end
  end

  def current_sort(params)
    'asc'
  end

  def column_header_id(options)
    "#{@transaction_type||'foo'}-#{options[:column_name]}-column"
  end

  def tbody_id(options)
    "#{@transaction_type||'foo'}-tbody"
  end

  def loading_indicator_id(prefix)
    "#{prefix||'foo'}_loading_indicator_id"
  end

  def loading_indicator_tag(prefix)
    %Q[<span style="display:none" id="#{loading_indicator_id(prefix)}"><img src="/images/indicator.gif" alt="loading..."></img></span>]
  end

  def is_logged_in()
    @current_user
  end

  def is_me?(contact_id)
    @current_user and @current_user.contact_id == contact_id
  end

  def has_role?(*roles)
    @current_user and @current_user.has_role?(*roles)
  end

  def has_role_or_is_me?(contact_id, *roles)
    has_role?(*roles) or is_me?(contact_id)
  end

  def custom_change_observer(element, handler)
    custom_observer(element, handler, 'change')
  end

  def custom_observer(element, handler, *event_types)
    ident = Time.now.to_f.to_s.gsub(/[^0-9]/, '')
    js = "
      var elem_#{ident} = $('#{element}');
      handler = function(event) {
        var element = elem_#{ident};
        Event.extend(event);
        #{handler}
      };"
    event_types.each {|event_type|
      js += "if(elem_#{ident}) {elem_#{ident}.addEventListener('#{event_type}', handler, false);} else {alert('#{element} not found!')}"
    }
    javascript_tag(js)
  end

  def edit_link(link_id, options, form_id = nil)
    make_link(link_id,
              image_tag("edit.png", :alt => "edit", :title => "edit"),
              options,
              form_id)
  end

  def delete_link(link_id, options, form_id = nill)
    make_link(link_id,
              image_tag("remove.png", :alt => "delete", :title => "delete"),
              options,
              form_id)
  end

  def make_link(link_id, image_tag, options, form_id = nil)
    html = %Q[
      <a id="#{link_id}"
         onclick="return false">
        #{image_tag}
      </a>
    ]
    ify = form_id ? "form_has_not_been_edited('#{form_id}') ||" : ""
    html += custom_observer(link_id,
                            "if(#{ify} confirm('Current entry form will be lost.  Continue?')) {
                                 #{remote_function(options)}
                             }",
                            'click')
    return html
  end

  def show_errors_for(name, object, page)
    object.attributes.each {|field,value|
      unless object.errors[field]
        page << "if($('#{name}_#{field}')) {$('#{name}_#{field}').removeClassName('fieldWithErrors')}"
      end
    }
    object.errors.each {|field, msg|
      page << "if($('#{name}_#{field}')) {$('#{name}_#{field}').addClassName('fieldWithErrors')}"
    }
  end
end
