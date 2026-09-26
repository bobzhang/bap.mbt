///|
fn project() -> @project.Project {
  @project.Project::empty(@core_theory.Target::x86_64()).with_program(
    @types.Program::create(subs=[]),
  )
}

///|
fn v(m : @primus.Machine, n : Int) -> @primus.Value raise {
  @primus.Value::of_int(m, width=64, n)
}

///|
fn show(x : @primus.Value) -> String {
  (try! x.to_word().to_uint64()).to_string()
}

///|
test "regions: create, lookup, count and move" {
  let log = []
  let (status, _) = @primus.Machine::run(project(), start=m => {
    let heap = @primus.Value::symbol_to_value(m, "heap")
    let freed = @primus.Value::symbol_to_value(m, "freed")
    @primus_region.create(m, heap, v(m, 0x100), v(m, 0x1ff)) |> ignore
    @primus_region.create(m, heap, v(m, 0x180), v(m, 0x2ff)) |> ignore
    @primus_region.create(m, heap, v(m, 0x400), v(m, 0x4ff)) |> ignore
    log.push("count=\{show(@primus_region.count(m, heap))}")
    log.push("lower(0x190)=\{show(@primus_region.lower(m, heap, v(m, 0x190)))}")
    log.push("upper(0x190)=\{show(@primus_region.upper(m, heap, v(m, 0x190)))}")
    log.push("lower(0x300)=\{show(@primus_region.lower(m, heap, v(m, 0x300)))}")
    // points of other widths are compared numerically
    let narrow = @primus.Value::of_int(m, width=16, 0x401)
    log.push("upper(0x401:16)=\{show(@primus_region.upper(m, heap, narrow))}")
    log.push(
      "move(0x190)=\{show(@primus_region.move_regions(m, freed, heap, v(m, 0x190)))}",
    )
    log.push("count(heap)=\{show(@primus_region.count(m, heap))}")
    log.push("count(freed)=\{show(@primus_region.count(m, freed))}")
    log.push(
      "move(0x190)=\{show(@primus_region.move_regions(m, freed, heap, v(m, 0x190)))}",
    )
    let unknown = @primus.Value::symbol_to_value(m, "unknown")
    log.push("count(unknown)=\{show(@primus_region.count(m, unknown))}")
  })
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "count=3",
      #|  "lower(0x190)=256",
      #|  "upper(0x190)=767",
      #|  "lower(0x300)=0",
      #|  "upper(0x401:16)=1279",
      #|  "move(0x190)=1",
      #|  "count(heap)=1",
      #|  "count(freed)=2",
      #|  "move(0x190)=0",
      #|  "count(unknown)=0",
      #|]
    ),
  )
}

///|
test "regions are local to machines and the primitives are linked" {
  let log = []
  let (status, _) = @primus.Machine::run(
    project(),
    init=m => @primus_region.install(m),
    start=m => {
      let heap = @primus.Value::symbol_to_value(m, "heap")
      @primus_region.create(m, heap, v(m, 1), v(m, 2)) |> ignore
      m.fork(then=m => {
        if m.current() != @primus.Id::global() {
          @primus_region.create(m, heap, v(m, 3), v(m, 4)) |> ignore
        }
        m.call(Symbol("region-count"), args=[heap], then=(m, r) => {
          log.push("\{m.current()}: \{show(r.unwrap())}")
        })
      })
    },
    fini=m => {
      if m.current() != @primus.Id::global() {
        m.kill(m.current())
        m.switch(@primus.Id::global())
      }
    },
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|["1: 2", "0: 1"]
    ),
  )
  debug_inspect(
    @primus_region.primitives().map(p => "\{p.name}: \{p.types}"),
    content=(
      #|[
      #|  "region-create: (sym int int) -> sym",
      #|  "region-contains: (sym int) -> int",
      #|  "region-move: (sym sym int) -> bool",
      #|  "region-lower: (sym int) -> int",
      #|  "region-upper: (sym int) -> int",
      #|  "region-count: (sym) -> int",
      #|]
    ),
  )
  assert_true(@primus_region.register())
  assert_false(@primus_region.register())
}
