// Upstream-compatible BIL printers (`Bap_exp.PP`, `Bap_stmt.pp`,
// `Bap_bil_adt`, and the ppx-sexp representation used by the `sexp`
// format). The port's `Exp::to_string`/`Stmt::to_string` use a different
// concrete syntax, so the plugin reproduces the upstream text here.

///|
/// Prints a word like upstream `Bitvector.pp_hex`: uppercase hexadecimal,
/// with the `0x` prefix only for values that are not single digits.
pub fn word_to_hex(w : @types.Word) -> String {
  w.format_value(
    format=WordHex,
    letter_case=WordUpperCase,
    prefix=WordAutoPrefix,
    suffix=WordNoSuffix,
  )
}

///|
/// Prints a word like upstream `Bitvector.pp_dec`.
fn word_to_dec(w : @types.Word) -> String {
  w.format_value(format=WordDec, prefix=WordAutoPrefix, suffix=WordNoSuffix)
}

///|
/// The identifier of a variable, as printed by upstream `Var.pp`
/// (`name` or `name.version` for SSA versions).
pub fn var_ident(v : @types.Var) -> String {
  let index = v.index()
  let base = v.base().name()
  if index > 0 && base != "" {
    "\{base}.\{index}"
  } else {
    v.name()
  }
}

///|
/// Prints a value type like upstream `Type.pp` (`u32`, `u64?u8`).
pub fn type_to_string(t : @types.ValueType) -> String {
  match t {
    Imm(n) => "u\{n}"
    Mem(addr_width~, value_width~) => "u\{addr_width}?u\{value_width}"
  }
}

///|
fn endian_to_string(e : @bitvec.Endian) -> String {
  match e {
    LittleEndian => "el"
    BigEndian => "be"
  }
}

///|
fn binop_to_string(op : @types.BinOp) -> String {
  match op {
    Plus => "+"
    Minus => "-"
    Times => "*"
    Div => "/"
    SignedDiv => "/$"
    Mod => "%"
    SignedMod => "%$"
    LShift => "<<"
    RShift => ">>"
    ARShift => "~>>"
    And => "&"
    Or => "|"
    Xor => "^"
    Eq => "="
    Neq => "<>"
    Lt => "<"
    Le => "<="
    SignedLt => "<$"
    SignedLe => "<=$"
  }
}

///|
fn unop_to_string(op : @types.UnOp) -> String {
  match op {
    Neg => "-"
    Not => "~"
  }
}

///|
fn op_prec(op : @types.BinOp) -> Int {
  match op {
    Times | Div | SignedDiv | Mod | SignedMod => 8
    Plus | Minus => 7
    LShift | RShift | ARShift => 6
    Lt | Le | SignedLt | SignedLe => 5
    Eq | Neq => 4
    And => 3
    Xor => 2
    Or => 1
  }
}

///|
fn exp_prec(e : @types.Exp) -> Int {
  match e {
    Var(_) | Int(_) | Unknown(_, _) => 10
    Load(_) | Cast(_) | Extract(_) => 10
    UnOp(_, _) => 9
    BinOp(op, _, _) => op_prec(op)
    Store(_) | Let(_, _, _) | Ite(_) | Concat(_) => 0
  }
}

///|
fn is_bit(w : @types.Word, value : Bool) -> Bool {
  w.bitwidth() == 1 && (if value { w.is_one() } else { w.is_zero() })
}

///|
/// The size (in bits) of the value stored or loaded by a memory access.
fn exp_bits(e : @types.Exp) -> Int? {
  match e.infer_type() {
    Ok(Imm(n)) => Some(n)
    _ => None
  }
}

///|
fn pp_sub_exp(
  fmt : @text_tags.Formatter,
  parent : @types.Exp,
  child : @types.Exp,
) -> Unit {
  if exp_prec(child) >= exp_prec(parent) {
    pp_exp(fmt, child)
  } else {
    fmt.print_format("(@[<2>")
    pp_exp(fmt, child)
    fmt.print_format("@])")
  }
}

