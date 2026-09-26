///|
/// A well-formed LLVM MC operand list for every supported opcode.
fn fixture(insn : @arm.Insn) -> Array[@mc.Op] {
  let name = insn.name()
  let lsl1 = i((1 << 3) | 2)
  let am2 = i((2 << 13) | 1)
  match insn {
    Move(op) =>
      match op {
        MOVi | MVNi => [r("R0"), i(1), ..al, r("Nil")]
        MOVr | MVNr => [r("R0"), r("R1"), ..al, r("Nil")]
        MOVsi | MVNsi => [r("R0"), r("R1"), lsl1, ..al, r("Nil")]
        MOVsr | MVNsr => [r("R0"), r("R1"), r("R2"), i(2), ..al, r("Nil")]
        MOVPCLR => al
        MOVi16 => [r("R0"), i(1), ..al]
        MOVTi16 => [r("R0"), r("R0"), i(1), ..al]
        TEQrsi => [r("R0"), r("R1"), r("R2"), lsl1, ..al]
        CMPri | CMNri | TSTri | TEQri => [r("R1"), i(1), ..al]
        CMPrr | CMNzrr | TSTrr | TEQrr => [r("R1"), r("R2"), ..al]
        CMPrsi | CMNzrsi | TSTrsi => [r("R1"), r("R2"), lsl1, ..al]
        CMPrsr | CMNzrsr | TSTrsr | TEQrsr =>
          [r("R1"), r("R2"), r("R3"), i(2), ..al]
        _ if name.has_suffix("rsr") =>
          [r("R0"), r("R1"), r("R2"), r("R3"), i(2), ..al, r("CPSR")]
        _ if name.has_suffix("rsi") =>
          [r("R0"), r("R1"), r("R2"), lsl1, ..al, r("CPSR")]
        _ if name.has_suffix("ri") => [r("R0"), r("R1"), i(1), ..al, r("CPSR")]
        _ => [r("R0"), r("R1"), r("R2"), ..al, r("CPSR")]
      }
    Bits(op) =>
      match op {
        UXTB | UXTH | SXTB | SXTH => [r("R0"), r("R1"), i(0), ..al]
        UXTAB | UXTAH | SXTAB | SXTAH => [r("R0"), r("R1"), r("R2"), i(1), ..al]
        UBFX | SBFX => [r("R0"), r("R1"), i(2), i(3), ..al]
        BFI => [r("R0"), r("R0"), r("R1"), i(0xFFFF00FF), ..al]
        BFC => [r("R0"), r("R0"), i(0xFFFF00FF), ..al]
        RBIT | REV | REV16 => [r("R0"), r("R1"), ..al]
        SWPB => [r("R0"), r("R1"), r("R2"), ..al]
        PKHTB => [r("R0"), r("R1"), r("R2"), i(8), ..al]
      }
    Mult(op) =>
      match op {
        MUL => [r("R0"), r("R1"), r("R2"), ..al, r("CPSR")]
        MLA => [r("R0"), r("R1"), r("R2"), r("R3"), ..al, r("CPSR")]
        MLS | SMLABB | SMLAD | SMLAWB =>
          [r("R0"), r("R1"), r("R2"), r("R3"), ..al]
        UMULL | SMULL => [r("R0"), r("R1"), r("R2"), r("R3"), ..al, r("CPSR")]
        UMLAL | SMLAL =>
          [
            r("R0"),
            r("R1"),
            r("R2"),
            r("R3"),
            r("R0"),
            r("R1"),
            ..al,
            r("CPSR"),
          ]
        SMULBB | SMUAD | SMULTB => [r("R0"), r("R1"), r("R2"), ..al]
        SMLALBT => [r("R0"), r("R1"), r("R2"), r("R3"), ..al]
      }
    MemMulti(_) =>
      if name.has_suffix("_UPD") {
        [r("R0"), r("R0"), ..al, r("R1"), r("R2")]
      } else {
        [r("R0"), ..al, r("R1"), r("R2")]
      }
    Mem(op) =>
      match op {
        STRD | LDRD => [r("R2"), r("R3"), r("R1"), r("Nil"), i(8), ..al]
        STRD_POST | LDRD_POST =>
          [r("R2"), r("R3"), r("R1"), r("R1"), r("Nil"), i(8), ..al]
        STRD_PRE => [r("R1"), r("R2"), r("R3"), r("R1"), r("Nil"), i(8), ..al]
        LDRD_PRE => [r("R2"), r("R3"), r("R1"), r("R1"), r("Nil"), i(8), ..al]
        STRH | LDRH | LDRSH | LDRSB => [r("R0"), r("R1"), r("Nil"), i(2), ..al]
        STRH_PRE | STRH_POST | STRHTr =>
          [r("R1"), r("R0"), r("R1"), r("Nil"), i(2), ..al]
        LDRSHTi => [r("R0"), r("R1"), r("R1"), i(2), ..al]
        LDRH_PRE
        | LDRH_POST
        | LDRHTr
        | LDRSH_PRE
        | LDRSH_POST
        | LDRSHTr
        | LDRSB_PRE
        | LDRSB_POST
        | LDRSBTr => [r("R0"), r("R1"), r("R1"), r("Nil"), i(2), ..al]
        STRi12 | LDRi12 | STRBi12 | LDRBi12 => [r("R0"), r("R1"), i(4), ..al]
        STRrs | LDRrs | STRBrs | LDRBrs =>
          [r("R0"), r("R1"), r("R2"), am2, ..al]
        STR_POST_IMM | STRB_POST_IMM | STRBT_POST_IMM =>
          [r("R1"), r("R0"), r("R1"), r("Nil"), i(4), ..al]
        LDR_POST_IMM | LDRB_POST_IMM | LDRBT_POST_IMM =>
          [r("R0"), r("R1"), r("R1"), r("Nil"), i(4), ..al]
        STR_POST_REG
        | STRT_POST_REG
        | STRB_POST_REG
        | STRBT_POST_REG
        | STR_PRE_REG
        | STRB_PRE_REG => [r("R1"), r("R0"), r("R1"), r("R2"), am2, ..al]
        LDR_POST_REG
        | LDRT_POST_REG
        | LDRB_POST_REG
        | LDRBT_POST_REG
        | LDR_PRE_REG
        | LDRB_PRE_REG => [r("R0"), r("R1"), r("R1"), r("R2"), am2, ..al]
        STR_PRE_IMM | STRB_PRE_IMM => [r("R1"), r("R0"), r("R1"), i(4), ..al]
        LDR_PRE_IMM | LDRB_PRE_IMM => [r("R0"), r("R1"), r("R1"), i(4), ..al]
        LDREX | LDREXB | LDREXH => [r("R0"), r("R1"), ..al]
        LDREXD => [r("R0_R1"), r("R2"), ..al]
        STREX | STREXB | STREXH => [r("R2"), r("R0"), r("R1"), ..al]
        STREXD => [r("R4"), r("R0_R1"), r("R2"), ..al]
      }
    Branch(op) =>
      match op {
        Bcc | BL | BL_pred => [i(8), ..al]
        BLXi => [i(8)]
        BX | BLX => [r("R3")]
        BX_pred | BLX_pred => [r("R3"), ..al]
        BX_RET => al
      }
    Special(op) =>
      match op {
        SVC => [i(0), ..al]
        MRS => [r("R0"), ..al]
        MSR => [i(0xC), r("R0"), ..al]
        CPS2p | DMB | DSB | HINT | PLDi12 => [i(0)]
      }
  }
}

///|
test "every supported instruction lifts" {
  let lifted = []
  let failed = []
  let empty = []
  for insn in @arm.Insn::all() {
    let name = insn.name()
    let mc = @mc.Insn::create(name, fixture(insn), addr=0x1000)
    try @arm.lift(mc) catch {
      err => failed.push("\{name}: \{err.message()}")
    } noraise {
      [] => empty.push(name)
      stmts => {
        lifted.push(name)
        for s in stmts {
          guard s.check_type() is Ok(_) else {
            fail("\{name}: ill-typed \{s.to_string()}")
          }
        }
      }
    }
  }
  assert_eq(lifted.length(), 185)
  // barriers and hints are no-ops
  debug_inspect(
    empty,
    content=(
      #|["CPS2p", "DMB", "DSB", "HINT", "PLDi12"]
    ),
  )
  // register pairs (e.g. `R0_R1`) are not ARM registers upstream
  debug_inspect(
    failed,
    content=(
      #|[
      #|  "LDREXD: bad operands for instruction: unsupported operand: R0_R1",
      #|  "STREXD: bad operands for instruction: unsupported operand: R0_R1",
      #|]
    ),
  )
}
