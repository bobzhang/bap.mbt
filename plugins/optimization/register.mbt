///|
/// The name of the plugin and of its project pass.
pub let name : String = "optimization"

///|
let doc : String =
  #|removes dead code and propagates constants
  #|
  #|An autorun pass that conservatively removes dead code. The removed dead
  #|code is usually produced by a lifter. Applies constant folding, dead code
  #|elimination, and constant propagation in a loop until the fixed point is
  #|reached. On level 0 nothing is touched, on level 1 only virtual variables
  #|are optimized, level 2 also optimizes processor flags, and level 3 extends
  #|the analysis to all variables.

///|
/// Keeps only the dependencies that are currently registered as project passes.
///
/// Upstream depends on the `api` pass (`plugins/api`); the dependency is
/// kept only when the `api` plugin has registered it (the frontend loads
/// the `api` plugin before this one).
fn available_deps(deps : Array[String]) -> Array[String] {
  deps.filter(dep => @project.find_pass(dep) is Some(_))
}

///|
/// Creates the `optimization` project pass for the given level.
pub fn pass(
  level~ : Int32,
  is_flag? : (@types.Var) -> Bool,
  cache? : OptimizationCache,
) -> @project.ProjectPass {
  @project.ProjectPass::create(
    name~,
    autorun=true,
    deps=available_deps(["api"]),
    run=project => Ok(run(project, level~, is_flag?, cache?)),
  )
}

///|
/// Registers the autorun `optimization` pass (upstream registers it only when
/// the level is positive). Idempotent: returns `false` when nothing was
/// registered.
pub fn register(
  level~ : Int32,
  is_flag? : (@types.Var) -> Bool,
  cache? : OptimizationCache,
) -> Result[Bool, String] {
  if level > 0 {
    @project.register_pass_if_absent(pass(level~, is_flag?, cache?))
  } else {
    Ok(false)
  }
}

///|
/// Declares the `optimization` plugin to `bap_main` with its `level`
/// parameter (`--optimization-level`). Does nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["pass", "optimization", "analysis", "simplification"],
    doc~,
    () => {
      let level = @bap_main.Configuration::parameter(
        doc="Specifies the optimization level.",
        @bap_main.Type::int(),
        "level",
      )
      @bap_main.Extension::register(ctxt => {
        match register(level=ctxt.get(level), cache=OptimizationCache::new()) {
          Ok(_) => ()
          Err(reason) => fail(reason)
        }
      })
    },
  )
}
