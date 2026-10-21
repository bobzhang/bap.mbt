// Port of `Bap_recipe`: recipe descriptions of command line arguments.

///|
using @sexp {type Sexp}
//
// A recipe is a directory with a `recipe.scm` specification (and an
// optional `descr` file), or a single specification file. Zipped recipes
// are not supported (there is no zip support in the port); loading one
// yields a `MalformedRecipe` error.

///|
/// Recipe errors (upstream `error`).
pub(all) suberror RecipeError {
  /// an item argument must be an atom, got a list with these elements
  ExpectAtom(String)
  /// a malformed `<name>=<value>` variable definition
  ExpectVar(String)
  /// an unknown recipe item
  BadItem(String)
  /// a malformed `parameter` item
  BadParam(String)
  /// a missing file
  MissingEntry(String)
  /// an s-expression syntax error
  BadSexp(String)
  /// the recipe is not found
  NoRecipe(String)
  /// the substitution symbol is not bound
  BadSubst(String)
  /// the passed variable is not a parameter of the recipe
  UnboundParam(String)
  /// the variable is specified twice
  DuplicateVar(String)
  /// a malformed recipe archive (name, entry, message)
  MalformedRecipe(String, String, String)
  /// a system error
  SystemError(String)
} derive(Eq, Debug)

///|
pub extend RecipeError with Eq::{not_equal, equal}

///|
pub extend RecipeError with Debug::{to_repr}

///|
/// The human-readable error message (upstream `pp_error`).
pub fn RecipeError::to_string(self : RecipeError) -> String {
  match self {
    ExpectAtom(s) => "Parse error: expected an atom got (\{s})"
    ExpectVar(s) => "Parse error: bad variable definition, got `\{s}'"
    BadItem(s) => "Parse error: unknown recipe item - \{s}"
    MissingEntry(s) => "The required file `\{s}' is missing"
    BadSexp(err) => "Parse error: \{err}"
    NoRecipe(r) => "Can't find the required recipe `\{r}'"
    BadSubst(v) => "Don't know how to substitute $\{v}"
    MalformedRecipe(x, y, z) => "Malformed recipe: \{x}, \{y}, \{z}"
    DuplicateVar(s) => "Variable \{s} was specified twice"
    BadParam(s) =>
      "Syntax error in the parameter `\{s}' specification. Expecting: (parameter <name> <value> <desc>)"
    UnboundParam(s) => "Unknown parameter `\{s}'"
    SystemError(s) => "System error: \{s}"
  }
}

///|
/// A recipe parameter.
pub struct Param {
  priv name : String
  priv defl : String
  priv desc : String
} derive(Eq, Debug)

///|
pub extend Param with Eq::{not_equal, equal}

///|
pub extend Param with Debug::{to_repr}

///|
/// The parameter name.
pub fn Param::name(self : Param) -> String {
  self.name
}

///|
/// The parameter description.
pub fn Param::doc(self : Param) -> String {
  self.desc
}

///|
/// The default value of the parameter.
pub fn Param::default(self : Param) -> String {
  self.defl
}

///|
/// The human-readable description of the parameter (upstream `Param.pp`).
pub fn Param::to_string(self : Param) -> String {
  "\{self.name} - \{self.desc} (defaults to \{self.defl})"
}

///|
priv enum Item {
  Cmd(String)
  Use(String)
  Opt(String, Array[String])
  Par(Param)
}

///|
priv struct Spec {
  cmd : String?
  uses : Array[String]
  opts : Array[(String, Array[String])]
  pars : Array[Param]
}

///|
priv struct Workspace {
  path : String
  main : String
}

///|
/// A loaded recipe.
pub struct Recipe {
  priv root : Workspace
  priv args : Array[String]
  priv descr : String
  priv spec : Spec
  priv loads : Array[Recipe]
}

