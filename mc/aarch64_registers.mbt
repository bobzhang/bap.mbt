// Resolution of the AArch64 register aliases of lifted BIL onto the 64-bit
// general purpose registers `X0`..`X30` and `SP`.
//
// The AArch64 Primus Lisp semantics name registers by their operands and
// aliases: `W0`..`W30` (the low words of `X0`..`X30`), `WSP`, `FP` and `LR`
// (`X29` and `X30`), and the `R0`..`R31` base registers of
// `alias-base-register` (`setw`). Upstream resolves them with the aliasing
// of `arm_target.ml` in `Core.desugar`; like the x86 sub-registers
// (`resolve_x86_subregisters`), the port resolves them when lifting, so
// that the BIL of different instructions names the same register the same
// way: reads of 32-bit views are extractions and writes to them
// zero-extend into the 64-bit register (ARM ARM, `X[n] = ZeroExtend(...)`).

///|
/// The AArch64 register aliases: name -> (register, lo, hi).
let aarch64_alias_table : Map[String, (String, Int, Int)] = {
  let table : Map[String, (String, Int, Int)] = Map([])
  for i in 0..<31 {
    table["R\{i}"] = ("X\{i}", 0, 63)
    table["W\{i}"] = ("X\{i}", 0, 31)
  }
  table["R31"] = ("SP", 0, 63)
  table["WSP"] = ("SP", 0, 31)
  table["FP"] = ("X29", 0, 63)
  table["LR"] = ("X30", 0, 63)
  table
}

///|
fn aarch64_resolve_exp(e : @types.Exp) -> @types.Exp {
  let n = aarch64_resolve_exp
  match e {
    Var(v) =>
      match aarch64_alias_table.get(v.name) {
        Some((base, lo, hi)) if x86_imm_width(v) == hi - lo + 1 => {
          let bv = @types.Var::create(base, Imm(64))
          if hi == 63 {
            Var(bv)
          } else {
            Cast(kind=Low, width=hi + 1, exp=Var(bv))
          }
        }
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
/// Rewrites the AArch64 register aliases of `stmts` (`W0`..`W30`, `WSP`,
/// `FP`, `LR`, `R0`..`R31`) onto `X0`..`X30` and `SP`: reads of the 32-bit
/// views are the low words of the 64-bit registers, writes to them
/// zero-extend the value into the 64-bit register.
///
/// ```mbt check
/// test {
///   let w0 = @types.Var::create("W0", Imm(32))
///   let lr = @types.Var::create("LR", Imm(64))
///   let bil : Array[@types.Stmt] = [
///     Move(w0, Cast(kind=Low, width=32, exp=Var(lr))),
///   ]
///   inspect(
///     @mc.resolve_aarch64_registers(bil)[0].to_string(),
///     content="X0:imm64 := pad:64[low:32[X30:imm64]]",
///   )
/// }
/// ```
pub fn resolve_aarch64_registers(
  stmts : Array[@types.Stmt],
) -> Array[@types.Stmt] {
  let n = aarch64_resolve_exp
  stmts.map(s => {
    match s {
      Move(v, e) =>
        match aarch64_alias_table.get(v.name) {
          Some((base, lo, hi)) if x86_imm_width(v) == hi - lo + 1 => {
            let bv = @types.Var::create(base, Imm(64))
            if hi == 63 {
              Move(bv, n(e))
            } else {
              Move(bv, x86_zero_extend(n(e)))
            }
          }
          _ => Move(v, n(e))
        }
      Jmp(e) => Jmp(n(e))
      If(cond~, yes~, no~) =>
        If(
          cond=n(cond),
          yes=resolve_aarch64_registers(yes),
          no=resolve_aarch64_registers(no),
        )
      While(cond~, body~) =>
        While(cond=n(cond), body=resolve_aarch64_registers(body))
      s => s
    }
  })
}
