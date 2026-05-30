///|
fn bytes_0_to_15() -> Bytes {
  Bytes::from_array(Array::makei(16, i => i.to_byte()))
}

///|
test "image exposes segment memory and symbol membership" {
  let text = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x4000UL,
    bytes_0_to_15(),
    executable=true,
  )
  let symbol = @image.Symbol::create(
    name="main",
    addr=0x4004UL,
    size=4,
    is_function=true,
  )
  let image = @image.Image::from_segments(
    entry=0x4004UL,
    endian=LittleEndian,
    [text],
    symbols=[symbol],
    filename="a.out",
  )
  assert_true(image.entry_point() == 0x4004UL)
  assert_true(image.filename() == Some("a.out"))
  assert_true(text.is_executable())
  assert_true(image.memory().lookup(0x4004UL).length() == 1)
  assert_true(image.segment_of_symbol(symbol) is Some(_))
  assert_true(image.symbols_of_segment(text).length() == 1)
  match image.memory_of_symbol(symbol) {
    Some((mem, rest)) => {
      assert_true(rest.length() == 0)
      inspect(mem.hexdump(), content="04 05 06 07")
    }
    None => fail("expected symbol memory")
  }
}

///|
test "image words follow endian-aware memory loads" {
  let little = @image.Segment::create(
    name=".data",
    endian=LittleEndian,
    addr=0UL,
    bytes_0_to_15(),
  )
  let big = @image.Segment::create(
    name=".data",
    endian=BigEndian,
    addr=0UL,
    bytes_0_to_15(),
  )
  let le_img = @image.Image::from_segments(entry=0UL, endian=LittleEndian, [
    little,
  ])
  let be_img = @image.Image::from_segments(entry=0UL, endian=BigEndian, [big])
  let le_words = le_img.words(word_size=16).entries()
  let be_words = be_img.words(word_size=16).entries()
  assert_true(le_words.length() == 8)
  assert_true(be_words.length() == 8)
  inspect(le_words[0].1.to_hex(), content="0x0100")
  inspect(be_words[0].1.to_hex(), content="0x0001")
  inspect(le_words[7].1.to_hex(), content="0x0f0e")
  inspect(be_words[7].1.to_hex(), content="0x0e0f")
}
