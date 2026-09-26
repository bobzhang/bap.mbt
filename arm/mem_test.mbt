///|
/// Memory holding the words 0x11223344, 0x55667788, 0x99AABBCC, 0xDDEEFF00
/// at 0x1000..0x100F.
let words : Bytes = b"\x44\x33\x22\x11\x88\x77\x66\x55\xcc\xbb\xaa\x99\x00\xff\xee\xdd"

///|
test "word loads and stores with immediate offsets" {
  inspect(
    lift_str("LDRi12", [r("R0"), r("R1"), i(4), ..al]),
    content=(
      #|R0:imm32 := load(mem:mem32x8, (R1:imm32 + 4:32u)):imm32
    ),
  )
  inspect(
    lift_str("STRi12", [r("R0"), r("R1"), i(-8), ..al]),
    content=(
      #|mem:mem32x8 := store(mem:mem32x8, (R1:imm32 + 0xFFFFFFF8:32u), R0:imm32)
    ),
  )
  inspect(
    lift_str("LDRBi12", [r("R0"), r("R1"), i(0), ..al]),
    content=(
      #|%v2:imm8 := load(mem:mem32x8, (R1:imm32 + 0:32u)):imm8
      #|R0:imm32 := pad:32[%v2:imm8]
    ),
  )
  inspect(
    lift_str("STRBi12", [r("R0"), r("R1"), i(1), ..al]),
    content=(
      #|%v2:imm8 := low:8[R0:imm32]
      #|mem:mem32x8 := store(mem:mem32x8, (R1:imm32 + 1:32u), %v2:imm8)
    ),
  )
  // #-0 is encoded as INT32_MIN
  inspect(
    lift_str("LDRi12", [r("R0"), r("R1"), i(-0x80000000), ..al]),
    content=(
      #|R0:imm32 := load(mem:mem32x8, (R1:imm32 + 0:32u)):imm32
    ),
  )
  let init = state([("R0", 0xCAFEBABE), ("R1", 0x1004)], bytes=words)
  let s = run("LDRi12", [r("R0"), r("R1"), i(4), ..al], init)
  assert_eq(reg_value(s, "R0"), 0x99AABBCC)
  let s = run("LDRBi12", [r("R0"), r("R1"), i(-1), ..al], init)
  assert_eq(reg_value(s, "R0"), 0x11)
  let s = run("STRi12", [r("R0"), r("R1"), i(-4), ..al], init)
  assert_eq(mem_word(s, 0x1000), 0xCAFEBABE)
  assert_eq(reg_value(s, "R1"), 0x1004)
  let s = run("STRBi12", [r("R0"), r("R1"), i(0), ..al], init)
  assert_eq(mem_word(s, 0x1004), 0x556677BE)
}

///|
test "register offsets with shifts" {
  // ldr r0, [r1, r2, lsl #2]
  let lsl2 = (2 << 13) | 2
  inspect(
    lift_str("LDRrs", [r("R0"), r("R1"), r("R2"), i(lsl2), ..al]),
    content=(
      #|R0:imm32 := load(mem:mem32x8, (R1:imm32 + (R2:imm32 << 2:32u))):imm32
    ),
  )
  // ldr r0, [r1, -r2, lsr #1]
  let neg_lsr1 = (3 << 13) | 0x1000 | 1
  inspect(
    lift_str("LDRrs", [r("R0"), r("R1"), r("R2"), i(neg_lsr1), ..al]),
    content=(
      #|R0:imm32 := load(mem:mem32x8, (R1:imm32 + (0xFFFFFFFF:32u * (R2:imm32 >> 1:32u)))):imm32
    ),
  )
  let init = state([("R0", 0xAB), ("R1", 0x1000), ("R2", 2)], bytes=words)
  let s = run("LDRrs", [r("R0"), r("R1"), r("R2"), i(lsl2), ..al], init)
  assert_eq(reg_value(s, "R0"), 0x99AABBCC)
  let s = run("LDRBrs", [r("R0"), r("R1"), r("R2"), i(lsl2), ..al], init)
  assert_eq(reg_value(s, "R0"), 0xCC)
  let init2 = state([("R0", 0xAB), ("R1", 0x100C), ("R2", 8)], bytes=words)
  let s = run("LDRrs", [r("R0"), r("R1"), r("R2"), i(neg_lsr1), ..al], init2)
  assert_eq(reg_value(s, "R0"), 0x99AABBCC)
  let s = run("STRrs", [r("R0"), r("R1"), r("R2"), i(lsl2), ..al], init)
  assert_eq(mem_word(s, 0x1008), 0xAB)
  let s = run("STRBrs", [r("R0"), r("R1"), r("R2"), i(lsl2), ..al], init)
  assert_eq(mem_word(s, 0x1008), 0x99AABBAB)
}

