///|
/// The phantom kind of the class of Core Theory instances.
pub enum TheoryCls {}

///|
/// An instance of the Core Theory in the knowledge base (`Theory.theory`):
/// an object of the `core:theory` class whose `core:instance` property is
/// the theory structure.
pub type Theory = @knowledge.Object[TheoryCls]

///|
let theory_cls : @knowledge.Class[TheoryCls, Unit] = @knowledge.Class::create(
  name=core_name("theory"),
  sort=(),
  desc="the class of Core Theory instances",
  public=true,
)

///|
/// The class of Core Theory instances.
pub fn theory_class() -> @knowledge.Class[TheoryCls, Unit] {
  theory_cls
}

///|
/// A declared (or instantiated) theory (`'a theory` of the manager).
///
/// Sets of names and features are kept as sorted arrays of strings.
priv struct TheoryDef {
  names : Array[String]
  desc : String
  desugared : Bool
  requires : Array[String]
  provides : Array[String]
  structure : (@knowledge.State) -> Core raise
  is_empty : Bool
  id : Array[String]
}

///|
fn string_set(items : Array[String]) -> Array[String] {
  let result = []
  for item in items {
    if !result.contains(item) {
      result.push(item)
    }
  }
  result.sort()
  result
}

///|
fn string_set_union(lhs : Array[String], rhs : Array[String]) -> Array[String] {
  string_set(lhs + rhs)
}

///|
fn string_set_subset(lhs : Array[String], rhs : Array[String]) -> Bool {
  lhs.all(item => rhs.contains(item))
}

///|
let empty_theory_name : @knowledge.Name = core_name("empty")

///|
/// The empty theory (`Empty.theory`), the bottom of the theory domain.
let empty_theory : TheoryDef = {
  names: [empty_theory_name.show()],
  desc: "The empty theory.",
  desugared: false,
  requires: ["empty"],
  provides: [empty_theory_name.show()],
  structure: _ => Core::empty(),
  is_empty: true,
  id: [empty_theory_name.show()],
}

///|
/// All declared theories, in the order of declaration.
let known_theories : Map[String, (@knowledge.Name, TheoryDef)] = Map([])

///|
/// `Theory.declare ?desc ?extends ?context ?provides ?package ~name s`:
/// declares `structure` as an instance of the Core Theory.
///
/// The name (qualified with `pkg`, `user` by default) must be unique.
/// `extends` lists the (qualified names of the) theories included in the
/// structure, so that they are not instantiated twice. The theory is only
/// applicable if the context of instantiation contains all features of
/// `context`. `provides` is a set of semantic tags describing the
/// capabilities of the theory (the qualified name of the theory is always
/// provided).
///
/// The structure is a knowledge computation, so that a theory can depend
/// on other theories (e.g., `state => current(state)` or `require`) or
/// on the knowledge base. `declare` is a keyword in MoonBit, hence the
/// name.
pub fn declare_theory(
  desc~ : String = "",
  extends~ : Array[String] = [],
  context~ : Array[String] = [],
  provides~ : Array[String] = [],
  pkg? : String,
  name~ : String,
  structure : (@knowledge.State) -> Core raise,
) -> Unit raise {
  let name = @knowledge.Name::create(name, pkg?)
  match known_theories.get(name.show()) {
    Some((_, other)) => {
      let described = if other.desc == "" {
        "no description to its theory"
      } else {
        "the following description to its theory: \{other.desc}"
      }
      fail(
        "Theory.declare: Name exists. A theory with the name `\{name.show()}' is already declared by some other component. The other component provided \{described}.",
      )
    }
    None => ()
  }
  let extends = extends.map(text => @knowledge.Name::read(text).show())
  known_theories[name.show()] = (
    name,
    {
      names: string_set([name.show(), empty_theory_name.show()] + extends),
      desc,
      desugared: false,
      requires: string_set(context),
      provides: string_set(provides + [name.show()]),
      structure,
      is_empty: false,
      id: [name.show()],
    },
  )
}

///|
fn theory_order(lhs : TheoryDef, rhs : TheoryDef) -> @knowledge.PartialOrder {
  let le = string_set_subset(lhs.names, rhs.names)
  let ge = string_set_subset(rhs.names, lhs.names)
  if le && ge {
    Equal
  } else if le {
    Less
  } else if ge {
    Greater
  } else {
    Incomparable
  }
}

