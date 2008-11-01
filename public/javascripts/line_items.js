function toggle_description(evt) {
  show_description++;
  var arr = document.getElementsByClassName('description');
  for (var i = 0; i < arr.length; i++) {
    set_visibility(arr[i], show_description & 1)
  }
  return true;
}

function add_line_item(args, hook1, hook2, update_hook, edit_hook, show_edit_button){
  var prefix = args['prefix'];
  var id = prefix + '_' + counters[prefix + '_line_id'] + '_line'
    tr = document.createElement("tr");
  tr.className = "line";
  tr.id = id;
  hook1(args, tr);
  hook2(args, tr);
  td = document.createElement("td");
  a = document.createElement("a");
  a.onclick = function () {
    edit_hook(id);
    Element.remove(id);
    update_hook();
  };
  if(show_edit_button) {
    a.appendChild(document.createTextNode('e'));
    td.appendChild(a);
  }
  td.appendChild(document.createTextNode(' '));
  a = document.createElement("a");
  a.onclick = function () {
    Element.remove(id);
    update_hook();
  };
  a.appendChild(document.createTextNode('x'));
  td.appendChild(a);
  tr.appendChild(td);
  $(prefix + '_lines').lastChild.insertBefore(tr, $(prefix + '_lines').lastChild.lastChild.previousSibling);
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

function get_node_value(node, id) {
  return node.getElementsBySelector(id).first().lastChild.data.replace(/\$/, '');
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

function dollar_value(cents) {
  cents = "" + cents;
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

function systems_stuff(args, tr){
  if($('system_id') != null) {
    var line_id = counters[args['prefix'] + '_line_id'];
    tr.appendChild(make_hidden("line", "system_id", args['system_id'], args['system_id'], line_id));
  }
}

function sales_stuff(args, tr){
  systems_stuff(args, tr);
  var line_id = counters[args['prefix'] + '_line_id'];
  tr.appendChild(make_hidden("line", "unit_price", args['unit_price'], args['unit_price'], line_id));
  td = document.createElement("td");
  td.appendChild(make_hidden("line", "total_price", "$0.00", "$0.00", line_id));
  tr.appendChild(td);
}

function gizmo_events_stuff(args, tr){
  var gizmo_type_id = args['gizmo_type_id'];
  var gizmo_count = args['gizmo_count'];
  var description = args['description'];
  var gizmo_type = all_gizmo_types[gizmo_type_id];
  var line_id = counters[args['prefix'] + '_line_id'];
  tr.appendChild(make_hidden("line", "gizmo_type_id", gizmo_type, gizmo_type_id, line_id));
  var desc = make_hidden("line", "description", description, description, line_id)
  set_visibility(desc, show_description);
  tr.appendChild(desc);
  tr.appendChild(make_hidden("line", "gizmo_count", gizmo_count, gizmo_count, line_id));
}

function add_priced_gizmo_event(gizmo_type_id, gizmo_count, unit_price, description) {
  var args = new Array();
  args['gizmo_type_id'] = gizmo_type_id;
  args['unit_price'] = dollar_value(cent_value(unit_price));
  args['gizmo_count'] = gizmo_count;
  args['prefix'] = 'gizmo_event';
  args['description'] = description;
  return args;
}

function add_unpriced_gizmo_event(gizmo_type_id, gizmo_count) {
  var args = new Array();
  args['gizmo_type_id'] = gizmo_type_id;
  args['gizmo_count'] = gizmo_count;
  args['prefix'] = 'gizmo_event';
  return args;
}

function edit_sale(id) {
  thing = $(id);
  $('gizmo_type_id').value = thing.getElementsBySelector(".gizmo_type_id").first().firstChild.value;
  sale_gizmo_type_selected();
  $('gizmo_count').value = thing.getElementsBySelector(".gizmo_count").first().firstChild.value;
  if($('system_id') != null) {
    $('system_id').value = thing.getElementsBySelector(".system_id").first().firstChild.value;
  }
  $('unit_price').value = thing.getElementsBySelector(".unit_price").first().firstChild.value;
  $('description').value = thing.getElementsBySelector(".description").first().firstChild.value;
  $('gizmo_type_id').focus();
}

function edit_disbursement(id) {
  thing = $(id);
  $('gizmo_type_id').value = thing.getElementsBySelector(".gizmo_type_id").first().firstChild.value;
  disbursement_gizmo_type_selected();
  $('gizmo_count').value = thing.getElementsBySelector(".gizmo_count").first().firstChild.value;
  if($('system_id') != null) {
    $('system_id').value = thing.getElementsBySelector(".system_id").first().firstChild.value;
  }
  $('gizmo_type_id').focus();
}

function edit_payment(id) {
  thing = $(id);
  $('payment_method_id').value = thing.getElementsBySelector(".payment_method_id").first().firstChild.value;
  $('payment_amount').value = thing.getElementsBySelector(".amount").first().firstChild.value;
  $('payment_method_id').focus();
}

function add_sale_gizmo_event(gizmo_type_id, gizmo_count, unit_price, description, system_id) {
  var args = add_priced_gizmo_event(gizmo_type_id, gizmo_count, unit_price, description);
  args['system_id'] = system_id;
  if(args['system_id'] == undefined) {
    args['system_id'] = '';
  }
  add_line_item(args, gizmo_events_stuff, sales_stuff, sale_compute_totals, edit_sale, true);
}

function add_disbursement_gizmo_event(gizmo_type_id, gizmo_count, system_id) {
  var args = add_unpriced_gizmo_event(gizmo_type_id, gizmo_count);
  args['system_id'] = system_id;
  if(args['system_id'] == undefined) {
    args['system_id'] = '';
  }
  add_line_item(args, gizmo_events_stuff, systems_stuff, function(){}, edit_disbursement, true);
}

function add_recycling_gizmo_event(gizmo_type_id, gizmo_count) {
  add_disbursement_gizmo_event(gizmo_type_id, gizmo_count)
}

function add_donation_gizmo_event(gizmo_type_id, gizmo_count, unit_price, description) {
  var args = add_priced_gizmo_event(gizmo_type_id, gizmo_count, unit_price, description);
  add_edit_button = true;
  if(!gizmo_types[gizmo_type_id] && all_gizmo_types[gizmo_type_id])
    add_edit_button = false;
  add_line_item(args, gizmo_events_stuff, sales_stuff, donation_compute_totals, edit_sale, add_edit_button);
}

function add_priced_gizmo_event_from_form()
{
  if($('gizmo_type_id').selectedIndex == 0 || $('unit_price').value == '' || $('gizmo_count').value == '') {
    return true;
  }
  if(system_bad()) {
    return true;
  }
  string = "add_" + gizmo_context_name + "_gizmo_event($('gizmo_type_id').value, $('gizmo_count').value, $('unit_price').value, $('description').value";
  if($('system_id') != null) {
    string += ", $('system_id').value";
  }
  string += ");";
  eval(string);
  $('gizmo_type_id').selectedIndex = 0; //should be default, but it's yucky
  $('unit_price').enable();
  $('description').value = $('description').defaultValue;
  $('unit_price').value = $('unit_price').defaultValue;
  $('gizmo_count').value = $('gizmo_count').defaultValue;
  if($('system_id') != null) {
    $('system_id').value = $('system_id').defaultValue;
    $('system_id').disable();
  }
  $('gizmo_type_id').focus();
  return false;
}

function system_bad(){
  if($('system_id') != null && !$('system_id').disabled && $('system_id').value == '') {
    return true;
  } else {
    return false;
  }
}

function add_unpriced_gizmo_event_from_form()
{
  if($('gizmo_type_id').selectedIndex == 0 || $('gizmo_count').value == '') {
    return true;
  }
  if(system_bad()) {
    return true;
  }
  string = "add_" + gizmo_context_name + "_gizmo_event($('gizmo_type_id').value, $('gizmo_count').value";
  if($('system_id') != null) {
    string += ", $('system_id').value";
  }
  string += ");";
  eval(string);
  $('gizmo_type_id').selectedIndex = 0; //should be default, but it's yucky
  $('gizmo_count').value = $('gizmo_count').defaultValue;
  if($('system_id') != null) {
    $('system_id').value = $('system_id').defaultValue;
    $('system_id').disable();
  }
  $('gizmo_type_id').focus();
  return false;
}

function get_grand_total(){
  var total = 0;
  var arr = $('gizmo_event_lines').getElementsBySelector("tr.line");
  for (var x = 0; x < arr.length; x++) {
    total += cent_value(get_node_value(arr[x], "td.total_price"));
  }
  return total;
}

function get_subtotal() {
  var total = 0;
  var arr = $('gizmo_event_lines').getElementsBySelector("tr.line");
  for (var x = 0; x < arr.length; x++) {
    total += (get_node_value(arr[x], "td.gizmo_count") * cent_value(get_node_value(arr[x], "td.unit_price")));

  }
  return total;
}

function get_total_payment() {
  var total = 0;
  var arr = $('payment_lines').getElementsBySelector("tr.line");
  for (var x = 0; x < arr.length; x++) {
    total += cent_value(get_node_value(arr[x], "td.amount"));
  }
  return total;
}

function update_gizmo_events_totals() {
  gizmo_events = $('gizmo_event_lines').getElementsBySelector(".line");
  for (var i = 0; i < gizmo_events.length; i++)
  {
    thing = gizmo_events[i];

    var multiplier = defined(discount_schedules)
      ? (discount_schedules[$('sale_discount_schedule_id').value][parseInt(thing.getElementsBySelector(".gizmo_type_id").first().firstChild.value)])
      : 1;
    var amount_b4_discount = cent_value(get_node_value(thing, ".unit_price")) * Math.floor(thing.getElementsBySelector(".gizmo_count").first().firstChild.value);
    var amount = multiplier * amount_b4_discount;
    if (isNaN(amount))
      amount = 0;
    var mystring = "$" + dollar_value(amount);
    thing.getElementsBySelector(".total_price").first().innerHTML = mystring;
  }
}

function set_visibility(node, visibility) {
  if (visibility) {
    node.removeClassName("invisible");
  }
  else {
    node.addClassName("invisible");
  }
}

function get_donation_totals() {
  var totals = new Array();
  totals['required'] = 0;
  totals['suggested'] = 0;
  var arr = $('gizmo_event_lines').getElementsBySelector("tr.line");
  for (var x = 0; x < arr.length; x++) {
    var type_id = arr[x].getElementsBySelector("td.gizmo_type_id").first().firstChild.value;
    var type;
    type = (fees[type_id]['suggested'] > 0) ? 'suggested' : 'required';

    totals[type] += cent_value(get_node_value(arr[x], "td.total_price"));
  }
  return totals;
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
  var payment = get_total_payment();

  $('subtotal').innerHTML = dollar_value(subtotal);
  $('discount').innerHTML = dollar_value(discount);
  $('grand_total').innerHTML = dollar_value(grand_total);
  $('total_payments').innerHTML = dollar_value(payment);
  $('change_due').innerHTML = dollar_value(payment - grand_total);
  if(payment - grand_total < 0) {
    $('change_due_tr').addClassName('short_row');
  }
}

function payment_stuff(args, tr){
  var payment_amount = args['payment_amount'];
  var payment_method_id = args['payment_method_id'];
  var line_id = counters[args['prefix'] + '_line_id'];
  tr.appendChild(make_hidden("payments", "payment_method_id", payment_methods[payment_method_id], payment_method_id, line_id));
  amount_node = make_hidden("payments", "amount", payment_amount, payment_amount, line_id);
  amount_node.className = "amount";
  tr.appendChild(amount_node);
}

function add_payment(payment_method_id, payment_amount, compute_totals) {
  args = new Array();
  args['payment_method_id'] = payment_method_id;
  args['payment_amount'] = dollar_value(cent_value(payment_amount));
  args['prefix'] = 'payment';
  add_line_item(args, payment_stuff, function () {}, compute_totals, edit_payment);
}

function add_payment_from_form(compute_totals) {
  if($('payment_method_id').selectedIndex == 0 || $('payment_amount').value == '') {
    return true;
  }
  add_payment($('payment_method_id').value, $('payment_amount').value, compute_totals)
  $('payment_method_id').selectedIndex = 0; //should be default, but it's yucky
  $('payment_amount').value = $('payment_amount').defaultValue;
  $('payment_method_id').focus();
  return false;
}

function contact_method_stuff(args, tr){
  var contact_method_value = args['contact_method_value'];
  var contact_method_type_id = args['contact_method_type_id'];
  var contact_method_usable = args['contact_method_usable'];
  var line_id = counters[args['prefix'] + '_line_id'];
  tr.appendChild(make_hidden("contact_methods", "contact_method_type_id", contact_method_types[contact_method_type_id], contact_method_type_id, line_id));
  usable_node = make_hidden("contact_methods", "ok", contact_method_usable, contact_method_usable, line_id);
  usable_node.className = "ok";
  tr.appendChild(usable_node);
  description_node = make_hidden("contact_methods", "value", contact_method_value, contact_method_value, line_id);
  description_node.className = "description";
  tr.appendChild(description_node);
}

function add_contact_method(contact_method_type_id, contact_method_usable, contact_method_value) {
  args = new Array();
  args['contact_method_type_id'] = contact_method_type_id;
  args['contact_method_usable'] = contact_method_usable;
  args['contact_method_value'] = contact_method_value;
  args['prefix'] = 'contact_method';
  add_line_item(args, contact_method_stuff, function () {}, function () {});
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

function max(a,b) { return a>b ? a : b; }

function sale_gizmo_type_selected() {
  disbursement_gizmo_type_selected();
}
function donation_gizmo_type_selected() {
  $('unit_price').value = dollar_value(max(fees[$('gizmo_type_id').value]['required'], fees[$('gizmo_type_id').value]['suggested']));
  if (fees[$('gizmo_type_id').value]['required'] > fees[$('gizmo_type_id').value]['suggested']) {
    $('unit_price').disabled=false;
  }
  else {
    $('unit_price').disabled=true;
  }
}
function recycling_gizmo_type_selected() {
}
function disbursement_gizmo_type_selected() {
  if(system_types.include($('gizmo_type_id').value)) {
    $('system_id').enable();
    $('system_id').value = '';
  } else {
    $('system_id').disable();
    $('system_id').value = '';
  }
}
function contact_contact_method_selected() {
}

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
function is_tab(event) {
  return (event.keyCode==9 && !event.shiftKey);
}
