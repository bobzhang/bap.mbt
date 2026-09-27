// Expected outputs in this file were cross-checked against upstream
// `lib/ogre/ogre.ml` compiled with core_kernel/sexplib (OCaml 4.14).

///|
fn parse_error(text : String) -> String {
  try @ogre.Doc::from_string(text) catch {
    e => e.message()
  } noraise {
    _ => "no error"
  }
}

///|
test "segments: named and positional facts are normalized, newest first" {
  let doc = @ogre.Doc::from_string(
    (
      #|(declare segment (addr int) (size int) (r bool) (w bool) (x bool))
      #|(segment 0 4096 true false true)
      #|(segment 0x1000 4096 True False false)
      #|(segment (x true) (addr 16) (size 1) (r true) (w true))
    ),
  )
  inspect(doc.declarations(), content="1")
  inspect(doc.definitions(), content="1")
  inspect(
    doc.to_string(),
    content=(
      #|(declare segment (addr int) (size int) (r bool) (w bool) (x bool))
      #|
      #|(segment 16 1 true true true)
      #|(segment 4096 4096 true false false)
      #|(segment 0 4096 true false true)
      #|
    ),
  )
  inspect(
    doc.to_yaml(),
    content=(
      #|scheme:
      #|  "segment" : {"addr" : int, "size" : int, "r" : bool, "w" : bool, "x" : bool}
      #|"segment":
      #|  - "addr": 16
      #|    "size": 1
      #|    "r": true
      #|    "w": true
      #|    "x": true
      #|  - "addr": 4096
      #|    "size": 4096
      #|    "r": true
      #|    "w": false
      #|    "x": false
      #|  - "addr": 0
      #|    "size": 4096
      #|    "r": true
      #|    "w": false
      #|    "x": true
      #|
    ),
  )
  // printing and parsing again is stable up to the (upstream) reversal of
  // fact order
  let again = @ogre.Doc::from_string(doc.to_string())
  assert_true(again.facts("segment").length() == 3)
  assert_true(again.facts("segment")[0].get("addr") is Some("0"))
  let twice = @ogre.Doc::from_string(again.to_string())
  assert_eq(twice.to_string(), doc.to_string())
  assert_true(twice == doc)
}

///|
test "positional declarations use field indices as names" {
  let doc = @ogre.Doc::from_string(
    "(declare foo int str (name str) float)(foo 1 hello (name world) 2.5)",
  )
  inspect(
    doc.to_string(),
    content=(
      #|(declare foo int str (name str) float)
      #|
      #|(foo 1 hello world 2.5)
      #|
    ),
  )
  debug_inspect(
    doc.declaration("foo"),
    content=(
      #|Some(
      #|  [
      #|    { name: "0", typ: Int },
      #|    { name: "1", typ: Str },
      #|    { name: "name", typ: Str },
      #|    { name: "3", typ: Float },
      #|  ],
      #|)
    ),
  )
  debug_inspect(
    doc.facts("foo")[0].fields(),
    content=(
      #|[("0", "1"), ("1", "hello"), ("3", "2.5"), ("name", "world")]
    ),
  )
  inspect(
    doc.to_yaml(),
    content=(
      #|scheme:
      #|  "foo" : {"0" : int, "1" : str, "name" : str, "3" : float}
      #|"foo":
      #|  - "0": 1
      #|    "1": "hello"
      #|    "name": "world"
      #|    "3": 2.5
      #|
    ),
  )
}

