// Tests of the native RISC-V decoder: instruction kinds, sizes, invalid
// and truncated input, register widths, and the `@mc` decoder.

///|
/// `NAME op op | assembly`, in the format of the samples.
fn render_insn(insn : @mc.Insn) -> String {
  let ops = insn.ops
    .iter()
    .map(op => {
      match op {
        Reg(name~, ..) => "Reg:" + name
        Imm(v) => "Imm:" + v.to_string()
        Fmm(v) => "Fmm:" + v.to_string()
      }
    })
    .collect()
  if ops.is_empty() {
    "\{insn.name} | \{insn.assembly}"
  } else {
    "\{insn.name} \{ops.join(" ")} | \{insn.assembly}"
  }
}

///|
/// The little-endian bytes of the `size`-byte instruction `value`.
fn le(value : UInt32, size : Int32) -> Bytes {
  Bytes::makei(size, i => (value >> (8 * i)).to_byte())
}

///|
/// The encoding `value` (2 or 4 bytes, by its low bits) decoded for RV64.
fn show(value : UInt32, xlen~ : @riscv.Xlen = RV64) -> String {
  let size = if (value & 3U) == 3U { 4 } else { 2 }
  match @riscv.decode(le(value, size), 0x10000UL, xlen~) {
    Some(insn) =>
      "\{render_insn(insn)} [\{insn.kinds.iter().map(k => "\{Repr(k)}").collect().join(", ")}]"
    None => "invalid"
  }
}

///|
test "decode: every sample decodes like llvm-mc" {
  let names : Map[String, Unit] = Map([])
  for sample in llvm_samples {
    let (xlen, value, size, expected) = sample
    let bytes = le(value, size)
    guard @riscv.decode(bytes, 0x10000UL, xlen~) is Some(insn) else {
      fail("0x\{value.to_string(radix=16)}: not decoded, expected \{expected}")
    }
    assert_eq(render_insn(insn), expected)
    assert_eq(insn.size, size)
    assert_eq(insn.raw, bytes)
    assert_eq(insn.encoding, @riscv.encoding(xlen))
    names[insn.name] = ()
  }
  // the number of samples and of distinct LLVM opcodes they cover
  inspect(
    llvm_samples.length(),
    content=(
      #|191
    ),
  )
  inspect(
    names.length(),
    content=(
      #|160
    ),
  )
}

///|
test "decode: control transfers and memory accesses carry LLVM's kinds" {
  // (except that the jumps that link no register, `j` and `ret`, are
  // jumps, not calls, as their compressed forms)
  let lines = [
    show(0x0080006f), // jal zero, 8
    show(0x008000ef), // jal ra, 8
    show(0x00008067), // ret
    show(0x000780e7), // jalr a5
    show(0xfe010ee3), // beqz sp, -4
    show(0x8082), // c.jr ra
    show(0x9782), // c.jalr a5
    show(0xa011), // c.j 4
    show(0xc119), // c.beqz a0, 6
    show(0x2011, xlen=RV32), // c.jal 4
    show(0x00053503), // ld a0, 0(a0)
    show(0x00b53023), // sd a1, 0(a0)
    show(0x100527af), // lr.w a5, (a0)
    show(0x00b5202f), // amoadd.w zero, a1, (a0)
    show(0x30200073), // mret
  ]
  inspect(
    lines.join("\n"),
    content=(
      #|JAL Reg:X0 Imm:8 | j 8 [UnconditionalBranch, Barrier, Terminator, MayAffectControlFlow]
      #|JAL Reg:X1 Imm:8 | jal 8 [Call, MayAffectControlFlow]
      #|JALR Reg:X0 Reg:X1 Imm:0 | ret [IndirectBranch, Barrier, Terminator, MayAffectControlFlow]
      #|JALR Reg:X1 Reg:X15 Imm:0 | jalr a5 [Call, MayAffectControlFlow]
      #|BEQ Reg:X2 Reg:X0 Imm:-4 | beqz sp, -4 [ConditionalBranch, Terminator, MayAffectControlFlow]
      #|C_JR Reg:X1 | ret [IndirectBranch, Barrier, Terminator, MayAffectControlFlow]
      #|C_JALR Reg:X15 | jalr a5 [Call, MayAffectControlFlow]
      #|C_J Imm:4 | j 4 [UnconditionalBranch, Barrier, Terminator, MayAffectControlFlow]
      #|C_BEQZ Reg:X10 Imm:6 | beqz a0, 6 [ConditionalBranch, Terminator, MayAffectControlFlow]
      #|C_JAL Imm:4 | jal 4 [Call, MayAffectControlFlow]
      #|LD Reg:X10 Reg:X10 Imm:0 | ld a0, 0(a0) [MayLoad]
      #|SD Reg:X11 Reg:X10 Imm:0 | sd a1, 0(a0) [MayStore]
      #|LR_W Reg:X15 Reg:X10 | lr.w a5, (a0) [MayLoad]
      #|AMOADD_W Reg:X0 Reg:X11 Reg:X10 | amoadd.w zero, a1, (a0) [MayLoad, MayStore]
      #|MRET | mret [Return, Barrier, Terminator, MayAffectControlFlow]
    ),
  )
}

