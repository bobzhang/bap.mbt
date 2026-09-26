// Port of BAP `plugins/x86/x86_lifter.ml` (part 3): arithmetic, logic,
// shifts, rotates and bit operations.

///|
fn Ctx::to_ir_arith(
  self : Ctx,
  op : Opcode,
) -> Array[@types.Stmt] raise X86Error {
  match op {
    Add(t, o1, o2) => {
      let tmp = new_tmp(t)
      let tmp2 = new_tmp(t)
      cat([
        [
          assign(tmp, self.op2e(t, o1)),
          assign(tmp2, self.op2e(t, o2)),
          self.assn(t, o1, e_plus(self.op2e(t, o1), ev(tmp2))),
        ],
        set_flags_add(t, ev(tmp), ev(tmp2), self.op2e(t, o1)),
      ])
    }
    Adc(t, o1, o2) => {
      let orig1 = new_tmp(t)
      let orig2 = new_tmp(t)
      let bits = t
      let c = (e : @types.Exp) => e_unsigned(bits + 1, e)
      // Literally compute the addition with an extra bit and see what the
      // value is for CF
      let s1 = ev(orig1)
      let s2 = ev(orig2)
      let r = self.op2e(t, o1)
      let bige = e_plus(e_plus(c(s1), c(s2)), c(e_unsigned(t, ev(cf))))
      cat([
        [
          assign(orig1, self.op2e(t, o1)),
          assign(orig2, self.op2e(t, o2)),
          self.assn(t, o1, e_plus(e_plus(s1, s2), e_unsigned(t, ev(cf)))),
          assign(cf, e_extract(bits, bits, bige)),
        ],
        set_aopszf_add(t, s1, s2, r),
      ])
    }
    Inc(t, o) => {
      let tmp = new_tmp(t)
      cat([
        [
          assign(tmp, self.op2e(t, o)),
          self.assn(t, o, e_plus(self.op2e(t, o), int_exp(1, t))),
        ],
        set_aopszf_add(t, ev(tmp), int_exp(1, t), self.op2e(t, o)),
      ])
    }
    Dec(t, o) => {
      let tmp = new_tmp(t)
      cat([
        [
          assign(tmp, self.op2e(t, o)),
          self.assn(t, o, e_minus(self.op2e(t, o), int_exp(1, t))),
        ],
        // CF is maintained
        set_aopszf_sub(t, ev(tmp), int_exp(1, t), self.op2e(t, o)),
      ])
    }
    Sub(t, o1, o2) => {
      let oldo1 = new_tmp(t)
      let oldo2 = new_tmp(t)
      let op1 = self.op2e(t, o1)
      let op2 = self.src_operand(o2, t)
      cat([
        [
          assign(oldo1, op1),
          assign(oldo2, op2),
          self.assn(t, o1, e_minus(op1, op2)),
        ],
        set_flags_sub(t, ev(oldo1), ev(oldo2), op1),
      ])
    }
    Sbb(t, o1, o2) => {
      let tmp_s = new_tmp(t)
      let tmp_d = new_tmp(t)
      let orig_s = ev(tmp_s)
      let orig_d = ev(tmp_d)
      let sube = e_plus(orig_s, e_unsigned(t, ev(cf)))
      let d = self.op2e(t, o1)
      let s1 = self.src_operand(o2, t)
      cat([
        [
          assign(tmp_s, s1),
          assign(tmp_d, d),
          self.assn(t, o1, e_minus(orig_d, sube)),
          assign(of_, e_high(1, e_and(e_xor(orig_s, orig_d), e_xor(orig_d, d)))),
          // sub overflow | add overflow
          assign(cf, e_or(e_gt(sube, orig_d), e_lt(sube, orig_s))),
        ],
        set_apszf(t, orig_s, orig_d, d),
      ])
    }
    Cmp(t, o1, o2) => {
      let tmp = new_tmp(t)
      cat([
        [assign(tmp, e_minus(self.op2e(t, o1), self.op2e(t, o2)))],
        set_flags_sub(t, self.op2e(t, o1), self.op2e(t, o2), ev(tmp)),
      ])
    }
    Cmpxchg(t, src, dst) => {
      let eax_e = self.op2e(t, o_rax)
      let dst_e = self.op2e(t, dst)
      let src_e = self.op2e(t, src)
      let tmp = new_tmp(t)
      cat([
        [assign(tmp, e_minus(eax_e, dst_e))],
        set_flags_sub(t, eax_e, dst_e, ev(tmp)),
        // port: the accumulator is only written when the comparison
        // fails (upstream writes it back unconditionally, which clears the
        // upper half of RAX in 64-bit mode); the destination is written in
        // both cases (Intel SDM CMPXCHG)
        [
          if_(ev(zf), [self.assn(t, dst, src_e)], [
            assign(tmp, dst_e),
            self.assn(t, o_rax, ev(tmp)),
            self.assn(t, dst, ev(tmp)),
          ]),
        ],
      ])
    }
    Cmpxchg8b(t, o) => {
      // port: EDX:EAX <- m64 loads the low half into EAX (upstream swaps the
      // halves) and is only written when the comparison fails; with REX.W
      // this is CMPXCHG16B over RDX:RAX and RCX:RBX (Intel SDM)
      let h = t / 2
      let accumulator = e_concat(self.op2e(h, o_rdx), self.op2e(h, o_rax))
      let dst = new_tmp(t, name="dst")
      let dst_e = ev(dst)
      let src_e = e_concat(self.op2e(h, o_rcx), self.op2e(h, o_rbx))
      let equal = new_tmp(1)
      let equal_v = ev(equal)
      [
        assign(dst, self.op2e(t, o)),
        assign(equal, e_eq(accumulator, dst_e)),
        assign(zf, equal_v),
        self.assn(t, o, e_ite(equal_v, src_e, dst_e)),
        if_(equal_v, [], [
          self.assn(h, o_rax, e_extract(h - 1, 0, dst_e)),
          self.assn(h, o_rdx, e_extract(t - 1, h, dst_e)),
        ]),
      ]
    }
    Xadd(t, src_op, dst_op) => {
      // port: the decoder passes (reg, r/m); the sum goes to the r/m
      // operand and its old value to the register (upstream swaps them)
      let tmp_res = new_tmp(t)
      let tmp_dst = new_tmp(t)
      let tmp_src = new_tmp(t)
      // a memory destination is stored first, as its address may depend
      // on the register; a register destination is written last (it wins
      // when both operands are the same register)
      let writes = match dst_op {
        Oaddr(_) =>
          [self.assn(t, dst_op, ev(tmp_res)), self.assn(t, src_op, ev(tmp_dst))]
        _ =>
          [self.assn(t, src_op, ev(tmp_dst)), self.assn(t, dst_op, ev(tmp_res))]
      }
      cat([
        [
          assign(tmp_src, self.op2e(t, src_op)),
          assign(tmp_dst, self.op2e(t, dst_op)),
          assign(tmp_res, e_plus(ev(tmp_dst), ev(tmp_src))),
        ],
        writes,
        set_flags_add(t, ev(tmp_dst), ev(tmp_src), ev(tmp_res)),
      ])
    }
    Xchg(t, src, dst) => {
      let tmp = new_tmp(t)
      [
        assign(tmp, self.op2e(t, src)),
        self.assn(t, src, self.op2e(t, dst)),
        self.assn(t, dst, ev(tmp)),
      ]
    }
    And(t, o1, o2) =>
      cat([
        [
          self.assn(t, o1, e_and(self.op2e(t, o1), self.op2e(t, o2))),
          assign(of_, exp_false),
          assign(cf, exp_false),
          assign(af, e_unknown("AF is undefined after and", 1)),
        ],
        set_pszf(t, self.op2e(t, o1)),
      ])
    Or(t, o1, o2) => {
      let o2 = self.src_operand(o2, t)
      cat([
        [
          self.assn(t, o1, e_or(self.op2e(t, o1), o2)),
          assign(of_, exp_false),
          assign(cf, exp_false),
          assign(af, e_unknown("AF is undefined after or", 1)),
        ],
        set_pszf(t, self.op2e(t, o1)),
      ])
    }
    Xor(t, o1, o2) if o1 == o2 =>
      [
        self.assn(t, o1, int_exp(0, t)),
        assign(af, e_unknown("AF is undefined after xor", 1)),
        assign(zf, exp_true),
        assign(pf, exp_true),
        assign(of_, exp_false),
        assign(cf, exp_false),
        assign(sf, exp_false),
      ]
    Xor(t, o1, o2) =>
      cat([
        [
          self.assn(t, o1, e_xor(self.op2e(t, o1), self.op2e(t, o2))),
          assign(of_, exp_false),
          assign(cf, exp_false),
          assign(af, e_unknown("AF is undefined after xor", 1)),
        ],
        set_pszf(t, self.op2e(t, o1)),
      ])
    Test(t, o1, o2) => {
      let o2 = self.src_operand(o2, t)
      let tmp = new_tmp(t)
      cat([
        [
          assign(tmp, e_and(self.op2e(t, o1), o2)),
          assign(of_, exp_false),
          assign(cf, exp_false),
          assign(af, e_unknown("AF is undefined after and", 1)),
        ],
        set_pszf(t, ev(tmp)),
      ])
    }
    Ptest(t, o1, o2) => {
      let tmp1 = new_tmp(t)
      let tmp2 = new_tmp(t)
      [
        assign(tmp1, e_and(self.op2e(t, o2), self.op2e(t, o1))),
        assign(tmp2, e_and(self.op2e(t, o2), e_not(self.op2e(t, o1)))),
        assign(af, exp_false),
        assign(of_, exp_false),
        assign(pf, exp_false),
        assign(sf, exp_false),
        assign(zf, e_eq(ev(tmp1), int_exp(0, t))),
        assign(cf, e_eq(ev(tmp2), int_exp(0, t))),
      ]
    }
    Not(t, o) => [self.assn(t, o, e_not(self.op2e(t, o)))]
    Neg(t, o) => {
      let tmp = new_tmp(t)
      let min_int = e_lsl(int_exp(1, t), int_exp(t - 1, t))
      cat([
        [
          assign(tmp, self.op2e(t, o)),
          self.assn(t, o, e_minus(int_exp(0, t), self.op2e(t, o))),
          assign(
            cf,
            e_ite(e_eq(ev(tmp), int_exp(0, t)), int_exp(0, 1), int_exp(1, 1)),
          ),
          assign(
            of_,
            e_ite(e_eq(ev(tmp), min_int), int_exp(1, 1), int_exp(0, 1)),
          ),
        ],
        set_apszf(t, ev(tmp), int_exp(0, t), self.op2e(t, o)),
      ])
    }
    Mul(t, src) => {
      // Mul always multiplies EAX by src and stores the result in EDX:EAX
      // starting from the "right hand side" based on the type t of src.
      // The OF and CF flags are set to 0 if the upper half of the result is
      // 0; otherwise, they are set to 1
      let new_t = t * 2
      let (assnstmts, assne) = self.assn_dbl(
        t,
        e_times(
          e_unsigned(new_t, self.op2e(t, o_rax)),
          e_unsigned(new_t, self.op2e(t, src)),
        ),
      )
      let flag = e_neq(e_extract(new_t - 1, new_t / 2, assne), int_exp(0, t))
      cat([
        assnstmts,
        [
          assign(of_, flag),
          assign(cf, flag),
          assign(sf, e_unknown("SF is undefined after Mul", 1)),
          assign(zf, e_unknown("ZF is undefined after Mul", 1)),
          assign(af, e_unknown("AF is undefined after Mul", 1)),
          assign(pf, e_unknown("PF is undefined after Mul", 1)),
        ],
      ])
    }
    Imul(t, (oneopform, dst), src1, src2) => {
      let new_t = t * 2
      let mul_stmts = if oneopform {
        // For one operand form, use assn_double
        let (assnstmts, assne) = self.assn_dbl(
          t,
          e_times(
            e_signed(new_t, self.op2e(t, src1)),
            e_signed(new_t, self.op2e(t, src2)),
          ),
        )
        // port: CF/OF are set when the product is not the sign extension
        // of its low half (upstream: when the upper half is not zero)
        let flag = e_neq(assne, e_signed(new_t, e_low(t, assne)))
        cat([assnstmts, [assign(of_, flag), assign(cf, flag)]])
      } else {
        // Two and three operand forms
        let tmp = new_tmp(new_t)
        // Flag is set when the result is truncated
        let flag = e_neq(ev(tmp), e_signed(new_t, self.op2e(t, dst)))
        [
          assign(
            tmp,
            e_times(
              e_signed(new_t, self.op2e(t, src1)),
              e_signed(new_t, self.op2e(t, src2)),
            ),
          ),
          self.assn(t, dst, e_low(t, ev(tmp))),
          assign(of_, flag),
          assign(cf, flag),
        ]
      }
      cat([
        mul_stmts,
        [
          assign(pf, e_unknown("PF is undefined after imul", 1)),
          assign(sf, e_unknown("SF is undefined after imul", 1)),
          assign(zf, e_unknown("ZF is undefined after imul", 1)),
          assign(af, e_unknown("AF is undefined after imul", 1)),
        ],
      ])
    }
    Div(t, src) => self.div(t, src, false)
    Idiv(t, src) => self.div(t, src, true)
    Cld => [assign(df, exp_false)]
    _ => self.to_ir_simd(op)
  }
}

