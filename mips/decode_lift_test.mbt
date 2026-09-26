// End-to-end tests: machine code decoded by the native decoder, lifted by
// the MIPS lifter and executed by the BIL interpreter, with the branch
// delay slots of `delay_slot`.

///|
/// Execute the top-level statements `stmts` of one instruction from
/// `state`; returns the new state and the target of the jump taken, if any.
fn step(
  stmts : Array[@types.Stmt],
  state : @types.BilState,
) -> (@types.BilState, UInt64?) raise {
  let mut state = state
  let mut target : UInt64? = None
  for stmt in stmts {
    match stmt {
      Jmp(dst) =>
        match dst.eval_value(state.values()) {
          Ok(BilWord(w)) => target = Some(w.to_uint64())
          _ => fail("bad jump target")
        }
      If(cond~, yes~, no~) =>
        match cond.eval_value(state.values()) {
          Ok(BilWord(w)) => {
            let (next, taken) = step(if w.is_zero() { no } else { yes }, state)
            state = next
            if taken is Some(_) {
              target = taken
            }
          }
          _ => fail("bad condition")
        }
      _ =>
        match @types.exec_stmts([stmt], state~) {
          Ok(next) => state = next
          Err(msg) => fail(msg)
        }
    }
  }
  (state, target)
}

///|
/// Run the big-endian MIPS32 `program` loaded at `base` from `state` until
/// control leaves it; returns the final state and the address control left
/// to. Delayed branches execute the instruction in their delay slot before
/// the jump takes effect.
fn run_program(
  program : Array[UInt],
  base : UInt64,
  state : @types.BilState,
  arch? : @mips.Arch = Mips32,
  endian? : @bitvec.Endian = BigEndian,
) -> (@types.BilState, UInt64) raise {
  let code = Bytes::makei(program.length() * 4, i => {
    let word = program[i / 4]
    let shift = match endian {
      BigEndian => 24 - 8 * (i % 4)
      LittleEndian => 8 * (i % 4)
    }
    (word >> shift).to_byte()
  })
  let lift = (pc : UInt64) => {
    let offset = (pc - base).to_int()
    guard @mips.decode(code[offset:offset + 4], pc, arch~, endian~)
      is Some(insn) else {
      fail("invalid instruction at 0x\{pc.to_string(radix=16)}")
    }
    (insn, @mips.lift_checked(insn, arch~, endian~))
  }
  let limit = base + (program.length() * 4).to_uint64()
  let mut state = state
  let mut pc = base
  let mut steps = 0
  while pc >= base && pc < limit {
    steps += 1
    if steps > 1000 {
      fail("too many steps")
    }
    let (insn, bil) = lift(pc)
    let (next, target) = step(bil, state)
    state = next
    match @mips.delay_slot(insn.name) {
      Some(1) => {
        let (_, slot) = lift(pc + 4)
        let (after, _) = step(slot, state)
        state = after
        pc = target.unwrap_or(pc + 8)
      }
      _ => pc = target.unwrap_or(pc + 4)
    }
  }
  (state, pc)
}

///|
fn word32(value : Int64) -> @types.BilValue raise {
  BilWord(@types.Word::of_int64(value, width=32))
}

///|
fn show_regs(state : @types.BilState, names : Array[String]) -> String {
  names
  .map(name => {
    match state.get_word(name) {
      Some(w) => "\{name}=\{w.to_string()}"
      None => "\{name}=<unset>"
    }
  })
  .join(" ")
}

///|
test "decode, lift and run a counting loop with a filled delay slot" {
  let program : Array[UInt] = [
    0x24020000, // 0x400000: addiu $v0, $zero, 0
     0x24040005, // 0x400004: addiu $a0, $zero, 5
     0x00441021, // 0x400008: addu $v0, $v0, $a0
     0x2484ffff, // 0x40000c: addiu $a0, $a0, -1
     0x1480fffd, // 0x400010: bnez $a0, 0x400008
     0x24630001, // 0x400014: addiu $v1, $v1, 1 (delay slot)
     0x03e00008, // 0x400018: jr $ra
     0x00000000, // 0x40001c: nop (delay slot)
  ]
  let state = @types.BilState::new()
    .set("ZERO", word32(0))
    .set("V1", word32(0))
    .set("RA", word32(0x400100))
  let (state, exit) = run_program(program, 0x400000UL, state)
  assert_eq(exit, 0x400100UL)
  inspect(
    show_regs(state, ["V0", "V1", "A0"]),
    content="V0=0xF:32u V1=5:32u A0=0:32u",
  )
}

///|
test "decode, lift and run a little-endian stack frame" {
  let program : Array[UInt] = [
    0x27bdffe0, // addiu $sp, $sp, -32
     0xafbf001c, // sw $ra, 28($sp)
     0x3c051234, // lui $a1, 0x1234
     0x34a55678, // ori $a1, $a1, 0x5678
     0xafa50010, // sw $a1, 16($sp)
     0x83a60010, // lb $a2, 16($sp) (the low byte, little endian)
     0x97a70012, // lhu $a3, 18($sp)
     0x0005c023, // negu $t8, $a1
     0x00a0c827, // not $t9, $a1
     0x8fbf001c, // lw $ra, 28($sp)
     0x03e00008, // jr $ra
     0x27bd0020, // addiu $sp, $sp, 32 (delay slot)
  ]
  let mem = @types.BilMemory::empty(addr_width=32)
  let state = @types.BilState::new()
    .set("ZERO", word32(0))
    .set("SP", word32(0x7fff0000))
    .set("RA", word32(0x400800))
    .set("mem", BilMem(mem))
  let (state, exit) = run_program(
    program,
    0x400000UL,
    state,
    endian=LittleEndian,
  )
  assert_eq(exit, 0x400800UL)
  inspect(
    show_regs(state, ["SP", "A1", "A2", "A3", "T8", "T9"]),
    content="SP=0x7FFF0000:32u A1=0x12345678:32u A2=0x78:32u A3=0x1234:32u T8=0xEDCBA988:32u T9=0xEDCBA987:32u",
  )
}