///|
/// Joins two theories: a theory subsumed by the other one is dropped,
/// incomparable theories are joined (`Core::join`).
fn theory_merge(lhs : TheoryDef, rhs : TheoryDef) -> TheoryDef {
  match theory_order(lhs, rhs) {
    Less => rhs
    Greater => lhs
    Incomparable =>
      {
        names: string_set_union(lhs.names, rhs.names),
        desc: "",
        is_empty: false,
        requires: string_set_union(lhs.requires, rhs.requires),
        provides: string_set_union(lhs.provides, rhs.provides),
        structure: state => {
          let p = (lhs.structure)(state)
          let q = (rhs.structure)(state)
          p.join(q)
        },
        desugared: false,
        id: string_set_union(lhs.id, rhs.id),
      }
    Equal =>
      match (lhs.desugared, rhs.desugared) {
        (false, true) => rhs
        _ => lhs
      }
  }
}

///|
let theory_domain : @knowledge.Domain[TheoryDef] = @knowledge.Domain::new(
  name=core_name("theory"),
  empty=Some(empty_theory),
  is_empty=theory => theory.is_empty,
  order=theory_order,
  join=(lhs, rhs) => Ok(theory_merge(lhs, rhs)),
  inspect=theory => {
    let names = "(" + theory.names.join(" ") + ")"
    if theory.desc == "" {
      names
    } else {
      "(\{names} \{theory.desc})"
    }
  },
)

///|
let theory_slot : @knowledge.Slot[TheoryCls, TheoryDef] = theory_cls.property(
  name=core_name("instance"),
  domain=theory_domain,
  desc="The theory structure",
)

///|
/// The current theory (`*current-theory*`), the null object if unset.
let current_theory_var : @knowledge.Var[Theory] = @knowledge.Var::new(
  "*current-theory*",
  _ => @knowledge.Object::null(theory_cls),
  pkg="core",
  inspect=theory => theory.repr(),
)

///|
/// The declared theories interned as symbols (`*theories*`), cached with
/// the number of theories that were declared when the cache was built.
let theories_var : @knowledge.Var[(Int32, Array[(Theory, TheoryDef)])?] = @knowledge.Var::new(
  "*theories*",
  _ => None,
  pkg="core",
)

///|
fn theories(state : @knowledge.State) -> Array[(Theory, TheoryDef)] raise {
  match theories_var.get(state) {
    Some((count, theories)) if count == known_theories.length() => theories
    _ => {
      let result = []
      for _, entry in known_theories {
        let (name, def) = entry
        let object = state.intern_symbol(
          name.unqualified(),
          theory_cls,
          pkg=name.pkg(),
        )
        result.push((object, def))
      }
      theories_var.set(state, Some((known_theories.length(), result)))
      result
    }
  }
}

///|
fn without_subsumptions(theories : Array[TheoryDef]) -> Array[TheoryDef] {
  theories.filter(t1 => !theories.iter().any(t2 => theory_order(t1, t2) is Less))
}

///|
/// Selects the theories applicable in `context` that provide at least
/// one of the `requires` features (all theories if `requires` is `None`),
/// dropping those subsumed by other selected theories.
fn refine_theories(
  context : Array[String],
  requires : Array[String]?,
  theories : Array[TheoryDef],
) -> Array[TheoryDef] {
  without_subsumptions(
    theories.filter(theory => {
      string_set_subset(theory.requires, context) &&
      (match requires {
        None => true
        Some(required) => theory.provides.iter().any(f => required.contains(f))
      })
    }),
  )
}

///|
fn theory_for_id(state : @knowledge.State, id : Array[String]) -> Theory {
  state.intern_symbol(
    "'(" + id.join(" ") + ")",
    theory_cls,
    pkg="core-internal",
  )
}

///|
fn is_instantiated(state : @knowledge.State, id : Theory) -> Bool raise {
  !state.collect(theory_slot, id).is_empty
}

