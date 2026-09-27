// The PE/COFF loader: the facts of the upstream LLVM loader
// (`lib/bap_llvm/llvm_coff_loader.hpp`) and the image derived from them.

///|
/// The LLVM triple parts (architecture, subarchitecture, vendor) of a
/// COFF machine (`COFFObjectFile::getArch` and `ObjectFile::makeTriple`,
/// which makes ARMNT files `thumbv7-windows`).
fn coff_llvm_triple(machine : Int) -> (String, String, String) {
  match machine {
    @coff.IMAGE_FILE_MACHINE_I386 => ("i386", "", "")
    @coff.IMAGE_FILE_MACHINE_AMD64 => ("x86_64", "", "")
    @coff.IMAGE_FILE_MACHINE_ARMNT => ("thumb", "v7", "windows")
    @coff.IMAGE_FILE_MACHINE_ARM64 => ("aarch64", "", "")
    _ => ("unknown", "", "")
  }
}

///|
/// The target of a COFF machine.
fn coff_target(c : @coff.Coff) -> @core_theory.Target {
  let base = match c.header.machine {
    @coff.IMAGE_FILE_MACHINE_I386 => @core_theory.Target::x86()
    @coff.IMAGE_FILE_MACHINE_AMD64 => @core_theory.Target::x86_64()
    @coff.IMAGE_FILE_MACHINE_ARMNT | @coff.IMAGE_FILE_MACHINE_THUMB =>
      @core_theory.Target::thumb()
    @coff.IMAGE_FILE_MACHINE_ARM => @core_theory.Target::arm()
    @coff.IMAGE_FILE_MACHINE_ARM64 => @core_theory.Target::aarch64()
    _ => @core_theory.Target::unknown().with_bits(c.bytes_in_address() * 8)
  }
  base.with_endianness(LittleEndian).with_filetype(COFF).with_system(Windows)
}

///|
/// The address of a section (`getSectionAddress`: the RVA plus the image
/// base).
fn coff_section_address(c : @coff.Coff, s : @coff.SectionHeader) -> UInt64 {
  s.virtual_address.to_uint64() + c.image_base()
}

///|
/// The size of a section (`getSectionSize`): the smaller of the virtual
/// and the raw sizes in images, the raw size in objects.
fn coff_section_size(c : @coff.Coff, s : @coff.SectionHeader) -> UInt64 {
  if c.pe_offset is Some(_) {
    (if s.virtual_size < s.size_of_raw_data {
      s.virtual_size
    } else {
      s.size_of_raw_data
    }).to_uint64()
  } else {
    s.size_of_raw_data.to_uint64()
  }
}

///|
/// Whether a section contains code (`is_code_section`).
fn coff_is_code(s : @coff.SectionHeader) -> Bool {
  (s.characteristics & (@coff.IMAGE_SCN_MEM_EXECUTE | @coff.IMAGE_SCN_CNT_CODE)) !=
  0
}

///|
/// The section of a symbol, if it is defined in one.
fn coff_symbol_section(
  c : @coff.Coff,
  sym : @coff.Symbol,
) -> @coff.SectionHeader? {
  if sym.section_number > 0 {
    c.sections.get(sym.section_number - 1)
  } else {
    None
  }
}

///|
/// The address of a symbol (`getSymbolAddress`): the value, plus the
/// section address for symbols defined in a section.
fn coff_symbol_address(c : @coff.Coff, sym : @coff.Symbol) -> UInt64 {
  match coff_symbol_section(c, sym) {
    Some(s) => sym.value.to_uint64() + coff_section_address(c, s)
    None => sym.value.to_uint64()
  }
}

///|
/// The LLVM loader facts of the exported functions
/// (`emit_exported_symbols`): sorted by address, each one extends to the
/// next one of its section or to the end of the section.
///
/// Upstream pairs the export address table entry `i` with the name whose
/// ordinal is `i` for `i` below the number of names; the port pairs every
/// named entry, and skips the forwarded exports (which are not code).
fn coff_export_facts(
  data : Bytes,
  c : @coff.Coff,
  facts : Array[@ogre.Ogre[Unit]],
) -> Unit {
  let exports = match @coff.exports(data, c) {
    Ok(Some(e)) => e.exports
    _ => return
  }
  let syms = []
  for e in exports {
    match (e.name, e.forwarder) {
      (Some(name), None) => syms.push((e.rva, name))
      _ => ()
    }
  }
  syms.sort_by((x, y) => x.0.compare(y.0))
  let base = c.image_base()
  for i, sym in syms {
    guard c.section_of_rva(sym.0) is Some(s) else { continue }
    let section_end = s.virtual_address + s.virtual_size
    let size = match syms.get(i + 1) {
      Some(next) if c.section_of_rva(next.0) == Some(s) => next.0 - sym.0
      _ => section_end - sym.0
    }
    let off = s.pointer_to_raw_data + sym.0 - s.virtual_address
    let addr = sym.0.to_uint64() + base
    facts.push(
      @ogre.provide(
        llvm_symbol_entry(),
        (sym.1, int64(addr), size.to_int64(), off.to_int64(), 0L),
      ),
    )
    facts.push(
      @ogre.provide(llvm_code_entry(), (sym.1, off.to_int64(), size.to_int64())),
    )
  }
}

