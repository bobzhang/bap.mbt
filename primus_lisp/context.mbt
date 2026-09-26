// Context classes (upstream `Bap_primus_lisp_context`).

///|
/// A context is a mapping from context classes (e.g., `arch`, `target`,
/// `abi`) to sets of features. Definitions are constrained by contexts
/// with the `(declare (context ...))` attribute, and a definition is
/// applicable in a program context `P` if its context `D` satisfies
/// `D <= P`.
pub struct Context {
  priv classes : @sorted_map.SortedMap[String, @sorted_set.SortedSet[String]]
} derive(Eq)

///|
pub fn Context::empty() -> Context {
  { classes: @sorted_map.SortedMap::new() }
}

///|
/// Creates a context from a list of classes and their features, e.g.,
/// `Context::create([("arch", ["x86_64"]), ("abi", ["sysv"])])`.
pub fn Context::create(descs : Array[(String, Array[String])]) -> Context {
  let mut cs = Context::empty()
  for d in descs {
    cs = cs.push(d.0, @sorted_set.SortedSet(d.1))
  }
  cs
}

///|
fn Context::push(
  self : Context,
  name : String,
  vs : @sorted_set.SortedSet[String],
) -> Context {
  let vs = match self.classes.get(name) {
    None => vs
    Some(old) => old.union(vs)
  }
  { classes: self.classes.add(name, vs) }
}

///|
/// The features of the given class.
pub fn Context::features(self : Context, name : String) -> Array[String] {
  match self.classes.get(name) {
    None => []
    Some(vs) => vs.to_array()
  }
}

///|
/// The classes of the context.
pub fn Context::classes(self : Context) -> Array[String] {
  self.classes.keys_as_iter().collect()
}

///|
pub fn Context::is_empty(self : Context) -> Bool {
  self.classes.is_empty()
}

///|
/// `x.le(y)` is true if `x` is less specific than (or as specific as) `y`,
/// i.e., if for each class `c` in `x` the features of `c` in `x` are a
/// subset of the features of `c` in `y` (upstream `Context.(<=)`).
pub fn Context::le(self : Context, other : Context) -> Bool {
  self.classes
  .iter()
  .all(kv => {
    let (name, xs) = kv
    match other.classes.get(name) {
      None => xs.is_empty()
      Some(ys) => xs.subset(ys)
    }
  })
}

///|
/// The partial order of contexts (upstream `Context.order`).
pub fn Context::order(self : Context, other : Context) -> @knowledge.PartialOrder {
  match (self.le(other), other.le(self)) {
    (true, false) => Less
    (true, true) => Equal
    (false, false) => Incomparable
    (false, true) => Greater
  }
}

///|
/// The union of two contexts.
pub fn Context::merge(self : Context, other : Context) -> Context {
  let mut cs = self
  for kv in other.classes.iter() {
    cs = cs.push(kv.0, kv.1)
  }
  cs
}

///|
pub impl Show for Context with output(self, logger) {
  logger.write_string("(context")
  for kv in self.classes.iter() {
    logger.write_string(" (\{kv.0}")
    for f in kv.1 {
      logger.write_string(" \{f}")
    }
    logger.write_char(')')
  }
  logger.write_char(')')
}

///|
fn parse_context_name(t : Tree) -> String raise AttributeError {
  match t.data {
    Atom(x) => {
      let n = x.length()
      if n < 2 {
        x
      } else if x.has_prefix("\"") {
        if x.has_suffix("\"") {
          x.unsafe_substring(start=1, end=n - 1)
        } else {
          raise AttributeError::Failure(UnterminatedQuote, [t])
        }
      } else {
        x
      }
    }
    List(_) => raise AttributeError::Failure(ExpectAtom, [t])
  }
}

///|
/// Parses the arguments of the `context` attribute:
/// `((class feature ...) ...)`.
pub fn Context::parse(trees : Array[Tree]) -> Context raise AttributeError {
  let mut cs = Context::empty()
  for t in trees {
    match t.data {
      List([x, .. xs]) => {
        let name = parse_context_name(x)
        let vs = []
        for f in xs {
          vs.push(parse_context_name(f))
        }
        cs = cs.push(name, @sorted_set.SortedSet(vs))
      }
      _ => raise AttributeError::Failure(ExpectList, [t])
    }
  }
  cs
}

///|
/// The legacy architecture name of a target (upstream `Arch.to_string` of
/// `Project.arch`), used as the feature of the `arch` class.
pub fn legacy_arch_name(t : @core_theory.Target) -> String {
  let names = [t].iter().concat(t.parents().iter()).map(t => t.name().unqualified()).collect()
  let has = (n : String) => names.contains(n)
  let name = t.name().unqualified()
  if has("x86_64") {
    "x86_64"
  } else if has("i386") || has("i86") {
    "x86"
  } else if has("aarch64") {
    if t.endianness() is BigEndian {
      "aarch64_be"
    } else {
      "aarch64"
    }
  } else if has("riscv64") {
    "riscv64"
  } else if has("riscv32") {
    "riscv32"
  } else {
    name
  }
}

///|
/// The context of a target (upstream `Context.of_project`): the classes
/// `arch`, `abi`, `fabi`, `filetype`, `endian`, `endianness`, `target`,
/// `bits`, `byte`, `data-addr-size`, `code-addr-size`, and `target-system`.
pub fn Context::of_target(
  t : @core_theory.Target,
  abi_name? : String,
) -> Context {
  let targets = []
  for p in [t].iter().concat(t.parents().iter()) {
    targets.push(p.name().unqualified())
    for n in p.nicknames() {
      targets.push(n)
    }
  }
  let extra = match abi_name {
    Some(n) => [n]
    None => []
  }
  let endian = match t.endianness() {
    BigEndian => "big"
    _ => "little"
  }
  Context::create([
    ("arch", [legacy_arch_name(t)] + extra),
    ("abi", extra + [t.abi().name().unqualified()]),
    ("fabi", [t.fabi().name().unqualified()]),
    ("filetype", [t.filetype().name().unqualified()]),
    ("endian", [endian]),
    ("endianness", [t.endianness().name().unqualified()]),
    ("target", targets),
    ("bits", [t.bits().to_string()]),
    ("byte", [t.byte().to_string()]),
    ("data-addr-size", [t.data_addr_size().to_string()]),
    ("code-addr-size", [t.code_addr_size().to_string()]),
    ("target-system", [t.system().name().unqualified()]),
  ])
}
