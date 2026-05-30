///|
fn bytes_0_to_15() -> Bytes {
  bytes_from_range(0, 16)
}

///|
fn bytes_from_range(first : Int, length : Int) -> Bytes {
  Bytes::from_array(Array::makei(length, i => (first + i).to_byte()))
}

///|
fn assert_contiguous_word_addresses(
  image : @image.Image,
  word_size : Int,
  base : UInt64,
  count : Int,
) -> Unit raise {
  let entries = image.words(word_size~).entries()
  let step = (word_size / 8).to_uint64()
  assert_true(entries.length() == count)
  for i in 0..<count {
    let expected = base + (i * (word_size / 8)).to_uint64()
    assert_true(entries[i].0.min_addr() == expected)
    assert_true(entries[i].0.max_addr() == expected + step - 1UL)
  }
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
  let section = @image.Section::create(name=".text.hot", addr=0x4004UL, size=4)
  let image = @image.Image::from_segments(
    entry=0x4004UL,
    endian=LittleEndian,
    [text],
    sections=[section],
    symbols=[symbol],
    filename="a.out",
  )
  assert_true(image.entry_point() == 0x4004UL)
  assert_true(image.filename() == Some("a.out"))
  assert_true(image.addr_size() == 32)
  assert_true(image.arch().is_unknown())
  assert_true(text.is_executable())
  assert_true(image.memory().lookup(0x4004UL).length() == 1)
  assert_true(image.sections_of_segment(text).length() == 1)
  assert_true(image.segment_of_symbol(symbol) is Some(_))
  assert_true(image.symbols_of_segment(text).length() == 1)
  match image.memory_of_section(section) {
    Some(mem) => inspect(mem.hexdump(), content="04 05 06 07")
    None => fail("expected section memory")
  }
  match image.memory_of_symbol(symbol) {
    Some((mem, rest)) => {
      assert_true(rest.length() == 0)
      inspect(mem.hexdump(), content="04 05 06 07")
    }
    None => fail("expected symbol memory")
  }
}

///|
test "image address size follows target metadata" {
  let segment = @image.Segment::create(
    name=".raw",
    endian=LittleEndian,
    addr=0UL,
    b"\x00",
  )
  let unknown = @image.Image::from_segments(entry=0UL, endian=LittleEndian, [
    segment,
  ])
  assert_true(unknown.addr_size() == 32)
  let amd64 = @image.Image::from_segments(
    entry=0UL,
    endian=LittleEndian,
    [segment],
    target=@core_theory.Target::x86_64(),
  )
  assert_true(amd64.addr_size() == 64)
  assert_true(amd64.arch().matches("x86_64"))
  let spec = amd64.spec()
  assert_true(spec.fact_count("arch") == 1)
  assert_true(spec.fact_count("bits") == 1)
  assert_true(spec.fact_count("is-little-endian") == 1)
  assert_true(spec.facts("arch")[0].value("name") == Some("x86_64"))
  assert_true(spec.facts("bits")[0].value("size") == Some("64"))
}

///|
test "image symbol memory can span contiguous segment chunks" {
  let first = @image.Segment::create(
    name=".a",
    endian=LittleEndian,
    addr=0x1000UL,
    b"\x00\x01\x02\x03",
  )
  let second = @image.Segment::create(
    name=".b",
    endian=LittleEndian,
    addr=0x1004UL,
    b"\x04\x05\x06",
  )
  let symbol = @image.Symbol::create(name="span", addr=0x1002UL, size=5)
  let image = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [first, second],
    symbols=[symbol],
  )
  match image.memories_of_symbol(symbol) {
    Some(chunks) => {
      assert_true(chunks.length() == 2)
      inspect(chunks[0].hexdump(), content="02 03")
      inspect(chunks[1].hexdump(), content="04 05 06")
    }
    None => fail("expected symbol chunks")
  }
  match image.memory_of_symbol(symbol) {
    Some((head, rest)) => {
      inspect(head.hexdump(), content="02 03")
      assert_true(rest.length() == 1)
      inspect(rest[0].hexdump(), content="04 05 06")
    }
    None => fail("expected symbol memory tuple")
  }
}

