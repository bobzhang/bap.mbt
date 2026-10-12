///|
/// The byte order and width of a thin Mach-O file, if `data` starts with
/// a Mach-O magic number.
fn detect(data : BytesView) -> (@bitvec.Endian, Bool)? {
  if data.length() < 4 {
    return None
  }
  let be = (data[0].to_uint() << 24) |
    (data[1].to_uint() << 16) |
    (data[2].to_uint() << 8) |
    data[3].to_uint()
  match be {
    0xfeedface => Some((BigEndian, false))
    0xfeedfacf => Some((BigEndian, true))
    0xcefaedfe => Some((LittleEndian, false))
    0xcffaedfe => Some((LittleEndian, true))
    _ => None
  }
}

///|
/// Whether `data` is a thin Mach-O file (not a universal binary).
pub fn is_macho(data : BytesView) -> Bool {
  detect(data) is Some(_)
}

///|
fn reader_of(data : Bytes) -> (Reader, Bool) raise Malformed {
  match detect(data) {
    Some((endian, is64)) => ({ data, endian, }, is64)
    None => raise Malformed("not a Mach-O file")
  }
}

///|
fn parse_header(r : Reader, is64 : Bool) -> Header raise Malformed {
  r.check(0, if is64 { 32 } else { 28 }, "Mach-O header")
  {
    is64,
    endian: r.endian,
    cputype: r.u32(4).reinterpret_as_int(),
    cpusubtype: r.u32(8).reinterpret_as_int(),
    filetype: r.u32(12).reinterpret_as_int(),
    ncmds: r.int32(16),
    sizeofcmds: r.int32(20),
    flags: r.u32(24),
  }
}

///|
fn parse_section(
  r : Reader,
  off : Int32,
  is64 : Bool,
) -> Section raise Malformed {
  if is64 {
    {
      sectname: r.fixed_name(off, 16),
      segname: r.fixed_name(off + 16, 16),
      addr: r.u64(off + 32),
      size: r.u64(off + 40),
      offset: r.u32(off + 48),
      align: r.u32(off + 52),
      reloff: r.u32(off + 56),
      nreloc: r.u32(off + 60),
      flags: r.u32(off + 64),
      reserved1: r.u32(off + 68),
      reserved2: r.u32(off + 72),
    }
  } else {
    {
      sectname: r.fixed_name(off, 16),
      segname: r.fixed_name(off + 16, 16),
      addr: r.u32(off + 32).to_uint64(),
      size: r.u32(off + 36).to_uint64(),
      offset: r.u32(off + 40),
      align: r.u32(off + 44),
      reloff: r.u32(off + 48),
      nreloc: r.u32(off + 52),
      flags: r.u32(off + 56),
      reserved1: r.u32(off + 60),
      reserved2: r.u32(off + 64),
    }
  }
}

///|
fn parse_segment(
  r : Reader,
  off : Int32,
  size : Int32,
  is64 : Bool,
) -> Segment raise Malformed {
  let (header_size, section_size) = if is64 { (72, 80) } else { (56, 68) }
  if size < header_size {
    raise Malformed("Mach-O segment command is too small")
  }
  let (vmaddr, vmsize, fileoff, filesize, rest) = if is64 {
    (r.u64(off + 24), r.u64(off + 32), r.u64(off + 40), r.u64(off + 48), 56)
  } else {
    (
      r.u32(off + 24).to_uint64(),
      r.u32(off + 28).to_uint64(),
      r.u32(off + 32).to_uint64(),
      r.u32(off + 36).to_uint64(),
      40,
    )
  }
  let nsects = r.int32(off + rest + 8)
  if nsects > (size - header_size) / section_size {
    raise Malformed("Mach-O segment command has too many sections")
  }
  let sections = []
  for i in 0..<nsects {
    sections.push(parse_section(r, off + header_size + i * section_size, is64))
  }
  {
    segname: r.fixed_name(off + 8, 16),
    vmaddr,
    vmsize,
    fileoff,
    filesize,
    maxprot: r.u32(off + rest).reinterpret_as_int(),
    initprot: r.u32(off + rest + 4).reinterpret_as_int(),
    flags: r.u32(off + rest + 12),
    sections,
  }
}

