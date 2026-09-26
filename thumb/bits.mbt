// Port of `plugins/thumb/thumb_bits.ml`: sign/zero extensions.

///|
fn sx(
  width : Int,
  rd : @types.Var,
  rm : @types.Var,
  cnd : Cond,
) -> Array[@types.Stmt] {
  set_if(rd, signed32(low(width, v(rm))), cnd)
}

///|
fn ux(
  width : Int,
  rd : @types.Var,
  rm : @types.Var,
  cnd : Cond,
) -> Array[@types.Stmt] {
  set_if(rd, unsigned32(low(width, v(rm))), cnd)
}
