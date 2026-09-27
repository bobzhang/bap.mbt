///|
/// Instruction properties reported by the decoder (upstream
/// `Disasm_expert.Kind.t`, restricted to the members the port models).
/// Mirrors `@project.ProjectInstructionKind`.
pub(all) enum Kind {
  ConditionalBranch
  UnconditionalBranch
  IndirectBranch
  Return
  Call
  Barrier
  Terminator
  MayAffectControlFlow
  MayLoad
  MayStore
} derive(Eq, Debug)

///|
pub extend Kind with Eq::{equal, not_equal}

///|
pub extend Kind with Debug::{to_repr}

///|
/// A decoded instruction as seen by the lifters (upstream `MC.Insn.t`
/// together with its memory): the backend opcode name (LLVM MC style, e.g.
/// `ADDiu`, `ADD4`, `MOVi`) and numeric code, textual assembly, operands,
/// address and size of the instruction, the encoding it was decoded with,
/// its kinds, and the raw encoded bytes.
///
/// Values are immutable: build them with `Insn::create`.
pub struct Insn {
  name : String
  code : Int
  assembly : String
  ops : ReadOnlyArray[Op]
  addr : UInt64
  size : Int
  encoding : @core_theory.Language
  kinds : ReadOnlyArray[Kind]
  raw : Bytes
} derive(Eq, Debug)

///|
pub extend Insn with Eq::{equal, not_equal}

///|
pub extend Insn with Debug::{to_repr}

///|
/// Create an instruction. The address and size are required, since
/// PC-relative semantics and fall-through computation depend on them.
/// `encoding` defaults to `Language::unknown()`, meaning that the lifting
/// context decides it; `raw` may be empty when the encoded bytes are not
/// available (e.g. hand-written fixtures).
pub fn Insn::create(
  name : String,
  ops : ArrayView[Op],
  addr~ : UInt64,
  size~ : Int,
  assembly? : String = "",
  code? : Int = 0,
  encoding? : @core_theory.Language = @core_theory.Language::unknown(),
  kinds? : ArrayView[Kind] = [],
  raw? : Bytes = b"",
) -> Insn {
  {
    name,
    code,
    assembly,
    ops: ReadOnlyArray::from_array(ops.to_owned()),
    addr,
    size,
    encoding,
    kinds: ReadOnlyArray::from_array(kinds.to_owned()),
    raw,
  }
}

///|
/// The opcode name.
pub fn Insn::name(self : Insn) -> String {
  self.name
}

///|
/// The backend-specific numeric opcode (`0` when unknown).
pub fn Insn::code(self : Insn) -> Int {
  self.code
}

///|
/// The textual assembly (may be empty).
pub fn Insn::assembly(self : Insn) -> String {
  self.assembly
}

///|
/// The operands.
pub fn Insn::ops(self : Insn) -> ReadOnlyArray[Op] {
  self.ops
}

///|
/// The address of the instruction.
pub fn Insn::addr(self : Insn) -> UInt64 {
  self.addr
}

///|
/// The size of the instruction in bytes.
pub fn Insn::size(self : Insn) -> Int {
  self.size
}

///|
/// The encoding the instruction was decoded with (`Language::unknown()`
/// when the decoder did not say).
pub fn Insn::encoding(self : Insn) -> @core_theory.Language {
  self.encoding
}

///|
/// The kinds (properties) of the instruction reported by the decoder.
pub fn Insn::kinds(self : Insn) -> ReadOnlyArray[Kind] {
  self.kinds
}

///|
/// Whether the decoder reported the kind `kind`.
pub fn Insn::has_kind(self : Insn, kind : Kind) -> Bool {
  self.kinds.iter().any(k => k == kind)
}

///|
/// The raw encoded bytes (may be empty).
pub fn Insn::raw(self : Insn) -> Bytes {
  self.raw
}

///|
/// The `index`th operand.
pub fn Insn::op(self : Insn, index : Int) -> Op? {
  self.ops.get(index)
}

///|
/// Address of the instruction following this one.
pub fn Insn::next_addr(self : Insn) -> UInt64 {
  self.addr + self.size.to_uint64()
}
