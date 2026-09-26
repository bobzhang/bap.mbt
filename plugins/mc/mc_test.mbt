///|
fn run_bap(argv : Array[String], stdin? : String) -> String raise {
  @bap_main.reset()
  @bap_main.set_file_system(
    @fixtures.file_system([("bin/true", @fixtures.x86_64_elf())]),
  )
  @project.register_builtin_services() |> ignore
  let buf = StringBuilder()
  @mc.declare_plugin(out=s => buf.write_string(s), read_line=() => stdin)
  @bap_main.initialize(argv=["bap", ..argv], out=s => buf.write_string(s), err=s => {
    buf.write_string(s)
  }) catch {
    e => {
      @bap_main.reset()
      return buf.to_string() + @bap_main.error_to_string(e)
    }
  }
  @bap_main.reset()
  @fixtures.normalize_tids(buf.to_string())
}

///|
test "mc prints the BIL of x86-64 instructions" {
  inspect(
    run_bap(["mc", "--show-bil", "--", "48 83 ec 08"]),
    content=(
      #|{
      #|  sub_dst := RSP
      #|  sub_src := 8
      #|  RSP := sub_dst - sub_src
      #|  CF := sub_dst < sub_src
      #|  OF := high:1[(sub_dst ^ sub_src) & (sub_dst ^ RSP)]
      #|  AF := 4:4[RSP ^ sub_dst ^ sub_src]
      #|  PF :=
      #|    ~low:1[let parity_tmp1 = RSP >> 4 ^ RSP in
      #|           let parity_tmp2 = parity_tmp1 >> 2 ^ parity_tmp1 in parity_tmp2 >>
      #|           1 ^ parity_tmp2]
      #|  SF := high:1[RSP]
      #|  ZF := 0 = RSP
      #|}
      #|
    ),
  )
  inspect(
    run_bap(["mc", "--show-insn", "--show-bil", "--", "31d2"]),
    content=(
      #|XOR32rr(EDX,EDX)
      #|{
      #|  EDX := 0
      #|  CF := 0
      #|  OF := 0
      #|  AF := unknown[AF undefined after logical operation]:u1
      #|  PF :=
      #|    ~low:1[let parity_tmp1 = EDX >> 4 ^ EDX in
      #|           let parity_tmp2 = parity_tmp1 >> 2 ^ parity_tmp1 in parity_tmp2 >>
      #|           1 ^ parity_tmp2]
      #|  SF := high:1[EDX]
      #|  ZF := 0 = EDX
      #|}
      #|
    ),
  )
}

///|
test "mc accepts the input formats" {
  for
    input in [
      ["0x31", "0xd2"],
      ["\\x31\\xd2"],
      ["31", "d2"],
      ["31d2"],
      ["0x31 0xd2"],
    ] {
    inspect(
      run_bap(["mc", "--show-insn=asm", "--", ..input]),
      content="XOR32rr EDX, EDX\n",
    )
  }
  inspect(
    run_bap(["mc", "--show-insn=asm"], stdin="31 d2\n"),
    content="XOR32rr EDX, EDX\n",
  )
}

///|
test "mc prints the IR, addresses, sizes, memory, and kinds" {
  inspect(
    run_bap([
      "mc", "--show-addr", "--show-size", "--show-memory", "--show-kinds", "--show-bir",
      "--address=0x1000", "--", "c3",
    ]),
    content=(
      #|1000: c3 
      #|0x1000:64u:
      #|0x1
      #|00000001:
      #|00000002: ret_addr := mem[RSP, el]:u64
      #|00000003: RSP := RSP + 8
      #|00000004: goto ret_addr
      #|Return
      #|Barrier
      #|Terminator
      #|May_affect_control_flow
      #|
    ),
  )
}

///|
test "mc reports errors" {
  inspect(
    run_bap(["mc", "--show-insn"]),
    content=(
      #|No input was received
    ),
  )
  inspect(
    run_bap(["mc", "--show-insn", "--", "zz"]),
    content=(
      #|Could not parse: malformed input
    ),
  )
  inspect(
    run_bap(["mc", "--show-insn=nope", "--", "c3"]),
    content=(
      #|Unknown printer nope for Bap.Std.Insn, expecting: asm
      #|  adt
      #|  pretty
      #|  sexp
    ),
  )
  inspect(
    run_bap(["mc", "--show-size=x", "--", "c3"]),
    content=(
      #|--show-size doesn't expect any formats yet
    ),
  )
  inspect(
    run_bap(["mc", "--arch=x86", "--triple=i386", "--", "c3"]),
    content=(
      #|The target, triple, and arch options could not be used together
    ),
  )
  inspect(
    run_bap(["mc", "--show-insn", "--", "c3 0f"]),
    content=(
      #|RET64()
      #|the last byte wasn't disassembled
    ),
  )
  inspect(
    run_bap(["mc", "--show-insn", "--only-one", "--", "c3 c3"]),
    content=(
      #|RET64()
      #|
    ),
  )
  inspect(
    run_bap(["mc", "--show-insn", "--stop-on-errors", "--", "0f"]),
    content=(
      #|Invalid instruction at offset 0:
      #|00000000 (0F)                                             |.               |
      #|
    ),
  )
}

///|
test "objdump disassembles the code segments" {
  inspect(
    run_bap(["objdump", "bin/true", "--show-addr", "--show-insn=asm"]),
    content=(
      #|0x401000:64u:
      #|PUSH64r RBP
      #|0x401001:64u:
      #|MOV64rr RBP, RSP
      #|0x401004:64u:
      #|CALL64pcrel32 0x5
      #|0x401009:64u:
      #|POP64r RBP
      #|0x40100A:64u:
      #|RET
      #|0x40100B:64u:
      #|NOOP
      #|0x40100C:64u:
      #|NOOP
      #|0x40100D:64u:
      #|NOOP
      #|0x40100E:64u:
      #|XOR32rr EAX, EAX
      #|0x401010:64u:
      #|RET
      #|
    ),
  )
}
