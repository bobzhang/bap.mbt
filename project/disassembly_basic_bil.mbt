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
fn project_basic_bil_virtual(name : String, width : Int) -> @types.Var {
  @types.Var::new(name~, typ=Imm(width), is_virtual=true)
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
fn project_basic_bil_x86_flag_var(name : String) -> @types.Var {
  project_basic_bil_reg(name, 1)
}

///|
fn project_basic_bil_x86_flag(name : String) -> @types.Exp {
  @types.Exp::var_exp(project_basic_bil_x86_flag_var(name))
}

///|
fn project_basic_bil_x86_flag_move(
  name : String,
  value : @types.Exp,
) -> @types.Stmt {
  @types.Stmt::move_stmt(project_basic_bil_x86_flag_var(name), value)
}

///|
fn project_basic_bil_x86_flag_assign(
  name : String,
  value : Int64,
) -> Result[Array[@types.Stmt], String] {
  match project_basic_bil_int(value, 1) {
    Ok(imm) => Ok([project_basic_bil_x86_flag_move(name, imm)])
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_cpuexn(
  self : ProjectDisassemblyInstruction,
) -> Result[Array[@types.Stmt], String] {
  let code = if self.name().to_upper() == "INT3" {
    3
  } else {
    match self.project_basic_bil_immediate(0) {
      Ok(value) =>
        match @types.int_of_int64(value) {
          Ok(code) => code
          Err(reason) => return Err(reason)
        }
      Err(reason) => return Err(reason)
    }
  }
  Ok([@types.Stmt::cpuexn(code)])
}

///|
fn project_basic_bil_x86_unknown_regs(
  source : String,
  registers : Array[String],
) -> Array[@types.Stmt] {
  let stmts : Array[@types.Stmt] = []
  for register in registers {
    stmts.push(
      @types.Stmt::move_stmt(
        project_basic_bil_reg(register, 32),
        @types.Exp::unknown(source, Imm(32)),
      ),
    )
  }
  stmts
}

///|
fn project_basic_bil_x86_or(
  left : @types.Exp,
  right : @types.Exp,
) -> @types.Exp {
  @types.Exp::binop(@types.BinOp::bit_or(), left, right)
}

///|
fn project_basic_bil_x86_xor(
  left : @types.Exp,
  right : @types.Exp,
) -> @types.Exp {
  @types.Exp::binop(@types.BinOp::bit_xor(), left, right)
}

///|
fn project_basic_bil_x86_not(exp : @types.Exp) -> @types.Exp {
  @types.Exp::unop(@types.UnOp::not(), exp)
}

///|
fn project_basic_bil_x86_parity(
  result : @types.Exp,
  width : Int,
) -> Result[@types.Exp, String] {
  let four = match project_basic_bil_int(4L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let two = match project_basic_bil_int(2L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let one = match project_basic_bil_int(1L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let tmp1 = project_basic_bil_virtual("parity_tmp1", width)
  let tmp2 = project_basic_bil_virtual("parity_tmp2", width)
  let first = project_basic_bil_x86_xor(
    @types.Exp::binop(@types.BinOp::rshift(), result, four),
    result,
  )
  let second = project_basic_bil_x86_xor(
    @types.Exp::binop(@types.BinOp::rshift(), @types.Exp::var_exp(tmp1), two),
    @types.Exp::var_exp(tmp1),
  )
  let third = project_basic_bil_x86_xor(
    @types.Exp::binop(@types.BinOp::rshift(), @types.Exp::var_exp(tmp2), one),
    @types.Exp::var_exp(tmp2),
  )
  Ok(
    project_basic_bil_x86_not(
      @types.Exp::cast(
        @types.CastKind::low(),
        1,
        @types.Exp::let_(tmp1, first, @types.Exp::let_(tmp2, second, third)),
      ),
    ),
  )
}

///|
fn project_basic_bil_x86_sub_flag_moves(
  lhs : @types.Exp,
  rhs : @types.Exp,
  result : @types.Exp,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let zero = match project_basic_bil_int(0L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let parity = match project_basic_bil_x86_parity(result, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let lhs_xor_rhs = project_basic_bil_x86_xor(lhs, rhs)
  let lhs_xor_result = project_basic_bil_x86_xor(lhs, result)
  Ok([
    project_basic_bil_x86_flag_move(
      "CF",
      @types.Exp::binop(@types.BinOp::lt(), lhs, rhs),
    ),
    project_basic_bil_x86_flag_move(
      "OF",
      @types.Exp::cast(
        @types.CastKind::high(),
        1,
        @types.Exp::binop(@types.BinOp::bit_and(), lhs_xor_rhs, lhs_xor_result),
      ),
    ),
    project_basic_bil_x86_flag_move(
      "AF",
      @types.Exp::extract(
        project_basic_bil_x86_xor(project_basic_bil_x86_xor(result, lhs), rhs),
        hi=4,
        lo=4,
      ),
    ),
    project_basic_bil_x86_flag_move("PF", parity),
    project_basic_bil_x86_flag_move(
      "SF",
      @types.Exp::cast(@types.CastKind::high(), 1, result),
    ),
    project_basic_bil_x86_flag_move(
      "ZF",
      @types.Exp::binop(@types.BinOp::eq(), zero, result),
    ),
  ])
}

///|
fn project_basic_bil_x86_test_flag_moves(
  result : @types.Exp,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let zero = match project_basic_bil_int(0L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let zero_flag = match project_basic_bil_int(0L, 1) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let parity = match project_basic_bil_x86_parity(result, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok([
    project_basic_bil_x86_flag_move("CF", zero_flag),
    project_basic_bil_x86_flag_move("OF", zero_flag),
    project_basic_bil_x86_flag_move(
      "AF",
      @types.Exp::unknown("AF undefined after TEST", Imm(1)),
    ),
    project_basic_bil_x86_flag_move("PF", parity),
    project_basic_bil_x86_flag_move(
      "SF",
      @types.Exp::cast(@types.CastKind::high(), 1, result),
    ),
    project_basic_bil_x86_flag_move(
      "ZF",
      @types.Exp::binop(@types.BinOp::eq(), zero, result),
    ),
  ])
}

///|
fn project_basic_bil_x86_jcc_condition(mnemonic : String) -> @types.Exp {
  let of = project_basic_bil_x86_flag("OF")
  let cf = project_basic_bil_x86_flag("CF")
  let zf = project_basic_bil_x86_flag("ZF")
  let sf = project_basic_bil_x86_flag("SF")
  let pf = project_basic_bil_x86_flag("PF")
  let sf_xor_of = () => project_basic_bil_x86_xor(sf, of)
  match mnemonic {
    "JO" => of
    "JNO" => project_basic_bil_x86_not(of)
    "JB" => cf
    "JAE" => project_basic_bil_x86_not(cf)
    "JE" => zf
    "JNE" => project_basic_bil_x86_not(zf)
    "JBE" => project_basic_bil_x86_or(cf, zf)
    "JA" => project_basic_bil_x86_not(project_basic_bil_x86_or(cf, zf))
    "JS" => sf
    "JNS" => project_basic_bil_x86_not(sf)
    "JP" => pf
    "JNP" => project_basic_bil_x86_not(pf)
    "JL" => sf_xor_of()
    "JGE" => project_basic_bil_x86_not(sf_xor_of())
    "JLE" => project_basic_bil_x86_or(zf, sf_xor_of())
    _ => project_basic_bil_x86_not(project_basic_bil_x86_or(zf, sf_xor_of()))
  }
}

///|
fn project_basic_bil_x86_setcc_condition(mnemonic : String) -> @types.Exp {
  match mnemonic {
    "SETO" => project_basic_bil_x86_jcc_condition("JO")
    "SETNO" => project_basic_bil_x86_jcc_condition("JNO")
    "SETB" => project_basic_bil_x86_jcc_condition("JB")
    "SETAE" => project_basic_bil_x86_jcc_condition("JAE")
    "SETE" => project_basic_bil_x86_jcc_condition("JE")
    "SETNE" => project_basic_bil_x86_jcc_condition("JNE")
    "SETBE" => project_basic_bil_x86_jcc_condition("JBE")
    "SETA" => project_basic_bil_x86_jcc_condition("JA")
    "SETS" => project_basic_bil_x86_jcc_condition("JS")
    "SETNS" => project_basic_bil_x86_jcc_condition("JNS")
    "SETP" => project_basic_bil_x86_jcc_condition("JP")
    "SETNP" => project_basic_bil_x86_jcc_condition("JNP")
    "SETL" => project_basic_bil_x86_jcc_condition("JL")
    "SETGE" => project_basic_bil_x86_jcc_condition("JGE")
    "SETLE" => project_basic_bil_x86_jcc_condition("JLE")
    _ => project_basic_bil_x86_jcc_condition("JG")
  }
}

///|
fn project_basic_bil_x86_cmov_condition(mnemonic : String) -> @types.Exp {
  if mnemonic.has_prefix("CMOVNO") {
    project_basic_bil_x86_jcc_condition("JNO")
  } else if mnemonic.has_prefix("CMOVAE") {
    project_basic_bil_x86_jcc_condition("JAE")
  } else if mnemonic.has_prefix("CMOVNE") {
    project_basic_bil_x86_jcc_condition("JNE")
  } else if mnemonic.has_prefix("CMOVBE") {
    project_basic_bil_x86_jcc_condition("JBE")
  } else if mnemonic.has_prefix("CMOVNS") {
    project_basic_bil_x86_jcc_condition("JNS")
  } else if mnemonic.has_prefix("CMOVNP") {
    project_basic_bil_x86_jcc_condition("JNP")
  } else if mnemonic.has_prefix("CMOVGE") {
    project_basic_bil_x86_jcc_condition("JGE")
  } else if mnemonic.has_prefix("CMOVLE") {
    project_basic_bil_x86_jcc_condition("JLE")
  } else if mnemonic.has_prefix("CMOVO") {
    project_basic_bil_x86_jcc_condition("JO")
  } else if mnemonic.has_prefix("CMOVB") {
    project_basic_bil_x86_jcc_condition("JB")
  } else if mnemonic.has_prefix("CMOVE") {
    project_basic_bil_x86_jcc_condition("JE")
  } else if mnemonic.has_prefix("CMOVA") {
    project_basic_bil_x86_jcc_condition("JA")
  } else if mnemonic.has_prefix("CMOVS") {
    project_basic_bil_x86_jcc_condition("JS")
  } else if mnemonic.has_prefix("CMOVP") {
    project_basic_bil_x86_jcc_condition("JP")
  } else if mnemonic.has_prefix("CMOVL") {
    project_basic_bil_x86_jcc_condition("JL")
  } else {
    project_basic_bil_x86_jcc_condition("JG")
  }
}

///|
fn project_basic_bil_concat_bits(bits : Array[@types.Exp]) -> @types.Exp {
  let mut result = bits[0]
  for index in 1..<bits.length() {
    result = @types.Exp::concat(result, bits[index])
  }
  result
}

///|
fn project_basic_bil_x86_lahf() -> Array[@types.Stmt] {
  let ah = project_basic_bil_reg("AH", 8)
  let value = project_basic_bil_concat_bits([
    project_basic_bil_x86_flag("SF"),
    project_basic_bil_x86_flag("ZF"),
    @types.Exp::unknown("LAHF bit 5", Imm(1)),
    project_basic_bil_x86_flag("AF"),
    @types.Exp::unknown("LAHF bit 3", Imm(1)),
    project_basic_bil_x86_flag("PF"),
    @types.Exp::unknown("LAHF bit 1", Imm(1)),
    project_basic_bil_x86_flag("CF"),
  ])
  [@types.Stmt::move_stmt(ah, value)]
}

///|
fn project_basic_bil_x86_sahf() -> Array[@types.Stmt] {
  let ah = @types.Exp::var_exp(project_basic_bil_reg("AH", 8))
  [
    project_basic_bil_x86_flag_move("SF", @types.Exp::extract(ah, hi=7, lo=7)),
    project_basic_bil_x86_flag_move("ZF", @types.Exp::extract(ah, hi=6, lo=6)),
    project_basic_bil_x86_flag_move("AF", @types.Exp::extract(ah, hi=4, lo=4)),
    project_basic_bil_x86_flag_move("PF", @types.Exp::extract(ah, hi=2, lo=2)),
    project_basic_bil_x86_flag_move("CF", @types.Exp::extract(ah, hi=0, lo=0)),
  ]
}

///|
fn project_basic_bil_x86_flags_bit(index : Int) -> @types.Exp {
  match index {
    0 => project_basic_bil_x86_flag("CF")
    2 => project_basic_bil_x86_flag("PF")
    4 => project_basic_bil_x86_flag("AF")
    6 => project_basic_bil_x86_flag("ZF")
    7 => project_basic_bil_x86_flag("SF")
    10 => project_basic_bil_x86_flag("DF")
    11 => project_basic_bil_x86_flag("OF")
    _ => @types.Exp::unknown("RFLAGS bit \{index}", Imm(1))
  }
}

///|
fn project_basic_bil_x86_flags_image(width : Int) -> Result[@types.Exp, String] {
  if width != 32 && width != 64 {
    return Err("unsupported PUSHF width \{width}")
  }
  let bits : Array[@types.Exp] = []
  for offset in 0..<width {
    bits.push(project_basic_bil_x86_flags_bit(width - offset - 1))
  }
  Ok(project_basic_bil_concat_bits(bits))
}

///|
fn project_basic_bil_x86_pushf(
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  match project_basic_bil_x86_flags_image(width) {
    Ok(flags) => project_basic_bil_push_exp(flags, width)
    Err(reason) => Err(reason)
  }
}

///|
fn project_basic_bil_x86_popf(
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  if width != 32 && width != 64 {
    return Err("unsupported POPF width \{width}")
  }
  let sp = match project_basic_bil_stack_pointer(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let updated_sp = match project_basic_bil_stack_increment(sp, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let mem = project_basic_bil_stack_mem(width)
  let flags = project_basic_bil_virtual("popf_flags", width)
  let flags_exp = @types.Exp::var_exp(flags)
  let stmts = [
    @types.Stmt::move_stmt(
      flags,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=@types.Exp::var_exp(sp),
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(sp, updated_sp),
  ]
  let flag_bits : Array[(Int, String)] = [
    (11, "OF"),
    (10, "DF"),
    (7, "SF"),
    (6, "ZF"),
    (4, "AF"),
    (2, "PF"),
    (0, "CF"),
  ]
  for entry in flag_bits {
    stmts.push(
      project_basic_bil_x86_flag_move(
        entry.1,
        @types.Exp::extract(flags_exp, hi=entry.0, lo=entry.0),
      ),
    )
  }
  Ok(stmts)
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
fn ProjectDisassemblyInstruction::project_basic_bil_value(
  self : ProjectDisassemblyInstruction,
  index : Int,
  width : Int,
) -> Result[@types.Exp, String] {
  match self.project_basic_bil_operand(index) {
    Ok(operand) =>
      match operand.register_name() {
        Some(name) =>
          Ok(@types.Exp::var_exp(project_basic_bil_reg(name, width)))
        None =>
          match operand.to_int64() {
            Some(value) => project_basic_bil_int(value, width)
            None =>
              Err(
                "instruction \{self.name()} operand \{index} is not a register or immediate",
              )
          }
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
fn ProjectDisassemblyInstruction::project_basic_bil_imul_common(
  self : ProjectDisassemblyInstruction,
  width : Int,
  lhs : @types.Exp,
  rhs : @types.Exp,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let product_width = width * 2
  let tmp = project_basic_bil_virtual("imul_tmp", product_width)
  let tmp_exp = @types.Exp::var_exp(tmp)
  let dst_exp = @types.Exp::var_exp(dst)
  let product = @types.Exp::binop(
    @types.BinOp::times(),
    @types.Exp::cast(@types.CastKind::signed(), product_width, lhs),
    @types.Exp::cast(@types.CastKind::signed(), product_width, rhs),
  )
  let flag = @types.Exp::binop(
    @types.BinOp::neq(),
    tmp_exp,
    @types.Exp::cast(@types.CastKind::signed(), product_width, dst_exp),
  )
  Ok([
    @types.Stmt::move_stmt(tmp, product),
    @types.Stmt::move_stmt(
      dst,
      @types.Exp::cast(@types.CastKind::low(), width, @types.Exp::var_exp(tmp)),
    ),
    project_basic_bil_x86_flag_move("OF", flag),
    project_basic_bil_x86_flag_move("CF", flag),
    project_basic_bil_x86_flag_move(
      "PF",
      @types.Exp::unknown("PF is undefined after imul", Imm(1)),
    ),
    project_basic_bil_x86_flag_move(
      "SF",
      @types.Exp::unknown("SF is undefined after imul", Imm(1)),
    ),
    project_basic_bil_x86_flag_move(
      "ZF",
      @types.Exp::unknown("ZF is undefined after imul", Imm(1)),
    ),
    project_basic_bil_x86_flag_move(
      "AF",
      @types.Exp::unknown("AF is undefined after imul", Imm(1)),
    ),
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_imul_imm_common(
  self : ProjectDisassemblyInstruction,
  width : Int,
  src : @types.Exp,
  imm_index : Int,
) -> Result[Array[@types.Stmt], String] {
  let imm = match self.project_basic_bil_immediate(imm_index) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs = match project_basic_bil_int(imm, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  self.project_basic_bil_imul_common(width, src, rhs)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_imul_rr_imm(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let src = match self.project_basic_bil_register(1, width) {
    Ok(value) => @types.Exp::var_exp(value)
    Err(reason) => return Err(reason)
  }
  self.project_basic_bil_imul_imm_common(width, src, 2)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_imul_rm_imm(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, _) = match self.project_basic_bil_memory_addr(1) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = @types.Exp::load(
    mem=@types.Exp::var_exp(mem),
    addr~,
    LittleEndian,
    size,
  )
  self.project_basic_bil_imul_imm_common(width, src, 6)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_imul_rr(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let lhs = match self.project_basic_bil_register(0, width) {
    Ok(value) => @types.Exp::var_exp(value)
    Err(reason) => return Err(reason)
  }
  let rhs = match self.project_basic_bil_register(1, width) {
    Ok(value) => @types.Exp::var_exp(value)
    Err(reason) => return Err(reason)
  }
  self.project_basic_bil_imul_common(width, lhs, rhs)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_imul_rm(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let lhs = match self.project_basic_bil_register(0, width) {
    Ok(value) => @types.Exp::var_exp(value)
    Err(reason) => return Err(reason)
  }
  let (addr, mem, _) = match self.project_basic_bil_memory_addr(1) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs = @types.Exp::load(
    mem=@types.Exp::var_exp(mem),
    addr~,
    LittleEndian,
    size,
  )
  self.project_basic_bil_imul_common(width, lhs, rhs)
}

///|
fn project_basic_bil_x86_mul_flag_moves(
  flag : @types.Exp,
  mnemonic : String,
) -> Array[@types.Stmt] {
  [
    project_basic_bil_x86_flag_move("OF", flag),
    project_basic_bil_x86_flag_move("CF", flag),
    project_basic_bil_x86_flag_move(
      "SF",
      @types.Exp::unknown("SF is undefined after \{mnemonic}", Imm(1)),
    ),
    project_basic_bil_x86_flag_move(
      "ZF",
      @types.Exp::unknown("ZF is undefined after \{mnemonic}", Imm(1)),
    ),
    project_basic_bil_x86_flag_move(
      "AF",
      @types.Exp::unknown("AF is undefined after \{mnemonic}", Imm(1)),
    ),
    project_basic_bil_x86_flag_move(
      "PF",
      @types.Exp::unknown("PF is undefined after \{mnemonic}", Imm(1)),
    ),
  ]
}

///|
fn project_basic_bil_x86_imul_acc_flag_moves(
  flag : @types.Exp,
) -> Array[@types.Stmt] {
  [
    project_basic_bil_x86_flag_move("OF", flag),
    project_basic_bil_x86_flag_move("CF", flag),
    project_basic_bil_x86_flag_move(
      "PF",
      @types.Exp::unknown("PF is undefined after imul", Imm(1)),
    ),
    project_basic_bil_x86_flag_move(
      "SF",
      @types.Exp::unknown("SF is undefined after imul", Imm(1)),
    ),
    project_basic_bil_x86_flag_move(
      "ZF",
      @types.Exp::unknown("ZF is undefined after imul", Imm(1)),
    ),
    project_basic_bil_x86_flag_move(
      "AF",
      @types.Exp::unknown("AF is undefined after imul", Imm(1)),
    ),
  ]
}

///|
fn project_basic_bil_x86_accumulator(width : Int) -> Result[@types.Var, String] {
  match width {
    8 => Ok(project_basic_bil_reg("AL", 8))
    16 => Ok(project_basic_bil_reg("AX", 16))
    32 => Ok(project_basic_bil_reg("EAX", 32))
    64 => Ok(project_basic_bil_reg("RAX", 64))
    _ => Err("unsupported x86 accumulator width \{width}")
  }
}

///|
fn project_basic_bil_x86_high_accumulator(
  width : Int,
) -> Result[@types.Var, String] {
  match width {
    16 => Ok(project_basic_bil_reg("DX", 16))
    32 => Ok(project_basic_bil_reg("EDX", 32))
    64 => Ok(project_basic_bil_reg("RDX", 64))
    _ => Err("unsupported x86 high accumulator width \{width}")
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_mul_source(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[@types.Exp, String] {
  match self.operands().length() {
    1 =>
      match self.project_basic_bil_register(0, width) {
        Ok(src) => Ok(@types.Exp::var_exp(src))
        Err(reason) => Err(reason)
      }
    5 => {
      let (addr, mem, _) = match self.project_basic_bil_memory_addr(0) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let size = match @types.Size::of_int(width) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(
        @types.Exp::load(
          mem=@types.Exp::var_exp(mem),
          addr~,
          LittleEndian,
          size,
        ),
      )
    }
    count => Err("unsupported \{self.name()} operand count \{count}")
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_mul(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let src = match self.project_basic_bil_mul_source(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let acc = match project_basic_bil_x86_accumulator(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let product_width = width * 2
  let product = @types.Exp::binop(
    @types.BinOp::times(),
    @types.Exp::cast(
      @types.CastKind::unsigned(),
      product_width,
      @types.Exp::var_exp(acc),
    ),
    @types.Exp::cast(@types.CastKind::unsigned(), product_width, src),
  )
  if width == 8 {
    let ax = project_basic_bil_reg("AX", 16)
    let high = @types.Exp::cast(
      @types.CastKind::high(),
      width,
      @types.Exp::var_exp(ax),
    )
    let zero = match project_basic_bil_int(0L, width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    let flag = @types.Exp::binop(@types.BinOp::neq(), high, zero)
    let stmts = [@types.Stmt::move_stmt(ax, product)]
    for stmt in project_basic_bil_x86_mul_flag_moves(flag, "Mul") {
      stmts.push(stmt)
    }
    Ok(stmts)
  } else {
    let high_acc = match project_basic_bil_x86_high_accumulator(width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    let tmp = project_basic_bil_virtual("mul_tmp", product_width)
    let tmp_exp = @types.Exp::var_exp(tmp)
    let high = @types.Exp::cast(@types.CastKind::high(), width, tmp_exp)
    let zero = match project_basic_bil_int(0L, width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    let flag = @types.Exp::binop(@types.BinOp::neq(), high, zero)
    let stmts = [
      @types.Stmt::move_stmt(tmp, product),
      @types.Stmt::move_stmt(
        acc,
        @types.Exp::cast(
          @types.CastKind::low(),
          width,
          @types.Exp::var_exp(tmp),
        ),
      ),
      @types.Stmt::move_stmt(
        high_acc,
        @types.Exp::cast(
          @types.CastKind::high(),
          width,
          @types.Exp::var_exp(tmp),
        ),
      ),
    ]
    for stmt in project_basic_bil_x86_mul_flag_moves(flag, "Mul") {
      stmts.push(stmt)
    }
    Ok(stmts)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_imul_acc(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let src = match self.project_basic_bil_mul_source(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let acc = match project_basic_bil_x86_accumulator(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let product_width = width * 2
  let product = @types.Exp::binop(
    @types.BinOp::times(),
    @types.Exp::cast(
      @types.CastKind::signed(),
      product_width,
      @types.Exp::var_exp(acc),
    ),
    @types.Exp::cast(@types.CastKind::signed(), product_width, src),
  )
  if width == 8 {
    let ax = project_basic_bil_reg("AX", 16)
    let high = @types.Exp::cast(
      @types.CastKind::high(),
      width,
      @types.Exp::var_exp(ax),
    )
    let zero = match project_basic_bil_int(0L, width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    let flag = @types.Exp::binop(@types.BinOp::neq(), high, zero)
    let stmts = [@types.Stmt::move_stmt(ax, product)]
    for stmt in project_basic_bil_x86_imul_acc_flag_moves(flag) {
      stmts.push(stmt)
    }
    Ok(stmts)
  } else {
    let high_acc = match project_basic_bil_x86_high_accumulator(width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    let tmp = project_basic_bil_virtual("imul_tmp", product_width)
    let tmp_exp = @types.Exp::var_exp(tmp)
    let high = @types.Exp::cast(@types.CastKind::high(), width, tmp_exp)
    let zero = match project_basic_bil_int(0L, width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    let flag = @types.Exp::binop(@types.BinOp::neq(), high, zero)
    let stmts = [
      @types.Stmt::move_stmt(tmp, product),
      @types.Stmt::move_stmt(
        acc,
        @types.Exp::cast(
          @types.CastKind::low(),
          width,
          @types.Exp::var_exp(tmp),
        ),
      ),
      @types.Stmt::move_stmt(
        high_acc,
        @types.Exp::cast(
          @types.CastKind::high(),
          width,
          @types.Exp::var_exp(tmp),
        ),
      ),
    ]
    for stmt in project_basic_bil_x86_imul_acc_flag_moves(flag) {
      stmts.push(stmt)
    }
    Ok(stmts)
  }
}

///|
fn project_basic_bil_x86_div_undefined_flag_moves(
  mnemonic : String,
) -> Array[@types.Stmt] {
  [
    project_basic_bil_x86_flag_move(
      "CF",
      @types.Exp::unknown("CF is undefined after \{mnemonic}", Imm(1)),
    ),
    project_basic_bil_x86_flag_move(
      "OF",
      @types.Exp::unknown("OF is undefined after \{mnemonic}", Imm(1)),
    ),
    project_basic_bil_x86_flag_move(
      "SF",
      @types.Exp::unknown("SF is undefined after \{mnemonic}", Imm(1)),
    ),
    project_basic_bil_x86_flag_move(
      "ZF",
      @types.Exp::unknown("ZF is undefined after \{mnemonic}", Imm(1)),
    ),
    project_basic_bil_x86_flag_move(
      "AF",
      @types.Exp::unknown("AF is undefined after \{mnemonic}", Imm(1)),
    ),
    project_basic_bil_x86_flag_move(
      "PF",
      @types.Exp::unknown("PF is undefined after \{mnemonic}", Imm(1)),
    ),
  ]
}

///|
fn project_basic_bil_x86_double_accumulator_exp(
  width : Int,
) -> Result[@types.Exp, String] {
  if width == 8 {
    Ok(@types.Exp::var_exp(project_basic_bil_reg("AX", 16)))
  } else {
    let high = match project_basic_bil_x86_high_accumulator(width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    let low = match project_basic_bil_x86_accumulator(width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    Ok(@types.Exp::concat(@types.Exp::var_exp(high), @types.Exp::var_exp(low)))
  }
}

///|
fn project_basic_bil_x86_apply_double_result(
  width : Int,
  result : @types.Exp,
  tmp_name : String,
) -> Result[Array[@types.Stmt], String] {
  if width == 8 {
    Ok([@types.Stmt::move_stmt(project_basic_bil_reg("AX", 16), result)])
  } else {
    let acc = match project_basic_bil_x86_accumulator(width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    let high_acc = match project_basic_bil_x86_high_accumulator(width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    let product_width = width * 2
    let tmp = project_basic_bil_virtual(tmp_name, product_width)
    Ok([
      @types.Stmt::move_stmt(tmp, result),
      @types.Stmt::move_stmt(
        acc,
        @types.Exp::cast(
          @types.CastKind::low(),
          width,
          @types.Exp::var_exp(tmp),
        ),
      ),
      @types.Stmt::move_stmt(
        high_acc,
        @types.Exp::cast(
          @types.CastKind::high(),
          width,
          @types.Exp::var_exp(tmp),
        ),
      ),
    ])
  }
}

///|
fn project_basic_bil_x86_div_bound(
  product_width : Int,
  signed_min : Bool,
) -> Result[@types.Exp, String] {
  let one = match project_basic_bil_int(1L, product_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let shift = match
    project_basic_bil_int((product_width - 1).to_int64(), product_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let lbound = @types.Exp::binop(@types.BinOp::lshift(), one, shift)
  if signed_min {
    Ok(lbound)
  } else {
    Ok(@types.Exp::binop(@types.BinOp::minus(), lbound, one))
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_div_common(
  self : ProjectDisassemblyInstruction,
  width : Int,
  signed : Bool,
) -> Result[Array[@types.Stmt], String] {
  let src = match self.project_basic_bil_mul_source(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let product_width = width * 2
  let divisor = project_basic_bil_virtual("divisor", product_width)
  let dividend = project_basic_bil_virtual("dividend", product_width)
  let quotient = project_basic_bil_virtual("div", product_width)
  let remainder = project_basic_bil_virtual("rem", product_width)
  let divisor_exp = @types.Exp::var_exp(divisor)
  let dividend_exp = @types.Exp::var_exp(dividend)
  let quotient_exp = @types.Exp::var_exp(quotient)
  let remainder_exp = @types.Exp::var_exp(remainder)
  let zero_product = match project_basic_bil_int(0L, product_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let zero_width = match project_basic_bil_int(0L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let source_cast = @types.Exp::cast(
    if signed {
      @types.CastKind::signed()
    } else {
      @types.CastKind::unsigned()
    },
    product_width,
    src,
  )
  let dividend_value = match
    project_basic_bil_x86_double_accumulator_exp(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let quotient_op = if signed {
    @types.BinOp::sdivide()
  } else {
    @types.BinOp::divide()
  }
  let remainder_op = if signed {
    @types.BinOp::smodulo()
  } else {
    @types.BinOp::modulo()
  }
  let result = @types.Exp::concat(
    @types.Exp::cast(@types.CastKind::low(), width, remainder_exp),
    @types.Exp::cast(@types.CastKind::low(), width, quotient_exp),
  )
  let apply_result = match
    project_basic_bil_x86_apply_double_result(width, result, "div_result") {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let failure_branch = [@types.Stmt::cpuexn(0)]
  let checked_result = if signed {
    let lbound = match project_basic_bil_x86_div_bound(product_width, true) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    let ubound = match project_basic_bil_x86_div_bound(product_width, false) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    let overflow = @types.Exp::binop(
      @types.BinOp::bit_or(),
      @types.Exp::binop(@types.BinOp::slt(), ubound, quotient_exp),
      @types.Exp::binop(@types.BinOp::slt(), quotient_exp, lbound),
    )
    @types.Stmt::if_(overflow, failure_branch, apply_result)
  } else {
    let quotient_fits = @types.Exp::binop(
      @types.BinOp::eq(),
      @types.Exp::cast(@types.CastKind::high(), width, quotient_exp),
      zero_width,
    )
    @types.Stmt::if_(quotient_fits, apply_result, failure_branch)
  }
  let else_branch = [
    @types.Stmt::move_stmt(
      quotient,
      @types.Exp::binop(quotient_op, dividend_exp, divisor_exp),
    ),
    @types.Stmt::move_stmt(
      remainder,
      @types.Exp::binop(remainder_op, dividend_exp, divisor_exp),
    ),
    checked_result,
  ]
  let mnemonic = if signed { "idiv" } else { "div" }
  let stmts = [
    @types.Stmt::move_stmt(divisor, source_cast),
    @types.Stmt::move_stmt(dividend, dividend_value),
    @types.Stmt::if_(
      @types.Exp::binop(@types.BinOp::eq(), divisor_exp, zero_product),
      [@types.Stmt::cpuexn(0)],
      else_branch,
    ),
  ]
  for stmt in project_basic_bil_x86_div_undefined_flag_moves(mnemonic) {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_div(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  self.project_basic_bil_div_common(width, false)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_idiv(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  self.project_basic_bil_div_common(width, true)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_shift_count(
  self : ProjectDisassemblyInstruction,
  index : Int,
  width : Int,
) -> Result[@types.Exp, String] {
  match self.project_basic_bil_shift_count_with_width(index, width) {
    Ok((count, _)) => Ok(count)
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_shift_count_with_width(
  self : ProjectDisassemblyInstruction,
  index : Int,
  width : Int,
) -> Result[(@types.Exp, Int), String] {
  match self.project_basic_bil_operand(index) {
    Ok(operand) =>
      match operand.register_name() {
        Some(name) =>
          Ok((@types.Exp::var_exp(project_basic_bil_reg(name, 8)), 8))
        None =>
          match operand.to_int64() {
            Some(value) =>
              match project_basic_bil_int(value, width) {
                Ok(count) => Ok((count, width))
                Err(reason) => Err(reason)
              }
            None =>
              Err(
                "instruction \{self.name()} operand \{index} is not a shift count",
              )
          }
      }
    Err(reason) => Err(reason)
  }
}

///|
fn project_basic_bil_rotate_expr(
  src : @types.Var,
  count : @types.Exp,
  count_width : Int,
  width : Int,
  left : Bool,
) -> Result[@types.Exp, String] {
  let width_exp = match project_basic_bil_int(width.to_int64(), count_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let remainder = @types.Exp::binop(@types.BinOp::minus(), width_exp, count)
  let src_exp = @types.Exp::var_exp(src)
  let left_shift = @types.Exp::binop(@types.BinOp::lshift(), src_exp, count)
  let right_shift = @types.Exp::binop(@types.BinOp::rshift(), src_exp, count)
  let complement_left = @types.Exp::binop(
    @types.BinOp::lshift(),
    src_exp,
    remainder,
  )
  let complement_right = @types.Exp::binop(
    @types.BinOp::rshift(),
    src_exp,
    remainder,
  )
  if left {
    Ok(@types.Exp::binop(@types.BinOp::bit_or(), left_shift, complement_right))
  } else {
    Ok(@types.Exp::binop(@types.BinOp::bit_or(), right_shift, complement_left))
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_rotate_r(
  self : ProjectDisassemblyInstruction,
  width : Int,
  left : Bool,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = match self.project_basic_bil_register(1, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (count, count_width) = match
    self.project_basic_bil_shift_count_with_width(2, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs = match
    project_basic_bil_rotate_expr(src, count, count_width, width, left) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok([@types.Stmt::move_stmt(dst, rhs)])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_shift_r(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = match self.project_basic_bil_register(1, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let count = match self.project_basic_bil_shift_count(2, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok([
    @types.Stmt::move_stmt(
      dst,
      @types.Exp::binop(op, @types.Exp::var_exp(src), count),
    ),
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_cmp_rr(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let lhs = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs = match self.project_basic_bil_register(1, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let tmp = project_basic_bil_virtual("cmp_tmp", width)
  let lhs_exp = @types.Exp::var_exp(lhs)
  let rhs_exp = @types.Exp::var_exp(rhs)
  let result_exp = @types.Exp::var_exp(tmp)
  let flags = match
    project_basic_bil_x86_sub_flag_moves(lhs_exp, rhs_exp, result_exp, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(
      tmp,
      @types.Exp::binop(@types.BinOp::minus(), lhs_exp, rhs_exp),
    ),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_cmp_ri(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let lhs = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let imm = match self.project_basic_bil_immediate(1) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs_exp = match project_basic_bil_int(imm, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let tmp = project_basic_bil_virtual("cmp_tmp", width)
  let lhs_exp = @types.Exp::var_exp(lhs)
  let result_exp = @types.Exp::var_exp(tmp)
  let flags = match
    project_basic_bil_x86_sub_flag_moves(lhs_exp, rhs_exp, result_exp, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(
      tmp,
      @types.Exp::binop(@types.BinOp::minus(), lhs_exp, rhs_exp),
    ),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_test_rr(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let lhs = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs = match self.project_basic_bil_register(1, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let tmp = project_basic_bil_virtual("test_tmp", width)
  let lhs_exp = @types.Exp::var_exp(lhs)
  let rhs_exp = @types.Exp::var_exp(rhs)
  let result_exp = @types.Exp::var_exp(tmp)
  let flags = match project_basic_bil_x86_test_flag_moves(result_exp, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(
      tmp,
      @types.Exp::binop(@types.BinOp::bit_and(), lhs_exp, rhs_exp),
    ),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_test_ri(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let lhs = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let imm = match self.project_basic_bil_immediate(1) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs_exp = match project_basic_bil_int(imm, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let tmp = project_basic_bil_virtual("test_tmp", width)
  let lhs_exp = @types.Exp::var_exp(lhs)
  let result_exp = @types.Exp::var_exp(tmp)
  let flags = match project_basic_bil_x86_test_flag_moves(result_exp, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(
      tmp,
      @types.Exp::binop(@types.BinOp::bit_and(), lhs_exp, rhs_exp),
    ),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
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
fn ProjectDisassemblyInstruction::project_basic_bil_mov_mi(
  self : ProjectDisassemblyInstruction,
  data_width : Int,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, _) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let imm = match self.project_basic_bil_immediate(5) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let value = match project_basic_bil_int(imm, data_width) {
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
        value,
        LittleEndian,
        size,
      ),
    ),
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_absolute_address_width(
  self : ProjectDisassemblyInstruction,
) -> Int {
  if self.memory().length() >= 9 {
    64
  } else {
    32
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_absolute_addr(
  self : ProjectDisassemblyInstruction,
  index : Int,
  address_width : Int,
) -> Result[@types.Exp, String] {
  let immediate = match self.project_basic_bil_immediate(index) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  match
    project_basic_bil_word(immediate.reinterpret_as_uint64(), address_width) {
    Ok(word) => Ok(@types.Exp::int(word))
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_mov_abs_load(
  self : ProjectDisassemblyInstruction,
  data_width : Int,
) -> Result[Array[@types.Stmt], String] {
  let address_width = self.project_basic_bil_absolute_address_width()
  let dst = match self.project_basic_bil_register(0, data_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr = match self.project_basic_bil_absolute_addr(1, address_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(data_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let mem = @types.Var::new(
    name="mem",
    typ=Mem(addr_width=address_width, value_width=8),
  )
  Ok([
    @types.Stmt::move_stmt(
      dst,
      @types.Exp::load(mem=@types.Exp::var_exp(mem), addr~, LittleEndian, size),
    ),
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_mov_abs_store(
  self : ProjectDisassemblyInstruction,
  data_width : Int,
) -> Result[Array[@types.Stmt], String] {
  let address_width = self.project_basic_bil_absolute_address_width()
  let addr = match self.project_basic_bil_absolute_addr(0, address_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = match self.project_basic_bil_register(1, data_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(data_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let mem = @types.Var::new(
    name="mem",
    typ=Mem(addr_width=address_width, value_width=8),
  )
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
fn ProjectDisassemblyInstruction::project_basic_bil_setcc(
  self : ProjectDisassemblyInstruction,
) -> Result[Array[@types.Stmt], String] {
  let value = @types.Exp::cast(
    @types.CastKind::unsigned(),
    8,
    project_basic_bil_x86_setcc_condition(self.name().to_upper()),
  )
  match self.operands().length() {
    1 => {
      let dst = match self.project_basic_bil_register(0, 8) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok([@types.Stmt::move_stmt(dst, value)])
    }
    5 => {
      let (addr, mem, _) = match self.project_basic_bil_memory_addr(0) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok([
        @types.Stmt::move_stmt(
          mem,
          @types.Exp::store(
            mem=@types.Exp::var_exp(mem),
            addr~,
            value,
            LittleEndian,
            R8,
          ),
        ),
      ])
    }
    count => Err("unsupported \{self.name()} operand count \{count}")
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_cmov(
  self : ProjectDisassemblyInstruction,
  data_width : Int,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, data_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = match self.operands().length() {
    2 =>
      match self.project_basic_bil_register(1, data_width) {
        Ok(value) => @types.Exp::var_exp(value)
        Err(reason) => return Err(reason)
      }
    6 => {
      let (addr, mem, _) = match self.project_basic_bil_memory_addr(1) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let size = match @types.Size::of_int(data_width) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      @types.Exp::load(mem=@types.Exp::var_exp(mem), addr~, LittleEndian, size)
    }
    count => return Err("unsupported \{self.name()} operand count \{count}")
  }
  let dst_exp = @types.Exp::var_exp(dst)
  Ok([
    @types.Stmt::move_stmt(
      dst,
      @types.Exp::ite(
        if_=project_basic_bil_x86_cmov_condition(self.name().to_upper()),
        then_=src,
        else_=dst_exp,
      ),
    ),
  ])
}

///|
fn project_basic_bil_reverse_bytes(
  value : @types.Exp,
  width : Int,
) -> Result[@types.Exp, String] {
  if width != 32 && width != 64 {
    return Err("unsupported BSWAP width \{width}")
  }
  let byte_count = width / 8
  let mut result = @types.Exp::extract(value, hi=7, lo=0)
  for index in 1..<byte_count {
    result = @types.Exp::concat(
      result,
      @types.Exp::extract(value, hi=index * 8 + 7, lo=index * 8),
    )
  }
  Ok(result)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_bswap(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let value = match
    project_basic_bil_reverse_bytes(@types.Exp::var_exp(dst), width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok([@types.Stmt::move_stmt(dst, value)])
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
fn ProjectDisassemblyInstruction::project_basic_bil_movx_rr(
  self : ProjectDisassemblyInstruction,
  dst_width : Int,
  src_width : Int,
  cast_kind : @types.CastKind,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, dst_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = match self.project_basic_bil_register(1, src_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok([
    @types.Stmt::move_stmt(
      dst,
      @types.Exp::cast(cast_kind, dst_width, @types.Exp::var_exp(src)),
    ),
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_movx_rm(
  self : ProjectDisassemblyInstruction,
  dst_width : Int,
  src_width : Int,
  cast_kind : @types.CastKind,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, dst_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (addr, mem, _) = match self.project_basic_bil_memory_addr(1) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(src_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let source = @types.Exp::load(
    mem=@types.Exp::var_exp(mem),
    addr~,
    LittleEndian,
    size,
  )
  Ok([
    @types.Stmt::move_stmt(dst, @types.Exp::cast(cast_kind, dst_width, source)),
  ])
}

///|
fn project_basic_bil_sign_extend_register(
  src_name : String,
  src_width : Int,
  dst_name : String,
  dst_width : Int,
) -> Array[@types.Stmt] {
  let src = project_basic_bil_reg(src_name, src_width)
  let dst = project_basic_bil_reg(dst_name, dst_width)
  [
    @types.Stmt::move_stmt(
      dst,
      @types.Exp::cast(
        @types.CastKind::signed(),
        dst_width,
        @types.Exp::var_exp(src),
      ),
    ),
  ]
}

///|
fn project_basic_bil_sign_extend_high_register(
  src_name : String,
  src_width : Int,
  dst_name : String,
  dst_width : Int,
) -> Array[@types.Stmt] {
  let src = project_basic_bil_reg(src_name, src_width)
  let dst = project_basic_bil_reg(dst_name, dst_width)
  let extended = @types.Exp::cast(
    @types.CastKind::signed(),
    src_width * 2,
    @types.Exp::var_exp(src),
  )
  [
    @types.Stmt::move_stmt(
      dst,
      @types.Exp::cast(@types.CastKind::high(), dst_width, extended),
    ),
  ]
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_xchg_rr(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let left = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let right = match self.project_basic_bil_register(1, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let tmp = project_basic_bil_virtual("xchg_tmp", width)
  Ok([
    @types.Stmt::move_stmt(tmp, @types.Exp::var_exp(left)),
    @types.Stmt::move_stmt(left, @types.Exp::var_exp(right)),
    @types.Stmt::move_stmt(right, @types.Exp::var_exp(tmp)),
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_xchg_rm(
  self : ProjectDisassemblyInstruction,
  data_width : Int,
) -> Result[Array[@types.Stmt], String] {
  let register = match self.project_basic_bil_register(0, data_width) {
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
  let tmp = project_basic_bil_virtual("xchg_tmp", data_width)
  Ok([
    @types.Stmt::move_stmt(tmp, @types.Exp::var_exp(register)),
    @types.Stmt::move_stmt(
      register,
      @types.Exp::load(mem=@types.Exp::var_exp(mem), addr~, LittleEndian, size),
    ),
    @types.Stmt::move_stmt(
      mem,
      @types.Exp::store(
        mem=@types.Exp::var_exp(mem),
        addr~,
        @types.Exp::var_exp(tmp),
        LittleEndian,
        size,
      ),
    ),
  ])
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
fn project_basic_bil_push_exp(
  src : @types.Exp,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
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
        src,
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(sp, updated_sp),
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_push(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  match self.project_basic_bil_value(0, width) {
    Ok(src) => project_basic_bil_push_exp(src, width)
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_push_mem(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, _) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  project_basic_bil_push_exp(
    @types.Exp::load(mem=@types.Exp::var_exp(mem), addr~, LittleEndian, size),
    width,
  )
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
fn ProjectDisassemblyInstruction::project_basic_bil_jcc(
  self : ProjectDisassemblyInstruction,
  mnemonic : String,
) -> Result[Array[@types.Stmt], String] {
  match self.project_basic_bil_immediate(0) {
    Ok(target) =>
      match
        project_basic_bil_control(
          @types.Stmt::goto(),
          target.reinterpret_as_uint64(),
        ) {
        Ok(branch) =>
          Ok([
            @types.Stmt::if_(
              project_basic_bil_x86_jcc_condition(mnemonic),
              branch,
              [],
            ),
          ])
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn project_basic_bil_indirect_control(
  attr : @types.StmtAttribute[String],
  target : @types.Exp,
) -> Array[@types.Stmt] {
  [@types.Stmt::encode(attr, "indirect"), @types.Stmt::jmp(target)]
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_control_reg(
  self : ProjectDisassemblyInstruction,
  width : Int,
  attr : @types.StmtAttribute[String],
) -> Result[Array[@types.Stmt], String] {
  match self.project_basic_bil_register(0, width) {
    Ok(target) =>
      Ok(project_basic_bil_indirect_control(attr, @types.Exp::var_exp(target)))
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_control_mem(
  self : ProjectDisassemblyInstruction,
  width : Int,
  attr : @types.StmtAttribute[String],
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, _) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok(
    project_basic_bil_indirect_control(
      attr,
      @types.Exp::load(mem=@types.Exp::var_exp(mem), addr~, LittleEndian, size),
    ),
  )
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
  let name = self.name().to_upper()
  if name.has_prefix("CMOV") {
    let width = if name.contains("64") { 64 } else { 32 }
    return self.project_basic_bil_cmov(width)
  }
  match name {
    "SUB8RI8" => self.project_basic_bil_binop_ri(8, @types.BinOp::minus())
    "SUB32RI8" | "SUB32RI32" =>
      self.project_basic_bil_binop_ri(32, @types.BinOp::minus())
    "ADD8RI8" => self.project_basic_bil_binop_ri(8, @types.BinOp::plus())
    "ADD32RI8" | "ADD32RI32" =>
      self.project_basic_bil_binop_ri(32, @types.BinOp::plus())
    "SUB64RI8" | "SUB64RI32" =>
      self.project_basic_bil_binop_ri(64, @types.BinOp::minus())
    "ADD64RI8" | "ADD64RI32" =>
      self.project_basic_bil_binop_ri(64, @types.BinOp::plus())
    "OR8RI8" => self.project_basic_bil_binop_ri(8, @types.BinOp::bit_or())
    "OR32RI8" | "OR32RI32" =>
      self.project_basic_bil_binop_ri(32, @types.BinOp::bit_or())
    "OR64RI8" | "OR64RI32" =>
      self.project_basic_bil_binop_ri(64, @types.BinOp::bit_or())
    "AND8RI8" => self.project_basic_bil_binop_ri(8, @types.BinOp::bit_and())
    "AND32RI8" | "AND32RI32" =>
      self.project_basic_bil_binop_ri(32, @types.BinOp::bit_and())
    "AND64RI8" | "AND64RI32" =>
      self.project_basic_bil_binop_ri(64, @types.BinOp::bit_and())
    "XOR8RI8" => self.project_basic_bil_binop_ri(8, @types.BinOp::bit_xor())
    "XOR32RI8" | "XOR32RI32" =>
      self.project_basic_bil_binop_ri(32, @types.BinOp::bit_xor())
    "XOR64RI8" | "XOR64RI32" =>
      self.project_basic_bil_binop_ri(64, @types.BinOp::bit_xor())
    "IMUL16RRI8" | "IMUL16RRI16" => self.project_basic_bil_imul_rr_imm(16)
    "IMUL32RRI8" | "IMUL32RRI32" => self.project_basic_bil_imul_rr_imm(32)
    "IMUL64RRI8" | "IMUL64RRI32" => self.project_basic_bil_imul_rr_imm(64)
    "IMUL16RMI8" | "IMUL16RMI16" => self.project_basic_bil_imul_rm_imm(16)
    "IMUL32RMI8" | "IMUL32RMI32" => self.project_basic_bil_imul_rm_imm(32)
    "IMUL64RMI8" | "IMUL64RMI32" => self.project_basic_bil_imul_rm_imm(64)
    "IMUL16RR" => self.project_basic_bil_imul_rr(16)
    "IMUL32RR" => self.project_basic_bil_imul_rr(32)
    "IMUL64RR" => self.project_basic_bil_imul_rr(64)
    "IMUL16RM" => self.project_basic_bil_imul_rm(16)
    "IMUL32RM" => self.project_basic_bil_imul_rm(32)
    "IMUL64RM" => self.project_basic_bil_imul_rm(64)
    "IMUL8R" | "IMUL8M" => self.project_basic_bil_imul_acc(8)
    "IMUL16R" | "IMUL16M" => self.project_basic_bil_imul_acc(16)
    "IMUL32R" | "IMUL32M" => self.project_basic_bil_imul_acc(32)
    "IMUL64R" | "IMUL64M" => self.project_basic_bil_imul_acc(64)
    "MUL8R" | "MUL8M" => self.project_basic_bil_mul(8)
    "MUL16R" | "MUL16M" => self.project_basic_bil_mul(16)
    "MUL32R" | "MUL32M" => self.project_basic_bil_mul(32)
    "MUL64R" | "MUL64M" => self.project_basic_bil_mul(64)
    "DIV8R" | "DIV8M" => self.project_basic_bil_div(8)
    "DIV16R" | "DIV16M" => self.project_basic_bil_div(16)
    "DIV32R" | "DIV32M" => self.project_basic_bil_div(32)
    "DIV64R" | "DIV64M" => self.project_basic_bil_div(64)
    "IDIV8R" | "IDIV8M" => self.project_basic_bil_idiv(8)
    "IDIV16R" | "IDIV16M" => self.project_basic_bil_idiv(16)
    "IDIV32R" | "IDIV32M" => self.project_basic_bil_idiv(32)
    "IDIV64R" | "IDIV64M" => self.project_basic_bil_idiv(64)
    "ROL8R1" | "ROL8RCL" | "ROL8RI8" => self.project_basic_bil_rotate_r(8, true)
    "ROL32R1" | "ROL32RCL" | "ROL32RI8" =>
      self.project_basic_bil_rotate_r(32, true)
    "ROL64R1" | "ROL64RCL" | "ROL64RI8" =>
      self.project_basic_bil_rotate_r(64, true)
    "ROR8R1" | "ROR8RCL" | "ROR8RI8" =>
      self.project_basic_bil_rotate_r(8, false)
    "ROR32R1" | "ROR32RCL" | "ROR32RI8" =>
      self.project_basic_bil_rotate_r(32, false)
    "ROR64R1" | "ROR64RCL" | "ROR64RI8" =>
      self.project_basic_bil_rotate_r(64, false)
    "SHL8R1" | "SHL8RCL" | "SHL8RI8" =>
      self.project_basic_bil_shift_r(8, @types.BinOp::lshift())
    "SHL32R1" | "SHL32RCL" | "SHL32RI8" =>
      self.project_basic_bil_shift_r(32, @types.BinOp::lshift())
    "SHL64R1" | "SHL64RCL" | "SHL64RI8" =>
      self.project_basic_bil_shift_r(64, @types.BinOp::lshift())
    "SHR8R1" | "SHR8RCL" | "SHR8RI8" =>
      self.project_basic_bil_shift_r(8, @types.BinOp::rshift())
    "SHR32R1" | "SHR32RCL" | "SHR32RI8" =>
      self.project_basic_bil_shift_r(32, @types.BinOp::rshift())
    "SHR64R1" | "SHR64RCL" | "SHR64RI8" =>
      self.project_basic_bil_shift_r(64, @types.BinOp::rshift())
    "SAR8R1" | "SAR8RCL" | "SAR8RI8" =>
      self.project_basic_bil_shift_r(8, @types.BinOp::arshift())
    "SAR32R1" | "SAR32RCL" | "SAR32RI8" =>
      self.project_basic_bil_shift_r(32, @types.BinOp::arshift())
    "SAR64R1" | "SAR64RCL" | "SAR64RI8" =>
      self.project_basic_bil_shift_r(64, @types.BinOp::arshift())
    "INC8R" => self.project_basic_bil_incdec(8, @types.BinOp::plus())
    "INC32R" => self.project_basic_bil_incdec(32, @types.BinOp::plus())
    "INC64R" => self.project_basic_bil_incdec(64, @types.BinOp::plus())
    "DEC8R" => self.project_basic_bil_incdec(8, @types.BinOp::minus())
    "DEC32R" => self.project_basic_bil_incdec(32, @types.BinOp::minus())
    "DEC64R" => self.project_basic_bil_incdec(64, @types.BinOp::minus())
    "NOT8R" => self.project_basic_bil_unop_r(8, @types.UnOp::not())
    "NOT32R" => self.project_basic_bil_unop_r(32, @types.UnOp::not())
    "NOT64R" => self.project_basic_bil_unop_r(64, @types.UnOp::not())
    "NEG8R" => self.project_basic_bil_unop_r(8, @types.UnOp::neg())
    "NEG32R" => self.project_basic_bil_unop_r(32, @types.UnOp::neg())
    "NEG64R" => self.project_basic_bil_unop_r(64, @types.UnOp::neg())
    "SUB8RR" | "SUB8RR_REV" =>
      self.project_basic_bil_binop_rr(8, @types.BinOp::minus())
    "SUB32RR" | "SUB32RR_REV" =>
      self.project_basic_bil_binop_rr(32, @types.BinOp::minus())
    "ADD8RR" | "ADD8RR_REV" =>
      self.project_basic_bil_binop_rr(8, @types.BinOp::plus())
    "ADD32RR" | "ADD32RR_REV" =>
      self.project_basic_bil_binop_rr(32, @types.BinOp::plus())
    "SUB64RR" | "SUB64RR_REV" =>
      self.project_basic_bil_binop_rr(64, @types.BinOp::minus())
    "ADD64RR" | "ADD64RR_REV" =>
      self.project_basic_bil_binop_rr(64, @types.BinOp::plus())
    "CMP8RI8" => self.project_basic_bil_cmp_ri(8)
    "CMP32RI8" | "CMP32RI32" => self.project_basic_bil_cmp_ri(32)
    "CMP64RI8" | "CMP64RI32" => self.project_basic_bil_cmp_ri(64)
    "CMP8RR" | "CMP8RR_REV" => self.project_basic_bil_cmp_rr(8)
    "CMP32RR" | "CMP32RR_REV" => self.project_basic_bil_cmp_rr(32)
    "CMP64RR" | "CMP64RR_REV" => self.project_basic_bil_cmp_rr(64)
    "MOV8RM" => self.project_basic_bil_mov_rm(8)
    "MOV32RM" => self.project_basic_bil_mov_rm(32)
    "MOV64RM" => self.project_basic_bil_mov_rm(64)
    "MOV8MR" => self.project_basic_bil_mov_mr(8)
    "MOV32MR" => self.project_basic_bil_mov_mr(32)
    "MOV64MR" => self.project_basic_bil_mov_mr(64)
    "MOV8MI" => self.project_basic_bil_mov_mi(8)
    "MOV32MI" => self.project_basic_bil_mov_mi(32)
    "MOV64MI" => self.project_basic_bil_mov_mi(64)
    "MOV8RA" => self.project_basic_bil_mov_abs_load(8)
    "MOV32RA" => self.project_basic_bil_mov_abs_load(32)
    "MOV64RA" => self.project_basic_bil_mov_abs_load(64)
    "MOV8AR" => self.project_basic_bil_mov_abs_store(8)
    "MOV32AR" => self.project_basic_bil_mov_abs_store(32)
    "MOV64AR" => self.project_basic_bil_mov_abs_store(64)
    "LEA32R" => self.project_basic_bil_lea(32)
    "LEA64R" => self.project_basic_bil_lea(64)
    "MOV8RI" => self.project_basic_bil_mov_imm(8)
    "MOV32RI" => self.project_basic_bil_mov_imm(32)
    "MOV64RI" => self.project_basic_bil_mov_imm(64)
    "MOV64RI32" => self.project_basic_bil_mov_imm(64)
    "MOV8RR" | "MOV8RR_REV" => self.project_basic_bil_mov_rr(8)
    "MOV32RR" | "MOV32RR_REV" => self.project_basic_bil_mov_rr(32)
    "MOV64RR" | "MOV64RR_REV" => self.project_basic_bil_mov_rr(64)
    "MOVZX32RR8" =>
      self.project_basic_bil_movx_rr(32, 8, @types.CastKind::unsigned())
    "MOVZX64RR8" =>
      self.project_basic_bil_movx_rr(64, 8, @types.CastKind::unsigned())
    "MOVZX32RM8" =>
      self.project_basic_bil_movx_rm(32, 8, @types.CastKind::unsigned())
    "MOVZX64RM8" =>
      self.project_basic_bil_movx_rm(64, 8, @types.CastKind::unsigned())
    "MOVZX32RR16" =>
      self.project_basic_bil_movx_rr(32, 16, @types.CastKind::unsigned())
    "MOVZX64RR16" =>
      self.project_basic_bil_movx_rr(64, 16, @types.CastKind::unsigned())
    "MOVZX32RM16" =>
      self.project_basic_bil_movx_rm(32, 16, @types.CastKind::unsigned())
    "MOVZX64RM16" =>
      self.project_basic_bil_movx_rm(64, 16, @types.CastKind::unsigned())
    "MOVSX32RR8" =>
      self.project_basic_bil_movx_rr(32, 8, @types.CastKind::signed())
    "MOVSX64RR8" =>
      self.project_basic_bil_movx_rr(64, 8, @types.CastKind::signed())
    "MOVSX32RM8" =>
      self.project_basic_bil_movx_rm(32, 8, @types.CastKind::signed())
    "MOVSX64RM8" =>
      self.project_basic_bil_movx_rm(64, 8, @types.CastKind::signed())
    "MOVSX32RR16" =>
      self.project_basic_bil_movx_rr(32, 16, @types.CastKind::signed())
    "MOVSX64RR16" =>
      self.project_basic_bil_movx_rr(64, 16, @types.CastKind::signed())
    "MOVSX32RM16" =>
      self.project_basic_bil_movx_rm(32, 16, @types.CastKind::signed())
    "MOVSX64RM16" =>
      self.project_basic_bil_movx_rm(64, 16, @types.CastKind::signed())
    "MOVSX32RR32" =>
      self.project_basic_bil_movx_rr(32, 32, @types.CastKind::signed())
    "MOVSX64RR32" =>
      self.project_basic_bil_movx_rr(64, 32, @types.CastKind::signed())
    "MOVSX32RM32" =>
      self.project_basic_bil_movx_rm(32, 32, @types.CastKind::signed())
    "MOVSX64RM32" =>
      self.project_basic_bil_movx_rm(64, 32, @types.CastKind::signed())
    "CBW" => Ok(project_basic_bil_sign_extend_register("AL", 8, "AX", 16))
    "CWDE" => Ok(project_basic_bil_sign_extend_register("AX", 16, "EAX", 32))
    "CDQE" => Ok(project_basic_bil_sign_extend_register("EAX", 32, "RAX", 64))
    "CWD" => Ok(project_basic_bil_sign_extend_high_register("AX", 16, "DX", 16))
    "CDQ" =>
      Ok(project_basic_bil_sign_extend_high_register("EAX", 32, "EDX", 32))
    "CQO" =>
      Ok(project_basic_bil_sign_extend_high_register("RAX", 64, "RDX", 64))
    "XCHG8RR" => self.project_basic_bil_xchg_rr(8)
    "XCHG32RR" => self.project_basic_bil_xchg_rr(32)
    "XCHG64RR" => self.project_basic_bil_xchg_rr(64)
    "XCHG8RM" => self.project_basic_bil_xchg_rm(8)
    "XCHG32RM" => self.project_basic_bil_xchg_rm(32)
    "XCHG64RM" => self.project_basic_bil_xchg_rm(64)
    "OR8RR" | "OR8RR_REV" =>
      self.project_basic_bil_binop_rr(8, @types.BinOp::bit_or())
    "OR32RR" | "OR32RR_REV" =>
      self.project_basic_bil_binop_rr(32, @types.BinOp::bit_or())
    "OR64RR" | "OR64RR_REV" =>
      self.project_basic_bil_binop_rr(64, @types.BinOp::bit_or())
    "AND8RR" | "AND8RR_REV" =>
      self.project_basic_bil_binop_rr(8, @types.BinOp::bit_and())
    "AND32RR" | "AND32RR_REV" =>
      self.project_basic_bil_binop_rr(32, @types.BinOp::bit_and())
    "AND64RR" | "AND64RR_REV" =>
      self.project_basic_bil_binop_rr(64, @types.BinOp::bit_and())
    "XOR8RR" | "XOR8RR_REV" =>
      self.project_basic_bil_binop_rr(8, @types.BinOp::bit_xor())
    "XOR32RR" | "XOR32RR_REV" =>
      self.project_basic_bil_binop_rr(32, @types.BinOp::bit_xor())
    "XOR64RR" | "XOR64RR_REV" =>
      self.project_basic_bil_binop_rr(64, @types.BinOp::bit_xor())
    "TEST8RI8" => self.project_basic_bil_test_ri(8)
    "TEST32RI32" => self.project_basic_bil_test_ri(32)
    "TEST64RI32" => self.project_basic_bil_test_ri(64)
    "TEST8RR" | "TEST8RR_REV" => self.project_basic_bil_test_rr(8)
    "TEST32RR" | "TEST32RR_REV" => self.project_basic_bil_test_rr(32)
    "TEST64RR" | "TEST64RR_REV" => self.project_basic_bil_test_rr(64)
    "SETO"
    | "SETNO"
    | "SETB"
    | "SETAE"
    | "SETE"
    | "SETNE"
    | "SETBE"
    | "SETA"
    | "SETS"
    | "SETNS"
    | "SETP"
    | "SETNP"
    | "SETL"
    | "SETGE"
    | "SETLE"
    | "SETG" => self.project_basic_bil_setcc()
    "BSWAP32R" => self.project_basic_bil_bswap(32)
    "BSWAP64R" => self.project_basic_bil_bswap(64)
    "PUSH32R" | "PUSH32I8" | "PUSH32I32" => self.project_basic_bil_push(32)
    "PUSH64R" | "PUSH64I8" | "PUSH64I32" => self.project_basic_bil_push(64)
    "PUSH32M" => self.project_basic_bil_push_mem(32)
    "PUSH64M" => self.project_basic_bil_push_mem(64)
    "POP32R" => self.project_basic_bil_pop(32)
    "POP64R" => self.project_basic_bil_pop(64)
    "LEAVE" => self.project_basic_bil_leave(32)
    "LEAVE64" => self.project_basic_bil_leave(64)
    "ENDBR32" | "ENDBR64" => Ok([])
    "NOOP" => Ok([])
    "CLC" => project_basic_bil_x86_flag_assign("CF", 0L)
    "STC" => project_basic_bil_x86_flag_assign("CF", 1L)
    "CMC" =>
      Ok([
        project_basic_bil_x86_flag_move(
          "CF",
          project_basic_bil_x86_not(project_basic_bil_x86_flag("CF")),
        ),
      ])
    "CLD" => project_basic_bil_x86_flag_assign("DF", 0L)
    "STD" => project_basic_bil_x86_flag_assign("DF", 1L)
    "LAHF" => Ok(project_basic_bil_x86_lahf())
    "SAHF" => Ok(project_basic_bil_x86_sahf())
    "PUSHF32" => project_basic_bil_x86_pushf(32)
    "PUSHF64" => project_basic_bil_x86_pushf(64)
    "POPF32" => project_basic_bil_x86_popf(32)
    "POPF64" => project_basic_bil_x86_popf(64)
    "INT3" | "INT" => self.project_basic_bil_cpuexn()
    "HLT" => Ok([])
    "RDTSC" => Ok(project_basic_bil_x86_unknown_regs("rdtsc", ["EAX", "EDX"]))
    "CPUID" =>
      Ok(
        project_basic_bil_x86_unknown_regs("cpuid", ["EAX", "EBX", "ECX", "EDX"]),
      )
    "XGETBV" => Ok(project_basic_bil_x86_unknown_regs("xgetbv", ["EAX", "EDX"]))
    "SYSCALL" | "SYSENTER" =>
      Ok([@types.Stmt::encode(@types.Stmt::call(), "syscall")])
    "JMP_1" => self.project_basic_bil_jump()
    "JMP_4" => self.project_basic_bil_jump()
    "CALLPCREL32" => self.project_basic_bil_call(32)
    "CALL64PCREL32" => self.project_basic_bil_call(64)
    "CALL32R" => self.project_basic_bil_control_reg(32, @types.Stmt::call())
    "CALL64R" => self.project_basic_bil_control_reg(64, @types.Stmt::call())
    "CALL32M" => self.project_basic_bil_control_mem(32, @types.Stmt::call())
    "CALL64M" => self.project_basic_bil_control_mem(64, @types.Stmt::call())
    "JMP32R" => self.project_basic_bil_control_reg(32, @types.Stmt::goto())
    "JMP64R" => self.project_basic_bil_control_reg(64, @types.Stmt::goto())
    "JMP32M" => self.project_basic_bil_control_mem(32, @types.Stmt::goto())
    "JMP64M" => self.project_basic_bil_control_mem(64, @types.Stmt::goto())
    "JO_1" | "JO_4" => self.project_basic_bil_jcc("JO")
    "JNO_1" | "JNO_4" => self.project_basic_bil_jcc("JNO")
    "JB_1" | "JB_4" => self.project_basic_bil_jcc("JB")
    "JAE_1" | "JAE_4" => self.project_basic_bil_jcc("JAE")
    "JE_1" | "JE_4" => self.project_basic_bil_jcc("JE")
    "JNE_1" | "JNE_4" => self.project_basic_bil_jcc("JNE")
    "JBE_1" | "JBE_4" => self.project_basic_bil_jcc("JBE")
    "JA_1" | "JA_4" => self.project_basic_bil_jcc("JA")
    "JS_1" | "JS_4" => self.project_basic_bil_jcc("JS")
    "JNS_1" | "JNS_4" => self.project_basic_bil_jcc("JNS")
    "JP_1" | "JP_4" => self.project_basic_bil_jcc("JP")
    "JNP_1" | "JNP_4" => self.project_basic_bil_jcc("JNP")
    "JL_1" | "JL_4" => self.project_basic_bil_jcc("JL")
    "JGE_1" | "JGE_4" => self.project_basic_bil_jcc("JGE")
    "JLE_1" | "JLE_4" => self.project_basic_bil_jcc("JLE")
    "JG_1" | "JG_4" => self.project_basic_bil_jcc("JG")
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
