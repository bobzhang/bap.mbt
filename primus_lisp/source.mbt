// Primus Lisp sources: an s-expression reader with source locations
// (upstream `Bap_primus_lisp_source`, `Bap_primus_lisp_loc`, and the part of
// `Parsexp` used by them).

///|
/// A position in a source text (upstream `Parsexp.Positions.pos`).
///
/// `line` is 1-based, `col` and `offset` are 0-based and are counted in
/// UTF-16 code units.
pub(all) struct Position {
  line : Int
  col : Int
  offset : Int
} derive(Eq, Compare, Debug)

///|
/// A region of a source text, `end_pos` is exclusive.
pub(all) struct Range {
  start_pos : Position
  end_pos : Position
} derive(Eq, Compare, Debug)

///|
/// A region of the specified file (upstream `Loc.t`).
pub(all) struct Loc {
  file : String
  range : Range
} derive(Eq, Compare, Debug)

///|
let no_position : Position = { line: 1, col: 0, offset: 0 }

///|
let no_range : Range = { start_pos: no_position, end_pos: no_position }

///|
/// Renders the location in the OCaml-compiler style used upstream:
/// `File "init.lisp", line 3, characters 2-10`.
pub impl Show for Loc with output(self, logger) {
  let s = self.range.start_pos
  let e = self.range.end_pos
  let len = e.offset - s.offset
  logger.write_string(
    "File \{self.file.escape()}, line \{s.line}, characters \{s.col}-\{s.col + len}",
  )
}

///|
/// Merges two locations of the same file into the smallest location that
/// covers both. Returns the first location when the files differ.
pub fn Loc::merge(self : Loc, other : Loc) -> Loc {
  if self.file != other.file {
    return self
  }
  let min_pos = (p1 : Position, p2 : Position) => {
    line: @cmp.minimum(p1.line, p2.line),
    col: @cmp.minimum(p1.col, p2.col),
    offset: @cmp.minimum(p1.offset, p2.offset),
  }
  let max_pos = (p1 : Position, p2 : Position) => {
    line: @cmp.maximum(p1.line, p2.line),
    col: @cmp.maximum(p1.col, p2.col),
    offset: @cmp.maximum(p1.offset, p2.offset),
  }
  {
    file: self.file,
    range: {
      start_pos: min_pos(self.range.start_pos, other.range.start_pos),
      end_pos: max_pos(self.range.end_pos, other.range.end_pos),
    },
  }
}

///|
/// The location of the `off`-th character of the location.
pub fn Loc::nth_char(self : Loc, off : Int) -> Loc {
  let shift = (p : Position, n : Int) => {
    line: p.line,
    col: p.col + n,
    offset: p.offset + n,
  }
  {
    file: self.file,
    range: {
      start_pos: shift(self.range.start_pos, off),
      end_pos: shift(self.range.start_pos, off + 1),
    },
  }
}

///|
/// A token of the Lisp syntax tree.
pub(all) enum Token {
  Atom(String)
  List(Array[Tree])
} derive(Eq, Debug)

///|
/// A node of the concrete syntax tree. Every node read from a source has a
/// unique identifier `id` (the upstream `Id.t`), which is used to find its
/// location, and to identify the expressions in the type checker.
///
/// Quoted atoms keep their source representation (including the quotes
/// and the escape sequences), exactly as upstream (Parsexp CST atoms).
pub(all) struct Tree {
  data : Token
  id : Int
} derive(Eq, Debug)

///|
pub impl Show for Tree with output(self, logger) {
  match self.data {
    Atom(x) => logger.write_string(x)
    List(xs) => {
      logger.write_char('(')
      for i, x in xs {
        if i > 0 {
          logger.write_char(' ')
        }
        x.output(logger)
      }
      logger.write_char(')')
    }
  }
}

///|
/// Creates a tree that has no source (the null identifier).
pub fn Tree::atom(x : String, id? : Int = 0) -> Tree {
  { data: Atom(x), id }
}

///|
pub fn Tree::list(xs : Array[Tree], id? : Int = 0) -> Tree {
  { data: List(xs), id }
}

///|
/// Errors of the s-expression reader.
pub(all) suberror SexpError {
  UnexpectedEof(file~ : String, pos~ : Position)
  UnexpectedClosingParen(file~ : String, pos~ : Position)
  UnterminatedString(file~ : String, pos~ : Position)
  UnterminatedComment(file~ : String, pos~ : Position)
} derive(Eq, Debug)

///|
pub impl Show for SexpError with output(self, logger) {
  let (file, pos, what) = match self {
    UnexpectedEof(file~, pos~) => (file, pos, "unexpected end of input")
    UnexpectedClosingParen(file~, pos~) => (file, pos, "unexpected ')'")
    UnterminatedString(file~, pos~) => (file, pos, "unterminated string")
    UnterminatedComment(file~, pos~) => (file, pos, "unterminated comment")
  }
  logger.write_string(
    "File \{file.escape()}, line \{pos.line}, character \{pos.col}: s-expression parse error: \{what}",
  )
}

