///|
test "image memory annotates ELF segments, symbols and sections" {
  guard @image.register_builtin_backends() is Ok(_) else {
    fail("can't register builtin backends")
  }
  let (image, _) = expect_elf_image(
    @image.Image::of_bytes(image_elf_test_make_x86_64(), backend="elf"),
  )
  debug_inspect(
    memory_annotations(image, 0x400000UL),
    content=(
      #|[
      #|  "segment@4194304+6=.load0 4194304 6",
      #|  "symbol@4194304+2=main",
      #|  "symbol-info@4194304+2=main 4194304 2",
      #|  "section@4194304+4=.text",
      #|]
    ),
  )
  debug_inspect(
    memory_annotations(image, 0x400002UL).map(s => {
      s.split("=").next().unwrap().to_owned()
    }),
    content=(
      #|[
      #|  "segment@4194304+6",
      #|  "section@4194304+4",
      #|  "symbol@4194306+1",
      #|  "symbol-info@4194306+1",
      #|]
    ),
  )
  // typed projections restore the annotated values
  let names = image
    .memory()
    .to_sequence()
    .filter_map(entry => entry.1.get(@image.symbol()))
  debug_inspect(names, content="[\"main\", \"data_object\"]")
  let sections = image
    .memory()
    .to_sequence()
    .filter_map(entry => entry.1.get(@image.section()))
  assert_true(sections.contains(".text"))
  let segments = image
    .memory()
    .to_sequence()
    .filter_map(entry => entry.1.get(@image.segment()))
  assert_true(segments.length() == 1 && segments[0].equal(image.segments()[0]))
  let symbol_infos = image
    .memory()
    .to_sequence()
    .filter_map(entry => entry.1.get(@image.symbol_info()))
  assert_true(symbol_infos.all(s => image.symbols().any(t => t.equal(s))))
  // the values do not project with other tags
  for entry in image.memory().to_sequence() {
    assert_true(entry.1.get(@image.code_region()) is None)
    assert_true(entry.1.get(@image.file()) is None)
  }
}

///|
test "image memory annotates code regions of the specification" {
  let spec = "(declare entry-point (addr int))" +
    " (declare named-region (addr int) (size int) (name str))" +
    " (declare code-region (addr int) (size int) (off int))" +
    " (entry-point 8192)" +
    " (named-region 8192 3 text)" +
    " (code-region 8192 3 1)"
  match @image.Image::of_ogre_string(b"\x00\x11\x22\x33\x44", spec) {
    Ok((image, _)) => {
      debug_inspect(
        memory_annotations(image, 8192UL),
        content=(
          #|["segment@8192+3=text 8192 3", "code-region@8192+3=()"]
        ),
      )
      let regions = image
        .memory()
        .to_sequence()
        .filter(entry => entry.1.has_tag(@image.code_region()))
        .map(entry => entry.0.hexdump())
      debug_inspect(regions, content="[\"11 22 33\"]")
    }
    Err(reason) => fail(reason)
  }
}

///|
test "image tags are registered with upstream identifiers" {
  let tags = [
    @image.segment().typeid(),
    @image.symbol().typeid(),
    @image.function_start().typeid(),
    @image.symbol_info().typeid(),
    @image.section().typeid(),
    @image.code_region().typeid(),
    @image.file().typeid(),
    @image.specification().typeid(),
  ]
  debug_inspect(
    tags,
    content=(
      #|[
      #|  "a0eec123-5937-4283-b141-58d579a9b0df:segment",
      #|  "768bc13d-d4be-43fc-9f7a-c369ebab9c7e:symbol",
      #|  "1c1809ec-a38a-4aee-a46c-3d49127ba85a:function-start",
      #|  "706e78cf-07de-4417-a422-effa7821dd02:symbol-info",
      #|  "4014408d-a3af-488f-865b-5413beaf198e:section",
      #|  "5296b7e9-d5c3-40ce-98ba-7655ec68fad7:code-region",
      #|  "c119f700-4069-47ad-ba99-fc29791e0d47:file",
      #|  "a0c98f1f-3693-412a-a11a-2b6c3f6935a7:image-specification",
      #|]
    ),
  )
  // specifications, section and symbol names are serializable values
  let doc = @image.Spec::from_arch(@core_theory.Target::x86_64())
  let value = @types.Value::create(@image.specification(), doc)
  let (typeid, data) = value.encode().unwrap()
  match @types.Value::decode(typeid, data) {
    Some(restored) =>
      assert_true(restored.get(@image.specification()) == Some(doc))
    None => fail("expected a restored specification")
  }
  let section = @types.Value::create(@image.section(), ".text")
  let (typeid, data) = section.encode().unwrap()
  assert_true(
    @types.Value::decode(typeid, data).map(v => v.get(@image.section())) ==
    Some(Some(".text")),
  )
}
