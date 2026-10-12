///|
/// The relocation information of a unit (upstream
/// `Bil_lifter.Relocations`): the internal relocations (fixup address to
/// the target address) and the external references (fixup address to the
/// name of the external symbol).
pub struct Relocations {
  priv rels : Map[UInt64, UInt64]
  priv exts : Map[UInt64, String]
}

///|
/// No relocations.
pub fn Relocations::empty() -> Relocations {
  { rels: Map([]), exts: Map([]), }
}

///|
/// Creates the relocation information from the lists of relocations and
/// external references.
pub fn Relocations::create(
  rels~ : ArrayView[(UInt64, UInt64)] = [],
  exts~ : ArrayView[(UInt64, String)] = [],
) -> Relocations {
  let r : Map[UInt64, UInt64] = Map([])
  for x in rels {
    r[x.0] = x.1
  }
  let e : Map[UInt64, String] = Map([])
  for x in exts {
    e[x.0] = x.1
  }
  { rels: r, exts: e, }
}

///|
/// The relocation information of an image (its relocations with known
/// targets and its external references).
pub fn Relocations::of_image(image : @image.Image) -> Relocations {
  let rels = []
  for r in image.relocations() {
    match r.target() {
      Some(t) => rels.push((r.fixup(), t))
      None => ()
    }
  }
  Relocations::create(
    rels~,
    exts=image.external_references().map(x => (x.addr(), x.name())),
  )
}

///|
fn const_addr(w : @types.Word) -> UInt64? {
  try w.to_uint64() catch {
    _ => None
  } noraise {
    x => Some(x)
  }
}

///|
/// The constant addresses loaded by the program (upstream
/// `reference_analyzer`): loads from constants, and from variables that
/// were assigned constants.
pub fn references(bil : ArrayView[@types.Stmt]) -> Array[UInt64] {
  let vars : Map[String, UInt64] = Map([])
  let refs : Array[UInt64] = []
  let add = (a : UInt64) => if !refs.contains(a) { refs.push(a) }
  fn exp(e : @types.Exp) -> Unit {
    match e {
      Load(mem~, addr~, ..) => {
        match addr {
          Int(w) =>
            match const_addr(w) {
              Some(a) => add(a)
              None => ()
            }
          Var(v) =>
            match vars.get(v.to_string()) {
              Some(a) => add(a)
              None => ()
            }
          _ => ()
        }
        exp(mem)
        exp(addr)
      }
      Int(_) | Var(_) | Unknown(_) => ()
      Store(mem~, addr~, value~, ..) => {
        exp(mem)
        exp(addr)
        exp(value)
      }
      Let(_, x, y) | BinOp(_, x, y) | Concat(high=x, low=y) => {
        exp(x)
        exp(y)
      }
      Cast(exp=x, ..) | Extract(exp=x, ..) | UnOp(_, x) => exp(x)
      Ite(cond~, yes~, no~) => {
        exp(cond)
        exp(yes)
        exp(no)
      }
    }
  }

  fn stmts(xs : ArrayView[@types.Stmt]) -> Unit {
    for s in xs {
      match s {
        Move(v, e) => {
          match e {
            Int(w) =>
              match const_addr(w) {
                Some(a) => vars[v.to_string()] = a
                None => ()
              }
            _ => ()
          }
          exp(e)
        }
        Jmp(e) => exp(e)
        Special(_) | CpuExn(_) => ()
        While(cond~, body~) => {
          exp(cond)
          stmts(body)
        }
        If(cond~, yes~, no~) => {
          exp(cond)
          stmts(yes)
          stmts(no)
        }
      }
    }
  }

  stmts(bil)
  refs.sort()
  refs
}

///|
/// Replaces every jump (at any depth) with the given statements.
pub fn map_jmps(
  bil : ArrayView[@types.Stmt],
  f : (@types.Exp) -> Array[@types.Stmt],
) -> Array[@types.Stmt] {
  let out = []
  for s in bil {
    match s {
      Jmp(e) => out.append(f(e))
      While(cond~, body~) => out.push(While(cond~, body=map_jmps(body, f)))
      If(cond~, yes~, no~) =>
        out.push(If(cond~, yes=map_jmps(yes, f), no=map_jmps(no, f)))
      s => out.push(s)
    }
  }
  out
}

///|
/// Redirects the jumps of an instruction that is affected by a relocation
/// (upstream `Relocations.fixup`). The candidate addresses are the
/// constant addresses loaded by the instruction, followed by the addresses
/// of its bytes; if one of them has an internal relocation, all jumps go to
/// its target; otherwise, if one has an external reference, all jumps
/// become calls to the external symbol (suffixed with `:external` in
/// stubs).
pub fn Relocations::fixup(
  self : Relocations,
  bil : ArrayView[@types.Stmt],
  addr~ : UInt64,
  size~ : Int32,
  width~ : Int32,
  is_stub~ : Bool = false,
) -> Array[@types.Stmt] {
  let addresses = references(bil)
  for i in 0..<size {
    addresses.push(addr + i.to_uint64())
  }
  for a in addresses {
    match self.rels.get(a) {
      Some(dst) => {
        let dst = @types.Word::of_uint64(width~, dst) catch {
          _ => return bil.to_owned()
        }
        return map_jmps(bil, _ => [Jmp(Int(dst))])
      }
      None => ()
    }
  }
  for a in addresses {
    match self.exts.get(a) {
      Some(name) => {
        let name = if is_stub { name + ":external" } else { name }
        return map_jmps(bil, _ => {
          [@types.Stmt::encode(@types.Stmt::call(), name)]
        })
      }
      None => ()
    }
  }
  bil.to_owned()
}
