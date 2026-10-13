// The Primus Lisp abstract syntax (upstream `Bap_primus_lisp_types`,
// `Bap_primus_lisp_type`, `Bap_primus_lisp_var`, `Bap_primus_lisp_word`).

///|
/// A Lisp type (upstream `Bap_primus_lisp_types.typ`).
///
/// - `Any` is the top type (no constraints);
/// - `Symbol` is the type of symbols;
/// - `Name(a)` is a type variable;
/// - `Type(n)` is the type of `n`-bit words.
pub(all) enum Typ {
  Any
  Symbol
  Name(String)
  Type(Int32)
} derive(Eq, Compare, Debug)

///|
pub impl Show for Typ with fn output(self, logger) {
  match self {
    Any | Symbol => ()
    Name(s) => logger.write_string(s)
    Type(n) => logger.write_object(n)
  }
}

///|
/// The width of symbols (upstream `Type.symbol_size`).
pub let symbol_size : Int32 = 63

///|
/// Parses a type annotation, e.g., `32` (upstream `Type.read`).
pub fn Typ::read(s : String) -> Typ? {
  match parse_small_int(s.trim().to_owned()) {
    Some(n) => Some(Type(n))
    None => None
  }
}

///|
/// `Typ::mem(t, n)` is true if an `n`-bit word is a member of `t`.
pub fn Typ::mem(self : Typ, n : Int32) -> Bool {
  match self {
    Any | Name(_) => true
    Symbol => n == symbol_size
    Type(m) => m == n
  }
}

///|
/// A signature of a function (upstream `Type.signature`).
pub(all) struct Signature {
  args : Array[Typ]
  rest : Typ?
  ret : Typ
} derive(Eq, Compare, Debug)

///|
pub fn Signature::new(args : Array[Typ], rest? : Typ, ret : Typ) -> Signature {
  { args, rest, ret, }
}

///|
pub impl Show for Signature with fn output(self, logger) {
  logger.write_char('(')
  for i, t in self.args {
    if i > 0 {
      logger.write_char(' ')
    }
    logger.write_string(show_typ(t))
  }
  if self.rest is Some(r) {
    logger.write_string("&rest \{show_typ(r)}")
  }
  logger.write_string(") => (\{show_typ(self.ret)})")
}

///|
fn show_typ(t : Typ) -> String {
  match t {
    Any => "any"
    Symbol => "sym"
    Name(s) => s
    Type(n) => n.to_string()
  }
}

///|
/// A variable occurrence (upstream `var = KB.Name.t term indexed`).
pub(all) struct LVar {
  name : @knowledge.Name
  typ : Typ
  id : Int32
} derive(Eq, Debug)

///|
pub impl Show for LVar with fn output(self, logger) {
  logger.write_string(self.name.show())
  match self.typ {
    Any => ()
    t => logger.write_string(":\{t}")
  }
}

///|
/// A word literal (upstream `word = Z.t term indexed`).
pub(all) struct LWord {
  value : @bigint.BigInt
  typ : Typ
  id : Int32
} derive(Eq, Debug)

///|
/// A symbol literal (upstream `sym = KB.Name.t indexed`).
pub(all) struct LSym {
  name : @knowledge.Name
  id : Int32
} derive(Eq, Debug)

///|
/// An element of a `msg` format string.
pub(all) enum Fmt {
  Lit(String)
  Pos(Int32)
} derive(Eq, Debug)

///|
/// A Lisp expression (upstream `ast = exp indexed`).
pub(all) struct Ast {
  data : Exp
  id : Int32
} derive(Eq, Debug)

///|
/// The expression language (upstream `Bap_primus_lisp_types.exp`).
pub(all) enum Exp {
  Int(LWord)
  Var(LVar)
  Sym(LSym)
  Ite(Ast, Ast, Ast)
  Let(LVar, Ast, Ast)
  App(Binding, Array[Ast])
  Seq(Array[Ast])
  Set(LVar, Ast)
  Rep(Ast, Ast)
  Msg(Array[Fmt], Array[Ast])
  Err(String)
} derive(Eq, Debug)

///|
/// The callee of an application.
pub(all) enum Binding {
  Dynamic(@knowledge.Name)
  Static(Array[LVar], Ast)
} derive(Eq, Debug)

///|
/// The unqualified name when the name is in `pkg`, otherwise the fully
/// qualified name.
fn show_name_in(name : @knowledge.Name, pkg : String) -> String {
  if name.pkg() == pkg {
    name.unqualified()
  } else {
    name.show()
  }
}

///|
/// Pretty-prints an expression (upstream `Program.Ast.pp`), names from
/// the package `pkg` are printed unqualified.
pub fn Ast::to_string_in(self : Ast, pkg~ : String = "user") -> String {
  let buf = StringBuilder()
  pp_ast(buf, pkg, self)
  buf.to_string()
}

