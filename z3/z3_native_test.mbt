// Tests against the real solver. They are skipped (pass trivially) when
// the Z3 library cannot be loaded on the host.

///|
fn w(width : Int, n : Int) -> @types.Word {
  try! @types.Word::of_int(width~, n)
}

///|
test "satisfiable and unsatisfiable bitvector constraints" {
  if !@z3.is_available() {
    return
  }
  let ctx = @z3.Context::new()
  let s = @z3.Solver::new(ctx)
  let x = ctx.bv_const("x", 8)
  // x + 3 == 10
  s.add(x.add(ctx.bv_int(3L, 8)).eq(ctx.bv_int(10L, 8)))
  debug_inspect(s.check(), content="Sat")
  let m = s.model()
  inspect(m.eval_word(x).unwrap().to_string(), content="7:8u")
  // x < 5 contradicts x == 7
  s.push()
  s.add(x.ult(ctx.bv_int(5L, 8)))
  debug_inspect(s.check(), content="Unsat")
  inspect(s.num_scopes(), content="1")
  s.pop()
  debug_inspect(s.check(), content="Sat")
  inspect(s.num_scopes(), content="0")
}

///|
test "bitvector arithmetic models" {
  if !@z3.is_available() {
    return
  }
  let ctx = @z3.Context::new()
  let s = @z3.Solver::new(ctx, simple=true)
  s.set_timeout(10000)
  let x = ctx.bv_const("x", 32)
  let y = ctx.bv_const("y", 32)
  // x * y == 391 /\ 1 < x < y < 391 has the unique solution 17 * 23
  let c391 = ctx.bv_int(391L, 32)
  let one = ctx.bv_int(1L, 32)
  let m = s
    .check_formulas([
      x.mul(y).eq(c391),
      one.ult(x),
      x.ult(y),
      y.ult(c391),
      // no overflow: both factors below 2^16
      x.lshr(ctx.bv_int(16L, 32)).eq(ctx.bv_int(0L, 32)),
      y.lshr(ctx.bv_int(16L, 32)).eq(ctx.bv_int(0L, 32)),
    ])
    .unwrap()
  inspect(
    m.eval_word(x).unwrap().to_string(),
    content=(
      #|0x11:32u
    ),
  )
  inspect(
    m.eval_word(y).unwrap().to_string(),
    content=(
      #|0x17:32u
    ),
  )
  // the scope opened by check_formulas is closed again
  inspect(s.num_scopes(), content="0")
  // signed division and remainder, shifts, extraction and extensions
  let z = ctx.bv_const("z", 8)
  let m = s
    .check_formulas([
      z.sdiv(ctx.bv_int(3L, 8)).eq(ctx.bv_int(-5L, 8)),
      z.srem(ctx.bv_int(3L, 8)).eq(ctx.bv_int(-1L, 8)),
    ])
    .unwrap()
  inspect(
    m.eval_word(z).unwrap().to_string(),
    content=(
      #|0xF0:8u
    ),
  ) // -16
  let e = ctx.word(w(8, 0xf0)).sign_ext(8)
  inspect(
    e.simplify().to_word().unwrap().to_string(),
    content=(
      #|0xFFF0:16u
    ),
  )
  inspect(
    ctx.word(w(8, 0xf0)).zero_ext(8).simplify().to_word().unwrap().to_string(),
    content=(
      #|0xF0:16u
    ),
  )
  inspect(
    ctx
    .word(w(16, 0x1234))
    .extract(11, 4)
    .simplify()
    .to_word()
    .unwrap()
    .to_string(),
    content=(
      #|0x23:8u
    ),
  )
  inspect(
    ctx
    .word(w(8, 0x12))
    .concat(ctx.word(w(8, 0x34)))
    .simplify()
    .to_word()
    .unwrap()
    .to_string(),
    content=(
      #|0x1234:16u
    ),
  )
  inspect(
    ctx
    .word(w(8, 0x81))
    .ashr(ctx.bv_int(1L, 8))
    .simplify()
    .to_word()
    .unwrap()
    .to_string(),
    content=(
      #|0xC0:8u
    ),
  )
  inspect(
    ctx
    .word(w(8, 0x81))
    .rotate_left(1)
    .simplify()
    .to_word()
    .unwrap()
    .to_string(),
    content="3:8u",
  )
  inspect(
    ctx
    .bv_int(-1L, 8)
    .udiv(ctx.bv_int(16L, 8))
    .simplify()
    .to_word()
    .unwrap()
    .to_string(),
    content=(
      #|0xF:8u
    ),
  )
  inspect(
    ctx.bv_int(-1L, 8).neg().simplify().to_word().unwrap().to_string(),
    content="1:8u",
  )
  inspect(
    ctx.bv_int(5L, 8).redor().simplify().to_word().unwrap().to_string(),
    content="1:1u",
  )
}

