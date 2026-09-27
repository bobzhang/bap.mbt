// The Mach-O loader: the facts of the upstream LLVM loader
// (`lib/bap_llvm/llvm_macho_loader.hpp`) and the image derived from them.

///|
/// The LLVM architecture name of a Mach-O CPU type
/// (`Triple::getArchTypeName(MachOObjectFile::getArch(...))`).
fn macho_llvm_arch(cputype : Int) -> String {
  match cputype {
    @macho.CPU_TYPE_X86 => "i386"
    @macho.CPU_TYPE_X86_64 => "x86_64"
    @macho.CPU_TYPE_ARM => "arm"
    @macho.CPU_TYPE_ARM64 => "aarch64"
    @macho.CPU_TYPE_ARM64_32 => "aarch64_32"
    @macho.CPU_TYPE_POWERPC => "powerpc"
    @macho.CPU_TYPE_POWERPC64 => "powerpc64"
    _ => "unknown"
  }
}

///|
/// The address size of a Mach-O CPU type: 64 for the `CPU_ARCH_ABI64`
/// types, 32 otherwise (`arm64_32` has 32-bit addresses).
fn macho_bits(cputype : Int) -> Int {
  if (cputype & @macho.CPU_ARCH_ABI64) != 0 {
    64
  } else {
    32
  }
}

///|
/// The target of a Mach-O CPU type and subtype.
fn macho_target(
  cputype : Int,
  cpusubtype : Int,
  endian : @bitvec.Endian,
) -> @core_theory.Target {
  let base = match cputype {
    @macho.CPU_TYPE_X86 => @core_theory.Target::x86()
    @macho.CPU_TYPE_X86_64 => @core_theory.Target::x86_64()
    @macho.CPU_TYPE_ARM64 | @macho.CPU_TYPE_ARM64_32 =>
      @core_theory.Target::aarch64()
    @macho.CPU_TYPE_ARM =>
      match cpusubtype & 0x00ffffff {
        9 | 10 | 11 | 12 =>
          image_elf_known_target("armv7", @core_theory.Target::arm())
        14 | 15 | 16 => @core_theory.Target::thumb()
        _ => @core_theory.Target::arm()
      }
    @macho.CPU_TYPE_POWERPC => @core_theory.Target::powerpc()
    @macho.CPU_TYPE_POWERPC64 => @core_theory.Target::powerpc64()
    _ => @core_theory.Target::unknown().with_bits(macho_bits(cputype))
  }
  base
  .with_endianness(image_elf_target_endian(endian))
  .with_filetype(MachO)
  .with_system(Darwin)
}

///|
/// The name of the host architecture of a Mach-O CPU type, as
/// `@native_io.host_architecture` names it.
fn macho_host_arch(cputype : Int) -> String {
  match cputype {
    @macho.CPU_TYPE_X86 => "i386"
    @macho.CPU_TYPE_X86_64 => "x86_64"
    @macho.CPU_TYPE_ARM => "arm"
    @macho.CPU_TYPE_ARM64 => "aarch64"
    @macho.CPU_TYPE_POWERPC => "powerpc"
    @macho.CPU_TYPE_POWERPC64 => "powerpc64"
    _ => "unknown"
  }
}

///|
/// Selects an architecture of a universal binary: the first one of the
/// `target` (if any), otherwise the first one of the host, otherwise the
/// first one.
fn macho_select_arch(
  archs : Array[@macho.FatArch],
  target? : @core_theory.Target,
) -> @macho.FatArch? {
  let target_of = (a : @macho.FatArch) => {
    macho_target(a.cputype, a.cpusubtype, LittleEndian)
  }
  match target {
    Some(t) if !t.is_unknown() =>
      match
        archs.search_by(a => {
          let at = target_of(a)
          at.belongs(t) || t.belongs(at)
        }) {
        Some(i) => return Some(archs[i])
        None => ()
      }
    _ => ()
  }
  let host = @native_io.host_architecture()
  match archs.search_by(a => macho_host_arch(a.cputype) == host) {
    Some(i) => Some(archs[i])
    None => archs.get(0)
  }
}

