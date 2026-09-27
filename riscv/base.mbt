// The 32-bit instructions of the native RISC-V decoder: RV32I/RV64I with
// Zicsr and Zifencei, the privileged `mret`/`sret`/`wfi`/`sfence.vma`, and
// the M, A, F and D extensions.
//
// Opcode names, operand orders and register names follow LLVM's
// `RISCVGenDisassemblerTables` (e.g. stores are `[rs2, rs1, offset]`,
// branch and jump offsets are relative to the instruction, `LUI`/`AUIPC`
// keep the unshifted 20-bit immediate, and FP arithmetic carries the
// rounding mode as a trailing immediate); the assembly is printed like
// LLVM's `RISCVInstPrinter`, with its aliases (`li`, `mv`, `ret`, `j`,
// `beqz`, `csrr`, `fmv.s`, ...).

///|
/// The register width: RV32 or RV64.
pub(all) enum Xlen {
  RV32
  RV64
} derive(Eq, Debug)

///|
pub extend Xlen with Eq::{equal, not_equal}

///|
pub extend Xlen with Debug::{to_repr}

///|
fn bits(word : UInt, lo : Int, count : Int) -> Int {
  ((word >> lo) & ((1U << count) - 1U)).reinterpret_as_int()
}

///|
/// Sign-extend the low `width` bits of `value`.
fn sext(value : Int, width : Int) -> Int64 {
  let v = value.to_int64() & ((1L << width) - 1L)
  if v >> (width - 1) != 0L {
    v - (1L << width)
  } else {
    v
  }
}

///|
/// The I-type immediate.
fn imm_i(w : UInt) -> Int64 {
  sext(bits(w, 20, 12), 12)
}

///|
/// The S-type immediate.
fn imm_s(w : UInt) -> Int64 {
  sext((bits(w, 25, 7) << 5) | bits(w, 7, 5), 12)
}

///|
/// The B-type immediate (a byte offset).
fn imm_b(w : UInt) -> Int64 {
  sext(
    (bits(w, 31, 1) << 12) |
    (bits(w, 7, 1) << 11) |
    (bits(w, 25, 6) << 5) |
    (bits(w, 8, 4) << 1),
    13,
  )
}

///|
/// The J-type immediate (a byte offset).
fn imm_j(w : UInt) -> Int64 {
  sext(
    (bits(w, 31, 1) << 20) |
    (bits(w, 12, 8) << 12) |
    (bits(w, 20, 1) << 11) |
    (bits(w, 21, 10) << 1),
    21,
  )
}

///|
/// `mnemonic reg, offset(base)`.
fn mem_text(
  mnemonic : String,
  reg : Operand,
  base : Operand,
  offset : Int64,
) -> String {
  "\{mnemonic} \{reg.text}, \{offset}(\{base.text})"
}

///|
/// `OP-IMM` forms (`ADDI`, `XORI`, ..., the shifts and their `W`
/// variants) with LLVM's preferred aliases.
fn op_imm(name : String, rd : Int, rs1 : Int, value : Int64) -> Form {
  let ops = [x(rd), x(rs1), imm(value)]
  let mnemonic = name.to_lower()
  let text = match (name, rs1, value) {
    ("ADDI", 0, 0) if rd == 0 => "nop"
    ("ADDI", 0, _) => "li \{ops[0].text}, \{value}"
    ("ADDI", _, 0) => "mv \{ops[0].text}, \{ops[1].text}"
    ("ADDIW", _, 0) => "sext.w \{ops[0].text}, \{ops[1].text}"
    ("XORI", _, -1) => "not \{ops[0].text}, \{ops[1].text}"
    ("SLTIU", _, 1) => "seqz \{ops[0].text}, \{ops[1].text}"
    ("ANDI", _, 255) => "zext.b \{ops[0].text}, \{ops[1].text}"
    _ => plain(mnemonic, ops)
  }
  form(name, mnemonic, ops, assembly=text)
}

