// A native decoder of the T32 (Thumb and Thumb-2) instruction set
// producing the instructions of the LLVM ARM disassembler in Thumb mode:
// LLVM opcode names (`tADDi3`, `t2LDRi12`, ...) and operand lists as LLVM
// builds them (see `@arm.decode_a32` for the conventions shared with A32):
//
// - the 16-bit Thumb instructions carry the optional flag-setting operand
//   first (`s_cc_out`): `CPSR` outside an IT block, `Nil` inside;
// - the predicate operands come from the enclosing IT block (`AL`
//   outside), as LLVM's `AddThumbPredicate` inserts them;
// - Thumb-2 modified immediates are decoded to their 32-bit values
//   (`t2_so_imm`), shifted registers are packed as `ARM_AM::getSORegOpc`,
//   8-bit offsets are signed (`#-0` is `INT32_MIN`), branch targets are
//   byte offsets relative to the `PC` (the address plus 4);
// - `t2IT` has the first condition and the mask operands, the mask in
//   LLVM's condition-independent form (a set bit means "else");
// - the immediate shifts by 32 (`lsrs r0, r1, #32`) have the encoded 0;
//   the exclusive accesses have the unscaled 8-bit offset field;
// - the kinds are LLVM's `MCInstrDesc` properties (`@arm.llvm_kinds`), the
//   assembly LLVM's (with the `.w` qualifier exactly when LLVM prints it),
//   and the `SoftFail` encodings are valid instructions, as for upstream
//   BAP. `SDIV`/`UDIV` are decoded (LLVM needs the `hwdiv` feature).
//
// The IT state is carried from an IT instruction to the instructions it
// predicates by an `ItBlock` value (the decoder made by `t32_decoder`
// keeps one): the instructions must be decoded in sequence, as LLVM's
// disassembler does.
//
// Covered: the Thumb-1 instructions (all the opcodes of the Thumb lifter
// and the Thumb Lisp semantics) and the Thumb-2 data processing, load and
// store (single, dual, multiple, exclusive), multiply, divide, bit field,
// extension, branch (`t2B`, `t2Bcc`, `tBL`, `tBLXi`, `t2TBB`/`t2TBH`), IT
// and hint/barrier instructions. Coprocessor, VFP/NEON, saturating and
// parallel arithmetic encodings are reported as invalid.

///|
/// The state of an IT block: the conditions of the instructions left in
/// the block and the address of the next instruction.
pub struct ItBlock {
  priv conds : Array[Int]
  priv mut next : UInt64
}

///|
/// A fresh IT state (outside of any IT block).
pub fn ItBlock::new() -> ItBlock {
  { conds: [], next: 0, }
}

///|
/// The condition of the instruction at `addr`: the next condition of the
/// block when `addr` follows the last decoded instruction, `None` outside
/// of an IT block.
fn ItBlock::current(self : ItBlock, addr : UInt64) -> Int? {
  if self.conds.is_empty() || addr != self.next {
    self.conds.clear()
    None
  } else {
    self.conds.last()
  }
}

///|
/// Whether an IT block is active at `addr`.
pub fn ItBlock::in_block(self : ItBlock, addr : UInt64) -> Bool {
  !self.conds.is_empty() && addr == self.next
}

///|
/// `ITStatus::setITState` of LLVM: the conditions of the instructions of
/// the block opened by `IT firstcond, mask` (the mask in LLVM's form). As
/// in LLVM, they are pushed on the conditions left of an enclosing block
/// (for an IT instruction in an IT block), which resume after them.
fn ItBlock::start(self : ItBlock, firstcond : Int, mask : Int) -> Unit {
  let tz = (mask & 0xF).ctz()
  for pos = tz + 1; pos <= 3; pos = pos + 1 {
    self.conds.push(firstcond ^ ((mask >> pos) & 1))
  }
  self.conds.push(firstcond)
}

///|
priv struct T32Insn {
  name : String
  ops : Array[@mc.Op]
  text : String
}

///|
fn t32(name : String, ops : Array[@mc.Op], text : String) -> T32Insn? {
  Some({ name, ops, text, })
}

///|
fn t32_bits(x : Int, lo : Int, len : Int) -> Int {
  (x >> lo) & ((1 << len) - 1)
}

///|
fn t32_bit(x : Int, n : Int) -> Bool {
  ((x >> n) & 1) == 1
}

///|
let t32_cpsr : @mc.Op = @arm.Reg::CPSR.to_mc()

///|
fn t_gpr(n : Int) -> @mc.Op {
  @arm.mc_gpr(n)
}

///|
fn t_rn(n : Int) -> String {
  @arm.gpr_asm(n)
}

///|
fn t_imm(v : Int) -> @mc.Op {
  @arm.mc_imm(v)
}

///|
/// The address `[rn, #offset]`, with the zero offset omitted (LLVM's
/// `printThumbAddrModeImm5SOperand` and `printThumbAddrModeSPOperand`).
fn t_addr_imm(rn : Int, offset : Int) -> String {
  if offset == 0 {
    "[\{t_rn(rn)}]"
  } else {
    "[\{t_rn(rn)}, #\{offset}]"
  }
}

///|
/// A 32-bit value as an unsigned immediate (as LLVM stores decoded
/// Thumb-2 modified immediates).
fn uimm(v : UInt) -> @mc.Op {
  Imm(v.to_uint64().reinterpret_as_int64())
}

///|
/// An 8-bit or 12-bit offset as LLVM's Thumb-2 decoders produce it:
/// negative when subtracted, `INT32_MIN` for `#-0`.
fn t2_offset(add : Bool, v : Int) -> Int {
  if add {
    v
  } else if v == 0 {
    -2147483648
  } else {
    -v
  }
}

///|
/// The address `[rn, #offset]` of an offset form, the zero offset omitted.
fn t2_addr(rn : Int, offset : Int) -> String {
  if offset == 0 {
    "[\{t_rn(rn)}]"
  } else {
    "[\{t_rn(rn)}, \{t2_offset_text(offset)}]"
  }
}

///|
fn t2_offset_text(v : Int) -> String {
  if v == -2147483648 {
    "#-0"
  } else {
    @arm.imm_asm(v)
  }
}

///|
/// `ThumbExpandImm`: the value of a Thumb-2 modified immediate.
pub fn t2_expand_imm(imm12 : Int) -> UInt {
  let imm8 = (imm12 & 0xFF).reinterpret_as_uint()
  if imm12 >> 10 == 0 {
    match (imm12 >> 8) & 3 {
      0 => imm8
      1 => (imm8 << 16) | imm8
      2 => (imm8 << 24) | (imm8 << 8)
      _ => (imm8 << 24) | (imm8 << 16) | (imm8 << 8) | imm8
    }
  } else {
    let unrotated = 0x80U | (imm12 & 0x7F).reinterpret_as_uint()
    let rot = (imm12 >> 7) & 0x1F
    (unrotated >> rot) | (unrotated << (32 - rot))
  }
}