///|
/// Upstream `Div` and `Idiv`.
fn Ctx::div(
  self : Ctx,
  t : Int,
  src : Operand,
  signed : Bool,
) -> Array[@types.Stmt] raise X86Error {
  let dt = t * 2
  let zero = int_exp(0, dt)
  let dividend = new_tmp(dt, name="dividend")
  let divisor = new_tmp(dt, name="divisor")
  let tdiv = new_tmp(dt, name="div")
  let trem = new_tmp(dt, name="rem")
  let result = e_concat(e_low(t, ev(trem)), e_low(t, ev(tdiv)))
  let apply_result = self.assn_dbl(t, result).0
  let body = if signed {
    // port: #DE when the quotient is not the sign extension of its low
    // half (upstream checks the range of the double-width type)
    [
      assign(tdiv, bop(SignedDiv, ev(dividend), ev(divisor))),
      assign(trem, bop(SignedMod, ev(dividend), ev(divisor))),
      if_(
        e_neq(ev(tdiv), e_signed(dt, e_low(t, ev(tdiv)))),
        [divide_by_zero],
        apply_result,
      ),
    ]
  } else {
    [
      assign(tdiv, bop(Div, ev(dividend), ev(divisor))),
      assign(trem, bop(Mod, ev(dividend), ev(divisor))),
      if_(e_eq(e_high(t, ev(tdiv)), int_exp(0, t)), apply_result, [
        divide_by_zero,
      ]),
    ]
  }
  let divisor_e = if signed {
    e_signed(dt, self.op2e(t, src))
  } else {
    e_unsigned(dt, self.op2e(t, src))
  }
  cat([
    [
      assign(divisor, divisor_e),
      assign(dividend, self.op2e_dbl(t)),
      if_(e_eq(ev(divisor), zero), [divide_by_zero], body),
    ],
    undefine([cf, of_, sf, zf, af, pf]),
  ])
}

