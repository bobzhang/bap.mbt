// The C lexer: turns a (spliced) source text into preprocessing tokens.
//
// The lexer is deliberately lenient: characters that do not start a valid
// token and unterminated literals become `Other` tokens, so text in
// excluded conditional blocks (`#if 0`) never stops the preprocessor. Such
// tokens are rejected by the parser if they reach it.

///|
/// The kind of a preprocessing token.
pub(all) enum TokenKind {
  Ident
  IntLit
  FloatLit
  /// A character constant; the token text is the decoded contents.
  CharLit
  /// A string literal; the token text is the decoded contents.
  StrLit
  Punct
  /// A character sequence that is not a valid token.
  Other
} derive(Eq, Debug)

///|
pub extend TokenKind with Eq::{equal, not_equal}

///|
pub extend TokenKind with Debug::{to_repr}

///|
/// A preprocessing token.
pub(all) struct Token {
  kind : TokenKind
  /// The spelling (the decoded contents for character and string literals).
  text : String
  /// The file the token comes from.
  file : String
  /// The line of the token (1-based).
  line : Int
  /// Whether the token is the first one on its logical line.
  bol : Bool
  /// Whether the token is preceded by white space (or a comment).
  space : Bool
} derive(Eq, Debug)

///|
pub extend Token with Eq::{equal, not_equal}

///|
pub extend Token with Debug::{to_repr}

///|
fn Token::is_punct(self : Token, p : String) -> Bool {
  self.kind is Punct && self.text == p
}

///|
fn Token::is_ident(self : Token, name : String) -> Bool {
  self.kind is Ident && self.text == name
}

///|
fn Token::loc(self : Token) -> String {
  "\{self.file}:\{self.line}"
}

///|
/// Removes backslash-newline sequences (line continuations), keeping the
/// number of lines: the removed newlines are re-inserted after the logical
/// line, so that token lines stay close to the physical ones.
fn splice_lines(text : String) -> String {
  let out = StringBuilder()
  let mut pending = 0
  let n = text.length()
  let mut i = 0
  while i < n {
    let c = text.code_unit_at(i)
    if c == '\\' {
      // a backslash followed by optional spaces and a newline
      let mut j = i + 1
      while j < n &&
            (
              text.code_unit_at(j) == ' ' ||
              text.code_unit_at(j) == '\t' ||
              text.code_unit_at(j) == '\r'
            ) {
        j += 1
      }
      if j < n && text.code_unit_at(j) == '\n' {
        pending += 1
        i = j + 1
        continue
      }
    }
    if c == '\n' {
      out.write_char('\n')
      for _ in 0..<pending {
        out.write_char('\n')
      }
      pending = 0
    } else if c != '\r' {
      out.write_char(c.to_int().unsafe_to_char())
    }
    i += 1
  }
  out.to_string()
}

///|
let punctuators : Array[String] = [
  "...", "<<=", ">>=", "->", "++", "--", "<<", ">>", "<=", ">=", "==", "!=", "&&",
  "||", "*=", "/=", "%=", "+=", "-=", "&=", "^=", "|=", "##",
]

///|
fn is_ident_start(c : UInt16) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' || c == '$'
}

///|
fn is_ident_char(c : UInt16) -> Bool {
  is_ident_start(c) || (c >= '0' && c <= '9')
}

///|
fn is_digit(c : UInt16) -> Bool {
  c >= '0' && c <= '9'
}

///|
/// Decodes the escape sequences of a character or string literal body.
fn unescape(body : String) -> String {
  let out = StringBuilder()
  let n = body.length()
  let mut i = 0
  while i < n {
    let c = body.code_unit_at(i)
    if c != '\\' || i + 1 >= n {
      out.write_char(c.to_int().unsafe_to_char())
      i += 1
      continue
    }
    let e = body.code_unit_at(i + 1)
    i += 2
    match e {
      'n' => out.write_char('\n')
      't' => out.write_char('\t')
      'r' => out.write_char('\r')
      'a' => out.write_char('\u{07}')
      'b' => out.write_char('\u{08}')
      'f' => out.write_char('\u{0c}')
      'v' => out.write_char('\u{0b}')
      'x' => {
        let mut v = 0
        while i < n && hex_digit(body.code_unit_at(i)) is Some(d) {
          v = v * 16 + d
          i += 1
        }
        out.write_char((v % 0x110000).unsafe_to_char())
      }
      '0'..='7' => {
        let mut v = e.to_int() - '0'.to_int()
        let mut k = 1
        while k < 3 &&
              i < n &&
              body.code_unit_at(i) >= '0' &&
              body.code_unit_at(i) <= '7' {
          v = v * 8 + (body.code_unit_at(i).to_int() - '0'.to_int())
          i += 1
          k += 1
        }
        out.write_char(v.unsafe_to_char())
      }
      _ => out.write_char(e.to_int().unsafe_to_char())
    }
  }
  out.to_string()
}

///|
fn hex_digit(c : UInt16) -> Int? {
  if c >= '0' && c <= '9' {
    Some(c.to_int() - '0'.to_int())
  } else if c >= 'a' && c <= 'f' {
    Some(c.to_int() - 'a'.to_int() + 10)
  } else if c >= 'A' && c <= 'F' {
    Some(c.to_int() - 'A'.to_int() + 10)
  } else {
    None
  }
}

