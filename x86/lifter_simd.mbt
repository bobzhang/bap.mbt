// Port of BAP `plugins/x86/x86_lifter.ml` (part 4): SSE/AVX moves and
// packed integer instructions.

///|
fn PackedOp::apply(
  self : PackedOp,
  x : @types.Exp,
  y : @types.Exp,
) -> @types.Exp {
  match self {
    PBin(op) => bop(op, x, y)
    PMin(signed) => min_symbolic(signed, x, y)
    PMax(signed) => max_symbolic(signed, x, y)
    PAvg(et) => {
      // port: the sum is computed with one more bit (upstream drops the
      // carry out of the element)
      let w = et + 1
      let one = int_exp(1, w)
      e_low(
        et,
        e_lsr(e_plus(e_plus(e_unsigned(w, x), e_unsigned(w, y)), one), one),
      )
    }
    PAndN => e_and(e_not(x), y)
  }
}

///|
/// Upstream `op2e_s_keep_width` (the width is the requested type).
fn Ctx::op2e_keep_width(
  self : Ctx,
  t : Int,
  operand : Operand,
) -> (@types.Exp, Int) raise X86Error {
  (self.op2e(t, operand), t)
}

///|
fn Ctx::to_ir_simd(
  self : Ctx,
  op : Opcode,
) -> Array[@types.Stmt] raise X86Error {
  let mode = self.mode
  let mw = mode.width()
  let im = (i : Int) => int_exp(i, mw)
  match op {
    Movdq(ts, s, td, d, align) => {
      let (s, al) = match s {
        Ovec(_) | Oreg(_) => (self.op2e(ts, s), [])
        Oaddr(a) => (self.op2e(ts, s), [a])
        _ => raise ArchException("invalid source operand for movdq")
      }
      let (d, al) = match d {
        // Behavior is to clear the xmm bits
        Ovec(_) => (self.assn(td, d, e_unsigned(td, s)), al)
        Oreg(_) => (self.assn(td, d, s), al)
        Oaddr(a) => {
          let al = al.copy()
          al.insert(0, a)
          (self.assn(td, d, s), al)
        }
        _ => raise ArchException("invalid dest operand for movdq")
      }
      // movdqa raises a general protection exception if its operands aren't
      // aligned on a 16-byte boundary
      let checks = if align {
        al.map(a => if_(e_eq(e_and(a, im(15)), im(0)), [], [general_protection]))
      } else {
        []
      }
      cat([[d], checks])
    }
    Movoffset((tdst, dst), offsets) => {
      // If a vex prefix is present, then extra space is filled with 0.
      // Otherwise, the bits are preserved.
      let padding = (hi : Int, lo : Int) => {
        if hi < lo {
          []
        } else if self.has_vex {
          [int_exp(0, hi - lo + 1)]
        } else {
          [e_extract(hi, lo, self.op2e(tdst, dst))]
        }
      }
      let offsets = offsets.copy()
      offsets.sort_by((a, b) => a.offdstoffset.compare(b.offdstoffset))
      let mut elist : Array[@types.Exp] = []
      let mut nextbit = 0
      for o in offsets {
        let e = e_extract(
          o.offlen + o.offsrcoffset - 1,
          o.offsrcoffset,
          self.op2e(o.offtyp, o.offop),
        )
        elist = cat_exps([[e], padding(o.offdstoffset - 1, nextbit), elist])
        nextbit = o.offdstoffset + o.offlen
      }
      let elist = cat_exps([padding(tdst - 1, nextbit), elist])
      [self.assn(tdst, dst, concat_explist(elist))]
    }
    Punpck(t, et, o, d, s, vs) => {
      let nelem = t / et
      if nelem % 2 != 0 {
        raise ArchException("Assert_failure: punpck")
      }
      let nelem_per_src = nelem / 2
      let halft = t / 2
      let castf = (e : @types.Exp) => {
        match o {
          High => e_high(halft, e)
          Low => e_low(halft, e)
        }
      }
      let se = castf(self.op2e(t, s))
      let de = castf(self.op2e(t, d))
      let st = new_tmp(halft)
      let dt = new_tmp(halft)
      let exps : Array[@types.Exp] = []
      for i = nelem_per_src - 1; i >= 0; i = i - 1 {
        exps.push(extract_element(et, ev(st), i))
        exps.push(extract_element(et, ev(dt), i))
      }
      let dest = match vs {
        None => d
        Some(vdst) => vdst
      }
      [assign(st, se), assign(dt, de), self.assn(t, dest, concat_explist(exps))]
    }
    Ppackedbinop(t, et, fbop, _, d, s, vs) => {
      let nops = t / et
      let tmp_dst = new_tmp(t)
      let vdst = match vs {
        Some(v) => v
        None => d
      }
      let iv = new_tmp(8)
      let elt = new_tmp(et)
      // assumption: immediate operands are repeated for all vector elements
      let getelement = (o : Operand, i : Int) => {
        match o {
          Oimm(_) => self.op2e(et, o)
          _ => extract_element(et, self.op2e(t, o), i)
        }
      }
      // port: the shifts by a register or memory operand shift every
      // element by the (unsigned) low quadword of the source, clearing (or
      // sign-filling) the elements when it exceeds the element width
      // (upstream shifts each element by the matching source element)
      let count = new_tmp(64, name="count")
      let (shift_count, stmts) = match (fbop, s) {
        (PBin(LShift | RShift | ARShift), Ovec(_) | Oaddr(_)) =>
          (
            Some(ev(count)),
            [
              assign(count, e_low(64, self.op2e(t, s))),
              assign(tmp_dst, int_exp(0, t)),
            ],
          )
        _ => (None, [assign(tmp_dst, int_exp(0, t))])
      }
      let apply = (x : @types.Exp, i : Int) => {
        match (fbop, shift_count) {
          (PBin(ARShift), Some(c)) => {
            let big = e_lt(int_exp(et - 1, 64), c)
            bop(ARShift, x, e_ite(big, int_exp(et - 1, et), e_low(et, c)))
          }
          (PBin(op), Some(c)) =>
            e_ite(
              e_lt(int_exp(et - 1, 64), c),
              int_exp(0, et),
              bop(op, x, e_low(et, c)),
            )
          _ => fbop.apply(x, getelement(s, i))
        }
      }
      for i in 0..<nops {
        stmts.push(assign(elt, apply(getelement(d, i), i)))
        stmts.push(assign(iv, int_exp(i, 8)))
        stmts.push(
          assign(
            tmp_dst,
            e_or(
              ev(tmp_dst),
              e_lsl(e_unsigned(t, ev(elt)), e_times(ev(iv), int_exp(et, 8))),
            ),
          ),
        )
      }
      stmts.push(self.assn(t, vdst, ev(tmp_dst)))
      stmts
    }
    Pbinop(t, fbop, _, o1, o2, vop) =>
      match vop {
        None =>
          [self.assn(t, o1, fbop.apply(self.op2e(t, o1), self.op2e(t, o2)))]
        Some(vop) =>
          [self.assn(t, o1, fbop.apply(self.op2e(t, vop), self.op2e(t, o2)))]
      }
    Pcmp(t, elebits, bop_, _, dst, src, vsrc) => {
      let ncmps = t / elebits
      let src = match src {
        Ovec(_) => self.op2e(t, src)
        Oaddr(a) => self.load(t, a)
        _ => raise ArchException("invalid")
      }
      let vsrc = match vsrc {
        Some(v) => v
        None => dst
      }
      let tmp_dst = new_tmp(t)
      let iv = new_tmp(8)
      let elt = new_tmp(elebits)
      let elt_1 = new_tmp(elebits)
      let elt_2 = new_tmp(elebits)
      let stmts = [assign(tmp_dst, int_exp(0, t))]
      for i in 0..<ncmps {
        let left_bit = i * elebits
        let right_bit = (i + 1) * elebits - 1
        stmts.push(assign(elt_1, e_extract(right_bit, left_bit, src)))
        stmts.push(
          assign(elt_2, e_extract(right_bit, left_bit, self.op2e(t, vsrc))),
        )
        stmts.push(assign(iv, int_exp(i, 8)))
        stmts.push(
          if_(
            bop(bop_, ev(elt_1), ev(elt_2)),
            [assign(elt, int_exp(-1, elebits))],
            [assign(elt, int_exp(0, elebits))],
          ),
        )
        stmts.push(
          assign(
            tmp_dst,
            e_or(
              ev(tmp_dst),
              e_lsl(
                e_unsigned(t, ev(elt)),
                e_times(ev(iv), int_exp(elebits, 8)),
              ),
            ),
          ),
        )
      }
      stmts.push(self.assn(t, dst, ev(tmp_dst)))
      stmts
    }
    Pmov(t, dstet, srcet, dst, src, signed, _) => {
      let nelem = t / dstet
      let exps : Array[@types.Exp] = []
      for i = nelem - 1; i >= 0; i = i - 1 {
        let e = extract_element(srcet, self.op2e(t, src), i)
        exps.push(
          if signed {
            e_signed(dstet, e)
          } else {
            e_unsigned(dstet, e)
          },
        )
      }
      [self.assn(t, dst, concat_explist(exps))]
    }
    Pmovmskb(t, dst, src) => {
      let nbytes = t / 8
      let src = match src {
        Ovec(_) => self.op2e(t, src)
        _ => raise ArchException("invalid operand")
      }
      let padt = 32 - nbytes
      if padt <= 0 {
        raise ArchException("pmovmskb: zero-width padding")
      }
      let mut acc = int_exp(0, padt)
      for i = nbytes; i >= 1; i = i - 1 {
        acc = e_concat(acc, e_extract(i * 8 - 1, i * 8 - 1, src))
      }
      [self.assn(32, dst, acc)]
    }
    Palignr(t, dst, src, vsrc, imm) => {
      let (dst_e, t_concat) = self.op2e_keep_width(t, dst)
      let (src_e, _) = self.op2e_keep_width(t, src)
      let imm = self.op2e(t, imm)
      let conct = e_concat(dst_e, src_e)
      let shift = e_lsr(conct, e_unsigned(t_concat, e_lsl(imm, int_exp(3, t))))
      let high = match t {
        256 | 128 | 64 => t - 1
        _ =>
          raise ArchException(
            "impossible: used non 64/128/256-bit operand in palignr",
          )
      }
      let result = e_extract(high, 0, shift)
      let addresses : Array[@types.Exp] = []
      for o in [src, dst] {
        if o is Oaddr(a) {
          addresses.insert(0, a)
        }
      }
      // Palignr seems to cause a CPU general protection exception if this
      // fails.
      cat([
        addresses.map(addr => {
          if_(e_eq(e_and(addr, im(15)), im(0)), [], [general_protection])
        }),
        match vsrc {
          None => [self.assn(t, dst, result)]
          Some(vdst) => [self.assn(t, vdst, result)]
        },
      ])
    }
    Pcmpstr(t, xmm1, xmm2m128, _, imm8cb, pcmpinfo) =>
      self.pcmpstr(t, xmm1, xmm2m128, imm8cb, pcmpinfo)
    Pshufd(t, dst, src, vsrc, imm) => {
      let src_e = self.op2e(t, src)
      let imm_e = self.op2e(t, imm)
      let get_dword = (ndword : Int) => {
        let high_b = 2 * (ndword % 4) + 1
        let low_b = 2 * (ndword % 4)
        let index = e_unsigned(t, e_extract(high_b, low_b, imm_e))
        // Use the same pattern for the top half of a ymm register
        let (index, index_width) = if t == 256 && ndword > 3 {
          (e_plus(index, int_exp(4, t)), 256)
        } else {
          (index, t)
        }
        e_low(32, e_lsr(src_e, e_times(index, int_exp(32, index_width))))
      }
      let topdword = if t == 128 { 3 } else { 7 }
      let parts : Array[@types.Exp] = []
      for n = topdword; n >= 0; n = n - 1 {
        parts.push(get_dword(n))
      }
      let dwords = concat_explist(parts)
      match vsrc {
        None => [self.assn(t, dst, dwords)]
        Some(vdst) => [self.assn(t, vdst, dwords)]
      }
    }
    Pshufb(exp_type, dst_op, src_op, vsrc) => {
      let op_size = exp_type
      let index_bits = match op_size {
        64 => 3
        128 | 256 => 4
        _ => raise ArchException("invalid size for pshufb")
      }
      let src = self.op2e(exp_type, src_op)
      let dst = self.op2e(exp_type, dst_op)
      let dst_op = match vsrc {
        Some(v) => v
        None => dst_op
      }
      let zero = int_exp(0, op_size)
      let msb_one = int_exp(0x80, 8)
      let byte = int_exp(8, 8)
      let iv = new_tmp(8, name="i")
      let mask_byte_i = new_tmp(8)
      let tmp_byte = new_tmp(exp_type)
      let tmp_dst = new_tmp(exp_type)
      let ind = new_tmp(8)
      let check_mem_alignment = match src_op {
        Oaddr(addr) if op_size == 128 => {
          let word_size = mw
          let zero = int_exp(0, word_size)
          let oxf = int_exp(0xf, word_size)
          [if_(e_neq(e_and(oxf, addr), zero), [CpuExn(13)], [])]
        }
        _ => []
      }
      let stmts = cat([check_mem_alignment, [assign(tmp_dst, zero)]])
      for i in 0..<(op_size / 8) {
        stmts.push(assign(iv, int_exp(i, 8)))
        stmts.push(
          assign(
            mask_byte_i,
            e_extract(7, 0, e_lsr(src, e_times(ev(iv), byte))),
          ),
        )
        stmts.push(
          if_(
            e_eq(e_and(msb_one, ev(mask_byte_i)), msb_one),
            [assign(tmp_byte, zero)],
            [
              assign(
                ind,
                // port: the low `index_bits` bits (upstream extracts one
                // bit more, selecting zero bytes past the vector)
                e_unsigned(8, e_extract(index_bits - 1, 0, ev(mask_byte_i))),
              ),
              assign(
                tmp_byte,
                e_unsigned(
                  op_size,
                  e_extract(7, 0, e_lsr(dst, e_times(ev(ind), byte))),
                ),
              ),
            ],
          ),
        )
        stmts.push(
          assign(
            tmp_dst,
            e_or(ev(tmp_dst), e_lsl(ev(tmp_byte), e_times(ev(iv), byte))),
          ),
        )
      }
      stmts.push(self.assn(exp_type, dst_op, ev(tmp_dst)))
      stmts
    }
    _ => raise ArchException("unhandled opcode")
  }
}

