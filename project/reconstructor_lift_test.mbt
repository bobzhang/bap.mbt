///|
/// The Basic disassembly of `bytes` at `start`, split into blocks at
/// `starts` and linked by `edges`.
fn lift_ir_disassembly(
  triple : String,
  bytes : Bytes,
  start~ : UInt64,
  starts~ : Array[UInt64],
  edges~ : Array[@project.ProjectDisassemblyEdge],
) -> @project.ProjectDisassemblyState raise {
  let whole = reconstructor_basic_disassembly(triple, bytes, start~)
  let memory = @memory.Memory::from_bytes(endian=LittleEndian, start~, bytes)
  let blocks : Array[@memory.Memory] = []
  for i, from in starts {
    let end = if i + 1 < starts.length() {
      starts[i + 1]
    } else {
      start + bytes.length().to_uint64()
    }
    match memory.view(from~, words=(end - from).to_int(), word_size=8) {
      Ok(view) => blocks.push(view)
      Err(reason) => fail(reason)
    }
  }
  @project.ProjectDisassemblyState::create(
    blocks~,
    instructions=whole.instructions(),
    edges~,
  )
}

///|
/// The names and jumps of the blocks of `sub`.
fn lift_ir_jmps(sub : @types.Term[@types.Sub]) -> String {
  let lines : Array[String] = []
  for blk in sub.blks() {
    lines.push(blk.name())
    for jmp in blk.jmps() {
      lines.push("  " + jmp.jmp_to_string())
    }
  }
  lines.join("\n")
}

///|
test "reconstruction lifts branches, falls, calls and returns into IR" {
  // 0x9000: test rax, rax
  // 0x9003: je 0x900a
  // 0x9005: add rax, 1
  // 0x9009: ret
  // 0x900a: call 0x9000
  // 0x900f: ret
  let bytes = b"\x48\x85\xc0" +
    b"\x74\x05" +
    b"\x48\x83\xc0\x01" +
    b"\xc3" +
    b"\xe8\xf1\xff\xff\xff" +
    b"\xc3"
  let disassembly = lift_ir_disassembly(
    "x86_64",
    bytes,
    start=0x9000UL,
    starts=[0x9000UL, 0x9005UL, 0x900aUL, 0x900fUL],
    edges=[
      @project.ProjectDisassemblyEdge::create(
        source=0x9003UL,
        target=0x900aUL,
        kind=CondEdge,
      ),
      @project.ProjectDisassemblyEdge::create(
        source=0x9003UL,
        target=0x9005UL,
        kind=FallEdge,
      ),
      @project.ProjectDisassemblyEdge::create(
        source=0x900aUL,
        target=0x900fUL,
        kind=FallEdge,
      ),
    ],
  )
  let project = @project.Project::empty(@core_theory.Target::x86_64()).with_disassembly(
    disassembly,
  )
  guard project.reconstruct() is Ok(reconstructed) else {
    fail("reconstruction failed")
  }
  let subs = reconstructed.program().subs()
  assert_eq(subs.length(), 1)
  // the conditional branch keeps its lifted jump and falls to the next
  // block; the call returns to its fallthrough and, targeting the entry of
  // its own subroutine, is linked to the subroutine; as upstream, a return
  // jumps to the return address popped from the stack, an unresolved jump
  // that becomes a call without return (`alternate_nonlocal`)
  inspect(
    lift_ir_jmps(subs[0]),
    content=(
      #|@0x0000000000009000
      #|  when ZF:imm1 goto @0x000000000000900a
      #|  goto @0x0000000000009005
      #|@0x0000000000009005
      #|  call *%ret_addr:imm64 with noreturn
      #|@0x000000000000900a
      #|  call @sub_0x9000 with return @0x000000000000900f
      #|@0x000000000000900f
      #|  call *%ret_addr:imm64 with noreturn
    ),
  )
  // the terms carry the address and instruction they were lifted from
  let entry = subs[0].blks()[0]
  let jne = entry.jmps()[0]
  inspect(
    jne.get_attr("address").unwrap_or("-"),
    content=(
      #|0x9003:64u
    ),
  )
  inspect(
    jne.get_attr("insn").unwrap_or("-"),
    content=(
      #|JCC_1(0x5,0x4)
    ),
  )
  inspect(
    entry.get_attr("address").unwrap_or("-"),
    content=(
      #|0x9000:64u
    ),
  )
  assert_eq(reconstructed.lift_errors(), [])
}

///|
fn lift_ir_var(name : String, width? : Int = 32) -> @types.Var {
  @types.Var::new(name~, typ=Imm(width))
}

///|
fn lift_ir_int(value : Int) -> @types.Exp {
  Int(@types.Word::of_int(width=32, value)) catch {
    _ => panic()
  }
}

