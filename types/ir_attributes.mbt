///|
let sub_extern_attr = "extern"

///|
let sub_leaf_attr = "leaf"

///|
let sub_malloc_attr = "malloc"

///|
let sub_const_attr = "const"

///|
let sub_noreturn_attr = "noreturn"

///|
let sub_nothrow_attr = "nothrow"

///|
let sub_returns_twice_attr = "returns-twice"

///|
let sub_entry_point_attr = "entry-point"

///|
let sub_intrinsic_attr = "intrinsic"

///|
let sub_pure_attr = "pure"

///|
let arg_warn_unused_attr = "warn-unused"

///|
let arg_alloc_size_attr = "alloc-size"

///|
let arg_format_attr = "format"

///|
let arg_restricted_attr = "restricted"

///|
let arg_nonnull_attr = "nonnull"

///|
let term_filename_attr = "filename"

///|
let term_format_attr = "format"

///|
let term_origin_attr = "origin"

///|
let term_comment_attr = "comment"

///|
let term_python_attr = "python"

///|
let term_shell_attr = "shell"

///|
let term_weight_attr = "weight"

///|
let term_color_attr = "color"

///|
let term_foreground_attr = "foreground"

///|
let term_background_attr = "background"

///|
let term_tainted_reg_attr = "tainted-reg"

///|
let term_tainted_ptr_attr = "tainted-ptr"

///|
let term_synthetic_attr = "synthetic"

///|
let term_visited_attr = "visited"

///|
let term_live_attr = "live"

///|
let term_dead_attr = "dead"

///|
let term_precondition_attr = "precondition"

///|
let term_invariant_attr = "invariant"

///|
let term_postcondition_attr = "postcondition"

///|
let term_mark_attr = "mark"

///|
pub(all) enum IrColor {
  IrBlack
  IrRed
  IrGreen
  IrYellow
  IrBlue
  IrMagenta
  IrCyan
  IrWhite
  IrGray
} derive(Eq, Debug)

///|
pub fn IrColor::to_string(self : IrColor) -> String {
  match self {
    IrBlack => "black"
    IrRed => "red"
    IrGreen => "green"
    IrYellow => "yellow"
    IrBlue => "blue"
    IrMagenta => "magenta"
    IrCyan => "cyan"
    IrWhite => "white"
    IrGray => "gray"
  }
}

///|
pub fn IrColor::of_string(text : String) -> IrColor? {
  match text {
    "black" => Some(IrBlack)
    "red" => Some(IrRed)
    "green" => Some(IrGreen)
    "yellow" => Some(IrYellow)
    "blue" => Some(IrBlue)
    "magenta" => Some(IrMagenta)
    "cyan" => Some(IrCyan)
    "white" => Some(IrWhite)
    "gray" => Some(IrGray)
    _ => None
  }
}

///|
pub fn Attr::flag(key : String) -> Attr {
  Attr::new(key~, value="true")
}

///|
pub fn Attr::filename(filename : String) -> Attr {
  Attr::new(key=term_filename_attr, value=filename)
}

///|
pub fn Attr::format(format : String) -> Attr {
  Attr::new(key=term_format_attr, value=format)
}

///|
pub fn Attr::origin(tid : Tid) -> Attr {
  Attr::new(key=term_origin_attr, value=tid.to_string())
}

///|
pub fn Attr::python(script : String) -> Attr {
  Attr::new(key=term_python_attr, value=script)
}

///|
pub fn Attr::shell(script : String) -> Attr {
  Attr::new(key=term_shell_attr, value=script)
}

///|
pub fn Attr::weight(weight : Double) -> Attr {
  Attr::new(key=term_weight_attr, value=weight.to_string())
}

///|
pub fn Attr::color(color : IrColor) -> Attr {
  Attr::new(key=term_color_attr, value=color.to_string())
}

///|
pub fn Attr::foreground(color : IrColor) -> Attr {
  Attr::new(key=term_foreground_attr, value=color.to_string())
}

///|
pub fn Attr::background(color : IrColor) -> Attr {
  Attr::new(key=term_background_attr, value=color.to_string())
}

///|
pub fn Attr::tainted_reg(seed : Tid) -> Attr {
  Attr::new(key=term_tainted_reg_attr, value=seed.to_string())
}

