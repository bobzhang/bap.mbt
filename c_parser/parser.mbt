// A recursive-descent parser for C declarations.
//
// The parser understands the declarations that FrontC (the parser used by
// upstream BAP) accepts in header files: typedefs; struct, union, and enum
// definitions (with bit fields); variable and function declarations with
// pointers, arrays, function pointers, `const`/`volatile`/`restrict`
// qualifiers, and storage classes; prototypes (with `...`) and old-style
// identifier lists; GNU `__attribute__((...))` lists and `__asm__` labels;
// and function definitions, whose bodies are skipped. Initializers are
// skipped too, except that constant array sizes and enumerator values are
// kept.

///|
priv struct Parser {
  toks : Array[Token]
  mut pos : Int32
  /// The names declared with `typedef` (FrontC `Clexer.add_type`).
  types : Map[String, Unit]
  eof : Token
}

///|
let type_keywords : Array[String] = [
  "void", "char", "short", "int", "long", "float", "double", "signed", "__signed",
  "__signed__", "unsigned", "_Bool", "_Complex", "__complex", "__complex__", "struct",
  "union", "enum", "typeof", "__typeof", "__typeof__",
]

///|
let qualifier_keywords : Array[String] = [
  "const", "__const", "__const__", "volatile", "__volatile", "__volatile__", "restrict",
  "__restrict", "__restrict__", "_Atomic",
]

///|
let storage_keywords : Array[String] = [
  "typedef", "extern", "static", "auto", "register", "inline", "__inline", "__inline__",
  "_Noreturn", "__thread", "_Thread_local", "__extension__",
]

///|
let attribute_keywords : Array[String] = ["__attribute__", "__attribute"]

///|
let asm_keywords : Array[String] = ["asm", "__asm", "__asm__"]

///|
/// Builtin type names (FrontC `BUILTIN_TYPE`).
let builtin_types : Array[String] = [
  "__builtin_va_list", "__int128", "__int128_t", "__uint128_t",
]

///|
fn Parser::peek(self : Parser) -> Token {
  match self.toks.get(self.pos) {
    Some(t) => t
    None => self.eof
  }
}

///|
fn Parser::peek_at(self : Parser, k : Int32) -> Token {
  match self.toks.get(self.pos + k) {
    Some(t) => t
    None => self.eof
  }
}

///|
fn Parser::at_eof(self : Parser) -> Bool {
  self.pos >= self.toks.length()
}

///|
fn Parser::is_punct(self : Parser, p : String) -> Bool {
  !self.at_eof() && self.peek().is_punct(p)
}

///|
fn Parser::is_ident_in(self : Parser, names : Array[String]) -> Bool {
  let t = self.peek()
  !self.at_eof() && t.kind is Ident && names.contains(t.text)
}

///|
fn Parser::error(self : Parser, msg : String) -> ParseError {
  let t = self.peek()
  if self.at_eof() {
    ParseError("\{t.loc()}: \{msg} at the end of input")
  } else {
    ParseError("\{t.loc()}: \{msg} before `\{t.text}`")
  }
}

///|
fn Parser::expect(self : Parser, p : String) -> Unit raise ParseError {
  if self.is_punct(p) {
    self.pos += 1
  } else {
    raise self.error("expected `\{p}`")
  }
}

///|
/// Whether `t` may start a declaration specifier (a type name, a keyword,
/// or an attribute).
fn Parser::starts_specifier(self : Parser, t : Token) -> Bool {
  t.kind is Ident &&
  (
    self.types.contains(t.text) ||
    type_keywords.contains(t.text) ||
    qualifier_keywords.contains(t.text) ||
    storage_keywords.contains(t.text) ||
    attribute_keywords.contains(t.text) ||
    builtin_types.contains(t.text)
  )
}

///|
fn is_keyword(name : String) -> Bool {
  type_keywords.contains(name) ||
  qualifier_keywords.contains(name) ||
  storage_keywords.contains(name) ||
  attribute_keywords.contains(name) ||
  asm_keywords.contains(name) ||
  name is ("sizeof" | "_Static_assert" | "static_assert")
}

