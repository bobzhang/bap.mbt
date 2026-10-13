///|
/// # Primus dictionaries (upstream `plugins/primus_dictionary`)
///
/// A key-value storage for Primus Lisp programs. Dictionaries are denoted
/// with symbols (any value, compared by its numeric value) and it is the
/// responsibility of the user to prevent name clashes between different
/// dictionaries. Keys are ordered by their numeric values, so the keys of
/// a dictionary can be iterated with `dict-first` and `dict-next`. The
/// dictionaries are persistent and local to each machine.
///
/// Upstream exposes the operations as Primus Lisp primitives (`dict-add`,
/// `dict-get`, `dict-has`, `dict-del`, `dict-first`, `dict-next`,
/// `dict-length`). Primus Lisp is ported separately, so this package
/// provides them as host functions (`primitives`) with their Lisp
/// signatures and documentation, and the `bap:lisp-dictionary` component
/// links them into the machine under their names (as `Host` code), so they
/// can be called with `Machine::call` or bound by a Lisp interpreter.
pub let component_name : String = "lisp-dictionary"

///|
/// A primitive: its name, Lisp type signature, documentation and the host
/// implementation applied to the arguments.
pub struct Primitive {
  name : String
  types : String
  docs : String
  run : (@primus.Machine, Array[@primus.Value]) -> @primus.Value raise
}

///|
/// The numeric order of words (upstream `Primus.Value.compare`): values
/// are compared ignoring their widths.
fn value_order(a : @types.Word, b : @types.Word) -> Int32 {
  let w = if a.bitwidth() > b.bitwidth() { a.bitwidth() } else { b.bitwidth() }
  let widen = (x : @types.Word) => {
    if x.bitwidth() == w {
      x
    } else {
      x.extract(hi=w - 1, lo=0) catch {
        _ => x
      }
    }
  }
  widen(a).compare_unsigned(widen(b)) catch {
    _ => a.compare(b)
  }
}

///|
priv struct Key(@types.Word)

///|
impl Eq for Key with fn equal(self, other) {
  value_order(self.0, other.0) == 0
}

///|
impl Compare for Key with fn compare(self, other) {
  value_order(self.0, other.0)
}

///|
/// A dictionary: the key values and the associated data, ordered by keys.
priv struct Dict(@sorted_map.SortedMap[Key, (@primus.Value, @primus.Value)])

///|
let state : @primus.State[@sorted_map.SortedMap[Key, Dict]] = @primus.State::declare_(
  uuid="F050079C-7FDB-4A8F-8A59-72C9693ADBCE",
  name="lisp-dictionaries",
  _ => @sorted_map.new(),
)

///|
fn nil(m : @primus.Machine) -> @primus.Value {
  @primus.Value::b0(m)
}

///|
fn find(m : @primus.Machine, dic : @primus.Value) -> Dict? {
  m.get_local(state).get(Key(dic.to_word()))
}

///|
/// `(dict-add DIC KEY DATA)`: associates `DATA` with `KEY` in `DIC`.
/// Returns `KEY`.
pub fn add(
  m : @primus.Machine,
  dic : @primus.Value,
  key : @primus.Value,
  data : @primus.Value,
) -> @primus.Value {
  let k = Key(dic.to_word())
  m.update_local(state, dicts => {
    let Dict(d) = dicts.get(k).unwrap_or(Dict(@sorted_map.new()))
    dicts.add(k, Dict(d.add(Key(key.to_word()), (key, data))))
  })
  key
}

///|
/// `(dict-get DIC KEY)`: the data associated with `KEY` in `DIC`, or nil.
pub fn get(
  m : @primus.Machine,
  dic : @primus.Value,
  key : @primus.Value,
) -> @primus.Value {
  match find(m, dic) {
    Some(Dict(d)) =>
      match d.get(Key(key.to_word())) {
        Some((_, x)) => x
        None => nil(m)
      }
    None => nil(m)
  }
}

///|
/// `(dict-has DIC KEY)`: true if `DIC` has `KEY`.
pub fn has(
  m : @primus.Machine,
  dic : @primus.Value,
  key : @primus.Value,
) -> @primus.Value {
  match find(m, dic) {
    Some(Dict(d)) => @primus.Value::of_bool(m, d.contains(Key(key.to_word())))
    None => nil(m)
  }
}

///|
/// `(dict-del DIC)` deletes the dictionary, `(dict-del DIC KEY)` deletes
/// the association of `KEY`. Returns nil.
pub fn del(
  m : @primus.Machine,
  dic : @primus.Value,
  key? : @primus.Value,
) -> @primus.Value {
  let k = Key(dic.to_word())
  m.update_local(state, dicts => {
    match key {
      None => dicts.remove(k)
      Some(key) =>
        match dicts.get(k) {
          None => dicts
          Some(Dict(d)) => dicts.add(k, Dict(d.remove(Key(key.to_word()))))
        }
    }
  })
  nil(m)
}

///|
/// `(dict-first DIC)`: the first (the smallest) key of `DIC`, or nil.
pub fn first(m : @primus.Machine, dic : @primus.Value) -> @primus.Value {
  match find(m, dic) {
    Some(Dict(d)) =>
      match d.values().head() {
        Some((key, _)) => key
        None => nil(m)
      }
    None => nil(m)
  }
}

