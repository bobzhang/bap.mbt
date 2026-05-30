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
fn compiler_inspect(compiler : Compiler) -> String {
  compiler.to_string()
}

///|
fn compiler_domain() -> @knowledge.Domain[Compiler?] {
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
fn target_domain() -> @knowledge.Domain[Target] {
  let unknown = Target::unknown()
  @knowledge.Domain::new(
    name=core_name("unit-target"),
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
pub fn SourceFacts::new() -> SourceFacts {
  let cls : @knowledge.Class[Unit, Unit] = @knowledge.Class::create(
    name=core_name("unit-source"),
    sort=(),
    desc="source-code artifact",
  )
  let language = cls.property(
    name=core_name("source-language"),
    domain=source_language_domain(),
    desc="the language of the unit source code",
  )
  let code = cls.property(
    name=core_name("source-code"),
    domain=@knowledge.Domain::string(core_name("source-code")),
    desc="the unit source code text",
  )
  let file = cls.property(
    name=core_name("source-path"),
    domain=optional_string_domain("source-path"),
    desc="a path to the source code file",
  )
  {
    state_value: @knowledge.State::new(),
    class_value: cls,
    language_value: @knowledge.FactTable::new(language),
    code_value: @knowledge.FactTable::new(code),
    file_value: @knowledge.FactTable::new(file),
  }
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
pub fn SourceFacts::collect_source(
  self : SourceFacts,
  object : @knowledge.Object[Unit],
) -> Source {
  let language = match self.language_value.collect(object) {
    Some(value) => value
    None => OtherLanguage("unknown")
  }
  let code = match self.code_value.collect(object) {
    Some(value) => value
    None => ""
  }
  match self.file_value.collect(object) {
    Some(Some(file)) => Source::create(language~, code~, file~)
    _ => Source::create(language~, code~)
  }
}

///|
pub fn ProgramUnitFacts::new() -> ProgramUnitFacts {
  let cls : @knowledge.Class[Unit, Unit] = @knowledge.Class::create(
    name=core_name("unit"),
    sort=(),
    desc="a unit of code",
  )
  let path = cls.property(
    name=core_name("unit-path"),
    domain=optional_string_domain("unit-path"),
    desc="a filesystem name of the file that contains the program",
  )
  let bias = cls.property(
    name=core_name("unit-bias"),
    domain=optional_word_domain("unit-bias"),
    desc="the value by which all addresses of the unit are biased",
  )
  let target = cls.property(
    name=core_name("unit-target"),
    domain=target_domain(),
    desc="the target system for the unit",
  )
  let source = cls.property(
    name=core_name("unit-source"),
    domain=source_domain(),
    desc="the source of the unit",
  )
  let compiler = cls.property(
    name=core_name("unit-compiler"),
    domain=compiler_domain(),
    desc="the compiler that compiled the unit",
  )
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
