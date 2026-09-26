///|
test "term attributes round-trip" {
  let size : &@c.Ruler = @c.SizeBase::new(LP64)
  let t = @c.CType::structure("s", [
    ("e", @c.CType::basic(Enum([("A", None), ("B", Some(-7L))]))),
    ("p", @c.CType::pointer(restrict=true, @c.CType::basic(const_=true, Char))),
    ("a", @c.CType::array(size=3, @c.CType::basic(Double))),
    ("u", @c.CType::union("u", [("f", @c.CType::basic(Float))])),
  ])
  let proto : @c.Proto = {
    return_: t,
    args: [("x", @c.CType::basic(attrs=[@c.Attr::new("unused")], SInt))],
    variadic: true,
  }
  let w = @types.Word::of_int(width=16, 0xBEEF)
  let datum : @c.Data = Seq([@c.data(size, t), Imm(R16, Set([w])), Imm(R8, Top)])
  let layout = @c.layout(size, t)
  let sub = @types.Sub::create(name="f")
  let sub = @c.type_tag().set(sub, t)
  let sub = @c.proto_tag().set(sub, proto)
  let sub = @c.data_tag().set(sub, datum)
  let sub = @c.layout_tag().set(sub, layout)
  assert_eq(@c.type_tag().get(sub), Some(t))
  assert_eq(@c.proto_tag().get(sub), Some(proto))
  assert_eq(@c.data_tag().get(sub), Some(datum))
  assert_eq(@c.layout_tag().get(sub), Some(layout))
  assert_true(@c.proto_tag().has(sub))
  assert_eq(
    [
      @c.data_tag().name(),
      @c.layout_tag().name(),
      @c.type_tag().name(),
      @c.proto_tag().name(),
    ],
    ["c.data", "c.layout", "c.type", "c.proto"],
  )
  let bare = @types.Sub::create(name="g")
  assert_eq(@c.type_tag().get(bare), None)
  assert_true(!@c.proto_tag().has(bare))
  // malformed values are ignored
  let broken = bare.set_attr(@types.Attr::new(key="c.data", value="[1,"))
  assert_eq(@c.data_tag().get(broken), None)
  assert_eq(@c.type_tag().decode("\"Nope\""), None)
  assert_eq(@c.data_tag().decode("[\"Imm\", 12, \"Top\"]"), None)
  inspect(
    @c.data_tag().attr(Imm(R32, Set([@types.Word::of_int(width=32, 5)]))).value,
    content=(
      #|["Imm",32,["Set",[[32,"00000005"]]]]
    ),
  )
}
