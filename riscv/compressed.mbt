// The 16-bit instructions of the C extension. LLVM decodes them into the
// `C_*` opcodes (with the operands of the compressed form, e.g. `C_ADDI`
// repeats the destination as its tied source), and prints them as the
// instruction they expand to (`c.addi sp, -16` is printed as `addi sp,
// sp, -16`), so each form below is built from its expansion with the
// compressed name and operands.

///|
/// The form `base` (an expansion) renamed to the compressed opcode `name`
/// with the operands `ops`.
fn compressed(
  base : Form,
  name : String,
  ops : Array[Operand],
  kinds? : Array[@mc.Kind],
) -> Form {
  {
    ..base,
    name,
    operands: ops,
    kinds: match kinds {
      Some(k) => k
      None => base.kinds
    },
  }
}

///|
/// A compressed form that LLVM prints with its own `c.` mnemonic (the
/// hints and reserved forms that have no expansion).
fn compressed_text(name : String, ops : Array[Operand], text : String) -> Form {
  { name, operands: ops, kinds: [], assembly: text, }
}

///|
/// The 3-bit register fields of the compressed formats denote `x8`-`x15`.
fn creg(field : Int) -> Int {
  8 + field
}

///|
/// The 6-bit signed immediate `imm[5] = bit 12`, `imm[4:0] = bits 6:2`.
fn ci_imm(h : UInt) -> Int64 {
  sext((bits(h, 12, 1) << 5) | bits(h, 2, 5), 6)
}

///|
/// The 6-bit unsigned shift amount of `c.slli`/`c.srli`/`c.srai`.
fn ci_shamt(h : UInt) -> Int {
  (bits(h, 12, 1) << 5) | bits(h, 2, 5)
}

///|
/// The offset of `c.lw`/`c.sw`/`c.flw`/`c.fsw`: `uimm[5:3] = bits 12:10`,
/// `uimm[2] = bit 6`, `uimm[6] = bit 5`.
fn cl_word_offset(h : UInt) -> Int64 {
  ((bits(h, 10, 3) << 3) | (bits(h, 6, 1) << 2) | (bits(h, 5, 1) << 6)).to_int64()
}

///|
/// The offset of `c.ld`/`c.sd`/`c.fld`/`c.fsd`: `uimm[5:3] = bits 12:10`,
/// `uimm[7:6] = bits 6:5`.
fn cl_double_offset(h : UInt) -> Int64 {
  ((bits(h, 10, 3) << 3) | (bits(h, 5, 2) << 6)).to_int64()
}

///|
/// The jump offset of `c.j`/`c.jal`.
fn cj_offset(h : UInt) -> Int64 {
  sext(
    (bits(h, 12, 1) << 11) |
    (bits(h, 11, 1) << 4) |
    (bits(h, 9, 2) << 8) |
    (bits(h, 8, 1) << 10) |
    (bits(h, 7, 1) << 6) |
    (bits(h, 6, 1) << 7) |
    (bits(h, 3, 3) << 1) |
    (bits(h, 2, 1) << 5),
    12,
  )
}

///|
/// The branch offset of `c.beqz`/`c.bnez`.
fn cb_offset(h : UInt) -> Int64 {
  sext(
    (bits(h, 12, 1) << 8) |
    (bits(h, 10, 2) << 3) |
    (bits(h, 5, 2) << 6) |
    (bits(h, 3, 2) << 1) |
    (bits(h, 2, 1) << 5),
    9,
  )
}

///|
/// Quadrant 0: stack-pointer based additions, loads and stores.
fn decode_c0(h : UInt, xlen : Xlen) -> Form? {
  let rd = creg(bits(h, 2, 3))
  let rs1 = creg(bits(h, 7, 3))
  let rv64 = xlen is RV64
  match bits(h, 13, 3) {
    0 => {
      if h == 0U {
        return Some(compressed_text("C_UNIMP", [], "unimp"))
      }
      let offset = ((bits(h, 7, 4) << 6) |
      (bits(h, 11, 2) << 4) |
      (bits(h, 5, 1) << 3) |
      (bits(h, 6, 1) << 2)).to_int64()
      guard offset != 0L else { return None }
      Some(
        compressed(op_imm("ADDI", rd, 2, offset), "C_ADDI4SPN", [
          x(rd),
          x(2),
          imm(offset),
        ]),
      )
    }
    1 => {
      let base = load("FLD", fd, rd, rs1, cl_double_offset(h))
      Some(compressed(base, "C_FLD", base.operands))
    }
    2 => {
      let base = load("LW", x, rd, rs1, cl_word_offset(h))
      Some(compressed(base, "C_LW", base.operands))
    }
    3 =>
      if rv64 {
        let base = load("LD", x, rd, rs1, cl_double_offset(h))
        Some(compressed(base, "C_LD", base.operands))
      } else {
        let base = load("FLW", fs, rd, rs1, cl_word_offset(h))
        Some(compressed(base, "C_FLW", base.operands))
      }
    5 => {
      let base = store("FSD", fd, rd, rs1, cl_double_offset(h))
      Some(compressed(base, "C_FSD", base.operands))
    }
    6 => {
      let base = store("SW", x, rd, rs1, cl_word_offset(h))
      Some(compressed(base, "C_SW", base.operands))
    }
    7 =>
      if rv64 {
        let base = store("SD", x, rd, rs1, cl_double_offset(h))
        Some(compressed(base, "C_SD", base.operands))
      } else {
        let base = store("FSW", fs, rd, rs1, cl_word_offset(h))
        Some(compressed(base, "C_FSW", base.operands))
      }
    _ => None
  }
}

