///|
/// The plugin name; pass names are prefixed with it.
pub let name : String = "warn-unused"

///|
let doc : String =
  #|the legacy warn-unused analysis
  #|
  #|If a subroutine has GNU attribute warn_unused_result and its result is
  #|not used, then print a warning message.
  #|
  #|--warn-unused-taint taints all values defined by functions that are marked
  #|with warn_unused_result (runs callsites as a dependency);
  #|--warn-unused-print prints all calls that weren't checked;
  #|--warn-unused-mark marks all unchecked calls with the dead attribute;
  #|--warn-unused is the same as --warn-unused-taint --propagate-taint
  #|--warn-unused-print.

///|
/// The attribute key of `Taint.regs`: the taints of registers that a term
/// reads, as computed by the taint propagation analysis.
pub let tainted_regs_attr : String = "tainted-regs"

///|
/// Attaches the register taint map (`Taint.regs`) to a term. Each entry maps
/// a variable to the set of taint seeds (term identifiers) it carries.
pub fn[T] with_tainted_regs(
  term : @types.Term[T],
  regs : Array[(@types.Var, Array[@types.Tid])],
) -> @types.Term[T] {
  let entries = regs.map(entry => {
    let tids = entry.1.map(tid => tid.to_string()).join(",")
    "\{entry.0.to_string()}=\{tids}"
  })
  term.set_attr(
    @types.Attr::new(key=tainted_regs_attr, value=entries.join(";")),
  )
}

///|
/// Reads the register taint map (`Taint.regs`) of a term, keyed by the
/// printed variable.
pub fn[T] tainted_regs(
  term : @types.Term[T],
) -> Array[(String, Array[@types.Tid])]? {
  match term.get_attr(tainted_regs_attr) {
    None => None
    Some(text) => {
      let result = []
      for entry in text.split(";") {
        if entry.is_empty() {
          continue
        }
        let (reg, tids) = match entry.rev_split_once("=") {
          Some((v, t)) => (v.to_owned(), t.to_owned())
          None => (entry.to_owned(), "")
        }
        let parsed = []
        for tid in tids.split(",") {
          if tid.is_empty() {
            continue
          }
          match @types.Tid::from_string(tid.to_owned()) {
            Ok(t) => parsed.push(t)
            Err(_) => ()
          }
        }
        result.push((reg, parsed))
      }
      Some(result)
    }
  }
}

///|
fn process(
  prog : @types.Term[@types.Program],
  def : @types.Term[@types.Def],
  taint : @types.Tid,
  call : @types.Call,
) -> @types.Term[@types.Def] {
  match call.target() {
    Indirect(_) => def
    Direct(callee) =>
      match prog.find_sub(callee) {
        None => def
        Some(sub) =>
          if sub
            .args()
            .any(arg => arg.arg_lhs() == def.lhs() && arg.is_warn_unused()) {
            def.with_tainted_reg(taint)
          } else {
            def
          }
      }
  }
}

///|
/// Taints every definition synthesized for a call (see the `callsites`
/// plugin) that defines a `warn_unused_result` argument of the callee. The
/// taint seed is the call term.
pub fn taint_program(
  prog : @types.Term[@types.Program],
) -> @types.Term[@types.Program] {
  prog.map_subs(sub => {
    sub.map_blks(blk => {
      blk.map_defs(def => {
        match def.origin() {
          None => def
          Some(tid) =>
            match prog.program_find_jmp(tid) {
              None => def
              Some(jmp) =>
                match jmp.kind() {
                  JmpCall(call) => process(prog, def, jmp.tid(), call)
                  _ => def
                }
            }
        }
      })
    })
  })
}

///|
/// The seeds of visited terms (`collect_seeds`).
pub fn collect_seeds(prog : @types.Term[@types.Program]) -> Array[@types.Tid] {
  prog.fold_program_terms([], (seeds, term) => {
    match term.tainted_reg() {
      Some(seed) if term.is_visited() && !seeds.contains(seed) =>
        seeds.push(seed)
      _ => ()
    }
    seeds
  })
}

///|
fn sanitize(term : @types.IrTerm, seeds : @hashset.HashSet[@types.Tid]) -> Unit {
  if term.taints_reg() {
    return
  }
  let taints = match term {
    DefTerm(def) => tainted_regs(def)
    JmpTerm(jmp) => tainted_regs(jmp)
    _ => None
  }
  match taints {
    None => ()
    Some(entries) =>
      for entry in entries {
        for tid in entry.1 {
          seeds.remove(tid)
        }
      }
  }
}

