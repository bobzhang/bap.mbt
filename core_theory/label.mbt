///|
let fresh_label_counter : Ref[Int] = Ref(0)

///|
struct Label {
  id : Int
  target_value : Target?
  unit_value : ProgramUnit?
  addr_value : @types.Word?
  name_value : String?
  ivec_value : Int?
  encoding_value : Language?
  semantics_value : Semantics?
  aliases_value : Array[String]
  possible_names_value : @knowledge.Opinions[String?]
  valid_flag : Bool
  subroutine_flag : Bool
}

///|
fn next_label_id() -> Int {
  fresh_label_counter.val = fresh_label_counter.val + 1
  fresh_label_counter.val
}

///|
fn unique_aliases(items : Array[String]) -> Array[String] {
  let result = []
  for item in items {
    if !result.contains(item) {
      result.push(item)
    }
  }
  result
}

///|
fn possible_label_name_equal(lhs : String?, rhs : String?) -> Bool {
  lhs == rhs
}

///|
fn inspect_possible_label_name(value : String?) -> String {
  match value {
    Some(text) => text
    None => "none"
  }
}

///|
fn empty_possible_label_names() -> @knowledge.Opinions[String?] {
  let empty : String? = None
  @knowledge.Opinions::empty(
    empty~,
    equal=possible_label_name_equal,
    inspect=inspect_possible_label_name,
  )
}

///|
fn Label::make(
  target? : Target,
  unit? : ProgramUnit,
  addr? : @types.Word,
  name? : String,
  ivec? : Int,
  encoding? : Language,
  semantics? : Semantics,
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
    semantics_value: semantics,
    aliases_value: match aliases {
      Some(items) => unique_aliases(items)
      None => []
    },
    possible_names_value: empty_possible_label_names(),
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
    semantics_value: None,
    aliases_value: [],
    possible_names_value: empty_possible_label_names(),
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
  if !aliases.contains(alias_name) {
    aliases.push(alias_name)
  }
  { ..self, aliases_value: aliases }
}

///|
pub fn Label::with_possible_name(
  self : Label,
  agent : @knowledge.Agent,
  name : String,
) -> Label {
  {
    ..self,
    possible_names_value: self.possible_names_value.add(agent, Some(name)),
  }
}

///|
pub fn Label::with_unit(self : Label, unit : ProgramUnit) -> Label {
  { ..self, unit_value: Some(unit) }
}

///|
pub fn Label::with_encoding(self : Label, language : Language) -> Label {
  { ..self, encoding_value: Some(language) }
}

///|
pub fn Label::with_semantics(self : Label, semantics : Semantics) -> Label {
  { ..self, semantics_value: Some(semantics) }
}

///|
pub fn Label::with_subroutine(
  self : Label,
  is_subroutine? : Bool = true,
) -> Label {
  { ..self, subroutine_flag: is_subroutine }
}

///|
pub fn Label::id(self : Label) -> Int {
  self.id
}

///|
pub fn Label::target(self : Label) -> Target {
  match self.target_value {
    Some(target) => target
    None =>
      match self.unit_value {
        Some(unit) => unit.target()
        None => Target::unknown()
      }
  }
}

///|
pub fn Label::unit(self : Label) -> ProgramUnit? {
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
pub fn Label::possible_name(self : Label) -> String? {
  self.possible_names_value.choice()
}

///|
pub fn Label::possible_name_opinions(
  self : Label,
) -> @knowledge.Opinions[String?] {
  self.possible_names_value
}

///|
pub fn Label::ivec(self : Label) -> Int? {
  self.ivec_value
}

///|
pub fn Label::encoding(self : Label) -> Language? {
  self.encoding_value
}

///|
pub fn Label::semantics(self : Label) -> Semantics? {
  self.semantics_value
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