///|
test "pre-indexed accesses write back before the access" {
  inspect(
    lift_str("LDR_PRE_IMM", [r("R0"), r("R1"), r("R1"), i(4), ..al]),
    content=(
      #|R0:imm32 := load(mem:mem32x8, (R1:imm32 + 4:32u)):imm32
      #|R1:imm32 := (R1:imm32 + 4:32u)
    ),
  )
  inspect(
    lift_str("STR_PRE_IMM", [r("R1"), r("R0"), r("R1"), i(-4), ..al]),
    content=(
      #|mem:mem32x8 := store(mem:mem32x8, (R1:imm32 + 0xFFFFFFFC:32u), R0:imm32)
      #|R1:imm32 := (R1:imm32 + 0xFFFFFFFC:32u)
    ),
  )
  inspect(
    lift_str(
      "LDR_PRE_REG",
      [r("R0"), r("R1"), r("R1"), r("R2"), i(2 << 13), ..al],
    ),
    content=(
      #|R0:imm32 := load(mem:mem32x8, (R1:imm32 + (R2:imm32 << 0:32u))):imm32
      #|R1:imm32 := (R1:imm32 + (R2:imm32 << 0:32u))
    ),
  )
  let init = state([("R0", 0x77), ("R1", 0x1004), ("R2", 4)], bytes=words)
  let s = run("LDR_PRE_IMM", [r("R0"), r("R1"), r("R1"), i(4), ..al], init)
  assert_eq(reg_value(s, "R0"), 0x99AABBCC)
  assert_eq(reg_value(s, "R1"), 0x1008)
  let s = run("LDRB_PRE_IMM", [r("R0"), r("R1"), r("R1"), i(3), ..al], init)
  assert_eq(reg_value(s, "R0"), 0x55)
  assert_eq(reg_value(s, "R1"), 0x1007)
  let s = run("STR_PRE_IMM", [r("R1"), r("R0"), r("R1"), i(-4), ..al], init)
  assert_eq(mem_word(s, 0x1000), 0x77)
  assert_eq(reg_value(s, "R1"), 0x1000)
  let s = run("STRB_PRE_IMM", [r("R1"), r("R0"), r("R1"), i(1), ..al], init)
  assert_eq(mem_word(s, 0x1004), 0x55667788)
  assert_eq(mem_word(s, 0x1008), 0x99AABBCC)
  assert_eq(reg_value(s, "R1"), 0x1005)
  let reg_ops = [r("R0"), r("R1"), r("R1"), r("R2"), i(2 << 13), ..al]
  let s = run("LDR_PRE_REG", reg_ops, init)
  assert_eq(reg_value(s, "R0"), 0x99AABBCC)
  assert_eq(reg_value(s, "R1"), 0x1008)
  let s = run("LDRB_PRE_REG", reg_ops, init)
  assert_eq(reg_value(s, "R0"), 0xCC)
  let st_ops = [r("R1"), r("R0"), r("R1"), r("R2"), i(2 << 13), ..al]
  let s = run("STR_PRE_REG", st_ops, init)
  assert_eq(mem_word(s, 0x1008), 0x77)
  assert_eq(reg_value(s, "R1"), 0x1008)
  let s = run("STRB_PRE_REG", st_ops, init)
  assert_eq(mem_word(s, 0x1008), 0x99AABB77)
}

