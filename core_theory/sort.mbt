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