///|
/// Upstream `Shift`.
fn Ctx::shift(
  self : Ctx,
  st : @types.BinOp,
  s : Int,
  dst : Operand,
  shift : Operand,
) -> Array[@types.Stmt] raise X86Error {
  let old = new_tmp(s, name="tmp")
  let size = int_exp(s, s)
  let dste = self.op2e(s, dst)
  // port: the count is masked to 5 bits (6 for 64-bit operands), so 8- and
  // 16-bit operands can be shifted by more than their width (upstream
  // masks to the width)
  let count = e_and(self.op2e(s, shift), count_mask(s))
  let new_of = match st {
    LShift => e_xor(e_high(1, dste), ev(cf))
    RShift => e_high(1, ev(old))
    ARShift => exp_false
    _ => raise ArchException("invalid shift type")
  }
  // undefined for SHL and SHR instructions where the count is greater than
  // or equal to the size (in bits) of the destination operand
  let new_cf = match st {
    LShift => e_low(1, e_lsr(ev(old), e_minus(size, count)))
    // the last bit shifted out; a copy of the sign for SAR by more than
    // the width
    _ => e_low(1, bop(st, ev(old), e_minus(count, int_exp(1, s))))
  }
  [
    assign(old, dste),
    self.assn(s, dst, bop(st, dste, count)),
    if_(
      e_neq(count, int_exp(0, s)),
      [
        assign(cf, new_cf),
        assign(sf, compute_sf(dste)),
        assign(zf, compute_zf(s, dste)),
        assign(pf, compute_pf(s, dste)),
        assign(af, e_unknown("after-shift", 1)),
        if_(e_eq(count, int_exp(1, s)), [assign(of_, new_of)], [
          assign(of_, e_unknown("after-shift", 1)),
        ]),
      ],
      [],
    ),
  ]
}

