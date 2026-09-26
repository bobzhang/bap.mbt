// Decoder tests: invalid encodings, byte orders, and the decoder
// registered with `@mc`.

///|
test "invalid encodings" {
  let words : Array[UInt] = [
    0x00000000, // primary opcode 0
    0x44000002, // sc (not supported)
    0x7c0004ac, // sync (not supported)
    0xfc210828, // fsub (floating point, not supported)
    0x7c642e14, // add with OE=1 (addo)
    0x7c6428d6, // mulhw with bit 21 set
    0x7c6429ae | 1, // stbx with Rc=1
    0x7c6405d4, // addme with rb != 0
    0x7c832bf9, // cmpb with Rc=1
    0x7c8302f5, // popcntw with Rc=1
    0x2c448000, // cmpwi with bit 9 set
    0x7c442800, // cmpw with bit 9 set
    0x4d828020, // bclr with bits 16-18 set
    0x4c800001, // mcrf with LK=1
    0x7c781120, // mtcrf with bit 11 set (mtocrf)
    0x7c700026, // mfcr with bit 11 set (mfocrf)
    0xe8610003, // DS form extended opcode 3
    0xf8610002, // std extended opcode 2 (stq)
    0x78830010, // MD form extended opcode 4 with bit 30 clear is rldcl...
    0x7883001c, // ...extended opcode 7 is invalid
  ]
  inspect(
    listing(R64, words),
    content=(
      #|00000000  invalid
      #|44000002  invalid
      #|7c0004ac  invalid
      #|fc210828  invalid
      #|7c642e14  invalid
      #|7c6428d6  invalid
      #|7c6429af  invalid
      #|7c6405d4  invalid
      #|7c832bf9  invalid
      #|7c8302f5  invalid
      #|2c448000  invalid
      #|7c442800  invalid
      #|4d828020  invalid
      #|4c800001  invalid
      #|7c781120  invalid
      #|7c700026  invalid
      #|e8610003  invalid
      #|f8610002  invalid
      #|78830010  RLDCL X3, X4, R0, 0  | rotld 3, 4, 0
      #|7883001c  invalid
    ),
  )
}

///|
test "CTR decrementing and hinted branches" {
  let words : Array[UInt] = [
    0x4320fff8, // bdnz- .-8 (BO = 25: bdnz+)
     0x4300fff8, // BO = 24: bdnz-
     0x4360fff8, // BO = 27: bdz+
     0x4340fff8, // BO = 26: bdz-
     0x4200fff9, // bdnzl
     0x4200fffa, // bdnza
     0x4240fffb, // bdzla
     0x4201fff8, // BO = 16 with BI = 1 is a generic bc
     0x4e400020, // bdzlr
     0x4e000021, // bdnzlrl
     0x4f200020, // bdnzlr+
     0x4e800820, // blr with BH = 1 is a generic bclr
  ]
  inspect(
    listing(R32, words),
    content=(
      #|4320fff8  BDNZp -2  | bdnz+ .-8  | cond,term,flow
      #|4300fff8  BDNZm -2  | bdnz- .-8  | cond,term,flow
      #|4360fff8  BDZp -2  | bdz+ .-8  | cond,term,flow
      #|4340fff8  BDZm -2  | bdz- .-8  | cond,term,flow
      #|4200fff9  BDNZL -2  | bdnzl .-8  | call,flow
      #|4200fffa  BDNZA -2  | bdnza 0xfffffff8  | cond,term,flow
      #|4240fffb  BDZLA -2  | bdzla 0xfffffff8  | call,flow
      #|4201fff8  gBC 16, CR0GT, -2  | bc 16, 1, .-8  | cond,flow
      #|4e400020  BDZLR  | bdzlr  | cond,return,term,flow
      #|4e000021  BDNZLRL  | bdnzlrl  | call,flow
      #|4f200020  BDNZLRp  | bdnzlr+  | cond,return,term,flow
      #|4e800820  gBCLR 20, CR0LT, 1  | bclr 20, 0, 1  | cond,flow
    ),
  )
}

///|
test "byte orders and truncated input" {
  // addi r1, r1, 16 in both byte orders
  let be : Bytes = b"\x38\x21\x00\x10"
  let le : Bytes = b"\x10\x00\x21\x38"
  guard @powerpc.decode(be, 0x100, mode=R64) is Some(insn) else {
    fail("big endian")
  }
  assert_eq(show_insn(insn.name(), insn.ops()[:]), "ADDI R1, R1, 16")
  assert_eq(insn.raw(), be)
  assert_eq(insn.encoding(), @core_theory.Language::llvm_powerpc64())
  guard @powerpc.decode(le, 0x100, mode=R64, endian=LittleEndian) is Some(insn) else {
    fail("little endian")
  }
  assert_eq(show_insn(insn.name(), insn.ops()[:]), "ADDI R1, R1, 16")
  assert_eq(insn.raw(), le)
  // only the first word is decoded
  guard @powerpc.decode(b"\x38\x21\x00\x10\xff", 0) is Some(insn) else {
    fail("longer input")
  }
  assert_eq(insn.size(), 4)
  assert_eq(insn.encoding(), @core_theory.Language::llvm_powerpc32())
  assert_true(@powerpc.decode(b"\x38\x21\x00", 0) is None)
}

///|
test "the decoder registered with @mc" {
  @powerpc.register_decoder()
  @powerpc.register_decoder()
  let registered = @mc.decoders().filter(d => d.name() == @powerpc.decoder_name)
  assert_eq(registered.length(), 1)
  let ppc = @mc.Context::create(@core_theory.Target::powerpc())
  let ppc64le = @mc.Context::create(@core_theory.Target::powerpc64le())
  let mips = @mc.Context::create(@core_theory.Target::mips())
  guard @mc.find_decoder(ppc) is Some(decoder) else { fail("no decoder") }
  assert_eq(decoder.name(), @powerpc.decoder_name)
  assert_true(decoder.accepts(ppc64le))
  assert_false(decoder.accepts(mips))
  // `bl .+8` then garbage then a truncated word
  let bytes : Bytes = b"\x48\x00\x00\x09\x00\x00\x00\x00\x4e\x80"
  guard decoder.decode(ppc, bytes[:], 0x1000) is Decoded(insn) else {
    fail("bl")
  }
  assert_eq(show_insn(insn.name(), insn.ops()[:]), "BL 2")
  assert_eq(insn.encoding(), @core_theory.Language::llvm_powerpc32())
  assert_true(insn.has_kind(Call))
  assert_eq(decoder.decode(ppc, bytes[4:], 0x1004), Invalid(size=4))
  assert_eq(decoder.decode(ppc, bytes[8:], 0x1008), Truncated)
  // ppc64le: `blr` in little endian
  guard decoder.decode(ppc64le, b"\x20\x00\x80\x4e"[:], 0) is Decoded(insn) else {
    fail("blr")
  }
  assert_eq(insn.name(), "BLR")
  assert_eq(insn.encoding(), @core_theory.Language::llvm_powerpc64())
  // the decoded instructions are lifted in the same context
  let lifted = @mc.Registry::global().lift(ppc, insn) catch {
    Unsupported(..) => {
      @powerpc.register()
      @mc.Registry::global().lift(ppc, insn)
    }
    err => raise err
  }
  inspect(
    lifted.bil().map(s => s.to_string()).join("\n"),
    content=(
      #|jmp (LR:imm32 & (0xFFFFFFFF:32u << pad:32[2:8u]))
    ),
  )
}
