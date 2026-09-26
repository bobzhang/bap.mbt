///|
/// Runs `bap` with an in-memory file system holding the ELF fixture.
fn bap(argv : Array[String], stdin? : String) -> String {
  let buf = StringBuilder()
  let code = @frontend.run(
    ["bap", ..argv],
    fs=@fixtures.file_system([("bin/true", @fixtures.x86_64_elf())]),
    out=s => buf.write_string(s),
    err=s => buf.write_string("[err] " + s),
    read_line=() => stdin,
    write_file=(path, _) => Err("can't write \{path}"),
    // the cache plugin needs the host file system
    plugins=@frontend.plugin_table().filter(p => p.name != "cache"),
  )
  let out = @fixtures.normalize_tids(buf.to_string())
  if code == 0 {
    out
  } else {
    out + "[exit \{code}]"
  }
}

///|
test "bap --version" {
  inspect(
    bap(["--version"]),
    content=(
      #|2.6.0-alpha
      #|
    ),
  )
}

///|
test "bap without arguments prints the usage" {
  inspect(
    bap([]),
    content=(
      #|
      #|Usage:
      #|  bap <COMMAND> [<OPTIONS>]
      #|
      #|Common options:
      #|  --version                prints the version number and exits;
      #|  --plugin-path <DIR>      adds <DIR> to the plugins search path;
      #|  --logdir <DIR>           creates a log file in <DIR>;
      #|  --recipe <VAL>           extracts command line arguments from the recipe.
      #|
      #|Commands:
      #|  analyze                  analyses the knowledge base
      #|  config                   prints BAP configuration
      #|  list                     explores various BAP facilities
      #|  .                        does nothing and prints nothing
      #|  dependencies             outputs program dependencies such as libraries and symbols
      #|  compare                  compares several alternative versions of the binary with the base
      #|  disassemble              disassembles and analyzes the input file
      #|  objdump                  disassembles and prints a binary using the linear sweep algorithm
      #|  mc                       disassembles a (human readable) string of bytes
      #|  match-patterns           run the specified patterns file on the input file and prints the matches
      #|  primus-observations      prints a list of Primus observations
      #|  primus-components        prints a list of Primus components
      #|  primus-systems           prints a list of Primus systems
      #|  print-recipes            prints available recipes
      #|  recipes                  provides commands to manipulate the recipe subsystem
      #|  specification            displays information about the binary
      #|
      #|Plugins:
      #|  analyze                  analyses the knowledge base
      #|  beagle                   beagle is an obfuscated string solver that uses CPU emulation for
      #|  bil                      defines the semantics of BAP Instruction Language (BIL) and makes old
      #|  byteweight               identifies function starts using byteweight signatures
      #|  callgraph-collator       compares projects by their callgraphs
      #|  callsites                annotates callsites with subroutines arguments
      #|  constant-tracker         a constant tracking analysis based on Primus
      #|  dependencies             outputs program dependencies such as libraries and symbols
      #|  disassemble              disassembles and analyzes the input file
      #|  dump-symbols             dumps functions as a sexp-list of blocks
      #|  emit-ida-script          generates IDA Python scripts
      #|  glibc-runtime            enables ad-hoc support for glibc runtime code
      #|  mc                       provides mc and objdump commands
      #|  optimization             removes dead code and propagates constants
      #|  patterns                 applies semantic actions to the matching byte patterns
      #|  phoenix                  outputs the project in a phoenix format
      #|  primus-approximation     provides approximations of elementary functions to Primus Lisp
      #|  primus-dictionary        provides a Primus Lisp key-value storage library
      #|  primus-exploring         evaluates all Primus machines, prioritizing the least visited
      #|  primus-greedy            schedules Primus machines in the DFS order
      #|  primus-limit             ensures termination by limiting Primus machines
      #|  primus-lisp              loads and manages Primus Lisp sources
      #|  primus-loader            generic Primus dynamic loader
      #|  primus-mark-visited      provides the bap:mark-visited and bap:report-visited components
      #|  primus-powerpc           provides PPC Primus support package
      #|  primus-print             prints Primus states and observations
      #|  primus-promiscuous       enables the promiscuous mode of execution
      #|  primus-propagate-taint   a compatibility layer between different taint analysis frameworks
      #|  primus-random            provides components for Primus state randomization and controls their
      #|  primus-region            provides Primus Lisp library for manipulating program regions
      #|  primus-round-robin       schedules Primus machines in the BFS order
      #|  primus-systems           loads Primus systems and registers them in the system repository
      #|  primus-taint             a taint analysis control interface
      #|  primus-test              provides primitives for Primus Tesing and Verification Framework
      #|  primus-wandering         schedules Primus machines in a random order
      #|  primus-x86               x86 Primus Support package
      #|  print                    prints the project in various formats
      #|  propagate-taint          propagates taint with the microexecution
      #|  read-symbols             provides functions addresses and (optionally) names from a user specified
      #|  recipe-command           provides the recipe command
      #|  relocatable              extracts symbolic information from the program relocations
      #|  report                   reports program status using progress bars
      #|  riscv                    provides RISCV semantics
      #|  run                      emulates the program using Primus
      #|  specification            provides the specification command
      #|  strings                  searches in binaries for string-like artifacts
      #|  taint                    marks terms as taint sources
      #|  trace                    manages execution traces
      #|  warn-unused              the legacy warn-unused analysis
      #|
      #|If no command line options or arguments are specified, then this
      #|message is printed. To hush this message specify the `.' command,
      #|e.g., `bap .'. The command could be omitted altogether, in that case the
      #|`disassemble' command is assumed, e.g., `bap /bin/ls' is the same
      #|as `bap disassemble /bin/ls'. Not that the default command is
      #|subject to change, so it is better not to rely on this behavior in
      #|your automation tools.
      #|
      #|Run 'bap <COMMAND> --help' for more information a command.
      #|Run 'bap --<PLUGIN>-help for more information about a plugin.
      #|Run 'bap --help' for the detailed manual.
      #|
    ),
  )
}