///|
pub fn Attr::tainted_ptr(seed : Tid) -> Attr {
  Attr::new(key=term_tainted_ptr_attr, value=seed.to_string())
}

///|
pub fn Attr::synthetic() -> Attr {
  Attr::flag(term_synthetic_attr)
}

///|
pub fn Attr::visited() -> Attr {
  Attr::flag(term_visited_attr)
}

///|
pub fn Attr::live() -> Attr {
  Attr::flag(term_live_attr)
}

///|
pub fn Attr::dead() -> Attr {
  Attr::flag(term_dead_attr)
}

///|
pub fn Attr::mark(value? : String = "true") -> Attr {
  Attr::new(key=term_mark_attr, value~)
}

///|
pub fn Attr::precondition(exp : Exp) -> Attr {
  Attr::new(key=term_precondition_attr, value=exp.to_string())
}

///|
pub fn Attr::invariant(exp : Exp) -> Attr {
  Attr::new(key=term_invariant_attr, value=exp.to_string())
}

///|
pub fn Attr::postcondition(exp : Exp) -> Attr {
  Attr::new(key=term_postcondition_attr, value=exp.to_string())
}

///|
pub fn Attr::sub_extern() -> Attr {
  Attr::flag(sub_extern_attr)
}

///|
pub fn Attr::sub_leaf() -> Attr {
  Attr::flag(sub_leaf_attr)
}

///|
pub fn Attr::sub_malloc() -> Attr {
  Attr::flag(sub_malloc_attr)
}

///|
pub fn Attr::sub_const() -> Attr {
  Attr::flag(sub_const_attr)
}

///|
pub fn Attr::sub_noreturn() -> Attr {
  Attr::flag(sub_noreturn_attr)
}

///|
pub fn Attr::sub_nothrow() -> Attr {
  Attr::flag(sub_nothrow_attr)
}

///|
pub fn Attr::sub_returns_twice() -> Attr {
  Attr::flag(sub_returns_twice_attr)
}

///|
pub fn Attr::sub_entry_point() -> Attr {
  Attr::flag(sub_entry_point_attr)
}

///|
pub fn Attr::sub_intrinsic() -> Attr {
  Attr::flag(sub_intrinsic_attr)
}

///|
pub fn Attr::sub_pure() -> Attr {
  Attr::flag(sub_pure_attr)
}

///|
pub fn Arg::warn_unused() -> Attr {
  Attr::flag(arg_warn_unused_attr)
}

///|
pub fn Arg::alloc_size() -> Attr {
  Attr::flag(arg_alloc_size_attr)
}

///|
pub fn Arg::format(format : String) -> Attr {
  Attr::new(key=arg_format_attr, value=format)
}

///|
pub fn Arg::restricted() -> Attr {
  Attr::flag(arg_restricted_attr)
}

///|
pub fn Arg::nonnull() -> Attr {
  Attr::flag(arg_nonnull_attr)
}

///|
pub fn[T] Term::with_flag(self : Term[T], key : String) -> Term[T] {
  self.set_attr(Attr::flag(key))
}

///|
pub fn[T] Term::without_flag(self : Term[T], key : String) -> Term[T] {
  self.del_attr(key)
}

///|
pub fn[T] Term::has_flag(self : Term[T], key : String) -> Bool {
  self.has_attr(key)
}

///|
fn[T] term_double(term : Term[T], key : String) -> Double? {
  match term.get_attr(key) {
    Some(text) =>
      try @string.parse_double(text) catch {
        _ => None
      } noraise {
        value => Some(value)
      }
    None => None
  }
}

///|
fn[T] term_tid(term : Term[T], key : String) -> Tid? {
  match term.get_attr(key) {
    Some(text) =>
      match Tid::from_string(text) {
        Ok(tid) => Some(tid)
        Err(_) => None
      }
    None => None
  }
}

///|
pub fn[T] Term::with_filename(self : Term[T], filename : String) -> Term[T] {
  self.set_attr(Attr::filename(filename))
}

///|
pub fn[T] Term::without_filename(self : Term[T]) -> Term[T] {
  self.del_attr(term_filename_attr)
}

///|
pub fn[T] Term::filename(self : Term[T]) -> String? {
  self.get_attr(term_filename_attr)
}