///|
fn item_of_sexp(sexp : Sexp) -> Item raise RecipeError {
  match sexp {
    List([Atom("extend"), Atom(x)]) => Use(x)
    List([Atom("parameter"), Atom(name), Atom(defl), Atom(desc)]) =>
      Par({ name, defl, desc, })
    List([Atom("option"), Atom(name), .. args]) => {
      let atoms = []
      for arg in args {
        match arg {
          Atom(x) => atoms.push(x)
          List(xs) => raise ExpectAtom(xs.map(x => x.to_string()).join(""))
        }
      }
      Opt(name, atoms)
    }
    List([Atom("parameter"), Atom(s), ..]) => raise BadParam(s)
    List([Atom("command"), Atom(name)]) => Cmd(name)
    x => raise BadItem(x.to_string())
  }
}

///|
/// Builds the specification; as upstream, extensions, options and
/// parameters are accumulated in the reverse order.
fn spec_of_items(items : Array[Item]) -> Spec {
  let uses = []
  let opts = []
  let pars = []
  let mut cmd = None
  for item in items {
    match item {
      Use(x) => uses.insert(0, x)
      Opt(x, xs) => opts.insert(0, (x, xs))
      Par(x) => pars.insert(0, x)
      Cmd(name) => cmd = Some(name)
    }
  }
  { cmd, uses, opts, pars, }
}

///|
fn parse_recipe(text : String) -> Spec raise RecipeError {
  let sexps = @sexp.Sexp::of_string_many(text) catch {
    ParseError(line~, column~, msg) =>
      raise BadSexp("line \{line}, column \{column}: \{msg}")
  }
  let items = []
  for sexp in sexps {
    items.push(item_of_sexp(sexp))
  }
  spec_of_items(items)
}

///|
priv struct Env {
  fs : FileSystem
  vars : Map[String, String]
  paths : Array[String]
}

///|
fn input(
  env : Env,
  root : Workspace,
  file : String,
) -> String raise RecipeError {
  let path = concat(root.path, file)
  if (env.fs.file_exists)(path) {
    match (env.fs.read_file)(path) {
      Ok(text) => text
      Err(err) => raise SystemError(err)
    }
  } else {
    raise MissingEntry(path)
  }
}

///|
fn get_descr(env : Env, root : Workspace) -> String raise RecipeError {
  input(env, root, "descr") catch {
    MissingEntry(_) => "Description was not provided"
    err => raise err
  }
}

///|
priv suberror SubstError {
  NoIdent(String)
  Unbound(String)
}

///|
fn is_ident_char(c : UInt16) -> Bool {
  c is ('a'..<='z' | 'A'..<='Z' | '0'..<='9' | '_')
}

///|
/// Substitutes `$name`, `$(name)` and `${name}` in [s] (upstream
/// `Buffer.add_substitute`); `\$` is a literal dollar sign.
fn substitute(
  s : String,
  f : (String) -> String raise SubstError,
) -> String raise SubstError {
  let buf = StringBuilder()
  let lim = s.length()
  let mut previous : UInt16 = ' '
  let mut i = 0
  while i < lim {
    let current = s[i]
    if current == '$' && previous == '\\' {
      buf.write_char('$')
      previous = ' '
      i += 1
    } else if current == '$' {
      let j = i + 1
      if j >= lim {
        raise NoIdent(s)
      }
      let (ident, next) = if s[j] == '(' || s[j] == '{' {
        let opening = s[j]
        let closing : UInt16 = if opening == '(' { ')' } else { '}' }
        let mut k = 0
        let mut stop = j + 1
        while true {
          if stop >= lim {
            raise NoIdent(s)
          }
          if s[stop] == opening {
            k += 1
          } else if s[stop] == closing {
            if k == 0 {
              break
            }
            k -= 1
          }
          stop += 1
        }
        (s[j + 1:stop].to_owned(), stop + 1)
      } else {
        let mut stop = j + 1
        while stop < lim && is_ident_char(s[stop]) {
          stop += 1
        }
        (s[j:stop].to_owned(), stop)
      }
      buf.write_string(f(ident))
      previous = ' '
      i = next
    } else if previous == '\\' {
      buf.write_char('\\')
      buf.write_char(s.get_char(i).unwrap_or('?'))
      previous = ' '
      i += 1
    } else if current == '\\' {
      previous = current
      i += 1
    } else {
      buf.write_char(s.get_char(i).unwrap_or('?'))
      previous = current
      i += 1
    }
  }
  if previous == '\\' {
    buf.write_char('\\')
  }
  buf.to_string()
}

