// The deep-mapping steps of the type mapper (upstream private `do_map_*`
// methods). They are public so that an overriding `map_T` can delegate to
// the default behavior (the equivalent of calling `super#map_T`) while still
// dispatching the nested elements through the overriding mapper.

///|
/// Maps a type by dispatching on its constructor. Specs are mapped as
/// upstream `map_spec`: the payload first, then the qualifier, then the
/// attributes.
pub fn[M : TypeMapper] default_map_type(mapper : M, t : CType) -> CType raise {
  match t {
    Void => mapper.map_void(Void)
    Array(s) => {
      let t = mapper.map_array(s.t)
      let qualifier = mapper.map_cvr_qualifier(s.qualifier)
      let attrs = mapper.map_attrs(s.attrs)
      Array({ t, qualifier, attrs, })
    }
    Basic(s) => {
      let t = mapper.map_basic(s.t)
      let qualifier = mapper.map_cv_qualifier(s.qualifier)
      let attrs = mapper.map_attrs(s.attrs)
      Basic({ t, qualifier, attrs, })
    }
    Pointer(s) => {
      let t = mapper.map_pointer(s.t)
      let qualifier = mapper.map_cvr_qualifier(s.qualifier)
      let attrs = mapper.map_attrs(s.attrs)
      Pointer({ t, qualifier, attrs, })
    }
    Function(s) => {
      let t = mapper.map_function(s.t)
      let attrs = mapper.map_attrs(s.attrs)
      Function({ t, qualifier: s.qualifier, attrs, })
    }
    Union(s) => {
      let t = mapper.map_union(s.t)
      let attrs = mapper.map_attrs(s.attrs)
      Union({ t, qualifier: s.qualifier, attrs, })
    }
    Structure(s) => {
      let t = mapper.map_structure(s.t)
      let attrs = mapper.map_attrs(s.attrs)
      Structure({ t, qualifier: s.qualifier, attrs, })
    }
  }
}

///|
/// Maps the element type of an array.
pub fn[M : TypeMapper] default_map_array(
  mapper : M,
  a : ArrayType,
) -> ArrayType raise {
  { element: mapper.map_type(a.element), size: a.size, }
}

///|
/// Maps the type referenced by a pointer.
pub fn[M : TypeMapper] default_map_pointer(
  mapper : M,
  t : CType,
) -> CType raise {
  mapper.map_type(t)
}

///|
/// Maps the return type, then the arguments.
pub fn[M : TypeMapper] default_map_function(
  mapper : M,
  p : Proto,
) -> Proto raise {
  let return_ = mapper.map_type(p.return_)
  let args = map_fields(mapper, p.args)
  { return_, args, variadic: p.variadic, }
}

///|
fn[M : TypeMapper] map_fields(
  mapper : M,
  fields : Array[(String, CType)],
) -> Array[(String, CType)] raise {
  let result = []
  for field in fields {
    let (n, t) = field
    let n = mapper.map_name(n)
    let t = mapper.map_type(t)
    result.push((n, t))
  }
  result
}

///|
fn[M : TypeMapper] map_compound(mapper : M, c : Compound) -> Compound raise {
  let fields = map_fields(mapper, c.fields)
  let name = mapper.map_name(c.name)
  { name, fields, }
}

///|
/// Maps the fields (name, then type), then the name of the union.
pub fn[M : TypeMapper] default_map_union(
  mapper : M,
  c : Compound,
) -> Compound raise {
  map_compound(mapper, c)
}

///|
/// Maps the fields (name, then type), then the name of the structure.
pub fn[M : TypeMapper] default_map_structure(
  mapper : M,
  c : Compound,
) -> Compound raise {
  map_compound(mapper, c)
}

///|
/// Dispatches a basic type to `map_integer` or `map_floating`.
pub fn[M : TypeMapper] default_map_basic(mapper : M, t : Basic) -> Basic raise {
  if t.is_integer() {
    mapper.map_integer(t)
  } else {
    mapper.map_floating(t)
  }
}

///|
/// Dispatches an integer type to `map_char`, `map_signed`, `map_unsigned`, or
/// `map_enum` (in this order, so `signed char` is a `char`).
pub fn[M : TypeMapper] default_map_integer(
  mapper : M,
  t : Basic,
) -> Basic raise {
  match t {
    Enum(fields) => Enum(mapper.map_enum(fields))
    t if t.is_char() => mapper.map_char(t)
    t if t.is_signed() => mapper.map_signed(t)
    t if t.is_unsigned() => mapper.map_unsigned(t)
    t => t
  }
}

///|
/// Dispatches a floating-point type to `map_real` or `map_complex`.
pub fn[M : TypeMapper] default_map_floating(
  mapper : M,
  t : Basic,
) -> Basic raise {
  if t.is_real() {
    mapper.map_real(t)
  } else if t.is_complex() {
    mapper.map_complex(t)
  } else {
    t
  }
}

///|
/// Maps every attribute with `map_attr`.
pub fn[M : TypeMapper] default_map_attrs(
  mapper : M,
  attrs : Array[Attr],
) -> Array[Attr] raise {
  let result = []
  for attr in attrs {
    result.push(mapper.map_attr(attr))
  }
  result
}

///|
/// A mapper that uses only the default methods, i.e., an identity mapper
/// (upstream `new C.Type.Mapper.base`).
pub(all) struct IdentityMapper {}

///|
pub impl TypeMapper for IdentityMapper

///|
/// Raised by `Search::finished` to abort the traversal.
pub suberror SearchFinished derive(Debug)

///|
/// A search with an early exit (upstream `C.Type.Mapper.Search` and the
/// `Finder` instantiation of the mapper).
///
/// Embed a `Search[E]` in a mapper, call `finished(x)` from any method when
/// the needle is found, and run the mapper with `Search::find`.
pub struct Search[E] {
  mut found : E?
}

///|
pub fn[E] Search::new() -> Search[E] {
  { found: None, }
}

///|
/// `finished(needle)` terminates the search with `needle` as the result.
pub fn[E] Search::finished(self : Search[E], needle : E) -> Unit raise {
  self.found = Some(needle)
  raise SearchFinished
}

///|
/// The needle found by the last search, if any.
pub fn[E] Search::result(self : Search[E]) -> E? {
  self.found
}

///|
/// Runs `mapper` on `t` and returns the found needle, if any. Errors other
/// than the search termination are propagated.
pub fn[E, M : TypeMapper] Search::find(
  self : Search[E],
  mapper : M,
  t : CType,
) -> E? raise {
  self.found = None
  try mapper.run(t) catch {
    SearchFinished => ()
    e => raise e
  } noraise {
    _ => ()
  }
  self.found
}
