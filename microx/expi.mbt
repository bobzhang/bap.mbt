// Expression interpreter over BAP results (a port of `Bap_expi`).
//
// Upstream `expi` is an open-recursive OCaml class that lives in a state
// monad.  Here the state is the persistent `ExpContext` and the
// overridable methods that matter for microexecution (the hooks invoked
// when a value is unknown) are closures stored in `Expi`.

///|
using @types {
  type BilContext,
  type BilResult,
  type BilResultId,
  type BilResultStorage,
  type Exp,
  type Var,
  type ValueType,
  type Word,
}

///|
/// Expression evaluation context (upstream `Bap_expi.context`): the
/// variable bindings plus the generator of fresh result identifiers.
///
/// The context is persistent; every operation returns an updated copy.
pub struct ExpContext {
  priv vars : BilContext
  priv id : BilResultId
} derive(Eq, Debug)

///|
pub extend ExpContext with Eq::{not_equal, equal}

///|
pub extend ExpContext with Debug::{to_repr}

///|
/// Creates an empty context. The first created result gets the identifier
/// `succ zero`, as upstream.
pub fn ExpContext::new() -> ExpContext {
  { vars: BilContext::new(), id: BilResultId::zero().succ(), }
}

///|
/// [ctxt.lookup(v)] is the result bound to [v], if any.
pub fn ExpContext::lookup(self : ExpContext, variable : Var) -> BilResult? {
  self.vars.lookup(variable)
}

///|
/// [ctxt.update(v, r)] binds [v] to [r].
pub fn ExpContext::update(
  self : ExpContext,
  variable : Var,
  result : BilResult,
) -> ExpContext {
  { ..self, vars: self.vars.update(variable, result), }
}

///|
/// All bindings, sorted by variable name.
pub fn ExpContext::bindings(self : ExpContext) -> Array[(Var, BilResult)] {
  self.vars.bindings()
}

///|
/// The identifier that the next created result will receive.
pub fn ExpContext::next_id(self : ExpContext) -> BilResultId {
  self.id
}

///|
/// Creates a fresh undefined (bottom) result.
pub fn ExpContext::create_undefined(
  self : ExpContext,
) -> (ExpContext, BilResult) {
  ({ ..self, id: self.id.succ(), }, BilResult::undefined(self.id))
}

///|
/// Creates a fresh immediate result.
pub fn ExpContext::create_word(
  self : ExpContext,
  word : Word,
) -> (ExpContext, BilResult) {
  ({ ..self, id: self.id.succ(), }, BilResult::word(word, self.id))
}

///|
/// Creates a fresh storage result.
pub fn ExpContext::create_storage(
  self : ExpContext,
  storage : BilResultStorage,
) -> (ExpContext, BilResult) {
  ({ ..self, id: self.id.succ(), }, BilResult::storage(storage, self.id))
}

///|
/// Creates a fresh result holding the given value.
pub fn ExpContext::create_value(
  self : ExpContext,
  value : @types.BilResultValue,
) -> (ExpContext, BilResult) {
  match value {
    BilResultImm(word) => self.create_word(word)
    BilResultMem(storage) => self.create_storage(storage)
    BilResultBot => self.create_undefined()
  }
}

///|
/// An expression interpreter (upstream `Expi.t`).
///
/// The plain interpreter (`Expi::new()` without hooks) yields a bottom
/// result for every unknown value: unbound variables, uninitialized memory
/// cells and `Unknown` expressions. Hooks replace the bottom value:
///
/// - `lookup` is called when a variable is unbound or bound to bottom;
/// - `load` is called when a memory cell at the given address is unknown;
/// - `unknown` is called for `Unknown(name, typ)` expressions.
///
/// Each hook returns the value that a fresh result is created from.
pub struct Expi {
  priv lookup_hook : ((Var) -> @types.BilResultValue)?
  priv load_hook : ((Word) -> @types.BilResultValue)?
  priv unknown_hook : ((String, ValueType) -> @types.BilResultValue)?
}

