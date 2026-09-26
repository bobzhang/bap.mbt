///|
fn sub_with_args(name : String, n : Int) -> @types.Term[@types.Sub] {
  let args = Array::makei(n, i => {
    let v = @types.Var::create("\{name}_a\{i + 1}", Imm(32))
    @types.Arg::create(v, @types.Exp::var_exp(v))
  })
  @types.Sub::create(name~, args~)
}

///|
test "GNU argument attributes" {
  let sub = sub_with_args("printf_like", 3)
  let sub = @c.apply_attr(
    @c.Attr::new("format", args=["printf", "2", "3"]),
    sub,
  )
  let sub = @c.apply_attr(@c.Attr::new("nonnull", args=["1", "2"]), sub)
  let sub = @c.apply_attr(@c.Attr::new("alloc_size", args=["3"]), sub)
  let sub = @c.apply_attr(@c.Attr::new("warn_unused_result"), sub)
  let args = sub.args()
  assert_eq(args[0].is_nonnull(), true)
  assert_eq(args[1].is_nonnull(), true)
  assert_eq(args[2].is_nonnull(), false)
  assert_eq(args[1].format(), Some("printf"))
  assert_eq(args[0].format(), None)
  assert_eq(args[2].is_alloc_size(), true)
  assert_eq(args[2].is_warn_unused(), true)
  assert_eq(args[0].is_warn_unused(), false)
}

///|
test "GNU subroutine attributes" {
  let sub = sub_with_args("f", 0)
  let sub = ["const", "pure", "malloc", "noreturn", "returns_twice", "nothrow"].fold(
    init=sub,
    (sub, name) => @c.apply_attr(@c.Attr::new(name), sub),
  )
  assert_true(sub.is_const() && sub.is_pure() && sub.is_malloc())
  assert_true(sub.is_noreturn() && sub.is_nothrow())
  assert_true(sub.has_flag(@types.Attr::sub_returns_twice().key))
}

///|
test "unknown, malformed, and out-of-range attributes are ignored" {
  let sub = sub_with_args("g", 1)
  let same = [
    @c.Attr::new("unknown_attr", args=["1"]),
    @c.Attr::new("nonnull", args=["5"]),
    @c.Attr::new("nonnull", args=["x"]),
    @c.Attr::new("format", args=["printf"]),
  ].fold(init=sub, (sub, attr) => @c.apply_attr(attr, sub))
  assert_eq(same.args()[0].is_nonnull(), false)
  assert_eq(same.args()[0].format(), None)
  assert_eq(
    @c.apply_attr(@c.Attr::new("warn_unused_result"), sub_with_args("h", 0))
    .args()
    .length(),
    0,
  )
}

///|
test "custom attribute passes" {
  @c.register_attr_pass((attr, sub) => {
    if attr.name == "c_test_marker" {
      sub.set_attr(@types.Attr::flag("c-test-marker"))
    } else {
      sub
    }
  })
  let sub = @c.apply_attr(@c.Attr::new("c_test_marker"), sub_with_args("k", 0))
  assert_true(sub.has_flag("c-test-marker"))
}
