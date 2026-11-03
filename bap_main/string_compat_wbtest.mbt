///|
test "compatibility trimming and splitting preserve non-BMP text" {
  assert_eq(strip(" \t😀 x\n"), "😀 x")
  assert_eq(lstrip("\t😀 "), "😀 ")
  assert_eq(rstrip(" 😀\n"), " 😀")
  assert_eq(lsplit2("😀=𐐀", '='), Some(("😀", "𐐀")))
}
