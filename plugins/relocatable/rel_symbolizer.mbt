///|
/// The plugin name.
pub let name : String = "relocatable"

///|
/// The name of the stub symbolizer (the upstream knowledge agent).
pub let symbolizer_name : String = "plt-symbolizer"

///|
/// The name of the rooter that marks MIPS external references as functions.
pub let rooter_name : String = "roots-for-mips"

///|
let doc : String =
  #|Extracts symbolic information from the program relocations.
  #|
  #|The relocation symbolizer leverages the relocation information stored in
  #|files to extract symbol names. Since a relocation references an external
  #|symbol which doesn't have an address we use an address of a callsite.

///|
/// A lifted instruction: its BIL and the last address it occupies.
pub(all) struct LiftedInsn {
  bil : Array[@types.Stmt]
  max_addr : UInt64
}

///|
/// Simplifies BIL with constant folding and propagation to a fixed point.
pub fn optimize(bil : Array[@types.Stmt]) -> Array[@types.Stmt] {
  @types.fixpoint(bil, stmts => {
    @types.propagate_consts(@types.fold_consts(stmts))
  })
}

///|
/// Collects the BIL of up to `number_of_instructions` instructions starting
/// at `entry`, following unconditional constant jumps (`collect_insns`).
pub fn collect_insns(
  number_of_instructions : Int,
  entry : UInt64,
  lift : (UInt64) -> LiftedInsn?,
) -> Array[@types.Stmt] {
  let bils : Array[Array[@types.Stmt]] = []
  let mut addr = entry
  while bils.length() < number_of_instructions {
    guard lift(addr) is Some(insn) else { break }
    match insn.bil {
      [Jmp(Int(next))] =>
        try next.to_uint64() catch {
          _ => break
        } noraise {
          target => {
            bils.push(insn.bil)
            addr = target
          }
        }
      _ => {
        bils.push(insn.bil)
        addr = insn.max_addr + 1
      }
    }
  }
  optimize(bils.fold(init=[], (acc, bil) => acc + bil))
}

///|
/// The number of instructions of a PLT entry for a target.
pub fn plt_size(target : @core_theory.Target) -> Int? {
  let sizes = [
    (@core_theory.Target::arm_family(), 4),
    (@core_theory.Target::x86(), 1),
    (@core_theory.Target::powerpc_family(), 4),
  ]
  for entry in sizes {
    if !target.is_unknown() && target.belongs(entry.0) {
      return Some(entry.1)
    }
  }
  None
}

///|
fn is_intrinsic(s : String) -> Bool {
  s.has_prefix("intrinsic:")
}

///|
fn demangle(s : String) -> String {
  if s.has_suffix(":external") {
    s.unsafe_substring(start=0, end=s.length() - ":external".length())
  } else {
    s
  }
}

///|
fn word_addr(w : @types.Word) -> UInt64? {
  try w.to_uint64() catch {
    _ => None
  } noraise {
    a => Some(a)
  }
}

///|
/// References found in BIL: constant jump targets, constant loads, and calls
/// to external functions (`find_references`).
pub fn find_references(bil : Array[@types.Stmt]) -> Array[RelRef] {
  bil.filter_map(stmt => {
    match stmt {
      Jmp(Load(addr=Int(dst), ..))
      | Jmp(Int(dst))
      | Move(_, Load(addr=Int(dst), ..)) => word_addr(dst).map(a => Addr(a))
      Special(_) =>
        match @types.Stmt::decode(@types.Stmt::call(), stmt) {
          Some(dst) if !is_intrinsic(dst) => Some(Name(demangle(dst)))
          _ => None
        }
      _ => None
    }
  })
}

///|
/// Resolves the name of the stub at `addr` (`resolve_stubs`): the reference
/// at the stub address, or a reference of the first PLT instructions.
pub fn resolve_stub(
  refs : References,
  target : @core_theory.Target,
  addr : UInt64,
  lift : (UInt64) -> LiftedInsn?,
) -> String? {
  match refs.lookup(addr) {
    Some(Name(s)) => Some(s)
    _ =>
      match plt_size(target) {
        None => None
        Some(size) =>
          for item in find_references(collect_insns(size, addr, lift)) {
            match item {
              Name(s) => break Some(s)
              Addr(dst) =>
                match refs.lookup(dst) {
                  Some(Name(s)) => break Some(s)
                  _ => ()
                }
            }
          } nobreak {
            None
          }
      }
  }
}

///|
/// A symbolizer that names stubs from the relocation references.
pub fn symbolizer(
  refs : References,
  target : @core_theory.Target,
  is_stub~ : (UInt64) -> Bool,
  lift? : (UInt64) -> LiftedInsn? = _ => None,
) -> @project.ProjectSymbolizer {
  @project.ProjectSymbolizer::create(addr => {
    if is_stub(addr) {
      resolve_stub(refs, target, addr, lift)
    } else {
      None
    }
  })
}

