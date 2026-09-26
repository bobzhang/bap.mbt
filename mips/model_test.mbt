///|
test "model: general purpose registers" {
  let m32 : @mips.Arch = Mips32
  let m64 : @mips.Arch = Mips64
  debug_inspect(
    m32.find_gpr("SP"),
    content=(
      #|Some({ name: "SP", typ: Imm(32), is_virtual: false })
    ),
  )
  assert_eq(m32.find_gpr("R29"), m32.find_gpr("SP"))
  assert_eq(m32.find_gpr("SP_64"), None)
  debug_inspect(
    m64.find_gpr("SP_64"),
    content=(
      #|Some({ name: "SP", typ: Imm(64), is_virtual: false })
    ),
  )
  assert_eq(m64.find_gpr("R31"), m64.gpr(31))
  assert_eq(m64.gpr(32), None)
  inspect(
    m32.gprs().map(v => v.name).join(" "),
    content=(
      #|ZERO AT V0 V1 A0 A1 A2 A3 T0 T1 T2 T3 T4 T5 T6 T7 S0 S1 S2 S3 S4 S5 S6 S7 T8 T9 K0 K1 GP SP FP RA
    ),
  )
  assert_eq(m32.gpr_bitwidth(), 32)
  assert_eq(m64.gpr_bitwidth(), 64)
  assert_eq(m64.addr_bitwidth(), 64)
}

///|
test "model: special registers and predicates" {
  let m32 : @mips.Arch = Mips32
  let m64 : @mips.Arch = Mips64
  debug_inspect(
    m64.fpr(31),
    content=(
      #|Some({ name: "F31", typ: Imm(64), is_virtual: false })
    ),
  )
  assert_eq(m32.fpr(32), None)
  assert_eq(m32.find_fpr("F7"), m32.fpr(7))
  assert_eq(m32.find_fpr("F32"), None)
  assert_eq(m32.fpr_bitwidth(), 64)
  debug_inspect(
    (m32.hi(), m64.lo()),
    content=(
      #|(
      #|  { name: "HI", typ: Imm(32), is_virtual: false },
      #|  { name: "LO", typ: Imm(64), is_virtual: false },
      #|)
    ),
  )
  debug_inspect(
    m64.mem(),
    content=(
      #|{
      #|  name: "mem",
      #|  typ: Mem(addr_width=64, value_width=8),
      #|  is_virtual: false,
      #|}
    ),
  )
  assert_true(m32.is_sp(m32.sp()))
  assert_true(m32.is_bp(m32.fp()))
  assert_true(m32.is_mem(m32.mem()))
  assert_true(m32.is_reg(m32.sp()))
  assert_false(m32.is_reg(m32.hi()))
  assert_false(m32.is_reg(m64.sp()))
  assert_false(m32.is_flag(m32.sp()))
}

///|
test "model: GNU C calling convention" {
  let o32 = @mips.Arch::Mips32.gnu_calling_convention()
  let n64 = @mips.Arch::Mips64.gnu_calling_convention()
  inspect(
    o32.int_args.map(v => v.name).join(" ") +
    " | " +
    o32.float_args.map(v => v.name).join(" "),
    content=(
      #|A0 A1 A2 A3 | F1 F2 F3 F4
    ),
  )
  inspect(
    n64.int_args.map(v => v.name).join(" ") +
    " | " +
    n64.float_args.map(v => v.name).join(" "),
    content=(
      #|A0 A1 A2 A3 T0 T1 T2 T3 | F1 F2 F3 F4 F5 F6 F7 F8
    ),
  )
  debug_inspect(
    (
      o32.data_model,
      o32.float_args_shadow_int_args,
      n64.data_model,
      n64.float_args_shadow_int_args,
    ),
    content=(
      #|(ILP32, true, ILP64, false)
    ),
  )
  debug_inspect(
    (o32.float_bits, o32.double_bits, o32.long_double_bits),
    content=(
      #|(32, 64, 64)
    ),
  )
}
