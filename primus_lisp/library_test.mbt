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

///|
test "type check all semantic files together for each target" {
  let out = []
  for
    t in [
      @core_theory.Target::riscv64(),
      @core_theory.Target::riscv32(),
      @core_theory.Target::x86_64(),
      @core_theory.Target::i386(),
      @core_theory.Target::arm(),
      @core_theory.Target::thumb(),
      @core_theory.Target::aarch64(),
      @core_theory.Target::powerpc(),
      @core_theory.Target::powerpc64(),
    ] {
    let errs = semantic_errors(t, @primus_lisp.semantic_dirs)
    out.push("\{t.name().unqualified()}: \{errs.length()}")
  }
  debug_inspect(
    out,
    content=(
      #|[
      #|  "riscv64: 0",
      #|  "riscv32: 0",
      #|  "x86_64: 0",
      #|  "i386: 0",
      #|  "arm: 0",
      #|  "thumb: 0",
      #|  "aarch64: 0",
      #|  "powerpc: 0",
      #|  "powerpc64: 0",
      #|]
    ),
  )
}
