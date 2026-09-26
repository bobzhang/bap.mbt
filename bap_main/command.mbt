// Port of `Bap_main.Extension.Command`: commands with typed command-line
// grammars.
//
// BAP builds a grammar with `args $ p1 $ p2 ...`, where the type of the
// command function is threaded through `('f, 'r) t`. MoonBit has no
// user-defined `$`, so the grammar is extended with `Grammar::add`:
//
//   Command::args().add(p1).add(p2)
//
// has type `Grammar[(A1) -> (A2) -> R, R]` for `p1 : CommandParam[A1]`,
// `p2 : CommandParam[A2]`, and the command function receives the parsed
// arguments followed by the context.

///|
priv enum ParamKind {
  PosParam
  AllParam
  KeyParam
}

///|
/// A command-line parameter of a command (`'a Command.param`).
pub struct CommandParam[A] {
  priv kind : ParamKind
  priv make : (Int) -> Term[A]
}

///|
/// A command-line grammar (`('f, 'r) Command.t`): `F` is the type of the
/// command function and `R` its result after all arguments are applied.
pub struct Grammar[F, R] {
  priv len : Int?
  priv invalid : String?
  priv run : (F) -> Term[R]
}

///|
/// The type of command functions.
pub type CommandFn = (Ctxt) -> Unit raise

///|
/// Namespace for `Bap_main.Extension.Command` functions.
pub(all) struct Command {}

///|
/// `Command::args()` is the empty grammar.
pub fn[A] Command::args() -> Grammar[A, A] {
  { len: Some(0), invalid: None, run: f => Term::pure(f), }
}

///|
/// `grammar.add(p)` extends the grammar with the parameter `p`
/// (`grammar $ p` in BAP). Positional parameters are numbered in the order
/// they are added; no positional parameter may follow `arguments`.
pub fn[A, B, C] Grammar::add(
  self : Grammar[A, (B) -> C],
  p : CommandParam[B],
) -> Grammar[A, C] {
  let (len, invalid) = match (self.len, p.kind) {
    (Some(n), PosParam) => (Some(n + 1), self.invalid)
    (Some(_), AllParam) => (None, self.invalid)
    (None, PosParam) | (None, AllParam) =>
      (None, Some("can't add an argument after arguments"))
    (l, KeyParam) => (l, self.invalid)
  }
  let n = self.len.unwrap_or(0)
  let run = self.run
  let make = p.make
  { len, invalid, run: f => run(f).app(make(n)), }
}

///|
/// `Command::argument(t)` is a positional argument of type `t`.
pub fn[A] Command::argument(doc? : String = "", t : Type[A]) -> CommandParam[A] {
  {
    kind: PosParam,
    make: n => {
      let info = ArgInfo::new(
        docv=t.name,
        doc~,
        pos={ start: n, len: Some(1), rev: false, },
        absent=(t.print)(t.default),
      )
      arg_pos(converter(t), t.default, info)
    },
  }
}

///|
/// `Command::arguments(t)` is any number of positional arguments of type
/// `t` (all the remaining ones).
pub fn[A] Command::arguments(
  doc? : String = "",
  t : Type[A],
) -> CommandParam[Array[A]] {
  {
    kind: AllParam,
    make: n => {
      let info = ArgInfo::new(docv=t.name, doc~, pos={
        start: n,
        len: None,
        rev: false,
      })
      arg_pos_list(converter(t), [], info)
    },
  }
}

///|
fn[A] key_param(t : Term[A]) -> CommandParam[A] {
  { kind: KeyParam, make: _ => t, }
}

///|
/// `Command::switch(values, name)` is a choice between `--<name v>`
/// options; `Some(v)` if one is given, `None` otherwise.
pub fn[A] Command::switch(
  doc? : (A) -> String,
  aliases? : (A) -> Array[String] = _ => [],
  values : Array[A],
  name : (A) -> String,
) -> CommandParam[A?] {
  let doc = match doc {
    Some(f) => f
    None => s => "Select \{name(s)}"
  }
  let choices = values.map(x => {
    (
      Some(x),
      ArgInfo::new(names=[name(x), ..aliases(x)], doc=doc(x), kind=Flag),
    )
  })
  key_param(arg_vflag(None, choices))
}

///|
/// `Command::switches(values, name)` is a multiple choice: every occurrence
/// of `--<name v>` adds `v` to the list (in command-line order).
pub fn[A] Command::switches(
  doc? : (A) -> String,
  aliases? : (A) -> Array[String] = _ => [],
  values : Array[A],
  name : (A) -> String,
) -> CommandParam[Array[A]] {
  let doc = match doc {
    Some(f) => f
    None => s => "Select \{name(s)}"
  }
  let choices = values.map(x => {
    (x, ArgInfo::new(names=[name(x), ..aliases(x)], doc=doc(x), kind=Flag))
  })
  key_param(arg_vflag_all([], choices))
}