///|
pub fn[T] Term::with_format(self : Term[T], format : String) -> Term[T] {
  self.set_attr(Attr::format(format))
}

///|
pub fn[T] Term::without_format(self : Term[T]) -> Term[T] {
  self.del_attr(term_format_attr)
}

///|
pub fn[T] Term::format(self : Term[T]) -> String? {
  self.get_attr(term_format_attr)
}

///|
pub fn[T] Term::with_origin(self : Term[T], tid : Tid) -> Term[T] {
  self.set_attr(Attr::origin(tid))
}

///|
pub fn[T] Term::without_origin(self : Term[T]) -> Term[T] {
  self.del_attr(term_origin_attr)
}

///|
pub fn[T] Term::origin(self : Term[T]) -> Tid? {
  term_tid(self, term_origin_attr)
}

///|
pub fn[T] Term::origin_text(self : Term[T]) -> String? {
  self.get_attr(term_origin_attr)
}

///|
pub fn[T] Term::has_origin(self : Term[T], tid : Tid) -> Bool {
  self.origin_text() == Some(tid.to_string())
}

///|
pub fn[T] Term::with_precondition(self : Term[T], exp : Exp) -> Term[T] {
  self.set_attr(Attr::precondition(exp))
}

///|
pub fn[T] Term::without_precondition(self : Term[T]) -> Term[T] {
  self.del_attr(term_precondition_attr)
}

///|
pub fn[T] Term::precondition(self : Term[T]) -> String? {
  self.get_attr(term_precondition_attr)
}

///|
pub fn[T] Term::has_precondition(self : Term[T], exp : Exp) -> Bool {
  self.precondition() == Some(exp.to_string())
}

///|
pub fn[T] Term::with_invariant(self : Term[T], exp : Exp) -> Term[T] {
  self.set_attr(Attr::invariant(exp))
}

///|
pub fn[T] Term::without_invariant(self : Term[T]) -> Term[T] {
  self.del_attr(term_invariant_attr)
}

///|
pub fn[T] Term::invariant(self : Term[T]) -> String? {
  self.get_attr(term_invariant_attr)
}

///|
pub fn[T] Term::has_invariant(self : Term[T], exp : Exp) -> Bool {
  self.invariant() == Some(exp.to_string())
}

///|
pub fn[T] Term::with_postcondition(self : Term[T], exp : Exp) -> Term[T] {
  self.set_attr(Attr::postcondition(exp))
}

///|
pub fn[T] Term::without_postcondition(self : Term[T]) -> Term[T] {
  self.del_attr(term_postcondition_attr)
}

///|
pub fn[T] Term::postcondition(self : Term[T]) -> String? {
  self.get_attr(term_postcondition_attr)
}

///|
pub fn[T] Term::has_postcondition(self : Term[T], exp : Exp) -> Bool {
  self.postcondition() == Some(exp.to_string())
}

///|
pub fn[T] Term::with_comment(self : Term[T], text : String) -> Term[T] {
  self.set_attr(Attr::comment(text))
}

///|
pub fn[T] Term::without_comment(self : Term[T]) -> Term[T] {
  self.del_attr(term_comment_attr)
}

///|
pub fn[T] Term::comment(self : Term[T]) -> String? {
  self.get_attr(term_comment_attr)
}

///|
pub fn[T] Term::with_python(self : Term[T], script : String) -> Term[T] {
  self.set_attr(Attr::python(script))
}

///|
pub fn[T] Term::without_python(self : Term[T]) -> Term[T] {
  self.del_attr(term_python_attr)
}

///|
pub fn[T] Term::python(self : Term[T]) -> String? {
  self.get_attr(term_python_attr)
}

///|
pub fn[T] Term::with_shell(self : Term[T], script : String) -> Term[T] {
  self.set_attr(Attr::shell(script))
}

///|
pub fn[T] Term::without_shell(self : Term[T]) -> Term[T] {
  self.del_attr(term_shell_attr)
}

///|
pub fn[T] Term::shell(self : Term[T]) -> String? {
  self.get_attr(term_shell_attr)
}

///|
pub fn[T] Term::with_weight(self : Term[T], weight : Double) -> Term[T] {
  self.set_attr(Attr::weight(weight))
}

