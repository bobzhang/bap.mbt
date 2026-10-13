///|
fn addr_attr(n : Int32) -> @types.Attr raise {
  @types.Attr::address(@types.Word::of_int(width=64, n))
}

///|
fn sample_program() -> @types.Term[@types.Program] raise {
  let rax = @types.Var::new(name="RAX", typ=Imm(64))
  let def = @types.Def::create(rax, Int(@types.Word::of_int(width=64, 1)))
    .set_attr(addr_attr(0x400004))
    .set_attr(@types.Attr::color(IrRed))
    .set_attr(@types.Attr::comment("it's $5 \\ ok"))
    .set_attr(@types.Attr::foreground(IrBlue))
  let jmp = @types.Jmp::create_ret(Indirect(Var(rax)))
    .set_attr(addr_attr(0x400008))
    .set_attr(@types.Attr::background(IrGray))
  let blk = @types.Blk::create(defs=[def], jmps=[jmp]).set_attr(
    @types.Attr::comment("block of $sub_name"),
  )
  let sub = @types.Sub::create(name="main", blks=[blk])
    .set_attr(addr_attr(0x400000))
    .set_attr(@types.Attr::color(IrGreen))
  // a term without an address is skipped
  let stub = @types.Sub::create(name="stub").set_attr(
    @types.Attr::color(IrYellow),
  )
  @types.Program::create(subs=[sub, stub])
}

///|
test "the script contains the selected attributes" {
  let program = sample_program()
  let memory = @memory.MemMap::singleton(
    @memory.Memory::from_bytes(endian=LittleEndian, start=0x400000UL, b"\x90"),
    "python=ida.make_code(0x400000)\n",
  )
  inspect(
    @emit_ida_script.extract_script(memory, program, [
      "color", "comment", "foreground", "background",
    ]),
    content=(
      #|
      #|from bap.utils import ida
      #|ida.make_code(0x400000)
      #|ida.set_color(0x400004, 0xccccff)
      #|ida.comment.add(0x400004, 'comment', 'it\'s $5 \\ ok')
      #|ida.comment.add(0x400004, 'foreground', 'blue')
      #|ida.comment.add(0x400008, 'background', 'gray')
      #|ida.comment.add(0x400008, 'comment', 'block of $sub_name')
      #|ida.set_color(0x400008, 0x99ff99)
      #|
      #|# eplogue code if needed
      #|
    ),
  )
  inspect(
    @emit_ida_script.extract_script(@memory.MemMap::empty(), program, ["color"]),
    content=(
      #|
      #|from bap.utils import ida
      #|ida.set_color(0x400004, 0xccccff)
      #|ida.set_color(0x400008, 0x99ff99)
      #|
      #|# eplogue code if needed
      #|
    ),
  )
}

///|
test "substitutions follow Buffer.add_substitute" {
  let f = (s : String) => "<\{s}>"
  let run = (s : String) => {
    let buf = StringBuilder()
    @emit_ida_script.add_substitute(buf, f, s)
    buf.to_string()
  }
  assert_eq(run("a $x b"), "a <x> b")
  assert_eq(run("${long name}.$(y)z"), "<long name>.<y>z")
  assert_eq(run("\\$x \\n \\"), "$x \\n \\")
  assert_eq(run("$1abc!"), "<1abc>!")
  assert_eq(run("end$"), "end$")
}

///|
test "python code of attributes" {
  assert_eq(
    @emit_ida_script.python_of_attr("color", "magenta"),
    "ida.set_color($addr, 0xffb2ff)",
  )
  assert_eq(
    @emit_ida_script.python_of_attr("color", "not-a-color"),
    "ida.comment.add($addr, 'color', 'not-a-color')",
  )
  assert_eq(@emit_ida_script.idacode_of_color(IrBlack), 0)
}

///|
test "the pass writes the script" {
  let program = sample_program()
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_program(
    program,
  )
  let out = StringBuilder()
  @emit_ida_script.register(attrs=["color"], out=s => out.write_string(s)).unwrap()
  // registering again updates the configuration of the same pass
  @emit_ida_script.register(attrs=["background"], out=s => out.write_string(s)).unwrap()
  assert_true(
    @project.passes()
    .filter(p => p.name() == @emit_ida_script.pass_name)
    .length() ==
    1,
  )
  guard @project.find_pass(@emit_ida_script.pass_name) is Some(pass) else {
    fail("the pass is not registered")
  }
  assert_true(pass.run(project) is Ok(_))
  inspect(
    out.to_string(),
    content=(
      #|
      #|from bap.utils import ida
      #|ida.comment.add(0x400008, 'background', 'gray')
      #|
      #|# eplogue code if needed
      #|
    ),
  )
}

///|
test "the plugin is declared in the bap_main framework" {
  @bap_main.reset()
  @bap_main.set_file_system(@bap_main.FileSystem::in_memory(files=[]))
  @emit_ida_script.declare_plugin()
  @bap_main.initialize(argv=["bap", "--emit-ida-script-attr=color"])
  assert_eq(@bap_main.loaded_plugins(), ["emit-ida-script"])
  assert_true(@project.find_pass(@emit_ida_script.pass_name) is Some(_))
  @bap_main.reset()
}
