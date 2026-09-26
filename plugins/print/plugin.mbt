// Plugin registration (upstream `Print_main.main` and the
// `Config.declare_extension` blocks).

///|
/// Prints the BIR of the (filtered) program in the `attr` text-tags mode
/// (upstream `print_bir`).
fn print_bir(
  fmt : @text_tags.Formatter,
  project : @project.Project,
  patterns : Array[Pattern],
) -> Unit {
  let program = extract_program(patterns, project)
  @text_tags.with_mode(fmt, "attr", () => pp_program(fmt, program)) catch {
    _ => pp_program(fmt, program)
  }
}

///|
/// Prints the Ogre specification of the project file (upstream
/// `print_spec`); nothing is printed if there is no specification.
fn print_spec(fmt : @text_tags.Formatter, project : @project.Project) -> Unit {
  let spec = project.specification()
  if !spec.is_empty() {
    fmt.print_string(spec.to_string())
  }
}

///|
/// Registers the IR term writers in the `adt` format (the first
/// `Config.declare_extension` of upstream `print_main.ml`).
pub fn register_term_writers() -> Unit {
  let desc = "Abstract Data Type pretty printing format"
  for
    cls in [
      @types.IrTermClass::ProgramTermClass,
      SubTermClass,
      ArgTermClass,
      BlkTermClass,
      PhiTermClass,
      DefTermClass,
      JmpTermClass,
    ] {
    add_term_writer(cls, "adt", desc~, adt_ir_term)
  }
}

///|
/// Registers the project writers of the print plugin (upstream `main`).
///
/// - `bir_attrs`: the BIR attributes to print (`--print-bir-attr`);
/// - `ansi_colors`: color the output with ANSI escapes
///   (`--print-with-colors`);
/// - `demangler`: the name of the demangler for symbol names
///   (`--print-demangled-with`);
/// - `symbol_formats`: the columns of the symbols writer
///   (`--print-symbol-format`);
/// - `symbols`, `sections`, `patterns`: restrict the printed elements
///   (`--print-symbol`, `--print-section`, `--print-matching`);
/// - `semantics`: the semantic slots to print (`--print-semantics`). The
///   port's IR terms do not carry knowledge-base values, so the BIR is
///   printed as usual.
///
/// Registration is idempotent: writers are replaced by name.
pub fn register(
  bir_attrs? : Array[String] = [],
  ansi_colors? : Bool = false,
  demangler? : String,
  symbol_formats? : Array[SymbolFormat] = [WithName],
  symbols? : Array[String] = [],
  sections? : Array[String] = [],
  patterns? : Array[String] = [],
  semantics? : Array[String],
) -> Result[Unit, String] {
  ignore(semantics)
  let patterns = match compile_patterns(symbols~, sections~, patterns~) {
    Ok(p) => p
    Err(e) => return Err(e)
  }
  let demangle = match create_demangler(demangler) {
    Ok(d) => d
    Err(e) => return Err(e)
  }
  register_term_writers()
  for attr in bir_attrs {
    @text_tags.attr_show(attr)
  }
  @text_tags.attr_print_colors(ansi_colors)
  add_writer("symbols", desc="print symbol table", (fmt, p) => {
    pp_symbols(fmt, p, patterns~, demangle~, formats=symbol_formats)
  })
  add_writer("bir", desc="print program in IR", (fmt, p) => {
    print_bir(fmt, p, patterns)
  })
  add_writer("adt", desc="print program IR in ADT format", adt_project)
  add_writer("callgraph", desc="print program callgraph in DOT format", (fmt, p) => {
    pp_callgraph(fmt, extract_program(patterns, p))
    fmt.print_format("@.")
  })
  add_writer("cfg", desc="print rich CFG for each procedure", (fmt, p) => {
    pp_bir_graph(fmt, extract_program(patterns, p), labeled=true)
  })
  add_writer("graph", desc="print unlabeled CFG for each procedure", (fmt, p) => {
    pp_bir_graph(fmt, extract_program(patterns, p), labeled=false)
  })
  let disasm = (name, desc, printer) => {
    add_writer(name, desc~, (fmt, p) => pp_disasm(fmt, p, printer, patterns~))
  }
  disasm("asm", "print assembly instructions", insn_printer("asm"))
  disasm(
    "asm.adt",
    "print assembly instruction endcoded in ADT format",
    insn_printer("adt"),
  )
  disasm(
    "asm.decoded",
    "print assembly instructions as it was decoded",
    insn_printer("pretty"),
  )
  disasm(
    "asm.sexp",
    "print assembly instructions as it was decoded",
    insn_printer("sexp"),
  )
  disasm("bil", "print BIL instructions", bil_printer("pretty"))
  disasm("bil.adt", "print BIL instructions in ADT format", bil_printer("adt"))
  disasm(
    "bil.sexp",
    "print BIL instructions in Sexp format",
    bil_printer("sexp"),
  )
  add_writer(
    "ogre",
    desc="print the file specification in the OGRE format",
    print_spec,
  )
  Ok(())
}

