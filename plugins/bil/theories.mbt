// The BIL theories (upstream `plugins/bil/bil_semantics.ml` and the
// theory declarations of `bil_main.ml`/`bil_lifter.ml`/`bil_ir.ml`).

///|
/// `Bil_semantics.Core`: the theory that denotes Core Theory terms with
/// BIL (`@core_theory.Core::bil`), where binding a constant with `let_`
/// substitutes it and simplifies the resulting expression, as upstream's
/// `recursive_simpl`.
pub fn bil_theory() -> @core_theory.Core {
  let ct = @core_theory.Core::bil()
  {
    ..ct,
    let_: (v, rhs, body) => {
      state => {
        let r = rhs(state)
        match r.bil() {
          Some(Int(_) as c) => {
            let b = body(state)
            match b.bil() {
              Some(e) => {
                let e : @types.Exp = Let(v.reify(), c, e)
                b.put(@core_theory.bil_exp_slot(), Some(e.simplify()))
              }
              None => b
            }
          }
          _ => ct.let_(v, @core_theory.pure_const(r), body)(state)
        }
      }
    },
  }
}

///|
/// The IEEE-754 formats supported by the emulator.
let supported_formats : Array[@core_theory.Ieee754Parameters] = [
  @core_theory.Ieee754Parameters::binary16(),
  @core_theory.Ieee754Parameters::binary32(),
  @core_theory.Ieee754Parameters::binary64(),
  @core_theory.Ieee754Parameters::binary80(),
  @core_theory.Ieee754Parameters::binary128(),
]

///|
fn ieee754_of_sort(s : Sort) -> @core_theory.Ieee754Parameters? {
  for p in supported_formats {
    if s.same(Sort::ieee754(p)) {
      return Some(p)
    }
  }
  None
}

