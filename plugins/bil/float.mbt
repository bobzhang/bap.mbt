// A port of upstream `plugins/bil/bil_float.ml`: IEEE-754 binary
// floating-point operations denoted in terms of bitvector arithmetic of an
// arbitrary Core Theory (upstream the functor `Bil_float.Make(B)`).
//
// Terms are direct-style knowledge computations (`@core_theory.Pure`);
// upstream's monadic binder `x >>>= f` (which binds the value of `x` to a
// fresh scoped variable with `let_`) is `self.bind(x, f)`, and upstream's
// `x >>-> f` (which inspects the sort of a value) is `with_sort(x, f)`.
// The operations are faithful to upstream, including its known
// imprecisions (e.g., `fsqrt` is computed with a polynomial and the
// rounding-mode dispatch of `is_round_up` treats `rtp` as the default).

///|
/// The emulator of floating-point operations over the theory `b`.
priv struct FE {
  b : @core_theory.Core
}

///|
using @core_theory {type Pure, type Sort}

///|
fn bits_sort(n : Int32) -> Sort {
  Sort::bitv(n)
}

///|
fn sort_size(s : Sort) -> Int32 {
  match s.bitv_size() {
    Some(n) => n
    None => if s == Sort::bool() { 1 } else { 0 }
  }
}

///|
/// `x >>-> f`: applies `f` to the sort and the value of `x`.
fn with_sort(x : Pure, f : (Sort, Pure) -> Pure) -> Pure {
  state => {
    let v = x(state)
    f(v.sort(), @core_theory.pure_const(v))(state)
  }
}

///|
/// A sequence of bindings (the flat form of a chain of `>>>=`): each
/// `bind` evaluates a term, binds its value to a fresh variable and
/// returns the variable; `FE::lets` wraps the result in the bindings.
priv struct Lets {
  fe : FE
  state : @knowledge.State
  binds : Array[(@core_theory.Var, @core_theory.Value)]
}

///|
fn Lets::bind(self : Lets, t : Pure) -> Pure raise {
  let v = t(self.state)
  let x = @core_theory.Var::fresh(v.sort())
  self.binds.push((x, v))
  self.fe.b.var_(x)
}

///|
fn FE::lets(self : FE, f : (Lets) -> Pure raise) -> Pure {
  state => {
    let l = { fe: self, state, binds: [], }
    let mut r = f(l)
    for i = l.binds.length() - 1; i >= 0; i = i - 1 {
      let (x, v) = l.binds[i]
      r = self.b.let_(x, @core_theory.pure_const(v), r)
    }
    r(state)
  }
}

///|
/// `x >>>= f`: binds the value of `x` to a fresh variable.
fn FE::bind(self : FE, a : Pure, body : (Pure) -> Pure) -> Pure {
  state => {
    let v = a(state)
    @core_theory.Var::scoped_pure(v.sort(), x => {
      self.b.let_(x, @core_theory.pure_const(v), body(self.b.var_(x)))
    })(state)
  }
}

///|
fn spec(fsort : Sort) -> @core_theory.Ieee754Parameters {
  match fsort.ieee754_spec() {
    Some(p) => p
    None => abort("Bil_float: not an IEEE-754 sort: \{fsort.to_string()}")
  }
}

///|
fn exps(fsort : Sort) -> Sort {
  bits_sort(spec(fsort).w)
}

///|
fn sigs(fsort : Sort) -> Sort {
  bits_sort(spec(fsort).p)
}

///|
fn fbits_sort(fsort : Sort) -> Sort {
  bits_sort(spec(fsort).k)
}

// Bitvector helpers (upstream module `B`).

///|
fn FE::of_int(self : FE, s : Sort, n : Int32) -> Pure {
  self.b.of_int(s, n)
}

///|
fn FE::one(self : FE, s : Sort) -> Pure {
  self.b.succ(self.b.zero(s))
}

///|
fn FE::ones(self : FE, s : Sort) -> Pure {
  self.b.not(self.b.zero(s))
}

///|
fn FE::is_one(self : FE, x : Pure) -> Pure {
  with_sort(x, (s, x) => self.b.eq(x, self.one(s)))
}

///|
fn FE::is_all_ones(self : FE, x : Pure) -> Pure {
  with_sort(x, (s, x) => self.b.eq(x, self.ones(s)))
}

///|
fn FE::testbit(self : FE, x : Pure, i : Pure) -> Pure {
  self.b.lsb(self.b.rshift(x, i))
}

///|
fn FE::abs(self : FE, x : Pure) -> Pure {
  self.b.ite(self.b.msb(x), self.b.neg(x), x)
}

///|
fn FE::max(self : FE, x : Pure, y : Pure) -> Pure {
  self.b.ite(self.b.ugt(x, y), x, y)
}

///|
fn FE::leading_one(self : FE, s : Sort) -> Pure {
  self.b.lshift(self.one(s), self.of_int(s, sort_size(s) - 1))
}

///|
fn FE::and3(self : FE, x : Pure, y : Pure, z : Pure) -> Pure {
  self.b.and_(self.b.and_(x, y), z)
}

///|
fn FE::xor(self : FE, s : Pure, s1 : Pure) -> Pure {
  self.b.and_(self.b.or_(s, s1), self.b.inv(self.b.and_(s, s1)))
}

// The representation of floats.

///|
fn FE::fsign(self : FE, x : Pure) -> Pure {
  self.b.msb(x)
}

///|
fn FE::exponent(self : FE, fsort : Sort, bitv : Pure) -> Pure {
  let p = spec(fsort)
  self.b.low(
    exps(fsort),
    self.b.rshift(bitv, self.of_int(fbits_sort(fsort), p.t)),
  )
}

///|
/// Packs the sign, the exponent and the (already `t`-bit) coefficient.
fn FE::pack_raw(
  self : FE,
  fsort : Sort,
  sign : Pure,
  expn : Pure,
  coef : Pure,
) -> Pure {
  let bits = fbits_sort(fsort)
  let bit = bits_sort(1)
  let bits_1 = bits_sort(sort_size(bits) - 1)
  let sign = self.b.ite(sign, self.one(bit), self.b.zero(bit))
  self.b.append(bits, sign, self.b.append(bits_1, expn, coef))
}

///|
fn FE::pack(
  self : FE,
  fsort : Sort,
  sign : Pure,
  expn : Pure,
  coef : Pure,
) -> Pure {
  let p = spec(fsort)
  let is_subnormal = self.b.and_(
    self.b.inv(self.b.msb(coef)),
    self.is_one(expn),
  )
  self.bind(self.b.ite(is_subnormal, self.b.pred(expn), expn), expn => {
    if p.p == p.t {
      self.pack_raw(fsort, sign, expn, coef)
    } else {
      self.bind(self.b.low(bits_sort(p.t), coef), coef => {
        self.pack_raw(fsort, sign, expn, coef)
      })
    }
  })
}

///|
fn FE::raw_significand(self : FE, fsort : Sort, bitv : Pure) -> Pure {
  self.b.low(bits_sort(spec(fsort).t), bitv)
}

///|
fn FE::finite_significand(
  self : FE,
  fsort : Sort,
  expn : Pure,
  bitv : Pure,
) -> Pure {
  let p = spec(fsort)
  self.bind(self.raw_significand(fsort, bitv), coef => {
    if p.t == p.p {
      coef
    } else {
      let bit = bits_sort(1)
      let leading = self.b.ite(
        self.b.is_zero(expn),
        self.b.zero(bit),
        self.one(bit),
      )
      self.b.append(sigs(fsort), leading, coef)
    }
  })
}

