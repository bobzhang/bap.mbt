///|
pub(all) enum DwarfSection {
  DwarfInfo
  DwarfAbbrev
  DwarfStr
  DwarfLineStr
  DwarfStrOffsets
  DwarfAddr
  DwarfRanges
  DwarfRnglists
  DwarfLoclists
} derive(Eq, Debug)

///|
struct DwarfSectionBuffer {
  data_value : Bytes
  position_value : Int
}

///|
struct DwarfData {
  endian_value : @bitvec.Endian
  sections_value : Array[(DwarfSection, DwarfSectionBuffer)]
}

///|
pub fn DwarfSection::to_string(self : DwarfSection) -> String {
  match self {
    DwarfInfo => ".debug_info"
    DwarfAbbrev => ".debug_abbrev"
    DwarfStr => ".debug_str"
    DwarfLineStr => ".debug_line_str"
    DwarfStrOffsets => ".debug_str_offsets"
    DwarfAddr => ".debug_addr"
    DwarfRanges => ".debug_ranges"
    DwarfRnglists => ".debug_rnglists"
    DwarfLoclists => ".debug_loclists"
  }
}

///|
pub fn DwarfSectionBuffer::create(
  data : Bytes,
  position? : Int = 0,
) -> Result[DwarfSectionBuffer, String] {
  if position < 0 || position > data.length() {
    Err("DWARF section buffer position is out of bounds")
  } else {
    Ok({ data_value: data, position_value: position })
  }
}

///|
pub fn DwarfSectionBuffer::data(self : DwarfSectionBuffer) -> Bytes {
  self.data_value
}

///|
pub fn DwarfSectionBuffer::position(self : DwarfSectionBuffer) -> Int {
  self.position_value
}

///|
pub fn DwarfSectionBuffer::pos(self : DwarfSectionBuffer) -> Int {
  self.position()
}

///|
pub fn DwarfSectionBuffer::with_position(
  self : DwarfSectionBuffer,
  position : Int,
) -> Result[DwarfSectionBuffer, String] {
  DwarfSectionBuffer::create(self.data_value, position~)
}

///|
pub fn DwarfSectionBuffer::with_pos(
  self : DwarfSectionBuffer,
  position : Int,
) -> Result[DwarfSectionBuffer, String] {
  self.with_position(position)
}

///|
pub fn DwarfSectionBuffer::offset(
  self : DwarfSectionBuffer,
  offset : Int,
) -> Result[DwarfSectionBuffer, String] {
  self.with_position(self.position_value + offset)
}

///|
pub fn DwarfSectionBuffer::with_off(
  self : DwarfSectionBuffer,
  offset : Int,
) -> Result[DwarfSectionBuffer, String] {
  self.offset(offset)
}

///|
pub fn DwarfSectionBuffer::input(self : DwarfSectionBuffer) -> DwarfInput {
  DwarfInput::of_bytes(self.data_value).with_position(self.position_value)
}

///|
fn dwarf_section_index(
  sections : Array[(DwarfSection, DwarfSectionBuffer)],
  section : DwarfSection,
) -> Int? {
  sections.search_by(entry => entry.0 == section)
}

///|
pub fn DwarfData::create(
  endian~ : @bitvec.Endian,
  sections~ : Array[(DwarfSection, DwarfSectionBuffer)],
) -> Result[DwarfData, String] {
  let out : Array[(DwarfSection, DwarfSectionBuffer)] = []
  for entry in sections {
    if dwarf_section_index(out, entry.0) is Some(_) {
      return Err("duplicate DWARF section: \{entry.0.to_string()}")
    }
    out.push(entry)
  }
  Ok({ endian_value: endian, sections_value: out })
}

///|
pub fn DwarfData::from_bytes(
  endian~ : @bitvec.Endian,
  info? : Bytes,
  abbrev? : Bytes,
  str? : Bytes,
  line_str? : Bytes,
  str_offsets? : Bytes,
  addr? : Bytes,
  ranges? : Bytes,
  rnglists? : Bytes,
  loclists? : Bytes,
) -> Result[DwarfData, String] {
  let sections : Array[(DwarfSection, DwarfSectionBuffer)] = []
  match info {
    Some(data) =>
      match DwarfSectionBuffer::create(data) {
        Ok(buffer) => sections.push((DwarfInfo, buffer))
        Err(reason) => return Err(reason)
      }
    None => ()
  }
  match abbrev {
    Some(data) =>
      match DwarfSectionBuffer::create(data) {
        Ok(buffer) => sections.push((DwarfAbbrev, buffer))
        Err(reason) => return Err(reason)
      }
    None => ()
  }
  match str {
    Some(data) =>
      match DwarfSectionBuffer::create(data) {
        Ok(buffer) => sections.push((DwarfStr, buffer))
        Err(reason) => return Err(reason)
      }
    None => ()
  }
  match line_str {
    Some(data) =>
      match DwarfSectionBuffer::create(data) {
        Ok(buffer) => sections.push((DwarfLineStr, buffer))
        Err(reason) => return Err(reason)
      }
    None => ()
  }
  match str_offsets {
    Some(data) =>
      match DwarfSectionBuffer::create(data) {
        Ok(buffer) => sections.push((DwarfStrOffsets, buffer))
        Err(reason) => return Err(reason)
      }
    None => ()
  }
  match addr {
    Some(data) =>
      match DwarfSectionBuffer::create(data) {
        Ok(buffer) => sections.push((DwarfAddr, buffer))
        Err(reason) => return Err(reason)
      }
    None => ()
  }
  match ranges {
    Some(data) =>
      match DwarfSectionBuffer::create(data) {
        Ok(buffer) => sections.push((DwarfRanges, buffer))
        Err(reason) => return Err(reason)
      }
    None => ()
  }
  match rnglists {
    Some(data) =>
      match DwarfSectionBuffer::create(data) {
        Ok(buffer) => sections.push((DwarfRnglists, buffer))
        Err(reason) => return Err(reason)
      }
    None => ()
  }
  match loclists {
    Some(data) =>
      match DwarfSectionBuffer::create(data) {
        Ok(buffer) => sections.push((DwarfLoclists, buffer))
        Err(reason) => return Err(reason)
      }
    None => ()
  }
  DwarfData::create(endian~, sections~)
}

///|
pub fn DwarfData::endian(self : DwarfData) -> @bitvec.Endian {
  self.endian_value
}

///|
pub fn DwarfData::sections(
  self : DwarfData,
) -> Array[(DwarfSection, DwarfSectionBuffer)] {
  self.sections_value.copy()
}

///|
pub fn DwarfData::section(
  self : DwarfData,
  section : DwarfSection,
) -> Result[DwarfSectionBuffer, String] {
  match dwarf_section_index(self.sections_value, section) {
    Some(index) => Ok(self.sections_value[index].1)
    None => Err("section \{section.to_string()} is not available")
  }
}

///|
pub fn DwarfData::has_section(self : DwarfData, section : DwarfSection) -> Bool {
  dwarf_section_index(self.sections_value, section) is Some(_)
}
