///|
fn rdi() -> @types.Var {
  @types.Var::new(name="RDI", typ=Imm(64))
}

///|
fn word64(value : Int) -> @types.Word raise {
  @types.Word::of_int(width=64, value)
}

///|
fn names(prog : @types.Term[@types.Program]) -> Array[String] {
  prog.subs().map(sub => "\{sub.sub_name()}/\{sub.arg_count()}")
}

///|
/// `_start` calls `callee` from its first block and passes `0x1000` in RDI.
fn start_program(
  first : @types.Term[@types.Jmp],
) -> @types.Term[@types.Program] raise {
  let entry = @types.Blk::create(
    tid=@types.Tid::for_name("start_entry"),
    defs=[@types.Def::create(rdi(), @types.Exp::int(word64(0x1000)))],
    jmps=[first],
  )
  let start = @types.Sub::create(
    name="_start",
    blks=[entry],
    tid=@types.Tid::for_name("_start"),
  ).with_entry_point()
  let callee = @types.Sub::create(
    name="sub_2000",
    args=[@types.Arg::create(rdi(), @types.Exp::var_exp(rdi()), intent=In)],
    tid=@types.Tid::for_name("sub_2000"),
  )
  let main = @types.Sub::create(
    name="sub_1000",
    tid=@types.Tid::for_name("sub_1000"),
  ).set_attr(@types.Attr::address(word64(0x1000)))
  @types.Program::create(subs=[start, callee, main])
}

///|
fn direct_call(tid : @types.Tid) -> @types.Term[@types.Jmp] {
  @types.Jmp::create_call(@types.Call::create(target=@types.Label::direct(tid)))
}

///|
test "__libc_start_main is the direct callee of the entry point" {
  let prog = start_program(direct_call(@types.Tid::for_name("sub_2000")))
  let renamed = @glibc_runtime.rename_libc_start_main(prog)
  debug_inspect(
    names(renamed),
    content=(
      #|["_start/0", "__libc_start_main/0", "sub_1000/0"]
    ),
  )
  // idempotent once the subroutine exists
  debug_inspect(
    names(@glibc_runtime.rename_libc_start_main(renamed)),
    content=(
      #|["_start/0", "__libc_start_main/0", "sub_1000/0"]
    ),
  )
}

///|
test "__libc_start_main is synthesized when the entry jumps" {
  let prog = start_program(
    @types.Jmp::create_goto(
      @types.Label::direct(@types.Tid::for_name("sub_2000")),
    ),
  )
  let renamed = @glibc_runtime.rename_libc_start_main(prog)
  debug_inspect(
    names(renamed),
    content=(
      #|["_start/0", "sub_2000/1", "sub_1000/0", "__libc_start_main/0"]
    ),
  )
  let entry = renamed.subs()[0].blks()[0]
  inspect(
    entry.jmps().map(j => j.jmp_to_string()).join("; "),
    content="call @__libc_start_main with noreturn",
  )
}

///|
test "main is recovered from the first argument of __libc_start_main" {
  let prog = start_program(direct_call(@types.Tid::for_name("sub_2000")))
  let with_start = prog.change_sub(@types.Tid::for_name("sub_2000"), sub => {
    sub.map(s => s.with_name("__libc_start_main"))
  })
  debug_inspect(
    @glibc_runtime.detect_main_address(with_start).map(w => w.to_string()),
    content=(
      #|Some("0x1000:64u")
    ),
  )
  let recovered = @glibc_runtime.rename_main(with_start, abi=sub => {
    sub.with_comment("abi applied")
  })
  debug_inspect(
    names(recovered),
    content=(
      #|["_start/0", "__libc_start_main/1", "main/0"]
    ),
  )
  debug_inspect(recovered.subs()[2].comment(), content="Some(\"abi applied\")")
  // without __libc_start_main nothing is detected
  debug_inspect(@glibc_runtime.detect_main_address(prog), content="None")
}

