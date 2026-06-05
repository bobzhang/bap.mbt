///|
fn int_compare(left : Int, right : Int) -> Int {
  left.compare(right)
}

///|
fn string_compare(left : String, right : String) -> Int {
  left.compare(right)
}

///|
fn int_string_relation() -> @relation.Relation[Int, String] {
  @relation.Relation::empty(
    compare_left=int_compare,
    compare_right=string_compare,
  )
}

///|
test "relation add mem find and fold are deterministic" {
  let relation = int_string_relation()
  assert_true(relation.is_empty())
  let relation = relation.add(2, "b").add(1, "c").add(1, "a").add(2, "b")
  assert_eq(relation.length(), 3)
  assert_true(relation.mem(1, "a"))
  assert_true(relation.mem(2, "a"))
  assert_true(!relation.mem(3, "a"))
  assert_true(!relation.mem(2, "missing"))
  assert_true(relation.findl(1) == ["a", "c"])
  assert_true(relation.findr("b") == [2])
  assert_true(relation.pairs() == [(1, "a"), (1, "c"), (2, "b")])
  let rendered = relation.fold(init=[], f=fn(left, right, acc) {
    acc.push("\{left}:\{right}")
    acc
  })
  assert_true(rendered == ["1:a", "1:c", "2:b"])
}

///|
test "relation exposes BAP-style top-level functions" {
  let relation = @relation.empty(
    compare_left=int_compare,
    compare_right=string_compare,
  )
  assert_true(@relation.is_empty(relation))
  let relation = @relation.add(relation, 2, "b")
  let relation = @relation.add(relation, 1, "a")
  assert_true(@relation.mem(relation, 2, "b"))
  assert_true(@relation.mem(relation, 2, "a"))
  assert_true(@relation.findl(relation, 1) == ["a"])
  assert_true(@relation.findr(relation, "b") == [2])
  let folded = @relation.fold(relation, init=[], f=fn(left, right, acc) {
    acc.push("\{left}:\{right}")
    acc
  })
  assert_true(folded == ["1:a", "2:b"])
  let iterated = []
  @relation.iter(relation, fn(left, right) {
    iterated.push("\{left}->\{right}")
  })
  assert_true(iterated == ["1->a", "2->b"])
  let matched = @relation.matching(relation, init=[], saturated=fn(
    left,
    right,
    acc,
  ) {
    acc.push("\{left}=\{right}")
    acc
  })
  assert_true(matched == ["1=a", "2=b"])
}

///|
test "relation add suppresses duplicate exact edges" {
  let relation = int_string_relation().add(1, "a").add(2, "b")
  assert_true(relation.mem(1, "b"))
  let relation = relation.add(1, "b").add(1, "b")
  assert_eq(relation.length(), 3)
  assert_true(relation.mem(1, "b"))
  assert_true(relation.pairs() == [(1, "a"), (1, "b"), (2, "b")])
}

///|
test "relation matching reports bijections as saturated" {
  let relation = int_string_relation().add(2, "b").add(1, "a")
  let saturated = relation.matching(init=[], saturated=fn(left, right, acc) {
    acc.push("\{left}->\{right}")
    acc
  })
  assert_true(saturated == ["1->a", "2->b"])
}

///|
test "relation matching reports non-injective backward mappings" {
  let relation = int_string_relation().add(1, "a").add(1, "b")
  let unmatched = relation.matching(init=[], unmatched=fn(reason, acc) {
    match reason {
      NonInjectiveBwd(values, left) =>
        acc.push("\{left}->[" + values.join(",") + "]")
      NonInjectiveFwd(_, _) => acc.push("unexpected")
    }
    acc
  })
  assert_true(unmatched == ["1->[a,b]"])
}

///|
test "relation matching reports non-injective forward mappings per left edge" {
  let relation = int_string_relation().add(1, "x").add(2, "x")
  let unmatched = relation.matching(init=[], unmatched=fn(reason, acc) {
    match reason {
      NonInjectiveFwd(lefts, right) =>
        acc.push("[" + lefts.map(v => v.to_string()).join(",") + "]->\{right}")
      NonInjectiveBwd(_, _) => acc.push("unexpected")
    }
    acc
  })
  assert_true(unmatched == ["[1,2]->x", "[1,2]->x"])
}
