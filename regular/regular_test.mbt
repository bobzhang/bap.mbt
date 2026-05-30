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
test "prefix trie find and longest_match follow BAP trie behavior" {
  let trie : @regular.PrefixTrie[Int] = @regular.PrefixTrie::new()
  trie.add("", 0)
  trie.add("a", 1)
  trie.add("abcde", 3)
  assert_true(trie.longest_match("") == Some((0, 0)))
  assert_true(trie.longest_match("abcd") == Some((1, 1)))
  assert_true(trie.longest_match("abcdef") == Some((5, 3)))
  trie.add("abc", 2)
  assert_true(trie.longest_match("abcd") == Some((3, 2)))
  trie.remove("abc")
  assert_true(trie.longest_match("abcd") == Some((1, 1)))
  trie.remove("")
  assert_true(trie.longest_match("nothing") == None)
  assert_true(trie.find("a") == Some(1))
  assert_true(trie.find("abc") == None)
  assert_true(trie.find("abcde") == Some(3))
}