///|
fn parse_dysymtab(r : Reader, off : Int32) -> Dysymtab raise Malformed {
  let f = (i : Int32) => r.u32(off + 8 + i * 4)
  {
    ilocalsym: f(0),
    nlocalsym: f(1),
    iextdefsym: f(2),
    nextdefsym: f(3),
    iundefsym: f(4),
    nundefsym: f(5),
    tocoff: f(6),
    ntoc: f(7),
    modtaboff: f(8),
    nmodtab: f(9),
    extrefsymoff: f(10),
    nextrefsyms: f(11),
    indirectsymoff: f(12),
    nindirectsyms: f(13),
    extreloff: f(14),
    nextrel: f(15),
    locreloff: f(16),
    nlocrel: f(17),
  }
}

///|
/// A `lc_str` string of a load command: the string at `str_off` from the
/// start of the command, bounded by the command.
fn lc_str(
  r : Reader,
  off : Int32,
  size : Int32,
  str_off : Int32,
) -> String raise Malformed {
  if str_off < 0 || str_off >= size {
    raise Malformed("Mach-O load command string is out of bounds")
  }
  r.cstring(off + str_off, off + size)
}

///|
fn parse_thread_states(
  r : Reader,
  off : Int32,
  size : Int32,
) -> Array[(UInt32, Bytes)] raise Malformed {
  let states = []
  let mut pos = off + 8
  while pos + 8 <= off + size {
    let flavor = r.u32(pos)
    let count = r.int32(pos + 4)
    if count > (off + size - pos - 8) / 4 {
      raise Malformed("Mach-O thread state is out of bounds")
    }
    states.push((flavor, r.data[pos + 8:pos + 8 + count * 4].to_owned()))
    pos = pos + 8 + count * 4
  }
  states
}

///|
fn parse_command(
  r : Reader,
  off : Int32,
  cmd : UInt32,
  size : Int32,
  is64 : Bool,
) -> LoadCommand raise Malformed {
  match cmd {
    LC_SEGMENT | LC_SEGMENT_64 =>
      SegmentCommand(parse_segment(r, off, size, cmd == LC_SEGMENT_64))
    LC_SYMTAB => {
      r.check(off, 24, "Mach-O symtab command")
      SymtabCommand({
        symoff: r.u32(off + 8),
        nsyms: r.u32(off + 12),
        stroff: r.u32(off + 16),
        strsize: r.u32(off + 20),
      })
    }
    LC_DYSYMTAB => {
      r.check(off, 80, "Mach-O dysymtab command")
      DysymtabCommand(parse_dysymtab(r, off))
    }
    LC_MAIN => {
      r.check(off, 24, "Mach-O main command")
      MainCommand(entryoff=r.u64(off + 8), stacksize=r.u64(off + 16))
    }
    LC_THREAD | LC_UNIXTHREAD =>
      ThreadCommand(cmd~, states=parse_thread_states(r, off, size))
    LC_LOAD_DYLIB
    | LC_ID_DYLIB
    | LC_LOAD_WEAK_DYLIB
    | LC_REEXPORT_DYLIB
    | LC_LAZY_LOAD_DYLIB
    | LC_LOAD_UPWARD_DYLIB => {
      r.check(off, 24, "Mach-O dylib command")
      DylibCommand({
        cmd,
        name: lc_str(r, off, size, r.int32(off + 8)),
        timestamp: r.u32(off + 12),
        current_version: r.u32(off + 16),
        compatibility_version: r.u32(off + 20),
      })
    }
    LC_LOAD_DYLINKER => {
      r.check(off, 12, "Mach-O dylinker command")
      DylinkerCommand(lc_str(r, off, size, r.int32(off + 8)))
    }
    LC_UUID => {
      r.check(off, 24, "Mach-O uuid command")
      UuidCommand(r.data[off + 8:off + 24].to_owned())
    }
    LC_FUNCTION_STARTS => {
      r.check(off, 16, "Mach-O function starts command")
      FunctionStartsCommand(dataoff=r.u32(off + 8), datasize=r.u32(off + 12))
    }
    _ => {
      ignore(is64)
      OtherCommand(cmd~, r.data[off + 8:off + size].to_owned())
    }
  }
}

