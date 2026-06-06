///|
pub(all) enum DwarfLocationListEntry {
  DwarfLocBaseAddressx(Int)
  DwarfLocStartxEndx(Int, Int, Bytes)
  DwarfLocStartxLength(Int, Int, Bytes)
  DwarfLocOffsetPair(Int, Int, Bytes)
  DwarfLocDefaultLocation(Bytes)
  DwarfLocBaseAddress(UInt64)
  DwarfLocStartEnd(UInt64, UInt64, Bytes)
  DwarfLocStartLength(UInt64, Int, Bytes)
} derive(Eq, Debug)

///|
struct DwarfLocationList {
  entries_value : Array[DwarfLocationListEntry]
}

///|
fn dwarf_read_location_expr(
  input : DwarfInput,
  endian : @bitvec.Endian,
) -> Result[(Bytes, DwarfInput), String] {
  input.read_block(lenspec=DwarfLeb128, endian~)
}

///|
fn dwarf_read_legacy_location_expr(
  input : DwarfInput,
  endian : @bitvec.Endian,
) -> Result[(Bytes, DwarfInput), String] {
  input.read_block(lenspec=DwarfTwo, endian~)
}

///|
fn dwarf_legacy_location_base_marker(addr_size : DwarfWordSize) -> UInt64 {
  match addr_size {
    W32 => 0xffffffffUL
    W64 => UInt64::lnot(0UL)
  }
}

///|
fn dwarf_location_offset_to_int(value : UInt64) -> Result[Int, String] {
  if value > 2147483647UL {
    Err("DWARF location-list offset does not fit in Int")
  } else {
    Ok(value.to_int())
  }
}

///|
pub fn DwarfLocationList::read(
  buffer : DwarfSectionBuffer,
  offset? : Int = 0,
  endian~ : @bitvec.Endian,
  addr_size~ : DwarfWordSize,
) -> Result[DwarfLocationList, String] {
  let mut cursor = match buffer.offset(offset) {
    Ok(section) => section.input()
    Err(reason) => return Err(reason)
  }
  let entries : Array[DwarfLocationListEntry] = []
  let mut done = false
  while !done {
    match cursor.read_byte() {
      Ok((0x00, next)) => {
        cursor = next
        done = true
      }
      Ok((0x01, next)) =>
        match next.read_code() {
          Ok((index, after_index)) => {
            entries.push(DwarfLocBaseAddressx(index))
            cursor = after_index
          }
          Err(reason) => return Err(reason)
        }
      Ok((0x02, next)) =>
        match next.read_code() {
          Ok((start_index, after_start)) =>
            match after_start.read_code() {
              Ok((end_index, after_end)) =>
                match dwarf_read_location_expr(after_end, endian) {
                  Ok((expr, after_expr)) => {
                    entries.push(
                      DwarfLocStartxEndx(start_index, end_index, expr),
                    )
                    cursor = after_expr
                  }
                  Err(reason) => return Err(reason)
                }
              Err(reason) => return Err(reason)
            }
          Err(reason) => return Err(reason)
        }
      Ok((0x03, next)) =>
        match next.read_code() {
          Ok((start_index, after_start)) =>
            match after_start.read_code() {
              Ok((length, after_length)) =>
                match dwarf_read_location_expr(after_length, endian) {
                  Ok((expr, after_expr)) => {
                    entries.push(
                      DwarfLocStartxLength(start_index, length, expr),
                    )
                    cursor = after_expr
                  }
                  Err(reason) => return Err(reason)
                }
              Err(reason) => return Err(reason)
            }
          Err(reason) => return Err(reason)
        }
      Ok((0x04, next)) =>
        match next.read_code() {
          Ok((start, after_start)) =>
            match after_start.read_code() {
              Ok((end, after_end)) =>
                match dwarf_read_location_expr(after_end, endian) {
                  Ok((expr, after_expr)) => {
                    entries.push(DwarfLocOffsetPair(start, end, expr))
                    cursor = after_expr
                  }
                  Err(reason) => return Err(reason)
                }
              Err(reason) => return Err(reason)
            }
          Err(reason) => return Err(reason)
        }
      Ok((0x05, next)) =>
        match dwarf_read_location_expr(next, endian) {
          Ok((expr, after_expr)) => {
            entries.push(DwarfLocDefaultLocation(expr))
            cursor = after_expr
          }
          Err(reason) => return Err(reason)
        }
      Ok((0x06, next)) =>
        match next.read_address(endian~, size=addr_size) {
          Ok((addr, after_addr)) => {
            entries.push(DwarfLocBaseAddress(addr))
            cursor = after_addr
          }
          Err(reason) => return Err(reason)
        }
      Ok((0x07, next)) =>
        match next.read_address(endian~, size=addr_size) {
          Ok((start, after_start)) =>
            match after_start.read_address(endian~, size=addr_size) {
              Ok((end, after_end)) =>
                match dwarf_read_location_expr(after_end, endian) {
                  Ok((expr, after_expr)) => {
                    entries.push(DwarfLocStartEnd(start, end, expr))
                    cursor = after_expr
                  }
                  Err(reason) => return Err(reason)
                }
              Err(reason) => return Err(reason)
            }
          Err(reason) => return Err(reason)
        }
      Ok((0x08, next)) =>
        match next.read_address(endian~, size=addr_size) {
          Ok((start, after_start)) =>
            match after_start.read_code() {
              Ok((length, after_length)) =>
                match dwarf_read_location_expr(after_length, endian) {
                  Ok((expr, after_expr)) => {
                    entries.push(DwarfLocStartLength(start, length, expr))
                    cursor = after_expr
                  }
                  Err(reason) => return Err(reason)
                }
              Err(reason) => return Err(reason)
            }
          Err(reason) => return Err(reason)
        }
      Ok((kind, _)) =>
        return Err("unsupported DWARF location-list entry: \{kind}")
      Err(reason) => return Err(reason)
    }
  }
  Ok({ entries_value: entries })
}