///|
fn FE::unpack(
  self : FE,
  fsort : Sort,
  x : Pure,
  f : (Pure, Pure, Pure) -> Pure,
) -> Pure {
  self.lets(l => {
    let (sign, expn, coef) = l.unpack(fsort, x)
    f(sign, expn, coef)
  })
}

///|
fn FE::unpack_raw(
  self : FE,
  fsort : Sort,
  x : Pure,
  f : (Pure, Pure, Pure) -> Pure,
) -> Pure {
  self.lets(l => {
    let (sign, expn, coef) = l.unpack_raw(fsort, x)
    f(sign, expn, coef)
  })
}

///|
fn FE::with_sign(self : FE, sign : Pure, bitv : Pure) -> Pure {
  with_sort(bitv, (s, bitv) => {
    let s1 = bits_sort(sort_size(s) - 1)
    let bit = bits_sort(1)
    self.b.ite(
      sign,
      self.b.logor(self.b.append(s, self.one(bit), self.b.zero(s1)), bitv),
      self.b.logand(self.b.append(s, self.b.zero(bit), self.ones(s1)), bitv),
    )
  })
}

///|
fn FE::fzero(self : FE, fsort : Sort, sign : Pure) -> Pure {
  let bits = fbits_sort(fsort)
  self.bind(self.b.zero(bits), bitv => {
    self.b.ite(
      sign,
      self.bind(self.ones(bits), ones => {
        self.bind(self.b.not(self.b.rshift(ones, self.one(bits))), one => {
          self.b.logor(one, bitv)
        })
      }),
      bitv,
    )
  })
}

///|
fn FE::fone(self : FE, fsort : Sort, sign : Pure) -> Pure {
  let p = spec(fsort)
  self.pack_raw(
    fsort,
    sign,
    self.of_int(exps(fsort), p.bias),
    self.b.zero(bits_sort(p.t)),
  )
}

///|
fn FE::inf(self : FE, fsort : Sort, sign : Pure) -> Pure {
  self.pack(fsort, sign, self.ones(exps(fsort)), self.b.zero(sigs(fsort)))
}

///|
fn FE::is_inf(self : FE, fsort : Sort, x : Pure) -> Pure {
  self.unpack(fsort, x, (_, expn, coef) => {
    self.b.and_(self.b.is_zero(coef), self.is_all_ones(expn))
  })
}

///|
fn FE::is_nan(self : FE, fsort : Sort, x : Pure) -> Pure {
  self.unpack_raw(fsort, x, (_, expn, coef) => {
    self.b.and_(self.is_all_ones(expn), self.b.non_zero(coef))
  })
}

///|
fn FE::qnan(self : FE, fsort : Sort) -> Pure {
  let p = spec(fsort)
  let s = bits_sort(p.t)
  self.bind(self.b.not(self.b.rshift(self.ones(s), self.one(s))), coef => {
    self.pack_raw(fsort, self.b.b1, self.ones(exps(fsort)), coef)
  })
}

///|
/// Sets the leading bit of the coefficient (no checks for nan).
fn FE::transform_to_quite(self : FE, fsort : Sort, x : Pure) -> Pure {
  let p = spec(fsort)
  let bits = fbits_sort(fsort)
  let mask = self.b.lshift(self.one(bits), self.of_int(bits, p.t - 1))
  self.b.logor(x, mask)
}

///|
fn FE::is_special(self : FE, fsort : Sort, x : Pure) -> Pure {
  self.unpack(fsort, x, (_, expn, _) => self.is_all_ones(expn))
}

///|
fn FE::is_finite(self : FE, fsort : Sort, x : Pure) -> Pure {
  self.b.inv(self.is_special(fsort, x))
}

///|
fn FE::is_finite_nonzero(self : FE, fsort : Sort, x : Pure) -> Pure {
  let b = self.b
  self.unpack_raw(fsort, x, (_, expn, coef) => {
    self.bind(b.inv(self.is_all_ones(expn)), ok_expn => {
      b.and_(ok_expn, b.or_(b.non_zero(expn), b.non_zero(coef)))
    })
  })
}

///|
fn FE::is_fzero(self : FE, x : Pure) -> Pure {
  with_sort(x, (s, x) => {
    self.b.is_zero(self.b.rshift(self.b.lshift(x, self.one(s)), self.one(s)))
  })
}

///|
/// `match_ cases`: the value of the first case whose condition holds; the
/// value of the last case is the default.
fn FE::match_(self : FE, cases : Array[(Pure, Pure)]) -> Pure {
  let n = cases.length()
  let mut result = cases[n - 1].1
  for i = n - 2; i >= 0; i = i - 1 {
    result = self.b.ite(cases[i].0, cases[i].1, result)
  }
  result
}

///|
fn FE::extract_last(self : FE, x : Pure, n : Pure) -> Pure {
  with_sort(x, (xsort, x) => {
    with_sort(n, (nsort, n) => {
      let mask = self.b.lshift(self.ones(xsort), n)
      let size = self.of_int(nsort, sort_size(xsort))
      self.b.ite(self.b.eq(n, size), x, self.b.logand(x, self.b.not(mask)))
    })
  })
}

///|
fn FE::is_round_up(
  self : FE,
  rm : Pure,
  sign : Pure,
  last : Pure,
  gbit : Pure,
  round : Pure,
  sticky : Pure,
) -> Pure {
  let b = self.b
  let case = (m : Pure, t : Pure, f : Pure) => b.ite(b.requal(rm, m), t, f)
  case(
    b.rtn,
    b.inv(sign),
    case(
      b.rtz,
      sign,
      case(
        b.rna,
        gbit,
        case(b.rne, b.and_(gbit, b.or_(b.or_(round, sticky), last)), b.b0),
      ),
    ),
  )
}

///|
fn FE::round(
  self : FE,
  rm : Pure,
  sign : Pure,
  coef : Pure,
  loss : Pure,
  lost_bits : Pure,
  f : (Pure, Pure) -> Pure,
) -> Pure {
  self.lets(l => {
    let (coef, is_overflow) = l.round(rm, sign, coef, loss, lost_bits)
    f(coef, is_overflow)
  })
}

///|
/// The maximum exponent that fits in `n` bits (reserving one for special
/// numbers).
fn max_exponent1(n : Int32) -> Int32 {
  @math.pow(2.0, n.to_double()).to_int() - 2
}

///|
fn FE::max_exponent(self : FE, s : Sort) -> Pure {
  self.of_int(s, max_exponent1(sort_size(s)))
}

///|
fn FE::min_exponent(self : FE, s : Sort) -> Pure {
  self.of_int(s, 1)
}

///|
/// The power of 2 nearest to `num` (from above) and its exponent.
fn nearest_pow2(num : Int32) -> (Int32, Int32) {
  for pow = 0, n = 1 {
    let n1 = 2 * n
    if n1 >= num {
      break (pow + 1, n1)
    }
    continue pow + 1, n1
  }
}

///|
/// The number of leading zeros.
fn FE::clz(self : FE, x : Pure) -> Pure {
  let b = self.b
  with_sort(x, (sort, x) => {
    let size = sort_size(sort)
    let (pow, num) = nearest_pow2(size)
    let sort1 = bits_sort(num)
    let shifts : Array[(Int32, Int32)] = []
    let mut prev = 0
    for p in 0..<pow {
      let curr = num / (2 << p)
      let total = curr + prev
      shifts.push((total, curr))
      prev = total
    }
    fn go(lets : @list.List[Pure], x : Pure, i : Int32) -> Pure {
      if i >= shifts.length() {
        lets.fold(init=b.zero(sort), (acc, n) => b.add(acc, n))
      } else {
        let (total, shf) = shifts[i]
        self.bind(b.lshift(self.ones(sort1), self.of_int(sort, total)), mask => {
          let x_masked = b.is_zero(b.logand(x, mask))
          self.bind(b.ite(x_masked, b.lshift(x, self.of_int(sort, shf)), x), nextx => {
            self.bind(
              b.ite(
                b.is_zero(b.logand(x, mask)),
                self.of_int(sort, shf),
                b.zero(sort),
              ),
              nextn => go(lets.prepend(nextn), nextx, i + 1),
            )
          })
        })
      }
    }

    self.bind(go(@list.List([]), b.unsigned(sort1, x), 0), n => {
      self.bind(self.of_int(sort, num - size), dif => {
        b.ite(b.is_zero(x), self.of_int(sort, size), b.sub(n, dif))
      })
    })
  })
}

