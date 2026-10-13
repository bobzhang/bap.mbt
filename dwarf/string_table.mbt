///|
struct DwarfStringTable {
  buffer_value : DwarfSectionBuffer
}

///|
pub fn DwarfStringTable::read(
  buffer : DwarfSectionBuffer,
  offset~ : Int32 = 0,
) -> Result[DwarfStringTable, String] {
  match buffer.offset(offset) {
    Ok(section) => Ok({ buffer_value: section, })
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfStringTable::base_offset(self : DwarfStringTable) -> Int32 {
  self.buffer_value.position()
}

///|
pub fn DwarfStringTable::data(self : DwarfStringTable) -> Bytes {
  self.buffer_value.data()
}

///|
pub fn DwarfStringTable::is_empty(self : DwarfStringTable) -> Bool {
  self.buffer_value.position() >= self.buffer_value.data().length()
}

///|
pub fn DwarfStringTable::string(
  self : DwarfStringTable,
  offset : Int32,
) -> Result[String, String] {
  dwarf_read_str_section_name(self.buffer_value, offset)
}

///|
pub fn DwarfStringTable::entries(
  self : DwarfStringTable,
) -> Result[Array[(Int32, String)], String] {
  let entries : Array[(Int32, String)] = []
  let mut cursor = self.buffer_value.input()
  let end_position = self.buffer_value.data().length()
  while cursor.position() < end_position {
    let relative_offset = cursor.position() - self.buffer_value.position()
    match cursor.read_cstring() {
      Ok((text, next)) => {
        entries.push((relative_offset, text))
        cursor = next
      }
      Err(reason) => return Err(reason)
    }
  }
  Ok(entries)
}

///|
pub fn DwarfStringTable::strings(
  self : DwarfStringTable,
) -> Result[Array[String], String] {
  match self.entries() {
    Ok(entries) => Ok(entries.map(entry => entry.1))
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfData::string_table(
  self : DwarfData,
  offset~ : Int32 = 0,
) -> Result[DwarfStringTable, String] {
  match self.section(DwarfStr) {
    Ok(section) => DwarfStringTable::read(section, offset~)
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfData::line_string_table(
  self : DwarfData,
  offset~ : Int32 = 0,
) -> Result[DwarfStringTable, String] {
  match self.section(DwarfLineStr) {
    Ok(section) => DwarfStringTable::read(section, offset~)
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfData::debug_string(
  self : DwarfData,
  offset~ : Int32 = 0,
) -> Result[String, String] {
  match self.string_table() {
    Ok(table) => table.string(offset)
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfData::line_string(
  self : DwarfData,
  offset~ : Int32 = 0,
) -> Result[String, String] {
  match self.line_string_table() {
    Ok(table) => table.string(offset)
    Err(reason) => Err(reason)
  }
}
