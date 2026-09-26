///|
test "dictionary parameters" {
  fresh()
  let log = Ref("")
  @bap_main.register_plugin("dict", () => {
    let dict = @bap_main.Command::dictionary(
      ["x", "y", "z"],
      @bap_main.Type::int(),
      k => "set-" + k,
      as_flag=_ => 1,
    )
    @bap_main.Command::register("dict", @bap_main.Command::args().add(dict), dict => {
      _ => log.val = dict.map(kv => "\{kv.0}=\{kv.1}").join(" ")
    })
  })
  inspect(run_main(["dict", "--set-x=5", "--set-z"]), content="ok")
  inspect(log.val, content="z=1 y=0 x=5")
}

///|
test "grammar is checked when the command is registered" {
  fresh()
  @bap_main.register_plugin("bad", () => {
    let files = @bap_main.Command::arguments(@bap_main.Type::string())
    let n = @bap_main.Command::argument(@bap_main.Type::int())
    @bap_main.Command::register(
      "bad",
      @bap_main.Command::args().add(files).add(n),
      _ => _ => _ => (),
    )
  })
  inspect(
    run_main([]),
    content=(
      #|error: Failed to load 1 plugins, details follow:
      #|The plugin `bad' has failed with the following error:
      #|Invalid parameter: can't add an argument after arguments
      #|
    ),
  )
}

///|
test "default function and default command" {
  fresh()
  let log = Ref("")
  setup_copy(log)
  let default : (@bap_main.Ctxt) -> Unit raise = _ => log.val = "default"
  inspect(run_main([], default~), content="ok")
  inspect(log.val, content="default")
  // options without a command also go to the default function
  fresh()
  setup_copy(log)
  inspect(run_main(["--no-tools"], default~), content="ok")
  inspect(log.val, content="default")
  // the default command is inserted when no command is given
  fresh()
  setup_copy(log)
  inspect(run_main(["5", "in"], default_command="copy"), content="ok")
  inspect(
    log.val,
    content="count=5 output=a.out inputs=in verbose=0 force=false arch=- modes=",
  )
  fresh()
  setup_copy(log)
  inspect(
    run_main(["li"], default_command="copy"),
    content=(
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: command 'li' ambiguous and could be either 'lint' or 'list'
      #|Usage: bap COMMAND ...
      #|Try 'bap --help' for more information.
      #|
    ),
  )
  // without commands and a default, a positional argument is an error
  fresh()
  inspect(
    run_main(["file"]),
    content=(
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: unknown command 'file'.
      #|Usage: bap [OPTION]...
      #|Try 'bap --help' for more information.
      #|
    ),
  )
}

///|
test "commands see a refined context" {
  fresh()
  let seen = Ref("")
  @bap_main.register_plugin("loader", provides=["loader"], () => {
    @bap_main.Configuration::parameter(
      @bap_main.Type::string().with_default("raw"),
      "format",
    )
    |> ignore
  })
  @bap_main.register_plugin("printer", provides=["printer"], () => {
    @bap_main.Configuration::parameter(@bap_main.Type::string(), "style")
    |> ignore
    @bap_main.Command::register(
      "print",
      @bap_main.Command::args(),
      requires=["printer"],
      ctxt => seen.val = ctxt.to_string(),
    )
    @bap_main.Command::register("all", @bap_main.Command::args(), ctxt => {
      seen.val = ctxt.to_string() +
        ctxt.commands().map(i => "\{i.name()}: \{i.doc()}").join("\n")
    })
  })
  inspect(run_main(["print", "--printer-style=bold"]), content="ok")
  inspect(
    seen.val,
    content=(
      #|printer-style = bold
      #|
    ),
  )
  fresh()
  @bap_main.register_plugin("loader", provides=["loader"], () => {
    @bap_main.Configuration::parameter(
      @bap_main.Type::string().with_default("raw"),
      "format",
    )
    |> ignore
  })
  @bap_main.register_plugin("printer", provides=["printer"], () => {
    @bap_main.Command::register(
      "all",
      @bap_main.Command::args(),
      doc="Prints everything. And more.",
      ctxt => {
        seen.val = ctxt.to_string() +
          ctxt.commands().map(i => "\{i.name()}: \{i.doc()}").join("\n")
      },
    )
  })
  inspect(run_main(["all"]), content="ok")
  inspect(
    seen.val,
    content=(
      #|loader-format = raw
      #|all: prints everything
    ),
  )
}