///|
/// Prints an expression in the upstream BIL concrete syntax.
pub fn pp_exp(fmt : @text_tags.Formatter, exp : @types.Exp) -> Unit {
  match exp {
    Load(mem~, addr~, endian~, typ~) => {
      pp_exp(fmt, mem)
      fmt.print_string("[")
      pp_exp(fmt, addr)
      match typ {
        Imm(8) => fmt.print_string("]")
        _ => {
          fmt.print_string(", ")
          fmt.print_string(endian_to_string(endian))
          fmt.print_string("]:")
          fmt.print_string(type_to_string(typ))
        }
      }
    }
    Store(mem~, addr~, value~, endian~) => {
      fmt.print_format("@[<4>")
      pp_exp(fmt, mem)
      fmt.print_format("@;with [")
      pp_exp(fmt, addr)
      let edn = endian_to_string(endian)
      match exp_bits(value) {
        Some(8) => fmt.print_string("] <- ")
        Some(n) => fmt.print_string(", \{edn}]:u\{n} <- ")
        None => fmt.print_string(", \{edn}] <- ")
      }
      pp_exp(fmt, value)
      fmt.print_format("@]")
    }
    Ite(cond~, yes~, no~) => {
      fmt.print_format("@[if ")
      pp_exp(fmt, cond)
      fmt.print_format("@;then ")
      pp_exp(fmt, yes)
      fmt.print_format("@;else ")
      pp_exp(fmt, no)
      fmt.print_format("@]")
    }
    Extract(hi~, lo~, exp=e) => {
      fmt.print_string("\{hi}:\{lo}[")
      pp_exp(fmt, e)
      fmt.print_string("]")
    }
    Concat(high~, low~) => {
      pp_sub_exp(fmt, exp, high)
      fmt.print_string(".")
      pp_sub_exp(fmt, exp, low)
    }
    BinOp(Eq, e, Int(x)) if is_bit(x, true) => pp_exp(fmt, e)
    BinOp(Eq, Int(x), e) if is_bit(x, true) => pp_exp(fmt, e)
    BinOp(Eq, e, Int(x)) | BinOp(Eq, Int(x), e) if is_bit(x, false) => {
      fmt.print_string("~")
      pp_sub_exp(fmt, exp, e)
    }
    BinOp(Plus, le, Int(x)) if x.msb() => {
      // an integer always binds tighter than `+`
      pp_sub_exp(fmt, exp, le)
      fmt.print_string(" - ")
      fmt.print_string(word_to_hex(x.neg()))
    }
    BinOp(op, le, re) => {
      pp_sub_exp(fmt, exp, le)
      fmt.print_space()
      fmt.print_string(binop_to_string(op))
      fmt.print_space()
      pp_sub_exp(fmt, exp, re)
    }
    UnOp(op, e) => {
      fmt.print_string(unop_to_string(op))
      pp_sub_exp(fmt, exp, e)
    }
    Var(v) => fmt.print_string(var_ident(v))
    Int(w) => fmt.print_string(word_to_hex(w))
    Cast(kind~, width~, exp=e) => {
      fmt.print_string("\{kind.to_string()}:\{width}[")
      pp_exp(fmt, e)
      fmt.print_string("]")
    }
    Let(v, def, body) => {
      fmt.print_format("@[let ")
      fmt.print_string(var_ident(v))
      fmt.print_format(" =@ ")
      pp_exp(fmt, def)
      fmt.print_format(" in@ ")
      pp_exp(fmt, body)
      fmt.print_format("@]")
    }
    Unknown(s, typ) => fmt.print_string("unknown[\{s}]:\{type_to_string(typ)}")
  }
}

///|
/// Renders an expression in the upstream BIL concrete syntax.
pub fn exp_to_string(exp : @types.Exp) -> String {
  let fmt = @text_tags.Formatter::new()
  pp_exp(fmt, exp)
  fmt.flush_str()
}

