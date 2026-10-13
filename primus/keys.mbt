///|
/// Ordered wrapper around `Var` used as a persistent map key.
priv struct VarKey(@types.Var)

///|
impl Eq for VarKey with fn equal(self, other) {
  self.0.compare(other.0) == 0
}

///|
impl Compare for VarKey with fn compare(self, other) {
  self.0.compare(other.0)
}

///|
/// Ordered wrapper around `Word` (addresses) used as a persistent map key.
priv struct AddrKey(@types.Word)

///|
impl Eq for AddrKey with fn equal(self, other) {
  self.0.compare(other.0) == 0
}

///|
impl Compare for AddrKey with fn compare(self, other) {
  self.0.compare(other.0)
}

///|
/// Reads the `address` attribute of a term (upstream `Term.get_attr t
/// address`).
pub fn[T] term_address(t : @types.Term[T]) -> @types.Word? {
  match t.get_attr("address") {
    None => None
    Some(text) =>
      try @types.Word::from_string(text) catch {
        _ => None
      } noraise {
        w => Some(w)
      }
  }
}

///|
/// Bit width of the target's code/data addresses (falls back to 32 for
/// targets that do not specify it, like upstream `Theory.Target.unknown`).
fn target_bits(t : @core_theory.Target) -> Int32 {
  let b = t.bits()
  if b <= 0 {
    32
  } else {
    b
  }
}
