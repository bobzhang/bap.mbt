// The integer (non-coprocessor) opcode space of the native MIPS decoder:
// the primary opcodes, SPECIAL, REGIMM, SPECIAL2, SPECIAL3 and the MIPS32
// Release 6 compact branches and PC-relative forms.
//
// Opcode names, operand orders and register classes follow LLVM's
// `MipsGenDisassemblerTables` (e.g. memory operands decoded by
// `DecodeMem` are `[rt, base, offset]` with `GPR32` names, and `SC`/`SCD`
// repeat `rt` as the tied input).

///|
/// A GPR operand of the register class of the instruction: `GPR64` for
/// the 64-bit (`D*`) instructions, `GPR32` otherwise.
fn reg_of(wide : Bool) -> (Int) -> Operand {
  if wide {
    gpr64
  } else {
    gpr32
  }
}

///|
/// `name rd, rs, rt`.
fn three_regs(
  name : String,
  mnemonic : String,
  rd : Int,
  rs : Int,
  rt : Int,
  wide? : Bool = false,
) -> Form {
  let g = reg_of(wide)
  form(name, mnemonic, [g(rd), g(rs), g(rt)])
}

///|
/// A load or store decoded by LLVM's `DecodeMem`: `[rt, base, offset]`.
fn memory(
  f : Fields,
  name : String,
  mnemonic : String,
  kinds : Array[@mc.Kind],
) -> Form {
  form(
    name,
    mnemonic,
    [gpr32(f.rt), gpr32(f.rs), imm(f.simm16())],
    kinds~,
    layout=Mem,
  )
}

///|
/// A store conditional: `[rt, rt, base, offset]` (`rt` is also the success
/// flag output).
fn store_conditional_form(
  name : String,
  mnemonic : String,
  rt : Int,
  base : Int,
  offset : Int64,
) -> Form {
  form(
    name,
    mnemonic,
    [gpr32(rt), gpr32(rt), gpr32(base), imm(offset)],
    kinds=store_kinds,
    layout=Mem,
  )
}

///|
/// A conditional branch comparing two registers: `[rs, rt, target]`.
fn branch_rr(f : Fields, name : String, mnemonic : String) -> Form {
  form(
    name,
    mnemonic,
    [gpr32(f.rs), gpr32(f.rt), imm(branch_target(f.imm16, 16))],
    kinds=cond_branch,
  )
}

///|
/// A conditional branch on one register: `[reg, target]`.
fn branch_r(
  name : String,
  mnemonic : String,
  reg : Int,
  target : Int64,
  kinds? : Array[@mc.Kind] = cond_branch,
) -> Form {
  form(name, mnemonic, [gpr32(reg), imm(target)], kinds~)
}

///|
/// `name rd, rt, sa` (shifts by an immediate amount).
fn dec_shift_imm(
  name : String,
  mnemonic : String,
  f : Fields,
  wide? : Bool = false,
) -> Form {
  let g = reg_of(wide)
  form(name, mnemonic, [g(f.rd), g(f.rt), imm(f.sa.to_int64())])
}

///|
/// `name rd, rt, rs` (shifts by a register amount; the amount is a `GPR32`
/// operand even for the doubleword shifts).
fn dec_shift_var(
  name : String,
  mnemonic : String,
  f : Fields,
  wide? : Bool = false,
) -> Form {
  let g = reg_of(wide)
  form(name, mnemonic, [g(f.rd), g(f.rt), gpr32(f.rs)])
}

///|
/// `mnemonic rd, rs` printed as `move rd, rs` when `rt` is `$zero`.
fn with_move_alias(result : Form, f : Fields) -> Form {
  if f.rt == 0 {
    let ops = result.operands
    { ..result, layout: Text("move \{ops[0].text}, \{ops[1].text}"), }
  } else {
    result
  }
}

///|
/// Printed as `neg_mnemonic rd, rt` when `rs` is `$zero` (`neg`, `negu`).
fn with_neg_alias(result : Form, f : Fields, neg_mnemonic : String) -> Form {
  if f.rs == 0 {
    let ops = result.operands
    {
      ..result,
      layout: Text("\{neg_mnemonic} \{ops[0].text}, \{ops[2].text}"),
    }
  } else {
    result
  }
}

///|
/// A trap comparing two registers: `[rs, rt, code]`.
fn trap_rr(name : String, mnemonic : String, f : Fields) -> Form {
  let code = bits(f.word, 6, 10)
  let ops = [gpr32(f.rs), gpr32(f.rt), imm(code.to_int64())]
  let text = if code == 0 {
    "\{mnemonic} \{ops[0].text}, \{ops[1].text}"
  } else {
    "\{mnemonic} \{ops[0].text}, \{ops[1].text}, \{code}"
  }
  form(name, mnemonic, ops, layout=Text(text))
}

