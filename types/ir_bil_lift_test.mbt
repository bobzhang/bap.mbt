///|
/// Renames fresh tids (`%<id>`) by order of appearance, so that the text
/// does not depend on the global tid counter.
fn lift_normalize(text : String) -> String {
  let names : Map[String, String] = Map([])
  let out = StringBuilder()
  let chars = text.to_array()
  let mut i = 0
  while i < chars.length() {
    if chars[i] == '%' && i + 1 < chars.length() && chars[i + 1] is ('0'..<='9') {
      let digits = StringBuilder()
      let mut j = i + 1
      while j < chars.length() && chars[j] is ('0'..<='9') {
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

///|
fn lift_text(blks : Array[@types.Term[@types.Blk]]) -> String {
  lift_normalize(blks.map(blk => blk.blk_to_string()).join("\n"))
}

///|
fn lift_var(name : String, width~ : Int32 = 32) -> @types.Var {
  @types.Var::new(name~, typ=Imm(width))
}

///|
fn lift_word(value : Int32, width~ : Int32 = 32) -> @types.Word {
  @types.Word::of_int(width~, value) catch {
    _ => panic()
  }
}

///|
fn lift_int(value : Int32, width~ : Int32 = 32) -> @types.Exp {
  Int(lift_word(value, width~))
}

///|
fn lift_move(name : String, value : Int32) -> @types.Stmt {
  Move(lift_var(name), lift_int(value))
}

///|
test "Blk::of_bil keeps straight-line assignments in one block" {
  let blks = @types.Blk::of_bil([lift_move("x", 1), lift_move("y", 2)])
  inspect(
    lift_text(blks),
    content=(
      #|%b0
      #|x:imm32 := 1:32u
      #|y:imm32 := 2:32u
    ),
  )
  inspect(@types.Blk::of_bil([]).length(), content="0")
  inspect(@types.Blk::of_bil([Special("nop")]).length(), content="0")
}

///|
test "Blk::of_bil lowers two-arm conditionals into a diamond" {
  let cond = @types.Exp::Var(lift_var("c", width=1))
  let blks = @types.Blk::of_bil([
    lift_move("x", 0),
    If(cond~, yes=[lift_move("y", 1)], no=[lift_move("y", 2)]),
    lift_move("z", 3),
  ])
  inspect(
    lift_text(blks),
    content=(
      #|%b0
      #|x:imm32 := 0:32u
      #|goto %b1
      #|%b1
      #|when c:imm1 goto %b2
      #|goto %b3
      #|%b3
      #|y:imm32 := 2:32u
      #|goto %b4
      #|%b2
      #|y:imm32 := 1:32u
      #|goto %b4
      #|%b4
      #|z:imm32 := 3:32u
    ),
  )
}

///|
test "Blk::of_bil lowers one-arm and nested conditionals" {
  let c = @types.Exp::Var(lift_var("c", width=1))
  let d = @types.Exp::Var(lift_var("d", width=1))
  // a conditional jump
  let jmp = @types.Blk::of_bil([If(cond=c, yes=[Jmp(lift_int(0x10))], no=[])])
  inspect(
    lift_text(jmp),
    content=(
      #|%b0
      #|when c:imm1 goto @0x00000010
    ),
  )
  // a jump under two conditions keeps both guards
  let nested = @types.Blk::of_bil([
    If(cond=c, yes=[If(cond=d, yes=[Jmp(lift_int(0x10))], no=[])], no=[]),
  ])
  inspect(
    lift_text(nested),
    content=(
      #|%b0
      #|when (c:imm1 & d:imm1) goto @0x00000010
    ),
  )
  // an assignment under a condition, with an empty then-arm
  let assign = @types.Blk::of_bil([If(cond=c, yes=[], no=[lift_move("x", 1)])])
  inspect(
    lift_text(assign),
    content=(
      #|%b0
      #|when c:imm1 goto %b1
      #|goto %b2
      #|%b2
      #|x:imm32 := 1:32u
      #|goto %b1
      #|%b1
    ),
  )
}

///|
test "Blk::of_bil lowers while loops into head, body and tail blocks" {
  let c = @types.Exp::Var(lift_var("c", width=1))
  let blks = @types.Blk::of_bil([
    lift_move("i", 0),
    While(cond=c, body=[lift_move("i", 1), lift_move("j", 2)]),
    lift_move("k", 3),
  ])
  inspect(
    lift_text(blks),
    content=(
      #|%b0
      #|i:imm32 := 0:32u
      #|goto %b1
      #|%b1
      #|goto %b2
      #|%b2
      #|when c:imm1 goto %b3
      #|goto %b4
      #|%b3
      #|i:imm32 := 1:32u
      #|j:imm32 := 2:32u
      #|goto %b2
      #|%b4
      #|k:imm32 := 3:32u
    ),
  )
  let empty = @types.Blk::of_bil([While(cond=c, body=[])])
  inspect(
    lift_text(empty),
    content=(
      #|%b0
      #|when c:imm1 goto %b0
    ),
  )
}

///|
test "Blk::of_bil lowers jumps, calls, interrupts and specials" {
  let target = lift_int(0x1000)
  let indirect = @types.Exp::Var(lift_var("r"))
  inspect(
    lift_text(@types.Blk::of_bil([Jmp(target), lift_move("dead", 0)])),
    content=(
      #|%b0
      #|goto @0x00001000
      #|%b1
      #|dead:imm32 := 0:32u
    ),
  )
  inspect(
    lift_text(@types.Blk::of_bil([Jmp(indirect)])),
    content=(
      #|%b0
      #|goto *r:imm32
    ),
  )
  // jumps to subroutines are calls
  let callee = @types.Tid::for_addr(lift_word(0x1000))
  inspect(
    lift_text(
      @types.Blk::of_bil([Jmp(target)], is_subroutine=tid => tid == callee),
    ),
    content=(
      #|%b0
      #|call @0x00001000 with noreturn
    ),
  )
  // the call special of upstream lifters calls a named subroutine
  inspect(
    lift_text(
      @types.Blk::of_bil([@types.Stmt::encode(@types.Stmt::call(), "puts")]),
    ),
    content=(
      #|%b0
      #|call @puts with noreturn
    ),
  )
  // the control hints of the Basic lifter classify the next jump
  inspect(
    lift_text(
      @types.Blk::of_bil([
        @types.Stmt::encode(@types.Stmt::call(), "indirect"),
        Jmp(indirect),
      ]),
    ),
    content=(
      #|%b0
      #|call *r:imm32 with noreturn
    ),
  )
  inspect(
    lift_text(
      @types.Blk::of_bil([
        @types.Stmt::encode(@types.Stmt::goto(), "0x1000"),
        Jmp(target),
      ]),
    ),
    content=(
      #|%b0
      #|goto @0x00001000
    ),
  )
  inspect(
    lift_text(@types.Blk::of_bil([CpuExn(0x80), lift_move("x", 1)])),
    content=(
      #|%b0
      #|goto @interrupt:#128
      #|%b1
      #|x:imm32 := 1:32u
    ),
  )
  // address labels are normalized to the code address width
  inspect(
    lift_text(
      @types.Blk::of_bil([Jmp(lift_int(0x10, width=64))], addr_width=32),
    ),
    content=(
      #|%b0
      #|goto @0x00000010
    ),
  )
}
