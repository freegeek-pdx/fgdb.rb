/////////////////////////////////////
// ALIASES TO BE CALLED FROM VIEWS //
/////////////////////////////////////

function handle_gizmo_events(){
  return _add_gizmo_event_from_form();
}

function handle_shifts() {
  return add_shift_from_form();
}

function handle_payments(){
  return add_payment_from_form();
}

function handle_all(){
  handle_gizmo_events();
  handle_payments();
}

/////////////////////
// GENERAL HELPERS //
/////////////////////

function strlist_to_arr(str) {
  return str.split(",").map(function(a){return a.split(" ")}).flatten().select(function(a){return a != "";});
}

function is_a_list(str) {
  return str.include(" ") || str.include(",");
}

function first(a,b) { return a>0 ? a : b; }

function set_visibility(node, visibility) {
  if (visibility) {
    node.removeClassName("invisible");
  }
  else {
    node.addClassName("invisible");
  }
}

// this one gets the visible part
function get_node_value(node, id) {
  return node.getElementsBySelector(id).first().lastChild.data.replace(/\$/, '');
}

// this one gets the hidden part
function getValueBySelector(thing, selector) {
  return thing.getElementsBySelector(selector).first().firstChild.value;
}

function find_these_lines(name){
  return $(name).getElementsBySelector("tr.line");
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
      }
      else {
        value += parseInt(arr[1]);
      }
    }
  }
  return value;
}

////////////////////
// LINE ITEM JUNK //
////////////////////


function prefix_to_container(prefix) {
  // why is this not the sames as args['prefix']? FIX THIS!!!
  if(prefix == "contact_method") {
    return "contact_methods";
  } else if (prefix == "payment") {
    return "payments";
  } else if (prefix == "gizmo_event") {
    return "line";
  } else if (prefix == "shift") {
    return "shifts";
  } else {
    alert("BROKEN");
  }
}


function add_line_item(args, stupid_hook, update_hook, edit_hook){
  var prefix = args['prefix'];
  var id = prefix + '_' + counters[prefix + '_line_id'] + '_line'
    tr = document.createElement("tr");
  tr.className = "line";
  tr.id = id;
  stupid_hook(args, tr);
  td = document.createElement("td");
  a = document.createElement("a");
  a.onclick = function () {
    edit_hook(id);
    Element.remove(id);
    update_hook();
  };
  if(edit_hook) {
    a.appendChild(document.createTextNode('e'));
    a.className = 'disable_link';
    td.appendChild(a);
  }
  td.appendChild(document.createTextNode(' '));
  a = document.createElement("a");
  a.onclick = function () {
    Element.remove(id);
    update_hook();
  };
  a.appendChild(document.createTextNode('x'));
  a.className = 'disable_link';
  td.appendChild(a);
  if(!args['uneditable']) {
    tr.appendChild(td);
  }
  tr.appendChild(make_hidden(prefix_to_container(args['prefix']), "id", "", args['id'], counters[prefix + '_line_id']));
  $(prefix + '_lines').lastChild.insertBefore(tr, $(prefix + '_form'));
  counters[args['prefix'] + '_line_id']++;
  update_hook();
}

function make_hidden(container, name, display_value, value, line_id){
  hidden = document.createElement("input");
  hidden.name = container + '[-' + line_id + '][' + name + ']';
  hidden.value = value;
  hidden.type = 'hidden';
  td = document.createElement("td");
  td.className = name;
  td.appendChild(hidden);
  td.appendChild(document.createTextNode(display_value));
  return td;
}

////////////////
// EDIT HOOKS //
////////////////

function edit_gizmo_event(id) {
  thing = $(id);
  $('gizmo_type_id').value = getValueBySelector(thing, ".gizmo_type_id");
  $('gizmo_type_id').onchange();
  $('gizmo_count').value = getValueBySelector(thing, ".gizmo_count");
  if($('system_id') != null) {
    $('system_id').value = getValueBySelector(thing, ".system_id");
  }
  if($('contract_id') != null) {
    $('contract_id').value = getValueBySelector(thing, ".recycling_contract_id");
  }
  if($('covered') != null) {
    $('covered').checked = getValueBySelector(thing, ".covered") == "true";
    if($('covered').onchange) {
      $('covered').onchange();
    }
  }
  if($('unit_price') != null) {
    $('unit_price').value = getValueBySelector(thing, ".unit_price");
  }
  $('description').value = getValueBySelector(thing, ".description");
  $('gizmo_type_id').focus();
}