///|
/// The SPECIAL opcode space (primary opcode 0).
fn decode_special(f : Fields, arch : Arch, r6 : Bool) -> Form? {
  let wide = arch is Mips64
  let { rs, rt, rd, sa, .. } = f
  match f.funct {
    0x00 => {
      guard rs == 0 else { return None }
      if rt == 0 && rd == 0 {
        match sa {
          0 =>
            return Some(
              form(
                "SLL",
                "sll",
                [gpr32(0), gpr32(0), imm(0)],
                layout=Text("nop"),
              ),
            )
          1 => return Some(form("SSNOP", "ssnop", []))
          3 => return Some(form("EHB", "ehb", []))
          5 => return Some(form("PAUSE", "pause", []))
          _ => ()
        }
      }
      Some(dec_shift_imm("SLL", "sll", f))
    }
    0x02 if rs == 0 => Some(dec_shift_imm("SRL", "srl", f))
    0x02 if rs == 1 => Some(dec_shift_imm("ROTR", "rotr", f))
    0x03 if rs == 0 => Some(dec_shift_imm("SRA", "sra", f))
    0x04 if sa == 0 => Some(dec_shift_var("SLLV", "sllv", f))
    0x05 if r6 && sa < 4 =>
      Some(
        form("LSA_R6", "lsa", [
          gpr32(rd),
          gpr32(rs),
          gpr32(rt),
          imm((sa + 1).to_int64()),
        ]),
      )
    0x06 if sa == 0 => Some(dec_shift_var("SRLV", "srlv", f))
    0x06 if sa == 1 => Some(dec_shift_var("ROTRV", "rotrv", f))
    0x07 if sa == 0 => Some(dec_shift_var("SRAV", "srav", f))
    // the hazard-barrier jumps have `GPR64` variants on MIPS64
    0x08 if !r6 && rt == 0 && rd == 0 && sa == 0 =>
      Some(form("JR", "jr", [gpr32(rs)], kinds=indirect_branch))
    0x08 if !r6 && rt == 0 && rd == 0 && sa == 16 => {
      let (name, g) = if wide { ("JR_HB64", gpr64) } else { ("JR_HB", gpr32) }
      Some(form(name, "jr.hb", [g(rs)], kinds=indirect_branch))
    }
    0x09 if r6 && rt == 0 && rd == 0 && sa == 16 => {
      let (name, g) = if wide {
        ("JR_HB64_R6", gpr64)
      } else {
        ("JR_HB_R6", gpr32)
      }
      Some(form(name, "jr.hb", [g(rs)], kinds=indirect_branch))
    }
    0x09 if rt == 0 && (sa == 0 || sa == 16) => {
      let hb64 = sa == 16 && wide
      let name = match (sa, hb64) {
        (0, _) => "JALR"
        (_, false) => "JALR_HB"
        (_, true) => "JALR_HB64"
      }
      let mnemonic = if sa == 0 { "jalr" } else { "jalr.hb" }
      let g = if hb64 { gpr64 } else { gpr32 }
      let ops = [g(rd), g(rs)]
      let text = if rd == 31 {
        "\{mnemonic} \{ops[1].text}"
      } else if rd == 0 && (sa == 0 || (r6 && !hb64)) {
        let jr = if sa == 0 { "jr" } else { "jr.hb" }
        "\{jr} \{ops[1].text}"
      } else {
        "\{mnemonic} \{ops[0].text}, \{ops[1].text}"
      }
      Some(form(name, mnemonic, ops, kinds=call_kinds, layout=Text(text)))
    }
    0x01 if !r6 && sa == 0 && bits(f.word, 17, 1) == 0 => {
      let cc = bits(f.word, 18, 3)
      let (name, mnemonic) = if bits(f.word, 16, 1) == 0 {
        ("MOVF_I", "movf")
      } else {
        ("MOVT_I", "movt")
      }
      let ops = [gpr32(rd), gpr32(rs), fcc(cc), gpr32(rd)]
      Some(
        form(
          name,
          mnemonic,
          ops,
          layout=Text("\{mnemonic} \{ops[0].text}, \{ops[1].text}, $fcc\{cc}"),
        ),
      )
    }
    0x0a if !r6 && sa == 0 => Some(conditional_move("MOVZ_I_I", "movz", f))
    0x0b if !r6 && sa == 0 => Some(conditional_move("MOVN_I_I", "movn", f))
    0x0c => {
      let code = bits(f.word, 6, 20)
      let text = if code == 0 { "syscall" } else { "syscall \{code}" }
      Some(
        form("SYSCALL", "syscall", [imm(code.to_int64())], layout=Text(text)),
      )
    }
    0x0d => {
      let code1 = bits(f.word, 16, 10)
      let code2 = bits(f.word, 6, 10)
      let text = match (code1, code2) {
        (0, 0) => "break"
        (c, 0) => "break \{c}"
        (c1, c2) => "break \{c1}, \{c2}"
      }
      Some(
        form(
          "BREAK",
          "break",
          [imm(code1.to_int64()), imm(code2.to_int64())],
          layout=Text(text),
        ),
      )
    }
    0x0e if r6 => {
      let code = bits(f.word, 6, 20)
      let text = if code == 0 { "sdbbp" } else { "sdbbp \{code}" }
      Some(form("SDBBP_R6", "sdbbp", [imm(code.to_int64())], layout=Text(text)))
    }
    // LLVM ignores bits 11-25 of `sync`
    0x0f => {
      let text = if sa == 0 { "sync" } else { "sync \{sa}" }
      Some(form("SYNC", "sync", [imm(sa.to_int64())], layout=Text(text)))
    }
    0x10 if !r6 && rs == 0 && rt == 0 && sa == 0 =>
      Some(form("MFHI", "mfhi", [gpr32(rd)]))
    0x10 if r6 && rt == 0 && sa == 1 =>
      Some(form("CLZ_R6", "clz", [gpr32(rd), gpr32(rs)]))
    0x11 if !r6 && rt == 0 && rd == 0 && sa == 0 =>
      Some(form("MTHI", "mthi", [gpr32(rs)]))
    0x11 if r6 && rt == 0 && sa == 1 =>
      Some(form("CLO_R6", "clo", [gpr32(rd), gpr32(rs)]))
    0x12 if !r6 && rs == 0 && rt == 0 && sa == 0 =>
      Some(form("MFLO", "mflo", [gpr32(rd)]))
    0x12 if r6 && wide && rt == 0 && sa == 1 =>
      Some(form("DCLZ_R6", "dclz", [gpr64(rd), gpr64(rs)]))
    0x13 if !r6 && rt == 0 && rd == 0 && sa == 0 =>
      Some(form("MTLO", "mtlo", [gpr32(rs)]))
    0x13 if r6 && wide && rt == 0 && sa == 1 =>
      Some(form("DCLO_R6", "dclo", [gpr64(rd), gpr64(rs)]))
    0x14 if wide && sa == 0 =>
      Some(dec_shift_var("DSLLV", "dsllv", f, wide=true))
    0x15 if r6 && wide && sa < 4 =>
      Some(
        form("DLSA_R6", "dlsa", [
          gpr64(rd),
          gpr64(rs),
          gpr64(rt),
          imm((sa + 1).to_int64()),
        ]),
      )
    0x16 if wide && sa == 0 =>
      Some(dec_shift_var("DSRLV", "dsrlv", f, wide=true))
    0x16 if wide && sa == 1 =>
      Some(dec_shift_var("DROTRV", "drotrv", f, wide=true))
    0x17 if wide && sa == 0 =>
      Some(dec_shift_var("DSRAV", "dsrav", f, wide=true))
    0x18..=0x1f => decode_mul_div(f, arch, r6)
    0x20 if sa == 0 => Some(three_regs("ADD", "add", rd, rs, rt))
    0x21 if sa == 0 =>
      Some(with_move_alias(three_regs("ADDu", "addu", rd, rs, rt), f))
    0x22 if sa == 0 =>
      Some(with_neg_alias(three_regs("SUB", "sub", rd, rs, rt), f, "neg"))
    0x23 if sa == 0 =>
      Some(with_neg_alias(three_regs("SUBu", "subu", rd, rs, rt), f, "negu"))
    0x24 if sa == 0 => Some(three_regs("AND", "and", rd, rs, rt))
    0x25 if sa == 0 =>
      Some(with_move_alias(three_regs("OR", "or", rd, rs, rt), f))
    0x26 if sa == 0 => Some(three_regs("XOR", "xor", rd, rs, rt))
    0x27 if sa == 0 => {
      let result = three_regs("NOR", "nor", rd, rs, rt)
      if rt == 0 {
        let ops = result.operands
        Some({ ..result, layout: Text("not \{ops[0].text}, \{ops[1].text}"), })
      } else {
        Some(result)
      }
    }
    0x2a if sa == 0 => Some(three_regs("SLT", "slt", rd, rs, rt))
    0x2b if sa == 0 => Some(three_regs("SLTu", "sltu", rd, rs, rt))
    0x2c if wide && sa == 0 =>
      Some(three_regs("DADD", "dadd", rd, rs, rt, wide=true))
    0x2d if wide && sa == 0 =>
      Some(
        with_move_alias(three_regs("DADDu", "daddu", rd, rs, rt, wide=true), f),
      )
    0x2e if wide && sa == 0 =>
      Some(
        with_neg_alias(
          three_regs("DSUB", "dsub", rd, rs, rt, wide=true),
          f,
          "dneg",
        ),
      )
    0x2f if wide && sa == 0 =>
      Some(
        with_neg_alias(
          three_regs("DSUBu", "dsubu", rd, rs, rt, wide=true),
          f,
          "dnegu",
        ),
      )
    0x30 => Some(trap_rr("TGE", "tge", f))
    0x31 => Some(trap_rr("TGEU", "tgeu", f))
    0x32 => Some(trap_rr("TLT", "tlt", f))
    0x33 => Some(trap_rr("TLTU", "tltu", f))
    0x34 => Some(trap_rr("TEQ", "teq", f))
    0x35 if r6 && sa == 0 =>
      Some(
        three_regs(
          "SELEQZ" + (if wide { "64" } else { "" }),
          "seleqz",
          rd,
          rs,
          rt,
          wide~,
        ),
      )
    0x36 => Some(trap_rr("TNE", "tne", f))
    0x37 if r6 && sa == 0 =>
      Some(
        three_regs(
          "SELNEZ" + (if wide { "64" } else { "" }),
          "selnez",
          rd,
          rs,
          rt,
          wide~,
        ),
      )
    0x38 if wide && rs == 0 => Some(dec_shift_imm("DSLL", "dsll", f, wide=true))
    0x3a if wide && rs == 0 => Some(dec_shift_imm("DSRL", "dsrl", f, wide=true))
    0x3a if wide && rs == 1 =>
      Some(dec_shift_imm("DROTR", "drotr", f, wide=true))
    0x3b if wide && rs == 0 => Some(dec_shift_imm("DSRA", "dsra", f, wide=true))
    0x3c if wide && rs == 0 =>
      Some(dec_shift_imm("DSLL32", "dsll32", f, wide=true))
    0x3e if wide && rs == 0 =>
      Some(dec_shift_imm("DSRL32", "dsrl32", f, wide=true))
    0x3e if wide && rs == 1 =>
      Some(dec_shift_imm("DROTR32", "drotr32", f, wide=true))
    0x3f if wide && rs == 0 =>
      Some(dec_shift_imm("DSRA32", "dsra32", f, wide=true))
    _ => None
  }
}

