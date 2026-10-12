// The s-expression layer of the textual Ogre format: a reader following the
// sexplib lexer (comments, quoted strings and escapes) and the `pp_hum`
// printer used by upstream `Doc.pp`.

///|
priv enum Sexp {
  Atom(String)
  List(Array[Sexp])
}

///|
priv struct SexpReader {
  chars : Array[Char]
  mut pos : Int32
  mut line : Int32
  mut bol : Int32
}

///|
fn SexpReader::error(self : SexpReader, reason : String) -> OgreError {
  OgreError(
    "Sexplib.Parser: failed to parse line \{self.line} char \{self.pos - self.bol}: \{reason}",
  )
}

///|
fn SexpReader::peek(self : SexpReader, offset~ : Int32 = 0) -> Char? {
  let i = self.pos + offset
  if i < self.chars.length() {
    Some(self.chars[i])
  } else {
    None
  }
}

///|
fn SexpReader::advance(self : SexpReader) -> Unit {
  if self.chars[self.pos] == '\n' {
    self.line += 1
    self.bol = self.pos + 1
  }
  self.pos += 1
}

///|
fn is_blank(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\u{0C}' || c == '\n' || c == '\r'
}

///|
fn is_unquoted(c : Char) -> Bool {
  !(is_blank(c) || c == ';' || c == '(' || c == ')' || c == '"')
}

///|
fn SexpReader::skip_block_comment(self : SexpReader) -> Unit raise OgreError {
  // positioned right after the opening `#|`
  let mut depth = 1
  while depth > 0 {
    match self.peek() {
      None => raise self.error("unterminated block comment")
      Some('"') => {
        self.advance()
        ignore(self.read_quoted())
      }
      Some('#') if self.peek(offset=1) is Some('|') => {
        self.advance()
        self.advance()
        depth += 1
      }
      Some('|') if self.peek(offset=1) is Some('#') => {
        self.advance()
        self.advance()
        depth -= 1
      }
      Some(_) => self.advance()
    }
  }
}

///|
/// Skips whitespace and comments. Returns `true` when a `#;` sexp comment
/// marker was consumed.
fn SexpReader::skip_layout(self : SexpReader) -> Bool raise OgreError {
  while true {
    match self.peek() {
      Some(c) if is_blank(c) => self.advance()
      Some(';') =>
        while self.peek() is Some(c) && c != '\n' && c != '\r' {
          self.advance()
        }
      Some('#') =>
        match self.peek(offset=1) {
          Some('|') => {
            self.advance()
            self.advance()
            self.skip_block_comment()
          }
          Some(';') => {
            self.advance()
            self.advance()
            return true
          }
          _ => return false
        }
      _ => return false
    }
  }
  false
}

///|
fn hex_digit(c : Char) -> Int32? {
  let d = digit_value(c)
  if d < 16 {
    Some(d)
  } else {
    None
  }
}

///|
/// Reads the body of a quoted string, positioned right after the opening
/// quote. Escapes produce bytes; the result is decoded as UTF-8.
fn SexpReader::read_quoted(self : SexpReader) -> String raise OgreError {
  let buf = @buffer.Buffer()
  while true {
    match self.peek() {
      None => raise self.error("unterminated string")
      Some('"') => {
        self.advance()
        break
      }
      Some('\\') => {
        self.advance()
        match self.peek() {
          None => raise self.error("unterminated string")
          Some('\n') => {
            self.advance()
            while self.peek() is Some(' ' | '\t') {
              self.advance()
            }
          }
          Some('\r') if self.peek(offset=1) is Some('\n') => {
            self.advance()
            self.advance()
            while self.peek() is Some(' ' | '\t') {
              self.advance()
            }
          }
          Some(c) => {
            let simple : Byte? = match c {
              '\\' => Some(b'\\')
              '\'' => Some(b'\'')
              '"' => Some(b'"')
              'n' => Some(b'\n')
              't' => Some(b'\t')
              'b' => Some(b'\x08')
              'r' => Some(b'\r')
              ' ' => Some(b' ')
              _ => None
            }
            match simple {
              Some(byte) => {
                buf.write_byte(byte)
                self.advance()
              }
              None =>
                match (c, self.peek(offset=1), self.peek(offset=2)) {
                  ('0'..<='9', Some('0'..<='9' as c2), Some('0'..<='9' as c3)) => {
                    let value = digit_value(c) * 100 +
                      digit_value(c2) * 10 +
                      digit_value(c3)
                    if value > 255 {
                      raise self.error("illegal escape")
                    }
                    buf.write_byte(value.to_byte())
                    self.advance()
                    self.advance()
                    self.advance()
                  }
                  ('x', Some(h1), Some(h2)) if hex_digit(h1) is Some(d1) &&
                    hex_digit(h2) is Some(d2) => {
                    buf.write_byte((d1 * 16 + d2).to_byte())
                    self.advance()
                    self.advance()
                    self.advance()
                  }
                  _ => {
                    buf.write_byte(b'\\')
                    buf.write_char_utf8(c)
                    self.advance()
                  }
                }
            }
          }
        }
      }
      Some(c) => {
        buf.write_char_utf8(c)
        self.advance()
      }
    }
  }
  @utf8.decode_lossy(buf.to_bytes())
}