///|
fn FE::possible_lshift(self : FE, expn : Pure, coef : Pure) -> Pure {
  let b = self.b
  with_sort(expn, (exps, expn) => {
    with_sort(coef, (sigs, coef) => {
      self.bind(self.clz(coef), clz => {
        self.bind(self.min_exponent(exps), mine => {
          self.bind(b.ite(b.ult(expn, mine), b.zero(exps), b.sub(expn, mine)), diff => {
            self.bind(b.unsigned(sigs, diff), diff => {
              b.ite(b.ult(clz, diff), clz, diff)
            })
          })
        })
      })
    })
  })
}

///|
fn FE::norm_finite(
  self : FE,
  expn : Pure,
  coef : Pure,
  f : (Pure, Pure) -> Pure,
) -> Pure {
  let b = self.b
  with_sort(expn, (exps, expn) => {
    with_sort(coef, (_, coef) => {
      self.bind(self.possible_lshift(expn, coef), shift => {
        self.bind(b.unsigned(exps, shift), dexpn => {
          self.bind(b.lshift(coef, shift), coef => {
            self.bind(
              b.ite(
                b.is_zero(coef),
                self.min_exponent(exps),
                b.sub(expn, dexpn),
              ),
              expn => f(expn, coef),
            )
          })
        })
      })
    })
  })
}

///|
fn FE::norm(
  self : FE,
  expn : Pure,
  coef : Pure,
  f : (Pure, Pure) -> Pure,
) -> Pure {
  with_sort(expn, (_, expn) => {
    self.b.ite(
      self.is_all_ones(expn),
      f(expn, coef),
      self.norm_finite(expn, coef, f),
    )
  })
}

///|
fn FE::fadd_finite(
  self : FE,
  fsort : Sort,
  rm : Pure,
  x : Pure,
  y : Pure,
) -> Pure {
  let b = self.b
  let exps = exps(fsort)
  let sigs = sigs(fsort)
  self.lets(l => {
    let (xsign, xexpn, xcoef) = l.unpack(fsort, x)
    let (_, yexpn, ycoef) = l.unpack(fsort, y)
    let lost_bits = l.bind(
      b.ite(b.ugt(xexpn, yexpn), b.sub(xexpn, yexpn), b.sub(yexpn, xexpn)),
    )
    let loss = l.bind(
      self.match_([
        (b.eq(xexpn, yexpn), b.zero(sigs)),
        (b.ugt(xexpn, yexpn), self.extract_last(ycoef, lost_bits)),
        (b.ult(xexpn, yexpn), self.extract_last(xcoef, lost_bits)),
      ]),
    )
    let xcoef = l.bind(
      b.ite(b.ugt(xexpn, yexpn), xcoef, b.rshift(xcoef, lost_bits)),
    )
    let ycoef = l.bind(
      b.ite(b.ugt(yexpn, xexpn), ycoef, b.rshift(ycoef, lost_bits)),
    )
    let sum = l.bind(b.add(xcoef, ycoef))
    let expn = l.bind(self.max(xexpn, yexpn))
    let expn = l.bind(b.ite(b.uge(sum, xcoef), expn, b.succ(expn)))
    let (gbit, round, sticky) = l.guardbits1(
      b.ult(sum, xcoef),
      b.lsb(sum),
      loss,
      lost_bits,
    )
    let coef = l.bind(
      b.ite(b.ult(sum, xcoef), b.rshift(sum, self.one(sigs)), sum),
    )
    let coef = l.bind(
      b.ite(b.ult(sum, xcoef), b.logor(coef, self.leading_one(sigs)), coef),
    )
    let up = l.bind(
      self.is_round_up(rm, xsign, b.lsb(coef), gbit, round, sticky),
    )
    let coef1 = l.bind(b.ite(up, b.succ(coef), coef))
    let rnd_overflow = l.bind(b.and_(b.is_zero(coef1), b.non_zero(coef)))
    let coef = l.bind(b.ite(rnd_overflow, self.leading_one(sigs), coef1))
    let _ = l.bind(b.ite(rnd_overflow, b.succ(expn), expn))
    let coef = l.bind(
      b.ite(b.ugt(expn, self.max_exponent(exps)), b.zero(sigs), coef),
    )
    self.norm(expn, coef, (expn, coef) => self.pack(fsort, xsign, expn, coef))
  })
}

///|
fn FE::common_ground(
  self : FE,
  xexpn : Pure,
  xcoef : Pure,
  yexpn : Pure,
  ycoef : Pure,
  f : (Pure, Pure, Pure, Pure) -> Pure,
) -> Pure {
  let b = self.b
  with_sort(xexpn, (exps, xexpn) => {
    with_sort(xcoef, (sigs, xcoef) => {
      self.bind(
        b.ite(b.ugt(xexpn, yexpn), b.sub(xexpn, yexpn), b.sub(yexpn, xexpn)),
        diff => {
          self.bind(b.ite(b.is_zero(diff), diff, b.sub(diff, self.one(exps))), lost_bits => {
            self.match_([
              (
                b.ugt(xexpn, yexpn),
                self.bind(self.extract_last(ycoef, lost_bits), loss => {
                  self.bind(b.lshift(xcoef, self.one(sigs)), xcoef => {
                    self.bind(b.rshift(ycoef, lost_bits), ycoef => {
                      f(loss, lost_bits, xcoef, ycoef)
                    })
                  })
                }),
              ),
              (
                b.ult(xexpn, yexpn),
                self.bind(self.extract_last(xcoef, lost_bits), loss => {
                  self.bind(b.rshift(xcoef, lost_bits), xcoef => {
                    self.bind(b.lshift(ycoef, self.one(sigs)), ycoef => {
                      f(loss, lost_bits, xcoef, ycoef)
                    })
                  })
                }),
              ),
              (b.eq(xexpn, yexpn), f(b.zero(sigs), b.zero(exps), xcoef, ycoef)),
            ])
          })
        },
      )
    })
  })
}

///|
fn FE::fsub_finite(
  self : FE,
  fsort : Sort,
  rm : Pure,
  x : Pure,
  y : Pure,
) -> Pure {
  let b = self.b
  self.lets(l => {
    let (xsign, xexpn, xcoef) = l.unpack(fsort, x)
    let (_, yexpn, ycoef) = l.unpack(fsort, y)
    let (xcoef, sigs1) = l.bitv_extend(xcoef, 1)
    let (ycoef, _) = l.bitv_extend(ycoef, 1)
    let swap = l.bind(
      b.or_(
        b.ult(xexpn, yexpn),
        b.and_(b.eq(xexpn, yexpn), b.ult(xcoef, ycoef)),
      ),
    )
    let sign = l.bind(b.ite(swap, b.inv(xsign), xsign))
    let sign = l.bind(
      b.ite(b.and_(b.eq(xexpn, yexpn), b.eq(xcoef, ycoef)), b.b0, sign),
    )
    self.common_ground(xexpn, xcoef, yexpn, ycoef, (
      loss,
      lost_bits,
      xcoef,
      ycoef,
    ) => {
      self.fsub_rest(
        fsort, rm, sign, swap, sigs1, xexpn, yexpn, loss, lost_bits, xcoef, ycoef,
      )
    })
  })
}

