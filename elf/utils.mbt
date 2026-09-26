///|
/// The file bytes `data[pos + offset:pos + offset + size]` of a range of
/// the ELF file starting at `pos`.
fn file_range(
  data : Bytes,
  pos : Int,
  offset : UInt64,
  size : UInt64,
  what : String,
) -> Bytes raise Malformed {
  if pos < 0 || pos > data.length() {
    raise Malformed("ELF data position is out of bounds")
  }
  let len = (data.length() - pos).to_uint64()
  if offset > len || size > len - offset {
    raise Malformed("\{what} is out of bounds")
  }
  let start = pos + offset.to_int()
  data[start:start + size.to_int()].to_owned()
}

///|
/// Decodes a null-terminated string of a string table: UTF-8 when valid,
/// otherwise byte per character (Latin-1), so every name is readable.
fn cstring_at(table : BytesView, offset : Int) -> String raise Malformed {
  if offset < 0 || offset >= table.length() {
    raise Malformed("ELF string offset is out of bounds")
  }
  let mut stop = offset
  while stop < table.length() && table[stop] != b'\x00' {
    stop = stop + 1
  }
  if stop >= table.length() {
    raise Malformed("ELF string is not null-terminated")
  }
  let bytes = table[offset:stop]
  @utf8.decode(bytes) catch {
    _ =>
      String::from_array(bytes.to_array().map(b => b.to_int().unsafe_to_char()))
  }
}

///|
/// Reads the null-terminated string at `offset` of a string table.
pub fn string_at(table : BytesView, offset : Int) -> Result[String, String] {
  catch_malformed(() => cstring_at(table, offset))
}

///|
/// The contents of a section as they are in the file (upstream
/// `Elf.string_of_section`): `sh_size` bytes at `sh_offset`, regardless of
/// the section type.
pub fn string_of_section(
  data : Bytes,
  section : Section,
  pos? : Int = 0,
) -> Result[Bytes, String] {
  catch_malformed(() => {
    file_range(data, pos, section.sh_offset, section.sh_size, "ELF section")
  })
}

///|
/// The file image of a program header: `p_filesz` bytes at `p_offset`.
pub fn string_of_segment(
  data : Bytes,
  segment : Segment,
  pos? : Int = 0,
) -> Result[Bytes, String] {
  catch_malformed(() => {
    file_range(data, pos, segment.p_offset, segment.p_filesz, "ELF segment")
  })
}

///|
/// The name of a section (upstream `Elf.section_name`): the string at
/// `sh_name` in the section name string table `e_shstrndx`.
pub fn section_name(
  data : Bytes,
  elf : Elf,
  section : Section,
  pos? : Int = 0,
) -> Result[String, String] {
  catch_malformed(() => {
    guard elf.e_sections.get(elf.e_shstrndx) is Some(names) else {
      raise Malformed(
        "index \{elf.e_shstrndx} doesn't point to a valid section",
      )
    }
    let table = file_range(
      data,
      pos,
      names.sh_offset,
      names.sh_size,
      "ELF section name table",
    )
    cstring_at(table, section.sh_name.reinterpret_as_int())
  })
}

///|
/// The names of all sections, in section order; a section whose name
/// can't be read is `None`.
pub fn section_names(data : Bytes, elf : Elf, pos? : Int = 0) -> Array[String?] {
  elf.e_sections.map(section => {
    section_name(data, elf, section, pos~).to_option()
  })
}

///|
/// The first section with the given name.
pub fn find_section(
  data : Bytes,
  elf : Elf,
  name : String,
  pos? : Int = 0,
) -> Section? {
  for section in elf.e_sections {
    if section_name(data, elf, section, pos~) is Ok(n) && n == name {
      return Some(section)
    }
  }
  None
}

///|
/// A symbol table entry (`Elf32_Sym`/`Elf64_Sym`), with every field.
pub(all) struct Symbol {
  st_name : UInt
  st_value : UInt64
  st_size : UInt64
  st_info : Int
  st_other : Int
  st_shndx : Int
} derive(Eq, Compare, Debug)

///|
pub extend Symbol with Eq::{equal, not_equal}

///|
pub extend Symbol with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend Symbol with Debug::{to_repr}

///|
/// The symbol binding (`ELF_ST_BIND`): 0 local, 1 global, 2 weak, ...
pub fn Symbol::st_bind(self : Symbol) -> Int {
  self.st_info >> 4
}

///|
/// The symbol type (`ELF_ST_TYPE`): 0 none, 1 object, 2 function, ...
pub fn Symbol::st_type(self : Symbol) -> Int {
  self.st_info & 0xf
}

///|
/// The symbol visibility (`ELF_ST_VISIBILITY`).
pub fn Symbol::st_visibility(self : Symbol) -> Int {
  self.st_other & 3
}

///|
/// The size of a symbol table entry of a class.
pub fn EClass::symbol_size(self : EClass) -> Int {
  match self {
    ELFCLASS32 => 16
    ELFCLASS64 => 24
  }
}

