// DOT renderings of the callgraph and of the BIR control flow graphs
// (upstream `Graphlib.Dot.pp_graph`, `print_callgraph`, and
// `print_bir_graph`).

///|
/// A generic DOT printer (upstream `Graphlib.Dot.pp_graph`). Nodes and
/// edges are given by their names and labels, an empty label is omitted.
pub fn pp_dot_graph(
  fmt : @text_tags.Formatter,
  name? : String,
  cluster~ : Bool = false,
  subgraph~ : Bool = false,
  attrs~ : Array[String] = [],
  nodes~ : ArrayView[(String, String)],
  edges~ : ArrayView[(String, String, String)],
) -> Unit {
  let attrs = if attrs.is_empty() { "" } else { "@;" + attrs.join("@;") }
  let graphname = match name {
    None => ""
    Some(name) =>
      if cluster {
        escape_ocaml_string("cluster_" + name)
      } else {
        escape_ocaml_string(name)
      }
  }
  let graph = if subgraph { "subgraph" } else { "digraph" }
  fmt.print_format("@.@[<v2>")
  fmt.print_string("\{graph} \{graphname} {")
  // the attributes are spliced into the format string upstream
  fmt.print_format(attrs)
  match name {
    Some(name) => {
      fmt.print_format("@;")
      fmt.print_string("label=\{escape_ocaml_string(name)}")
      fmt.print_format("@;")
    }
    None => ()
  }
  for node in nodes {
    fmt.print_format("@;")
    match node.1 {
      "" => fmt.print_string("\"\{node.0}\"")
      label => fmt.print_string("\"\{node.0}\"[label=\"\{label}\"]")
    }
  }
  for edge in edges {
    fmt.print_format("@;")
    fmt.print_string("\"\{edge.0}\" -> \"\{edge.1}\"")
    if edge.2 != "" {
      fmt.print_string("[label=\"\{edge.2}\"]")
    }
  }
  fmt.print_format("@]@.}")
}

///|
/// Prints the program callgraph in the DOT format (upstream
/// `Graphs.Callgraph.pp`).
pub fn pp_callgraph(
  fmt : @text_tags.Formatter,
  program : @types.Term[@types.Program],
) -> Unit {
  let graph = @types.Program::to_graph(program)
  let nodes = graph.nodes().map(tid => (tid_name(tid), ""))
  let edges = graph.edges().map(e => (tid_name(e.src), tid_name(e.dst), ""))
  pp_dot_graph(fmt, nodes~, edges~)
}

///|
/// Renders a term with a plain formatter (upstream `Term.to_string`).
fn term_to_line(pp : (@text_tags.Formatter) -> Unit) -> String {
  let fmt = @text_tags.Formatter::new()
  pp(fmt)
  fmt.flush_str()
}

///|
fn bir_node_label(blk : @types.Term[@types.Blk]) -> String {
  let lines = []
  for phi in blk.phis() {
    lines.push(term_to_line(fmt => pp_phi(fmt, phi)))
  }
  for def in blk.defs() {
    lines.push(term_to_line(fmt => pp_def(fmt, def)))
  }
  for jmp in blk.jmps() {
    let keep = match jmp.kind() {
      JmpCall(_) | Ret(_) | Interrupt(_, _) => true
      Goto(_) => jmp.succ_tid_of_jmp() is None
    }
    if keep {
      lines.push(term_to_line(fmt => pp_jmp(fmt, jmp)))
    }
  }
  let body = lines.join("\n").replace_all(old="\n", new="\\l")
  "\\\{tid_to_string(blk.tid())}\n\{body}"
}

///|
fn bir_node_name(blk : @types.Term[@types.Blk]) -> String {
  "\\" + tid_to_string(blk.tid())
}

///|
/// Prints the control flow graph of a subroutine as a DOT cluster
/// (upstream `pp_bir_cfg`).
pub fn pp_bir_cfg(
  fmt : @text_tags.Formatter,
  sub : @types.Term[@types.Sub],
  labeled~ : Bool = true,
) -> Unit {
  let cfg = sub.to_cfg()
  let nodes = cfg
    .nodes()
    .map(blk => {
      (bir_node_name(blk), if labeled { bir_node_label(blk) } else { "" })
    })
  let edges = cfg
    .edges()
    .map(e => {
      let label = if labeled {
        let cond = e.cond(sub)
        if cond is Int(w) && w.is_one() {
          ""
        } else {
          exp_to_string(cond)
        }
      } else {
        ""
      }
      (bir_node_name(e.src()), bir_node_name(e.dst()), label)
    })
  pp_dot_graph(
    fmt,
    name=sub.sub_name(),
    subgraph=true,
    cluster=true,
    nodes~,
    edges~,
  )
}

///|
/// Prints the control flow graphs of all subroutines together with the
/// interprocedural call edges (upstream `print_bir_graph`).
pub fn pp_bir_graph(
  fmt : @text_tags.Formatter,
  program : @types.Term[@types.Program],
  labeled~ : Bool = true,
) -> Unit {
  let entries : Map[@types.Tid, @types.Tid] = Map([])
  for sub in program.subs() {
    match sub.first_blk() {
      Some(entry) => entries[sub.tid()] = entry.tid()
      None => ()
    }
  }
  fmt.print_format("digraph {@\nnode[shape=box];@\n")
  for sub in program.subs() {
    pp_bir_cfg(fmt, sub, labeled~)
    fmt.print_format("@.")
    for src in sub.blks() {
      for jmp in src.jmps() {
        match jmp.alt() {
          Some(dst) =>
            match @types.Jmp::resolve(dst) {
              ResolvedTarget(dst) =>
                match entries.get(dst) {
                  Some(dst) => {
                    fmt.print_string(
                      "\"\\\{tid_to_string(src.tid())}\" -> \"\\\{tid_to_string(dst)}\";",
                    )
                    fmt.print_format("@\n")
                  }
                  None => ()
                }
              IndirectTarget(_) => ()
            }
          None => ()
        }
      }
    }
  }
  fmt.print_string("}")
}
