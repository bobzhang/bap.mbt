///|
fn r(name : String) -> @mc.Op {
  @mc.Op::reg(name)
}

///|
fn i(value : Int64) -> @mc.Op {
  @mc.Imm(value)
}

///|
/// Predicate operands: condition immediate plus the `CPSR` flag register.
fn pred(cond : @thumb.Cond) -> Array[@mc.Op] {
  [i(cond.to_int().to_int64()), r("CPSR")]
}

///|
fn al() -> Array[@mc.Op] {
  pred(AL)
}

///|
fn insn(
  name : String,
  ops : Array[@mc.Op],
  addr~ : UInt64 = 0x1000,
) -> @mc.Insn {
  @mc.Insn::create(name, ops, addr~, size=2)
}

///|
/// Render BIL one statement per line, expanding `If` bodies (the default
/// `Stmt::to_string` only summarises them).
fn render(stmts : Array[@types.Stmt], indent~ : String = "") -> String {
  stmts
  .map(s => {
    match s {
      If(cond~, yes~, no~) => {
        let inner = indent + "  "
        let head = "\{indent}if \{cond.to_string()} {\n\{render(yes, indent=inner)}\n\{indent}}"
        if no.is_empty() {
          head
        } else {
          "\{head} else {\n\{render(no, indent=inner)}\n\{indent}}"
        }
      }
      _ => indent + s.to_string()
    }
  })
  .join("\n")
}

///|
fn lift(
  name : String,
  ops : Array[@mc.Op],
  addr~ : UInt64 = 0x1000,
) -> String raise {
  render(@thumb.lift(insn(name, ops, addr~)))
}

///|
test "opcode table mirrors thumb_opcodes" {
  let all = @thumb.Opcode::all()
  assert_eq(all.length(), 54)
  for op in all {
    assert_eq(@thumb.Opcode::of_name(op.name()), Some(op))
  }
  assert_eq(@thumb.Opcode::of_name("tadc"), None)
  assert_eq(@thumb.Opcode::of_name("t2LDRpci"), Some(T2LDRpci))
  let count = (k : @thumb.OpcodeKind) => {
    all.filter(op => op.kind() == k).length()
  }
  assert_eq(count(Mov), 18)
  assert_eq(count(MemMulti), 6)
  assert_eq(count(Mem), 18)
  assert_eq(count(Branch), 8)
  assert_eq(count(Bit), 4)
  assert_true(@thumb.TPUSH.is_mem())
  assert_true(!@thumb.TB.is_mem())
  inspect(@thumb.TSTMIA_UPD, content="tSTMIA_UPD")
  let conds = @thumb.Cond::all()
  assert_eq(conds.length(), 15)
  for c in conds {
    assert_eq(@thumb.Cond::of_int(c.to_int()), Some(c))
  }
  assert_eq(@thumb.Cond::of_int(15), None)
  assert_eq(@thumb.Cond::of_int(-1), None)
}

