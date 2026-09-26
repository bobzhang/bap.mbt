// The Basic disassembler machine (upstream `lib/bap_disasm/bap_disasm_basic.ml`):
// disassemblers created for a backend and a target triple, or looked up by
// encoding (Core Theory language) through the registered constructors, and
// the callback-driven `run` with its `step`/`stop`/`jump`/`back` state
// operations.
//
// The upstream machine is driven by the C disassembler: `C.run` decodes from
// the current offset until an instruction satisfies one of the stop
// predicates, an invalid instruction is met (`Is_invalid` is always pushed),
// or the memory ends (signalled by a zero-sized instruction). The port
// emulates that loop over the built-in decoders.
//
// Deviation: the continuation-passing style of `run` is kept, so every
// `step`/`jump` called from a callback nests a call. OCaml runs these in
// constant stack space; in MoonBit the stack grows with the number of
// callbacks of one run, so long sweeps should use a stop predicate that is
// rarely hit (or none, as `ProjectDisassemblyLinearSweep`), or drive
// `insn_of_mem` from a loop.

///|
/// A Basic disassembler (upstream `('a,'k) Basic.t`): the backend and the
/// target triple it decodes for, its name in the disassemblers table and the
/// name of the encoding it implements.
struct ProjectDisassemblyBasic {
  backend_value : String
  triple_value : String
  cpu_value : String
  attrs_value : String
  debug_level_value : Int
  store_asm_value : Bool
  store_kinds_value : Bool
  name_value : String
  encoding_value : String
  /// the `@mc` decoder and the decoding context, for the disassemblers of
  /// the encodings provided by the registered `@mc` decoders
  mc_value : (@mc.Decoder, @mc.Context)?
}

///|
/// The result of `insn_of_mem`: the memory of the decoded (or invalid)
/// instruction, the instruction when it is valid, and what is left.
struct ProjectDisassemblyBasicInsnResult {
  memory_value : @memory.Memory
  instruction_value : ProjectDisassemblyInstruction?
  remainder_value : ProjectDisassemblyBasicRemainder
}

///|
/// A position of the disassembler (upstream `step`): the memory being
/// disassembled, the offset of the next instruction and the stop
/// predicates.
priv struct ProjectDisassemblyBasicStep {
  mem : @memory.Memory
  off : Int
  preds : Array[ProjectDisassemblyBasicPred]
}

///|
/// The state of a running Basic disassembler (upstream
/// `('a,'k,'s,'r) Basic.state`), passed to the callbacks of `run`: `S` is
/// the type of the user data threaded through the callbacks and `R` the
/// type of the result of the run.
struct ProjectDisassemblyBasicState[S, R] {
  backlog : Int
  dis : ProjectDisassemblyBasic
  current : ProjectDisassemblyBasicStep
  history : Array[ProjectDisassemblyBasicStep]
  insns_value : Array[(@memory.Memory, ProjectDisassemblyInstruction?)]
  return_ : (S) -> R
  stopped : ((ProjectDisassemblyBasicState[S, R], S) -> R)?
  invalid : ((ProjectDisassemblyBasicState[S, R], @memory.Memory, S) -> R)?
  hit : ((
    ProjectDisassemblyBasicState[S, R],
    @memory.Memory,
    ProjectDisassemblyInstruction,
    S,
  ) -> R)?
}

///|
/// The result of decoding one instruction.
priv enum ProjectDisassemblyBasicDecoded {
  /// a valid instruction occupying the memory
  BasicDecodedValid(@memory.Memory, ProjectDisassemblyInstruction)
  /// an invalid instruction occupying the memory
  BasicDecodedInvalid(@memory.Memory)
  /// no instruction can be decoded: the memory is exhausted (upstream: a
  /// zero-sized instruction)
  BasicDecodedEnd
}

