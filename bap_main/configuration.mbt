// Port of `Bap_main.Extension.Configuration`: plugin configuration
// parameters that can be specified on the command line
// (`--<plugin>-<name>`), in the environment (`BAP_<PLUGIN>_<NAME>`), or in
// configuration files (`<plugin>-<name> = <value>`), in that order of
// precedence, falling back to the default value of the parameter type.

///|
/// A configuration parameter (`'a Configuration.param`).
pub struct Parameter[A] {
  priv value : @future.Future[(Ctxt, A)]
}

///|
/// Namespace for `Bap_main.Extension.Configuration` functions.
pub(all) struct Configuration {}

///|
fn option_name(pctxt : PluginCtxt, name : String) -> String {
  "\{pctxt.name}-\{name}"
}

///|
/// `BAP_<NAME>` with dashes replaced by underscores, uppercased.
fn env_var_for_option(name : String) -> String {
  "BAP_" + name.replace_all(old="-", new="_").to_upper()
}

///|
/// Decides the default value of a parameter from the environment, then
/// from the configuration files, then from its type.
fn[A] decide_default(t : Type[A], name : String, pctxt : PluginCtxt) -> A raise {
  let name = option_name(pctxt, name)
  let parse = (where_ : String, what : String) => {
    (t.parse)(what) catch {
      e =>
        raise Invalid(
          "the value \{ocaml_quote(what)} for the parameter \{ocaml_quote(name)} is malformed in the \{where_} - \{parse_error_message(e)}",
        )
    }
  }
  match (pctxt.getenv)(env_var_for_option(name)) {
    Some(v) => parse("process environment ", v)
    None =>
      match pctxt.config.iter().find_first(kv => kv.0 == name) {
        None => t.default
        Some((_, v)) => parse("configuration file", v)
      }
  }
}

///|
/// `Grammar.extend`: registers the builder of the option term of a
/// parameter with the plugin being loaded.
fn[A, B] extend_grammar(
  wrap : (Type[A]) -> Type[B],
  typ : Type[A],
  make_term : (Type[A], B, Array[String], String, String) -> Term[B],
  doc : String,
  aliases : Array[String],
  name : String,
) -> Parameter[B] {
  let (value, ready) = @future.Future::create()
  let wrapped = wrap(typ)
  main_state.val.slot.specs.push(pctxt => {
    let names = [name, ..aliases].map(n => option_name(pctxt, n))
    let default = decide_default(wrapped, name, pctxt)
    let term = make_term(typ, default, names, doc, wrapped.name)
    let key = option_name(pctxt, name)
    term.map(x => {
      () => {
        ready.try_fulfill(x) |> ignore
        context_set(
          scope=pctxt.name,
          key~,
          value=(wrapped.print)(x),
          digest=(wrapped.digest)(x),
        )
      }
    })
  })
  { value: context_state.val.ready.both(value), }
}

///|
/// `Configuration::parameter(t, name)` declares a configuration parameter
/// of the plugin being loaded.
///
/// The parameter extends the common options with `--<plugin>-<name>[=]v`
/// (and `--<plugin>-<alias>` for each alias; even one-letter names are
/// prefixed and long). With `as_flag`, the value may be omitted on the
/// command line and `as_flag` is used.
pub fn[A] Configuration::parameter(
  doc? : String = "Undocumented",
  as_flag? : A,
  aliases? : Array[String] = [],
  t : Type[A],
  name : String,
) -> Parameter[A] {
  extend_grammar(
    x => x,
    t,
    (t, default, names, doc, docv) => {
      let kind = match as_flag {
        None => Opt
        Some(v) => OptVopt((t.print)(v))
      }
      let info = ArgInfo::new(
        names~,
        docs=s_common_options,
        doc~,
        docv~,
        kind~,
        absent=(t.print)(default),
      )
      arg_opt(vopt?=as_flag, converter(t), default, info)
    },
    doc,
    aliases,
    name,
  )
}

