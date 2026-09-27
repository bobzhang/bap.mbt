// Port of `plugins/thumb/thumb_branch.ml`.
//
// Upstream's `blxi`/`bxi` additionally attach the destination label's
// encoding (`llvm-thumb` when bit 0 of the target is set, `llvm-armv7`
// otherwise) to the instruction's `dests` slot. That is knowledge-base
// metadata with no BIL counterpart; `dest_encoding` exposes the same
// decision, and the provider records it in `@mc.Lifted::dest_encoding`.

///|
/// Thumb interworking mask (`0xffff_fffe`).
let mask : Int = 0xfffffffe

///|
/// Encoding of an interworking branch destination: `llvm-thumb` when
/// bit 0 of the target address is set, `llvm-armv7` otherwise (upstream
/// `Thumb_branch.make_dests`).
pub fn dest_encoding(dst : UInt64) -> @core_theory.Language {
  if (dst & 1UL) == 1UL {
    @core_theory.Language::llvm_t32()
  } else {
    @core_theory.Language::llvm_a32()
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
fn bli(pc : Int, dst : Int) -> Array[@types.Stmt] {
  // port: the return address has bit 0 set (Thumb); upstream omits it
  [set(lr, const_(pc_offset(pc, 0) | 1)), goto(pc_offset(pc, dst) & mask)]
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
fn blxr(pc : Int, dst : @types.Var) -> Array[@types.Stmt] {
  // port: `blx rm` is a 16-bit instruction, it returns to `pc + 2` in
  // Thumb (bit 0 set); upstream links `pc + 4`
  [set(lr, const_((pc + 2) | 1)), Jmp(logand(v(dst), const_(mask)))]
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
