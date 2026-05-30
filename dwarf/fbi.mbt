///|
struct DwarfFunction {
  name_value : String
  low_pc_value : UInt64
  high_pc_value : UInt64?
}

///|
priv enum DwarfRangeListRef {
  DwarfRangeOffset(Int)
  DwarfRnglistsIndex(Int)
}

///|
priv enum DwarfNameRef {
  DwarfCuNameRef(Int)
  DwarfSectionNameRef(Int)
}

///|
priv enum DwarfFunctionAttrValue {
  DwarfAttrName(String)
  DwarfAttrLinkageName(String)
  DwarfAttrLowPc(UInt64)
  DwarfAttrEntryPc(UInt64)
  DwarfAttrHighPcAbs(UInt64)
  DwarfAttrHighPcRel(Int64)
  DwarfAttrRanges(DwarfRangeListRef)
  DwarfAttrNameRef(DwarfNameRef)
  DwarfAttrStrOffsetsBase(Int)
  DwarfAttrAddrBase(Int)
  DwarfAttrRnglistsBase(Int)
  DwarfAttrIgnored
}

///|
priv struct DwarfDieName {
  unit_start : Int
  unit_offset : Int
  section_offset : Int
  name : String
}

///|
priv struct DwarfFunctionCandidate {
  unit_start : Int
  name : String?
  name_ref : DwarfNameRef?
  low_pc : UInt64
  high_pc : UInt64?
}

///|
priv struct DwarfParsedUnit {
  function_candidates : Array[DwarfFunctionCandidate]
  die_names : Array[DwarfDieName]
  next : DwarfInput
}

///|
priv struct DwarfRangeSummary {
  low : UInt64
  high : UInt64
}

///|
priv struct DwarfScope {
  range_base : UInt64
}

///|
pub fn DwarfFunction::create(
  name~ : String,
  low_pc~ : UInt64,
  high_pc? : UInt64,
) -> DwarfFunction {
  { name_value: name, low_pc_value: low_pc, high_pc_value: high_pc }
}

///|
pub fn DwarfFunction::name(self : DwarfFunction) -> String {
  self.name_value
}

///|
pub fn DwarfFunction::low_pc(self : DwarfFunction) -> UInt64 {
  self.low_pc_value
}

///|
pub fn DwarfFunction::high_pc(self : DwarfFunction) -> UInt64? {
  self.high_pc_value
}

///|
fn dwarf_name_value(
  field : DwarfAbbrevField,
  name : String,
) -> DwarfFunctionAttrValue {
  match field.attr() {
    DwarfLinkageName => DwarfAttrLinkageName(name)
    _ => DwarfAttrName(name)
  }
}

///|
fn dwarf_ref_offset_to_int(value : Int64) -> Result[Int, String] {
  if value < 0L {
    Err("negative DWARF reference offset")
  } else {
    let offset = value.to_int()
    if offset.to_int64() == value {
      Ok(offset)
    } else {
      Err("DWARF reference offset does not fit in Int")
    }
  }
}

///|
fn dwarf_lookup_die_name(
  names : Array[DwarfDieName],
  unit_start : Int,
  name_ref : DwarfNameRef,
) -> String? {
  let index = match name_ref {
    DwarfCuNameRef(offset) =>
      names.search_by(item => {
        item.unit_start == unit_start && item.unit_offset == offset
      })
    DwarfSectionNameRef(offset) =>
      names.search_by(item => item.section_offset == offset)
  }
  match index {
    Some(index) => Some(names[index].name)
    None => None
  }
}

///|
fn DwarfFunctionCandidate::resolve(
  self : DwarfFunctionCandidate,
  names : Array[DwarfDieName],
) -> DwarfFunction? {
  let display_name = match self.name {
    Some(text) => Some(text)
    None =>
      match self.name_ref {
        Some(name_ref) =>
          dwarf_lookup_die_name(names, self.unit_start, name_ref)
        None => None
      }
  }
  match display_name {
    Some(text) =>
      Some(
        DwarfFunction::create(
          name=text,
          low_pc=self.low_pc,
          high_pc?=self.high_pc,
        ),
      )
    None => None
  }
}