///|
/// The constructors of the disassemblers of the registered encodings
/// (upstream `constructors`), by encoding name.
let project_disassembly_basic_constructors : Map[
  String,
  (@core_theory.Target) -> Result[ProjectDisassemblyBasic, String],
] = Map([])

///|
let project_disassembly_basic_builtins_registered : Ref[Bool] = { val: false, }

///|
/// The encodings whose constructors are the built-in `llvm` ones: the
/// registered `@mc` decoders take precedence over them.
let project_disassembly_basic_builtin_encodings : Map[String, Unit] = Map([])

///|
/// The triples the built-in `llvm` backend decodes.
fn project_disassembly_basic_llvm_supports(triple : String) -> Bool {
  triple.contains("x86") ||
  triple.contains("amd64") ||
  triple.contains("i386") ||
  triple.contains("i486") ||
  triple.contains("i586") ||
  triple.contains("i686") ||
  triple.contains("arm")
}

///|
/// Registers the encodings decoded by the built-in `llvm` backend (upstream:
/// the `llvm` plugin registers its encodings on load).
fn project_disassembly_basic_register_builtins() -> Unit {
  if project_disassembly_basic_builtins_registered.val {
    return
  }
  project_disassembly_basic_builtins_registered.val = true
  let builtin = (language : @core_theory.Language, triple : String) => {
    let key = language.to_string()
    if !project_disassembly_basic_constructors.contains(key) {
      project_disassembly_basic_builtin_encodings[key] = ()
      project_disassembly_basic_constructors[key] = _ => {
        ProjectDisassemblyBasic::create(triple, backend="llvm")
      }
    }
  }
  project_disassembly_basic_builtin_encodings.clear()
  builtin(@core_theory.Language::llvm_x86(), "i386")
  builtin(@core_theory.Language::llvm_x86_64(), "x86_64")
  builtin(@core_theory.Language::llvm_a32(), "armv7")
}

///|
/// `Basic.register encoding create`: provides the constructor of the
/// disassemblers of `encoding`, used by `lookup`. It is an error to register
/// a second constructor for an encoding (the built-in `llvm` encodings
/// included).
///
/// Decoders that produce `@mc.Insn` values are better registered with
/// `@mc.register_decoder`, which `lookup` consults for the encodings
/// without a registered constructor (see `ProjectDisassemblyBasic::lookup`).
pub fn ProjectDisassemblyBasic::register(
  encoding : @core_theory.Language,
  create : (@core_theory.Target) -> Result[ProjectDisassemblyBasic, String],
) -> Result[Unit, String] {
  project_disassembly_basic_register_builtins()
  let key = encoding.to_string()
  if project_disassembly_basic_constructors.contains(key) {
    Err(
      "A disassembler backend for the encoding \{key} is already provided. Please, disable the old one before registering a new one.",
    )
  } else {
    project_disassembly_basic_constructors[key] = create
    Ok(())
  }
}

///|
/// The encodings that have a registered disassembler, sorted by name.
pub fn ProjectDisassemblyBasic::registered_encodings() -> Array[String] {
  project_disassembly_basic_register_builtins()
  let names = project_disassembly_basic_constructors.keys().collect()
  names.sort()
  names
}

