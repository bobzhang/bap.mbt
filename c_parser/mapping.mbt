// The mapping from the C declarations to `@c` types: a port of upstream
// `plugins/frontc_parser/frontc_parser_main.ml` (which maps the FrontC
// AST to `Bap_c_type`).
//
// Upstream quirks that are preserved:
// - only declarations with exactly one declarator are recorded
//   (`int a, b;` and `typedef int a, b;` declare nothing);
// - structure, union, and enumeration tags are recorded only by
//   declarations without declarators (`struct s {...};`), and a reference
//   to an unknown tag is an empty compound that is resolved (one level
//   deep) against the tags once the whole file is processed;
// - an unknown type name is `void`; bit fields, old-style prototypes, and
//   builtin types (`__builtin_va_list`) are `void`;
// - `const`/`volatile` qualify basic types and pointers, and propagate
//   into structure fields, but not into arrays, unions, or functions;
// - array sizes and enumerator values are kept only when they are integer
//   literals, read with OCaml's `Int.of_string`/`Int64.of_string` (so
//   `010` is ten, and a literal with a suffix like `1U` has no value);
// - attributes of `void` are dropped;
// - `[u]int{8,16,32,64}_t` are predefined as the first unsigned (signed)
//   integer type of the data model with that size, in the order of
//   `C.Type.all_of_unsigned` (`all_of_signed`); as upstream, this makes
//   `uint8_t` a `_Bool`.
//
// Deviation: upstream fails on an array size literal that OCaml cannot
// read (e.g., `a[3U]`); here the size is unknown.

///|
fn int_type(size : IntSize, sign : Sign) -> @c.Basic {
  match (size, sign) {
    (NoSize, NoSign | Signed) => SInt
    (Short, NoSign | Signed) => SShort
    (Long, NoSign | Signed) => SLong
    (LongLong, NoSign | Signed) => SLongLong
    (NoSize, Unsigned) => UInt
    (Short, Unsigned) => UShort
    (Long, Unsigned) => ULong
    (LongLong, Unsigned) => ULongLong
  }
}

///|
fn char_type(sign : Sign) -> @c.Basic {
  match sign {
    NoSign => Char
    Signed => SChar
    Unsigned => UChar
  }
}

///|
let cv : @c.Qualifier[Unit] = { const_: false, volatile_: false, restrict: (), }

///|
let cvr : @c.Qualifier[Bool] = {
  const_: false,
  volatile_: false,
  restrict: false,
}

///|
fn basic(t : @c.Basic) -> @c.CType {
  Basic({ qualifier: cv, t, attrs: [], })
}

///|
fn pointer(t : @c.CType) -> @c.CType {
  Pointer({ qualifier: cvr, t, attrs: [], })
}

///|
fn restrict_pointer(t : @c.CType) -> @c.CType {
  Pointer({ qualifier: { ..cvr, restrict: true, }, t, attrs: [], })
}

///|
/// OCaml's `Int64.of_string`: an optional sign, then a decimal number or a
/// `0x`/`0o`/`0b`/`0u` prefixed one; underscores are allowed after the first
/// digit. Leading zeros do not denote octal.
fn ocaml_int_of_string(s : String) -> Int64? {
  let (negative, s) = if s.has_prefix("-") {
    (true, s.unsafe_substring(start=1, end=s.length()))
  } else if s.has_prefix("+") {
    (false, s.unsafe_substring(start=1, end=s.length()))
  } else {
    (false, s)
  }
  let prefix = if s.length() > 2 {
    s.unsafe_substring(start=0, end=2)
  } else {
    ""
  }
  let (base, digits) = match prefix {
    "0x" | "0X" => (16, s.unsafe_substring(start=2, end=s.length()))
    "0o" | "0O" => (8, s.unsafe_substring(start=2, end=s.length()))
    "0b" | "0B" => (2, s.unsafe_substring(start=2, end=s.length()))
    "0u" | "0U" => (10, s.unsafe_substring(start=2, end=s.length()))
    _ => (10, s)
  }
  if digits.is_empty() || digits.has_prefix("_") {
    return None
  }
  let mut v = 0UL
  for c in digits {
    if c == '_' {
      continue
    }
    let d = match hex_digit(c.to_int().to_uint16()) {
      Some(d) if d < base => d
      _ => return None
    }
    v = v * base.to_uint64() + d.to_uint64()
  }
  let v = v.reinterpret_as_int64()
  Some(if negative { -v } else { v })
}

///|
fn array_size(e : Expression) -> Int32? {
  match e {
    Literal(ConstInt(s)) => ocaml_int_of_string(s).map(v => v.to_int())
    _ => None
  }
}

///|
fn array(size : Int32?, t : @c.CType) -> @c.CType {
  Array({ qualifier: cvr, t: { element: t, size, }, attrs: [], })
}

