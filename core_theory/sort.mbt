///|
pub(all) enum Sort {
  Sym(@knowledge.Name)
  IntSort(Int)
  App(Sort, Sort)
} derive(Eq, Hash, Debug)

///|
pub fn Sort::sym(name : @knowledge.Name) -> Sort {
  Sym(name)
}

///|
pub fn Sort::int(width : Int) -> Sort {
  IntSort(width)
}

///|
pub fn Sort::app(lhs : Sort, rhs : Sort) -> Sort {
  App(lhs, rhs)
}

///|
pub fn Sort::arrow(lhs : Sort, rhs : Sort) -> Sort {
  App(App(Sym(@knowledge.Name::create("arrow", pkg="core")), lhs), rhs)
}

///|
pub fn Sort::bool() -> Sort {
  Sym(@knowledge.Name::create("bool", pkg="core"))
}

///|
pub fn Sort::bitv(width : Int) -> Sort {
  App(Sym(@knowledge.Name::create("bitv", pkg="core")), IntSort(width))
}

///|
pub fn Sort::mem(keys : Sort, values : Sort) -> Sort {
  App(App(Sym(@knowledge.Name::create("mem", pkg="core")), keys), values)
}

///|
pub fn Sort::float(width : Int) -> Sort {
  App(Sym(@knowledge.Name::create("float", pkg="core")), IntSort(width))
}

///|
pub fn Sort::rmode() -> Sort {
  Sym(@knowledge.Name::create("rmode", pkg="core"))
}

///|
pub fn Sort::same(self : Sort, other : Sort) -> Bool {
  self == other
}

///|
fn core_sort_name(text : String) -> @knowledge.Name {
  @knowledge.Name::create(text, pkg="core")
}

///|
pub fn Sort::persistent() -> @knowledge.Persistent[Sort] {
  let name_codec = @knowledge.Persistent::name()
  let int_codec = @knowledge.Persistent::int()
  let fields_codec = persistent_string_fields()
  @knowledge.Persistent::convert(
    to_persistent=sort => {
      match sort {
        Sym(name) => ["sym", name_codec.encode(name)]
        IntSort(width) => ["int", int_codec.encode(width)]
        App(lhs, rhs) =>
          [
            "app",
            Sort::persistent().encode(lhs),
            Sort::persistent().encode(rhs),
          ]
      }
    },
    of_persistent=fields => {
      match fields {
        ["sym", encoded] =>
          match name_codec.decode(encoded) {
            Ok(name) => Ok(Sym(name))
            Err(reason) => Err(reason)
          }
        ["int", encoded] =>
          match int_codec.decode(encoded) {
            Ok(width) => Ok(IntSort(width))
            Err(reason) => Err(reason)
          }
        ["app", encoded_lhs, encoded_rhs] => {
          let lhs = match Sort::persistent().decode(encoded_lhs) {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          let rhs = match Sort::persistent().decode(encoded_rhs) {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          Ok(App(lhs, rhs))
        }
        _ => Err("invalid persistent sort encoding")
      }
    },
    fields_codec,
  )
}

///|
pub fn Sort::name(self : Sort) -> @knowledge.Name? {
  match self {
    Sym(name) => Some(name)
    App(head, _) => head.name()
    IntSort(_) => None
  }
}

///|
pub fn Sort::value(self : Sort) -> Int? {
  match self {
    IntSort(value) => Some(value)
    _ => None
  }
}

///|
pub fn Sort::forget(self : Sort) -> Sort {
  self
}

///|
pub fn Sort::refine(self : Sort, witness : @knowledge.Name) -> Sort? {
  match self {
    Sym(name) if name == witness => Some(self)
    App(_, _) if self.name() == Some(witness) => Some(self)
    _ => None
  }
}

///|
pub fn Sort::refine_bool(self : Sort) -> Sort? {
  self.refine(core_sort_name("bool"))
}

///|
pub fn Sort::refine_bitv(self : Sort) -> Sort? {
  self.refine(core_sort_name("bitv"))
}

///|
pub fn Sort::bitv_size(self : Sort) -> Int? {
  match self.refine_bitv() {
    Some(sort) =>
      match sort.tail() {
        [IntSort(width)] => Some(width)
        _ => None
      }
    None => None
  }
}

///|
pub fn Sort::refine_mem(self : Sort) -> Sort? {
  self.refine(core_sort_name("mem"))
}

///|
pub fn Sort::mem_keys(self : Sort) -> Sort? {
  match self.refine_mem() {
    Some(sort) =>
      match sort.tail() {
        [keys, _] => Some(keys)
        _ => None
      }
    None => None
  }
}

///|
pub fn Sort::mem_values(self : Sort) -> Sort? {
  match self.refine_mem() {
    Some(sort) =>
      match sort.tail() {
        [_, values] => Some(values)
        _ => None
      }
    None => None
  }
}

///|
pub fn Sort::refine_float(self : Sort) -> Sort? {
  self.refine(core_sort_name("float"))
}

///|
pub fn Sort::float_width(self : Sort) -> Int? {
  match self.refine_float() {
    Some(sort) =>
      match sort.tail() {
        [IntSort(width)] => Some(width)
        _ => None
      }
    None => None
  }
}

///|
pub fn Sort::refine_rmode(self : Sort) -> Sort? {
  self.refine(core_sort_name("rmode"))
}

///|
pub fn Sort::head(self : Sort) -> Sort {
  match self {
    App(head, _) => head.head()
    _ => self
  }
}

///|
pub fn Sort::tail(self : Sort) -> Array[Sort] {
  match self {
    App(head, arg) => {
      let args = head.tail()
      args.push(arg)
      args
    }
    _ => []
  }
}

///|
pub fn Sort::to_string(self : Sort) -> String {
  match self {
    Sym(name) => name.show()
    IntSort(width) => width.to_string()
    App(head, arg) => "\{head.to_string()}<\{arg.to_string()}>"
  }
}
