///|
test "MOVi decodes the modified immediate" {
  inspect(
    lift_str("MOVi", [r("R0"), i(0x12), ..al, r("Nil")]),
    content=(
      #|R0:imm32 := 0x12:32u
    ),
  )
  // rotation 4 (ror 8) of 0xFF, setting the flags
  inspect(
    lift_str("MOVi", [r("R0"), i(0x4FF), ..al, r("CPSR")]),
    content=(
      #|R0:imm32 := 0xFF000000:32u
      #|CF:imm1 := high:1[0x4FF:32u]
      #|NF:imm1 := high:1[R0:imm32]
      #|ZF:imm1 := (R0:imm32 == 0:32u)
    ),
  )
  assert_eq(@arm.decode_modified_imm(0x4FF), 0xFF000000)
  assert_eq(@arm.decode_modified_imm(0x1FF), 0xC000003F)
  assert_eq(@arm.decode_modified_imm(0x0AB), 0xAB)
  // the carry of an unrotated immediate is undefined, unless the raw
  // instruction says otherwise
  inspect(
    lift_str("MOVi", [r("R0"), i(0x12), ..al, r("CPSR")]),
    content=(
      #|R0:imm32 := 0x12:32u
      #|CF:imm1 := unknown(undefined:imm1)
      #|NF:imm1 := high:1[R0:imm32]
      #|ZF:imm1 := (R0:imm32 == 0:32u)
    ),
  )
  inspect(
    lift_str("MOVi", [r("R0"), i(0x12), ..al, r("CPSR")], raw=0xE3B00F12),
    content=(
      #|R0:imm32 := 0x12:32u
      #|CF:imm1 := 0:1u
      #|NF:imm1 := high:1[R0:imm32]
      #|ZF:imm1 := (R0:imm32 == 0:32u)
    ),
  )
}

///|
test "T32 immediates are not re-decoded" {
  inspect(
    lift_str("t2MOVi", [r("R0"), i(0x4FF), ..al, r("Nil")]),
    content=(
      #|R0:imm32 := 0x4FF:32u
    ),
  )
  let insn = @mc.Insn::create("MOVi", [r("R0"), i(0x4FF), ..al, r("Nil")])
  inspect(
    render(@arm.lift(insn, encoding=T32)),
    content=(
      #|R0:imm32 := 0x4FF:32u
    ),
  )
}

///|
test "register moves and shifted moves" {
  inspect(
    lift_str("MOVr", [r("R0"), r("R1"), ..al, r("CPSR")]),
    content=(
      #|R0:imm32 := R1:imm32
      #|CF:imm1 := CF:imm1
      #|NF:imm1 := high:1[R0:imm32]
      #|ZF:imm1 := (R0:imm32 == 0:32u)
    ),
  )
  // lsl #2
  inspect(
    lift_str("MOVsi", [r("R0"), r("R1"), i((2 << 3) | 2), ..al, r("Nil")]),
    content=(
      #|%v1:imm32 := R1:imm32
      #|R0:imm32 := (%v1:imm32 << 2:32u)
    ),
  )
  // asr by register
  inspect(
    lift_str("MOVsr", [r("R0"), r("R1"), r("R2"), i(1), ..al, r("CPSR")]),
    content=(
      #|%v1:imm32 := R1:imm32
      #|R0:imm32 := (%v1:imm32 a>> R2:imm32)
      #|CF:imm1 := low:1[(%v1:imm32 >> (R2:imm32 - 1:32u))]
      #|NF:imm1 := high:1[R0:imm32]
      #|ZF:imm1 := (R0:imm32 == 0:32u)
    ),
  )
  inspect(
    lift_str("MVNr", [r("R0"), r("R1"), ..al, r("Nil")]),
    content=(
      #|R0:imm32 := (not R1:imm32)
    ),
  )
  inspect(
    lift_str("MVNi", [r("R0"), i(0), ..al, r("Nil")]),
    content=(
      #|R0:imm32 := (not 0:32u)
    ),
  )
  inspect(
    lift_str("MVNsi", [r("R0"), r("R1"), i((4 << 3) | 3), ..al, r("Nil")]),
    content=(
      #|%v1:imm32 := R1:imm32
      #|R0:imm32 := (not (%v1:imm32 >> 4:32u))
    ),
  )
  inspect(
    lift_str("MVNsr", [r("R0"), r("R1"), r("R2"), i(4), ..al, r("Nil")]),
    content=(
      #|%v1:imm32 := R1:imm32
      #|R0:imm32 := (not ((%v1:imm32 >> R2:imm32) | (%v1:imm32 << (0x20:32u - R2:imm32))))
    ),
  )
  inspect(lift_str("MOVPCLR", al), content="jmp LR:imm32")
}

