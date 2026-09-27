// Port of `plugins/thumb/thumb_mov.ml`: data-processing instructions.

///|
fn carry_from_add(r : @types.Exp, rn : @types.Exp) -> @types.Exp {
  ult(r, rn)
}

///|
fn overflow_from_add(
  r : @types.Exp,
  rn : @types.Exp,
  rm : @types.Exp,
) -> @types.Exp {
  msb(logand(logxor(rn, lnot(rm)), logxor(rn, r)))
}

///|
fn overflow_from_sub(
  r : @types.Exp,
  rn : @types.Exp,
  rm : @types.Exp,
) -> @types.Exp {
  msb(logand(logxor(rn, rm), logxor(rn, r)))
}

///|
fn borrow_from_sub(rn : @types.Exp, rm : @types.Exp) -> @types.Exp {
  ult(rn, rm)
}

///|
/// Flags of an addition whose result is held in `r`.
fn add_flags(
  r : @types.Var,
  rn : @types.Exp,
  rm : @types.Exp,
) -> Array[@types.Stmt] {
  [
    set(nf, msb(v(r))),
    set(zf, is_zero(v(r))),
    set(cf, carry_from_add(v(r), rn)),
    set(vf, overflow_from_add(v(r), rn, rm)),
  ]
}

///|
/// Flags of `x - y` whose result is held in `r` (upstream `cmp`).
fn cmp_flags(
  x : @types.Exp,
  y : @types.Exp,
  r : @types.Var,
) -> Array[@types.Stmt] {
  [
    set(nf, msb(v(r))),
    set(zf, is_zero(v(r))),
    set(cf, lnot(borrow_from_sub(x, y))),
    set(vf, overflow_from_sub(v(r), x, y)),
  ]
}

///|
/// Negative and zero flags of the value in `r`.
fn nz_flags(r : @types.Var) -> Array[@types.Stmt] {
  [set(nf, msb(v(r))), set(zf, is_zero(v(r)))]
}

///|
fn movi8(rd : @types.Var, x : Int64, cnd : Cond) -> Array[@types.Stmt] {
  // port: the result is an 8-bit constant, so N is clear (upstream tests
  // bit 7 of the immediate)
  it_set(
    rd,
    const_(x.to_int()),
    _ => [set(nf, bit0), set(zf, bool_const(x == 0L))],
    cnd,
  )
}

///|
fn movsr(rd : @types.Var, rn : @types.Var) -> Array[@types.Stmt] {
  [set(rd, v(rn)), set(nf, msb(v(rd))), set(zf, is_zero(v(rd)))]
}

///|
fn addi3(
  rd : @types.Var,
  rn : @types.Var,
  x : Int,
  cnd : Cond,
) -> Array[@types.Stmt] {
  it_set(rd, add(v(rn), const_(x)), r => add_flags(r, v(rn), const_(x)), cnd)
}

///|
fn addi8(rd : @types.Var, x : Int, cnd : Cond) -> Array[@types.Stmt] {
  it_set(rd, add(v(rd), const_(x)), r => add_flags(r, v(rd), const_(x)), cnd)
}

///|
fn addrr(
  rd : @types.Var,
  rn : @types.Var,
  rm : @types.Var,
  cnd : Cond,
) -> Array[@types.Stmt] {
  it_set(rd, add(v(rn), v(rm)), r => add_flags(r, v(rn), v(rm)), cnd)
}

///|
fn adcs(
  rd : @types.Var,
  rn : @types.Var,
  rm : @types.Var,
  cnd : Cond,
) -> Array[@types.Stmt] {
  // port: the carry out of `rn + rm + C` (upstream compares the result with
  // `rn`, which misses the carry when `rm + C` wraps)
  let carry = (r : @types.Var) => {
    msb(logor(logand(v(rn), v(rm)), logand(logor(v(rn), v(rm)), lnot(v(r)))))
  }
  it_set(
    rd,
    add(add(v(rn), v(rm)), unsigned32(v(cf))),
    r => {
      [
        set(nf, msb(v(r))),
        set(zf, is_zero(v(r))),
        set(cf, carry(r)),
        set(vf, overflow_from_add(v(r), v(rn), v(rm))),
      ]
    },
    cnd,
  )
}

