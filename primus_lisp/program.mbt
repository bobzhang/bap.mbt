// Lisp programs: packages and their definitions (upstream
// `Bap_primus_lisp_program`).

///|
/// Definitions of one kind, indexed by name. The most recent definition
/// is the first in the list.
pub type Defs[T] = @sorted_map.SortedMap[String, Array[Def[T]]]

///|
/// A package: definitions of all kinds.
pub struct Package {
  semas : Defs[Sema]
  codes : Defs[Prim]
  macros : Defs[Macro]
  substs : Defs[Subst]
  consts : Defs[Const]
  places : Defs[Place]
  defs : Defs[Func]
  mets : Defs[Func]
  pars : Defs[Para]
  sigs : Defs[Signal]
}

///|
fn[T] nodefs() -> Defs[T] {
  @sorted_map.SortedMap::new()
}

///|
let empty_package : Package = {
  semas: nodefs(),
  codes: nodefs(),
  macros: nodefs(),
  substs: nodefs(),
  consts: nodefs(),
  places: nodefs(),
  defs: nodefs(),
  mets: nodefs(),
  pars: nodefs(),
  sigs: nodefs(),
}

///|
/// A kind of definitions (upstream `Program.Items`), i.e., an accessor for
/// the corresponding field of a package.
pub struct Item[T] {
  name : String
  get : (Package) -> Defs[T]
  set : (Package, Defs[T]) -> Package
}

///|
/// Functions (`defun`).
pub let func : Item[Func] = {
  name: "func",
  get: p => p.defs,
  set: (p, x) => { ..p, defs: x, },
}

///|
/// Methods (`defmethod`).
pub let meth : Item[Func] = {
  name: "meth",
  get: p => p.mets,
  set: (p, x) => { ..p, mets: x, },
}

///|
/// Macros (`defmacro`).
pub let macro_item : Item[Macro] = {
  name: "macro",
  get: p => p.macros,
  set: (p, x) => { ..p, macros: x, },
}

///|
/// Substitutions (`defsubst`).
pub let subst : Item[Subst] = {
  name: "subst",
  get: p => p.substs,
  set: (p, x) => { ..p, substs: x, },
}

///|
/// Constants (`defconstant`).
pub let const_item : Item[Const] = {
  name: "const",
  get: p => p.consts,
  set: (p, x) => { ..p, consts: x, },
}

///|
/// Places (registers and global variables).
pub let place : Item[Place] = {
  name: "place",
  get: p => p.places,
  set: (p, x) => { ..p, places: x, },
}

///|
/// Parameters (`defparameter`).
pub let para : Item[Para] = {
  name: "para",
  get: p => p.pars,
  set: (p, x) => { ..p, pars: x, },
}

///|
/// Primitives (host functions).
pub let primitive : Item[Prim] = {
  name: "primitive",
  get: p => p.codes,
  set: (p, x) => { ..p, codes: x, },
}

///|
/// Semantic primitives.
pub let semantics : Item[Sema] = {
  name: "semantics",
  get: p => p.semas,
  set: (p, x) => { ..p, semas: x, },
}

///|
/// Signals.
pub let signal : Item[Signal] = {
  name: "signal",
  get: p => p.sigs,
  set: (p, x) => { ..p, sigs: x, },
}

///|
/// A Primus Lisp program: a library of packages, the current package,
/// the context in which the program is applied, and the sources.
///
/// Programs are persistent values, all updates return new programs (the
/// source store is shared).
pub struct Program {
  context : Context
  pkg : String
  sources : Source
  exports : @sorted_map.SortedMap[String, @sorted_set.SortedSet[String]]
  library : @sorted_map.SortedMap[String, Package]
  pkgdocs : @sorted_map.SortedMap[String, String]
}

///|
/// The package in which definitions are placed by default.
pub let default_package : String = "user"

///|
pub fn Program::empty() -> Program {
  {
    context: Context::empty(),
    pkg: default_package,
    sources: Source::new(),
    exports: @sorted_map.SortedMap::new(),
    library: @sorted_map.SortedMap::new(),
    pkgdocs: @sorted_map.SortedMap::new(),
  }
}

///|
pub fn Program::with_package(self : Program, pkg : String) -> Program {
  { ..self, pkg, }
}

