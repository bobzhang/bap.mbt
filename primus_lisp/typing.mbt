// The Primus Lisp type checker (upstream `Program.Typing`).
//
// Primus Lisp has a soft (gradual) type system: an expression is either a
// symbol or a bitvector of some width, `Any` is the top type. Type
// inference assigns a type variable to every expression (the expressions
// are identified by their unique identifiers), and a program is ill-typed
// if some class of expressions that must have the same type has no type.
//
// Upstream represents the typing environment as a pair of persistent maps
// (term -> type variable, type variable -> type values) and computes a
// fixed point over the call graph merging the environments of callees.
// The port uses a single union-find structure that accumulates the
// constraints of all functions and iterates the inference over the call
// graph (callees first) until the environment stabilizes. Since the
// constraints of different functions are only related via signatures (the
// ground types of the parameters and the result), the result is the same.

///|
/// A ground type value.
pub(all) enum TypeValue {
  TAny
  TSym
  TWord(Int)
} derive(Eq, Debug)

///|
pub impl Show for TypeValue with fn output(self, logger) {
  match self {
    TAny => logger.write_string("any")
    TSym => logger.write_string("sym")
    TWord(n) => logger.write_string("i\{n}")
  }
}

///|
/// A type error (upstream `type_error`). Every problem refers to the
/// identifiers of the expressions involved.
pub(all) enum TypeProblem {
  UnresolvedVariable(Int, String)
  UnresolvedFunction(Int, String, Array[Signature])
  UnresolvedSignal(Int, String, Signature?)
  UnresolvedParameter(Int, String)
  NoUnification(Int, TypeValue, Int, TypeValue)
} derive(Eq, Debug)

///|
/// A type error together with the sources, so that it can be rendered.
pub struct TypeError {
  sources : Source
  problem : TypeProblem
}

///|
pub impl Show for TypeError with fn output(self, logger) {
  let src = self.sources
  let pp_exp = (id : Int) => {
    let loc = src.loc(id)
    "\{loc}:\n\{src.underline(loc)}"
  }
  match self.problem {
    UnresolvedVariable(exp, name) =>
      logger.write_string("Unresolved variable `\{name}':\n\{pp_exp(exp)}")
    UnresolvedFunction(exp, name, []) =>
      logger.write_string(
        "Unresolved function or primitive `\{name}':\n\{pp_exp(exp)}",
      )
    UnresolvedFunction(exp, name, sigs) => {
      logger.write_string(
        "No matching signature for `\{name}':\n\{pp_exp(exp)}\nTried:\n",
      )
      for i, s in sigs {
        logger.write_string("\{i + 1}: \{s}\n")
      }
    }
    UnresolvedSignal(exp, name, None) =>
      logger.write_string(
        "Unresolved signal for method `\{name}':\n\{pp_exp(exp)}",
      )
    UnresolvedSignal(exp, name, Some(s)) =>
      logger.write_string(
        "The signal `\{name}' has signature `\{s}'. This signature doesn't match with the inferred type of the method:\n\{pp_exp(exp)}",
      )
    UnresolvedParameter(exp, name) =>
      logger.write_string(
        "The variable `\{name}' is treated as parameter, but there is no such parameter:\n\{pp_exp(exp)}",
      )
    NoUnification(x, t1, y, t2) =>
      logger.write_string(
        "Type error: expected \{t1} got \{t2}. Details follow, the expression:\n\{pp_exp(x)} has type \{t1}, but it is expected to have type \{t2} after its unification with the expression:\n\{pp_exp(y)}",
      )
  }
}

///|
/// A short one-line description of the error (without the source excerpt).
pub fn TypeError::summary(self : TypeError) -> String {
  let loc = (id : Int) => {
    let l = self.sources.loc(id)
    let file = match l.file.rev_find("/") {
      Some(i) => l.file.unsafe_substring(start=i + 1, end=l.file.length())
      None => l.file
    }
    "\{file}:\{l.range.start_pos.line}"
  }
  match self.problem {
    UnresolvedVariable(exp, name) => "\{loc(exp)}: unresolved variable \{name}"
    UnresolvedFunction(exp, name, []) =>
      "\{loc(exp)}: unresolved function \{name}"
    UnresolvedFunction(exp, name, _) =>
      "\{loc(exp)}: no matching signature for \{name}"
    UnresolvedSignal(exp, name, _) => "\{loc(exp)}: unresolved signal \{name}"
    UnresolvedParameter(exp, name) =>
      "\{loc(exp)}: unresolved parameter \{name}"
    NoUnification(x, t1, _, t2) => "\{loc(x)}: expected \{t1} got \{t2}"
  }
}