///|
test "shift semantics" {
  let init = state([("R1", 0x80000011), ("R2", 4)], flags=[("CF", true)])
  let shifted = (simm : Int) => {
    let s = run("MOVsi", [r("R0"), r("R1"), i(simm), ..al, r("CPSR")], init)
    (reg_value(s, "R0"), flag_value(s, "CF"))
  }
  debug_inspect(shifted((4 << 3) | 1), content="(4160749569, false)") // asr #4
  debug_inspect(shifted((4 << 3) | 2), content="(272, false)") // lsl #4
  debug_inspect(shifted((1 << 3) | 2), content="(34, true)") // lsl #1
  debug_inspect(shifted((4 << 3) | 3), content="(134217729, false)") // lsr #4
  debug_inspect(shifted((1 << 3) | 3), content="(1073741832, true)") // lsr #1
  debug_inspect(shifted((4 << 3) | 4), content="(402653185, false)") // ror #4
  debug_inspect(shifted(5), content="(3221225480, true)") // rrx
  // shift amount taken from a register
  let s = run("MOVsr", [r("R0"), r("R1"), r("R2"), i(3), ..al, r("Nil")], init)
  assert_eq(reg_value(s, "R0"), 0x08000001)
  let s = run(
    "ADDrsr",
    [r("R0"), r("R2"), r("R1"), r("R2"), i(2), ..al, r("Nil")],
    init,
  )
  assert_eq(reg_value(s, "R0"), 0x114)
}

