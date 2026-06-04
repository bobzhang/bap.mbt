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
let term_precondition_attr = "precondition"

///|
let term_invariant_attr = "invariant"

///|
let term_postcondition_attr = "postcondition"

///|
let term_mark_attr = "mark"

///|
pub fn Attr::flag(key : String) -> Attr {
  Attr::new(key~, value="true")
}

///|
pub fn Attr::filename(filename : String) -> Attr {
  Attr::new(key="filename", value=filename)
}

///|
pub fn Attr::format(format : String) -> Attr {
  Attr::new(key="format", value=format)
}

///|
pub fn Attr::origin(tid : Tid) -> Attr {
  Attr::new(key="origin", value=tid.to_string())
}

///|
pub fn Attr::synthetic() -> Attr {
  Attr::flag("synthetic")
}

///|
pub fn Attr::visited() -> Attr {
  Attr::flag("visited")
}

///|
pub fn Attr::live() -> Attr {
  Attr::flag("live")
}

///|
pub fn Attr::dead() -> Attr {
  Attr::flag("dead")
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
