///|
/// One sample instruction per modeled opcode, with MIPS64-style operands.
let samples64 : Array[(String, Array[@mc.Op])] = {
  let rrr = [r("V0_64"), r("A0_64"), r("A1_64")]
  let rr = [r("V0_64"), r("A0_64")]
  let rri = [r("V0_64"), r("A0_64"), i(8)]
  let ri = [r("A0_64"), i(8)]
  let mem = [r("T0_64"), r("SP_64"), i(8)]
  [
    ("ADD", rrr),
    ("ADDi", rri),
    ("ADDiu", rri),
    ("ADDiupc", ri),
    ("ADDu", rrr),
    ("ALUipc", ri),
    ("AND", rrr),
    ("ANDi", rri),
    ("BAL", ri),
    ("BEQ", rri),
    ("BEQC", rri),
    ("BEQL", rri),
    ("BEQZALC", ri),
    ("BEQZC", ri),
    ("BGEC", rri),
    ("BGEUC", rri),
    ("BGEZ", ri),
    ("BGEZAL", ri),
    ("BGEZALC", ri),
    ("BGEZC", ri),
    ("BGTZ", ri),
    ("BGTZALC", ri),
    ("BGTZC", ri),
    ("BGTZL", ri),
    ("BITSWAP", rr),
    ("BLEZ", ri),
    ("BLEZALC", ri),
    ("BLEZC", ri),
    ("BLTC", rri),
    ("BLTUC", rri),
    ("BLTZALC", ri),
    ("BLTZC", ri),
    ("BNE", rri),
    ("BNEC", rri),
    ("BNEZALC", ri),
    ("BNEZC", ri),
    ("CLO", rr),
    ("CLZ", rr),
    ("DADDiu", rri),
    ("DADDu", rrr),
    ("DBITSWAP", rr),
    ("DDIV", rrr),
    ("DDIVu", rrr),
    ("DLSA", [r("V0_64"), r("A0_64"), r("A1_64"), i(1)]),
    ("DMOD", rrr),
    ("DMODu", rrr),
    ("DMUH", rrr),
    ("DMUHu", rrr),
    ("DMUL", rrr),
    ("DMULu", rrr),
    ("DSBH", rr),
    ("DSLL", rri),
    ("DSLL32", rri),
    ("DSLLV", rrr),
    ("DSRA", rri),
    ("DSRA32", rri),
    ("DSRAV", rrr),
    ("DSRL", rri),
    ("DSRL32", rri),
    ("DSRLV", rrr),
    ("DSUB", rrr),
    ("DSUBu", rrr),
    ("J", [i(0x400000)]),
    ("JAL", [i(0x400000)]),
    ("JALR", rr),
    ("JALR.HB", rr),
    ("JALR64", rr),
    ("JIALC", ri),
    ("JIC", ri),
    ("JR", [r("RA_64")]),
    ("LB", mem),
    ("LBE", mem),
    ("LBu", mem),
    ("LBue", mem),
    ("LD", mem),
    ("LDPC", ri),
    ("LH", mem),
    ("LHE", mem),
    ("LHu", mem),
    ("LHue", mem),
    ("LL", mem),
    ("LLD", mem),
    ("LLDX", mem),
    ("LLE", mem),
    ("LLX", mem),
    ("LLXE", mem),
    ("LSA", [r("V0_64"), r("A0_64"), r("A1_64"), i(1)]),
    ("LUi", ri),
    ("LW", mem),
    ("LWE", mem),
    ("LWPC", ri),
    ("LWu", mem),
    ("LWupc", ri),
    ("MOD", rrr),
    ("MODu", rrr),
    ("MUH", rrr),
    ("MUHu", rrr),
    ("MUL", rrr),
    ("MULT", rr),
    ("MULTu", rr),
    ("MULu", rrr),
    ("NAL", []),
    ("NOP", []),
    ("NOR", rrr),
    ("NOT", rr),
    ("OR", rrr),
    ("ORi", rri),
    ("ROTR", rri),
    ("ROTRV", rrr),
    ("SB", mem),
    ("SBE", mem),
    ("SC", mem),
    ("SCD", mem),
    ("SCDX", mem),
    ("SCE", mem),
    ("SCX", mem),
    ("SCXE", mem),
    ("SD", mem),
    ("SDIV", rr),
    ("SEB", rr),
    ("SEH", rr),
    ("SELEQZ", rrr),
    ("SELNEQ", rrr),
    ("SH", mem),
    ("SHE", mem),
    ("SLL", rri),
    ("SLLV", rrr),
    ("SLT", rrr),
    ("SLTi", rri),
    ("SLTiu", rri),
    ("SLTu", rrr),
    ("SRA", rri),
    ("SRAV", rrr),
    ("SRL", rri),
    ("SRLV", rrr),
    ("SUB", rrr),
    ("SUBu", rrr),
    ("SW", mem),
    ("SWE", mem),
    ("UDIV", rr),
    ("WSBH", rr),
    ("XOR", rrr),
    ("XORi", rri),
  ]
}