///|
/// `(dict-next DIC KEY)`: the key that follows `KEY` in `DIC`, or nil if
/// `KEY` is the last one.
pub fn next(
  m : @primus.Machine,
  dic : @primus.Value,
  key : @primus.Value,
) -> @primus.Value {
  match find(m, dic) {
    Some(Dict(d)) => {
      let k = Key(key.to_word())
      match d.values().find_first(p => Key(p.0.to_word()) > k) {
        Some((x, _)) => x
        None => nil(m)
      }
    }
    None => nil(m)
  }
}

///|
/// `(dict-length DIC)`: the number of keys in `DIC`, or nil.
pub fn length(m : @primus.Machine, dic : @primus.Value) -> @primus.Value raise {
  match find(m, dic) {
    Some(Dict(d)) =>
      @primus.Value::of_int(m, width=m.target().bits(), d.length())
    None => nil(m)
  }
}

///|
fn arity(name : String, args : Array[@primus.Value], n : Int32) -> Unit raise {
  if args.length() != n {
    raise @primus.RuntimeError(
      "\{name}: expects \{n} arguments, got \{args.length()}",
    )
  }
}

///|
/// The Lisp primitives of the library.
pub fn primitives() -> Array[Primitive] {
  [
    {
      name: "dict-add",
      types: "(sym a b) -> bool",
      docs: "(dict-add DIC KEY DATA) associates DATA with KEY in the dictionary DIC. Returns KEY.",
      run: (m, args) => {
        arity("dict-add", args, 3)
        add(m, args[0], args[1], args[2])
      },
    },
    {
      name: "dict-get",
      types: "(sym a) -> b",
      docs: "(dict-get DIC KEY) returns data associated with KEY in the dictionary DIC, and returns NIL if either DIC doesn't exist on no data are associated",
      run: (m, args) => {
        arity("dict-get", args, 2)
        get(m, args[0], args[1])
      },
    },
    {
      name: "dict-has",
      types: "(sym a) -> bool",
      docs: "(dict-has DIC KEY) returns T if the dictionary DIC has the key KEY",
      run: (m, args) => {
        arity("dict-has", args, 2)
        has(m, args[0], args[1])
      },
    },
    {
      name: "dict-del",
      types: "(sym a) -> bool",
      docs: "(dict-del DIC KEY) deletes any association with KEY in the dictionary DIC",
      run: (m, args) => {
        match args {
          [dic] => del(m, dic)
          [dic, key] => del(m, dic, key~)
          _ => raise @primus.RuntimeError("dict-del: expects 1 or 2 arguments")
        }
      },
    },
    {
      name: "dict-first",
      types: "(sym) -> a",
      docs: "(dict-first DIC) is the first key in DIC or nil if DIC is empty.",
      run: (m, args) => {
        arity("dict-first", args, 1)
        first(m, args[0])
      },
    },
    {
      name: "dict-next",
      types: "(sym a) -> a",
      docs: "(dict-next DIC KEY) returns the next key after KEY. Returns nil if KEY was the last key in the dictionary. Could be used together with DICT-FIRST for iterating.",
      run: (m, args) => {
        arity("dict-next", args, 2)
        next(m, args[0], args[1])
      },
    },
    {
      name: "dict-length",
      types: "(sym) -> int",
      docs: "(dict-first DIC) is the total number of keys in DIC.",
      run: (m, args) => {
        arity("dict-length", args, 1)
        length(m, args[0])
      },
    },
  ]
}

///|
/// Links the primitives into the machine (the `bap:lisp-dictionary`
/// component body).
///
/// The primitives are linked under their names and defined as Primus Lisp
/// primitives (in the `core` package), as the upstream component does.
pub fn install(m : @primus.Machine) -> Unit {
  for p in primitives() {
    let run = p.run
    @primus.Linker::link(
      m,
      name=p.name,
      Host(m => m.set_result(Some(run(m, m.call_args())))),
    )
    @primus_lisp.define_host_primitive(
      m,
      p.name,
      types=p.types,
      docs=p.docs,
      run,
    )
  }
}

///|
let desc : String = "Provides a key-value storage for Primus Lisp programs. Dictionaries are represented with symbols and it is a responsibility of user to prevent name clashing between different dictionaries."

///|
/// Registers the `bap:lisp-dictionary` component. Idempotent: returns
/// `false` if it was already registered.
pub fn register() -> Bool {
  @primus.Components::register_generic(
    component_name,
    m => install(m),
    pkg="bap",
    desc~,
  ) catch {
    _ => return false
  }
  true
}

///|
let enabled : Ref[Bool] = { val: false, }

///|
/// Registers the component and adds it to the legacy main system, as the
/// upstream plugin does when it is loaded. Idempotent.
pub fn enable() -> Unit {
  register() |> ignore
  if !enabled.val {
    enabled.val = true
    @primus.Machine::add_component(m => install(m))
  }
}

///|
/// The name of the plugin.
pub let name : String = "primus-dictionary"

///|
/// Declares the `primus-dictionary` plugin to `bap_main`. Does nothing if
/// already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["primus", "primus-library", "dictionary"],
    doc="provides a Primus Lisp key-value storage library\n\n" + desc,
    () => @bap_main.Extension::register(_ => enable()),
  )
}
