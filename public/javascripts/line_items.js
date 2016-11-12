/////////////////////////////////////
// ALIASES TO BE CALLED FROM VIEWS //
/////////////////////////////////////

function handle_gizmo_events(){
  return _add_gizmo_event_from_form();
}

function handle_payments(){
  return add_payment_from_form();
}

function handle_all(){
  handle_gizmo_events();
  if($('payment_amount')) {
    handle_payments();
  }
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
  var elms = node.getElementsBySelector(id);
  if(elms.length == 0) {
    return null;
  }
  return elms.first().lastChild.data.replace(/\$/, '')
}

// this one gets the hidden part
function getValueBySelector(thing, selector) {
  return thing.getElementsBySelector(selector).first().firstChild.value;
}

function find_these_lines(name){
  return $(name + "_lines").getElementsBySelector("tr.line");
}

////////////////////
// LINE ITEM JUNK //
////////////////////

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
  tr.appendChild(make_hidden(args['prefix'], "id", "", args['id'], counters[prefix + '_line_id']));
  $(prefix + '_lines').lastChild.insertBefore(tr, $(prefix + '_form'));
  counters[args['prefix'] + '_line_id']++;
  update_hook();
}

function make_hidden(prefix, name, display_value, value, line_id){
  hidden = document.createElement("input");
  hidden.name = prefix + '[-' + line_id + '][' + name + ']';
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
  if($('gizmo_count') != null) {
    $('gizmo_count').value = getValueBySelector(thing, ".gizmo_count");
  }
  if($('barcode') != null) {
    $('barcode').value = getValueBySelector(thing, ".barcode");
  }
  if($('system_id') != null) {
    $('system_id').value = getValueBySelector(thing, ".system_id");
  }
  if($('contract_id') != null) {
    $('contract_id').value = getValueBySelector(thing, ".recycling_contract_id");
    $('contract_id').onchange();
  }
  if($('covered') != null) {
    $('covered').value = getValueBySelector(thing, ".covered");
    $('covered').enable();
    if($('covered').onchange) {
      $('covered').onchange();
    }
  }
  coveredness_type_selected();
  if($('unit_price') != null) {
    $('unit_price').value = getValueBySelector(thing, ".unit_price");
  }
  if($('reason') != null) {
    $('reason').value = getValueBySelector(thing, ".reason");
    $('tester').value = getValueBySelector(thing, ".tester");
    $('sale_id').value = getValueBySelector(thing, ".return_sale_id");
    $('disbursement_id').value = getValueBySelector(thing, ".return_disbursement_id");
    $('store_credit_hash').value = getValueBySelector(thing, ".store_credit_hash");
  }
  if($('discount') != null) {
    $('discount').value = getValueBySelector(thing, ".discount");
  }
  $('description').value = getValueBySelector(thing, ".description");
  $('gizmo_type_id').focus();
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
  if($('coupon_details')) {
    $('coupon_details').value = getValueBySelector(thing, ".coupon_details");
  }
  $('payment_method_id').focus();
}

/////////////////////////
// ADD JUNK FROM FORMS //
/////////////////////////

function update_amount_for_storecredit() {
  var a = dollar_value(get_storecredit_amount($('store_credit_id').value));
  if(a == "0.00") {
    a = "";
  }
  $('payment_amount').value = a;
//  alert_for_storecredit($('store_credit_id').value);
}

systems_invalid = false;

