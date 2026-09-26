// A small backtracking regular expression engine covering the PCRE subset
// that is used by the `--print-matching` patterns (upstream uses
// `Re.Pcre` with partial, i.e., unanchored, matching).

///|
priv enum ReNode {
  ReChar(Char)
  ReAny
  ReClass(Array[(Char, Char)], Bool)
  ReStart
  ReEnd
  ReGroup(Array[Array[ReNode]])
  ReRepeat(ReNode, Int, Int, Bool)
}

///|
/// A compiled regular expression.
priv struct Regex {
  source : String
  alternatives : Array[Array[ReNode]]
}

///|
priv struct ReParser {
  chars : Array[Char]
  mut pos : Int
}

///|
fn ReParser::peek(self : ReParser) -> Char? {
  if self.pos < self.chars.length() {
    Some(self.chars[self.pos])
  } else {
    None
  }
}

///|
fn ReParser::next(self : ReParser) -> Char? {
  let c = self.peek()
  if c is Some(_) {
    self.pos += 1
  }
  c
}

///|
fn re_class_of_escape(c : Char) -> (Array[(Char, Char)], Bool)? {
  match c {
    'd' => Some(([('0', '9')], false))
    'D' => Some(([('0', '9')], true))
    'w' => Some(([('a', 'z'), ('A', 'Z'), ('0', '9'), ('_', '_')], false))
    'W' => Some(([('a', 'z'), ('A', 'Z'), ('0', '9'), ('_', '_')], true))
    's' =>
      Some(
        (
          [
            (' ', ' '),
            ('\t', '\t'),
            ('\n', '\n'),
            ('\r', '\r'),
            ('\u{0b}', '\u{0c}'),
          ],
          false,
        ),
      )
    'S' =>
      Some(
        (
          [
            (' ', ' '),
            ('\t', '\t'),
            ('\n', '\n'),
            ('\r', '\r'),
            ('\u{0b}', '\u{0c}'),
          ],
          true,
        ),
      )
    _ => None
  }
}

///|
fn re_escaped_char(c : Char) -> Char {
  match c {
    'n' => '\n'
    't' => '\t'
    'r' => '\r'
    _ => c
  }
}

///|
fn ReParser::parse_class(self : ReParser) -> ReNode raise Failure {
  let negated = if self.peek() is Some('^') {
    self.pos += 1
    true
  } else {
    false
  }
  let ranges : Array[(Char, Char)] = []
  let mut first = true
  for ;; {
    guard self.next() is Some(c) else { fail("unterminated character class") }
    if c == ']' && !first {
      break
    }
    first = false
    let lo = if c == '\\' {
      guard self.next() is Some(e) else { fail("dangling escape") }
      match re_class_of_escape(e) {
        Some((rs, false)) => {
          ranges.append(rs)
          continue
        }
        _ => re_escaped_char(e)
      }
    } else {
      c
    }
    if self.peek() is Some('-') &&
      self.pos + 1 < self.chars.length() &&
      self.chars[self.pos + 1] != ']' {
      self.pos += 1
      guard self.next() is Some(hi) else { fail("bad range") }
      let hi = if hi == '\\' {
        guard self.next() is Some(e) else { fail("dangling escape") }
        re_escaped_char(e)
      } else {
        hi
      }
      ranges.push((lo, hi))
    } else {
      ranges.push((lo, lo))
    }
  }
  ReClass(ranges, negated)
}

///|
fn ReParser::parse_int(self : ReParser) -> Int? {
  let mut n = 0
  let mut seen = false
  while self.peek() is Some('0'..='9' as d) {
    n = n * 10 + (d.to_int() - '0'.to_int())
    seen = true
    self.pos += 1
  }
  if seen {
    Some(n)
  } else {
    None
  }
}

///|
fn ReParser::parse_atom(self : ReParser) -> ReNode raise Failure {
  guard self.next() is Some(c) else { fail("unexpected end of pattern") }
  match c {
    '.' => ReAny
    '^' => ReStart
    '$' => ReEnd
    '[' => self.parse_class()
    '(' => {
      // non-capturing group marker `(?:` is accepted and ignored
      if self.peek() is Some('?') &&
        self.pos + 1 < self.chars.length() &&
        self.chars[self.pos + 1] == ':' {
        self.pos += 2
      }
      let alts = self.parse_alternatives()
      guard self.next() is Some(')') else { fail("unbalanced parenthesis") }
      ReGroup(alts)
    }
    '\\' => {
      guard self.next() is Some(e) else { fail("dangling escape") }
      match re_class_of_escape(e) {
        Some((rs, neg)) => ReClass(rs, neg)
        None => ReChar(re_escaped_char(e))
      }
    }
    '*' | '+' | '?' => fail("nothing to repeat")
    _ => ReChar(c)
  }
}

