///|
pub(all) enum DwarfRangeListEntry {
  DwarfRangeBaseAddressx(Int)
  DwarfRangeStartxEndx(Int, Int)
  DwarfRangeStartxLength(Int, Int)
  DwarfRangeOffsetPair(Int, Int)
  DwarfRangeBaseAddress(UInt64)
  DwarfRangeStartEnd(UInt64, UInt64)
  DwarfRangeStartLength(UInt64, Int)
} derive(Eq, Debug)

///|
struct DwarfRangeList {
  entries_value : Array[DwarfRangeListEntry]
}

///|
pub fn DwarfRangeList::read(
  buffer : DwarfSectionBuffer,
  offset? : Int = 0,
  endian~ : @bitvec.Endian,
  addr_size~ : DwarfWordSize,
) -> Result[DwarfRangeList, String] {
  let mut cursor = match buffer.offset(offset) {
    Ok(section) => section.input()
    Err(reason) => return Err(reason)
  }
  let entries : Array[DwarfRangeListEntry] = []
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
            entries.push(DwarfRangeBaseAddressx(index))
            cursor = after_index
          }
          Err(reason) => return Err(reason)
        }
      Ok((0x02, next)) =>
        match next.read_code() {
          Ok((start_index, after_start)) =>
            match after_start.read_code() {
              Ok((end_index, after_end)) => {
                entries.push(DwarfRangeStartxEndx(start_index, end_index))
                cursor = after_end
              }
              Err(reason) => return Err(reason)
            }
          Err(reason) => return Err(reason)
        }
      Ok((0x03, next)) =>
        match next.read_code() {
          Ok((start_index, after_start)) =>
            match after_start.read_code() {
              Ok((length, after_length)) => {
                entries.push(DwarfRangeStartxLength(start_index, length))
                cursor = after_length
              }
              Err(reason) => return Err(reason)
            }
          Err(reason) => return Err(reason)
        }
      Ok((0x04, next)) =>
        match next.read_code() {
          Ok((start, after_start)) =>
            match after_start.read_code() {
              Ok((end, after_end)) => {
                entries.push(DwarfRangeOffsetPair(start, end))
                cursor = after_end
              }
              Err(reason) => return Err(reason)
            }
          Err(reason) => return Err(reason)
        }
      Ok((0x05, next)) =>
        match next.read_address(endian~, size=addr_size) {
          Ok((addr, after_addr)) => {
            entries.push(DwarfRangeBaseAddress(addr))
            cursor = after_addr
          }
          Err(reason) => return Err(reason)
        }
      Ok((0x06, next)) =>
        match next.read_address(endian~, size=addr_size) {
          Ok((start, after_start)) =>
            match after_start.read_address(endian~, size=addr_size) {
              Ok((end, after_end)) => {
                entries.push(DwarfRangeStartEnd(start, end))
                cursor = after_end
              }
              Err(reason) => return Err(reason)
            }
          Err(reason) => return Err(reason)
        }
      Ok((0x07, next)) =>
        match next.read_address(endian~, size=addr_size) {
          Ok((start, after_start)) =>
            match after_start.read_code() {
              Ok((length, after_length)) => {
                entries.push(DwarfRangeStartLength(start, length))
                cursor = after_length
              }
              Err(reason) => return Err(reason)
            }
          Err(reason) => return Err(reason)
        }
      Ok((kind, _)) => return Err("unsupported DWARF range-list entry: \{kind}")
      Err(reason) => return Err(reason)
    }
  }
  Ok({ entries_value: entries })
}

///|
pub fn DwarfRangeList::read_ranges(
  buffer : DwarfSectionBuffer,
  offset? : Int = 0,
  endian~ : @bitvec.Endian,
  addr_size~ : DwarfWordSize,
) -> Result[DwarfRangeList, String] {
  let mut cursor = match buffer.offset(offset) {
    Ok(section) => section.input()
    Err(reason) => return Err(reason)
  }
  let max_addr = dwarf_max_address(addr_size)
  let entries : Array[DwarfRangeListEntry] = []
  let mut done = false
  while !done {
    match cursor.read_address(endian~, size=addr_size) {
      Ok((start, after_start)) =>
        match after_start.read_address(endian~, size=addr_size) {
          Ok((end, after_end)) => {
            cursor = after_end
            if start == 0UL && end == 0UL {
              done = true
            } else if start == max_addr {
              entries.push(DwarfRangeBaseAddress(end))
            } else if start > 2147483647UL || end > 2147483647UL {
              return Err("DWARF range offset does not fit in Int")
            } else {
              entries.push(DwarfRangeOffsetPair(start.to_int(), end.to_int()))
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
pub fn DwarfRangeList::entries(
  self : DwarfRangeList,
) -> Array[DwarfRangeListEntry] {
  self.entries_value.copy()
}

///|
pub fn DwarfRangeList::length(self : DwarfRangeList) -> Int {
  self.entries_value.length()
}

///|
pub fn DwarfRangeList::is_empty(self : DwarfRangeList) -> Bool {
  self.entries_value.is_empty()
}

///|
pub fn DwarfData::ranges(
  self : DwarfData,
  offset? : Int = 0,
  addr_size~ : DwarfWordSize,
) -> Result[DwarfRangeList, String] {
  match self.section(DwarfRanges) {
    Ok(section) =>
      DwarfRangeList::read_ranges(
        section,
        offset~,
        endian=self.endian(),
        addr_size~,
      )
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfData::rnglist(
  self : DwarfData,
  offset? : Int = 0,
  addr_size~ : DwarfWordSize,
) -> Result[DwarfRangeList, String] {
  match self.section(DwarfRnglists) {
    Ok(section) =>
      DwarfRangeList::read(section, offset~, endian=self.endian(), addr_size~)
    Err(reason) => Err(reason)
  }
}