///|
/// `MOVZ`/`MOVN rd, rs, rt`; the destination is also a (tied) input.
fn conditional_move(name : String, mnemonic : String, f : Fields) -> Form {
  let ops = [gpr32(f.rd), gpr32(f.rs), gpr32(f.rt), gpr32(f.rd)]
  form(
    name,
    mnemonic,
    ops,
    layout=Text("\{mnemonic} \{ops[0].text}, \{ops[1].text}, \{ops[2].text}"),
  )
}

///|
/// SPECIAL functions `0x18`-`0x1f`: the pre-R6 `HI`/`LO` multiplies and
/// divides and their three-operand Release 6 replacements.
fn decode_mul_div(f : Fields, arch : Arch, r6 : Bool) -> Form? {
  let wide = arch is Mips64
  let { rs, rt, rd, sa, .. } = f
  let doubleword = f.funct >= 0x1c
  if doubleword && !wide {
    return None
  }
  if !r6 {
    guard rd == 0 && sa == 0 else { return None }
    let g = reg_of(doubleword)
    let (name, mnemonic, zero) = match f.funct {
      0x18 => ("MULT", "mult", false)
      0x19 => ("MULTu", "multu", false)
      0x1a => ("SDIV", "div", true)
      0x1b => ("UDIV", "divu", true)
      0x1c => ("DMULT", "dmult", false)
      0x1d => ("DMULTu", "dmultu", false)
      0x1e => ("DSDIV", "ddiv", true)
      _ => ("DUDIV", "ddivu", true)
    }
    let ops = [g(rs), g(rt)]
    // LLVM prints the pre-R6 divides with an explicit `$zero` destination
    let text = if zero {
      "\{mnemonic} $zero, \{ops[0].text}, \{ops[1].text}"
    } else {
      "\{mnemonic} \{ops[0].text}, \{ops[1].text}"
    }
    Some(form(name, mnemonic, ops, layout=Text(text)))
  } else {
    let (name, mnemonic) = match (f.funct, sa) {
      (0x18, 2) => ("MUL_R6", "mul")
      (0x18, 3) => ("MUH", "muh")
      (0x19, 2) => ("MULU", "mulu")
      (0x19, 3) => ("MUHU", "muhu")
      (0x1a, 2) => ("DIV", "div")
      (0x1a, 3) => ("MOD", "mod")
      (0x1b, 2) => ("DIVU", "divu")
      (0x1b, 3) => ("MODU", "modu")
      (0x1c, 2) => ("DMUL_R6", "dmul")
      (0x1c, 3) => ("DMUH", "dmuh")
      (0x1d, 2) => ("DMULU", "dmulu")
      (0x1d, 3) => ("DMUHU", "dmuhu")
      (0x1e, 2) => ("DDIV", "ddiv")
      (0x1e, 3) => ("DMOD", "dmod")
      (0x1f, 2) => ("DDIVU", "ddivu")
      (0x1f, 3) => ("DMODU", "dmodu")
      _ => return None
    }
    Some(three_regs(name, mnemonic, rd, rs, rt, wide=doubleword))
  }
}

