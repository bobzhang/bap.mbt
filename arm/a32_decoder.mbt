// A native decoder of the A32 (ARMv7-A) instruction set producing the
// instructions of the LLVM ARM disassembler (upstream decodes ARM code
// with LLVM MC): LLVM opcode names (`ADDrsi`, `LDR_PRE_IMM`, ...) and
// operand lists as LLVM builds them, which is what the ARM lifter of this
// package (and the Lisp semantics) consume:
//
// - registers `R0`..`R12`, `SP`, `LR`, `PC`, `CPSR`, and `Nil` for LLVM's
//   `NoRegister`;
// - a `pred` operand is two operands, the condition code and `CPSR` (or
//   `Nil` when the condition is `AL`); the optional `S` bit is the `cc_out`
//   operand, `CPSR` or `Nil`;
// - modified immediates (`mod_imm`) are the undecoded 12-bit fields;
//   shifted register operands are packed as `ARM_AM::getSORegOpc`
//   (`shift | amount << 3`); addressing mode 2 offsets as
//   `ARM_AM::getAM2Opc` (`amount | sub << 12 | shift << 13 | index << 16`),
//   addressing mode 3 offsets as `ARM_AM::getAM3Opc` (`imm8 | sub << 8 |
//   index << 9`, the index mode 1 for pre- and 2 for post-indexing), 12-bit
//   offsets and bit field masks as the 32-bit patterns LLVM computes in
//   unsigned arithmetic (`#-4` is `4294967292`, `#-0` is `2147483648`);
//   branch targets are byte offsets relative to the `PC` (the address plus
//   8); `BL` has no predicate operands (`BL_pred` has);
// - the kinds are LLVM's `MCInstrDesc` properties of the opcode (see
//   `llvm_kinds`);
// - the assembly is LLVM's (`printInstruction` with its aliases, e.g.
//   `lsl r0, r1, #2` for `MOVsi`, `pop`/`push`, `#bits, #rot` modified
//   immediates);
// - the encodings LLVM reports as `SoftFail` (should-be-zero/one fields
//   set) are valid instructions, as for upstream BAP.
//
// The decoder covers the instructions of the ARM lifter (`Insn::all`) and
// a few related ones LLVM decodes in the same encoding space (e.g. `CLZ`,
// `PKHBT`, the halfword multiplies, `SWP`, the barriers, `CPS`, the
// `sysLDM`/`sysSTM` forms); the other encodings LLVM decodes (VFP, NEON,
// coprocessor, media, saturating and parallel arithmetic, ...) are decoded
// by the tables of `decode_ext.mbt`. `decode_llvm_test.mbt` and
// `decode_llvm_ext_test.mbt` hold samples verified against LLVM 22.

///|
fn a32_field(w : UInt, lo : Int, len : Int) -> Int {
  ((w >> lo) & ((1U << len) - 1)).reinterpret_as_int()
}

///|
fn a32_bit(w : UInt, n : Int) -> Bool {
  ((w >> n) & 1) == 1
}

///|
/// A decoded instruction before it is packed into an `@mc.Insn`.
priv struct A32Insn {
  name : String
  ops : Array[@mc.Op]
  text : String
}

///|
fn decoded(name : String, ops : Array[@mc.Op], text : String) -> A32Insn? {
  Some({ name, ops, text, })
}

///|
/// The value of a 12-bit offset as LLVM's `DecodeAddrModeImm12Operand`
/// produces it: negative when `U` is clear, `INT32_MIN` for `#-0`.
fn a32_offset12(add : Bool, imm : Int) -> Int {
  if add {
    imm
  } else if imm == 0 {
    -2147483648
  } else {
    -imm
  }
}

///|
fn a32_offset_asm(offset : Int) -> String {
  if offset == -2147483648 {
    "#-0"
  } else {
    imm_asm(offset)
  }
}

///|
/// The address `[rn, #offset]` of a 12-bit offset, as LLVM's
/// `printAddrModeImm12Operand`: a zero offset is only printed for the
/// pre-indexed forms.
fn a32_offset12_addr(
  rn : Int,
  offset : Int,
  always_imm0? : Bool = false,
) -> String {
  if offset == 0 && !always_imm0 {
    "[\{gpr_asm(rn)}]"
  } else {
    "[\{gpr_asm(rn)}, \{a32_offset_asm(offset)}]"
  }
}

///|
/// `ARM_AM::getAM2Opc`.
fn am2_opc(add : Bool, amount : Int, shift : Int, index : Int) -> Int {
  amount | ((if add { 0 } else { 1 }) << 12) | (shift << 13) | (index << 16)
}

///|
/// `ARM_AM::getAM3Opc`: the index mode `index` is 0 for the offset
/// forms, 1 for the pre-indexed and 2 for the post-indexed ones.
fn am3_opc(add : Bool, imm8 : Int, index? : Int = 0) -> Int {
  imm8 | ((if add { 0 } else { 1 }) << 8) | (index << 9)
}

///|
fn a32_sign(add : Bool) -> String {
  if add {
    ""
  } else {
    "-"
  }
}

