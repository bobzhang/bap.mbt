// Port of BAP `lib/x86_cpu/x86_types.ml`: the intermediate representation
// produced by the legacy byte-level decoder (`x86_disasm.ml`) and consumed by
// the legacy lifter (`x86_lifter.ml`).

///|
/// Processor mode of the legacy decoder and lifter (upstream
/// `X86_types.mode`): 32-bit protected mode (`X86`) or 64-bit long mode
/// (`X8664`).
pub(all) enum Mode {
  X86
  X8664
} derive(Eq, Debug)

///|
pub extend Mode with Eq::{equal, not_equal}

///|
pub extend Mode with Debug::{to_repr}

///|
/// Width in bits of the general purpose registers and of addresses in the
/// mode (upstream `width_of_mode`).
pub fn Mode::width(self : Mode) -> Int32 {
  match self {
    X86 => 32
    X8664 => 64
  }
}

///|
/// An immediate value, as the BAP `Word.t` values of the legacy decoder:
/// the bits, a width and a signedness flag. The signedness only matters
/// when the immediate is resized (`Imm::resize`): signed immediates are
/// sign-extended, unsigned ones zero-extended, like BAP `Word.extract`.
priv struct Imm {
  bits : UInt64
  width : Int32
  signed : Bool
} derive(Eq, Debug)

///|
/// Operands of the decoded instructions (upstream `X86_types.operand`).
priv enum Operand {
  /// general purpose register by number (0-15)
  Oreg(Int32)
  /// vector (XMM/YMM) register by number
  Ovec(Int32)
  /// segment register by number
  Oseg(Int32)
  /// memory reference by effective address
  Oaddr(@types.Exp)
  /// immediate
  Oimm(Imm)
} derive(Eq, Debug)

///|
priv enum JumpTarget {
  Jabs(Operand)
  /// next instruction address and offset
  Jrel(Imm, Imm)
} derive(Debug)

///|
priv enum Order {
  Low
  High
} derive(Debug)

///|
priv enum Direction {
  Forward
  Backward
} derive(Eq, Debug)

///|
/// Element operations of packed instructions (upstream passes OCaml
/// closures of type `binopf`).
priv enum PackedOp {
  PBin(@types.BinOp)
  PMin(Bool)
  PMax(Bool)
  PAvg(Int32)
  PAndN
} derive(Debug)

///|
/// `Pcmpstr.imm8cb`: the decoded immediate control byte of PCMPxSTRx.
priv struct Imm8cb {
  words : Bool
  signed : Bool
  /// 0 = equal any, 1 = ranges, 2 = equal each, 3 = equal ordered
  agg : Int32
  negintres1 : Bool
  maskintres1 : Bool
  /// `MSB` output selection (otherwise `LSB`)
  msb : Bool
} derive(Debug)

///|
/// `Pcmpstr.pcmpinfo`: whether the instruction outputs an index (or a
/// mask) and whether string lengths are implicit (or explicit).
priv struct PcmpInfo {
  index : Bool
  implicit : Bool
} derive(Debug)

///|
/// `offsetinfo`: a source slice of `Movoffset`.
priv struct OffsetInfo {
  offlen : Int32
  offtyp : Int32
  offop : Operand
  offsrcoffset : Int32
  offdstoffset : Int32
} derive(Debug)