///|
/// The REGIMM opcode space (primary opcode 1).
fn decode_regimm(f : Fields, arch : Arch, r6 : Bool) -> Form? {
  let wide = arch is Mips64
  let target = branch_target(f.imm16, 16)
  let rs = f.rs
  let trap = (name : String, mnemonic : String) => {
    Some(form(name, mnemonic, [gpr32(rs), imm(f.simm16())]))
  }
  match f.rt {
    0x00 => Some(branch_r("BLTZ", "bltz", rs, target))
    0x01 => Some(branch_r("BGEZ", "bgez", rs, target))
    0x02 if !r6 => Some(branch_r("BLTZL", "bltzl", rs, target))
    0x03 if !r6 => Some(branch_r("BGEZL", "bgezl", rs, target))
    0x06 if r6 && wide =>
      Some(
        form(
          "DAHI",
          "dahi",
          [gpr64(rs), gpr64(rs), imm(f.uimm16())],
          layout=Text(
            "dahi $\{gpr_asm_name(rs)}, $\{gpr_asm_name(rs)}, \{f.uimm16()}",
          ),
        ),
      )
    0x08 if !r6 => trap("TGEI", "tgei")
    0x09 if !r6 => trap("TGEIU", "tgeiu")
    0x0a if !r6 => trap("TLTI", "tlti")
    // sic: the LLVM name of `tltiu`
    0x0b if !r6 => trap("TTLTIU", "tltiu")
    0x0c if !r6 => trap("TEQI", "teqi")
    0x0e if !r6 => trap("TNEI", "tnei")
    0x10 if !r6 =>
      Some(branch_r("BLTZAL", "bltzal", rs, target, kinds=call_kinds))
    0x10 if r6 && rs == 0 && f.imm16 == 0 => Some(form("NAL", "nal", []))
    0x11 if !r6 => {
      let result = branch_r("BGEZAL", "bgezal", rs, target, kinds=call_kinds)
      if rs == 0 {
        Some({ ..result, layout: Text("bal \{target}"), })
      } else {
        Some(result)
      }
    }
    0x11 if r6 && rs == 0 =>
      Some(form("BAL", "bal", [imm(target)], kinds=call_kinds))
    0x12 if !r6 =>
      Some(branch_r("BLTZALL", "bltzall", rs, target, kinds=call_kinds))
    0x13 if !r6 =>
      Some(branch_r("BGEZALL", "bgezall", rs, target, kinds=call_kinds))
    0x17 if r6 && rs == 0 => Some(form("SIGRIE", "sigrie", [imm(f.uimm16())]))
    0x1e if r6 && wide =>
      Some(
        form(
          "DATI",
          "dati",
          [gpr64(rs), gpr64(rs), imm(f.uimm16())],
          layout=Text(
            "dati $\{gpr_asm_name(rs)}, $\{gpr_asm_name(rs)}, \{f.uimm16()}",
          ),
        ),
      )
    0x1f =>
      Some(
        form(
          "SYNCI",
          "synci",
          [gpr32(rs), imm(f.simm16())],
          layout=Text("synci \{f.simm16()}($\{gpr_asm_name(rs)})"),
        ),
      )
    _ => None
  }
}

///|
/// The SPECIAL2 opcode space (primary opcode `0x1c`, removed in R6).
fn decode_special2(f : Fields, arch : Arch) -> Form? {
  let wide = arch is Mips64
  let { rs, rt, rd, sa, .. } = f
  // `clz`/`clo` encode the destination in both the `rt` and `rd` fields,
  // and LLVM's decoder combines the two fields with a bitwise or
  let count_dst = rt | rd
  match f.funct {
    0x00 if rd == 0 && sa == 0 =>
      Some(form("MADD", "madd", [gpr32(rs), gpr32(rt)]))
    0x01 if rd == 0 && sa == 0 =>
      Some(form("MADDU", "maddu", [gpr32(rs), gpr32(rt)]))
    0x02 if sa == 0 => Some(three_regs("MUL", "mul", rd, rs, rt))
    0x04 if rd == 0 && sa == 0 =>
      Some(form("MSUB", "msub", [gpr32(rs), gpr32(rt)]))
    0x05 if rd == 0 && sa == 0 =>
      Some(form("MSUBU", "msubu", [gpr32(rs), gpr32(rt)]))
    0x20 if sa == 0 => Some(form("CLZ", "clz", [gpr32(count_dst), gpr32(rs)]))
    0x21 if sa == 0 => Some(form("CLO", "clo", [gpr32(count_dst), gpr32(rs)]))
    0x24 if wide && sa == 0 =>
      Some(form("DCLZ", "dclz", [gpr64(count_dst), gpr64(rs)]))
    0x25 if wide && sa == 0 =>
      Some(form("DCLO", "dclo", [gpr64(count_dst), gpr64(rs)]))
    0x3f => {
      let code = bits(f.word, 6, 20)
      let text = if code == 0 { "sdbbp" } else { "sdbbp \{code}" }
      Some(form("SDBBP", "sdbbp", [imm(code.to_int64())], layout=Text(text)))
    }
    _ => None
  }
}

