///|
fn project(subs : Array[@types.Term[@types.Sub]]) -> @project.Project {
  let prog = @types.Program::create(subs~)
  @project.Project::empty(@core_theory.Target::x86_64()).with_program(prog)
}

///|
/// A subroutine with a chain of `n` blocks named `<prefix>0`...
fn chain(
  name : String,
  prefix : String,
  n : Int,
  names : Map[@types.Tid, String],
) -> @types.Term[@types.Sub] {
  let tids = Array::makei(n, _ => @types.Tid::create())
  let blks = []
  for i, tid in tids {
    names[tid] = "\{prefix}\{i}"
    let jmps = if i + 1 < n {
      [@types.Jmp::create_goto(Direct(tids[i + 1]))]
    } else {
      []
    }
    blks.push(@types.Blk::create(tid~, jmps~))
  }
  @types.Sub::create(name~, blks~)
}

///|
/// A subroutine with a single block that jumps to itself.
fn spin(names : Map[@types.Tid, String]) -> @types.Term[@types.Sub] {
  let tid = @types.Tid::create()
  names[tid] = "L"
  @types.Sub::create(name="spin", blks=[
    @types.Blk::create(tid~, jmps=[@types.Jmp::create_goto(Direct(tid))]),
  ])
}

///|
fn resume_other(m : @primus.Machine) -> Unit raise {
  let others = m.forks().filter(id => id != m.current())
  if others.last() is Some(id) {
    m.kill(m.current())
    m.switch(id)
  }
}

///|
test "the exploring scheduler prefers machines heading to less explored blocks" {
  let names = Map([])
  let main = chain("main", "c", 5, names)
  let spin = spin(names)
  let log = []
  let spins = Ref(0)
  let (status, _) = @primus.Machine::run(
    project([main, spin]),
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus_exploring.install(m)
      m.observe(@primus.enter_blk, b => {
        let name = names.get(b.tid()).unwrap()
        log.push("\{m.current()}:\{name}")
        if name == "L" {
          spins.val += 1
          if spins.val > 6 {
            @primus.Interpreter::halt(m)
          }
        }
      })
    },
    start=m => {
      m.fork(then=m => {
        let sub = if m.current() == @primus.Id::global() {
          "main"
        } else {
          "spin"
        }
        @primus.Linker::schedule_exec(m, Symbol(sub))
      })
    },
    fini=resume_other,
  )
  inspect(
    status,
    content=(
      #|Normal
    ),
  )
  debug_inspect(
    log,
    content=(
      #|[
      #|  "1:L",
      #|  "0:c0",
      #|  "1:L",
      #|  "0:c1",
      #|  "1:L",
      #|  "0:c2",
      #|  "1:L",
      #|  "0:c3",
      #|  "1:L",
      #|  "0:c4",
      #|  "1:L",
      #|  "1:L",
      #|]
    ),
  )
}

///|
test "blocks are counted and machines standing at block boundaries alternate" {
  let names = Map([])
  let main = chain("main", "c", 3, names)
  let log = []
  let counts = []
  let (status, _) = @primus.Machine::run(
    project([main]),
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus_exploring.install(m)
      m.observe(@primus.enter_blk, b => {
        log.push("\{m.current()}:\{names.get(b.tid()).unwrap()}")
      })
    },
    start=m => {
      m.fork()
      @primus.Linker::schedule_exec(m, Symbol("main"))
    },
    fini=m => {
      if m.current() == @primus.Id::global() {
        for blk in main.blks() {
          counts.push(@primus_exploring.explored(m, blk.tid()))
        }
      }
      resume_other(m)
    },
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|["1:c0", "0:c0", "1:c1", "0:c1", "1:c2", "0:c2"]
    ),
  )
  debug_inspect(
    counts,
    content=(
      #|[2, 2, 2]
    ),
  )
}

///|
test "the exploring scheduler registers its component once" {
  @primus_exploring.register() |> ignore
  assert_false(@primus_exploring.register())
}