///|
pub impl Show for Ast with fn output(self, logger) {
  logger.write_string(self.to_string_in())
}

///|
fn pp_var(buf : StringBuilder, pkg : String, v : LVar) -> Unit {
  buf.write_string(show_name_in(v.name, pkg))
  match v.typ {
    Any => ()
    t => buf.write_string(":\{t}")
  }
}

///|
fn concat_prog(xs : Array[Ast]) -> Array[Ast] {
  let out = []
  for x in xs {
    match x.data {
      Seq(ys) => out.append(concat_prog(ys))
      _ => out.push(x)
    }
  }
  out
}

///|
fn pp_exps(buf : StringBuilder, pkg : String, xs : Array[Ast]) -> Unit {
  for i, x in xs {
    if i > 0 {
      buf.write_char(' ')
    }
    pp_ast(buf, pkg, x)
  }
}

///|
fn pp_prog(buf : StringBuilder, pkg : String, x : Ast) -> Unit {
  match x.data {
    Seq(xs) => pp_exps(buf, pkg, concat_prog(xs))
    _ => pp_ast(buf, pkg, x)
  }
}

///|
fn pp_ast(buf : StringBuilder, pkg : String, x : Ast) -> Unit {
  match x.data {
    Int(w) => {
      buf.write_string(w.value.to_string())
      match w.typ {
        Any => ()
        t => buf.write_string(":\{t}")
      }
    }
    Sym(s) => buf.write_string(show_name_in(s.name, pkg))
    Var(v) => pp_var(buf, pkg, v)
    Ite(c, t, e) => {
      buf.write_string("(if ")
      pp_ast(buf, pkg, c)
      buf.write_char(' ')
      pp_ast(buf, pkg, t)
      buf.write_char(' ')
      pp_prog(buf, pkg, e)
      buf.write_char(')')
    }
    Let(v, e, b) => {
      buf.write_string("(let (")
      pp_var(buf, pkg, v)
      buf.write_char(' ')
      pp_ast(buf, pkg, e)
      buf.write_string(") ")
      pp_ast(buf, pkg, b)
      buf.write_char(')')
    }
    App(b, xs) => {
      buf.write_char('(')
      match b {
        Dynamic(n) => buf.write_string(show_name_in(n, pkg))
        Static(_) => buf.write_string("<lambda>")
      }
      if xs.length() > 0 {
        buf.write_char(' ')
        pp_exps(buf, pkg, xs)
      }
      buf.write_char(')')
    }
    Seq([]) => buf.write_string("()")
    Seq([x]) => pp_ast(buf, pkg, x)
    Seq(xs) => {
      buf.write_string("(prog ")
      pp_exps(buf, pkg, concat_prog(xs))
      buf.write_char(')')
    }
    Set(v, x) => {
      buf.write_string("(set ")
      pp_var(buf, pkg, v)
      buf.write_char(' ')
      pp_ast(buf, pkg, x)
      buf.write_char(')')
    }
    Rep(c, b) => {
      buf.write_string("(while ")
      pp_ast(buf, pkg, c)
      buf.write_char(' ')
      pp_prog(buf, pkg, b)
      buf.write_char(')')
    }
    Msg(fmt, es) => {
      buf.write_string("(msg \"")
      for f in fmt {
        match f {
          Lit(s) => buf.write_string(s)
          Pos(n) => buf.write_string("$\{n}")
        }
      }
      buf.write_char('"')
      if es.length() > 0 {
        buf.write_char(' ')
        pp_exps(buf, pkg, es)
      }
      buf.write_char(')')
    }
    Err(msg) => buf.write_string("(error \{msg})")
  }
}

// ---------------------------------------------------------------------------
// Literals

///|
/// Parses a small non-negative or negative integer in OCaml `int_of_string`
/// syntax (decimal, `0x`, `0o`, `0b`).
fn parse_small_int(s : String) -> Int32? {
  match parse_bigint(s) {
    Some(v) => if v.bit_length() < 31 { Some(v.to_int()) } else { None }
    None => None
  }
}

///|
fn digit_value(c : Char) -> Int32 {
  if c >= '0' && c <= '9' {
    c.to_int() - '0'.to_int()
  } else if c >= 'a' && c <= 'z' {
    c.to_int() - 'a'.to_int() + 10
  } else if c >= 'A' && c <= 'Z' {
    c.to_int() - 'A'.to_int() + 10
  } else {
    99
  }
}