///|
/// The thin binary of `data`: the selected architecture of a universal
/// Mach-O binary (the one of the `target`, if given and present,
/// otherwise the one of the host, otherwise the first one), or `data`
/// itself.
///
/// Upstream BAP cannot load universal binaries (LLVM's `createBinary`
/// returns a `MachOUniversalBinary`, which is not an object file); the
/// port loads one of their slices.
pub fn thin_binary(
  data : Bytes,
  target? : @core_theory.Target,
) -> Result[Bytes, String] {
  if !@macho.is_fat(data) {
    return Ok(data)
  }
  match @macho.fat_archs(data) {
    Err(reason) => Err(reason)
    Ok(archs) =>
      match macho_select_arch(archs, target?) {
        Some(arch) => @macho.fat_slice(data, arch)
        None => Err("universal binary has no architectures")
      }
  }
}

///|
/// The size of a section as LLVM computes it (`getSectionSize`): zero
/// fill sections keep their size, others are clamped to the file.
fn macho_section_size(data : Bytes, section : @macho.Section) -> UInt64 {
  if section.is_zerofill() {
    return section.size
  }
  let file_size = data.length().to_uint64()
  let off = section.offset.to_uint64()
  if off > file_size {
    0UL
  } else if file_size - off < section.size {
    file_size - off
  } else {
    section.size
  }
}

///|
/// The entry point: the `LC_MAIN` entry, the `LC_UNIXTHREAD` initial
/// program counter, or the lowest address of the sections with pure
/// instructions (upstream `entry_of_commands` and `entry_of_sections`).
///
/// Upstream emits the `entryoff` of `LC_MAIN`, a file offset, as the
/// address of the entry point; the port translates it to the virtual
/// address that the file offset is mapped to. Upstream ignores
/// `LC_UNIXTHREAD`.
fn macho_entry(m : @macho.MachO) -> UInt64? {
  match m.main_entry_offset() {
    Some(off) =>
      return match m.address_of_offset(off) {
        Some(addr) => Some(addr)
        None => Some(off)
      }
    None => ()
  }
  match m.thread_entry() {
    Some(pc) => return Some(pc)
    None => ()
  }
  let mut entry : UInt64? = None
  for section in m.sections() {
    if section.is_text() {
      match entry {
        Some(e) if e <= section.addr => ()
        _ => entry = Some(section.addr)
      }
    }
  }
  entry
}

///|
/// The sizes of the symbols that belong to a section (upstream
/// `get_symbols_sizes`): the distance to the next symbol of the section,
/// or to the end of the section.
fn macho_symbol_sizes(
  data : Bytes,
  sections : Array[@macho.Section],
  symbols : Array[@macho.Nlist],
) -> Array[(@macho.Nlist, UInt64)] {
  let sized = []
  for sym in symbols {
    guard sym.n_sect > 0 && sym.n_sect <= sections.length() else { continue }
    let section = sections[sym.n_sect - 1]
    let end = section.addr + macho_section_size(data, section)
    let addr = sym.n_value
    if end < addr {
      continue
    }
    let mut size = end - addr
    for next in symbols {
      if next.n_sect == sym.n_sect && next.n_value > addr {
        let distance = next.n_value - addr
        if distance < size {
          size = distance
        }
      }
    }
    sized.push((sym, size))
  }
  sized
}

///|
/// The assembler temporary labels: the local symbols named `l...` or
/// `L...` (e.g., the `ltmp0` label that clang puts at the start of the
/// sections of arm64 objects), which name no program entity (C symbols
/// start with `_`); the function at the address of such a label would
/// otherwise have an ambiguous name.
fn macho_is_temporary_label(sym : @macho.Nlist) -> Bool {
  (sym.n_type & 0x01) == 0 &&
  (sym.name.has_prefix("l") || sym.name.has_prefix("L"))
}