///|
/// `Basic.create ?debug_level ?cpu ?attrs ?backend triple`: a disassembler
/// of the `backend` for the target `triple`. Fails for unknown backends and
/// for targets the backend cannot decode.
///
/// The backends are the registered Basic backends (the built-in `llvm`,
/// which decodes x86, x86-64 and ARM, and `raw`) and the registered `@mc`
/// decoders, named by their names: with an `@mc` decoder, `triple` names a
/// Core Theory target (see `@core_theory.Target::lookup`) whose default
/// encoding the decoder must accept. The `llvm` backend also defers to the
/// `@mc` decoders for the targets it cannot decode itself.
pub fn ProjectDisassemblyBasic::create(
  triple : String,
  backend? : String = "llvm",
  cpu? : String = "",
  attrs? : String = "",
  debug_level? : Int = 0,
) -> Result[ProjectDisassemblyBasic, String] {
  let name = [backend, triple, cpu].filter(part => part != "").join("-") + attrs
  let mc_decoder = if backend != "llvm" &&
    project_disassembly_basic_known_backend(backend) {
    None
  } else {
    @mc.decoders().iter().find_first(decoder => decoder.name() == backend)
  }
  let from_mc = (decoder : @mc.Decoder?) => {
    guard @core_theory.Target::lookup(triple) is Some(target) else {
      return None
    }
    let ctx = @mc.Context::create(target, encoding=@mc.default_encoding(target))
    let decoder = match decoder {
      Some(decoder) => if decoder.accepts(ctx) { Some(decoder) } else { None }
      None => @mc.find_decoder(ctx)
    }
    decoder.map(decoder => {
      let dis : ProjectDisassemblyBasic = {
        backend_value: decoder.name(),
        triple_value: triple,
        cpu_value: cpu,
        attrs_value: attrs,
        debug_level_value: debug_level,
        store_asm_value: false,
        store_kinds_value: false,
        name_value: name,
        encoding_value: name,
        mc_value: Some((decoder, ctx)),
      }
      dis
    })
  }
  match mc_decoder {
    Some(decoder) =>
      return match from_mc(Some(decoder)) {
        Some(dis) => Ok(dis)
        None => Err("Unsupported target: \{triple} \{cpu}")
      }
    None => ()
  }
  if !project_disassembly_basic_known_backend(backend) {
    return Err("Unknown backend: \{backend}")
  }
  if backend == "llvm" && !project_disassembly_basic_llvm_supports(triple) {
    return match from_mc(None) {
      Some(dis) => Ok(dis)
      None => Err("Unsupported target: \{triple} \{cpu}")
    }
  }
  Ok({
    backend_value: backend,
    triple_value: triple,
    cpu_value: cpu,
    attrs_value: attrs,
    debug_level_value: debug_level,
    store_asm_value: false,
    store_kinds_value: false,
    name_value: name,
    encoding_value: name,
    mc_value: None,
  })
}

///|
/// The name of a disassembler of `encoding` for `target` (upstream
/// `make_name`).
fn project_disassembly_basic_make_name(
  target : @core_theory.Target,
  encoding : @core_theory.Language,
) -> String {
  "\{encoding.to_string()}-\{target.to_string()}"
}

///|
/// `Basic.lookup target encoding`: the disassembler of `encoding` for
/// `target`. The disassembler is made by the constructor registered for the
/// encoding with `ProjectDisassemblyBasic::register`; otherwise it decodes
/// with the first `@mc` decoder accepting the context (`target`, `encoding`)
/// (see `@mc.register_decoder`); otherwise with the built-in `llvm` decoder
/// of the encoding (x86, x86-64 and ARM).
pub fn ProjectDisassemblyBasic::lookup(
  target : @core_theory.Target,
  encoding : @core_theory.Language,
) -> Result[ProjectDisassemblyBasic, String] {
  project_disassembly_basic_register_builtins()
  let key = encoding.to_string()
  let finish = (dis : ProjectDisassemblyBasic) => {
    ..dis,
    name_value: project_disassembly_basic_make_name(target, encoding),
    encoding_value: encoding.name().unqualified(),
  }
  if project_disassembly_basic_constructors.get(key) is Some(create) &&
    !project_disassembly_basic_builtin_encodings.contains(key) {
    return create(target).map(finish)
  }
  let ctx = @mc.Context::create(target, encoding~)
  match @mc.find_decoder(ctx) {
    Some(decoder) =>
      Ok(
        finish({
          backend_value: decoder.name(),
          triple_value: target.to_string() + "-" + key,
          cpu_value: "",
          attrs_value: "",
          debug_level_value: 0,
          store_asm_value: false,
          store_kinds_value: false,
          name_value: "",
          encoding_value: "",
          mc_value: Some((decoder, ctx)),
        }),
      )
    None =>
      match project_disassembly_basic_constructors.get(key) {
        Some(create) => create(target).map(finish)
        None => Err("no disassembler for encoding \{key}")
      }
  }
}

