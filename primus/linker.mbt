///|
/// A name of linked code (upstream ``Primus.Linker.name``:
/// `` `tid | `addr | `symbol ``).
pub(all) enum Name {
  Tid(@types.Tid)
  Addr(@types.Word)
  Symbol(String)
} derive(Eq, Debug)

///|
/// Renders a name: symbols as is, addresses in hex, tids in the usual tid
/// syntax (`%<id>` or `@<name>`).
pub fn Name::to_string(self : Name) -> String {
  match self {
    Symbol(s) => s
    Addr(a) => a.to_hex()
    Tid(t) => t.to_string()
  }
}

///|
pub impl Show for Name with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn Name::to_sexp(self : Name) -> Sexp {
  Atom(self.to_string())
}

///|
/// Code that can be linked into a machine (upstream `Primus.Linker.code`,
/// a first-class functor producing `exec : unit Machine.t`).
///
/// - `Host(f)`: arbitrary host code, executed synchronously; this is how
///   primitives, stubs and (later) Primus Lisp functions are linked;
/// - `Subroutine(sub)` / `Block(blk)`: BIR code executed by the
///   interpreter. When reached by a jump it is executed at the top level
///   (it is pushed onto the control stack and can be forked at every step).
pub(all) enum Code {
  Host((Machine) -> Unit raise)
  Subroutine(@types.Term[@types.Sub])
  Block(@types.Term[@types.Blk])
}

///|
priv struct Refs {
  term : @types.Tid?
  name : String?
  addr : @types.Word?
}

///|
/// The linker table (upstream `Primus.Linker` state). The same code may
/// be referred to by a tid, a symbol and an address. The table is a local
/// (per-fork) state; all operations are static functions taking the
/// machine.
pub struct Linker {
  priv codes : @sorted_map.SortedMap[Int32, Code]
  priv aliases : @sorted_map.SortedMap[Int32, Refs]
  priv terms : @immut_hashmap.HashMap[@types.Tid, Int32]
  priv names : @immut_hashmap.HashMap[String, Int32]
  priv addrs : @sorted_map.SortedMap[AddrKey, Int32]
  priv last : Int32
}

///|
let linker_state : State[Linker] = State::declare_(
  uuid="38bf35bf-1091-4220-bf75-de79db9de4d2",
  name="linker",
  _ => {
    codes: @sorted_map.SortedMap::new(),
    aliases: @sorted_map.SortedMap::new(),
    terms: @immut_hashmap.HashMap::new(),
    names: @immut_hashmap.HashMap::new(),
    addrs: @sorted_map.SortedMap::new(),
    last: 0,
  },
)

///|
/// The name of the handler called when an unresolved name is executed.
pub let unresolved_handler : String = "__primus_linker_unresolved_call"

///|
fn call_sexp(call : (String, Array[Value])) -> Sexp {
  let items = [Sexp::Atom(call.0)]
  for v in call.1 {
    items.push(Atom(v.value.to_hex()))
  }
  List(items)
}

///|
/// Posted before code with the given name is executed.
pub let will_exec : Statement[Name] = Statement::provide(
  "linker-exec",
  inspect=Name::to_sexp,
  desc="Occurs before code with the given name is executed.",
)

///|
/// Occurs before code with the given name is executed (`Linker.exec`).
pub let linker_exec : Observation[Name] = will_exec.obs

///|
let will_fail : Statement[Name] = Statement::provide(
  "linker-unresolved",
  inspect=Name::to_sexp,
  desc="Occurs when a linker hits the unresolved name.",
)

///|
/// Occurs when the linker hits an unresolved name (`Linker.unresolved`).
pub let linker_unresolved : Observation[Name] = will_fail.obs

///|
/// Posted when a call is made (`Linker.Trace.call_entered`).
pub let call_entered : Statement[(String, Array[Value])] = Statement::provide(
  "call",
  inspect=call_sexp,
  desc="Occurs when the call is made.",
)

///|
/// Occurs when a subroutine is called, with its name and input arguments
/// (`Linker.Trace.call`).
pub let call : Observation[(String, Array[Value])] = call_entered.obs

///|
/// Posted when a call returns (`Linker.Trace.call_returned`).
pub let call_returned : Statement[(String, Array[Value])] = Statement::provide(
  "call-return",
  inspect=call_sexp,
  desc="Occurs when the call returns.",
)

