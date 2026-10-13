// A small command-line parser implementing the subset of Cmdliner that BAP
// relies on (a port of `Cmdliner_cline` and of the argument converters of
// `Cmdliner_arg`).
//
// Options are `-k` (one-letter names) or `--name` (longer names). Values
// are given as `--name=v`, `--name v`, `-kv`, or `-k v`; flags never take
// a separate value, and a glued value after a short flag is re-read as
// more short flags (`-vvv`). Unambiguous prefixes of long options are
// accepted. `--` terminates option processing.

///|
priv enum OptKind {
  Flag
  Opt
  OptVopt(String)
}

///|
priv struct PosKind {
  start : Int32
  len : Int32?
  rev : Bool
}

///|
priv struct ArgInfo {
  id : Int32
  names : Array[String]
  docv : String
  doc : String
  docs : String
  env : (String, String)?
  kind : OptKind
  pos : PosKind?
  absent : String
}

///|
let arg_counter : Ref[Int32] = Ref(0)

///|
let s_options = "OPTIONS"

///|
let s_common_options = "COMMON OPTIONS"

///|
let s_arguments = "ARGUMENTS"

///|
/// Dashes option names like Cmdliner: one-letter names become `-k`.
fn dash_name(n : String) -> String {
  if n.length() == 1 {
    "-" + n
  } else {
    "--" + n
  }
}

///|
fn ArgInfo::new(
  names~ : Array[String] = [],
  docv~ : String = "",
  doc~ : String = "",
  docs~ : String = "",
  env? : (String, String),
  kind~ : OptKind = Flag,
  pos? : PosKind,
  absent~ : String = "",
) -> ArgInfo {
  arg_counter.val += 1
  let docs = if docs != "" {
    docs
  } else if pos is Some(_) {
    s_arguments
  } else {
    s_options
  }
  {
    id: arg_counter.val,
    names: names.map(dash_name),
    docv,
    doc,
    docs,
    env,
    kind,
    pos,
    absent,
  }
}

///|
fn ArgInfo::is_pos(self : ArgInfo) -> Bool {
  self.pos is Some(_)
}

///|
priv enum ClArg {
  O(Array[(Int32, String, String?)])
  P(Array[String])
}

///|
priv struct Cline {
  values : Map[Int32, ClArg]
}

///|
fn Cline::opt_arg(self : Cline, a : ArgInfo) -> Array[(Int32, String, String?)] {
  match self.values.get(a.id) {
    Some(O(l)) => l
    _ => []
  }
}

///|
fn Cline::pos_arg(self : Cline, a : ArgInfo) -> Array[String] {
  match self.values.get(a.id) {
    Some(P(l)) => l
    _ => []
  }
}

///|
fn is_opt(s : String) -> Bool {
  s.length() > 1 && s.has_prefix("-")
}

///|
fn is_short_opt(s : String) -> Bool {
  s.length() == 2 && s.has_prefix("-")
}

///|
fn parse_opt_arg(s : String) -> (String, String?) {
  let l = s.length()
  if !s.has_prefix("--") {
    if l == 2 {
      (s, None)
    } else {
      (s[:2].to_owned(), Some(s[2:].to_owned()))
    }
  } else {
    match s.find("=") {
      Some(i) => (s[:i].to_owned(), Some(s[i + 1:].to_owned()))
      None => (s, None)
    }
  }
}

///|
fn hint_matching_opt(
  optidx : Array[(String, ArgInfo)],
  s : String,
) -> Array[String] {
  if s.length() <= 2 {
    return []
  }
  let (short_opt, long_opt) = if !s.has_prefix("--") {
    (s, "-" + s)
  } else {
    (s[1:].to_owned(), s)
  }
  let short_opt = parse_opt_arg(short_opt).0
  let long_opt = parse_opt_arg(long_opt).0
  let all = trie_ambiguities(optidx, "-")
  let l = suggest(long_opt, all)
  match (all.contains(short_opt), l) {
    (false, l) => l
    (true, []) => [short_opt]
    (true, l) => if l.contains(short_opt) { l } else { [short_opt, ..l] }
  }
}

