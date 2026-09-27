///|
fn setup_help() -> Unit raise {
  fresh()
  let log = Ref("")
  setup_copy(log)
  @bap_main.register_plugin("foo", doc="Foo analysis.", () => {
    @bap_main.Extension::documentation(
      "# DESCRIPTION\n\nAnalyses the foo of a binary.\n\n# EXAMPLES\n\n```\nbap --foo-depth=3\n```",
    )
    @bap_main.Configuration::parameter(
      doc="Maximum depth of the $(b,foo) analysis.",
      @bap_main.Type::int().with_default(8),
      "depth",
    )
    |> ignore
    @bap_main.Configuration::flag("verbose") |> ignore
  })
}

///|
let host_man : String =
  #|# DESCRIPTION
  #|
  #|The Binary Analysis Platform. This paragraph is long enough to be
  #|wrapped to the manual page width by the plain text renderer, as
  #|Cmdliner would do.
  #|
  #|- first item
  #|
  #|# SEE ALSO
  #|
  #|bap-copy(1)

///|
test "main help page" {
  setup_help()
  inspect(
    run_main(["--help"], man=host_man),
    content=(
      #|ok
      #|--- out ---
      #|NAME
      #|       bap
      #|
      #|SYNOPSIS
      #|       bap COMMAND ...
      #|
      #|DESCRIPTION
      #|       The Binary Analysis Platform. This paragraph is long enough to be wrapped
      #|       to the manual page width by the plain text renderer, as Cmdliner would
      #|       do.
      #|
      #|       -   first item
      #|
      #|COMMANDS
      #|       copy
      #|           copies files
      #|
      #|       lint
      #|           no description provided
      #|
      #|       list
      #|           no description provided
      #|
      #|OPTIONS
      #|       -L VAL, --plugin-path=VAL, --load-path=VAL
      #|           Adds folder to the list of plugins search paths
      #|
      #|       --logdir=VAL, --log-dir=VAL
      #|           A folder for log files. (absent BAP_LOG_DIR env)
      #|
      #|       --recipe=VAL
      #|           Load the specified recipe
      #|
      #|COMMON OPTIONS
      #|       --foo-depth=VAL
      #|           Maximum depth of the foo analysis. (absent=8)
      #|
      #|       --foo-help[=VAL]
      #|           prints more information about the foo plugin (default=auto)
      #|
      #|       --foo-verbose
      #|           Undocumented
      #|
      #|       --help[=FMT]
      #|           Show this help in format FMT. The value FMT must be one of 'auto',
      #|           'pager', 'groff' or 'plain'. With 'auto', the format is 'pager' or
      #|           'plain' whenever the TERM env var is 'dumb' or undefined.
      #|           (default=auto)
      #|
      #|       --no-foo
      #|           Disable the foo plugin
      #|
      #|       --no-tools
      #|           Disable the tools plugin
      #|
      #|       --tools-help[=VAL]
      #|           prints more information about the tools plugin (default=auto)
      #|
      #|       --version
      #|           Show version information.
      #|
      #|ENVIRONMENT
      #|       BAP_LOG_DIR
      #|           A folder for log files.
      #|
      #|SEE ALSO
      #|       bap-copy(1)
      #|
    ),
  )
}

///|
test "command help page" {
  setup_help()
  inspect(
    run_main(["copy", "--help=plain"]),
    content=(
      #|ok
      #|--- out ---
      #|NAME
      #|       bap-copy - copies files
      #|
      #|SYNOPSIS
      #|       bap copy [OPTION]... [VAL] [FILE]...
      #|
      #|DESCRIPTION
      #|       Copies files.
      #|
      #|       Copies the input files to the output.
      #|
      #|ARGUMENTS
      #|       FILE
      #|           The input files.
      #|
      #|       VAL How many copies. (absent=0)
      #|
      #|OPTIONS
      #|       --arm
      #|           Select arm
      #|
      #|       -F, --fast
      #|           Select fast
      #|
      #|       -L VAL, --plugin-path=VAL, --load-path=VAL
      #|           Adds folder to the list of plugins search paths
      #|
      #|       --logdir=VAL, --log-dir=VAL
      #|           A folder for log files. (absent BAP_LOG_DIR env)
      #|
      #|       -o VAL, --output=VAL
      #|           The output file. (absent=a.out)
      #|
      #|       --recipe=VAL
      #|           Load the specified recipe
      #|
      #|       -S, --safe
      #|           Select safe
      #|
      #|       -v, --verbose
      #|           Verbosity.
      #|
      #|       --x86
      #|           Select x86
      #|
      #|COMMON OPTIONS
      #|       --foo-depth=VAL
      #|           Maximum depth of the foo analysis. (absent=8)
      #|
      #|       --foo-help[=VAL]
      #|           prints more information about the foo plugin (default=auto)
      #|
      #|       --foo-verbose
      #|           Undocumented
      #|
      #|       --help[=FMT]
      #|           Show this help in format FMT. The value FMT must be one of 'auto',
      #|           'pager', 'groff' or 'plain'. With 'auto', the format is 'pager' or
      #|           'plain' whenever the TERM env var is 'dumb' or undefined.
      #|           (default=auto)
      #|
      #|       --no-foo
      #|           Disable the foo plugin
      #|
      #|       --no-tools
      #|           Disable the tools plugin
      #|
      #|       --tools-help[=VAL]
      #|           prints more information about the tools plugin (default=auto)
      #|
      #|       --version
      #|           Show version information.
      #|
      #|ENVIRONMENT
      #|       BAP_LOG_DIR
      #|           A folder for log files.
      #|
    ),
  )
}

