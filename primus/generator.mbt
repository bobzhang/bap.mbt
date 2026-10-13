///|
/// A type-erased iterator instance: the current value, the successor, and
/// the reseeding function (upstream `Generator.iterator` existential).
priv struct GenIter {
  value : () -> @bitvec.BitVec
  next : () -> GenIter
  seed : (Int32) -> GenIter
}

///|
fn[T, D] make_gen_iter(
  iface : Infinite[T, D],
  to_bitvec : (D) -> @bitvec.BitVec,
  state : T,
  seed : (Int32) -> T,
) -> GenIter {
  {
    value: () => to_bitvec((iface.value)(state)),
    next: () => make_gen_iter(iface, to_bitvec, (iface.next)(state), seed),
    seed: s => make_gen_iter(iface, to_bitvec, seed(s), seed),
  }
}

///|
priv enum GenCtor {
  Const(GenIter)
  Seeded((Int32) -> GenIter)
}

///|
/// A value generator used to produce values of uninitialized variables and
/// memory (upstream `Primus.Generator.t`).
///
/// A generator is a *description*: the iteration state lives in the local
/// state of each machine, so forks advance their generators independently.
/// When a generator is first used in a machine it is seeded with the
/// machine identifier plus a per-machine salt (seedable generators only).
pub struct Generator {
  priv size : Int32
  priv init : GenCtor
  priv id : Int32
}

///|
let last_generator_id : Ref[Int32] = { val: 0, }

///|
fn next_generator_id() -> Int32 {
  last_generator_id.val += 1
  last_generator_id.val
}

///|
/// The number of bits produced by one iteration.
pub fn Generator::width(self : Generator) -> Int32 {
  self.size
}

///|
pub fn Generator::to_sexp(self : Generator) -> Sexp {
  List([Atom("generator"), Atom(self.id.to_string())])
}

///|
/// Creates a generator from an infinite iterator (upstream
/// `Generator.of_iterator`). `seed` rebuilds the iterator state from a seed;
/// without it the generator always starts from `init`.
pub fn[T, D] Generator::of_iterator(
  width~ : Int32 = 8,
  seed? : (Int32) -> T,
  to_bitvec~ : (D) -> @bitvec.BitVec,
  iface : Infinite[T, D],
  init : T,
) -> Generator {
  let seed : (Int32) -> T = match seed {
    Some(f) => f
    None => _ => init
  }
  {
    size: width,
    id: next_generator_id(),
    init: Const(make_gen_iter(iface, to_bitvec, init, seed)),
  }
}

///|
/// Creates a generator from an iterator over integers (upstream
/// `Generator.create`); values are taken modulo `2^width`.
pub fn[T] Generator::create(
  width~ : Int32 = 8,
  iface : Infinite[T, Int32],
  init : T,
) -> Generator {
  Generator::of_iterator(
    width~,
    to_bitvec=(x : Int32) => bv_of_u64(width, x.to_uint64()),
    iface,
    init,
  )
}

///|
/// A generator that always produces the same value (upstream
/// `Generator.static`).
pub fn Generator::static_value(width~ : Int32 = 8, value : Int32) -> Generator {
  let v = bv_of_u64(width, value.to_uint64())
  Generator::of_iterator(
    width~,
    to_bitvec=x => x,
    { min: v, max: v, value: x => x, next: x => x, },
    v,
  )
}

///|
/// A generator defined by an unfolding function over `(state, value)`
/// pairs (upstream `Generator.unfold`).
pub fn[A] Generator::unfold(
  width~ : Int32 = 8,
  min~ : Int32 = -2147483648,
  max~ : Int32 = 2147483647,
  seed~ : Int32 = 0,
  f~ : ((A, Int32)) -> (A, Int32),
  init : A,
) -> Generator {
  Generator::create(
    width~,
    { min, max, value: (p : (A, Int32)) => p.1, next: f, },
    (init, seed),
  )
}