///|
/// Decodes the A32 instruction word `word` located at `addr`. The raw
/// bytes of the instruction are the little-endian bytes of the word unless
/// `raw` is given.
pub fn decode_a32_word(
  word : UInt,
  addr? : UInt64 = 0,
  raw? : Bytes,
) -> @mc.Insn? {
  let cond = a32_field(word, 28, 4)
  let decoded = if cond == 15 {
    a32_unconditional(word)
  } else {
    match a32_field(word, 25, 3) {
      0 => a32_group0(word, cond)
      1 => a32_dp_imm(word, cond)
      2 => a32_ldst_imm(word, cond)
      3 =>
        if a32_bit(word, 4) {
          a32_media(word, cond)
        } else {
          a32_ldst_reg(word, cond)
        }
      4 => a32_ldm_stm(word, cond)
      5 => a32_branch(word, cond)
      7 if a32_bit(word, 24) =>
        decoded(
          "SVC",
          [mc_imm(a32_field(word, 0, 24)), ..mc_pred(cond)],
          "svc\{cond_asm(cond)} #\{a32_field(word, 0, 24)}",
        )
      _ => None
    }
  }
  let decoded = match decoded {
    None => a32_ext(word)
    d => d
  }
  let raw = match raw {
    Some(raw) => raw
    None => Bytes::makei(4, i => (word >> (8 * i)).to_byte())
  }
  decoded.map(d => {
    @mc.Insn::create(
      d.name,
      d.ops,
      addr~,
      size=4,
      assembly=d.text,
      encoding=@core_theory.Language::llvm_a32(),
      kinds=llvm_kinds(d.name, d.ops),
      raw~,
    )
  })
}

///|
/// Decodes the A32 instruction at the start of `bytes` loaded at `addr`.
/// Instruction words are little-endian unless `big_endian` is set.
pub fn decode_a32(
  bytes : BytesView,
  addr? : UInt64 = 0,
  big_endian? : Bool = false,
) -> @mc.Decoded {
  if bytes.length() < 4 {
    return Truncated
  }
  let b = (i : Int) => bytes[if big_endian { 3 - i } else { i }].to_uint()
  let word = b(0) | (b(1) << 8) | (b(2) << 16) | (b(3) << 24)
  match decode_a32_word(word, addr~, raw=bytes[:4].to_owned()) {
    Some(insn) => Decoded(insn)
    None => Invalid(size=4)
  }
}

///|
/// Instructions with the condition field `0b1111`.
fn a32_unconditional(w : UInt) -> A32Insn? {
  if a32_field(w, 25, 3) == 5 {
    // BLX (immediate): always switches to Thumb
    let offset = sign_extend(
      (a32_field(w, 0, 24) << 2) | (a32_field(w, 24, 1) << 1),
      26,
    )
    decoded("BLXi", [mc_imm(offset)], "blx \{imm_asm(offset)}")
  } else if (w & 0xFF70F000) == 0xF550F000 {
    let rn = a32_field(w, 16, 4)
    let offset = a32_offset12(a32_bit(w, 23), a32_field(w, 0, 12))
    decoded(
      "PLDi12",
      [mc_gpr(rn), mc_imm_u32(offset)],
      "pld \{a32_offset12_addr(rn, offset)}",
    )
  } else if (w & 0xFFFFFF00) == 0xF57FF000 {
    let opt = a32_field(w, 0, 4)
    let kind = a32_field(w, 4, 4)
    let name = match kind {
      4 => "DSB"
      5 => "DMB"
      6 => "ISB"
      _ => return None
    }
    decoded(name, [mc_imm(opt)], barrier_asm(kind, opt, ""))
  } else if (w & 0xFFF1FE20) == 0xF1000000 &&
    a32_field(w, 18, 2) != 1 &&
    (a32_bit(w, 17) || a32_field(w, 0, 5) == 0) {
    // `CPS` in its canonical encodings (LLVM's decoder table accepts some
    // other encodings, as `SoftFail`s, depending on unrelated bits)
    let imod = a32_field(w, 18, 2)
    let iflags = a32_field(w, 6, 3)
    let mode = a32_field(w, 0, 5)
    let flags = StringBuilder()
    if (iflags & 4) != 0 {
      flags.write_char('a')
    }
    if (iflags & 2) != 0 {
      flags.write_char('i')
    }
    if (iflags & 1) != 0 {
      flags.write_char('f')
    }
    if iflags == 0 {
      flags.write_string("none")
    }
    let effect = if imod == 2 { "ie" } else { "id" }
    match (imod, a32_bit(w, 17)) {
      (0, _) => decoded("CPS1p", [mc_imm(mode)], "cps #\{mode}")
      (_, true) =>
        decoded(
          "CPS3p",
          [mc_imm(imod), mc_imm(iflags), mc_imm(mode)],
          "cps\{effect} \{flags.to_string()}, #\{mode}",
        )
      _ =>
        decoded(
          "CPS2p",
          [mc_imm(imod), mc_imm(iflags)],
          "cps\{effect} \{flags.to_string()}",
        )
    }
  } else {
    None
  }
}

///|
/// Instructions with bits 27..25 equal to `000`: data processing with
/// register operands, multiplies, synchronization primitives, the extra
/// load/store instructions and the miscellaneous instructions.
fn a32_group0(w : UInt, cond : Int) -> A32Insn? {
  let op = a32_field(w, 20, 5)
  if a32_bit(w, 7) && a32_bit(w, 4) {
    if a32_field(w, 5, 2) == 0 {
      if a32_bit(w, 24) {
        a32_sync(w, cond)
      } else {
        a32_multiply(w, cond)
      }
    } else {
      a32_extra_ldst(w, cond)
    }
  } else if (op & 0b11001) == 0b10000 {
    if a32_bit(w, 7) {
      a32_halfword_multiply(w, cond)
    } else {
      a32_misc(w, cond)
    }
  } else {
    a32_dp_reg(w, cond)
  }
}

///|
let a32_dp_mnemonics : ReadOnlyArray[String] = [
  "AND", "EOR", "SUB", "RSB", "ADD", "ADC", "SBC", "RSC", "TST", "TEQ", "CMP", "CMN",
  "ORR", "MOV", "BIC", "MVN",
]

///|
/// The LLVM name of a data-processing instruction with the opcode `opc`
/// and the operand form `form` (0: immediate, 1: register, 2: register
/// shifted by an immediate, 3: register shifted by a register).
fn a32_dp_name(opc : Int, form : Int) -> String {
  let base = a32_dp_mnemonics[opc]
  match opc {
    13 | 15 => base + ["i", "r", "si", "sr"][form]
    11 => ["CMNri", "CMNzrr", "CMNzrsi", "CMNzrsr"][form]
    _ => base + ["ri", "rr", "rsi", "rsr"][form]
  }
}

