// Advanced SIMD and floating-point instructions: data processing (scalar
// floating point, conversions, the AdvSIMD vector and scalar classes) and
// the SIMD&FP loads and stores (single registers in every addressing mode,
// pairs, literals, and the structure loads and stores `LD1`..`LD4R`/`ST1`..
// `ST4`).
//
// These instructions are regular enough to be decoded by tables. Each
// encoding class of the ARM ARM is described by a `SimdClass`: its fixed
// bits, the bits selecting the instruction (the class key, with a few
// value-dependent refinements: `ORR` with equal sources is `mov`, a zero
// index gives `UMOVvi32_idx0`, a zero offset drops the offset from the
// assembly, `Rm = 31` selects post-index immediates, ...) and its operand
// fields. The per-class tables of `simd_tables.mbt` map a key to the LLVM
// opcode name and to templates of the operand list and of the assembly in
// which `%slot%` stands for a value computed from the word (see
// `SimdClass::slot`): an operand field (`d`, `n`, `m`, ...), a register of
// a list (`t1` is `t + 1` modulo 32), a general-purpose register name
// (`X:n`, `XSP:n`, `w:d`, ...) or a class-specific value (lane indices,
// shift amounts, scaled offsets, expanded immediates, condition names).
//
// The tables were derived from, and are checked against, LLVM 22's
// disassembler with upstream BAP's features (`+v8.1a,+v8.2a,+v8.3a`; no
// half-precision arithmetic, dot product, cryptography or SVE), so names,
// operands, assembly and kinds are those of LLVM.

///|
/// How the table key of a class is computed from the key bits.
priv enum SimdKey {
  Plain
  V3Same
  Copy
  Shift
  Elem
  Ext
  Fix
  ZeroImm
  M31
  Single
}

///|
/// The class-specific slots of a class.
priv enum SimdExtra {
  NoExtra
  ModImm
  CopyIdx
  ShiftAmt
  ElemIdx
  FixBits
  FpImm
  Cond
  LsUi
  LsS9
  LsPair
  LsLit
  SingleIdx
}

///|
priv struct SimdClass {
  mask : UInt32
  value : UInt32
  /// The key bits, most significant first.
  kpos : Array[Int32]
  /// The operand fields and their bits, most significant first.
  fields : Array[(Char, Array[Int32])]
  key : SimdKey
  extra : SimdExtra
  table : (Int32) -> (String, String, String)?
}

///|
fn bits_of(w : UInt32, positions : Array[Int32]) -> Int32 {
  positions.fold(init=0, (v, b) => {
    (v << 1) | ((w >> b) & 1).reinterpret_as_int()
  })
}

///|
fn SimdClass::has_field(self : SimdClass, name : Char) -> Bool {
  self.fields.iter().any(f => f.0 == name)
}

///|
/// The value of the operand field `name` of `w` (0 when the class has no
/// such field).
fn SimdClass::field(self : SimdClass, w : UInt32, name : Char) -> Int32 {
  for f in self.fields {
    if f.0 == name {
      return bits_of(w, f.1)
    }
  }
  0
}

///|
fn SimdClass::matches(self : SimdClass, w : UInt32) -> Bool {
  (w & self.mask) == self.value &&
  (!(self.key is Shift) || self.field(w, 'h') != 0)
}

///|
/// The index of the lowest set bit of `v` among its low 4 bits, 4 if none.
fn low_set_bit4(v : Int32) -> Int32 {
  for s in 0..<4 {
    if ((v >> s) & 1) == 1 {
      return s
    }
  }
  4
}

///|
/// The index of the highest set bit of the nonzero 4-bit `v`.
fn high_set_bit4(v : Int32) -> Int32 {
  for c = 3; c > 0; c = c - 1 {
    if ((v >> c) & 1) == 1 {
      return c
    }
  }
  0
}

