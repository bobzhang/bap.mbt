///|
/// The plugin name and the name of its project pass.
pub let name : String = "glibc-runtime"

///|
let doc : String =
  #|Enables ad-hoc support for glibc runtime code. In particular it detects
  #|the locations of main and __libc_start_main functions (and adds the
  #|latter if it is absent).

///|
let libc_start_main = "__libc_start_main"

///|
/// The attribute key of the C prototype (`C.proto`) dropped on renaming.
pub let c_proto_attr : String = "c.proto"

///|
/// `true` if the specification references `__libc_start_main` externally.
pub fn references_glibc_start_main(doc : @ogre.Doc) -> Bool {
  doc
  .get(@image.Scheme::external_reference())
  .iter()
  .any(entry => entry.1 == libc_start_main)
}

///|
/// `true` if the project looks like a glibc executable (`is_glibc`).
pub fn is_glibc(project : @project.Project) -> Bool {
  references_glibc_start_main(project.specification())
}

///|
fn find_by_name(
  prog : @types.Term[@types.Program],
  sub_name : String,
) -> @types.Term[@types.Sub]? {
  for sub in prog.subs() {
    if sub.sub_name() == sub_name {
      return Some(sub)
    }
  }
  None
}

///|
fn calls(jmp : @types.Term[@types.Jmp], tid : @types.Tid) -> Bool {
  match jmp.kind() {
    JmpCall(call) => call.target() == Direct(tid)
    _ => false
  }
}

///|
/// The first block (in program order) that calls the subroutine `tid`.
fn find_first_caller(
  prog : @types.Term[@types.Program],
  tid : @types.Tid,
) -> @types.Term[@types.Blk]? {
  for sub in prog.subs() {
    for blk in sub.blks() {
      if blk.jmps().iter().any(jmp => calls(jmp, tid)) {
        return Some(blk)
      }
    }
  }
  None
}

///|
fn is_sub_absent(prog : @types.Term[@types.Program], sub_name : String) -> Bool {
  find_by_name(prog, sub_name) is None
}

///|
fn find_entry_point(
  prog : @types.Term[@types.Program],
) -> @types.Term[@types.Sub]? {
  for sub in prog.subs() {
    if sub.is_entry_point() {
      return Some(sub)
    }
  }
  None
}

///|
fn insert_call(
  prog : @types.Term[@types.Program],
  start : @types.Term[@types.Sub],
  entry : @types.Term[@types.Blk],
  jmp : @types.Term[@types.Jmp],
) -> (@types.Tid, @types.Term[@types.Program]) {
  let tid = @types.Tid::for_name(libc_start_main)
  let sub = @types.Sub::create(tid~, name=libc_start_main)
  let prog = prog.append_sub(sub)
  let call = @types.Jmp::create_call(
    @types.Call::create(target=@types.Label::direct(tid)),
  )
  let entry = entry.remove_jmp(jmp.tid()).insert_jmp_before(call)
  let start = start.update_blk(entry)
  (tid, prog.update_sub(start))
}

///|
/// Finds (or synthesizes) the `__libc_start_main` subroutine called from the
/// first block of the entry point (`find_libc_start_main`).
pub fn find_libc_start_main(
  prog : @types.Term[@types.Program],
) -> (@types.Tid, @types.Term[@types.Program])? {
  guard find_entry_point(prog) is Some(start) else { return None }
  guard start.first_blk() is Some(entry) else { return None }
  guard entry.first_jmp() is Some(jmp) else { return None }
  match jmp.kind() {
    Goto(_) => Some(insert_call(prog, start, entry, jmp))
    Ret(_) | Interrupt(_, _) => None
    JmpCall(call) =>
      match call.target() {
        Direct(tid) => Some((tid, prog))
        Indirect(_) => Some(insert_call(prog, start, entry, jmp))
      }
  }
}

///|
fn proj_int(exp : @types.Exp) -> @types.Word? {
  match exp {
    Int(x) => Some(x)
    _ => None
  }
}

///|
/// Detects the address of `main` from the first argument that the first
/// caller of `__libc_start_main` passes to it (`detect_main_address`).
pub fn detect_main_address(prog : @types.Term[@types.Program]) -> @types.Word? {
  guard find_by_name(prog, libc_start_main) is Some(start) else { return None }
  guard find_first_caller(prog, start.tid()) is Some(entry) else { return None }
  guard start.first_arg() is Some(arg) else { return None }
  let defs = entry.defs().rev()
  match arg.arg_rhs() {
    Var(reg) =>
      match defs.search_by(def => def.lhs().same(reg)) {
        Some(i) => proj_int(defs[i].rhs())
        None => None
      }
    Load(addr~, ..) =>
      for def in defs {
        match def.rhs() {
          Store(addr=a, value~, ..) if a == addr => break proj_int(value)
          _ => ()
        }
      } nobreak {
        None
      }
    _ => None
  }
}

///|
/// Drops the arguments and the C prototype of a subroutine, renames it, and
/// applies the ABI to it (`reinsert_args_for_new_name`).
pub fn reinsert_args_for_new_name(
  sub : @types.Term[@types.Sub],
  new_name : String,
  abi? : (@types.Term[@types.Sub]) -> @types.Term[@types.Sub] = sub => sub,
) -> @types.Term[@types.Sub] {
  abi(sub.filter_args(_ => false).del_attr(c_proto_attr).with_name(new_name))
}

