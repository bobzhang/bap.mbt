///|
/// `compute_value`: collects every promised property of the object.
fn[K, S] State::compute_value(
  self : State,
  cls : Class[K, S],
  object : Object[K],
) -> Unit raise {
  match class_slots.get(cls.name()) {
    Some(slots) => {
      let packs = [ for _, pack in slots => pack ]
      for pack in packs {
        if (pack.has_promises)() && !object.is_null() {
          (pack.collect)(self, object.id())
        }
      }
    }
    None => ()
  }
}

///|
/// `get_value cls obj`: computes all promised properties of `obj` and
/// returns the value holding all its properties.
pub fn[K, S] State::value(
  self : State,
  cls : Class[K, S],
  object : Object[K],
) -> Value[K, S] raise {
  self.compute_value(cls, object)
  match self.info(cls.name(), object.id()) {
    Some(info) if !object.is_null() => Value::create(cls, info.data)
    _ => Value::empty(cls)
  }
}

///|
/// `Knowledge.run cls comp init`: evaluates the knowledge computation
/// `comp` in the knowledge base `init`.
///
/// The computation must evaluate to an object of the class `cls`; `run`
/// then computes all properties of that object (triggering all promises of
/// the class slots) and returns its value together with the resulting
/// knowledge base, or the conflict if the computation diverged. `init` is
/// never modified.
///
/// ```mbt nocheck
/// let (value, state) = @knowledge.run(cls, kb => {
///   let obj = kb.create(cls)
///   kb.provide(slot, obj, 42)
///   obj
/// }, @knowledge.State::empty()).unwrap()
/// ```
pub fn[K, S] run(
  cls : Class[K, S],
  comp : (State) -> Object[K] raise,
  init : State,
) -> (Value[K, S], State) raise {
  let state = init.fork()
  let object = comp(state)
  (state.value(cls, object), state)
}

///|
/// Evaluates a knowledge computation in a copy of `init`, returning its
/// result and the resulting knowledge base (the generic form of `run`).
pub fn[R] eval(comp : (State) -> R raise, init : State) -> (R, State) raise {
  let state = init.fork()
  (comp(state), state)
}

///|
/// A context variable (`Knowledge.Context.var`).
///
/// Context variables are not part of the knowledge per se: they hold an
/// arbitrary (not necessarily domain) value in the knowledge base state,
/// are never persisted, and are rolled back together with the rest of the
/// state when a computation is rejected.
struct Var[T] {
  key : Key[T]
  init : (State) -> T raise
  inspect : ((T) -> String)?
}

///|
/// `Context.declare ?inspect ?package name init` (`declare` is a MoonBit
/// keyword): declares a new context
/// variable initialized with the knowledge computation `init`.
pub fn[T] Var::new(
  name : String,
  init : (State) -> T raise,
  pkg? : String,
  inspect? : (T) -> String,
) -> Var[T] {
  { key: Key::fresh(Name::create(name, pkg?)), init, inspect, }
}

///|
/// The name of the variable.
pub fn[T] Var::name(self : Var[T]) -> Name {
  self.key.name
}

///|
/// Renders a value of the variable with its inspector.
pub fn[T] Var::inspect(self : Var[T], value : T) -> String {
  match self.inspect {
    Some(f) => f(value)
    None => "<opaque>"
  }
}

///|
/// `Context.get v`: the current value of the variable.
pub fn[T] Var::get(self : Var[T], state : State) -> T raise {
  match state.env.context.get(self.key.uid) {
    Some(store) => {
      let cell = self.key.cell
      cell.val = None
      store()
      let result = cell.val
      cell.val = None
      result.unwrap()
    }
    None => (self.init)(state)
  }
}

///|
/// `Context.set v x`: assigns `x` to the variable.
pub fn[T] Var::set(self : Var[T], state : State, value : T) -> Unit {
  state.env = {
    ..state.env,
    context: state.env.context.add(self.key.uid, self.key.storing(value)),
  }
}

///|
/// `Context.update v f`: applies `f` to the value of the variable.
pub fn[T] Var::update(self : Var[T], state : State, f : (T) -> T) -> Unit raise {
  self.set(state, f(self.get(state)))
}

///|
/// `Context.with_var v x f`: dynamically binds `v` to `x` while `f` runs.
pub fn[T, R] Var::with_(
  self : Var[T],
  state : State,
  value : T,
  f : () -> R raise,
) -> R raise {
  let previous = self.get(state)
  self.set(state, value)
  let result = f()
  self.set(state, previous)
  result
}
