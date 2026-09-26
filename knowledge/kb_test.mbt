///|
fn kb_name(name : String) -> @knowledge.Name {
  @knowledge.Name::create(name, pkg="kb-test")
}

///|
fn kb_class(name : String) -> @knowledge.Class[Unit, Unit] {
  @knowledge.Class::create(name=kb_name(name), sort=())
}

///|
fn int_domain(name : String) -> @knowledge.Domain[Int] {
  @knowledge.Domain::total(kb_name(name), x => x.to_string(), empty=0, compare=(
    x,
    y,
  ) => x.compare(y))
}

///|
fn string_set_domain(name : String) -> @knowledge.Domain[Set[String]] {
  @knowledge.Domain::set(kb_name(name), x => x)
}

///|
fn opt_string_domain(name : String) -> @knowledge.Domain[String?] {
  @knowledge.Domain::optional(@knowledge.Domain::flat(kb_name(name), x => x))
}

///|
fn sorted_items(set : Set[String]) -> Array[String] {
  let items = set.to_array()
  items.sort()
  items
}

///|
test "collect iterates a self-recursive promise to the least fixed point" {
  let cls = kb_class("counter")
  let slot = cls.property(name=kb_name("counter-value"), domain=int_domain("n"))
  let runs = Ref(0)
  ignore(
    slot.promise((kb, obj) => {
      runs.val += 1
      let current = kb.collect(slot, obj)
      if current < 5 {
        current + 1
      } else {
        current
      }
    }),
  )
  let kb = @knowledge.State::new()
  let obj = kb.create(cls)
  assert_eq(kb.collect(slot, obj), 5)
  // 0->1->...->5 and one more round to observe that nothing changes
  assert_eq(runs.val, 6)
  // the property is computed once
  assert_eq(kb.collect(slot, obj), 5)
  assert_eq(runs.val, 6)
}

///|
test "collect reaches the fixed point of mutually recursive properties" {
  // reachability over a cyclic graph a -> b -> c -> a, c -> d
  let cls = kb_class("node")
  let name = cls.property(
    name=kb_name("node-name"),
    domain=opt_string_domain("node-name"),
  )
  let reach = cls.property(
    name=kb_name("node-reach"),
    domain=string_set_domain("reach"),
  )
  let kb = @knowledge.State::new()
  let nodes : Map[String, @knowledge.Object[Unit]] = Map([])
  for n in ["a", "b", "c", "d"] {
    let obj = kb.create(cls)
    kb.provide(name, obj, Some(n))
    nodes[n] = obj
  }
  let edges : Map[String, Array[String]] = {
    "a": ["b"],
    "b": ["c"],
    "c": ["a", "d"],
    "d": [],
  }
  ignore(
    reach.promise((kb, obj) => {
      let me = kb.require_some(name, obj)
      let result : Set[String] = Set([])
      result.add(me)
      for succ in edges[me] {
        for x in kb.collect(reach, nodes[succ]) {
          result.add(x)
        }
      }
      result
    }),
  )
  assert_eq(sorted_items(kb.collect(reach, nodes["a"])), ["a", "b", "c", "d"])
  assert_eq(sorted_items(kb.collect(reach, nodes["d"])), ["d"])
}

///|
test "two promises of the same slot are joined and conflicts diverge" {
  let cls = kb_class("joined")
  let tags = cls.property(
    name=kb_name("joined-tags"),
    domain=string_set_domain("tags"),
  )
  ignore(tags.promise((_, _) => Set(["x"])))
  ignore(tags.promise((_, _) => Set(["y"])))
  let kb = @knowledge.State::new()
  let obj = kb.create(cls)
  assert_eq(sorted_items(kb.collect(tags, obj)), ["x", "y"])
  // a flat property with two inconsistent promises
  let flat = cls.property(
    name=kb_name("joined-flat"),
    domain=opt_string_domain("flat"),
  )
  ignore(flat.promise((_, _) => Some("left")))
  ignore(flat.promise((_, _) => Some("right")))
  let other = kb.create(cls)
  let before = kb.fork()
  match kb.transaction(() => kb.collect(flat, other)) {
    Err(@knowledge.NonMonotonicUpdate(slot~, ..)) =>
      assert_eq(slot.show(), "kb-test:joined-flat")
    _ => fail("expected a conflict")
  }
  // the transaction rolled back the knowledge base
  assert_eq(kb.serialize(), before.serialize())
  assert_true(kb.current(flat, other) is None)
}