///|
/// Renames the subroutine located at the detected `main` address to `main`
/// when the program has no `main` subroutine (`rename_main`).
pub fn rename_main(
  prog : @types.Term[@types.Program],
  abi? : (@types.Term[@types.Sub]) -> @types.Term[@types.Sub] = sub => sub,
) -> @types.Term[@types.Program] {
  if !is_sub_absent(prog, "main") {
    return prog
  }
  match detect_main_address(prog) {
    None => prog
    Some(addr) =>
      prog.map_subs(sub => {
        if @types.IrTerm::SubTerm(sub).has_address(addr) {
          reinsert_args_for_new_name(sub, "main", abi~)
        } else {
          sub
        }
      })
  }
}

///|
/// Names the subroutine called from the program entry `__libc_start_main`,
/// inserting it when necessary (`rename_libc_start_main`).
pub fn rename_libc_start_main(
  prog : @types.Term[@types.Program],
) -> @types.Term[@types.Program] {
  if !is_sub_absent(prog, libc_start_main) {
    return prog
  }
  match find_libc_start_main(prog) {
    None => prog
    Some((tid, prog)) =>
      prog.change_sub(tid, sub => {
        sub.map(s => reinsert_args_for_new_name(s, libc_start_main))
      })
  }
}

///|
/// The ABI pass component: discovers `__libc_start_main` when enabled or
/// when the project references glibc.
pub fn discover_libc_start_main(
  project : @project.Project,
  enable? : Bool = false,
) -> @project.Project {
  if enable || is_glibc(project) {
    project.map_program(rename_libc_start_main)
  } else {
    project
  }
}

///|
/// The `glibc-runtime` pass: recovers `main` when enabled or when the project
/// references glibc (`recover_main`).
pub fn recover_main(
  project : @project.Project,
  enable? : Bool = false,
  main_abi? : (@project.Project, @types.Term[@types.Sub]) -> @types.Term[
    @types.Sub,
  ] = (_, sub) => sub,
) -> @project.Project {
  if enable || is_glibc(project) {
    project.map_program(prog => {
      rename_main(prog, abi=sub => main_abi(project, sub))
    })
  } else {
    project
  }
}

///|
let glibc_internal_prefix = "__GI_"

///|
/// Computes the aliases of a label with the `__GI_` (glibc internal) prefix
/// stripped from its name and existing aliases (the
/// `glibc-internal-aliases` rule). The result includes the old aliases.
pub fn glibc_internal_aliases(
  label_name : String?,
  aliases : Array[String],
) -> Array[String] {
  let result : Array[String] = []
  let add = (s : String) => {
    if !s.is_empty() && !result.contains(s) {
      result.push(s)
    }
  }
  let strip = (s : String) => {
    if s.has_prefix(glibc_internal_prefix) {
      Some(
        s.unsafe_substring(start=glibc_internal_prefix.length(), end=s.length()),
      )
    } else {
      None
    }
  }
  match label_name.bind(strip) {
    Some(s) => add(s)
    None => ()
  }
  for other in aliases {
    match strip(other) {
      Some(s) => add(s)
      None => ()
    }
  }
  for other in aliases {
    if !result.contains(other) {
      result.push(other)
    }
  }
  result.sort_by(String::lexical_compare)
  result
}

///|
/// Adds the glibc internal aliases to every subroutine of the program.
pub fn refine_glibc_internal_aliases(
  prog : @types.Term[@types.Program],
) -> @types.Term[@types.Program] {
  prog.map_subs(sub => {
    let existing = sub.sub_aliases()
    glibc_internal_aliases(Some(sub.sub_name()), existing).fold(init=sub, (
      sub,
      other,
    ) => if existing.contains(other) { sub } else { sub.with_sub_alias(other) })
  })
}

///|
let abi_component_registered : Ref[Bool] = Ref(false)

///|
fn available_deps(deps : Array[String]) -> Array[String] {
  deps.filter(dep => @project.find_pass(dep) is Some(_))
}

///|
/// Creates the autorun `glibc-runtime` pass. Upstream depends on the `api`
/// pass, which is kept only when it is registered.
pub fn pass(
  enable? : Bool = false,
  main_abi? : (@project.Project, @types.Term[@types.Sub]) -> @types.Term[
    @types.Sub,
  ],
) -> @project.ProjectPass {
  @project.ProjectPass::create(
    name~,
    autorun=true,
    deps=available_deps(["api"]),
    run=project => Ok(recover_main(project, enable~, main_abi?)),
  )
}

///|
/// Registers the `__libc_start_main` discovery with the ABI pass and the
/// autorun `glibc-runtime` pass. Idempotent: returns `false` if the pass was
/// already registered.
pub fn register(
  enable? : Bool = false,
  main_abi? : (@project.Project, @types.Term[@types.Sub]) -> @types.Term[
    @types.Sub,
  ],
) -> Result[Bool, String] {
  if !abi_component_registered.val {
    abi_component_registered.val = true
    @abi.register_pass(project => discover_libc_start_main(project, enable~))
  }
  @project.register_pass_if_absent(pass(enable~, main_abi?))
}

///|
/// Declares the `glibc-runtime` plugin to `bap_main` with its `enable` flag.
/// Does nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(name, provides=["abi", "api"], doc~, () => {
    let enable = @bap_main.Configuration::flag(
      doc="Override the glib detection heuristic and enable the runtime fixup.",
      "enable",
    )
    @bap_main.Extension::register(ctxt => {
      match register(enable=ctxt.get(enable)) {
        Ok(_) => ()
        Err(reason) => fail(reason)
      }
    })
  })
}