///|
fn cat_exps(parts : Array[Array[@types.Exp]]) -> Array[@types.Exp] {
  let result : Array[@types.Exp] = []
  for part in parts {
    result.push_iter(part.iter())
  }
  result
}

///|
/// Upstream `Pcmpstr` (PCMPESTRI, PCMPESTRM, PCMPISTRI, PCMPISTRM). All
/// bytes and bits are numbered with zero being the least significant.
fn Ctx::pcmpstr(
  self : Ctx,
  t : Int,
  xmm1 : Operand,
  xmm2m128 : Operand,
  imm8cb : Imm8cb,
  pcmpinfo : PcmpInfo,
) -> Array[@types.Stmt] raise X86Error {
  let r = self.vars()
  let xmm1_e = self.op2e(t, xmm1)
  let xmm2m128_e = self.op2e(t, xmm2m128)
  let regm = self.mode.width()
  let (nelem, elemt) = if imm8cb.words { (8, 16) } else { (16, 8) }
  // Get element index in e
  let get_elem = (e : @types.Exp, i : Int) => extract_element(elemt, e, i)
  let get_xmm1 = (i : Int) => get_elem(xmm1_e, i)
  let get_xmm2 = (i : Int) => get_elem(xmm2m128_e, i)
  // nelem - 1, ..., 0
  let nelem_range = [ for i in 0..<nelem => nelem - 1 - i ]
  // the is_valid variables: whether an index is a valid element (before
  // the NULL element)
  let valid_vars : Map[(Int, Int), @types.Var] = Map([])
  let is_valid = (xmmnum : Int, index : Int) => {
    match valid_vars.get((xmmnum, index)) {
      Some(v) => v
      None => {
        let v = new_tmp(1, name="is_valid_xmm\{xmmnum}_ele\{index}")
        valid_vars[(xmmnum, index)] = v
        v
      }
    }
  }
  let is_valid_xmm1_e = (i : Int) => ev(is_valid(1, i))
  let is_valid_xmm2_e = (i : Int) => ev(is_valid(2, i))
  // implicit (NULL-based) string length
  let implicit_check = (xmmnum : Int, get : (Int) -> @types.Exp) => {
    let acc : Array[@types.Stmt] = []
    for i in nelem_range {
      let previous_valid = if i == 0 {
        exp_true
      } else {
        ev(is_valid(xmmnum, i - 1))
      }
      let current_valid = e_neq(get(i), int_exp(0, elemt))
      acc.insert(
        0,
        assign(is_valid(xmmnum, i), e_and(previous_valid, current_valid)),
      )
    }
    acc
  }
  // explicit string length
  let explicit_check = (xmmnum : Int, sizee : @types.Exp) => {
    let nelem_e = int_exp(nelem, regm)
    let sizev = new_tmp(regm, name="sz")
    // upstream folds the element checks in front of the size computation
    let stmts = [
      if_(e_lt(nelem_e, sizee), [assign(sizev, nelem_e)], [assign(sizev, sizee)]),
    ]
    for i in nelem_range {
      stmts.insert(
        0,
        assign(is_valid(xmmnum, i), e_lt(int_exp(i, regm), ev(sizev))),
      )
    }
    stmts
  }
  let (xmm1_checks, xmm2_checks) = if pcmpinfo.implicit {
    (implicit_check(1, get_xmm1), implicit_check(2, get_xmm2))
  } else {
    (explicit_check(1, ev(r.rax)), explicit_check(2, ev(r.rdx)))
  }
  let get_bit = (index : Int) => {
    match imm8cb.agg {
      0 => {
        // EqualAny: is xmm2[index] at xmm1[j] for any j?
        let mut acc = exp_false
        for j in nelem_range {
          let is_eql = e_eq(get_xmm2(index), get_xmm1(j))
          acc = e_or(e_and(is_eql, is_valid_xmm1_e(j)), acc)
        }
        e_and(is_valid_xmm2_e(index), acc)
      }
      1 => {
        // Ranges: is there an even j such that
        // xmm1[j] <= xmm2[index] <= xmm1[j+1]?
        let le = (x : @types.Exp, y : @types.Exp) => {
          if imm8cb.signed {
            bop(SignedLe, x, y)
          } else {
            bop(Le, x, y)
          }
        }
        let mut acc = exp_false
        for j = nelem / 2 - 1; j >= 0; j = j - 1 {
          let ind0 = 2 * j
          let ind1 = ind0 + 1
          let rangevalid = e_and(is_valid_xmm1_e(ind0), is_valid_xmm1_e(ind1))
          let inrange = e_and(
            le(get_xmm1(ind0), get_xmm2(index)),
            le(get_xmm2(index), get_xmm1(ind1)),
          )
          acc = e_and(rangevalid, e_or(inrange, acc))
        }
        e_and(is_valid_xmm2_e(index), acc)
      }
      2 => {
        // EqualEach: does xmm1[index] = xmm2[index]?
        let xmm1_invalid = e_not(is_valid_xmm1_e(index))
        let xmm2_invalid = e_not(is_valid_xmm2_e(index))
        let bothinvalid = e_and(xmm1_invalid, xmm2_invalid)
        let eitherinvalid = e_or(xmm1_invalid, xmm2_invalid)
        let equal = e_eq(get_xmm1(index), get_xmm2(index))
        e_or(bothinvalid, e_and(e_not(eitherinvalid), equal))
      }
      _ => {
        // EqualOrdered: does the substring xmm1 occur at xmm2[index]?
        let mut acc = exp_true
        for j = nelem - index - 1; j >= 0; j = j - 1 {
          let equal = e_eq(get_xmm1(j), get_xmm2(index + j))
          let substrended = e_not(is_valid_xmm1_e(j))
          let bigstrended = e_not(is_valid_xmm2_e(index + j))
          acc = e_or(substrended, e_and(e_not(bigstrended), e_and(equal, acc)))
        }
        acc
      }
    }
  }
  let bits = nelem_range.map(get_bit)
  let res = new_tmp(bits.length())
  let res_bil = [assign(res, concat_explist(bits))]
  let int_res_1 = new_tmp(16, name="IntRes1")
  let int_res_2 = new_tmp(16, name="IntRes2")
  let contains_null = (e : @types.Exp) => {
    let mut acc = exp_false
    for i in 0..<nelem {
      acc = e_or(acc, e_eq(get_elem(e, i), int_exp(0, elemt)))
    }
    acc
  }
  // For pcmpistri/pcmpestri
  let sb = (exp : @types.Exp) => {
    let mut acc = int_exp(nelem, regm)
    let range = if imm8cb.msb {
      [
        for i in 0..<nelem => i
      ]
    } else {
      nelem_range
    }
    for i in range {
      acc = e_ite(e_eq(exp_true, e_extract(i, i, exp)), int_exp(i, regm), acc)
    }
    acc
  }
  // For pcmpistrm/pcmpestrm
  let mask = (e : @types.Exp) => {
    if imm8cb.msb {
      concat_explist(
        nelem_range.map(i => e_unsigned(elemt, e_extract(i, i, e))),
      )
    } else {
      e_unsigned(128, e)
    }
  }
  let res_of_cb = if !imm8cb.negintres1 {
    assign(int_res_2, ev(int_res_1))
  } else if !imm8cb.maskintres1 {
    // int_res_1 is bitwise-notted
    assign(int_res_2, e_not(ev(int_res_1)))
  } else {
    // only the valid elements in xmm2 are bitwise-notted
    let validvector = e_unsigned(
      16,
      concat_explist(nelem_range.map(is_valid_xmm2_e)),
    )
    assign(int_res_2, e_xor(validvector, ev(int_res_1)))
  }
  let res_of_pcmpinfo = if pcmpinfo.index {
    assign(r.rcx, sb(ev(int_res_2)))
  } else {
    // FIXME: ymms should be used instead of xmms here
    assign(r.ymms[0], mask(ev(int_res_2)))
  }
  cat([
    xmm1_checks,
    xmm2_checks,
    res_bil,
    [
      assign(int_res_1, e_unsigned(16, ev(res))),
      res_of_cb,
      res_of_pcmpinfo,
      assign(cf, e_neq(ev(int_res_2), int_exp(0, 16))),
      assign(zf, contains_null(xmm2m128_e)),
      assign(sf, contains_null(xmm1_e)),
      assign(of_, e_extract(0, 0, ev(int_res_2))),
      assign(af, int_exp(0, 1)),
      assign(pf, int_exp(0, 1)),
    ],
  ])
}
