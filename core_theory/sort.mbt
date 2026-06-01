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
