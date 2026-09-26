///|
/// The name of the plugin and of its project pass.
pub let name : String = "callsites"

///|
let doc : String =
  #|annotates callsites with subroutines arguments
  #|
  #|Injects artificial definitions of subroutine arguments at call sites.
  #|Input arguments are defined just before the call, and output arguments
  #|are defined at the beginning of the block to which the callee returns.

///|
/// The attribute key of the instruction tag (`Disasm.insn`) transferred from
/// the call to the synthesized definitions.
pub let insn_attr : String = "insn"

///|
let address_attr = "address"

///|
fn call_of_jmp(jmp : @types.Term[@types.Jmp]) -> @types.Call? {
  match jmp.kind() {
    JmpCall(call) => Some(call)
    Goto(_) | Ret(_) | Interrupt(_, _) => None
  }
}

///|
fn callee(
  call : @types.Call,
  prog : @types.Term[@types.Program],
) -> @types.Term[@types.Sub]? {
  match call.target() {
    Direct(tid) => prog.find_sub(tid)
    Indirect(_) => None
  }
}

///|
/// `true` if an argument with the given intent should be materialized for a
/// callsite processed with `intent` (unknown intents always match).
pub fn intent_matches(
  arg : @types.Term[@types.Arg],
  intent : @types.Intent,
) -> Bool {
  match arg.intent() {
    None => true
    Some(x) =>
      match (x, intent) {
        (In, In) | (Out, Out) => true
        (Both, _) | (_, Both) => true
        _ => false
      }
  }
}

///|
fn[A, B] transfer_attr(
  key : String,
  src : @types.Term[A],
  dst : @types.Term[B],
) -> @types.Term[B] {
  match src.get_attr(key) {
    Some(value) => dst.set_attr(@types.Attr::new(key~, value~))
    None => dst
  }
}

///|
fn transfer_attrs(
  call : @types.Term[@types.Jmp],
  def : @types.Term[@types.Def],
) -> @types.Term[@types.Def] {
  let def = def.with_synthetic().with_origin(call.tid())
  transfer_attr(address_attr, call, transfer_attr(insn_attr, call, def))
}

///|
/// Creates a definition from an argument, preserving the argument attributes
/// (`def_of_arg`).
pub fn def_of_arg(arg : @types.Term[@types.Arg]) -> @types.Term[@types.Def] {
  @types.Def::create(arg.arg_lhs(), arg.arg_rhs()).with_attrs(arg.attrs())
}

///|
fn intent_rank(intent : @types.Intent?) -> Int {
  match intent {
    None => 0
    Some(In) => 1
    Some(Out) => 2
    Some(Both) => 3
  }
}

///|
/// Arguments of a subroutine stably sorted by intent (`enum_args`).
fn enum_args(sub : @types.Term[@types.Sub]) -> Array[@types.Term[@types.Arg]] {
  let indexed = sub.args().mapi((i, arg) => (i, arg))
  indexed.sort_by((x, y) => {
    let c = intent_rank(x.1.intent()).compare(intent_rank(y.1.intent()))
    if c != 0 {
      c
    } else {
      x.0.compare(y.0)
    }
  })
  indexed.map(p => p.1)
}

///|
fn defs_of_args(
  call : @types.Term[@types.Jmp],
  intent : @types.Intent,
  args : Array[@types.Term[@types.Arg]],
) -> Array[@types.Term[@types.Def]] {
  args.filter_map(arg => {
    if intent_matches(arg, intent) {
      Some(transfer_attrs(call, def_of_arg(arg)))
    } else {
      None
    }
  })
}

///|
fn add_def(
  intent : @types.Intent,
  blk : @types.Term[@types.Blk],
  def : @types.Term[@types.Def],
) -> @types.Term[@types.Blk] {
  match intent {
    Out => blk.insert_def_before(def)
    _ => blk.append_def(def)
  }
}

///|
fn target(
  intent : @types.Intent,
  sub : @types.Term[@types.Sub],
  blk : @types.Term[@types.Blk],
  call : @types.Call,
) -> @types.Term[@types.Blk]? {
  match intent {
    Out =>
      match call.return_label() {
        Some(Direct(tid)) => sub.find_blk(tid)
        _ => None
      }
    _ => Some(blk)
  }
}

///|
/// Inserts argument definitions at every callsite of `sub` whose callee is a
/// subroutine of `prog` (`insert_defs`).
pub fn insert_defs(
  prog : @types.Term[@types.Program],
  sub : @types.Term[@types.Sub],
) -> @types.Term[@types.Sub] {
  let mut sub = sub
  for intent in [@types.In, @types.Out] {
    for blk in sub.blks() {
      for jmp in blk.jmps() {
        guard call_of_jmp(jmp) is Some(call) else { continue }
        guard callee(call, prog) is Some(callee) else { continue }
        guard target(intent, sub, blk, call) is Some(dst) else { continue }
        let updated = defs_of_args(jmp, intent, enum_args(callee)).fold(
          init=dst,
          (blk, def) => add_def(intent, blk, def),
        )
        sub = sub.update_blk(updated)
      }
    }
  }
  sub
}

///|
/// Annotates all callsites of the program (`fill_calls`).
pub fn fill_calls(
  prog : @types.Term[@types.Program],
) -> @types.Term[@types.Program] {
  prog.map_subs(sub => insert_defs(prog, sub))
}

///|
/// The `callsites` project transformation (`main`).
pub fn run(project : @project.Project) -> @project.Project {
  project.map_program(fill_calls)
}

///|
/// Creates the `callsites` project pass, which depends on the `abi` pass.
pub fn pass() -> @project.ProjectPass {
  @project.ProjectPass::create(name~, deps=["abi"], run=project => {
    Ok(run(project))
  })
}

///|
/// Registers the `callsites` pass together with the `abi` pass it depends on.
/// Idempotent: returns `false` if the pass was already registered.
pub fn register() -> Result[Bool, String] {
  match @abi.register_project_pass_if_absent() {
    Ok(_) => @project.register_pass_if_absent(pass())
    Err(reason) => Err(reason)
  }
}

///|
/// Declares the `callsites` plugin to `bap_main`. Does nothing if already
/// declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(name, provides=["pass"], doc~, () => {
    @bap_main.Extension::register(_ => {
      match register() {
        Ok(_) => ()
        Err(reason) => fail(reason)
      }
    })
  })
}