///|
fn take_range(start : Int32, stop : Int32, l : Array[String]) -> Array[String] {
  let out = []
  for i, v in l {
    if i >= start && i <= stop {
      out.push(v)
    }
  }
  out
}

///|
fn err_pos_excess(excess : Array[String]) -> String {
  "too many arguments, don't know what to do with " +
  excess.map(quote).join(", ")
}

///|
/// Parses `args` against the argument declarations. Returns the command
/// line or the (newline-separated) error messages, together with the
/// partially parsed command line (used to honor `--help` even when the
/// command line is invalid).
fn Cline::create(
  al : Array[ArgInfo],
  args : Array[String],
  peek_opts~ : Bool = false,
) -> Result[Cline, (String, Cline)] {
  let optidx : Array[(String, ArgInfo)] = []
  let posidx : Array[ArgInfo] = []
  let values : Map[Int32, ClArg] = Map([])
  for a in al {
    if a.is_pos() {
      posidx.push(a)
      values[a.id] = P([])
    } else {
      for n in a.names {
        optidx.push((n, a))
      }
      values[a.id] = O([])
    }
  }
  let cl = { values, }
  // options
  let errs = []
  let pargs = []
  let queue = args.copy()
  queue.rev_in_place()
  let mut k = 0
  while queue.pop() is Some(s) {
    if s == "--" {
      while queue.pop() is Some(rest) {
        pargs.push(rest)
      }
      break
    }
    if !is_opt(s) {
      pargs.push(s)
      k += 1
      continue
    }
    let (name, value) = parse_opt_arg(s)
    match trie_find(optidx, name) {
      Found(a) => {
        let value = match (value, a.kind) {
          (Some(v), Flag) if is_short_opt(name) => {
            queue.push("-" + v)
            None
          }
          (Some(_), _) => value
          (None, Flag) => None
          (None, _) =>
            match queue.last() {
              None => None
              Some(v) =>
                if is_opt(v) {
                  None
                } else {
                  queue.pop() |> ignore
                  Some(v)
                }
            }
        }
        values[a.id] = O([(k, name, value), ..cl.opt_arg(a)])
      }
      NotFound =>
        if !peek_opts {
          errs.push(err_unknown("option", name, hint_matching_opt(optidx, s)))
        }
      Ambiguous =>
        errs.push(err_ambiguous("option", name, trie_ambiguities(optidx, name)))
    }
    k += 1
  }
  if !errs.is_empty() {
    return Err((errs.join("\n"), cl))
  }
  if peek_opts {
    return Ok(cl)
  }
  // positional arguments
  if pargs.is_empty() {
    return Ok(cl)
  }
  let last = pargs.length() - 1
  let pos = (rev : Bool, k : Int32) => if rev { last - k } else { k }
  let mut max_spec = -1
  for a in posidx {
    let apos = a.pos.unwrap()
    let start = pos(apos.rev, apos.start)
    let stop = match apos.len {
      None => pos(apos.rev, last)
      Some(n) => pos(apos.rev, apos.start + n - 1)
    }
    let (start, stop) = if apos.rev { (stop, start) } else { (start, stop) }
    values[a.id] = P(take_range(start, stop, pargs))
    if stop > max_spec {
      max_spec = stop
    }
  }
  if last <= max_spec {
    Ok(cl)
  } else {
    Err((err_pos_excess(take_range(max_spec + 1, last, pargs)), cl))
  }
}

// Converters ---------------------------------------------------------------------

///|
priv suberror CliError {
  CliError(String)
}

///|
fn err_flag_value(f : String, v : String) -> String {
  "option \{quote(f)} is a flag, it cannot take the argument \{quote(v)}"
}

///|
fn err_opt_value_missing(f : String) -> String {
  "option \{quote(f)} needs an argument"
}

///|
fn err_opt_parse(f : String, err : String) -> String {
  "option \{quote(f)}: \{err}"
}

///|
fn err_opt_repeated(f : String, g : String) -> String {
  if f == g {
    "option \{quote(f)} cannot be repeated"
  } else {
    "options \{quote(f)} and \{quote(g)} cannot be present at the same time"
  }
}

