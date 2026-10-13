///|
/// # The promiscuous mode (upstream `plugins/primus_promiscuous`)
///
/// In general a block is terminated by a sequence of jumps
///
/// ```text
/// when C1 jmp D1
/// when C2 jmp D2
/// ...
/// when Cm jmp Dm
/// ```
///
/// and the IR requires the invariant `C1 \/ C2 \/ ... \/ Cm`. The
/// promiscuous path explorer is a non-deterministic interpreter that, for
/// every block terminated with `m` jumps, forks up to `m-1` machines after
/// the last definition of the block, so that in the `n`-th machine the
/// destination `Dn` is taken. For `Dn` to be taken the condition
/// `~C1 /\ ... /\ ~C(n-1) /\ Cn` must hold; since that would in general
/// require an SMT solver, the program must be in the trivial condition
/// form (TCF, see `@project.Project::to_trivial_condition_form`), where
/// every jump condition is a single variable or a constant. The forked
/// machine forcefully assigns the variables (the *assumptions*) and
/// records them as its *conflicts*. Blocks that were already visited (by
/// any machine, or marked with the `visited` attribute in the project) do
/// not fork again.
///
/// Calls with a direct return label also fork: the forked machine skips
/// the call, continues from the return block and halts when the block
/// returns, so that the code after a call is explored even if the callee
/// is unresolved or never returns.
///
/// As upstream, the forked machine immediately switches back to its
/// parent, which continues first; the child is resumed later by a
/// scheduler (e.g., the greedy one).
pub let component_name : String = "promiscuous-path-explorer"

///|
/// The name of the component that disables division by zero errors.
pub let division_by_zero_component : String = "division-by-zero-handler"

///|
/// An assumption: the variable `variable` used by the jump `jmp` is assumed to
/// be `res`.
pub(all) struct Assn {
  jmp : @types.Tid
  variable : @types.Var
  res : Bool
}

///|
/// Renders an assumption as upstream (`(<tid>: <var> <bool>)`).
pub fn Assn::to_sexp(self : Assn) -> @primus.Sexp {
  List([
    Atom("\{self.jmp.to_string()}: \{self.variable.to_string()}"),
    Atom(if self.res { "true" } else { "false" }),
  ])
}

///|
priv struct Conflicts {
  conflicts : Array[Assn]
  visited : @immut_hashset.HashSet[@types.Tid]
}

///|
fn init_visited(
  prog : @types.Term[@types.Program],
) -> @immut_hashset.HashSet[@types.Tid] {
  let mut visited = @immut_hashset.new()
  for sub in prog.subs() {
    for blk in sub.blks() {
      if blk.is_visited() {
        visited = visited.add(blk.tid())
      }
    }
  }
  visited
}

///|
let state : @primus.State[Conflicts] = @primus.State::declare_(
  uuid="58bb35f4-f259-4712-8d15-bdde1be3caa8",
  name="conflicts",
  inspect=s => List(s.conflicts.map(Assn::to_sexp)),
  proj => { conflicts: [], visited: init_visited(proj.program()), },
)

///|
/// The assumptions forced in the current machine (empty in machines that
/// did not deviate from the concrete path).
pub fn conflicts(m : @primus.Machine) -> Array[Assn] {
  m.get_local(state).conflicts
}

///|
/// Whether the block was already visited (and will not fork again).
pub fn is_visited(m : @primus.Machine, tid : @types.Tid) -> Bool {
  m.get_global(state).visited.contains(tid)
}

///|
fn neg(assns : @list.List[Assn]) -> @list.List[Assn] {
  assns.map(a => { ..a, res: !a.res, })
}