function _add_gizmo_event_from_form()
{
  if(systems_invalid || $('gizmo_type_id').value == "" || ($('covered') != null && (!$('covered').disabled) && $('covered').selectedIndex == 0) || ($('unit_price') != null && $('unit_price').value == '') || ($('gizmo_count') != null && $('gizmo_count').value == '')) {
    return true;
  }
  if($('system_id') != null && $('gizmo_count') != null) {
    var list = strlist_to_arr($('system_id').value);
    if(parseInt($('gizmo_count').value) != list.length && list.length != 0) {
      alert("you gave a different number of system ids than the number of gizmos. If you have systems without an ID they will need to be entered separately, please fix this and try again.");
  if($('barcode') != null) {
    $('barcode').focus();
  } else {
    $('gizmo_type_id').focus();
  }
      return true;
    }
  }
  var args = new Object();
  args['gizmo_type_id'] = $('gizmo_type_id').value;
  if($('gizmo_count') != null) {
    args['gizmo_count'] = $('gizmo_count').value;
  }
  args['description'] = $('description').value;
  if($('unit_price') != null) {
    args['unit_price'] = $('unit_price').value;
  }
  if($('discount') != null) {
    args['discount'] = $('discount').options[$('discount').selectedIndex].text;
    args['discount_id'] = $('discount').value;
  }
  if($('system_id') != null) {
    args['system_id'] = $('system_id').value;
  }
  if($('reason') != null) {
    args['reason'] = $('reason').value;
    args['tester'] = $('tester').value;
    if((!gt_is_sc()) && $('sale_id').value == "" && $('disbursement_id').value == "") {
      $('sale_id').value = prompt("You didn't enter a sale or disbursement id. If this is a sale, please enter the sale id now, or continue if it was a disbursement or you are sure you don't want to enter the id.");
    }
    if((!gt_is_sc()) && $('sale_id').value == "" && $('disbursement_id').value == "") {
      $('disbursement_id').value = prompt("You didn't enter a sale or disbursement id. If this is a disbursement, please enter the disbursement id now, or continue if you are sure you don't want to enter one. You can cancel to go back to enter the sale id.");
    }
    while((!gt_is_sc()) && $('sale_id').value != "" && !sale_exists($('sale_id').value)) {
      $('sale_id').value = prompt("You entered a nonexistant sale id. Please enter a correct one now, or continue without entering one if you want to leave it blank.");
    }
    while((!gt_is_sc()) && $('disbursement_id').value != "" && !disbursement_exists($('disbursement_id').value)) {
      $('disbursement_id').value = prompt("You entered a nonexistant disbursement id. Please enter a correct one now, or continue without entering one if you want to leave it blank.");
    }
    args['sale_id'] = $('sale_id').value;
    args['disbursement_id'] = $('disbursement_id').value;
    args['store_credit_hash'] = $('store_credit_hash').value;
  }
  if($('covered') != null) {
    args['covered'] = $('covered').value;
  }
  if($('barcode') != null) {
    args['barcode'] = $('barcode').value;
  }
  if($('contract_id') != null) {
    args['contract_id'] = $('contract_id').value;
  }
  add_gizmo_event(args);
  $('gizmo_type_id').selectedIndex = 0; //should be default, but it's yucky
  if($('unit_price') != null) {
    $('unit_price').enable();
  }
  if($('barcode') != null) {
    $('barcode').value = $('barcode').defaultValue;
    $('barcode').disable();
  }
  $('description').value = $('description').defaultValue;
  if($('unit_price') != null) {
    $('unit_price').value = $('unit_price').defaultValue;
  }
  if($('gizmo_count') != null) {
    $('gizmo_count').value = $('gizmo_count').defaultValue;
  }
  if($('system_id') != null) {
    $('system_id').value = $('system_id').defaultValue;
    // $('system_id').disable();
  }
  if($('reason') != null){
    $('reason').value = $('reason').defaultValue;
    $('tester').value = $('tester').defaultValue;
    $('sale_id').value = $('sale_id').defaultValue;
    $('disbursement_id').value = $('disbursement_id').defaultValue;
    $('store_credit_hash').value = $('store_credit_hash').defaultValue;
  }
  if($('discount') != null) {
    $('discount').selectedIndex = 0;
  }
  if($('covered') != null){
    $('covered').selectedIndex = 0;
    $('covered').disable();
    $('covered').value = "false";
  }
  if($('contract_id') != null) {
    $('contract_id').selectedIndex = 0;
  }
  $('gizmo_type_id').focus();
  return false;
}

function add_payment_from_form() {
  if(!has_a_price)
    return;
  if($('payment_method_id').selectedIndex == 0 || $('payment_amount').value == '') {
    return true;
  }
  if($('coupon_details') && (!$('coupon_details').disabled) && $('coupon_details').value == '') {
    return true;
  }
  var args = new Object();
  args['payment_method_id'] = $('payment_method_id').value;
  args['payment_amount'] = $('payment_amount').value;
  if($('store_credit_id')) {
    args['store_credit_id'] = $('store_credit_id').value;
  }
  if($('coupon_details')) {
    args['coupon_details'] = $('coupon_details').value;
  }
  add_payment(args);
  $('payment_method_id').selectedIndex = 0; //should be default, but it's yucky
  $('payment_amount').value = $('payment_amount').defaultValue;
  if($('store_credit_id')) {
    $('store_credit_id').value = $('store_credit_id').defaultValue;
  }
  if($('coupon_details')) {
    $('coupon_details').value = $('coupon_details').defaultValue;
  }
  $('payment_method_id').focus();
  return false;
}

