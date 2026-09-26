// A small s-expression reader with source positions (upstream uses
// `Sexplib.Sexp`), supporting `;` line comments, `#| |#` block comments,
// `#;` s-expression comments and quoted atoms.

///|
/// An s-expression.
pub(all) enum Sexp {
  Atom(String)
  List(Array[Sexp])
} derive(Eq, Debug)

///|
pub extend Sexp with Eq::{not_equal, equal}

///|
pub extend Sexp with Debug::{to_repr}

///|
fn atom_needs_quotes(s : String) -> Bool {
  s == "" ||
  s
  .to_array()
  .any(c => c is (' ' | '\t' | '\n' | '\r' | '(' | ')' | '"' | ';' | '\\'))
}

///|
fn quote_atom(s : String) -> String {
  let buf = StringBuilder()
  buf.write_char('"')
  for c in s {
    match c {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\t' => buf.write_string("\\t")
      '\r' => buf.write_string("\\r")
      c => buf.write_char(c)
    }
  }
  buf.write_char('"')
  buf.to_string()
}

///|
/// Renders the s-expression in the machine (single-line) format.
pub fn Sexp::to_string(self : Sexp) -> String {
  match self {
    Atom(s) => if atom_needs_quotes(s) { quote_atom(s) } else { s }
    List(items) => "(" + items.map(item => item.to_string()).join(" ") + ")"
  }
}

///|
/// A syntax error at the given line (1-based) and column (0-based).
priv suberror SexpSyntaxError {
  SexpSyntaxError(line~ : Int, column~ : Int, String)
}

///|
priv struct Reader {
  text : Array[Char]
  mut pos : Int
  mut line : Int
  mut bol : Int
}

///|
fn Reader::peek(self : Reader) -> Char? {
  self.text.get(self.pos)
}

///|
fn Reader::advance(self : Reader) -> Unit {
  if self.text[self.pos] == '\n' {
    self.line += 1
    self.bol = self.pos + 1
  }
  self.pos += 1
}

///|
fn Reader::fail(self : Reader, msg : String) -> SexpSyntaxError {
  SexpSyntaxError(line=self.line, column=self.pos - self.bol, msg)
}

///|
fn Reader::skip(self : Reader) -> Unit raise SexpSyntaxError {
  while self.peek() is Some(c) {
    match c {
      ' ' | '\t' | '\n' | '\r' | '\u{0C}' => self.advance()
      ';' =>
        while self.peek() is Some(c) && c != '\n' {
          self.advance()
        }
      '#' if self.text.get(self.pos + 1) is Some('|') => {
        self.advance()
        self.advance()
        let mut depth = 1
        while depth > 0 {
          match self.peek() {
            None => raise self.fail("unterminated block comment")
            Some('|') if self.text.get(self.pos + 1) is Some('#') => {
              self.advance()
              self.advance()
              depth -= 1
            }
            Some('#') if self.text.get(self.pos + 1) is Some('|') => {
              self.advance()
              self.advance()
              depth += 1
            }
            Some(_) => self.advance()
          }
        }
      }
      '#' if self.text.get(self.pos + 1) is Some(';') => {
        self.advance()
        self.advance()
        ignore(self.read())
      }
      _ => return
    }
  }
}

///|
fn Reader::quoted(self : Reader) -> String raise SexpSyntaxError {
  self.advance()
  let buf = StringBuilder()
  while self.peek() is Some(c) {
    self.advance()
    match c {
      '"' => return buf.to_string()
      '\\' => {
        guard self.peek() is Some(e) else {
          raise self.fail("unterminated quoted string")
        }
        self.advance()
        match e {
          'n' => buf.write_char('\n')
          't' => buf.write_char('\t')
          'r' => buf.write_char('\r')
          'b' => buf.write_char('\u{08}')
          '\n' =>
            while self.peek() is Some(' ' | '\t') {
              self.advance()
            }
          '0'..='9' => {
            let mut code = e.to_int() - '0'.to_int()
            for _ in 0..<2 {
              match self.peek() {
                Some('0'..='9' as d) => {
                  code = code * 10 + (d.to_int() - '0'.to_int())
                  self.advance()
                }
                _ => raise self.fail("invalid escape sequence")
              }
            }
            buf.write_char(code.unsafe_to_char())
          }
          other => buf.write_char(other)
        }
      }
      _ => buf.write_char(c)
    }
  }
  raise self.fail("unterminated quoted string")
}

///|
fn Reader::read(self : Reader) -> Sexp raise SexpSyntaxError {
  self.skip()
  match self.peek() {
    None => raise self.fail("unexpected end of input")
    Some('(') => {
      self.advance()
      let items = []
      while true {
        self.skip()
        match self.peek() {
          None => raise self.fail("unclosed parentheses at end of input")
          Some(')') => {
            self.advance()
            break
          }
          Some(_) => items.push(self.read())
        }
      }
      List(items)
    }
    Some(')') => raise self.fail("unexpected character: ')'")
    Some('"') => Atom(self.quoted())
    Some(_) => {
      let buf = StringBuilder()
      while self.peek() is Some(c) {
        if c is (' ' | '\t' | '\n' | '\r' | '\u{0C}' | '(' | ')' | '"' | ';') {
          break
        }
        buf.write_char(c)
        self.advance()
      }
      Atom(buf.to_string())
    }
  }
}

///|
fn Reader::new(text : String) -> Reader {
  { text: text.to_array(), pos: 0, line: 1, bol: 0, }
}

///|
fn Reader::read_all(self : Reader) -> Array[Sexp] raise SexpSyntaxError {
  let result = []
  self.skip()
  while self.peek() is Some(_) {
    result.push(self.read())
    self.skip()
  }
  result
}

///|
fn sexp_of_string(text : String) -> Sexp raise SexpSyntaxError {
  let reader = Reader::new(text)
  let sexp = reader.read()
  reader.skip()
  if reader.peek() is Some(_) {
    raise reader.fail("s-expression followed by data")
  }
  sexp
}

///|
fn sexps_of_string(text : String) -> Array[Sexp] raise SexpSyntaxError {
  Reader::new(text).read_all()
}
