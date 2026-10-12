///|
let fresh_label_counter : Ref[Int32] = Ref(0)

///|
let interned_label_ids : Map[String, Int32] = Map([])

///|
struct Label {
  id : Int32
  target_value : Target?
  unit_value : ProgramUnit?
  addr_value : @types.Word?
  name_value : String?
  ivec_value : Int32?
  encoding_value : Language?
  semantics_value : Semantics?
  aliases_value : Array[String]
  possible_names_value : @knowledge.Opinions[String?]
  valid_flag : Bool
  subroutine_flag : Bool
}

///|
fn next_label_id() -> Int32 {
  fresh_label_counter.val = fresh_label_counter.val + 1
  fresh_label_counter.val
}

///|
fn ensure_label_counter_at_least(id : Int32) -> Unit {
  if fresh_label_counter.val < id {
    fresh_label_counter.val = id
  }
}

///|
fn label_package(pkg? : String) -> String {
  @knowledge.Name::read("label", pkg?).pkg()
}

///|
fn label_target_key(target : Target?) -> String {
  match target {
    Some(value) => value.name().show()
    None => ""
  }
}

///|
fn interned_label_id(
  kind : String,
  pkg : String,
  value : String,
  target? : Target,
) -> Int32 {
  let key = "\{kind}|\{pkg}|\{value}|\{label_target_key(target)}"
  match interned_label_ids.get(key) {
    Some(id) => id
    None => {
      let id = next_label_id()
      interned_label_ids[key] = id
      id
    }
  }
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
  id? : Int32,
  target? : Target,
  unit? : ProgramUnit,
  addr? : @types.Word,
  name? : String,
  ivec? : Int32,
  encoding? : Language,
  semantics? : Semantics,
  aliases? : Array[String],
  is_valid? : Bool,
  is_subroutine? : Bool,
) -> Label {
  {
    id: match id {
      Some(value) => value
      None => next_label_id()
    },
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
pub fn Label::cls() -> @knowledge.Class[Unit, Unit] {
  Program::cls()
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
pub fn Label::for_name(name : String, target? : Target, pkg? : String) -> Label {
  let label_pkg = label_package(pkg?)
  Label::make(
    id=interned_label_id("name", label_pkg, name, target?),
    name~,
    target?,
  )
}

///|
pub fn Label::for_addr(
  addr : @types.Word,
  target? : Target,
  pkg? : String,
) -> Label {
  let label_pkg = label_package(pkg?)
  Label::make(
    id=interned_label_id("addr", label_pkg, addr.to_hex(), target?),
    addr~,
    target?,
  )
}

///|
pub fn Label::for_ivec(ivec : Int32, target? : Target, pkg? : String) -> Label {
  let label_pkg = label_package(pkg?)
  Label::make(
    id=interned_label_id("ivec", label_pkg, ivec.to_string(), target?),
    ivec~,
    target?,
  )
}

///|
pub fn Label::with_alias(self : Label, alias_name : String) -> Label {
  let aliases = self.aliases_value.copy()
  if !aliases.contains(alias_name) {
    aliases.push(alias_name)
  }
  { ..self, aliases_value: aliases, }
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
  { ..self, unit_value: Some(unit), }
}

///|
pub fn Label::with_encoding(self : Label, language : Language) -> Label {
  { ..self, encoding_value: Some(language), }
}

///|
pub fn Label::with_semantics(self : Label, semantics : Semantics) -> Label {
  { ..self, semantics_value: Some(semantics), }
}

///|
pub fn Label::with_valid(self : Label, is_valid~ : Bool = true) -> Label {
  { ..self, valid_flag: is_valid, }
}

///|
pub fn Label::with_subroutine(
  self : Label,
  is_subroutine~ : Bool = true,
) -> Label {
  { ..self, subroutine_flag: is_subroutine, }
}

///|
pub fn Label::id(self : Label) -> Int32 {
  self.id
}

///|
pub fn Label::same(self : Label, other : Label) -> Bool {
  self.id == other.id
}

///|
pub fn Label::compare(self : Label, other : Label) -> Int32 {
  self.id.compare(other.id)
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
pub fn Label::ivec(self : Label) -> Int32? {
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
fn Label::aliases_set(self : Label) -> Set[String] {
  let aliases : Set[String] = Set([])
  for alias_name in self.aliases_value {
    aliases.add(alias_name)
  }
  aliases
}

///|
pub fn Label::is_valid(self : Label) -> Bool {
  self.valid_flag
}

///|
pub fn Label::is_subroutine(self : Label) -> Bool {
  self.subroutine_flag
}

///|
pub fn Label::persistent() -> @knowledge.Persistent[Label] {
  let int_codec = @knowledge.Persistent::int()
  let opt_target_codec = @knowledge.Persistent::optional(Target::persistent())
  let opt_unit_codec = @knowledge.Persistent::optional(
    ProgramUnit::persistent(),
  )
  let opt_word_codec = @knowledge.Persistent::optional(word_persistent())
  let opt_string_codec = @knowledge.Persistent::optional(
    @knowledge.Persistent::string(),
  )
  let opt_int_codec = @knowledge.Persistent::optional(int_codec)
  let opt_language_codec = @knowledge.Persistent::optional(
    Language::persistent(),
  )
  let opt_semantics_codec = @knowledge.Persistent::optional(
    Semantics::persistent(),
  )
  let aliases_codec = @knowledge.Persistent::array(
    @knowledge.Persistent::string(),
  )
  let possible_names_codec = @knowledge.Opinions::persistent(
    opt_string_codec,
    empty=None,
    equal=possible_label_name_equal,
    inspect=inspect_possible_label_name,
  )
  let bool_codec = @knowledge.Persistent::bool()
  @knowledge.Persistent::convert(
    to_persistent=label => {
      [
        int_codec.encode(label.id()),
        opt_target_codec.encode(label.target_value),
        opt_unit_codec.encode(label.unit()),
        opt_word_codec.encode(label.addr()),
        opt_string_codec.encode(label.name()),
        opt_int_codec.encode(label.ivec()),
        opt_language_codec.encode(label.encoding()),
        opt_semantics_codec.encode(label.semantics()),
        aliases_codec.encode(label.aliases()),
        possible_names_codec.encode(label.possible_name_opinions()),
        bool_codec.encode(label.is_valid()),
        bool_codec.encode(label.is_subroutine()),
      ]
    },
    of_persistent=fields => {
      let has_possible_names = fields.length() == 12
      if fields.length() != 11 && fields.length() != 12 {
        return Err(
          "invalid persistent label encoding: expected 11 or 12 fields, got \{fields.length()}",
        )
      }
      let id = match int_codec.decode(fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let target = match opt_target_codec.decode(fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let unit = match opt_unit_codec.decode(fields[2]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let addr = match opt_word_codec.decode(fields[3]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let name = match opt_string_codec.decode(fields[4]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let ivec = match opt_int_codec.decode(fields[5]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let encoding = match opt_language_codec.decode(fields[6]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let semantics = match opt_semantics_codec.decode(fields[7]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let aliases = match aliases_codec.decode(fields[8]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let possible_names = if has_possible_names {
        match possible_names_codec.decode(fields[9]) {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
      } else {
        empty_possible_label_names()
      }
      let valid_index = if has_possible_names { 10 } else { 9 }
      let subroutine_index = if has_possible_names { 11 } else { 10 }
      let valid = match bool_codec.decode(fields[valid_index]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let subroutine = match bool_codec.decode(fields[subroutine_index]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      ensure_label_counter_at_least(id)
      Ok({
        ..Label::make(
          id~,
          target?,
          unit?,
          addr?,
          name?,
          ivec?,
          encoding?,
          semantics?,
          aliases~,
          is_valid=valid,
          is_subroutine=subroutine,
        ),
        possible_names_value: possible_names,
      })
    },
    persistent_string_fields(),
  )
}
