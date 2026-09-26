// Reader, parser, macros, constants, substitutions, attributes.

///|
test "reader: trees and locations" {
  let src = @primus_lisp.Source::new()
  let trees = src.load_string(
    "a.lisp", "; comment\n(foo \"bar baz\" 1:8)\n#| block |# (x #;(skipped) y)",
  )
  inspect(
    trees.map(t => t.to_string()).join(" | "),
    content="(foo \"bar baz\" 1:8) | (x y)",
  )
  inspect(
    src.loc(trees[0].id),
    content="File \"a.lisp\", line 2, characters 0-19",
  )
  guard trees[0].data is List([_, s, _]) else { fail("bad tree") }
  inspect(src.loc(s.id), content="File \"a.lisp\", line 2, characters 5-14")
  inspect(src.text_at(src.loc(s.id)), content="\"bar baz\"")
  inspect(
    src.underline(src.loc(s.id)),
    content=(
      #|| ; comment
      #|> (foo "bar baz" 1:8)
      #|>      ^^^^^^^^^
      #|| #| block |# (x #;(skipped) y)
      #|
    ),
  )
  let err = try src.load_string("b.lisp", "(foo (bar)") catch {
    e => e.to_string()
  } noraise {
    _ => "no error"
  }
  inspect(
    err,
    content="File \"b.lisp\", line 1, character 0: s-expression parse error: unexpected end of input",
  )
}

///|
fn parse_in(defs : String, exp : String) -> String raise {
  let loader = @primus_lisp.Loader::of_files([("defs.lisp", defs)])
  let prog = @primus_lisp.load_program(loader, ["defs"])
  let tree = prog.sources.read_string(exp)[0]
  prog.parse_exp(tree).to_string()
}

///|
test "literals" {
  inspect(parse_in("", "42"), content="42")
  inspect(parse_in("", "0x2a:8"), content="42:8")
  inspect(parse_in("", "-1"), content="-1")
  inspect(parse_in("", "?a"), content="97:8")
  inspect(parse_in("", "'sym"), content="sym")
  inspect(
    parse_in("", ":key"),
    content=(
      #|:key
    ),
  )
  inspect(parse_in("", "x:32"), content="x:32")
  inspect(parse_in("", "core:x"), content="core:x")
  inspect(parse_in("", "()"), content="0:1")
  inspect(
    parse_in("", "(msg \"x=$0, \\$1\" x)"),
    content="(msg \"x=$0, $1\" x)",
  )
}

///|
test "special forms" {
  inspect(
    parse_in("", "(if c a b c)"),
    content=(
      #|(if c a b c)
    ),
  )
  inspect(
    parse_in("", "(let ((x 1) (y x)) (+ x y))"),
    content="(let (x 1) (let (y x) (+ x y)))",
  )
  inspect(
    parse_in("", "(while c (set x 1) x)"),
    content="(while c (set x 1) x)",
  )
  inspect(parse_in("", "(error \"oops\")"), content="(error \"oops\")")
}

///|
test "macros, constants and substitutions" {
  let defs =
    #|(defconstant answer 42)
    #|(defconstant nil2 answer)
    #|(defmacro twice (x) (prog x x))
    #|(defmacro sum (x) x)
    #|(defmacro sum (x xs) (+ x (sum xs)))
    #|(defmacro head (x) x)
    #|(defmacro head (x y) x)
    #|(defsubst letters :ascii "ab")
    #|(defsubst bytes :hex 0a0b0c)
    #|(defsubst three 1 2 3)
  inspect(parse_in(defs, "answer"), content="42")
  inspect(parse_in(defs, "nil2"), content="42")
  inspect(parse_in(defs, "(twice (f))"), content="(prog (f) (f))")
  inspect(parse_in(defs, "(sum 1 2 3 4)"), content="(+ 1 (+ 2 (+ 3 4)))")
  inspect(parse_in(defs, "(sum 1)"), content="1")
  inspect(parse_in(defs, "(head 1 2)"), content="1")
  inspect(parse_in(defs, "(f letters)"), content="(f 97 98)")
  inspect(parse_in(defs, "(f bytes)"), content="(f 10 11 12)")
  inspect(parse_in(defs, "(sum three)"), content="(+ 1 (+ 2 3))")
}

///|
test "macro resolution errors" {
  let defs =
    #|(defmacro m (x) x)
    #|(defmacro m (y) y)
  let err = try parse_in(defs, "(m 1)") catch {
    e => {
      let lines : Array[StringView] = e.to_string().split("\n").collect()
      "\{lines[0]}\n\{lines[1]}"
    }
  } noraise {
    r => r
  }
  inspect(
    err,
    content=(
      #|File "/unknown/", line 1, characters 0-5
      #|Parse error: unable to resolve macro `m', because several equally applicable definitions were found.
    ),
  )
}

///|
test "the standard macros of the core library" {
  let loader = @primus_lisp.Loader::embedded(["lisp"])
  let prog = @primus_lisp.load_program(loader, ["core"])
  let parse = (s : String) => {
    prog
    .with_package("core")
    .parse_exp(prog.sources.read_string(s)[0])
    .to_string_in(pkg="core")
  }
  inspect(parse("(when c x y)"), content="(if c (prog x y) 0:1)")
  inspect(
    parse("(and a b c)"),
    content="(let (r a) (if r (let (r b) (if r c r)) r))",
  )
  inspect(parse("(incr x y)"), content="(prog (set x (+ x 1)) (set y (+ y 1)))")
  inspect(
    parse("(case k 1 'a 2 'b 'c)"),
    content="(let (key k) (if (= key 1) a (if (= key 2) b c)))",
  )
  inspect(parse("nil"), content="0:1")
}
