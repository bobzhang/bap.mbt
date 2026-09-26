// Port of `plugins/thumb/thumb_branch.ml`.
//
// Upstream's `blxi`/`bxi` additionally attach the destination label's
// encoding (`llvm-thumb` when bit 0 of the target is set, `llvm-armv7`
// otherwise) to the instruction's `dests` slot. That is knowledge-base
// metadata with no BIL counterpart; `dest_encoding` exposes the same
// decision so callers can record it.

///|
/// Thumb interworking mask (`0xffff_fffe`).
let mask : Int = 0xfffffffe

///|
/// Encoding name of an interworking branch destination: `llvm-thumb` when
/// bit 0 of the target address is set, `llvm-armv7` otherwise (upstream
/// `Thumb_branch.make_dests`).
pub fn dest_encoding(dst : UInt64) -> String {
  if (dst & 1UL) == 1UL {
    "llvm-thumb"
  } else {
    "llvm-armv7"
  }
}

///|
fn b(pc : Int, dst : Int) -> Array[@types.Stmt] {
  [goto(pc_offset(pc, dst))]
}

///|
fn bcc(pc : Int, cnd : Cond, dst : Int) -> Array[@types.Stmt] {
  match cnd {
    AL => b(pc, dst)
    cnd => [If(cond=holds(cnd), yes=[goto(pc_offset(pc, dst))], no=[])]
  }
}

///|
/// `next pc`: the value stored to `LR` (`pc + 4`).
fn next(pc : Int) -> @types.Exp {
  const_(pc_offset(pc, 0))
}

///|
fn bli(pc : Int, dst : Int) -> Array[@types.Stmt] {
  [set(lr, next(pc)), goto(pc_offset(pc, dst) & mask)]
}

///|
fn bxr(dst : @types.Var) -> Array[@types.Stmt] {
  [Jmp(logand(v(dst), const_(mask)))]
}

///|
fn bxi(pc : Int, off : Int) -> Array[@types.Stmt] {
  [goto(pc_offset(pc, off) & mask)]
}

///|
fn blr(pc : Int, dst : @types.Var) -> Array[@types.Stmt] {
  [set(lr, next(pc)), Jmp(logand(v(dst), const_(mask)))]
}

///|
fn blxr(pc : Int, dst : @types.Var) -> Array[@types.Stmt] {
  blr(pc, dst)
}

///|
fn cbnz(pc : Int, rn : @types.Var, dst : Int) -> Array[@types.Stmt] {
  [If(cond=lnot(is_zero(v(rn))), yes=[goto(pc_offset(pc, dst))], no=[])]
}

///|
fn cbz(pc : Int, rn : @types.Var, dst : Int) -> Array[@types.Stmt] {
  [If(cond=is_zero(v(rn)), yes=[goto(pc_offset(pc, dst))], no=[])]
}

///|
/// `goto (Label.for_name "arm:unpredictable")`: a named label without an
/// address lowers to a BIL `call` special.
fn unpredictable() -> Array[@types.Stmt] {
  [@types.Stmt::encode(@types.Stmt::call(), "arm:unpredictable")]
}
