// The BML standard library (upstream `Bap_bml` module initializers) and
// the extra functions registered by the `map_terms` plugin.

///|
fn unit_name(prefix : String, key : String, suffix : String) -> String {
  let name = prefix + "-" + key
  if suffix == "" {
    name
  } else {
    name + "-" + suffix
  }
}

///|
/// The unit markers: (attribute, suffix, predicate prefix).
fn unit_markers() -> Array[(Attr, String, String)] {
  let result = []
  for attr in [Attr::synthetic(), Attr::live(), Attr::dead(), Attr::visited()] {
    result.push((attr, "", "is"))
  }
  for
    attr in [
      Attr::sub_const(),
      Attr::sub_pure(),
      Attr::stub(),
      Attr::sub_extern(),
      Attr::sub_leaf(),
      Attr::sub_malloc(),
      Attr::sub_noreturn(),
      Attr::sub_returns_twice(),
      Attr::sub_nothrow(),
    ] {
    result.push((attr, "sub", "is"))
  }
  for attr in [@types.Arg::alloc_size(), @types.Arg::nonnull()] {
    result.push((attr, "arg", "is"))
  }
  result.push((Attr::mark(), "", "has"))
  result
}

///|
let tainted_reg_attr : String = Attr::tainted_reg(@types.Tid::for_name("")).key

///|
let tainted_ptr_attr : String = Attr::tainted_ptr(@types.Tid::for_name("")).key

///|
let color_grammar : String = [
  "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white", "gray",
].join(" | ")

///|
/// Parses a color name (upstream `Color.color_t`).
pub fn parse_color(s : String) -> @types.IrColor raise ParseError {
  match @types.IrColor::of_string(s) {
    Some(color) => color
    None => raise expect(color_grammar, s)
  }
}

///|
/// Quotes a string as OCaml's `%S` conversion does.
fn ocaml_quote(s : String) -> String {
  let buf = StringBuilder()
  buf.write_char('"')
  for byte in @utf8.encode(s) {
    let c = byte.to_int()
    match c {
      0x22 => buf.write_string("\\\"")
      0x5c => buf.write_string("\\\\")
      0x0a => buf.write_string("\\n")
      0x09 => buf.write_string("\\t")
      0x0d => buf.write_string("\\r")
      0x08 => buf.write_string("\\b")
      _ =>
        if c >= 0x20 && c <= 0x7e {
          buf.write_char(c.unsafe_to_char())
        } else {
          let d = c.to_string()
          buf.write_char('\\')
          for _ in d.length()..<3 {
            buf.write_char('0')
          }
          buf.write_string(d)
        }
    }
  }
  buf.write_char('"')
  buf.to_string()
}

///|
fn expect(what : String, got : String) -> ParseError {
  ParseError("Expected \{what} got \{ocaml_quote(got)}")
}

///|
fn tid_of_attr(term : IrTerm, key : String) -> @types.Tid? {
  match term.get_attr(key) {
    Some(text) =>
      match @types.Tid::from_string(text) {
        Ok(tid) => Some(tid)
        Err(_) => None
      }
    None => None
  }
}

///|
/// The taint identifiers mentioned in the value of the attribute [key]
/// (the `tainted-regs`/`tainted-ptrs` attributes map variables to sets of
/// taints; every `%`- or `@`-prefixed token of the value is a taint).
fn taints_of_attr(term : IrTerm, key : String) -> Array[@types.Tid] {
  guard term.get_attr(key) is Some(text) else { [] }
  let result = []
  let token = StringBuilder()
  let flush = () => {
    let s = token.to_string()
    token.reset()
    if s.has_prefix("%") || s.has_prefix("@") {
      if @types.Tid::from_string(s) is Ok(tid) {
        result.push(tid)
      }
    }
  }
  for c in text {
    if c is (' ' | '\t' | '\n' | '(' | ')' | '{' | '}' | '[' | ']' | ',' | ';') {
      flush()
    } else {
      token.write_char(c)
    }
  }
  flush()
  result
}

///|
/// The attribute that maps registers to the taints of their values
/// (upstream `Taint.regs`).
pub let tainted_regs_attr : String = "tainted-regs"

///|
/// The attribute that maps registers to the taints of the values they
/// point to (upstream `Taint.ptrs`).
pub let tainted_ptrs_attr : String = "tainted-ptrs"

///|
fn has_seed(kind : String, s : String) -> Predicate {
  term => {
    match tid_of_attr(term, kind) {
      None => false
      Some(seed) =>
        match @types.Tid::from_string(s) {
          Ok(expected) => seed == expected
          Err(_) => false
        }
    }
  }
}

///|
fn has_taint(kind : String, s : String) -> Predicate {
  term => {
    term.has_attr(kind) &&
    (match @types.Tid::from_string(s) {
      Ok(taint) => taints_of_attr(term, kind).contains(taint)
      Err(_) => false
    })
  }
}

///|
fn either(x : Predicate, y : Predicate) -> Predicate {
  term => x(term) || y(term)
}

///|
fn seed(key : String) -> Mapper {
  term => {
    map_deep(term, t => t.set_attr(Attr::new(key~, value=t.tid().to_string())))
  }
}

///|
fn color_marker(
  set : (@types.IrColor) -> Attr,
) -> (String) -> Mapper raise ParseError {
  s => marker(set(parse_color(s)))
}

