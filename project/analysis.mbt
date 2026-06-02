///|
priv struct ProjectAnalysisContext {
  rule_value : String
  position_value : Int
  parsed_value : Array[String]
  inputs_value : Array[String]
}

///|
struct ProjectAnalysisArg[T] {
  rule_value : String
  description_value : String
  parse_fn : (ProjectAnalysisContext) -> Result[
    (T, ProjectAnalysisContext),
    String,
  ]
}

///|
struct ProjectAnalysisArgs[T] {
  grammar_value : Array[String]
  parse_fn : (Array[String]) -> Result[T, String]
}

///|
struct ProjectAnalysisInfo {
  name_value : @knowledge.Name
  description_value : String
  grammar_value : Array[String]
}

///|
struct ProjectAnalysis {
  info_value : ProjectAnalysisInfo
  apply_fn : (Array[String]) -> Result[Unit, String]
}

///|
let project_analysis_registry : Map[String, ProjectAnalysis] = {}

///|
fn project_analysis_context(inputs : Array[String]) -> ProjectAnalysisContext {
  {
    rule_value: "",
    position_value: 0,
    parsed_value: [],
    inputs_value: inputs.copy(),
  }
}

///|
fn project_analysis_drop_first(inputs : Array[String]) -> Array[String] {
  if inputs.length() <= 1 {
    []
  } else {
    [
      for i in 1..<inputs.length() => inputs[i]
    ]
  }
}

///|
fn project_analysis_parse_error(
  ctxt : ProjectAnalysisContext,
  problem : String,
) -> String {
  let rule = if ctxt.rule_value.is_empty() {
    "<argument>"
  } else {
    ctxt.rule_value
  }
  "Syntax error: when parsing rule \{rule} of argument \{ctxt.position_value + 1} - \{problem}"
}

///|
fn project_analysis_keyword_token(key : String) -> String {
  if key.has_prefix(":") {
    key
  } else {
    ":" + key
  }
}

///|
fn project_analysis_keyword_name(key : String) -> String {
  if key.has_prefix(":") {
    key[1:].to_owned()
  } else {
    key
  }
}

///|
fn project_analysis_pull_keyword(
  key : String,
  inputs : Array[String],
) -> Array[String]? {
  let token = project_analysis_keyword_token(key)
  for i in 0..<inputs.length() {
    if inputs[i] == token {
      if i + 1 < inputs.length() {
        let result = []
        result.push(inputs[i + 1])
        for j in 0..<i {
          result.push(inputs[j])
        }
        for j in (i + 2)..<inputs.length() {
          result.push(inputs[j])
        }
        return Some(result)
      } else if i == 0 && inputs.length() == 1 {
        return Some([])
      } else {
        return None
      }
    }
  }
  None
}

///|
fn project_analysis_filter_flag(
  key : String,
  inputs : Array[String],
) -> Array[String]? {
  let token = project_analysis_keyword_token(key)
  for i in 0..<inputs.length() {
    if inputs[i] == token {
      let result = []
      for j in 0..<i {
        result.push(inputs[j])
      }
      for j in (i + 1)..<inputs.length() {
        result.push(inputs[j])
      }
      return Some(result)
    }
  }
  None
}

///|
fn[T] project_analysis_parse_arg(
  arg : ProjectAnalysisArg[T],
  ctxt : ProjectAnalysisContext,
) -> Result[(T, ProjectAnalysisContext), String] {
  (arg.parse_fn)({ ..ctxt, rule_value: arg.rule_value })
}

///|
fn project_analysis_join_grammar(grammar : Array[String]) -> String {
  let builder = StringBuilder()
  for i in 0..<grammar.length() {
    if i > 0 {
      builder.write_char(' ')
    }
    builder.write_string(grammar[i])
  }
  builder.to_string()
}

///|
fn project_analysis_parse_bitvec(
  text : String,
) -> Result[@bitvec.BitVec, String] {
  try @bitvec.from_string(text) catch {
    _ => Err("invalid bitvector literal")
  } noraise {
    value => Ok(value)
  }
}

