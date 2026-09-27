// The commands of the frontend: `.`, `list`, and `config` (upstream
// `bap_frontend.ml`).

///|
/// The entities that `bap list` can print.
pub(all) enum Entity {
  Entities
  Plugins
  Commands
  Recipes
  Tags
  Passes
  Formats
  Classes
  Theories
  Agents
  Rules
  Collators
  Targets
} derive(Eq, Debug)

///|
pub extend Entity with Eq::{equal, not_equal}

///|
pub extend Entity with Debug::{to_repr}

///|
let entities : Array[(String, Entity)] = [
  ("entities", Entities),
  ("plugins", Plugins),
  ("commands", Commands),
  ("recipes", Recipes),
  ("tags", Tags),
  ("features", Tags),
  ("passes", Passes),
  ("formats", Formats),
  ("classes", Classes),
  ("theories", Theories),
  ("agents", Agents),
  ("rules", Rules),
  ("collators", Collators),
  ("targets", Targets),
]

///|
pub fn Entity::name(self : Entity) -> String {
  match self {
    Entities => "entities"
    Plugins => "plugins"
    Commands => "commands"
    Recipes => "recipes"
    Tags => "features"
    Passes => "passes"
    Formats => "formats"
    Classes => "classes"
    Theories => "theories"
    Agents => "agents"
    Rules => "rules"
    Collators => "collators"
    Targets => "targets"
  }
}

///|
let entity_desc : Array[(Entity, String)] = [
  (Entities, "prints this message"),
  (Plugins, "installed BAP plugins"),
  (Commands, "bap utility commands"),
  (Recipes, "installed recipes"),
  (Tags, "plugin capabilities"),
  (Passes, "disassembler passes"),
  (Formats, "data output formats"),
  (Classes, "knowledge representation classes"),
  (Theories, "installed theories"),
  (Agents, "knowledge providers"),
  (Rules, "knowledge base rules"),
  (Collators, "project collators (comparators)"),
]

///|
fn unqualified(s : String) -> String {
  match s.rev_find(".") {
    None => s
    Some(p) => s[p + 1:].to_owned()
  }
}

///|
/// Whether `str` is in `set`, possibly unqualified or lowercased
/// (upstream `matches`).
fn matches(default : Bool, set : Array[String]?, str : String) -> Bool {
  match set {
    None => default
    Some(set) =>
      set.contains(str) ||
      set.contains(unqualified(str)) ||
      set.contains(unqualified(str).to_lower())
  }
}

///|
/// Splits the `--filter` list into the requested and the excluded names.
fn parse_filter(filter : Array[String]) -> (Array[String]?, Array[String]?) {
  let mut features : Array[String]? = None
  let mut exclude : Array[String]? = None
  let push = (x : String, xs : Array[String]?) => {
    match xs {
      None => Some([x])
      Some(xs) => Some([x, ..xs])
    }
  }
  for elt in filter {
    if elt.has_prefix("-") {
      exclude = push(elt[1:].to_owned(), exclude)
    } else if elt.has_prefix("+") {
      features = push(elt[1:].to_owned(), features)
    } else {
      features = push(elt, features)
    }
  }
  (features, exclude)
}

///|
fn term_class_name(cls : @types.IrTermClass) -> String {
  match cls {
    ProgramTermClass => "Bap.Std.Program"
    SubTermClass => "Bap.Std.Sub"
    ArgTermClass => "Bap.Std.Arg"
    BlkTermClass => "Bap.Std.Blk"
    PhiTermClass => "Bap.Std.Phi"
    DefTermClass => "Bap.Std.Def"
    JmpTermClass => "Bap.Std.Jmp"
  }
}

///|
/// The registered data writers grouped by the type name (upstream
/// `Data.all_writers`): `(typename, [(name, version, description)])`.
fn all_writers() -> Array[(String, Array[(String, String, String)])] {
  let version = @bap_main.Configuration::version()
  let groups : Array[(String, Array[(String, String, String)])] = [
    (
      "Bap.Std.Project",
      @print.writers().map(w => (w.name(), w.version(), w.desc())),
    ),
  ]
  for entry in @print.term_writers() {
    let (cls, name, desc) = entry
    let typename = term_class_name(cls)
    match groups.search_by(g => g.0 == typename) {
      Some(i) => groups[i].1.push((name, version, desc))
      None => groups.push((typename, [(name, version, desc)]))
    }
  }
  groups
}

