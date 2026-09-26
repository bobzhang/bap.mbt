// The `disassemble` and `compare` commands (upstream
// `Disassemble_main`).

///|
/// The name of the plugin.
pub let plugin_name : String = "disassemble"

///|
/// The manual of the `disassemble` command.
pub let man : String =
  #|
  #|# DESCRIPTION
  #|
  #|Disassembles and analyzes the input file. This is the default
  #|command of the bap frontend which is assumed when no other command
  #|was specified.
  #|
  #|The input file is automatically parsed (unless the $(b,--raw) or
  #|$(b,--loader) options were specified), then the extracted code, if
  #|any, is disassembled, and the `Bap.Std.project` data structure is
  #|built, on which the specified passes are run.
  #|
  #|# PASSES
  #|
  #|The passes are specified by the $(b,--pass) option and are run in the
  #|order in which they specified. In addition, all passes that are
  #|flagged with `autorun' are run before the explicitly specified
  #|passes. Finally, if a pass specifies other passes as its
  #|dependencies, then they are run before it, in the order in which
  #|they were specified (modulo their own dependencies).
  #|
  #|It's also possible to specify the passes using the old style syntax,
  #|e.g., `$(b,--<PASS>)`, which is discouraged and later could be disabled.
  #|Additionaly, it is not allowed to mix passes the old and the new
  #|style.
  #|
  #|# OUTPUT
  #|
  #|After all passes are run on the input, the resulting project data
  #|structure could be dumped using the $(b,--dump) (or $(b,-d) for short)
  #|option, whichaccepts the desired format and, optionally, the output
  #|file name.
  #|
  #|It is possible to specify the $(b,--dump) option multiple times, in
  #|which case the project will be dumped in several formats.
  #|
  #|# DISASSEMBLY COMPONENTS
  #|
  #|The $(b,--disassembler), $(b,--rooters), $(b,--symbolizers),
  #|$(b,--branchers), and $(b,--reconstructor) options select the
  #|registered components that build the project. By default the
  #|$(b,recursive) disassembler (the recursive descent over the Basic
  #|decoder) is used together with all registered rooters, symbolizers,
  #|and branchers.
  #|
  #|# EXAMPLES
  #|
  #|```
  #|  bap dis /bin/echo --passes=run,check -dbir:out.bir -dasm:out.asm
  #|```
  #|

///|
/// The features required by the `disassemble` command.
pub let features_used : Array[String] = [
  "semantics", "function-starts", "disassembler", "lifter", "symbolizer", "rooter",
  "reconstructor", "brancher", "loader", "abi",
]

///|
/// A file that may not exist yet (upstream `rw_file`).
fn rw_file() -> @bap_main.Type[String] {
  @bap_main.Type::create(
    name="<FILE>",
    digest=path => {
      match (@bap_main.file_system().read_file)(path) {
        Some(bytes) => @utf8.decode_lossy(bytes)
        None => "empty"
      }
    },
    parse=s => s,
    print=s => s,
    "",
  )
}

///|
/// The target type (`Theory.Target.lookup ~package:"bap"`).
pub fn target_type() -> @bap_main.Type[@core_theory.Target] {
  @bap_main.Type::create(
    name="NAME",
    parse=s => {
      // Upstream declares architecture targets in the `bap` package; the
      // port's built-in targets live in their own package, so fall back to an
      // unqualified lookup (which also accepts nicknames such as `x86_64`).
      let found = match @core_theory.Target::lookup(s, pkg="bap") {
        Some(t) => Some(t)
        None => @core_theory.Target::lookup(s)
      }
      match found {
        Some(t) => t
        None =>
          raise @bap_main.Invalid(
            "unknown target \{quote(s)}, please see `bap list targets' for the full list of targets",
          )
      }
    },
    print=t => t.to_string(),
    @core_theory.Target::unknown(),
  )
}

///|
fn opt_string(name : String, doc : String) -> @bap_main.CommandParam[String?] {
  @bap_main.Command::parameter(
    doc~,
    @bap_main.Type::some(@bap_main.Type::string()),
    name,
  )
}

///|
fn opt_list(
  name : String,
  doc : String,
) -> @bap_main.CommandParam[Array[String]?] {
  @bap_main.Command::parameter(
    doc~,
    @bap_main.Type::some(@bap_main.Type::list(@bap_main.Type::string())),
    name,
  )
}