///|
/// The number of `entry`-sized entries of a table section: the section's
/// `sh_entsize`, or `default` when it is zero.
fn table_entries(
  section : Section,
  default : Int,
  what : String,
) -> (Int, Int) raise Malformed {
  let entsize = if section.sh_entsize == 0UL {
    default.to_uint64()
  } else {
    section.sh_entsize
  }
  if entsize < default.to_uint64() || entsize > 0xffffUL {
    raise Malformed("\{what} entry size is invalid")
  }
  if section.sh_size % entsize != 0UL {
    raise Malformed("\{what} size is not entry-aligned")
  }
  let count = section.sh_size / entsize
  if count > 0x7fffffffUL {
    raise Malformed("\{what} is too large")
  }
  (entsize.to_int(), count.to_int())
}

///|
/// The entries of a symbol table section (`SHT_SYMTAB` or `SHT_DYNSYM`).
pub fn symbols(
  data : Bytes,
  elf : Elf,
  section : Section,
  pos? : Int = 0,
) -> Result[Array[Symbol], String] {
  catch_malformed(() => {
    let (entsize, count) = table_entries(
      section,
      elf.e_class.symbol_size(),
      "ELF symbol table",
    )
    let table = file_range(
      data,
      pos,
      section.sh_offset,
      section.sh_size,
      "ELF symbol table",
    )
    let r : Reader = {
      data: table,
      pos: 0,
      len: table.length(),
      endian: elf.endian(),
    }
    let class = elf.e_class
    Array::makei(count, i => {
      let base = (i * entsize).to_uint64()
      {
        st_name: r.uint(base, 4).to_uint(),
        st_value: r.field(class, base, 4, 8),
        st_size: r.field(class, base, 8, 16),
        st_info: r.field(class, base, 12, 4, bytes32=1, bytes64=1).to_int() &
        0xff,
        st_other: r.field(class, base, 13, 5, bytes32=1, bytes64=1).to_int() &
        0xff,
        st_shndx: r.field(class, base, 14, 6, bytes32=2, bytes64=2).to_int() &
        0xffff,
      }
    })
  })
}

///|
/// The name of a symbol of a symbol table section: the string at
/// `st_name` in the string table linked by the section (`sh_link`).
pub fn symbol_name(
  data : Bytes,
  elf : Elf,
  symtab : Section,
  symbol : Symbol,
  pos? : Int = 0,
) -> Result[String, String] {
  catch_malformed(() => {
    guard elf.e_sections.get(symtab.sh_link.reinterpret_as_int())
      is Some(strtab) else {
      raise Malformed("ELF symbol string table link is out of bounds")
    }
    let table = file_range(
      data,
      pos,
      strtab.sh_offset,
      strtab.sh_size,
      "ELF string table",
    )
    cstring_at(table, symbol.st_name.reinterpret_as_int())
  })
}

///|
/// A relocation entry (`Elf_Rel`/`Elf_Rela`); `r_addend` is present for
/// `SHT_RELA` sections.
pub(all) struct Relocation {
  r_offset : UInt64
  r_info : UInt64
  r_addend : Int64?
} derive(Eq, Compare, Debug)

///|
pub extend Relocation with Eq::{equal, not_equal}

///|
pub extend Relocation with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend Relocation with Debug::{to_repr}

///|
/// The symbol index of the relocation (`ELF_R_SYM`) in a file of `class`.
pub fn Relocation::r_sym(self : Relocation, class : EClass) -> UInt {
  match class {
    ELFCLASS32 => (self.r_info >> 8).to_uint()
    ELFCLASS64 => (self.r_info >> 32).to_uint()
  }
}

///|
/// The relocation type (`ELF_R_TYPE`) in a file of `class`.
pub fn Relocation::r_type(self : Relocation, class : EClass) -> UInt {
  match class {
    ELFCLASS32 => (self.r_info & 0xffUL).to_uint()
    ELFCLASS64 => (self.r_info & 0xffffffffUL).to_uint()
  }
}

///|
/// The entries of a relocation section (`SHT_REL` or `SHT_RELA`).
pub fn relocations(
  data : Bytes,
  elf : Elf,
  section : Section,
  pos? : Int = 0,
) -> Result[Array[Relocation], String] {
  catch_malformed(() => {
    let class = elf.e_class
    let word = match class {
      ELFCLASS32 => 4
      ELFCLASS64 => 8
    }
    let has_addend = section.sh_type is SHT_RELA
    let (entsize, count) = table_entries(
      section,
      if has_addend {
        3 * word
      } else {
        2 * word
      },
      "ELF relocation table",
    )
    let table = file_range(
      data,
      pos,
      section.sh_offset,
      section.sh_size,
      "ELF relocation table",
    )
    let r : Reader = {
      data: table,
      pos: 0,
      len: table.length(),
      endian: elf.endian(),
    }
    Array::makei(count, i => {
      let base = (i * entsize).to_uint64()
      {
        r_offset: r.field(class, base, 0, 0),
        r_info: r.field(class, base, 4, 8),
        r_addend: if has_addend {
          let raw = r.field(class, base, 8, 16)
          Some(
            match class {
              ELFCLASS32 => raw.to_uint().reinterpret_as_int().to_int64()
              ELFCLASS64 => raw.reinterpret_as_int64()
            },
          )
        } else {
          None
        },
      }
    })
  })
}
