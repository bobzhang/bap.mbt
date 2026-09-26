// The x86 / x86-64 decoder of the Basic `llvm` backend: a reimplementation
// of LLVM's X86 MC disassembler (X86Disassembler.cpp / X86Disassembler-
// Decoder.cpp of LLVM 22) for the legacy, VEX, XOP and 3DNow! encodings.
//
// The opcode tables (which LLVM instruction a prefix context, opcode map,
// opcode and ModR/M byte select), the operand specifications and the
// instruction kinds are generated from LLVM 22 itself into
// `disassembly_basic_x86_tables.mbt`. This file implements the byte-level
// parts: the prefix reader (including LLVM's handling of redundant REX and
// legacy prefixes, mandatory prefixes and prefix-only instructions), the
// VEX/XOP readers, the ModR/M, SIB and displacement readers (16-, 32- and
// 64-bit addressing, RIP-relative and EIZ/RIZ forms), the immediates and
// the translation of the operands into MCInst operands. EVEX and APX
// (REX2) encodings are not supported and decode as invalid instructions.

///|
/// The tables of `disassembly_basic_x86_tables.mbt`, parsed.
priv struct X86LlvmTables {
  names : Array[String]
  opcodes : Array[Int]
  specs : Array[String]
  kinds : Array[Int]
  tsinfo : Array[Int]
  dec_start : Array[Int]
  dec_data : Array[Int]
  tables : Array[Int]
  spaces32 : Array[Int]
  spaces64 : Array[Int]
  tdn : Array[Int]
  registers : Map[String, Int]
  templates : Array[String]
  by_name : Map[String, Int]
}

///|
let x86_llvm_tables_cache : Ref[X86LlvmTables?] = { val: None, }

///|
/// Decodes a string of base-32 varints (see the tables file header).
fn x86_llvm_ints(data : String) -> Array[Int] {
  let out = []
  let mut acc = 0
  let mut shift = 0
  for c in data {
    if c >= 'A' && c <= 'Z' {
      acc = acc | ((c.to_int() - 'A'.to_int()) << shift)
      shift += 5
    } else if c >= '0' && c <= '5' {
      acc = acc | ((c.to_int() - '0'.to_int() + 26) << shift)
      shift += 5
    } else {
      let digit = if c >= 'a' && c <= 'z' {
        c.to_int() - 'a'.to_int()
      } else if c >= '6' && c <= '9' {
        c.to_int() - '6'.to_int() + 26
      } else if c == '+' {
        30
      } else if c == '-' {
        31
      } else {
        continue
      }
      out.push(acc | (digit << shift))
      acc = 0
      shift = 0
    }
  }
  out
}

///|
/// Splits a space-separated table string (the multi-line strings carry
/// newlines that are not part of the data).
fn x86_llvm_words(data : String) -> Array[String] {
  data
  .replace_all(old="\n", new="")
  .split(" ")
  .map(word => word.to_owned())
  .collect()
}

///|
fn x86_llvm_tables_load() -> X86LlvmTables {
  let names = x86_llvm_words(x86_llvm_names_data)
  let by_name : Map[String, Int] = Map([])
  for i, name in names {
    by_name[name] = i
  }
  let dec_data = x86_llvm_ints(x86_llvm_decisions_data)
  let dec_start = []
  let mut off = 0
  while off < dec_data.length() {
    dec_start.push(off)
    let count = match dec_data[off] & 3 {
      0 => 1
      1 => 2
      2 => 16
      _ => 72
    }
    off += 1 + count
  }
  let registers : Map[String, Int] = Map([])
  for entry in x86_llvm_words(x86_llvm_registers_data) {
    let parts : Array[StringView] = entry.split("=").collect()
    if parts.length() == 2 {
      registers[parts[0].to_owned()] = @string.parse_int(parts[1]) catch {
        _ => 0
      }
    }
  }
  {
    names,
    opcodes: x86_llvm_ints(x86_llvm_opcodes_data),
    specs: x86_llvm_words(x86_llvm_specs_data),
    kinds: x86_llvm_ints(x86_llvm_kinds_data),
    tsinfo: x86_llvm_ints(x86_llvm_tsinfo_data),
    dec_start,
    dec_data,
    tables: x86_llvm_ints(x86_llvm_tables_data),
    spaces32: x86_llvm_ints(x86_llvm_spaces32_data),
    spaces64: x86_llvm_ints(x86_llvm_spaces64_data),
    tdn: x86_llvm_ints(x86_llvm_3dnow_data),
    registers,
    templates: x86_llvm_words(x86_llvm_templates_data).map(t => {
      t.replace_all(old="~", new=" ")
    }),
    by_name,
  }
}

