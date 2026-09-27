// Table-driven decoding of the instructions the lifter does not model
// (classic floating point, AltiVec, VSX, `isel`, traps, barriers,
// `mftb`, `mfocrf`/`mtocrf`, cache and TLB management, decimal floating
// point, ...), as the LLVM PowerPC disassembler decodes them. It is used
// for the words `decode_spec` does not decode, so that recursive
// disassembly does not stop at them: the instructions lift as
// `Unsupported` (the `powerpc` lifter has no semantics for them).
//
// Each class is an instruction format of a primary opcode (for example
// the X-form instructions of opcode 31). Its key bits (the extended
// opcode, with refinements given by `rules`: A-form and VA-form
// instructions whose last register is in the extended-opcode position,
// value-dependent mnemonics such as `trap`, `lwsync` or `xxmrghd`) select
// an entry of `decode_ext_tables.mbt`: the LLVM opcode name, templates of
// the operand list and of the assembly, and the bits that must be zero.
// A `%slot%` of a template is a value computed from the word (see
// `PpcClass::slot`): an operand field (`t`, `a`, `b` are the fields at
// bits 6, 11 and 16), a register named from a field (`R:t`, `F:b`, `V:a`,
// `G0:a` is `ZERO` for 0, `VS:tx` is the VSX register `TX:T`, ...) or a
// format-specific value (displacements, split fields such as `spr`,
// condition register fields). The tables were learned from, and are
// checked against, LLVM 22's disassembler.

///|
/// The flag of a key rule.
priv enum PpcFlag {
  NoFlag
  /// The given bits are all zero.
  Zero(Array[Int])
  /// The bits at the first positions equal those at the second ones.
  Eq(Array[Int], Array[Int])
  /// The 1-based index of the value of the given bits among the values, 0
  /// for other values.
  Vals(Array[Int], Array[Int])
}

///|
priv struct PpcClass {
  mask : UInt
  value : UInt
  /// The key bits (bit 0 is the least significant bit of the word), most
  /// significant first.
  kpos : Array[Int]
  /// The operand fields and their bits, most significant first.
  fields : Array[(Char, Array[Int])]
  /// Key refinements `(mask, value, keep, bits, flag, tag)`: the first
  /// rule whose `mask` selects `value` in the key bits makes the key the
  /// kept key bits, the given bits (from bit 12), the flag (from bit 26) and the
  /// tag (from bit 28).
  rules : Array[(Int, Int, Int, Array[Int], PpcFlag, Int)]
  table : (Int) -> (String, String, String, UInt)?
}

///|
fn word_bits(w : UInt, positions : Array[Int]) -> Int {
  positions.fold(init=0, (v, b) => {
    (v << 1) | ((w >> b) & 1).reinterpret_as_int()
  })
}

///|
/// Bits `from..to` of the word, numbered from the most significant bit as
/// in the Power ISA.
fn isa_bits(w : UInt, from : Int, to : Int) -> Int {
  field(w, from, to)
}

///|
fn PpcClass::field(self : PpcClass, w : UInt, name : Char) -> Int {
  for f in self.fields {
    if f.0 == name {
      return word_bits(w, f.1)
    }
  }
  0
}

///|
fn PpcClass::key_of(self : PpcClass, w : UInt) -> Int {
  let kb = word_bits(w, self.kpos)
  for rule in self.rules {
    let (mask, value, keep, positions, flag, tag) = rule
    guard (kb & mask) == value else { continue }
    let flag = match flag {
      NoFlag => 0
      Zero(ps) => if ps.iter().all(p => ((w >> p) & 1) == 0) { 1 } else { 0 }
      Eq(ps, qs) =>
        if ps
          .iter()
          .zip(qs.iter())
          .all(pq => ((w >> pq.0) & 1) == ((w >> pq.1) & 1)) {
          1
        } else {
          0
        }
      Vals(ps, values) =>
        match values.search(word_bits(w, ps)) {
          Some(i) => i + 1
          None => 0
        }
    }
    return (kb & keep) |
      (word_bits(w, positions) << 12) |
      (flag << 26) |
      (tag << 28)
  }
  kb
}

///|
/// A VSX register (`vsrc`): `VSL0`..`VSL31`, then `V0`..`V31`.
fn vsx_name(n : Int) -> String {
  if n < 32 {
    "VSL\{n}"
  } else {
    "V\{n - 32}"
  }
}

///|
/// A scalar VSX register (`vsfrc`): `F0`..`F31`, then `VF0`..`VF31`.
fn vsf_name(n : Int) -> String {
  if n < 32 {
    "F\{n}"
  } else {
    "VF\{n - 32}"
  }
}