//////////////////
// STUPID HOOKS //
//////////////////

function coveredness_stuff(args, tr){
  if(!coveredness_enabled)
    return;
  if($('covered') == null)
    return;
  var line_id = counters[args['prefix'] + '_line_id'];
  tr.appendChild(make_hidden(args['prefix'], "covered", args['covered'], args['covered'], line_id));
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
        hidden.name = args['prefix'] + '[-' + line_id + '][system_id]';
        hidden.value = args['system_id'];
        hidden.type = 'hidden';
        td = document.createElement("td");
        td.className = "system_id";
        td.appendChild(hidden);
        td.appendChild(document.createTextNode(args['system_id'] + "["));
        a = document.createElement("a");
        a.href = "/spec_sheets/fix_contract_edit?system_id=" + args['system_id'];
        a.target = "_blank";
        a.appendChild(document.createTextNode(all_contracts_names[get_system_contract(args['system_id'])]));
        td.appendChild(a);
        td.appendChild(document.createTextNode("]"));
        tr.appendChild(td);
      } else {
        tr.appendChild(make_hidden(args['prefix'], "system_id", args['system_id'], args['system_id'], line_id));
      }
    }
    else {
      tr.appendChild(make_hidden(args['prefix'], "system_id", "", "", line_id));
    }
  }
  else {
    tr.appendChild(make_hidden(args['prefix'], "system_id", "", "", line_id));
  }
}

function contracts_stuff(args, tr){
  if($('contract_id') != null) {
    var line_id = counters[args['prefix'] + '_line_id'];
    var contract = all_contracts[args['contract_id']];
    tr.appendChild(make_hidden(args['prefix'], "recycling_contract_id", contract, args['contract_id'], line_id));
  }
}

function unit_price_stuff(args, tr){
  if(!has_a_price)
    return;
  var line_id = counters[args['prefix'] + '_line_id'];
  tr.appendChild(make_hidden(args['prefix'], "unit_price", args['unit_price'], args['unit_price'], line_id));
  if($('discount') != null) {
    var dis = make_hidden(args['prefix'], "discount", args['discount'], args['discount_id'], line_id);
    tr.appendChild(dis);
    set_visibility(dis, discount_visible & 1);
  }
  if($('gizmo_count') != null) {
    td = document.createElement("td");
    td.appendChild(make_hidden(args['prefix'], "total_price", "$0.00", "$0.00", line_id));
    tr.appendChild(td);
  }
}

function returns_stuff(args,tr) {
  if($('reason') == null) {
    return;
  }
  var line_id = counters[args['prefix'] + '_line_id'];
  var reason = args['reason'];
  var tester = args['tester'];
  var sale_id = args['sale_id'];
  var disbursement_id = args['disbursement_id'];
  var sc_hash = args['store_credit_hash'];
  tr.appendChild(make_hidden(args['prefix'], "return_sale_id", sale_id, sale_id, line_id));
  tr.appendChild(make_hidden(args['prefix'], "return_disbursement_id", disbursement_id, disbursement_id, line_id));
  tr.appendChild(make_hidden(args['prefix'], "store_credit_hash", sc_hash, sc_hash, line_id));
  tr.appendChild(make_hidden(args['prefix'], "reason", reason.truncate(15), reason, line_id));
  tr.appendChild(make_hidden(args['prefix'], "tester", tester.truncate(15), tester, line_id));
}

function gizmo_events_stuff(args, tr){
  var gizmo_type_id = args['gizmo_type_id'];
  var gizmo_count = args['gizmo_count'];
  var description = args['description'];
  var gizmo_type = all_gizmo_types[gizmo_type_id];
  var line_id = counters[args['prefix'] + '_line_id'];
  tr.appendChild(make_hidden(args['prefix'], "gizmo_type_id", gizmo_type, gizmo_type_id, line_id));
  if($('barcode') != null) {
    barcode_stuff(args, tr);
  }
  var desc = make_hidden(args['prefix'], "description", description, description, line_id)
  set_visibility(desc, show_description & 1);
  tr.appendChild(desc);
  if($('gizmo_count') != null) {
    tr.appendChild(make_hidden(args['prefix'], "gizmo_count", gizmo_count, gizmo_count, line_id));
  }
}

