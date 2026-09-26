///|
test "branch: mips32 compare-and-branch semantics" {
  inspect(
    show("mips", [
      ("BEQ", [r("T0"), r("T1"), i(0x20)]),
      ("BEQL", [r("T0"), r("T1"), i(0x20)]),
      ("BNE", [r("T0"), r("ZERO"), i(-8)]),
      ("BLTC", [r("A0"), r("A1"), i(0x10)]),
      ("BGEC", [r("A0"), r("A1"), i(0x10)]),
      ("BEQC", [r("A0"), r("A1"), i(0x10)]),
      ("BNEC", [r("A0"), r("A1"), i(0x10)]),
      ("BLTUC", [r("A0"), r("A1"), i(0x10)]),
      ("BGEUC", [r("A0"), r("A1"), i(0x10)]),
    ]),
    content=(
      #|BEQ T0, T1, 0x20
      #|  if (T0 == T1) {
      #|    jmp (0x1000:32u + 0x20:32u)
      #|  }
      #|BEQL T0, T1, 0x20
      #|  if (T0 == T1) {
      #|    jmp (0x1000:32u + 0x20:32u)
      #|  }
      #|BNE T0, ZERO, 0x-8
      #|  if ~(T0 == ZERO) {
      #|    jmp (0x1000:32u + 0xFFFFFFF8:32u)
      #|  }
      #|BLTC A0, A1, 0x10
      #|  if (A0 < A1) {
      #|    jmp (0x1000:32u + 0x10:32u)
      #|  }
      #|BGEC A0, A1, 0x10
      #|  if (A1 <= A0) {
      #|    jmp (0x1000:32u + 0x10:32u)
      #|  }
      #|BEQC A0, A1, 0x10
      #|  if (A0 == A1) {
      #|    jmp (0x1000:32u + 0x10:32u)
      #|  }
      #|BNEC A0, A1, 0x10
      #|  if (A0 != A1) {
      #|    jmp (0x1000:32u + 0x10:32u)
      #|  }
      #|BLTUC A0, A1, 0x10
      #|  if (A0 < A1) {
      #|    jmp (0x1000:32u + 0x10:32u)
      #|  }
      #|BGEUC A0, A1, 0x10
      #|  if (A1 <= A0) {
      #|    jmp (0x1000:32u + 0x10:32u)
      #|  }
      #|
    ),
  )
}

///|
test "branch: mips32 compare-with-zero semantics" {
  inspect(
    show("mips", [
      ("BGEZ", [r("S0"), i(0x40)]),
      ("BLEZ", [r("S0"), i(0x40)]),
      ("BGTZ", [r("S0"), i(0x40)]),
      ("BGTZL", [r("S0"), i(0x40)]),
      ("BLTZALC", [r("S0"), i(0x40)]),
      ("BLEZALC", [r("S0"), i(0x40)]),
      ("BGEZALC", [r("S0"), i(0x40)]),
      ("BGTZALC", [r("S0"), i(0x40)]),
      ("BEQZALC", [r("S0"), i(0x40)]),
      ("BNEZALC", [r("S0"), i(0x40)]),
      ("BLTZC", [r("S0"), i(0x40)]),
      ("BLEZC", [r("S0"), i(0x40)]),
      ("BGEZC", [r("S0"), i(0x40)]),
      ("BGTZC", [r("S0"), i(0x40)]),
      ("BEQZC", [r("S0"), i(0x40)]),
      ("BNEZC", [r("S0"), i(0x40)]),
    ]),
    content=(
      #|BGEZ S0, 0x40
      #|  if (pad:32[0:1u] <= S0) {
      #|    jmp (0x1000:32u + 0x40:32u)
      #|  }
      #|BLEZ S0, 0x40
      #|  if (S0 <= pad:32[0:1u]) {
      #|    jmp (0x1000:32u + 0x40:32u)
      #|  }
      #|BGTZ S0, 0x40
      #|  if (pad:32[0:1u] <= S0) {
      #|    jmp (0x1000:32u + 0x40:32u)
      #|  }
      #|BGTZL S0, 0x40
      #|  if (pad:32[0:1u] <= S0) {
      #|    jmp (0x1000:32u + 0x40:32u)
      #|  }
      #|BLTZALC S0, 0x40
      #|  if (S0 < pad:32[0:1u]) {
      #|    jmp (0x1000:32u + 0x40:32u)
      #|  }
      #|BLEZALC S0, 0x40
      #|  if (S0 <= pad:32[0:1u]) {
      #|    jmp (0x1000:32u + 0x40:32u)
      #|  }
      #|BGEZALC S0, 0x40
      #|  if (pad:32[0:1u] <= S0) {
      #|    jmp (0x1000:32u + 0x40:32u)
      #|  }
      #|BGTZALC S0, 0x40
      #|  if (pad:32[0:1u] < S0) {
      #|    jmp (0x1000:32u + 0x40:32u)
      #|  }
      #|BEQZALC S0, 0x40
      #|  if (S0 == pad:32[0:1u]) {
      #|    jmp (0x1000:32u + 0x40:32u)
      #|  }
      #|BNEZALC S0, 0x40
      #|  if (S0 != pad:32[0:1u]) {
      #|    jmp (0x1000:32u + 0x40:32u)
      #|  }
      #|BLTZC S0, 0x40
      #|  if (S0 < pad:32[0:1u]) {
      #|    jmp (0x1000:32u + 0x40:32u)
      #|  }
      #|BLEZC S0, 0x40
      #|  if (S0 <= pad:32[0:1u]) {
      #|    jmp (0x1000:32u + 0x40:32u)
      #|  }
      #|BGEZC S0, 0x40
      #|  if (pad:32[0:1u] <= S0) {
      #|    jmp (0x1000:32u + 0x40:32u)
      #|  }
      #|BGTZC S0, 0x40
      #|  if (pad:32[0:1u] < S0) {
      #|    jmp (0x1000:32u + 0x40:32u)
      #|  }
      #|BEQZC S0, 0x40
      #|  if (S0 == pad:32[0:1u]) {
      #|    jmp (0x1000:32u + 0x40:32u)
      #|  }
      #|BNEZC S0, 0x40
      #|  if (S0 != pad:32[0:1u]) {
      #|    jmp (0x1000:32u + 0x40:32u)
      #|  }
      #|
    ),
  )
}

