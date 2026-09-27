// Port of BAP `plugins/x86/x86_lifter.ml` (part 2): `ToIR.to_ir` for the
// general purpose instructions.

///|
fn Ctx::is_small_imm(_self : Ctx, op : Operand, t : Int) -> Bool {
  match op {
    Oimm(imm) => imm.width < t
    _ => false
  }
}

///|
fn Ctx::sign_extend_imm(
  self : Ctx,
  op : Operand,
  t : Int,
) -> @types.Exp raise X86Error {
  match op {
    Oimm(imm) => e_signed(t, self.op2e(imm.width, op))
    _ => raise ArchException("imm operand expected")
  }
}

///|
/// A source operand, sign-extending small immediates (upstream
/// `if is_small_imm o t then sign_extend_imm o t else op2e t o`).
fn Ctx::src_operand(
  self : Ctx,
  op : Operand,
  t : Int,
) -> @types.Exp raise X86Error {
  if self.is_small_imm(op, t) {
    self.sign_extend_imm(op, t)
  } else {
    self.op2e(t, op)
  }
}

///|
fn Ctx::pref_is(self : Ctx, p : Int) -> Bool {
  self.pref is [x] && x == p
}

///|
fn cat(parts : Array[Array[@types.Stmt]]) -> Array[@types.Stmt] {
  let result : Array[@types.Stmt] = []
  for part in parts {
    result.push_iter(part.iter())
  }
  result
}