///|
fn FE::add_or_sub_finite(
  self : FE,
  is_sub : Pure,
  fsort : Sort,
  rm : Pure,
  x : Pure,
  y : Pure,
) -> Pure {
  let is_sub = self.xor(is_sub, self.xor(self.fsign(x), self.fsign(y)))
  self.b.ite(
    is_sub,
    self.fsub_finite(fsort, rm, x, y),
    self.fadd_finite(fsort, rm, x, y),
  )
}

///|
fn FE::fsum_special(
  self : FE,
  fsort : Sort,
  is_sub : Pure,
  x : Pure,
  y : Pure,
) -> Pure {
  let b = self.b
  let is_sub = self.xor(is_sub, self.xor(self.fsign(x), self.fsign(y)))
  self.lets(l => {
    let (xinf, xsnan, xqnan) = l.special(fsort, x)
    let (yinf, ysnan, yqnan) = l.special(fsort, y)
    let xnan = l.bind(b.or_(xsnan, xqnan))
    let ynan = l.bind(b.or_(ysnan, yqnan))
    let is_inf = l.bind(b.and_(xinf, yinf))
    self.match_([
      (b.and_(is_sub, is_inf), self.qnan(fsort)),
      (b.and_(xinf, yinf), x),
      (b.and_(xnan, b.inv(ynan)), self.transform_to_quite(fsort, x)),
      (b.and_(ynan, b.inv(xnan)), self.transform_to_quite(fsort, y)),
      (b.b1, self.transform_to_quite(fsort, x)),
    ])
  })
}

///|
fn FE::add_or_sub(
  self : FE,
  is_sub : Pure,
  fsort : Sort,
  rm : Pure,
  x : Pure,
  y : Pure,
) -> Pure {
  let b = self.b
  self.bind(self.is_finite(fsort, x), is_x_fin => {
    self.bind(self.is_finite(fsort, y), is_y_fin => {
      b.ite(
        b.and_(is_x_fin, is_y_fin),
        self.add_or_sub_finite(is_sub, fsort, rm, x, y),
        self.fsum_special(fsort, is_sub, x, y),
      )
    })
  })
}

///|
fn FE::fsub(self : FE, fsort : Sort, rm : Pure, x : Pure, y : Pure) -> Pure {
  self.add_or_sub(self.b.b1, fsort, rm, x, y)
}

///|
fn FE::fadd(self : FE, fsort : Sort, rm : Pure, x : Pure, y : Pure) -> Pure {
  self.add_or_sub(self.b.b0, fsort, rm, x, y)
}

///|
fn FE::fmul_finite(
  self : FE,
  fsort : Sort,
  rm : Pure,
  x : Pure,
  y : Pure,
) -> Pure {
  let b = self.b
  let precision = spec(fsort).p
  let exps = exps(fsort)
  let sigs = sigs(fsort)
  let mine = 1
  let maxe = max_exponent1(sort_size(exps))
  self.lets(l => {
    let (xsign, xexpn, xcoef) = l.unpack(fsort, x)
    let (ysign, yexpn, ycoef) = l.unpack(fsort, y)
    let sign = l.bind(self.xor(xsign, ysign))
    let (xcoef, dx) = l.normalize_coef(xcoef)
    let (ycoef, dy) = l.normalize_coef(ycoef)
    let dnorm = l.bind(b.add(dx, dy))
    let (xexpn, exps1) = l.double(xexpn)
    let (xcoef, sigs1) = l.double(xcoef)
    let (yexpn, _) = l.double(yexpn)
    let (ycoef, _) = l.double(ycoef)
    let prec = l.bind(self.of_int(sigs1, precision))
    let expn = l.bind(b.add(xexpn, yexpn))
    let coef = l.bind(b.mul(xcoef, ycoef))
    let coef_overflowed = l.bind(b.msb(coef))
    let expn = l.bind(b.ite(coef_overflowed, b.succ(expn), expn))
    let bias = l.bind(self.of_int(exps1, spec(fsort).bias))
    let dexpn = l.bind(b.add(bias, b.unsigned(exps1, dnorm)))
    let underflow = l.bind(
      b.ite(
        b.sge(dexpn, expn),
        b.add(b.sub(dexpn, expn), self.of_int(exps1, mine)),
        b.zero(exps1),
      ),
    )
    let is_underflow = l.bind(b.ugt(underflow, self.of_int(exps1, precision)))
    let expn = l.bind(b.add(b.sub(expn, dexpn), underflow))
    let is_overflow = l.bind(b.ugt(expn, self.of_int(exps1, maxe)))
    let from_overflow = l.bind(
      b.ite(coef_overflowed, self.one(sigs1), b.zero(sigs1)),
    )
    let coef = l.bind(
      b.rshift(coef, b.add(from_overflow, b.unsigned(sigs1, underflow))),
    )
    let coef = l.bind(b.lshift(coef, self.one(sigs1)))
    let loss = l.bind(b.low(sigs, coef))
    let coef = l.bind(b.high(sigs, coef))
    let expn = l.bind(b.low(exps, expn))
    let (coef, rnd_overflow) = l.round(rm, sign, coef, loss, prec)
    let coef = l.bind(b.ite(rnd_overflow, self.leading_one(sigs), coef))
    let expn = l.bind(b.ite(rnd_overflow, b.succ(expn), expn))
    let is_overflow = l.bind(
      b.or_(b.ugt(expn, self.of_int(exps, maxe)), is_overflow),
    )
    self.norm(expn, coef, (expn, coef) => {
      self.lets(l => {
        let expn = l.bind(b.ite(is_underflow, b.zero(exps), expn))
        let expn = l.bind(b.ite(is_overflow, self.ones(exps), expn))
        let coef = l.bind(
          b.ite(b.or_(is_overflow, is_underflow), b.zero(sigs), coef),
        )
        self.pack(fsort, sign, expn, coef)
      })
    })
  })
}

///|
fn FE::fmul_special(self : FE, fsort : Sort, x : Pure, y : Pure) -> Pure {
  let b = self.b
  self.lets(l => {
    let (xinf, xsnan, xqnan) = l.special(fsort, x)
    let (yinf, _, _) = l.special(fsort, y)
    let xsign = l.bind(self.fsign(x))
    let ysign = l.bind(self.fsign(y))
    let is_inf = l.bind(b.and_(xinf, yinf))
    self.match_([
      (b.and_(self.is_fzero(x), yinf), self.qnan(fsort)),
      (b.and_(self.is_fzero(y), xinf), self.qnan(fsort)),
      (is_inf, self.with_sign(self.xor(xsign, ysign), x)),
      (b.or_(xsnan, xqnan), self.transform_to_quite(fsort, x)),
      (b.b1, self.transform_to_quite(fsort, y)),
    ])
  })
}

///|
fn FE::fmul(self : FE, fsort : Sort, rm : Pure, x : Pure, y : Pure) -> Pure {
  let b = self.b
  self.bind(self.is_finite(fsort, x), is_x_fin => {
    self.bind(self.is_finite(fsort, y), is_y_fin => {
      b.ite(
        b.and_(is_x_fin, is_y_fin),
        self.fmul_finite(fsort, rm, x, y),
        self.fmul_special(fsort, x, y),
      )
    })
  })
}

///|
fn FE::mask_bit(self : FE, sort : Sort, i : Int32) -> Pure {
  self.b.lshift(self.one(sort), self.of_int(sort, i))
}