///|
fn parse_exn(data : Bytes) -> MachO raise Malformed {
  let (r, is64) = reader_of(data)
  let header = parse_header(r, is64)
  let mut off = if is64 { 32 } else { 28 }
  let limit = off + header.sizeofcmds
  if limit > data.length() {
    raise Malformed("Mach-O load commands are out of bounds")
  }
  let commands = []
  for _ in 0..<header.ncmds {
    if off + 8 > limit {
      raise Malformed("Mach-O load command is out of bounds")
    }
    let cmd = r.u32(off)
    let size = r.int32(off + 4)
    if size < 8 || off + size > limit {
      raise Malformed("Mach-O load command has an invalid size")
    }
    commands.push(parse_command(r, off, cmd, size, is64))
    off = off + size
  }
  { header, commands, }
}

///|
/// Parses a thin Mach-O file: its header and load commands (upstream
/// `llvm::object::MachOObjectFile`). Universal binaries are parsed with
/// `fat_archs` and their slices extracted with `fat_slice`.
pub fn parse(data : Bytes) -> Result[MachO, String] {
  catch_malformed(() => parse_exn(data))
}

///|
/// The segment commands in the load command order.
pub fn MachO::segments(self : MachO) -> Array[Segment] {
  [
    for cmd in self.commands if cmd is SegmentCommand(s) => s
  ]
}

///|
/// All sections in the load command order; the `n_sect` field of a
/// symbol is a one-based index into this array.
pub fn MachO::sections(self : MachO) -> Array[Section] {
  let sections = []
  for segment in self.segments() {
    for section in segment.sections {
      sections.push(section)
    }
  }
  sections
}

///|
/// The symbol table command, if any.
pub fn MachO::symtab(self : MachO) -> Symtab? {
  for cmd in self.commands {
    if cmd is SymtabCommand(s) {
      return Some(s)
    }
  }
  None
}

///|
/// The dynamic symbol table command, if any.
pub fn MachO::dysymtab(self : MachO) -> Dysymtab? {
  for cmd in self.commands {
    if cmd is DysymtabCommand(s) {
      return Some(s)
    }
  }
  None
}

///|
/// The dynamic libraries commands (`LC_LOAD_DYLIB`, `LC_ID_DYLIB`,
/// `LC_LOAD_WEAK_DYLIB`, `LC_REEXPORT_DYLIB`, `LC_LAZY_LOAD_DYLIB`,
/// `LC_LOAD_UPWARD_DYLIB`) in the load command order.
pub fn MachO::dylibs(self : MachO) -> Array[Dylib] {
  [
    for cmd in self.commands if cmd is DylibCommand(d) => d
  ]
}

///|
/// Whether the file is an executable (`MH_EXECUTE` or `MH_PRELOAD`).
pub fn MachO::is_executable(self : MachO) -> Bool {
  self.header.filetype == MH_EXECUTE || self.header.filetype == MH_PRELOAD
}

///|
/// The first segment that maps the start of the file (upstream
/// `first_segment`): `fileoff = 0` and `filesize <> 0`.
pub fn MachO::first_segment(self : MachO) -> Segment? {
  for segment in self.segments() {
    if segment.fileoff == 0UL && segment.filesize != 0UL {
      return Some(segment)
    }
  }
  None
}

///|
/// The address of the start of the image (upstream `image_base`): the
/// address of the first segment that maps the start of the file, or zero.
pub fn MachO::image_base(self : MachO) -> UInt64 {
  match self.first_segment() {
    Some(segment) => segment.vmaddr
    None => 0UL
  }
}

///|
/// The virtual address of the file offset `off`, if a segment maps it.
pub fn MachO::address_of_offset(self : MachO, off : UInt64) -> UInt64? {
  for segment in self.segments() {
    if segment.filesize != 0UL &&
      segment.fileoff <= off &&
      off - segment.fileoff < segment.filesize {
      return Some(segment.vmaddr + (off - segment.fileoff))
    }
  }
  None
}

