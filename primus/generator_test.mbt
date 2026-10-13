///|
test "uninitialized variables are generated once" {
  let x = reg("x")
  let y = @types.Var::create("y", Imm(16))
  let log = []
  let (status, _) = @primus.Machine::run(project([]), start=m => {
    @primus.Env::add(m, x, @primus.Generator::static_value(0x2a))
    @primus.Env::add(m, y, @primus.Generator::static_value(width=16, 0x1234))
    m.observe(@primus.var_generated, p => log.push("generated \{p.0.name()}"))
    assert_true(@primus.Env::has(m, x))
    assert_false(@primus.Env::is_set(m, x))
    log.push(@primus.Env::get(m, x).to_word().to_hex())
    log.push(@primus.Env::get(m, x).to_word().to_hex())
    log.push(@primus.Env::get(m, y).to_word().to_hex())
    assert_true(@primus.Env::is_set(m, x))
    inspect(@primus.Env::all(m).length(), content="2")
    @primus.Env::del(m, x)
    assert_false(@primus.Env::is_set(m, x))
  })
  inspect(status_string(status), content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "generated x",
      #|  "0x2a2a2a2a2a2a2a2a",
      #|  "0x2a2a2a2a2a2a2a2a",
      #|  "generated y",
      #|  "0x1234",
      #|]
    ),
  )
}

///|
test "reading an unset variable without a generator fails" {
  let x = reg("x")
  let b0 = blk(defs=[def(reg("y"), Var(x))])
  let (status, _) = run_main_sub([sub("main", [b0])], [])
  inspect(status_string(status), content="Exn(undefined variable `x')")
  let (status, values) = run_main_sub([sub("main", [b0])], [reg("y")], init=m => {
    @primus.Env::add(m, x, @primus.Generator::static_value(width=64, 5))
  })
  inspect(status_string(status), content="Normal")
  debug_inspect(values, content="[Some(5)]")
}

///|
test "uninitialized memory is generated and remembered" {
  let log = []
  let (_, _) = @primus.Machine::run(project([]), start=m => {
    m.observe(@primus.load_generated, p => {
      log.push("gen \{word_int(p.0)}=\{value_int(p.1)}")
    })
    @primus.Memory::allocate(
      m,
      w64(0x100),
      4,
      generator=@primus.Generator::static_value(width=16, 0xBEEF),
    )
    let a = @primus.Memory::load(m, w64(0x100))
    let b = @primus.Memory::load(m, w64(0x101))
    let a2 = @primus.Memory::load(m, w64(0x100))
    log.push("\{word_int(a)} \{word_int(b)} \{word_int(a2)}")
    assert_true(@primus.Memory::is_mapped(m, w64(0x103)))
    assert_false(@primus.Memory::is_mapped(m, w64(0x104)))
    assert_true(@primus.Memory::is_writable(m, w64(0x100)))
  })
  debug_inspect(
    log,
    content=(
      #|["gen 256=239", "gen 257=190", "239 190 239"]
    ),
  )
}

///|
test "memory regions with init, static data and banks" {
  let log = []
  let (_, _) = @primus.Machine::run(project([]), start=m => {
    @primus.Memory::add_region(m, lower=w64(0x10), upper=w64(0x14), init=a => {
      w8(word_int(a).to_int() * 2)
    })
    log.push(word_int(@primus.Memory::load(m, w64(0x12))).to_string())
    let data = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0x200UL,
      b"\x01\x02\x03",
    )
    @primus.Memory::add_text(m, data)
    log.push(word_int(@primus.Memory::load(m, w64(0x201))).to_string())
    log.push(@primus.Memory::is_writable(m, w64(0x201)).to_string())
    @primus.Memory::store(m, w64(0x201), w8(9)) catch {
      e => log.push(@primus.exn_to_string(e))
    }
    @primus.Memory::store_never_fail(m, w64(0x201), w8(9))
    log.push(word_int(@primus.Memory::load(m, w64(0x201))).to_string())
    // a different bank has its own layers
    let main = @primus.Memory::memory(m)
    @primus.Memory::switch(
      m,
      @primus.Descriptor::create(addr_size=64, data_size=8, "other"),
    )
    log.push(@primus.Memory::is_mapped(m, w64(0x12)).to_string())
    @primus.Memory::switch(m, main)
    log.push(@primus.Memory::is_mapped(m, w64(0x12)).to_string())
    log.push(main.name())
  })
  debug_inspect(
    log,
    content=(
      #|[
      #|  "36",
      #|  "2",
      #|  "false",
      #|  "Page fault at 0x0000000000000201",
      #|  "9",
      #|  "false",
      #|  "true",
      #|  "mem",
      #|]
    ),
  )
}

///|
test "random generators are deterministic per machine and within range" {
  let first = []
  let second = []
  for out in [first, second] {
    let (_, _) = @primus.Machine::run(project([]), start=m => {
      let g = @primus.Generator::random_lcg(min=10, max=20, 42)
      let b = @primus.Generator::seeded_byte()
      for _ in 0..<20 {
        let v = @primus.Generator::next(m, g)
        assert_true(v >= 10 && v <= 20)
        let x = @primus.Generator::next(m, b)
        assert_true(x >= 0 && x <= 255)
        out.push(v)
      }
    })
  }
  assert_eq(first, second)
  // not constant
  assert_true(first.iter().any(x => x != first[0]))
}

///|
test "forks advance generators independently" {
  let draws = []
  let (_, _) = @primus.Machine::run(project([]), start=m => {
    let g = @primus.Generator::static_value(3)
    let seq = @primus.Generator::unfold(
      width=8,
      seed=1,
      f=p => (p.0, p.1 + 1),
      (),
    )
    draws.push(@primus.Generator::next(m, seq))
    m.fork(then=m => {
      draws.push(@primus.Generator::next(m, seq))
      draws.push(@primus.Generator::next(m, g))
      if m.current() != @primus.Id::global() {
        m.switch(@primus.Id::global())
      }
    })
  })
  // the parent draws 1; after the fork both the child and the parent draw 2
  debug_inspect(draws, content="[1, 2, 3, 2, 3]")
}

///|
test "mcg generators" {
  let g = @primus.Mcg::for_width(8)
  let xs = g.tabulate(n=5, 1)
  inspect(xs.length(), content="5")
  assert_true(xs.iter().all(x => x.width() == 8))
  let wide = @primus.Mcg::for_width(100)
  assert_true(wide.tabulate(n=3, 7).iter().all(x => x.width() == 100))
  let r = @primus.Mcg::create(min=5, max=6, 8)
  assert_true(
    r
    .tabulate(n=50, 3)
    .iter()
    .all(x => {
      let v = try! x.to_int()
      v == 5 || v == 6
    }),
  )
}

///|
test "iterators" {
  let count : @primus.Iterator[Int32, Int32] = Fin({
    min: 0,
    max: 3,
    value: x => x,
    next: x => if x < 3 { Some(x + 1) } else { None },
  })
  debug_inspect(count.to_iter(0).collect(), content="[0, 1, 2, 3]")
  let evens : @primus.Iterator[Int32, Int32] = Inf({
    min: 0,
    max: 100,
    value: x => x * 2,
    next: x => x + 1,
  })
  debug_inspect(evens.to_iter(1).take(3).collect(), content="[2, 4, 6]")
  inspect(evens.max(), content="100")
}
