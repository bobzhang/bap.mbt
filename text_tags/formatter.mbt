// A port of the pretty-printing engine of OCaml's `Format` module (boxes,
// break hints and semantic tags), which `Text_tags` is built upon.
//
// Tabulation boxes are not supported.

///|
priv enum BoxType {
  HBox
  VBox
  HVBox
  HovBox
  Box
  Fits
}

///|
priv enum Token {
  Text(String)
  Break(fits~ : (String, Int, String), breaks~ : (String, Int, String))
  Begin(Int, BoxType)
  End
  Newline
  IfNewline
  OpenTag(String)
  CloseTag
}

///|
priv struct QueueElem {
  mut size : Int
  token : Token
  length : Int
}

///|
priv struct ScanElem {
  left_total : Int
  elem : QueueElem
}

///|
priv struct FormatElem {
  box_type : BoxType
  width : Int
}

///|
/// Semantic tag handling functions (upstream
/// `Format.formatter_tag_functions`).
///
/// `mark_open_tag`/`mark_close_tag` return zero-width markers that are
/// output around the tagged text when tags are marked;
/// `print_open_tag`/`print_close_tag` are called for their side effects
/// (usually on the formatter itself) when tags are printed.
pub(all) struct TagFunctions {
  mark_open_tag : (String) -> String
  mark_close_tag : (String) -> String
  print_open_tag : (String) -> Unit
  print_close_tag : (String) -> Unit
}

///|
/// The default tag functions: markers are `<tag>` and `</tag>`, printing
/// does nothing.
pub fn TagFunctions::default() -> TagFunctions {
  {
    mark_open_tag: tag => "<\{tag}>",
    mark_close_tag: tag => "</\{tag}>",
    print_open_tag: _ => (),
    print_close_tag: _ => (),
  }
}

///|
/// Low-level output functions of a formatter (upstream
/// `Format.formatter_out_functions`).
pub(all) struct OutFunctions {
  out_string : (String) -> Unit
  out_flush : () -> Unit
  out_newline : () -> Unit
  out_spaces : (Int) -> Unit
  out_indent : (Int) -> Unit
}

///|
/// Output functions that write into [logger].
pub fn OutFunctions::of_logger(logger : &Logger) -> OutFunctions {
  let blanks = (n : Int) => {
    for _ in 0..<n {
      logger.write_char(' ')
    }
  }
  {
    out_string: s => logger.write_string(s),
    out_flush: () => (),
    out_newline: () => logger.write_char('\n'),
    out_spaces: blanks,
    out_indent: blanks,
  }
}

///|
/// A pretty-printer (upstream `Format.formatter`).
///
/// Material is queued until the size of the enclosing box is known, so it
/// reaches the output only after a flush (`print_flush`, `print_newline`)
/// or when the pending material overflows the line.
pub struct Formatter {
  priv scan_stack : Array[ScanElem]
  priv format_stack : Array[FormatElem]
  priv tag_stack : Array[String]
  priv mark_stack : Array[String]
  priv queue : @deque.Deque[QueueElem]
  priv mut margin : Int
  priv mut min_space_left : Int
  priv mut max_indent : Int
  priv mut space_left : Int
  priv mut current_indent : Int
  priv mut is_new_line : Bool
  priv mut left_total : Int
  priv mut right_total : Int
  priv mut curr_depth : Int
  priv mut max_boxes : Int
  priv mut ellipsis : String
  priv mut out : OutFunctions
  priv mut print_tags : Bool
  priv mut mark_tags : Bool
  priv mut tags : TagFunctions
  priv buffer : StringBuilder?
}

///|
let infinity : Int = 1000000010

///|
fn sentinel() -> ScanElem {
  { left_total: -1, elem: { size: -1, token: Text(""), length: 0, }, }
}

///|
fn Formatter::make(out : OutFunctions, buffer : StringBuilder?) -> Formatter {
  let sys = { size: -1, token: Begin(0, HovBox), length: 0, }
  let queue = @deque.Deque([])
  queue.push_back(sys)
  let margin = 78
  let min_space_left = 10
  {
    scan_stack: [sentinel(), { left_total: 1, elem: sys, }],
    format_stack: [],
    tag_stack: [],
    mark_stack: [],
    queue,
    margin,
    min_space_left,
    max_indent: margin - min_space_left,
    space_left: margin,
    current_indent: 0,
    is_new_line: true,
    left_total: 1,
    right_total: 1,
    curr_depth: 1,
    max_boxes: 2147483647,
    ellipsis: ".",
    out,
    print_tags: false,
    mark_tags: false,
    tags: TagFunctions::default(),
    buffer,
  }
}

