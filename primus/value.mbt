///|
/// A Primus value: a word paired with a unique identifier
/// (upstream `Primus.Value.t = {id; value}`).
///
/// Every value produced by a machine gets a fresh identifier, which lets
/// analyses (e.g. taint trackers) distinguish values that are equal as
/// words. Identifiers are allocated from the machine-wide counter (the
/// upstream global `value` state), see `Value::of_word`.
pub struct Value {
  id : Int64
  value : @types.Word
} derive(Eq, Debug)

///|
pub fn Value::to_word(self : Value) -> @types.Word {
  self.value
}

///|
pub fn Value::id(self : Value) -> Int64 {
  self.id
}

///|
/// Upstream ordering: by identifier, then by word.
pub fn Value::compare(self : Value, other : Value) -> Int32 {
  let c = self.id.compare(other.id)
  if c != 0 {
    c
  } else {
    self.value.compare(other.value)
  }
}

///|
pub impl Compare for Value with fn compare(self, other) {
  Value::compare(self, other)
}

///|
pub impl Hash for Value with fn hash_combine(self, hasher) {
  hasher.combine(self.id)
}

///|
/// Renders the value as `<word>#<id>`.
pub fn Value::to_string(self : Value) -> String {
  "\{self.value.to_string()}#\{self.id}"
}

///|
pub impl Show for Value with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn Value::to_sexp(self : Value) -> Sexp {
  Atom(self.to_string())
}

///|
pub fn Value::bitwidth(self : Value) -> Int32 {
  self.value.bitwidth()
}

///|
pub fn Value::is_zero(self : Value) -> Bool {
  self.value.is_zero()
}

///|
pub fn Value::is_one(self : Value) -> Bool {
  self.value.is_one()
}

///|
pub fn Value::is_positive(self : Value) -> Bool {
  self.value.is_positive()
}

///|
pub fn Value::is_negative(self : Value) -> Bool {
  self.value.is_negative()
}

///|
pub fn Value::is_non_positive(self : Value) -> Bool {
  self.value.is_non_positive()
}

///|
pub fn Value::is_non_negative(self : Value) -> Bool {
  self.value.is_non_negative()
}

///|
/// Creates a fresh value from a word (`Value.of_word`).
pub fn Value::of_word(m : Machine, w : @types.Word) -> Value {
  { id: m.fresh_value_id(), value: w, }
}

///|
fn word_error(e : Error) -> PrimusError {
  RuntimeError("word operation failed: \{e}")
}

///|
fn[T] wrap_word(f : () -> T raise) -> T raise PrimusError {
  f() catch {
    e => raise word_error(e)
  }
}

///|
/// Parses a word literal such as `0x10:32u` (`Value.of_string`).
pub fn Value::of_string(m : Machine, s : String) -> Value raise PrimusError {
  Value::of_word(m, wrap_word(() => @types.Word::from_string(s)))
}

///|
pub fn Value::of_bool(m : Machine, b : Bool) -> Value {
  Value::of_word(m, @types.Word::of_bool(b))
}

///|
pub fn Value::of_int(
  m : Machine,
  width~ : Int32,
  x : Int32,
) -> Value raise PrimusError {
  Value::of_word(m, wrap_word(() => @types.Word::of_int(width~, x)))
}

///|
pub fn Value::of_int64(
  m : Machine,
  width~ : Int32 = 64,
  x : Int64,
) -> Value raise PrimusError {
  Value::of_word(m, wrap_word(() => @types.Word::of_int64(x, width~)))
}

///|
pub fn Value::b0(m : Machine) -> Value {
  Value::of_word(m, @types.Word::b0())
}

///|
pub fn Value::b1(m : Machine) -> Value {
  Value::of_word(m, @types.Word::b1())
}

///|
pub fn Value::one(m : Machine, width : Int32) -> Value raise PrimusError {
  Value::of_word(m, wrap_word(() => @types.Word::one(width~)))
}

///|
pub fn Value::zero(m : Machine, width : Int32) -> Value raise PrimusError {
  Value::of_word(m, wrap_word(() => @types.Word::zero(width~)))
}

///|
pub fn Value::ones(m : Machine, width : Int32) -> Value raise PrimusError {
  Value::of_word(m, wrap_word(() => @types.Word::ones(width~)))
}

///|
pub fn Value::signed(m : Machine, x : Value) -> Value {
  Value::of_word(m, x.value.signed())
}

///|
pub fn Value::extract(
  m : Machine,
  hi? : Int32,
  lo~ : Int32 = 0,
  x : Value,
) -> Value raise PrimusError {
  let hi = hi.unwrap_or(x.bitwidth() - 1)
  Value::of_word(m, wrap_word(() => x.value.extract(hi~, lo~)))
}

///|
pub fn Value::concat(
  m : Machine,
  x : Value,
  y : Value,
) -> Value raise PrimusError {
  Value::of_word(m, wrap_word(() => x.value.concat(y.value)))
}

///|
pub fn Value::succ(m : Machine, x : Value) -> Value {
  Value::of_word(m, x.value.succ())
}

///|
pub fn Value::pred(m : Machine, x : Value) -> Value {
  Value::of_word(m, x.value.pred())
}

///|
pub fn Value::nsucc(m : Machine, x : Value, n : Int32) -> Value {
  Value::of_word(m, x.value.nsucc(n))
}