///|
fn SimdClass::key_of(self : SimdClass, w : UInt32, kb : Int32) -> Int32 {
  let f = (c : Char) => self.field(w, c)
  match self.key {
    Plain => kb
    V3Same =>
      if (kb & 0xff) == 0x43 && f('n') == f('m') {
        kb | 0x200
      } else {
        kb
      }
    Copy => {
      // `kb` is Q:op:imm4; the element size is the lowest set bit of imm5
      let imm5 = f('i')
      let size = low_set_bit4(imm5)
      let idx = if size < 4 { imm5 >> (size + 1) } else { 0 }
      let mut k = kb
      if ((kb >> 4) & 1) == 1 {
        let idx2 = if size < 4 { (kb & 15) >> size } else { 0 }
        k = (kb & 15).lnot() & kb
        if idx2 == 0 {
          k = k | (1 << 10)
        }
      }
      k = k | (size << 6)
      if idx == 0 {
        k | (1 << 9)
      } else {
        k
      }
    }
    Shift => kb | (high_set_bit4(f('h')) << 7)
    Elem => kb | (f('L') << 8)
    Ext => kb | (f('i') >> 3 << 8)
    Fix => kb | (f('s') >> 5 << 10)
    ZeroImm => if f('i') == 0 { kb | 0x10000 } else { kb }
    M31 => if f('m') == 31 { kb | 0x10000 } else { kb }
    Single => {
      let mut k = kb | (f('z') << 7)
      if (kb & 6) == 6 {
        k = k | (f('Q') << 5) | (f('S') << 6)
      } else if (kb & 6) == 4 && (f('z') & 1) == 1 {
        k = k | (f('S') << 6)
      }
      if self.has_field('m') && f('m') == 31 {
        k | 0x10000
      } else {
        k
      }
    }
  }
}

///|
/// The 8-bit floating-point immediate `imm8` (`VFPExpandImm`) as LLVM
/// prints it (`%.8f`): `(16 + mantissa) / 16 * 2^e` with `e` in -3..4 is
/// exactly `(16 + mantissa) * 781250 * 2^(e + 3)` hundred-millionths.
fn fp8_text(imm8 : Int32) -> String {
  let mant = imm8 & 15
  let cd = (imm8 >> 4) & 3
  let e = if ((imm8 >> 6) & 1) == 1 { cd - 3 } else { cd + 1 }
  let scaled = (16 + mant).to_int64() * 781250L * (1L << (e + 3))
  let frac = (scaled % 100000000L).to_string()
  let sign = if ((imm8 >> 7) & 1) == 1 { "-" } else { "" }
  "\{sign}\{scaled / 100000000L}." + "0".repeat(8 - frac.length()) + frac
}

///|
/// The 64-bit `MOVI` immediate (each bit of `imm8` gives a byte) as LLVM
/// prints it (`%#016llx`).
fn movi64_text(imm8 : Int32) -> String {
  let mut v = 0UL
  for i in 0..<8 {
    if ((imm8 >> i) & 1) == 1 {
      v = v | (0xffUL << (8 * i))
    }
  }
  if v == 0UL {
    return "0000000000000000"
  }
  let hex = v.to_string(radix=16)
  let pad = 14 - hex.length()
  "0x" + (if pad > 0 { "0".repeat(pad) } else { "" }) + hex
}

///|
/// The class-specific slot `name` of `w`, if any.
fn SimdClass::extra_slot(
  self : SimdClass,
  w : UInt32,
  kb : Int32,
  name : String,
) -> Int32? {
  let f = (c : Char) => self.field(w, c)
  match (self.extra, name) {
    (CopyIdx, "x" | "y") => {
      let imm5 = f('i')
      let size = low_set_bit4(imm5)
      if size == 4 {
        Some(0)
      } else if name == "x" {
        Some(imm5 >> (size + 1))
      } else {
        Some((kb & 15) >> size)
      }
    }
    (ShiftAmt, "r" | "l") => {
      let h = f('h')
      let hb = (h << 3) | f('b')
      let esize = 8 << high_set_bit4(h)
      Some(if name == "r" { 2 * esize - hb } else { hb - esize })
    }
    (ElemIdx, "m5") => Some((f('M') << 4) | f('m'))
    (ElemIdx, "m4") => Some(f('m'))
    (ElemIdx, "xh") => Some((f('H') << 2) | (f('L') << 1) | f('M'))
    (ElemIdx, "xs") => Some((f('H') << 1) | f('L'))
    (ElemIdx, "xd") => Some(f('H'))
    (FixBits, "fb") => Some(64 - f('s'))
    (LsUi, "i1") => Some(f('i') << 1)
    (LsUi, "i2") => Some(f('i') << 2)
    (LsUi, "i3") => Some(f('i') << 3)
    (LsUi, "i4") => Some(f('i') << 4)
    (LsS9, "s") => Some(sext(f('i'), 9))
    (LsPair, "s") => Some(sext(f('i'), 7))
    (LsPair, "s2") => Some(sext(f('i'), 7) * 4)
    (LsPair, "s3") => Some(sext(f('i'), 7) * 8)
    (LsPair, "s4") => Some(sext(f('i'), 7) * 16)
    (LsLit, "s") => Some(sext(f('i'), 19))
    (LsLit, "s2") => Some(sext(f('i'), 19) * 4)
    (SingleIdx, "xb") => Some((f('Q') << 3) | (f('S') << 2) | f('z'))
    (SingleIdx, "xh") => Some((f('Q') << 2) | (f('S') << 1) | (f('z') >> 1))
    (SingleIdx, "xs") => Some((f('Q') << 1) | f('S'))
    (SingleIdx, "xd") => Some(f('Q'))
    _ => None
  }
}