function edit_shift(id) {
  thing = $(id);
  $('job_id').value = getValueBySelector(thing, ".job_id");
  $('duration').value = getValueBySelector(thing, ".duration");
  $('job_id').focus();
}


function edit_payment(id) {
  thing = $(id);
  $('payment_method_id').value = getValueBySelector(thing, ".payment_method_id");
  sale_payment_method_selected();
//  eval(gizmo_context_name + "_payment_method_selected();");
  $('payment_amount').value = getValueBySelector(thing, ".amount");
  if($('store_credit_id')) {
    $('store_credit_id').value = getValueBySelector(thing, ".store_credit_id");
  }
  $('payment_method_id').focus();
}

//////////////////
// STUPID HOOKS //
//////////////////

function sales_hooks(args, tr) {
  gizmo_events_stuff(args, tr);
  coveredness_stuff(args, tr);
  systems_stuff(args, tr);
  unit_price_stuff(args, tr);
}

function disbursements_hooks(args, tr) {
  gizmo_events_stuff(args, tr);
  systems_stuff(args, tr);
  coveredness_stuff(args, tr);
}

function recycling_hooks(args, tr) {
  gizmo_events_stuff(args, tr);
  contracts_stuff(args, tr);
  coveredness_stuff(args, tr);
}
function donation_hooks(args, tr) {
  gizmo_events_stuff(args, tr);
  coveredness_stuff(args, tr);
  systems_stuff(args, tr);
  unit_price_stuff(args, tr);
}
function shift_hook(args, tr) {
  var job_id = args['job_id'];
  var duration = args['duration'];
  var job = all_jobs[job_id];
  var line_id = counters[args['prefix'] + '_line_id'];
  tr.appendChild(make_hidden(prefix_to_container(args['prefix']), "job_id", job, job_id, line_id));
  tr.appendChild(make_hidden(prefix_to_container(args['prefix']), "duration", duration, duration, line_id));
}

/////////////////////////
// ADD JUNK FROM FORMS //
/////////////////////////

function is_priced() {
  if(gizmo_context_name == "donation" || gizmo_context_name == "sale")
    return true;
  else if(gizmo_context_name == "recycling" || gizmo_context_name == "disbursement" || gizmo_context_name == "gizmo_return")
    return false;
  else
    alert("BUG. go yell at Ryan.");
  return false;
}

function update_amount_for_storecredit() {
  var a = dollar_value(get_storecredit_amount($('store_credit_id').value));
  if(a == "0.00") {
    a = "";
  }
  $('payment_amount').value = a;
}

function add_shift_from_form() {
  if($('job_id').selectedIndex == 0 || $('duration').value == '') {
    return true;
  }
  var args = new Object();
  args['duration'] = $('duration').value;
  args['job_id'] = $('job_id').value;
  add_shift(args);
  $('job_id').selectedIndex = 0;
  $('duration').value = $('duration').defaultValue;
  $('job_id').focus();
  return false;
}