///|
/// Decodes a 16-bit Thumb instruction `h` with the condition `cond` given
/// by the IT block (`in_it`) or `AL`.
fn t16_decode(h : Int, cond : Int, in_it : Bool) -> T32Insn? {
  let s = if in_it { @arm.mc_nil() } else { t32_cpsr }
  let sx = if in_it { "" } else { "s" }
  let c = @arm.cond_asm(cond)
  let p = @arm.mc_pred(cond)
  let r0 = t32_bits(h, 0, 3)
  let r3 = t32_bits(h, 3, 3)
  let r6 = t32_bits(h, 6, 3)
  let r8 = t32_bits(h, 8, 3)
  let imm8 = t32_bits(h, 0, 8)
  let imm5 = t32_bits(h, 6, 5)
  match h >> 11 {
    0 | 1 | 2 => {
      // shift by immediate, and MOVS (register)
      let op = h >> 11
      // (LLVM decodes `movs` also in IT blocks, unpredicated)
      if op == 0 && imm5 == 0 {
        return t32(
          "tMOVSr",
          [t_gpr(r0), t_gpr(r3)],
          "movs \{t_rn(r0)}, \{t_rn(r3)}",
        )
      }
      // (the operand of a shift by 32 is 0, as the encoded field)
      let (name, mnemonic) = match op {
        0 => ("tLSLri", "lsl")
        1 => ("tLSRri", "lsr")
        _ => ("tASRri", "asr")
      }
      let amount = if op != 0 && imm5 == 0 { 32 } else { imm5 }
      t32(
        name,
        [t_gpr(r0), s, t_gpr(r3), t_imm(imm5), ..p],
        "\{mnemonic}\{sx}\{c} \{t_rn(r0)}, \{t_rn(r3)}, #\{amount}",
      )
    }
    3 => {
      let sub = t32_bit(h, 9)
      let mnemonic = if sub { "sub" } else { "add" }
      if t32_bit(h, 10) {
        t32(
          if sub {
            "tSUBi3"
          } else {
            "tADDi3"
          },
          [t_gpr(r0), s, t_gpr(r3), t_imm(r6), ..p],
          "\{mnemonic}\{sx}\{c} \{t_rn(r0)}, \{t_rn(r3)}, #\{r6}",
        )
      } else {
        t32(
          if sub {
            "tSUBrr"
          } else {
            "tADDrr"
          },
          [t_gpr(r0), s, t_gpr(r3), t_gpr(r6), ..p],
          "\{mnemonic}\{sx}\{c} \{t_rn(r0)}, \{t_rn(r3)}, \{t_rn(r6)}",
        )
      }
    }
    4 =>
      t32(
        "tMOVi8",
        [t_gpr(r8), s, t_imm(imm8), ..p],
        "mov\{sx}\{c} \{t_rn(r8)}, #\{imm8}",
      )
    5 =>
      t32(
        "tCMPi8",
        [t_gpr(r8), t_imm(imm8), ..p],
        "cmp\{c} \{t_rn(r8)}, #\{imm8}",
      )
    6 | 7 => {
      let sub = h >> 11 == 7
      t32(
        if sub {
          "tSUBi8"
        } else {
          "tADDi8"
        },
        [t_gpr(r8), s, t_gpr(r8), t_imm(imm8), ..p],
        "\{if sub { "sub" } else { "add" }}\{sx}\{c} \{t_rn(r8)}, #\{imm8}",
      )
    }
    8 =>
      if t32_bit(h, 10) {
        t16_special(h, p, c)
      } else {
        t16_data(h, s, sx, p, c)
      }
    9 =>
      t32(
        "tLDRpci",
        [t_gpr(r8), t_imm(imm8 * 4), ..p],
        "ldr\{c} \{t_rn(r8)}, [pc, #\{imm8 * 4}]",
      )
    10 | 11 => {
      let (name, mnemonic) = match t32_bits(h, 9, 3) {
        0 => ("tSTRr", "str")
        1 => ("tSTRHr", "strh")
        2 => ("tSTRBr", "strb")
        3 => ("tLDRSB", "ldrsb")
        4 => ("tLDRr", "ldr")
        5 => ("tLDRHr", "ldrh")
        6 => ("tLDRBr", "ldrb")
        _ => ("tLDRSH", "ldrsh")
      }
      t32(
        name,
        [t_gpr(r0), t_gpr(r3), t_gpr(r6), ..p],
        "\{mnemonic}\{c} \{t_rn(r0)}, [\{t_rn(r3)}, \{t_rn(r6)}]",
      )
    }
    12 | 13 | 14 | 15 | 16 | 17 => {
      let load = t32_bit(h, 11)
      let (size, scale) = match h >> 12 {
        6 => ("", 4)
        7 => ("B", 1)
        _ => ("H", 2)
      }
      let name = (if load { "tLDR" } else { "tSTR" }) + size + "i"
      t32(
        name,
        [t_gpr(r0), t_gpr(r3), t_imm(imm5), ..p],
        "\{if load { "ldr" } else { "str" }}\{size.to_lower()}\{c} \{t_rn(r0)}, \{t_addr_imm(r3, imm5 * scale)}",
      )
    }
    18 | 19 => {
      let load = t32_bit(h, 11)
      t32(
        if load {
          "tLDRspi"
        } else {
          "tSTRspi"
        },
        [t_gpr(r8), t_gpr(13), t_imm(imm8), ..p],
        "\{if load { "ldr" } else { "str" }}\{c} \{t_rn(r8)}, \{t_addr_imm(13, imm8 * 4)}",
      )
    }
    20 =>
      t32(
        "tADR",
        [t_gpr(r8), t_imm(imm8), ..p],
        "adr\{c} \{t_rn(r8)}, #\{imm8 * 4}",
      )
    21 =>
      t32(
        "tADDrSPi",
        [t_gpr(r8), t_gpr(13), t_imm(imm8), ..p],
        "add\{c} \{t_rn(r8)}, sp, #\{imm8 * 4}",
      )
    22 | 23 => t16_misc(h, p, c)
    24 | 25 => {
      let mask = imm8
      guard mask != 0 else { return None }
      if t32_bit(h, 11) {
        t32(
          "tLDMIA",
          [t_gpr(r8), ..p, ..@arm.mc_reglist(mask)],
          "ldm\{c} \{t_rn(r8)}\{if ((mask >> r8) & 1) == 0 { "!" } else { "" }}, \{@arm.reglist_asm(mask)}",
        )
      } else {
        t32(
          "tSTMIA_UPD",
          [t_gpr(r8), t_gpr(r8), ..p, ..@arm.mc_reglist(mask)],
          "stm\{c} \{t_rn(r8)}!, \{@arm.reglist_asm(mask)}",
        )
      }
    }
    26 | 27 => {
      let bcond = t32_bits(h, 8, 4)
      match bcond {
        // LLVM's pseudo instructions with a fixed encoding
        14 if imm8 == 0xF9 => t32("t__brkdiv0", [], "__brkdiv0")
        14 if imm8 == 0xFE => t32("tTRAP", [], "trap")
        14 => t32("tUDF", [t_imm(imm8)], "udf #\{imm8}")
        15 => t32("tSVC", [t_imm(imm8), ..p], "svc\{c} #\{imm8}")
        _ => {
          // (unpredictable in IT blocks, but LLVM decodes them there)
          let offset = @arm.sign_extend(imm8 << 1, 9)
          t32(
            "tBcc",
            [t_imm(offset), ..@arm.mc_pred(bcond)],
            "b\{@arm.cond_asm(bcond)} #\{offset}",
          )
        }
      }
    }
    28 => {
      let offset = @arm.sign_extend(t32_bits(h, 0, 11) << 1, 12)
      t32("tB", [t_imm(offset), ..p], "b\{c} #\{offset}")
    }
    _ => None
  }
}

///|
/// Thumb data processing (`010000 op Rm Rdn`).
fn t16_data(
  h : Int,
  s : @mc.Op,
  sx : String,
  p : Array[@mc.Op],
  c : String,
) -> T32Insn? {
  let rdn = t32_bits(h, 0, 3)
  let rm = t32_bits(h, 3, 3)
  let op = t32_bits(h, 6, 4)
  let names = [
    "tAND", "tEOR", "tLSLrr", "tLSRrr", "tASRrr", "tADC", "tSBC", "tROR", "tTST",
    "tRSB", "tCMPr", "tCMNz", "tORR", "tMUL", "tBIC", "tMVN",
  ]
  let mnemonics = [
    "and", "eor", "lsl", "lsr", "asr", "adc", "sbc", "ror", "tst", "rsb", "cmp",
    "cmn", "orr", "mul", "bic", "mvn",
  ]
  let name = names[op]
  let m = mnemonics[op]
  match op {
    8 | 10 | 11 =>
      t32(
        name,
        [t_gpr(rdn), t_gpr(rm), ..p],
        "\{m}\{c} \{t_rn(rdn)}, \{t_rn(rm)}",
      )
    9 =>
      t32(
        name,
        [t_gpr(rdn), s, t_gpr(rm), ..p],
        "rsb\{sx}\{c} \{t_rn(rdn)}, \{t_rn(rm)}, #0",
      )
    13 =>
      t32(
        name,
        [t_gpr(rdn), s, t_gpr(rm), t_gpr(rdn), ..p],
        "mul\{sx}\{c} \{t_rn(rdn)}, \{t_rn(rm)}, \{t_rn(rdn)}",
      )
    15 =>
      t32(
        name,
        [t_gpr(rdn), s, t_gpr(rm), ..p],
        "mvn\{sx}\{c} \{t_rn(rdn)}, \{t_rn(rm)}",
      )
    _ =>
      t32(
        name,
        [t_gpr(rdn), s, t_gpr(rdn), t_gpr(rm), ..p],
        "\{m}\{sx}\{c} \{t_rn(rdn)}, \{t_rn(rm)}",
      )
  }
}

