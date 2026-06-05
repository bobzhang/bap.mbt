///|
test "translated BAP memory reads files on native target" {
  let path = "_build/memory-of-file-test.bin"
  let data = b"\x01\x02\x03\x04"
  match @native_io.write_file(path, data) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @memory.Memory::of_file(endian=LittleEndian, start=0x5000UL, path) {
    Ok(memory) => {
      assert_true(memory.min_addr() == 0x5000UL)
      assert_true(memory.max_addr() == 0x5003UL)
      assert_true(memory.to_bytes() == data)
      inspect(memory.hexdump(), content="01 02 03 04")
      match memory.load(0x5000UL, width=16) {
        Ok(word) => assert_true(word.to_hex() == "0x0201")
        Err(reason) => fail(reason)
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "translated BAP memory of_file reports native read failures" {
  assert_true(
    @memory.Memory::of_file(
      endian=LittleEndian,
      start=0UL,
      "__bap_mbt_missing_memory_file__",
    )
    is Err(_),
  )
}