///|
/// Long division (pre: nominator > denominator), `f` receives the
/// quotient and the gbit, round and sticky bits.
fn FE::long_division(
  self : FE,
  prec : Int32,
  nomin : Pure,
  denom : Pure,
  f : (Pure, (Pure, Pure, Pure)) -> Pure,
) -> Pure {
  let b = self.b
  let lost_alot = (b.b1, b.b1, b.b0)
  let lost_half = (b.b1, b.b0, b.b0)
  let lost_zero = (b.b0, b.b0, b.b0)
  let lost_afew = (b.b0, b.b0, b.b1)
  with_sort(nomin, (sort, nomin) => {
    fn go(i : Int32, bits : @list.List[Pure], nomin : Pure) -> Pure {
      if i < 0 {
        self.bind(bits.fold(init=b.zero(sort), (acc, x) => b.logor(acc, x)), coef => {
          self.match_([
            (b.ugt(nomin, denom), f(coef, lost_alot)),
            (b.eq(nomin, denom), f(coef, lost_half)),
            (b.eq(nomin, b.zero(sort)), f(coef, lost_zero)),
            (b.b1, f(coef, lost_afew)),
          ])
        })
      } else {
        self.bind(
          b.ite(b.ugt(nomin, denom), self.mask_bit(sort, i), b.zero(sort)),
          bit => {
            self.bind(b.ite(b.ugt(nomin, denom), b.sub(nomin, denom), nomin), next => {
              self.bind(b.lshift(next, self.one(sort)), next => {
                self.bind(next, next => go(i - 1, bits.prepend(bit), next))
              })
            })
          },
        )
      }
    }

    go(prec - 1, @list.List([]), nomin)
  })
}

///|
fn FE::fdiv_finite(
  self : FE,
  fsort : Sort,
  rm : Pure,
  x : Pure,
  y : Pure,
) -> Pure {
  let b = self.b
  let exps = exps(fsort)
  let prec = spec(fsort).p
  self.lets(l => {
    let (xsign, xexpn, xcoef) = l.unpack(fsort, x)
    let (ysign, yexpn, ycoef) = l.unpack(fsort, y)
    let sign = l.bind(self.xor(xsign, ysign))
    let (nomin, dx) = l.normalize_coef(xcoef)
    let (denom, dy) = l.normalize_coef(ycoef)
    let de = l.bind(b.sub(dy, dx))
    let (nomin, sigs1) = l.bitv_extend(nomin, 1)
    let (denom, _) = l.bitv_extend(denom, 1)
    // norm_nominator
    let nomin1 = l.bind(
      b.ite(b.ult(nomin, denom), b.lshift(nomin, self.one(sigs1)), nomin),
    )
    let dexpn1 = l.bind(
      b.ite(b.ult(nomin, denom), self.one(exps), b.zero(exps)),
    )
    self.long_division(prec, nomin1, denom, (coef, lost) => {
      self.fdiv_rest(fsort, rm, sign, xexpn, yexpn, de, dexpn1, coef, lost)
    })
  })
}

///|
fn FE::fdiv_special(self : FE, fsort : Sort, x : Pure, y : Pure) -> Pure {
  let b = self.b
  self.lets(l => {
    let (xinf, xsnan, xqnan) = l.special(fsort, x)
    let (yinf, ysnan, _) = l.special(fsort, y)
    let xsign = l.bind(self.fsign(x))
    let ysign = l.bind(self.fsign(y))
    let is_inf = l.bind(b.and_(xinf, yinf))
    let is_finx = l.bind(b.inv(b.or_(b.or_(xinf, xsnan), xsnan)))
    let is_finy = l.bind(b.inv(b.or_(b.or_(yinf, ysnan), ysnan)))
    let sign = l.bind(self.xor(xsign, ysign))
    self.match_([
      (b.and_(self.is_fzero(x), self.is_fzero(y)), self.qnan(fsort)),
      (b.and_(self.is_fzero(x), is_finy), self.fzero(fsort, sign)),
      (b.and_(self.is_fzero(y), is_finx), self.inf(fsort, sign)),
      (b.and_(xinf, yinf), self.qnan(fsort)),
      (is_inf, self.with_sign(self.xor(xsign, ysign), x)),
      (b.or_(xsnan, xqnan), self.transform_to_quite(fsort, x)),
      (b.b1, self.transform_to_quite(fsort, y)),
    ])
  })
}

///|
fn FE::fdiv(self : FE, fsort : Sort, rm : Pure, x : Pure, y : Pure) -> Pure {
  let b = self.b
  b.ite(
    b.and_(self.is_finite_nonzero(fsort, x), self.is_finite_nonzero(fsort, y)),
    self.fdiv_finite(fsort, rm, x, y),
    self.fdiv_special(fsort, x, y),
  )
}

///|
/// Converts to a smaller format (pre: `fsort` is larger than `fsort1`).
fn FE::truncate(
  self : FE,
  fsort : Sort,
  x : Pure,
  rm : Pure,
  fsort1 : Sort,
) -> Pure {
  let b = self.b
  let sigs_sh = sort_size(sigs(fsort1))
  let d_bias = spec(fsort).bias - spec(fsort1).bias
  let dst_maxe = max_exponent1(sort_size(exps(fsort1)))
  let sigs1 = sigs(fsort1)
  self.unpack(fsort, x, (sign, expn, coef) => {
    let special = self.lets(l => {
      let expn = l.bind(b.low(exps(fsort1), expn))
      let coef = l.bind(b.high(sigs1, coef))
      self.pack(fsort1, sign, expn, coef)
    })
    let finite = self.lets(l => {
      let expn = l.bind(b.sub(expn, self.of_int(exps(fsort), d_bias)))
      let rounded = self.lets(l => {
        let expn = l.bind(b.low(exps(fsort1), expn))
        let truncated = l.bind(
          b.lshift(coef, self.of_int(sigs(fsort), sigs_sh)),
        )
        let truncated = l.bind(b.high(sigs1, truncated))
        let coef = l.bind(b.high(sigs1, coef))
        let last = l.bind(b.lsb(coef))
        let gbit = l.bind(b.msb(truncated))
        let truncated = l.bind(b.lshift(truncated, self.one(sigs1)))
        let round = l.bind(b.msb(truncated))
        let truncated = l.bind(b.lshift(truncated, self.one(sigs1)))
        let sticky = l.bind(b.non_zero(truncated))
        let up = l.bind(self.is_round_up(rm, sign, last, gbit, round, sticky))
        let expn = l.bind(
          b.ite(b.and_(self.is_all_ones(coef), up), b.succ(expn), expn),
        )
        let coef = l.bind(b.ite(up, b.succ(coef), coef))
        b.ite(
          self.is_all_ones(expn),
          self.inf(fsort1, sign),
          self.pack(fsort1, sign, expn, coef),
        )
      })
      b.ite(
        b.ugt(expn, self.of_int(exps(fsort), dst_maxe)),
        self.inf(fsort1, sign),
        rounded,
      )
    })
    b.ite(b.or_(self.is_all_ones(expn), b.is_zero(expn)), special, finite)
  })
}

