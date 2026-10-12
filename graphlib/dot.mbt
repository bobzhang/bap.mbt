///|
fn graph_dot_escape(text : String) -> String {
  let builder = StringBuilder()
  for i in 0..<text.char_length() {
    match text.get_char(i) {
      Some(char) =>
        match char.to_int() {
          10 => builder.write_string("\\l")
          34 => builder.write_string("\\\"")
          92 => builder.write_string("\\\\")
          _ => builder.write_char(char)
        }
      None => ()
    }
  }
  builder.to_string()
}

///|
fn graph_dot_quote(text : String) -> String {
  "\"\{graph_dot_escape(text)}\""
}

///|
fn[N] graph_dot_no_node_attrs(_node : N) -> Array[(String, String)] {
  []
}

///|
fn[N, E] graph_dot_no_edge_attrs(_edge : Edge[N, E]) -> Array[(String, String)] {
  []
}

///|
fn graph_dot_has_attr(
  attrs : ArrayView[(String, String)],
  key : String,
) -> Bool {
  attrs.any(attr => attr.0 == key)
}

///|
fn graph_dot_write_attrs(
  builder : StringBuilder,
  attrs : ArrayView[(String, String)],
) -> Unit {
  if !attrs.is_empty() {
    builder.write_string(" [")
    for i, attr in attrs {
      if i > 0 {
        builder.write_string(", ")
      }
      builder.write_string(attr.0)
      builder.write_string("=")
      builder.write_string(graph_dot_quote(attr.1))
    }
    builder.write_string("]")
  }
}

///|
fn[N : Hash + Eq, E] graph_dot_default_node_names(
  graph : Graph[N, E],
) -> Map[N, String] {
  graph.depth_first_search(init=({} : Map[N, String]), leave_node=(
    rpost,
    node,
    names,
  ) => {
    names[node] = rpost.to_string()
    names
  })
}

///|
fn[N : Hash + Eq] graph_dot_node_name(
  node : N,
  default_names : Map[N, String],
  string_of_node : ((N) -> String)?,
) -> String {
  match string_of_node {
    Some(to_string) => to_string(node)
    None =>
      match default_names.get(node) {
        Some(name) => name
        None => ""
      }
  }
}

///|
fn[N, E] graph_dot_edge_attrs(
  edge : Edge[N, E],
  edge_attrs : (Edge[N, E]) -> Array[(String, String)],
  string_of_edge : ((Edge[N, E]) -> String)?,
) -> Array[(String, String)] {
  let attrs = edge_attrs(edge)
  match string_of_edge {
    Some(to_string) if !graph_dot_has_attr(attrs, "label") => {
      let out = [("label", to_string(edge))]
      for attr in attrs {
        out.push(attr)
      }
      out
    }
    _ => attrs
  }
}

///|
pub fn[N : Hash + Eq, E] Graph::to_dot(
  self : Graph[N, E],
  name~ : String = "G",
  graph_attrs~ : ArrayView[(String, String)] = [],
  node_attrs~ : (N) -> Array[(String, String)] = graph_dot_no_node_attrs,
  edge_attrs~ : (Edge[N, E]) -> Array[(String, String)] = graph_dot_no_edge_attrs,
  string_of_node~ : ((N) -> String)? = None,
  string_of_edge~ : ((Edge[N, E]) -> String)? = None,
) -> String {
  let default_names = graph_dot_default_node_names(self)
  let builder = StringBuilder()
  builder.write_string("digraph ")
  builder.write_string(graph_dot_quote(name))
  builder.write_string(" {\n")
  for attr in graph_attrs {
    builder.write_string("  ")
    builder.write_string(attr.0)
    builder.write_string("=")
    builder.write_string(graph_dot_quote(attr.1))
    builder.write_string(";\n")
  }
  for node in self.nodes {
    builder.write_string("  ")
    builder.write_string(
      graph_dot_quote(graph_dot_node_name(node, default_names, string_of_node)),
    )
    graph_dot_write_attrs(builder, node_attrs(node))
    builder.write_string(";\n")
  }
  for edge in self.edges {
    builder.write_string("  ")
    builder.write_string(
      graph_dot_quote(
        graph_dot_node_name(edge.src, default_names, string_of_node),
      ),
    )
    builder.write_string(" -> ")
    builder.write_string(
      graph_dot_quote(
        graph_dot_node_name(edge.dst, default_names, string_of_node),
      ),
    )
    graph_dot_write_attrs(
      builder,
      graph_dot_edge_attrs(edge, edge_attrs, string_of_edge),
    )
    builder.write_string(";\n")
  }
  builder.write_string("}\n")
  builder.to_string()
}