///|
test "provide diverges on non-monotonic updates and run discards the state" {
  let cls = kb_class("mono")
  let slot = cls.property(
    name=kb_name("mono-value"),
    domain=opt_string_domain("mono"),
  )
  let init = @knowledge.State::new()
  let obj = init.create(cls)
  init.provide(slot, obj, Some("a"))
  let result = @knowledge.run(
    cls,
    kb => {
      kb.provide(slot, obj, Some("a"))
      kb.provide(slot, obj, Some("b"))
      obj
    },
    init,
  )
  match result {
    Err(err) => {
      assert_true(err is @knowledge.NonMonotonicUpdate(_))
      assert_true(
        @knowledge.Conflict::to_string(err).has_prefix(
          "Unable to update the slot",
        ),
      )
    }
    Ok(_) => fail("expected a conflict")
  }
  assert_eq(init.current(slot, obj), Some("a"))
  // providing empty values or to the null object is a no-op
  init.provide(slot, obj, None)
  init.provide(slot, @knowledge.Object::null(cls), Some("zzz"))
  assert_eq(init.current(slot, obj), Some("a"))
  assert_eq(init.collect(slot, @knowledge.Object::null(cls)), None)
}

///|
test "rejected promises evaluate to bottom and roll back their effects" {
  let cls = kb_class("rejecting")
  let input = cls.property(
    name=kb_name("rejecting-input"),
    domain=opt_string_domain("in"),
  )
  let side = cls.property(
    name=kb_name("rejecting-side"),
    domain=opt_string_domain("side"),
  )
  let output = cls.property(
    name=kb_name("rejecting-output"),
    domain=opt_string_domain("out"),
  )
  ignore(
    output.promise((kb, obj) => {
      // an effect that must be discarded when the promise is rejected
      kb.provide(side, obj, Some("touched"))
      let x = kb.require_some(input, obj)
      Some("out:" + x)
    }),
  )
  ignore(
    output.promise((_, _) => {
      @knowledge.guard_(false)
      Some("never")
    }),
  )
  let kb = @knowledge.State::new()
  let missing = kb.create(cls)
  assert_eq(kb.collect(output, missing), None)
  assert_eq(kb.current(side, missing), None)
  let present = kb.create(cls)
  kb.provide(input, present, Some("x"))
  assert_eq(kb.collect(output, present), Some("out:x"))
  assert_eq(kb.current(side, present), Some("touched"))
}

///|
test "with_empty catches rejections only" {
  let cls = kb_class("with-empty")
  let slot = cls.property(
    name=kb_name("with-empty-v"),
    domain=opt_string_domain("v"),
  )
  let kb = @knowledge.State::new()
  let obj = kb.create(cls)
  let r = kb.with_empty(missing=-1, () => {
    kb.provide(slot, obj, Some("rolled back"))
    ignore(kb.require(slot, kb.create(cls)))
    1
  })
  assert_eq(r, -1)
  assert_eq(kb.current(slot, obj), None)
  assert_eq(kb.with_empty(missing=0, () => @knowledge.reject()), 0)
  assert_eq(
    kb.with_empty(missing=0, () => {
      @knowledge.proceed(unless=true)
      1
    }),
    0,
  )
  assert_eq(
    kb.with_empty(missing=0, () => {
      @knowledge.on(true, () => ())
      @knowledge.unless(false, () => ())
      2
    }),
    2,
  )
  assert_eq(
    kb.with_empty(missing=0, () => {
      @knowledge.unless(true, () => ())
      3
    }),
    0,
  )
  // other conflicts propagate
  let failed = kb.transaction(() => {
    kb.with_empty(missing=0, () => raise @knowledge.Failure("boom"))
  })
  assert_true(failed is Err(@knowledge.Failure("boom")))
  // catch_ restores the state and runs the handler
  let handled = kb.catch_(
    () => {
      kb.provide(slot, obj, Some("lost"))
      raise @knowledge.Failure("oops")
    },
    err => @knowledge.Conflict::to_string(err),
  )
  assert_eq(handled, "oops")
  assert_eq(kb.current(slot, obj), None)
}