///|
/// `Command::dictionary(keys, t, name)` declares a `--<name k>[=]v` option
/// for each key `k`. The result has one binding per key (the default of
/// `t` for the omitted ones), in reverse order of `keys` (as in BAP).
pub fn[K, D] Command::dictionary(
  doc? : (K) -> String,
  as_flag? : (K) -> D,
  aliases? : (K) -> Array[String] = _ => [],
  keys : Array[K],
  data : Type[D],
  name : (K) -> String,
) -> CommandParam[Array[(K, D)]] {
  let docv = data.name
  let mut terms : Term[Array[(K, D)]] = Term::pure([])
  for key in keys {
    let n = name(key)
    let names = [n, ..aliases(key)]
    let d = match doc {
      None => "sets `\{n}' to \{docv}"
      Some(f) => f(key)
    }
    let vopt = match as_flag {
      None => None
      Some(f) => Some(f(key))
    }
    let kind = match vopt {
      None => Opt
      Some(v) => OptVopt((data.print)(v))
    }
    let info = ArgInfo::new(
      names~,
      docv~,
      doc=d,
      kind~,
      absent=(data.print)(data.default),
    )
    let term = arg_opt(vopt?, converter(data), data.default, info)
    terms = terms.map(xs => (x : D) => [(key, x), ..xs]).app(term)
  }
  key_param(terms)
}

///|
/// `Command::parameter(t, name)` is an optional `--<name>[=]v` parameter
/// (one-letter names and aliases are short keys: `-k v`). The default of
/// `t` is used when it is absent; with `as_flag` the value may be omitted.
pub fn[A] Command::parameter(
  doc? : String = "",
  as_flag? : A,
  aliases? : Array[String] = [],
  t : Type[A],
  name : String,
) -> CommandParam[A] {
  let kind = match as_flag {
    None => Opt
    Some(v) => OptVopt((t.print)(v))
  }
  let info = ArgInfo::new(
    names=[name, ..aliases],
    docv=t.name,
    doc~,
    kind~,
    absent=(t.print)(t.default),
  )
  key_param(arg_opt(vopt?=as_flag, converter(t), t.default, info))
}

///|
/// `Command::parameters(t, name)` is a multi-occurring parameter; values
/// are collected in command-line order.
pub fn[A] Command::parameters(
  doc? : String = "",
  as_flag? : A,
  aliases? : Array[String] = [],
  t : Type[A],
  name : String,
) -> CommandParam[Array[A]] {
  let kind = match as_flag {
    None => Opt
    Some(v) => OptVopt((t.print)(v))
  }
  let info = ArgInfo::new(names=[name, ..aliases], docv=t.name, doc~, kind~)
  key_param(arg_opt_all(vopt?=as_flag, converter(t), [], info))
}

///|
/// `Command::flag(name)` is `true` if `--<name>` occurs (at most once).
pub fn Command::flag(
  doc? : String = "",
  aliases? : Array[String] = [],
  name : String,
) -> CommandParam[Bool] {
  let info = ArgInfo::new(names=[name, ..aliases], doc~, kind=Flag)
  key_param(arg_flag(info))
}

///|
/// `Command::flags(name)` is the number of occurrences of `--<name>`.
pub fn Command::flags(
  doc? : String = "",
  aliases? : Array[String] = [],
  name : String,
) -> CommandParam[Int] {
  let info = ArgInfo::new(names=[name, ..aliases], doc~, kind=Flag)
  key_param(arg_flag_all(info).map(xs => xs.filter(x => x).length()))
}

///|
/// `Command::register(name, grammar, f)` declares the command `name`
/// (`Command.declare`).
///
/// When `name` is selected on the command line and its arguments parse,
/// `f` is applied to them and to the context, refined to the plugins that
/// provide one of `requires` (all plugins when not specified). Raises
/// `Invalid` if the grammar is ill-formed.
///
/// A command declared twice makes `init` fail with `Configuration`.
pub fn[F] Command::register(
  doc? : String = "no description provided",
  requires? : Array[String],
  name : String,
  grammar : Grammar[F, CommandFn],
  f : F,
) -> Unit raise {
  if grammar.invalid is Some(msg) {
    raise Invalid(msg)
  }
  let man = markdown_to_manpage(doc)
  let short = short_description(default=doc, first_sentence_of_man(man))
  let term = (grammar.run)(f)
  let st = main_state.val
  st.slot.actions.push((name, short))
  st.commands.push({ name, term, doc: short, man, requires, })
}