///|
test "post-indexed accesses write back after the access" {
  // ldr r0, [r1], #-4 (AM2 immediate: bit 12 means subtract)
  let minus4 = 0x1000 | 4
  inspect(
    lift_str(
      "LDR_POST_IMM",
      [r("R0"), r("R1"), r("R1"), r("Nil"), i(minus4), ..al],
    ),
    content=(
      #|R0:imm32 := load(mem:mem32x8, R1:imm32):imm32
      #|R1:imm32 := (R1:imm32 + 0xFFFFFFFC:32u)
    ),
  )
  inspect(
    lift_str(
      "STR_POST_REG",
      [r("R1"), r("R0"), r("R1"), r("R2"), i(2 << 13), ..al],
    ),
    content=(
      #|mem:mem32x8 := store(mem:mem32x8, R1:imm32, R0:imm32)
      #|R1:imm32 := (R1:imm32 + (R2:imm32 << 0:32u))
    ),
  )
  let init = state([("R0", 0x77), ("R1", 0x1004), ("R2", 8)], bytes=words)
  let imm_ld = (name : String, imm : Int) => {
    let ops = [r("R0"), r("R1"), r("R1"), r("Nil"), i(imm), ..al]
    let s = run(name, ops, init)
    (reg_value(s, "R0"), reg_value(s, "R1"))
  }
  debug_inspect(imm_ld("LDR_POST_IMM", minus4), content="(1432778632, 4096)")
  debug_inspect(imm_ld("LDRB_POST_IMM", 1), content="(136, 4101)")
  debug_inspect(imm_ld("LDRBT_POST_IMM", 1), content="(136, 4101)")
  let imm_st = (name : String, imm : Int) => {
    let ops = [r("R1"), r("R0"), r("R1"), r("Nil"), i(imm), ..al]
    let s = run(name, ops, init)
    (mem_word(s, 0x1004), reg_value(s, "R1"))
  }
  debug_inspect(imm_st("STR_POST_IMM", 4), content="(119, 4104)")
  debug_inspect(imm_st("STRB_POST_IMM", minus4), content="(1432778615, 4096)")
  debug_inspect(imm_st("STRBT_POST_IMM", 4), content="(1432778615, 4104)")
  let reg_ld = (name : String) => {
    let ops = [r("R0"), r("R1"), r("R1"), r("R2"), i(2 << 13), ..al]
    let s = run(name, ops, init)
    (reg_value(s, "R0"), reg_value(s, "R1"))
  }
  debug_inspect(reg_ld("LDR_POST_REG"), content="(1432778632, 4108)")
  debug_inspect(reg_ld("LDRT_POST_REG"), content="(1432778632, 4108)")
  debug_inspect(reg_ld("LDRB_POST_REG"), content="(136, 4108)")
  debug_inspect(reg_ld("LDRBT_POST_REG"), content="(136, 4108)")
  let reg_st = (name : String) => {
    let ops = [r("R1"), r("R0"), r("R1"), r("R2"), i(2 << 13), ..al]
    let s = run(name, ops, init)
    (mem_word(s, 0x1004), reg_value(s, "R1"))
  }
  debug_inspect(reg_st("STR_POST_REG"), content="(119, 4108)")
  debug_inspect(reg_st("STRT_POST_REG"), content="(119, 4108)")
  debug_inspect(reg_st("STRB_POST_REG"), content="(1432778615, 4108)")
  debug_inspect(reg_st("STRBT_POST_REG"), content="(1432778615, 4108)")
}

///|
test "loads into PC are jumps and write back first" {
  inspect(
    lift_str("LDR_POST_IMM", [r("PC"), r("SP"), r("SP"), r("Nil"), i(4), ..al]),
    content=(
      #|%v1:imm32 := SP:imm32
      #|SP:imm32 := (SP:imm32 + 4:32u)
      #|jmp load(mem:mem32x8, %v1:imm32):imm32
    ),
  )
  inspect(
    lift_str("LDR_PRE_IMM", [r("PC"), r("SP"), r("SP"), i(4), ..al]),
    content=(
      #|%v1:imm32 := SP:imm32
      #|SP:imm32 := (SP:imm32 + 4:32u)
      #|jmp load(mem:mem32x8, (%v1:imm32 + 4:32u)):imm32
    ),
  )
  inspect(
    lift_str("LDRi12", [r("PC"), r("SP"), i(4), ..cc(0)]),
    content=(
      #|if (ZF:imm1 == 1:1u) {
      #|  jmp load(mem:mem32x8, (SP:imm32 + 4:32u)):imm32
      #|}
    ),
  )
  let init = state([("SP", 0x1004)], bytes=words)
  let stmts = lift_insn(
    "LDR_POST_IMM",
    [r("PC"), r("SP"), r("SP"), r("Nil"), i(4), ..al],
  )
  assert_eq(jump_target(stmts, init), Some(0x55667788))
  assert_eq(reg_value(exec(stmts, init), "SP"), 0x1008)
}

