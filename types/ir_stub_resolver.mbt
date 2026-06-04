///|
let sub_stub_attr = "stub"

///|
let sub_alias_attr_prefix = "alias:"

///|
fn add_unique_text(items : Array[String], item : String) -> Unit {
  if !items.contains(item) {
    items.push(item)
  }
}

///|
fn add_unique_tid(items : Array[Tid], item : Tid) -> Unit {
  if !items.contains(item) {
    items.push(item)
  }
}

///|
fn sorted_texts(items : Array[String]) -> Array[String] {
  let result = items.copy()
  result.sort_by((left, right) => left.compare(right))
  result
}

///|
pub fn Attr::stub() -> Attr {
  Attr::flag(sub_stub_attr)
}

///|
pub fn Attr::sub_alias(alias_name : String) -> Attr {
  Attr::new(key=sub_alias_attr_prefix + alias_name, value=alias_name)
}

///|
pub fn Term::with_stub(self : Term[Sub]) -> Term[Sub] {
  self.set_attr(Attr::stub())
}

///|
pub fn Term::without_stub(self : Term[Sub]) -> Term[Sub] {
  self.del_attr(sub_stub_attr)
}

///|
pub fn Term::is_stub(self : Term[Sub]) -> Bool {
  self.has_attr(sub_stub_attr)
}

///|
pub fn Term::with_sub_alias(self : Term[Sub], alias_name : String) -> Term[Sub] {
  self.set_attr(Attr::sub_alias(alias_name))
}

///|
pub fn Term::without_sub_alias(
  self : Term[Sub],
  alias_name : String,
) -> Term[Sub] {
  self.del_attr(sub_alias_attr_prefix + alias_name)
}

///|
pub fn Term::sub_aliases(self : Term[Sub]) -> Array[String] {
  let aliases = []
  let attrs = self.attrs()
  attrs.each((key, value) => {
    if key.has_prefix(sub_alias_attr_prefix) {
      let alias_name = if value != "" {
        value
      } else {
        key[sub_alias_attr_prefix.length():].to_owned()
      }
      add_unique_text(aliases, alias_name)
    }
  })
  sorted_texts(aliases)
}

///|
pub fn Term::has_sub_alias(self : Term[Sub], alias_name : String) -> Bool {
  self.sub_aliases().contains(alias_name)
}

///|
pub fn Term::sub_symbol_names(self : Term[Sub]) -> Array[String] {
  sorted_texts([self.sub_name()] + self.sub_aliases())
}

///|
fn stub_graph_add_node(
  graph : Map[String, Array[String]],
  name : String,
) -> Unit {
  if !graph.contains(name) {
    graph[name] = []
  }
}

///|
fn stub_graph_add_edge(
  graph : Map[String, Array[String]],
  left : String,
  right : String,
) -> Unit {
  stub_graph_add_node(graph, left)
  stub_graph_add_node(graph, right)
  let left_neighbors = match graph.get(left) {
    Some(items) => items.copy()
    None => []
  }
  add_unique_text(left_neighbors, right)
  graph[left] = left_neighbors
  let right_neighbors = match graph.get(right) {
    Some(items) => items.copy()
    None => []
  }
  add_unique_text(right_neighbors, left)
  graph[right] = right_neighbors
}

///|
fn stub_alias_graph(subs : Array[Term[Sub]]) -> Map[String, Array[String]] {
  let graph : Map[String, Array[String]] = {}
  for sub in subs {
    let name = sub.sub_name()
    stub_graph_add_node(graph, name)
    for alias_name in sub.sub_aliases() {
      stub_graph_add_edge(graph, name, alias_name)
    }
  }
  graph
}

///|
fn text_intersects(left : Array[String], right : Array[String]) -> Bool {
  left.any(item => right.contains(item))
}

///|
fn stub_should_link(
  sub : Term[Sub],
  link_only : Array[String],
  no_link : Array[String],
) -> Bool {
  let symbols = sub.sub_symbol_names()
  !text_intersects(symbols, no_link) &&
  (link_only.is_empty() || text_intersects(symbols, link_only))
}

