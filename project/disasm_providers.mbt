// Rooters, symbolizers and branchers as knowledge providers (upstream
// `Rooter.provide`/`providing`, `Symbolizer.provide`/`providing`/`get_name`
// and `Brancher.provide`/`providing`, `Brancher.of_bil`/`of_image`).
//
// `provide` installs the provider for good (upstream: a global promise);
// `providing` installs it while a scope evaluates. The providers answer
// only for the labels of the program units they apply to (their `path`),
// and translate the addresses between the biased (loaded) and unbiased
// (file) address spaces unless they are biased (see
// `ProjectDisassemblySourceContext`).

// Rooters.

///|
/// The promise of `Theory.Label.is_subroutine` made by the rooter.
fn ProjectRooter::promise_fn(
  self : ProjectRooter,
) -> (@knowledge.State, @knowledge.Object[Unit]) -> Bool? raise {
  let roots : Map[UInt64, Unit] = Map([])
  for root in self.roots_value {
    roots[root] = ()
  }
  let path = self.path_value
  let biased = self.biased_flag
  (kb, label) => {
    match project_label_provider_addr(kb, label, path~, biased~) {
      Some(addr) if roots.contains(addr) => Some(true)
      _ => None
    }
  }
}

///|
/// `Rooter.provide r`: every root of `r` is a subroutine start
/// (`Theory.Label.is_subroutine`) from now on.
pub fn ProjectRooter::provide(self : ProjectRooter) -> Unit {
  project_label_is_subroutine.promise(self.promise_fn()) |> ignore
}

///|
/// `Rooter.providing r f`: evaluates `f` with the roots of `r` being
/// subroutine starts.
pub fn[R] ProjectRooter::providing(
  self : ProjectRooter,
  f : () -> R raise?,
) -> R raise? {
  project_label_is_subroutine.promising(promise=self.promise_fn(), f)
}

// Symbolizers.

///|
/// The proposal of `Theory.Label.possible_name` made by the symbolizer.
fn ProjectSymbolizer::propose_fn(
  self : ProjectSymbolizer,
) -> (@knowledge.State, @knowledge.Object[Unit]) -> String? raise {
  let path = self.path_value
  let biased = self.biased_flag
  (kb, label) => {
    match project_label_provider_addr(kb, label, path~, biased~) {
      Some(addr) => self.run(addr)
      None => None
    }
  }
}

///|
/// `Symbolizer.provide agent s`: the names found by `s` are the opinions of
/// `agent` on the possible names of the program labels
/// (`Theory.Label.possible_name`) from now on.
pub fn ProjectSymbolizer::provide(
  self : ProjectSymbolizer,
  agent : @knowledge.Agent,
) -> Unit {
  project_label_possible_name.propose(agent, self.propose_fn()) |> ignore
}

///|
/// `Symbolizer.providing agent s f`: evaluates `f` with the names found by
/// `s` proposed by `agent`.
pub fn[R] ProjectSymbolizer::providing(
  self : ProjectSymbolizer,
  agent : @knowledge.Agent,
  f : () -> R raise?,
) -> R raise? {
  project_label_possible_name.proposing(agent, propose=self.propose_fn(), f)
}

///|
/// `Symbolizer.get_name addr`: the name of the program at `addr`
/// (`Theory.Label.name`), or `sub_<addr>`.
pub fn ProjectSymbolizer::get_name(
  kb : @knowledge.State,
  addr : UInt64,
) -> String raise {
  project_disasm_knowledge_init()
  let label = project_label_for_addr(kb, addr)
  match kb.collect(project_label_name, label) {
    Some(name) => name
    None => ProjectSymbolizer::name_of_addr(addr)
  }
}

///|
let project_symbolizer_agent_value : Ref[@knowledge.Agent?] = { val: None, }

///|
/// The agent proposing the names found by the project symbolizers.
pub fn ProjectSymbolizer::agent() -> @knowledge.Agent {
  match project_symbolizer_agent_value.val {
    Some(agent) => agent
    None => {
      let agent = match
        @knowledge.Agent::register(
          "project-symbolizer",
          pkg="bap",
          desc="provides the names found by the project symbolizers",
          reliability=Reliable,
        ) {
        Ok(agent) => agent
        Err(_) => @knowledge.Agent::read("project-symbolizer", pkg="bap")
      }
      project_symbolizer_agent_value.val = Some(agent)
      agent
    }
  }
}