///|
test "halfword, signed and dual accesses (addressing mode 3)" {
  // ldrh r0, [r1, #-2]: bit 8 of the immediate means subtract
  inspect(
    lift_str("LDRH", [r("R0"), r("R1"), r("Nil"), i(0x102), ..al]),
    content=(
      #|%v2:imm16 := load(mem:mem32x8, (R1:imm32 + 0xFFFFFFFE:32u)):imm16
      #|R0:imm32 := pad:32[%v2:imm16]
    ),
  )
  inspect(
    lift_str("STRH", [r("R0"), r("R1"), r("R2"), i(0), ..al]),
    content=(
      #|%v2:imm16 := low:16[R0:imm32]
      #|mem:mem32x8 := store(mem:mem32x8, (R1:imm32 + R2:imm32), %v2:imm16)
    ),
  )
  inspect(
    lift_str("LDRSB", [r("R0"), r("R1"), r("R2"), i(0x100), ..al]),
    content=(
      #|%v2:imm8 := load(mem:mem32x8, (R1:imm32 + (0xFFFFFFFF:32u * R2:imm32))):imm8
      #|R0:imm32 := extend:32[%v2:imm8]
    ),
  )
  inspect(
    lift_str("LDRD", [r("R2"), r("R3"), r("R1"), r("Nil"), i(8), ..al]),
    content=(
      #|R2:imm32 := load(mem:mem32x8, (R1:imm32 + 8:32u)):imm32
      #|R3:imm32 := load(mem:mem32x8, ((R1:imm32 + 8:32u) + 4:32u)):imm32
    ),
  )
  inspect(
    lift_str(
      "STRD_PRE",
      [r("R1"), r("R2"), r("R3"), r("R1"), r("Nil"), i(0x108), ..al],
    ),
    content=(
      #|mem:mem32x8 := store(mem:mem32x8, (R1:imm32 + 0xFFFFFFF8:32u), R2:imm32)
      #|mem:mem32x8 := store(mem:mem32x8, ((R1:imm32 + 0xFFFFFFF8:32u) + 4:32u), R3:imm32)
      #|R1:imm32 := (R1:imm32 + 0xFFFFFFF8:32u)
    ),
  )
  let init = state([("R0", 0), ("R1", 0x1004), ("R2", 2)], bytes=words)
  let ld = (name : String, ops : Array[@mc.Op]) => {
    reg_value(run(name, ops, init), "R0")
  }
  assert_eq(ld("LDRH", [r("R0"), r("R1"), r("Nil"), i(0x102), ..al]), 0x1122)
  assert_eq(ld("LDRH", [r("R0"), r("R1"), r("R2"), i(0), ..al]), 0x5566)
  assert_eq(ld("LDRSH", [r("R0"), r("R1"), r("Nil"), i(0), ..al]), 0x7788)
  assert_eq(ld("LDRSH", [r("R0"), r("R1"), r("Nil"), i(4), ..al]), 0xFFFFBBCC)
  assert_eq(ld("LDRSB", [r("R0"), r("R1"), r("Nil"), i(0), ..al]), 0xFFFFFF88)
  assert_eq(ld("LDRSB", [r("R0"), r("R1"), r("R2"), i(0x100), ..al]), 0x22)
  let s = run(
    "STRH",
    [r("R1"), r("R1"), r("Nil"), i(0), ..al],
    state([("R1", 0x1004)], bytes=words),
  )
  assert_eq(mem_word(s, 0x1004), 0x55661004)
  let dual = [r("R2"), r("R3"), r("R1"), r("Nil"), i(4), ..al]
  let s = run("LDRD", dual, init)
  assert_eq(reg_value(s, "R2"), 0x99AABBCC)
  assert_eq(reg_value(s, "R3"), 0xDDEEFF00)
  let s = run(
    "STRD",
    dual,
    state([("R1", 0x1000), ("R2", 1), ("R3", 2)], bytes=words),
  )
  assert_eq(mem_word(s, 0x1004), 1)
  assert_eq(mem_word(s, 0x1008), 2)
}

