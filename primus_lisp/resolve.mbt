// Name resolution (upstream `Bap_primus_lisp_resolve`).
//
// A name is resolved to a definition in five stages:
// 1. all definitions with the given name;
// 2. definitions applicable to the program context;
// 3. the most specific definitions (the upper bounds by the context order);
// 4. all definitions must belong to the same context class;
// 5. overloading by the arguments (arity and types).

///|
/// The detailed explanation of a failed resolution.
pub struct Resolution {
  constr : Context
  stage1 : Array[Loc]
  stage2 : Array[Loc]
  stage3 : Array[Loc]
  stage4 : Array[Loc]
  stage5 : Array[Loc]
}

///|
pub impl Show for Resolution with output(self, logger) {
  if self.stage5.is_empty() {
    logger.write_string("no suitable definitions were found.\n")
  } else {
    logger.write_string("several equally applicable definitions were found.\n")
  }
  let pp_stage = (s : Array[Loc]) => {
    if s.is_empty() {
      logger.write_string("No definitions\n")
    } else {
      for l in s {
        logger.write_string("\{l}\n")
      }
    }
  }
  logger.write_string("The following candidates were considered:\n")
  logger.write_string("All definitions with the given name:\n")
  pp_stage(self.stage1)
  logger.write_string("All definitions applicable to the given context:\n")
  pp_stage(self.stage2)
  logger.write_string(
    "Definitions that are most specific to the given context:\n",
  )
  pp_stage(self.stage3)
  if self.stage3 == self.stage4 {
    logger.write_string(
      "All definitions applicable to the specified arguments:\n",
    )
    pp_stage(self.stage5)
  } else {
    logger.write_string(
      "Overloading was not applied, since the above definitions belong to different context classes\n",
    )
  }
  logger.write_string(
    "Note: the definitions were considered in the following context:\n\{self.constr}",
  )
}

///|
fn[T] stage3(s2 : Array[Def[T]]) -> Array[Def[T]] {
  // fold over the list keeping the upper bounds, the list is kept in the
  // reversed order as in upstream
  let mut cs : @list.List[Def[T]] = @list.empty()
  for d in s2 {
    match cs {
      Empty => cs = @list.singleton(d)
      More(c, tail=_) =>
        match d.attrs.context.order(c.attrs.context) {
          Equal | Incomparable => cs = cs.add(d)
          Less => ()
          Greater => cs = @list.singleton(d)
        }
    }
  }
  cs.to_array()
}

///|
fn[T] stage4(s3 : Array[Def[T]]) -> Array[Def[T]] {
  match s3 {
    [] => []
    [x, .. xs] =>
      if xs.iter().all(y => x.attrs.context.order(y.attrs.context) is Equal) {
        s3
      } else {
        []
      }
  }
}

///|
fn[T] locs(prog : Program, defs : Array[Def[T]]) -> Array[Loc] {
  let out = []
  for d in defs {
    let l = prog.sources.loc(d.id)
    if !out.contains(l) {
      out.push(l)
    }
  }
  out.sort()
  out
}

///|
/// The resolution result: `None` if there are no definitions with the
/// given name, `Some(Ok(x))` on success, and `Some(Err(r))` with the
/// explanation otherwise.
fn[T, B] run(
  prog : Program,
  item : Item[T],
  name : @knowledge.Name,
  unique~ : Bool,
  overload : (Array[Def[T]]) -> Array[(Def[T], B)],
) -> Result[Array[(Def[T], B)], Resolution]? {
  let prog = prog.with_package(name.pkg())
  let uname = name.unqualified()
  let ctxt = prog.context
  let s1 = prog.get(item, name=uname).filter(d => d.name == uname)
  let s2 = s1.filter(d => d.attrs.context.le(ctxt))
  let s3 = if unique { stage3(s2) } else { s2 }
  let s4 = if unique { stage4(s3) } else { s3 }
  let s5 = overload(s4)
  let ok = if unique { s5.length() == 1 } else { true }
  if ok {
    Some(Ok(s5))
  } else if s1.is_empty() {
    None
  } else {
    Some(
      Err({
        constr: ctxt,
        stage1: locs(prog, s1),
        stage2: locs(prog, s2),
        stage3: locs(prog, s3),
        stage4: locs(prog, s4),
        stage5: locs(prog, s5.map(x => x.0)),
      }),
    )
  }
}

///|
fn[T, B] one(
  r : Result[Array[(Def[T], B)], Resolution]?,
) -> Result[(Def[T], B), Resolution]? {
  match r {
    None => None
    Some(Err(e)) => Some(Err(e))
    Some(Ok(xs)) => Some(Ok(xs[0]))
  }
}

///|
/// Resolves a macro application, returns the macro and the bindings of
/// its parameters.
pub fn resolve_macro(
  prog : Program,
  name : @knowledge.Name,
  args : Array[Tree],
) -> Result[(Def[Macro], Array[(String, Array[Tree])]), Resolution]? {
  one(
    run(prog, macro_item, name, unique=true, s3 => {
      let cands = []
      for d in s3 {
        if d.macro_bind(args) is Some((n, bs)) {
          cands.push((n, d, bs))
        }
      }
      cands.sort_by((x, y) => x.0.compare(y.0))
      match cands {
        [] => []
        [(n, _, _), ..] => cands.filter(c => c.0 == n).map(c => (c.1, c.2))
      }
    }),
  )
}

///|
fn[X] all_bindings(
  typechecks : (Typ, X) -> Bool,
  bs : Array[(LVar, X)],
) -> Bool {
  bs.iter().all(b => typechecks(b.0.typ, b.1))
}

///|
/// Resolves a function application, the arguments are checked with the
/// `typechecks` predicate. Returns the function and the bindings of its
/// parameters.
pub fn[X] resolve_defun(
  prog : Program,
  item? : Item[Func] = func,
  typechecks : (Typ, X) -> Bool,
  name : @knowledge.Name,
  args : Array[X],
) -> Result[(Def[Func], Array[(LVar, X)]), Resolution]? {
  one(
    run(prog, item, name, unique=true, s3 => {
      let out = []
      for d in s3 {
        let ps = d.code.args
        if ps.length() == args.length() {
          let bs = ps.mapi((i, p) => (p, args[i]))
          if all_bindings(typechecks, bs) {
            out.push((d, bs))
          }
        }
      }
      out
    }),
  )
}

///|
/// Resolves a method (signal handler) application. All applicable methods
/// are returned, a method may have fewer parameters than arguments.
pub fn[X] resolve_meth(
  prog : Program,
  typechecks : (Typ, X) -> Bool,
  name : @knowledge.Name,
  args : Array[X],
) -> Result[Array[(Def[Func], Array[(LVar, X)])], Resolution]? {
  run(prog, meth, name, unique=false, s3 => {
    let out = []
    for d in s3 {
      let ps = d.code.args
      if ps.length() <= args.length() {
        let bs = ps.mapi((i, p) => (p, args[i]))
        if all_bindings(typechecks, bs) {
          out.push((d, bs))
        }
      }
    }
    out
  })
}

///|
/// Resolves a definition of a kind that has no overloading (primitives,
/// semantic primitives, substitutions, constants, parameters).
pub fn[T] resolve_simple(
  prog : Program,
  item : Item[T],
  name : @knowledge.Name,
) -> Result[Def[T], Resolution]? {
  match one(run(prog, item, name, unique=true, s3 => s3.map(d => (d, ())))) {
    None => None
    Some(Err(e)) => Some(Err(e))
    Some(Ok((d, _))) => Some(Ok(d))
  }
}