///|
test "lifter: every opcode lifts to well-typed BIL on every target" {
  @mips.register()
  let names = samples64.map(sample => sample.0)
  names.sort()
  assert_eq(names, @mips.opcodes())
  inspect(
    names.length(),
    content=(
      #|143
    ),
  )
  for sample in samples64 {
    let (name, ops) = sample
    // MIPS32 samples use the plain ABI register names
    let ops32 = ops.map(op => {
      match op {
        Reg(name~, ..) => r(name.replace(old="_64", new=""))
        op => op
      }
    })
    for target in @mips.targets {
      let ops = if target.has_prefix("mips64") { ops } else { ops32 }
      let bil = @mc.lift(target, insn(name, ops))
      for stmt in bil {
        assert_true(stmt.check_type() is Ok(_), msg="\{target} \{name}")
      }
      assert_true(
        bil.length() > 0 || name == "NOP",
        msg="\{target} \{name} produced no BIL",
      )
    }
  }
}

///|
test "lifter: registration" {
  @mips.register()
  @mips.register()
  let targets = @mc.lifter_targets()
  for target in @mips.targets {
    assert_true(targets.contains(target))
  }
  debug_inspect(
    @mips.targets,
    content=(
      #|<ReadOnlyArray: ["mips", "mipsel", "mips64", "mips64el"]>
    ),
  )
  // big and little endian targets differ only in memory accesses
  let lw = insn("LW", [r("T0"), r("SP"), i(0)])
  inspect(
    render(@mc.lift("mips", lw)),
    content=(
      #|T0 := mem[(SP + 0:32u), be]:u32
      #|
    ),
  )
  inspect(
    render(@mc.lift("mipsel", lw)),
    content=(
      #|T0 := mem[(SP + 0:32u), el]:u32
      #|
    ),
  )
}

///|
test "lifter: unmodeled opcodes lift to an empty program" {
  assert_false(@mips.is_supported("LWL"))
  assert_true(@mips.is_supported("LWPC"))
  assert_eq(@mips.lift_mips(insn("LWL", [r("T0"), r("SP"), i(0)])).length(), 0)
  assert_eq(@mips.lift_mips(insn("SDIVR6", [])).length(), 0)
}

///|
test "lifter: operand errors" {
  try @mips.lift_mips(insn("ADDu", [r("T0"), r("T1")])) catch {
    err =>
      inspect(
        err.message(),
        content=(
          #|instruction ADDu doesn't have an operand with index 2
        ),
      )
  } noraise {
    _ => fail("expected a missing operand error")
  }
  try @mips.lift_mips(insn("ADDiu", [r("T0"), r("T1"), r("T2")])) catch {
    err =>
      inspect(
        err.message(),
        content=(
          #|MIPS lifter fail: imm operand expected
        ),
      )
  } noraise {
    _ => fail("expected an immediate operand error")
  }
  try @mips.lift_mips(insn("JR", [i(4)])) catch {
    err =>
      inspect(
        err.message(),
        content=(
          #|MIPS lifter fail: reg operand expected
        ),
      )
  } noraise {
    _ => fail("expected a register operand error")
  }
  try @mips.lift_mips(insn("ADDu", [r("HWR29"), r("T1"), r("T2")])) catch {
    err =>
      inspect(
        err.message(),
        content=(
          #|MIPS lifter fail: unexpected left side of :=
        ),
      )
  } noraise {
    _ => fail("expected an invalid destination error")
  }
}

///|
test "lifter: register names" {
  // unknown source registers read as zero of GPR width; FPRs are 64 bits;
  // numeric aliases resolve to ABI names; `_64` names are MIPS64 only
  inspect(
    show("mips", [
      ("ADDu", [r("V0"), r("HWR29"), r("R8")]),
      ("ADDu", [r("V0"), r("T0_64"), r("F2")]),
    ]),
    content=(
      #|ADDu V0, HWR29, R8
      #|  V0 := (0:32u + T0)
      #|ADDu V0, T0_64, F2
      #|  V0 := pad:32[(pad:64[0:32u] + F2)]
      #|
    ),
  )
  inspect(
    show("mips64", [("ADDu", [r("R2"), r("V0"), r("T0_64")])]),
    content=(
      #|ADDu R2, V0, T0_64
      #|  V0 := (V0 + T0)
      #|
    ),
  )
}

///|
test "lifter: 64-bit addresses and truncation on mips32" {
  let jal = insn("BAL", [r("RA"), i(0x10)], addr=0x1_0000_1000)
  inspect(
    render(@mips.lift_mips(jal)),
    content=(
      #|RA := (0x1000:32u + extend:32[8:8u])
      #|jmp (0x1000:32u + 0x10:32u)
      #|
    ),
  )
  inspect(
    render(@mips.lift_mips64(jal)),
    content=(
      #|RA := (0x100001000:64u + extend:64[8:8u])
      #|jmp (0x100001000:64u + extend:64[0x10:32u])
      #|
    ),
  )
}
