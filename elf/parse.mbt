///|
/// A malformed ELF input; public entry points report it as `Err(message)`.
priv suberror Malformed {
  Malformed(String)
}

///|
fn[T] catch_malformed(f : () -> T raise Malformed) -> Result[T, String] {
  try f() catch {
    Malformed(reason) => Err(reason)
  } noraise {
    x => Ok(x)
  }
}

///|
/// A little reader over the ELF file bytes `data[pos:pos + len]`: every
/// offset is relative to the start of the file.
priv struct Reader {
  data : Bytes
  pos : Int
  len : Int
  endian : @bitvec.Endian
}

///|
fn Reader::uint(
  self : Reader,
  offset : UInt64,
  bytes : Int,
) -> UInt64 raise Malformed {
  if offset > self.len.to_uint64() ||
    bytes.to_uint64() > self.len.to_uint64() - offset {
    raise Malformed("truncated ELF input")
  }
  let base = self.pos + offset.to_int()
  let mut value = 0UL
  for i in 0..<bytes {
    let shift = match self.endian {
      LittleEndian => i * 8
      BigEndian => (bytes - 1 - i) * 8
    }
    value = value | (self.data[base + i].to_uint64() << shift)
  }
  value
}

///|
/// Reads a field at `off32` (`bytes32` wide) in ELF32 entries and at `off64`
/// (`bytes64` wide) in ELF64 entries.
fn Reader::field(
  self : Reader,
  class : EClass,
  base : UInt64,
  off32 : Int,
  off64 : Int,
  bytes32? : Int = 4,
  bytes64? : Int = 8,
) -> UInt64 raise Malformed {
  match class {
    ELFCLASS32 => self.uint(base + off32.to_uint64(), bytes32)
    ELFCLASS64 => self.uint(base + off64.to_uint64(), bytes64)
  }
}

///|
/// The size of the file header of a class.
pub fn EClass::header_size(self : EClass) -> Int {
  match self {
    ELFCLASS32 => 52
    ELFCLASS64 => 64
  }
}

///|
/// The size of a program header of a class.
pub fn EClass::program_header_size(self : EClass) -> Int {
  match self {
    ELFCLASS32 => 32
    ELFCLASS64 => 56
  }
}

///|
/// The size of a section header of a class.
pub fn EClass::section_header_size(self : EClass) -> Int {
  match self {
    ELFCLASS32 => 40
    ELFCLASS64 => 64
  }
}

///|
/// Checks that a header table fits in the file (upstream
/// `validate_offsets`); empty tables are always valid.
fn Reader::check_table(
  self : Reader,
  table : TableInfo,
  name : String,
) -> Unit raise Malformed {
  if table.entry_num == 0 {
    return
  }
  let size = table.entry_size.to_uint64() * table.entry_num.to_uint64()
  let len = self.len.to_uint64()
  if table.table_offset > len || size > len - table.table_offset {
    raise Malformed("\{name} is out of bounds")
  }
}

///|
/// Parses the program header at `base` (upstream `parse_segment`).
fn Reader::segment(
  self : Reader,
  class : EClass,
  base : UInt64,
) -> Segment raise Malformed {
  {
    p_type: PType::of_int(self.field(class, base, 0, 0, bytes64=4).to_uint()),
    p_flags: PFlag::of_bits(self.field(class, base, 24, 4, bytes64=4).to_uint()),
    p_offset: self.field(class, base, 4, 8),
    p_vaddr: self.field(class, base, 8, 16),
    p_paddr: self.field(class, base, 12, 24),
    p_filesz: self.field(class, base, 16, 32),
    p_memsz: self.field(class, base, 20, 40),
    p_align: self.field(class, base, 28, 48),
  }
}

///|
/// Parses the section header at `base` (upstream `parse_section`).
fn Reader::section(
  self : Reader,
  class : EClass,
  base : UInt64,
) -> Section raise Malformed {
  let width = match class {
    ELFCLASS32 => 32
    ELFCLASS64 => 64
  }
  {
    sh_name: self.field(class, base, 0, 0, bytes64=4).to_uint(),
    sh_type: ShType::of_int(self.field(class, base, 4, 4, bytes64=4).to_uint()),
    sh_flags: ShFlag::of_bits(self.field(class, base, 8, 8), width~),
    sh_addr: self.field(class, base, 12, 16),
    sh_offset: self.field(class, base, 16, 24),
    sh_size: self.field(class, base, 20, 32),
    sh_link: self.field(class, base, 24, 40, bytes64=4).to_uint(),
    sh_info: self.field(class, base, 28, 44, bytes64=4).to_uint(),
    sh_addralign: self.field(class, base, 32, 48),
    sh_entsize: self.field(class, base, 36, 56),
  }
}

///|
fn[T] Reader::table(
  _self : Reader,
  table : TableInfo,
  parse : (UInt64) -> T raise Malformed,
) -> Array[T] raise Malformed {
  Array::makei(table.entry_num, i => {
    parse(table.table_offset + i.to_uint64() * table.entry_size.to_uint64())
  })
}