///|
/// Special data instructions and branch and exchange (`010001 op ...`).
fn t16_special(h : Int, p : Array[@mc.Op], c : String) -> T32Insn? {
  let rdn = (t32_bits(h, 7, 1) << 3) | t32_bits(h, 0, 3)
  let rm = t32_bits(h, 3, 4)
  match t32_bits(h, 8, 2) {
    0 =>
      if rm == 13 {
        t32(
          "tADDrSP",
          [t_gpr(rdn), t_gpr(13), t_gpr(rdn), ..p],
          "add\{c} \{t_rn(rdn)}, sp, \{t_rn(rdn)}",
        )
      } else if rdn == 13 {
        t32(
          "tADDspr",
          [t_gpr(13), t_gpr(13), t_gpr(rm), ..p],
          "add\{c} sp, \{t_rn(rm)}",
        )
      } else {
        t32(
          "tADDhirr",
          [t_gpr(rdn), t_gpr(rdn), t_gpr(rm), ..p],
          "add\{c} \{t_rn(rdn)}, \{t_rn(rm)}",
        )
      }
    1 =>
      t32(
        "tCMPhir",
        [t_gpr(rdn), t_gpr(rm), ..p],
        "cmp\{c} \{t_rn(rdn)}, \{t_rn(rm)}",
      )
    2 =>
      t32(
        "tMOVr",
        [t_gpr(rdn), t_gpr(rm), ..p],
        "mov\{c} \{t_rn(rdn)}, \{t_rn(rm)}",
      )
    _ =>
      if t32_bit(h, 7) {
        guard t32_bits(h, 0, 3) == 0 else { return None }
        t32("tBLXr", [..p, t_gpr(rm)], "blx\{c} \{t_rn(rm)}")
      } else {
        // (non-zero low bits: a `SoftFail`)
        t32("tBX", [t_gpr(rm), ..p], "bx\{c} \{t_rn(rm)}")
      }
  }
}

///|
/// Miscellaneous 16-bit instructions (`1011 ...`).
fn t16_misc(h : Int, p : Array[@mc.Op], c : String) -> T32Insn? {
  let r0 = t32_bits(h, 0, 3)
  let r3 = t32_bits(h, 3, 3)
  let op = t32_bits(h, 5, 7)
  if op >> 3 == 0 {
    let imm7 = t32_bits(h, 0, 7)
    let sub = t32_bit(h, 7)
    t32(
      if sub {
        "tSUBspi"
      } else {
        "tADDspi"
      },
      [t_gpr(13), t_gpr(13), t_imm(imm7), ..p],
      "\{if sub { "sub" } else { "add" }}\{c} sp, #\{imm7 * 4}",
    )
  } else if (h & 0x0500) == 0x0100 {
    // CBZ/CBNZ (unpredictable in IT blocks, but LLVM decodes them there)
    let offset = (t32_bits(h, 9, 1) << 6) | (t32_bits(h, 3, 5) << 1)
    let nz = t32_bit(h, 11)
    t32(
      if nz {
        "tCBNZ"
      } else {
        "tCBZ"
      },
      [t_gpr(r0), t_imm(offset)],
      "\{if nz { "cbnz" } else { "cbz" }} \{t_rn(r0)}, #\{offset}",
    )
  } else if op >> 3 == 0b0010 {
    let (name, m) = match t32_bits(h, 6, 2) {
      0 => ("tSXTH", "sxth")
      1 => ("tSXTB", "sxtb")
      2 => ("tUXTH", "uxth")
      _ => ("tUXTB", "uxtb")
    }
    t32(name, [t_gpr(r0), t_gpr(r3), ..p], "\{m}\{c} \{t_rn(r0)}, \{t_rn(r3)}")
  } else if op >> 4 == 0b010 || op >> 4 == 0b110 {
    let pop = op >> 4 == 0b110
    let extra = if t32_bit(h, 8) {
      if pop {
        0x8000
      } else {
        0x4000
      }
    } else {
      0
    }
    let mask = t32_bits(h, 0, 8) | extra
    guard mask != 0 else { return None }
    t32(
      if pop {
        "tPOP"
      } else {
        "tPUSH"
      },
      [..p, ..@arm.mc_reglist(mask)],
      "\{if pop { "pop" } else { "push" }}\{c} \{@arm.reglist_asm(mask)}",
    )
  } else if op >> 1 == 0b101000 || op >> 1 == 0b101001 || op >> 1 == 0b101011 {
    let (name, m) = match t32_bits(h, 6, 2) {
      0 => ("tREV", "rev")
      1 => ("tREV16", "rev16")
      _ => ("tREVSH", "revsh")
    }
    t32(name, [t_gpr(r0), t_gpr(r3), ..p], "\{m}\{c} \{t_rn(r0)}, \{t_rn(r3)}")
  } else if (h & 0xFFE8) == 0xB660 {
    let iflags = t32_bits(h, 0, 3)
    let imod = if t32_bit(h, 4) { 3 } else { 2 }
    let flags = StringBuilder()
    for pair in [(4, 'a'), (2, 'i'), (1, 'f')] {
      if (iflags & pair.0) != 0 {
        flags.write_char(pair.1)
      }
    }
    if iflags == 0 {
      flags.write_string("none")
    }
    t32(
      "tCPS",
      [t_imm(imod), t_imm(iflags)],
      "cps\{if imod == 2 { "ie" } else { "id" }} \{flags.to_string()}",
    )
  } else if (h & 0xFFF7) == 0xB650 {
    let big = t32_bit(h, 3)
    t32(
      "tSETEND",
      [t_imm(if big { 1 } else { 0 })],
      "setend \{if big { "be" } else { "le" }}",
    )
  } else if op >> 3 == 0b1110 {
    t32("tBKPT", [t_imm(t32_bits(h, 0, 8))], "bkpt #\{t32_bits(h, 0, 8)}")
  } else if op >> 3 == 0b1111 {
    let firstcond = t32_bits(h, 4, 4)
    let mask = t32_bits(h, 0, 4)
    if mask == 0 {
      let hint = firstcond
      let text = if hint <= 4 {
        ["nop", "yield", "wfe", "wfi", "sev"][hint] + c
      } else {
        "hint\{c} #\{hint}"
      }
      t32("tHINT", [t_imm(hint), ..p], text)
    } else {
      // (an IT instruction in an IT block starts a new block, as in LLVM)
      // `DecodeIT`: the first condition `0b1111` is a `SoftFail` for `AL`
      let firstcond = if firstcond == 15 { 14 } else { firstcond }
      // LLVM's `DecodeIT`: flip the mask bits above the terminating bit
      // when the low bit of the first condition is set
      let llvm_mask = if (firstcond & 1) == 1 {
        let low = mask & -mask
        mask ^ (0xF & (-low << 1))
      } else {
        mask
      }
      let suffix = StringBuilder()
      let tz = llvm_mask.ctz()
      for pos = 3; pos > tz; pos = pos - 1 {
        suffix.write_char(if ((llvm_mask >> pos) & 1) == 1 { 'e' } else { 't' })
      }
      t32(
        "t2IT",
        [t_imm(firstcond), t_imm(llvm_mask)],
        "it\{suffix.to_string()} \{if firstcond == 14 { "al" } else { @arm.cond_asm(firstcond) }}",
      )
    }
  } else {
    None
  }
}

///|
/// Decodes the 32-bit Thumb-2 instruction made of the halfwords `h1` and
/// `h2` with the condition `cond`.
fn t32_decode(h1 : Int, h2 : Int, cond : Int) -> T32Insn? {
  match t32_bits(h1, 11, 2) {
    1 =>
      if t32_bit(h1, 10) {
        None
      } else if t32_bit(h1, 9) {
        t2_dp_shifted(h1, h2, cond)
      } else if t32_bit(h1, 6) {
        t2_dual_exclusive(h1, h2, cond)
      } else {
        t2_ldm_stm(h1, h2, cond)
      }
    2 =>
      if t32_bit(h2, 15) {
        t2_branch_misc(h1, h2, cond)
      } else if t32_bit(h1, 9) {
        t2_plain_imm(h1, h2, cond)
      } else {
        t2_modified_imm(h1, h2, cond)
      }
    3 =>
      if t32_bit(h1, 10) {
        None
      } else if t32_bits(h1, 9, 2) == 0 {
        if t32_bit(h1, 4) {
          t2_load(h1, h2, cond)
        } else if !t32_bit(h1, 8) {
          t2_store(h1, h2, cond)
        } else {
          None
        }
      } else if !t32_bit(h1, 8) {
        t2_dp_register(h1, h2, cond)
      } else if t32_bits(h1, 7, 4) == 0b0110 {
        t2_multiply(h1, h2, cond)
      } else if t32_bits(h1, 7, 4) == 0b0111 {
        t2_long_multiply(h1, h2, cond)
      } else {
        None
      }
    _ => None
  }
}