///|
test "float values are printed like sexplib (%.15G, falling back to %.17G)" {
  let doc = @ogre.Doc::from_string(
    "(declare f (v float)) (f 1e20) (f 0.1) (f 3) (f 1e-5) (f 0.30000000000000004) (f -0) (f inf) (f -inf) (f 1.5e300) (f 123456.7) (f 1234567890123456789) (f 0.000123) (f 1e15) (f 1e16) (f 2.5e-7) (f 100) (f 1_000.5) (f 5.) (f .5) (f 0x1p3) (f nan)",
  )
  inspect(
    doc.to_string(),
    content=(
      #|(declare f (v float))
      #|
      #|(f NAN)
      #|(f 8)
      #|(f 0.5)
      #|(f 5)
      #|(f 1000.5)
      #|(f 100)
      #|(f 2.5E-07)
      #|(f 1E+16)
      #|(f 1E+15)
      #|(f 0.000123)
      #|(f 1.2345678901234568E+18)
      #|(f 123456.7)
      #|(f 1.5E+300)
      #|(f -INF)
      #|(f INF)
      #|(f -0)
      #|(f 0.30000000000000004)
      #|(f 1E-05)
      #|(f 3)
      #|(f 0.1)
      #|(f 1E+20)
      #|
    ),
  )
  // the normalized spellings parse back to the same document
  let again = @ogre.Doc::from_string(doc.to_string())
  assert_eq(again.facts("f").length(), 21)
  let typ = @ogre.Type::float()
  assert_eq(typ.pack(0.1 + 0.2), "0.30000000000000004")
  // spellings produced by OCaml's `%.15G`/`%.17G` for edge cases
  let edge = [
    0.9999999999999999,
    9.999999999999999e22,
    5.0e-324,
    1.7976931348623157e308,
    123456789012345.6,
    0.1 + 0.7,
    1.0e-4,
    99999.99999999999,
    2.2250738585072014e-308,
    -1.5,
  ]
  assert_eq(edge.map(x => typ.pack(x)), [
    "0.99999999999999989", "1E+23", "4.94065645841247E-324", "1.7976931348623157E+308",
    "123456789012345.59", "0.79999999999999993", "0.0001", "99999.999999999985",
    "2.2250738585072014E-308", "-1.5",
  ])
  assert_eq(typ.parse("1E+20"), Some(1.0e20))
  assert_eq(typ.parse("-INF"), Some(@double.neg_infinity))
  assert_eq(typ.parse("x1"), None)
}

///|
test "int values follow OCaml Int64.of_string" {
  let doc = @ogre.Doc::from_string(
    "(declare i (v int)) (i 0x10) (i -5) (i +7) (i 1_000) (i 0o17) (i 0b101) (i 0xFFFFFFFFFFFFFFFF) (i -9223372036854775808) (i 0u18446744073709551615) (i -0x10)",
  )
  inspect(
    doc.to_string(),
    content=(
      #|(declare i (v int))
      #|
      #|(i -16)
      #|(i -9223372036854775808)
      #|(i -1)
      #|(i 5)
      #|(i 15)
      #|(i 1000)
      #|(i 7)
      #|(i -5)
      #|(i 16)
      #|
    ),
  )
  let int = @ogre.Type::int()
  assert_eq(int.parse("9223372036854775807"), Some(9223372036854775807L))
  assert_eq(int.parse("9223372036854775808"), None)
  assert_eq(int.parse("0x10000000000000000"), None)
  assert_eq(int.parse("_1"), None)
  assert_eq(int.parse(""), None)
  assert_eq(int.parse("0x"), None)
  assert_eq(@ogre.Typ::Int.normalize("0b11"), Some("3"))
  assert_eq(@ogre.Typ::Bool.normalize("True"), Some("true"))
  assert_eq(@ogre.Typ::Bool.normalize("yes"), None)
  assert_eq(@ogre.Typ::Str.normalize(""), Some(""))
}

///|
test "string atoms are quoted and escaped like sexplib" {
  let doc = @ogre.Doc::from_string(
    (
      #|(declare s (v str))
      #|(s "hello world") (s "a;b") (s "") (s "x#|y") (s "tab\there")
      #|(s "q\"uote") (s |x) (s "line\n") (s "a\nb") (s "\x41B")
      #|(s "caf\195\169") (s "continued \
      #|   line")
    ),
  )
  inspect(
    doc.to_string(),
    content=(
      #|(declare s (v str))
      #|
      #|(s "continued line")
      #|(s "caf\195\169")
      #|(s AB)
      #|(s  "a\
      #|   \nb")
      #|(s "line\n")
      #|(s |x)
      #|(s "q\"uote")
      #|(s "tab\there")
      #|(s "x#|y")
      #|(s "")
      #|(s "a;b")
      #|(s "hello world")
      #|
    ),
  )
  let values = doc.facts("s").map(entry => entry.get("v").unwrap())
  assert_true(values.contains("café"))
  assert_true(values.contains("a\nb"))
  assert_true(values.contains("q\"uote"))
  // the printed form reads back to the same document
  assert_true(
    @ogre.Doc::from_string(@ogre.Doc::from_string(doc.to_string()).to_string()) ==
    doc,
  )
}

