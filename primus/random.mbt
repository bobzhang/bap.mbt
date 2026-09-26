///|
/// A multiplicative congruential generator with a power-of-two modulus
/// (upstream `Primus.Random.MCG.S`).
///
/// The state is an array of sub-generator states (one element for the
/// basis generators); states are never mutated, `next` returns a new array.
pub struct Mcg {
  size : Int
  min : UInt64
  max : UInt64
  create : (Int) -> Array[UInt64]
  next : (Array[UInt64]) -> Array[UInt64]
  value : (Array[UInt64]) -> @bitvec.BitVec
}

///|
fn mask64(bits : Int) -> UInt64 {
  if bits >= 64 {
    0xFFFFFFFFFFFFFFFFUL
  } else if bits <= 0 {
    0UL
  } else {
    (1UL << bits) - 1UL
  }
}

///|
fn bv_of_u64(width : Int, x : UInt64) -> @bitvec.BitVec {
  try! @bitvec.of_uint64(width~, x & mask64(width))
}

///|
fn bv_to_u64(x : @bitvec.BitVec) -> UInt64 {
  if x.width() > 64 {
    (try! x.truncate(width=64)).to_uint64() catch {
      _ => 0UL
    }
  } else {
    x.to_uint64() catch {
      _ => 0UL
    }
  }
}

///|
fn odd_hash(seed : Int) -> UInt64 {
  let h = seed.to_uint64() * 2UL + 1UL
  if h == 0UL {
    1UL
  } else {
    h
  }
}

///|
/// A basis generator with modulus `2^m` and multiplier `a`: it produces
/// `m - 3` bits of pseudorandomness.
fn mcg_basis(m : Int, a : UInt64) -> Mcg {
  let size = m - 3
  let mk = mask64(m)
  {
    size,
    min: 0UL,
    max: mask64(size),
    create: seed => [(a * odd_hash(seed)) & mk],
    next: xs => [(a * xs[0]) & mk],
    value: xs => bv_of_u64(size, xs[0] >> 3),
  }
}

///|
/// Multipliers from arXiv:2001.05304 (as upstream).
let mcg13 : Mcg = mcg_basis(16, 0x7dc5UL)

///|
let mcg29 : Mcg = mcg_basis(32, 0xae3cc725UL)

///|
let mcg61 : Mcg = mcg_basis(64, 0xcc62fceb9202faadUL)

///|
/// Keeps the `size` most significant bits of a wider generator.
fn mcg_cut(size : Int, sub : Mcg) -> Mcg {
  let noise = sub.size - size
  {
    size,
    min: 0UL,
    max: mask64(size),
    create: sub.create,
    next: sub.next,
    value: xs => {
      let v = (sub.value)(xs).rshift(noise)
      try! v.truncate(width=size)
    },
  }
}

///|
/// Concatenates several basis generators to produce `size` bits.
fn mcg_cat(size : Int, sub : Mcg) -> Mcg {
  let generators = (size + sub.size - 1) / sub.size
  {
    size,
    min: 0UL,
    max: mask64(size),
    create: seed => {
      let out = []
      for salt in 0..<generators {
        out.push((sub.create)(seed + salt)[0])
      }
      out
    },
    next: xs => xs.map(x => (sub.next)([x])[0]),
    value: xs => {
      let mut y = try! @bitvec.zero(width=size)
      for x in xs {
        let v = try! (sub.value)([x]).widen(width=size)
        y = try! y.lshift(sub.size).bit_or(v)
      }
      y
    },
  }
}

///|
/// Maps a generator into the `[min, max]` range (sizes up to 64 bits).
fn mcg_range(size : Int, min : UInt64, max : UInt64, gen : Mcg) -> Mcg {
  let mk = mask64(size)
  let range = (max - min + 1UL) & mk
  {
    size,
    min,
    max,
    create: gen.create,
    next: gen.next,
    value: xs => {
      let u = bv_to_u64((gen.value)(xs))
      let off = if range == 0UL { u } else { u % range }
      bv_of_u64(size, (min + off) & mk)
    },
  }
}

///|
/// The generator for the given bit width (upstream `MCG.make_for_width`).
pub fn Mcg::for_width(width : Int) -> Mcg {
  let n = if width < 1 { 1 } else { width }
  match n {
    13 => mcg13
    29 => mcg29
    64 => mcg_cat(64, mcg29)
    _ =>
      if n < 13 {
        mcg_cut(n, mcg13)
      } else if n < 29 {
        mcg_cut(n, mcg29)
      } else if n < 61 {
        mcg_cut(n, mcg61)
      } else if n == 61 {
        mcg61
      } else {
        mcg_cat(n, mcg61)
      }
  }
}

///|
fn ceil_log2(x : UInt64) -> Int {
  // the number of bits needed to represent values in [0, x)
  if x <= 1UL {
    return 1
  }
  let mut bits = 0
  let mut v = x - 1UL
  while v != 0UL {
    bits += 1
    v = v >> 1
  }
  bits
}

///|
/// Creates a generator of `width` bits, optionally restricted to the
/// `[min, max]` range (upstream `MCG.create`/`create_small`).
///
/// Upstream sizes the underlying generator by the *number* of values in
/// the range; this port sizes it by the number of *bits* needed to cover
/// the range, which is equivalent in distribution and avoids the upstream
/// zero-range corner case.
pub fn Mcg::create(min? : Int, max? : Int, width : Int) -> Mcg {
  if min is None && max is None {
    return Mcg::for_width(width)
  }
  let w = if width > 64 { 64 } else if width < 1 { 1 } else { width }
  let mk = mask64(w)
  let lo = match min {
    Some(x) => x.to_uint64() & mk
    None => 0UL
  }
  let hi = match max {
    Some(x) => x.to_uint64() & mk
    None => mk
  }
  let range = (hi - lo + 1UL) & mk
  let bits = if range == 0UL { w } else { ceil_log2(range) }
  mcg_range(w, lo, hi, Mcg::for_width(bits))
}

///|
/// Enumerates the first `n` values of a generator seeded with `seed`
/// (upstream `MCG.tabulate`, returning the values instead of printing).
pub fn Mcg::tabulate(self : Mcg, n~ : Int, seed : Int) -> Array[@bitvec.BitVec] {
  let out = []
  let mut state = (self.create)(seed)
  for _ in 0..<n {
    out.push((self.value)(state))
    state = (self.next)(state)
  }
  out
}
