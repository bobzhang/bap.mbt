///|
/// A minimal S-expression (`Sexplib.Sexp.t`).
pub(all) enum Sexp {
  Atom(String)
  List(Array[Sexp])
} derive(Eq, Debug)

///|
pub extend Sexp with Eq::{not_equal, equal}

///|
pub extend Sexp with Debug::{to_repr}

///|
priv suberror SexpError {
  SexpError(String)
}

///|
priv struct Reader {
  text : Array[Char]
  mut pos : Int
}

///|
fn Reader::peek(self : Reader) -> Char? {
  if self.pos < self.text.length() {
    Some(self.text[self.pos])
  } else {
    None
  }
}

///|
fn Reader::at(self : Reader, offset : Int) -> Char? {
  let i = self.pos + offset
  if i < self.text.length() {
    Some(self.text[i])
  } else {
    None
  }
}

///|
fn is_space(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\u{0C}'
}

///|
fn is_atom_char(c : Char) -> Bool {
  !is_space(c) && c != '(' && c != ')' && c != '"' && c != ';'
}

///|
/// Skips whitespace and comments (`; line`, `#| block |#`, and `#;` datum
/// comments).
fn Reader::skip(self : Reader) -> Unit raise SexpError {
  for ;; {
    match self.peek() {
      Some(c) if is_space(c) => self.pos += 1
      Some(';') =>
        while self.peek() is Some(c) && c != '\n' {
          self.pos += 1
        }
      Some('#') if self.at(1) is Some('|') => {
        self.pos += 2
        let mut depth = 1
        while depth > 0 {
          match (self.peek(), self.at(1)) {
            (Some('|'), Some('#')) => {
              depth -= 1
              self.pos += 2
            }
            (Some('#'), Some('|')) => {
              depth += 1
              self.pos += 2
            }
            (Some(_), _) => self.pos += 1
            (None, _) => raise SexpError("unterminated block comment")
          }
        }
      }
      Some('#') if self.at(1) is Some(';') => {
        self.pos += 2
        ignore(self.read())
      }
      _ => break
    }
  }
}

///|
fn Reader::read_string(self : Reader) -> String raise SexpError {
  // the opening quote was consumed
  let sb = StringBuilder()
  for ;; {
    match self.peek() {
      None => raise SexpError("unterminated string")
      Some('"') => {
        self.pos += 1
        break
      }
      Some('\\') => {
        self.pos += 1
        match self.peek() {
          Some('n') => sb.write_char('\n')
          Some('t') => sb.write_char('\t')
          Some('r') => sb.write_char('\r')
          Some('b') => sb.write_char('\b')
          Some('\n') =>
            // a line continuation skips the leading blanks of the next line
            while self.at(1) is Some(' ' | '\t') {
              self.pos += 1
            }
          Some(c) if c >= '0' && c <= '9' => {
            let mut code = 0
            for _ in 0..<3 {
              match self.peek() {
                Some(d) if d >= '0' && d <= '9' => {
                  code = code * 10 + (d.to_int() - '0'.to_int())
                  self.pos += 1
                }
                _ => raise SexpError("invalid decimal escape")
              }
            }
            sb.write_char(code.unsafe_to_char())
            continue
          }
          Some(c) => sb.write_char(c)
          None => raise SexpError("unterminated string")
        }
        self.pos += 1
      }
      Some(c) => {
        sb.write_char(c)
        self.pos += 1
      }
    }
  }
  sb.to_string()
}

///|
fn Reader::read(self : Reader) -> Sexp raise SexpError {
  self.skip()
  match self.peek() {
    None => raise SexpError("unexpected end of input")
    Some(')') => raise SexpError("unexpected closing parenthesis")
    Some('(') => {
      self.pos += 1
      let items = []
      for ;; {
        self.skip()
        match self.peek() {
          Some(')') => {
            self.pos += 1
            break
          }
          None => raise SexpError("unclosed parenthesis")
          _ => items.push(self.read())
        }
      }
      List(items)
    }
    Some('"') => {
      self.pos += 1
      Atom(self.read_string())
    }
    Some(_) => {
      let sb = StringBuilder()
      while self.peek() is Some(c) && is_atom_char(c) {
        sb.write_char(c)
        self.pos += 1
      }
      Atom(sb.to_string())
    }
  }
}

///|
/// Parses all S-expressions of a text (`Sexp.load_sexps`).
pub fn parse_sexps(text : String) -> Result[Array[Sexp], String] {
  let reader : Reader = { text: text.iter().collect(), pos: 0, }
  let result = []
  try {
    for ;; {
      reader.skip()
      if reader.peek() is None {
        break
      }
      result.push(reader.read())
    }
  } catch {
    SexpError(msg) => return Err(msg)
  }
  Ok(result)
}
