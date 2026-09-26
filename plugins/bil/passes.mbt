///|
/// # The BIL plugin (upstream `plugins/bil`)
///
/// The BIL transformation pipeline: normalization and optimization passes
/// registered in the `@types` BIL pass registry, the selection of the
/// pipeline from the normalization and optimization levels and the
/// user-selected passes, and its application (to a fixed point) to the
/// output of the BIL lifters.

///|
let log : @main_event.MainLogReporter = @main_event.MainLogReporter::create(
  section="bil",
)

///|
fn register_norm(
  name : String,
  desc : String,
  normalize_exp : Bool,
) -> @types.BilPass {
  @types.register_pass(name, desc~, bil => @types.normalize(bil, normalize_exp~))
}

///|
/// Transforms BIL to the first normalized form (`bnf1`).
pub let bnf1 : @types.BilPass = register_norm(
  "bnf1", "Transforms BIL to the first normalized form", false,
)

///|
/// Transforms BIL to the second normalized form (`bnf2`).
pub let bnf2 : @types.BilPass = register_norm(
  "bnf2", "Transforms BIL to the second normalized form", true,
)

///|
/// Constant folding (`constant-folding`).
pub let fold_consts : @types.BilPass = @types.register_pass(
  "constant-folding",
  desc="constant-folding",
  @types.fold_consts,
)

///|
/// Constant propagation (`constant-propagation`).
pub let consts_propagation : @types.BilPass = @types.register_pass(
  "constant-propagation",
  desc="constant-propagation",
  @types.propagate_consts,
)

///|
/// Dead code elimination for virtual variables (`prune-dead-virtuals`).
pub let prune_dead : @types.BilPass = @types.register_pass(
  "prune-dead-virtuals",
  desc="dead code elimination for virtual variables",
  @types.prune_dead_virtuals,
)

///|
/// The passes of the optimization level 1.
pub fn o1() -> Array[@types.BilPass] {
  [fold_consts, consts_propagation, prune_dead]
}

///|
/// The normalization levels (`--bil-normalization`).
pub fn normalizations() -> Array[(String, Array[@types.BilPass])] {
  [("0", []), ("1", [bnf1]), ("2", [bnf2])]
}

///|
/// The optimization levels (`--bil-optimization`), level 1 by default.
pub fn optimizations() -> Array[(String, Array[@types.BilPass])] {
  [("0", []), ("1", o1())]
}

///|
fn find_level(
  levels : Array[(String, Array[@types.BilPass])],
  level : String,
) -> Array[@types.BilPass]? {
  for l in levels {
    if l.0 == level {
      return Some(l.1)
    }
  }
  None
}

///|
/// The pipeline: all normalization passes of the level, then all
/// optimization passes of the level, then the selected passes (looked up
/// by name). Fails on unknown levels or pass names.
pub fn pipeline(
  normalization? : String = "0",
  optimization? : String = "1",
  passes? : ArrayView[String] = [],
) -> Result[Array[@types.BilPass], String] {
  let norm = match find_level(normalizations(), normalization) {
    Some(ps) => ps
    None => return Err("unknown normalization level \{normalization}")
  }
  let optim = match find_level(optimizations(), optimization) {
    Some(ps) => ps
    None => return Err("unknown optimization level \{optimization}")
  }
  let selected = []
  for name in passes {
    match @types.passes().search_by(p => p.name() == name) {
      Some(i) => selected.push(@types.passes()[i])
      None => return Err("unknown BIL pass \{name}")
    }
  }
  Ok(norm + optim + selected)
}

///|
/// Selects the pipeline (upstream `Bil.select_passes`).
pub fn select(
  normalization? : String = "0",
  optimization? : String = "1",
  passes? : ArrayView[String] = [],
) -> Result[Unit, String] {
  match pipeline(normalization~, optimization~, passes~) {
    Ok(ps) => {
      @types.select_passes(ps)
      Ok(())
    }
    Err(e) => Err(e)
  }
}

///|
/// The lines of `--bil-list-passes`: every registered pass (name and
/// description), in the alphabetical order.
pub fn list_passes() -> Array[String] {
  let lines = @types.passes().map(p => p.to_string())
  lines.sort()
  lines
}

///|
/// Applies the selected passes (upstream `apply_passes` of the lifters
/// factory): the code is type checked, the passes are applied in order
/// until a fixed point is reached, and the result is type checked again.
pub fn apply_passes(
  bil : Array[@types.Stmt],
) -> Result[Array[@types.Stmt], String] {
  let check = (bil : Array[@types.Stmt]) => {
    match @types.check_stmt_types(bil) {
      Ok(_) => Ok(bil)
      Err(e) => Err("The lifted code is not well-typed: \{e.to_string()}")
    }
  }
  match check(bil) {
    Err(e) => Err(e)
    Ok(bil) => {
      let passes = @types.selected_passes()
      check(
        @types.fixpoint(bil, bil => passes.fold(init=bil, (bil, f) => f(bil))),
      )
    }
  }
}
