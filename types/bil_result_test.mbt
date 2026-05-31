///|
fn result_word(value : Int, width? : Int = 8) -> @types.Word {
  try! @types.Word::of_int(width~, value)
}

///|
test "BAP-style BIL result ids are hexadecimal and successor based" {
  let zero = @types.BilResultId::zero()
  let first = zero.succ()
  let marker = @types.BilResultId::of_uint64(0x2AUL)
  assert_true(zero.to_uint64() == 0UL)
  assert_true(first.to_uint64() == 1UL)
  assert_eq(zero.to_string(), "0x0")
  assert_eq(first.to_string(), "0x1")
  assert_eq(marker.to_string(), "0x2A")
}

///|
test "BAP-style BIL result values and results render like OCaml" {
  let id = @types.BilResultId::of_uint64(10UL)
  let word = result_word(0x2A)
  let imm = @types.BilResult::word(word, id)
  let undefined = @types.BilResult::undefined(id.succ())
  let storage = @types.BilResult::storage(
    @types.BilResultStorage::linear(),
    id.succ().succ(),
  )
  assert_true(imm.id() == id)
  assert_true(imm.value() == BilResultImm(word))
  assert_eq(imm.to_string(), "[0xA] 0x2A:8u")
  assert_eq(undefined.value().to_string(), "bot")
  assert_eq(undefined.to_string(), "[0xB] bot")
  assert_eq(storage.value().to_string(), "<storage>")
  assert_eq(storage.to_string(), "[0xC] <storage>")
}

///|
test "BAP-style linear result storage keeps the newest matching save" {
  let addr = result_word(4)
  let first = result_word(0x11)
  let second = result_word(0x22)
  let storage = @types.BilResultStorage::linear()
    .save(addr, first)
    .save(addr, second)
  assert_true(!storage.is_sparse())
  assert_true(storage.load(addr) == Some(second))
  assert_true(storage.load(result_word(5)) == None)
}

///|
test "BAP-style sparse result storage replaces saved addresses" {
  let addr = result_word(4)
  let other = result_word(5)
  let first = result_word(0x11)
  let second = result_word(0x22)
  let storage = @types.BilResultStorage::sparse()
    .save(addr, first)
    .save(other, first)
    .save(addr, second)
  assert_true(storage.is_sparse())
  assert_true(storage.load(addr) == Some(second))
  assert_true(storage.load(other) == Some(first))
}
