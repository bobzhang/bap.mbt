// Parsing the human-readable machine code (upstream `read_input` and
// `to_binary`).

///|
fn hex_value(c : Char) -> Int? {
  match c {
    '0'..='9' => Some(c.to_int() - '0'.to_int())
    'a'..='f' => Some(c.to_int() - 'a'.to_int() + 10)
    'A'..='F' => Some(c.to_int() - 'A'.to_int() + 10)
    _ => None
  }
}

///|
/// Interprets the escape sequences of an OCaml string literal body
/// (`Scanf.unescaped`): `\xHH`, `\DDD`, `\\`, `\n`, `\t`, `\r`, `\b`,
/// `\"`, `\'`, and `\ `; other characters stand for themselves.
fn unescape(s : String) -> Bytes raise McError {
  let chars = s.to_array()
  let out : Array[Byte] = []
  let n = chars.length()
  let mut i = 0
  while i < n {
    let c = chars[i]
    if c != '\\' {
      if c.to_int() > 0xff {
        raise McFail(BadUserInput)
      }
      out.push(c.to_int().to_byte())
      i += 1
      continue
    }
    if i + 1 >= n {
      raise McFail(BadUserInput)
    }
    match chars[i + 1] {
      'x' => {
        match
          (chars.get(i + 2).bind(hex_value), chars.get(i + 3).bind(hex_value)) {
          (Some(h), Some(l)) => out.push((h * 16 + l).to_byte())
          _ => raise McFail(BadUserInput)
        }
        i += 4
      }
      '0'..='9' => {
        let mut v = 0
        for k in 1..<=3 {
          match chars.get(i + k) {
            Some('0'..='9' as d) => v = v * 10 + (d.to_int() - '0'.to_int())
            _ => raise McFail(BadUserInput)
          }
        }
        if v > 255 {
          raise McFail(BadUserInput)
        }
        out.push(v.to_byte())
        i += 4
      }
      'n' => {
        out.push(b'\n')
        i += 2
      }
      't' => {
        out.push(b'\t')
        i += 2
      }
      'r' => {
        out.push(b'\r')
        i += 2
      }
      'b' => {
        out.push(b'\x08')
        i += 2
      }
      '\\' | '"' | '\'' | ' ' as e => {
        out.push(e.to_int().to_byte())
        i += 2
      }
      _ => raise McFail(BadUserInput)
    }
  }
  Bytes::from_array(out)
}

///|
/// Makes binary data from its ASCII representation (upstream
/// `to_binary`): the input is split on the separators (space, comma,
/// semicolon), or into pairs of characters if there are no separators,
/// `map` is applied to each piece, and the result is unescaped.
fn to_binary(
  s : String,
  map? : (String) -> String = x => x,
) -> Bytes raise McError {
  let is_sep = (c : Char) => c is (' ' | ',' | ';')
  let separated = s.iter().any(is_sep)
  let pieces : Array[String] = if separated {
    let parts = []
    let cur = StringBuilder()
    for c in s {
      if is_sep(c) {
        parts.push(cur.to_string())
        cur.reset()
      } else {
        cur.write_char(c)
      }
    }
    parts.push(cur.to_string())
    // repeated separators (e.g., double spaces) are ignored
    parts.filter(p => p != "")
  } else {
    let chars = s.to_array()
    [
      for n in 0..<(chars.length() / 2) => {
        String::from_array(chars[n * 2:n * 2 + 2])
      }
    ]
  }
  unescape(pieces.map(map).join(""))
}

///|
/// Parses the input of the `mc` command (upstream `read_input`): the
/// command-line arguments concatenated, or a line from `read_line` (the
/// standard input) when there are no arguments or the only argument is
/// `-`. Accepts `\x31\xd2`, `0x31 0xd2`, `31 d2`, and `31d2` forms.
pub fn read_input(
  input : Array[String],
  read_line? : () -> String? = () => None,
) -> Bytes raise McError {
  let input = match input {
    [] | ["-"] => read_line()
    s => Some(s.join(""))
  }
  match input {
    None => raise McFail(NoInput)
    Some(input) => {
      let input = input.trim_end(chars="\r\n").to_owned()
      if input.has_prefix("\\x") {
        to_binary(input)
      } else if input.has_prefix("0x") {
        to_binary(input, map=x => x.replace_all(old="0x", new="\\x"))
      } else if input == "" {
        raise McFail(NoInput)
      } else {
        to_binary(input, map=x => "\\x" + x)
      }
    }
  }
}