///|
/// Upstream `Shiftd` (SHLD/SHRD).
fn Ctx::shiftd(
  self : Ctx,
  st : @types.BinOp,
  s : Int,
  dst : Operand,
  fill : Operand,
  count : Operand,
) -> Array[@types.Stmt] raise X86Error {
  let was = new_tmp(s, name="tmp")
  let e_dst = self.op2e(s, dst)
  let e_fill = self.op2e(s, fill)
  // Check for 64-bit operand
  let size = int_exp(s, s)
  // port: the count is masked to 5 bits (6 for 64-bit operands)
  let e_count = e_and(self.op2e(s, count), count_mask(s))
  let (new_cf, ret1, ret2) = match st {
    LShift =>
      (
        e_low(1, e_lsr(ev(was), e_minus(size, e_count))),
        e_lsr(e_fill, e_minus(size, e_count)),
        e_lsl(e_dst, e_count),
      )
    RShift =>
      (
        e_high(1, e_lsl(ev(was), e_minus(size, e_count))),
        e_lsl(e_fill, e_minus(size, e_count)),
        e_lsr(e_dst, e_count),
      )
    _ => raise ArchException("impossible")
  }
  let new_of = e_high(1, e_xor(ev(was), e_dst))
  let unk_of = e_unknown("OF undefined after shiftd of more then 1 bit", 1)
  let result = e_or(ret1, ret2)
  // SWXXX If shift is greater than the operand size, dst and flags are
  // undefined
  [
    assign(was, e_dst),
    self.assn(s, dst, result),
    if_(
      e_neq(e_count, int_exp(0, s)),
      [
        assign(cf, new_cf),
        assign(sf, compute_sf(e_dst)),
        assign(zf, compute_zf(s, e_dst)),
        assign(pf, compute_pf(s, e_dst)),
        // For a 1-bit shift, the OF flag is set if a sign change occurred;
        // otherwise, it is cleared. For shifts greater than 1 bit, the OF
        // flag is undefined.
        if_(e_eq(e_count, int_exp(1, s)), [assign(of_, new_of)], [
          assign(of_, unk_of),
        ]),
      ],
      [],
    ),
  ]
}

