// The command-line declarations of the `mc` and `objdump` commands.

///|
/// The name of the plugin.
pub let plugin_name : String = "mc"

///|
/// The manual of the `mc` command.
pub let mc_man : String =
  #|
  #|# DESCRIPTION
  #|
  #|Disassembles a (human readable) string of bytes. This command is the
  #|BAP machine code playground, which is intended to mimic a subset of
  #|llvm-mc functionality, using the BAP disassembly backend. The main
  #|use case is to explore various information associated with the
  #|dissasembled instruction.
  #|
  #|# EXAMPLES
  #|
  #|The following input formats are supported:
  #|
  #|```
  #|    0x31 0xd2 0x48 0xf7 0xf3
  #|    \\x31\\xd2\\x48\\xf7\\xf3
  #|    31 d2 48 f7 f3
  #|    31d248f7f3
  #|```
  #|
  #|# SETTING ARCHITECHTURE
  #|
  #|The target architecture is controlled by several groups of options
  #|that can not be used together:
  #|
  #|- $(b,arch);
  #|- $(b,target) and $(b,encoding);
  #|- $(b,triple), $(b,backend), $(b,cpu), $(b,bits), and $(b,order).
  #|
  #|The $(b,arch) option provides the least control but is easiest to
  #|use. Use the common names for the architecture and it should work.
  #|You can use the $(b,bits) and $(b,order) options to give more hints.
  #|
  #|The $(b,target) and $(b,encoding) provides precise control over the
  #|selection of the target and the encoding that is used to represent
  #|machine instructions. The $(b,encoding) field can be omitted and will
  #|be deduced from the target. Use $(b, bap list targets) to get the list
  #|of supported targets.
  #|
  #|Finally, the $(b,triple), $(b,backend), $(b,cpu),... group of options
  #|provides the full control over the disassembler backend and bypasses
  #|the target selection. When this group is used the semantics of the
  #|instructions will not be provided.
  #|

///|
/// The manual of the `objdump` command.
pub let objdump_man : String =
  #|
  #|# DESCRIPTION
  #|
  #|Disassembles and prints a binary using the linear sweep algorithm.
  #|This command is a sibling to the $(b,mc) command, except
  #|that it takes a binary file as an input. If the binary contains only
  #|raw code (i.e., no meta information), then use the $(b,raw) loader.
  #|
  #|# EXAMPLES
  #|
  #|```
  #|  bap objdump /bin/ls --show-asm
  #|  bap objdump ./code --loader=raw
  #|```
  #|

///|
fn language_type() -> @bap_main.Type[@core_theory.Language] {
  @bap_main.Type::create(
    parse=s => {
      match @core_theory.Language::read(s, pkg="bap") {
        Ok(l) => l
        Err(msg) => fail(msg)
      }
    },
    print=l => l.to_string(),
    @core_theory.Language::unknown(),
  )
}

///|
fn target_type() -> @bap_main.Type[@core_theory.Target] {
  @bap_main.Type::create(
    parse=s => {
      match @core_theory.Target::get(s, pkg="bap") {
        Ok(t) => t
        Err(msg) => fail(msg)
      }
    },
    print=t => t.to_string(),
    @core_theory.Target::unknown(),
  )
}

///|
fn outputs_param() -> @bap_main.CommandParam[Array[(Show, Array[String])]] {
  @bap_main.Command::dictionary(
    doc=s => {
      match s {
        Insn => "Print the decoded instruction."
        Bil => "Print the BIL code."
        Bir => "Print the IR."
        Sema => "Print the full semantics of the instruction."
        Kinds => "Print semantics tags associated with instruction."
        Size => "Print the instruction size."
        Addr => "Print the instruction address"
        Memory => "Print the instruction memory representation"
        Knowledge => "Print the knowledge base."
        Invalid => "Print invalid instructions."
      }
    },
    as_flag=s => {
      match s {
        Insn | Bil | Bir => ["pretty"]
        Sema => ["all-slots"]
        _ => [enabled]
      }
    },
    all_outputs,
    @bap_main.Type::list(@bap_main.Type::string()),
    s => "show-" + s.name(),
  )
}

