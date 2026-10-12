///|
priv struct Reader {
  text : Array[Char]
  mut pos : Int32
  mut line : Int32
  mut bol : Int32
}

///|
fn Reader::new(text : String) -> Reader {
  { text: text.to_array(), pos: 0, line: 1, bol: 0, }
}

///|
fn Reader::peek(self : Reader) -> Char? {
  self.text.get(self.pos)
}

///|
fn Reader::at(self : Reader, offset : Int32) -> Char? {
  self.text.get(self.pos + offset)
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
fn Reader::fail(self : Reader, msg : String) -> ParseError {
  ParseError(line=self.line, column=self.pos - self.bol, msg)
}

///|
fn is_blank(c : Char) -> Bool {
  c is (' ' | '\t' | '\n' | '\r' | '\u{0C}')
}

///|
/// Skips blanks and comments.
fn Reader::skip(self : Reader) -> Unit raise ParseError {
  while self.peek() is Some(c) {
    match c {
      _ if is_blank(c) => self.advance()
      ';' =>
        while self.peek() is Some(c) && c != '\n' {
          self.advance()
        }
      '#' if self.at(1) is Some('|') => {
        self.advance()
        self.advance()
        let mut depth = 1
        while depth > 0 {
          match (self.peek(), self.at(1)) {
            (None, _) => raise self.fail("unterminated block comment")
            (Some('|'), Some('#')) => {
              self.advance()
              self.advance()
              depth -= 1
            }
            (Some('#'), Some('|')) => {
              self.advance()
              self.advance()
              depth += 1
            }
            (Some(_), _) => self.advance()
          }
        }
      }
      '#' if self.at(1) is Some(';') => {
        self.advance()
        self.advance()
        ignore(self.read())
      }
      _ => return
    }
  }
}

///|
fn digit_value(c : Char) -> Int32? {
  match c {
    '0'..<='9' => Some(c.to_int() - '0'.to_int())
    _ => None
  }
}

///|
fn hex_value(c : Char) -> Int32? {
  match c {
    '0'..<='9' => Some(c.to_int() - '0'.to_int())
    'a'..<='f' => Some(c.to_int() - 'a'.to_int() + 10)
    'A'..<='F' => Some(c.to_int() - 'A'.to_int() + 10)
    _ => None
  }
}

///|
fn push_char(buf : Array[Byte], c : Char) -> Unit {
  let code = c.to_int()
  if code < 0x80 {
    buf.push(code.to_byte())
  } else {
    for b in @utf8.encode(c.to_string()) {
      buf.push(b)
    }
  }
}

///|
/// Reads a quoted atom; the current character is the opening quote.
fn Reader::quoted(self : Reader) -> String raise ParseError {
  self.advance()
  let buf : Array[Byte] = []
  while self.peek() is Some(c) {
    match c {
      '"' => {
        self.advance()
        return @utf8.decode_lossy(Bytes::from_array(buf))
      }
      '\\' => {
        guard self.at(1) is Some(e) else {
          raise self.fail("unterminated quoted string")
        }
        match e {
          '\\' | '\'' | '"' | ' ' => {
            push_char(buf, e)
            self.pos += 2
          }
          'n' => {
            buf.push(b'\n')
            self.pos += 2
          }
          't' => {
            buf.push(b'\t')
            self.pos += 2
          }
          'b' => {
            buf.push(b'\x08')
            self.pos += 2
          }
          'r' => {
            buf.push(b'\r')
            self.pos += 2
          }
          '\n' | '\r' => {
            // a line continuation: skip the newline and the leading blanks
            self.advance()
            if e == '\r' && self.at(1) is Some('\n') {
              self.pos += 1
            }
            self.advance()
            while self.peek() is Some(' ' | '\t') {
              self.advance()
            }
          }
          '0'..<='9' if self.at(2).bind(digit_value) is Some(d2) &&
            self.at(3).bind(digit_value) is Some(d3) => {
            let code = (e.to_int() - '0'.to_int()) * 100 + d2 * 10 + d3
            if code > 255 {
              raise self.fail("illegal escape sequence \\\{e}\{d2}\{d3}")
            }
            buf.push(code.to_byte())
            self.pos += 4
          }
          'x' if self.at(2).bind(hex_value) is Some(h1) &&
            self.at(3).bind(hex_value) is Some(h2) => {
            buf.push((h1 * 16 + h2).to_byte())
            self.pos += 4
          }
          _ => {
            // an unknown escape keeps its backslash
            buf.push(b'\\')
            self.pos += 1
          }
        }
      }
      _ => {
        push_char(buf, c)
        self.advance()
      }
    }
  }
  raise self.fail("unterminated quoted string")
}

///|
fn Reader::read(self : Reader) -> Sexp raise ParseError {
  self.skip()
  match self.peek() {
    None => raise self.fail("unexpected end of input")
    Some('(') => {
      self.advance()
      let items = []
      for ;; {
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
      let start = self.pos
      while self.peek() is Some(c) &&
            !is_blank(c) &&
            !(c is ('(' | ')' | '"' | ';')) {
        self.advance()
      }
      Atom(String::from_array(self.text[start:self.pos]))
    }
  }
}

///|
/// Parses exactly one s-expression (surrounded by optional blanks and
/// comments), like `Sexp.of_string`.
///
/// ```mbt check
/// test {
///   let sexp = @sexp.Sexp::of_string("(a \"b c\" ; comment\n (d))")
///   inspect(sexp, content="(a\"b c\"(d))")
///   let sexps = @sexp.Sexp::of_string_many("a (b) ; c")
///   inspect(sexps.length(), content="2")
/// }
/// ```
pub fn Sexp::of_string(text : String) -> Sexp raise ParseError {
  let reader = Reader::new(text)
  let sexp = reader.read()
  reader.skip()
  if reader.peek() is Some(_) {
    raise reader.fail("s-expression followed by data")
  }
  sexp
}

///|
/// Parses a sequence of s-expressions (`Sexp.of_string_many`, the
/// contents of a file read by `Sexp.load_sexps`).
pub fn Sexp::of_string_many(text : String) -> Array[Sexp] raise ParseError {
  let reader = Reader::new(text)
  let result = []
  reader.skip()
  while reader.peek() is Some(_) {
    result.push(reader.read())
    reader.skip()
  }
  result
}
