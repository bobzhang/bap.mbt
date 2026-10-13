///|
/// # Generator specifications (upstream `Primus_random_main.Generator`)
///
/// A specification is an s-expression: an optional predicate followed by
/// the generator name and its parameters,
///
/// ```text
/// specification = {generator};
/// generator =
///           | "random"
///           | "static"
///           | "(" [predicate], constructor, ")";
/// predicate =
///           | "_"
///           | "(", "var", "_", ")"
///           | "(", "var", ident, {ident}, ")"
///           | "(", "mem", "_", ")"
///           | "(", "mem", section, ")"
///           | "(", "mem", expression, [expression], ")"
/// constructor =
///           | "static", {numeral}
///           | "random", {numeral};
/// expression = numeral | ident;
/// section = ? a literal that starts with ':' ?;
/// ```
///
/// The generators are checked in order and the first matching one is
/// used.
pub(all) enum MemRegion {
  /// `(mem _)`: any address.
  Default
  /// `(mem <expr>)`: a single address.
  Address(String)
  /// `(mem :<name>)`: a section, i.e., the interval between the
  /// `bap:<name>-lower` and `bap:<name>-upper` variables.
  Section(String)
  /// `(mem <expr> <expr>)`: an interval (bounds included).
  Interval(String, String)
} derive(Eq, Debug)

///|
/// What a generator specification applies to.
pub(all) enum Predicate {
  /// `_` or no predicate: anything.
  Any
  /// `(var <name>...)`: the listed variables; `(var _)` (the empty list)
  /// matches all variables.
  Vars(Array[String])
  /// `(mem ...)`: memory.
  Mem(MemRegion)
} derive(Eq, Debug)

///|
/// The generator kind.
pub(all) enum Distribution {
  /// Enumerates the given values (zero by default).
  Static
  /// A uniform pseudo-random sequence.
  Random
} derive(Eq, Debug)

///|
/// A generator specification.
pub(all) struct Spec {
  predicate : Predicate
  distribution : Distribution
  parameters : Array[String]
} derive(Eq, Debug)

///|
/// Errors in generator specifications.
pub suberror SpecError {
  SpecError(String)
} derive(Debug)

///|
pub impl Show for SpecError with fn output(self, logger) {
  match self {
    SpecError(msg) => logger.write_string(msg)
  }
}

///|
/// The default specification: `random` for everything.
pub let default_spec : Spec = {
  predicate: Any,
  distribution: Random,
  parameters: [],
}

///|
fn is_keyword(s : String) -> Bool {
  s.has_prefix(":")
}

///|
fn distribution_of_sexp(s : @primus.Sexp) -> Distribution raise SpecError {
  match s {
    Atom("static" | "Static") => Static
    Atom("random" | "Random") => Random
    other => raise SpecError("expected static or random, got \{other}")
  }
}

///|
fn atoms(xs : ArrayView[@primus.Sexp]) -> Array[String] raise SpecError {
  let out = []
  for x in xs {
    guard x is Atom(a) else {
      raise SpecError("Expected a flat list of atoms, got \{x}")
    }
    out.push(a)
  }
  out
}

///|
fn predicate_of_sexp(s : @primus.Sexp) -> Predicate raise SpecError {
  match s {
    Atom("_") => Any
    List([Atom("var"), Atom("_")]) => Vars([])
    List([Atom("var"), .. vars]) => Vars(atoms(vars))
    List([Atom("mem"), Atom("_")]) => Mem(Default)
    List([Atom("mem"), Atom(loc)]) =>
      Mem(if is_keyword(loc) { Section(loc) } else { Address(loc) })
    List([Atom("mem"), Atom(lower), Atom(upper)]) => Mem(Interval(lower, upper))
    other => raise SpecError("Expected a generator specification got \{other}")
  }
}

///|
/// Reads a specification from an s-expression.
pub fn Spec::of_sexp(s : @primus.Sexp) -> Spec raise SpecError {
  match s {
    Atom("static" | "Static" | "random" | "Random") =>
      { predicate: Any, distribution: distribution_of_sexp(s), parameters: [], }
    List([Atom("static" | "Static" | "random" | "Random") as d, .. ps]) =>
      {
        predicate: Any,
        distribution: distribution_of_sexp(d),
        parameters: atoms(ps),
      }
    List([pred, d, .. ps]) =>
      {
        predicate: predicate_of_sexp(pred),
        distribution: distribution_of_sexp(d),
        parameters: atoms(ps),
      }
    other => raise SpecError("expected a generator specification, got \{other}")
  }
}

///|
/// Parses a single specification.
///
/// ```mbt check
/// test {
///   let s = @primus_random.Spec::parse("((var RAX RDI) random -5 5)")
///   inspect(s.to_string(), content="((var RAX RDI) Random -5 5)")
/// }
/// ```
pub fn Spec::parse(text : String) -> Spec raise SpecError {
  let sexp = @primus.Sexp::parse(text) catch {
    e => raise SpecError(e.to_string())
  }
  Spec::of_sexp(sexp)
}

///|
/// Parses a sequence of specifications (the contents of an
/// initialization file).
pub fn Spec::parse_many(text : String) -> Array[Spec] raise SpecError {
  let sexps = @primus.Sexp::parse_many(text) catch {
    e => raise SpecError(e.to_string())
  }
  sexps.map(Spec::of_sexp)
}