///|
test "branch: mips32 jumps and links" {
  inspect(
    show("mips", [
      ("BAL", [r("RA"), i(0x100)]),
      ("BGEZAL", [r("A0"), i(0x100)]),
      ("J", [i(0x400000)]),
      ("JAL", [i(0x400000)]),
      ("JALR", [r("RA"), r("T9")]),
      ("JALR.HB", [r("RA"), r("T9")]),
      ("JALR64", [r("RA"), r("T9")]),
      ("JIALC", [r("T9"), i(8)]),
      ("JIC", [r("T9"), i(8)]),
      ("JR", [r("RA")]),
      ("NAL", []),
    ]),
    content=(
      #|BAL RA, 0x100
      #|  RA := (0x1000:32u + extend:32[8:8u])
      #|  jmp (0x1000:32u + 0x100:32u)
      #|BGEZAL A0, 0x100
      #|  if (pad:32[0:1u] <= A0) {
      #|    RA := (0x1000:32u + extend:32[8:8u])
      #|    jmp (0x1000:32u + 0x100:32u)
      #|  }
      #|J 0x400000
      #|  jmp 0x400000:32u
      #|JAL 0x400000
      #|  RA := (0x1000:32u + extend:32[8:8u])
      #|  jmp 0x400000:32u
      #|JALR RA, T9
      #|  RA := (0x1000:32u + extend:32[8:8u])
      #|  jmp T9
      #|JALR.HB RA, T9
      #|  RA := (0x1000:32u + extend:32[8:8u])
      #|  jmp T9
      #|JALR64 RA, T9
      #|  RA := (0x1000:32u + extend:32[8:8u])
      #|  jmp T9
      #|JIALC T9, 0x8
      #|  RA := (0x1000:32u + extend:32[8:8u])
      #|  jmp (T9 + 8:32u)
      #|JIC T9, 0x8
      #|  jmp (T9 + 8:32u)
      #|JR RA
      #|  jmp RA
      #|NAL 
      #|  RA := (0x1000:32u + extend:32[8:8u])
      #|
    ),
  )
}

///|
test "branch: mips64 semantics" {
  inspect(
    show("mips64", [
      ("BEQ", [r("T0_64"), r("T1_64"), i(0x20)]),
      ("BGEZAL", [r("A0_64"), i(0x100)]),
      ("JALR64", [r("RA_64"), r("T9_64")]),
      ("JR", [r("RA_64")]),
      ("J", [i(0x400000)]),
    ]),
    content=(
      #|BEQ T0_64, T1_64, 0x20
      #|  if (T0 == T1) {
      #|    jmp (0x1000:64u + extend:64[0x20:32u])
      #|  }
      #|BGEZAL A0_64, 0x100
      #|  if (pad:64[0:1u] <= A0) {
      #|    RA := (0x1000:64u + extend:64[8:8u])
      #|    jmp (0x1000:64u + extend:64[0x100:32u])
      #|  }
      #|JALR64 RA_64, T9_64
      #|  RA := (0x1000:64u + extend:64[8:8u])
      #|  jmp T9
      #|JR RA_64
      #|  jmp RA
      #|J 0x400000
      #|  jmp 0x400000:32u
      #|
    ),
  )
}

///|
test "branch: every branch has a one-instruction delay slot" {
  let branches = [
    "BAL", "BEQ", "BEQL", "BNE", "BGEZ", "BLEZ", "BGEZAL", "BLTZALC", "BLEZALC",
    "BGEZALC", "BGTZALC", "BEQZALC", "BNEZALC", "BLTC", "BGEC", "BEQC", "BNEC", "BLTUC",
    "BGEUC", "BLTZC", "BLEZC", "BGEZC", "BGTZC", "BEQZC", "BNEZC", "BGTZ", "BGTZL",
    "J", "JAL", "JALR", "JALR.HB", "JIALC", "JIC", "JR", "NAL", "JALR64",
  ]
  for name in branches {
    assert_eq(@mips.delay_slot(name), Some(1))
  }
  let delayed = @mips.opcodes().filter(name => @mips.delay_slot(name) is Some(_))
  assert_eq(delayed.length(), branches.length())
  assert_eq(@mips.delay_slot("ADDiu"), None)
  assert_eq(@mips.delay_slot("FOO"), None)
}

///|
test "branch: evaluation" {
  let bal = @mips.lift_mips(insn("BAL", [r("RA"), i(0x100)], addr=0x4000))
  let state = run(bal, [])
  assert_eq(reg_hex(state, "RA"), "0x4008:32u")
  let taken = @mips.lift_mips(insn("BNE", [r("T0"), r("T1"), i(0x20)]))
  guard taken is [If(cond~, ..)] else { fail("expected a conditional") }
  let regs = [("T0", word_value(32, 1)), ("T1", word_value(32, 2))]
  let cond_value = cond.eval_value(
    regs.fold(init=Map([]), (m, reg) => {
      m[reg.0] = reg.1
      m
    }),
  )
  assert_eq(cond_value, Ok(BilWord(@types.Word::b1())))
}
