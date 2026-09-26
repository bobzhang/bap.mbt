///|
/// Runs `bap` over a file system with the Mach-O and PE/COFF fixtures.
fn bap_objects(argv : Array[String]) -> String {
  let buf = StringBuilder()
  let code = @frontend.run(
    ["bap", ..argv],
    fs=@fixtures.file_system([
      ("bin/hello", @objects.x86_64_macho()),
      ("bin/hello-arm64", @objects.arm64_macho()),
      ("bin/universal", @objects.fat_macho()),
      ("bin/hello.exe", @objects.x86_64_pe()),
    ]),
    out=s => buf.write_string(s),
    err=s => buf.write_string("[err] " + s),
    write_file=(path, _) => Err("can't write \{path}"),
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
test "bap disassembles a Mach-O executable" {
  inspect(
    bap_objects(["bin/hello", "-dasm"]),
    content=(
      #|
      #|Disassembly of section __text
      #|
      #|100000400: <_main>
      #|100000400:
      #|100000400: 55                                     pushq %rbp
      #|100000401: 48 89 e5                               movq %rsp, %rbp
      #|100000404: e8 05 00 00 00                         callq 5 # 10000040e <_foo>
      #|100000409:
      #|100000409: 5d                                     popq %rbp
      #|10000040a: c3                                     retq
      #|
      #|10000040e: <_foo>
      #|10000040e:
      #|10000040e: 31 c0                                  xorl %eax, %eax
      #|100000410: c3                                     retq
      #|
      #|100000411: <sub_0x100000411>
      #|100000411:
      #|100000411: e9 02 00 00 00                         jmp 2 # 100000418
      #|100000418:
      #|100000418: ff 25 e2 0b 00 00                      jmpq *3042(%rip)
      #|
      #|Disassembly of section __stubs
      #|
      #|100000411: <sub_0x100000411>
      #|100000411:
      #|100000411: e9 02 00 00 00                         jmp 2 # 100000418
      #|100000418:
      #|100000418: ff 25 e2 0b 00 00                      jmpq *3042(%rip)
      #|
    ),
  )
}

///|
test "bap disassembles an arm64 Mach-O executable" {
  inspect(
    bap_objects(["bin/hello-arm64", "-dasm"]),
    content=(
      #|
      #|Disassembly of section __text
      #|
      #|100000400: <_main>
      #|100000400:
      #|100000400: fd 7b bf a9                            stp x29, x30, [sp, #-16]!
      #|100000404: 03 00 00 94                            bl #12 # 100000410 <_foo>
      #|100000408:
      #|100000408: fd 7b c1 a8                            ldp x29, x30, [sp], #16
      #|10000040c: c0 03 5f d6                            ret
      #|
      #|100000410: <_foo>
      #|100000410:
      #|100000410: 00 00 80 52                            mov w0, #0
      #|100000414: c0 03 5f d6                            ret
      #|
    ),
  )
}

///|
test "bap disassembles the architecture of the target of a universal binary" {
  inspect(
    bap_objects(["bin/universal", "-dasm", "--target=target:aarch64"]),
    content=(
      #|
      #|Disassembly of section __text
      #|
      #|100000400: <_main>
      #|100000400:
      #|100000400: fd 7b bf a9                            stp x29, x30, [sp, #-16]!
      #|100000404: 03 00 00 94                            bl #12 # 100000410 <_foo>
      #|100000408:
      #|100000408: fd 7b c1 a8                            ldp x29, x30, [sp], #16
      #|10000040c: c0 03 5f d6                            ret
      #|
      #|100000410: <_foo>
      #|100000410:
      #|100000410: 00 00 80 52                            mov w0, #0
      #|100000414: c0 03 5f d6                            ret
      #|
    ),
  )
  inspect(
    head(bap_objects(["bin/universal", "-dasm", "--target=target:x86_64"]), 6),
    content=(
      #|
      #|Disassembly of section __text
      #|
      #|100000400: <_main>
      #|100000400:
      #|100000400: 55                                     pushq %rbp
    ),
  )
}

///|
test "bap disassembles a PE executable" {
  inspect(
    bap_objects(["bin/hello.exe", "-dasm"]),
    content=(
      #|
      #|Disassembly of section .text
      #|
      #|140001000: <main>
      #|140001000:
      #|140001000: 55                                     pushq %rbp
      #|140001001: 48 89 e5                               movq %rsp, %rbp
      #|140001004: e8 05 00 00 00                         callq 5 # 14000100e <long_function_foo>
      #|140001009:
      #|140001009: 5d                                     popq %rbp
      #|14000100a: c3                                     retq
      #|
      #|14000100e: <long_function_foo>
      #|14000100e:
      #|14000100e: 31 c0                                  xorl %eax, %eax
      #|140001010: c3                                     retq
      #|
    ),
  )
}

///|
test "bap specification of Mach-O and PE files" {
  let spec = bap_objects(["specification", "bin/hello"])
  inspect(
    spec
    .split("\n")
    .filter(l => {
      l.has_prefix("(format") ||
      l.has_prefix("(entry-point") ||
      l.has_prefix("(code-start")
    })
    .map(l => l.to_owned())
    .collect()
    .join("\n"),
    content=(
      #|(code-start 4294968337)
      #|(code-start 4294968320)
      #|(code-start 4294968334)
      #|(entry-point 4294968320)
      #|(format macho)
    ),
  )
  let spec = bap_objects(["specification", "bin/hello.exe"])
  inspect(
    spec
    .split("\n")
    .filter(l => {
      l.has_prefix("(format") ||
      l.has_prefix("(entry-point") ||
      l.has_prefix("(require")
    })
    .map(l => l.to_owned())
    .collect()
    .join("\n"),
    content=(
      #|(entry-point 5368713216)
      #|(format coff)
      #|(require KERNEL32.dll)
    ),
  )
}

///|
/// Runs `bap` over a file system with the ELF relocatable objects.
fn bap_elf_objects(argv : Array[String]) -> String {
  let buf = StringBuilder()
  let code = @frontend.run(
    ["bap", ..argv],
    fs=@fixtures.file_system([
      ("obj/x86.o", @objects.x86_64_elf_object()),
      ("obj/arm64.o", @objects.aarch64_elf_object()),
      ("obj/riscv.o", @objects.riscv64_elf_object()),
      ("obj/pauth.o", @objects.aarch64_pauth_elf_object()),
    ]),
    out=s => buf.write_string(s),
    err=s => buf.write_string("[err] " + s),
    write_file=(path, _) => Err("can't write \{path}"),
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
/// The subroutines and the calls of the program of `bap <file> -dbir`.
fn bap_elf_object_calls(file : String) -> String {
  bap_elf_objects([file, "-dbir"])
  .split("\n")
  .filter(line => line.contains(": sub ") || line.contains(" call @"))
  .map(line => line.to_owned())
  .to_array()
  .join("\n")
}

///|
test "bap resolves the relocated calls of ELF objects" {
  // the calls go to the relocation targets (not to the placeholder
  // destinations, the next instructions), so the callers are not split
  inspect(
    bap_elf_object_calls("obj/x86.o"),
    content=(
      #|00000002: sub sq(sq_result)
      #|00000017: sub g(g_result)
      #|00000022: call @sq with return @0x000000000000000b
      #|00000035: sub f(f_result)
      #|00000043: call @g with return @0x0000000000000015
      #|00000048: call @ext with return @0x000000000000001c
      #|00000064: sub ext(ext_result)
    ),
  )
  inspect(
    bap_elf_object_calls("obj/arm64.o"),
    content=(
      #|00000002: sub sq(sq_result)
      #|00000007: sub g(g_result)
      #|00000014: call @sq with return @0x0000000000000010
    ),
  )
  inspect(
    bap_elf_object_calls("obj/riscv.o"),
    content=(
      #|00000002: sub sq(sq_result)
      #|00000008: sub g(g_result)
      #|00000016: call @sq with return @0x0000000000000018
    ),
  )
  // the listing shows the destinations of the relocated calls, lifted by
  // the lifters of the targets
  inspect(
    bap_elf_objects(["obj/arm64.o", "-dasm"]),
    content=(
      #|
      #|Disassembly of section .text
      #|
      #|0: <sq>
      #|0:
      #|0: 00 7c 00 1b                                    mul w0, w0, w0
      #|4: c0 03 5f d6                                    ret
      #|
      #|8: <g>
      #|8:
      #|8: fd 7b bf a9                                    stp x29, x30, [sp, #-16]!
      #|c: 00 00 00 94                                    bl #0 # 0 <sq>
      #|10:
      #|10: 00 04 00 11                                   add w0, w0, #1
      #|14: fd 7b c1 a8                                   ldp x29, x30, [sp], #16
      #|18: c0 03 5f d6                                   ret
      #|
    ),
  )
  inspect(
    bap_elf_objects(["obj/x86.o", "-dasm"]),
    content=(
      #|
      #|Disassembly of section .text
      #|
      #|0: <sq>
      #|0:
      #|0: 89 f8                                          movl %edi, %eax
      #|2: 0f af c7                                       imull %edi, %eax
      #|5: c3                                             retq
      #|
      #|6: <g>
      #|6:
      #|6: e8 00 00 00 00                                 callq 0 # 0 <sq>
      #|b:
      #|b: 83 c0 01                                       addl $1, %eax
      #|e: c3                                             retq
      #|
      #|f: <f>
      #|f:
      #|f: 53                                             pushq %rbx
      #|10: e8 00 00 00 00                                callq 0 # 6 <g>
      #|15:
      #|15: 89 c3                                         movl %eax, %ebx
      #|17: e8 00 00 00 00                                callq 0
      #|1c:
      #|1c: 01 d8                                         addl %ebx, %eax
      #|1e: 5b                                            popq %rbx
      #|1f: c3                                            retq
      #|
    ),
  )
}

///|
test "bap keeps the blocks that lead to a return without semantics" {
  // the arm64e `retab` has no semantics: it must end its block rather than
  // fall through past the end of the code, which reverted the blocks that
  // led to it (the fall-through of the `cbz`)
  inspect(
    bap_elf_objects(["obj/pauth.o", "-dasm"]),
    content=(
      #|
      #|Disassembly of section .text
      #|
      #|0: <f>
      #|0:
      #|0: 7f 23 03 d5                                    pacibsp
      #|4: 60 00 00 34                                    cbz w0, #12 # 10
      #|8:
      #|8: 20 00 80 52                                    mov w0, #1
      #|c: ff 0f 5f d6                                    retab
      #|10:
      #|10: 40 00 80 52                                   mov w0, #2
      #|14: ff 0f 5f d6                                   retab
      #|
    ),
  )
}