///|
/// Loads specifications from a file (upstream `Generator.from_file`).
pub fn Spec::from_file(path : String) -> Array[Spec] raise SpecError {
  let bytes = match @native_io.read_file(path) {
    Ok(b) => b
    Err(msg) => raise SpecError("\{path}: \{msg}")
  }
  let text = @utf8.decode(bytes) catch {
    _ => raise SpecError("\{path}: invalid UTF-8")
  }
  Spec::parse_many(text)
}

///|
fn predicate_to_string(p : Predicate) -> String {
  match p {
    Any => "_"
    Vars([]) => "(var _)"
    Vars(vars) => "(var \{vars.join(" ")})"
    Mem(Default) => "(mem _)"
    Mem(Address(s) | Section(s)) => "(mem \{s})"
    Mem(Interval(lower, upper)) => "(mem \{lower} \{upper})"
  }
}

///|
/// Prints the specification (upstream `Generator.pp`).
pub fn Spec::to_string(self : Spec) -> String {
  let name = match self.distribution {
    Static => "Static"
    Random => "Random"
  }
  "(\{predicate_to_string(self.predicate)} \{name} \{self.parameters.join(" ")})"
}

///|
/// The configuration type of specifications (upstream `Generator.t`).
pub fn spec_type() -> @bap_main.Type[Spec] {
  @bap_main.Type::create(
    name="GEN",
    parse=s => Spec::parse(s),
    print=Spec::to_string,
    default_spec,
  )
}

///|
fn parse_int(s : String) -> Int32 raise SpecError {
  @string.parse_int(s, base=0) catch {
    _ => raise SpecError("expected a number, got \{s}")
  }
}

///|
fn parse_int64(s : String) -> Int64 raise SpecError {
  @string.parse_int64(s, base=0) catch {
    _ => raise SpecError("expected a number, got \{s}")
  }
}

///|
fn bitvec_of_int64(width : Int32, x : Int64) -> @bitvec.BitVec {
  let u = x.reinterpret_as_uint64()
  let u = if width < 64 { u & ((1UL << width) - 1UL) } else { u }
  @bitvec.of_uint64(width~, u) catch {
    _ => @bitvec.of_bool(false)
  }
}

///|
/// Creates the uniform generator (upstream `create_uniform`):
/// `(random)`, `(random <upper>)`, `(random <lower> <upper>)` or
/// `(random <lower> <upper> <seed>)`. The seed of the generator is the sum
/// of the global seed and the local one; as upstream, the one-parameter
/// form uses the global seed as the local one.
fn create_uniform(
  seed : Int32,
  width : Int32,
  ps : Array[String],
) -> @primus.Generator raise SpecError {
  let (min, max, local_seed) = match ps {
    [] => (None, None, 0)
    [max] => (None, Some(parse_int(max)), seed)
    [min, max] => (Some(parse_int(min)), Some(parse_int(max)), 0)
    [min, max, s] => (Some(parse_int(min)), Some(parse_int(max)), parse_int(s))
    _ => raise SpecError("Generator Uniform expects less than 3 arguments")
  }
  @primus.Generator::random_lcg(width~, min?, max?, seed + local_seed)
}

///|
/// Creates the static generator (upstream `create_const`): zero by
/// default, the given value, or the given values in a cycle.
///
/// Note: upstream builds the cyclic iterator with `next i = i`, so it
/// always produces the first value although the documentation says the
/// values are enumerated; the port enumerates them.
fn create_const(
  width : Int32,
  ps : Array[String],
) -> @primus.Generator raise SpecError {
  let xs = ps.map(parse_int64)
  let (min, max) = match xs {
    [] => (0L, 0L)
    _ =>
      (
        xs.fold(init=xs[0], (a, b) => if b < a { b } else { a }),
        xs.fold(init=xs[0], (a, b) => if b > a { b } else { a }),
      )
  }
  let n = if xs.is_empty() { 1 } else { xs.length() }
  let value = (i : Int32) => if xs.is_empty() { 0L } else { xs[i % n] }
  @primus.Generator::of_iterator(
    width~,
    to_bitvec=x => bitvec_of_int64(width, x),
    { min, max, value, next: i => (i + 1) % n, },
    0,
  )
}

///|
/// Creates the generator described by the specification for values of the
/// given width.
pub fn Spec::create(
  self : Spec,
  seed~ : Int32 = 0,
  width~ : Int32 = 8,
) -> @primus.Generator raise SpecError {
  match self.distribution {
    Random => create_uniform(seed, width, self.parameters)
    Static => create_const(width, self.parameters)
  }
}

///|
/// The generator of the first specification whose predicate satisfies
/// `matches`.
pub fn first_match(
  specs : Array[Spec],
  seed~ : Int32 = 0,
  width~ : Int32 = 8,
  matches : (Predicate) -> Bool,
) -> @primus.Generator? raise SpecError {
  for s in specs {
    if matches(s.predicate) {
      return Some(s.create(seed~, width~))
    }
  }
  None
}

///|
/// The generator for the variable (upstream `Generator.for_var`).
pub fn for_var(
  specs : Array[Spec],
  seed~ : Int32 = 0,
  width~ : Int32 = 8,
  v : @types.Var,
) -> @primus.Generator? raise SpecError {
  first_match(specs, seed~, width~, p => {
    match p {
      Vars([]) | Any => true
      Vars(names) => names.contains(v.name())
      Mem(_) => false
    }
  })
}
