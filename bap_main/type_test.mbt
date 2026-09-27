///|
fn[A] parse_result(t : @bap_main.Type[A], s : String) -> Result[A, String] {
  try t.parse(s) catch {
    e => Err(@bap_main.error_to_string(e))
  } noraise {
    v => Ok(v)
  }
}

///|
test "bool and char" {
  let t = @bap_main.Type::bool()
  debug_inspect(parse_result(t, "true"), content="Ok(true)")
  debug_inspect(parse_result(t, "false"), content="Ok(false)")
  debug_inspect(
    parse_result(t, "yes"),
    content=(
      #|Err("Invalid parameter: invalid value 'yes', either 'true' or 'false'")
    ),
  )
  inspect(t.print(true), content="true")
  inspect(t.name(), content="VAL")
  debug_inspect(t.default(), content="false")
  let c = @bap_main.Type::char()
  debug_inspect(parse_result(c, "x"), content="Ok('x')")
  debug_inspect(
    parse_result(c, "xy"),
    content=(
      #|Err("Invalid parameter: invalid value 'xy', expected a character")
    ),
  )
}

///|
test "integers use OCaml literal syntax" {
  let t = @bap_main.Type::int()
  debug_inspect(parse_result(t, "42"), content="Ok(42)")
  debug_inspect(parse_result(t, "-17"), content="Ok(-17)")
  debug_inspect(parse_result(t, "+5"), content="Ok(5)")
  debug_inspect(parse_result(t, "0x1F"), content="Ok(31)")
  debug_inspect(parse_result(t, "0o17"), content="Ok(15)")
  debug_inspect(parse_result(t, "0b101"), content="Ok(5)")
  debug_inspect(parse_result(t, "1_000"), content="Ok(1000)")
  debug_inspect(parse_result(t, "0xFFFFFFFF"), content="Ok(-1)")
  debug_inspect(parse_result(t, "2147483647"), content="Ok(2147483647)")
  debug_inspect(parse_result(t, "-2147483648"), content="Ok(-2147483648)")
  debug_inspect(
    parse_result(t, "2147483648"),
    content=(
      #|Err("Invalid parameter: invalid value '2147483648', expected an integer")
    ),
  )
  debug_inspect(
    parse_result(t, "_1"),
    content=(
      #|Err("Invalid parameter: invalid value '_1', expected an integer")
    ),
  )
  debug_inspect(
    parse_result(t, "12a"),
    content=(
      #|Err("Invalid parameter: invalid value '12a', expected an integer")
    ),
  )
  let t64 = @bap_main.Type::int64()
  debug_inspect(
    parse_result(t64, "9223372036854775807"),
    content="Ok(9223372036854775807)",
  )
  debug_inspect(parse_result(t64, "0xFFFFFFFFFFFFFFFF"), content="Ok(-1)")
  debug_inspect(
    parse_result(t64, "9223372036854775808"),
    content=(
      #|Err("Invalid parameter: invalid value '9223372036854775808', expected a 64-bit integer")
    ),
  )
  debug_inspect(
    parse_result(@bap_main.Type::nativeint(), "x"),
    content=(
      #|Err("Invalid parameter: invalid value 'x', expected a processor-native integer")
    ),
  )
  debug_inspect(
    parse_result(@bap_main.Type::int32(), "4294967296"),
    content=(
      #|Err("Invalid parameter: invalid value '4294967296', expected a 32-bit integer")
    ),
  )
}

///|
test "floats parse and print like OCaml" {
  let t = @bap_main.Type::float()
  debug_inspect(parse_result(t, "1.5"), content="Ok(1.5)")
  debug_inspect(parse_result(t, "1e3"), content="Ok(1000)")
  debug_inspect(parse_result(t, "1_000.5"), content="Ok(1000.5)")
  debug_inspect(parse_result(t, "2."), content="Ok(2)")
  debug_inspect(parse_result(t, ".5"), content="Ok(0.5)")
  debug_inspect(parse_result(t, "0x1.8p1"), content="Ok(3)")
  debug_inspect(parse_result(t, "-inf"), content="Ok(-Infinity)")
  debug_inspect(
    parse_result(t, "abc"),
    content=(
      #|Err("Invalid parameter: invalid value 'abc', expected a floating point number")
    ),
  )
  inspect(t.print(2.0), content="2.")
  inspect(t.print(0.5), content="0.5")
  inspect(t.print(-3.25), content="-3.25")
  inspect(t.print(0.1 + 0.2), content="0.3")
  inspect(t.print(1.0e20), content="1e+20")
  inspect(t.print(123456789012.0), content="123456789012.")
  inspect(t.print(1234567890123.0), content="1.23456789012e+12")
  inspect(t.print(0.0001), content="0.0001")
  inspect(t.print(0.00001), content="1e-05")
  inspect(t.print(1.0 / 0.0), content="inf")
  inspect(t.print(0.0), content="0.")
}

