// Registry, model, RTL/DSL and ABI tests.

///|
test "register with mc" {
  @powerpc.register()
  @powerpc.register()
  let targets = @mc.lifter_targets()
  assert_true(targets.contains("ppc"))
  assert_true(targets.contains("ppc64"))
  assert_true(targets.contains("ppc64le"))
  let insn = @mc.Insn::create("ADD4", [reg("R11"), reg("R2"), reg("R11")])
  inspect(
    @mc.lift("ppc", insn).map(s => s.to_string()).join("\n"),
    content="R11:imm32 := (R2:imm32 + R11:imm32)",
  )
  inspect(
    @mc.lift("ppc64", insn).map(s => s.to_string()).join("\n"),
    content="R11:imm64 := (R2:imm64 + R11:imm64)",
  )
}

///|
test "unsupported and malformed instructions" {
  try @powerpc.lift32(@mc.Insn::create("FADD", [])) catch {
    err => assert_true(err is Unsupported("FADD"))
  } noraise {
    _ => fail("expected an unsupported instruction")
  }
  try @powerpc.lift32(@mc.Insn::create("ADD4", [reg("R1")])) catch {
    err => assert_true(err is BadOperands("ADD4"))
  } noraise {
    _ => fail("expected bad operands")
  }
  try
    @powerpc.lift32(@mc.Insn::create("ADDI", [reg("R1"), reg("R1"), reg("R2")]))
  catch {
    err => assert_true(err is Failure(_))
  } noraise {
    _ => fail("expected an imm operand failure")
  }
  try
    @powerpc.lift32(@mc.Insn::create("ADD4", [imm(1), reg("R1"), reg("R2")]))
  catch {
    err => assert_true(err is Failure(_))
  } noraise {
    _ => fail("expected a reg operand failure")
  }
}

///|
test "supported instructions" {
  let names = @powerpc.supported_insns()
  inspect(
    names.length(),
    content=(
      #|296
    ),
  )
  // record forms are registered under both LLVM spellings
  assert_true(names.contains("ADD4o") && names.contains("ADD4_rec"))
  assert_true(names.contains("ANDIo") && names.contains("ANDI_rec"))
  assert_true(@powerpc.find_insn_lifter("gBCTARL") is Some(_))
  assert_true(@powerpc.find_insn_lifter("XYZ") is None)
}

///|
test "custom lifters can be registered" {
  @powerpc.register_insn(
    "TEST_NOP_PPC",
    @powerpc.infallible((_, _) => [@powerpc.message("test")]),
  )
  let bil = @powerpc.lift32(@mc.Insn::create("TEST_NOP_PPC", []))
  inspect(
    bil.map(s => s.to_string()).join("\n"),
    content=(
      #|special test
    ),
  )
}

///|
test "model registers" {
  let m32 = @powerpc.Model::ppc32()
  let m64 = @powerpc.Model::ppc64()
  assert_eq(m32.gpr_bitwidth, 32)
  assert_eq(m64.gpr_bitwidth, 64)
  assert_eq(m64.gpr["X3"], m64.gpri[3])
  assert_eq(m64.gpr["R3"].typ, Imm(64))
  assert_eq(m32.fpri[31].name, "F31")
  assert_eq(m32.vri[0].typ, Imm(128))
  inspect(
    m32.cri[:5].map(v => v.name).join(" "),
    content="CR0LT CR0GT CR0EQ CR0UN CR1LT",
  )
  inspect(m32.cri[31].name, content="CR7UN")
  inspect(
    m32.cr_fields["CR7"].map(v => v.name).join(" "),
    content="CR7LT CR7GT CR7EQ CR7UN",
  )
  assert_eq(m32.crn["CR3EQ"], m32.cri[14])
  assert_eq(m32.mem.typ, Mem(addr_width=32, value_width=8))
  assert_eq(m64.mem.typ, Mem(addr_width=64, value_width=8))
  inspect(
    m32.flags.map(v => v.name).join(" "),
    content="SO CA CA32 OV OV32 CR0LT CR0GT CR0EQ",
  )
  assert_true(m32.is_sp(m32.gpri[1]))
  assert_true(m32.is_reg(m32.gpri[7]))
  assert_true(!m32.is_reg(m32.ctr))
  assert_true(m32.is_flag(m32.ca))
  assert_true(m32.is_cf(m32.ca) && m32.is_vf(m32.ov))
  assert_true(m32.is_nf(m32.cri[0]) && m32.is_zf(m32.cri[1]))
  assert_true(m32.is_mem(m32.mem) && !m32.is_bp(m32.gpri[31]))
  assert_eq(m64.lr.typ, Imm(64))
  assert_eq(m32.float_unordered.name, "FU")
}

