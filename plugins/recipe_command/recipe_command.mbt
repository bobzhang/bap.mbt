// The `recipes` and `print-recipes` commands (upstream
// `Recipe_command_main`).

///|
/// The name of the plugin.
pub let plugin_name : String = "recipe-command"

///|
/// The manual of the `recipes` command.
pub let doc : String =
  #|
  #|# DESCRIPTION
  #|
  #|Provides commands to manipulate the recipe subsystem.
  #|
  #|# RECIPE DESCRIPTION
  #|
  #|A recipe is either a single file or a directory (optionally
  #|zipped) that contains a parametrized specification of command
  #|line parameters and support files if necessary.
  #|
  #|The purpose of the recipe is to make bap runs reproducible, so
  #|that you can share one simple file - the recipe, instead of a
  #|bunch of scripts together with some verbal instructions. Since
  #|recipes introduce an extra layer of abstraction they actually
  #|simplify interaction with bap by hiding unnecessary
  #|details. Recipes also provide a mechanism for building ready
  #|solutions and sharing them with users.
  #|
  #|To use a recipe, just specify its name using the $(b,--recipe)
  #|command line parameter. If a recipe has parameters then they could
  #|be specified as colon separated list of $(b,<key>=<value>)
  #|pairs. See the $(b,--recipe) parameter for more information. To
  #|read the recipe description, including the list of parameters and
  #|resulting command line, use the $(b,print-recipes) command.
  #|
  #|The main (and the only necessary) part of a recipe is the recipe
  #|specification, that is a file that contains a list of recipe items
  #|in an arbitrary order. Each item is either a command line
  #|option, a parameter, or a reference to another recipe. All items
  #|share the same syntax - they are flat s-expressions, i.e., a
  #|whitespace separated list of strings enclosed in parentheses. The
  #|first string in the lists denotes the type of the item. E.g.,
  #|$(b,(option run-entry-points malloc calloc free)).
  #|
  #|The $(b,option) command requires one mandatory parameter, the
  #|option name, and an arbitrary number of arguments that will be
  #|passed to the corresponding command line option. If there are more
  #|than one argument then they will be concatenated with the comma
  #|symbol, e.g., $(b,(option opt a b c d)) will be translated to
  #|$(b,--opt=a,b,c,d). Option arguments may contain substitution
  #|symbols. A substitution symbol starts with the dollar sign, that is
  #|followed by a named (optionally delimited with curly braces, to
  #|disambiguate it from the rest of the argument). There is one built
  #|in parameter called $(b,prefix), that is substituted with the path
  #|to the recipe top folder. See the $(b,parameter) command to learn
  #|how to introduce parameters.
  #|
  #|The $(b,parameter) command introduces a parameter to the recipe, i.e.,
  #|a variable ingredient that could be changed when the recipe is
  #|used. The parameter command has 3 arguments, all required. The
  #|first argument is the parameter name, the second is the default
  #|value, that is used if the a parameter wasn't set, and the last
  #|argument is the parameter description.
  #|
  #|The $(b,command) stanza specifies the command that the recipe should
  #|run. It is optional, since recipes could be generic and applicable to
  #|different commands, which gives an extra freedom to the recipe
  #|user.
  #|
  #|Finally, the $(b,extend) command is like the include statement in
  #|the C preprocessor as it includes all the ingredients from another
  #|recipe. (Make sure that you're not introducing loops!). The
  #|command has one mandatory argument, the name of the recipe to
  #|include.
  #|
  #|# RECIPE GRAMMAR
  #|
  #|```
  #|    recipe ::= {<recipe-item>}
  #|    recipe-item ::= <option> | <parameter> | <extend> | <command>
  #|    option ::= (option <atom> {<atom>})
  #|    parameter ::= (parameter <atom> <atom> <atom>)
  #|    extend ::= (extend <atom>)
  #|    command ::= (command <atom>)
  #|```
  #|

///|
/// The error raised by `print-recipes` (upstream `Recipe_error`).
pub(all) suberror RecipeCommandError {
  RecipeError(@recipe.RecipeError)
}

///|
/// The directories searched for recipes: the current directory, the
/// data directory, and the system data directory.
pub fn recipe_paths() -> Array[String] {
  [
    ".",
    @bap_main.Configuration::datadir(),
    @bap_main.Configuration::sysdatadir(),
  ]
}

///|
fn cleanup(keep : Bool, r : @recipe.Recipe) -> Unit {
  if !keep {
    r.close()
  }
}

///|
/// The description of a recipe (upstream `print_recipe`).
pub fn describe_recipe(r : @recipe.Recipe, argv~ : Array[String]) -> String {
  let sb = StringBuilder()
  sb.write_string("DESCRIPTION\n\n\{r.doc()}\n\n")
  let params = r.params()
  if !params.is_empty() {
    sb.write_string("PARAMETERS\n\n")
    for p in params {
      sb.write_string("- \{p.to_string()}\n")
    }
    sb.write_string("\n")
  }
  let args = r.argv(argv~)
  let sep = if args.length() > 4 { " \\\n" } else { " " }
  sb.write_string("COMMAND LINE\n\n\{args.join(sep)}\n")
  sb.to_string()
}

///|
fn prefix(s : String, len : Int32) -> String {
  String::from_array(s.to_array()[:len])
}

