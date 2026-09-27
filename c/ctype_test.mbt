///|
test "basic type groups" {
  assert_true(@c.Basic::SChar.is_char() && @c.Basic::SChar.is_signed())
  assert_true(@c.Basic::Bool.is_unsigned() && @c.Basic::Bool.is_integer())
  assert_true(!@c.Basic::Char.is_signed() && !@c.Basic::Char.is_unsigned())
  assert_true(@c.Basic::Enum([]).is_integer() && @c.Basic::Enum([]).is_enum())
  assert_true(@c.Basic::CDouble.is_floating() && !@c.Basic::CDouble.is_real())
  assert_true(@c.Basic::LongDouble.is_real() && !@c.Basic::Float.is_integer())
  assert_eq(@c.Basic::all_floating().length(), 6)
  assert_true(@c.Basic::all_signed().iter().all(@c.Basic::is_signed))
  assert_true(@c.Basic::all_unsigned().iter().all(@c.Basic::is_unsigned))
  assert_true(@c.Basic::all_chars().iter().all(@c.Basic::is_char))
  assert_true(@c.Basic::all_shorts().iter().all(@c.Basic::is_short))
  assert_true(@c.Basic::all_cints().iter().all(@c.Basic::is_cint))
  assert_true(@c.Basic::all_longs().iter().all(@c.Basic::is_long))
  assert_true(@c.Basic::all_long_longs().iter().all(@c.Basic::is_long_long))
  assert_true(@c.Basic::all_reals().iter().all(@c.Basic::is_real))
  assert_true(@c.Basic::all_complex().iter().all(@c.Basic::is_complex))
}

///|
test "constructors, qualifiers, and predicates" {
  let attrs = [@c.Attr::new("aligned", args=["16"])]
  let cint = @c.CType::basic(attrs~, const_=true, SInt)
  assert_true(cint.is_const() && !cint.is_volatile() && !cint.is_restrict())
  assert_true(cint.is_basic() && cint.is_cint() && cint.is_signed())
  assert_true(cint.is_integer() && !cint.is_floating() && !cint.is_char())
  assert_eq(cint.attrs(), attrs)
  let p = @c.CType::pointer(volatile_=true, restrict=true, cint)
  assert_true(p.is_pointer() && p.is_volatile() && p.is_restrict())
  assert_true(!p.is_const() && !p.is_basic())
  let a = @c.CType::array(size=4, const_=true, @c.CType::basic(Double))
  assert_true(a.is_array() && a.is_const())
  assert_true(a is Array({ t: { size: Some(4), .. }, .. }))
  let s = @c.CType::structure("s", [("x", cint)])
  assert_true(s.is_structure() && !s.is_const() && !s.is_union())
  let u = @c.CType::union("u", [("x", cint)])
  assert_true(u.is_union() && !u.is_structure())
  let f = @c.CType::function_(variadic=true, [("fmt", p)])
  assert_true(f.is_function())
  assert_true(f is Function({ t: { return_: Void, variadic: true, .. }, .. }))
  assert_true(@c.CType::Void.is_void() && @c.CType::Void.attrs().is_empty())
  assert_true(@c.CType::basic(Enum([])).is_enum())
  assert_true(@c.CType::basic(CFloat).is_complex())
  assert_true(@c.CType::basic(Float).is_real())
  assert_true(@c.CType::basic(UShort).is_short())
  assert_true(@c.CType::basic(ULong).is_unsigned())
}

///|
test "printer: scalars" {
  inspect(@c.CType::Void, content="void")
  inspect(@c.CType::basic(SInt), content="signed")
  inspect(@c.CType::basic(ULongLong), content="unsigned long long")
  inspect(@c.CType::basic(const_=true, Char), content=" const char")
  inspect(
    @c.CType::basic(const_=true, volatile_=true, CLongDouble),
    content=" const  volatile long double complex",
  )
  inspect(@c.CType::pointer(@c.CType::basic(Char)), content="char*")
  inspect(
    @c.CType::pointer(const_=true, @c.CType::pointer(Void)),
    content="void* const *",
  )
  inspect(
    @c.CType::array(size=16, @c.CType::basic(UChar)),
    content="unsigned char[16]",
  )
  inspect(@c.CType::array(@c.CType::basic(Bool)), content="_Bool[]")
  inspect(
    @c.CType::basic(attrs=[@c.Attr::new("mode", args=["DI"])], SLong),
    content=" __attribute__((mode(DI))) signed long",
  )
  inspect(
    @c.Attr::new("format", args=["printf", "1", "2"]),
    content="format(printf, 1, 2)",
  )
}

///|
test "printer: functions" {
  let printf = @c.CType::function_(
    variadic=true,
    return_=@c.CType::basic(SInt),
    [("fmt", @c.CType::pointer(@c.CType::basic(const_=true, Char)))],
  )
  inspect(printf, content="signed (*)( const char* fmt, ...);")
  inspect(@c.CType::function_([]), content="void (*)(void);")
  guard printf is Function({ t: proto, .. }) else { fail("not a function") }
  inspect(proto, content="signed (*)( const char* fmt, ...)")
  let attrs = [@c.Attr::new("noreturn")]
  inspect(
    @c.CType::function_(attrs~, [("code", @c.CType::basic(SInt))]),
    content="void (*)(signed code) __attribute__((noreturn)) ;",
  )
}

///|
test "printer: compounds" {
  let point = @c.CType::structure("point", [
    ("x", @c.CType::basic(SInt)),
    ("y", @c.CType::basic(SInt)),
    ("next", @c.CType::pointer(@c.CType::structure("point", []))),
    ("u", @c.CType::union("value", [])),
  ])
  inspect(
    point,
    content=(
      #|struct point {
      #|    signed x;
      #|    signed y;
      #|    struct point* next;
      #|    union value u;
      #|};
    ),
  )
  inspect(
    @c.CType::union(attrs=[@c.Attr::new("packed")], "u", [
      ("f", @c.CType::basic(Float)),
    ]),
    content=(
      #|union u {
      #|    float f;
      #|} __attribute__((packed)) ;
    ),
  )
  // upstream Format emits the indentation even for an empty body
  assert_eq(
    @c.CType::structure("empty", []).to_string(),
    "struct empty {\n    \n};",
  )
}

///|
test "printer: enumerations" {
  inspect(
    @c.CType::basic(Enum([("RED", None), ("GREEN", Some(5L))])),
    content=(
      #|enum {
      #|    RED,,
      #|    GREEN= 5,,
      #|}
      #|
    ),
  )
}
