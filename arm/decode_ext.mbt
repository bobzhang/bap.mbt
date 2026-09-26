// Table-driven decoding of the A32 instructions the lifter does not model:
// VFP (data processing, loads and stores, transfers, `vmrs`/`vmsr`), NEON
// (all data-processing classes and the element and structure loads and
// stores), the coprocessor instructions (`mcr`/`mrc`, `cdp`, `ldc`/`stc`,
// `mcrr`/`mrrc` and their `2` forms) and the media, saturating and
// parallel arithmetic instructions, as the LLVM ARM disassembler decodes
// them. `decode_a32_word` uses it for the words its decoder does not
// decode, so that recursive disassembly does not stop at them; the
// instructions lift as `Unsupported` when no semantics define them.
//
// Each class is an encoding class of the ARM ARM. Its key bits (refined by
// `rules`, as for the PowerPC tables: two-register VFP forms, `vmrs` to
// `APSR_nzcv`, zero offsets, `vmov` aliases, writeback forms of the NEON
// loads and stores, ...) select an entry of `decode_ext_tables.mbt`: the
// LLVM opcode name, templates of the operand list and of the assembly,
// the bits that must be zero and, for register lists, the largest first
// register. A `%slot%` of a template is a value computed from the word
// (see `ArmClass::slot`): an operand field, a register named from a field
// (`G:n` is `R0`..`PC`, `g:n` its assembly name), a VFP/NEON register
// number (`sd` is `Vd:D`, `dd` is `D:Vd`, `qd` is `dd / 2`, `DP:dd` a
// register pair, ...) or a class-specific value (immediates, shift
// amounts, lane indices). The predicate operands of conditional classes
// are `Imm:%c% Reg:%P:c%` and the condition suffix follows the mnemonic,
// as LLVM prints it. The tables were learned from, and are checked
// against, LLVM 22's disassembler (`armv7-linux-gnueabi`).

///|
priv enum ArmFlag {
  NoFlag
  Zero(Array[Int])
  Eq(Array[Int], Array[Int])
  Vals(Array[Int], Array[Int])
}

///|
/// Class-level validity conditions (beyond the class bits).
priv enum ArmValid {
  Always
  /// Coprocessors 10 and 11 are VFP/NEON.
  NotVfp
  /// ... and the `P`/`W` bits of `LDC`/`STC` are not both clear.
  NotVfpLdc
  /// The NEON size field is not `0b11`.
  SizeNot3
  /// A NEON shift: `L:imm6` is at least 8.
  ShiftImm
}

///|
priv struct ArmClass {
  mask : UInt
  value : UInt
  kpos : Array[Int]
  fields : Array[(Char, Array[Int])]
  rules : Array[(Int, Int, Int, Array[Int], ArmFlag, Int)]
  /// Whether bits 28-31 are the condition (predicate operands and
  /// assembly suffix).
  cond : Bool
  valid : ArmValid
  /// The bits of the first register of a register list, whose largest
  /// value an entry may limit.
  limit : Array[Int]
  table : (Int) -> (String, String, String, UInt, Int)?
}

///|
fn arm_bits(w : UInt, positions : Array[Int]) -> Int {
  positions.fold(init=0, (v, b) => {
    (v << 1) | ((w >> b) & 1).reinterpret_as_int()
  })
}

///|
fn ArmClass::field(self : ArmClass, w : UInt, name : Char) -> Int {
  for f in self.fields {
    if f.0 == name {
      return arm_bits(w, f.1)
    }
  }
  0
}

///|
fn ArmClass::matches(self : ArmClass, w : UInt) -> Bool {
  guard (w & self.mask) == self.value else { return false }
  guard !self.cond || w >> 28 != 15 else { return false }
  let not_vfp = () => a32_field(w, 9, 3) != 5
  match self.valid {
    Always => true
    NotVfp => not_vfp()
    NotVfpLdc => not_vfp() && (a32_bit(w, 24) || a32_bit(w, 21))
    SizeNot3 => a32_field(w, 20, 2) != 3
    ShiftImm => a32_bit(w, 7) || a32_field(w, 19, 3) != 0
  }
}

///|
fn ArmClass::key_of(self : ArmClass, w : UInt) -> Int {
  let kb = arm_bits(w, self.kpos)
  for rule in self.rules {
    let (mask, value, keep, positions, flag, tag) = rule
    guard (kb & mask) == value else { continue }
    let bit_of = (p : Int) => (w >> p) & 1
    let flag = match flag {
      NoFlag => 0
      Zero(ps) => if ps.iter().all(p => bit_of(p) == 0) { 1 } else { 0 }
      Eq(ps, qs) =>
        if ps.iter().zip(qs.iter()).all(pq => bit_of(pq.0) == bit_of(pq.1)) {
          1
        } else {
          0
        }
      Vals(ps, values) =>
        match values.search(arm_bits(w, ps)) {
          Some(i) => i + 1
          None => 0
        }
    }
    return (kb & keep) |
      (arm_bits(w, positions) << 12) |
      (flag << 26) |
      (tag << 28)
  }
  kb
}

