///|
fn[N] graph_render_set(
  elements : Set[N],
  element_to_string : (N) -> String,
  sep~ : String,
) -> String {
  let parts : Array[String] = []
  for element in elements {
    parts.push(element_to_string(element))
  }
  parts.join(sep)
}

///|
pub fn[E] GraphPath::to_string(
  self : GraphPath[E],
  edge_to_string~ : (E) -> String,
) -> String {
  let parts = self.edges_value.map(edge => edge_to_string(edge))
  if parts.is_empty() {
    "{}"
  } else {
    "{ " + parts.join(", ") + "}"
  }
}

///|
pub fn[N : Hash + Eq] Tree::to_string(
  self : Tree[N],
  node_to_string~ : (N) -> String,
) -> String {
  let builder = StringBuilder()
  builder.write_string("digraph {\n")
  if self.all_value.length() == 1 {
    builder.write_string("  ")
    builder.write_string(graph_dot_quote(node_to_string(self.all_value[0])))
    builder.write_string("\n")
  } else {
    for parent in self.all_value {
      for child in self.children(parent) {
        builder.write_string("  ")
        builder.write_string(graph_dot_quote(node_to_string(parent)))
        builder.write_string(" -> ")
        builder.write_string(graph_dot_quote(node_to_string(child)))
        builder.write_string("\n")
      }
    }
  }
  builder.write_string("}")
  builder.to_string()
}

///|
pub fn[N : Hash + Eq] Frontier::to_string(
  self : Frontier[N],
  node_to_string~ : (N) -> String,
) -> String {
  let lines : Array[String] = []
  for source in self.all_value {
    match self.map_value.get(source) {
      Some(elements) =>
        lines.push(
          "[\{node_to_string(source)} => (\{graph_render_set(elements, node_to_string, sep=" ")})]",
        )
      None => lines.push("()")
    }
  }
  lines.join("\n")
}

///|
pub fn[N] Group::to_string(
  self : Group[N],
  element_to_string~ : (N) -> String,
) -> String {
  "{\{self.equiv_value.to_int()}: \{element_to_string(self.top_value)} => (\{graph_render_set(self.members_value, element_to_string, sep=" ")})}"
}

///|
pub fn[N] Partition::to_string(
  self : Partition[N],
  element_to_string~ : (N) -> String,
) -> String {
  let builder = StringBuilder()
  builder.write_string("partition = {\n")
  for group in self.groups() {
    builder.write_string("  ")
    builder.write_string(group.to_string(element_to_string~))
    builder.write_string("\n")
  }
  builder.write_string("}")
  builder.to_string()
}