///|
test "image symbol memory rejects gaps across segments" {
  let first = @image.Segment::create(
    name=".a",
    endian=LittleEndian,
    addr=0x1000UL,
    b"\x00\x01\x02\x03",
  )
  let second = @image.Segment::create(
    name=".b",
    endian=LittleEndian,
    addr=0x1008UL,
    b"\x08\x09",
  )
  let symbol = @image.Symbol::create(name="gap", addr=0x1002UL, size=5)
  let image = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [first, second],
    symbols=[symbol],
  )
  assert_true(image.memories_of_symbol(symbol) is None)
  assert_true(image.memory_of_symbol(symbol) is None)
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

///|
test "translated BAP image words keep high-base addresses contiguous by word size" {
  let base = 0x1000ffUL
  let segments = [
    for i in 0..<4 => {
      let first = i * 16
      @image.Segment::create(
        name=".high\{i}",
        endian=LittleEndian,
        addr=base + first.to_uint64(),
        bytes_from_range(first, 16),
      )
    }
  ]
  let image = @image.Image::from_segments(
    entry=base,
    endian=LittleEndian,
    segments,
  )
  assert_contiguous_word_addresses(image, 8, base, 64)
  assert_contiguous_word_addresses(image, 16, base, 32)
  assert_contiguous_word_addresses(image, 32, base, 16)
  assert_contiguous_word_addresses(image, 64, base, 8)
  let words = image.words(word_size=16).entries().map(entry => entry.1.to_hex())
  assert_true(words[0:4].to_owned() == ["0x0100", "0x0302", "0x0504", "0x0706"])
  assert_true(
    words[28:32].to_owned() == ["0x3938", "0x3b3a", "0x3d3c", "0x3f3e"],
  )
}

///|
test "translated BAP image words expose expected byte and int64 lists" {
  let little = @image.Image::from_segments(entry=0UL, endian=LittleEndian, [
    @image.Segment::create(
      name=".le",
      endian=LittleEndian,
      addr=0UL,
      bytes_0_to_15(),
    ),
  ])
  let big = @image.Image::from_segments(entry=0UL, endian=BigEndian, [
    @image.Segment::create(
      name=".be",
      endian=BigEndian,
      addr=0UL,
      bytes_0_to_15(),
    ),
  ])
  let le64 = little.words(word_size=64).entries().map(entry => entry.1.to_hex())
  let be64 = big.words(word_size=64).entries().map(entry => entry.1.to_hex())
  assert_true(le64 == ["0x0706050403020100", "0x0f0e0d0c0b0a0908"])
  assert_true(be64 == ["0x0001020304050607", "0x08090a0b0c0d0e0f"])
  let segments = [
    for i in 0..<4 => {
      let base = i * 16
      @image.Segment::create(
        name=".seg\{i}",
        endian=LittleEndian,
        addr=base.to_uint64(),
        bytes_from_range(base, 16),
      )
    }
  ]
  let many = @image.Image::from_segments(
    entry=0UL,
    endian=LittleEndian,
    segments,
  )
  let bytes = many.words(word_size=8).entries()
  assert_true(bytes.length() == 64)
  inspect(bytes[0].1.to_hex(), content="0x00")
  inspect(bytes[15].1.to_hex(), content="0x0f")
  inspect(bytes[16].1.to_hex(), content="0x10")
  inspect(bytes[63].1.to_hex(), content="0x3f")
}

