// Expected outputs were produced by the upstream OCaml implementation
// (Text_tags over OCaml 4.14 Format).

///|
fn render(mode : String, fmt_string : String) -> String raise {
  let fmt = @text_tags.Formatter::new()
  @text_tags.install(fmt, mode)
  fmt.print_format(fmt_string)
  fmt.flush_str()
}

///|
test "html mode" {
  assert_eq(
    render("html", "@{<(a (href #) (id x))>link@}"),
    "\n <a href=\"#\" id=\"x\">link</a>\n",
  )
  assert_eq(
    render("html", "@{<(a (href \"\\\"q\\\"\") (title \"hi there\"))>x@}"),
    "\n <a href=\"q\" title=\"hi there\">x</a>\n",
  )
  assert_eq(render("html", "@{<(html)>body@}"), "\n <html >body</html>\n")
  assert_eq(
    render("html", "@{<html>@{<head>@{<title>Tags!@}@}@{<body>Hello!@}@}"),
    "\n <html>\n  <head>\n   <title>Tags!</title>\n  </head>\n \n  <body>Hello!</body>\n </html>\n",
  )
}

///|
test "blocks mode" {
  assert_eq(
    render("blocks", "@{<(sub (id main))>r0 := r1@,r1 := r2@,return lr@}"),
    "\n begin(main) r0 := r1\n r1 := r2\n return lrend(main)\n",
  )
  assert_eq(
    render("blocks", "@{<(sub (id main) (title \"main function\"))>r0@,r1@}"),
    "\n begin(main function) r0\n r1end(main function)\n",
  )
  assert_eq(
    render(
      "blocks", "@{<(sub (id f))>entry:@,@{<(blk (id b1))>x := 1@,goto b2@}@,@{<plain>skip@}@}@.after",
    ),
    "\n begin(f) entry:\n \n  begin(b1) x := 1\n  goto b2end(b1)\n \n skipend(f)\n\nafter",
  )
  assert_eq(render("blocks", "a@{<x>b@}c"), "abc")
}

///|
test "attr mode" {
  @text_tags.attr_show("comment")
  assert_eq(
    render(
      "attr", "x := 1@{<.comment hello world>@}@\ny := 2@{<.address 0x10>@}@.",
    ),
    "x := 1.comment hello world\n\ny := 2\n",
  )
  @text_tags.attr_show("foreground")
  @text_tags.attr_print_colors(true)
  assert_eq(
    render("attr", "@{<.foreground \u{1b}[31m>red@}@.plain@."),
    "\u{1b}[31mred\u{1b}[39;49m\nplain\n",
  )
  @text_tags.attr_print_colors(false)
  assert_eq(
    render("attr", "@{<.foreground \u{1b}[31m>red@}@."),
    ".foreground \u{1b}[31m\nred\n",
  )
  @text_tags.attr_hide("foreground")
  assert_eq(render("attr", "@{<.foreground \u{1b}[31m>red@}@."), "red\n")
  @text_tags.attr_hide("comment")
}

///|
test "none mode and the default formatter ignore tags" {
  assert_eq(render("none", "@{<html>a@,b@}"), "a\nb")
  let fmt = @text_tags.Formatter::new()
  fmt.print_format("@{<html>a@}")
  inspect(fmt.flush_str(), content="a")
}

///|
test "modes registry" {
  assert_eq(@text_tags.available_modes(), ["blocks", "none", "html", "attr"])
  let fmt = @text_tags.Formatter::new()
  try @text_tags.install(fmt, "latex") catch {
    err => debug_inspect(err, content="UnknownMode(\"latex\")")
  } noraise {
    _ => fail("expected to fail")
  }
  @text_tags.register_mode("upper", fmt => {
    fmt.set_mark_tags(true)
    fmt.set_tag_functions({
      ..fmt.get_tag_functions(),
      mark_open_tag: tag => "[" + tag.to_upper(),
      mark_close_tag: _ => "]",
    })
  })
  assert_eq(render("upper", "@{<em>x@}"), "[EMx]")
  assert_eq(@text_tags.available_modes()[0], "upper")
}

///|
test "with_mode restores the previous mode" {
  let fmt = @text_tags.Formatter::new()
  let result = @text_tags.with_mode(fmt, "html", () => {
    fmt.print_format("@{<b>x@}")
    42
  })
  assert_eq(result, 42)
  assert_eq(fmt.flush_str(), "\n <b>x</b>\n")
  assert_true(!fmt.get_mark_tags() && !fmt.get_print_tags())
  fmt.print_format("@{<b>y@}")
  assert_eq(fmt.flush_str(), "y")
  // the previous settings are restored when the body raises
  let body : () -> Unit raise = () => {
    assert_true(fmt.get_mark_tags())
    fail("boom")
  }
  try @text_tags.with_mode(fmt, "blocks", body) catch {
    _ => ()
  } noraise {
    _ => fail("expected to fail")
  }
  assert_true(!fmt.get_mark_tags())
}
