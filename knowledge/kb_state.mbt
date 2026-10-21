///|
/// The status of a slot computation on an object (`Env.work`).
///
/// `Working(waiting, current)` holds the promise ids that are currently
/// running (`current`) and those that must be re-run because they observed
/// an intermediate approximation of the slot (`waiting`).
priv enum Work {
  Done
  Working(@sorted_set.SortedSet[Int32], @sorted_set.SortedSet[Int32])
}

///|
/// Everything the knowledge base knows about an object (`Env.info`).
priv struct Info {
  data : Record
  comp : @sorted_map.SortedMap[Int32, Work]
  name : Name?
}

///|
let noinfo : Info = {
  data: empty_record,
  comp: @sorted_map.SortedMap::new(),
  name: None,
}

///|
/// The objects of one class (`Env.objects`).
///
/// - `last` is the last allocated object identifier of the class;
/// - `vals` maps object identifiers to their knowledge;
/// - `objs` is the symbol table: fully qualified names (including names
///   imported into other packages) to objects;
/// - `pubs` lists the public symbols of each package.
priv struct Objects {
  last : Int32
  vals : @sorted_map.SortedMap[Int32, Info]
  objs : @hashmap.HashMap[Name, Int32]
  pubs : @hashmap.HashMap[String, @sorted_set.SortedSet[Int32]]
}

///|
let empty_class : Objects = {
  last: 0,
  vals: @sorted_map.SortedMap::new(),
  objs: @hashmap.HashMap::new(),
  pubs: @hashmap.HashMap::new(),
}

///|
/// The knowledge base (`Env.t`): an immutable value, so that snapshots
/// are O(1) and rejected computations can be rolled back.
priv struct Env {
  classes : @hashmap.HashMap[Name, Objects]
  pkg : String
  context : @sorted_map.SortedMap[Int32, () -> Unit]
}

///|
let empty_env : Env = {
  classes: @hashmap.HashMap::new(),
  pkg: "user",
  context: @sorted_map.SortedMap::new(),
}

///|
/// The knowledge base state (`Knowledge.state`) and the handle of a
/// knowledge computation.
///
/// # The knowledge monad in MoonBit
///
/// Upstream knowledge computations have type `'a knowledge`, a
/// state-and-failure monad over the knowledge base. MoonBit has no
/// higher-kinded types, so the port uses direct style instead:
///
/// - `'a knowledge` is `(State) -> A raise`: a function that receives the
///   handle of the knowledge base it runs in, reads and updates it in
///   place, and `raise`s a conflict (any `Error`, see `Conflict`) to
///   diverge;
/// - `return x` is just `x`, `x >>= f` is `f(x_computed)`, and
///   `Knowledge.fail c` is `raise c`;
/// - the knowledge base itself is an immutable value held by the mutable
///   handle, so `run`, `catch_` and `with_empty` can restore the snapshot
///   taken on entry when a computation diverges, exactly like the
///   upstream monad discards the state of a failed computation.
///
/// Note that a plain MoonBit `try`/`catch` does *not* roll the state back;
/// use `State::catch_` (upstream `Knowledge.catch`) for that.
struct State {
  mut env : Env
}

///|
/// An empty knowledge base (`Knowledge.empty`).
pub fn State::new() -> State {
  { env: empty_env, }
}

///|
/// An empty knowledge base (`Knowledge.empty`).
pub fn State::empty() -> State {
  State::new()
}

///|
/// A new handle on a snapshot of the knowledge base. Updates made through
/// either handle are not visible through the other one.
pub fn State::fork(self : State) -> State {
  { env: self.env, }
}

///|
/// Replaces the knowledge of `self` with the knowledge of `other`.
pub fn State::assign(self : State, other : State) -> Unit {
  self.env = other.env
}

///|
/// `Knowledge.catch x handler`: evaluates `body` and, if it diverges with
/// a conflict, restores the knowledge base to the state before `body` and
/// evaluates `handler` with the conflict.
pub fn[R] State::catch_(
  self : State,
  body : () -> R raise,
  handler : (Error) -> R raise,
) -> R raise {
  let snapshot = self.env
  body() catch {
    err => {
      self.env = snapshot
      handler(err)
    }
  }
}

///|
/// Evaluates `body` as a transaction: if it diverges, the knowledge base
/// is restored and the conflict is returned as an `Err`.
#warnings("-78")
pub fn[R] State::transaction(
  self : State,
  body : () -> R raise,
) -> Result[R, Error] {
  let snapshot = self.env
  try body() catch {
    err => {
      self.env = snapshot
      Err(err)
    }
  } noraise {
    r => Ok(r)
  }
}

///|
fn State::class_objects(self : State, cls : Name) -> Objects {
  match self.env.classes.get(cls) {
    Some(objects) => objects
    None => empty_class
  }
}