///|
/// Builds a data-processing instruction from its opcode, form and the
/// operands of its second (shifter) operand.
fn a32_dp(
  w : UInt,
  cond : Int,
  opc : Int,
  form : Int,
  shifter : Array[@mc.Op],
  shifter_asm : String,
  mov_alias? : (String, String),
) -> A32Insn? {
  let s = a32_bit(w, 20)
  let rn = a32_field(w, 16, 4)
  let rd = a32_field(w, 12, 4)
  let name = a32_dp_name(opc, form)
  let mnemonic = a32_dp_mnemonics[opc].to_lower()
  if opc >= 8 && opc <= 11 {
    // comparisons and tests: no destination, always set the flags (a
    // non-zero `Rd` field is a `SoftFail`, a valid instruction for BAP)
    decoded(
      name,
      [mc_gpr(rn), ..shifter, ..mc_pred(cond)],
      "\{mnemonic}\{cond_asm(cond)} \{gpr_asm(rn)}, \{shifter_asm}",
    )
  } else {
    let flags = if s { "s" } else { "" }
    if opc == 13 || opc == 15 {
      // a non-zero `Rn` field: LLVM rejects the moves (but decodes the
      // register form as `MOVr_TC` when the registers are in its `tcGPR`
      // class: `R0`..`R3`, `R12`) and accepts the `MVN` register forms
      let tc_gpr = (n : Int) => n <= 3 || n == 12
      let name = match (opc, form) {
        _ if rn == 0 => name
        (13, 1) if tc_gpr(rd) && tc_gpr(a32_field(w, 0, 4)) => "MOVr_TC"
        (13, _) | (15, 0) => return None
        _ => name
      }
      // LLVM prints the shifted moves as shifts: `lsl rd, rm, #2`
      let (mnemonic, shifter_asm) = match (opc, mov_alias) {
        (13, Some(shift_alias)) => shift_alias
        _ => (mnemonic, shifter_asm)
      }
      decoded(
        name,
        [mc_gpr(rd), ..shifter, ..mc_pred(cond), mc_cc_out(s)],
        "\{mnemonic}\{flags}\{cond_asm(cond)} \{gpr_asm(rd)}, \{shifter_asm}",
      )
    } else {
      decoded(
        name,
        [mc_gpr(rd), mc_gpr(rn), ..shifter, ..mc_pred(cond), mc_cc_out(s)],
        "\{mnemonic}\{flags}\{cond_asm(cond)} \{gpr_asm(rd)}, \{gpr_asm(rn)}, \{shifter_asm}",
      )
    }
  }
}

///|
/// Data processing with a register, a register shifted by an immediate,
/// or a register shifted by a register as the second operand.
fn a32_dp_reg(w : UInt, cond : Int) -> A32Insn? {
  let opc = a32_field(w, 21, 4)
  let rm = a32_field(w, 0, 4)
  let typ = a32_field(w, 5, 2)
  if a32_bit(w, 4) {
    // register-shifted register (bit 7 is clear here)
    let rs = a32_field(w, 8, 4)
    let shift = shift_opc_of_type(typ, 1)
    a32_dp(
      w,
      cond,
      opc,
      3,
      [mc_gpr(rm), mc_gpr(rs), mc_imm(shift)],
      "\{gpr_asm(rm)}, \{shift_opc_asm(shift)} \{gpr_asm(rs)}",
      mov_alias=(shift_opc_asm(shift), "\{gpr_asm(rm)}, \{gpr_asm(rs)}"),
    )
  } else {
    let imm5 = a32_field(w, 7, 5)
    if imm5 == 0 && typ == 0 {
      a32_dp(w, cond, opc, 1, [mc_gpr(rm)], gpr_asm(rm))
    } else {
      let shift = shift_opc_of_type(typ, imm5)
      a32_dp(
        w,
        cond,
        opc,
        2,
        [mc_gpr(rm), mc_imm(shift | (imm5 << 3))],
        gpr_asm(rm) + shift_imm_asm(shift, imm5),
        mov_alias=(
          shift_opc_asm(shift),
          if shift == 5 {
            gpr_asm(rm)
          } else {
            "\{gpr_asm(rm)}, #\{if imm5 == 0 { 32 } else { imm5 }}"
          },
        ),
      )
    }
  }
}

///|
/// Data processing with a modified immediate, `MOVW`, `MOVT` and the
/// hints.
fn a32_dp_imm(w : UInt, cond : Int) -> A32Insn? {
  let op = a32_field(w, 20, 5)
  let rd = a32_field(w, 12, 4)
  match op {
    0b10000 | 0b10100 => {
      let imm16 = (a32_field(w, 16, 4) << 12) | a32_field(w, 0, 12)
      if op == 0b10000 {
        decoded(
          "MOVi16",
          [mc_gpr(rd), mc_imm(imm16), ..mc_pred(cond)],
          "movw\{cond_asm(cond)} \{gpr_asm(rd)}, #\{imm16}",
        )
      } else {
        decoded(
          "MOVTi16",
          [mc_gpr(rd), mc_gpr(rd), mc_imm(imm16), ..mc_pred(cond)],
          "movt\{cond_asm(cond)} \{gpr_asm(rd)}, #\{imm16}",
        )
      }
    }
    0b10010 if (w & 0x000FFF00) == 0x0000F000 && a32_field(w, 0, 8) < 240 => {
      let hint = a32_field(w, 0, 8)
      let text = match hint {
        0 => "nop"
        1 => "yield"
        2 => "wfe"
        3 => "wfi"
        4 => "sev"
        _ => "hint #\{hint}"
      }
      let text = if hint < 5 {
        text + cond_asm(cond)
      } else {
        "hint\{cond_asm(cond)} #\{hint}"
      }
      decoded("HINT", [mc_imm(hint), ..mc_pred(cond)], text)
    }
    0b10010 | 0b10110 => None
    _ => {
      let opc = a32_field(w, 21, 4)
      let imm12 = a32_field(w, 0, 12)
      // `MOVi` to `PC` and `MSRi` print the value unsigned
      let unsigned = opc == 13 && rd == 15
      a32_dp(w, cond, opc, 0, [mc_imm(imm12)], mod_imm_asm(imm12, unsigned~))
    }
  }
}

