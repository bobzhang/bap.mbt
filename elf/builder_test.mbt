///|
/// A program header of a test file.
priv struct TPhdr {
  typ : UInt32
  flags : UInt32
  offset : UInt64
  vaddr : UInt64
  paddr : UInt64
  filesz : UInt64
  memsz : UInt64
  align : UInt64
}

///|
/// A section of a test file; its contents are placed after the headers.
priv struct TSection {
  name : String
  typ : UInt32
  flags : UInt64
  addr : UInt64
  data : Bytes
  link : UInt32
  info : UInt32
  align : UInt64
  entsize : UInt64
}

///|
fn tsection(
  name : String,
  typ : UInt32,
  data : Bytes,
  flags~ : UInt64 = 0,
  addr~ : UInt64 = 0,
  link~ : UInt32 = 0,
  info~ : UInt32 = 0,
  align~ : UInt64 = 1,
  entsize~ : UInt64 = 0,
) -> TSection {
  { name, typ, flags, addr, data, link, info, align, entsize, }
}

///|
priv struct Writer {
  buf : Array[Byte]
  big : Bool
}

///|
fn Writer::put(
  self : Writer,
  offset : Int32,
  bytes : Int32,
  value : UInt64,
) -> Unit {
  while self.buf.length() < offset + bytes {
    self.buf.push(b'\x00')
  }
  for i in 0..<bytes {
    let shift = if self.big { (bytes - 1 - i) * 8 } else { i * 8 }
    self.buf[offset + i] = ((value >> shift) & 0xffUL).to_byte()
  }
}

///|
fn Writer::blob(self : Writer, offset : Int32, data : Bytes) -> Unit {
  while self.buf.length() < offset + data.length() {
    self.buf.push(b'\x00')
  }
  for i in 0..<data.length() {
    self.buf[offset + i] = data[i]
  }
}

