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
  assert_true(image.segment_of_symbol_exn(symbol).name() == ".text")
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
  let (memory, rest) = image.memory_of_symbol_exn(symbol)
  assert_true(rest.length() == 0)
  inspect(memory.hexdump(), content="04 05 06 07")
}

///|
test "image exposes BAP top-level loading and accessors" {
  let text = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x5000UL,
    bytes_0_to_15(),
    executable=true,
  )
  let symbol = @image.Symbol::create(
    name="entry",
    addr=0x5002UL,
    size=4,
    is_function=true,
  )
  let image = @image.Image::from_segments(
    entry=0x5002UL,
    endian=LittleEndian,
    [text],
    symbols=[symbol],
    filename="top.bin",
    target=@core_theory.Target::x86_64(),
  )
  assert_true(@image.entry_point(image) == 0x5002UL)
  assert_true(@image.filename(image) == Some("top.bin"))
  assert_true(@image.addr_size(image) == 64)
  assert_true(@image.arch(image).matches("x86_64"))
  assert_true(@image.endian(image) == LittleEndian)
  assert_true(@image.segments(image).length() == 1)
  assert_true(@image.symbols(image).length() == 1)
  assert_true(@image.memory(image).lookup(0x5002UL).length() == 1)
  inspect(
    @image.memory_of_segment(image, text).hexdump(),
    content="00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f",
  )
  let (memory, rest) = @image.memory_of_symbol(image, symbol)
  assert_true(rest.is_empty())
  inspect(memory.hexdump(), content="02 03 04 05")
  assert_true(@image.symbols_of_segment(image, text).length() == 1)
  assert_true(@image.segment_of_symbol(image, symbol).name() == ".text")
  assert_true(@image.words(image, 16).lookup(0x5002UL).length() == 1)
  assert_true(@image.spec(image).fact_count("arch") == 1)
  assert_true(@image.data(image).is_empty())

  match @image.of_bigstring(b"\xaa\xbb") {
    Ok((loaded, warnings)) => {
      assert_true(warnings.is_empty())
      assert_true(@image.data(loaded) == b"\xaa\xbb")
    }
    Err(reason) => fail(reason)
  }
  match @image.of_string("Aé") {
    Ok((loaded, warnings)) => {
      assert_true(warnings.is_empty())
      assert_true(@image.data(loaded) == @utf8.encode("Aé"))
    }
    Err(reason) => fail(reason)
  }
  let doc = match
    @image.OgreDoc::from_string(
      "(declare entry-point (addr int)) (entry-point 80)",
    ) {
    Ok(doc) => doc
    Err(reason) => fail(reason)
  }
  match @image.from_spec(b"\x90", doc) {
    Ok((loaded, warnings)) => {
      assert_true(warnings.is_empty())
      assert_true(@image.entry_point(loaded) == 80UL)
    }
    Err(reason) => fail(reason)
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
test "image segments and symbols expose BAP regular facades" {
  let text = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x4000UL,
    bytes_0_to_15(),
    offset=64,
    executable=true,
  )
  let text_copy = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x4000UL,
    bytes_from_range(100, 16),
    offset=64,
    executable=true,
  )
  let later_text = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x4010UL,
    bytes_0_to_15(),
    offset=64,
    executable=true,
  )
  let data = @image.Segment::create(
    name=".data",
    endian=LittleEndian,
    addr=0x4000UL,
    bytes_0_to_15(),
  )
  inspect(text.to_string(), content=".text 16384 16")
  assert_true(@image.Segment::module_name() == Some("Bap.Std.Image.Segment"))
  assert_true(@image.Segment::version() == "2.0.0")
  assert_true(text.equal(text_copy))
  assert_true(!text.equal(later_text))
  assert_true(text.compare(later_text) < 0)
  assert_true(data.compare(text) < 0)
  assert_true(text.hash() == data.hash())

  let main = @image.Symbol::create(
    name="main",
    addr=0x4004UL,
    size=4,
    is_function=true,
  )
  let main_copy = @image.Symbol::create(
    name="main",
    addr=0x4004UL,
    size=4,
    is_function=true,
  )
  let debug_main = @image.Symbol::create(
    name="main",
    addr=0x4004UL,
    size=4,
    is_debug=true,
  )
  let later_main = @image.Symbol::create(
    name="main",
    addr=0x4008UL,
    size=4,
    is_function=true,
  )
  inspect(main.to_string(), content="main 16388 4")
  assert_true(@image.Symbol::module_name() == Some("Bap.Std.Image.Symbol"))
  assert_true(@image.Symbol::version() == "2.0.0")
  assert_true(main.equal(main_copy))
  assert_true(!main.equal(debug_main))
  assert_true(main.compare(later_main) < 0)
  assert_true(debug_main.compare(main) < 0)
  assert_true(main.hash() == debug_main.hash())
}