///|
/// Quadrant 1: immediates, arithmetic, jumps and branches.
fn decode_c1(h : UInt, xlen : Xlen) -> Form? {
  let rd = bits(h, 7, 5)
  let rv64 = xlen is RV64
  match bits(h, 13, 3) {
    0 => {
      let value = ci_imm(h)
      if rd == 0 {
        if value == 0L {
          Some(compressed(op_imm("ADDI", 0, 0, 0L), "C_NOP", []))
        } else {
          Some(compressed_text("C_NOP_HINT", [imm(value)], "c.nop \{value}"))
        }
      } else if value == 0L {
        let ops = [x(rd), x(rd), imm(0L)]
        Some(compressed_text("C_ADDI", ops, "c.addi \{ops[0].text}, 0"))
      } else {
        Some(
          compressed(op_imm("ADDI", rd, rd, value), "C_ADDI", [
            x(rd),
            x(rd),
            imm(value),
          ]),
        )
      }
    }
    1 =>
      if rv64 {
        guard rd != 0 else { return None }
        let value = ci_imm(h)
        Some(
          compressed(op_imm("ADDIW", rd, rd, value), "C_ADDIW", [
            x(rd),
            x(rd),
            imm(value),
          ]),
        )
      } else {
        let offset = cj_offset(h)
        Some(compressed(jal(1, offset), "C_JAL", [imm(offset)]))
      }
    2 => {
      let value = ci_imm(h)
      if rd == 0 {
        Some(compressed_text("C_LI", [x(0), imm(value)], "c.li zero, \{value}"))
      } else {
        Some(
          compressed(op_imm("ADDI", rd, 0, value), "C_LI", [x(rd), imm(value)]),
        )
      }
    }
    3 =>
      if rd == 2 {
        let value = sext(
          (bits(h, 12, 1) << 9) |
          (bits(h, 6, 1) << 4) |
          (bits(h, 5, 1) << 6) |
          (bits(h, 3, 2) << 7) |
          (bits(h, 2, 1) << 5),
          10,
        )
        guard value != 0L else { return None }
        Some(
          compressed(op_imm("ADDI", 2, 2, value), "C_ADDI16SP", [
            x(2),
            x(2),
            imm(value),
          ]),
        )
      } else {
        let raw = ci_shamt(h)
        guard raw != 0 else { return None }
        // LLVM's `decodeCLUIImmOperand`: negative values are kept as
        // 20-bit unsigned numbers
        let value = if raw > 31 {
          sext(raw, 6) & 0xfffffL
        } else {
          raw.to_int64()
        }
        let ops = [x(rd), imm(value)]
        if rd == 0 {
          Some(compressed_text("C_LUI", ops, "c.lui zero, \{value}"))
        } else {
          Some(compressed(form("LUI", "lui", ops), "C_LUI", ops))
        }
      }
    4 => {
      let rd = creg(bits(h, 7, 3))
      let rs2 = creg(bits(h, 2, 3))
      match bits(h, 10, 2) {
        0 | 1 => {
          let shamt = ci_shamt(h)
          guard rv64 || shamt < 32 else { return None }
          let (name, base) = if bits(h, 10, 2) == 0 {
            ("C_SRLI", "SRLI")
          } else {
            ("C_SRAI", "SRAI")
          }
          let ops = [x(rd), x(rd), imm(shamt.to_int64())]
          if shamt == 0 {
            // the shift-by-zero hints are printed in their compressed form
            Some(
              compressed_text(
                name,
                ops,
                "\{name.to_lower().replace(old="_", new=".")} \{ops[0].text}, 0",
              ),
            )
          } else {
            Some(compressed(op_imm(base, rd, rd, shamt.to_int64()), name, ops))
          }
        }
        2 => {
          let value = ci_imm(h)
          Some(
            compressed(op_imm("ANDI", rd, rd, value), "C_ANDI", [
              x(rd),
              x(rd),
              imm(value),
            ]),
          )
        }
        _ => {
          let (name, base) = match (bits(h, 12, 1), bits(h, 5, 2)) {
            (0, 0) => ("C_SUB", "SUB")
            (0, 1) => ("C_XOR", "XOR")
            (0, 2) => ("C_OR", "OR")
            (0, 3) => ("C_AND", "AND")
            (1, 0) if rv64 => ("C_SUBW", "SUBW")
            (1, 1) if rv64 => ("C_ADDW", "ADDW")
            _ => return None
          }
          Some(
            compressed(op_reg(base, rd, rd, rs2), name, [x(rd), x(rd), x(rs2)]),
          )
        }
      }
    }
    5 => {
      let offset = cj_offset(h)
      Some(
        compressed(jal(0, offset), "C_J", [imm(offset)], kinds=uncond_branch),
      )
    }
    _ => {
      let rs1 = creg(bits(h, 7, 3))
      let offset = cb_offset(h)
      let (name, base) = if bits(h, 13, 3) == 6 {
        ("C_BEQZ", "BEQ")
      } else {
        ("C_BNEZ", "BNE")
      }
      Some(
        compressed(branch(base, rs1, 0, offset), name, [x(rs1), imm(offset)]),
      )
    }
  }
}

