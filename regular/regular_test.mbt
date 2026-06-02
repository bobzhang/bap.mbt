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
  let root = @regular.Digest::create(namespace_name="cache")
  assert_true(root == @regular.Digest::create(namespace_name="cache"))
  assert_true(
    root.add("entry") == @regular.digest(namespace_name="cache", "entry"),
  )
  assert_true(root.add("entry") != root.add("other"))
  assert_true(
    root.add_bytes(b"entry") ==
    root.add(@regular.digest_bytes(b"entry").to_string()),
  )
  assert_true(root.compare(root.add("entry")) != 0)
}

///|
test "regular cache delegates load and save by digest" {
  let store : Map[@regular.Digest, String] = {}
  let cache = @regular.Cache::create(load=key => store.get(key), save=(
    key,
    value,
  ) => store[key] = value)
  let key = @regular.digest(namespace_name="cache", "unit")
  assert_true(cache.load(key) is None)
  cache.save(key, "value")
  assert_true(cache.load(key) == Some("value"))
  let empty : @regular.Cache[String] = @regular.Cache::oblivion()
  empty.save(key, "ignored")
  assert_true(empty.load(key) is None)
}

///|
test "regular sequence helpers mirror BAP sequence wrappers" {
  let source = [1, 2, 3]
  let copied = @regular.seq_of_array(source)
  assert_true(copied == source)
  source[0] = 9
  assert_true(copied == [1, 2, 3])
  assert_true(@regular.seq_of_list(@list.from_array([1, 2, 3])) == [1, 2, 3])
  let helper_empty : Array[Int] = @regular.seq_empty()
  assert_true(helper_empty == [])
  assert_true(@regular.seq_singleton(4) == [4])
  assert_true(@regular.seq_return(4) == [4])
  assert_true(@regular.seq_init(4, i => i * 2) == [0, 2, 4, 6])
  assert_true(@regular.seq_init(-1, i => i) == [])
  assert_true(
    @regular.seq_unfold(init=1, f=state => {
      if state > 4 {
        None
      } else {
        Some((state * 2, state + 1))
      }
    }) ==
    [2, 4, 6, 8],
  )
  assert_true(
    @regular.seq_unfold_step(init=0, f=state => {
      if state >= 6 {
        SeqDone
      } else if state % 2 == 0 {
        SeqSkip(state + 1)
      } else {
        SeqYield(state, state + 1)
      }
    }) ==
    [1, 3, 5],
  )
  assert_true(@regular.seq_range(1, 4) == [1, 2, 3])
  assert_true(@regular.seq_range(4, 1) == [])
  assert_true(@regular.seq_range(1, 4, inclusive=true) == [1, 2, 3, 4])
  assert_true(@regular.seq_range(4, 4, inclusive=true) == [4])
  assert_true(@regular.seq_range(4, 1, inclusive=true) == [])
  assert_true(@regular.seq_cons(0, copied) == [0, 1, 2, 3])
  assert_true(@regular.seq_append([0], copied) == [0, 1, 2, 3])
  assert_true(@regular.seq_concat([[0], copied, [4, 5]]) == [0, 1, 2, 3, 4, 5])
  let empty : Array[Int] = []
  assert_true(@regular.seq_is_empty(empty))
  assert_true(!@regular.seq_is_empty(copied))
  assert_true(@regular.seq_length(copied) == 3)
  assert_true(@regular.seq_hd(copied) == Some(1))
  assert_true(@regular.seq_hd(empty) is None)
  assert_true(@regular.seq_hd_exn(copied) == 1)
  try @regular.seq_hd_exn(empty) catch {
    EmptySeq => ()
  } noraise {
    _ => fail("expected EmptySeq")
  }
  assert_true(@regular.seq_tl(copied) == Some([2, 3]))
  assert_true(@regular.seq_tl(empty) is None)
  assert_true(@regular.seq_next(copied) == Some((1, [2, 3])))
  assert_true(@regular.seq_next(empty) is None)
  assert_true(@regular.seq_nth(copied, 1) == Some(2))
  assert_true(@regular.seq_nth(copied, -1) is None)
  assert_true(@regular.seq_nth(copied, 3) is None)
  assert_true(@regular.seq_last(copied) == Some(3))
  assert_true(@regular.seq_last(empty) is None)
  assert_true(@regular.seq_take(copied, 2) == [1, 2])
  assert_true(@regular.seq_take(copied, -1) == [])
  assert_true(@regular.seq_take(copied, 9) == copied)
  assert_true(@regular.seq_drop(copied, 1) == [2, 3])
  assert_true(@regular.seq_drop(copied, -1) == copied)
  assert_true(@regular.seq_drop(copied, 9) == [])
  assert_true(@regular.seq_drop_eagerly(copied, 2) == [3])
  assert_true(@regular.seq_split_n(copied, 2) == ([1, 2], [3]))
  assert_true(@regular.seq_split_n(copied, -1) == ([], [1, 2, 3]))
  assert_true(@regular.seq_split_n(copied, 9) == ([1, 2, 3], []))
  assert_true(@regular.seq_take_while(copied, value => value < 3) == [1, 2])
  assert_true(@regular.seq_take_while(copied, value => value < 0) == [])
  assert_true(@regular.seq_drop_while(copied, value => value < 3) == [3])
  assert_true(@regular.seq_drop_while(copied, value => value < 9) == [])
  assert_true(@regular.seq_map(copied, value => value * 2) == [2, 4, 6])
  assert_true(@regular.seq_mapi(copied, (i, value) => i + value) == [1, 3, 5])
  assert_true(
    @regular.seq_filter_map(copied, value => {
      if value % 2 == 1 {
        Some(value * 10)
      } else {
        None
      }
    }) ==
    [10, 30],
  )
  assert_true(
    @regular.seq_filter_mapi(copied, (i, value) => {
      if value % 2 == 0 {
        Some(i + value)
      } else {
        None
      }
    }) ==
    [3],
  )
  assert_true(@regular.seq_filter_opt([Some(1), None, Some(3), None]) == [1, 3])
  assert_true(
    @regular.seq_concat_map(copied, value => [value, -value]) ==
    [1, -1, 2, -2, 3, -3],
  )
  assert_true(
    @regular.seq_concat_mapi(copied, (i, value) => [i, value]) ==
    [0, 1, 1, 2, 2, 3],
  )
  assert_true(@regular.seq_filter(copied, value => value % 2 == 1) == [1, 3])
  assert_true(@regular.seq_fold(copied, 0, (acc, value) => acc + value) == 6)
  assert_true(
    @regular.seq_foldi(copied, 0, (i, acc, value) => acc + i * 10 + value) == 36,
  )
  let iterated = []
  @regular.seq_iter(copied, value => iterated.push(value * 10))
  assert_true(iterated == [10, 20, 30])
  let iteratedi = []
  @regular.seq_iteri(copied, (i, value) => iteratedi.push(i + value))
  assert_true(iteratedi == [1, 3, 5])
  assert_true(@regular.seq_find(copied, value => value > 1) == Some(2))
  assert_true(@regular.seq_find(copied, value => value > 5) is None)
  assert_true(
    @regular.seq_find_map(copied, value => {
      if value % 2 == 0 {
        Some(value * 10)
      } else {
        None
      }
    }) ==
    Some(20),
  )
  assert_true(
    @regular.seq_find_map(copied, value => {
      if value > 5 {
        Some(value * 10)
      } else {
        None
      }
    })
    is None,
  )
  assert_true(@regular.seq_exists(copied, value => value == 2))
  assert_true(!@regular.seq_exists(copied, value => value == 9))
  assert_true(@regular.seq_for_all(copied, value => value > 0))
  assert_true(!@regular.seq_for_all(copied, value => value % 2 == 1))
  assert_true(@regular.seq_all(copied, value => value < 4))
  assert_true(!@regular.seq_all(copied, value => value < 3))
  assert_true(@regular.seq_to_list(copied).to_array() == [1, 2, 3])
  let as_array = @regular.seq_to_array(copied)
  assert_true(as_array == [1, 2, 3])
  let mutable_source = [4, 5, 6]
  let owned = @regular.seq_to_array(mutable_source)
  mutable_source[1] = 9
  assert_true(owned == [4, 5, 6])
  assert_true(@regular.seq_rev(copied) == [3, 2, 1])
  assert_true(@regular.seq_to_list_rev(copied).to_array() == [3, 2, 1])
  assert_true(@regular.seq_compare(Int::compare, [1, 2], [1, 3]) < 0)
  assert_true(@regular.seq_compare(Int::compare, [1, 2, 3], [1, 2]) > 0)
  assert_true(@regular.seq_compare(Int::compare, [1, 2], [1, 2, 0]) < 0)
  assert_true(@regular.seq_compare(Int::compare, [1, 2], [1, 2]) == 0)
  inspect(@regular.seq_render(copied), content="{1, 2, 3}")
  inspect(@regular.seq_render(copied, max=2), content="{1, 2, ...}")
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

///|
test "suffix trie mirrors BAP reversed-token matching" {
  let trie : @regular.SuffixTrie[Int] = @regular.SuffixTrie::new()
  assert_true(trie.is_empty())
  trie.add("", 0)
  trie.add("c", 1)
  trie.add("abc", 3)
  assert_true(trie.length() == 3)
  assert_true(trie.find("abc") == Some(3))
  assert_true(trie.find("xxabc") == None)
  assert_true(trie.longest_match("xxabc") == Some((3, 3)))
  assert_true(trie.longest_match("zc") == Some((1, 1)))
  assert_true(trie.longest_match("none") == Some((0, 0)))
  trie.change("abc", value => {
    match value {
      Some(current) => Some(current + 10)
      None => None
    }
  })
  assert_true(trie.find("abc") == Some(13))
  let entries = trie.fold(init=[], f=fn(acc, key, value) {
    acc.push("\{key}=\{value}")
    acc
  })
  entries.sort_by((left, right) => left.compare(right))
  assert_true(entries == ["=0", "c=1", "abc=13"])
  trie.remove("")
  assert_true(trie.longest_match("none") == None)
}