///|
fn parse_elf(data : Bytes, pos : Int, len : Int?) -> Elf raise Malformed {
  if pos < 0 || pos > data.length() {
    raise Malformed("ELF data position is out of bounds")
  }
  let len = match len {
    Some(len) => len
    None => data.length() - pos
  }
  if len < 0 || len > data.length() - pos {
    raise Malformed("ELF data length is out of bounds")
  }
  if len < 16 {
    raise Malformed("truncated ELF header")
  }
  if data[pos] != b'\x7f' ||
    data[pos + 1] != b'E' ||
    data[pos + 2] != b'L' ||
    data[pos + 3] != b'F' {
    raise Malformed("not an ELF file")
  }
  let e_class = match data[pos + 4].to_int() {
    1 => ELFCLASS32
    2 => ELFCLASS64
    other => raise Malformed("unsupported ELF class: \{other}")
  }
  let e_data = match data[pos + 5].to_int() {
    1 => ELFDATA2LSB
    2 => ELFDATA2MSB
    other => raise Malformed("unsupported ELF data encoding: \{other}")
  }
  if len < e_class.header_size() {
    raise Malformed("truncated ELF header")
  }
  let r : Reader = { data, pos, len, endian: e_data.endian(), }
  let half = (off32 : Int, off64 : Int) => {
    r.field(e_class, 0, off32, off64, bytes32=2, bytes64=2).to_int() & 0xffff
  }
  let e_phoff = r.field(e_class, 0, 28, 32)
  let e_shoff = r.field(e_class, 0, 32, 40)
  let e_phentsize = half(42, 54)
  let e_phnum = half(44, 56)
  let e_shentsize = half(46, 58)
  let e_shnum = half(48, 60)
  let e_shstrndx = half(50, 62)
  // extended numbering is stored in the section header 0
  let zero = if (e_phnum == 0xffff || e_shnum == 0 || e_shstrndx == 0xffff) &&
    e_shoff != 0UL {
    if e_shentsize < e_class.section_header_size() {
      raise Malformed("ELF section headers are too small")
    }
    r.check_table(
      { table_offset: e_shoff, entry_size: e_shentsize, entry_num: 1, },
      "ELF section table",
    )
    Some(r.section(e_class, e_shoff))
  } else {
    None
  }
  let shnum = match (e_shnum, zero) {
    (0, Some(zero)) =>
      if zero.sh_size > 0x7fffffffUL {
        raise Malformed("ELF extended section count is too large")
      } else {
        zero.sh_size.to_int()
      }
    _ => e_shnum
  }
  let phnum = match (e_phnum, zero) {
    (0xffff, Some(zero)) => zero.sh_info.reinterpret_as_int()
    (0xffff, None) => raise Malformed("extended ELF program table is missing")
    _ => e_phnum
  }
  let shstrndx = match (e_shstrndx, zero) {
    (0xffff, Some(zero)) => zero.sh_link.reinterpret_as_int()
    (0xffff, None) => raise Malformed("extended ELF section table is missing")
    _ => e_shstrndx
  }
  if phnum < 0 || shstrndx < 0 {
    raise Malformed("ELF extended numbering is invalid")
  }
  let e_phtab = {
    table_offset: e_phoff,
    entry_size: e_phentsize,
    entry_num: phnum,
  }
  let e_shtab = {
    table_offset: e_shoff,
    entry_size: e_shentsize,
    entry_num: shnum,
  }
  if phnum > 0 && e_phentsize < e_class.program_header_size() {
    raise Malformed("ELF program headers are too small")
  }
  if shnum > 0 && e_shentsize < e_class.section_header_size() {
    raise Malformed("ELF section headers are too small")
  }
  r.check_table(e_phtab, "ELF program table")
  r.check_table(e_shtab, "ELF section table")
  {
    e_class,
    e_data,
    e_version: data[pos + 6].to_int(),
    e_osabi: EOsabi::of_int(data[pos + 7].to_int()),
    e_abiver: data[pos + 8].to_int(),
    e_type: EType::of_int(half(16, 16)),
    e_machine: EMachine::of_int(half(18, 18)),
    e_entry: r.field(e_class, 0, 24, 24),
    e_shstrndx: shstrndx,
    e_sections: r.table(e_shtab, base => r.section(e_class, base)),
    e_segments: r.table(e_phtab, base => r.segment(e_class, base)),
    e_file_version: r.field(e_class, 0, 20, 20, bytes64=4).to_uint(),
    e_flags: r.field(e_class, 0, 36, 48, bytes64=4).to_uint(),
    e_ehsize: half(40, 52),
    e_phtab,
    e_shtab,
  }
}

///|
/// Parses an ELF file (upstream `Elf.from_bigstring`).
///
/// The file is `data[pos:pos + len]` (by default all of `data` from
/// `pos`), and every file offset is relative to `pos`. The reader is not
/// restricted to loadable images: relocatable objects, core files, shared
/// objects and files without program or section header tables parse as
/// well, and values without a named constructor are preserved (`EM_EXT`,
/// `ET_EXT`, ...). Parsing fails only when the identification is not an
/// ELF one, the class or data encoding is unknown, the header is
/// truncated, or a non-empty header table doesn't fit in the file or has
/// too small entries.
///
/// ```mbt check
/// test {
///   let header = Bytes::from_array(
///     Array::makei(64, i => {
///       match i {
///         0 => b'\x7f'
///         1 => b'E'
///         2 => b'L'
///         3 => b'F'
///         4 => b'\x02'
///         5 | 6 | 16 => b'\x01'
///         18 => b'\x3e'
///         _ => b'\x00'
///       }
///     }),
///   )
///   let elf = @elf.from_bytes(header).unwrap()
///   debug_inspect(elf.e_type, content="ET_REL")
///   debug_inspect(elf.e_machine, content="EM_X86_64")
///   assert_true(elf.e_sections.is_empty() && elf.e_segments.is_empty())
/// }
/// ```
pub fn from_bytes(
  data : Bytes,
  pos? : Int = 0,
  len? : Int,
) -> Result[Elf, String] {
  catch_malformed(() => parse_elf(data, pos, len))
}

///|
/// Parses an ELF file (upstream name of `from_bytes`).
pub fn from_bigstring(
  data : Bytes,
  pos? : Int = 0,
  len? : Int,
) -> Result[Elf, String] {
  from_bytes(data, pos~, len?)
}