///|
test "enumerations accept unambiguous prefixes" {
  let t = @bap_main.Type::enumeration([
    ("arm", 1),
    ("armv7", 2),
    ("x86", 3),
    ("x86-64", 4),
  ])
  debug_inspect(t.default(), content="1")
  debug_inspect(parse_result(t, "arm"), content="Ok(1)")
  debug_inspect(parse_result(t, "armv"), content="Ok(2)")
  debug_inspect(parse_result(t, "x86-"), content="Ok(4)")
  debug_inspect(
    parse_result(t, "x"),
    content=(
      #|Err("Invalid parameter: enum value 'x' ambiguous and could be either 'x86' or 'x86-64'")
    ),
  )
  debug_inspect(
    parse_result(t, "mips"),
    content=(
      #|Err("Invalid parameter: invalid value 'mips', expected one of 'arm', 'armv7', 'x86' or 'x86-64'")
    ),
  )
  inspect(t.print(3), content="x86")
  let empty : Result[@bap_main.Type[Int], String] = try
    @bap_main.Type::enumeration([])
  catch {
    e => Err(@bap_main.error_to_string(e))
  } noraise {
    t => Ok(t)
  }
  inspect(empty is Err(_), content="true")
}

///|
test "compound types round trip" {
  let ints = @bap_main.Type::list(@bap_main.Type::int())
  debug_inspect(parse_result(ints, "1,2,,3"), content="Ok([1, 2, 3])")
  debug_inspect(parse_result(ints, ""), content="Ok([])")
  inspect(ints.print([1, 2, 3]), content="1,2,3")
  debug_inspect(
    parse_result(ints, "1,x"),
    content=(
      #|Err("Invalid parameter: invalid element in list ('1,x'): invalid value 'x', expected an integer")
    ),
  )
  let colon = @bap_main.Type::list(@bap_main.Type::string(), sep=':')
  debug_inspect(
    parse_result(colon, "/a:/b"),
    content=(
      #|Ok(["/a", "/b"])
    ),
  )
  let arr = @bap_main.Type::array(@bap_main.Type::bool())
  debug_inspect(
    parse_result(arr, "true,false"),
    content=(
      #|Ok(<FixedArray: [true, false]>)
    ),
  )
  inspect(arr.print([true, true]), content="true,true")
  let pair = @bap_main.Type::pair(
    @bap_main.Type::string(),
    @bap_main.Type::int(),
  )
  debug_inspect(
    parse_result(pair, "a,1,2"),
    content=(
      #|Err("Invalid parameter: invalid element in pair ('a,1,2'): invalid value '1,2', expected an integer")
    ),
  )
  debug_inspect(
    parse_result(pair, "key,7"),
    content=(
      #|Ok(("key", 7))
    ),
  )
  debug_inspect(
    parse_result(pair, "key"),
    content=(
      #|Err("Invalid parameter: invalid value 'key', missing a ',' separator")
    ),
  )
  inspect(pair.print(("x", 2)), content="x,2")
  let t3 = @bap_main.Type::t3(
    @bap_main.Type::int(),
    @bap_main.Type::int(),
    @bap_main.Type::string(),
    sep=':',
  )
  debug_inspect(
    parse_result(t3, "1:2:a:b"),
    content=(
      #|Ok((1, 2, "a:b"))
    ),
  )
  debug_inspect(
    parse_result(t3, "1:x:a"),
    content=(
      #|Err("Invalid parameter: invalid element in triple ('x:a'): invalid value 'x', expected an integer")
    ),
  )
  let t4 = @bap_main.Type::t4(
    @bap_main.Type::int(),
    @bap_main.Type::int(),
    @bap_main.Type::int(),
    @bap_main.Type::int(),
  )
  debug_inspect(parse_result(t4, "1,2,3,4"), content="Ok((1, 2, 3, 4))")
  inspect(t4.print((4, 3, 2, 1)), content="4,3,2,1")
  debug_inspect(t4.default(), content="(0, 0, 0, 0)")
  let opt = @bap_main.Type::some(@bap_main.Type::int())
  debug_inspect(parse_result(opt, "5"), content="Ok(Some(5))")
  inspect(opt.print(None), content="")
  debug_inspect(opt.default(), content="None")
}

