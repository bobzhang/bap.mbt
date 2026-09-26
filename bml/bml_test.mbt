///|
fn tid(name : String) -> @types.Tid {
  @types.Tid::for_name(name)
}

///|
fn reg(name : String) -> @types.Var {
  @types.Var::new(name~, typ=Imm(32))
}

///|
/// @main: @b1 [ @d1: x := y + 1; @d2: z := x; @j1: goto @b1 ]
/// @other: @b2 [ @d3: y := 0 ]
fn sample_program() -> @types.Term[@types.Program] {
  let one = @types.Exp::Int(try! @types.Word::of_int(width=32, 1))
  let b1 = @types.Blk::create(
    tid=tid("b1"),
    defs=[
      @types.Def::create(
        reg("x"),
        BinOp(Plus, Var(reg("y")), one),
        tid=tid("d1"),
      ),
      @types.Def::create(reg("z"), Var(reg("x")), tid=tid("d2")),
    ],
    jmps=[@types.Jmp::create_goto(Direct(tid("b1")), tid=tid("j1"))],
  )
  let main = @types.Sub::create(name="main", blks=[b1], tid=tid("main")).with_visited()
  let b2 = @types.Blk::create(tid=tid("b2"), defs=[
    @types.Def::create(reg("y"), one, tid=tid("d3")),
  ])
  let other = @types.Sub::create(name="other", blks=[b2], tid=tid("other"))
  @types.Program::create(subs=[main, other])
}

///|
fn find(prog : @types.Term[@types.Program], name : String) -> @types.IrTerm {
  let terms = prog.program_terms()
  for term in terms {
    if term.tid() == tid(name) {
      return term
    }
  }
  abort("no term \{name}")
}

///|
fn apply(pattern : String) -> @types.Term[@types.Program] raise {
  match @bml.map_terms([pattern], sample_program()) {
    Ok(prog) => prog
    Err(err) => fail(err)
  }
}

///|
test "parse errors" {
  let err = (text : String) => {
    match @bml.parse_string(text) {
      Ok(_) => "ok"
      Err(e) => e
    }
  }
  inspect(err("((is-visited) (foreground blue))"), content="ok")
  inspect(
    err("((is-visited) (foreground purple))"),
    content=(
      #|Expected black | red | green | yellow | blue | magenta | cyan | white | gray got "purple"
    ),
  )
  inspect(
    err("((foo) (set-mark))"),
    content=(
      #|Unbound name: "foo"
    ),
  )
  inspect(
    err("((is-visited x) (set-mark))"),
    content="Term is-visited has arity 1",
  )
  inspect(err("((term-name) (set-mark))"), content="Term term-name has arity 0")
  inspect(
    err("((a)"),
    content="Syntax error: line 1, column 4 - unclosed parentheses at end of input",
  )
  inspect(
    err("(a b c)"),
    content=(
      #|expect "("<preds> <marks>")"
    ),
  )
  inspect(err("(a (set-mark))"), content="expected <expr> got a")
  inspect(
    err("((true x y) (set-mark))"),
    content="expected <exp> got (true x y)",
  )
  // lists of expressions, nested lists and empty lists
  guard @bml.parse_string("(((true) ((is-visited))) ())") is Ok(p) else {
    fail("expected a pattern")
  }
  assert_eq(p.preds.length(), 2)
  assert_eq(p.mappers.length(), 0)
}

///|
test "markers are applied to terms and all their subterms" {
  let prog = apply("((is-visited) (foreground blue))")
  assert_eq(find(prog, "main").foreground(), Some(IrBlue))
  assert_eq(find(prog, "b1").foreground(), Some(IrBlue))
  assert_eq(find(prog, "d2").foreground(), Some(IrBlue))
  assert_eq(find(prog, "other").foreground(), None)
  assert_eq(find(prog, "d3").foreground(), None)
  // the program term itself is not matched
  assert_true(prog.foreground() is None)
  let prog = apply("((has-foreground red) (set-mark))")
  assert_true(!find(prog, "main").has_mark())
}

///|
test "definition predicates and comments" {
  let prog = apply("((def-lhs x) (comment \"assigns x\"))")
  assert_eq(find(prog, "d1").comment(), Some("assigns x"))
  assert_eq(find(prog, "d2").comment(), None)
  let prog = apply("((def-uses x) (python \"print(1)\"))")
  assert_eq(find(prog, "d2").python(), Some("print(1)"))
  assert_eq(find(prog, "d1").python(), None)
  let prog = apply("(((term-name @d3) (true)) (set-dead))")
  assert_true(find(prog, "d3").is_dead())
  assert_true(!find(prog, "d1").is_dead())
  let prog = apply("((term-tid @j1) (set-synthetic))")
  assert_true(find(prog, "j1").is_synthetic())
  assert_true(!find(prog, "b1").is_synthetic())
}

