///|
struct SourceFacts {
  state_value : @knowledge.State
  class_value : @knowledge.Class[Unit, Unit]
  language_value : @knowledge.FactTable[Unit, Language]
  code_value : @knowledge.FactTable[Unit, String]
  file_value : @knowledge.FactTable[Unit, String?]
}

///|
struct ProgramUnitFacts {
  state_value : @knowledge.State
  class_value : @knowledge.Class[Unit, Unit]
  path_value : @knowledge.FactTable[Unit, String?]
  bias_value : @knowledge.FactTable[Unit, @types.Word?]
  target_value : @knowledge.FactTable[Unit, Target]
  source_value : @knowledge.FactTable[Unit, Source?]
  compiler_value : @knowledge.FactTable[Unit, Compiler?]
}

///|
fn core_name(text : String) -> @knowledge.Name {
  @knowledge.Name::create(text, pkg="core")
}

///|
fn source_language_domain() -> @knowledge.Domain[Language] {
  @knowledge.Domain::flat(
    core_name("source-language"),
    value => value.to_string(),
    empty=OtherLanguage("unknown"),
  )
}

///|
fn optional_string_domain(name : String) -> @knowledge.Domain[String?] {
  @knowledge.Domain::optional(@knowledge.Domain::string(core_name(name)))
}

///|
fn optional_word_domain(name : String) -> @knowledge.Domain[@types.Word?] {
  @knowledge.Domain::optional(
    @knowledge.Domain::flat(core_name(name), value => value.to_string()),
  )
}

///|
fn source_equal(lhs : Source, rhs : Source) -> Bool {
  lhs.language_value == rhs.language_value &&
  lhs.code_value == rhs.code_value &&
  lhs.file_value == rhs.file_value
}

///|
fn source_inspect(source : Source) -> String {
  let file = match source.file_value {
    Some(path) => path
    None => "none"
  }
  "source(language=\{source.language_value.to_string()}, file=\{file})"
}

///|
fn source_domain() -> @knowledge.Domain[Source?] {
  @knowledge.Domain::optional(
    @knowledge.Domain::new(
      name=core_name("unit-source"),
      empty=None,
      is_empty=(_ : Source) => false,
      order=(lhs : Source, rhs : Source) => {
        if source_equal(lhs, rhs) {
          Equal
        } else {
          Incomparable
        }
      },
      join=(lhs : Source, rhs : Source) => {
        if source_equal(lhs, rhs) {
          Ok(lhs)
        } else {
          Err("conflicting source facts")
        }
      },
      inspect=source_inspect,
    ),
  )
}

///|
fn string_map_equal(
  lhs : Map[String, String],
  rhs : Map[String, String],
) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for entry in lhs {
    if rhs.get(entry.0) != Some(entry.1) {
      return false
    }
  }
  true
}

///|
fn compiler_equal(lhs : Compiler, rhs : Compiler) -> Bool {
  lhs.name_value == rhs.name_value &&
  lhs.version_value == rhs.version_value &&
  lhs.options_value == rhs.options_value &&
  string_map_equal(lhs.specs_value, rhs.specs_value)
}

///|
fn string_array_compare(lhs : Array[String], rhs : Array[String]) -> Int {
  let limit = if lhs.length() < rhs.length() {
    lhs.length()
  } else {
    rhs.length()
  }
  for i in 0..<limit {
    let order = lhs[i].compare(rhs[i])
    if order != 0 {
      return order
    }
  }
  lhs.length().compare(rhs.length())
}

///|
fn sorted_string_map_entries(
  items : Map[String, String],
) -> Array[(String, String)] {
  let entries = []
  for entry in items {
    entries.push(entry)
  }
  entries.sort_by(fn(lhs, rhs) {
    let key_order = lhs.0.compare(rhs.0)
    if key_order != 0 {
      key_order
    } else {
      lhs.1.compare(rhs.1)
    }
  })
  entries
}

///|
fn string_map_compare(
  lhs : Map[String, String],
  rhs : Map[String, String],
) -> Int {
  let lhs_entries = sorted_string_map_entries(lhs)
  let rhs_entries = sorted_string_map_entries(rhs)
  let limit = if lhs_entries.length() < rhs_entries.length() {
    lhs_entries.length()
  } else {
    rhs_entries.length()
  }
  for i in 0..<limit {
    let key_order = lhs_entries[i].0.compare(rhs_entries[i].0)
    if key_order != 0 {
      return key_order
    }
    let value_order = lhs_entries[i].1.compare(rhs_entries[i].1)
    if value_order != 0 {
      return value_order
    }
  }
  lhs_entries.length().compare(rhs_entries.length())
}

