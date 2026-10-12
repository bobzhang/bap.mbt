// The Primus Lisp evaluator (upstream `Bap_primus_lisp.Interpreter`).
//
// Upstream evaluates Lisp in the Primus machine monad, so the evaluation
// can be forked at every bind. The port evaluates Lisp in the
// continuation-passing style over the Primus frame stack: every operation
// that has an effect on the machine (reading or writing a variable,
// creating a constant, calling a primitive, posting an observation) is
// performed in its own step, and the rest of the evaluation is scheduled
// as a frame *before* the effect is performed. A fork (or a switch)
// requested by the effect (e.g., by an observer) is applied when the step
// ends, so both the parent and the child continue the Lisp evaluation
// from that point, exactly as upstream.
//
// The local bindings of the Lisp program (function arguments and `let`
// variables, dynamically scoped as upstream) are kept in the per-fork Lisp
// state. A scope is closed by a cleanup frame, so the bindings are also
// restored when an exception unwinds through the scope.

///|
/// A continuation of the Lisp evaluation.
pub type Cont = (@primus.Machine, @primus.Value) -> Unit raise

///|
/// Performs `f` in the current step and continues with `k` in the next
/// step. The continuation is scheduled before `f` is run, so that a fork
/// requested by `f` duplicates it.
pub fn[T] step(
  m : @primus.Machine,
  f : (@primus.Machine) -> T raise,
  k : (@primus.Machine, T) -> Unit raise,
) -> Unit raise {
  let cell : Ref[T?] = Ref(None)
  m.schedule(m => {
    match cell.val {
      Some(x) => k(m, x)
      None => ()
    }
  })
  cell.val = Some(f(m))
}

///|
/// Runs `body` in a new scope: `bind` updates the local bindings, and the
/// bindings are restored when the body finishes (normally or with an
/// exception). The result of the body is passed to `k`.
fn scoped(
  m : @primus.Machine,
  bind : (LState) -> LState,
  body : (@primus.Machine, Cont) -> Unit raise,
  k : Cont,
) -> Unit {
  let saved = get_state(m).env
  m.schedule(m => {
    let s = get_state(m)
    match s.ret {
      Some(r) => {
        put_state(m, { ..s, ret: None, })
        k(m, r)
      }
      None => ()
    }
  })
  m.push_cleanup(m => update_state(m, s => { ..s, env: saved, }))
  m.schedule(m => {
    update_state(m, bind)
    body(m, (m, r) => update_state(m, s => { ..s, ret: Some(r), }))
  })
}

///|
/// Runs `body` and passes its result or the error message to `k`
/// (upstream `Machine.catch`).
fn catching(
  m : @primus.Machine,
  body : (@primus.Machine, Cont) -> Unit raise,
  k : (@primus.Machine, Result[@primus.Value, String]) -> Unit raise,
) -> Unit {
  m.schedule(m => {
    let s = get_state(m)
    let r : Result[@primus.Value, String] = match (s.ret, s.failure) {
      (Some(v), _) => Ok(v)
      (_, Some(e)) => Err(e)
      _ => Err("no value")
    }
    put_state(m, { ..s, ret: None, failure: None, })
    k(m, r)
  })
  m.push_handler((m, e) => {
    update_state(m, s => {
      ..s,
      ret: None,
      failure: Some(@primus.exn_to_string(e)),
    })
  })
  m.schedule(m => {
    body(m, (m, r) => update_state(m, s => { ..s, ret: Some(r), }))
  })
}

///|
fn lisp_var(s : LState, v : LVar) -> @types.Var {
  match s.places.get(key(v.name)) {
    Some(x) => x
    None => reify_var(v, width=s.width)
  }
}

///|
fn lookup_parameter(prog : Program, v : LVar) -> Def[Para]? {
  match prog.with_package(v.name.pkg()).get(para, name=v.name.unqualified()) {
    [p, ..] => Some(p)
    [] => None
  }
}

///|
fn width_of_typ(s : LState, t : Typ) -> Int32 {
  match t {
    Type(n) => n
    Symbol => symbol_size
    Any | Name(_) => s.width
  }
}

