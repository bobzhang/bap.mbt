///|
test "extensions" {
  inspect(
    lift_str("UXTB", [r("R0"), r("R1"), i(0), ..al]),
    content=(
      #|R0:imm32 := pad:32[low:8[R1:imm32]]
    ),
  )
  inspect(
    lift_str("SXTH", [r("R0"), r("R1"), i(1), ..al]),
    content=(
      #|R0:imm32 := extend:32[low:16[((R1:imm32 >> 8:32u) | (R1:imm32 << 0x18:32u))]]
    ),
  )
  inspect(
    lift_str("UXTAB", [r("R0"), r("R1"), r("R2"), i(0), ..al]),
    content=(
      #|R0:imm32 := (R1:imm32 + pad:32[low:8[R2:imm32]])
    ),
  )
  let init = state([("R1", 0x100), ("R2", 0x8081F2F3)])
  let ext = (name : String, rot : Int32) => {
    let s = run(name, [r("R0"), r("R2"), i(rot), ..al], init)
    reg_value(s, "R0")
  }
  assert_eq(ext("UXTB", 0), 0xF3)
  assert_eq(ext("UXTB", 1), 0xF2)
  assert_eq(ext("UXTB", 3), 0x80)
  assert_eq(ext("SXTB", 0), 0xFFFFFFF3)
  assert_eq(ext("SXTB", 2), 0xFFFFFF81)
  assert_eq(ext("UXTH", 0), 0xF2F3)
  assert_eq(ext("UXTH", 2), 0x8081)
  assert_eq(ext("SXTH", 0), 0xFFFFF2F3)
  assert_eq(ext("SXTH", 1), 0xFFFF81F2)
  let ext_add = (name : String, rot : Int32) => {
    let s = run(name, [r("R0"), r("R1"), r("R2"), i(rot), ..al], init)
    reg_value(s, "R0")
  }
  assert_eq(ext_add("UXTAB", 0), 0x1F3)
  assert_eq(ext_add("UXTAH", 0), 0xF3F3)
  assert_eq(ext_add("SXTAB", 0), 0xF3)
  assert_eq(ext_add("SXTAH", 2), 0xFFFF8181)
}

///|
test "bit field extraction" {
  inspect(
    lift_str("UBFX", [r("R0"), r("R1"), i(4), i(7), ..al]),
    content=(
      #|R0:imm32 := pad:32[extract[11:4](R1:imm32)]
    ),
  )
  let init = state([("R1", 0x0000F5A0)])
  let s = run("UBFX", [r("R0"), r("R1"), i(4), i(7), ..al], init)
  assert_eq(reg_value(s, "R0"), 0x5A)
  let s = run("SBFX", [r("R0"), r("R1"), i(8), i(7), ..al], init)
  assert_eq(reg_value(s, "R0"), 0xFFFFFFF5)
}

///|
test "bit field insertion" {
  // bfi r0, r1, #8, #4: the inverted mask operand is ~0x00000F00
  let bfi = [r("R0"), r("R0"), r("R1"), i(0xFFFFF0FF), ..al]
  inspect(
    lift_str("BFI", bfi),
    content=(
      #|R0:imm32 := concat(concat(extract[31:12](R0:imm32), extract[3:0](R1:imm32)), extract[7:0](R0:imm32))
    ),
  )
  // the same field decoded from the instruction word (lsb=8, msb=11)
  inspect(
    lift_str("BFI", bfi, raw=0xE7CB0411),
    content=(
      #|R0:imm32 := concat(concat(extract[31:12](R0:imm32), extract[3:0](R1:imm32)), extract[7:0](R0:imm32))
    ),
  )
  let init = state([("R0", 0xFFFFFFFF), ("R1", 0x5)])
  assert_eq(reg_value(run("BFI", bfi, init), "R0"), 0xFFFFF5FF)
  // fields touching bit 0 and bit 31
  let low = [r("R0"), r("R0"), r("R1"), i(0xFFFFFFF0), ..al]
  assert_eq(reg_value(run("BFI", low, init), "R0"), 0xFFFFFFF5)
  let high = [r("R0"), r("R0"), r("R1"), i(0x0FFFFFFF), ..al]
  assert_eq(reg_value(run("BFI", high, init), "R0"), 0x5FFFFFFF)
  let full = [r("R0"), r("R0"), r("R1"), i(0), ..al]
  assert_eq(reg_value(run("BFI", full, init), "R0"), 0x5)
  // bfc r0, #4, #8
  let bfc = [r("R0"), r("R0"), i(0xFFFFF00F), ..al]
  inspect(
    lift_str("BFC", bfc),
    content=(
      #|R0:imm32 := concat(concat(extract[31:12](R0:imm32), extract[7:0](0:32u)), extract[3:0](R0:imm32))
    ),
  )
  assert_eq(reg_value(run("BFC", bfc, init), "R0"), 0xFFFFF00F)
}