function _add_gizmo_event_from_form()
{
  if($('gizmo_type_id').selectedIndex == 0 || ($('unit_price') != null && $('unit_price').value == '') || $('gizmo_count').value == '') {
    return true;
  }
  if($('system_id') != null) {
    var list = strlist_to_arr($('system_id').value);
    if(parseInt($('gizmo_count').value) < list.length) {
      alert("you gave more system ids than the number of gizmos, which can't work...please fix this and try again.");
      $('gizmo_type_id').focus();
      return true;
    }
  }
  var args = new Object();
  args['gizmo_type_id'] = $('gizmo_type_id').value;
  args['gizmo_count'] = $('gizmo_count').value;
  args['description'] = $('description').value;
  if($('unit_price') != null) {
    args['unit_price'] = $('unit_price').value;
  }
  if($('system_id') != null) {
    args['system_id'] = $('system_id').value;
  }
  if($('covered') != null) {
    args['covered'] = $('covered').checked;
  }
  if($('contract_id') != null) {
    args['contract_id'] = $('contract_id').value;
  }
  add_gizmo_event(args);
  $('gizmo_type_id').selectedIndex = 0; //should be default, but it's yucky
  if($('unit_price') != null) {
    $('unit_price').enable();
  }
  $('description').value = $('description').defaultValue;
  if($('unit_price') != null) {
    $('unit_price').value = $('unit_price').defaultValue;
  }
  $('gizmo_count').value = $('gizmo_count').defaultValue;
  if($('system_id') != null) {
    $('system_id').value = $('system_id').defaultValue;
    $('system_id').disable();
  }
  if($('covered') != null){
    $('covered').checked = $('covered').defaultChecked;
    $('covered').disable();
    if($('covered').disabled) {
      $('covered').checked = false;
    }
  }
  if($('contract_id') != null) {
    $('contract_id').selectedIndex = 0;
  }
  $('gizmo_type_id').focus();
  return false;
}

function add_payment_from_form() {
  if(!is_priced())
    return;
  if($('payment_method_id').selectedIndex == 0 || $('payment_amount').value == '') {
    return true;
  }
  var args = new Object();
  args['payment_method_id'] = $('payment_method_id').value;
  args['payment_amount'] = $('payment_amount').value;
  if($('store_credit_id')) {
    args['store_credit_id'] = $('store_credit_id').value;
  }
  add_payment(args);
  $('payment_method_id').selectedIndex = 0; //should be default, but it's yucky
  $('payment_amount').value = $('payment_amount').defaultValue;
  if($('store_credit_id')) {
    $('store_credit_id').value = $('store_credit_id').defaultValue;
  }
  $('payment_method_id').focus();
  return false;
}

function add_contact_method_from_form() {
  if($('contact_method_value').value == '' || $('contact_method_type_id').selectedIndex == 0) {
    return true;
  }
  add_contact_method($('contact_method_type_id').value, $('is_usable').checked, $('contact_method_value').value)
  $('contact_method_type_id').selectedIndex = 0; //should be default, but it's yucky
  $('contact_method_value').value = $('contact_method_value').defaultValue;
  $('is_usable').checked = false;
  $('contact_method_type_id').focus();
  return false;
}

///////////////////////////////
// REAL PART OF STUPID HOOKS //
///////////////////////////////

function coveredness_stuff(args, tr){
  if(!coveredness_enabled)
    return;
  if($('covered') == null)
    return;
  var line_id = counters[args['prefix'] + '_line_id'];
  tr.appendChild(make_hidden(prefix_to_container(args['prefix']), "covered", args['covered'], args['covered'], line_id));
}

function systems_stuff(args, tr){
  var line_id = counters[args['prefix'] + '_line_id'];
  if($('system_id') == null)
    return;
  if(args['system_id'] != "") {
    if(get_system_contract(args['system_id']) == -1) {
      alert("system does not exist! ignoring...");
    }
    if(get_system_contract(args['system_id']) != -1) {
      if(all_contracts_names.length > 2) {
        hidden = document.createElement("input");
        hidden.name = "line" + '[-' + line_id + '][system_id]';
        hidden.value = args['system_id'];
        hidden.type = 'hidden';
        td = document.createElement("td");
        td.className = "system_id";
        td.appendChild(hidden);
        td.appendChild(document.createTextNode(args['system_id'] + "["));
        a = document.createElement("a");
        a.href = "/spec_sheets/fix_contract_edit?system_id=" + args['system_id'];
        a.appendChild(document.createTextNode(all_contracts_names[get_system_contract(args['system_id'])]));
        td.appendChild(a);
        td.appendChild(document.createTextNode("]"));
        tr.appendChild(td);
      } else {
        tr.appendChild(make_hidden(prefix_to_container(args['prefix']), "system_id", args['system_id'], args['system_id'], line_id));
      }
    }
    else {
      tr.appendChild(make_hidden(prefix_to_container(args['prefix']), "system_id", "", "", line_id));
    }
  }
  else {
    tr.appendChild(make_hidden(prefix_to_container(args['prefix']), "system_id", "", "", line_id));
  }
}

