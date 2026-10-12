// Port of BAP `plugins/x86/x86_lifter.ml` (part 1): operand reads and
// writes, flag helpers and bit-counting sequences.

///|
/// The lifting context of one instruction (the arguments of upstream
/// `to_ir`): the mode, the segment base selected by prefixes, the remaining
/// prefixes and whether a REX or VEX prefix is present.
priv struct Ctx {
  mode : Mode
  ss : @types.Var?
  pref : Array[Int32]
  has_rex : Bool
  has_vex : Bool
}

///|
fn Ctx::vars(self : Ctx) -> ModeVars {
  vars_of_mode(self.mode)
}

///|
/// Upstream `load` (`load_s mode ss`).
fn Ctx::load(
  self : Ctx,
  t : Int32,
  a : @types.Exp,
) -> @types.Exp raise X86Error {
  load_s(self.mode, self.ss, t, a)
}

///|
/// Upstream `store` (`store_s mode ss`).
fn Ctx::store(
  self : Ctx,
  t : Int32,
  a : @types.Exp,
  e : @types.Exp,
) -> @types.Stmt raise X86Error {
  store_s(self.mode, self.ss, t, a, e)
}

///|
/// Upstream `op2e_s`: read an operand of type `t`.
fn Ctx::op2e(
  self : Ctx,
  t : Int32,
  operand : Operand,
) -> @types.Exp raise X86Error {
  let mode = self.mode
  match operand {
    Ovec(r) =>
      match t {
        256 => ev(bits2ymm(mode, r))
        128 | 64 | 32 => e_low(t, ev(bits2ymm(mode, r)))
        _ => raise ArchException("invalid SIMD register size for op2e: \{t}")
      }
    Oreg(r) =>
      match t {
        64 => bits2reg64e(mode, r)
        32 => bits2reg32e(mode, r)
        16 => bits2reg16e(mode, r)
        8 => bits2reg8e(mode, r, has_rex=self.has_rex)
        _ => raise NoSemantics("unknown register")
      }
    Oseg(r) =>
      match t {
        64 => e_unsigned(64, ev(bits2segreg(r)))
        16 => ev(bits2segreg(r))
        _ => raise ArchException("Segment register when t is not r16")
      }
    Oaddr(e) => self.load(t, e)
    Oimm(i) => i.to_exp(t)
  }
}

///|
/// Upstream `assn_s`: assign `e` to an operand of type `t`, preserving the
/// bits of the register that are not written.
fn Ctx::assn(
  self : Ctx,
  t : Int32,
  v : Operand,
  e : @types.Exp,
) -> @types.Stmt raise X86Error {
  let mode = self.mode
  match (v, t) {
    // Zero-extend 128-bit assignments to 256-bit ymms.
    (Ovec(r), 128 | 64 | 32) if self.has_vex =>
      sub_assn(256, bits2ymm(mode, r), e_unsigned(256, e))
    (Ovec(r), 256 | 128 | 64 | 32) => sub_assn(t, bits2ymm(mode, r), e)
    (Ovec(_), _) =>
      raise ArchException("invalid SIMD register size for assignment")
    // Zero-extend 32-bit assignments to 64-bit registers.
    (Oreg(r), 32) if mode == X8664 =>
      sub_assn(64, bits2genreg(mode, r), e_unsigned(64, e))
    (Oreg(r), 64 | 32 | 16) => sub_assn(t, bits2genreg(mode, r), e)
    (Oreg(r), 8) if r < 4 || (mode == X8664 && self.has_rex) =>
      sub_assn(t, bits2genreg(mode, r), e)
    (Oreg(r), 8) => sub_assn(t, bits2genreg(mode, r & 3), e, off=8)
    (Oreg(_), _) => raise NoSemantics("assignment to sub registers")
    (Oseg(r), 16) => assign(bits2segreg(r), e)
    (Oseg(_), _) =>
      raise ArchException("Can't assign to non 16 bit segment register")
    (Oaddr(a), _) => self.store(t, a, e)
    (Oimm(_), _) =>
      raise ArchException("disasm x86: Can't assign to an immediate value")
  }
}

///|
/// Assign to `t` bits of `v`, starting at bit `off`, preserving the other
/// bits (upstream `sub_assn`).
fn sub_assn(
  t : Int32,
  v : @types.Var,
  e : @types.Exp,
  off~ : Int32 = 0,
) -> @types.Stmt {
  let bits = match v.typ {
    Imm(n) => n
    Mem(..) => 0
  }
  let mut result = e
  // the lower preserved bits, if any
  let lbh = off - 1
  if lbh > 0 {
    result = e_concat(result, e_extract(lbh, 0, ev(v)))
  }
  // the upper preserved bits, if any
  let ubh = bits - 1
  let ubl = t + off
  if ubh > ubl {
    result = e_concat(e_extract(ubh, ubl, ev(v)), result)
  }
  assign(v, result)
}