///|
/// Removes from `seeds` every seed that reaches a use in some definition or
/// jump; the remaining seeds are unchecked calls (`solve`).
pub fn solve(
  prog : @types.Term[@types.Program],
  seeds : Array[@types.Tid],
) -> Array[@types.Tid] {
  let set = @hashset.HashSet::from_array(seeds)
  for term in prog.program_terms() {
    match term {
      DefTerm(_) | JmpTerm(_) => sanitize(term, set)
      _ => ()
    }
  }
  seeds.filter(seed => set.contains(seed))
}

///|
/// The unchecked calls of the project program.
pub fn unchecked(project : @project.Project) -> Array[@types.Tid] {
  let prog = project.program()
  solve(prog, collect_seeds(prog))
}

///|
/// Renders the unchecked calls, one jump per line (`print`).
pub fn render_unchecked(
  prog : @types.Term[@types.Program],
  unchecked : Array[@types.Tid],
) -> String {
  let sb = StringBuilder()
  for jmp in prog.program_jmps() {
    if unchecked.contains(jmp.tid()) {
      sb.write_string("\{jmp.tid().to_string()}: \{jmp.jmp_to_string()}\n")
    }
  }
  sb.to_string()
}

///|
/// Marks the unchecked terms with the `dead` attribute (`mark`).
pub fn mark_unchecked(
  prog : @types.Term[@types.Program],
  unchecked : Array[@types.Tid],
) -> @types.Term[@types.Program] {
  prog.map_program_terms(term => {
    if unchecked.contains(term.tid()) {
      term.set_dead()
    } else {
      term
    }
  })
}

///|
/// The `warn-unused-taint` transformation.
pub fn taint(project : @project.Project) -> @project.Project {
  project.map_program(taint_program)
}

///|
/// The `warn-unused-mark` transformation.
pub fn mark(project : @project.Project) -> @project.Project {
  let found = unchecked(project)
  project.map_program(prog => mark_unchecked(prog, found))
}

///|
/// The `warn-unused-print` action.
pub fn print(project : @project.Project, out~ : (String) -> Unit) -> Unit {
  let found = unchecked(project)
  let text = render_unchecked(project.program(), found)
  if !text.is_empty() {
    out(text)
  }
}

///|
/// The project passes of the plugin: `warn-unused-taint` (after
/// `callsites`), `warn-unused-print`, `warn-unused-mark`, and `warn-unused`,
/// which only chains `warn-unused-taint`, `propagate-taint`, and
/// `warn-unused-print`.
pub fn passes(
  out? : (String) -> Unit = s => println(s.trim_end(chars="\n")),
) -> Array[@project.ProjectPass] {
  [
    @project.ProjectPass::create(name="\{name}-taint", deps=[@callsites.name], run=project => {
      Ok(taint(project))
    }),
    @project.ProjectPass::create(name="\{name}-print", run=project => {
      print(project, out~)
      Ok(project)
    }),
    @project.ProjectPass::create(name="\{name}-mark", run=project => {
      Ok(mark(project))
    }),
    @project.ProjectPass::create(
      name~,
      deps=["\{name}-taint", "propagate-taint", "\{name}-print"],
      run=project => Ok(project),
    ),
  ]
}

///|
/// Registers the plugin passes (and the `callsites` pass they depend on).
/// Idempotent: returns `false` if the passes were already registered.
pub fn register(out? : (String) -> Unit) -> Result[Bool, String] {
  match @callsites.register() {
    Err(reason) => return Err(reason)
    Ok(_) => ()
  }
  let mut registered = false
  for pass in passes(out?) {
    match @project.register_pass_if_absent(pass) {
      Ok(fresh) => registered = registered || fresh
      Err(reason) => return Err(reason)
    }
  }
  Ok(registered)
}

///|
/// Declares the `warn-unused` plugin to `bap_main`. Does nothing if already
/// declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(name, provides=["pass", "analysis"], doc~, () => {
    let _ = @bap_main.Configuration::flag(doc="run the taint pass", "taint")
    let _ = @bap_main.Configuration::flag(doc="run the print pass", "print")
    let _ = @bap_main.Configuration::flag(doc="run the mark pass", "mark")
    @bap_main.Extension::register(_ => {
      match register() {
        Ok(_) => ()
        Err(reason) => fail(reason)
      }
    })
  })
}
