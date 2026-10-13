///|
fn project() -> @project.Project {
  @project.Project::empty(@core_theory.Target::x86_64()).with_program(
    @types.Program::create(subs=[]),
  )
}

///|
fn v(m : @primus.Machine, n : Int32) -> @primus.Value raise {
  @primus.Value::of_int(m, width=64, n)
}

///|
fn show(x : @primus.Value) -> String {
  (try! x.to_word().to_uint64()).to_string()
}

///|
test "dictionaries: add, get, has, iterate, delete" {
  let log = []
  let (status, _) = @primus.Machine::run(project(), start=m => {
    let d = @primus.Value::symbol_to_value(m, "d")
    @primus_dictionary.add(m, d, v(m, 30), v(m, 3)) |> ignore
    @primus_dictionary.add(m, d, v(m, 10), v(m, 1)) |> ignore
    @primus_dictionary.add(m, d, v(m, 20), v(m, 2)) |> ignore
    // replaces the data of an existing key
    @primus_dictionary.add(m, d, v(m, 20), v(m, 22)) |> ignore
    log.push("length=\{show(@primus_dictionary.length(m, d))}")
    log.push("get(20)=\{show(@primus_dictionary.get(m, d, v(m, 20)))}")
    log.push("get(40)=\{show(@primus_dictionary.get(m, d, v(m, 40)))}")
    log.push("has(10)=\{show(@primus_dictionary.has(m, d, v(m, 10)))}")
    log.push("has(11)=\{show(@primus_dictionary.has(m, d, v(m, 11)))}")
    // iteration with dict-first and dict-next
    let keys = []
    let mut k = @primus_dictionary.first(m, d)
    while !k.is_zero() {
      keys.push(show(k))
      k = @primus_dictionary.next(m, d, k)
    }
    log.push("keys=\{keys.join(",")}")
    @primus_dictionary.del(m, d, key=v(m, 20)) |> ignore
    log.push("length=\{show(@primus_dictionary.length(m, d))}")
    @primus_dictionary.del(m, d) |> ignore
    log.push("length=\{show(@primus_dictionary.length(m, d))}")
    log.push("first=\{show(@primus_dictionary.first(m, d))}")
  })
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "length=3",
      #|  "get(20)=22",
      #|  "get(40)=0",
      #|  "has(10)=1",
      #|  "has(11)=0",
      #|  "keys=10,20,30",
      #|  "length=2",
      #|  "length=0",
      #|  "first=0",
      #|]
    ),
  )
}

///|
test "the dictionary primitives are linked by the component" {
  let log = []
  let (status, _) = @primus.Machine::run(
    project(),
    init=m => @primus_dictionary.install(m),
    start=m => {
      let d = @primus.Value::symbol_to_value(m, "d")
      m.call(Symbol("dict-add"), args=[d, v(m, 1), v(m, 42)], then=(m, _) => {
        m.call(Symbol("dict-get"), args=[d, v(m, 1)], then=(_, r) => {
          log.push("dict-get: \{show(r.unwrap())}")
        })
      })
    },
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|["dict-get: 42"]
    ),
  )
  let err = try
    (@primus_dictionary.primitives()[0].run)(@primus.Machine::new(project()), [])
  catch {
    e => @primus.exn_to_string(e)
  } noraise {
    _ => "no error"
  }
  inspect(
    err,
    content=(
      #|Primus interpreter runtime error: dict-add: expects 3 arguments, got 0
    ),
  )
  assert_true(@primus_dictionary.register())
  assert_false(@primus_dictionary.register())
}
