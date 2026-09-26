// Port of BAP `plugins/powerpc/powerpc_rtl.ml`.
//
// RTL is a tiny register-transfer language used to describe PowerPC
// instruction semantics. Every expression carries a bit width and a
// signedness; binary operations implicitly extend the narrower operand
// (respecting the derived signedness) and assignments implicitly cast the
// right-hand side to the shape of the left-hand side. RTL programs are
// lowered to BIL by `bil_of_rtl`.

///|
/// Signedness of an RTL expression.
pub(all) enum Sign {
  Signed
  Unsigned
} derive(Eq, Debug)

///|
pub extend Sign with Eq::{equal, not_equal}

///|
pub extend Sign with Debug::{to_repr}

///|
/// The shape of an RTL expression.
pub(all) enum RtlBody {
  /// A single variable, or a concatenation of variables (most significant
  /// first).
  Vars(@types.Var, Array[@types.Var])
  Word(@types.Word)
  Load(@types.Var, RtlBody, @bitvec.Endian, @types.Size)
  Concat(RtlBody, RtlBody)
  Binop(@types.BinOp, RtlBody, RtlBody)
  Extract(Int, Int, RtlBody)
  Cast(Sign, Int, RtlBody)
  Unop(@types.UnOp, RtlBody)
} derive(Eq, Debug)

///|
pub extend RtlBody with Eq::{equal, not_equal}

///|
pub extend RtlBody with Debug::{to_repr}

///|
/// An RTL expression: a body annotated with signedness and bit width.
pub struct RtlExp {
  body : RtlBody
  sign : Sign
  width : Int
} derive(Eq, Debug)

///|
pub extend RtlExp with Eq::{equal, not_equal}

///|
pub extend RtlExp with Debug::{to_repr}

///|
/// An RTL statement.
pub(all) enum Rtl {
  /// `lhs := rhs`
  Move(RtlExp, RtlExp)
  Jmp(RtlExp)
  Store(@types.Var, RtlExp, RtlExp, @bitvec.Endian, @types.Size)
  If(RtlExp, Array[Rtl], Array[Rtl])
  /// `Foreach(inverse, step, exp, code)` repeats `code` for each `step`
  /// sized chunk of `exp`; `inverse` starts from the most significant chunk.
  Foreach(Bool, RtlExp, RtlExp, Array[Rtl])
  Message(String)
} derive(Eq, Debug)

///|
pub extend Rtl with Eq::{equal, not_equal}

///|
pub extend Rtl with Debug::{to_repr}

///|
fn var_bitwidth(v : @types.Var) -> Int {
  match v.typ {
    Imm(width) => width
    // RTL never builds expressions out of memory variables; memories only
    // appear as the first component of `Load`/`Store`.
    Mem(value_width~, ..) => value_width
  }
}

///|
fn width_of_vars(vars : ArrayView[@types.Var]) -> Int {
  vars.fold(init=0, (acc, v) => acc + var_bitwidth(v))
}

///|
/// Build a word of `width` bits from a (possibly negative) integer, wrapping
/// modulo `2^width`. Widths used by the lifter are always positive.
fn make_word(width : Int, value : Int64) -> @types.Word {
  @types.Word::of_int64(value, width~) catch {
    _ => abort("PowerPC lifter: invalid word width \{width}")
  }
}

///|
/// Expression denoting variable `v` (unsigned).
pub fn RtlExp::of_var(v : @types.Var) -> RtlExp {
  { sign: Unsigned, width: var_bitwidth(v), body: Vars(v, []) }
}

///|
/// Expression denoting the concatenation of `vars` (most significant
/// first). `vars` must be non-empty.
pub fn RtlExp::of_vars(vars : ArrayView[@types.Var]) -> RtlExp {
  match vars {
    [] => abort("PowerPC lifter: empty var list")
    [v, .. rest] =>
      {
        sign: Unsigned,
        width: width_of_vars(vars),
        body: Vars(v, rest.to_owned()),
      }
  }
}

///|
/// Unsigned constant expression.
pub fn RtlExp::of_word(w : @types.Word) -> RtlExp {
  { sign: Unsigned, width: w.width(), body: Word(w) }
}

///|
/// Fresh virtual temporary of `width` bits.
pub fn RtlExp::tmp(width : Int) -> RtlExp {
  RtlExp::of_var(
    @types.Var::create("tmp", Imm(width), is_virtual=true, fresh=true),
  )
}

///|
/// Memory load of `size` from `mem` at `addr`.
pub fn RtlExp::load(
  mem : @types.Var,
  addr : RtlExp,
  endian : @bitvec.Endian,
  size : @types.Size,
) -> RtlExp {
  { sign: Unsigned, width: size.in_bits(), body: Load(mem, addr.body, endian, size) }
}