///|
/// The value of the template slot `name` of `w` (see the file header).
fn SimdClass::slot(
  self : SimdClass,
  w : UInt32,
  kb : Int32,
  name : String,
) -> String {
  if self.extra_slot(w, kb, name) is Some(v) {
    return v.to_string()
  }
  match (self.extra, name) {
    (ModImm | FpImm, "fp") => return fp8_text(self.field(w, 'i'))
    (ModImm, "i64") => return movi64_text(self.field(w, 'i'))
    (Cond, "cc") => return cond_asm(self.field(w, 'c'))
    _ => ()
  }
  if name.contains(":") {
    let parts = name.split(":").collect()
    let n = self.field(w, parts[1][0].unsafe_to_char())
    return match parts[0] {
      "X" => reg_name(true, n)
      "XSP" => reg_name(true, n, sp=true)
      "W" => reg_name(false, n)
      "WSP" => reg_name(false, n, sp=true)
      "x" => reg_asm(true, n)
      "xsp" => reg_asm(true, n, sp=true)
      "w" => reg_asm(false, n)
      "wsp" => reg_asm(false, n, sp=true)
      _ => abort("unknown SIMD template slot " + name)
    }
  }
  match name.to_array() {
    [c, '1'..<='3' as k] =>
      ((self.field(w, c) + (k.to_int() - '0'.to_int())) % 32).to_string()
    [c] => self.field(w, c).to_string()
    _ => abort("unknown SIMD template slot " + name)
  }
}

///|
/// The template `t` with its `%slot%` placeholders replaced.
fn SimdClass::expand(
  self : SimdClass,
  w : UInt32,
  kb : Int32,
  t : String,
) -> String {
  let out = StringBuilder()
  for i, part in t.split("%").collect() {
    if i % 2 == 0 {
      out.write_view(part)
    } else {
      out.write_string(self.slot(w, kb, part.to_owned()))
    }
  }
  out.to_string()
}

///|
/// The port-local code of a register named as LLVM names it: the
/// general-purpose registers as in `registers.mbt`, `B<n>`..`Q<n>` from
/// 200 (32 per class) and the `D`/`Q` lists (`Q0_Q1`, ...) from 400.
fn simd_reg_code(name : String) -> Int32 {
  match name {
    "WSP" => 32
    "WZR" => 33
    "FP" => 63
    "LR" => 64
    "SP" => 65
    "XZR" => 66
    _ => {
      let parts = name.split("_").collect()
      let first = parts[0]
      let n = parse_dec(first[1:].to_owned()).to_int()
      let cls = match first[0] {
        'W' => return n + 1
        'X' => return n + 34
        'B' => 0
        'H' => 1
        'S' => 2
        'D' => 3
        _ => 4
      }
      if parts.length() == 1 {
        200 + 32 * cls + n
      } else {
        400 + 32 * ((cls - 3) * 3 + parts.length() - 2) + n
      }
    }
  }
}

///|
/// The value of a decimal number with an optional `-` sign.
fn parse_dec(s : String) -> Int64 {
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
/// The operand list of the template `t`.
fn SimdClass::operands(
  self : SimdClass,
  w : UInt32,
  kb : Int32,
  t : String,
) -> Array[@mc.Op] {
  if t.is_empty() {
    return []
  }
  t
  .split(" ")
  .map(tok => {
    let text = self.expand(w, kb, tok[4:].to_owned())
    if tok.has_prefix("Reg:") {
      @mc.Op::Reg(name=text, code=simd_reg_code(text))
    } else {
      @mc.Op::Imm(parse_dec(text))
    }
  })
  .collect()
}

///|
/// Decodes an Advanced SIMD or floating-point instruction (data processing,
/// loads and stores).
fn a64_simd(w : UInt32) -> A64Insn? {
  for cls in simd_classes {
    guard cls.matches(w) else { continue }
    let kb = bits_of(w, cls.kpos)
    guard (cls.table)(cls.key_of(w, kb)) is Some((name, ops, text)) else {
      continue
    }
    return a64(name, cls.operands(w, kb, ops), cls.expand(w, kb, text))
  }
  None
}
