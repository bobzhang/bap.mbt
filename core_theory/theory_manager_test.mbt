///|
/// A test property of values: the constant value of an expression.
let test_const : @knowledge.Slot[@core_theory.ValueCls, Int?] = @core_theory.Value::cls().property(
  name=@knowledge.Name::create("const", pkg="core-test"),
  domain=@knowledge.Domain::optional(
    @knowledge.Domain::flat(@knowledge.Name::create("const", pkg="core-test"), n => {
      n.to_string()
    }),
  ),
)

///|
/// A test property of effects: the name of the assigned variable.
let test_written : @knowledge.Slot[@core_theory.EffectCls, String?] = @core_theory.Effect::cls().property(
  name=@knowledge.Name::create("written", pkg="core-test"),
  domain=@knowledge.Domain::optional(
    @knowledge.Domain::flat(
      @knowledge.Name::create("written", pkg="core-test"),
      text => text,
    ),
  ),
)

///|
/// A tiny constant-folding theory that only knows `int`, `add` and `set`.
fn const_theory() -> @core_theory.Core {
  {
    ..@core_theory.Core::empty(),
    int: (s, w) => {
      _ => @core_theory.Value::empty(s).put(test_const, Some(w.to_int()))
    },
    add: (x, y) => {
      state => {
        let x = x(state)
        let y = y(state)
        let result = @core_theory.Value::empty(x.sort())
        match (x.get(test_const), y.get(test_const)) {
          (Some(a), Some(b)) => result.put(test_const, Some(a + b))
          _ => result
        }
      }
    },
    set: (v, _) => {
      _ => {
        @core_theory.Effect::empty(@core_theory.EffectSort::bot()).put(
          test_written,
          Some(v.name()),
        )
      }
    },
  }
}

///|
fn declare_test_theories() -> Unit raise {
  if @core_theory.declared_theories()
    .iter()
    .any(doc => doc.name.show() == "core-test:bil") {
    return
  }
  @core_theory.declare_theory(
    name="bil",
    pkg="core-test",
    desc="BIL for tests",
    provides=["test-bil"],
    _ => @core_theory.Core::bil(),
  )
  @core_theory.declare_theory(
    name="consts",
    pkg="core-test",
    provides=["test-consts"],
    _ => const_theory(),
  )
  @core_theory.declare_theory(
    name="arm-only",
    pkg="core-test",
    context=["test-arm"],
    provides=["test-arch"],
    _ => const_theory(),
  )
  @core_theory.declare_theory(
    name="bil-ext",
    pkg="core-test",
    extends=["core-test:bil"],
    provides=["test-ext"],
    _ => @core_theory.Core::bil(),
  )
}

///|
test "theory join: properties of both theories are joined" {
  let state = @knowledge.State::new()
  let ct = @core_theory.Core::bil().join(const_theory())
  let s8 = @core_theory.Sort::bitv(8)
  let evaluations = Ref(0)
  let one : @core_theory.Pure = state => {
    evaluations.val += 1
    ct.of_int(s8, 1)(state)
  }
  let sum = ct.add(one, ct.of_int(s8, 2))(state)
  // the argument is evaluated once and shared by both theories
  assert_eq(evaluations.val, 1)
  assert_true(sum.sort() == s8)
  assert_eq(sum.get(test_const), Some(3))
  inspect(
    sum.bil().map(exp => exp.to_string()).unwrap_or(""),
    content=(
      #|(1:8u + 2:8u)
    ),
  )
  // operations unknown to one theory get only the properties of the other
  let x = ct.var_(@core_theory.Var::create(s8, "x"))
  let product = ct.mul(x, x)(state)
  assert_true(product.get(test_const) is None)
  assert_true(product.bil() is Some(_))
  let r = @core_theory.Var::create(s8, "R")
  let effect = ct.set(r, ct.add(one, one))(state)
  assert_eq(effect.get(test_written), Some("R"))
  inspect(
    effect.bil().map(stmt => stmt.to_string()).join("; "),
    content=(
      #|R:imm8 := (1:8u + 1:8u)
    ),
  )
}

///|
test "semantics provided by two theories are joined in the knowledge base" {
  let state = @knowledge.State::new()
  let s32 = @core_theory.Sort::bitv(32)
  let r = @core_theory.Var::create(s32, "R0")
  // a theory-polymorphic lifter of `R0 := 1 + 2`
  let lift : (@core_theory.Core) -> @core_theory.Eff = ct => {
    ct.set(r, ct.add(ct.of_int(s32, 1), ct.of_int(s32, 2)))
  }
  let label = state.create(@core_theory.Program::cls())
  let slot = @core_theory.Semantics::slot()
  for ct in [@core_theory.Core::bil(), const_theory()] {
    let effect = lift(ct)(state)
    state.provide(slot, label, @core_theory.Semantics::of_effect(effect))
  }
  let semantics = state.collect(slot, label)
  assert_eq(semantics.get(test_written), Some("R0"))
  inspect(
    semantics.bil().map(stmt => stmt.to_string()).join("; "),
    content=(
      #|R0:imm32 := (1:32u + 2:32u)
    ),
  )
}

