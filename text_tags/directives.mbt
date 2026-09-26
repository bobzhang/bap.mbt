///|
fn parse_int_prefix(s : String, start : Int) -> (Int?, Int) {
  let mut i = start
  while i < s.length() && s[i] == ' ' {
    i += 1
  }
  let mut neg = false
  if i < s.length() && s[i] == '-' {
    neg = true
    i += 1
  }
  let digits_start = i
  let mut n = 0
  while i < s.length() && s[i] >= '0' && s[i] <= '9' {
    n = n * 10 + (s[i].to_int() - '0'.to_int())
    i += 1
  }
  if i == digits_start {
    (None, start)
  } else {
    (Some(if neg { -n } else { n }), i)
  }
}

///|
/// The index of the first `>` at or after [start], or the length of [s].
fn index_from(s : String, start : Int) -> Int {
  for i in start..<s.length() {
    if s[i] == '>' {
      return i
    }
  }
  s.length()
}

///|
/// Parses the box specification of `@[<spec>` and opens the box.
fn Formatter::open_box_spec(self : Formatter, spec : String) -> Unit {
  let spec = spec.trim(chars=" ").to_owned()
  let mut kind_end = 0
  while kind_end < spec.length() &&
        spec[kind_end] >= 'a' &&
        spec[kind_end] <= 'z' {
    kind_end += 1
  }
  let kind = spec[:kind_end].to_owned()
  let indent = parse_int_prefix(spec, kind_end).0.unwrap_or(0)
  match kind {
    "v" => self.open_vbox(indent)
    "h" => self.open_hbox()
    "hv" => self.open_hvbox(indent)
    "hov" => self.open_hovbox(indent)
    _ => self.open_box(indent)
  }
}

///|
/// Interprets a `Format`-style format string without conversions.
///
/// The supported directives are `@[` (optionally followed by
/// `<v n>`, `<hov n>`, `<hv n>`, `<h>`, `<b n>` or `<n>`), `@]`, `@,`,
/// `@ ` (space), `@;` (optionally followed by `<width offset>`), `@.`
/// (newline and flush), `@\n` (forced newline), `@?` (flush),
/// `@{<tag>`, `@}` and `@@`. All other characters, including `%` and
/// literal newlines, are printed as is.
///
/// # Example
///
/// ```mbt check
/// test {
///   let fmt = @text_tags.Formatter::new()
///   fmt.print_format("@[<v 2>begin@,body@]@,end")
///   inspect(fmt.flush_str(), content="begin\n  body\nend")
/// }
/// ```
pub fn Formatter::print_format(self : Formatter, fmt : String) -> Unit {
  let text = StringBuilder()
  let flush_text = () => {
    let s = text.to_string()
    if s != "" {
      self.print_string(s)
      text.reset()
    }
  }
  let n = fmt.length()
  let mut i = 0
  while i < n {
    let c = fmt[i]
    if c != '@' || i + 1 >= n {
      text.write_char(fmt.get_char(i).unwrap_or('?'))
      i += fmt.get_char(i).map(c => c.utf16_len()).unwrap_or(1)
      continue
    }
    let d = fmt[i + 1]
    i += 2
    match d {
      '@' => text.write_char('@')
      '[' => {
        flush_text()
        if i < n && fmt[i] == '<' {
          let close = index_from(fmt, i)
          self.open_box_spec(fmt[i + 1:close].to_owned())
          i = if close < n { close + 1 } else { n }
        } else {
          self.open_box(0)
        }
      }
      ']' => {
        flush_text()
        self.close_box()
      }
      ',' => {
        flush_text()
        self.print_cut()
      }
      ' ' => {
        flush_text()
        self.print_space()
      }
      ';' => {
        flush_text()
        if i < n && fmt[i] == '<' {
          let close = index_from(fmt, i)
          let (width, next) = parse_int_prefix(fmt, i + 1)
          let (offset, _) = parse_int_prefix(fmt, next)
          self.print_break(width.unwrap_or(1), offset.unwrap_or(0))
          i = if close < n { close + 1 } else { n }
        } else {
          self.print_break(1, 0)
        }
      }
      '.' => {
        flush_text()
        self.print_newline()
      }
      '\n' => {
        flush_text()
        self.force_newline()
      }
      '?' => {
        flush_text()
        self.print_flush()
      }
      '{' => {
        flush_text()
        if i < n && fmt[i] == '<' {
          let close = index_from(fmt, i)
          self.open_tag(fmt[i + 1:close].to_owned())
          i = if close < n { close + 1 } else { n }
        } else {
          self.open_tag("")
        }
      }
      '}' => {
        flush_text()
        self.close_tag()
      }
      _ => {
        text.write_char('@')
        i -= 1
      }
    }
  }
  flush_text()
}
