// Port of `Arm_utils`: operand assertions, temporaries, conditional
// execution, and small BIL construction helpers shared by the lifters.

///|
fn[T] fail(msg : String) -> T raise @mc.LiftError {
  raise Failure(msg)
}

///|
fn assert_reg(op : Op) -> Reg raise @mc.LiftError {
  match op {
    Reg(reg) => reg
    Imm(_) => fail("expected reg")
  }
}

///|
fn assert_imm(op : Op) -> UInt32 raise @mc.LiftError {
  match op {
    Imm(imm) => imm
    Reg(_) => fail("expected imm")
  }
}

///|
fn assert_cond(op : Op) -> Cond raise @mc.LiftError {
  let imm = assert_imm(op)
  match Cond::of_int(imm.reinterpret_as_int()) {
    Some(cond) => cond
    None => fail("bad argument (cond): not a condition: \{imm}")
  }
}

///|
/// Counter for virtual temporaries. It is reset at the start of every
/// lifted instruction so that the produced BIL is deterministic; temporaries
/// are virtual and never live across instructions.
let tmp_counter : Ref[Int32] = Ref(0)

///|
fn tmp(typ : @types.ValueType, name~ : String = "v") -> @types.Var {
  tmp_counter.val += 1
  @types.Var::new(name="\{name}\{tmp_counter.val}", typ~, is_virtual=true)
}

///|
fn word(width : Int32, value : UInt64) -> @types.Word {
  try! @types.Word::of_uint64(width~, value)
}

///|
fn imm_word(value : UInt32) -> @types.Word {
  word(32, value.to_uint64())
}

///|
fn int32(value : UInt32) -> @types.Exp {
  Int(imm_word(value))
}

///|
fn int_bits(width : Int32, value : UInt64) -> @types.Exp {
  Int(word(width, value))
}

///|
fn bool_exp(value : Bool) -> @types.Exp {
  Int(@types.Word::of_bool(value))
}

///|
fn v(x : @types.Var) -> @types.Exp {
  Var(x)
}

///|
fn assign(x : @types.Var, exp : @types.Exp) -> @types.Stmt {
  Move(x, exp)
}

///|
fn bin(op : @types.BinOp, x : @types.Exp, y : @types.Exp) -> @types.Exp {
  BinOp(op, x, y)
}

///|
fn lnot(x : @types.Exp) -> @types.Exp {
  UnOp(Not, x)
}

///|
fn cast(kind : @types.CastKind, width : Int32, x : @types.Exp) -> @types.Exp {
  Cast(kind~, width~, exp=x)
}

///|
fn extract(hi : Int32, lo : Int32, x : @types.Exp) -> @types.Exp {
  Extract(hi~, lo~, exp=x)
}

///|
fn concat(high : @types.Exp, low : @types.Exp) -> @types.Exp {
  Concat(high~, low~)
}

///|
fn load(mem : @types.Exp, addr : @types.Exp, size : @types.Size) -> @types.Exp {
  @types.Exp::load(mem~, addr~, LittleEndian, size)
}

///|
fn store(
  mem : @types.Exp,
  addr : @types.Exp,
  value : @types.Exp,
  size : @types.Size,
) -> @types.Exp {
  @types.Exp::store(mem~, addr~, value, LittleEndian, size)
}

///|
/// `Arm_utils.assn`: assignments to `PC` are jumps.
fn assn(dst : @types.Var, src : @types.Exp) -> @types.Stmt {
  if dst == pc {
    Jmp(src)
  } else {
    Move(dst, src)
  }
}

///|
fn bitlen(typ : @types.ValueType) -> Int32 {
  match typ {
    Imm(len) => len
    Mem(value_width~, ..) => value_width
  }
}

///|
fn exp_of_reg(reg : Reg) -> @types.Exp {
  Var(reg.to_var())
}

///|
fn exp_of_op(op : Op) -> @types.Exp {
  match op {
    Reg(reg) => exp_of_reg(reg)
    Imm(imm) => int32(imm)
  }
}

///|
fn cast_of_sign(sign : Sign, width : Int32, exp : @types.Exp) -> @types.Exp {
  match sign {
    Signed => cast(Signed, width, exp)
    Unsigned => cast(Unsigned, width, exp)
  }
}

///|
/// The most significant bit.
fn msb(r : @types.Exp) -> @types.Exp {
  cast(High, 1, r)
}

///|
fn zero(typ : @types.ValueType) -> @types.Exp {
  int_bits(bitlen(typ), 0)
}

///|
/// The BIL expression that holds when the condition is satisfied.
fn cond_exp(cond : Cond) -> @types.Exp {
  let z = v(zf)
  let c = v(cf)
  let vv = v(vf)
  let n = v(nf)
  let f = bool_exp(false)
  let t = bool_exp(true)
  match cond {
    EQ => bin(Eq, z, t)
    NE => bin(Eq, z, f)
    CS => bin(Eq, c, t)
    CC => bin(Eq, c, f)
    MI => bin(Eq, n, t)
    PL => bin(Eq, n, f)
    VS => bin(Eq, vv, t)
    VC => bin(Eq, vv, f)
    HI => bin(And, bin(Eq, c, t), bin(Eq, z, f))
    LS => bin(Or, bin(Eq, c, f), bin(Eq, z, t))
    GE => bin(Eq, n, vv)
    LT => bin(Neq, n, vv)
    GT => bin(And, bin(Eq, z, f), bin(Eq, n, vv))
    LE => bin(Or, bin(Eq, z, t), bin(Neq, n, vv))
    AL => t
  }
}

///|
/// `Arm_utils.exec`: execute `stmts` under the condition operand `cond`,
/// appending `flags` when `wflag` is the `CPSR` register.
///
/// Unconditional code is returned as is. Conditional code consisting only
/// of moves is predicated with `ite` expressions, other code is wrapped
/// into an `if` statement.
fn exec(
  stmts : Array[@types.Stmt],
  cond : Op,
  flags? : Array[@types.Stmt],
  wflag? : Op,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let cond = assert_cond(cond)
  let stmts = match (flags, wflag) {
    (Some(f), Some(Reg(CPSR))) => [..stmts, ..f]
    _ => stmts
  }
  match cond {
    AL => stmts
    _ if stmts.iter().all(s => s is Move(_, _)) => {
      let cvar = tmp(@types.ValueType::bool_t())
      let c = v(cvar)
      let result = [assign(cvar, cond_exp(cond))]
      for s in stmts {
        match s {
          Move(x, _) if x.is_virtual() => result.push(s)
          Move(dst, x) =>
            result.push(assign(dst, Ite(cond=c, yes=x, no=v(dst))))
          _ => panic()
        }
      }
      result
    }
    _ => [If(cond=cond_exp(cond), yes=stmts, no=[])]
  }
}
