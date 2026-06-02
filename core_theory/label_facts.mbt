///|
struct LabelFacts {
  state_value : @knowledge.State
  class_value : @knowledge.Class[Unit, Unit]
  addr_value : @knowledge.FactTable[Unit, @types.Word?]
  name_value : @knowledge.FactTable[Unit, String?]
  possible_name_value : @knowledge.FactTable[Unit, @knowledge.Opinions[String?]]
  ivec_value : @knowledge.FactTable[Unit, Int?]
  encoding_value : @knowledge.FactTable[Unit, Language]
  semantics_value : @knowledge.FactTable[Unit, Semantics]
  aliases_value : @knowledge.FactTable[Unit, Array[String]]
  unit_value : @knowledge.FactTable[Unit, ProgramUnit?]
  valid_value : @knowledge.FactTable[Unit, Bool?]
  subroutine_value : @knowledge.FactTable[Unit, Bool?]
}

///|
fn optional_int_domain(name : String) -> @knowledge.Domain[Int?] {
  @knowledge.Domain::optional(
    @knowledge.Domain::flat(core_name(name), value => value.to_string()),
  )
}

///|
fn optional_bool_domain(name : String) -> @knowledge.Domain[Bool?] {
  @knowledge.Domain::optional(
    @knowledge.Domain::flat(core_name(name), value => value.to_string()),
  )
}

///|
fn optional_int_persistent() -> @knowledge.Persistent[Int?] {
  @knowledge.Persistent::optional(@knowledge.Persistent::int())
}

///|
fn optional_bool_persistent() -> @knowledge.Persistent[Bool?] {
  @knowledge.Persistent::optional(@knowledge.Persistent::bool())
}

///|
fn optional_program_unit_persistent() -> @knowledge.Persistent[ProgramUnit?] {
  @knowledge.Persistent::optional(ProgramUnit::persistent())
}

///|
fn possible_name_domain() -> @knowledge.Domain[@knowledge.Opinions[String?]] {
  @knowledge.Domain::opinions(
    core_name("possible-name"),
    empty=None,
    equal=possible_label_name_equal,
    inspect=inspect_possible_label_name,
  )
}

///|
fn program_unit_equal(lhs : ProgramUnit, rhs : ProgramUnit) -> Bool {
  lhs.same(rhs)
}

///|
fn program_unit_domain() -> @knowledge.Domain[ProgramUnit?] {
  @knowledge.Domain::optional(
    @knowledge.Domain::new(
      name=core_name("label-unit"),
      empty=None,
      is_empty=(_ : ProgramUnit) => false,
      order=(lhs : ProgramUnit, rhs : ProgramUnit) => {
        if program_unit_equal(lhs, rhs) {
          Equal
        } else {
          Incomparable
        }
      },
      join=(lhs : ProgramUnit, rhs : ProgramUnit) => {
        if program_unit_equal(lhs, rhs) {
          Ok(lhs)
        } else {
          Err("conflicting label unit facts")
        }
      },
      inspect=(unit : ProgramUnit) => unit.name(),
    ),
  )
}

///|
pub fn LabelFacts::new() -> LabelFacts {
  let cls = Label::cls()
  let addr = Label::addr_slot()
  let name = Label::name_slot()
  let possible_name = Label::possible_name_slot()
  let ivec = Label::ivec_slot()
  let encoding = Label::encoding_slot()
  let semantics = Semantics::slot()
  let aliases = Label::aliases_slot()
  let unit = Label::unit_slot()
  let valid = Label::is_valid_slot()
  let subroutine = Label::is_subroutine_slot()
  {
    state_value: @knowledge.State::new(),
    class_value: cls,
    addr_value: @knowledge.FactTable::new(addr),
    name_value: @knowledge.FactTable::new(name),
    possible_name_value: @knowledge.FactTable::new(possible_name),
    ivec_value: @knowledge.FactTable::new(ivec),
    encoding_value: @knowledge.FactTable::new(encoding),
    semantics_value: @knowledge.FactTable::new(semantics),
    aliases_value: @knowledge.FactTable::new(aliases),
    unit_value: @knowledge.FactTable::new(unit),
    valid_value: @knowledge.FactTable::new(valid),
    subroutine_value: @knowledge.FactTable::new(subroutine),
  }
}

///|
pub fn Label::addr_slot() -> @knowledge.Slot[Unit, @types.Word?] {
  Label::cls().property(
    name=core_name("label-addr"),
    domain=optional_word_domain("label-addr"),
    desc="the program virtual address",
    persistent=optional_word_persistent(),
    public=true,
  )
}