///|
test "theory manager: declaration, selection and composition" {
  declare_test_theories()
  let state = @knowledge.State::new()
  let s8 = @core_theory.Sort::bitv(8)
  let term : (@core_theory.Core) -> @core_theory.Pure = ct => {
    ct.add(ct.of_int(s8, 1), ct.of_int(s8, 2))
  }
  // a single theory selected by the features it provides
  let bil = @core_theory.instance(state, requires=["test-bil"])
  let value = term(@core_theory.require(state, bil))(state)
  assert_true(value.bil() is Some(_))
  assert_true(value.get(test_const) is None)
  // instances are cached
  assert_true(@core_theory.instance(state, requires=["test-bil"]) == bil)
  // several theories are joined
  let both = @core_theory.instance(state, requires=["test-bil", "test-consts"])
  assert_true(both != bil)
  let value = term(@core_theory.require(state, both))(state)
  assert_true(value.bil() is Some(_))
  assert_eq(value.get(test_const), Some(3))
  // a theory is selected by its name
  let named = @core_theory.instance(state, requires=["core-test:consts"])
  let value = term(@core_theory.require(state, named))(state)
  assert_eq(value.get(test_const), Some(3))
  assert_true(value.bil() is None)
  // a theory is only applicable in its context
  let no_context = @core_theory.instance(state, requires=["test-arch"])
  let value = term(@core_theory.require(state, no_context))(state)
  assert_true(value.is_empty())
  let arm = @core_theory.instance(state, context=["test-arm"], requires=[
    "test-arch",
  ])
  let value = term(@core_theory.require(state, arm))(state)
  assert_eq(value.get(test_const), Some(3))
  // the requirement that no theory provides gives the empty theory
  let none = @core_theory.instance(state, requires=["no-such-feature"])
  assert_true(term(@core_theory.require(state, none))(state).is_empty())
  // a declared theory symbol requires its structure directly
  let symbol = state.intern_symbol(
    "consts",
    @core_theory.theory_class(),
    pkg="core-test",
  )
  let value = term(@core_theory.require(state, symbol))(state)
  assert_eq(value.get(test_const), Some(3))
  // documentation
  let docs = @core_theory.declared_theories().filter(doc => {
    doc.name.pkg() == "core-test"
  })
  inspect(
    docs
    .map(doc => {
      "\{doc.name.show()} [\{doc.requires.join(",")}] [\{doc.provides.join(",")}]"
    })
    .join("\n"),
    content=(
      #|core-test:bil [] [test-bil]
      #|core-test:consts [] [test-consts]
      #|core-test:arm-only [test-arm] [test-arch]
      #|core-test:bil-ext [] [test-ext]
    ),
  )
  // names are unique
  let duplicate = try
    @core_theory.declare_theory(name="bil", pkg="core-test", _ => {
      @core_theory.Core::empty()
    })
  catch {
    _ => true
  } noraise {
    _ => false
  }
  assert_true(duplicate)
}

///|
test "theory manager: subsumed theories are not instantiated" {
  let evaluated = Ref([])
  @core_theory.declare_theory(
    name="base",
    pkg="core-test-subsumption",
    provides=["test-base"],
    _ => {
      evaluated.val.push("base")
      const_theory()
    },
  )
  @core_theory.declare_theory(
    name="derived",
    pkg="core-test-subsumption",
    extends=["core-test-subsumption:base"],
    provides=["test-derived"],
    _ => {
      evaluated.val.push("derived")
      const_theory()
    },
  )
  let state = @knowledge.State::new()
  let t = @core_theory.instance(state, requires=["test-base", "test-derived"])
  ignore(@core_theory.require(state, t))
  ignore(@core_theory.require(state, t))
  assert_eq(evaluated.val, ["derived"])
  let t = @core_theory.instance(state, requires=["test-base"])
  ignore(@core_theory.require(state, t))
  assert_eq(evaluated.val, ["derived", "base"])
}

///|
test "theory manager: with_current scopes the current theory" {
  declare_test_theories()
  let state = @knowledge.State::new()
  let s8 = @core_theory.Sort::bitv(8)
  let bil = @core_theory.instance(state, requires=["test-bil"])
  let consts = @core_theory.instance(state, requires=["test-consts"])
  let add : @core_theory.Pure = state => {
    let ct = @core_theory.current(state)
    ct.add(ct.of_int(s8, 1), ct.of_int(s8, 1))(state)
  }
  @core_theory.with_current(state, bil, () => {
    assert_true(@core_theory.instance(state) == bil)
    assert_true(add(state).bil() is Some(_))
    @core_theory.with_current(state, consts, () => {
      assert_true(@core_theory.instance(state) == consts)
      let value = add(state)
      assert_eq(value.get(test_const), Some(2))
      assert_true(value.bil() is None)
    })
    // the previous theory is restored
    assert_true(@core_theory.instance(state) == bil)
    // explicit requirements ignore the current theory
    assert_true(
      @core_theory.instance(state, requires=["test-consts"]) == consts,
    )
    // the current theory is restored when the scope raises
    let raised = try
      @core_theory.with_current(state, consts, () => {
        fail("boom")
        ()
      })
    catch {
      _ => true
    } noraise {
      _ => false
    }
    assert_true(raised)
    assert_true(@core_theory.instance(state) == bil)
  })
  assert_true(@core_theory.instance(state) != bil)
}

