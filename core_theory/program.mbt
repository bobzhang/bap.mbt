///|
let program_unit_counter : Ref[Int] = Ref(0)

///|
pub(all) enum Language {
  C
  Cxx
  Ada
  Fortran
  Pascal
  OtherLanguage(String)
} derive(Eq, Debug)

///|
struct Source {
  language_value : Language
  code_value : String
  file_value : String?
}

///|
struct Compiler {
  name_value : String
  version_value : Array[String]
  options_value : Array[String]
  specs_value : Map[String, String]
}

///|
struct ProgramUnit {
  id_value : Int
  path_value : String?
  lower_value : @types.Word?
  upper_value : @types.Word?
  bias_value : @types.Word?
  target_value : Target
  source_value : Source?
  compiler_value : Compiler?
}

///|
struct Program {
  units_value : Array[ProgramUnit]
  labels_value : Array[Label]
  target_value : Target?
}

///|
fn next_program_unit_id() -> Int {
  program_unit_counter.val = program_unit_counter.val + 1
  program_unit_counter.val
}

///|
fn default_target(target : Target?) -> Target {
  match target {
    Some(value) => value
    None => Target::unknown()
  }
}

///|
pub fn Language::c() -> Language {
  C
}

///|
pub fn Language::cxx() -> Language {
  Cxx
}

///|
pub fn Language::ada() -> Language {
  Ada
}

///|
pub fn Language::fortran() -> Language {
  Fortran
}

///|
pub fn Language::pascal() -> Language {
  Pascal
}

///|
pub fn Language::of_string(name : String) -> Language {
  match name.to_lower() {
    "c" => C
    "c++" | "cpp" | "cxx" => Cxx
    "ada" => Ada
    "fortran" => Fortran
    "pascal" => Pascal
    other => OtherLanguage(other)
  }
}

///|
pub fn Language::to_string(self : Language) -> String {
  match self {
    C => "c"
    Cxx => "cxx"
    Ada => "ada"
    Fortran => "fortran"
    Pascal => "pascal"
    OtherLanguage(name) => name
  }
}

///|
pub fn Source::create(
  language? : Language,
  code? : String,
  file? : String,
) -> Source {
  {
    language_value: match language {
      Some(value) => value
      None => OtherLanguage("unknown")
    },
    code_value: match code {
      Some(text) => text
      None => ""
    },
    file_value: file,
  }
}

///|
pub fn Source::language(self : Source) -> Language {
  self.language_value
}

///|
pub fn Source::code(self : Source) -> String {
  self.code_value
}

///|
pub fn Source::file(self : Source) -> String? {
  self.file_value
}

///|
pub fn Source::with_language(self : Source, language : Language) -> Source {
  { ..self, language_value: language }
}

///|
pub fn Source::with_code(self : Source, code : String) -> Source {
  { ..self, code_value: code }
}

///|
pub fn Source::with_file(self : Source, file : String) -> Source {
  { ..self, file_value: Some(file) }
}

///|
pub fn Compiler::create(
  name : String,
  specs? : Map[String, String],
  version? : Array[String],
  options? : Array[String],
) -> Compiler {
  {
    name_value: name,
    version_value: match version {
      Some(items) => items.copy()
      None => []
    },
    options_value: match options {
      Some(items) => items.copy()
      None => []
    },
    specs_value: match specs {
      Some(items) => items.copy()
      None => {}
    },
  }
}

///|
pub fn Compiler::name(self : Compiler) -> String {
  self.name_value
}

///|
pub fn Compiler::version(self : Compiler) -> Array[String] {
  self.version_value.copy()
}

///|
pub fn Compiler::options(self : Compiler) -> Array[String] {
  self.options_value.copy()
}

///|
pub fn Compiler::specs(self : Compiler) -> Map[String, String] {
  self.specs_value.copy()
}

///|
pub fn Compiler::spec(self : Compiler, key : String) -> String? {
  self.specs_value.get(key)
}

///|
pub fn Compiler::to_string(self : Compiler) -> String {
  let parts = [self.name_value]
  if !self.version_value.is_empty() {
    parts.push(self.version_value.join("."))
  }
  for option in self.options_value {
    parts.push(option)
  }
  parts.join(" ")
}

///|
fn ProgramUnit::make(
  path? : String,
  lower? : @types.Word,
  upper? : @types.Word,
  bias? : @types.Word,
  target? : Target,
  source? : Source,
  compiler? : Compiler,
) -> ProgramUnit {
  {
    id_value: next_program_unit_id(),
    path_value: path,
    lower_value: lower,
    upper_value: upper,
    bias_value: bias,
    target_value: default_target(target),
    source_value: source,
    compiler_value: compiler,
  }
}

///|
pub fn ProgramUnit::fresh(
  target? : Target,
  source? : Source,
  compiler? : Compiler,
) -> ProgramUnit {
  ProgramUnit::make(target?, source?, compiler?)
}