///|
pub fn DwarfLocationList::read_loc(
  buffer : DwarfSectionBuffer,
  offset? : Int = 0,
  endian~ : @bitvec.Endian,
  addr_size~ : DwarfWordSize,
) -> Result[DwarfLocationList, String] {
  let mut cursor = match buffer.offset(offset) {
    Ok(section) => section.input()
    Err(reason) => return Err(reason)
  }
  let entries : Array[DwarfLocationListEntry] = []
  let base_marker = dwarf_legacy_location_base_marker(addr_size)
  let mut done = false
  while !done {
    match cursor.read_address(endian~, size=addr_size) {
      Ok((start, after_start)) =>
        match after_start.read_address(endian~, size=addr_size) {
          Ok((end, after_end)) =>
            if start == 0UL && end == 0UL {
              cursor = after_end
              done = true
            } else if start == base_marker {
              entries.push(DwarfLocBaseAddress(end))
              cursor = after_end
            } else {
              let start = match dwarf_location_offset_to_int(start) {
                Ok(value) => value
                Err(reason) => return Err(reason)
              }
              let end = match dwarf_location_offset_to_int(end) {
                Ok(value) => value
                Err(reason) => return Err(reason)
              }
              match dwarf_read_legacy_location_expr(after_end, endian) {
                Ok((expr, after_expr)) => {
                  entries.push(DwarfLocOffsetPair(start, end, expr))
                  cursor = after_expr
                }
                Err(reason) => return Err(reason)
              }
            }
          Err(reason) => return Err(reason)
        }
      Err(reason) => return Err(reason)
    }
  }
  Ok({ entries_value: entries })
}

///|
pub fn DwarfLocationList::entries(
  self : DwarfLocationList,
) -> Array[DwarfLocationListEntry] {
  self.entries_value.copy()
}

///|
pub fn DwarfLocationList::length(self : DwarfLocationList) -> Int {
  self.entries_value.length()
}

///|
pub fn DwarfLocationList::is_empty(self : DwarfLocationList) -> Bool {
  self.entries_value.is_empty()
}

///|
pub fn DwarfData::loclist(
  self : DwarfData,
  offset? : Int = 0,
  addr_size~ : DwarfWordSize,
) -> Result[DwarfLocationList, String] {
  match self.section(DwarfLoclists) {
    Ok(section) =>
      DwarfLocationList::read(
        section,
        offset~,
        endian=self.endian(),
        addr_size~,
      )
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfData::loc(
  self : DwarfData,
  offset? : Int = 0,
  addr_size~ : DwarfWordSize,
) -> Result[DwarfLocationList, String] {
  match self.section(DwarfLoc) {
    Ok(section) =>
      DwarfLocationList::read_loc(
        section,
        offset~,
        endian=self.endian(),
        addr_size~,
      )
    Err(reason) => Err(reason)
  }
}
