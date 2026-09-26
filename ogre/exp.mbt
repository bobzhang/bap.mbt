// The query expression language (upstream `Exp`).

///|
/// How a query variable designates an attribute of the selection: by name
/// (`attr[field]`, upstream `attr.(field)`) or by position in the `from`
/// clause (`field.at(n)`, upstream `field.[n]`).
priv enum Name {
  ByName(String)
  ByPos(Int)
} derive(Debug)

///|
/// A variable: a field of some attribute of the selection.
priv struct Column[A] {
  attr : A
  field : Header
} derive(Debug)

///|
priv enum Bop {
  And
  Or
  Lt
  EqOp
  Add
  Sub
} derive(Debug)

///|
priv enum Term[V] {
  True
  Int(Int64)
  Str(String)
  Flt(Double)
  Var(V)
  Bop(Bop, Term[V], Term[V])
  Not(Term[V])
} derive(Debug)

///|
/// A query expression (upstream `Query.exp`).
///
/// Expressions are built from constants ([Exp::str], [Exp::int],
/// [Exp::bool], [Exp::float]), field variables (`attr[field]` and
/// `field.at(n)`) and the logical, comparison and arithmetic combinators
/// below. Every combinator simplifies its result like upstream does.
struct Exp {
  term : Term[Column[Name]]
}

///|
pub impl Debug for Exp with fn to_repr(self) {
  Repr(self.term)
}

///|
fn[V] Term::bool(b : Bool) -> Term[V] {
  if b {
    True
  } else {
    Not(True)
  }
}

///|
/// OCaml polymorphic comparison of floats: `nan` equals itself and is
/// smaller than every other float.
fn float_compare(x : Double, y : Double) -> Int {
  match (x.is_nan(), y.is_nan()) {
    (true, true) => 0
    (true, false) => -1
    (false, true) => 1
    (false, false) => if x < y { -1 } else if x > y { 1 } else { 0 }
  }
}

///|
fn[V] is_zero_const(t : Term[V]) -> Bool {
  match t {
    Int(0L) => true
    Flt(x) => x == 0.0
    _ => false
  }
}

///|
/// Preserves NNF, pushes disjuncts inwards and short-circuits expressions
/// (upstream `Exp.simpl`; the clauses are tried in the same order).
fn[V] simpl(e : Term[V]) -> Term[V] {
  match e {
    Bop(And, Not(True), _) | Bop(And, _, Not(True)) => Not(True)
    Bop(And, True, e) | Bop(And, e, True) => simpl(e)
    Bop(Or, Not(True), e) | Bop(Or, e, Not(True)) => simpl(e)
    Bop(Or, True, _) | Bop(Or, _, True) => True
    Bop(Lt, Int(x), Int(y)) => Term::bool(x < y)
    Bop(Lt, Str(x), Str(y)) => Term::bool(string_compare(x, y) < 0)
    Bop(Lt, Flt(x), Flt(y)) => Term::bool(float_compare(x, y) < 0)
    Bop(EqOp, Int(x), Int(y)) => Term::bool(x == y)
    Bop(EqOp, Str(x), Str(y)) => Term::bool(x == y)
    Bop(EqOp, Flt(x), Flt(y)) => Term::bool(float_compare(x, y) == 0)
    Bop(Add, z, x) if is_zero_const(z) => simpl(x)
    Bop(Add, x, z) if is_zero_const(z) => simpl(x)
    Bop(Sub, x, z) if is_zero_const(z) => simpl(x)
    Bop(Add, Int(x), Int(y)) => Int(x + y)
    Bop(Sub, Int(x), Int(y)) => Int(x - y)
    Bop(Add, Flt(x), Flt(y)) => Flt(x + y)
    Bop(Sub, Flt(x), Flt(y)) => Flt(x - y)
    Not(Not(x)) => simpl(x)
    Not(Bop(Or, x, y)) => simpl(Bop(And, Not(x), Not(y)))
    Not(Bop(And, x, y)) => simpl(Bop(Or, Not(x), Not(y)))
    Bop(Or, Bop(And, x, y), z) | Bop(Or, z, Bop(And, x, y)) =>
      simpl(Bop(And, Bop(Or, z, x), Bop(Or, z, y)))
    Not(e) => Not(simpl(e))
    Bop(op, x, y) => Bop(op, simpl(x), simpl(y))
    e => e
  }
}