///|
/// `OP` forms (`ADD`, `SUB`, ..., `MUL`, ..., and their `W` variants).
fn op_reg(name : String, rd : Int, rs1 : Int, rs2 : Int) -> Form {
  let ops = [x(rd), x(rs1), x(rs2)]
  let mnemonic = name.to_lower()
  let text = match (name, rs1, rs2) {
    ("SUB", 0, _) => "neg \{ops[0].text}, \{ops[2].text}"
    ("SUBW", 0, _) => "negw \{ops[0].text}, \{ops[2].text}"
    ("SLTU", 0, _) => "snez \{ops[0].text}, \{ops[2].text}"
    ("SLT", _, 0) => "sltz \{ops[0].text}, \{ops[1].text}"
    ("SLT", 0, _) => "sgtz \{ops[0].text}, \{ops[2].text}"
    _ => plain(mnemonic, ops)
  }
  form(name, mnemonic, ops, assembly=text)
}

///|
/// Conditional branches: `[rs1, rs2, offset]`.
fn branch(name : String, rs1 : Int, rs2 : Int, offset : Int64) -> Form {
  let ops = [x(rs1), x(rs2), imm(offset)]
  let mnemonic = name.to_lower()
  let a = ops[0].text
  let b = ops[1].text
  let text = match (name, rs1, rs2) {
    ("BEQ", _, 0) => "beqz \{a}, \{offset}"
    ("BNE", _, 0) => "bnez \{a}, \{offset}"
    ("BLT", _, 0) => "bltz \{a}, \{offset}"
    ("BGE", _, 0) => "bgez \{a}, \{offset}"
    ("BLT", 0, _) => "bgtz \{b}, \{offset}"
    ("BGE", 0, _) => "blez \{b}, \{offset}"
    _ => plain(mnemonic, ops)
  }
  form(name, mnemonic, ops, kinds=cond_branch, assembly=text)
}

///|
/// `JAL rd, offset`.
fn jal(rd : Int, offset : Int64) -> Form {
  let ops = [x(rd), imm(offset)]
  let text = match rd {
    0 => "j \{offset}"
    1 => "jal \{offset}"
    _ => plain("jal", ops)
  }
  form("JAL", "jal", ops, kinds=link_kinds(rd, uncond_branch), assembly=text)
}

///|
/// `JALR rd, offset(rs1)`.
fn jalr(rd : Int, rs1 : Int, offset : Int64) -> Form {
  let ops = [x(rd), x(rs1), imm(offset)]
  let base = ops[1].text
  let text = match (rd, rs1, offset) {
    (0, 1, 0) => "ret"
    (0, _, 0) => "jr \{base}"
    (1, _, 0) => "jalr \{base}"
    (0, _, _) => "jr \{offset}(\{base})"
    (1, _, _) => "jalr \{offset}(\{base})"
    _ => "jalr \{ops[0].text}, \{offset}(\{base})"
  }
  form(
    "JALR",
    "jalr",
    ops,
    kinds=link_kinds(rd, indirect_branch),
    assembly=text,
  )
}

///|
/// Loads: `[rd, rs1, offset]` (`reg` gives the class of `rd`).
fn load(
  name : String,
  reg : (Int) -> Operand,
  rd : Int,
  rs1 : Int,
  offset : Int64,
) -> Form {
  let ops = [reg(rd), x(rs1), imm(offset)]
  let mnemonic = name.to_lower()
  form(
    name,
    mnemonic,
    ops,
    kinds=load_kinds,
    assembly=mem_text(mnemonic, ops[0], ops[1], offset),
  )
}

///|
/// Stores: `[rs2, rs1, offset]` (`reg` gives the class of `rs2`).
fn store(
  name : String,
  reg : (Int) -> Operand,
  rs2 : Int,
  rs1 : Int,
  offset : Int64,
) -> Form {
  let ops = [reg(rs2), x(rs1), imm(offset)]
  let mnemonic = name.to_lower()
  form(
    name,
    mnemonic,
    ops,
    kinds=store_kinds,
    assembly=mem_text(mnemonic, ops[0], ops[1], offset),
  )
}

