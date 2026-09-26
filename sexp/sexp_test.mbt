///|
fn read(text : String) -> String {
  try @sexp.Sexp::of_string(text) catch {
    err => "error: \{err}"
  } noraise {
    sexp => sexp.to_string()
  }
}

///|
fn read_many(text : String) -> String {
  try @sexp.Sexp::of_string_many(text) catch {
    err => "error: \{err}"
  } noraise {
    sexps => sexps.map(s => s.to_string()).join(" | ")
  }
}

///|
test "reading atoms, lists and comments" {
  debug_inspect(
    @sexp.Sexp::of_string("(foo (bar \"baz qux\") ())"),
    content=(
      #|List([Atom("foo"), List([Atom("bar"), Atom("baz qux")]), List([])])
    ),
  )
  inspect(read("  atom  "), content="atom")
  inspect(read("(a ; line comment\n b)"), content="(a b)")
  inspect(read("(a #| block #| nested |# |# b)"), content="(a b)")
  inspect(read("(a #;(ignored sexp) b)"), content="(a b)")
  inspect(read("(a#b|c)"), content="(a#b|c)")
  inspect(
    read_many("; header\n(a) b \"c\" #;d\n(e f)\n"),
    content="(a) | b | c | (e f)",
  )
  inspect(read_many(""), content="")
}

///|
test "quoted atoms and escapes" {
  debug_inspect(
    @sexp.Sexp::of_string_many(
      (
        #|"a\"b" "\\" "\n\t\r\b" "\065\x42" "\q" "\ x" "\'"
        #|"line \
        #|    continued" "caf\195\169" "héllo"
      ),
    ),
    content=(
      #|[
      #|  Atom("a\"b"),
      #|  Atom("\\"),
      #|  Atom("\n\t\r\b"),
      #|  Atom("AB"),
      #|  Atom("\\q"),
      #|  Atom(" x"),
      #|  Atom("'"),
      #|  Atom("line continued"),
      #|  Atom("café"),
      #|  Atom("héllo"),
      #|]
    ),
  )
}

///|
test "syntax errors carry positions" {
  inspect(
    read("(a"),
    content="error: line 1, column 2: unclosed parentheses at end of input",
  )
  inspect(
    read(")"),
    content="error: line 1, column 0: unexpected character: ')'",
  )
  inspect(
    read("a b"),
    content="error: line 1, column 2: s-expression followed by data",
  )
  inspect(read(""), content="error: line 1, column 0: unexpected end of input")
  inspect(
    read("\n  \"abc"),
    content="error: line 2, column 6: unterminated quoted string",
  )
  inspect(
    read("#| open"),
    content="error: line 1, column 7: unterminated block comment",
  )
  inspect(
    read("\"\\999\""),
    content="error: line 1, column 1: illegal escape sequence \\999",
  )
  let err = try @sexp.Sexp::of_string("(") catch {
    e => e
  } noraise {
    _ => fail("expected an error")
  }
  inspect(err.message(), content="unclosed parentheses at end of input")
  assert_true(err is ParseError(line=1, column=1, _))
}

///|
test "printing follows sexplib's machine format" {
  let sexp : @sexp.Sexp = List([
    Atom("a"),
    Atom("b"),
    List([Atom("c"), Atom("")]),
    Atom("d e"),
    Atom("f"),
    List([]),
    Atom("#|x"),
    Atom("q\"\\\n\u{01}é"),
  ])
  inspect(
    sexp,
    content=(
      #|(a b(c"")"d e"f()"#|x""q\"\\\n\001\195\169")
    ),
  )
  inspect(@sexp.escape_atom("plain"), content="plain")
  inspect(@sexp.must_escape("a|#"), content="true")
  inspect(@sexp.must_escape("a#|"), content="true")
  inspect(@sexp.must_escape("|a#"), content="false")
  // printing and reading round-trip
  assert_eq(@sexp.Sexp::of_string(sexp.to_string()), sexp)
  debug_inspect(sexp.list().map(xs => xs.length()), content="Some(8)")
  debug_inspect(@sexp.Sexp::List([]).atom(), content="None")
  debug_inspect(@sexp.Sexp::Atom("x").atom(), content="Some(\"x\")")
}
