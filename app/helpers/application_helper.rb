# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  # I'm stupid. :P
  def render_thing(a)
    render :inline => File.read(File.join(RAILS_ROOT, "app", "views", params[:controller], "#{a}.html.erb"))
  end

  def link_for_my_links(str)
    if str.match(/^(.*)@LINK@(.*)@PARAMS@(.*)@ENDLINK@(.*)$/)
      before = $1
      name = $2
      params = eval($3)
      after = $4
      return before + link_to(name, params) + after
    else
      return str
    end
  end

  def gt_for_txn(thing)
    [GizmoType.new(:id=>1, :description=>"pick a gizmo")] + thing.showable_gizmo_types
  end

  def save_exception_data(e)
    exception_data = process_exception_data(e)
    tempfile = `mktemp -p #{File.join(RAILS_ROOT, "tmp", "crash")} crash.XXXXXX`.chomp
    crash_id = tempfile.match(/^.*\.([^.]+)$/)[1]
    exception_data["tempfile"] = tempfile
    exception_data["crash_id"] = crash_id
    f = File.open(tempfile, "w")
    f.write(exception_data.to_json)
    f.close
    exception_data
  end

  def process_exception_data(e)
    rescue_template = ActionController::Rescue::DEFAULT_RESCUE_TEMPLATES[e.class.name] || ActionController::Rescue::DEFAULT_RESCUE_TEMPLATE
    rescue_status = ActionController::Rescue::DEFAULT_RESCUE_RESPONSES[e.class.name] || ActionController::Rescue::DEFAULT_RESCUE_RESPONSE
    new_params = params.dup
    new_params.delete("action")
    new_params.delete("controller")
    h = {:exception_class => e.class.name,
      :message => e.to_s,
    :template => rescue_template,
    :status => ActionController::StatusCodes::SYMBOL_TO_STATUS_CODE[rescue_status],
    :response => rescue_status,
    :controller => params[:controller],
    :action => params[:action],
    :params => new_params,
    :clean_message => e.clean_message,
    :rails_env => RAILS_ENV,
    }
    if Thread.current['user']
      h[:user] = Thread.current['user'].login
    end
    if Thread.current['cashier']
      h[:cashier] = Thread.current['cashier'].login
    end
    if request.env["HTTP_REFERER"]
      h[:referer] = request.env["HTTP_REFERER"]
    end
    h[:client_ip] = request.remote_ip
    h[:date] = DateTime.now.to_s
    eval("h = process_exception_data_#{rescue_template}(e, h)")
    h = JSON.parse(h.to_json)
    return h
  end

  def process_exception_data_simple(e, h)
    return h
  end

  alias :process_exception_data_unknown_action :process_exception_data_simple
  alias :process_exception_data_missing_template :process_exception_data_simple

  def process_exception_data_backtrace(e, h)
    h[:application_backtrace] = e.application_backtrace
    h[:framework_backtrace] = e.framework_backtrace
    h[:full_backtrace] = e.clean_backtrace
    h[:response_headers] = {}
    h[:blame_trace] = e.describe_blame
    if response
      h[:response_headers] = response.headers.dup
    end
    h[:session] = request.session.instance_variable_get("@data")
    return h
  end

  alias :process_exception_data_diagnostics :process_exception_data_backtrace
  alias :process_exception_data_template_error :process_exception_data_backtrace

  def process_exception_data_routing_error(e, h)
    unless e.failures.empty?
      h[:failures] = []
      e.failures.each do |route, reason|
        h[:failures] << [route.inspect.gsub('\\', ''), reason.downcase]
      end
    end
    return h
  end

  def contract_enabled
    Contract.usable.length > 1
  end

  def barcode(info, opts = {})
    tag("img", {:height => 30, :width => 100}.merge(opts).merge({:src => url_for(:controller => "barcode", :action => "barcode", :id => info, :format => "gif")}))
  end

  def gizmo_events_options_for_transaction
    options_from_collection_for_select(gt_for_txn(@transaction), "id", "description")
  end

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
    begin
      obj = instance_variable_get(obj_name)
    rescue
    end
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

  include HtmlHelper

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

  # start auth junk

  def is_logged_in()
    @current_user
  end

  def is_me?(contact_id)
    @current_user and @current_user.contact_id == contact_id
  end

  def has_role?(*roles)
    @current_user and @current_user.has_role?(*roles)
  end

  def is_staff?
    has_worker = @current_user and @current_user.contact and @current_user.contact.has_worker?
    has_worker || has_role?("ADMIN")
  end

  def has_role_or_is_me?(contact_id, *roles)
    has_role?(*roles) or is_me?(contact_id)
  end

  # end auth junk

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
              "E",
              "Edit",
              options,
              form_id)
  end

  def delete_link(link_id, options, form_id = nill)
    make_link(link_id,
              "D",
              "Delete",
              options,
              form_id)
  end

  def make_link(link_id, image_tag, title, options, form_id = nil)
    image_tag = title
    html = %Q[
      <a id="#{link_id}" title="#{title}"
         onclick="return false">
        #{image_tag}
      </a>
    ]
    ify = form_id ? "$('#{form_id}') == null || form_has_not_been_edited('#{form_id}') ||" : ""
    html += custom_observer(link_id,
                            "if(#{ify} confirm('Current entry form will be lost.  Continue?')) {
                                 #{remote_function(options)}
                             }",
                            'click')
    return html
  end

  def new_edit_link(link_id, options, form_id = nil)
    new_make_link(link_id,
                  "E",
                  "Edit",
                  options,
                  form_id)
  end

  def new_delete_link(link_id, options, form_id = nill)
    new_make_link(link_id,
                  "D",
                  "Delete",
                  options,
                  form_id)
  end

  def new_make_link(link_id, image_tag, title, options, form_id = nil)
    image_tag = title
    ify = form_id ? "form_has_not_been_edited('#{h form_id}') ||" : ""
    html = %Q[
      <a id="#{link_id}" title="#{title}" href="#{h options[:url][:controller]}/#{h options[:url][:action]}/#{h options[:url][:id]}#{h options[:url][:return_to_search]=='true' ? '?return_to_search=true' : ''}"
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

  def array_to_html(*args)
    args.flatten.join('<br />')
  end

  def h_over_array(*args)
    args.flatten.map{|x| h(x)}
  end

  def hideable(html, title, default = false)
    if html.length > 0
      if html.class == Array
        html = array_to_html(h_over_array(html))
      else
        html = h(html)
      end
      return "<span class=\"noprint noblock\"><input onchange=process_hide() type=checkbox id=hideable_check " + (default ? "checked" : "") + " /><label id=hideable_label for=hideable_check>" + "show " + h(title) + "</label></span>" + "<div class=hideable>" + html + "</div>" + javascript_tag("process_hide()")
    end
  end
end