///|
/// Prints a statement in the upstream BIL concrete syntax.
pub fn pp_stmt(fmt : @text_tags.Formatter, stmt : @types.Stmt) -> Unit {
  match stmt {
    Move(v, e) => {
      fmt.print_format("@[<2>")
      fmt.print_string(var_ident(v))
      fmt.print_format(" :=@ ")
      pp_exp(fmt, e)
      fmt.print_format("@]")
    }
    Jmp(Var(_) | Int(_) as e) => {
      fmt.print_format("@[<2>jmp@ ")
      pp_exp(fmt, e)
      fmt.print_format("@]")
    }
    Jmp(e) => {
      fmt.print_format("@[<2>jmp@ (")
      pp_exp(fmt, e)
      fmt.print_format(")@]")
    }
    Special(s) =>
      match special_attribute(s) {
        Some((cons, vals)) => {
          fmt.print_string(cons + "(")
          fmt.print_format("@[<hv2>")
          fmt.print_string(vals.map(sexp_atom).join(", "))
          fmt.print_format("@])")
        }
        None => {
          fmt.print_format("special@ @[<1>(")
          fmt.print_string(s)
          fmt.print_format(")@]")
        }
      }
    While(cond~, body~) => {
      fmt.print_format("@[<v0>@[<v2>while (@[")
      pp_exp(fmt, cond)
      fmt.print_format("@]) {@;")
      pp_stmt_list(fmt, body)
      fmt.print_format("@]@;}@]")
    }
    If(cond~, yes~, no=[]) => {
      fmt.print_format("@[<v0>@[<v2>if (@[")
      pp_exp(fmt, cond)
      fmt.print_format("@]) {@;")
      pp_stmt_list(fmt, yes)
      fmt.print_format("@]@,}@]")
    }
    If(cond~, yes~, no~) => {
      fmt.print_format("@[<v0>@[<v2>if (@[")
      pp_exp(fmt, cond)
      fmt.print_format("@]) {@;")
      pp_stmt_list(fmt, yes)
      fmt.print_format("@]@,}@;")
      fmt.print_format("@[<v0>@[<v2>else {@;")
      pp_stmt_list(fmt, no)
      fmt.print_format("@]@;}@]")
      fmt.print_format("@]")
    }
    CpuExn(n) => fmt.print_string("cpuexn (\{n})")
  }
}

///|
/// Decodes a BIL attribute encoded in a special statement as
/// `@attribute:(<constr> <data>)` (upstream `Special.pp`), returning the
/// constructor name without the `bap:` package and the payload atoms.
fn special_attribute(s : String) -> (String, Array[String])? {
  guard s.strip_prefix("@attribute:") is Some(payload) else { None }
  let chars = payload.to_array()
  guard chars.length() >= 2 &&
    chars[0] == '(' &&
    chars[chars.length() - 1] == ')' else {
    None
  }
  let atoms = []
  let mut i = 1
  let last = chars.length() - 1
  while i < last {
    let c = chars[i]
    if c == ' ' || c == '\t' || c == '\n' {
      i += 1
    } else if c == '"' {
      let buf = StringBuilder()
      i += 1
      while i < last && chars[i] != '"' {
        if chars[i] == '\\' && i + 1 < last {
          i += 1
          buf.write_char(re_escaped_char(chars[i]))
        } else {
          buf.write_char(chars[i])
        }
        i += 1
      }
      i += 1
      atoms.push(buf.to_string())
    } else if c == '(' || c == ')' {
      return None
    } else {
      let buf = StringBuilder()
      while i < last && !(chars[i] is (' ' | '\t' | '\n' | '(' | ')')) {
        buf.write_char(chars[i])
        i += 1
      }
      atoms.push(buf.to_string())
    }
  }
  guard atoms is [cons, .. vals] else { None }
  let cons = match cons.strip_prefix("bap:") {
    Some(rest) => rest.to_owned()
    None => cons
  }
  Some((cons, vals.to_owned()))
}

///|
fn pp_stmt_list(
  fmt : @text_tags.Formatter,
  stmts : ArrayView[@types.Stmt],
) -> Unit {
  for i, s in stmts {
    if i > 0 {
      fmt.print_format("@;")
    }
    pp_stmt(fmt, s)
  }
}

///|
/// Prints a BIL program (a statement list) like upstream `Bil.pp`.
pub fn pp_bil(fmt : @text_tags.Formatter, bil : ArrayView[@types.Stmt]) -> Unit {
  fmt.print_format("@[<v0>@[<v2>{@;")
  pp_stmt_list(fmt, bil)
  fmt.print_format("@]@;}@]")
}

///|
/// Renders a BIL program like upstream `Bil.to_string`.
pub fn bil_to_string(bil : ArrayView[@types.Stmt]) -> String {
  let fmt = @text_tags.Formatter::new()
  pp_bil(fmt, bil)
  fmt.flush_str()
}

// ADT format (upstream `Bap_bil_adt`)