///|
/// The 8-bit VFP/NEON floating-point immediate as LLVM prints it
/// (`%.6e`): the values are `k / 128` for an integer `k`, whose decimal
/// mantissas have at most six digits.
fn vfp_imm_text(imm8 : Int) -> String {
  let mant = imm8 & 15
  let cd = (imm8 >> 4) & 3
  let e = if ((imm8 >> 6) & 1) == 1 { cd - 3 } else { cd + 1 }
  // v = k / 128
  let k = (16 + mant).to_int64() << (e + 3)
  let (exp, scaled) = if k < 128L {
    (-1, k * 10000000L / 128L)
  } else if k < 1280L {
    (0, k * 1000000L / 128L)
  } else {
    (1, k * 100000L / 128L)
  }
  let frac = (scaled % 1000000L).to_string()
  let sign = if ((imm8 >> 7) & 1) == 1 { "-" } else { "" }
  let exp_text = if exp < 0 { "-0\{-exp}" } else { "+0\{exp}" }
  "\{sign}\{scaled / 1000000L}." +
  "0".repeat(6 - frac.length()) +
  frac +
  "e" +
  exp_text
}

///|
/// The NEON modified immediate `a:bcd:efgh`.
fn neon_imm8(w : UInt) -> Int {
  (a32_field(w, 24, 1) << 7) | (a32_field(w, 16, 3) << 4) | a32_field(w, 0, 4)
}

///|
fn hex_text(v : UInt64) -> String {
  "0x" + v.to_string(radix=16)
}

///|
/// The numeric slots of the VFP/NEON register numbers and immediates.
fn arm_number_slot(w : UInt, name : String) -> Int? {
  let f = (lo : Int, len : Int) => a32_field(w, lo, len)
  let dd = (f(22, 1) << 4) | f(12, 4)
  let dn = (f(7, 1) << 4) | f(16, 4)
  let dm = (f(5, 1) << 4) | f(0, 4)
  let imm6 = f(16, 6)
  let esize = if f(7, 1) == 1 {
    64
  } else if imm6 >= 32 {
    32
  } else if imm6 >= 16 {
    16
  } else {
    8
  }
  let i8 = f(0, 8)
  let u = f(23, 1)
  match name {
    "sd" => Some((f(12, 4) << 1) | f(22, 1))
    "sn" => Some((f(16, 4) << 1) | f(7, 1))
    "sm" => Some((f(0, 4) << 1) | f(5, 1))
    "sm1" => Some(((f(0, 4) << 1) | f(5, 1)) + 1)
    "dd" => Some(dd)
    "dn" => Some(dn)
    "dm" => Some(dm)
    "qd" => Some(dd >> 1)
    "qn" => Some(dn >> 1)
    "qm" => Some(dm >> 1)
    "dd1" | "dd2" | "dd3" | "dd4" | "dd6" | "dn1" =>
      Some(
        (
          (if name[1] == 'd' { dd } else { dn }) +
          (name[2].to_int() - '0'.to_int())
        ) %
        32,
      )
    "ddn1" | "ddn2" | "ddn3" | "dnn1" | "dnn2" | "dnn3" =>
      Some(
        (if name[1] == 'd' { dd } else { dn }) +
        (name[3].to_int() - '0'.to_int()),
      )
    "vi8" => Some((f(16, 4) << 4) | f(0, 4))
    "fx" => Some((f(0, 4) << 1) | f(5, 1))
    "fb16" => Some(16 - ((f(0, 4) << 1) | f(5, 1)))
    "fb32" => Some(32 - ((f(0, 4) << 1) | f(5, 1)))
    "i5" => Some(f(7, 5))
    "shimm" => Some((f(6, 1) << 5) | f(7, 5))
    "bk" => Some((f(8, 12) << 4) | f(0, 4))
    "msb" => Some(f(16, 5))
    "wid" => Some(f(16, 5) - f(7, 5) + 1)
    "sat1" => Some(f(16, 5) + 1)
    "o4" => Some(if u == 1 { i8 * 4 } else { -i8 * 4 })
    "am5" => Some(i8 | ((1 - u) << 8))
    "am5u" => Some(i8 | (u << 8))
    "ms16" => Some(f(0, 3))
    "xs16" => Some((f(5, 1) << 1) | f(3, 1))
    "nsr" => Some(if esize == 64 { 64 - imm6 } else { 2 * esize - imm6 })
    "nsl" => Some(if esize == 64 { imm6 } else { imm6 - esize })
    "nme" => Some((f(5, 1) << 12) | (f(8, 4) << 8) | neon_imm8(w))
    _ => None
  }
}

