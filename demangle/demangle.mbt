///|
struct Demangler {
  fullname_value : @knowledge.Name
  run_fn : (String) -> String
}

///|
pub(all) struct Demanglers {}

///|
let demangler_registry : Map[String, (String) -> String] = Map([])

///|
let demangler_selected : Map[String, Demangler] = Map([])

///|
let demangler_builtins_registered : Ref[Bool] = Ref(false)

///|
fn demangler_key(name : @knowledge.Name) -> String {
  name.show()
}

///|
fn demangler_target_key(target : @core_theory.Target) -> String {
  target.name().show()
}

///|
fn demangler_value(
  name : String,
  pkg~ : String,
  run~ : (String) -> String,
) -> Demangler {
  { fullname_value: @knowledge.Name::create(name, pkg~), run_fn: run, }
}

///|
fn demangler_add(demangler : Demangler) -> Result[Unit, String] {
  let key = demangler_key(demangler.fullname())
  if demangler_registry.contains(key) {
    Err("demangler \{key} is already registered")
  } else {
    demangler_registry[key] = demangler.run_fn
    Ok(())
  }
}

///|
fn demangler_install_builtin(demangler : Demangler) -> Unit {
  demangler_registry[demangler_key(demangler.fullname())] = demangler.run_fn
}

///|
fn demangler_ensure_builtins() -> Unit {
  if !demangler_builtins_registered.val {
    demangler_install_builtin(
      demangler_value("id", pkg="bap", run=fn(name) { name }),
    )
    demangler_install_builtin(
      demangler_value("strip-leading-underscore", pkg="bap", run=fn(name) {
        if name.has_prefix("_") {
          name[1:].to_owned()
        } else {
          name
        }
      }),
    )
    demangler_builtins_registered.val = true
  }
}

///|
pub fn Demangler::create(
  name : String,
  run : (String) -> String,
  pkg? : String,
) -> Result[Demangler, String] {
  demangler_ensure_builtins()
  let demangler = demangler_value(
    name,
    pkg=match pkg {
      Some(value) => value
      None => "user"
    },
    run~,
  )
  match demangler_add(demangler) {
    Ok(_) => Ok(demangler)
    Err(reason) => Err(reason)
  }
}

///|
pub fn Demangler::declare_demangler(
  name : String,
  run : (String) -> String,
  pkg? : String,
) -> Result[Unit, String] {
  Demangler::declare_(name, run, pkg?)
}

///|
pub fn Demangler::declare_(
  name : String,
  run : (String) -> String,
  pkg? : String,
) -> Result[Unit, String] {
  Demangler::create(name, run, pkg?).map(_ => ())
}

///|
pub fn Demangler::id() -> Demangler {
  demangler_ensure_builtins()
  demangler_value("id", pkg="bap", run=fn(name) { name })
}

///|
pub fn Demangler::strip_leading_underscore() -> Demangler {
  demangler_ensure_builtins()
  demangler_value("strip-leading-underscore", pkg="bap", run=fn(name) {
    if name.has_prefix("_") {
      name[1:].to_owned()
    } else {
      name
    }
  })
}

///|
pub fn Demangler::run(self : Demangler, name : String) -> String {
  (self.run_fn)(name)
}

///|
pub fn Demangler::name(self : Demangler) -> String {
  self.fullname_value.unqualified()
}

///|
pub fn Demangler::fullname(self : Demangler) -> @knowledge.Name {
  self.fullname_value
}

///|
pub fn Demanglers::register(_demangler : Demangler) -> Unit {
  ()
}

///|
pub fn Demanglers::lookup(name : String, pkg? : String) -> Demangler? {
  demangler_ensure_builtins()
  let fullname = @knowledge.Name::create(name, pkg?)
  match demangler_registry.get(demangler_key(fullname)) {
    Some(run) => Some({ fullname_value: fullname, run_fn: run, })
    None => None
  }
}

///|
pub fn Demanglers::get(
  name : String,
  pkg? : String,
) -> Result[Demangler, String] {
  match Demanglers::lookup(name, pkg?) {
    Some(demangler) => Ok(demangler)
    None => {
      let available = Demanglers::available()
        .map(demangler => demangler.fullname().show())
        .join(", ")
      Err(
        "failed to find a demangler named \{@knowledge.Name::create(name, pkg?).show()}; available demanglers: \{available}",
      )
    }
  }
}

///|
pub fn Demanglers::install(
  target : @core_theory.Target,
  demangler : Demangler,
) -> Result[Unit, String] {
  demangler_ensure_builtins()
  let key = demangler_target_key(target)
  match demangler_selected.get(key) {
    Some(used) =>
      Err(
        "target \{target.name().show()} already has demangler \{used.fullname().show()}",
      )
    None => {
      demangler_selected[key] = demangler
      Ok(())
    }
  }
}

///|
pub fn Demanglers::select(target : @core_theory.Target) -> Demangler {
  demangler_ensure_builtins()
  match demangler_selected.get(demangler_target_key(target)) {
    Some(demangler) => demangler
    None => Demangler::id()
  }
}

///|
pub fn Demanglers::available() -> Array[Demangler] {
  demangler_ensure_builtins()
  let demanglers : Array[Demangler] = []
  for entry in demangler_registry {
    demanglers.push({
      fullname_value: @knowledge.Name::of_string(entry.0),
      run_fn: entry.1,
    })
  }
  demanglers.sort_by((left, right) => left.fullname().compare(right.fullname()))
  demanglers
}