///|
test "long entries are wrapped like OCaml Format at margin 78" {
  let doc = @ogre.Doc::from_string(
    (
      #|(declare named-symbol (addr int) (name str))
      #|(named-symbol 4198400 _ZN4core3fmt9Formatter9write_str17h3a1f5e3c7b2d1a0fE_and_more_and_more)
      #|(named-symbol 1 "a b c d e f g h i j k l m n o p q r s t u v w x y z a b c d e f g h i j k l m n o p q r s t u v w x y z")
      #|(declare llvm:section-entry (name str) (addr int) (size int) (off int) (another-long-field-name int) (yet-another-field str) (more bool))
      #|(llvm:section-entry .text 4096 1024 512 1 two true)
    ),
  )
  inspect(
    doc.to_string(),
    content=(
      #|(declare llvm:section-entry (name str) (addr int) (size int) (off int)
      #| (another-long-field-name int) (yet-another-field str) (more bool))
      #|(declare named-symbol (addr int) (name str))
      #|
      #|(llvm:section-entry .text 4096 1024 512 1 two true)
      #|(named-symbol 1
      #| "a b c d e f g h i j k l m n o p q r s t u v w x y z a b c d e f g h i j k l m n o p q r s t u v w x y z")
      #|(named-symbol 4198400
      #| _ZN4core3fmt9Formatter9write_str17h3a1f5e3c7b2d1a0fE_and_more_and_more)
      #|
    ),
  )
  assert_true(@ogre.Doc::from_string(doc.to_string()).declarations() == 2)
}

///|
test "comments, duplicates and the empty document" {
  let doc = @ogre.Doc::from_string(
    "; a comment\n(declare a (x int)) #| block #| nested |# |# (a 1) #; (a 2) (a 3) (a 0x1) (a 1)",
  )
  inspect(
    doc.to_string(),
    content=(
      #|(declare a (x int))
      #|
      #|(a 3)
      #|(a 1)
      #|
    ),
  )
  let empty = @ogre.Doc::from_string("  ")
  assert_true(empty.is_empty())
  assert_true(empty == @ogre.Doc::empty())
  inspect(empty.to_string(), content="\n")
  inspect(empty.to_yaml(), content="scheme:\n")
  inspect(empty.declarations(), content="0")
  inspect(empty.definitions(), content="0")
}

