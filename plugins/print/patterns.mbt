///|
/// A property of an address that can be matched by a `--print-matching`
/// pattern (upstream `property`).
priv struct Property {
  name : String
  extract : (@project.Project, UInt64) -> String?
  explain : String
}

///|
fn find_symbol_name(project : @project.Project, addr : UInt64) -> String? {
  for symbol in project.symbols() {
    if symbol.contains(addr) {
      return Some(symbol.name())
    }
  }
  None
}

///|
fn find_section_name(project : @project.Project, addr : UInt64) -> String? {
  match project.image() {
    Some(image) =>
      match find_in_image_memory(image, addr, @image.section()) {
        Some(name) => return Some(name)
        None => ()
      }
    None => ()
  }
  memory_tag_value(project.memory(), addr, "section")
}

///|
fn find_segment_name(project : @project.Project, addr : UInt64) -> String? {
  match project.image() {
    Some(image) =>
      find_in_image_memory(image, addr, @image.segment()).map(seg => seg.name())
    None =>
      match memory_tag_value(project.memory(), addr, "segment") {
        Some(name) => Some(name)
        None =>
          // without an image, the memory map is tagged with segment names
          project
          .memory()
          .lookup(addr)
          .iter()
          .find_first(entry => !entry.1.contains("="))
          .map(entry => entry.1)
      }
  }
}

///|
/// The first image memory annotation of `tag` covering `addr` (upstream
/// `find_in_memory`).
fn[T] find_in_image_memory(
  image : @image.Image,
  addr : UInt64,
  tag : @types.Tag[T],
) -> T? {
  for entry in image.memory().lookup(addr) {
    match entry.1.get(tag) {
      Some(x) => return Some(x)
      None => ()
    }
  }
  None
}

///|
/// Looks for a memory annotation of the form `key=value` covering `addr`.
fn memory_tag_value(
  memory : @memory.MemMap[String],
  addr : UInt64,
  key : String,
) -> String? {
  let prefix = key + "="
  for entry in memory.lookup(addr) {
    if entry.1.has_prefix(prefix) {
      return Some(
        entry.1.unsafe_substring(start=prefix.length(), end=entry.1.length()),
      )
    }
  }
  None
}

///|
fn find_subroutine_name(project : @project.Project, addr : UInt64) -> String? {
  project.disassembly_symtab().find_by_start(addr).map(fn_ => fn_.name())
}

///|
let properties : Array[Property] = [
  {
    name: "symbol",
    extract: find_symbol_name,
    explain: "name of the enclosing symbol, where the symbol is looked up in the file symbol table or debuging information, if any",
  },
  {
    name: "section",
    extract: find_section_name,
    explain: "name of the enclosing section of the file",
  },
  {
    name: "segment",
    extract: find_segment_name,
    explain: "name of the enclosing segment of the file",
  },
  {
    name: "subroutine",
    extract: find_subroutine_name,
    explain: "name of the enclosing subroutine",
  },
]

///|
/// Descriptions of the properties that can be used in `--print-matching`
/// patterns, as `(name, explanation)` pairs.
pub fn property_descriptions() -> Array[(String, String)] {
  properties.map(p => (p.name, p.explain))
}

///|
/// A compiled `property:regexp` pattern.
struct Pattern {
  property : Property
  regex : @regex.Regex
}

///|
pub fn Pattern::property(self : Pattern) -> String {
  self.property.name
}

///|
pub fn Pattern::regexp(self : Pattern) -> String {
  self.regex.source()
}