///|
test "bit reversal" {
  inspect(
    lift_str("RBIT", [r("R0"), r("R1"), ..al]),
    content=(
      #|%v1:imm32 := (R1:imm32 >> 1:32u)
      #|%r2:imm32 := R1:imm32
      #|%s3:imm32 := 0x1F:32u
      #|while (%v1:imm32 != 0:32u) {
      #|  %r2:imm32 := (%r2:imm32 << 1:32u)
      #|  %r2:imm32 := (%r2:imm32 | (%v1:imm32 & 1:32u))
      #|  %v1:imm32 := (%v1:imm32 >> 1:32u)
      #|  %s3:imm32 := (%s3:imm32 - 1:32u)
      #|}
      #|R0:imm32 := (%r2:imm32 << %s3:imm32)
    ),
  )
  let rbit = (x : UInt32) => {
    let s = run("RBIT", [r("R0"), r("R1"), ..al], state([("R1", x)]))
    reg_value(s, "R0")
  }
  assert_eq(rbit(1), 0x80000000)
  assert_eq(rbit(0x80000000), 1)
  assert_eq(rbit(0x12345678), 0x1E6A2C48)
}

///|
test "byte reversals and packing" {
  inspect(
    lift_str("REV", [r("R0"), r("R1"), ..al]),
    content=(
      #|R0:imm32 := concat(concat(concat(extract[7:0](R1:imm32), extract[15:8](R1:imm32)), extract[23:16](R1:imm32)), extract[31:24](R1:imm32))
    ),
  )
  inspect(
    lift_str("REV16", [r("R0"), r("R1"), ..al]),
    content=(
      #|R0:imm32 := concat(concat(concat(extract[23:16](R1:imm32), extract[31:24](R1:imm32)), extract[7:0](R1:imm32)), extract[15:8](R1:imm32))
    ),
  )
  inspect(
    lift_str("PKHTB", [r("R0"), r("R1"), r("R2"), i(16), ..al]),
    content=(
      #|R0:imm32 := concat(extract[31:16](R1:imm32), extract[15:0]((R2:imm32 a>> 0x10:32u)))
    ),
  )
  let init = state([("R1", 0x11223344), ("R2", 0xAABBCCDD)])
  assert_eq(
    reg_value(run("REV", [r("R0"), r("R1"), ..al], init), "R0"),
    0x44332211,
  )
  assert_eq(
    reg_value(run("REV16", [r("R0"), r("R1"), ..al], init), "R0"),
    0x22114433,
  )
  let s = run("PKHTB", [r("R0"), r("R1"), r("R2"), i(16), ..al], init)
  assert_eq(reg_value(s, "R0"), 0x1122AABB)
}

///|
test "swap byte" {
  inspect(
    lift_str("SWPB", [r("R0"), r("R1"), r("R2"), ..al]),
    content=(
      #|%v1:imm8 := load(mem:mem32x8, R2:imm32):imm8
      #|mem:mem32x8 := store(mem:mem32x8, R2:imm32, extract[7:0](R1:imm32))
      #|R0:imm32 := pad:32[%v1:imm8]
    ),
  )
  let init = state([("R1", 0x1FF), ("R2", 0x1001)], bytes=b"\x10\x20\x30\x40")
  let s = run("SWPB", [r("R0"), r("R1"), r("R2"), ..al], init)
  assert_eq(reg_value(s, "R0"), 0x20)
  assert_eq(mem_word(s, 0x1000), 0x4030FF10)
}

///|
test "conditional bit operations use ite" {
  inspect(
    lift_str("REV", [r("R0"), r("R1"), ..cc(0)]),
    content=(
      #|%v1:imm1 := (ZF:imm1 == 1:1u)
      #|R0:imm32 := ite(%v1:imm1, concat(concat(concat(extract[7:0](R1:imm32), extract[15:8](R1:imm32)), extract[23:16](R1:imm32)), extract[31:24](R1:imm32)), R0:imm32)
    ),
  )
  inspect(
    lift_error("REV", [i(0), r("R1"), ..al]),
    content="Failure: REV:ops ((Imm 0:32u) (Reg R1) (Imm 0xE:32u) (Reg Nil)) doesn't match bits insn REV",
  )
}