///|
test "main address passed through memory" {
  let mem = @types.Var::new(name="mem", typ=Mem(addr_width=64, value_width=8))
  let slot = @types.Exp::int(word64(0x8000))
  let store = @types.Exp::Store(
    mem=@types.Exp::var_exp(mem),
    addr=slot,
    value=@types.Exp::int(word64(0x1000)),
    endian=LittleEndian,
  )
  let entry = @types.Blk::create(defs=[@types.Def::create(mem, store)], jmps=[
    direct_call(@types.Tid::for_name("__libc_start_main")),
  ])
  let load = @types.Exp::Load(
    mem=@types.Exp::var_exp(mem),
    addr=slot,
    endian=LittleEndian,
    typ=Imm(64),
  )
  let start = @types.Sub::create(
    name="__libc_start_main",
    args=[@types.Arg::create(rdi(), load)],
    tid=@types.Tid::for_name("__libc_start_main"),
  )
  let prog = @types.Program::create(subs=[
    @types.Sub::create(name="_start", blks=[entry]),
    start,
  ])
  debug_inspect(
    @glibc_runtime.detect_main_address(prog).map(w => w.to_string()),
    content=(
      #|Some("0x1000:64u")
    ),
  )
}

///|
test "glibc detection uses external references" {
  let doc = @ogre.Doc::empty().put(
    @image.Scheme::external_reference(),
    (0L, "__libc_start_main"),
  )
  inspect(@glibc_runtime.references_glibc_start_main(doc), content="true")
  inspect(
    @glibc_runtime.references_glibc_start_main(@ogre.Doc::empty()),
    content="false",
  )
  let image = @image.Image::create(entry=0, endian=LittleEndian, spec=doc)
  let project = @project.Project::from_image(image).with_program(
    start_program(direct_call(@types.Tid::for_name("sub_2000"))),
  )
  inspect(@glibc_runtime.is_glibc(project), content="true")
  let discovered = @glibc_runtime.discover_libc_start_main(project)
  debug_inspect(
    names(discovered.program()),
    content=(
      #|["_start/0", "__libc_start_main/0", "sub_1000/0"]
    ),
  )
  // not a glibc project and not enabled: untouched
  let plain = @project.Project::empty(@core_theory.Target::unknown()).with_program(
    project.program(),
  )
  debug_inspect(
    names(@glibc_runtime.discover_libc_start_main(plain).program()),
    content=(
      #|["_start/0", "sub_2000/1", "sub_1000/0"]
    ),
  )
}

///|
test "glibc internal aliases" {
  debug_inspect(
    @glibc_runtime.glibc_internal_aliases(Some("__GI_memcpy"), [
      "__GI___memcpy", "memcpy_alias",
    ]),
    content=(
      #|["__GI___memcpy", "__memcpy", "memcpy", "memcpy_alias"]
    ),
  )
  debug_inspect(
    @glibc_runtime.glibc_internal_aliases(Some("__GI_"), []),
    content="[]",
  )
  let prog = @types.Program::create(subs=[
    @types.Sub::create(name="__GI_strlen"),
  ])
  debug_inspect(
    @glibc_runtime.refine_glibc_internal_aliases(prog).subs()[0].sub_aliases(),
    content=(
      #|["strlen"]
    ),
  )
}

///|
test "registration adds the abi component and the autorun pass" {
  debug_inspect(@glibc_runtime.register(enable=true), content="Ok(true)")
  debug_inspect(@glibc_runtime.register(), content="Ok(false)")
  guard @project.find_pass("glibc-runtime") is Some(pass) else {
    fail("glibc-runtime is not registered")
  }
  inspect(pass.autorun(), content="true")
  let prog = start_program(direct_call(@types.Tid::for_name("sub_2000")))
  let project = @project.Project::empty(@core_theory.Target::unknown()).with_program(
    prog,
  )
  let after_abi = @abi.pass(project)
  guard after_abi.run_pass("glibc-runtime") is Ok(result) else {
    fail("glibc-runtime failed")
  }
  debug_inspect(
    names(result.program()),
    content=(
      #|["_start/0", "__libc_start_main/0", "sub_1000/0"]
    ),
  )
}