///|
test "translated BAP image words preserve gapped segment addresses" {
  let segments = [
    for base in [0x000UL, 0x10dUL, 0x21aUL, 0x327UL] => {
      @image.Segment::create(
        name=".gap",
        endian=LittleEndian,
        addr=base,
        bytes_0_to_15(),
      )
    }
  ]
  let image = @image.Image::from_segments(
    entry=0UL,
    endian=LittleEndian,
    segments,
  )
  let words = image.words(word_size=8)
  assert_true(words.length() == 64)
  match (words.min_binding(), words.max_binding()) {
    (Some((min_mem, min_word)), Some((max_mem, max_word))) => {
      assert_true(min_mem.min_addr() == 0UL)
      assert_true(max_mem.min_addr() == 0x336UL)
      assert_true(max_mem.min_addr() - min_mem.min_addr() == 0x336UL)
      inspect(min_word.to_hex(), content="0x00")
      inspect(max_word.to_hex(), content="0x0f")
    }
    _ => fail("expected word min/max bindings")
  }
  assert_true(words.lookup(0x10dUL).length() == 1)
  assert_true(words.lookup(0x10cUL).is_empty())
  assert_true(words.lookup(0x21aUL).length() == 1)
}

///|
test "translated BAP image words enumerate out-of-order segments by address" {
  let high = @image.Segment::create(
    name=".high",
    endian=LittleEndian,
    addr=0x20UL,
    bytes_from_range(0x20, 16),
  )
  let low = @image.Segment::create(
    name=".low",
    endian=LittleEndian,
    addr=0UL,
    bytes_from_range(0, 16),
  )
  let middle = @image.Segment::create(
    name=".middle",
    endian=LittleEndian,
    addr=0x10UL,
    bytes_from_range(0x10, 16),
  )
  let image = @image.Image::from_segments(entry=0UL, endian=LittleEndian, [
    high, low, middle,
  ])
  let entries = image.words(word_size=8).entries()
  assert_true(entries.length() == 48)
  assert_true(entries[0].0.min_addr() == 0UL)
  inspect(entries[0].1.to_hex(), content="0x00")
  inspect(entries[15].1.to_hex(), content="0x0f")
  assert_true(entries[16].0.min_addr() == 0x10UL)
  inspect(entries[16].1.to_hex(), content="0x10")
  inspect(entries[31].1.to_hex(), content="0x1f")
  assert_true(entries[32].0.min_addr() == 0x20UL)
  inspect(entries[32].1.to_hex(), content="0x20")
  inspect(entries[47].1.to_hex(), content="0x2f")
}

