///|
/// The phantom kind of the class of Core Theory values (`Value.cls`).
///
/// Objects and slots of the value class are indexed by this type, so that
/// properties of values (e.g., the BIL expression of a value) can not be
/// confused with properties of other classes.
pub enum ValueCls {}

///|
/// A denotation of an expression (`Theory.Value.t`).
///
/// A value is a knowledge value of the class `core:value` refined by the
/// sort of the expression: an extensible record whose fields are the
/// properties of the value class (declared by any theory with
/// `Value::cls().property(...)`), plus the sort. Different theories
/// contribute different properties of the same value, which are joined
/// independently (see `Theory.join`).
struct Value(@knowledge.Value[ValueCls, Sort])

///|
let value_cls : @knowledge.Class[ValueCls, Unit] = @knowledge.Class::create(
  name=core_name("value"),
  sort=(),
  desc="the denotation of an expression",
  public=true,
)

///|
/// `Value.cls`: the class of all values.
pub fn Value::cls() -> @knowledge.Class[ValueCls, Unit] {
  value_cls
}

///|
/// The class of values of the given sort (`KB.Class.refine cls s`).
pub fn Value::sorted_cls(sort : Sort) -> @knowledge.Class[ValueCls, Sort] {
  value_cls.refine(sort~)
}

///|
/// Wraps a knowledge value of the value class.
pub fn Value::of_kb(value : @knowledge.Value[ValueCls, Sort]) -> Value {
  Value(value)
}

///|
/// The underlying knowledge value.
pub fn Value::kb(self : Value) -> @knowledge.Value[ValueCls, Sort] {
  self.0
}

///|
/// `Value.empty s`: the value of sort `s` with no properties.
pub fn Value::empty(sort : Sort) -> Value {
  Value(@knowledge.Value::empty(Value::sorted_cls(sort)))
}

///|
/// `Value.sort v`: the sort of the value.
pub fn Value::sort(self : Value) -> Sort {
  self.0.cls().sort()
}

///|
/// `KB.Value.refine v s`: the same value (with the same properties and
/// time-stamp) with the sort changed to `s`, unchecked.
pub fn Value::refine(self : Value, sort : Sort) -> Value {
  Value(self.0.refine(sort))
}

///|
/// `Value.resort refine v`: the same value with the sort refined by
/// `refine`, or `None` if the refinement fails.
pub fn Value::resort(self : Value, refine : (Sort) -> Sort?) -> Value? {
  match refine(self.sort().forget()) {
    Some(sort) => Some(self.refine(sort))
    None => None
  }
}

///|
/// `Value.forget v`: the value with the sort forgotten (sorts are not
/// statically indexed in the port, so this is the identity).
pub fn Value::forget(self : Value) -> Value {
  self.refine(self.sort().forget())
}

///|
/// `Match.can refine v f`: applies `action` to `v` if its sort refines.
pub fn[A] Value::match_can(
  self : Value,
  refine : (Sort) -> Sort?,
  action : (Value) -> A,
  otherwise : () -> A,
) -> A {
  match self.resort(refine) {
    Some(value) => action(value)
    None => otherwise()
  }
}

///|
/// Alias of `Value::match_can`.
pub fn[A] Value::can(
  self : Value,
  refine : (Sort) -> Sort?,
  action : (Value) -> A,
  otherwise : () -> A,
) -> A {
  self.match_can(refine, action, otherwise)
}

///|
/// `Match.both`: applies `action` if the sorts of both values refine.
pub fn[A] Value::match_both(
  self : Value,
  refine_self : (Sort) -> Sort?,
  other : Value,
  refine_other : (Sort) -> Sort?,
  action : (Value, Value) -> A,
  otherwise : () -> A,
) -> A {
  match (self.resort(refine_self), other.resort(refine_other)) {
    (Some(lhs), Some(rhs)) => action(lhs, rhs)
    _ => otherwise()
  }
}

///|
/// Alias of `Value::match_both`.
pub fn[A] Value::both(
  self : Value,
  refine_self : (Sort) -> Sort?,
  other : Value,
  refine_other : (Sort) -> Sort?,
  action : (Value, Value) -> A,
  otherwise : () -> A,
) -> A {
  self.match_both(refine_self, other, refine_other, action, otherwise)
}

///|
/// `KB.Value.get p v`: the property `p` of the value (or its empty value).
pub fn[P] Value::get(self : Value, slot : @knowledge.Slot[ValueCls, P]) -> P {
  self.0.get(slot)
}

///|
/// The property `p` of the value, if it was set.
pub fn[P] Value::find(self : Value, slot : @knowledge.Slot[ValueCls, P]) -> P? {
  self.0.find(slot)
}

///|
/// `KB.Value.put p v x`: the value with the property `p` set to `x`.
pub fn[P] Value::put(
  self : Value,
  slot : @knowledge.Slot[ValueCls, P],
  value : P,
) -> Value {
  Value(self.0.put(slot, value))
}