///|
test "define, refine, rename, and defaults" {
  let even = @bap_main.Type::int()
    .refine(x => if x % 2 != 0 { raise @bap_main.Invalid("\{x} is odd") })
    .rename("EVEN")
    .with_default(2)
  inspect(even.name(), content="EVEN")
  debug_inspect(even.default(), content="2")
  debug_inspect(parse_result(even, "4"), content="Ok(4)")
  debug_inspect(
    parse_result(even, "3"),
    content=(
      #|Err("Invalid parameter: 3 is odd")
    ),
  )
  let bad_default = try
    @bap_main.Type::int()
    .with_default(1)
    .refine(x => if x % 2 != 0 { raise @bap_main.Invalid("odd") })
  catch {
    _ => None
  } noraise {
    t => Some(t)
  }
  inspect(bad_default is None, content="true")
  let upper = @bap_main.Type::create(
    name="UPPER",
    parse=s => s.to_upper(),
    print=s => s.to_lower(),
    "",
  )
  inspect(upper.parse("abc"), content="ABC")
  inspect(upper.print("ABC"), content="abc")
  // the default digest is the MD5 of the printed value
  inspect(
    @bap_main.Type::string().digest(""),
    content="d41d8cd98f00b204e9800998ecf8427e",
  )
  inspect(
    @bap_main.Type::string().digest("abc"),
    content="900150983cd24fb0d6963f7d28e17f72",
  )
  let custom = @bap_main.Type::create(
    digest=_ => "constant",
    parse=s => s,
    print=s => s,
    "",
  )
  inspect(custom.digest("anything"), content="constant")
}

///|
test "file types use the installed file system" {
  @bap_main.set_file_system(
    @bap_main.FileSystem::in_memory(files=[("/data/a.txt", "abc")], dirs=[
      "/data",
    ]),
  )
  let file = @bap_main.Type::file()
  let dir = @bap_main.Type::dir()
  let regular = @bap_main.Type::non_dir_file()
  debug_inspect(
    parse_result(file, "/data"),
    content=(
      #|Ok("/data")
    ),
  )
  debug_inspect(
    parse_result(file, "/nope"),
    content=(
      #|Err("Invalid parameter: no '/nope' file or directory")
    ),
  )
  debug_inspect(
    parse_result(dir, "/data/a.txt"),
    content=(
      #|Err("Invalid parameter: '/data/a.txt' is not a directory")
    ),
  )
  debug_inspect(
    parse_result(dir, "/nope"),
    content=(
      #|Err("Invalid parameter: no '/nope' directory")
    ),
  )
  debug_inspect(
    parse_result(regular, "/data"),
    content=(
      #|Err("Invalid parameter: '/data' is a directory")
    ),
  )
  debug_inspect(
    parse_result(regular, "/nope"),
    content=(
      #|Err("Invalid parameter: no '/nope' file")
    ),
  )
  // files are digested by contents, missing files share a digest
  inspect(
    regular.digest("/data/a.txt"),
    content="900150983cd24fb0d6963f7d28e17f72",
  )
  inspect(regular.digest("/x") == regular.digest("/y"), content="true")
  inspect(file.digest("/data") == file.digest("/data"), content="true")
  inspect(
    @bap_main.Type::path().digest("/data/a.txt") ==
    regular.digest("/data/a.txt"),
    content="false",
  )
  @bap_main.set_file_system(@bap_main.FileSystem::native())
}