///|
fn x86_llvm_tables() -> X86LlvmTables {
  match x86_llvm_tables_cache.val {
    Some(tables) => tables
    None => {
      let tables = x86_llvm_tables_load()
      x86_llvm_tables_cache.val = Some(tables)
      tables
    }
  }
}

///|
/// The ModR/M decision `dec` applied to `modrm`: the local instruction id
/// or -1 (invalid), and whether LLVM reads the ModR/M byte.
fn X86LlvmTables::decide(
  self : X86LlvmTables,
  dec : Int,
  modrm : Int,
) -> (Int, Bool) {
  let start = self.dec_start[dec]
  let header = self.dec_data[start]
  let read = header >= 4
  let reg_form = modrm >> 6 == 3
  let reg_field = (modrm >> 3) & 7
  let value = match header & 3 {
    0 => self.dec_data[start + 1]
    1 => self.dec_data[start + (if reg_form { 2 } else { 1 })]
    2 => self.dec_data[start + 1 + (if reg_form { 8 } else { 0 }) + reg_field]
    _ =>
      if reg_form {
        self.dec_data[start + 9 + (modrm - 0xC0)]
      } else {
        self.dec_data[start + 1 + reg_field]
      }
  }
  (value - 1, read)
}

///|
/// Lookup of an instruction in the table selected by `slot` of the prefix
/// context spaces of the mode.
fn X86LlvmTables::lookup(
  self : X86LlvmTables,
  mode64 : Bool,
  slot : Int,
  opcode : Int,
  modrm : Int,
) -> (Int, Bool) {
  let spaces = if mode64 { self.spaces64 } else { self.spaces32 }
  let table = spaces[slot] - 1
  if table < 0 {
    return (-1, false)
  }
  self.decide(self.tables[table * 256 + opcode], modrm)
}

///|
/// A decoded x86 instruction in LLVM's MCInst form.
priv struct X86LlvmInsn {
  id : Int
  size : Int
  operands : Array[ProjectInstructionOperand]
  lock : Bool
  rep : Int
  mandatory : Int
  adsize : Bool
  mode64 : Bool
  opcode : Int
}

///|
priv suberror X86LlvmFail {
  X86LlvmFail(Int)
}

///|
priv struct X86LlvmCursor {
  bytes : BytesView
  mut pos : Int
}

///|
fn X86LlvmCursor::consume(self : X86LlvmCursor) -> Int raise X86LlvmFail {
  if self.pos >= self.bytes.length() {
    raise X86LlvmFail(self.pos)
  }
  let value = self.bytes[self.pos].to_int()
  self.pos += 1
  value
}

///|
fn X86LlvmCursor::peek(self : X86LlvmCursor) -> Int {
  if self.pos >= self.bytes.length() {
    -1
  } else {
    self.bytes[self.pos].to_int()
  }
}

///|
/// Little-endian unsigned read of `count` bytes.
fn X86LlvmCursor::read_le(
  self : X86LlvmCursor,
  count : Int,
) -> UInt64 raise X86LlvmFail {
  let mut value = 0UL
  for k in 0..<count {
    value = value | (self.consume().to_uint64() << (8 * k))
  }
  value
}

///|
fn x86_llvm_sext(value : UInt64, bits : Int) -> Int64 {
  if bits >= 64 {
    value.reinterpret_as_int64()
  } else {
    let shift = 64 - bits
    (value << shift).reinterpret_as_int64() >> shift
  }
}

///|
let x86_llvm_gpr8 : Array[String] = [
  "AL", "CL", "DL", "BL", "AH", "CH", "DH", "BH", "R8B", "R9B", "R10B", "R11B", "R12B",
  "R13B", "R14B", "R15B",
]

///|
let x86_llvm_gpr8_rex : Array[String] = [
  "AL", "CL", "DL", "BL", "SPL", "BPL", "SIL", "DIL", "R8B", "R9B", "R10B", "R11B",
  "R12B", "R13B", "R14B", "R15B",
]

///|
let x86_llvm_gpr16 : Array[String] = [
  "AX", "CX", "DX", "BX", "SP", "BP", "SI", "DI", "R8W", "R9W", "R10W", "R11W", "R12W",
  "R13W", "R14W", "R15W",
]

