///|
/// A jump destination label (upstream `Theory.Label` objects created by
/// the BIL parser with `for_addr`, `for_name` and `for_ivec`, or any
/// other program label).
pub(all) enum Dst {
  /// the label of the instruction at the address
  Addr(@types.Word)
  /// the label of a named subroutine (a `call` special)
  Name(String)
  /// the label of an interrupt vector (a `cpuexn`)
  Ivec(Int32)
  /// a program label (term identifier)
  Label(@types.Tid)
} derive(Eq, Debug)

///|
pub extend Dst with Eq::{not_equal, equal}

///|
pub extend Dst with Debug::{to_repr}

///|
/// The term identifier of the label.
pub fn Dst::tid(self : Dst) -> @types.Tid {
  match self {
    Addr(w) => @types.Tid::for_addr(w)
    Name(n) => @types.Tid::for_name(n)
    Ivec(n) => @types.Tid::for_ivec(n)
    Label(t) => t
  }
}

///|
/// The effect part of the Core Theory (the operations that denote
/// statements), the interface through which BIL programs are reflected
/// into other representations (upstream `Theory.Parser.Make` over
/// `Theory.Core`, restricted to effects). The pure values stay BIL
/// expressions: the Core Theory algebra of values lives in
/// `core_theory`.
pub struct EffAlgebra[E] {
  /// the empty effect (`pass`, `skip`, `perform`)
  empty : E
  /// `set var exp`: a data effect
  set : (@types.Var, @types.Exp) -> E
  /// `repeat cond body`: a loop
  repeat : (@types.Exp, E) -> E
  /// `branch cond yes nay`
  branch : (@types.Exp, E, E) -> E
  /// `jmp exp`: an indirect jump
  jmp : (@types.Exp) -> E
  /// `goto label`: a direct jump; `call` marks subroutine labels
  goto : (Dst, Bool) -> E
  /// `seq x y`
  seq : (E, E) -> E
  /// `blk label data ctrl`: a (possibly labeled) block
  blk : (@types.Tid?, E, E) -> E
}

///|
/// A BIL program that can't be reflected.
pub(all) suberror ReflectError {
  ReflectError(String)
} derive(Eq, Debug)

///|
pub extend ReflectError with Eq::{not_equal, equal}

///|
pub extend ReflectError with Debug::{to_repr}

///|
pub impl Show for ReflectError with fn output(self, logger) {
  match self {
    ReflectError(msg) => logger.write_string(msg)
  }
}

///|
pub extend ReflectError with Show::{output, to_string}

///|
/// Reflects a BIL program in the algebra (upstream `Theory.Parser.run`
/// with the BIL grammar `Bil.Theory.parser`): every statement becomes a
/// block that is sequenced with the rest of the program; `call` and
/// `intrinsic` specials become gotos to subroutine labels, jumps to
/// constants become gotos to address labels, `cpuexn` becomes a goto to an
/// interrupt vector, other specials are ignored, loops are data effects
/// (their bodies can't transfer control).
pub fn[E] reflect(
  alg : EffAlgebra[E],
  bil : ArrayView[@types.Stmt],
) -> E raise ReflectError {
  let null : @types.Tid? = None
  let blk = (data : E, ctrl : E) => (alg.blk)(null, data, ctrl)
  match bil {
    [] => blk(alg.empty, alg.empty)
    [x, .. xs] => {
      let next = () => reflect(alg, xs)
      let call = (name : String) => {
        (alg.seq)(blk(alg.empty, (alg.goto)(Name(name), true)), next())
      }
      match @types.Stmt::decode(@types.Stmt::call(), x) {
        Some(dst) => return call(dst)
        None => ()
      }
      match @types.Stmt::decode(@types.Stmt::intrinsic(), x) {
        Some(data) => return call("intrinsic:" + data)
        None => ()
      }
      match x {
        Move(v, e) => (alg.seq)(blk((alg.set)(v, e), alg.empty), next())
        Jmp(Int(w)) =>
          (alg.seq)(blk(alg.empty, (alg.goto)(Addr(w), false)), next())
        Jmp(e) => (alg.seq)(blk(alg.empty, (alg.jmp)(e)), next())
        Special(_) => (alg.seq)(blk(alg.empty, alg.empty), next())
        While(cond~, body~) =>
          (alg.seq)(
            blk((alg.repeat)(cond, reflect_data(alg, body)), alg.empty),
            next(),
          )
        If(cond~, yes~, no~) =>
          (alg.seq)(
            (alg.branch)(cond, reflect(alg, yes), reflect(alg, no)),
            next(),
          )
        CpuExn(n) =>
          (alg.seq)(blk(alg.empty, (alg.goto)(Ivec(n), false)), next())
      }
    }
  }
}

