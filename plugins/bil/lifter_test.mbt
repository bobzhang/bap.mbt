///|
test "intrinsic specifications" {
  let parse = (s : String) => {
    @bil.ISpec::parse(s).to_string() catch {
      Failure(msg) => "error: \{msg}"
    }
  }
  inspect(
    [
      ":any", ":unknown", ":special", "tag:call", "kind:ret", "asm:addsd", "llvm:trap",
      ":bad", "a:b:c",
    ]
    .map(parse)
    .join("\n"),
    content=(
      #|:any
      #|:unknown
      #|:special
      #|tag:CALL
      #|tag:RET
      #|asm:ADDSD
      #|LLVM:TRAP
      #|error: unknown keyword `bad', expects any | unknown | special
      #|error: ill-formed specification: a:b:c
    ),
  )
}

///|
fn insn(
  name : String,
  ops? : Array[@mc.Op] = [],
  assembly? : String = "",
  kinds? : Array[@mc.Kind] = [],
) -> @mc.Insn {
  @mc.Insn::create(
    name,
    ops,
    addr=0x1000,
    size=4,
    assembly~,
    encoding=@core_theory.Language::llvm_x86_64(),
    kinds~,
  )
}

///|
test "intrinsic calls" {
  let i = insn("ADD64ri8", ops=[@mc.Op::reg("RAX", code=35), Imm(-1), Fmm(1.5)])
  inspect(
    show_bil(@bil.create_intrinsic(@core_theory.Target::x86_64(), i)),
    content=(
      #|insn:op1:imm64 := 0x23:64u
      #|insn:op2:imm64 := 0xFFFFFFFFFFFFFFFF:64u
      #|insn:op3:imm64 := 0x3FF8000000000000:64u
      #|insn:next_address:imm64 := 0x1004:64u
      #|special @attribute:(bap:intrinsic llvm-x86_64:ADD64ri8)
    ),
  )
}

///|
/// A registry with a single lifter for the test instructions.
fn registry() -> @mc.Registry {
  let r = @mc.Registry::new()
  let x = @types.Var::create("RAX", Imm(64))
  let t = @types.Var::create("t", Imm(64), is_virtual=true)
  let r11 = @types.Var::create("R11", Imm(64))
  r.register(
    @mc.Provider::create("test", accepts=_ => true, lift=(_, insn) => {
      match insn.name() {
        "NOP" => @mc.Lifted::of_bil([])
        "ADD" =>
          @mc.Lifted::of_bil([
            Move(t, BinOp(Plus, Int(w(64, 1)), Int(w(64, 2)))),
            Move(x, BinOp(Plus, Var(x), Var(t))),
          ])
        "HLT" => @mc.Lifted::of_bil([Special("halt")])
        "JMP" => @mc.Lifted::of_bil([Jmp(Int(w(64, 0x2000)))])
        "LOADJMP" =>
          @mc.Lifted::of_bil([
            Move(r11, Int(w(64, 0x3000))),
            Jmp(
              Load(
                mem=Var(
                  @types.Var::create("mem", Mem(addr_width=64, value_width=8)),
                ),
                addr=Var(r11),
                endian=LittleEndian,
                typ=Imm(64),
              ),
            ),
          ])
        name => raise Unsupported(opcode=name, target="test")
      }
    }),
  )
  r
}

///|
fn lift_with(
  specs : Array[@bil.ISpec],
  name : String,
  assembly? : String = "",
) -> String {
  let ctx = @mc.Context::create(@core_theory.Target::x86_64())
  let cfg = { ..@bil.Config::default(), enable_intrinsics: specs, }
  let lifted = @bil.lift(
    registry(),
    ctx,
    insn(name, assembly~, kinds=[Call]),
    cfg~,
  ) catch {
    e => return "error: \{e.message()}"
  }
  show_bil(lifted.bil())
}

