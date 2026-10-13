// Port of `plugins/thumb/thumb_core.ml`.
//
// Upstream builds denotations in the tagless-final `Theory.Core`; this port
// emits BIL directly. The mapping follows `plugins/bil/bil_semantics.ml`:
// `set` -> `Move`, `blk data ctrl` -> data statements followed by control
// statements, `branch` -> `If`, `goto <addr>` -> `Jmp (Int addr)`,
// `goto <named label>` -> `special` encoded with the `call` attribute,
// `jmp e` -> `Jmp e`, `loadw b0`/`storew b0` -> little-endian load/store.
// Booleans are 1-bit words in BIL, so the Core Theory `bit`/`bool`
// coercions (`ite v 1 0`, `1 = flag`) collapse to the operand itself.

///|
fn reg32(name : String) -> @types.Var {
  @types.Var::new(name~, typ=Imm(32))
}

///|
fn flag(name : String) -> @types.Var {
  @types.Var::new(name~, typ=Imm(1))
}

///|
/// Memory variable `mem : Mem[32, 8]`.
let mem : @types.Var = @types.Var::new(
  name="mem",
  typ=Mem(addr_width=32, value_width=8),
)

///|
let sp : @types.Var = reg32("SP")

///|
let lr : @types.Var = reg32("LR")

///|
let nf : @types.Var = flag("NF")

///|
let zf : @types.Var = flag("ZF")

///|
let cf : @types.Var = flag("CF")

///|
let vf : @types.Var = flag("VF")

///|
/// Stand-in for upstream `Theory.Var.fresh s32`: a virtual 32-bit
/// temporary local to one instruction's semantics.
fn fresh32() -> @types.Var {
  @types.Var::new(name="t", typ=Imm(32), is_virtual=true)
}

///|
fn word32(value : Int32) -> @types.Word {
  try! @types.Word::of_uint64(width=32, value.reinterpret_as_uint().to_uint64())
}

///|
/// `const x` / `bitv (W32.int x)`: a 32-bit constant, wrapping modulo 2^32.
fn const_(value : Int32) -> @types.Exp {
  Int(word32(value))
}

///|
let bit0 : @types.Exp = Int(@types.Word::b0())

///|
let bit1 : @types.Exp = Int(@types.Word::b1())

///|
fn bool_const(value : Bool) -> @types.Exp {
  if value {
    bit1
  } else {
    bit0
  }
}

///|
fn v(x : @types.Var) -> @types.Exp {
  Var(x)
}

///|
fn binop(op : @types.BinOp, x : @types.Exp, y : @types.Exp) -> @types.Exp {
  BinOp(op, x, y)
}

///|
fn add(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  binop(Plus, x, y)
}

///|
fn sub(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  binop(Minus, x, y)
}

///|
fn logand(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  binop(And, x, y)
}

///|
fn logor(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  binop(Or, x, y)
}

///|
fn logxor(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  binop(Xor, x, y)
}

///|
fn eq(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  binop(Eq, x, y)
}

///|
fn neq(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  binop(Neq, x, y)
}

///|
/// Unsigned less-than (`CT.ult`).
fn ult(x : @types.Exp, y : @types.Exp) -> @types.Exp {
  binop(Lt, x, y)
}

///|
/// Bitwise / boolean complement (`CT.not` and `CT.inv`).
fn lnot(x : @types.Exp) -> @types.Exp {
  UnOp(Not, x)
}

///|
fn ite(c : @types.Exp, yes : @types.Exp, no : @types.Exp) -> @types.Exp {
  Ite(cond=c, yes~, no~)
}

///|
/// `nth n x`: bit `n` of `x` as a 1-bit value.
fn nth(n : Int32, x : @types.Exp) -> @types.Exp {
  Extract(hi=n, lo=n, exp=x)
}

///|
fn msb(x : @types.Exp) -> @types.Exp {
  nth(31, x)
}

///|
/// `is_zero x` as a 1-bit value (`bit (CT.is_zero x)`).
fn is_zero(x : @types.Exp) -> @types.Exp {
  eq(x, const_(0))
}

///|
fn signed32(x : @types.Exp) -> @types.Exp {
  Cast(kind=Signed, width=32, exp=x)
}

///|
fn unsigned32(x : @types.Exp) -> @types.Exp {
  Cast(kind=Unsigned, width=32, exp=x)
}

