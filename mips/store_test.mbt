///|
test "store: mips32 semantics" {
  inspect(
    show("mipsel", [
      ("SB", [r("T0"), r("SP"), i(4)]),
      ("SBE", [r("T0"), r("SP"), i(4)]),
      ("SH", [r("T0"), r("SP"), i(-2)]),
      ("SHE", [r("T0"), r("SP"), i(-2)]),
      ("SW", [r("T0"), r("SP"), i(8)]),
      ("SWE", [r("T0"), r("SP"), i(8)]),
      ("SC", [r("T0"), r("SP"), i(8)]),
      ("SCE", [r("T0"), r("SP"), i(8)]),
      ("SCX", [r("T0"), r("SP"), i(8)]),
      ("SCXE", [r("T0"), r("SP"), i(8)]),
    ]),
    content=(
      #|SB T0, SP, 0x4
      #|  mem := mem with [(SP + 4:32u), el]:u8 <- extract:7:0[T0]
      #|SBE T0, SP, 0x4
      #|  mem := mem with [(SP + 4:32u), el]:u8 <- extract:7:0[T0]
      #|SH T0, SP, 0x-2
      #|  mem := mem with [(SP + 0xFFFFFFFE:32u), el]:u16 <- extract:15:0[T0]
      #|SHE T0, SP, 0x-2
      #|  mem := mem with [(SP + 0xFFFFFFFE:32u), el]:u16 <- extract:15:0[T0]
      #|SW T0, SP, 0x8
      #|  mem := mem with [(SP + 8:32u), el]:u32 <- T0
      #|SWE T0, SP, 0x8
      #|  mem := mem with [(SP + 8:32u), el]:u32 <- T0
      #|SC T0, SP, 0x8
      #|  mem := mem with [(SP + 8:32u), el]:u32 <- T0
      #|SCE T0, SP, 0x8
      #|  mem := mem with [(SP + 8:32u), el]:u32 <- T0
      #|SCX T0, SP, 0x8
      #|  mem := mem with [(SP + 8:32u), el]:u32 <- T0
      #|SCXE T0, SP, 0x8
      #|  mem := mem with [(SP + 8:32u), el]:u32 <- T0
      #|
    ),
  )
}

///|
test "store: mips64 semantics" {
  inspect(
    show("mips64", [
      ("SB", [r("T0_64"), r("SP_64"), i(4)]),
      ("SW", [r("T0_64"), r("SP_64"), i(8)]),
      ("SD", [r("T0_64"), r("SP_64"), i(16)]),
      ("SCD", [r("T0_64"), r("SP_64"), i(16)]),
      ("SCDX", [r("T0_64"), r("SP_64"), i(16)]),
    ]),
    content=(
      #|SB T0_64, SP_64, 0x4
      #|  mem := mem with [(SP + extend:64[4:32u]), be]:u8 <- extract:7:0[T0]
      #|SW T0_64, SP_64, 0x8
      #|  mem := mem with [(SP + extend:64[8:32u]), be]:u32 <- extract:31:0[T0]
      #|SD T0_64, SP_64, 0x10
      #|  mem := mem with [(SP + extend:64[0x10:32u]), be]:u64 <- T0
      #|SCD T0_64, SP_64, 0x10
      #|  mem := mem with [(SP + extend:64[0x10:32u]), be]:u64 <- T0
      #|SCDX T0_64, SP_64, 0x10
      #|  mem := mem with [(SP + extend:64[0x10:32u]), be]:u64 <- T0
      #|
    ),
  )
}

///|
test "store: evaluation with memory" {
  let mem = @types.BilMemory::empty(addr_width=32)
  let regs = [
    ("mem", @types.BilValue::BilMem(mem)),
    ("SP", word_value(32, 0x100)),
    ("T0", word_value(32, 0x11223344)),
  ]
  let be = run(@mips.lift_mips(insn("SW", [r("T0"), r("SP"), i(4)])), regs)
  let cells = be.get_memory("mem").unwrap()
  debug_inspect(
    [
      for a in 0x104UL..<0x108UL => cells.cell(a).unwrap().to_int()
    ],
    content=(
      #|[17, 34, 51, 68]
    ),
  )
  let le = run(@mips.lift_mipsel(insn("SH", [r("T0"), r("SP"), i(0)])), regs)
  let cells = le.get_memory("mem").unwrap()
  debug_inspect(
    [
      for a in 0x100UL..<0x103UL => cells.cell(a).map(b => b.to_int())
    ],
    content=(
      #|[Some(68), Some(51), None]
    ),
  )
}