///|
pub fn Label::name_slot() -> @knowledge.Slot[Unit, String?] {
  Label::cls().property(
    name=core_name("label-name"),
    domain=optional_string_domain("label-name"),
    desc="the program linkage name",
    persistent=optional_string_persistent(),
    public=true,
  )
}

///|
pub fn Label::possible_name_slot() -> @knowledge.Slot[
  Unit,
  @knowledge.Opinions[String?],
] {
  Label::cls().property(
    name=core_name("possible-name"),
    domain=possible_name_domain(),
    desc="a unique name associated with the program",
    public=true,
  )
}

///|
pub fn Label::ivec_slot() -> @knowledge.Slot[Unit, Int?] {
  Label::cls().property(
    name=core_name("label-ivec"),
    domain=optional_int_domain("label-ivec"),
    desc="the program interrupt vector",
    persistent=optional_int_persistent(),
    public=true,
  )
}

///|
pub fn Label::encoding_slot() -> @knowledge.Slot[Unit, Language] {
  Label::cls().property(
    name=core_name("encoding"),
    domain=source_language_domain(),
    desc="the language of the code",
    persistent=Language::persistent(),
    public=true,
  )
}

///|
pub fn Label::aliases_slot() -> @knowledge.Slot[Unit, Array[String]] {
  Label::cls().property(
    name=core_name("label-aliases"),
    domain=@knowledge.Domain::powerset(core_name("label-aliases"), item => item),
    desc="the set of known program names",
    persistent=@knowledge.Persistent::array(@knowledge.Persistent::string()),
    public=true,
  )
}

///|
pub fn Label::unit_slot() -> @knowledge.Slot[Unit, ProgramUnit?] {
  Label::cls().property(
    name=core_name("label-unit"),
    domain=program_unit_domain(),
    desc="the program unit",
    persistent=optional_program_unit_persistent(),
    public=true,
  )
}

///|
pub fn Label::is_valid_slot() -> @knowledge.Slot[Unit, Bool?] {
  Label::cls().property(
    name=core_name("is-valid"),
    domain=optional_bool_domain("is-valid"),
    desc="is the program valid or not",
    persistent=optional_bool_persistent(),
    public=true,
  )
}

///|
pub fn Label::is_subroutine_slot() -> @knowledge.Slot[Unit, Bool?] {
  Label::cls().property(
    name=core_name("is-subroutine"),
    domain=optional_bool_domain("is-subroutine"),
    desc="is the program a subroutine entry point",
    persistent=optional_bool_persistent(),
    public=true,
  )
}

///|
pub fn LabelFacts::class(self : LabelFacts) -> @knowledge.Class[Unit, Unit] {
  self.class_value
}

///|
pub fn LabelFacts::create(self : LabelFacts) -> @knowledge.Object[Unit] {
  self.state_value.create(self.class_value)
}

///|
pub fn LabelFacts::addr(
  self : LabelFacts,
) -> @knowledge.FactTable[Unit, @types.Word?] {
  self.addr_value
}

///|
pub fn LabelFacts::name(
  self : LabelFacts,
) -> @knowledge.FactTable[Unit, String?] {
  self.name_value
}

///|
pub fn LabelFacts::possible_name(
  self : LabelFacts,
) -> @knowledge.FactTable[Unit, @knowledge.Opinions[String?]] {
  self.possible_name_value
}

///|
pub fn LabelFacts::ivec(self : LabelFacts) -> @knowledge.FactTable[Unit, Int?] {
  self.ivec_value
}

///|
pub fn LabelFacts::encoding(
  self : LabelFacts,
) -> @knowledge.FactTable[Unit, Language] {
  self.encoding_value
}

///|
pub fn LabelFacts::semantics(
  self : LabelFacts,
) -> @knowledge.FactTable[Unit, Semantics] {
  self.semantics_value
}

///|
pub fn LabelFacts::aliases(
  self : LabelFacts,
) -> @knowledge.FactTable[Unit, Array[String]] {
  self.aliases_value
}

///|
pub fn LabelFacts::unit(
  self : LabelFacts,
) -> @knowledge.FactTable[Unit, ProgramUnit?] {
  self.unit_value
}

///|
pub fn LabelFacts::is_valid(
  self : LabelFacts,
) -> @knowledge.FactTable[Unit, Bool?] {
  self.valid_value
}

