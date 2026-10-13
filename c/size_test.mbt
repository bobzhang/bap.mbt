///|
fn int_sizes(model : @c.Model) -> Array[Int32] {
  let size = @c.SizeBase::new(model)
  [
    @c.CType::basic(Char),
    @c.CType::basic(SShort),
    @c.CType::basic(SInt),
    @c.CType::basic(SLong),
    @c.CType::basic(SLongLong),
    @c.CType::pointer(Void),
  ].map(t => size.bits(t).unwrap())
}

///|
test "integer sizes follow the data model table" {
  // char short int long long-long addr
  assert_eq(int_sizes(LP32), [8, 16, 16, 32, 64, 32])
  assert_eq(int_sizes(ILP32), [8, 16, 32, 32, 64, 32])
  assert_eq(int_sizes(ILP64), [8, 16, 64, 64, 64, 64])
  assert_eq(int_sizes(LLP64), [8, 16, 32, 32, 64, 64])
  assert_eq(int_sizes(LP64), [8, 16, 32, 64, 64, 64])
  assert_true(@c.Model::LP32.is_model32())
  assert_true(@c.Model::ILP32.is_model32())
  assert_true(@c.Model::LLP64.is_model64())
}

///|
test "sizes of the remaining basic types" {
  let size = @c.SizeBase::new(LP64)
  let sizes = [
    @c.Basic::Bool,
    UChar,
    SChar,
    UShort,
    UInt,
    ULong,
    ULongLong,
    Float,
    Double,
    LongDouble,
    CFloat,
    CDouble,
    CLongDouble,
    Enum([("A", None), ("B", Some(10L))]),
  ].map(t => size.basic(t).in_bits())
  assert_eq(sizes, [8, 8, 8, 16, 32, 64, 64, 32, 64, 128, 64, 128, 256, 32])
  assert_eq(size.pointer().in_bits(), 64)
  assert_eq(@c.SizeBase::new(ILP32).pointer().in_bits(), 32)
  // a real is `R32 | R64 | R128`
  assert_eq(size.real(LongDouble).in_bits(), 128)
  assert_eq(size.floating(CFloat).in_bits(), 64)
  // enumerations are approximated by `unsigned int`
  assert_eq(@c.SizeBase::new(LP32).enum_([]).in_bits(), 16)
}

///|
test "incomplete types have no size" {
  let size = @c.SizeBase::new(LP64)
  assert_eq(size.bits(Void), None)
  assert_eq(size.bits(@c.CType::function_([])), None)
  assert_eq(size.bits(@c.CType::array(@c.CType::basic(SInt))), None)
  assert_eq(
    size.bits(
      @c.CType::structure("s", [("x", @c.CType::basic(SInt)), ("v", Void)]),
    ),
    None,
  )
  assert_eq(size.bits(@c.CType::union("u", [("v", Void)])), None)
  // an empty union has no complete member either
  assert_eq(size.bits(@c.CType::union("u", [])), None)
  assert_eq(size.bits(@c.CType::structure("e", [])), Some(0))
}

///|
test "arrays" {
  let size = @c.SizeBase::new(ILP32)
  let a = @c.CType::array(size=10, @c.CType::basic(SShort))
  assert_eq(size.bits(a), Some(160))
  assert_eq(size.alignment(a).in_bits(), 16)
  let m = @c.CType::array(
    size=3,
    @c.CType::array(size=2, @c.CType::basic(Double)),
  )
  assert_eq(size.bits(m), Some(384))
}

