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
        [
          self.assn(t, dst, e_ite(ev(zf), src_e, dst_e)),
          self.assn(t, o_rax, e_ite(ev(zf), eax_e, dst_e)),
        ],
      ])
    }
    Cmpxchg8b(o) => {
      // only 32bit case
      let accumulator = e_concat(self.op2e(32, o_rdx), self.op2e(32, o_rax))
      let dst_e = self.op2e(64, o)
      let src_e = e_concat(self.op2e(32, o_rcx), self.op2e(32, o_rbx))
      let dst_low_e = e_extract(63, 32, dst_e)
      let dst_hi_e = e_extract(31, 0, dst_e)
      let eax_e = self.op2e(32, o_rax)
      let edx_e = self.op2e(32, o_rdx)
      let equal = new_tmp(1)
      let equal_v = ev(equal)
      [
        assign(equal, e_eq(accumulator, dst_e)),
        assign(zf, equal_v),
        self.assn(64, o, e_ite(equal_v, src_e, dst_e)),
        self.assn(32, o_rax, e_ite(equal_v, eax_e, dst_low_e)),
        self.assn(32, o_rdx, e_ite(equal_v, edx_e, dst_hi_e)),
      ]
    }
    Xadd(t, dst_op, src_op) => {
      let tmp_res = new_tmp(t)
      let tmp_dst = new_tmp(t)
      let tmp_src = new_tmp(t)
      let dst = self.op2e(t, dst_op)
      let src = self.op2e(t, src_op)
      cat([
        [
          assign(tmp_src, src),
          assign(tmp_dst, dst),
          assign(tmp_res, e_plus(src, dst)),
          self.assn(t, src_op, dst),
          self.assn(t, dst_op, ev(tmp_res)),
        ],
        set_flags_add(t, ev(tmp_dst), ev(tmp_src), dst),
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
        // Intel checks if EAX == EDX:EAX. Instead of doing this, we are
        // just going to check if the upper bits are != 0
        let flag = e_neq(e_extract(new_t - 1, new_t / 2, assne), int_exp(0, t))
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
    let min_bv = (try! @bitvec.one(width=dt)).lshift(dt - 1)
    let lbound : @types.Exp = Int(@types.Word::from_bitvec(min_bv))
    let ubound : @types.Exp = Int(@types.Word::from_bitvec(min_bv.pred()))
    [
      assign(tdiv, bop(SignedDiv, ev(dividend), ev(divisor))),
      assign(trem, bop(SignedMod, ev(dividend), ev(divisor))),
      if_(
        e_or(e_sgt(ev(tdiv), ubound), e_slt(ev(tdiv), lbound)),
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
  let count_mask = e_minus(size, int_exp(1, s))
  let count = e_and(self.op2e(s, shift), count_mask)
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
    _ => e_high(1, e_lsl(ev(old), e_minus(size, count)))
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
  let count_mask = e_minus(size, int_exp(1, s))
  let e_count = e_and(self.op2e(s, count), count_mask)
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
/// Upstream `Rotate` (ROL/ROR; RCL/RCR are not implemented upstream).
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
  let mask_size = word_size - 1
  let count_var = new_tmp(word_size)
  let count = ev(count_var)
  let zero = int_exp(0, word_size)
  let one = int_exp(1, word_size)
  let dst = self.op2e(word_size, dst_op)
  let shift_mask = int_exp(mask_size, word_size)
  let size = int_exp(word_size, word_size)
  let shift = self.op2e(word_size, shift_op)
  let unk = e_unknown("OF undefined after rotate of more then 1 bit", 1)
  let count_stmt = assign(count_var, bop(Mod, e_and(shift, shift_mask), size))
  if shift_type == LShift {
    [
      count_stmt,
      self.assn(
        word_size,
        dst_op,
        e_or(e_lsl(dst, count), e_lsr(dst, e_minus(size, count))),
      ),
      if_(e_eq(count, zero), [assign(cf, e_low(1, dst))], [
        if_(e_eq(count, one), [assign(of_, e_xor(ev(cf), e_high(1, dst)))], [
          assign(of_, unk),
        ]),
      ]),
    ]
  } else {
    [
      count_stmt,
      self.assn(
        word_size,
        dst_op,
        e_or(e_lsr(dst, count), e_lsl(dst, e_minus(size, count))),
      ),
      if_(e_eq(count, zero), [assign(cf, e_high(1, dst))], [
        if_(
          e_eq(count, one),
          [
            assign(
              of_,
              e_xor(
                e_high(1, dst),
                e_high(1, e_lsl(dst, int_exp(1, word_size))),
              ),
            ),
          ],
          [assign(of_, unk)],
        ),
      ]),
    ]
  }
}

///|
/// Upstream `Bt`.
fn Ctx::bt(
  self : Ctx,
  t : Int,
  bitoffset : Operand,
  bitbase : Operand,
) -> Array[@types.Stmt] raise X86Error {
  let offset = self.op2e(t, bitoffset)
  let (value, shift) = match bitbase {
    Oreg(_) => {
      let reg = self.op2e(t, bitbase)
      (reg, e_and(offset, int_exp(t - 1, t)))
    }
    Oaddr(a) => {
      let offset = e_unsigned(self.mode.width(), offset)
      let byte = self.load(8, e_plus(a, e_lsr(offset, int_exp(3, t))))
      (byte, e_and(e_low(8, offset), int_exp(7, 8)))
    }
    _ => raise ArchException("Invalid bt operand")
  }
  [
    assign(cf, e_low(1, e_lsr(value, shift))),
    assign(of_, e_unknown("OF undefined after bt", 1)),
    assign(sf, e_unknown("SF undefined after bt", 1)),
    assign(af, e_unknown("AF undefined after bt", 1)),
    assign(pf, e_unknown("PF undefined after bt", 1)),
  ]
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
