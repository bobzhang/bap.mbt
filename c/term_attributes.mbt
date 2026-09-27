// Port of BAP `lib/bap_c/bap_c_term_attributes.ml` (BIR attributes).
//
// Upstream registers typed `Value.Tag`s (`c.data`, `c.layout`, `c.type`,
// `c.proto`). Term attributes in this port are string key/value pairs, so a
// `TermTag[A]` couples an attribute key with a lossless JSON codec for `A`.

///|
/// A typed term attribute stored under a string key.
pub struct TermTag[A] {
  name : String
  priv encode : (A) -> String
  priv decode : (String) -> A?
}

///|
/// The attribute key.
pub fn[A] TermTag::name(self : TermTag[A]) -> String {
  self.name
}

///|
/// Encodes `value` as a term attribute.
pub fn[A] TermTag::attr(self : TermTag[A], value : A) -> @types.Attr {
  @types.Attr::new(key=self.name, value=(self.encode)(value))
}

///|
/// Decodes an attribute value; `None` if it is malformed.
pub fn[A] TermTag::decode(self : TermTag[A], value : String) -> A? {
  (self.decode)(value)
}

///|
/// Attaches `value` to `term` (upstream `Term.set_attr term tag value`).
pub fn[T, A] TermTag::set(
  self : TermTag[A],
  term : @types.Term[T],
  value : A,
) -> @types.Term[T] {
  term.set_attr(self.attr(value))
}

///|
/// The value attached to `term` (upstream `Term.get_attr term tag`).
pub fn[T, A] TermTag::get(self : TermTag[A], term : @types.Term[T]) -> A? {
  match term.get_attr(self.name) {
    None => None
    Some(value) => (self.decode)(value)
  }
}

///|
/// `true` if `term` has this attribute.
pub fn[T, A] TermTag::has(self : TermTag[A], term : @types.Term[T]) -> Bool {
  term.has_attr(self.name)
}

///|
fn[A : FromJson] decode_json(value : String) -> A? {
  try @json.from_json(@json.parse(value)) catch {
    _ => None
  } noraise {
    x => Some(x)
  }
}

///|
/// The abstraction of the data representation of a C value
/// (`c.data`). It is attached to each inserted arg term.
pub fn data_tag() -> TermTag[Data] {
  {
    name: "c.data",
    encode: d => data_to_json(d).stringify(),
    decode: s => {
      let json = @json.parse(s) catch { _ => return None }
      data_of_json(json)
    },
  }
}

///|
/// The layout of a C object (`c.layout`).
pub fn layout_tag() -> TermTag[Layout] {
  {
    name: "c.layout",
    encode: l => layout_to_json(l).stringify(),
    decode: s => {
      let json = @json.parse(s) catch { _ => return None }
      layout_of_json(json)
    },
  }
}

///|
/// The C type associated with a term (`c.type`). It is attached to each
/// inserted arg term.
pub fn type_tag() -> TermTag[CType] {
  { name: "c.type", encode: t => t.to_json().stringify(), decode: decode_json, }
}

///|
/// The function prototype (`c.proto`), attached to each annotated
/// subroutine.
pub fn proto_tag() -> TermTag[Proto] {
  {
    name: "c.proto",
    encode: p => p.to_json().stringify(),
    decode: decode_json,
  }
}

///|
fn word_to_json(w : @types.Word) -> Json {
  [Json::number(w.bitwidth().to_double()), Json::string(w.to_hex(prefix=false))]
}

///|
fn word_of_json(json : Json) -> @types.Word? {
  guard json is [Number(width, ..), String(hex)] else { return None }
  try @types.Word::from_hex(width=width.to_int(), hex) catch {
    _ => None
  } noraise {
    w => Some(w)
  }
}

///|
fn data_to_json(d : Data) -> Json {
  match d {
    Imm(size, value) => {
      let value = match value {
        Top => Json::string("Top")
        Set(ws) => [Json::string("Set"), Json::array(ws.map(word_to_json))]
      }
      [Json::string("Imm"), Json::number(size.in_bits().to_double()), value]
    }
    Seq(xs) => [Json::string("Seq"), Json::array(xs.map(data_to_json))]
    Ptr(x) => [Json::string("Ptr"), data_to_json(x)]
  }
}

///|
fn data_of_json(json : Json) -> Data? {
  match json {
    [String("Imm"), Number(bits, ..), value] => {
      guard @types.Size::of_int_opt(bits.to_int()) is Some(size) else {
        return None
      }
      match value {
        String("Top") => Some(Imm(size, Top))
        [String("Set"), Array(ws)] => {
          let words = []
          for w in ws {
            guard word_of_json(w) is Some(w) else { return None }
            words.push(w)
          }
          Some(Imm(size, Set(words)))
        }
        _ => None
      }
    }
    [String("Seq"), Array(xs)] => {
      let items = []
      for x in xs {
        guard data_of_json(x) is Some(x) else { return None }
        items.push(x)
      }
      Some(Seq(items))
    }
    [String("Ptr"), x] =>
      match data_of_json(x) {
        Some(x) => Some(Ptr(x))
        None => None
      }
    _ => None
  }
}

///|
fn layout_to_json(l : Layout) -> Json {
  layout_datum_to_json(l.layout)
}

///|
fn layout_datum_to_json(d : Datum[Obj[Layout], Int]) -> Json {
  match d {
    Imm(size, obj) => {
      let obj : Json = match obj {
        Basic(t) => [Json::string("Basic"), t.to_json()]
        Field(name, l) =>
          [Json::string("Field"), Json::string(name), layout_to_json(l)]
        Undef => Json::string("Undef")
        Union(xs) =>
          [Json::string("Union"), Json::array(xs.map(layout_to_json))]
      }
      [Json::string("Imm"), Json::number(size.to_double()), obj]
    }
    Seq(xs) => [Json::string("Seq"), Json::array(xs.map(layout_datum_to_json))]
    Ptr(x) => [Json::string("Ptr"), layout_datum_to_json(x)]
  }
}

///|
fn layout_of_json(json : Json) -> Layout? {
  match layout_datum_of_json(json) {
    Some(layout) => Some({ layout, })
    None => None
  }
}

///|
fn layout_datum_of_json(json : Json) -> Datum[Obj[Layout], Int]? {
  match json {
    [String("Imm"), Number(size, ..), obj] => {
      let obj : Obj[Layout] = match obj {
        [String("Basic"), t] => {
          let t : Basic = @json.from_json(t) catch { _ => return None }
          Basic(t)
        }
        [String("Field"), String(name), l] => {
          guard layout_of_json(l) is Some(l) else { return None }
          Field(name, l)
        }
        String("Undef") => Undef
        [String("Union"), Array(xs)] => {
          let items = []
          for x in xs {
            guard layout_of_json(x) is Some(x) else { return None }
            items.push(x)
          }
          Union(items)
        }
        _ => return None
      }
      Some(Imm(size.to_int(), obj))
    }
    [String("Seq"), Array(xs)] => {
      let items = []
      for x in xs {
        guard layout_datum_of_json(x) is Some(x) else { return None }
        items.push(x)
      }
      Some(Seq(items))
    }
    [String("Ptr"), x] =>
      match layout_datum_of_json(x) {
        Some(x) => Some(Ptr(x))
        None => None
      }
    _ => None
  }
}
