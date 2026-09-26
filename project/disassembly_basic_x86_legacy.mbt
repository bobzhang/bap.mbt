// The Basic BIL lifter (`lift_basic_bil`) and the x86 SIMD semantics
// (`apply_x86_simd`) were written against the fixture decoder that preceded
// the LLVM-compatible x86 decoder, and key on its opcode names and operand
// layouts (e.g. `ADD32rr` with two operands, `JE_1` with an absolute
// target, `REP_MOVS32_64`, `PUSH16R_64`, `SETE`, `CMOVA32rr`). The decoder
// now produces LLVM's MCInst form (`ADD32rr` with the tied source,
// `JCC_1` with a relative displacement and a condition code, ...). This
// file converts the LLVM form of an x86 instruction into the form these
// consumers expect, so that they keep working unchanged; instructions of
// other encodings are returned as they are.

///|
fn x86_legacy_register(name : String) -> ProjectInstructionOperand {
  ProjectInstructionOperand::register(
    name~,
    code=x86_llvm_tables().registers.get(name).unwrap_or(0),
  )
}

///|
/// The accumulator of width `width`.
fn x86_legacy_accumulator(width : Int) -> ProjectInstructionOperand {
  x86_legacy_register(
    match width {
      8 => "AL"
      16 => "AX"
      64 => "RAX"
      _ => "EAX"
    },
  )
}

///|
/// The width encoded in an LLVM opcode name after `prefix` (`ADD32rr`).
fn x86_legacy_width(name : String, prefix : String) -> Int {
  if !name.has_prefix(prefix) {
    return 0
  }
  let rest = name.view(start_offset=prefix.length())
  if rest.has_prefix("16") {
    16
  } else if rest.has_prefix("32") {
    32
  } else if rest.has_prefix("64") {
    64
  } else if rest.has_prefix("8") {
    8
  } else {
    0
  }
}

///|
/// The last repeat prefix (0xF2 or 0xF3) before the opcode, or 0.
fn x86_legacy_repeat_prefix(bytes : Bytes, mode64 : Bool) -> Int {
  let mut rep = 0
  for byte in bytes {
    let b = byte.to_int()
    match b {
      0xF2 | 0xF3 => rep = b
      0x26 | 0x2E | 0x36 | 0x3E | 0x64 | 0x65 | 0x66 | 0x67 | 0xF0 => ()
      _ => if !(mode64 && b >= 0x40 && b <= 0x4F) { break }
    }
  }
  rep
}

///|
/// Whether an operand-size prefix precedes the opcode.
fn x86_legacy_has_opsize(bytes : Bytes, mode64 : Bool) -> Bool {
  for byte in bytes {
    let b = byte.to_int()
    match b {
      0x66 => return true
      0x26 | 0x2E | 0x36 | 0x3E | 0x64 | 0x65 | 0x67 | 0xF0 | 0xF2 | 0xF3 => ()
      _ => if !(mode64 && b >= 0x40 && b <= 0x4F) { break }
    }
  }
  false
}

///|
let x86_legacy_condition_names : Array[String] = [
  "O", "NO", "B", "AE", "E", "NE", "BE", "A", "S", "NS", "P", "NP", "L", "GE", "LE",
  "G",
]

///|
let x86_legacy_simd_rr : Array[String] = [
  "PCMPEQB", "PCMPGTB", "PADDQ", "PMINUB", "PAND", "PMINSB", "PMAXUB", "PANDN", "PAVGB",
  "PAVGW", "PMAXSB", "PMAXUW", "PMAXSW", "PMINUW", "PMINSW", "POR", "PMINUD", "PMINSD",
  "PMAXUD", "PMAXSD", "PXOR", "PSUBB", "PSUBW", "PSUBD", "PSUBQ", "PADDB", "PADDW",
  "PADDD", "PSHUFB", "PSRLW", "PSRLD", "PSRLQ", "PSRAW", "PSRAD", "PSLLW", "PSLLD",
  "PSLLQ",
]

