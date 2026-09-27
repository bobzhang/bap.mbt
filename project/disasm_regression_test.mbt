///|
/// Disassembles `bytes` at `start` for `target` with the recursive driver
/// while the decoders registered by `register` are installed; the blocks
/// and the barrier jumps (by their addresses).
fn regression_disassemble(
  target : @core_theory.Target,
  endian : @bitvec.Endian,
  start : UInt64,
  bytes : Bytes,
  register : () -> Unit,
) -> (String, String, String) raise {
  guard @project.register_builtin_disassembly_drivers() is Ok(_) else {
    fail("registration failed")
  }
  let before = @mc.decoders().map(d => d.name())
  register()
  let added = @mc.decoders().map(d => d.name()).filter(n => !before.contains(n))
  let code = @memory.Memory::from_bytes(endian~, start~, bytes)
  let result = @project.Project::empty(target)
    .with_memory(@memory.MemMap::singleton(code, "code"))
    .with_symbols([
      @image.Symbol::create(name="f", addr=start, is_function=true),
    ])
    .disassemble(driver="recursive")
  // the decoders are needed by the reconstruction too
  let reconstructed = result.bind(project => project.reconstruct())
  for name in added {
    ignore(@mc.unregister_decoder(name))
  }
  guard result is Ok(project) &&
    project.disassembly_driver_state() is Some(driver) else {
    fail("disassembly failed")
  }
  let blocks = project
    .disassembly()
    .blocks()
    .map(b => b.min_addr().to_string(radix=16))
    .join(" ")
  let barriers = []
  for addr = start; addr < start + bytes.length().to_uint64(); addr = addr + 1 {
    match driver.jump(addr) {
      Some(jump) =>
        barriers.push(
          "\{addr.to_string(radix=16)}:\{if jump.is_barrier() { "barrier" } else { "falls" }}",
        )
      None => ()
    }
  }
  // the jumps of the blocks of the first subroutine of the reconstructed
  // program, with the fresh block labels and variables hidden
  guard reconstructed is Ok(reconstructed) &&
    reconstructed.program().subs() is [sub, ..] else {
    fail("reconstruction failed")
  }
  let hide = (text : String) => {
    let out = StringBuilder()
    let mut fresh = false
    for c in text {
      if c == '%' || c == '#' {
        fresh = true
        out.write_char(c)
        out.write_char('_')
      } else if fresh && c is ('0'..='9') {
        ()
      } else {
        fresh = false
        out.write_char(c)
      }
    }
    out.to_string()
  }
  let ir = sub
    .blks()
    .map(blk => blk.jmps().map(jmp => hide(jmp.jmp_to_string())).join("; "))
    .filter(text => text != "")
    .join(" | ")
  (blocks, barriers.join(" "), ir)
}

///|
test "a predicated ARM return is not a barrier" {
  // cmp r0, #1; movlt r0, #0; bxlt lr; mov r0, #1; bx lr
  let (blocks, jumps, ir) = regression_disassemble(
    @core_theory.Target::arm(),
    LittleEndian,
    0x8000UL,
    b"\x01\x00\x50\xe3\x00\x00\xa0\xb3\x1e\xff\x2f\xb1\x01\x00\xa0\xe3\x1e\xff\x2f\xe1",
    () => @arm.register_decoder(),
  )
  // the code after the conditional return is disassembled (upstream
  // `Insn.derive_props`: a conditional jump is not a barrier)
  inspect(
    blocks,
    content=(
      #|8000 800c
    ),
  )
  inspect(
    jumps,
    content=(
      #|8008:falls 8010:barrier
    ),
  )
  // the lifted block of the conditional return falls to the next block
  inspect(
    ir,
    content=(
      #|when (NF:imm1 != VF:imm1) call *LR:imm32 with noreturn; goto @0x0000800c | call *LR:imm32 with noreturn
    ),
  )
}

///|

///|
/// A lifter of the AArch64 branches of the test (the port lifts AArch64
/// with the Primus Lisp semantics, not loaded here): `b.cond` and `cbz`
/// jump under a condition, `ret` jumps to the link register.
fn regression_a64_lifter() -> @mc.Provider {
  let v = (name : String, width : Int) => {
    @types.Exp::Var(@types.Var::new(name~, typ=Imm(width)))
  }
  let target = (insn : @mc.Insn, index : Int) => {
    match insn.op(index) {
      Some(Imm(off)) =>
        @types.Exp::Int(
          @types.Word::of_uint64(
            width=64,
            insn.addr + (off * 4L).reinterpret_as_uint64(),
          ) catch {
            _ => panic()
          },
        )
      _ => panic()
    }
  }
  @mc.Provider::create(
    "a64-regression",
    accepts=ctx => ctx.encoded_as(@core_theory.Language::llvm_a64()),
    lift=(_, insn) => {
      let bil : Array[@types.Stmt] = match insn.name {
        "Bcc" => [If(cond=v("C", 1), yes=[Jmp(target(insn, 1))], no=[])]
        "CBZW" => [If(cond=v("Z", 1), yes=[Jmp(target(insn, 1))], no=[])]
        "RET" => [Jmp(v("X30", 64))]
        _ => []
      }
      @mc.Lifted::of_bil(bil)
    },
  )
}

