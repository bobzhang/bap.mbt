// Lifting instructions of several architectures.

///|
fn lifter_for(
  target : @core_theory.Target,
  dir : String,
) -> ((String, Array[@primus_lisp.Operand]) -> String raise) raise {
  let lifter = @primus_lisp.load_semantics(target, [dir])
  let pkg = @mc.default_encoding(target).to_string()
  (name, ops) => {
    show_bil(
      lifter.lift(
        @knowledge.Name::create(name, pkg~),
        ops,
        pc=@types.Word::of_int(width=target.bits(), 0x1000),
      ),
    )
  }
}

///|
test "lift aarch64 instructions" {
  let lift = lifter_for(@core_theory.Target::aarch64(), "semantics/arm")
  inspect(
    lift("ADDXri", [Reg("X0"), Reg("X1"), Imm(4), Imm(0)]),
    content=(
      #|X0:imm64 := (X1:imm64 + 4:64u)
      #|
    ),
  )
  inspect(
    lift("SUBSXri", [Reg("X0"), Reg("X1"), Imm(1), Imm(0)]),
    content=(
      #|%#1:imm64 := ((X1:imm64 + 0xFFFFFFFFFFFFFFFE:64u) + 1:64u)
      #|NF:imm1 := extract[63:63](%#1:imm64)
      #|VF:imm1 := (((extract[63:63](X1:imm64) & 1:1u) & (not extract[63:63](%#1:imm64))) | (((not extract[63:63](X1:imm64)) & 0:1u) & extract[63:63](%#1:imm64)))
      #|ZF:imm1 := (%#1:imm64 == 0:64u)
      #|CF:imm1 := (((extract[63:63](X1:imm64) & 1:1u) | (1:1u & (not extract[63:63](%#1:imm64)))) | (extract[63:63](X1:imm64) & (not extract[63:63](%#1:imm64))))
      #|X0:imm64 := %#1:imm64
      #|
    ),
  )
  inspect(
    lift("ADRP", [Reg("X0"), Imm(2)]),
    content=(
      #|X0:imm64 := 0x3000:64u
      #|
    ),
  )
  inspect(
    lift("MADDXrrr", [Reg("X0"), Reg("X1"), Reg("X2"), Reg("XZR")]),
    content=(
      #|X0:imm64 := (0:64u + (X1:imm64 * X2:imm64))
      #|
    ),
  )
}

///|
test "lift thumb instructions" {
  let lift = lifter_for(@core_theory.Target::thumb(), "semantics/arm")
  inspect(
    lift("t2ADDri12", [Reg("R0"), Reg("R1"), Imm(4), Imm(14), Unknown]),
    content=(
      #|R0:imm32 := (R1:imm32 + 4:32u)
      #|
    ),
  )
}

///|
test "lift x86 and powerpc instructions" {
  let lift = lifter_for(@core_theory.Target::x86_64(), "semantics/x86")
  inspect(
    lift("PMULUDQrr", [Reg("XMM0"), Reg("XMM0"), Reg("XMM1")]),
    content=(
      #|%#1:imm64 := (pad:64[extract[95:64](XMM0:imm128)] * pad:64[extract[95:64](XMM1:imm128)])
      #|%#2:imm64 := (pad:64[extract[31:0](XMM0:imm128)] * pad:64[extract[31:0](XMM1:imm128)])
      #|XMM0:imm128 := concat(%#1:imm64, %#2:imm64)
      #|
    ),
  )
  inspect(
    lift("HLT", []),
    content=(
      #|special @attribute:(bap:intrinsic intrinsic:hlt)
      #|
    ),
  )
  let lift = lifter_for(@core_theory.Target::powerpc(), "semantics/powerpc")
  inspect(
    lift("NOP", []),
    content=(
      #|
    ),
  )
}
