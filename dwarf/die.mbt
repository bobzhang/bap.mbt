///|
struct DwarfDie {
  section_offset_value : Int
  unit_offset_value : Int
  depth_value : Int
  code_value : Int
  entry_value : DwarfAbbrevEntry
  attributes_value : Array[DwarfDieAttribute]
  attributes_offset_value : Int
  end_offset_value : Int
}

///|
struct DwarfDieAttribute {
  index_value : Int
  field_value : DwarfAbbrevField
  offset_value : Int
  end_offset_value : Int
}

///|
pub(all) enum DwarfDieReference {
  DwarfUnitReference(Int)
  DwarfSectionReference(Int)
  DwarfSupplementaryReference(Int)
  DwarfAlternateReference(Int)
  DwarfTypeSignatureReference(UInt64)
} derive(Eq, Debug)

///|
pub fn DwarfDieReference::section_offset(
  self : DwarfDieReference,
  unit_start~ : Int,
) -> Result[Int, String] {
  if unit_start < 0 {
    return Err("negative DWARF unit start offset")
  }
  match self {
    DwarfUnitReference(offset) =>
      if offset < 0 {
        Err("negative DWARF reference offset")
      } else {
        let target = unit_start + offset
        if target < unit_start {
          Err("DWARF reference offset overflow")
        } else {
          Ok(target)
        }
      }
    DwarfSectionReference(offset) =>
      if offset < 0 {
        Err("negative DWARF reference offset")
      } else {
        Ok(offset)
      }
    DwarfSupplementaryReference(_) | DwarfAlternateReference(_) =>
      Err("DWARF DIE reference targets external debug data")
    DwarfTypeSignatureReference(_) =>
      Err("DWARF type-signature reference is not a section offset")
  }
}

///|
fn dwarf_die_create(
  section_offset~ : Int,
  unit_offset~ : Int,
  depth~ : Int,
  code~ : Int,
  entry~ : DwarfAbbrevEntry,
  attributes~ : Array[DwarfDieAttribute],
  attributes_offset~ : Int,
  end_offset~ : Int,
) -> DwarfDie {
  {
    section_offset_value: section_offset,
    unit_offset_value: unit_offset,
    depth_value: depth,
    code_value: code,
    entry_value: entry,
    attributes_value: attributes.copy(),
    attributes_offset_value: attributes_offset,
    end_offset_value: end_offset,
  }
}

///|
fn dwarf_die_attribute_create(
  index~ : Int,
  field~ : DwarfAbbrevField,
  offset~ : Int,
  end_offset~ : Int,
) -> DwarfDieAttribute {
  {
    index_value: index,
    field_value: field,
    offset_value: offset,
    end_offset_value: end_offset,
  }
}

///|
fn dwarf_die_attribute_check_bounds(
  attribute : DwarfDieAttribute,
  info : DwarfSectionBuffer,
) -> Result[Unit, String] {
  if attribute.offset_value < 0 ||
    attribute.end_offset_value < attribute.offset_value ||
    attribute.end_offset_value > info.data().length() {
    Err("DWARF DIE attribute span is out of bounds")
  } else {
    Ok(())
  }
}

///|
fn[T] dwarf_die_attribute_finish(
  attribute : DwarfDieAttribute,
  value : T,
  next : DwarfInput,
) -> Result[T, String] {
  if next.position() == attribute.end_offset_value {
    Ok(value)
  } else {
    Err("DWARF DIE attribute reader did not consume payload")
  }
}

///|
fn dwarf_die_attribute_finish_uint_reference(
  attribute : DwarfDieAttribute,
  offset : UInt64,
  next : DwarfInput,
  make : (Int) -> DwarfDieReference,
) -> Result[DwarfDieReference, String] {
  match dwarf_ref_uint_offset_to_int(offset) {
    Ok(value) => dwarf_die_attribute_finish(attribute, make(value), next)
    Err(reason) => Err(reason)
  }
}