///|
test "indexed addressing mode 3 accesses" {
  let init = state([("R0", 0), ("R1", 0x1004), ("R2", 4)], bytes=words)
  let ld = (name : String, imm : Int) => {
    let s = run(name, [r("R0"), r("R1"), r("R1"), r("Nil"), i(imm), ..al], init)
    (reg_value(s, "R0"), reg_value(s, "R1"))
  }
  debug_inspect(ld("LDRH_PRE", 2), content="(21862, 4102)")
  debug_inspect(ld("LDRH_POST", 0x102), content="(30600, 4098)")
  debug_inspect(ld("LDRSH_PRE", 4), content="(4294949836, 4104)")
  debug_inspect(ld("LDRSH_POST", 4), content="(30600, 4104)")
  debug_inspect(ld("LDRSB_PRE", 0x101), content="(17, 4099)")
  debug_inspect(ld("LDRSB_POST", 1), content="(4294967176, 4101)")
  // unprivileged variants: the sign bit set means ADD
  debug_inspect(ld("LDRHTr", 0x102), content="(30600, 4102)")
  debug_inspect(ld("LDRSHTr", 0x002), content="(30600, 4098)")
  debug_inspect(ld("LDRSBTr", 0x101), content="(4294967176, 4101)")
  let s = run("LDRSHTi", [r("R0"), r("R1"), r("R1"), i(0x104), ..al], init)
  debug_inspect(
    (reg_value(s, "R0"), reg_value(s, "R1")),
    content="(30600, 4104)",
  )
  // register offset of an unprivileged access: bit 0 means ADD
  let s = run("LDRHTr", [r("R0"), r("R1"), r("R1"), r("R2"), i(0), ..al], init)
  assert_eq(reg_value(s, "R1"), 0x1000)
  let st = (name : String, imm : Int) => {
    let ops = [r("R1"), r("R1"), r("R1"), r("Nil"), i(imm), ..al]
    let s = run(name, ops, init)
    (mem_word(s, 0x1000), mem_word(s, 0x1004), reg_value(s, "R1"))
  }
  debug_inspect(st("STRH_PRE", 0x104), content="(287444996, 1432778632, 4096)")
  debug_inspect(st("STRH_POST", 4), content="(287454020, 1432752132, 4104)")
  debug_inspect(st("STRHTr", 0x104), content="(287454020, 1432752132, 4104)")
  let dual = (name : String, ops : Array[@mc.Op]) => {
    let s = run(name, ops, init)
    (reg_value(s, "R2"), reg_value(s, "R3"), reg_value(s, "R1"))
  }
  debug_inspect(
    dual("LDRD_PRE", [r("R2"), r("R3"), r("R1"), r("R1"), r("Nil"), i(4), ..al]),
    content="(2578103244, 3723427584, 4104)",
  )
  debug_inspect(
    dual(
      "LDRD_POST",
      [r("R2"), r("R3"), r("R1"), r("R1"), r("Nil"), i(0x104), ..al],
    ),
    content="(1432778632, 2578103244, 4096)",
  )
  let init = state([("R1", 0x1004), ("R2", 1), ("R3", 2)], bytes=words)
  let s = run(
    "STRD_POST",
    [r("R1"), r("R2"), r("R3"), r("R1"), r("Nil"), i(8), ..al],
    init,
  )
  debug_inspect(
    (mem_word(s, 0x1004), mem_word(s, 0x1008), reg_value(s, "R1")),
    content="(1, 2, 4108)",
  )
  let s = run(
    "STRD_PRE",
    [r("R1"), r("R2"), r("R3"), r("R1"), r("Nil"), i(0x104), ..al],
    init,
  )
  debug_inspect(
    (mem_word(s, 0x1000), mem_word(s, 0x1004), reg_value(s, "R1")),
    content="(1, 2, 4096)",
  )
}