///|
test "term-parent" {
  // the block containing @d1 is marked, as are its subterms
  let prog = apply("((term-parent @d1) (set-mark))")
  assert_true(find(prog, "b1").has_mark())
  assert_true(find(prog, "d2").has_mark())
  assert_true(!find(prog, "main").has_mark())
  assert_true(!find(prog, "b2").has_mark())
  // the subroutine containing the block @b2
  let prog = apply("((term-parent @b2) (set-live))")
  assert_true(find(prog, "other").is_live())
  assert_true(find(prog, "d3").is_live())
  assert_true(!find(prog, "main").is_live())
}

///|
test "unset-attr and sub markers" {
  let prog = apply("((true) (unset-attr visited))")
  assert_true(!find(prog, "main").is_visited())
  let prog = apply("((is-visited) (set-noreturn-sub))")
  assert_true(find(prog, "main").is_sub_noreturn())
  let prog = apply("((term-name @other) ((set-const-sub) (set-stub-sub)))")
  assert_true(find(prog, "other").is_sub_const())
  assert_true(find(prog, "other").is_sub_stub())
}

///|
test "taints" {
  let prog = apply("((term-name @d1) (taint-reg))")
  assert_eq(find(prog, "d1").tainted_reg(), Some(tid("d1")))
  let seeded = prog
  let tainted = @bml.map_terms(["((taints) (set-mark))"], seeded).unwrap()
  assert_true(find(tainted, "d1").has_mark())
  assert_true(!find(tainted, "d2").has_mark())
  // as upstream, the unary taints-ptr checks the register seed
  let tainted = @bml.map_terms(["((taints-ptr @d1) (set-mark))"], seeded).unwrap()
  assert_true(find(tainted, "d1").has_mark())
  // taint sets
  let prog = sample_program()
  let prog = @bml.map_program(
    [
      @bml.Pattern::new([@bml.has("nothing")], []),
      @bml.Pattern::new([term => term.tid() == tid("d2")], [
        term => {
          term.set_attr(
            @types.Attr::new(key=@bml.tainted_regs_attr, value="((x (%12 @t)))"),
          )
        },
      ]),
    ],
    prog,
  )
  let marked = @bml.map_terms(
    ["((has-tainted-reg @t) (set-mark))", "((has-taints) (set-visited))"],
    prog,
  ).unwrap()
  assert_true(find(marked, "d2").has_mark())
  assert_true(!find(marked, "d1").has_mark())
  assert_true(find(marked, "d2").is_visited())
  let marked = @bml.map_terms(["((has-tainted-reg @u) (set-mark))"], prog).unwrap()
  assert_true(!find(marked, "d2").has_mark())
}

///|
test "registries can be extended" {
  @bml.predicates.nullary.register("is-def", term => term is DefTerm(_))
  @bml.mappers.unary.register("set-flag", s => @bml.marker(@types.Attr::flag(s)))
  let prog = apply("((is-def) (set-flag touched))")
  assert_true(find(prog, "d1").has_flag("touched"))
  assert_true(!find(prog, "b1").has_flag("touched"))
  assert_true(@bml.predicates.nullary.find("is-def") is Some(_))
  assert_true(@bml.mappers.nullary.find("is-def") is None)
  let names = @bml.predicates.nullary.list().map(entry => entry.0)
  assert_true(names.contains("true") && names.contains("is-synthetic"))
  assert_true(names.contains("is-returns-twice-sub"))
  assert_true(names.contains("is-alloc-size-arg") && names.contains("has-mark"))
  let names = @bml.mappers.nullary.list().map(entry => entry.0)
  assert_true(
    names.contains("set-visited") && names.contains("set-nonnull-arg"),
  )
}

///|
test "patterns files" {
  let text =
    #|; color visited terms
    #|((is-visited) (foreground blue))
    #|#| a block comment |#
    #|((def-lhs z) ((comment "z") (set-mark)))
  guard @bml.parse_patterns(text) is Ok(patterns) else { fail("parse failed") }
  assert_eq(patterns.length(), 2)
  let prog = @bml.map_program(patterns, sample_program())
  assert_eq(find(prog, "d2").comment(), Some("z"))
  assert_true(find(prog, "d2").has_mark())
  assert_eq(find(prog, "d2").foreground(), Some(IrBlue))
  guard @bml.parse_patterns("((true) (set-mark))\n((true) (nope))") is Err(err) else {
    fail("expected an error")
  }
  inspect(
    err,
    content=(
      #|Unbound name: "nope"
    ),
  )
  let sexp : @bml.Sexp = List([Atom("a b"), List([]), Atom("")])
  inspect(sexp.to_string(), content="(\"a b\" () \"\")")
}
