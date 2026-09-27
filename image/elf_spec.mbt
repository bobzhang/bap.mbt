///|
/// `(llvm:entry-point addr)`: the entry point of the file.
fn llvm_entry_point() -> @ogre.Attribute[Int64, Int64] {
  int_attribute("llvm:entry-point", Scheme::addr())
}

///|
/// `(llvm:elf-program-header name off size)`: a program header as it is in
/// the file.
fn llvm_elf_program_header() -> @ogre.Attribute[
  (String, Int64, Int64),
  (String, Int64, Int64),
] {
  @ogre.Attribute::new(
    name="llvm:elf-program-header",
    @ogre.scheme3(Scheme::name(), Scheme::off(), Scheme::size()),
    t => t,
  )
}

///|
/// `(llvm:elf-virtual-program-header name addr size)`: a program header as
/// it is in memory.
fn llvm_elf_virtual_program_header() -> @ogre.Attribute[
  (String, Int64, Int64),
  (String, Int64, Int64),
] {
  @ogre.Attribute::new(
    name="llvm:elf-virtual-program-header",
    @ogre.scheme3(Scheme::name(), Scheme::addr(), Scheme::size()),
    t => t,
  )
}

///|
/// `(llvm:elf-program-header-flags name ld r w x)`: whether a program
/// header is loadable and its permissions.
fn llvm_elf_program_header_flags() -> @ogre.Attribute[
  (String, Bool, Bool, Bool, Bool),
  (String, Bool, Bool, Bool, Bool),
] {
  @ogre.Attribute::new(
    name="llvm:elf-program-header-flags",
    @ogre.scheme5(
      Scheme::name(),
      bool_field("ld"),
      Scheme::readable(),
      Scheme::writable(),
      Scheme::executable(),
    ),
    t => t,
  )
}

///|
/// `(llvm:section-entry name addr size off)`: a named section.
fn llvm_section_entry() -> @ogre.Attribute[
  (String, Int64, Int64, Int64),
  (String, Int64, Int64, Int64),
] {
  @ogre.Attribute::new(
    name="llvm:section-entry",
    @ogre.scheme4(Scheme::name(), Scheme::addr(), Scheme::size(), Scheme::off()),
    t => t,
  )
}

///|
/// `(llvm:section-flags name r w x)`: the permissions of a named section.
fn llvm_section_flags() -> @ogre.Attribute[
  (String, Bool, Bool, Bool),
  (String, Bool, Bool, Bool),
] {
  @ogre.Attribute::new(
    name="llvm:section-flags",
    @ogre.scheme4(
      Scheme::name(),
      Scheme::readable(),
      Scheme::writable(),
      Scheme::executable(),
    ),
    t => t,
  )
}

///|
/// `(llvm:code-entry name off size)`: a named entry that contains code.
fn llvm_code_entry() -> @ogre.Attribute[
  (String, Int64, Int64),
  (String, Int64, Int64),
] {
  @ogre.Attribute::new(
    name="llvm:code-entry",
    @ogre.scheme3(Scheme::name(), Scheme::off(), Scheme::size()),
    t => t,
  )
}

///|
/// The name of the `i`th program header (upstream `name_of_index`).
fn llvm_name_of_index(i : Int) -> String {
  if i < 10 {
    "0\{i}"
  } else {
    i.to_string()
  }
}

///|
/// The raw ELF facts the upstream LLVM loader puts in the image
/// specification (`llvm_elf_loader.hpp`): the entry point, every program
/// header as it is in the file and in memory with its flags, and every
/// named section with its flags, executable sections being code entries.
///
/// They keep the file layout of all program headers (including the
/// non-loadable ones) and sections that the image projection drops.
///
/// The relocations (`emit_relocations`) are those of the image: the
/// `llvm:relocation` of the relocations to a (nonzero) address, the
/// `llvm:name-reference` of the references to external symbols, and the
/// `llvm:relative-relocation` of the relative relocations. (Upstream also
/// names the references to defined symbols.)
fn image_elf_loader_facts(
  data : Bytes,
  elf : @elf.Elf,
  relocations~ : Array[Relocation],
  external_references~ : Array[ExternalReference],
) -> OgreDoc? {
  let int = (x : UInt64) => x.reinterpret_as_int64()
  let facts = [@ogre.provide(llvm_entry_point(), int(elf.e_entry))]
  for r in relocations {
    match r.target() {
      Some(target) if target != 0UL =>
        facts.push(
          @ogre.provide(llvm_relocation(), (int(r.fixup()), int(target))),
        )
      Some(_) => ()
      None =>
        if r.is_relative() {
          facts.push(@ogre.provide(llvm_relative_relocation(), int(r.fixup())))
        }
    }
  }
  for x in external_references {
    facts.push(@ogre.provide(llvm_name_reference(), (int(x.addr()), x.name())))
  }
  for i, header in elf.e_segments {
    let name = llvm_name_of_index(i)
    facts.push(
      @ogre.provide(
        llvm_elf_program_header(),
        (name, int(header.p_offset), int(header.p_filesz)),
      ),
    )
    facts.push(
      @ogre.provide(
        llvm_elf_virtual_program_header(),
        (name, int(header.p_vaddr), int(header.p_memsz)),
      ),
    )
    facts.push(
      @ogre.provide(
        llvm_elf_program_header_flags(),
        (
          name,
          header.p_type is PT_LOAD,
          header.is_readable(),
          header.is_writable(),
          header.is_executable(),
        ),
      ),
    )
  }
  for section in elf.e_sections {
    match @elf.section_name(data, elf, section) {
      Ok(name) if name != "" => {
        facts.push(
          @ogre.provide(
            llvm_section_entry(),
            (
              name,
              int(section.sh_addr),
              int(section.sh_size),
              int(section.sh_offset),
            ),
          ),
        )
        facts.push(
          @ogre.provide(
            llvm_section_flags(),
            (name, true, section.is_writable(), section.is_executable()),
          ),
        )
        if section.is_executable() {
          facts.push(
            @ogre.provide(
              llvm_code_entry(),
              (name, int(section.sh_offset), int(section.sh_size)),
            ),
          )
        }
      }
      _ => ()
    }
  }
  try @ogre.exec(@ogre.Ogre::all_unit(facts), @ogre.Doc::empty()) catch {
    _ => None
  } noraise {
    doc => Some(doc)
  }
}