///|
test "image exposes BAP tag and specification facades" {
  let segment_tag = @image.segment()
  assert_true(segment_tag.name() == "segment")
  assert_true(segment_tag.uuid() == "a0eec123-5937-4283-b141-58d579a9b0df")
  let symbol_tag = @image.symbol()
  assert_true(symbol_tag.name() == "symbol")
  assert_true(symbol_tag.uuid() == "768bc13d-d4be-43fc-9f7a-c369ebab9c7e")
  let section_tag = @image.section()
  assert_true(section_tag.name() == "section")
  assert_true(section_tag.uuid() == "4014408d-a3af-488f-865b-5413beaf198e")
  let code_region_tag = @image.code_region()
  assert_true(code_region_tag.name() == "code-region")
  assert_true(code_region_tag.uuid() == "5296b7e9-d5c3-40ce-98ba-7655ec68fad7")
  let specification_tag = @image.specification()
  assert_true(specification_tag.name() == "image-specification")
  assert_true(
    specification_tag.uuid() == "a0c98f1f-3693-412a-a11a-2b6c3f6935a7",
  )
  let spec = @image.Spec::from_arch(@core_theory.Target::x86_64())
  assert_true(spec.fact_count("arch") == 1)
  assert_true(spec.fact_count("bits") == 1)
  assert_true(spec.fact_count("is-little-endian") == 1)
  assert_true(spec.facts("arch")[0].value("name") == Some("x86_64"))
  let slot = @image.Spec::slot()
  assert_true(
    slot.owner().show() == @core_theory.ProgramUnit::cls().name().show(),
  )
  assert_true(slot.name().show() == "bap:unit-spec")
  assert_true(slot.domain().name().show() == "bap:spec")
  assert_true(slot.domain().is_empty(@image.OgreDoc::empty()))
  assert_true(!slot.domain().is_empty(spec))
  match slot.persistent() {
    Some(codec) =>
      match codec.decode(codec.encode(spec)) {
        Ok(decoded) => {
          assert_true(decoded.fact_count("arch") == 1)
          assert_true(decoded.facts("arch")[0].value("name") == Some("x86_64"))
        }
        Err(reason) => fail(reason)
      }
    None => fail("expected persistent unit-spec slot")
  }
  let arm_target = @core_theory.Target::arm()
  let arm = @image.Spec::from_arch(arm_target)
  match slot.domain().join(@image.OgreDoc::empty(), arm) {
    Ok(joined) =>
      assert_true(
        joined.facts("arch")[0].value("name") ==
        Some(arm_target.name().unqualified()),
      )
    Err(reason) => fail(reason)
  }
  match slot.domain().join(spec, arm) {
    Ok(joined) => assert_true(joined.fact_count("arch") == 2)
    Err(reason) => fail(reason)
  }
  let lhs = match
    @image.OgreDoc::from_string("(declare conflict (value str))") {
    Ok(doc) => doc
    Err(reason) => fail(reason)
  }
  let rhs = match
    @image.OgreDoc::from_string("(declare conflict (value int))") {
    Ok(doc) => doc
    Err(reason) => fail(reason)
  }
  match slot.domain().join(lhs, rhs) {
    Ok(_) => fail("expected conflicting Ogre declarations")
    Err(reason) => assert_true(reason.contains("conflicting Ogre declaration"))
  }
}