///|
fn err_pos_parse(a : ArgInfo, err : String) -> String {
  match a.docv {
    "" => err
    docv =>
      match a.pos {
        Some({ len: Some(1), .. }) => "\{docv} argument: \{err}"
        _ => "\{docv}... arguments: \{err}"
      }
  }
}

///|
fn err_env_parse(var_name : String, err : String) -> String {
  "environment variable \{quote(var_name)}: \{err}"
}

///|
/// The environment used to evaluate terms.
priv struct EvalEnv {
  getenv : (String) -> String?
}

///|
/// A term: the arguments it declares and how to compute its value from a
/// parsed command line (`Cmdliner.Term.t`).
priv struct Term[A] {
  args : Array[ArgInfo]
  convert : (EvalEnv, Cline) -> A raise CliError
}

///|
fn[A] Term::pure(x : A) -> Term[A] {
  { args: [], convert: (_, _) => x, }
}

///|
fn[A, B] Term::map(self : Term[A], f : (A) -> B) -> Term[B] {
  let convert = self.convert
  { args: self.args, convert: (ei, cl) => f(convert(ei, cl)), }
}

///|
/// `f.app(x)`: evaluates `f` first, then `x` (Cmdliner's `$`).
fn[A, B] Term::app(self : Term[(A) -> B], x : Term[A]) -> Term[B] {
  let cf = self.convert
  let cx = x.convert
  {
    args: [..self.args, ..x.args],
    convert: (ei, cl) => {
      let f = cf(ei, cl)
      let v = cx(ei, cl)
      f(v)
    },
  }
}

///|
fn[A] try_env(
  ei : EvalEnv,
  a : ArgInfo,
  parse : (String) -> Result[A, String],
  absent : A,
) -> A raise CliError {
  match a.env {
    None => absent
    Some((var_name, _)) =>
      match (ei.getenv)(var_name) {
        None => absent
        Some(v) =>
          match parse(v) {
            Ok(v) => v
            Err(e) => raise CliError(err_env_parse(var_name, e))
          }
      }
  }
}

///|
fn env_bool_parse(s : String) -> Result[Bool, String] {
  match s.to_lower() {
    "" | "false" | "no" | "n" | "0" => Ok(false)
    "true" | "yes" | "y" | "1" => Ok(true)
    s => Err(err_invalid_val(s, alts_str(["true", "yes", "false", "no"])))
  }
}

///|
fn arg_flag(a : ArgInfo) -> Term[Bool] {
  {
    args: [a],
    convert: (ei, cl) => {
      match cl.opt_arg(a) {
        [] => try_env(ei, a, env_bool_parse, false)
        [(_, _, None)] => true
        [(_, f, Some(v))] => raise CliError(err_flag_value(f, v))
        [(_, f, _), (_, g, _), ..] => raise CliError(err_opt_repeated(f, g))
      }
    },
  }
}

///|
fn arg_flag_all(a : ArgInfo) -> Term[Array[Bool]] {
  {
    args: [a],
    convert: (ei, cl) => {
      match cl.opt_arg(a) {
        [] =>
          try_env(
            ei,
            a,
            s => {
              match env_bool_parse(s) {
                Ok(b) => Ok([b])
                Err(e) => Err(e)
              }
            },
            [],
          )
        l => {
          let out = []
          for i = l.length() - 1; i >= 0; i = i - 1 {
            match l[i] {
              (_, _, None) => out.push(true)
              (_, f, Some(v)) => raise CliError(err_flag_value(f, v))
            }
          }
          out
        }
      }
    },
  }
}

///|
fn[A] arg_vflag(default : A, choices : Array[(A, ArgInfo)]) -> Term[A] {
  {
    args: choices.map(c => c.1),
    convert: (_, cl) => {
      let mut fv : (String, A)? = None
      for c in choices {
        let (v, a) = c
        match cl.opt_arg(a) {
          [] => ()
          [(_, f, None)] =>
            match fv {
              None => fv = Some((f, v))
              Some((g, _)) => raise CliError(err_opt_repeated(g, f))
            }
          [(_, f, Some(v))] => raise CliError(err_flag_value(f, v))
          [(_, f, _), (_, g, _), ..] => raise CliError(err_opt_repeated(g, f))
        }
      }
      match fv {
        None => default
        Some((_, v)) => v
      }
    },
  }
}