///|
fn ReParser::parse_sequence(self : ReParser) -> Array[ReNode] raise Failure {
  let nodes : Array[ReNode] = []
  while self.peek() is Some(c) && c != '|' && c != ')' {
    let atom = self.parse_atom()
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
        match self.parse_int() {
          Some(lo) =>
            match self.next() {
              Some('}') => (lo, lo)
              Some(',') =>
                match (self.parse_int(), self.next()) {
                  (Some(hi), Some('}')) => (lo, hi)
                  (None, Some('}')) => (lo, -1)
                  _ => fail("bad repetition")
                }
              _ => fail("bad repetition")
            }
          None => {
            self.pos = save
            (1, 1)
          }
        }
      }
      _ => (1, 1)
    }
    if min == 1 && max == 1 {
      nodes.push(atom)
    } else {
      let greedy = if self.peek() is Some('?') {
        self.pos += 1
        false
      } else {
        true
      }
      nodes.push(ReRepeat(atom, min, max, greedy))
    }
  }
  nodes
}

///|
fn ReParser::parse_alternatives(
  self : ReParser,
) -> Array[Array[ReNode]] raise Failure {
  let alts = [self.parse_sequence()]
  while self.peek() is Some('|') {
    self.pos += 1
    alts.push(self.parse_sequence())
  }
  alts
}

///|
fn Regex::compile(source : String) -> Regex raise Failure {
  let parser : ReParser = { chars: source.to_array(), pos: 0, }
  let alternatives = parser.parse_alternatives()
  if parser.pos != parser.chars.length() {
    fail("unbalanced parenthesis")
  }
  { source, alternatives, }
}

///|
fn re_class_mem(ranges : Array[(Char, Char)], negated : Bool, c : Char) -> Bool {
  let inside = ranges.any(r => r.0 <= c && c <= r.1)
  inside != negated
}

///|
fn re_match_node(
  node : ReNode,
  input : Array[Char],
  pos : Int,
  k : (Int) -> Bool,
) -> Bool {
  match node {
    ReChar(c) => pos < input.length() && input[pos] == c && k(pos + 1)
    ReAny => pos < input.length() && input[pos] != '\n' && k(pos + 1)
    ReClass(ranges, negated) =>
      pos < input.length() &&
      re_class_mem(ranges, negated, input[pos]) &&
      k(pos + 1)
    ReStart => pos == 0 && k(pos)
    ReEnd => pos == input.length() && k(pos)
    ReGroup(alts) => alts.any(seq => re_match_seq(seq, 0, input, pos, k))
    ReRepeat(inner, min, max, greedy) =>
      re_match_repeat(inner, min, max, greedy, 0, input, pos, k)
  }
}

///|
fn re_match_repeat(
  inner : ReNode,
  min : Int,
  max : Int,
  greedy : Bool,
  count : Int,
  input : Array[Char],
  pos : Int,
  k : (Int) -> Bool,
) -> Bool {
  let can_more = max < 0 || count < max
  let more = () => {
    can_more &&
    re_match_node(inner, input, pos, next => {
      next != pos &&
      re_match_repeat(inner, min, max, greedy, count + 1, input, next, k)
    })
  }
  if count < min {
    re_match_node(inner, input, pos, next => {
      re_match_repeat(inner, min, max, greedy, count + 1, input, next, k)
    })
  } else if greedy {
    more() || k(pos)
  } else {
    k(pos) || more()
  }
}

///|
fn re_match_seq(
  seq : Array[ReNode],
  index : Int,
  input : Array[Char],
  pos : Int,
  k : (Int) -> Bool,
) -> Bool {
  if index == seq.length() {
    k(pos)
  } else {
    re_match_node(seq[index], input, pos, next => {
      re_match_seq(seq, index + 1, input, next, k)
    })
  }
}

///|
/// Unanchored search, like `Re.execp`: succeeds if the expression matches
/// any substring of `text`.
fn Regex::execp(self : Regex, text : String) -> Bool {
  let input = text.to_array()
  for start in 0..<=input.length() {
    if self.alternatives.any(seq => {
        re_match_seq(seq, 0, input, start, _ => true)
      }) {
      return true
    }
  }
  false
}