///|
fn[V] conj(x : Term[V], y : Term[V]) -> Term[V] {
  simpl(Bop(And, x, y))
}

///|
fn[V] equal(x : Term[V], y : Term[V]) -> Term[V] {
  simpl(Bop(EqOp, x, y))
}

///|
/// A string constant (upstream `str`).
pub fn Exp::str(value : String) -> Exp {
  { term: Str(value), }
}

///|
/// An integer constant (upstream `int`).
pub fn Exp::int(value : Int64) -> Exp {
  { term: Int(value), }
}

///|
/// A logic constant (upstream `bool`).
pub fn Exp::bool(value : Bool) -> Exp {
  { term: Term::bool(value), }
}

///|
/// A real number constant (upstream `float`).
pub fn Exp::float(value : Double) -> Exp {
  { term: Flt(value), }
}

///|
/// Conjunction (upstream `&&`).
pub fn Exp::conj(self : Exp, other : Exp) -> Exp {
  { term: conj(self.term, other.term), }
}

///|
/// Disjunction (upstream `||`).
pub fn Exp::disj(self : Exp, other : Exp) -> Exp {
  { term: simpl(Bop(Or, self.term, other.term)), }
}

///|
/// Implication (upstream `==>`).
pub fn Exp::implies(self : Exp, other : Exp) -> Exp {
  { term: simpl(Bop(Or, Not(self.term), other.term)), }
}

///|
/// Logical negation (upstream `not`).
pub fn Exp::negate(self : Exp) -> Exp {
  { term: simpl(Not(self.term)), }
}

///|
/// Less than (upstream `<`).
pub fn Exp::lt(self : Exp, other : Exp) -> Exp {
  { term: simpl(Bop(Lt, self.term, other.term)), }
}

///|
/// Greater than (upstream `>`), defined as `other < self`.
pub fn Exp::gt(self : Exp, other : Exp) -> Exp {
  other.lt(self)
}

///|
/// Less than or equal (upstream `<=`), defined as `not (other < self)`.
pub fn Exp::le(self : Exp, other : Exp) -> Exp {
  other.lt(self).negate()
}

///|
/// Greater than or equal (upstream `>=`), defined as `not (other > self)`.
pub fn Exp::ge(self : Exp, other : Exp) -> Exp {
  other.gt(self).negate()
}

///|
/// Equality (upstream `=`).
pub fn Exp::eq(self : Exp, other : Exp) -> Exp {
  { term: equal(self.term, other.term), }
}

///|
/// Non-equality (upstream `<>`).
pub fn Exp::ne(self : Exp, other : Exp) -> Exp {
  self.eq(other).negate()
}

///|
/// Summation (upstream `+`); also available as the `+` operator.
pub fn Exp::add(self : Exp, other : Exp) -> Exp {
  { term: simpl(Bop(Add, self.term, other.term)), }
}

///|
/// Subtraction (upstream `-`); also available as the `-` operator.
pub fn Exp::sub(self : Exp, other : Exp) -> Exp {
  { term: simpl(Bop(Sub, self.term, other.term)), }
}

///|
pub impl Add for Exp with fn add(self, other) {
  Exp::add(self, other)
}

///|
pub impl Sub for Exp with fn sub(self, other) {
  Exp::sub(self, other)
}

///|
/// `attr[field]` (upstream `attr.(field)`): a variable ranging over the
/// values of `field` of the attribute `attr` in the selection.
#alias("_[_]")
pub fn[A, K, T] Attribute::get(self : Attribute[A, K], field : Field[T]) -> Exp {
  { term: Var({ attr: ByName(self.name), field: field.header(), }), }
}

///|
/// `field.at(n)` (upstream `field.[n]`): a variable ranging over the values
/// of `field` of the `n`-th attribute of the selection (counting from 0).
pub fn[T] Field::at(self : Field[T], n : Int) -> Exp {
  { term: Var({ attr: ByPos(n), field: self.header(), }), }
}

///|
pub extend Exp with Debug::{to_repr}