///|
test "AArch64 conditional branches fall through, returns are barriers" {
  let registry = @mc.Registry::global()
  registry.register(regression_a64_lifter())
  // subs w8, w0, #1; b.lt +16; cbz w0, +12; mov w0, #1; ret; mov w0, wzr; ret
  let result = try
    regression_disassemble(
      @core_theory.Target::aarch64(),
      LittleEndian,
      0x1000UL,
      b"\x08\x04\x00\x71\x8b\x00\x00\x54\x60\x00\x00\x34\x20\x00\x80\x52\xc0\x03\x5f\xd6\xe0\x03\x1f\x2a\xc0\x03\x5f\xd6",
      () => @aarch64.register_decoder(),
    )
  catch {
    err => Err(err)
  } noraise {
    result => Ok(result)
  }
  ignore(registry.unregister("a64-regression"))
  guard result is Ok((blocks, jumps, ir)) else { fail("disassembly failed") }
  inspect(
    blocks,
    content=(
      #|1000 1008 100c 1014
    ),
  )
  inspect(
    ir,
    content=(
      #|when C:imm1 goto @0x0000000000001014; goto @0x0000000000001008 | when Z:imm1 goto @0x0000000000001014; goto @0x000000000000100c | call *X30:imm64 with noreturn | call *X30:imm64 with noreturn
    ),
  )
  inspect(
    jumps,
    content=(
      #|1004:falls 1008:falls 1010:barrier 1018:barrier
    ),
  )
}

///|
test "a PowerPC conditional return falls through" {
  // cmpwi 3, 0; beqlr; li 3, 1; blr
  let (blocks, jumps, ir) = regression_disassemble(
    @core_theory.Target::powerpc(),
    BigEndian,
    0x2000UL,
    b"\x2c\x03\x00\x00\x4d\x82\x00\x20\x38\x60\x00\x01\x4e\x80\x00\x20",
    () => @powerpc.register_decoder(),
  )
  inspect(
    blocks,
    content=(
      #|2000 2008
    ),
  )
  inspect(
    jumps,
    content=(
      #|2004:falls 200c:barrier
    ),
  )
  // the lifted block of the conditional return falls to the next block
  inspect(
    ir,
    content=(
      #|goto %_ | when (extract[2:2](%_#_:imm5) == 0:1u) goto %_; goto %_ | goto %_ | when (%_#_:imm1 & %_#_:imm1) call *(LR:imm32 & 0xFFFFFFFC:32u) with noreturn; goto @0x00002008 | call *(LR:imm32 & 0xFFFFFFFC:32u) with noreturn
    ),
  )
}

///|
test "AArch64 conditional branches (LLVM terminators) get fall edges" {
  guard @project.register_builtin_disassembly_drivers() is Ok(_) else {
    fail("registration failed")
  }
  let before = @mc.decoders().map(d => d.name())
  @aarch64.register_decoder()
  let registry = @mc.Registry::global()
  registry.register(regression_a64_lifter())
  // subs w8, w0, #1; b.lt +16; cbz w0, +12; mov w0, #1; ret; mov w0, wzr; ret
  let code = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1000UL,
    b"\x08\x04\x00\x71\x8b\x00\x00\x54\x60\x00\x00\x34\x20\x00\x80\x52\xc0\x03\x5f\xd6\xe0\x03\x1f\x2a\xc0\x03\x5f\xd6",
  )
  let result = @project.Project::empty(@core_theory.Target::aarch64())
    .with_memory(@memory.MemMap::singleton(code, "code"))
    .with_symbols([
      @image.Symbol::create(name="f", addr=0x1000UL, is_function=true),
    ])
    .disassemble_rec(driver="recursive")
  ignore(registry.unregister("a64-regression"))
  if !before.contains(@aarch64.a64_decoder_name) {
    ignore(@mc.unregister_decoder(@aarch64.a64_decoder_name))
  }
  let result = match result {
    Ok(result) => result
    Err(e) => fail(e)
  }
  let falls = result
    .disassembly()
    .edges()
    .filter(e => e.kind() is FallEdge)
    .map(e => {
      let target = match e.target() {
        Some(t) => t.to_string(radix=16)
        None => "?"
      }
      "\{e.source().to_string(radix=16)}->\{target}"
    })
  falls.sort()
  inspect(
    falls.join(" "),
    content=(
      #|1004->1008 1008->100c
    ),
  )
}