///|
/// Builds an ELF file: header, program headers, section contents (at
/// their natural order after the headers), a `.shstrtab` section appended
/// when there are sections, then the section header table.
fn build_elf(
  is64~ : Bool = true,
  big~ : Bool = false,
  typ~ : Int32 = 2,
  machine~ : Int32 = 62,
  osabi~ : Int32 = 0,
  entry~ : UInt64 = 0,
  flags~ : UInt32 = 0,
  phdrs~ : Array[TPhdr] = [],
  sections~ : Array[TSection] = [],
  tail~ : Bytes = b"",
) -> Bytes {
  let w : Writer = { buf: [], big, }
  let word = if is64 { 8 } else { 4 }
  let ehsize = if is64 { 64 } else { 52 }
  let phentsize = if is64 { 56 } else { 32 }
  let shentsize = if is64 { 64 } else { 40 }
  w.blob(0, b"\x7fELF")
  w.put(4, 1, if is64 { 2 } else { 1 })
  w.put(5, 1, if big { 2 } else { 1 })
  w.put(6, 1, 1)
  w.put(7, 1, osabi.to_uint64())
  w.put(16, 2, typ.to_uint64())
  w.put(18, 2, machine.to_uint64())
  w.put(20, 4, 1)
  w.put(24, word, entry)
  let phoff = if phdrs.is_empty() { 0 } else { ehsize }
  // section contents follow the program headers
  let mut cursor = ehsize + phdrs.length() * phentsize
  let all_sections = if sections.is_empty() {
    []
  } else {
    let names = StringBuilder()
    names.write_char('\u{0}')
    let offsets = []
    for s in sections {
      offsets.push(names.to_string().length())
      names.write_string(s.name)
      names.write_char('\u{0}')
    }
    offsets.push(names.to_string().length())
    names.write_string(".shstrtab")
    names.write_char('\u{0}')
    let shstrtab = @utf8.encode(names.to_string())
    let result = [(0U, tsection("", 0, b""), 0)]
    for i, s in sections {
      result.push((offsets[i].reinterpret_as_uint(), s, 0))
    }
    result.push(
      (
        offsets[sections.length()].reinterpret_as_uint(),
        tsection(".shstrtab", 3, shstrtab),
        0,
      ),
    )
    result
  }
  let placed = []
  for entry in all_sections {
    let (name_off, s, _) = entry
    let off = if s.typ == 0 { 0 } else { cursor }
    if s.typ != 0 && s.typ != 8 {
      w.blob(cursor, s.data)
      cursor = cursor + s.data.length()
    }
    placed.push((name_off, s, off))
  }
  w.blob(cursor, tail)
  cursor = cursor + tail.length()
  let shoff = if placed.is_empty() { 0 } else { cursor }
  for i, entry in placed {
    let (name_off, s, off) = entry
    let base = shoff + i * shentsize
    // NOBITS sections take the size of their (unwritten) contents
    let size = s.data.length().to_uint64()
    w.put(base, 4, name_off.to_uint64())
    w.put(base + 4, 4, s.typ.to_uint64())
    if is64 {
      w.put(base + 8, 8, s.flags)
      w.put(base + 16, 8, s.addr)
      w.put(base + 24, 8, off.to_uint64())
      w.put(base + 32, 8, size)
      w.put(base + 40, 4, s.link.to_uint64())
      w.put(base + 44, 4, s.info.to_uint64())
      w.put(base + 48, 8, s.align)
      w.put(base + 56, 8, s.entsize)
    } else {
      w.put(base + 8, 4, s.flags)
      w.put(base + 12, 4, s.addr)
      w.put(base + 16, 4, off.to_uint64())
      w.put(base + 20, 4, size)
      w.put(base + 24, 4, s.link.to_uint64())
      w.put(base + 28, 4, s.info.to_uint64())
      w.put(base + 32, 4, s.align)
      w.put(base + 36, 4, s.entsize)
    }
  }
  for i, p in phdrs {
    let base = phoff + i * phentsize
    w.put(base, 4, p.typ.to_uint64())
    if is64 {
      w.put(base + 4, 4, p.flags.to_uint64())
      w.put(base + 8, 8, p.offset)
      w.put(base + 16, 8, p.vaddr)
      w.put(base + 24, 8, p.paddr)
      w.put(base + 32, 8, p.filesz)
      w.put(base + 40, 8, p.memsz)
      w.put(base + 48, 8, p.align)
    } else {
      w.put(base + 4, 4, p.offset)
      w.put(base + 8, 4, p.vaddr)
      w.put(base + 12, 4, p.paddr)
      w.put(base + 16, 4, p.filesz)
      w.put(base + 20, 4, p.memsz)
      w.put(base + 24, 4, p.flags.to_uint64())
      w.put(base + 28, 4, p.align)
    }
  }
  let (phoff_at, shoff_at) = if is64 { (32, 40) } else { (28, 32) }
  w.put(phoff_at, word, phoff.to_uint64())
  w.put(shoff_at, word, shoff.to_uint64())
  let fields = if is64 { 48 } else { 36 }
  w.put(fields, 4, flags.to_uint64())
  w.put(fields + 4, 2, ehsize.to_uint64())
  w.put(fields + 6, 2, phentsize.to_uint64())
  w.put(fields + 8, 2, phdrs.length().to_uint64())
  w.put(fields + 10, 2, shentsize.to_uint64())
  w.put(fields + 12, 2, placed.length().to_uint64())
  w.put(
    fields + 14,
    2,
    if placed.is_empty() {
      0
    } else {
      (placed.length() - 1).to_uint64()
    },
  )
  while w.buf.length() < ehsize {
    w.buf.push(b'\x00')
  }
  Bytes::from_array(w.buf)
}

///|
/// The offset of the first byte after the headers of a file built by
/// `build_elf` with `phnum` program headers.
fn contents_offset(phnum : Int32, is64~ : Bool = true) -> UInt64 {
  (if is64 { 64 + phnum * 56 } else { 52 + phnum * 32 }).to_uint64()
}

///|
fn le64(values : Array[UInt64]) -> Bytes {
  let w : Writer = { buf: [], big: false, }
  for i, v in values {
    w.put(i * 8, 8, v)
  }
  Bytes::from_array(w.buf)
}

///|
/// An `Elf64_Sym` entry.
fn sym64(
  name : Int32,
  info : Int32,
  other : Int32,
  shndx : Int32,
  value : UInt64,
  size : UInt64,
) -> Bytes {
  let w : Writer = { buf: [], big: false, }
  w.put(0, 4, name.to_uint64())
  w.put(4, 1, info.to_uint64())
  w.put(5, 1, other.to_uint64())
  w.put(6, 2, shndx.to_uint64())
  w.put(8, 8, value)
  w.put(16, 8, size)
  Bytes::from_array(w.buf)
}

///|
fn concat(parts : Array[Bytes]) -> Bytes {
  let buf = []
  for part in parts {
    for b in part {
      buf.push(b)
    }
  }
  Bytes::from_array(buf)
}