///|
test "exclusive accesses" {
  inspect(
    lift_str("LDREX", [r("R0"), r("R1"), ..al]),
    content=(
      #|R0:imm32 := load(mem:mem32x8, (R1:imm32 + 0:32u)):imm32
    ),
  )
  inspect(
    lift_str("STREX", [r("R2"), r("R0"), r("R1"), ..al]),
    content=(
      #|mem:mem32x8 := store(mem:mem32x8, (R1:imm32 + 0:32u), R0:imm32)
      #|R2:imm32 := 0:32u
    ),
  )
  inspect(
    lift_str("LDREXB", [r("R0"), r("R1"), ..al]),
    content=(
      #|%v2:imm8 := load(mem:mem32x8, (R1:imm32 + 0:32u)):imm8
      #|R0:imm32 := pad:32[%v2:imm8]
    ),
  )
  inspect(
    lift_str("STREXH", [r("R2"), r("R0"), r("R1"), ..al]),
    content=(
      #|%v2:imm16 := low:16[R0:imm32]
      #|mem:mem32x8 := store(mem:mem32x8, (R1:imm32 + 0:32u), %v2:imm16)
      #|R2:imm32 := 0:32u
    ),
  )
  let init = state([("R0", 0xAABBCCDD), ("R1", 0x1004), ("R2", 7)], bytes=words)
  assert_eq(
    reg_value(run("LDREX", [r("R0"), r("R1"), ..al], init), "R0"),
    0x55667788,
  )
  assert_eq(
    reg_value(run("LDREXB", [r("R0"), r("R1"), ..al], init), "R0"),
    0x88,
  )
  assert_eq(
    reg_value(run("LDREXH", [r("R0"), r("R1"), ..al], init), "R0"),
    0x7788,
  )
  let s = run("STREX", [r("R2"), r("R0"), r("R1"), ..al], init)
  assert_eq(mem_word(s, 0x1004), 0xAABBCCDD)
  assert_eq(reg_value(s, "R2"), 0)
  let s = run("STREXB", [r("R2"), r("R0"), r("R1"), ..al], init)
  assert_eq(mem_word(s, 0x1004), 0x556677DD)
  let s = run("STREXH", [r("R2"), r("R0"), r("R1"), ..al], init)
  assert_eq(mem_word(s, 0x1004), 0x5566CCDD)
  // the two-register forms are lifted as word accesses of the first
  // register, as upstream does
  let s = run("LDREX", [r("R0"), r("R2"), r("R1"), ..al], init)
  assert_eq(reg_value(s, "R0"), 0x55667788)
  assert_eq(reg_value(s, "R2"), 7)
  let s = run("STREX", [r("R3"), r("R0"), r("R2"), r("R1"), ..al], init)
  assert_eq(mem_word(s, 0x1004), 0xAABBCCDD)
  assert_eq(mem_word(s, 0x1008), 0x99AABBCC)
  assert_eq(reg_value(s, "R3"), 0)
  // register-pair operands are not modeled
  inspect(
    lift_error("LDREXD", [r("R0_R1"), r("R2"), ..al]),
    content="BadOperands: unsupported operand: R0_R1",
  )
  inspect(
    lift_error("STREXD", [r("R4"), r("R0"), r("R2"), ..al]),
    content="Failure: STREXD:dual store requires a second source",
  )
}