///|
/// The command-line parameters shared by `disassemble` and `compare`.
priv struct Params {
  outputs : @bap_main.CommandParam[Array[String]]
  old_style_passes : @bap_main.CommandParam[Array[String]]
  passes : @bap_main.CommandParam[Array[Array[String]]]
  loader : @bap_main.CommandParam[String]
  target : @bap_main.CommandParam[@core_theory.Target]
  update : @bap_main.CommandParam[Bool]
  knowledge : @bap_main.CommandParam[String?]
}

///|
fn Params::new() -> Params {
  let plugins = @bap_main.registered_plugins()
  {
    old_style_passes: @bap_main.Command::switches(
      doc=name => "Enables the pass \{name} in the old style (DEPRECATED)",
      plugins,
      name => name,
    ),
    passes: @bap_main.Command::parameters(
      doc="Run the selected passes (in the specified order)",
      aliases=["p"],
      @bap_main.Type::list(@bap_main.Type::string()).rename("PASSES"),
      "passes",
    ),
    outputs: @bap_main.Command::parameters(
      doc="Dumps the program to <FILE> (defaults to stdout) in the <FMT> format (defaults to bir).",
      as_flag="bir",
      aliases=["d"],
      @bap_main.Type::string().rename("[<FMT>[:<FILE>]]"),
      "dump",
    ),
    update: @bap_main.Command::flag(
      "update",
      aliases=["u"],
      doc="Preserve the knowledge base, i.e., do not change it.",
    ),
    knowledge: @bap_main.Command::parameter(
      doc="Import the knowledge to the provided knowledge base. If the $(b,--update) flag is set the the knowledge base will be also updated with the new information. If $(b,--update) is set, the the knowledge base might not exist and it will be created",
      aliases=["k", "knowledge-base"],
      @bap_main.Type::some(rw_file()),
      "project",
    ),
    loader: @bap_main.Command::parameter(
      doc="Use the specified loader. The loader could be either an identifier or a filename. The default loader $(b,llvm) selects the loader by the file name and contents. To load unstructured files use the $(b,raw) loader.",
      @bap_main.Type::string().with_default("llvm"),
      "loader",
    ),
    target: @bap_main.Command::parameter(
      doc="Sets the target architecture of the binary. See `bap list targets` for the full hierarchy of targets.",
      target_type(),
      "target",
    ),
  }
}

///|
/// Validates the pass options and the dump formats.
fn prepare(
  old_style : Array[String],
  passes : Array[Array[String]],
  outputs : Array[String],
) -> (Array[@project.ProjectPass], Array[Output]) raise DisassembleError {
  let names = validate_passes_style(
    old_style,
    passes.fold(init=[], (a, b) => a + b),
  )
  let passes = validate_passes(names)
  let outputs = outputs.map(Output::parse)
  (passes, outputs)
}

