///|
/// `!!x`: the term that evaluates to the value `x`.
pub fn pure_const(value : Value) -> Pure {
  _ => value
}

///|
/// `!!x`: the effectful term that evaluates to the effect `x`.
pub fn eff_const(effect : Effect) -> Eff {
  _ => effect
}

///|
/// Evaluates the term `x` in the knowledge base `state`.
pub fn eval_pure(x : Pure, state : @knowledge.State) -> Value raise {
  x(state)
}

///|
/// Evaluates the effectful term `x` in the knowledge base `state`.
pub fn eval_eff(x : Eff, state : @knowledge.State) -> Effect raise {
  x(state)
}

///|
/// The sort of memory values (the top sort if `sort` is not a memory).
fn sort_mem_values(sort : Sort) -> Sort {
  match sort.mem_values() {
    Some(values) => values
    None => Sort::top()
  }
}

///|
/// The sort of the bitvector representation of floats (the top sort if
/// `sort` is not a float).
fn sort_float_bits(sort : Sort) -> Sort {
  match sort.float_bits() {
    Some(bits) => bits
    None => Sort::top()
  }
}

///|
/// The size of a bitvector sort (booleans are one bit wide, other sorts
/// have size zero).
fn sort_size(sort : Sort) -> Int {
  match sort.bitv_size() {
    Some(size) => size
    None => if sort == Sort::bool() { 1 } else { 0 }
  }
}

///|
/// The depth of `Var::scoped_pure` scopes (upstream the `pure` context
/// variable of `bap_core_theory_var.ml`).
let scoped_pure_depth : @knowledge.Var[Int] = @knowledge.Var::new(
  "scoped-var-depth",
  _ => 0,
  pkg="core",
  inspect=depth => depth.to_string(),
)

///|
/// `Var.scoped s f`: applies `f` to a fresh immutable variable of sort `s`
/// that is unique in the scope of the evaluation of the term built by
/// `f`, so that nested scoped variables never clash (the name of the
/// variable is `$<depth>`, as upstream).
pub fn Var::scoped_pure(sort : Sort, f : (Var) -> Pure) -> Pure {
  state => {
    let depth = scoped_pure_depth.get(state)
    let variable : Var = {
      sort_value: sort,
      ident_value: "$\{depth}",
      version_value: 0,
      mutable_flag: false,
      virtual_flag: true,
    }
    scoped_pure_depth.set(state, depth + 1)
    defer scoped_pure_depth.set(state, depth)
    f(variable)(state)
  }
}

///|
/// `int s (n mod 2^size s)`: the bitvector constant `n` of sort `s` (a
/// negative `n` is taken in two's complement). A convenience for
/// `Core::int` that defers the construction of the bitvector to the
/// evaluation of the term.
pub fn Core::of_int(self : Core, sort : Sort, n : Int) -> Pure {
  state => self.int(sort, bitvec_of_int(sort_size(sort), n))(state)
}
