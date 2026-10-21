///|
fn sample_fs() -> @recipe.FileSystem {
  @recipe.FileSystem::in_memory({
    "recipes/base.recipe/recipe.scm": (
      #|(parameter depth 128 "maximum depth of analysis")
      #|(option analysis-depth $depth)
      #|(option primus-lisp-load $prefix/lisp/x.lisp)
    ),
    "recipes/base.recipe/descr": "Base analysis",
    "recipes/main.scm": (
      #|; the main recipe
      #|(extend base)
      #|(command analyze)
      #|(parameter entry main "entry point")
      #|(option run-entry-points ${entry} free)
      #|(option no-optimization)
    ),
    "recipes/escape.scm": "(option price \\$10 ${entry}x)\n(parameter entry e \"\")",
    "recipes/parens.scm": "(option x $(entry))",
    "recipes/unbound.scm": "(option x $unknown)",
    "recipes/dangling.scm": "(option x abc$)",
    "recipes/bad-item.scm": "(foo bar)",
    "recipes/bad-param.scm": "(parameter x)",
    "recipes/bad-atom.scm": "(option a (b c))",
    "recipes/bad-sexp.scm": "(option a",
    "recipes/zipped.recipe": "PK\u{03}\u{04}...",
    "recipes/missing.recipe/descr": "no spec",
  })
}

///|
fn load(
  name : String,
  env~ : Array[(String, String)] = [],
) -> @recipe.Recipe raise {
  @recipe.load(paths=["recipes"], env~, fs=sample_fs(), name)
}

///|
fn load_error(name : String, env~ : Array[(String, String)] = []) -> String {
  try
    @recipe.load(paths=["nowhere", "recipes"], env~, fs=sample_fs(), name)
  catch {
    err => err.to_string()
  } noraise {
    _ => "ok"
  }
}

///|
test "loading, extension and substitution" {
  let recipe = load("main")
  assert_eq(recipe.command(), Some("analyze"))
  assert_eq(recipe.doc(), "Description was not provided")
  assert_eq(recipe.prefix(), "recipes")
  assert_eq(recipe.args(), [
    "--primus-lisp-load=recipes/base.recipe/lisp/x.lisp", "--analysis-depth=128",
    "--no-optimization", "--run-entry-points=main,free",
  ])
  assert_eq(recipe.loads().length(), 1)
  assert_eq(recipe.loads()[0].doc(), "Base analysis")
  assert_eq(recipe.params().map(p => p.to_string()), [
    "entry - entry point (defaults to main)", "depth - maximum depth of analysis (defaults to 128)",
  ])
  let p = recipe.params()[1]
  assert_eq(
    (p.name(), p.default(), p.doc()),
    ("depth", "128", "maximum depth of analysis"),
  )
  recipe.close()
}

///|
test "parameters are bound from the name and the environment" {
  let recipe = load(" main : depth = 10 ")
  assert_eq(recipe.args(), [
    "--primus-lisp-load=recipes/base.recipe/lisp/x.lisp", "--analysis-depth=10",
    "--no-optimization", "--run-entry-points=main,free",
  ])
  // as upstream, the bindings are also checked against the parameters of
  // the extended recipes when they are loaded
  inspect(load_error("main:entry=start"), content="Unknown parameter `entry'")
  let recipe = load("main", env=[("depth", "7")])
  assert_eq(recipe.args()[1], "--analysis-depth=7")
  inspect(
    load_error("main:depth=1", env=[("depth", "2")]),
    content="Variable depth was specified twice",
  )
  inspect(load_error("main:foo=1"), content="Unknown parameter `foo'")
  inspect(
    load_error("main:depth"),
    content="Parse error: bad variable definition, got `depth'",
  )
  inspect(
    load_error("main:a=b=c"),
    content="Parse error: bad variable definition, got `a=b=c'",
  )
}

///|
test "substitution syntax" {
  assert_eq(load("escape").args(), ["--price=$10,ex"])
  inspect(
    load_error("unbound"),
    content="Don't know how to substitute $unknown",
  )
  inspect(load_error("dangling"), content="Don't know how to substitute $abc$")
  // `$(name)` is not usable, since parentheses delimit s-expressions
  inspect(
    load_error("parens"),
    content="Parse error: expected an atom got (entry)",
  )
}

///|
test "argv generation" {
  let recipe = load("main")
  let args = recipe.args()
  assert_eq(recipe.argv(), ["analyze", ..args])
  assert_eq(recipe.argv(argv=["bap"]), ["bap", "analyze", ..args])
  assert_eq(
    recipe.argv(argv=["bap", "/bin/ls"]),
    ["bap", "analyze", "/bin/ls", ..args],
  )
  // the second argument is a prefix of the command
  assert_eq(
    recipe.argv(argv=["bap", "ana", "x"]),
    ["bap", "analyze", "x", ..args],
  )
  assert_eq(
    recipe.argv(argv=["bap", "/bin/ls", "--", "y"]),
    ["bap", "analyze", "/bin/ls", ..args, "--", "y"],
  )
  let base = recipe.loads()[0]
  assert_eq(base.command(), None)
  assert_eq(
    base.argv(argv=["bap", "x", "--", "y"]),
    ["bap", "x", ..base.args(), "--", "y"],
  )
}

///|
test "errors" {
  inspect(load_error("nope"), content="Can't find the required recipe `nope'")
  inspect(
    load_error("bad-item"),
    content="Parse error: unknown recipe item - (foo bar)",
  )
  inspect(
    load_error("bad-param"),
    content="Syntax error in the parameter `x' specification. Expecting: (parameter <name> <value> <desc>)",
  )
  inspect(
    load_error("bad-atom"),
    content="Parse error: expected an atom got (bc)",
  )
  inspect(
    load_error("bad-sexp"),
    content="Parse error: line 1, column 9: unclosed parentheses at end of input",
  )
  inspect(
    load_error("zipped"),
    content="Malformed recipe: recipes/zipped.recipe, , zipped recipes are not supported",
  )
  inspect(
    load_error("missing"),
    content="The required file `recipes/missing.recipe/recipe.scm' is missing",
  )
  // the search continues in the next directories
  try
    @recipe.load(
      paths=["recipes/base.recipe", "recipes"],
      fs=sample_fs(),
      "main",
    )
  catch {
    err => fail(err.to_string())
  } noraise {
    recipe => assert_eq(recipe.command(), Some("analyze"))
  }
}

///|
test "search" {
  assert_eq(@recipe.search(["recipes", "nowhere"], fs=sample_fs()), [
    "recipes/base.recipe", "recipes/missing.recipe", "recipes/zipped.recipe",
  ])
  assert_eq(@recipe.search(["nowhere"], fs=sample_fs()), [])
}

///|
test "path helpers" {
  assert_eq(@recipe.concat("a", "b"), "a/b")
  assert_eq(@recipe.concat("a/", "b"), "a/b")
  assert_eq(@recipe.concat("", "b"), "b")
  assert_eq(@recipe.dirname("a/b/c"), "a/b")
  assert_eq(@recipe.dirname("a//b/"), "a")
  assert_eq(@recipe.dirname("c"), ".")
  assert_eq(@recipe.dirname("/c"), "/")
  assert_eq(@recipe.basename("a/b/c"), "c")
  assert_eq(@recipe.basename("a/b/"), "b")
  assert_eq(@recipe.basename("/"), "/")
}