///|
fn linkable_stub_subs(
  subs : Array[Term[Sub]],
  link_only : Array[String],
  no_link : Array[String],
) -> Array[Term[Sub]] {
  subs.filter(sub => stub_should_link(sub, link_only, no_link))
}

///|
fn stub_components(graph : Map[String, Array[String]]) -> Array[Array[String]] {
  let seen : Map[String, Bool] = {}
  let components = []
  graph.each((start, _) => {
    if !seen.contains(start) {
      let component = []
      let stack = [start]
      seen[start] = true
      while stack.length() > 0 {
        match stack.pop() {
          Some(name) => {
            component.push(name)
            match graph.get(name) {
              Some(neighbors) =>
                for next in neighbors {
                  if !seen.contains(next) {
                    seen[next] = true
                    stack.push(next)
                  }
                }
              None => ()
            }
          }
          None => ()
        }
      }
      components.push(sorted_texts(component))
    }
  })
  components
}

///|
fn component_contains_sub(component : Array[String], sub : Term[Sub]) -> Bool {
  component.contains(sub.sub_name())
}

///|
fn link_stub_component(
  links : Map[Tid, Tid],
  component : Array[String],
  subs : Array[Term[Sub]],
) -> Unit {
  let stubs = []
  let mut implementation : Term[Sub]? = None
  let mut ambiguous_impl = false
  for sub in subs {
    if component_contains_sub(component, sub) {
      if sub.is_stub() {
        stubs.push(sub)
      } else {
        match implementation {
          Some(_) => ambiguous_impl = true
          None => implementation = Some(sub)
        }
      }
    }
  }
  match implementation {
    Some(real) if !ambiguous_impl =>
      for stub in stubs {
        links[stub.tid()] = real.tid()
      }
    _ => ()
  }
}

///|
pub fn Term::program_stub_links(
  self : Term[Program],
  link_only? : Array[String],
  no_link? : Array[String],
) -> Map[Tid, Tid] {
  let subs = linkable_stub_subs(
    self.subs(),
    match link_only {
      Some(items) => items
      None => []
    },
    match no_link {
      Some(items) => items
      None => []
    },
  )
  let graph = stub_alias_graph(subs)
  let links : Map[Tid, Tid] = {}
  for component in stub_components(graph) {
    link_stub_component(links, component, subs)
  }
  links
}

///|
fn resolve_stub_label(label : Label, links : Map[Tid, Tid]) -> Label {
  match label {
    Direct(tid) =>
      match links.get(tid) {
        Some(real) => Direct(real)
        None => label
      }
    Indirect(_) => label
  }
}

///|
fn resolve_stub_call(call : Call, links : Map[Tid, Tid]) -> Call {
  {
    target: resolve_stub_label(call.target, links),
    return_label: match call.return_label {
      Some(label) => Some(resolve_stub_label(label, links))
      None => None
    },
  }
}

///|
fn resolve_stub_jmp_kind(kind : JmpKind, links : Map[Tid, Tid]) -> JmpKind {
  match kind {
    JmpCall(call) => JmpCall(resolve_stub_call(call, links))
    Goto(label) => Goto(resolve_stub_label(label, links))
    Ret(label) => Ret(resolve_stub_label(label, links))
    Interrupt(_, _) => kind
  }
}

///|
pub fn Term::program_resolve_stub_calls(
  self : Term[Program],
  link_only? : Array[String],
  no_link? : Array[String],
) -> Term[Program] {
  let links = self.program_stub_links(link_only?, no_link?)
  self.with_payload({
    subs: self
    .subs()
    .map(sub => {
      sub.with_payload({
        ..sub.payload_value,
        blks: sub
        .blks()
        .map(blk => {
          blk.with_payload({
            ..blk.payload_value,
            jmps: blk
            .jmps()
            .map(jmp => jmp.with_kind(resolve_stub_jmp_kind(jmp.kind(), links))),
          })
        }),
      })
    }),
  })
}

///|
pub fn Term::program_stub_tids(self : Term[Program]) -> Array[Tid] {
  let stubs = []
  for sub in self.subs() {
    if sub.is_stub() {
      add_unique_tid(stubs, sub.tid())
    }
  }
  stubs
}
