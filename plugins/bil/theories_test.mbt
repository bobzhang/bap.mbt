///|
fn f32_word(x : Float) -> @types.Word {
  try! @types.Word::of_int64(
    x.reinterpret_as_uint().to_uint64().reinterpret_as_int64(),
    width=32,
  )
}

///|
fn f64_word(x : Double) -> @types.Word {
  try! @types.Word::of_int64(x.reinterpret_as_int64(), width=64)
}

///|
/// The BIL expression of a binary operation on the float variables `x` and
/// `y` of the given format, in the FP-emulating BIL theory.
fn fp_binop(
  bits : Int,
  op : (@core_theory.Core, @core_theory.Pure, @core_theory.Pure) -> @core_theory.Pure,
) -> @types.Exp raise {
  let state = @knowledge.State::new()
  let ct = @bil.bil_fp_theory()
  let p = @core_theory.Ieee754Parameters::binary(bits).unwrap()
  let fs = @core_theory.Sort::ieee754(p)
  let x = ct.var_(@core_theory.Var::create(fs, "x"))
  let y = ct.var_(@core_theory.Var::create(fs, "y"))
  op(ct, x, y)(state).bil().unwrap()
}

///|
fn eval2(e : @types.Exp, x : @types.Word, y : @types.Word) -> @types.Word raise {
  match e.eval({ "x": x, "y": y }) {
    Ok(w) => w
    Err(msg) => fail(msg)
  }
}

///|
let f32_samples : Array[Float] = [
  1.0, 2.0, 3.0, 0.5, -1.5, 100.25, 1.0e-3, -7.75, 3.4e38, 1.0e-40, 0.0, 12345.678,
]

///|
fn check_f32(
  name : String,
  op : (@core_theory.Core, @core_theory.Pure, @core_theory.Pure) -> @core_theory.Pure,
  native : (Float, Float) -> Float,
) -> Array[String] raise {
  let e = fp_binop(32, op)
  let wrong = []
  for a in f32_samples {
    for b in f32_samples {
      let got = eval2(e, f32_word(a), f32_word(b))
      let expected = f32_word(native(a, b))
      if got != expected {
        wrong.push(
          "\{name} \{a} \{b}: \{got.to_string()} /= \{expected.to_string()}",
        )
      }
    }
  }
  wrong
}

///|
test "floating-point emulation of binary32 arithmetic" {
  let add = check_f32("fadd", (ct, x, y) => ct.fadd(ct.rne, x, y), (a, b) => {
    a + b
  })
  // all results agree with the native arithmetic, except the sign of the
  // NaN of 0/0 (upstream `qnan` sets the sign bit)
  debug_inspect(
    add,
    content=(
      #|[]
    ),
  )
  let sub = check_f32("fsub", (ct, x, y) => ct.fsub(ct.rne, x, y), (a, b) => {
    a - b
  })
  debug_inspect(
    sub,
    content=(
      #|[]
    ),
  )
  let mul = check_f32("fmul", (ct, x, y) => ct.fmul(ct.rne, x, y), (a, b) => {
    a * b
  })
  debug_inspect(
    mul,
    content=(
      #|[]
    ),
  )
  let div = check_f32("fdiv", (ct, x, y) => ct.fdiv(ct.rne, x, y), (a, b) => {
    a / b
  })
  debug_inspect(
    div,
    content=(
      #|["fdiv 0 0: 0xFFC00000:32u /= 0x7FC00000:32u"]
    ),
  )
}