///|
test "image exposes relocation metadata defensively" {
  let segment = @image.Segment::create(
    name=".raw",
    endian=LittleEndian,
    addr=0x1000UL,
    b"\x00",
  )
  let relocations = [@image.Relocation::create(fixup=0x1004UL, target=0x2000UL)]
  let references = [
    @image.ExternalReference::create(addr=0x1008UL, name="puts"),
  ]
  let required_libraries = ["libc.so.6"]
  let rpaths = ["/opt/lib"]
  let runpaths = ["$ORIGIN/lib"]
  let symbol_values = [@image.SymbolValue::create(addr=0x1000UL, value=0x80UL)]
  let image = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [segment],
    relocations~,
    external_references=references,
    required_libraries~,
    rpaths~,
    runpaths~,
    symbol_values~,
    interpreter="/lib64/ld-linux-x86-64.so.2",
    soname="libdemo.so",
    load_bias=-16L,
    is_executable=true,
    base_address=0x1000UL,
  )
  relocations.push(@image.Relocation::create(fixup=0x1010UL, relative=true))
  references.push(@image.ExternalReference::create(addr=0x1018UL, name="exit"))
  required_libraries.push("libm.so.6")
  rpaths.push("/mutated")
  runpaths.push("/mutated-run")
  symbol_values.push(@image.SymbolValue::create(addr=0x1001UL, value=0x81UL))
  assert_true(image.base_address() == Some(0x1000UL))
  assert_true(image.relocations().length() == 1)
  assert_true(image.relocations()[0].fixup() == 0x1004UL)
  assert_true(image.relocations()[0].target() == Some(0x2000UL))
  assert_true(image.relocations()[0].addend() == None)
  assert_true(!image.relocations()[0].uses_memory_addend())
  assert_true(image.external_references().length() == 1)
  assert_true(image.external_references()[0].name() == "puts")
  assert_true(image.required_libraries() == ["libc.so.6"])
  assert_true(image.rpaths() == ["/opt/lib"])
  assert_true(image.runpaths() == ["$ORIGIN/lib"])
  assert_true(image.symbol_values().length() == 1)
  assert_true(image.symbol_values()[0].value() == 0x80UL)
  assert_true(image.interpreter() == Some("/lib64/ld-linux-x86-64.so.2"))
  assert_true(image.soname() == Some("libdemo.so"))
  assert_true(image.load_bias() == Some(-16L))
  assert_true(image.is_executable() == Some(true))
  let updated = image
    .add_relocation(@image.Relocation::create(fixup=0x1010UL, relative=true))
    .add_external_reference(
      @image.ExternalReference::create(addr=0x1018UL, name="exit"),
    )
    .add_required_library("libm.so.6")
    .add_rpath("/vendor/lib")
    .add_runpath("$ORIGIN/plugins")
    .add_symbol_value(@image.SymbolValue::create(addr=0x1001UL, value=0x81UL))
    .with_interpreter("/lib/ld.so")
    .with_soname("libupdated.so")
    .with_load_bias(32L)
    .with_is_executable(false)
    .with_base_address(0x3000UL)
  assert_true(image.base_address() == Some(0x1000UL))
  assert_true(updated.base_address() == Some(0x3000UL))
  assert_true(updated.relocations().length() == 2)
  assert_true(updated.relocations()[1].is_relative())
  assert_true(updated.external_references().length() == 2)
  assert_true(updated.required_libraries() == ["libc.so.6", "libm.so.6"])
  assert_true(updated.rpaths() == ["/opt/lib", "/vendor/lib"])
  assert_true(updated.runpaths() == ["$ORIGIN/lib", "$ORIGIN/plugins"])
  assert_true(updated.symbol_values().length() == 2)
  assert_true(updated.interpreter() == Some("/lib/ld.so"))
  assert_true(updated.soname() == Some("libupdated.so"))
  assert_true(updated.load_bias() == Some(32L))
  assert_true(updated.is_executable() == Some(false))
}

