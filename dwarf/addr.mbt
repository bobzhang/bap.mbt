///|
struct DwarfAddressTable {
  addresses_value : Array[UInt64]
  base_offset_value : Int32
  version_value : Int32?
  addr_size_value : DwarfWordSize
}

///|
fn dwarf_read_address_entries(
  input : DwarfInput,
  end_position : Int32,
  endian : @bitvec.Endian,
  addr_size : DwarfWordSize,
) -> Result[Array[UInt64], String] {
  let entries : Array[UInt64] = []
  let mut cursor = input
  while cursor.position() < end_position {
    match cursor.read_address(endian~, size=addr_size) {
      Ok((addr, next)) => {
        entries.push(addr)
        cursor = next
      }
      Err(reason) => return Err(reason)
    }
  }
  if cursor.position() == end_position {
    Ok(entries)
  } else {
    Err("DWARF address table entry overran contribution")
  }
}

///|
pub fn DwarfAddressTable::read(
  buffer : DwarfSectionBuffer,
  offset~ : Int32 = 0,
  endian~ : @bitvec.Endian,
  addr_size~ : DwarfWordSize,
) -> Result[DwarfAddressTable, String] {
  let start = match buffer.offset(offset) {
    Ok(section) => section
    Err(reason) => return Err(reason)
  }
  let end_position = buffer.data().length()
  match
    dwarf_read_address_entries(start.input(), end_position, endian, addr_size) {
    Ok(entries) =>
      Ok({
        addresses_value: entries,
        base_offset_value: start.position(),
        version_value: None,
        addr_size_value: addr_size,
      })
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfAddressTable::read_contribution(
  buffer : DwarfSectionBuffer,
  offset~ : Int32 = 0,
  endian~ : @bitvec.Endian,
) -> Result[DwarfAddressTable, String] {
  let start = match buffer.offset(offset) {
    Ok(section) => section
    Err(reason) => return Err(reason)
  }
  match start.input().read_unit_size(endian~) {
    Ok(((_, unit_size), after_size)) => {
      let end_position = after_size.position() + unit_size
      if end_position > buffer.data().length() {
        return Err("DWARF address table contribution is out of bounds")
      }
      match after_size.read_version() {
        Ok((version, after_version)) =>
          match after_version.read_address_size() {
            Ok((addr_size, after_addr_size)) =>
              match after_addr_size.read_byte() {
                Ok((0, after_segment)) =>
                  match
                    dwarf_read_address_entries(
                      after_segment, end_position, endian, addr_size,
                    ) {
                    Ok(entries) =>
                      Ok({
                        addresses_value: entries,
                        base_offset_value: after_segment.position(),
                        version_value: Some(version),
                        addr_size_value: addr_size,
                      })
                    Err(reason) => Err(reason)
                  }
                Ok((selector_size, _)) =>
                  Err(
                    "unsupported DWARF address table segment selector size: \{selector_size}",
                  )
                Err(reason) => Err(reason)
              }
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    }
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfAddressTable::addresses(self : DwarfAddressTable) -> Array[UInt64] {
  self.addresses_value.copy()
}

///|
pub fn DwarfAddressTable::address(
  self : DwarfAddressTable,
  index : Int32,
) -> Result[UInt64, String] {
  if index < 0 || index >= self.addresses_value.length() {
    Err("DWARF address index is out of bounds")
  } else {
    Ok(self.addresses_value[index])
  }
}

///|
pub fn DwarfAddressTable::length(self : DwarfAddressTable) -> Int32 {
  self.addresses_value.length()
}

///|
pub fn DwarfAddressTable::is_empty(self : DwarfAddressTable) -> Bool {
  self.addresses_value.is_empty()
}

///|
pub fn DwarfAddressTable::base_offset(self : DwarfAddressTable) -> Int32 {
  self.base_offset_value
}

///|
pub fn DwarfAddressTable::version(self : DwarfAddressTable) -> Int32? {
  self.version_value
}

///|
pub fn DwarfAddressTable::address_size(
  self : DwarfAddressTable,
) -> DwarfWordSize {
  self.addr_size_value
}

///|
pub fn DwarfData::address_table(
  self : DwarfData,
  offset~ : Int32 = 0,
  addr_size~ : DwarfWordSize,
) -> Result[DwarfAddressTable, String] {
  match self.section(DwarfAddr) {
    Ok(section) =>
      DwarfAddressTable::read(
        section,
        offset~,
        endian=self.endian(),
        addr_size~,
      )
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfData::address_table_contribution(
  self : DwarfData,
  offset~ : Int32 = 0,
) -> Result[DwarfAddressTable, String] {
  match self.section(DwarfAddr) {
    Ok(section) =>
      DwarfAddressTable::read_contribution(
        section,
        offset~,
        endian=self.endian(),
      )
    Err(reason) => Err(reason)
  }
}