///|
pub fn[T] ProjectAnalysisArg::argument(
  rule~ : String,
  description? : String,
  parse~ : (String) -> Result[T, String],
) -> ProjectAnalysisArg[T] {
  {
    rule_value: rule,
    description_value: match description {
      Some(text) => text
      None => "No description"
    },
    parse_fn: ctxt => {
      if ctxt.inputs_value.is_empty() {
        Err(project_analysis_parse_error(ctxt, "expects an argument"))
      } else {
        let token = ctxt.inputs_value[0]
        match parse(token) {
          Err(reason) => Err(project_analysis_parse_error(ctxt, reason))
          Ok(value) => {
            let parsed = ctxt.parsed_value.copy()
            parsed.push(token)
            Ok(
              (
                value,
                {
                  ..ctxt,
                  position_value: ctxt.position_value + 1,
                  parsed_value: parsed,
                  inputs_value: project_analysis_drop_first(ctxt.inputs_value),
                },
              ),
            )
          }
        }
      }
    },
  }
}

///|
pub fn ProjectAnalysisArg::empty() -> ProjectAnalysisArg[Unit] {
  {
    rule_value: "",
    description_value: "no arguments are expected",
    parse_fn: ctxt => {
      if ctxt.inputs_value.is_empty() {
        Ok(((), ctxt))
      } else {
        Err(project_analysis_parse_error(ctxt, "too many arguments"))
      }
    },
  }
}

///|
pub fn ProjectAnalysisArg::string() -> ProjectAnalysisArg[String] {
  ProjectAnalysisArg::argument(
    rule="<string>",
    description="a sequence of characters without whitespace",
    parse=text => Ok(text),
  )
}

///|
pub fn ProjectAnalysisArg::int() -> ProjectAnalysisArg[Int] {
  ProjectAnalysisArg::argument(rule="<int>", description="an integer", parse=text => {
    try @string.parse_int(text) catch {
      _ => Err("invalid integer")
    } noraise {
      value => Ok(value)
    }
  })
}

///|
pub fn ProjectAnalysisArg::bitvec() -> ProjectAnalysisArg[@bitvec.BitVec] {
  ProjectAnalysisArg::argument(
    rule="<bitvec>",
    description="a bitvector literal",
    parse=project_analysis_parse_bitvec,
  )
}

///|
pub fn ProjectAnalysisArg::program() -> ProjectAnalysisArg[@core_theory.Label] {
  ProjectAnalysisArg::argument(
    rule="<label>",
    description="a core program label",
    parse=text => Ok(@core_theory.Label::for_name(text)),
  )
}

///|
pub fn ProjectAnalysisArg::unit() -> ProjectAnalysisArg[
  @core_theory.ProgramUnit,
] {
  ProjectAnalysisArg::argument(
    rule="<unit>",
    description="a core program unit",
    parse=text => Ok(@core_theory.ProgramUnit::for_file(text)),
  )
}

///|
pub fn[T] ProjectAnalysisArg::optional(
  arg : ProjectAnalysisArg[T],
) -> ProjectAnalysisArg[T?] {
  {
    rule_value: "[\{arg.rule_value}]",
    description_value: arg.description_value,
    parse_fn: ctxt => {
      if ctxt.inputs_value.is_empty() {
        Ok((None, ctxt))
      } else {
        match project_analysis_parse_arg(arg, ctxt) {
          Err(reason) => Err(reason)
          Ok((value, next)) => Ok((Some(value), next))
        }
      }
    },
  }
}

///|
pub fn[T] ProjectAnalysisArg::keyword(
  key : String,
  arg : ProjectAnalysisArg[T],
) -> ProjectAnalysisArg[T?] {
  let name = project_analysis_keyword_name(key)
  {
    rule_value: "[:\{name} \{arg.rule_value}]",
    description_value: "an argument prefixed by the keyword",
    parse_fn: ctxt => {
      match project_analysis_pull_keyword(key, ctxt.inputs_value) {
        None => Ok((None, ctxt))
        Some(inputs) =>
          match
            project_analysis_parse_arg(arg, { ..ctxt, inputs_value: inputs }) {
            Err(reason) => Err(reason)
            Ok((value, next)) => Ok((Some(value), next))
          }
      }
    },
  }
}

