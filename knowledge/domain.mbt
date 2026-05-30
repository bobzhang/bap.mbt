///|
struct Domain[T] {
  name : Name
  empty_value : T?
  is_empty_fn : (T) -> Bool
  order_fn : (T, T) -> PartialOrder
  join_fn : (T, T) -> Result[T, String]
  inspect_fn : (T) -> String
}

///|
pub fn[T] Domain::new(
  name~ : Name,
  empty~ : T?,
  is_empty~ : (T) -> Bool,
  order~ : (T, T) -> PartialOrder,
  join~ : (T, T) -> Result[T, String],
  inspect~ : (T) -> String,
) -> Domain[T] {
  {
    name,
    empty_value: empty,
    is_empty_fn: is_empty,
    order_fn: order,
    join_fn: join,
    inspect_fn: inspect,
  }
}

///|
pub fn[T : Eq] Domain::flat(
  name : Name,
  inspect : (T) -> String,
  empty? : T,
) -> Domain[T] {
  let is_empty = value => {
    match empty {
      Some(bottom) => value == bottom
      None => false
    }
  }
  Domain::new(
    name~,
    empty~,
    is_empty~,
    order=(lhs, rhs) => {
      if lhs == rhs {
        Equal
      } else if is_empty(lhs) {
        Less
      } else if is_empty(rhs) {
        Greater
      } else {
        Incomparable
      }
    },
    join=(lhs, rhs) => {
      if lhs == rhs || is_empty(rhs) {
        Ok(lhs)
      } else if is_empty(lhs) {
        Ok(rhs)
      } else {
        Err("conflicting values in flat domain \{name.show()}")
      }
    },
    inspect~,
  )
}

///|
pub fn[T] Domain::optional(base : Domain[T]) -> Domain[T?] {
  Domain::new(
    name=Name::create("\{base.name.unqualified()}?", pkg=base.name.pkg()),
    empty=Some(None),
    is_empty=(value : T?) => value is None,
    order=(lhs, rhs) => {
      match (lhs, rhs) {
        (None, None) => Equal
        (None, Some(_)) => Less
        (Some(_), None) => Greater
        (Some(l), Some(r)) => base.order(l, r)
      }
    },
    join=(lhs, rhs) => {
      match (lhs, rhs) {
        (None, value) => Ok(value)
        (value, None) => Ok(value)
        (Some(l), Some(r)) =>
          match base.join(l, r) {
            Ok(value) => Ok(Some(value))
            Err(reason) => Err(reason)
          }
      }
    },
    inspect=(value : T?) => {
      match value {
        Some(inner) => "some(\{base.inspect(inner)})"
        None => "none"
      }
    },
  )
}

///|
pub fn Domain::bool(name : Name) -> Domain[Bool] {
  Domain::new(
    name~,
    empty=Some(false),
    is_empty=(value : Bool) => !value,
    order=(lhs : Bool, rhs : Bool) => {
      if lhs == rhs {
        Equal
      } else if !lhs && rhs {
        Less
      } else {
        Greater
      }
    },
    join=(lhs : Bool, rhs : Bool) => Ok(lhs || rhs),
    inspect=(value : Bool) => value.to_string(),
  )
}

///|
pub fn Domain::string(name : Name) -> Domain[String] {
  Domain::flat(name, value => value, empty="")
}

///|
fn[T : Eq] array_subset(lhs : Array[T], rhs : Array[T]) -> Bool {
  lhs.all(item => rhs.contains(item))
}

///|
fn[T : Eq] array_union(lhs : Array[T], rhs : Array[T]) -> Array[T] {
  let result = []
  for item in lhs {
    if !result.contains(item) {
      result.push(item)
    }
  }
  for item in rhs {
    if !result.contains(item) {
      result.push(item)
    }
  }
  result
}

///|
pub fn[T : Eq] Domain::powerset(
  name : Name,
  inspect : (T) -> String,
) -> Domain[Array[T]] {
  let empty : Array[T] = []
  Domain::new(
    name~,
    empty=Some(empty),
    is_empty=(value : Array[T]) => value.is_empty(),
    order=(lhs : Array[T], rhs : Array[T]) => {
      let lhs_le_rhs = array_subset(lhs, rhs)
      let rhs_le_lhs = array_subset(rhs, lhs)
      if lhs_le_rhs && rhs_le_lhs {
        Equal
      } else if lhs_le_rhs {
        Less
      } else if rhs_le_lhs {
        Greater
      } else {
        Incomparable
      }
    },
    join=(lhs : Array[T], rhs : Array[T]) => Ok(array_union(lhs, rhs)),
    inspect=(value : Array[T]) => {
      "[\{[ for item in value => inspect(item) ].join(", ")}]"
    },
  )
}

///|
pub fn[T] Domain::name(self : Domain[T]) -> Name {
  self.name
}

///|
pub fn[T] Domain::empty(self : Domain[T]) -> T? {
  self.empty_value
}

///|
pub fn[T] Domain::is_empty(self : Domain[T], value : T) -> Bool {
  (self.is_empty_fn)(value)
}

///|
pub fn[T] Domain::order(self : Domain[T], lhs : T, rhs : T) -> PartialOrder {
  (self.order_fn)(lhs, rhs)
}

///|
pub fn[T] Domain::join(self : Domain[T], lhs : T, rhs : T) -> Result[T, String] {
  (self.join_fn)(lhs, rhs)
}

///|
pub fn[T] Domain::inspect(self : Domain[T], value : T) -> String {
  (self.inspect_fn)(value)
}