///|
fn State::set_class_objects(
  self : State,
  cls : Name,
  objects : Objects,
) -> Unit {
  self.env = { ..self.env, classes: self.env.classes.add(cls, objects), }
}

///|
fn State::info(self : State, cls : Name, id : Int32) -> Info? {
  self.class_objects(cls).vals.get(id)
}

///|
fn State::update_info(
  self : State,
  cls : Name,
  id : Int32,
  f : (Info) -> Info,
) -> Unit {
  let objects = self.class_objects(cls)
  let info = match objects.vals.get(id) {
    Some(info) => info
    None => noinfo
  }
  self.set_class_objects(cls, {
    ..objects,
    vals: objects.vals.add(id, f(info)),
  })
}

///|
/// `Object.create`: a fresh object of the class with an indefinite extent.
///
/// As upstream, the object is only allocated: it is listed by
/// `State::objects` (and serialized) once the knowledge base learns
/// something about it (a property, a computation, or a name).
pub fn[K, S] State::create(self : State, cls : Class[K, S]) -> Object[K] {
  let name = cls.name()
  let objects = self.class_objects(name)
  let id = objects.last + 1
  self.set_class_objects(name, { ..objects, last: id, })
  { id, class_name: name, _phantom: None, }
}

///|
/// `Object.delete`: forgets everything known about the object (its facts,
/// computation status and name). The symbol table still resolves the
/// object's name, as upstream.
pub fn[K, S] State::delete(
  self : State,
  cls : Class[K, S],
  object : Object[K],
) -> Unit {
  let name = cls.name()
  match self.env.classes.get(name) {
    Some(objects) =>
      self.set_class_objects(name, {
        ..objects,
        vals: objects.vals.remove(object.id()),
      })
    None => ()
  }
}

///|
/// `Object.scoped cls scope`: passes a fresh object to `scope` and deletes
/// it (with all its knowledge) after `scope` evaluates.
pub fn[K, S, R] State::scoped(
  self : State,
  cls : Class[K, S],
  scope : (Object[K]) -> R raise?,
) -> R raise? {
  let object = self.create(cls)
  let result = scope(object)
  self.delete(cls, object)
  result
}

///|
/// `Knowledge.objects cls`: all objects of the class that have some
/// knowledge (properties, computed slots or a name), in creation order.
pub fn[K, S] State::objects(
  self : State,
  cls : Class[K, S],
) -> Array[Object[K]] {
  let name = cls.name()
  self.class_objects(name).vals
  .keys_as_iter()
  .map(id => Object::{ id, class_name: name, _phantom: None, })
  .to_array()
}

///|
/// `Symbol.set_package`: makes `pkg` the current package.
pub fn State::set_current_pkg(self : State, pkg : String) -> Unit {
  self.env = { ..self.env, pkg: if pkg == "" { "user" } else { pkg }, }
}

///|
/// `Symbol.in_package pkg f`: evaluates `f` with `pkg` as the current
/// package (affects the symbol reader and printer).
pub fn[R] State::in_package(
  self : State,
  pkg : String,
  f : () -> R raise?,
) -> R raise? {
  let previous = self.env.pkg
  self.set_current_pkg(pkg)
  let result = f()
  self.set_current_pkg(previous)
  result
}

///|
/// `Symbol.package`: the current package.
pub fn State::current_pkg(self : State) -> String {
  self.env.pkg
}

///|
/// Alias of `State::in_package`.
pub fn[R] State::with_pkg(self : State, pkg : String, body : () -> R) -> R {
  self.in_package(pkg, body)
}

///|
fn Objects::publicize(self : Objects, name : Name, id : Int32) -> Objects {
  let pkg = name.pkg()
  let pubs = match self.pubs.get(pkg) {
    Some(ids) => ids.add(id)
    None => @sorted_set.SortedSet::singleton(id)
  }
  { ..self, pubs: self.pubs.add(pkg, pubs), }
}

///|
/// `Object.do_intern`: finds or creates the object named `name`.
fn[K, S] State::do_intern(
  self : State,
  cls : Class[K, S],
  name : Name,
  public : Bool,
) -> Object[K] {
  let cls_name = cls.name()
  let objects = self.class_objects(cls_name)
  match objects.objs.get(name) {
    None => {
      let id = objects.last + 1
      let info = { ..noinfo, name: Some(name), }
      let objects = {
        ..objects,
        last: id,
        vals: objects.vals.add(id, info),
        objs: objects.objs.add(name, id),
      }
      self.set_class_objects(
        cls_name,
        if public {
          objects.publicize(name, id)
        } else {
          objects
        },
      )
      { id, class_name: cls_name, _phantom: None, }
    }
    Some(id) => {
      if public &&
        !(objects.pubs.get(name.pkg()) is Some(ids) && ids.contains(id)) {
        self.set_class_objects(cls_name, objects.publicize(name, id))
      }
      { id, class_name: cls_name, _phantom: None, }
    }
  }
}

