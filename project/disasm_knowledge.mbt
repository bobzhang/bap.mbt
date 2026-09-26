// The knowledge the disassembler keeps about program labels (upstream: the
// `Theory.Label` properties and the instruction slots `Memory.slot`,
// `Disasm_expert.Basic.Insn.slot`, `Insn.Slot.dests` and `Insn.Slot.delay`).
//
// Program labels are the objects of the Core Theory program class
// (`@core_theory.Label::cls()`). The Core Theory label properties are
// declared once here, so that the promises of the disassembler, of the
// rooters, symbolizers and branchers, and the facts collected by the driver
// all refer to the same slots.
//
// Deviation: upstream keeps the destinations and the delay of an
// instruction in its `Theory.Semantics` value; the port keeps them in
// dedicated label properties (`project_insn_dests_slot` and
// `project_insn_delay_slot`), leaving the Core Theory semantics alone.

///|
let project_label_cls : @knowledge.Class[Unit, Unit] = @core_theory.Label::cls()

///|
/// `Theory.Label.addr`.
let project_label_addr : @knowledge.Slot[Unit, @types.Word?] = @core_theory.Label::addr_slot()

///|
/// `Theory.Label.is_valid`.
let project_label_is_valid : @knowledge.Slot[Unit, Bool?] = @core_theory.Label::is_valid_slot()

///|
/// `Theory.Label.is_subroutine`.
let project_label_is_subroutine : @knowledge.Slot[Unit, Bool?] = @core_theory.Label::is_subroutine_slot()

///|
/// `Theory.Label.encoding`.
let project_label_encoding : @knowledge.Slot[Unit, @core_theory.Language] = @core_theory.Label::encoding_slot()

///|
/// `Theory.Label.unit`.
let project_label_unit : @knowledge.Slot[Unit, @core_theory.ProgramUnit?] = @core_theory.Label::unit_slot()

///|
/// `Theory.Label.name`.
let project_label_name : @knowledge.Slot[Unit, String?] = @core_theory.Label::name_slot()

///|
/// `Theory.Label.possible_name`.
let project_label_possible_name : @knowledge.Slot[
  Unit,
  @knowledge.Opinions[String?],
] = @core_theory.Label::possible_name_slot()

///|
fn project_disasm_name(text : String) -> @knowledge.Name {
  @knowledge.Name::create(text, pkg="bap")
}

///|
/// The memory occupied by the instruction of a label (upstream
/// `Memory.slot`).
let project_insn_memory_slot : @knowledge.Slot[Unit, @memory.Memory?] = project_label_cls.property(
  name=project_disasm_name("mem"),
  domain=@knowledge.Domain::optional(
    @knowledge.Domain::new(
      name=project_disasm_name("mem"),
      empty=None,
      is_empty=_ => false,
      order=(lhs, rhs) => {
        if project_memory_equal(lhs, rhs) {
          Equal
        } else {
          Incomparable
        }
      },
      join=(lhs, rhs) => {
        if project_memory_equal(lhs, rhs) {
          Ok(rhs)
        } else {
          Err("conflicting instruction memory")
        }
      },
      inspect=mem => mem.to_string(),
    ),
  ),
  desc="the memory occupied by the instruction",
)

///|
fn project_insn_same(
  lhs : ProjectDisassemblyInstruction,
  rhs : ProjectDisassemblyInstruction,
) -> Bool {
  lhs.name() == rhs.name() &&
  lhs.code() == rhs.code() &&
  project_memory_equal(lhs.memory(), rhs.memory())
}

///|
/// The instruction decoded at a label (upstream
/// `Disasm_expert.Basic.Insn.slot`).
let project_insn_slot : @knowledge.Slot[Unit, ProjectDisassemblyInstruction?] = project_label_cls.property(
  name=project_disasm_name("insn"),
  domain=@knowledge.Domain::optional(
    @knowledge.Domain::new(
      name=project_disasm_name("insn"),
      empty=None,
      is_empty=_ => false,
      order=(lhs, rhs) => {
        if project_insn_same(lhs, rhs) {
          Equal
        } else {
          Incomparable
        }
      },
      join=(lhs, rhs) => {
        if project_insn_same(lhs, rhs) {
          Ok(rhs)
        } else {
          Err("conflicting instructions")
        }
      },
      inspect=insn => insn.assembly(),
    ),
  ),
  desc="the instruction decoded at the label",
)

///|
fn project_labels_subset(
  lhs : Array[@knowledge.Object[Unit]],
  rhs : Array[@knowledge.Object[Unit]],
) -> Bool {
  lhs.iter().all(label => rhs.contains(label))
}

///|
fn project_labels_union(
  lhs : Array[@knowledge.Object[Unit]],
  rhs : Array[@knowledge.Object[Unit]],
) -> Array[@knowledge.Object[Unit]] {
  let result = lhs.copy()
  for label in rhs {
    if !result.contains(label) {
      result.push(label)
    }
  }
  result.sort()
  result
}