///|
/// Converts to a larger format (pre: `fsort` is smaller than `fsort1`).
fn FE::extend_(self : FE, fsort : Sort, x : Pure, fsort1 : Sort) -> Pure {
  let b = self.b
  let d_sigs = sort_size(sigs(fsort1)) - sort_size(sigs(fsort))
  let d_bias = spec(fsort1).bias - spec(fsort).bias
  self.unpack(fsort, x, (sign, expn, coef) => {
    self.bind(
      self.match_([
        (self.is_all_ones(expn), self.ones(exps(fsort1))),
        (
          b.eq(expn, self.min_exponent(exps(fsort))),
          self.min_exponent(exps(fsort1)),
        ),
        (
          b.b1,
          b.add(
            b.unsigned(exps(fsort1), expn),
            self.of_int(exps(fsort1), d_bias),
          ),
        ),
      ]),
      expn => {
        self.bind(b.unsigned(sigs(fsort1), coef), coef => {
          self.bind(b.lshift(coef, self.of_int(sigs(fsort1), d_sigs)), coef => {
            self.pack(fsort1, sign, expn, coef)
          })
        })
      },
    )
  })
}

///|
fn FE::convert(
  self : FE,
  fsort : Sort,
  x : Pure,
  rm : Pure,
  fsort1 : Sort,
) -> Pure {
  let size = (f : Sort) => sort_size(fbits_sort(f))
  if size(fsort) == size(fsort1) {
    self.b.unsigned(fbits_sort(fsort1), x)
  } else if size(fsort) < size(fsort1) {
    self.extend_(fsort, x, fsort1)
  } else {
    self.truncate(fsort, x, rm, fsort1)
  }
}

///|
fn double_precision(fsort : Sort) -> Sort {
  let bits = sort_size(fbits_sort(fsort))
  match @core_theory.Ieee754Parameters::binary(2 * bits) {
    Some(p) => Sort::ieee754(p)
    None => abort("Bil_float: no binary format of \{2 * bits} bits")
  }
}

///|
fn FE::gen_cast_float(
  self : FE,
  fsort : Sort,
  sign : Pure,
  bitv : Pure,
) -> Pure {
  let b = self.b
  let p = spec(fsort)
  let exps = exps(fsort)
  let sigs = bits_sort(p.p)
  with_sort(bitv, (inps, bitv) => {
    self.lets(l => {
      let expn = l.bind(self.of_int(exps, p.bias + p.p - 1))
      let prec = l.bind(self.of_int(sigs, p.p))
      let clz = l.bind(self.clz(bitv))
      let clz = l.bind(b.unsigned(sigs, clz))
      let msbn = l.bind(b.sub(self.of_int(sigs, sort_size(inps)), clz))
      let large = self.lets(l => {
        let de = l.bind(b.sub(msbn, prec))
        let hi = l.bind(b.sub(msbn, self.one(sigs)))
        let lo = l.bind(b.add(b.sub(hi, prec), self.one(sigs)))
        let coef = l.bind(b.extract(sigs, hi, lo, bitv))
        let loss = l.bind(b.extract(sigs, b.pred(lo), b.zero(sigs), bitv))
        self.round(b.rne, sign, coef, loss, lo, (coef, rnd_overflow) => {
          self.lets(l => {
            let coef = l.bind(
              b.ite(
                rnd_overflow,
                b.not(b.rshift(self.ones(sigs), self.one(sigs))),
                coef,
              ),
            )
            let expn = l.bind(b.ite(rnd_overflow, b.succ(expn), expn))
            let expn = l.bind(b.add(expn, b.unsigned(exps, de)))
            self.norm(expn, coef, (expn, coef) => {
              self.pack(fsort, sign, expn, coef)
            })
          })
        })
      })
      let small = self.bind(b.unsigned(sigs, bitv), coef => {
        self.norm(expn, coef, (expn, coef) => self.pack(fsort, sign, expn, coef))
      })
      b.ite(b.ugt(msbn, prec), large, small)
    })
  })
}

///|
fn FE::cast_float(self : FE, fsort : Sort, bitv : Pure) -> Pure {
  self.gen_cast_float(fsort, self.b.b0, bitv)
}

///|
fn FE::cast_float_signed(self : FE, fsort : Sort, bitv : Pure) -> Pure {
  let sign = self.b.msb(bitv)
  let bitv = self.b.ite(sign, self.b.neg(bitv), bitv)
  self.gen_cast_float(fsort, sign, bitv)
}

///|
fn FE::cast_int(self : FE, fsort : Sort, outs : Sort, bitv : Pure) -> Pure {
  let b = self.b
  let p = spec(fsort)
  let exps = exps(fsort)
  let sigs = bits_sort(p.p)
  self.unpack(fsort, bitv, (sign, expn, coef) => {
    self.bind(b.add(b.sub(expn, self.of_int(exps, p.bias)), self.one(exps)), bits => {
      self.bind(b.sub(self.of_int(sigs, p.p), b.unsigned(sigs, bits)), bits => {
        self.bind(b.rshift(coef, b.unsigned(sigs, bits)), coef => {
          self.bind(b.unsigned(outs, coef), coef => {
            b.ite(sign, b.neg(coef), coef)
          })
        })
      })
    })
  })
}

///|
/// Returns `x` in the range `[1.0; 2.0]`.
fn FE::range_reduction(
  self : FE,
  fsort : Sort,
  x : Pure,
  f : (Pure, Pure, Pure) -> Pure,
) -> Pure {
  let b = self.b
  let bias = spec(fsort).bias
  let low = self.of_int(exps(fsort), bias)
  let top = self.of_int(exps(fsort), bias + 1)
  self.unpack_raw(fsort, x, (sign, expn, coef) => {
    self.bind(
      self.match_([
        (b.and_(b.eq(expn, top), b.non_zero(coef)), b.sub(expn, low)),
        (b.ugt(expn, top), b.sub(expn, low)),
        (b.or_(b.eq(expn, low), b.eq(expn, top)), b.zero(exps(fsort))),
        (b.ult(expn, low), b.sub(low, expn)),
      ]),
      d_expn => {
        self.bind(b.uge(expn, low), increase => {
          self.bind(
            b.ite(b.uge(expn, low), b.sub(expn, d_expn), b.add(expn, d_expn)),
            expn => {
              self.bind(self.pack_raw(fsort, sign, expn, coef), r => {
                f(r, d_expn, increase)
              })
            },
          )
        })
      },
    )
  })
}

///|
fn FE::sqrt2(self : FE, fsort1 : Sort) -> Pure {
  let fsort = Sort::ieee754(@core_theory.Ieee754Parameters::binary128())
  let c = @bitvec.from_hex(width=128, "3fff6a09e667f3bcc908b2fb1366ea95") catch {
    _ => abort("sqrt2")
  }
  self.bind(self.b.int(fbits_sort(fsort), c), x => {
    self.convert(fsort, x, self.b.rne, fsort1)
  })
}

///|
fn FE::range_reconstruction(
  self : FE,
  fsort : Sort,
  x : Pure,
  d_expn : Pure,
  clz : Pure,
  increase : Pure,
) -> Pure {
  let b = self.b
  let two = self.of_int(exps(fsort), 2)
  self.bind(self.sqrt2(fsort), sqrt2 => {
    self.unpack_raw(fsort, x, (sign, expn, coef) => {
      b.ite(
        b.is_zero(clz),
        self.bind(b.lsb(d_expn), is_odd => {
          self.bind(
            b.ite(
              b.and_(is_odd, increase),
              b.succ(d_expn),
              b.ite(is_odd, b.pred(d_expn), d_expn),
            ),
            d_expn => {
              self.bind(
                b.ite(
                  increase,
                  b.add(expn, b.div(d_expn, two)),
                  b.sub(expn, b.div(d_expn, two)),
                ),
                expn => {
                  self.bind(self.pack_raw(fsort, sign, expn, coef), r => {
                    b.ite(is_odd, self.fdiv(fsort, b.rne, r, sqrt2), r)
                  })
                },
              )
            },
          )
        }),
        self.bind(b.unsigned(exps(fsort), clz), clz => {
          self.bind(b.lsb(clz), is_odd => {
            self.bind(b.ite(is_odd, b.pred(clz), clz), clz => {
              self.bind(b.div(clz, two), clz => {
                self.bind(b.sub(b.sub(expn, b.div(d_expn, two)), clz), expn => {
                  self.bind(self.pack_raw(fsort, sign, expn, coef), r => {
                    b.ite(is_odd, self.fdiv(fsort, b.rne, r, sqrt2), r)
                  })
                })
              })
            })
          })
        }),
      )
    })
  })
}

