///|
fn bare_parse_error(pos : Int, reason : String) -> BareError {
  BareParseError("invalid BARE specification at offset \{pos}: \{reason}")
}

///|
fn bare_skip_ws(text : String, pos : Ref[Int]) -> Unit {
  while pos.val < text.length() {
    match text.get_char(pos.val) {
      Some(c) if bare_is_space(c) => pos.val = pos.val + c.utf16_len()
      _ => return
    }
  }
}

///|
fn bare_parse_quoted(
  text : String,
  pos : Ref[Int],
) -> Result[String, BareError] {
  pos.val = pos.val + 1
  let builder = StringBuilder()
  while pos.val < text.length() {
    let c = match text.get_char(pos.val) {
      Some(c) => c
      None => return Err(bare_parse_error(pos.val, "invalid string offset"))
    }
    if c == '"' {
      pos.val = pos.val + 1
      return Ok(builder.to_string())
    } else if c == '\\' {
      pos.val = pos.val + 1
      if pos.val >= text.length() {
        return Err(bare_parse_error(pos.val, "unterminated escape sequence"))
      }
      let escaped = match text.get_char(pos.val) {
        Some(c) => c
        None => return Err(bare_parse_error(pos.val, "invalid escape offset"))
      }
      match escaped {
        '"' => builder.write_char('"')
        '\\' => builder.write_char('\\')
        'n' => builder.write_char('\n')
        'r' => builder.write_char('\r')
        't' => builder.write_char('\t')
        other => builder.write_char(other)
      }
      pos.val = pos.val + escaped.utf16_len()
    } else {
      builder.write_char(c)
      pos.val = pos.val + c.utf16_len()
    }
  }
  Err(bare_parse_error(pos.val, "unterminated string literal"))
}

///|
fn bare_parse_atom(text : String, pos : Ref[Int]) -> Result[String, BareError] {
  let start = pos.val
  while pos.val < text.length() {
    let c = match text.get_char(pos.val) {
      Some(c) => c
      None => return Err(bare_parse_error(pos.val, "invalid atom offset"))
    }
    if bare_is_space(c) || c == '(' || c == ')' {
      return Ok(text[start:pos.val].to_owned())
    }
    pos.val = pos.val + c.utf16_len()
  }
  if start == pos.val {
    Err(bare_parse_error(pos.val, "expected atom"))
  } else {
    Ok(text[start:pos.val].to_owned())
  }
}

///|
fn bare_parse_term(
  text : String,
  pos : Ref[Int],
) -> Result[BareTerm, BareError] {
  bare_skip_ws(text, pos)
  if pos.val >= text.length() {
    return Err(bare_parse_error(pos.val, "expected expression"))
  }
  match text.get_char(pos.val) {
    None => Err(bare_parse_error(pos.val, "invalid expression offset"))
    Some(c) =>
      match c {
        '(' => {
          pos.val = pos.val + 1
          let items = []
          while true {
            bare_skip_ws(text, pos)
            if pos.val >= text.length() {
              return Err(bare_parse_error(pos.val, "unterminated list"))
            }
            if text.get_char(pos.val) == Some(')') {
              pos.val = pos.val + 1
              return Ok(BareList(items))
            }
            match bare_parse_term(text, pos) {
              Ok(item) => items.push(item)
              Err(reason) => return Err(reason)
            }
          }
          Err(bare_parse_error(pos.val, "unreachable parser state"))
        }
        ')' => Err(bare_parse_error(pos.val, "unexpected ')'"))
        '"' =>
          match bare_parse_quoted(text, pos) {
            Ok(value) => Ok(BareAtom(value))
            Err(reason) => Err(reason)
          }
        _ =>
          match bare_parse_atom(text, pos) {
            Ok(value) => Ok(BareAtom(value))
            Err(reason) => Err(reason)
          }
      }
  }
}

///|
pub fn BareTerm::parse_many(
  text : String,
) -> Result[Array[BareTerm], BareError] {
  let pos : Ref[Int] = Ref(0)
  let terms = []
  while true {
    bare_skip_ws(text, pos)
    if pos.val >= text.length() {
      return Ok(terms)
    }
    match bare_parse_term(text, pos) {
      Ok(term) => terms.push(term)
      Err(reason) => return Err(reason)
    }
  }
  Ok(terms)
}

///|
pub fn BareTerm::parse(text : String) -> Result[BareTerm, BareError] {
  match BareTerm::parse_many(text) {
    Ok(terms) =>
      if terms.length() == 1 {
        Ok(terms[0])
      } else {
        Err(bare_parse_error(0, "expected exactly one expression"))
      }
    Err(reason) => Err(reason)
  }
}
