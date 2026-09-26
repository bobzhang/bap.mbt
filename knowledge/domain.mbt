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
pub fn[T] Domain::custom(
  name : Name,
  inspect : (T) -> String,
  empty~ : T,
  order~ : (T, T) -> PartialOrder,
  join? : (T, T) -> Result[T, String] = (lhs, rhs) => {
    match order(lhs, rhs) {
      Greater => Ok(lhs)
      Equal | Less => Ok(rhs)
      Incomparable =>
        Err(
          "domain \{name.show()} has no join for \{inspect(lhs)} and \{inspect(rhs)}",
        )
    }
  },
) -> Domain[T] {
  Domain::new(
    name~,
    empty=Some(empty),
    is_empty=(value : T) => order(empty, value) == Equal,
    order~,
    join~,
    inspect~,
  )
}

///|
fn[T : Eq] flat_default_join(
  name : Name,
  empty : T?,
  lhs : T,
  rhs : T,
) -> Result[T, String] {
  let is_empty = value => {
    match empty {
      Some(bottom) => value == bottom
      None => false
    }
  }
  if lhs == rhs || is_empty(rhs) {
    Ok(lhs)
  } else if is_empty(lhs) {
    Ok(rhs)
  } else {
    Err("conflicting values in flat domain \{name.show()}")
  }
}

///|
pub fn[T : Eq] Domain::flat(
  name : Name,
  inspect : (T) -> String,
  empty? : T,
  join? : (T, T) -> Result[T, String] = (lhs, rhs) => {
    flat_default_join(name, empty, lhs, rhs)
  },
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
    join~,
    inspect~,
  )
}

///|
fn[T] total_default_join(
  compare : (T, T) -> Int,
  lhs : T,
  rhs : T,
) -> Result[T, String] {
  if compare(lhs, rhs) <= 0 {
    Ok(rhs)
  } else {
    Ok(lhs)
  }
}

