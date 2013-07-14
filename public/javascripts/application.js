// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function find_ts_customer_notes() {
  if(typeof(timeoutID) != 'undefined') {
    clearTimeout(timeoutID);
  }
  timeoutID = setTimeout("actually_find_ts_customer_notes();", 200);
}

function actually_find_ts_customer_notes() {
  var str = encodeURIComponent($('open_struct_customer_name').value);
  // FIXME : update_calc_url + '
  new Ajax.Request('/tech_support_notes/find_notes/' + str, {asynchronous:true, evalScripts:true, onLoading:function(request) {Element.show("ts_customer_search_loading_indicator_id");}});
}

function prep_disabled_list(list, optional, hook_list, disable) {
  return;
  for(var i = 0; i < list.length; i++) {
    var e = list[i];
    if($(e)) {
      $(e).onkeydown = function(event) {handle_enabling(event, list, optional, hook_list[event.target.id]);};
      if(i != 0 && disable) {
        $(e).disable();
      }
    }
  }
}

function wo_no_system_id() {
  if(confirm("Is this an actual system (not an Other Gizmo)?")) {
    if(confirm("Check that this is a supported Free Geek system. Non-FG systems should only be accepted to perform data backups prior to donation. Is this a Non-FG system?")) {
      $('open_struct_issue').value = 'Data Backup';
      $('open_struct_box_source').hide();
      $('open_struct_sale_date').hide();
      $('open_struct_sale_id').hide();
      $('open_struct_warranty').hide();
      $('open_struct_system_id').hide();
      $('open_struct_box_type').enable();
    }
  } else {
    $('open_struct_box_type').value = 'Other Gizmo';
  }
  $('open_struct_system_id').hide();
  $('open_struct_box_source').enable();
}

function handle_enabling(event, linelist, optional, hook) {
  var is_opt = false;
  for(var i = 0; i < optional.length; i++) {
    var e = optional[i];
    if(e == event.target.id) {
      is_opt = true;
    }
  }
  if(is_tab(event) && (event.target.value != "" || is_opt)) {
    if(hook) {
      hook();
    }
    var last = "NOT_IT";
    var found = 0;
    for(var i = 0; i < linelist.length; i++) {
      var e = linelist[i];
      if($(e) && $(e).visible()) {
        if(e == event.target.id) {
          found += 1;
        }
        if(last == event.target.id) {
          $(e).enable();
        }
        last = e;
      }
    }
    if(found != 1) {
      alert("Unexpected field (" + found + "): " + event.target.id);
    }
  };
}

function focus_on_last_enabled(linelist) {
  var last = undefined;
    for(var i = 0; i < linelist.length; i++) {
      var e = linelist[i];
      if($(e) && !$(e).disabled) {
        last = e;
      }
    }
  if(last) {
    $(e).focus();
  }
}

function focus_on_next_enabled(linelist, lookfor) {
  var found = undefined;
    for(var i = 0; i < linelist.length; i++) {
      var e = linelist[i];
      if($(e) && !$(e).disabled) {
        if(found) {
          $(e).focus();
          return;
        }
        if(e == lookfor) {
          found = true;
        }
      }
    }
}

function is_tab(event) {
  return (event.keyCode==9 && !event.shiftKey);
}

function magic_onkeyscroll(event) {
  var target = event.target;
  if(event.ctrlKey)
    return;
  var s = target.selectedIndex;
  var o = s;
  while(s + 1 < target.length && target.options[s + 1].text[0] == target.options[o].text[0])
    s = s + 1;
  target.value = target.options[s].value;
  target.value = target.options[o].value;
}

function update_calculated_price(form) {
  var str = form.serialize();
  new Ajax.Request(update_calc_url + '?' + str, {asynchronous:true, evalScripts:true, onLoading:function(request) {Element.show(calculated_price_loading_id);}});
}

function show_cancellable(obj, t) {
  if(cancelled_attendance_types.include(parseInt($("attendance_attendance_type_id_" + t).value))) {
    $("cancellable_assignments_" + t).show();
  } else {
    $("cancellable_assignments_" + t).hide();
  }
}