///|
test "image backends can be registered and used for byte loading" {
  let backend = @image.ImageBackend::create(
    name="unit-raw",
    description="raw bytes",
    extensions=["raw", "bin"],
    priority=10,
    load=data => {
      let segment = @image.Segment::create(
        name=".raw",
        endian=LittleEndian,
        addr=0x80UL,
        data,
      )
      Ok(
        (
          @image.Image::from_segments(entry=0x80UL, endian=LittleEndian, [
            segment,
          ]),
          ["loaded"],
        ),
      )
    },
  )
  match @image.register_backend(name="unit-raw", backend) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@image.find_backend("unit-raw") is Some(_))
  assert_true(@image.available_backends().contains("unit-raw"))
  assert_true(backend.description() == "raw bytes")
  assert_true(backend.extensions() == ["raw", "bin"])
  assert_true(backend.priority() == 10)
  assert_true(backend.supports_extension("raw"))
  match @image.Image::of_bytes(b"\xaa\xbb", backend="unit-raw") {
    Ok((img, warnings)) => {
      assert_true(warnings == ["loaded"])
      assert_true(img.memory().lookup(0x81UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  match @image.Image::of_bigstring(b"\xcc\xdd", backend="unit-raw") {
    Ok((img, warnings)) => {
      assert_true(warnings == ["loaded"])
      assert_true(img.memory().lookup(0x81UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  match @image.Image::of_string("Aé", backend="unit-raw") {
    Ok((img, warnings)) => {
      assert_true(warnings == ["loaded"])
      assert_true(img.memory().lookup(0x82UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  assert_true(@image.register_backend(name="unit-raw", backend) is Err(_))
}

///|
test "image backend discovery returns extension matches by priority" {
  let low = @image.ImageBackend::create(
    name="unit-low-priority",
    extensions=["unit"],
    priority=1,
    load=_ => Err("unused"),
  )
  let high = @image.ImageBackend::create(
    name="unit-high-priority",
    extensions=["unit"],
    priority=100,
    load=_ => Err("unused"),
  )
  match @image.register_backend(name="unit-low-priority", low) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @image.register_backend(name="unit-high-priority", high) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(
    @image.backend_names_for_extension("unit") ==
    ["unit-high-priority", "unit-low-priority"],
  )
  assert_true(@image.backends_for_extension("missing").is_empty())
}

///|
test "image registers built-in raw and Ogre backends idempotently" {
  match @image.register_builtin_backends() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @image.register_builtin_backends() {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@image.find_backend("raw") is Some(_))
  assert_true(@image.find_backend("ogre") is Some(_))
  assert_true(@image.backend_names_for_extension("raw").contains("raw"))
  assert_true(@image.backend_names_for_extension("bin").contains("raw"))
  assert_true(@image.backend_names_for_extension("ogre").contains("ogre"))
  match @image.Image::of_bytes(b"\xaa\xbb", backend="raw") {
    Ok((img, warnings)) => {
      assert_true(warnings.is_empty())
      assert_true(img.segments().length() == 1)
      assert_true(img.segments()[0].name() == ".raw")
      assert_true(img.segments()[0].is_executable())
      assert_true(img.memory().lookup(0x01UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  let spec = "(declare arch (name str))" +
    " (declare bits (size int))" +
    " (declare entry-point (addr int))" +
    " (declare is-little-endian (flag bool))" +
    " (arch riscv64)" +
    " (bits 64)" +
    " (entry-point 0)" +
    " (is-little-endian true)"
  match @image.Image::of_bytes(@utf8.encode(spec), backend="ogre") {
    Ok((img, warnings)) => {
      assert_true(warnings.is_empty())
      assert_true(img.entry_point() == 0UL)
      assert_true(img.segments().is_empty())
      match img.target() {
        Some(target) => {
          assert_true(target.matches("riscv64"))
          assert_true(target.bits() == 64)
          assert_true(target.endianness() == LittleEndian)
        }
        None => fail("expected Ogre target")
      }
    }
    Err(reason) => fail(reason)
  }
  match
    @image.Image::of_bytes_for_filename(
      @utf8.encode(spec),
      filename="unit.OGRE",
    ) {
    Ok((img, warnings)) => {
      assert_true(warnings.is_empty())
      assert_true(img.arch().matches("riscv64"))
    }
    Err(reason) => fail(reason)
  }
  assert_true(@image.Image::of_bytes(b"\xff", backend="ogre") is Err(_))
}

///|
test "image backend discovery loads bytes by filename extension" {
  let failing = @image.ImageBackend::create(
    name="unit-image-failing-loader",
    extensions=["imgunit"],
    priority=100,
    load=_ => Err("not this backend"),
  )
  let fallback = @image.ImageBackend::create(
    name="unit-image-fallback-loader",
    extensions=["imgunit"],
    priority=10,
    load=data => {
      let segment = @image.Segment::create(
        name=".imgunit",
        endian=LittleEndian,
        addr=0x700UL,
        data,
      )
      Ok(
        (
          @image.Image::from_segments(entry=0x700UL, endian=LittleEndian, [
            segment,
          ]),
          ["fallback"],
        ),
      )
    },
  )
  match @image.register_backend(name="unit-image-failing-loader", failing) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @image.register_backend(name="unit-image-fallback-loader", fallback) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(
    @image.backend_names_for_extension("imgunit") ==
    ["unit-image-failing-loader", "unit-image-fallback-loader"],
  )
  match
    @image.Image::of_bytes_for_filename(b"\xaa", filename="sample.IMGUNIT") {
    Ok((img, warnings)) => {
      assert_true(warnings == ["fallback"])
      assert_true(img.memory().lookup(0x700UL).length() == 1)
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    @image.Image::of_bytes_for_filename(b"", filename="sample") is Err(_),
  )
  assert_true(
    @image.Image::of_bytes_for_filename(b"", filename="sample.missing")
    is Err(_),
  )
}

///|
test "image file loading reports read errors" {
  assert_true(@image.Image::of_file("__bap_mbt_missing_image__") is Err(_))
}