///|
pub fn Program::reset_package(self : Program) -> Program {
  self.with_package(default_package)
}

///|
pub fn Program::with_context(self : Program, context : Context) -> Program {
  { ..self, context, }
}

///|
pub fn Program::with_sources(self : Program, sources : Source) -> Program {
  { ..self, sources, }
}

///|
pub fn Program::is_empty(self : Program) -> Bool {
  self.library.is_empty()
}

///|
/// Two programs are equal if they are built from the same sources.
pub fn Program::equal(self : Program, other : Program) -> Bool {
  physical_equal(self.sources, other.sources)
}

///|
/// Packages and their documentation.
pub fn Program::packages(self : Program) -> Array[(String, String)] {
  self.library
  .keys_as_iter()
  .map(pkg => {
    (
      pkg,
      match self.pkgdocs.get(pkg) {
        Some(d) => d
        None => ""
      },
    )
  })
  .collect()
}

///|
pub fn Program::update_package_documentation(
  self : Program,
  pkg : String,
  docs : String,
) -> Program {
  { ..self, pkgdocs: self.pkgdocs.add(pkg, docs), }
}

///|
fn[T] filter_defs(defs : Defs[T], f : (Def[T]) -> Bool) -> Defs[T] {
  let mut out = nodefs()
  for kv in defs.iter() {
    let xs = kv.1.filter(f)
    if xs.length() > 0 {
      out = out.add(kv.0, xs)
    }
  }
  out
}

///|
fn filter_package(pkg : Package, f : (Attrs) -> Bool) -> Package {
  {
    semas: filter_defs(pkg.semas, d => f(d.attrs)),
    codes: filter_defs(pkg.codes, d => f(d.attrs)),
    macros: filter_defs(pkg.macros, d => f(d.attrs)),
    substs: filter_defs(pkg.substs, d => f(d.attrs)),
    consts: filter_defs(pkg.consts, d => f(d.attrs)),
    places: filter_defs(pkg.places, d => f(d.attrs)),
    defs: filter_defs(pkg.defs, d => f(d.attrs)),
    mets: filter_defs(pkg.mets, d => f(d.attrs)),
    pars: filter_defs(pkg.pars, d => f(d.attrs)),
    sigs: filter_defs(pkg.sigs, d => f(d.attrs)),
  }
}

///|
/// The package with the given name (all definitions, or only public ones).
pub fn Program::get_package(
  self : Program,
  pkg : String,
  public? : Bool = false,
) -> Package {
  match self.library.get(pkg) {
    None => empty_package
    Some(pkg) =>
      if public {
        filter_package(pkg, a => a.is_public())
      } else {
        pkg
      }
  }
}

///|
fn Program::targets(self : Program, pkg : String) -> Array[String] {
  match self.exports.get(pkg) {
    None => []
    Some(s) => s.to_array()
  }
}

///|
/// The set of packages in which the definitions of `from` are visible
/// (including `from`).
fn Program::transitive_closure(
  self : Program,
  from : String,
) -> @sorted_set.SortedSet[String] {
  let mut seen = @sorted_set.SortedSet::new()
  let todo = [from]
  while todo.pop() is Some(p) {
    if !seen.contains(p) {
      seen = seen.add(p)
      for t in self.targets(p) {
        todo.push(t)
      }
    }
  }
  seen
}

///|
/// Merges two lists of definitions removing duplicates (the same name and
/// identifier). Mirrors upstream (`++`), including the order.
fn[T] merge_defs(xs : Defs[T], ys : Defs[T]) -> Defs[T] {
  let seen : Map[String, Array[Int]] = Map([])
  let out : Map[String, Array[Def[T]]] = Map([])
  let add = (defs : Defs[T]) => {
    for kv in defs.iter() {
      for d in kv.1 {
        let ids = match seen.get(d.name) {
          Some(ids) => ids
          None => {
            let ids = []
            seen[d.name] = ids
            ids
          }
        }
        if !ids.contains(d.id) {
          ids.push(d.id)
          match out.get(kv.0) {
            Some(arr) => arr.insert(0, d)
            None => out[kv.0] = [d]
          }
        }
      }
    }
  }
  add(xs)
  add(ys)
  let mut r = nodefs()
  for k, v in out {
    r = r.add(k, v)
  }
  r
}

