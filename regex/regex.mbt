// A small backtracking matcher for the subset of PCRE syntax used by BAP
// plugins (upstream uses `Re.Pcre` from ocaml-re). It supports
//
// - literals and `.` (any character except a newline);
// - character classes `[...]` with ranges, negation `[^...]`, and the
//   class escapes `\d \w \s \D \W \S` inside and outside of classes;
// - the escapes `\t \n \r \f \v`, any other escaped character is literal;
// - anchors `^` (start of input), `$` (end of input or before a final
//   newline), and the word boundaries `\b` and `\B`;
// - groups `( )` and `(?: )` (groups do not capture), alternation `|`;
// - the quantifiers `* + ? {n} {n,} {n,m}`, greedy by default, lazy with
//   a `?` suffix, and possessive with a `+` suffix;
// - case-insensitive (ASCII) matching with `Regex::compile(caseless=true)`.

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
priv enum Mode {
  Greedy
  Lazy
  Possessive
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
  Repeat(Node, Int, Int, Mode)
}

///|
/// A compiled regular expression.
pub struct Regex {
  priv source : String
  priv alternatives : Array[Array[Node]]
  priv caseless : Bool
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
fn Parser::next(self : Parser) -> Char raise RegexError {
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
fn class_escape(c : Char) -> ClassItem? {
  match c {
    'd' => Some(Digit(true))
    'D' => Some(Digit(false))
    'w' => Some(Word(true))
    'W' => Some(Word(false))
    's' => Some(Space(true))
    'S' => Some(Space(false))
    _ => None
  }
}

///|
fn Parser::parse_alt(self : Parser) -> Array[Array[Node]] raise RegexError {
  let alts = [self.parse_seq()]
  while self.peek() is Some('|') {
    self.pos += 1
    alts.push(self.parse_seq())
  }
  alts
}

///|
fn Parser::parse_seq(self : Parser) -> Array[Node] raise RegexError {
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
/// Parses a `{n}`, `{n,}` or `{n,m}` bound at the current (opening brace)
/// position. A brace that does not start a valid bound is a literal (as in
/// PCRE), in which case the position is left unchanged and `None` returned.
fn Parser::parse_bound(self : Parser) -> (Int, Int)? {
  let save = self.pos
  self.pos += 1
  guard self.parse_number() is Some(lo) else {
    self.pos = save
    return None
  }
  let hi = if self.peek() is Some(',') {
    self.pos += 1
    self.parse_number().unwrap_or(-1)
  } else {
    lo
  }
  if self.peek() is Some('}') {
    self.pos += 1
    Some((lo, hi))
  } else {
    self.pos = save
    None
  }
}

///|
fn Parser::parse_quantifier(
  self : Parser,
  atom : Node,
) -> Node raise RegexError {
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
    Some('{') =>
      match self.parse_bound() {
        Some(bound) => bound
        None => return atom
      }
    _ => return atom
  }
  if max >= 0 && max < min {
    raise RegexError("numbers out of order in {} quantifier")
  }
  match atom {
    Bol | Eol | WordBoundary(_) => raise RegexError("nothing to repeat")
    _ => ()
  }
  let mode = match self.peek() {
    Some('?') => {
      self.pos += 1
      Lazy
    }
    Some('+') => {
      self.pos += 1
      Possessive
    }
    _ => Greedy
  }
  Repeat(atom, min, max, mode)
}

///|
fn Parser::parse_class(self : Parser) -> Node raise RegexError {
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
      let e = self.next()
      match class_escape(e) {
        Some(item) => item
        None => Range(escape_char(e), escape_char(e))
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
        if hi < lo {
          raise RegexError("range out of order in character class")
        }
        items.push(Range(lo, hi))
      }
      _ => items.push(item)
    }
  }
  Class(items, negated)
}

///|
fn Parser::parse_atom(self : Parser) -> Node raise RegexError {
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
    '\\' => {
      let e = self.next()
      match e {
        'b' => WordBoundary(true)
        'B' => WordBoundary(false)
        _ =>
          match class_escape(e) {
            Some(item) => Class([item], false)
            None => Lit(escape_char(e))
          }
      }
    }
    c => Lit(c)
  }
}