///|
/// `EXT`/`INS`-style bit field operations: `[rt, rs, pos, size]` (`INS`
/// also takes `rt` as a tied input). Like LLVM, the size is not validated:
/// a negative size is printed modulo 64, and the doubleword forms keep it
/// as an unsigned 32-bit number.
fn bit_field(
  name : String,
  mnemonic : String,
  f : Fields,
  pos : Int,
  size : Int,
  insert~ : Bool,
  wide~ : Bool,
) -> Form {
  let g = reg_of(wide)
  let size_op = if wide && size < 0 {
    size.to_int64() + 0x1_0000_0000L
  } else {
    size.to_int64()
  }
  let ops = [g(f.rt), g(f.rs), imm(pos.to_int64()), imm(size_op)]
  let shown = if size < 0 { size + 64 } else { size }
  let text = "\{mnemonic} \{ops[0].text}, \{ops[1].text}, \{pos}, \{shown}"
  if insert {
    ops.push(g(f.rt))
  }
  form(name, mnemonic, ops, layout=Text(text))
}

///|
/// A Release 6 load or store with a 9-bit offset: `[rt, base, offset]`.
fn memory9(
  f : Fields,
  name : String,
  mnemonic : String,
  kinds : Array[@mc.Kind],
) -> Form {
  let offset = sext(bits(f.word, 7, 9), 9)
  form(
    name,
    mnemonic,
    [gpr32(f.rt), gpr32(f.rs), imm(offset)],
    kinds~,
    layout=Mem,
  )
}

///|
/// The SPECIAL3 opcode space (primary opcode `0x1f`).
fn decode_special3(f : Fields, arch : Arch, r6 : Bool) -> Form? {
  let wide = arch is Mips64
  let { rs, rt, rd, sa, .. } = f
  match f.funct {
    0x00 =>
      Some(bit_field("EXT", "ext", f, sa, rd + 1, insert=false, wide=false))
    // LLVM decodes `dextm` and `dextu` as `DEXT` (and `dinsm`/`dinsu` as
    // `DINS`), with the combined position and size
    0x01 if wide =>
      Some(bit_field("DEXT", "dext", f, sa, rd + 33, insert=false, wide=true))
    0x02 if wide =>
      Some(
        bit_field("DEXT", "dext", f, sa + 32, rd + 1, insert=false, wide=true),
      )
    0x03 if wide =>
      Some(bit_field("DEXT", "dext", f, sa, rd + 1, insert=false, wide=true))
    0x04 =>
      Some(bit_field("INS", "ins", f, sa, rd - sa + 1, insert=true, wide=false))
    0x05 if wide =>
      Some(
        bit_field(
          "DINS",
          "dins",
          f,
          sa,
          rd + 32 - sa + 1,
          insert=false,
          wide=true,
        ),
      )
    0x06 if wide =>
      Some(
        bit_field(
          "DINS",
          "dins",
          f,
          sa + 32,
          rd - sa + 1,
          insert=false,
          wide=true,
        ),
      )
    0x07 if wide =>
      Some(
        bit_field("DINS", "dins", f, sa, rd - sa + 1, insert=false, wide=true),
      )
    0x20 if r6 && sa >> 2 == 2 => {
      let bp = sa & 3
      let ops = [gpr32(rd), gpr32(rs), gpr32(rt), imm(bp.to_int64())]
      Some(form("ALIGN", "align", ops))
    }
    0x20 if rs == 0 =>
      match sa {
        0x00 if r6 => Some(form("BITSWAP", "bitswap", [gpr32(rd), gpr32(rt)]))
        0x02 => Some(form("WSBH", "wsbh", [gpr32(rd), gpr32(rt)]))
        0x10 => Some(form("SEB", "seb", [gpr32(rd), gpr32(rt)]))
        0x18 => Some(form("SEH", "seh", [gpr32(rd), gpr32(rt)]))
        _ => None
      }
    0x24 if r6 && wide && sa >> 3 == 1 => {
      let bp = sa & 7
      let ops = [gpr64(rd), gpr64(rs), gpr64(rt), imm(bp.to_int64())]
      Some(form("DALIGN", "dalign", ops))
    }
    0x24 if wide && rs == 0 =>
      match sa {
        0x00 if r6 => Some(form("DBITSWAP", "dbitswap", [gpr64(rd), gpr64(rt)]))
        0x02 => Some(form("DSBH", "dsbh", [gpr64(rd), gpr64(rt)]))
        0x05 => Some(form("DSHD", "dshd", [gpr64(rd), gpr64(rt)]))
        _ => None
      }
    // only the user-local hardware register 29 is decoded
    0x3b if rs == 0 && rd == 29 && bits(f.word, 9, 2) == 0 => {
      let sel = bits(f.word, 6, 3)
      let ops = [gpr32(rt), hwr(rd), imm(sel.to_int64())]
      let text = if sel == 0 {
        "rdhwr \{ops[0].text}, \{ops[1].text}"
      } else {
        "rdhwr \{ops[0].text}, \{ops[1].text}, \{sel}"
      }
      Some(form("RDHWR", "rdhwr", ops, layout=Text(text)))
    }
    // Release 6 loads linked, stores conditional, `cache` and `pref` with
    // a 9-bit offset
    0x36 if r6 => Some(memory9(f, "LL_R6", "ll", load_kinds))
    0x37 if r6 && wide => Some(memory9(f, "LLD_R6", "lld", load_kinds))
    0x26 | 0x27 if r6 => {
      let offset = sext(bits(f.word, 7, 9), 9)
      if f.funct == 0x26 {
        Some(store_conditional_form("SC_R6", "sc", rt, rs, offset))
      } else {
        Some(store_conditional_form("SCD_R6", "scd", rt, rs, offset))
      }
    }
    0x25 | 0x35 if r6 && bits(f.word, 6, 1) == 0 => {
      let offset = sext(bits(f.word, 7, 9), 9)
      let (name, mnemonic) = if f.funct == 0x25 {
        ("CACHE_R6", "cache")
      } else {
        ("PREF_R6", "pref")
      }
      let ops = [gpr32(rs), imm(offset), imm(rt.to_int64())]
      Some(
        form(
          name,
          mnemonic,
          ops,
          layout=Text("\{mnemonic} \{rt}, \{offset}(\{ops[0].text})"),
        ),
      )
    }
    _ => None
  }
}