///|
/// Creates a formatter that accumulates its output in a buffer, see
/// `Formatter::contents`.
pub fn Formatter::new() -> Formatter {
  let buffer = StringBuilder()
  Formatter::make(OutFunctions::of_logger(buffer), Some(buffer))
}

///|
/// Creates a formatter that writes into [logger].
pub fn Formatter::of_logger(logger : &Logger) -> Formatter {
  Formatter::make(OutFunctions::of_logger(logger), None)
}

///|
/// Creates a formatter with the given output functions.
pub fn Formatter::of_out_functions(out : OutFunctions) -> Formatter {
  Formatter::make(out, None)
}

///|
/// The text written so far by a formatter created with `Formatter::new`
/// (the pending material is not flushed). Empty for other formatters.
pub fn Formatter::contents(self : Formatter) -> String {
  match self.buffer {
    Some(buffer) => buffer.to_string()
    None => ""
  }
}

///|
/// Flushes the formatter and returns (and clears) the accumulated text of a
/// formatter created with `Formatter::new`.
pub fn Formatter::flush_str(self : Formatter) -> String {
  self.print_flush()
  match self.buffer {
    Some(buffer) => {
      let text = buffer.to_string()
      buffer.reset()
      text
    }
    None => ""
  }
}

// Output primitives

///|
fn Formatter::format_pp_text(
  self : Formatter,
  size : Int,
  text : String,
) -> Unit {
  self.space_left -= size
  (self.out.out_string)(text)
  self.is_new_line = false
}

///|
fn Formatter::format_string(self : Formatter, s : String) -> Unit {
  if s != "" {
    self.format_pp_text(s.length(), s)
  }
}

///|
fn Formatter::break_new_line(
  self : Formatter,
  breaks : (String, Int, String),
  width : Int,
) -> Unit {
  let (before, offset, after) = breaks
  self.format_string(before)
  (self.out.out_newline)()
  self.is_new_line = true
  let indent = self.margin - width + offset
  let real_indent = if self.max_indent < indent {
    self.max_indent
  } else {
    indent
  }
  self.current_indent = real_indent
  self.space_left = self.margin - self.current_indent
  (self.out.out_indent)(self.current_indent)
  self.format_string(after)
}

///|
fn Formatter::break_line(self : Formatter, width : Int) -> Unit {
  self.break_new_line(("", 0, ""), width)
}

///|
fn Formatter::break_same_line(
  self : Formatter,
  fits : (String, Int, String),
) -> Unit {
  let (before, width, after) = fits
  self.format_string(before)
  self.space_left -= width
  (self.out.out_spaces)(width)
  self.format_string(after)
}

///|
fn Formatter::force_break_line(self : Formatter) -> Unit {
  match self.format_stack.last() {
    None => (self.out.out_newline)()
    Some({ box_type, width, }) =>
      if width > self.space_left {
        match box_type {
          Fits | HBox => ()
          VBox | HVBox | HovBox | Box => self.break_line(width)
        }
      }
  }
}

///|
fn Formatter::skip_token(self : Formatter) -> Unit {
  match self.queue.pop_front() {
    None => ()
    Some({ size, length, .. }) => {
      self.left_total -= length
      self.space_left += size
    }
  }
}