///|
fn color_equal(
  get : (IrTerm) -> @types.IrColor?,
) -> (String) -> Predicate raise ParseError {
  s => {
    let color = parse_color(s)
    term => get(term) == Some(color)
  }
}

// Plugin (`map_terms`) features

///|
fn term_addr(s : String) -> Predicate {
  term => term.has_address_text(s)
}

///|
fn term_tid(s : String) -> Predicate {
  match @types.Tid::from_string(s) {
    Err(_) => _ => false
    Ok(tid) => term => term.tid() == tid
  }
}

///|
fn term_name(s : String) -> Predicate {
  term => term.name() == s
}

///|
fn def_lhs(s : String) -> Predicate {
  term => {
    match term {
      DefTerm(def) => def.lhs().name() == s
      _ => false
    }
  }
}

///|
fn def_uses(s : String) -> Predicate {
  term => {
    match term {
      DefTerm(def) => def.def_free_vars().any(v => v.name() == s)
      _ => false
    }
  }
}

///|
priv enum ParentOf {
  OfSub
  OfBlk(@types.Tid)
}

///|
fn find_parent(sub : @types.Term[@types.Sub], child : @types.Tid) -> ParentOf? {
  if sub.blks().any(b => b.tid() == child) {
    return Some(OfSub)
  }
  for blk in sub.blks() {
    if blk.jmps().any(t => t.tid() == child) ||
      blk.defs().any(t => t.tid() == child) ||
      blk.phis().any(t => t.tid() == child) {
      return Some(OfBlk(blk.tid()))
    }
  }
  None
}

///|
/// The stateful `term-parent` predicate: a subroutine is satisfied if it
/// contains the block [s]; a block is satisfied if it contains the term [s]
/// and its subroutine was checked before.
fn term_parent(s : String) -> Predicate {
  match @types.Tid::from_string(s) {
    Err(_) => _ => false
    Ok(tid) => {
      let marked : Ref[@types.Tid?] = { val: None, }
      term => {
        match term {
          BlkTerm(b) =>
            match marked.val {
              None => false
              Some(m) => b.tid() == m
            }
          SubTerm(sub) =>
            match find_parent(sub, tid) {
              Some(OfSub) => true
              Some(OfBlk(b)) => {
                marked.val = Some(b)
                false
              }
              None => false
            }
          _ => false
        }
      }
    }
  }
}

///|
/// Removes the attribute [key] from a term, but not from its subterms
/// (upstream `unmarker`).
fn unset_attr(key : String) -> Mapper {
  term => term.del_attr(key)
}

///|
fn stdlib_predicates() -> Ops[Predicate] {
  let ops = Ops::new()
  for entry in unit_markers() {
    let (attr, suffix, prefix) = entry
    ops.nullary.register(unit_name(prefix, attr.key, suffix), has(attr.key))
  }
  // colors
  ops.unary.register("has-foreground", color_equal(t => t.foreground()))
  ops.unary.register("has-background", color_equal(t => t.background()))
  ops.unary.register("has-color", color_equal(t => t.color()))
  // taints
  let reg = tainted_reg_attr
  let ptr = tainted_ptr_attr
  ops.nullary.register("taints", either(has(reg), has(ptr)))
  ops.nullary.register("taints-reg", has(reg))
  ops.nullary.register("taints-ptr", has(ptr))
  ops.nullary.register(
    "has-taints",
    either(has(tainted_ptrs_attr), has(tainted_regs_attr)),
  )
  ops.nullary.register("has-tainted-ptr", has(tainted_ptrs_attr))
  ops.nullary.register("has-tainted-reg", has(tainted_regs_attr))
  // NB: as upstream, the unary `taints-reg` checks the pointer seed and
  // `taints-ptr` checks the register seed.
  ops.unary.register("taints-reg", s => has_seed(ptr, s))
  ops.unary.register("taints-ptr", s => has_seed(reg, s))
  ops.unary.register("has-tainted-ptr", s => has_taint(tainted_ptrs_attr, s))
  ops.unary.register("has-tainted-reg", s => has_taint(tainted_regs_attr, s))
  ops.nullary.register("true", _ => true)
  // map_terms plugin features
  ops.unary.register("term-addr", s => term_addr(s))
  ops.unary.register("term-tid", s => term_tid(s))
  ops.unary.register("term-name", s => term_name(s))
  ops.unary.register("term-parent", s => term_parent(s))
  ops.unary.register("def-lhs", s => def_lhs(s))
  ops.unary.register("def-uses", s => def_uses(s))
  ops
}

///|
fn stdlib_mappers() -> Ops[Mapper] {
  let ops = Ops::new()
  for entry in unit_markers() {
    let (attr, suffix, _) = entry
    ops.nullary.register(unit_name("set", attr.key, suffix), marker(attr))
  }
  ops.unary.register("foreground", color_marker(Attr::foreground))
  ops.unary.register("background", color_marker(Attr::background))
  ops.unary.register("color", color_marker(Attr::color))
  ops.unary.register("comment", s => marker(Attr::comment(s)))
  ops.unary.register("python", s => marker(Attr::python(s)))
  ops.nullary.register("taint-ptr", seed(tainted_ptr_attr))
  ops.nullary.register("taint-reg", seed(tainted_reg_attr))
  // map_terms plugin features
  ops.unary.register("unset-attr", s => unset_attr(s))
  ops
}