///|
test "mov group: additions" {
  inspect(
    lift("tADDi3", [r("R0"), r("CPSR"), r("R1"), i(3), ..al()]),
    content=(
      #|%t:imm32 := (R1:imm32 + 3:32u)
      #|NF:imm1 := extract[31:31](%t:imm32)
      #|ZF:imm1 := (%t:imm32 == 0:32u)
      #|CF:imm1 := (%t:imm32 < R1:imm32)
      #|VF:imm1 := extract[31:31](((R1:imm32 ^ (not 3:32u)) & (R1:imm32 ^ %t:imm32)))
      #|R0:imm32 := %t:imm32
    ),
  )
  inspect(
    lift("tADDi3", [r("R0"), r("CPSR"), r("R1"), i(3), ..pred(EQ)]),
    content=(
      #|R0:imm32 := ite(ZF:imm1, (R1:imm32 + 3:32u), R0:imm32)
    ),
  )
  inspect(
    lift("tADDi8", [r("R2"), r("CPSR"), r("R2"), i(200), ..al()]),
    content=(
      #|%t:imm32 := (R2:imm32 + 0xC8:32u)
      #|NF:imm1 := extract[31:31](%t:imm32)
      #|ZF:imm1 := (%t:imm32 == 0:32u)
      #|CF:imm1 := (%t:imm32 < R2:imm32)
      #|VF:imm1 := extract[31:31](((R2:imm32 ^ (not 0xC8:32u)) & (R2:imm32 ^ %t:imm32)))
      #|R2:imm32 := %t:imm32
    ),
  )
  inspect(
    lift("tADDrr", [r("R0"), r("CPSR"), r("R1"), r("R2"), ..pred(NE)]),
    content=(
      #|R0:imm32 := ite((not ZF:imm1), (R1:imm32 + R2:imm32), R0:imm32)
    ),
  )
  inspect(
    lift("tADC", [r("R0"), r("CPSR"), r("R0"), r("R1"), ..al()]),
    content=(
      #|%t:imm32 := ((R0:imm32 + R1:imm32) + pad:32[CF:imm1])
      #|NF:imm1 := extract[31:31](%t:imm32)
      #|ZF:imm1 := (%t:imm32 == 0:32u)
      #|CF:imm1 := extract[31:31](((R0:imm32 & R1:imm32) | ((R0:imm32 | R1:imm32) & (not %t:imm32))))
      #|VF:imm1 := extract[31:31](((R0:imm32 ^ (not R1:imm32)) & (R0:imm32 ^ %t:imm32)))
      #|R0:imm32 := %t:imm32
    ),
  )
  inspect(
    lift("tADDrSPi", [r("R3"), r("SP"), i(4), ..al()]),
    content=(
      #|R3:imm32 := (SP:imm32 + 0x10:32u)
    ),
  )
  inspect(
    lift("tADDspi", [r("SP"), r("SP"), i(2), ..pred(GT)]),
    content=(
      #|SP:imm32 := ite(((not ZF:imm1) & (NF:imm1 == VF:imm1)), (SP:imm32 + 8:32u), SP:imm32)
    ),
  )
}

///|
test "mov group: subtractions and compares" {
  inspect(
    lift("tSUBi3", [r("R0"), r("CPSR"), r("R1"), i(1), ..al()]),
    content=(
      #|%t:imm32 := (R1:imm32 - 1:32u)
      #|NF:imm1 := extract[31:31](%t:imm32)
      #|ZF:imm1 := (%t:imm32 == 0:32u)
      #|CF:imm1 := (not (R1:imm32 < 1:32u))
      #|VF:imm1 := extract[31:31](((R1:imm32 ^ 1:32u) & (R1:imm32 ^ %t:imm32)))
      #|R0:imm32 := %t:imm32
    ),
  )
  inspect(
    lift("tSUBi8", [r("R4"), r("CPSR"), r("R4"), i(8), ..pred(LT)]),
    content=(
      #|R4:imm32 := ite((NF:imm1 != VF:imm1), (R4:imm32 - 8:32u), R4:imm32)
    ),
  )
  inspect(
    lift("tSUBrr", [r("R0"), r("CPSR"), r("R1"), r("R2"), ..al()]),
    content=(
      #|%t:imm32 := (R1:imm32 - R2:imm32)
      #|NF:imm1 := extract[31:31](%t:imm32)
      #|ZF:imm1 := (%t:imm32 == 0:32u)
      #|CF:imm1 := (not (R1:imm32 < R2:imm32))
      #|VF:imm1 := extract[31:31](((R1:imm32 ^ R2:imm32) & (R1:imm32 ^ %t:imm32)))
      #|R0:imm32 := %t:imm32
    ),
  )
  inspect(
    lift("tSUBspi", [r("SP"), r("SP"), i(4), ..al()]),
    content=(
      #|SP:imm32 := (SP:imm32 - 0x10:32u)
    ),
  )
  inspect(
    lift("tCMPi8", [r("R0"), i(5), ..al()]),
    content=(
      #|%t:imm32 := (R0:imm32 - 5:32u)
      #|NF:imm1 := extract[31:31](%t:imm32)
      #|ZF:imm1 := (%t:imm32 == 0:32u)
      #|CF:imm1 := (not (R0:imm32 < 5:32u))
      #|VF:imm1 := extract[31:31](((R0:imm32 ^ 5:32u) & (R0:imm32 ^ %t:imm32)))
    ),
  )
  inspect(
    lift("tCMPr", [r("R0"), r("R1"), ..al()]),
    content=(
      #|%t:imm32 := (R0:imm32 - R1:imm32)
      #|NF:imm1 := extract[31:31](%t:imm32)
      #|ZF:imm1 := (%t:imm32 == 0:32u)
      #|CF:imm1 := (not (R0:imm32 < R1:imm32))
      #|VF:imm1 := extract[31:31](((R0:imm32 ^ R1:imm32) & (R0:imm32 ^ %t:imm32)))
    ),
  )
}

