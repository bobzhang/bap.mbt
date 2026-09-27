// `bap mc` on MIPS and RISC-V machine code, decoded by the native decoders
// of the `mips` and `riscv` packages (registered in the `@mc` decoder
// table) and lifted by the MIPS lifter and the RISC-V Lisp semantics.

///|
fn register_native_decoders() -> Unit raise {
  @mips.register_decoder()
  @rv.register_decoder()
  guard @riscv_plugin.enable() is Ok(_) else { fail("riscv not enabled") }
}

///|
test "mc decodes and lifts MIPS code" {
  register_native_decoders()
  inspect(
    run_bap([
      "mc", "--arch=mips", "--show-insn=asm", "--show-bil", "--show-kinds", "--",
      "27 bd ff e0 03 e0 00 08",
    ]),
    content=(
      #|addiu $sp, $sp, -32
      #|{
      #|  SP := SP - 0x20
      #|}
      #|jr $ra
      #|{
      #|  jmp RA
      #|}
      #|Indirect_branch
      #|Barrier
      #|Terminator
      #|May_affect_control_flow
      #|
    ),
  )
  // little endian, and MIPS64
  inspect(
    run_bap(["mc", "--arch=mipsel", "--show-insn=asm", "--", "e0 ff bd 27"]),
    content=(
      #|addiu $sp, $sp, -32
      #|
    ),
  )
  inspect(
    run_bap([
      "mc", "--arch=mips64", "--show-insn=asm", "--show-bil", "--", "67 bd ff e0",
    ]),
    content=(
      #|daddiu $sp, $sp, -32
      #|{
      #|  SP := SP + extend:64[0xFFFFFFE0]
      #|}
      #|
    ),
  )
}

///|
test "mc decodes and lifts RISC-V code" {
  register_native_decoders()
  inspect(
    run_bap([
      "mc", "--arch=riscv64", "--show-insn=asm", "--show-bil", "--", "41 11 13 05 15 00 82 80",
    ]),
    content=(
      #|addi sp, sp, -16
      #|{
      #|  X2 := X2 - 0x10
      #|}
      #|addi a0, a0, 1
      #|{
      #|  X10 := X10 + 1
      #|}
      #|ret
      #|{
      #|  jmp (X1 & 0xFFFFFFFFFFFFFFFE)
      #|}
      #|
    ),
  )
  inspect(
    run_bap(["mc", "--arch=riscv32", "--show-insn=asm", "--", "08 61"]),
    content=(
      #|flw fa0, 0(a0)
      #|
    ),
  )
}
