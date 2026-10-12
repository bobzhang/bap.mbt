///|
/// A namespace scope of an open element: its raw qualified name and the
/// namespace bindings in effect inside it.
priv struct Scope {
  qname : String
  bindings : Map[String, String]
}

///|
/// A streaming XML input (`Xmlm.input`).
pub struct Input {
  priv chars : Array[Char]
  priv mut pos : Int32
  priv mut line : Int32
  priv mut col : Int32
  priv strip : Bool
  priv entity : (String) -> String?
  priv ns : (String) -> String?
  priv mut peeked : Signal?
  priv mut started : Bool
  priv mut root_seen : Bool
  priv mut finished : Bool
  priv mut pending_end : Bool
  priv scopes : Array[Scope]
  priv mut signal_pos : Pos
}

///|
/// Creates an input from the text of a document. `strip` removes the
/// insignificant white space from the character data; `entity` resolves
/// the entities other than the predefined ones; `ns` resolves the
/// namespace prefixes that are not declared in the document.
pub fn Input::from_string(
  text : StringView,
  strip~ : Bool = false,
  entity~ : (String) -> String? = _ => None,
  ns~ : (String) -> String? = _ => None,
) -> Input {
  let chars : Array[Char] = []
  let mut prev_cr = false
  for c in text {
    // normalize the line ends: \r\n and \r become \n
    if c == '\r' {
      chars.push('\n')
      prev_cr = true
    } else {
      if !(c == '\n' && prev_cr) {
        chars.push(c)
      }
      prev_cr = false
    }
  }
  // skip the byte order mark
  let start = if chars.length() > 0 && chars[0] == '\u{FEFF}' { 1 } else { 0 }
  {
    chars,
    pos: start,
    line: 1,
    col: 1,
    strip,
    entity,
    ns,
    peeked: None,
    started: false,
    root_seen: false,
    finished: false,
    pending_end: false,
    scopes: [],
    signal_pos: { line: 1, col: 1, },
  }
}

///|
/// Creates an input from UTF-8 encoded bytes.
pub fn Input::from_bytes(
  bytes : BytesView,
  strip~ : Bool = false,
  entity~ : (String) -> String? = _ => None,
  ns~ : (String) -> String? = _ => None,
) -> Input raise XmlError {
  let text = @utf8.decode(bytes) catch {
    _ => raise XmlError(pos={ line: 1, col: 1, }, "malformed UTF-8 input")
  }
  Input::from_string(text, strip~, entity~, ns~)
}

///|
/// The position of the last signal returned by `input` or `peek` (or of
/// the input if an error was detected).
pub fn Input::pos(self : Input) -> Pos {
  self.signal_pos
}

///|
fn Input::here(self : Input) -> Pos {
  { line: self.line, col: self.col, }
}

///|
fn Input::fail(self : Input, msg : String) -> XmlError {
  self.signal_pos = self.here()
  XmlError(pos=self.here(), msg)
}

///|
fn Input::at_end(self : Input) -> Bool {
  self.pos >= self.chars.length()
}

///|
fn Input::cur(self : Input) -> Char? {
  self.chars.get(self.pos)
}

///|
fn Input::advance(self : Input) -> Unit {
  if self.pos < self.chars.length() {
    if self.chars[self.pos] == '\n' {
      self.line += 1
      self.col = 1
    } else {
      self.col += 1
    }
    self.pos += 1
  }
}

///|
fn Input::next_char(self : Input) -> Char raise XmlError {
  match self.cur() {
    Some(c) => {
      self.advance()
      c
    }
    None => raise self.fail("unexpected end of input")
  }
}

///|
fn Input::looking_at(self : Input, s : String) -> Bool {
  let mut i = 0
  for c in s {
    match self.chars.get(self.pos + i) {
      Some(d) if d == c => i += 1
      _ => return false
    }
  }
  true
}

