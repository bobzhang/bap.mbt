///|
fn bil_uncat(exp : @types.Exp) -> Array[@types.Exp] {
  let parts = []
  fn go(exp : @types.Exp) -> Unit {
    match exp {
      Concat(high~, low~) => {
        go(high)
        go(low)
      }
      _ => parts.push(exp)
    }
  }

  go(exp)
  parts
}

///|
fn bil_is_big(endian : @bitvec.Endian) -> @types.Exp {
  match endian {
    BigEndian => Int(@types.Word::b1())
    LittleEndian => Int(@types.Word::b0())
  }
}

///|
fn bil_byte(n : Int) -> @types.Exp {
  Int(@types.Word::from_bitvec(bitvec_of_int(8, n) catch { _ => @bitvec.b0() }))
}

///|
fn bil_is_bit(v : @types.Var) -> Bool {
  v.typ() is Imm(1)
}

///|
fn bil_is_mem(v : @types.Var) -> Bool {
  v.typ() is Mem(_)
}

///|
fn bil_parse_bitv(
  g : BitvGrammar[@types.Exp, @types.Exp],
  exp : @types.Exp,
) -> Pure {
  match exp {
    Cast(kind=High, width~, exp~) => (g.high)(width, exp)
    Cast(kind=Low, width~, exp~) => (g.low)(width, exp)
    Cast(kind=Unsigned, width~, exp~) => (g.unsigned)(width, exp)
    Cast(kind=Signed, width~, exp~) => (g.signed)(width, exp)
    BinOp(Plus, x, y) => (g.add)(x, y)
    BinOp(Minus, x, y) => (g.sub)(x, y)
    BinOp(Times, x, y) => (g.mul)(x, y)
    BinOp(Div, x, y) => (g.div)(x, y)
    BinOp(SignedDiv, x, y) => (g.sdiv)(x, y)
    BinOp(Mod, x, y) => (g.modulo)(x, y)
    BinOp(SignedMod, x, y) => (g.smodulo)(x, y)
    BinOp(LShift, x, y) => (g.lshift)(x, y)
    BinOp(RShift, x, y) => (g.rshift)(x, y)
    BinOp(ARShift, x, y) => (g.arshift)(x, y)
    BinOp(And, x, y) => (g.logand)(x, y)
    BinOp(Or, x, y) => (g.logor)(x, y)
    BinOp(Xor, x, y) => (g.logxor)(x, y)
    BinOp(Eq | Neq | Lt | Le | SignedLt | SignedLe, _, _) =>
      (g.ite)(exp, Int(@types.Word::b1()), Int(@types.Word::b0()))
    UnOp(Neg, x) => (g.neg)(x)
    UnOp(Not, x) => (g.not)(x)
    Load(mem~, addr~, endian~, typ=Imm(size)) =>
      (g.load_word)(size, bil_is_big(endian), mem, addr)
    Var(v) =>
      match v.typ() {
        Imm(size) => (g.var_)(v.name(), size)
        _ => g.error
      }
    Int(x) => (g.int)(x.to_bitvec(), x.bitwidth())
    Let(v, y, z) if bil_is_bit(v) => (g.let_bit)(v.name(), y, z)
    Let(v, y, z) if bil_is_mem(v) => (g.let_mem)(v.name(), y, z)
    Let(v, y, z) => (g.let_reg)(v.name(), y, z)
    Ite(cond~, yes~, no~) => (g.ite)(cond, yes, no)
    Extract(hi~, lo~, exp~) => {
      let size = if hi - lo + 1 < 0 { 0 } else { hi - lo + 1 }
      (g.extract)(size, bil_byte(hi), bil_byte(lo), exp)
    }
    Concat(_) => (g.concat)(bil_uncat(exp))
    Unknown(_, Imm(size)) => (g.unknown)(size)
    Load(_) | Store(_) | Unknown(_, Mem(_)) => g.error
  }
}

