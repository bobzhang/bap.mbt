///|
fn byte_values(bytes : Bytes) -> Array[Int] {
  bytes.to_array().map(byte => byte.to_int())
}

///|
test "translated BAP bytes create allocates zero-filled byte storage" {
  let bytes = Bytes::new(8)
  assert_true(bytes.length() == 8)
  assert_true(byte_values(bytes) == [0, 0, 0, 0, 0, 0, 0, 0])
  assert_true(@regular.bytes_empty().length() == 0)
  match @regular.bytes_create(4) {
    Ok(created) => assert_true(byte_values(created) == [0, 0, 0, 0])
    Err(reason) => fail(reason)
  }
  assert_true(@regular.bytes_create(-1) is Err(_))
  match @regular.bytes_make(3, b'X') {
    Ok(made) => assert_true(made == b"XXX")
    Err(reason) => fail(reason)
  }
  match @regular.bytes_init(4, i => (i + 65).to_byte()) {
    Ok(initialized) => assert_true(initialized == b"ABCD")
    Err(reason) => fail(reason)
  }
  assert_true(@regular.bytes_make(-1, b'X') is Err(_))
  assert_true(@regular.bytes_init(-1, _ => b'X') is Err(_))
}

///|
test "translated BAP bytes copy preserves value while owning storage" {
  let source : Array[Byte] = [84, 101, 115, 116]
  let bytes = Bytes::from_array(source)
  source[0] = 0
  assert_true(byte_values(bytes) == [84, 101, 115, 116])
  let copied = Bytes::makei(bytes.length(), i => bytes[i])
  assert_true(copied == bytes)
  assert_true(byte_values(copied) == [84, 101, 115, 116])
  assert_true(@regular.bytes_copy(bytes) == bytes)
  assert_true(byte_values(@regular.bytes_copy(bytes)) == [84, 101, 115, 116])
}

///|
test "translated BAP bytes access and sub helpers use byte offsets" {
  let bytes = b"abcdef"
  assert_true(@regular.bytes_length(bytes) == 6)
  assert_true(@regular.bytes_get(bytes, 0) == Some(b'a'))
  assert_true(@regular.bytes_get(bytes, 5) == Some(b'f'))
  assert_true(@regular.bytes_get(bytes, -1) is None)
  assert_true(@regular.bytes_get(bytes, 6) is None)
  match @regular.bytes_sub(bytes, 2, 3) {
    Ok(slice) => assert_true(slice == b"cde")
    Err(reason) => fail(reason)
  }
  match @regular.bytes_subo(bytes, pos=2, len=3) {
    Ok(slice) => assert_true(slice == b"cde")
    Err(reason) => fail(reason)
  }
  match @regular.bytes_subo(bytes, pos=2) {
    Ok(slice) => assert_true(slice == b"cdef")
    Err(reason) => fail(reason)
  }
  assert_true(@regular.bytes_sub(bytes, -1, 1) is Err(_))
  assert_true(@regular.bytes_sub(bytes, 1, -1) is Err(_))
  assert_true(@regular.bytes_sub(bytes, 5, 2) is Err(_))
}

///|
test "translated BAP bytes comparison helpers use lexical byte order" {
  assert_true(@regular.bytes_equal(b"ab", b"ab"))
  assert_true(!@regular.bytes_equal(b"ab", b"ac"))
  assert_true(@regular.bytes_compare(b"ab", b"ac") < 0)
  assert_true(@regular.bytes_compare(b"abc", b"ab") > 0)
  assert_true(@regular.bytes_compare(b"ab", b"ab") == 0)
  assert_true(@regular.bytes_mem(b"ab", b'b'))
  assert_true(!@regular.bytes_mem(b"ab", b'c'))
}

///|
test "translated BAP bytes trim removes ASCII edge whitespace" {
  assert_true(@regular.bytes_trim(b" \t\nvalue\r\n") == b"value")
  assert_true(@regular.bytes_trim(b"\x0b\x0cvalue\x0c") == b"value")
  assert_true(@regular.bytes_trim(b"value") == b"value")
  assert_true(@regular.bytes_trim(b" \n\t") == b"")
  assert_true(@regular.bytes_trim(b"\x00 value \x00") == b"\x00 value \x00")
}

///|
test "translated BAP bytes extend crops and pads deterministically" {
  match @regular.bytes_extend(b"abc", 2, 3) {
    Ok(extended) =>
      assert_true(byte_values(extended) == [0, 0, 97, 98, 99, 0, 0, 0])
    Err(reason) => fail(reason)
  }
  match @regular.bytes_extend(b"abc", -1, 0) {
    Ok(extended) => assert_true(extended == b"bc")
    Err(reason) => fail(reason)
  }
  match @regular.bytes_extend(b"abc", 0, -1) {
    Ok(extended) => assert_true(extended == b"ab")
    Err(reason) => fail(reason)
  }
  match @regular.bytes_extend(b"abc", -1, -1) {
    Ok(extended) => assert_true(extended == b"b")
    Err(reason) => fail(reason)
  }
  match @regular.bytes_extend(b"abc", 5, -7) {
    Ok(extended) => assert_true(byte_values(extended) == [0])
    Err(reason) => fail(reason)
  }
  assert_true(@regular.bytes_extend(b"abc", -4, 0) is Err(_))
  assert_true(@regular.bytes_extend(b"abc", 0, -4) is Err(_))
}