///|
/// The facts of the upstream LLVM loader for a PE/COFF file (`load` of
/// `llvm_coff_loader.hpp` after `emit_common_header`).
fn coff_llvm_facts(data : Bytes, c : @coff.Coff) -> Array[@ogre.Ogre[Unit]] {
  let facts = []
  let (arch, subarch, vendor) = coff_llvm_triple(c.header.machine)
  let bits = match arch {
    "x86_64" | "aarch64" => 64
    "i386" | "thumb" => 32
    _ => c.bytes_in_address() * 8
  }
  facts.push(@ogre.provide(Scheme::arch(), arch))
  facts.push(@ogre.provide(Scheme::subarch(), subarch))
  facts.push(@ogre.provide(Scheme::vendor(), vendor))
  facts.push(@ogre.provide(Scheme::system(), ""))
  facts.push(@ogre.provide(Scheme::abi(), "unknown"))
  facts.push(@ogre.provide(Scheme::bits(), bits.to_int64()))
  facts.push(@ogre.provide(Scheme::is_little_endian(), true))
  facts.push(@ogre.provide(Scheme::format(), "coff"))
  facts.push(@ogre.provide(Scheme::is_executable(), c.is_executable()))
  let base = c.image_base()
  facts.push(@ogre.provide(llvm_base_address(), int64(base)))
  // the entry point (`emit_entry_point`)
  // (the header is read as PE32 or PE32+ by the address size of the
  // architecture; a mismatch leaves the entry point zero)
  let entry = match c.optional_header {
    Some(h) if (h.magic == @coff.IMAGE_NT_OPTIONAL_HDR64_MAGIC) == (bits == 64) =>
      h.address_of_entry_point.to_uint64()
    _ => 0UL
  }
  facts.push(@ogre.provide(llvm_entry_point(), int64(entry + base)))
  // the sections (`emit_sections`)
  let is_rel = c.is_relocatable()
  for s in c.sections {
    let r = (s.characteristics & @coff.IMAGE_SCN_MEM_READ) != 0
    let w = (s.characteristics & @coff.IMAGE_SCN_MEM_WRITE) != 0
    let x = coff_is_code(s)
    let vaddr = int64(coff_section_address(c, s))
    let vsize = (if is_rel { s.size_of_raw_data } else { s.virtual_size }).to_int64()
    let fsize = s.size_of_raw_data.to_int64()
    let off = s.pointer_to_raw_data.to_int64()
    // non-executable sections of objects all have the same address
    if !is_rel || x {
      facts.push(
        @ogre.provide(llvm_section_entry(), (s.name, vaddr, fsize, off)),
      )
      facts.push(
        @ogre.provide(
          llvm_coff_virtual_section_header(),
          (s.name, vaddr, vsize),
        ),
      )
      facts.push(@ogre.provide(llvm_section_flags(), (s.name, r, w, x)))
      if x {
        facts.push(@ogre.provide(llvm_code_entry(), (s.name, off, fsize)))
      }
    }
  }
  // the symbols (`emit_symbols`), sized as `get_symbols_sizes` does
  let symbols = @coff.symbols(data, c).unwrap_or([])
  for sym in symbols {
    guard coff_symbol_section(c, sym) is Some(s) else { continue }
    // section symbols name no program entity; the symbols of the
    // non-executable sections of objects, which are not mapped, would
    // alias the addresses of the code
    if coff_is_section_definition(sym) || (is_rel && !coff_is_code(s)) {
      continue
    }
    let addr = coff_symbol_address(c, sym)
    let end = coff_section_address(c, s) + coff_section_size(c, s)
    if end < addr {
      continue
    }
    let mut size = end - addr
    for next in symbols {
      if next.section_number == sym.section_number {
        let next_addr = coff_symbol_address(c, next)
        if next_addr > addr && next_addr - addr < size {
          size = next_addr - addr
        }
      }
    }
    let off = (s.pointer_to_raw_data + sym.value).to_int64()
    facts.push(
      @ogre.provide(
        llvm_symbol_entry(),
        (sym.name, int64(addr), int64(size), off, sym.value.to_int64()),
      ),
    )
    if sym.is_function_definition() {
      facts.push(@ogre.provide(llvm_code_entry(), (sym.name, off, int64(size))))
    }
  }
  // the relocations of the sections (`emit_relocations`); as the
  // non-executable sections of objects are not mapped (they would all be
  // at the same address), their relocations would alias the addresses of
  // the code and are omitted
  for s in c.sections {
    if is_rel && !coff_is_code(s) {
      continue
    }
    for rel in @coff.relocations(data, c, s).unwrap_or([]) {
      match
        symbols.search_by(sym => {
          sym.index == rel.symbol_table_index.reinterpret_as_int()
        }) {
        Some(i) => {
          let sym = symbols[i]
          if coff_is_section_definition(sym) {
            continue
          }
          let at = int64(
            rel.virtual_address.to_uint64() + coff_section_address(c, s),
          )
          let addr = coff_symbol_address(c, sym)
          if addr != 0UL {
            facts.push(@ogre.provide(llvm_relocation(), (at, int64(addr))))
          }
          facts.push(@ogre.provide(llvm_name_reference(), (at, sym.name)))
        }
        None => ()
      }
    }
  }
  coff_export_facts(data, c, facts)
  // the imported libraries (`emit_import_directories`) and, an extension
  // of the port, the import address table slots of the imported functions
  for imp in @coff.imports(data, c).unwrap_or([]) {
    facts.push(@ogre.provide(Scheme::require(), imp.dll))
    for entry in imp.entries {
      match entry.name {
        Some(name) =>
          facts.push(
            @ogre.provide(
              llvm_name_reference(),
              (int64(entry.iat_rva.to_uint64() + base), name),
            ),
          )
        None => ()
      }
    }
  }
  facts
}

