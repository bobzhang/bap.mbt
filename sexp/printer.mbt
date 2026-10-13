///|
/// `true` if the atom must be quoted to be read back (sexplib
/// `must_escape`): it is empty, contains a character that delimits atoms,
/// a backslash, a control or non-ASCII character, or a `#|` / `|#`
/// comment delimiter.
pub fn must_escape(atom : String) -> Bool {
  if atom == "" {
    return true
  }
  let chars = atom.to_array()
  for i, c in chars {
    match c {
      '"' | '(' | ')' | ';' | '\\' => return true
      '|' if i > 0 && chars[i - 1] == '#' => return true
      '#' if i > 0 && chars[i - 1] == '|' => return true
      _ if c.to_int() <= 32 || c.to_int() >= 127 => return true
      _ => ()
    }
  }
  false
}

///|
fn write_escaped_byte(buf : StringBuilder, b : Int32) -> Unit {
  match b {
    0x22 => buf.write_string("\\\"")
    0x5C => buf.write_string("\\\\")
    0x0A => buf.write_string("\\n")
    0x09 => buf.write_string("\\t")
    0x0D => buf.write_string("\\r")
    0x08 => buf.write_string("\\b")
    _ if b >= 32 && b <= 126 => buf.write_char(b.unsafe_to_char())
    _ => {
      buf.write_char('\\')
      buf.write_char(('0'.to_int() + b / 100).unsafe_to_char())
      buf.write_char(('0'.to_int() + b / 10 % 10).unsafe_to_char())
      buf.write_char(('0'.to_int() + b % 10).unsafe_to_char())
    }
  }
}

///|
/// The atom as sexplib prints it: verbatim, or quoted and escaped like
/// OCaml's `String.escaped` (non-ASCII characters are escaped as the
/// decimal codes of their UTF-8 bytes) if `must_escape(atom)`.
pub fn escape_atom(atom : String) -> String {
  if !must_escape(atom) {
    return atom
  }
  let buf = StringBuilder()
  buf.write_char('"')
  for c in atom {
    let code = c.to_int()
    if code < 0x80 {
      write_escaped_byte(buf, code)
    } else {
      for b in @utf8.encode(c.to_string()) {
        write_escaped_byte(buf, b.to_int())
      }
    }
  }
  buf.write_char('"')
  buf.to_string()
}

///|
/// Writes `sexp` in the machine format; returns `true` if it ended with
/// an unquoted atom (so that a following atom needs a separating space).
fn write_mach(buf : StringBuilder, sexp : Sexp, may_need_space : Bool) -> Bool {
  match sexp {
    Atom(s) => {
      let escaped = escape_atom(s)
      let plain = !must_escape(s)
      if may_need_space && plain {
        buf.write_char(' ')
      }
      buf.write_string(escaped)
      plain
    }
    List(items) => {
      buf.write_char('(')
      let mut need_space = false
      for item in items {
        need_space = write_mach(buf, item, need_space)
      }
      buf.write_char(')')
      false
    }
  }
}

///|
/// Renders the s-expression in sexplib's machine format
/// (`Sexp.to_string`).
///
/// ```mbt check
/// test {
///   let sexp : @sexp.Sexp = List([Atom("a"), Atom("b c"), List([]), Atom("d")])
///   inspect(sexp.to_string(), content="(a\"b c\"()d)")
/// }
/// ```
pub fn Sexp::to_string(self : Sexp) -> String {
  let buf = StringBuilder()
  ignore(write_mach(buf, self, false))
  buf.to_string()
}

///|
pub impl Show for Sexp with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub extend Sexp with Show::{output}