///|
/// `KB.Value.has p v`: the property `p` is not empty.
pub fn[P] Value::has(self : Value, slot : @knowledge.Slot[ValueCls, P]) -> Bool {
  self.0.has(slot)
}

///|
/// `v.![p]`: the property `p`, rejecting (with `Empty`) if it is empty.
pub fn[P] Value::require(
  self : Value,
  slot : @knowledge.Slot[ValueCls, P],
) -> P raise @knowledge.Conflict {
  self.0.require(slot)
}

///|
/// `v.?[p]`: the optional property `p`, rejecting if it is `None`.
pub fn[P] Value::require_some(
  self : Value,
  slot : @knowledge.Slot[ValueCls, P?],
) -> P raise @knowledge.Conflict {
  self.0.require_some(slot)
}

///|
/// All properties of the value are empty.
pub fn Value::is_empty(self : Value) -> Bool {
  self.0.is_empty()
}

///|
/// `KB.Value.join x y`: joins the properties of `x` and `y` pairwise,
/// keeping the sort of `x`. Raises `JoinConflict` if a pair of properties
/// is not joinable.
pub fn Value::join(
  self : Value,
  other : Value,
) -> Value raise @knowledge.Conflict {
  Value(self.0.join(other.0))
}

///|
/// `KB.Value.merge x y`: joins the properties of `x` and `y`, resolving
/// conflicts with `on_conflict` (the newer property wins by default). The
/// sort of `x` is kept.
pub fn Value::merge(
  self : Value,
  other : Value,
  on_conflict~ : @knowledge.MergeStrategy = DropOld,
) -> Value {
  Value(self.0.merge(other.0, on_conflict~))
}

///|
/// Orders values by their information content.
pub fn Value::order(self : Value, other : Value) -> @knowledge.PartialOrder {
  self.0.order(other.0)
}

///|
/// Values are equal if they have the same sort and the same properties.
pub fn Value::equal(self : Value, other : Value) -> Bool {
  self.sort() == other.sort() && self.0.equal(other.0)
}

///|
/// A total order: by sort, then by the knowledge value order.
pub fn Value::compare(self : Value, other : Value) -> Int32 {
  let order = self.sort().to_string().compare(other.sort().to_string())
  if order != 0 {
    order
  } else {
    self.0.compare(other.0)
  }
}

///|
/// Renders the sort and the properties of the value.
pub fn Value::to_string(self : Value) -> String {
  if self.0.is_empty() {
    self.sort().to_string()
  } else {
    "\{self.sort().to_string()}:\{self.0.inspect()}"
  }
}

///|
fn is_top_sort(sort : Sort) -> Bool {
  sort == Sort::top()
}

///|
/// The domain of values (`Value.Top.domain`): the empty value of the top
/// sort is the bottom and values are joined property-wise.
///
/// Upstream the joined value keeps the class (and so the sort) of the
/// left operand; the port keeps the sort of the right operand when the
/// left one is the (sort-less) top sort, so that storing a value in an
/// empty slot does not forget its sort.
let value_domain : @knowledge.Domain[Value] = {
  let empty = Value::empty(Sort::top())
  @knowledge.Domain::new(
    name=core_name("value"),
    empty=Some(empty),
    is_empty=value => value.is_empty(),
    order=(lhs, rhs) => lhs.order(rhs),
    join=(lhs, rhs) => {
      let (lhs, rhs) = if is_top_sort(lhs.sort()) && !is_top_sort(rhs.sort()) {
        (lhs.refine(rhs.sort()), rhs)
      } else {
        (lhs, rhs)
      }
      try lhs.join(rhs) catch {
        error => Err(@knowledge.Conflict::to_string(error))
      } noraise {
        value => Ok(value)
      }
    },
    inspect=value => value.to_string(),
  )
}

///|
/// `Value.Top.domain`.
pub fn Value::domain() -> @knowledge.Domain[Value] {
  value_domain
}

///|
let value_persistent : @knowledge.Persistent[Value] = {
  let sort_codec = Sort::persistent()
  let data_codec = @knowledge.Value::persistent(Value::sorted_cls(Sort::top()))
  @knowledge.Persistent::convert(
    to_persistent=value => {
      [sort_codec.encode(value.sort()), data_codec.encode(value.0)]
    },
    of_persistent=fields => {
      match persistent_decode_fields(fields, 2, "value") {
        Ok(_) => ()
        Err(reason) => return Err(reason)
      }
      let sort = match sort_codec.decode(fields[0]) {
        Ok(sort) => sort
        Err(reason) => return Err(reason)
      }
      match data_codec.decode(fields[1]) {
        Ok(data) => Ok(Value(data.refine(sort)))
        Err(reason) => Err(reason)
      }
    },
    persistent_string_fields(),
  )
}

///|
/// Persists the sort and the persistent properties of a value.
pub fn Value::persistent() -> @knowledge.Persistent[Value] {
  value_persistent
}
