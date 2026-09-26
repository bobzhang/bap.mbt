// BIL optimizations applied to the code shown by phoenix (upstream
// `Phoenix_helpers`).

///|
/// The context of a phoenix run: the project data that the printers and
/// the optimizations depend on.
struct Env {
  options : Options
  symtab : @project.ProjectDisassemblySymtab
  cfg : @project.ProjectDisassemblyCfg
  memory : @memory.MemMap[String]
  addr_bits : Int
}

///|
/// Creates the environment for a project. The symbol table and the CFG
/// default to the ones reconstructed from the project disassembly.
pub fn Env::new(
  project : @project.Project,
  options? : Options = Options::new(),
  symtab? : @project.ProjectDisassemblySymtab,
  cfg? : @project.ProjectDisassemblyCfg,
) -> Env {
  let bits = project.target().code_addr_size()
  {
    options,
    symtab: match symtab {
      Some(s) => s
      None => project.disassembly_symtab()
    },
    cfg: match cfg {
      Some(c) => c
      None => project.disassembly_cfg()
    },
    memory: project.memory(),
    addr_bits: if bits == 32 {
      32
    } else {
      64
    },
  }
}

///|
fn word_to_uint64(w : @types.Word) -> UInt64? {
  if w.bitwidth() > 64 {
    None
  } else {
    let v = w.to_uint64() catch { _ => return None }
    Some(v)
  }
}

///|
/// Maps addresses that belong to a function to `name` or `name + off`
/// (upstream `resolve_to_symbols`).
fn Env::resolve_to_symbols(
  self : Env,
  bil : Array[@types.Stmt],
) -> Array[@types.Stmt] {
  @types.map_exps(bil, e => {
    match e {
      Int(w) =>
        match word_to_uint64(w) {
          None => e
          Some(addr) =>
            match self.symtab.owners(addr) {
              [f, ..] => {
                let start = f.addr()
                let sym : @types.Exp = Var(
                  @types.Var::new(name=f.name(), typ=Imm(self.addr_bits)),
                )
                if start == addr {
                  sym
                } else {
                  let off = @types.Word::of_uint64(
                    width=w.bitwidth(),
                    addr - start,
                  ) catch {
                    _ => return e
                  }
                  BinOp(Plus, sym, Int(off))
                }
              }
              [] => e
            }
        }
      _ => e
    }
  })
}

///|
/// Substitutes loads from constant addresses with the contents of the
/// memory (upstream `resolve_indirects`).
fn Env::resolve_indirects(
  self : Env,
  bil : Array[@types.Stmt],
) -> Array[@types.Stmt] {
  @types.map_exps(bil, e => {
    match e {
      Load(addr=Int(w), typ=Imm(bits), ..) =>
        match word_to_uint64(w) {
          None => e
          Some(addr) =>
            match self.memory.lookup(addr) {
              [(mem, _), ..] =>
                match mem.get(addr~, scale=bits) {
                  Ok(value) => Int(value)
                  Err(_) => e
                }
              [] => e
            }
        }
      _ => e
    }
  })
}

///|
/// A conservative side-effect check of `e` in the scope `scope`.
fn has_side_effect(e : @types.Exp, scope : Array[@types.Stmt]) -> Bool {
  e.exists(x => {
    match x {
      Load(_) | Store(_) => true
      Var(v) => @types.is_assigned(scope, v)
      _ => false
    }
  })
}

///|
/// Inlines temporary variables whose definition is side-effect free or
/// is another variable that is not changed in the scope of the
/// definition (upstream `inline_variables`).
pub fn inline_variables(stmts : Array[@types.Stmt]) -> Array[@types.Stmt] {
  let result = []
  let mut xs = stmts
  while !xs.is_empty() {
    let s = xs[0]
    let rest = xs[1:].to_owned()
    match s {
      Move(_) if rest.is_empty() => {
        result.push(s)
        xs = rest
      }
      Move(x, Var(y)) if x.is_virtual() =>
        if @types.is_assigned(rest, y) || @types.is_assigned(rest, x) {
          result.push(s)
          xs = rest
        } else {
          xs = @types.substitute(rest, Var(x), Var(y))
        }
      Move(x, y) if x.is_virtual() =>
        if has_side_effect(y, rest) || @types.is_assigned(rest, x) {
          result.push(s)
          xs = rest
        } else {
          xs = @types.substitute(rest, Var(x), y)
        }
      _ => {
        result.push(s)
        xs = rest
      }
    }
  }
  result
}

///|
/// Optimizes the BIL of an instruction according to the options
/// (upstream `optimizations`).
pub fn Env::optimize(
  self : Env,
  bil : Array[@types.Stmt],
) -> Array[@types.Stmt] {
  let o = self.options
  if o.no_optimizations {
    return bil
  }
  let id = (b : Array[@types.Stmt]) => b
  let disable_if = (flag : Bool, f : (Array[@types.Stmt]) -> Array[@types.Stmt]) => {
    if flag {
      id
    } else {
      f
    }
  }
  // `List.reduce_exn ~f:Fn.compose` applies the last optimization first
  let passes = [
    disable_if(o.no_resolve, b => self.resolve_indirects(b)),
    disable_if(o.no_resolve, b => self.resolve_to_symbols(b)),
    // upstream calls `Bil.prune_unreferenced` with its defaults, which
    // prune nothing
    disable_if(o.keep_alive, b => @types.prune_unreferenced(b)),
    disable_if(o.keep_consts, @types.fold_consts),
    disable_if(o.keep_consts, @types.normalize_negatives),
    disable_if(o.no_inline, inline_variables),
  ].map(f => (b : Array[@types.Stmt]) => @types.fixpoint(b, f))
  let composed = (b : Array[@types.Stmt]) => {
    passes.rev_fold(init=b, (acc, f) => f(acc))
  }
  @types.fixpoint(bil, composed)
}

///|
fn insn_bil(
  insn : @project.ProjectDisassemblyInstruction,
) -> Array[@types.Stmt] {
  match insn.lift_basic_bil() {
    Ok(bil) => bil
    Err(_) => []
  }
}

///|
/// The optimized BIL of a block (upstream `bil_of_block`).
pub fn Env::bil_of_block(
  self : Env,
  blk : @project.ProjectDisassemblyBlock,
) -> Array[@types.Stmt] {
  let result = []
  for insn in blk.instructions() {
    result.append(self.optimize(insn_bil(insn)))
  }
  result
}
