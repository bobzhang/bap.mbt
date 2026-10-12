///|
/// Registers a `foo` plugin with a few parameters; the extension records
/// the values it observes into `seen`.
fn setup_foo(seen : Ref[String]) -> Unit raise {
  @bap_main.register_plugin("foo", provides=["analysis"], doc="Foo analysis.", () => {
    let depth = @bap_main.Configuration::parameter(
      doc="Maximum depth.",
      @bap_main.Type::int(),
      "depth",
      aliases=["d"],
    )
    let names = @bap_main.Configuration::parameters(
      doc="Names to use.",
      @bap_main.Type::string(),
      "name",
    )
    let verbose = @bap_main.Configuration::flag(doc="Be verbose.", "verbose")
    let level = @bap_main.Configuration::parameter(
      as_flag=10,
      @bap_main.Type::int().with_default(1),
      "level",
    )
    @bap_main.Extension::register(ctxt => {
      seen.val = "depth=\{ctxt.get(depth)} names=\{ctxt.get(names).join(",")} verbose=\{ctxt.get(verbose)} level=\{@bap_main.Configuration::get(ctxt, level)}"
    })
  })
}

///|
test "configuration defaults and command line" {
  fresh()
  let seen = Ref("")
  setup_foo(seen)
  inspect(run_main([]), content="ok")
  inspect(
    seen.val,
    content=(
      #|depth=0 names= verbose=false level=1
    ),
  )
  fresh()
  setup_foo(seen)
  inspect(
    run_main([
      "--foo-depth=3", "--foo-name", "a", "--foo-name=b", "--foo-verbose", "--foo-level",
    ]),
    content="ok",
  )
  inspect(
    seen.val,
    content=(
      #|depth=3 names=a,b verbose=true level=10
    ),
  )
  // aliases are prefixed too, and unambiguous prefixes are accepted
  fresh()
  setup_foo(seen)
  inspect(run_main(["--foo-d", "4", "--foo-lev=5"]), content="ok")
  inspect(
    seen.val,
    content=(
      #|depth=4 names= verbose=false level=5
    ),
  )
}

///|
test "configuration precedence: command line, environment, files" {
  fresh()
  let seen = Ref("")
  setup_foo(seen)
  inspect(
    run_main([], config=[("foo-depth", "3"), ("foo-name", "x,y")]),
    content="ok",
  )
  inspect(
    seen.val,
    content=(
      #|depth=3 names=x,y verbose=false level=1
    ),
  )
  fresh()
  setup_foo(seen)
  inspect(
    run_main([], env=[("BAP_FOO_DEPTH", "5"), ("BAP_FOO_VERBOSE", "true")], config=[
      ("foo-depth", "3"),
    ]),
    content="ok",
  )
  inspect(
    seen.val,
    content=(
      #|depth=5 names= verbose=true level=1
    ),
  )
  fresh()
  setup_foo(seen)
  inspect(
    run_main(["--foo-depth=7"], env=[("BAP_FOO_DEPTH", "5")], config=[
      ("foo-depth", "3"),
    ]),
    content="ok",
  )
  inspect(
    seen.val,
    content=(
      #|depth=7 names= verbose=false level=1
    ),
  )
}

///|
test "malformed configuration values" {
  fresh()
  let seen = Ref("")
  setup_foo(seen)
  inspect(
    run_main([], env=[("BAP_FOO_DEPTH", "deep")]),
    content=(
      #|error: Invalid parameter: the value "deep" for the parameter "foo-depth" is malformed in the process environment  - invalid value 'deep', expected an integer
    ),
  )
  fresh()
  setup_foo(seen)
  inspect(
    run_main([], config=[("foo-depth", "deep")]),
    content=(
      #|error: Invalid parameter: the value "deep" for the parameter "foo-depth" is malformed in the configuration file - invalid value 'deep', expected an integer
    ),
  )
  fresh()
  setup_foo(seen)
  inspect(
    run_main(["--foo-depth=deep"]),
    content=(
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: option '--foo-depth': invalid value 'deep', expected an integer
      #|Usage: bap [OPTION]...
      #|Try 'bap --help' for more information.
      #|
    ),
  )
  fresh()
  setup_foo(seen)
  inspect(
    run_main(["--foo-depth=1", "--foo-depth=2"]),
    content=(
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: option '--foo-depth' cannot be repeated
      #|Usage: bap [OPTION]...
      #|Try 'bap --help' for more information.
      #|
    ),
  )
  fresh()
  setup_foo(seen)
  inspect(
    run_main(["--foo-dept"]),
    content=(
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: option '--foo-dept' needs an argument
      #|Usage: bap [OPTION]...
      #|Try 'bap --help' for more information.
      #|
    ),
  )
  fresh()
  setup_foo(seen)
  inspect(
    run_main(["--foo-verbose=yes"]),
    content=(
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: option '--foo-verbose' is a flag, it cannot take the argument 'yes'
      #|Usage: bap [OPTION]...
      #|Try 'bap --help' for more information.
      #|
    ),
  )
  fresh()
  setup_foo(seen)
  inspect(
    run_main(["--foo-deep=1", "--f"]),
    content=(
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: unknown option '--foo-deep', did you mean '--foo-help'?
      #|option '--f' ambiguous and could be one of '--foo-d', '--foo-depth', '--foo-help', '--foo-level', '--foo-name' or '--foo-verbose'
      #|Usage: bap [OPTION]...
      #|Try 'bap --help' for more information.
      #|
    ),
  )
}

