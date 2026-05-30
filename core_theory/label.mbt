///|
let fresh_label_counter : Ref[Int] = Ref(0)

///|
struct Label {
  id : Int
  target_value : Target?
  unit_value : String?
  addr_value : @types.Word?
  name_value : String?
  ivec_value : Int?
  encoding_value : Bytes?
  aliases_value : Array[String]
  valid_flag : Bool
  subroutine_flag : Bool
}

///|
fn next_label_id() -> Int {
  fresh_label_counter.val = fresh_label_counter.val + 1
  fresh_label_counter.val
}

///|
fn Label::make(
  target? : Target,
  unit? : String,
  addr? : @types.Word,
  name? : String,
  ivec? : Int,
  encoding? : Bytes,
  aliases? : Array[String],
  is_valid? : Bool,
  is_subroutine? : Bool,
) -> Label {
  {
    id: next_label_id(),
    target_value: target,
    unit_value: unit,
    addr_value: addr,
    name_value: name,
    ivec_value: ivec,
    encoding_value: encoding,
    aliases_value: match aliases {
      Some(items) => items.copy()
      None => []
    },
    valid_flag: match is_valid {
      Some(flag) => flag
      None => true
    },
    subroutine_flag: match is_subroutine {
      Some(flag) => flag
      None => false
    },
  }
}

///|
pub fn Label::fresh(target? : Target) -> Label {
  Label::make(target?)
}

///|
pub fn Label::null() -> Label {
  {
    id: 0,
    target_value: None,
    unit_value: None,
    addr_value: None,
    name_value: None,
    ivec_value: None,
    encoding_value: None,
    aliases_value: [],
    valid_flag: false,
    subroutine_flag: false,
  }
}

///|
pub fn Label::for_name(name : String, target? : Target) -> Label {
  Label::make(name~, target?)
}

///|
pub fn Label::for_addr(addr : @types.Word, target? : Target) -> Label {
  Label::make(addr~, target?)
}

///|
pub fn Label::for_ivec(ivec : Int, target? : Target) -> Label {
  Label::make(ivec~, target?)
}

///|
pub fn Label::with_alias(self : Label, alias_name : String) -> Label {
  let aliases = self.aliases_value.copy()
  aliases.push(alias_name)
  { ..self, aliases_value: aliases }
}

///|
pub fn Label::id(self : Label) -> Int {
  self.id
}

///|
pub fn Label::target(self : Label) -> Target? {
  self.target_value
}

///|
pub fn Label::unit(self : Label) -> String? {
  self.unit_value
}

///|
pub fn Label::addr(self : Label) -> @types.Word? {
  self.addr_value
}

///|
pub fn Label::name(self : Label) -> String? {
  self.name_value
}

///|
pub fn Label::ivec(self : Label) -> Int? {
  self.ivec_value
}

///|
pub fn Label::encoding(self : Label) -> Bytes? {
  self.encoding_value
}

///|
pub fn Label::aliases(self : Label) -> Array[String] {
  self.aliases_value.copy()
}

///|
pub fn Label::is_valid(self : Label) -> Bool {
  self.valid_flag
}

///|
pub fn Label::is_subroutine(self : Label) -> Bool {
  self.subroutine_flag
}