///|
/// The LLVM loader specification of a PE/COFF file (the document the
/// upstream `bap_llvm_load` primitive returns, without the PDB facts).
pub fn coff_llvm_spec(data : Bytes) -> Result[OgreDoc, String] {
  let c = match @coff.parse(data) {
    Ok(c) => c
    Err(reason) => return Err(reason)
  }
  try
    @ogre.exec(
      @ogre.Ogre::all_unit(coff_llvm_facts(data, c)),
      @ogre.Doc::empty(),
    )
  catch {
    error => Err(error.message())
  } noraise {
    doc => Ok(doc)
  }
}

///|
/// The image specification of a PE/COFF file: the LLVM loader facts and
/// the image facts translated from them (upstream `llvm` loader
/// `from_data`).
pub fn coff_spec(data : Bytes) -> Result[OgreDoc, String] {
  match coff_llvm_spec(data) {
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
/// Loads a PE/COFF file: derives the image from its `coff_spec` with the
/// target of its machine.
fn image_coff_load(data : Bytes) -> Result[(Image, Array[String]), String] {
  let c = match @coff.parse(data) {
    Ok(c) => c
    Err(reason) => return Err(reason)
  }
  match coff_spec(data) {
    Err(reason) => Err(reason)
    Ok(doc) => Image::from_spec(data, doc, target=coff_target(c))
  }
}

///|
/// The PE/COFF image backend (of the upstream `llvm` loader): PE32 and
/// PE32+ executables and libraries, and COFF objects.
pub fn ImageBackend::coff() -> ImageBackend {
  ImageBackend::create(
    name="coff",
    description="PE/COFF executable image",
    extensions=["exe", "dll", "sys", "efi", "obj", "coff", "pe"],
    priority=25,
    load=image_coff_load,
  )
}

///|
/// Whether the symbol defines a section (LLVM `isSectionDefinition`: a
/// static or absolute external symbol followed by the auxiliary section
/// definition record), e.g., the `.text` symbol of an object. LLVM reports
/// such symbols as debug symbols (`ST_Debug`); they name no program entity,
/// and the function at the start of the section would otherwise have an
/// ambiguous name.
fn coff_is_section_definition(sym : @coff.Symbol) -> Bool {
  sym.number_of_aux_symbols > 0 &&
  (
    sym.storage_class == 3 ||
    (sym.storage_class == 2 && sym.section_number == -1)
  )
}