///|
let t2_dp_names : ReadOnlyArray[String] = [
  "AND", "BIC", "ORR", "ORN", "EOR", "", "PKH", "", "ADD", "", "ADC", "SBC", "",
  "SUB", "RSB", "",
]

///|
/// The name of the comparison a data-processing opcode turns into when
/// its destination is `PC` and it sets the flags.
fn t2_compare_name(op : Int) -> String? {
  match op {
    0 => Some("TST")
    4 => Some("TEQ")
    8 => Some("CMN")
    13 => Some("CMP")
    _ => None
  }
}

///|
/// Data processing (modified immediate).
fn t2_modified_imm(h1 : Int, h2 : Int, cond : Int) -> T32Insn? {
  let op = t32_bits(h1, 5, 4)
  let s = t32_bit(h1, 4)
  let rn_ = t32_bits(h1, 0, 4)
  let rd = t32_bits(h2, 8, 4)
  let imm12 = (t32_bits(h1, 10, 1) << 11) |
    (t32_bits(h2, 12, 3) << 8) |
    t32_bits(h2, 0, 8)
  let value = t2_expand_imm(imm12)
  let p = @arm.mc_pred(cond)
  let c = @arm.cond_asm(cond)
  let sx = if s { "s" } else { "" }
  let base = t2_dp_names[op]
  guard base != "" && base != "PKH" else { return None }
  if rd == 15 && s && t2_compare_name(op) is Some(cmp) {
    let name = if cmp == "CMN" { "t2CMNri" } else { "t2" + cmp + "ri" }
    return t32(
      name,
      [t_gpr(rn_), uimm(value), ..p],
      "\{cmp.to_lower()}\{c}.w \{t_rn(rn_)}, #\{value}",
    )
  }
  if rn_ == 15 && (op == 2 || op == 3) {
    let mov = if op == 2 { "MOV" } else { "MVN" }
    return t32(
      "t2" + mov + "i",
      [t_gpr(rd), uimm(value), ..p, @arm.mc_cc_out(s)],
      "\{mov.to_lower()}\{sx}\{c}.w \{t_rn(rd)}, #\{value}",
    )
  }
  // LLVM's `t2ADDspImm`/`t2SUBspImm` when both are `SP`
  let form = if rd == 13 && rn_ == 13 && (base == "ADD" || base == "SUB") {
    "spImm"
  } else {
    "ri"
  }
  t32(
    "t2" + base + form,
    [t_gpr(rd), t_gpr(rn_), uimm(value), ..p, @arm.mc_cc_out(s)],
    "\{base.to_lower()}\{sx}\{c}.w \{t_rn(rd)}, \{t_rn(rn_)}, #\{value}",
  )
}

///|
/// Data processing (plain binary immediate): `ADDW`, `SUBW`, `ADR`,
/// `MOVW`, `MOVT` and the bit field instructions.
fn t2_plain_imm(h1 : Int, h2 : Int, cond : Int) -> T32Insn? {
  let op = t32_bits(h1, 4, 5)
  let rn_ = t32_bits(h1, 0, 4)
  let rd = t32_bits(h2, 8, 4)
  let imm12 = (t32_bits(h1, 10, 1) << 11) |
    (t32_bits(h2, 12, 3) << 8) |
    t32_bits(h2, 0, 8)
  let p = @arm.mc_pred(cond)
  let c = @arm.cond_asm(cond)
  match op {
    0 | 10 => {
      let sub = op == 10
      // (LLVM decodes `subw rd, pc, #0` as `t2SUBri12`)
      if rn_ == 15 && !(sub && imm12 == 0) {
        let offset = t2_offset(!sub, imm12)
        t32(
          "t2ADR",
          [t_gpr(rd), @arm.mc_imm_u32(offset), ..p],
          "adr\{c}.w \{t_rn(rd)}, \{t2_offset_text(offset)}",
        )
      } else {
        // LLVM's `t2ADDspImm12`/`t2SUBspImm12` when both are `SP`
        let sp = if rd == 13 && rn_ == 13 { "spImm12" } else { "ri12" }
        t32(
          (if sub { "t2SUB" } else { "t2ADD" }) + sp,
          [t_gpr(rd), t_gpr(rn_), t_imm(imm12), ..p],
          "\{if sub { "subw" } else { "addw" }}\{c} \{t_rn(rd)}, \{t_rn(rn_)}, #\{imm12}",
        )
      }
    }
    4 | 12 => {
      let imm16 = (rn_ << 12) | imm12
      if op == 4 {
        t32(
          "t2MOVi16",
          [t_gpr(rd), t_imm(imm16), ..p],
          "movw\{c} \{t_rn(rd)}, #\{imm16}",
        )
      } else {
        t32(
          "t2MOVTi16",
          [t_gpr(rd), t_gpr(rd), t_imm(imm16), ..p],
          "movt\{c} \{t_rn(rd)}, #\{imm16}",
        )
      }
    }
    20 | 28 => {
      guard !t32_bit(h2, 5) && !t32_bit(h1, 10) else { return None }
      let lsb = (t32_bits(h2, 12, 3) << 2) | t32_bits(h2, 6, 2)
      let widthm1 = t32_bits(h2, 0, 5)
      let name = if op == 20 { "t2SBFX" } else { "t2UBFX" }
      t32(
        name,
        [t_gpr(rd), t_gpr(rn_), t_imm(lsb), t_imm(widthm1), ..p],
        "\{if op == 20 { "sbfx" } else { "ubfx" }}\{c} \{t_rn(rd)}, \{t_rn(rn_)}, #\{lsb}, #\{widthm1 + 1}",
      )
    }
    22 => {
      guard !t32_bit(h2, 5) && !t32_bit(h1, 10) else { return None }
      let lsb = (t32_bits(h2, 12, 3) << 2) | t32_bits(h2, 6, 2)
      let msb = t32_bits(h2, 0, 5)
      // `lsb > msb` is a `SoftFail`, the field is then the bit `msb`
      let lsb = if lsb > msb { msb } else { lsb }
      let msb_mask = if msb == 31 { 0xFFFFFFFFU } else { (1U << (msb + 1)) - 1 }
      let lsb_mask = (1U << lsb) - 1
      let inv_mask = @arm.mc_imm_u32(
        (msb_mask ^ lsb_mask).lnot().reinterpret_as_int(),
      )
      let width = msb - lsb + 1
      if rn_ == 15 {
        t32(
          "t2BFC",
          [t_gpr(rd), t_gpr(rd), inv_mask, ..p],
          "bfc\{c} \{t_rn(rd)}, #\{lsb}, #\{width}",
        )
      } else {
        t32(
          "t2BFI",
          [t_gpr(rd), t_gpr(rd), t_gpr(rn_), inv_mask, ..p],
          "bfi\{c} \{t_rn(rd)}, \{t_rn(rn_)}, #\{lsb}, #\{width}",
        )
      }
    }
    _ => None
  }
}

