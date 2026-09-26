// Execute lifted Thumb BIL with the `types` BIL evaluator to check the
// concrete effect of flags, conditions and memory operations.

///|
fn word(width : Int, value : UInt64) -> @types.BilValue raise {
  BilWord(@types.Word::of_uint64(width~, value))
}

///|
fn machine(regs : Array[(String, UInt64)]) -> @types.BilState raise {
  let mut state = @types.BilState::new().set(
    "mem",
    BilMem(@types.BilMemory::empty(addr_width=32)),
  )
  for flag in ["NF", "ZF", "CF", "VF"] {
    state = state.set(flag, word(1, 0))
  }
  for reg in regs {
    state = state.set(reg.0, word(32, reg.1))
  }
  state
}

///|
fn run(
  state : @types.BilState,
  name : String,
  ops : Array[@mc.Op],
) -> @types.BilState raise {
  let stmts = @thumb.lift(@mc.Insn::create(name, ops, addr=0x1000, size=2))
  match @types.exec_stmts(stmts, state~) {
    Ok(next) => next
    Err(reason) => fail(reason)
  }
}

///|
fn get(state : @types.BilState, name : String) -> UInt64 raise {
  match state.get_word(name) {
    Some(w) => w.to_uint64()
    None => fail("missing \{name}")
  }
}

///|
fn flags(state : @types.BilState) -> String raise {
  let parts = []
  for f in ["NF", "ZF", "CF", "VF"] {
    parts.push("\{f}=\{get(state, f)}")
  }
  parts.join(" ")
}

///|
fn ops(names : Array[String], tail : Array[@mc.Op]) -> Array[@mc.Op] {
  [..names.map(n => @mc.Op::reg(n)), ..tail]
}

///|
let al_ops : Array[@mc.Op] = [@mc.Imm(14), @mc.Op::reg("CPSR")]

///|
test "eval: add flags" {
  let s = run(
    machine([("R1", 0xFFFFFFFF)]),
    "tADDi3",
    ops(["R0", "CPSR", "R1"], [@mc.Imm(1), ..al_ops]),
  )
  assert_eq(get(s, "R0"), 0)
  inspect(flags(s), content="NF=0 ZF=1 CF=1 VF=0")
  let s = run(
    machine([("R2", 0x7FFFFFFF)]),
    "tADDi8",
    ops(["R2", "CPSR", "R2"], [@mc.Imm(1), ..al_ops]),
  )
  assert_eq(get(s, "R2"), 0x80000000)
  inspect(flags(s), content="NF=1 ZF=0 CF=0 VF=1")
  // ADC adds the incoming carry
  let s = machine([("R0", 1), ("R1", 2)]).set("CF", word(1, 1))
  let s = run(s, "tADC", ops(["R0", "CPSR", "R0", "R1"], al_ops))
  assert_eq(get(s, "R0"), 4)
}

///|
test "eval: subtract and compare flags" {
  let s = run(
    machine([("R0", 3), ("R1", 5)]),
    "tCMPr",
    ops(["R0", "R1"], al_ops),
  )
  inspect(flags(s), content="NF=1 ZF=0 CF=0 VF=0")
  assert_eq(get(s, "R0"), 3)
  let s = run(
    machine([("R0", 5)]),
    "tCMPi8",
    ops(["R0"], [@mc.Imm(5), ..al_ops]),
  )
  inspect(flags(s), content="NF=0 ZF=1 CF=1 VF=0")
  let s = run(
    machine([("R1", 0x80000000)]),
    "tSUBi3",
    ops(["R0", "CPSR", "R1"], [@mc.Imm(1), ..al_ops]),
  )
  assert_eq(get(s, "R0"), 0x7FFFFFFF)
  inspect(flags(s), content="NF=0 ZF=0 CF=1 VF=1")
}

///|
test "eval: shifts" {
  let s = run(
    machine([("R1", 0x80000001)]),
    "tLSLri",
    ops(["R0", "CPSR", "R1"], [@mc.Imm(1), ..al_ops]),
  )
  assert_eq(get(s, "R0"), 2)
  inspect(flags(s), content="NF=0 ZF=0 CF=1 VF=0")
  let s = run(
    machine([("R1", 0x80000008)]),
    "tASRri",
    ops(["R0", "CPSR", "R1"], [@mc.Imm(4), ..al_ops]),
  )
  assert_eq(get(s, "R0"), 0xF8000000)
  inspect(flags(s), content="NF=1 ZF=0 CF=1 VF=0")
  let s = run(
    machine([("R1", 0x80000008)]),
    "tLSRri",
    ops(["R0", "CPSR", "R1"], [@mc.Imm(4), ..al_ops]),
  )
  assert_eq(get(s, "R0"), 0x08000000)
}

