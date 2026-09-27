///|
/// Byte-wise (OCaml `String.compare`) ordering of two strings.
///
/// OCaml strings are compared byte by byte. Ogre strings are stored as UTF-8
/// in BAP, and UTF-8 preserves the code-point order, so comparing Unicode
/// scalar values reproduces the upstream order. MoonBit's own
/// `String::compare` orders by length first and cannot be used here.
fn string_compare(a : String, b : String) -> Int {
  let ai = a.iter()
  let bi = b.iter()
  while true {
    match (ai.next(), bi.next()) {
      (None, None) => return 0
      (None, Some(_)) => return -1
      (Some(_), None) => return 1
      (Some(x), Some(y)) => if x < y { return -1 } else if x > y { return 1 }
    }
  }
  0
}

///|
fn sort_strings(names : Array[String]) -> Array[String] {
  names.sort_by(string_compare)
  names
}

///|
/// OCaml `String.escaped` (as used by `%S` and by sexplib) applied to the
/// UTF-8 encoding of `text`. The result is always printable ASCII.
fn ocaml_escaped(text : String) -> String {
  let bytes = @utf8.encode(text)
  let out = StringBuilder()
  for byte in bytes {
    let code = byte.to_int()
    match code {
      0x22 => out.write_string("\\\"")
      0x5c => out.write_string("\\\\")
      0x0a => out.write_string("\\n")
      0x09 => out.write_string("\\t")
      0x0d => out.write_string("\\r")
      0x08 => out.write_string("\\b")
      _ =>
        if code >= 0x20 && code <= 0x7e {
          out.write_char(code.unsafe_to_char())
        } else {
          out.write_char('\\')
          out.write_char((48 + code / 100).unsafe_to_char())
          out.write_char((48 + code / 10 % 10).unsafe_to_char())
          out.write_char((48 + code % 10).unsafe_to_char())
        }
    }
  }
  out.to_string()
}

///|
/// OCaml's `%S` conversion: a double-quoted, escaped string literal.
fn ocaml_quote(text : String) -> String {
  "\"" + ocaml_escaped(text) + "\""
}