///|
/// The source store (upstream `Source.t`): the parsed files, the source
/// ranges and origins of every tree, and the equivalence classes of
/// derived (renamed) identifiers.
///
/// Unlike upstream the store is mutable and shared by all programs that
/// were derived from it; identifiers only grow, so sharing is safe.
pub struct Source {
  priv mut lastid : Int
  priv ranges : Map[Int, Range]
  priv origin : Map[Int, String]
  priv files : Map[String, Array[Tree]]
  priv inputs : Map[String, String]
  priv rclass : Map[Int, Int]
}

///|
pub fn Source::new() -> Source {
  {
    lastid: 0,
    ranges: {},
    origin: {},
    files: {},
    inputs: {},
    rclass: {},
  }
}

///|
pub fn Source::is_empty(self : Source) -> Bool {
  self.lastid == 0
}

///|
/// The last identifier that was allocated.
pub fn Source::lastid(self : Source) -> Int {
  self.lastid
}

///|
/// Allocates a fresh identifier that is derived from `from`, i.e., has the
/// same location as `from` (unless `from` is the null identifier).
pub fn Source::derive_id(self : Source, from : Int) -> Int {
  self.lastid += 1
  let id = self.lastid
  if from != 0 {
    self.rclass[id] = from
  }
  id
}

///|
fn Source::repr(self : Source, id : Int) -> Int {
  let mut id = id
  let mut fuel = 1_000_000
  while fuel > 0 {
    fuel -= 1
    match self.rclass.get(id) {
      None => break
      Some(id2) => {
        if id2 == id {
          break
        }
        id = id2
      }
    }
  }
  id
}

///|
/// The trees of the loaded file.
pub fn Source::find(self : Source, file : String) -> Array[Tree]? {
  self.files.get(file)
}

///|
/// The text of the loaded file.
pub fn Source::input(self : Source, file : String) -> String? {
  self.inputs.get(file)
}

///|
/// Loaded file names in the lexicographic order.
pub fn Source::filenames(self : Source) -> Array[String] {
  let names = self.files.keys().collect()
  names.sort()
  names
}

///|
pub fn Source::range(self : Source, id : Int) -> Range {
  match self.ranges.get(self.repr(id)) {
    Some(r) => r
    None => no_range
  }
}

///|
pub fn Source::filename(self : Source, id : Int) -> String {
  match self.origin.get(self.repr(id)) {
    Some(f) => f
    None => "/unknown/"
  }
}

///|
pub fn Source::loc(self : Source, id : Int) -> Loc {
  { file: self.filename(id), range: self.range(id) }
}

///|
pub fn Source::has_loc(self : Source, id : Int) -> Bool {
  self.origin.contains(self.repr(id))
}

///|
/// The location that covers all the given trees.
pub fn Source::loc_of_trees(self : Source, trees : ArrayView[Tree]) -> Loc {
  match trees {
    [] => self.loc(0)
    [t, .. ts] => {
      let mut loc = self.loc(t.id)
      for t in ts {
        loc = loc.merge(self.loc(t.id))
      }
      loc
    }
  }
}

///|
/// The source text at the location.
pub fn Source::text_at(self : Source, loc : Loc) -> String {
  match self.inputs.get(loc.file) {
    None => ""
    Some(text) => {
      let s = @cmp.maximum(0, loc.range.start_pos.offset)
      let e = @cmp.minimum(text.length(), loc.range.end_pos.offset)
      if s >= e {
        ""
      } else {
        text.unsafe_substring(start=s, end=e)
      }
    }
  }
}

///|
/// Renders the lines around the location, marking the lines of the
/// location with `>` and underlining the location (upstream
/// `Source.pp_underline`).
pub fn Source::underline(self : Source, loc : Loc, context? : Int = 4) -> String {
  guard self.inputs.get(loc.file) is Some(text) else { return "" }
  let start_pos = loc.range.start_pos
  let end_pos = loc.range.end_pos
  let buf = StringBuilder()
  let underline = (off : Int, len : Int) => {
    buf.write_string("> ")
    for i in 0..<len {
      buf.write_char(if i < off { ' ' } else { '^' })
    }
    buf.write_char('\n')
  }
  let mut current = 0
  for line in text.split("\n") {
    current += 1
    if current == end_pos.line + 1 {
      underline(start_pos.col, end_pos.col)
    }
    let distance = @cmp.minimum(
      (current - start_pos.line).abs(),
      (current - end_pos.line).abs(),
    )
    let bad = current >= start_pos.line && current <= end_pos.line
    if distance < context {
      buf.write_char(if bad { '>' } else { '|' })
      buf.write_char(' ')
      buf.write_view(line)
      buf.write_char('\n')
    }
  }
  if current == end_pos.line {
    underline(start_pos.col, end_pos.col)
  }
  buf.to_string()
}