///|
test "data processing forms" {
  inspect(
    lift_str("ADDri", [r("R0"), r("R1"), i(0x104), ..al, r("Nil")]),
    content=(
      #|%v2:imm32 := R1:imm32
      #|%v3:imm32 := 1:32u
      #|R0:imm32 := (R1:imm32 + 1:32u)
    ),
  )
  inspect(
    lift_str("ADDrr", [r("R0"), r("R1"), r("R2"), ..al, r("CPSR")]),
    content=(
      #|%v2:imm32 := R1:imm32
      #|%v3:imm32 := R2:imm32
      #|R0:imm32 := (R1:imm32 + R2:imm32)
      #|CF:imm1 := (R0:imm32 < %v2:imm32)
      #|VF:imm1 := high:1[((not (%v2:imm32 ^ %v3:imm32)) & (%v2:imm32 ^ R0:imm32))]
      #|NF:imm1 := high:1[R0:imm32]
      #|ZF:imm1 := (R0:imm32 == 0:32u)
    ),
  )
  inspect(
    lift_str(
      "SUBrsi",
      [r("R0"), r("R1"), r("R2"), i((3 << 3) | 3), ..al, r("Nil")],
    ),
    content=(
      #|%v1:imm32 := R2:imm32
      #|%v2:imm32 := R1:imm32
      #|%v3:imm32 := (%v1:imm32 >> 3:32u)
      #|R0:imm32 := (R1:imm32 - (%v1:imm32 >> 3:32u))
    ),
  )
  inspect(
    lift_str(
      "ANDrsr",
      [r("R0"), r("R1"), r("R2"), r("R3"), i(2), ..al, r("CPSR")],
    ),
    content=(
      #|%v1:imm32 := R2:imm32
      #|R0:imm32 := (R1:imm32 & (%v1:imm32 << R3:imm32))
      #|CF:imm1 := ite((R3:imm32 != 0:32u), low:1[(%v1:imm32 >> (0x20:32u - R3:imm32))], CF:imm1)
      #|NF:imm1 := high:1[R0:imm32]
      #|ZF:imm1 := (R0:imm32 == 0:32u)
    ),
  )
  inspect(
    lift_str("ORRri", [r("R0"), r("R1"), i(0xFF), ..al, r("CPSR")]),
    content=(
      #|R0:imm32 := (R1:imm32 | 0xFF:32u)
      #|CF:imm1 := unknown(undefined:imm1)
      #|NF:imm1 := high:1[R0:imm32]
      #|ZF:imm1 := (R0:imm32 == 0:32u)
    ),
  )
  inspect(
    lift_str("BICrr", [r("R0"), r("R1"), r("R2"), ..al, r("Nil")]),
    content=(
      #|R0:imm32 := (R1:imm32 & (not R2:imm32))
    ),
  )
  inspect(
    lift_str("EORrr", [r("R0"), r("R1"), r("R2"), ..al, r("Nil")]),
    content=(
      #|R0:imm32 := (R1:imm32 ^ R2:imm32)
    ),
  )
  inspect(
    lift_str("ADCrr", [r("R0"), r("R1"), r("R2"), ..al, r("CPSR")]),
    content=(
      #|%v2:imm32 := R1:imm32
      #|%v3:imm32 := R2:imm32
      #|R0:imm32 := ((R1:imm32 + R2:imm32) + pad:32[CF:imm1])
      #|CF:imm1 := high:1[((pad:33[%v2:imm32] + pad:33[%v3:imm32]) + pad:33[CF:imm1])]
      #|VF:imm1 := high:1[((not (%v2:imm32 ^ %v3:imm32)) & (%v2:imm32 ^ R0:imm32))]
      #|NF:imm1 := high:1[R0:imm32]
      #|ZF:imm1 := (R0:imm32 == 0:32u)
    ),
  )
  inspect(
    lift_str("SBCrr", [r("R0"), r("R1"), r("R2"), ..al, r("Nil")]),
    content=(
      #|%v2:imm32 := R1:imm32
      #|%v3:imm32 := R2:imm32
      #|R0:imm32 := ((R1:imm32 + (not R2:imm32)) + pad:32[CF:imm1])
    ),
  )
  inspect(
    lift_str("RSBri", [r("R0"), r("R1"), i(0), ..al, r("Nil")]),
    content=(
      #|%v2:imm32 := R1:imm32
      #|%v3:imm32 := 0:32u
      #|R0:imm32 := (0:32u - R1:imm32)
    ),
  )
  inspect(
    lift_str("RSCrr", [r("R0"), r("R1"), r("R2"), ..al, r("Nil")]),
    content=(
      #|%v2:imm32 := R1:imm32
      #|%v3:imm32 := R2:imm32
      #|R0:imm32 := (((not R1:imm32) + R2:imm32) + pad:32[CF:imm1])
    ),
  )
}

///|
test "arithmetic results and flags" {
  let arith = (name : String, a : UInt, b : UInt, carry : Bool) => {
    let init = state([("R1", a), ("R2", b)], flags=[("CF", carry)])
    let s = run(name, [r("R0"), r("R1"), r("R2"), ..al, r("CPSR")], init)
    "\{reg_value(s, "R0")} \{nzcv(s)}"
  }
  inspect(arith("ADDrr", 1, 2, false), content="3 ----")
  inspect(arith("ADDrr", 0xFFFFFFFF, 1, false), content="0 -ZC-")
  inspect(arith("ADDrr", 0x7FFFFFFF, 1, false), content="2147483648 N--V")
  inspect(arith("SUBrr", 5, 3, false), content="2 --C-")
  inspect(arith("SUBrr", 3, 5, false), content="4294967294 N---")
  inspect(arith("SUBrr", 0x80000000, 1, false), content="2147483647 --CV")
  inspect(arith("RSBrr", 3, 5, false), content="2 --C-")
  inspect(arith("ADCrr", 1, 2, true), content="4 ----")
  inspect(arith("ADCrr", 0xFFFFFFFF, 0, true), content="0 -ZC-")
  inspect(arith("SBCrr", 5, 3, true), content="2 --C-")
  inspect(arith("SBCrr", 5, 3, false), content="1 --C-")
  inspect(arith("RSCrr", 3, 5, true), content="2 --C-")
  inspect(arith("ANDrr", 0xF0F0, 0xFF00, false), content="61440 ----")
  inspect(arith("ORRrr", 0x80000000, 1, false), content="2147483649 N---")
  inspect(arith("EORrr", 7, 7, false), content="0 -Z--")
  inspect(arith("BICrr", 0xFF, 0x0F, false), content="240 ----")
}