function set_offsite_from_job_default() {
  set_offsite_from_job("offsite", "job_id");
}

function set_offsite_from_job(offsite, job) {
  $(offsite).checked = offsite_jobs[$(job).value] == "true";
}

function display_disciplinary_notes() {
  if($('contact__has_areas_disciplined_from') && $('contact__has_areas_disciplined_from').innerHTML == "true") {
    var str = "This volunteer may not work in the following areas:\n";
    var a = eval($('contact__areas_disciplined_from').innerHTML);
    for(var i = 0; i < a.length; i++) {
      str = str + " * " + a[i] + "\n";
    }
    str = str + "Please check with the volunteer coordinator or a collective staff member for assistance.";
    alert(str);
  }
}

function handle_scroll() {
  var arr = document.getElementsByClassName('follow_scroll');
  for(var i = 0; i < arr.length; i++) {
    move_to_top(arr[i]);
  }
}

function move_to_top(object) {
  var top = document.documentElement.scrollTop;
  var current = object.positionedOffset()[1];
  var change = top - current + 15;
  new Effect.Move(object, {y: change, mode: 'relative'});
}

cashierable_enabled = true;
trigger_worked_shifts_changed = false;

function show_worked_shifts_changed() {
  if(trigger_worked_shifts_changed == true) {
    $('routine_blah').hide();
    $('you_have_changed').show();
  }
}

function updateWorkedShiftTimeleft() {
  worked_shift_timeleft -= 1;
  var string = "" + ((worked_shift_timeleft - (worked_shift_timeleft % 60)) / 60);
  string += ":";
  var end = "" + (worked_shift_timeleft % 60);
  if(end.length == 1)
    string += "0";
  string += end;
  $('worked_shift_time_left_data').innerHTML = string;
  if(worked_shift_timeleft > 0) {
    setTimeout('updateWorkedShiftTimeleft();', 1000);
  } else {
    $('worked_shift_time_left_link').hide();
    $('worked_shift_time_left_error').removeClassName('hidden');
    $('worked_shift_password').enable();
    $('worked_shift_hidden_password').show();
  }
}

function cleanup_hour_select(hour_id, start_hour, end_hour) {
  var e = $(hour_id);
  for(var hour = 0; hour <= 23; hour++) {
    if(hour < start_hour || hour > end_hour) {
      e.options[hour].hide();
    } else {
      var display = "";
      if(hour > 12) {
        display = display + (hour - 12);
      } else {
        display = display + (hour);
      }
      if(hour >= 12) {
        display = display + " PM";
      } else {
        display = display + " AM";
      }
      e.options[hour].text = display;
    }
  }
}

function monitorInitFinding() {
  var applet = document.jzebra;
  if (applet != null) {
    if (!applet.isDoneFinding()) {
      window.setTimeout('monitorInitFinding()', 100);
    } else {
      var list = document.jzebra.getPrinters();
      list = list.split(",").select(function(n) {return (n != "null");})
      list.each(function(i){
        e = document.createElement("option");
        e.text = e.value = i;
        $('receipt_printer').add(e, $('receipt_printer').options[0]);
      });
      var a = $('receipt_printer').options;
      for(var i = 0; i < a.length; i++) {
        var q = a[i];
        if(q.value == receipt_printer_default) {
          $('receipt_printer').selectedIndex = i;
        }
      }
    }
  } else {
    alert('ERROR: applet is not found. do you have Java enabled?');
  }
}

function monitorAppending() {
  var applet = document.jzebra;
  if (applet != null) {
    if (!applet.isDoneAppending()) {
      window.setTimeout('monitorAppending()', 100);
    } else {
      applet.print(); // Don't print until all of the data has been appended
      monitorPrinting();
    }
  } else {
    alert("ERROR: Applet not loaded! do you have java?");
  }
}

function after_print_hook() {
        if(typeof(loading_indicator_after_print) != "undefined") {
          Element.hide(loading_indicator_after_print);
        }
        if(typeof(redirect_after_print) != "undefined") {
          window.location.href = redirect_after_print;
        }
}