///|
/// The COP0 (system control) opcode space.
fn decode_cop0(f : Fields, arch : Arch) -> Form? {
  let wide = arch is Mips64
  let { rs, rt, rd, .. } = f
  let sel = bits(f.word, 0, 3)
  let zero_middle = bits(f.word, 3, 8) == 0
  match rs {
    0x00 | 0x01 | 0x04 | 0x05 if zero_middle => {
      let g = if rs == 0x01 || rs == 0x05 { gpr64 } else { gpr32 }
      if (rs == 0x01 || rs == 0x05) && !wide {
        return None
      }
      let (name, mnemonic, ops) = match rs {
        0x00 => ("MFC0", "mfc0", [g(rt), cop0(rd), imm(sel.to_int64())])
        0x01 => ("DMFC0", "dmfc0", [g(rt), cop0(rd), imm(sel.to_int64())])
        0x04 => ("MTC0", "mtc0", [cop0(rd), g(rt), imm(sel.to_int64())])
        _ => ("DMTC0", "dmtc0", [cop0(rd), g(rt), imm(sel.to_int64())])
      }
      // both directions print the GPR first
      let (gpr, creg) = if rs == 0x00 || rs == 0x01 {
        (ops[0].text, ops[1].text)
      } else {
        (ops[1].text, ops[0].text)
      }
      Some(
        form(
          name,
          mnemonic,
          ops,
          layout=Text("\{mnemonic} \{gpr}, \{creg}, \{sel}"),
        ),
      )
    }
    0x0b if rd == 12 && bits(f.word, 0, 5) == 0 && f.sa == 0 => {
      let (name, mnemonic) = if bits(f.word, 5, 1) == 0 {
        ("DI", "di")
      } else {
        ("EI", "ei")
      }
      let text = if rt == 0 {
        mnemonic
      } else {
        "\{mnemonic} $\{gpr_asm_name(rt)}"
      }
      Some(form(name, mnemonic, [gpr32(rt)], layout=Text(text)))
    }
    0x10..=0x1f =>
      match f.funct {
        _ if bits(f.word, 6, 19) != 0 => None
        0x20 => Some(form("WAIT", "wait", []))
        0x01 => Some(form("TLBR", "tlbr", []))
        0x02 => Some(form("TLBWI", "tlbwi", []))
        0x06 => Some(form("TLBWR", "tlbwr", []))
        0x08 => Some(form("TLBP", "tlbp", []))
        0x18 => Some(form("ERET", "eret", []))
        0x1f => Some(form("DERET", "deret", []))
        _ => None
      }
    _ => None
  }
}

///|
/// Release 6 `POP06`/`POP07`/`POP26`/`POP27`/`POP10`/`POP30`: compact
/// branches sharing the primary opcodes of `BLEZ`, `BGTZ`, `BLEZL`,
/// `BGTZL`, `ADDI` and `DADDI`, distinguished by the register fields.
fn decode_r6_compact(f : Fields) -> Form? {
  let { rs, rt, .. } = f
  let target = branch_target(f.imm16, 16)
  let rr = (name : String, mnemonic : String) => {
    Some(branch_rr(f, name, mnemonic))
  }
  let one = (name : String, mnemonic : String, kinds : Array[@mc.Kind]) => {
    Some(branch_r(name, mnemonic, rt, target, kinds~))
  }
  match f.opcode {
    0x06 =>
      if rt == 0 {
        Some(branch_r("BLEZ", "blez", rs, target))
      } else if rs == 0 {
        one("BLEZALC", "blezalc", call_kinds)
      } else if rs == rt {
        one("BGEZALC", "bgezalc", call_kinds)
      } else {
        rr("BGEUC", "bgeuc")
      }
    0x07 =>
      if rt == 0 {
        Some(branch_r("BGTZ", "bgtz", rs, target))
      } else if rs == 0 {
        one("BGTZALC", "bgtzalc", call_kinds)
      } else if rs == rt {
        one("BLTZALC", "bltzalc", call_kinds)
      } else {
        rr("BLTUC", "bltuc")
      }
    0x16 =>
      if rt == 0 {
        None
      } else if rs == 0 {
        one("BLEZC", "blezc", cond_branch)
      } else if rs == rt {
        one("BGEZC", "bgezc", cond_branch)
      } else {
        rr("BGEC", "bgec")
      }
    0x17 =>
      if rt == 0 {
        None
      } else if rs == 0 {
        one("BGTZC", "bgtzc", cond_branch)
      } else if rs == rt {
        one("BLTZC", "bltzc", cond_branch)
      } else {
        rr("BLTC", "bltc")
      }
    0x08 =>
      if rs == 0 && rt != 0 {
        one("BEQZALC", "beqzalc", call_kinds)
      } else if rs != 0 && rs < rt {
        rr("BEQC", "beqc")
      } else {
        rr("BOVC", "bovc")
      }
    0x18 =>
      if rs == 0 && rt != 0 {
        one("BNEZALC", "bnezalc", call_kinds)
      } else if rs != 0 && rs < rt {
        rr("BNEC", "bnec")
      } else {
        rr("BNVC", "bnvc")
      }
    _ => None
  }
}