///|
test "mov group: moves, shifts and orr" {
  inspect(
    lift("tMOVi8", [r("R0"), r("CPSR"), i(0x80), ..al()]),
    content=(
      #|%t:imm32 := 0x80:32u
      #|NF:imm1 := 0:1u
      #|ZF:imm1 := 0:1u
      #|R0:imm32 := %t:imm32
    ),
  )
  inspect(
    lift("tMOVi8", [r("R0"), r("CPSR"), i(0), ..pred(MI)]),
    content=(
      #|R0:imm32 := ite(NF:imm1, 0:32u, R0:imm32)
    ),
  )
  inspect(
    lift("tMOVSr", [r("R1"), r("R2")]),
    content=(
      #|R1:imm32 := R2:imm32
      #|NF:imm1 := extract[31:31](R1:imm32)
      #|ZF:imm1 := (R1:imm32 == 0:32u)
    ),
  )
  inspect(
    lift("tASRri", [r("R0"), r("CPSR"), r("R1"), i(3), ..al()]),
    content=(
      #|%t:imm32 := (R1:imm32 a>> 3:32u)
      #|CF:imm1 := extract[2:2](R1:imm32)
      #|NF:imm1 := extract[31:31](%t:imm32)
      #|ZF:imm1 := (%t:imm32 == 0:32u)
      #|R0:imm32 := %t:imm32
    ),
  )
  inspect(
    lift("tASRri", [r("R0"), r("CPSR"), r("R1"), i(0), ..al()]),
    content=(
      #|%t:imm32 := ite(extract[31:31](R1:imm32), 0xFFFFFFFF:32u, 0:32u)
      #|CF:imm1 := extract[31:31](R1:imm32)
      #|NF:imm1 := extract[31:31](%t:imm32)
      #|ZF:imm1 := (%t:imm32 == 0:32u)
      #|R0:imm32 := %t:imm32
    ),
  )
  inspect(
    lift("tLSRri", [r("R0"), r("CPSR"), r("R1"), i(4), ..al()]),
    content=(
      #|%t:imm32 := (R1:imm32 >> 4:32u)
      #|CF:imm1 := extract[3:3](R1:imm32)
      #|NF:imm1 := extract[31:31](%t:imm32)
      #|ZF:imm1 := (%t:imm32 == 0:32u)
      #|R0:imm32 := %t:imm32
    ),
  )
  inspect(
    lift("tLSRri", [r("R0"), r("CPSR"), r("R1"), i(0), ..al()]),
    content=(
      #|%t:imm32 := 0:32u
      #|CF:imm1 := extract[31:31](R1:imm32)
      #|NF:imm1 := 0:1u
      #|ZF:imm1 := 1:1u
      #|R0:imm32 := %t:imm32
    ),
  )
  inspect(
    lift("tLSLri", [r("R0"), r("CPSR"), r("R1"), i(4), ..al()]),
    content=(
      #|%t:imm32 := (R1:imm32 << 4:32u)
      #|CF:imm1 := extract[28:28](R1:imm32)
      #|NF:imm1 := extract[31:31](%t:imm32)
      #|ZF:imm1 := (%t:imm32 == 0:32u)
      #|R0:imm32 := %t:imm32
    ),
  )
  inspect(
    lift("tLSLri", [r("R0"), r("CPSR"), r("R1"), i(0), ..al()]),
    content=(
      #|%t:imm32 := R1:imm32
      #|NF:imm1 := extract[31:31](%t:imm32)
      #|ZF:imm1 := (%t:imm32 == 0:32u)
      #|R0:imm32 := %t:imm32
    ),
  )
  inspect(
    lift("tLSLri", [r("R0"), r("CPSR"), r("R1"), i(4), ..pred(CS)]),
    content=(
      #|R0:imm32 := ite(CF:imm1, (R1:imm32 << 4:32u), R0:imm32)
    ),
  )
  inspect(
    lift("tORR", [r("R0"), r("CPSR"), r("R0"), r("R1"), ..al()]),
    content=(
      #|%t:imm32 := (R0:imm32 | R1:imm32)
      #|NF:imm1 := extract[31:31](%t:imm32)
      #|ZF:imm1 := (%t:imm32 == 0:32u)
      #|R0:imm32 := %t:imm32
    ),
  )
}