///|
fn minimize(s : String) -> String {
  if s.length() < 60 {
    s
  } else {
    prefix(s, 60) + "..."
  }
}

///|
/// The one-line summary of a recipe description (upstream `summary`).
fn summary(s : String) -> String {
  let first = match s.find("\n") {
    None => s
    Some(p) => prefix(s, if p < 60 { p } else { 60 })
  }
  let chars = first.to_array()
  if chars.length() > 0 {
    chars[0] = chars[0].to_ascii_lowercase()
  }
  minimize(String::from_array(chars))
}

///|
fn pad_right(s : String, width : Int32) -> String {
  if s.length() >= width {
    s
  } else {
    s + " ".repeat(width - s.length())
  }
}

///|
/// Lists the recipes installed in `recipe_paths` (upstream
/// `print_all_recipes`). Malformed recipes are reported to `err`.
pub fn list_recipes(
  keep~ : Bool = false,
  paths~ : Array[String] = recipe_paths(),
  fs~ : @recipe.FileSystem = @recipe.FileSystem::native(),
  out~ : (String) -> Unit,
  err~ : (String) -> Unit = _ => (),
) -> Unit {
  for dir in paths {
    if (fs.file_exists)(dir) && (fs.is_directory)(dir) {
      let entries = (fs.read_dir)(dir).copy()
      entries.sort_by(lex_compare)
      for entry in entries {
        let file = @recipe.concat(dir, entry)
        if entry.has_suffix(".recipe") {
          let name = prefix(entry, entry.length() - ".recipe".length())
          try {
            @recipe.load(paths~, fs~, name)
          } catch {
            e => err("Malformed recipe \{file}: \{e.to_string()}\n")
          } noraise {
            r => {
              out(
                "  " +
                pad_right(@recipe.basename(name), 24) +
                " " +
                summary(r.doc()) +
                "\n",
              )
              cleanup(keep, r)
            }
          }
        }
      }
    }
  }
}

///|
/// Describes each of the recipes (upstream `print-recipes` with
/// arguments).
pub fn print_recipes(
  recipes : Array[String],
  keep~ : Bool = false,
  paths~ : Array[String] = recipe_paths(),
  fs~ : @recipe.FileSystem = @recipe.FileSystem::native(),
  argv~ : Array[String] = @env.args(),
  out~ : (String) -> Unit,
  err~ : (String) -> Unit = _ => (),
) -> Unit raise RecipeCommandError {
  match recipes {
    [] => list_recipes(keep~, paths~, fs~, out~, err~)
    recipes =>
      for name in recipes {
        let r = @recipe.load(paths~, fs~, name) catch {
          e => raise RecipeError(e)
        }
        out(describe_recipe(r, argv~))
        cleanup(keep, r)
      }
  }
}

///|
let printer_registered : Ref[Bool] = Ref(false)

///|
/// Declares the `recipe-command` plugin (the `recipes` and `print-recipes`
/// commands) in the `bap_main` framework. Does nothing if it is already
/// registered.
///
/// `argv` is the command line of the process, shown in the recipe
/// descriptions; `fs` is the file system with the recipes.
pub fn declare_plugin(
  out~ : (String) -> Unit = s => println(s.trim_end(chars="\n")),
  err~ : (String) -> Unit = s => println(s.trim_end(chars="\n")),
  argv~ : Array[String] = @env.args(),
  fs~ : @recipe.FileSystem = @recipe.FileSystem::native(),
  paths? : Array[String],
) -> Unit raise {
  if @bap_main.registered_plugins().contains(plugin_name) {
    return
  }
  if !printer_registered.val {
    printer_registered.val = true
    @bap_main.register_error_printer(e => {
      match e {
        RecipeError(e) => Some(e.to_string())
        _ => None
      }
    })
  }
  @bap_main.register_plugin(
    plugin_name,
    provides=["command", "recipe"],
    doc="provides the recipe command",
    () => {
      @bap_main.Command::register(doc~, "recipes", @bap_main.Command::args(), _ => {
        ()
      })
      let recipes = @bap_main.Command::arguments(@bap_main.Type::string())
      let keep_open = @bap_main.Command::flag(
        aliases=["k"],
        doc="Do not delete the temporary workspace.",
        "keep-open",
      )
      @bap_main.Command::register(
        doc="prints available recipes.",
        "print-recipes",
        @bap_main.Command::args().add(recipes).add(keep_open),
        recipes => {
          keep => {
            _ctxt => {
              let paths = match paths {
                Some(p) => p
                None => recipe_paths()
              }
              print_recipes(recipes, keep~, paths~, fs~, argv~, out~, err~)
            }
          }
        },
      )
      @bap_main.Extension::register(
        doc="provides the recipe command",
        provides=["command", "recipe"],
        _ => (),
      )
    },
  )
}

///|
/// OCaml's `String.compare`: the lexicographic order (MoonBit's `String`
/// comparison orders by length first).
fn lex_compare(a : String, b : String) -> Int32 {
  let n = if a.length() < b.length() { a.length() } else { b.length() }
  for i in 0..<n {
    let c = a[i].compare(b[i])
    if c != 0 {
      return c
    }
  }
  a.length().compare(b.length())
}