///|
fn low(width : Int32, x : @types.Exp) -> @types.Exp {
  Cast(kind=Low, width~, exp=x)
}

///|
/// `load s p`: little-endian load of `size` from `mem`.
fn load(size : @types.Size, addr : @types.Exp) -> @types.Exp {
  @types.Exp::load(mem=v(mem), addr~, @bitvec.LittleEndian, size)
}

///|
/// `storew b0 mem p x` as a memory expression; the width comes from `x`.
fn store_exp(addr : @types.Exp, value : @types.Exp) -> @types.Exp {
  Store(mem=v(mem), addr~, value~, endian=@bitvec.LittleEndian)
}

///|
/// `p <-- x`: unconditional store.
fn store(addr : @types.Exp, value : @types.Exp) -> @types.Stmt {
  Move(mem, store_exp(addr, value))
}

///|
fn set(dst : @types.Var, exp : @types.Exp) -> @types.Stmt {
  Move(dst, exp)
}

///|
/// `r += x`
fn set_add(r : @types.Var, x : @types.Exp) -> @types.Stmt {
  set(r, add(v(r), x))
}

///|
/// `r -= x`
fn set_sub(r : @types.Var, x : @types.Exp) -> @types.Stmt {
  set(r, sub(v(r), x))
}

///|
/// `~?cond`: the predicate that holds when `cond` is satisfied.
fn holds(cond : Cond) -> @types.Exp {
  let is_set = (x : @types.Var) => v(x)
  let is_clear = (x : @types.Var) => lnot(v(x))
  match cond {
    EQ => is_set(zf)
    NE => is_clear(zf)
    CS => is_set(cf)
    CC => is_clear(cf)
    MI => is_set(nf)
    PL => is_clear(nf)
    VS => is_set(vf)
    VC => is_clear(vf)
    HI => logand(is_set(cf), is_clear(zf))
    LS => logor(is_clear(cf), is_set(zf))
    GE => eq(v(nf), v(vf))
    LT => neq(v(nf), v(vf))
    GT => logand(is_clear(zf), eq(v(nf), v(vf)))
    LE => logor(is_set(zf), neq(v(nf), v(vf)))
    AL => bit1
  }
}

///|
/// `(dst <-? exp) cnd`: conditional register assignment.
fn set_if(dst : @types.Var, exp : @types.Exp, cnd : Cond) -> Array[@types.Stmt] {
  match cnd {
    AL => [set(dst, exp)]
    _ => [set(dst, ite(holds(cnd), exp, v(dst)))]
  }
}

///|
/// `(dst <--? src) cnd`: conditional store.
fn store_if(
  addr : @types.Exp,
  value : @types.Exp,
  cnd : Cond,
) -> Array[@types.Stmt] {
  match cnd {
    AL => [store(addr, value)]
    _ => [set(mem, ite(holds(cnd), store_exp(addr, value), v(mem)))]
  }
}

///|
/// `it_set dst exp rest cnd`: outside an IT block (`AL`) the result is
/// computed into a fresh temporary, the flag updates from `rest` run, and
/// only then is `dst` written; under a condition only `dst` is updated
/// (conditional Thumb instructions do not set flags).
fn it_set(
  dst : @types.Var,
  exp : @types.Exp,
  rest : (@types.Var) -> Array[@types.Stmt],
  cnd : Cond,
) -> Array[@types.Stmt] {
  match cnd {
    AL => {
      let tmp = fresh32()
      [set(tmp, exp), ..rest(tmp), set(dst, v(tmp))]
    }
    _ => [set(dst, ite(holds(cnd), exp, v(dst)))]
  }
}

///|
/// `branch cnd t f`
fn branch(
  cnd : Cond,
  yes : Array[@types.Stmt],
  no : Array[@types.Stmt],
) -> Array[@types.Stmt] {
  match cnd {
    AL => yes
    _ => [If(cond=holds(cnd), yes~, no~)]
  }
}

///|
/// `goto addr` for a code address.
fn goto(addr : Int32) -> @types.Stmt {
  Jmp(const_(addr))
}

///|
/// `pc +> off`: Thumb pc-relative target, `pc + off + 4` modulo 2^32.
fn pc_offset(pc : Int32, off : Int32) -> Int32 {
  pc + off + 4
}