///|
/// Creates an expression interpreter with the given unknown-value hooks.
pub fn Expi::new(
  lookup? : (Var) -> @types.BilResultValue,
  load? : (Word) -> @types.BilResultValue,
  unknown? : (String, ValueType) -> @types.BilResultValue,
) -> Expi {
  { lookup_hook: lookup, load_hook: load, unknown_hook: unknown, }
}

///|
/// The empty storage used for memories that are unknown (a linear
/// storage, as upstream).
pub fn Expi::empty(_self : Expi) -> BilResultStorage {
  BilResultStorage::linear()
}

///|
priv struct ExpRun {
  expi : Expi
  mut ctxt : ExpContext
}

///|
fn ExpRun::create(self : ExpRun, value : @types.BilResultValue) -> BilResult {
  let (ctxt, result) = self.ctxt.create_value(value)
  self.ctxt = ctxt
  result
}

///|
fn ExpRun::bot(self : ExpRun) -> BilResult {
  self.create(BilResultBot)
}

///|
fn ExpRun::word(self : ExpRun, word : Word) -> BilResult {
  self.create(BilResultImm(word))
}

///|
fn ExpRun::lookup(self : ExpRun, variable : Var) -> BilResult {
  let result = match self.ctxt.lookup(variable) {
    Some(result) => result
    None => self.bot()
  }
  match (result.value(), self.expi.lookup_hook) {
    (BilResultBot, Some(hook)) => self.create(hook(variable))
    _ => result
  }
}

///|
fn ExpRun::update(self : ExpRun, variable : Var, result : BilResult) -> Unit {
  self.ctxt = self.ctxt.update(variable, result)
}

///|
fn ExpRun::load(
  self : ExpRun,
  storage : BilResultStorage,
  addr : Word,
) -> BilResult {
  let result = match storage.load(addr) {
    Some(word) => self.word(word)
    None => self.bot()
  }
  match (result.value(), self.expi.load_hook) {
    (BilResultBot, Some(hook)) => self.create(hook(addr))
    _ => result
  }
}

///|
fn ExpRun::imm(self : ExpRun, exp : Exp) -> Word? {
  match self.eval(exp).value() {
    BilResultImm(word) => Some(word)
    _ => None
  }
}

///|
fn ExpRun::mem(self : ExpRun, exp : Exp) -> BilResultStorage? {
  match self.eval(exp).value() {
    BilResultMem(storage) => Some(storage)
    BilResultBot => Some(self.expi.empty())
    BilResultImm(_) => None
  }
}

///|
fn value_size(mem : Exp) -> Int? {
  match mem.infer_type() {
    Ok(Mem(value_width~, ..)) => Some(value_width)
    _ => None
  }
}

///|
fn is_bit(word : Word, value : Bool) -> Bool {
  word.bitwidth() == 1 && (if value { word.is_one() } else { word.is_zero() })
}