///|
fn int64(x : UInt64) -> Int64 {
  x.reinterpret_as_int64()
}

///|
/// The facts of the upstream LLVM loader for a Mach-O file (`load` of
/// `llvm_macho_loader.hpp` after `emit_common_header`).
fn macho_llvm_facts(data : Bytes, m : @macho.MachO) -> Array[@ogre.Ogre[Unit]] {
  let facts = []
  let cputype = m.header.cputype
  // the common header (of `ObjectFile::makeTriple`: only the architecture
  // is known)
  facts.push(@ogre.provide(Scheme::arch(), macho_llvm_arch(cputype)))
  facts.push(@ogre.provide(Scheme::subarch(), ""))
  facts.push(@ogre.provide(Scheme::vendor(), ""))
  facts.push(@ogre.provide(Scheme::system(), ""))
  facts.push(@ogre.provide(Scheme::abi(), "unknown"))
  facts.push(@ogre.provide(Scheme::bits(), macho_bits(cputype).to_int64()))
  facts.push(
    @ogre.provide(Scheme::is_little_endian(), m.header.endian is LittleEndian),
  )
  facts.push(@ogre.provide(Scheme::format(), "macho"))
  facts.push(@ogre.provide(llvm_base_address(), int64(m.image_base())))
  let is_exec = m.is_executable()
  facts.push(@ogre.provide(Scheme::is_executable(), is_exec))
  if is_exec {
    match macho_entry(m) {
      Some(entry) => facts.push(@ogre.provide(llvm_entry_point(), int64(entry)))
      None => ()
    }
  } else {
    facts.push(@ogre.provide(llvm_entry_point(), 0L))
  }
  let sections = m.sections()
  let symbols = @macho.symbols(data, m).unwrap_or([])
  let symbol_name = (index : UInt) => {
    let i = index.reinterpret_as_int()
    if i >= 0 && i < symbols.length() {
      Some(symbols[i])
    } else {
      None
    }
  }
  // the load commands: segments, and the dynamic relocations
  for cmd in m.commands {
    match cmd {
      SegmentCommand(s) => {
        let prot = s.initprot
        facts.push(
          @ogre.provide(
            llvm_segment_command(),
            (s.segname, int64(s.fileoff), int64(s.filesize)),
          ),
        )
        facts.push(
          @ogre.provide(
            llvm_segment_command_flags(),
            (
              s.segname,
              (prot & @macho.VM_PROT_READ) != 0,
              (prot & @macho.VM_PROT_WRITE) != 0,
              (prot & @macho.VM_PROT_EXECUTE) != 0,
            ),
          ),
        )
        facts.push(
          @ogre.provide(
            llvm_virtual_segment_command(),
            (s.segname, int64(s.vmaddr), int64(s.vmsize)),
          ),
        )
      }
      DysymtabCommand(d) => {
        // the symbol stubs and pointers (`emit_indirect_symbols`)
        let indirect = @macho.indirect_symbols(data, m).unwrap_or([])
        for section in sections {
          let stride = if section.typ() == @macho.S_SYMBOL_STUBS {
            section.reserved2.to_uint64()
          } else if m.header.is64 {
            8UL
          } else {
            4UL
          }
          if !section.contains_symbol_stubs() || stride == 0UL {
            continue
          }
          let count = section.size / stride
          let first = section.reserved1.reinterpret_as_int()
          for j = 0
              j.to_uint64() < count &&
             first + j < d.nindirectsyms.reinterpret_as_int() &&
             first + j < indirect.length()
              j = j + 1 {
            match symbol_name(indirect[first + j]) {
              Some(sym) =>
                facts.push(
                  @ogre.provide(
                    llvm_name_reference(),
                    (int64(section.addr + j.to_uint64() * stride), sym.name),
                  ),
                )
              None => ()
            }
          }
        }
        // the external relocations (`emit_dyn_relocations`)
        let base = m.image_base()
        for rel in @macho.external_relocations(data, m).unwrap_or([]) {
          if rel.r_scattered || !rel.r_extern {
            continue
          }
          match symbol_name(rel.r_symbolnum.reinterpret_as_uint()) {
            Some(sym) if m.first_segment() is Some(first) => {
              let at = base + (rel.r_word0.to_uint64() - first.fileoff)
              if sym.n_value != 0UL {
                facts.push(
                  @ogre.provide(
                    llvm_relocation(),
                    (int64(at), int64(sym.n_value)),
                  ),
                )
              }
              facts.push(
                @ogre.provide(llvm_name_reference(), (int64(at), sym.name)),
              )
            }
            _ => ()
          }
        }
      }
      _ => ()
    }
  }
  // the sections (`emit_sections`)
  for section in sections {
    let size = int64(macho_section_size(data, section))
    let off = section.offset.to_int64()
    facts.push(
      @ogre.provide(
        llvm_section_entry(),
        (section.sectname, int64(section.addr), size, off),
      ),
    )
    if section.is_code() {
      facts.push(
        @ogre.provide(llvm_code_entry(), (section.sectname, off, size)),
      )
    }
  }
  // the symbols (`emit_symbols`)
  for entry in macho_symbol_sizes(data, sections, symbols) {
    let (sym, size) = entry
    let section = sections[sym.n_sect - 1]
    if macho_is_temporary_label(sym) {
      continue
    }
    if sym.typ() == @macho.N_SECT {
      let off = if m.header.filetype == @macho.MH_OBJECT {
        sym.n_value + section.offset.to_uint64()
      } else {
        sym.n_value
      }
      facts.push(
        @ogre.provide(
          llvm_symbol_entry(),
          (
            sym.name,
            int64(sym.n_value),
            int64(size),
            int64(off),
            int64(sym.n_value),
          ),
        ),
      )
      // functions are the symbols of text sections (`ST_Function`); a
      // symbol before the start of its section is not code (upstream
      // takes `__mh_execute_header`, which LLVM puts in `__text` but is
      // the address of the Mach-O header, for a function)
      if !sym.is_stab() && section.is_text() && sym.n_value >= section.addr {
        facts.push(
          @ogre.provide(llvm_code_entry(), (sym.name, int64(off), int64(size))),
        )
      }
    } else {
      facts.push(
        @ogre.provide(llvm_macho_symbol(), (sym.name, int64(sym.n_value))),
      )
    }
  }
  // the relocations of the sections (`emit_relocations`)
  for section in sections {
    for rel in @macho.relocations(data, m, section).unwrap_or([]) {
      if rel.r_scattered || !rel.r_extern {
        continue
      }
      match symbol_name(rel.r_symbolnum.reinterpret_as_uint()) {
        Some(sym) => {
          let at = section.addr + rel.r_address.to_uint64()
          if sym.n_value != 0UL {
            facts.push(
              @ogre.provide(llvm_relocation(), (int64(at), int64(sym.n_value))),
            )
          }
          facts.push(
            @ogre.provide(llvm_name_reference(), (int64(at), sym.name)),
          )
        }
        None => ()
      }
    }
  }
  // the libraries (`emit_libraries`)
  for dylib in m.dylibs() {
    facts.push(@ogre.provide(Scheme::require(), dylib.name))
  }
  // the port's extension: the function starts
  for addr in @macho.function_starts(data, m).unwrap_or([]) {
    facts.push(@ogre.provide(llvm_function_start(), int64(addr)))
  }
  facts
}