///|
/// Occurs when a subroutine returns, with its name and all arguments
/// (inputs followed by outputs) (`Linker.Trace.return`).
pub let call_return : Observation[(String, Array[Value])] = call_returned.obs

///|
/// Posted when a Lisp function is called (`Linker.Trace.lisp_call_entered`).
pub let lisp_call_entered : Statement[(String, Array[Value])] = Statement::provide(
  "lisp-call",
  inspect=call_sexp,
  desc="Occurs when the call to Lisp code is made.",
)

///|
/// Occurs when a Lisp function is called (`Linker.Trace.lisp_call`).
pub let lisp_call : Observation[(String, Array[Value])] = lisp_call_entered.obs

///|
/// Posted when a Lisp function returns (`Linker.Trace.lisp_call_returned`).
pub let lisp_call_returned : Statement[(String, Array[Value])] = Statement::provide(
  "lisp-call-return",
  inspect=call_sexp,
  desc="OCcurs when the call to Lisp code returns.",
)

///|
/// Occurs when a Lisp function returns (`Linker.Trace.lisp_call_return`).
pub let lisp_call_return : Observation[(String, Array[Value])] = lisp_call_returned.obs

///|
fn Linker::id_of_name(self : Linker, name : Name) -> Int32? {
  match name {
    Symbol(s) => self.names.get(s)
    Addr(a) => self.addrs.get(AddrKey(a))
    Tid(t) => self.terms.get(t)
  }
}

///|
fn Linker::code_of_name(self : Linker, name : Name) -> Code? {
  match self.id_of_name(name) {
    Some(id) => self.codes.get(id)
    None => None
  }
}

///|
fn Linker::resolve_name(self : Linker, name : Name) -> String? {
  match name {
    Symbol(s) => Some(s)
    _ =>
      match self.id_of_name(name) {
        None => None
        Some(id) =>
          match self.aliases.get(id) {
            Some({ name: Some(n), .. }) if self.names.get(n) == Some(id) =>
              Some(n)
            _ => None
          }
      }
  }
}

///|
/// Links code under the given names (`Linker.link`). Names already bound
/// are rebound to the new code.
pub fn Linker::link(
  m : Machine,
  addr? : @types.Word,
  name? : String,
  tid? : @types.Tid,
  code : Code,
) -> Unit {
  m.update_local(linker_state, s => {
    let key = s.last + 1
    {
      codes: s.codes.add(key, code),
      aliases: s.aliases.add(key, { term: tid, name, addr, }),
      terms: match tid {
        Some(t) => s.terms.add(t, key)
        None => s.terms
      },
      names: match name {
        Some(n) => s.names.add(n, key)
        None => s.names
      },
      addrs: match addr {
        Some(a) => s.addrs.add(AddrKey(a), key)
        None => s.addrs
      },
      last: key,
    }
  })
}

///|
/// Removes the code referred to by the name, together with all its other
/// names (`Linker.unlink`).
pub fn Linker::unlink(m : Machine, name : Name) -> Unit {
  let s = m.get_local(linker_state)
  guard s.id_of_name(name) is Some(id) else { return }
  let mut terms = s.terms
  let mut names = s.names
  let mut addrs = s.addrs
  for k, v in s.terms {
    if v == id {
      terms = terms.remove(k)
    }
  }
  for k, v in s.names {
    if v == id {
      names = names.remove(k)
    }
  }
  s.addrs.each((k, v) => if v == id { addrs = addrs.remove(k) })
  m.put_local(linker_state, {
    codes: s.codes.remove(id),
    aliases: s.aliases.remove(id),
    terms,
    names,
    addrs,
    last: s.last,
  })
}

///|
/// Looks up the code bound to the name (`Linker.lookup`).
pub fn Linker::lookup(m : Machine, name : Name) -> Code? {
  m.get_local(linker_state).code_of_name(name)
}

///|
/// Whether some code is bound to the name (`Linker.is_linked`).
pub fn Linker::is_linked(m : Machine, name : Name) -> Bool {
  Linker::lookup(m, name) is Some(_)
}

///|
fn Linker::resolve_refs(m : Machine, name : Name) -> Refs? {
  let s = m.get_local(linker_state)
  match s.id_of_name(name) {
    None => None
    Some(id) => s.aliases.get(id)
  }
}

///|
/// The address of the code bound to the name (`Linker.resolve_addr`).
pub fn Linker::resolve_addr(m : Machine, name : Name) -> @types.Word? {
  match Linker::resolve_refs(m, name) {
    Some(r) => r.addr
    None => None
  }
}