///|
test "mem group: loads" {
  inspect(
    lift("tLDRi", [r("R0"), r("R1"), i(2), ..al()]),
    content=(
      #|R0:imm32 := load(mem:mem32x8, (R1:imm32 + 8:32u)):imm32
    ),
  )
  inspect(
    lift("tLDRspi", [r("R0"), r("SP"), i(1), ..pred(HI)]),
    content=(
      #|R0:imm32 := ite((CF:imm1 & (not ZF:imm1)), load(mem:mem32x8, (SP:imm32 + 4:32u)):imm32, R0:imm32)
    ),
  )
  inspect(
    lift("tLDRr", [r("R0"), r("R1"), r("R2"), ..al()]),
    content=(
      #|R0:imm32 := load(mem:mem32x8, (R1:imm32 + R2:imm32)):imm32
    ),
  )
  // pc = (0x1002 + 4) & ~3 = 0x1004
  inspect(
    lift("tLDRpci", [r("R0"), i(0x10), ..al()], addr=0x1002),
    content=(
      #|R0:imm32 := load(mem:mem32x8, (0x1004:32u + 0x10:32u)):imm32
    ),
  )
  inspect(
    lift("t2LDRpci", [r("R0"), i(8), ..al()], addr=0x1000),
    content=(
      #|R0:imm32 := load(mem:mem32x8, (0x1004:32u + 8:32u)):imm32
    ),
  )
  inspect(
    lift("tLDRBi", [r("R0"), r("R1"), i(3), ..al()]),
    content=(
      #|R0:imm32 := pad:32[load(mem:mem32x8, (R1:imm32 + 3:32u)):imm8]
    ),
  )
  inspect(
    lift("tLDRBr", [r("R0"), r("R1"), r("R2"), ..al()]),
    content=(
      #|R0:imm32 := pad:32[load(mem:mem32x8, (R1:imm32 + R2:imm32)):imm8]
    ),
  )
  inspect(
    lift("tLDRSB", [r("R0"), r("R1"), r("R2"), ..al()]),
    content=(
      #|R0:imm32 := extend:32[load(mem:mem32x8, (R1:imm32 + R2:imm32)):imm8]
    ),
  )
  inspect(
    lift("tLDRHi", [r("R0"), r("R1"), i(3), ..al()]),
    content=(
      #|R0:imm32 := pad:32[load(mem:mem32x8, (R1:imm32 + 6:32u)):imm16]
    ),
  )
  inspect(
    lift("tLDRHr", [r("R0"), r("R1"), r("R2"), ..al()]),
    content=(
      #|R0:imm32 := pad:32[load(mem:mem32x8, (R1:imm32 + R2:imm32)):imm16]
    ),
  )
  inspect(
    lift("tLDRSH", [r("R0"), r("R1"), r("R2"), ..pred(LS)]),
    content=(
      #|R0:imm32 := ite(((not CF:imm1) | ZF:imm1), extend:32[load(mem:mem32x8, (R1:imm32 + R2:imm32)):imm16], R0:imm32)
    ),
  )
}