///|
/// Load/store word and unsigned byte with an immediate offset.
fn a32_ldst_imm(w : UInt, cond : Int) -> A32Insn? {
  let p = a32_bit(w, 24)
  let add = a32_bit(w, 23)
  let byte = a32_bit(w, 22)
  let wb = a32_bit(w, 21)
  let load = a32_bit(w, 20)
  let rn = a32_field(w, 16, 4)
  let rt = a32_field(w, 12, 4)
  let imm12 = a32_field(w, 0, 12)
  let base = (if load { "LDR" } else { "STR" }) + (if byte { "B" } else { "" })
  let mnemonic = base.to_lower()
  let c = cond_asm(cond)
  if p && !wb {
    let offset = a32_offset12(add, imm12)
    decoded(
      base + "i12",
      [mc_gpr(rt), mc_gpr(rn), mc_imm_u32(offset), ..mc_pred(cond)],
      "\{mnemonic}\{c} \{gpr_asm(rt)}, \{a32_offset12_addr(rn, offset)}",
    )
  } else if p {
    let offset = a32_offset12(add, imm12)
    let ops = if load {
      [mc_gpr(rt), mc_gpr(rn), mc_gpr(rn), mc_imm_u32(offset), ..mc_pred(cond)]
    } else {
      [mc_gpr(rn), mc_gpr(rt), mc_gpr(rn), mc_imm_u32(offset), ..mc_pred(cond)]
    }
    decoded(
      base + "_PRE_IMM",
      ops,
      "\{mnemonic}\{c} \{gpr_asm(rt)}, \{a32_offset12_addr(rn, offset, always_imm0=true)}!",
    )
  } else {
    // post-indexed; with W set, the unprivileged (`T`) variants
    let name = base + (if wb { "T" } else { "" }) + "_POST_IMM"
    let offset = am2_opc(add, imm12, 2, 2)
    let ops = if load {
      [
        mc_gpr(rt),
        mc_gpr(rn),
        mc_gpr(rn),
        mc_nil(),
        mc_imm(offset),
        ..mc_pred(cond),
      ]
    } else {
      [
        mc_gpr(rn),
        mc_gpr(rt),
        mc_gpr(rn),
        mc_nil(),
        mc_imm(offset),
        ..mc_pred(cond),
      ]
    }
    let t = if wb { "t" } else { "" }
    decoded(
      name,
      ops,
      "\{mnemonic}\{t}\{c} \{gpr_asm(rt)}, [\{gpr_asm(rn)}], #\{a32_sign(add)}\{imm12}",
    )
  }
}

///|
/// Load/store word and unsigned byte with a (shifted) register offset.
fn a32_ldst_reg(w : UInt, cond : Int) -> A32Insn? {
  let p = a32_bit(w, 24)
  let add = a32_bit(w, 23)
  let byte = a32_bit(w, 22)
  let wb = a32_bit(w, 21)
  let load = a32_bit(w, 20)
  let rn = a32_field(w, 16, 4)
  let rt = a32_field(w, 12, 4)
  let rm = a32_field(w, 0, 4)
  let imm5 = a32_field(w, 7, 5)
  let shift = shift_opc_of_type(a32_field(w, 5, 2), imm5)
  let base = (if load { "LDR" } else { "STR" }) + (if byte { "B" } else { "" })
  let mnemonic = base.to_lower()
  let c = cond_asm(cond)
  let offset_asm = "\{a32_sign(add)}\{gpr_asm(rm)}\{shift_imm_asm(shift, imm5)}"
  if p && !wb {
    decoded(
      base + "rs",
      [
        mc_gpr(rt),
        mc_gpr(rn),
        mc_gpr(rm),
        mc_imm(am2_opc(add, imm5, shift, 0)),
        ..mc_pred(cond),
      ],
      "\{mnemonic}\{c} \{gpr_asm(rt)}, [\{gpr_asm(rn)}, \{offset_asm}]",
    )
  } else {
    let (name, index, text) = if p {
      (
        base + "_PRE_REG",
        0,
        "\{mnemonic}\{c} \{gpr_asm(rt)}, [\{gpr_asm(rn)}, \{offset_asm}]!",
      )
    } else {
      let t = if wb { "t" } else { "" }
      (
        base + (if wb { "T" } else { "" }) + "_POST_REG",
        2,
        "\{mnemonic}\{t}\{c} \{gpr_asm(rt)}, [\{gpr_asm(rn)}], \{offset_asm}",
      )
    }
    let offset = mc_imm(am2_opc(add, imm5, shift, index))
    let ops = if load {
      [mc_gpr(rt), mc_gpr(rn), mc_gpr(rn), mc_gpr(rm), offset, ..mc_pred(cond)]
    } else {
      [mc_gpr(rn), mc_gpr(rt), mc_gpr(rn), mc_gpr(rm), offset, ..mc_pred(cond)]
    }
    decoded(name, ops, text)
  }
}

