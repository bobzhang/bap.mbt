// Linking Lisp programs into the Primus machine (upstream
// `Bap_primus_lisp.Make`): externals, advisors, places, primitives,
// signals, and the type checker.

///|
fn export_externals(prog : Program) -> Program {
  let defs = prog.fold(func, init=[], (_, def, acc : Array[Def[Func]]) => {
    acc.push(def)
    acc
  })
  let mut prog = prog
  let seen : Map[(Int, String), Unit] = Map([])
  for def in defs {
    for name in def.attrs.externals {
      if !seen.contains((def.id, name)) {
        seen[(def.id, name)] = ()
        let qname = @knowledge.Name::create(name, pkg="external").show()
        prog = prog.add(func, def.rename(qname))
      }
    }
  }
  prog
}

///|
fn collect_advisors(
  prog : Program,
) -> @sorted_map.SortedMap[(String, String), Advisors] {
  let out : Map[
    (String, String),
    (Array[@knowledge.Name], Array[@knowledge.Name]),
  ] = Map([])
  let seen : Map[((String, String), Int, Bool), Unit] = Map([])
  prog.fold(func, init=(), (pkg, def, _) => {
    if prog.is_applicable(def) {
      let advisor = @knowledge.Name::create(def.name, pkg~)
      for after in [false, true] {
        for target in def.attrs.advice(if after { After } else { Before }) {
          let k = key(target)
          // the same definition is visible in several packages, it is
          // registered only once per target
          if !seen.contains((k, def.id, after)) {
            seen[(k, def.id, after)] = ()
            let (b, a) = match out.get(k) {
              Some(x) => x
              None => {
                let x = ([], [])
                out[k] = x
                x
              }
            }
            if after {
              a.push(advisor)
            } else {
              b.push(advisor)
            }
          }
        }
      }
    }
  })
  let mut r = @sorted_map.SortedMap::new()
  for k, v in out {
    v.0.sort_by(compare_names)
    v.1.sort_by(compare_names)
    r = r.add(k, { before: v.0, after: v.1, })
  }
  r
}

///|
fn find_sub(
  prog : @types.Term[@types.Program],
  name : String,
) -> @types.Term[@types.Sub]? {
  for s in prog.subs() {
    if @types.Sub::name(s) == name {
      return Some(s)
    }
  }
  None
}

///|
fn check_arg(t : Typ, arg : @types.Term[@types.Arg]) -> Bool {
  match arg.arg_lhs().typ {
    Imm(s) => t.mem(s)
    _ => false
  }
}

///|
/// Links an external function as the implementation of the subroutine
/// with the same name (upstream `link_feature`).
fn link_feature(
  m : @primus.Machine,
  prog : Program,
  def : Def[Func],
) -> Unit raise {
  let name = def.name
  let sub = find_sub(m.program(), name)
  let (inputs, ret, tid, addr) = match sub {
    None => ([], None, None, None)
    Some(sub) => {
      let inputs = []
      let mut ret = None
      for a in sub.args() {
        match a.intent() {
          Some(Out) => if ret is None { ret = Some(a) }
          _ => inputs.push(a)
        }
      }
      (inputs, ret, Some(sub.tid()), @primus.term_address(sub))
    }
  }
  let fullname = @knowledge.Name::create(name, pkg="external")
  match resolve_defun(prog, check_arg, fullname, inputs) {
    None => ()
    Some(Err(_)) if tid is None => ()
    Some(Err(r)) => m.raise_exn(UnresolvedName(fullname.show(), r.to_string()))
    Some(Ok((f, bs))) => {
      let body = f.code.body
      let code = @primus.Code::Host(m => {
        let call_args = m.call_args()
        let vals = if call_args.length() == bs.length() && !bs.is_empty() {
          call_args
        } else {
          bs.map(b => @primus.Interpreter::exp(m, b.1.arg_rhs()))
        }
        let lbs = bs.mapi((i, b) => (b.0, vals[i]))
        let init = @primus.Value::b0(m)
        eval_advices(m, false, init, fullname, vals, (m, _) => {
          notify_call(m, @primus.call_entered, name, vals, m => {
            notify_call(m, @primus.lisp_call_entered, name, vals, m => {
              eval_body(m, lbs, body, (m, r) => {
                notify_call(m, @primus.lisp_call_returned, name, vals + [r], m => {
                  notify_call(m, @primus.call_returned, name, vals + [r], m => {
                    eval_advices(m, true, r, fullname, vals, (m, r) => {
                      step(
                        m,
                        m => {
                          if ret is Some(a) {
                            @primus.Interpreter::assign(m, a.arg_rhs(), r)
                          }
                          m.set_result(Some(r))
                        },
                        (_, _) => (),
                      )
                    })
                  })
                })
              })
            })
          })
        })
      })
      @primus.Linker::link(m, addr?, tid?, name~, code)
    }
  }
}

///|
fn link_features(m : @primus.Machine) -> Unit raise {
  update_state(m, s => { ..s, program: export_externals(s.program), })
  let prog = get_state(m).program.with_package("external")
  for def in prog.get(func) {
    link_feature(m, prog, def)
  }
}

///|
/// Links the program into the machine (upstream `link_program`): merges it
/// with the program of the machine, links the external functions as
/// implementations of the subroutines of the binary program (replacing
/// them), and collects the advisors.
pub fn link_program(m : @primus.Machine, prog : Program) -> Unit raise {
  update_state(m, s => { ..s, program: s.program.merge(prog), })
  link_features(m)
  update_state(m, s => { ..s, advices: collect_advisors(s.program), })
}