///|
/// Compiles a regular expression written in the supported PCRE subset
/// (see the package documentation). On failure, returns the reason.
///
/// If `caseless` is `true`, ASCII letters match regardless of their case.
///
/// ```mbt check
/// test {
///   let re = @regex.Regex::compile("^(str|mem)cpy$").unwrap()
///   inspect(re.execp("memcpy"), content="true")
///   inspect(re.execp("wcscpy"), content="false")
///   inspect(@regex.Regex::compile("(ab") is Err(_), content="true")
/// }
/// ```
pub fn Regex::compile(
  pattern : String,
  caseless? : Bool = false,
) -> Result[Regex, String] {
  let parser : Parser = { chars: pattern.iter().collect(), pos: 0, }
  try {
    let alts = parser.parse_alt()
    if parser.pos < parser.chars.length() {
      raise RegexError("unbalanced parenthesis")
    }
    alts
  } catch {
    RegexError(msg) => Err(msg)
  } noraise {
    alternatives => Ok({ source: pattern, alternatives, caseless, })
  }
}

///|
/// The source text of the expression.
pub fn Regex::source(self : Regex) -> String {
  self.source
}

///|
pub impl Show for Regex with fn output(self, logger) {
  logger.write_string(self.source)
}

///|
pub extend Regex with Show::{to_string, output}

///|
fn fold_case(c : Char) -> Char {
  if c >= 'A' && c <= 'Z' {
    (c.to_int() + 32).unsafe_to_char()
  } else {
    c
  }
}

///|
fn swap_case(c : Char) -> Char {
  if c >= 'A' && c <= 'Z' {
    (c.to_int() + 32).unsafe_to_char()
  } else if c >= 'a' && c <= 'z' {
    (c.to_int() - 32).unsafe_to_char()
  } else {
    c
  }
}

///|
priv struct Matcher {
  input : Array[Char]
  caseless : Bool
}

///|
fn Matcher::class_item_matches(
  self : Matcher,
  item : ClassItem,
  c : Char,
) -> Bool {
  match item {
    Range(lo, hi) =>
      (c >= lo && c <= hi) ||
      (
        self.caseless &&
        ({
          let d = swap_case(c)
          d >= lo && d <= hi
        })
      )
    Digit(b) => is_digit(c) == b
    Word(b) => is_word(c) == b
    Space(b) => is_space(c) == b
  }
}

///|
fn Matcher::match_seq(
  self : Matcher,
  seq : Array[Node],
  index : Int,
  pos : Int,
  k : (Int) -> Bool,
) -> Bool {
  if index == seq.length() {
    k(pos)
  } else {
    self.match_node(seq[index], pos, p => self.match_seq(seq, index + 1, p, k))
  }
}

///|
fn Matcher::match_alts(
  self : Matcher,
  alts : Array[Array[Node]],
  pos : Int,
  k : (Int) -> Bool,
) -> Bool {
  alts.any(seq => self.match_seq(seq, 0, pos, k))
}

///|
/// Matches `node` repeated between `min` and `max` (`-1` - unbounded)
/// times, `count` repetitions being already matched. Optional repetitions
/// must consume input, which guarantees termination.
fn Matcher::match_repeat(
  self : Matcher,
  node : Node,
  min : Int,
  max : Int,
  reluctant : Bool,
  count : Int,
  pos : Int,
  k : (Int) -> Bool,
) -> Bool {
  if count < min {
    return self.match_node(node, pos, p => {
      self.match_repeat(node, min, max, reluctant, count + 1, p, k)
    })
  }
  let more = () => {
    (max < 0 || count < max) &&
    self.match_node(node, pos, p => {
      p != pos && self.match_repeat(node, min, max, reluctant, count + 1, p, k)
    })
  }
  if reluctant {
    k(pos) || more()
  } else {
    more() || k(pos)
  }
}

