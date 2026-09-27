// Small BIL construction helpers shared by the legacy and the per-opcode
// lifters (upstream uses the `Bil` infix operators of `Bap.Std`).

///|
/// Counter of virtual temporaries; reset at the start of every lifted
/// instruction so that the produced BIL is deterministic (temporaries never
/// live across instructions).
let tmp_counter : Ref[Int] = Ref(0)

///|
fn reset_tmps() -> Unit {
  tmp_counter.val = 0
}

///|
/// A fresh virtual temporary (upstream `Var.create ~fresh:true
/// ~is_virtual:true name`).
fn new_tmp(width : Int, name? : String = "v") -> @types.Var {
  tmp_counter.val += 1
  @types.Var::new(
    name="\{name}_\{tmp_counter.val}",
    typ=Imm(width),
    is_virtual=true,
  )
}

///|
fn mask64(width : Int) -> UInt64 {
  if width >= 64 {
    0xFFFFFFFFFFFFFFFFUL
  } else {
    (1UL << width) - 1UL
  }
}

///|
/// A `width`-bit word with the (two's complement) value `value`,
/// sign-extended when `width` exceeds 64 bits.
fn word_of_int64(value : Int64, width : Int) -> @types.Word {
  let bits = value.reinterpret_as_uint64() & mask64(width)
  if width > 64 && value < 0L {
    let low = try! @bitvec.of_uint64(width~, bits)
    let high = (try! @bitvec.ones(width~)).lshift(64)
    @types.Word::from_bitvec(try! high.bit_or(low))
  } else {
    try! @types.Word::of_uint64(width~, bits)
  }
}

///|
/// A `width`-bit word with the unsigned value `bits` (truncated).
fn word_of_uint64(bits : UInt64, width : Int) -> @types.Word {
  try! @types.Word::of_uint64(width~, bits & mask64(width))
}

///|
/// Upstream `int_exp n width` (`BV.of_int n ~width`): negative values wrap.
fn int_exp(n : Int, width : Int) -> @types.Exp {
  Int(word_of_int64(n.to_int64(), width))
}

///|
fn int64_exp(n : Int64, width : Int) -> @types.Exp {
  Int(word_of_int64(n, width))
}

///|
fn uint64_exp(n : UInt64, width : Int) -> @types.Exp {
  Int(word_of_uint64(n, width))
}

///|
let exp_false : @types.Exp = int_exp(0, 1)

///|
let exp_true : @types.Exp = int_exp(1, 1)

///|
fn ev(v : @types.Var) -> @types.Exp {
  Var(v)
}

///|
fn bop(op : @types.BinOp, x : @types.Exp, y : @types.Exp) -> @types.Exp {
  BinOp(op, x, y)
}

///|
fn e_plus(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  BinOp(Plus, x, y)
}

///|
fn e_minus(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  BinOp(Minus, x, y)
}

///|
fn e_times(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  BinOp(Times, x, y)
}

///|
fn e_and(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  BinOp(And, x, y)
}

///|
fn e_or(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  BinOp(Or, x, y)
}

///|
fn e_xor(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  BinOp(Xor, x, y)
}

///|
fn e_lsl(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  BinOp(LShift, x, y)
}

///|
fn e_lsr(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  BinOp(RShift, x, y)
}

///|
fn e_eq(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  BinOp(Eq, x, y)
}

///|
fn e_neq(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  BinOp(Neq, x, y)
}

///|
/// `x < y` (unsigned).
fn e_lt(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  BinOp(Lt, x, y)
}

///|
/// `x > y` (unsigned), i.e. `y < x` as in BAP's `Bil.(>)`.
fn e_gt(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  BinOp(Lt, y, x)
}

///|
fn e_slt(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  BinOp(SignedLt, x, y)
}

///|
fn e_not(x : @types.Exp) -> @types.Exp {
  UnOp(Not, x)
}

///|
fn e_neg(x : @types.Exp) -> @types.Exp {
  UnOp(Neg, x)
}

