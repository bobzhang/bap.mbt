///|
/// Lexicographic (code-unit) order of strings, as OCaml's `compare`.
fn lexical_compare(a : String, b : String) -> Int32 {
  let n = @cmp.minimum(a.length(), b.length())
  for i in 0..<n {
    let c = a[i].to_int() - b[i].to_int()
    if c != 0 {
      return if c < 0 { -1 } else { 1 }
    }
  }
  a.length().compare(b.length())
}

///|
/// OCaml's `String.escaped`.
fn ocaml_escaped(s : String) -> String {
  let buf = StringBuilder()
  for i in 0..<s.length() {
    let c = s[i].to_int()
    match c {
      0x22 => buf.write_string("\\\"")
      0x5c => buf.write_string("\\\\")
      0x0a => buf.write_string("\\n")
      0x09 => buf.write_string("\\t")
      0x0d => buf.write_string("\\r")
      0x08 => buf.write_string("\\b")
      _ =>
        if c >= 0x20 && c <= 0x7e {
          buf.write_char(c.unsafe_to_char())
        } else {
          let d = c & 0xff
          buf.write_char('\\')
          buf.write_char((0x30 + d / 100).unsafe_to_char())
          buf.write_char((0x30 + d / 10 % 10).unsafe_to_char())
          buf.write_char((0x30 + d % 10).unsafe_to_char())
        }
    }
  }
  buf.to_string()
}

///|
/// The directory part of a path (`FilePath.dirname`).
fn dirname(path : String) -> String {
  match path.rev_find("/") {
    Some(0) => "/"
    Some(i) => path.unsafe_substring(start=0, end=i)
    None => "."
  }
}

///|
/// The last component of a path.
fn basename(path : String) -> String {
  match path.rev_find("/") {
    Some(i) => path.unsafe_substring(start=i + 1, end=path.length())
    None => path
  }
}

///|
/// `Filename.concat`.
fn concat_path(dir : String, file : String) -> String {
  if dir == "" || dir.has_suffix("/") {
    dir + file
  } else {
    dir + "/" + file
  }
}