///|
pub fn ProgramUnit::for_file(
  path : String,
  target? : Target,
  bias? : @types.Word,
  source? : Source,
  compiler? : Compiler,
) -> ProgramUnit {
  ProgramUnit::make(path~, target?, bias?, source?, compiler?)
}

///|
pub fn ProgramUnit::for_region(
  lower~ : @types.Word,
  upper~ : @types.Word,
  target? : Target,
  bias? : @types.Word,
  source? : Source,
  compiler? : Compiler,
) -> ProgramUnit {
  ProgramUnit::make(lower~, upper~, target?, bias?, source?, compiler?)
}

///|
pub fn ProgramUnit::id(self : ProgramUnit) -> Int {
  self.id_value
}

///|
pub fn ProgramUnit::same(self : ProgramUnit, other : ProgramUnit) -> Bool {
  self.id_value == other.id_value
}

///|
pub fn ProgramUnit::path(self : ProgramUnit) -> String? {
  self.path_value
}

///|
pub fn ProgramUnit::lower(self : ProgramUnit) -> @types.Word? {
  self.lower_value
}

///|
pub fn ProgramUnit::upper(self : ProgramUnit) -> @types.Word? {
  self.upper_value
}

///|
pub fn ProgramUnit::bias(self : ProgramUnit) -> @types.Word? {
  self.bias_value
}

///|
fn unit_bias_error() -> Result[@types.Word, String] {
  Err("program unit bias conversion requires addresses with matching widths")
}

///|
pub fn ProgramUnit::to_real_addr(
  self : ProgramUnit,
  address : @types.Word,
) -> Result[@types.Word, String] {
  match self.bias_value {
    Some(bias) =>
      try address.sub(bias) catch {
        _ => unit_bias_error()
      } noraise {
        real => Ok(real)
      }
    None => Ok(address)
  }
}

///|
pub fn ProgramUnit::to_biased_addr(
  self : ProgramUnit,
  address : @types.Word,
) -> Result[@types.Word, String] {
  match self.bias_value {
    Some(bias) =>
      try address.add(bias) catch {
        _ => unit_bias_error()
      } noraise {
        biased => Ok(biased)
      }
    None => Ok(address)
  }
}

///|
pub fn ProgramUnit::target(self : ProgramUnit) -> Target {
  self.target_value
}

///|
pub fn ProgramUnit::source(self : ProgramUnit) -> Source? {
  self.source_value
}

///|
pub fn ProgramUnit::compiler(self : ProgramUnit) -> Compiler? {
  self.compiler_value
}

///|
pub fn ProgramUnit::with_target(
  self : ProgramUnit,
  target : Target,
) -> ProgramUnit {
  { ..self, target_value: target }
}

///|
pub fn ProgramUnit::with_bias(
  self : ProgramUnit,
  bias : @types.Word,
) -> ProgramUnit {
  { ..self, bias_value: Some(bias) }
}

///|
pub fn ProgramUnit::with_source(
  self : ProgramUnit,
  source : Source,
) -> ProgramUnit {
  { ..self, source_value: Some(source) }
}

///|
pub fn ProgramUnit::with_compiler(
  self : ProgramUnit,
  compiler : Compiler,
) -> ProgramUnit {
  { ..self, compiler_value: Some(compiler) }
}

///|
pub fn ProgramUnit::name(self : ProgramUnit) -> String {
  match self.path_value {
    Some(path) => path
    None =>
      match (self.lower_value, self.upper_value) {
        (Some(lower), Some(upper)) => "\{lower.to_hex()}-\{upper.to_hex()}"
        _ => "unit:\{self.id_value}"
      }
  }
}

///|
pub fn Program::create(
  units? : Array[ProgramUnit],
  labels? : Array[Label],
  target? : Target,
) -> Program {
  {
    units_value: match units {
      Some(items) => items.copy()
      None => []
    },
    labels_value: match labels {
      Some(items) => items.copy()
      None => []
    },
    target_value: target,
  }
}

///|
pub fn Program::units(self : Program) -> Array[ProgramUnit] {
  self.units_value.copy()
}

///|
pub fn Program::labels(self : Program) -> Array[Label] {
  self.labels_value.copy()
}

///|
pub fn Program::target(self : Program) -> Target? {
  match self.target_value {
    Some(target) => Some(target)
    None =>
      if self.units_value.is_empty() {
        None
      } else {
        Some(self.units_value[0].target())
      }
  }
}

///|
pub fn Program::add_unit(self : Program, unit : ProgramUnit) -> Program {
  let units = self.units_value.copy()
  units.push(unit)
  { ..self, units_value: units }
}

///|
pub fn Program::add_label(self : Program, label : Label) -> Program {
  let labels = self.labels_value.copy()
  labels.push(label)
  { ..self, labels_value: labels }
}
