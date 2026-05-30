///|
pub(all) enum UnOp {
  Not
  Neg
} derive(Eq, Debug)

///|
pub fn UnOp::to_string(self : UnOp) -> String {
  match self {
    Not => "not"
    Neg => "neg"
  }
}

///|
pub(all) enum BinOp {
  Plus
  Minus
  Times
  Div
  SignedDiv
  Mod
  SignedMod
  And
  Or
  Xor
  LShift
  RShift
  ARShift
  Eq
  Neq
  Lt
  Le
  SignedLt
  SignedLe
} derive(Eq, Debug)

///|
pub fn BinOp::to_string(self : BinOp) -> String {
  match self {
    Plus => "+"
    Minus => "-"
    Times => "*"
    Div => "/"
    SignedDiv => "s/"
    Mod => "%"
    SignedMod => "s%"
    And => "&"
    Or => "|"
    Xor => "^"
    LShift => "<<"
    RShift => ">>"
    ARShift => "a>>"
    Eq => "=="
    Neq => "!="
    Lt => "<"
    Le => "<="
    SignedLt => "s<"
    SignedLe => "s<="
  }
}

///|
pub(all) enum Exp {
  Int(Word)
  Var(Var)
  Unknown(String, ValueType)
  Load(mem~ : Exp, addr~ : Exp, endian~ : @bitvec.Endian, typ~ : ValueType)
  Store(mem~ : Exp, addr~ : Exp, value~ : Exp, endian~ : @bitvec.Endian)
  Let(Var, Exp, Exp)
  Cast(ValueType, Exp)
  UnOp(UnOp, Exp)
  BinOp(BinOp, Exp, Exp)
  Ite(cond~ : Exp, yes~ : Exp, no~ : Exp)
} derive(Eq, Debug)

///|
pub fn Exp::type_of(self : Exp) -> ValueType {
  match self {
    Int(word) => Imm(word.width())
    Var(v) => v.typ
    Unknown(_, typ) => typ
    Load(typ~, ..) => typ
    Store(mem~, ..) => mem.type_of()
    Let(_, _, body) => body.type_of()
    Cast(typ, _) => typ
    UnOp(_, exp) => exp.type_of()
    BinOp(op, lhs, _) =>
      match op {
        Eq | Neq | Lt | Le | SignedLt | SignedLe => Imm(1)
        _ => lhs.type_of()
      }
    Ite(yes~, ..) => yes.type_of()
  }
}

///|
pub fn Exp::to_string(self : Exp) -> String {
  match self {
    Int(word) => word.to_string()
    Var(v) => v.to_string()
    Unknown(name, typ) => "unknown(\{name}:\{typ.to_string()})"
    Load(mem~, addr~, endian=_, typ~) =>
      "load(\{mem.to_string()}, \{addr.to_string()}):\{typ.to_string()}"
    Store(mem~, addr~, value~, endian=_) =>
      "store(\{mem.to_string()}, \{addr.to_string()}, \{value.to_string()})"
    Let(v, value, body) =>
      "let \{v.to_string()} = \{value.to_string()} in \{body.to_string()}"
    Cast(typ, exp) => "cast(\{typ.to_string()}, \{exp.to_string()})"
    UnOp(op, exp) => "(\{op.to_string()} \{exp.to_string()})"
    BinOp(op, lhs, rhs) =>
      "(\{lhs.to_string()} \{op.to_string()} \{rhs.to_string()})"
    Ite(cond~, yes~, no~) =>
      "ite(\{cond.to_string()}, \{yes.to_string()}, \{no.to_string()})"
  }
}

///|
pub(all) enum Stmt {
  Move(Var, Exp)
  Jmp(Exp)
  Special(String)
  CpuExn(Int)
  If(cond~ : Exp, yes~ : Array[Stmt], no~ : Array[Stmt])
  While(cond~ : Exp, body~ : Array[Stmt])
} derive(Eq, Debug)

///|
pub fn Stmt::to_string(self : Stmt) -> String {
  match self {
    Move(v, exp) => "\{v.to_string()} := \{exp.to_string()}"
    Jmp(exp) => "jmp \{exp.to_string()}"
    Special(text) => "special \{text}"
    CpuExn(code) => "cpuexn \{code}"
    If(cond~, yes~, no~) =>
      "if \{cond.to_string()} then \{yes.length()} stmts else \{no.length()} stmts"
    While(cond~, body~) => "while \{cond.to_string()} do \{body.length()} stmts"
  }
}

///|
pub fn Stmt::defined_var(self : Stmt) -> Var? {
  match self {
    Move(v, _) => Some(v)
    _ => None
  }
}
