// A faithful port of the subset of OCaml's `Format` pretty-printing engine
// that Ogre relies on (structural `b`/`v`/`hov` boxes, break hints and forced
// newlines, margin 78, max indent 68). Upstream prints documents with
// `Sexp.pp_hum` inside `Format` boxes, so long facts are wrapped exactly by
// this algorithm.

///|
priv enum BoxType {
  VBox
  HovBox
  Box
  Fits
}

///|
priv enum PpToken {
  Text(String)
  Begin(Int32, BoxType)
  End
  Break(Int32, Int32)
  Newline
}

///|
priv struct QElem {
  mut size : Int32
  token : PpToken
  length : Int32
}

///|
priv struct ScanElem {
  left_total : Int32
  elem : QElem
}

///|
priv struct PpBox {
  box_type : BoxType
  width : Int32
}

///|
priv struct Formatter {
  queue : Array[QElem]
  mut head : Int32
  scan_stack : Array[ScanElem]
  format_stack : Array[PpBox]
  margin : Int32
  max_indent : Int32
  mut space_left : Int32
  mut current_indent : Int32
  mut is_new_line : Bool
  mut left_total : Int32
  mut right_total : Int32
  mut curr_depth : Int32
  out : StringBuilder
}

///|
let pp_infinity : Int32 = 1000000010

///|
fn Formatter::new() -> Formatter {
  let sys_tok = { size: -1, token: Begin(0, HovBox), length: 0, }
  let fmt : Formatter = {
    queue: [sys_tok],
    head: 0,
    scan_stack: [],
    format_stack: [],
    margin: 78,
    max_indent: 68,
    space_left: 78,
    current_indent: 0,
    is_new_line: true,
    left_total: 1,
    right_total: 1,
    curr_depth: 1,
    out: StringBuilder(),
  }
  fmt.initialize_scan_stack()
  fmt.scan_stack.push({ left_total: 1, elem: sys_tok, })
  fmt
}

///|
fn Formatter::initialize_scan_stack(self : Formatter) -> Unit {
  self.scan_stack.clear()
  self.scan_stack.push({
    left_total: -1,
    elem: { size: -1, token: Text(""), length: 0, },
  })
}

///|
fn Formatter::enqueue(self : Formatter, elem : QElem) -> Unit {
  self.right_total += elem.length
  self.queue.push(elem)
}

///|
fn Formatter::output_spaces(self : Formatter, n : Int32) -> Unit {
  for _ in 0..<n {
    self.out.write_char(' ')
  }
}

///|
fn Formatter::break_new_line(
  self : Formatter,
  offset : Int32,
  width : Int32,
) -> Unit {
  self.out.write_char('\n')
  self.is_new_line = true
  let indent = self.margin - width + offset
  let real_indent = if self.max_indent < indent {
    self.max_indent
  } else {
    indent
  }
  self.current_indent = real_indent
  self.space_left = self.margin - self.current_indent
  self.output_spaces(self.current_indent)
}

///|
fn Formatter::break_same_line(self : Formatter, width : Int32) -> Unit {
  self.space_left -= width
  self.output_spaces(width)
}

///|
fn Formatter::force_break_line(self : Formatter) -> Unit {
  match self.format_stack.last() {
    None => self.out.write_char('\n')
    Some({ box_type, width, }) =>
      if width > self.space_left {
        match box_type {
          Fits => ()
          VBox | HovBox | Box => self.break_new_line(0, width)
        }
      }
  }
}

