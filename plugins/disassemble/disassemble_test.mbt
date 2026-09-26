///|
fn run_bap(argv : Array[String]) -> String raise {
  @bap_main.reset()
  @bap_main.set_file_system(
    @fixtures.file_system([("bin/true", @fixtures.x86_64_elf())]),
  )
  @project.register_builtin_services() |> ignore
  let buf = StringBuilder()
  @print.declare_plugin()
  @disassemble.declare_plugin(out=s => buf.write_string(s))
  @bap_main.initialize(
    argv=["bap", ..argv],
    default_command="disassemble",
    out=s => buf.write_string(s),
    err=s => buf.write_string(s),
  )
  @bap_main.reset()
  @fixtures.normalize_tids(buf.to_string())
}

///|
test "disassemble dumps the program in the bir format" {
  inspect(
    run_bap(["bin/true", "-dbir"]),
    content=(
      #|00000001: program
      #|00000002: sub main()
      #|
      #|
      #|00000003:
      #|00000004: mem := mem with [RSP - 8, el]:u64 <- RBP
      #|00000005: RSP := RSP - 8
      #|00000006: RBP := RSP
      #|00000007: RSP := RSP - 8
      #|00000008: mem := mem with [RSP, el]:u64 <- 0x401009
      #|00000009: call @foo with return @0x0000000000401009
      #|
      #|00000010:
      #|00000011: RBP := mem[RSP, el]:u64
      #|00000012: RSP := RSP + 8
      #|00000013: ret_addr := mem[RSP, el]:u64
      #|00000014: RSP := RSP + 8
      #|00000015: call ret_addr with noreturn
      #|
      #|00000016: sub sub_0x40100b()
      #|
      #|
      #|00000017:
      #|00000018: call @foo with noreturn
      #|
      #|00000019: sub foo()
      #|
      #|
      #|00000020:
      #|00000021: EAX := 0
      #|00000022: CF := 0
      #|00000023: OF := 0
      #|00000024: AF := unknown[AF undefined after logical operation]:u1
      #|00000025: PF :=
      #|          ~low:1[let parity_tmp1 = EAX >> 4 ^ EAX in
      #|                 let parity_tmp2 = parity_tmp1 >> 2 ^ parity_tmp1 in
      #|                 parity_tmp2 >> 1 ^ parity_tmp2]
      #|00000026: SF := high:1[EAX]
      #|00000027: ZF := 0 = EAX
      #|00000028: ret_addr := mem[RSP, el]:u64
      #|00000029: RSP := RSP + 8
      #|00000030: call ret_addr with noreturn
      #|
    ),
  )
}

///|
fn run_error(argv : Array[String]) -> String {
  try run_bap(argv) catch {
    err => {
      @bap_main.reset()
      @bap_main.error_to_string(err)
    }
  } noraise {
    out => "unexpected success: " + out
  }
}

///|
test "disassemble dumps the assembly and the ogre spec" {
  inspect(
    run_bap(["disassemble", "bin/true", "-dasm"]),
    content=(
      #|
      #|Disassembly of section .text
      #|
      #|401000: <main>
      #|401000:
      #|401000: 55                                        PUSH64r RBP
      #|401001: 48 89 e5                                  MOV64rr RBP, RSP
      #|401004: e8 05 00 00 00                            CALL64pcrel32 0x5 # 40100e <foo>
      #|401009:
      #|401009: 5d                                        POP64r RBP
      #|40100a: c3                                        RET
      #|
      #|40100e: <foo>
      #|40100e:
      #|40100e: 31 c0                                     XOR32rr EAX, EAX
      #|401010: c3                                        RET
      #|
    ),
  )
  inspect(
    run_bap(["bin/true", "--dump=symbols"]),
    content=(
      #|main 
      #|foo 
      #|
    ),
  )
}

///|
test "disassemble reports bad invocations" {
  inspect(
    run_error(["bin/false", "-dbir"]),
    content=(
      #|Unable to open file `bin/false'.
    ),
  )
  inspect(
    run_error(["bin/true", "-dnope"]),
    content=(
      #|The format "nope" is not known.
    ),
  )
  inspect(
    run_error(["bin/true", "-dbir-9.9"]),
    content=(
      #|The selected version of the format "bir" is not supported.
    ),
  )
  inspect(
    run_error(["bin/true", "-pno-such-pass"]),
    content=(
      #|Bad invocation: failed to find the pass named "no-such-pass", make sure that your plugin is installed
    ),
  )
  inspect(
    run_error(["bin/true", "--update"]),
    content=(
      #|Expected the path to an existing knowledge base (either add or remove the --update option)
    ),
  )
}