///|
/// Change the width and signedness of `self`, inserting a BIL cast when the
/// width changes.
pub fn RtlExp::cast(self : RtlExp, width : Int, sign : Sign) -> RtlExp {
  match (self.sign == sign, self.width == width) {
    (true, true) => self
    (false, true) => { ..self, sign, }
    _ =>
      if self.width == 1 {
        { width, sign, body: Cast(self.sign, width, self.body) }
      } else {
        { width, sign, body: Cast(sign, width, self.body) }
      }
  }
}

///|
pub fn RtlExp::signed(self : RtlExp) -> RtlExp {
  { ..self, sign: Signed }
}

///|
pub fn RtlExp::unsigned(self : RtlExp) -> RtlExp {
  { ..self, sign: Unsigned }
}

///|
pub fn RtlExp::with_sign(self : RtlExp, sign : Sign) -> RtlExp {
  { ..self, sign, }
}

///|
pub fn RtlExp::width(self : RtlExp) -> Int {
  self.width
}

///|
pub fn RtlExp::sign(self : RtlExp) -> Sign {
  self.sign
}

///|
pub fn RtlExp::body(self : RtlExp) -> RtlBody {
  self.body
}

///|
fn derive_sign(s1 : Sign, s2 : Sign) -> Sign {
  match (s1, s2) {
    (Signed, _) | (_, Signed) => Signed
    _ => Unsigned
  }
}

///|
fn binop_with_signedness(
  sign : Sign,
  op : @types.BinOp,
  lhs : RtlExp,
  rhs : RtlExp,
) -> RtlExp {
  let width = Int::max(lhs.width, rhs.width)
  let lhs = lhs.cast(width, sign)
  let rhs = rhs.cast(width, sign)
  { sign, width, body: Binop(op, lhs.body, rhs.body) }
}

///|
fn binop_with_cast(op : @types.BinOp, lhs : RtlExp, rhs : RtlExp) -> RtlExp {
  binop_with_signedness(derive_sign(lhs.sign, rhs.sign), op, lhs, rhs)
}

///|
fn logop_with_cast(op : @types.BinOp, lhs : RtlExp, rhs : RtlExp) -> RtlExp {
  { ..binop_with_cast(op, lhs, rhs), width: 1 }
}

///|
fn derive_op(
  x : RtlExp,
  y : RtlExp,
  op_u : @types.BinOp,
  op_s : @types.BinOp,
) -> @types.BinOp {
  match derive_sign(x.sign, y.sign) {
    Signed => op_s
    Unsigned => op_u
  }
}

///|
pub extend RtlExp with Add::{add}

///|
pub impl Add for RtlExp with add(x, y) {
  binop_with_cast(Plus, x, y)
}

///|
pub extend RtlExp with Sub::{sub}

///|
pub impl Sub for RtlExp with sub(x, y) {
  binop_with_cast(Minus, x, y)
}

///|
pub extend RtlExp with Mul::{mul}

///|
pub impl Mul for RtlExp with mul(x, y) {
  binop_with_cast(Times, x, y)
}

///|
/// Division, signed if either operand is signed.
pub extend RtlExp with Div::{div}

///|
pub impl Div for RtlExp with div(x, y) {
  binop_with_cast(derive_op(x, y, Div, SignedDiv), x, y)
}

///|
/// Remainder, signed if either operand is signed.
pub extend RtlExp with Mod::{mod}

///|
pub impl Mod for RtlExp with mod(x, y) {
  binop_with_cast(derive_op(x, y, Mod, SignedMod), x, y)
}

///|
/// Bitwise and (always unsigned).
pub extend RtlExp with BitAnd::{land}

///|
pub impl BitAnd for RtlExp with land(x, y) {
  binop_with_signedness(Unsigned, And, x, y)
}

///|
/// Bitwise or (always unsigned).
pub extend RtlExp with BitOr::{lor}

///|
pub impl BitOr for RtlExp with lor(x, y) {
  binop_with_signedness(Unsigned, Or, x, y)
}

///|
/// Bitwise xor (always unsigned).
pub extend RtlExp with BitXOr::{lxor}

///|
pub impl BitXOr for RtlExp with lxor(x, y) {
  binop_with_signedness(Unsigned, Xor, x, y)
}

///|
/// Bitwise complement.
pub fn RtlExp::lnot(self : RtlExp) -> RtlExp {
  { ..self, body: Unop(Not, self.body) }
}

///|
/// Shift left.
pub fn RtlExp::shl(self : RtlExp, amount : RtlExp) -> RtlExp {
  binop_with_cast(LShift, self, amount)
}

///|
/// Shift right: arithmetic if `self` is signed, logical otherwise.
pub fn RtlExp::shr(self : RtlExp, amount : RtlExp) -> RtlExp {
  let op : @types.BinOp = if self.sign == Signed { ARShift } else { RShift }
  binop_with_cast(op, self, amount)
}