///|
test "decode: sizes, register widths, and invalid or truncated input" {
  // too short for anything, and for a 32-bit instruction
  assert_true(@riscv.decode(b"\x13", 0UL) is None)
  assert_true(@riscv.decode(b"\x13\x05", 0UL) is None)
  // c.unimp and the reserved compressed `c.addi4spn` with a zero offset
  inspect(show(0x0000), content="C_UNIMP | unimp []")
  inspect(show(0x0004), content="invalid")
  // longer encodings are not supported
  assert_true(@riscv.decode(b"\x1f\x00\x00\x00\x00\x00", 0UL) is None)
  // with `compressed=false` 16-bit encodings are invalid
  assert_true(@riscv.decode(b"\x41\x11", 0UL, compressed=false) is None)
  // RV64-only instructions are invalid on RV32; the same halfword is
  // `c.ld` on RV64 and `c.flw` on RV32
  inspect(show(0x0005051b, xlen=RV32), content="invalid")
  inspect(
    show(0x6108),
    content="C_LD Reg:X10 Reg:X10 Imm:0 | ld a0, 0(a0) [MayLoad]",
  )
  inspect(
    show(0x6108, xlen=RV32),
    content="C_FLW Reg:F10_F Reg:X10 Imm:0 | flw fa0, 0(a0) [MayLoad]",
  )
  // the size, raw bytes, address and encoding of the decoded instructions
  guard @riscv.decode(b"\x41\x11\x13\x05", 0x2000UL) is Some(c) else {
    fail("invalid")
  }
  assert_eq(c.size, 2)
  assert_eq(c.raw, b"\x41\x11")
  assert_eq(c.next_addr(), 0x2002UL)
  assert_eq(c.encoding, @core_theory.Language::llvm_riscv64())
  guard @riscv.decode(b"\x13\x05\x15\x00", 0x2000UL, xlen=RV32) is Some(w) else {
    fail("invalid")
  }
  assert_eq(w.size, 4)
  assert_eq(w.encoding, @core_theory.Language::llvm_riscv32())
  inspect(w.assembly, content="addi a0, a0, 1")
}

///|
test "decode: the decoder of the @mc table" {
  let decoder = @riscv.decoder()
  let ctx64 = @mc.Context::create(@core_theory.Target::riscv64())
  let ctx32 = @mc.Context::create(@core_theory.Target::riscv32())
  assert_true(decoder.accepts(ctx64))
  assert_true(decoder.accepts(ctx32))
  assert_false(
    decoder.accepts(@mc.Context::create(@core_theory.Target::mips())),
  )
  assert_eq(@riscv.xlen_of_context(ctx32), RV32)
  assert_eq(@riscv.xlen_of_context(ctx64), RV64)
  debug_inspect(decoder.decode(ctx64, b"\x13", 0UL), content="Truncated")
  // a 32-bit instruction needs four bytes
  debug_inspect(
    decoder.decode(ctx64, b"\x13\x05\x15", 0UL),
    content="Truncated",
  )
  debug_inspect(
    decoder.decode(ctx64, b"\x04\x00", 0UL),
    content="Invalid(size=2)",
  )
  debug_inspect(
    decoder.decode(ctx64, b"\xff\xff\xff\xff", 0UL),
    content="Invalid(size=4)",
  )
  // `addiw` exists on RV64 only
  let addiw = b"\x1b\x05\x05\x00"
  guard decoder.decode(ctx64, addiw, 0UL) is Decoded(insn) else {
    fail("not decoded")
  }
  inspect(insn.assembly, content="sext.w a0, a0")
  debug_inspect(decoder.decode(ctx32, addiw, 0UL), content="Invalid(size=4)")
  // registration is idempotent
  @riscv.register_decoder()
  @riscv.register_decoder()
  assert_eq(
    @mc.decoders().filter(d => d.name() == @riscv.decoder_name).length(),
    1,
  )
  guard @mc.find_decoder(ctx32) is Some(found) else { fail("not registered") }
  assert_eq(found.name(), "riscv")
}
