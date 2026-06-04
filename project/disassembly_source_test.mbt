///|
test "project disassembly source context checks path applicability" {
  match
    @project.ProjectDisassemblySourceContext::create(size=32, path="unit.bin") {
    Ok(context) => {
      assert_true(context.path() == Some("unit.bin"))
      assert_true(context.bias() == None)
      assert_true(context.size() == 32)
      assert_true(context.is_applicable())
      assert_true(context.is_applicable(path="unit.bin"))
      assert_true(!context.is_applicable(path="other.bin"))
    }
    Err(reason) => fail(reason)
  }
  match @project.ProjectDisassemblySourceContext::create(size=32) {
    Ok(context) => {
      assert_true(context.is_applicable())
      assert_true(!context.is_applicable(path="unit.bin"))
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disassembly source context converts biased label addresses" {
  let target = @core_theory.Target::x86_64()
  let base = @types.Word::of_uint64(width=64, 0x400000UL)
  let unit = @core_theory.ProgramUnit::for_file("main.o", target~, bias=base)
  let address = @types.Word::of_uint64(width=64, 0x401234UL)
  let label = @core_theory.Label::for_addr(address, target~).with_unit(unit)
  match @project.ProjectDisassemblySourceContext::for_label(label) {
    Ok(context) => {
      assert_true(context.path() == Some("main.o"))
      assert_true(context.bias() == Some(base))
      assert_true(context.size() == 64)
      match context.create_addr(0x401234UL) {
        Ok(word) => assert_true(word.to_string() == "0x401234:64u")
        Err(reason) => fail(reason)
      }
      match context.create_addr(0x401234UL, unbiased=true) {
        Ok(word) => assert_true(word.to_string() == "0x1234:64u")
        Err(reason) => fail(reason)
      }
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project disassembly source context normalizes word widths" {
  let bias = @types.Word::of_uint64(width=32, 0x1000UL)
  match @project.ProjectDisassemblySourceContext::create(size=64, bias~) {
    Ok(context) => {
      assert_true(context.bias().map(word => word.bitwidth()) == Some(64))
      let wide = @types.Word::of_uint64(width=128, 0x1100UL)
      match context.create_word_addr(wide, unbiased=true) {
        Ok(word) => assert_true(word.to_string() == "0x100:64u")
        Err(reason) => fail(reason)
      }
    }
    Err(reason) => fail(reason)
  }
  match @project.ProjectDisassemblySourceContext::create(size=0) {
    Err(reason) =>
      assert_true(
        reason ==
        "project disassembly source context requires positive address size",
      )
    Ok(_) => fail("unexpected zero-width source context")
  }
}