///|
/// `Basic.custom target encoding backend`: a disassembler of `encoding` for
/// `target` implemented by the (registered) `backend`.
pub fn ProjectDisassemblyBasic::custom(
  target : @core_theory.Target,
  encoding : @core_theory.Language,
  backend? : String = "raw",
) -> ProjectDisassemblyBasic {
  {
    backend_value: backend,
    triple_value: target.to_string() + "-" + encoding.to_string(),
    cpu_value: "",
    attrs_value: "",
    debug_level_value: 0,
    store_asm_value: false,
    store_kinds_value: false,
    name_value: project_disassembly_basic_make_name(target, encoding),
    encoding_value: encoding.name().unqualified(),
    mc_value: None,
  }
}

///|
/// `Basic.with_disasm ?backend triple ~f`: applies `f` to a disassembler
/// created with `create`.
pub fn[A] ProjectDisassemblyBasic::with_disasm(
  triple : String,
  backend? : String = "llvm",
  f : (ProjectDisassemblyBasic) -> Result[A, String],
) -> Result[A, String] {
  match ProjectDisassemblyBasic::create(triple, backend~) {
    Ok(disasm) => {
      let result = f(disasm)
      disasm.close()
      result
    }
    Err(reason) => Err(reason)
  }
}

///|
/// The name of the disassembler (for `create`d ones, the backend, triple
/// and cpu, dash-separated, followed by the attributes).
pub fn ProjectDisassemblyBasic::name(self : ProjectDisassemblyBasic) -> String {
  self.name_value
}

///|
/// The name of the encoding implemented by the disassembler (upstream
/// `Insn.encoding` of its instructions): the unqualified name of the
/// encoding it was looked up for, or its name.
pub fn ProjectDisassemblyBasic::encoding(
  self : ProjectDisassemblyBasic,
) -> String {
  self.encoding_value
}

///|
/// The memory of the invalid instruction at the start of `memory`: one
/// byte, four for ARM (the LLVM ARM disassembler consumes a whole word).
/// `None` when not enough bytes remain.
fn ProjectDisassemblyBasic::project_disassembly_basic_invalid(
  self : ProjectDisassemblyBasic,
  memory : @memory.Memory,
) -> Result[ProjectDisassemblyBasicDecoded, String] {
  let words = if self.project_disassembly_basic_is_arm_llvm() { 4 } else { 1 }
  if memory.length() < words {
    Ok(BasicDecodedEnd)
  } else {
    match memory.view(words~) {
      Ok(chunk) => Ok(BasicDecodedInvalid(chunk))
      Err(reason) => Err(reason)
    }
  }
}

///|
fn project_disassembly_basic_valid(
  instruction : ProjectDisassemblyInstruction,
) -> ProjectDisassemblyBasicDecoded {
  BasicDecodedValid(instruction.memory(), instruction)
}