///|
fn dwarf_die_index(dies : Array[DwarfDie], die : DwarfDie) -> Int? {
  dies.search_by(item => item.section_offset() == die.section_offset())
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
) -> Result[(Array[DwarfDieAttribute], DwarfInput), String] {
  let out : Array[DwarfDieAttribute] = []
  let mut cursor = input
  let mut index = 0
  for field in entry.fields() {
    let offset = cursor.position()
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
        out.push(
          dwarf_die_attribute_create(
            index~,
            field~,
            offset~,
            end_offset=next.position(),
          ),
        )
        cursor = next
        index += 1
      }
      Err(reason) => return Err(reason)
    }
  }
  Ok((out, cursor))
}

///|
pub fn DwarfDieAttribute::index(self : DwarfDieAttribute) -> Int {
  self.index_value
}

///|
pub fn DwarfDieAttribute::field(self : DwarfDieAttribute) -> DwarfAbbrevField {
  self.field_value
}

///|
pub fn DwarfDieAttribute::attr(self : DwarfDieAttribute) -> DwarfAttr {
  self.field_value.attr()
}

///|
pub fn DwarfDieAttribute::form(self : DwarfDieAttribute) -> DwarfForm {
  self.field_value.form()
}

///|
pub fn DwarfDieAttribute::value_kind(
  self : DwarfDieAttribute,
) -> DwarfAbbrevValueKind {
  self.field_value.value_kind()
}

///|
pub fn DwarfDieAttribute::is_value_field(self : DwarfDieAttribute) -> Bool {
  self.field_value.is_value_field()
}

///|
pub fn DwarfDieAttribute::offset(self : DwarfDieAttribute) -> Int {
  self.offset_value
}

///|
pub fn DwarfDieAttribute::end_offset(self : DwarfDieAttribute) -> Int {
  self.end_offset_value
}