///|
/// The value of the template slot `name` of `w` (see the file header).
fn ArmClass::slot(self : ArmClass, w : UInt, name : String) -> String {
  if arm_number_slot(w, name) is Some(v) {
    return v.to_string()
  }
  let ni = neon_imm8(w).to_uint64()
  match name {
    "fpe" =>
      return vfp_imm_text((a32_field(w, 16, 4) << 4) | a32_field(w, 0, 4))
    "nfpe" => return vfp_imm_text(ni.to_int())
    "nix" => return hex_text(ni)
    "nix8" => return hex_text(ni << 8)
    "nix16" => return hex_text(ni << 16)
    "nix24" => return hex_text(ni << 24)
    "nixm8" => return hex_text((ni << 8) | 0xffUL)
    "nixm16" => return hex_text((ni << 16) | 0xffffUL)
    "ni64" => {
      let mut v = 0UL
      for i in 0..<8 {
        if ((ni >> i) & 1UL) == 1UL {
          v = v | (0xffUL << (8 * i))
        }
      }
      return hex_text(v)
    }
    "P:c" => return if w >> 28 == 14 { "" } else { "CPSR" }
    _ => ()
  }
  if name.contains(":") {
    let parts = name.split(":").collect()
    let arg = parts[1].to_owned()
    return match (parts[0], arg) {
      ("G" | "g" | "GA" | "ga", _) => {
        let n = self.field(w, arg[0].unsafe_to_char())
        match parts[0] {
          "G" => gpr(n).name()
          "g" => gpr_asm(n)
          "GA" => if n == 15 { "APSR_NZCV" } else { gpr(n).name() }
          _ => if n == 15 { "apsr_nzcv" } else { gpr_asm(n) }
        }
      }
      (kind, _) => {
        let d = arm_number_slot(w, arg).unwrap()
        match kind {
          "Q" => "Q\{d}"
          "DP" => if d % 2 == 0 { "Q\{d / 2}" } else { "D\{d}_D\{d + 1}" }
          "DPS" => "D\{d}_D\{d + 2}"
          "DT" => "D\{d}_D\{d + 1}_D\{d + 2}"
          "DTS" => "D\{d}_D\{d + 2}_D\{d + 4}"
          "DQ" =>
            if d % 2 == 0 {
              "Q\{d / 2}_Q\{d / 2 + 1}"
            } else {
              "D\{d}_D\{d + 1}_D\{d + 2}_D\{d + 3}"
            }
          "DQS" => "D\{d}_D\{d + 2}_D\{d + 4}_D\{d + 6}"
          _ => abort("unknown ARM template slot " + name)
        }
      }
    }
  }
  match name.to_array() {
    [c] => self.field(w, c).to_string()
    _ => abort("unknown ARM template slot " + name)
  }
}

///|
fn ArmClass::expand(self : ArmClass, w : UInt, t : String) -> String {
  let out = StringBuilder()
  for i, part in t.split("%").collect() {
    if i % 2 == 0 {
      out.write_view(part)
    } else {
      out.write_string(self.slot(w, part.to_owned()))
    }
  }
  out.to_string()
}

///|
fn arm_parse_int(s : String) -> Int64 {
  let mut v = 0L
  let mut neg = false
  for c in s {
    if c == '-' {
      neg = true
    } else {
      v = v * 10L + (c.to_int() - '0'.to_int()).to_int64()
    }
  }
  if neg {
    -v
  } else {
    v
  }
}

///|
/// The code of a register named as LLVM names it: the core registers as
/// in `mc_ops.mbt`, `S0`..`S31` from 64, `D0`..`D31` from 96, `Q0`..`Q15`
/// from 128 and register lists (`D0_D1`, `Q0_Q1`, ...) from 160.
fn arm_reg_op(name : String) -> @mc.Op {
  if name.is_empty() {
    return mc_nil()
  }
  for r in Reg::all() {
    if r.name() == name {
      return r.to_mc()
    }
  }
  let parts = name.split("_").collect()
  let first = parts[0]
  let n = arm_parse_int(first[1:].to_owned()).to_int()
  let base = match first[0] {
    'S' => 64
    'D' => 96
    'Q' => 128
    _ => 0
  }
  let code = if parts.length() == 1 {
    base + n
  } else {
    160 + (parts.length() - 2) * 64 + (if first[0] == 'Q' { 32 } else { 0 }) + n
  }
  Reg(name~, code~)
}