///|
pub fn Compiler::equal(self : Compiler, other : Compiler) -> Bool {
  compiler_equal(self, other)
}

///|
pub fn Compiler::compare(self : Compiler, other : Compiler) -> Int {
  let name_order = self.name_value.compare(other.name_value)
  if name_order != 0 {
    return name_order
  }
  let version_order = string_array_compare(
    self.version_value,
    other.version_value,
  )
  if version_order != 0 {
    return version_order
  }
  let options_order = string_array_compare(
    self.options_value,
    other.options_value,
  )
  if options_order != 0 {
    return options_order
  }
  string_map_compare(self.specs_value, other.specs_value)
}

///|
fn compiler_inspect(compiler : Compiler) -> String {
  compiler.to_string()
}

///|
pub fn Compiler::domain() -> @knowledge.Domain[Compiler?] {
  @knowledge.Domain::optional(
    @knowledge.Domain::new(
      name=core_name("unit-compiler"),
      empty=None,
      is_empty=(_ : Compiler) => false,
      order=(lhs : Compiler, rhs : Compiler) => {
        if compiler_equal(lhs, rhs) {
          Equal
        } else {
          Incomparable
        }
      },
      join=(lhs : Compiler, rhs : Compiler) => {
        if compiler_equal(lhs, rhs) {
          Ok(lhs)
        } else {
          Err("conflicting compiler facts")
        }
      },
      inspect=compiler_inspect,
    ),
  )
}

///|
fn target_equal(lhs : Target, rhs : Target) -> Bool {
  lhs.name().show() == rhs.name().show()
}

///|
fn word_persistent() -> @knowledge.Persistent[@types.Word] {
  @knowledge.Persistent::create(to_string=word => word.to_string(), of_string=input => {
    try @types.Word::from_string(input[:]) catch {
      _ => Err("invalid persistent word")
    } noraise {
      word => Ok(word)
    }
  })
}

///|
fn optional_string_persistent() -> @knowledge.Persistent[String?] {
  @knowledge.Persistent::optional(@knowledge.Persistent::string())
}

///|
fn optional_word_persistent() -> @knowledge.Persistent[@types.Word?] {
  @knowledge.Persistent::optional(word_persistent())
}

///|
fn optional_source_persistent() -> @knowledge.Persistent[Source?] {
  @knowledge.Persistent::optional(Source::persistent())
}

///|
fn optional_compiler_persistent() -> @knowledge.Persistent[Compiler?] {
  @knowledge.Persistent::optional(Compiler::persistent())
}

///|
fn target_domain_named(name : String) -> @knowledge.Domain[Target] {
  let unknown = Target::unknown()
  @knowledge.Domain::new(
    name=core_name(name),
    empty=Some(unknown),
    is_empty=(target : Target) => target.is_unknown(),
    order=(lhs : Target, rhs : Target) => {
      if target_equal(lhs, rhs) {
        Equal
      } else if lhs.is_unknown() {
        Less
      } else if rhs.is_unknown() {
        Greater
      } else {
        Incomparable
      }
    },
    join=(lhs : Target, rhs : Target) => {
      if target_equal(lhs, rhs) || rhs.is_unknown() {
        Ok(lhs)
      } else if lhs.is_unknown() {
        Ok(rhs)
      } else {
        Err("conflicting target facts")
      }
    },
    inspect=(target : Target) => target.name().show(),
  )
}

///|
pub fn target_domain() -> @knowledge.Domain[Target] {
  target_domain_named("unit-target")
}

///|
pub fn Target::domain() -> @knowledge.Domain[Target] {
  target_domain()
}

///|
pub fn SourceFacts::new() -> SourceFacts {
  let cls = Source::cls()
  let language = Source::language_slot()
  let code = Source::code_slot()
  let file = Source::file_slot()
  {
    state_value: @knowledge.State::new(),
    class_value: cls,
    language_value: @knowledge.FactTable::new(language),
    code_value: @knowledge.FactTable::new(code),
    file_value: @knowledge.FactTable::new(file),
  }
}

///|
pub fn Source::language_slot() -> @knowledge.Slot[Unit, Language] {
  Source::cls().property(
    name=core_name("source-language"),
    domain=source_language_domain(),
    desc="the language of the unit source code",
    persistent=Language::persistent(),
    public=true,
  )
}