///|
pub fn[T] Term::without_weight(self : Term[T]) -> Term[T] {
  self.del_attr(term_weight_attr)
}

///|
pub fn[T] Term::weight(self : Term[T]) -> Double? {
  term_double(self, term_weight_attr)
}

///|
fn[T] term_color(term : Term[T], key : String) -> IrColor? {
  match term.get_attr(key) {
    Some(text) => IrColor::of_string(text)
    None => None
  }
}

///|
pub fn[T] Term::with_color(self : Term[T], color : IrColor) -> Term[T] {
  self.set_attr(Attr::color(color))
}

///|
pub fn[T] Term::without_color(self : Term[T]) -> Term[T] {
  self.del_attr(term_color_attr)
}

///|
pub fn[T] Term::color(self : Term[T]) -> IrColor? {
  term_color(self, term_color_attr)
}

///|
pub fn[T] Term::has_color(self : Term[T], color : IrColor) -> Bool {
  self.color() == Some(color)
}

///|
pub fn[T] Term::with_foreground(self : Term[T], color : IrColor) -> Term[T] {
  self.set_attr(Attr::foreground(color))
}

///|
pub fn[T] Term::without_foreground(self : Term[T]) -> Term[T] {
  self.del_attr(term_foreground_attr)
}

///|
pub fn[T] Term::foreground(self : Term[T]) -> IrColor? {
  term_color(self, term_foreground_attr)
}

///|
pub fn[T] Term::has_foreground(self : Term[T], color : IrColor) -> Bool {
  self.foreground() == Some(color)
}

///|
pub fn[T] Term::with_background(self : Term[T], color : IrColor) -> Term[T] {
  self.set_attr(Attr::background(color))
}

///|
pub fn[T] Term::without_background(self : Term[T]) -> Term[T] {
  self.del_attr(term_background_attr)
}

///|
pub fn[T] Term::background(self : Term[T]) -> IrColor? {
  term_color(self, term_background_attr)
}

///|
pub fn[T] Term::has_background(self : Term[T], color : IrColor) -> Bool {
  self.background() == Some(color)
}

///|
fn taint_seed(text : String) -> Tid? {
  match Tid::from_string(text) {
    Ok(tid) => Some(tid)
    Err(_) => None
  }
}

///|
fn[T] term_taint_seed(term : Term[T], key : String) -> Tid? {
  match term.get_attr(key) {
    Some(text) => taint_seed(text)
    None => None
  }
}

///|
pub fn[T] Term::with_tainted_reg(self : Term[T], seed : Tid) -> Term[T] {
  self.set_attr(Attr::tainted_reg(seed))
}

///|
pub fn[T] Term::without_tainted_reg(self : Term[T]) -> Term[T] {
  self.del_attr(term_tainted_reg_attr)
}

///|
pub fn[T] Term::tainted_reg(self : Term[T]) -> Tid? {
  term_taint_seed(self, term_tainted_reg_attr)
}

///|
pub fn[T] Term::tainted_reg_text(self : Term[T]) -> String? {
  self.get_attr(term_tainted_reg_attr)
}

///|
pub fn[T] Term::has_tainted_reg(self : Term[T], seed : Tid) -> Bool {
  self.tainted_reg_text() == Some(seed.to_string())
}

///|
pub fn[T] Term::taints_reg(self : Term[T]) -> Bool {
  self.has_attr(term_tainted_reg_attr)
}

///|
pub fn[T] Term::with_tainted_ptr(self : Term[T], seed : Tid) -> Term[T] {
  self.set_attr(Attr::tainted_ptr(seed))
}

///|
pub fn[T] Term::without_tainted_ptr(self : Term[T]) -> Term[T] {
  self.del_attr(term_tainted_ptr_attr)
}

///|
pub fn[T] Term::tainted_ptr(self : Term[T]) -> Tid? {
  term_taint_seed(self, term_tainted_ptr_attr)
}

///|
pub fn[T] Term::tainted_ptr_text(self : Term[T]) -> String? {
  self.get_attr(term_tainted_ptr_attr)
}

///|
pub fn[T] Term::has_tainted_ptr(self : Term[T], seed : Tid) -> Bool {
  self.tainted_ptr_text() == Some(seed.to_string())
}