///|
/// The count mask of shifts and rotates: 5 bits, 6 bits for 64-bit
/// operands (Intel SDM SAL/SAR/SHL/SHR, ROL/ROR).
fn count_mask(size : Int) -> @types.Exp {
  int_exp(if size == 64 { 0x3f } else { 0x1f }, size)
}

///|
/// Upstream `Rotate` (ROL/ROR; RCL/RCR are not implemented upstream).
///
/// port: the operand is rotated by the masked count modulo the width, CF
/// is the bit rotated into the least (ROL) or most (ROR) significant bit
/// whenever the masked count is not zero and OF is defined for a masked
/// count of 1 (upstream only assigns CF for a zero count and computes OF
/// from the stale CF).
fn Ctx::rotate(
  self : Ctx,
  shift_type : @types.BinOp,
  word_size : Int,
  dst_op : Operand,
  shift_op : Operand,
  use_cf : Bool,
) -> Array[@types.Stmt] raise X86Error {
  if use_cf {
    raise NoSemantics("rotate use_vf")
  }
  let masked_var = new_tmp(word_size, name="masked")
  let masked = ev(masked_var)
  let count_var = new_tmp(word_size)
  let count = ev(count_var)
  let zero = int_exp(0, word_size)
  let one = int_exp(1, word_size)
  let dst = self.op2e(word_size, dst_op)
  let size = int_exp(word_size, word_size)
  let shift = self.op2e(word_size, shift_op)
  let unk = e_unknown("OF undefined after rotate of more then 1 bit", 1)
  let left = shift_type == LShift
  let rotated = if left {
    e_or(e_lsl(dst, count), e_lsr(dst, e_minus(size, count)))
  } else {
    e_or(e_lsr(dst, count), e_lsl(dst, e_minus(size, count)))
  }
  // `dst` reads the rotated value after the assignment
  let (new_cf, new_of) = if left {
    (e_low(1, dst), e_xor(e_high(1, dst), e_low(1, dst)))
  } else {
    (
      e_high(1, dst),
      e_xor(e_high(1, dst), e_extract(word_size - 2, word_size - 2, dst)),
    )
  }
  [
    assign(masked_var, e_and(shift, count_mask(word_size))),
    assign(count_var, bop(Mod, masked, size)),
    self.assn(word_size, dst_op, rotated),
    if_(
      e_neq(masked, zero),
      [
        assign(cf, new_cf),
        if_(e_eq(masked, one), [assign(of_, new_of)], [assign(of_, unk)]),
      ],
      [],
    ),
  ]
}