///|
test "lifting with intrinsics and passes" {
  @bil.select() |> ignore
  inspect(
    lift_with([], "ADD"),
    content=(
      #|RAX:imm64 := (RAX:imm64 + 3:64u)
    ),
  )
  inspect(lift_with([], "NOP"), content="")
  inspect(
    lift_with([], "UD2"),
    content=(
      #|error: unsupported instruction: UD2 (target target:x86_64)
    ),
  )
  inspect(
    lift_with([], "HLT"),
    content=(
      #|special halt
    ),
  )
  inspect(
    lift_with([Unk], "UD2"),
    content=(
      #|insn:next_address:imm64 := 0x1004:64u
      #|special @attribute:(bap:intrinsic llvm-x86_64:UD2)
    ),
  )
  inspect(
    lift_with([Unk], "NOP"),
    content=(
      #|insn:next_address:imm64 := 0x1004:64u
      #|special @attribute:(bap:intrinsic llvm-x86_64:NOP)
    ),
  )
  inspect(
    lift_with([Special], "HLT"),
    content=(
      #|insn:next_address:imm64 := 0x1004:64u
      #|special @attribute:(bap:intrinsic llvm-x86_64:HLT)
    ),
  )
  inspect(
    lift_with([Any], "ADD"),
    content=(
      #|insn:next_address:imm64 := 0x1004:64u
      #|special @attribute:(bap:intrinsic llvm-x86_64:ADD)
    ),
  )
  inspect(
    lift_with([Asm("ADDQ")], "ADD", assembly=" addq %rax, 1"),
    content=(
      #|insn:next_address:imm64 := 0x1004:64u
      #|special @attribute:(bap:intrinsic llvm-x86_64:ADD)
    ),
  )
  inspect(
    lift_with([Tag("CALL")], "ADD"),
    content=(
      #|insn:next_address:imm64 := 0x1004:64u
      #|special @attribute:(bap:intrinsic llvm-x86_64:ADD)
    ),
  )
  inspect(
    lift_with([Tag("RET")], "ADD"),
    content=(
      #|RAX:imm64 := (RAX:imm64 + 3:64u)
    ),
  )
  inspect(
    lift_with([Insn("LLVM", "AD")], "ADD"),
    content=(
      #|insn:next_address:imm64 := 0x1004:64u
      #|special @attribute:(bap:intrinsic llvm-x86_64:ADD)
    ),
  )
  @types.select_passes([])
}

///|
test "relocations redirect jumps" {
  @types.select_passes([])
  let ctx = @mc.Context::create(@core_theory.Target::x86_64())
  let lift = (rels : @bil.Relocations, name : String) => {
    let p = @bil.provider(registry(), relocations=rels)
    show_bil(p.lift(ctx, insn(name)).bil()) catch {
      e => "error: \{e.message()}"
    }
  }
  let internal = @bil.Relocations::create(rels=[(0x1002, 0x4000)])
  inspect(
    lift(internal, "JMP"),
    content=(
      #|jmp 0x4000:64u
    ),
  )
  let external = @bil.Relocations::create(exts=[(0x3000, "printf")])
  inspect(
    lift(external, "LOADJMP"),
    content=(
      #|R11:imm64 := 0x3000:64u
      #|special @attribute:(bap:call printf)
    ),
  )
  inspect(
    lift(@bil.Relocations::empty(), "JMP"),
    content=(
      #|jmp 0x2000:64u
    ),
  )
  let bil : Array[@types.Stmt] = [Jmp(Int(w(64, 0)))]
  inspect(
    show_bil(external.fixup(bil, addr=0x3000, size=1, width=64, is_stub=true)),
    content=(
      #|special @attribute:(bap:call printf:external)
    ),
  )
}

///|
test "plugin configuration" {
  guard @bil.enable(list=true) is Some(lines) else {
    fail("expected a listing")
  }
  assert_true(lines.iter().any(l => l.has_prefix("prune-dead-virtuals")))
  assert_true(
    @bil.enable(normalization="1", enable_intrinsics=[Special]) is None,
  )
  assert_eq(@bil.current_config().enable_intrinsics, [@bil.ISpec::Special])
  let err = try @bil.enable(normalization="7") catch {
    Failure(msg) => msg
  } noraise {
    _ => "ok"
  }
  inspect(
    err,
    content=(
      #|unknown normalization level 7
    ),
  )
  @bil.configure(@bil.Config::default())
  @bil.uninstall_lift_hook()
  @types.select_passes([])
}

///|
test "project lifting applies the selected passes" {
  let insn = @project.ProjectDisassemblyInstruction::create(
    @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0x1000,
      b"\x90\x90\x90\x90",
    ),
    name="ADD",
    encoding="llvm",
    operands=[],
  )
  let target = @core_theory.Target::x86_64()
  let lift = () => {
    match insn.lift(target~, registry=registry()) {
      Ok(l) => show_bil(l.bil())
      Err(e) => "error: \{e}"
    }
  }
  // without the hook the lifted code is kept as is (two statements)
  assert_eq(lift().split("\n").count(), 2)
  assert_true(@bil.enable() is None)
  assert_true(@project.lift_hooks().contains(@bil.lift_hook_name))
  inspect(
    lift(),
    content=(
      #|RAX:imm64 := (RAX:imm64 + 3:64u)
    ),
  )
  @bil.uninstall_lift_hook()
  @bil.configure(@bil.Config::default())
  @types.select_passes([])
  assert_eq(lift().split("\n").count(), 2)
}