///|
pub fn[T] Domain::total(
  name : Name,
  inspect : (T) -> String,
  empty~ : T,
  compare~ : (T, T) -> Int,
  join? : (T, T) -> Result[T, String] = (lhs, rhs) => {
    total_default_join(compare, lhs, rhs)
  },
) -> Domain[T] {
  Domain::new(
    name~,
    empty=Some(empty),
    is_empty=(value : T) => compare(value, empty) == 0,
    order=(lhs : T, rhs : T) => {
      let order = compare(lhs, rhs)
      if order < 0 {
        Less
      } else if order > 0 {
        Greater
      } else {
        Equal
      }
    },
    join~,
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
        (Some(l), Some(r)) =>
          if base.order(l, r) == Equal {
            Equal
          } else {
            Incomparable
          }
      }
    },
    join=(lhs, rhs) => {
      match (lhs, rhs) {
        (None, value) => Ok(value)
        (value, None) => Ok(value)
        (Some(l), Some(r)) =>
          if base.order(l, r) == Equal {
            Ok(Some(r))
          } else {
            Err(
              "domain \{base.name().show()}? has no join for \{base.inspect(l)} and \{base.inspect(r)}",
            )
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
pub fn Domain::tribool(name? : Name) -> Domain[Bool?] {
  let name = match name {
    Some(value) => value
    None => Name::create("bool")
  }
  Domain::new(
    name~,
    empty=Some(None),
    is_empty=(value : Bool?) => value is None,
    order=(lhs : Bool?, rhs : Bool?) => {
      match (lhs, rhs) {
        (None, None) => Equal
        (None, Some(_)) => Less
        (Some(_), None) => Greater
        (Some(l), Some(r)) => if l == r { Equal } else { Incomparable }
      }
    },
    join=(lhs : Bool?, rhs : Bool?) => {
      match (lhs, rhs) {
        (None, value) => Ok(value)
        (value, None) => Ok(value)
        (Some(l), Some(r)) =>
          if l == r {
            Ok(Some(r))
          } else {
            Err("domain \{name.show()} has no join for \{l} and \{r}")
          }
      }
    },
    inspect=(value : Bool?) => {
      match value {
        Some(inner) => inner.to_string()
        None => "none"
      }
    },
  )
}

///|
pub fn Domain::string(name : Name) -> Domain[String] {
  Domain::custom(name, value => value, empty="", order=(lhs, rhs) => {
    match (lhs == "", rhs == "") {
      (true, true) => Equal
      (true, false) => Greater
      (false, true) => Less
      (false, false) => {
        let order = lhs.compare(rhs)
        if order > 0 {
          Less
        } else if order < 0 {
          Greater
        } else {
          Equal
        }
      }
    }
  })
}

///|
/// `Domain.obj cls`: objects of the class ordered totally by their
/// identifiers, with the null object as the bottom (upstream derives it
/// with `Domain.total ~empty:Oid.zero ~order:Oid.compare`).
pub fn[K, S] Domain::obj(cls : Class[K, S]) -> Domain[Object[K]] {
  Domain::total(cls.name(), value => value.repr(), empty=Object::null(cls), compare=(
    lhs : Object[K],
    rhs : Object[K],
  ) => lhs.id().compare(rhs.id()))
}

///|
fn[K : Eq + Hash, T] map_values_equal(
  lhs : Map[K, T],
  rhs : Map[K, T],
  equal : (T, T) -> Bool,
) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for entry in lhs {
    match rhs.get(entry.0) {
      Some(value) if equal(entry.1, value) => ()
      _ => return false
    }
  }
  true
}

///|
fn[K : Eq + Hash, T] map_values_leq(
  lhs : Map[K, T],
  rhs : Map[K, T],
  equal : (T, T) -> Bool,
) -> Bool {
  for entry in lhs {
    match rhs.get(entry.0) {
      Some(value) if equal(entry.1, value) => ()
      _ => return false
    }
  }
  true
}

///|
fn[K : Eq + Hash, T] map_join_values(
  lhs : Map[K, T],
  rhs : Map[K, T],
  join : (T, T) -> Result[T, String],
) -> Result[Map[K, T], String] {
  let result : Map[K, T] = Map([])
  for entry in lhs {
    result[entry.0] = entry.1
  }
  for entry in rhs {
    match result.get(entry.0) {
      Some(value) =>
        match join(value, entry.1) {
          Ok(joined) => result[entry.0] = joined
          Err(reason) => return Err(reason)
        }
      None => result[entry.0] = entry.1
    }
  }
  Ok(result)
}

///|
pub fn[K : Eq + Hash, T] Domain::mapping(
  name : Name,
  inspect_key : (K) -> String,
  inspect_value : (T) -> String,
  equal~ : (T, T) -> Bool,
  join? : (T, T) -> Result[T, String] = (lhs, rhs) => {
    if equal(lhs, rhs) {
      Ok(rhs)
    } else {
      Err(
        "mapping domain \{name.show()} has no join for \{inspect_value(lhs)} and \{inspect_value(rhs)}",
      )
    }
  },
) -> Domain[Map[K, T]] {
  let empty : Map[K, T] = Map([])
  Domain::new(
    name~,
    empty=Some(empty),
    is_empty=(value : Map[K, T]) => value.length() == 0,
    order=(lhs : Map[K, T], rhs : Map[K, T]) => {
      if map_values_equal(lhs, rhs, equal) {
        Equal
      } else {
        let lhs_le_rhs = map_values_leq(lhs, rhs, equal)
        let rhs_le_lhs = map_values_leq(rhs, lhs, equal)
        if lhs_le_rhs {
          Less
        } else if rhs_le_lhs {
          Greater
        } else {
          Incomparable
        }
      }
    },
    join=(lhs : Map[K, T], rhs : Map[K, T]) => map_join_values(lhs, rhs, join),
    inspect=(value : Map[K, T]) => {
      let keys = []
      for entry in value {
        keys.push(inspect_key(entry.0))
      }
      keys.sort_by((lhs, rhs) => lhs.compare(rhs))
      "(\{keys.join(" ")})"
    },
  )
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
fn[T : Eq + Hash] set_subset(lhs : Set[T], rhs : Set[T]) -> Bool {
  for item in lhs {
    if !rhs.contains(item) {
      return false
    }
  }
  true
}

///|
fn[T : Eq + Hash] set_union(lhs : Set[T], rhs : Set[T]) -> Set[T] {
  let result : Set[T] = Set([])
  for item in lhs {
    result.add(item)
  }
  for item in rhs {
    result.add(item)
  }
  result
}

///|
pub fn[T : Eq + Hash] Domain::set(
  name : Name,
  inspect : (T) -> String,
) -> Domain[Set[T]] {
  let empty : Set[T] = Set([])
  Domain::new(
    name~,
    empty=Some(empty),
    is_empty=(value : Set[T]) => value.is_empty(),
    order=(lhs : Set[T], rhs : Set[T]) => {
      let lhs_le_rhs = set_subset(lhs, rhs)
      let rhs_le_lhs = set_subset(rhs, lhs)
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
    join=(lhs : Set[T], rhs : Set[T]) => Ok(set_union(lhs, rhs)),
    inspect=(value : Set[T]) => {
      let items = []
      for item in value {
        items.push(inspect(item))
      }
      items.sort_by((lhs, rhs) => lhs.compare(rhs))
      "{\{items.join(", ")}}"
    },
  )
}

///|
pub fn[T] Domain::opinions(
  name : Name,
  empty~ : T,
  equal~ : (T, T) -> Bool,
  inspect~ : (T) -> String,
) -> Domain[Opinions[T]] {
  Domain::new(
    name~,
    empty=Some(Opinions::empty(empty~, equal~, inspect~)),
    is_empty=(value : Opinions[T]) => value.is_empty(),
    order=(lhs : Opinions[T], rhs : Opinions[T]) => {
      let order = lhs.compare_votes(rhs)
      if order < 0 {
        Less
      } else if order > 0 {
        Greater
      } else {
        Equal
      }
    },
    join=(lhs : Opinions[T], rhs : Opinions[T]) => Ok(lhs.join(rhs)),
    inspect=(value : Opinions[T]) => value.inspect(),
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