///|
pub fn[T] Term::taints_ptr(self : Term[T]) -> Bool {
  self.has_attr(term_tainted_ptr_attr)
}

///|
pub fn[T] Term::taints(self : Term[T]) -> Bool {
  self.taints_reg() || self.taints_ptr()
}

///|
pub fn[T] Term::with_synthetic(self : Term[T]) -> Term[T] {
  self.with_flag(term_synthetic_attr)
}

///|
pub fn[T] Term::without_synthetic(self : Term[T]) -> Term[T] {
  self.without_flag(term_synthetic_attr)
}

///|
pub fn[T] Term::is_synthetic(self : Term[T]) -> Bool {
  self.has_flag(term_synthetic_attr)
}

///|
pub fn[T] Term::with_visited(self : Term[T]) -> Term[T] {
  self.with_flag(term_visited_attr)
}

///|
pub fn[T] Term::without_visited(self : Term[T]) -> Term[T] {
  self.without_flag(term_visited_attr)
}

///|
pub fn[T] Term::is_visited(self : Term[T]) -> Bool {
  self.has_flag(term_visited_attr)
}

///|
pub fn[T] Term::with_live(self : Term[T]) -> Term[T] {
  self.with_flag(term_live_attr)
}

///|
pub fn[T] Term::without_live(self : Term[T]) -> Term[T] {
  self.without_flag(term_live_attr)
}

///|
pub fn[T] Term::is_live(self : Term[T]) -> Bool {
  self.has_flag(term_live_attr)
}

///|
pub fn[T] Term::with_dead(self : Term[T]) -> Term[T] {
  self.with_flag(term_dead_attr)
}

///|
pub fn[T] Term::without_dead(self : Term[T]) -> Term[T] {
  self.without_flag(term_dead_attr)
}

///|
pub fn[T] Term::is_dead(self : Term[T]) -> Bool {
  self.has_flag(term_dead_attr)
}

///|
pub fn Term::with_warn_unused(self : Term[Arg]) -> Term[Arg] {
  self.set_attr(Arg::warn_unused())
}

///|
pub fn Term::without_warn_unused(self : Term[Arg]) -> Term[Arg] {
  self.without_flag(arg_warn_unused_attr)
}

///|
pub fn Term::is_warn_unused(self : Term[Arg]) -> Bool {
  self.has_flag(arg_warn_unused_attr)
}

///|
pub fn Term::with_alloc_size(self : Term[Arg]) -> Term[Arg] {
  self.set_attr(Arg::alloc_size())
}

///|
pub fn Term::without_alloc_size(self : Term[Arg]) -> Term[Arg] {
  self.without_flag(arg_alloc_size_attr)
}

///|
pub fn Term::is_alloc_size(self : Term[Arg]) -> Bool {
  self.has_flag(arg_alloc_size_attr)
}

///|
pub fn Term::with_arg_format(self : Term[Arg], format : String) -> Term[Arg] {
  self.set_attr(Arg::format(format))
}

///|
pub fn Term::without_arg_format(self : Term[Arg]) -> Term[Arg] {
  self.del_attr(arg_format_attr)
}

///|
pub fn Term::arg_format(self : Term[Arg]) -> String? {
  self.get_attr(arg_format_attr)
}

///|
pub fn Term::with_restricted(self : Term[Arg]) -> Term[Arg] {
  self.set_attr(Arg::restricted())
}

///|
pub fn Term::without_restricted(self : Term[Arg]) -> Term[Arg] {
  self.without_flag(arg_restricted_attr)
}

///|
pub fn Term::is_restricted(self : Term[Arg]) -> Bool {
  self.has_flag(arg_restricted_attr)
}

///|
pub fn Term::with_nonnull(self : Term[Arg]) -> Term[Arg] {
  self.set_attr(Arg::nonnull())
}

///|
pub fn Term::without_nonnull(self : Term[Arg]) -> Term[Arg] {
  self.without_flag(arg_nonnull_attr)
}

///|
pub fn Term::is_nonnull(self : Term[Arg]) -> Bool {
  self.has_flag(arg_nonnull_attr)
}

///|
pub fn Term::with_extern(self : Term[Sub]) -> Term[Sub] {
  self.with_flag(sub_extern_attr)
}

