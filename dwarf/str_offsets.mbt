///|
struct DwarfStringOffsetsTable {
  offsets_value : Array[Int32]
  base_offset_value : Int32
  version_value : Int32?
  dwarf_size_value : DwarfWordSize
}

///|
fn dwarf_read_string_offset_entries(
  input : DwarfInput,
  end_position : Int32,
  endian : @bitvec.Endian,
  dwarf_size : DwarfWordSize,
) -> Result[Array[Int32], String] {
  let offsets : Array[Int32] = []
  let mut cursor = input
  while cursor.position() < end_position {
    match cursor.read_offset(endian~, size=dwarf_size) {
      Ok((offset, next)) => {
        offsets.push(offset)
        cursor = next
      }
      Err(reason) => return Err(reason)
    }
  }
  if cursor.position() == end_position {
    Ok(offsets)
  } else {
    Err("DWARF string-offset table entry overran contribution")
  }
}

///|
pub fn DwarfStringOffsetsTable::read(
  buffer : DwarfSectionBuffer,
  offset~ : Int32 = 0,
  endian~ : @bitvec.Endian,
  dwarf_size~ : DwarfWordSize,
) -> Result[DwarfStringOffsetsTable, String] {
  let start = match buffer.offset(offset) {
    Ok(section) => section
    Err(reason) => return Err(reason)
  }
  let end_position = buffer.data().length()
  match
    dwarf_read_string_offset_entries(
      start.input(),
      end_position,
      endian,
      dwarf_size,
    ) {
    Ok(offsets) =>
      Ok({
        offsets_value: offsets,
        base_offset_value: start.position(),
        version_value: None,
        dwarf_size_value: dwarf_size,
      })
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfStringOffsetsTable::read_contribution(
  buffer : DwarfSectionBuffer,
  offset~ : Int32 = 0,
  endian~ : @bitvec.Endian,
) -> Result[DwarfStringOffsetsTable, String] {
  let start = match buffer.offset(offset) {
    Ok(section) => section
    Err(reason) => return Err(reason)
  }
  match start.input().read_unit_size(endian~) {
    Ok(((dwarf_size, unit_size), after_size)) => {
      let end_position = after_size.position() + unit_size
      if end_position > buffer.data().length() {
        return Err("DWARF string-offset table contribution is out of bounds")
      }
      match after_size.read_version() {
        Ok((version, after_version)) =>
          match after_version.read_int16(endian~) {
            Ok((0, after_padding)) =>
              match
                dwarf_read_string_offset_entries(
                  after_padding, end_position, endian, dwarf_size,
                ) {
                Ok(offsets) =>
                  Ok({
                    offsets_value: offsets,
                    base_offset_value: after_padding.position(),
                    version_value: Some(version),
                    dwarf_size_value: dwarf_size,
                  })
                Err(reason) => Err(reason)
              }
            Ok((padding, _)) =>
              Err("unsupported DWARF string-offset table padding: \{padding}")
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    }
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfStringOffsetsTable::offsets(
  self : DwarfStringOffsetsTable,
) -> Array[Int32] {
  self.offsets_value.copy()
}

///|
pub fn DwarfStringOffsetsTable::offset(
  self : DwarfStringOffsetsTable,
  index : Int32,
) -> Result[Int32, String] {
  if index < 0 || index >= self.offsets_value.length() {
    Err("DWARF string-offset index is out of bounds")
  } else {
    Ok(self.offsets_value[index])
  }
}

///|
pub fn DwarfStringOffsetsTable::strings(
  self : DwarfStringOffsetsTable,
  str_section : DwarfSectionBuffer,
) -> Result[Array[String], String] {
  let out : Array[String] = []
  for offset in self.offsets_value {
    match dwarf_read_str_section_name(str_section, offset) {
      Ok(text) => out.push(text)
      Err(reason) => return Err(reason)
    }
  }
  Ok(out)
}

///|
pub fn DwarfStringOffsetsTable::string(
  self : DwarfStringOffsetsTable,
  str_section : DwarfSectionBuffer,
  index : Int32,
) -> Result[String, String] {
  match self.offset(index) {
    Ok(offset) => dwarf_read_str_section_name(str_section, offset)
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfStringOffsetsTable::length(self : DwarfStringOffsetsTable) -> Int32 {
  self.offsets_value.length()
}

///|
pub fn DwarfStringOffsetsTable::is_empty(
  self : DwarfStringOffsetsTable,
) -> Bool {
  self.offsets_value.is_empty()
}

///|
pub fn DwarfStringOffsetsTable::base_offset(
  self : DwarfStringOffsetsTable,
) -> Int32 {
  self.base_offset_value
}

///|
pub fn DwarfStringOffsetsTable::version(
  self : DwarfStringOffsetsTable,
) -> Int32? {
  self.version_value
}

///|
pub fn DwarfStringOffsetsTable::dwarf_size(
  self : DwarfStringOffsetsTable,
) -> DwarfWordSize {
  self.dwarf_size_value
}

///|
pub fn DwarfData::string_offsets(
  self : DwarfData,
  offset~ : Int32 = 0,
  dwarf_size~ : DwarfWordSize,
) -> Result[DwarfStringOffsetsTable, String] {
  match self.section(DwarfStrOffsets) {
    Ok(section) =>
      DwarfStringOffsetsTable::read(
        section,
        offset~,
        endian=self.endian(),
        dwarf_size~,
      )
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfData::string_offsets_contribution(
  self : DwarfData,
  offset~ : Int32 = 0,
) -> Result[DwarfStringOffsetsTable, String] {
  match self.section(DwarfStrOffsets) {
    Ok(section) =>
      DwarfStringOffsetsTable::read_contribution(
        section,
        offset~,
        endian=self.endian(),
      )
    Err(reason) => Err(reason)
  }
}