///|
/// Decodes the instruction at the start of `memory`. The built-in `llvm`
/// backend reports the bytes it cannot decode as invalid instructions; the
/// other backends (such as `raw`) decode every byte as a `.byte` pseudo
/// instruction.
fn ProjectDisassemblyBasic::project_disassembly_basic_decode(
  self : ProjectDisassemblyBasic,
  memory : @memory.Memory,
) -> Result[ProjectDisassemblyBasicDecoded, String] {
  if memory.length() == 0 {
    return Ok(BasicDecodedEnd)
  }
  if self.mc_value is Some((decoder, ctx)) {
    return project_disassembly_basic_decode_mc(decoder, ctx, memory)
  }
  let decoded = if self.project_disassembly_basic_is_x86_64_llvm() {
    match project_disassembly_basic_x86_jcxz_instruction(memory, 64) {
      Ok(Some(instruction)) => Ok(Some(instruction))
      Ok(None) =>
        match project_disassembly_basic_decode_x86_64_llvm(memory) {
          Ok(Some(instruction)) => Ok(Some(instruction))
          Ok(None) =>
            match project_disassembly_basic_decode_x86_llvm(memory) {
              Ok(Some(instruction)) if !project_disassembly_basic_x86_short_incdec(
                  instruction,
                ) => Ok(Some(instruction))
              Ok(_) => Ok(None)
              Err(reason) => Err(reason)
            }
          Err(reason) => Err(reason)
        }
      Err(reason) => Err(reason)
    }
  } else if self.project_disassembly_basic_is_x86_llvm() {
    project_disassembly_basic_decode_x86_llvm(memory)
  } else if self.project_disassembly_basic_is_arm_llvm() {
    project_disassembly_basic_decode_arm_llvm(memory)
  } else if self.backend_value == "llvm" {
    Ok(None)
  } else {
    return match memory.view(words=1) {
      Ok(chunk) =>
        Ok(project_disassembly_basic_valid(project_raw_byte_instruction(chunk)))
      Err(reason) => Err(reason)
    }
  }
  match decoded {
    Ok(Some(instruction)) => Ok(project_disassembly_basic_valid(instruction))
    Ok(None) => self.project_disassembly_basic_invalid(memory)
    Err(reason) => Err(reason)
  }
}

///|
fn project_disassembly_basic_satisfies(
  instruction : ProjectDisassemblyInstruction,
  preds : Array[ProjectDisassemblyBasicPred],
) -> Bool {
  preds.any(pred => {
    match pred {
      BasicValid => true
      BasicKind(kind) => instruction.has_kind(kind)
    }
  })
}

///|
/// What stopped one round of decoding (upstream: the last instruction of
/// `C.run`).
priv enum ProjectDisassemblyBasicOutcome {
  BasicOutcomeEnd
  BasicOutcomeInvalid(@memory.Memory)
  BasicOutcomeHit(@memory.Memory, ProjectDisassemblyInstruction)
}

///|
/// Pushes the current position to the history (keeping `backlog` entries)
/// and moves to `current` (upstream `update_state`).
fn[S, R] ProjectDisassemblyBasicState::update(
  self : ProjectDisassemblyBasicState[S, R],
  current : ProjectDisassemblyBasicStep,
) -> ProjectDisassemblyBasicState[S, R] {
  let history = [self.current] + self.history
  let history = if history.length() > self.backlog {
    history[:self.backlog].to_owned()
  } else {
    history
  }
  { ..self, history, current, }
}

///|
/// Decodes from the current position until an instruction satisfies a stop
/// predicate, an invalid instruction is met, or the memory ends (upstream
/// `C.run`), appending the decoded instructions to `insns`.
fn[S, R] ProjectDisassemblyBasicState::decode_round(
  self : ProjectDisassemblyBasicState[S, R],
  insns : Array[(@memory.Memory, ProjectDisassemblyInstruction?)],
) -> (Int, ProjectDisassemblyBasicOutcome) {
  let mem = self.current.mem
  let length = mem.length()
  for off = self.current.off {
    if off >= length {
      break (off, BasicOutcomeEnd)
    }
    let decoded = match mem.view(from=mem.min_addr() + off.to_uint64()) {
      Ok(rest) =>
        match self.dis.project_disassembly_basic_decode(rest) {
          Ok(decoded) => decoded
          Err(_) => BasicDecodedEnd
        }
      Err(_) => BasicDecodedEnd
    }
    match decoded {
      BasicDecodedEnd => break (off, BasicOutcomeEnd)
      BasicDecodedInvalid(chunk) => {
        insns.push((chunk, None))
        break (off + chunk.length(), BasicOutcomeInvalid(chunk))
      }
      BasicDecodedValid(chunk, insn) => {
        insns.push((chunk, Some(insn)))
        let next = off + chunk.length()
        if project_disassembly_basic_satisfies(insn, self.current.preds) {
          break (next, BasicOutcomeHit(chunk, insn))
        }
        continue next
      }
    }
  } nobreak {
    (length, BasicOutcomeEnd)
  }
}

