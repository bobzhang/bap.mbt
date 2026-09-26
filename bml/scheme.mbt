// The BML surface syntax and the term marker (upstream `Scheme` and
// `marker` of the `map_terms` plugin).
//
//     bml    ::= (<exps> <exps>)
//     exps   ::= <exp>  | (<exp>1 .. <exp>N)
//     exp    ::= (<id>) | (<id> <arg>)
//     arg    ::= <id> | ?quoted string?
//     id     ::= ?alphanumeric sequence?

///|
/// The BML grammar, as printed by upstream.
pub let grammar : String =
  #|    bml    ::= (<exps> <exps>)
  #|    exps   ::= <exp>  | (<exp>1 .. <exp>N)
  #|    exp    ::= (<id>) | (<id> <arg>)
  #|    arg    ::= <id> | ?quoted string?
  #|    id     ::= ?alphanumeric sequence?

///|
/// A pattern: if all predicates are satisfied by a term, then all mappers
/// are applied to it in order.
pub struct Pattern {
  preds : Array[Predicate]
  mappers : Array[Mapper]
}

///|
/// Creates a pattern.
pub fn Pattern::new(
  preds : Array[Predicate],
  mappers : Array[Mapper],
) -> Pattern {
  { preds, mappers, }
}

///|
fn[T] lookup(
  arity : Int,
  first : (String) -> T?,
  second : (String) -> Bool,
  tag : String,
) -> Result[T, String] {
  match first(tag) {
    Some(exp) => Ok(exp)
    None =>
      match second(tag) {
        false => Err("Unbound name: \{ocaml_quote(tag)}")
        true => Err("Term \{tag} has arity \{arity}")
      }
  }
}

///|
fn[T] parse_exp(ops : Ops[T], sexp : Sexp) -> Result[T, String] {
  match sexp {
    List([Atom(tag)]) =>
      lookup(
        0,
        name => ops.nullary.find(name),
        name => ops.unary.find(name) is Some(_),
        tag,
      )
    List([Atom(tag), Atom(v)]) =>
      match
        lookup(
          1,
          name => ops.unary.find(name),
          name => ops.nullary.find(name) is Some(_),
          tag,
        ) {
        Err(err) => Err(err)
        Ok(parse_arg) =>
          try parse_arg(v) catch {
            ParseError(msg) => Err(msg)
          } noraise {
            value => Ok(value)
          }
      }
    list => Err("expected <exp> got \{list.to_string()}")
  }
}

///|
fn[T] parse_exps(
  ops : Ops[T],
  sexp : Sexp,
  out : Array[Result[T, String]],
) -> Unit {
  match sexp {
    List([Atom(_), ..]) => out.push(parse_exp(ops, sexp))
    List(exps) =>
      for exp in exps {
        parse_exps(ops, exp, out)
      }
    s => out.push(Err("expected <expr> got \{s.to_string()}"))
  }
}

///|
fn[T] parse_all(ops : Ops[T], sexp : Sexp) -> Result[Array[T], String] {
  let results = []
  parse_exps(ops, sexp, results)
  let values = []
  for result in results {
    match result {
      Ok(value) => values.push(value)
      Err(err) => return Err(err)
    }
  }
  Ok(values)
}

///|
/// Parses a list of predicate expressions.
pub fn parse_preds(sexp : Sexp) -> Result[Array[Predicate], String] {
  parse_all(predicates, sexp)
}

///|
/// Parses a list of mapper expressions.
pub fn parse_mappers(sexp : Sexp) -> Result[Array[Mapper], String] {
  parse_all(mappers, sexp)
}

///|
/// Parses a pattern `(<preds> <mappers>)` (upstream `Scheme.parse`).
pub fn parse(sexp : Sexp) -> Result[Pattern, String] {
  match sexp {
    List([preds, marks]) =>
      match (parse_preds(preds), parse_mappers(marks)) {
        (Ok(preds), Ok(mappers)) => Ok({ preds, mappers, })
        (Err(e), _) | (_, Err(e)) => Err(e)
      }
    _ => Err("expect \"(\"<preds> <marks>\")\"")
  }
}

///|
fn syntax_error(err : SexpSyntaxError) -> String {
  match err {
    SexpSyntaxError(line~, column~, msg) =>
      "Syntax error: line \{line}, column \{column} - \{msg}"
  }
}

///|
/// Parses a pattern from its textual representation (upstream
/// `Scheme.parse_string`).
///
/// # Example
///
/// ```mbt check
/// test {
///   guard @bml.parse_string("((is-visited) (foreground blue))") is Ok(p) else {
///     fail("expected a pattern")
///   }
///   assert_eq(p.preds.length(), 1)
///   assert_eq(p.mappers.length(), 1)
/// }
/// ```
pub fn parse_string(text : String) -> Result[Pattern, String] {
  try sexp_of_string(text) catch {
    err => Err(syntax_error(err))
  } noraise {
    sexp => parse(sexp)
  }
}

///|
/// Parses a sequence of patterns (the contents of a patterns file).
pub fn parse_patterns(text : String) -> Result[Array[Pattern], String] {
  let sexps = sexps_of_string(text) catch {
    err => return Err(syntax_error(err))
  }
  let result = []
  for sexp in sexps {
    match parse(sexp) {
      Ok(pattern) => result.push(pattern)
      Err(err) => return Err(err)
    }
  }
  Ok(result)
}

///|
/// Reads and parses a patterns file (upstream `Scheme.parse_file`). File
/// IO is only available on the native target.
pub fn parse_file(path : String) -> Result[Array[Pattern], String] {
  match @native_io.read_file(path) {
    Err(err) => Err(err)
    Ok(bytes) => {
      let text = @utf8.decode_lossy(bytes)
      parse_patterns(text)
    }
  }
}

///|
/// The term mapper built from [patterns] (upstream `marker`): every
/// pattern is tried on the term in order, then the subterms are mapped.
pub fn marker_of_patterns(patterns : Array[Pattern]) -> Mapper {
  fn go(term : IrTerm) -> IrTerm {
    let mut term = term
    for pattern in patterns {
      if pattern.preds.all(p => p(term)) {
        for m in pattern.mappers {
          term = m(term)
        }
      }
    }
    map_children(term, go)
  }

  go
}

///|
/// Applies [patterns] to all subroutines of [program] and their subterms
/// (upstream `marker#run`); the program term itself is not matched.
pub fn map_program(
  patterns : Array[Pattern],
  program : @types.Term[@types.Program],
) -> @types.Term[@types.Program] {
  match map_children(ProgramTerm(program), marker_of_patterns(patterns)) {
    ProgramTerm(program) => program
    _ => program
  }
}

///|
/// Parses the patterns given as strings (each one as for `parse_string`)
/// and the optional patterns file, and applies them to [program] (upstream
/// `Map_terms_main.main`).
pub fn map_terms(
  patterns : Array[String],
  file? : String,
  program : @types.Term[@types.Program],
) -> Result[@types.Term[@types.Program], String] {
  let parsed = []
  for text in patterns {
    match parse_string(text) {
      Ok(pattern) => parsed.push(pattern)
      Err(err) => return Err(err)
    }
  }
  match file {
    None => ()
    Some(file) =>
      match parse_file(file) {
        Ok(ps) => parsed.append(ps)
        Err(err) => return Err(err)
      }
  }
  Ok(map_program(parsed, program))
}