///|
/// Parses a preprocessed token stream into a list of definitions. `types`
/// are the names that are already known to be type names.
pub fn parse_definitions(
  tokens : Array[Token],
  types~ : Array[String] = [],
) -> Array[Definition] raise ParseError {
  let eof = match tokens.last() {
    Some(t) => { ..t, kind: Other, text: "", }
    None =>
      {
        kind: Other,
        text: "",
        file: "<string>",
        line: 1,
        bol: true,
        space: false,
      }
  }
  let p = { toks: tokens, pos: 0, types: Map([]), eof, }
  for t in types {
    p.types[t] = ()
  }
  let defs = []
  while !p.at_eof() {
    if p.is_punct(";") {
      p.pos += 1
    } else if p.is_ident_in(["__extension__"]) {
      p.pos += 1
    } else if p.is_ident_in(asm_keywords) {
      p.pos += 1
      p.skip_asm_body()
      p.expect(";")
    } else if p.is_ident_in(["_Static_assert", "static_assert"]) {
      p.pos += 1
      p.skip_balanced_until([";"]) |> ignore
      p.expect(";")
    } else {
      defs.push(p.external_declaration())
    }
  }
  defs
}

///|
/// Skips `volatile`/`goto` qualifiers and the parenthesized body of an
/// `asm` statement or label.
fn Parser::skip_asm_body(self : Parser) -> Unit raise ParseError {
  while self.is_ident_in(qualifier_keywords + ["goto", "inline"]) {
    self.pos += 1
  }
  self.expect("(")
  self.skip_balanced_until([")"]) |> ignore
  self.expect(")")
}

///|
/// Skips tokens up to (not including) one of `stops` at the nesting level
/// zero. Returns the skipped tokens.
fn Parser::skip_balanced_until(
  self : Parser,
  stops : Array[String],
) -> Array[Token] raise ParseError {
  let skipped = []
  let mut depth = 0
  while !self.at_eof() {
    let t = self.peek()
    if t.kind is Punct {
      if depth == 0 && stops.contains(t.text) {
        return skipped
      }
      match t.text {
        "(" | "[" | "{" => depth += 1
        ")" | "]" | "}" => {
          if depth == 0 {
            raise self.error("unbalanced `\{t.text}`")
          }
          depth -= 1
        }
        _ => ()
      }
    }
    skipped.push(t)
    self.pos += 1
  }
  raise self.error("expected one of \{stops.join(" ")}")
}

///|
/// Classifies an expression: a (parenthesized) literal is a constant,
/// adjacent string literals are concatenated.
fn classify_expression(toks : Array[Token]) -> Expression {
  let mut view = toks[:]
  while view.length() >= 2 &&
        view[0].is_punct("(") &&
        view[view.length() - 1].is_punct(")") &&
        balanced_inner(view[1:view.length() - 1]) {
    view = view[1:view.length() - 1]
  }
  match view {
    [] => Nothing
    [{ kind: IntLit, text, .. }] => Literal(ConstInt(text))
    [{ kind: FloatLit, text, .. }] => Literal(ConstFloat(text))
    [{ kind: CharLit, text, .. }] => Literal(ConstChar(text))
    strings if strings.iter().all(t => t.kind is StrLit) =>
      Literal(ConstString(strings.iter().map(t => t.text).join("")))
    _ => Other
  }
}

///|
fn balanced_inner(toks : ArrayView[Token]) -> Bool {
  let mut depth = 0
  for t in toks {
    if t.is_punct("(") {
      depth += 1
    } else if t.is_punct(")") {
      if depth == 0 {
        return false
      }
      depth -= 1
    }
  }
  depth == 0
}

///|
fn Parser::expression(
  self : Parser,
  stops : Array[String],
) -> Expression raise ParseError {
  classify_expression(self.skip_balanced_until(stops))
}

// Attributes

///|
/// Parses a list of `__attribute__((...))` clauses (possibly empty).
fn Parser::attributes(self : Parser) -> Array[GnuAttr] raise ParseError {
  let attrs = []
  while self.is_ident_in(attribute_keywords) {
    self.pos += 1
    self.expect("(")
    self.expect("(")
    for ;; {
      if self.is_punct(")") {
        break
      }
      attrs.push(self.attribute())
      if self.is_punct(",") {
        self.pos += 1
      } else {
        break
      }
    }
    self.expect(")")
    self.expect(")")
  }
  attrs
}