///|
/// `Bil_semantics.Emulator`: extends the theory `ct` with the emulation of
/// the IEEE-754 binary floating-point operations in bitvector arithmetic
/// (`Bil_float.Make(ct)`): `fadd`, `fsub`, `fmul`, `fdiv`, `fsqrt`, the
/// casts, the classification predicates and `forder`. Floats of other
/// formats are unknown values.
pub fn fp_emulation(ct : @core_theory.Core) -> @core_theory.Core {
  let fe : FE = { b: ct, }
  let pc = @core_theory.pure_const
  let fop = (op : (Sort, Pure, Pure, Pure) -> Pure) => {
    (rm : Pure, x : Pure, y : Pure) => {
      state => {
        let x = x(state)
        let y = y(state)
        let xs = x.sort()
        match ieee754_of_sort(xs) {
          None => ct.unk(xs)(state)
          Some(p) => {
            let bs = bits_sort(p.k)
            op(Sort::ieee754(p), rm, pc(x.refine(bs)), pc(y.refine(bs)))(state).refine(
              xs,
            )
          }
        }
      }
    }
  }
  let fuop = (op : (Sort, Pure, Pure) -> Pure) => {
    (rm : Pure, x : Pure) => {
      state => {
        let x = x(state)
        let xs = x.sort()
        match ieee754_of_sort(xs) {
          None => ct.unk(xs)(state)
          Some(p) =>
            op(Sort::ieee754(p), rm, pc(x.refine(bits_sort(p.k))))(state).refine(
              xs,
            )
        }
      }
    }
  }
  let make_cast_float = (cast : (Sort, Pure) -> Pure) => {
    (s : Sort, _rm : Pure, v : Pure) => {
      state => {
        match ieee754_of_sort(s) {
          None => ct.unk(s)(state)
          Some(p) => cast(Sort::ieee754(p), v)(state).refine(s)
        }
      }
    }
  }
  let cast_int = (ts : Sort, _rm : Pure, v : Pure) => {
    state => {
      let v = v(state)
      match ieee754_of_sort(v.sort()) {
        None => ct.unk(ts)(state)
        Some(p) =>
          fe.cast_int(Sort::ieee754(p), ts, pc(v.refine(bits_sort(p.k))))(state)
      }
    }
  }
  let case = (f : (Sort, Pure) -> Pure) => {
    (x : Pure) => {
      state => {
        let x = x(state)
        match ieee754_of_sort(x.sort()) {
          None => ct.unk(Sort::bool())(state)
          Some(p) => f(Sort::ieee754(p), pc(x.refine(bits_sort(p.k))))(state)
        }
      }
    }
  }
  let forder = (x : Pure, y : Pure) => {
    state => {
      let x = x(state)
      let y = y(state)
      match ieee754_of_sort(x.sort()) {
        None => ct.unk(Sort::bool())(state)
        Some(p) => {
          let bs = bits_sort(p.k)
          let ms = bits_sort(p.k - 1)
          let x = pc(x.refine(bs))
          let y = pc(y.refine(bs))
          let ws = bits_sort(p.w)
          let fs = bits_sort(p.t)
          let small = (s : Sort, n : Int) => ct.of_int(s, n)
          let ones = small(ws, -1)
          let zero = small(fs, 0)
          let expn = (v : Pure) => {
            ct.extract(ws, small(ws, p.t + p.w - 1), small(ws, p.t), v)
          }
          let frac = (v : Pure) => {
            ct.extract(fs, small(fs, p.t - 1), small(fs, 0), v)
          }
          let magn = (v : Pure) => {
            ct.extract(ms, small(ms, p.k - 2), small(ms, 0), v)
          }
          let not_nan = (v : Pure) => {
            ct.or_(ct.neq(expn(v), ones), ct.neq(frac(v), zero))
          }
          fe.bind(magn(x), mx => {
            fe.bind(magn(y), my => {
              fe.bind(ct.msb(x), x_is_neg => {
                fe.bind(ct.msb(y), y_is_neg => {
                  let x_is_pos = ct.inv(x_is_neg)
                  let y_is_pos = ct.inv(y_is_neg)
                  [
                    not_nan(y),
                    ct.inv(ct.and_(ct.is_zero(mx), ct.is_zero(my))),
                    ct.inv(ct.and_(x_is_pos, y_is_neg)),
                    ct.or_(
                      ct.and_(x_is_neg, y_is_pos),
                      ct.ite(x_is_neg, ct.ult(my, mx), ct.ult(mx, my)),
                    ),
                  ].fold(init=not_nan(x), (acc, t) => ct.and_(acc, t))
                })
              })
            })
          })(state)
        }
      }
    }
  }
  {
    ..ct,
    fbits: x => {
      state => {
        let x = x(state)
        match x.sort().float_bits() {
          Some(bits) => x.refine(bits)
          None => x
        }
      }
    },
    float: (s, x) => state => x(state).refine(s),
    fadd: fop((s, rm, x, y) => fe.fadd(s, rm, x, y)),
    fsub: fop((s, rm, x, y) => fe.fsub(s, rm, x, y)),
    fmul: fop((s, rm, x, y) => fe.fmul(s, rm, x, y)),
    fdiv: fop((s, rm, x, y) => fe.fdiv(s, rm, x, y)),
    fsqrt: fuop((s, rm, x) => fe.fsqrt(s, rm, x)),
    cast_float: make_cast_float((s, v) => fe.cast_float(s, v)),
    cast_sfloat: make_cast_float((s, v) => fe.cast_float_signed(s, v)),
    cast_int,
    cast_sint: cast_int,
    is_finite: case((s, x) => fe.is_finite(s, x)),
    is_nan: case((s, x) => fe.is_nan(s, x)),
    is_inf: case((s, x) => fe.is_inf(s, x)),
    is_fzero: case((_, x) => fe.is_fzero(x)),
    is_fpos: case((_, x) => ct.inv(ct.msb(x))),
    is_fneg: case((_, x) => ct.msb(x)),
    forder,
  }
}

///|
/// `Bil_semantics.Core_with_fp_emulation`: the BIL theory with the
/// floating-point emulation.
pub fn bil_fp_theory() -> @core_theory.Core {
  fp_emulation(bil_theory())
}

///|
fn is_declared(name : String) -> Bool {
  @core_theory.declared_theories().iter().any(t => t.name.show() == name)
}

///|
/// Declares the BIL theories (upstream `bil_main.ml`): `bap:bil` (the
/// semantics in BIL, providing `bil` and `lifter`) and, when `with_fp`,
/// `bap:bil-fp-emu` (extending `bap:bil` with the floating-point
/// emulation, providing also `floating-point`). Theories that are already
/// declared are left as they are.
pub fn declare_theories(with_fp? : Bool = true) -> Unit raise {
  if !is_declared("bap:bil") {
    @core_theory.declare_theory(
      name="bil",
      pkg="bap",
      desc="semantics in BIL",
      provides=["bil", "lifter"],
      _ => bil_theory(),
    )
  }
  if with_fp && !is_declared("bap:bil-fp-emu") {
    @core_theory.declare_theory(
      name="bil-fp-emu",
      pkg="bap",
      extends=["bap:bil"],
      desc="semantics in BIL, including FP emulation",
      provides=["bil", "floating-point", "lifter"],
      _ => bil_fp_theory(),
    )
  }
}