///|
fn structure(name : String, fields : Array[(String, @c.CType)]) -> @c.CType {
  Structure({ qualifier: (), t: { name, fields, }, attrs: [], })
}

///|
fn union_(name : String, fields : Array[(String, @c.CType)]) -> @c.CType {
  Union({ qualifier: (), t: { name, fields, }, attrs: [], })
}

///|
fn enum_(_name : String, items : Array[(String, Int64?)]) -> @c.CType {
  basic(Enum(items))
}

///|
fn func(
  variadic : Bool,
  return_ : @c.CType,
  args : Array[(String, @c.CType)],
) -> @c.CType {
  let args = if args is [(_, Void)] { [] } else { args }
  Function({ qualifier: (), t: { return_, args, variadic, }, attrs: [], })
}

///|
fn gnu_attr(a : GnuAttr) -> @c.Attr? {
  match a {
    GnuCall(name, args) => Some({ name, args: gnu_attrs_args(args), })
    GnuId(name) => Some({ name, args: [], })
    GnuNone | GnuCst(_) | GnuExtension | GnuInline | GnuTypeArg => None
  }
}

///|
fn gnu_attrs_args(args : Array[GnuAttr]) -> Array[String] {
  args.filter_map(a => {
    match a {
      GnuId(s)
      | GnuCst(ConstInt(s) | ConstFloat(s) | ConstChar(s) | ConstString(s)) =>
        Some(s)
      _ => None
    }
  })
}

///|
fn gnu_attrs(attrs : Array[GnuAttr]) -> Array[@c.Attr] {
  attrs.filter_map(gnu_attr)
}

///|
fn with_attrs(attrs : Array[@c.Attr], t : @c.CType) -> @c.CType {
  if attrs.is_empty() {
    return t
  }
  match t {
    Void => Void
    Basic(s) => Basic({ ..s, attrs: s.attrs + attrs, })
    Pointer(s) => Pointer({ ..s, attrs: s.attrs + attrs, })
    Array(s) => Array({ ..s, attrs: s.attrs + attrs, })
    Structure(s) => Structure({ ..s, attrs: s.attrs + attrs, })
    Union(s) => Union({ ..s, attrs: s.attrs + attrs, })
    Function(s) => Function({ ..s, attrs: s.attrs + attrs, })
  }
}

///|
priv enum Qualify {
  QConst
  QVolatile
}

///|
fn qualify(q : Qualify, t : @c.CType) -> @c.CType {
  match t {
    Basic(s) => {
      let qualifier = match q {
        QConst => { ..s.qualifier, const_: true, }
        QVolatile => { ..s.qualifier, volatile_: true, }
      }
      Basic({ ..s, qualifier, })
    }
    Pointer(s) => {
      let qualifier = match q {
        QConst => { ..s.qualifier, const_: true, }
        QVolatile => { ..s.qualifier, volatile_: true, }
      }
      Pointer({ ..s, qualifier, })
    }
    Structure(s) =>
      Structure({
        ..s,
        t: { ..s.t, fields: s.t.fields.map(f => (f.0, qualify(q, f.1))), },
      })
    t => t
  }
}

///|
priv struct Env {
  /// declarations (FrontC `env`), in the order of their first definition
  env : Map[String, @c.CType]
  /// structure, union, and enumeration tags
  tags : Map[String, @c.CType]
}

///|
fn Env::gamma(self : Env, name : String) -> @c.CType {
  match self.env.get(name) {
    Some(t) => t
    None => Void
  }
}

///|
fn Env::lookup(self : Env, what : () -> @c.CType, name : String) -> @c.CType {
  match self.tags.get(name) {
    Some(t) => t
    None => what()
  }
}

///|
fn Env::ctype(self : Env, t : BaseType) -> @c.CType {
  match t {
    NoType | OldProto(_) | Bitfield(_) | BuiltinType(_) | Void => Void
    Bool => basic(Bool)
    Char(sign) => basic(char_type(sign))
    Int(size, sign) => basic(int_type(size, sign))
    Float(_) => basic(Float)
    Double(long) => basic(if long { LongDouble } else { Double })
    ComplexFloat => basic(CFloat)
    ComplexDouble => basic(CDouble)
    ComplexLongDouble => basic(CLongDouble)
    Ptr(t) => pointer(self.ctype(t))
    RestrictPtr(t) => restrict_pointer(self.ctype(t))
    Array(et, e) => array(array_size(e), self.ctype(et))
    Struct(n, []) => self.lookup(() => structure(n, []), n)
    Union(n, []) => self.lookup(() => union_(n, []), n)
    Enum(n, []) => self.lookup(() => enum_(n, []), n)
    Struct(n, fs) => structure(n, self.fields(name_groups(fs)))
    Union(n, fs) => union_(n, self.fields(name_groups(fs)))
    Proto(r, args, v) => func(v, self.ctype(r), self.fields(single_names(args)))
    NamedType(name) => self.gamma(name)
    Enum(name, fs) => enum_(name, enum_items(fs))
    Const(t) => qualify(QConst, self.ctype(t))
    Volatile(t) => qualify(QVolatile, self.ctype(t))
    GnuType(a, t) => with_attrs(gnu_attrs(a), self.ctype(t))
  }
}

