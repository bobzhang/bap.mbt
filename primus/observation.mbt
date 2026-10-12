///|
/// A provider of an observation (upstream `Primus.Observation.provider`).
///
/// Providers are global: they are registered when an observation is
/// declared with `Observation::provide` and are shared by all machines.
pub struct Provider {
  priv info : Info
  priv key : Int32
  priv mut observers : Int32
  priv mut triggers : Int32
  priv listeners : Array[(Sexp) -> Unit]
}

///|
/// An observation of values of type `T` (upstream `'a observation`).
///
/// Observations are typed keys. Subscribers are stored per machine (see
/// `Machine::observe`); an observation value is delivered through a private
/// slot so that heterogeneous observers can share one table.
pub struct Observation[T] {
  priv key : Int32
  priv name : String
  priv inspect : (T) -> Sexp
  priv slot : Ref[T?]
  priv provider : Provider
}

///|
/// The capability to post an observation (upstream `'a statement`).
/// Only the component that declared the observation holds its statement.
pub struct Statement[T] {
  priv obs : Observation[T]
}

///|
/// A handle of a subscription that can be cancelled with `Machine::cancel`.
pub struct Subscription {
  priv key : Int32
  priv id : Int32
  priv watcher : Bool
} derive(Eq, Debug)

///|
let providers : Map[String, Provider] = Map([])

///|
let last_observation_key : Ref[Int32] = { val: 0, }

///|
fn[T] opaque_sexp(_x : T) -> Sexp {
  Atom("<opaque>")
}

///|
/// Declares a new observation (upstream `Observation.provide`).
///
/// Returns the observation (used to subscribe) and the statement (used to
/// post). The name must be unique within its package; declaring the same
/// name twice aborts, as upstream.
pub fn[T] Observation::provide(
  name : String,
  desc~ : String = "",
  inspect~ : (T) -> Sexp = opaque_sexp,
  pkg~ : String = "primus",
) -> (Observation[T], Statement[T]) {
  let fullname = @knowledge.Name::create(name, pkg~)
  let shown = fullname.show()
  if providers.contains(shown) {
    abort(
      "Observation name `\{shown}' is already used by another component. Please, choose a different name",
    )
  }
  last_observation_key.val += 1
  let provider = Provider::{
    info: Info::create(fullname, desc~),
    key: last_observation_key.val,
    observers: 0,
    triggers: 0,
    listeners: [],
  }
  providers[shown] = provider
  let obs = Observation::{
    key: provider.key,
    name: shown,
    inspect,
    slot: { val: None, },
    provider,
  }
  (obs, Statement::{ obs, })
}

///|
/// The (fully qualified) name of the observation.
pub fn[T] Observation::name(self : Observation[T]) -> String {
  self.name
}

///|
/// Renders an observed value with the observation's inspector.
pub fn[T] Observation::inspect(self : Observation[T], x : T) -> Sexp {
  (self.inspect)(x)
}

///|
/// The provider of the observation.
pub fn[T] Observation::provider(self : Observation[T]) -> Provider {
  self.provider
}

///|
/// Returns the observation posted by the statement.
pub fn[T] Observation::of_statement(stmt : Statement[T]) -> Observation[T] {
  stmt.obs
}

///|
/// All registered providers (upstream `Observation.list_providers`).
pub fn Observation::list_providers() -> Array[Provider] {
  providers.values().collect()
}

///|
/// Documentation of all registered observations (upstream `Observation.list`).
pub fn Observation::list() -> Array[Info] {
  providers.values().map(p => p.info).collect()
}

///|
/// Finds a provider by its (fully qualified or short primus) name.
pub fn Provider::find(name : String) -> Provider? {
  match providers.get(name) {
    Some(p) => Some(p)
    None => providers.get(@knowledge.Name::create(name, pkg="primus").show())
  }
}

///|
/// The short name of the provider: unqualified for the `primus` package,
/// `package:name` otherwise.
pub fn Provider::name(self : Provider) -> String {
  let name = self.info.name()
  let short = name.unqualified()
  match name.pkg() {
    "primus" => short
    pkg => "\{pkg}:\{short}"
  }
}

///|
pub fn Provider::fullname(self : Provider) -> @knowledge.Name {
  self.info.name()
}

///|
pub fn Provider::desc(self : Provider) -> String {
  self.info.desc()
}

///|
pub fn Provider::info(self : Provider) -> Info {
  self.info
}

///|
/// The total number of observers ever subscribed to this provider.
pub fn Provider::observers(self : Provider) -> Int32 {
  self.observers
}

///|
/// How many times the observation was triggered (upstream `triggers`
/// stream, represented here as a counter).
pub fn Provider::triggers(self : Provider) -> Int32 {
  self.triggers
}

///|
/// Registers a global listener of the inspected data stream of the
/// provider (upstream `Provider.data`).
pub fn Provider::on_data(self : Provider, f : (Sexp) -> Unit) -> Unit {
  self.listeners.push(f)
}

///|
/// Declares a new observation and returns only its statement (see
/// `Observation::provide`); the observation is `Observation::of_statement`.
pub fn[T] Statement::provide(
  name : String,
  desc~ : String = "",
  inspect~ : (T) -> Sexp = opaque_sexp,
  pkg~ : String = "primus",
) -> Statement[T] {
  Observation::provide(name, desc~, inspect~, pkg~).1
}

///|
/// The observation posted by the statement.
pub fn[T] Statement::observation(self : Statement[T]) -> Observation[T] {
  self.obs
}
