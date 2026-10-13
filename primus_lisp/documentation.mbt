// Documentation of Lisp programs (upstream `Bap_primus_lisp.Doc` and
// `plugins/primus_lisp/primus_lisp_documentation.ml`).

///|
/// The documentation of a definition.
pub struct DocEntry {
  /// the normalized documentation string
  desc : String
  /// the source code of the definition, if it comes from a source
  code : String?
  /// the location (with the base name of the file)
  loc : Loc?
}

///|
fn[T] DocEntry::create(prog : Program, def : Def[T]) -> DocEntry {
  let src = prog.sources
  let desc = @primus.info_normalize_text(def.docs)
  if def.id != 0 && src.has_loc(def.id) {
    let loc = src.loc(def.id)
    let base = match loc.file.rev_find("/") {
      Some(i) => loc.file.unsafe_substring(start=i + 1, end=loc.file.length())
      None => loc.file
    }
    { desc, code: Some(src.text_at(loc)), loc: Some({ ..loc, file: base, }), }
  } else {
    { desc, code: None, loc: None, }
  }
}

///|
fn merge_desc(x : String, y : String) -> String {
  if x == "" {
    y
  } else if y == "" || x == y {
    x
  } else {
    "\{x}\nOR\n\{y}"
  }
}

///|
fn DocEntry::merge(self : DocEntry, other : DocEntry) -> DocEntry {
  {
    desc: merge_desc(self.desc, other.desc),
    code: match self.code {
      Some(c) => Some(c)
      None => other.code
    },
    loc: match self.loc {
      Some(l) => Some(l)
      None => other.loc
    },
  }
}

///|
fn[T] describe(
  prog : Program,
  item : Item[T],
) -> Array[(@knowledge.Name, DocEntry)] {
  let entries : Map[String, (@knowledge.Name, DocEntry)] = Map([])
  let seen : Map[(String, Int32), Unit] = Map([])
  prog.fold(item, init=(), (pkg, def, _) => {
    let name = @knowledge.Name::create(def.name, pkg~)
    let k = name.show()
    // the same definition is visible in many packages, merge by name
    if !seen.contains((k, def.id)) {
      seen[(k, def.id)] = ()
      let e = DocEntry::create(prog, def)
      entries[k] = match entries.get(k) {
        Some((n, old)) => (n, old.merge(e))
        None => (name, e)
      }
    }
  })
  let out = entries.values().collect()
  out.sort_by((a, b) => a.0.show().compare(b.0.show()))
  out
}

///|
/// The documentation index of the program: categories (`Macros`,
/// `Substitutions`, `Constants`, `Functions`, `Methods`, `Parameters`,
/// `Primitives`, `Signals`) with the documented definitions, empty
/// categories are omitted (upstream `Doc.create_index`).
pub fn documentation(
  prog : Program,
) -> Array[(String, Array[(@knowledge.Name, DocEntry)])] {
  let prims = describe(prog, primitive) + describe(prog, semantics)
  let index = [
    ("Macros", describe(prog, macro_item)),
    ("Substitutions", describe(prog, subst)),
    ("Constants", describe(prog, const_item)),
    ("Functions", describe(prog, func)),
    ("Methods", describe(prog, meth)),
    ("Parameters", describe(prog, para)),
    ("Primitives", prims),
    ("Signals", describe(prog, signal_item)),
  ]
  index.filter(c => !c.1.is_empty())
}

///|
/// Renders the documentation index in the Org-mode format (upstream
/// `Primus_lisp_documentation.print`).
pub fn documentation_to_org(
  index : Array[(String, Array[(@knowledge.Name, DocEntry)])],
) -> String {
  let buf = StringBuilder()
  for cat in index {
    buf.write_string("* \{cat.0}\n")
    for e in cat.1 {
      buf.write_string("** ~\{e.0.show()}~\n")
      buf.write_string(e.1.desc)
      buf.write_char('\n')
    }
  }
  buf.to_string()
}