///|
/// Reflects a BIL program that has only data effects (upstream
/// `Theory.Parser.stmtd`, used for loop bodies).
pub fn[E] reflect_data(
  alg : EffAlgebra[E],
  bil : ArrayView[@types.Stmt],
) -> E raise ReflectError {
  match bil {
    [] => alg.empty
    [x, .. xs] => {
      if @types.Stmt::decode(@types.Stmt::call(), x) is Some(_) ||
        @types.Stmt::decode(@types.Stmt::intrinsic(), x) is Some(_) {
        raise ReflectError("a call in a data context")
      }
      match x {
        Move(v, e) => (alg.seq)((alg.set)(v, e), reflect_data(alg, xs))
        Special(_) => (alg.seq)(alg.empty, reflect_data(alg, xs))
        While(cond~, body~) =>
          (alg.seq)(
            (alg.repeat)(cond, reflect_data(alg, body)),
            reflect_data(alg, xs),
          )
        If(cond~, yes~, no~) =>
          (alg.seq)(
            (alg.branch)(cond, reflect_data(alg, yes), reflect_data(alg, no)),
            reflect_data(alg, xs),
          )
        Jmp(_) | CpuExn(_) =>
          raise ReflectError("a control transfer in a data context")
      }
    }
  }
}

///|
/// The BIL denotation of the effects (the effect part of upstream
/// `Bil_semantics.Core`): statements are sequences of BIL statements;
/// gotos to address labels are jumps to constants, to interrupt vectors
/// are `cpuexn`, to named labels are `call` specials, and to other labels
/// are `goto` specials; labeled blocks start with a `label` special.
pub fn bil_algebra() -> EffAlgebra[Array[@types.Stmt]] {
  {
    empty: [],
    set: (v, e) => [Move(v, e)],
    repeat: (c, body) => [While(cond=c, body~)],
    branch: (c, yes, no) => {
      if yes.is_empty() && no.is_empty() {
        []
      } else {
        [If(cond=c, yes~, no~)]
      }
    },
    jmp: e => [Jmp(e)],
    goto: (dst, _) => {
      match dst {
        Addr(w) => [Jmp(Int(w))]
        Ivec(n) => [CpuExn(n)]
        Name(n) => [@types.Stmt::encode(@types.Stmt::call(), n)]
        Label(t) => [@types.Stmt::encode(@types.Stmt::goto(), t.to_string())]
      }
    },
    seq: (x, y) => x + y,
    blk: (label, x, y) => {
      match label {
        None => x + y
        Some(t) =>
          [@types.Stmt::encode(@types.Stmt::label(), t.to_string()), ..x, ..y]
      }
    },
  }
}

///|
/// Reflects BIL into BIL through the Core Theory effects (the
/// normalization performed by upstream's BIL lifter when it denotes the
/// lifted BIL with the BIL theory): specials other than calls,
/// intrinsics and interrupts are removed, empty branches are dropped, and
/// `intrinsic` specials become `call`s to `intrinsic:<name>`.
pub fn reflect_bil(
  bil : ArrayView[@types.Stmt],
) -> Array[@types.Stmt] raise ReflectError {
  reflect(bil_algebra(), bil)
}

///|
/// Builds the IR of a BIL program (the `bap:bir` theory applied to the
/// reflected BIL and reified, upstream `Bil_ir`). Delegates to the shared
/// implementation `@types.Blk::of_bil`, which also contracts and orders
/// the blocks as upstream `BIR.normalize`/`BIR.reify` do.
pub fn lift_bir(
  bil : Array[@types.Stmt],
  is_subroutine? : (@types.Tid) -> Bool,
) -> Array[@types.Term[@types.Blk]] {
  @types.Blk::of_bil(bil, is_subroutine?)
}

///|
/// The destinations of the jumps of a program (upstream `jump-dests`
/// theory, `Brancher`): `None` stands for an unknown (indirect)
/// destination.
pub fn brancher_algebra() -> EffAlgebra[Array[Dst?]] {
  let union = (x : Array[Dst?], y : Array[Dst?]) => {
    let out = x.copy()
    for d in y {
      if !out.contains(d) {
        out.push(d)
      }
    }
    out
  }
  {
    empty: [],
    set: (_, _) => [],
    repeat: (_, _) => [],
    branch: (_, x, y) => union(x, y),
    jmp: _ => [None],
    goto: (dst, _) => [Some(dst)],
    seq: union,
    blk: (_, x, y) => union(x, y),
  }
}

///|
/// The jump destinations of a BIL program.
pub fn jump_destinations(
  bil : ArrayView[@types.Stmt],
) -> Array[Dst?] raise ReflectError {
  reflect(brancher_algebra(), bil)
}
