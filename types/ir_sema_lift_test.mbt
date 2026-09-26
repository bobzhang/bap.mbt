///|
fn lift_opt(value : String?) -> String {
  match value {
    Some(text) => text
    None => "-"
  }
}

///|
fn lift_attrs(blks : Array[@types.Term[@types.Blk]]) -> String {
  let lines : Array[String] = []
  for blk in blks {
    lines.push("\{blk.name()} address=\{lift_opt(blk.get_attr("address"))}")
    for def in blk.defs() {
      lines.push(
        "  \{def.def_to_string()} insn=\{lift_opt(def.get_attr("insn"))} address=\{lift_opt(def.get_attr("address"))}",
      )
    }
    for jmp in blk.jmps() {
      lines.push(
        "  \{jmp.jmp_to_string()} insn=\{lift_opt(jmp.get_attr("insn"))} address=\{lift_opt(jmp.get_attr("address"))}",
      )
    }
  }
  lift_normalize(lines.join("\n"))
}

///|
test "Blk::lift_insn attributes the terms of one instruction" {
  let insn = @types.IrInsn::new(
    [lift_move("x", 1), Jmp(lift_int(0x20))],
    addr=lift_word(0x10),
    insn="MOV(x,1)",
  )
  inspect(
    lift_attrs(@types.Blk::lift_insn(insn)),
    content=(
      #|@0x00000010 address=-
      #|  x:imm32 := 1:32u insn=MOV(x,1) address=0x10:32u
      #|  goto @0x00000020 insn=MOV(x,1) address=0x10:32u
    ),
  )
}

///|
test "Blk::lift_block splits blocks at instruction boundaries and adds falls" {
  let c = @types.Exp::Var(lift_var("c", width=1))
  let next = @types.Jmp::resolved(@types.Tid::for_addr(lift_word(0x20)))
  let insns = [
    @types.IrInsn::new(
      [If(cond=c, yes=[lift_move("x", 1)], no=[])],
      addr=lift_word(0x10),
      insn="CMOV",
    ),
    @types.IrInsn::new([lift_move("y", 2)], addr=lift_word(0x14), insn="MOV"),
    @types.IrInsn::new(
      [If(cond=c, yes=[Jmp(lift_int(0x40))], no=[])],
      addr=lift_word(0x18),
      insn="JNE",
    ),
  ]
  let blks = @types.Blk::lift_block(
    @types.Tid::for_addr(lift_word(0x10)),
    insns,
    addr=lift_word(0x10),
    fall=IntraFall(next),
  )
  inspect(
    lift_attrs(blks),
    content=(
      #|@0x00000010 address=0x10:32u
      #|  when c:imm1 goto %b0 insn=CMOV address=0x10:32u
      #|  goto %b1 insn=CMOV address=0x10:32u
      #|%b0 address=-
      #|  x:imm32 := 1:32u insn=CMOV address=0x10:32u
      #|  goto %b1 insn=CMOV address=0x10:32u
      #|%b1 address=-
      #|  y:imm32 := 2:32u insn=MOV address=0x14:32u
      #|  when c:imm1 goto @0x00000040 insn=JNE address=0x18:32u
      #|  goto @0x00000020 insn=- address=-
    ),
  )
}