///|
pub fn Source::code_slot() -> @knowledge.Slot[Unit, String] {
  Source::cls().property(
    name=core_name("source-code"),
    domain=@knowledge.Domain::string(core_name("source-code")),
    desc="the unit source code text",
    persistent=@knowledge.Persistent::string(),
    public=true,
  )
}

///|
pub fn Source::file_slot() -> @knowledge.Slot[Unit, String?] {
  Source::cls().property(
    name=core_name("source-path"),
    domain=optional_string_domain("source-path"),
    desc="a path to the source code file",
    persistent=optional_string_persistent(),
    public=true,
  )
}

///|
pub fn SourceFacts::class(self : SourceFacts) -> @knowledge.Class[Unit, Unit] {
  self.class_value
}

///|
pub fn SourceFacts::create(self : SourceFacts) -> @knowledge.Object[Unit] {
  self.state_value.create(self.class_value)
}

///|
pub fn SourceFacts::language(
  self : SourceFacts,
) -> @knowledge.FactTable[Unit, Language] {
  self.language_value
}

///|
pub fn SourceFacts::code(
  self : SourceFacts,
) -> @knowledge.FactTable[Unit, String] {
  self.code_value
}

///|
pub fn SourceFacts::file(
  self : SourceFacts,
) -> @knowledge.FactTable[Unit, String?] {
  self.file_value
}

