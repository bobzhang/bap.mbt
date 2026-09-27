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
  target_value : @knowledge.FactTable[Unit, Target]
  aliases_value : @knowledge.FactTable[Unit, Set[String]]
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
fn label_bool_domain() -> @knowledge.Domain[Bool?] {
  @knowledge.Domain::tribool()
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
  let target = Label::target_slot()
  let aliases = Label::aliases_slot()
  let unit = Label::unit_slot()
  let valid = Label::is_valid_slot()
  let subroutine = Label::is_subroutine_slot()
  let state = @knowledge.State::new()
  {
    state_value: state,
    class_value: cls,
    addr_value: @knowledge.FactTable::new(addr, state~),
    name_value: @knowledge.FactTable::new(name, state~),
    possible_name_value: @knowledge.FactTable::new(possible_name, state~),
    ivec_value: @knowledge.FactTable::new(ivec, state~),
    encoding_value: @knowledge.FactTable::new(encoding, state~),
    semantics_value: @knowledge.FactTable::new(semantics, state~),
    target_value: @knowledge.FactTable::new(target, state~),
    aliases_value: @knowledge.FactTable::new(aliases, state~),
    unit_value: @knowledge.FactTable::new(unit, state~),
    valid_value: @knowledge.FactTable::new(valid, state~),
    subroutine_value: @knowledge.FactTable::new(subroutine, state~),
  }
}

///|
/// The `Label::addr_slot` property, declared once.
let label_addr_slot : @knowledge.Slot[Unit, @types.Word?] = Label::cls().property(
  name=core_name("label-addr"),
  domain=optional_word_domain("label-addr"),
  desc="the program virtual address",
  persistent=optional_word_persistent(),
  public=true,
)

///|
pub fn Label::addr_slot() -> @knowledge.Slot[Unit, @types.Word?] {
  label_addr_slot
}

///|
/// The `Label::name_slot` property, declared once.
let label_name_slot : @knowledge.Slot[Unit, String?] = Label::cls().property(
  name=core_name("label-name"),
  domain=optional_string_domain("label-name"),
  desc="the program linkage name",
  persistent=optional_string_persistent(),
  public=true,
)

///|
pub fn Label::name_slot() -> @knowledge.Slot[Unit, String?] {
  label_name_slot
}

///|
/// The `Label::possible_name_slot` property, declared once.
let label_possible_name_slot : @knowledge.Slot[
  Unit,
  @knowledge.Opinions[String?],
] = Label::cls().property(
  name=core_name("possible-name"),
  domain=possible_name_domain(),
  desc="a unique name associated with the program",
  public=true,
)

///|
pub fn Label::possible_name_slot() -> @knowledge.Slot[
  Unit,
  @knowledge.Opinions[String?],
] {
  label_possible_name_slot
}

///|
/// The `Label::ivec_slot` property, declared once.
let label_ivec_slot : @knowledge.Slot[Unit, Int?] = Label::cls().property(
  name=core_name("label-ivec"),
  domain=optional_int_domain("label-ivec"),
  desc="the program interrupt vector",
  persistent=optional_int_persistent(),
  public=true,
)

///|
pub fn Label::ivec_slot() -> @knowledge.Slot[Unit, Int?] {
  label_ivec_slot
}

///|
/// The `Label::encoding_slot` property, declared once.
let label_encoding_slot : @knowledge.Slot[Unit, Language] = Label::cls().property(
  name=core_name("encoding"),
  domain=source_language_domain(),
  desc="the language of the code",
  persistent=Language::persistent(),
  public=true,
)

///|
pub fn Label::encoding_slot() -> @knowledge.Slot[Unit, Language] {
  label_encoding_slot
}

///|
/// The `Label::aliases_slot` property, declared once.
let label_aliases_slot : @knowledge.Slot[Unit, Set[String]] = Label::cls().property(
  name=core_name("label-aliases"),
  domain=@knowledge.Domain::set(core_name("label-aliases"), item => item),
  desc="the set of known program names",
  persistent=@knowledge.Persistent::set(@knowledge.Persistent::string()),
  public=true,
)

///|
pub fn Label::aliases_slot() -> @knowledge.Slot[Unit, Set[String]] {
  label_aliases_slot
}

///|
/// The `Label::target_slot` property, declared once.
let label_target_slot : @knowledge.Slot[Unit, Target] = Label::cls().property(
  name=core_name("label-target"),
  domain=target_domain_named("label-target"),
  desc="the explicit program label target",
  persistent=Target::persistent(),
  public=true,
)

///|
pub fn Label::target_slot() -> @knowledge.Slot[Unit, Target] {
  label_target_slot
}

///|
/// The `Label::unit_slot` property, declared once.
let label_unit_slot : @knowledge.Slot[Unit, ProgramUnit?] = Label::cls().property(
  name=core_name("label-unit"),
  domain=program_unit_domain(),
  desc="the program unit",
  persistent=optional_program_unit_persistent(),
  public=true,
)

///|
pub fn Label::unit_slot() -> @knowledge.Slot[Unit, ProgramUnit?] {
  label_unit_slot
}

///|
/// The `Label::is_valid_slot` property, declared once.
let label_is_valid_slot : @knowledge.Slot[Unit, Bool?] = Label::cls().property(
  name=core_name("is-valid"),
  domain=label_bool_domain(),
  desc="is the program valid or not",
  persistent=optional_bool_persistent(),
  public=true,
)

///|
pub fn Label::is_valid_slot() -> @knowledge.Slot[Unit, Bool?] {
  label_is_valid_slot
}

///|
/// The `Label::is_subroutine_slot` property, declared once.
let label_is_subroutine_slot : @knowledge.Slot[Unit, Bool?] = Label::cls().property(
  name=core_name("is-subroutine"),
  domain=label_bool_domain(),
  desc="is the program a subroutine entry point",
  persistent=optional_bool_persistent(),
  public=true,
)

///|
pub fn Label::is_subroutine_slot() -> @knowledge.Slot[Unit, Bool?] {
  label_is_subroutine_slot
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
) -> @knowledge.FactTable[Unit, Set[String]] {
  self.aliases_value
}

///|
pub fn LabelFacts::target(
  self : LabelFacts,
) -> @knowledge.FactTable[Unit, Target] {
  self.target_value
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
  match self.aliases_value.provide(object, label.aliases_set()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match self.target_value.provide(object, label.target()) {
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
  self.collect_possible_name_opinions(object).choice()
}

///|
pub fn LabelFacts::collect_possible_name_opinions(
  self : LabelFacts,
  object : @knowledge.Object[Unit],
) -> @knowledge.Opinions[String?] {
  match self.possible_name_value.collect(object) {
    Some(opinions) => opinions
    None => empty_possible_label_names()
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
) -> Set[String] {
  match self.aliases_value.collect(object) {
    Some(aliases) => aliases
    None => Set([])
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
  match self.target_value.collect(object) {
    Some(target) if !self.target_value.slot().domain().is_empty(target) =>
      target
    _ =>
      match self.collect_unit(object) {
        Some(unit) => unit.target()
        None => Target::unknown()
      }
  }
}
