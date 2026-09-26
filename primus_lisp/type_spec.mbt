// Textual type specifications of primitives (a notation for upstream
// `Lisp.Type.Spec`), used by plugins that describe their primitives with
// strings, e.g., `"(sym int int) -> sym"` or `"(all any) -> bool"`.

///|
fn spec_type(t : String, bits : Int) -> Typ? {
  match t {
    "any" => Some(Any)
    "sym" => Some(Symbol)
    "int" => Some(Type(bits))
    "bool" => Some(Type(1))
    "byte" => Some(Type(8))
    _ =>
      match parse_small_int(t) {
        Some(n) => Some(Type(n))
        None =>
          if t.length() > 0 && t.iter().all(c => c >= 'a' && c <= 'z') {
            Some(Name(t))
          } else {
            None
          }
      }
  }
}

///|
/// Parses a type specification of a primitive for a target with words of
/// `bits` bits. The syntax is `(<params>) -> <type>`, where the parameters
/// are a list of types optionally followed by `all <type>` (or `// all
/// <type>`) that describes the rest of the parameters; the types are
/// `any`, `sym`, `int` (a machine word), `bool`, `byte`, a number (a word
/// of that width), or a lowercase name (a type variable). Returns `None` if
/// the specification is malformed.
///
/// ```mbt check
/// test {
///   let s = @primus_lisp.parse_type_spec("(sym int // all byte) -> bool", 64)
///   inspect(s.unwrap(), content="(sym 64&rest 8) => (1)")
/// }
/// ```
pub fn parse_type_spec(spec : String, bits : Int) -> Signature? {
  let spec = spec.trim().to_owned()
  guard spec.find("->") is Some(i) else { return None }
  let lhs = spec.unsafe_substring(start=0, end=i).trim().to_owned()
  let rhs = spec
    .unsafe_substring(start=i + 2, end=spec.length())
    .trim()
    .to_owned()
  guard lhs.has_prefix("(") && lhs.has_suffix(")") else { return None }
  let inner = lhs.unsafe_substring(start=1, end=lhs.length() - 1)
  let words : Array[String] = inner
    .split(" ")
    .map(s => s.trim().to_owned())
    .filter(s => s != "" && s != "//")
    .collect()
  let args = []
  let mut rest = None
  let mut i = 0
  while i < words.length() {
    if words[i] == "all" {
      guard i + 1 < words.length() else { return None }
      guard spec_type(words[i + 1], bits) is Some(t) else { return None }
      rest = Some(t)
      i += 2
    } else {
      guard spec_type(words[i], bits) is Some(t) else { return None }
      args.push(t)
      i += 1
    }
  }
  guard spec_type(rhs, bits) is Some(ret) else { return None }
  Some({ args, rest, ret, })
}

///|
/// Defines a primitive implemented by a direct host function, with the
/// type signature given as a textual specification (see
/// `parse_type_spec`).
pub fn define_host_primitive(
  m : @primus.Machine,
  name : String,
  types~ : String,
  docs? : String = "",
  pkg? : String = "core",
  run : (@primus.Machine, Array[@primus.Value]) -> @primus.Value raise,
) -> Unit {
  let types = parse_type_spec(types, addr_width(m))
  define_primitive(
    m,
    name,
    types?,
    docs~,
    pkg~,
    Closure::sync((m, _, args) => run(m, args)),
  )
}