function monitorPrinting() {
  var applet = document.jzebra;
  if (applet != null) {
    if (!applet.isDonePrinting()) {
      window.setTimeout('monitorPrinting()', 100);
    } else {
      var e = applet.getException();
      if(e != null) {
        alert("ERROR: printing failed. " + e.getLocalizedMessage());
      } else {
        after_print_hook();
      }
    }
  } else {
    alert("Applet not loaded!");
  }
}

function monitorPrintFinding() {
  var applet = document.jzebra;
  if (applet != null) {
    if (!applet.isDoneFinding()) {
      window.setTimeout('monitorPrintFinding()', 100);
    } else {
      if(selected_printer() != applet.getPrinter()) {
        alert('ERROR: Could not choose correct printer');
        return;
      }
      applet.append(text_pending_print);
      monitorAppending();
      applet.print();
    }
  } else {
    alert('ERROR: applet is not found. do you have Java enabled?');
  }
}

function set_printers() {
  document.jzebra.findPrinter("");
  monitorInitFinding();
}

// FIXME: needs to be rewritten to be event driven so that race conditions and errors are accounted for

function print_text(text) {
  var ap = document.jzebra;
  if(ap == null) {
    alert('ERROR: jZebra could not load, do you have java installed?');
    return;
  }
  var printer = selected_printer();
  if(printer == "") {
    alert('ERROR: Please choose a printer');
    return;
  }
  text_pending_print = text;
  ap.findPrinter(printer);
  monitorPrintFinding();
}

function selected_printer() {
  return $('receipt_printer').options[$('receipt_printer').selectedIndex].value;
}

function selection_toggle(id) {
  var is_r = !window.location.href.match("default_assignments");
  var name = (is_r) ? 'Assignment' : 'DefaultAssignment';
  var e = $(name + "_" + id);
  if(e.className != 'selected') {
    e.old_class = e.className;
    e.className = 'selected';
  } else {
    e.className = e.old_class;
  }
}

function toggle_disabled_with_hidden(field_id) {
  toggle_disabled_with_hidden_and(field_id, undefined);
}

function toggle_disabled_with_hidden_and(field_id, other_id) {
  var r_field  = $(field_id);
  var o_field  = (other_id != undefined) ? $(other_id) : undefined;
  r_field.disabled = !r_field.disabled;
  if(other_id != undefined) {
    o_field.disabled = r_field.disabled;
  }
  if(r_field.disabled) {
    var h_field = $(field_id + "_hidden");
    h_field.value = r_field.value;
  }
  if(other_id != undefined && r_field.disabled) {
    var ho_field = $(other_id + "_hidden");
    ho_field.value = o_field.value;
  }
}


function reassign(assigned_id) {
  var is_r = !window.location.href.match("default_assignments");
  var name = (is_r) ? 'Assignment' : 'DefaultAssignment';
  var controller = (is_r) ? 'assignments' : 'default_assignments';
  var available_id = all_selected();
  if(available_id.split(",").length != 1 || available_id.length == 0) {
    alert("Select one assignment to reassign this shift to by clicking on it and then try again");
    selection_toggle(assigned_id);
    return;
  }
  var available_e = $(name + "_" + available_id);
  var arr = [assigned_id, available_id];
  arr = arr.join(",");
  window.location.href = "/" + controller + "/reassign/" + arr;
}

function all_selected() {
  var a = document.getElementsByClassName("selected");
  var r = [];
  for(var i = 0; i < a.length; i++) {
    var x = a[i];
    var s = x.id.split("_")[1];
    r.push(s);
  }
  return r.join(",");
}

function do_multi_edit() {
  var is_r = !window.location.href.match("default_assignments");
  var controller = (is_r) ? 'assignments' : 'default_assignments';
  var ids = all_selected();
  if(ids.length == 0) {
    alert("Select some assignments by clicking on them and try again");
    return;
  }
  window.location.href = "/" + controller + "/edit/" + ids;
}