function barcode_stuff(args, tr){
  var barcode = args['barcode'];
  var line_id = counters[args['prefix'] + '_line_id'];
  tr.appendChild(make_hidden(args['prefix'], "barcode", barcode, barcode, line_id));
}

function transaction_hooks(args, tr) {
  gizmo_events_stuff(args, tr);
  returns_stuff(args, tr);
  systems_stuff(args, tr);
  contracts_stuff(args, tr);
  coveredness_stuff(args, tr);
  unit_price_stuff(args, tr);
}

function payment_stuff(args, tr){
  var payment_amount = args['payment_amount'];
  var payment_method_id = args['payment_method_id'];
  var line_id = counters[args['prefix'] + '_line_id'];
  tr.appendChild(make_hidden(args['prefix'], "payment_method_id", payment_methods[payment_method_id], payment_method_id, line_id));
  amount_node = make_hidden(args['prefix'], "amount", payment_amount, payment_amount, line_id);
  amount_node.className = "amount";
  tr.appendChild(amount_node);
  if($('store_credit_id')) {
    var storecredit_id = args['store_credit_id'];
    tr.appendChild(make_hidden(args['prefix'], "store_credit_id", storecredit_id, storecredit_id, line_id));
  }
  if($('coupon_details')) {
    var coupon_details = args['coupon_details'];
    tr.appendChild(make_hidden(args['prefix'], "coupon_details", coupon_details, coupon_details, line_id));
  }
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
  lines = find_these_lines('gizmo_events');
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

function get_system_pricing(system_id) {
  var val;
  if(system_id != "" && !system_pricing_cache[system_id]) {
    var myhash = new Hash();
    myhash.set('barcode', system_id);
    var str = myhash.toQueryString();
    ge_thinking();
    new Ajax.Request(get_system_pricing_url + '?' + str, {asynchronous:false, evalScripts:true});
  }
  val = system_pricing_cache[system_id];
  if(val != undefined) {
    apply_ge_hash(val);
    return true;
  }
  return false;
}

function barcode_selected() {
  if($('barcode')) {
    return get_system_pricing($('barcode').value);
  }
}

function apply_ge_hash(hash) {
  $('system_id').value = hash['system_id'];
  $('gizmo_type_id').value = hash['gizmo_type_id'];
  $('description').value = hash['description'];
  if(hash['description'] != "") {
    on_description();
  }
  $('unit_price').value = hash['unit_price'];
  $('gizmo_count').value = hash['gizmo_count'];
  coveredness_type_selected();
  handle_gizmo_events();
  return;
}

// OLDTODO: just pass the hash in the parameters: option below

function get_system_covered(system_id) {
  if(!system_covered_cache[system_id]) {
    get_system_contract(system_id);
  }
  return system_covered_cache[system_id];
}

function ge_thinking() {
  Element.show(line_item_loading_id);
  disable_ge_entry_line();
}

function ge_done() {
  Element.hide(line_item_loading_id);
  enable_ge_entry_line();
}

function get_system_contract(system_id){
  var val;
  if(system_contract_cache[system_id]) {
    val = system_contract_cache[system_id];
  } else {
    var myhash = new Hash();
    internal_system_contract_id = -2;
    myhash.set('system_id', system_id);
    var str = myhash.toQueryString();
    ge_thinking();
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
    st_lid = sc_loading_id;
    myhash.set('id', id);
    myhash.set('loading', st_lid);
    var str = myhash.toQueryString();
    Element.show(st_lid);
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

function sale_exists(sale_id){
  var val;
  if(sale_id_cache[sale_id]) {
    val = sale_id_cache[sale_id];
  } else {
    var myhash = new Hash();
    internal_sale_exists = -2;
    myhash.set('id', sale_id);
    var str = myhash.toQueryString();
    Element.show(line_item_loading_id);
    new Ajax.Request(get_sale_exists_url + '?' + str, {asynchronous:false, evalScripts:true});
    sale_id_cache[sale_id] = internal_sale_exists;
    val = internal_sale_exists;
  }
  if(val == -2) {
    alert("internal error");
  }
  return val;
}

function disbursement_exists(disbursement_id){
  var val;
  if(disbursement_id_cache[disbursement_id]) {
    val = disbursement_id_cache[disbursement_id];
  } else {
    var myhash = new Hash();
    internal_disbursement_exists = -2;
    myhash.set('id', disbursement_id);
    var str = myhash.toQueryString();
    Element.show(line_item_loading_id);
    new Ajax.Request(get_disbursement_exists_url + '?' + str, {asynchronous:false, evalScripts:true});
    disbursement_id_cache[disbursement_id] = internal_disbursement_exists;
    val = internal_disbursement_exists;
  }
  if(val == -2) {
    alert("internal error");
  }
  return val;
}

function has_alert_for_storecredit(id) {
  return (storecredit_errors_cache[id] != null);
}

function alert_for_storecredit(id) {
  if(has_alert_for_storecredit(id)) {
    alert(storecredit_errors_cache[id]);
  }
}

function donation_compute_totals() {
  if($("gizmo_events_lines") == null || $('payments_lines') == null) {
    // TODO: code that computes invoice payments goes here.
    return;
  }
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
  $('discount_amt').innerHTML = dollar_value(discount);
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
  var subtotal = get_subtotal();
  $('grand_total').innerHTML = dollar_value(subtotal);
}

function get_grand_total(){
  var total = 0;
  var arr = find_these_lines('gizmo_events');
  for (var x = 0; x < arr.length; x++) {
    total += cent_value(get_node_value(arr[x], "td.total_price"));
  }
  return total;
}

function get_subtotal() {
  var total = 0;
  var arr = find_these_lines('gizmo_events');
  for (var x = 0; x < arr.length; x++) {
    count = get_node_value(arr[x], "td.gizmo_count");
    if(count == null) {
      count = 1;
    }
    total += (count * cent_value(get_node_value(arr[x], "td.unit_price")));

  }
  return total;
}

function get_total_payment() {
  var total = 0;
  var arr = find_these_lines('payments');
  for (var x = 0; x < arr.length; x++) {
    total += cent_value(get_node_value(arr[x], "td.amount"));
  }
  return total;
}

function get_storecredit(){
  var total = 0;
  var arr = find_these_lines('payments');
  for (var x = 0; x < arr.length; x++) {
    if(get_node_value(arr[x], "td.payment_method_id") == "store credit") {
      total += cent_value(get_node_value(arr[x], "td.amount"));
    }
  }
  return total;
}

function get_not_storecredit(){
  var total = 0;
  var arr = find_these_lines('payments');
  for (var x = 0; x < arr.length; x++) {
    if(get_node_value(arr[x], "td.payment_method_id") != "store credit") {
      total += cent_value(get_node_value(arr[x], "td.amount"));
    }
  }
  return total;
}

function update_gizmo_events_totals() {
  if($("gizmo_events_lines") == null) {
    return;
  }
  gizmo_events = find_these_lines('gizmo_events');
  for (var i = 0; i < gizmo_events.length; i++)
  {
    thing = gizmo_events[i];

    var multiplier = 1;
    if($('sale_discount_percentage_id') != null) {
      var percent = get_percentage_field_value('sale_discount_percentage_id');
      if(get_node_value(thing, ".discount") != "sale") {
        percent = parseInt(get_node_value(thing, ".discount"));
      }

      multiplier = !(not_discounted[parseInt(getValueBySelector(thing, ".gizmo_type_id"))]) ? (100 - percent) / 100 : 1;
    }

    var amount_b4_discount = cent_value(get_node_value(thing, ".unit_price")) * Math.floor(getValueBySelector(thing, ".gizmo_count"));
    var amount = multiplier * amount_b4_discount;
    if (isNaN(amount))
      amount = 0;
    var mystring = "$" + dollar_value(amount);
    thing.getElementsBySelector(".total_price").first().innerHTML = mystring;
  }
}

function get_donation_totals() {
  if($("gizmo_events_lines") == null || $('payments_lines') == null) {
    return;
  }
  var totals = new Object();
  totals['required'] = 0;
  totals['suggested'] = 0;
  var arr = find_these_lines('gizmo_events');
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

function ge_linelist() {
  return ['gizmo_type_id', 'gizmo_count', 'sale_id', 'disbursement_id', 'store_credit_hash', 'reason', 'tester', 'system_id', 'contract_id','covered', 'unit_price'];
}

function disable_ge_entry_line(){
  if(typeof(ge_entry_enabled_arr) == "undefined") {
    ge_entry_enabled_arr = new Array();
  }
  var ge_entry_enabled_hash = new Hash();
  var list = ge_linelist();
  for(var q = 0; q < list.size(); q++) {
    var i = list[q];
    var o = $(i);
    if(o != null) {
      ge_entry_enabled_hash.set(i, (!o.disabled).toString());
      o.disable();
    }
  }
  disable_all_links();
  ge_entry_enabled_arr.push(ge_entry_enabled_hash);
}

function enable_ge_entry_line(){
  var ge_entry_enabled_hash = ge_entry_enabled_arr.pop();
  if(typeof(ge_entry_enabled_arr) == "undefined") {
    return;
  }
  enable_all_links();
  var list = ge_linelist();
  for(var q = 0; q < list.size(); q++) {
    var i = list[q];
    var o = $(i);
    if(o != null && ge_entry_enabled_hash.get(i) == "true") {
      o.enable();
    }
  }
}

function last_and_tab(event) {
  linelist = ge_linelist();
  return is_tab(event) && is_last_enabled_visable_there_field_thing_in_line_item(event.target.id, linelist);
}

function last_and_tab_p(event) {
  linelist = ['payment_amount', 'store_credit_id', 'coupon_details'];
  return is_tab(event) && is_last_enabled_visable_there_field_thing_in_line_item(event.target.id, linelist);
}

function handle_ge(event) {
  if(is_tab(event)) {
    if(event.target.onchange) {
      event.target.onchange();
    }
    if(last_and_tab(event)) {
      return handle_gizmo_events();
    }
  }
}

function handle_p(event) {
  if(is_tab(event)) {
    if(event.target.id == 'store_credit_id') {
      update_amount_for_storecredit();
      if(get_storecredit_amount(event.target.value) == null) {
        event.target.focus();
        return false;
      }
    }
    if(last_and_tab_p(event)) {
      return handle_payments();
    }
  }
}

///////////////////
// ADD LINE ITEM //
///////////////////

function add_payment(args) {
  args['prefix'] = 'payments';
  add_line_item(args, payment_stuff, eval(gizmo_context_name + "_compute_totals"), edit_payment);
}

function add_gizmo_event(args){
  if(args['system_id'] != null && args['system_id'] != '' && args['gizmo_count'] != null) {
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
        newargs['covered'] = get_system_covered(i);
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
  args['prefix'] = 'gizmo_events';
  args['unit_price'] = dollar_cent_value(args['unit_price']);
  if(args['system_id'] == undefined) {
    args['system_id'] = '';
  }
  add_line_item(args, transaction_hooks, sale_compute_totals, edit_gizmo_event);
}

function add_gizmo_return_gizmo_event(args) {
  args['prefix'] = 'gizmo_events';
  args['unit_price'] = dollar_cent_value(args['unit_price']);
  if(args['system_id'] == undefined) {
    args['system_id'] = '';
  }
  add_line_item(args, transaction_hooks, gizmo_return_compute_totals, edit_gizmo_event);
}

function add_disbursement_gizmo_event(args) {
  args['prefix'] = 'gizmo_events';
  if(args['system_id'] == undefined) {
    args['system_id'] = '';
  }
  if(args['covered'] == undefined) {
    args['covered'] = '';
  }
  add_line_item(args, transaction_hooks, update_contract_notes, edit_gizmo_event);
}

function add_recycling_gizmo_event(args) {
  args['prefix'] = 'gizmo_events';
  if(args['contract_id'] == undefined) {
    args['contract_id'] = '';
  }
  if(args['covered'] == undefined) {
    args['covered'] = '';
  }
  add_line_item(args, transaction_hooks, function(){}, edit_gizmo_event);
}

function add_donation_gizmo_event(args) {
  args['unit_price'] = dollar_cent_value(args['unit_price']);
  args['prefix'] = 'gizmo_events';
  if(args['covered'] == undefined) {
    args['covered'] = '';
  }
  add_line_item(args, transaction_hooks, donation_compute_totals, edit_gizmo_event);
}

///////////////
// ONCHANGES //
///////////////

function contract_selected () {
  coveredness_type_selected();
}

function system_selected() {
  coveredness_type_selected();
}

function storecredit_selected () {
  var val = dollar_value(get_storecredit_amount($('store_credit_hash').value));
  alert_for_storecredit($('store_credit_hash').value);
  if(val == "0.00") {
    val="";
  }
  $('unit_price').value = val;
}
function coveredness_type_selected() {
  if($('covered') == null)
    return;
  contract_widget = $('contract_id') || $('donation_contract_id');
  systems_invalid = false;
  if(gizmo_context == "sale" ? (system_types.include($('gizmo_type_id').value) || $('gizmo_type_id').value == "") : gizmo_types_covered[$('gizmo_type_id').value] == true) {
    if(contract_widget && contract_widget.value != "1") {
      $('covered').disable();
      $('covered').value = "false";
    } else if($('system_id') && $('system_id').value && is_a_list($('system_id').value)) {
      $('covered').disable();
      $('covered').value = "nil";

      var list = strlist_to_arr("" + $('system_id').value);
      var ni = 0;
      while (ni < list.length) {
        var i = list[ni];
        var v = get_system_contract(i);
        if(v == -1) {
          systems_invalid = true;
          alert('System ID #' + i + ' from system list is invalid, please remove or correct it.');
        }
        ni++;
      }
    } else if($('system_id') && $('system_id').value && !is_a_list($('system_id').value) && get_system_covered($('system_id').value) != "nil") {
      $('covered').value = get_system_covered($('system_id').value);
      $('covered').disable();
    } else {
      if($('covered').disabled) {
        $('covered').enable();
        $('covered').value = "nil";
      }
    }
  }
  else {
    if(!$('covered').disabled) {
      $('covered').disable();
      $('covered').value = "false";
    }
  }
}
function get_name_of_selected(name) {
  return $(name).options[$(name).selectedIndex].innerHTML;
}
function sale_payment_method_selected(){
  if($('store_credit_id') == null)
    return;
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
  if(get_name_of_selected('payment_method_id') == "coupon") {
    $('coupon_details').enable();
  } else {
    $('coupon_details').disable();
    if((typeof(old_selected_payment_method) == "undefined") || old_selected_payment_method == "coupon") {
      $('coupon_details').value = "";
    }
  }
  old_selected_payment_method = get_name_of_selected('payment_method_id');
}
function donation_payment_method_selected(){
}
function gizmo_type_selected() {
  coveredness_type_selected();
  systems_type_selected();
  eval(gizmo_context_name + "_gizmo_type_selected();");
}
function sale_gizmo_type_selected() {
}

function gt_is_sc() {
  return get_name_of_selected('gizmo_type_id') == "Store Credit";
}
function gizmo_return_gizmo_type_selected() {
  if(gt_is_sc()) {
    $('sale_id').disabled = true;
    $('disbursement_id').disabled = true;
    $('unit_price').disabled = true;
    $('reason').disabled = true;
    $('tester').disabled = true;
    $('store_credit_hash').disabled = false;
  } else {
    $('sale_id').disabled = false;
    $('disbursement_id').disabled = false;
    $('unit_price').disabled = false;
    $('reason').disabled = false;
    $('tester').disabled = false;
    $('store_credit_hash').disabled = true;
    $('store_credit_hash').value = $('store_credit_hash').defaultValue;
  }
}
function donation_gizmo_type_selected() {
  if($('covered') && $('covered').value == "true") {
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
  if($('unit_price').disabled == false && $('covered') != null && $('covered').value == "true")
    $('unit_price').disabled = true;
}
function recycling_gizmo_type_selected() {
}
function disbursement_gizmo_type_selected() {
  coveredness_type_selected();
  systems_type_selected();
}
function gizmo_type_left() {
  if($('system_id') == null)
    return;
  if(system_types.include($('gizmo_type_id').value) || $('gizmo_type_id').value == "") {
    if($('sale_contact_type') && $('sale_contact_type').value != 'named') {
      $('sale_contact_type').value = 'named';
      trigger_change_on($('sale_contact_type'));
    }
  }
}
function systems_type_selected() {
  if($('system_id') == null)
    return;
  if(system_types.include($('gizmo_type_id').value) || $('gizmo_type_id').value == "") {
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