///|
test "promising and observing are scoped, observers chain forward" {
  let cls = kb_class("chain")
  let src = cls.property(name=kb_name("chain-src"), domain=int_domain("src"))
  let dst = cls.property(name=kb_name("chain-dst"), domain=int_domain("dst"))
  let seen = []
  let pid = src.observe((kb, obj, v) => {
    seen.push(v)
    kb.provide(dst, obj, v * 10)
  })
  let kb = @knowledge.State::new()
  let obj = kb.create(cls)
  kb.provide(src, obj, 3)
  assert_eq(kb.current(dst, obj), 30)
  src.unobserve(pid)
  kb.provide(src, obj, 4)
  assert_eq(seen, [3])
  assert_eq(kb.current(dst, obj), 30)
  let other = kb.create(cls)
  let during = src.promising(promise=(_, _) => 7, () => kb.collect(src, other))
  assert_eq(during, 7)
  assert_eq(src.promise_count(), 0)
  let third = kb.create(cls)
  assert_eq(kb.collect(src, third), 0)
  let observed = dst.observing(observe=(_, _, v) => seen.push(v), () => {
    kb.provide(dst, third, 9)
    kb.current(dst, third)
  })
  assert_eq(observed, 9)
  assert_eq(seen, [3, 9])
  assert_eq(dst.observer_count(), 0)
}

///|
test "scoped objects are deleted with their facts" {
  let cls = kb_class("scoped")
  let slot = cls.property(name=kb_name("scoped-v"), domain=int_domain("v"))
  let kb = @knowledge.State::new()
  let keep = kb.create(cls)
  kb.provide(slot, keep, 1)
  let (inner, seen) = kb.scoped(cls, obj => {
    kb.provide(slot, obj, 42)
    (obj, kb.current(slot, obj))
  })
  assert_eq(seen, 42)
  assert_eq(kb.current(slot, inner), 0)
  assert_eq(kb.objects(cls).length(), 1)
  assert_true(kb.objects(cls)[0].equal(keep))
  let v = kb.value(cls, inner)
  assert_true(v.is_empty())
}

///|
test "symbols are interned per package, imported and made public" {
  let cls = kb_class("sym")
  let other_cls = kb_class("sym-other")
  let kb = @knowledge.State::new()
  let pub_x = kb.intern_symbol("x", cls, public=true, pkg="lib")
  let priv_y = kb.intern_symbol("y", cls, pkg="lib")
  ignore(kb.intern_symbol("z", other_cls, public=true, pkg="lib"))
  assert_true(kb.intern_symbol("x", cls, pkg="lib").equal(pub_x))
  // not visible in the user package before importing
  let user_x = kb.read(cls, "x").unwrap()
  assert_true(!user_x.equal(pub_x))
  kb.in_package("app", () => {
    kb.import_(["lib"])
    assert_true(kb.read(cls, "x").unwrap().equal(pub_x))
    // the import only brings public symbols
    assert_true(!kb.read(cls, "y").unwrap().equal(priv_y))
    // the printer still shows the home package
    assert_eq(kb.repr(pub_x), "lib:x")
  }) catch {
    err => fail(@knowledge.Conflict::to_string(err))
  }
  assert_eq(kb.current_pkg(), "user")
  // qualified names import non-public symbols
  kb.import_(["lib:y"], pkg="app2")
  assert_true(kb.read(cls, "y", pkg="app2").unwrap().equal(priv_y))
  // strict imports refuse to shadow; non-strict imports shadow
  let own = kb.intern_symbol("x", cls, pkg="app3")
  let strict = kb.transaction(() => kb.import_(["lib"], strict=true, pkg="app3"))
  assert_true(strict is Err(@knowledge.ImportConflict(_, _)))
  assert_true(kb.read(cls, "x", pkg="app3").unwrap().equal(own))
  kb.import_(["lib"], pkg="app3")
  assert_true(kb.read(cls, "x", pkg="app3").unwrap().equal(pub_x))
  // unknown packages and symbols
  assert_true(
    kb.transaction(() => kb.import_(["nowhere"]))
    is Err(@knowledge.NotAPackage("nowhere")),
  )
  assert_true(
    kb.transaction(() => kb.import_(["lib:nothing"]))
    is Err(@knowledge.NotASymbol(_)),
  )
  // keywords live in the keyword package
  let kw = kb.read(cls, ":kw").unwrap()
  assert_eq(kb.repr(kw), ":kw")
}

