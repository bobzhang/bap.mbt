///|
struct DwarfFunction {
  name_value : String
  low_pc_value : UInt64
  high_pc_value : UInt64?
}

///|
priv enum DwarfFunctionAttrValue {
  DwarfAttrName(String)
  DwarfAttrLowPc(UInt64)
  DwarfAttrEntryPc(UInt64)
  DwarfAttrHighPcAbs(UInt64)
  DwarfAttrHighPcRel(Int64)
  DwarfAttrStrOffsetsBase(Int)
  DwarfAttrIgnored
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
    DwarfStrp | DwarfOffset =>
      match input.read_offset(endian~, size=dwarf_size) {
        Ok((_, next)) => Ok(next)
        Err(reason) => Err(reason)
      }
    DwarfStrx(spec) =>
      match input.read_index(spec, endian) {
        Ok((_, next)) => Ok(next)
        Err(reason) => Err(reason)
      }
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
fn dwarf_read_attr_value(
  input : DwarfInput,
  field : DwarfAbbrevField,
  endian : @bitvec.Endian,
  dwarf_size : DwarfWordSize,
  addr_size : DwarfWordSize,
  str_offsets_base : Int,
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
            str_offsets_base,
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
            Ok((name, next)) => Ok((DwarfAttrName(name), next))
            Err(reason) => Err(reason)
          }
        DwarfStrp =>
          match dwarf_read_strp_name(input, endian, dwarf_size, str_section) {
            Ok((name, next)) => Ok((DwarfAttrName(name), next))
            Err(reason) => Err(reason)
          }
        DwarfStrx(spec) =>
          match
            dwarf_read_strx_name(
              input, spec, endian, dwarf_size, str_offsets_base, str_offsets_section,
              str_section,
            ) {
            Ok((name, next)) => Ok((DwarfAttrName(name), next))
            Err(reason) => Err(reason)
          }
        form =>
          match dwarf_skip_form(input, form, endian, dwarf_size, addr_size) {
            Ok(next) => Ok((DwarfAttrIgnored, next))
            Err(reason) => Err(reason)
          }
      }
    DwarfLowPcValue =>
      match input.read_address(endian~, size=addr_size) {
        Ok((addr, next)) => Ok((DwarfAttrLowPc(addr), next))
        Err(reason) => Err(reason)
      }
    DwarfEntryPcValue =>
      match input.read_address(endian~, size=addr_size) {
        Ok((addr, next)) => Ok((DwarfAttrEntryPc(addr), next))
        Err(reason) => Err(reason)
      }
    DwarfHighPcAddressValue =>
      match input.read_address(endian~, size=addr_size) {
        Ok((addr, next)) => Ok((DwarfAttrHighPcAbs(addr), next))
        Err(reason) => Err(reason)
      }
    DwarfHighPcOffsetValue =>
      match field.form() {
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
    DwarfStrOffsetsBaseValue =>
      match input.read_offset(endian~, size=dwarf_size) {
        Ok((base, next)) => Ok((DwarfAttrStrOffsetsBase(base), next))
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
fn dwarf_collect_function(
  values : Array[DwarfFunctionAttrValue],
) -> DwarfFunction? {
  let mut name : String? = None
  let mut low_pc : UInt64? = None
  let mut entry_pc : UInt64? = None
  let mut high_abs : UInt64? = None
  let mut high_rel : Int64? = None
  for value in values {
    match value {
      DwarfAttrName(text) => name = Some(text)
      DwarfAttrLowPc(addr) => low_pc = Some(addr)
      DwarfAttrEntryPc(addr) => entry_pc = Some(addr)
      DwarfAttrHighPcAbs(addr) => high_abs = Some(addr)
      DwarfAttrHighPcRel(offset) => high_rel = Some(offset)
      DwarfAttrStrOffsetsBase(_) => ()
      DwarfAttrIgnored => ()
    }
  }
  let start_pc = match low_pc {
    Some(addr) => Some(addr)
    None => entry_pc
  }
  match (name, start_pc) {
    (Some(text), Some(start)) => {
      let high = match high_abs {
        Some(addr) => Some(addr)
        None =>
          match (low_pc, high_rel) {
            (Some(low), Some(offset)) if offset >= 0L =>
              Some(low + offset.reinterpret_as_uint64())
            _ => None
          }
      }
      Some(DwarfFunction::create(name=text, low_pc=start, high_pc?=high))
    }
    _ => None
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
fn dwarf_read_die(
  input : DwarfInput,
  entry : DwarfAbbrevEntry,
  endian : @bitvec.Endian,
  dwarf_size : DwarfWordSize,
  addr_size : DwarfWordSize,
  str_offsets_base : Int,
  str_offsets_section : DwarfSectionBuffer?,
  str_section : DwarfSectionBuffer,
) -> Result[(DwarfFunction?, Int?, DwarfInput), String] {
  let values : Array[DwarfFunctionAttrValue] = []
  let mut cursor = input
  for field in entry.fields() {
    if entry.captures_values() || field.attr() == DwarfStrOffsetsBase {
      match
        dwarf_read_attr_value(
          cursor, field, endian, dwarf_size, addr_size, str_offsets_base, str_offsets_section,
          str_section,
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
  Ok(
    (
      dwarf_collect_function(values),
      dwarf_collect_str_offsets_base(values),
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
fn dwarf_parse_unit(
  info : DwarfInput,
  abbrev_section : DwarfSectionBuffer,
  str_section : DwarfSectionBuffer,
  str_offsets_section : DwarfSectionBuffer?,
  endian : @bitvec.Endian,
) -> Result[(Array[DwarfFunction], DwarfInput), String] {
  match info.read_unit_size(endian~) {
    Ok(((dwarf_size, unit_size), after_size)) => {
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
              let functions : Array[DwarfFunction] = []
              let mut cursor = after_header
              let mut str_offsets_base = 0
              while cursor.position() < cu_end {
                match cursor.read_code() {
                  Ok((0, next)) => cursor = next
                  Ok((code, after_code)) =>
                    match table.lookup(code) {
                      Some(entry) =>
                        match
                          dwarf_read_die(
                            after_code, entry, endian, dwarf_size, addr_size, str_offsets_base,
                            str_offsets_section, str_section,
                          ) {
                          Ok((Some(function_item), base, next)) => {
                            functions.push(function_item)
                            str_offsets_base = dwarf_update_str_offsets_base(
                              base, str_offsets_base,
                            )
                            cursor = next
                          }
                          Ok((None, base, next)) => {
                            str_offsets_base = dwarf_update_str_offsets_base(
                              base, str_offsets_base,
                            )
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
                Ok((functions, cursor.with_position(cu_end)))
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
  let functions : Array[DwarfFunction] = []
  let mut cursor = info_section.input()
  while cursor.remaining() > 0 {
    if dwarf_remaining_is_zero_padding(cursor) {
      return Ok(functions)
    }
    match
      dwarf_parse_unit(
        cursor,
        abbrev_section,
        str_section,
        str_offsets_section,
        self.endian(),
      ) {
      Ok((unit_functions, next)) => {
        for function_item in unit_functions {
          functions.push(function_item)
        }
        cursor = next
      }
      Err(reason) => return Err(reason)
    }
  }
  Ok(functions)
}