///|
test "cpu view" {
  let cpu = @powerpc.Cpu::create(R64, BigEndian, 0x1000)
  assert_eq(cpu.word_width, 64)
  assert_eq(cpu.cr.width(), 32)
  assert_eq(cpu.cr7.width(), 4)
  assert_eq(cpu.pc.sign(), Signed)
  inspect(
    cpu.pc.to_bil().to_string(),
    content=(
      #|0x1000:64u
    ),
  )
  inspect(
    cpu.find_reg("ZERO8").to_bil().to_string(),
    content=(
      #|0:64u
    ),
  )
  inspect(cpu.find_reg("F1").to_bil().to_string(), content="F1:imm64")
  inspect(cpu.find_reg("VR2").to_bil().to_string(), content="VR2:imm128")
  inspect(cpu.gpr(3).to_bil().to_string(), content="R3:imm64")
  inspect(cpu.fpr(3).to_bil().to_string(), content="F3:imm64")
  inspect(cpu.vr(3).to_bil().to_string(), content="VR3:imm128")
  try cpu.gpr(32) catch {
    err => assert_true(err is Failure(_))
  } noraise {
    _ => fail("expected a missing register")
  }
}

///|
test "little endian loads" {
  let insn = @mc.Insn::create("LWZ", [reg("R9"), imm(4), reg("R1")])
  let endian_of = (bil : Array[@types.Stmt]) => {
    match @types.find_exp(bil, e => e is Load(..)) {
      Some(Load(endian~, ..)) => Some(endian)
      _ => None
    }
  }
  assert_eq(endian_of(@powerpc.lift64le(insn)), Some(LittleEndian))
  assert_eq(endian_of(@powerpc.lift64(insn)), Some(BigEndian))
  assert_eq(endian_of(@powerpc.lift32(insn)), Some(BigEndian))
  inspect(
    @powerpc.lift64(insn).map(s => s.to_string()).join("\n"),
    content=(
      #|R9:imm64 := pad:64[load(mem:mem64x8, (R1:imm64 + extend:64[4:32u])):imm32]
    ),
  )
}

///|
test "rtl expressions: widths and signedness" {
  let a = @powerpc.uvar(32)
  let b = @powerpc.svar(64)
  let sum = a + b
  assert_eq(sum.width(), 64)
  assert_eq(sum.sign(), Signed)
  assert_eq(a.lt(b).width(), 1)
  assert_eq((a & b).sign(), Unsigned)
  assert_eq(a.concat(b).width(), 96)
  assert_eq(b.low(@powerpc.word).width(), 32)
  assert_eq(b.low(@powerpc.word).sign(), Unsigned)
  assert_eq(b.nth(@powerpc.byte, 0).width(), 8)
  assert_eq(b.bits(0, 3).width(), 4)
  // extracting more bits than available zero-extends
  assert_eq(@powerpc.uvar(4).bits(0, 7).width(), 8)
  inspect(b.width_exp().to_bil().to_string(), content="0x40:64u")
  inspect(@powerpc.ones(8).to_bil().to_string(), content="0xFF:8u")
  inspect(@powerpc.sconst(8, -1).to_bil().to_string(), content="0xFF:8u")
}

///|
test "rtl: extraction from concatenated registers yields registers" {
  let cpu = @powerpc.Cpu::create(R32, BigEndian, 0)
  let lt = cpu.cr.nth(@powerpc.bit, 0)
  inspect(
    lt.to_bil().to_string(),
    content=(
      #|CR0LT:imm1
    ),
  )
  let field = cpu.cr.nth(4, 7)
  inspect(
    field.to_bil().to_string(),
    content=(
      #|concat(concat(concat(CR7LT:imm1, CR7GT:imm1), CR7EQ:imm1), CR7UN:imm1)
    ),
  )
  inspect(
    cpu.cr1.msb().to_bil().to_string(),
    content=(
      #|CR1LT:imm1
    ),
  )
}

///|
test "rtl: assignments to parts of registers" {
  let x = @powerpc.Cpu::create(R32, BigEndian, 0).gpr(3)
  let bil = @powerpc.bil_of_rtl([
    x.high(16).set(@powerpc.uconst(16, 0xABCD)),
    x.extract(15, 8).set(@powerpc.uconst(8, 0x12)),
  ])
  inspect(
    bil.map(s => s.to_string()).join("\n"),
    content=(
      #|R3:imm32 := concat(0xABCD:16u, extract[15:0](R3:imm32))
      #|R3:imm32 := concat(extract[31:16](R3:imm32), concat(0x12:8u, extract[7:0](R3:imm32)))
    ),
  )
  @powerpc.register_insn("TEST_ASSIGN_PPC", (cpu, _) => {
    let x = cpu.gpr(3)
    [
      x.high(16).set(@powerpc.uconst(16, 0xABCD)),
      x.extract(15, 8).set(@powerpc.uconst(8, 0x12)),
    ]
  })
  let r = run(R32, "TEST_ASSIGN_PPC", [], init=[("R3", 0x1111_1111)])
  r.check("R3", 0xABCD_1211)
}