///|
test "context variables are part of the (rolled back) state" {
  let counter : @knowledge.Var[Int] = @knowledge.Var::new(
    "counter",
    _ => 0,
    pkg="kb-test",
    inspect=x => x.to_string(),
  )
  assert_eq(counter.name().show(), "kb-test:counter")
  let kb = @knowledge.State::new()
  assert_eq(counter.get(kb), 0)
  counter.set(kb, 5)
  counter.update(kb, x => x + 1)
  assert_eq(counter.get(kb), 6)
  let inside = counter.with_(kb, 100, () => counter.get(kb))
  assert_eq(inside, 100)
  assert_eq(counter.get(kb), 6)
  // isolation: forks and runs do not affect the original state
  let fork = kb.fork()
  counter.set(fork, 42)
  assert_eq(counter.get(kb), 6)
  let (r, after) = @knowledge.eval(
    kb => {
      counter.set(kb, 7)
      counter.get(kb)
    },
    kb,
  ).unwrap()
  assert_eq(r, 7)
  assert_eq(counter.get(after), 7)
  assert_eq(counter.get(kb), 6)
  // rejected computations roll the variables back
  kb.with_empty(missing=(), () => {
    counter.set(kb, 1000)
    @knowledge.reject()
  }) catch {
    _ => fail("unexpected")
  }
  assert_eq(counter.get(kb), 6)
  assert_eq(counter.inspect(3), "3")
}

///|
test "run computes all promised properties into a value" {
  let cls = kb_class("run")
  let a = cls.property(name=kb_name("run-a"), domain=int_domain("a"))
  let b = cls.property(name=kb_name("run-b"), domain=int_domain("b"))
  let c = cls.property(name=kb_name("run-c"), domain=int_domain("c"))
  ignore(b.promise((kb, obj) => kb.collect(a, obj) + 1))
  let (value, state) = @knowledge.run(
    cls,
    kb => {
      let obj = kb.create(cls)
      kb.provide(a, obj, 41)
      obj
    },
    @knowledge.State::new(),
  ).unwrap()
  assert_eq(value.get(a), 41)
  assert_eq(value.get(b), 42)
  assert_eq(value.get(c), 0)
  assert_true(value.has(b) && !value.has(c))
  assert_eq(value.inspect(), "((kb-test:run-a 41) (kb-test:run-b 42))")
  assert_eq(value.inspect_slots(["run-b"]), "42")
  assert_eq(state.objects(cls).length(), 1)
  assert_true(value.cls().same(cls))
}

///|
test "values are records ordered by information content" {
  let cls = kb_class("val")
  let x = cls.property(name=kb_name("val-x"), domain=opt_string_domain("x"))
  let y = cls.property(name=kb_name("val-y"), domain=opt_string_domain("y"))
  let empty = @knowledge.Value::empty(cls)
  assert_true(empty.is_empty())
  let vx = empty.put(x, Some("1"))
  let vy = empty.put(y, Some("2"))
  assert_true(vx.order(vy) == Incomparable)
  assert_true(empty.order(vx) == Less)
  let joined = vx.join(vy)
  assert_eq(joined.get(x), Some("1"))
  assert_eq(joined.get(y), Some("2"))
  assert_true(vx.order(joined) == Less)
  let conflicting = vx.put(x, Some("other"))
  try vx.join(conflicting) catch {
    @knowledge.JoinConflict(_) => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected a join conflict")
  }
  // merge resolves conflicts by age (drop the older value by default)
  let merged = vx.merge(conflicting)
  assert_eq(merged.get(x), Some("other"))
  assert_eq(conflicting.merge(vx).get(x), Some("other"))
  assert_eq(vx.merge(conflicting, on_conflict=DropNew).get(x), Some("1"))
  assert_eq(vx.merge(conflicting, on_conflict=DropLeft).get(x), Some("other"))
  assert_eq(vx.merge(conflicting, on_conflict=DropRight).get(x), Some("1"))
  // refine keeps the information and the age
  let refined : @knowledge.Value[Unit, String] = vx.refine("sorted")
  assert_eq(refined.cls().sort(), "sorted")
  assert_eq(refined.get(x), Some("1"))
  assert_true(vx.put(x, None).equal(vx))
  assert_eq(vx.require_some(x), "1")
  try vy.require_some(x) catch {
    @knowledge.Empty(_) => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected an empty conflict")
  }
  // values form a domain, so they can be properties of other objects
  let holder = kb_class("val-holder")
  let slot = holder.property(
    name=kb_name("val-holder-v"),
    domain=@knowledge.Value::domain(cls),
  )
  let kb = @knowledge.State::new()
  let obj = kb.create(holder)
  kb.provide(slot, obj, vx)
  kb.provide(slot, obj, vy)
  assert_eq(kb.current(slot, obj).get(y), Some("2"))
  assert_eq(kb.current(slot, obj).get(x), Some("1"))
}

