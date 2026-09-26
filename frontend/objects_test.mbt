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
      #|100000400: 55                                     PUSH64r RBP
      #|100000401: 48 89 e5                               MOV64rr RBP, RSP
      #|100000404: e8 05 00 00 00                         CALL64pcrel32 0x5 # 10000040e <_foo>
      #|100000409:
      #|100000409: 5d                                     POP64r RBP
      #|10000040a: c3                                     RET
      #|
      #|10000040e: <_foo>
      #|10000040e:
      #|10000040e: 31 c0                                  XOR32rr EAX, EAX
      #|100000410: c3                                     RET
      #|
      #|100000411: <sub_0x100000411>
      #|100000411:
      #|100000411: e9 02 00 00 00                         jmp 0x2 # 100000418
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
      #|100000404: 03 00 00 94                            bl #12 # <_foo>
      #|100000408:
      #|100000408: fd 7b c1 a8                            ldp x29, x30, [sp], #16
      #|10000040c: c0 03 5f d6                            ret
      #|
      #|100000410: <_foo>
      #|100000410:
      #|100000410: 00 00 80 52                            movz w0, #0
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
      #|100000404: 03 00 00 94                            bl #12 # <_foo>
      #|100000408:
      #|100000408: fd 7b c1 a8                            ldp x29, x30, [sp], #16
      #|10000040c: c0 03 5f d6                            ret
      #|
      #|100000410: <_foo>
      #|100000410:
      #|100000410: 00 00 80 52                            movz w0, #0
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
      #|100000400: 55                                     PUSH64r RBP
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
      #|140001000: 55                                     PUSH64r RBP
      #|140001001: 48 89 e5                               MOV64rr RBP, RSP
      #|140001004: e8 05 00 00 00                         CALL64pcrel32 0x5 # 14000100e <long_function_foo>
      #|140001009:
      #|140001009: 5d                                     POP64r RBP
      #|14000100a: c3                                     RET
      #|
      #|14000100e: <long_function_foo>
      #|14000100e:
      #|14000100e: 31 c0                                  XOR32rr EAX, EAX
      #|140001010: c3                                     RET
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
