// Resolution of the x86 sub-register variables of lifted BIL onto the full
// registers, as upstream's x86 lifters emit them (`x86_tools_reg.ml`
// `RR.get`/`RR.set`): a sub-register read extracts bits of the full
// register; a 32-bit write in 64-bit mode zero-extends into the full
// register (Intel SDM 3.4.1.1) and the other writes merge into it.
//
// Upstream's `Core.desugar` (`bap_core_theory_pass.ml`, `set`/`assign_sub`)
// merges every sub-register write, 32-bit ones included, with the aliases
// of `x86_target.ml` (`lo_bits_of main are M32.main`), so it relies on the
// lifters writing the full registers; lifters that emit sub-register
// variables (the project's Basic lifter, the Primus Lisp semantics) are
// resolved with this pass instead.

///|
/// The x86 sub-registers of the `bits`-bit mode (32 or 64): name -> (full
/// register, full register width, lo, hi).
fn x86_subregister_table(
  bits : Int32,
) -> Map[String, (String, Int32, Int32, Int32)] {
  let table : Map[String, (String, Int32, Int32, Int32)] = Map([])
  let names : Array[(String, String, String, String)] = [
    ("AX", "AL", "AH", "A"),
    ("CX", "CL", "CH", "C"),
    ("DX", "DL", "DH", "D"),
    ("BX", "BL", "BH", "B"),
    ("SP", "SPL", "", "SP"),
    ("BP", "BPL", "", "BP"),
    ("SI", "SIL", "", "SI"),
    ("DI", "DIL", "", "DI"),
  ]
  let full = (i : Int32) => {
    if i < 8 {
      let stem = names[i].3
      let stem = if stem.length() == 1 { stem + "X" } else { stem }
      if bits == 64 {
        "R" + stem
      } else {
        "E" + stem
      }
    } else {
      "R\{i}"
    }
  }
  let count = if bits == 64 { 16 } else { 8 }
  for i in 0..<count {
    let base = full(i)
    if i < 8 {
      let (w, b, h, _) = names[i]
      if bits == 64 {
        table["E" + w] = (base, 64, 0, 31)
      }
      table[w] = (base, bits, 0, 15)
      if bits == 64 || i < 4 {
        table[b] = (base, bits, 0, 7)
      }
      if h != "" {
        table[h] = (base, bits, 8, 15)
      }
    } else {
      table["R\{i}D"] = (base, 64, 0, 31)
      table["R\{i}W"] = (base, 64, 0, 15)
      table["R\{i}B"] = (base, 64, 0, 7)
      table["R\{i}L"] = (base, 64, 0, 7)
    }
    table["XMM\{i}"] = ("YMM\{i}", 256, 0, 127)
  }
  table
}

///|
let x86_subregister_tables : Map[
  Int32,
  Map[String, (String, Int32, Int32, Int32)],
] = Map([])

///|
fn x86_subregisters(bits : Int32) -> Map[String, (String, Int32, Int32, Int32)] {
  match x86_subregister_tables.get(bits) {
    Some(t) => t
    None => {
      let t = x86_subregister_table(bits)
      x86_subregister_tables[bits] = t
      t
    }
  }
}

///|
fn x86_imm_width(v : @types.Var) -> Int32 {
  match v.typ {
    Imm(w) => w
    Mem(..) => 0
  }
}

///|
/// The part `hi..lo` of the full register `base`.
fn x86_register_part(
  base : @types.Var,
  width : Int32,
  lo : Int32,
  hi : Int32,
) -> @types.Exp {
  if lo == 0 {
    Cast(kind=Low, width=hi + 1, exp=Var(base))
  } else if hi == width - 1 {
    Cast(kind=High, width=width - lo, exp=Var(base))
  } else {
    Extract(hi~, lo~, exp=Var(base))
  }
}

///|
/// `pad:64[e]`, folded for constants.
fn x86_zero_extend(e : @types.Exp) -> @types.Exp {
  match e {
    Int(w) =>
      try @types.Word::of_uint64(width=64, w.to_uint64()) catch {
        _ => Cast(kind=Unsigned, width=64, exp=e)
      } noraise {
        x => Int(x)
      }
    _ => Cast(kind=Unsigned, width=64, exp=e)
  }
}