///|
/// The LLVM loader specification of a thin Mach-O file (the document the
/// upstream `bap_llvm_load` primitive returns).
pub fn macho_llvm_spec(data : Bytes) -> Result[OgreDoc, String] {
  let m = match @macho.parse(data) {
    Ok(m) => m
    Err(reason) => return Err(reason)
  }
  try
    @ogre.exec(
      @ogre.Ogre::all_unit(macho_llvm_facts(data, m)),
      @ogre.Doc::empty(),
    )
  catch {
    error => Err(error.message())
  } noraise {
    doc => Ok(doc)
  }
}

///|
/// The image specification of a Mach-O file: the LLVM loader facts and
/// the image facts translated from them (upstream `llvm` loader
/// `from_data`). A universal binary is loaded as its `thin_binary`.
pub fn macho_spec(
  data : Bytes,
  target? : @core_theory.Target,
) -> Result[OgreDoc, String] {
  let data = match thin_binary(data, target?) {
    Ok(thin) => thin
    Err(reason) => return Err(reason)
  }
  match macho_llvm_spec(data) {
    Err(reason) => Err(reason)
    Ok(doc) =>
      try llvm_translate(doc) catch {
        error => Err(error.message())
      } noraise {
        doc => Ok(doc)
      }
  }
}

///|
/// Adds the code starts without a named symbol (the function starts of
/// the port's `llvm:function-start` facts) as function symbols named
/// `sub_<addr>` (the name BAP gives to unnamed subroutines), sized up to
/// the next code start or symbol; the project uses image symbols as
/// disassembly roots.
fn Image::with_unnamed_code_starts(self : Image, doc : OgreDoc) -> Image {
  let named = self.symbols().map(s => s.addr())
  let starts = spec_values(doc, Scheme::code_start()).filter_map(x => {
    if x < 0L {
      None
    } else {
      Some(x.reinterpret_as_uint64())
    }
  })
  let boundaries = named.copy()
  for s in starts {
    boundaries.push(s)
  }
  let mut image = self
  let seen : Map[UInt64, Unit] = Map([])
  for addr in starts {
    if named.contains(addr) || seen.contains(addr) {
      continue
    }
    seen[addr] = ()
    match
      self.segments().search_by(s => s.contains(addr) && s.is_executable()) {
      None => ()
      Some(i) => {
        let segment = self.segments()[i]
        let mut stop = segment.max_addr() + 1UL
        for section in self.sections() {
          if section.contains(addr) && section.max_addr() + 1UL < stop {
            stop = section.max_addr() + 1UL
          }
        }
        for b in boundaries {
          if b > addr && b < stop {
            stop = b
          }
        }
        image = image.add_symbol(
          Symbol::create(
            name="sub_" + addr.to_string(radix=16),
            addr~,
            size=(stop - addr).to_int(),
            is_function=true,
          ),
        )
      }
    }
  }
  image
}