///|
test "floating-point emulation of binary64 arithmetic" {
  let samples : Array[Double] = [1.0, 0.1, -2.5, 1.0e300, 3.0e-310, 42.0, -0.0]
  let ops : Array[
    (
      String,
      (@core_theory.Core, @core_theory.Pure, @core_theory.Pure) -> @core_theory.Pure,
      (Double, Double) -> Double,
    ),
  ] = [
    ("fadd", (ct, x, y) => ct.fadd(ct.rne, x, y), (a, b) => a + b),
    ("fsub", (ct, x, y) => ct.fsub(ct.rne, x, y), (a, b) => a - b),
    ("fmul", (ct, x, y) => ct.fmul(ct.rne, x, y), (a, b) => a * b),
    ("fdiv", (ct, x, y) => ct.fdiv(ct.rne, x, y), (a, b) => a / b),
  ]
  let wrong = []
  for op in ops {
    let e = fp_binop(64, op.1)
    for a in samples {
      for b in samples {
        let got = eval2(e, f64_word(a), f64_word(b))
        let expected = f64_word((op.2)(a, b))
        if got != expected {
          wrong.push(
            "\{op.0} \{a} \{b}: \{got.to_string()} /= \{expected.to_string()}",
          )
        }
      }
    }
  }
  debug_inspect(
    wrong,
    content=(
      #|["fdiv 0 0: 0xFFF8000000000000:64u /= 0x7FF8000000000000:64u"]
    ),
  )
}

///|
test "floating-point square roots, casts and predicates" {
  let state = @knowledge.State::new()
  let ct = @bil.bil_fp_theory()
  let fs = @core_theory.Sort::ieee754(
    @core_theory.Ieee754Parameters::binary32(),
  )
  let s32 = @core_theory.Sort::bitv(32)
  let x = ct.var_(@core_theory.Var::create(fs, "x"))
  let i = ct.var_(@core_theory.Var::create(s32, "x"))
  let eval1 = (t : @core_theory.Pure, arg : @types.Word) => {
    let e = t(state).bil().unwrap()
    match e.eval({ "x": arg }) {
      Ok(w) => w.to_string()
      Err(msg) => "error: " + msg
    }
  }
  // upstream computes binary32 square roots in binary64 with the binary128
  // polynomial coefficients truncated to 64 bits, which is wrong (faithfully
  // ported); binary64 square roots are exact, see below. Likewise upstream
  // `is_inf` tests the coefficient with the implicit leading bit, so it
  // never holds for binary32/binary64 infinities.
  let sqrt = ct.fsqrt(ct.rne, x)
  let results = []
  let roots : Array[Float] = [4.0, 2.0, 0.25, 0.0, 1.0e10]
  for a in roots {
    let expected = f32_word(a.sqrt()).to_string()
    results.push("sqrt \{a}: \{eval1(sqrt, f32_word(a))} (native \{expected})")
  }
  let to_int = ct.cast_sint(s32, ct.rne, x)
  results.push("cast_sint -7.5: \{eval1(to_int, f32_word(-7.5))}")
  let of_int = ct.cast_sfloat(fs, ct.rne, i)
  let minus3 = try! @types.Word::of_int(width=32, -3)
  results.push(
    "cast_sfloat -3: \{eval1(of_int, minus3)} (native \{f32_word(-3.0).to_string()})",
  )
  let nan : Float = 0.0 / 0.0
  let inf : Float = 1.0 / 0.0
  for
    p in [
      ("is_nan", ct.is_nan(x)),
      ("is_inf", ct.is_inf(x)),
      ("is_finite", ct.is_finite(x)),
      ("is_fzero", ct.is_fzero(x)),
      ("is_fneg", ct.is_fneg(x)),
    ] {
    let vals = [nan, inf, 0.0, -1.0].map(v => eval1(p.1, f32_word(v)))
    results.push("\{p.0}: \{vals.join(" ")}")
  }
  let y = ct.var_(@core_theory.Var::create(fs, "y"))
  let lt = ct.forder(x, y)(state).bil().unwrap()
  let order = (a : Float, b : Float) => {
    eval2(lt, f32_word(a), f32_word(b)).to_string()
  }
  results.push(
    "forder 1 2: \{order(1.0, 2.0)}, 2 1: \{order(2.0, 1.0)}, -1 1: \{order(-1.0, 1.0)}",
  )
  inspect(
    results.join("\n"),
    content=(
      #|sqrt 4: 0x7F800000:32u (native 0x40000000:32u)
      #|sqrt 2: 0xFF800000:32u (native 0x3FB504F3:32u)
      #|sqrt 0.25: 0x7F800000:32u (native 0x3F000000:32u)
      #|sqrt 0: 0:32u (native 0:32u)
      #|sqrt 10000000000: 0xFF800000:32u (native 0x47C35000:32u)
      #|cast_sint -7.5: 0xFFFFFFF9:32u
      #|cast_sfloat -3: 0xC0400000:32u (native 0xC0400000:32u)
      #|is_nan: 1:1u 0:1u 0:1u 0:1u
      #|is_inf: 0:1u 0:1u 0:1u 0:1u
      #|is_finite: 0:1u 0:1u 1:1u 1:1u
      #|is_fzero: 0:1u 0:1u 1:1u 0:1u
      #|is_fneg: 0:1u 0:1u 0:1u 1:1u
      #|forder 1 2: 1:1u, 2 1: 0:1u, -1 1: 1:1u
    ),
  )
}

