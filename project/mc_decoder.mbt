// Project instructions of the instructions decoded by the `@mc` decoders
// (see `@mc.register_decoder` and `ProjectDisassemblyBasic::lookup`).

///|
/// The project instruction of an `@mc.Insn` decoded from `memory` (the
/// inverse of `to_mc_insn`): its name, opcode code, assembly, operands and
/// kinds; its encoding is the name of the instruction encoding.
pub fn ProjectDisassemblyInstruction::of_mc_insn(
  insn : @mc.Insn,
  memory : @memory.Memory,
) -> ProjectDisassemblyInstruction {
  let operands = insn
    .ops()
    .iter()
    .map(op => {
      match op {
        Reg(name~, code~) => ProjectRegisterOperand(code, name)
        Imm(value) => ProjectImmediateOperand(value)
        Fmm(value) => ProjectFloatingOperand(value)
      }
    })
    .collect()
  let encoding = insn.encoding()
  ProjectDisassemblyInstruction::create(
    memory,
    assembly=insn.assembly(),
    code=insn.code(),
    name=insn.name(),
    encoding=if encoding.is_unknown() { "" } else { encoding.to_string() },
    kinds=insn.kinds().iter().map(ProjectInstructionKind::of_mc_kind).collect(),
    operands~,
  )
}