///|
/// Loads a Mach-O file (or the `thin_binary` of a universal binary):
/// derives the image from its `macho_spec`, with the target of the CPU
/// type, and adds the function starts without symbols as functions.
fn image_macho_load(
  data : Bytes,
  target? : @core_theory.Target,
) -> Result[(Image, Array[String]), String] {
  let data = match thin_binary(data, target?) {
    Ok(thin) => thin
    Err(reason) => return Err(reason)
  }
  let m = match @macho.parse(data) {
    Ok(m) => m
    Err(reason) => return Err(reason)
  }
  match macho_spec(data) {
    Err(reason) => Err(reason)
    Ok(doc) => {
      let target = macho_target(
        m.header.cputype,
        m.header.cpusubtype,
        m.header.endian,
      )
      match Image::from_spec(data, doc, target~) {
        Ok((image, warnings)) =>
          Ok((image.with_unnamed_code_starts(doc), warnings))
        Err(reason) => Err(reason)
      }
    }
  }
}

///|
/// The Mach-O image backend (of the upstream `llvm` loader): thin and
/// universal (fat) Mach-O executables, libraries and objects.
pub fn ImageBackend::macho() -> ImageBackend {
  ImageBackend::create(
    name="macho",
    description="Mach-O executable image (thin or universal)",
    extensions=["macho", "dylib", "bundle", "o"],
    priority=25,
    load=data => image_macho_load(data),
  )
}