///|
/// The name of an attribute. The `const` keyword (with its GNU spellings)
/// is the `const` attribute, as FrontC reads it as the `CONST` token.
fn attribute_name(name : String) -> String {
  match name {
    "__const" | "__const__" => "const"
    name => name
  }
}

///|
fn Parser::attribute(self : Parser) -> GnuAttr raise ParseError {
  if self.is_punct(",") || self.is_punct(")") {
    return GnuNone
  }
  let t = self.peek()
  guard t.kind is Ident else { raise self.error("expected an attribute") }
  self.pos += 1
  let name = attribute_name(t.text)
  if !self.is_punct("(") {
    return GnuId(name)
  }
  self.pos += 1
  let args = []
  for ;; {
    if self.is_punct(")") {
      break
    }
    args.push(self.attribute_arg())
    if self.is_punct(",") {
      self.pos += 1
    } else {
      break
    }
  }
  self.expect(")")
  GnuCall(name, args)
}

///|
fn Parser::attribute_arg(self : Parser) -> GnuAttr raise ParseError {
  let t = self.peek()
  if t.kind is Ident && self.peek_at(1).is_punct("(") {
    return self.attribute()
  }
  let toks = self.skip_balanced_until([",", ")"])
  match toks {
    [{ kind: Ident, text, .. }] => GnuId(attribute_name(text))
    _ =>
      match classify_expression(toks) {
        Literal(c) => GnuCst(c)
        Nothing => GnuNone
        Other => GnuTypeArg
      }
  }
}

// Declaration specifiers

///|
priv struct Specifiers {
  typ : BaseType
  storage : Storage
  is_typedef : Bool
}

///|
fn Parser::specifiers(self : Parser) -> Specifiers raise ParseError {
  let mut storage : Storage = NoStorage
  let mut is_typedef = false
  let mut is_const = false
  let mut is_volatile = false
  let attrs = []
  let mut n_void = 0
  let mut char = 0
  let mut short = 0
  let mut int = 0
  let mut long = 0
  let mut float = 0
  let mut double = 0
  let mut signed = 0
  let mut unsigned = 0
  let mut bool = 0
  let mut complex = 0
  let mut tagged : BaseType? = None
  let mut named : String? = None
  let mut builtin : String? = None
  let has_type = () => {
    n_void +
    char +
    short +
    int +
    long +
    float +
    double +
    signed +
    unsigned +
    bool +
    complex >
    0 ||
    tagged is Some(_) ||
    named is Some(_) ||
    builtin is Some(_)
  }
  while !self.at_eof() && self.peek().kind is Ident {
    let name = self.peek().text
    match name {
      "typedef" => is_typedef = true
      "extern" => storage = Extern
      "static" => storage = Static
      "auto" => storage = Auto
      "register" => storage = Register
      "inline"
      | "__inline"
      | "__inline__"
      | "_Noreturn"
      | "__thread"
      | "_Thread_local"
      | "__extension__"
      | "restrict"
      | "__restrict"
      | "__restrict__"
      | "_Atomic" => ()
      "const" | "__const" | "__const__" => is_const = true
      "volatile" | "__volatile" | "__volatile__" => is_volatile = true
      "__attribute__" | "__attribute" => {
        attrs.append(self.attributes())
        continue
      }
      "void" => n_void += 1
      "char" => char += 1
      "short" => short += 1
      "int" => int += 1
      "long" => long += 1
      "float" => float += 1
      "double" => double += 1
      "signed" | "__signed" | "__signed__" => signed += 1
      "unsigned" => unsigned += 1
      "_Bool" => bool += 1
      "_Complex" | "__complex" | "__complex__" => complex += 1
      "struct" | "union" => {
        if has_type() {
          raise self.error("two or more data types in declaration specifiers")
        }
        tagged = Some(self.compound_specifier(attrs))
        continue
      }
      "enum" => {
        if has_type() {
          raise self.error("two or more data types in declaration specifiers")
        }
        tagged = Some(self.enum_specifier(attrs))
        continue
      }
      "typeof" | "__typeof" | "__typeof__" => {
        self.pos += 1
        self.expect("(")
        self.skip_balanced_until([")"]) |> ignore
        self.expect(")")
        builtin = Some(name)
        continue
      }
      name if builtin_types.contains(name) && !has_type() =>
        builtin = Some(name)
      name if self.types.contains(name) && !has_type() => named = Some(name)
      _ => break
    }
    self.pos += 1
  }
  let typ : BaseType = if n_void > 0 {
    Void
  } else if bool > 0 {
    Bool
  } else if char > 0 {
    Char(sign_of(signed, unsigned))
  } else if float > 0 {
    if complex > 0 {
      ComplexFloat
    } else {
      Float(long > 0)
    }
  } else if double > 0 {
    if complex > 0 {
      if long > 0 {
        ComplexLongDouble
      } else {
        ComplexDouble
      }
    } else {
      Double(long > 0)
    }
  } else if complex > 0 {
    ComplexDouble
  } else if short + int + long + signed + unsigned > 0 {
    let size : IntSize = if short > 0 {
      Short
    } else if long == 1 {
      Long
    } else if long >= 2 {
      LongLong
    } else {
      NoSize
    }
    Int(size, sign_of(signed, unsigned))
  } else if tagged is Some(t) {
    t
  } else if named is Some(n) {
    NamedType(n)
  } else if builtin is Some(b) {
    BuiltinType(b)
  } else {
    NoType
  }
  let typ = if is_volatile { Volatile(typ) } else { typ }
  let typ = if is_const { Const(typ) } else { typ }
  let typ = if attrs.is_empty() { typ } else { GnuType(attrs, typ) }
  { typ, storage, is_typedef, }
}

