///|
test "parser slice preserves raw UTF-16 offsets" {
  let parser = Parser::new("a😀b")
  let high = parser.slice(1, 2)
  let low = parser.slice(2, 3)
  assert_eq(high.length(), 1)
  assert_eq(low.length(), 1)
  assert_eq(high.code_unit_at(0), 0xD83D)
  assert_eq(low.code_unit_at(0), 0xDE00)
  assert_eq(parser.slice(1, 3).to_owned(), "😀")
  assert_eq(parser.slice(4, 4).length(), 0)
}