///|
/// Quadrant 2: shifts, stack-pointer based loads and stores, register
/// moves, jumps and `ebreak`.
fn decode_c2(h : UInt, xlen : Xlen) -> Form? {
  let rd = bits(h, 7, 5)
  let rs2 = bits(h, 2, 5)
  let rv64 = xlen is RV64
  // stack-relative offsets
  let lwsp = ((bits(h, 12, 1) << 5) |
  (bits(h, 4, 3) << 2) |
  (bits(h, 2, 2) << 6)).to_int64()
  let ldsp = ((bits(h, 12, 1) << 5) |
  (bits(h, 5, 2) << 3) |
  (bits(h, 2, 3) << 6)).to_int64()
  let swsp = ((bits(h, 9, 4) << 2) | (bits(h, 7, 2) << 6)).to_int64()
  let sdsp = ((bits(h, 10, 3) << 3) | (bits(h, 7, 3) << 6)).to_int64()
  match bits(h, 13, 3) {
    0 => {
      let shamt = ci_shamt(h)
      guard rv64 || shamt < 32 else { return None }
      let ops = [x(rd), x(rd), imm(shamt.to_int64())]
      if rd == 0 || shamt == 0 {
        Some(compressed_text("C_SLLI", ops, "c.slli \{ops[0].text}, \{shamt}"))
      } else {
        Some(
          compressed(op_imm("SLLI", rd, rd, shamt.to_int64()), "C_SLLI", ops),
        )
      }
    }
    1 => {
      let base = load("FLD", fd, rd, 2, ldsp)
      Some(compressed(base, "C_FLDSP", base.operands))
    }
    2 => {
      guard rd != 0 else { return None }
      let base = load("LW", x, rd, 2, lwsp)
      Some(compressed(base, "C_LWSP", base.operands))
    }
    3 =>
      if rv64 {
        guard rd != 0 else { return None }
        let base = load("LD", x, rd, 2, ldsp)
        Some(compressed(base, "C_LDSP", base.operands))
      } else {
        let base = load("FLW", fs, rd, 2, lwsp)
        Some(compressed(base, "C_FLWSP", base.operands))
      }
    4 =>
      match (bits(h, 12, 1), rd, rs2) {
        (0, 0, 0) => None
        (0, _, 0) =>
          Some(
            compressed(jalr(0, rd, 0L), "C_JR", [x(rd)], kinds=indirect_branch),
          )
        (0, 0, _) =>
          Some(
            compressed_text("C_MV", [x(0), x(rs2)], "c.mv zero, \{x(rs2).text}"),
          )
        (0, _, _) =>
          Some(compressed(op_imm("ADDI", rd, rs2, 0L), "C_MV", [x(rd), x(rs2)]))
        (_, 0, 0) =>
          Some(compressed(form("EBREAK", "ebreak", []), "C_EBREAK", []))
        (_, _, 0) => Some(compressed(jalr(1, rd, 0L), "C_JALR", [x(rd)]))
        (_, 0, _) =>
          Some(
            compressed_text(
              "C_ADD",
              [x(0), x(0), x(rs2)],
              "c.add zero, \{x(rs2).text}",
            ),
          )
        _ =>
          Some(
            compressed(op_reg("ADD", rd, rd, rs2), "C_ADD", [
              x(rd),
              x(rd),
              x(rs2),
            ]),
          )
      }
    5 => {
      let base = store("FSD", fd, rs2, 2, sdsp)
      Some(compressed(base, "C_FSDSP", base.operands))
    }
    6 => {
      let base = store("SW", x, rs2, 2, swsp)
      Some(compressed(base, "C_SWSP", base.operands))
    }
    _ =>
      if rv64 {
        let base = store("SD", x, rs2, 2, sdsp)
        Some(compressed(base, "C_SDSP", base.operands))
      } else {
        let base = store("FSW", fs, rs2, 2, swsp)
        Some(compressed(base, "C_FSWSP", base.operands))
      }
  }
}

///|
/// Decode the 16-bit instruction `h` (whose low two bits are not `11`).
fn decode_compressed(h : UInt, xlen : Xlen) -> Form? {
  match bits(h, 0, 2) {
    0 => decode_c0(h, xlen)
    1 => decode_c1(h, xlen)
    _ => decode_c2(h, xlen)
  }
}
