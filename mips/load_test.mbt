///|
test "load: mips32 big-endian semantics" {
  inspect(
    show("mips", [
      ("LB", [r("T0"), r("SP"), i(4)]),
      ("LBE", [r("T0"), r("SP"), i(4)]),
      ("LBu", [r("T0"), r("SP"), i(4)]),
      ("LBue", [r("T0"), r("SP"), i(4)]),
      ("LH", [r("T0"), r("SP"), i(-2)]),
      ("LHE", [r("T0"), r("SP"), i(-2)]),
      ("LHu", [r("T0"), r("SP"), i(-2)]),
      ("LHue", [r("T0"), r("SP"), i(-2)]),
      ("LL", [r("T0"), r("SP"), i(8)]),
      ("LLE", [r("T0"), r("SP"), i(8)]),
      ("LLX", [r("T0"), r("SP"), i(8)]),
      ("LLXE", [r("T0"), r("SP"), i(8)]),
      ("LW", [r("T0"), r("SP"), i(8)]),
      ("LWE", [r("T0"), r("SP"), i(8)]),
      ("LWu", [r("T0"), r("SP"), i(8)]),
      ("LWPC", [r("T0"), i(4)]),
      ("LWupc", [r("T0"), i(4)]),
    ]),
    content=(
      #|LB T0, SP, 0x4
      #|  T0 := extend:32[mem[(SP + 4:32u), be]:u8]
      #|LBE T0, SP, 0x4
      #|  T0 := pad:32[mem[(SP + 4:32u), be]:u8]
      #|LBu T0, SP, 0x4
      #|  T0 := pad:32[mem[(SP + 4:32u), be]:u8]
      #|LBue T0, SP, 0x4
      #|  T0 := pad:32[mem[(SP + 4:32u), be]:u8]
      #|LH T0, SP, 0x-2
      #|  T0 := extend:32[mem[(SP + 0xFFFFFFFE:32u), be]:u16]
      #|LHE T0, SP, 0x-2
      #|  T0 := extend:32[mem[(SP + 0xFFFFFFFE:32u), be]:u16]
      #|LHu T0, SP, 0x-2
      #|  T0 := pad:32[mem[(SP + 0xFFFFFFFE:32u), be]:u16]
      #|LHue T0, SP, 0x-2
      #|  T0 := pad:32[mem[(SP + 0xFFFFFFFE:32u), be]:u16]
      #|LL T0, SP, 0x8
      #|  T0 := mem[(SP + 8:32u), be]:u32
      #|LLE T0, SP, 0x8
      #|  T0 := mem[(SP + 8:32u), be]:u32
      #|LLX T0, SP, 0x8
      #|  T0 := mem[(SP + 8:32u), be]:u32
      #|LLXE T0, SP, 0x8
      #|  T0 := mem[(SP + 8:32u), be]:u32
      #|LW T0, SP, 0x8
      #|  T0 := mem[(SP + 8:32u), be]:u32
      #|LWE T0, SP, 0x8
      #|  T0 := mem[(SP + 8:32u), be]:u32
      #|LWu T0, SP, 0x8
      #|  T0 := mem[(SP + 8:32u), be]:u32
      #|LWPC T0, 0x4
      #|  T0 := mem[(0x1000:32u + 4:32u), be]:u32
      #|LWupc T0, 0x4
      #|  T0 := mem[(0x1000:32u + 4:32u), be]:u32
      #|
    ),
  )
}

///|
test "load: mips64 semantics" {
  inspect(
    show("mips64el", [
      ("LB", [r("T0_64"), r("SP_64"), i(4)]),
      ("LW", [r("T0_64"), r("SP_64"), i(8)]),
      ("LWu", [r("T0_64"), r("SP_64"), i(8)]),
      ("LD", [r("T0_64"), r("SP_64"), i(16)]),
      ("LLD", [r("T0_64"), r("SP_64"), i(16)]),
      ("LLDX", [r("T0_64"), r("SP_64"), i(16)]),
      ("LDPC", [r("T0_64"), i(2)]),
    ]),
    content=(
      #|LB T0_64, SP_64, 0x4
      #|  T0 := extend:64[mem[(SP + extend:64[4:32u]), el]:u8]
      #|LW T0_64, SP_64, 0x8
      #|  T0 := extend:64[mem[(SP + extend:64[8:32u]), el]:u32]
      #|LWu T0_64, SP_64, 0x8
      #|  T0 := pad:64[mem[(SP + extend:64[8:32u]), el]:u32]
      #|LD T0_64, SP_64, 0x10
      #|  T0 := mem[(SP + extend:64[0x10:32u]), el]:u64
      #|LLD T0_64, SP_64, 0x10
      #|  T0 := mem[(SP + extend:64[0x10:32u]), el]:u64
      #|LLDX T0_64, SP_64, 0x10
      #|  T0 := mem[(SP + extend:64[0x10:32u]), el]:u64
      #|LDPC T0_64, 0x2
      #|  T0 := mem[((0x1000:64u & 0xFFFFFFFFFFFFFFF8:64u) + extend:64[2:32u]), el]:u64
      #|
    ),
  )
}

///|
test "load: doubleword loads into 32-bit registers are narrowed" {
  // The destination width wins: the 64-bit load is sign-cast to 32 bits.
  inspect(
    render(
      @mips.lift(
        insn("LD", [r("T0"), r("SP"), i(0)]),
        arch=Mips32,
        endian=BigEndian,
      ),
    ),
    content=(
      #|T0 := extend:32[mem[(SP + 0:32u), be]:u64]
      #|
    ),
  )
}

///|
test "load: evaluation with memory" {
  let mem = @types.BilMemory::from_bytes(
    addr_width=32,
    start=0x100,
    b"\x80\x01\x02\x03",
  )
  let regs = [
    ("mem", @types.BilValue::BilMem(mem)),
    ("SP", word_value(32, 0x100)),
  ]
  let lb = run(@mips.lift_mips(insn("LB", [r("T0"), r("SP"), i(0)])), regs)
  assert_eq(reg_hex(lb, "T0"), "0xFFFFFF80:32u")
  let lbu = run(@mips.lift_mips(insn("LBu", [r("T0"), r("SP"), i(0)])), regs)
  assert_eq(reg_hex(lbu, "T0"), "0x80:32u")
  let lw_be = run(@mips.lift_mips(insn("LW", [r("T0"), r("SP"), i(0)])), regs)
  assert_eq(reg_hex(lw_be, "T0"), "0x80010203:32u")
  let lw_le = run(@mips.lift_mipsel(insn("LW", [r("T0"), r("SP"), i(0)])), regs)
  assert_eq(reg_hex(lw_le, "T0"), "0x3020180:32u")
  let lh = run(@mips.lift_mips(insn("LHu", [r("T0"), r("SP"), i(2)])), regs)
  assert_eq(reg_hex(lh, "T0"), "0x203:32u")
}
