///|
let program_unit_counter : Ref[Int] = Ref(0)

///|
let interned_program_unit_ids : Map[String, Int] = {}

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
fn program_unit_pkg(pkg? : String) -> String {
  @knowledge.Name::read("unit", pkg?).pkg()
}

///|
fn interned_program_unit_id(kind : String, value : String) -> Int {
  let key = "\{kind}|\{value}"
  match interned_program_unit_ids.get(key) {
    Some(id) => id
    None => {
      let id = next_program_unit_id()
      interned_program_unit_ids[key] = id
      id
    }
  }
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
pub fn Language::unknown() -> Language {
  OtherLanguage("unknown")
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
pub fn Language::is_unknown(self : Language) -> Bool {
  self == Language::unknown()
}

///|
fn Language::rank(self : Language) -> Int {
  match self {
    C => 0
    Cxx => 1
    Ada => 2
    Fortran => 3
    Pascal => 4
    OtherLanguage(_) => 5
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
pub fn Language::persistent() -> @knowledge.Persistent[Language] {
  @knowledge.Persistent::convert(
    to_persistent=language => language.to_string(),
    of_persistent=input => Ok(Language::of_string(input)),
    @knowledge.Persistent::string(),
  )
}

///|
pub fn Language::equal(self : Language, other : Language) -> Bool {
  self == other
}

///|
pub fn Language::compare(self : Language, other : Language) -> Int {
  let rank_order = self.rank().compare(other.rank())
  if rank_order != 0 {
    return rank_order
  }
  match (self, other) {
    (OtherLanguage(lhs), OtherLanguage(rhs)) => lhs.compare(rhs)
    _ => 0
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
      None => Language::unknown()
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
pub fn Source::equal(self : Source, other : Source) -> Bool {
  self.language_value.equal(other.language_value) &&
  self.code_value == other.code_value &&
  self.file_value == other.file_value
}

///|
fn optional_string_compare(lhs : String?, rhs : String?) -> Int {
  match (lhs, rhs) {
    (None, None) => 0
    (None, Some(_)) => -1
    (Some(_), None) => 1
    (Some(left), Some(right)) => left.compare(right)
  }
}

///|
pub fn Source::compare(self : Source, other : Source) -> Int {
  let language_order = self.language_value.compare(other.language_value)
  if language_order != 0 {
    return language_order
  }
  let code_order = self.code_value.compare(other.code_value)
  if code_order != 0 {
    return code_order
  }
  optional_string_compare(self.file_value, other.file_value)
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
fn persistent_string_fields() -> @knowledge.Persistent[Array[String]] {
  @knowledge.Persistent::array(@knowledge.Persistent::string())
}

///|
fn persistent_decode_fields(
  fields : Array[String],
  count : Int,
  context : String,
) -> Result[Array[String], String] {
  if fields.length() == count {
    Ok(fields)
  } else {
    Err(
      "invalid persistent \{context} encoding: expected \{count} fields, got \{fields.length()}",
    )
  }
}

///|
pub fn Source::persistent() -> @knowledge.Persistent[Source] {
  let file_codec = @knowledge.Persistent::optional(
    @knowledge.Persistent::string(),
  )
  @knowledge.Persistent::convert(
    to_persistent=source => {
      [
        source.language().to_string(),
        source.code(),
        file_codec.encode(source.file()),
      ]
    },
    of_persistent=fields => {
      match persistent_decode_fields(fields, 3, "source") {
        Ok(_) => ()
        Err(reason) => return Err(reason)
      }
      let file = match file_codec.decode(fields[2]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(
        Source::create(
          language=Language::of_string(fields[0]),
          code=fields[1],
          file?,
        ),
      )
    },
    persistent_string_fields(),
  )
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
fn compiler_sexp_needs_quote(text : String) -> Bool {
  if text == "" {
    return true
  }
  for ch in text {
    match ch {
      '(' | ')' | '"' | '\\' | ' ' | '\n' | '\r' | '\t' => return true
      _ => ()
    }
  }
  false
}

///|
fn compiler_sexp_atom(text : String) -> String {
  if !compiler_sexp_needs_quote(text) {
    return text
  }
  let builder = StringBuilder()
  builder.write_char('"')
  for ch in text {
    match ch {
      '\\' => builder.write_string("\\\\")
      '"' => builder.write_string("\\\"")
      '\n' => builder.write_string("\\n")
      '\r' => builder.write_string("\\r")
      '\t' => builder.write_string("\\t")
      other => builder.write_char(other)
    }
  }
  builder.write_char('"')
  builder.to_string()
}

///|
fn compiler_sexp_list(items : Array[String]) -> String {
  "(\{items.join(" ")})"
}

///|
fn compiler_sexp_string_list(items : Array[String]) -> String {
  compiler_sexp_list([ for item in items => compiler_sexp_atom(item) ])
}

///|
fn compiler_sexp_string_map(items : Map[String, String]) -> String {
  let entries = []
  for entry in items {
    entries.push(entry)
  }
  entries.sort_by(fn(lhs, rhs) { lhs.0.compare(rhs.0) })
  compiler_sexp_list(
    [
      for entry in entries => {
        compiler_sexp_list([
          compiler_sexp_atom(entry.0),
          compiler_sexp_atom(entry.1),
        ])
      }
    ],
  )
}

///|
pub fn Compiler::to_string(self : Compiler) -> String {
  compiler_sexp_list([
    compiler_sexp_list(["name", compiler_sexp_atom(self.name_value)]),
    compiler_sexp_list([
      "version",
      compiler_sexp_string_list(self.version_value),
    ]),
    compiler_sexp_list([
      "options",
      compiler_sexp_string_list(self.options_value),
    ]),
    compiler_sexp_list(["specs", compiler_sexp_string_map(self.specs_value)]),
  ])
}

///|
pub fn Compiler::persistent() -> @knowledge.Persistent[Compiler] {
  let string_codec = @knowledge.Persistent::string()
  let string_array_codec = @knowledge.Persistent::array(string_codec)
  let specs_codec = @knowledge.Persistent::map(string_codec, string_codec)
  @knowledge.Persistent::convert(
    to_persistent=compiler => {
      [
        compiler.name(),
        string_array_codec.encode(compiler.version()),
        string_array_codec.encode(compiler.options()),
        specs_codec.encode(compiler.specs()),
      ]
    },
    of_persistent=fields => {
      match persistent_decode_fields(fields, 4, "compiler") {
        Ok(_) => ()
        Err(reason) => return Err(reason)
      }
      let version = match string_array_codec.decode(fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let options = match string_array_codec.decode(fields[2]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let specs = match specs_codec.decode(fields[3]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(Compiler::create(fields[0], version~, options~, specs~))
    },
    persistent_string_fields(),
  )
}

///|
fn ensure_program_unit_counter_at_least(id : Int) -> Unit {
  if program_unit_counter.val < id {
    program_unit_counter.val = id
  }
}

///|
fn ProgramUnit::make(
  id? : Int,
  path? : String,
  lower? : @types.Word,
  upper? : @types.Word,
  bias? : @types.Word,
  target? : Target,
  source? : Source,
  compiler? : Compiler,
) -> ProgramUnit {
  {
    id_value: match id {
      Some(value) => value
      None => next_program_unit_id()
    },
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
  ProgramUnit::make(
    id=interned_program_unit_id("file", path),
    path~,
    target?,
    bias?,
    source?,
    compiler?,
  )
}

///|
pub fn ProgramUnit::for_region(
  lower~ : @types.Word,
  upper~ : @types.Word,
  target? : Target,
  bias? : @types.Word,
  source? : Source,
  compiler? : Compiler,
  pkg? : String,
) -> ProgramUnit {
  let region_pkg = program_unit_pkg(pkg?)
  ProgramUnit::make(
    id=interned_program_unit_id(
      "region",
      "\{region_pkg}|\{lower.to_hex()}-\{upper.to_hex()}",
    ),
    lower~,
    upper~,
    target?,
    bias?,
    source?,
    compiler?,
  )
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
pub fn ProgramUnit::compare(self : ProgramUnit, other : ProgramUnit) -> Int {
  self.id_value.compare(other.id_value)
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
fn ProgramUnit::persistent_kind(self : ProgramUnit) -> String {
  match self.path_value {
    Some(_) => "file"
    None =>
      match (self.lower_value, self.upper_value) {
        (Some(_), Some(_)) => "region"
        _ => "fresh"
      }
  }
}

///|
fn[T] persistent_require_some(
  value : T?,
  field : String,
  context : String,
) -> Result[T, String] {
  match value {
    Some(item) => Ok(item)
    None => Err("invalid persistent \{context} encoding: missing \{field}")
  }
}

///|
pub fn ProgramUnit::persistent() -> @knowledge.Persistent[ProgramUnit] {
  let int_codec = @knowledge.Persistent::int()
  let opt_string_codec = @knowledge.Persistent::optional(
    @knowledge.Persistent::string(),
  )
  let opt_word_codec = @knowledge.Persistent::optional(word_persistent())
  let target_codec = Target::persistent()
  let opt_source_codec = @knowledge.Persistent::optional(Source::persistent())
  let opt_compiler_codec = @knowledge.Persistent::optional(
    Compiler::persistent(),
  )
  @knowledge.Persistent::convert(
    to_persistent=unit => {
      [
        unit.persistent_kind(),
        int_codec.encode(unit.id()),
        opt_string_codec.encode(unit.path()),
        opt_word_codec.encode(unit.lower()),
        opt_word_codec.encode(unit.upper()),
        opt_word_codec.encode(unit.bias()),
        target_codec.encode(unit.target()),
        opt_source_codec.encode(unit.source()),
        opt_compiler_codec.encode(unit.compiler()),
      ]
    },
    of_persistent=fields => {
      match persistent_decode_fields(fields, 9, "program unit") {
        Ok(_) => ()
        Err(reason) => return Err(reason)
      }
      let id = match int_codec.decode(fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let path = match opt_string_codec.decode(fields[2]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let lower = match opt_word_codec.decode(fields[3]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let upper = match opt_word_codec.decode(fields[4]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let bias = match opt_word_codec.decode(fields[5]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let target = match target_codec.decode(fields[6]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let source = match opt_source_codec.decode(fields[7]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let compiler = match opt_compiler_codec.decode(fields[8]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      match fields[0] {
        "file" => {
          let file_path = match
            persistent_require_some(path, "path", "program unit") {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          Ok(
            ProgramUnit::for_file(file_path, target~, bias?, source?, compiler?),
          )
        }
        "region" => {
          let lower = match
            persistent_require_some(lower, "lower", "program unit") {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          let upper = match
            persistent_require_some(upper, "upper", "program unit") {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          Ok(
            ProgramUnit::for_region(
              lower~,
              upper~,
              target~,
              bias?,
              source?,
              compiler?,
            ),
          )
        }
        "fresh" => {
          ensure_program_unit_counter_at_least(id)
          Ok(
            ProgramUnit::make(
              id~,
              path?,
              lower?,
              upper?,
              bias?,
              target~,
              source?,
              compiler?,
            ),
          )
        }
        _ => Err("invalid persistent program unit encoding: invalid kind")
      }
    },
    persistent_string_fields(),
  )
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
fn optional_target_equal(lhs : Target?, rhs : Target?) -> Bool {
  match (lhs, rhs) {
    (None, None) => true
    (Some(left), Some(right)) => left.equal(right)
    _ => false
  }
}

///|
fn optional_target_compare(lhs : Target?, rhs : Target?) -> Int {
  match (lhs, rhs) {
    (None, None) => 0
    (None, Some(_)) => -1
    (Some(_), None) => 1
    (Some(left), Some(right)) => left.compare(right)
  }
}

///|
fn program_unit_array_compare(
  lhs : Array[ProgramUnit],
  rhs : Array[ProgramUnit],
) -> Int {
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
fn label_array_compare(lhs : Array[Label], rhs : Array[Label]) -> Int {
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
pub fn Program::equal(self : Program, other : Program) -> Bool {
  program_unit_array_compare(self.units_value, other.units_value) == 0 &&
  label_array_compare(self.labels_value, other.labels_value) == 0 &&
  optional_target_equal(self.target(), other.target())
}

///|
pub fn Program::compare(self : Program, other : Program) -> Int {
  let unit_order = program_unit_array_compare(
    self.units_value,
    other.units_value,
  )
  if unit_order != 0 {
    return unit_order
  }
  let label_order = label_array_compare(self.labels_value, other.labels_value)
  if label_order != 0 {
    return label_order
  }
  optional_target_compare(self.target(), other.target())
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