///|
test "Blk::lift_block turns the jumps of calls into calls with returns" {
  let tid = @types.Tid::for_addr(lift_word(0x10))
  let next = @types.Jmp::resolved(@types.Tid::for_addr(lift_word(0x15)))
  let call = @types.IrInsn::new(
    [lift_move("sp", 4), Jmp(lift_int(0x100))],
    addr=lift_word(0x10),
    is_call=true,
  )
  inspect(
    lift_text(@types.Blk::lift_block(tid, [call], fall=IntraFall(next))),
    content=(
      #|@0x00000010
      #|sp:imm32 := 4:32u
      #|call @0x00000100 with return @0x00000015
    ),
  )
  inspect(
    lift_text(@types.Blk::lift_block(tid, [call])),
    content=(
      #|@0x00000010
      #|sp:imm32 := 4:32u
      #|call @0x00000100 with noreturn
    ),
  )
  // a barrier gets no fallthrough
  let ret = @types.IrInsn::new(
    [Jmp(@types.Exp::Var(lift_var("lr")))],
    is_barrier=true,
  )
  inspect(
    lift_text(@types.Blk::lift_block(tid, [ret], fall=IntraFall(next))),
    content=(
      #|@0x00000010
      #|goto *lr:imm32
    ),
  )
  // an interrupt of a call instruction returns to the fallthrough
  let svc = @types.IrInsn::new([CpuExn(0)], is_call=true)
  inspect(
    lift_text(@types.Blk::lift_block(tid, [svc], fall=IntraFall(next))),
    content=(
      #|@0x00000010
      #|interrupt 0x0 return @0x00000015
    ),
  )
  // a fallthrough into another subroutine is an implicit call
  let other = @types.Jmp::resolved(@types.Tid::for_name("other"))
  inspect(
    lift_text(
      @types.Blk::lift_block(
        tid,
        [@types.IrInsn::new([lift_move("x", 1)])],
        fall=InterFall(other),
      ),
    ),
    content=(
      #|@0x00000010
      #|x:imm32 := 1:32u
      #|call @other with noreturn
    ),
  )
  inspect(
    lift_text(@types.Blk::lift_block(tid, [call], fall=InterFall(other))),
    content=(
      #|@0x00000010
      #|sp:imm32 := 4:32u
      #|call @0x00000100 with return %b0
      #|%b0
      #|call @other with noreturn
    ),
  )
}

///|
test "Blk::lift_insns lifts a sequence ending with its last instruction" {
  let insns = [
    @types.IrInsn::new([lift_move("x", 1)], addr=lift_word(0x10), insn="A"),
    @types.IrInsn::new([Jmp(lift_int(0x40))], addr=lift_word(0x14), insn="B"),
  ]
  inspect(
    lift_attrs(@types.Blk::lift_insns(insns, addr=lift_word(0x10))),
    content=(
      #|@0x00000010 address=0x10:32u
      #|  x:imm32 := 1:32u insn=A address=-
      #|  goto @0x00000040 insn=B address=-
    ),
  )
  inspect(@types.Blk::lift_insns([]).length(), content="1")
}

///|
test "Program::relink_calls links calls and nonlocal jumps to subroutines" {
  let entry_a = @types.Tid::for_addr(lift_word(0x10))
  let entry_b = @types.Tid::for_addr(lift_word(0x40))
  let inner = @types.Tid::for_addr(lift_word(0x20))
  let sub_a = @types.Tid::for_name("a")
  let sub_b = @types.Tid::for_name("b")
  let a = @types.Sub::create(name="a", tid=sub_a, blks=[
    @types.Blk::create(tid=entry_a, jmps=[
      @types.Jmp::create_call(
        @types.Call::create(
          target=@types.Label::direct(entry_b),
          return_label=@types.Label::direct(inner),
        ),
      ),
    ]),
    @types.Blk::create(tid=inner, jmps=[
      @types.Jmp::create_goto(
        @types.Label::direct(entry_a),
        cond=Var(lift_var("c", width=1)),
      ),
      @types.Jmp::create_goto(@types.Label::indirect(Var(lift_var("r")))),
    ]),
  ])
  let b = @types.Sub::create(name="b", tid=sub_b, blks=[
    @types.Blk::create(tid=entry_b, jmps=[
      @types.Jmp::create_goto(@types.Label::direct(entry_a)),
    ]),
  ])
  let entries : Map[@types.Tid, @types.Tid] = Map([
    (entry_a, sub_a),
    (entry_b, sub_b),
  ])
  let prog = @types.Program::relink_calls(
    @types.Program::create(subs=[a, b]),
    entries,
  )
  inspect(
    prog.subs().map(sub => sub.sub_to_string()).join("\n"),
    content=(
      #|sub a()
      #|@0x00000010
      #|call @b with return @0x00000020
      #|@0x00000020
      #|when c:imm1 call @a with noreturn
      #|call *r:imm32 with noreturn
      #|sub b()
      #|@0x00000040
      #|call @a with noreturn
    ),
  )
}