///|
fn merge_packages(p1 : Package, p2 : Package) -> Package {
  {
    semas: merge_defs(p1.semas, p2.semas),
    codes: merge_defs(p1.codes, p2.codes),
    macros: merge_defs(p1.macros, p2.macros),
    substs: merge_defs(p1.substs, p2.substs),
    consts: merge_defs(p1.consts, p2.consts),
    places: merge_defs(p1.places, p2.places),
    defs: merge_defs(p1.defs, p2.defs),
    mets: merge_defs(p1.mets, p2.mets),
    pars: merge_defs(p1.pars, p2.pars),
    sigs: merge_defs(p1.sigs, p2.sigs),
  }
}

///|
/// Makes the public definitions of the package `from` visible in the
/// package `target` (the current package by default).
pub fn Program::use_package(
  self : Program,
  target? : String,
  from : String,
) -> Program {
  let target = match target {
    Some(t) => t
    None => self.pkg
  }
  let exports = match self.exports.get(from) {
    None => @sorted_set.SortedSet::singleton(target)
    Some(s) => s.add(target)
  }
  let prog = { ..self, exports: self.exports.add(from, exports), }
  let public = prog.get_package(from, public=true)
  let mut library = prog.library
  for t in prog.transitive_closure(from) {
    library = library.add(
      t,
      match library.get(t) {
        None => public
        Some(pkg) => merge_packages(pkg, public)
      },
    )
  }
  { ..prog, library, }
}

///|
fn Program::reexport(self : Program) -> Program {
  let mut prog = self
  for kv in self.exports.iter() {
    for target in kv.1 {
      prog = prog.use_package(target~, kv.0)
    }
  }
  prog
}

///|
/// Merges two programs (upstream `Program.merge`).
pub fn Program::merge(self : Program, other : Program) -> Program {
  let mut pkgdocs = self.pkgdocs
  for kv in other.pkgdocs.iter() {
    match pkgdocs.get(kv.0) {
      None => pkgdocs = pkgdocs.add(kv.0, kv.1)
      Some("") => pkgdocs = pkgdocs.add(kv.0, kv.1)
      Some(_) => ()
    }
  }
  let mut library = self.library
  for kv in other.library.iter() {
    library = library.add(
      kv.0,
      match library.get(kv.0) {
        None => kv.1
        Some(p) => merge_packages(p, kv.1)
      },
    )
  }
  let mut exports = self.exports
  for kv in other.exports.iter() {
    exports = exports.add(
      kv.0,
      match exports.get(kv.0) {
        None => kv.1
        Some(s) => s.union(kv.1)
      },
    )
  }
  {
    pkgdocs,
    sources: other.sources,
    context: self.context.merge(other.context),
    library,
    exports,
    pkg: self.pkg,
  }.reexport()
}

///|
fn[T] add_to_defs(defs : Defs[T], x : Def[T]) -> Defs[T] {
  match defs.get(x.name) {
    None => defs.add(x.name, [x])
    Some(ds) =>
      if ds.iter().any(d => d.name == x.name && d.id == x.id) {
        defs
      } else {
        defs.add(x.name, [x] + ds)
      }
  }
}

///|
/// Adds a definition to the program. The name of the definition may be
/// qualified with a package, otherwise it is added to the current package.
/// Public definitions are also added to all packages that use the package.
pub fn[T] Program::add(self : Program, item : Item[T], elt : Def[T]) -> Program {
  let name = @knowledge.Name::read(elt.name, pkg=self.pkg)
  let parent = name.pkg()
  let elt = elt.rename(name.unqualified())
  let is_public = elt.attrs.is_public()
  let mut library = self.library
  for pkg in self.transitive_closure(parent) {
    if is_public || pkg == parent {
      let p = match library.get(pkg) {
        None => empty_package
        Some(p) => p
      }
      library = library.add(pkg, (item.set)(p, add_to_defs((item.get)(p), elt)))
    }
  }
  { ..self, library, }
}

///|
/// Definitions of the given kind in the current package, all of them or
/// only those with the given name.
pub fn[T] Program::get(
  self : Program,
  item : Item[T],
  name? : String,
) -> Array[Def[T]] {
  match self.library.get(self.pkg) {
    None => []
    Some(pkg) => {
      let defs = (item.get)(pkg)
      match name {
        Some(name) =>
          match defs.get(name) {
            Some(xs) => xs
            None => []
          }
        None => {
          let out = []
          for kv in defs.iter() {
            out.append(kv.1)
          }
          out
        }
      }
    }
  }
}