///|
/// Release 6 `POP66`/`POP76`: `BEQZC`/`BNEZC` with a 21-bit offset, or
/// `JIC`/`JIALC` when `rs` is zero.
fn decode_r6_pop_x6(f : Fields, arch : Arch) -> Form? {
  let is_eq = f.opcode == 0x36
  // MIPS64 uses the `GPR64` variants (`BEQZC64`, `JIC64`, ...)
  let (reg, suffix) = if arch is Mips64 { (gpr64, "64") } else { (gpr32, "") }
  if f.rs != 0 {
    let target = branch_target(bits(f.word, 0, 21), 21)
    let (name, mnemonic) = if is_eq {
      ("BEQZC", "beqzc")
    } else {
      ("BNEZC", "bnezc")
    }
    Some(
      form(name + suffix, mnemonic, [reg(f.rs), imm(target)], kinds=cond_branch),
    )
  } else {
    let (name, mnemonic, kinds) = if is_eq {
      ("JIC", "jic", indirect_branch)
    } else {
      ("JIALC", "jialc", call_kinds)
    }
    // the offset is decoded unsigned
    Some(form(name + suffix, mnemonic, [reg(f.rt), imm(f.uimm16())], kinds~))
  }
}

///|
/// Release 6 PC-relative forms (primary opcode `0x3b`).
fn decode_r6_pcrel(f : Fields, arch : Arch) -> Form? {
  let wide = arch is Mips64
  let rs = f.rs
  let sel = f.rt
  let imm19 = sext(bits(f.word, 0, 19), 19) * 4L
  match sel >> 3 {
    0 => {
      let ops = [gpr32(rs), imm(imm19)]
      Some(
        form(
          "ADDIUPC",
          "addiupc",
          ops,
          layout=Text("lapc \{ops[0].text}, \{imm19}"),
        ),
      )
    }
    1 => Some(form("LWPC", "lwpc", [gpr32(rs), imm(imm19)], kinds=load_kinds))
    2 if wide =>
      Some(form("LWUPC", "lwupc", [gpr32(rs), imm(imm19)], kinds=load_kinds))
    _ =>
      match sel {
        0x1e => Some(form("AUIPC", "auipc", [gpr32(rs), imm(f.simm16())]))
        0x1f => Some(form("ALUIPC", "aluipc", [gpr32(rs), imm(f.simm16())]))
        0x18 | 0x19 | 0x1a | 0x1b if wide =>
          Some(
            form(
              "LDPC",
              "ldpc",
              [gpr64(rs), imm(sext(bits(f.word, 0, 18), 18) * 8L)],
              kinds=load_kinds,
            ),
          )
        _ => None
      }
  }
}