///|
/// Upstream `op_dbl`: the double-width operands of multiplication and
/// division.
fn op_dbl(t : Int32) -> Array[(Int32, Operand)] raise X86Error {
  match t {
    8 => [(16, o_rax)]
    16 => [(16, o_rdx), (16, o_rax)]
    32 => [(32, o_rdx), (32, o_rax)]
    64 => [(64, o_rdx), (64, o_rax)]
    _ => raise ArchException("op_dbl only defined for Reg 8, 16, 32, and 64")
  }
}

///|
/// Upstream `op2e_dbl_s`: the double-width operand (e.g. `EDX:EAX`).
fn Ctx::op2e_dbl(self : Ctx, t : Int32) -> @types.Exp raise X86Error {
  let exps : Array[@types.Exp] = []
  for item in op_dbl(t) {
    exps.push(self.op2e(item.0, item.1))
  }
  concat_explist(exps)
}

///|
/// Upstream `assn_dbl_s`: assign a double-width value, returning the
/// statements and an expression holding the value.
fn Ctx::assn_dbl(
  self : Ctx,
  t : Int32,
  e : @types.Exp,
) -> (Array[@types.Stmt], @types.Exp) raise X86Error {
  match op_dbl(t) {
    [(ct, o)] => ([self.assn(ct, o, e)], self.op2e(ct, o))
    l => {
      let tmp = new_tmp(t * 2)
      let stmts = [assign(tmp, e)]
      let mut off = 0
      for k = l.length() - 1; k >= 0; k = k - 1 {
        let (ct, o) = l[k]
        let newoff = off + ct
        stmts.push(self.assn(ct, o, e_extract(newoff - 1, off, ev(tmp))))
        off = newoff
      }
      (stmts, ev(tmp))
    }
  }
}

///|
/// Upstream `compute_jump_target`.
fn Ctx::jump_target(
  self : Ctx,
  target : JumpTarget,
) -> @types.Exp raise X86Error {
  match target {
    Jabs(o) => self.op2e(self.mode.width(), o)
    Jrel(na, offset) => e_plus(na.to_exp(na.width), offset.to_exp(offset.width))
  }
}

///|
/// Upstream `string_incr`.
fn string_incr(mode : Mode, t : Int32, v : @types.Var) -> @types.Stmt {
  if t == 8 {
    assign(v, e_plus(ev(v), df_to_offset(mode, ev(df))))
  } else {
    assign(
      v,
      e_plus(
        ev(v),
        e_times(df_to_offset(mode, ev(df)), int_exp(t / 8, mode.width())),
      ),
    )
  }
}

///|
/// Upstream `rep_wrap`: repeat `stmts` while RCX is not zero (and, for
/// `check_zf`, while ZF has the expected value).
fn rep_wrap(
  mode : Mode,
  stmts : Array[@types.Stmt],
  check_zf? : Int32,
) -> Array[@types.Stmt] raise X86Error {
  let w = mode.width()
  let rcx = vars_of_mode(mode).rcx
  let flag = new_tmp(1)
  let cond = e_and(e_neq(ev(rcx), int_exp(0, w)), ev(flag))
  let head = assign(flag, int_exp(1, 1))
  let tail = [assign(rcx, e_minus(ev(rcx), int_exp(1, w)))]
  match check_zf {
    None => ()
    Some(x) if x == repz => tail.push(assign(flag, ev(zf)))
    Some(x) if x == repnz => tail.push(assign(flag, e_not(ev(zf))))
    Some(_) => raise ArchException("invalid value for ?check_zf")
  }
  let body = stmts.copy()
  body.push_iter(tail.iter())
  [head, While(cond~, body~)]
}

///|
fn compute_sf(result : @types.Exp) -> @types.Exp {
  e_high(1, result)
}

///|
fn compute_zf(t : Int32, result : @types.Exp) -> @types.Exp {
  e_eq(int_exp(0, t), result)
}

///|
/// Upstream `compute_pf`: the parity of the low byte of `r`.
fn compute_pf(t : Int32, r : @types.Exp) -> @types.Exp {
  let acc = new_tmp(t)
  let var_acc = ev(acc)
  e_not(
    e_low(
      1,
      Let(
        acc,
        e_xor(e_lsr(r, int_exp(4, t)), r),
        Let(
          acc,
          e_xor(e_lsr(var_acc, int_exp(2, t)), var_acc),
          e_xor(e_lsr(var_acc, int_exp(1, t)), var_acc),
        ),
      ),
    ),
  )
}

///|
fn set_sf(r : @types.Exp) -> @types.Stmt {
  assign(sf, compute_sf(r))
}

///|
fn set_zf(t : Int32, r : @types.Exp) -> @types.Stmt {
  assign(zf, compute_zf(t, r))
}

///|
fn set_pf(t : Int32, r : @types.Exp) -> @types.Stmt {
  assign(pf, compute_pf(t, r))
}

///|
fn set_pszf(t : Int32, r : @types.Exp) -> Array[@types.Stmt] {
  [set_pf(t, r), set_sf(r), set_zf(t, r)]
}