///|
/// Decoded instructions (upstream `X86_types.opcode`). Types are bit
/// widths.
#warnings("-unused_value")
priv enum Opcode {
  Bswap(Int32, Operand)
  /// bytes to release, far return
  Retn((Int32, Operand)?, Bool)
  Nop
  /// type, dst, src, condition
  Mov(Int32, Operand, Operand, @types.Exp?)
  Movs(Int32)
  /// dst type, dst, src type, src
  Movzx(Int32, Operand, Int32, Operand)
  Movsx(Int32, Operand, Int32, Operand)
  /// dst type, dst, src type, src, aligned
  Movdq(Int32, Operand, Int32, Operand, Bool)
  Movoffset((Int32, Operand), Array[OffsetInfo])
  Lea(Int32, Operand, @types.Exp)
  /// target, return address
  Call(Operand, Imm)
  Shift(@types.BinOp, Int32, Operand, Operand)
  Shiftd(@types.BinOp, Int32, Operand, Operand, Operand)
  /// direction, type, dst, count, through carry
  Rotate(@types.BinOp, Int32, Operand, Operand, Bool)
  /// kind (the ModR/M reg field of `0f ba`: 4 BT, 5 BTS, 6 BTR, 7 BTC),
  /// type, bit offset, bit base
  Bt(Int32, Int32, Operand, Operand)
  Bs(Int32, Operand, Operand, Direction)
  Jump(JumpTarget)
  Jcc(JumpTarget, @types.Exp)
  Setcc(Int32, Operand, @types.Exp)
  Hlt
  Cmps(Int32)
  Scas(Int32)
  Stos(Int32)
  Push(Int32, Operand)
  Pop(Int32, Operand)
  Pushf(Int32)
  Popf(Int32)
  /// size, src, dst
  Popcnt(Int32, Operand, Operand)
  Sahf
  Lahf
  Add(Int32, Operand, Operand)
  Adc(Int32, Operand, Operand)
  Inc(Int32, Operand)
  Dec(Int32, Operand)
  Sub(Int32, Operand, Operand)
  Sbb(Int32, Operand, Operand)
  Cmp(Int32, Operand, Operand)
  Cmpxchg(Int32, Operand, Operand)
  /// CMPXCHG8B (64) or CMPXCHG16B (128)
  Cmpxchg8b(Int32, Operand)
  Xadd(Int32, Operand, Operand)
  Xchg(Int32, Operand, Operand)
  And(Int32, Operand, Operand)
  Or(Int32, Operand, Operand)
  Xor(Int32, Operand, Operand)
  Test(Int32, Operand, Operand)
  Ptest(Int32, Operand, Operand)
  Not(Int32, Operand)
  Neg(Int32, Operand)
  Mul(Int32, Operand)
  /// type, (one operand form, dst), src1, src2
  Imul(Int32, (Bool, Operand), Operand, Operand)
  Div(Int32, Operand)
  Idiv(Int32, Operand)
  Cld
  Rdtsc
  Cpuid
  Xgetbv
  Stmxcsr(Operand)
  Ldmxcsr(Operand)
  Fnstcw(Operand)
  Fldcw(Operand)
  Fld(Operand)
  Fst(Operand, Bool)
  /// dest size, element size, order, dest, src, VEX src
  Punpck(Int32, Int32, Order, Operand, Operand, Operand?)
  Ppackedbinop(Int32, Int32, PackedOp, String, Operand, Operand, Operand?)
  Pbinop(Int32, PackedOp, String, Operand, Operand, Operand?)
  /// dest size, dest element size, source element size, dst, src, signed
  Pmov(Int32, Int32, Int32, Operand, Operand, Bool, String)
  Pmovmskb(Int32, Operand, Operand)
  Pcmp(Int32, Int32, @types.BinOp, String, Operand, Operand, Operand?)
  Palignr(Int32, Operand, Operand, Operand?, Operand)
  Pcmpstr(Int32, Operand, Operand, Operand, Imm8cb, PcmpInfo)
  Pshufb(Int32, Operand, Operand, Operand?)
  Pshufd(Int32, Operand, Operand, Operand?, Operand)
  Leave(Int32)
  Interrupt(Operand)
  Interrupt3
  Sysenter
  Syscall
} derive(Debug)

///|
/// The REX prefix (Table 2-4).
priv struct Rex {
  w : Bool
  r : Bool
  x : Bool
  b : Bool
}

///|
/// The VEX prefix.
priv struct Vex {
  nr : Bool
  nx : Bool
  nb : Bool
  map_select : Int32
  we : Bool
  v : Int32
  l : Bool
  pp : Int32
}

///|
/// Decoded prefix information (upstream `X86_types.prefix`); sizes are bit
/// widths.
#warnings("-unused_field")
priv struct Prefix {
  addrsize : Int32
  opsize : Int32
  bopsize : Int32
  mopsize : Int32
  repeat : Bool
  nrepeat : Bool
  addrsize_override : Bool
  opsize_override : Bool
  rex : Rex?
  vex : Vex?
  r_extend : Int32
  rm_extend : Int32
  sib_extend : Int32
}

///|
/// Failures of the legacy decoder and lifter: upstream `No_semantics`
/// (unimplemented instructions, lifted to an empty program upstream) and
/// `Arch_exception` (invalid instructions).
priv suberror X86Error {
  NoSemantics(String)
  ArchException(String)
} derive(Debug)
