///|
/// A Z3 term (a bitvector or a boolean formula).
///
/// Terms are hash-consed by Z3: two terms of the same context are equal
/// iff they are structurally equal, and they are ordered by their Z3
/// identifiers.
pub struct Expr {
  priv ctx : Context
  priv raw : RawAst
}

///|
/// The sort of a term.
pub(all) enum Sort {
  Bool
  BitVec(Int32)
  Other
} derive(Eq, Debug)

///|
/// Binary operators. The bitvector operators take bitvectors of the same
/// width (`Concat` excepted); the comparisons return booleans; `Eq` and
/// `Distinct` take terms of the same sort; the `Bool*`, `Implies` and
/// `Iff` operators take booleans.
pub(all) enum BinOp {
  Add
  Sub
  Mul
  Udiv
  Sdiv
  Urem
  Srem
  Smod
  And
  Or
  Xor
  Shl
  Lshr
  Ashr
  Concat
  Ult
  Ule
  Ugt
  Uge
  Slt
  Sle
  Sgt
  Sge
  Eq
  Distinct
  BoolAnd
  BoolOr
  BoolXor
  Implies
  Iff
} derive(Eq, Debug)

///|
fn BinOp::code(self : BinOp) -> Int32 {
  match self {
    Add => 0
    Sub => 1
    Mul => 2
    Udiv => 3
    Sdiv => 4
    Urem => 5
    Srem => 6
    Smod => 7
    And => 8
    Or => 9
    Xor => 10
    Shl => 11
    Lshr => 12
    Ashr => 13
    Concat => 14
    Ult => 15
    Ule => 16
    Ugt => 17
    Uge => 18
    Slt => 19
    Sle => 20
    Sgt => 21
    Sge => 22
    Eq => 23
    Distinct => 24
    BoolAnd => 25
    BoolOr => 26
    BoolXor => 27
    Implies => 28
    Iff => 29
  }
}

///|
/// Unary operators: bitwise complement, two's complement negation, the
/// reductions to a 1-bit vector, and the boolean negation.
pub(all) enum UnOp {
  Not
  Neg
  RedOr
  RedAnd
  BoolNot
} derive(Eq, Debug)

///|
fn UnOp::code(self : UnOp) -> Int32 {
  match self {
    Not => 0
    Neg => 1
    RedOr => 2
    RedAnd => 3
    BoolNot => 4
  }
}

///|
fn Context::wrap(self : Context, raw : RawAst) -> Expr raise Z3Error {
  self.check()
  if raw_ast_is_null(raw) {
    raise Failure("Z3 returned a null term")
  }
  { ctx: self, raw, }
}

///|
/// The boolean constant.
pub fn Context::bool(self : Context, b : Bool) -> Expr raise Z3Error {
  self.wrap(raw_bool_val(self.raw, b))
}

///|
/// A boolean variable.
pub fn Context::bool_const(self : Context, name : String) -> Expr raise Z3Error {
  self.wrap(raw_bool_const(self.raw, c_string(name)))
}

///|
/// A bitvector variable of the given width.
pub fn Context::bv_const(
  self : Context,
  name : String,
  width : Int32,
) -> Expr raise Z3Error {
  if width <= 0 {
    raise Failure("invalid bitvector width \{width}")
  }
  self.wrap(raw_bv_const(self.raw, c_string(name), width))
}

///|
/// A bitvector numeral of the given width from a decimal string (the
/// value is taken modulo `2^width`).
pub fn Context::bv_numeral(
  self : Context,
  decimal : String,
  width : Int32,
) -> Expr raise Z3Error {
  if width <= 0 {
    raise Failure("invalid bitvector width \{width}")
  }
  self.wrap(raw_bv_numeral(self.raw, c_string(decimal), width))
}

///|
/// A bitvector numeral of the given width.
pub fn Context::bv_int(
  self : Context,
  value : Int64,
  width : Int32,
) -> Expr raise Z3Error {
  let dec = if value >= 0L {
    value.to_string()
  } else {
    // two's complement modulo 2^width
    let m = @bigint.BigInt::from_int(1) << width
    (m + @bigint.BigInt::from_int64(value)).to_string()
  }
  self.bv_numeral(dec, width)
}

///|
/// The unsigned decimal representation of a word.
fn word_to_decimal(w : @types.Word) -> String {
  let hex = w.to_hex(prefix=false)
  if hex == "" {
    "0"
  } else {
    @bigint.BigInt::from_string(hex, radix=16).to_string()
  }
}

