// Helpers shared by the black-box tests of the primus package.

///|
fn w64(n : Int32) -> @types.Word {
  try! @types.Word::of_int(width=64, n)
}

///|
fn w8(n : Int32) -> @types.Word {
  try! @types.Word::of_int(width=8, n)
}

///|
fn int64(n : Int32) -> @types.Exp {
  Int(w64(n))
}

///|
fn reg(name : String) -> @types.Var {
  @types.Var::create(name, Imm(64))
}

///|
fn mem_var() -> @types.Var {
  @types.Var::create("mem", Mem(addr_width=64, value_width=8))
}

///|
fn def(v : @types.Var, e : @types.Exp) -> @types.Term[@types.Def] {
  @types.Def::create(v, e)
}

///|
fn goto(
  dst : @types.Term[@types.Blk],
  cond? : @types.Exp,
) -> @types.Term[@types.Jmp] {
  match cond {
    Some(c) => @types.Jmp::create_goto(Direct(dst.tid()), cond=c)
    None => @types.Jmp::create_goto(Direct(dst.tid()))
  }
}

///|
fn blk(
  tid? : @types.Tid,
  defs~ : Array[@types.Term[@types.Def]] = [],
  jmps~ : Array[@types.Term[@types.Jmp]] = [],
) -> @types.Term[@types.Blk] {
  @types.Blk::create(tid?, defs~, jmps~)
}

///|
fn sub(
  name : String,
  args~ : Array[@types.Term[@types.Arg]] = [],
  blks : Array[@types.Term[@types.Blk]],
) -> @types.Term[@types.Sub] {
  @types.Sub::create(name~, args~, blks~)
}

///|
fn project(subs : Array[@types.Term[@types.Sub]]) -> @project.Project {
  let prog = @types.Program::create(subs~)
  @project.Project::empty(@core_theory.Target::x86_64()).with_program(prog)
}

///|
fn word_int(w : @types.Word) -> UInt64 {
  try! w.to_uint64()
}

///|
fn value_int(v : @primus.Value) -> UInt64 {
  word_int(v.to_word())
}

///|
/// Runs `main` of the program (linked with `link_program`) and returns the
/// exit status together with the values of the given variables observed
/// at the end of the run.
fn run_main_sub(
  subs : Array[@types.Term[@types.Sub]],
  vars : Array[@types.Var],
  init~ : (@primus.Machine) -> Unit raise = _ => (),
) -> (@primus.ExitStatus, Array[UInt64?]) {
  let results : Array[UInt64?] = []
  let (status, _) = @primus.Machine::run(
    project(subs),
    init=m => {
      @primus.Interpreter::link_program(m)
      init(m)
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
    fini=m => {
      results.clear()
      for v in vars {
        results.push(
          if @primus.Env::is_set(m, v) {
            Some(value_int(@primus.Env::get(m, v)))
          } else {
            None
          },
        )
      }
    },
  )
  (status, results)
}

///|
fn status_string(s : @primus.ExitStatus) -> String {
  s.to_string()
}
