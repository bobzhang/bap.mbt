///|
/// A toy MIPS decoder: `jr ra` (0x03e00008) is a return, `nop` (0) a no-op,
/// and the other words are invalid.
fn mc_decoder_toy_mips() -> @mc.Decoder {
  @mc.Decoder::create(
    "toy-mips",
    accepts=ctx => ctx.encoded_as(@core_theory.Language::llvm_mips32()),
    decode=(ctx, bytes, addr) => {
      if bytes.length() < 4 {
        return Truncated
      }
      let word = (bytes[0].to_int() << 24) |
        (bytes[1].to_int() << 16) |
        (bytes[2].to_int() << 8) |
        bytes[3].to_int()
      let (name, kinds) : (String, Array[@mc.Kind]) = match word {
        0x03e00008 => ("JR", [Return, Barrier, Terminator])
        0 => ("NOP", [])
        _ => return Invalid(size=4)
      }
      Decoded(
        @mc.Insn::create(
          name,
          [],
          addr~,
          size=4,
          encoding=ctx.encoding(),
          kinds~,
          raw=bytes[:4].to_owned(),
        ),
      )
    },
  )
}

///|
test "the Basic disassembler decodes with the registered @mc decoders" {
  let target = @core_theory.Target::mips()
  let encoding = @core_theory.Language::llvm_mips32()
  // there is no built-in MIPS decoder
  assert_true(
    @project.ProjectDisassemblyBasic::lookup(target, encoding) is Err(_),
  )
  @mc.register_decoder(mc_decoder_toy_mips())
  let result = try {
    guard @project.ProjectDisassemblyBasic::lookup(target, encoding) is Ok(dis) else {
      fail("no disassembler for the registered decoder")
    }
    assert_eq(dis.backend(), "toy-mips")
    let memory = @memory.Memory::from_bytes(
      endian=BigEndian,
      start=0x1000UL,
      b"\x00\x00\x00\x00\xff\xff\xff\xff\x03\xe0\x00\x08\x00\x00",
    )
    let insns = dis.run(memory, init=(), return_=_ => [], stopped=(s, _) => {
      s.insns()
    })
    let listed = insns.map(item => {
      let name = match item.1 {
        Some(insn) => "\{insn.name()}:\{insn.encoding()}"
        None => "invalid"
      }
      "\{item.0.min_addr().to_string(radix=16)}+\{item.0.length()} \{name}"
    })
    // the last two bytes are too short for an instruction
    inspect(
      listed.join(", "),
      content="1000+4 NOP:llvm-mips32, 1004+4 invalid, 1008+4 JR:llvm-mips32",
    )
    guard insns[2].1 is Some(jr) else { fail("no jr") }
    assert_true(jr.has_kind(ProjectReturn))
    // `create` finds the decoder by name or, for the llvm backend, by the
    // default encoding of the target named by the triple
    assert_true(
      @project.ProjectDisassemblyBasic::create(
        target.to_string(),
        backend="toy-mips",
      )
      is Ok(_),
    )
    assert_true(
      @project.ProjectDisassemblyBasic::create(target.to_string()) is Ok(_),
    )
  } catch {
    err => Err(err)
  } noraise {
    _ => Ok(())
  }
  assert_true(@mc.unregister_decoder("toy-mips"))
  match result {
    Ok(_) => ()
    Err(err) => raise err
  }
}