///|
test "image applies relocation fixups immutably" {
  let segment = @image.Segment::create(
    name=".data",
    endian=LittleEndian,
    addr=0x1000UL,
    b"\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00",
    writable=true,
  )
  let image = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [segment],
    relocations=[
      @image.Relocation::create(fixup=0x1000UL, target=0x1122334455667788UL),
      @image.Relocation::create(fixup=0x1008UL, relative=true),
    ],
    base_address=0x1000UL,
    target=@core_theory.Target::x86_64(),
  )
  match image.with_applied_relocations() {
    Ok(applied) => {
      inspect(
        applied.segments()[0].memory().hexdump(),
        content="88 77 66 55 44 33 22 11 20 10 00 00 00 00 00 00",
      )
      inspect(
        image.segments()[0].memory().hexdump(),
        content="00 00 00 00 00 00 00 00 20 00 00 00 00 00 00 00",
      )
    }
    Err(reason) => fail(reason)
  }
  let missing_base = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [segment],
    relocations=[@image.Relocation::create(fixup=0x1008UL, relative=true)],
    target=@core_theory.Target::x86_64(),
  )
  assert_true(missing_base.with_applied_relocations() is Err(_))
}

///|
test "image applies relocation addends" {
  let segment = @image.Segment::create(
    name=".data",
    endian=LittleEndian,
    addr=0x1000UL,
    b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
    writable=true,
  )
  let image = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [segment],
    relocations=[
      @image.Relocation::create(fixup=0x1000UL, target=0x4000UL, addend=8L),
      @image.Relocation::create(fixup=0x1008UL, addend=0x30L, relative=true),
      @image.Relocation::create(fixup=0x1010UL, addend=-8L, relative=true),
    ],
    base_address=0x1000UL,
    target=@core_theory.Target::x86_64(),
  )
  match image.with_applied_relocations() {
    Ok(applied) =>
      inspect(
        applied.segments()[0].memory().hexdump(),
        content="08 40 00 00 00 00 00 00 30 10 00 00 00 00 00 00 f8 0f 00 00 00 00 00 00",
      )
    Err(reason) => fail(reason)
  }
}

