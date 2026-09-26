// Port of `Arm_mem_shift`: operand-level wrappers around `Arm_mem` and
// decoding of the offsets of addressing modes 2 and 3.

///|
fn repair_negate(bit_set : Bool, rtype : Repair) -> Bool {
  (bit_set && rtype is NEG) || (!bit_set && rtype is POS)
}

///|
/// `Arm_mem_shift.repair_imm`: extract the immediate offset and apply the
/// add/subtract bit selected by `sign_mask`.
fn repair_imm(
  src : UInt,
  sign_mask~ : UInt,
  imm_mask~ : UInt,
  rtype : Repair,
) -> @types.Exp {
  let bit_set = (sign_mask & src) == sign_mask
  let offset = src & imm_mask
  int32(if repair_negate(bit_set, rtype) { 0U - offset } else { offset })
}

///|
/// `Arm_mem_shift.repair_reg`: negate a register offset when the
/// add/subtract bit says so.
fn repair_reg(
  reg : @types.Exp,
  imm : UInt,
  sign_mask~ : UInt,
  rtype : Repair,
) -> @types.Exp {
  let bit_set = (sign_mask & imm) == sign_mask
  if repair_negate(bit_set, rtype) {
    bin(Times, int32(0xFFFFFFFF), reg)
  } else {
    reg
  }
}

///|
/// `Arm_mem_shift.lift_r_op`: single register access with an operand
/// offset (register or immediate) and an optional shift.
fn lift_r_op(
  dest1~ : Op,
  dest2? : Op,
  shift? : Op,
  base~ : Op,
  offset~ : Op,
  mode : ModeR,
  sign : Sign,
  size : MemSize,
  operation : Operation,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let base = assert_reg(base).to_var()
  let offset_e = match offset {
    Reg(r) => v(r.to_var())
    Imm(w) => if w == 0x80000000 { int32(0) } else { int32(w) }
  }
  let offset_e = match shift {
    Some(s) => shift_mem(offset_e, s, @types.ValueType::reg32_t())
    None => offset_e
  }
  match (dest1, dest2) {
    (Reg(d1), Some(Reg(d2))) if d1.is_gpr() && d2.is_gpr() =>
      mem_lift_r(
        dst1=d1.to_var(),
        dst2=d2.to_var(),
        base~,
        offset=offset_e,
        mode,
        sign,
        size,
        operation,
      )
    (Reg(d), None) if d.is_gpr() =>
      mem_lift_r(
        dst1=d.to_var(),
        base~,
        offset=offset_e,
        mode,
        sign,
        size,
        operation,
      )
    (op1, op2) => {
      let op2 = match op2 {
        None => "unspecified"
        Some(op) => op.to_string()
      }
      fail("Unexpected arguments: \{op1.to_string()}, \{op2}")
    }
  }
}

///|
/// `Arm_mem_shift.lift_r_exp`: single register access with an already
/// computed offset expression.
fn lift_r_exp(
  dest1~ : Op,
  dest2? : Op,
  base~ : Op,
  offset~ : @types.Exp,
  mode : ModeR,
  sign : Sign,
  size : MemSize,
  operation : Operation,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let dst1 = assert_reg(dest1).to_var()
  let base = assert_reg(base).to_var()
  match dest2 {
    Some(dest2) => {
      let dst2 = assert_reg(dest2).to_var()
      mem_lift_r(dst1~, dst2~, base~, offset~, mode, sign, size, operation)
    }
    None => mem_lift_r(dst1~, base~, offset~, mode, sign, size, operation)
  }
}

///|
/// `Arm_mem_shift.lift_m`: load/store multiple over operand lists.
fn lift_m(
  dest_list : ArrayView[Op],
  base : Op,
  mode : ModeM,
  update : UpdateM,
  operation : Operation,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let base = assert_reg(base).to_var()
  let dests = []
  for d in dest_list {
    dests.push(assert_reg(d).to_var())
  }
  mem_lift_m(dests, base, mode, update, operation)
}

///|
/// Offset of addressing mode 3: register offset (`reg_off`) or, when the
/// register is `Nil`, the 8-bit immediate; bit 8 set means subtract.
fn mem_offset_reg_or_imm_neg(
  reg_off : Op,
  imm_off : UInt,
) -> @types.Exp raise @mc.LiftError {
  match reg_off {
    Reg(Nil) => repair_imm(imm_off, sign_mask=0x100, imm_mask=0xff, NEG)
    Reg(reg) if reg.is_gpr() =>
      repair_reg(v(reg.to_var()), imm_off, sign_mask=0x100, NEG)
    op => fail("unexpected operand: \{op.to_string()}")
  }
}

///|
/// Like `mem_offset_reg_or_imm_neg` for the unprivileged (`T`) variants,
/// where the sign bit is set when the offset is positive.
fn mem_offset_reg_or_imm_pos(
  reg_off : Op,
  imm_off : UInt,
) -> @types.Exp raise @mc.LiftError {
  match reg_off {
    Reg(Nil) => repair_imm(imm_off, sign_mask=0x100, imm_mask=0xff, POS)
    Reg(reg) if reg.is_gpr() =>
      repair_reg(v(reg.to_var()), imm_off, sign_mask=0x1, POS)
    op => fail("unexpected operand: \{op.to_string()}")
  }
}