///|
test "comparisons and tests set the flags only" {
  inspect(
    lift_str("CMPri", [r("R1"), i(0), ..al]),
    content=(
      #|%v3:imm32 := R1:imm32
      #|%v4:imm32 := 0:32u
      #|%v1:imm32 := (R1:imm32 - 0:32u)
      #|CF:imm1 := (%v4:imm32 <= %v3:imm32)
      #|VF:imm1 := high:1[((%v3:imm32 ^ %v4:imm32) & (%v3:imm32 ^ %v1:imm32))]
      #|NF:imm1 := high:1[%v1:imm32]
      #|ZF:imm1 := (%v1:imm32 == 0:32u)
    ),
  )
  inspect(
    lift_str("CMPrsi", [r("R1"), r("R2"), i((1 << 3) | 2), ..al]),
    content=(
      #|%v2:imm32 := R2:imm32
      #|%v3:imm32 := R1:imm32
      #|%v4:imm32 := (%v2:imm32 << 1:32u)
      #|%v1:imm32 := (R1:imm32 - (%v2:imm32 << 1:32u))
      #|CF:imm1 := (%v4:imm32 <= %v3:imm32)
      #|VF:imm1 := high:1[((%v3:imm32 ^ %v4:imm32) & (%v3:imm32 ^ %v1:imm32))]
      #|NF:imm1 := high:1[%v1:imm32]
      #|ZF:imm1 := (%v1:imm32 == 0:32u)
    ),
  )
  inspect(
    lift_str("TSTrr", [r("R1"), r("R2"), ..al]),
    content=(
      #|%v1:imm32 := (R1:imm32 & R2:imm32)
      #|CF:imm1 := CF:imm1
      #|NF:imm1 := high:1[%v1:imm32]
      #|ZF:imm1 := (%v1:imm32 == 0:32u)
    ),
  )
  inspect(
    lift_str("TEQrsi", [r("R0"), r("R1"), r("R2"), i((1 << 3) | 2), ..al]),
    content=(
      #|%v2:imm32 := R2:imm32
      #|%v1:imm32 := (R1:imm32 ^ (%v2:imm32 << 1:32u))
      #|CF:imm1 := ite((1:32u != 0:32u), low:1[(%v2:imm32 >> (0x20:32u - 1:32u))], CF:imm1)
      #|NF:imm1 := high:1[%v1:imm32]
      #|ZF:imm1 := (%v1:imm32 == 0:32u)
    ),
  )
  let cmp = (name : String, a : UInt, b : UInt) => {
    let init = state([("R1", a), ("R2", b)])
    nzcv(run(name, [r("R1"), r("R2"), ..al], init))
  }
  inspect(cmp("CMPrr", 5, 5), content="-ZC-")
  inspect(cmp("CMPrr", 4, 5), content="N---")
  inspect(cmp("CMNzrr", 0xFFFFFFFF, 1), content="-ZC-")
  inspect(cmp("TSTrr", 0xF0, 0x0F), content="-Z--")
  inspect(cmp("TEQrr", 0x80000000, 1), content="N---")
  let s = run(
    "CMPrsr",
    [r("R1"), r("R2"), r("R3"), i(2), ..al],
    state([("R1", 8), ("R2", 1), ("R3", 3)]),
  )
  inspect(nzcv(s), content="-ZC-")
  let s = run(
    "CMNzrsr",
    [r("R1"), r("R2"), r("R3"), i(2), ..al],
    state([("R1", 8), ("R2", 1), ("R3", 3)]),
  )
  inspect(nzcv(s), content="----")
  let s = run(
    "TSTrsr",
    [r("R1"), r("R2"), r("R3"), i(2), ..al],
    state([("R1", 8), ("R2", 1), ("R3", 3)]),
  )
  inspect(nzcv(s), content="----")
  let s = run(
    "TEQrsr",
    [r("R1"), r("R2"), r("R3"), i(2), ..al],
    state([("R1", 8), ("R2", 1), ("R3", 3)]),
  )
  inspect(nzcv(s), content="-Z--")
  let s = run(
    "TSTrsi",
    [r("R1"), r("R2"), i((3 << 3) | 2), ..al],
    state([("R1", 8), ("R2", 1)]),
  )
  inspect(nzcv(s), content="----")
  let s = run(
    "CMNzrsi",
    [r("R1"), r("R2"), i((3 << 3) | 2), ..al],
    state([("R1", 0xFFFFFFF8), ("R2", 1)]),
  )
  inspect(nzcv(s), content="-ZC-")
  // TEQ/TST with immediates
  inspect(
    lift_str("TEQri", [r("R1"), i(0x1FF), ..al]),
    content=(
      #|%v1:imm32 := (R1:imm32 ^ 0xC000003F:32u)
      #|CF:imm1 := high:1[0x1FF:32u]
      #|NF:imm1 := high:1[%v1:imm32]
      #|ZF:imm1 := (%v1:imm32 == 0:32u)
    ),
  )
}

