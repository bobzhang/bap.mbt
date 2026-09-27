///|
fn wb_var(name : String, width : Int) -> Exp raise @mc.LiftError {
  Exp::of_var(@types.Var::new(name~, typ=Imm(width)))
}

///|
fn wb_render(rtl : Array[Rtl]) -> String raise @mc.LiftError {
  rtl_to_bil(rtl).map(s => s.to_string()).join("\n")
}

///|
test "rtl: assignment to a concatenation of variables" {
  let hi = wb_var("HI", 32)
  let lo = wb_var("LO", 32)
  let x = wb_var("X", 64)
  let pair = hi.concat(lo)
  inspect(
    wb_render([pair.assign(x)]),
    content=(
      #|HI:imm32 := extract[63:32](X:imm64)
      #|LO:imm32 := extract[31:0](X:imm64)
    ),
  )
  // `Vars` with several variables (the `of_vars` form of upstream)
  let vars : Exp = {
    sign: Unsigned,
    width: 64,
    body: Vars(@types.Var::new(name="HI", typ=Imm(32)), [
      @types.Var::new(name="LO", typ=Imm(32)),
    ]),
  }
  inspect(
    wb_render([vars.assign(x)]),
    content=(
      #|HI:imm32 := extract[63:32](X:imm64)
      #|LO:imm32 := extract[31:0](X:imm64)
    ),
  )
  // a var-aligned slice of a concatenation is the variable itself
  let low_half = vars.extract(31, 0)
  inspect(
    bil_exp(low_half.body).to_string(),
    content=(
      #|LO:imm32
    ),
  )
  // a misaligned slice is a plain extract
  inspect(
    bil_exp(vars.extract(40, 8).body).to_string(),
    content=(
      #|extract[40:8](concat(HI:imm32, LO:imm32))
    ),
  )
  // partial update of a slice spanning both variables
  inspect(
    wb_render([vars.extract(47, 16).assign(wb_var("Y", 32))]),
    content=(
      #|HI:imm32 := concat(extract[31:16](HI:imm32), extract[31:16](Y:imm32))
      #|LO:imm32 := concat(extract[15:0](Y:imm32), extract[15:0](LO:imm32))
    ),
  )
}

///|
test "rtl: casts and foreach" {
  let b = wb_var("B", 1).signed()
  // 1-bit values extend by their own signedness
  inspect(
    bil_exp(b.cast(8, Unsigned).body).to_string(),
    content=(
      #|extend:8[B:imm1]
    ),
  )
  inspect(
    bil_exp(wb_var("W", 32).cast(1, Signed).body).to_string(),
    content=(
      #|low:1[W:imm32]
    ),
  )
  // inverse iteration starts from the most significant chunk
  let step = wb_var("S", 8)
  let r = wb_var("R", 16)
  inspect(
    wb_render([Foreach(true, step, r, [step.assign(step + one)])]),
    content=(
      #|S:imm8 := extract[15:8](R:imm16)
      #|S:imm8 := (S:imm8 + pad:8[1:1u])
      #|R:imm16 := concat(S:imm8, extract[7:0](R:imm16))
      #|S:imm8 := extract[7:0](R:imm16)
      #|S:imm8 := (S:imm8 + pad:8[1:1u])
      #|R:imm16 := concat(extract[15:8](R:imm16), S:imm8)
    ),
  )
}

///|
test "rtl: invalid left-hand side" {
  // writes to constants (the zero register) are discarded
  assert_eq(wb_render([one.assign(zero)]), "")
  try wb_render([(one + one).assign(zero)]) catch {
    err =>
      inspect(
        err.message(),
        content=(
          #|MIPS lifter fail: unexpected left side of :=
        ),
      )
  } noraise {
    _ => fail("expected failure")
  }
  let mem = Exp::of_var(
    @types.Var::new(name="mem", typ=Mem(addr_width=32, value_width=8)),
  ) catch {
    err => {
      inspect(
        err.message(),
        content=(
          #|MIPS lifter fail: variable mem doesn't has notion of bitwidth
        ),
      )
      return
    }
  }
  ignore(mem)
  fail("expected failure")
}