///|
/// `Configuration::parameters(t, name)` declares a multi-occurring
/// parameter: every occurrence of `--<plugin>-<name> v` adds `v` to the
/// list. From the environment and configuration files the value is read
/// as a comma-separated list.
pub fn[A] Configuration::parameters(
  doc? : String = "Undocumented",
  as_flag? : A,
  aliases? : Array[String] = [],
  t : Type[A],
  name : String,
) -> Parameter[Array[A]] {
  extend_grammar(
    x => Type::list(x),
    t,
    (t, default, names, doc, docv) => {
      let kind = match as_flag {
        None => Opt
        Some(v) => OptVopt((t.print)(v))
      }
      let info = ArgInfo::new(names~, docs=s_common_options, doc~, docv~, kind~)
      arg_opt_all(vopt?=as_flag, converter(t), default, info)
    },
    doc,
    aliases,
    name,
  )
}

///|
/// `Configuration::flag(name)` declares a boolean parameter that is set by
/// `--<plugin>-<name>` (or by a `true` value in the environment or in a
/// configuration file).
pub fn Configuration::flag(
  doc? : String = "Undocumented",
  aliases? : Array[String] = [],
  name : String,
) -> Parameter[Bool] {
  extend_grammar(
    x => x,
    Type::bool(),
    (_, default, names, doc, _) => {
      let info = ArgInfo::new(names~, docs=s_common_options, doc~, kind=Flag)
      arg_flag(info).map(x => x || default)
    },
    doc,
    aliases,
    name,
  )
}

///|
/// `Configuration::get(ctxt, p)` is `ctxt.get(p)`.
pub fn[A] Configuration::get(ctxt : Ctxt, p : Parameter[A]) -> A {
  ctxt.get(p)
}

///|
/// `Configuration::determined(p)` is a future that becomes determined with
/// the value of `p` once the context is ready.
pub fn[A] Configuration::determined(p : Parameter[A]) -> @future.Future[A] {
  p.value.map(p => p.1)
}

///|
/// The preconfigured BAP version.
pub fn Configuration::version() -> String {
  "2.6.0-alpha"
}

///|
/// The short commit SHA when built from a development tree (empty here).
pub fn Configuration::build_id() -> String {
  ""
}

///|
/// The installation prefix used for the preconfigured directories.
let config_prefix = "/usr/local"

///|
/// The directory for system-wide BAP read-only data.
pub fn Configuration::sysdatadir() -> String {
  config_prefix + "/share/bap"
}

///|
/// The directory for BAP libraries and internal binaries.
pub fn Configuration::libdir() -> String {
  config_prefix + "/lib"
}

///|
/// The directory for system-wide BAP configuration files.
pub fn Configuration::confdir() -> String {
  config_prefix + "/etc/bap"
}

///|
/// The directory for binaries.
pub fn Configuration::bindir() -> String {
  config_prefix + "/bin"
}

///|
/// The directory for plugins.
pub fn Configuration::plugindir() -> String {
  config_prefix + "/lib/bap"
}

///|
/// The directory for user-specific BAP read-only data:
/// `$XDG_DATA_HOME/bap`, or `$HOME/.local/share/bap`, or the current
/// directory. `getenv` defaults to the process environment.
pub fn Configuration::datadir(
  getenv? : (String) -> String? = @env.get_env_var,
) -> String {
  match getenv("XDG_DATA_HOME") {
    Some(dir) => filename_concat(dir, "bap")
    None =>
      match getenv("HOME") {
        Some(dir) =>
          filename_concat(
            filename_concat(filename_concat(dir, ".local"), "share"),
            "bap",
          )
        None => @env.current_dir().unwrap_or(".")
      }
  }
}

///|
/// The directory for user-specific non-essential data: `$XDG_CACHE_HOME/bap`,
/// or `$HOME/.cache/bap`, or `$TMPDIR/bap/cache`.
pub fn Configuration::cachedir(
  getenv? : (String) -> String? = @env.get_env_var,
) -> String {
  match getenv("XDG_CACHE_HOME") {
    Some(dir) => filename_concat(dir, "bap")
    None =>
      match getenv("HOME") {
        Some(dir) => filename_concat(filename_concat(dir, ".cache"), "bap")
        None => {
          let tmp = getenv("TMPDIR").unwrap_or("/tmp")
          filename_concat(filename_concat(tmp, "bap"), "cache")
        }
      }
  }
}