///|
pub fn DwarfDieAttribute::payload(
  self : DwarfDieAttribute,
  info : DwarfSectionBuffer,
) -> Result[Bytes, String] {
  match dwarf_die_attribute_check_bounds(self, info) {
    Ok(_) => Ok(info.data()[self.offset_value:self.end_offset_value].to_owned())
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfDieAttribute::input(
  self : DwarfDieAttribute,
  info : DwarfSectionBuffer,
) -> Result[DwarfInput, String] {
  match dwarf_die_attribute_check_bounds(self, info) {
    Ok(_) =>
      match info.with_position(self.offset_value) {
        Ok(buffer) => Ok(buffer.input())
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfDieAttribute::string(
  self : DwarfDieAttribute,
  info : DwarfSectionBuffer,
) -> Result[String, String] {
  match self.form() {
    DwarfString =>
      match self.input(info) {
        Ok(input) =>
          match input.read_cstring() {
            Ok((value, next)) => dwarf_die_attribute_finish(self, value, next)
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    _ => Err("DWARF DIE attribute is not an inline string")
  }
}

///|
pub fn DwarfDieAttribute::address(
  self : DwarfDieAttribute,
  info : DwarfSectionBuffer,
  endian~ : @bitvec.Endian,
  addr_size~ : DwarfWordSize,
) -> Result[UInt64, String] {
  match self.form() {
    DwarfAddr =>
      match self.input(info) {
        Ok(input) =>
          match input.read_address(endian~, size=addr_size) {
            Ok((value, next)) => dwarf_die_attribute_finish(self, value, next)
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    _ => Err("DWARF DIE attribute is not an address")
  }
}

///|
pub fn DwarfDieAttribute::section_offset_value(
  self : DwarfDieAttribute,
  info : DwarfSectionBuffer,
  endian~ : @bitvec.Endian,
  dwarf_size~ : DwarfWordSize,
) -> Result[Int, String] {
  match self.form() {
    DwarfStrp
    | DwarfLineStrp
    | DwarfStrpSup
    | DwarfStrpAlt
    | DwarfOffset
    | DwarfRefAlt =>
      match self.input(info) {
        Ok(input) =>
          match input.read_offset(endian~, size=dwarf_size) {
            Ok((value, next)) => dwarf_die_attribute_finish(self, value, next)
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    _ => Err("DWARF DIE attribute is not a section offset")
  }
}

///|
pub fn DwarfDieAttribute::index_value(
  self : DwarfDieAttribute,
  info : DwarfSectionBuffer,
  endian~ : @bitvec.Endian,
) -> Result[Int, String] {
  let read = match self.form() {
    DwarfStrx(spec) | DwarfAddrx(spec) =>
      (input : DwarfInput) => input.read_index(spec, endian)
    DwarfRnglistx | DwarfLoclistx => (input : DwarfInput) => input.read_code()
    _ => return Err("DWARF DIE attribute is not an index")
  }
  match self.input(info) {
    Ok(input) =>
      match read(input) {
        Ok((value, next)) =>
          if value < 0 {
            Err("negative DWARF index")
          } else {
            dwarf_die_attribute_finish(self, value, next)
          }
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfDieAttribute::reference(
  self : DwarfDieAttribute,
  info : DwarfSectionBuffer,
  endian~ : @bitvec.Endian,
  version~ : Int,
  dwarf_size~ : DwarfWordSize,
  addr_size~ : DwarfWordSize,
) -> Result[DwarfDieReference, String] {
  match self.form() {
    DwarfRef(lenspec) =>
      match self.input(info) {
        Ok(input) =>
          match input.read_unsigned_const(lenspec, endian) {
            Ok((offset, next)) =>
              dwarf_die_attribute_finish_uint_reference(self, offset, next, value => {
                DwarfUnitReference(value)
              })
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    DwarfRefAddr =>
      match self.input(info) {
        Ok(input) =>
          match
            dwarf_read_ref_addr_offset(
              input, endian, version, dwarf_size, addr_size,
            ) {
            Ok((value, next)) =>
              dwarf_die_attribute_finish(
                self,
                DwarfSectionReference(value),
                next,
              )
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    DwarfRefSup4 =>
      match self.input(info) {
        Ok(input) =>
          match input.read_unsigned_const(DwarfFour, endian) {
            Ok((offset, next)) =>
              dwarf_die_attribute_finish_uint_reference(self, offset, next, value => {
                DwarfSupplementaryReference(value)
              })
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    DwarfRefSup8 =>
      match self.input(info) {
        Ok(input) =>
          match input.read_unsigned_const(DwarfEight, endian) {
            Ok((offset, next)) =>
              dwarf_die_attribute_finish_uint_reference(self, offset, next, value => {
                DwarfSupplementaryReference(value)
              })
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    DwarfRefAlt =>
      match self.input(info) {
        Ok(input) =>
          match input.read_offset(endian~, size=dwarf_size) {
            Ok((value, next)) =>
              dwarf_die_attribute_finish(
                self,
                DwarfAlternateReference(value),
                next,
              )
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    DwarfRefSig8 =>
      match self.input(info) {
        Ok(input) =>
          match input.read_unsigned_const(DwarfEight, endian) {
            Ok((signature, next)) =>
              dwarf_die_attribute_finish(
                self,
                DwarfTypeSignatureReference(signature),
                next,
              )
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    _ => Err("DWARF DIE attribute is not a reference")
  }
}

///|
pub fn DwarfDieAttribute::const_value(
  self : DwarfDieAttribute,
  info : DwarfSectionBuffer,
  endian~ : @bitvec.Endian,
) -> Result[Int64, String] {
  match self.form() {
    DwarfImplicitConst(value) =>
      if self.offset_value == self.end_offset_value {
        Ok(value)
      } else {
        Err("DWARF implicit const attribute has a payload span")
      }
    DwarfConst(lenspec) | DwarfSignedConst(lenspec) =>
      match self.input(info) {
        Ok(input) =>
          match input.read_const(lenspec~, endian~) {
            Ok((value, next)) => dwarf_die_attribute_finish(self, value, next)
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    _ => Err("DWARF DIE attribute is not a constant")
  }
}

///|
pub fn DwarfDieAttribute::block(
  self : DwarfDieAttribute,
  info : DwarfSectionBuffer,
  endian~ : @bitvec.Endian,
) -> Result[Bytes, String] {
  let lenspec = match self.form() {
    DwarfBlock(spec) => spec
    DwarfExpr => DwarfLeb128
    _ => return Err("DWARF DIE attribute is not a block")
  }
  match self.input(info) {
    Ok(input) =>
      match input.read_block(lenspec~, endian~) {
        Ok((value, next)) => dwarf_die_attribute_finish(self, value, next)
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfDieAttribute::flag(
  self : DwarfDieAttribute,
  info : DwarfSectionBuffer,
) -> Result[Bool, String] {
  match self.form() {
    DwarfFlagPresent =>
      if self.offset_value == self.end_offset_value {
        Ok(true)
      } else {
        Err("DWARF flag-present attribute has a payload span")
      }
    DwarfFlag =>
      match self.input(info) {
        Ok(input) =>
          match input.read_byte() {
            Ok((value, next)) =>
              dwarf_die_attribute_finish(self, value != 0, next)
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    _ => Err("DWARF DIE attribute is not a flag")
  }
}

///|
pub fn DwarfDie::section_offset(self : DwarfDie) -> Int {
  self.section_offset_value
}

///|
pub fn DwarfDie::unit_start_offset(self : DwarfDie) -> Int {
  self.section_offset_value - self.unit_offset_value
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
pub fn DwarfDie::attributes(self : DwarfDie) -> Array[DwarfDieAttribute] {
  self.attributes_value.copy()
}

///|
pub fn DwarfDie::attribute(
  self : DwarfDie,
  attr : DwarfAttr,
) -> DwarfDieAttribute? {
  match self.attributes_value.search_by(attribute => attribute.attr() == attr) {
    Some(index) => Some(self.attributes_value[index])
    None => None
  }
}

///|
pub fn DwarfDie::attributes_by_attr(
  self : DwarfDie,
  attr : DwarfAttr,
) -> Array[DwarfDieAttribute] {
  self.attributes_value.filter(attribute => attribute.attr() == attr)
}

///|
pub fn DwarfDie::parent(self : DwarfDie, dies : Array[DwarfDie]) -> DwarfDie? {
  if self.depth_value <= 0 {
    return None
  }
  match dwarf_die_index(dies, self) {
    Some(index) => {
      let parent_depth = self.depth_value - 1
      let mut cursor = index - 1
      while cursor >= 0 {
        let candidate = dies[cursor]
        if candidate.depth() == parent_depth {
          return Some(candidate)
        }
        cursor -= 1
      }
      None
    }
    None => None
  }
}

///|
pub fn DwarfDie::direct_children(
  self : DwarfDie,
  dies : Array[DwarfDie],
) -> Array[DwarfDie] {
  let out : Array[DwarfDie] = []
  match dwarf_die_index(dies, self) {
    Some(index) => {
      let child_depth = self.depth_value + 1
      let mut cursor = index + 1
      while cursor < dies.length() && dies[cursor].depth() > self.depth_value {
        let candidate = dies[cursor]
        if candidate.depth() == child_depth {
          out.push(candidate)
        }
        cursor += 1
      }
      out
    }
    None => out
  }
}

///|
pub fn DwarfDie::descendants(
  self : DwarfDie,
  dies : Array[DwarfDie],
) -> Array[DwarfDie] {
  let out : Array[DwarfDie] = []
  match dwarf_die_index(dies, self) {
    Some(index) => {
      let mut cursor = index + 1
      while cursor < dies.length() && dies[cursor].depth() > self.depth_value {
        out.push(dies[cursor])
        cursor += 1
      }
      out
    }
    None => out
  }
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
              Ok((attributes, next)) => {
                out.push(
                  dwarf_die_create(
                    section_offset~,
                    unit_offset~,
                    depth~,
                    code~,
                    entry~,
                    attributes~,
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
pub fn DwarfData::die_by_section_offset(
  self : DwarfData,
  offset : Int,
) -> Result[DwarfDie?, String] {
  if offset < 0 {
    return Err("negative DWARF DIE section offset")
  }
  match self.dies() {
    Ok(dies) =>
      match dies.search_by(die => die.section_offset() == offset) {
        Some(index) => Ok(Some(dies[index]))
        None => Ok(None)
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfData::referenced_die(
  self : DwarfData,
  reference : DwarfDieReference,
  unit_start~ : Int,
) -> Result[DwarfDie?, String] {
  match reference.section_offset(unit_start~) {
    Ok(offset) => self.die_by_section_offset(offset)
    Err(reason) => Err(reason)
  }
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