///|
fn list_entity(
  what : Entity,
  ctxt : @bap_main.Ctxt,
  selected : (String) -> Bool,
  io : Io,
) -> Unit {
  let sb = StringBuilder()
  match what {
    Recipes => {
      @recipe_command.list_recipes(out=s => sb.write_string(s), err=io.err)
      sb.write_string(
        "Use the `print-recipes' for the detailed list of recipes\n",
      )
    }
    Plugins => sb.write_string(pp_info(ctxt.plugins()))
    Commands => sb.write_string(pp_info(ctxt.commands()))
    Passes =>
      for p in @project.passes() {
        sb.write_string("  \{p.name()}\n")
      }
    Tags =>
      for feature in ctxt.features() {
        let plugins = ctxt
          .refine(provides=[feature])
          .plugins()
          .map(p => p.name())
        sb.write_string("  \{pad_right(feature, 24)} \{plugins.join(", ")}\n")
      }
    Formats =>
      for group in all_writers() {
        let (typename, writers) = group
        if selected(typename) {
          sb.write_string("  \{typename}:\n")
          for w in writers {
            let (name, ver, desc) = w
            let desc = if desc == "" { "no description provided" } else { desc }
            sb.write_string(
              "    \{pad_right("\{name} (\{ver})", 22)} \{desc}\n",
            )
          }
        }
      }
    Classes =>
      for entry in @knowledge.Documentation::classes() {
        let (cls, properties) = entry
        let name = cls.name().show()
        if selected(name) {
          sb.write_string("\n  \{pad_right(name, 30)} \{cls.desc()}\n")
          for prop in properties {
            sb.write_string(
              "    - \{pad_right(prop.name().show(), 26)} \{prop.desc()}\n",
            )
          }
        }
      }
    Theories => ()
    Agents =>
      for agent in @knowledge.Documentation::agents() {
        let name = agent.name().show()
        if selected(name) {
          sb.write_string("  \{pad_right(name, 32)} \{agent.desc()}\n")
        }
      }
    Rules =>
      for rule in @knowledge.Documentation::rules() {
        sb.write_string("(\{rule.name().show()}")
        for req in rule.requires() {
          sb.write_string("\n  (require \{req.show()})")
        }
        sb.write_string("\n  (provide \{rule.provides().show()}))\n")
        if rule.desc() != "" {
          sb.write_string("; \{rule.desc()}\n")
        }
      }
    Collators =>
      for collator in @project.registered_collators() {
        let name = collator.qualified_name().show()
        if selected(name) {
          sb.write_string("  \{pad_right(name, 32)} \{collator.desc()}\n")
        }
      }
    Entities =>
      for entry in entity_desc {
        let (entity, desc) = entry
        let name = entity.name()
        if selected(name) {
          sb.write_string("  \{pad_right(name, 24)} \{desc}\n")
        }
      }
    Targets =>
      for family in @core_theory.Target::families() {
        match family {
          [parent, .. members] => {
            let pkg = parent.name().pkg()
            sb.write_string("  \{parent.to_string()}:\n")
            for m in members {
              let n = m.name()
              let name = if n.pkg() == pkg { n.unqualified() } else { n.show() }
              sb.write_string("   - \{name}\n")
            }
          }
          [] => ()
        }
      }
  }
  (io.out)(sb.to_string())
}

///|
let config_doc : String =
  #|
  #|# DESCRIPTION
  #|
  #|Does nothing and prints nothing. This command could be used to hush
  #|the default bap usage message, which is printed when the bap command
  #|is issued without any arguments.
  #|

///|
/// Declares the `.`, `list`, and `config` commands of the frontend.
pub fn declare_commands(io : Io) -> Unit raise {
  @bap_main.Command::register(doc=config_doc, ".", @bap_main.Command::args(), _ => {
    ()
  })
  let what = @bap_main.Command::argument(
    @bap_main.Type::enumeration(entities).with_default(Entities),
  )
  let filter = @bap_main.Command::parameter(
    aliases=["f"],
    doc="Select what to print. The input is a comma-separated list of names, optionally prefixed with the minus sign, e.g., $(b,--filter=foo,-bar). When specified, then only entities with specified names will be printed. If the name is specified with the $(b,-) before it, then entities with that name will not be printed.",
    @bap_main.Type::list(@bap_main.Type::string()),
    "filter",
  )
  @bap_main.Command::register(
    doc="explores various BAP facilities",
    "list",
    @bap_main.Command::args().add(what).add(filter),
    what => {
      filter => {
        ctxt => {
          let (requires, exclude) = parse_filter(filter)
          let ctxt = ctxt.refine(provides?=requires, exclude?)
          let selected = (name : String) => {
            matches(true, requires, name) && !matches(false, exclude, name)
          }
          list_entity(what, ctxt, selected, io)
        }
      }
    },
  )
  let config_entities : Array[(String, String)] = [
    ("version", @bap_main.Configuration::version()),
    ("build_id", @bap_main.Configuration::build_id()),
    ("datadir", @bap_main.Configuration::datadir()),
    ("cachedir", @bap_main.Configuration::cachedir()),
    ("sysdatadir", @bap_main.Configuration::sysdatadir()),
    ("libdir", @bap_main.Configuration::libdir()),
    ("confdir", @bap_main.Configuration::confdir()),
    ("bindir", @bap_main.Configuration::bindir()),
    ("plugindir", @bap_main.Configuration::plugindir()),
  ]
  let entity = @bap_main.Command::argument(
    @bap_main.Type::some(@bap_main.Type::enumeration(config_entities)),
  )
  @bap_main.Command::register(
    doc="prints BAP configuration",
    "config",
    @bap_main.Command::args().add(entity),
    entity => {
      _ctxt => {
        match entity {
          Some(value) => (io.out)(value + "\n")
          None =>
            for entry in config_entities {
              (io.out)("\{entry.0}: \{entry.1}\n")
            }
        }
      }
    },
  )
}
