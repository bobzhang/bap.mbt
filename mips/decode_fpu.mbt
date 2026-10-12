// The floating point (COP1 and COP1X) part of the native MIPS decoder:
// moves between the register files, FPU branches, loads and stores, and the
// arithmetic, conversion, comparison and selection instructions.
//
// The FPU mode follows LLVM's defaults: MIPS32 Release 2 uses 32-bit FPU
// registers (doubles are even/odd pairs `D0`..`D15`, opcode suffix `_D32`),
// MIPS64 and Release 6 use 64-bit ones (`D0_64`..`D31_64`, suffix `_D64`).

///|
/// Whether the FPU registers are 64 bits wide.
fn fp64(arch : Arch, r6 : Bool) -> Bool {
  arch is Mips64 || r6
}

///|
/// The double-precision register `n` of the FPU mode.
fn fpr_double(fp64 : Bool, n : Int32) -> Operand? {
  if fp64 {
    Some(fgr64(n))
  } else {
    afgr64(n)
  }
}

///|
/// `32` or `64`: the width of the double-precision registers of the FPU
/// mode, as used in LLVM names (`CVT_D32_S`, `FADD_D64`).
fn double_bits(fp64 : Bool) -> String {
  if fp64 {
    "64"
  } else {
    "32"
  }
}

///|
/// `LWC1`, `LDC1`, `SWC1` and `SDC1` (LLVM's `DecodeFMem`: `[ft, base,
/// offset]`, where `ft` is decoded as a 64-bit FPU register).
fn decode_fpu_memory(f : Fields, arch : Arch, r6 : Bool) -> Form? {
  let wide = fp64(arch, r6)
  let (name, mnemonic, kinds) = match f.opcode {
    0x31 => ("LWC1", "lwc1", load_kinds)
    0x39 => ("SWC1", "swc1", store_kinds)
    0x35 => (if wide { "LDC164" } else { "LDC1" }, "ldc1", load_kinds)
    _ => (if wide { "SDC164" } else { "SDC1" }, "sdc1", store_kinds)
  }
  Some(
    form(
      name,
      mnemonic,
      [fgr64(f.rt), gpr32(f.rs), imm(f.simm16())],
      kinds~,
      layout=Mem,
    ),
  )
}

///|
/// Names of the `c.cond.fmt` conditions, by the low four bits of the
/// function field.
let fpu_conditions : ReadOnlyArray[String] = [
  "f", "un", "eq", "ueq", "olt", "ult", "ole", "ule", "sf", "ngle", "seq", "ngl",
  "lt", "nge", "le", "ngt",
]

///|
/// Names of the Release 6 `cmp.cond.fmt` conditions (the assembly name,
/// and the LLVM name, which spells `af` as `F`), by the function field.
let fpu_r6_conditions : ReadOnlyArray[(String, String)] = [
  ("af", "F"),
  ("un", "UN"),
  ("eq", "EQ"),
  ("ueq", "UEQ"),
  ("lt", "LT"),
  ("ult", "ULT"),
  ("le", "LE"),
  ("ule", "ULE"),
  ("saf", "SAF"),
  ("sun", "SUN"),
  ("seq", "SEQ"),
  ("sueq", "SUEQ"),
  ("slt", "SLT"),
  ("sult", "SULT"),
  ("sle", "SLE"),
  ("sule", "SULE"),
]