///|
test "disassemble prints missing instructions" {
  inspect(
    run_bap(["bin/true", "--print-missing"]),
    content=(
      #|
      #|Histogram:
      #|
      #|Lifted:  10
      #|Failed:  0
      #|Missed:  0
      #|
    ),
  )
}

///|
test "disassemble runs passes" {
  inspect(
    run_bap(["bin/true", "-pflatten", "-dbir"]),
    content=(
      #|00000001: program
      #|00000002: sub main()
      #|
      #|
      #|00000003:
      #|00000004: flat_1 := RSP - 8
      #|00000005: flat_2 := mem with [flat_1, el]:u64 <- RBP
      #|00000006: mem := flat_2
      #|00000007: flat_3 := RSP - 8
      #|00000008: RSP := flat_3
      #|00000009: RBP := RSP
      #|00000010: flat_4 := RSP - 8
      #|00000011: RSP := flat_4
      #|00000012: flat_5 := mem with [RSP, el]:u64 <- 0x401009
      #|00000013: mem := flat_5
      #|00000014: call @foo with return @0x0000000000401009
      #|
      #|00000015:
      #|00000016: flat_6 := mem[RSP, el]:u64
      #|00000017: RBP := flat_6
      #|00000018: flat_7 := RSP + 8
      #|00000019: RSP := flat_7
      #|00000020: flat_8 := mem[RSP, el]:u64
      #|00000021: ret_addr := flat_8
      #|00000022: flat_9 := RSP + 8
      #|00000023: RSP := flat_9
      #|00000024: call ret_addr with noreturn
      #|
      #|00000025: sub sub_0x40100b()
      #|
      #|
      #|00000026:
      #|00000027: call @foo with noreturn
      #|
      #|00000028: sub foo()
      #|
      #|
      #|00000029:
      #|00000030: EAX := 0
      #|00000031: CF := 0
      #|00000032: OF := 0
      #|00000033: AF := unknown[AF undefined after logical operation]:u1
      #|00000034: flat_10 := EAX >> 4
      #|00000035: flat_11 := flat_10 ^ EAX
      #|00000036: flat_12 := flat_11 >> 2
      #|00000037: flat_13 := flat_12 ^ flat_11
      #|00000038: flat_14 := flat_13 >> 1
      #|00000039: flat_15 := flat_14 ^ flat_13
      #|00000040: flat_16 := low:1[flat_15]
      #|00000041: flat_17 := ~flat_16
      #|00000042: PF := flat_17
      #|00000043: flat_18 := high:1[EAX]
      #|00000044: SF := flat_18
      #|00000045: flat_19 := 0 = EAX
      #|00000046: ZF := flat_19
      #|00000047: flat_20 := mem[RSP, el]:u64
      #|00000048: ret_addr := flat_20
      #|00000049: flat_21 := RSP + 8
      #|00000050: RSP := flat_21
      #|00000051: call ret_addr with noreturn
      #|
    ),
  )
}

///|
test "disassemble stores and reuses the knowledge base" {
  let files : Map[String, String] = Map([])
  let write_file = (path : String, text : String) => {
    files[path] = text
    Ok(())
  }
  @bap_main.reset()
  @bap_main.set_file_system(
    @fixtures.file_system([("bin/true", @fixtures.x86_64_elf())]),
  )
  @project.register_builtin_services() |> ignore
  let buf = StringBuilder()
  @print.declare_plugin()
  @disassemble.declare_plugin(out=s => buf.write_string(s), write_file~)
  @bap_main.initialize(
    argv=["bap", "bin/true", "--project=a.proj", "--update", "-dasm:out.asm"],
    default_command="disassemble",
    err=s => buf.write_string(s),
  ) catch {
    e => fail(buf.to_string() + @bap_main.error_to_string(e))
  }
  @bap_main.reset()
  inspect(buf.to_string(), content="")
  assert_true(files.contains("a.proj"))
  inspect(files.get("out.asm").unwrap_or("").length() > 0, content="true")
  // the stored project is used instead of the file
  let kb = @utf8.encode(files["a.proj"])
  @bap_main.set_file_system(
    @fixtures.file_system([("bin/true", b""), ("a.proj", kb)]),
  )
  @print.declare_plugin()
  @disassemble.declare_plugin(out=s => buf.write_string(s), write_file~)
  @bap_main.initialize(
    argv=["bap", "bin/true", "-k", "a.proj", "-dasm"],
    default_command="disassemble",
  )
  @bap_main.reset()
  // the section names are not persisted
  let restored = buf.to_string().replace(old=".section@0x401000", new=".text")
  assert_eq(restored, files["out.asm"])
}