///|
/// A registry whose lifter gives the instructions `CMOV`, `LOOP`, `SVC`
/// and `SPIN` structured semantics.
fn lift_ir_registry() -> @mc.Registry {
  let registry = @mc.Registry::new()
  let c = @types.Exp::Var(lift_ir_var("c", width=1))
  registry.register(
    @mc.Provider::create("structured", accepts=_ => true, lift=(_, insn) => {
      let bil : Array[@types.Stmt] = match insn.name {
        "CMOV" =>
          [
            If(cond=c, yes=[Move(lift_ir_var("x"), lift_ir_int(1))], no=[
              Move(lift_ir_var("x"), lift_ir_int(2)),
            ]),
          ]
        "LOOP" =>
          [
            While(cond=c, body=[
              Move(
                lift_ir_var("x"),
                BinOp(Plus, Var(lift_ir_var("x")), lift_ir_int(1)),
              ),
            ]),
          ]
        "SVC" => [CpuExn(0)]
        "SPIN" => [Jmp(lift_ir_int(0x10c))]
        _ => raise @mc.Unsupported(opcode=insn.name, target="structured")
      }
      @mc.Lifted::of_bil(bil)
    }),
  )
  registry
}

///|
test "reconstruction keeps conditional assignments, loops and interrupts" {
  let insn = (
    addr : UInt64,
    name : String,
    kinds : Array[@project.ProjectInstructionKind],
  ) => {
    let mem = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=addr,
      b"\x00\x00\x00\x00",
    )
    @project.ProjectDisassemblyInstruction::create(mem, name~, kinds~)
  }
  let first = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x100UL,
    Bytes::make(12, b'\x00'),
  )
  let second = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x10cUL,
    Bytes::make(4, b'\x00'),
  )
  let disassembly = @project.ProjectDisassemblyState::create(
    blocks=[first, second],
    instructions=[
      insn(0x100UL, "CMOV", []),
      insn(0x104UL, "LOOP", []),
      insn(0x108UL, "SVC", [ProjectCall]),
      insn(0x10cUL, "SPIN", [ProjectUnconditionalBranch, ProjectBarrier]),
    ],
    edges=[
      @project.ProjectDisassemblyEdge::create(
        source=0x108UL,
        target=0x10cUL,
        kind=FallEdge,
      ),
    ],
  )
  let project = @project.Project::empty(@core_theory.Target::arm()).with_disassembly(
    disassembly,
  )
  let reconstructor = @project.ProjectReconstructor::default(
    registry=lift_ir_registry(),
  )
  guard project.reconstruct(reconstructor~) is Ok(reconstructed) else {
    fail("reconstruction failed")
  }
  let subs = reconstructed.program().subs()
  // as upstream (`insert_synthetic`), the interrupt handler, called but not
  // disassembled, gets a synthetic subroutine
  inspect(
    subs
    .map(sub => "\{sub.sub_name()} synthetic=\{sub.is_synthetic()}")
    .join(" "),
    content=(
      #|sub_0x100 synthetic=false interrupt:#0 synthetic=true
    ),
  )
  // both arms of the conditional and the loop body keep their assignments
  // in blocks of their own; the interrupt of the call instruction returns
  // to the fallthrough; the jump to itself of the last block stays local
  inspect(
    lift_ir_normalize(subs[0].sub_to_string()),
    content=(
      #|sub sub_0x100()
      #|@0x00000100
      #|when c:imm1 goto %b0
      #|goto %b1
      #|%b1
      #|x:imm32 := 2:32u
      #|goto %b2
      #|%b0
      #|x:imm32 := 1:32u
      #|goto %b2
      #|%b2
      #|goto %b3
      #|%b4
      #|x:imm32 := (x:imm32 + 1:32u)
      #|goto %b3
      #|%b3
      #|when c:imm1 goto %b4
      #|goto %b5
      #|%b5
      #|interrupt 0x0 return @0x0000010c
      #|@0x0000010c
      #|goto @0x0000010c
    ),
  )
}

///|
/// Renames fresh tids (`%<id>`) by order of appearance.
fn lift_ir_normalize(text : String) -> String {
  let names : Map[String, String] = Map([])
  let out = StringBuilder()
  let chars = text.to_array()
  let mut i = 0
  while i < chars.length() {
    if chars[i] == '%' && i + 1 < chars.length() && chars[i + 1] is ('0'..='9') {
      let digits = StringBuilder()
      let mut j = i + 1
      while j < chars.length() && chars[j] is ('0'..='9') {
        digits.write_char(chars[j])
        j += 1
      }
      let key = digits.to_string()
      let name = match names.get(key) {
        Some(name) => name
        None => {
          let name = "%b\{names.length()}"
          names[key] = name
          name
        }
      }
      out.write_string(name)
      i = j
    } else {
      out.write_char(chars[i])
      i += 1
    }
  }
  out.to_string()
}
