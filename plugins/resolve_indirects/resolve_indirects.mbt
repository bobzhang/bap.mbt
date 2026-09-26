// The `resolve-indirects` pass: a port of upstream
// `plugins/resolve_indirects/resolve_indirects_main.ml`, which substitutes
// the loads from constant addresses with the contents of the memory of the
// project.
//
// Upstream bug: the plugin does not compile. Its `main` is defined as
//
//     let main =
//       Project.map_program ~f:(fun prog ->
//           let memory = Project.memory proj in ...)
//
// i.e., a partial application of `Project.map_program` whose mapping
// function refers to `proj`, which is not bound anywhere (the intended
// definition is `let main proj = Project.map_program proj ~f:...`). The
// plugin also has no `dune` file, so it was never built or registered.
// The port implements the evident intent: for every expression of every
// block of every subroutine, a load `mem[c, e]:n` whose address `c` is a
// constant is replaced with the `n`-bit word stored at `c` in the first
// memory region of the project that contains `c` (read with the
// endianness of that region, as upstream `Memory.get` does). A load that
// cannot be read (no region, or a region that ends before the word) is kept.
// As in upstream's `Bil.mapper`, the address is checked before its own
// subexpressions are resolved, so a load whose address is itself a
// constant-address load is not resolved in the same pass.

///|
/// The name of the pass.
pub let name : String = "resolve-indirects"

///|
/// Resolves the constant-address loads of `e` with `memory`.
pub fn resolve_exp(
  memory : @memory.MemMap[String],
  e : @types.Exp,
) -> @types.Exp {
  let go = (e : @types.Exp) => resolve_exp(memory, e)
  match e {
    Int(_) | Var(_) | Unknown(_) => e
    Load(mem~, addr~, endian~, typ~) => {
      let mapped = @types.Exp::Load(mem=go(mem), addr=go(addr), endian~, typ~)
      match (addr, typ) {
        (Int(a), Imm(bits)) => read(memory, a, bits).unwrap_or(mapped)
        _ => mapped
      }
    }
    Store(mem~, addr~, value~, endian~) =>
      Store(mem=go(mem), addr=go(addr), value=go(value), endian~)
    Let(v, value, body) => Let(v, go(value), go(body))
    Cast(kind~, width~, exp~) => Cast(kind~, width~, exp=go(exp))
    Extract(hi~, lo~, exp~) => Extract(hi~, lo~, exp=go(exp))
    Concat(high~, low~) => Concat(high=go(high), low=go(low))
    UnOp(op, x) => UnOp(op, go(x))
    BinOp(op, x, y) => BinOp(op, go(x), go(y))
    Ite(cond~, yes~, no~) => Ite(cond=go(cond), yes=go(yes), no=go(no))
  }
}

///|
fn read(
  memory : @memory.MemMap[String],
  addr : @types.Word,
  bits : Int,
) -> @types.Exp? {
  let addr = addr.to_uint64() catch { _ => return None }
  guard memory.find_addr(addr) is Some((mem, _)) else { return None }
  match mem.get(addr~, scale=bits) {
    Ok(w) => Some(@types.Exp::int(w))
    Err(_) => None
  }
}

///|
/// Substitutes the constant-address loads in the program of `project` with
/// the contents of the project's memory.
pub fn run(project : @project.Project) -> @project.Project {
  let memory = project.memory()
  project.map_program(prog => {
    prog.map_subs(sub => {
      sub.map_blks(blk => blk.map_exp(e => resolve_exp(memory, e)))
    })
  })
}

///|
/// The `resolve-indirects` project pass (not autorun, as upstream).
pub fn pass() -> @project.ProjectPass {
  @project.ProjectPass::create(name~, run=project => Ok(run(project)))
}

///|
/// Registers the pass. Returns `false` if it was already registered.
pub fn register() -> Result[Bool, String] {
  @project.register_pass_if_absent(pass())
}

///|
/// Declares the `resolve-indirects` plugin, which registers the pass (run
/// it with `--pass=resolve-indirects`). Upstream registers the pass when
/// the (never built) plugin is loaded. Does nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["pass", "analysis"],
    doc="substitutes loads from constant addresses with the memory contents",
    () => {
      @bap_main.Extension::register(_ => {
        match register() {
          Ok(_) => ()
          Err(e) => fail(e)
        }
      })
    },
  )
}