///|
fn enum_items(items : Array[(String, Expression)]) -> Array[(String, Int64?)] {
  items.map(item => {
    match item.1 {
      Literal(ConstInt(x)) => (item.0, ocaml_int_of_string(x))
      _ => (item.0, None)
    }
  })
}

///|
fn name_groups(
  groups : Array[NameGroup],
) -> Array[(String, BaseType, Array[GnuAttr])] {
  let out = []
  for g in groups {
    for n in g.names {
      out.push((n.name, n.typ, n.attrs))
    }
  }
  out
}

///|
fn single_names(
  names : Array[SingleName],
) -> Array[(String, BaseType, Array[GnuAttr])] {
  names.map(n => (n.name.name, n.name.typ, n.name.attrs))
}

///|
fn Env::fields(
  self : Env,
  xs : Array[(String, BaseType, Array[GnuAttr])],
) -> Array[(String, @c.CType)] {
  xs.map(x => (x.0, with_attrs(gnu_attrs(x.2), self.ctype(x.1))))
}

///|
/// Resolves empty compounds (references to tags) against the tags.
priv struct Resolver {
  tags : Map[String, @c.CType]
}

///|
fn Resolver::resolve(self : Resolver, t : @c.Compound) -> @c.Compound {
  if !t.fields.is_empty() {
    return t
  }
  match self.tags.get(t.name) {
    Some(Structure(s)) | Some(Union(s)) => { ..s.t, name: t.name, }
    _ => t
  }
}

///|
impl @c.TypeMapper for Resolver with fn map_structure(self, t) {
  self.resolve(t)
}

///|
impl @c.TypeMapper for Resolver with fn map_union(self, t) {
  self.resolve(t)
}

///|
/// The name of an integer type definition, e.g., `uint32_t`.
fn int_typedef_name(bits : Int32, t : @c.Basic) -> String {
  let sign = if t.is_signed() { "" } else { "u" }
  "\{sign}int\{bits}_t"
}

///|
/// The predefined integer types of the data model (`[u]int{8,16,32,64}_t`).
pub fn predefined_types(size : &@c.Ruler) -> Array[(String, @c.CType)] {
  let out = []
  for sz in [@types.Size::R8, R16, R32, R64] {
    for types in [@c.Basic::all_unsigned(), @c.Basic::all_signed()] {
      match types.search_by(t => size.integer(t) == sz) {
        Some(i) => {
          let t = types[i]
          out.push((int_typedef_name(sz.in_bits(), t), basic(t)))
        }
        None => ()
      }
    }
  }
  out
}

///|
/// Maps parsed definitions to declarations (upstream `parse`), in the
/// order of their first definition. The predefined integer types come
/// first.
pub fn to_decls(
  size : &@c.Ruler,
  defs : Array[Definition],
) -> Array[(String, @c.CType)] {
  let env = { env: Map([]), tags: Map([]), }
  for p in predefined_types(size) {
    env.env[p.0] = p.1
  }
  let add = (name : String, t : BaseType, a : Array[GnuAttr]) => {
    env.env[name] = with_attrs(gnu_attrs(a), env.ctype(t))
  }
  for def in defs {
    match def {
      DecDef({ names: [n], .. })
      | FunDef({ name: n, .. })
      | TypeDef({ names: [n], .. }, _)
      | OnlyTypeDef({ names: [n], .. }) => add(n.name, n.typ, n.attrs)
      OnlyTypeDef({ typ, .. }) =>
        match tag_of(typ) {
          Some(n) => env.tags[n] = env.ctype(typ)
          None => ()
        }
      _ => ()
    }
  }
  let resolver : Resolver = { tags: env.tags, }
  env.env
  .iter()
  .map(entry => {
    let t = @c.TypeMapper::run(resolver, entry.1) catch { _ => entry.1 }
    (entry.0, t)
  })
  .collect()
}

///|
/// The tag of a structure, union, or enumeration type. Attributes are
/// looked through (`struct __attribute__((packed)) s {...};`).
fn tag_of(t : BaseType) -> String? {
  match t {
    Struct(n, _) | Union(n, _) | Enum(n, _) => Some(n)
    GnuType(_, t) => tag_of(t)
    _ => None
  }
}