///|
/// Compiles `--print-symbol`, `--print-section`, and `--print-matching`
/// options into patterns (upstream `compile_patterns`). Each of the
/// `symbols` is a shortcut for `symbol:<name>` and each of the `sections`
/// for `section:<name>`.
pub fn compile_patterns(
  symbols? : Array[String] = [],
  sections? : Array[String] = [],
  patterns? : Array[String] = [],
) -> Result[Array[Pattern], String] {
  let sources = []
  for s in symbols {
    sources.push("symbol:" + s)
  }
  for s in sections {
    sources.push("section:" + s)
  }
  sources.append(patterns)
  let result = []
  for pattern in sources {
    guard pattern.find(":") is Some(pos) else {
      return Err(
        "wrong pattern \{escape_ocaml_string(pattern)}, expected `:`, none found",
      )
    }
    let name = pattern.unsafe_substring(start=0, end=pos)
    let source = pattern.unsafe_substring(start=pos + 1, end=pattern.length())
    let regex = match @regex.Regex::compile(source) {
      Ok(regex) => regex
      Err(msg) =>
        return Err(
          "bad regular expression \{escape_ocaml_string(source)}: \{msg}",
        )
    }
    guard properties.search_by(p => p.name == name) is Some(i) else {
      return Err("unknown property \{escape_ocaml_string(name)}")
    }
    result.push({ property: properties[i], regex, })
  }
  Ok(result)
}

///|
/// [matches(patterns, project, addr)] is true if every pattern matches the
/// corresponding property of `addr` (upstream `matches`). A pattern never
/// matches an element without an address, so an empty pattern list
/// accepts everything.
pub fn matches(
  patterns : Array[Pattern],
  project : @project.Project,
  addr : UInt64?,
) -> Bool {
  patterns.all(p => {
    match addr {
      None => false
      Some(addr) =>
        match (p.property.extract)(project, addr) {
          None => false
          Some(value) => p.regex.execp(value)
        }
    }
  })
}

///|
/// Parses the textual value of an `address` term attribute, e.g.,
/// `0x400000:64u` or `4194304`.
fn parse_address_attr(text : String) -> UInt64? {
  let body = match text.find(":") {
    Some(i) => text.unsafe_substring(start=0, end=i)
    None => text
  }
  let (digits, radix) = if body.has_prefix("0x") || body.has_prefix("0X") {
    (body.unsafe_substring(start=2, end=body.length()), 16)
  } else {
    (body, 10)
  }
  if digits.length() == 0 {
    return None
  }
  let mut n : UInt64 = 0
  for c in digits {
    let d = match c {
      '0'..='9' => c.to_int() - '0'.to_int()
      'a'..='f' => c.to_int() - 'a'.to_int() + 10
      'A'..='F' => c.to_int() - 'A'.to_int() + 10
      _ => return None
    }
    if d >= radix {
      return None
    }
    n = n * radix.to_uint64() + d.to_uint64()
  }
  Some(n)
}

///|
fn[T] term_address(term : @types.Term[T]) -> UInt64? {
  match term.get_attr("address") {
    Some(text) => parse_address_attr(text)
    None => None
  }
}

///|
/// Restricts the project program to the subroutines whose address matches
/// the patterns (upstream `extract_program`).
pub fn extract_program(
  patterns : Array[Pattern],
  project : @project.Project,
) -> @types.Term[@types.Program] {
  project
  .program()
  .filter_subs(sub => matches(patterns, project, term_address(sub)))
}

///|
/// Renders a string as an OCaml `%S` literal.
fn escape_ocaml_string(s : String) -> String {
  let buf = StringBuilder()
  buf.write_char('"')
  for c in s {
    match c {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\t' => buf.write_string("\\t")
      '\r' => buf.write_string("\\r")
      _ =>
        if c.to_int() < 0x20 || c.to_int() == 0x7f {
          let code = c.to_int()
          buf.write_char('\\')
          buf.write_char(('0'.to_int() + code / 100).unsafe_to_char())
          buf.write_char(('0'.to_int() + code / 10 % 10).unsafe_to_char())
          buf.write_char(('0'.to_int() + code % 10).unsafe_to_char())
        } else {
          buf.write_char(c)
        }
    }
  }
  buf.write_char('"')
  buf.to_string()
}
