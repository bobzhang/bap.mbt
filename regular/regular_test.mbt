///|
test "format registry records reader and writer metadata" {
  let registry = @regular.FormatRegistry::new()
  registry.add_reader(
    @regular.FormatInfo::new(
      name="sexp",
      version="1",
      description="S-expression",
    ),
  )
  registry.add_writer(@regular.FormatInfo::new(name="json", version="1"))
  assert_true(
    registry.default_reader().map(info => info.to_string()) ==
    Some("sexp@1: S-expression"),
  )
  assert_true(
    registry.default_writer().map(info => info.to_string()) == Some("json@1"),
  )
  assert_true(
    registry.find_reader("sexp", version="1").map(info => info.name) ==
    Some("sexp"),
  )
  assert_true(
    registry.find_writer("json").map(info => info.version) == Some("1"),
  )
}

///|
test "digest helpers are deterministic and byte-oriented" {
  let a = @regular.digest_bytes(b"abc")
  let b = @regular.digest_bytes(b"abd")
  inspect(a.to_string(), content="e71fa2190541574b")
  assert_true(a != b)
  assert_true(@regular.digest_string("abc").to_string() == a.to_string())
}

///|
fn assert_trie_longest(
  trie : @regular.PrefixTrie[Int],
  cases : Array[(String, (Int, Int)?)],
) -> Unit raise {
  for item in cases {
    let (key, expected) = item
    assert_true(trie.longest_match(key) == expected)
  }
}

///|
fn assert_trie_find(
  trie : @regular.PrefixTrie[Int],
  cases : Array[(String, Int?)],
) -> Unit raise {
  for item in cases {
    let (key, expected) = item
    assert_true(trie.find(key) == expected)
  }
}

///|
test "prefix trie find and longest_match follow BAP trie behavior" {
  let trie : @regular.PrefixTrie[Int] = @regular.PrefixTrie::new()
  assert_true(trie.length() == 0)
  trie.change("missing", _ => None)
  assert_true(trie.length() == 0)
  trie.add("", 0)
  trie.add("a", 1)
  trie.add("abcde", 3)
  assert_true(trie.length() == 3)
  assert_trie_longest(trie, [
    ("", Some((0, 0))),
    ("a", Some((1, 1))),
    ("ab", Some((1, 1))),
    ("abc", Some((1, 1))),
    ("abcd", Some((1, 1))),
    ("abcde", Some((5, 3))),
    ("abcdef", Some((5, 3))),
    ("nothing", Some((0, 0))),
  ])
  trie.add("abc", 2)
  assert_true(trie.length() == 4)
  assert_trie_longest(trie, [
    ("", Some((0, 0))),
    ("a", Some((1, 1))),
    ("ab", Some((1, 1))),
    ("abc", Some((3, 2))),
    ("abcd", Some((3, 2))),
    ("abcde", Some((5, 3))),
    ("abcdef", Some((5, 3))),
    ("nothing", Some((0, 0))),
  ])
  trie.change("abc", value => {
    match value {
      Some(current) => Some(current + 10)
      None => None
    }
  })
  assert_true(trie.find("abc") == Some(12))
  assert_true(trie.length() == 4)
  trie.change("new", _ => Some(4))
  assert_true(trie.find("new") == Some(4))
  assert_true(trie.length() == 5)
  trie.remove("new")
  assert_true(trie.length() == 4)
  trie.remove("abc")
  assert_true(trie.length() == 3)
  assert_trie_longest(trie, [
    ("", Some((0, 0))),
    ("a", Some((1, 1))),
    ("ab", Some((1, 1))),
    ("abc", Some((1, 1))),
    ("abcd", Some((1, 1))),
    ("abcde", Some((5, 3))),
    ("abcdef", Some((5, 3))),
    ("nothing", Some((0, 0))),
  ])
  trie.remove("")
  assert_true(trie.length() == 2)
  let folded = trie.fold(init=[], f=fn(acc, key, value) {
    acc.push("\{key}=\{value}")
    acc
  })
  folded.sort_by((left, right) => left.compare(right))
  assert_true(folded == ["a=1", "abcde=3"])
  let iterated = []
  trie.iter(f=fn(key, value) { iterated.push("\{key}=\{value}") })
  iterated.sort_by((left, right) => left.compare(right))
  assert_true(iterated == folded)
  assert_trie_longest(trie, [
    ("", None),
    ("a", Some((1, 1))),
    ("ab", Some((1, 1))),
    ("abc", Some((1, 1))),
    ("abcd", Some((1, 1))),
    ("abcde", Some((5, 3))),
    ("abcdef", Some((5, 3))),
    ("nothing", None),
  ])
  assert_trie_find(trie, [
    ("", None),
    ("a", Some(1)),
    ("ab", None),
    ("abc", None),
    ("abcd", None),
    ("abcde", Some(3)),
    ("abcdef", None),
    ("nothing", None),
  ])
}
