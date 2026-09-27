// Expected outputs were produced by OCaml 4.14's Format module.

///|
test "vertical boxes and literal newlines" {
  let fmt = @text_tags.Formatter::new()
  fmt.print_format("xx@[<v 2>a\nb@,c@]")
  assert_eq(fmt.flush_str(), "xxa\nb\n    c")
}

///|
test "hov boxes fill lines up to the margin" {
  let fmt = @text_tags.Formatter::new()
  let word = (c : Char) => String::make(30, c)
  fmt.open_hovbox(2)
  fmt.print_string(word('a'))
  fmt.print_space()
  fmt.print_string(word('b'))
  fmt.print_space()
  fmt.print_string(word('c'))
  fmt.print_space()
  fmt.print_string(word('d'))
  fmt.close_box()
  assert_eq(
    fmt.flush_str(),
    "\{word('a')} \{word('b')}\n  \{word('c')} \{word('d')}",
  )
}

///|
test "hv boxes are either horizontal or vertical" {
  let fmt = @text_tags.Formatter::new()
  let long = String::make(80, 'x')
  fmt.print_format("@[<hv 2>(a@ b@ c)@]@.@[<hv 2>(\{long}@ b@ c)@]")
  assert_eq(fmt.flush_str(), "(a b c)\n(\{long}\n  b\n  c)")
}

///|
test "breaks with offsets, margins and custom breaks" {
  let fmt = @text_tags.Formatter::new()
  fmt.set_margin(10)
  assert_eq(fmt.get_margin(), 10)
  fmt.print_format("@[<v 0>a@;<1 4>b@]")
  assert_eq(fmt.flush_str(), "a\n    b")
  fmt.open_vbox(0)
  fmt.print_string("x")
  fmt.print_custom_break(fits=("", 1, ""), breaks=(";", 2, "|"))
  fmt.print_string("y")
  fmt.close_box()
  assert_eq(fmt.flush_str(), "x;\n  |y")
}

///|
test "formatter is a logger and can write into another logger" {
  let out = StringBuilder()
  let fmt = @text_tags.Formatter::of_logger(out)
  let n = 42
  fmt <+ "answer = \{n}"
  fmt.print_char('!')
  fmt.print_newline()
  assert_eq(out.to_string(), "answer = 42!\n")
  // tags written through the logger interface
  let fmt = @text_tags.Formatter::new()
  @text_tags.install(fmt, "html")
  fmt.open_tag("i")
  fmt.write_string("it")
  fmt.close_tag()
  assert_eq(fmt.flush_str(), "\n <i>it</i>\n")
}