///|
fn[A] arg_vflag_all(
  default : Array[A],
  choices : Array[(A, ArgInfo)],
) -> Term[Array[A]] {
  {
    args: choices.map(c => c.1),
    convert: (_, cl) => {
      let acc : Array[(Int32, A)] = []
      for c in choices {
        let (fv, a) = c
        for occ in cl.opt_arg(a) {
          match occ {
            (k, _, None) => acc.push((k, fv))
            (_, f, Some(v)) => raise CliError(err_flag_value(f, v))
          }
        }
      }
      if acc.is_empty() {
        default
      } else {
        acc.sort_by((x, y) => x.0.compare(y.0))
        acc.map(p => p.1)
      }
    },
  }
}

///|
fn[A] parse_opt_value(
  parse : (String) -> Result[A, String],
  f : String,
  v : String,
) -> A raise CliError {
  match parse(v) {
    Ok(v) => v
    Err(err) => raise CliError(err_opt_parse(f, err))
  }
}

///|
fn[A] arg_opt(
  vopt? : A,
  parse : (String) -> Result[A, String],
  default : A,
  a : ArgInfo,
) -> Term[A] {
  {
    args: [a],
    convert: (ei, cl) => {
      match cl.opt_arg(a) {
        [] => try_env(ei, a, parse, default)
        [(_, f, Some(v))] => parse_opt_value(parse, f, v)
        [(_, f, None)] =>
          match vopt {
            None => raise CliError(err_opt_value_missing(f))
            Some(v) => v
          }
        [(_, f, _), (_, g, _), ..] => raise CliError(err_opt_repeated(g, f))
      }
    },
  }
}

///|
fn[A] arg_opt_all(
  vopt? : A,
  parse : (String) -> Result[A, String],
  default : Array[A],
  a : ArgInfo,
) -> Term[Array[A]] {
  {
    args: [a],
    convert: (ei, cl) => {
      match cl.opt_arg(a) {
        [] =>
          try_env(
            ei,
            a,
            s => {
              match parse(s) {
                Ok(v) => Ok([v])
                Err(e) => Err(e)
              }
            },
            default,
          )
        l => {
          let parsed : Array[(Int32, A)] = []
          for occ in l {
            let (k, f, v) = occ
            match v {
              Some(v) => parsed.push((k, parse_opt_value(parse, f, v)))
              None =>
                match vopt {
                  None => raise CliError(err_opt_value_missing(f))
                  Some(dv) => parsed.push((k, dv))
                }
            }
          }
          parsed.sort_by((x, y) => x.0.compare(y.0))
          parsed.map(p => p.1)
        }
      }
    },
  }
}

///|
fn[A] parse_pos_value(
  parse : (String) -> Result[A, String],
  a : ArgInfo,
  v : String,
) -> A raise CliError {
  match parse(v) {
    Ok(v) => v
    Err(err) => raise CliError(err_pos_parse(a, err))
  }
}

///|
fn[A] arg_pos(
  parse : (String) -> Result[A, String],
  default : A,
  a : ArgInfo,
) -> Term[A] {
  {
    args: [a],
    convert: (ei, cl) => {
      match cl.pos_arg(a) {
        [] => try_env(ei, a, parse, default)
        [v] => parse_pos_value(parse, a, v)
        _ => raise CliError("too many positional values for \{a.docv}")
      }
    },
  }
}

///|
fn[A] arg_pos_list(
  parse : (String) -> Result[A, String],
  default : Array[A],
  a : ArgInfo,
) -> Term[Array[A]] {
  {
    args: [a],
    convert: (ei, cl) => {
      match cl.pos_arg(a) {
        [] =>
          try_env(
            ei,
            a,
            s => {
              match parse(s) {
                Ok(v) => Ok([v])
                Err(e) => Err(e)
              }
            },
            default,
          )
        l => {
          let out = []
          for v in l {
            out.push(parse_pos_value(parse, a, v))
          }
          out
        }
      }
    },
  }
}