///|
test "conditional execution" {
  // moves are predicated with ite
  inspect(
    lift_str("MOVr", [r("R0"), r("R1"), ..cc(0), r("Nil")]),
    content=(
      #|%v2:imm1 := (ZF:imm1 == 1:1u)
      #|R0:imm32 := ite(%v2:imm1, R1:imm32, R0:imm32)
    ),
  )
  inspect(
    lift_str("ADDri", [r("R0"), r("R0"), i(1), ..cc(1), r("CPSR")]),
    content=(
      #|%v4:imm1 := (ZF:imm1 == 0:1u)
      #|%v2:imm32 := R0:imm32
      #|%v3:imm32 := 1:32u
      #|R0:imm32 := ite(%v4:imm1, (R0:imm32 + 1:32u), R0:imm32)
      #|CF:imm1 := ite(%v4:imm1, (R0:imm32 < %v2:imm32), CF:imm1)
      #|VF:imm1 := ite(%v4:imm1, high:1[((not (%v2:imm32 ^ %v3:imm32)) & (%v2:imm32 ^ R0:imm32))], VF:imm1)
      #|NF:imm1 := ite(%v4:imm1, high:1[R0:imm32], NF:imm1)
      #|ZF:imm1 := ite(%v4:imm1, (R0:imm32 == 0:32u), ZF:imm1)
    ),
  )
  // a conditional assignment to PC becomes a conditional jump
  inspect(
    lift_str("MOVr", [r("PC"), r("LR"), ..cc(11), r("Nil")]),
    content=(
      #|if (NF:imm1 != VF:imm1) then 1 stmts else 0 stmts
    ),
  )
  let conds = [
    (0, [("ZF", true)], true),
    (0, [], false),
    (1, [], true),
    (2, [("CF", true)], true),
    (3, [("CF", true)], false),
    (4, [("NF", true)], true),
    (5, [("NF", true)], false),
    (6, [("VF", true)], true),
    (7, [("VF", true)], false),
    (8, [("CF", true)], true),
    (8, [("CF", true), ("ZF", true)], false),
    (9, [("ZF", true)], true),
    (10, [("NF", true), ("VF", true)], true),
    (11, [("NF", true)], true),
    (12, [("NF", true), ("VF", true)], true),
    (12, [("ZF", true)], false),
    (13, [("ZF", true)], true),
    (13, [], false),
  ]
  for c in conds {
    let init = state([("R0", 0), ("R1", 42)], flags=c.1)
    let s = run("MOVr", [r("R0"), r("R1"), ..cc(c.0), r("Nil")], init)
    assert_eq(reg_value(s, "R0") == 42, c.2, msg="cond \{c.0}")
  }
}

///|
test "wide moves" {
  inspect(
    lift_str("MOVi16", [r("R0"), i(0xBEEF), ..al]),
    content=(
      #|R0:imm32 := 0xBEEF:32u
    ),
  )
  inspect(
    lift_str("MOVTi16", [r("R0"), r("R0"), i(0xDEAD), ..al]),
    content=(
      #|R0:imm32 := ((R0:imm32 & 0xFFFF:32u) | (0xDEAD:32u << 0x10:32u))
    ),
  )
  let s = run(
    "MOVTi16",
    [r("R0"), r("R0"), i(0xDEAD), ..al],
    state([("R0", 0x1234BEEF)]),
  )
  assert_eq(reg_value(s, "R0"), 0xDEADBEEF)
}