///|
test "rtl: switch and foreach" {
  @powerpc.register_insn("TEST_SWITCH_PPC", (cpu, ops) => {
    let x = cpu.ureg(ops, 0)
    let out = cpu.gpr(4)
    let nibble = @powerpc.uvar(4)
    let count = @powerpc.uvar(8)
    [
      @powerpc.switch_(x, [
        @powerpc.case(@powerpc.uconst(32, 1), [out.set(@powerpc.uconst(32, 10))]),
        @powerpc.case(@powerpc.uconst(32, 2), [out.set(@powerpc.uconst(32, 20))]),
        @powerpc.default([out.set(@powerpc.uconst(32, 99))]),
      ]),
      // count non-zero nibbles of x, least significant first
      count.set(@powerpc.zero),
      @powerpc.foreach_from(inverse=false, nibble, x, [
        @powerpc.when_(nibble.neq(@powerpc.zero), [
          count.set(count + @powerpc.one),
        ]),
      ]),
      cpu.gpr(5).set(count),
      @powerpc.ifnot(x.eq(@powerpc.zero), [cpu.gpr(6).set(@powerpc.one)]),
    ]
  })
  let r = run(R32, "TEST_SWITCH_PPC", [reg("R3")], init=[("R3", 2)])
  r.check("R4", 20)
  r.check("R5", 1)
  r.check("R6", 1)
  let r = run(R32, "TEST_SWITCH_PPC", [reg("R3")], init=[("R3", 0x0102_0000)])
  r.check("R4", 99)
  r.check("R5", 2)
  let r = run(R32, "TEST_SWITCH_PPC", [reg("R3")], init=[("R3", 0)])
  r.check("R4", 99)
  r.check("R5", 0)
  r.check("R6", 0)
  try @powerpc.switch_(@powerpc.zero, [@powerpc.default([])]) catch {
    err => assert_true(err is Failure(_))
  } noraise {
    _ => fail("expected an empty switch failure")
  }
}

///|
test "dsl: of_string" {
  let show = (s : String) => {
    @powerpc.of_string(s, Unsigned).to_bil().to_string()
  }
  inspect(
    show("0xFFFF_FFFF_FFFF"),
    content=(
      #|0xFFFFFFFFFFFF:48u
    ),
  )
  inspect(
    show("0o474"),
    content=(
      #|0x13C:9u
    ),
  )
  inspect(
    show("0b00"),
    content=(
      #|0:2u
    ),
  )
  inspect(show("0b03FA") catch { _ => "error" }, content="error")
  inspect(
    show("42"),
    content=(
      #|0x2A:6u
    ),
  )
  inspect(
    show("1"),
    content=(
      #|1:1u
    ),
  )
  assert_eq(@powerpc.of_string("0x03FA", Signed).sign(), Signed)
  assert_eq(@powerpc.of_string("0x03FA", Signed).width(), 16)
}

///|
test "abi: sysv32" {
  let abi = @powerpc.Sysv32Abi::new()
  inspect(abi.int_args.join(" "), content="R3 R4 R5 R6 R7 R8 R9 R10")
  inspect(abi.float_args.join(" "), content="F1 F2 F3 F4 F5 F6 F7 F8")
  let layout = abi.layout(
    [Integral(32), Floating(64), Integral(64)],
    ret=Integral(64),
  )
  debug_inspect(
    layout,
    content=(
      #|{
      #|  args: [Pointer("R3"), Registers(["F1"]), Pointer("R4")],
      #|  ret: Some(Registers(["R3", "R4"])),
      #|}
    ),
  )
  // large return values are returned through a hidden reference, which
  // takes the first argument register
  let layout = abi.layout([Integral(32)], ret=Integral(128))
  debug_inspect(
    layout,
    content=(
      #|{ args: [Pointer("R4")], ret: Some(Reference("R3")) }
    ),
  )
  let layout = abi.layout([], ret=Integral(64), little_endian=true)
  debug_inspect(
    layout,
    content=(
      #|{ args: [], ret: Some(Registers(["R4", "R3"])) }
    ),
  )
  // floating arguments spill to memory once F1..F8 are used
  let args = Array::make(9, @powerpc.AbiValue::Floating(64))
  let layout = abi.layout(args, ret=Floating(64))
  assert_eq(layout.args[8], Memory)
  assert_eq(layout.ret, Some(Registers(["F0"])))
}