///|
fn Formatter::format_pp_token(
  self : Formatter,
  size : Int,
  token : Token,
) -> Unit {
  match token {
    Text(s) => self.format_pp_text(size, s)
    Begin(off, ty) => {
      let insertion_point = self.margin - self.space_left
      if insertion_point > self.max_indent {
        self.force_break_line()
      }
      let width = self.space_left - off
      let box_type = match ty {
        VBox => VBox
        _ => if size > self.space_left { ty } else { Fits }
      }
      self.format_stack.push({ box_type, width, })
    }
    End => ignore(self.format_stack.pop())
    Newline =>
      match self.format_stack.last() {
        None => (self.out.out_newline)()
        Some({ width, .. }) => self.break_line(width)
      }
    IfNewline =>
      if self.current_indent != self.margin - self.space_left {
        self.skip_token()
      }
    Break(fits~, breaks~) => {
      let (before, off, _) = breaks
      match self.format_stack.last() {
        None => ()
        Some({ box_type, width, }) =>
          match box_type {
            HovBox =>
              if size + before.length() > self.space_left {
                self.break_new_line(breaks, width)
              } else {
                self.break_same_line(fits)
              }
            Box =>
              if self.is_new_line {
                self.break_same_line(fits)
              } else if size + before.length() > self.space_left {
                self.break_new_line(breaks, width)
              } else if self.current_indent > self.margin - width + off {
                self.break_new_line(breaks, width)
              } else {
                self.break_same_line(fits)
              }
            HVBox | VBox => self.break_new_line(breaks, width)
            Fits | HBox => self.break_same_line(fits)
          }
      }
    }
    OpenTag(tag) => {
      (self.out.out_string)((self.tags.mark_open_tag)(tag))
      self.mark_stack.push(tag)
    }
    CloseTag =>
      match self.mark_stack.pop() {
        None => ()
        Some(tag) => (self.out.out_string)((self.tags.mark_close_tag)(tag))
      }
  }
}

///|
fn Formatter::advance_left(self : Formatter) -> Unit {
  while self.queue.front() is Some({ size, token, length, }) {
    let pending_count = self.right_total - self.left_total
    if size >= 0 || pending_count >= self.space_left {
      ignore(self.queue.pop_front())
      let size = if size >= 0 { size } else { infinity }
      self.format_pp_token(size, token)
      self.left_total = length + self.left_total
    } else {
      break
    }
  }
}

///|
fn Formatter::enqueue(self : Formatter, elem : QueueElem) -> Unit {
  self.right_total += elem.length
  self.queue.push_back(elem)
}

///|
fn Formatter::enqueue_advance(self : Formatter, elem : QueueElem) -> Unit {
  self.enqueue(elem)
  self.advance_left()
}

///|
fn Formatter::initialize_scan_stack(self : Formatter) -> Unit {
  self.scan_stack.clear()
  self.scan_stack.push(sentinel())
}

///|
fn Formatter::set_size(self : Formatter, is_break : Bool) -> Unit {
  guard self.scan_stack.last() is Some({ left_total, elem, }) else { return }
  let size = elem.size
  if left_total < self.left_total {
    self.initialize_scan_stack()
  } else {
    match elem.token {
      Break(..) =>
        if is_break {
          elem.size = self.right_total + size
          ignore(self.scan_stack.pop())
        }
      Begin(_) =>
        if !is_break {
          elem.size = self.right_total + size
          ignore(self.scan_stack.pop())
        }
      _ => ()
    }
  }
}

///|
fn Formatter::scan_push(self : Formatter, b : Bool, elem : QueueElem) -> Unit {
  self.enqueue(elem)
  if b {
    self.set_size(true)
  }
  self.scan_stack.push({ left_total: self.right_total, elem, })
}

///|
fn Formatter::open_box_gen(
  self : Formatter,
  indent : Int,
  ty : BoxType,
) -> Unit {
  self.curr_depth += 1
  if self.curr_depth < self.max_boxes {
    self.scan_push(false, {
      size: -self.right_total,
      token: Begin(indent, ty),
      length: 0,
    })
  } else if self.curr_depth == self.max_boxes {
    self.enqueue_string(self.ellipsis)
  }
}

///|
fn Formatter::enqueue_string(self : Formatter, s : String) -> Unit {
  self.enqueue_advance({ size: s.length(), token: Text(s), length: s.length(), })
}

///|
fn Formatter::rinit(self : Formatter) -> Unit {
  self.left_total = 1
  self.right_total = 1
  self.queue.clear()
  self.initialize_scan_stack()
  self.format_stack.clear()
  self.tag_stack.clear()
  self.mark_stack.clear()
  self.current_indent = 0
  self.curr_depth = 0
  self.space_left = self.margin
  self.open_box_gen(0, HovBox)
}

///|
fn Formatter::flush_queue(self : Formatter, newline : Bool) -> Unit {
  for _ in 0..<self.tag_stack.length() {
    self.close_tag()
  }
  while self.curr_depth > 1 {
    self.close_box()
  }
  self.right_total = infinity
  self.advance_left()
  if newline {
    (self.out.out_newline)()
  }
  self.rinit()
}

// Public printing interface

///|
/// Prints a string (upstream `pp_print_string`).
pub fn Formatter::print_string(self : Formatter, s : String) -> Unit {
  self.print_as(s.length(), s)
}

