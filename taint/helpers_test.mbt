// Helpers shared by the black-box tests of the taint package.

///|
fn w64(n : Int32) -> @types.Word {
  try! @types.Word::of_int(width=64, n)
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
/// A definition located at the given address (so that the program
/// counter changes when it is entered).
fn def_at(
  addr : Int32,
  v : @types.Var,
  e : @types.Exp,
) -> @types.Term[@types.Def] {
  @types.Def::create(v, e).set_attr(@types.Attr::address(w64(addr)))
}

///|
fn load64(addr : @types.Exp) -> @types.Exp {
  Load(mem=Var(mem_var()), addr~, endian=LittleEndian, typ=Imm(64))
}

///|
fn store64(addr : @types.Exp, value : @types.Exp) -> @types.Exp {
  Store(mem=Var(mem_var()), addr~, value~, endian=LittleEndian)
}

///|
fn project(blks : Array[@types.Term[@types.Blk]]) -> @project.Project {
  let main = @types.Sub::create(name="main", blks~)
  let prog = @types.Program::create(subs=[main])
  @project.Project::empty(@core_theory.Target::x86_64()).with_program(prog)
}

///|
/// Runs `main` of a single-subroutine program. `init` runs after the
/// program is linked and 64 bytes of memory are mapped at 0x1000; `fini`
/// runs at the end of every machine.
fn run(
  blks : Array[@types.Term[@types.Blk]],
  init~ : (@primus.Machine) -> Unit raise = _ => (),
  fini~ : (@primus.Machine) -> Unit raise = _ => (),
) -> String {
  let (status, _) = @primus.Machine::run(
    project(blks),
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus.Memory::allocate(m, w64(0x1000), 64)
      init(m)
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
    fini~,
  )
  status.to_string()
}

///|
/// Introduces a direct taint of the given kind on the value of `var`
/// right after the definition `tid` is evaluated.
fn taint_after(
  m : @primus.Machine,
  tid : @types.Tid,
  target : @types.Var,
  kind : String,
  log? : Array[String],
) -> Unit {
  m.observe(@primus.leave_def, d => {
    if d.tid() == tid {
      let k = @taint.Kind::create(m, kind)
      let t = @taint.Tracker::new_direct(m, @primus.Env::get(m, target), k)
      if log is Some(log) {
        log.push("introduced \{t} of \{k.name(m)}")
      }
    }
  })
}

///|
/// The objects directly attached to the value of `var`, as a string.
fn direct_of(m : @primus.Machine, target : @types.Var) -> String {
  guard @primus.Env::is_set(m, target) else { "unset" }
  let v = try! @primus.Env::get(m, target)
  objects_string(@taint.Tracker::lookup(m, v, Direct))
}

///|
/// The objects indirectly attached to the address.
fn indirect_at(m : @primus.Machine, addr : Int32) -> String {
  let a = @primus.Value::of_word(m, w64(addr))
  objects_string(@taint.Tracker::lookup(m, a, Indirect))
}

///|
fn objects_string(objs : @sorted_set.SortedSet[@taint.Object]) -> String {
  "{" + objs.to_array().map(o => o.to_string()).join(",") + "}"
}