///|
test "image applies memory addend relocations" {
  let text = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x1000UL,
    b"\x90\xc3\x00\x00\x00\x00\x00\x00",
    executable=true,
  )
  let data = @image.Segment::create(
    name=".data",
    endian=LittleEndian,
    addr=0x2000UL,
    b"\x20\x00\x00\x00\x00\x00\x00\x00",
    writable=true,
  )
  let image = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [text, data],
    relocations=[
      @image.Relocation::create(
        fixup=0x2000UL,
        target=0x4000UL,
        memory_addend=true,
      ),
    ],
    target=@core_theory.Target::x86_64(),
  )
  assert_true(image.relocations()[0].uses_memory_addend())
  match image.with_applied_relocations() {
    Ok(applied) => {
      inspect(
        applied.segments()[0].memory().hexdump(),
        content="90 c3 00 00 00 00 00 00",
      )
      inspect(
        applied.segments()[1].memory().hexdump(),
        content="20 40 00 00 00 00 00 00",
      )
    }
    Err(reason) => fail(reason)
  }
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
  let chunks = image.memories_of_symbol_exn(symbol)
  assert_true(chunks.length() == 2)
  inspect(chunks[0].hexdump(), content="02 03")
  inspect(chunks[1].hexdump(), content="04 05 06")
  match image.memory_of_symbol(symbol) {
    Some((head, rest)) => {
      inspect(head.hexdump(), content="02 03")
      assert_true(rest.length() == 1)
      inspect(rest[0].hexdump(), content="04 05 06")
    }
    None => fail("expected symbol memory tuple")
  }
  let (head, rest) = image.memory_of_symbol_exn(symbol)
  inspect(head.hexdump(), content="02 03")
  assert_true(rest.length() == 1)
  inspect(rest[0].hexdump(), content="04 05 06")
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
  try image.memories_of_symbol_exn(symbol) catch {
    MissingImageSymbolMemory(name, addr, size) => {
      assert_true(name == "gap")
      assert_true(addr == 0x1002UL)
      assert_true(size == 5)
    }
    _ => fail("expected MissingImageSymbolMemory")
  } noraise {
    _ => fail("expected memories_of_symbol_exn failure")
  }
  try image.memory_of_symbol_exn(symbol) catch {
    MissingImageSymbolMemory(name, addr, size) => {
      assert_true(name == "gap")
      assert_true(addr == 0x1002UL)
      assert_true(size == 5)
    }
    _ => fail("expected MissingImageSymbolMemory")
  } noraise {
    _ => fail("expected memory_of_symbol_exn failure")
  }
  let missing = @image.Symbol::create(name="outside", addr=0x2000UL, size=1)
  try image.segment_of_symbol_exn(missing) catch {
    MissingImageSegment(name, addr) => {
      assert_true(name == "outside")
      assert_true(addr == 0x2000UL)
    }
    _ => fail("expected MissingImageSegment")
  } noraise {
    _ => fail("expected segment_of_symbol_exn failure")
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
test "image loader registry builds images from Ogre documents" {
  let spec = "(declare entry-point (addr int))" +
    " (declare mapped (addr int) (size int) (off int))" +
    " (declare named-region (addr int) (size int) (name str))" +
    " (declare segment (addr int) (size int) (r bool) (w bool) (x bool))" +
    " (entry-point 16)" +
    " (mapped 16 2 0)" +
    " (named-region 16 2 loaded)" +
    " (segment 16 2 true false true)"
  let loader = @image.ImageLoader::create(from_data=_ => {
    match @image.OgreDoc::from_string(spec) {
      Ok(doc) => Ok(Some(doc))
      Err(reason) => Err(reason)
    }
  })
  match @image.register_loader(name="unit-ogre-doc-loader", loader) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@image.find_loader("unit-ogre-doc-loader") is Some(_))
  assert_true(@image.available_loaders().contains("unit-ogre-doc-loader"))
  match @image.Image::of_bytes(b"\xaa\xbb", backend="unit-ogre-doc-loader") {
    Ok((img, warnings)) => {
      assert_true(warnings.is_empty())
      assert_true(img.entry_point() == 16UL)
      assert_true(img.segments().length() == 1)
      assert_true(img.segments()[0].addr() == 16UL)
      inspect(img.segments()[0].memory().hexdump(), content="aa bb")
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    @image.register_loader(name="unit-ogre-doc-loader", loader) is Err(_),
  )
  let empty_loader = @image.ImageLoader::create(from_data=_ => Ok(None))
  match @image.register_loader(name="unit-empty-doc-loader", empty_loader) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(
    @image.Image::of_bytes(b"\xaa\xbb", backend="unit-empty-doc-loader")
    is Err(_),
  )
}

///|
test "image exposes BAP KB loader registration facade" {
  let spec = "(declare entry-point (addr int))" +
    " (declare mapped (addr int) (size int) (off int))" +
    " (declare named-region (addr int) (size int) (name str))" +
    " (declare segment (addr int) (size int) (r bool) (w bool) (x bool))" +
    " (entry-point 48)" +
    " (mapped 48 2 0)" +
    " (named-region 48 2 kb-loaded)" +
    " (segment 48 2 true false true)"
  match
    @image.KB::register_loader(
      name="unit-kb-ogre-doc-loader",
      from_file=_ => Ok(None),
      from_data=_ => {
        match @image.OgreDoc::from_string(spec) {
          Ok(doc) => Ok(Some(doc))
          Err(reason) => Err(reason)
        }
      },
    ) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@image.find_loader("unit-kb-ogre-doc-loader") is Some(_))
  match @image.Image::of_bytes(b"\x11\x22", backend="unit-kb-ogre-doc-loader") {
    Ok((img, warnings)) => {
      assert_true(warnings.is_empty())
      assert_true(img.entry_point() == 48UL)
      assert_true(img.segments().length() == 1)
      assert_true(img.segments()[0].name() == "kb-loaded")
      inspect(img.segments()[0].memory().hexdump(), content="11 22")
    }
    Err(reason) => fail(reason)
  }
  assert_true(
    @image.KB::register_loader(
      name="unit-kb-ogre-doc-loader",
      from_file=_ => Ok(None),
      from_data=_ => Ok(None),
    )
    is Err(_),
  )
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
      assert_true(img.base_address() == Some(0UL))
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