///|
/// Upstream `Bt`, extended to BTS/BTR/BTC (`kind` 5, 6 and 7), which
/// complement, reset or set the selected bit.
fn Ctx::bt(
  self : Ctx,
  kind : Int,
  t : Int,
  bitoffset : Operand,
  bitbase : Operand,
) -> Array[@types.Stmt] raise X86Error {
  let offset = self.op2e(t, bitoffset)
  let (value, shift, width, addr) = match bitbase {
    Oreg(_) => {
      let reg = self.op2e(t, bitbase)
      (reg, e_and(offset, int_exp(t - 1, t)), t, None)
    }
    Oaddr(a) => {
      // port: an immediate offset is taken modulo the operand size and a
      // register offset is signed (upstream zero-extends both)
      let aw = self.mode.width()
      let offset = match bitoffset {
        Oimm(_) => e_unsigned(aw, e_and(offset, int_exp(t - 1, t)))
        _ => e_signed(aw, offset)
      }
      let byte_addr = e_plus(a, bop(ARShift, offset, int_exp(3, aw)))
      let byte = self.load(8, byte_addr)
      (byte, e_and(e_low(8, offset), int_exp(7, 8)), 8, Some(byte_addr))
    }
    _ => raise ArchException("Invalid bt operand")
  }
  let selected = new_tmp(width, name="bits")
  let mask = e_lsl(int_exp(1, width), e_unsigned(width, shift))
  let updated = match kind {
    5 => Some(e_or(ev(selected), mask))
    6 => Some(e_and(ev(selected), e_not(mask)))
    7 => Some(e_xor(ev(selected), mask))
    _ => None
  }
  let write = match (updated, addr) {
    (None, _) => []
    (Some(v), None) => [self.assn(t, bitbase, v)]
    (Some(v), Some(a)) => [self.store(8, a, v)]
  }
  cat([
    [
      assign(selected, value),
      assign(cf, e_low(1, e_lsr(ev(selected), shift))),
      assign(of_, e_unknown("OF undefined after bt", 1)),
      assign(sf, e_unknown("SF undefined after bt", 1)),
      assign(af, e_unknown("AF undefined after bt", 1)),
      assign(pf, e_unknown("PF undefined after bt", 1)),
    ],
    write,
  ])
}

///|
/// Upstream `Bs` (BSF/BSR, and TZCNT/LZCNT with the F3 prefix).
fn Ctx::bs(
  self : Ctx,
  t : Int,
  dst : Operand,
  src : Operand,
  dir : Direction,
) -> Array[@types.Stmt] raise X86Error {
  let is_zero_count = self.pref.contains(0xf3)
  let width = t
  let src_e = self.op2e(t, src)
  let is_fwd = dir == Forward
  let res = new_tmp(t)
  let assn_res = assign(res, src_e)
  guard width is (16 | 32 | 64) else {
    raise ArchException("Invalid bitscan width")
  }
  let scan_bil = if is_fwd { ctz(res, width) } else { clz(res, width) }
  let assn_result = self.assn(
    t,
    dst,
    if is_zero_count || is_fwd {
      ev(res)
    } else {
      e_xor(ev(res), int_exp(width - 1, width))
    },
  )
  let bil = cat([[assn_res], scan_bil])
  let bil = if is_zero_count {
    cat([
      bil,
      [
        assn_result,
        assign(cf, e_eq(ev(res), int_exp(width, width))),
        assign(zf, e_eq(ev(res), int_exp(0, width))),
      ],
    ])
  } else {
    [
      if_(
        e_eq(src_e, int_exp(0, width)),
        [assign(zf, int_exp(1, 1)), self.assn(t, dst, e_unknown("bits", t))],
        cat([bil, [assn_result, assign(zf, int_exp(0, 1))]]),
      ),
    ]
  }
  cat([bil, bitscan_flags(is_zero_count)])
}