///|
/// `Symbol.intern ?public ?desc ?package name cls`: the object named
/// `name` in the package `pkg` (defaults to the current package), created on the
/// first use. Public symbols are exported by `import`ing their package.
/// Any `:` in `name` is taken literally.
pub fn[K, S] State::intern_symbol(
  self : State,
  name : String,
  cls : Class[K, S],
  public~ : Bool = false,
  desc? : String,
  pkg? : String,
) -> Object[K] {
  ignore(desc)
  let pkg = match pkg {
    Some(pkg) => pkg
    None => self.env.pkg
  }
  self.do_intern(cls, Name::create(name, pkg~), public)
}

///|
/// Interns the fully qualified `name` (non-public).
pub fn[K, S] State::intern(
  self : State,
  cls : Class[K, S],
  name~ : Name,
) -> Object[K] {
  self.do_intern(cls, name, false)
}

///|
/// Interns `name` in `pkg` (defaults to the current package).
pub fn[K, S] State::intern_named(
  self : State,
  cls : Class[K, S],
  name : String,
  pkg? : String,
) -> Object[K] {
  self.intern_symbol(name, cls, pkg?)
}

///|
/// `Object.read cls input`: `nil`, `#<class id>`, or a (possibly
/// qualified) symbol name read relative to `pkg` (defaults to the current
/// package), which is interned.
pub fn[K, S] State::read(
  self : State,
  cls : Class[K, S],
  input : String,
  pkg? : String,
) -> Result[Object[K], String] {
  if input == "nil" || input.has_prefix("#<") {
    Object::read(cls, input)
  } else {
    let pkg_name = match pkg {
      Some(value) => value
      None => self.env.pkg
    }
    Ok(self.intern(cls, name=Name::read(input, pkg=pkg_name)))
  }
}

///|
/// The (home) name of an interned object.
pub fn[K] State::interned_name(self : State, object : Object[K]) -> Name? {
  match self.info(object.class_name(), object.id()) {
    Some(info) => info.name
    None => None
  }
}

///|
/// `Object.repr`: the symbol name (unqualified if it belongs to the current
/// package) or the `#<class id>` representation of uninterned objects.
pub fn[K] State::repr(self : State, object : Object[K]) -> String {
  match self.interned_name(object) {
    Some(name) =>
      if name.pkg() == self.env.pkg {
        name.unqualified()
      } else {
        name.show()
      }
    None => object.repr()
  }
}

///|
/// `Symbol.import ?strict ?package names`: imports `names` into `package`
/// (the package `pkg`, defaults to the current package).
///
/// An element of `names` without a package separator is a package, and
/// all public symbols of that package are imported; a qualified name
/// imports that symbol, even if it is not public. Unknown packages or
/// symbols raise `NotAPackage`/`NotASymbol`. Unless `strict`, an imported
/// name shadows a name already present in `package`; a strict import
/// raises `ImportConflict` instead. Imported names are not public.
pub fn State::import_(
  self : State,
  names : Array[String],
  strict~ : Bool = false,
  pkg? : String,
) -> Unit raise Conflict {
  let pkg = match pkg {
    Some(p) => if p == "" { "user" } else { p }
    None => self.env.pkg
  }
  let mut classes = self.env.classes
  for input in names {
    let target : Result[Name, String] = if name_has_separator(input) {
      Ok(Name::read(input))
    } else {
      Err(input)
    }
    // check_name
    match target {
      Err(p) =>
        if !classes
          .values()
          .any(objects => objects.objs.keys().any(name => name.pkg() == p)) {
          raise NotAPackage(p)
        }
      Ok(sym) =>
        if !classes.values().any(objects => objects.objs.contains(sym)) {
          raise NotASymbol(sym)
        }
    }
    for cls, objects in classes {
      let mut objs = objects.objs
      for id, info in objects.vals {
        guard info.name is Some(sym) else { continue }
        let needed = match target {
          Ok(wanted) => sym == wanted
          Err(p) => objects.pubs.get(p) is Some(ids) && ids.contains(id)
        }
        if !needed {
          continue
        }
        let imported = Name::create(sym.unqualified(), pkg~)
        let existing = objs.get(imported).unwrap_or(0)
        if !strict || existing == 0 || existing == id {
          objs = objs.add(imported, id)
        } else {
          let other = match objects.vals.get(existing) {
            Some({ name: Some(other), .. }) => other
            _ => imported
          }
          raise ImportConflict(sym, other)
        }
      }
      classes = classes.add(cls, { ..objects, objs, })
    }
  }
  self.env = { ..self.env, classes, }
}

///|
/// `true` if the input contains an unescaped package separator.
fn name_has_separator(input : String) -> Bool {
  let mut escaped = false
  for ch in input {
    if escaped {
      escaped = false
    } else if ch == '\\' {
      escaped = true
    } else if ch == ':' {
      return true
    }
  }
  false
}