///|
fn mcg_generator(width : Int32, mcg : Mcg, start : Int32) -> Generator {
  let iface : Infinite[Array[UInt64], @bitvec.BitVec] = {
    min: bv_of_u64(width, mcg.min),
    max: bv_of_u64(width, mcg.max),
    value: mcg.value,
    next: mcg.next,
  }
  Generator::of_iterator(
    width~,
    seed=s => (mcg.create)(s + start),
    to_bitvec=x => x,
    iface,
    (mcg.create)(start),
  )
}

///|
/// A seedable pseudorandom generator (upstream `Generator.Random.lcg`).
pub fn Generator::random_lcg(
  width~ : Int32 = 8,
  min? : Int32,
  max? : Int32,
  seed : Int32,
) -> Generator {
  mcg_generator(width, Mcg::create(min?, max?, width), seed)
}

///|
/// A seedable pseudorandom byte generator (upstream `Generator.Random.byte`).
pub fn Generator::random_byte(seed : Int32) -> Generator {
  Generator::random_lcg(min=0, max=255, seed)
}

///|
/// A generator whose iterator is built from the machine seed (upstream
/// `Generator.Random.Seeded.create`).
pub fn Generator::seeded_create(
  width~ : Int32 = 8,
  init : (Int32) -> Generator,
) -> Generator {
  let make = fn(seed : Int32) -> GenIter {
    match init(seed).init {
      Const(it) => it
      Seeded(f) => f(seed)
    }
  }
  { size: width, init: Seeded(make), id: next_generator_id(), }
}

///|
/// A pseudorandom generator seeded by the machine (upstream
/// `Generator.Random.Seeded.lcg`).
pub fn Generator::seeded_lcg(
  width~ : Int32 = 8,
  min? : Int32,
  max? : Int32,
) -> Generator {
  Generator::random_lcg(width~, min?, max?, 0)
}

///|
/// A pseudorandom byte generator seeded by the machine (upstream
/// `Generator.Random.Seeded.byte`).
pub fn Generator::seeded_byte() -> Generator {
  Generator::seeded_lcg()
}

///|
priv struct GenState {
  iterators : @sorted_map.SortedMap[Int32, GenIter]
  salt : Int32
}

///|
let generators_state : State[GenState] = State::declare_(
  name="iterators",
  uuid="9927004d-fe57-4de9-8705-c3d6862238cf",
  _ => { iterators: @sorted_map.SortedMap::new(), salt: 1, },
)

///|
fn Generator::call(self : Generator, m : Machine) -> @bitvec.BitVec {
  for ;; {
    let st = m.get_local(generators_state)
    match st.iterators.get(self.id) {
      Some(it) => {
        let value = (it.value)()
        m.put_local(generators_state, {
          iterators: st.iterators.add(self.id, (it.next)()),
          salt: st.salt,
        })
        return value
      }
      None => {
        let seed = m.current().0 + st.salt
        match self.init {
          Const(it) =>
            m.put_local(generators_state, {
              iterators: st.iterators.add(self.id, (it.seed)(seed)),
              salt: st.salt + 1,
            })
          Seeded(init) =>
            m.put_local(generators_state, {
              iterators: st.iterators.add(self.id, init(seed)),
              salt: st.salt,
            })
        }
      }
    }
  }
}

///|
/// The next value of the generator as an integer (upstream
/// `Generator.Make(M).next`); values that do not fit are saturated.
pub fn Generator::next(m : Machine, gen : Generator) -> Int32 {
  let x = gen.call(m)
  if x.fits_int() {
    x.to_int() catch {
      _ => 2147483647
    }
  } else {
    2147483647
  }
}

///|
/// Produces a word of the given width by concatenating as many iterations
/// as needed (upstream `Generator.Make(M).word`); the first iteration
/// provides the most significant bits and the result keeps the `width`
/// least significant bits.
pub fn Generator::word(
  m : Machine,
  gen : Generator,
  width : Int32,
) -> @types.Word {
  let mut x = gen.call(m)
  let mut built = gen.size
  while built < width {
    let y = gen.call(m)
    x = try! x.concat(y)
    built += gen.size
  }
  try! @types.Word::create(x, width)
}
