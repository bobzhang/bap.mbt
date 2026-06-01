///|
test "BAP-style vector starts empty and appends past initial capacity" {
  let vector = @types.BapVector::create(0, capacity=1)
  assert_true(vector.is_empty())
  assert_true(vector.length() == 0)
  assert_true(vector.capacity() == 1)
  vector.append(10)
  vector.append(20)
  vector.append(30)
  assert_true(vector.length() == 3)
  assert_true(vector.capacity() >= 3)
  assert_true(vector.to_array() == [10, 20, 30])
}

///|
test "BAP-style vector nth get and set respect logical size" {
  let vector = @types.BapVector::create(-1, capacity=4)
  vector.append(1)
  vector.append(2)
  assert_true(vector.nth(0) == Some(1))
  assert_true(vector.nth(1) == Some(2))
  assert_true(vector.nth(2) == None)
  assert_true(vector.nth(-1) == None)
  assert_true(vector.get(1) == 2)
  vector.set(1, 42)
  assert_true(vector.to_array() == [1, 42])
}

///|
test "BAP-style vector traversal and mapping use occupied elements only" {
  let vector = @types.BapVector::create(0, capacity=5)
  vector.append(3)
  vector.append(4)
  vector.append(5)
  let seen = []
  vector.iteri((index, value) => seen.push(index * 10 + value))
  assert_true(seen == [3, 14, 25])
  let iter_seen = []
  vector.iter(value => iter_seen.push(value * 10))
  assert_true(iter_seen == [30, 40, 50])
  assert_true(vector.map_to_array(value => value * 2) == [6, 8, 10])
  assert_true(vector.foldi(0, (index, acc, value) => acc + index + value) == 15)
  assert_true(vector.fold(1, (acc, value) => acc * value) == 60)
  let folded : Result[Int, String] = vector.fold_result(0, (acc, value) => {
    Ok(acc + value)
  })
  assert_true(folded == Ok(12))
  assert_true(
    vector.fold_result(0, (acc, value) => {
      if value == 4 {
        Err("stop")
      } else {
        Ok(acc + value)
      }
    }) ==
    Err("stop"),
  )
}

///|
test "BAP-style vector search helpers return first match" {
  let vector = @types.BapVector::create("", capacity=1)
  vector.append("aa")
  vector.append("bbb")
  vector.append("cc")
  assert_true(
    vector.findi((_, value) => value.length() == 3) == Some((1, "bbb")),
  )
  assert_true(vector.find(value => value.has_prefix("c")) == Some("cc"))
  assert_true(
    vector.find_mapi((index, value) => {
      if value.length() == 2 {
        Some("\{index}:\{value}")
      } else {
        None
      }
    }) ==
    Some("0:aa"),
  )
  assert_true(
    vector.find_map(value => {
      if value.length() == 2 {
        Some(value + "!")
      } else {
        None
      }
    }) ==
    Some("aa!"),
  )
  assert_true(vector.exists(value => value == "bbb"))
  assert_true(!vector.exists(value => value == "missing"))
  assert_true(vector.for_all(value => value.length() >= 2))
  assert_true(vector.count(value => value.length() == 2) == 2)
}

///|
test "BAP-style vector index helpers support equality and custom equality" {
  let vector = @types.BapVector::create("default")
  vector.append("A")
  vector.append("b")
  vector.append("a")
  assert_true(vector.index("b") == Some(1))
  assert_true(vector.index("missing") == None)
  assert_true(vector.index_with("missing", default=99) == 99)
  assert_true(vector.index_exn("a") == 2)
  assert_true(vector.contains("A"))
  assert_true(vector.mem("A"))
  assert_true(!vector.mem("missing"))
  assert_true(
    vector.index_with_by("a", default=-1, (left, right) => {
      left.to_upper() == right.to_upper()
    }) ==
    0,
  )
  assert_true(
    vector.mem_by("a", (left, right) => left.to_upper() == right.to_upper()),
  )
  assert_eq(vector.to_string(value => value), "{A; b; a}")
}

///|
test "BAP-style vector min and max helpers use custom comparison" {
  let vector = @types.BapVector::create(0)
  assert_true(vector.min_elt_by((left, right) => left.compare(right)) == None)
  assert_true(vector.max_elt_by((left, right) => left.compare(right)) == None)
  vector.append(7)
  vector.append(2)
  vector.append(11)
  assert_true(
    vector.min_elt_by((left, right) => left.compare(right)) == Some(2),
  )
  assert_true(
    vector.max_elt_by((left, right) => left.compare(right)) == Some(11),
  )
  assert_true(
    vector.min_elt(compare=(left, right) => left.compare(right)) == Some(2),
  )
  assert_true(
    vector.max_elt(compare=(left, right) => left.compare(right)) == Some(11),
  )
  assert_true(
    vector.min_elt_by((left, right) => right.compare(left)) == Some(11),
  )
}