///|
let x86_llvm_gpr32 : Array[String] = [
  "EAX", "ECX", "EDX", "EBX", "ESP", "EBP", "ESI", "EDI", "R8D", "R9D", "R10D", "R11D",
  "R12D", "R13D", "R14D", "R15D",
]

///|
let x86_llvm_gpr64 : Array[String] = [
  "RAX", "RCX", "RDX", "RBX", "RSP", "RBP", "RSI", "RDI", "R8", "R9", "R10", "R11",
  "R12", "R13", "R14", "R15",
]

///|
let x86_llvm_segments : Array[String] = ["ES", "CS", "SS", "DS", "FS", "GS"]

///|
/// The register of file `file` (an operand specification letter) with
/// encoding `index`, or `None` when LLVM rejects it.
fn x86_llvm_register(
  file : Char,
  index : Int,
  rex : Bool,
  regsize : Int,
) -> String? {
  let file = if file == 'v' {
    match regsize {
      2 => 'w'
      8 => 'q'
      _ => 'd'
    }
  } else {
    file
  }
  match file {
    'b' =>
      Some(if rex { x86_llvm_gpr8_rex[index] } else { x86_llvm_gpr8[index] })
    'w' => Some(x86_llvm_gpr16[index])
    'd' => Some(x86_llvm_gpr32[index])
    'q' => Some(x86_llvm_gpr64[index])
    'x' => Some("XMM\{index}")
    'y' => Some("YMM\{index}")
    'm' => Some("MM\{index & 7}")
    's' =>
      if (index & 7) <= 5 {
        Some(x86_llvm_segments[index & 7])
      } else {
        None
      }
    'c' => Some("CR\{index}")
    'e' => Some("DR\{index}")
    'k' => {
      let index = index & 15
      if index <= 7 {
        Some("K\{index}")
      } else {
        None
      }
    }
    't' => if index <= 7 { Some("TMM\{index}") } else { None }
    _ => None
  }
}

///|
/// The effective address of a ModR/M operand.
priv struct X86LlvmModrm {
  modrm : Int
  reg : Int
  rm : Int
  memory : Bool
  base : String
  index : String
  scale : Int
  disp : Int64
  sib : Bool
  sib_index : Int
}

///|
fn x86_llvm_read_modrm(
  cursor : X86LlvmCursor,
  mode64 : Bool,
  addrsize : Int,
  rex : Int,
) -> X86LlvmModrm raise X86LlvmFail {
  let modrm = cursor.consume()
  let md = modrm >> 6
  let rm_low = modrm & 7
  let reg = ((modrm >> 3) & 7) | (((rex >> 2) & 1) << 3)
  let rm = rm_low | ((rex & 1) << 3)
  if md == 3 {
    return {
      modrm,
      reg,
      rm,
      memory: false,
      base: "",
      index: "",
      scale: 1,
      disp: 0,
      sib: false,
      sib_index: 0,
    }
  }
  let mut base = ""
  let mut index = ""
  let mut scale = 1
  let mut dsize = 0
  let mut sib = false
  let mut sib_index = 0
  if addrsize == 2 {
    if md == 0 && rm_low == 6 {
      dsize = 2
    } else {
      let (b, i) = match rm_low {
        0 => ("BX", "SI")
        1 => ("BX", "DI")
        2 => ("BP", "SI")
        3 => ("BP", "DI")
        4 => ("SI", "")
        5 => ("DI", "")
        6 => ("BP", "")
        _ => ("BX", "")
      }
      base = b
      index = i
      dsize = if md == 1 { 1 } else if md == 2 { 2 } else { 0 }
    }
  } else {
    let names = if addrsize == 4 { x86_llvm_gpr32 } else { x86_llvm_gpr64 }
    if rm_low == 4 {
      sib = true
      let s = cursor.consume()
      let si = ((s >> 3) & 7) | (((rex >> 1) & 1) << 3)
      let sb = (s & 7) | ((rex & 1) << 3)
      sib_index = si
      scale = 1 << (s >> 6)
      if si != 4 {
        index = names[si]
      }
      if (sb == 5 || sb == 13) && md == 0 {
        dsize = 4
      } else {
        base = names[sb]
        dsize = if md == 1 { 1 } else if md == 2 { 4 } else { 0 }
      }
      if index == "" &&
        (
          scale != 1 ||
          (base == "" && !mode64) ||
          (
            base != "" &&
            base != "ESP" &&
            base != "RSP" &&
            base != "R12D" &&
            base != "R12"
          )
        ) {
        index = if addrsize == 4 { "EIZ" } else { "RIZ" }
      }
    } else if rm_low == 5 && md == 0 {
      if mode64 {
        base = if addrsize == 4 { "EIP" } else { "RIP" }
      }
      dsize = 4
    } else {
      base = names[rm]
      dsize = if md == 1 { 1 } else if md == 2 { 4 } else { 0 }
    }
  }
  let disp = if dsize > 0 {
    x86_llvm_sext(cursor.read_le(dsize), 8 * dsize)
  } else {
    0L
  }
  { modrm, reg, rm, memory: true, base, index, scale, disp, sib, sib_index, }
}