function contracts_stuff(args, tr){
  if($('contract_id') != null) {
    var line_id = counters[args['prefix'] + '_line_id'];
    var contract = all_contracts[args['contract_id']];
    tr.appendChild(make_hidden(prefix_to_container(args['prefix']), "recycling_contract_id", contract, args['contract_id'], line_id));
  }
}

function unit_price_stuff(args, tr){
  var line_id = counters[args['prefix'] + '_line_id'];
  tr.appendChild(make_hidden(prefix_to_container(args['prefix']), "unit_price", args['unit_price'], args['unit_price'], line_id));
  td = document.createElement("td");
  td.appendChild(make_hidden(prefix_to_container(args['prefix']), "total_price", "$0.00", "$0.00", line_id));
  tr.appendChild(td);
}

function gizmo_events_stuff(args, tr){
  var gizmo_type_id = args['gizmo_type_id'];
  var gizmo_count = args['gizmo_count'];
  var description = args['description'];
  var gizmo_type = all_gizmo_types[gizmo_type_id];
  var line_id = counters[args['prefix'] + '_line_id'];
  tr.appendChild(make_hidden(prefix_to_container(args['prefix']), "gizmo_type_id", gizmo_type, gizmo_type_id, line_id));
  var desc = make_hidden(prefix_to_container(args['prefix']), "description", description, description, line_id)
  set_visibility(desc, show_description);
  tr.appendChild(desc);
  tr.appendChild(make_hidden(prefix_to_container(args['prefix']), "gizmo_count", gizmo_count, gizmo_count, line_id));
}
function payment_stuff(args, tr){
  var payment_amount = args['payment_amount'];
  var payment_method_id = args['payment_method_id'];
  var line_id = counters[args['prefix'] + '_line_id'];
  tr.appendChild(make_hidden(prefix_to_container(args['prefix']), "payment_method_id", payment_methods[payment_method_id], payment_method_id, line_id));
  amount_node = make_hidden(prefix_to_container(args['prefix']), "amount", payment_amount, payment_amount, line_id);
  amount_node.className = "amount";
  tr.appendChild(amount_node);
  if($('store_credit_id')) {
    var storecredit_id = args['store_credit_id'];
    tr.appendChild(make_hidden(prefix_to_container(args['prefix']), "store_credit_id", storecredit_id, storecredit_id, line_id));
  }
}

function contact_method_stuff(args, tr){
  var contact_method_value = args['contact_method_value'];
  var contact_method_type_id = args['contact_method_type_id'];
  var contact_method_usable = args['contact_method_usable'];
  var line_id = counters[args['prefix'] + '_line_id'];
  tr.appendChild(make_hidden(prefix_to_container(args['prefix']), "contact_method_type_id", contact_method_types[contact_method_type_id], contact_method_type_id, line_id));
  usable_node = make_hidden(prefix_to_container(args['prefix']), "ok", contact_method_usable, contact_method_usable, line_id);
  usable_node.className = "ok";
  tr.appendChild(usable_node);
  description_node = make_hidden(prefix_to_container(args['prefix']), "value", contact_method_value, contact_method_value, line_id);
  description_node.className = "description";
  tr.appendChild(description_node);
}

//////////////////
// UPDATE HOOKS //
//////////////////

function update_contract_notes(){
  if($('contract_notes') == null)
    return;
  var mynotes;
  var found = new Array();
  mynotes = "";
  lines = find_these_lines('gizmo_event_lines');
  for(var i = 0; i < lines.size(); i++) {
    line = lines[i];
    system_id = getValueBySelector(line, ".system_id");
    if(system_id != null && system_id != "") {
      contract_id = get_system_contract(system_id);
      if(!found[contract_id]) {
        notes = contracts_notes[contract_id];
        if(notes.length > 0) {
          if(mynotes.length > 0) {
            mynotes += "-----\n";
          }
          mynotes += notes + "\n";
        }
        found[contract_id] = true;
      }
    }
  }
  $('contract_notes').innerHTML = mynotes;
  if(mynotes.length > 0){
    $('contract_notes').show();
  } else {
    $('contract_notes').hide();
  }
}