///|
/// Instantiates a theory: its structure is evaluated once and stored in
/// the knowledge base. A theory that (directly or not) instantiates
/// itself while being instantiated gets the empty structure (see the
/// note on recursive modules upstream).
fn instantiate(state : @knowledge.State, theory : TheoryDef) -> Theory raise {
  let id = theory_for_id(state, theory.id)
  if is_instantiated(state, id) {
    return id
  }
  state.provide(theory_slot, id, { ..empty_theory, is_empty: false, })
  let structure = (theory.structure)(state)
  state.provide(theory_slot, id, { ..theory, structure: _ => structure, })
  id
}

///|
/// `Theory.instance ?context ?requires ()`: the current theory, or a new
/// instance of the Core Theory.
///
/// If neither `context` nor `requires` is specified and a current theory
/// is set (see `with_current`), then it is returned. Otherwise the
/// instance is built from all declared theories applicable in `context`
/// that provide at least one feature of `requires` (all features if not
/// specified), excluding theories subsumed by other ones: if no theory
/// matches, the empty theory is returned; if one matches it is
/// instantiated; otherwise the join of all matching theories is
/// instantiated and cached in the knowledge base. Use `require` to get
/// the structure of the instance.
pub fn instance(
  state : @knowledge.State,
  context? : Array[String],
  requires? : Array[String],
) -> Theory raise {
  let theory = current_theory_var.get(state)
  if context is None && requires is None && !theory.is_null() {
    return theory
  }
  let context = match context {
    Some(context) => context
    None => []
  }
  let candidates = refine_theories(
    context,
    requires,
    theories(state).map(entry => entry.1),
  )
  match candidates {
    [] => theory_for_id(state, empty_theory.id)
    [theory] => instantiate(state, theory)
    _ => {
      let mut ids = []
      for theory in candidates {
        ids = string_set_union(ids, theory.id)
      }
      let id = theory_for_id(state, ids)
      if is_instantiated(state, id) {
        return id
      }
      let defs = []
      for theory in candidates {
        defs.push(state.collect(theory_slot, instantiate(state, theory)))
      }
      state.provide(theory_slot, id, reduce_balanced(defs, theory_merge))
      id
    }
  }
}

///|
fn[T] reduce_balanced(items : Array[T], f : (T, T) -> T) -> T {
  if items.length() == 1 {
    items[0]
  } else {
    let mid = items.length() / 2
    f(
      reduce_balanced(items[:mid].to_owned(), f),
      reduce_balanced(items[mid:].to_owned(), f),
    )
  }
}

///|
/// `Theory.require theory`: the structure of the theory instance.
///
/// The structure of a declared theory (named by its symbol) is returned
/// as is. The structure of an instance created by `instance` is desugared
/// (see `Core::desugar`) once and cached.
pub fn require(state : @knowledge.State, theory : Theory) -> Core raise {
  for entry in theories(state) {
    if entry.0 == theory {
      return (entry.1.structure)(state)
    }
  }
  let def = state.collect(theory_slot, theory)
  if def.desugared {
    (def.structure)(state)
  } else {
    let structure = Core::desugar((def.structure)(state))
    state.provide(theory_slot, theory, {
      ..def,
      desugared: true,
      structure: _ => structure,
    })
    structure
  }
}

///|
/// `Theory.with_current t f`: evaluates `f` with `theory` as the current
/// theory (a dynamic scope: the previous theory is restored afterwards,
/// also if `f` raises).
pub fn[R] with_current(
  state : @knowledge.State,
  theory : Theory,
  f : () -> R raise,
) -> R raise {
  let previous = current_theory_var.get(state)
  current_theory_var.set(state, theory)
  defer current_theory_var.set(state, previous)
  f()
}

///|
/// `Theory.current`: the structure of the current theory (`instance >=>
/// require`).
pub fn current(state : @knowledge.State) -> Core raise {
  require(state, instance(state))
}

///|
/// The documentation of a declared theory (`Documentation.Theory`).
pub struct TheoryDoc {
  name : @knowledge.Name
  desc : String
  requires : Array[String]
  provides : Array[String]
}

///|
/// `Documentation.theories ()`: all declared theories. The provided
/// features exclude the names of the theory itself and of the empty
/// theory.
pub fn declared_theories() -> Array[TheoryDoc] {
  let result = []
  for _, entry in known_theories {
    let (name, def) = entry
    result.push({
      name,
      desc: def.desc,
      requires: def.requires,
      provides: def.provides.filter(feature => {
        feature != name.show() && feature != empty_theory_name.show()
      }),
    })
  }
  result
}
