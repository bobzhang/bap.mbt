///|
test "x86-64 SSE floating-point instructions lift to intrinsic calls" {
  // as upstream's x86 plugin, the semantics context enables the
  // intrinsic semantics of the SSE floating-point instructions
  let registry = @mc.Registry::new()
  @primus_lisp.register_semantics_providers(registry~)
  let target = @core_theory.Target::x86_64()
  let ctx = @mc.Context::create(target)
  let insn = @mc.Insn::create(
    "ADDSDrr_Int",
    [@mc.Op::reg("XMM0"), @mc.Op::reg("XMM0"), @mc.Op::reg("XMM1")],
    addr=0x1000UL,
    size=4,
    encoding=@mc.default_encoding(target),
  )
  inspect(
    registry.lift(ctx, insn).bil().map(s => s.to_string()).join("\n"),
    content=(
      #|intrinsic:x0:imm64 := extract[63:0](low:128[YMM0:imm256])
      #|intrinsic:x1:imm64 := extract[63:0](low:128[YMM1:imm256])
      #|special @attribute:(bap:intrinsic intrinsic:fadd_rne_ieee754_binary)
      #|%#1:imm64 := intrinsic:y0:imm64
      #|YMM0:imm256 := concat(high:128[YMM0:imm256], concat(high:64[low:128[YMM0:imm256]], %#1:imm64))
    ),
  )
}