///|
test "persistent slots survive a save/load round trip" {
  let cls = kb_class("persisted")
  let kept = cls.property(
    name=kb_name("persisted-kept"),
    domain=opt_string_domain("kept"),
    persistent=@knowledge.Persistent::optional(@knowledge.Persistent::string()),
  )
  let dropped = cls.property(
    name=kb_name("persisted-dropped"),
    domain=int_domain("dropped"),
  )
  let runs = Ref(0)
  ignore(
    kept.promise((_, _) => {
      runs.val += 1
      Some("computed\u{0}with:odd\ncharacters")
    }),
  )
  let kb = @knowledge.State::new()
  let sym = kb.intern_symbol("main", cls, pkg="prog")
  kb.provide(dropped, sym, 5)
  let anon = kb.create(cls)
  ignore(kb.collect(kept, anon))
  ignore(kb.collect(kept, sym))
  assert_eq(runs.val, 2)
  let data = kb.to_bytes()
  let loaded = @knowledge.State::of_bytes(data)
  assert_eq(loaded.serialize(), kb.serialize())
  assert_eq(
    loaded.current(kept, anon),
    Some("computed\u{0}with:odd\ncharacters"),
  )
  assert_eq(loaded.current(dropped, sym), 0)
  assert_true(loaded.read(cls, "prog:main").unwrap().equal(sym))
  assert_eq(loaded.repr(sym), "prog:main")
  // computed properties are not recomputed after loading
  ignore(loaded.collect(kept, anon))
  assert_eq(runs.val, 2)
  // new objects do not reuse loaded identifiers
  assert_true(loaded.create(cls).id() > anon.id())
  // persisted values of a class
  let io = @knowledge.Value::persistent(cls)
  let v = @knowledge.Value::empty(cls).put(kept, Some("v")).put(dropped, 3)
  let back = io.decode(io.encode(v)).unwrap()
  assert_eq(back.get(kept), Some("v"))
  assert_eq(back.get(dropped), 0)
  try @knowledge.State::deserialize("garbage") catch {
    @knowledge.Failure(_) => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected a failure")
  }
  assert_true(loaded.pp().has_prefix("(in-package user)"))
}

///|
test "suggest, propose and resolve opinions in the knowledge base" {
  let weak = register_test_agent("kb-weak", Unreliable)
  let strong = register_test_agent("kb-strong", Reliable)
  let cls = kb_class("opinion")
  let empty : String? = None
  let slot = cls.property(
    name=kb_name("opinion-name"),
    domain=@knowledge.Domain::opinions(
      kb_name("opinion-name"),
      empty~,
      equal=optional_string_equal,
      inspect=inspect_optional_string,
    ),
  )
  ignore(slot.propose(weak, (_, _) => Some("weak")))
  let kb = @knowledge.State::new()
  let obj = kb.create(cls)
  kb.suggest(strong, slot, obj, Some("strong"))
  // the slot has a value, so the proposal is not run
  assert_eq(kb.resolve(slot, obj), Some("strong"))
  let other = kb.create(cls)
  assert_eq(kb.resolve(slot, other), Some("weak"))
}