///|
test "mem group: stores" {
  inspect(
    lift("tSTRi", [r("R0"), r("R1"), i(1), ..al()]),
    content=(
      #|mem:mem32x8 := store(mem:mem32x8, (R1:imm32 + 4:32u), R0:imm32)
    ),
  )
  inspect(
    lift("tSTRspi", [r("R0"), r("SP"), i(1), ..pred(GE)]),
    content=(
      #|mem:mem32x8 := ite((NF:imm1 == VF:imm1), store(mem:mem32x8, (SP:imm32 + 4:32u), R0:imm32), mem:mem32x8)
    ),
  )
  inspect(
    lift("tSTRr", [r("R0"), r("R1"), r("R2"), ..al()]),
    content=(
      #|mem:mem32x8 := store(mem:mem32x8, (R1:imm32 + R2:imm32), R0:imm32)
    ),
  )
  inspect(
    lift("tSTRBi", [r("R0"), r("R1"), i(5), ..al()]),
    content=(
      #|mem:mem32x8 := store(mem:mem32x8, (R1:imm32 + 5:32u), low:8[R0:imm32])
    ),
  )
  inspect(
    lift("tSTRBr", [r("R0"), r("R1"), r("R2"), ..al()]),
    content=(
      #|mem:mem32x8 := store(mem:mem32x8, (R1:imm32 + R2:imm32), low:8[R0:imm32])
    ),
  )
  inspect(
    lift("tSTRHi", [r("R0"), r("R1"), i(2), ..al()]),
    content=(
      #|mem:mem32x8 := store(mem:mem32x8, (R1:imm32 + 4:32u), low:16[R0:imm32])
    ),
  )
  inspect(
    lift("tSTRHr", [r("R0"), r("R1"), r("R2"), ..pred(LE)]),
    content=(
      #|mem:mem32x8 := ite((ZF:imm1 | (NF:imm1 != VF:imm1)), store(mem:mem32x8, (R1:imm32 + R2:imm32), low:16[R0:imm32]), mem:mem32x8)
    ),
  )
}

///|
test "mem group: multi-register transfers" {
  inspect(
    lift("tSTMIA_UPD", [r("R0"), ..al(), r("R1"), r("R2")]),
    content=(
      #|mem:mem32x8 := store(mem:mem32x8, (R0:imm32 + 0:32u), R1:imm32)
      #|mem:mem32x8 := store(mem:mem32x8, (R0:imm32 + 4:32u), R2:imm32)
      #|R0:imm32 := (R0:imm32 + 8:32u)
    ),
  )
  inspect(
    lift("tSTMIA_UPD", [r("R0"), r("R0"), ..pred(VS), r("R1")]),
    content=(
      #|if VF:imm1 {
      #|  mem:mem32x8 := store(mem:mem32x8, (R0:imm32 + 0:32u), R1:imm32)
      #|  R0:imm32 := (R0:imm32 + 4:32u)
      #|}
    ),
  )
  inspect(
    lift("tLDMIA", [r("R3"), ..al(), r("R1"), r("R2")]),
    content=(
      #|R1:imm32 := load(mem:mem32x8, (R3:imm32 + 0:32u)):imm32
      #|R2:imm32 := load(mem:mem32x8, (R3:imm32 + 4:32u)):imm32
      #|R3:imm32 := (R3:imm32 + 8:32u)
    ),
  )
  inspect(
    lift("tPUSH", [..al(), r("R4"), r("LR")]),
    content=(
      #|SP:imm32 := (SP:imm32 - 8:32u)
      #|mem:mem32x8 := store(mem:mem32x8, (SP:imm32 + 0:32u), R4:imm32)
      #|mem:mem32x8 := store(mem:mem32x8, (SP:imm32 + 4:32u), LR:imm32)
    ),
  )
  inspect(
    lift("tPOP", [..al(), r("R4"), r("R5")]),
    content=(
      #|R4:imm32 := load(mem:mem32x8, (SP:imm32 + 0:32u)):imm32
      #|R5:imm32 := load(mem:mem32x8, (SP:imm32 + 4:32u)):imm32
      #|SP:imm32 := (SP:imm32 + 8:32u)
    ),
  )
  inspect(
    lift("tPOP", [..al(), r("R4"), r("PC")]),
    content=(
      #|R4:imm32 := load(mem:mem32x8, (SP:imm32 + 0:32u)):imm32
      #|%t:imm32 := load(mem:mem32x8, (SP:imm32 + 4:32u)):imm32
      #|SP:imm32 := (SP:imm32 + 8:32u)
      #|jmp %t:imm32
    ),
  )
  inspect(
    lift("tPOP", [..pred(VC), r("PC")]),
    content=(
      #|if (not VF:imm1) {
      #|  %t:imm32 := load(mem:mem32x8, (SP:imm32 + 0:32u)):imm32
      #|  SP:imm32 := (SP:imm32 + 4:32u)
      #|  jmp %t:imm32
      #|}
    ),
  )
}