///|
test "configuration files are read from the configuration directories" {
  fresh()
  let seen = Ref("")
  setup_foo(seen)
  @bap_main.set_file_system(
    @bap_main.FileSystem::in_memory(
      files=[
        (
          "/home/u/.config/bap/a.conf", "# comment\nfoo-depth = 11 # trailing\n\n",
        ),
        ("/home/u/.config/bap/b.conf", "foo-depth = 12\nfoo-verbose=true\n"),
        ("/xdg/bap/config", "foo-depth = 13\nfoo-name = n1,n2\n"),
      ],
      dirs=["/home/u/.config/bap", "/xdg/bap"],
    ),
  )
  inspect(
    run_main([], env=[("HOME", "/home/u"), ("XDG_CONFIG_HOME", "/xdg")]),
    content="ok",
  )
  // the first occurrence (most specific file) wins
  inspect(
    seen.val,
    content=(
      #|depth=11 names=n1,n2 verbose=true level=1
    ),
  )
  // explicit `config` entries take precedence over files
  fresh()
  setup_foo(seen)
  @bap_main.set_file_system(
    @bap_main.FileSystem::in_memory(
      files=[("/xdg/bap/config", "foo-depth = 13\n")],
      dirs=["/xdg/bap"],
    ),
  )
  inspect(
    run_main([], env=[("XDG_CONFIG_HOME", "/xdg")], config=[("foo-depth", "1")]),
    content="ok",
  )
  inspect(
    seen.val,
    content=(
      #|depth=1 names= verbose=false level=1
    ),
  )
  // malformed lines are reported with their location
  fresh()
  setup_foo(seen)
  @bap_main.set_file_system(
    @bap_main.FileSystem::in_memory(
      files=[("/xdg/bap/config", "foo-depth = 1\nfoo-depth 2\n")],
      dirs=["/xdg/bap"],
    ),
  )
  inspect(
    run_main([], env=[("XDG_CONFIG_HOME", "/xdg")]),
    content=(
      #|error: Invalid parameter: File "/xdg/bap/config", line 2, characters 1-12
      #|Syntax error: expects <parameter> = <value>
    ),
  )
}

///|
test "context: values, digests, determined futures" {
  fresh()
  let captured : Ref[@bap_main.Ctxt?] = Ref(None)
  let depth_future : Ref[@future.Future[Int32]?] = Ref(None)
  @bap_main.register_plugin("foo", provides=["analysis"], () => {
    let depth = @bap_main.Configuration::parameter(
      @bap_main.Type::int(),
      "depth",
    )
    depth_future.val = Some(@bap_main.Configuration::determined(depth))
    @bap_main.Extension::register(ctxt => captured.val = Some(ctxt))
  })
  @bap_main.register_plugin("bar", provides=["loader"], () => {
    @bap_main.Configuration::flag("fast") |> ignore
    @bap_main.Extension::register(_ => ())
  })
  inspect(depth_future.val is None, content="true")
  inspect(run_main(["--foo-depth=3"]), content="ok")
  debug_inspect(depth_future.val.unwrap().peek(), content="Some(3)")
  let ctxt = captured.val.unwrap()
  inspect(
    ctxt,
    content=(
      #|bar-fast = false
      #|foo-depth = 3
      #|
    ),
  )
  debug_inspect(ctxt.features(), content="[\"analysis\", \"loader\"]")
  debug_inspect(ctxt.plugins().map(i => i.name()), content="[\"bar\", \"foo\"]")
  let refined = ctxt.refine(provides=["loader"])
  inspect(
    refined,
    content=(
      #|bar-fast = false
      #|
    ),
  )
  debug_inspect(
    ctxt.refine(exclude=["loader"]).features(),
    content="[\"analysis\"]",
  )
  inspect(ctxt.digest() == ctxt.digest(), content="true")
  inspect(ctxt.digest() == refined.digest(), content="false")
  inspect(ctxt.digest().length(), content="32")
  // the digest depends on parameter values
  let first = ctxt.digest()
  fresh()
  @bap_main.register_plugin("foo", provides=["analysis"], () => {
    @bap_main.Configuration::parameter(@bap_main.Type::int(), "depth") |> ignore
    @bap_main.Extension::register(ctxt => captured.val = Some(ctxt))
  })
  @bap_main.register_plugin("bar", provides=["loader"], () => {
    @bap_main.Configuration::flag("fast") |> ignore
  })
  inspect(run_main(["--foo-depth=4"]), content="ok")
  inspect(captured.val.unwrap().digest() == first, content="false")
}

///|
test "disabled plugins are not evaluated and leave the context" {
  fresh()
  let seen = Ref("")
  setup_foo(seen)
  let bar_ran = Ref(false)
  let captured : Ref[@bap_main.Ctxt?] = Ref(None)
  @bap_main.register_plugin("bar", () => {
    @bap_main.Extension::register(ctxt => {
      bar_ran.val = true
      captured.val = Some(ctxt)
    })
  })
  inspect(run_main(["--no-foo", "--foo-depth=2"]), content="ok")
  inspect(seen.val, content="")
  inspect(bar_ran.val, content="true")
  inspect(captured.val.unwrap().to_string(), content="")
  debug_inspect(
    captured.val.unwrap().plugins().map(i => i.name()),
    content="[\"bar\"]",
  )
}