///|
/// The extra load/store instructions: halfword, signed byte and
/// doubleword accesses (addressing mode 3).
fn a32_extra_ldst(w : UInt, cond : Int) -> A32Insn? {
  let p = a32_bit(w, 24)
  let add = a32_bit(w, 23)
  let imm_form = a32_bit(w, 22)
  let wb = a32_bit(w, 21)
  let l = a32_bit(w, 20)
  let rn = a32_field(w, 16, 4)
  let rt = a32_field(w, 12, 4)
  let rm = a32_field(w, 0, 4)
  let imm8 = (a32_field(w, 8, 4) << 4) | a32_field(w, 0, 4)
  // (name, is a load, is a dual access)
  let (base, load, dual) = match (a32_field(w, 5, 2), l) {
    (1, false) => ("STRH", false, false)
    (1, true) => ("LDRH", true, false)
    (2, false) => ("LDRD", true, true)
    (2, true) => ("LDRSB", true, false)
    (3, false) => ("STRD", false, true)
    _ => ("LDRSH", true, false)
  }
  guard !dual || rt != 15 else { return None }
  let mnemonic = base.to_lower()
  let c = cond_asm(cond)
  let t_asm = if dual {
    "\{gpr_asm(rt)}, \{gpr_asm(rt + 1)}"
  } else {
    gpr_asm(rt)
  }
  let offset_asm = if imm_form {
    "#\{a32_sign(add)}\{imm8}"
  } else {
    "\{a32_sign(add)}\{gpr_asm(rm)}"
  }
  // `printAddrMode3Operand`: a zero offset is omitted (not `#-0`)
  let offset_addr = if imm_form && add && imm8 == 0 {
    "[\{gpr_asm(rn)}]"
  } else {
    "[\{gpr_asm(rn)}, \{offset_asm}]"
  }
  if !p && wb {
    // the unprivileged variants of the halfword and signed byte accesses
    guard !dual else { return None }
    let (name, offset) = if imm_form {
      (base + "Ti", [mc_imm(imm8 | ((if add { 1 } else { 0 }) << 8))])
    } else {
      guard load || a32_field(w, 8, 4) == 0 else { return None }
      (base + "Tr", [mc_gpr(rm), mc_imm(if add { 1 } else { 0 })])
    }
    let t = if load {
      [mc_gpr(rt), mc_gpr(rn)]
    } else {
      [mc_gpr(rn), mc_gpr(rt)]
    }
    return decoded(
      name,
      [..t, mc_gpr(rn), ..offset, ..mc_pred(cond)],
      "\{mnemonic}t\{c} \{t_asm}, [\{gpr_asm(rn)}], \{offset_asm}",
    )
  }
  let index = if p && !wb { 0 } else if p { 1 } else { 2 }
  let offset = if imm_form {
    [mc_nil(), mc_imm(am3_opc(add, imm8, index~))]
  } else {
    [mc_gpr(rm), mc_imm(am3_opc(add, 0, index~))]
  }
  let ts = if dual { [mc_gpr(rt), mc_gpr(rt + 1)] } else { [mc_gpr(rt)] }
  if p && !wb {
    decoded(
      base,
      [..ts, mc_gpr(rn), ..offset, ..mc_pred(cond)],
      "\{mnemonic}\{c} \{t_asm}, \{offset_addr}",
    )
  } else {
    let (suffix, text) = if p {
      ("_PRE", "\{mnemonic}\{c} \{t_asm}, [\{gpr_asm(rn)}, \{offset_asm}]!")
    } else {
      ("_POST", "\{mnemonic}\{c} \{t_asm}, [\{gpr_asm(rn)}], \{offset_asm}")
    }
    let front = if load { [..ts, mc_gpr(rn)] } else { [mc_gpr(rn), ..ts] }
    decoded(
      base + suffix,
      [..front, mc_gpr(rn), ..offset, ..mc_pred(cond)],
      text,
    )
  }
}

///|
/// Multiply and multiply-accumulate (bits 27..24 `0000`, bits 7..4
/// `1001`).
fn a32_multiply(w : UInt, cond : Int) -> A32Insn? {
  let s = a32_bit(w, 20)
  let hi = a32_field(w, 16, 4)
  let lo = a32_field(w, 12, 4)
  let rm = a32_field(w, 8, 4)
  let rn = a32_field(w, 0, 4)
  let c = cond_asm(cond)
  let flags = if s { "s" } else { "" }
  match a32_field(w, 21, 3) {
    0 =>
      decoded(
        "MUL",
        [mc_gpr(hi), mc_gpr(rn), mc_gpr(rm), ..mc_pred(cond), mc_cc_out(s)],
        "mul\{flags}\{c} \{gpr_asm(hi)}, \{gpr_asm(rn)}, \{gpr_asm(rm)}",
      )
    1 =>
      decoded(
        "MLA",
        [
          mc_gpr(hi),
          mc_gpr(rn),
          mc_gpr(rm),
          mc_gpr(lo),
          ..mc_pred(cond),
          mc_cc_out(s),
        ],
        "mla\{flags}\{c} \{gpr_asm(hi)}, \{gpr_asm(rn)}, \{gpr_asm(rm)}, \{gpr_asm(lo)}",
      )
    3 if !s =>
      decoded(
        "MLS",
        [mc_gpr(hi), mc_gpr(rn), mc_gpr(rm), mc_gpr(lo), ..mc_pred(cond)],
        "mls\{c} \{gpr_asm(hi)}, \{gpr_asm(rn)}, \{gpr_asm(rm)}, \{gpr_asm(lo)}",
      )
    op if op >= 4 => {
      let (name, accumulate) = match op {
        4 => ("UMULL", false)
        5 => ("UMLAL", true)
        6 => ("SMULL", false)
        _ => ("SMLAL", true)
      }
      let acc = if accumulate { [mc_gpr(lo), mc_gpr(hi)] } else { [] }
      decoded(
        name,
        [
          mc_gpr(lo),
          mc_gpr(hi),
          mc_gpr(rn),
          mc_gpr(rm),
          ..acc,
          ..mc_pred(cond),
          mc_cc_out(s),
        ],
        "\{name.to_lower()}\{flags}\{c} \{gpr_asm(lo)}, \{gpr_asm(hi)}, \{gpr_asm(rn)}, \{gpr_asm(rm)}",
      )
    }
    _ => None
  }
}