///|
fn Formatter::format_token(
  self : Formatter,
  size : Int32,
  token : PpToken,
) -> Unit {
  match token {
    Text(s) => {
      self.space_left -= size
      self.out.write_string(s)
      self.is_new_line = false
    }
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
        None => self.out.write_char('\n')
        Some({ width, .. }) => self.break_new_line(0, width)
      }
    Break(fits, off) =>
      match self.format_stack.last() {
        None => ()
        Some({ box_type, width, }) =>
          match box_type {
            HovBox =>
              if size > self.space_left {
                self.break_new_line(off, width)
              } else {
                self.break_same_line(fits)
              }
            Box =>
              if self.is_new_line {
                self.break_same_line(fits)
              } else if size > self.space_left {
                self.break_new_line(off, width)
              } else if self.current_indent > self.margin - width + off {
                self.break_new_line(off, width)
              } else {
                self.break_same_line(fits)
              }
            Fits => self.break_same_line(fits)
            VBox => self.break_new_line(off, width)
          }
      }
  }
}

///|
fn Formatter::advance_left(self : Formatter) -> Unit {
  while self.head < self.queue.length() {
    let elem = self.queue[self.head]
    let pending_count = self.right_total - self.left_total
    if elem.size >= 0 || pending_count >= self.space_left {
      self.head += 1
      let size = if elem.size >= 0 { elem.size } else { pp_infinity }
      self.format_token(size, elem.token)
      self.left_total = elem.length + self.left_total
    } else {
      break
    }
  }
}

///|
fn Formatter::enqueue_advance(self : Formatter, elem : QElem) -> Unit {
  self.enqueue(elem)
  self.advance_left()
}

///|
fn Formatter::set_size(self : Formatter, is_break : Bool) -> Unit {
  guard self.scan_stack.last() is Some({ left_total, elem, }) else { return }
  let size = elem.size
  if left_total < self.left_total {
    self.initialize_scan_stack()
  } else {
    match elem.token {
      Break(_, _) =>
        if is_break {
          elem.size = self.right_total + size
          ignore(self.scan_stack.pop())
        }
      Begin(_, _) =>
        if !is_break {
          elem.size = self.right_total + size
          ignore(self.scan_stack.pop())
        }
      _ => ()
    }
  }
}

///|
fn Formatter::scan_push(self : Formatter, set : Bool, elem : QElem) -> Unit {
  self.enqueue(elem)
  if set {
    self.set_size(true)
  }
  self.scan_stack.push({ left_total: self.right_total, elem, })
}

///|
fn Formatter::open_box_gen(
  self : Formatter,
  indent : Int32,
  ty : BoxType,
) -> Unit {
  self.curr_depth += 1
  self.scan_push(false, {
    size: -self.right_total,
    token: Begin(indent, ty),
    length: 0,
  })
}

///|
/// `pp_open_box` (a structural `b` box).
fn Formatter::open_box(self : Formatter, indent : Int32) -> Unit {
  self.open_box_gen(indent, Box)
}

///|
fn Formatter::open_vbox(self : Formatter, indent : Int32) -> Unit {
  self.open_box_gen(indent, VBox)
}

///|
fn Formatter::close_box(self : Formatter) -> Unit {
  if self.curr_depth > 1 {
    self.enqueue({ size: 0, token: End, length: 0, })
    self.set_size(true)
    self.set_size(false)
    self.curr_depth -= 1
  }
}

///|
fn Formatter::print_string(self : Formatter, s : String) -> Unit {
  let size = s.length()
  self.enqueue_advance({ size, token: Text(s), length: size, })
}

///|
fn Formatter::print_break(
  self : Formatter,
  width : Int32,
  offset : Int32,
) -> Unit {
  self.scan_push(true, {
    size: -self.right_total,
    token: Break(width, offset),
    length: width,
  })
}

///|
fn Formatter::print_space(self : Formatter) -> Unit {
  self.print_break(1, 0)
}

///|
fn Formatter::force_newline(self : Formatter) -> Unit {
  self.enqueue_advance({ size: 0, token: Newline, length: 0, })
}

///|
/// Flushes the queue (`pp_print_flush`) and returns everything printed.
fn Formatter::contents(self : Formatter) -> String {
  while self.curr_depth > 1 {
    self.close_box()
  }
  self.right_total = pp_infinity
  self.advance_left()
  self.out.to_string()
}