///|
/// The COP1 opcode space.
fn decode_cop1(f : Fields, arch : Arch, r6 : Bool) -> Form? {
  let wide = arch is Mips64
  let fp64 = fp64(arch, r6)
  let rt = f.rt
  let fs = f.rd
  let zero_low = bits(f.word, 0, 11) == 0
  let dbits = double_bits(fp64)
  match f.rs {
    0x00 if zero_low =>
      if fp64 {
        Some(form("MFC1_D64", "mfc1", [gpr32(rt), fgr64(fs)]))
      } else {
        Some(form("MFC1", "mfc1", [gpr32(rt), fgr32(fs)]))
      }
    0x01 if zero_low && wide =>
      Some(form("DMFC1", "dmfc1", [gpr64(rt), fgr64(fs)]))
    0x02 if zero_low => Some(form("CFC1", "cfc1", [gpr32(rt), fcr(fs)]))
    0x03 if zero_low =>
      match fpr_double(fp64, fs) {
        Some(d) => Some(form("MFHC1_D\{dbits}", "mfhc1", [gpr32(rt), d]))
        None => None
      }
    0x04 if zero_low =>
      if fp64 {
        Some(fpu_move_to("MTC1_D64", "mtc1", [fgr64(fs), gpr32(rt)]))
      } else {
        Some(fpu_move_to("MTC1", "mtc1", [fgr32(fs), gpr32(rt)]))
      }
    0x05 if zero_low && wide =>
      Some(fpu_move_to("DMTC1", "dmtc1", [fgr64(fs), gpr64(rt)]))
    0x06 if zero_low => Some(fpu_move_to("CTC1", "ctc1", [fcr(fs), gpr32(rt)]))
    0x07 if zero_low =>
      match fpr_double(fp64, fs) {
        // the high half is inserted into the (tied) input register
        Some(d) =>
          Some(fpu_move_to("MTHC1_D\{dbits}", "mthc1", [d, d, gpr32(rt)]))
        None => None
      }
    0x08 if !r6 => {
      let cc = bits(f.word, 18, 3)
      let (name, mnemonic) = match bits(f.word, 16, 2) {
        0 => ("BC1F", "bc1f")
        1 => ("BC1T", "bc1t")
        2 => ("BC1FL", "bc1fl")
        _ => ("BC1TL", "bc1tl")
      }
      let target = branch_target(f.imm16, 16)
      let text = if cc == 0 {
        "\{mnemonic} \{target}"
      } else {
        "\{mnemonic} $fcc\{cc}, \{target}"
      }
      Some(
        form(
          name,
          mnemonic,
          [fcc(cc), imm(target)],
          kinds=cond_branch,
          layout=Text(text),
        ),
      )
    }
    0x09 | 0x0d if r6 => {
      let (name, mnemonic) = if f.rs == 0x09 {
        ("BC1EQZ", "bc1eqz")
      } else {
        ("BC1NEZ", "bc1nez")
      }
      Some(
        form(
          name,
          mnemonic,
          [fgr64(rt), imm(branch_target(f.imm16, 16))],
          kinds=cond_branch,
        ),
      )
    }
    0x10 | 0x11 | 0x14 | 0x15 => decode_fpu_arith(f, arch, r6)
    0x16 if wide && !r6 => decode_fpu_paired(f)
    _ => None
  }
}

///|
/// A move from a GPR into an FPU register (the operands start with the
/// FPU register and end with the GPR), printed `mnemonic rt, fs`.
fn fpu_move_to(name : String, mnemonic : String, ops : Array[Operand]) -> Form {
  let fpr = ops[0]
  let gpr = ops[ops.length() - 1]
  form(name, mnemonic, ops, layout=Text("\{mnemonic} \{gpr.text}, \{fpr.text}"))
}

///|
/// The format of an FPU operand: single (`S`), double (`D`), word (`W`) or
/// long (`L`).
priv enum FpuFmt {
  S
  D
  W
  L
}

///|
/// The register of the format `fmt` numbered `n`: 32-bit registers for
/// singles and words, doubles in the FPU mode, and 64-bit registers for
/// longs.
fn fpu_reg(fp64 : Bool, fmt : FpuFmt, n : Int32) -> Operand? {
  match fmt {
    S | W => Some(fgr32(n))
    D => fpr_double(fp64, n)
    L => Some(fgr64(n))
  }
}