///|
test "plugin manual, version, and help errors" {
  setup_help()
  inspect(
    run_main(["--foo-help"]),
    content=(
      #|error: All is good.
      #|--- out ---
      #|DESCRIPTION
      #|       Analyses the foo of a binary.
      #|
      #|EXAMPLES
      #|
      #|       bap --foo-depth=3
      #|
      #|
    ),
  )
  setup_help()
  inspect(
    run_main(["--tools-help"]),
    content=(
      #|error: All is good.
    ),
  )
  setup_help()
  inspect(
    run_main(["--version"]),
    content=(
      #|ok
      #|--- out ---
      #|2.6.0-alpha
      #|
    ),
  )
  // `--help` wins over parse errors
  setup_help()
  inspect(
    run_main(["--unknown", "--help"]),
    content=(
      #|ok
      #|--- out ---
      #|NAME
      #|       bap
      #|
      #|SYNOPSIS
      #|       bap COMMAND ...
      #|
      #|COMMANDS
      #|       copy
      #|           copies files
      #|
      #|       lint
      #|           no description provided
      #|
      #|       list
      #|           no description provided
      #|
      #|OPTIONS
      #|       -L VAL, --plugin-path=VAL, --load-path=VAL
      #|           Adds folder to the list of plugins search paths
      #|
      #|       --logdir=VAL, --log-dir=VAL
      #|           A folder for log files. (absent BAP_LOG_DIR env)
      #|
      #|       --recipe=VAL
      #|           Load the specified recipe
      #|
      #|COMMON OPTIONS
      #|       --foo-depth=VAL
      #|           Maximum depth of the foo analysis. (absent=8)
      #|
      #|       --foo-help[=VAL]
      #|           prints more information about the foo plugin (default=auto)
      #|
      #|       --foo-verbose
      #|           Undocumented
      #|
      #|       --help[=FMT]
      #|           Show this help in format FMT. The value FMT must be one of 'auto',
      #|           'pager', 'groff' or 'plain'. With 'auto', the format is 'pager' or
      #|           'plain' whenever the TERM env var is 'dumb' or undefined.
      #|           (default=auto)
      #|
      #|       --no-foo
      #|           Disable the foo plugin
      #|
      #|       --no-tools
      #|           Disable the tools plugin
      #|
      #|       --tools-help[=VAL]
      #|           prints more information about the tools plugin (default=auto)
      #|
      #|       --version
      #|           Show version information.
      #|
      #|ENVIRONMENT
      #|       BAP_LOG_DIR
      #|           A folder for log files.
      #|
    ),
  )
  setup_help()
  inspect(
    run_main(["--help=bogus"]),
    content=(
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: option '--help': invalid value 'bogus', expected one of 'auto', 'pager', 'groff' or 'plain'
      #|
    ),
  )
}

///|
test "markdown manual pages" {
  debug_inspect(
    @bap_main.markdown_to_manpage(
      "Intro text\nspanning lines.\n\n## Usage\n\n1. first\n\n2) second\n\n* star\n\n```\ncode\n\nmore code\n```\n\ntrailing```\n\n```one line```",
    ),
    content=(
      #|[
      #|  Paragraph("Intro text\nspanning lines."),
      #|  Section("Usage"),
      #|  Item("1", "first"),
      #|  Item("2", "second"),
      #|  Item("*", "star"),
      #|  Verbatim("\ncode\n\nmore code\n"),
      #|  Paragraph("ERROR: Unbalanced ```"),
      #|  Paragraph("trailing"),
      #|  Verbatim("one line"),
      #|]
    ),
  )
}