///|
/// The bitvector numeral of a word (of the same width).
pub fn Context::word(self : Context, w : @types.Word) -> Expr raise Z3Error {
  self.bv_numeral(word_to_decimal(w), w.bitwidth())
}

///|
/// Applies a binary operator.
pub fn Expr::binop(self : Expr, op : BinOp, other : Expr) -> Expr raise Z3Error {
  self.ctx.wrap(raw_binop(self.ctx.raw, op.code(), self.raw, other.raw))
}

///|
/// Applies a unary operator.
pub fn Expr::unop(self : Expr, op : UnOp) -> Expr raise Z3Error {
  self.ctx.wrap(raw_unop(self.ctx.raw, op.code(), self.raw))
}

///|
/// `bvadd`
pub fn Expr::add(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Add, other)
}

///|
/// `bvsub`
pub fn Expr::sub(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Sub, other)
}

///|
/// `bvmul`
pub fn Expr::mul(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Mul, other)
}

///|
/// `bvudiv`
pub fn Expr::udiv(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Udiv, other)
}

///|
/// `bvsdiv`
pub fn Expr::sdiv(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Sdiv, other)
}

///|
/// `bvurem`
pub fn Expr::urem(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Urem, other)
}

///|
/// `bvsrem`
pub fn Expr::srem(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Srem, other)
}

///|
/// `bvand`
pub fn Expr::logand(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(And, other)
}

///|
/// `bvor`
pub fn Expr::logor(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Or, other)
}

///|
/// `bvxor`
pub fn Expr::logxor(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Xor, other)
}

///|
/// `bvshl`
pub fn Expr::shl(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Shl, other)
}

///|
/// `bvlshr`
pub fn Expr::lshr(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Lshr, other)
}

///|
/// `bvashr`
pub fn Expr::ashr(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Ashr, other)
}

///|
/// `concat`: `self` provides the most significant bits.
pub fn Expr::concat(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Concat, other)
}

///|
/// `bvult`
pub fn Expr::ult(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Ult, other)
}

///|
/// `bvule`
pub fn Expr::ule(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Ule, other)
}

///|
/// `bvslt`
pub fn Expr::slt(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Slt, other)
}

///|
/// `bvsle`
pub fn Expr::sle(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Sle, other)
}

///|
/// The equality of two terms of the same sort.
pub fn Expr::eq(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Eq, other)
}

///|
/// The boolean conjunction.
pub fn Expr::and_(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(BoolAnd, other)
}

///|
/// The boolean disjunction.
pub fn Expr::or_(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(BoolOr, other)
}

///|
/// The boolean implication.
pub fn Expr::implies(self : Expr, other : Expr) -> Expr raise Z3Error {
  self.binop(Implies, other)
}

///|
/// The boolean negation.
pub fn Expr::not(self : Expr) -> Expr raise Z3Error {
  self.unop(BoolNot)
}

///|
/// `bvnot`
pub fn Expr::lnot(self : Expr) -> Expr raise Z3Error {
  self.unop(Not)
}

///|
/// `bvneg`
pub fn Expr::neg(self : Expr) -> Expr raise Z3Error {
  self.unop(Neg)
}

///|
/// `bvredor`: the 1-bit vector that is one iff some bit is set.
pub fn Expr::redor(self : Expr) -> Expr raise Z3Error {
  self.unop(RedOr)
}

///|
/// Simplifies the term (`Z3_simplify`).
pub fn Expr::simplify(self : Expr) -> Expr raise Z3Error {
  self.ctx.wrap(raw_unop(self.ctx.raw, 5, self.raw))
}

///|
/// The bits `hi..lo` (inclusive) of a bitvector.
pub fn Expr::extract(self : Expr, hi : Int32, lo : Int32) -> Expr raise Z3Error {
  if hi < lo || lo < 0 {
    raise Failure("invalid extraction [\{hi}:\{lo}]")
  }
  self.ctx.wrap(raw_extract(self.ctx.raw, hi, lo, self.raw))
}

///|
/// Extends a bitvector with `n` zero bits.
pub fn Expr::zero_ext(self : Expr, n : Int32) -> Expr raise Z3Error {
  self.ctx.wrap(raw_indexed(self.ctx.raw, 0, n, self.raw))
}

///|
/// Extends a bitvector with `n` copies of its sign bit.
pub fn Expr::sign_ext(self : Expr, n : Int32) -> Expr raise Z3Error {
  self.ctx.wrap(raw_indexed(self.ctx.raw, 1, n, self.raw))
}

