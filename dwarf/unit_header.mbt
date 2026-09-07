///|
pub(all) enum DwarfInfoUnitKind {
  DwarfInfoUnitLegacy
  DwarfInfoUnitCompile
  DwarfInfoUnitType
  DwarfInfoUnitPartial
  DwarfInfoUnitSkeleton
  DwarfInfoUnitSplitCompile
  DwarfInfoUnitSplitType
  DwarfInfoUnitUnknown(Int)
} derive(Eq, Debug)

///|
pub extend DwarfInfoUnitKind with Eq::{not_equal, equal}

///|
pub extend DwarfInfoUnitKind with Debug::{to_repr}

///|
struct DwarfInfoUnitHeader {
  start_offset_value : Int
  end_offset_value : Int
  header_end_offset_value : Int
  unit_size_value : Int
  dwarf_size_value : DwarfWordSize
  version_value : Int
  kind_value : DwarfInfoUnitKind
  address_size_value : DwarfWordSize
  abbrev_offset_value : Int
  supported_value : Bool
}

///|
fn dwarf_info_unit_kind_of_code(code : Int) -> DwarfInfoUnitKind {
  match code {
    1 => DwarfInfoUnitCompile
    2 => DwarfInfoUnitType
    3 => DwarfInfoUnitPartial
    4 => DwarfInfoUnitSkeleton
    5 => DwarfInfoUnitSplitCompile
    6 => DwarfInfoUnitSplitType
    other => DwarfInfoUnitUnknown(other)
  }
}

///|
fn DwarfInfoUnitKind::tail_bytes(
  self : DwarfInfoUnitKind,
  dwarf_size : DwarfWordSize,
) -> Int? {
  match self {
    DwarfInfoUnitLegacy | DwarfInfoUnitCompile | DwarfInfoUnitPartial => Some(0)
    DwarfInfoUnitSkeleton | DwarfInfoUnitSplitCompile => Some(8)
    DwarfInfoUnitType | DwarfInfoUnitSplitType =>
      Some(8 + dwarf_word_bytes(dwarf_size))
    DwarfInfoUnitUnknown(_) => None
  }
}

///|
pub fn DwarfInfoUnitKind::unit_type(self : DwarfInfoUnitKind) -> Int? {
  match self {
    DwarfInfoUnitLegacy => None
    DwarfInfoUnitCompile => Some(1)
    DwarfInfoUnitType => Some(2)
    DwarfInfoUnitPartial => Some(3)
    DwarfInfoUnitSkeleton => Some(4)
    DwarfInfoUnitSplitCompile => Some(5)
    DwarfInfoUnitSplitType => Some(6)
    DwarfInfoUnitUnknown(code) => Some(code)
  }
}

///|
pub fn DwarfInfoUnitKind::is_supported(self : DwarfInfoUnitKind) -> Bool {
  self.tail_bytes(W32) is Some(_)
}

///|
fn dwarf_info_unit_header_create(
  start~ : Int,
  end~ : Int,
  header_end~ : Int,
  unit_size~ : Int,
  dwarf_size~ : DwarfWordSize,
  version~ : Int,
  kind~ : DwarfInfoUnitKind,
  address_size~ : DwarfWordSize,
  abbrev_offset~ : Int,
  supported~ : Bool,
) -> Result[DwarfInfoUnitHeader, String] {
  if header_end > end {
    Err("DWARF unit header over-read")
  } else {
    Ok({
      start_offset_value: start,
      end_offset_value: end,
      header_end_offset_value: header_end,
      unit_size_value: unit_size,
      dwarf_size_value: dwarf_size,
      version_value: version,
      kind_value: kind,
      address_size_value: address_size,
      abbrev_offset_value: abbrev_offset,
      supported_value: supported,
    })
  }
}