///|
fn x86_llvm_is_legacy_prefix(byte : Int) -> Bool {
  match byte {
    0x26
    | 0x2E
    | 0x36
    | 0x3E
    | 0x64
    | 0x65
    | 0x66
    | 0x67
    | 0xF0
    | 0xF2
    | 0xF3 => true
    _ => false
  }
}

///|
/// Decodes the instruction at the start of `bytes` like LLVM's X86
/// disassembler: `Ok(insn)` or `Err(size)` for an invalid instruction of
/// `size` bytes (the bytes LLVM consumed before failing, at least one).
fn x86_llvm_decode(
  bytes : BytesView,
  mode64 : Bool,
) -> Result[X86LlvmInsn, Int] {
  let cursor : X86LlvmCursor = { bytes, pos: 0, }
  x86_llvm_decode_cursor(cursor, mode64) catch {
    X86LlvmFail(size) => Err(if size < 1 { 1 } else { size })
  }
}

///|
fn x86_llvm_decode_cursor(
  cursor : X86LlvmCursor,
  mode64 : Bool,
) -> Result[X86LlvmInsn, Int] raise X86LlvmFail {
  let tables = x86_llvm_tables()
  let n = cursor.bytes.length()
  let is_rex = (byte : Int) => mode64 && byte >= 0x40 && byte <= 0x4F
  let mut lock = false
  let mut rep = 0
  let mut mand = 0
  let mut opsize = false
  let mut adsize = false
  let mut segment = -1
  let mut rex = 0
  let mut xacquire = false
  let mut byte = -1
  // prefixes (LLVM readPrefixes)
  while cursor.pos < n {
    byte = cursor.consume()
    if cursor.pos == 1 && byte == 0xF0 {
      break
    }
    let next = cursor.peek()
    if (byte == 0xF2 || byte == 0xF3) && next >= 0 {
      if next == 0xF0 || (next & 0xFE) == 0x86 || (next & 0xF8) == 0x90 {
        xacquire = true
        if !(byte == 0xF3 && next == 0x90) {
          break
        }
      }
      if byte == 0xF3 &&
        (next == 0x88 || next == 0x89 || next == 0xC6 || next == 0xC7) {
        xacquire = true
        break
      }
      if is_rex(next) && cursor.pos + 1 >= n {
        raise X86LlvmFail(cursor.pos + 1)
      }
    }
    match byte {
      0xF0 => lock = true
      0xF2 | 0xF3 =>
        if next >= 0 {
          if is_rex(next) || next == 0x0F || next == 0x66 {
            mand = byte
          }
          rep = byte
        }
      0x26 => segment = 0
      0x2E => segment = 1
      0x36 => segment = 2
      0x3E => segment = 3
      0x64 => segment = 4
      0x65 => segment = 5
      0x66 => {
        opsize = true
        if next >= 0 && mand == 0 && (next == 0x0F || is_rex(next)) {
          mand = 0x66
        }
      }
      0x67 => adsize = true
      _ =>
        if is_rex(byte) {
          rex = byte
          continue
        } else {
          break
        }
    }
    rex = 0
  }
  // vector extension prefixes
  let mut vex = false
  let mut xop = false
  let mut vex_map = 0
  let mut vex_w = 0
  let mut vex_l = 0
  let mut vex_pp = 0
  let mut vex_vvvv = 0
  if byte == 0x62 && cursor.pos < n {
    let b1 = cursor.peek()
    if mode64 || (b1 & 0xC0) == 0xC0 {
      // EVEX: not supported
      raise X86LlvmFail(if cursor.pos + 3 < n { cursor.pos + 3 } else { n })
    }
    cursor.pos -= 1
  } else if (byte == 0xC4 || byte == 0xC5) && cursor.pos < n {
    let b1 = cursor.peek()
    if mode64 || (b1 & 0xC0) == 0xC0 {
      vex = true
      let v1 = cursor.consume()
      let (r, x, b) = (
        1 - ((v1 >> 7) & 1),
        1 - ((v1 >> 6) & 1),
        1 - ((v1 >> 5) & 1),
      )
      if byte == 0xC4 {
        let v2 = cursor.consume()
        vex_map = v1 & 0x1F
        vex_w = (v2 >> 7) & 1
        vex_vvvv = 15 - ((v2 >> 3) & 15)
        vex_l = (v2 >> 2) & 1
        vex_pp = v2 & 3
        if mode64 {
          rex = 0x40 | (vex_w << 3) | (r << 2) | (x << 1) | b
        }
      } else {
        vex_map = 1
        vex_vvvv = 15 - ((v1 >> 3) & 15)
        vex_l = (v1 >> 2) & 1
        vex_pp = v1 & 3
        if vex_pp == 1 {
          opsize = true
        }
        if mode64 {
          rex = 0x40 | (r << 2)
        }
      }
    } else {
      cursor.pos -= 1
    }
  } else if byte == 0x8F && cursor.pos < n {
    let b1 = cursor.peek()
    if (b1 & 0x38) != 0 {
      vex = true
      xop = true
      let v1 = cursor.consume()
      let v2 = cursor.consume()
      vex_map = v1 & 0x1F
      vex_w = (v2 >> 7) & 1
      vex_vvvv = 15 - ((v2 >> 3) & 15)
      vex_l = (v2 >> 2) & 1
      vex_pp = v2 & 3
      if vex_pp == 1 {
        opsize = true
      }
      if mode64 {
        rex = 0x40 |
          (vex_w << 3) |
          ((1 - ((v1 >> 7) & 1)) << 2) |
          ((1 - ((v1 >> 6) & 1)) << 1) |
          (1 - ((v1 >> 5) & 1))
      }
    } else {
      cursor.pos -= 1
    }
  } else if mode64 && byte == 0xD5 && cursor.pos < n {
    // REX2 (APX): not supported
    raise X86LlvmFail(cursor.pos + 1)
  } else {
    cursor.pos -= 1
  }
  let rexw = (rex >> 3) & 1
  let (regsize, addrsize, immsize) = if mode64 {
    (
      if rexw == 1 {
        8
      } else if opsize {
        2
      } else {
        4
      },
      if adsize {
        4
      } else {
        8
      },
      if rexw == 0 && opsize {
        2
      } else {
        4
      },
    )
  } else {
    (
      if opsize {
        2
      } else {
        4
      },
      if adsize {
        2
      } else {
        4
      },
      if opsize {
        2
      } else {
        4
      },
    )
  }
  // opcode
  let mut map = 0
  let mut opcode = 0
  let mut tdn_modrm : X86LlvmModrm? = None
  if vex {
    let valid = if xop {
      vex_map >= 8 && vex_map <= 10
    } else {
      vex_map >= 1 && vex_map <= 3
    }
    if !valid {
      raise X86LlvmFail(cursor.pos)
    }
    map = vex_map
    opcode = cursor.consume()
  } else {
    let mut current = cursor.consume()
    if current == 0x0F {
      current = cursor.consume()
      if current == 0x38 {
        current = cursor.consume()
        map = 2
      } else if current == 0x3A {
        current = cursor.consume()
        map = 3
      } else if current == 0x0F {
        tdn_modrm = Some(x86_llvm_read_modrm(cursor, mode64, addrsize, rex))
        current = cursor.consume()
        map = 4
      } else {
        map = 1
      }
    } else if mand != 0 {
      mand = 0
    }
    opcode = current
  }
  // prefix bytes decoded as instructions (end of input, xacquire/xrelease)
  if map == 0 && !vex && (x86_llvm_is_legacy_prefix(opcode) || is_rex(opcode)) {
    let name = match opcode {
      0x26 => "ES_PREFIX"
      0x2E => "CS_PREFIX"
      0x36 => "SS_PREFIX"
      0x3E => "DS_PREFIX"
      0x64 => "FS_PREFIX"
      0x65 => "GS_PREFIX"
      0x66 => "DATA16_PREFIX"
      0x67 => if mode64 { "ADDR32_PREFIX" } else { "ADDR16_PREFIX" }
      0xF0 => "LOCK_PREFIX"
      0xF2 => if xacquire { "XACQUIRE_PREFIX" } else { "REPNE_PREFIX" }
      0xF3 => if xacquire { "XRELEASE_PREFIX" } else { "REP_PREFIX" }
      _ => {
        // only 0x48 is an instruction (REX64_PREFIX) in LLVM's tables
        if opcode != 0x48 {
          raise X86LlvmFail(cursor.pos)
        }
        "REX64_PREFIX"
      }
    }
    return Ok({
      id: tables.by_name.get(name).unwrap_or(0),
      size: cursor.pos,
      operands: [],
      lock,
      rep,
      mandatory: mand,
      adsize,
      mode64,
      opcode,
    })
  }
  // instruction id
  let lookup_opcode = if map == 0 && opcode == 0x90 && (rex & 1) == 1 && !vex {
    0x91
  } else {
    opcode
  }
  let (id, read_modrm) = match tdn_modrm {
    Some(ea) => {
      let entry = tables.tdn[opcode * 2 + (if ea.memory { 1 } else { 0 })]
      (entry - 1, false)
    }
    None => {
      let slot = if vex {
        let mi = if xop { map - 8 } else { map - 1 }
        384 +
        (
          ((((if xop { 1 } else { 0 }) * 3 + mi) * 4 + vex_pp) * 2 + vex_l) * 2 +
          vex_w
        )
      } else {
        let mi = match mand {
          0x66 => 1
          0xF2 => 2
          0xF3 => 3
          _ => 0
        }
        let ri = if mand != 0 {
          0
        } else {
          match rep {
            0xF2 => 1
            0xF3 => 2
            _ => 0
          }
        }
        (
          (
            ((map * 4 + mi) * 2 + (if opsize { 1 } else { 0 })) * 2 +
            (if adsize { 1 } else { 0 })
          ) *
          3 +
          ri
        ) *
        2 +
        rexw
      }
      let modrm = cursor.peek()
      let (id, read) = tables.lookup(
        mode64,
        slot,
        lookup_opcode,
        if modrm < 0 {
          0
        } else {
          modrm
        },
      )
      // LLVM also looks the instruction up with the operand-size attribute
      // when a 0x66 prefix is present but not part of the context; that
      // lookup reads the ModR/M byte when its table needs it
      let read = if vex && opsize && vex_pp != 1 && !read {
        let alt = 384 +
          (
            (
              (
                (
                  (if xop { 1 } else { 0 }) * 3 +
                  (if xop { map - 8 } else { map - 1 })
                ) *
                4 +
                1
              ) *
              2 +
              vex_l
            ) *
            2 +
            vex_w
          )
        tables.lookup(
          mode64,
          alt,
          lookup_opcode,
          if modrm < 0 {
            0
          } else {
            modrm
          },
        ).1
      } else {
        read
      }
      if read && modrm < 0 {
        raise X86LlvmFail(cursor.pos)
      }
      (id, read)
    }
  }
  let ea = match tdn_modrm {
    Some(ea) => Some(ea)
    None =>
      if read_modrm {
        Some(x86_llvm_read_modrm(cursor, mode64, addrsize, rex))
      } else {
        None
      }
  }
  if id < 0 {
    raise X86LlvmFail(cursor.pos)
  }
  let spec = tables.specs[id]
  let has_rex = rex != 0
  let vvvv = if mode64 { vex_vvvv } else { vex_vvvv & 7 }
  // operand reading (LLVM readOperands): immediates in specification order
  // and register validity checks
  let mut need_vvvv = vex && vex_vvvv != 0
  let imms : Array[UInt64] = []
  let mut saw_regimm = false
  let items = spec.length() / 2
  for k in 0..<items {
    let tag = spec[2 * k].to_int().unsafe_to_char()
    let arg = spec[2 * k + 1].to_int().unsafe_to_char()
    match tag {
      'I' | 'U' | 'J' =>
        if saw_regimm && arg == 'b' && tag != 'J' {
          imms.push(imms[imms.length() - 1] & 15)
        } else {
          let size = match arg {
            'b' => 1
            'w' => 2
            'd' => 4
            'q' => 8
            _ => immsize
          }
          imms.push(cursor.read_le(size))
        }
      'X' => {
        imms.push(cursor.read_le(1))
        saw_regimm = true
      }
      'O' => imms.push(cursor.read_le(addrsize))
      'g' | 'r' | 'v' | 'o' => {
        let index = match tag {
          'g' => ea.map(e => e.reg).unwrap_or(0)
          'r' => ea.map(e => e.rm).unwrap_or(0)
          'v' => {
            need_vvvv = false
            if !vex {
              raise X86LlvmFail(cursor.pos)
            }
            vvvv
          }
          _ => (opcode & 7) | ((rex & 1) << 3)
        }
        if x86_llvm_register(arg, index, has_rex, regsize) is None {
          raise X86LlvmFail(cursor.pos)
        }
      }
      'M' =>
        match ea {
          Some(e) if e.memory && (arg == '.' || e.sib) => ()
          _ => raise X86LlvmFail(cursor.pos)
        }
      _ => ()
    }
  }
  if need_vvvv {
    raise X86LlvmFail(cursor.pos)
  }
  let size = cursor.pos
  // translation into MCInst operands
  let groups : Array[Array[ProjectInstructionOperand]] = []
  let mut imm_index = 0
  let reg = (name : String) => {
    ProjectInstructionOperand::register(
      name~,
      code=tables.registers.get(name).unwrap_or(0),
    )
  }
  let nil = ProjectInstructionOperand::register(name="Nil")
  let seg_operand = () => {
    if segment < 0 {
      nil
    } else {
      reg(x86_llvm_segments[segment])
    }
  }
  for k in 0..<items {
    let tag = spec[2 * k].to_int().unsafe_to_char()
    let arg = spec[2 * k + 1].to_int().unsafe_to_char()
    let group : Array[ProjectInstructionOperand] = match tag {
      'd' | 'D' => []
      'g' | 'r' | 'v' | 'o' => {
        let index = match tag {
          'g' => ea.map(e => e.reg).unwrap_or(0)
          'r' => ea.map(e => e.rm).unwrap_or(0)
          'v' => vvvv
          _ => (opcode & 7) | ((rex & 1) << 3)
        }
        [reg(x86_llvm_register(arg, index, has_rex, regsize).unwrap_or("Nil"))]
      }
      'f' => [reg("ST\{ea.map(e => e.modrm & 7).unwrap_or(0)}")]
      'M' =>
        match ea {
          Some(e) => {
            let index = match arg {
              'x' => "XMM\{e.sib_index}"
              'y' => "YMM\{e.sib_index}"
              // SIB-only forms (ForceSIB): no EIZ/RIZ pseudo index
              's' if e.index == "EIZ" || e.index == "RIZ" => ""
              _ => e.index
            }
            [
              if e.base == "" {
                nil
              } else {
                reg(e.base)
              },
              ProjectInstructionOperand::immediate(e.scale.to_int64()),
              if index == "" {
                nil
              } else {
                reg(index)
              },
              ProjectInstructionOperand::immediate(e.disp),
              seg_operand(),
            ]
          }
          None => []
        }
      'C' => [ProjectInstructionOperand::immediate((opcode & 15).to_int64())]
      'I' | 'U' | 'J' => {
        let raw = imms[imm_index]
        imm_index += 1
        let value = match (tag, arg) {
          ('U', _) | (_, 'v') => raw.reinterpret_as_int64()
          (_, 'b') => x86_llvm_sext(raw, 8)
          (_, 'w') => x86_llvm_sext(raw, 16)
          (_, 'd') => x86_llvm_sext(raw, 32)
          _ => raw.reinterpret_as_int64()
        }
        [ProjectInstructionOperand::immediate(value)]
      }
      'X' => {
        let raw = imms[imm_index]
        imm_index += 1
        let name = if arg == 'y' { "YMM" } else { "XMM" }
        [reg(name + (raw >> 4).to_int().to_string())]
      }
      'O' => {
        let raw = imms[imm_index]
        imm_index += 1
        [
          ProjectInstructionOperand::immediate(raw.reinterpret_as_int64()),
          seg_operand(),
        ]
      }
      'S' => {
        let base = if mode64 {
          if adsize {
            "ESI"
          } else {
            "RSI"
          }
        } else if adsize {
          "SI"
        } else {
          "ESI"
        }
        [reg(base), seg_operand()]
      }
      'T' => {
        let base = if mode64 {
          if adsize {
            "EDI"
          } else {
            "RDI"
          }
        } else if adsize {
          "DI"
        } else {
          "EDI"
        }
        [reg(base)]
      }
      _ => []
    }
    groups.push(group)
  }
  let operands : Array[ProjectInstructionOperand] = []
  for k in 0..<items {
    let tag = spec[2 * k].to_int().unsafe_to_char()
    match tag {
      'd' | 'D' => {
        let target = spec[2 * k + 1].to_int() -
          '0'.to_int() +
          (if tag == 'D' { 10 } else { 0 })
        for operand in groups[target] {
          operands.push(operand)
        }
      }
      _ =>
        for operand in groups[k] {
          operands.push(operand)
        }
    }
  }
  Ok({ id, size, operands, lock, rep, mandatory: mand, adsize, mode64, opcode, })
}

