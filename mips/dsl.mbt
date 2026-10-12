// Port of BAP `plugins/mips/mips_dsl.ml`: helpers used to describe the
// instruction semantics on top of the RTL layer.

///|
let bit : Int32 = 1

///|
let byte : Int32 = 8

///|
let halfword : Int32 = 16

///|
let word : Int32 = 32

///|
let doubleword : Int32 = 64

///|
let quadword : Int32 = 128

///|
fn make_word(width : Int32, value : Int64) -> @types.Word raise @mc.LiftError {
  @types.Word::of_int64(value, width~) catch {
    _ => raise mips_fail("can't create a \{width}-bit word from \{value}")
  }
}

///|
fn apply_sign(sign : Sign, e : Exp) -> Exp {
  match sign {
    Signed => e.signed()
    Unsigned => e.unsigned()
  }
}

///|
/// Upstream `unsigned const width value`.
fn uconst(width : Int32, value : Int32) -> Exp raise @mc.LiftError {
  Exp::of_word(make_word(width, value.to_int64()))
}

///|
let zero : Exp = Exp::of_word(@types.Word::b0())

///|
let one : Exp = Exp::of_word(@types.Word::b1())

///|
/// `last e bits` - the `bits` most significant bits of `e`.
fn last(e : Exp, bits : Int32) -> Exp raise @mc.LiftError {
  e.extract(e.width - 1, e.width - bits)
}

///|
/// `first e bits` - the `bits` least significant bits of `e`.
fn first(e : Exp, bits : Int32) -> Exp raise @mc.LiftError {
  e.extract(bits - 1, 0)
}

///|
/// `high width e` - the high `width` bits of `e`.
fn high(width : Int32, e : Exp) -> Exp raise @mc.LiftError {
  last(e, width)
}

///|
/// `low width e` - the low `width` bits of `e`.
fn low(width : Int32, e : Exp) -> Exp raise @mc.LiftError {
  first(e, width)
}

///|
/// `nth width e index` - the `index`-th `width`-sized chunk of `e`,
/// counting from the least significant chunk.
fn nth(width : Int32, e : Exp, index : Int32) -> Exp raise @mc.LiftError {
  e.extract((index + 1) * width - 1, index * width)
}

///|
/// `when_ cond code` = `if_ cond code []`.
fn when_(cond : Exp, code : Array[Rtl]) -> Rtl {
  if_(cond, code, [])
}
