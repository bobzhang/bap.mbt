///|
pub(all) enum DwarfAbbrevValueKind {
  DwarfIgnoredValue
  DwarfNameValue
  DwarfLowPcValue
  DwarfEntryPcValue
  DwarfHighPcAddressValue
  DwarfHighPcOffsetValue
  DwarfRangesValue
  DwarfStrOffsetsBaseValue
  DwarfAddrBaseValue
  DwarfRnglistsBaseValue
} derive(Eq, Debug)

///|
struct DwarfAbbrevField {
  attr_value : DwarfAttr
  form_value : DwarfForm
}

///|
struct DwarfAbbrevEntry {
  code_value : Int
  tag_value : DwarfTag
  has_children_value : Bool
  fields_value : Array[DwarfAbbrevField]
}

///|
struct DwarfAbbrevTable {
  entries_value : Array[DwarfAbbrevEntry]
}

///|
pub fn DwarfAbbrevField::create(
  attr~ : DwarfAttr,
  form~ : DwarfForm,
) -> DwarfAbbrevField {
  { attr_value: attr, form_value: form }
}

///|
pub fn DwarfAbbrevField::attr(self : DwarfAbbrevField) -> DwarfAttr {
  self.attr_value
}

///|
pub fn DwarfAbbrevField::form(self : DwarfAbbrevField) -> DwarfForm {
  self.form_value
}

///|
pub fn DwarfAbbrevField::value_kind(
  self : DwarfAbbrevField,
) -> DwarfAbbrevValueKind {
  match (self.attr_value, self.form_value) {
    (DwarfName, DwarfString)
    | (DwarfName, DwarfStrp)
    | (DwarfName, DwarfStrx(_))
    | (DwarfLinkageName, DwarfString)
    | (DwarfLinkageName, DwarfStrp)
    | (DwarfLinkageName, DwarfStrx(_)) => DwarfNameValue
    (DwarfLowPc, DwarfAddr) | (DwarfLowPc, DwarfAddrx(_)) => DwarfLowPcValue
    (DwarfEntryPc, DwarfAddr) | (DwarfEntryPc, DwarfAddrx(_)) =>
      DwarfEntryPcValue
    (DwarfHighPc, DwarfAddr) | (DwarfHighPc, DwarfAddrx(_)) =>
      DwarfHighPcAddressValue
    (DwarfHighPc, DwarfConst(_)) => DwarfHighPcOffsetValue
    (DwarfRanges, DwarfOffset) | (DwarfRanges, DwarfRnglistx) =>
      DwarfRangesValue
    (DwarfStrOffsetsBase, DwarfOffset) => DwarfStrOffsetsBaseValue
    (DwarfAddrBase, DwarfOffset) => DwarfAddrBaseValue
    (DwarfRnglistsBase, DwarfOffset) => DwarfRnglistsBaseValue
    _ => DwarfIgnoredValue
  }
}

///|
pub fn DwarfAbbrevField::is_value_field(self : DwarfAbbrevField) -> Bool {
  self.value_kind() != DwarfIgnoredValue
}

///|
pub fn DwarfAbbrevEntry::create(
  code~ : Int,
  tag~ : DwarfTag,
  has_children~ : Bool,
  fields~ : Array[DwarfAbbrevField],
) -> DwarfAbbrevEntry {
  {
    code_value: code,
    tag_value: tag,
    has_children_value: has_children,
    fields_value: fields.copy(),
  }
}

///|
pub fn DwarfAbbrevEntry::code(self : DwarfAbbrevEntry) -> Int {
  self.code_value
}

///|
pub fn DwarfAbbrevEntry::tag(self : DwarfAbbrevEntry) -> DwarfTag {
  self.tag_value
}

///|
pub fn DwarfAbbrevEntry::has_children(self : DwarfAbbrevEntry) -> Bool {
  self.has_children_value
}

///|
pub fn DwarfAbbrevEntry::fields(
  self : DwarfAbbrevEntry,
) -> Array[DwarfAbbrevField] {
  self.fields_value.copy()
}

///|
pub fn DwarfAbbrevEntry::captures_values(self : DwarfAbbrevEntry) -> Bool {
  match self.tag_value {
    DwarfSubprogram | DwarfEntryPoint | DwarfInlinedSubroutine => true
    _ => false
  }
}

///|
pub fn DwarfAbbrevEntry::value_fields(
  self : DwarfAbbrevEntry,
) -> Array[DwarfAbbrevField] {
  if self.captures_values() {
    self.fields_value.filter(field => field.is_value_field())
  } else {
    []
  }
}

///|
fn DwarfAbbrevTable::contains_code(
  entries : Array[DwarfAbbrevEntry],
  code : Int,
) -> Bool {
  entries.any(entry => entry.code() == code)
}

///|
fn read_abbrev_fields(
  input : DwarfInput,
) -> Result[(Array[DwarfAbbrevField], DwarfInput), String] {
  let fields = []
  let mut cursor = input
  let mut done = false
  while !done {
    match cursor.read_code() {
      Ok((attr_code, after_attr)) =>
        match after_attr.read_code() {
          Ok((form_code, after_form)) =>
            if attr_code == 0 && form_code == 0 {
              cursor = after_form
              done = true
            } else {
              match dwarf_form_of_int(form_code) {
                Ok(form) => {
                  fields.push(
                    DwarfAbbrevField::create(
                      attr=dwarf_attr_of_int(attr_code),
                      form~,
                    ),
                  )
                  cursor = after_form
                }
                Err(reason) => return Err(reason)
              }
            }
          Err(reason) => return Err(reason)
        }
      Err(reason) => return Err(reason)
    }
  }
  Ok((fields, cursor))
}

///|
pub fn DwarfAbbrevTable::read(
  input : DwarfInput,
) -> Result[(DwarfAbbrevTable, DwarfInput), String] {
  let entries = []
  let mut cursor = input
  let mut done = false
  while !done {
    match cursor.read_code() {
      Ok((0, next)) => {
        cursor = next
        done = true
      }
      Ok((code, after_code)) => {
        if DwarfAbbrevTable::contains_code(entries, code) {
          return Err("duplicate DWARF abbreviation code: \{code}")
        }
        match after_code.read_tag() {
          Ok((tag, after_tag)) =>
            match after_tag.read_byte() {
              Ok((children, after_children)) =>
                match read_abbrev_fields(after_children) {
                  Ok((fields, after_fields)) => {
                    entries.push(
                      DwarfAbbrevEntry::create(
                        code~,
                        tag~,
                        has_children=children != 0,
                        fields~,
                      ),
                    )
                    cursor = after_fields
                  }
                  Err(reason) => return Err(reason)
                }
              Err(reason) => return Err(reason)
            }
          Err(reason) => return Err(reason)
        }
      }
      Err(reason) => return Err(reason)
    }
  }
  Ok(({ entries_value: entries }, cursor))
}

///|
pub fn DwarfAbbrevTable::of_bytes(
  data : Bytes,
  offset? : Int = 0,
) -> Result[DwarfAbbrevTable, String] {
  match
    DwarfAbbrevTable::read(DwarfInput::of_bytes(data).with_position(offset)) {
    Ok((table, _)) => Ok(table)
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfAbbrevTable::entries(
  self : DwarfAbbrevTable,
) -> Array[DwarfAbbrevEntry] {
  self.entries_value.copy()
}

///|
pub fn DwarfAbbrevTable::lookup(
  self : DwarfAbbrevTable,
  code : Int,
) -> DwarfAbbrevEntry? {
  match self.entries_value.search_by(entry => entry.code() == code) {
    Some(index) => Some(self.entries_value[index])
    None => None
  }
}