///|
/// The legacy form of an LLVM x86 instruction: its name and operands, or
/// `None` when the instruction keeps its LLVM form.
fn ProjectDisassemblyInstruction::x86_legacy_form(
  self : ProjectDisassemblyInstruction,
  mode64 : Bool,
) -> (String, Array[ProjectInstructionOperand])? {
  let name = self.name()
  let ops = self.operands()
  let n = ops.length()
  let pick = (indices : Array[Int]) => {
    let out = []
    for i in indices {
      match ops.get(i) {
        Some(op) => out.push(op)
        None => ()
      }
    }
    out
  }
  let range = (from : Int, count : Int) => Array::makei(count, k => from + k)
  let mode_suffix = if mode64 { "_64" } else { "" }
  // absolute target of a relative branch
  let absolute = () => {
    match ops.get(0) {
      Some(ProjectImmediateOperand(rel)) =>
        project_disassembly_basic_add_signed_offset(
          self.addr() + self.memory().length().to_uint64(),
          rel,
        ).map(target => {
          [ProjectInstructionOperand::immediate(target.reinterpret_as_int64())]
        })
      _ => None
    }
  }
  let condition = (index : Int) => {
    match ops.get(index) {
      Some(ProjectImmediateOperand(cc)) if cc >= 0L && cc < 16L =>
        Some(x86_legacy_condition_names[cc.to_int()])
      _ => None
    }
  }
  // arithmetic and logic
  for op in ["ADD", "SUB", "ADC", "SBB", "AND", "OR", "XOR"] {
    let width = x86_legacy_width(name, op)
    if width == 0 {
      continue
    }
    let w = width.to_string()
    let rest = name.view(start_offset=op.length() + w.length()).to_owned()
    return match rest {
      "rr" | "rr_REV" if n == 3 => Some((name, pick([0, 2])))
      "rm" if n == 7 => Some((name, pick([0] + range(2, 5))))
      "ri" => Some((op + w + (if width == 8 { "ri8" } else { "ri" + w }), ops))
      "mi" => Some((op + w + (if width == 8 { "mi8" } else { "mi" + w }), ops))
      "i8" | "i16" | "i32" if n == 1 => {
        let acc = x86_legacy_accumulator(width)
        Some(
          (
            op +
            w +
            (if width == 8 {
              "ri8"
            } else if width == 64 {
              "ri32"
            } else {
              "ri" + w
            }),
            [acc, acc, ops[0]],
          ),
        )
      }
      _ => None
    }
  }
  for op in ["CMP", "TEST"] {
    let width = x86_legacy_width(name, op)
    if width == 0 {
      continue
    }
    let w = width.to_string()
    let rest = name.view(start_offset=op.length() + w.length()).to_owned()
    let imm_suffix = if width == 8 {
      "ri8"
    } else if width == 64 {
      "ri32"
    } else {
      "ri" + w
    }
    return match rest {
      "ri" => Some((op + w + imm_suffix, ops))
      "mi" if op == "CMP" =>
        Some((op + w + (if width == 8 { "mi8" } else { "mi" + w }), ops))
      "i8" | "i16" | "i32" if n == 1 =>
        Some((op + w + imm_suffix, [x86_legacy_accumulator(width), ops[0]]))
      _ => None
    }
  }
  // two-address forms whose tied source the lifter does not expect
  let tied_rr = [
    "IMUL16rr", "IMUL32rr", "IMUL64rr", "BSF16rr", "BSF32rr", "BSF64rr", "BSR16rr",
    "BSR32rr", "BSR64rr", "BTC16rr", "BTC32rr", "BTC64rr", "BTR16rr", "BTR32rr",
    "BTR64rr", "BTS16rr", "BTS32rr", "BTS64rr", "BTC16ri8", "BTC32ri8", "BTC64ri8",
    "BTR16ri8", "BTR32ri8", "BTR64ri8", "BTS16ri8", "BTS32ri8", "BTS64ri8",
  ]
  if tied_rr.contains(name) && n == 3 {
    return Some((name, pick([0, 2])))
  }
  let tied_rm = [
    "IMUL16rm", "IMUL32rm", "IMUL64rm", "BSF16rm", "BSF32rm", "BSF64rm", "BSR16rm",
    "BSR32rm", "BSR64rm",
  ]
  if tied_rm.contains(name) && n == 7 {
    return Some((name, pick([0] + range(2, 5))))
  }
  match name {
    "IMUL16rri" => return Some(("IMUL16rri16", ops))
    "IMUL32rri" => return Some(("IMUL32rri32", ops))
    "IMUL16rmi" => return Some(("IMUL16rmi16", ops))
    "IMUL32rmi" => return Some(("IMUL32rmi32", ops))
    _ => ()
  }
  // shifts and rotates
  for op in ["SHL", "SHR", "SAR", "ROL", "ROR", "RCL", "RCR"] {
    let width = x86_legacy_width(name, op)
    if width == 0 {
      continue
    }
    let w = width.to_string()
    let rest = name.view(start_offset=op.length() + w.length()).to_owned()
    let one = ProjectInstructionOperand::immediate(1L)
    let cl = x86_legacy_register("CL")
    return match rest {
      "ri" => Some((op + w + "ri8", ops))
      "r1" if n == 2 => Some((op + w + "r1", [ops[0], ops[1], one]))
      "rCL" if n == 2 => Some((op + w + "rCL", [ops[0], ops[1], cl]))
      "mi" => Some((op + w + "mi8", ops))
      "m1" if n == 5 => Some((op + w + "m1", ops + [one]))
      "mCL" if n == 5 => Some((op + w + "mCL", ops + [cl]))
      _ => None
    }
  }
  for op in ["SHLD", "SHRD"] {
    let width = x86_legacy_width(name, op)
    if width == 0 {
      continue
    }
    if name.has_suffix("CL") {
      return Some((name, ops + [x86_legacy_register("CL")]))
    }
    return None
  }
  // one-operand read-modify-write forms
  for op in ["INC", "DEC", "NOT", "NEG"] {
    let width = x86_legacy_width(name, op)
    if width == 0 {
      continue
    }
    let w = width.to_string()
    let rest = name.view(start_offset=op.length() + w.length()).to_owned()
    return match rest {
      "r" | "r_alt" if n == 2 => Some((op + w + "r", [ops[0]]))
      _ => None
    }
  }
  if name.has_prefix("BSWAP") && n == 2 {
    return Some((name, [ops[0]]))
  }
  // exchanges
  if name.has_prefix("CMPXCHG") {
    let width = x86_legacy_width(name, "CMPXCHG")
    let w = width.to_string()
    if width > 0 && name.has_suffix("rr") && n == 2 {
      return Some((name, [ops[0], ops[0], ops[1]]))
    }
    if width > 0 && name.has_suffix("rm") {
      return Some(("CMPXCHG" + w + "mr", ops))
    }
    if name == "CMPXCHG8B" {
      return Some(("CMPXCHG8Bm", ops))
    }
    return None
  }
  if name.has_prefix("XADD") {
    let w = x86_legacy_width(name, "XADD").to_string()
    if name.has_suffix("rr") && n == 4 {
      return Some((name, [ops[0], ops[0], ops[1]]))
    }
    if name.has_suffix("rm") && n == 7 {
      return Some(("XADD" + w + "mr", pick(range(2, 5) + [0])))
    }
    return None
  }
  if name.has_prefix("XCHG") {
    let width = x86_legacy_width(name, "XCHG")
    let w = width.to_string()
    if name.has_suffix("rr") && n == 4 {
      return Some((name, pick([0, 1])))
    }
    if name.has_suffix("ar") && n == 2 {
      return Some(("XCHG" + w + "rr", [x86_legacy_accumulator(width), ops[0]]))
    }
    if name.has_suffix("rm") && n == 7 {
      return Some((name, pick([0] + range(2, 5))))
    }
    return None
  }
  // moves
  match name {
    "MOV8ri_alt" | "MOV16ri_alt" | "MOV32ri_alt" =>
      return Some((name.view(end_offset=name.length() - 4).to_owned(), ops))
    "MOV64mi32" => return Some(("MOV64mi", ops))
    "LEA64_32r" => return Some(("LEA32r", ops))
    _ => ()
  }
  if name.has_prefix("MOV") &&
    (name.has_suffix("ao32") || name.has_suffix("ao64")) {
    let width = x86_legacy_width(name, "MOV")
    return Some(("MOV\{width}ra", [x86_legacy_accumulator(width), ops[0]]))
  }
  if name.has_prefix("MOV") &&
    (name.has_suffix("o32a") || name.has_suffix("o64a")) {
    let width = x86_legacy_width(name, "MOV")
    return Some(("MOV\{width}ar", [ops[0], x86_legacy_accumulator(width)]))
  }
  // conditional moves and sets
  if name.has_prefix("CMOV") && name != "CMOV" {
    let width = x86_legacy_width(name, "CMOV")
    if name.has_suffix("rr") && n == 4 {
      return condition(3).map(cc => ("CMOV\{cc}\{width}rr", pick([0, 2])))
    }
    if name.has_suffix("rm") && n == 8 {
      return condition(7).map(cc => {
        ("CMOV\{cc}\{width}rm", pick([0] + range(2, 5)))
      })
    }
    return None
  }
  match name {
    "SETCCr" if n == 2 => return condition(1).map(cc => ("SET" + cc, [ops[0]]))
    "SETCCm" if n == 6 =>
      return condition(5).map(cc => ("SET" + cc, pick(range(0, 5))))
    _ => ()
  }
  // stack
  match name {
    "PUSH16r" | "PUSH16rmr" => return Some(("PUSH16r" + mode_suffix, [ops[0]]))
    "PUSH32rmr" => return Some(("PUSH32r", ops))
    "PUSH64rmr" => return Some(("PUSH64r", ops))
    "PUSH16i8" => return Some(("PUSH16i8" + mode_suffix, ops))
    "PUSH16i" => return Some(("PUSH16i16" + mode_suffix, ops))
    "PUSH32i" => return Some(("PUSH32i32", ops))
    "PUSH16rmm" => return Some(("PUSH16m" + mode_suffix, ops))
    "PUSH32rmm" => return Some(("PUSH32m", ops))
    "PUSH64rmm" => return Some(("PUSH64m", ops))
    "POP16r" | "POP16rmr" => return Some(("POP16r" + mode_suffix, [ops[0]]))
    "POP32rmr" => return Some(("POP32r", ops))
    "POP64rmr" => return Some(("POP64r", ops))
    // LLVM ignores the operand-size prefix of LEAVE; the lifter models the
    // 16-bit form
    "LEAVE" | "LEAVE64" if x86_legacy_has_opsize(
        self.memory().to_bytes(),
        mode64,
      ) => return Some(("LEAVE16" + mode_suffix, ops))
    "PUSHF16" => return Some(("PUSHF16" + mode_suffix, ops))
    "POPF16" => return Some(("POPF16" + mode_suffix, ops))
    "RET32" | "RETI32" => return Some(("RET", ops))
    "RETI64" => return Some(("RET64", ops))
    "LRET32" | "LRETI32" =>
      return Some((if mode64 { "RETF64" } else { "RETF" }, ops))
    "LRET64" | "LRETI64" => return Some(("RETF64", ops))
    _ => ()
  }
  // branches with absolute targets
  match name {
    "JMP_1" | "JMP_4" => return absolute().map(target => (name, target))
    "JCC_1" | "JCC_4" =>
      return match (condition(1), absolute()) {
        (Some(cc), Some(target)) =>
          Some(("J" + cc + name.view(start_offset=3).to_owned(), target))
        _ => None
      }
    "JECXZ" => return absolute().map(target => ("JECXZ_1", target))
    "JRCXZ" => return absolute().map(target => ("JRCXZ_1", target))
    _ => ()
  }
  // string instructions
  for op in ["MOVS", "STOS", "CMPS", "SCAS"] {
    if !name.has_prefix(op) || name.length() != op.length() + 1 {
      continue
    }
    let data_width = match name[op.length()] {
      'B' => 8
      'W' => 16
      'L' => 32
      'Q' => 64
      _ => return None
    }
    let address_width = match ops.get(0) {
      Some(ProjectRegisterOperand(_, "RDI")) => 64
      Some(ProjectRegisterOperand(_, "EDI")) => 32
      _ => return None
    }
    if data_width == 64 && address_width != 64 {
      return None
    }
    let rep = x86_legacy_repeat_prefix(self.memory().to_bytes(), mode64)
    let prefix = match (op, rep) {
      ("MOVS" | "STOS", 0xF2 | 0xF3) => "REP_"
      (_, 0xF3) => "REPE_"
      (_, 0xF2) => "REPNE_"
      _ => ""
    }
    let suffix = if address_width == 64 && data_width != 64 {
      "_64"
    } else {
      ""
    }
    return Some((prefix + op + data_width.to_string() + suffix, []))
  }
  // port I/O
  if name.has_prefix("IN") && (name.has_suffix("ri") || name.has_suffix("rr")) {
    let width = x86_legacy_width(name, "IN")
    if width > 0 {
      let port = if name.has_suffix("ri") {
        ops[0]
      } else {
        x86_legacy_register("DX")
      }
      return Some(("IN\{width}", [x86_legacy_accumulator(width), port]))
    }
  }
  if name.has_prefix("OUT") && (name.has_suffix("ir") || name.has_suffix("rr")) {
    let width = x86_legacy_width(name, "OUT")
    if width > 0 {
      let port = if name.has_suffix("ir") {
        ops[0]
      } else {
        x86_legacy_register("DX")
      }
      return Some(("OUT\{width}", [port, x86_legacy_accumulator(width)]))
    }
  }
  // renamed instructions without operand changes
  match name {
    "TRAP" => return Some(("UD2", ops))
    "WAIT" => return Some(("FWAIT", ops))
    "MONITOR32rrr" | "MONITOR64rrr" => return Some(("MONITOR", []))
    "MWAITrr" => return Some(("MWAIT", []))
    "MWAITXrrr" => return Some(("MWAITX", []))
    "FLDCW16m" => return Some(("FLDCWm", ops))
    "FNSTCW16m" => return Some(("FNSTCWm", ops))
    "LDMXCSR" => return Some(("LDMXCSRm", ops))
    "STMXCSR" => return Some(("STMXCSRm", ops))
    _ => ()
  }
  if name.has_prefix("NOOP") {
    return Some(("NOOP", []))
  }
  // SIMD register forms (apply_x86_simd); memory sources are addressed by
  // a base register alone
  let simple_base = (index : Int) => {
    match (ops.get(index + 2), ops.get(index + 3)) {
      (Some(ProjectRegisterOperand(_, "Nil")), Some(ProjectImmediateOperand(0L))
      ) => ops.get(index)
      _ => None
    }
  }
  for base in x86_legacy_simd_rr {
    if (name == base + "rr" || name == base + "ri") && n == 3 {
      return Some((base, pick([0, 2])))
    }
    if name == base + "rm" && n == 7 {
      return simple_base(2).map(reg => (base, [ops[0], reg]))
    }
  }
  for base in ["MOVUPS", "MOVAPS", "MOVDQA", "MOVDQU"] {
    if name == base + "rm" && n == 6 {
      return simple_base(1).map(reg => (base, [ops[0], reg]))
    }
  }
  match name {
    "PSRLDQri" | "PSLLDQri" if n == 3 =>
      return Some(
        (name.view(end_offset=name.length() - 2).to_owned(), pick([0, 2])),
      )
    "MOVUPSrr" | "MOVUPSrr_REV" => return Some(("MOVUPS", ops))
    "MOVAPSrr" | "MOVAPSrr_REV" => return Some(("MOVAPS", ops))
    "MOVDQArr" | "MOVDQArr_REV" => return Some(("MOVDQA", ops))
    "MOVDQUrr" | "MOVDQUrr_REV" => return Some(("MOVDQU", ops))
    "PALIGNRrri" if n == 4 => return Some(("PALIGNR", pick([0, 2, 3])))
    "PMOVMSKBrr" => return Some(("PMOVMSKB", ops))
    _ => ()
  }
  None
}

///|
/// The instruction in the form the Basic BIL lifter and the SIMD semantics
/// expect (see the file comment): instructions decoded by the x86 LLVM
/// decoder (encodings `llvm-x86` and `llvm-x86_64`) are converted, the
/// others are returned unchanged.
fn ProjectDisassemblyInstruction::project_basic_x86_legacy(
  self : ProjectDisassemblyInstruction,
) -> ProjectDisassemblyInstruction {
  let mode64 = match self.encoding() {
    "llvm-x86_64" => true
    "llvm-x86" => false
    _ => return self
  }
  match self.x86_legacy_form(mode64) {
    Some((name, operands)) => self.with_metadata(name~).with_operands(operands)
    None => self
  }
}