///|
/// `Basic.step s data`: continues the disassembly from the current position
/// and calls the `hit` callback on the next instruction satisfying a stop
/// predicate, the `invalid` callback on the next invalid instruction, or the
/// `stopped` callback when the memory ends. Without a callback, `return` is
/// applied to `data` (or, for invalid instructions, the disassembly goes on).
pub fn[S, R] ProjectDisassemblyBasicState::step(
  self : ProjectDisassemblyBasicState[S, R],
  data : S,
) -> R {
  let insns : Array[(@memory.Memory, ProjectDisassemblyInstruction?)] = []
  for s = self {
    let (off, outcome) = s.decode_round(insns)
    let s = { ..s.update({ ..s.current, off, }), insns_value: insns.copy(), }
    match outcome {
      BasicOutcomeEnd =>
        break match s.stopped {
          Some(f) => f(s, data)
          None => (s.return_)(data)
        }
      BasicOutcomeInvalid(mem) =>
        match s.invalid {
          Some(f) => break f(s, mem, data)
          None => continue s
        }
      BasicOutcomeHit(mem, insn) =>
        break match s.hit {
          Some(f) => f(s, mem, insn, data)
          None => (s.return_)(data)
        }
    }
  }
}

///|
/// `Basic.jump s mem data`: continues the disassembly from the start of
/// `mem`.
pub fn[S, R] ProjectDisassemblyBasicState::jump(
  self : ProjectDisassemblyBasicState[S, R],
  mem : @memory.Memory,
  data : S,
) -> R {
  { ..self, current: { ..self.current, mem, off: 0, }, }.step(data)
}

///|
/// `Basic.stop s data`: stops the disassembly with `data`.
pub fn[S, R] ProjectDisassemblyBasicState::stop(
  self : ProjectDisassemblyBasicState[S, R],
  data : S,
) -> R {
  (self.return_)(data)
}

///|
/// `Basic.back s data`: continues the disassembly from the previous
/// position kept in the history (see the `backlog` of `run`), or from the
/// current one when the history is empty.
pub fn[S, R] ProjectDisassemblyBasicState::back(
  self : ProjectDisassemblyBasicState[S, R],
  data : S,
) -> R {
  match self.history {
    [] => self.step(data)
    [previous, .. rest] =>
      { ..self, current: previous, history: rest.to_owned(), }.step(data)
  }
}

///|
/// `Basic.run ?backlog ?stop_on ?invalid ?stopped ?hit dis ~return ~init
/// mem`: disassembles `mem` from its start, calling `hit` on every
/// instruction satisfying one of the `stop_on` predicates, `invalid` on
/// every invalid instruction and `stopped` when the memory ends. The
/// callbacks continue the disassembly with the state operations (`step`,
/// `jump`, `back`) or finish it with `stop`. `backlog` is the number of
/// previous positions kept for `back`.
pub fn[S, R] ProjectDisassemblyBasic::run(
  self : ProjectDisassemblyBasic,
  mem : @memory.Memory,
  return_~ : (S) -> R,
  init~ : S,
  backlog? : Int = 0,
  stop_on? : Array[ProjectDisassemblyBasicPred] = [],
  invalid? : (ProjectDisassemblyBasicState[S, R], @memory.Memory, S) -> R,
  stopped? : (ProjectDisassemblyBasicState[S, R], S) -> R,
  hit? : (
    ProjectDisassemblyBasicState[S, R],
    @memory.Memory,
    ProjectDisassemblyInstruction,
    S,
  ) -> R,
) -> R {
  let state : ProjectDisassemblyBasicState[S, R] = {
    backlog,
    dis: self,
    current: { mem, off: 0, preds: [], },
    history: [],
    insns_value: [],
    return_,
    stopped,
    invalid,
    hit,
  }
  state.with_preds(stop_on).jump(mem, init)
}