///|
fn apply_subst(
  root : Workspace,
  pars : Array[Param],
  vars : Map[String, String],
  opts : Array[(String, Array[String])],
) -> Array[String] raise RecipeError {
  let subst = (arg : String) => {
    if arg == "prefix" {
      root.path
    } else {
      match vars.get(arg) {
        Some(x) => x
        None =>
          match pars.search_by(p => p.name == arg) {
            Some(i) => pars[i].defl
            None => raise Unbound(arg)
          }
      }
    }
  }
  let result = []
  for opt in opts {
    let (name, args) = opt
    let substituted = []
    for arg in args {
      let value = substitute(arg, subst) catch {
        Unbound(v) => raise BadSubst(v)
        NoIdent(s) => raise BadSubst(s)
      }
      substituted.push(value)
    }
    let name = "--" + name
    result.push(
      if substituted.is_empty() {
        name
      } else {
        name + "=" + substituted.join(",")
      },
    )
  }
  result
}

///|
fn is_zip(env : Env, path : String) -> Bool {
  match (env.fs.read_file)(path) {
    Ok(text) => text.has_prefix("PK\u{03}\u{04}")
    Err(_) => false
  }
}

///|
fn read_workspace(env : Env, t : String) -> Workspace raise RecipeError {
  if (env.fs.is_directory)(t) {
    { path: t, main: "recipe.scm", }
  } else if is_zip(env, t) {
    raise MalformedRecipe(t, "", "zipped recipes are not supported")
  } else {
    { path: dirname(t), main: basename(t), }
  }
}

///|
fn check_vars(
  vars : Map[String, String],
  spec : Spec,
  loads : Array[Recipe],
) -> Unit raise RecipeError {
  let specs = [spec, ..loads.map(r => r.spec)]
  for arg, _ in vars {
    if !specs.any(s => s.pars.any(p => p.name == arg)) {
      raise UnboundParam(arg)
    }
  }
}

///|
/// [search(paths)] is the list of recipes available in [paths]: all files
/// and directories with the `.recipe` extension (as upstream, the full
/// paths are returned).
pub fn search(
  paths : Array[String],
  fs~ : FileSystem = FileSystem::native(),
) -> Array[String] {
  let result = []
  for p in paths {
    if (fs.file_exists)(p) && (fs.is_directory)(p) {
      for file in (fs.read_dir)(p) {
        if file.has_suffix(".recipe") {
          result.push(concat(p, file))
        }
      }
    }
  }
  result
}

///|
fn which(env : Env, name : String) -> String? {
  for p in env.paths {
    if (env.fs.file_exists)(p) && (env.fs.is_directory)(p) {
      for
        candidate in [
          concat(p, name),
          concat(p, name) + ".scm",
          concat(p, name) + ".recipe",
        ] {
        if (env.fs.file_exists)(candidate) {
          return Some(candidate)
        }
      }
    }
  }
  None
}

///|
fn load_path(env : Env, path : String) -> Recipe raise RecipeError {
  let root = read_workspace(env, path)
  let descr = get_descr(env, root)
  let spec = parse_recipe(input(env, root, root.main))
  let loads = []
  for name in spec.uses {
    loads.push(load_name(env, name))
  }
  check_vars(env.vars, spec, loads)
  let args = apply_subst(root, spec.pars, env.vars, spec.opts)
  { root, descr, spec, loads, args, }
}

///|
fn load_name(env : Env, name : String) -> Recipe raise RecipeError {
  match which(env, name) {
    None => raise NoRecipe(name)
    Some(path) => load_path(env, path)
  }
}

///|
fn parse_var(s : String) -> (String, String) raise RecipeError {
  match s.split("=").to_array() {
    [key, x] => (key.trim().to_owned(), x.trim().to_owned())
    _ => raise ExpectVar(s)
  }
}

