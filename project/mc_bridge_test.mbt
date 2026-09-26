///|
fn bridge_insn(
  addr : UInt64,
  name : String,
  operands : Array[@project.ProjectInstructionOperand],
  size? : Int = 4,
  encoding? : String = "llvm",
) -> @project.ProjectDisassemblyInstruction {
  let bytes = Bytes::make(size, b'\x00')
  let mem = @memory.Memory::from_bytes(endian=BigEndian, start=addr, bytes)
  @project.ProjectDisassemblyInstruction::create(
    mem,
    name~,
    encoding~,
    operands~,
  )
}

///|
fn bridge_reg(name : String) -> @project.ProjectInstructionOperand {
  @project.ProjectInstructionOperand::register(name~, code=0)
}

///|
fn bridge_imm(value : Int64) -> @project.ProjectInstructionOperand {
  @project.ProjectInstructionOperand::immediate(value)
}

///|
/// A project for `target` whose disassembly has one block holding
/// `instructions` (and no edges).
fn bridge_project(
  target : @core_theory.Target,
  instructions : Array[@project.ProjectDisassemblyInstruction],
) -> @project.Project {
  let start = instructions[0].addr()
  let size = instructions.fold(init=0, (n, insn) => n + insn.memory().length())
  let block = @memory.Memory::from_bytes(
    endian=BigEndian,
    start~,
    Bytes::make(size, b'\x00'),
  )
  let disassembly = @project.ProjectDisassemblyState::create(
    blocks=[block],
    instructions~,
  )
  @project.Project::empty(target).with_disassembly(disassembly)
}

///|
fn bridge_stmts(stmts : Array[@types.Stmt]) -> String {
  stmts.map(s => s.to_string()).join("\n")
}

///|
test "project instruction converts to mc insn" {
  let mem = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x400UL,
    b"\x01\x02\x03\x04",
  )
  let insn = @project.ProjectDisassemblyInstruction::create(
    mem,
    name="ADDiu",
    code=17,
    encoding="llvm-mips32le",
    kinds=[ProjectMayLoad],
    assembly="addiu $t0, $t1, 4",
    operands=[
      @project.ProjectInstructionOperand::register(name="T0", code=9),
      @project.ProjectInstructionOperand::register(name="T1", code=10),
      @project.ProjectInstructionOperand::immediate(4),
    ],
  )
  let mc = insn.to_mc_insn()
  assert_eq(mc.name, "ADDiu")
  assert_eq(mc.addr, 0x400UL)
  assert_eq(mc.size, 4)
  assert_eq(mc.code, 17)
  assert_eq(mc.encoding, @core_theory.Language::llvm_mips32le())
  assert_eq(mc.kinds[:].to_owned(), [@mc.MayLoad])
  assert_eq(mc.raw, b"\x01\x02\x03\x04")
  assert_eq(mc.ops[:].to_owned(), [
    @mc.Reg(name="T0", code=9),
    @mc.Reg(name="T1", code=10),
    @mc.Imm(4),
  ])
  // generic decoder tags are not encodings: the target decides
  let generic = bridge_insn(0x400, "ADDiu", [])
  assert_true(generic.encoding_language().is_unknown())
  assert_eq(
    generic.lift_context(@core_theory.Target::mipsel()).encoding(),
    @core_theory.Language::llvm_mips32le(),
  )
  // kinds round-trip
  for
    kind in [
      @project.ProjectConditionalBranch,
      ProjectUnconditionalBranch,
      ProjectIndirectBranch,
      ProjectReturn,
      ProjectCall,
      ProjectBarrier,
      ProjectTerminator,
      ProjectMayAffectControlFlow,
      ProjectMayLoad,
      ProjectMayStore,
    ] {
    assert_eq(
      @project.ProjectInstructionKind::of_mc_kind(kind.to_mc_kind()),
      kind,
    )
  }
}