///|
/// Data processing (shifted register).
fn t2_dp_shifted(h1 : Int, h2 : Int, cond : Int) -> T32Insn? {
  let op = t32_bits(h1, 5, 4)
  // bit 15 of the second halfword set: a `SoftFail`, except for `ORR` (and
  // the moves and shifts in its encoding space), which LLVM rejects
  guard !t32_bit(h2, 15) || op != 2 else { return None }
  let s = t32_bit(h1, 4)
  let rn_ = t32_bits(h1, 0, 4)
  let rd = t32_bits(h2, 8, 4)
  let rm = t32_bits(h2, 0, 4)
  let typ = t32_bits(h2, 4, 2)
  let imm5 = (t32_bits(h2, 12, 3) << 2) | t32_bits(h2, 6, 2)
  let p = @arm.mc_pred(cond)
  let c = @arm.cond_asm(cond)
  let sx = if s { "s" } else { "" }
  let cc = @arm.mc_cc_out(s)
  let shift = @arm.shift_opc_of_type(typ, imm5)
  let so = t_imm(shift | (imm5 << 3))
  let plain = imm5 == 0 && typ == 0
  let shift_text = @arm.shift_imm_asm(shift, imm5)
  let base = t2_dp_names[op]
  guard base != "" else { return None }
  if base == "PKH" {
    guard !s && !t32_bit(h2, 4) else { return None }
    let tb = t32_bit(h2, 5)
    let name = if tb { "t2PKHTB" } else { "t2PKHBT" }
    return t32(
      name,
      [t_gpr(rd), t_gpr(rn_), t_gpr(rm), t_imm(imm5), ..p],
      "\{if tb { "pkhtb" } else { "pkhbt" }}\{c} \{t_rn(rd)}, \{t_rn(rn_)}, \{t_rn(rm)}\{shift_text}",
    )
  }
  if rd == 15 && s && t2_compare_name(op) is Some(cmp) {
    let prefix = if cmp == "CMN" { "t2CMNz" } else { "t2" + cmp }
    return if plain {
      t32(
        prefix + "rr",
        [t_gpr(rn_), t_gpr(rm), ..p],
        "\{cmp.to_lower()}\{c}.w \{t_rn(rn_)}, \{t_rn(rm)}",
      )
    } else {
      t32(
        prefix + "rs",
        [t_gpr(rn_), t_gpr(rm), so, ..p],
        "\{cmp.to_lower()}\{c}.w \{t_rn(rn_)}, \{t_rn(rm)}\{shift_text}",
      )
    }
  }
  if rn_ == 15 && op == 2 {
    // MOV (register) and the shifts by an immediate
    if plain {
      return t32(
        "t2MOVr",
        [t_gpr(rd), t_gpr(rm), ..p, cc],
        "mov\{sx}\{c}.w \{t_rn(rd)}, \{t_rn(rm)}",
      )
    }
    if shift == 5 {
      return t32(
        "t2RRX",
        [t_gpr(rd), t_gpr(rm), ..p, cc],
        "rrx\{sx}\{c} \{t_rn(rd)}, \{t_rn(rm)}",
      )
    }
    let (name, m) = match shift {
      1 => ("t2ASRri", "asr")
      2 => ("t2LSLri", "lsl")
      3 => ("t2LSRri", "lsr")
      _ => ("t2RORri", "ror")
    }
    return t32(
      name,
      [t_gpr(rd), t_gpr(rm), t_imm(imm5), ..p, cc],
      "\{m}\{sx}\{c}.w \{t_rn(rd)}, \{t_rn(rm)}, #\{imm5}",
    )
  }
  if rn_ == 15 && op == 3 {
    return if plain {
      t32(
        "t2MVNr",
        [t_gpr(rd), t_gpr(rm), ..p, cc],
        "mvn\{sx}\{c}.w \{t_rn(rd)}, \{t_rn(rm)}",
      )
    } else {
      t32(
        "t2MVNs",
        [t_gpr(rd), t_gpr(rm), so, ..p, cc],
        "mvn\{sx}\{c}.w \{t_rn(rd)}, \{t_rn(rm)}\{shift_text}",
      )
    }
  }
  if plain {
    t32(
      "t2" + base + "rr",
      [t_gpr(rd), t_gpr(rn_), t_gpr(rm), ..p, cc],
      "\{base.to_lower()}\{sx}\{c}.w \{t_rn(rd)}, \{t_rn(rn_)}, \{t_rn(rm)}",
    )
  } else {
    t32(
      "t2" + base + "rs",
      [t_gpr(rd), t_gpr(rn_), t_gpr(rm), so, ..p, cc],
      "\{base.to_lower()}\{sx}\{c}.w \{t_rn(rd)}, \{t_rn(rn_)}, \{t_rn(rm)}\{shift_text}",
    )
  }
}

///|
/// Branches and miscellaneous control.
fn t2_branch_misc(h1 : Int, h2 : Int, cond : Int) -> T32Insn? {
  let p = @arm.mc_pred(cond)
  let c = @arm.cond_asm(cond)
  let s = t32_bits(h1, 10, 1)
  let j1 = t32_bits(h2, 13, 1)
  let j2 = t32_bits(h2, 11, 1)
  let i1 = 1 - (j1 ^ s)
  let i2 = 1 - (j2 ^ s)
  // the 25-bit offset of B.W, BL and BLX
  let long_offset = (lo : Int) => {
    @arm.sign_extend(
      (s << 24) | (i1 << 23) | (i2 << 22) | (t32_bits(h1, 0, 10) << 12) | lo,
      25,
    )
  }
  match (t32_bit(h2, 14), t32_bit(h2, 12)) {
    (false, false) => {
      let bcond = t32_bits(h1, 6, 4)
      if bcond < 14 {
        let offset = @arm.sign_extend(
          (s << 20) |
          (j2 << 19) |
          (j1 << 18) |
          (t32_bits(h1, 0, 6) << 12) |
          (t32_bits(h2, 0, 11) << 1),
          21,
        )
        t32(
          "t2Bcc",
          [t_imm(offset), ..@arm.mc_pred(bcond)],
          "b\{@arm.cond_asm(bcond)}.w #\{offset}",
        )
      } else {
        t2_misc_control(h1, h2, p, c)
      }
    }
    (false, true) => {
      let offset = long_offset(t32_bits(h2, 0, 11) << 1)
      t32("t2B", [t_imm(offset), ..p], "b\{c}.w #\{offset}")
    }
    (true, true) => {
      let offset = long_offset(t32_bits(h2, 0, 11) << 1)
      t32("tBL", [..p, t_imm(offset)], "bl\{c} #\{offset}")
    }
    (true, false) => {
      guard !t32_bit(h2, 0) else { return None }
      let offset = long_offset(t32_bits(h2, 1, 10) << 2)
      t32("tBLXi", [..p, t_imm(offset)], "blx\{c} #\{offset}")
    }
  }
}

///|
/// Status register accesses, hints and barriers.
fn t2_misc_control(
  h1 : Int,
  h2 : Int,
  p : Array[@mc.Op],
  c : String,
) -> T32Insn? {
  let op = t32_bits(h1, 4, 7)
  match op {
    0b0111000 | 0b0111001 => {
      guard t32_bits(h2, 12, 3) == 0 && t32_bits(h2, 0, 8) == 0 else {
        return None
      }
      let mask = (t32_bits(h1, 4, 1) << 4) | t32_bits(h2, 8, 4)
      guard mask != 0 else { return None }
      t32(
        "t2MSR_AR",
        [t_imm(mask), t_gpr(t32_bits(h1, 0, 4)), ..p],
        "msr\{c} \{@arm.msr_mask_asm(mask)}, \{t_rn(t32_bits(h1, 0, 4))}",
      )
    }
    0b0111010 => {
      guard (h1 & 0xF) == 0xF && t32_bits(h2, 8, 7) == 0 else { return None }
      let hint = t32_bits(h2, 0, 8)
      let text = match hint {
        0 => "nop\{c}"
        1 => "yield\{c}"
        2 => "wfe\{c}"
        3 => "wfi\{c}"
        4 => "sev\{c}"
        _ => "hint\{c} #\{hint}"
      }
      t32("t2HINT", [t_imm(hint), ..p], text)
    }
    0b0111011 => {
      guard (h1 & 0xF) == 0xF && t32_bits(h2, 8, 7) == 0xF else { return None }
      let opt = t32_bits(h2, 0, 4)
      let (name, kind) = match t32_bits(h2, 4, 4) {
        4 => ("t2DSB", 4)
        5 => ("t2DMB", 5)
        6 => ("t2ISB", 6)
        _ => return None
      }
      t32(name, [t_imm(opt), ..p], @arm.barrier_asm(kind, opt, c))
    }
    0b0111110 | 0b0111111 => {
      guard (h1 & 0xF) == 0xF &&
        t32_bits(h2, 0, 8) == 0 &&
        t32_bits(h2, 12, 3) == 0 else {
        return None
      }
      let rd = t32_bits(h2, 8, 4)
      if op == 0b0111111 {
        t32("t2MRSsys_AR", [t_gpr(rd), ..p], "mrs\{c} \{t_rn(rd)}, spsr")
      } else {
        t32("t2MRS_AR", [t_gpr(rd), ..p], "mrs\{c} \{t_rn(rd)}, apsr")
      }
    }
    _ => None
  }
}

///|
/// Load and store multiple.
fn t2_ldm_stm(h1 : Int, h2 : Int, cond : Int) -> T32Insn? {
  let mode = match t32_bits(h1, 7, 2) {
    1 => "IA"
    2 => "DB"
    _ => return None
  }
  let wb = t32_bit(h1, 5)
  let load = t32_bit(h1, 4)
  let rn_ = t32_bits(h1, 0, 4)
  let mask = h2 & 0xFFFF
  guard mask != 0 else { return None }
  guard load || (mask & 0xA000) == 0 else { return None }
  let name = "t2" +
    (if load { "LDM" } else { "STM" }) +
    mode +
    (if wb { "_UPD" } else { "" })
  let base = if wb { [t_gpr(rn_), t_gpr(rn_)] } else { [t_gpr(rn_)] }
  let c = @arm.cond_asm(cond)
  let text = match (load, mode, rn_, wb) {
    (true, "IA", 13, true) => "pop\{c}.w \{@arm.reglist_asm(mask)}"
    (false, "DB", 13, true) => "push\{c}.w \{@arm.reglist_asm(mask)}"
    _ =>
      "\{if load { "ldm" } else { "stm" }}\{if mode == "IA" { "" } else { "db" }}\{c}.w \{t_rn(rn_)}\{if wb { "!" } else { "" }}, \{@arm.reglist_asm(mask)}"
  }
  t32(name, [..base, ..@arm.mc_pred(cond), ..@arm.mc_reglist(mask)], text)
}