///|
/// The `entryoff` of the `LC_MAIN` command: the offset of the entry point
/// from the start of the `__TEXT` segment (and the file).
pub fn MachO::main_entry_offset(self : MachO) -> UInt64? {
  let mut entry = None
  for cmd in self.commands {
    if cmd is MainCommand(entryoff~, ..) {
      entry = Some(entryoff)
    }
  }
  entry
}

///|
fn state_word(
  state : Bytes,
  endian : @bitvec.Endian,
  index : Int32,
  bytes : Int32,
) -> UInt64? {
  let r : Reader = { data: state, endian, }
  try r.uint(index * bytes, bytes) catch {
    _ => None
  } noraise {
    x => Some(x)
  }
}

///|
/// The program counter of an initial thread state of the CPU.
fn thread_pc(
  cputype : Int32,
  endian : @bitvec.Endian,
  flavor : UInt32,
  state : Bytes,
) -> UInt64? {
  match (cputype, flavor) {
    // x86_THREAD_STATE32: eax..esp, ss, eflags, eip
    (CPU_TYPE_X86, 1) => state_word(state, endian, 10, 4)
    // x86_THREAD_STATE64: rax..r15, rip
    (CPU_TYPE_X86_64, 4) => state_word(state, endian, 16, 8)
    // x86_THREAD_STATE: a flavor header followed by the state
    (CPU_TYPE_X86 | CPU_TYPE_X86_64, 7) =>
      match state_word(state, endian, 0, 4) {
        Some(inner) if state.length() > 8 =>
          thread_pc(cputype, endian, inner.to_uint(), state[8:].to_owned())
        _ => None
      }
    // ARM_THREAD_STATE: r0..r12, sp, lr, pc
    (CPU_TYPE_ARM, 1) => state_word(state, endian, 15, 4)
    // ARM_THREAD_STATE64: x0..x28, fp, lr, sp, pc
    (CPU_TYPE_ARM64 | CPU_TYPE_ARM64_32, 6) => state_word(state, endian, 32, 8)
    // PPC_THREAD_STATE / PPC_THREAD_STATE64: srr0 first
    (CPU_TYPE_POWERPC, 1) => state_word(state, endian, 0, 4)
    (CPU_TYPE_POWERPC64, 5) => state_word(state, endian, 0, 8)
    _ => None
  }
}

///|
/// The initial program counter of the `LC_UNIXTHREAD` (or `LC_THREAD`)
/// command, if the thread state flavor is known.
pub fn MachO::thread_entry(self : MachO) -> UInt64? {
  for cmd in self.commands {
    if cmd is ThreadCommand(states~, ..) {
      for state in states {
        match
          thread_pc(self.header.cputype, self.header.endian, state.0, state.1) {
          Some(pc) => return Some(pc)
          None => ()
        }
      }
    }
  }
  None
}

///|
/// The type bits of the section flags (`SECTION_TYPE`).
pub fn Section::typ(self : Section) -> UInt32 {
  self.flags & SECTION_TYPE
}

///|
/// Whether the section contains instructions (upstream `is_code_section`:
/// `S_ATTR_PURE_INSTRUCTIONS` or `S_ATTR_SOME_INSTRUCTIONS`).
pub fn Section::is_code(self : Section) -> Bool {
  (self.flags & (S_ATTR_PURE_INSTRUCTIONS | S_ATTR_SOME_INSTRUCTIONS)) != 0
}

///|
/// Whether the section contains only instructions
/// (`S_ATTR_PURE_INSTRUCTIONS`), i.e. is a text section for LLVM.
pub fn Section::is_text(self : Section) -> Bool {
  (self.flags & S_ATTR_PURE_INSTRUCTIONS) != 0
}

///|
/// Whether the section occupies no file space (`S_ZEROFILL`,
/// `S_GB_ZEROFILL`).
pub fn Section::is_zerofill(self : Section) -> Bool {
  let typ = self.typ()
  typ == S_ZEROFILL || typ == S_GB_ZEROFILL
}