///|
/// Folds over all definitions of the given kind in all packages.
pub fn[T, A] Program::fold(
  self : Program,
  item : Item[T],
  init~ : A,
  f : (String, Def[T], A) -> A,
) -> A {
  let mut acc = init
  for kv in self.library.iter() {
    for dk in (item.get)(kv.1).iter() {
      for d in dk.1 {
        acc = f(kv.0, d, acc)
      }
    }
  }
  acc
}

///|
/// Runs `f` with the program switched to `package`.
pub fn[R] Program::in_package(
  self : Program,
  pkg : String,
  f : (Program) -> R raise?,
) -> R raise? {
  f({ ..self, pkg, })
}

///|
/// `true` if the definition is applicable in the context of the program.
pub fn[T] Program::is_applicable(self : Program, def : Def[T]) -> Bool {
  def.attrs.context.le(self.context)
}

// ---------------------------------------------------------------------------
// Places

///|
/// Converts a theory variable to a BIL variable.
pub fn bil_var_of_theory(v : @core_theory.Var) -> @types.Var? {
  let sort = v.sort()
  match sort.bitv_size() {
    Some(n) => Some(@types.Var::create(v.name(), Imm(n)))
    None =>
      match sort.refine_bool() {
        Some(_) => Some(@types.Var::create(v.name(), Imm(1)))
        None =>
          match (sort.mem_keys(), sort.mem_values()) {
            (Some(k), Some(x)) =>
              match (k.bitv_size(), x.bitv_size()) {
                (Some(a), Some(b)) =>
                  Some(
                    @types.Var::create(
                      v.name(),
                      Mem(addr_width=a, value_width=b),
                    ),
                  )
                _ => None
              }
            _ => None
          }
      }
  }
}

///|
fn target_registers(
  target : @core_theory.Target,
) -> Array[(@knowledge.Name, @types.Var)] {
  let regs : Array[(@knowledge.Name, @types.Var)] = []
  for t in [target].iter().concat(target.parents().iter()) {
    let pkg = t.name().unqualified()
    for v in t.vars() {
      if bil_var_of_theory(v) is Some(bv) {
        let name = @knowledge.Name::create(v.name(), pkg~)
        if !regs.iter().any(r => r.0 == name) {
          regs.push((name, bv))
        }
      }
    }
  }
  regs
}

///|
/// The BIL variable of a Lisp variable, a variable without a type
/// annotation has the width of the machine word.
pub fn reify_var(v : LVar, width~ : Int) -> @types.Var {
  let n = match v.typ {
    Type(t) => t
    Symbol => symbol_size
    _ => width
  }
  @types.Var::create(v.name.show(), Imm(n))
}

///|
/// Adds places to the program (upstream `Program.with_places`): the
/// registers of the target (in the package named after the target and its
/// ancestors, as well as in the `target` package), the global and static
/// variables declared in the program, and the given program variables (in
/// the `program` package).
pub fn Program::with_places(
  self : Program,
  target : @core_theory.Target,
  globals? : Array[@types.Var] = [],
) -> Program {
  let mut prog = self
  let regs = target_registers(target)
  for r in regs {
    prog = prog.add(place, Def::new(r.0.show(), { location: r.1, }))
  }
  // globals and statics
  let width = target.bits()
  let vars : Array[@types.Var] = []
  let collect = (xs : Array[LVar]) => {
    for x in xs {
      let v = reify_var(x, width~)
      if !vars.contains(v) {
        vars.push(v)
      }
    }
  }
  prog.fold(func, init=(), (_, def, _) => {
    collect(def.attrs.globals)
    collect(def.attrs.statics)
  })
  for v in vars {
    prog = prog.add(place, Def::new(v.name, { location: v, }))
  }
  for v in globals {
    let name = @knowledge.Name::create(v.name, pkg="program")
    prog = prog.add(place, Def::new(name.show(), { location: v, }))
  }
  for r in regs {
    let name = @knowledge.Name::create(r.1.name, pkg="target")
    prog = prog.add(place, Def::new(name.show(), { location: r.1, }))
  }
  prog
}