///|
fn e_low(width : Int, x : @types.Exp) -> @types.Exp {
  Cast(kind=Low, width~, exp=x)
}

///|
fn e_high(width : Int, x : @types.Exp) -> @types.Exp {
  Cast(kind=High, width~, exp=x)
}

///|
fn e_unsigned(width : Int, x : @types.Exp) -> @types.Exp {
  Cast(kind=Unsigned, width~, exp=x)
}

///|
fn e_signed(width : Int, x : @types.Exp) -> @types.Exp {
  Cast(kind=Signed, width~, exp=x)
}

///|
fn e_extract(hi : Int, lo : Int, x : @types.Exp) -> @types.Exp {
  Extract(hi~, lo~, exp=x)
}

///|
fn e_concat(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  Concat(high=x, low=y)
}

///|
fn e_ite(c : @types.Exp, x : @types.Exp, y : @types.Exp) -> @types.Exp {
  Ite(cond=c, yes=x, no=y)
}

///|
fn e_unknown(name : String, width : Int) -> @types.Exp {
  Unknown(name, Imm(width))
}

///|
fn e_load(
  mem : @types.Var,
  addr : @types.Exp,
  width : Int,
) -> @types.Exp raise X86Error {
  match @types.Size::of_int_opt(width) {
    Some(size) => @types.Exp::load(mem=Var(mem), addr~, LittleEndian, size)
    None => raise ArchException("invalid load size \{width}")
  }
}

///|
fn store_stmt(
  mem : @types.Var,
  addr : @types.Exp,
  width : Int,
  value : @types.Exp,
) -> @types.Stmt raise X86Error {
  match @types.Size::of_int_opt(width) {
    Some(size) =>
      Move(
        mem,
        @types.Exp::store(mem=Var(mem), addr~, value, LittleEndian, size),
      )
    None => raise ArchException("invalid store size \{width}")
  }
}

///|
fn assign(v : @types.Var, e : @types.Exp) -> @types.Stmt {
  Move(v, e)
}

///|
fn if_(
  c : @types.Exp,
  yes : Array[@types.Stmt],
  no : Array[@types.Stmt],
) -> @types.Stmt {
  If(cond=c, yes~, no~)
}

///|
/// Upstream `concat_explist`: `e1 ^ e2 ^ ...` (left associative).
fn concat_explist(exps : ArrayView[@types.Exp]) -> @types.Exp raise X86Error {
  guard exps is [first, .. rest] else {
    raise ArchException("concat of an empty list")
  }
  let mut acc = first
  for e in rest {
    acc = e_concat(acc, e)
  }
  acc
}

///|
/// Upstream `extract_element nbits e n`.
fn extract_element(nbits : Int, e : @types.Exp, n : Int) -> @types.Exp {
  e_extract(n * nbits + (nbits - 1), n * nbits, e)
}

///|
/// Upstream `reverse_bytes`: the bytes of `e` from the lowest to the
/// highest, concatenated (so that the lowest byte becomes the highest).
fn reverse_bytes(e : @types.Exp, width : Int) -> @types.Exp raise X86Error {
  let bytes = width / 8
  concat_explist([ for n in 0..<bytes => extract_element(8, e, n) ])
}

///|
/// Upstream `min_symbolic`.
fn min_symbolic(signed : Bool, x : @types.Exp, y : @types.Exp) -> @types.Exp {
  let cond = if signed { e_slt(x, y) } else { e_lt(x, y) }
  e_ite(cond, x, y)
}

///|
/// Upstream `max_symbolic`.
fn max_symbolic(signed : Bool, x : @types.Exp, y : @types.Exp) -> @types.Exp {
  let cond = if signed { e_slt(x, y) } else { e_lt(x, y) }
  e_ite(e_not(cond), x, y)
}

///|
fn intrinsic(name : String) -> @types.Stmt {
  @types.Stmt::encode(@types.Stmt::intrinsic(), name)
}

///|
fn special_call(name : String) -> @types.Stmt {
  @types.Stmt::encode(@types.Stmt::call(), name)
}