///|
/// The destinations of the instruction of a label (upstream
/// `Insn.Slot.dests`): `None` for an instruction that does not transfer
/// control, `Some(labels)` for the labels it may transfer control to (the
/// null label stands for an unknown, indirect, destination). The empty value
/// is `Some([])`: nothing is known; destinations are joined by union, and it
/// is a conflict to know both that an instruction jumps and that it does
/// not.
let project_insn_dests_slot : @knowledge.Slot[
  Unit,
  Array[@knowledge.Object[Unit]]?,
] = project_label_cls.property(
  name=project_disasm_name("insn-dests"),
  domain=@knowledge.Domain::new(
    name=project_disasm_name("insn-dests"),
    empty=Some(Some([])),
    is_empty=dests => dests is Some([]),
    order=(lhs, rhs) => {
      match (lhs, rhs) {
        (Some([]), Some([])) => Equal
        (Some([]), _) => Less
        (_, Some([])) => Greater
        (None, None) => Equal
        (None, _) | (_, None) => Incomparable
        (Some(x), Some(y)) =>
          match (project_labels_subset(x, y), project_labels_subset(y, x)) {
            (true, true) => Equal
            (true, false) => Less
            (false, true) => Greater
            (false, false) => Incomparable
          }
      }
    },
    join=(lhs, rhs) => {
      match (lhs, rhs) {
        (None, None) => Ok(None)
        (None, Some(x)) | (Some(x), None) =>
          if x.is_empty() {
            Ok(None)
          } else {
            Err("Jump_vs_Move")
          }
        (Some(x), Some(y)) => Ok(Some(project_labels_union(x, y)))
      }
    },
    inspect=dests => {
      match dests {
        None => "none"
        Some(labels) => "(\{labels.map(label => label.repr()).join(" ")})"
      }
    },
  ),
  desc="the destinations of the instruction",
)

///|
/// The length of the delay slot of the instruction of a label (upstream
/// `Insn.Slot.delay`).
let project_insn_delay_slot : @knowledge.Slot[Unit, Int?] = project_label_cls.property(
  name=project_disasm_name("insn-delay"),
  domain=@knowledge.Domain::optional(
    @knowledge.Domain::flat(project_disasm_name("insn-delay"), value => {
      value.to_string()
    }),
  ),
  desc="the length of the delay slot",
)

///|
/// The lifted semantics of the instruction of a label (the BIL and the
/// delay provided by the lifters), from which the default destinations and
/// delay are derived.
let project_insn_lifted_slot : @knowledge.Slot[Unit, @mc.Lifted?] = project_label_cls.property(
  name=project_disasm_name("insn-lifted"),
  domain=@knowledge.Domain::optional(
    @knowledge.Domain::new(
      name=project_disasm_name("insn-lifted"),
      empty=None,
      is_empty=_ => false,
      order=(lhs, rhs) => if lhs == rhs { Equal } else { Incomparable },
      join=(lhs, rhs) => {
        if lhs == rhs {
          Ok(rhs)
        } else {
          Err("conflicting instruction semantics")
        }
      },
      inspect=lifted => lifted.bil().map(stmt => stmt.to_string()).join("; "),
    ),
  ),
  desc="the lifted semantics of the instruction",
)

///|
/// The width of the label addresses.
const PROJECT_LABEL_ADDR_WIDTH : Int = 64

///|
fn project_label_word(addr : UInt64) -> @types.Word {
  @types.Word::of_uint64(width=PROJECT_LABEL_ADDR_WIDTH, addr) catch {
    _ => panic()
  }
}

///|
fn project_word_addr(word : @types.Word) -> UInt64? {
  try word.to_uint64() catch {
    _ => None
  } noraise {
    addr => Some(addr)
  }
}

///|
/// `Theory.Label.for_addr addr`: the label of the program at `addr`.
fn project_label_for_addr(
  kb : @knowledge.State,
  addr : UInt64,
) -> @knowledge.Object[Unit] raise {
  let label = kb.intern_named(
    project_label_cls,
    "0x" + addr.to_string(radix=16),
  )
  kb.provide(project_label_addr, label, Some(project_label_word(addr)))
  label
}

///|
/// `Theory.Label.for_name name`: the label of the program named `name`.
fn project_label_for_name(
  kb : @knowledge.State,
  name : String,
) -> @knowledge.Object[Unit] raise {
  let label = kb.intern_named(project_label_cls, name)
  kb.provide(project_label_name, label, Some(name))
  label
}

///|
/// The address of `label`, if known.
fn project_label_addr_of(
  kb : @knowledge.State,
  label : @knowledge.Object[Unit],
) -> UInt64? raise {
  match kb.collect(project_label_addr, label) {
    Some(word) => project_word_addr(word)
    None => None
  }
}