///|
pub fn DwarfInfoUnitHeader::read(
  buffer : DwarfSectionBuffer,
  offset? : Int = 0,
  endian~ : @bitvec.Endian,
) -> Result[DwarfInfoUnitHeader, String] {
  let start = match buffer.offset(offset) {
    Ok(section) => section
    Err(reason) => return Err(reason)
  }
  let unit_start = start.position()
  match start.input().read_unit_size(endian~) {
    Ok(((dwarf_size, unit_size), after_size)) => {
      let unit_end = after_size.position() + unit_size
      if unit_end > buffer.data().length() {
        return Err("truncated DWARF input")
      }
      match after_size.read_version() {
        Ok((version, after_version)) =>
          if version >= 5 {
            match after_version.read_byte() {
              Ok((unit_type, after_unit_type)) =>
                match after_unit_type.read_address_size() {
                  Ok((addr_size, after_addr_size)) =>
                    match
                      after_addr_size.read_offset(endian~, size=dwarf_size) {
                      Ok((abbrev_offset, after_abbrev)) => {
                        let kind = dwarf_info_unit_kind_of_code(unit_type)
                        match kind.tail_bytes(dwarf_size) {
                          Some(bytes) =>
                            match after_abbrev.skip(bytes~) {
                              Ok(after_tail) =>
                                dwarf_info_unit_header_create(
                                  start=unit_start,
                                  end=unit_end,
                                  header_end=after_tail.position(),
                                  unit_size~,
                                  dwarf_size~,
                                  version~,
                                  kind~,
                                  address_size=addr_size,
                                  abbrev_offset~,
                                  supported=true,
                                )
                              Err(reason) => Err(reason)
                            }
                          None =>
                            dwarf_info_unit_header_create(
                              start=unit_start,
                              end=unit_end,
                              header_end=after_abbrev.position(),
                              unit_size~,
                              dwarf_size~,
                              version~,
                              kind~,
                              address_size=addr_size,
                              abbrev_offset~,
                              supported=false,
                            )
                        }
                      }
                      Err(reason) => Err(reason)
                    }
                  Err(reason) => Err(reason)
                }
              Err(reason) => Err(reason)
            }
          } else {
            match after_version.read_offset(endian~, size=dwarf_size) {
              Ok((abbrev_offset, after_abbrev)) =>
                match after_abbrev.read_address_size() {
                  Ok((addr_size, after_addr_size)) =>
                    dwarf_info_unit_header_create(
                      start=unit_start,
                      end=unit_end,
                      header_end=after_addr_size.position(),
                      unit_size~,
                      dwarf_size~,
                      version~,
                      kind=DwarfInfoUnitLegacy,
                      address_size=addr_size,
                      abbrev_offset~,
                      supported=true,
                    )
                  Err(reason) => Err(reason)
                }
              Err(reason) => Err(reason)
            }
          }
        Err(reason) => Err(reason)
      }
    }
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInfoUnitHeader::start_offset(self : DwarfInfoUnitHeader) -> Int {
  self.start_offset_value
}

///|
pub fn DwarfInfoUnitHeader::end_offset(self : DwarfInfoUnitHeader) -> Int {
  self.end_offset_value
}

///|
pub fn DwarfInfoUnitHeader::next_offset(self : DwarfInfoUnitHeader) -> Int {
  self.end_offset_value
}

///|
pub fn DwarfInfoUnitHeader::header_end_offset(
  self : DwarfInfoUnitHeader,
) -> Int {
  self.header_end_offset_value
}

///|
pub fn DwarfInfoUnitHeader::body_offset(self : DwarfInfoUnitHeader) -> Int {
  self.header_end_offset_value
}

///|
pub fn DwarfInfoUnitHeader::unit_size(self : DwarfInfoUnitHeader) -> Int {
  self.unit_size_value
}

///|
pub fn DwarfInfoUnitHeader::dwarf_size(
  self : DwarfInfoUnitHeader,
) -> DwarfWordSize {
  self.dwarf_size_value
}

///|
pub fn DwarfInfoUnitHeader::version(self : DwarfInfoUnitHeader) -> Int {
  self.version_value
}

///|
pub fn DwarfInfoUnitHeader::kind(
  self : DwarfInfoUnitHeader,
) -> DwarfInfoUnitKind {
  self.kind_value
}

///|
pub fn DwarfInfoUnitHeader::unit_type(self : DwarfInfoUnitHeader) -> Int? {
  self.kind_value.unit_type()
}

///|
pub fn DwarfInfoUnitHeader::address_size(
  self : DwarfInfoUnitHeader,
) -> DwarfWordSize {
  self.address_size_value
}

///|
pub fn DwarfInfoUnitHeader::abbrev_offset(self : DwarfInfoUnitHeader) -> Int {
  self.abbrev_offset_value
}

///|
pub fn DwarfInfoUnitHeader::is_supported(self : DwarfInfoUnitHeader) -> Bool {
  self.supported_value
}

///|
pub fn DwarfData::unit_header(
  self : DwarfData,
  offset? : Int = 0,
) -> Result[DwarfInfoUnitHeader, String] {
  match self.section(DwarfInfo) {
    Ok(section) =>
      DwarfInfoUnitHeader::read(section, offset~, endian=self.endian())
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfData::unit_headers(
  self : DwarfData,
) -> Result[Array[DwarfInfoUnitHeader], String] {
  let section = match self.section(DwarfInfo) {
    Ok(section) => section
    Err(reason) => return Err(reason)
  }
  let headers : Array[DwarfInfoUnitHeader] = []
  let mut cursor = section.input()
  while cursor.remaining() > 0 {
    if dwarf_remaining_is_zero_padding(cursor) {
      return Ok(headers)
    }
    let offset = cursor.position() - section.position()
    match DwarfInfoUnitHeader::read(section, offset~, endian=self.endian()) {
      Ok(header) => {
        headers.push(header)
        cursor = cursor.with_position(header.next_offset())
      }
      Err(reason) => return Err(reason)
    }
  }
  Ok(headers)
}
