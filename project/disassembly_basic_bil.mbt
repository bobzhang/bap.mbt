///|
fn project_basic_bil_addr_text(addr : UInt64) -> String {
  "0x" + addr.to_string(radix=16)
}

///|
fn project_basic_bil_word(
  value : UInt64,
  width : Int,
) -> Result[@types.Word, String] {
  try @types.Word::of_uint64(width~, value) catch {
    _ => Err("unable to create \{width}-bit BIL word")
  } noraise {
    word => Ok(word)
  }
}

///|
fn project_basic_bil_int(
  value : Int64,
  width : Int,
) -> Result[@types.Exp, String] {
  try @types.Word::of_int64(value, width~) catch {
    _ => Err("unable to create \{width}-bit BIL immediate")
  } noraise {
    word => Ok(@types.Exp::int(word))
  }
}

///|
fn project_basic_bil_addr_with_width(
  value : UInt64,
  width : Int,
) -> Result[@types.Exp, String] {
  match project_basic_bil_word(value, width) {
    Ok(word) => Ok(@types.Exp::int(word))
    Err(reason) => Err(reason)
  }
}

///|
fn project_basic_bil_reg(name : String, width : Int) -> @types.Var {
  @types.Var::new(name=name.to_upper(), typ=Imm(width))
}

///|
fn project_basic_bil_arm_mem() -> @types.Var {
  @types.Var::new(name="mem", typ=Mem(addr_width=32, value_width=8))
}

///|
fn project_basic_bil_stack_mem(width : Int) -> @types.Var {
  @types.Var::new(name="mem", typ=Mem(addr_width=width, value_width=8))
}

///|
fn project_basic_bil_stack_pointer(width : Int) -> Result[@types.Var, String] {
  match width {
    32 => Ok(project_basic_bil_reg("ESP", 32))
    64 => Ok(project_basic_bil_reg("RSP", 64))
    _ => Err("unsupported stack width \{width}")
  }
}

///|
fn project_basic_bil_stack_offset(
  sp : @types.Var,
  width : Int,
  op : @types.BinOp,
) -> Result[@types.Exp, String] {
  match project_basic_bil_int((width / 8).to_int64(), width) {
    Ok(offset) => Ok(@types.Exp::binop(op, @types.Exp::var_exp(sp), offset))
    Err(reason) => Err(reason)
  }
}

///|
fn project_basic_bil_stack_decrement(
  sp : @types.Var,
  width : Int,
) -> Result[@types.Exp, String] {
  project_basic_bil_stack_offset(sp, width, @types.BinOp::minus())
}

///|
fn project_basic_bil_stack_increment(
  sp : @types.Var,
  width : Int,
) -> Result[@types.Exp, String] {
  project_basic_bil_stack_offset(sp, width, @types.BinOp::plus())
}

///|
fn project_basic_bil_arm_ne_flag() -> @types.Var {
  @types.Var::new(name="ARM.NE", typ=Imm(1))
}