///|
/// Declares the `print` plugin in the `bap_main` framework with the
/// upstream command-line parameters (`--print-bir-attr`,
/// `--print-symbol`, ...). The extension calls `register` with the
/// parsed configuration.
pub fn declare_plugin() -> Unit raise {
  @bap_main.register_plugin(
    "print",
    provides=["printer"],
    doc="prints the project in various formats",
    () => {
      let demangle = @bap_main.Configuration::parameter(
        doc="Demangle symbols, using the specified demangler",
        @bap_main.Type::some(@bap_main.Type::string()),
        "demangled-with",
      )
      let bir_attr = @bap_main.Configuration::parameters(
        doc="When printing IR emit an attribute $(docv)",
        @bap_main.Type::string(),
        "bir-attr",
      )
      let ansi_colors = @bap_main.Configuration::parameter(
        doc="Allow coloring output with ansi color escape sequences",
        @bap_main.Type::bool(),
        "with-colors",
      )
      let symbol_format = @bap_main.Configuration::parameters(
        doc="Print found symbols. Optional value defines output format, and can be `name', `addr' or `size'. You can specify this parameter several times, if you want both, for example.",
        @bap_main.Type::enumeration([
          ("name", WithName),
          ("addr", WithAddr),
          ("size", WithSize),
        ]),
        "symbol-format",
      )
      let subs = @bap_main.Configuration::parameters(
        doc="same as --print-matching=symbol:NAME",
        @bap_main.Type::string(),
        "symbol",
      )
      let secs = @bap_main.Configuration::parameters(
        doc="same as --print-matching=section:NAME",
        @bap_main.Type::string(),
        "section",
      )
      let matching = @bap_main.Configuration::parameters(
        doc="Only print elements that matches with the provided patterns. A pattern consists of the name of a property and a regular expression, which denotes a set of values of this property.",
        @bap_main.Type::string(),
        "matching",
      )
      let semantics = @bap_main.Configuration::parameter(
        doc="Display the SEMANTICS-LIST semantics of the program.",
        as_flag=Some([]),
        @bap_main.Type::some(@bap_main.Type::list(@bap_main.Type::string())),
        "semantics",
      )
      @bap_main.Extension::register(ctxt => {
        let formats = ctxt.get(symbol_format)
        let result = register(
          bir_attrs=ctxt.get(bir_attr),
          ansi_colors=ctxt.get(ansi_colors),
          demangler?=ctxt.get(demangle),
          symbol_formats=if formats.is_empty() { [WithName] } else { formats },
          symbols=ctxt.get(subs),
          sections=ctxt.get(secs),
          patterns=ctxt.get(matching),
          semantics?=ctxt.get(semantics),
        )
        match result {
          Ok(_) => ()
          Err(msg) => fail(msg)
        }
      })
    },
  )
}