///|
fn adt_type(t : @types.ValueType) -> String {
  match t {
    Imm(n) => "Imm(\{n})"
    Mem(addr_width~, value_width~) => "Mem(\{addr_width},\{value_width})"
  }
}

///|
/// A variable in the ADT format, e.g., `Var("RAX",Imm(64))`.
pub fn var_to_adt(v : @types.Var) -> String {
  "Var(\"\{var_ident(v)}\",\{adt_type(v.typ())})"
}

///|
fn adt_endian(e : @bitvec.Endian) -> String {
  match e {
    LittleEndian => "LittleEndian()"
    BigEndian => "BigEndian()"
  }
}

///|
fn binop_sexp_name(op : @types.BinOp) -> String {
  match op {
    Plus => "PLUS"
    Minus => "MINUS"
    Times => "TIMES"
    Div => "DIVIDE"
    SignedDiv => "SDIVIDE"
    Mod => "MOD"
    SignedMod => "SMOD"
    LShift => "LSHIFT"
    RShift => "RSHIFT"
    ARShift => "ARSHIFT"
    And => "AND"
    Or => "OR"
    Xor => "XOR"
    Eq => "EQ"
    Neq => "NEQ"
    Lt => "LT"
    Le => "LE"
    SignedLt => "SLT"
    SignedLe => "SLE"
  }
}

///|
fn unop_sexp_name(op : @types.UnOp) -> String {
  match op {
    Neg => "NEG"
    Not => "NOT"
  }
}

///|
fn cast_sexp_name(kind : @types.CastKind) -> String {
  match kind {
    Unsigned => "UNSIGNED"
    Signed => "SIGNED"
    High => "HIGH"
    Low => "LOW"
  }
}

///|
/// An expression in the ADT format (upstream `Exp.Io.print ~fmt:"adt"`).
pub fn exp_to_adt(e : @types.Exp) -> String {
  match e {
    Load(mem~, addr~, endian~, typ~) => {
      let size = typ.bitwidth().unwrap_or(0)
      "Load(\{exp_to_adt(mem)},\{exp_to_adt(addr)},\{adt_endian(endian)},\{size})"
    }
    Store(mem~, addr~, value~, endian~) => {
      let size = exp_bits(value).unwrap_or(0)
      "Store(\{exp_to_adt(mem)},\{exp_to_adt(addr)},\{exp_to_adt(value)},\{adt_endian(endian)},\{size})"
    }
    BinOp(op, x, y) =>
      "\{binop_sexp_name(op)}(\{exp_to_adt(x)},\{exp_to_adt(y)})"
    UnOp(op, x) => "\{unop_sexp_name(op)}(\{exp_to_adt(x)})"
    Var(v) => var_to_adt(v)
    Int(w) => "Int(\{word_to_dec(w)},\{w.bitwidth()})"
    Cast(kind~, width~, exp~) =>
      "\{cast_sexp_name(kind)}(\{width},\{exp_to_adt(exp)})"
    Let(v, x, y) => "Let(\{var_to_adt(v)},\{exp_to_adt(x)},\{exp_to_adt(y)})"
    Unknown(s, t) => "Unknown(\{escape_ocaml_string(s)},\{adt_type(t)})"
    Ite(cond~, yes~, no~) =>
      "Ite(\{exp_to_adt(cond)},\{exp_to_adt(yes)},\{exp_to_adt(no)})"
    Extract(hi~, lo~, exp~) => "Extract(\{hi},\{lo},\{exp_to_adt(exp)})"
    Concat(high~, low~) => "Concat(\{exp_to_adt(high)},\{exp_to_adt(low)})"
  }
}

///|
/// A statement in the ADT format.
pub fn stmt_to_adt(s : @types.Stmt) -> String {
  match s {
    Move(v, e) => "Move(\{var_to_adt(v)},\{exp_to_adt(e)})"
    Jmp(e) => "Jmp(\{exp_to_adt(e)})"
    Special(s) => "Special(\{escape_ocaml_string(s)})"
    While(cond~, body~) => "While(\{exp_to_adt(cond)}, (\{stmts_to_adt(body)}))"
    If(cond~, yes~, no~) =>
      "If(\{exp_to_adt(cond)}, (\{stmts_to_adt(yes)}), (\{stmts_to_adt(no)}))"
    CpuExn(n) => "CpuExn(\{n})"
  }
}