///|
test "branch group" {
  // targets are `addr + off + 4`
  inspect(
    lift("tB", [i(0x20), ..al()]),
    content=(
      #|jmp 0x1024:32u
    ),
  )
  inspect(
    lift("tB", [i(-8), ..al()]),
    content=(
      #|jmp 0xFFC:32u
    ),
  )
  inspect(
    lift("tBcc", [i(0x10), ..pred(EQ)]),
    content=(
      #|if ZF:imm1 {
      #|  jmp 0x1014:32u
      #|}
    ),
  )
  inspect(
    lift("tBcc", [i(0x10), ..al()]),
    content=(
      #|jmp 0x1014:32u
    ),
  )
  inspect(
    lift("tBL", [..al(), i(0x101), r("CPSR")]),
    content=(
      #|LR:imm32 := 0x1005:32u
      #|jmp 0x1104:32u
    ),
  )
  inspect(
    lift("tBLXi", [..al(), i(0x200)]),
    content=(
      #|LR:imm32 := 0x1005:32u
      #|jmp 0x1204:32u
    ),
  )
  inspect(
    lift("tBLXi", [..al(), i(0x200), r("CPSR")]),
    content=(
      #|LR:imm32 := 0x1005:32u
      #|jmp 0x1204:32u
    ),
  )
  inspect(
    lift("tBLXr", [..al(), r("R3")]),
    content=(
      #|LR:imm32 := 0x1003:32u
      #|jmp (R3:imm32 & 0xFFFFFFFE:32u)
    ),
  )
  inspect(
    lift("tBLXr", [..al(), r("PC")]),
    content=(
      #|special @attribute:(bap:call arm:unpredictable)
    ),
  )
  inspect(
    lift("tBX", [r("LR"), ..al()]),
    content=(
      #|jmp (LR:imm32 & 0xFFFFFFFE:32u)
    ),
  )
  inspect(
    lift("tBX", [r("PC"), ..al()]),
    content=(
      #|jmp 0x1004:32u
    ),
  )
  inspect(
    lift("tCBNZ", [r("R0"), i(6)]),
    content=(
      #|if (not (R0:imm32 == 0:32u)) {
      #|  jmp 0x100A:32u
      #|}
    ),
  )
  inspect(
    lift("tCBZ", [r("R1"), i(6)]),
    content=(
      #|if (R1:imm32 == 0:32u) {
      #|  jmp 0x100A:32u
      #|}
    ),
  )
  assert_eq(@thumb.dest_encoding(0x1001).to_string(), "llvm-thumb")
  assert_eq(@thumb.dest_encoding(0x1000).to_string(), "llvm-armv7")
}

///|
test "bit group" {
  inspect(
    lift("tSXTB", [r("R0"), r("R1"), ..al()]),
    content=(
      #|R0:imm32 := extend:32[low:8[R1:imm32]]
    ),
  )
  inspect(
    lift("tSXTH", [r("R0"), r("R1"), ..al()]),
    content=(
      #|R0:imm32 := extend:32[low:16[R1:imm32]]
    ),
  )
  inspect(
    lift("tUXTB", [r("R0"), r("R1"), ..al()]),
    content=(
      #|R0:imm32 := pad:32[low:8[R1:imm32]]
    ),
  )
  inspect(
    lift("tUXTH", [r("R0"), r("R1"), ..pred(PL)]),
    content=(
      #|R0:imm32 := ite((not NF:imm1), pad:32[low:16[R1:imm32]], R0:imm32)
    ),
  )
}