///|
test "project instruction lift dispatches to providers and falls back to Basic" {
  let mips = @core_theory.Target::mips()
  let addiu = bridge_insn(0x1000, "ADDiu", [
    bridge_reg("T0"),
    bridge_reg("T1"),
    bridge_imm(4),
  ])
  // the built-in MIPS provider (global registry) lifts ADDiu
  match addiu.lift(target=mips) {
    Ok(lifted) => {
      inspect(
        bridge_stmts(lifted.bil()),
        content="T0:imm32 := (T1:imm32 + 4:32u)",
      )
      assert_eq(lifted.delay(), 0)
    }
    Err(reason) => fail(reason)
  }
  // a custom registry without providers falls back to the Basic lifter,
  // which does not model ADDiu
  let empty = @mc.Registry::new()
  assert_eq(
    addiu.lift(target=mips, registry=empty),
    Err("unsupported Basic BIL lift for instruction ADDIU"),
  )
  // an opcode the MIPS provider does not model falls back to Basic too
  let ret = bridge_insn(0x1004, "RET", [])
  assert_eq(
    ret.lift(target=mips),
    Ok(@mc.Lifted::of_bil([@types.Stmt::special("ret")])),
  )
  // errors other than `Unsupported` are reported, not replaced by Basic
  let broken = bridge_insn(0x1008, "ADDu", [bridge_reg("T0"), bridge_reg("T1")])
  assert_eq(
    broken.lift(target=mips),
    Err("instruction ADDu doesn't have an operand with index 2"),
  )
  // a registry-provided lifter wins over Basic
  let custom = @mc.Registry::new()
  custom.register(
    @mc.Provider::create("custom", accepts=_ => true, lift=(_, insn) => {
      guard insn.name == "RET" else {
        raise @mc.Unsupported(opcode=insn.name, target="custom")
      }
      @mc.Lifted::of_bil([@types.Stmt::special("custom-ret")])
    }),
  )
  assert_eq(
    ret.lift(target=mips, registry=custom),
    Ok(@mc.Lifted::of_bil([@types.Stmt::special("custom-ret")])),
  )
}

///|
test "project instruction lift uses the instruction encoding" {
  // a Thumb-encoded instruction of an ARM target goes to the Thumb provider
  let blx = bridge_insn(
    0x2000,
    "tBLXi",
    [bridge_imm(14), bridge_reg("CPSR"), bridge_imm(0x100)],
    encoding="llvm-thumb",
  )
  match blx.lift(target=@core_theory.Target::arm()) {
    Ok(lifted) =>
      assert_eq(lifted.dest_encoding(), Some(@core_theory.Language::llvm_a32()))
    Err(reason) => fail(reason)
  }
  // Thumb-2 opcodes fall through to the ARM provider
  let t2 = bridge_insn(
    0x2004,
    "t2MOVr",
    [
      bridge_reg("R0"),
      bridge_reg("R1"),
      bridge_imm(14),
      bridge_reg("Nil"),
      bridge_reg("Nil"),
    ],
    encoding="llvm-thumb",
  )
  match t2.lift(target=@core_theory.Target::arm()) {
    Ok(lifted) =>
      inspect(bridge_stmts(lifted.bil()), content="R0:imm32 := R1:imm32")
    Err(reason) => fail(reason)
  }
}

///|
test "builtin lifters are registered in a deterministic order" {
  let registry = @mc.Registry::new()
  @project.register_builtin_lifters(registry~)
  @project.register_builtin_lifters(registry~)
  assert_eq(registry.names(), ["thumb", "arm", "mips", "powerpc", "systemz"])
  @project.register_builtin_lifters()
  let global = @mc.Registry::global().names()
  for name in ["thumb", "arm", "mips", "powerpc", "systemz"] {
    assert_true(global.contains(name))
  }
}

///|
test "block lifting places delayed jumps after the delay slot" {
  let mips = @core_theory.Target::mips()
  // beq t0, t1, 0x20 ; addiu t0, t0, 1 (delay slot writes the tested t0)
  let beq = bridge_insn(0x1000, "BEQ", [
    bridge_reg("T0"),
    bridge_reg("T1"),
    bridge_imm(0x20),
  ])
  let addiu = bridge_insn(0x1004, "ADDiu", [
    bridge_reg("T0"),
    bridge_reg("T0"),
    bridge_imm(1),
  ])
  let project = bridge_project(mips, [beq, addiu])
  match project.lift() {
    Ok(stmts) =>
      inspect(
        bridge_stmts(stmts),
        content=(
          #|%delay_slot_1000_0:imm1 := (T0:imm32 == T1:imm32)
          #|T0:imm32 := (T0:imm32 + 1:32u)
          #|if %delay_slot_1000_0:imm1 then 1 stmts else 0 stmts
        ),
      )
    Err(reason) => fail(reason)
  }
  // a delay slot that does not touch the branch operands needs no copy
  let addiu_t2 = bridge_insn(0x1004, "ADDiu", [
    bridge_reg("T2"),
    bridge_reg("T2"),
    bridge_imm(1),
  ])
  match bridge_project(mips, [beq, addiu_t2]).lift() {
    Ok(stmts) =>
      inspect(
        bridge_stmts(stmts),
        content=(
          #|T2:imm32 := (T2:imm32 + 1:32u)
          #|if (T0:imm32 == T1:imm32) then 1 stmts else 0 stmts
        ),
      )
    Err(reason) => fail(reason)
  }
}

