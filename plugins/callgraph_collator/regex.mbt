// A small backtracking matcher for the PCRE subset accepted by the
// `--callgraph-ignore-matching` option (upstream uses `Re.Pcre`). It supports
// literals, `.`, character classes with ranges and negation, the escapes
// `\d \w \s \D \W \S \b \B \t \n \r` (other escaped characters are literal),
// anchors `^` and `$`, groups `( )` and `(?: )`, alternation `|`, and the
// quantifiers `* + ? {n} {n,} {n,m}` (optionally lazy).

///|
priv suberror RegexError {
  RegexError(String)
}

///|
priv enum ClassItem {
  Range(Char, Char)
  Digit(Bool)
  Word(Bool)
  Space(Bool)
}

///|
priv enum Node {
  Lit(Char)
  AnyChar
  Class(Array[ClassItem], Bool)
  Bol
  Eol
  WordBoundary(Bool)
  Group(Array[Array[Node]])
  Repeat(Node, Int, Int)
}

///|
/// A compiled regular expression.
pub struct Regex {
  priv alternatives : Array[Array[Node]]
}

///|
priv struct Parser {
  chars : Array[Char]
  mut pos : Int
}

///|
fn Parser::peek(self : Parser) -> Char? {
  if self.pos < self.chars.length() {
    Some(self.chars[self.pos])
  } else {
    None
  }
}

///|
fn Parser::next(self : Parser) -> Char raise {
  match self.peek() {
    Some(c) => {
      self.pos += 1
      c
    }
    None => raise RegexError("unexpected end of regular expression")
  }
}

///|
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn is_word(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || is_digit(c) || c == '_'
}

///|
fn is_space(c : Char) -> Bool {
  c == ' ' ||
  c == '\t' ||
  c == '\n' ||
  c == '\r' ||
  c == '\u{0B}' ||
  c == '\u{0C}'
}

///|
fn escape_char(c : Char) -> Char {
  match c {
    't' => '\t'
    'n' => '\n'
    'r' => '\r'
    'f' => '\u{0C}'
    'v' => '\u{0B}'
    _ => c
  }
}

///|
fn Parser::parse_alt(self : Parser) -> Array[Array[Node]] raise {
  let alts = [self.parse_seq()]
  while self.peek() is Some('|') {
    self.pos += 1
    alts.push(self.parse_seq())
  }
  alts
}

///|
fn Parser::parse_seq(self : Parser) -> Array[Node] raise {
  let seq = []
  while self.peek() is Some(c) && c != '|' && c != ')' {
    let atom = self.parse_atom()
    seq.push(self.parse_quantifier(atom))
  }
  seq
}

///|
fn Parser::parse_number(self : Parser) -> Int? {
  let start = self.pos
  let mut n = 0
  while self.peek() is Some(c) && is_digit(c) {
    n = n * 10 + (c.to_int() - '0'.to_int())
    self.pos += 1
  }
  if self.pos == start {
    None
  } else {
    Some(n)
  }
}

///|
fn Parser::parse_quantifier(self : Parser, atom : Node) -> Node raise {
  let (min, max) = match self.peek() {
    Some('*') => {
      self.pos += 1
      (0, -1)
    }
    Some('+') => {
      self.pos += 1
      (1, -1)
    }
    Some('?') => {
      self.pos += 1
      (0, 1)
    }
    Some('{') => {
      let save = self.pos
      self.pos += 1
      match self.parse_number() {
        None => {
          self.pos = save
          return atom
        }
        Some(lo) => {
          let hi = if self.peek() is Some(',') {
            self.pos += 1
            self.parse_number().unwrap_or(-1)
          } else {
            lo
          }
          if self.peek() is Some('}') {
            self.pos += 1
            (lo, hi)
          } else {
            self.pos = save
            return atom
          }
        }
      }
    }
    _ => return atom
  }
  match atom {
    Bol | Eol | WordBoundary(_) => raise RegexError("nothing to repeat")
    _ => ()
  }
  // lazy and possessive suffixes do not change whether a match exists
  if self.peek() is Some('?' | '+') {
    self.pos += 1
  }
  Repeat(atom, min, max)
}

///|
fn Parser::parse_class(self : Parser) -> Node raise {
  let negated = if self.peek() is Some('^') {
    self.pos += 1
    true
  } else {
    false
  }
  let items = []
  let mut first = true
  for ;; {
    let c = self.next()
    if c == ']' && !first {
      break
    }
    first = false
    let item = if c == '\\' {
      match self.next() {
        'd' => Digit(true)
        'D' => Digit(false)
        'w' => Word(true)
        'W' => Word(false)
        's' => Space(true)
        'S' => Space(false)
        e => Range(escape_char(e), escape_char(e))
      }
    } else {
      Range(c, c)
    }
    match item {
      Range(lo, _) if self.peek() is Some('-') &&
        self.pos + 1 < self.chars.length() &&
        self.chars[self.pos + 1] != ']' => {
        self.pos += 1
        let hi = match self.next() {
          '\\' => escape_char(self.next())
          h => h
        }
        items.push(Range(lo, hi))
      }
      _ => items.push(item)
    }
  }
  Class(items, negated)
}