///|
test "features and requirements select plugins" {
  fresh()
  let ran = []
  @bap_main.register_plugin("gui-only", features=["gui"], provides=["ui"], () => {
    @bap_main.Extension::register(_ => ran.push("gui-only"))
  })
  @bap_main.register_plugin("lifter", provides=["lifter", "semantics"], () => {
    @bap_main.Extension::register(_ => ran.push("lifter"))
  })
  @bap_main.register_plugin("loader", provides=["loader"], () => {
    @bap_main.Extension::register(_ => ran.push("loader"))
    @bap_main.Extension::register(_ => ran.push("loader-second"))
  })
  inspect(run_main([]), content="ok")
  debug_inspect(
    ran,
    content=(
      #|["lifter", "loader-second", "loader"]
    ),
  )
  debug_inspect(
    @bap_main.loaded_plugins(),
    content=(
      #|["lifter", "loader"]
    ),
  )
  ran.clear()
  @bap_main.reset()
  @bap_main.register_plugin("gui-only", features=["gui"], provides=["ui"], () => {
    @bap_main.Extension::register(_ => ran.push("gui-only"))
  })
  @bap_main.register_plugin("lifter", provides=["lifter", "semantics"], () => {
    @bap_main.Extension::register(_ => ran.push("lifter"))
  })
  @bap_main.register_plugin("loader", provides=["loader"], () => {
    @bap_main.Extension::register(_ => ran.push("loader"))
  })
  inspect(
    run_main([], features=["gui"], requires=["ui", "semantics"]),
    content="ok",
  )
  debug_inspect(
    ran,
    content=(
      #|["gui-only", "lifter"]
    ),
  )
  debug_inspect(
    @bap_main.registered_plugins(),
    content=(
      #|["gui-only", "lifter", "loader"]
    ),
  )
}

///|
test "initialization errors" {
  fresh()
  @bap_main.register_plugin("ok", () => ())
  let dup = try @bap_main.register_plugin("ok", () => ()) catch {
    e => @bap_main.error_to_string(e)
  } noraise {
    _ => "registered"
  }
  inspect(
    dup,
    content=(
      #|Invalid parameter: the plugin "ok" is already registered
    ),
  )
  @bap_main.register_plugin("broken", () => raise @bap_main.Invalid("boom"))
  inspect(
    run_main([]),
    content=(
      #|error: Failed to load 1 plugins, details follow:
      #|The plugin `broken' has failed with the following error:
      #|Invalid parameter: boom
      #|
    ),
  )
  inspect(
    run_main([]),
    content=(
      #|error: The system was left in an inconsistent state after the last attempt to initialize, which failed with:
      #|Failed to load 1 plugins, details follow:
      #|The plugin `broken' has failed with the following error:
      #|Invalid parameter: boom
      #|
    ),
  )
  fresh()
  inspect(run_main([]), content="ok")
  inspect(run_main([]), content="error: The system was already initialized")
  // errors raised by extensions stop the initialization
  fresh()
  let later = Ref(false)
  @bap_main.register_plugin("a", () => {
    @bap_main.Extension::register(_ => raise @bap_main.ExitRequested(3))
  })
  @bap_main.register_plugin("b", () => {
    @bap_main.Extension::register(_ => later.val = true)
  })
  inspect(run_main([]), content="error: Exiting with 3.")
  inspect(later.val, content="false")
  // duplicate commands
  fresh()
  @bap_main.register_plugin("a", () => {
    @bap_main.Command::register("run", @bap_main.Command::args(), _ => ())
  })
  @bap_main.register_plugin("b", () => {
    @bap_main.Command::register("run", @bap_main.Command::args(), _ => ())
  })
  inspect(
    run_main(["run"]),
    content=(
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: command 'run' is declared more than once
      #|
    ),
  )
}