///|
priv struct Tvals {
  result : Result[TypeValue, TypeProblem]
  origin : Int
} derive(Eq)

///|
fn Tvals::meet(id : Int, x : Tvals, y : Tvals) -> Tvals {
  match (x.result, y.result) {
    (Err(_), _) => x
    (_, Err(_)) => y
    (Ok(t1), Ok(t2)) => {
      let result = match (t1, t2) {
        (TAny, _) | (_, TAny) => Ok(TAny)
        _ =>
          if t1 == t2 {
            Ok(t1)
          } else {
            Err(NoUnification(x.origin, t1, y.origin, t2))
          }
      }
      { result, origin: id, }
    }
  }
}

///|
/// The typing environment: a union-find over the expressions (positive
/// identifiers) and the type variables (negative nodes), with type values
/// attached to the class representatives.
priv struct Gamma {
  parent : Map[Int, Int]
  vals : Map[Int, Tvals]
  names : Map[String, Int]
  mut next_name : Int
  mut changes : Int
}

///|
fn Gamma::new() -> Gamma {
  { parent: {}, vals: {}, names: {}, next_name: -1, changes: 0, }
}

///|
fn Gamma::find(self : Gamma, x : Int) -> Int {
  match self.parent.get(x) {
    None => {
      self.parent[x] = x
      self.changes += 1
      x
    }
    Some(p) =>
      if p == x {
        x
      } else {
        let r = self.find(p)
        if r != p {
          self.parent[x] = r
        }
        r
      }
  }
}

///|
fn Gamma::name_node(self : Gamma, n : String) -> Int {
  match self.names.get(n) {
    Some(x) => x
    None => {
      let x = self.next_name
      self.next_name -= 1
      self.names[n] = x
      x
    }
  }
}

///|
fn Gamma::set_val(self : Gamma, r : Int, t : Tvals) -> Unit {
  match self.vals.get(r) {
    Some(old) if old == t => ()
    _ => {
      self.vals[r] = t
      self.changes += 1
    }
  }
}

///|
fn Gamma::unify(self : Gamma, x : Int, y : Int) -> Unit {
  if x == y {
    ignore(self.find(x))
    return
  }
  let rx = self.find(x)
  let ry = self.find(y)
  if rx == ry {
    return
  }
  // keep the smaller node as the representative (type variables first)
  let (u, v) = if rx < ry { (rx, ry) } else { (ry, rx) }
  let id = @cmp.minimum(x, y)
  match (self.vals.get(u), self.vals.get(v)) {
    (None, None) => ()
    (Some(_), None) => ()
    (None, Some(t)) => self.vals[u] = t
    (Some(t), Some(t2)) => self.vals[u] = Tvals::meet(id, t, t2)
  }
  self.vals.remove(v)
  self.parent[v] = u
  self.changes += 1
}

///|
fn Gamma::constr_grnd(self : Gamma, x : Int, t : TypeValue) -> Unit {
  let r = self.find(x)
  let t1 = { result: Ok(t), origin: x, }
  match self.vals.get(r) {
    None => self.set_val(r, t1)
    Some(t2) => self.set_val(r, Tvals::meet(x, t1, t2))
  }
}

///|
fn Gamma::constr(self : Gamma, x : Int, t : Typ) -> Unit {
  match t {
    Any => ignore(self.find(x))
    Name(n) => self.unify(x, self.name_node(n))
    Symbol => self.constr_grnd(x, TSym)
    Type(n) => self.constr_grnd(x, TWord(n))
  }
}

///|
fn Gamma::widen(self : Gamma, x : Int) -> Unit {
  self.constr_grnd(x, TAny)
}

///|
fn Gamma::fail(self : Gamma, x : Int, err : TypeProblem) -> Unit {
  let r = self.find(x)
  self.set_val(r, { result: Err(err), origin: x, })
}

///|
fn Gamma::type_of(self : Gamma, x : Int) -> Typ {
  match self.vals.get(self.find(x)) {
    Some({ result: Ok(TSym), .. }) => Symbol
    Some({ result: Ok(TWord(n)), .. }) => Type(n)
    _ => Any
  }
}

