///|
fn lp64() -> &@c.Ruler {
  @c.SizeBase::new(LP64)
}

///|
test "data of scalars and references" {
  let size = lp64()
  inspect(@c.data_to_string(@c.data(size, Void)), content="{}")
  inspect(
    @c.data_to_string(@c.data(size, @c.CType::basic(SInt))),
    content="Top:u32",
  )
  inspect(
    @c.data_to_string(@c.data(size, @c.CType::pointer(@c.CType::basic(Char)))),
    content="Top:u8 ptr",
  )
  inspect(
    @c.data_to_string(@c.data(size, @c.CType::array(@c.CType::basic(SShort)))),
    content="Top:u16 ptr",
  )
  inspect(
    @c.data_to_string(
      @c.data(size, @c.CType::array(size=3, @c.CType::basic(SShort))),
    ),
    content="{Top:u16, Top:u16, Top:u16} ptr",
  )
  inspect(
    @c.data_to_string(@c.data(size, @c.CType::function_([]))),
    content="Top:u64 ptr",
  )
}

///|
test "data of compounds includes the paddings" {
  let size = lp64()
  let foo = @c.CType::structure("foo", [
    ("v1", @c.CType::basic(Char)),
    ("v2", @c.CType::basic(UInt)),
    ("v3", @c.CType::basic(Char)),
  ])
  // the 24-bit paddings are represented as three bytes
  inspect(
    @c.data_to_string(@c.data(size, foo)),
    content="{Top:u8, {{}:u8, {}:u8, {}:u8}, Top:u32, Top:u8, {{}:u8, {}:u8, {}:u8}}",
  )
  let bar = @c.CType::structure("bar", [
    ("c", @c.CType::basic(Char)),
    ("d", @c.CType::basic(Double)),
  ])
  let d = @c.data(size, bar)
  inspect(
    @c.data_to_string(d),
    content="{Top:u8, {{}:u8, {}:u8, {}:u8, {}:u8, {}:u8, {}:u8, {}:u8}, Top:u64}",
  )
  assert_eq(@c.size_of_data(size, d), 8 + 56 + 64)
  let u = @c.CType::union("u", [
    ("c", @c.CType::basic(Char)),
    ("s", @c.CType::basic(SShort)),
  ])
  inspect(@c.data_to_string(@c.data(size, u)), content="{Top:u8, Top:u8}")
  let w = @types.Word::of_int(width=8, 42)
  inspect(@c.data_to_string(Imm(R8, Set([w]))), content="{0x2A:8u}:u8")
}

///|
test "layout" {
  let size = lp64()
  let foo = @c.CType::structure("foo", [
    ("v1", @c.CType::basic(Char)),
    ("v2", @c.CType::basic(UInt)),
    ("v3", @c.CType::basic(Char)),
  ])
  let l = @c.layout(size, foo)
  inspect(
    l,
    content="{ [<v1 : [char : 8]> : 8], [<undef> : 24], [<v2 : [unsigned : 32]> : 32], [<v3 : [char : 8]> : 8], [<undef> : 24] }",
  )
  assert_eq(@c.size_of_layout(size, l), 96)
  let u = @c.CType::union("u", [
    ("c", @c.CType::basic(Char)),
    ("i", @c.CType::basic(SInt)),
  ])
  inspect(
    @c.layout(size, u),
    content="[{ [<c : [char : 8]> : 8], [<undef> : 24] } | [<i : [signed : 32]> : 32] : 32]",
  )
  inspect(
    @c.layout(size, @c.CType::pointer(@c.CType::basic(SInt))),
    content="*[signed : 32]",
  )
  inspect(
    @c.layout(size, @c.CType::array(size=2, @c.CType::basic(Char))),
    content="*{ [char : 8], [char : 8] }",
  )
  inspect(@c.layout(size, @c.CType::function_([])), content="*[<undef> : 64]")
  inspect(@c.layout(size, Void), content="[<undef> : 8]")
  assert_eq(
    @c.size_of_layout(size, @c.layout(size, @c.CType::pointer(foo))),
    64,
  )
}
