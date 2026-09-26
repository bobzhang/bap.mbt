///|
/// The plugin name.
pub let plugin_name : String = "callgraph-collator"

///|
/// The name of the registered collator.
pub let name : String = "callgraph"

///|
let doc : String =
  #|Compares projects by their callgraphs. Outputs differences immitating
  #|uniform diff format, e.g., `- src -> dst` indicates that in the
  #|alternative version there is no call from src to dst, and `+ src -> dst`
  #|means that in the base there is no call from src to dst.

///|
/// Callgraph filters (`ignore-reserved`, `ignore-unresolved`,
/// `ignore-matching`).
pub struct CallgraphFilter {
  ignore_reserved : Bool
  ignore_unresolved : Bool
  ignore_matching : Regex?
}

///|
/// Creates a filter; `ignore_matching` is a PCRE-style regular expression that
/// ignores functions it partially matches.
pub fn CallgraphFilter::new(
  ignore_reserved? : Bool = false,
  ignore_unresolved? : Bool = false,
  ignore_matching? : String,
) -> Result[CallgraphFilter, String] {
  let regex = match ignore_matching {
    None => None
    Some(pattern) =>
      match Regex::compile(pattern) {
        Ok(regex) => Some(regex)
        Err(reason) => return Err(reason)
      }
  }
  Ok({ ignore_reserved, ignore_unresolved, ignore_matching: regex, })
}

///|
/// `true` if a function name passes the filter.
pub fn CallgraphFilter::accepts(self : CallgraphFilter, name : String) -> Bool {
  let ignored = (
      self.ignore_reserved && (name.has_prefix("_") || name.has_prefix("."))
    ) ||
    (self.ignore_unresolved && name.has_prefix("sub_")) ||
    (match self.ignore_matching {
      Some(regex) => regex.execp(name)
      None => false
    })
  !ignored
}

///|
/// The name of a call destination: the name of the target tid with leading
/// `@` and `%` stripped (`name_of_dst`).
pub fn name_of_dst(jmp : @types.Term[@types.Jmp]) -> String? {
  match jmp.alt() {
    Some(ResolvedDst(tid)) => {
      let text = tid.to_string()
      let mut i = 0
      while i < text.length() && (text[i] == '@' || text[i] == '%') {
        i += 1
      }
      Some(text.unsafe_substring(start=i, end=text.length()))
    }
    _ => None
  }
}

///|
fn insert_sorted(dsts : Array[String], dst : String) -> Unit {
  match dsts.binary_search_by(x => x.lexical_compare(dst)) {
    Ok(_) => ()
    Err(i) => dsts.insert(i, dst)
  }
}

///|
/// Collects the calls of a program as a map from caller names to the sorted
/// set of callee names.
pub fn calls_of_program(
  prog : @types.Term[@types.Program],
  filter : CallgraphFilter,
) -> Map[String, Array[String]] {
  let calls : Map[String, Array[String]] = Map([])
  for sub in prog.subs() {
    let src = sub.sub_name()
    for blk in sub.blks() {
      for jmp in blk.jmps() {
        match name_of_dst(jmp) {
          Some(dst) if filter.accepts(src) && filter.accepts(dst) =>
            match calls.get(src) {
              Some(dsts) => insert_sorted(dsts, dst)
              None => calls[src] = [dst]
            }
          _ => ()
        }
      }
    }
  }
  calls
}

///|
fn set_diff(xs : Array[String], ys : Array[String]) -> Array[String] {
  xs.filter(x => !ys.contains(x))
}

///|
/// Renders the difference between a base and an alternative callgraph
/// (`None` when they are equal).
pub fn diff_calls(
  base : Map[String, Array[String]],
  alt : Map[String, Array[String]],
) -> String? {
  let keys = []
  for key in base.keys() {
    keys.push(key)
  }
  for key in alt.keys() {
    if !base.contains(key) {
      keys.push(key)
    }
  }
  keys.sort_by(String::lexical_compare)
  let sb = StringBuilder()
  let mut different = false
  let print = (pref : Char, src : String, dsts : Array[String]) => {
    for dst in dsts {
      sb.write_string("\{pref} \{src} -> \{dst}\n")
    }
  }
  for src in keys {
    match (base.get(src), alt.get(src)) {
      (Some(lhs), None) => {
        different = true
        print('-', src, lhs)
      }
      (None, Some(rhs)) => {
        different = true
        print('+', src, rhs)
      }
      (Some(lhs), Some(rhs)) if lhs != rhs => {
        different = true
        print('-', src, set_diff(lhs, rhs))
        print('+', src, set_diff(rhs, lhs))
      }
      _ => ()
    }
  }
  if different {
    Some(sb.to_string())
  } else {
    None
  }
}

