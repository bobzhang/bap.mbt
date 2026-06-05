///|
struct DwarfDie {
  section_offset_value : Int
  unit_offset_value : Int
  depth_value : Int
  code_value : Int
  entry_value : DwarfAbbrevEntry
  attributes_offset_value : Int
  end_offset_value : Int
}

///|
fn dwarf_die_create(
  section_offset~ : Int,
  unit_offset~ : Int,
  depth~ : Int,
  code~ : Int,
  entry~ : DwarfAbbrevEntry,
  attributes_offset~ : Int,
  end_offset~ : Int,
) -> DwarfDie {
  {
    section_offset_value: section_offset,
    unit_offset_value: unit_offset,
    depth_value: depth,
    code_value: code,
    entry_value: entry,
    attributes_offset_value: attributes_offset,
    end_offset_value: end_offset,
  }
}

///|
fn dwarf_skip_die_attributes(
  input : DwarfInput,
  entry : DwarfAbbrevEntry,
  unit_end : Int,
  endian : @bitvec.Endian,
  version : Int,
  dwarf_size : DwarfWordSize,
  addr_size : DwarfWordSize,
) -> Result[DwarfInput, String] {
  let mut cursor = input
  for field in entry.fields() {
    match
      dwarf_skip_form(
        cursor,
        field.form(),
        endian,
        version,
        dwarf_size,
        addr_size,
      ) {
      Ok(next) => {
        if next.position() > unit_end {
          return Err("DWARF DIE attribute over-read")
        }
        cursor = next
      }
      Err(reason) => return Err(reason)
    }
  }
  Ok(cursor)
}

///|
pub fn DwarfDie::section_offset(self : DwarfDie) -> Int {
  self.section_offset_value
}

///|
pub fn DwarfDie::unit_offset(self : DwarfDie) -> Int {
  self.unit_offset_value
}

///|
pub fn DwarfDie::depth(self : DwarfDie) -> Int {
  self.depth_value
}

///|
pub fn DwarfDie::code(self : DwarfDie) -> Int {
  self.code_value
}

///|
pub fn DwarfDie::entry(self : DwarfDie) -> DwarfAbbrevEntry {
  self.entry_value
}

///|
pub fn DwarfDie::tag(self : DwarfDie) -> DwarfTag {
  self.entry_value.tag()
}

///|
pub fn DwarfDie::has_children(self : DwarfDie) -> Bool {
  self.entry_value.has_children()
}

///|
pub fn DwarfDie::fields(self : DwarfDie) -> Array[DwarfAbbrevField] {
  self.entry_value.fields()
}

///|
pub fn DwarfDie::attributes_offset(self : DwarfDie) -> Int {
  self.attributes_offset_value
}

///|
pub fn DwarfDie::end_offset(self : DwarfDie) -> Int {
  self.end_offset_value
}

///|
pub fn DwarfInfoUnitHeader::dies(
  self : DwarfInfoUnitHeader,
  info : DwarfSectionBuffer,
  abbrev_table : DwarfAbbrevTable,
  endian~ : @bitvec.Endian,
) -> Result[Array[DwarfDie], String] {
  if !self.is_supported() {
    return Ok([])
  }
  let mut cursor = match info.with_position(self.body_offset()) {
    Ok(buffer) => buffer.input()
    Err(reason) => return Err(reason)
  }
  if self.end_offset() > info.data().length() {
    return Err("truncated DWARF input")
  }
  let out : Array[DwarfDie] = []
  let mut depth = 0
  while cursor.position() < self.end_offset() {
    let section_offset = cursor.position()
    let unit_offset = section_offset - self.start_offset()
    match cursor.read_code() {
      Ok((0, next)) => {
        if depth > 0 {
          depth -= 1
        }
        cursor = next
      }
      Ok((code, after_code)) =>
        match abbrev_table.lookup(code) {
          Some(entry) => {
            let attributes_offset = after_code.position()
            match
              dwarf_skip_die_attributes(
                after_code,
                entry,
                self.end_offset(),
                endian,
                self.version(),
                self.dwarf_size(),
                self.address_size(),
              ) {
              Ok(next) => {
                out.push(
                  dwarf_die_create(
                    section_offset~,
                    unit_offset~,
                    depth~,
                    code~,
                    entry~,
                    attributes_offset~,
                    end_offset=next.position(),
                  ),
                )
                if entry.has_children() {
                  depth += 1
                }
                cursor = next
              }
              Err(reason) => return Err(reason)
            }
          }
          None => return Err("unknown DWARF abbreviation code: \{code}")
        }
      Err(reason) => return Err(reason)
    }
  }
  if cursor.position() > self.end_offset() {
    Err("DWARF DIE over-read")
  } else {
    Ok(out)
  }
}

///|
pub fn DwarfData::unit_dies(
  self : DwarfData,
  offset? : Int = 0,
) -> Result[Array[DwarfDie], String] {
  let header = match self.unit_header(offset~) {
    Ok(header) => header
    Err(reason) => return Err(reason)
  }
  if !header.is_supported() {
    return Ok([])
  }
  let info = match self.section(DwarfInfo) {
    Ok(info) => info
    Err(reason) => return Err(reason)
  }
  let abbrev_table = match self.abbrev_table(offset=header.abbrev_offset()) {
    Ok(table) => table
    Err(reason) => return Err(reason)
  }
  header.dies(info, abbrev_table, endian=self.endian())
}

///|
pub fn DwarfData::dies(self : DwarfData) -> Result[Array[DwarfDie], String] {
  let info = match self.section(DwarfInfo) {
    Ok(info) => info
    Err(reason) => return Err(reason)
  }
  let headers = match self.unit_headers() {
    Ok(headers) => headers
    Err(reason) => return Err(reason)
  }
  let out : Array[DwarfDie] = []
  for header in headers {
    if header.is_supported() {
      let abbrev_table = match
        self.abbrev_table(offset=header.abbrev_offset()) {
        Ok(table) => table
        Err(reason) => return Err(reason)
      }
      match header.dies(info, abbrev_table, endian=self.endian()) {
        Ok(dies) =>
          for die in dies {
            out.push(die)
          }
        Err(reason) => return Err(reason)
      }
    }
  }
  Ok(out)
}