///|
/// Load/store dual, load/store exclusive and table branch.
fn t2_dual_exclusive(h1 : Int, h2 : Int, cond : Int) -> T32Insn? {
  let p_bit = t32_bit(h1, 8)
  let add = t32_bit(h1, 7)
  let wb = t32_bit(h1, 5)
  let load = t32_bit(h1, 4)
  let rn_ = t32_bits(h1, 0, 4)
  let rt = t32_bits(h2, 12, 4)
  let rt2 = t32_bits(h2, 8, 4)
  let imm8 = t32_bits(h2, 0, 8)
  let p = @arm.mc_pred(cond)
  let c = @arm.cond_asm(cond)
  if p_bit || wb {
    // LDRD/STRD (immediate)
    let offset = t2_offset(add, imm8 * 4)
    let otext = t2_offset_text(offset)
    let m = if load { "ldrd" } else { "strd" }
    let regs = "\{t_rn(rt)}, \{t_rn(rt2)}"
    if p_bit && !wb {
      t32(
        if load {
          "t2LDRDi8"
        } else {
          "t2STRDi8"
        },
        [t_gpr(rt), t_gpr(rt2), t_gpr(rn_), t_imm(offset), ..p],
        "\{m}\{c} \{regs}, \{t2_addr(rn_, offset)}",
      )
    } else {
      let suffix = if p_bit { "_PRE" } else { "_POST" }
      let text = if p_bit {
        "\{m}\{c} \{regs}, [\{t_rn(rn_)}, \{otext}]!"
      } else {
        "\{m}\{c} \{regs}, [\{t_rn(rn_)}], \{otext}"
      }
      let ops = if load {
        [t_gpr(rt), t_gpr(rt2), t_gpr(rn_), t_gpr(rn_), t_imm(offset), ..p]
      } else {
        [t_gpr(rn_), t_gpr(rt), t_gpr(rt2), t_gpr(rn_), t_imm(offset), ..p]
      }
      t32((if load { "t2LDRD" } else { "t2STRD" }) + suffix, ops, text)
    }
  } else if !add {
    // LDREX/STREX (word, with an offset)
    if load {
      guard rt2 == 15 else { return None }
      t32(
        "t2LDREX",
        [t_gpr(rt), t_gpr(rn_), t_imm(imm8), ..p],
        "ldrex\{c} \{t_rn(rt)}, \{t2_addr(rn_, imm8 * 4)}",
      )
    } else {
      t32(
        "t2STREX",
        [t_gpr(rt2), t_gpr(rt), t_gpr(rn_), t_imm(imm8), ..p],
        "strex\{c} \{t_rn(rt2)}, \{t_rn(rt)}, \{t2_addr(rn_, imm8 * 4)}",
      )
    }
  } else {
    let op3 = t32_bits(h2, 4, 4)
    let rd = t32_bits(h2, 0, 4)
    if load && op3 <= 1 {
      // TBB/TBH
      guard t32_bits(h2, 5, 11) == 0b11110000000 else { return None }
      let h = op3 == 1
      t32(
        if h {
          "t2TBH"
        } else {
          "t2TBB"
        },
        [t_gpr(rn_), t_gpr(rd), ..p],
        if h {
          "tbh\{c} [\{t_rn(rn_)}, \{t_rn(rd)}, lsl #1]"
        } else {
          "tbb\{c} [\{t_rn(rn_)}, \{t_rn(rd)}]"
        },
      )
    } else {
      let size = match op3 {
        4 => "B"
        5 => "H"
        7 => "D"
        _ => return None
      }
      if load {
        guard rd == 15 else { return None }
        if size == "D" {
          t32(
            "t2LDREXD",
            [t_gpr(rt), t_gpr(rt2), t_gpr(rn_), ..p],
            "ldrexd\{c} \{t_rn(rt)}, \{t_rn(rt2)}, [\{t_rn(rn_)}]",
          )
        } else {
          guard rt2 == 15 else { return None }
          t32(
            "t2LDREX" + size,
            [t_gpr(rt), t_gpr(rn_), ..p],
            "ldrex\{size.to_lower()}\{c} \{t_rn(rt)}, [\{t_rn(rn_)}]",
          )
        }
      } else if size == "D" {
        t32(
          "t2STREXD",
          [t_gpr(rd), t_gpr(rt), t_gpr(rt2), t_gpr(rn_), ..p],
          "strexd\{c} \{t_rn(rd)}, \{t_rn(rt)}, \{t_rn(rt2)}, [\{t_rn(rn_)}]",
        )
      } else {
        guard rt2 == 15 else { return None }
        t32(
          "t2STREX" + size,
          [t_gpr(rd), t_gpr(rt), t_gpr(rn_), ..p],
          "strex\{size.to_lower()}\{c} \{t_rn(rd)}, \{t_rn(rt)}, [\{t_rn(rn_)}]",
        )
      }
    }
  }
}

///|
/// The name suffix of a single load/store of `size` (0 byte, 1 halfword,
/// 2 word), signed or not.
fn t2_size_name(size : Int, signed : Bool) -> String {
  match (size, signed) {
    (0, false) => "B"
    (0, true) => "SB"
    (1, false) => "H"
    (1, true) => "SH"
    _ => ""
  }
}

///|
/// The single loads and stores (`t2LDR*`, `t2STR*`).
fn t2_single(
  h1 : Int,
  h2 : Int,
  cond : Int,
  load : Bool,
  size : Int,
  signed : Bool,
) -> T32Insn? {
  let rn_ = t32_bits(h1, 0, 4)
  let rt = t32_bits(h2, 12, 4)
  let p = @arm.mc_pred(cond)
  let c = @arm.cond_asm(cond)
  let sz = t2_size_name(size, signed)
  let base = (if load { "t2LDR" } else { "t2STR" }) + sz
  let m = (if load { "ldr" } else { "str" }) + sz.to_lower()
  if load && rn_ == 15 {
    // literal
    let offset = t2_offset(t32_bit(h1, 7), t32_bits(h2, 0, 12))
    return t32(
      base + "pci",
      [t_gpr(rt), t_imm(offset), ..p],
      "\{m}\{c}.w \{t_rn(rt)}, [pc, \{t2_offset_text(offset)}]",
    )
  }
  if t32_bit(h1, 7) {
    let imm12 = t32_bits(h2, 0, 12)
    t32(
      base + "i12",
      [t_gpr(rt), t_gpr(rn_), t_imm(imm12), ..p],
      "\{m}\{c}.w \{t_rn(rt)}, \{t2_addr(rn_, imm12)}",
    )
  } else if t32_bit(h2, 11) {
    let imm8 = t32_bits(h2, 0, 8)
    let add = t32_bit(h2, 9)
    let offset = t2_offset(add, imm8)
    let otext = t2_offset_text(offset)
    match (t32_bit(h2, 10), t32_bit(h2, 8)) {
      (true, false) => {
        // negative offset (the unprivileged `T` forms are not supported)
        guard !add else { return None }
        t32(
          base + "i8",
          [t_gpr(rt), t_gpr(rn_), t_imm(offset), ..p],
          "\{m}\{c} \{t_rn(rt)}, [\{t_rn(rn_)}, \{otext}]",
        )
      }
      (pre, true) => {
        let ops = if load {
          [t_gpr(rt), t_gpr(rn_), t_gpr(rn_), t_imm(offset), ..p]
        } else {
          [t_gpr(rn_), t_gpr(rt), t_gpr(rn_), t_imm(offset), ..p]
        }
        let text = if pre {
          "\{m}\{c} \{t_rn(rt)}, [\{t_rn(rn_)}, \{otext}]!"
        } else {
          "\{m}\{c} \{t_rn(rt)}, [\{t_rn(rn_)}], \{otext}"
        }
        t32(base + (if pre { "_PRE" } else { "_POST" }), ops, text)
      }
      _ => None
    }
  } else if t32_bits(h2, 6, 6) == 0 {
    let rm = t32_bits(h2, 0, 4)
    let amount = t32_bits(h2, 4, 2)
    let shift = if amount == 0 { "" } else { ", lsl #\{amount}" }
    t32(
      base + "s",
      [t_gpr(rt), t_gpr(rn_), t_gpr(rm), t_imm(amount), ..p],
      "\{m}\{c}.w \{t_rn(rt)}, [\{t_rn(rn_)}, \{t_rn(rm)}\{shift}]",
    )
  } else {
    None
  }
}