///|
/// Prints a string that is considered to have the width [size].
pub fn Formatter::print_as(self : Formatter, size : Int, s : String) -> Unit {
  if self.curr_depth < self.max_boxes {
    self.enqueue_advance({ size, token: Text(s), length: size, })
  }
}

///|
/// Prints a character.
pub fn Formatter::print_char(self : Formatter, c : Char) -> Unit {
  self.print_as(1, c.to_string())
}

///|
/// Prints an integer.
pub fn Formatter::print_int(self : Formatter, n : Int) -> Unit {
  self.print_string(n.to_string())
}

///|
/// Opens a compacting box with enhanced structure (`@[<b n>`).
pub fn Formatter::open_box(self : Formatter, indent : Int) -> Unit {
  self.open_box_gen(indent, Box)
}

///|
/// Opens a horizontal box.
pub fn Formatter::open_hbox(self : Formatter) -> Unit {
  self.open_box_gen(0, HBox)
}

///|
/// Opens a vertical box: every break hint splits the line.
pub fn Formatter::open_vbox(self : Formatter, indent : Int) -> Unit {
  self.open_box_gen(indent, VBox)
}

///|
/// Opens a horizontal/vertical box.
pub fn Formatter::open_hvbox(self : Formatter, indent : Int) -> Unit {
  self.open_box_gen(indent, HVBox)
}

///|
/// Opens a horizontal-or-vertical compacting box.
pub fn Formatter::open_hovbox(self : Formatter, indent : Int) -> Unit {
  self.open_box_gen(indent, HovBox)
}

///|
/// Closes the most recently opened box.
pub fn Formatter::close_box(self : Formatter) -> Unit {
  if self.curr_depth > 1 {
    if self.curr_depth < self.max_boxes {
      self.enqueue({ size: 0, token: End, length: 0, })
      self.set_size(true)
      self.set_size(false)
    }
    self.curr_depth -= 1
  }
}

///|
/// Opens a semantic tag.
pub fn Formatter::open_tag(self : Formatter, tag : String) -> Unit {
  if self.print_tags {
    self.tag_stack.push(tag)
    (self.tags.print_open_tag)(tag)
  }
  if self.mark_tags {
    self.enqueue({ size: 0, token: OpenTag(tag), length: 0, })
  }
}

///|
/// Closes the most recently opened semantic tag.
pub fn Formatter::close_tag(self : Formatter) -> Unit {
  if self.mark_tags {
    self.enqueue({ size: 0, token: CloseTag, length: 0, })
  }
  if self.print_tags {
    match self.tag_stack.pop() {
      None => ()
      Some(tag) => (self.tags.print_close_tag)(tag)
    }
  }
}

///|
/// A general break hint: prints [width] spaces if the line is not split,
/// otherwise splits the line and adds [offset] to the indentation.
pub fn Formatter::print_break(
  self : Formatter,
  width : Int,
  offset : Int,
) -> Unit {
  self.print_custom_break(fits=("", width, ""), breaks=("", offset, ""))
}

///|
/// A break hint that prints `fits` if the line is not split and `breaks`
/// otherwise (upstream `pp_print_custom_break`).
pub fn Formatter::print_custom_break(
  self : Formatter,
  fits~ : (String, Int, String),
  breaks~ : (String, Int, String),
) -> Unit {
  let (before, width, after) = fits
  if self.curr_depth < self.max_boxes {
    self.scan_push(true, {
      size: -self.right_total,
      token: Break(fits~, breaks~),
      length: before.length() + width + after.length(),
    })
  }
}

///|
/// A break hint that prints a space if the line is not split.
pub fn Formatter::print_space(self : Formatter) -> Unit {
  self.print_break(1, 0)
}

///|
/// A break hint that prints nothing if the line is not split.
pub fn Formatter::print_cut(self : Formatter) -> Unit {
  self.print_break(0, 0)
}

///|
/// Forces a new line in the current box.
pub fn Formatter::force_newline(self : Formatter) -> Unit {
  if self.curr_depth < self.max_boxes {
    self.enqueue_advance({ size: 0, token: Newline, length: 0, })
  }
}

///|
/// Prints the next token only if the line has just been split.
pub fn Formatter::print_if_newline(self : Formatter) -> Unit {
  if self.curr_depth < self.max_boxes {
    self.enqueue_advance({ size: 0, token: IfNewline, length: 0, })
  }
}