///|
/// The name LLVM prints for the CSR `csr`: its standard name, or its
/// number.
fn csr_name(csr : Int, xlen : Xlen) -> String {
  match csr_names.get(csr) {
    Some(name) => name
    None =>
      match (xlen, csr_names_rv32.get(csr)) {
        (RV32, Some(name)) => name
        _ => csr.to_string()
      }
  }
}

///|
/// The Zicsr instructions and their aliases.
fn decode_csr(w : UInt, xlen : Xlen) -> Form? {
  let rd = bits(w, 7, 5)
  let rs1 = bits(w, 15, 5)
  let csr = bits(w, 20, 12)
  let f3 = bits(w, 12, 3)
  let name = match f3 {
    1 => "CSRRW"
    2 => "CSRRS"
    3 => "CSRRC"
    5 => "CSRRWI"
    6 => "CSRRSI"
    7 => "CSRRCI"
    _ => return None
  }
  let csr_text = csr_name(csr, xlen)
  let source = if f3 < 4 { x(rs1) } else { imm(rs1.to_int64()) }
  let ops = [x(rd), imm_text(csr.to_int64(), csr_text), source]
  let dst = ops[0].text
  let src = source.text
  let text = match (f3, rd, rs1) {
    // reads
    (2, _, 0) =>
      match csr {
        1 => "frflags \{dst}"
        2 => "frrm \{dst}"
        3 => "frcsr \{dst}"
        0xc00 => "rdcycle \{dst}"
        0xc01 => "rdtime \{dst}"
        0xc02 => "rdinstret \{dst}"
        0xc80 if xlen is RV32 => "rdcycleh \{dst}"
        0xc81 if xlen is RV32 => "rdtimeh \{dst}"
        0xc82 if xlen is RV32 => "rdinstreth \{dst}"
        _ => "csrr \{dst}, \{csr_text}"
      }
    // writes and swaps
    (1, _, _) =>
      match (csr, rd) {
        (1, 0) => "fsflags \{src}"
        (2, 0) => "fsrm \{src}"
        (3, 0) => "fscsr \{src}"
        (1, _) => "fsflags \{dst}, \{src}"
        (2, _) => "fsrm \{dst}, \{src}"
        (3, _) => "fscsr \{dst}, \{src}"
        (_, 0) => "csrw \{csr_text}, \{src}"
        _ => "csrrw \{dst}, \{csr_text}, \{src}"
      }
    (5, _, _) =>
      match (csr, rd) {
        (1, 0) => "fsflagsi \{src}"
        (2, 0) => "fsrmi \{src}"
        (1, _) => "fsflagsi \{dst}, \{src}"
        (2, _) => "fsrmi \{dst}, \{src}"
        (_, 0) => "csrwi \{csr_text}, \{src}"
        _ => "csrrwi \{dst}, \{csr_text}, \{src}"
      }
    (2, 0, _) => "csrs \{csr_text}, \{src}"
    (3, 0, _) => "csrc \{csr_text}, \{src}"
    (6, 0, _) => "csrsi \{csr_text}, \{src}"
    (7, 0, _) => "csrci \{csr_text}, \{src}"
    _ => "\{name.to_lower()} \{dst}, \{csr_text}, \{src}"
  }
  Some(form(name, name.to_lower(), ops, assembly=text))
}

///|
/// The text of a `fence` predecessor or successor set.
fn fence_set(set : Int) -> String {
  if set == 0 {
    "0"
  } else {
    let buf = StringBuilder()
    if (set & 8) != 0 {
      buf.write_char('i')
    }
    if (set & 4) != 0 {
      buf.write_char('o')
    }
    if (set & 2) != 0 {
      buf.write_char('r')
    }
    if (set & 1) != 0 {
      buf.write_char('w')
    }
    buf.to_string()
  }
}