///|
/// The global typing information (upstream `Typing.t`).
priv struct Glob {
  globs : Map[(String, String), Int]
  prims : Map[(String, String), Signature]
  funcs : Map[(String, String), Array[Def[Func]]]
  paras : Map[(String, String), Unit]
}

///|
fn key(n : @knowledge.Name) -> (String, String) {
  (n.pkg(), n.unqualified())
}

///|
fn prenex_type(id : Int, t : Typ) -> Typ {
  match t {
    Name(n) => Name("\{n}$\{id}")
    t => t
  }
}

///|
fn prenex_signature(id : Int, s : Signature) -> Signature {
  {
    args: s.args.map(t => prenex_type(id, t)),
    rest: s.rest.map(t => prenex_type(id, t)),
    ret: prenex_type(id, s.ret),
  }
}

///|
fn signature_of_gamma(g : Gamma, def : Def[Func]) -> Signature {
  {
    rest: None,
    ret: g.type_of(def.code.body.id),
    args: def.code.args.map(a => g.type_of(a.id)),
  }
}

///|
fn Glob::signatures(
  self : Glob,
  id : Int,
  g : Gamma,
  name : @knowledge.Name,
) -> Array[Signature] {
  match self.prims.get(key(name)) {
    Some(s) => [prenex_signature(id, s)]
    None =>
      match self.funcs.get(key(name)) {
        None => []
        Some(fs) => fs.map(d => signature_of_gamma(g, d))
      }
  }
}

///|
/// Checks the arity, returns `true` if the signature is applicable.
fn applicable_signature(
  s : Signature,
  nargs : Int,
  allow_partial~ : Bool,
) -> Bool {
  if nargs < s.args.length() {
    allow_partial
  } else if nargs > s.args.length() {
    s.rest is Some(_)
  } else {
    true
  }
}

///|
fn apply_signature(
  g : Gamma,
  appid : Int,
  ts : Array[Int],
  s : Signature,
) -> Unit {
  let n = @cmp.minimum(ts.length(), s.args.length())
  for i in 0..<n {
    g.constr(ts[i], s.args[i])
  }
  match s.ret {
    Any => g.widen(appid)
    ret => g.constr(appid, ret)
  }
  if ts.length() > s.args.length() {
    guard s.rest is Some(typ) else { return }
    for i in s.args.length()..<ts.length() {
      g.constr(ts[i], typ)
    }
  }
}

///|
fn Glob::apply(
  self : Glob,
  g : Gamma,
  id : Int,
  name : @knowledge.Name,
  args : Array[Ast],
) -> Unit {
  let sigs = self.signatures(id, g, name)
  let ids = args.map(a => a.id)
  for s in sigs {
    if applicable_signature(s, ids.length(), allow_partial=false) {
      apply_signature(g, id, ids, s)
      return
    }
  }
  g.fail(id, UnresolvedFunction(id, name.show(), sigs))
}

///|
fn Glob::constr_glob(
  self : Glob,
  vars : @sorted_map.SortedMap[(String, String), Int],
  v : LVar,
  g : Gamma,
) -> Unit {
  let name = key(v.name)
  if vars.contains(name) {
    return
  }
  match self.globs.get(name) {
    Some(n) => g.constr(v.id, Type(n))
    None =>
      if !self.paras.contains(name) {
        g.fail(v.id, UnresolvedVariable(v.id, v.name.show()))
      }
  }
}

///|
fn is_special(name : @knowledge.Name) -> Bool {
  let s = name.unqualified()
  s.length() > 1 && s.has_prefix("*") && s.has_suffix("*")
}

///|
fn Glob::constr_special(self : Glob, v : LVar, g : Gamma) -> Unit {
  if is_special(v.name) && !self.paras.contains(key(v.name)) {
    g.fail(v.id, UnresolvedParameter(v.id, v.name.show()))
  }
}

///|
fn varclass(
  vars : @sorted_map.SortedMap[(String, String), Int],
  v : LVar,
) -> Int {
  match vars.get(key(v.name)) {
    Some(id) => id
    None => v.id
  }
}