///|
/// If `node` always matches exactly one character, the number of
/// consecutive characters from `pos` that it matches (at most `max`,
/// unless `max` is negative).
fn Matcher::single_char_run(
  self : Matcher,
  node : Node,
  pos : Int,
  max : Int,
) -> Int? {
  match node {
    Lit(_) | AnyChar | Class(_) => ()
    _ => return None
  }
  let len = self.input.length()
  let mut n = 0
  while (max < 0 || n < max) &&
        pos + n < len &&
        self.match_node(node, pos + n, _ => true) {
    n += 1
  }
  Some(n)
}

///|
fn Matcher::match_node(
  self : Matcher,
  node : Node,
  pos : Int,
  k : (Int) -> Bool,
) -> Bool {
  let input = self.input
  let len = input.length()
  match node {
    Lit(c) =>
      pos < len &&
      (
        input[pos] == c ||
        (self.caseless && fold_case(input[pos]) == fold_case(c))
      ) &&
      k(pos + 1)
    AnyChar => pos < len && input[pos] != '\n' && k(pos + 1)
    Class(items, negated) =>
      pos < len &&
      items.any(item => self.class_item_matches(item, input[pos])) != negated &&
      k(pos + 1)
    Bol => pos == 0 && k(pos)
    Eol => (pos == len || (pos == len - 1 && input[pos] == '\n')) && k(pos)
    WordBoundary(expected) => {
      let before = pos > 0 && is_word(input[pos - 1])
      let after = pos < len && is_word(input[pos])
      (before != after) == expected && k(pos)
    }
    Group(alts) => self.match_alts(alts, pos, k)
    Repeat(inner, min, max, mode) if self.single_char_run(inner, pos, max)
      is Some(run) =>
      // iterate instead of recursing for repetitions of single characters
      if run < min {
        false
      } else {
        match mode {
          Greedy => {
            let mut n = run
            while n >= min {
              if k(pos + n) {
                return true
              }
              n -= 1
            }
            false
          }
          Lazy => {
            let mut n = min
            while n <= run {
              if k(pos + n) {
                return true
              }
              n += 1
            }
            false
          }
          Possessive => k(pos + run)
        }
      }
    Repeat(inner, min, max, Greedy) =>
      self.match_repeat(inner, min, max, false, 0, pos, k)
    Repeat(inner, min, max, Lazy) =>
      self.match_repeat(inner, min, max, true, 0, pos, k)
    Repeat(inner, min, max, Possessive) => {
      // an atomic group: commit to the first (longest) way to match
      let mut end = -1
      self.match_repeat(inner, min, max, false, 0, pos, p => {
        end = p
        true
      }) &&
      k(end)
    }
  }
}

///|
/// The leftmost match: its start and end character offsets.
fn Regex::search(
  self : Regex,
  chars : Array[Char],
  anchored~ : Bool,
) -> (Int, Int)? {
  let matcher = { input: chars, caseless: self.caseless, }
  let last = if anchored { 0 } else { chars.length() }
  for start in 0..<=last {
    let mut end = -1
    let k = if anchored {
      p => {
        if p == chars.length() {
          end = p
          true
        } else {
          false
        }
      }
    } else {
      p => {
        end = p
        true
      }
    }
    if matcher.match_alts(self.alternatives, start, k) {
      return Some((start, end))
    }
  }
  None
}

///|
/// `true` if the expression matches some substring of `input` (unanchored
/// search, `Re.execp`).
pub fn Regex::execp(self : Regex, input : String) -> Bool {
  self.search(input.iter().collect(), anchored=false) is Some(_)
}

///|
/// `true` if the expression matches the whole `input`.
pub fn Regex::matches(self : Regex, input : String) -> Bool {
  self.search(input.iter().collect(), anchored=true) is Some(_)
}

///|
/// The leftmost substring of `input` matched by the expression (with
/// PCRE's backtracking preferences for the match length).
pub fn Regex::find(self : Regex, input : String) -> String? {
  let chars : Array[Char] = input.iter().collect()
  match self.search(chars, anchored=false) {
    Some((start, end)) => Some(String::from_array(chars[start:end]))
    None => None
  }
}
