// Tests of the native MIPS decoder: the LLVM-verified samples of
// `decode_llvm_test.mbt` in both byte orders, instruction kinds, invalid
// and truncated input, the `@mc` decoder, and decode -> lift -> execute.

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
fn be_bytes(word : UInt32) -> Bytes {
  [
    (word >> 24).to_byte(),
    (word >> 16).to_byte(),
    (word >> 8).to_byte(),
    word.to_byte(),
  ]
}

///|
fn le_bytes(word : UInt32) -> Bytes {
  [
    word.to_byte(),
    (word >> 8).to_byte(),
    (word >> 16).to_byte(),
    (word >> 24).to_byte(),
  ]
}

///|
test "decode: every sample decodes like llvm-mc, in both byte orders" {
  let names : Map[String, Unit] = Map([])
  for sample in llvm_samples {
    let (arch, r6, word, expected) = sample
    let be = be_bytes(word)
    guard @mips.decode(be, 0x1000UL, arch~, r6~) is Some(insn) else {
      fail("0x\{word.to_string(radix=16)}: not decoded, expected \{expected}")
    }
    assert_eq(render_insn(insn), expected)
    assert_eq(insn.size, 4)
    assert_eq(insn.addr, 0x1000UL)
    assert_eq(insn.raw, be)
    assert_eq(insn.encoding, @mips.encoding(arch, BigEndian))
    guard @mips.decode(
        le_bytes(word),
        0x1000UL,
        arch~,
        endian=LittleEndian,
        r6~,
      )
      is Some(insn_le) else {
      fail("0x\{word.to_string(radix=16)}: not decoded (little endian)")
    }
    assert_eq(render_insn(insn_le), expected)
    assert_eq(insn_le.encoding, @mips.encoding(arch, LittleEndian))
    names[insn.name] = ()
  }
  // the number of samples and of distinct LLVM opcodes they cover
  inspect(
    llvm_samples.length(),
    content=(
      #|371
    ),
  )
  inspect(
    names.length(),
    content=(
      #|361
    ),
  )
}

///|
/// Decode `word` (big endian) at `addr` and show its kinds.
fn kinds_of(
  word : UInt32,
  arch~ : @mips.Arch = Mips32,
  r6~ : Bool = false,
) -> String {
  match @mips.decode(be_bytes(word), 0x1000UL, arch~, r6~) {
    Some(insn) =>
      "\{insn.name}: [\{insn.kinds.iter().map(k => "\{Repr(k)}").collect().join(", ")}]"
    None => "invalid"
  }
}

///|
test "decode: instruction kinds follow the LLVM instruction descriptions" {
  let lines = [
    kinds_of(0x10400003), // beqz $2, 16
    kinds_of(0x08100010), // j
    kinds_of(0x03e00008), // jr $ra
    kinds_of(0x0c100010), // jal
    kinds_of(0x0320f809), // jalr $25
    kinds_of(0x04110001), // bal
    kinds_of(0x8fbf001c), // lw
    kinds_of(0xafbf001c), // sw
    kinds_of(0x27bdffe0), // addiu
    kinds_of(0x45000004), // bc1f
    kinds_of(0xc8000004, r6=true), // bc
    kinds_of(0xe8000004, r6=true), // balc
    kinds_of(0x20850004, r6=true), // beqc $4, $5
    kinds_of(0xd8040010, r6=true), // jic $4, 16
    kinds_of(0x42000018), // eret
  ]
  inspect(
    lines.join("\n"),
    content=(
      #|BEQ: [ConditionalBranch, Terminator, MayAffectControlFlow]
      #|J: [UnconditionalBranch, Barrier, Terminator, MayAffectControlFlow]
      #|JR: [IndirectBranch, Barrier, Terminator, MayAffectControlFlow]
      #|JAL: [Call, MayAffectControlFlow]
      #|JALR: [Call, MayAffectControlFlow]
      #|BGEZAL: [Call, MayAffectControlFlow]
      #|LW: [MayLoad]
      #|SW: [MayStore]
      #|ADDiu: []
      #|BC1F: [ConditionalBranch, Terminator, MayAffectControlFlow]
      #|BC: [UnconditionalBranch, Barrier, Terminator, MayAffectControlFlow]
      #|BALC: [Call, MayAffectControlFlow]
      #|BEQC: [ConditionalBranch, Terminator, MayAffectControlFlow]
      #|JIC: [IndirectBranch, Barrier, Terminator, MayAffectControlFlow]
      #|ERET: []
    ),
  )
}

///|
test "decode: invalid, truncated, and mode-dependent words" {
  // too short
  assert_true(@mips.decode(b"\x27\xbd\xff", 0UL) is None)
  // reserved: SPECIAL function 0x3d
  assert_true(@mips.decode(be_bytes(0x0000003d), 0UL) is None)
  // MIPS64 instructions are invalid on MIPS32 (daddiu, ld)
  assert_true(@mips.decode(be_bytes(0x67bdffe0), 0UL) is None)
  assert_true(@mips.decode(be_bytes(0xdfbf0018), 0UL) is None)
  assert_true(@mips.decode(be_bytes(0x67bdffe0), 0UL, arch=Mips64) is Some(_))
  // `jr` and `beql` are removed in Release 6
  assert_true(@mips.decode(be_bytes(0x03e00008), 0UL, r6=true) is None)
  assert_true(@mips.decode(be_bytes(0x50400003), 0UL, r6=true) is None)
  // the same word is `addi` in Release 2 and `beqc` in Release 6
  let word = be_bytes(0x20850004)
  guard @mips.decode(word, 0UL) is Some(r2) &&
    @mips.decode(word, 0UL, r6=true) is Some(r6) else {
    fail("not decoded")
  }
  inspect(r2.assembly, content="addi $5, $4, 4")
  inspect(r6.assembly, content="beqc $4, $5, 20")
}

///|
test "decode: the decoder of the @mc table" {
  let decoder = @mips.decoder()
  let ctx = @mc.Context::create(@core_theory.Target::mipsel())
  assert_true(decoder.accepts(ctx))
  assert_false(
    decoder.accepts(@mc.Context::create(@core_theory.Target::riscv64())),
  )
  debug_inspect(decoder.decode(ctx, b"\x00\x00", 0UL), content="Truncated")
  debug_inspect(
    decoder.decode(ctx, le_bytes(0x0000003d), 0UL),
    content="Invalid(size=4)",
  )
  // little-endian `addiu $sp, $sp, -32` on `mipsel`
  guard decoder.decode(ctx, le_bytes(0x27bdffe0), 0x400000UL) is Decoded(insn) else {
    fail("not decoded")
  }
  inspect(
    "\{insn.assembly} \{insn.encoding.to_string()}",
    content="addiu $sp, $sp, -32 llvm-mips32le",
  )
  // a MIPS64 context decodes the 64-bit instructions
  let ctx64 = @mc.Context::create(@core_theory.Target::mips64())
  guard decoder.decode(ctx64, be_bytes(0x67bdffe0), 0UL) is Decoded(insn64) else {
    fail("not decoded")
  }
  inspect(
    render_insn(insn64),
    content="DADDiu Reg:SP_64 Reg:SP_64 Imm:-32 | daddiu $sp, $sp, -32",
  )
  // registration is idempotent
  @mips.register_decoder()
  @mips.register_decoder()
  let registered = @mc.decoders().filter(d => d.name() == @mips.decoder_name)
  assert_eq(registered.length(), 1)
  guard @mc.find_decoder(ctx) is Some(found) else { fail("not registered") }
  assert_eq(found.name(), "mips")
}
