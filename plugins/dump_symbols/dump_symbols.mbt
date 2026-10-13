///|
/// The plugin name and the name of its project pass.
pub let name : String = "dump-symbols"

///|
let doc : String =
  #|dumps functions as a sexp-list of blocks
  #|
  #|Output symbol information. In the output file, each symbol is in format
  #|of `(<symbol name> <symbol start address> <symbol end address>)', e.g.,
  #|`(malloc 0x11034 0x11038)'

///|
fn needs_quotes(s : String) -> Bool {
  s.is_empty() ||
  s.contains("#|") ||
  s.contains("|#") ||
  s
  .iter()
  .any(c => {
    match c {
      ' ' | '\t' | '\n' | '\r' | '(' | ')' | '"' | ';' | '\\' => true
      _ => c.to_int() < 0x20 || c.to_int() >= 0x7f
    }
  })
}

///|
/// Renders a sexp atom, quoting it like `Sexp.to_string_hum` when needed.
pub fn sexp_atom(s : String) -> String {
  if !needs_quotes(s) {
    return s
  }
  let sb = StringBuilder()
  sb.write_char('"')
  for b in @utf8.encode(s) {
    match b {
      b'"' => sb.write_string("\\\"")
      b'\\' => sb.write_string("\\\\")
      b'\n' => sb.write_string("\\n")
      b'\t' => sb.write_string("\\t")
      b'\r' => sb.write_string("\\r")
      b'\b' => sb.write_string("\\b")
      _ =>
        if b < 0x20 || b >= 0x7f {
          let code = b.to_int()
          sb.write_string("\\")
          sb.write_string((code / 100).to_string())
          sb.write_string((code / 10 % 10).to_string())
          sb.write_string((code % 10).to_string())
        } else {
          sb.write_char(b.to_int().unsafe_to_char())
        }
    }
  }
  sb.write_char('"')
  sb.to_string()
}

///|
fn int64_text(addr : UInt64) -> String {
  addr.reinterpret_as_int64().to_string()
}

///|
/// Blocks of a function in reverse postorder starting from its entry; blocks
/// unreachable from the entry follow as further depth-first trees
/// (`Graphlib.reverse_postorder_traverse ~start:entry`).
fn reverse_postorder(
  function : @project.ProjectDisassemblyFunction,
  edges : Array[(UInt64, UInt64)],
) -> Array[@project.ProjectDisassemblyBlock] {
  let blocks = function.blocks()
  let entry = function.entry()
  let order : Array[@project.ProjectDisassemblyBlock] = [entry]
  for blk in blocks {
    if blk.addr() != entry.addr() {
      order.push(blk)
    }
  }
  let by_addr : Map[UInt64, @project.ProjectDisassemblyBlock] = Map([])
  for blk in order {
    by_addr[blk.addr()] = blk
  }
  let visited : Map[UInt64, Bool] = Map([])
  let post : Array[@project.ProjectDisassemblyBlock] = []
  fn visit(blk : @project.ProjectDisassemblyBlock) -> Unit {
    visited[blk.addr()] = true
    for edge in edges {
      if edge.0 == blk.addr() && !visited.contains(edge.1) {
        match by_addr.get(edge.1) {
          Some(dst) => visit(dst)
          None => ()
        }
      }
    }
    post.push(blk)
  }
  for blk in order {
    if !visited.contains(blk.addr()) {
      visit(blk)
    }
  }
  post.rev()
}

///|
/// Renders a symbol table as a list of `(name min-addr max-addr)` entries, one
/// per block of each function in reverse postorder.
pub fn render_symtab(
  symtab : @project.ProjectDisassemblySymtab,
  cfg : @project.ProjectDisassemblyCfg,
) -> String {
  let edges = cfg.edges().map(e => (e.src().addr(), e.dst().addr()))
  let sb = StringBuilder()
  for function in symtab.to_sequence() {
    let fname = sexp_atom(function.name())
    for blk in reverse_postorder(function, edges) {
      let mem = blk.memory()
      sb.write_string(
        "(\{fname} \{int64_text(mem.min_addr())} \{int64_text(mem.max_addr())})\n",
      )
    }
  }
  sb.to_string()
}

///|
/// Renders the project symbols (`output`).
pub fn dump(project : @project.Project) -> String {
  render_symtab(project.disassembly_symtab(), project.disassembly_cfg())
}

///|
/// Dumps the project symbols to `file`, or to `out` when no file is given
/// (`main`).
pub fn run(
  project : @project.Project,
  file? : String,
  out~ : (String) -> Unit = s => println(s.trim_end(chars="\n")),
) -> Result[Unit, String] {
  let text = dump(project)
  match file {
    Some(path) => @native_io.write_file(path, @utf8.encode(text))
    None => {
      if !text.is_empty() {
        out(text)
      }
      Ok(())
    }
  }
}

///|
/// Creates the (non-autorun) `dump-symbols` pass.
pub fn pass(file? : String, out? : (String) -> Unit) -> @project.ProjectPass {
  @project.ProjectPass::create(name~, run=project => {
    match run(project, file?, out?) {
      Ok(_) => Ok(project)
      Err(reason) => Err(reason)
    }
  })
}

///|
/// Registers the `dump-symbols` pass. Idempotent: returns `false` if the pass
/// was already registered.
pub fn register(
  file? : String,
  out? : (String) -> Unit,
) -> Result[Bool, String] {
  @project.register_pass_if_absent(pass(file?, out?))
}

///|
/// Declares the `dump-symbols` plugin to `bap_main` with its `file`
/// parameter. Does nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(name, provides=["printer", "pass"], doc~, () => {
    let file = @bap_main.Configuration::parameter(
      doc="Dump symbols to the specified FILE",
      @bap_main.Type::some(@bap_main.Type::string()),
      "file",
    )
    @bap_main.Extension::register(ctxt => {
      match register(file?=ctxt.get(file)) {
        Ok(_) => ()
        Err(reason) => fail(reason)
      }
    })
  })
}