function format_float(float) {
  var str = (parseInt(float * 100) / 100).toString();
  if(str.split(".").length == 1) {
    str += ".00";
  }
  if(str.split(".")[1].length == 1) {
    str += "0";
  }
  return str;
}

function get_system_contract(system_id){
  var val;
  if(system_contract_cache[system_id]) {
    val = system_contract_cache[system_id];
  } else {
    var myhash = new Hash();
    internal_system_contract_id = -2;
    myhash.set('system_id', system_id);
    var str = myhash.toQueryString(); // TODO: just pass the hash in the parameters: option below
    Element.show(line_item_loading_id);
    new Ajax.Request(get_system_contract_url + '?' + str, {asynchronous:false, evalScripts:true});
    system_contract_cache[system_id] = internal_system_contract_id;
    val = internal_system_contract_id;
  }
  if(val == -2) {
    alert("internal error");
  }
  return val;
}

function get_storecredit_amount(id) {
  if(id == null || id == "") {
    return null;
  }
  var val;
  if(storecredit_amount_cache[id]) {
    val = storecredit_amount_cache[id];
  } else {
    var myhash = new Hash();
    internal_storecredit_amount = -2;
    myhash.set('id', id);
    var str = myhash.toQueryString(); // TODO: just pass the hash in the parameters: option below
    Element.show(payment_line_item_loading_id);
    new Ajax.Request(get_storecredit_amount_url + '?' + str, {asynchronous:false, evalScripts:true});
    storecredit_amount_cache[id] = internal_storecredit_amount;
    val = internal_storecredit_amount;
  }
  if(val == -2) {
    alert("internal error");
  }
  if(val == -1) {
    val = null;
  }
  return val;
}

function shift_compute_totals () {
  var today = get_hours_today();
  var myhash = new Hash();
  myhash.set('worked_shift[hours_today]', today);
  myhash.set('worked_shift[date_performed]', shifts_date);
  myhash.set('worked_shift[worker_id]', shifts_worker);
  var str = myhash.toQueryString();
  new Ajax.Request(update_shift_totals_url + '?' + str, {asynchronous:true, evalScripts:true, onLoading:function(request) {Element.show(shifts_totals_loading_id);}});
}

function donation_compute_totals() {
  update_gizmo_events_totals();

  var totals = get_donation_totals();
  var required = totals['required'];
  var suggested = totals['suggested'];
  var total = required + suggested;
  var payment = get_total_payment();
  var short = payment - required;
  var bonus = payment - total;

  $('required').innerHTML = dollar_value(required);
  $('suggested').innerHTML = dollar_value(suggested);
  $('total').innerHTML = dollar_value(total);
  $('received').innerHTML = dollar_value(payment);
  $('short').innerHTML = dollar_value(short);
  set_visibility($('short_row'), short < 0);
  $('bonus').innerHTML = dollar_value(bonus);
  set_visibility($('bonus_row'), bonus > 0);
}

function sale_compute_totals() {
  update_gizmo_events_totals();
  $('change_due_tr').removeClassName('short_row');
  var subtotal = get_subtotal();
  var grand_total = get_grand_total();
  var discount = subtotal - grand_total;
  var store_credit = get_storecredit();
  var not_store_credit = get_not_storecredit();
  var payment = get_total_payment();

  $('subtotal').innerHTML = dollar_value(subtotal);
  $('discount').innerHTML = dollar_value(discount);
  $('grand_total').innerHTML = dollar_value(grand_total);
  $('total_payments').innerHTML = dollar_value(payment);
  var storecredit_left = store_credit - grand_total;
  if(storecredit_left > 0) {
    // show the row, show how much is left
    $('storecredit_left_tr').show();
    $('storecredit_left').innerHTML = dollar_value(storecredit_left);
    // no more money owed
    grand_total = 0;
  } else if (storecredit_left <= 0) {
    // hide the row
    $('storecredit_left_tr').hide();
    // spent too much, leave it to the real money
    grand_total = -1 * storecredit_left;
  }
  var change_due = not_store_credit - grand_total;
  $('change_due').innerHTML = dollar_value(change_due);
  if(change_due < 0) {
    $('change_due_tr').addClassName('short_row');
  }
  update_contract_notes();
}