///|
test "every condition code" {
  let rendered = @thumb.Cond::all().map(c => {
    let stmts = @thumb.lift(
      insn("tMOVi8", [r("R0"), r("CPSR"), i(1), ..pred(c)]),
    )
    "\{c.to_int()}: \{render(stmts)}"
  })
  inspect(
    rendered.join("\n"),
    content=(
      #|0: R0:imm32 := ite(ZF:imm1, 1:32u, R0:imm32)
      #|1: R0:imm32 := ite((not ZF:imm1), 1:32u, R0:imm32)
      #|2: R0:imm32 := ite(CF:imm1, 1:32u, R0:imm32)
      #|3: R0:imm32 := ite((not CF:imm1), 1:32u, R0:imm32)
      #|4: R0:imm32 := ite(NF:imm1, 1:32u, R0:imm32)
      #|5: R0:imm32 := ite((not NF:imm1), 1:32u, R0:imm32)
      #|6: R0:imm32 := ite(VF:imm1, 1:32u, R0:imm32)
      #|7: R0:imm32 := ite((not VF:imm1), 1:32u, R0:imm32)
      #|8: R0:imm32 := ite((CF:imm1 & (not ZF:imm1)), 1:32u, R0:imm32)
      #|9: R0:imm32 := ite(((not CF:imm1) | ZF:imm1), 1:32u, R0:imm32)
      #|10: R0:imm32 := ite((NF:imm1 == VF:imm1), 1:32u, R0:imm32)
      #|11: R0:imm32 := ite((NF:imm1 != VF:imm1), 1:32u, R0:imm32)
      #|12: R0:imm32 := ite(((not ZF:imm1) & (NF:imm1 == VF:imm1)), 1:32u, R0:imm32)
      #|13: R0:imm32 := ite((ZF:imm1 | (NF:imm1 != VF:imm1)), 1:32u, R0:imm32)
      #|14: %t:imm32 := 1:32u
      #|NF:imm1 := 0:1u
      #|ZF:imm1 := 0:1u
      #|R0:imm32 := %t:imm32
    ),
  )
}

///|
test "lift errors" {
  try @thumb.lift(insn("tFOO", [])) catch {
    err => assert_true(err is @mc.Unsupported(opcode="tFOO", ..))
  } noraise {
    _ => fail("expected unsupported opcode")
  }
  // modelled opcodes without upstream semantics
  for name in ["tSTMIA", "tLDMIA_UPD"] {
    try @thumb.lift(insn(name, [r("R0"), ..al(), r("R1")])) catch {
      err => assert_true(err is @mc.Unsupported(..))
    } noraise {
      _ => fail("expected unsupported opcode")
    }
  }
  // wrong operand shape
  try @thumb.lift(insn("tMOVSr", [r("R0")])) catch {
    err => assert_true(err is @mc.BadOperands(opcode="tMOVSr", ..))
  } noraise {
    _ => fail("expected bad operands")
  }
  // predicate immediate out of range
  try @thumb.lift(insn("tSXTB", [r("R0"), r("R1"), i(15), r("CPSR")])) catch {
    err => assert_true(err is @mc.BadOperands(opcode="tSXTB", ..))
  } noraise {
    _ => fail("expected bad condition")
  }
  // non-register in a register list
  try @thumb.lift(insn("tPUSH", [..al(), r("R4"), i(1)])) catch {
    err => assert_true(err is @mc.BadOperands(opcode="tPUSH", ..))
  } noraise {
    _ => fail("expected bad register list")
  }
}