///|
/// The signed halfword multiplies (`SMLA<x><y>`, `SMLAW<y>`, `SMULW<y>`,
/// `SMLAL<x><y>`, `SMUL<x><y>`).
fn a32_halfword_multiply(w : UInt, cond : Int) -> A32Insn? {
  guard !a32_bit(w, 4) else { return None }
  let rd = a32_field(w, 16, 4)
  let ra = a32_field(w, 12, 4)
  let rm = a32_field(w, 8, 4)
  let rn = a32_field(w, 0, 4)
  let x = if a32_bit(w, 5) { "T" } else { "B" }
  let y = if a32_bit(w, 6) { "T" } else { "B" }
  let c = cond_asm(cond)
  let three = (name : String) => {
    decoded(
      name,
      [mc_gpr(rd), mc_gpr(rn), mc_gpr(rm), ..mc_pred(cond)],
      "\{name.to_lower()}\{c} \{gpr_asm(rd)}, \{gpr_asm(rn)}, \{gpr_asm(rm)}",
    )
  }
  let four = (name : String) => {
    decoded(
      name,
      [mc_gpr(rd), mc_gpr(rn), mc_gpr(rm), mc_gpr(ra), ..mc_pred(cond)],
      "\{name.to_lower()}\{c} \{gpr_asm(rd)}, \{gpr_asm(rn)}, \{gpr_asm(rm)}, \{gpr_asm(ra)}",
    )
  }
  match a32_field(w, 21, 2) {
    0 => four("SMLA" + x + y)
    1 => if a32_bit(w, 5) { three("SMULW" + y) } else { four("SMLAW" + y) }
    2 => {
      let name = "SMLAL" + x + y
      decoded(
        name,
        [
          mc_gpr(ra),
          mc_gpr(rd),
          mc_gpr(rn),
          mc_gpr(rm),
          mc_gpr(ra),
          mc_gpr(rd),
          ..mc_pred(cond),
        ],
        "\{name.to_lower()}\{c} \{gpr_asm(ra)}, \{gpr_asm(rd)}, \{gpr_asm(rn)}, \{gpr_asm(rm)}",
      )
    }
    _ => three("SMUL" + x + y)
  }
}

///|
/// Swaps and the exclusive loads and stores (bits 27..24 `0001`, bits
/// 7..4 `1001`).
fn a32_sync(w : UInt, cond : Int) -> A32Insn? {
  let rn = a32_field(w, 16, 4)
  let rt = a32_field(w, 12, 4)
  let low = a32_field(w, 0, 4)
  let c = cond_asm(cond)
  if !a32_bit(w, 23) {
    // SWP/SWPB
    guard a32_field(w, 20, 2) == 0 else { return None }
    let name = if a32_bit(w, 22) { "SWPB" } else { "SWP" }
    return decoded(
      name,
      [mc_gpr(rt), mc_gpr(low), mc_gpr(rn), ..mc_pred(cond)],
      "\{name.to_lower()}\{c} \{gpr_asm(rt)}, \{gpr_asm(low)}, [\{gpr_asm(rn)}]",
    )
  }
  guard a32_field(w, 8, 4) == 15 else { return None }
  let size = match a32_field(w, 21, 2) {
    0 => ""
    1 => "D"
    2 => "B"
    _ => "H"
  }
  // `DecodeGPRPairRegisterClass`: registers above `R13` are invalid, an
  // odd register names the pair of the even one below it (a `SoftFail`)
  guard size != "D" || (if a32_bit(w, 20) { rt } else { low }) <= 13 else {
    return None
  }
  let rt = if size == "D" && a32_bit(w, 20) { rt & -2 } else { rt }
  let low = if size == "D" && !a32_bit(w, 20) { low & -2 } else { low }
  if a32_bit(w, 20) {
    guard a32_field(w, 0, 4) == 15 else { return None }
    let t = if size == "D" { mc_gpr_pair(rt) } else { mc_gpr(rt) }
    let t_asm = if size == "D" {
      "\{gpr_asm(rt)}, \{gpr_asm(rt + 1)}"
    } else {
      gpr_asm(rt)
    }
    let name = "LDREX" + size
    decoded(
      name,
      [t, mc_gpr(rn), ..mc_pred(cond)],
      "\{name.to_lower()}\{c} \{t_asm}, [\{gpr_asm(rn)}]",
    )
  } else {
    let t = if size == "D" { mc_gpr_pair(low) } else { mc_gpr(low) }
    let t_asm = if size == "D" {
      "\{gpr_asm(low)}, \{gpr_asm(low + 1)}"
    } else {
      gpr_asm(low)
    }
    let name = "STREX" + size
    decoded(
      name,
      [mc_gpr(rt), t, mc_gpr(rn), ..mc_pred(cond)],
      "\{name.to_lower()}\{c} \{gpr_asm(rt)}, \{t_asm}, [\{gpr_asm(rn)}]",
    )
  }
}