///|
fn FE::horner(self : FE, fsort : Sort, x : Pure, cfs : Array[Pure]) -> Pure {
  let add = (x, y) => self.add_or_sub_finite(self.b.b0, fsort, self.b.rne, x, y)
  let mul = (x, y) => self.fmul_finite(fsort, self.b.rne, x, y)
  fn sum(y : Pure, i : Int32) -> Pure {
    if i >= cfs.length() {
      y
    } else {
      self.bind(mul(x, y), y => self.bind(add(y, cfs[i]), y => sum(y, i + 1)))
    }
  }

  sum(cfs[0], 1)
}

///|
fn FE::normalize_subnormal(
  self : FE,
  fsort : Sort,
  x : Pure,
  f : (Pure, Pure) -> Pure,
) -> Pure {
  self.unpack(fsort, x, (sign, expn, coef) => {
    self.bind(self.clz(coef), clz => {
      self.bind(self.b.lshift(coef, clz), coef => {
        self.bind(self.pack(fsort, sign, expn, coef), r => f(r, clz))
      })
    })
  })
}

///|
/// The coefficients of the polynomial approximation of `sqrt (x + 1)` on
/// `[0.0; 1.0]` (degree 23, binary128 constants).
let sqrt_coefs : Array[String] = [
  "3fea283d1af5d3b8b0e9889579874140", "bfede2119c815a1d59de530775f68488", "3ff0766a0fd57550fbcaf5949c387bfb",
  "bff272ebd07e2237538440a72429c8d9", "3ff408b110927387f462771163341fec", "bff5242b7488a8af2abfbadce8148c9e",
  "3ff606758477172056f0e80bc6f46e09", "bff69084710b6e59fb3f53199edfb3dd", "3ff70e24e277a45deb05c37590719576",
  "bff74ec376fd27c8ac279836961f6025", "3ff78aabb74359ac28498e73a2e9989f", "bff7c74981d8ac6e123f062aee10b24c",
  "3ff805e10b3ea64c491b21abdb7f9796", "bff82fbf8642c69d9c901bcfcd18b8e1", "3ff8657a1d1b03f0f63a64018888f16c",
  "bff8acff29ed5e34f19ffa86dc9e5b9a", "3ff907fff45a4ee1cba42e6e42229c85", "bff94fffff0ee79b4a473fa1503182d5",
  "3ff9bffffff219963def0395eb8c25e4", "bffa3fffffffbb055e0eddae1c1de75f", "3ffafffffffffe5a8a7bc5d57eea900e",
  "bffbfffffffffffd5373ee69a938caf9", "3ffdffffffffffffff22a39a2a24d3f4", "3fff0000000000000000000000000000",
]

///|
fn FE::coefs(self : FE, s : Sort) -> Array[Pure] {
  // upstream creates the constants with `Bitvec.of_string` (arbitrary
  // precision) and `B.int s`, which truncates them to the size of `s`
  sqrt_coefs.map(x => {
    let v = @bitvec.from_hex(width=128, x) catch { _ => abort("coefs") }
    let v = v.extract(hi=sort_size(s) - 1, lo=0) catch { _ => v }
    self.b.int(s, v)
  })
}

///|
fn FE::fsqrt(self : FE, fsort : Sort, rm : Pure, x : Pure) -> Pure {
  let b = self.b
  let fsort1 = double_precision(fsort)
  b.ite(
    self.is_fzero(x),
    self.fzero(fsort, b.b0),
    self.normalize_subnormal(fsort, x, (x, clz) => {
      self.range_reduction(fsort, x, (y, d_expn, increase) => {
        self.bind(self.fone(fsort, b.b0), one => {
          self.bind(self.fsub(fsort, rm, y, one), y => {
            self.bind(self.extend_(fsort, y, fsort1), y => {
              self.bind(
                self.horner(fsort1, y, self.coefs(fbits_sort(fsort1))),
                y => {
                  self.bind(b.unsigned(exps(fsort1), d_expn), d_expn => {
                    self.bind(
                      self.range_reconstruction(
                        fsort1, y, d_expn, clz, increase,
                      ),
                      r => self.truncate(fsort1, r, rm, fsort),
                    )
                  })
                },
              )
            })
          })
        })
      })
    }),
  )
}

///|
/// The sort of the value of a term.
fn Lets::sort_of(self : Lets, x : Pure) -> Sort raise {
  x(self.state).sort()
}

///|
/// `unpack` in a sequence of bindings: the sign, the exponent (subnormals
/// adjusted) and the coefficient with the leading bit.
fn Lets::unpack(
  self : Lets,
  fsort : Sort,
  x : Pure,
) -> (Pure, Pure, Pure) raise {
  let fe = self.fe
  let x = self.bind(x)
  let expn = self.bind(fe.exponent(fsort, x))
  let sign = self.bind(fe.fsign(x))
  let coef = self.bind(fe.finite_significand(fsort, expn, x))
  let expn = self.bind(fe.b.ite(fe.b.is_zero(expn), fe.b.succ(expn), expn))
  (sign, expn, coef)
}

///|
fn Lets::unpack_raw(
  self : Lets,
  fsort : Sort,
  x : Pure,
) -> (Pure, Pure, Pure) raise {
  let fe = self.fe
  let x = self.bind(x)
  let expn = self.bind(fe.exponent(fsort, x))
  let coef = self.bind(fe.raw_significand(fsort, x))
  (fe.fsign(x), expn, coef)
}

///|
/// `with_special`: whether the float is an infinity, a signaling or a
/// quiet NaN.
fn Lets::special(
  self : Lets,
  fsort : Sort,
  x : Pure,
) -> (Pure, Pure, Pure) raise {
  let b = self.fe.b
  let (_, expn, coef) = self.unpack_raw(fsort, x)
  let is_special = self.bind(self.fe.is_all_ones(expn))
  let is_inf = self.bind(b.and_(is_special, b.is_zero(coef)))
  let is_snan = self.bind(
    self.fe.and3(is_special, b.non_zero(coef), b.inv(b.msb(coef))),
  )
  let is_qnan = self.bind(b.and_(is_special, b.msb(coef)))
  (is_inf, is_snan, is_qnan)
}

///|
fn Lets::guardbits(
  self : Lets,
  loss : Pure,
  lost_bits : Pure,
) -> (Pure, Pure, Pure) raise {
  let fe = self.fe
  let b = fe.b
  let sort = self.sort_of(lost_bits)
  let has_grd = self.bind(b.ugt(lost_bits, b.zero(sort)))
  let has_rnd = self.bind(b.ugt(lost_bits, fe.one(sort)))
  let has_stk = self.bind(b.ugt(lost_bits, fe.of_int(sort, 2)))
  let grd_pos = self.bind(b.ite(has_grd, b.pred(lost_bits), b.zero(sort)))
  let rnd_pos = self.bind(b.ite(has_rnd, b.pred(grd_pos), b.zero(sort)))
  let grd = self.bind(b.ite(has_grd, fe.testbit(loss, grd_pos), b.b0))
  let rnd = self.bind(b.ite(has_rnd, fe.testbit(loss, rnd_pos), b.b0))
  let stk = self.bind(
    b.ite(has_stk, b.non_zero(fe.extract_last(loss, rnd_pos)), b.b0),
  )
  (grd, rnd, stk)
}