///|
test "translated BAP bytes container helpers use byte indexes" {
  let bytes = b"baNaNa"
  assert_true(!@regular.bytes_is_empty(bytes))
  assert_true(@regular.bytes_is_empty(b""))
  assert_true(
    @regular.bytes_to_array(bytes).map(byte => byte.to_int()) ==
    byte_values(bytes),
  )
  assert_true(@regular.bytes_index(bytes, b'a') == Some(1))
  assert_true(@regular.bytes_index_from(bytes, 2, b'a') == Some(3))
  assert_true(@regular.bytes_index_from(bytes, 6, b'a') is None)
  assert_true(@regular.bytes_rindex(bytes, b'a') == Some(5))
  assert_true(@regular.bytes_rindex_from(bytes, 4, b'a') == Some(3))
  assert_true(@regular.bytes_contains(bytes, b'N'))
  assert_true(!@regular.bytes_contains_from(bytes, 5, b'N'))
  assert_true(@regular.bytes_rcontains_from(bytes, 2, b'N'))
  assert_true(
    @regular.bytes_map(bytes, byte => if byte == b'a' { b'o' } else { byte }) ==
    b"boNoNo",
  )
  assert_true(
    @regular.bytes_mapi(bytes, (i, byte) => if i % 2 == 0 { b'_' } else { byte }) ==
    b"_a_a_a",
  )
  assert_true(@regular.bytes_cat(b"ab", b"cd") == b"abcd")
  assert_true(@regular.bytes_concat(b",", [b"a", b"b", b"c"]) == b"a,b,c")
  assert_true(@regular.bytes_uppercase(bytes) == b"BANANA")
  assert_true(@regular.bytes_lowercase(bytes) == b"banana")
  assert_true(@regular.bytes_capitalize(b"word") == b"Word")
  assert_true(@regular.bytes_uncapitalize(b"Word") == b"word")
  assert_true(@regular.bytes_escaped(b"a\n\t\r\\\"b") == b"a\\n\\t\\r\\\\\\\"b")
  assert_true(
    @regular.bytes_escaped(Bytes::from_array([0, 8, 31, 127, 255])) ==
    b"\\000\\b\\031\\127\\255",
  )
}

///|
test "translated BAP bytes traversal helpers scan in byte order" {
  let bytes = b"abca"
  let indexed = []
  @regular.bytes_iteri(bytes, (index, byte) => {
    indexed.push((index, byte.to_int()))
  })
  assert_true(indexed == [(0, 97), (1, 98), (2, 99), (3, 97)])
  let iterated = []
  @regular.bytes_iter(bytes, byte => iterated.push(byte.to_int()))
  assert_true(iterated == [97, 98, 99, 97])
  assert_true(
    @regular.bytes_fold(bytes, "", (acc, byte) => acc + "\{byte.to_int()};") ==
    "97;98;99;97;",
  )
  assert_true(@regular.bytes_find(bytes, byte => byte > b'b') == Some(b'c'))
  assert_true(
    @regular.bytes_find_map(bytes, byte => {
      if byte == b'b' {
        Some(byte.to_int() + 1)
      } else {
        None
      }
    }) ==
    Some(99),
  )
  assert_true(@regular.bytes_exists(bytes, byte => byte == b'c'))
  assert_true(!@regular.bytes_exists(bytes, byte => byte == b'z'))
  assert_true(@regular.bytes_for_all(bytes, byte => byte >= b'a'))
  assert_true(!@regular.bytes_for_all(bytes, byte => byte < b'c'))
  assert_true(@regular.bytes_count(bytes, byte => byte == b'a') == 2)
  assert_true(@regular.bytes_min_elt(bytes) == Some(b'a'))
  assert_true(@regular.bytes_max_elt(bytes) == Some(b'c'))
  assert_true(@regular.bytes_min_elt(b"") is None)
  assert_true(@regular.bytes_max_elt(b"") is None)
}

///|
test "translated BAP bytes text and binary serialization round trip" {
  let bytes : Bytes = [
    0x54, 0x68, 0x69, 0x73, 0x00, 0xff, 0x20, 0x42, 0x41, 0x50,
  ]
  let atom = @regular.bytes_to_sexp_atom(bytes)
  inspect(atom, content="#bytes:5468697300ff20424150")
  match @regular.bytes_from_sexp_atom(atom) {
    Ok(decoded) => assert_true(decoded == bytes)
    Err(reason) => fail(reason)
  }
  let encoded = @regular.bytes_bin_write(bytes)
  assert_true(@regular.bytes_bin_size(bytes) == encoded.length())
  assert_true(byte_values(encoded[0:4].to_owned()) == [10, 0, 0, 0])
  match @regular.bytes_bin_read(encoded) {
    Ok((decoded, pos)) => {
      assert_true(decoded == bytes)
      assert_true(pos == encoded.length())
    }
    Err(reason) => fail(reason)
  }
  assert_true(@regular.bytes_from_hex("0ff") is Err(_))
  assert_true(@regular.bytes_bin_read(encoded[:6]) is Err(_))
}
