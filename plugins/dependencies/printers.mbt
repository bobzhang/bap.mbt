///|
/// Output formats of the `dependencies` command.
pub(all) enum DependencyFormat {
  Yaml
  Sexp
  Json
  Graph
} derive(Eq, Debug)

///|
pub extend DependencyFormat with Eq::{not_equal, equal}

///|
pub extend DependencyFormat with Debug::{to_repr}

///|
/// OCaml `%S` string quoting.
fn ocaml_quote(s : String) -> String {
  let sb = StringBuilder()
  sb.write_char('"')
  for c in s {
    match c {
      '"' => sb.write_string("\\\"")
      '\\' => sb.write_string("\\\\")
      '\n' => sb.write_string("\\n")
      '\t' => sb.write_string("\\t")
      '\r' => sb.write_string("\\r")
      _ => sb.write_char(c)
    }
  }
  sb.write_char('"')
  sb.to_string()
}

///|
fn yaml_list(items : Array[String]) -> String {
  items.map(x => "    - \{x}").join("\n")
}

///|
/// Renders a unit in YAML (`Unit.Yaml.pp`).
pub fn yaml_unit(unit : DependencyInfo) -> String {
  "\n\{unit.name}:\n  imports:\n\{yaml_list(unit.imports)}\n  exports:\n\{yaml_list(unit.exports)}\n  libraries:\n\{yaml_list(unit.libraries)}\n"
}

///|
/// Renders a unit as an S-expression (`Unit.Sexp.pp`), on a single line.
pub fn sexp_unit(unit : DependencyInfo) -> String {
  let sb = StringBuilder()
  sb.write_string("(\{unit.name}")
  for
    field in [
      ("imports", unit.imports),
      ("exports", unit.exports),
      ("libraries", unit.libraries),
    ] {
    if !field.1.is_empty() {
      sb.write_string(" (\{field.0} \{field.1.join(" ")})")
    }
  }
  sb.write_string(")")
  sb.to_string()
}

///|
/// Renders a unit as JSON (`Unit.Json.pp`).
pub fn json_unit(unit : DependencyInfo) -> String {
  let list = (xs : Array[String]) => xs.map(ocaml_quote).join(", ")
  "  \{ocaml_quote(unit.name)}: {\n    \"imports\": [\{list(unit.imports)}],\n    \"exports\": [\{list(unit.exports)}],\n    \"libraries\": [\{list(unit.libraries)}]\n  }"
}

///|
/// Renders the library edges of a unit (`Unit.Deps.pp`).
pub fn graph_unit(unit : DependencyInfo) -> String {
  unit.libraries
  .map(dep => "\{ocaml_quote(unit.name)} -> \{ocaml_quote(dep)}\n")
  .join("")
}

///|
/// Renders the collected dependencies in the given format, including the
/// final newline (`pp`).
pub fn DependencyState::render(
  self : DependencyState,
  format : DependencyFormat,
) -> String {
  let units = self.sorted_units()
  match format {
    Yaml => units.map(u => yaml_unit(u) + "\n").join("") + "\n"
    Sexp => units.map(u => sexp_unit(u) + "\n").join("") + "\n"
    Json => "{\n" + units.map(json_unit).join(",\n") + "\n}\n"
    Graph =>
      "digraph \{ocaml_quote(self.root)} {\n" +
      units.map(u => graph_unit(u) + "\n").join("") +
      "}\n"
  }
}
