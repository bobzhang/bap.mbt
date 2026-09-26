///|
fn bir(bil : Array[@types.Stmt]) -> String {
  show_bir(@bil.lift_bir(bil))
}

///|
test "straight-line code is a single block" {
  let x = v("x")
  let y = v("y")
  inspect(
    bir([Move(x, int(1)), Move(y, Var(x)), Special("nop")]),
    content=(
      #|%0:
      #|  x:imm32 := 1:32u
      #|  y:imm32 := x:imm32
      #|
    ),
  )
  inspect(bir([]), content="")
}

///|
test "jumps" {
  let x = v("x")
  inspect(
    bir([Move(x, int(1)), Jmp(Int(w(32, 0x1000)))]),
    content=(
      #|%0:
      #|  x:imm32 := 1:32u
      #|  goto @0x00001000
      #|
    ),
  )
  inspect(
    bir([Move(x, int(1)), Jmp(Var(x))]),
    content=(
      #|%0:
      #|  x:imm32 := 1:32u
      #|  goto (x:imm32)
      #|
    ),
  )
  inspect(
    bir([CpuExn(0x80)]),
    content=(
      #|%0:
      #|  goto @interrupt:#128
      #|
    ),
  )
  inspect(
    bir([
      Move(x, int(1)),
      @types.Stmt::encode(@types.Stmt::call(), "malloc"),
      Move(x, int(2)),
    ]),
    content=(
      #|%0:
      #|  x:imm32 := 1:32u
      #|  call @malloc with return %1
      #|%1:
      #|  x:imm32 := 2:32u
      #|
    ),
  )
  // a goto to an address label that is a subroutine is a call
  let blks = @bil.lift_bir([Jmp(Int(w(32, 0x2000)))], is_subroutine=t => {
    t.name() is Some(_)
  })
  inspect(
    show_bir(blks),
    content=(
      #|%0:
      #|  call @0x00002000 with noreturn
      #|
    ),
  )
}

///|
test "conditionals" {
  let x = v("x")
  let c = bool_var("CF")
  // a conditional jump becomes a guarded jump
  inspect(
    bir([If(cond=c, yes=[Jmp(Int(w(32, 0x10)))], no=[])]),
    content=(
      #|%0:
      #|  when CF:imm1 goto @0x00000010
      #|
    ),
  )
  inspect(
    bir([
      If(cond=c, yes=[Move(x, int(1))], no=[Move(x, int(2))]),
      Move(x, BinOp(Plus, Var(x), int(1))),
    ]),
    content=(
      #|%0:
      #|  when CF:imm1 goto %2
      #|  goto %1
      #|%1:
      #|  x:imm32 := 2:32u
      #|  goto %3
      #|%2:
      #|  x:imm32 := 1:32u
      #|  goto %3
      #|%3:
      #|  x:imm32 := (x:imm32 + 1:32u)
      #|
    ),
  )
  inspect(
    bir([If(cond=c, yes=[], no=[Move(x, int(2))])]),
    content=(
      #|%0:
      #|  when CF:imm1 goto %2
      #|  goto %1
      #|%1:
      #|  x:imm32 := 2:32u
      #|  goto %2
      #|%2:
      #|
    ),
  )
  inspect(
    bir([If(cond=c, yes=[], no=[])]),
    content=(
      #|%0:
      #|  when CF:imm1 goto %1
      #|  goto %1
      #|%1:
      #|
    ),
  )
}

///|
test "loops" {
  let x = v("x")
  let c = bool_var("CF")
  inspect(
    bir([
      Move(x, int(0)),
      While(cond=c, body=[Move(x, BinOp(Plus, Var(x), int(1)))]),
      Move(x, int(5)),
    ]),
    content=(
      #|%0:
      #|  x:imm32 := 0:32u
      #|  goto %1
      #|%1:
      #|  goto %2
      #|%2:
      #|  when CF:imm1 goto %3
      #|  goto %4
      #|%3:
      #|  x:imm32 := (x:imm32 + 1:32u)
      #|  goto %2
      #|%4:
      #|  x:imm32 := 5:32u
      #|
    ),
  )
  inspect(
    bir([While(cond=c, body=[])]),
    content=(
      #|%0:
      #|  when CF:imm1 goto %0
      #|
    ),
  )
  // upstream asserts that loop bodies have no control transfers (its
  // parser fails); the shared lowering keeps the jump
  inspect(
    bir([While(cond=c, body=[Jmp(int(1))])]),
    content=(
      #|%0:
      #|  goto %2
      #|%1:
      #|  goto @0x00000001
      #|%2:
      #|  when CF:imm1 goto %1
      #|
    ),
  )
}

///|
test "BIL round trip and jump destinations" {
  let x = v("x")
  let c = bool_var("CF")
  let bil : Array[@types.Stmt] = [
    Move(x, int(1)),
    Special("hint"),
    @types.Stmt::encode(@types.Stmt::intrinsic(), "llvm-x86_64:CPUID"),
    If(cond=c, yes=[Jmp(Int(w(32, 0x10)))], no=[]),
    If(cond=c, yes=[], no=[]),
    CpuExn(3),
    Jmp(Var(x)),
  ]
  inspect(
    show_bil(@bil.reflect_bil(bil)),
    content=(
      #|x:imm32 := 1:32u
      #|special @attribute:(bap:call intrinsic:llvm-x86_64:CPUID)
      #|if CF:imm1 then 1 stmts else 0 stmts
      #|cpuexn 3
      #|jmp x:imm32
    ),
  )
  let dests = @bil.jump_destinations(bil).map(d => {
    match d {
      Some(d) => d.tid().to_string()
      None => "?"
    }
  })
  inspect(
    dests.join(" "),
    content=(
      #|@intrinsic\:llvm-x86_64\:CPUID @0x00000010 @interrupt:#3 ?
    ),
  )
}