///|
fn sign_of(signed : Int32, unsigned : Int32) -> Sign {
  if unsigned > 0 {
    Unsigned
  } else if signed > 0 {
    Signed
  } else {
    NoSign
  }
}

///|
/// Parses `struct`/`union` [attributes] [tag] [`{` fields `}`]; the
/// attributes are appended to `attrs`.
fn Parser::compound_specifier(
  self : Parser,
  attrs : Array[GnuAttr],
) -> BaseType raise ParseError {
  let is_struct = self.peek().text == "struct"
  self.pos += 1
  attrs.append(self.attributes())
  let name = if !self.at_eof() &&
    self.peek().kind is Ident &&
    !is_keyword(self.peek().text) {
    self.pos += 1
    self.toks[self.pos - 1].text
  } else {
    ""
  }
  attrs.append(self.attributes())
  let fields = if self.is_punct("{") {
    self.pos += 1
    let fields = self.struct_declarations()
    self.expect("}")
    fields
  } else if name == "" {
    raise self.error("expected a structure tag or `{`")
  } else {
    []
  }
  if is_struct {
    Struct(name, fields)
  } else {
    Union(name, fields)
  }
}

///|
fn Parser::struct_declarations(
  self : Parser,
) -> Array[NameGroup] raise ParseError {
  let groups = []
  while !self.is_punct("}") {
    if self.at_eof() {
      raise self.error("expected `}`")
    }
    if self.is_punct(";") || self.is_ident_in(["__extension__"]) {
      self.pos += 1
      continue
    }
    if self.is_ident_in(["_Static_assert", "static_assert"]) {
      self.pos += 1
      self.skip_balanced_until([";"]) |> ignore
      self.expect(";")
      continue
    }
    let spec = self.specifiers()
    if spec.typ is NoType && !self.is_punct(":") {
      raise self.error("expected a field declaration")
    }
    let names = []
    if !self.is_punct(";") {
      for ;; {
        let name = if self.is_punct(":") {
          { name: "", typ: spec.typ, attrs: [], init: Nothing, }
        } else {
          self.declarator(spec.typ)
        }
        let name = if self.is_punct(":") {
          self.pos += 1
          let width = self.expression([",", ";", "__attribute__"])
          let attrs = name.attrs + self.attributes()
          { ..name, typ: Bitfield(bitfield_sign(spec.typ), width), attrs, }
        } else {
          name
        }
        names.push(name)
        if self.is_punct(",") {
          self.pos += 1
        } else {
          break
        }
      }
    }
    self.expect(";")
    groups.push({ typ: spec.typ, storage: NoStorage, names, })
  }
  groups
}

///|
fn bitfield_sign(t : BaseType) -> Sign {
  match t {
    Int(_, s) | Char(s) => s
    Const(t) | Volatile(t) | GnuType(_, t) => bitfield_sign(t)
    _ => NoSign
  }
}

