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
pub fn Mode::width(self : Mode) -> Int {
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
  width : Int
  signed : Bool
} derive(Eq, Debug)

///|
/// Operands of the decoded instructions (upstream `X86_types.operand`).
priv enum Operand {
  /// general purpose register by number (0-15)
  Oreg(Int)
  /// vector (XMM/YMM) register by number
  Ovec(Int)
  /// segment register by number
  Oseg(Int)
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
  PAvg(Int)
  PAndN
} derive(Debug)

///|
/// `Pcmpstr.imm8cb`: the decoded immediate control byte of PCMPxSTRx.
priv struct Imm8cb {
  words : Bool
  signed : Bool
  /// 0 = equal any, 1 = ranges, 2 = equal each, 3 = equal ordered
  agg : Int
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
  offlen : Int
  offtyp : Int
  offop : Operand
  offsrcoffset : Int
  offdstoffset : Int
} derive(Debug)

///|
/// Decoded instructions (upstream `X86_types.opcode`). Types are bit
/// widths.
#warnings("-unused_value")
priv enum Opcode {
  Bswap(Int, Operand)
  /// bytes to release, far return
  Retn((Int, Operand)?, Bool)
  Nop
  /// type, dst, src, condition
  Mov(Int, Operand, Operand, @types.Exp?)
  Movs(Int)
  /// dst type, dst, src type, src
  Movzx(Int, Operand, Int, Operand)
  Movsx(Int, Operand, Int, Operand)
  /// dst type, dst, src type, src, aligned
  Movdq(Int, Operand, Int, Operand, Bool)
  Movoffset((Int, Operand), Array[OffsetInfo])
  Lea(Int, Operand, @types.Exp)
  /// target, return address
  Call(Operand, Imm)
  Shift(@types.BinOp, Int, Operand, Operand)
  Shiftd(@types.BinOp, Int, Operand, Operand, Operand)
  /// direction, type, dst, count, through carry
  Rotate(@types.BinOp, Int, Operand, Operand, Bool)
  /// kind (the ModR/M reg field of `0f ba`: 4 BT, 5 BTS, 6 BTR, 7 BTC),
  /// type, bit offset, bit base
  Bt(Int, Int, Operand, Operand)
  Bs(Int, Operand, Operand, Direction)
  Jump(JumpTarget)
  Jcc(JumpTarget, @types.Exp)
  Setcc(Int, Operand, @types.Exp)
  Hlt
  Cmps(Int)
  Scas(Int)
  Stos(Int)
  Push(Int, Operand)
  Pop(Int, Operand)
  Pushf(Int)
  Popf(Int)
  /// size, src, dst
  Popcnt(Int, Operand, Operand)
  Sahf
  Lahf
  Add(Int, Operand, Operand)
  Adc(Int, Operand, Operand)
  Inc(Int, Operand)
  Dec(Int, Operand)
  Sub(Int, Operand, Operand)
  Sbb(Int, Operand, Operand)
  Cmp(Int, Operand, Operand)
  Cmpxchg(Int, Operand, Operand)
  /// CMPXCHG8B (64) or CMPXCHG16B (128)
  Cmpxchg8b(Int, Operand)
  Xadd(Int, Operand, Operand)
  Xchg(Int, Operand, Operand)
  And(Int, Operand, Operand)
  Or(Int, Operand, Operand)
  Xor(Int, Operand, Operand)
  Test(Int, Operand, Operand)
  Ptest(Int, Operand, Operand)
  Not(Int, Operand)
  Neg(Int, Operand)
  Mul(Int, Operand)
  /// type, (one operand form, dst), src1, src2
  Imul(Int, (Bool, Operand), Operand, Operand)
  Div(Int, Operand)
  Idiv(Int, Operand)
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
  Punpck(Int, Int, Order, Operand, Operand, Operand?)
  Ppackedbinop(Int, Int, PackedOp, String, Operand, Operand, Operand?)
  Pbinop(Int, PackedOp, String, Operand, Operand, Operand?)
  /// dest size, dest element size, source element size, dst, src, signed
  Pmov(Int, Int, Int, Operand, Operand, Bool, String)
  Pmovmskb(Int, Operand, Operand)
  Pcmp(Int, Int, @types.BinOp, String, Operand, Operand, Operand?)
  Palignr(Int, Operand, Operand, Operand?, Operand)
  Pcmpstr(Int, Operand, Operand, Operand, Imm8cb, PcmpInfo)
  Pshufb(Int, Operand, Operand, Operand?)
  Pshufd(Int, Operand, Operand, Operand?, Operand)
  Leave(Int)
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
  map_select : Int
  we : Bool
  v : Int
  l : Bool
  pp : Int
}

///|
/// Decoded prefix information (upstream `X86_types.prefix`); sizes are bit
/// widths.
#warnings("-unused_field")
priv struct Prefix {
  addrsize : Int
  opsize : Int
  bopsize : Int
  mopsize : Int
  repeat : Bool
  nrepeat : Bool
  addrsize_override : Bool
  opsize_override : Bool
  rex : Rex?
  vex : Vex?
  r_extend : Int
  rm_extend : Int
  sib_extend : Int
}

///|
/// Failures of the legacy decoder and lifter: upstream `No_semantics`
/// (unimplemented instructions, lifted to an empty program upstream) and
/// `Arch_exception` (invalid instructions).
priv suberror X86Error {
  NoSemantics(String)
  ArchException(String)
} derive(Debug)