///|
/// The system instructions (`ecall`, `ebreak`, `mret`, ...) and Zicsr.
fn decode_system(w : UInt, xlen : Xlen) -> Form? {
  if bits(w, 12, 3) != 0 {
    if w == 0xc0001073U {
      return Some(form("UNIMP", "unimp", []))
    }
    return decode_csr(w, xlen)
  }
  match w {
    0x00000073U => Some(form("ECALL", "ecall", []))
    0x00100073U => Some(form("EBREAK", "ebreak", []))
    0x10200073U => Some(form("SRET", "sret", [], kinds=return_kinds))
    0x30200073U => Some(form("MRET", "mret", [], kinds=return_kinds))
    0x10500073U => Some(form("WFI", "wfi", []))
    _ =>
      if bits(w, 25, 7) == 0x09 && bits(w, 7, 5) == 0 {
        let rs1 = bits(w, 15, 5)
        let rs2 = bits(w, 20, 5)
        let ops = [x(rs1), x(rs2)]
        let text = match (rs1, rs2) {
          (0, 0) => "sfence.vma"
          (_, 0) => "sfence.vma \{ops[0].text}"
          _ => plain("sfence.vma", ops)
        }
        Some(form("SFENCE_VMA", "sfence.vma", ops, assembly=text))
      } else {
        None
      }
  }
}

///|
/// The atomic memory operations of the A extension.
fn decode_amo(w : UInt, xlen : Xlen) -> Form? {
  let width = match bits(w, 12, 3) {
    2 => "W"
    3 if xlen is RV64 => "D"
    _ => return None
  }
  let op = match bits(w, 27, 5) {
    0x02 if bits(w, 20, 5) == 0 => "LR"
    0x03 => "SC"
    0x01 => "AMOSWAP"
    0x00 => "AMOADD"
    0x04 => "AMOXOR"
    0x0c => "AMOAND"
    0x08 => "AMOOR"
    0x10 => "AMOMIN"
    0x14 => "AMOMAX"
    0x18 => "AMOMINU"
    0x1c => "AMOMAXU"
    _ => return None
  }
  let (suffix, text_suffix) = match (bits(w, 26, 1), bits(w, 25, 1)) {
    (0, 0) => ("", "")
    (1, 0) => ("_AQ", ".aq")
    (0, _) => ("_RL", ".rl")
    _ => ("_AQRL", ".aqrl")
  }
  let name = "\{op}_\{width}\{suffix}"
  let mnemonic = "\{op.to_lower()}.\{width.to_lower()}\{text_suffix}"
  let rd = x(bits(w, 7, 5))
  let rs1 = x(bits(w, 15, 5))
  let rs2 = x(bits(w, 20, 5))
  if op == "LR" {
    Some(
      form(
        name,
        mnemonic,
        [rd, rs1],
        kinds=load_kinds,
        assembly="\{mnemonic} \{rd.text}, (\{rs1.text})",
      ),
    )
  } else {
    let kinds = if op == "SC" { store_kinds } else { load_store_kinds }
    Some(
      form(
        name,
        mnemonic,
        [rd, rs2, rs1],
        kinds~,
        assembly="\{mnemonic} \{rd.text}, \{rs2.text}, (\{rs1.text})",
      ),
    )
  }
}

///|
/// The names of the rounding modes (`7`, dynamic, is not printed).
fn rounding_mode(rm : Int) -> String? {
  match rm {
    0 => Some("rne")
    1 => Some("rtz")
    2 => Some("rdn")
    3 => Some("rup")
    4 => Some("rmm")
    7 => Some("dyn")
    _ => None
  }
}