///|
/// `Basic.insn_of_mem dis mem`: the first instruction of `mem` (`None` if
/// it is invalid), its memory, and what is left of `mem` after it.
pub fn ProjectDisassemblyBasic::insn_of_mem(
  self : ProjectDisassemblyBasic,
  mem : @memory.Memory,
) -> Result[ProjectDisassemblyBasicInsnResult, String] {
  let split = (chunk : @memory.Memory) => {
    if chunk.max_addr() == mem.max_addr() {
      Ok(BasicFinished)
    } else {
      mem.view(from=chunk.max_addr() + 1UL).map(left => BasicLeft(left))
    }
  }
  let result = (chunk : @memory.Memory, insn : ProjectDisassemblyInstruction?) => {
    split(chunk).map(remainder => {
      memory_value: chunk,
      instruction_value: insn,
      remainder_value: remainder,
    })
  }
  if mem.length() == 0 {
    return Ok(ProjectDisassemblyBasicInsnResult::create(mem, BasicFinished))
  }
  self.run(
    mem,
    stop_on=[BasicValid],
    return_=r => r,
    init=Ok(ProjectDisassemblyBasicInsnResult::create(mem, BasicLeft(mem))),
    hit=(s, chunk, insn, _) => s.stop(result(chunk, Some(insn))),
    invalid=(s, chunk, _) => s.stop(result(chunk, None)),
  )
}

///|
pub fn ProjectDisassemblyBasicInsnResult::create(
  memory : @memory.Memory,
  instruction? : ProjectDisassemblyInstruction,
  remainder : ProjectDisassemblyBasicRemainder,
) -> ProjectDisassemblyBasicInsnResult {
  {
    memory_value: memory,
    instruction_value: instruction,
    remainder_value: remainder,
  }
}

///|
pub fn ProjectDisassemblyBasicInsnResult::memory(
  self : ProjectDisassemblyBasicInsnResult,
) -> @memory.Memory {
  self.memory_value
}

///|
pub fn ProjectDisassemblyBasicInsnResult::instruction(
  self : ProjectDisassemblyBasicInsnResult,
) -> ProjectDisassemblyInstruction? {
  self.instruction_value
}

///|
pub fn ProjectDisassemblyBasicInsnResult::remainder(
  self : ProjectDisassemblyBasicInsnResult,
) -> ProjectDisassemblyBasicRemainder {
  self.remainder_value
}

///|
/// The disassembler of the state.
pub fn[S, R] ProjectDisassemblyBasicState::disasm(
  self : ProjectDisassemblyBasicState[S, R],
) -> ProjectDisassemblyBasic {
  self.dis
}

///|
/// `Basic.addr s`: the address of the current position.
pub fn[S, R] ProjectDisassemblyBasicState::addr(
  self : ProjectDisassemblyBasicState[S, R],
) -> UInt64 {
  self.current.mem.min_addr() + self.current.off.to_uint64()
}

///|
/// `Basic.preds s`: the stop predicates.
pub fn[S, R] ProjectDisassemblyBasicState::preds(
  self : ProjectDisassemblyBasicState[S, R],
) -> Array[ProjectDisassemblyBasicPred] {
  self.current.preds.copy()
}

///|
/// `Basic.with_preds s preds`: the state with the stop predicates `preds`
/// (a set: duplicates are dropped).
pub fn[S, R] ProjectDisassemblyBasicState::with_preds(
  self : ProjectDisassemblyBasicState[S, R],
  preds : Array[ProjectDisassemblyBasicPred],
) -> ProjectDisassemblyBasicState[S, R] {
  let set : Array[ProjectDisassemblyBasicPred] = []
  for pred in preds {
    if !set.contains(pred) {
      set.push(pred)
    }
  }
  { ..self, current: { ..self.current, preds: set, }, }
}