///|
fn Parser::parse_atom(self : Parser) -> Node raise {
  match self.next() {
    '.' => AnyChar
    '^' => Bol
    '$' => Eol
    '[' => self.parse_class()
    '(' => {
      if self.peek() is Some('?') {
        self.pos += 1
        if self.next() != ':' {
          raise RegexError("unsupported group syntax")
        }
      }
      let alts = self.parse_alt()
      if self.next() != ')' {
        raise RegexError("unbalanced parenthesis")
      }
      Group(alts)
    }
    ')' => raise RegexError("unbalanced parenthesis")
    '*' | '+' | '?' => raise RegexError("nothing to repeat")
    '\\' =>
      match self.next() {
        'd' => Class([Digit(true)], false)
        'D' => Class([Digit(false)], false)
        'w' => Class([Word(true)], false)
        'W' => Class([Word(false)], false)
        's' => Class([Space(true)], false)
        'S' => Class([Space(false)], false)
        'b' => WordBoundary(true)
        'B' => WordBoundary(false)
        e => Lit(escape_char(e))
      }
    c => Lit(c)
  }
}

///|
/// Compiles a regular expression.
pub fn Regex::compile(pattern : String) -> Result[Regex, String] {
  let parser : Parser = { chars: pattern.iter().collect(), pos: 0, }
  try {
    let alts = parser.parse_alt()
    if parser.pos < parser.chars.length() {
      raise RegexError("unbalanced parenthesis")
    }
    alts
  } catch {
    RegexError(msg) => Err("invalid regular expression \{pattern}: \{msg}")
    e => Err("invalid regular expression \{pattern}: \{e}")
  } noraise {
    alternatives => Ok({ alternatives, })
  }
}

///|
fn class_item_matches(item : ClassItem, c : Char) -> Bool {
  match item {
    Range(lo, hi) => c >= lo && c <= hi
    Digit(b) => is_digit(c) == b
    Word(b) => is_word(c) == b
    Space(b) => is_space(c) == b
  }
}

///|
fn match_seq(
  input : Array[Char],
  seq : Array[Node],
  index : Int,
  pos : Int,
  k : (Int) -> Bool,
) -> Bool {
  if index == seq.length() {
    k(pos)
  } else {
    match_node(input, seq[index], pos, p => {
      match_seq(input, seq, index + 1, p, k)
    })
  }
}

///|
fn match_alts(
  input : Array[Char],
  alts : Array[Array[Node]],
  pos : Int,
  k : (Int) -> Bool,
) -> Bool {
  alts.any(seq => match_seq(input, seq, 0, pos, k))
}

///|
fn match_repeat(
  input : Array[Char],
  node : Node,
  min : Int,
  max : Int,
  count : Int,
  pos : Int,
  k : (Int) -> Bool,
) -> Bool {
  let more = (max < 0 || count < max) &&
    match_node(input, node, pos, p => {
      p != pos && match_repeat(input, node, min, max, count + 1, p, k)
    })
  more || (count >= min && k(pos))
}

///|
fn match_node(
  input : Array[Char],
  node : Node,
  pos : Int,
  k : (Int) -> Bool,
) -> Bool {
  let len = input.length()
  match node {
    Lit(c) => pos < len && input[pos] == c && k(pos + 1)
    AnyChar => pos < len && input[pos] != '\n' && k(pos + 1)
    Class(items, negated) =>
      pos < len &&
      items.any(item => class_item_matches(item, input[pos])) != negated &&
      k(pos + 1)
    Bol => pos == 0 && k(pos)
    Eol => (pos == len || (pos == len - 1 && input[pos] == '\n')) && k(pos)
    WordBoundary(expected) => {
      let before = pos > 0 && is_word(input[pos - 1])
      let after = pos < len && is_word(input[pos])
      (before != after) == expected && k(pos)
    }
    Group(alts) => match_alts(input, alts, pos, k)
    Repeat(inner, min, max) =>
      if min > 0 {
        // match the mandatory repetitions first, allowing empty matches
        match_node(input, inner, pos, p => {
          match_node(
            input,
            Repeat(inner, min - 1, if max < 0 { -1 } else { max - 1 }),
            p,
            k,
          )
        })
      } else {
        match_repeat(input, inner, 0, max, 0, pos, k)
      }
  }
}

///|
/// `true` if the expression matches some substring of `input` (`Re.execp`).
pub fn Regex::execp(self : Regex, input : String) -> Bool {
  let chars : Array[Char] = input.iter().collect()
  for start in 0..<=chars.length() {
    if match_alts(chars, self.alternatives, start, _ => true) {
      return true
    }
  }
  false
}
