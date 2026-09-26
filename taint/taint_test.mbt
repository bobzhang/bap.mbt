///|
test "kinds are interned and objects are fresh" {
  let log = []
  let status = run([], init=m => {
    let k1 = @taint.Kind::create(m, "untrusted")
    let k2 = @taint.Kind::create(m, "untrusted")
    let k3 = @taint.Kind::create(m, "secret")
    log.push("same kind: \{k1 == k2}, different: \{k1 != k3}")
    log.push("names: \{k1.name(m)} \{k3.name(m)}")
    let o1 = @taint.Object::create(m, k1)
    let o2 = @taint.Object::create(m, k3)
    let o3 = @taint.Object::create(m, k1)
    log.push("objects: \{o1} \{o2} \{o3}")
    log.push("kinds: \{o1.kind(m).name(m)} \{o2.kind(m).name(m)}")
    let back = @taint.Object::of_value(o2.to_value())
    log.push("round trip: \{back == o2} \{back.kind(m) == k3}")
    log.push("inspect: \{o3.inspect()}")
    let bogus = @taint.Object::of_value(@primus.Value::of_word(m, w64(42)))
    try bogus.kind(m) catch {
      e => log.push("bogus: \{@primus.exn_to_string(e)}")
    } noraise {
      _ => log.push("bogus has a kind")
    }
  })
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "same kind: true, different: true",
      #|  "names: untrusted secret",
      #|  "objects: 1 2 3",
      #|  "kinds: untrusted secret",
      #|  "round trip: true true",
      #|  "inspect: 3",
      #|  "bogus: bad taint object: 0x2A:64u#4",
      #|]
    ),
  )
}

///|
test "the low-level tracker interface" {
  let log = []
  let status = run([], init=m => {
    let k = @taint.Kind::create(m, "k")
    let v = @primus.Value::of_word(m, w64(7))
    let same_word = @primus.Value::of_word(m, w64(7))
    let t1 = @taint.Object::create(m, k)
    let t2 = @taint.Object::create(m, k)
    let both = @sorted_set.SortedSet::from_iter([t1, t2].iter())
    @taint.Tracker::attach(m, v, Direct, both)
    log.push(
      "direct v: \{objects_string(@taint.Tracker::lookup(m, v, Direct))}",
    )
    // direct relations are indexed by value identity
    log.push(
      "direct same word: \{objects_string(@taint.Tracker::lookup(m, same_word, Direct))}",
    )
    log.push(
      "indirect v: \{objects_string(@taint.Tracker::lookup(m, v, Indirect))}",
    )
    @taint.Tracker::attach(m, v, Indirect, @sorted_set.SortedSet::singleton(t1))
    // indirect relations are indexed by addresses (words)
    log.push(
      "indirect same word: \{objects_string(@taint.Tracker::lookup(m, same_word, Indirect))}",
    )
    @taint.Tracker::detach(m, v, Direct, @sorted_set.SortedSet::singleton(t1))
    log.push(
      "after detach: \{objects_string(@taint.Tracker::lookup(m, v, Direct))}",
    )
    log.push("objects: \{objects_string(@taint.Tracker::objects(m))}")
    @taint.Tracker::detach(m, v, Direct, both)
    @taint.Tracker::detach(m, v, Indirect, both)
    log.push("all detached: \{objects_string(@taint.Tracker::objects(m))}")
    let a = @primus.Value::of_word(m, w64(0x1000))
    let n = @primus.Value::of_word(m, w64(3))
    let t3 = @taint.Tracker::new_indirect(m, addr=a, len=n, k)
    log.push(
      "region: \{indirect_at(m, 0xfff)} \{indirect_at(m, 0x1000)} \{indirect_at(m, 0x1002)} \{indirect_at(m, 0x1003)} (\{t3})",
    )
    let huge = @primus.Value::of_word(m, @types.Word::of_int64(-1L))
    try @taint.Tracker::new_indirect(m, addr=a, len=huge, k) catch {
      e => log.push("bad length: \{@primus.exn_to_string(e)}")
    } noraise {
      _ => log.push("no error")
    }
  })
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "direct v: {1,2}",
      #|  "direct same word: {}",
      #|  "indirect v: {}",
      #|  "indirect same word: {1}",
      #|  "after detach: {2}",
      #|  "objects: {1,2}",
      #|  "all detached: {}",
      #|  "region: {} {3} {3} {} (3)",
      #|  "bad length: bad taint cast: 0xFFFFFFFFFFFFFFFF:64u#15 is not an integer",
      #|]
    ),
  )
}