///|
/// Store single data item.
fn t2_store(h1 : Int, h2 : Int, cond : Int) -> T32Insn? {
  let size = t32_bits(h1, 5, 2)
  guard size != 3 && t32_bits(h1, 0, 4) != 15 else { return None }
  t2_single(h1, h2, cond, false, size, false)
}

///|
/// Load single data item (the memory hints are not supported).
fn t2_load(h1 : Int, h2 : Int, cond : Int) -> T32Insn? {
  let size = t32_bits(h1, 5, 2)
  let signed = t32_bit(h1, 8)
  guard size != 3 && !(size == 2 && signed) else { return None }
  // loads of bytes and halfwords to PC, other than the pre- and
  // post-indexed ones, are the preload hints
  let writeback = !t32_bit(h1, 7) &&
    t32_bits(h1, 0, 4) != 15 &&
    t32_bit(h2, 11) &&
    t32_bit(h2, 8)
  if size != 2 && t32_bits(h2, 12, 4) == 15 && !writeback {
    guard size == 0 else { return None }
    return t2_preload(h1, h2, cond, signed)
  }
  t2_single(h1, h2, cond, true, size, signed)
}

///|
/// The preload hints `PLD` and (`signed`) `PLI`.
fn t2_preload(h1 : Int, h2 : Int, cond : Int, signed : Bool) -> T32Insn? {
  let rn_ = t32_bits(h1, 0, 4)
  let p = @arm.mc_pred(cond)
  let (base, m) = if signed { ("t2PLI", "pli") } else { ("t2PLD", "pld") }
  if rn_ == 15 {
    let offset = t2_offset(t32_bit(h1, 7), t32_bits(h2, 0, 12))
    t32(
      base + "pci",
      [t_imm(offset), ..p],
      "\{m} [pc, \{t2_offset_text(offset)}]",
    )
  } else if t32_bit(h1, 7) {
    let imm12 = t32_bits(h2, 0, 12)
    t32(
      base + "i12",
      [t_gpr(rn_), t_imm(imm12), ..p],
      "\{m} \{t2_addr(rn_, imm12)}",
    )
  } else if t32_bits(h2, 8, 4) == 0b1100 {
    let offset = t2_offset(false, t32_bits(h2, 0, 8))
    t32(
      base + "i8",
      [t_gpr(rn_), t_imm(offset), ..p],
      "\{m} [\{t_rn(rn_)}, \{t2_offset_text(offset)}]",
    )
  } else if t32_bits(h2, 6, 6) == 0 {
    let rm = t32_bits(h2, 0, 4)
    let amount = t32_bits(h2, 4, 2)
    let shift = if amount == 0 { "" } else { ", lsl #\{amount}" }
    t32(
      base + "s",
      [t_gpr(rn_), t_gpr(rm), t_imm(amount), ..p],
      "\{m} [\{t_rn(rn_)}, \{t_rn(rm)}\{shift}]",
    )
  } else {
    None
  }
}

///|
/// Data processing (register): shifts by a register, extensions, byte
/// reversals and count leading zeros.
fn t2_dp_register(h1 : Int, h2 : Int, cond : Int) -> T32Insn? {
  guard t32_bits(h2, 12, 4) == 15 else { return None }
  let op1 = t32_bits(h1, 4, 4)
  let rn_ = t32_bits(h1, 0, 4)
  let rd = t32_bits(h2, 8, 4)
  let rm = t32_bits(h2, 0, 4)
  let op2 = t32_bits(h2, 4, 4)
  let p = @arm.mc_pred(cond)
  let c = @arm.cond_asm(cond)
  if op1 >> 3 == 0 && op2 == 0 {
    let s = t32_bit(h1, 4)
    let (name, m) = match op1 >> 1 {
      0 => ("t2LSLrr", "lsl")
      1 => ("t2LSRrr", "lsr")
      2 => ("t2ASRrr", "asr")
      _ => ("t2RORrr", "ror")
    }
    t32(
      name,
      [t_gpr(rd), t_gpr(rn_), t_gpr(rm), ..p, @arm.mc_cc_out(s)],
      "\{m}\{if s { "s" } else { "" }}\{c}.w \{t_rn(rd)}, \{t_rn(rn_)}, \{t_rn(rm)}",
    )
  } else if op1 <= 5 && op2 >> 3 == 1 {
    let rot = t32_bits(h2, 4, 2)
    let (sign, size) = match op1 {
      0 => ("S", "H")
      1 => ("U", "H")
      4 => ("S", "B")
      5 => ("U", "B")
      _ => return None
    }
    let rot_text = if rot == 0 { "" } else { ", ror #\{rot * 8}" }
    if rn_ == 15 {
      let name = sign + "XT" + size
      t32(
        "t2" + name,
        [t_gpr(rd), t_gpr(rm), t_imm(rot), ..p],
        "\{name.to_lower()}\{c}.w \{t_rn(rd)}, \{t_rn(rm)}\{rot_text}",
      )
    } else {
      let name = sign + "XTA" + size
      t32(
        "t2" + name,
        [t_gpr(rd), t_gpr(rn_), t_gpr(rm), t_imm(rot), ..p],
        "\{name.to_lower()}\{c} \{t_rn(rd)}, \{t_rn(rn_)}, \{t_rn(rm)}\{rot_text}",
      )
    }
  } else if op1 >> 2 == 2 && op2 >> 2 == 2 {
    guard rn_ == rm else { return None }
    let name = match (op1 & 3, op2 & 3) {
      (1, 0) => "REV"
      (1, 1) => "REV16"
      (1, 2) => "RBIT"
      (1, 3) => "REVSH"
      (3, 0) => "CLZ"
      _ => return None
    }
    t32(
      "t2" + name,
      [t_gpr(rd), t_gpr(rm), ..p],
      "\{name.to_lower()}\{c}.w \{t_rn(rd)}, \{t_rn(rm)}",
    )
  } else {
    None
  }
}

///|
/// Multiply, multiply accumulate and the signed halfword multiplies.
fn t2_multiply(h1 : Int, h2 : Int, cond : Int) -> T32Insn? {
  let op1 = t32_bits(h1, 4, 3)
  let rn_ = t32_bits(h1, 0, 4)
  let ra = t32_bits(h2, 12, 4)
  let rd = t32_bits(h2, 8, 4)
  let op2 = t32_bits(h2, 4, 2)
  let rm = t32_bits(h2, 0, 4)
  guard t32_bits(h2, 6, 2) == 0 else { return None }
  let p = @arm.mc_pred(cond)
  let c = @arm.cond_asm(cond)
  let three = (name : String) => {
    t32(
      "t2" + name,
      [t_gpr(rd), t_gpr(rn_), t_gpr(rm), ..p],
      "\{name.to_lower()}\{c} \{t_rn(rd)}, \{t_rn(rn_)}, \{t_rn(rm)}",
    )
  }
  let four = (name : String) => {
    t32(
      "t2" + name,
      [t_gpr(rd), t_gpr(rn_), t_gpr(rm), t_gpr(ra), ..p],
      "\{name.to_lower()}\{c} \{t_rn(rd)}, \{t_rn(rn_)}, \{t_rn(rm)}, \{t_rn(ra)}",
    )
  }
  let x = if t32_bit(h2, 5) { "T" } else { "B" }
  let y = if t32_bit(h2, 4) { "T" } else { "B" }
  match (op1, op2) {
    (0, 0) => if ra == 15 { three("MUL") } else { four("MLA") }
    (0, 1) => four("MLS")
    (1, _) =>
      if ra == 15 {
        three("SMUL" + x + y)
      } else {
        four("SMLA" + x + y)
      }
    (2, 0 | 1) => {
      let xs = if op2 == 1 { "X" } else { "" }
      if ra == 15 {
        three("SMUAD" + xs)
      } else {
        four("SMLAD" + xs)
      }
    }
    (3, 0 | 1) => if ra == 15 { three("SMULW" + y) } else { four("SMLAW" + y) }
    _ => None
  }
}