///|
/// Evaluates the expression and passes its value to `k` (upstream
/// `eval_exp`).
pub fn eval(m : @primus.Machine, e : Ast, k : Cont) -> Unit raise {
  match e.data {
    Int(w) => {
      let width = width_of_typ(get_state(m), w.typ)
      step(
        m,
        m => @primus.Interpreter::constant(m, word_of_bigint(w.value, width)),
        k,
      )
    }
    Sym(s) =>
      step(m, m => @primus.Value::symbol_to_value(m, s.name.unqualified()), k)
    Var(v) => lookup(m, v, k)
    Ite(c, yes, nay) =>
      eval(m, c, (m, cv) => {
        step(
          m,
          m => @primus.Interpreter::branch(m, cv, () => true, () => false),
          (m, taken) => eval(m, if taken { yes } else { nay }, k),
        )
      })
    Let(v, x, body) =>
      eval(m, x, (m, w) => {
        let s = get_state(m)
        let name = lisp_var(s, v).name
        scoped(
          m,
          s => { ..s, env: s.env.add(name, w), },
          (m, k) => eval(m, body, k),
          k,
        )
      })
    App(Dynamic(name), args) =>
      eval_args(m, args, 0, @list.List([]), (m, vals) => {
        eval_lisp(m, name, vals, k)
      })
    App(Static(_), _) => failf(m, "static bindings are not supported")
    Seq(xs) => seq(m, xs, 0, k)
    Set(v, x) => eval(m, x, (m, w) => set_var(m, v, w, k))
    Rep(c, body) => rep(m, c, body, k)
    Msg(fmt, es) => msg(m, fmt, es, 0, StringBuilder(), k)
    Err(msg) => {
      let s = get_state(m)
      let loc = s.program.sources.loc(e.id)
      m.raise_exn(RuntimeError("\{loc}\n\{unquote(msg)}"))
    }
  }
}

///|
fn eval_args(
  m : @primus.Machine,
  args : Array[Ast],
  i : Int32,
  acc : @list.List[@primus.Value],
  k : (@primus.Machine, Array[@primus.Value]) -> Unit raise,
) -> Unit raise {
  if i >= args.length() {
    k(m, acc.rev().to_array())
  } else {
    eval(m, args[i], (m, v) => eval_args(m, args, i + 1, acc.prepend(v), k))
  }
}

///|
fn seq(m : @primus.Machine, xs : Array[Ast], i : Int32, k : Cont) -> Unit raise {
  if xs.is_empty() {
    step(m, m => @primus.Interpreter::constant(m, @types.Word::b0()), k)
  } else if i == xs.length() - 1 {
    eval(m, xs[i], k)
  } else {
    eval(m, xs[i], (m, _) => seq(m, xs, i + 1, k))
  }
}

///|
fn rep(m : @primus.Machine, c : Ast, body : Ast, k : Cont) -> Unit raise {
  eval(m, c, (m, x) => {
    step(
      m,
      m => {
        let zero = @primus.Value::zero(m, x.bitwidth())
        let stop = @primus.Interpreter::binop(m, Eq, x, zero)
        @primus.Interpreter::branch(m, x, () => None, () => Some(stop))
      },
      (m, stop) => {
        match stop {
          Some(r) => k(m, r)
          None => eval(m, body, (m, _) => rep(m, c, body, k))
        }
      },
    )
  })
}

///|
fn lookup(m : @primus.Machine, v : LVar, k : Cont) -> Unit raise {
  let s = get_state(m)
  let bvar = lisp_var(s, v)
  match s.env.get(bvar.name) {
    Some(x) => k(m, x)
    None =>
      if @primus.Env::has(m, bvar) {
        step(m, m => @primus.Interpreter::get(m, bvar), k)
      } else {
        match lookup_parameter(s.program, v) {
          None => step(m, m => @primus.Interpreter::get(m, bvar), k)
          Some(p) =>
            eval(m, p.code.default, (m, x) => {
              step(
                m,
                m => {
                  @primus.Interpreter::set(m, bvar, x)
                  x
                },
                k,
              )
            })
        }
      }
  }
}

