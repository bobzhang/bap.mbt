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
pub fn UnOp::string_of_unop(self : UnOp) -> String {
  match self {
    Not => "~"
    Neg => "-"
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
pub fn BinOp::string_of_binop(self : BinOp) -> String {
  match self {
    Plus => "+"
    Minus => "-"
    Times => "*"
    Div => "/"
    SignedDiv => "/$"
    Mod => "%"
    SignedMod => "%$"
    And => "&"
    Or => "|"
    Xor => "^"
    LShift => "<<"
    RShift => ">>"
    ARShift => "~>>"
    Eq => "="
    Neq => "<>"
    Lt => "<"
    Le => "<="
    SignedLt => "<$"
    SignedLe => "<=$"
  }
}

///|
pub fn BinOp::is_commutative(self : BinOp) -> Bool {
  match self {
    Plus | Times | And | Xor | Or | Eq | Neq => true
    _ => false
  }
}

///|
pub fn BinOp::is_associative(self : BinOp) -> Bool {
  match self {
    Plus | Times | And | Or | Xor => true
    _ => false
  }
}

///|
pub(all) enum CastKind {
  Unsigned
  Signed
  High
  Low
} derive(Eq, Debug)

///|
pub fn CastKind::to_string(self : CastKind) -> String {
  match self {
    Unsigned => "pad"
    Signed => "extend"
    High => "high"
    Low => "low"
  }
}

///|
pub fn CastKind::string_of_cast(self : CastKind) -> String {
  self.to_string()
}

///|
pub(all) enum Exp {
  Int(Word)
  Var(Var)
  Unknown(String, ValueType)
  Load(mem~ : Exp, addr~ : Exp, endian~ : @bitvec.Endian, typ~ : ValueType)
  Store(mem~ : Exp, addr~ : Exp, value~ : Exp, endian~ : @bitvec.Endian)
  Let(Var, Exp, Exp)
  Cast(kind~ : CastKind, width~ : Int, exp~ : Exp)
  Extract(hi~ : Int, lo~ : Int, exp~ : Exp)
  Concat(high~ : Exp, low~ : Exp)
  UnOp(UnOp, Exp)
  BinOp(BinOp, Exp, Exp)
  Ite(cond~ : Exp, yes~ : Exp, no~ : Exp)
} derive(Eq, Debug)

///|
pub fn Exp::load(
  mem~ : Exp,
  addr~ : Exp,
  endian : @bitvec.Endian,
  size : Size,
) -> Exp {
  Load(mem~, addr~, endian~, typ=Imm(size.in_bits()))
}

///|
pub fn Exp::load_byte(mem~ : Exp, addr~ : Exp) -> Exp {
  Exp::load(mem~, addr~, BigEndian, R8)
}

///|
pub fn Exp::store(
  mem~ : Exp,
  addr~ : Exp,
  value : Exp,
  endian : @bitvec.Endian,
  size : Size,
) -> Exp {
  let _ = size
  Store(mem~, addr~, value~, endian~)
}

///|
pub fn Exp::store_byte(mem~ : Exp, addr~ : Exp, value : Exp) -> Exp {
  Exp::store(mem~, addr~, value, BigEndian, R8)
}

///|
pub fn Exp::binop(op : BinOp, lhs : Exp, rhs : Exp) -> Exp {
  BinOp(op, lhs, rhs)
}

///|
pub fn Exp::unop(op : UnOp, exp : Exp) -> Exp {
  UnOp(op, exp)
}

///|
#alias(var)
pub fn Exp::var_exp(variable : Var) -> Exp {
  Var(variable)
}

///|
pub fn Exp::int(word : Word) -> Exp {
  Int(word)
}

///|
pub fn Exp::let_(variable : Var, value : Exp, body : Exp) -> Exp {
  Let(variable, value, body)
}

///|
pub fn Exp::cast(kind : CastKind, width : Int, exp : Exp) -> Exp {
  Cast(kind~, width~, exp~)
}

///|
pub fn Exp::unknown(name : String, typ : ValueType) -> Exp {
  Unknown(name, typ)
}

///|
pub fn Exp::extract(exp : Exp, hi? : Int = -1, lo? : Int = 0) -> Exp {
  let actual_hi = if hi >= 0 {
    hi
  } else {
    match exp.type_of() {
      Imm(width) => width - 1
      Mem(_) => hi
    }
  }
  Extract(hi=actual_hi, lo~, exp~)
}

///|
pub fn Exp::concat(high : Exp, low : Exp) -> Exp {
  Concat(high~, low~)
}

///|
pub fn Exp::ite(if_~ : Exp, then_~ : Exp, else_~ : Exp) -> Exp {
  Ite(cond=if_, yes=then_, no=else_)
}

///|
pub fn Exp::type_of(self : Exp) -> ValueType {
  match self {
    Int(word) => Imm(word.width())
    Var(v) => v.typ
    Unknown(_, typ) => typ
    Load(typ~, ..) => typ
    Store(mem~, ..) => mem.type_of()
    Let(_, _, body) => body.type_of()
    Cast(width~, ..) => Imm(width)
    Extract(hi~, lo~, ..) => Imm(hi - lo + 1)
    Concat(high~, low~) =>
      match (high.type_of(), low.type_of()) {
        (Imm(high_width), Imm(low_width)) => Imm(high_width + low_width)
        (typ, _) => typ
      }
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
    Cast(kind~, width~, exp~) =>
      "\{kind.to_string()}:\{width}[\{exp.to_string()}]"
    Extract(hi~, lo~, exp~) => "extract[\{hi}:\{lo}](\{exp.to_string()})"
    Concat(high~, low~) => "concat(\{high.to_string()}, \{low.to_string()})"
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
struct StmtAttribute[T] {
  key : String
  encode_value : (T) -> String
  decode_value : (String) -> T
}

///|
pub(all) suberror StmtAttributeError {
  DuplicateStmtAttribute(String)
} derive(Eq, Debug)

///|
let stmt_attribute_prefix = "@attribute:"

///|
let stmt_attribute_registry : Array[String] = [
  "bap:call", "bap:intrinsic", "bap:goto", "bap:label",
]

///|
fn stmt_attribute_key(name : String, pkg? : String) -> String {
  match pkg {
    Some(value) if value != "" => "\{value}:\{name}"
    _ => name
  }
}

///|
fn stmt_attribute_string(name : String, pkg? : String) -> StmtAttribute[String] {
  {
    key: stmt_attribute_key(name, pkg?),
    encode_value: value => value,
    decode_value: value => value,
  }
}

///|
pub fn[T] StmtAttribute::register(
  name : String,
  encode~ : (T) -> String,
  decode~ : (String) -> T,
  pkg? : String,
) -> StmtAttribute[T] raise StmtAttributeError {
  let key = stmt_attribute_key(name, pkg?)
  if stmt_attribute_registry.contains(key) {
    raise DuplicateStmtAttribute(key)
  }
  stmt_attribute_registry.push(key)
  { key, encode_value: encode, decode_value: decode }
}

///|
pub fn[T] StmtAttribute::declare_(
  name : String,
  encode~ : (T) -> String,
  decode~ : (String) -> T,
  pkg? : String,
) -> StmtAttribute[T] raise StmtAttributeError {
  StmtAttribute::register(name, encode~, decode~, pkg?)
}

///|
pub fn[T] StmtAttribute::key(self : StmtAttribute[T]) -> String {
  self.key
}

///|
fn stmt_attribute_quote_atom(text : String) -> String {
  if text == "" ||
    text.contains(" ") ||
    text.contains("(") ||
    text.contains(")") ||
    text.contains("\"") {
    "\"\{text}\""
  } else {
    text
  }
}

///|
fn stmt_attribute_unquote_atom(text : String) -> String {
  if text.length() >= 2 && text.has_prefix("\"") && text.has_suffix("\"") {
    text[1:text.length() - 1].to_owned()
  } else {
    text
  }
}

///|
fn stmt_attribute_encode_payload(key : String, data : String) -> String {
  if data == "" {
    stmt_attribute_prefix + key
  } else {
    stmt_attribute_prefix +
    "(\{stmt_attribute_quote_atom(key)} \{stmt_attribute_quote_atom(data)})"
  }
}

///|
fn stmt_attribute_decode_payload(payload : String) -> (String, String)? {
  if payload.has_prefix("(") && payload.has_suffix(")") {
    let inner = payload[1:payload.length() - 1].to_owned()
    let parts = inner.split(" ").to_array()
    if parts.length() == 0 {
      None
    } else {
      let key = stmt_attribute_unquote_atom(parts[0].to_owned())
      if parts.length() == 1 {
        Some((key, ""))
      } else {
        let data_parts = []
        for i in 1..<parts.length() {
          data_parts.push(parts[i].to_owned())
        }
        Some((key, stmt_attribute_unquote_atom(data_parts.join(" "))))
      }
    }
  } else {
    Some((payload, ""))
  }
}

///|
fn stmt_attribute_decode_special(text : String) -> (String, String)? {
  if text.has_prefix(stmt_attribute_prefix) {
    stmt_attribute_decode_payload(
      text[stmt_attribute_prefix.length():].to_owned(),
    )
  } else {
    None
  }
}

///|
#alias(move)
pub fn Stmt::move_stmt(variable : Var, exp : Exp) -> Stmt {
  Move(variable, exp)
}

///|
pub fn Stmt::jmp(exp : Exp) -> Stmt {
  Jmp(exp)
}

///|
pub fn Stmt::special(text : String) -> Stmt {
  Special(text)
}

///|
pub fn Stmt::while_(cond : Exp, body : Array[Stmt]) -> Stmt {
  While(cond~, body~)
}

///|
pub fn Stmt::if_(cond : Exp, yes : Array[Stmt], no : Array[Stmt]) -> Stmt {
  If(cond~, yes~, no~)
}

///|
pub fn Stmt::cpuexn(code : Int) -> Stmt {
  CpuExn(code)
}

///|
pub fn Stmt::call() -> StmtAttribute[String] {
  stmt_attribute_string("call", pkg="bap")
}

///|
pub fn Stmt::intrinsic() -> StmtAttribute[String] {
  stmt_attribute_string("intrinsic", pkg="bap")
}

///|
pub fn Stmt::goto() -> StmtAttribute[String] {
  stmt_attribute_string("goto", pkg="bap")
}

///|
pub fn Stmt::label() -> StmtAttribute[String] {
  stmt_attribute_string("label", pkg="bap")
}

///|
pub fn[T] Stmt::encode(attr : StmtAttribute[T], value : T) -> Stmt {
  Special(stmt_attribute_encode_payload(attr.key, (attr.encode_value)(value)))
}

///|
pub fn[T] Stmt::decode(attr : StmtAttribute[T], stmt : Stmt) -> T? {
  match stmt {
    Special(text) =>
      match stmt_attribute_decode_special(text) {
        Some((key, data)) if key == attr.key => Some((attr.decode_value)(data))
        _ => None
      }
    _ => None
  }
}

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