///|
fn Input::skip_string(self : Input, s : String) -> Unit {
  for _ in s {
    self.advance()
  }
}

///|
fn Input::expect(self : Input, s : String) -> Unit raise XmlError {
  if self.looking_at(s) {
    self.skip_string(s)
  } else {
    raise self.fail("expected `\{s}'")
  }
}

///|
fn is_space(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

///|
fn Input::skip_spaces(self : Input) -> Bool {
  let start = self.pos
  while self.cur() is Some(c) && is_space(c) {
    self.advance()
  }
  self.pos > start
}

///|
fn is_name_char(c : Char) -> Bool {
  !(is_space(c) ||
  c is ('<' | '>' | '/' | '=' | '"' | '\'' | '&' | ';' | '?' | '!' | '[' | ']'))
}

///|
fn is_name_start(c : Char) -> Bool {
  is_name_char(c) && !(c is ('-' | '.' | '0'..<='9'))
}

///|
fn Input::read_name(self : Input) -> String raise XmlError {
  match self.cur() {
    Some(c) if is_name_start(c) => ()
    _ => raise self.fail("expected a name")
  }
  let buf = StringBuilder()
  while self.cur() is Some(c) && is_name_char(c) {
    buf.write_char(c)
    self.advance()
  }
  buf.to_string()
}

///|
/// Skips everything up to and including `stop`.
fn Input::skip_until(
  self : Input,
  stop : String,
  what : String,
) -> Unit raise XmlError {
  while !self.looking_at(stop) {
    if self.at_end() {
      raise self.fail("unterminated \{what}")
    }
    self.advance()
  }
  self.skip_string(stop)
}

///|
fn Input::skip_comment(self : Input) -> Unit raise XmlError {
  self.expect("<!--")
  self.skip_until("-->", "comment")
}

///|
fn Input::skip_pi(self : Input) -> Unit raise XmlError {
  self.expect("<?")
  self.skip_until("?>", "processing instruction")
}

///|
/// Skips white space, comments and processing instructions.
fn Input::skip_misc(self : Input) -> Unit raise XmlError {
  for ;; {
    let _ = self.skip_spaces()
    if self.looking_at("<!--") {
      self.skip_comment()
    } else if self.looking_at("<?") {
      self.skip_pi()
    } else {
      break
    }
  }
}

///|
/// Reads the document type declaration verbatim (including the internal
/// subset).
fn Input::read_doctype(self : Input) -> String raise XmlError {
  let buf = StringBuilder()
  let mut depth = 0
  let mut quote : Char? = None
  for ;; {
    let c = self.next_char()
    buf.write_char(c)
    match quote {
      Some(q) => if c == q { quote = None }
      None =>
        match c {
          '"' | '\'' => quote = Some(c)
          '[' => depth += 1
          ']' => depth -= 1
          '>' if depth == 0 => break
          _ => ()
        }
    }
  }
  buf.to_string()
}

///|
fn char_of_code(code : Int32) -> Char? {
  if (code >= 0 && code < 0xD800) || (code > 0xDFFF && code <= 0x10FFFF) {
    Some(code.unsafe_to_char())
  } else {
    None
  }
}

///|
/// Reads an entity or character reference (after `&`) and returns its
/// replacement text.
fn Input::read_reference(self : Input) -> String raise XmlError {
  self.expect("&")
  if self.looking_at("#") {
    self.advance()
    let hex = self.looking_at("x")
    if hex {
      self.advance()
    }
    let mut code = 0
    let mut digits = 0
    while self.cur() is Some(c) && c != ';' {
      let d = match c {
        '0'..<='9' => c.to_int() - '0'.to_int()
        'a'..<='f' if hex => c.to_int() - 'a'.to_int() + 10
        'A'..<='F' if hex => c.to_int() - 'A'.to_int() + 10
        _ => raise self.fail("malformed character reference")
      }
      code = code * (if hex { 16 } else { 10 }) + d
      if code > 0x10FFFF {
        raise self.fail("character reference out of range")
      }
      digits += 1
      self.advance()
    }
    self.expect(";")
    if digits == 0 {
      raise self.fail("malformed character reference")
    }
    match char_of_code(code) {
      Some(c) => c.to_string()
      None => raise self.fail("illegal character reference")
    }
  } else {
    let name = self.read_name()
    self.expect(";")
    match name {
      "lt" => "<"
      "gt" => ">"
      "amp" => "&"
      "quot" => "\""
      "apos" => "'"
      _ =>
        match (self.entity)(name) {
          Some(text) => text
          None => raise self.fail("unknown entity `\{name}'")
        }
    }
  }
}

///|
fn Input::read_attr_value(self : Input) -> String raise XmlError {
  let quote = self.next_char()
  if quote != '"' && quote != '\'' {
    raise self.fail("expected a quoted attribute value")
  }
  let buf = StringBuilder()
  for ;; {
    match self.cur() {
      None => raise self.fail("unterminated attribute value")
      Some(c) if c == quote => {
        self.advance()
        break
      }
      Some('<') => raise self.fail("`<' in an attribute value")
      Some('&') => buf.write_string(self.read_reference())
      Some(c) => {
        buf.write_char(if is_space(c) { ' ' } else { c })
        self.advance()
      }
    }
  }
  buf.to_string()
}

///|
fn split_qname(qname : String) -> (String, String) {
  match qname.find(":") {
    Some(i) =>
      (
        qname.unsafe_substring(start=0, end=i),
        qname.unsafe_substring(start=i + 1, end=qname.length()),
      )
    None => ("", qname)
  }
}

///|
fn Input::resolve_prefix(
  self : Input,
  bindings : Map[String, String],
  prefix : String,
) -> String raise XmlError {
  match prefix {
    "xml" => ns_xml
    "xmlns" => ns_xmlns
    _ =>
      match bindings.get(prefix) {
        Some(uri) => uri
        None =>
          if prefix == "" {
            ""
          } else {
            match (self.ns)(prefix) {
              Some(uri) => uri
              None => raise self.fail("unknown namespace prefix `\{prefix}'")
            }
          }
      }
  }
}

///|
/// Reads a start tag (the input is at `<`).
fn Input::read_start_tag(self : Input) -> Signal raise XmlError {
  self.expect("<")
  let qname = self.read_name()
  let raw : Array[(String, String)] = []
  for ;; {
    let spaced = self.skip_spaces()
    match self.cur() {
      Some('>') => {
        self.advance()
        break
      }
      Some('/') => {
        self.advance()
        self.expect(">")
        self.pending_end = true
        break
      }
      None => raise self.fail("unterminated start tag")
      Some(_) => {
        if !spaced {
          raise self.fail("expected white space before an attribute")
        }
        let name = self.read_name()
        let _ = self.skip_spaces()
        self.expect("=")
        let _ = self.skip_spaces()
        let value = self.read_attr_value()
        if raw.iter().any(a => a.0 == name) {
          raise self.fail("duplicate attribute `\{name}'")
        }
        raw.push((name, value))
      }
    }
  }
  // namespace declarations
  let bindings = match self.scopes.last() {
    Some(s) => s.bindings.copy()
    None => Map([])
  }
  for a in raw {
    if a.0 == "xmlns" {
      bindings[""] = a.1
    } else if a.0.has_prefix("xmlns:") {
      bindings[a.0.unsafe_substring(start=6, end=a.0.length())] = a.1
    }
  }
  let (prefix, local_name) = split_qname(qname)
  let name = { uri: self.resolve_prefix(bindings, prefix), local_name, }
  let attrs : Array[Attribute] = []
  for a in raw {
    let aname = if a.0 == "xmlns" {
      { uri: ns_xmlns, local_name: "xmlns", }
    } else {
      let (p, l) = split_qname(a.0)
      if p == "" {
        { uri: "", local_name: l, }
      } else {
        { uri: self.resolve_prefix(bindings, p), local_name: l, }
      }
    }
    attrs.push({ name: aname, value: a.1, })
  }
  self.scopes.push({ qname, bindings, })
  self.root_seen = true
  ElStart({ name, attrs, })
}

///|
fn Input::close_element(self : Input) -> Signal raise XmlError {
  let _ = self.scopes.pop()
  if self.scopes.is_empty() {
    self.finished = true
    self.skip_misc()
    if !self.at_end() {
      raise self.fail("unexpected content after the root element")
    }
  }
  ElEnd
}

///|
fn Input::read_end_tag(self : Input) -> Signal raise XmlError {
  self.expect("</")
  let qname = self.read_name()
  let _ = self.skip_spaces()
  self.expect(">")
  match self.scopes.last() {
    Some(s) if s.qname == qname => ()
    Some(s) => raise self.fail("expected the end tag of `\{s.qname}'")
    None => raise self.fail("unexpected end tag")
  }
  self.close_element()
}

///|
fn strip_data(s : String) -> String {
  let buf = StringBuilder()
  let mut space = false
  for c in s {
    if is_space(c) {
      space = true
    } else {
      if space && buf.to_string() != "" {
        buf.write_char(' ')
      }
      space = false
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Reads the character data up to the next markup; `None` if there is no
/// (significant) data.
fn Input::read_data(self : Input) -> String? raise XmlError {
  let buf = StringBuilder()
  for ;; {
    match self.cur() {
      None => raise self.fail("unexpected end of input inside an element")
      Some('<') =>
        if self.looking_at("<!--") {
          self.skip_comment()
        } else if self.looking_at("<![CDATA[") {
          self.skip_string("<![CDATA[")
          while !self.looking_at("]]>") {
            buf.write_char(self.next_char())
          }
          self.skip_string("]]>")
        } else if self.looking_at("<?") {
          self.skip_pi()
        } else {
          break
        }
      Some('&') => buf.write_string(self.read_reference())
      Some(c) => {
        buf.write_char(c)
        self.advance()
      }
    }
  }
  let data = buf.to_string()
  let data = if self.strip { strip_data(data) } else { data }
  if data == "" {
    None
  } else {
    Some(data)
  }
}

///|
fn Input::read_signal(self : Input) -> Signal raise XmlError {
  if !self.started {
    self.started = true
    self.skip_misc()
    let dtd = if self.looking_at("<!DOCTYPE") {
      Some(self.read_doctype())
    } else {
      None
    }
    self.skip_misc()
    return Dtd(dtd)
  }
  if self.pending_end {
    self.pending_end = false
    return self.close_element()
  }
  if self.finished {
    raise self.fail("end of input")
  }
  if !self.root_seen {
    if self.looking_at("<") && !self.looking_at("</") {
      return self.read_start_tag()
    }
    raise self.fail("expected the root element")
  }
  let start = self.here()
  match self.read_data() {
    Some(data) => {
      self.signal_pos = start
      return Data(data)
    }
    None => ()
  }
  if self.looking_at("</") {
    self.read_end_tag()
  } else {
    self.read_start_tag()
  }
}

///|
/// Returns the next signal without consuming it.
pub fn Input::peek(self : Input) -> Signal raise XmlError {
  match self.peeked {
    Some(s) => s
    None => {
      self.signal_pos = self.here()
      let s = self.read_signal()
      self.peeked = Some(s)
      s
    }
  }
}

///|
/// Consumes and returns the next signal.
pub fn Input::input(self : Input) -> Signal raise XmlError {
  let s = self.peek()
  self.peeked = None
  s
}

///|
/// `true` if the whole document was read (the root element was closed and
/// no signal is pending).
pub fn Input::eoi(self : Input) -> Bool {
  self.started && self.finished && !self.pending_end && self.peeked is None
}