///|
/// A floating point form whose last operand is the rounding mode `rm`
/// (printed after the registers unless dynamic).
fn with_rm(
  name : String,
  mnemonic : String,
  regs : Array[Operand],
  rm : Int,
) -> Form? {
  guard rounding_mode(rm) is Some(mode) else { return None }
  // the exact conversions into doubles take a legacy rounding mode
  // operand, which is printed unless it is `rne`
  let legacy = name is ("FCVT_D_S" | "FCVT_D_W" | "FCVT_D_WU")
  let text = if (legacy && rm == 0) || (!legacy && rm == 7) {
    plain(mnemonic, regs)
  } else {
    plain(mnemonic, regs) + ", " + mode
  }
  let ops = regs.copy()
  ops.push(imm_text(rm.to_int64(), mode))
  Some(form(name, mnemonic, ops, assembly=text))
}

///|
/// The OP-FP instructions of the F and D extensions.
fn decode_op_fp(w : UInt, xlen : Xlen) -> Form? {
  let rd = bits(w, 7, 5)
  let rs1 = bits(w, 15, 5)
  let rs2 = bits(w, 20, 5)
  let rm = bits(w, 12, 3)
  let funct7 = bits(w, 25, 7)
  let double = (funct7 & 1) == 1
  let (fr, sfx, letter) = if double { (fd, "_D", "d") } else { (fs, "_S", "s") }
  let rv64 = xlen is RV64
  match funct7 >> 1 {
    0x00 | 0x02 | 0x04 | 0x06 => {
      let op = match funct7 >> 1 {
        0x00 => "add"
        0x02 => "sub"
        0x04 => "mul"
        _ => "div"
      }
      with_rm(
        "F\{op.to_upper()}\{sfx}",
        "f\{op}.\{letter}",
        [fr(rd), fr(rs1), fr(rs2)],
        rm,
      )
    }
    0x16 if rs2 == 0 =>
      with_rm("FSQRT\{sfx}", "fsqrt.\{letter}", [fr(rd), fr(rs1)], rm)
    0x08 => {
      let (op, short) = match rm {
        0 => ("sgnj", "fmv")
        1 => ("sgnjn", "fneg")
        2 => ("sgnjx", "fabs")
        _ => return None
      }
      let ops = [fr(rd), fr(rs1), fr(rs2)]
      let mnemonic = "f\{op}.\{letter}"
      let text = if rs1 == rs2 {
        "\{short}.\{letter} \{ops[0].text}, \{ops[1].text}"
      } else {
        plain(mnemonic, ops)
      }
      Some(form("F\{op.to_upper()}\{sfx}", mnemonic, ops, assembly=text))
    }
    0x0a => {
      let op = match rm {
        0 => "min"
        1 => "max"
        _ => return None
      }
      Some(
        form("F\{op.to_upper()}\{sfx}", "f\{op}.\{letter}", [
          fr(rd),
          fr(rs1),
          fr(rs2),
        ]),
      )
    }
    0x10 =>
      // fcvt.s.d / fcvt.d.s
      match (double, rs2) {
        (false, 1) => with_rm("FCVT_S_D", "fcvt.s.d", [fs(rd), fd(rs1)], rm)
        (true, 0) => with_rm("FCVT_D_S", "fcvt.d.s", [fd(rd), fs(rs1)], rm)
        _ => None
      }
    0x28 => {
      let op = match rm {
        0 => "le"
        1 => "lt"
        2 => "eq"
        _ => return None
      }
      Some(
        form("F\{op.to_upper()}\{sfx}", "f\{op}.\{letter}", [
          x(rd),
          fr(rs1),
          fr(rs2),
        ]),
      )
    }
    0x30 | 0x34 => {
      let to_int = funct7 >> 1 == 0x30
      let (int_name, int_letter) = match rs2 {
        0 => ("W", "w")
        1 => ("WU", "wu")
        2 if rv64 => ("L", "l")
        3 if rv64 => ("LU", "lu")
        _ => return None
      }
      let fp_name = if double { "D" } else { "S" }
      if to_int {
        with_rm(
          "FCVT_\{int_name}_\{fp_name}",
          "fcvt.\{int_letter}.\{letter}",
          [x(rd), fr(rs1)],
          rm,
        )
      } else {
        with_rm(
          "FCVT_\{fp_name}_\{int_name}",
          "fcvt.\{letter}.\{int_letter}",
          [fr(rd), x(rs1)],
          rm,
        )
      }
    }
    0x38 if rs2 == 0 && (!double || rv64 || rm == 1) =>
      match rm {
        0 =>
          if double {
            Some(form("FMV_X_D", "fmv.x.d", [x(rd), fd(rs1)]))
          } else {
            Some(form("FMV_X_W", "fmv.x.w", [x(rd), fs(rs1)]))
          }
        1 => Some(form("FCLASS\{sfx}", "fclass.\{letter}", [x(rd), fr(rs1)]))
        _ => None
      }
    0x3c if rs2 == 0 && rm == 0 && (!double || rv64) =>
      if double {
        Some(form("FMV_D_X", "fmv.d.x", [fd(rd), x(rs1)]))
      } else {
        Some(form("FMV_W_X", "fmv.w.x", [fs(rd), x(rs1)]))
      }
    _ => None
  }
}