///|
/// The kinds of the instruction with local id `id` (the MCInstrDesc flags;
/// `MayAffectControlFlow` for branches, calls and returns).
fn X86LlvmTables::project_kinds(
  self : X86LlvmTables,
  id : Int,
) -> Array[ProjectInstructionKind] {
  let bits = self.kinds[id]
  let kinds = []
  let all : Array[(Int, ProjectInstructionKind)] = [
    (1, ProjectConditionalBranch),
    (2, ProjectUnconditionalBranch),
    (4, ProjectIndirectBranch),
    (8, ProjectReturn),
    (16, ProjectCall),
    (32, ProjectBarrier),
    (64, ProjectTerminator),
    (128, ProjectMayAffectControlFlow),
    (256, ProjectMayLoad),
    (512, ProjectMayStore),
  ]
  for entry in all {
    if (bits & entry.0) != 0 {
      kinds.push(entry.1)
    }
  }
  kinds
}

///|
/// Decodes the x86 (`mode64 = false`) or x86-64 instruction at the start of
/// `memory` with the LLVM-compatible decoder.
fn project_disassembly_basic_decode_x86_mc(
  memory : @memory.Memory,
  mode64~ : Bool,
) -> Result[ProjectDisassemblyBasicDecoded, String] {
  let length = memory.length()
  if length == 0 {
    return Ok(BasicDecodedEnd)
  }
  let window = 32
  let decode = (count : Int) => {
    match memory.view(words=count) {
      Ok(chunk) => Ok(x86_llvm_decode(chunk.to_bytes()[:], mode64))
      Err(reason) => Err(reason)
    }
  }
  let first = if length > window { window } else { length }
  let decoded = match decode(first) {
    Ok(result) => result
    Err(reason) => return Err(reason)
  }
  // prefix runs longer than the window: decode again over the whole memory
  let decoded = match decoded {
    Ok(insn) if insn.size >= first && length > first =>
      match decode(length) {
        Ok(result) => result
        Err(reason) => return Err(reason)
      }
    Err(size) if size >= first && length > first =>
      match decode(length) {
        Ok(result) => result
        Err(reason) => return Err(reason)
      }
    other => other
  }
  match decoded {
    Ok(insn) =>
      match memory.view(words=insn.size) {
        Ok(chunk) => {
          let tables = x86_llvm_tables()
          let assembly = x86_llvm_print(tables, insn, chunk.min_addr())
          let instruction = ProjectDisassemblyInstruction::create(
            chunk,
            assembly~,
            bil=x86_llvm_bil_text(tables, insn, chunk, assembly),
            code=tables.opcodes[insn.id],
            name=tables.names[insn.id],
            encoding=if mode64 { "llvm-x86_64" } else { "llvm-x86" },
            kinds=tables.project_kinds(insn.id),
            operands=insn.operands,
          )
          Ok(BasicDecodedValid(chunk, instruction))
        }
        Err(reason) => Err(reason)
      }
    Err(size) => {
      let size = if size > length { length } else { size }
      match memory.view(words=size) {
        Ok(chunk) => Ok(BasicDecodedInvalid(chunk))
        Err(reason) => Err(reason)
      }
    }
  }
}

///|
/// The textual summary of the semantics kept with the instruction: the
/// target of a direct branch (`jmp 0x...`, `if jne then jmp 0x...`), the
/// raw-byte placeholder otherwise.
fn x86_llvm_bil_text(
  tables : X86LlvmTables,
  insn : X86LlvmInsn,
  chunk : @memory.Memory,
  assembly : String,
) -> String {
  let bits = tables.kinds[insn.id]
  let branch = (bits & 3) != 0 && (bits & 4) == 0
  match (branch, insn.operands.get(0)) {
    (true, Some(ProjectImmediateOperand(offset))) =>
      match
        project_disassembly_basic_add_signed_offset(
          chunk.max_addr() + 1UL,
          offset,
        ) {
        Some(target) => {
          let jump = "jmp 0x" + target.to_string(radix=16)
          if (bits & 1) != 0 {
            let mnemonic = match assembly.find(" ") {
              Some(space) => assembly.view(end_offset=space).to_owned()
              None => assembly
            }
            "if " + mnemonic + " then " + jump
          } else {
            jump
          }
        }
        None => project_raw_byte_bil(chunk)
      }
    _ => project_raw_byte_bil(chunk)
  }
}
