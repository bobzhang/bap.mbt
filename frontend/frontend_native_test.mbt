///|
/// Runs `bap` on the host file system (with all plugins, including the
/// cache) in a fresh temporary directory holding the ELF fixture.
fn native_bap(argv : (String) -> Array[String]) -> (Int, String, String) {
  let tmp = match @env.get_env_var("TMPDIR") {
    Some(dir) if dir != "" => dir
    _ => "/tmp"
  }
  let dir = @native_io.make_temp_dir(dir=tmp, prefix="bap-frontend-").unwrap()
  let file = dir + "/true.elf"
  @native_io.write_file(file, @fixtures.x86_64_elf()).unwrap()
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
  let bir = @native_io.read_file(dir + "/true.elf.bir").unwrap()
  inspect(bir.length() > 0, content="true")
  @native_io.remove_tree(dir) |> ignore
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
  @native_io.remove_tree(dir) |> ignore
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
  @native_io.remove_tree(dir) |> ignore
}