///|
pub fn Term::without_extern(self : Term[Sub]) -> Term[Sub] {
  self.without_flag(sub_extern_attr)
}

///|
pub fn Term::is_extern(self : Term[Sub]) -> Bool {
  self.has_flag(sub_extern_attr)
}

///|
pub fn Term::with_leaf(self : Term[Sub]) -> Term[Sub] {
  self.with_flag(sub_leaf_attr)
}

///|
pub fn Term::without_leaf(self : Term[Sub]) -> Term[Sub] {
  self.without_flag(sub_leaf_attr)
}

///|
pub fn Term::is_leaf(self : Term[Sub]) -> Bool {
  self.has_flag(sub_leaf_attr)
}

///|
pub fn Term::with_malloc(self : Term[Sub]) -> Term[Sub] {
  self.with_flag(sub_malloc_attr)
}

///|
pub fn Term::without_malloc(self : Term[Sub]) -> Term[Sub] {
  self.without_flag(sub_malloc_attr)
}

///|
pub fn Term::is_malloc(self : Term[Sub]) -> Bool {
  self.has_flag(sub_malloc_attr)
}

///|
pub fn Term::with_const(self : Term[Sub]) -> Term[Sub] {
  self.with_flag(sub_const_attr)
}

///|
pub fn Term::without_const(self : Term[Sub]) -> Term[Sub] {
  self.without_flag(sub_const_attr)
}

///|
pub fn Term::is_const(self : Term[Sub]) -> Bool {
  self.has_flag(sub_const_attr)
}

///|
pub fn Term::with_noreturn(self : Term[Sub]) -> Term[Sub] {
  self.with_flag(sub_noreturn_attr)
}

///|
pub fn Term::without_noreturn(self : Term[Sub]) -> Term[Sub] {
  self.without_flag(sub_noreturn_attr)
}

///|
pub fn Term::is_noreturn(self : Term[Sub]) -> Bool {
  self.has_flag(sub_noreturn_attr)
}

///|
pub fn Term::with_nothrow(self : Term[Sub]) -> Term[Sub] {
  self.with_flag(sub_nothrow_attr)
}

///|
pub fn Term::without_nothrow(self : Term[Sub]) -> Term[Sub] {
  self.without_flag(sub_nothrow_attr)
}

///|
pub fn Term::is_nothrow(self : Term[Sub]) -> Bool {
  self.has_flag(sub_nothrow_attr)
}

///|
pub fn Term::with_returns_twice(self : Term[Sub]) -> Term[Sub] {
  self.with_flag(sub_returns_twice_attr)
}

///|
pub fn Term::without_returns_twice(self : Term[Sub]) -> Term[Sub] {
  self.without_flag(sub_returns_twice_attr)
}

///|
pub fn Term::returns_twice(self : Term[Sub]) -> Bool {
  self.has_flag(sub_returns_twice_attr)
}

///|
pub fn Term::with_entry_point(self : Term[Sub]) -> Term[Sub] {
  self.with_flag(sub_entry_point_attr)
}

///|
pub fn Term::without_entry_point(self : Term[Sub]) -> Term[Sub] {
  self.without_flag(sub_entry_point_attr)
}

///|
pub fn Term::is_entry_point(self : Term[Sub]) -> Bool {
  self.has_flag(sub_entry_point_attr)
}

///|
pub fn Term::with_intrinsic(self : Term[Sub]) -> Term[Sub] {
  self.with_flag(sub_intrinsic_attr)
}

///|
pub fn Term::without_intrinsic(self : Term[Sub]) -> Term[Sub] {
  self.without_flag(sub_intrinsic_attr)
}

///|
pub fn Term::is_intrinsic(self : Term[Sub]) -> Bool {
  self.has_flag(sub_intrinsic_attr)
}

///|
pub fn Term::with_pure(self : Term[Sub]) -> Term[Sub] {
  self.with_flag(sub_pure_attr)
}

///|
pub fn Term::without_pure(self : Term[Sub]) -> Term[Sub] {
  self.without_flag(sub_pure_attr)
}

///|
pub fn Term::is_pure(self : Term[Sub]) -> Bool {
  self.has_flag(sub_pure_attr)
}
