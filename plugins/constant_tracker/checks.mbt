// The Primus Lisp checks shipped with the plugin (check-hardcoded-values.lisp
// and check-null-pointers.lisp), expressed over the tracker.

///|
/// The incident reported for a hardcoded socket address.
pub let hardcoded_socket_address : String = "hardcoded-socket-address"

///|
/// The incident reported for a dereference of a constant null pointer.
pub let null_pointer_dereference : String = "null-pointer-dereference"

///|
/// `check-hardcoded-socket-address`: the 16-byte socket address at `ptr` is
/// static data.
pub fn ConstantTracker::check_hardcoded_socket_address(
  self : ConstantTracker,
  ptr : UInt64,
  load : (UInt64) -> Int64?,
) -> String? {
  if self.points_to_static_data(ptr, 16, load) {
    Some(hardcoded_socket_address)
  } else {
    None
  }
}

///|
/// The `call` method of check-hardcoded-values.lisp: `accept`, `bind`, and
/// `connect` pass the address as the second argument, `sendto` and
/// `recvfrom` as the fifth one. `args` are the argument values.
pub fn ConstantTracker::check_call(
  self : ConstantTracker,
  callee : String,
  args : ArrayView[UInt64],
  load : (UInt64) -> Int64?,
) -> String? {
  match (callee, args.length()) {
    ("accept" | "bind" | "connect", 3) =>
      self.check_hardcoded_socket_address(args[1], load)
    ("sendto" | "recvfrom", 6) =>
      self.check_hardcoded_socket_address(args[4], load)
    _ => None
  }
}

///|
/// `check-null-pointer` (on `loading` and `storing`): the pointer is zero and
/// a static constant.
pub fn ConstantTracker::check_null_pointer(
  self : ConstantTracker,
  ptr : UInt64,
  id : Int64,
) -> String? {
  if ptr == 0 && self.is_const(id) {
    Some(null_pointer_dereference)
  } else {
    None
  }
}
