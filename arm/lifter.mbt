// Port of the entry points of `Arm_lifter`: operand conversion, dispatch
// by instruction group, PC resolution and lifter registration.

///|
/// `Arm_lifter.arm_ops`: convert all backend operands. Unsupported operands
/// raise `BadOperands` with an empty opcode (filled in by `lift`).
pub fn ops_of_mc(ops : ArrayView[@mc.Op]) -> Array[Op] raise @mc.LiftError {
  let result = []
  for op in ops {
    match Op::of_mc(op) {
      Some(op) => result.push(op)
      // port: a register pair (`R0_R1`, LLVM's `GPRPair` operand of
      // `LDREXD`/`STREXD`) stands for its two registers
      None if op is Reg(name~, ..) && register_pair(name) is Some((lo, hi)) => {
        result.push(Reg(lo))
        result.push(Reg(hi))
      }
      None =>
        raise BadOperands(
          opcode="",
          detail="unsupported operand: \{op.to_string()}",
        )
    }
  }
  result
}

///|
/// The registers of a register pair name (`R0_R1`).
fn register_pair(name : String) -> (Reg, Reg)? {
  let parts : Array[StringView] = name.split("_").collect()
  match parts {
    [lo, hi] =>
      match (Reg::of_name(lo), Reg::of_name(hi)) {
        (Some(lo), Some(hi)) => Some((lo, hi))
        _ => None
      }
    _ => None
  }
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
    Move(op) => lift_move(encoding, ops, op)
    Bits(op) => lift_bits(raw, ops, op)
    Mult(op) => lift_mult(ops, op)
    Mem(op) => lift_mem(ops, op)
    MemMulti(op) => lift_mem_multi(ops, op)
    Branch(op) => lift_branch(addr, ops, op)
    Special(op) => lift_special(ops, op)
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
      let ops = ops_of_mc(insn.ops) catch {
        BadOperands(opcode="", detail~) =>
          raise BadOperands(opcode=insn.name, detail~)
        err => raise err
      }
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
/// Name of the provider installed by `register`.
pub let provider_name : String = "arm"

///|
/// Whether the provider applies to `ctx`: 32-bit little-endian targets of
/// the ARM family decoded as ARM (`llvm-armv7`) or Thumb (`llvm-thumb`)
/// instructions. Like upstream, the lifter only produces little-endian
/// memory accesses, so big-endian targets are rejected explicitly rather
/// than lifted with the wrong byte order.
pub fn accepts(ctx : @mc.Context) -> Bool {
  ctx.belongs(@core_theory.Target::arm_family()) &&
  ctx.target.bits() == 32 &&
  !(ctx.target.endianness() is BigEndian) &&
  (
    ctx.encoding == @core_theory.Language::llvm_a32() ||
    ctx.encoding == @core_theory.Language::llvm_t32()
  )
}

///|
/// The instruction word of an A32 instruction from its raw (little-endian)
/// bytes, when available.
fn raw_word(insn : @mc.Insn) -> UInt? {
  let raw = insn.raw
  if raw.length() == 4 {
    Some(
      raw[0].to_uint() |
      (raw[1].to_uint() << 8) |
      (raw[2].to_uint() << 16) |
      (raw[3].to_uint() << 24),
    )
  } else {
    None
  }
}

///|
/// Lift in a context. In the Thumb encoding only Thumb-2 (`t2`-prefixed)
/// opcodes are handled (Thumb-1 `t*` opcodes are left to the `thumb`
/// provider, which is registered first); in the ARM encoding `t2` opcodes
/// are rejected. Opcodes the lifter does not model raise `Unsupported`.
///
/// `BLXi` in the ARM encoding always switches to Thumb, which is recorded
/// as the destination encoding of the result.
pub fn lift_in_context(
  ctx : @mc.Context,
  insn : @mc.Insn,
) -> @mc.Lifted raise @mc.LiftError {
  let thumb = ctx.encoding == @core_theory.Language::llvm_t32()
  guard is_thumb2(insn.name) == thumb && Insn::of_name(insn.name) is Some(_) else {
    raise Unsupported(opcode=insn.name, target=ctx.target.to_string())
  }
  let (encoding, raw) : (Encoding, UInt?) = if thumb {
    (T32, None)
  } else {
    (A32, raw_word(insn))
  }
  let bil = lift(insn, encoding~, raw?)
  let dest_encoding = if !thumb && insn.name == "BLXi" {
    Some(@core_theory.Language::llvm_t32())
  } else {
    None
  }
  @mc.Lifted::create(bil, dest_encoding?)
}

///|
/// The ARM lifter provider (see `accepts` and `lift_in_context`).
pub fn provider() -> @mc.Provider {
  @mc.Provider::create(provider_name, accepts~, lift=lift_in_context)
}

///|
/// Register the ARM provider with `registry` (the global `@mc` registry by
/// default). Idempotent: the provider is replaced by name. To lift Thumb
/// code, register the `thumb` provider first so that Thumb-1 opcodes reach
/// it before this provider (which handles Thumb-2 ones).
pub fn register(registry? : @mc.Registry = @mc.Registry::global()) -> Unit {
  registry.register(provider())
}