///|
/// Decode the 32-bit instruction word `w`.
fn decode_base(w : UInt, xlen : Xlen) -> Form? {
  let rd = bits(w, 7, 5)
  let f3 = bits(w, 12, 3)
  let rs1 = bits(w, 15, 5)
  let rs2 = bits(w, 20, 5)
  let funct7 = bits(w, 25, 7)
  let rv64 = xlen is RV64
  match bits(w, 0, 7) {
    0x37 => Some(form("LUI", "lui", [x(rd), imm(bits(w, 12, 20).to_int64())]))
    0x17 =>
      Some(form("AUIPC", "auipc", [x(rd), imm(bits(w, 12, 20).to_int64())]))
    0x6f => Some(jal(rd, imm_j(w)))
    0x67 if f3 == 0 => Some(jalr(rd, rs1, imm_i(w)))
    0x63 => {
      let name = match f3 {
        0 => "BEQ"
        1 => "BNE"
        4 => "BLT"
        5 => "BGE"
        6 => "BLTU"
        7 => "BGEU"
        _ => return None
      }
      Some(branch(name, rs1, rs2, imm_b(w)))
    }
    0x03 => {
      let name = match f3 {
        0 => "LB"
        1 => "LH"
        2 => "LW"
        3 if rv64 => "LD"
        4 => "LBU"
        5 => "LHU"
        6 if rv64 => "LWU"
        _ => return None
      }
      Some(load(name, x, rd, rs1, imm_i(w)))
    }
    0x23 => {
      let name = match f3 {
        0 => "SB"
        1 => "SH"
        2 => "SW"
        3 if rv64 => "SD"
        _ => return None
      }
      Some(store(name, x, rs2, rs1, imm_s(w)))
    }
    0x13 =>
      match f3 {
        0 => Some(op_imm("ADDI", rd, rs1, imm_i(w)))
        2 => Some(op_imm("SLTI", rd, rs1, imm_i(w)))
        3 => Some(op_imm("SLTIU", rd, rs1, imm_i(w)))
        4 => Some(op_imm("XORI", rd, rs1, imm_i(w)))
        6 => Some(op_imm("ORI", rd, rs1, imm_i(w)))
        7 => Some(op_imm("ANDI", rd, rs1, imm_i(w)))
        1 | 5 => {
          // the shift amount has 6 bits on RV64 and 5 on RV32
          let (shamt, high) = if rv64 {
            (bits(w, 20, 6), bits(w, 26, 6))
          } else {
            (bits(w, 20, 5), bits(w, 25, 7))
          }
          let arith = if rv64 { 0x10 } else { 0x20 }
          let name = match (f3, high) {
            (1, 0) => "SLLI"
            (5, 0) => "SRLI"
            (5, h) if h == arith => "SRAI"
            _ => return None
          }
          Some(op_imm(name, rd, rs1, shamt.to_int64()))
        }
        _ => None
      }
    0x1b if rv64 =>
      match (f3, funct7) {
        (0, _) => Some(op_imm("ADDIW", rd, rs1, imm_i(w)))
        (1, 0) => Some(op_imm("SLLIW", rd, rs1, rs2.to_int64()))
        (5, 0) => Some(op_imm("SRLIW", rd, rs1, rs2.to_int64()))
        (5, 0x20) => Some(op_imm("SRAIW", rd, rs1, rs2.to_int64()))
        _ => None
      }
    0x33 => {
      let name = match (funct7, f3) {
        (0, 0) => "ADD"
        (0x20, 0) => "SUB"
        (0, 1) => "SLL"
        (0, 2) => "SLT"
        (0, 3) => "SLTU"
        (0, 4) => "XOR"
        (0, 5) => "SRL"
        (0x20, 5) => "SRA"
        (0, 6) => "OR"
        (0, 7) => "AND"
        (1, 0) => "MUL"
        (1, 1) => "MULH"
        (1, 2) => "MULHSU"
        (1, 3) => "MULHU"
        (1, 4) => "DIV"
        (1, 5) => "DIVU"
        (1, 6) => "REM"
        (1, 7) => "REMU"
        _ => return None
      }
      Some(op_reg(name, rd, rs1, rs2))
    }
    0x3b if rv64 => {
      let name = match (funct7, f3) {
        (0, 0) => "ADDW"
        (0x20, 0) => "SUBW"
        (0, 1) => "SLLW"
        (0, 5) => "SRLW"
        (0x20, 5) => "SRAW"
        (1, 0) => "MULW"
        (1, 4) => "DIVW"
        (1, 5) => "DIVUW"
        (1, 6) => "REMW"
        (1, 7) => "REMUW"
        _ => return None
      }
      Some(op_reg(name, rd, rs1, rs2))
    }
    0x0f =>
      match f3 {
        _ if rd != 0 || rs1 != 0 => None
        0 => {
          let pred = bits(w, 24, 4)
          let succ = bits(w, 20, 4)
          if bits(w, 28, 4) == 8 && pred == 3 && succ == 3 {
            Some(form("FENCE_TSO", "fence.tso", []))
          } else if bits(w, 28, 4) != 0 {
            None
          } else {
            let ops = [
              imm_text(pred.to_int64(), fence_set(pred)),
              imm_text(succ.to_int64(), fence_set(succ)),
            ]
            let text = if pred == 15 && succ == 15 {
              "fence"
            } else {
              plain("fence", ops)
            }
            Some(form("FENCE", "fence", ops, assembly=text))
          }
        }
        1 if bits(w, 20, 12) == 0 => Some(form("FENCE_I", "fence.i", []))
        _ => None
      }
    0x73 => decode_system(w, xlen)
    0x2f => decode_amo(w, xlen)
    0x07 =>
      match f3 {
        2 => Some(load("FLW", fs, rd, rs1, imm_i(w)))
        3 => Some(load("FLD", fd, rd, rs1, imm_i(w)))
        _ => None
      }
    0x27 =>
      match f3 {
        2 => Some(store("FSW", fs, rs2, rs1, imm_s(w)))
        3 => Some(store("FSD", fd, rs2, rs1, imm_s(w)))
        _ => None
      }
    0x43 | 0x47 | 0x4b | 0x4f => {
      let (fr, sfx, letter) = match bits(w, 25, 2) {
        0 => (fs, "_S", "s")
        1 => (fd, "_D", "d")
        _ => return None
      }
      let op = match bits(w, 0, 7) {
        0x43 => "madd"
        0x47 => "msub"
        0x4b => "nmsub"
        _ => "nmadd"
      }
      with_rm(
        "F\{op.to_upper()}\{sfx}",
        "f\{op}.\{letter}",
        [fr(rd), fr(rs1), fr(rs2), fr(bits(w, 27, 5))],
        f3,
      )
    }
    0x53 => decode_op_fp(w, xlen)
    _ => None
  }
}