///|
pub fn ProjectAnalysisArg::flag(key : String) -> ProjectAnalysisArg[Bool] {
  let name = project_analysis_keyword_name(key)
  {
    rule_value: "[:\{name}]",
    description_value: "an optional flag",
    parse_fn: ctxt => {
      match project_analysis_filter_flag(key, ctxt.inputs_value) {
        None => Ok((false, ctxt))
        Some(inputs) => Ok((true, { ..ctxt, inputs_value: inputs }))
      }
    },
  }
}

///|
pub fn[T] ProjectAnalysisArg::rest(
  arg : ProjectAnalysisArg[T],
) -> ProjectAnalysisArg[Array[T]] {
  {
    rule_value: "[\{arg.rule_value}] ...",
    description_value: arg.description_value,
    parse_fn: ctxt => {
      let values : Array[T] = []
      let mut current = ctxt
      while !current.inputs_value.is_empty() {
        match project_analysis_parse_arg(arg, current) {
          Err(reason) => return Err(reason)
          Ok((value, next)) => {
            values.push(value)
            current = next
          }
        }
      }
      Ok((values, current))
    },
  }
}

///|
pub fn[A, B] ProjectAnalysisArg::map(
  self : ProjectAnalysisArg[A],
  f : (A) -> B,
) -> ProjectAnalysisArg[B] {
  {
    rule_value: self.rule_value,
    description_value: self.description_value,
    parse_fn: ctxt => {
      match project_analysis_parse_arg(self, ctxt) {
        Err(reason) => Err(reason)
        Ok((value, next)) => Ok((f(value), next))
      }
    },
  }
}

///|
pub fn[T] ProjectAnalysisArg::rule(self : ProjectAnalysisArg[T]) -> String {
  self.rule_value
}

///|
pub fn[T] ProjectAnalysisArg::description(
  self : ProjectAnalysisArg[T],
) -> String {
  self.description_value
}

///|
pub fn[T] ProjectAnalysisArgs::one(
  arg : ProjectAnalysisArg[T],
) -> ProjectAnalysisArgs[T] {
  {
    grammar_value: [arg.rule()],
    parse_fn: inputs => {
      let ctxt = project_analysis_context(inputs)
      match project_analysis_parse_arg(arg, ctxt) {
        Err(reason) => Err(reason)
        Ok((value, _)) => Ok(value)
      }
    },
  }
}

///|
pub fn[A, B] ProjectAnalysisArgs::pair(
  lhs : ProjectAnalysisArg[A],
  rhs : ProjectAnalysisArg[B],
) -> ProjectAnalysisArgs[(A, B)] {
  {
    grammar_value: [lhs.rule(), rhs.rule()],
    parse_fn: inputs => {
      let ctxt = project_analysis_context(inputs)
      match project_analysis_parse_arg(lhs, ctxt) {
        Err(reason) => Err(reason)
        Ok((left, next)) =>
          match project_analysis_parse_arg(rhs, next) {
            Err(reason) => Err(reason)
            Ok((right, _)) => Ok((left, right))
          }
      }
    },
  }
}

///|
pub fn[A, B, C] ProjectAnalysisArgs::triple(
  first : ProjectAnalysisArg[A],
  second : ProjectAnalysisArg[B],
  third : ProjectAnalysisArg[C],
) -> ProjectAnalysisArgs[(A, B, C)] {
  {
    grammar_value: [first.rule(), second.rule(), third.rule()],
    parse_fn: inputs => {
      let ctxt = project_analysis_context(inputs)
      match project_analysis_parse_arg(first, ctxt) {
        Err(reason) => Err(reason)
        Ok((a, ctxt)) =>
          match project_analysis_parse_arg(second, ctxt) {
            Err(reason) => Err(reason)
            Ok((b, ctxt)) =>
              match project_analysis_parse_arg(third, ctxt) {
                Err(reason) => Err(reason)
                Ok((c, _)) => Ok((a, b, c))
              }
          }
      }
    },
  }
}

///|
pub fn[T] ProjectAnalysisArgs::parse(
  self : ProjectAnalysisArgs[T],
  inputs : Array[String],
) -> Result[T, String] {
  (self.parse_fn)(inputs)
}