///|
test "register installs the thumb provider" {
  let registry = @mc.Registry::new()
  @thumb.register(registry~)
  @thumb.register(registry~)
  assert_eq(registry.names(), [@thumb.provider_name])
  let ctx = @mc.Context::create(@core_theory.Target::thumb())
  let lifted = registry.lift(ctx, insn("tMOVSr", [r("R1"), r("R2")]))
  assert_eq(lifted.bil.length(), 3)
  // Thumb encoding of a little-endian 32-bit ARM target only
  assert_true(@thumb.accepts(ctx))
  assert_true(
    @thumb.accepts(
      @mc.Context::create(
        @core_theory.Target::arm(),
        encoding=@core_theory.Language::llvm_t32(),
      ),
    ),
  )
  assert_false(@thumb.accepts(@mc.Context::create(@core_theory.Target::arm())))
  assert_false(
    @thumb.accepts(@mc.Context::create(@core_theory.Target::thumbeb())),
  )
  assert_false(
    @thumb.accepts(@mc.Context::create(@core_theory.Target::aarch64())),
  )
}

///|
test "thumb and arm providers combine: t* to thumb, t2* to arm" {
  let registry = @mc.Registry::new()
  @thumb.register(registry~)
  @arm.register(registry~)
  // re-registration keeps the order
  @thumb.register(registry~)
  assert_eq(registry.names(), [@thumb.provider_name, @arm.provider_name])
  let ctx = @mc.Context::create(@core_theory.Target::thumb())
  // a Thumb-1 opcode is lifted by the thumb provider
  let t1 = registry.lift(ctx, insn("tMOVSr", [r("R1"), r("R2")]))
  assert_eq(t1, @thumb.provider().lift(ctx, insn("tMOVSr", [r("R1"), r("R2")])))
  // a Thumb-2 opcode is unsupported by thumb and falls through to arm
  let t2 = @mc.Insn::create(
    "t2MOVr",
    [r("R0"), r("R1"), ..al(), r("Nil")],
    addr=0x1000,
    size=4,
  )
  try @thumb.provider().lift(ctx, t2) catch {
    err => assert_true(err is Unsupported(opcode="t2MOVr", ..))
  } noraise {
    _ => fail("thumb should not model t2MOVr")
  }
  inspect(
    registry.lift(ctx, t2).bil.map(s => s.to_string()).join("\n"),
    content="R0:imm32 := R1:imm32",
  )
  // an ARM-encoded instruction never reaches the thumb provider
  let arm = @mc.Context::create(@core_theory.Target::arm())
  let movr = @mc.Insn::create(
    "MOVr",
    [r("R0"), r("R1"), ..al(), r("Nil")],
    addr=0x1000,
    size=4,
  )
  assert_eq(registry.accepting(arm).map(p => p.name()), [@arm.provider_name])
  inspect(
    registry.lift(arm, movr).bil.map(s => s.to_string()).join("\n"),
    content="R0:imm32 := R1:imm32",
  )
  // opcodes nobody models are unsupported
  try registry.lift(ctx, insn("tFOO", [])) catch {
    err => assert_true(err is Unsupported(opcode="tFOO", ..))
  } noraise {
    _ => fail("expected unsupported opcode")
  }
}

///|
test "thumb interworking branches record the destination encoding" {
  let ctx = @mc.Context::create(@core_theory.Target::thumb())
  let lift = (name : String, ops : Array[@mc.Op]) => {
    @thumb.provider().lift(ctx, insn(name, ops)).dest_encoding
  }
  // bx pc: the destination (pc + 4, word aligned) is ARM code
  assert_eq(
    lift("tBX", [r("PC"), ..al()]),
    Some(@core_theory.Language::llvm_a32()),
  )
  // blx imm always switches to ARM, bl stays in Thumb
  assert_eq(
    lift("tBLXi", [..al(), i(0x100)]),
    Some(@core_theory.Language::llvm_a32()),
  )
  assert_eq(
    lift("tBL", [..al(), i(0x100), r("CPSR")]),
    Some(@core_theory.Language::llvm_t32()),
  )
  // register branches decide at run time
  assert_eq(lift("tBX", [r("LR"), ..al()]), None)
  assert_eq(lift("tBLXr", [..al(), r("R3")]), None)
  // ordinary branches do not switch
  assert_eq(lift("tB", [i(0x10), ..al()]), None)
  assert_eq(lift("tMOVSr", [r("R1"), r("R2")]), None)
}
