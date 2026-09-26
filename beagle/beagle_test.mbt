///|
test "words are ordered lexicographically and deduplicated" {
  let w = @beagle.Words::of_array(["b", "aa", "b", "ab"])
  assert_eq(w.to_array(), ["aa", "ab", "b"])
  assert_true(w.mem("ab"))
  assert_false(w.mem("c"))
  let w = w.add("a").union(@beagle.Words::of_array(["c"]))
  inspect(w, content="a, aa, ab, b, c")
  assert_eq(w.length(), 5)
  assert_true(@beagle.Words::empty().is_empty())
}

///|
test "words printing is truncated and escaped" {
  let long = "x".repeat(100)
  let w = @beagle.Words::of_array([long])
  assert_eq(w.to_string().length(), @beagle.max_printed)
  inspect(
    @beagle.Words::of_array(["a\"b", "c\n\u{1}"]),
    content=(
      #|a\"b, c\n\001
    ),
  )
}

///|
test "words round-trip through sexp and term attributes" {
  let w = @beagle.Words::of_array(["hello", "world", "two words"])
  inspect(
    w.to_sexp(),
    content=(
      #|(hello "two words" world)
    ),
  )
  assert_eq(@beagle.Words::of_sexp(w.to_sexp()), Some(w))
  let def = @types.Def::create(
    @types.Var::create("x", Imm(8)),
    Int(try! @types.Word::of_int(width=8, 1)),
  ).set_attr(@beagle.words_attr(@beagle.words_tag, w))
  assert_eq(@beagle.term_words(def, @beagle.words_tag), Some(w))
  assert_eq(@beagle.term_words(def, @beagle.chars_tag), None)
}

///|
test "prey and statics" {
  let t1 = @types.Tid::create()
  let t2 = @types.Tid::create()
  let prey = @beagle.Prey::create([t1, t2], b"hi")
  assert_eq(prey.data(), b"hi")
  assert_eq(prey.text(), "hi")
  assert_eq(prey.terms().length(), 2)
  inspect(
    @beagle.detected().name(),
    content=(
      #|primus:beagle-prey
    ),
  )
  inspect(
    @beagle.caught().name(),
    content=(
      #|primus:beagle
    ),
  )
  inspect(
    @beagle.caught().inspect((prey, @beagle.Words::of_array(["hi"]))),
    content="(hi (hi))",
  )
  let a1 = try! @types.Word::of_int(width=32, 0x20)
  let a0 = try! @types.Word::of_int(width=32, 0x10)
  let s = @beagle.Statics::of_array([(a1, "foo"), (a0, "bar"), (a1, "baz")])
  inspect(
    s.to_string(),
    content=(
      #|0x10: bar
      #|0x20: baz
      #|
    ),
  )
  assert_eq(s.find(a0), Some("bar"))
}