function show_message(msg) {
  popup1 = new Popup();
  popup1.content = msg;
  popup1.style = {'border':'3px solid black','backgroundColor':'white'};
  popup1.show();
  document.onkeydown = function(e){
    var keycode;
    if (e == null) {
      keycode = event.keyCode;
    } else {
      keycode = e.which;
    }
    if(keycode == 27){
      popup1.hide();
      document.onkeydown = null;
    }
  };
}

var FixedAutocomplete = Class.create(Ajax.Autocompleter, {
  baseInitialize: function($super,element, update, options) {
    $super(element, update, options);
    Event.observe(this.element, "input", this.onInput.bindAsEventListener(this));
  },

   onInput: function(event) {
     if(this.observer) clearTimeout(this.observer);

     this.observer = setTimeout(this.onObserverEvent.bind(this), this.options.frequency*1000);
     if(this.options.afterInput) {
       this.options.afterInput();
     }
   },
});

function trigger_volunteer_task_type() {
  $('volunteer_task_program').value = volunteer_task_programs[$('volunteer_task_volunteer_task_type').value];
}

function toggle_the_admin() {
  div = $('hidden_admin');
  klass = 'hidden';
  if(div.hasClassName(klass)) {
    div.removeClassName(klass);
  } else {
    div.addClassName(klass);
  }
}

function update_cashier_code() {
  cashier_id_field = $('cashier_code');
  if(cashier_id_field == null)
    return;
  thing = document.getElementsByClassName('cashierable_form')[0];
  if(cashier_id_field.value.length == 4) {
    if(arguments[0] != null) {
      good_cashier_code(cashier_id_field.value, arguments[0]);
    } else {
      good_cashier_code(cashier_id_field.value);
    }
  } else {
    disable_cashierable();
  }
}

function form_to_json(){
  form_id = editable_form_name;
  if($(form_id) == null)
    return "";
  orig = cashierable_enabled;
  if(orig == false) {
    enable_cashierable();
  }
  var hash = Form.serialize(form_id).toQueryParams();
  hash.cashier_code = "...";
  var result = Object.toJSON(hash);
  if(orig == false) {
    disable_cashierable();
  }
  if(orig != cashierable_enabled) {
    alert("BUG, form_to_json");
  }
  return result;
}

function set_contact_name() {
  list = document.getElementsByClassName('contact_search_textbox')[0].value.split(' ');
  if(list.length == 2) {
    $('contact_first_name').value = list[0];
    $('contact_surname').value = list[1];
  }
}

function set_organization_name() {
  value = document.getElementsByClassName('contact_search_textbox')[0].value;
  list = value.split(' ');
  if(list.length == 2) {
    if($('contact_first_name').value == list[0]) {
      $('contact_first_name').value = "";
    }
    if($('contact_surname').value == list[1]) {
      $('contact_surname').value = "";
    }
  }
  $('contact_organization').value = value;
}

function process_hide(){
  if($('hideable_check').checked) {
    _hide_changes("hidden", "hideable", "show", "hide");
  } else {
    _hide_changes("hideable", "hidden", "hide", "show");
  }
}

function _hide_changes(one, two, three, four){
  document.getElementsByClassName(one)[0].className = two;
//  $('hideable_label').innerHTML = $('hideable_label').innerHTML.replace(three, four);
}

function disable_cashierable(){
  cashierable_enabled = false;
    thing.disable();
  if(document.getElementsByClassName('cancel')[0] != null) {
    document.getElementsByClassName('cancel')[0].disabled = false;
  }
    disable_all_links();
  if(typeof(form_is_editable) == "undefined" || form_is_editable) {
    $('cashier_code').enable();
  }
    $('cashier_code').focus();
}

function disable_always_disabled(){
  var arr = document.getElementsByClassName("always_disabled");
  for (var i = 0; i < arr.length; i++) {
    var thing = arr[i];
    thing.disable();
  }
}

function enable_cashierable(){
  cashierable_enabled = true;
    thing.enable();
    disable_always_disabled();
    enable_all_links();
  if($('covered')) {
    $('covered').value = "nil";
  }
}