///|
/// The assumptions for taking each jump of the block: for the `n`-th jump
/// the conditions of the previous jumps are false and its own condition
/// (if it is a variable) is true. The result is in the reverse order of
/// jumps, as upstream. Raises if a condition is neither a variable nor a
/// constant (the block is not in TCF).
pub fn assumptions(
  blk : @types.Term[@types.Blk],
) -> Array[Array[Assn]] raise @primus.PrimusError {
  let mut assns : @list.List[Assn] = @list.List([])
  let mut assms : @list.List[Array[Assn]] = @list.List([])
  for jmp in blk.jmps() {
    match jmp.cond() {
      Var(c) => {
        let assn = { jmp: jmp.tid(), variable: c, res: true, }
        assms = assms.prepend([assn, ..neg(assns).to_array()])
        assns = assns.prepend(assn)
      }
      Int(_) => assms = assms.prepend(neg(assns).to_array())
      _ => raise RuntimeError("Not in TCF")
    }
  }
  assms.to_array()
}

///|
fn force_assumptions(m : @primus.Machine, assns : Array[Assn]) -> Unit raise {
  for assn in assns {
    let r = @primus.Interpreter::constant(m, @types.Word::of_bool(assn.res))
    let r2 = @primus.Interpreter::get(m, assn.variable)
    let op : @types.BinOp = if assn.res { Or } else { And }
    let v = @primus.Interpreter::binop(m, op, r, r2)
    @primus.Interpreter::set(m, assn.variable, v)
  }
}

///|
fn unsat_assumptions(
  m : @primus.Machine,
  blk : @types.Term[@types.Blk],
) -> Array[Array[Assn]] raise {
  assumptions(blk).map(assns => {
    assns.filter(a => {
      let r = @primus.Env::get(m, a.variable).to_word()
      r != @types.Word::of_bool(a.res)
    })
  })
}

///|
/// Forks the machine unless the block is visited: the child runs `child`,
/// switches back to the parent and continues with `k(m, child_id)` when it
/// is resumed; the parent continues with `k(m, parent_id)`.
fn do_fork(
  m : @primus.Machine,
  blk : @types.Term[@types.Blk],
  child~ : (@primus.Machine) -> Unit raise,
  k : (@primus.Machine, @primus.Id) -> Unit raise,
) -> Unit raise {
  let pid = m.current()
  if is_visited(m, blk.tid()) {
    return k(m, pid)
  }
  m.fork(then=m => {
    if m.current() == pid {
      k(m, pid)
    } else {
      let id = m.current()
      child(m)
      m.switch(pid, then=m => k(m, id))
    }
  })
}

///|
fn fork_each(
  m : @primus.Machine,
  blk : @types.Term[@types.Blk],
  lists : Array[Array[Assn]],
  i : Int32,
) -> Unit raise {
  guard i < lists.length() else { return }
  let conflicts = lists[i]
  if conflicts.is_empty() {
    fork_each(m, blk, lists, i + 1)
  } else {
    do_fork(
      m,
      blk,
      child=m => {
        force_assumptions(m, conflicts)
        m.update_local(state, t => { ..t, conflicts, })
      },
      (m, _) => fork_each(m, blk, lists, i + 1),
    )
  }
}

///|
fn fork_blk(m : @primus.Machine, blk : @types.Term[@types.Blk]) -> Unit raise {
  fork_each(m, blk, unsat_assumptions(m, blk), 0)
}

///|
fn assume_returns(
  m : @primus.Machine,
  blk : @types.Term[@types.Blk],
  call : @types.Call,
) -> Unit raise {
  guard call.return_label() is Some(Direct(dst)) else { return }
  let pid = m.current()
  do_fork(m, blk, child=_ => (), (m, id) => {
    if id != pid {
      m.schedule(m => @primus.Interpreter::halt(m))
      if !is_visited(m, dst) {
        @primus.Linker::schedule_exec(m, Tid(dst))
      }
    }
  })
}

///|
fn is_last(
  blk : @types.Term[@types.Blk],
  def : @types.Term[@types.Def],
) -> Bool {
  match blk.last_def() {
    None => true
    Some(last) => last.tid() == def.tid()
  }
}