///|
test "the taint-attached observation" {
  let log = []
  let status = run([], init=m => {
    m.observe(@taint.attached, p => {
      let (r, o, v) = p
      log.push("\{r} \{o} \{v.to_word().to_hex()}")
    })
    let k = @taint.Kind::create(m, "k")
    let v = @primus.Value::of_word(m, w64(1))
    ignore(@taint.Tracker::new_direct(m, v, k))
    let a = @primus.Value::of_word(m, w64(0x1000))
    let n = @primus.Value::of_word(m, w64(2))
    ignore(@taint.Tracker::new_indirect(m, addr=a, len=n, k))
    let t = @taint.Object::create(m, k)
    @taint.Tracker::attach(m, v, Direct, @sorted_set.SortedSet::singleton(t))
  })
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "Direct 1 0x0000000000000001",
      #|  "Indirect 2 0x0000000000001000",
      #|  "Indirect 2 0x0000000000001001",
      #|  "Direct 3 0x0000000000000001",
      #|]
    ),
  )
}

///|
/// x := 5; y := x + 1; mem[0x1000] := y; z := mem[0x1000]; w := 7;
/// c := low:32[x]; mem[0x1008] := x; u := mem[0x1008]
fn dataflow_program() -> (
  Array[@types.Term[@types.Blk]],
  @types.Tid,
  Array[@types.Var],
) {
  let x = reg("x")
  let y = reg("y")
  let z = reg("z")
  let w = reg("w")
  let c = @types.Var::create("c", Imm(32))
  let u = reg("u")
  let mem = mem_var()
  let dx = def_at(0x10, x, int64(5))
  let b0 = @types.Blk::create(defs=[
    dx,
    def_at(0x14, y, BinOp(Plus, Var(x), int64(1))),
    def_at(0x18, mem, store64(int64(0x1000), Var(y))),
    def_at(0x1c, z, load64(int64(0x1000))),
    def_at(0x20, w, int64(7)),
    def_at(0x24, c, Cast(kind=Low, width=32, exp=Var(x))),
    def_at(0x28, mem, store64(int64(0x1008), Var(x))),
    def_at(0x2c, u, load64(int64(0x1008))),
  ])
  ([b0], dx.tid(), [x, y, z, w, c, u])
}

///|
fn dataflow_report(
  m : @primus.Machine,
  vars : Array[@types.Var],
  log : Array[String],
) -> Unit {
  for v in vars {
    log.push("\{v.name()}: \{direct_of(m, v)}")
  }
  log.push(
    "mem[0x1000..0x1008): \{[for i in 0..<8 => indirect_at(m, 0x1000 + i)].join("")}",
  )
  log.push(
    "mem[0x1008..0x1010): \{[for i in 0..<8 => indirect_at(m, 0x1008 + i)].join("")}",
  )
}

///|
test "propagate-by-computation taints computed, stored and loaded values" {
  let (blks, tx, vars) = dataflow_program()
  let log = []
  let status = run(
    blks,
    init=m => {
      @taint.propagate_by_computation(m)
      @taint.propagate_exactly(m)
      @taint.Policy::set_default(
        m,
        @taint.Policy::of_name(m, @taint.computation_policy_name),
      )
      taint_after(m, tx, vars[0], "untrusted", log~)
    },
    fini=m => dataflow_report(m, vars, log),
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "introduced 1 of untrusted",
      #|  "x: {1}",
      #|  "y: {1}",
      #|  "z: {1}",
      #|  "w: {}",
      #|  "c: {1}",
      #|  "u: {1}",
      #|  "mem[0x1000..0x1008): {1}{1}{1}{1}{1}{1}{1}{1}",
      #|  "mem[0x1008..0x1010): {1}{1}{1}{1}{1}{1}{1}{1}",
      #|]
    ),
  )
}

///|
test "propagate-exactly taints only transferred values" {
  let (blks, tx, vars) = dataflow_program()
  let log = []
  let status = run(
    blks,
    init=m => {
      @taint.propagate_exactly(m)
      @taint.Policy::set_default(
        m,
        @taint.Policy::of_name(m, @taint.exact_policy_name),
      )
      taint_after(m, tx, vars[0], "untrusted", log~)
    },
    fini=m => dataflow_report(m, vars, log),
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "introduced 1 of untrusted",
      #|  "x: {1}",
      #|  "y: {}",
      #|  "z: {}",
      #|  "w: {}",
      #|  "c: {1}",
      #|  "u: {1}",
      #|  "mem[0x1000..0x1008): {}{}{}{}{}{}{}{}",
      #|  "mem[0x1008..0x1010): {1}{1}{1}{1}{1}{1}{1}{1}",
      #|]
    ),
  )
}