///|
/// Decode the instruction word `word` (already assembled from the bytes in
/// the target byte order).
fn decode_form(word : UInt, arch : Arch, r6 : Bool) -> Form? {
  let f = fields(word)
  let wide = arch is Mips64
  let { rs, rt, .. } = f
  match f.opcode {
    0x00 => decode_special(f, arch, r6)
    0x01 => decode_regimm(f, arch, r6)
    0x02 | 0x03 => {
      let target = (bits(word, 0, 26) << 2).to_int64()
      if f.opcode == 0x02 {
        Some(form("J", "j", [imm(target)], kinds=uncond_branch))
      } else {
        Some(form("JAL", "jal", [imm(target)], kinds=call_kinds))
      }
    }
    0x04 => {
      let result = branch_rr(f, "BEQ", "beq")
      let target = result.operands[2].text
      if rs == 0 && rt == 0 {
        Some({ ..result, layout: Text("b \{target}"), })
      } else if rt == 0 {
        Some({ ..result, layout: Text("beqz $\{gpr_asm_name(rs)}, \{target}"), })
      } else {
        Some(result)
      }
    }
    0x05 => {
      let result = branch_rr(f, "BNE", "bne")
      if rt == 0 {
        let target = result.operands[2].text
        Some({ ..result, layout: Text("bnez $\{gpr_asm_name(rs)}, \{target}"), })
      } else {
        Some(result)
      }
    }
    0x06 | 0x07 | 0x16 | 0x17 | 0x08 | 0x18 if r6 => decode_r6_compact(f)
    0x06 if rt == 0 =>
      Some(branch_r("BLEZ", "blez", rs, branch_target(f.imm16, 16)))
    0x07 if rt == 0 =>
      Some(branch_r("BGTZ", "bgtz", rs, branch_target(f.imm16, 16)))
    0x08 => Some(form("ADDi", "addi", [gpr32(rt), gpr32(rs), imm(f.simm16())]))
    0x09 =>
      Some(form("ADDiu", "addiu", [gpr32(rt), gpr32(rs), imm(f.simm16())]))
    0x0a => Some(form("SLTi", "slti", [gpr32(rt), gpr32(rs), imm(f.simm16())]))
    0x0b =>
      Some(form("SLTiu", "sltiu", [gpr32(rt), gpr32(rs), imm(f.simm16())]))
    0x0c => Some(form("ANDi", "andi", [gpr32(rt), gpr32(rs), imm(f.uimm16())]))
    0x0d => Some(form("ORi", "ori", [gpr32(rt), gpr32(rs), imm(f.uimm16())]))
    0x0e => Some(form("XORi", "xori", [gpr32(rt), gpr32(rs), imm(f.uimm16())]))
    0x0f if !r6 && rs == 0 =>
      Some(form("LUi", "lui", [gpr32(rt), imm(f.uimm16())]))
    // Release 6 `lui` is `aui` with `rs` zero
    0x0f if r6 =>
      Some(form("AUI", "aui", [gpr32(rt), gpr32(rs), imm(f.uimm16())]))
    0x10 => decode_cop0(f, arch)
    0x11 => decode_cop1(f, arch, r6)
    0x13 if !r6 => decode_cop1x(f, arch)
    0x12 if r6 => {
      // Release 6 COP2 loads and stores: `[rt, base, offset]` with the
      // base in bits 11-15 and an 11-bit offset
      let cop2 : Operand = {
        op: Reg(name="COP2\{rt}", code=rt),
        text: "$\{rt}",
      }
      if rs == 0x09 || rs == 0x0d {
        let (name, mnemonic) = if rs == 0x09 {
          ("BC2EQZ", "bc2eqz")
        } else {
          ("BC2NEZ", "bc2nez")
        }
        return Some(
          form(
            name,
            mnemonic,
            [cop2, imm(branch_target(f.imm16, 16))],
            kinds=cond_branch,
          ),
        )
      }
      let (name, mnemonic, kinds) = match rs {
        0x0a => ("LWC2_R6", "lwc2", load_kinds)
        0x0b => ("SWC2_R6", "swc2", store_kinds)
        0x0e => ("LDC2_R6", "ldc2", load_kinds)
        0x0f => ("SDC2_R6", "sdc2", store_kinds)
        _ => return None
      }
      Some(
        form(
          name,
          mnemonic,
          [cop2, gpr32(f.rd), imm(sext(bits(word, 0, 11), 11))],
          kinds~,
          layout=Mem,
        ),
      )
    }
    0x14 | 0x15 if !r6 => {
      let (name, mnemonic, zero) = if f.opcode == 0x14 {
        ("BEQL", "beql", "beqzl")
      } else {
        ("BNEL", "bnel", "bnezl")
      }
      let result = branch_rr(f, name, mnemonic)
      if rt == 0 {
        let target = result.operands[2].text
        Some({
          ..result,
          layout: Text("\{zero} $\{gpr_asm_name(rs)}, \{target}"),
        })
      } else {
        Some(result)
      }
    }
    0x16 if rt == 0 =>
      Some(branch_r("BLEZL", "blezl", rs, branch_target(f.imm16, 16)))
    0x17 if rt == 0 =>
      Some(branch_r("BGTZL", "bgtzl", rs, branch_target(f.imm16, 16)))
    0x18 if wide =>
      Some(form("DADDi", "daddi", [gpr64(rt), gpr64(rs), imm(f.simm16())]))
    0x19 if wide =>
      Some(form("DADDiu", "daddiu", [gpr64(rt), gpr64(rs), imm(f.simm16())]))
    0x1a if wide && !r6 => Some(memory(f, "LDL", "ldl", load_kinds))
    0x1b if wide && !r6 => Some(memory(f, "LDR", "ldr", load_kinds))
    0x1c if !r6 => decode_special2(f, arch)
    0x1f => decode_special3(f, arch, r6)
    0x20 => Some(memory(f, "LB", "lb", load_kinds))
    0x21 => Some(memory(f, "LH", "lh", load_kinds))
    0x22 if !r6 => Some(memory(f, "LWL", "lwl", load_kinds))
    0x23 => Some(memory(f, "LW", "lw", load_kinds))
    0x24 => Some(memory(f, "LBu", "lbu", load_kinds))
    0x25 => Some(memory(f, "LHu", "lhu", load_kinds))
    0x26 if !r6 => Some(memory(f, "LWR", "lwr", load_kinds))
    0x27 if wide => Some(memory(f, "LWu", "lwu", load_kinds))
    0x28 => Some(memory(f, "SB", "sb", store_kinds))
    0x29 => Some(memory(f, "SH", "sh", store_kinds))
    0x2a if !r6 => Some(memory(f, "SWL", "swl", store_kinds))
    0x2b => Some(memory(f, "SW", "sw", store_kinds))
    0x2c if wide && !r6 => Some(memory(f, "SDL", "sdl", store_kinds))
    0x2d if wide && !r6 => Some(memory(f, "SDR", "sdr", store_kinds))
    0x2e if !r6 => Some(memory(f, "SWR", "swr", store_kinds))
    0x2f | 0x33 if !r6 => {
      let (name, mnemonic) = if f.opcode == 0x2f {
        ("CACHE", "cache")
      } else {
        ("PREF", "pref")
      }
      let ops = [gpr32(rs), imm(f.simm16()), imm(rt.to_int64())]
      Some(
        form(
          name,
          mnemonic,
          ops,
          layout=Text("\{mnemonic} \{rt}, \{f.simm16()}(\{ops[0].text})"),
        ),
      )
    }
    0x30 if !r6 => Some(memory(f, "LL", "ll", load_kinds))
    0x31 | 0x35 | 0x39 | 0x3d => decode_fpu_memory(f, arch, r6)
    0x32 | 0x3a | 0x36 | 0x3e if !r6 => {
      let (name, mnemonic, kinds) = match f.opcode {
        0x32 => ("LWC2", "lwc2", load_kinds)
        0x36 => ("LDC2", "ldc2", load_kinds)
        0x3a => ("SWC2", "swc2", store_kinds)
        _ => ("SDC2", "sdc2", store_kinds)
      }
      let cop2 : Operand = {
        op: Reg(name="COP2\{rt}", code=rt),
        text: "$\{rt}",
      }
      Some(
        form(
          name,
          mnemonic,
          [cop2, gpr32(rs), imm(f.simm16())],
          kinds~,
          layout=Mem,
        ),
      )
    }
    0x1d if !r6 =>
      Some(
        form(
          "JALX",
          "jalx",
          [imm((bits(word, 0, 26) << 2).to_int64())],
          kinds=call_kinds,
        ),
      )
    0x1d if r6 && wide =>
      Some(form("DAUI", "daui", [gpr64(rt), gpr64(rs), imm(f.uimm16())]))
    0x32 if r6 =>
      Some(
        form(
          "BC",
          "bc",
          [imm(branch_target(bits(word, 0, 26), 26))],
          kinds=uncond_branch,
        ),
      )
    0x34 if wide && !r6 => Some(memory(f, "LLD", "lld", load_kinds))
    0x36 | 0x3e if r6 => decode_r6_pop_x6(f, arch)
    0x37 if wide => Some(memory(f, "LD", "ld", load_kinds))
    0x38 if !r6 => Some(store_conditional_form("SC", "sc", rt, rs, f.simm16()))
    0x3a if r6 =>
      Some(
        form(
          "BALC",
          "balc",
          [imm(branch_target(bits(word, 0, 26), 26))],
          kinds=call_kinds,
        ),
      )
    0x3b if r6 => decode_r6_pcrel(f, arch)
    0x3c if wide && !r6 =>
      Some(store_conditional_form("SCD", "scd", rt, rs, f.simm16()))
    0x3f if wide => Some(memory(f, "SD", "sd", store_kinds))
    _ => None
  }
}