///|
/// On MIPS targets, every well-defined external reference is a subroutine
/// start (`mark_mips_stubs_as_functions`).
pub fn mips_roots(
  refs : References,
  target : @core_theory.Target,
) -> Array[UInt64] {
  if target.is_unknown() || !target.belongs(@core_theory.Target::mips_family()) {
    return []
  }
  refs
  .to_array()
  .filter_map(entry => {
    match entry.1 {
      Ref(_) => Some(entry.0)
      Bad => None
    }
  })
}

///|
/// `true` for PLT-like stub sections.
pub fn is_stub_section(section_name : String) -> Bool {
  section_name.has_prefix(".plt") ||
  section_name == "__stubs" ||
  section_name == "__symbol_stub"
}

///|
/// The default stub predicate of a project: the address starts a subroutine
/// marked as a stub, or lies in a PLT-like section of the image.
pub fn project_is_stub(project : @project.Project) -> (UInt64) -> Bool {
  let starts : Array[UInt64] = []
  for sub in project.program().subs() {
    if sub.is_stub() {
      match sub.get_attr("address") {
        Some(text) =>
          match parse_address(text) {
            Some(a) => starts.push(a)
            None => ()
          }
        None => ()
      }
    }
  }
  let sections = match project.image() {
    Some(image) =>
      image.sections().filter(section => is_stub_section(section.name()))
    None => []
  }
  addr => starts.contains(addr) || sections.iter().any(s => s.contains(addr))
}

///|
fn parse_address(text : String) -> UInt64? {
  try @types.Word::from_string(text) catch {
    _ => None
  } noraise {
    word => word_addr(word)
  }
}

///|
/// Lifts instructions from the project disassembly with the basic lifter.
pub fn project_lift(project : @project.Project) -> (UInt64) -> LiftedInsn? {
  let state = project.disassembly()
  addr => {
    match state.instruction_at(addr) {
      None => None
      Some(insn) =>
        match insn.lift_basic_bil() {
          Ok(bil) => Some({ bil, max_addr: insn.memory().max_addr(), })
          Err(_) => Some({ bil: [], max_addr: insn.memory().max_addr(), })
        }
    }
  }
}

///|
/// Renames the stub subroutines of the project program (those with an
/// address) to the external symbols they reference.
pub fn name_stubs(
  project : @project.Project,
  is_stub? : (UInt64) -> Bool,
  lift? : (UInt64) -> LiftedInsn?,
) -> @project.Project {
  let refs = References::of_project(project)
  let target = project.target()
  let is_stub = is_stub.unwrap_or(project_is_stub(project))
  let lift = lift.unwrap_or(project_lift(project))
  project.map_program(prog => {
    prog.map_subs(sub => {
      match sub.get_attr("address").bind(parse_address) {
        Some(addr) if is_stub(addr) =>
          match resolve_stub(refs, target, addr, lift) {
            Some(resolved) => sub.with_name(resolved)
            None => sub
          }
        _ => sub
      }
    })
  })
}

///|
/// Creates the (non-autorun) `relocatable` pass that renames stubs.
pub fn pass() -> @project.ProjectPass {
  @project.ProjectPass::create(name~, run=project => Ok(name_stubs(project)))
}

///|
/// Registers the `plt-symbolizer` symbolizer and `roots-for-mips` rooter
/// sources for an image, using `lift` to analyze PLT entries.
pub fn register_sources(
  image : @image.Image,
  target? : @core_theory.Target,
  lift? : (UInt64) -> LiftedInsn?,
) -> Unit {
  let target = target.unwrap_or(
    image.target().unwrap_or(@core_theory.Target::unknown()),
  )
  let refs = References::create(target, image.spec())
  let sections = image
    .sections()
    .filter(section => is_stub_section(section.name()))
  @project.register_symbolizer_source_value(
    name=symbolizer_name,
    symbolizer(
      refs,
      target,
      is_stub=addr => sections.iter().any(s => s.contains(addr)),
      lift?,
    ),
  )
  @project.register_rooter_source_value(
    name=rooter_name,
    @project.ProjectRooter::create(mips_roots(refs, target)),
  )
}

///|
/// Registers the `relocatable` stub-naming pass. Idempotent: returns `false`
/// if it was already registered.
pub fn register() -> Result[Bool, String] {
  @project.register_pass_if_absent(pass())
}

///|
/// Declares the `relocatable` plugin to `bap_main`. Does nothing if already
/// declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(name, doc~, () => {
    @bap_main.Extension::register(_ => {
      match register() {
        Ok(_) => ()
        Err(reason) => fail(reason)
      }
    })
  })
}