///|
/// Closes all boxes and tags, prints all pending material and resets the
/// formatter.
pub fn Formatter::print_flush(self : Formatter) -> Unit {
  self.flush_queue(false)
  (self.out.out_flush)()
}

///|
/// Like `print_flush`, but also outputs a new line.
pub fn Formatter::print_newline(self : Formatter) -> Unit {
  self.flush_queue(true)
  (self.out.out_flush)()
}

// Configuration

///|
/// Sets whether tags are printed, i.e., the `print_*_tag` functions are
/// called.
pub fn Formatter::set_print_tags(self : Formatter, enabled : Bool) -> Unit {
  self.print_tags = enabled
}

///|
/// Sets whether tags are marked, i.e., the `mark_*_tag` markers are output.
pub fn Formatter::set_mark_tags(self : Formatter, enabled : Bool) -> Unit {
  self.mark_tags = enabled
}

///|
/// Whether tags are printed.
pub fn Formatter::get_print_tags(self : Formatter) -> Bool {
  self.print_tags
}

///|
/// Whether tags are marked.
pub fn Formatter::get_mark_tags(self : Formatter) -> Bool {
  self.mark_tags
}

///|
/// Sets both `print_tags` and `mark_tags`.
pub fn Formatter::set_tags(self : Formatter, enabled : Bool) -> Unit {
  self.print_tags = enabled
  self.mark_tags = enabled
}

///|
/// The current tag functions.
pub fn Formatter::get_tag_functions(self : Formatter) -> TagFunctions {
  self.tags
}

///|
/// Sets the tag functions.
pub fn Formatter::set_tag_functions(
  self : Formatter,
  tags : TagFunctions,
) -> Unit {
  self.tags = tags
}

///|
/// The current output functions.
pub fn Formatter::get_out_functions(self : Formatter) -> OutFunctions {
  self.out
}

///|
/// Sets the output functions.
pub fn Formatter::set_out_functions(
  self : Formatter,
  out : OutFunctions,
) -> Unit {
  self.out = out
}

///|
/// The right margin (78 by default).
pub fn Formatter::get_margin(self : Formatter) -> Int {
  self.margin
}

///|
fn limit(n : Int) -> Int {
  if n < infinity {
    n
  } else {
    infinity - 1
  }
}

///|
fn Formatter::set_min_space_left(self : Formatter, n : Int) -> Unit {
  if n >= 1 {
    let n = limit(n)
    self.min_space_left = n
    self.max_indent = self.margin - self.min_space_left
    self.rinit()
  }
}

///|
/// Sets the maximum indentation (68 by default).
pub fn Formatter::set_max_indent(self : Formatter, n : Int) -> Unit {
  if n > 1 {
    self.set_min_space_left(self.margin - n)
  }
}

///|
/// The maximum indentation.
pub fn Formatter::get_max_indent(self : Formatter) -> Int {
  self.max_indent
}

///|
/// Sets the right margin.
pub fn Formatter::set_margin(self : Formatter, n : Int) -> Unit {
  if n >= 1 {
    self.margin = limit(n)
    let new_max_indent = if self.max_indent <= self.margin {
      self.max_indent
    } else {
      let a = self.margin - self.min_space_left
      let b = self.margin / 2
      let m = if a > b { a } else { b }
      if m > 1 {
        m
      } else {
        1
      }
    }
    self.set_max_indent(new_max_indent)
  }
}

///|
/// Sets the maximum number of simultaneously open boxes.
pub fn Formatter::set_max_boxes(self : Formatter, n : Int) -> Unit {
  if n > 1 {
    self.max_boxes = n
  }
}

///|
/// Sets the text printed for boxes nested deeper than the maximum.
pub fn Formatter::set_ellipsis_text(self : Formatter, s : String) -> Unit {
  self.ellipsis = s
}

///|
pub extend Formatter with Logger::{
  write_view,
  write_string,
  write_char,
  write_string_interpolation,
  write,
}

///|
#deprecated
#warnings("-deprecated")
pub extend Formatter with Logger::{write_substring}

///|
pub impl Logger for Formatter with fn write_string(self, s) {
  self.print_string(s)
}

///|
pub impl Logger for Formatter with fn write_view(self, s) {
  self.print_string(s.to_owned())
}

///|
pub impl Logger for Formatter with fn write_char(self, c) {
  self.print_char(c)
}