///|
test "bap mc" {
  inspect(
    bap(["mc", "--show-bil", "--", "48 83 ec 08"]),
    content=(
      #|{
      #|  v_1 := RSP
      #|  RSP := RSP - 8
      #|  CF := v_1 < 8
      #|  OF := high:1[(v_1 ^ 8) & (v_1 ^ RSP)]
      #|  AF := 0x10 = (0x10 & (RSP ^ v_1 ^ 8))
      #|  PF :=
      #|    ~low:1[let v_3 = RSP >> 4 ^ RSP in
      #|           let v_3 = v_3 >> 2 ^ v_3 in v_3 >> 1 ^ v_3]
      #|  SF := high:1[RSP]
      #|  ZF := 0 = RSP
      #|}
      #|
    ),
  )
}

///|
test "bap disassemble" {
  inspect(
    bap(["disassemble", "bin/true", "-dbir"]),
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
  inspect(
    bap(["bin/true", "-dasm"]),
    content=(
      #|
      #|Disassembly of section .text
      #|
      #|401000: <main>
      #|401000:
      #|401000: 55                                        pushq %rbp
      #|401001: 48 89 e5                                  movq %rsp, %rbp
      #|401004: e8 05 00 00 00                            callq 5 # 40100e <foo>
      #|401009:
      #|401009: 5d                                        popq %rbp
      #|40100a: c3                                        retq
      #|
      #|40100e: <foo>
      #|40100e:
      #|40100e: 31 c0                                     xorl %eax, %eax
      #|401010: c3                                        retq
      #|
    ),
  )
}

///|
test "bap specification" {
  inspect(
    bap(["specification", "bin/true"]),
    content=(
      #|(declare abi (name str))
      #|(declare arch (name str))
      #|(declare bits (size int))
      #|(declare code-start (addr int))
      #|(declare entry-point (addr int))
      #|(declare format (name str))
      #|(declare is-little-endian (flag bool))
      #|(declare llvm:code-entry (name str) (off int) (size int))
      #|(declare llvm:elf-program-header (name str) (off int) (size int))
      #|(declare llvm:elf-program-header-flags (name str) (ld bool) (r bool) 
      #| (w bool) (x bool))
      #|(declare llvm:elf-virtual-program-header (name str) (addr int) (size int))
      #|(declare llvm:entry-point (addr int))
      #|(declare llvm:section-entry (name str) (addr int) (size int) (off int))
      #|(declare llvm:section-flags (name str) (r bool) (w bool) (x bool))
      #|(declare mapped (addr int) (size int) (off int))
      #|(declare named-region (addr int) (size int) (name str))
      #|(declare named-symbol (addr int) (name str))
      #|(declare section (addr int) (size int))
      #|(declare segment (addr int) (size int) (r bool) (w bool) (x bool))
      #|(declare symbol-chunk (addr int) (size int) (root int))
      #|
      #|(abi sysv)
      #|(arch x86_64)
      #|(bits 64)
      #|(code-start 4198400)
      #|(code-start 4198414)
      #|(entry-point 4198400)
      #|(format elf)
      #|(is-little-endian true)
      #|(llvm:code-entry .text 4096 17)
      #|(llvm:elf-program-header 00 4096 17)
      #|(llvm:elf-program-header-flags 00 true true false true)
      #|(llvm:elf-virtual-program-header 00 4198400 17)
      #|(llvm:entry-point 4198400)
      #|(llvm:section-entry .shstrtab 0 33 4195)
      #|(llvm:section-entry .strtab 0 10 4185)
      #|(llvm:section-entry .symtab 0 72 4113)
      #|(llvm:section-entry .text 4198400 17 4096)
      #|(llvm:section-flags .shstrtab true false false)
      #|(llvm:section-flags .strtab true false false)
      #|(llvm:section-flags .symtab true false false)
      #|(llvm:section-flags .text true false true)
      #|(mapped 4198400 17 4096)
      #|(named-region 4198400 17 .load0)
      #|(named-region 4198400 17 .text)
      #|(named-region 0 72 .symtab)
      #|(named-region 0 10 .strtab)
      #|(named-region 0 33 .shstrtab)
      #|(named-symbol 4198400 main)
      #|(named-symbol 4198414 foo)
      #|(section 4198400 17)
      #|(section 0 72)
      #|(section 0 10)
      #|(section 0 33)
      #|(segment 4198400 17 true false true)
      #|(symbol-chunk 4198400 11 4198400)
      #|(symbol-chunk 4198414 3 4198414)
      #|
      #|
    ),
  )
}

///|
test "bap list and config" {
  inspect(
    bap(["list"]),
    content=(
      #|  entities                 prints this message
      #|  plugins                  installed BAP plugins
      #|  commands                 bap utility commands
      #|  recipes                  installed recipes
      #|  features                 plugin capabilities
      #|  passes                   disassembler passes
      #|  formats                  data output formats
      #|  classes                  knowledge representation classes
      #|  theories                 installed theories
      #|  agents                   knowledge providers
      #|  rules                    knowledge base rules
      #|  collators                project collators (comparators)
      #|
    ),
  )
  inspect(
    bap(["list", "passes"]),
    content=(
      #|  ssa
      #|  destroy-ssa
      #|  flatten
      #|  trivial-condition-form
      #|  stub-resolver
      #|  beagle
      #|  abi
      #|  callsites
      #|  dump-symbols
      #|  emit-ida-script
      #|  glibc-runtime
      #|  phoenix
      #|  propagate-taint
      #|  relocatable
      #|  run
      #|  strings-collect
      #|  strings
      #|  warn-unused-taint
      #|  warn-unused-print
      #|  warn-unused-mark
      #|  warn-unused
      #|
    ),
  )
  inspect(
    bap(["config", "version"]),
    content=(
      #|2.6.0-alpha
      #|
    ),
  )
  inspect(
    bap(["."]),
    content=(
      #|
    ),
  )
}