///|
/// `Theory.Label.target label`: the target of the unit of the label.
fn project_label_target(
  kb : @knowledge.State,
  label : @knowledge.Object[Unit],
) -> @core_theory.Target raise {
  match kb.collect(project_label_unit, label) {
    Some(unit) => unit.target()
    None => @core_theory.Target::unknown()
  }
}

///|
/// The source context of a label (upstream `Source.Context.for_label`): the
/// path and bias of its unit.
fn project_label_context(
  kb : @knowledge.State,
  label : @knowledge.Object[Unit],
) -> ProjectDisassemblySourceContext raise {
  let result = match kb.collect(project_label_unit, label) {
    Some(unit) => ProjectDisassemblySourceContext::for_unit(unit)
    None => ProjectDisassemblySourceContext::create()
  }
  match result {
    Ok(context) => context
    Err(reason) => raise @knowledge.Failure(reason)
  }
}

///|
/// The address of `label` in the address space of a provider with the
/// `path` and bias assumption `biased` (upstream `Context.create_addr
/// ~unbiased:(not biased)`), or `None` when the label has no address or the
/// provider does not apply to the label.
fn project_label_provider_addr(
  kb : @knowledge.State,
  label : @knowledge.Object[Unit],
  path~ : String?,
  biased~ : Bool,
) -> UInt64? raise {
  guard kb.collect(project_label_addr, label) is Some(word) else { None }
  let context = project_label_context(kb, label)
  guard context.is_applicable(path?) else { None }
  match context.create_word_addr(word, unbiased=!biased) {
    Ok(addr) => project_word_addr(addr)
    Err(_) => None
  }
}

///|
/// The destinations of lifted code (upstream: the destinations computed by
/// the BIL semantics): the constant jumps, the unknown destination (the
/// null label) of the other jumps, and the functions named by the `call`
/// specials. A `call` or `goto` special immediately followed by a jump is
/// the Basic lifter hint classifying the jump (see `@types` BIR lifting),
/// not a call of its own.
fn project_bil_dests(
  kb : @knowledge.State,
  bil : Array[@types.Stmt],
  dests : Array[@knowledge.Object[Unit]],
) -> Unit raise {
  for i, stmt in bil {
    match stmt {
      Jmp(Int(word)) =>
        match project_word_addr(word) {
          Some(addr) => dests.push(project_label_for_addr(kb, addr))
          None => dests.push(@knowledge.Object::null(project_label_cls))
        }
      Jmp(_) => dests.push(@knowledge.Object::null(project_label_cls))
      If(yes~, no~, ..) => {
        project_bil_dests(kb, yes, dests)
        project_bil_dests(kb, no, dests)
      }
      While(body~, ..) => project_bil_dests(kb, body, dests)
      Special(_) if !(bil.get(i + 1) is Some(Jmp(_))) =>
        match @types.Stmt::decode(@types.Stmt::call(), stmt) {
          Some(name) => dests.push(project_label_for_name(kb, name))
          None => ()
        }
      _ => ()
    }
  }
}

///|
let project_disasm_knowledge_ready : Ref[Bool] = { val: false, }

///|
/// Installs the rules the disassembler relies on (upstream: provided by the
/// Core Theory, the target plugins and the BIL lifter plugin):
///
/// - the encoding of a label is the default encoding of the target of its
///   unit (`@mc.default_encoding`);
/// - the name of a label is the most trusted of its possible names;
/// - the semantics of an instruction is its lifting on the target of its
///   unit, through the built-in lifters, and its destinations and delay are
///   derived from it.
fn project_disasm_knowledge_init() -> Unit {
  if project_disasm_knowledge_ready.val {
    return
  }
  project_disasm_knowledge_ready.val = true
  project_label_encoding.promise((kb, label) => {
    match kb.collect(project_label_unit, label) {
      Some(unit) => @mc.default_encoding(unit.target())
      None => @core_theory.Language::unknown()
    }
  })
  |> ignore
  project_label_name.promise((kb, label) => {
    kb.resolve(project_label_possible_name, label)
  })
  |> ignore
  project_insn_lifted_slot.promise((kb, label) => {
    guard kb.collect(project_insn_slot, label) is Some(insn) else { None }
    let target = project_label_target(kb, label)
    match insn.lift(target~) {
      Ok(lifted) => Some(lifted)
      Err(_) => None
    }
  })
  |> ignore
  project_insn_dests_slot.promise((kb, label) => {
    guard kb.collect(project_insn_lifted_slot, label) is Some(lifted) else {
      Some([])
    }
    let dests : Array[@knowledge.Object[Unit]] = []
    project_bil_dests(kb, lifted.bil(), dests)
    Some(project_labels_union([], dests))
  })
  |> ignore
  project_insn_delay_slot.promise((kb, label) => {
    match kb.collect(project_insn_lifted_slot, label) {
      Some(lifted) if lifted.delay() > 0 => Some(lifted.delay())
      _ => None
    }
  })
  |> ignore
}