///|
test "document errors carry upstream messages" {
  inspect(parse_error("(a 1)"), content="a is not declared in the scheme")
  inspect(
    parse_error("(declare a (x int)) (declare a (x str))"),
    content=(
      #|Failed to parse an OGRE document, got a signature mismatch. Expected:
      #|(((fname x) (ftype Int)))
      #|Got:
      #|(((fname x) (ftype Str)))
      #|
    ),
  )
  inspect(
    parse_error("(declare a (x int) (y int)) (a 1)"),
    content=(
      #|attribute "a" didn't provide a value for the field "y"
    ),
  )
  inspect(parse_error("(declare a (x int)) (a 1 2)"), content="wrong arity")
  inspect(
    parse_error("(declare a (x int)) (a (z 1))"),
    content="unknown field z",
  )
  inspect(
    parse_error("(declare a (x int) (y int)) (a (x 1) (x 2))"),
    content=(
      #|("Map.of_alist_or_error: duplicate key" x)
    ),
  )
  inspect(
    parse_error("(declare a (x int)) (a hello)"),
    content=(
      #|value "hello" is not in a domain of values of field 'a.x'
    ),
  )
  inspect(
    parse_error("(declare i (v int)) (i 9223372036854775808)"),
    content=(
      #|value "9223372036854775808" is not in a domain of values of field 'i.v'
    ),
  )
  inspect(
    parse_error("(declare b (v bool)) (b yes)"),
    content=(
      #|value "yes" is not in a domain of values of field 'b.v'
    ),
  )
  inspect(
    parse_error("(declare a (1x int))"),
    content="bad field name 1x, expected [a..z][a..z-]*",
  )
  inspect(
    parse_error("(declare a (x integer))"),
    content="expected <field-type> ::= int | str | bool | float",
  )
  inspect(
    parse_error("(declare)"),
    content="expected (declare <attribute-name> <field-decls>)",
  )
  inspect(
    parse_error("(declare a (x int y))"),
    content="expected <decl> ::= <field-type> | (<field-name> <field-type>)",
  )
  inspect(
    parse_error("hello"),
    content="expected <ogre-entry> ::= | (declare <attribute-name> <field-decls>)| (<attribute-name> <attribute-value>)",
  )
  inspect(
    parse_error("(declare a (x int)) (a (x 1 2))"),
    content="expected <attribute-value> ::= <field-value> | (<field-name> <field-value>)",
  )
  inspect(
    parse_error("(declare a (x int)"),
    content="Sexplib.Parser: failed to parse line 1 char 18: unterminated list",
  )
  inspect(
    parse_error("(declare a (x int)))"),
    content="Sexplib.Parser: failed to parse line 1 char 19: unexpected ')'",
  )
  inspect(
    parse_error("(declare a (x str))\n(a \"open"),
    content=(
      #|Sexplib.Parser: failed to parse line 2 char 8: unterminated string
    ),
  )
  inspect(
    parse_error("(declare a (x str)) (a b#|c)"),
    content="Sexplib.Parser: failed to parse line 1 char 27: comment tokens in unquoted atom",
  )
  inspect(
    parse_error("#| open"),
    content="Sexplib.Parser: failed to parse line 1 char 7: unterminated block comment",
  )
}

///|
test "merge adds the facts of the smaller document to the larger one" {
  let d1 = @ogre.Doc::from_string(
    "(declare arch (name str)) (arch x86_64) (declare segment (addr int) (size int)) (segment 0 4096)",
  )
  let d2 = @ogre.Doc::from_string(
    "(declare arch (name str)) (arch arm) (declare bits (size int)) (bits 32)",
  )
  let expected =
    #|(declare arch (name str))
    #|(declare bits (size int))
    #|(declare segment (addr int) (size int))
    #|
    #|(arch arm)
    #|(arch x86_64)
    #|(bits 32)
    #|(segment 0 4096)
    #|
  inspect(d1.merge(d2).to_string(), content=expected)
  inspect(d2.merge(d1).to_string(), content=expected)
  assert_true(d1.compare(d2) > 0)
  assert_true(d2.compare(d1) < 0)
  assert_true(d1.merge(d1) == d1)
  assert_true(@ogre.Doc::empty().merge(d2) == d2)
  assert_true(d2.merge(@ogre.Doc::empty()) == d2)
  let conflicting = @ogre.Doc::from_string("(declare arch (name int))")
  try d1.merge(conflicting) catch {
    e =>
      inspect(
        e,
        content=(
          #|Failed to parse an OGRE document, got a signature mismatch. Expected:
          #|(((fname name) (ftype Str)))
          #|Got:
          #|(((fname name) (ftype Int)))
          #|
        ),
      )
  } noraise {
    _ => fail("expected a signature mismatch")
  }
  // clear keeps the scheme only
  let cleared = d1.merge(d2).clear()
  inspect(cleared.declarations(), content="3")
  inspect(cleared.definitions(), content="0")
  inspect(
    cleared.to_string(),
    content=(
      #|(declare arch (name str))
      #|(declare bits (size int))
      #|(declare segment (addr int) (size int))
      #|
      #|
    ),
  )
  debug_inspect(
    cleared.attributes(),
    content=(
      #|["arch", "bits", "segment"]
    ),
  )
}