///|
fn Parser::enum_specifier(
  self : Parser,
  attrs : Array[GnuAttr],
) -> BaseType raise ParseError {
  self.pos += 1
  attrs.append(self.attributes())
  let name = if !self.at_eof() &&
    self.peek().kind is Ident &&
    !is_keyword(self.peek().text) {
    self.pos += 1
    self.toks[self.pos - 1].text
  } else {
    ""
  }
  attrs.append(self.attributes())
  if !self.is_punct("{") {
    if name == "" {
      raise self.error("expected an enumeration tag or `{`")
    }
    return Enum(name, [])
  }
  self.pos += 1
  let items = []
  while !self.is_punct("}") {
    let t = self.peek()
    guard !self.at_eof() && t.kind is Ident else {
      raise self.error("expected an enumerator")
    }
    self.pos += 1
    self.attributes() |> ignore
    let value = if self.is_punct("=") {
      self.pos += 1
      self.expression([",", "}"])
    } else {
      Nothing
    }
    items.push((t.text, value))
    if self.is_punct(",") {
      self.pos += 1
    } else {
      break
    }
  }
  self.expect("}")
  Enum(name, items)
}

// Declarators

///|
priv enum Suffix {
  ArraySuffix(Expression)
  ProtoSuffix(Array[SingleName], Bool)
  OldProtoSuffix(Array[String])
}

///|
priv struct PointerQuals {
  is_const : Bool
  is_volatile : Bool
  is_restrict : Bool
}

///|
/// Parses a (possibly abstract) declarator whose specifiers denote `base`.
fn Parser::declarator(self : Parser, base : BaseType) -> Name raise ParseError {
  let attrs = []
  let (name, build) = self.declarator_parts(attrs)
  self.trailing_attributes(attrs)
  { name, typ: build(base), attrs, init: Nothing, }
}

///|
/// Parses the attributes and `asm` labels that follow a declarator.
fn Parser::trailing_attributes(
  self : Parser,
  attrs : Array[GnuAttr],
) -> Unit raise ParseError {
  for ;; {
    if self.is_ident_in(attribute_keywords) {
      attrs.append(self.attributes())
    } else if self.is_ident_in(asm_keywords) {
      self.pos += 1
      self.skip_asm_body()
    } else {
      break
    }
  }
}

///|
fn Parser::declarator_parts(
  self : Parser,
  attrs : Array[GnuAttr],
) -> (String, (BaseType) -> BaseType) raise ParseError {
  let pointers : Array[PointerQuals] = []
  while self.is_punct("*") {
    self.pos += 1
    let mut is_const = false
    let mut is_volatile = false
    let mut is_restrict = false
    for ;; {
      if self.is_ident_in(["const", "__const", "__const__"]) {
        is_const = true
      } else if self.is_ident_in(["volatile", "__volatile", "__volatile__"]) {
        is_volatile = true
      } else if self.is_ident_in(["restrict", "__restrict", "__restrict__"]) {
        is_restrict = true
      } else if self.is_ident_in(["_Atomic"]) {
        ()
      } else if self.is_ident_in(attribute_keywords) {
        attrs.append(self.attributes())
        continue
      } else {
        break
      }
      self.pos += 1
    }
    pointers.push({ is_const, is_volatile, is_restrict, })
  }
  attrs.append(self.attributes())
  let t = self.peek()
  let mut name = ""
  let mut inner : (BaseType) -> BaseType = t => t
  if !self.at_eof() && t.kind is Ident && !is_keyword(t.text) {
    name = t.text
    self.pos += 1
  } else if self.is_punct("(") && self.is_nested_declarator(self.peek_at(1)) {
    self.pos += 1
    let (n, f) = self.declarator_parts(attrs)
    self.trailing_attributes(attrs)
    self.expect(")")
    name = n
    inner = f
  }
  let suffixes : Array[Suffix] = []
  for ;; {
    if self.is_punct("[") {
      self.pos += 1
      while self.is_ident_in(qualifier_keywords + ["static"]) {
        self.pos += 1
      }
      let size = self.expression(["]"])
      self.expect("]")
      suffixes.push(ArraySuffix(size))
    } else if self.is_punct("(") {
      self.pos += 1
      suffixes.push(self.parameters())
    } else {
      break
    }
  }
  let build = (base : BaseType) => {
    let mut t = base
    for p in pointers {
      t = if p.is_restrict { RestrictPtr(t) } else { Ptr(t) }
      if p.is_volatile {
        t = Volatile(t)
      }
      if p.is_const {
        t = Const(t)
      }
    }
    for i = suffixes.length() - 1; i >= 0; i = i - 1 {
      t = match suffixes[i] {
        ArraySuffix(size) => Array(t, size)
        ProtoSuffix(params, variadic) => Proto(t, params, variadic)
        OldProtoSuffix(names) => OldProto(t, names, false)
      }
    }
    inner(t)
  }
  (name, build)
}

