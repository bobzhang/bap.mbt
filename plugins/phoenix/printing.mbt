// Code printers (upstream `Phoenix_printing`). The upstream printers use
// the tabulation boxes of `Format`, which the port's Format engine does
// not provide, so the tab stops are emulated from the known column at
// which the instruction lines start.

///|
/// The name of the block starting at `addr`: `<fn>_ENTRY`, `<fn>_<off>`,
/// or `text_<addr>` outside of functions (upstream `pp_blk_name`).
pub fn Env::block_name(self : Env, addr : UInt64) -> String {
  match self.symtab.owners(addr) {
    [f, ..] => {
      let off = addr - f.addr()
      if off == 0UL {
        "\{f.name()}_ENTRY"
      } else {
        "\{f.name()}_\{off.to_string(radix=16)}"
      }
    }
    [] => {
      let hex = addr.to_string(radix=16).to_upper()
      "text_" + (if addr >= 10UL { "0x" + hex } else { hex })
    }
  }
}

///|
/// The tab stops set by upstream `setup_tab_stops`.
let tab_stops : Array[Int] = [6, 31, 51]

///|
/// Emulates `pp_print_tab` at column `col`: returns the padding and the
/// new column.
fn tab(col : Int) -> (String, Int) {
  match tab_stops.iter().find_first(t => t >= col) {
    Some(t) => (String::make(t - col, ' '), t)
    None => ("\n" + String::make(tab_stops[0], ' '), tab_stops[0])
  }
}

///|
/// An instruction line: `<tab><memory><tab><insn>` (upstream
/// `pp_insn_line`). With `col`, the tabulation stops are emulated from
/// that starting column; without it (no tabulation box) tabs print
/// nothing.
fn insn_line(
  mem : @memory.Memory,
  insn : @project.ProjectDisassemblyInstruction,
  col? : Int,
) -> String {
  let mem_text = @print.memory_to_string(mem)
  let insn_text = @print.insn_to_string(insn, "pretty")
  match col {
    None => mem_text + insn_text
    Some(col) => {
      let (pad1, col) = tab(col)
      let (pad2, _) = tab(col + mem_text.length())
      pad1 + mem_text + pad2 + insn_text
    }
  }
}

///|
/// Prints the instructions of a block, each on its own line (upstream
/// `pp_insns`).
fn pp_insns(
  fmt : @text_tags.Formatter,
  blk : @project.ProjectDisassemblyBlock,
  col? : Int,
) -> Unit {
  for insn in blk.insns() {
    fmt.print_cut()
    fmt.print_string(insn_line(insn.0, insn.1, col?))
  }
}

///|
/// Prints BIL statements separated by cuts (upstream `pp_list Stmt.pp`).
fn pp_stmts(fmt : @text_tags.Formatter, bil : Array[@types.Stmt]) -> Unit {
  for i, s in bil {
    if i > 0 {
      fmt.print_cut()
    }
    @print.pp_stmt(fmt, s)
  }
}

///|
/// Prints a block in an anchored `pre` element (upstream `pp_blk`).
fn Env::pp_blk(
  self : Env,
  fmt : @text_tags.Formatter,
  blk : @project.ProjectDisassemblyBlock,
  pp : (@text_tags.Formatter, @project.ProjectDisassemblyBlock) -> Unit,
) -> Unit {
  fmt.open_tag("(a (id \{self.block_name(blk.addr())}))")
  fmt.open_tag("(pre (style \"margin : 0\"))")
  pp(fmt, blk)
  fmt.print_break(1, 0)
  fmt.close_tag()
  fmt.close_tag()
}

///|
/// The blocks of a function in the reverse postorder of its control flow
/// graph, starting from the entry (upstream
/// `Graphlib.reverse_postorder_traverse ~start:entry`).
pub fn Env::function_blocks(
  self : Env,
  f : @project.ProjectDisassemblyFunction,
) -> Array[@project.ProjectDisassemblyBlock] {
  let blocks = f.blocks()
  let by_addr : Map[UInt64, @project.ProjectDisassemblyBlock] = Map([])
  for b in blocks {
    by_addr[b.addr()] = b
  }
  let edges = []
  for b in blocks {
    for e in self.cfg.outputs(b) {
      let dst = e.dst().addr()
      if by_addr.contains(dst) {
        edges.push((b.addr(), dst, ()))
      }
    }
  }
  let graph : @graphlib.Graph[UInt64, Unit] = @graphlib.Graph::create(
    nodes=blocks.map(b => b.addr()),
    edges~,
  )
  graph
  .reverse_postorder_traverse(start=Some(f.entry().addr()))
  .map(addr => by_addr[addr])
}

///|
/// Prints a function as a `div` of its blocks (upstream `pp_sym`).
fn Env::pp_sym(
  self : Env,
  fmt : @text_tags.Formatter,
  f : @project.ProjectDisassemblyFunction,
  pp : (@text_tags.Formatter, @project.ProjectDisassemblyBlock) -> Unit,
) -> Unit {
  fmt.print_break(1, 0)
  fmt.open_vbox(2)
  fmt.open_tag("(div (id \{f.name()}))")
  for blk in self.function_blocks(f) {
    self.pp_blk(fmt, blk, pp)
  }
  fmt.close_tag()
  fmt.close_box()
}

///|
/// Prints a code page as an HTML document (upstream `pp_code`).
fn pp_code(fmt : @text_tags.Formatter, body : () -> Unit) -> Unit {
  fmt.print_cut()
  fmt.open_vbox(0)
  // the tabulation box and its stops (`setup_tab_stops`)
  fmt.print_as(6, "")
  fmt.print_as(25, "")
  fmt.print_as(20, "")
  fmt.print_break(1, 0)
  fmt.open_tag("html")
  fmt.open_tag("head")
  fmt.open_tag(
    "(link (rel stylesheet) (type css) (href ../../../css/code-panel.css))",
  )
  fmt.close_tag()
  fmt.close_tag()
  fmt.open_tag("body")
  body()
  fmt.print_break(1, 0)
  fmt.close_tag()
  fmt.close_tag()
  fmt.close_box()
  fmt.print_flush()
}

///|
/// Renders a page with the `html` text-tags mode installed (upstream
/// `Phoenix_root.with_file`).
fn html_page(pp : (@text_tags.Formatter) -> Unit) -> String {
  let fmt = @text_tags.Formatter::new()
  @text_tags.install(fmt, "html") catch {
    _ => ()
  }
  pp(fmt)
  fmt.flush_str()
}

///|
/// The BIL page of a function (upstream `store_asm`).
pub fn Env::bil_page(
  self : Env,
  f : @project.ProjectDisassemblyFunction,
) -> String {
  html_page(fmt => {
    pp_code(fmt, () => {
      self.pp_sym(fmt, f, (fmt, blk) => pp_stmts(fmt, self.bil_of_block(blk)))
    })
  })
}

///|
/// The column at which the instruction lines of the dump start: the
/// dump nests `html > body > pre > div > a > pre`, and every tag opens a
/// vertical box indented by one.
let dump_insn_column = 6

///|
/// The assembly dump of all functions (upstream `store_dump`).
pub fn Env::dump_page(self : Env) -> String {
  html_page(fmt => {
    pp_code(fmt, () => {
      fmt.open_tag("(pre (class \"prettyprint linenums\"))")
      for f in self.symtab.to_sequence() {
        self.pp_sym(fmt, f, (fmt, blk) => {
          pp_insns(fmt, blk, col=dump_insn_column)
        })
      }
      fmt.close_tag()
    })
  })
}
