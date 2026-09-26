// Loading, parsing, and type checking of the upstream Lisp library.

///|
test "load the standard library" {
  let loader = @primus_lisp.Loader::embedded(["lisp", "site-lisp"])
  let ctxt = @primus_lisp.Context::of_target(@core_theory.Target::x86_64())
  let prog = @primus_lisp.load_program(loader, ["core", "posix"], context=ctxt)
  let files = prog.sources.filenames()
  debug_inspect(
    files.length(),
    content=(
      #|19
    ),
  )
  debug_inspect(
    prog.get(@primus_lisp.func).length(),
    content=(
      #|147
    ),
  )
}

///|
fn semantic_errors(
  target : @core_theory.Target,
  dirs : Array[String],
) -> Array[String] raise {
  let lifter = @primus_lisp.load_semantics(target, dirs, strict=false)
  lifter.errors().map(e => e.summary())
}

///|
test "type check semantics" {
  debug_inspect(
    semantic_errors(@core_theory.Target::riscv64(), ["semantics/riscv"]),
    content=(
      #|[]
    ),
  )
  debug_inspect(
    semantic_errors(@core_theory.Target::x86_64(), ["semantics/x86"]),
    content=(
      #|[]
    ),
  )
  debug_inspect(
    semantic_errors(@core_theory.Target::arm(), ["semantics/arm"]),
    content=(
      #|[]
    ),
  )
  debug_inspect(
    semantic_errors(@core_theory.Target::powerpc(), ["semantics/powerpc"]),
    content=(
      #|[]
    ),
  )
}
