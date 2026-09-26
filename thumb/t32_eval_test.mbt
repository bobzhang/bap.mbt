// End-to-end tests: decode Thumb machine code (with an IT block), lift it
// with the Thumb and ARM lifters and evaluate the BIL.

///|
test "decode, lift and run a Thumb sequence with an IT block" {
  let registry = @mc.Registry::new()
  @thumb.register(registry~)
  @arm.register(registry~)
  let ctx = @mc.Context::create(
    @core_theory.Target::thumb(),
    encoding=@core_theory.Language::llvm_t32(),
  )
  let bytes = halfwords([
    0x2005, // movs r0, #5
     0x2107, // movs r1, #7
     0x1842, // adds r2, r0, r1
     0x2A0C, // cmp r2, #12
     0xBF0C, // ite eq
     0x2301, // moveq r3, #1
     0x2302, // movne r3, #2
     0xF101, 0x0401, // add.w r4, r1, #1
     0xF44F, 0x5580, // mov.w r5, #0x1000
     0xF8C5, 0x2004, // str.w r2, [r5, #4]
     0x686E, // ldr r6, [r5, #4]
     0xFB01, 0xF702, // mul r7, r1, r2
  ])
  let decoder = @thumb.t32_decoder()
  assert_true(decoder.accepts(ctx))
  let mut state = machine([])
  let names = []
  for off = 0; off < bytes.length(); {
    guard decoder.decode(ctx, bytes[off:], 0x1000UL + off.to_uint64())
      is Decoded(insn) else {
      fail("cannot decode at \{off}")
    }
    names.push(insn.name)
    let bil = registry.lift(ctx, insn).bil() catch {
        // t2IT has no semantics
        Unsupported(..) if insn.name == "t2IT" => []
        err => raise err
      }
    state = match @types.exec_stmts(bil, state~) {
      Ok(next) => next
      Err(reason) => fail("\{insn.name}: \{reason}")
    }
    continue off + insn.size
  }
  inspect(
    names.join(" "),
    content="tMOVi8 tMOVi8 tADDrr tCMPi8 t2IT tMOVi8 tMOVi8 t2ADDri t2MOVi t2STRi12 tLDRi t2MUL",
  )
  inspect(
    [
      get(state, "R2"),
      get(state, "R3"),
      get(state, "R4"),
      get(state, "R5"),
      get(state, "R6"),
      get(state, "R7"),
    ]
    .map(v => v.to_string())
    .join(" "),
    content="12 1 8 4096 12 84",
  )
  inspect(flags(state), content="NF=0 ZF=1 CF=1 VF=0")
}