///|
pub fn[T] ProjectAnalysisArgs::grammar(
  self : ProjectAnalysisArgs[T],
) -> Array[String] {
  self.grammar_value.copy()
}

///|
pub fn[T] ProjectAnalysisArgs::grammar_string(
  self : ProjectAnalysisArgs[T],
) -> String {
  project_analysis_join_grammar(self.grammar_value)
}

///|
pub fn ProjectAnalysisInfo::name(self : ProjectAnalysisInfo) -> String {
  self.name_value.unqualified()
}

///|
pub fn ProjectAnalysisInfo::qualified_name(
  self : ProjectAnalysisInfo,
) -> @knowledge.Name {
  self.name_value
}

///|
pub fn ProjectAnalysisInfo::pkg(self : ProjectAnalysisInfo) -> String {
  self.name_value.pkg()
}

///|
pub fn ProjectAnalysisInfo::description(self : ProjectAnalysisInfo) -> String {
  self.description_value
}

///|
pub fn ProjectAnalysisInfo::grammar(
  self : ProjectAnalysisInfo,
) -> Array[String] {
  self.grammar_value.copy()
}

///|
pub fn ProjectAnalysisInfo::grammar_string(
  self : ProjectAnalysisInfo,
) -> String {
  project_analysis_join_grammar(self.grammar_value)
}

///|
pub fn[T] ProjectAnalysis::create(
  name~ : String,
  pkg? : String,
  description? : String,
  args~ : ProjectAnalysisArgs[T],
  run~ : (T) -> Result[Unit, String],
) -> ProjectAnalysis {
  let info = {
    name_value: @knowledge.Name::read(name, pkg?),
    description_value: match description {
      Some(text) => text
      None => ""
    },
    grammar_value: args.grammar(),
  }
  {
    info_value: info,
    apply_fn: inputs => {
      match args.parse(inputs) {
        Err(reason) => Err(reason)
        Ok(value) => run(value)
      }
    },
  }
}

///|
pub fn ProjectAnalysis::name(self : ProjectAnalysis) -> String {
  self.info_value.name()
}

///|
pub fn ProjectAnalysis::qualified_name(
  self : ProjectAnalysis,
) -> @knowledge.Name {
  self.info_value.qualified_name()
}

///|
pub fn ProjectAnalysis::pkg(self : ProjectAnalysis) -> String {
  self.info_value.pkg()
}

///|
pub fn ProjectAnalysis::description(self : ProjectAnalysis) -> String {
  self.info_value.description()
}

///|
pub fn ProjectAnalysis::grammar(self : ProjectAnalysis) -> Array[String] {
  self.info_value.grammar()
}

///|
pub fn ProjectAnalysis::grammar_string(self : ProjectAnalysis) -> String {
  self.info_value.grammar_string()
}

///|
pub fn ProjectAnalysis::info(self : ProjectAnalysis) -> ProjectAnalysisInfo {
  self.info_value
}

///|
pub fn ProjectAnalysis::apply(
  self : ProjectAnalysis,
  inputs : Array[String],
) -> Result[Unit, String] {
  (self.apply_fn)(inputs)
}

///|
pub fn register_analysis(analysis : ProjectAnalysis) -> Result[Unit, String] {
  let name = analysis.qualified_name().show()
  if project_analysis_registry.contains(name) {
    Err("project analysis \{name} is already registered")
  } else {
    project_analysis_registry[name] = analysis
    Ok(())
  }
}

///|
pub fn find_analysis(name : String, pkg? : String) -> ProjectAnalysis? {
  project_analysis_registry.get(@knowledge.Name::read(name, pkg?).show())
}

///|
pub fn registered_analyses() -> Array[ProjectAnalysisInfo] {
  let result = []
  project_analysis_registry.each((_, analysis) => result.push(analysis.info()))
  result
}

///|
pub fn apply_analysis(
  name : String,
  inputs : Array[String],
  pkg? : String,
) -> Result[Unit, String] {
  match find_analysis(name, pkg?) {
    None => Err("unknown project analysis \{name}")
    Some(analysis) => analysis.apply(inputs)
  }
}