///|
test "no taint is propagated without a selected policy" {
  let (blks, tx, vars) = dataflow_program()
  let log = []
  let status = run(
    blks,
    init=m => {
      @taint.propagate_by_computation(m)
      taint_after(m, tx, vars[0], "untrusted", log~)
    },
    fini=m => dataflow_report(m, vars, log),
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "introduced 1 of untrusted",
      #|  "x: {1}",
      #|  "y: {}",
      #|  "z: {}",
      #|  "w: {}",
      #|  "c: {}",
      #|  "u: {}",
      #|  "mem[0x1000..0x1008): {}{}{}{}{}{}{}{}",
      #|  "mem[0x1008..0x1010): {}{}{}{}{}{}{}{}",
      #|]
    ),
  )
}

///|
test "policies are selected per kind" {
  let x = reg("x")
  let y = reg("y")
  let z = reg("z")
  let dx = def_at(0x10, x, int64(5))
  let b0 = @types.Blk::create(defs=[
    dx,
    def_at(0x14, y, BinOp(Plus, Var(x), int64(1))),
    def_at(0x18, z, Cast(kind=Low, width=64, exp=Var(x))),
  ])
  let log = []
  let status = run(
    [b0],
    init=m => {
      @taint.propagate_by_computation(m)
      @taint.propagate_exactly(m)
      let exact = @taint.Policy::of_name(m, @taint.exact_policy_name)
      let computation = @taint.Policy::of_name(
        m, @taint.computation_policy_name,
      )
      let secret = @taint.Kind::create(m, "secret")
      let public = @taint.Kind::create(m, "public")
      // the first selection also becomes the default
      @taint.Policy::select(m, exact, secret)
      log.push(
        "default is exact: \{@taint.Policy::default(m) == Some(exact)}, public uses exact: \{@taint.Policy::selected(m, exact, public)}",
      )
      @taint.Policy::set_default(m, computation)
      log.push(
        "secret uses exact: \{@taint.Policy::selected(m, exact, secret)}, public uses computation: \{@taint.Policy::selected(m, computation, public)}",
      )
      taint_after(m, dx.tid(), x, "secret", log~)
      taint_after(m, dx.tid(), x, "public", log~)
    },
    fini=m => {
      for v in [x, y, z] {
        log.push("\{v.name()}: \{direct_of(m, v)}")
      }
    },
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "default is exact: true, public uses exact: true",
      #|  "secret uses exact: true, public uses computation: true",
      #|  "introduced 1 of public",
      #|  "introduced 2 of secret",
      #|  "x: {1,2}",
      #|  "y: {1}",
      #|  "z: {1,2}",
      #|]
    ),
  )
}

///|
test "sanitization removes the taints of a kind from all values" {
  let x = reg("x")
  let y = reg("y")
  let z = reg("z")
  let dx = def_at(0x10, x, int64(5))
  let dz = def_at(0x18, z, BinOp(Times, Var(y), int64(2)))
  let b0 = @types.Blk::create(defs=[
    dx,
    def_at(0x14, y, BinOp(Plus, Var(x), int64(1))),
    dz,
    def_at(0x1c, mem_var(), store64(int64(0x1000), Var(z))),
  ])
  let log = []
  let status = run(
    [b0],
    init=m => {
      @taint.propagate_by_computation(m)
      @taint.Policy::set_default(
        m,
        @taint.Policy::of_name(m, @taint.computation_policy_name),
      )
      taint_after(m, dx.tid(), x, "untrusted", log~)
      taint_after(m, dx.tid(), x, "secret", log~)
      m.observe(@primus.leave_def, d => {
        if d.tid() == dz.tid() {
          log.push(
            "before: x=\{direct_of(m, x)} y=\{direct_of(m, y)} z=\{direct_of(m, z)}",
          )
          // sanitizing z kills the untrusted taint everywhere
          @taint.Tracker::sanitize(
            m,
            @primus.Env::get(m, z),
            Direct,
            @taint.Kind::create(m, "untrusted"),
          )
          log.push(
            "after: x=\{direct_of(m, x)} y=\{direct_of(m, y)} z=\{direct_of(m, z)}",
          )
        }
      })
    },
    fini=m => {
      log.push("mem: \{indirect_at(m, 0x1000)}")
      @taint.Tracker::sanitize(
        m,
        @primus.Value::of_word(m, w64(0x1000)),
        Indirect,
        @taint.Kind::create(m, "secret"),
      )
      log.push("objects: \{objects_string(@taint.Tracker::objects(m))}")
    },
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "introduced 1 of secret",
      #|  "introduced 2 of untrusted",
      #|  "before: x={1,2} y={1,2} z={1,2}",
      #|  "after: x={1} y={1} z={1}",
      #|  "mem: {1}",
      #|  "objects: {}",
      #|]
    ),
  )
}