function show_contract_notes() {
  if($('donation_contract_id') == null)
    return;
  var mynotes = contracts_notes[parseInt($('donation_contract_id').value)];
  $('contract_notes').innerHTML = mynotes;
  if(mynotes.length > 0){
    $('contract_notes').show();
  } else {
    $('contract_notes').hide();
  }
  contract_selected();
}

function select_visibility(obj_name, method_name, choices, value) {
    for( var i = 0; i < choices.length; i++)
    {var choice = choices[i]; if(choice == 'extend') {}
        else if(choice == value) {$(obj_name + '_' + method_name + '_' + choice + '_choice').show();}
        else {$(obj_name + '_' + method_name + '_' + choice + '_choice').hide();} }
}

// Called as:
// confirmReplaceElementValue(elem_id, new_elem_value, confirm_message)
function confirmReplaceElementValue(id, val, msg){
  var truth_value = confirm(msg)
  if (truth_value){
    // alert("updating element:" + id + " with value:" + val)
    $(id).value = val
  }
  return truth_value
}

// Called as:
// calculateOffsetLeft(_inputField)
// was ob
function calculateOffsetLeft(r){
  return absolute_offset(r,"offsetLeft")
}

// Called as:
// calculateOffsetTop(_inputField)
// Was Qb...
function calculateOffsetTop(r){
  return absolute_offset(r,"offsetTop")
}

function absolute_offset(r,attr){
  var tot=0;
  while(r){
    tot+=r[attr];
    r=r.offsetParent
  }
  return tot
}

function contactKeyListener(event) {
  var keyCode = event.keyCode ? event.keyCode : event.which ? event.which : event.charCode;

        if (keyCode == 13 || keyCode == 10) {
                return false;
  }
}

function magicContactOnlyOnSubmit(button, event) {
  var keyCode = event.keyCode ? event.keyCode : event.which ? event.which : event.charCode;

  if (keyCode == 13 || keyCode == 10) {
    magicContact(button);
  }
}

function magicContact(button) {
  button = $(button);
  button.click();
}

function setRelativelyAbsolute(elem_id, relative_to_id) {
  rel = $(relative_to_id);
  elem = $(elem_id);
  elem.style.left=calculateOffsetLeft(rel)+"px";
  elem.style.top=calculateOffsetTop(rel)+rel.offsetHeight-1+"px";
}

function alertEvent( element, value,  event) {
  // alert('event element: ' + Event.element(event));
  alert('alertEvent: event id: ' + Event.element(event).id);
}

function matchValueVsManyPatterns(value, patts) {
  var stringValue = value.toString();
  patts = $A(patts);
  var result = false;
  patts.each(function(patt, index) {
    var stringPatt = patt.toString();
    var regex = new RegExp(stringPatt);
    if (stringValue.match(regex)) {
      result = true;
    }
  });
  return result;
}
// request only if trigger element id matches one of given patterns
function updateTotalsIfMatch( element, value,  event, controller, patterns) {
  if((event == null) || (patterns.length > 0 && matchValueVsManyPatterns(Event.element(event).id, patterns))) {
    new Ajax.Request('/' + controller + '/update_totals?' + value, {asynchronous:true, evalScripts:true});
  }
}

function updateTotalsForContext( element, value,  event, context) {
  var patts = [];
  var controller = context + 's';
  if (context == 'sale') {
    patts.push('unit_price$');
    patts.push('gizmo_count$');
  }
  patts.push('amount$');
  patts.push('gizmo_type_id$');
  patts.push('payment_method_id$');
  patts.push('discount_schedule_id$');
  updateTotalsIfMatch( element, value, event, controller, patts);
}

function updateTotals(context, formId) {
  var value = Form.serialize(formId);
  new Ajax.Request('/' + context + 's/update_totals?' + value, {asynchronous:true, evalScripts:true});
}

function set_display_mode(type, mode) {
  $$(type).each(function(elem) {
                  if (mode == 0) {
                    elem.hide();
                  } else {
                    elem.show();
                  }
                });
}

