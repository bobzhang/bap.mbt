// Port of `plugins/thumb/thumb_mem.ml`: loads, stores and multi-register
// transfers.

///|
fn ldri(
  rd : @types.Var,
  r : @types.Var,
  i : Int,
  cnd : Cond,
) -> Array[@types.Stmt] {
  set_if(rd, load(R32, add(v(r), const_(i))), cnd)
}

///|
fn ldrr(
  rd : @types.Var,
  rn : @types.Var,
  rm : @types.Var,
  cnd : Cond,
) -> Array[@types.Stmt] {
  set_if(rd, load(R32, add(v(rn), v(rm))), cnd)
}

///|
fn ldrbi(
  rd : @types.Var,
  rn : @types.Var,
  i : Int,
  cnd : Cond,
) -> Array[@types.Stmt] {
  set_if(rd, unsigned32(load(R8, add(v(rn), const_(i)))), cnd)
}

///|
fn ldrbr(
  rd : @types.Var,
  rn : @types.Var,
  rm : @types.Var,
  cnd : Cond,
) -> Array[@types.Stmt] {
  set_if(rd, unsigned32(load(R8, add(v(rn), v(rm)))), cnd)
}

///|
fn ldrsb(
  rd : @types.Var,
  rn : @types.Var,
  rm : @types.Var,
  cnd : Cond,
) -> Array[@types.Stmt] {
  set_if(rd, signed32(load(R8, add(v(rn), v(rm)))), cnd)
}

///|
fn ldrhi(
  rd : @types.Var,
  rn : @types.Var,
  i : Int,
  cnd : Cond,
) -> Array[@types.Stmt] {
  set_if(rd, unsigned32(load(R16, add(v(rn), const_(i)))), cnd)
}

///|
fn ldrhr(
  rd : @types.Var,
  rn : @types.Var,
  rm : @types.Var,
  cnd : Cond,
) -> Array[@types.Stmt] {
  set_if(rd, unsigned32(load(R16, add(v(rn), v(rm)))), cnd)
}

///|
fn ldrsh(
  rd : @types.Var,
  rn : @types.Var,
  rm : @types.Var,
  cnd : Cond,
) -> Array[@types.Stmt] {
  set_if(rd, signed32(load(R16, add(v(rn), v(rm)))), cnd)
}

///|
/// Literal-pool load: `rd := mem[(pc & ~3) + off]` where `pc` is the
/// instruction address plus 4.
fn ldrpci(
  rd : @types.Var,
  pc : Int,
  off : Int,
  cnd : Cond,
) -> Array[@types.Stmt] {
  set_if(rd, load(R32, add(const_(pc & (3).lnot()), const_(off))), cnd)
}

///|
fn ldm(
  b : @types.Var,
  regs : Array[@types.Var],
  cnd : Cond,
) -> Array[@types.Stmt] {
  let body = []
  for i, r in regs {
    body.push(set(r, load(R32, add(v(b), const_(i * 4)))))
  }
  body.push(set_add(b, const_(regs.length() * 4)))
  branch(cnd, body, [])
}

///|
fn stri(
  rd : @types.Var,
  rm : @types.Var,
  i : Int,
  cnd : Cond,
) -> Array[@types.Stmt] {
  store_if(add(v(rm), const_(i)), v(rd), cnd)
}

///|
fn strr(
  rd : @types.Var,
  rm : @types.Var,
  rn : @types.Var,
  cnd : Cond,
) -> Array[@types.Stmt] {
  store_if(add(v(rm), v(rn)), v(rd), cnd)
}

///|
fn strhi(
  rd : @types.Var,
  rm : @types.Var,
  i : Int,
  cnd : Cond,
) -> Array[@types.Stmt] {
  store_if(add(v(rm), const_(i)), low(16, v(rd)), cnd)
}

///|
fn strhr(
  rd : @types.Var,
  rm : @types.Var,
  rn : @types.Var,
  cnd : Cond,
) -> Array[@types.Stmt] {
  store_if(add(v(rm), v(rn)), low(16, v(rd)), cnd)
}

///|
fn strbi(
  rd : @types.Var,
  rm : @types.Var,
  i : Int,
  cnd : Cond,
) -> Array[@types.Stmt] {
  store_if(add(v(rm), const_(i)), low(8, v(rd)), cnd)
}

///|
fn strbr(
  rd : @types.Var,
  rm : @types.Var,
  rn : @types.Var,
  cnd : Cond,
) -> Array[@types.Stmt] {
  store_if(add(v(rm), v(rn)), low(8, v(rd)), cnd)
}

///|
fn stm(
  b : @types.Var,
  regs : Array[@types.Var],
  cnd : Cond,
) -> Array[@types.Stmt] {
  let body = []
  for i, r in regs {
    body.push(store(add(v(b), const_(i * 4)), v(r)))
  }
  body.push(set_add(b, const_(regs.length() * 4)))
  branch(cnd, body, [])
}

///|
fn pop(regs : Array[@types.Var], cnd : Cond) -> Array[@types.Stmt] {
  ldm(sp, regs, cnd)
}

///|
/// `pop {..., pc}`: load the non-pc registers, bump `SP`, then jump to the
/// word at the updated `SP`.
fn popret(regs : Array[@types.Var], cnd : Cond) -> Array[@types.Stmt] {
  let body = []
  for i, r in regs {
    body.push(set(r, load(R32, add(v(sp), const_(i * 4)))))
  }
  body.push(set_add(sp, const_(regs.length() * 4)))
  body.push(Jmp(load(R32, v(sp))))
  match cnd {
    AL => body
    _ => [If(cond=holds(cnd), yes=body, no=[])]
  }
}

///|
fn push(regs : Array[@types.Var], cnd : Cond) -> Array[@types.Stmt] {
  let body = [set_sub(sp, const_(regs.length() * 4))]
  for i, r in regs {
    body.push(store(add(v(sp), const_(i * 4)), v(r)))
  }
  branch(cnd, body, [])
}
