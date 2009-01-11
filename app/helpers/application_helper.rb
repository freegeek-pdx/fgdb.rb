# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def coveredness_enabled
    Default["coveredness_enabled"] == "1"
  end

  # ajax crap, copied from ajax/active scaffold while in the process of getting rid of active scaffold -->

  def generate_temporary_id
    (Time.now.to_f*1000).to_i.to_s
  end

  def element_row_id(options)
    "#{options[:scaffold_id]}-#{options[:action]}-#{options[:id]}-row"
  end

  def element_cell_id(options)
    "#{options[:scaffold_id]}-#{options[:action]}-#{options[:id]}-cell"
  end

  def element_form_id(options)
    "#{options[:scaffold_id]}-#{options[:action]}-#{options[:id]}-form"
  end

  def element_messages_id(options)
    "#{options[:scaffold_id]}-#{options[:action]}-#{options[:id]}-messages"
  end

  def format_date(date)
    format = ActiveSupport::CoreExtensions::Date::Conversions::DATE_FORMATS[:default] || "%m/%d/%Y"
    date.strftime(format)
  end

  def format_time(time)
    format = ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS[:default] || "%m/%d/%Y %I:%M %p"
    time.strftime(format)
  end

  # end of ajax crap

  class Column
    def initialize(klass, opts)
      raise "bad constructor: needs a name" unless opts.has_key? :name
      @klass = klass
      @opts = opts
    end

    def eval
      @opts[:eval] || "#{(@klass).to_s.underscore}.#{@opts[:name]}"
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
      @opts[:label] || (@opts[:name]).titleize
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
    else
      html += choices.values.first
      js = "$('#{obj_name}_#{choices.keys.first}_enabled').value = 'true'"
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

  def show_loading_indicator(prefix)
    "Element.show('#{loading_indicator_id(prefix)}');"
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

  def new_edit_link(link_id, options, form_id = nil)
    new_make_link(link_id,
                  image_tag("edit.png", :alt => "edit", :title => "edit", :class => "image-link"),
                  options,
                  form_id)
  end

  def new_delete_link(link_id, options, form_id = nill)
    new_make_link(link_id,
                  image_tag("remove.png", :alt => "delete", :title => "delete", :class => "image-link"),
                  options,
                  form_id)
  end

  def new_make_link(link_id, image_tag, options, form_id = nil)
    ify = form_id ? "form_has_not_been_edited('#{h form_id}') ||" : ""
    html = %Q[
      <a id="#{link_id}" href="#{h options[:url][:controller]}/#{h options[:url][:action]}/#{h options[:url][:id]}#{h options[:url][:return_to_search]=='true' ? '?return_to_search=true' : ''}"
         onclick="if(#{h ify} confirm('Current entry form will be lost.  Continue?')) {
                                 #{h remote_function(options)}
                             }">
        #{image_tag}
      </a>
    ]
    return html
  end

  def show_errors_for(name, object, page)
    page << "array = $$('.fieldWithErrors'); for (var count = 0; count < array.length; count++) {array[count].removeClassName('fieldWithErrors')}"
    object.errors.each {|field, msg|
      page << "if($('#{name}_#{field}')) {$('#{name}_#{field}').addClassName('fieldWithErrors')}"
    }
  end
end