///|
fn addspi(off : Int, cnd : Cond) -> Array[@types.Stmt] {
  set_if(sp, add(v(sp), const_(off)), cnd)
}

///|
fn addrspi(rd : @types.Var, off : Int, cnd : Cond) -> Array[@types.Stmt] {
  set_if(rd, add(v(sp), const_(off)), cnd)
}

///|
fn sub_(
  rd : @types.Var,
  x : @types.Exp,
  y : @types.Exp,
  cnd : Cond,
) -> Array[@types.Stmt] {
  it_set(rd, sub(x, y), r => cmp_flags(x, y, r), cnd)
}

///|
fn subi3(
  rd : @types.Var,
  rn : @types.Var,
  x : Int,
  cnd : Cond,
) -> Array[@types.Stmt] {
  sub_(rd, v(rn), const_(x), cnd)
}

///|
fn subi8(rd : @types.Var, x : Int, cnd : Cond) -> Array[@types.Stmt] {
  sub_(rd, v(rd), const_(x), cnd)
}

///|
fn subrr(
  rd : @types.Var,
  rn : @types.Var,
  rm : @types.Var,
  cnd : Cond,
) -> Array[@types.Stmt] {
  sub_(rd, v(rn), v(rm), cnd)
}

///|
/// Upstream also defines `subrspi` (`rd := SP - off`), but `Thumb_main`
/// never dispatches to it, so it is not ported.
fn subspi(off : Int, cnd : Cond) -> Array[@types.Stmt] {
  set_if(sp, sub(v(sp), const_(off)), cnd)
}

///|
fn asri(
  rd : @types.Var,
  rm : @types.Var,
  n : Int,
  cnd : Cond,
) -> Array[@types.Stmt] {
  match n {
    0 =>
      it_set(
        rd,
        ite(msb(v(rm)), const_(-1), const_(0)),
        r => [set(cf, msb(v(rm))), ..nz_flags(r)],
        cnd,
      )
    n =>
      it_set(
        rd,
        binop(ARShift, v(rm), const_(n)),
        r => [set(cf, nth(n - 1, v(rm))), ..nz_flags(r)],
        cnd,
      )
  }
}

///|
fn lsri(
  rd : @types.Var,
  rm : @types.Var,
  n : Int,
  cnd : Cond,
) -> Array[@types.Stmt] {
  match n {
    0 =>
      it_set(
        rd,
        const_(0),
        _ => [set(cf, msb(v(rm))), set(nf, bit0), set(zf, bit1)],
        cnd,
      )
    n =>
      it_set(
        rd,
        binop(RShift, v(rm), const_(n)),
        r => [set(cf, nth(n - 1, v(rm))), ..nz_flags(r)],
        cnd,
      )
  }
}

///|
fn lsli(
  rd : @types.Var,
  rm : @types.Var,
  n : Int,
  cnd : Cond,
) -> Array[@types.Stmt] {
  match n {
    0 => it_set(rd, v(rm), nz_flags, cnd)
    n =>
      it_set(
        rd,
        binop(LShift, v(rm), const_(n)),
        r => [set(cf, nth(32 - n, v(rm))), ..nz_flags(r)],
        cnd,
      )
  }
}

///|
fn lorr(rd : @types.Var, rm : @types.Var, cnd : Cond) -> Array[@types.Stmt] {
  it_set(rd, logor(v(rd), v(rm)), nz_flags, cnd)
}

///|
fn cmpi8(rd : @types.Var, x : Int, cnd : Cond) -> Array[@types.Stmt] {
  let r = fresh32()
  // port: comparisons in IT blocks are conditional (upstream ignores the
  // predicate)
  branch(
    cnd,
    [set(r, sub(v(rd), const_(x))), ..cmp_flags(v(rd), const_(x), r)],
    [],
  )
}

///|
fn cmpr(rn : @types.Var, rm : @types.Var, cnd : Cond) -> Array[@types.Stmt] {
  let r = fresh32()
  branch(cnd, [set(r, sub(v(rn), v(rm))), ..cmp_flags(v(rn), v(rm), r)], [])
}
