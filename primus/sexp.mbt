///|
/// A minimal S-expression, the MoonBit counterpart of `Sexp.t` used by
/// upstream Primus for inspecting observations, states and values, and for
/// the `defsystem` system-description language.
pub(all) enum Sexp {
  Atom(String)
  List(Array[Sexp])
} derive(Eq, Debug)

///|
fn sexp_needs_quotes(s : String) -> Bool {
  if s.is_empty() {
    return true
  }
  for c in s {
    match c {
      ' ' | '\t' | '\n' | '\r' | '(' | ')' | '"' | ';' => return true
      _ => ()
    }
  }
  false
}

///|
fn sexp_write(buf : StringBuilder, s : Sexp) -> Unit {
  match s {
    Atom(a) =>
      if sexp_needs_quotes(a) {
        buf.write_char('"')
        for c in a {
          match c {
            '"' => buf.write_string("\\\"")
            '\\' => buf.write_string("\\\\")
            '\n' => buf.write_string("\\n")
            _ => buf.write_char(c)
          }
        }
        buf.write_char('"')
      } else {
        buf.write_string(a)
      }
    List(xs) => {
      buf.write_char('(')
      for i, x in xs {
        if i > 0 {
          buf.write_char(' ')
        }
        sexp_write(buf, x)
      }
      buf.write_char(')')
    }
  }
}

///|
/// Renders the S-expression in the usual machine-readable syntax.
pub fn Sexp::to_string(self : Sexp) -> String {
  let buf = StringBuilder()
  sexp_write(buf, self)
  buf.to_string()
}

///|
pub impl Show for Sexp with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// Convenience constructor for a list of atoms.
pub fn Sexp::atoms(xs : Array[String]) -> Sexp {
  List(xs.map(x => Sexp::Atom(x)))
}

///|
/// Errors raised by the S-expression reader.
pub(all) suberror SexpParseError {
  UnexpectedEof
  UnexpectedChar(Char, Int)
  UnbalancedParen(Int)
} derive(Eq, Debug)

///|
priv struct SexpReader {
  chars : Array[Char]
  mut pos : Int
}

///|
fn SexpReader::skip_blanks(self : SexpReader) -> Unit {
  while self.pos < self.chars.length() {
    match self.chars[self.pos] {
      ' ' | '\t' | '\n' | '\r' => self.pos += 1
      ';' =>
        while self.pos < self.chars.length() && self.chars[self.pos] != '\n' {
          self.pos += 1
        }
      _ => break
    }
  }
}

///|
fn SexpReader::read(self : SexpReader) -> Sexp raise SexpParseError {
  self.skip_blanks()
  guard self.pos < self.chars.length() else { raise UnexpectedEof }
  match self.chars[self.pos] {
    '(' => {
      self.pos += 1
      let items = []
      while true {
        self.skip_blanks()
        guard self.pos < self.chars.length() else { raise UnexpectedEof }
        if self.chars[self.pos] == ')' {
          self.pos += 1
          break
        }
        items.push(self.read())
      }
      List(items)
    }
    ')' => raise UnbalancedParen(self.pos)
    '"' => {
      self.pos += 1
      let buf = StringBuilder()
      while true {
        guard self.pos < self.chars.length() else { raise UnexpectedEof }
        let c = self.chars[self.pos]
        self.pos += 1
        match c {
          '"' => break
          '\\' => {
            guard self.pos < self.chars.length() else { raise UnexpectedEof }
            let e = self.chars[self.pos]
            self.pos += 1
            match e {
              'n' => buf.write_char('\n')
              't' => buf.write_char('\t')
              _ => buf.write_char(e)
            }
          }
          _ => buf.write_char(c)
        }
      }
      Atom(buf.to_string())
    }
    _ => {
      let buf = StringBuilder()
      while self.pos < self.chars.length() {
        match self.chars[self.pos] {
          ' ' | '\t' | '\n' | '\r' | '(' | ')' | ';' => break
          c => {
            buf.write_char(c)
            self.pos += 1
          }
        }
      }
      Atom(buf.to_string())
    }
  }
}

///|
/// Parses a sequence of S-expressions (comments start with `;`).
pub fn Sexp::parse_many(text : String) -> Array[Sexp] raise SexpParseError {
  let reader = SexpReader::{ chars: text.to_array(), pos: 0, }
  let out = []
  while true {
    reader.skip_blanks()
    if reader.pos >= reader.chars.length() {
      break
    }
    out.push(reader.read())
  }
  out
}

///|
/// Parses a single S-expression.
pub fn Sexp::parse(text : String) -> Sexp raise SexpParseError {
  let reader = SexpReader::{ chars: text.to_array(), pos: 0, }
  let r = reader.read()
  reader.skip_blanks()
  if reader.pos < reader.chars.length() {
    raise UnexpectedChar(reader.chars[reader.pos], reader.pos)
  }
  r
}

///|
pub fn SexpParseError::to_string(self : SexpParseError) -> String {
  match self {
    UnexpectedEof => "unexpected end of input"
    UnexpectedChar(c, pos) => "unexpected character '\{c}' at \{pos}"
    UnbalancedParen(pos) => "unbalanced parenthesis at \{pos}"
  }
}
