///|
/// The sentinel of the pack-expansion state (`unsigned` max upstream).
const PACK_NONE : Int = 2147483647

///|
/// The stream the AST is printed into (upstream `OutputBuffer`).
///
/// The text is kept as a list of non-empty pieces. The printer only ever
/// rewinds to a position it observed earlier, which is always a piece
/// boundary, so rewinding drops whole pieces.
priv struct Output {
  pieces : Array[StringView]
  mut len : Int
  /// The index into the pack being expanded, or `PACK_NONE`.
  mut pack_index : Int
  /// The size of the pack being expanded, or `PACK_NONE`.
  mut pack_max : Int
  /// The depth of `(` and `)` inside the printed template arguments.
  mut paren_depth : UInt
  /// Whether template arguments are being printed.
  mut inside_template : Bool
}

///|
fn Output::new() -> Output {
  {
    pieces: [],
    len: 0,
    pack_index: PACK_NONE,
    pack_max: PACK_NONE,
    paren_depth: 0,
    inside_template: false,
  }
}

///|
fn Output::add(self : Output, s : StringView) -> Unit {
  if s.length() > 0 {
    self.pieces.push(s)
    self.len += s.length()
  }
}

///|
fn Output::pos(self : Output) -> Int {
  self.len
}

///|
/// Rewinds the stream to an earlier position.
fn Output::set_pos(self : Output, pos : Int) -> Unit {
  while self.len > pos {
    guard self.pieces.pop() is Some(piece) else { break }
    self.len -= piece.length()
  }
}

///|
/// The last code unit of the stream (0 when empty).
fn Output::back(self : Output) -> UInt16 {
  match self.pieces.last() {
    Some(piece) => piece.at(piece.length() - 1)
    None => 0
  }
}

///|
fn Output::print_open(self : Output, open? : StringView = "(") -> Unit {
  if self.inside_template {
    self.paren_depth += 1
  }
  self.add(open)
}

///|
fn Output::print_close(self : Output, close? : StringView = ")") -> Unit {
  if self.inside_template {
    self.paren_depth -= 1
  }
  self.add(close)
}

///|
fn Output::add_uint(self : Output, n : Int) -> Unit {
  self.add(n.to_string())
}

///|
fn Output::contents(self : Output) -> String {
  let sb = StringBuilder(size_hint=self.len)
  for piece in self.pieces {
    sb.write_view(piece)
  }
  sb.to_string()
}
