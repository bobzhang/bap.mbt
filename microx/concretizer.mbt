// Port of `Microx_concretizer`: an expression interpreter that never
// halts due to an unknown value.

///|
/// A policy for concretizing unknown values.
pub(all) enum Policy {
  /// a random 64-bit value
  Random
  /// the given constant
  Fixed(Int64)
  /// a random value from the inclusive interval `[lo, hi]`
  Interval(Int64, Int64)
} derive(Eq, Debug)

///|
pub extend Policy with Eq::{not_equal, equal}

///|
pub extend Policy with Debug::{to_repr}

///|
/// Renders the policy as the upstream s-expression, e.g. `(Fixed 42)`.
pub fn Policy::to_string(self : Policy) -> String {
  match self {
    Random => "Random"
    Fixed(x) => "(Fixed \{x})"
    Interval(lo, hi) => "(Interval \{lo} \{hi})"
  }
}

///|
fn rand64(rng : @random.Rand, lo : Int64, hi : Int64) -> Int64 {
  let (lo, hi) = if hi < lo { (hi, lo) } else { (lo, hi) }
  let span = (hi - lo).reinterpret_as_uint64() + 1UL
  let offset = if span == 0UL { rng.uint64() } else { rng.uint64(limit=span) }
  lo + offset.reinterpret_as_int64()
}

///|
/// [generate(rng, policy)] produces a 64-bit value according to [policy].
///
/// Upstream draws interval values with a slightly off formula
/// (`lo + random (hi + (hi - lo))`); this port samples uniformly from the
/// documented inclusive interval instead.
pub fn generate(rng : @random.Rand, policy : Policy) -> Int64 {
  match policy {
    Fixed(x) => x
    Random => rng.uint64().reinterpret_as_int64()
    Interval(lo, hi) => rand64(rng, lo, hi)
  }
}

///|
fn generate_word(rng : @random.Rand, policy : Policy, size : Int) -> Word {
  let value = generate(rng, policy)
  @types.Word::of_int64(value).extract(hi=size - 1, lo=0) catch {
    _ => panic()
  }
}

///|
fn seeded_rng(seed : Int?) -> @random.Rand {
  match seed {
    None => @random.Rand::new()
    Some(seed) => {
      let bytes = FixedArray::make(32, (0 : Byte))
      for i in 0..<4 {
        bytes[i] = ((seed >> (8 * i)) & 0xff).to_byte()
      }
      @random.Rand::chacha8(seed=Bytes::from_array(bytes[:]))
    }
  }
}

///|
/// Creates a concretizing expression interpreter (upstream
/// `Microx_concretizer.main`).
///
/// - `memory` returns a byte value at the given address, if known;
/// - `lookup` returns a value of a given variable, if known;
/// - `random_seed`, if specified, seeds the pseudo random generator (each
///   concretizer owns its generator);
/// - `reg_policy` is the policy for concretizing register values and
///   `Unknown` expressions;
/// - `mem_policy` is the policy for concretizing heap values.
///
/// Concretized values are not written back into the context, so every
/// evaluation of an unknown variable or cell produces a fresh value, as
/// upstream.
pub fn concretizer(
  memory? : (Word) -> Word?,
  lookup? : (Var) -> Word?,
  random_seed? : Int,
  reg_policy? : Policy = Random,
  mem_policy? : Policy = Random,
) -> Expi {
  let rng = seeded_rng(random_seed)
  let emit = (typ : ValueType) => {
    match typ {
      Imm(size) => @types.BilResultImm(generate_word(rng, reg_policy, size))
      Mem(_) => @types.BilResultMem(BilResultStorage::linear())
    }
  }
  Expi::new(
    lookup=variable => {
      match lookup {
        Some(f) =>
          match f(variable) {
            Some(word) => BilResultImm(word)
            None => emit(variable.typ())
          }
        None => emit(variable.typ())
      }
    },
    load=addr => {
      match memory {
        Some(f) =>
          match f(addr) {
            Some(word) => BilResultImm(word)
            None => BilResultImm(generate_word(rng, mem_policy, 8))
          }
        None => BilResultImm(generate_word(rng, mem_policy, 8))
      }
    },
    unknown=(_, typ) => emit(typ),
  )
}