function gizmo_return_compute_totals(){
  update_gizmo_events_totals();
  var subtotal = get_subtotal();
  $('grand_total').innerHTML = dollar_value(subtotal);
}

function get_grand_total(){
  var total = 0;
  var arr = find_these_lines('gizmo_event_lines');
  for (var x = 0; x < arr.length; x++) {
    total += cent_value(get_node_value(arr[x], "td.total_price"));
  }
  return total;
}

function get_subtotal() {
  var total = 0;
  var arr = find_these_lines('gizmo_event_lines');
  for (var x = 0; x < arr.length; x++) {
    total += (get_node_value(arr[x], "td.gizmo_count") * cent_value(get_node_value(arr[x], "td.unit_price")));

  }
  return total;
}

function get_total_payment() {
  var total = 0;
  var arr = find_these_lines('payment_lines');
  for (var x = 0; x < arr.length; x++) {
    total += cent_value(get_node_value(arr[x], "td.amount"));
  }
  return total;
}

function get_storecredit(){
  var total = 0;
  var arr = find_these_lines('payment_lines');
  for (var x = 0; x < arr.length; x++) {
    if(get_node_value(arr[x], "td.payment_method_id") == "store credit") {
      total += cent_value(get_node_value(arr[x], "td.amount"));
    }
  }
  return total;
}

function get_not_storecredit(){
  var total = 0;
  var arr = find_these_lines('payment_lines');
  for (var x = 0; x < arr.length; x++) {
    if(get_node_value(arr[x], "td.payment_method_id") != "store credit") {
      total += cent_value(get_node_value(arr[x], "td.amount"));
    }
  }
  return total;
}

function update_gizmo_events_totals() {
  gizmo_events = find_these_lines('gizmo_event_lines');
  for (var i = 0; i < gizmo_events.length; i++)
  {
    thing = gizmo_events[i];

    var multiplier = defined(discount_schedules)
      ? (discount_schedules[$('sale_discount_schedule_id').value][parseInt(getValueBySelector(thing, ".gizmo_type_id"))])
      : 1;
    var amount_b4_discount = cent_value(get_node_value(thing, ".unit_price")) * Math.floor(getValueBySelector(thing, ".gizmo_count"));
    var amount = multiplier * amount_b4_discount;
    if (isNaN(amount))
      amount = 0;
    var mystring = "$" + dollar_value(amount);
    thing.getElementsBySelector(".total_price").first().innerHTML = mystring;
  }
}

function get_hours_today () {
  var total = 0.0;
  var arr = find_these_lines('shift_lines');
  for (var x = 0; x < arr.length; x++) {
    total += parseFloat(getValueBySelector(arr[x], "td.duration"));
 }
  return total;
}

function get_donation_totals() {
  var totals = new Object();
  totals['required'] = 0;
  totals['suggested'] = 0;
  var arr = find_these_lines('gizmo_event_lines');
  for (var x = 0; x < arr.length; x++) {
    var type;
    var type_id = getValueBySelector(arr[x], "td.gizmo_type_id");
    type = (fees[type_id]['required'] > 0) ? 'required' : 'suggested';
    if($('covered') && getValueBySelector(arr[x], "td.covered") == "true")
      type = "suggested";
    totals[type] += cent_value(get_node_value(arr[x], "td.total_price"));
  }
  return totals;
}

/////////////////
// VALIDATIONS //
/////////////////

function validate_sale() {
}
function validate_donation() {
  var required = get_donation_totals()['required'];
  var payment = get_total_payment();
  return (payment >= required)
    || confirm("The total payments (" + dollar_value(payment) + ") do not cover the required amount (" + dollar_value(required) + "), is that ok?");
}
function validate_recycling() {
}
function validate_disbursement() {
}