///|
test "structure layout with padding" {
  let size = @c.SizeBase::new(LP64)
  // struct foo { char v1; int v2; char v3; }: 3 bytes of padding before v2
  // and 3 bytes of trailing padding
  let foo = @c.CType::structure("foo", [
    ("v1", @c.CType::basic(Char)),
    ("v2", @c.CType::basic(UInt)),
    ("v3", @c.CType::basic(Char)),
  ])
  assert_eq(size.bits(foo), Some(96))
  assert_eq(size.alignment(foo).in_bits(), 32)
  // the structure method excludes the trailing padding
  guard foo is Structure(spec) else { fail("not a structure") }
  assert_eq(size.structure(spec), Some(72))
  // struct { char c; double d; short s; } on LP64: 1+7+8+2+6 bytes
  let bar = @c.CType::structure("bar", [
    ("c", @c.CType::basic(Char)),
    ("d", @c.CType::basic(Double)),
    ("s", @c.CType::basic(SShort)),
  ])
  assert_eq(size.bits(bar), Some(192))
  // pointers are 32-bit aligned on ILP32
  let node = @c.CType::structure("node", [
    ("tag", @c.CType::basic(Char)),
    ("next", @c.CType::pointer(@c.CType::structure("node", []))),
  ])
  assert_eq(@c.SizeBase::new(ILP32).bits(node), Some(64))
  assert_eq(size.bits(node), Some(128))
  // nested structures are aligned by their largest member
  let outer = @c.CType::structure("outer", [
    ("c", @c.CType::basic(Char)),
    ("inner", foo),
  ])
  assert_eq(size.bits(outer), Some(128))
}

///|
test "union layout" {
  let size = @c.SizeBase::new(LP64)
  let u = @c.CType::union("u", [
    ("c", @c.CType::basic(Char)),
    ("i", @c.CType::basic(SInt)),
    ("a", @c.CType::array(size=5, @c.CType::basic(Char))),
  ])
  // the largest member is 40 bits, rounded up to the 32-bit alignment
  assert_eq(size.bits(u), Some(64))
  guard u is Union(spec) else { fail("not a union") }
  assert_eq(size.union(spec), Some(40))
  assert_eq(size.alignment(u).in_bits(), 32)
}

///|
test "alignment" {
  let size = @c.SizeBase::new(LP64)
  assert_eq(size.alignment(Void).in_bits(), 8)
  assert_eq(size.alignment(@c.CType::function_([])).in_bits(), 64)
  assert_eq(size.alignment(@c.CType::basic(LongDouble)).in_bits(), 128)
  assert_eq(size.alignment(@c.CType::structure("e", [])).in_bits(), 8)
}

///|
test "helpers" {
  assert_eq(@c.next_multitude_of(n=8, 0), 0)
  assert_eq(@c.next_multitude_of(n=8, 1), 8)
  assert_eq(@c.next_multitude_of(n=32, 72), 96)
  assert_eq(@c.next_multitude_of(n=32, 96), 96)
  assert_eq(@c.padding(R32, 8), 24)
  assert_eq(@c.padding(R32, 32), 0)
  assert_eq(@c.padding(R64, 72), 56)
  assert_eq(@c.max_enum_elt([]), 0L)
  assert_eq(@c.max_enum_elt([("A", None), ("B", None)]), 1L)
  assert_eq(
    @c.max_enum_elt([("A", Some(5L)), ("B", None), ("C", Some(2L))]),
    6L,
  )
  assert_eq(@c.max_enum_elt([("A", Some(-3L))]), -3L)
}

///|
/// A data model with a 128-bit `long double` alignment override, like a
/// target-specific subclass of `C.Size.base`.
struct CustomRuler {
  base : @c.SizeBase
}

///|
impl @c.Ruler for CustomRuler with fn model(self) {
  self.base.model
}

///|
impl @c.Ruler for CustomRuler with fn integer(self, t) {
  match t {
    SLong | ULong => R32
    t => self.base.integer(t)
  }
}

///|
test "overridden methods are observed by bits and alignment" {
  let ruler : &@c.Ruler = CustomRuler::{ base: @c.SizeBase::new(LP64), }
  assert_eq(ruler.bits(@c.CType::basic(SLong)), Some(32))
  let s = @c.CType::structure("s", [
    ("a", @c.CType::basic(Char)),
    ("b", @c.CType::basic(ULong)),
  ])
  assert_eq(ruler.bits(s), Some(64))
  assert_eq(@c.SizeBase::new(LP64).bits(s), Some(128))
}