///|
fn step(m : @primus.Machine, pos : @primus.Pos) -> Unit raise {
  match pos {
    Blk({ me: blk, .. }) if blk.def_count() == 0 => fork_blk(m, blk)
    Def({ up: { me: blk, .. }, me: def, }) if is_last(blk, def) =>
      fork_blk(m, blk)
    Jmp({ up: { me: blk, .. }, me: jmp, }) =>
      if jmp.kind() is JmpCall(call) {
        assume_returns(m, blk, call)
      }
    _ => ()
  }
}

///|
fn mark_visited(m : @primus.Machine, blk : @types.Term[@types.Blk]) -> Unit {
  m.update_global(state, t => { ..t, visited: t.visited.add(blk.tid()), })
}

///|
/// Initializes the path explorer in the machine (the component body).
pub fn install(m : @primus.Machine) -> Unit {
  m.observe(@primus.leave_pos, pos => step(m, pos))
  m.observe(@primus.leave_blk, blk => mark_visited(m, blk))
}

///|
/// Links a handler that ignores divisions by zero (the
/// `division-by-zero-handler` component body).
pub fn install_division_by_zero_handler(m : @primus.Machine) -> Unit {
  @primus.Linker::link(m, name=@primus.division_by_zero_handler, Host(_ => ()))
}

///|
/// Registers the `bap:promiscuous-path-explorer` and
/// `bap:division-by-zero-handler` components. Idempotent: returns `false`
/// if they were already registered.
pub fn register() -> Bool {
  @primus.Components::register_generic(
    component_name,
    m => install(m),
    pkg="bap",
    desc="Forces execution of all linearly independent paths by forcefully flipping the branch conditions.",
  ) catch {
    _ => return false
  }
  @primus.Components::register_generic(
    division_by_zero_component,
    m => install_division_by_zero_handler(m),
    pkg="bap",
    desc="Disables division by zero errors.",
  ) catch {
    _ => ()
  }
  true
}

///|
/// The components added to the legacy main system by the (deprecated)
/// `--primus-promiscuous-mode` flag.
pub let legacy_promiscuous_mode_components : Array[String] = [
  "var-randomizer", "mem-randomizer", "arg-randomizer", "promiscuous-path-explorer",
  "division-by-zero-handler", "limit",
]

///|
/// Adds the promiscuous mode components to the `bap:legacy-main` system
/// (upstream `enable_legacy_promiscuous_mode`).
pub fn enable_legacy_promiscuous_mode() -> Unit raise @primus.SystemError {
  @primus.System::update("legacy-main", pkg="bap", sys => {
    let mut sys = sys
    for c in legacy_promiscuous_mode_components {
      sys = sys.add_component(c, pkg="bap")
    }
    sys
  })
}

///|
/// The name of the plugin.
pub let name : String = "primus-promiscuous"

///|
let doc : String =
  #|enables the promiscuous mode of execution
  #|
  #|When this mode is enabled the Primus Machine will venture into paths
  #|with unsatisfied constraints. Basically, it means that on every branch
  #|the state is duplicated. The program will be translated into the
  #|Trivial Condition Form, where each compound condition expression is
  #|trivialized to a variable, that is bound earlier in the block.

///|
/// Declares the `primus-promiscuous` plugin to `bap_main` with its
/// (deprecated) `mode` flag. Does nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(name, provides=["primus", "fuzzer"], doc~, () => {
    let flag = @bap_main.Configuration::flag(
      "mode",
      doc="(DEPRECATED) Enable the mode.",
    )
    @bap_main.Extension::register(ctxt => {
      register() |> ignore
      if ctxt.get(flag) {
        enable_legacy_promiscuous_mode()
      }
    })
  })
}

///|
/// Translates the project program into the trivial condition form required
/// by the path explorer.
pub fn to_tcf(proj : @project.Project) -> @project.Project {
  proj.to_trivial_condition_form()
}
