// Port of BAP `plugins/mips/mips_rtl.ml`: a small register-transfer
// language used by the MIPS instruction semantics. RTL expressions carry a
// width and a signedness so that operands are implicitly cast (sign- or
// zero-extended) the same way upstream does before being lowered to BIL.

///|
priv enum Sign {
  Signed
  Unsigned
} derive(Eq)

///|
/// Body of an RTL expression; mirrors upstream `Mips_rtl.body`.
priv enum Body {
  /// A variable, or a concatenation of variables (most significant first).
  Vars(@types.Var, Array[@types.Var])
  Word(@types.Word)
  Load(@types.Var, Body, @bitvec.Endian, @types.Size)
  Concat(Body, Body)
  Binop(@types.BinOp, Body, Body)
  Extract(Int, Int, Body)
  Cast(Sign, Int, Body)
  Unop(@types.UnOp, Body)
}

///|
/// A sized, signed RTL expression.
priv struct Exp {
  body : Body
  sign : Sign
  width : Int
}

///|
/// RTL statements; mirrors upstream `Mips_rtl.t`.
priv enum Rtl {
  Move(Exp, Exp)
  Jmp(Exp)
  Store(@types.Var, Exp, Exp, @bitvec.Endian, @types.Size)
  If(Exp, Array[Rtl], Array[Rtl])
  /// `Foreach(inverse, step, exp, code)` repeats `code` for each
  /// `step`-sized chunk of `exp`.
  Foreach(Bool, Exp, Exp, Array[Rtl])
}

///|
fn mips_fail(msg : String) -> @mc.LiftError {
  Failure("MIPS lifter fail: " + msg)
}

///|
fn var_bitwidth(v : @types.Var) -> Int raise @mc.LiftError {
  match v.typ {
    Imm(w) => w
    _ => raise mips_fail("variable \{v.name} doesn't has notion of bitwidth")
  }
}

///|
fn width_of_vars(vars : ArrayView[@types.Var]) -> Int raise @mc.LiftError {
  let mut width = 0
  for v in vars {
    width += var_bitwidth(v)
  }
  width
}

///|
fn var_of_exp(e : Exp) -> @types.Var raise @mc.LiftError {
  match e.body {
    Vars(v, _) => v
    _ => raise mips_fail("variable expected")
  }
}

///|
fn bil_exp(body : Body) -> @types.Exp {
  match body {
    Vars(v, vars) =>
      vars.fold(init=@types.Exp::var_exp(v), (e, v) => {
        @types.Exp::concat(e, @types.Exp::var_exp(v))
      })
    Word(w) => @types.Exp::int(w)
    Load(mem, addr, endian, size) =>
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=bil_exp(addr),
        endian,
        size,
      )
    Concat(x, y) => @types.Exp::concat(bil_exp(x), bil_exp(y))
    Binop(op, x, y) => @types.Exp::binop(op, bil_exp(x), bil_exp(y))
    Extract(hi, lo, x) => @types.Exp::extract(bil_exp(x), hi~, lo~)
    Cast(_, 1, x) => @types.Exp::cast(Low, 1, bil_exp(x))
    Cast(Signed, width, x) => @types.Exp::cast(Signed, width, bil_exp(x))
    Cast(Unsigned, width, x) => @types.Exp::cast(Unsigned, width, bil_exp(x))
    Unop(op, x) => @types.Exp::unop(op, bil_exp(x))
  }
}

///|
/// Change width and/or signedness of `x`. A signedness-only change does not
/// produce a BIL cast; 1-bit values are extended according to their own
/// signedness.
fn Exp::cast(x : Exp, width : Int, sign : Sign) -> Exp {
  let same_sign = x.sign == sign
  let same_size = x.width == width
  if same_size {
    if same_sign {
      x
    } else {
      { ..x, sign, }
    }
  } else if x.width == 1 {
    { width, sign, body: Cast(x.sign, width, x.body), }
  } else {
    { width, sign, body: Cast(sign, width, x.body), }
  }
}

///|
fn derive_sign(s : Sign, s2 : Sign) -> Sign {
  match (s, s2) {
    (Signed, _) | (_, Signed) => Signed
    _ => Unsigned
  }
}

///|
fn Exp::unop(x : Exp, op : @types.UnOp) -> Exp {
  { ..x, body: Unop(op, x.body), }
}

///|
fn binop_with_signedness(
  sign : Sign,
  op : @types.BinOp,
  lhs : Exp,
  rhs : Exp,
) -> Exp {
  let width = if lhs.width > rhs.width { lhs.width } else { rhs.width }
  let lhs = lhs.cast(width, sign)
  let rhs = rhs.cast(width, sign)
  { sign, width, body: Binop(op, lhs.body, rhs.body), }
}

///|
fn unsigned_binop(op : @types.BinOp, lhs : Exp, rhs : Exp) -> Exp {
  binop_with_signedness(Unsigned, op, lhs, rhs)
}

///|
fn binop_with_cast(op : @types.BinOp, lhs : Exp, rhs : Exp) -> Exp {
  binop_with_signedness(derive_sign(lhs.sign, rhs.sign), op, lhs, rhs)
}

///|
fn logop_with_cast(op : @types.BinOp, lhs : Exp, rhs : Exp) -> Exp {
  { ..binop_with_cast(op, lhs, rhs), width: 1, }
}

///|
fn Exp::concat(lhs : Exp, rhs : Exp) -> Exp {
  {
    sign: Unsigned,
    width: lhs.width + rhs.width,
    body: Concat(lhs.body, rhs.body),
  }
}

///|
impl Add for Exp with fn add(x, y) {
  binop_with_cast(Plus, x, y)
}