///|
/// The COP1 arithmetic, conversion, comparison and selection instructions
/// of the formats `S`, `D`, `W` and `L`.
fn decode_fpu_arith(f : Fields, arch : Arch, r6 : Bool) -> Form? {
  let fp64 = fp64(arch, r6)
  let fmt : FpuFmt = match f.rs {
    0x10 => S
    0x11 => D
    0x14 => W
    _ => L
  }
  if r6 && fmt is (W | L) && f.funct < 0x20 {
    return decode_fpu_r6_compare(f, fmt)
  }
  // long sources need the 64-bit FPU mode (long results do not)
  if fmt is L && !fp64 {
    return None
  }
  let ft = f.rt
  let fs = f.rd
  let fd = f.sa
  let dbits = double_bits(fp64)
  // the format of the LLVM names and of the assembly
  let (suffix, letter) = match fmt {
    S => ("_S", "s")
    D => ("_D\{dbits}", "d")
    W => ("_W", "w")
    L => ("_L", "l")
  }
  let reg = (x : FpuFmt, n : Int32) => fpu_reg(fp64, x, n)
  let binary = (op : String) => {
    guard fmt is (S | D) else { return None }
    match (reg(fmt, fd), reg(fmt, fs), reg(fmt, ft)) {
      (Some(d), Some(s), Some(t)) =>
        Some(form("F\{op.to_upper()}\{suffix}", "\{op}.\{letter}", [d, s, t]))
      _ => None
    }
  }
  // `name fd, fs` converting from `fmt` into `into`
  let unary = (name : String, mnemonic : String, into : FpuFmt) => {
    guard ft == 0 else { return None }
    match (reg(into, fd), reg(fmt, fs)) {
      (Some(d), Some(s)) => Some(form(name, mnemonic, [d, s]))
      _ => None
    }
  }
  // the name of a format in a conversion name
  let conv = (x : FpuFmt) => {
    match x {
      S => "S"
      D => "D\{dbits}"
      W => "W"
      L => "L"
    }
  }
  let round = (op : String, into : FpuFmt) => {
    guard fmt is (S | D) else { return None }
    let (into_name, into_letter) = if into is W {
      ("W", "w")
    } else {
      ("L", "l")
    }
    unary(
      "\{op.to_upper()}_\{into_name}_\{conv(fmt)}",
      "\{op}.\{into_letter}.\{letter}",
      into,
    )
  }
  // Release 6 three-operand forms over `S`/`D` (`name fd, fs, ft`); the
  // LLVM names use `_S`/`_D` whatever the FPU mode
  let r6_binary = (op : String, tied : Bool) => {
    guard r6 && fmt is (S | D) else { return None }
    let name = "\{op.to_upper().replace_all(old=".", new="")}_\{letter.to_upper()}"
    match (reg(fmt, fd), reg(fmt, fs), reg(fmt, ft)) {
      (Some(d), Some(s), Some(t)) => {
        let ops = if tied { [d, d, s, t] } else { [d, s, t] }
        Some(
          form(
            name,
            "\{op}.\{letter}",
            ops,
            layout=Text("\{op}.\{letter} \{d.text}, \{s.text}, \{t.text}"),
          ),
        )
      }
      _ => None
    }
  }
  match f.funct {
    0x00 => binary("add")
    0x01 => binary("sub")
    0x02 => binary("mul")
    0x03 => binary("div")
    0x04 if fmt is (S | D) => unary("FSQRT" + suffix, "sqrt." + letter, fmt)
    0x05 if fmt is (S | D) => unary("FABS" + suffix, "abs." + letter, fmt)
    0x06 if fmt is (S | D) => unary("FMOV" + suffix, "mov." + letter, fmt)
    0x07 if fmt is (S | D) => unary("FNEG" + suffix, "neg." + letter, fmt)
    0x08 => round("round", L)
    0x09 => round("trunc", L)
    0x0a => round("ceil", L)
    0x0b => round("floor", L)
    0x0c => round("round", W)
    0x0d => round("trunc", W)
    0x0e => round("ceil", W)
    0x0f => round("floor", W)
    0x10 => r6_binary("sel", true)
    0x11 if !r6 && fmt is (S | D) && bits(f.word, 17, 1) == 0 => {
      let cc = bits(f.word, 18, 3)
      let (op, mnemonic) = if bits(f.word, 16, 1) == 0 {
        ("MOVF", "movf")
      } else {
        ("MOVT", "movt")
      }
      match (reg(fmt, fd), reg(fmt, fs)) {
        (Some(d), Some(s)) =>
          Some(
            form(
              "\{op}\{suffix}",
              "\{mnemonic}.\{letter}",
              [d, s, fcc(cc), d],
              layout=Text(
                "\{mnemonic}.\{letter} \{d.text}, \{s.text}, $fcc\{cc}",
              ),
            ),
          )
        _ => None
      }
    }
    0x12 | 0x13 if !r6 && fmt is (S | D) => {
      let (op, mnemonic) = if f.funct == 0x12 {
        ("MOVZ_I", "movz")
      } else {
        ("MOVN_I", "movn")
      }
      match (reg(fmt, fd), reg(fmt, fs)) {
        (Some(d), Some(s)) => {
          let g = gpr32(ft)
          Some(
            form(
              "\{op}\{suffix}",
              "\{mnemonic}.\{letter}",
              [d, s, g, d],
              layout=Text(
                "\{mnemonic}.\{letter} \{d.text}, \{s.text}, \{g.text}",
              ),
            ),
          )
        }
        _ => None
      }
    }
    0x14 => r6_binary("seleqz", false)
    0x17 => r6_binary("selnez", false)
    0x18 => r6_binary("maddf", true)
    0x19 => r6_binary("msubf", true)
    0x1c => r6_binary("min", false)
    0x1d => r6_binary("mina", false)
    0x1e => r6_binary("max", false)
    0x1f => r6_binary("maxa", false)
    0x20 if !(fmt is S) => unary("CVT_S_\{conv(fmt)}", "cvt.s.\{letter}", S)
    0x21 if !(fmt is D) =>
      unary("CVT_\{conv(D)}_\{conv(fmt)}", "cvt.d.\{letter}", D)
    0x24 if fmt is (S | D) => unary("CVT_W_\{conv(fmt)}", "cvt.w.\{letter}", W)
    0x26 if fmt is S && arch is Mips64 && !r6 =>
      Some(form("CVT_PS_S64", "cvt.ps.s", [fgr64(fd), fgr32(fs), fgr32(ft)]))
    0x25 if fmt is (S | D) => unary("CVT_L_\{conv(fmt)}", "cvt.l.\{letter}", L)
    0x30..<=0x3f if !r6 && fmt is (S | D) && bits(f.word, 6, 2) == 0 => {
      let cc = bits(f.word, 8, 3)
      let cond = fpu_conditions[f.funct - 0x30]
      match (reg(fmt, fs), reg(fmt, ft)) {
        (Some(s), Some(t)) => {
          let mnemonic = "c.\{cond}.\{letter}"
          let text = if cc == 0 {
            "\{mnemonic} \{s.text}, \{t.text}"
          } else {
            "\{mnemonic} $fcc\{cc}, \{s.text}, \{t.text}"
          }
          Some(
            form(
              "C_\{cond.to_upper()}\{suffix}",
              mnemonic,
              [fcc(cc), s, t],
              layout=Text(text),
            ),
          )
        }
        _ => None
      }
    }
    _ => None
  }
}