///|
fn Lets::guardbits1(
  self : Lets,
  overflow : Pure,
  last : Pure,
  loss : Pure,
  lost_bits : Pure,
) -> (Pure, Pure, Pure) raise {
  let b = self.fe.b
  let (guard1, round1, sticky1) = self.guardbits(loss, lost_bits)
  let gbit = self.bind(b.ite(overflow, last, guard1))
  let round = self.bind(b.ite(overflow, guard1, round1))
  let sticky = self.bind(b.ite(overflow, b.or_(round1, sticky1), sticky1))
  (gbit, round, sticky)
}

///|
fn Lets::round(
  self : Lets,
  rm : Pure,
  sign : Pure,
  coef : Pure,
  loss : Pure,
  lost_bits : Pure,
) -> (Pure, Pure) raise {
  let fe = self.fe
  let b = fe.b
  let (grd, rnd, stk) = self.guardbits(loss, lost_bits)
  let coef1 = self.bind(
    b.ite(
      fe.is_round_up(rm, sign, b.lsb(coef), grd, rnd, stk),
      b.succ(coef),
      coef,
    ),
  )
  let is_overflow = self.bind(b.and_(b.non_zero(coef), b.is_zero(coef1)))
  (coef1, is_overflow)
}

///|
fn Lets::normalize_coef(self : Lets, coef : Pure) -> (Pure, Pure) raise {
  let clz = self.bind(self.fe.clz(coef))
  let coef = self.bind(self.fe.b.lshift(coef, clz))
  (coef, clz)
}

///|
fn Lets::bitv_extend(
  self : Lets,
  bitv : Pure,
  addend : Int32,
) -> (Pure, Sort) raise {
  let sort = self.sort_of(bitv)
  let sort1 = bits_sort(sort_size(sort) + addend)
  (self.bind(self.fe.b.unsigned(sort1, bitv)), sort1)
}

///|
fn Lets::double(self : Lets, bitv : Pure) -> (Pure, Sort) raise {
  self.bitv_extend(bitv, sort_size(self.sort_of(bitv)))
}

///|
fn FE::fsub_rest(
  self : FE,
  fsort : Sort,
  rm : Pure,
  sign : Pure,
  swap : Pure,
  sigs1 : Sort,
  xexpn : Pure,
  yexpn : Pure,
  loss : Pure,
  lost_bits : Pure,
  xcoef : Pure,
  ycoef : Pure,
) -> Pure {
  let b = self.b
  let exps = exps(fsort)
  let sigs = sigs(fsort)
  self.lets(l => {
    let borrow = l.bind(b.ite(b.is_zero(loss), b.zero(sigs1), self.one(sigs1)))
    let coef = l.bind(
      b.ite(
        swap,
        b.sub(b.sub(ycoef, xcoef), borrow),
        b.sub(b.sub(xcoef, ycoef), borrow),
      ),
    )
    let msbc = l.bind(b.msb(coef))
    let expn = l.bind(self.max(xexpn, yexpn))
    let expn = l.bind(
      b.ite(b.eq(xexpn, yexpn), expn, b.sub(expn, self.one(exps))),
    )
    let expn = l.bind(
      b.ite(
        b.is_zero(coef),
        self.min_exponent(exps),
        b.ite(msbc, b.succ(expn), expn),
      ),
    )
    let (guard1, round1, sticky1) = l.guardbits(loss, lost_bits)
    let guard1 = l.bind(b.ite(b.or_(round1, sticky1), b.inv(guard1), guard1))
    let gbit = l.bind(b.ite(msbc, b.lsb(coef), guard1))
    let round = l.bind(b.ite(msbc, guard1, round1))
    let sticky = l.bind(b.ite(msbc, b.or_(round1, sticky1), sticky1))
    let coef = l.bind(b.ite(msbc, b.rshift(coef, self.one(sigs1)), coef))
    let up = l.bind(
      self.is_round_up(rm, sign, b.lsb(coef), gbit, round, sticky),
    )
    let coef = l.bind(b.unsigned(sigs, coef))
    let coef1 = l.bind(b.ite(up, b.succ(coef), coef))
    let rnd_overflow = l.bind(b.and_(b.is_zero(coef1), b.non_zero(coef)))
    let coef = l.bind(b.ite(rnd_overflow, self.leading_one(sigs), coef1))
    let expn = l.bind(b.ite(rnd_overflow, b.succ(expn), expn))
    self.norm(expn, coef, (expn, coef) => self.pack(fsort, sign, expn, coef))
  })
}

///|
fn FE::fdiv_rest(
  self : FE,
  fsort : Sort,
  rm : Pure,
  sign : Pure,
  xexpn : Pure,
  yexpn : Pure,
  de : Pure,
  dexpn1 : Pure,
  coef : Pure,
  lost : (Pure, Pure, Pure),
) -> Pure {
  let b = self.b
  let exps = exps(fsort)
  let sigs = sigs(fsort)
  let prec1 = self.of_int(exps, spec(fsort).p)
  let maxe = self.max_exponent(exps)
  let mine = self.min_exponent(exps)
  let (guard1, round1, sticky1) = lost
  self.lets(l => {
    let coef = l.bind(b.unsigned(sigs, coef))
    let bias = l.bind(self.of_int(exps, spec(fsort).bias))
    let dexpn = l.bind(b.sub(b.unsigned(exps, de), dexpn1))
    let expn = l.bind(b.sub(xexpn, yexpn))
    let underflowed = l.bind(
      b.and_(
        b.ult(xexpn, yexpn),
        b.ugt(b.sub(yexpn, xexpn), b.sub(b.add(dexpn, bias), mine)),
      ),
    )
    let is_underflow = l.bind(
      b.and_(
        b.ult(xexpn, yexpn),
        b.ugt(
          b.sub(yexpn, xexpn),
          b.sub(b.add(b.add(prec1, dexpn), bias), mine),
        ),
      ),
    )
    let is_overflow = l.bind(
      b.and_(b.ugt(xexpn, yexpn), b.ugt(expn, b.sub(b.sub(maxe, dexpn), bias))),
    )
    let expn = l.bind(b.add(b.add(expn, dexpn), bias))
    let underflow_case = self.lets(l => {
      let fix_underflow = l.bind(b.add(self.abs(expn), mine))
      let loss = l.bind(self.extract_last(coef, fix_underflow))
      let (gbit, round, sticky) = l.guardbits(loss, fix_underflow)
      let sticky = l.bind(b.or_(b.or_(sticky, round1), sticky1))
      let coef = l.bind(b.rshift(coef, fix_underflow))
      let up = l.bind(
        self.is_round_up(rm, sign, b.lsb(coef), gbit, round, sticky),
      )
      let coef = l.bind(b.ite(up, b.succ(coef), coef))
      self.norm(mine, coef, (expn, coef) => self.pack(fsort, sign, expn, coef))
    })
    let otherwise = self.lets(l => {
      let up = l.bind(
        self.is_round_up(rm, sign, b.lsb(coef), guard1, round1, sticky1),
      )
      let coef = l.bind(b.ite(up, b.succ(coef), coef))
      let expn = l.bind(b.ite(is_underflow, b.zero(exps), expn))
      let expn = l.bind(b.ite(is_overflow, self.ones(exps), expn))
      let coef = l.bind(
        b.ite(b.or_(is_overflow, is_underflow), b.zero(sigs), coef),
      )
      self.norm(expn, coef, (expn, coef) => self.pack(fsort, sign, expn, coef))
    })
    b.ite(underflowed, underflow_case, otherwise)
  })
}
