///|
/// The name of the pass registered by the plugin.
pub let pass_name : String = "phoenix"

///|
let current_options : Ref[Options] = Ref(Options::new())

///|
let reporter : Ref[(String) -> Unit] = Ref(s => println(s))

///|
/// Registers the `phoenix` project pass that stores the site and reports
/// `Stored data to <dir>` (upstream `run`). Calling it again only updates
/// the configuration of the already registered pass.
pub fn register(
  options? : Options = Options::new(),
  report? : (String) -> Unit = s => println(s),
) -> Result[Unit, String] {
  current_options.val = options
  reporter.val = report
  let pass = @project.ProjectPass::create(name=pass_name, run=project => {
    match store(project, options=current_options.val) {
      Ok(dest) => {
        (reporter.val)("Stored data to \{dest}")
        Ok(project)
      }
      Err(e) => Err(e)
    }
  })
  match @project.register_pass_if_absent(pass) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

///|
/// Declares the plugin in the `bap_main` framework with the upstream
/// options (`--phoenix-labels-with`, `--phoenix-output-folder`, ...).
pub fn declare_plugin() -> Unit raise {
  @bap_main.register_plugin(
    "phoenix",
    provides=["printer"],
    doc="outputs the project in a phoenix format",
    () => {
      let label = (x : String, y : String) => {
        @bap_main.Configuration::flag(
          doc="Put \{y} on graph labels (deprecated: use --label-with)",
          "labels-with-\{x}",
        )
      }
      let with_name = label("name", "block name")
      let with_asm = label("asm", "assembler instructions")
      let with_bil = label("bil", "bil instructions")
      let labels_with = @bap_main.Configuration::parameter(
        doc="Put block name, assembler instructions, or bil instructions on graph labels using `name', `asm', or `bil' respectively. Can be specified as a list of multiple elements separated by commas.",
        @bap_main.Type::list(
          @bap_main.Type::enumeration([
            ("name", WithName),
            ("asm", WithAsm),
            ("bil", WithBil),
          ]),
        ).with_default([WithName]),
        "labels-with",
      )
      let output_folder = @bap_main.Configuration::parameter(
        doc="Output data into the specified folder",
        @bap_main.Type::string().with_default("phoenix"),
        "output-folder",
      )
      let no_resolve = @bap_main.Configuration::flag(
        doc="Do not resolve addresses to symbolic names",
        "no-resolve",
      )
      let keep_alive = @bap_main.Configuration::flag(
        doc="Keep alive unused temporary variables",
        "keep-alive",
      )
      let no_inline = @bap_main.Configuration::flag(
        doc="Disable inlining temporary variables",
        "no-inline",
      )
      let keep_consts = @bap_main.Configuration::flag(
        doc="Disable constant folding",
        "keep-const",
      )
      let no_optimizations = @bap_main.Configuration::flag(
        doc="Disable all kinds of optimizations",
        "no-optimizations",
      )
      @bap_main.Extension::register(ctxt => {
        let formats = []
        if ctxt.get(with_name) {
          formats.push(WithName)
        }
        if ctxt.get(with_asm) {
          formats.push(WithAsm)
        }
        if ctxt.get(with_bil) {
          formats.push(WithBil)
        }
        formats.append(ctxt.get(labels_with))
        let options = Options::new(
          output_folder=ctxt.get(output_folder),
          cfg_format=formats,
          no_resolve=ctxt.get(no_resolve),
          keep_alive=ctxt.get(keep_alive),
          no_inline=ctxt.get(no_inline),
          keep_consts=ctxt.get(keep_consts),
          no_optimizations=ctxt.get(no_optimizations),
        )
        match register(options~) {
          Ok(_) => ()
          Err(e) => fail(e)
        }
      })
    },
  )
}