///////////////////////////////
// HELPERS USED IN THE VIEWS //
///////////////////////////////

function is_tab(event) {
  return (event.keyCode==9 && !event.shiftKey);
}

function is_enabled_visable_there_field_thing(name) {
  var el = $(name);
  if(!el) {
    return false;
  }
  if(el == null) {
    return false;
  }
  if(el.disabled) {
    return false;
  }
  if(!el.visible) {
    return false;
  }
  return true;
}

function last_enabled_visable_there_field_thing_in_line_item(names) {
  var last = null;
  for(var i in names) {
    if(is_enabled_visable_there_field_thing(names[i])) {
      last = names[i];
    }
  }
  return last;
}

function is_last_enabled_visable_there_field_thing_in_line_item(name, names) {
  if(last_enabled_visable_there_field_thing_in_line_item(names) == name) {
    return true;
  } else {
    return false;
  }
}

function last_and_tab(event) {
  linelist = ['gizmo_count', 'system_id', 'contract_id','covered', 'unit_price'];
  return is_tab(event) && is_last_enabled_visable_there_field_thing_in_line_item(event.target.id, linelist);
}

function last_and_tab_p(event) {
  linelist = ['payment_amount', 'store_credit_id'];
  return is_tab(event) && is_last_enabled_visable_there_field_thing_in_line_item(event.target.id, linelist);
}

function handle_ge(event) {
  if(last_and_tab(event)) {
    if(event.target.onchange)
      event.target.onchange();
    return handle_gizmo_events();
  }
}

function handle_p(event) {
  if(last_and_tab_p(event)) {
    if(event.target.onchange)
      event.target.onchange();
    return handle_payments();
  }
}

function handle_s(event) {
  if(is_tab(event)) {
    if(event.target.onchange)
      event.target.onchange();
    return handle_shifts();
  }
}

///////////////////
// ADD LINE ITEM //
///////////////////

function add_payment(args) {
  args['prefix'] = 'payment';
  add_line_item(args, payment_stuff, eval(gizmo_context_name + "_compute_totals"), edit_payment);
}

function add_contact_method(contact_method_type_id, contact_method_usable, contact_method_value) {
  args = new Object();
  args['contact_method_type_id'] = contact_method_type_id;
  args['contact_method_usable'] = contact_method_usable;
  args['contact_method_value'] = contact_method_value;
  args['prefix'] = 'contact_method';
  add_line_item(args, contact_method_stuff, function () {}, false);
}

function add_gizmo_event(args){
  if(args['system_id'] != null && args['system_id'] != '') {
    if(is_a_list("" + args['system_id'])) {
      var list = strlist_to_arr("" + args['system_id']);
      var ni = 0;
      while (ni < list.length) {
        var i = list[ni];
        var newargs = new Object();
        for(var foo in args) {
          newargs[foo] = args[foo];
        }
        newargs['system_id'] = i;
        newargs['gizmo_count'] = 1;
        add_gizmo_event(newargs);
        ni++;
      }
      if(parseInt(args['gizmo_count']) > list.length) {
        var newargs = new Object();
        for(var foo in args) {
          newargs[foo] = args[foo];
        }
        newargs['system_id'] = '';
        newargs['gizmo_count'] = parseInt(args['gizmo_count']) - list.length;
        add_gizmo_event(newargs);
      }
      return;
    }
  }
  eval("add_" + gizmo_context_name + "_gizmo_event(args)");
}

function add_sale_gizmo_event(args) {
  args['prefix'] = 'gizmo_event';
  args['unit_price'] = dollar_cent_value(args['unit_price']);
  if(args['system_id'] == undefined) {
    args['system_id'] = '';
  }
  add_line_item(args, sales_hooks, sale_compute_totals, edit_gizmo_event);
}

function add_shift(args) {
  args['prefix'] = 'shift';
  add_line_item(args, shift_hook, shift_compute_totals, edit_shift);
}

