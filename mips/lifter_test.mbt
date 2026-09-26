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
    ("AUI", rri),
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
    // modeled deliberately unlike upstream (see `branch.mbt`,
    // `multiply.mbt`, `divide.mbt`, ...)
    ("AUIPC", ri),
    ("BGEZALL", ri),
    ("BGEZL", ri),
    ("BLEZL", ri),
    ("BLTZ", ri),
    ("BLTZAL", ri),
    ("BLTZALL", ri),
    ("BLTZL", ri),
    ("BNEL", rri),
    ("BC", [i(8)]),
    ("BALC", [i(8)]),
    ("JALX", [i(0x400000)]),
    ("DADD", rrr),
    ("DADDi", rri),
    ("DIV", rrr),
    ("DIVU", rrr),
    ("DSDIV", rr),
    ("DUDIV", rr),
    ("DMULT", rr),
    ("DMULTu", rr),
    ("MADD", rr),
    ("MADDU", rr),
    ("MSUB", rr),
    ("MSUBU", rr),
    ("MFHI", [r("V0_64")]),
    ("MFLO", [r("V0_64")]),
    ("MTHI", [r("V0_64")]),
    ("MTLO", [r("V0_64")]),
    ("MOVZ_I_I", [r("V0_64"), r("A0_64"), r("A1_64"), r("V0_64")]),
    ("MOVN_I_I", [r("V0_64"), r("A0_64"), r("A1_64"), r("V0_64")]),
    ("DROTR", rri),
    ("DROTR32", rri),
    ("DROTRV", rrr),
    ("DSHD", rr),
    ("EXT", [r("V0_64"), r("A0_64"), i(4), i(8)]),
    ("DEXT", [r("V0_64"), r("A0_64"), i(4), i(8)]),
    ("INS", [r("V0_64"), r("A0_64"), i(4), i(8), r("V0_64")]),
    ("DINS", [r("V0_64"), r("A0_64"), i(4), i(8)]),
    ("SSNOP", []),
    ("EHB", []),
    ("PAUSE", []),
    ("SYNC", [i(0)]),
    ("SYNCI", [r("A0_64"), i(0)]),
    ("PREF", [r("A0_64"), i(0), i(0)]),
    ("PREF_R6", [r("A0_64"), i(0), i(0)]),
  ]
}

///|
/// The modeled opcodes without effect on the modeled state.
let no_effect : Array[String] = [
  "NOP", "SSNOP", "EHB", "PAUSE", "SYNC", "SYNCI", "PREF", "PREF_R6",
]

///|
test "lifter: every opcode lifts to well-typed BIL on every target" {
  let names = samples64.map(sample => sample.0)
  names.sort()
  assert_eq(names, @mips.opcodes())
  inspect(
    names.length(),
    content=(
      #|189
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
      let bil = lift_on(target, insn(name, ops))
      for stmt in bil {
        assert_true(stmt.check_type() is Ok(_), msg="\{target} \{name}")
      }
      assert_true(
        bil.length() > 0 || no_effect.contains(name),
        msg="\{target} \{name} produced no BIL",
      )
    }
  }
}

///|
test "lifter: registration" {
  let registry = @mc.Registry::new()
  @mips.register(registry~)
  @mips.register(registry~)
  assert_eq(registry.names(), [@mips.provider_name])
  debug_inspect(
    @mips.targets,
    content=(
      #|<ReadOnlyArray: ["mips", "mipsel", "mips64", "mips64el"]>
    ),
  )
  for target in @mips.targets {
    assert_true(@mips.accepts(@mc.Context::create(target_of(target))))
  }
  // other families and encodings are rejected
  assert_false(@mips.accepts(@mc.Context::create(@core_theory.Target::arm())))
  assert_false(
    @mips.accepts(
      @mc.Context::create(
        @core_theory.Target::mips(),
        encoding=@core_theory.Language::llvm_t32(),
      ),
    ),
  )
  // big and little endian targets differ only in memory accesses
  let lw = insn("LW", [r("T0"), r("SP"), i(0)])
  inspect(
    render(lift_on("mips", lw)),
    content=(
      #|T0 := mem[(SP + 0:32u), be]:u32
      #|
    ),
  )
  inspect(
    render(lift_on("mipsel", lw)),
    content=(
      #|T0 := mem[(SP + 0:32u), el]:u32
      #|
    ),
  )
}

///|
test "lifter: provider reports unmodeled opcodes and delay slots" {
  let ctx = @mc.Context::create(@core_theory.Target::mips())
  // the raw lifter answers an empty program, the provider `Unsupported`
  let lwl = insn("LWL", [r("T0"), r("SP"), i(0)])
  assert_eq(@mips.lift_mips(lwl).length(), 0)
  try @mips.provider().lift(ctx, lwl) catch {
    err => assert_true(err is Unsupported(opcode="LWL", ..))
  } noraise {
    _ => fail("expected unsupported instruction")
  }
  // NOP is modeled and lifts to an empty program
  let nop = @mips.provider().lift(ctx, insn("NOP", []))
  assert_eq(nop, @mc.Lifted::of_bil([]))
  // branches have one delay slot, other instructions none
  let beq = @mips.provider().lift(ctx, insn("BEQ", [r("T0"), r("T1"), i(8)]))
  assert_eq(beq.delay, 1)
  assert_eq(beq.dest_encoding, None)
  let addiu = @mips.provider().lift(
    ctx,
    insn("ADDiu", [r("T0"), r("T0"), i(1)]),
  )
  assert_eq(addiu.delay, 0)
  // a bi-endian target takes the byte order from the encoding
  let bi = @mc.Context::create(
    @core_theory.Target::mipsbi(),
    encoding=@core_theory.Language::llvm_mips32le(),
  )
  assert_true(@mips.mode_of_context(bi) is (Mips32, LittleEndian))
  assert_true(
    @mips.mode_of_context(@mc.Context::create(@core_theory.Target::mips64()))
    is (Mips64, BigEndian),
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
  // unknown registers and the zero register read as zero, and writes to
  // them are discarded (deliberately unlike upstream for `ZERO`)
  assert_eq(
    @mips.lift_mips(insn("ADDu", [r("HWR29"), r("T1"), r("T2")])).length(),
    0,
  )
  assert_eq(
    @mips.lift_mips(insn("ADDu", [r("ZERO"), r("T1"), r("T2")])).length(),
    0,
  )
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
      #|  V0 := (0:32u + extract:31:0[F2])
      #|
    ),
  )
  inspect(
    show("mips64", [("ADDu", [r("R2"), r("V0"), r("T0_64")])]),
    content=(
      #|ADDu R2, V0, T0_64
      #|  V0 := extend:64[(extract:31:0[V0] + extract:31:0[T0])]
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
