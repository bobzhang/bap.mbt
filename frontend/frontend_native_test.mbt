///|
/// Runs `bap` on the host file system (with all plugins, including the
/// cache) in a fresh temporary directory holding the ELF fixture.
fn native_bap(argv : (String) -> Array[String]) -> (Int, String, String) raise {
  let dir = @fixtures.host_temp_dir_with_elf()
  let file = dir + "/true.elf"
  let buf = StringBuilder()
  let code = @frontend.run(
    ["bap", ..argv(file), "--cache-dir=" + dir + "/cache"],
    out=s => buf.write_string(s),
    err=s => buf.write_string("[err] " + s),
  )
  let text = buf.to_string().replace_all(old=dir, new="<tmp>")
  (code, text, dir)
}

///|
test "bap disassembles a file on the host file system" {
  let (code, out, dir) = native_bap(file => {
    [file, "-dasm", "-dbir:" + file + ".bir"]
  })
  inspect(code, content="0")
  inspect(
    out,
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
  let bir = @fixtures.host_read_file(dir + "/true.elf.bir")
  inspect(bir.length() > 0, content="true")
  @fixtures.host_remove_dir(dir)
}

///|
test "bap specification of a file on the host file system" {
  let (code, out, dir) = native_bap(file => ["specification", file])
  inspect(
    code,
    content=(
      #|0
    ),
  )
  inspect(
    out.contains("(arch x86_64)"),
    content=(
      #|true
    ),
  )
  @fixtures.host_remove_dir(dir)
}

///|
test "bap stores and analyzes the knowledge base" {
  let (code, out, dir) = native_bap(file => {
    [file, "--project=" + file + ".proj", "--update"]
  })
  inspect(code, content="0")
  inspect(out, content="")
  let buf = StringBuilder()
  let code = @frontend.run(
    [
      "bap",
      "analyze",
      "--project=" + dir + "/true.elf.proj",
      "subroutines",
      "--cache-dir=" + dir + "/cache",
    ],
    out=s => buf.write_string(s),
    err=s => buf.write_string("[err] " + s),
  )
  inspect(
    code,
    content=(
      #|0
    ),
  )
  inspect(
    buf.to_string().replace_all(old=dir, new="<tmp>"),
    content=(
      #|<tmp>/true.elf:0x401000: main
      #|<tmp>/true.elf:0x40100e: foo
      #|
    ),
  )
  @fixtures.host_remove_dir(dir)
}

///|
/// Disassembles the host `/usr/bin/true` when it is a Mach-O executable
/// (macOS hosts; a universal binary is loaded as its slice of the host):
/// its function is found with `LC_FUNCTION_STARTS` at the `LC_MAIN` entry.
test "bap disassembles the host /usr/bin/true (Mach-O hosts)" {
  let data = @fixtures.host_read_file("/usr/bin/true") catch { _ => return }
  guard @image.detect_format(data) is Some("macho") else { return }
  let dir = @fixtures.host_temp_dir_with_elf()
  let buf = StringBuilder()
  let code = @frontend.run(
    ["bap", "/usr/bin/true", "-dasm", "--cache-dir=" + dir + "/cache"],
    out=s => buf.write_string(s),
    err=s => buf.write_string("[err] " + s),
  )
  @fixtures.host_remove_dir(dir)
  inspect(code, content="0")
  let out = buf.to_string()
  assert_true(out.contains("Disassembly of section __text"))
  assert_true(out.contains(": <sub_0x"))
  assert_true(!out.contains("[err]"))
}