function add_gizmo_return_gizmo_event(args) {
  args['prefix'] = 'gizmo_event';
  args['unit_price'] = dollar_cent_value(args['unit_price']);
  if(args['system_id'] == undefined) {
    args['system_id'] = '';
  }
  add_line_item(args, sales_hooks, gizmo_return_compute_totals, edit_gizmo_event);
}

function add_disbursement_gizmo_event(args) {
  args['prefix'] = 'gizmo_event';
  if(args['system_id'] == undefined) {
    args['system_id'] = '';
  }
  if(args['covered'] == undefined) {
    args['covered'] = '';
  }
  add_line_item(args, disbursements_hooks, update_contract_notes, edit_gizmo_event);
}

function add_recycling_gizmo_event(args) {
  args['prefix'] = 'gizmo_event';
  if(args['contract_id'] == undefined) {
    args['contract_id'] = '';
  }
  if(args['covered'] == undefined) {
    args['covered'] = '';
  }
  add_line_item(args, recycling_hooks, function(){}, edit_gizmo_event);
}

function add_donation_gizmo_event(args) {
  args['unit_price'] = dollar_cent_value(args['unit_price']);
  args['prefix'] = 'gizmo_event';
  if(args['covered'] == undefined) {
    args['covered'] = '';
  }
  add_line_item(args, donation_hooks, donation_compute_totals, edit_gizmo_event);
}

///////////////
// ONCHANGES //
///////////////

function coveredness_type_selected() {
  if($('covered') == null)
    return;
  if(gizmo_types_covered[$('gizmo_type_id').value] == true) {
    if($('covered').disabled) {
      $('covered').enable();
      $('covered').checked = true;
    }
  }
  else {
    if(!$('covered').disabled) {
      $('covered').disable();
      $('covered').checked = false;
    }
  }
  if($('covered').disabled) {
    $('covered').checked = false;
  }
}
function get_name_of_selected(name) {
  return $(name).options[$(name).selectedIndex].innerHTML;
}
function sale_payment_method_selected(){
  if(get_name_of_selected('payment_method_id') == "store credit") {
    $('store_credit_id').enable();
    $('payment_amount').disable();
    if((typeof(old_selected_payment_method) == "undefined" || old_selected_payment_method != "store credit")) {
      $('payment_amount').value = "";
      $('store_credit_id').value = "";
    }
  } else if (get_name_of_selected('payment_method_id') != "store credit"){
    $('store_credit_id').disable();
    $('payment_amount').enable();
    if((typeof(old_selected_payment_method) == "undefined") || old_selected_payment_method == "store credit") {
      $('payment_amount').value = "";
      $('store_credit_id').value = "";
    }
  }
  old_selected_payment_method = get_name_of_selected('payment_method_id');
}
function donation_payment_method_selected(){
}
function sale_gizmo_type_selected() {
  coveredness_type_selected();
  systems_type_selected();
}
function gizmo_return_gizmo_type_selected() {
  systems_type_selected();
}
function donation_gizmo_type_selected() {
  coveredness_type_selected()
  if($('covered') && $('covered').checked == true) {
    $('unit_price').value = dollar_value(first(fees[$('gizmo_type_id').value]['suggested'], fees[$('gizmo_type_id').value]['required']));
  } else {
    $('unit_price').value = dollar_value(first(fees[$('gizmo_type_id').value]['required'], fees[$('gizmo_type_id').value]['suggested']));
  }
  if (dollar_value(fees[$('gizmo_type_id').value]['required']) == $('unit_price').value) {
    $('unit_price').disabled=false;
  }
  else {
    $('unit_price').disabled=true;
  }
  if($('unit_price').disabled == false && $('covered') != null && $('covered').checked == true)
    $('unit_price').disabled = true;
}
function recycling_gizmo_type_selected() {
  coveredness_type_selected();
}
function disbursement_gizmo_type_selected() {
  coveredness_type_selected();
  systems_type_selected();
}
function systems_type_selected() {
  if($('system_id') == null)
    return;
  if(system_types.include($('gizmo_type_id').value)) {
    $('system_id').enable();
  } else {
    $('system_id').disable();
    $('system_id').value = '';
  }
}

function contact_contact_method_selected() {
}

/////////
// END //
/////////