///|
pub fn SourceFacts::provide_source(
  self : SourceFacts,
  object : @knowledge.Object[Unit],
  source : Source,
) -> Result[Unit, String] {
  match self.language_value.provide(object, source.language()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match self.code_value.provide(object, source.code()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match self.file_value.provide(object, source.file()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  Ok(())
}

///|
pub fn SourceFacts::for_source(
  self : SourceFacts,
  source : Source,
) -> Result[@knowledge.Object[Unit], String] {
  let object = self.create()
  match self.provide_source(object, source) {
    Ok(_) => Ok(object)
    Err(reason) => Err(reason)
  }
}

///|
pub fn SourceFacts::collect_language(
  self : SourceFacts,
  object : @knowledge.Object[Unit],
) -> Language {
  match self.language_value.collect(object) {
    Some(value) => value
    None => Language::unknown()
  }
}

///|
pub fn SourceFacts::collect_code(
  self : SourceFacts,
  object : @knowledge.Object[Unit],
) -> String {
  match self.code_value.collect(object) {
    Some(value) => value
    None => ""
  }
}

///|
pub fn SourceFacts::collect_file(
  self : SourceFacts,
  object : @knowledge.Object[Unit],
) -> String? {
  match self.file_value.collect(object) {
    Some(file) => file
    None => None
  }
}

///|
pub fn SourceFacts::collect_source(
  self : SourceFacts,
  object : @knowledge.Object[Unit],
) -> Source {
  let language = self.collect_language(object)
  let code = self.collect_code(object)
  match self.collect_file(object) {
    Some(file) => Source::create(language~, code~, file~)
    None => Source::create(language~, code~)
  }
}

///|
pub fn ProgramUnitFacts::new() -> ProgramUnitFacts {
  let cls = ProgramUnit::cls()
  let path = ProgramUnit::path_slot()
  let bias = ProgramUnit::bias_slot()
  let target = ProgramUnit::target_slot()
  let source = ProgramUnit::source_slot()
  let compiler = ProgramUnit::compiler_slot()
  {
    state_value: @knowledge.State::new(),
    class_value: cls,
    path_value: @knowledge.FactTable::new(path),
    bias_value: @knowledge.FactTable::new(bias),
    target_value: @knowledge.FactTable::new(target),
    source_value: @knowledge.FactTable::new(source),
    compiler_value: @knowledge.FactTable::new(compiler),
  }
}

///|
pub fn ProgramUnit::path_slot() -> @knowledge.Slot[Unit, String?] {
  ProgramUnit::cls().property(
    name=core_name("unit-path"),
    domain=optional_string_domain("unit-path"),
    desc="a filesystem name of the file that contains the program",
    persistent=optional_string_persistent(),
    public=true,
  )
}

///|
pub fn ProgramUnit::bias_slot() -> @knowledge.Slot[Unit, @types.Word?] {
  ProgramUnit::cls().property(
    name=core_name("unit-bias"),
    domain=optional_word_domain("unit-bias"),
    desc="the value by which all addresses of the unit are biased",
    persistent=optional_word_persistent(),
    public=true,
  )
}

///|
pub fn ProgramUnit::target_slot() -> @knowledge.Slot[Unit, Target] {
  ProgramUnit::cls().property(
    name=core_name("unit-target"),
    domain=target_domain(),
    desc="the target system for the unit",
    persistent=Target::persistent(),
    public=true,
  )
}

///|
pub fn ProgramUnit::source_slot() -> @knowledge.Slot[Unit, Source?] {
  ProgramUnit::cls().property(
    name=core_name("unit-source"),
    domain=source_domain(),
    desc="the source of the unit",
    persistent=optional_source_persistent(),
    public=true,
  )
}

///|
pub fn ProgramUnit::compiler_slot() -> @knowledge.Slot[Unit, Compiler?] {
  ProgramUnit::cls().property(
    name=core_name("unit-compiler"),
    domain=Compiler::domain(),
    desc="the compiler that compiled the unit",
    persistent=optional_compiler_persistent(),
    public=true,
  )
}

///|
pub fn ProgramUnitFacts::class(
  self : ProgramUnitFacts,
) -> @knowledge.Class[Unit, Unit] {
  self.class_value
}

///|
pub fn ProgramUnitFacts::create(
  self : ProgramUnitFacts,
) -> @knowledge.Object[Unit] {
  self.state_value.create(self.class_value)
}

///|
pub fn ProgramUnitFacts::path(
  self : ProgramUnitFacts,
) -> @knowledge.FactTable[Unit, String?] {
  self.path_value
}

///|
pub fn ProgramUnitFacts::bias(
  self : ProgramUnitFacts,
) -> @knowledge.FactTable[Unit, @types.Word?] {
  self.bias_value
}

///|
pub fn ProgramUnitFacts::target(
  self : ProgramUnitFacts,
) -> @knowledge.FactTable[Unit, Target] {
  self.target_value
}

///|
pub fn ProgramUnitFacts::source(
  self : ProgramUnitFacts,
) -> @knowledge.FactTable[Unit, Source?] {
  self.source_value
}

///|
pub fn ProgramUnitFacts::compiler(
  self : ProgramUnitFacts,
) -> @knowledge.FactTable[Unit, Compiler?] {
  self.compiler_value
}

///|
pub fn ProgramUnitFacts::provide_unit(
  self : ProgramUnitFacts,
  object : @knowledge.Object[Unit],
  unit : ProgramUnit,
) -> Result[Unit, String] {
  match self.path_value.provide(object, unit.path()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match self.bias_value.provide(object, unit.bias()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match self.target_value.provide(object, unit.target()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match self.source_value.provide(object, unit.source()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match self.compiler_value.provide(object, unit.compiler()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  Ok(())
}

///|
pub fn ProgramUnitFacts::for_unit(
  self : ProgramUnitFacts,
  unit : ProgramUnit,
) -> Result[@knowledge.Object[Unit], String] {
  let object = self.create()
  match self.provide_unit(object, unit) {
    Ok(_) => Ok(object)
    Err(reason) => Err(reason)
  }
}

///|
pub fn ProgramUnitFacts::collect_path(
  self : ProgramUnitFacts,
  object : @knowledge.Object[Unit],
) -> String? {
  match self.path_value.collect(object) {
    Some(path) => path
    None => None
  }
}

///|
pub fn ProgramUnitFacts::collect_bias(
  self : ProgramUnitFacts,
  object : @knowledge.Object[Unit],
) -> @types.Word? {
  match self.bias_value.collect(object) {
    Some(bias) => bias
    None => None
  }
}

///|
pub fn ProgramUnitFacts::collect_target(
  self : ProgramUnitFacts,
  object : @knowledge.Object[Unit],
) -> Target {
  match self.target_value.collect(object) {
    Some(target) => target
    None => Target::unknown()
  }
}

///|
pub fn ProgramUnitFacts::collect_source(
  self : ProgramUnitFacts,
  object : @knowledge.Object[Unit],
) -> Source? {
  match self.source_value.collect(object) {
    Some(source) => source
    None => None
  }
}

///|
pub fn ProgramUnitFacts::collect_compiler(
  self : ProgramUnitFacts,
  object : @knowledge.Object[Unit],
) -> Compiler? {
  match self.compiler_value.collect(object) {
    Some(compiler) => compiler
    None => None
  }
}
