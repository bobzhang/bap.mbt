// A minimal s-expression reader for tag specifications (upstream uses
// `Sexplib.Sexp.of_string`).

///|
priv enum Sexp {
  Atom(String)
  List(Array[Sexp])
}

///|
priv suberror SexpError {
  SexpError(String)
}

///|
fn is_sexp_space(c : Char) -> Bool {
  c is (' ' | '\t' | '\n' | '\r' | '\u{0C}')
}

///|
priv struct SexpReader {
  text : Array[Char]
  mut pos : Int
}

///|
fn SexpReader::skip(self : SexpReader) -> Unit {
  while self.pos < self.text.length() {
    let c = self.text[self.pos]
    if is_sexp_space(c) {
      self.pos += 1
    } else if c == ';' {
      while self.pos < self.text.length() && self.text[self.pos] != '\n' {
        self.pos += 1
      }
    } else {
      break
    }
  }
}

///|
fn SexpReader::quoted(self : SexpReader) -> String raise SexpError {
  self.pos += 1
  let buf = StringBuilder()
  while self.pos < self.text.length() {
    let c = self.text[self.pos]
    self.pos += 1
    match c {
      '"' => return buf.to_string()
      '\\' => {
        guard self.pos < self.text.length() else {
          raise SexpError("unterminated escape")
        }
        let e = self.text[self.pos]
        self.pos += 1
        match e {
          'n' => buf.write_char('\n')
          't' => buf.write_char('\t')
          'r' => buf.write_char('\r')
          'b' => buf.write_char('\u{08}')
          '\n' =>
            while self.pos < self.text.length() &&
                  self.text[self.pos] is (' ' | '\t') {
              self.pos += 1
            }
          '0'..='9' if self.pos + 1 < self.text.length() => {
            let code = (e.to_int() - '0'.to_int()) * 100 +
              (self.text[self.pos].to_int() - '0'.to_int()) * 10 +
              (self.text[self.pos + 1].to_int() - '0'.to_int())
            self.pos += 2
            buf.write_char(code.unsafe_to_char())
          }
          other => buf.write_char(other)
        }
      }
      _ => buf.write_char(c)
    }
  }
  raise SexpError("unterminated quoted string")
}

///|
fn SexpReader::read(self : SexpReader) -> Sexp raise SexpError {
  self.skip()
  guard self.pos < self.text.length() else {
    raise SexpError("unexpected end of input")
  }
  match self.text[self.pos] {
    '(' => {
      self.pos += 1
      let items = []
      while true {
        self.skip()
        guard self.pos < self.text.length() else {
          raise SexpError("unclosed parentheses")
        }
        if self.text[self.pos] == ')' {
          self.pos += 1
          break
        }
        items.push(self.read())
      }
      List(items)
    }
    ')' => raise SexpError("unexpected character: ')'")
    '"' => Atom(self.quoted())
    _ => {
      let buf = StringBuilder()
      while self.pos < self.text.length() {
        let c = self.text[self.pos]
        if is_sexp_space(c) || c is ('(' | ')' | '"' | ';') {
          break
        }
        buf.write_char(c)
        self.pos += 1
      }
      Atom(buf.to_string())
    }
  }
}

///|
/// Parses exactly one s-expression.
fn Sexp::of_string(s : String) -> Sexp raise SexpError {
  let reader = { text: s.to_array(), pos: 0, }
  let sexp = reader.read()
  reader.skip()
  if reader.pos < reader.text.length() {
    raise SexpError("trailing garbage")
  }
  sexp
}