function contact_form_org_toggle() {
  if( $('contact_is_organization').checked ) {
    $$('.organization').each(function(elem) { elem.show(); });
  } else {
    $$('.organization').each(function(elem) { elem.hide(); });
  }
}

function defined(variable)
{
    return (typeof(variable) != 'undefined');
}

function form_has_not_been_edited(form_name) {
  return form_to_json() == initial_form_json;
}

function set_new_val(element, new_val) {
  element.value = new_val;
  element.defaultValue = new_val;
  trigger_change_on(element);
}

function trigger_change_on(element) {
  var event = document.createEvent('HTMLEvents');
  event.initEvent('change',true,true);
  element.dispatchEvent(event);
}

function get_percentage_field_value(field_id) {
  return parseInt($(field_id).options[$(field_id).selectedIndex].text);
}

function dollar_cent_value(amt) {
  return dollar_value(cent_value(amt));
}

function dollar_value(cents) {
  cents = "" + Math.floor(cents);
  if (cents.length == 0) {
    return "0.00";
  }
  else if (cents.length == 1) {
    return "0.0" + cents;
  }
  else if (cents.length == 2) {
    return "0." + cents;
  }
  else {
    return cents.replace(/(\d\d)$/, ".$1");
  }
}

function cent_value(value) {
  var arr = ("" + value).split(".");
  if (arr.length > 0) {
    if(arr[0].length > 0)
      value = parseInt(arr[0]) * 100;
    else
      value = 0;
    if (arr.length > 1) {
      if (arr[1].length == 1) {
        value += parseInt(arr[1]) * 10;
      } else if(arr[1].length > 2) {
        var tempint = parseInt(arr[1][0] + arr[1][1]);
        if(parseInt(arr[1][2]) >= 5) {
          tempint++;
        }
        value += tempint;
      }
      else {
        value += parseInt(arr[1]);
      }
    }
  }
  return value;
}

function remove_condition(obj_name, value)
{
  Element.remove(obj_name + "_tbody_for_" + value);
  Element.show($(obj_name + "_" + value + "_option"));
  $(obj_name + '_' + value + '_enabled').value = false;
}

function add_condition(obj_name, value)
{
  if(value != ''){
    var list_of_conditions = eval("list_of_" + obj_name + "_conditions");
    var condition_display_names  = eval("condition_" + obj_name + "_display_names");
    Insertion.Bottom(obj_name + "_table", '<tbody id="' + obj_name + '_tbody_for_' + value + '"><tr><th class="conditions"><span>' + condition_display_names.get(value) + ':</span></td><td>' + list_of_conditions.get(value) + '</td><td><span><input value="-" type="button" id="' + obj_name + '_delete_"' + value + '" onclick="remove_condition(\'' + obj_name + '\', \'' + value + '\')"/></span></td></tr></tbody>');
    Element.hide($(obj_name + '_' + value + '_option'));
    $(obj_name + '_' + value + '_enabled').value = true;
    $(obj_name + '_adder').value = "";
    $(obj_name + '_adder').focus();
  }
}

function disable_all_links() {
  var arr = document.getElementsByClassName("disable_link");
  for (var i = 0; i < arr.length; i++) {
    var thing = arr[i];
    if(thing.status == undefined || thing.status == 0) {
      thing.origOnClick = thing.onclick;
      thing.onclick = function () { return false; };
      thing.status = 1;
    }
  }
}

function enable_all_links() {
  var arr = document.getElementsByClassName("disable_link");
  for (var i = 0; i < arr.length; i++) {
    var thing = arr[i];
    if(thing.status == 1) {
      thing.onclick = thing.origOnClick;
      thing.origOnClick = "";
      thing.status = 0
    }
  }
}

function toggle_description(evt) {
  show_description++;
  var arr = document.getElementsByClassName('description');
  for (var i = 0; i < arr.length; i++) {
    set_visibility(arr[i], show_description & 1)
  }
  return true;
}

function toggle_discount(evt) {
  discount_visible++;
  var arr = document.getElementsByClassName('discount');
  for (var i = 0; i < arr.length; i++) {
    set_visibility(arr[i], discount_visible & 1)
  }
  return true;
}