///|
fn set_var(
  m : @primus.Machine,
  v : LVar,
  w : @primus.Value,
  k : Cont,
) -> Unit raise {
  let s = get_state(m)
  let bvar = lisp_var(s, v)
  if s.env.contains(bvar.name) {
    put_state(m, { ..s, env: s.env.add(bvar.name, w), })
    k(m, w)
  } else {
    step(
      m,
      m => {
        @primus.Interpreter::set(m, bvar, w)
        w
      },
      k,
    )
  }
}

///|
fn show_value(m : @primus.Machine, v : @primus.Value) -> String {
  match @primus.Value::symbol_of_value(m, v) {
    "" => v.to_word().to_string()
    s => "#<\{s} \{v.to_word().to_string()}>"
  }
}

///|
fn msg(
  m : @primus.Machine,
  fmt : Array[Fmt],
  es : Array[Ast],
  i : Int32,
  buf : StringBuilder,
  k : Cont,
) -> Unit raise {
  if i >= fmt.length() {
    let text = buf.to_string()
    step(
      m,
      m => {
        m.make(message_obs.1, text)
        @primus.Interpreter::constant(m, @types.Word::b0())
      },
      k,
    )
  } else {
    match fmt[i] {
      Lit(s) => {
        let b = StringBuilder()
        b.write_string(buf.to_string())
        b.write_string(s)
        msg(m, fmt, es, i + 1, b, k)
      }
      Pos(n) =>
        match es.get(n) {
          None => failf(m, "bad positional argument $\{n}")
          Some(e) =>
            catching(m, (m, k) => eval(m, e, k), (m, r) => {
              let text = match r {
                Ok(v) => show_value(m, v)
                Err(err) => "<\{err}>"
              }
              let b = StringBuilder()
              b.write_string(buf.to_string())
              b.write_string(text)
              msg(m, fmt, es, i + 1, b, k)
            })
        }
    }
  }
}

///|
fn check_value(t : Typ, v : @primus.Value) -> Bool {
  t.mem(v.bitwidth())
}

///|
fn fold_advices(
  m : @primus.Machine,
  names : Array[@knowledge.Name],
  i : Int32,
  after : Bool,
  r : @primus.Value,
  args : Array[@primus.Value],
  k : Cont,
) -> Unit raise {
  if i >= names.length() {
    k(m, r)
  } else if after {
    eval_lisp(m, names[i], args + [r], (m, r) => {
      fold_advices(m, names, i + 1, after, r, args, k)
    })
  } else {
    eval_lisp(m, names[i], args, (m, r) => {
      fold_advices(m, names, i + 1, after, r, args, k)
    })
  }
}

///|
/// Evaluates the `:before` (`after=false`) or `:after` advices of the
/// function `primary` (upstream `eval_advices`).
fn eval_advices(
  m : @primus.Machine,
  after : Bool,
  init : @primus.Value,
  primary : @knowledge.Name,
  args : Array[@primus.Value],
  k : Cont,
) -> Unit raise {
  match get_state(m).advices.get(key(primary)) {
    None => k(m, init)
    Some(a) => {
      let names = if after { a.after } else { a.before }
      fold_advices(m, names, 0, after, init, args, k)
    }
  }
}

///|
fn notify_call(
  m : @primus.Machine,
  stmt : @primus.Statement[(String, Array[@primus.Value])],
  name : String,
  args : Array[@primus.Value],
  k : (@primus.Machine) -> Unit raise,
) -> Unit raise {
  step(m, m => m.post(stmt, () => (name, args)), (m, _) => k(m))
}

///|
/// Binds the parameters and evaluates the body of a function or a method.
fn eval_body(
  m : @primus.Machine,
  bs : Array[(LVar, @primus.Value)],
  body : Ast,
  k : Cont,
) -> Unit {
  scoped(
    m,
    s => {
      let mut env = s.env
      for b in bs {
        env = env.add(lisp_var(s, b.0).name, b.1)
      }
      { ..s, env, cur: body.id, }
    },
    (m, k) => eval(m, body, k),
    k,
  )
}