///|
fn declare_mc(out : (String) -> Unit, read_line : () -> String?) -> Unit raise {
  let arch = @bap_main.Command::parameter(
    doc="The target architecture.",
    aliases=["a"],
    @bap_main.Type::some(@bap_main.Type::string()),
    "arch",
  )
  let target = @bap_main.Command::parameter(
    doc="The target name.",
    aliases=["t"],
    target_type(),
    "target",
  )
  let encoding = @bap_main.Command::parameter(
    doc="The target encoding.",
    aliases=["e"],
    language_type(),
    "encoding",
  )
  let triple = @bap_main.Command::parameter(
    doc="The target triple.",
    @bap_main.Type::some(@bap_main.Type::string()),
    "triple",
  )
  let cpu = @bap_main.Command::parameter(
    doc="The target CPU (used with triple).",
    @bap_main.Type::some(@bap_main.Type::string()),
    "cpu",
  )
  let backend = @bap_main.Command::parameter(
    doc="The disassembling backend (used with triple).",
    @bap_main.Type::some(@bap_main.Type::string()),
    "backend",
  )
  let bits = @bap_main.Command::parameter(
    doc="The number of bits in the address (used with triple or arch)",
    @bap_main.Type::some(@bap_main.Type::int()),
    "bits",
  )
  let order = @bap_main.Command::parameter(
    doc="The order of bytes in the target's word (used with triple or arch).",
    @bap_main.Type::some(
      @bap_main.Type::enumeration([
        ("big", @bitvec.Endian::BigEndian),
        ("little", @bitvec.Endian::LittleEndian),
      ]),
    ),
    "order",
  )
  let base = @bap_main.Command::parameter(
    doc="Specify an address of first byte",
    aliases=["b"],
    @bap_main.Type::string(),
    "address",
  )
  let only_one = @bap_main.Command::flag(
    doc="Stop after the first instruction is decoded",
    "only-one",
  )
  let stop_on_error = @bap_main.Command::flag(
    doc="Stop disassembling on the first error and report it",
    "stop-on-errors",
  )
  let input = @bap_main.Command::arguments(@bap_main.Type::string())
  let grammar = @bap_main.Command::args()
    .add(arch)
    .add(target)
    .add(encoding)
    .add(triple)
    .add(cpu)
    .add(backend)
    .add(bits)
    .add(order)
    .add(base)
    .add(only_one)
    .add(stop_on_error)
    .add(input)
    .add(outputs_param())
  @bap_main.Command::register(doc=mc_man, "mc", grammar, arch => {
    target => {
      encoding => {
        triple => {
          cpu => {
            backend => {
              bits => {
                order => {
                  base => {
                    only_one => {
                      stop_on_error => {
                        input => {
                          outputs => {
                            _ctxt => {
                              mc(
                                arch?,
                                target~,
                                encoding~,
                                triple?,
                                cpu?,
                                backend?,
                                bits?,
                                order?,
                                base=if base == "" { "0" } else { base },
                                only_one~,
                                stop_on_error~,
                                input~,
                                outputs~,
                                read_line~,
                                out~,
                              )
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
  })
}

///|
fn declare_objdump(out : (String) -> Unit) -> Unit raise {
  let loader = @bap_main.Command::parameter(
    doc="Use the specified loader. Use the loader `raw' to load unstructured files",
    @bap_main.Type::string().with_default("llvm"),
    "loader",
  )
  let stop_on_error = @bap_main.Command::flag(
    doc="Stop disassembling on the first error and report it",
    "stop-on-errors",
  )
  let file = @bap_main.Command::argument(@bap_main.Type::file())
  let grammar = @bap_main.Command::args()
    .add(loader)
    .add(stop_on_error)
    .add(file)
    .add(outputs_param())
  @bap_main.Command::register(doc=objdump_man, "objdump", grammar, loader => {
    stop_on_error => {
      file => {
        outputs => {
          _ctxt => objdump(loader~, stop_on_error~, file, outputs~, out~)
        }
      }
    }
  })
}

///|
/// Declares the `mc` plugin (the `mc` and `objdump` commands) in the
/// `bap_main` framework. Does nothing if it is already registered.
///
/// `out` receives the output; `read_line` reads a line of the standard
/// input (used by `mc` when no bytes are given on the command line).
pub fn declare_plugin(
  out? : (String) -> Unit = s => println(s.trim_end(chars="\n")),
  read_line? : () -> String? = () => None,
) -> Unit raise {
  if @bap_main.registered_plugins().contains(plugin_name) {
    return
  }
  register_error_printer()
  @bap_main.register_plugin(
    plugin_name,
    provides=["command", "disassembler"],
    doc="provides mc and objdump commands",
    () => {
      declare_mc(out, read_line)
      declare_objdump(out)
      @bap_main.Extension::register(doc="provides mc and objdump commands", _ => {
        ()
      })
    },
  )
}