///|
test "desugar: register aliases and constant registers" {
  let s64 = @core_theory.Sort::bitv(64)
  let s32 = @core_theory.Sort::bitv(32)
  let s8 = @core_theory.Sort::bitv(8)
  let rax = @core_theory.Var::create(s64, "RAX")
  let eax = @core_theory.Var::create(s32, "EAX")
  let ah = @core_theory.Var::create(s8, "AH")
  let al = @core_theory.Var::create(s8, "AL")
  let ax = @core_theory.Var::create(@core_theory.Sort::bitv(16), "AX")
  let layout = [
    @core_theory.Alias::def(rax, [
      @core_theory.Alias::unk(),
      @core_theory.Alias::reg(eax),
    ]),
    @core_theory.Alias::def(eax, [
      @core_theory.Alias::unk(),
      @core_theory.Alias::reg(ax),
    ]),
    @core_theory.Alias::def(ax, [
      @core_theory.Alias::reg(ah),
      @core_theory.Alias::reg(al),
    ]),
  ]
  let aliasing = []
  for spec in layout {
    match spec {
      Ok(spec) => aliasing.push(spec)
      Err(reason) => fail(reason)
    }
  }
  let target = @core_theory.Target::create(
    name=@knowledge.Name::create("desugar-target", pkg="core-test"),
    bits=64,
    vars=[rax, eax, ax, ah, al],
    aliasing~,
  )
  let ct = @core_theory.Core::bil().desugar()
  let x = @core_theory.Var::create(s8, "x")
  let with_target : (@core_theory.Target, () -> String raise) -> String raise = (
    target,
    f,
  ) => {
    @core_theory.Label::target_slot().promising(promise=(_, _) => target, () => {
      f()
    })
  }
  let state = @knowledge.State::new()
  let render = (term : @core_theory.Pure) => {
    with_target(target, () => {
      term(state).bil().map(exp => exp.to_string()).unwrap_or("<none>")
    })
  }
  let stmts = (term : @core_theory.Eff) => {
    with_target(target, () => {
      term(state).bil().map(stmt => stmt.to_string()).join("; ")
    })
  }
  let lines = [
    "AL: \{render(ct.var_(al))}",
    "AH: \{render(ct.var_(ah))}",
    "EAX: \{render(ct.var_(eax))}",
    "RAX: \{render(ct.var_(rax))}",
    "AL := x: \{stmts(ct.set(al, ct.var_(x)))}",
    "AH := x: \{stmts(ct.set(ah, ct.var_(x)))}",
    "EAX := RAX: \{stmts(ct.set(eax, ct.low(s32, ct.var_(rax))))}",
    // variables bound by let are never desugared
    "let AL: \{render(ct.let_(al, ct.var_(x), ct.var_(al)))}",
  ]
  inspect(
    lines.join("\n"),
    content=(
      #|AL: extract[7:0](RAX:imm64)
      #|AH: extract[15:8](RAX:imm64)
      #|EAX: extract[31:0](RAX:imm64)
      #|RAX: RAX:imm64
      #|AL := x: RAX:imm64 := concat(high:56[RAX:imm64], x:imm8)
      #|AH := x: RAX:imm64 := concat(concat(high:48[RAX:imm64], x:imm8), low:8[RAX:imm64])
      #|EAX := RAX: RAX:imm64 := concat(high:32[RAX:imm64], low:32[RAX:imm64])
      #|let AL: let AL:imm8 = x:imm8 in AL:imm8
    ),
  )
  // constant registers
  let riscv = @core_theory.Target::riscv64()
  guard riscv.find_var("X0") is Some(zero) else { fail("missing X0") }
  let read = with_target(riscv, () => {
    ct.var_(zero)(state).bil().map(exp => exp.to_string()).unwrap_or("<none>")
  })
  let write = with_target(riscv, () => {
    ct.set(zero, ct.var_(x))(state).bil().length().to_string()
  })
  inspect(
    "X0 = \{read}; writes: \{write}",
    content=(
      #|X0 = 0:64u; writes: 0
    ),
  )
  // the desugaring pass is registered
  let pass = @core_theory.lookup_pass("core:desugar-variables")
  let read = with_target(riscv, () => {
    pass(@core_theory.Core::bil()).var_(zero)(state)
    .bil()
    .map(exp => exp.to_string())
    .unwrap_or("<none>")
  })
  inspect(
    read,
    content=(
      #|0:64u
    ),
  )
}
