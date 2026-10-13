///|
/// The BIL type of a sort (`Var.reify` typing): booleans are one-bit
/// immediates, bitvectors of size `n` are `n`-bit immediates, memories
/// map their key and value sizes, floats are represented by their bits.
/// Other sorts (which have no BIL type) are typed as one-bit immediates.
pub fn Sort::bil_type(self : Sort) -> @types.ValueType {
  if self == Sort::bool() {
    return Imm(1)
  }
  match self.bitv_size() {
    Some(size) => Imm(size)
    None =>
      match (self.mem_keys(), self.mem_values()) {
        (Some(keys), Some(values)) =>
          Mem(addr_width=sort_size(keys), value_width=sort_size(values))
        _ =>
          match self.float_bits() {
            Some(bits) => Imm(sort_size(bits))
            None => Imm(1)
          }
      }
  }
}

///|
/// `Var.reify`: the BIL variable of a Core Theory variable.
pub fn Var::reify(self : Var) -> @types.Var {
  @types.Var::new(
    name=self.name(),
    typ=self.sort().bil_type(),
    is_virtual=self.is_virtual(),
  )
}

///|
let bil_exp_domain : @knowledge.Domain[@types.Exp?] = @knowledge.Domain::optional(
  @knowledge.Domain::flat(@knowledge.Name::create("exp", pkg="bap"), exp => {
    exp.to_string()
  }),
)

///|
/// `Exp.slot`: the BIL expression of a value.
let bil_exp_property : @knowledge.Slot[ValueCls, @types.Exp?] = value_cls.property(
  name=@knowledge.Name::create("exp", pkg="bap"),
  domain=bil_exp_domain,
  desc="semantics of expressions in BIL",
  public=true,
)

///|
let bil_stmts_domain : @knowledge.Domain[Array[@types.Stmt]] = @knowledge.Domain::flat(
  @knowledge.Name::create("bil", pkg="bap"),
  stmts => "(" + stmts.map(stmt => stmt.to_string()).join("; ") + ")",
  empty=[],
)

///|
/// `Bil.slot`: the BIL statements of an effect (and so of a semantics).
let bil_stmts_slot : @knowledge.Slot[EffectCls, Array[@types.Stmt]] = effect_cls.property(
  name=@knowledge.Name::create("bil", pkg="bap"),
  domain=bil_stmts_domain,
  desc="semantics of statements in BIL",
  public=true,
)

///|
/// `Exp.slot`: the property of values that holds their BIL expression.
pub fn bil_exp_slot() -> @knowledge.Slot[ValueCls, @types.Exp?] {
  bil_exp_property
}

///|
/// `Bil.slot`: the property of effects (and semantics) that holds their
/// BIL statements.
pub fn bil_slot() -> @knowledge.Slot[EffectCls, Array[@types.Stmt]] {
  bil_stmts_slot
}

///|
/// The BIL expression of the value, if it was provided.
pub fn Value::bil(self : Value) -> @types.Exp? {
  self.get(bil_exp_property)
}

///|
/// The BIL statements of the effect.
pub fn Effect::bil(self : Effect) -> Array[@types.Stmt] {
  self.get(bil_stmts_slot)
}

///|
/// The BIL statements of the semantics.
pub fn Semantics::bil(self : Semantics) -> Array[@types.Stmt] {
  self.get(bil_stmts_slot)
}

///|
/// The BIL expression of `v` (an `unknown` expression if it has none).
fn bil_value_exp(v : Value) -> @types.Exp {
  match v.get(bil_exp_property) {
    Some(exp) => exp
    None => Unknown("empty", v.sort().bil_type())
  }
}

///|
fn bil_value(sort : Sort, exp : @types.Exp) -> Value {
  Value::empty(sort).put(bil_exp_property, Some(exp))
}

///|
fn bil_word(width : Int32, n : Int32) -> @types.Word raise {
  @types.Word::create(
    bitvec_of_int(width, n),
    if width < 1 {
      1
    } else {
      width
    },
  )
}

///|
fn bil_eff(stmts : Array[@types.Stmt]) -> Effect {
  Effect::empty(EffectSort::bot()).put(bil_stmts_slot, stmts)
}