///|
fn dwarf_skip_form(
  input : DwarfInput,
  form : DwarfForm,
  endian : @bitvec.Endian,
  dwarf_size : DwarfWordSize,
  addr_size : DwarfWordSize,
) -> Result[DwarfInput, String] {
  match form {
    DwarfAddr =>
      match input.read_address(endian~, size=addr_size) {
        Ok((_, next)) => Ok(next)
        Err(reason) => Err(reason)
      }
    DwarfStrp | DwarfOffset | DwarfRefAddr =>
      match input.read_offset(endian~, size=dwarf_size) {
        Ok((_, next)) => Ok(next)
        Err(reason) => Err(reason)
      }
    DwarfStrpSup | DwarfLineStrp =>
      match input.read_offset(endian~, size=dwarf_size) {
        Ok((_, next)) => Ok(next)
        Err(reason) => Err(reason)
      }
    DwarfStrx(spec) =>
      match input.read_index(spec, endian) {
        Ok((_, next)) => Ok(next)
        Err(reason) => Err(reason)
      }
    DwarfAddrx(spec) =>
      match input.read_index(spec, endian) {
        Ok((_, next)) => Ok(next)
        Err(reason) => Err(reason)
      }
    DwarfRnglistx =>
      match input.read_code() {
        Ok((_, next)) => Ok(next)
        Err(reason) => Err(reason)
      }
    DwarfLoclistx =>
      match input.read_code() {
        Ok((_, next)) => Ok(next)
        Err(reason) => Err(reason)
      }
    DwarfData16 => input.skip(bytes=16)
    DwarfImplicitConst(_) => Ok(input)
    DwarfRefSup4 => input.skip(bytes=4)
    DwarfString =>
      match input.read_cstring() {
        Ok((_, next)) => Ok(next)
        Err(reason) => Err(reason)
      }
    DwarfBlock(lenspec) =>
      match input.read_block(lenspec~, endian~) {
        Ok((_, next)) => Ok(next)
        Err(reason) => Err(reason)
      }
    DwarfRef(lenspec) | DwarfConst(lenspec) =>
      match input.read_const(lenspec~, endian~) {
        Ok((_, next)) => Ok(next)
        Err(reason) => Err(reason)
      }
    DwarfFlagPresent => Ok(input)
    DwarfExpr =>
      match input.read_block(lenspec=DwarfLeb128, endian~) {
        Ok((_, next)) => Ok(next)
        Err(reason) => Err(reason)
      }
    DwarfIndirect =>
      match input.read_form() {
        Ok((indirect_form, next)) =>
          dwarf_skip_form(next, indirect_form, endian, dwarf_size, addr_size)
        Err(reason) => Err(reason)
      }
  }
}