///|
test "wide words round-trip through numerals" {
  if !@z3.is_available() {
    return
  }
  let ctx = @z3.Context::new()
  let big = @types.Word::from_hex(width=128, "fedcba9876543210f0e1d2c3b4a59687")
  let e = ctx.word(big)
  debug_inspect(e.sort(), content="BitVec(128)")
  assert_true(e.is_numeral())
  assert_true(e.to_word().unwrap() == big)
  inspect(
    e.numeral_string().unwrap(),
    content=(
      #|338770000845734292533317652709722396295
    ),
  )
  // arithmetic is modulo 2^128
  let s = @z3.Solver::new(ctx)
  let v = ctx.bv_const("v", 128)
  let m = s.check_formulas([v.add(e).eq(ctx.bv_int(0L, 128))]).unwrap()
  assert_true(m.eval_word(v).unwrap() == big.neg())
}

///|
test "boolean structure, ite and term identity" {
  if !@z3.is_available() {
    return
  }
  let ctx = @z3.Context::new()
  let p = ctx.bool_const("p")
  let q = ctx.bool_const("q")
  let s = @z3.Solver::new(ctx)
  assert_true(s.check_formulas([p.and_(p.not())]) is None)
  let m = s.check_formulas([p.or_(q), p.not(), q.implies(p).not()]).unwrap()
  debug_inspect(m.eval(p).unwrap().bool_value(), content="Some(false)")
  debug_inspect(m.eval(q).unwrap().bool_value(), content="Some(true)")
  let x = ctx.bv_const("x", 4)
  let t = ctx.ite(x.eq(ctx.bv_int(0L, 4)), ctx.bv_int(1L, 4), x)
  debug_inspect(t.sort(), content="BitVec(4)")
  inspect(t, content="(ite (= x #x0) #x1 x)")
  // hash-consing: equal terms are the same term
  let x2 = ctx.bv_const("x", 4)
  assert_true(x == x2)
  assert_eq(x.compare(x2), 0)
  assert_true(x != x.add(x))
  // all distinct 2-bit values: 4 fit, 5 do not
  let vs = [0, 1, 2, 3, 4].map(i => ctx.bv_const("d\{i}", 2))
  assert_true(s.check_formulas([ctx.distinct(vs[:4].to_owned())]) is Some(_))
  assert_true(s.check_formulas([ctx.distinct(vs)]) is None)
  assert_true(
    s.check_formulas([ctx.and_all([]), ctx.or_all([]).not()]) is Some(_),
  )
}

///|
test "errors are reported instead of aborting" {
  if !@z3.is_available() {
    return
  }
  let ctx = @z3.Context::new()
  let a = ctx.bv_const("a", 8)
  let b = ctx.bv_const("b", 16)
  // sort mismatch
  let r = try a.add(b) catch {
    Failure(_) => "failure"
    e => "unexpected: \{e}"
  } noraise {
    _ => "no error"
  }
  inspect(r, content="failure")
  // the context is still usable
  inspect(a.add(a), content="(bvadd a a)")
  let r = try a.extract(3, 5) catch {
    Failure(m) => m
    e => "unexpected: \{e}"
  } noraise {
    _ => "no error"
  }
  inspect(r, content="invalid extraction [3:5]")
}