///|
/// `Bil_semantics.Core`: the theory that denotes terms with BIL.
///
/// Values get the `bap:exp` property (see `bil_exp_slot`) and effects get
/// the `bap:bil` property (see `bil_slot`), so the result of a
/// theory-polymorphic lifter evaluated in this theory (or in a join with
/// it) can be read with `Value::bil`, `Effect::bil` or `Semantics::bil`.
/// The `Basic` operations that BIL does not express directly are derived
/// from the minimal ones (`Core::basic`); rounding modes are 8-bit
/// constants; floating-point and transcendental operations are left
/// empty (upstream emulates IEEE-754 floats in BIL only when the
/// `--bil-enable-fp-emulation` option is set; this emulator is not
/// ported).
///
/// Deviations: `append` extends/truncates the concatenation as documented
/// by the Core signature (upstream swaps the widening and narrowing
/// cases).
pub fn Core::bil() -> Core {
  bil_core
}

///|
let bil_core : Core = {
  let empty = Core::empty()
  let exp : (Sort, @types.Exp) -> Pure = (s, e) => _ => bil_value(s, e)
  let bit : (@types.Exp) -> Pure = e => exp(Sort::bool(), e)
  let unk : (Sort) -> Pure = s => {
    let name = if s == Sort::bool() || s.bitv_size() is Some(_) {
      "bits"
    } else {
      "unk"
    }
    exp(s, Unknown(name, s.bil_type()))
  }
  let eff : (Array[@types.Stmt]) -> Eff = stmts => _ => bil_eff(stmts)
  let lo1 : ((@types.Exp) -> @types.Exp) -> (Pure) -> Pure = f => {
    x => state => bil_value(Sort::bool(), f(bil_value_exp(x(state))))
  }
  let lo2 : ((@types.Exp, @types.Exp) -> @types.Exp) -> (Pure, Pure) -> Pure = f => {
    (x, y) => {
      state => {
        let x = bil_value_exp(x(state))
        let y = bil_value_exp(y(state))
        bil_value(Sort::bool(), f(x, y))
      }
    }
  }
  let uop : ((@types.Exp) -> @types.Exp) -> (Pure) -> Pure = f => {
    x => {
      state => {
        let x = x(state)
        bil_value(x.sort(), f(bil_value_exp(x)))
      }
    }
  }
  let aop : ((@types.Exp, @types.Exp) -> @types.Exp) -> (Pure, Pure) -> Pure = f => {
    (x, y) => {
      state => {
        let x = x(state)
        let y = bil_value_exp(y(state))
        bil_value(x.sort(), f(bil_value_exp(x), y))
      }
    }
  }
  let bin : (@types.BinOp) -> (@types.Exp, @types.Exp) -> @types.Exp = op => {
    (x, y) => BinOp(op, x, y)
  }
  let ult = lo2(bin(Lt))
  let slt = lo2(bin(SignedLt))
  let ule = lo2(bin(Le))
  let sle = lo2(bin(SignedLe))
  let int : (Sort, @bitvec.BitVec) -> Pure = (s, w) => {
    state => {
      ignore(state)
      bil_value(s, Int(@types.Word::create(w, sort_size(s))))
    }
  }
  let msb = lo1(e => Cast(kind=High, width=1, exp=e))
  let logor = aop(bin(Or))
  let ite : (Pure, Pure, Pure) -> Pure = (cnd, yes, nay) => {
    state => {
      let cnd = bil_value_exp(cnd(state))
      let yes = yes(state)
      let s = yes.sort()
      let yes = bil_value_exp(yes)
      let nay = bil_value_exp(nay(state))
      match (yes, nay) {
        (Int(w), Int(w1)) if w.bitwidth() == 1 && w.is_one() && w1.is_zero() =>
          bil_value(s, cnd)
        (Int(w), Int(w1)) if w.bitwidth() == 1 && w.is_zero() && w1.is_one() =>
          bil_value(s, UnOp(Not, cnd))
        _ => bil_value(s, Ite(cond=cnd, yes~, no=nay))
      }
    }
  }
  let mask_high : (Sort, Int32) -> Pure = (res, n) => {
    _ => {
      let width = sort_size(res)
      let ones = @types.Word::ones(width~)
      bil_value(res, Int(ones.rshift(n).lnot()))
    }
  }
  let cast : (Sort, Pure, Pure) -> Pure = (res, b, x) => {
    state => {
      let b = b(state)
      let x = x(state)
      let src = bil_value_exp(x)
      let fill = bil_value_exp(b)
      let diff = sort_size(res) - sort_size(x.sort())
      let casted : (@types.CastKind) -> Pure = kind => {
        exp(res, Cast(kind~, width=sort_size(res), exp=src))
      }
      let term = if diff == 0 {
        exp(res, src)
      } else if diff > 0 {
        match fill {
          Int(bit) =>
            if bit.is_zero() {
              casted(Unsigned)
            } else {
              ite(
                msb(pure_const(x)),
                casted(Signed),
                logor(casted(Unsigned), mask_high(res, diff)),
              )
            }
          _ =>
            ite(
              pure_const(b),
              logor(casted(Unsigned), mask_high(res, diff)),
              casted(Unsigned),
            )
        }
      } else {
        exp(res, Cast(kind=Low, width=sort_size(res), exp=src))
      }
      term(state)
    }
  }
  let shift : (Bool) -> (Pure, Pure, Pure) -> Pure = left => {
    (b, x, y) => {
      state => {
        let b = bil_value_exp(b(state))
        let x = x(state)
        let xs = x.sort()
        let x = bil_value_exp(x)
        let y = bil_value_exp(y(state))
        let op : @types.BinOp = if left { LShift } else { RShift }
        let shifted : @types.Exp = BinOp(op, x, y)
        let zero_fill = match b {
          Int(w) => w.is_zero()
          _ => false
        }
        if zero_fill {
          bil_value(xs, shifted)
        } else {
          let ones : @types.Exp = Int(@types.Word::ones(width=sort_size(xs)))
          let mask : @types.Exp = UnOp(Not, BinOp(op, ones, y))
          bil_value(xs, Ite(cond=b, yes=BinOp(Or, shifted, mask), no=shifted))
        }
      }
    }
  }
  let append : (Sort, Pure, Pure) -> Pure = (s, x, y) => {
    state => {
      let x = x(state)
      let y = y(state)
      let total = sort_size(x.sort()) + sort_size(y.sort())
      let both : @types.Exp = Concat(
        high=bil_value_exp(x),
        low=bil_value_exp(y),
      )
      let size = sort_size(s)
      if total == size {
        bil_value(s, both)
      } else if total < size {
        bil_value(s, Cast(kind=Unsigned, width=size, exp=both))
      } else {
        bil_value(s, Cast(kind=Low, width=size, exp=both))
      }
    }
  }
  let concat : (Sort, Array[Pure]) -> Pure = (s, xs) => {
    state => {
      if xs.is_empty() {
        return unk(s)(state)
      }
      let mut size = 0
      let mut result : @types.Exp? = None
      for x in xs {
        let x = x(state)
        size = size + sort_size(x.sort())
        let e = bil_value_exp(x)
        result = match result {
          None => Some(e)
          Some(acc) => Some(Concat(high=acc, low=e))
        }
      }
      cast(
        s,
        bit(Int(@types.Word::b0())),
        exp(Sort::bitv(size), result.unwrap()),
      )(state)
    }
  }
  let load : (Pure, Pure) -> Pure = (mem, key) => {
    state => {
      let mem = mem(state)
      let key = bil_value_exp(key(state))
      let vals = sort_mem_values(mem.sort())
      match @types.Size::of_int_opt(sort_size(vals)) {
        Some(sz) =>
          bil_value(
            vals,
            @types.Exp::load(mem=bil_value_exp(mem), addr=key, BigEndian, sz),
          )
        None => unk(vals)(state)
      }
    }
  }
  let store : (Pure, Pure, Pure) -> Pure = (m, k, d) => {
    state => {
      let m = m(state)
      let k = bil_value_exp(k(state))
      let d = d(state)
      match @types.Size::of_int_opt(sort_size(d.sort())) {
        Some(sz) =>
          bil_value(
            m.sort(),
            @types.Exp::store(
              mem=bil_value_exp(m),
              addr=k,
              bil_value_exp(d),
              BigEndian,
              sz,
            ),
          )
        None => unk(m.sort())(state)
      }
    }
  }
  let base : Core = {
    ..empty,
    var_: v => exp(v.sort(), Var(v.reify())),
    unk,
    let_: (bound, rhs, body) => {
      state => {
        let v = bound.reify()
        let rhs = bil_value_exp(rhs(state))
        let body = body(state)
        let bs = body.sort()
        let body = bil_value_exp(body)
        match rhs {
          Int(_) => bil_value(bs, body.substitute_var(v, rhs))
          _ => bil_value(bs, Let(v, rhs, body))
        }
      }
    },
    ite,
    b0: bit(Int(@types.Word::b0())),
    b1: bit(Int(@types.Word::b1())),
    inv: lo1(e => UnOp(Not, e)),
    and_: lo2(bin(And)),
    or_: lo2(bin(Or)),
    int,
    msb,
    lsb: lo1(e => Cast(kind=Low, width=1, exp=e)),
    neg: uop(e => UnOp(Neg, e)),
    not: uop(e => UnOp(Not, e)),
    add: aop(bin(Plus)),
    sub: aop(bin(Minus)),
    mul: aop(bin(Times)),
    div: aop(bin(Div)),
    sdiv: aop(bin(SignedDiv)),
    modulo: aop(bin(Mod)),
    smodulo: aop(bin(SignedMod)),
    logand: aop(bin(And)),
    logor,
    logxor: aop(bin(Xor)),
    shiftr: shift(false),
    shiftl: shift(true),
    sle,
    ule,
    cast,
    concat,
    append,
    load,
    store,
    perform: s => _ => Effect::empty(s),
    set: (lhs, rhs) => {
      state => bil_eff([Move(lhs.reify(), bil_value_exp(rhs(state)))])
    },
    jmp: dst => state => bil_eff([Jmp(bil_value_exp(dst(state)))]),
    goto: lbl => {
      eff([@types.Stmt::encode(@types.Stmt::goto(), bil_label_tid(lbl))])
    },
    seq: (x, y) => {
      state => {
        let x = x(state).bil()
        let y = y(state).bil()
        bil_eff(x + y)
      }
    },
    blk: (lbl, x, y) => {
      state => {
        let x = x(state).bil()
        let y = y(state).bil()
        if lbl.same(Label::null()) {
          bil_eff(x + y)
        } else {
          bil_eff(
            [@types.Stmt::encode(@types.Stmt::label(), bil_label_tid(lbl))] +
            x +
            y,
          )
        }
      }
    },
    repeat: (cnd, body) => {
      state => {
        let cnd = bil_value_exp(cnd(state))
        let body = body(state).bil()
        bil_eff([While(cond=cnd, body~)])
      }
    },
    branch: (cnd, yes, nay) => {
      state => {
        let cnd = bil_value_exp(cnd(state))
        let yes = yes(state).bil()
        let nay = nay(state).bil()
        if yes.is_empty() && nay.is_empty() {
          bil_eff([])
        } else {
          bil_eff([If(cond=cnd, yes~, no=nay)])
        }
      }
    },
    is_zero: x => {
      state => {
        let x = x(state)
        let zero : @types.Exp = Int(bil_word(sort_size(x.sort()), 0))
        bil_value(Sort::bool(), BinOp(Eq, bil_value_exp(x), zero))
      }
    },
    non_zero: x => {
      state => {
        let x = x(state)
        let zero : @types.Exp = Int(bil_word(sort_size(x.sort()), 0))
        bil_value(Sort::bool(), BinOp(Neq, bil_value_exp(x), zero))
      }
    },
    high: (s, x) => bil_make_cast(s, High, x),
    low: (s, x) => bil_make_cast(s, Low, x),
    signed: (s, x) => bil_make_cast(s, Signed, x),
    unsigned: (s, x) => bil_make_cast(s, Unsigned, x),
    arshift: aop(bin(ARShift)),
    rshift: aop(bin(RShift)),
    lshift: aop(bin(LShift)),
    eq: lo2(bin(Eq)),
    neq: lo2(bin(Neq)),
    slt,
    ult,
    sgt: (x, y) => slt(y, x),
    ugt: (x, y) => ult(y, x),
    sge: (x, y) => sle(y, x),
    uge: (x, y) => ule(y, x),
  }
  // `include Theory.Basic.Make(Base)` followed by `include Base`
  let derived = base.basic()
  let basic : Core = {
    ..derived,
    is_zero: base.is_zero,
    non_zero: base.non_zero,
    high: base.high,
    low: base.low,
    signed: base.signed,
    unsigned: base.unsigned,
    arshift: base.arshift,
    rshift: base.rshift,
    lshift: base.lshift,
    eq: base.eq,
    neq: base.neq,
    slt: base.slt,
    ult: base.ult,
    sgt: base.sgt,
    ugt: base.ugt,
    sge: base.sge,
    uge: base.uge,
  }
  let rmode : (Int32) -> Pure = n => {
    state => {
      let s = Sort::bitv(8)
      basic.int(s, bitvec_of_int(8, n))(state).refine(Sort::rmode())
    }
  }
  let as_byte : (Pure) -> Pure = x => state => x(state).refine(Sort::bitv(8))
  {
    ..basic,
    loadw: (rs, cnd, mem, key) => {
      match @types.Size::of_int_opt(sort_size(rs)) {
        None => basic.loadw(rs, cnd, mem, key)
        Some(sz) =>
          state => {
            let cnd = cnd(state)
            let key = bil_value_exp(key(state))
            let mem = bil_value_exp(mem(state))
            let bel = exp(rs, @types.Exp::load(mem~, addr=key, BigEndian, sz))
            let lel = exp(
              rs,
              @types.Exp::load(mem~, addr=key, LittleEndian, sz),
            )
            match bil_value_exp(cnd) {
              Int(dir) => if dir.is_one() { bel(state) } else { lel(state) }
              _ => ite(pure_const(cnd), bel, lel)(state)
            }
          }
      }
    },
    storew: (cnd, mem, key, elt) => {
      state => {
        let elt = elt(state)
        match @types.Size::of_int_opt(sort_size(elt.sort())) {
          None => basic.storew(cnd, mem, key, pure_const(elt))(state)
          Some(sz) => {
            let dir = bil_value_exp(cnd(state))
            let key = bil_value_exp(key(state))
            let mem = mem(state)
            let ms = mem.sort()
            let mem = bil_value_exp(mem)
            let e = bil_value_exp(elt)
            let bes = exp(
              ms,
              @types.Exp::store(mem~, addr=key, e, BigEndian, sz),
            )
            let les = exp(
              ms,
              @types.Exp::store(mem~, addr=key, e, LittleEndian, sz),
            )
            match dir {
              Int(dir) => if dir.is_one() { bes(state) } else { les(state) }
              _ => ite(bit(dir), bes, les)(state)
            }
          }
        }
      }
    },
    extract: (s, hi, lo, x) => {
      state => {
        let hi = hi(state)
        let lo = lo(state)
        let e = x(state)
        match (bil_value_exp(hi), bil_value_exp(lo)) {
          (Int(h), Int(l)) => {
            let h = h.to_int()
            let l = l.to_int()
            if h - l + 1 == sort_size(s) {
              bil_value(s, Extract(hi=h, lo=l, exp=bil_value_exp(e)))
            } else {
              basic.extract(s, pure_const(hi), pure_const(lo), pure_const(e))(
                state,
              )
            }
          }
          _ =>
            basic.extract(s, pure_const(hi), pure_const(lo), pure_const(e))(
              state,
            )
        }
      }
    },
    goto: lbl => {
      match lbl.addr() {
        Some(addr) =>
          _ => {
            let size = lbl.target().code_addr_size()
            let dst = if size > 0 {
              @types.Word::create(addr.to_bitvec(), size)
            } else {
              addr
            }
            bil_eff([Jmp(Int(dst))])
          }
        None =>
          match lbl.ivec() {
            Some(ivec) => eff([CpuExn(ivec)])
            None =>
              match lbl.name() {
                Some(name) =>
                  eff([@types.Stmt::encode(@types.Stmt::call(), name)])
                None => base.goto(lbl)
              }
          }
      }
    },
    fbits: x => state => unk(sort_float_bits(x(state).sort()))(state),
    rne: rmode(0),
    rna: rmode(1),
    rtp: rmode(2),
    rtn: rmode(3),
    rtz: rmode(4),
    requal: (x, y) => basic.eq(as_byte(x), as_byte(y)),
  }
}

///|
fn bil_make_cast(s : Sort, kind : @types.CastKind, x : Pure) -> Pure {
  state => {
    bil_value(s, Cast(kind~, width=sort_size(s), exp=bil_value_exp(x(state))))
  }
}

///|
/// The textual identifier of a label in BIL `goto`/`label` specials
/// (`Tid.to_string`).
fn bil_label_tid(label : Label) -> String {
  @types.Tid::restore(id=label.id()).to_string()
}
