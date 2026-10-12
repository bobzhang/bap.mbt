///|
/// A named lifter (upstream: a `Theory.Semantics` promise guarded by the
/// label's target and encoding). `accepts` decides from the context alone
/// whether the provider applies; `lift` raises `Unsupported` for opcodes it
/// does not model, so that other providers get a chance.
pub struct Provider {
  name : String
  accepts : (Context) -> Bool
  lift : (Context, Insn) -> Lifted raise LiftError
}

///|
pub fn Provider::create(
  name : String,
  accepts~ : (Context) -> Bool,
  lift~ : (Context, Insn) -> Lifted raise LiftError,
) -> Provider {
  { name, accepts, lift, }
}

///|
pub fn Provider::name(self : Provider) -> String {
  self.name
}

///|
pub fn Provider::accepts(self : Provider, ctx : Context) -> Bool {
  (self.accepts)(ctx)
}

///|
/// Lift with this provider only (no validation).
pub fn Provider::lift(
  self : Provider,
  ctx : Context,
  insn : Insn,
) -> Lifted raise LiftError {
  (self.lift)(ctx, insn)
}

///|
/// An ordered collection of lifter providers.
///
/// Providers are tried in the order of their first registration.
/// Registering a provider under an existing name replaces it in place,
/// so registration is idempotent and independent of how many times
/// initialization code runs.
struct Registry {
  providers : Array[Provider]
}

///|
/// A fresh, empty registry.
pub fn Registry::new() -> Registry {
  { providers: [], }
}

///|
let global_registry : Registry = Registry::new()

///|
/// The process-wide registry used by default by the lifter packages'
/// `register` functions and by the `project` package.
pub fn Registry::global() -> Registry {
  global_registry
}

///|
/// Register `provider`. A provider with the same name is replaced at its
/// original position; otherwise `provider` is appended.
pub fn Registry::register(self : Registry, provider : Provider) -> Unit {
  match self.providers.search_by(p => p.name == provider.name) {
    Some(index) => self.providers[index] = provider
    None => self.providers.push(provider)
  }
}

///|
/// Remove the provider named `name`; returns whether one was removed.
pub fn Registry::unregister(self : Registry, name : String) -> Bool {
  match self.providers.search_by(p => p.name == name) {
    Some(index) => {
      self.providers.remove(index) |> ignore
      true
    }
    None => false
  }
}

///|
/// The registered providers, in trial order.
pub fn Registry::providers(self : Registry) -> Array[Provider] {
  self.providers.copy()
}

///|
/// Names of the registered providers, in trial order.
pub fn Registry::names(self : Registry) -> Array[String] {
  self.providers.map(p => p.name)
}

///|
/// The provider registered under `name`.
pub fn Registry::find(self : Registry, name : String) -> Provider? {
  match self.providers.search_by(p => p.name == name) {
    Some(index) => Some(self.providers[index])
    None => None
  }
}

///|
/// Providers accepting `ctx`, in trial order.
pub fn Registry::accepting(self : Registry, ctx : Context) -> Array[Provider] {
  self.providers.filter(p => (p.accepts)(ctx))
}

///|
/// Lift `insn` in `ctx`: providers accepting `ctx` are tried in order and
/// the first result that is not `Unsupported` wins (including other
/// errors). When no provider accepts `ctx`, or all of them raise
/// `Unsupported`, `Unsupported` is raised.
///
/// When `validate` is set (the default) the produced BIL is type-checked
/// and `IllTyped` is raised for ill-typed programs.
pub fn Registry::lift(
  self : Registry,
  ctx : Context,
  insn : Insn,
  validate~ : Bool = true,
) -> Lifted raise LiftError {
  for provider in self.providers {
    if (provider.accepts)(ctx) {
      let lifted = (provider.lift)(ctx, insn) catch {
        Unsupported(..) => continue
        err => raise err
      }
      if validate {
        match @types.check_stmt_types(lifted.bil) {
          Ok(_) => ()
          Err(err) => raise IllTyped(opcode=insn.name, detail=err.to_string())
        }
      }
      return lifted
    }
  }
  raise Unsupported(opcode=insn.name, target=ctx.target.to_string())
}