///|
fn program_vars(prog : @types.Term[@types.Program]) -> Array[@types.Var] {
  let seen : Map[String, Unit] = Map([])
  let out = []
  let add = (v : @types.Var) => {
    if !seen.contains(v.name) {
      seen[v.name] = ()
      out.push(v)
    }
  }
  for sub in prog.subs() {
    for a in sub.args() {
      add(a.arg_lhs())
    }
    for blk in sub.blks() {
      for d in blk.defs() {
        add(d.lhs())
        for v in @types.Def::free_vars(d) {
          add(v)
        }
      }
      for j in blk.jmps() {
        for v in j.cond().free_vars() {
          add(v)
        }
      }
    }
  }
  out
}

///|
/// Adds the places (registers, program variables, and global variables of
/// the program) and initializes the variables that are not yet set to
/// zero (upstream `link_places`).
pub fn link_places(m : @primus.Machine) -> Unit raise {
  let globals = @primus.Env::all(m) + program_vars(m.program())
  let s = get_state(m)
  let prog = s.program.with_places(m.target(), globals~)
  let mut places = s.places
  prog.fold(place, init=(), (pkg, def, _) => {
    places = places.add(
      key(@knowledge.Name::create(def.name, pkg~)),
      def.code.location,
    )
  })
  put_state(m, { ..s, program: prog, places, })
  for kv in places.iter() {
    let v = kv.1
    if !@primus.Env::has(m, v) {
      match v.typ {
        Imm(n) => @primus.Env::set(m, v, @primus.Value::zero(m, n))
        _ => ()
      }
    }
  }
}

///|
fn signature_of_sub(sub : @types.Term[@types.Sub]) -> Signature {
  let lisp_type = (a : @types.Term[@types.Arg]) => {
    match a.arg_lhs().typ {
      Imm(n) => Typ::Type(n)
      _ => Any
    }
  }
  let args = sub.args()
  if args.is_empty() {
    { args: [], rest: Some(Any), ret: Any, }
  } else {
    let ins = []
    let mut ret : Typ = Any
    for a in args {
      match a.intent() {
        Some(Out) => ret = lisp_type(a)
        _ => ins.push(lisp_type(a))
      }
    }
    { args: ins, rest: None, ret, }
  }
}

///|
/// Type checks the program of the machine (upstream `typecheck`): links the
/// places and infers the types, the subroutines of the binary program are
/// available as externals. Every type error is posted as the `type_error`
/// observation. Returns the number of errors.
pub fn typecheck(m : @primus.Machine) -> Int raise {
  link_places(m)
  let externals = m
    .program()
    .subs()
    .map(s => (@types.Sub::name(s), signature_of_sub(s)))
  let s = get_state(m)
  let typed = s.program.infer_types(externals~)
  let errs = typed.errors()
  for e in errs {
    m.make(type_error_obs.1, e)
  }
  update_state(m, s => { ..s, typed: Some(typed), })
  errs.length()
}

///|
/// Defines a primitive (upstream `Lisp.define`), the primitive is added to
/// the program of the machine in the package `pkg` (`core` by default).
pub fn define_primitive(
  m : @primus.Machine,
  name : String,
  types? : Signature,
  docs? : String = "",
  pkg? : String = "core",
  closure : Closure,
) -> Unit {
  let qname = @knowledge.Name::read(name, pkg~).show()
  update_state(m, s => {
    ..s,
    program: s.program.add(
      primitive,
      Def::new(qname, docs~, { lambda: closure, types, }),
    ),
  })
}

///|
/// Reflects an observation into the Lisp methods (upstream `Lisp.signal`):
/// when the observation occurs, all Lisp methods named after the
/// observation are evaluated with the arguments computed by `proj`. The
/// methods are evaluated as frames of the machine (a resumable
/// subscription), so they may fork. With `once=true` the methods are run at
/// most once per machine (for observations like `system-fini` that are
/// posted after the machine finished). Returns the subscription.
pub fn[T] signal(
  m : @primus.Machine,
  obs : @primus.Observation[T],
  params? : Signature,
  docs? : String = "undocumented",
  once? : Bool = false,
  proj : (@primus.Machine, T) -> Array[@primus.Value] raise,
) -> @primus.Subscription {
  let types = match params {
    Some(p) => { ..p, ret: Any, }
    None => { args: [], rest: Some(Any), ret: Any, }
  }
  let name = @knowledge.Name::read(obs.name(), pkg="primus")
  update_state(m, s => {
    ..s,
    program: s.program.add(
      signal_item,
      Def::new(name.show(), docs~, { types, }),
    ),
  })
  // the methods are scheduled (as a resumable observer would) only if
  // the program has methods for the signal. Observations posted outside of
  // the scheduler loop (e.g., `fini`) are delivered at most once per
  // machine with `once`, otherwise the scheduled methods would keep the
  // machine running
  let key = name.show()
  m.subscribe(obs, x => {
    let s = get_state(m)
    let has_methods = !s.program
      .with_package(name.pkg())
      .get(meth, name=name.unqualified())
      .is_empty()
    if has_methods && !(once && s.fired.contains(key)) {
      if once {
        put_state(m, { ..s, fired: s.fired.add(key), })
      }
      m.schedule(m => eval_signal(m, name, proj(m, x), _ => ()))
    }
  })
}
