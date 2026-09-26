///|
/// The first `n` lines of the text.
fn head(text : String, n : Int) -> String {
  let lines = text.split("\n").map(l => l.to_owned()).collect()
  lines[:if lines.length() < n { lines.length() } else { n }].join("\n")
}

///|
/// The help pages list every plugin option, so only their beginnings are
/// compared.
test "bap --help" {
  inspect(
    head(bap(["--help"]), 12),
    content=(
      #|NAME
      #|       bap-disassemble - disassembles and analyzes the input file
      #|
      #|SYNOPSIS
      #|       bap disassemble [OPTION]... [FILE]
      #|
      #|DESCRIPTION
      #|       Disassembles and analyzes the input file. This is the default command of
      #|       the bap frontend which is assumed when no other command was specified.
      #|
      #|       The input file is automatically parsed (unless the --raw or --loader
      #|       options were specified), then the extracted code, if any, is
    ),
  )
  inspect(
    head(bap(["mc", "--help"]), 8),
    content=(
      #|NAME
      #|       bap-mc - disassembles a (human readable) string of bytes
      #|
      #|SYNOPSIS
      #|       bap mc [OPTION]... [VAL]...
      #|
      #|DESCRIPTION
      #|       Disassembles a (human readable) string of bytes. This command is the BAP
    ),
  )
  inspect(
    head(bap(["--print-help"]), 8),
    content=(
      #|       prints the project in various formats
      #|
    ),
  )
}

///|
test "bap recipes" {
  inspect(bap(["recipes"]), content="")
}

///|
test "bap mc --show-bir" {
  inspect(
    bap(["mc", "--show-insn=asm", "--show-bir", "--", "48 83 ec 08"]),
    content=(
      #|SUB64ri8 RSP, RSP, 0x8
      #|00000001:
      #|00000002: v_1 := RSP
      #|00000003: RSP := RSP - 8
      #|00000004: CF := v_1 < 8
      #|00000005: OF := high:1[(v_1 ^ 8) & (v_1 ^ RSP)]
      #|00000006: AF := 0x10 = (0x10 & (RSP ^ v_1 ^ 8))
      #|00000007: PF :=
      #|          ~low:1[let v_3 = RSP >> 4 ^ RSP in
      #|                 let v_3 = v_3 >> 2 ^ v_3 in v_3 >> 1 ^ v_3]
      #|00000008: SF := high:1[RSP]
      #|00000009: ZF := 0 = RSP
      #|
    ),
  )
}

///|
test "bap mc reads the standard input" {
  inspect(
    bap(["mc", "--show-insn=asm"], stdin="0x31 0xd2"),
    content=(
      #|XOR32rr EDX, EDX
      #|
    ),
  )
}

///|
test "bap reports errors" {
  inspect(
    bap(["bin/false"]),
    content=(
      #|[err] Unable to open file `bin/false'.
      #|[exit 1]
    ),
  )
  inspect(
    bap(["bin/true", "--no-such-option"]),
    content=(
      #|[err] bap: unknown option '--no-such-option'.
      #|Usage: bap disassemble [OPTION]... [FILE]
      #|Try 'bap disassemble --help' or 'bap --help' for more information.
      #|[exit 1]
    ),
  )
  inspect(
    bap(["bin/true", "-pnope"]),
    content=(
      #|[err] Bad invocation: failed to find the pass named "nope", make sure that your plugin is installed
      #|[exit 1]
    ),
  )
}

///|
test "bap list" {
  inspect(
    bap(["list", "formats"]),
    content=(
      #|  Bap.Std.Project:
      #|    symbols (2.6.0-alpha)  print symbol table
      #|    bir (2.6.0-alpha)      print program in IR
      #|    adt (2.6.0-alpha)      print program IR in ADT format
      #|    callgraph (2.6.0-alpha) print program callgraph in DOT format
      #|    cfg (2.6.0-alpha)      print rich CFG for each procedure
      #|    graph (2.6.0-alpha)    print unlabeled CFG for each procedure
      #|    asm (2.6.0-alpha)      print assembly instructions
      #|    asm.adt (2.6.0-alpha)  print assembly instruction endcoded in ADT format
      #|    asm.decoded (2.6.0-alpha) print assembly instructions as it was decoded
      #|    asm.sexp (2.6.0-alpha) print assembly instructions as it was decoded
      #|    bil (2.6.0-alpha)      print BIL instructions
      #|    bil.adt (2.6.0-alpha)  print BIL instructions in ADT format
      #|    bil.sexp (2.6.0-alpha) print BIL instructions in Sexp format
      #|    ogre (2.6.0-alpha)     print the file specification in the OGRE format
      #|  Bap.Std.Program:
      #|    adt (2.6.0-alpha)      Abstract Data Type pretty printing format
      #|  Bap.Std.Sub:
      #|    adt (2.6.0-alpha)      Abstract Data Type pretty printing format
      #|  Bap.Std.Arg:
      #|    adt (2.6.0-alpha)      Abstract Data Type pretty printing format
      #|  Bap.Std.Blk:
      #|    adt (2.6.0-alpha)      Abstract Data Type pretty printing format
      #|  Bap.Std.Phi:
      #|    adt (2.6.0-alpha)      Abstract Data Type pretty printing format
      #|  Bap.Std.Def:
      #|    adt (2.6.0-alpha)      Abstract Data Type pretty printing format
      #|  Bap.Std.Jmp:
      #|    adt (2.6.0-alpha)      Abstract Data Type pretty printing format
      #|
    ),
  )
  inspect(
    bap(["list", "commands", "--filter=command"]),
    content=(
      #|  dependencies             outputs program dependencies such as libraries and symbols
      #|  compare                  compares several alternative versions of the binary with the base
      #|  disassemble              disassembles and analyzes the input file
      #|  objdump                  disassembles and prints a binary using the linear sweep algorithm
      #|  mc                       disassembles a (human readable) string of bytes
      #|  print-recipes            prints available recipes
      #|  recipes                  provides commands to manipulate the recipe subsystem
      #|  specification            displays information about the binary
      #|
    ),
  )
}

///|
test "bap runs passes and Primus" {
  inspect(
    bap(["bin/true", "--run", "--run-entry-points=main", "-dbir"]),
    content=(
      #|00000001: program
      #|00000002: sub main()
      #|
      #|
      #|00000003:
      #|00000004: v_1 := RBP
      #|00000005: RSP := RSP - 8
      #|00000006: mem := mem with [RSP, el]:u64 <- v_1
      #|00000007: RBP := RSP
      #|00000008: RSP := RSP - 8
      #|00000009: mem := mem with [RSP, el]:u64 <- 0x401009
      #|00000010: call @foo with return @0x0000000000401009
      #|
      #|00000011:
      #|00000012: RBP := mem[RSP, el]:u64
      #|00000013: RSP := RSP + 8
      #|00000014: v_1 := mem[RSP, el]:u64
      #|00000015: RSP := RSP + 8
      #|00000016: call v_1 with noreturn
      #|
      #|00000017: sub foo()
      #|
      #|
      #|00000018:
      #|00000019: RAX := 0
      #|00000020: AF := unknown[AF is undefined after xor]:u1
      #|00000021: ZF := 1
      #|00000022: PF := 1
      #|00000023: OF := 0
      #|00000024: CF := 0
      #|00000025: SF := 0
      #|00000026: v_1 := mem[RSP, el]:u64
      #|00000027: RSP := RSP + 8
      #|00000028: call v_1 with noreturn
      #|
    ),
  )
}