///|
/// Rotates a bitvector to the left by `n` bits.
pub fn Expr::rotate_left(self : Expr, n : Int32) -> Expr raise Z3Error {
  self.ctx.wrap(raw_indexed(self.ctx.raw, 2, n, self.raw))
}

///|
/// Rotates a bitvector to the right by `n` bits.
pub fn Expr::rotate_right(self : Expr, n : Int32) -> Expr raise Z3Error {
  self.ctx.wrap(raw_indexed(self.ctx.raw, 3, n, self.raw))
}

///|
/// `if cnd then yes else no`, where `cnd` is a boolean.
pub fn Context::ite(
  self : Context,
  cnd : Expr,
  yes : Expr,
  no : Expr,
) -> Expr raise Z3Error {
  self.wrap(raw_ite(self.raw, cnd.raw, yes.raw, no.raw))
}

///|
/// The conjunction of the formulas (`true` if there are none).
pub fn Context::and_all(self : Context, xs : Array[Expr]) -> Expr raise Z3Error {
  match xs {
    [] => self.bool(true)
    [x, .. rest] => {
      let mut acc = x
      for y in rest {
        acc = acc.and_(y)
      }
      acc
    }
  }
}

///|
/// The disjunction of the formulas (`false` if there are none).
pub fn Context::or_all(self : Context, xs : Array[Expr]) -> Expr raise Z3Error {
  match xs {
    [] => self.bool(false)
    [x, .. rest] => {
      let mut acc = x
      for y in rest {
        acc = acc.or_(y)
      }
      acc
    }
  }
}

///|
/// The terms are pairwise distinct.
pub fn Context::distinct(
  self : Context,
  xs : Array[Expr],
) -> Expr raise Z3Error {
  let parts = []
  for i in 0..<xs.length() {
    for j in (i + 1)..<xs.length() {
      parts.push(xs[i].binop(Distinct, xs[j]))
    }
  }
  self.and_all(parts)
}

///|
/// The context of the term.
pub fn Expr::context(self : Expr) -> Context {
  self.ctx
}

///|
/// The sort of the term.
pub fn Expr::sort(self : Expr) -> Sort {
  match raw_sort_of(self.ctx.raw, self.raw) {
    0 => Bool
    n if n > 0 => BitVec(n)
    _ => Other
  }
}

///|
/// Whether the term is a boolean formula.
pub fn Expr::is_bool(self : Expr) -> Bool {
  self.sort() is Bool
}

///|
/// The width of a bitvector term (0 for other sorts).
pub fn Expr::bitwidth(self : Expr) -> Int32 {
  match self.sort() {
    BitVec(n) => n
    _ => 0
  }
}

///|
/// Whether the term is a numeral.
pub fn Expr::is_numeral(self : Expr) -> Bool {
  raw_is_numeral(self.ctx.raw, self.raw)
}

///|
/// The value of a boolean constant (`None` if it is not `true`/`false`).
pub fn Expr::bool_value(self : Expr) -> Bool? {
  match raw_bool_value(self.ctx.raw, self.raw) {
    1 => Some(true)
    -1 => Some(false)
    _ => None
  }
}

///|
/// The unsigned decimal value of a bitvector numeral.
pub fn Expr::numeral_string(self : Expr) -> String? {
  if !self.is_numeral() {
    return None
  }
  Some(bytes_to_string(raw_numeral_string(self.ctx.raw, self.raw)))
}

///|
/// The value of a bitvector numeral as a word of the same width.
pub fn Expr::to_word(self : Expr) -> @types.Word? {
  guard self.sort() is BitVec(width) else { return None }
  guard self.numeral_string() is Some(dec) else { return None }
  let hex = @bigint.BigInt::from_string(dec).to_string(radix=16)
  Some(@types.Word::from_hex(width~, hex)) catch {
    _ => None
  }
}

///|
/// The SMT-LIB rendering of the term.
pub fn Expr::to_string(self : Expr) -> String {
  bytes_to_string(raw_ast_to_string(self.ctx.raw, self.raw))
}

///|
pub impl Show for Expr with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// The Z3 identifier of the term (unique among the live terms of the
/// context).
pub fn Expr::id(self : Expr) -> Int32 {
  raw_ast_id(self.ctx.raw, self.raw)
}

///|
pub impl Eq for Expr with fn equal(self, other) {
  raw_ast_eq(self.ctx.raw, self.raw, other.raw)
}

///|
pub impl Compare for Expr with fn compare(self, other) {
  self.id().compare(other.id())
}

///|
pub impl Hash for Expr with fn hash_combine(self, hasher) {
  hasher.combine_int(raw_ast_hash(self.ctx.raw, self.raw))
}