// Branchers.

///|
/// `Brancher.create f`: a brancher resolving the destinations of the
/// instructions with `f mem insn`.
pub fn ProjectBrancher::of_resolver(
  resolve : (@memory.Memory, ProjectDisassemblyInstruction) -> Array[
    ProjectDisassemblyEdge,
  ],
) -> ProjectBrancher {
  {
    path_value: None,
    biased_value: false,
    resolve_fn: (mem, insn) => {
      match insn {
        Some(insn) => resolve(mem, insn)
        None => []
      }
    },
  }
}

///|
/// `Brancher.resolve b mem insn`: the destinations of the instruction
/// `insn` occupying `mem`.
pub fn ProjectBrancher::resolve_insn(
  self : ProjectBrancher,
  mem : @memory.Memory,
  insn : ProjectDisassemblyInstruction,
) -> Array[ProjectDisassemblyEdge] {
  (self.resolve_fn)(mem, Some(insn))
}

///|
/// The kinds of the destinations of lifted code (upstream `dests`).
priv enum ProjectBilDestKind {
  BilJump
  BilCond
  BilFall
} derive(Eq)

///|
fn project_bil_dests_kind(
  dests : Array[(UInt64?, ProjectBilDestKind)],
) -> ProjectBilDestKind {
  if dests.iter().all(dest => dest.1 == BilFall) {
    BilFall
  } else if dests.iter().any(dest => dest.1 == BilJump) {
    BilJump
  } else {
    BilCond
  }
}

///|
fn project_bil_has_jumps(bil : Array[@types.Stmt]) -> Bool {
  bil
  .iter()
  .any(stmt => {
    match stmt {
      Jmp(_) => true
      If(yes~, no~, ..) =>
        project_bil_has_jumps(yes) || project_bil_has_jumps(no)
      While(body~, ..) => project_bil_has_jumps(body)
      _ => false
    }
  })
}

///|
/// `dests_of_bil`: the destinations of the jumps of the BIL.
fn project_bil_branch_dests(
  bil : Array[@types.Stmt],
) -> Array[(UInt64?, ProjectBilDestKind)] {
  let result = []
  for stmt in bil {
    match stmt {
      Jmp(Int(word)) => result.push((project_word_addr(word), BilJump))
      Jmp(_) => result.push((None, BilJump))
      If(yes~, no~, ..) => {
        let x = project_bil_branch_dests(yes)
        let y = project_bil_branch_dests(no)
        let kind = match
          (project_bil_dests_kind(x), project_bil_dests_kind(y)) {
          (BilJump, BilJump) => BilJump
          (BilFall, BilFall) => BilFall
          _ => BilCond
        }
        for dest in x.rev() + y {
          result.push((dest.0, kind))
        }
      }
      While(body~, ..) =>
        result.push_iter(project_bil_branch_dests(body).iter())
      _ => ()
    }
  }
  result
}

///|
/// The relocation information of an image (upstream `Rel_info`): the
/// internal relocations and the external references.
priv struct ProjectRelInfo {
  rels : Map[UInt64, UInt64]
  exts : Map[UInt64, Unit]
}

///|
fn ProjectRelInfo::of_image(image : @image.Image) -> ProjectRelInfo {
  let rels : Map[UInt64, UInt64] = Map([])
  for rel in image.relocations() {
    match rel.target() {
      Some(target) => rels[rel.fixup()] = target
      None => ()
    }
  }
  let exts : Map[UInt64, Unit] = Map([])
  for ext in image.external_references() {
    exts[ext.addr()] = ()
  }
  { rels, exts, }
}

///|
/// `fixup rel_info mem target`: the destination of a jump of the
/// instruction at `mem`, corrected by the relocations of the instruction:
/// the target of an internal relocation, none for an external reference.
fn ProjectRelInfo::fixup(
  self : ProjectRelInfo,
  mem : @memory.Memory,
  target : UInt64,
) -> UInt64? {
  let span = Array::makei(mem.length(), i => mem.min_addr() + i.to_uint64())
  for addr in span {
    match self.rels.get(addr) {
      Some(dst) => return Some(dst)
      None => ()
    }
  }
  if span.iter().any(addr => self.exts.contains(addr)) {
    None
  } else {
    Some(target)
  }
}

