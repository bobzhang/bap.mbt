///|
/// The bitvector `n mod 2^width` (negative numbers are taken in two's
/// complement); non-bitvector sorts (of size zero) use one bit.
pub fn bitvec_of_int(width : Int32, n : Int32) -> @bitvec.BitVec raise {
  let width = if width < 1 { 1 } else { width }
  if n >= 0 {
    @bitvec.of_int(width~, n)
  } else {
    @bitvec.of_int(width~, 0 - n).neg()
  }
}

///|
/// `Theory.Basic.Make(L)`: expresses the operations of the Basic theory in
/// terms of the operations of the Minimal theory of `self`.
///
/// The result is `self` with the `Basic` operations (`zero`, `is_zero`,
/// `non_zero`, `succ`, `pred`, `nsucc`, `npred`, `high`, `low`, `signed`,
/// `unsigned`, `extract`, `loadw`, `storew`, `arshift`, `rshift`,
/// `lshift`, `eq`, `neq`, `slt`, `ult`, `sgt`, `ugt`, `sge`, `uge`)
/// replaced by their derivations, so a theory only needs to define the
/// `Minimal` operations (`Init`, `Bool`, `Bitv`, `Memory`, `Effect`).
///
/// `storew` differs from upstream, whose shift amounts store the chunks
/// in the reverse of the order in which `loadw` loads them: here the
/// chunks are stored so that `loadw` with the same direction reads back
/// the stored word.
pub fn Core::basic(self : Core) -> Core {
  let l = self
  let eq : (Pure, Pure) -> Pure = (x, y) => {
    state => {
      let x = pure_const(x(state))
      let y = pure_const(y(state))
      l.and_(l.ule(x, y), l.ule(y, x))(state)
    }
  }
  let neq : (Pure, Pure) -> Pure = (x, y) => l.inv(eq(x, y))
  let slt : (Pure, Pure) -> Pure = (x, y) => {
    state => {
      let x = pure_const(x(state))
      let y = pure_const(y(state))
      l.and_(l.sle(x, y), l.inv(l.sle(y, x)))(state)
    }
  }
  let ult : (Pure, Pure) -> Pure = (x, y) => {
    state => {
      let x = pure_const(x(state))
      let y = pure_const(y(state))
      l.and_(l.ule(x, y), l.inv(l.ule(y, x)))(state)
    }
  }
  let small : (Sort, Int32) -> Pure = (s, n) => {
    state => l.int(s, bitvec_of_int(sort_size(s), n))(state)
  }
  let zero : (Sort) -> Pure = s => small(s, 0)
  let is_zero : (Pure) -> Pure = x => {
    state => {
      let x = x(state)
      eq(pure_const(x), zero(x.sort()))(state)
    }
  }
  let nsucc : (Pure, Int32) -> Pure = (x, n) => {
    state => {
      let x = x(state)
      l.add(pure_const(x), small(x.sort(), n))(state)
    }
  }
  let npred : (Pure, Int32) -> Pure = (x, n) => {
    state => {
      let x = x(state)
      l.sub(pure_const(x), small(x.sort(), n))(state)
    }
  }
  let succ : (Pure) -> Pure = x => nsucc(x, 1)
  let high : (Sort, Pure) -> Pure = (s, x) => {
    state => {
      let x = x(state)
      let t = x.sort()
      let diff = sort_size(t) - sort_size(s)
      let n = if diff < 0 { 0 } else { diff }
      let n = if n > sort_size(t) { sort_size(t) } else { n }
      l.cast(s, l.b0, l.shiftr(l.b0, pure_const(x), small(t, n)))(state)
    }
  }
  let bind : (Pure, (Var) -> Pure) -> Pure = (exp, body) => {
    state => {
      let exp = exp(state)
      Var::scoped_pure(exp.sort(), v => l.let_(v, pure_const(exp), body(v)))(
        state,
      )
    }
  }
  let loadw : (Sort, Pure, Pure, Pure) -> Pure = (out, dir, mem, key) => {
    state => {
      let dir = pure_const(dir(state))
      let mem = mem(state)
      let key = pure_const(key(state))
      let chunk_size = sort_size(sort_mem_values(mem.sort()))
      let needed = sort_size(out)
      let mem = pure_const(mem)
      fn loop_(chunks : @list.List[Pure], loaded : Int32) -> Pure {
        if loaded < needed && chunk_size > 0 {
          let key = nsucc(key, loaded / chunk_size)
          bind(l.load(mem, key), chunk => {
            loop_(chunks.prepend(l.var_(chunk)), loaded + chunk_size)
          })
        } else {
          l.ite(
            dir,
            l.concat(out, chunks.rev().to_array()),
            l.concat(out, chunks.to_array()),
          )
        }
      }

      loop_(@list.List([]), 0)(state)
    }
  }
  let storew : (Pure, Pure, Pure, Pure) -> Pure = (dir, mem, key, data) => {
    state => {
      let data = data(state)
      let mem = mem(state)
      let data_t = data.sort()
      let chunks = sort_mem_values(mem.sort())
      let needed = sort_size(data_t)
      let chunk_len = sort_size(chunks)
      let data = pure_const(data)
      let nth : (Int32) -> Pure = stored => {
        let shift = l.ite(
          dir,
          small(data_t, needed - stored - chunk_len),
          small(data_t, stored),
        )
        l.cast(chunks, l.b0, l.shiftr(l.b0, data, shift))
      }
      fn loop_(key : Pure, stored : Int32, mem : Pure) -> Pure {
        if stored < needed && chunk_len > 0 {
          loop_(succ(key), stored + chunk_len, l.store(mem, key, nth(stored)))
        } else {
          mem
        }
      }

      loop_(key, 0, pure_const(mem))(state)
    }
  }
  let lshift : (Pure, Pure) -> Pure = (x, y) => l.shiftl(l.b0, x, y)
  {
    ..l,
    eq,
    neq,
    slt,
    ult,
    sgt: (x, y) => slt(y, x),
    ugt: (x, y) => ult(y, x),
    sge: (x, y) => l.sle(y, x),
    uge: (x, y) => l.ule(y, x),
    zero,
    is_zero,
    non_zero: x => l.inv(is_zero(x)),
    nsucc,
    npred,
    succ,
    pred: x => npred(x, 1),
    high,
    low: (s, x) => l.cast(s, l.b0, x),
    signed: (s, x) => l.cast(s, l.msb(x), x),
    unsigned: (s, x) => l.cast(s, l.b0, x),
    loadw,
    storew,
    arshift: (x, y) => l.shiftr(l.msb(x), x, y),
    rshift: (x, y) => l.shiftr(l.b0, x, y),
    lshift,
    extract: (s, hi, lo, x) => {
      state => {
        let n = succ(l.sub(hi, lo))
        let x = x(state)
        let mask = lshift(l.not(zero(x.sort())), n)
        l.cast(
          s,
          l.b0,
          l.logand(l.not(mask), l.shiftr(l.b0, pure_const(x), lo)),
        )(state)
      }
    },
  }
}
