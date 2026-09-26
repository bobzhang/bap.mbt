///|
/// Runs `initialize` with a deterministic environment and file system and
/// reports the outcome, the help output, and the diagnostics.
fn run_main(
  argv : Array[String],
  env? : Array[(String, String)] = [],
  config? : Array[(String, String)] = [],
  features? : Array[String] = [],
  requires? : Array[String],
  default? : (@bap_main.Ctxt) -> Unit raise,
  default_command? : String,
  man? : String = "",
  recipe? : (String) -> @bap_main.Recipe raise,
) -> String {
  let out = StringBuilder()
  let err = StringBuilder()
  let env_map : Map[String, String] = Map::from_array(env)
  let result = try
    @bap_main.initialize(
      argv=["bap", ..argv],
      name="bap",
      env=v => env_map.get(v),
      config~,
      features~,
      requires?,
      default?,
      default_command?,
      man~,
      recipe?,
      out=s => out.write_string(s),
      err=s => err.write_string(s),
    )
  catch {
    e => "error: " + @bap_main.error_to_string(e)
  } noraise {
    _ => "ok"
  }
  let sb = StringBuilder()
  sb.write_string(result)
  if out.to_string() != "" {
    sb.write_string("\n--- out ---\n")
    sb.write_string(out.to_string())
  }
  if err.to_string() != "" {
    sb.write_string("\n--- err ---\n")
    sb.write_string(err.to_string())
  }
  sb.to_string()
}

///|
/// Resets the framework and installs an empty in-memory file system.
fn fresh() -> Unit {
  @bap_main.reset()
  @bap_main.set_file_system(@bap_main.FileSystem::in_memory(files=[]))
}