///|
test "reconstruction uses registered lifters and delay slots on MIPS" {
  let mips = @core_theory.Target::mips()
  // addiu a0, zero, 5 ; beq a0, v0, 0x20 ; addiu a0, a0, 1 (delay slot)
  let li = bridge_insn(0x1000, "ADDiu", [
    bridge_reg("A0"),
    bridge_reg("ZERO"),
    bridge_imm(5),
  ])
  let beq = bridge_insn(0x1004, "BEQ", [
    bridge_reg("A0"),
    bridge_reg("V0"),
    bridge_imm(0x20),
  ])
  let inc = bridge_insn(0x1008, "ADDiu", [
    bridge_reg("A0"),
    bridge_reg("A0"),
    bridge_imm(1),
  ])
  match bridge_project(mips, [li, beq, inc]).reconstruct() {
    Ok(reconstructed) => {
      let blk = reconstructed.program().subs()[0].blks()[0]
      // the branch condition is captured before the delay slot, whose
      // definition precedes the jump
      inspect(
        blk.defs().map(def => @types.Def::to_string(def)).join("\n"),
        content=(
          #|A0:imm32 := (ZERO:imm32 + 5:32u)
          #|%delay_slot_1004_0:imm1 := (A0:imm32 == V0:imm32)
          #|A0:imm32 := (A0:imm32 + 1:32u)
        ),
      )
      inspect(
        blk.jmps().map(jmp => @types.Jmp::to_string(jmp)).join("\n"),
        content=(
          #|when %delay_slot_1004_0:imm1 goto @0x00001024
        ),
      )
      assert_eq(reconstructed.lift_errors(), [])
    }
    Err(reason) => fail(reason)
  }
  // jal 0x400000 ; addiu a0, zero, 5 (argument set up in the delay slot)
  let jal = bridge_insn(0x2000, "JAL", [bridge_imm(0x400000)])
  let arg = bridge_insn(0x2004, "ADDiu", [
    bridge_reg("A0"),
    bridge_reg("ZERO"),
    bridge_imm(5),
  ])
  match bridge_project(mips, [jal, arg]).lift() {
    Ok(stmts) =>
      inspect(
        bridge_stmts(stmts),
        content=(
          #|RA:imm32 := (0x2000:32u + extend:32[8:8u])
          #|A0:imm32 := (ZERO:imm32 + 5:32u)
          #|jmp 0x400000:32u
        ),
      )
    Err(reason) => fail(reason)
  }
}

///|
test "reconstruction uses registered lifters on PowerPC and retains lift errors" {
  let ppc = @core_theory.Target::powerpc()
  let add = bridge_insn(0x2000, "ADD4", [
    bridge_reg("R3"),
    bridge_reg("R4"),
    bridge_reg("R5"),
  ])
  let unknown = bridge_insn(0x2004, "FADD", [])
  let subf = bridge_insn(0x2008, "SUBF", [
    bridge_reg("R6"),
    bridge_reg("R3"),
    bridge_reg("R4"),
  ])
  let project = bridge_project(ppc, [add, unknown, subf])
  assert_true(project.lift_errors().is_empty())
  match project.reconstruct() {
    Ok(reconstructed) => {
      let blk = reconstructed.program().subs()[0].blks()[0]
      // the instructions around the failing one are still lifted
      inspect(
        blk.defs().map(def => @types.Def::to_string(def)).join("\n"),
        content=(
          #|R3:imm32 := (R4:imm32 + R5:imm32)
          #|R6:imm32 := (((not R3:imm32) + R4:imm32) + pad:32[1:1u])
        ),
      )
      debug_inspect(
        reconstructed.lift_errors(),
        content=(
          #|[
          #|  {
          #|    addr: 8196,
          #|    opcode: "FADD",
          #|    message: "unsupported Basic BIL lift for instruction FADD",
          #|  },
          #|]
        ),
      )
      assert_eq(
        reconstructed.lift_errors()[0].to_string(),
        "FADD at 0x2004: unsupported Basic BIL lift for instruction FADD",
      )
    }
    Err(reason) => fail(reason)
  }
  // strict lifting reports the first failure
  assert_true(project.lift() is Err(_))
  assert_eq(project.disassembly().lift_errors(target=ppc).length(), 1)
}
