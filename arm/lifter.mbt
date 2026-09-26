// Port of the entry points of `Arm_lifter`: operand conversion, dispatch
// by instruction group, PC resolution and lifter registration.

///|
/// `Arm_lifter.arm_ops`: convert all backend operands.
pub fn ops_of_mc(ops : ArrayView[@mc.Op]) -> Array[Op] raise @mc.LiftError {
  let result = []
  for op in ops {
    match Op::of_mc(op) {
      Some(op) => result.push(op)
      None => raise BadOperands("unsupported operand: \{op.to_string()}")
    }
  }
  result
}

///|
/// Lift a decoded ARM instruction without resolving `PC`
/// (`Arm_lifter.insn_exn`).
///
/// - `addr` is the address of the instruction (used by branches);
/// - `encoding` selects how modified immediates are decoded;
/// - `raw` is the instruction word, used for the carry flag of
///   data-processing instructions with immediates and for `BFI`/`BFC`.
///   When it is absent it is reconstructed from the operands.
pub fn lift_typed(
  insn : Insn,
  ops : ArrayView[Op],
  addr? : UInt = 0,
  encoding? : Encoding = A32,
  raw? : UInt,
) -> Array[@types.Stmt] raise @mc.LiftError {
  tmp_counter.val = 0
  match insn {
    Move(op) => lift_move(encoding, raw_or_operand_word(raw, op, ops), ops, op)
    Bits(op) => lift_bits(raw, ops, op)
    Mult(op) => lift_mult(ops, op)
    Mem(op) => lift_mem(ops, op)
    MemMulti(op) => lift_mem_multi(ops, op)
    Branch(op) => lift_branch(addr, ops, op)
    Special(op) => lift_special(ops, op)
  }
}

///|
/// The instruction word used by `set_cf_data`. For A32 modified-immediate
/// forms the rotation field (bits 11..8) of the instruction word coincides
/// with the one of the undecoded immediate operand, which is all that
/// `set_cf_data` inspects.
fn raw_or_operand_word(
  raw : UInt?,
  insn : MoveInsn,
  ops : ArrayView[Op],
) -> UInt {
  match raw {
    Some(raw) => raw
    None => {
      let imm = match (insn, ops) {
        (MOVi | MVNi, [_, Imm(imm), ..]) => imm
        (ANDri | BICri | EORri | ORRri, [_, _, Imm(imm), ..]) => imm
        _ => 0
      }
      imm & 0xFFF
    }
  }
}

///|
/// Replace reads of `PC` with `pc_value` and turn assignments to `PC`
/// into jumps (`Arm_lifter.resolve_pc`).
pub fn resolve_pc(
  stmts : ArrayView[@types.Stmt],
  pc_value : UInt,
) -> Array[@types.Stmt] {
  let pc_exp = int32(pc_value)
  let map_exp = (e : @types.Exp) => e.substitute_var(pc, pc_exp)
  fn map_stmt(s : @types.Stmt) -> @types.Stmt {
    match s {
      Move(x, e) if x == pc => Jmp(map_exp(e))
      Move(x, e) => Move(x, map_exp(e))
      Jmp(e) => Jmp(map_exp(e))
      If(cond~, yes~, no~) =>
        If(cond=map_exp(cond), yes=yes.map(map_stmt), no=no.map(map_stmt))
      While(cond~, body~) => While(cond=map_exp(cond), body=body.map(map_stmt))
      Special(_) | CpuExn(_) => s
    }
  }
  stmts.iter().map(map_stmt).to_array()
}

///|
/// The encoding implied by an opcode name: Thumb-2 (`t2`-prefixed)
/// opcodes use T32, all others A32.
pub fn encoding_of_name(name : StringView) -> Encoding {
  if is_thumb2(name) {
    T32
  } else {
    A32
  }
}

///|
/// Lift an `@mc.Insn` to BIL (`Arm_lifter.lift`).
///
/// Opcodes unknown to the ARM lifter produce an empty program, as upstream
/// does. Reads of `PC` are resolved to the instruction address plus 8 and
/// writes to `PC` become jumps. `encoding` defaults to the one implied by
/// the opcode name (see `encoding_of_name`).
pub fn lift(
  insn : @mc.Insn,
  encoding? : Encoding,
  raw? : UInt,
) -> Array[@types.Stmt] raise @mc.LiftError {
  match Insn::of_name(insn.name) {
    None => []
    Some(arm_insn) => {
      let ops = ops_of_mc(insn.ops)
      let encoding = match encoding {
        Some(encoding) => encoding
        None => encoding_of_name(insn.name)
      }
      let addr = insn.addr.to_uint()
      let stmts = lift_typed(arm_insn, ops, addr~, encoding~, raw?) catch {
        Failure(msg) => raise Failure("\{insn.name}:\{msg}")
        err => raise err
      }
      resolve_pc(stmts, addr_of_pc(insn.addr).to_uint())
    }
  }
}

///|
/// Target names under which `register` installs the lifter: the BAP
/// `Arch.arm`, `Arch.armeb`, `Arch.thumb` and `Arch.thumbeb` families and
/// their generic names.
pub let target_names : ReadOnlyArray[String] = [
  "arm", "armv4", "armv5", "armv6", "armv7", "armeb", "armv4eb", "armv5eb", "armv6eb",
  "armv7eb", "thumb", "thumbv4", "thumbv5", "thumbv6", "thumbv7", "thumbeb", "thumbv4eb",
  "thumbv5eb", "thumbv6eb", "thumbv7eb",
]

///|
/// Register the ARM lifter with `@mc` for all ARM and Thumb targets.
/// Idempotent.
pub fn register() -> Unit {
  for name in target_names {
    @mc.register_lifter(name, insn => lift(insn))
  }
}