///|
fn declare_disassemble(
  params : Params,
  out : (String) -> Unit,
  write_file : (String, String) -> Result[Unit, String],
) -> Unit raise {
  let input = @bap_main.Command::argument(
    doc="The input file",
    @bap_main.Type::string().with_default("a.out").rename("FILE"),
  )
  let libraries = @bap_main.Command::parameters(
    doc="The input libraries to link with",
    aliases=["l"],
    @bap_main.Type::list(@bap_main.Type::string()).rename("FILES"),
    "libraries",
  )
  let print_missing = @bap_main.Command::flag(
    doc="Print missing instructions. It prints the list of all instructions that do not have a representable semantics, followed by the histogram of all missed opcodes, and finally prints the number of lifted opcodes, the number of addresses that wasn't disassembled at all, and the number of opcodes that do not have semantics.",
    "print-missing",
  )
  let disassembler = opt_string(
    "disassembler", "Use the specified disassembly driver; defaults to $(b,recursive).",
  )
  let rooter = opt_list(
    "rooters", "Use only the specified rooter sources (all registered sources by default).",
  )
  let symbolizer = opt_list(
    "symbolizers", "Use only the specified symbolizer sources (all registered sources by default).",
  )
  let brancher = opt_list(
    "branchers", "Use only the specified brancher sources (all registered sources by default).",
  )
  let reconstructor = opt_string(
    "reconstructor", "Use the specified reconstructor.",
  )
  let grammar = @bap_main.Command::args()
    .add(input)
    .add(libraries)
    .add(params.outputs)
    .add(params.old_style_passes)
    .add(params.passes)
    .add(params.loader)
    .add(params.target)
    .add(params.update)
    .add(params.knowledge)
    .add(print_missing)
    .add(disassembler)
    .add(rooter)
    .add(symbolizer)
    .add(brancher)
    .add(reconstructor)
  @bap_main.Command::register(
    doc=man,
    requires=features_used,
    "disassemble",
    grammar,
    input => {
      libraries => {
        outputs => {
          old_style => {
            passes => {
              loader => {
                target => {
                  update => {
                    kb => {
                      print_missing => {
                        disassembler => {
                          rooter => {
                            symbolizer => {
                              brancher => {
                                reconstructor => {
                                  _ctxt => {
                                    let libraries = libraries.fold(init=[], (
                                      a,
                                      b,
                                    ) => a + b)
                                    validate_knowledge(update, kb)
                                    validate_input(input)
                                    libraries.each(validate_input)
                                    let (passes, outputs) = prepare(
                                      old_style, passes, outputs,
                                    )
                                    create_and_process(
                                      input,
                                      libraries~,
                                      outputs~,
                                      passes~,
                                      loader~,
                                      target~,
                                      components={
                                        disassembler,
                                        rooters: rooter,
                                        symbolizers: symbolizer,
                                        branchers: brancher,
                                        reconstructor,
                                      },
                                      update~,
                                      knowledge=kb,
                                      print_missing~,
                                      out~,
                                      write_file~,
                                    )
                                    |> ignore
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
  )
}

///|
fn declare_compare(
  params : Params,
  out : (String) -> Unit,
  write_file : (String, String) -> Result[Unit, String],
) -> Unit raise {
  let base = @bap_main.Command::argument(
    doc="The base version.",
    @bap_main.Type::string().with_default("a.out").rename("BASE"),
  )
  let inputs = @bap_main.Command::arguments(
    doc="The alternative versions.",
    @bap_main.Type::string().with_default("b.out").rename("ALT"),
  )
  let collator = @bap_main.Command::argument(
    doc="The collator to use.",
    @bap_main.Type::string().rename("COLLATOR"),
  )
  let doc =
    #|
    #|# DESCRIPTION
    #|
    #|Compares several alternative versions of the binary with the base
    #|version, using the specified $(b,COLLATOR). For the list of
    #|available collators use $(b,bap list collators).
    #|
    #|# EXAMPLE
    #|
    #|```
    #|    bap compare callgraph testsuite/bin/*-echo
    #|```
    #|
  let grammar = @bap_main.Command::args()
    .add(collator)
    .add(base)
    .add(inputs)
    .add(params.outputs)
    .add(params.old_style_passes)
    .add(params.passes)
    .add(params.loader)
    .add(params.target)
    .add(params.update)
    .add(params.knowledge)
  @bap_main.Command::register(
    doc~,
    requires=features_used,
    "compare",
    grammar,
    collator => {
      input => {
        inputs => {
          outputs => {
            old_style => {
              passes => {
                loader => {
                  target => {
                    update => {
                      kb => {
                        _ctxt => {
                          match @project.find_collator(collator, pkg="bap") {
                            None => raise Fail(UnknownCollator(collator))
                            Some(collator) => {
                              let files = [input, ..inputs]
                              files.each(validate_input)
                              let (passes, outputs) = prepare(
                                old_style, passes, outputs,
                              )
                              let projs = files.map(file => {
                                create_and_process(
                                  file,
                                  outputs~,
                                  passes~,
                                  loader~,
                                  target~,
                                  update~,
                                  knowledge=kb,
                                  out~,
                                  write_file~,
                                )
                              })
                              collator.apply(projs)
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
  )
}

///|
/// Declares the `disassemble` plugin, with the `disassemble` and `compare`
/// commands, in the `bap_main` framework. Does nothing if it is already
/// registered.
///
/// `out` receives the dumps written to the standard output; `write_file`
/// writes the dumps and the knowledge base to files.
pub fn declare_plugin(
  out? : (String) -> Unit = s => println(s.trim_end(chars="\n")),
  write_file? : (String, String) -> Result[Unit, String] = default_write_file,
) -> Unit raise {
  if @bap_main.registered_plugins().contains(plugin_name) {
    return
  }
  register_error_printer()
  @bap_main.register_plugin(
    plugin_name,
    provides=["command", "analysis", "disassemble"],
    doc="implements the disassemble and compare commands",
    () => {
      let params = Params::new()
      declare_disassemble(params, out, write_file)
      declare_compare(params, out, write_file)
      @bap_main.Extension::register(
        doc=man,
        provides=["command", "analysis", "disassemble"],
        _ => (),
      )
    },
  )
}