///|
/// Calls a Lisp function or a primitive by name (upstream `eval_lisp`).
pub fn eval_lisp(
  m : @primus.Machine,
  fullname : @knowledge.Name,
  args : Array[@primus.Value],
  k : Cont,
) -> Unit raise {
  let s = get_state(m)
  match resolve_defun(s.program, check_value, fullname, args) {
    None => eval_primitive(m, fullname, args, k)
    Some(Err(r)) => m.raise_exn(UnresolvedName(fullname.show(), r.to_string()))
    Some(Ok((f, bs))) => {
      let name = f.name
      let is_external = f.attrs.externals.contains(name)
      let init = @primus.Value::b0(m)
      let body = (m : @primus.Machine) => {
        eval_advices(m, false, init, fullname, args, (m, _) => {
          eval_body(m, bs, f.code.body, (m, r) => {
            let after = (m : @primus.Machine) => {
              eval_advices(m, true, r, fullname, args, k)
            }
            if is_external {
              notify_call(m, @primus.call_returned, name, args + [r], after)
            } else {
              after(m)
            }
          })
        })
      }
      if is_external {
        notify_call(m, @primus.call_entered, name, args, body)
      } else {
        body(m)
      }
    }
  }
}

///|
/// Calls a primitive (upstream `eval_primitive`).
fn eval_primitive(
  m : @primus.Machine,
  name : @knowledge.Name,
  args : Array[@primus.Value],
  k : Cont,
) -> Unit raise {
  let s = get_state(m)
  match resolve_simple(s.program, primitive, name) {
    None => failf(m, "unresolved primitive \{name.show()}")
    Some(Err(_)) => failf(m, "conflicting primitive \{name.show()}")
    Some(Ok(code)) => {
      let init = @primus.Value::b0(m)
      eval_advices(m, false, init, name, args, (m, _) => {
        (code.code.lambda.run)(m, name.unqualified(), args, (m, r) => {
          step(
            m,
            m => {
              @primus.Interpreter::tick(m)
              m.post(primitive_obs.1, () => (name.show(), args + [r]))
            },
            (m, _) => eval_advices(m, true, r, name, args, k),
          )
        })
      })
    }
  }
}

///|
/// Evaluates all methods of the signal `name` (upstream `eval_signal`).
pub fn eval_signal(
  m : @primus.Machine,
  name : @knowledge.Name,
  args : Array[@primus.Value],
  k : (@primus.Machine) -> Unit raise,
) -> Unit raise {
  let s = get_state(m)
  match resolve_meth(s.program, check_value, name, args) {
    None => k(m)
    Some(Err(r)) => m.raise_exn(UnresolvedName(name.show(), r.to_string()))
    Some(Ok(mets)) => {
      fn go(m : @primus.Machine, i : Int32) -> Unit raise {
        if i >= mets.length() {
          k(m)
        } else {
          eval_body(m, mets[i].1, mets[i].0.code.body, (m, _) => go(m, i + 1))
        }
      }

      go(m, 0)
    }
  }
}

///|
/// Calls the Lisp function `name` (e.g., `"strlen"` or `"posix:strlen"`)
/// with the arguments and passes the result to `then` (upstream
/// `eval_fun`). The evaluation runs as frames of the machine, so it must be
/// started from host code that runs in a step (e.g., the `start` code of a
/// machine, or a scheduled task).
pub fn eval_fun(
  m : @primus.Machine,
  name : String,
  args : Array[@primus.Value],
  then~ : Cont = (_, _) => (),
) -> Unit raise {
  eval_lisp(m, @knowledge.Name::read(name), args, then)
}

///|
/// Evaluates the methods of the signal `name` (upstream `eval_method`).
pub fn eval_method(
  m : @primus.Machine,
  name : String,
  args : Array[@primus.Value],
  then~ : (@primus.Machine) -> Unit raise = _ => (),
) -> Unit raise {
  eval_signal(m, @knowledge.Name::read(name, pkg="primus"), args, then)
}