///|
/// Release 6 `cmp.cond.fmt fd, fs, ft` (encoded with the `W` format for
/// singles and the `L` format for doubles).
fn decode_fpu_r6_compare(f : Fields, fmt : FpuFmt) -> Form? {
  guard f.funct < 16 else { return None }
  let (cond, name) = fpu_r6_conditions[f.funct]
  let (reg, letter) = if fmt is W { (fgr32, "s") } else { (fgr64, "d") }
  Some(
    form("CMP_\{name}_\{letter.to_upper()}", "cmp.\{cond}.\{letter}", [
      reg(f.sa),
      reg(f.rd),
      reg(f.rt),
    ]),
  )
}

///|
/// The COP1X opcode space (primary opcode `0x13`, removed in Release 6):
/// indexed FPU loads and stores and the fused multiply-add family.
fn decode_cop1x(f : Fields, arch : Arch) -> Form? {
  let fp64 = fp64(arch, false)
  let dbits = double_bits(fp64)
  // the unaligned forms use `GPR64` address registers on MIPS64
  let base = gpr32(f.rs)
  let index = gpr32(f.rt)
  let (ubase, uindex) = if arch is Mips64 {
    (gpr64(f.rs), gpr64(f.rt))
  } else {
    (base, index)
  }
  let indexed = (
    name : String,
    mnemonic : String,
    reg : Operand?,
    kinds : Array[@mc.Kind],
  ) => {
    let (base, index) = if name.has_prefix("LUXC1") || name.has_prefix("SUXC1") {
      (ubase, uindex)
    } else {
      (base, index)
    }
    match reg {
      Some(r) =>
        Some(
          form(
            name,
            mnemonic,
            [r, base, index],
            kinds~,
            layout=Text("\{mnemonic} \{r.text}, \{index.text}(\{base.text})"),
          ),
        )
      None => None
    }
  }
  let d64 = if fp64 { "64" } else { "" }
  match f.funct {
    0x00 if f.rd == 0 =>
      indexed("LWXC1", "lwxc1", Some(fgr32(f.sa)), load_kinds)
    0x01 if f.rd == 0 =>
      indexed("LDXC1\{d64}", "ldxc1", fpr_double(fp64, f.sa), load_kinds)
    0x05 if f.rd == 0 =>
      indexed("LUXC1\{d64}", "luxc1", fpr_double(fp64, f.sa), load_kinds)
    0x08 if f.sa == 0 =>
      indexed("SWXC1", "swxc1", Some(fgr32(f.rd)), store_kinds)
    0x09 if f.sa == 0 =>
      indexed("SDXC1\{d64}", "sdxc1", fpr_double(fp64, f.rd), store_kinds)
    0x0d if f.sa == 0 =>
      indexed("SUXC1\{d64}", "suxc1", fpr_double(fp64, f.rd), store_kinds)
    0x20 | 0x21 | 0x28 | 0x29 | 0x30 | 0x31 | 0x38 | 0x39 => {
      let double = (f.funct & 1) == 1
      let op = match f.funct >> 3 {
        4 => "madd"
        5 => "msub"
        6 => "nmadd"
        _ => "nmsub"
      }
      let (suffix, letter) = if double {
        ("_D\{dbits}", "d")
      } else {
        ("_S", "s")
      }
      let reg = (n : Int32) => {
        if double {
          fpr_double(fp64, n)
        } else {
          Some(fgr32(n))
        }
      }
      match (reg(f.sa), reg(f.rs), reg(f.rd), reg(f.rt)) {
        (Some(fd), Some(fr), Some(fs), Some(ft)) =>
          Some(
            form("\{op.to_upper()}\{suffix}", "\{op}.\{letter}", [
              fd, fr, fs, ft,
            ]),
          )
        _ => None
      }
    }
    _ => None
  }
}

///|
/// The paired-single (`PS`) format instructions of MIPS64 Release 2.
fn decode_fpu_paired(f : Fields) -> Form? {
  let name = match f.funct {
    0x00 => "FADD_PS64"
    0x01 => "FSUB_PS64"
    0x02 => "FMUL_PS64"
    0x2c => "PLL_PS64"
    0x2d => "PLU_PS64"
    0x2e => "PUL_PS64"
    0x2f => "PUU_PS64"
    _ => return None
  }
  let mnemonic = match f.funct {
    0x00 => "add.ps"
    0x01 => "sub.ps"
    0x02 => "mul.ps"
    0x2c => "pll.ps"
    0x2d => "plu.ps"
    0x2e => "pul.ps"
    _ => "puu.ps"
  }
  Some(form(name, mnemonic, [fgr64(f.sa), fgr64(f.rd), fgr64(f.rt)]))
}