///|
test "error printers" {
  inspect(
    @bap_main.error_to_string(@bap_main.ExitRequested(0)),
    content="All is good.",
  )
  inspect(
    @bap_main.error_to_string(@bap_main.UnknownPlugin("x\"y")),
    content=(
      #|There is no plugin "x\"y" in the search path.
    ),
  )
  inspect(
    @bap_main.error_to_string(@bap_main.RecursiveInit),
    content="The system initialization procedure was called during the initialization. Aborting the infinite cycle.",
  )
  inspect(
    @bap_main.error_to_string(@bap_main.BadRecipe("oops")),
    content=(
      #|Can't load the specified recipe:
      #|oops
    ),
  )
  @bap_main.register_error_printer(e => {
    match e {
      @bap_main.Invalid("custom") => Some("a custom message")
      _ => None
    }
  })
  inspect(
    @bap_main.error_to_string(@bap_main.Invalid("custom")),
    content="a custom message",
  )
  inspect(
    @bap_main.error_to_string(@bap_main.Invalid("other")),
    content="Invalid parameter: other",
  )
}

///|
test "recipes extend the command line" {
  fresh()
  let log = Ref("")
  setup_copy(log)
  let recipe : (String) -> @bap_main.Recipe raise = name => {
    if name == "fast" {
      { command: Some("copy"), args: ["--fast", "-v"], }
    } else {
      raise @bap_main.Invalid("no recipe \{name}")
    }
  }
  inspect(run_main(["--recipe=fast", "9", "--", "x"], recipe~), content="ok")
  inspect(
    log.val,
    content="count=9 output=a.out inputs=x verbose=1 force=false arch=- modes=fast",
  )
  fresh()
  setup_copy(log)
  inspect(
    run_main(["--recipe", "slow"], recipe~),
    content=(
      #|error: Can't load the specified recipe:
      #|Invalid parameter: no recipe slow
    ),
  )
  fresh()
  setup_copy(log)
  inspect(
    run_main(["--recipe", "slow"]),
    content=(
      #|error: Can't load the specified recipe:
      #|no recipe loader is available for 'slow'
    ),
  )
  // a bad recipe does not change the state: initialization can be retried
  inspect(run_main(["list"]), content="ok")
  inspect(log.val, content="list")
}

///|
test "log messages are forwarded to the log writer" {
  fresh()
  let lines = []
  @bap_main.register_plugin("chatty", () => {
    @bap_main.Extension::register(_ => {
      @main_event.message(MainLogInfo, section="chatty", message="hello")
    })
  })
  @bap_main.initialize(argv=["bap"], env=_ => None, log=s => lines.push(s))
  debug_inspect(
    lines,
    content=(
      #|["chatty.info> hello"]
    ),
  )
}

///|
test "configuration directories" {
  let env = (m : Map[String, String]) => (v : String) => m.get(v)
  inspect(
    @bap_main.Configuration::datadir(getenv=env({ "XDG_DATA_HOME": "/xdg" })),
    content="/xdg/bap",
  )
  inspect(
    @bap_main.Configuration::datadir(getenv=env({ "HOME": "/home/u" })),
    content="/home/u/.local/share/bap",
  )
  inspect(
    @bap_main.Configuration::cachedir(getenv=env({ "XDG_CACHE_HOME": "/c/" })),
    content="/c/bap",
  )
  inspect(
    @bap_main.Configuration::cachedir(getenv=env({ "HOME": "/home/u" })),
    content="/home/u/.cache/bap",
  )
  inspect(
    @bap_main.Configuration::cachedir(getenv=env({ "TMPDIR": "/tmp" })),
    content="/tmp/bap/cache",
  )
  inspect(@bap_main.Configuration::confdir(), content="/usr/local/etc/bap")
  inspect(@bap_main.Configuration::version(), content="2.6.0-alpha")
}

///|
test "plugin descriptions and extension features" {
  fresh()
  let captured : Ref[@bap_main.Ctxt?] = Ref(None)
  @bap_main.register_plugin("manifest", doc="From the manifest.", () => {
    @bap_main.Extension::register(provides=["extra"], ctxt => {
      captured.val = Some(ctxt)
    })
  })
  @bap_main.register_plugin("self", doc="Ignored.", provides=["base"], () => {
    @bap_main.Extension::register(
      doc="Documented by the extension. More text.",
      _ => (),
    )
  })
  @bap_main.register_plugin("quiet", () => ())
  inspect(run_main([]), content="ok")
  let ctxt = captured.val.unwrap()
  inspect(
    ctxt.plugins().map(i => "\{i.name()}: \{i.doc()}").join("\n"),
    content=(
      #|manifest: from the manifest
      #|quiet: no description provided
      #|self: documented by the extension
    ),
  )
  debug_inspect(
    ctxt.features(),
    content=(
      #|["base", "extra"]
    ),
  )
}