///|
fn Glob::infer(
  self : Glob,
  g : Gamma,
  vs : @sorted_map.SortedMap[(String, String), Int],
  e : Ast,
) -> Unit {
  let id = e.id
  match e.data {
    Sym(_) => g.constr(id, Symbol)
    Int(x) => g.constr(id, x.typ)
    Var(v) => {
      g.constr(v.id, v.typ)
      self.constr_glob(vs, v, g)
      g.unify(id, v.id)
      g.unify(v.id, varclass(vs, v))
    }
    Ite(x, y, z) => {
      self.infer(g, vs, z)
      self.infer(g, vs, y)
      self.infer(g, vs, x)
    }
    Let(v, x, y) => {
      g.constr(v.id, v.typ)
      self.infer(g, vs, x)
      self.infer(g, vs.add(key(v.name), v.id), y)
      g.unify(x.id, v.id)
      g.unify(y.id, id)
      self.constr_special(v, g)
    }
    App(Dynamic(name), xs) => {
      self.reduce(g, vs, xs)
      self.apply(g, id, name, xs)
    }
    App(Static(_), _) => ()
    Seq([]) => ()
    Seq(xs) => {
      self.reduce(g, vs, xs)
      g.unify(xs[xs.length() - 1].id, id)
    }
    Set(v, x) => {
      self.infer(g, vs, x)
      self.constr_glob(vs, v, g)
      g.constr(v.id, v.typ)
      g.unify(id, v.id)
      g.unify(id, x.id)
      g.unify(id, varclass(vs, v))
    }
    Rep(c, x) => {
      self.infer(g, vs, x)
      self.infer(g, vs, c)
      g.unify(c.id, id)
    }
    Msg(_, xs) => {
      self.reduce(g, vs, xs)
      g.constr(id, Type(1))
    }
    Err(_) => ()
  }
}

///|
fn Glob::reduce(
  self : Glob,
  g : Gamma,
  vs : @sorted_map.SortedMap[(String, String), Int],
  xs : Array[Ast],
) -> Unit {
  for i = xs.length() - 1; i >= 0; i = i - 1 {
    self.infer(g, vs, xs[i])
  }
}

///|
fn bind_args(
  args : Array[LVar],
) -> @sorted_map.SortedMap[(String, String), Int] {
  let mut vs = @sorted_map.SortedMap::new()
  for a in args {
    vs = vs.add(key(a.name), a.id)
  }
  vs
}

///|
fn Glob::transfer(self : Glob, g : Gamma, f : Def[Func]) -> Unit {
  let args = f.code.args
  let vars = bind_args(args)
  for v in args {
    g.constr(v.id, v.typ)
  }
  self.infer(g, vars, f.code.body)
}

///|
/// Filters the definitions that are not applicable in the program context.
fn applicable_library(p : Program) -> @sorted_map.SortedMap[String, Package] {
  let ctxt = p.context
  let filter = (defs : Defs[Func]) => {
    filter_defs(defs, d => d.attrs.context.le(ctxt))
  }
  p.library.map((_, pkg) => {
    ..pkg,
    defs: filter(pkg.defs),
    mets: filter(pkg.mets),
    pars: filter_defs(pkg.pars, d => d.attrs.context.le(ctxt)),
  })
}

///|
fn calls(e : Ast, out : Array[@knowledge.Name]) -> Unit {
  match e.data {
    App(Dynamic(v), xs) => {
      out.push(v)
      for x in xs {
        calls(x, out)
      }
    }
    Var(_) | Int(_) | Sym(_) | Err(_) => ()
    Ite(x, y, z) => {
      calls(x, out)
      calls(y, out)
      calls(z, out)
    }
    Seq(xs) | App(_, xs) | Msg(_, xs) =>
      for x in xs {
        calls(x, out)
      }
    Let(_, x, y) | Rep(x, y) => {
      calls(x, out)
      calls(y, out)
    }
    Set(_, x) => calls(x, out)
  }
}

///|
/// A typed program: the program (with places and primitives) and its typing
/// environment (upstream `Type.env`).
pub struct TypedProgram {
  program : Program
  priv gamma : Gamma
}

///|
/// The inferred type of the expression with the given identifier.
pub fn TypedProgram::type_of(self : TypedProgram, id : Int) -> Typ {
  self.gamma.type_of(id)
}

///|
/// The inferred signature of a function definition.
pub fn TypedProgram::signature(
  self : TypedProgram,
  def : Def[Func],
) -> Signature {
  signature_of_gamma(self.gamma, def)
}