///|
test "binary64 square roots" {
  let state = @knowledge.State::new()
  let ct = @bil.bil_fp_theory()
  let fs = @core_theory.Sort::ieee754(
    @core_theory.Ieee754Parameters::binary64(),
  )
  let x = ct.var_(@core_theory.Var::create(fs, "x"))
  let e = ct.fsqrt(ct.rne, x)(state).bil().unwrap()
  let results = []
  for a in [4.0, 2.0, 0.25, 1.0e10] {
    let got = match e.eval({ "x": f64_word(a) }) {
      Ok(w) => w.to_string()
      Err(msg) => msg
    }
    results.push("\{a}: \{got} (native \{f64_word(a.sqrt()).to_string()})")
  }
  inspect(
    results.join("\n"),
    content=(
      #|4: 0x4000000000000000:64u (native 0x4000000000000000:64u)
      #|2: 0x3FF6A09E667F3BCD:64u (native 0x3FF6A09E667F3BCD:64u)
      #|0.25: 0x3FE0000000000000:64u (native 0x3FE0000000000000:64u)
      #|10000000000: 0x40F86A0000000000:64u (native 0x40F86A0000000000:64u)
    ),
  )
}

///|
test "the BIL theories" {
  let state = @knowledge.State::new()
  let ct = @bil.bil_theory()
  let s8 = @core_theory.Sort::bitv(8)
  let r = @core_theory.Var::create(s8, "r")
  // binding a constant substitutes and simplifies (upstream recursive_simpl)
  let t = @core_theory.Var::scoped_pure(s8, v => {
    ct.let_(
      v,
      ct.of_int(s8, 2),
      ct.add(ct.add(ct.var_(v), ct.of_int(s8, 3)), ct.var_(r)),
    )
  })
  inspect(
    t(state).bil().unwrap().to_string(),
    content=(
      #|(5:8u + r:imm8)
    ),
  )
  // floating-point operations are empty without the emulation
  let fs = @core_theory.Sort::ieee754(
    @core_theory.Ieee754Parameters::binary32(),
  )
  let x = ct.var_(@core_theory.Var::create(fs, "x"))
  assert_eq(ct.fadd(ct.rne, x, x)(state).bil(), None)
  // unsupported formats are unknown
  let fp = @bil.bil_fp_theory()
  let dec = @core_theory.Sort::ieee754(
    @core_theory.Ieee754Parameters::decimal64(),
  )
  let d = fp.var_(@core_theory.Var::create(dec, "d"))
  inspect(
    fp.fadd(fp.rne, d, d)(state).bil().unwrap().to_string(),
    content=(
      #|unknown(unk:imm64)
    ),
  )
  // declarations
  @bil.declare_theories()
  @bil.declare_theories()
  let names = @core_theory.declared_theories().map(t => t.name.show())
  assert_true(names.contains("bap:bil"))
  assert_true(names.contains("bap:bil-fp-emu"))
  let inst = @core_theory.instance(state, requires=["floating-point"])
  let core = @core_theory.require(state, inst)
  assert_true(core.fadd(core.rne, x, x)(state).bil() is Some(_))
}