///|
test "decode, lift and run a MIPS64 call through $t9" {
  let program : Array[UInt] = [
    0x67bdfff0, // 0x120000000: daddiu $sp, $sp, -16
     0xffbf0008, // sd $ra, 8($sp)
     0x0320f809, // jalr $t9 (to 0x120000020)
     0x24040003, // addiu $a0, $zero, 3 (delay slot)
     0xdfbf0008, // 0x120000010: ld $ra, 8($sp)
     0x03e00008, // jr $ra
     0x67bd0010, // daddiu $sp, $sp, 16 (delay slot)
     0x00000000, // nop
     0x0004102d, // 0x120000020: move $v0, $a0 (daddu $v0, $a0, $zero)
     0x00021078, // dsll $v0, $v0, 1
     0x03e00008, // jr $ra
     0x00000000, // nop
  ]
  let word64 = (v : Int64) => {
    @types.BilValue::BilWord(@types.Word::of_int64(v, width=64))
  }
  let state = @types.BilState::new()
    .set("ZERO", word64(0L))
    .set("SP", word64(0x7fff0000L))
    .set("RA", word64(0x120001000L))
    .set("T9", word64(0x120000020L))
    .set("mem", BilMem(@types.BilMemory::empty(addr_width=64)))
  let (state, exit) = run_program(program, 0x120000000UL, state, arch=Mips64)
  assert_eq(exit, 0x120001000UL)
  inspect(
    show_regs(state, ["V0", "A0", "SP", "RA"]),
    content="V0=6:64u A0=3:64u SP=0x7FFF0000:64u RA=0x120001000:64u",
  )
}

///|
test "every decoded sample of a modeled opcode lifts to well-typed BIL" {
  let lifted : Map[String, Unit] = Map([])
  for sample in llvm_samples {
    let (arch, r6, word, _) = sample
    guard @mips.decode(be_bytes(word), 0x1000UL, arch~, r6~) is Some(insn) else {
      fail("not decoded")
    }
    if @mips.is_supported(insn.name) {
      @mips.lift_checked(insn, arch~, endian=BigEndian) |> ignore
      lifted[insn.name] = ()
    }
  }
  // the modeled opcodes that no sample decodes to (directly or through an
  // LLVM alias): upstream spellings that LLVM never produces
  let aliases = @mips.opcode_aliases()
  let reached = (name : String) => {
    lifted.contains(name) ||
    aliases.iter().any(a => a.1 == name && lifted.contains(a.0))
  }
  inspect(
    @mips.opcodes().filter(name => !reached(name)).join(" "),
    content=(
      #|LBE LHE LLE LLX LWE NOP NOT SBE SCE SCX SHE SWE LBue LHue LLDX LLXE SCDX SCXE JALR64
    ),
  )
  let names = lifted.keys().collect()
  names.sort_by((a, b) => a.compare(b))
  inspect(
    names.length(),
    content=(
      #|141
    ),
  )
  inspect(
    names.join(" "),
    content=(
      #|J JR LB LD LH LL LW OR SB SC SD SH SW ADD AND AUI BAL BEQ BNE CLO CLZ JAL JIC LBu LHu LLD LUi LWu MOD MUH MUL NAL NOR ORi SCD SEB SEH SLL SLT SRA SRL SUB XOR ADDi ADDu ANDi BEQC BEQL BGEC BGEZ BGTZ BLEZ BLTC BNEC DDIV DMOD DMUH DSBH DSLL DSRA DSRL DSUB JALR LDPC LWPC MODU MUHU MULT MULU ROTR SDIV SLLV SLTi SLTu SRAV SRLV SUBu UDIV WSBH XORi ADDiu BEQZC BGEUC BGEZC BGTZC BGTZL BLEZC BLTUC BLTZC BNEZC DADDu DDIVU DMODU DMUHU DMULU DSLLV DSRAV DSRLV DSUBu JIALC JIC64 LL_R6 LWUPC MULTu ROTRV SC_R6 SLTiu ALUIPC BGEZAL CLO_R6 CLZ_R6 DADDiu DSLL32 DSRA32 DSRL32 LLD_R6 LSA_R6 MUL_R6 SCD_R6 SELEQZ SELNEZ ADDIUPC BEQZALC BEQZC64 BGEZALC BGTZALC BITSWAP BLEZALC BLTZALC BNEZALC BNEZC64 DLSA_R6 DMUL_R6 JALR_HB JIALC64 DBITSWAP JR_HB_R6 SELEQZ64 SELNEZ64 JALR_HB64 JR_HB64_R6
    ),
  )
}