///|
/// Upstream `ToIR.to_ir`.
fn Ctx::to_ir(self : Ctx, op : Opcode) -> Array[@types.Stmt] raise X86Error {
  let mode = self.mode
  let r = self.vars()
  let mw = mode.width()
  let rsp_e = ev(r.rsp)
  match op {
    Nop => []
    Bswap(t, op) =>
      match t {
        32 | 64 => [self.assn(t, op, reverse_bytes(self.op2e(t, op), t))]
        _ => raise ArchException("bswap: Expected 32 or 64 bit type")
      }
    Retn(op, far_ret) if self.pref.is_empty() ||
      self.pref_is(repz) ||
      self.pref_is(repnz) => {
      let temp = new_tmp(mw)
      if far_ret {
        // TODO Mess with segment selectors here
        raise NoSemantics("long retn not supported")
      }
      let stmts = [
        assign(temp, load_s(mode, None, mw, rsp_e)),
        assign(r.rsp, e_plus(rsp_e, int_exp(mw / 8, mw))),
      ]
      if op is Some((t, src)) {
        stmts.push(assign(r.rsp, e_plus(rsp_e, self.op2e(t, src))))
      }
      stmts.push(Jmp(ev(temp)))
      stmts
    }
    Mov(t, dst, src, condition) => {
      let c_src = match condition {
        None => self.op2e(t, src)
        Some(c) => e_ite(c, self.op2e(t, src), self.op2e(t, dst))
      }
      let stmts = [self.assn(t, dst, c_src)]
      if compute_segment_bases.val && (dst == o_fs || dst == o_gs) {
        let base = if dst == o_fs { r.fs_base } else { r.gs_base }
        stmts.push(assign(base, self.segment_base(self.op2e(t, dst))))
      }
      stmts
    }
    Movs(t) => {
      let stmts = [
        store_s(mode, None, t, ev(r.rdi), load_s(mode, None, t, ev(r.rsi))),
        string_incr(mode, t, r.rsi),
        string_incr(mode, t, r.rdi),
      ]
      if self.pref.is_empty() {
        stmts
      } else if self.pref.contains(repz) || self.pref.contains(repnz) {
        // movs has only rep instruction others just considered to be rep
        rep_wrap(mode, stmts)
      } else {
        raise NoSemantics("unsupported prefix for movs")
      }
    }
    Movzx(t, dst, ts, src) =>
      [self.assn(t, dst, e_unsigned(t, self.op2e(ts, src)))]
    Movsx(t, dst, ts, src) =>
      [self.assn(t, dst, e_signed(t, self.op2e(ts, src)))]
    Lea(t, reg, a) if self.pref.is_empty() => [self.assn(t, reg, e_low(t, a))]
    Call(o1, ra) => {
      let target = self.op2e(mw, o1)
      let push_ra = [
        assign(r.rsp, e_minus(rsp_e, int_exp(mw / 8, mw))),
        store_s(mode, None, mw, rsp_e, ra.to_exp(ra.width)),
      ]
      match o1 {
        Oimm(_) => cat([push_ra, [Jmp(target)]])
        _ => {
          let t = new_tmp(mw)
          cat([[assign(t, target)], push_ra, [Jmp(ev(t))]])
        }
      }
    }
    Jump(o) => [Jmp(self.jump_target(o))]
    Jcc(o, c) => [if_(c, [Jmp(self.jump_target(o))], [])]
    Setcc(t, o1, c) => [self.assn(t, o1, e_unsigned(t, c))]
    Shift(st, s, dst, shift) => self.shift(st, s, dst, shift)
    Shiftd(st, s, dst, fill, count) => self.shiftd(st, s, dst, fill, count)
    Rotate(st, t, dst, shift, use_cf) => self.rotate(st, t, dst, shift, use_cf)
    Bt(kind, t, bitoffset, bitbase) => self.bt(kind, t, bitoffset, bitbase)
    Bs(t, dst, src, dir) => self.bs(t, dst, src, dir)
    Hlt => [] // x86 Hlt is essentially a NOP
    Rdtsc =>
      [
        self.assn(32, o_rax, e_unknown("rdtsc", 32)),
        self.assn(32, o_rdx, e_unknown("rdtsc", 32)),
      ]
    Cpuid =>
      [o_rax, o_rbx, o_rcx, o_rdx].map(reg => {
        self.assn(32, reg, e_unknown("cpuid", 32))
      })
    Xgetbv =>
      [
        self.assn(32, o_rax, e_unknown("xgetbv", 32)),
        self.assn(32, o_rdx, e_unknown("xgetbv", 32)),
      ]
    Stmxcsr(dst) =>
      match dst {
        Oaddr(addr) => [self.store(32, addr, ev(mxcsr))]
        _ => raise ArchException("stmxcsr argument cannot be non-memory")
      }
    Ldmxcsr(src) =>
      match src {
        Oaddr(addr) => [assign(mxcsr, self.load(32, addr))]
        _ => raise ArchException("ldmxcsr argument cannot be non-memory")
      }
    Fnstcw(dst) =>
      match dst {
        Oaddr(addr) => [self.store(16, addr, ev(fpu_ctrl))]
        _ => raise ArchException("fnstcw argument cannot be non-memory")
      }
    Fldcw(src) =>
      match src {
        Oaddr(addr) => [assign(fpu_ctrl, self.load(16, addr))]
        _ => raise ArchException("fldcw argument cannot be non-memory")
      }
    Fld(_) => raise NoSemantics("unsupported FPU register stack")
    Fst(_, _) => raise NoSemantics("unsupported FPU flags")
    Cmps(t) => {
      let src1 = new_tmp(t)
      let src2 = new_tmp(t)
      let tmpres = new_tmp(t)
      let stmts = [
        assign(src1, self.op2e(t, Oaddr(ev(r.rsi)))),
        assign(src2, load_s(mode, None, t, ev(r.rdi))),
        assign(tmpres, e_minus(ev(src1), ev(src2))),
        string_incr(mode, t, r.rsi),
        string_incr(mode, t, r.rdi),
      ]
      stmts.push_iter(set_flags_sub(t, ev(src1), ev(src2), ev(tmpres)).iter())
      match self.pref {
        [] => stmts
        [single] if single == repz || single == repnz =>
          rep_wrap(mode, stmts, check_zf=single)
        _ => raise NoSemantics("unsupported flags in cmps")
      }
    }
    Scas(t) => {
      let src1 = new_tmp(t)
      let src2 = new_tmp(t)
      let tmpres = new_tmp(t)
      let stmts = [
        assign(src1, e_low(t, ev(r.rax))),
        assign(src2, load_s(mode, None, t, ev(r.rdi))),
        assign(tmpres, e_minus(ev(src1), ev(src2))),
        string_incr(mode, t, r.rdi),
      ]
      stmts.push_iter(set_flags_sub(t, ev(src1), ev(src2), ev(tmpres)).iter())
      match self.pref {
        [] => stmts
        [single] if single == repz || single == repnz =>
          rep_wrap(mode, stmts, check_zf=single)
        _ => raise NoSemantics("unsupported flags in scas")
      }
    }
    Stos(t) => {
      let stmts = [
        store_s(mode, None, t, ev(r.rdi), self.op2e(t, o_rax)),
        string_incr(mode, t, r.rdi),
      ]
      match self.pref {
        [] => stmts
        [single] if single == repz => rep_wrap(mode, stmts)
        _ => raise NoSemantics("unsupported prefix for stos")
      }
    }
    Push(t, o) => {
      let o = self.src_operand(o, t)
      let tmp = new_tmp(t) // only really needed when o involves esp
      [
        assign(tmp, o),
        assign(r.rsp, e_minus(rsp_e, int_exp(t / 8, mw))),
        store_s(mode, None, t, rsp_e, ev(tmp)),
      ]
    }
    Pop(t, o) => {
      // "The POP ESP instruction increments the stack pointer (ESP) before
      // data at the old top of stack is written into the destination", so
      // effectively there is no incrementation.
      let stmts = [self.assn(t, o, load_s(mode, None, t, rsp_e))]
      if o != o_rsp {
        stmts.push(assign(r.rsp, e_plus(rsp_e, int_exp(t / 8, mw))))
      }
      stmts
    }
    Pushf(t) =>
      match t {
        16 | 32 | 64 =>
          [
            assign(r.rsp, e_minus(rsp_e, int_exp(t / 8, mw))),
            store_s(mode, None, t, rsp_e, flags_exp(t)),
          ]
        _ => raise ArchException("impossible")
      }
    Popf(t) => {
      guard t is (16 | 32 | 64) else { raise ArchException("impossible") }
      let tmp = new_tmp(t)
      cat([
        [
          assign(tmp, load_s(mode, None, t, rsp_e)),
          assign(r.rsp, e_plus(rsp_e, int_exp(t / 8, mw))),
        ],
        flags_assignments(t, ev(tmp)),
      ])
    }
    Popcnt(t, s, d) => {
      let bits = self.op2e(t, s)
      let res = new_tmp(t)
      let cnt = match t {
        16 | 32 | 64 => popcount(res, t)
        _ => raise ArchException("Invalid popcnt width")
      }
      cat([
        [set_zf(t, bits), assign(res, bits)],
        cnt,
        [self.assn(t, d, ev(res))],
        [cf, of_, sf, af, pf].map(f => assign(f, int_exp(0, 1))),
      ])
    }
    Sahf => {
      let tah = new_tmp(8, name="AH")
      cat([[assign(tah, bits2reg8e(mode, 4))], flags_assignments(8, ev(tah))])
    }
    Lahf => [self.assn(8, Oreg(4), flags_exp(8))]
    Leave(t) if self.pref.is_empty() =>
      cat([[assign(r.rsp, ev(r.rbp))], self.to_ir(Pop(t, o_rbp))])
    Interrupt3 => [CpuExn(3)]
    Interrupt(Oimm(i)) => [CpuExn(i.bits.to_int())]
    Sysenter | Syscall => [special_call("syscall")]
    Leave(_) => raise NoSemantics("to_ir: Leave")
    Lea(_) => raise NoSemantics("to_ir: Lea")
    Retn(_) => raise NoSemantics("to_ir: Retn")
    Interrupt(_) => raise NoSemantics("to_ir: Interrupt")
    _ => self.to_ir_arith(op)
  }
}

///|
/// The segment base computed from the GDT or LDT (upstream `base_e`, only
/// used when `compute_segment_bases` is set).
fn Ctx::segment_base(self : Ctx, e : @types.Exp) -> @types.Exp raise X86Error {
  let r = self.vars()
  let mw = self.mode.width()
  // 0 = GDT, 1 = LDT
  let ti = e_extract(3, 3, e)
  let base = e_ite(ti, ev(r.ldt), ev(r.gdt))
  // Extract index into table
  let (entry_size, entry_shift) = match self.mode {
    X86 => (64, 6)
    X8664 => (128, 7)
  }
  let index = e_unsigned(
    mw,
    e_lsl(e_extract(15, 4, e), int_exp(entry_shift, mw)),
  )
  // Load the table entry
  let table_entry = load_s(self.mode, None, entry_size, e_plus(base, index))
  // Extract the base
  let parts : Array[@types.Exp] = []
  if self.mode == X8664 {
    parts.push(e_extract(95, 64, table_entry))
  }
  parts.push(e_extract(63, 56, table_entry))
  parts.push(e_extract(39, 32, table_entry))
  parts.push(e_extract(31, 16, table_entry))
  concat_explist(parts)
}