///|
fn ExpRun::eval(self : ExpRun, exp : Exp) -> BilResult {
  match exp {
    Int(word) => self.word(word)
    Var(variable) => self.lookup(variable)
    Unknown(name, typ) =>
      match self.expi.unknown_hook {
        Some(hook) => self.create(hook(name, typ))
        None => self.bot()
      }
    Load(mem~, addr~, typ~, ..) =>
      match (value_size(mem), typ) {
        (Some(vs), Imm(sz)) if vs == sz =>
          match self.mem(mem) {
            None => self.bot()
            Some(storage) =>
              match self.imm(addr) {
                None => self.bot()
                Some(addr) => self.load(storage, addr)
              }
          }
        _ => self.bot()
      }
    Store(mem~, addr~, value~, ..) =>
      match (value_size(mem), value.infer_type()) {
        (Some(vs), Ok(Imm(sz))) if vs == sz =>
          match self.mem(mem) {
            None => self.bot()
            Some(storage) =>
              match self.imm(addr) {
                None => self.bot()
                Some(addr) =>
                  match self.imm(value) {
                    None => self.bot()
                    Some(word) =>
                      self.create(BilResultMem(storage.save(addr, word)))
                  }
              }
          }
        _ => self.bot()
      }
    Let(variable, value, body) => {
      let bound = self.eval(value)
      let saved = self.lookup(variable)
      self.update(variable, bound)
      let result = self.eval(body)
      self.update(variable, saved)
      result
    }
    Cast(kind~, width~, exp~) =>
      match self.imm(exp) {
        None => self.bot()
        Some(word) =>
          match kind.apply(width, word) {
            Ok(word) => self.word(word)
            Err(_) => self.bot()
          }
      }
    Extract(hi~, lo~, exp~) =>
      match self.imm(exp) {
        None => self.bot()
        Some(word) =>
          try word.extract(hi~, lo~) catch {
            _ => self.bot()
          } noraise {
            word => self.word(word)
          }
      }
    Concat(high~, low~) => {
      let high = self.imm(high)
      let low = self.imm(low)
      match (high, low) {
        (Some(high), Some(low)) =>
          try high.concat(low) catch {
            _ => self.bot()
          } noraise {
            word => self.word(word)
          }
        _ => self.bot()
      }
    }
    UnOp(op, exp) =>
      match self.imm(exp) {
        None => self.bot()
        Some(word) =>
          match op.apply(word) {
            Ok(word) => self.word(word)
            Err(_) => self.bot()
          }
      }
    BinOp(op, lhs, rhs) =>
      match self.imm(lhs) {
        None => self.bot()
        Some(lhs) =>
          match self.imm(rhs) {
            None => self.bot()
            Some(rhs) =>
              match op.apply(lhs, rhs) {
                Ok(word) => self.word(word)
                Err(_) => self.bot()
              }
          }
      }
    Ite(cond~, yes~, no~) =>
      match self.imm(cond) {
        Some(word) if is_bit(word, true) => self.eval(yes)
        Some(word) if is_bit(word, false) => self.eval(no)
        _ => self.bot()
      }
  }
}

///|
/// [expi.eval_exp(ctxt, exp)] evaluates [exp] in [ctxt].
///
/// As upstream, the expression is normalized (memory accesses are split
/// into byte-sized cells) and simplified before the evaluation. Type
/// errors, invalid casts, and division by zero evaluate to bottom
/// (upstream the latter escapes as an OCaml exception).
pub fn Expi::eval_exp(
  self : Expi,
  ctxt : ExpContext,
  exp : Exp,
) -> (ExpContext, BilResult) {
  let run = { expi: self, ctxt, }
  let result = run.eval(exp.normalize().simplify())
  (run.ctxt, result)
}

///|
/// [expi.lookup(ctxt, v)] evaluates the variable [v].
pub fn Expi::lookup(
  self : Expi,
  ctxt : ExpContext,
  variable : Var,
) -> (ExpContext, BilResult) {
  let run = { expi: self, ctxt, }
  let result = run.lookup(variable)
  (run.ctxt, result)
}

///|
/// [expi.load(ctxt, storage, addr)] loads a cell from [storage].
pub fn Expi::load(
  self : Expi,
  ctxt : ExpContext,
  storage : BilResultStorage,
  addr : Word,
) -> (ExpContext, BilResult) {
  let run = { expi: self, ctxt, }
  let result = run.load(storage, addr)
  (run.ctxt, result)
}

///|
/// [expi.store(ctxt, storage, addr, word)] stores [word] into [storage].
pub fn Expi::store(
  _self : Expi,
  ctxt : ExpContext,
  storage : BilResultStorage,
  addr : Word,
  word : Word,
) -> (ExpContext, BilResult) {
  ctxt.create_storage(storage.save(addr, word))
}

///|
/// [eval(exp)] evaluates [exp] with the plain interpreter in an empty
/// context (upstream `Expi.eval`).
pub fn eval(exp : Exp) -> @types.BilResultValue {
  Expi::new().eval_exp(ExpContext::new(), exp).1.value()
}