///|
test "load and store multiple" {
  // ldmia r0!, {r1, r2, pc}
  inspect(
    lift_str("LDMIA_UPD", [r("R0"), r("R0"), ..al, r("R1"), r("R2"), r("PC")]),
    content=(
      #|%v1:imm32 := R0:imm32
      #|R1:imm32 := load(mem:mem32x8, (%v1:imm32 + 0:32u)):imm32
      #|R2:imm32 := load(mem:mem32x8, (%v1:imm32 + 4:32u)):imm32
      #|R0:imm32 := (R0:imm32 + 0xC:32u)
      #|jmp load(mem:mem32x8, (%v1:imm32 + 8:32u)):imm32
    ),
  )
  // stmdb sp!, {r4, lr}
  inspect(
    lift_str("STMDB_UPD", [r("SP"), r("SP"), ..al, r("R4"), r("LR")]),
    content=(
      #|%v1:imm32 := SP:imm32
      #|mem:mem32x8 := store(mem:mem32x8, (%v1:imm32 + 0xFFFFFFFC:32u), LR:imm32)
      #|mem:mem32x8 := store(mem:mem32x8, (%v1:imm32 + 0xFFFFFFF8:32u), R4:imm32)
      #|SP:imm32 := (SP:imm32 - 8:32u)
    ),
  )
  let init = state(
    [("R0", 0x1004), ("R1", 1), ("R2", 2), ("R3", 3)],
    bytes=words,
  )
  let ldm = (name : String, upd : Bool) => {
    let ops = if upd {
      [r("R0"), r("R0"), ..al, r("R1"), r("R2")]
    } else {
      [r("R0"), ..al, r("R1"), r("R2")]
    }
    let s = run(name, ops, init)
    (reg_value(s, "R1"), reg_value(s, "R2"), reg_value(s, "R0"))
  }
  debug_inspect(ldm("LDMIA", false), content="(1432778632, 2578103244, 4100)")
  debug_inspect(
    ldm("LDMIA_UPD", true),
    content="(1432778632, 2578103244, 4108)",
  )
  debug_inspect(ldm("LDMIB", false), content="(2578103244, 3723427584, 4100)")
  debug_inspect(
    ldm("LDMIB_UPD", true),
    content="(2578103244, 3723427584, 4108)",
  )
  debug_inspect(ldm("LDMDA", false), content="(287454020, 1432778632, 4100)")
  debug_inspect(ldm("LDMDA_UPD", true), content="(287454020, 1432778632, 4092)")
  let init_db = state(
    [("R0", 0x1008), ("R1", 1), ("R2", 2), ("R3", 3)],
    bytes=words,
  )
  let s = run("LDMDB", [r("R0"), ..al, r("R1"), r("R2")], init_db)
  assert_eq(reg_value(s, "R1"), 0x11223344)
  assert_eq(reg_value(s, "R2"), 0x55667788)
  let s = run("LDMDB_UPD", [r("R0"), r("R0"), ..al, r("R1"), r("R2")], init_db)
  assert_eq(reg_value(s, "R0"), 0x1000)
  let stm = (name : String, upd : Bool) => {
    let ops = if upd {
      [r("R0"), r("R0"), ..al, r("R1"), r("R2")]
    } else {
      [r("R0"), ..al, r("R1"), r("R2")]
    }
    let s = run(name, ops, init)
    [
      mem_word(s, 0x1000),
      mem_word(s, 0x1004),
      mem_word(s, 0x1008),
      mem_word(s, 0x100C),
      reg_value(s, "R0"),
    ]
  }
  debug_inspect(
    stm("STMIA", false),
    content=(
      #|[287454020, 1, 2, 3723427584, 4100]
    ),
  )
  debug_inspect(
    stm("STMIA_UPD", true),
    content="[287454020, 1, 2, 3723427584, 4108]",
  )
  debug_inspect(
    stm("STMIB", false),
    content="[287454020, 1432778632, 1, 2, 4100]",
  )
  debug_inspect(
    stm("STMIB_UPD", true),
    content="[287454020, 1432778632, 1, 2, 4108]",
  )
  debug_inspect(
    stm("STMDA", false),
    content="[1, 2, 2578103244, 3723427584, 4100]",
  )
  debug_inspect(
    stm("STMDA_UPD", true),
    content="[1, 2, 2578103244, 3723427584, 4092]",
  )
  debug_inspect(
    stm("STMDB", false),
    content=(
      #|[2, 1432778632, 2578103244, 3723427584, 4100]
    ),
  )
  debug_inspect(
    stm("STMDB_UPD", true),
    content=(
      #|[2, 1432778632, 2578103244, 3723427584, 4092]
    ),
  )
  // a pop into PC jumps to the loaded address after all other effects
  let pop = lift_insn("LDMIA_UPD", [r("SP"), r("SP"), ..al, r("R4"), r("PC")])
  let init = state([("SP", 0x1000)], bytes=words)
  assert_eq(jump_target(pop, init), Some(0x55667788))
  assert_true(pop[pop.length() - 1] is Jmp(_))
}