///|
/// Whether the section holds symbol stubs or symbol pointers, whose
/// entries are described by the indirect symbol table (upstream
/// `contains_sym_stubs`).
pub fn Section::contains_symbol_stubs(self : Section) -> Bool {
  match self.typ() {
    S_NON_LAZY_SYMBOL_POINTERS
    | S_LAZY_SYMBOL_POINTERS
    | S_LAZY_DYLIB_SYMBOL_POINTERS
    | S_THREAD_LOCAL_VARIABLE_POINTERS
    | S_SYMBOL_STUBS => true
    _ => false
  }
}

///|
/// Whether the symbol is a debugging (stab) entry.
pub fn Nlist::is_stab(self : Nlist) -> Bool {
  (self.n_type & N_STAB) != 0
}

///|
/// The type bits of `n_type` (`N_TYPE`): `N_UNDF`, `N_ABS`, `N_SECT`, ...
pub fn Nlist::typ(self : Nlist) -> Int32 {
  self.n_type & N_TYPE
}

///|
/// Whether the symbol is external (`N_EXT`).
pub fn Nlist::is_external(self : Nlist) -> Bool {
  (self.n_type & N_EXT) != 0
}

///|
fn symbols_exn(data : Bytes, macho : MachO) -> Array[Nlist] raise Malformed {
  let r : Reader = { data, endian: macho.header.endian, }
  guard macho.symtab() is Some(symtab) else { return [] }
  let entry_size = if macho.header.is64 { 16 } else { 12 }
  let nsyms = symtab.nsyms.reinterpret_as_int()
  let symoff = symtab.symoff.reinterpret_as_int()
  if nsyms < 0 || symoff < 0 || nsyms > (data.length() - symoff) / entry_size {
    raise Malformed("Mach-O symbol table is out of bounds")
  }
  let stroff = symtab.stroff.reinterpret_as_int()
  let strsize = symtab.strsize.reinterpret_as_int()
  if stroff < 0 || strsize < 0 || stroff > data.length() - strsize {
    raise Malformed("Mach-O string table is out of bounds")
  }
  let symbols = []
  for i in 0..<nsyms {
    let off = symoff + i * entry_size
    let strx = r.u32(off).reinterpret_as_int()
    let name = if strx <= 0 || strx >= strsize {
      ""
    } else {
      r.cstring(stroff + strx, stroff + strsize)
    }
    symbols.push({
      index: i,
      name,
      n_type: r.u8(off + 4),
      n_sect: r.u8(off + 5),
      n_desc: r.u16(off + 6),
      n_value: if macho.header.is64 {
        r.u64(off + 8)
      } else {
        r.u32(off + 8).to_uint64()
      },
    })
  }
  symbols
}

///|
/// The entries of the symbol table (`LC_SYMTAB`) with their names; an
/// entry with an invalid string index has an empty name.
pub fn symbols(data : Bytes, macho : MachO) -> Result[Array[Nlist], String] {
  catch_malformed(() => symbols_exn(data, macho))
}

///|
fn parse_relocation(
  r : Reader,
  off : Int32,
  is64 : Bool,
) -> Relocation raise Malformed {
  let w0 = r.u32(off)
  let w1 = r.u32(off + 4)
  let scattered = !is64 && (w0 & 0x80000000) != 0
  match r.endian {
    LittleEndian =>
      {
        r_word0: w0,
        r_word1: w1,
        r_address: w0.reinterpret_as_int(),
        r_symbolnum: (w1 & 0xffffff).reinterpret_as_int(),
        r_pcrel: ((w1 >> 24) & 1) != 0,
        r_length: ((w1 >> 25) & 3).reinterpret_as_int(),
        r_extern: ((w1 >> 27) & 1) != 0,
        r_type: (w1 >> 28).reinterpret_as_int(),
        r_scattered: scattered,
      }
    BigEndian =>
      {
        r_word0: w0,
        r_word1: w1,
        r_address: w0.reinterpret_as_int(),
        r_symbolnum: (w1 >> 8).reinterpret_as_int(),
        r_pcrel: ((w1 >> 7) & 1) != 0,
        r_length: ((w1 >> 5) & 3).reinterpret_as_int(),
        r_extern: ((w1 >> 4) & 1) != 0,
        r_type: (w1 & 0xf).reinterpret_as_int(),
        r_scattered: scattered,
      }
  }
}