///|
/// Parses an arbitrary-precision integer in the syntax of `Z.of_string`:
/// an optional sign, an optional radix prefix (`0x`, `0o`, `0b`), and the
/// digits (underscores are allowed between digits).
pub fn parse_bigint(s : String) -> @bigint.BigInt? {
  let chars = s.to_array()
  let n = chars.length()
  if n == 0 {
    return None
  }
  let mut i = 0
  let mut neg = false
  if chars[0] == '-' {
    neg = true
    i = 1
  } else if chars[0] == '+' {
    i = 1
  }
  let mut radix = 10
  if i + 1 < n && chars[i] == '0' {
    match chars[i + 1] {
      'x' | 'X' => {
        radix = 16
        i += 2
      }
      'o' | 'O' => {
        radix = 8
        i += 2
      }
      'b' | 'B' => {
        radix = 2
        i += 2
      }
      _ => ()
    }
  }
  if i >= n {
    return None
  }
  let big_radix = @bigint.BigInt::from_int(radix)
  let mut acc = @bigint.BigInt::from_int(0)
  let mut seen = false
  for j in i..<n {
    let c = chars[j]
    if c == '_' && seen {
      continue
    }
    let d = digit_value(c)
    if d >= radix {
      return None
    }
    acc = acc * big_radix + @bigint.BigInt::from_int(d)
    seen = true
  }
  if !seen {
    return None
  }
  Some(if neg { -acc } else { acc })
}

///|
/// Errors of the variable literal reader (upstream `Var.read_error`).
pub(all) enum VarReadError {
  VarEmpty
  NotAVar
  VarBadType
  VarBadFormat
} derive(Eq, Debug)

///|
/// Reads a variable literal `name[:type]` or `package:name:type`
/// (upstream `Bap_primus_lisp_var.read`).
pub fn read_var(
  pkg? : String,
  id : Int32,
  x : String,
) -> Result[LVar, VarReadError] {
  if x == "" {
    return Err(VarEmpty)
  }
  let c = x.get_char(0).unwrap()
  if (c >= '0' && c <= '9') || c == '\'' || c == '"' {
    return Err(NotAVar)
  }
  let parts = split_colons(x)
  match parts {
    [] => Err(VarEmpty)
    [_, _, _, _, ..] => Err(VarBadFormat)
    [pkg, name, sz] =>
      match Typ::read(sz) {
        None => Err(VarBadType)
        Some(typ) => Ok({ name: @knowledge.Name::create(name, pkg~), typ, id, })
      }
    [x] => Ok({ name: @knowledge.Name::read(x, pkg?), typ: Any, id, })
    [x, sz] =>
      match Typ::read(sz) {
        Some(typ) => Ok({ name: @knowledge.Name::read(x, pkg?), typ, id, })
        None =>
          Ok({ name: @knowledge.Name::read(x + ":" + sz, pkg?), typ: Any, id, })
      }
  }
}

///|
fn split_colons(x : String) -> Array[String] {
  x.split(":").map(s => s.to_owned()).collect()
}

///|
/// Errors of the word literal reader (upstream `Word.read_error`).
pub(all) enum WordReadError {
  WordEmpty
  NotAnInt
  Unclosed
  BadLiteral
  WordBadType
} derive(Eq, Debug)

///|
/// Reads a word literal: `42`, `-1`, `0x2a:8`, `?a` (upstream
/// `Bap_primus_lisp_word.read`).
pub fn read_word(id : Int32, x : String) -> Result[LWord, WordReadError] {
  if x == "" {
    return Err(WordEmpty)
  }
  let chars = x.to_array()
  if chars[0] == '?' {
    if chars.length() == 2 {
      return Ok({
        value: @bigint.BigInt::from_int(chars[1].to_int()),
        typ: Type(8),
        id,
      })
    } else {
      return Err(BadLiteral)
    }
  }
  let is_digit = (c : Char) => c >= '0' && c <= '9'
  if is_digit(chars[0]) ||
    (chars.length() > 1 && is_digit(chars[1]) && chars[0] == '-') {
    match split_colons(x) {
      [x] =>
        match parse_bigint(x.trim().to_owned()) {
          Some(value) => Ok({ value, typ: Any, id, })
          None => Err(BadLiteral)
        }
      [x, t] =>
        match parse_bigint(x.trim().to_owned()) {
          None => Err(BadLiteral)
          Some(value) =>
            match Typ::read(t) {
              None => Err(WordBadType)
              Some(typ) => Ok({ value, typ, id, })
            }
        }
      _ => Err(BadLiteral)
    }
  } else {
    Err(NotAnInt)
  }
}

///|
/// Converts an arbitrary-precision integer to a word of the given width
/// (upstream `Bitvec.(bigint x mod modulus width)`).
pub fn word_of_bigint(value : @bigint.BigInt, width : Int32) -> @types.Word {
  let w = if width <= 0 { 1 } else { width }
  let m = @bigint.BigInt::from_int(1) << w
  let mut r = value % m
  if r < @bigint.BigInt::from_int(0) {
    r = r + m
  }
  let hex = r.to_string(radix=16)
  @types.Word::from_hex(width=w, hex) catch {
    _ => try! @types.Word::zero(width=w)
  }
}
