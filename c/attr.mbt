// Port of BAP `lib/bap_c/bap_c_attr.ml` (attribute processing).
//
// Each registered action is a subroutine transformation that should do
// nothing if it doesn't know the attribute. The GNU attributes supported
// upstream (`alloc_size`, `format`, `nonnull`, `warn_unused_result`,
// `const`, `pure`, `malloc`, `noreturn`, `returns_twice`, `nothrow`) are
// registered by default.
//
// Deviation: upstream raises `Attr_type`/`Attr_arity` exceptions when a GNU
// attribute has a non-integer argument index or a wrong number of
// arguments; here such an attribute is ignored and the subroutine is
// returned unchanged (as upstream does for out-of-range argument indices).

///|
/// An attribute action (upstream `sub pass`).
pub type AttrPass = (Attr, @types.Term[@types.Sub]) -> @types.Term[@types.Sub]

///|
let attr_registry : Array[AttrPass] = gnu_attr_passes()

///|
/// Registers an attribute action. The most recently registered action is
/// applied first.
pub fn register_attr_pass(pass : AttrPass) -> Unit {
  attr_registry.insert(0, pass)
}

///|
/// Applies all registered actions for the attribute `attr` to `sub`
/// (upstream `C.Attr.apply`).
pub fn apply_attr(
  attr : Attr,
  sub : @types.Term[@types.Sub],
) -> @types.Term[@types.Sub] {
  attr_registry.fold(init=sub, (sub, pass) => pass(attr, sub))
}

///|
fn gnu_attr(
  name : String,
  f : (Array[String], @types.Term[@types.Sub]) -> @types.Term[@types.Sub],
) -> AttrPass {
  (attr, sub) => if attr.name == name { f(attr.args, sub) } else { sub }
}

///|
fn gnu_mark_arg(
  attr : @types.Attr,
  sub : @types.Term[@types.Sub],
  index : String,
) -> @types.Term[@types.Sub] {
  let i = @string.parse_int(index.trim()) catch { _ => return sub }
  match sub.nth_arg(i - 1) {
    None => sub
    Some(arg) => sub.update_arg(arg.set_attr(attr))
  }
}

///|
fn gnu_mark_args(
  attr : @types.Attr,
) -> (Array[String], @types.Term[@types.Sub]) -> @types.Term[@types.Sub] {
  (args, sub) => args.fold(init=sub, (sub, i) => gnu_mark_arg(attr, sub, i))
}

///|
fn gnu_format(
  args : Array[String],
  sub : @types.Term[@types.Sub],
) -> @types.Term[@types.Sub] {
  match args {
    [archetype, index, _] =>
      gnu_mark_arg(@types.Arg::format(archetype), sub, index)
    _ => sub
  }
}

///|
fn gnu_warn_unused_result(
  _args : Array[String],
  sub : @types.Term[@types.Sub],
) -> @types.Term[@types.Sub] {
  match sub.last_arg() {
    None => sub
    Some(arg) => sub.update_arg(arg.set_attr(@types.Arg::warn_unused()))
  }
}

///|
fn gnu_set(
  attr : @types.Attr,
) -> (Array[String], @types.Term[@types.Sub]) -> @types.Term[@types.Sub] {
  (_, sub) => sub.set_attr(attr)
}

///|
fn gnu_attr_passes() -> Array[AttrPass] {
  // upstream registers these in order by prepending, so the list is reversed
  let passes = [
    gnu_attr("alloc_size", gnu_mark_args(@types.Arg::alloc_size())),
    gnu_attr("format", gnu_format),
    gnu_attr("nonnull", gnu_mark_args(@types.Arg::nonnull())),
    gnu_attr("warn_unused_result", gnu_warn_unused_result),
    gnu_attr("const", gnu_set(@types.Attr::sub_const())),
    gnu_attr("pure", gnu_set(@types.Attr::sub_pure())),
    gnu_attr("malloc", gnu_set(@types.Attr::sub_malloc())),
    gnu_attr("noreturn", gnu_set(@types.Attr::sub_noreturn())),
    gnu_attr("returns_twice", gnu_set(@types.Attr::sub_returns_twice())),
    gnu_attr("nothrow", gnu_set(@types.Attr::sub_nothrow())),
  ]
  passes.rev()
}
