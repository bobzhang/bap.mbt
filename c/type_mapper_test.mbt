///|
fn sample_type() -> @c.CType {
  @c.CType::structure("node", [
    ("tag", @c.CType::basic(Enum([("A", None)]))),
    ("value", @c.CType::basic(attrs=[@c.Attr::new("aligned")], Double)),
    ("next", @c.CType::pointer(@c.CType::structure("node", []))),
    (
      "cb",
      @c.CType::pointer(
        @c.CType::function_(return_=@c.CType::basic(SChar), [
          ("x", @c.CType::array(size=2, @c.CType::basic(UInt))),
        ]),
      ),
    ),
  ])
}

///|
test "identity mapper" {
  let t = sample_type()
  assert_eq(@c.IdentityMapper::{ }.run(t), t)
}

///|
/// A mapper that prefixes names and turns every `double` into `float`.
struct Renamer {}

///|
impl @c.TypeMapper for Renamer with fn map_name(_self, name) {
  "my_" + name
}

///|
impl @c.TypeMapper for Renamer with fn map_real(_self, t) {
  match t {
    Double => Float
    t => t
  }
}

///|
test "mapper transforms nested elements" {
  let t = @c.TypeMapper::run(Renamer::{ }, sample_type())
  inspect(
    t,
    content=(
      #|struct my_node {
      #|    enum {
      #|    A,,
      #|}
      #| my_tag;
      #|     __attribute__((aligned)) float my_value;
      #|    struct my_node* my_next;
      #|    signed char (*)(unsigned[2] my_x);* my_cb;
      #|};
    ),
  )
}

///|
/// A visitor that records the order of events.
struct Tracer {
  events : Array[String]
}

///|
impl @c.TypeMapper for Tracer with fn enter_type(self, t) {
  self.events.push("enter " + t.to_string())
}

///|
impl @c.TypeMapper for Tracer with fn leave_pointer(self, _) {
  self.events.push("leave pointer")
}

///|
impl @c.TypeMapper for Tracer with fn enter_char(self, t) {
  self.events.push("char " + t.to_string())
}

///|
impl @c.TypeMapper for Tracer with fn enter_signed(self, t) {
  self.events.push("signed " + t.to_string())
}

///|
impl @c.TypeMapper for Tracer with fn enter_unsigned(self, t) {
  self.events.push("unsigned " + t.to_string())
}

///|
impl @c.TypeMapper for Tracer with fn enter_complex(self, t) {
  self.events.push("complex " + t.to_string())
}

///|
impl @c.TypeMapper for Tracer with fn enter_cvr_qualifier(self, q) {
  self.events.push("cvr const=\{q.const_}")
}

///|
impl @c.TypeMapper for Tracer with fn enter_attr(self, a) {
  self.events.push("attr " + a.to_string())
}

///|
test "visitor order" {
  let tracer = Tracer::{ events: [], }
  let t = @c.CType::function_(return_=@c.CType::basic(Bool), [
    ("a", @c.CType::pointer(const_=true, @c.CType::basic(SChar))),
    ("b", @c.CType::basic(attrs=[@c.Attr::new("unused")], CFloat)),
    ("c", @c.CType::basic(SShort)),
  ])
  ignore(@c.TypeMapper::run(tracer, t))
  debug_inspect(
    tracer.events,
    content=(
      #|[
      #|  "enter _Bool (*)(signed char const * a,  __attribute__((unused)) float complex b, signed short c);",
      #|  "enter _Bool",
      #|  "unsigned _Bool",
      #|  "enter signed char const *",
      #|  "enter signed char",
      #|  "char signed char",
      #|  "leave pointer",
      #|  "cvr const=true",
      #|  "enter  __attribute__((unused)) float complex",
      #|  "complex float complex",
      #|  "attr unused",
      #|  "enter signed short",
      #|  "signed signed short",
      #|]
    ),
  )
}

///|
/// A finder of the first pointer type (the upstream `Finder` example).
struct PointerFinder {
  search : @c.Search[@c.CType]
}

///|
impl @c.TypeMapper for PointerFinder with fn enter_pointer(self, t) {
  self.search.finished(t)
}

///|
test "search terminates at the first match" {
  let finder = PointerFinder::{ search: @c.Search::new(), }
  let found = finder.search.find(finder, sample_type())
  assert_eq(found, Some(@c.CType::structure("node", [])))
  assert_eq(finder.search.result(), found)
  assert_eq(finder.search.find(finder, @c.CType::basic(SInt)), None)
}

///|
/// A state-passing visitor that counts the basic types.
struct Counter {
  mut basics : Int32
}

///|
impl @c.TypeMapper for Counter with fn leave_basic(self, _) {
  self.basics += 1
}

///|
test "state-passing visitor" {
  let counter = Counter::{ basics: 0, }
  ignore(@c.TypeMapper::run(counter, sample_type()))
  assert_eq(counter.basics, 4)
}

///|
suberror Abort derive(Debug)

///|
struct Failing {}

///|
impl @c.TypeMapper for Failing with fn enter_enum(_self, _) {
  raise Abort
}

///|
test "errors other than the search termination propagate" {
  let search : @c.Search[Int32] = @c.Search::new()
  try search.find(Failing::{ }, sample_type()) catch {
    Abort => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected to fail")
  }
}