///|
/// Whether the token after `(` starts a nested declarator rather than a
/// parameter list.
fn Parser::is_nested_declarator(self : Parser, t : Token) -> Bool {
  if t.kind is Punct {
    t.text is ("*" | "(" | "^")
  } else if t.kind is Ident {
    attribute_keywords.contains(t.text) ||
    (!self.starts_specifier(t) && !is_keyword(t.text))
  } else {
    false
  }
}

///|
/// Parses a parameter list; the `(` is already consumed.
fn Parser::parameters(self : Parser) -> Suffix raise ParseError {
  if self.is_punct(")") {
    self.pos += 1
    return ProtoSuffix([], false)
  }
  let t = self.peek()
  if t.kind is Ident && !self.starts_specifier(t) && !is_keyword(t.text) {
    // an identifier list of an old-style declaration
    let names = []
    for ;; {
      let t = self.peek()
      guard !self.at_eof() && t.kind is Ident else {
        raise self.error("expected a parameter name")
      }
      names.push(t.text)
      self.pos += 1
      if self.is_punct(",") {
        self.pos += 1
      } else {
        break
      }
    }
    self.expect(")")
    return OldProtoSuffix(names)
  }
  let params = []
  let mut variadic = false
  for ;; {
    if self.is_punct("...") {
      self.pos += 1
      variadic = true
      break
    }
    let spec = self.specifiers()
    if spec.typ is NoType && spec.storage is NoStorage {
      raise self.error("expected a parameter declaration")
    }
    let name = self.declarator(spec.typ)
    params.push({ typ: spec.typ, storage: spec.storage, name, })
    if self.is_punct(",") {
      self.pos += 1
    } else {
      break
    }
  }
  self.expect(")")
  ProtoSuffix(params, variadic)
}

///|
fn is_function_type(t : BaseType) -> Bool {
  t is (Proto(_) | OldProto(_))
}

///|
fn Parser::skip_initializer(self : Parser) -> Expression raise ParseError {
  if self.is_punct("=") {
    self.pos += 1
    self.expression([",", ";"])
  } else {
    Nothing
  }
}

///|
fn Parser::skip_function_body(self : Parser) -> Unit raise ParseError {
  self.expect("{")
  self.skip_balanced_until(["}"]) |> ignore
  self.expect("}")
}

///|
fn Parser::external_declaration(self : Parser) -> Definition raise ParseError {
  let start = self.pos
  let spec = self.specifiers()
  if self.is_punct(";") {
    self.pos += 1
    return OnlyTypeDef({ typ: spec.typ, storage: spec.storage, names: [], })
  }
  let first = self.declarator(spec.typ)
  if first.name == "" && self.pos == start {
    raise self.error("expected a declaration")
  }
  if is_function_type(first.typ) && !spec.is_typedef {
    if first.typ is OldProto(_) &&
      !(self.is_punct(";") || self.is_punct(",") || self.is_punct("=")) {
      // old-style parameter declarations
      self.skip_balanced_until(["{"]) |> ignore
    }
    if self.is_punct("{") {
      self.skip_function_body()
      return FunDef({ typ: spec.typ, storage: spec.storage, name: first, })
    }
  }
  let names = [{ ..first, init: self.skip_initializer(), }]
  while self.is_punct(",") {
    self.pos += 1
    let name = self.declarator(spec.typ)
    names.push({ ..name, init: self.skip_initializer(), })
  }
  self.expect(";")
  let group = { typ: spec.typ, storage: spec.storage, names, }
  if spec.is_typedef {
    for n in names {
      if n.name != "" {
        self.types[n.name] = ()
      }
    }
    TypeDef(group, [])
  } else {
    DecDef(group)
  }
}