///|
fn SexpReader::read_atom(self : SexpReader) -> String raise OgreError {
  let start = self.pos
  while self.peek() is Some(c) && is_unquoted(c) {
    self.advance()
  }
  let text = String::from_array(self.chars[start:self.pos])
  if text.has_prefix("|#") {
    raise self.error("illegal end of comment")
  }
  if text.contains("#|") || text.contains("|#") {
    raise self.error("comment tokens in unquoted atom")
  }
  text
}

///|
/// Reads the next s-expression, or `None` at a closing parenthesis or the
/// end of input.
fn SexpReader::read(self : SexpReader) -> Sexp? raise OgreError {
  while self.skip_layout() {
    // `#;` comments out the following s-expression
    match self.read() {
      Some(_) => ()
      None => raise self.error("sexp comment without an s-expression")
    }
  }
  match self.peek() {
    None | Some(')') => None
    Some('(') => {
      self.advance()
      let items = []
      while self.read() is Some(item) {
        items.push(item)
      }
      match self.peek() {
        Some(')') => {
          self.advance()
          Some(List(items))
        }
        _ => raise self.error("unterminated list")
      }
    }
    Some('"') => {
      self.advance()
      Some(Atom(self.read_quoted()))
    }
    Some(_) => Some(Atom(self.read_atom()))
  }
}

///|
/// Parses a sequence of s-expressions (sexplib `scan_sexps`).
fn parse_sexps(text : String) -> Array[Sexp] raise OgreError {
  let reader : SexpReader = { chars: text.to_array(), pos: 0, line: 1, bol: 0, }
  let result = []
  while reader.read() is Some(sexp) {
    result.push(sexp)
  }
  if reader.peek() is Some(')') {
    raise reader.error("unexpected ')'")
  }
  result
}

///|
/// sexplib's `must_escape`, over the UTF-8 encoding of the atom.
fn must_escape(text : String) -> Bool {
  let bytes = @utf8.encode(text)
  let len = bytes.length()
  if len == 0 {
    return true
  }
  let mut ix = len - 1
  while true {
    let byte = bytes[ix]
    match byte {
      b'"' | b'(' | b')' | b';' | b'\\' => return true
      b'|' | b'#' => {
        if ix == 0 {
          return false
        }
        let partner = if byte == b'|' { b'#' } else { b'|' }
        if bytes[ix - 1] == partner {
          return true
        }
      }
      _ =>
        if byte <= b' ' || byte >= b'\x7f' {
          return true
        } else if ix == 0 {
          return false
        }
    }
    ix -= 1
  }
  false
}

///|
fn is_one_line(text : String) -> Bool {
  match text.find("\n") {
    None => true
    Some(index) => index + 1 == text.length()
  }
}

///|
fn esc_str(text : String) -> String {
  "\"" + ocaml_escaped(text) + "\""
}

///|
fn Formatter::pp_atom(self : Formatter, text : String) -> Unit {
  if !must_escape(text) {
    self.print_string(text)
  } else if is_one_line(text) {
    self.print_string(esc_str(text))
  } else {
    self.open_box(0)
    self.print_string(" \"")
    let lines = text.split("\n").map(line => line.to_owned()).collect()
    for i, line in lines {
      self.print_string(ocaml_escaped(line))
      if i + 1 < lines.length() {
        self.print_string("\\")
        self.force_newline()
        self.print_string("\\n")
      }
    }
    self.print_string("\"")
    self.close_box()
  }
}

///|
/// sexplib's `pp_hum_indent`.
fn Formatter::pp_sexp(self : Formatter, indent : Int32, sexp : Sexp) -> Unit {
  match sexp {
    Atom(text) => self.pp_atom(text)
    List([]) => self.print_string("()")
    List(items) => {
      self.open_box(indent)
      self.print_string("(")
      for i, item in items {
        if i > 0 {
          self.print_space()
        }
        self.pp_sexp(indent, item)
      }
      self.print_string(")")
      self.close_box()
    }
  }
}

///|
/// sexplib's `Sexp.to_string_hum ~indent`.
fn sexp_to_string_hum(sexp : Sexp, indent~ : Int32 = 1) -> String {
  match sexp {
    Atom(text) if is_one_line(text) =>
      if must_escape(text) {
        esc_str(text)
      } else {
        text
      }
    _ => {
      let fmt = Formatter::new()
      fmt.pp_sexp(indent, sexp)
      fmt.contents()
    }
  }
}
