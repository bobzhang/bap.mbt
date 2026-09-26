///|
/// The knowledge base of the fixture, created with `disassemble`.
fn knowledge_base() -> Bytes raise {
  @bap_main.set_file_system(
    @fixtures.file_system([("bin/true", @fixtures.x86_64_elf())]),
  )
  @project.register_builtin_services() |> ignore
  let files : Map[String, String] = Map([])
  @disassemble.create_and_process(
    "bin/true",
    update=true,
    knowledge=Some("a.proj"),
    out=_ => (),
    write_file=(path, text) => {
      files[path] = text
      Ok(())
    },
  )
  |> ignore
  @utf8.encode(files["a.proj"])
}

///|
fn run_bap(argv : Array[String], stdin? : Array[String] = []) -> String {
  let buf = StringBuilder()
  let lines = stdin.copy()
  try {
    let kb = knowledge_base()
    @bap_main.reset()
    @bap_main.set_file_system(
      @fixtures.file_system([
        ("a.proj", kb),
        ("cmds.txt", @utf8.encode("units\nsubroutines :matches f\n")),
      ]),
    )
    @analyze.declare_plugin(
      out=s => buf.write_string(s),
      err=s => buf.write_string("[err] " + s),
      read_line=() => {
        if lines.is_empty() {
          None
        } else {
          Some(lines.remove(0))
        }
      },
    )
    @bap_main.initialize(argv=["bap", ..argv], out=s => buf.write_string(s), err=s => {
      buf.write_string(s)
    })
  } catch {
    e => buf.write_string("[error] " + @bap_main.error_to_string(e))
  }
  @bap_main.reset()
  buf.to_string()
}

///|
test "analyze runs the core commands" {
  inspect(
    run_bap(["analyze", "units", "subroutines", "subroutine bin/true foo"]),
    content=(
      #|bin/true                                 target:x86_64
      #|bin/true:0x401000: main
      #|bin/true:0x40100e: foo
      #|bin/true:0x40100e
      #|bin/true:0x401010
      #|
    ),
  )
  inspect(
    run_bap(["analyze", "instruction 0x40100e", "instructions :semantics asm"]),
    content=(
      #|((bap:insn (XOR32rr(EAX,EAX)))
      #| (bap:asm "XOR32rr EAX, EAX")
      #| (bap:bil "{
      #|  RAX := 0
      #|  CF := 0
      #|  OF := 0
      #|  AF := unknown[AF undefined after logical operation]:u1
      #|  PF :=
      #|    ~low:1[let parity_tmp1 = low:32[RAX] >> 4 ^ low:32[RAX] in
      #|           let parity_tmp2 = parity_tmp1 >> 2 ^ parity_tmp1 in parity_tmp2 >>
      #|           1 ^ parity_tmp2]
      #|  SF := high:1[low:32[RAX]]
      #|  ZF := 0 = low:32[RAX]
      #|}")
      #| (bap:insn-code "40100e: 31 c0 "))
      #|bin/true:0x401000
      #|((bap:asm "PUSH64r RBP"))
      #|bin/true:0x401001
      #|((bap:asm "MOV64rr RBP, RSP"))
      #|bin/true:0x401004
      #|((bap:asm "CALL64pcrel32 0x5"))
      #|bin/true:0x401009
      #|((bap:asm "POP64r RBP"))
      #|bin/true:0x40100a
      #|((bap:asm "RET"))
      #|bin/true:0x40100b
      #|((bap:asm "NOOP"))
      #|bin/true:0x40100c
      #|((bap:asm "NOOP"))
      #|bin/true:0x40100d
      #|((bap:asm "NOOP"))
      #|bin/true:0x40100e
      #|((bap:asm "XOR32rr EAX, EAX"))
      #|bin/true:0x401010
      #|((bap:asm "RET"))
      #|
    ),
  )
}

///|
test "analyze runs the directives" {
  inspect(
    run_bap(["analyze", "commands", "directives"]),
    content=(
      #|bap:instruction                          prints the instruction semantics
      #|bap:instructions                         prints all instructions
      #|bap:units                                prints all units
      #|bap:subroutines                          prints all subroutines
      #|bap:subroutine                           prints a subroutine
      #|clear                                    clears the screen
      #|commands                                 lists known commands
      #|directives                               lists directives
      #|help                                     prints the help message
      #|in-package                               sets the default package
      #|quit                                     quits the interactive session
      #|save                                     saves the knowledge base on disk
      #|
    ),
  )
  inspect(
    run_bap(["analyze", "help units"]),
    content=(
      #|SYNOPSIS
      #|
      #|units 
      #|
      #|DESCRIPTION
      #|Prints all units. Prints all units stored in the knowledge base.
      #|
    ),
  )
}

///|
test "analyze runs a script" {
  inspect(
    run_bap(["analyze", "--script=cmds.txt"]),
    content=(
      #|bin/true                                 target:x86_64
      #|bin/true:0x40100e: foo
      #|
    ),
  )
}

///|
test "analyze reports errors" {
  inspect(
    run_bap(["analyze", "nope"]),
    content=(
      #|[error] Can't find a command "nope" in the package "bap"
    ),
  )
  inspect(
    run_bap(["analyze", "quit now"]),
    content=(
      #|[error] Error: doesn't accept arguments
    ),
  )
}

///|
test "analyze reads the commands from the input" {
  inspect(
    run_bap(["analyze"], stdin=["units", "nope", "in-package user", "quit"]),
    content=(
      #|bap> bin/true                                 target:x86_64
      #|bap> [err] Can't find a command "nope" in the package "bap"
      #|bap> user> 
    ),
  )
}
