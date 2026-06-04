///|
fn project_uint64_persistent() -> @knowledge.Persistent[UInt64] {
  @knowledge.Persistent::create(to_string=value => value.to_string(), of_string=input => {
    project_read_persistent_uint64(input)
  })
}

///|
fn project_int64_persistent() -> @knowledge.Persistent[Int64] {
  @knowledge.Persistent::create(to_string=value => value.to_string(), of_string=input => {
    project_read_persistent_int64(input)
  })
}

///|
fn project_double_persistent() -> @knowledge.Persistent[Double] {
  @knowledge.Persistent::create(to_string=value => value.to_string(), of_string=input => {
    project_read_persistent_double(input)
  })
}

///|
fn project_memory_region_persistent() -> @knowledge.Persistent[@memory.Memory] {
  let bytes_codec = @knowledge.Persistent::bytes()
  @knowledge.Persistent::convert(
    to_persistent=memory => {
      [
        project_persistent_endian(memory.endian()),
        memory.min_addr().to_string(),
        bytes_codec.encode(memory.to_bytes()),
      ]
    },
    of_persistent=fields => {
      if fields.length() != 3 {
        return Err("invalid persistent project memory region")
      }
      let endian = match project_read_persistent_endian(fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let start = match project_read_persistent_uint64(fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let data = match bytes_codec.decode(fields[2]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(@memory.Memory::from_bytes(endian~, start~, data))
    },
    project_ir_fields(),
  )
}

///|
fn project_instruction_kind_persistent() -> @knowledge.Persistent[
  ProjectInstructionKind,
] {
  @knowledge.Persistent::create(to_string=kind => kind.to_string(), of_string=input => {
    match input {
      "conditional-branch" => Ok(ProjectConditionalBranch)
      "unconditional-branch" => Ok(ProjectUnconditionalBranch)
      "indirect-branch" => Ok(ProjectIndirectBranch)
      "return" => Ok(ProjectReturn)
      "call" => Ok(ProjectCall)
      "barrier" => Ok(ProjectBarrier)
      "terminator" => Ok(ProjectTerminator)
      "may-affect-control-flow" => Ok(ProjectMayAffectControlFlow)
      "may-load" => Ok(ProjectMayLoad)
      "may-store" => Ok(ProjectMayStore)
      _ => Err("invalid persistent project instruction kind")
    }
  })
}

///|
fn project_instruction_operand_persistent() -> @knowledge.Persistent[
  ProjectInstructionOperand,
] {
  let int_codec = @knowledge.Persistent::int()
  let int64_codec = project_int64_persistent()
  let double_codec = project_double_persistent()
  @knowledge.Persistent::convert(
    to_persistent=operand => {
      match operand {
        ProjectRegisterOperand(code, name) =>
          ["register", int_codec.encode(code), name]
        ProjectImmediateOperand(value) =>
          ["immediate", int64_codec.encode(value)]
        ProjectFloatingOperand(value) =>
          ["floating", double_codec.encode(value)]
      }
    },
    of_persistent=fields => {
      match fields {
        ["register", code_text, name] => {
          let code = match int_codec.decode(code_text) {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          Ok(ProjectRegisterOperand(code, name))
        }
        ["immediate", value_text] => {
          let value = match int64_codec.decode(value_text) {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          Ok(ProjectImmediateOperand(value))
        }
        ["floating", value_text] => {
          let value = match double_codec.decode(value_text) {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          Ok(ProjectFloatingOperand(value))
        }
        _ => Err("invalid persistent project instruction operand")
      }
    },
    project_ir_fields(),
  )
}

///|
fn project_disassembly_edge_kind_persistent() -> @knowledge.Persistent[
  ProjectDisassemblyEdgeKind,
] {
  @knowledge.Persistent::create(to_string=kind => kind.to_string(), of_string=input => {
    match input {
      "jump" => Ok(JumpEdge)
      "cond" => Ok(CondEdge)
      "fall" => Ok(FallEdge)
      _ => Err("invalid persistent project disassembly edge kind")
    }
  })
}

///|
fn project_disassembly_edge_persistent() -> @knowledge.Persistent[
  ProjectDisassemblyEdge,
] {
  let uint64_codec = project_uint64_persistent()
  let target_codec = @knowledge.Persistent::optional(uint64_codec)
  let kind_codec = project_disassembly_edge_kind_persistent()
  @knowledge.Persistent::convert(
    to_persistent=edge => {
      [
        uint64_codec.encode(edge.source()),
        target_codec.encode(edge.target()),
        kind_codec.encode(edge.kind()),
      ]
    },
    of_persistent=fields => {
      if fields.length() != 3 {
        return Err("invalid persistent project disassembly edge")
      }
      let source = match uint64_codec.decode(fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let target = match target_codec.decode(fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let kind = match kind_codec.decode(fields[2]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(ProjectDisassemblyEdge::create(source~, target?, kind~))
    },
    project_ir_fields(),
  )
}

///|
fn project_disassembly_instruction_persistent() -> @knowledge.Persistent[
  ProjectDisassemblyInstruction,
] {
  @knowledge.Persistent::create(
    to_string=instruction => {
      project_ir_fields().encode(
        project_disassembly_instruction_fields(instruction),
      )
    },
    of_string=input => {
      match project_ir_fields().decode(input) {
        Ok(fields) => project_disassembly_instruction_of_fields(fields)
        Err(reason) => Err(reason)
      }
    },
  )
}

///|
fn project_disassembly_instruction_fields(
  instruction : ProjectDisassemblyInstruction,
) -> Array[String] {
  let memory_codec = project_memory_region_persistent()
  let int_codec = @knowledge.Persistent::int()
  let kinds_codec = @knowledge.Persistent::array(
    project_instruction_kind_persistent(),
  )
  let operands_codec = @knowledge.Persistent::array(
    project_instruction_operand_persistent(),
  )
  let subinstructions_codec = @knowledge.Persistent::array(
    project_disassembly_instruction_persistent(),
  )
  [
    memory_codec.encode(instruction.memory()),
    int_codec.encode(instruction.code()),
    instruction.name(),
    instruction.encoding(),
    instruction.assembly(),
    instruction.bil(),
    kinds_codec.encode(instruction.kinds()),
    operands_codec.encode(instruction.operands()),
    subinstructions_codec.encode(instruction.subinstructions()),
  ]
}

///|
fn project_disassembly_instruction_of_fields(
  fields : Array[String],
) -> Result[ProjectDisassemblyInstruction, String] {
  if fields.length() != 9 {
    return Err("invalid persistent project disassembly instruction")
  }
  let memory_codec = project_memory_region_persistent()
  let int_codec = @knowledge.Persistent::int()
  let kinds_codec = @knowledge.Persistent::array(
    project_instruction_kind_persistent(),
  )
  let operands_codec = @knowledge.Persistent::array(
    project_instruction_operand_persistent(),
  )
  let subinstructions_codec = @knowledge.Persistent::array(
    project_disassembly_instruction_persistent(),
  )
  let memory = match memory_codec.decode(fields[0]) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let code = match int_codec.decode(fields[1]) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let kinds = match kinds_codec.decode(fields[6]) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let operands = match operands_codec.decode(fields[7]) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let subinstructions = match subinstructions_codec.decode(fields[8]) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok(
    ProjectDisassemblyInstruction::create(
      memory,
      assembly=fields[4],
      bil=fields[5],
      code~,
      name=fields[2],
      encoding=fields[3],
      kinds~,
      operands~,
      subinstructions~,
    ),
  )
}

///|
pub fn ProjectDisassemblyState::persistent() -> @knowledge.Persistent[
  ProjectDisassemblyState,
] {
  let blocks_codec = @knowledge.Persistent::array(
    project_memory_region_persistent(),
  )
  let instructions_codec = @knowledge.Persistent::array(
    project_disassembly_instruction_persistent(),
  )
  let edges_codec = @knowledge.Persistent::array(
    project_disassembly_edge_persistent(),
  )
  @knowledge.Persistent::convert(
    to_persistent=state => {
      [
        blocks_codec.encode(state.blocks()),
        instructions_codec.encode(state.instructions()),
        edges_codec.encode(state.edges()),
      ]
    },
    of_persistent=fields => {
      if fields.length() != 3 {
        return Err("invalid persistent project disassembly state")
      }
      let blocks = match blocks_codec.decode(fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let instructions = match instructions_codec.decode(fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let edges = match edges_codec.decode(fields[2]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(ProjectDisassemblyState::create(blocks~, instructions~, edges~))
    },
    project_ir_fields(),
  )
}

///|
pub fn ProjectState::persistent() -> @knowledge.Persistent[ProjectState] {
  let disassembly_codec = ProjectDisassemblyState::persistent()
  let subroutines_codec = @knowledge.Persistent::array(project_sub_persistent())
  @knowledge.Persistent::convert(
    to_persistent=state => {
      [
        disassembly_codec.encode(state.disassembly()),
        subroutines_codec.encode(state.subroutines()),
      ]
    },
    of_persistent=fields => {
      if fields.length() != 2 {
        return Err("invalid persistent project state")
      }
      let disassembly = match disassembly_codec.decode(fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let subroutines = match subroutines_codec.decode(fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(ProjectState::create(disassembly~, subroutines~))
    },
    project_ir_fields(),
  )
}