///|
pub fn Value::npred(m : Machine, x : Value, n : Int32) -> Value {
  Value::of_word(m, x.value.npred(n))
}

///|
pub fn Value::abs(m : Machine, x : Value) -> Value {
  Value::of_word(m, x.value.abs())
}

///|
pub fn Value::neg(m : Machine, x : Value) -> Value {
  Value::of_word(m, x.value.neg())
}

///|
pub fn Value::lnot(m : Machine, x : Value) -> Value {
  Value::of_word(m, x.value.lnot())
}

///|
fn Value::lift2(
  m : Machine,
  x : Value,
  y : Value,
  f : (@types.Word, @types.Word) -> @types.Word raise @bitvec.BitVecError,
) -> Value raise PrimusError {
  Value::of_word(m, wrap_word(() => f(x.value, y.value)))
}

///|
pub fn Value::add(m : Machine, x : Value, y : Value) -> Value raise PrimusError {
  Value::lift2(m, x, y, @types.Word::add)
}

///|
pub fn Value::sub(m : Machine, x : Value, y : Value) -> Value raise PrimusError {
  Value::lift2(m, x, y, @types.Word::sub)
}

///|
pub fn Value::mul(m : Machine, x : Value, y : Value) -> Value raise PrimusError {
  Value::lift2(m, x, y, @types.Word::mul)
}

///|
pub fn Value::div(m : Machine, x : Value, y : Value) -> Value raise PrimusError {
  Value::lift2(m, x, y, @types.Word::div)
}

///|
pub fn Value::modulo(
  m : Machine,
  x : Value,
  y : Value,
) -> Value raise PrimusError {
  Value::lift2(m, x, y, @types.Word::modulo)
}

///|
pub fn Value::logand(
  m : Machine,
  x : Value,
  y : Value,
) -> Value raise PrimusError {
  Value::lift2(m, x, y, @types.Word::logand)
}

///|
pub fn Value::logor(
  m : Machine,
  x : Value,
  y : Value,
) -> Value raise PrimusError {
  Value::lift2(m, x, y, @types.Word::logor)
}

///|
pub fn Value::logxor(
  m : Machine,
  x : Value,
  y : Value,
) -> Value raise PrimusError {
  Value::lift2(m, x, y, @types.Word::logxor)
}

///|
fn shift_amount(y : Value) -> Int32 {
  // clamp by numeric magnitude: a wide operand with a small value (e.g.
  // `1:128`) is a small shift amount
  let big = 0x7fffffffUL
  let w = y.value
  let low = if w.bitwidth() > 64 {
    let high = w.extract(hi=w.bitwidth() - 1, lo=64) catch {
      _ => return 0x7fffffff
    }
    if !high.is_zero() {
      return 0x7fffffff
    }
    let l = w.extract(hi=63, lo=0) catch { _ => return 0x7fffffff }
    l.to_uint64() catch {
      _ => big
    }
  } else {
    w.to_uint64() catch {
      _ => big
    }
  }
  if low < big {
    low.to_int()
  } else {
    0x7fffffff
  }
}

///|
pub fn Value::lshift(m : Machine, x : Value, y : Value) -> Value {
  Value::of_word(m, x.value.lshift(shift_amount(y)))
}

///|
pub fn Value::rshift(m : Machine, x : Value, y : Value) -> Value {
  Value::of_word(m, x.value.rshift(shift_amount(y)))
}

///|
pub fn Value::arshift(m : Machine, x : Value, y : Value) -> Value {
  Value::of_word(m, x.value.arshift(shift_amount(y)))
}

///|
/// Persistent string interning table (upstream `Value.Index`).
priv struct SymbolIndex {
  by_name : @immut_hashmap.HashMap[String, Int32]
  by_key : @sorted_map.SortedMap[Int32, String]
  last : Int32
}

///|
/// Width of symbol keys (upstream `Value.Index.key_width`).
pub let symbol_key_width : Int32 = 63

///|
let symbols_state : State[SymbolIndex] = State::declare_(
  uuid="2d2293e9-4c42-4b82-90a7-7e8e74fd01ed",
  name="symbols",
  _ => {
    by_name: @immut_hashmap.HashMap::new(),
    by_key: @sorted_map.SortedMap::new(),
    last: 0,
  },
)

///|
/// Interns a symbol and returns its value (`Value.Symbol.to_value`).
/// The same symbol always maps to the same key; the returned value has the
/// identifier 0.
pub fn Value::symbol_to_value(
  m : Machine,
  sym : String,
) -> Value raise PrimusError {
  let index = m.get_global(symbols_state)
  let key = match index.by_name.get(sym) {
    Some(k) => k
    None => {
      let k = index.last + 1
      m.put_global(symbols_state, {
        by_name: index.by_name.add(sym, k),
        by_key: index.by_key.add(k, sym),
        last: k,
      })
      k
    }
  }
  {
    id: 0L,
    value: wrap_word(() => @types.Word::of_int(width=symbol_key_width, key)),
  }
}

///|
/// Returns the symbol interned under the value (`Value.Symbol.of_value`),
/// or the empty string.
pub fn Value::symbol_of_value(m : Machine, v : Value) -> String {
  let index = m.get_global(symbols_state)
  let n = v.value.to_uint64() catch { _ => return "" }
  guard n < 0x7fffffffUL else { return "" }
  let key = n.to_int()
  index.by_key.get(key).unwrap_or("")
}