///|
fn x86_resolve_exp(
  table : Map[String, (String, Int32, Int32, Int32)],
  e : @types.Exp,
) -> @types.Exp {
  let n = x => x86_resolve_exp(table, x)
  match e {
    Var(v) =>
      match table.get(v.name) {
        Some((base, width, lo, hi)) if x86_imm_width(v) == hi - lo + 1 =>
          x86_register_part(@types.Var::create(base, Imm(width)), width, lo, hi)
        _ => e
      }
    Int(_) | Unknown(_) => e
    Load(mem~, addr~, endian~, typ~) =>
      Load(mem=n(mem), addr=n(addr), endian~, typ~)
    Store(mem~, addr~, value~, endian~) =>
      Store(mem=n(mem), addr=n(addr), value=n(value), endian~)
    Let(v, x, y) => Let(v, n(x), n(y))
    Cast(kind~, width~, exp~) => Cast(kind~, width~, exp=n(exp))
    Extract(hi~, lo~, exp~) => Extract(hi~, lo~, exp=n(exp))
    Concat(high~, low~) => Concat(high=n(high), low=n(low))
    UnOp(op, x) => UnOp(op, n(x))
    BinOp(op, x, y) => BinOp(op, n(x), n(y))
    Ite(cond~, yes~, no~) => Ite(cond=n(cond), yes=n(yes), no=n(no))
  }
}

///|
fn x86_resolve_stmts(
  bits : Int32,
  table : Map[String, (String, Int32, Int32, Int32)],
  stmts : Array[@types.Stmt],
) -> Array[@types.Stmt] {
  let n = x => x86_resolve_exp(table, x)
  stmts.map(s => {
    match s {
      Move(v, e) =>
        match table.get(v.name) {
          Some((base, width, lo, hi)) if x86_imm_width(v) == hi - lo + 1 => {
            let bv = @types.Var::create(base, Imm(width))
            let e = n(e)
            if bits == 64 && lo == 0 && hi == 31 && width == 64 {
              Move(bv, x86_zero_extend(e))
            } else {
              let mut value = e
              if lo > 0 {
                value = Concat(
                  high=value,
                  low=x86_register_part(bv, width, 0, lo - 1),
                )
              }
              if hi < width - 1 {
                value = Concat(
                  high=x86_register_part(bv, width, hi + 1, width - 1),
                  low=value,
                )
              }
              Move(bv, value)
            }
          }
          _ => Move(v, n(e))
        }
      Jmp(e) => Jmp(n(e))
      If(cond~, yes~, no~) =>
        If(
          cond=n(cond),
          yes=x86_resolve_stmts(bits, table, yes),
          no=x86_resolve_stmts(bits, table, no),
        )
      While(cond~, body~) =>
        While(cond=n(cond), body=x86_resolve_stmts(bits, table, body))
      s => s
    }
  })
}

///|
/// Rewrites the x86 sub-register variables (`EAX`, `AX`, `AL`, `AH`,
/// `R8D`, `XMM0`, ...) of `stmts` onto the full registers of the `bits`-bit
/// mode (`RAX`/`EAX`, `R8`, `YMM0`, ...): reads become extractions of the
/// full register, 32-bit general purpose register writes in 64-bit mode
/// zero-extend the value and the other writes merge it into the full
/// register (upstream `RR.get`/`RR.set`). Variables of other widths are
/// left alone.
///
/// ```mbt check
/// test {
///   let eax = @types.Var::create("EAX", Imm(32))
///   let ebx = @types.Var::create("EBX", Imm(32))
///   let bil : Array[@types.Stmt] = [Move(eax, Var(ebx))]
///   inspect(
///     @mc.resolve_x86_subregisters(bil, bits=64)[0].to_string(),
///     content="RAX:imm64 := pad:64[low:32[RBX:imm64]]",
///   )
/// }
/// ```
pub fn resolve_x86_subregisters(
  stmts : Array[@types.Stmt],
  bits~ : Int32,
) -> Array[@types.Stmt] {
  x86_resolve_stmts(bits, x86_subregisters(bits), stmts)
}