///|
fn project_basic_bil_arm_offset_addr(
  base : @types.Var,
  offset : Int64,
) -> Result[@types.Exp, String] {
  let base_exp = @types.Exp::var_exp(base)
  if offset == 0L {
    Ok(base_exp)
  } else if offset > 0L {
    match project_basic_bil_int(offset, 32) {
      Ok(rhs) => Ok(@types.Exp::binop(@types.BinOp::plus(), base_exp, rhs))
      Err(reason) => Err(reason)
    }
  } else {
    match project_basic_bil_int(-offset, 32) {
      Ok(rhs) => Ok(@types.Exp::binop(@types.BinOp::minus(), base_exp, rhs))
      Err(reason) => Err(reason)
    }
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_operand(
  self : ProjectDisassemblyInstruction,
  index : Int,
) -> Result[ProjectInstructionOperand, String] {
  match self.operands_value.get(index) {
    Some(operand) => Ok(operand)
    None => Err("instruction \{self.name()} is missing operand \{index}")
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_register(
  self : ProjectDisassemblyInstruction,
  index : Int,
  width : Int,
) -> Result[@types.Var, String] {
  match self.project_basic_bil_operand(index) {
    Ok(operand) =>
      match operand.register_name() {
        Some(name) => Ok(project_basic_bil_reg(name, width))
        None =>
          Err("instruction \{self.name()} operand \{index} is not a register")
      }
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_immediate(
  self : ProjectDisassemblyInstruction,
  index : Int,
) -> Result[Int64, String] {
  match self.project_basic_bil_operand(index) {
    Ok(operand) =>
      match operand.to_int64() {
        Some(value) => Ok(value)
        None =>
          Err("instruction \{self.name()} operand \{index} is not an immediate")
      }
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_binop_ri(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  match self.project_basic_bil_register(0, width) {
    Ok(dst) =>
      match self.project_basic_bil_register(1, width) {
        Ok(src) =>
          match self.project_basic_bil_immediate(2) {
            Ok(imm) =>
              match project_basic_bil_int(imm, width) {
                Ok(rhs) =>
                  Ok([
                    @types.Stmt::move_stmt(
                      dst,
                      @types.Exp::binop(op, @types.Exp::var_exp(src), rhs),
                    ),
                  ])
                Err(reason) => Err(reason)
              }
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_incdec(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  match self.project_basic_bil_register(0, width) {
    Ok(dst) =>
      match project_basic_bil_int(1L, width) {
        Ok(one) =>
          Ok([
            @types.Stmt::move_stmt(
              dst,
              @types.Exp::binop(op, @types.Exp::var_exp(dst), one),
            ),
          ])
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_unop_r(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : @types.UnOp,
) -> Result[Array[@types.Stmt], String] {
  match self.project_basic_bil_register(0, width) {
    Ok(dst) =>
      Ok([
        @types.Stmt::move_stmt(
          dst,
          @types.Exp::unop(op, @types.Exp::var_exp(dst)),
        ),
      ])
    Err(reason) => Err(reason)
  }
}

///|
fn project_basic_bil_register_width(name : String) -> Int {
  if name.has_prefix("R") {
    64
  } else {
    32
  }
}

///|
fn project_basic_bil_offset_addr(
  base : @types.Exp,
  offset : Int64,
  width : Int,
) -> Result[@types.Exp, String] {
  if offset == 0L {
    Ok(base)
  } else if offset > 0L {
    match project_basic_bil_int(offset, width) {
      Ok(rhs) => Ok(@types.Exp::binop(@types.BinOp::plus(), base, rhs))
      Err(reason) => Err(reason)
    }
  } else {
    match project_basic_bil_int(-offset, width) {
      Ok(rhs) => Ok(@types.Exp::binop(@types.BinOp::minus(), base, rhs))
      Err(reason) => Err(reason)
    }
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_memory_addr(
  self : ProjectDisassemblyInstruction,
  base_index : Int,
) -> Result[(@types.Exp, @types.Var, Int), String] {
  let base_name = match self.project_basic_bil_operand(base_index) {
    Ok(operand) =>
      match operand.register_name() {
        Some(name) if name != "Nil" => name
        Some(_) => return Err("instruction \{self.name()} memory base is Nil")
        None =>
          return Err("instruction \{self.name()} memory base is not a register")
      }
    Err(reason) => return Err(reason)
  }
  let address_width = project_basic_bil_register_width(base_name)
  let base = project_basic_bil_reg(base_name, address_width)
  let scale = match self.project_basic_bil_immediate(base_index + 1) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  if scale != 1L && scale != 2L && scale != 4L && scale != 8L {
    return Err("unsupported \{self.name()} memory scale \{scale}")
  }
  let mut addr = @types.Exp::var_exp(base)
  match self.project_basic_bil_operand(base_index + 2) {
    Ok(index_operand) =>
      match index_operand.register_name() {
        Some(index_name) if index_name == "Nil" => ()
        Some(index_name) => {
          let index_width = project_basic_bil_register_width(index_name)
          if index_width != address_width {
            return Err("unsupported \{self.name()} mixed-width memory index")
          }
          let index = project_basic_bil_reg(index_name, address_width)
          let index_exp = @types.Exp::var_exp(index)
          let scaled = if scale == 1L {
            index_exp
          } else {
            match project_basic_bil_int(scale, address_width) {
              Ok(scale_exp) =>
                @types.Exp::binop(@types.BinOp::times(), index_exp, scale_exp)
              Err(reason) => return Err(reason)
            }
          }
          addr = @types.Exp::binop(@types.BinOp::plus(), addr, scaled)
        }
        None =>
          return Err(
            "instruction \{self.name()} memory index is not a register",
          )
      }
    Err(reason) => return Err(reason)
  }
  let displacement = match self.project_basic_bil_immediate(base_index + 3) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  match self.project_basic_bil_operand(base_index + 4) {
    Ok(segment_operand) =>
      match segment_operand.register_name() {
        Some(segment) if segment == "Nil" => ()
        Some(segment) =>
          return Err("unsupported \{self.name()} segment register \{segment}")
        None =>
          return Err(
            "instruction \{self.name()} segment operand is not a register",
          )
      }
    Err(reason) => return Err(reason)
  }
  let addr = match
    project_basic_bil_offset_addr(addr, displacement, address_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok(
    (
      addr,
      @types.Var::new(
        name="mem",
        typ=Mem(addr_width=address_width, value_width=8),
      ),
      address_width,
    ),
  )
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_mov_rm(
  self : ProjectDisassemblyInstruction,
  data_width : Int,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, data_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (addr, mem, _) = match self.project_basic_bil_memory_addr(1) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(data_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok([
    @types.Stmt::move_stmt(
      dst,
      @types.Exp::load(mem=@types.Exp::var_exp(mem), addr~, LittleEndian, size),
    ),
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_mov_mr(
  self : ProjectDisassemblyInstruction,
  data_width : Int,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, _) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = match self.project_basic_bil_register(5, data_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(data_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok([
    @types.Stmt::move_stmt(
      mem,
      @types.Exp::store(
        mem=@types.Exp::var_exp(mem),
        addr~,
        @types.Exp::var_exp(src),
        LittleEndian,
        size,
      ),
    ),
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_lea(
  self : ProjectDisassemblyInstruction,
  data_width : Int,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, data_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (addr, _, address_width) = match self.project_basic_bil_memory_addr(1) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let value = if address_width == data_width {
    addr
  } else {
    @types.Exp::cast(@types.CastKind::low(), data_width, addr)
  }
  Ok([@types.Stmt::move_stmt(dst, value)])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_mov_imm(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  match self.project_basic_bil_register(0, width) {
    Ok(dst) =>
      match self.project_basic_bil_immediate(1) {
        Ok(imm) =>
          match project_basic_bil_int(imm, width) {
            Ok(value) => Ok([@types.Stmt::move_stmt(dst, value)])
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_mov_rr(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  match self.project_basic_bil_register(0, width) {
    Ok(dst) =>
      match self.project_basic_bil_register(1, width) {
        Ok(src) => Ok([@types.Stmt::move_stmt(dst, @types.Exp::var_exp(src))])
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_binop_rr(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  match self.project_basic_bil_register(0, width) {
    Ok(dst) =>
      match self.project_basic_bil_register(1, width) {
        Ok(src) => {
          let rhs = if op == @types.BinOp::bit_xor() && dst == src {
            match project_basic_bil_int(0L, width) {
              Ok(zero) => zero
              Err(reason) => return Err(reason)
            }
          } else {
            @types.Exp::binop(
              op,
              @types.Exp::var_exp(dst),
              @types.Exp::var_exp(src),
            )
          }
          Ok([@types.Stmt::move_stmt(dst, rhs)])
        }
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_push(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let src = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let sp = match project_basic_bil_stack_pointer(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr = match project_basic_bil_stack_decrement(sp, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let updated_sp = match project_basic_bil_stack_decrement(sp, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let mem = project_basic_bil_stack_mem(width)
  Ok([
    @types.Stmt::move_stmt(
      mem,
      @types.Exp::store(
        mem=@types.Exp::var_exp(mem),
        addr~,
        @types.Exp::var_exp(src),
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(sp, updated_sp),
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_pop(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let sp = match project_basic_bil_stack_pointer(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let mem = project_basic_bil_stack_mem(width)
  let stmts = [
    @types.Stmt::move_stmt(
      dst,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=@types.Exp::var_exp(sp),
        LittleEndian,
        size,
      ),
    ),
  ]
  if dst != sp {
    let updated_sp = match project_basic_bil_stack_increment(sp, width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    stmts.push(@types.Stmt::move_stmt(sp, updated_sp))
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_leave(
  _self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let sp = match project_basic_bil_stack_pointer(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let fp = project_basic_bil_reg(if width == 64 { "RBP" } else { "EBP" }, width)
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let updated_sp = match project_basic_bil_stack_increment(sp, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let mem = project_basic_bil_stack_mem(width)
  Ok([
    @types.Stmt::move_stmt(sp, @types.Exp::var_exp(fp)),
    @types.Stmt::move_stmt(
      fp,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=@types.Exp::var_exp(sp),
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(sp, updated_sp),
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_direct_target(
  self : ProjectDisassemblyInstruction,
) -> Result[UInt64, String] {
  match self.project_basic_bil_immediate(0) {
    Ok(displacement) =>
      match
        project_disassembly_basic_add_signed_offset(
          self.addr() + self.memory().length().to_uint64(),
          displacement,
        ) {
        Some(target) => Ok(target)
        None => Err("direct target for \{self.name()} is not representable")
      }
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_absolute_target(
  self : ProjectDisassemblyInstruction,
) -> Result[UInt64, String] {
  match self.project_basic_bil_immediate(0) {
    Ok(target) => Ok(target.reinterpret_as_uint64())
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_call(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  match self.project_basic_bil_direct_target() {
    Ok(target) =>
      project_basic_bil_control_with_width(@types.Stmt::call(), target, width)
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_jump(
  self : ProjectDisassemblyInstruction,
) -> Result[Array[@types.Stmt], String] {
  match self.project_basic_bil_immediate(0) {
    Ok(target) =>
      project_basic_bil_control(
        @types.Stmt::goto(),
        target.reinterpret_as_uint64(),
      )
    Err(reason) => Err(reason)
  }
}

///|
fn project_basic_bil_control_with_width(
  attr : @types.StmtAttribute[String],
  target : UInt64,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  match project_basic_bil_addr_with_width(target, width) {
    Ok(addr_exp) =>
      Ok([
        @types.Stmt::encode(attr, project_basic_bil_addr_text(target)),
        @types.Stmt::jmp(addr_exp),
      ])
    Err(reason) => Err(reason)
  }
}

///|
fn project_basic_bil_control(
  attr : @types.StmtAttribute[String],
  target : UInt64,
) -> Result[Array[@types.Stmt], String] {
  project_basic_bil_control_with_width(attr, target, 64)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_arm_branch(
  self : ProjectDisassemblyInstruction,
  conditional : Bool,
) -> Result[Array[@types.Stmt], String] {
  let target = match self.project_basic_bil_absolute_target() {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let branch = match
    project_basic_bil_control_with_width(@types.Stmt::goto(), target, 32) {
    Ok(stmts) => stmts
    Err(reason) => return Err(reason)
  }
  if conditional {
    Ok([
      @types.Stmt::if_(
        @types.Exp::var_exp(project_basic_bil_arm_ne_flag()),
        branch,
        [],
      ),
    ])
  } else {
    Ok(branch)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_bx(
  self : ProjectDisassemblyInstruction,
) -> Result[Array[@types.Stmt], String] {
  match self.project_basic_bil_register(0, 32) {
    Ok(target) => Ok([@types.Stmt::jmp(@types.Exp::var_exp(target))])
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_arm_addsub(
  self : ProjectDisassemblyInstruction,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, 32) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = match self.project_basic_bil_register(1, 32) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let imm = match self.project_basic_bil_immediate(2) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs = if imm == 0L {
    @types.Exp::var_exp(src)
  } else {
    match project_basic_bil_int(imm, 32) {
      Ok(value) => @types.Exp::binop(op, @types.Exp::var_exp(src), value)
      Err(reason) => return Err(reason)
    }
  }
  Ok([@types.Stmt::move_stmt(dst, rhs)])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_arm_movi(
  self : ProjectDisassemblyInstruction,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, 32) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  match self.project_basic_bil_immediate(1) {
    Ok(imm) =>
      match project_basic_bil_int(imm, 32) {
        Ok(value) => Ok([@types.Stmt::move_stmt(dst, value)])
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_arm_movr(
  self : ProjectDisassemblyInstruction,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, 32) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  match self.project_basic_bil_register(1, 32) {
    Ok(src) => Ok([@types.Stmt::move_stmt(dst, @types.Exp::var_exp(src))])
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_arm_cmp(
  self : ProjectDisassemblyInstruction,
) -> Result[Array[@types.Stmt], String] {
  let lhs = match self.project_basic_bil_register(0, 32) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  match self.project_basic_bil_immediate(1) {
    Ok(imm) =>
      match project_basic_bil_int(imm, 32) {
        Ok(rhs) =>
          Ok([
            @types.Stmt::move_stmt(
              project_basic_bil_arm_ne_flag(),
              @types.Exp::binop(
                @types.BinOp::neq(),
                @types.Exp::var_exp(lhs),
                rhs,
              ),
            ),
          ])
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_arm_load(
  self : ProjectDisassemblyInstruction,
  post_index : Bool,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, 32) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let base = match self.project_basic_bil_register(1, 32) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let offset = match self.project_basic_bil_immediate(2) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let mem = project_basic_bil_arm_mem()
  let addr = if post_index {
    @types.Exp::var_exp(base)
  } else {
    match project_basic_bil_arm_offset_addr(base, offset) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
  }
  let stmts = [
    @types.Stmt::move_stmt(
      dst,
      @types.Exp::load(mem=@types.Exp::var_exp(mem), addr~, LittleEndian, R32),
    ),
  ]
  if post_index && offset != 0L {
    match project_basic_bil_arm_offset_addr(base, offset) {
      Ok(updated) => stmts.push(@types.Stmt::move_stmt(base, updated))
      Err(reason) => return Err(reason)
    }
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_arm_store(
  self : ProjectDisassemblyInstruction,
  pre_writeback : Bool,
) -> Result[Array[@types.Stmt], String] {
  let src = match self.project_basic_bil_register(0, 32) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let base = match self.project_basic_bil_register(1, 32) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let offset = match self.project_basic_bil_immediate(2) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let mem = project_basic_bil_arm_mem()
  let stmts : Array[@types.Stmt] = []
  let addr = if pre_writeback {
    if offset != 0L {
      match project_basic_bil_arm_offset_addr(base, offset) {
        Ok(updated) => stmts.push(@types.Stmt::move_stmt(base, updated))
        Err(reason) => return Err(reason)
      }
    }
    @types.Exp::var_exp(base)
  } else {
    match project_basic_bil_arm_offset_addr(base, offset) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
  }
  stmts.push(
    @types.Stmt::move_stmt(
      mem,
      @types.Exp::store(
        mem=@types.Exp::var_exp(mem),
        addr~,
        @types.Exp::var_exp(src),
        LittleEndian,
        R32,
      ),
    ),
  )
  Ok(stmts)
}

///|
pub fn ProjectDisassemblyInstruction::lift_basic_bil(
  self : ProjectDisassemblyInstruction,
) -> Result[Array[@types.Stmt], String] {
  match self.name().to_upper() {
    "SUB32RI8" => self.project_basic_bil_binop_ri(32, @types.BinOp::minus())
    "ADD32RI8" => self.project_basic_bil_binop_ri(32, @types.BinOp::plus())
    "SUB64RI8" => self.project_basic_bil_binop_ri(64, @types.BinOp::minus())
    "ADD64RI8" => self.project_basic_bil_binop_ri(64, @types.BinOp::plus())
    "OR32RI8" => self.project_basic_bil_binop_ri(32, @types.BinOp::bit_or())
    "OR64RI8" => self.project_basic_bil_binop_ri(64, @types.BinOp::bit_or())
    "AND32RI8" => self.project_basic_bil_binop_ri(32, @types.BinOp::bit_and())
    "AND64RI8" => self.project_basic_bil_binop_ri(64, @types.BinOp::bit_and())
    "XOR32RI8" => self.project_basic_bil_binop_ri(32, @types.BinOp::bit_xor())
    "XOR64RI8" => self.project_basic_bil_binop_ri(64, @types.BinOp::bit_xor())
    "INC32R" => self.project_basic_bil_incdec(32, @types.BinOp::plus())
    "INC64R" => self.project_basic_bil_incdec(64, @types.BinOp::plus())
    "DEC32R" => self.project_basic_bil_incdec(32, @types.BinOp::minus())
    "DEC64R" => self.project_basic_bil_incdec(64, @types.BinOp::minus())
    "NOT32R" => self.project_basic_bil_unop_r(32, @types.UnOp::not())
    "NOT64R" => self.project_basic_bil_unop_r(64, @types.UnOp::not())
    "NEG32R" => self.project_basic_bil_unop_r(32, @types.UnOp::neg())
    "NEG64R" => self.project_basic_bil_unop_r(64, @types.UnOp::neg())
    "SUB32RR" | "SUB32RR_REV" =>
      self.project_basic_bil_binop_rr(32, @types.BinOp::minus())
    "ADD32RR" | "ADD32RR_REV" =>
      self.project_basic_bil_binop_rr(32, @types.BinOp::plus())
    "SUB64RR" | "SUB64RR_REV" =>
      self.project_basic_bil_binop_rr(64, @types.BinOp::minus())
    "ADD64RR" | "ADD64RR_REV" =>
      self.project_basic_bil_binop_rr(64, @types.BinOp::plus())
    "MOV32RM" => self.project_basic_bil_mov_rm(32)
    "MOV64RM" => self.project_basic_bil_mov_rm(64)
    "MOV32MR" => self.project_basic_bil_mov_mr(32)
    "MOV64MR" => self.project_basic_bil_mov_mr(64)
    "LEA32R" => self.project_basic_bil_lea(32)
    "LEA64R" => self.project_basic_bil_lea(64)
    "MOV32RI" => self.project_basic_bil_mov_imm(32)
    "MOV64RI" => self.project_basic_bil_mov_imm(64)
    "MOV32RR" | "MOV32RR_REV" => self.project_basic_bil_mov_rr(32)
    "MOV64RR" | "MOV64RR_REV" => self.project_basic_bil_mov_rr(64)
    "OR32RR" | "OR32RR_REV" =>
      self.project_basic_bil_binop_rr(32, @types.BinOp::bit_or())
    "OR64RR" | "OR64RR_REV" =>
      self.project_basic_bil_binop_rr(64, @types.BinOp::bit_or())
    "AND32RR" | "AND32RR_REV" =>
      self.project_basic_bil_binop_rr(32, @types.BinOp::bit_and())
    "AND64RR" | "AND64RR_REV" =>
      self.project_basic_bil_binop_rr(64, @types.BinOp::bit_and())
    "XOR32RR" | "XOR32RR_REV" =>
      self.project_basic_bil_binop_rr(32, @types.BinOp::bit_xor())
    "XOR64RR" | "XOR64RR_REV" =>
      self.project_basic_bil_binop_rr(64, @types.BinOp::bit_xor())
    "PUSH32R" => self.project_basic_bil_push(32)
    "PUSH64R" => self.project_basic_bil_push(64)
    "POP32R" => self.project_basic_bil_pop(32)
    "POP64R" => self.project_basic_bil_pop(64)
    "LEAVE" => self.project_basic_bil_leave(32)
    "LEAVE64" => self.project_basic_bil_leave(64)
    "NOOP" => Ok([])
    "JMP_1" => self.project_basic_bil_jump()
    "JMP_4" => self.project_basic_bil_jump()
    "CALLPCREL32" => self.project_basic_bil_call(32)
    "CALL64PCREL32" => self.project_basic_bil_call(64)
    "B" => self.project_basic_bil_arm_branch(false)
    "BNE" => self.project_basic_bil_arm_branch(true)
    "BX" => self.project_basic_bil_bx()
    "ADDRI" => self.project_basic_bil_arm_addsub(@types.BinOp::plus())
    "SUBRI" => self.project_basic_bil_arm_addsub(@types.BinOp::minus())
    "MOVI" => self.project_basic_bil_arm_movi()
    "MOVR" => self.project_basic_bil_arm_movr()
    "CMPRI" => self.project_basic_bil_arm_cmp()
    "LDRI12" => self.project_basic_bil_arm_load(false)
    "LDR_POST_IMM" => self.project_basic_bil_arm_load(true)
    "STRI12" => self.project_basic_bil_arm_store(false)
    "STR_PRE_IMM" => self.project_basic_bil_arm_store(true)
    "RET" => Ok([@types.Stmt::special("ret")])
    name => Err("unsupported Basic BIL lift for instruction \{name}")
  }
}

///|
pub fn ProjectDisassemblyState::lift_basic_bil(
  self : ProjectDisassemblyState,
) -> Result[Array[@types.Stmt], String] {
  let result : Array[@types.Stmt] = []
  for instruction in self.instructions() {
    match instruction.lift_basic_bil() {
      Ok(stmts) =>
        for stmt in stmts {
          result.push(stmt)
        }
      Err(reason) =>
        return Err(
          "failed to lift Basic BIL for \{instruction.name()} at 0x\{instruction.addr().to_string(radix=16)}: \{reason}",
        )
    }
  }
  Ok(result)
}

///|
pub fn ProjectDisassemblyBlock::lift_basic_bil(
  self : ProjectDisassemblyBlock,
) -> Result[Array[@types.Stmt], String] {
  let result : Array[@types.Stmt] = []
  for instruction in self.instructions() {
    match instruction.lift_basic_bil() {
      Ok(stmts) =>
        for stmt in stmts {
          result.push(stmt)
        }
      Err(reason) =>
        return Err(
          "failed to lift Basic BIL for \{instruction.name()} at 0x\{instruction.addr().to_string(radix=16)} in block \{self.to_string()}: \{reason}",
        )
    }
  }
  Ok(result)
}

///|
pub fn ProjectDisasm::lift_basic_bil(
  self : ProjectDisasm,
) -> Result[Array[@types.Stmt], String] {
  self.disassembly().lift_basic_bil()
}

///|
pub fn Project::lift_basic_bil(
  self : Project,
) -> Result[Array[@types.Stmt], String] {
  self.disassembly().lift_basic_bil()
}