///|
/// `dests_of_bil ?rel_info target`: the destinations of the instructions
/// derived from their lifted semantics on `target`: the jumps of the BIL
/// (corrected by the relocations), and the fallthrough, unless the
/// instruction is a return or makes an unconditional jump that is not a
/// call.
fn project_brancher_dests_of_bil(
  target : @core_theory.Target,
  rel_info : ProjectRelInfo?,
) -> (@memory.Memory, ProjectDisassemblyInstruction) -> Array[
  ProjectDisassemblyEdge,
] {
  (mem, insn) => {
    let next = mem.max_addr() + 1UL
    let dests = match insn.lift(target~) {
      Err(_) => []
      Ok(lifted) =>
        if project_bil_has_jumps(lifted.bil()) {
          project_bil_branch_dests(lifted.bil()).map(dest => {
            match (dest, rel_info) {
              ((Some(addr), BilJump), Some(info)) =>
                (info.fixup(mem, addr), BilJump)
              _ => dest
            }
          })
        } else {
          []
        }
    }
    let fall = (Some(next), BilFall)
    let dests = match project_bil_dests_kind(dests) {
      BilFall if insn.has_kind(ProjectReturn) => []
      BilJump if insn.has_kind(ProjectCall) => [fall] + dests
      BilCond | BilFall => [fall] + dests
      _ => dests
    }
    dests.map(dest => {
      ProjectDisassemblyEdge::create(
        source=mem.min_addr(),
        target?=dest.0,
        kind=match dest.1 {
          BilJump => JumpEdge
          BilCond => CondEdge
          BilFall => FallEdge
        },
      )
    })
  }
}

///|
/// `Brancher.of_bil arch`: the brancher that derives the destinations of
/// the instructions from their semantics lifted on `target`.
pub fn ProjectBrancher::of_bil(target : @core_theory.Target) -> ProjectBrancher {
  ProjectBrancher::of_resolver(project_brancher_dests_of_bil(target, None))
}

///|
/// `Brancher.of_image img`: the brancher of the image, deriving the
/// destinations of the instructions from their semantics lifted on the
/// image target, corrected by the image relocations (jumps through
/// external references have no known destination).
pub fn ProjectBrancher::of_image(image : @image.Image) -> ProjectBrancher {
  let resolve = project_brancher_dests_of_bil(
    image.arch(),
    Some(ProjectRelInfo::of_image(image)),
  )
  { ..ProjectBrancher::of_resolver(resolve), biased_value: true, }
}

///|
/// The promise of the destinations of instructions made by the brancher
/// (upstream `provide_brancher`).
fn ProjectBrancher::promise_fn(
  self : ProjectBrancher,
) -> (@knowledge.State, @knowledge.Object[Unit]) -> Array[
  @knowledge.Object[Unit],
]? raise {
  (kb, label) => {
    guard kb.collect(project_insn_memory_slot, label) is Some(mem) &&
      kb.collect(project_insn_slot, label) is Some(insn) else {
      Some([])
    }
    let context = project_label_context(kb, label)
    guard context.is_applicable(path?=self.path_value) else { Some([]) }
    let addr = match
      context.create_addr(mem.min_addr(), unbiased=!self.biased_value) {
      Ok(word) =>
        match project_word_addr(word) {
          Some(addr) => addr
          None => return Some([])
        }
      Err(_) => return Some([])
    }
    let bias = mem.min_addr() - addr
    let dests : Array[@knowledge.Object[Unit]] = []
    for edge in self.resolve_insn(mem.rebase(addr), insn) {
      match edge.target() {
        Some(dst) => dests.push(project_label_for_addr(kb, dst + bias))
        None => ()
      }
    }
    Some(project_labels_union([], dests))
  }
}

///|
/// `Brancher.provide b`: the destinations found by `b` are destinations of
/// the instructions (`Insn.Slot.dests`) from now on.
pub fn ProjectBrancher::provide(self : ProjectBrancher) -> Unit {
  project_insn_dests_slot.promise(self.promise_fn()) |> ignore
}

///|
/// `Brancher.providing b f`: evaluates `f` with the destinations found by
/// `b` being destinations of the instructions.
pub fn[R] ProjectBrancher::providing(
  self : ProjectBrancher,
  f : () -> R raise?,
) -> R raise? {
  project_insn_dests_slot.promising(promise=self.promise_fn(), f)
}