///|
/// `Basic.insns s`: the instructions decoded since the last step, in
/// order, with `None` for the invalid ones.
pub fn[S, R] ProjectDisassemblyBasicState::insns(
  self : ProjectDisassemblyBasicState[S, R],
) -> Array[(@memory.Memory, ProjectDisassemblyInstruction?)] {
  self.insns_value.copy()
}

///|
/// `Basic.last s n`: the last `n` instructions of `insns`, the most recent
/// first.
pub fn[S, R] ProjectDisassemblyBasicState::last(
  self : ProjectDisassemblyBasicState[S, R],
  count : Int,
) -> Array[(@memory.Memory, ProjectDisassemblyInstruction?)] {
  let m = self.insns_value.length()
  let n = if count < m { count } else { m }
  Array::makei(n, i => self.insns_value[m - i - 1])
}

///|
/// `Basic.memory s`: the memory being disassembled.
pub fn[S, R] ProjectDisassemblyBasicState::memory(
  self : ProjectDisassemblyBasicState[S, R],
) -> @memory.Memory {
  self.current.mem
}

///|
/// `Basic.switch s dis`: continues with the disassembler `dis`.
pub fn[S, R] ProjectDisassemblyBasicState::switch(
  self : ProjectDisassemblyBasicState[S, R],
  disasm : ProjectDisassemblyBasic,
) -> ProjectDisassemblyBasicState[S, R] {
  { ..self, dis: disasm, }
}

///|
/// The Basic disassembler of `backend` for `target`: for `llvm`, the
/// disassembler of the target's default encoding (`@mc.default_encoding`,
/// upstream the `Theory.Label.encoding` provided by the target plugins),
/// otherwise a disassembler of the backend for the target triple.
fn project_disassembly_basic_for_target(
  target : @core_theory.Target,
  backend : String,
) -> Result[ProjectDisassemblyBasic, String] {
  if backend == "llvm" {
    ProjectDisassemblyBasic::lookup(target, @mc.default_encoding(target))
  } else {
    ProjectDisassemblyBasic::create(target.to_string(), backend~)
  }
}

///|
/// The longest instruction the `@mc` decoders are given the bytes of.
const PROJECT_DISASSEMBLY_BASIC_MC_WINDOW : Int = 16

///|
/// Decodes the instruction at the start of `memory` with the `@mc`
/// decoder.
fn project_disassembly_basic_decode_mc(
  decoder : @mc.Decoder,
  ctx : @mc.Context,
  memory : @memory.Memory,
) -> Result[ProjectDisassemblyBasicDecoded, String] {
  let window = if memory.length() < PROJECT_DISASSEMBLY_BASIC_MC_WINDOW {
    memory.length()
  } else {
    PROJECT_DISASSEMBLY_BASIC_MC_WINDOW
  }
  let bytes = match memory.view(words=window) {
    Ok(view) => view.to_bytes()
    Err(reason) => return Err(reason)
  }
  let chunk = (size : Int) => {
    if size <= 0 || size > memory.length() {
      Ok(None)
    } else {
      memory.view(words=size).map(chunk => Some(chunk))
    }
  }
  match decoder.decode(ctx, bytes[:], memory.min_addr()) {
    Truncated => Ok(BasicDecodedEnd)
    Invalid(size~) =>
      chunk(size).map(chunk => {
        match chunk {
          Some(chunk) => BasicDecodedInvalid(chunk)
          None => BasicDecodedEnd
        }
      })
    Decoded(insn) =>
      chunk(insn.size()).map(chunk => {
        match chunk {
          Some(chunk) =>
            BasicDecodedValid(
              chunk,
              ProjectDisassemblyInstruction::of_mc_insn(insn, chunk),
            )
          None => BasicDecodedEnd
        }
      })
  }
}
