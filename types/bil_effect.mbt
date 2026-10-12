///|
struct ExpEffect {
  reads_value : Bool
  loads_value : Bool
  stores_value : Bool
  raises_value : Bool
} derive(Eq, Debug)

///|
pub extend ExpEffect with Eq::{not_equal, equal}

///|
pub extend ExpEffect with Debug::{to_repr}

///|
fn ExpEffect::new(
  reads_value~ : Bool = false,
  loads_value~ : Bool = false,
  stores_value~ : Bool = false,
  raises_value~ : Bool = false,
) -> ExpEffect {
  { reads_value, loads_value, stores_value, raises_value, }
}

///|
pub fn ExpEffect::none() -> ExpEffect {
  ExpEffect::new()
}

///|
pub fn ExpEffect::read() -> ExpEffect {
  ExpEffect::new(reads_value=true)
}

///|
pub fn ExpEffect::load() -> ExpEffect {
  ExpEffect::new(loads_value=true)
}

///|
pub fn ExpEffect::store() -> ExpEffect {
  ExpEffect::new(stores_value=true)
}

///|
pub fn ExpEffect::raise_() -> ExpEffect {
  ExpEffect::new(raises_value=true)
}

///|
pub fn ExpEffect::join(self : ExpEffect, other : ExpEffect) -> ExpEffect {
  ExpEffect::new(
    reads_value=self.reads_value || other.reads_value,
    loads_value=self.loads_value || other.loads_value,
    stores_value=self.stores_value || other.stores_value,
    raises_value=self.raises_value || other.raises_value,
  )
}

///|
pub fn ExpEffect::of_list(effects : Array[ExpEffect]) -> ExpEffect {
  let mut result = ExpEffect::none()
  for effect in effects {
    result = result.join(effect)
  }
  result
}

///|
pub fn ExpEffect::reads(self : ExpEffect) -> Bool {
  self.reads_value
}

///|
pub fn ExpEffect::loads(self : ExpEffect) -> Bool {
  self.loads_value
}

///|
pub fn ExpEffect::stores(self : ExpEffect) -> Bool {
  self.stores_value
}

///|
pub fn ExpEffect::raises(self : ExpEffect) -> Bool {
  self.raises_value
}

///|
pub fn ExpEffect::has_effects(self : ExpEffect) -> Bool {
  self.raises_value || self.stores_value
}

///|
pub fn ExpEffect::has_coeffects(self : ExpEffect) -> Bool {
  self.reads_value || self.loads_value
}

///|
pub fn ExpEffect::idempotent(self : ExpEffect) -> Bool {
  !self.reads_value &&
  !self.loads_value &&
  !self.stores_value &&
  !self.raises_value
}

///|
let empty_bits = 0

///|
let maybe_bits = 1

///|
let exists_bits = 2

///|
let forall_bits = 3

///|
fn Word::is_all_ones(self : Word) -> Bool {
  self.lnot().is_zero()
}

///|
fn narrow_nonzero_bits(bits : Int32) -> Int32 {
  if bits == exists_bits {
    maybe_bits
  } else {
    bits
  }
}

///|
fn join_nonzero_bits(lhs : Int32, rhs : Int32) -> Int32 {
  if lhs == forall_bits || rhs == forall_bits {
    forall_bits
  } else if lhs == exists_bits || rhs == exists_bits {
    exists_bits
  } else if lhs == maybe_bits || rhs == maybe_bits {
    maybe_bits
  } else {
    empty_bits
  }
}

///|
fn ite_nonzero_bits(yes : Int32, no : Int32) -> Int32 {
  if (yes == exists_bits && no == forall_bits) ||
    (yes == forall_bits && no == exists_bits) {
    exists_bits
  } else if yes == no {
    yes
  } else {
    maybe_bits
  }
}

///|
fn Exp::nonzero_bits(self : Exp) -> Int32 {
  match self {
    Var(_) | Unknown(_) | Load(_) | Store(_) | Let(_) => maybe_bits
    Int(word) =>
      if word.is_zero() {
        empty_bits
      } else if word.is_all_ones() {
        forall_bits
      } else {
        exists_bits
      }
    Cast(kind=High | Low, ..) => maybe_bits
    Cast(exp~, ..) => narrow_nonzero_bits(exp.nonzero_bits())
    Extract(_) | Concat(_) => maybe_bits
    BinOp(Or, lhs, rhs) =>
      join_nonzero_bits(lhs.nonzero_bits(), rhs.nonzero_bits())
    BinOp(_) => maybe_bits
    UnOp(Neg, exp) => {
      let bits = exp.nonzero_bits()
      if bits == forall_bits {
        exists_bits
      } else {
        bits
      }
    }
    UnOp(Not, exp) => {
      let bits = exp.nonzero_bits()
      if bits == forall_bits {
        empty_bits
      } else if bits == empty_bits {
        forall_bits
      } else {
        bits
      }
    }
    Ite(yes~, no~, ..) =>
      ite_nonzero_bits(yes.nonzero_bits(), no.nonzero_bits())
  }
}

///|
fn division_effect(divisor : Exp) -> ExpEffect {
  let bits = divisor.nonzero_bits()
  if bits == empty_bits || bits == maybe_bits {
    ExpEffect::raise_()
  } else {
    ExpEffect::none()
  }
}

///|
pub fn ExpEffect::compute(exp : Exp) -> ExpEffect {
  exp.effect()
}

///|
pub fn Exp::effect(self : Exp) -> ExpEffect {
  match self {
    Var(_) => ExpEffect::read()
    Int(_) | Unknown(_) => ExpEffect::none()
    Load(mem~, addr~, ..) =>
      ExpEffect::of_list([
        ExpEffect::raise_(),
        ExpEffect::load(),
        mem.effect(),
        addr.effect(),
      ])
    Store(mem~, addr~, value~, ..) =>
      ExpEffect::of_list([
        ExpEffect::raise_(),
        ExpEffect::store(),
        mem.effect(),
        addr.effect(),
        value.effect(),
      ])
    BinOp(Div | SignedDiv | Mod | SignedMod, lhs, rhs) =>
      ExpEffect::of_list([division_effect(rhs), lhs.effect(), rhs.effect()])
    BinOp(_, lhs, rhs) => lhs.effect().join(rhs.effect())
    Extract(exp~, ..) => exp.effect()
    Concat(high~, low~) => high.effect().join(low.effect())
    Ite(cond~, yes~, no~) =>
      ExpEffect::of_list([cond.effect(), yes.effect(), no.effect()])
    UnOp(_, exp) | Cast(exp~, ..) => exp.effect()
    Let(_, value, body) => value.effect().join(body.effect())
  }
}
