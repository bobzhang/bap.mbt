// The kinds of the decoded instructions, as upstream BAP reads them from
// LLVM's `MCInstrDesc` (`llvm_disasm.cpp`): the static properties of the
// opcode (`llvm_descs`, generated from LLVM 22) and `mayAffectControlFlow`,
// which also holds for the instructions that define the `PC`.

///|
const DESC_COND : Int32 = 0x1

///|
const DESC_UNCOND : Int32 = 0x2

///|
const DESC_INDIRECT : Int32 = 0x4

///|
const DESC_RETURN : Int32 = 0x8

///|
const DESC_CALL : Int32 = 0x10

///|
const DESC_BARRIER : Int32 = 0x20

///|
const DESC_TERMINATOR : Int32 = 0x40

///|
/// `isBranch || isCall || isReturn || isIndirectBranch`.
const DESC_AFFECT_CF : Int32 = 0x80

///|
const DESC_MAY_LOAD : Int32 = 0x100

///|
const DESC_MAY_STORE : Int32 = 0x200

///|
/// `variadicOpsAreDefs`: the variadic operands (register lists) are defs.
const DESC_VARIADIC_DEFS : Int32 = 0x400

///|
/// The opcode implicitly defines the `PC`.
const DESC_IMPLICIT_PC : Int32 = 0x800

///|
/// The kinds of the instruction `name` with the operands `ops`, as LLVM's
/// `MCInstrDesc` reports them (`isConditionalBranch`, ..., `mayStore`, and
/// `mayAffectControlFlow`, which holds for branches, calls, returns and the
/// instructions defining the `PC`: one of their first `NumDefs` operands,
/// a variadic operand of an opcode whose variadic operands are defs, or an
/// implicit def). Opcodes unknown to the table have no kinds.
pub fn llvm_kinds(name : String, ops : ArrayView[@mc.Op]) -> Array[@mc.Kind] {
  guard llvm_descs.get(name) is Some((flags, defs, fixed)) else { return [] }
  let kinds : Array[@mc.Kind] = []
  let has = (bit : Int32) => (flags & bit) != 0
  if has(DESC_COND) {
    kinds.push(ConditionalBranch)
  }
  if has(DESC_UNCOND) {
    kinds.push(UnconditionalBranch)
  }
  if has(DESC_INDIRECT) {
    kinds.push(IndirectBranch)
  }
  if has(DESC_RETURN) {
    kinds.push(Return)
  }
  if has(DESC_CALL) {
    kinds.push(Call)
  }
  if has(DESC_BARRIER) {
    kinds.push(Barrier)
  }
  if has(DESC_TERMINATOR) {
    kinds.push(Terminator)
  }
  let is_pc = (op : @mc.Op) => op is Reg(name="PC", ..)
  let defines_pc = has(DESC_IMPLICIT_PC) ||
    ops[:if defs < ops.length() { defs } else { ops.length() }]
    .iter()
    .any(is_pc) ||
    (
      has(DESC_VARIADIC_DEFS) &&
      fixed >= 1 &&
      fixed - 1 < ops.length() &&
      ops[fixed - 1:].iter().any(is_pc)
    )
  if has(DESC_AFFECT_CF) || defines_pc {
    kinds.push(MayAffectControlFlow)
  }
  if has(DESC_MAY_LOAD) {
    kinds.push(MayLoad)
  }
  if has(DESC_MAY_STORE) {
    kinds.push(MayStore)
  }
  kinds
}