///|
/// The symbol of the code bound to the name (`Linker.resolve_symbol`).
pub fn Linker::resolve_symbol(m : Machine, name : Name) -> String? {
  match Linker::resolve_refs(m, name) {
    Some(r) => r.name
    None => None
  }
}

///|
/// The tid of the code bound to the name (`Linker.resolve_tid`).
pub fn Linker::resolve_tid(m : Machine, name : Name) -> @types.Tid? {
  match Linker::resolve_refs(m, name) {
    Some(r) => r.term
    None => None
  }
}

///|
/// Runs code: host code runs immediately; interpreted code is pushed onto
/// the control stack (tail position).
fn run_code(m : Machine, name : Name?, code : Code) -> Unit raise {
  if name is Some(n) {
    m.make(will_exec, n)
  }
  match code {
    Host(f) => f(m)
    Subroutine(sub) => m.push(SubEnter(sub))
    Block(blk) => m.push(BlkEnter(blk))
  }
}

///|
fn exec_unresolved(m : Machine, name : Name) -> Unit raise {
  m.make(will_fail, name)
  let s = m.get_local(linker_state)
  match s.code_of_name(Symbol(unresolved_handler)) {
    Some(code) => run_code(m, Some(name), code)
    None =>
      match s.resolve_name(name) {
        Some(sym) => m.raise_exn(UnboundName(Symbol(sym)))
        None => m.raise_exn(UnboundName(name))
      }
  }
}

///|
/// Executes the code bound to the name in the tail position: interpreted
/// code is pushed onto the control stack and executed by the scheduler.
fn exec_tail(m : Machine, name : Name) -> Unit raise {
  match Linker::lookup(m, name) {
    None => exec_unresolved(m, name)
    Some(code) => run_code(m, Some(name), code)
  }
}

///|
/// Binds call arguments to the input arguments of a subroutine: each
/// argument value is assigned to the expression of the corresponding
/// input (`in` or `in/out`) argument term.
fn bind_sub_args(
  m : Machine,
  sub : @types.Term[@types.Sub],
  args : Array[Value],
) -> Unit raise {
  let mut i = 0
  for arg in sub.args() {
    if i >= args.length() {
      break
    }
    if !(arg.intent() is Some(Out)) {
      Interpreter::assign(m, arg.arg_rhs(), args[i])
      i += 1
    }
  }
}

///|
/// Starts a call: resets the result register, publishes the arguments and
/// runs the code (the `CallName`/`CallCode` frames).
fn call_code_now(
  m : Machine,
  name : Name?,
  code : Code,
  args : Array[Value],
) -> Unit raise {
  m.current.result = None
  m.current.call_args = args
  if code is Subroutine(sub) && !args.is_empty() {
    bind_sub_args(m, sub, args)
  }
  run_code(m, name, code)
}

///|
fn call_name(m : Machine, name : Name, args : Array[Value]) -> Unit raise {
  match Linker::lookup(m, name) {
    Some(code) => call_code_now(m, Some(name), code, args)
    None => {
      m.current.result = None
      m.current.call_args = args
      exec_unresolved(m, name)
    }
  }
}

///|
/// Executes the code bound to the name and waits for it to finish
/// (`Linker.exec`). If nothing is bound, `linker_unresolved` is posted and
/// the `unresolved_handler` is called if linked, otherwise `UnboundName` is
/// raised. This is a synchronous (nested) run: forks requested by the
/// callee take effect only when the enclosing step ends; use
/// `Machine::call` for a forkable call.
pub fn Linker::exec(m : Machine, name : Name) -> Unit raise {
  m.run_nested(() => m.push(Exec(name)))
}

///|
/// Calls the code bound to the name with the arguments, waits for it to
/// finish and returns its result (see `Machine::call` for the protocol).
/// This is a synchronous (nested) run; use `Machine::call` for a forkable
/// call.
pub fn Linker::call(
  m : Machine,
  name : Name,
  args~ : Array[Value] = [],
) -> Value? raise {
  m.run_nested(() => m.push(CallName(name, args)))
  m.current.result
}

///|
/// Schedules the execution of the name as a separate step of the current
/// machine (see `Machine::schedule`). Use it (e.g. in the `start` code of
/// a run) to execute a program at the top level, where it can be forked.
pub fn Linker::schedule_exec(m : Machine, name : Name) -> Unit {
  m.push_user(Exec(name))
}