///|
/// The miscellaneous instructions: status register accesses, branch and
/// exchange, count leading zeros.
fn a32_misc(w : UInt, cond : Int) -> A32Insn? {
  let op = a32_field(w, 21, 2)
  let rm = a32_field(w, 0, 4)
  let rd = a32_field(w, 12, 4)
  let c = cond_asm(cond)
  match a32_field(w, 4, 3) {
    0 =>
      if (op & 1) == 0 {
        // (bit 9 set: the banked register form; LLVM also requires bit 16)
        guard !a32_bit(w, 9) && a32_bit(w, 16) else { return None }
        let (name, reg) = if a32_bit(w, 22) {
          ("MRSsys", "spsr")
        } else {
          ("MRS", "apsr")
        }
        decoded(
          name,
          [mc_gpr(rd), ..mc_pred(cond)],
          "mrs\{c} \{gpr_asm(rd)}, \{reg}",
        )
      } else {
        guard (w & 0x0000FFF0) == 0x0000F000 else { return None }
        let mask = (a32_field(w, 22, 1) << 4) | a32_field(w, 16, 4)
        guard mask != 0 else { return None }
        decoded(
          "MSR",
          [mc_imm(mask), mc_gpr(rm), ..mc_pred(cond)],
          "msr\{c} \{msr_mask_asm(mask)}, \{gpr_asm(rm)}",
        )
      }
    1 if op == 1 => {
      guard (w & 0x000FFF00) == 0x000FFF00 else { return None }
      if rm == 14 {
        decoded("BX_RET", mc_pred(cond), "bx\{c} lr")
      } else if cond == 14 {
        decoded("BX", [mc_gpr(rm)], "bx \{gpr_asm(rm)}")
      } else {
        decoded(
          "BX_pred",
          [mc_gpr(rm), ..mc_pred(cond)],
          "bx\{c} \{gpr_asm(rm)}",
        )
      }
    }
    1 if op == 3 => {
      guard (w & 0x000F0F00) == 0x000F0F00 else { return None }
      decoded(
        "CLZ",
        [mc_gpr(rd), mc_gpr(rm), ..mc_pred(cond)],
        "clz\{c} \{gpr_asm(rd)}, \{gpr_asm(rm)}",
      )
    }
    3 if op == 1 => {
      guard (w & 0x000FFF00) == 0x000FFF00 else { return None }
      if cond == 14 {
        decoded("BLX", [mc_gpr(rm)], "blx \{gpr_asm(rm)}")
      } else {
        decoded(
          "BLX_pred",
          [mc_gpr(rm), ..mc_pred(cond)],
          "blx\{c} \{gpr_asm(rm)}",
        )
      }
    }
    _ => None
  }
}

///|
/// The media instructions (bits 27..25 `011`, bit 4 set): extensions,
/// packing, reversals, bit fields and the dual multiplies.
fn a32_media(w : UInt, cond : Int) -> A32Insn? {
  let op1 = a32_field(w, 20, 5)
  let op2 = a32_field(w, 5, 3)
  let rn = a32_field(w, 16, 4)
  let rd = a32_field(w, 12, 4)
  let rm = a32_field(w, 0, 4)
  let c = cond_asm(cond)
  let two = (name : String) => {
    guard rn == 15 && a32_field(w, 8, 4) == 15 else { return None }
    decoded(
      name,
      [mc_gpr(rd), mc_gpr(rm), ..mc_pred(cond)],
      "\{name.to_lower()}\{c} \{gpr_asm(rd)}, \{gpr_asm(rm)}",
    )
  }
  match (op1, op2) {
    (0b01000, 0 | 2 | 4 | 6) => {
      let imm5 = a32_field(w, 7, 5)
      let (name, shift) = if a32_bit(w, 6) {
        ("PKHTB", if imm5 == 0 { ", asr #32" } else { ", asr #\{imm5}" })
      } else {
        ("PKHBT", if imm5 == 0 { "" } else { ", lsl #\{imm5}" })
      }
      decoded(
        name,
        [mc_gpr(rd), mc_gpr(rn), mc_gpr(rm), mc_imm(imm5), ..mc_pred(cond)],
        "\{name.to_lower()}\{c} \{gpr_asm(rd)}, \{gpr_asm(rn)}, \{gpr_asm(rm)}\{shift}",
      )
    }
    (0b01010 | 0b01011 | 0b01110 | 0b01111, 3) => {
      let rot = a32_field(w, 10, 2)
      let (sign, size) = match op1 {
        0b01010 => ("S", "B")
        0b01011 => ("S", "H")
        0b01110 => ("U", "B")
        _ => ("U", "H")
      }
      let rot_asm = if rot == 0 { "" } else { ", ror #\{rot * 8}" }
      if rn == 15 {
        let name = sign + "XT" + size
        decoded(
          name,
          [mc_gpr(rd), mc_gpr(rm), mc_imm(rot), ..mc_pred(cond)],
          "\{name.to_lower()}\{c} \{gpr_asm(rd)}, \{gpr_asm(rm)}\{rot_asm}",
        )
      } else {
        let name = sign + "XTA" + size
        decoded(
          name,
          [mc_gpr(rd), mc_gpr(rn), mc_gpr(rm), mc_imm(rot), ..mc_pred(cond)],
          "\{name.to_lower()}\{c} \{gpr_asm(rd)}, \{gpr_asm(rn)}, \{gpr_asm(rm)}\{rot_asm}",
        )
      }
    }
    (0b01011, 1) => two("REV")
    (0b01011, 5) => two("REV16")
    (0b01111, 1) => two("RBIT")
    (0b01111, 5) => two("REVSH")
    (0b10000, 0 | 1) => {
      let ra = a32_field(w, 12, 4)
      let rd = a32_field(w, 16, 4)
      let rm = a32_field(w, 8, 4)
      let rn = a32_field(w, 0, 4)
      let x = if a32_bit(w, 5) { "X" } else { "" }
      if ra == 15 {
        let name = "SMUAD" + x
        decoded(
          name,
          [mc_gpr(rd), mc_gpr(rn), mc_gpr(rm), ..mc_pred(cond)],
          "\{name.to_lower()}\{c} \{gpr_asm(rd)}, \{gpr_asm(rn)}, \{gpr_asm(rm)}",
        )
      } else {
        let name = "SMLAD" + x
        decoded(
          name,
          [mc_gpr(rd), mc_gpr(rn), mc_gpr(rm), mc_gpr(ra), ..mc_pred(cond)],
          "\{name.to_lower()}\{c} \{gpr_asm(rd)}, \{gpr_asm(rn)}, \{gpr_asm(rm)}, \{gpr_asm(ra)}",
        )
      }
    }
    (0b11010 | 0b11011 | 0b11110 | 0b11111, 2 | 6) => {
      let lsb = a32_field(w, 7, 5)
      let widthm1 = a32_field(w, 16, 5)
      let name = if op1 >= 0b11110 { "UBFX" } else { "SBFX" }
      decoded(
        name,
        [mc_gpr(rd), mc_gpr(rm), mc_imm(lsb), mc_imm(widthm1), ..mc_pred(cond)],
        "\{name.to_lower()}\{c} \{gpr_asm(rd)}, \{gpr_asm(rm)}, #\{lsb}, #\{widthm1 + 1}",
      )
    }
    (0b11100 | 0b11101, 0 | 4) => {
      let lsb = a32_field(w, 7, 5)
      let msb = a32_field(w, 16, 5)
      // `DecodeBitfieldMaskOperand`: `lsb > msb` is a `SoftFail`, the
      // field is then the bit `msb`
      let lsb = if lsb > msb { msb } else { lsb }
      // `DecodeBitfieldMaskOperand`: the inverted mask of the field
      let msb_mask = if msb == 31 { 0xFFFFFFFFU } else { (1U << (msb + 1)) - 1 }
      let lsb_mask = (1U << lsb) - 1
      let inv_mask = (msb_mask ^ lsb_mask).lnot().reinterpret_as_int()
      let inv_mask_op = mc_imm_u32(inv_mask)
      let width = msb - lsb + 1
      if rm == 15 {
        decoded(
          "BFC",
          [mc_gpr(rd), mc_gpr(rd), inv_mask_op, ..mc_pred(cond)],
          "bfc\{c} \{gpr_asm(rd)}, #\{lsb}, #\{width}",
        )
      } else {
        decoded(
          "BFI",
          [mc_gpr(rd), mc_gpr(rd), mc_gpr(rm), inv_mask_op, ..mc_pred(cond)],
          "bfi\{c} \{gpr_asm(rd)}, \{gpr_asm(rm)}, #\{lsb}, #\{width}",
        )
      }
    }
    _ => None
  }
}