///|
/// Upstream `set_apszf`: AF is `r_4 xor op1_4 xor op2_4`.
fn set_apszf(
  t : Int32,
  s1 : @types.Exp,
  s2 : @types.Exp,
  r : @types.Exp,
) -> Array[@types.Stmt] {
  let bit4 = int_exp(1 << 4, t)
  let stmts = [assign(af, e_eq(bit4, e_and(bit4, e_xor(e_xor(r, s1), s2))))]
  stmts.push_iter(set_pszf(t, r).iter())
  stmts
}

///|
fn set_aopszf_add(
  t : Int32,
  s1 : @types.Exp,
  s2 : @types.Exp,
  r : @types.Exp,
) -> Array[@types.Stmt] {
  let s1_high = e_high(1, s1)
  let s2_high = e_high(1, s2)
  let r_high = e_high(1, r)
  let stmts = [
    assign(of_, e_and(e_eq(s1_high, s2_high), e_xor(s1_high, r_high))),
  ]
  stmts.push_iter(set_apszf(t, s1, s2, r).iter())
  stmts
}

///|
fn set_flags_add(
  t : Int32,
  s1 : @types.Exp,
  s2 : @types.Exp,
  r : @types.Exp,
) -> Array[@types.Stmt] {
  let stmts = [assign(cf, e_lt(r, s1))]
  stmts.push_iter(set_aopszf_add(t, s1, s2, r).iter())
  stmts
}

///|
fn set_aopszf_sub(
  t : Int32,
  s1 : @types.Exp,
  s2 : @types.Exp,
  r : @types.Exp,
) -> Array[@types.Stmt] {
  let stmts = [assign(of_, e_high(1, e_and(e_xor(s1, s2), e_xor(s1, r))))]
  stmts.push_iter(set_apszf(t, s1, s2, r).iter())
  stmts
}

///|
fn set_flags_sub(
  t : Int32,
  s1 : @types.Exp,
  s2 : @types.Exp,
  r : @types.Exp,
) -> Array[@types.Stmt] {
  let stmts = [assign(cf, e_gt(s2, s1))]
  stmts.push_iter(set_aopszf_sub(t, s1, s2, r).iter())
  stmts
}

///|
/// Upstream `popcount`: the population count of `x`, in place.
fn popcount(x : @types.Var, width : Int32) -> Array[@types.Stmt] {
  let (sh, m1, m2, m4, h01) : (Int32, UInt64, UInt64, UInt64, UInt64) = match
    width {
    16 => (8, 0x5555, 0x3333, 0x0f0f, 0x0101)
    32 => (24, 0x55555555, 0x33333333, 0x0f0f0f0f, 0x01010101)
    _ =>
      (
        56, 0x5555555555555555, 0x3333333333333333, 0x0f0f0f0f0f0f0f0f, 0x0101010101010101,
      )
  }
  let i = (n : UInt64) => uint64_exp(n, width)
  let vx = ev(x)
  [
    assign(x, e_minus(vx, e_and(e_lsr(vx, i(1)), i(m1)))),
    assign(x, e_plus(e_and(vx, i(m2)), e_and(e_lsr(vx, i(2)), i(m2)))),
    assign(x, e_and(e_plus(vx, e_lsr(vx, i(4))), i(m4))),
    assign(x, e_lsr(e_times(vx, i(h01)), i(sh.to_uint64()))),
  ]
}

///|
/// Upstream `clz16`/`clz32`/`clz64`: count leading zeros of `x`, in place.
fn clz(x : @types.Var, width : Int32) -> Array[@types.Stmt] {
  let vx = ev(x)
  let stmts : Array[@types.Stmt] = []
  let mut s = 1
  while s < width {
    stmts.push(assign(x, e_or(vx, e_lsr(vx, int_exp(s, width)))))
    s = s * 2
  }
  stmts.push(assign(x, e_not(vx)))
  stmts.push_iter(popcount(x, width).iter())
  stmts
}

///|
/// Upstream `ctz16`/`ctz32`/`ctz64`: count trailing zeros of `x`, in place.
fn ctz(x : @types.Var, width : Int32) -> Array[@types.Stmt] {
  let vx = ev(x)
  let stmts = [assign(x, e_minus(e_and(vx, e_neg(vx)), int_exp(1, width)))]
  stmts.push_iter(popcount(x, width).iter())
  stmts
}

///|
fn bitscan_flags(is_zero_count : Bool) -> Array[@types.Stmt] {
  let l = [
    assign(of_, e_unknown("bits", 1)),
    assign(sf, e_unknown("bits", 1)),
    assign(af, e_unknown("bits", 1)),
    assign(pf, e_unknown("bits", 1)),
  ]
  if !is_zero_count {
    l.insert(0, assign(cf, e_unknown("bits", 1)))
  }
  l
}

///|
fn undefine(vars : Array[@types.Var]) -> Array[@types.Stmt] {
  vars.map(r => {
    let width = match r.typ {
      Imm(n) => n
      Mem(..) => 0
    }
    assign(r, e_unknown("#undefined", width))
  })
}