///|
fn ArmClass::operands(self : ArmClass, w : UInt, t : String) -> Array[@mc.Op] {
  if t.is_empty() {
    return []
  }
  t
  .split(" ")
  .map(tok => {
    let text = self.expand(w, tok[4:].to_owned())
    if tok.has_prefix("Reg:") {
      arm_reg_op(text)
    } else {
      @mc.Op::Imm(arm_parse_int(text))
    }
  })
  .collect()
}

///|
/// LLVM prints the registers past `d31` of a register list given by its
/// first register with the names of the registers that follow `D31` in its
/// register enumeration.
fn fix_list_names(insn_text : String) -> String {
  guard insn_text.contains("{") else { return insn_text }
  insn_text
  .replace_all(old="d32", new="fpinst2")
  .replace_all(old="d33", new="mvfr0")
  .replace_all(old="d34", new="mvfr1")
}

///|
/// `insn_text` with the condition suffix after the mnemonic (before its first
/// `.` or space).
fn with_cond_suffix(insn_text : String, cond : Int) -> String {
  let suffix = cond_asm(cond)
  guard suffix != "" else { return insn_text }
  let mut at = insn_text.length()
  for i, c in insn_text {
    if c == '.' || c == ' ' {
      at = i
      break
    }
  }
  insn_text[:at].to_owned() + suffix + insn_text[at:].to_owned()
}

///|
/// `VLDM`/`VSTM` (with the `vpush`/`vpop` aliases) and the `FLDMX`/`FSTMX`
/// forms (a `D` register list with an odd length field). As LLVM does,
/// lists running past the last register are truncated and empty lists
/// have one register.
fn a32_vldm(w : UInt) -> A32Insn? {
  let cond = a32_field(w, 28, 4)
  guard cond != 15 && a32_field(w, 25, 3) == 6 && a32_field(w, 9, 3) == 5 else {
    return None
  }
  let (mode, update) = match (a32_bit(w, 24), a32_bit(w, 23), a32_bit(w, 21)) {
    (false, true, false) => ("ia", false)
    (false, true, true) => ("ia", true)
    (true, false, true) => ("db", true)
    _ => return None
  }
  let load = a32_bit(w, 20)
  let double = a32_bit(w, 8)
  let imm8 = a32_field(w, 0, 8)
  let fx = double && (imm8 & 1) == 1
  let first = if double {
    (a32_field(w, 22, 1) << 4) | a32_field(w, 12, 4)
  } else {
    (a32_field(w, 12, 4) << 1) | a32_field(w, 22, 1)
  }
  guard !fx || first < 16 else { return None }
  let n = if double { imm8 >> 1 } else { imm8 }
  let count = if n < 1 { 1 } else if n > 32 - first { 32 - first } else { n }
  let prefix = if double { "D" } else { "S" }
  let regs = Array::makei(count, i => arm_reg_op("\{prefix}\{first + i}"))
  let reg_text = Array::makei(count, i => "\{prefix.to_lower()}\{first + i}").join(
    ", ",
  )
  let rn = a32_field(w, 16, 4)
  let base = [mc_gpr(rn), ..if update { [mc_gpr(rn)] } else { [] }]
  let op = if load { "LDM" } else { "STM" }
  let upd = if update { "_UPD" } else { "" }
  let name = if fx {
    "F\{op}X\{mode.to_upper()}\{upd}"
  } else {
    "V\{op}\{prefix}\{mode.to_upper()}\{upd}"
  }
  let push_pop = rn == 13 &&
    !fx &&
    update &&
    (if load { mode == "ia" } else { mode == "db" })
  let text = if push_pop {
    (if load { "vpop" } else { "vpush" }) + " {\{reg_text}}"
  } else {
    let mnemonic = (if load { "ldm" } else { "stm" }) + mode
    let mnemonic = if fx { "f\{mnemonic}x" } else { "v\{mnemonic}" }
    "\{mnemonic} \{gpr_asm(rn)}\{if update { "!" } else { "" }}, {\{reg_text}}"
  }
  decoded(name, [..base, ..mc_pred(cond), ..regs], with_cond_suffix(text, cond))
}

///|
/// Decodes `w` with the tables.
fn a32_ext(w : UInt) -> A32Insn? {
  if a32_vldm(w) is Some(insn) {
    return Some(insn)
  }
  for cls in arm_classes {
    guard cls.matches(w) else { continue }
    guard (cls.table)(cls.key_of(w)) is Some((name, ops, text, zero, max_first)) &&
      (w & zero) == 0 &&
      (max_first < 0 || arm_bits(w, cls.limit) <= max_first) else {
      continue
    }
    let insn_text = fix_list_names(cls.expand(w, text))
    let insn_text = if cls.cond {
      with_cond_suffix(insn_text, a32_field(w, 28, 4))
    } else {
      insn_text
    }
    return decoded(name, cls.operands(w, ops), insn_text)
  }
  None
}