///|
/// The summary line printed after all versions were collated.
pub fn summary_text(diffs : Int) -> String {
  match diffs {
    0 => "All versions have the same callgraph as the base version\n"
    1 => "Found one version that is different\n"
    n => "Found \{n} versions that are different\n"
  }
}

///|
/// Creates the callgraph collator. Its output is written to `file` at the end
/// of the summary, or streamed to `out`.
pub fn collator(
  filter : CallgraphFilter,
  file? : String,
  out? : (String) -> Unit = s => println(s.trim_end(chars="\n")),
) -> @project.RegisteredProjectCollator {
  let buffer = StringBuilder()
  let emit = (text : String) => {
    match file {
      Some(_) => buffer.write_string(text)
      None => out(text)
    }
  }
  @project.RegisteredProjectCollator::create(
    name~,
    pkg="bap",
    description="compares binaries by their callgraphs",
    prepare=project => (calls_of_program(project.program(), filter), 0),
    collate=(ver, state, project) => {
      let (base, diffs) = state
      let alt = calls_of_program(project.program(), filter)
      match diff_calls(base, alt) {
        Some(text) => {
          emit("Version \{ver} differs:\n")
          emit(text)
          (base, diffs + 1)
        }
        None => {
          emit("Version \{ver} is not different\n")
          (base, diffs)
        }
      }
    },
    summary=state => {
      emit(summary_text(state.1))
      match file {
        Some(path) =>
          match @native_io.write_file(path, @utf8.encode(buffer.to_string())) {
            Ok(_) => ()
            Err(reason) => out("failed to write \{path}: \{reason}")
          }
        None => ()
      }
    },
  )
}

///|
let registered : Ref[Bool] = Ref(false)

///|
/// Registers the `bap:callgraph` collator. Idempotent: returns `false` when it
/// was already registered by this package.
pub fn register(
  ignore_reserved? : Bool = false,
  ignore_unresolved? : Bool = false,
  ignore_matching? : String,
  file? : String,
  out? : (String) -> Unit,
) -> Result[Bool, String] {
  if registered.val {
    return Ok(false)
  }
  let filter = match
    CallgraphFilter::new(ignore_reserved~, ignore_unresolved~, ignore_matching?) {
    Ok(filter) => filter
    Err(reason) => return Err(reason)
  }
  match @project.register_collator(collator(filter, file?, out?)) {
    Ok(_) => {
      registered.val = true
      Ok(true)
    }
    Err(reason) => Err(reason)
  }
}

///|
/// Declares the `callgraph-collator` plugin to `bap_main` with its
/// parameters. Does nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(plugin_name) {
    return
  }
  @bap_main.register_plugin(plugin_name, provides=["collator"], doc~, () => {
    let ignore_reserved = @bap_main.Configuration::flag(
      doc="Ignore functions that have reserved names, i.e., starting with _ (underscore) or . (dot).",
      "ignore-reserved",
    )
    let ignore_unresolved = @bap_main.Configuration::flag(
      doc="Ignore functions with dummy names, i.e., starting with sub_.",
      "ignore-unresolved",
    )
    let ignore_matching = @bap_main.Configuration::parameter(
      doc="Ignore functions that partially match the speciefied PCRE regular expression.",
      @bap_main.Type::some(@bap_main.Type::string()),
      "ignore-matching",
    )
    let output = @bap_main.Configuration::parameter(
      doc="Outputs all information into the specified file.",
      @bap_main.Type::some(@bap_main.Type::string()),
      "output",
    )
    @bap_main.Extension::register(ctxt => {
      match
        register(
          ignore_reserved=ctxt.get(ignore_reserved),
          ignore_unresolved=ctxt.get(ignore_unresolved),
          ignore_matching?=ctxt.get(ignore_matching),
          file?=ctxt.get(output),
        ) {
        Ok(_) => ()
        Err(reason) => fail(reason)
      }
    })
  })
}
