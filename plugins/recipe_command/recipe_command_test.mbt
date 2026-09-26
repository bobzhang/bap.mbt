///|
fn sample_fs() -> @recipe.FileSystem {
  @recipe.FileSystem::in_memory({
    "share/base.recipe/recipe.scm": (
      #|(parameter depth 128 "maximum depth of analysis")
      #|(option analysis-depth $depth)
    ),
    "share/base.recipe/descr": "Base analysis\nwith more details",
    "share/dump.recipe/recipe.scm": (
      #|(extend base)
      #|(command disassemble)
      #|(option dump bir)
      #|(option passes a b)
    ),
    "share/dump.recipe/descr": "Dumps the program in the IR format",
    "share/broken.recipe/recipe.scm": "(option a",
    "share/broken.recipe/descr": "broken",
  })
}

///|
fn run_bap(argv : Array[String]) -> String {
  @bap_main.reset()
  @bap_main.set_file_system(@bap_main.FileSystem::in_memory(files=[]))
  let buf = StringBuilder()
  try {
    @recipe_command.declare_plugin(
      out=s => buf.write_string(s),
      err=s => buf.write_string(s),
      argv=["bap", ..argv],
      fs=sample_fs(),
      paths=["share"],
    )
    @bap_main.initialize(argv=["bap", ..argv], out=s => buf.write_string(s), err=s => {
      buf.write_string(s)
    })
  } catch {
    e => buf.write_string(@bap_main.error_to_string(e))
  }
  @bap_main.reset()
  buf.to_string()
}

///|
test "print-recipes lists the recipes" {
  inspect(
    run_bap(["print-recipes"]),
    content=(
      #|  base                     base analysis
      #|  dump                     dumps the program in the IR format
      #|Malformed recipe share/broken.recipe: Parse error: line 1, column 9: unclosed parentheses at end of input
      #|
    ),
  )
}

///|
test "print-recipes describes a recipe" {
  inspect(
    run_bap(["print-recipes", "dump"]),
    content=(
      #|DESCRIPTION
      #|
      #|Dumps the program in the IR format
      #|
      #|PARAMETERS
      #|
      #|- depth - maximum depth of analysis (defaults to 128)
      #|
      #|COMMAND LINE
      #|
      #|bap \
      #|disassemble \
      #|print-recipes \
      #|dump \
      #|--analysis-depth=128 \
      #|--passes=a,b \
      #|--dump=bir
      #|
    ),
  )
  inspect(
    run_bap(["print-recipes", "nope"]),
    content=(
      #|Can't find the required recipe `nope'
    ),
  )
}

///|
test "recipes prints nothing" {
  inspect(run_bap(["recipes"]), content="")
}
