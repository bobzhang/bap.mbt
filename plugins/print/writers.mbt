// The project writers registry (upstream `Project.add_writer`) and the
// IR term writers (upstream `Program.add_writer`, `Sub.add_writer`, ...).

///|
/// A named project output format.
struct Writer {
  name : String
  desc : String
  ver : String
  pp : (@text_tags.Formatter, @project.Project) -> Unit
}

///|
pub fn Writer::name(self : Writer) -> String {
  self.name
}

///|
pub fn Writer::desc(self : Writer) -> String {
  self.desc
}

///|
pub fn Writer::version(self : Writer) -> String {
  self.ver
}

///|
/// Prints the project into the formatter.
pub fn Writer::pp(
  self : Writer,
  fmt : @text_tags.Formatter,
  project : @project.Project,
) -> Unit {
  (self.pp)(fmt, project)
}

///|
/// Renders the project into a string.
pub fn Writer::to_string(self : Writer, project : @project.Project) -> String {
  let fmt = @text_tags.Formatter::new()
  (self.pp)(fmt, project)
  fmt.flush_str()
}

///|
let writer_registry : Array[Writer] = []

///|
/// Adds (or replaces) a project writer.
pub fn add_writer(
  name : String,
  desc~ : String,
  ver? : String = @bap_main.Configuration::version(),
  pp : (@text_tags.Formatter, @project.Project) -> Unit,
) -> Unit {
  let writer = { name, desc, ver, pp, }
  match writer_registry.search_by(w => w.name == name) {
    Some(i) => writer_registry[i] = writer
    None => writer_registry.push(writer)
  }
}

///|
/// All registered project writers, in the registration order.
pub fn writers() -> Array[Writer] {
  writer_registry.copy()
}

///|
pub fn find_writer(name : String) -> Writer? {
  writer_registry.iter().find_first(w => w.name == name)
}

///|
/// Renders the project with the writer `name`.
pub fn write(
  name : String,
  project : @project.Project,
) -> Result[String, String] {
  match find_writer(name) {
    Some(w) => Ok(w.to_string(project))
    None => Err("unknown output format \{name}")
  }
}

///|
/// A named IR term output format.
priv struct TermWriter {
  cls : @types.IrTermClass
  name : String
  desc : String
  pp : (@text_tags.Formatter, @types.IrTerm) -> Unit
}

///|
let term_writer_registry : Array[TermWriter] = []

///|
fn add_term_writer(
  cls : @types.IrTermClass,
  name : String,
  desc~ : String,
  pp : (@text_tags.Formatter, @types.IrTerm) -> Unit,
) -> Unit {
  let writer = { cls, name, desc, pp, }
  match term_writer_registry.search_by(w => w.cls == cls && w.name == name) {
    Some(i) => term_writer_registry[i] = writer
    None => term_writer_registry.push(writer)
  }
}

///|
/// The registered IR term writers as `(term class, format, description)`.
pub fn term_writers() -> Array[(@types.IrTermClass, String, String)] {
  term_writer_registry.map(w => (w.cls, w.name, w.desc))
}

///|
/// Renders an IR term with the term writer `format` of its class.
pub fn write_term(
  term : @types.IrTerm,
  format : String,
) -> Result[String, String] {
  let cls = term.class()
  match
    term_writer_registry
    .iter()
    .find_first(w => w.cls == cls && w.name == format) {
    Some(w) => {
      let fmt = @text_tags.Formatter::new()
      (w.pp)(fmt, term)
      Ok(fmt.flush_str())
    }
    None => Err("unknown output format \{format}")
  }
}