///|
fn bil_parse_mem(g : MemGrammar[@types.Exp], exp : @types.Exp) -> Pure {
  match exp {
    Unknown(_, Mem(addr_width~, value_width~)) =>
      (g.unknown)(addr_width, value_width)
    Store(mem~, addr~, value~, endian~) =>
      (g.store_word)(bil_is_big(endian), mem, addr, value)
    Var(v) =>
      match v.typ() {
        Mem(addr_width~, value_width~) =>
          (g.var_)(v.name(), addr_width, value_width)
        _ => g.error
      }
    Let(v, y, z) if bil_is_bit(v) => (g.let_bit)(v.name(), y, z)
    Let(v, y, z) if bil_is_mem(v) => (g.let_mem)(v.name(), y, z)
    Let(v, y, z) => (g.let_reg)(v.name(), y, z)
    Ite(cond~, yes~, no~) => (g.ite)(cond, yes, no)
    _ => g.error
  }
}

///|
fn bil_parse_bool(g : BoolGrammar[@types.Exp], exp : @types.Exp) -> Pure {
  match exp {
    Var(x) => (g.var_)(x.name())
    Int(x) => (g.int)(x.to_bitvec())
    Cast(kind=High, width=1, exp~) => (g.high)(exp)
    Cast(kind=Low, width=1, exp~) => (g.low)(exp)
    BinOp(Eq, x, y) => (g.eq)(x, y)
    BinOp(Neq, x, y) => (g.neq)(x, y)
    BinOp(Lt, x, y) => (g.lt)(x, y)
    BinOp(Le, x, y) => (g.le)(x, y)
    BinOp(SignedLt, x, y) => (g.slt)(x, y)
    BinOp(SignedLe, x, y) => (g.sle)(x, y)
    BinOp(Or, x, y) => (g.logor)(x, y)
    BinOp(And, x, y) => (g.logand)(x, y)
    BinOp(Xor, x, y) => (g.logxor)(x, y)
    UnOp(Not, x) => (g.not)(x)
    Let(v, y, z) if bil_is_bit(v) => (g.let_bit)(v.name(), y, z)
    Let(v, y, z) if bil_is_mem(v) => (g.let_mem)(v.name(), y, z)
    Let(v, y, z) => (g.let_reg)(v.name(), y, z)
    Ite(cond~, yes~, no~) => (g.ite)(cond, yes, no)
    Extract(hi~, lo~, exp~) if hi == lo => (g.extract)(hi, exp)
    Unknown(_) => (g.unknown)()
    _ => g.error
  }
}

///|
fn bil_parse_stmt(
  g : StmtGrammar[@types.Exp, @types.Exp, @types.Stmt],
  stmt : @types.Stmt,
) -> Eff {
  match @types.Stmt::decode(@types.Stmt::call(), stmt) {
    Some(dst) => return (g.call)(dst)
    None => ()
  }
  match @types.Stmt::decode(@types.Stmt::intrinsic(), stmt) {
    Some(data) => return (g.call)("intrinsic:" + data)
    None => ()
  }
  match stmt {
    Move(v, x) =>
      match v.typ() {
        Imm(1) => (g.set_bit)(v.name(), x)
        Imm(size) => (g.set_reg)(v.name(), size, x)
        Mem(addr_width~, value_width~) =>
          (g.set_mem)(v.name(), addr_width, value_width, x)
      }
    Jmp(Int(x)) => (g.goto)(x.to_bitvec())
    Jmp(x) => (g.jmp)(x)
    Special(text) => (g.special)(text)
    While(cond~, body~) => (g.while_)(cond, body)
    If(cond~, yes~, no~) => (g.if_)(cond, yes, no)
    CpuExn(n) => (g.cpuexn)(n)
  }
}

///|
/// The parser of BIL (`Bap_core_theory_bil_parser.t`): reflects BIL
/// expressions and statements into Core Theory terms. Floating-point and
/// rounding-mode terms do not exist in BIL (they are ill-formed).
pub fn bil_parser() -> Parser[@types.Exp, @types.Exp, @types.Stmt] {
  {
    bitv: bil_parse_bitv,
    bool: bil_parse_bool,
    mem: bil_parse_mem,
    stmt: bil_parse_stmt,
    float: (g, _) => g.error,
    rmode: (g, _) => g.error,
  }
}

///|
/// Reflects a BIL program into the theory `self` (`Bil.Theory.parser`
/// with `Theory.Parser.Make(CT).run`), so that legacy BIL lifters can
/// provide semantics in any theory.
pub fn Core::reflect_bil(self : Core, program : ArrayView[@types.Stmt]) -> Eff {
  self.parse(bil_parser(), program)
}