///|
/// Splits `text` (the contents of `file`) into preprocessing tokens.
/// Comments are removed, line continuations are spliced, and every token
/// records whether it starts a logical line.
pub fn tokenize(text : String, file? : String = "<string>") -> Array[Token] {
  let text = splice_lines(text)
  let tokens : Array[Token] = []
  let n = text.length()
  let mut i = 0
  let mut line = 1
  let mut bol = true
  let mut space = false
  let slice = (a : Int, b : Int) => text.unsafe_substring(start=a, end=b)
  let push = (kind : TokenKind, spelling : String, at_line : Int) => {
    tokens.push({ kind, text: spelling, file, line: at_line, bol, space, })
    bol = false
    space = false
  }
  while i < n {
    let c = text.code_unit_at(i)
    if c == '\n' {
      line += 1
      bol = true
      space = false
      i += 1
    } else if c == ' ' || c == '\t' || c == '\u{0c}' || c == '\u{0b}' {
      space = true
      i += 1
    } else if c == '/' && i + 1 < n && text.code_unit_at(i + 1) == '/' {
      while i < n && text.code_unit_at(i) != '\n' {
        i += 1
      }
      space = true
    } else if c == '/' && i + 1 < n && text.code_unit_at(i + 1) == '*' {
      i += 2
      while i < n &&
            !(text.code_unit_at(i) == '*' &&
            i + 1 < n &&
            text.code_unit_at(i + 1) == '/') {
        if text.code_unit_at(i) == '\n' {
          line += 1
        }
        i += 1
      }
      i = if i < n { i + 2 } else { n }
      space = true
    } else if is_ident_start(c) {
      // wide/unicode character and string prefixes
      let start = i
      while i < n && is_ident_char(text.code_unit_at(i)) {
        i += 1
      }
      let word = slice(start, i)
      if i < n &&
        (text.code_unit_at(i) == '"' || text.code_unit_at(i) == '\'') &&
        word is ("L" | "u" | "U" | "u8") {
        continue
      }
      push(Ident, word, line)
    } else if is_digit(c) ||
      (c == '.' && i + 1 < n && is_digit(text.code_unit_at(i + 1))) {
      let start = i
      let mut is_float = c == '.'
      let hex = c == '0' &&
        i + 1 < n &&
        (text.code_unit_at(i + 1) == 'x' || text.code_unit_at(i + 1) == 'X')
      i += 1
      while i < n {
        let d = text.code_unit_at(i)
        if (d == '+' || d == '-') &&
          (
            (text.code_unit_at(i - 1) is ('e' | 'E') && !hex) ||
            (text.code_unit_at(i - 1) is ('p' | 'P') && hex)
          ) {
          is_float = true
          i += 1
        } else if is_ident_char(d) || d == '.' {
          if d == '.' || (!hex && d is ('e' | 'E')) || (hex && d is ('p' | 'P')) {
            is_float = true
          }
          i += 1
        } else {
          break
        }
      }
      push(if is_float { FloatLit } else { IntLit }, slice(start, i), line)
    } else if c == '"' || c == '\'' {
      let start = i
      i += 1
      while i < n && text.code_unit_at(i) != c && text.code_unit_at(i) != '\n' {
        if text.code_unit_at(i) == '\\' && i + 1 < n {
          i += 1
        }
        i += 1
      }
      if i < n && text.code_unit_at(i) == c {
        let body = unescape(slice(start + 1, i))
        i += 1
        push(if c == '"' { StrLit } else { CharLit }, body, line)
      } else {
        push(Other, slice(start, i), line)
      }
    } else {
      let mut matched = false
      for p in punctuators {
        if i + p.length() <= n && slice(i, i + p.length()) == p {
          push(Punct, p, line)
          i += p.length()
          matched = true
          break
        }
      }
      if !matched {
        let s = slice(i, i + 1)
        let kind : TokenKind = if "{}[]()<>;:,.?!~+-*/%&|^=#".contains(s) {
          Punct
        } else {
          Other
        }
        push(kind, s, line)
        i += 1
      }
    }
  }
  tokens
}

///|
/// Renders tokens back to text (one logical line per source line), mostly
/// for debugging and testing the preprocessor.
pub fn tokens_to_string(tokens : ArrayView[Token]) -> String {
  let out = StringBuilder()
  for i, t in tokens {
    if i > 0 {
      if t.bol {
        out.write_char('\n')
      } else if t.space || needs_space(tokens[i - 1], t) {
        out.write_char(' ')
      }
    }
    match t.kind {
      StrLit => out.write_string(quote(t.text, '"'))
      CharLit => out.write_string(quote(t.text, '\''))
      _ => out.write_string(t.text)
    }
  }
  out.to_string()
}

///|
fn needs_space(prev : Token, next : Token) -> Bool {
  let word = (t : Token) => t.kind is (Ident | IntLit | FloatLit)
  word(prev) && word(next)
}

///|
fn quote(s : String, q : Char) -> String {
  let out = StringBuilder()
  out.write_char(q)
  for c in s {
    match c {
      '\n' => out.write_string("\\n")
      '\t' => out.write_string("\\t")
      '\\' => out.write_string("\\\\")
      c if c == q => {
        out.write_char('\\')
        out.write_char(c)
      }
      c => out.write_char(c)
    }
  }
  out.write_char(q)
  out.to_string()
}