///|
/// [load(name, paths~, env~)] searches and loads a recipe.
///
/// The [name] may be followed by colon-separated `<key>=<value>`
/// parameter bindings, e.g., `"analyze:depth=10"`. The recipe is searched
/// in the directories [paths], in order: the first existing `<name>`,
/// `<name>.scm` or `<name>.recipe` is taken. All recipes
/// included (`extend`ed) in the found recipe are loaded with the same
/// search paths and bindings. Parameters are substituted using [env] and
/// the bindings from [name]; every bound variable must be a parameter of
/// the recipe or of a recipe it directly extends.
#warnings("-78")
pub fn load(
  paths~ : Array[String] = [],
  env~ : Array[(String, String)] = [],
  fs~ : FileSystem = FileSystem::native(),
  name : String,
) -> Result[Recipe, RecipeError] {
  try {
    let parts = name.split(":").to_array()
    let name = parts[0].trim().to_owned()
    let vars : Map[String, String] = Map([])
    let bindings = env.copy()
    for part in parts[1:] {
      bindings.push(parse_var(part.to_owned()))
    }
    for binding in bindings {
      let (key, value) = binding
      if vars.contains(key) {
        raise DuplicateVar(key)
      }
      vars[key] = value
    }
    load_name({ fs, vars, paths, }, name)
  } catch {
    err => Err(err)
  } noraise {
    recipe => Ok(recipe)
  }
}

///|
fn collect_args(t : Recipe, out : Array[String]) -> Unit {
  for l in t.loads {
    collect_args(l, out)
  }
  out.append(t.args)
}

///|
/// The arguments specified in the recipe, preceded by the arguments of the
/// recipes it extends.
pub fn Recipe::args(self : Recipe) -> Array[String] {
  let out = []
  collect_args(self, out)
  out
}

///|
/// The recipe command, if one is specified.
pub fn Recipe::command(self : Recipe) -> String? {
  self.spec.cmd
}

///|
fn prepend_before_dash_dash(
  argv : Array[String],
  args : Array[String],
) -> Array[String] {
  match argv.search("--") {
    None => [..argv, ..args]
    Some(p) => [..argv[:p], ..args, ..argv[p:]]
  }
}

///|
/// [recipe.argv(argv~)] builds an argument vector from the recipe.
///
/// All arguments are appended to [argv] (empty by default); if [argv]
/// contains `--` then the arguments are inserted before it. If the recipe
/// specifies a command then it is inserted after the first argument of
/// [argv], unless the second argument is a prefix of the command, in which
/// case the second argument is replaced by the command.
pub fn Recipe::argv(self : Recipe, argv~ : Array[String] = []) -> Array[String] {
  match self.command() {
    None => prepend_before_dash_dash(argv, self.args())
    Some(cmd) => {
      let argv = match argv {
        [] | [_] => [..argv, cmd]
        [self_, arg, .. rest] if cmd.has_prefix(arg) => [self_, cmd, ..rest]
        [self_, arg, .. rest] => [self_, cmd, arg, ..rest]
      }
      prepend_before_dash_dash(argv, self.args())
    }
  }
}

///|
/// The recipe parameters, followed by the parameters of the recipes it
/// extends.
pub fn Recipe::params(self : Recipe) -> Array[Param] {
  let out = self.spec.pars.copy()
  for l in self.loads {
    out.append(l.params())
  }
  out
}

///|
/// The recipe description (the contents of its `descr` file).
pub fn Recipe::doc(self : Recipe) -> String {
  self.descr
}

///|
/// The recipes that this recipe extends.
pub fn Recipe::loads(self : Recipe) -> Array[Recipe] {
  self.loads
}

///|
/// The path of the recipe folder (the value of `$prefix`).
pub fn Recipe::prefix(self : Recipe) -> String {
  self.root.path
}

///|
/// Releases the resources of the recipe. Upstream this removes the folders
/// where zipped recipes are unpacked; as zipped recipes are not supported,
/// there is nothing to release.
pub fn Recipe::close(self : Recipe) -> Unit {
  for l in self.loads {
    l.close()
  }
}