///|
impl Sub for Exp with fn sub(x, y) {
  binop_with_cast(Minus, x, y)
}

///|
impl Mul for Exp with fn mul(x, y) {
  binop_with_cast(Times, x, y)
}

///|
/// Upstream `/`: unsigned division (with operand casts).
impl Div for Exp with fn div(x, y) {
  binop_with_cast(Div, x, y)
}

///|
/// Upstream `%`: unsigned modulo (with operand casts).
impl Mod for Exp with fn mod(x, y) {
  binop_with_cast(Mod, x, y)
}

///|
/// Upstream `/$`.
fn Exp::sdiv(x : Exp, y : Exp) -> Exp {
  binop_with_cast(SignedDiv, x, y)
}

///|
/// Upstream `%$`.
fn Exp::smod(x : Exp, y : Exp) -> Exp {
  binop_with_cast(SignedMod, x, y)
}

///|
fn Exp::lt(x : Exp, y : Exp) -> Exp {
  logop_with_cast(Lt, x, y)
}

///|
fn Exp::eq(x : Exp, y : Exp) -> Exp {
  logop_with_cast(Eq, x, y)
}

///|
fn Exp::ge(x : Exp, y : Exp) -> Exp {
  logop_with_cast(Le, y, x)
}

///|
fn Exp::neq(x : Exp, y : Exp) -> Exp {
  logop_with_cast(Neq, x, y)
}

///|
fn Exp::slt(x : Exp, y : Exp) -> Exp {
  logop_with_cast(SignedLt, x.signed(), y.signed())
}

///|
/// Signed `x <= y` (not in upstream, whose comparisons other than `slt`
/// are unsigned).
fn Exp::sle(x : Exp, y : Exp) -> Exp {
  logop_with_cast(SignedLe, x.signed(), y.signed())
}

///|
/// Signed `x > y`.
fn Exp::sgt(x : Exp, y : Exp) -> Exp {
  Exp::slt(y, x)
}

///|
/// Signed `x >= y`.
fn Exp::sge(x : Exp, y : Exp) -> Exp {
  Exp::sle(y, x)
}

///|
/// Upstream `lsl`.
fn Exp::lsl(x : Exp, y : Exp) -> Exp {
  unsigned_binop(LShift, x, y)
}

///|
/// Upstream `lsr`.
fn Exp::lsr(x : Exp, y : Exp) -> Exp {
  unsigned_binop(RShift, x, y)
}

///|
/// Upstream `asr`.
fn Exp::asr(x : Exp, y : Exp) -> Exp {
  binop_with_cast(ARShift, x, y)
}

///|
/// Upstream `land`.
impl BitAnd for Exp with fn land(x, y) {
  unsigned_binop(And, x, y)
}

///|
/// Upstream `lor`.
impl BitOr for Exp with fn lor(x, y) {
  unsigned_binop(Or, x, y)
}

///|
/// Upstream `lxor` (upstream `^` is concatenation, see `Exp::concat`).
impl BitXOr for Exp with fn lxor(x, y) {
  unsigned_binop(Xor, x, y)
}

///|
/// Upstream `lnot`.
fn lnot(x : Exp) -> Exp {
  x.unop(Not)
}

///|
fn Exp::of_var(v : @types.Var) -> Exp raise @mc.LiftError {
  { sign: Unsigned, width: var_bitwidth(v), body: Vars(v, []), }
}

///|
fn Exp::of_word(w : @types.Word) -> Exp {
  { sign: Unsigned, width: w.bitwidth(), body: Word(w), }
}

///|
fn Exp::load(
  mem : @types.Var,
  addr : Exp,
  endian : @bitvec.Endian,
  size : @types.Size,
) -> Exp {
  {
    sign: Unsigned,
    width: size.in_bits(),
    body: Load(mem, addr.body, endian, size),
  }
}

///|
fn extract_of_vars(
  e : Exp,
  hi : Int,
  lo : Int,
  vars : Array[@types.Var],
) -> Exp raise @mc.LiftError {
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
    let selected = bounds.filter(b => b.0 <= hi && b.1 >= lo).map(b => b.2)
    guard selected is [v, .. rest] else {
      raise Failure("MIPS lifter fail: empty variable extraction")
    }
    { sign: Unsigned, width, body: Vars(v, rest.to_owned()), }
  } else {
    { sign: Unsigned, width, body: Extract(hi, lo, e.body), }
  }
}

///|
/// Extract bits `hi..lo` (inclusive, LSB is bit 0). Extracting the full
/// width returns `e` unchanged; extracting a var-aligned slice of a
/// concatenation of variables returns the covered variables.
fn Exp::extract(e : Exp, hi : Int, lo : Int) -> Exp raise @mc.LiftError {
  let width = hi - lo + 1
  if width == e.width {
    e
  } else {
    match e.body {
      Vars(v, vars) if !vars.is_empty() =>
        extract_of_vars(e, hi, lo, [v, ..vars])
      _ => { sign: Unsigned, width, body: Extract(hi, lo, e.body), }
    }
  }
}

///|
fn Exp::signed(e : Exp) -> Exp {
  { ..e, sign: Signed, }
}

///|
fn Exp::unsigned(e : Exp) -> Exp {
  { ..e, sign: Unsigned, }
}

///|
/// Upstream `:=`.
fn Exp::assign(lhs : Exp, rhs : Exp) -> Rtl {
  Move(lhs, rhs)
}

///|
fn jmp(addr : Exp) -> Rtl {
  Jmp(addr)
}

///|
fn if_(cond : Exp, then_ : Array[Rtl], else_ : Array[Rtl]) -> Rtl {
  If(cond, then_, else_)
}