///|
/// `self < other` (a one-bit expression).
pub fn RtlExp::lt(self : RtlExp, other : RtlExp) -> RtlExp {
  logop_with_cast(derive_op(self, other, Lt, SignedLt), self, other)
}

///|
/// `self > other` (a one-bit expression).
pub fn RtlExp::gt(self : RtlExp, other : RtlExp) -> RtlExp {
  logop_with_cast(derive_op(self, other, Lt, SignedLt), other, self)
}

///|
/// `self <= other` (a one-bit expression).
pub fn RtlExp::le(self : RtlExp, other : RtlExp) -> RtlExp {
  logop_with_cast(derive_op(self, other, Le, SignedLe), self, other)
}

///|
/// `self >= other` (a one-bit expression).
pub fn RtlExp::ge(self : RtlExp, other : RtlExp) -> RtlExp {
  logop_with_cast(derive_op(self, other, Le, SignedLe), other, self)
}

///|
/// `self = other` (a one-bit expression).
pub fn RtlExp::eq(self : RtlExp, other : RtlExp) -> RtlExp {
  logop_with_cast(Eq, self, other)
}

///|
/// `self <> other` (a one-bit expression).
pub fn RtlExp::neq(self : RtlExp, other : RtlExp) -> RtlExp {
  logop_with_cast(Neq, self, other)
}

///|
/// Concatenation `self ^ low` (always unsigned).
pub fn RtlExp::concat(self : RtlExp, low : RtlExp) -> RtlExp {
  {
    sign: Unsigned,
    width: self.width + low.width,
    body: Concat(self.body, low.body),
  }
}

///|
fn extract_of_vars(
  e : RtlExp,
  hi : Int,
  lo : Int,
  vars : ArrayView[@types.Var],
) -> RtlExp {
  let width = hi - lo + 1
  let bounds : Array[(Int, Int, @types.Var)] = []
  let mut n = 0
  for v in vars {
    let len = var_bitwidth(v)
    bounds.push((e.width - n - 1, e.width - n - len, v))
    n += len
  }
  let has_hi = bounds.iter().any(b => b.0 == hi)
  let has_lo = bounds.iter().any(b => b.1 == lo)
  if has_hi && has_lo {
    let selected : Array[@types.Var] = []
    for b in bounds {
      if b.0 <= hi && b.1 >= lo {
        selected.push(b.2)
      }
    }
    match selected {
      [v, .. rest] => { sign: Unsigned, width, body: Vars(v, rest.to_owned()) }
      [] => { sign: Unsigned, width, body: Extract(hi, lo, e.body) }
    }
  } else {
    { sign: Unsigned, width, body: Extract(hi, lo, e.body) }
  }
}

///|
/// Extract bits `hi..lo` (least significant bit is 0). The result is always
/// unsigned. Extracting from a concatenation of variables at variable
/// boundaries yields the variables themselves, so the result stays
/// assignable.
pub fn RtlExp::extract(self : RtlExp, hi : Int, lo : Int) -> RtlExp {
  let width = hi - lo + 1
  if width == self.width {
    { ..self, sign: Unsigned }
  } else {
    match self.body {
      Vars(v, vars) if vars.length() > 0 =>
        extract_of_vars(self, hi, lo, [v, ..vars])
      _ => { sign: Unsigned, width, body: Extract(hi, lo, self.body) }
    }
  }
}

///|
/// Assignment `lhs := rhs`.
pub fn RtlExp::set(self : RtlExp, rhs : RtlExp) -> Rtl {
  Move(self, rhs)
}

///|
/// `store(mem, addr, data, endian, size)`
pub fn store(
  mem : @types.Var,
  addr : RtlExp,
  data : RtlExp,
  endian : @bitvec.Endian,
  size : @types.Size,
) -> Rtl {
  Store(mem, addr, data, endian, size)
}

///|
pub fn if_(cond : RtlExp, then_ : Array[Rtl], else_ : Array[Rtl]) -> Rtl {
  If(cond, then_, else_)
}

///|
pub fn jmp(addr : RtlExp) -> Rtl {
  Jmp(addr)
}

///|
/// `foreach(step, e, code)` repeats `code` for each `step`-sized chunk of
/// `e`, starting from the most significant chunk (as the `RTL.foreach` of
/// upstream `Powerpc.Std`). Assignments to `step` inside `code` are written
/// back to the corresponding chunk of `e`.
pub fn foreach(step : RtlExp, e : RtlExp, code : Array[Rtl]) -> Rtl {
  Foreach(true, step, e, code)
}

///|
/// Like `foreach`, but `inverse=false` starts from the least significant
/// chunk.
pub fn foreach_from(
  inverse~ : Bool,
  step : RtlExp,
  e : RtlExp,
  code : Array[Rtl],
) -> Rtl {
  Foreach(inverse, step, e, code)
}

///|
pub fn message(m : String) -> Rtl {
  Message(m)
}