///|
/// Long multiply, long multiply accumulate and divide.
fn t2_long_multiply(h1 : Int, h2 : Int, cond : Int) -> T32Insn? {
  let op1 = t32_bits(h1, 4, 3)
  let rn_ = t32_bits(h1, 0, 4)
  let lo = t32_bits(h2, 12, 4)
  let hi = t32_bits(h2, 8, 4)
  let op2 = t32_bits(h2, 4, 4)
  let rm = t32_bits(h2, 0, 4)
  let p = @arm.mc_pred(cond)
  let c = @arm.cond_asm(cond)
  match (op1, op2) {
    (1 | 3, 15) => {
      guard lo == 15 else { return None }
      let name = if op1 == 1 { "SDIV" } else { "UDIV" }
      t32(
        "t2" + name,
        [t_gpr(hi), t_gpr(rn_), t_gpr(rm), ..p],
        "\{name.to_lower()}\{c} \{t_rn(hi)}, \{t_rn(rn_)}, \{t_rn(rm)}",
      )
    }
    (0 | 2 | 4 | 6, 0) => {
      let (name, acc) = match op1 {
        0 => ("SMULL", false)
        2 => ("UMULL", false)
        4 => ("SMLAL", true)
        _ => ("UMLAL", true)
      }
      let extra = if acc { [t_gpr(lo), t_gpr(hi)] } else { [] }
      t32(
        "t2" + name,
        [t_gpr(lo), t_gpr(hi), t_gpr(rn_), t_gpr(rm), ..extra, ..p],
        "\{name.to_lower()}\{c} \{t_rn(lo)}, \{t_rn(hi)}, \{t_rn(rn_)}, \{t_rn(rm)}",
      )
    }
    _ => None
  }
}

///|
/// The Thumb-2 opcodes printed with the `.w` width qualifier by LLVM
/// (those with a 16-bit counterpart; observed from LLVM 22).
let t2_wide_names : Map[String, Unit] = {
  "t2ADCrr": (),
  "t2ADCrs": (),
  "t2ADDri": (),
  "t2ADDrr": (),
  "t2ADDrs": (),
  "t2ADDspImm": (),
  "t2ADR": (),
  "t2ANDrr": (),
  "t2ANDrs": (),
  "t2ASRri": (),
  "t2ASRrr": (),
  "t2B": (),
  "t2BICrr": (),
  "t2BICrs": (),
  "t2Bcc": (),
  "t2CMNri": (),
  "t2CMNzrr": (),
  "t2CMNzrs": (),
  "t2CMPri": (),
  "t2CMPrr": (),
  "t2CMPrs": (),
  "t2EORrr": (),
  "t2EORrs": (),
  "t2HINT": (),
  "t2LDMIA": (),
  "t2LDMIA_UPD": (),
  "t2LDRBi12": (),
  "t2LDRBpci": (),
  "t2LDRBs": (),
  "t2LDRHi12": (),
  "t2LDRHpci": (),
  "t2LDRHs": (),
  "t2LDRSBi12": (),
  "t2LDRSBpci": (),
  "t2LDRSBs": (),
  "t2LDRSHi12": (),
  "t2LDRSHpci": (),
  "t2LDRSHs": (),
  "t2LDRi12": (),
  "t2LDRpci": (),
  "t2LDRs": (),
  "t2LSLri": (),
  "t2LSLrr": (),
  "t2LSRri": (),
  "t2LSRrr": (),
  "t2MOVi": (),
  "t2MOVr": (),
  "t2MVNr": (),
  "t2MVNs": (),
  "t2ORRrr": (),
  "t2ORRrs": (),
  "t2REV": (),
  "t2REV16": (),
  "t2REVSH": (),
  "t2RORri": (),
  "t2RORrr": (),
  "t2RSBri": (),
  "t2SBCrr": (),
  "t2SBCrs": (),
  "t2STMIA": (),
  "t2STMIA_UPD": (),
  "t2STRBi12": (),
  "t2STRBs": (),
  "t2STRHi12": (),
  "t2STRHs": (),
  "t2STRi12": (),
  "t2STRs": (),
  "t2SUBri": (),
  "t2SUBspImm": (),
  "t2SUBrr": (),
  "t2SUBrs": (),
  "t2SXTB": (),
  "t2SXTH": (),
  "t2TEQri": (),
  "t2TEQrr": (),
  "t2TEQrs": (),
  "t2TSTri": (),
  "t2TSTrr": (),
  "t2TSTrs": (),
  "t2UDF": (),
  "t2UXTB": (),
  "t2UXTH": (),
}

///|
/// The assembly of a Thumb-2 instruction with the `.w` qualifier on its
/// mnemonic exactly when LLVM prints one: for the opcodes of
/// `t2_wide_names`, and for `push.w` (`t2STMDB_UPD` of `SP`).
fn t2_width(d : T32Insn) -> T32Insn {
  let (mnemonic, rest) = match d.text.find(" ") {
    Some(i) => (d.text[:i].to_owned(), d.text[i:].to_owned())
    None => (d.text, "")
  }
  let base = if mnemonic.has_suffix(".w") {
    mnemonic[:mnemonic.length() - 2].to_owned()
  } else {
    mnemonic
  }
  let wide = t2_wide_names.contains(d.name) ||
    (d.name == "t2STMDB_UPD" && base.has_prefix("push"))
  { ..d, text: (if wide { base + ".w" } else { base }) + rest, }
}

///|
/// Decodes the Thumb instruction at the start of `bytes` loaded at `addr`.
/// Halfwords are little-endian unless `big_endian` is set. With `it`, the
/// IT state is used for (and updated by) the instruction: instructions in
/// an IT block get the predicate of the block.
pub fn decode_t32(
  bytes : BytesView,
  addr? : UInt64 = 0,
  big_endian? : Bool = false,
  it? : ItBlock,
) -> @mc.Decoded {
  if bytes.length() < 2 {
    return Truncated
  }
  let half = (i : Int) => {
    let a = bytes[i].to_int()
    let b = bytes[i + 1].to_int()
    if big_endian {
      (a << 8) | b
    } else {
      (b << 8) | a
    }
  }
  let h1 = half(0)
  let wide = h1 >> 11 >= 0b11101
  let size = if wide { 4 } else { 2 }
  if bytes.length() < size {
    return Truncated
  }
  let it_cond = match it {
    Some(it) => it.current(addr)
    None => None
  }
  let (cond, in_it) = match it_cond {
    Some(cond) => (cond, true)
    None => (14, false)
  }
  let decoded = if wide {
    let h2 = half(2)
    match t32_decode(h1, h2, cond) {
      Some(d) => Some(t2_width(d))
      None =>
        // VFP, NEON and coprocessor instructions (the A32 tables)
        @arm.decode_t32_ext(((h1 << 16) | h2).reinterpret_as_uint(), cond).map(d => {
          name: d.0,
          ops: d.1,
          text: d.2,
        })
    }
  } else {
    t16_decode(h1, cond, in_it)
  }
  match it {
    Some(it) => {
      if in_it {
        it.conds.pop() |> ignore
      }
      it.next = addr + size.to_uint64()
      match decoded {
        Some({ name: "t2IT", ops: [Imm(firstcond), Imm(mask)], .. }) =>
          it.start(firstcond.to_int(), mask.to_int())
        _ => ()
      }
    }
    None => ()
  }
  match decoded {
    None => Invalid(size~)
    Some(d) =>
      Decoded(
        @mc.Insn::create(
          d.name,
          d.ops,
          addr~,
          size~,
          assembly=d.text,
          encoding=@core_theory.Language::llvm_t32(),
          kinds=@arm.llvm_kinds(d.name, d.ops),
          raw=bytes[:size].to_owned(),
        ),
      )
  }
}

///|
/// Name of the T32 decoder installed by `register_decoder`.
pub let t32_decoder_name : String = "arm-t32"

///|
/// Whether the T32 decoder applies to `ctx`: 32-bit targets of the ARM
/// family decoded as Thumb (`llvm-thumb`) instructions.
pub fn t32_decoder_accepts(ctx : @mc.Context) -> Bool {
  ctx.belongs(@core_theory.Target::arm_family()) &&
  ctx.target.bits() == 32 &&
  ctx.encoding == @core_theory.Language::llvm_t32()
}

///|
/// The T32 decoder (see `decode_t32`). The decoder keeps the IT state of
/// the instructions it decodes in sequence; halfwords are read in the
/// byte order of the target.
pub fn t32_decoder() -> @mc.Decoder {
  let it = ItBlock::new()
  @mc.Decoder::create(t32_decoder_name, accepts=t32_decoder_accepts, decode=(
    ctx,
    bytes,
    addr,
  ) => {
    decode_t32(
      bytes,
      addr~,
      big_endian=ctx.target.endianness() is BigEndian,
      it~,
    )
  })
}

///|
/// Registers the T32 decoder with `@mc.register_decoder`. Idempotent: the
/// decoder is replaced by name.
pub fn register_decoder() -> Unit {
  @mc.register_decoder(t32_decoder())
}
