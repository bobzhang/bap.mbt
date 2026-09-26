// Port of BAP `plugins/mips/mips_dsl.ml`: helpers used to describe the
// instruction semantics on top of the RTL layer.

///|
let bit : Int = 1

///|
let byte : Int = 8

///|
let halfword : Int = 16

///|
let word : Int = 32

///|
let doubleword : Int = 64

///|
let quadword : Int = 128

///|
fn make_word(width : Int, value : Int64) -> @types.Word raise @mc.LiftError {
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
fn uconst(width : Int, value : Int) -> Exp raise @mc.LiftError {
  Exp::of_word(make_word(width, value.to_int64()))
}

///|
let zero : Exp = Exp::of_word(@types.Word::b0())

///|
let one : Exp = Exp::of_word(@types.Word::b1())

///|
/// `last e bits` - the `bits` most significant bits of `e`.
fn last(e : Exp, bits : Int) -> Exp raise @mc.LiftError {
  e.extract(e.width - 1, e.width - bits)
}

///|
/// `first e bits` - the `bits` least significant bits of `e`.
fn first(e : Exp, bits : Int) -> Exp raise @mc.LiftError {
  e.extract(bits - 1, 0)
}

///|
/// `high width e` - the high `width` bits of `e`.
fn high(width : Int, e : Exp) -> Exp raise @mc.LiftError {
  last(e, width)
}

///|
/// `low width e` - the low `width` bits of `e`.
fn low(width : Int, e : Exp) -> Exp raise @mc.LiftError {
  first(e, width)
}

///|
/// `lsb e` - the least significant bit of `e`.
fn lsb(e : Exp) -> Exp raise @mc.LiftError {
  e.extract(0, 0)
}

///|
/// `nth width e index` - the `index`-th `width`-sized chunk of `e`,
/// counting from the least significant chunk.
fn nth(width : Int, e : Exp, index : Int) -> Exp raise @mc.LiftError {
  e.extract((index + 1) * width - 1, index * width)
}

///|
/// `when_ cond code` = `if_ cond code []`.
fn when_(cond : Exp, code : Array[Rtl]) -> Rtl {
  if_(cond, code, [])
}