///|
/// Type errors of the typed program (upstream `Type.errors`).
pub fn TypedProgram::errors(self : TypedProgram) -> Array[TypeError] {
  let g = self.gamma
  let seen : Map[Int, Unit] = Map([])
  let errs = []
  let nodes = g.parent.keys().collect()
  nodes.sort()
  for x in nodes {
    let r = g.find(x)
    if !seen.contains(r) {
      seen[r] = ()
      if g.vals.get(r) is Some({ result: Err(problem), .. }) {
        errs.push({ sources: self.program.sources, problem, })
      }
    }
  }
  errs
}

///|
/// Infers types of the program (upstream `Type.infer`).
///
/// `externals` are the signatures of external functions (e.g., the
/// subroutines of the binary program), they are available as
/// `external:<name>`.
pub fn Program::infer_types(
  self : Program,
  externals? : Array[(String, Signature)] = [],
  max_passes? : Int = 16,
) -> TypedProgram {
  let p = self
  let library = applicable_library(p)
  let prims : Map[(String, String), Signature] = Map([])
  p.fold(semantics, init=(), (pkg, def, _) => {
    prims[key(@knowledge.Name::create(def.name, pkg~))] = def.code.types
  })
  p.fold(primitive, init=(), (pkg, def, _) => {
    if def.code.types is Some(t) {
      prims[key(@knowledge.Name::create(def.name, pkg~))] = t
    }
  })
  for e in externals {
    prims[key(@knowledge.Name::create(e.0, pkg="external"))] = e.1
  }
  let globs : Map[(String, String), Int] = Map([])
  p.fold(place, init=(), (pkg, def, _) => {
    if def.code.location.typ is Imm(n) {
      globs[key(@knowledge.Name::read(def.name, pkg~))] = n
    }
  })
  let paras : Map[(String, String), Unit] = Map([])
  p.fold(para, init=(), (pkg, def, _) => {
    paras[key(@knowledge.Name::read(def.name, pkg~))] = ()
  })
  let funcs : Map[(String, String), Array[Def[Func]]] = Map([])
  let unique : Map[Int, Def[Func]] = Map([])
  let order : Array[Int] = []
  for kv in library.iter() {
    for dk in kv.1.defs.iter() {
      for def in dk.1 {
        let k = key(@knowledge.Name::read(def.name, pkg=kv.0))
        match funcs.get(k) {
          Some(xs) => xs.insert(0, def)
          None => funcs[k] = [def]
        }
        if !unique.contains(def.id) {
          unique[def.id] = def
          order.push(def.id)
        }
      }
    }
  }
  let glob = { globs, prims, funcs, paras, }
  // the call graph, callees are visited before callers
  let visited : Map[Int, Unit] = Map([])
  let post : Array[Def[Func]] = []
  fn visit(def : Def[Func]) -> Unit {
    if visited.contains(def.id) {
      return
    }
    visited[def.id] = ()
    let cs = []
    calls(def.code.body, cs)
    for c in cs {
      if funcs.get(key(c)) is Some(callees) {
        for callee in callees {
          visit(callee)
        }
      }
    }
    post.push(def)
  }

  for id in order {
    visit(unique[id])
  }
  let g = Gamma::new()
  for _ in 0..<max_passes {
    let before = g.changes
    for def in post {
      glob.transfer(g, def)
    }
    if g.changes == before {
      break
    }
  }
  // methods
  for kv in library.iter() {
    let pkg = kv.0
    for mk in kv.1.mets.iter() {
      for met in mk.1 {
        let name = met.name
        let fullname = @knowledge.Name::read(name, pkg~)
        let signal = match self.library.get(fullname.pkg()) {
          None => None
          Some(pkg) =>
            match pkg.sigs.get(fullname.unqualified()) {
              Some([x]) => Some(x)
              _ => None
            }
        }
        match signal {
          None => g.fail(met.id, UnresolvedSignal(met.id, name, None))
          Some(s) => {
            let args = met.code.args
            let pars = s.code.types
            if !applicable_signature(pars, args.length(), allow_partial=true) {
              g.fail(met.id, UnresolvedSignal(met.id, name, Some(pars)))
            } else {
              apply_signature(g, met.id, args.map(a => a.id), pars)
              glob.transfer(g, met)
            }
          }
        }
      }
    }
  }
  { program: self, gamma: g, }
}

///|
/// Type checks the program and returns the type errors (upstream
/// `Type.check`).
pub fn Program::type_errors(
  self : Program,
  externals? : Array[(String, Signature)] = [],
) -> Array[TypeError] {
  self.infer_types(externals~).errors()
}