///|
/// Parses `text` as the contents of `file` and adds it to the store.
/// Returns the top-level trees. A file that is already loaded is not
/// reloaded.
pub fn Source::load_string(
  self : Source,
  file : String,
  text : String,
) -> Array[Tree] raise SexpError {
  if self.files.get(file) is Some(trees) {
    return trees
  }
  let reader = Reader::new(self, file, text)
  let trees = reader.read_all()
  self.files[file] = trees
  self.inputs[file] = text
  trees
}

///|
/// Parses a string of s-expressions that is not associated with any
/// file. The trees are registered with the given pseudo-file name, but the
/// file is not added to the list of loaded files.
pub fn Source::read_string(
  self : Source,
  text : String,
  file? : String = "/unknown/",
) -> Array[Tree] raise SexpError {
  Reader::new(self, file, text).read_all()
}

///|
priv struct Reader {
  src : Source
  file : String
  text : String
  mut pos : Int
  mut line : Int
  mut bol : Int
}

///|
fn Reader::new(src : Source, file : String, text : String) -> Reader {
  { src, file, text, pos: 0, line: 1, bol: 0 }
}

///|
fn Reader::position(self : Reader) -> Position {
  { line: self.line, col: self.pos - self.bol, offset: self.pos }
}

///|
fn Reader::peek(self : Reader) -> Int {
  if self.pos < self.text.length() {
    self.text[self.pos].to_int()
  } else {
    -1
  }
}

///|
fn Reader::peek2(self : Reader) -> Int {
  if self.pos + 1 < self.text.length() {
    self.text[self.pos + 1].to_int()
  } else {
    -1
  }
}

///|
fn Reader::advance(self : Reader) -> Unit {
  if self.pos < self.text.length() {
    if self.text[self.pos] == '\n' {
      self.line += 1
      self.bol = self.pos + 1
    }
    self.pos += 1
  }
}

///|
fn is_space(c : Int) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == 0x0c
}

///|
fn is_atom_char(c : Int) -> Bool {
  c >= 0 && !is_space(c) && c != '(' && c != ')' && c != '"' && c != ';'
}

///|
/// Skips whitespace and comments. Returns `true` if a `#;` sexp comment
/// prefix was consumed.
fn Reader::skip(self : Reader) -> Unit raise SexpError {
  while true {
    let c = self.peek()
    if is_space(c) {
      self.advance()
    } else if c == ';' {
      while self.peek() >= 0 && self.peek() != '\n' {
        self.advance()
      }
    } else if c == '#' && self.peek2() == '|' {
      let start = self.position()
      self.advance()
      self.advance()
      let mut depth = 1
      while depth > 0 {
        let c = self.peek()
        if c < 0 {
          raise UnterminatedComment(file=self.file, pos=start)
        } else if c == '|' && self.peek2() == '#' {
          self.advance()
          self.advance()
          depth -= 1
        } else if c == '#' && self.peek2() == '|' {
          self.advance()
          self.advance()
          depth += 1
        } else {
          self.advance()
        }
      }
    } else if c == '#' && self.peek2() == ';' {
      self.advance()
      self.advance()
      self.skip()
      if self.peek() < 0 {
        raise UnexpectedEof(file=self.file, pos=self.position())
      }
      ignore(self.read_tree())
    } else {
      break
    }
  }
}

///|
fn Reader::register(self : Reader, data : Token, start : Position) -> Tree {
  self.src.lastid += 1
  let id = self.src.lastid
  self.src.ranges[id] = { start_pos: start, end_pos: self.position() }
  self.src.origin[id] = self.file
  { data, id }
}

///|
fn Reader::read_tree(self : Reader) -> Tree raise SexpError {
  let start = self.position()
  let c = self.peek()
  if c < 0 {
    raise UnexpectedEof(file=self.file, pos=start)
  } else if c == '(' {
    self.advance()
    let elts = []
    while true {
      self.skip()
      let c = self.peek()
      if c < 0 {
        raise UnexpectedEof(file=self.file, pos=start)
      } else if c == ')' {
        self.advance()
        break
      } else {
        elts.push(self.read_tree())
      }
    }
    self.register(List(elts), start)
  } else if c == ')' {
    raise UnexpectedClosingParen(file=self.file, pos=start)
  } else if c == '"' {
    self.advance()
    while true {
      let c = self.peek()
      if c < 0 {
        raise UnterminatedString(file=self.file, pos=start)
      } else if c == '\\' {
        self.advance()
        self.advance()
      } else if c == '"' {
        self.advance()
        break
      } else {
        self.advance()
      }
    }
    let atom = self.text.unsafe_substring(start=start.offset, end=self.pos)
    self.register(Atom(atom), start)
  } else {
    while is_atom_char(self.peek()) {
      self.advance()
    }
    let atom = self.text.unsafe_substring(start=start.offset, end=self.pos)
    self.register(Atom(atom), start)
  }
}

///|
fn Reader::read_all(self : Reader) -> Array[Tree] raise SexpError {
  let trees = []
  while true {
    self.skip()
    if self.peek() < 0 {
      break
    }
    trees.push(self.read_tree())
  }
  trees
}