///|
fn dwarf_read_str_section_name(
  str_section : DwarfSectionBuffer,
  offset : Int,
) -> Result[String, String] {
  match str_section.offset(offset) {
    Ok(buffer) =>
      match buffer.input().read_cstring() {
        Ok((name, _)) => Ok(name)
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn dwarf_read_strp_name(
  input : DwarfInput,
  endian : @bitvec.Endian,
  dwarf_size : DwarfWordSize,
  str_section : DwarfSectionBuffer,
) -> Result[(String, DwarfInput), String] {
  match input.read_offset(endian~, size=dwarf_size) {
    Ok((offset, next)) =>
      match dwarf_read_str_section_name(str_section, offset) {
        Ok(name) => Ok((name, next))
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn dwarf_read_line_strp_name(
  input : DwarfInput,
  endian : @bitvec.Endian,
  dwarf_size : DwarfWordSize,
  line_str_section : DwarfSectionBuffer?,
) -> Result[(String, DwarfInput), String] {
  let section = match line_str_section {
    Some(section) => section
    None => return Err("section .debug_line_str is not available")
  }
  match input.read_offset(endian~, size=dwarf_size) {
    Ok((offset, next)) =>
      match dwarf_read_str_section_name(section, offset) {
        Ok(name) => Ok((name, next))
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn dwarf_read_strx_name(
  input : DwarfInput,
  spec : DwarfIndexSpec,
  endian : @bitvec.Endian,
  dwarf_size : DwarfWordSize,
  str_offsets_base : Int,
  str_offsets_section : DwarfSectionBuffer?,
  str_section : DwarfSectionBuffer,
) -> Result[(String, DwarfInput), String] {
  let str_offsets_section = match str_offsets_section {
    Some(section) => section
    None => return Err("section .debug_str_offsets is not available")
  }
  match input.read_index(spec, endian) {
    Ok((index, next)) => {
      let entry_offset = str_offsets_base + index * dwarf_word_bytes(dwarf_size)
      match str_offsets_section.offset(entry_offset) {
        Ok(offset_entry) =>
          match offset_entry.input().read_offset(endian~, size=dwarf_size) {
            Ok((name_offset, _)) =>
              match dwarf_read_str_section_name(str_section, name_offset) {
                Ok(name) => Ok((name, next))
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
fn dwarf_lookup_addrx(
  addr_section : DwarfSectionBuffer?,
  index : Int,
  addr_base : Int?,
  endian : @bitvec.Endian,
  addr_size : DwarfWordSize,
) -> Result[UInt64, String] {
  let addr_section = match addr_section {
    Some(section) => section
    None => return Err("section .debug_addr is not available")
  }
  let addr_base = match addr_base {
    Some(base) => base
    None => return Err("DW_AT_addr_base is not available")
  }
  if index < 0 {
    return Err("negative DWARF address index")
  }
  let entry_offset = addr_base + index * dwarf_word_bytes(addr_size)
  match addr_section.offset(entry_offset) {
    Ok(entry) =>
      match entry.input().read_address(endian~, size=addr_size) {
        Ok((addr, _)) => Ok(addr)
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn dwarf_read_address_value(
  input : DwarfInput,
  form : DwarfForm,
  endian : @bitvec.Endian,
  addr_size : DwarfWordSize,
  addr_base : Int?,
  addr_section : DwarfSectionBuffer?,
) -> Result[(UInt64, DwarfInput), String] {
  match form {
    DwarfAddr => input.read_address(endian~, size=addr_size)
    DwarfAddrx(spec) =>
      match input.read_index(spec, endian) {
        Ok((index, next)) =>
          match
            dwarf_lookup_addrx(
              addr_section, index, addr_base, endian, addr_size,
            ) {
            Ok(addr) => Ok((addr, next))
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    _ => Err("unsupported DWARF address form")
  }
}

///|
fn dwarf_max_address(size : DwarfWordSize) -> UInt64 {
  match size {
    W32 => 0xffffffffUL
    W64 => UInt64::lnot(0UL)
  }
}

///|
fn dwarf_read_ranges_summary(
  ranges_section : DwarfSectionBuffer,
  offset : Int,
  base_addr : UInt64,
  endian : @bitvec.Endian,
  addr_size : DwarfWordSize,
) -> Result[DwarfRangeSummary?, String] {
  let mut cursor = match ranges_section.offset(offset) {
    Ok(buffer) => buffer.input()
    Err(reason) => return Err(reason)
  }
  let max_addr = dwarf_max_address(addr_size)
  let mut base = base_addr
  let mut low : UInt64? = None
  let mut high : UInt64? = None
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
              base = end
            } else if end > start {
              let abs_start = base + start
              let abs_end = base + end
              low = match low {
                Some(value) if value <= abs_start => Some(value)
                _ => Some(abs_start)
              }
              high = match high {
                Some(value) if value >= abs_end => Some(value)
                _ => Some(abs_end)
              }
            }
          }
          Err(reason) => return Err(reason)
        }
      Err(reason) => return Err(reason)
    }
  }
  match (low, high) {
    (Some(lo), Some(hi)) => Ok(Some({ low: lo, high: hi }))
    _ => Ok(None)
  }
}

///|
fn dwarf_update_range_summary(
  low : UInt64?,
  high : UInt64?,
  start : UInt64,
  end : UInt64,
) -> (UInt64?, UInt64?) {
  if end <= start {
    (low, high)
  } else {
    let next_low = match low {
      Some(value) if value <= start => Some(value)
      _ => Some(start)
    }
    let next_high = match high {
      Some(value) if value >= end => Some(value)
      _ => Some(end)
    }
    (next_low, next_high)
  }
}

///|
fn dwarf_read_rnglists_summary(
  rnglists_section : DwarfSectionBuffer,
  offset : Int,
  base_addr : UInt64,
  endian : @bitvec.Endian,
  addr_size : DwarfWordSize,
  addr_base : Int?,
  addr_section : DwarfSectionBuffer?,
) -> Result[DwarfRangeSummary?, String] {
  let mut cursor = match rnglists_section.offset(offset) {
    Ok(buffer) => buffer.input()
    Err(reason) => return Err(reason)
  }
  let mut base = base_addr
  let mut low : UInt64? = None
  let mut high : UInt64? = None
  let mut done = false
  while !done {
    match cursor.read_byte() {
      Ok((0x00, next)) => {
        cursor = next
        done = true
      }
      Ok((0x01, next)) =>
        match next.read_code() {
          Ok((index, after_index)) =>
            match
              dwarf_lookup_addrx(
                addr_section, index, addr_base, endian, addr_size,
              ) {
              Ok(addr) => {
                base = addr
                cursor = after_index
              }
              Err(reason) => return Err(reason)
            }
          Err(reason) => return Err(reason)
        }
      Ok((0x02, next)) =>
        match next.read_code() {
          Ok((start_index, after_start)) =>
            match after_start.read_code() {
              Ok((end_index, after_end)) => {
                let start = match
                  dwarf_lookup_addrx(
                    addr_section, start_index, addr_base, endian, addr_size,
                  ) {
                  Ok(addr) => addr
                  Err(reason) => return Err(reason)
                }
                let end = match
                  dwarf_lookup_addrx(
                    addr_section, end_index, addr_base, endian, addr_size,
                  ) {
                  Ok(addr) => addr
                  Err(reason) => return Err(reason)
                }
                cursor = after_end
                let (next_low, next_high) = dwarf_update_range_summary(
                  low, high, start, end,
                )
                low = next_low
                high = next_high
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
                let start = match
                  dwarf_lookup_addrx(
                    addr_section, start_index, addr_base, endian, addr_size,
                  ) {
                  Ok(addr) => addr
                  Err(reason) => return Err(reason)
                }
                cursor = after_length
                let (next_low, next_high) = dwarf_update_range_summary(
                  low,
                  high,
                  start,
                  start + length.to_uint64(),
                )
                low = next_low
                high = next_high
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
                cursor = after_end
                let (next_low, next_high) = dwarf_update_range_summary(
                  low,
                  high,
                  base + start.to_uint64(),
                  base + end.to_uint64(),
                )
                low = next_low
                high = next_high
              }
              Err(reason) => return Err(reason)
            }
          Err(reason) => return Err(reason)
        }
      Ok((0x05, next)) =>
        match next.read_address(endian~, size=addr_size) {
          Ok((addr, after_addr)) => {
            base = addr
            cursor = after_addr
          }
          Err(reason) => return Err(reason)
        }
      Ok((0x06, next)) =>
        match next.read_address(endian~, size=addr_size) {
          Ok((start, after_start)) =>
            match after_start.read_address(endian~, size=addr_size) {
              Ok((end, after_end)) => {
                cursor = after_end
                let (next_low, next_high) = dwarf_update_range_summary(
                  low, high, start, end,
                )
                low = next_low
                high = next_high
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
                cursor = after_length
                let (next_low, next_high) = dwarf_update_range_summary(
                  low,
                  high,
                  start,
                  start + length.to_uint64(),
                )
                low = next_low
                high = next_high
              }
              Err(reason) => return Err(reason)
            }
          Err(reason) => return Err(reason)
        }
      Ok((kind, _)) => return Err("unsupported DWARF range-list entry: \{kind}")
      Err(reason) => return Err(reason)
    }
  }
  match (low, high) {
    (Some(lo), Some(hi)) => Ok(Some({ low: lo, high: hi }))
    _ => Ok(None)
  }
}

///|
fn dwarf_read_rnglists_index_offset(
  rnglists_section : DwarfSectionBuffer,
  index : Int,
  rnglists_base : Int,
  endian : @bitvec.Endian,
  dwarf_size : DwarfWordSize,
) -> Result[Int, String] {
  if index < 0 {
    return Err("negative DWARF range-list index")
  }
  let entry_offset = rnglists_base + index * dwarf_word_bytes(dwarf_size)
  match rnglists_section.offset(entry_offset) {
    Ok(offset_entry) =>
      match offset_entry.input().read_offset(endian~, size=dwarf_size) {
        Ok((relative, _)) => Ok(rnglists_base + relative)
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn dwarf_read_attr_value(
  input : DwarfInput,
  field : DwarfAbbrevField,
  endian : @bitvec.Endian,
  dwarf_size : DwarfWordSize,
  addr_size : DwarfWordSize,
  addr_base : Int?,
  addr_section : DwarfSectionBuffer?,
  str_offsets_base : Int,
  line_str_section : DwarfSectionBuffer?,
  str_offsets_section : DwarfSectionBuffer?,
  str_section : DwarfSectionBuffer,
) -> Result[(DwarfFunctionAttrValue, DwarfInput), String] {
  match field.form() {
    DwarfIndirect =>
      match input.read_form() {
        Ok((actual_form, next)) =>
          return dwarf_read_attr_value(
            next,
            DwarfAbbrevField::create(attr=field.attr(), form=actual_form),
            endian,
            dwarf_size,
            addr_size,
            addr_base,
            addr_section,
            str_offsets_base,
            line_str_section,
            str_offsets_section,
            str_section,
          )
        Err(reason) => return Err(reason)
      }
    _ => ()
  }
  match field.value_kind() {
    DwarfNameValue =>
      match field.form() {
        DwarfString =>
          match input.read_cstring() {
            Ok((name, next)) => Ok((dwarf_name_value(field, name), next))
            Err(reason) => Err(reason)
          }
        DwarfStrp =>
          match dwarf_read_strp_name(input, endian, dwarf_size, str_section) {
            Ok((name, next)) => Ok((dwarf_name_value(field, name), next))
            Err(reason) => Err(reason)
          }
        DwarfLineStrp =>
          match
            dwarf_read_line_strp_name(
              input, endian, dwarf_size, line_str_section,
            ) {
            Ok((name, next)) => Ok((dwarf_name_value(field, name), next))
            Err(reason) => Err(reason)
          }
        DwarfStrx(spec) =>
          match
            dwarf_read_strx_name(
              input, spec, endian, dwarf_size, str_offsets_base, str_offsets_section,
              str_section,
            ) {
            Ok((name, next)) => Ok((dwarf_name_value(field, name), next))
            Err(reason) => Err(reason)
          }
        form =>
          match dwarf_skip_form(input, form, endian, dwarf_size, addr_size) {
            Ok(next) => Ok((DwarfAttrIgnored, next))
            Err(reason) => Err(reason)
          }
      }
    DwarfLowPcValue =>
      match
        dwarf_read_address_value(
          input,
          field.form(),
          endian,
          addr_size,
          addr_base,
          addr_section,
        ) {
        Ok((addr, next)) => Ok((DwarfAttrLowPc(addr), next))
        Err(reason) => Err(reason)
      }
    DwarfEntryPcValue =>
      match
        dwarf_read_address_value(
          input,
          field.form(),
          endian,
          addr_size,
          addr_base,
          addr_section,
        ) {
        Ok((addr, next)) => Ok((DwarfAttrEntryPc(addr), next))
        Err(reason) => Err(reason)
      }
    DwarfHighPcAddressValue =>
      match
        dwarf_read_address_value(
          input,
          field.form(),
          endian,
          addr_size,
          addr_base,
          addr_section,
        ) {
        Ok((addr, next)) => Ok((DwarfAttrHighPcAbs(addr), next))
        Err(reason) => Err(reason)
      }
    DwarfHighPcOffsetValue =>
      match field.form() {
        DwarfImplicitConst(value) => Ok((DwarfAttrHighPcRel(value), input))
        DwarfConst(lenspec) =>
          match input.read_const(lenspec~, endian~) {
            Ok((offset, next)) => Ok((DwarfAttrHighPcRel(offset), next))
            Err(reason) => Err(reason)
          }
        form =>
          match dwarf_skip_form(input, form, endian, dwarf_size, addr_size) {
            Ok(next) => Ok((DwarfAttrIgnored, next))
            Err(reason) => Err(reason)
          }
      }
    DwarfRangesValue =>
      match field.form() {
        DwarfRnglistx =>
          match input.read_code() {
            Ok((index, next)) =>
              Ok((DwarfAttrRanges(DwarfRnglistsIndex(index)), next))
            Err(reason) => Err(reason)
          }
        DwarfOffset =>
          match input.read_offset(endian~, size=dwarf_size) {
            Ok((offset, next)) =>
              Ok((DwarfAttrRanges(DwarfRangeOffset(offset)), next))
            Err(reason) => Err(reason)
          }
        form =>
          match dwarf_skip_form(input, form, endian, dwarf_size, addr_size) {
            Ok(next) => Ok((DwarfAttrIgnored, next))
            Err(reason) => Err(reason)
          }
      }
    DwarfNameRefValue =>
      match field.form() {
        DwarfRef(lenspec) =>
          match input.read_const(lenspec~, endian~) {
            Ok((offset, next)) =>
              match dwarf_ref_offset_to_int(offset) {
                Ok(value) => Ok((DwarfAttrNameRef(DwarfCuNameRef(value)), next))
                Err(reason) => Err(reason)
              }
            Err(reason) => Err(reason)
          }
        DwarfRefAddr =>
          match input.read_offset(endian~, size=dwarf_size) {
            Ok((offset, next)) =>
              if offset < 0 {
                Err("negative DWARF reference address")
              } else {
                Ok((DwarfAttrNameRef(DwarfSectionNameRef(offset)), next))
              }
            Err(reason) => Err(reason)
          }
        form =>
          match dwarf_skip_form(input, form, endian, dwarf_size, addr_size) {
            Ok(next) => Ok((DwarfAttrIgnored, next))
            Err(reason) => Err(reason)
          }
      }
    DwarfStrOffsetsBaseValue =>
      match input.read_offset(endian~, size=dwarf_size) {
        Ok((base, next)) => Ok((DwarfAttrStrOffsetsBase(base), next))
        Err(reason) => Err(reason)
      }
    DwarfAddrBaseValue =>
      match input.read_offset(endian~, size=dwarf_size) {
        Ok((base, next)) => Ok((DwarfAttrAddrBase(base), next))
        Err(reason) => Err(reason)
      }
    DwarfRnglistsBaseValue =>
      match input.read_offset(endian~, size=dwarf_size) {
        Ok((base, next)) => Ok((DwarfAttrRnglistsBase(base), next))
        Err(reason) => Err(reason)
      }
    DwarfIgnoredValue =>
      match
        dwarf_skip_form(input, field.form(), endian, dwarf_size, addr_size) {
        Ok(next) => Ok((DwarfAttrIgnored, next))
        Err(reason) => Err(reason)
      }
  }
}

///|
fn dwarf_collect_display_name(
  values : Array[DwarfFunctionAttrValue],
) -> String? {
  let mut name : String? = None
  let mut linkage_name : String? = None
  for value in values {
    match value {
      DwarfAttrName(text) => name = Some(text)
      DwarfAttrLinkageName(text) => linkage_name = Some(text)
      _ => ()
    }
  }
  match name {
    Some(text) => Some(text)
    None => linkage_name
  }
}

///|
fn dwarf_collect_function(
  values : Array[DwarfFunctionAttrValue],
  unit_start : Int,
  ranges_section : DwarfSectionBuffer?,
  rnglists_section : DwarfSectionBuffer?,
  addr_section : DwarfSectionBuffer?,
  endian : @bitvec.Endian,
  dwarf_size : DwarfWordSize,
  addr_size : DwarfWordSize,
  version : Int,
  range_base : UInt64,
  rnglists_base : Int?,
  addr_base : Int?,
) -> Result[DwarfFunctionCandidate?, String] {
  let mut name : String? = None
  let mut linkage_name : String? = None
  let mut name_ref : DwarfNameRef? = None
  let mut low_pc : UInt64? = None
  let mut entry_pc : UInt64? = None
  let mut high_abs : UInt64? = None
  let mut high_rel : Int64? = None
  let mut range_ref : DwarfRangeListRef? = None
  for value in values {
    match value {
      DwarfAttrName(text) => name = Some(text)
      DwarfAttrLinkageName(text) => linkage_name = Some(text)
      DwarfAttrLowPc(addr) => low_pc = Some(addr)
      DwarfAttrEntryPc(addr) => entry_pc = Some(addr)
      DwarfAttrHighPcAbs(addr) => high_abs = Some(addr)
      DwarfAttrHighPcRel(offset) => high_rel = Some(offset)
      DwarfAttrRanges(range_item) => range_ref = Some(range_item)
      DwarfAttrNameRef(offset) => name_ref = Some(offset)
      DwarfAttrStrOffsetsBase(_) => ()
      DwarfAttrAddrBase(_) => ()
      DwarfAttrRnglistsBase(_) => ()
      DwarfAttrIgnored => ()
    }
  }
  let ranges = match range_ref {
    Some(DwarfRangeOffset(offset)) if version < 5 => {
      let section = match ranges_section {
        Some(section) => section
        None => return Err("section .debug_ranges is not available")
      }
      let base = match low_pc {
        Some(addr) => addr
        None => range_base
      }
      match
        dwarf_read_ranges_summary(section, offset, base, endian, addr_size) {
        Ok(summary) => summary
        Err(reason) => return Err(reason)
      }
    }
    Some(DwarfRangeOffset(offset)) => {
      let section = match rnglists_section {
        Some(section) => section
        None => return Err("section .debug_rnglists is not available")
      }
      let base = match low_pc {
        Some(addr) => addr
        None => range_base
      }
      match
        dwarf_read_rnglists_summary(
          section, offset, base, endian, addr_size, addr_base, addr_section,
        ) {
        Ok(summary) => summary
        Err(reason) => return Err(reason)
      }
    }
    Some(DwarfRnglistsIndex(index)) => {
      let section = match rnglists_section {
        Some(section) => section
        None => return Err("section .debug_rnglists is not available")
      }
      let rnglists_base = match rnglists_base {
        Some(value) => value
        None => return Err("DW_AT_rnglists_base is not available")
      }
      let offset = match
        dwarf_read_rnglists_index_offset(
          section, index, rnglists_base, endian, dwarf_size,
        ) {
        Ok(offset) => offset
        Err(reason) => return Err(reason)
      }
      let base = match low_pc {
        Some(addr) => addr
        None => range_base
      }
      match
        dwarf_read_rnglists_summary(
          section, offset, base, endian, addr_size, addr_base, addr_section,
        ) {
        Ok(summary) => summary
        Err(reason) => return Err(reason)
      }
    }
    None => None
  }
  let start_pc = match ranges {
    Some(summary) => Some(summary.low)
    None =>
      match low_pc {
        Some(addr) => Some(addr)
        None => entry_pc
      }
  }
  let display_name = match name {
    Some(text) => Some(text)
    None => linkage_name
  }
  let has_name = display_name is Some(_) || name_ref is Some(_)
  match (has_name, start_pc) {
    (true, Some(start)) => {
      let high = match ranges {
        Some(summary) => Some(summary.high)
        None =>
          match high_abs {
            Some(addr) => Some(addr)
            None =>
              match (low_pc, high_rel) {
                (Some(low), Some(offset)) if offset >= 0L =>
                  Some(low + offset.reinterpret_as_uint64())
                _ => None
              }
          }
      }
      Ok(
        Some({
          unit_start,
          name: display_name,
          name_ref,
          low_pc: start,
          high_pc: high,
        }),
      )
    }
    _ => Ok(None)
  }
}

///|
fn dwarf_collect_str_offsets_base(
  values : Array[DwarfFunctionAttrValue],
) -> Int? {
  for value in values {
    match value {
      DwarfAttrStrOffsetsBase(base) => return Some(base)
      _ => ()
    }
  }
  None
}

///|
fn dwarf_collect_addr_base(values : Array[DwarfFunctionAttrValue]) -> Int? {
  for value in values {
    match value {
      DwarfAttrAddrBase(base) => return Some(base)
      _ => ()
    }
  }
  None
}

///|
fn dwarf_collect_rnglists_base(values : Array[DwarfFunctionAttrValue]) -> Int? {
  for value in values {
    match value {
      DwarfAttrRnglistsBase(base) => return Some(base)
      _ => ()
    }
  }
  None
}

///|
fn dwarf_collect_range_base(values : Array[DwarfFunctionAttrValue]) -> UInt64? {
  for value in values {
    match value {
      DwarfAttrLowPc(addr) => return Some(addr)
      _ => ()
    }
  }
  None
}

///|
fn dwarf_read_die(
  input : DwarfInput,
  entry : DwarfAbbrevEntry,
  endian : @bitvec.Endian,
  dwarf_size : DwarfWordSize,
  addr_size : DwarfWordSize,
  version : Int,
  addr_base : Int?,
  str_offsets_base : Int,
  rnglists_base : Int?,
  addr_section : DwarfSectionBuffer?,
  line_str_section : DwarfSectionBuffer?,
  str_offsets_section : DwarfSectionBuffer?,
  str_section : DwarfSectionBuffer,
  ranges_section : DwarfSectionBuffer?,
  rnglists_section : DwarfSectionBuffer?,
  range_base : UInt64,
  unit_start : Int,
) -> Result[
  (DwarfFunctionCandidate?, String?, Int?, Int?, Int?, UInt64?, DwarfInput),
  String,
] {
  let values : Array[DwarfFunctionAttrValue] = []
  let mut cursor = input
  for field in entry.fields() {
    if entry.captures_values() ||
      field.attr() == DwarfStrOffsetsBase ||
      field.attr() == DwarfAddrBase ||
      field.attr() == DwarfRnglistsBase ||
      field.attr() == DwarfLowPc {
      match
        dwarf_read_attr_value(
          cursor, field, endian, dwarf_size, addr_size, addr_base, addr_section,
          str_offsets_base, line_str_section, str_offsets_section, str_section,
        ) {
        Ok((value, next)) => {
          values.push(value)
          cursor = next
        }
        Err(reason) => return Err(reason)
      }
    } else {
      match
        dwarf_skip_form(cursor, field.form(), endian, dwarf_size, addr_size) {
        Ok(next) => cursor = next
        Err(reason) => return Err(reason)
      }
    }
  }
  let function_item = match
    dwarf_collect_function(
      values, unit_start, ranges_section, rnglists_section, addr_section, endian,
      dwarf_size, addr_size, version, range_base, rnglists_base, addr_base,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok(
    (
      function_item,
      dwarf_collect_display_name(values),
      dwarf_collect_str_offsets_base(values),
      dwarf_collect_addr_base(values),
      dwarf_collect_rnglists_base(values),
      dwarf_collect_range_base(values),
      cursor,
    ),
  )
}

///|
fn dwarf_read_unit_header(
  input : DwarfInput,
  version : Int,
  endian : @bitvec.Endian,
  dwarf_size : DwarfWordSize,
) -> Result[(Int, DwarfWordSize, DwarfInput), String] {
  if version >= 5 {
    match input.read_byte() {
      Ok((_, after_unit_type)) =>
        match after_unit_type.read_address_size() {
          Ok((addr_size, after_addr_size)) =>
            match after_addr_size.read_offset(endian~, size=dwarf_size) {
              Ok((abbrev_offset, after_offset)) =>
                Ok((abbrev_offset, addr_size, after_offset))
              Err(reason) => Err(reason)
            }
          Err(reason) => Err(reason)
        }
      Err(reason) => Err(reason)
    }
  } else {
    match input.read_offset(endian~, size=dwarf_size) {
      Ok((abbrev_offset, after_offset)) =>
        match after_offset.read_address_size() {
          Ok((addr_size, after_header)) =>
            Ok((abbrev_offset, addr_size, after_header))
          Err(reason) => Err(reason)
        }
      Err(reason) => Err(reason)
    }
  }
}

///|
fn dwarf_update_str_offsets_base(base : Int?, value : Int) -> Int {
  match base {
    Some(next) => next
    None => value
  }
}

///|
fn dwarf_current_scope(scopes : Array[DwarfScope]) -> DwarfScope {
  scopes[scopes.length() - 1]
}

///|
fn dwarf_current_range_base(scopes : Array[DwarfScope]) -> UInt64 {
  dwarf_current_scope(scopes).range_base
}

///|
fn dwarf_pop_scope(scopes : Array[DwarfScope]) -> Unit {
  if scopes.length() > 1 {
    ignore(scopes.pop())
  }
}

///|
fn dwarf_parse_unit(
  info : DwarfInput,
  abbrev_section : DwarfSectionBuffer,
  str_section : DwarfSectionBuffer,
  line_str_section : DwarfSectionBuffer?,
  str_offsets_section : DwarfSectionBuffer?,
  addr_section : DwarfSectionBuffer?,
  ranges_section : DwarfSectionBuffer?,
  rnglists_section : DwarfSectionBuffer?,
  endian : @bitvec.Endian,
) -> Result[DwarfParsedUnit, String] {
  match info.read_unit_size(endian~) {
    Ok(((dwarf_size, unit_size), after_size)) => {
      let unit_start = info.position()
      let cu_end = after_size.position() + unit_size
      match after_size.read_version() {
        Ok((version, after_version)) =>
          match
            dwarf_read_unit_header(after_version, version, endian, dwarf_size) {
            Ok((abbrev_offset, addr_size, after_header)) => {
              let table = match abbrev_section.offset(abbrev_offset) {
                Ok(buffer) =>
                  match DwarfAbbrevTable::read(buffer.input()) {
                    Ok((table, _)) => table
                    Err(reason) => return Err(reason)
                  }
                Err(reason) => return Err(reason)
              }
              let function_candidates : Array[DwarfFunctionCandidate] = []
              let die_names : Array[DwarfDieName] = []
              let mut cursor = after_header
              let mut str_offsets_base = 0
              let mut addr_base : Int? = None
              let mut rnglists_base : Int? = None
              let scopes : Array[DwarfScope] = [{ range_base: 0UL }]
              while cursor.position() < cu_end {
                let die_offset = cursor.position() - info.position()
                match cursor.read_code() {
                  Ok((0, next)) => {
                    dwarf_pop_scope(scopes)
                    cursor = next
                  }
                  Ok((code, after_code)) =>
                    match table.lookup(code) {
                      Some(entry) =>
                        match
                          dwarf_read_die(
                            after_code,
                            entry,
                            endian,
                            dwarf_size,
                            addr_size,
                            version,
                            addr_base,
                            str_offsets_base,
                            rnglists_base,
                            addr_section,
                            line_str_section,
                            str_offsets_section,
                            str_section,
                            ranges_section,
                            rnglists_section,
                            dwarf_current_range_base(scopes),
                            unit_start,
                          ) {
                          Ok(
                            (
                              function_item,
                              die_name,
                              str_base,
                              next_addr_base,
                              next_rnglists_base,
                              next_range_base,
                              next,
                            )
                          ) => {
                            match function_item {
                              Some(value) => function_candidates.push(value)
                              None => ()
                            }
                            match die_name {
                              Some(name) =>
                                die_names.push({
                                  unit_start,
                                  unit_offset: die_offset,
                                  section_offset: cursor.position(),
                                  name,
                                })
                              None => ()
                            }
                            str_offsets_base = dwarf_update_str_offsets_base(
                              str_base, str_offsets_base,
                            )
                            match next_addr_base {
                              Some(value) => addr_base = Some(value)
                              None => ()
                            }
                            match next_rnglists_base {
                              Some(value) => rnglists_base = Some(value)
                              None => ()
                            }
                            if entry.has_children() {
                              let child_range_base = match next_range_base {
                                Some(value) => value
                                None => dwarf_current_range_base(scopes)
                              }
                              scopes.push({ range_base: child_range_base })
                            }
                            cursor = next
                          }
                          Err(reason) => return Err(reason)
                        }
                      None =>
                        return Err("unknown DWARF abbreviation code: \{code}")
                    }
                  Err(reason) => return Err(reason)
                }
              }
              if cursor.position() > cu_end {
                Err("DWARF compilation unit over-read")
              } else {
                Ok({
                  function_candidates,
                  die_names,
                  next: cursor.with_position(cu_end),
                })
              }
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
fn dwarf_remaining_is_zero_padding(input : DwarfInput) -> Bool {
  let mut index = input.position()
  while index < input.data.length() {
    if input.data[index] != b'\x00' {
      return false
    }
    index = index + 1
  }
  true
}

///|
fn dwarf_resolve_function_candidates(
  candidates : Array[DwarfFunctionCandidate],
  die_names : Array[DwarfDieName],
) -> Array[DwarfFunction] {
  let functions : Array[DwarfFunction] = []
  for candidate in candidates {
    match candidate.resolve(die_names) {
      Some(function_item) => functions.push(function_item)
      None => ()
    }
  }
  functions
}

///|
pub fn DwarfData::functions(
  self : DwarfData,
) -> Result[Array[DwarfFunction], String] {
  let info_section = match self.section(DwarfInfo) {
    Ok(section) => section
    Err(reason) => return Err(reason)
  }
  let abbrev_section = match self.section(DwarfAbbrev) {
    Ok(section) => section
    Err(reason) => return Err(reason)
  }
  let str_section = match self.section(DwarfStr) {
    Ok(section) => section
    Err(reason) => return Err(reason)
  }
  let str_offsets_section = match self.section(DwarfStrOffsets) {
    Ok(section) => Some(section)
    Err(_) => None
  }
  let line_str_section = match self.section(DwarfLineStr) {
    Ok(section) => Some(section)
    Err(_) => None
  }
  let addr_section = match self.section(DwarfAddr) {
    Ok(section) => Some(section)
    Err(_) => None
  }
  let ranges_section = match self.section(DwarfRanges) {
    Ok(section) => Some(section)
    Err(_) => None
  }
  let rnglists_section = match self.section(DwarfRnglists) {
    Ok(section) => Some(section)
    Err(_) => None
  }
  let function_candidates : Array[DwarfFunctionCandidate] = []
  let die_names : Array[DwarfDieName] = []
  let mut cursor = info_section.input()
  while cursor.remaining() > 0 {
    if dwarf_remaining_is_zero_padding(cursor) {
      return Ok(
        dwarf_resolve_function_candidates(function_candidates, die_names),
      )
    }
    match
      dwarf_parse_unit(
        cursor,
        abbrev_section,
        str_section,
        line_str_section,
        str_offsets_section,
        addr_section,
        ranges_section,
        rnglists_section,
        self.endian(),
      ) {
      Ok(unit) => {
        for function_item in unit.function_candidates {
          function_candidates.push(function_item)
        }
        for die_name in unit.die_names {
          die_names.push(die_name)
        }
        cursor = unit.next
      }
      Err(reason) => return Err(reason)
    }
  }
  Ok(dwarf_resolve_function_candidates(function_candidates, die_names))
}