///|
fn relocation_table(
  data : Bytes,
  macho : MachO,
  offset : UInt32,
  count : UInt32,
) -> Array[Relocation] raise Malformed {
  let r : Reader = { data, endian: macho.header.endian, }
  let off = offset.reinterpret_as_int()
  let n = count.reinterpret_as_int()
  if n == 0 {
    return []
  }
  if off < 0 || n < 0 || n > (data.length() - off) / 8 {
    raise Malformed("Mach-O relocation table is out of bounds")
  }
  [
    for i in 0..<n => parse_relocation(r, off + i * 8, macho.header.is64)
  ]
}

///|
/// The relocation entries of a section (`reloff`, `nreloc`).
pub fn relocations(
  data : Bytes,
  macho : MachO,
  section : Section,
) -> Result[Array[Relocation], String] {
  catch_malformed(() => {
    relocation_table(data, macho, section.reloff, section.nreloc)
  })
}

///|
/// The external relocation entries of the dynamic symbol table
/// (`extreloff`, `nextrel`).
pub fn external_relocations(
  data : Bytes,
  macho : MachO,
) -> Result[Array[Relocation], String] {
  catch_malformed(() => {
    match macho.dysymtab() {
      Some(d) => relocation_table(data, macho, d.extreloff, d.nextrel)
      None => []
    }
  })
}

///|
/// The indirect symbol table of the dynamic symbol table: symbol table
/// indices, or `INDIRECT_SYMBOL_LOCAL` / `INDIRECT_SYMBOL_ABS` markers.
pub fn indirect_symbols(
  data : Bytes,
  macho : MachO,
) -> Result[Array[UInt32], String] {
  catch_malformed(() => {
    guard macho.dysymtab() is Some(d) else { return [] }
    let r : Reader = { data, endian: macho.header.endian, }
    let off = d.indirectsymoff.reinterpret_as_int()
    let n = d.nindirectsyms.reinterpret_as_int()
    if n == 0 {
      return []
    }
    if off < 0 || n < 0 || n > (data.length() - off) / 4 {
      raise Malformed("Mach-O indirect symbol table is out of bounds")
    }
    [
      for i in 0..<n => r.u32(off + i * 4)
    ]
  })
}

///|
/// The start addresses of the functions (`LC_FUNCTION_STARTS`): ULEB128
/// deltas, the first one from the start of the `__TEXT` segment,
/// terminated by a zero delta.
pub fn function_starts(
  data : Bytes,
  macho : MachO,
) -> Result[Array[UInt64], String] {
  catch_malformed(() => {
    let mut command = None
    for cmd in macho.commands {
      if cmd is FunctionStartsCommand(dataoff~, datasize~) {
        command = Some((dataoff, datasize))
      }
    }
    guard command is Some((dataoff, datasize)) else { return [] }
    let off = dataoff.reinterpret_as_int()
    let size = datasize.reinterpret_as_int()
    if off < 0 || size < 0 || off > data.length() - size {
      raise Malformed("Mach-O function starts are out of bounds")
    }
    let text = macho.segments().search_by(s => s.segname == "__TEXT")
    let mut addr = match text {
      Some(i) => macho.segments()[i].vmaddr
      None => macho.image_base()
    }
    let starts = []
    let mut pos = off
    while pos < off + size {
      let mut delta = 0UL
      let mut shift = 0
      while pos < off + size {
        let byte = data[pos]
        pos = pos + 1
        if shift < 64 {
          delta = delta | ((byte.to_uint64() & 0x7fUL) << shift)
        }
        shift = shift + 7
        if (byte.to_int() & 0x80) == 0 {
          break
        }
      }
      if delta == 0UL {
        break
      }
      addr = addr + delta
      starts.push(addr)
    }
    starts
  })
}
