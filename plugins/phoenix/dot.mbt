// The DOT rendering of the control flow graph (upstream `Phoenix_dot`,
// printed like `Graph.Graphviz.Dot.fprint_graph` from ocamlgraph).

///|
/// Escapes a CFG label (upstream `escape_label`).
fn escape_label(s : String) -> String {
  let buf = StringBuilder()
  for c in s {
    match c {
      '\n' | '\r' => buf.write_string("\\l")
      ',' | ';' => buf.write_char(' ')
      '\t' => buf.write_string("<tabulation>")
      _ => buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Renders a block with `@[<v>...@]@?` as upstream `label_of_vertex`.
fn vbox_text(pp : (@text_tags.Formatter) -> Unit) -> String {
  let fmt = @text_tags.Formatter::new()
  fmt.open_vbox(0)
  pp(fmt)
  fmt.close_box()
  fmt.flush_str()
}

///|
/// The label of a CFG node (upstream `label_of_vertex`).
pub fn Env::vertex_label(
  self : Env,
  blk : @project.ProjectDisassemblyBlock,
) -> String {
  let formats = self.options.cfg_format.copy()
  formats.sort_by((a, b) => a.rank().compare(b.rank()))
  let parts = formats.map(format => {
    match format {
      WithName => "«\{self.block_name(blk.addr())}»\\n"
      WithAsm =>
        escape_label(
          vbox_text(fmt => {
            self.pp_blk(fmt, blk, (fmt, blk) => pp_insns(fmt, blk))
          }),
        )
      WithBil =>
        escape_label(
          vbox_text(fmt => {
            self.pp_blk(fmt, blk, (fmt, blk) => {
              pp_stmts(fmt, self.bil_of_block(blk))
            })
          }),
        )
    }
  })
  parts.join("")
}

///|
/// Prints an ocamlgraph attribute list ` [a, b, ]` (the attributes are
/// printed in the reverse order, as `filter_style` reverses them).
fn pp_attributes(fmt : @text_tags.Formatter, attrs : Array[String]) -> Unit {
  if attrs.is_empty() {
    return
  }
  fmt.print_string(" [")
  fmt.open_hovbox(0)
  for attr in attrs.rev() {
    fmt.print_string(attr + ",")
    fmt.print_space()
  }
  fmt.close_box()
  fmt.print_string("]")
}

///|
fn dot_color(c : Int32) -> String {
  let hex = c.to_string(radix=16).to_upper()
  "\"#" + String::make(6 - hex.length(), '0') + hex + "\""
}

///|
fn edge_attributes(
  kind : @project.ProjectDisassemblyEdgeKind,
  mono : Bool,
) -> Array[String] {
  let (color, weight) = match (kind, mono) {
    (FallEdge, false) => (0x660000, 4)
    (FallEdge, true) => (0x000066, 8)
    (CondEdge, _) => (0x006600, 2)
    (JumpEdge, _) => (0x000066, 2)
  }
  [
    "color=\{dot_color(color)}",
    "arrowsize=0.500000",
    "headport=n",
    "tailport=s",
    "labelfloat=true",
    "weight=\{weight}",
  ]
}

///|
/// Prints the whole-program CFG in the DOT format. As upstream, every
/// function file contains the CFG of the whole program (`iter_vertex`
/// ignores the function).
pub fn Env::pp_cfg(self : Env, fmt : @text_tags.Formatter) -> Unit {
  let nodes = self.cfg.nodes()
  fmt.print_format("@[<v>digraph G {@ @[<v 2>  ")
  fmt.print_string("fontsize=14;")
  fmt.print_space()
  // nodes
  fmt.print_string("node")
  pp_attributes(fmt, [
    "shape=box",
    "fontsize=14",
    "fontcolor=\{dot_color(0x666699)}",
    "fontname=\"Monospace\"",
    "width=1.000000",
  ])
  fmt.print_string(";")
  fmt.print_space()
  for blk in nodes {
    fmt.print_string(ocaml_quote(self.block_name(blk.addr())))
    pp_attributes(fmt, ["label=\"\{self.vertex_label(blk)}\""])
    fmt.print_string(";")
    fmt.print_space()
  }
  fmt.print_space()
  // there are no subgraphs
  fmt.print_space()
  // edges
  fmt.print_string("edge")
  pp_attributes(fmt, ["penwidth=1.000000"])
  fmt.print_string(";")
  fmt.print_space()
  for src in nodes {
    let outputs = self.cfg.outputs(src)
    let mono = outputs.length() == 1
    for e in outputs {
      fmt.print_string(
        "\{ocaml_quote(self.block_name(src.addr()))} -> \{ocaml_quote(self.block_name(e.dst().addr()))}",
      )
      pp_attributes(fmt, edge_attributes(e.kind(), mono))
      fmt.print_string(";")
      fmt.print_space()
    }
  }
  fmt.print_space()
  fmt.print_format("@]}@;@]")
}

///|
/// Renders the CFG in the DOT format.
pub fn Env::cfg_to_dot(self : Env) -> String {
  let fmt = @text_tags.Formatter::new()
  @text_tags.install(fmt, "html") catch {
    _ => ()
  }
  self.pp_cfg(fmt)
  fmt.flush_str()
}

///|
/// Quotes a string like OCaml's `%S`.
fn ocaml_quote(s : String) -> String {
  let buf = StringBuilder()
  buf.write_char('"')
  for b in @utf8.encode(s) {
    let code = b.to_int()
    match code {
      0x22 => buf.write_string("\\\"")
      0x5c => buf.write_string("\\\\")
      0x0a => buf.write_string("\\n")
      0x09 => buf.write_string("\\t")
      0x0d => buf.write_string("\\r")
      0x08 => buf.write_string("\\b")
      _ =>
        if code < 0x20 || code >= 0x7f {
          let d = code.to_string()
          buf.write_char('\\')
          buf.write_string(String::make(3 - d.length(), '0') + d)
        } else {
          buf.write_char(code.unsafe_to_char())
        }
    }
  }
  buf.write_char('"')
  buf.to_string()
}