///|
test "the conservative gc finalizes unreachable taints" {
  let x = reg("x")
  let y = reg("y")
  let dx = def_at(0x10, x, int64(5))
  let b0 = @types.Blk::create(defs=[
    dx,
    def_at(0x14, y, BinOp(Plus, Var(x), int64(1))),
    def_at(0x18, x, int64(0)),
    def_at(0x1c, mem_var(), store64(int64(0x1000), Var(y))),
    def_at(0x20, y, int64(0)),
    def_at(0x24, mem_var(), store64(int64(0x1000), int64(0))),
    def_at(0x28, y, int64(1)),
  ])
  let log = []
  let status = run([b0], init=m => {
    @taint.propagate_by_computation(m)
    @taint.Policy::set_default(
      m,
      @taint.Policy::of_name(m, @taint.computation_policy_name),
    )
    @taint.Gc::conservative(m)
    taint_after(m, dx.tid(), x, "untrusted", log~)
    m.observe(@primus.pc_change, pc => {
      log.push(
        "pc \{pc.to_hex()}: \{objects_string(@taint.Tracker::objects(m))}",
      )
    })
    m.observe(@taint.taint_finalize, p => {
      log.push("finalize \{p.0} live=\{p.1}")
    })
  })
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "pc 0x0000000000000010: {}",
      #|  "introduced 1 of untrusted",
      #|  "pc 0x0000000000000014: {1}",
      #|  "pc 0x0000000000000018: {1}",
      #|  "pc 0x000000000000001c: {1}",
      #|  "pc 0x0000000000000020: {1}",
      #|  "pc 0x0000000000000024: {1}",
      #|  "pc 0x0000000000000028: {}",
      #|  "finalize 1 live=false",
      #|]
    ),
  )
}

///|
test "forked machines keep independent taint states" {
  let x = reg("x")
  let y = reg("y")
  let dx = def_at(0x10, x, int64(5))
  let dy = def_at(0x14, y, BinOp(Plus, Var(x), int64(1)))
  let b0 = @types.Blk::create(defs=[
    dx,
    dy,
    def_at(0x18, x, int64(0)),
    def_at(0x1c, y, int64(0)),
    def_at(0x20, x, int64(1)),
  ])
  let log = []
  let status = run(
    [b0],
    init=m => {
      @taint.propagate_by_computation(m)
      @taint.Policy::set_default(
        m,
        @taint.Policy::of_name(m, @taint.computation_policy_name),
      )
      @taint.Gc::conservative(m)
      taint_after(m, dx.tid(), x, "k", log~)
      m.observe(@taint.taint_finalize, p => {
        log.push("machine \{m.current()}: finalize \{p.0} live=\{p.1}")
      })
      // fork after y is computed; the child introduces its own taint
      m.observe(@primus.leave_def, d => {
        if d.tid() == dy.tid() && m.current() == @primus.Id::global() {
          let pid = m.current()
          m.fork(then=m => {
            if m.current() != pid {
              let t = @taint.Tracker::new_direct(
                m,
                @primus.Env::get(m, y),
                @taint.Kind::create(m, "child"),
              )
              log.push("child introduced \{t}")
            }
          })
        }
      })
    },
    fini=m => {
      log.push(
        "machine \{m.current()}: objects \{objects_string(@taint.Tracker::objects(m))}",
      )
      if m.current() != @primus.Id::global() {
        m.switch(@primus.Id::global())
      }
    },
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "introduced 1 of k",
      #|  "child introduced 2",
      #|  "machine 1: finalize 2 live=false",
      #|  "machine 1: finalize 1 live=true",
      #|  "machine 1: objects {}",
      #|  "machine 0: finalize 1 live=false",
      #|  "machine 0: objects {}",
      #|]
    ),
  )
}