///|
fn stmts_to_adt(stmts : ArrayView[@types.Stmt]) -> String {
  stmts.map(stmt_to_adt).join(", ")
}

///|
/// A BIL program in the ADT format, e.g., `(Move(...), Jmp(...))`.
pub fn bil_to_adt(bil : ArrayView[@types.Stmt]) -> String {
  "(\{stmts_to_adt(bil)})"
}

// Sexp format (the ppx_sexp_conv representation of `Bap_bil`)

///|
fn sexp_atom(s : String) -> String {
  let needs_quotes = s == "" ||
    s
    .iter()
    .any(c => {
      c == ' ' ||
      c == '(' ||
      c == ')' ||
      c == '"' ||
      c == ';' ||
      c == '\\' ||
      c.to_int() < 0x20
    })
  if needs_quotes {
    escape_ocaml_string(s)
  } else {
    s
  }
}

///|
fn sexp_type(t : @types.ValueType) -> String {
  match t {
    Imm(n) => "(Imm \{n})"
    Mem(addr_width~, value_width~) => "(Mem r\{addr_width} r\{value_width})"
  }
}

///|
fn sexp_var(v : @types.Var) -> String {
  "((name \{sexp_atom(var_ident(v))})(sort \{sexp_type(v.typ())}))"
}

///|
fn sexp_endian(e : @bitvec.Endian) -> String {
  match e {
    LittleEndian => "LittleEndian"
    BigEndian => "BigEndian"
  }
}

///|
/// An expression as an S-expression.
pub fn exp_to_sexp(e : @types.Exp) -> String {
  match e {
    Load(mem~, addr~, endian~, typ~) => {
      let size = typ.bitwidth().unwrap_or(0)
      "(Load \{exp_to_sexp(mem)} \{exp_to_sexp(addr)} \{sexp_endian(endian)} r\{size})"
    }
    Store(mem~, addr~, value~, endian~) => {
      let size = exp_bits(value).unwrap_or(0)
      "(Store \{exp_to_sexp(mem)} \{exp_to_sexp(addr)} \{exp_to_sexp(value)} \{sexp_endian(endian)} r\{size})"
    }
    BinOp(op, x, y) =>
      "(BinOp \{binop_sexp_name(op)} \{exp_to_sexp(x)} \{exp_to_sexp(y)})"
    UnOp(op, x) => "(UnOp \{unop_sexp_name(op)} \{exp_to_sexp(x)})"
    Var(v) => "(Var \{sexp_var(v)})"
    Int(w) => "(Int \{sexp_atom(w.to_string())})"
    Cast(kind~, width~, exp~) =>
      "(Cast \{cast_sexp_name(kind)} \{width} \{exp_to_sexp(exp)})"
    Let(v, x, y) => "(Let \{sexp_var(v)} \{exp_to_sexp(x)} \{exp_to_sexp(y)})"
    Unknown(s, t) => "(Unknown \{sexp_atom(s)} \{sexp_type(t)})"
    Ite(cond~, yes~, no~) =>
      "(Ite \{exp_to_sexp(cond)} \{exp_to_sexp(yes)} \{exp_to_sexp(no)})"
    Extract(hi~, lo~, exp~) => "(Extract \{hi} \{lo} \{exp_to_sexp(exp)})"
    Concat(high~, low~) => "(Concat \{exp_to_sexp(high)} \{exp_to_sexp(low)})"
  }
}

///|
/// A statement as an S-expression.
pub fn stmt_to_sexp(s : @types.Stmt) -> String {
  match s {
    Move(v, e) => "(Move \{sexp_var(v)} \{exp_to_sexp(e)})"
    Jmp(e) => "(Jmp \{exp_to_sexp(e)})"
    Special(s) => "(Special \{sexp_atom(s)})"
    While(cond~, body~) => "(While \{exp_to_sexp(cond)} \{bil_to_sexp(body)})"
    If(cond~, yes~, no~) =>
      "(If \{exp_to_sexp(cond)} \{bil_to_sexp(yes)} \{bil_to_sexp(no)})"
    CpuExn(n) => "(CpuExn \{n})"
  }
}

///|
/// A BIL program as an S-expression.
pub fn bil_to_sexp(bil : ArrayView[@types.Stmt]) -> String {
  "(\{bil.map(stmt_to_sexp).join(" ")})"
}