///|
test "eval: conditional execution leaves state alone when false" {
  let eq : Array[@mc.Op] = [@mc.Imm(0), @mc.Op::reg("CPSR")]
  let s = run(
    machine([("R0", 7)]),
    "tMOVi8",
    ops(["R0", "CPSR"], [@mc.Imm(1), ..eq]),
  )
  assert_eq(get(s, "R0"), 7)
  let s = run(
    machine([("R0", 7)]).set("ZF", word(1, 1)),
    "tMOVi8",
    ops(["R0", "CPSR"], [@mc.Imm(1), ..eq]),
  )
  assert_eq(get(s, "R0"), 1)
  // conditional instructions do not update flags
  inspect(flags(s), content="NF=0 ZF=1 CF=0 VF=0")
}

///|
test "eval: push, pop and byte loads" {
  let s = machine([("SP", 0x2000), ("R4", 0xDEADBEEF), ("LR", 0x1235)])
  let s = run(s, "tPUSH", [..al_ops, @mc.Op::reg("R4"), @mc.Op::reg("LR")])
  assert_eq(get(s, "SP"), 0x1FF8)
  let s = run(s, "tPOP", [..al_ops, @mc.Op::reg("R5"), @mc.Op::reg("R6")])
  assert_eq(get(s, "SP"), 0x2000)
  assert_eq(get(s, "R5"), 0xDEADBEEF)
  assert_eq(get(s, "R6"), 0x1235)
  // little-endian: byte at 0x1FF8 is 0xEF
  let s = s.set("R1", word(32, 0x1FF8)).set("R2", word(32, 0))
  let t = run(s, "tLDRSB", ops(["R0", "R1", "R2"], al_ops))
  assert_eq(get(t, "R0"), 0xFFFFFFEF)
  let t = run(s, "tLDRBi", ops(["R0", "R1"], [@mc.Imm(1), ..al_ops]))
  assert_eq(get(t, "R0"), 0xBE)
  let t = run(s, "tLDRHi", ops(["R0", "R1"], [@mc.Imm(1), ..al_ops]))
  assert_eq(get(t, "R0"), 0xDEAD)
  let t = run(
    s.set("R3", word(32, 0x1234ABCD)),
    "tSTRHi",
    ops(["R3", "R1"], [@mc.Imm(0), ..al_ops]),
  )
  let t = run(t, "tLDRi", ops(["R0", "R1"], [@mc.Imm(0), ..al_ops]))
  assert_eq(get(t, "R0"), 0xDEADABCD)
}

///|
test "eval: multi-register store and load" {
  let s = machine([("R0", 0x3000), ("R1", 11), ("R2", 22)])
  let s = run(
    s,
    "tSTMIA_UPD",
    [@mc.Op::reg("R0"), ..al_ops, @mc.Op::reg("R1"), @mc.Op::reg("R2")],
  )
  assert_eq(get(s, "R0"), 0x3008)
  let s = s.set("R3", word(32, 0x3000))
  let s = run(
    s,
    "tLDMIA",
    [@mc.Op::reg("R3"), ..al_ops, @mc.Op::reg("R4"), @mc.Op::reg("R5")],
  )
  assert_eq(get(s, "R3"), 0x3008)
  assert_eq(get(s, "R4"), 11)
  assert_eq(get(s, "R5"), 22)
}

///|
test "eval: extensions" {
  let s = machine([("R1", 0x1234F080)])
  assert_eq(get(run(s, "tSXTB", ops(["R0", "R1"], al_ops)), "R0"), 0xFFFFFF80)
  assert_eq(get(run(s, "tSXTH", ops(["R0", "R1"], al_ops)), "R0"), 0xFFFFF080)
  assert_eq(get(run(s, "tUXTB", ops(["R0", "R1"], al_ops)), "R0"), 0x80)
  assert_eq(get(run(s, "tUXTH", ops(["R0", "R1"], al_ops)), "R0"), 0xF080)
}

///|
test "lifted BIL is well typed and little-endian" {
  let stmts = @thumb.lift(
    @mc.Insn::create(
      "tLDRHi",
      [@mc.Op::reg("R0"), @mc.Op::reg("R1"), @mc.Imm(1), ..al_ops],
    ),
  )
  assert_true(@types.check_stmt_types(stmts) is Ok(_))
  assert_true(@types.exists_exp(stmts, e => e is Load(endian=LittleEndian, ..)))
  assert_true(!@types.exists_exp(stmts, e => e is Load(endian=BigEndian, ..)))
}
