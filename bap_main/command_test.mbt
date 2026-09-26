///|
/// Registers a `tools` plugin with a `copy` command whose invocations are
/// recorded in `log`.
fn setup_copy(log : Ref[String]) -> Unit raise {
  @bap_main.register_plugin("tools", provides=["tools"], () => {
    let count = @bap_main.Command::argument(
      doc="How many copies.",
      @bap_main.Type::int(),
    )
    let output = @bap_main.Command::parameter(
      doc="The output file.",
      @bap_main.Type::string().with_default("a.out"),
      "output",
      aliases=["o"],
    )
    let inputs = @bap_main.Command::arguments(
      doc="The input files.",
      @bap_main.Type::string().rename("FILE"),
    )
    let verbose = @bap_main.Command::flags(doc="Verbosity.", "verbose", aliases=[
      "v",
    ])
    let force = @bap_main.Command::flag("force")
    let arch = @bap_main.Command::switch(["x86", "arm"], a => a)
    let modes = @bap_main.Command::switches(["fast", "safe"], m => m, aliases=m => {
      [if m == "fast" { "F" } else { "S" }]
    })
    let grammar = @bap_main.Command::args()
      .add(count)
      .add(output)
      .add(inputs)
      .add(verbose)
      .add(force)
      .add(arch)
      .add(modes)
    @bap_main.Command::register(
      "copy",
      grammar,
      doc="Copies files.\n\nCopies the input files to the output.",
      count => {
        output => {
          inputs => {
            verbose => {
              force => {
                arch => {
                  modes => {
                    _ => {
                      log.val = "count=\{count} output=\{output} inputs=\{inputs.join(",")} verbose=\{verbose} force=\{force} arch=\{arch.unwrap_or("-")} modes=\{modes.join(",")}"
                    }
                  }
                }
              }
            }
          }
        }
      },
    )
    @bap_main.Command::register("list", @bap_main.Command::args(), _ => {
      log.val = "list"
    })
    @bap_main.Command::register("lint", @bap_main.Command::args(), _ => {
      log.val = "lint"
    })
  })
}

///|
test "command arguments and options" {
  let log = Ref("")
  fresh()
  setup_copy(log)
  inspect(
    run_main(["copy", "3", "a", "b", "-o", "out", "-vvv", "--arm"]),
    content="ok",
  )
  inspect(
    log.val,
    content="count=3 output=out inputs=a,b verbose=3 force=false arch=arm modes=",
  )
  fresh()
  setup_copy(log)
  inspect(
    run_main([
      "cop", "-ofile", "--force", "--fast", "-S", "--fast", "7", "--", "-dash",
    ]),
    content="ok",
  )
  inspect(
    log.val,
    content=(
      #|count=7 output=file inputs=-dash verbose=0 force=true arch=- modes=fast,safe,fast
    ),
  )
  // no arguments at all: defaults
  fresh()
  setup_copy(log)
  inspect(run_main(["copy"]), content="ok")
  inspect(
    log.val,
    content=(
      #|count=0 output=a.out inputs= verbose=0 force=false arch=- modes=
    ),
  )
  fresh()
  setup_copy(log)
  inspect(run_main(["list"]), content="ok")
  inspect(log.val, content="list")
}

///|
test "command line errors" {
  let log = Ref("")
  let errors = [
    ["copy", "x"],
    ["copy", "1", "--output"],
    ["copy", "-o", "a", "-o", "b"],
    ["copy", "--x86", "--arm"],
    ["copy", "--force", "--force"],
    ["copy", "--forc=yes"],
    ["copy", "--unknown"],
    ["cp"],
    ["c"],
    ["l"],
    ["list", "extra"],
  ]
  let sb = StringBuilder()
  for argv in errors {
    fresh()
    setup_copy(log)
    sb.write_string("$ bap \{argv.join(" ")}\n")
    sb.write_string(run_main(argv))
    sb.write_string("\n")
  }
  inspect(
    sb.to_string(),
    content=(
      #|$ bap copy x
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: VAL argument: invalid value 'x', expected an integer
      #|Usage: bap copy [OPTION]... [VAL] [FILE]...
      #|Try 'bap copy --help' or 'bap --help' for more information.
      #|
      #|$ bap copy 1 --output
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: option '--output' needs an argument
      #|Usage: bap copy [OPTION]... [VAL] [FILE]...
      #|Try 'bap copy --help' or 'bap --help' for more information.
      #|
      #|$ bap copy -o a -o b
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: option '-o' cannot be repeated
      #|Usage: bap copy [OPTION]... [VAL] [FILE]...
      #|Try 'bap copy --help' or 'bap --help' for more information.
      #|
      #|$ bap copy --x86 --arm
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: options '--x86' and '--arm' cannot be present at the same time
      #|Usage: bap copy [OPTION]... [VAL] [FILE]...
      #|Try 'bap copy --help' or 'bap --help' for more information.
      #|
      #|$ bap copy --force --force
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: option '--force' cannot be repeated
      #|Usage: bap copy [OPTION]... [VAL] [FILE]...
      #|Try 'bap copy --help' or 'bap --help' for more information.
      #|
      #|$ bap copy --forc=yes
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: option '--forc' is a flag, it cannot take the argument 'yes'
      #|Usage: bap copy [OPTION]... [VAL] [FILE]...
      #|Try 'bap copy --help' or 'bap --help' for more information.
      #|
      #|$ bap copy --unknown
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: unknown option '--unknown'.
      #|Usage: bap copy [OPTION]... [VAL] [FILE]...
      #|Try 'bap copy --help' or 'bap --help' for more information.
      #|
      #|$ bap cp
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: unknown command 'cp', did you mean 'copy'?
      #|Usage: bap COMMAND ...
      #|Try 'bap --help' for more information.
      #|
      #|$ bap c
      #|ok
      #|$ bap l
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: command 'l' ambiguous and could be either 'lint' or 'list'
      #|Usage: bap COMMAND ...
      #|Try 'bap --help' for more information.
      #|
      #|$ bap list extra
      #|error: Failed to process command-line options and configuration paratemers.
      #|--- err ---
      #|bap: too many arguments, don't know what to do with 'extra'
      #|Usage: bap list [OPTION]...
      #|Try 'bap list --help' or 'bap --help' for more information.
      #|
      #|
    ),
  )
}