///|
/// The numeric slots of a word that are not operand fields.
fn ppc_number_slot(w : UInt, name : String) -> Int? {
  let b = (from : Int, to : Int) => isa_bits(w, from, to)
  match name {
    "c" => Some(b(21, 25))
    "d" => Some(b(16, 31))
    "sd" => Some(sext(b(16, 31), 16).to_int())
    "ds" => Some(sext(b(16, 29) << 2, 16).to_int())
    "dq" => Some(sext(b(16, 27) << 4, 16).to_int())
    "dx" => Some((b(16, 25) << 6) | (b(11, 15) << 1) | b(31, 31))
    "hd" => Some(((b(31, 31) << 5) | b(6, 10)) * 8 - 512)
    "bf" => Some(b(6, 8))
    "bfa" => Some(b(11, 13))
    "fxm" => Some(b(12, 19))
    "l6" => Some(b(6, 6))
    "w15" => Some(b(15, 15))
    "lev" => Some(b(20, 26))
    "shb" => Some(b(22, 25))
    "dm" => Some(b(22, 23))
    "ui2" => Some(b(14, 15))
    "ui3" => Some(b(13, 15))
    "spr" => Some((b(16, 20) << 5) | b(11, 15))
    "ab" => Some((b(11, 15) << 5) | b(16, 20))
    "flm" => Some(b(7, 14))
    "u" => Some(b(16, 19))
    "l10" => Some(b(9, 10))
    "ui4" => Some(b(12, 15))
    "tx" => Some(b(6, 10) + 32 * b(31, 31))
    "ax" => Some(b(11, 15) + 32 * b(29, 29))
    "bx" => Some(b(16, 20) + 32 * b(30, 30))
    "cx" => Some(b(21, 25) + 32 * b(28, 28))
    "tq" => Some(b(6, 10) + 32 * b(28, 28))
    "tp" => Some(b(10, 10) * 16 + b(6, 9))
    "tp2" => Some(2 * (b(10, 10) * 16 + b(6, 9)))
    "sh6" => Some(b(16, 21))
    "b16" => Some(b(16, 16))
    "six" => Some(b(17, 20))
    "dcmx" => Some(b(9, 15))
    "dcmxv" => Some((b(25, 25) << 6) | (b(29, 29) << 5) | b(11, 15))
    "crm" | "fxl" => {
      // the lowest set bit of FXM selects the condition register field
      let fxm = b(12, 19)
      guard fxm != 0 else { return None }
      let low = fxm.ctz()
      Some(if name == "crm" { 7 - low } else { 1 << low })
    }
    _ => None
  }
}

///|
/// The value of the template slot `name` of `w` (see the file header).
fn PpcClass::slot(self : PpcClass, w : UInt, name : String) -> String {
  if ppc_number_slot(w, name) is Some(v) {
    return v.to_string()
  }
  if name.contains(":") {
    let parts = name.split(":").collect()
    let arg = parts[1].to_owned()
    // the 6-bit VSX register numbers (`tx`, `bx`, ...) versus the 5-bit
    // operand fields
    let (n, vsx) = match ppc_number_slot(w, arg) {
      Some(v) => (v, arg != "c")
      None => (self.field(w, arg[0].unsafe_to_char()), false)
    }
    return match parts[0] {
      "VF" if vsx => vsf_name(n)
      "R" => "R\{n}"
      "X" => "X\{n}"
      "G0" => if n == 0 { "ZERO" } else { "R\{n}" }
      "X0" => if n == 0 { "ZERO8" } else { "X\{n}" }
      "F" => "F\{n}"
      "V" => "V\{n}"
      "VF" => "VF\{n}"
      "VSL" => "VSL\{n}"
      "VS" => vsx_name(n)
      "CRB" => "CR\{n / 4}\{crbit_names[n % 4]}"
      _ => abort("unknown PowerPC template slot " + name)
    }
  }
  match name.to_array() {
    [c] => self.field(w, c).to_string()
    ['s', c] => {
      // a signed 5-bit field
      let v = self.field(w, c)
      (if v >= 16 { v - 32 } else { v }).to_string()
    }
    _ => abort("unknown PowerPC template slot " + name)
  }
}

///|
fn PpcClass::expand(self : PpcClass, w : UInt, t : String) -> String {
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
fn ppc_parse_int(s : String) -> Int64 {
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
fn PpcClass::operands(self : PpcClass, w : UInt, t : String) -> Array[@mc.Op] {
  if t.is_empty() {
    return []
  }
  t
  .split(" ")
  .map(tok => {
    let text = self.expand(w, tok[4:].to_owned())
    if tok.has_prefix("Reg:") {
      @mc.Op::reg(text)
    } else {
      @mc.Op::Imm(ppc_parse_int(text))
    }
  })
  .collect()
}

///|
/// Decodes `w` with the tables: the LLVM name, operands, assembly and
/// kinds.
fn decode_ext(w : UInt) -> (String, Array[@mc.Op], String, Array[@mc.Kind])? {
  for cls in ppc_classes {
    guard (w & cls.mask) == cls.value else { continue }
    guard (cls.table)(cls.key_of(w)) is Some((name, ops, text, zero)) &&
      (w & zero) == 0 else {
      continue
    }
    return Some(
      (name, cls.operands(w, ops), cls.expand(w, text), ppc_ext_kinds(name)),
    )
  }
  None
}
