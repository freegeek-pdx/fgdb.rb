var key_map = new Array();

function downcase(x) { return x.toLowerCase(); }

function normalize_key_binding(key) {
  var x = key.split("-");
  return x.length > 1 
    ? (x.slice(0,-1).map(downcase).sort().join("-") + "-" + x.last().toLowerCase())
    : key;
}

function bind_key(key, handler) {
  var key = normalize_key_binding(key);
  key_map[key] = handler;
}

function unbind_key(key) {
  delete key_map[normalize_key_binding(key)];
}
  
function key_handler(evt) {
  var key_sequence = "";
  if (evt.altKey) {
    key_sequence += "alt-";
  }
  if (evt.ctrlKey) {
    key_sequence += "ctrl-";
  }
  if (evt.shiftKey) {
    key_sequence += "shift-";
  }
  key_sequence += String.fromCharCode(evt.which || evt.charCode || evt.keyCode).toLowerCase();

  handler = key_map[key_sequence];

  return handler ? handler(evt) : false;
}

document.addEventListener('keypress', key_handler, true);
