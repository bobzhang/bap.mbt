///|
/// The name of the plugin.
pub let name : String = "bil"

///|
let doc : String =
  #|Defines the semantics of BAP Instruction Language (BIL) and makes old
  #|BIL lifters available in the system. The BIL code, obtained from the
  #|lifters is processed by the BIL transformation pipeline to enable
  #|optimization and/or normalization of BIL programs. The pipeline is
  #|formed as a concatenation of all normalization passes that correspond
  #|to the selected level of normalization, all optimization passes
  #|applicable to the selected level of optimization, and all passes
  #|selected via the --bil-passes command line argument. All passes are
  #|applied until a fixed point is reached. See --bil-list-passes for the
  #|list of available transformations.

///|
/// Configures the plugin (the body of the extension): selects the pipeline,
/// configures the lifter and installs the post-lift hook that applies the
/// pipeline in project lifting, and installs the theories and knowledge
/// base rules (`install_rules`). Returns the lines to print when
/// `list` is set (upstream prints them and exits), `None`
/// otherwise.
pub fn enable(
  list~ : Bool = false,
  normalization~ : String = "0",
  optimization~ : String = "1",
  passes~ : ArrayView[String] = [],
  with_fp~ : Bool = true,
  enable_intrinsics~ : ArrayView[ISpec] = [],
) -> Array[String]? raise Failure {
  if list {
    return Some(list_passes())
  }
  match select(normalization~, optimization~, passes~) {
    Ok(_) => ()
    Err(e) => raise Failure(e)
  }
  configure({ with_fp, enable_intrinsics: enable_intrinsics.to_owned(), })
  install_lift_hook()
  install_rules(with_fp~) catch {
    e => raise Failure("bil: \{e}")
  }
  None
}

///|
/// The name of the post-lift hook that applies the selected passes.
pub let lift_hook_name : String = "bil-passes"

///|
/// Makes project lifting apply the selected BIL passes to the semantics of
/// every lifted instruction (`apply_passes`), as upstream's lifters
/// factory does. Called by `enable`.
pub fn install_lift_hook() -> Unit {
  @project.register_lift_hook(name=lift_hook_name, apply_passes)
}

///|
/// Removes the hook installed by `install_lift_hook`.
pub fn uninstall_lift_hook() -> Unit {
  @project.unregister_lift_hook(lift_hook_name) |> ignore
}

///|
/// Declares the `bil` plugin to `bap_main` with its parameters. Does
/// nothing if already declared.
pub fn declare_plugin(exit~ : () -> Unit = () => ()) -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["bil", "core-theory", "lifter"],
    doc~,
    () => {
      let levels = (xs : Array[(String, Array[@types.BilPass])]) => {
        xs.map(x => (x.0, x.0))
      }
      let norml = @bap_main.Configuration::parameter(
        doc="Selects a BIL normalization level. The normalization process doesn't change the semantics of a BIL program, but applies some transformations to simplify it.",
        @bap_main.Type::enumeration(levels(normalizations())),
        "normalization",
      )
      let optim = @bap_main.Configuration::parameter(
        doc="Specifies an optimization level. Level 0 disables all optimizations, and level 1 performs regular program simplifications, e.g., applies constant folding, propagation, and elimination of dead temporary (aka virtual) variables.",
        @bap_main.Type::enumeration(levels(optimizations())).with_default("1"),
        "optimization",
      )
      let list = @bap_main.Configuration::flag(
        doc="List all available passes and exit",
        "list-passes",
      )
      let pass_names = @types.passes().map(p => (p.name(), p.name()))
      let passes = @bap_main.Configuration::parameter(
        doc="Selects the list and the order of analyses to be applied during the lifing to BIL code.",
        @bap_main.Type::list(@bap_main.Type::enumeration(pass_names)),
        "passes",
      )
      let fp = @bap_main.Configuration::parameter(
        doc="Enable/disable floating-point emulation (on by default).",
        aliases=["enable-fp-emulation"],
        as_flag=true,
        @bap_main.Type::bool().with_default(true),
        "floating-point-emulation",
      )
      let ispec = @bap_main.Type::create(
        name="ISPEC",
        parse=s => ISpec::parse(s),
        print=s => s.to_string(),
        Any,
      )
      let intrinsics = @bap_main.Configuration::parameters(
        doc="Translate the specified instructions into calls to intrinsic functions. Each element of the list is either a keyword (:any, :unknown, :special) or a predicate (asm:<str>, tag:<str>, <encoding>:<opcode>).",
        @bap_main.Type::list(ispec),
        "enable-intrinsics",
      )
      @bap_main.Extension::register(provides=["bil", "core-theory", "lifter"], ctxt => {
        let specs = ctxt.get(intrinsics).fold(init=[], (acc, xs) => acc + xs)
        match
          enable(
            list=ctxt.get(list),
            normalization=ctxt.get(norml),
            optimization=ctxt.get(optim),
            passes=ctxt.get(passes),
            with_fp=ctxt.get(fp),
            enable_intrinsics=specs,
          ) {
          Some(lines) => {
            for l in lines {
              println(l)
            }
            exit()
          }
          None => ()
        }
      })
    },
  )
}