///|
/// Load and store multiple.
fn a32_ldm_stm(w : UInt, cond : Int) -> A32Insn? {
  // the user-mode and exception-return variants (`^`) are `sysLDM...`
  let sys = a32_bit(w, 22)
  let mode = match (a32_bit(w, 24), a32_bit(w, 23)) {
    (false, false) => "DA"
    (false, true) => "IA"
    (true, false) => "DB"
    (true, true) => "IB"
  }
  let wb = a32_bit(w, 21)
  let load = a32_bit(w, 20)
  let rn = a32_field(w, 16, 4)
  let mask = a32_field(w, 0, 16)
  guard mask != 0 else { return None }
  let name = (if sys { "sys" } else { "" }) +
    (if load { "LDM" } else { "STM" }) +
    mode +
    (if wb { "_UPD" } else { "" })
  let base = if wb { [mc_gpr(rn), mc_gpr(rn)] } else { [mc_gpr(rn)] }
  let c = cond_asm(cond)
  let text = match (load, mode, rn, wb) {
    (true, "IA", 13, true) if !sys && mask.popcnt() > 1 =>
      "pop\{c} \{reglist_asm(mask)}"
    (false, "DB", 13, true) if !sys && mask.popcnt() > 1 =>
      "push\{c} \{reglist_asm(mask)}"
    _ => {
      let m = if mode == "IA" { "" } else { mode.to_lower() }
      let bang = if wb { "!" } else { "" }
      "\{if load { "ldm" } else { "stm" }}\{m}\{c} \{gpr_asm(rn)}\{bang}, \{reglist_asm(mask)}\{if sys { " ^" } else { "" }}"
    }
  }
  decoded(name, [..base, ..mc_pred(cond), ..mc_reglist(mask)], text)
}

///|
/// Branch and branch with link (immediate).
fn a32_branch(w : UInt, cond : Int) -> A32Insn? {
  let offset = sign_extend(a32_field(w, 0, 24) << 2, 26)
  let c = cond_asm(cond)
  if a32_bit(w, 24) {
    // LLVM's `BL` has no predicate operands, `BL_pred` has them
    if cond == 14 {
      decoded("BL", [mc_imm(offset)], "bl \{imm_asm(offset)}")
    } else {
      decoded(
        "BL_pred",
        [mc_imm(offset), ..mc_pred(cond)],
        "bl\{c} \{imm_asm(offset)}",
      )
    }
  } else {
    decoded(
      "Bcc",
      [mc_imm(offset), ..mc_pred(cond)],
      "b\{c} \{imm_asm(offset)}",
    )
  }
}

///|
/// Name of the A32 decoder installed by `register_decoder`.
pub let a32_decoder_name : String = "arm-a32"

///|
/// Whether the A32 decoder applies to `ctx`: 32-bit targets of the ARM
/// family decoded as ARM (`llvm-armv7`) instructions.
pub fn a32_decoder_accepts(ctx : @mc.Context) -> Bool {
  ctx.belongs(@core_theory.Target::arm_family()) &&
  ctx.target.bits() == 32 &&
  ctx.encoding == @core_theory.Language::llvm_a32()
}

///|
/// The A32 decoder (see `decode_a32`); instruction words are read in the
/// byte order of the target.
pub fn a32_decoder() -> @mc.Decoder {
  @mc.Decoder::create(a32_decoder_name, accepts=a32_decoder_accepts, decode=(
    ctx,
    bytes,
    addr,
  ) => decode_a32(bytes, addr~, big_endian=ctx.target.endianness() is BigEndian))
}

///|
/// Registers the A32 decoder with `@mc.register_decoder`. Idempotent: the
/// decoder is replaced by name.
pub fn register_decoder() -> Unit {
  @mc.register_decoder(a32_decoder())
}