///|
pub fn LabelFacts::is_subroutine(
  self : LabelFacts,
) -> @knowledge.FactTable[Unit, Bool?] {
  self.subroutine_value
}

///|
pub fn LabelFacts::provide_label(
  self : LabelFacts,
  object : @knowledge.Object[Unit],
  label : Label,
) -> Result[Unit, String] {
  match self.addr_value.provide(object, label.addr()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match self.name_value.provide(object, label.name()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match
    self.possible_name_value.provide(object, label.possible_name_opinions()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match self.ivec_value.provide(object, label.ivec()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match label.encoding() {
    Some(language) =>
      match self.encoding_value.provide(object, language) {
        Ok(_) => ()
        Err(reason) => return Err(reason)
      }
    None => ()
  }
  match label.semantics() {
    Some(semantics) =>
      match self.semantics_value.provide(object, semantics) {
        Ok(_) => ()
        Err(reason) => return Err(reason)
      }
    None => ()
  }
  match self.aliases_value.provide(object, label.aliases()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match self.unit_value.provide(object, label.unit()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match self.valid_value.provide(object, Some(label.is_valid())) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match self.subroutine_value.provide(object, Some(label.is_subroutine())) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  Ok(())
}

///|
pub fn LabelFacts::for_label(
  self : LabelFacts,
  label : Label,
) -> Result[@knowledge.Object[Unit], String] {
  let object = self.create()
  match self.provide_label(object, label) {
    Ok(_) => Ok(object)
    Err(reason) => Err(reason)
  }
}

///|
pub fn LabelFacts::collect_addr(
  self : LabelFacts,
  object : @knowledge.Object[Unit],
) -> @types.Word? {
  match self.addr_value.collect(object) {
    Some(addr) => addr
    None => None
  }
}

///|
pub fn LabelFacts::collect_name(
  self : LabelFacts,
  object : @knowledge.Object[Unit],
) -> String? {
  match self.name_value.collect(object) {
    Some(name) => name
    None => None
  }
}

///|
pub fn LabelFacts::collect_possible_name(
  self : LabelFacts,
  object : @knowledge.Object[Unit],
) -> String? {
  match self.possible_name_value.collect(object) {
    Some(opinions) => opinions.choice()
    None => None
  }
}

///|
pub fn LabelFacts::collect_ivec(
  self : LabelFacts,
  object : @knowledge.Object[Unit],
) -> Int? {
  match self.ivec_value.collect(object) {
    Some(ivec) => ivec
    None => None
  }
}

///|
pub fn LabelFacts::collect_encoding(
  self : LabelFacts,
  object : @knowledge.Object[Unit],
) -> Language? {
  match self.encoding_value.collect(object) {
    Some(language) if !self.encoding_value.slot().domain().is_empty(language) =>
      Some(language)
    _ => None
  }
}

///|
pub fn LabelFacts::collect_semantics(
  self : LabelFacts,
  object : @knowledge.Object[Unit],
) -> Semantics? {
  match self.semantics_value.collect(object) {
    Some(semantics) if !self.semantics_value.slot().domain().is_empty(semantics) =>
      Some(semantics)
    _ => None
  }
}

///|
pub fn LabelFacts::collect_aliases(
  self : LabelFacts,
  object : @knowledge.Object[Unit],
) -> Array[String] {
  match self.aliases_value.collect(object) {
    Some(aliases) => aliases
    None => []
  }
}

///|
pub fn LabelFacts::collect_unit(
  self : LabelFacts,
  object : @knowledge.Object[Unit],
) -> ProgramUnit? {
  match self.unit_value.collect(object) {
    Some(unit) => unit
    None => None
  }
}

///|
pub fn LabelFacts::collect_is_valid(
  self : LabelFacts,
  object : @knowledge.Object[Unit],
) -> Bool? {
  match self.valid_value.collect(object) {
    Some(flag) => flag
    None => None
  }
}

///|
pub fn LabelFacts::collect_is_subroutine(
  self : LabelFacts,
  object : @knowledge.Object[Unit],
) -> Bool? {
  match self.subroutine_value.collect(object) {
    Some(flag) => flag
    None => None
  }
}

///|
pub fn LabelFacts::collect_target(
  self : LabelFacts,
  object : @knowledge.Object[Unit],
) -> Target {
  match self.collect_unit(object) {
    Some(unit) => unit.target()
    None => Target::unknown()
  }
}
