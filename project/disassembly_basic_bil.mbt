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
fn project_basic_bil_stack_mem(address_width : Int) -> @types.Var {
  @types.Var::new(name="mem", typ=Mem(addr_width=address_width, value_width=8))
}

///|
fn project_basic_bil_stack_pointer(
  address_width : Int,
) -> Result[@types.Var, String] {
  match address_width {
    32 => Ok(project_basic_bil_reg("ESP", 32))
    64 => Ok(project_basic_bil_reg("RSP", 64))
    _ => Err("unsupported stack address width \{address_width}")
  }
}

///|
fn project_basic_bil_stack_offset(
  sp : @types.Var,
  value_width : Int,
  address_width : Int,
  op : @types.BinOp,
) -> Result[@types.Exp, String] {
  match project_basic_bil_int((value_width / 8).to_int64(), address_width) {
    Ok(offset) => Ok(@types.Exp::binop(op, @types.Exp::var_exp(sp), offset))
    Err(reason) => Err(reason)
  }
}

///|
fn project_basic_bil_stack_decrement(
  sp : @types.Var,
  value_width : Int,
  address_width : Int,
) -> Result[@types.Exp, String] {
  project_basic_bil_stack_offset(
    sp,
    value_width,
    address_width,
    @types.BinOp::minus(),
  )
}

///|
fn project_basic_bil_stack_increment(
  sp : @types.Var,
  value_width : Int,
  address_width : Int,
) -> Result[@types.Exp, String] {
  project_basic_bil_stack_offset(
    sp,
    value_width,
    address_width,
    @types.BinOp::plus(),
  )
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
fn ProjectDisassemblyInstruction::project_basic_bil_random(
  self : ProjectDisassemblyInstruction,
  width : Int,
  source : String,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let zero_flag = match project_basic_bil_int(0L, 1) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok([
    @types.Stmt::move_stmt(dst, @types.Exp::unknown(source, Imm(width))),
    project_basic_bil_x86_flag_move("CF", @types.Exp::unknown(source, Imm(1))),
    project_basic_bil_x86_flag_move("OF", zero_flag),
    project_basic_bil_x86_flag_move("SF", zero_flag),
    project_basic_bil_x86_flag_move("ZF", zero_flag),
    project_basic_bil_x86_flag_move("AF", zero_flag),
    project_basic_bil_x86_flag_move("PF", zero_flag),
  ])
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
fn project_basic_bil_x86_and(
  left : @types.Exp,
  right : @types.Exp,
) -> @types.Exp {
  @types.Exp::binop(@types.BinOp::bit_and(), left, right)
}

///|
fn project_basic_bil_x86_not(exp : @types.Exp) -> @types.Exp {
  @types.Exp::unop(@types.UnOp::not(), exp)
}

///|
fn project_basic_bil_bitscan_popcount(
  tmp : @types.Var,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let (
    one_value,
    two_value,
    four_value,
    sh_value,
    m1_value,
    m2_value,
    m4_value,
    h01_value,
  ) = match width {
    16 => (1L, 2L, 4L, 8L, 0x5555L, 0x3333L, 0x0f0fL, 0x0101L)
    32 => (1L, 2L, 4L, 24L, 0x55555555L, 0x33333333L, 0x0f0f0f0fL, 0x01010101L)
    64 =>
      (
        1L, 2L, 4L, 56L, 0x5555555555555555L, 0x3333333333333333L, 0x0f0f0f0f0f0f0f0fL,
        0x0101010101010101L,
      )
    _ => return Err("unsupported bitscan width \{width}")
  }
  let one = match project_basic_bil_int(one_value, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let two = match project_basic_bil_int(two_value, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let four = match project_basic_bil_int(four_value, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let sh = match project_basic_bil_int(sh_value, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let m1 = match project_basic_bil_int(m1_value, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let m2 = match project_basic_bil_int(m2_value, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let m4 = match project_basic_bil_int(m4_value, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let h01 = match project_basic_bil_int(h01_value, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let tmp_exp = fn() { @types.Exp::var_exp(tmp) }
  Ok([
    @types.Stmt::move_stmt(
      tmp,
      @types.Exp::binop(
        @types.BinOp::minus(),
        tmp_exp(),
        project_basic_bil_x86_and(
          @types.Exp::binop(@types.BinOp::rshift(), tmp_exp(), one),
          m1,
        ),
      ),
    ),
    @types.Stmt::move_stmt(
      tmp,
      @types.Exp::binop(
        @types.BinOp::plus(),
        project_basic_bil_x86_and(tmp_exp(), m2),
        project_basic_bil_x86_and(
          @types.Exp::binop(@types.BinOp::rshift(), tmp_exp(), two),
          m2,
        ),
      ),
    ),
    @types.Stmt::move_stmt(
      tmp,
      project_basic_bil_x86_and(
        @types.Exp::binop(
          @types.BinOp::plus(),
          tmp_exp(),
          @types.Exp::binop(@types.BinOp::rshift(), tmp_exp(), four),
        ),
        m4,
      ),
    ),
    @types.Stmt::move_stmt(
      tmp,
      @types.Exp::binop(
        @types.BinOp::rshift(),
        @types.Exp::binop(@types.BinOp::times(), tmp_exp(), h01),
        sh,
      ),
    ),
  ])
}

///|
fn project_basic_bil_bitscan_ctz(
  tmp : @types.Var,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let one = match project_basic_bil_int(1L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let tmp_exp = @types.Exp::var_exp(tmp)
  let isolated_low = project_basic_bil_x86_and(
    tmp_exp,
    @types.Exp::unop(@types.UnOp::neg(), @types.Exp::var_exp(tmp)),
  )
  let stmts = [
    @types.Stmt::move_stmt(
      tmp,
      @types.Exp::binop(@types.BinOp::minus(), isolated_low, one),
    ),
  ]
  match project_basic_bil_bitscan_popcount(tmp, width) {
    Ok(popcount) => {
      for stmt in popcount {
        stmts.push(stmt)
      }
      Ok(stmts)
    }
    Err(reason) => Err(reason)
  }
}

///|
fn project_basic_bil_bitscan_clz(
  tmp : @types.Var,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let shifts : Array[Int64] = match width {
    16 => [1L, 2L, 4L, 8L]
    32 => [1L, 2L, 4L, 8L, 16L]
    64 => [1L, 2L, 4L, 8L, 16L, 32L]
    _ => return Err("unsupported bitscan width \{width}")
  }
  let stmts : Array[@types.Stmt] = []
  for shift_value in shifts {
    let shift = match project_basic_bil_int(shift_value, width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    let tmp_exp = @types.Exp::var_exp(tmp)
    stmts.push(
      @types.Stmt::move_stmt(
        tmp,
        project_basic_bil_x86_or(
          tmp_exp,
          @types.Exp::binop(
            @types.BinOp::rshift(),
            @types.Exp::var_exp(tmp),
            shift,
          ),
        ),
      ),
    )
  }
  stmts.push(
    @types.Stmt::move_stmt(
      tmp,
      project_basic_bil_x86_not(@types.Exp::var_exp(tmp)),
    ),
  )
  match project_basic_bil_bitscan_popcount(tmp, width) {
    Ok(popcount) => {
      for stmt in popcount {
        stmts.push(stmt)
      }
      Ok(stmts)
    }
    Err(reason) => Err(reason)
  }
}

///|
fn project_basic_bil_bitscan_flags() -> Array[@types.Stmt] {
  [
    project_basic_bil_x86_flag_move("CF", @types.Exp::unknown("bits", Imm(1))),
    project_basic_bil_x86_flag_move("OF", @types.Exp::unknown("bits", Imm(1))),
    project_basic_bil_x86_flag_move("SF", @types.Exp::unknown("bits", Imm(1))),
    project_basic_bil_x86_flag_move("AF", @types.Exp::unknown("bits", Imm(1))),
    project_basic_bil_x86_flag_move("PF", @types.Exp::unknown("bits", Imm(1))),
  ]
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_bitscan_common(
  self : ProjectDisassemblyInstruction,
  width : Int,
  source : @types.Exp,
  forward : Bool,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let zero_word = match project_basic_bil_int(0L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let zero_flag = match project_basic_bil_int(0L, 1) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let one = match project_basic_bil_int(1L, 1) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let width_minus_one = match
    project_basic_bil_int((width - 1).to_int64(), width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let tmp = project_basic_bil_virtual("bitscan", width)
  let scan = if forward {
    match project_basic_bil_bitscan_ctz(tmp, width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
  } else {
    match project_basic_bil_bitscan_clz(tmp, width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
  }
  let result = if forward {
    @types.Exp::var_exp(tmp)
  } else {
    project_basic_bil_x86_xor(@types.Exp::var_exp(tmp), width_minus_one)
  }
  let no_branch = [@types.Stmt::move_stmt(tmp, source)]
  for stmt in scan {
    no_branch.push(stmt)
  }
  no_branch.push(@types.Stmt::move_stmt(dst, result))
  no_branch.push(project_basic_bil_x86_flag_move("ZF", zero_flag))
  let stmts = [
    @types.Stmt::if_(
      @types.Exp::binop(@types.BinOp::eq(), source, zero_word),
      [
        project_basic_bil_x86_flag_move("ZF", one),
        @types.Stmt::move_stmt(dst, @types.Exp::unknown("bits", Imm(width))),
      ],
      no_branch,
    ),
  ]
  for stmt in project_basic_bil_bitscan_flags() {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_bitscan_rr(
  self : ProjectDisassemblyInstruction,
  width : Int,
  forward : Bool,
) -> Result[Array[@types.Stmt], String] {
  let source = match self.project_basic_bil_register(1, width) {
    Ok(value) => @types.Exp::var_exp(value)
    Err(reason) => return Err(reason)
  }
  self.project_basic_bil_bitscan_common(width, source, forward)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_bitscan_rm(
  self : ProjectDisassemblyInstruction,
  width : Int,
  forward : Bool,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, _) = match self.project_basic_bil_memory_addr(1) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let source = @types.Exp::load(
    mem=@types.Exp::var_exp(mem),
    addr~,
    LittleEndian,
    size,
  )
  self.project_basic_bil_bitscan_common(width, source, forward)
}

///|
fn project_basic_bil_popcnt_clear_flags() -> Result[Array[@types.Stmt], String] {
  let zero = match project_basic_bil_int(0L, 1) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok([
    project_basic_bil_x86_flag_move("CF", zero),
    project_basic_bil_x86_flag_move("OF", zero),
    project_basic_bil_x86_flag_move("SF", zero),
    project_basic_bil_x86_flag_move("AF", zero),
    project_basic_bil_x86_flag_move("PF", zero),
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_popcnt_common(
  self : ProjectDisassemblyInstruction,
  width : Int,
  source : @types.Exp,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let zero = match project_basic_bil_int(0L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let tmp = project_basic_bil_virtual("popcnt", width)
  let stmts = [
    project_basic_bil_x86_flag_move(
      "ZF",
      @types.Exp::binop(@types.BinOp::eq(), zero, source),
    ),
    @types.Stmt::move_stmt(tmp, source),
  ]
  match project_basic_bil_bitscan_popcount(tmp, width) {
    Ok(popcount) =>
      for stmt in popcount {
        stmts.push(stmt)
      }
    Err(reason) => return Err(reason)
  }
  stmts.push(@types.Stmt::move_stmt(dst, @types.Exp::var_exp(tmp)))
  match project_basic_bil_popcnt_clear_flags() {
    Ok(flags) =>
      for stmt in flags {
        stmts.push(stmt)
      }
    Err(reason) => return Err(reason)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_popcnt_rr(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let source = match self.project_basic_bil_register(1, width) {
    Ok(value) => @types.Exp::var_exp(value)
    Err(reason) => return Err(reason)
  }
  self.project_basic_bil_popcnt_common(width, source)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_popcnt_rm(
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
  let source = @types.Exp::load(
    mem=@types.Exp::var_exp(mem),
    addr~,
    LittleEndian,
    size,
  )
  self.project_basic_bil_popcnt_common(width, source)
}

///|
fn project_basic_bil_count_zero_undefined_flags(
  op : String,
) -> Array[@types.Stmt] {
  [
    project_basic_bil_x86_flag_move("OF", @types.Exp::unknown(op, Imm(1))),
    project_basic_bil_x86_flag_move("SF", @types.Exp::unknown(op, Imm(1))),
    project_basic_bil_x86_flag_move("AF", @types.Exp::unknown(op, Imm(1))),
    project_basic_bil_x86_flag_move("PF", @types.Exp::unknown(op, Imm(1))),
  ]
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_count_zero_common(
  self : ProjectDisassemblyInstruction,
  width : Int,
  source : @types.Exp,
  trailing : Bool,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let zero = match project_basic_bil_int(0L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let tmp = project_basic_bil_virtual("cntzero", width)
  let scan = if trailing {
    match project_basic_bil_bitscan_ctz(tmp, width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
  } else {
    match project_basic_bil_bitscan_clz(tmp, width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
  }
  let op = if trailing { "tzcnt" } else { "lzcnt" }
  let stmts = [@types.Stmt::move_stmt(tmp, source)]
  for stmt in scan {
    stmts.push(stmt)
  }
  stmts.push(@types.Stmt::move_stmt(dst, @types.Exp::var_exp(tmp)))
  stmts.push(
    project_basic_bil_x86_flag_move(
      "CF",
      @types.Exp::binop(@types.BinOp::eq(), source, zero),
    ),
  )
  stmts.push(
    project_basic_bil_x86_flag_move(
      "ZF",
      @types.Exp::binop(@types.BinOp::eq(), @types.Exp::var_exp(tmp), zero),
    ),
  )
  for stmt in project_basic_bil_count_zero_undefined_flags(op) {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_count_zero_rr(
  self : ProjectDisassemblyInstruction,
  width : Int,
  trailing : Bool,
) -> Result[Array[@types.Stmt], String] {
  let source = match self.project_basic_bil_register(1, width) {
    Ok(value) => @types.Exp::var_exp(value)
    Err(reason) => return Err(reason)
  }
  self.project_basic_bil_count_zero_common(width, source, trailing)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_count_zero_rm(
  self : ProjectDisassemblyInstruction,
  width : Int,
  trailing : Bool,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, _) = match self.project_basic_bil_memory_addr(1) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let source = @types.Exp::load(
    mem=@types.Exp::var_exp(mem),
    addr~,
    LittleEndian,
    size,
  )
  self.project_basic_bil_count_zero_common(width, source, trailing)
}

///|
fn project_basic_bil_btx_offset_width(width : Int) -> Result[Int, String] {
  match width {
    16 => Ok(4)
    32 => Ok(5)
    64 => Ok(6)
    _ => Err("unsupported btx width \{width}")
  }
}

///|
fn project_basic_bil_btx_truncated_offset(
  offset : Int64,
  offset_width : Int,
) -> Result[(Int, @types.Exp), String] {
  let raw = match @types.int_of_int64(offset) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let truncated = raw & ((1 << offset_width) - 1)
  match project_basic_bil_int(truncated.to_int64(), offset_width) {
    Ok(exp) => Ok((truncated, exp))
    Err(reason) => Err(reason)
  }
}

///|
fn project_basic_bil_btx_mask_reg(
  width : Int,
  offset : @types.Exp,
) -> Result[@types.Exp, String] {
  match project_basic_bil_int(1L, width) {
    Ok(one) => Ok(@types.Exp::binop(@types.BinOp::lshift(), one, offset))
    Err(reason) => Err(reason)
  }
}

///|
fn project_basic_bil_btx_mask_imm(
  width : Int,
  offset : Int,
) -> Result[@types.Exp, String] {
  project_basic_bil_addr_with_width(1UL << offset, width)
}

///|
fn project_basic_bil_btx_flags(
  op : String,
  data : @types.Exp,
  offset : @types.Exp,
) -> Array[@types.Stmt] {
  let selected = @types.Exp::cast(
    @types.CastKind::low(),
    1,
    @types.Exp::binop(@types.BinOp::rshift(), data, offset),
  )
  let unknown = fn() { @types.Exp::unknown(op.to_lower(), Imm(1)) }
  [
    project_basic_bil_x86_flag_move("CF", selected),
    project_basic_bil_x86_flag_move("OF", unknown()),
    project_basic_bil_x86_flag_move("SF", unknown()),
    project_basic_bil_x86_flag_move("ZF", unknown()),
    project_basic_bil_x86_flag_move("AF", unknown()),
    project_basic_bil_x86_flag_move("PF", unknown()),
  ]
}

///|
fn project_basic_bil_btx_side_effect(
  op : String,
  data : @types.Exp,
  mask : @types.Exp,
) -> Result[@types.Exp?, String] {
  match op {
    "BT" => Ok(None)
    "BTC" => Ok(Some(project_basic_bil_x86_xor(data, mask)))
    "BTR" =>
      Ok(Some(project_basic_bil_x86_and(data, project_basic_bil_x86_not(mask))))
    "BTS" => Ok(Some(project_basic_bil_x86_or(data, mask)))
    _ => Err("unsupported btx operation \{op}")
  }
}

///|
fn project_basic_bil_btx_store(
  mem : @types.Var,
  addr : @types.Exp,
  width : Int,
  value : @types.Exp,
) -> Result[@types.Stmt, String] {
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok(
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
  )
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_btx_rr(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : String,
) -> Result[Array[@types.Stmt], String] {
  let offset_width = match project_basic_bil_btx_offset_width(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let base = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let offset = match self.project_basic_bil_register(1, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let offset_tmp = project_basic_bil_virtual("btx_o", offset_width)
  let offset_tmp_exp = @types.Exp::var_exp(offset_tmp)
  let data = @types.Exp::var_exp(base)
  let mask = match project_basic_bil_btx_mask_reg(width, offset_tmp_exp) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(
      offset_tmp,
      @types.Exp::cast(
        @types.CastKind::low(),
        offset_width,
        @types.Exp::var_exp(offset),
      ),
    ),
  ]
  for stmt in project_basic_bil_btx_flags(op, data, offset_tmp_exp) {
    stmts.push(stmt)
  }
  match project_basic_bil_btx_side_effect(op, @types.Exp::var_exp(base), mask) {
    Ok(Some(updated)) => stmts.push(@types.Stmt::move_stmt(base, updated))
    Ok(None) => ()
    Err(reason) => return Err(reason)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_btx_ri(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : String,
) -> Result[Array[@types.Stmt], String] {
  let offset_width = match project_basic_bil_btx_offset_width(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let base = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let raw_offset = match self.project_basic_bil_immediate(1) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (offset_value, offset) = match
    project_basic_bil_btx_truncated_offset(raw_offset, offset_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let mask = match project_basic_bil_btx_mask_imm(width, offset_value) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = project_basic_bil_btx_flags(op, @types.Exp::var_exp(base), offset)
  match project_basic_bil_btx_side_effect(op, @types.Exp::var_exp(base), mask) {
    Ok(Some(updated)) => stmts.push(@types.Stmt::move_stmt(base, updated))
    Ok(None) => ()
    Err(reason) => return Err(reason)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_btx_mi(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : String,
) -> Result[Array[@types.Stmt], String] {
  let offset_width = match project_basic_bil_btx_offset_width(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let raw_offset = match self.project_basic_bil_immediate(5) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (offset_value, offset) = match
    project_basic_bil_btx_truncated_offset(raw_offset, offset_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let mask = match project_basic_bil_btx_mask_imm(width, offset_value) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("btx_a", address_width)
  let data_tmp = project_basic_bil_virtual("btx_d", width)
  let stmts = [
    @types.Stmt::move_stmt(addr_tmp, addr),
    @types.Stmt::move_stmt(
      data_tmp,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=@types.Exp::var_exp(addr_tmp),
        LittleEndian,
        size,
      ),
    ),
  ]
  for
    stmt in project_basic_bil_btx_flags(
      op,
      @types.Exp::var_exp(data_tmp),
      offset,
    ) {
    stmts.push(stmt)
  }
  match
    project_basic_bil_btx_side_effect(op, @types.Exp::var_exp(data_tmp), mask) {
    Ok(Some(updated)) =>
      match
        project_basic_bil_btx_store(
          mem,
          @types.Exp::var_exp(addr_tmp),
          width,
          updated,
        ) {
        Ok(stmt) => stmts.push(stmt)
        Err(reason) => return Err(reason)
      }
    Ok(None) => ()
    Err(reason) => return Err(reason)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_btx_mr(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : String,
) -> Result[Array[@types.Stmt], String] {
  let offset_width = match project_basic_bil_btx_offset_width(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let offset = match self.project_basic_bil_register(5, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size_bytes = match project_basic_bil_int((width / 8).to_int64(), width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let bits_per_word = match project_basic_bil_int(width.to_int64(), width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let offset_tmp = project_basic_bil_virtual("btx_o", offset_width)
  let addr_tmp = project_basic_bil_virtual("btx_a", address_width)
  let byte_tmp = project_basic_bil_virtual("btx_b", address_width)
  let data_tmp = project_basic_bil_virtual("btx_d", width)
  let offset_exp = @types.Exp::var_exp(offset)
  let byte_offset = @types.Exp::binop(
    @types.BinOp::times(),
    size_bytes,
    @types.Exp::binop(@types.BinOp::sdivide(), offset_exp, bits_per_word),
  )
  let byte_offset = if address_width == width {
    byte_offset
  } else {
    @types.Exp::cast(@types.CastKind::signed(), address_width, byte_offset)
  }
  let effective_addr = @types.Exp::binop(
    @types.BinOp::plus(),
    @types.Exp::var_exp(addr_tmp),
    @types.Exp::var_exp(byte_tmp),
  )
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let mask = match
    project_basic_bil_btx_mask_reg(width, @types.Exp::var_exp(offset_tmp)) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(addr_tmp, addr),
    @types.Stmt::move_stmt(byte_tmp, byte_offset),
    @types.Stmt::move_stmt(
      data_tmp,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=effective_addr,
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(
      offset_tmp,
      @types.Exp::cast(@types.CastKind::low(), offset_width, offset_exp),
    ),
  ]
  for
    stmt in project_basic_bil_btx_flags(
      op,
      @types.Exp::var_exp(data_tmp),
      @types.Exp::var_exp(offset_tmp),
    ) {
    stmts.push(stmt)
  }
  match
    project_basic_bil_btx_side_effect(op, @types.Exp::var_exp(data_tmp), mask) {
    Ok(Some(updated)) =>
      match project_basic_bil_btx_store(mem, effective_addr, width, updated) {
        Ok(stmt) => stmts.push(stmt)
        Err(reason) => return Err(reason)
      }
    Ok(None) => ()
    Err(reason) => return Err(reason)
  }
  Ok(stmts)
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
fn project_basic_bil_x86_add_carryless_flag_moves(
  lhs : @types.Exp,
  rhs : @types.Exp,
  result : @types.Exp,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let lhs_high = @types.Exp::cast(@types.CastKind::high(), 1, lhs)
  let rhs_high = @types.Exp::cast(@types.CastKind::high(), 1, rhs)
  let result_high = @types.Exp::cast(@types.CastKind::high(), 1, result)
  let stmts = [
    project_basic_bil_x86_flag_move(
      "OF",
      @types.Exp::binop(
        @types.BinOp::bit_and(),
        @types.Exp::binop(@types.BinOp::eq(), lhs_high, rhs_high),
        project_basic_bil_x86_xor(lhs_high, result_high),
      ),
    ),
  ]
  match project_basic_bil_x86_apszf_flag_moves(lhs, rhs, result, width) {
    Ok(flags) => {
      for stmt in flags {
        stmts.push(stmt)
      }
      Ok(stmts)
    }
    Err(reason) => Err(reason)
  }
}

///|
fn project_basic_bil_x86_add_flag_moves(
  lhs : @types.Exp,
  rhs : @types.Exp,
  result : @types.Exp,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let stmts = [
    project_basic_bil_x86_flag_move(
      "CF",
      @types.Exp::binop(@types.BinOp::lt(), result, lhs),
    ),
  ]
  match
    project_basic_bil_x86_add_carryless_flag_moves(lhs, rhs, result, width) {
    Ok(flags) => {
      for stmt in flags {
        stmts.push(stmt)
      }
      Ok(stmts)
    }
    Err(reason) => Err(reason)
  }
}

///|
fn project_basic_bil_x86_apszf_flag_moves(
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
  Ok([
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
fn project_basic_bil_x86_logical_flag_moves(
  result : @types.Exp,
  width : Int,
  af_reason : String,
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
      @types.Exp::unknown(af_reason, Imm(1)),
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
  project_basic_bil_x86_logical_flag_moves(
    result, width, "AF undefined after TEST",
  )
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
  if width != 16 && width != 32 && width != 64 {
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
  value_width : Int,
  address_width : Int,
) -> Result[Array[@types.Stmt], String] {
  match project_basic_bil_x86_flags_image(value_width) {
    Ok(flags) => project_basic_bil_push_exp(flags, value_width, address_width)
    Err(reason) => Err(reason)
  }
}

///|
fn project_basic_bil_x86_popf(
  value_width : Int,
  address_width : Int,
) -> Result[Array[@types.Stmt], String] {
  if value_width != 16 && value_width != 32 && value_width != 64 {
    return Err("unsupported POPF width \{value_width}")
  }
  let sp = match project_basic_bil_stack_pointer(address_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let updated_sp = match
    project_basic_bil_stack_increment(sp, value_width, address_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(value_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let mem = project_basic_bil_stack_mem(address_width)
  let flags = project_basic_bil_virtual("popf_flags", value_width)
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
fn project_basic_bil_x86_addsub_prefix(
  op : @types.BinOp,
) -> Result[String, String] {
  if op == @types.BinOp::plus() {
    Ok("add")
  } else if op == @types.BinOp::minus() {
    Ok("sub")
  } else {
    Err("unsupported x86 ADD/SUB operation")
  }
}

///|
fn project_basic_bil_x86_addsub_flag_moves(
  lhs : @types.Exp,
  rhs : @types.Exp,
  result : @types.Exp,
  width : Int,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  if op == @types.BinOp::plus() {
    project_basic_bil_x86_add_flag_moves(lhs, rhs, result, width)
  } else if op == @types.BinOp::minus() {
    project_basic_bil_x86_sub_flag_moves(lhs, rhs, result, width)
  } else {
    Err("unsupported x86 ADD/SUB flag operation")
  }
}

///|
fn project_basic_bil_x86_append_addsub_flags(
  stmts : Array[@types.Stmt],
  lhs : @types.Exp,
  rhs : @types.Exp,
  result : @types.Exp,
  width : Int,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  let flags = match
    project_basic_bil_x86_addsub_flag_moves(lhs, rhs, result, width, op) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_addsub_common(
  self : ProjectDisassemblyInstruction,
  width : Int,
  lhs : @types.Exp,
  rhs : @types.Exp,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  let prefix = match project_basic_bil_x86_addsub_prefix(op) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let orig_dst = project_basic_bil_virtual("\{prefix}_dst", width)
  let orig_src = project_basic_bil_virtual("\{prefix}_src", width)
  let orig_dst_exp = @types.Exp::var_exp(orig_dst)
  let orig_src_exp = @types.Exp::var_exp(orig_src)
  let result_exp = @types.Exp::var_exp(dst)
  project_basic_bil_x86_append_addsub_flags(
    [
      @types.Stmt::move_stmt(orig_dst, lhs),
      @types.Stmt::move_stmt(orig_src, rhs),
      @types.Stmt::move_stmt(
        dst,
        @types.Exp::binop(op, orig_dst_exp, orig_src_exp),
      ),
    ],
    orig_dst_exp,
    orig_src_exp,
    result_exp,
    width,
    op,
  )
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_addsub_ri(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  let src = match self.project_basic_bil_register(1, width) {
    Ok(value) => @types.Exp::var_exp(value)
    Err(reason) => return Err(reason)
  }
  let imm = match self.project_basic_bil_immediate(2) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs = match project_basic_bil_int(imm, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  self.project_basic_bil_addsub_common(width, src, rhs, op)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_addsub_mi(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  let prefix = match project_basic_bil_x86_addsub_prefix(op) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let imm = match self.project_basic_bil_immediate(5) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs = match project_basic_bil_int(imm, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("\{prefix}_a", address_width)
  let orig_dst = project_basic_bil_virtual("\{prefix}_dst", width)
  let orig_src = project_basic_bil_virtual("\{prefix}_src", width)
  let result = project_basic_bil_virtual("\{prefix}_res", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let orig_dst_exp = @types.Exp::var_exp(orig_dst)
  let orig_src_exp = @types.Exp::var_exp(orig_src)
  let result_exp = @types.Exp::var_exp(result)
  project_basic_bil_x86_append_addsub_flags(
    [
      @types.Stmt::move_stmt(addr_tmp, addr),
      @types.Stmt::move_stmt(
        orig_dst,
        @types.Exp::load(
          mem=@types.Exp::var_exp(mem),
          addr=addr_exp,
          LittleEndian,
          size,
        ),
      ),
      @types.Stmt::move_stmt(orig_src, rhs),
      @types.Stmt::move_stmt(
        result,
        @types.Exp::binop(op, orig_dst_exp, orig_src_exp),
      ),
      @types.Stmt::move_stmt(
        mem,
        @types.Exp::store(
          mem=@types.Exp::var_exp(mem),
          addr=addr_exp,
          result_exp,
          LittleEndian,
          size,
        ),
      ),
    ],
    orig_dst_exp,
    orig_src_exp,
    result_exp,
    width,
    op,
  )
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_addsub_rm(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
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
  self.project_basic_bil_addsub_common(
    width,
    @types.Exp::var_exp(dst),
    @types.Exp::load(mem=@types.Exp::var_exp(mem), addr~, LittleEndian, size),
    op,
  )
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_addsub_mr(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  let prefix = match project_basic_bil_x86_addsub_prefix(op) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = match self.project_basic_bil_register(5, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("\{prefix}_a", address_width)
  let orig_dst = project_basic_bil_virtual("\{prefix}_dst", width)
  let orig_src = project_basic_bil_virtual("\{prefix}_src", width)
  let result = project_basic_bil_virtual("\{prefix}_res", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let orig_dst_exp = @types.Exp::var_exp(orig_dst)
  let orig_src_exp = @types.Exp::var_exp(orig_src)
  let result_exp = @types.Exp::var_exp(result)
  project_basic_bil_x86_append_addsub_flags(
    [
      @types.Stmt::move_stmt(addr_tmp, addr),
      @types.Stmt::move_stmt(
        orig_dst,
        @types.Exp::load(
          mem=@types.Exp::var_exp(mem),
          addr=addr_exp,
          LittleEndian,
          size,
        ),
      ),
      @types.Stmt::move_stmt(orig_src, @types.Exp::var_exp(src)),
      @types.Stmt::move_stmt(
        result,
        @types.Exp::binop(op, orig_dst_exp, orig_src_exp),
      ),
      @types.Stmt::move_stmt(
        mem,
        @types.Exp::store(
          mem=@types.Exp::var_exp(mem),
          addr=addr_exp,
          result_exp,
          LittleEndian,
          size,
        ),
      ),
    ],
    orig_dst_exp,
    orig_src_exp,
    result_exp,
    width,
    op,
  )
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_addsub_rr(
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
  self.project_basic_bil_addsub_common(
    width,
    @types.Exp::var_exp(dst),
    @types.Exp::var_exp(src),
    op,
  )
}

///|
fn project_basic_bil_x86_append_logical_flags(
  stmts : Array[@types.Stmt],
  result : @types.Exp,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let flags = match
    project_basic_bil_x86_logical_flag_moves(
      result, width, "AF undefined after logical operation",
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_logic_ri(
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
  let imm = match self.project_basic_bil_immediate(2) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs = match project_basic_bil_int(imm, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let result_exp = @types.Exp::var_exp(dst)
  project_basic_bil_x86_append_logical_flags(
    [
      @types.Stmt::move_stmt(
        dst,
        @types.Exp::binop(op, @types.Exp::var_exp(src), rhs),
      ),
    ],
    result_exp,
    width,
  )
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_logic_mi(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let imm = match self.project_basic_bil_immediate(5) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs = match project_basic_bil_int(imm, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("logic_a", address_width)
  let data_tmp = project_basic_bil_virtual("logic_d", width)
  let result_tmp = project_basic_bil_virtual("logic_r", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let data_exp = @types.Exp::var_exp(data_tmp)
  let result_exp = @types.Exp::var_exp(result_tmp)
  project_basic_bil_x86_append_logical_flags(
    [
      @types.Stmt::move_stmt(addr_tmp, addr),
      @types.Stmt::move_stmt(
        data_tmp,
        @types.Exp::load(
          mem=@types.Exp::var_exp(mem),
          addr=addr_exp,
          LittleEndian,
          size,
        ),
      ),
      @types.Stmt::move_stmt(result_tmp, @types.Exp::binop(op, data_exp, rhs)),
      @types.Stmt::move_stmt(
        mem,
        @types.Exp::store(
          mem=@types.Exp::var_exp(mem),
          addr=addr_exp,
          result_exp,
          LittleEndian,
          size,
        ),
      ),
    ],
    result_exp,
    width,
  )
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_logic_rm(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
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
  let result_exp = @types.Exp::var_exp(dst)
  project_basic_bil_x86_append_logical_flags(
    [
      @types.Stmt::move_stmt(
        dst,
        @types.Exp::binop(
          op,
          @types.Exp::var_exp(dst),
          @types.Exp::load(
            mem=@types.Exp::var_exp(mem),
            addr~,
            LittleEndian,
            size,
          ),
        ),
      ),
    ],
    result_exp,
    width,
  )
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_logic_mr(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = match self.project_basic_bil_register(5, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("logic_a", address_width)
  let data_tmp = project_basic_bil_virtual("logic_d", width)
  let result_tmp = project_basic_bil_virtual("logic_r", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let data_exp = @types.Exp::var_exp(data_tmp)
  let result_exp = @types.Exp::var_exp(result_tmp)
  project_basic_bil_x86_append_logical_flags(
    [
      @types.Stmt::move_stmt(addr_tmp, addr),
      @types.Stmt::move_stmt(
        data_tmp,
        @types.Exp::load(
          mem=@types.Exp::var_exp(mem),
          addr=addr_exp,
          LittleEndian,
          size,
        ),
      ),
      @types.Stmt::move_stmt(
        result_tmp,
        @types.Exp::binop(op, data_exp, @types.Exp::var_exp(src)),
      ),
      @types.Stmt::move_stmt(
        mem,
        @types.Exp::store(
          mem=@types.Exp::var_exp(mem),
          addr=addr_exp,
          result_exp,
          LittleEndian,
          size,
        ),
      ),
    ],
    result_exp,
    width,
  )
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_logic_rr(
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
  let rhs = if op == @types.BinOp::bit_xor() && dst == src {
    match project_basic_bil_int(0L, width) {
      Ok(zero) => zero
      Err(reason) => return Err(reason)
    }
  } else {
    @types.Exp::binop(op, @types.Exp::var_exp(dst), @types.Exp::var_exp(src))
  }
  let result_exp = @types.Exp::var_exp(dst)
  project_basic_bil_x86_append_logical_flags(
    [@types.Stmt::move_stmt(dst, rhs)],
    result_exp,
    width,
  )
}

///|
fn project_basic_bil_x86_carry(width : Int) -> @types.Exp {
  @types.Exp::cast(
    @types.CastKind::unsigned(),
    width,
    project_basic_bil_x86_flag("CF"),
  )
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_adc_common(
  self : ProjectDisassemblyInstruction,
  width : Int,
  rhs : @types.Exp,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let orig_dst = project_basic_bil_virtual("adc_dst", width)
  let orig_src = project_basic_bil_virtual("adc_src", width)
  let orig_dst_exp = @types.Exp::var_exp(orig_dst)
  let orig_src_exp = @types.Exp::var_exp(orig_src)
  let result_exp = @types.Exp::var_exp(dst)
  let carry = project_basic_bil_x86_carry(width)
  let wide_width = width + 1
  let wide_sum = @types.Exp::binop(
    @types.BinOp::plus(),
    @types.Exp::binop(
      @types.BinOp::plus(),
      @types.Exp::cast(@types.CastKind::unsigned(), wide_width, orig_dst_exp),
      @types.Exp::cast(@types.CastKind::unsigned(), wide_width, orig_src_exp),
    ),
    @types.Exp::cast(@types.CastKind::unsigned(), wide_width, carry),
  )
  let flags = match
    project_basic_bil_x86_add_carryless_flag_moves(
      orig_dst_exp, orig_src_exp, result_exp, width,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(orig_dst, result_exp),
    @types.Stmt::move_stmt(orig_src, rhs),
    @types.Stmt::move_stmt(
      dst,
      @types.Exp::binop(
        @types.BinOp::plus(),
        @types.Exp::binop(@types.BinOp::plus(), orig_dst_exp, orig_src_exp),
        carry,
      ),
    ),
    project_basic_bil_x86_flag_move(
      "CF",
      @types.Exp::extract(wide_sum, hi=width, lo=width),
    ),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_adc_mi(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let imm = match self.project_basic_bil_immediate(5) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs = match project_basic_bil_int(imm, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("adc_a", address_width)
  let orig_dst = project_basic_bil_virtual("adc_dst", width)
  let orig_src = project_basic_bil_virtual("adc_src", width)
  let result = project_basic_bil_virtual("adc_res", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let orig_dst_exp = @types.Exp::var_exp(orig_dst)
  let orig_src_exp = @types.Exp::var_exp(orig_src)
  let result_exp = @types.Exp::var_exp(result)
  let carry = project_basic_bil_x86_carry(width)
  let wide_width = width + 1
  let wide_sum = @types.Exp::binop(
    @types.BinOp::plus(),
    @types.Exp::binop(
      @types.BinOp::plus(),
      @types.Exp::cast(@types.CastKind::unsigned(), wide_width, orig_dst_exp),
      @types.Exp::cast(@types.CastKind::unsigned(), wide_width, orig_src_exp),
    ),
    @types.Exp::cast(@types.CastKind::unsigned(), wide_width, carry),
  )
  let flags = match
    project_basic_bil_x86_add_carryless_flag_moves(
      orig_dst_exp, orig_src_exp, result_exp, width,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(addr_tmp, addr),
    @types.Stmt::move_stmt(
      orig_dst,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(orig_src, rhs),
    @types.Stmt::move_stmt(
      result,
      @types.Exp::binop(
        @types.BinOp::plus(),
        @types.Exp::binop(@types.BinOp::plus(), orig_dst_exp, orig_src_exp),
        carry,
      ),
    ),
    @types.Stmt::move_stmt(
      mem,
      @types.Exp::store(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        result_exp,
        LittleEndian,
        size,
      ),
    ),
    project_basic_bil_x86_flag_move(
      "CF",
      @types.Exp::extract(wide_sum, hi=width, lo=width),
    ),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_sbb_common(
  self : ProjectDisassemblyInstruction,
  width : Int,
  rhs : @types.Exp,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let orig_src = project_basic_bil_virtual("sbb_src", width)
  let orig_dst = project_basic_bil_virtual("sbb_dst", width)
  let orig_src_exp = @types.Exp::var_exp(orig_src)
  let orig_dst_exp = @types.Exp::var_exp(orig_dst)
  let result_exp = @types.Exp::var_exp(dst)
  let carry = project_basic_bil_x86_carry(width)
  let borrowed = @types.Exp::binop(@types.BinOp::plus(), orig_src_exp, carry)
  let flags = match
    project_basic_bil_x86_apszf_flag_moves(
      orig_src_exp, orig_dst_exp, result_exp, width,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(orig_src, rhs),
    @types.Stmt::move_stmt(orig_dst, result_exp),
    @types.Stmt::move_stmt(
      dst,
      @types.Exp::binop(@types.BinOp::minus(), orig_dst_exp, borrowed),
    ),
    project_basic_bil_x86_flag_move(
      "OF",
      @types.Exp::cast(
        @types.CastKind::high(),
        1,
        @types.Exp::binop(
          @types.BinOp::bit_and(),
          project_basic_bil_x86_xor(orig_src_exp, orig_dst_exp),
          project_basic_bil_x86_xor(orig_dst_exp, result_exp),
        ),
      ),
    ),
    project_basic_bil_x86_flag_move(
      "CF",
      @types.Exp::binop(
        @types.BinOp::bit_or(),
        @types.Exp::binop(@types.BinOp::lt(), orig_dst_exp, borrowed),
        @types.Exp::binop(@types.BinOp::lt(), borrowed, orig_src_exp),
      ),
    ),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_sbb_mi(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let imm = match self.project_basic_bil_immediate(5) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs = match project_basic_bil_int(imm, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("sbb_a", address_width)
  let orig_src = project_basic_bil_virtual("sbb_src", width)
  let orig_dst = project_basic_bil_virtual("sbb_dst", width)
  let result = project_basic_bil_virtual("sbb_res", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let orig_src_exp = @types.Exp::var_exp(orig_src)
  let orig_dst_exp = @types.Exp::var_exp(orig_dst)
  let result_exp = @types.Exp::var_exp(result)
  let carry = project_basic_bil_x86_carry(width)
  let borrowed = @types.Exp::binop(@types.BinOp::plus(), orig_src_exp, carry)
  let flags = match
    project_basic_bil_x86_apszf_flag_moves(
      orig_src_exp, orig_dst_exp, result_exp, width,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(addr_tmp, addr),
    @types.Stmt::move_stmt(
      orig_dst,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(orig_src, rhs),
    @types.Stmt::move_stmt(
      result,
      @types.Exp::binop(@types.BinOp::minus(), orig_dst_exp, borrowed),
    ),
    @types.Stmt::move_stmt(
      mem,
      @types.Exp::store(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        result_exp,
        LittleEndian,
        size,
      ),
    ),
    project_basic_bil_x86_flag_move(
      "OF",
      @types.Exp::cast(
        @types.CastKind::high(),
        1,
        @types.Exp::binop(
          @types.BinOp::bit_and(),
          project_basic_bil_x86_xor(orig_src_exp, orig_dst_exp),
          project_basic_bil_x86_xor(orig_dst_exp, result_exp),
        ),
      ),
    ),
    project_basic_bil_x86_flag_move(
      "CF",
      @types.Exp::binop(
        @types.BinOp::bit_or(),
        @types.Exp::binop(@types.BinOp::lt(), orig_dst_exp, borrowed),
        @types.Exp::binop(@types.BinOp::lt(), borrowed, orig_src_exp),
      ),
    ),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_adc_rr(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let src = match self.project_basic_bil_register(1, width) {
    Ok(value) => @types.Exp::var_exp(value)
    Err(reason) => return Err(reason)
  }
  self.project_basic_bil_adc_common(width, src)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_adc_ri(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let imm = match self.project_basic_bil_immediate(2) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = match project_basic_bil_int(imm, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  self.project_basic_bil_adc_common(width, src)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_adc_rm(
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
  self.project_basic_bil_adc_common(width, src)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_adc_mr(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = match self.project_basic_bil_register(5, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("adc_a", address_width)
  let orig_dst = project_basic_bil_virtual("adc_dst", width)
  let orig_src = project_basic_bil_virtual("adc_src", width)
  let result = project_basic_bil_virtual("adc_res", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let orig_dst_exp = @types.Exp::var_exp(orig_dst)
  let orig_src_exp = @types.Exp::var_exp(orig_src)
  let result_exp = @types.Exp::var_exp(result)
  let carry = project_basic_bil_x86_carry(width)
  let wide_width = width + 1
  let wide_sum = @types.Exp::binop(
    @types.BinOp::plus(),
    @types.Exp::binop(
      @types.BinOp::plus(),
      @types.Exp::cast(@types.CastKind::unsigned(), wide_width, orig_dst_exp),
      @types.Exp::cast(@types.CastKind::unsigned(), wide_width, orig_src_exp),
    ),
    @types.Exp::cast(@types.CastKind::unsigned(), wide_width, carry),
  )
  let flags = match
    project_basic_bil_x86_add_carryless_flag_moves(
      orig_dst_exp, orig_src_exp, result_exp, width,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(addr_tmp, addr),
    @types.Stmt::move_stmt(
      orig_dst,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(orig_src, @types.Exp::var_exp(src)),
    @types.Stmt::move_stmt(
      result,
      @types.Exp::binop(
        @types.BinOp::plus(),
        @types.Exp::binop(@types.BinOp::plus(), orig_dst_exp, orig_src_exp),
        carry,
      ),
    ),
    @types.Stmt::move_stmt(
      mem,
      @types.Exp::store(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        result_exp,
        LittleEndian,
        size,
      ),
    ),
    project_basic_bil_x86_flag_move(
      "CF",
      @types.Exp::extract(wide_sum, hi=width, lo=width),
    ),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_sbb_rr(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let src = match self.project_basic_bil_register(1, width) {
    Ok(value) => @types.Exp::var_exp(value)
    Err(reason) => return Err(reason)
  }
  self.project_basic_bil_sbb_common(width, src)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_sbb_ri(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let imm = match self.project_basic_bil_immediate(2) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = match project_basic_bil_int(imm, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  self.project_basic_bil_sbb_common(width, src)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_sbb_rm(
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
  self.project_basic_bil_sbb_common(width, src)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_sbb_mr(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = match self.project_basic_bil_register(5, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("sbb_a", address_width)
  let orig_src = project_basic_bil_virtual("sbb_src", width)
  let orig_dst = project_basic_bil_virtual("sbb_dst", width)
  let result = project_basic_bil_virtual("sbb_res", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let orig_src_exp = @types.Exp::var_exp(orig_src)
  let orig_dst_exp = @types.Exp::var_exp(orig_dst)
  let result_exp = @types.Exp::var_exp(result)
  let carry = project_basic_bil_x86_carry(width)
  let borrowed = @types.Exp::binop(@types.BinOp::plus(), orig_src_exp, carry)
  let flags = match
    project_basic_bil_x86_apszf_flag_moves(
      orig_src_exp, orig_dst_exp, result_exp, width,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(addr_tmp, addr),
    @types.Stmt::move_stmt(
      orig_dst,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(orig_src, @types.Exp::var_exp(src)),
    @types.Stmt::move_stmt(
      result,
      @types.Exp::binop(@types.BinOp::minus(), orig_dst_exp, borrowed),
    ),
    @types.Stmt::move_stmt(
      mem,
      @types.Exp::store(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        result_exp,
        LittleEndian,
        size,
      ),
    ),
    project_basic_bil_x86_flag_move(
      "OF",
      @types.Exp::cast(
        @types.CastKind::high(),
        1,
        @types.Exp::binop(
          @types.BinOp::bit_and(),
          project_basic_bil_x86_xor(orig_src_exp, orig_dst_exp),
          project_basic_bil_x86_xor(orig_dst_exp, result_exp),
        ),
      ),
    ),
    project_basic_bil_x86_flag_move(
      "CF",
      @types.Exp::binop(
        @types.BinOp::bit_or(),
        @types.Exp::binop(@types.BinOp::lt(), orig_dst_exp, borrowed),
        @types.Exp::binop(@types.BinOp::lt(), borrowed, orig_src_exp),
      ),
    ),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
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
fn project_basic_bil_shiftd_count(
  raw_count : @types.Exp,
  count_width : Int,
  width : Int,
) -> Result[(@types.Exp, @types.Exp), String] {
  let size = match project_basic_bil_int(width.to_int64(), count_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let count_mask = match
    project_basic_bil_int((width - 1).to_int64(), count_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let count = @types.Exp::binop(@types.BinOp::bit_and(), raw_count, count_mask)
  let remaining = @types.Exp::binop(@types.BinOp::minus(), size, count)
  Ok((count, remaining))
}

///|
fn project_basic_bil_shiftd_result(
  old_dst : @types.Exp,
  fill : @types.Exp,
  count : @types.Exp,
  remaining : @types.Exp,
  left : Bool,
) -> @types.Exp {
  let ret1 = if left {
    @types.Exp::binop(@types.BinOp::rshift(), fill, remaining)
  } else {
    @types.Exp::binop(@types.BinOp::lshift(), fill, remaining)
  }
  let ret2 = if left {
    @types.Exp::binop(@types.BinOp::lshift(), old_dst, count)
  } else {
    @types.Exp::binop(@types.BinOp::rshift(), old_dst, count)
  }
  @types.Exp::binop(@types.BinOp::bit_or(), ret1, ret2)
}

///|
fn project_basic_bil_shiftd_flags(
  old_dst : @types.Exp,
  result : @types.Exp,
  count : @types.Exp,
  remaining : @types.Exp,
  count_width : Int,
  width : Int,
  left : Bool,
) -> Result[@types.Stmt, String] {
  let zero_count = match project_basic_bil_int(0L, count_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let one_count = match project_basic_bil_int(1L, count_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let zero_result = match project_basic_bil_int(0L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let cf = if left {
    @types.Exp::cast(
      @types.CastKind::low(),
      1,
      @types.Exp::binop(@types.BinOp::rshift(), old_dst, remaining),
    )
  } else {
    @types.Exp::cast(
      @types.CastKind::high(),
      1,
      @types.Exp::binop(@types.BinOp::lshift(), old_dst, remaining),
    )
  }
  let parity = match project_basic_bil_x86_parity(result, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let of_defined = @types.Exp::cast(
    @types.CastKind::high(),
    1,
    project_basic_bil_x86_xor(old_dst, result),
  )
  let of_undefined = @types.Exp::unknown(
    "OF undefined after shiftd of more then 1 bit",
    Imm(1),
  )
  Ok(
    @types.Stmt::if_(
      @types.Exp::binop(@types.BinOp::neq(), count, zero_count),
      [
        project_basic_bil_x86_flag_move("CF", cf),
        project_basic_bil_x86_flag_move(
          "SF",
          @types.Exp::cast(@types.CastKind::high(), 1, result),
        ),
        project_basic_bil_x86_flag_move(
          "ZF",
          @types.Exp::binop(@types.BinOp::eq(), zero_result, result),
        ),
        project_basic_bil_x86_flag_move("PF", parity),
        @types.Stmt::if_(
          @types.Exp::binop(@types.BinOp::eq(), count, one_count),
          [project_basic_bil_x86_flag_move("OF", of_defined)],
          [project_basic_bil_x86_flag_move("OF", of_undefined)],
        ),
      ],
      [],
    ),
  )
}

///|
fn project_basic_bil_shift_flags(
  old_dst : @types.Exp,
  result : @types.Exp,
  count : @types.Exp,
  remaining : @types.Exp,
  count_width : Int,
  width : Int,
  op : @types.BinOp,
) -> Result[@types.Stmt, String] {
  let zero_count = match project_basic_bil_int(0L, count_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let one_count = match project_basic_bil_int(1L, count_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let zero_result = match project_basic_bil_int(0L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let zero_flag = match project_basic_bil_int(0L, 1) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let cf = if op == @types.BinOp::lshift() {
    @types.Exp::cast(
      @types.CastKind::low(),
      1,
      @types.Exp::binop(@types.BinOp::rshift(), old_dst, remaining),
    )
  } else if op == @types.BinOp::rshift() || op == @types.BinOp::arshift() {
    @types.Exp::cast(
      @types.CastKind::low(),
      1,
      @types.Exp::binop(
        @types.BinOp::rshift(),
        old_dst,
        @types.Exp::binop(@types.BinOp::minus(), count, one_count),
      ),
    )
  } else {
    return Err("unsupported x86 shift operation")
  }
  let parity = match project_basic_bil_x86_parity(result, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let of_defined = if op == @types.BinOp::lshift() {
    @types.Exp::cast(
      @types.CastKind::high(),
      1,
      project_basic_bil_x86_xor(old_dst, result),
    )
  } else if op == @types.BinOp::rshift() {
    @types.Exp::cast(@types.CastKind::high(), 1, old_dst)
  } else if op == @types.BinOp::arshift() {
    zero_flag
  } else {
    return Err("unsupported x86 shift operation")
  }
  let of_undefined = @types.Exp::unknown(
    "OF undefined after shift of more then 1 bit",
    Imm(1),
  )
  Ok(
    @types.Stmt::if_(
      @types.Exp::binop(@types.BinOp::neq(), count, zero_count),
      [
        project_basic_bil_x86_flag_move("CF", cf),
        project_basic_bil_x86_flag_move(
          "SF",
          @types.Exp::cast(@types.CastKind::high(), 1, result),
        ),
        project_basic_bil_x86_flag_move(
          "ZF",
          @types.Exp::binop(@types.BinOp::eq(), zero_result, result),
        ),
        project_basic_bil_x86_flag_move(
          "AF",
          @types.Exp::unknown("AF undefined after shift", Imm(1)),
        ),
        project_basic_bil_x86_flag_move("PF", parity),
        @types.Stmt::if_(
          @types.Exp::binop(@types.BinOp::eq(), count, one_count),
          [project_basic_bil_x86_flag_move("OF", of_defined)],
          [project_basic_bil_x86_flag_move("OF", of_undefined)],
        ),
      ],
      [],
    ),
  )
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_shiftd_rr(
  self : ProjectDisassemblyInstruction,
  width : Int,
  left : Bool,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let old_src = match self.project_basic_bil_register(1, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let fill = match self.project_basic_bil_register(2, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (raw_count, count_width) = match
    self.project_basic_bil_shift_count_with_width(3, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (count, remaining) = match
    project_basic_bil_shiftd_count(raw_count, count_width, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let was = project_basic_bil_virtual("shiftd_was", width)
  let old_dst = @types.Exp::var_exp(was)
  let result = project_basic_bil_shiftd_result(
    old_dst,
    @types.Exp::var_exp(fill),
    count,
    remaining,
    left,
  )
  let flags = match
    project_basic_bil_shiftd_flags(
      old_dst, result, count, remaining, count_width, width, left,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok([
    @types.Stmt::move_stmt(was, @types.Exp::var_exp(old_src)),
    @types.Stmt::move_stmt(dst, result),
    flags,
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_shiftd_mr(
  self : ProjectDisassemblyInstruction,
  width : Int,
  left : Bool,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let fill = match self.project_basic_bil_register(5, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (raw_count, count_width) = match
    self.project_basic_bil_shift_count_with_width(6, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (count, remaining) = match
    project_basic_bil_shiftd_count(raw_count, count_width, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("shiftd_a", address_width)
  let was = project_basic_bil_virtual("shiftd_was", width)
  let old_dst = @types.Exp::var_exp(was)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let result = project_basic_bil_shiftd_result(
    old_dst,
    @types.Exp::var_exp(fill),
    count,
    remaining,
    left,
  )
  let flags = match
    project_basic_bil_shiftd_flags(
      old_dst, result, count, remaining, count_width, width, left,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok([
    @types.Stmt::move_stmt(addr_tmp, addr),
    @types.Stmt::move_stmt(
      was,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(
      mem,
      @types.Exp::store(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        result,
        LittleEndian,
        size,
      ),
    ),
    flags,
  ])
}

///|
fn project_basic_bil_rotate_exp(
  src_exp : @types.Exp,
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
fn project_basic_bil_rotate_expr(
  src : @types.Var,
  count : @types.Exp,
  count_width : Int,
  width : Int,
  left : Bool,
) -> Result[@types.Exp, String] {
  project_basic_bil_rotate_exp(
    @types.Exp::var_exp(src),
    count,
    count_width,
    width,
    left,
  )
}

///|
fn project_basic_bil_rotate_flags(
  result : @types.Exp,
  count : @types.Exp,
  count_width : Int,
  width : Int,
  left : Bool,
) -> Result[@types.Stmt, String] {
  let zero_count = match project_basic_bil_int(0L, count_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let one_count = match project_basic_bil_int(1L, count_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let one = match project_basic_bil_int(1L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let cf = if left {
    @types.Exp::cast(@types.CastKind::low(), 1, result)
  } else {
    @types.Exp::cast(@types.CastKind::high(), 1, result)
  }
  let of_defined = if left {
    project_basic_bil_x86_xor(
      @types.Exp::cast(@types.CastKind::high(), 1, result),
      @types.Exp::cast(@types.CastKind::low(), 1, result),
    )
  } else {
    project_basic_bil_x86_xor(
      @types.Exp::cast(@types.CastKind::high(), 1, result),
      @types.Exp::cast(
        @types.CastKind::high(),
        1,
        @types.Exp::binop(@types.BinOp::lshift(), result, one),
      ),
    )
  }
  let of_undefined = @types.Exp::unknown(
    "OF undefined after rotate of more then 1 bit",
    Imm(1),
  )
  Ok(
    @types.Stmt::if_(
      @types.Exp::binop(@types.BinOp::neq(), count, zero_count),
      [
        project_basic_bil_x86_flag_move("CF", cf),
        @types.Stmt::if_(
          @types.Exp::binop(@types.BinOp::eq(), count, one_count),
          [project_basic_bil_x86_flag_move("OF", of_defined)],
          [project_basic_bil_x86_flag_move("OF", of_undefined)],
        ),
      ],
      [],
    ),
  )
}

///|
fn project_basic_bil_rotate_carry_count(
  raw_count : @types.Exp,
  count_width : Int,
  width : Int,
) -> Result[@types.Exp, String] {
  let mask_value = if width == 64 { 0x3FL } else { 0x1FL }
  let count_mask = match project_basic_bil_int(mask_value, count_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let masked = @types.Exp::binop(@types.BinOp::bit_and(), raw_count, count_mask)
  if width == 8 || width == 16 {
    let rotate_width = match
      project_basic_bil_int((width + 1).to_int64(), count_width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    Ok(@types.Exp::binop(@types.BinOp::modulo(), masked, rotate_width))
  } else {
    Ok(masked)
  }
}

///|
fn project_basic_bil_rotate_carry_flags(
  rotated : @types.Exp,
  result : @types.Exp,
  count : @types.Exp,
  count_width : Int,
  width : Int,
  left : Bool,
) -> Result[@types.Stmt, String] {
  let zero_count = match project_basic_bil_int(0L, count_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let one_count = match project_basic_bil_int(1L, count_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let cf = if left {
    @types.Exp::cast(@types.CastKind::low(), 1, rotated)
  } else {
    @types.Exp::cast(@types.CastKind::high(), 1, rotated)
  }
  let of_defined = if left {
    project_basic_bil_x86_xor(
      @types.Exp::cast(@types.CastKind::high(), 1, result),
      cf,
    )
  } else {
    project_basic_bil_x86_xor(
      @types.Exp::cast(@types.CastKind::high(), 1, result),
      @types.Exp::extract(result, hi=width - 2, lo=width - 2),
    )
  }
  let of_undefined = @types.Exp::unknown(
    "OF undefined after rotate of more then 1 bit",
    Imm(1),
  )
  Ok(
    @types.Stmt::if_(
      @types.Exp::binop(@types.BinOp::neq(), count, zero_count),
      [
        project_basic_bil_x86_flag_move("CF", cf),
        @types.Stmt::if_(
          @types.Exp::binop(@types.BinOp::eq(), count, one_count),
          [project_basic_bil_x86_flag_move("OF", of_defined)],
          [project_basic_bil_x86_flag_move("OF", of_undefined)],
        ),
      ],
      [],
    ),
  )
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
  let (raw_count, count_width) = match
    self.project_basic_bil_shift_count_with_width(2, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (count, _) = match
    project_basic_bil_shiftd_count(raw_count, count_width, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs = match
    project_basic_bil_rotate_expr(src, count, count_width, width, left) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let flags = match
    project_basic_bil_rotate_flags(
      @types.Exp::var_exp(dst),
      count,
      count_width,
      width,
      left,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok([@types.Stmt::move_stmt(dst, rhs), flags])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_rotate_carry_r(
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
  let (raw_count, count_width) = match
    self.project_basic_bil_shift_count_with_width(2, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let count = match
    project_basic_bil_rotate_carry_count(raw_count, count_width, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src_exp = @types.Exp::var_exp(src)
  let carry = project_basic_bil_x86_flag("CF")
  let combined = if left {
    @types.Exp::concat(src_exp, carry)
  } else {
    @types.Exp::concat(carry, src_exp)
  }
  let rotated_exp = match
    project_basic_bil_rotate_exp(combined, count, count_width, width + 1, left) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rotated = project_basic_bil_virtual("rotate_carry_res", width + 1)
  let rotated_var = @types.Exp::var_exp(rotated)
  let result = if left {
    @types.Exp::extract(rotated_var, hi=width, lo=1)
  } else {
    @types.Exp::extract(rotated_var, hi=width - 1, lo=0)
  }
  let flags = match
    project_basic_bil_rotate_carry_flags(
      rotated_var,
      @types.Exp::var_exp(dst),
      count,
      count_width,
      width,
      left,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok([
    @types.Stmt::move_stmt(rotated, rotated_exp),
    @types.Stmt::move_stmt(dst, result),
    flags,
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_rotate_carry_m(
  self : ProjectDisassemblyInstruction,
  width : Int,
  left : Bool,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (raw_count, count_width) = match
    self.project_basic_bil_shift_count_with_width(5, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let count = match
    project_basic_bil_rotate_carry_count(raw_count, count_width, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("rotate_carry_a", address_width)
  let data_tmp = project_basic_bil_virtual("rotate_carry_d", width)
  let rotated_tmp = project_basic_bil_virtual("rotate_carry_res", width + 1)
  let result_tmp = project_basic_bil_virtual("rotate_carry_dst", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let data_exp = @types.Exp::var_exp(data_tmp)
  let rotated_exp = @types.Exp::var_exp(rotated_tmp)
  let result_exp = @types.Exp::var_exp(result_tmp)
  let carry = project_basic_bil_x86_flag("CF")
  let combined = if left {
    @types.Exp::concat(data_exp, carry)
  } else {
    @types.Exp::concat(carry, data_exp)
  }
  let rotated = match
    project_basic_bil_rotate_exp(combined, count, count_width, width + 1, left) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let result = if left {
    @types.Exp::extract(rotated_exp, hi=width, lo=1)
  } else {
    @types.Exp::extract(rotated_exp, hi=width - 1, lo=0)
  }
  let flags = match
    project_basic_bil_rotate_carry_flags(
      rotated_exp, result_exp, count, count_width, width, left,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok([
    @types.Stmt::move_stmt(addr_tmp, addr),
    @types.Stmt::move_stmt(
      data_tmp,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(rotated_tmp, rotated),
    @types.Stmt::move_stmt(result_tmp, result),
    @types.Stmt::move_stmt(
      mem,
      @types.Exp::store(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        result_exp,
        LittleEndian,
        size,
      ),
    ),
    flags,
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_rotate_m(
  self : ProjectDisassemblyInstruction,
  width : Int,
  left : Bool,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (raw_count, count_width) = match
    self.project_basic_bil_shift_count_with_width(5, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (count, _) = match
    project_basic_bil_shiftd_count(raw_count, count_width, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("rotate_a", address_width)
  let data_tmp = project_basic_bil_virtual("rotate_d", width)
  let result_tmp = project_basic_bil_virtual("rotate_res", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let data_exp = @types.Exp::var_exp(data_tmp)
  let result_exp = @types.Exp::var_exp(result_tmp)
  let rotated = match
    project_basic_bil_rotate_exp(data_exp, count, count_width, width, left) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let flags = match
    project_basic_bil_rotate_flags(result_exp, count, count_width, width, left) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok([
    @types.Stmt::move_stmt(addr_tmp, addr),
    @types.Stmt::move_stmt(
      data_tmp,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(result_tmp, rotated),
    @types.Stmt::move_stmt(
      mem,
      @types.Exp::store(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        result_exp,
        LittleEndian,
        size,
      ),
    ),
    flags,
  ])
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
  let (raw_count, count_width) = match
    self.project_basic_bil_shift_count_with_width(2, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (count, remaining) = match
    project_basic_bil_shiftd_count(raw_count, count_width, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let old_dst = project_basic_bil_virtual("shift_was", width)
  let old_dst_exp = @types.Exp::var_exp(old_dst)
  let result_exp = @types.Exp::var_exp(dst)
  let flag_stmt = match
    project_basic_bil_shift_flags(
      old_dst_exp, result_exp, count, remaining, count_width, width, op,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok([
    @types.Stmt::move_stmt(old_dst, @types.Exp::var_exp(src)),
    @types.Stmt::move_stmt(dst, @types.Exp::binop(op, old_dst_exp, count)),
    flag_stmt,
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_shift_m(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (raw_count, count_width) = match
    self.project_basic_bil_shift_count_with_width(5, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (count, remaining) = match
    project_basic_bil_shiftd_count(raw_count, count_width, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("shift_a", address_width)
  let data_tmp = project_basic_bil_virtual("shift_d", width)
  let result_tmp = project_basic_bil_virtual("shift_res", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let data_exp = @types.Exp::var_exp(data_tmp)
  let result_exp = @types.Exp::var_exp(result_tmp)
  let flag_stmt = match
    project_basic_bil_shift_flags(
      data_exp, result_exp, count, remaining, count_width, width, op,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok([
    @types.Stmt::move_stmt(addr_tmp, addr),
    @types.Stmt::move_stmt(
      data_tmp,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(result_tmp, @types.Exp::binop(op, data_exp, count)),
    @types.Stmt::move_stmt(
      mem,
      @types.Exp::store(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        result_exp,
        LittleEndian,
        size,
      ),
    ),
    flag_stmt,
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
fn ProjectDisassemblyInstruction::project_basic_bil_cmp_mi(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let imm = match self.project_basic_bil_immediate(5) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs_exp = match project_basic_bil_int(imm, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("cmp_a", address_width)
  let data_tmp = project_basic_bil_virtual("cmp_d", width)
  let result_tmp = project_basic_bil_virtual("cmp_tmp", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let data_exp = @types.Exp::var_exp(data_tmp)
  let result_exp = @types.Exp::var_exp(result_tmp)
  let flags = match
    project_basic_bil_x86_sub_flag_moves(data_exp, rhs_exp, result_exp, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(addr_tmp, addr),
    @types.Stmt::move_stmt(
      data_tmp,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(
      result_tmp,
      @types.Exp::binop(@types.BinOp::minus(), data_exp, rhs_exp),
    ),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_cmp_rm(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let lhs = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
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
  let rhs_tmp = project_basic_bil_virtual("cmp_src", width)
  let result_tmp = project_basic_bil_virtual("cmp_tmp", width)
  let lhs_exp = @types.Exp::var_exp(lhs)
  let rhs_exp = @types.Exp::var_exp(rhs_tmp)
  let result_exp = @types.Exp::var_exp(result_tmp)
  let flags = match
    project_basic_bil_x86_sub_flag_moves(lhs_exp, rhs_exp, result_exp, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(
      rhs_tmp,
      @types.Exp::load(mem=@types.Exp::var_exp(mem), addr~, LittleEndian, size),
    ),
    @types.Stmt::move_stmt(
      result_tmp,
      @types.Exp::binop(@types.BinOp::minus(), lhs_exp, rhs_exp),
    ),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_cmp_mr(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs = match self.project_basic_bil_register(5, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("cmp_a", address_width)
  let lhs_tmp = project_basic_bil_virtual("cmp_d", width)
  let result_tmp = project_basic_bil_virtual("cmp_tmp", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let lhs_exp = @types.Exp::var_exp(lhs_tmp)
  let rhs_exp = @types.Exp::var_exp(rhs)
  let result_exp = @types.Exp::var_exp(result_tmp)
  let flags = match
    project_basic_bil_x86_sub_flag_moves(lhs_exp, rhs_exp, result_exp, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(addr_tmp, addr),
    @types.Stmt::move_stmt(
      lhs_tmp,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(
      result_tmp,
      @types.Exp::binop(@types.BinOp::minus(), lhs_exp, rhs_exp),
    ),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_cmpxchg_rr(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let old_dst = match self.project_basic_bil_register(1, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = match self.project_basic_bil_register(2, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let acc = match project_basic_bil_x86_accumulator(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let tmp = project_basic_bil_virtual("cmpxchg_tmp", width)
  let acc_exp = @types.Exp::var_exp(acc)
  let old_dst_exp = @types.Exp::var_exp(old_dst)
  let src_exp = @types.Exp::var_exp(src)
  let result_exp = @types.Exp::var_exp(tmp)
  let flags = match
    project_basic_bil_x86_sub_flag_moves(
      acc_exp, old_dst_exp, result_exp, width,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(
      tmp,
      @types.Exp::binop(@types.BinOp::minus(), acc_exp, old_dst_exp),
    ),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  stmts.push(
    @types.Stmt::move_stmt(
      dst,
      @types.Exp::ite(
        if_=project_basic_bil_x86_flag("ZF"),
        then_=src_exp,
        else_=old_dst_exp,
      ),
    ),
  )
  stmts.push(
    @types.Stmt::move_stmt(
      acc,
      @types.Exp::ite(
        if_=project_basic_bil_x86_flag("ZF"),
        then_=acc_exp,
        else_=old_dst_exp,
      ),
    ),
  )
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_cmpxchg_mr(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = match self.project_basic_bil_register(5, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let acc = match project_basic_bil_x86_accumulator(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("cmpxchg_a", address_width)
  let old_dst = project_basic_bil_virtual("cmpxchg_d", width)
  let tmp = project_basic_bil_virtual("cmpxchg_tmp", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let old_dst_exp = @types.Exp::var_exp(old_dst)
  let acc_exp = @types.Exp::var_exp(acc)
  let src_exp = @types.Exp::var_exp(src)
  let result_exp = @types.Exp::var_exp(tmp)
  let flags = match
    project_basic_bil_x86_sub_flag_moves(
      acc_exp, old_dst_exp, result_exp, width,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(addr_tmp, addr),
    @types.Stmt::move_stmt(
      old_dst,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(
      tmp,
      @types.Exp::binop(@types.BinOp::minus(), acc_exp, old_dst_exp),
    ),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  stmts.push(
    @types.Stmt::move_stmt(
      mem,
      @types.Exp::store(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        @types.Exp::ite(
          if_=project_basic_bil_x86_flag("ZF"),
          then_=src_exp,
          else_=old_dst_exp,
        ),
        LittleEndian,
        size,
      ),
    ),
  )
  stmts.push(
    @types.Stmt::move_stmt(
      acc,
      @types.Exp::ite(
        if_=project_basic_bil_x86_flag("ZF"),
        then_=acc_exp,
        else_=old_dst_exp,
      ),
    ),
  )
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_xadd_rr(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let old_dst = match self.project_basic_bil_register(1, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = match self.project_basic_bil_register(2, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let tmp_src = project_basic_bil_virtual("xadd_src", width)
  let tmp_dst = project_basic_bil_virtual("xadd_dst", width)
  let tmp_result = project_basic_bil_virtual("xadd_tmp", width)
  let tmp_src_exp = @types.Exp::var_exp(tmp_src)
  let tmp_dst_exp = @types.Exp::var_exp(tmp_dst)
  let tmp_result_exp = @types.Exp::var_exp(tmp_result)
  let flags = match
    project_basic_bil_x86_add_flag_moves(
      tmp_dst_exp, tmp_src_exp, tmp_result_exp, width,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(tmp_src, @types.Exp::var_exp(src)),
    @types.Stmt::move_stmt(tmp_dst, @types.Exp::var_exp(old_dst)),
    @types.Stmt::move_stmt(
      tmp_result,
      @types.Exp::binop(@types.BinOp::plus(), tmp_dst_exp, tmp_src_exp),
    ),
    @types.Stmt::move_stmt(src, tmp_dst_exp),
    @types.Stmt::move_stmt(dst, tmp_result_exp),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_xadd_mr(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let src = match self.project_basic_bil_register(5, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("xadd_a", address_width)
  let tmp_src = project_basic_bil_virtual("xadd_src", width)
  let tmp_dst = project_basic_bil_virtual("xadd_dst", width)
  let tmp_result = project_basic_bil_virtual("xadd_tmp", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let tmp_src_exp = @types.Exp::var_exp(tmp_src)
  let tmp_dst_exp = @types.Exp::var_exp(tmp_dst)
  let tmp_result_exp = @types.Exp::var_exp(tmp_result)
  let flags = match
    project_basic_bil_x86_add_flag_moves(
      tmp_dst_exp, tmp_src_exp, tmp_result_exp, width,
    ) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(addr_tmp, addr),
    @types.Stmt::move_stmt(
      tmp_dst,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(tmp_src, @types.Exp::var_exp(src)),
    @types.Stmt::move_stmt(
      tmp_result,
      @types.Exp::binop(@types.BinOp::plus(), tmp_dst_exp, tmp_src_exp),
    ),
    @types.Stmt::move_stmt(src, tmp_dst_exp),
    @types.Stmt::move_stmt(
      mem,
      @types.Exp::store(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        tmp_result_exp,
        LittleEndian,
        size,
      ),
    ),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_cmpxchg8b(
  self : ProjectDisassemblyInstruction,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(64) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("cmpxchg8b_a", address_width)
  let dst_tmp = project_basic_bil_virtual("cmpxchg8b_d", 64)
  let equal = project_basic_bil_virtual("cmpxchg8b_eq", 1)
  let eax = project_basic_bil_reg("EAX", 32)
  let ebx = project_basic_bil_reg("EBX", 32)
  let ecx = project_basic_bil_reg("ECX", 32)
  let edx = project_basic_bil_reg("EDX", 32)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let dst_exp = @types.Exp::var_exp(dst_tmp)
  let equal_exp = @types.Exp::var_exp(equal)
  let accumulator = @types.Exp::concat(
    @types.Exp::var_exp(edx),
    @types.Exp::var_exp(eax),
  )
  let source = @types.Exp::concat(
    @types.Exp::var_exp(ecx),
    @types.Exp::var_exp(ebx),
  )
  Ok([
    @types.Stmt::move_stmt(addr_tmp, addr),
    @types.Stmt::move_stmt(
      dst_tmp,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(
      equal,
      @types.Exp::binop(@types.BinOp::eq(), accumulator, dst_exp),
    ),
    project_basic_bil_x86_flag_move("ZF", equal_exp),
    @types.Stmt::move_stmt(
      mem,
      @types.Exp::store(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        @types.Exp::ite(if_=equal_exp, then_=source, else_=dst_exp),
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(
      eax,
      @types.Exp::ite(
        if_=equal_exp,
        then_=@types.Exp::var_exp(eax),
        else_=@types.Exp::extract(dst_exp, hi=31, lo=0),
      ),
    ),
    @types.Stmt::move_stmt(
      edx,
      @types.Exp::ite(
        if_=equal_exp,
        then_=@types.Exp::var_exp(edx),
        else_=@types.Exp::extract(dst_exp, hi=63, lo=32),
      ),
    ),
  ])
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
fn ProjectDisassemblyInstruction::project_basic_bil_test_mr(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let rhs = match self.project_basic_bil_register(5, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("test_a", address_width)
  let lhs_tmp = project_basic_bil_virtual("test_d", width)
  let result_tmp = project_basic_bil_virtual("test_tmp", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let lhs_exp = @types.Exp::var_exp(lhs_tmp)
  let rhs_exp = @types.Exp::var_exp(rhs)
  let result_exp = @types.Exp::var_exp(result_tmp)
  let flags = match project_basic_bil_x86_test_flag_moves(result_exp, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stmts = [
    @types.Stmt::move_stmt(addr_tmp, addr),
    @types.Stmt::move_stmt(
      lhs_tmp,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(
      result_tmp,
      @types.Exp::binop(@types.BinOp::bit_and(), lhs_exp, rhs_exp),
    ),
  ]
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn project_basic_bil_x86_incdec_prefix(
  op : @types.BinOp,
) -> Result[String, String] {
  if op == @types.BinOp::plus() {
    Ok("inc")
  } else if op == @types.BinOp::minus() {
    Ok("dec")
  } else {
    Err("unsupported x86 INC/DEC operation")
  }
}

///|
fn project_basic_bil_x86_incdec_flag_moves(
  lhs : @types.Exp,
  rhs : @types.Exp,
  result : @types.Exp,
  width : Int,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  if op == @types.BinOp::plus() {
    project_basic_bil_x86_add_carryless_flag_moves(lhs, rhs, result, width)
  } else if op == @types.BinOp::minus() {
    let flags = match
      project_basic_bil_x86_sub_flag_moves(lhs, rhs, result, width) {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    let stmts : Array[@types.Stmt] = []
    for index in 1..<flags.length() {
      stmts.push(flags[index])
    }
    Ok(stmts)
  } else {
    Err("unsupported x86 INC/DEC flag operation")
  }
}

///|
fn project_basic_bil_x86_append_incdec_flags(
  stmts : Array[@types.Stmt],
  lhs : @types.Exp,
  rhs : @types.Exp,
  result : @types.Exp,
  width : Int,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  let flags = match
    project_basic_bil_x86_incdec_flag_moves(lhs, rhs, result, width, op) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
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
  let prefix = match project_basic_bil_x86_incdec_prefix(op) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let one = match project_basic_bil_int(1L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let orig_dst = project_basic_bil_virtual("\{prefix}_dst", width)
  let orig_src = project_basic_bil_virtual("\{prefix}_src", width)
  let orig_dst_exp = @types.Exp::var_exp(orig_dst)
  let orig_src_exp = @types.Exp::var_exp(orig_src)
  let result_exp = @types.Exp::var_exp(dst)
  project_basic_bil_x86_append_incdec_flags(
    [
      @types.Stmt::move_stmt(orig_dst, result_exp),
      @types.Stmt::move_stmt(orig_src, one),
      @types.Stmt::move_stmt(
        dst,
        @types.Exp::binop(op, orig_dst_exp, orig_src_exp),
      ),
    ],
    orig_dst_exp,
    orig_src_exp,
    result_exp,
    width,
    op,
  )
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_incdec_m(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : @types.BinOp,
) -> Result[Array[@types.Stmt], String] {
  let prefix = match project_basic_bil_x86_incdec_prefix(op) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let one = match project_basic_bil_int(1L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("\{prefix}_a", address_width)
  let orig_dst = project_basic_bil_virtual("\{prefix}_dst", width)
  let orig_src = project_basic_bil_virtual("\{prefix}_src", width)
  let result = project_basic_bil_virtual("\{prefix}_res", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let orig_dst_exp = @types.Exp::var_exp(orig_dst)
  let orig_src_exp = @types.Exp::var_exp(orig_src)
  let result_exp = @types.Exp::var_exp(result)
  project_basic_bil_x86_append_incdec_flags(
    [
      @types.Stmt::move_stmt(addr_tmp, addr),
      @types.Stmt::move_stmt(
        orig_dst,
        @types.Exp::load(
          mem=@types.Exp::var_exp(mem),
          addr=addr_exp,
          LittleEndian,
          size,
        ),
      ),
      @types.Stmt::move_stmt(orig_src, one),
      @types.Stmt::move_stmt(
        result,
        @types.Exp::binop(op, orig_dst_exp, orig_src_exp),
      ),
      @types.Stmt::move_stmt(
        mem,
        @types.Exp::store(
          mem=@types.Exp::var_exp(mem),
          addr=addr_exp,
          result_exp,
          LittleEndian,
          size,
        ),
      ),
    ],
    orig_dst_exp,
    orig_src_exp,
    result_exp,
    width,
    op,
  )
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
fn ProjectDisassemblyInstruction::project_basic_bil_unop_m(
  self : ProjectDisassemblyInstruction,
  width : Int,
  op : @types.UnOp,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("unop_a", address_width)
  let data_tmp = project_basic_bil_virtual("unop_d", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let data_exp = @types.Exp::var_exp(data_tmp)
  Ok([
    @types.Stmt::move_stmt(addr_tmp, addr),
    @types.Stmt::move_stmt(
      data_tmp,
      @types.Exp::load(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        LittleEndian,
        size,
      ),
    ),
    @types.Stmt::move_stmt(
      mem,
      @types.Exp::store(
        mem=@types.Exp::var_exp(mem),
        addr=addr_exp,
        @types.Exp::unop(op, data_exp),
        LittleEndian,
        size,
      ),
    ),
  ])
}

///|
fn project_basic_bil_x86_append_neg_flags(
  stmts : Array[@types.Stmt],
  zero : @types.Exp,
  operand : @types.Exp,
  result : @types.Exp,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let flags = match
    project_basic_bil_x86_sub_flag_moves(zero, operand, result, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  for stmt in flags {
    stmts.push(stmt)
  }
  Ok(stmts)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_neg_r(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let zero = match project_basic_bil_int(0L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let orig_dst = project_basic_bil_virtual("neg_dst", width)
  let orig_dst_exp = @types.Exp::var_exp(orig_dst)
  let result_exp = @types.Exp::var_exp(dst)
  project_basic_bil_x86_append_neg_flags(
    [
      @types.Stmt::move_stmt(orig_dst, result_exp),
      @types.Stmt::move_stmt(
        dst,
        @types.Exp::binop(@types.BinOp::minus(), zero, orig_dst_exp),
      ),
    ],
    zero,
    orig_dst_exp,
    result_exp,
    width,
  )
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_neg_m(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, address_width) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let zero = match project_basic_bil_int(0L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr_tmp = project_basic_bil_virtual("neg_a", address_width)
  let orig_dst = project_basic_bil_virtual("neg_dst", width)
  let result = project_basic_bil_virtual("neg_res", width)
  let addr_exp = @types.Exp::var_exp(addr_tmp)
  let orig_dst_exp = @types.Exp::var_exp(orig_dst)
  let result_exp = @types.Exp::var_exp(result)
  project_basic_bil_x86_append_neg_flags(
    [
      @types.Stmt::move_stmt(addr_tmp, addr),
      @types.Stmt::move_stmt(
        orig_dst,
        @types.Exp::load(
          mem=@types.Exp::var_exp(mem),
          addr=addr_exp,
          LittleEndian,
          size,
        ),
      ),
      @types.Stmt::move_stmt(
        result,
        @types.Exp::binop(@types.BinOp::minus(), zero, orig_dst_exp),
      ),
      @types.Stmt::move_stmt(
        mem,
        @types.Exp::store(
          mem=@types.Exp::var_exp(mem),
          addr=addr_exp,
          result_exp,
          LittleEndian,
          size,
        ),
      ),
    ],
    zero,
    orig_dst_exp,
    result_exp,
    width,
  )
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
fn ProjectDisassemblyInstruction::project_basic_bil_mov_rm_endian(
  self : ProjectDisassemblyInstruction,
  data_width : Int,
  endian : @bitvec.Endian,
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
      @types.Exp::load(mem=@types.Exp::var_exp(mem), addr~, endian, size),
    ),
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_mov_rm(
  self : ProjectDisassemblyInstruction,
  data_width : Int,
) -> Result[Array[@types.Stmt], String] {
  self.project_basic_bil_mov_rm_endian(data_width, LittleEndian)
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_mov_mr_endian(
  self : ProjectDisassemblyInstruction,
  data_width : Int,
  endian : @bitvec.Endian,
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
        endian,
        size,
      ),
    ),
  ])
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_mov_mr(
  self : ProjectDisassemblyInstruction,
  data_width : Int,
) -> Result[Array[@types.Stmt], String] {
  self.project_basic_bil_mov_mr_endian(data_width, LittleEndian)
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
fn project_basic_bil_push_exp(
  src : @types.Exp,
  value_width : Int,
  address_width : Int,
) -> Result[Array[@types.Stmt], String] {
  let sp = match project_basic_bil_stack_pointer(address_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let addr = match
    project_basic_bil_stack_decrement(sp, value_width, address_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let updated_sp = match
    project_basic_bil_stack_decrement(sp, value_width, address_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(value_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let mem = project_basic_bil_stack_mem(address_width)
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
  value_width : Int,
  address_width : Int,
) -> Result[Array[@types.Stmt], String] {
  match self.project_basic_bil_value(0, value_width) {
    Ok(src) => project_basic_bil_push_exp(src, value_width, address_width)
    Err(reason) => Err(reason)
  }
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_push_mem(
  self : ProjectDisassemblyInstruction,
  value_width : Int,
  address_width : Int,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, _) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(value_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  project_basic_bil_push_exp(
    @types.Exp::load(mem=@types.Exp::var_exp(mem), addr~, LittleEndian, size),
    value_width,
    address_width,
  )
}

///|
fn ProjectDisassemblyInstruction::project_basic_bil_pop(
  self : ProjectDisassemblyInstruction,
  value_width : Int,
  address_width : Int,
) -> Result[Array[@types.Stmt], String] {
  let dst = match self.project_basic_bil_register(0, value_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let sp = match project_basic_bil_stack_pointer(address_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(value_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let mem = project_basic_bil_stack_mem(address_width)
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
    let updated_sp = match
      project_basic_bil_stack_increment(sp, value_width, address_width) {
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
  value_width : Int,
  address_width : Int,
) -> Result[Array[@types.Stmt], String] {
  let sp = match project_basic_bil_stack_pointer(address_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let stack_fp = project_basic_bil_reg(
    if address_width == 64 {
      "RBP"
    } else {
      "EBP"
    },
    address_width,
  )
  let popped_fp = project_basic_bil_reg(
    if value_width == 16 {
      "BP"
    } else if value_width == 64 {
      "RBP"
    } else {
      "EBP"
    },
    value_width,
  )
  let size = match @types.Size::of_int(value_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let updated_sp = match
    project_basic_bil_stack_increment(sp, value_width, address_width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let mem = project_basic_bil_stack_mem(address_width)
  Ok([
    @types.Stmt::move_stmt(sp, @types.Exp::var_exp(stack_fp)),
    @types.Stmt::move_stmt(
      popped_fp,
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
fn ProjectDisassemblyInstruction::project_basic_bil_jcxz(
  self : ProjectDisassemblyInstruction,
  width : Int,
) -> Result[Array[@types.Stmt], String] {
  let target = match self.project_basic_bil_immediate(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let zero = match project_basic_bil_int(0L, width) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let register = project_basic_bil_reg(
    if width == 64 {
      "RCX"
    } else {
      "ECX"
    },
    width,
  )
  match
    project_basic_bil_control(
      @types.Stmt::goto(),
      target.reinterpret_as_uint64(),
    ) {
    Ok(branch) =>
      Ok([
        @types.Stmt::if_(
          @types.Exp::binop(
            @types.BinOp::eq(),
            @types.Exp::var_exp(register),
            zero,
          ),
          branch,
          [],
        ),
      ])
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
fn ProjectDisassemblyInstruction::project_basic_bil_mxcsr_mem(
  self : ProjectDisassemblyInstruction,
  load_mxcsr : Bool,
) -> Result[Array[@types.Stmt], String] {
  let (addr, mem, _) = match self.project_basic_bil_memory_addr(0) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let size = match @types.Size::of_int(32) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let mxcsr = project_basic_bil_reg("MXCSR", 32)
  if load_mxcsr {
    Ok([
      @types.Stmt::move_stmt(
        mxcsr,
        @types.Exp::load(
          mem=@types.Exp::var_exp(mem),
          addr~,
          LittleEndian,
          size,
        ),
      ),
    ])
  } else {
    Ok([
      @types.Stmt::move_stmt(
        mem,
        @types.Exp::store(
          mem=@types.Exp::var_exp(mem),
          addr~,
          @types.Exp::var_exp(mxcsr),
          LittleEndian,
          size,
        ),
      ),
    ])
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
  let name = self.name().to_upper()
  if name.has_prefix("CMOV") {
    let width = if name.contains("64") {
      64
    } else if name.contains("16") {
      16
    } else {
      32
    }
    return self.project_basic_bil_cmov(width)
  }
  match name {
    "SUB8RI8" => self.project_basic_bil_addsub_ri(8, @types.BinOp::minus())
    "SUB16RI8" | "SUB16RI16" =>
      self.project_basic_bil_addsub_ri(16, @types.BinOp::minus())
    "SUB32RI8" | "SUB32RI32" =>
      self.project_basic_bil_addsub_ri(32, @types.BinOp::minus())
    "SUB8MI8" => self.project_basic_bil_addsub_mi(8, @types.BinOp::minus())
    "SUB16MI8" | "SUB16MI16" =>
      self.project_basic_bil_addsub_mi(16, @types.BinOp::minus())
    "SUB32MI8" | "SUB32MI32" =>
      self.project_basic_bil_addsub_mi(32, @types.BinOp::minus())
    "SUB64MI8" | "SUB64MI32" =>
      self.project_basic_bil_addsub_mi(64, @types.BinOp::minus())
    "SUB8RM" => self.project_basic_bil_addsub_rm(8, @types.BinOp::minus())
    "SUB16RM" => self.project_basic_bil_addsub_rm(16, @types.BinOp::minus())
    "SUB32RM" => self.project_basic_bil_addsub_rm(32, @types.BinOp::minus())
    "SUB64RM" => self.project_basic_bil_addsub_rm(64, @types.BinOp::minus())
    "SUB8MR" => self.project_basic_bil_addsub_mr(8, @types.BinOp::minus())
    "SUB16MR" => self.project_basic_bil_addsub_mr(16, @types.BinOp::minus())
    "SUB32MR" => self.project_basic_bil_addsub_mr(32, @types.BinOp::minus())
    "SUB64MR" => self.project_basic_bil_addsub_mr(64, @types.BinOp::minus())
    "ADD8RI8" => self.project_basic_bil_addsub_ri(8, @types.BinOp::plus())
    "ADD16RI8" | "ADD16RI16" =>
      self.project_basic_bil_addsub_ri(16, @types.BinOp::plus())
    "ADD32RI8" | "ADD32RI32" =>
      self.project_basic_bil_addsub_ri(32, @types.BinOp::plus())
    "SUB64RI8" | "SUB64RI32" =>
      self.project_basic_bil_addsub_ri(64, @types.BinOp::minus())
    "ADD64RI8" | "ADD64RI32" =>
      self.project_basic_bil_addsub_ri(64, @types.BinOp::plus())
    "ADD8MI8" => self.project_basic_bil_addsub_mi(8, @types.BinOp::plus())
    "ADD16MI8" | "ADD16MI16" =>
      self.project_basic_bil_addsub_mi(16, @types.BinOp::plus())
    "ADD32MI8" | "ADD32MI32" =>
      self.project_basic_bil_addsub_mi(32, @types.BinOp::plus())
    "ADD64MI8" | "ADD64MI32" =>
      self.project_basic_bil_addsub_mi(64, @types.BinOp::plus())
    "ADD8RM" => self.project_basic_bil_addsub_rm(8, @types.BinOp::plus())
    "ADD16RM" => self.project_basic_bil_addsub_rm(16, @types.BinOp::plus())
    "ADD32RM" => self.project_basic_bil_addsub_rm(32, @types.BinOp::plus())
    "ADD64RM" => self.project_basic_bil_addsub_rm(64, @types.BinOp::plus())
    "ADD8MR" => self.project_basic_bil_addsub_mr(8, @types.BinOp::plus())
    "ADD16MR" => self.project_basic_bil_addsub_mr(16, @types.BinOp::plus())
    "ADD32MR" => self.project_basic_bil_addsub_mr(32, @types.BinOp::plus())
    "ADD64MR" => self.project_basic_bil_addsub_mr(64, @types.BinOp::plus())
    "ADC8RI8" => self.project_basic_bil_adc_ri(8)
    "ADC16RI8" | "ADC16RI16" => self.project_basic_bil_adc_ri(16)
    "ADC32RI8" | "ADC32RI32" => self.project_basic_bil_adc_ri(32)
    "ADC64RI8" | "ADC64RI32" => self.project_basic_bil_adc_ri(64)
    "ADC8MI8" => self.project_basic_bil_adc_mi(8)
    "ADC16MI8" | "ADC16MI16" => self.project_basic_bil_adc_mi(16)
    "ADC32MI8" | "ADC32MI32" => self.project_basic_bil_adc_mi(32)
    "ADC64MI8" | "ADC64MI32" => self.project_basic_bil_adc_mi(64)
    "SBB8RI8" => self.project_basic_bil_sbb_ri(8)
    "SBB16RI8" | "SBB16RI16" => self.project_basic_bil_sbb_ri(16)
    "SBB32RI8" | "SBB32RI32" => self.project_basic_bil_sbb_ri(32)
    "SBB64RI8" | "SBB64RI32" => self.project_basic_bil_sbb_ri(64)
    "SBB8MI8" => self.project_basic_bil_sbb_mi(8)
    "SBB16MI8" | "SBB16MI16" => self.project_basic_bil_sbb_mi(16)
    "SBB32MI8" | "SBB32MI32" => self.project_basic_bil_sbb_mi(32)
    "SBB64MI8" | "SBB64MI32" => self.project_basic_bil_sbb_mi(64)
    "OR8RI8" => self.project_basic_bil_logic_ri(8, @types.BinOp::bit_or())
    "OR16RI8" | "OR16RI16" =>
      self.project_basic_bil_logic_ri(16, @types.BinOp::bit_or())
    "OR32RI8" | "OR32RI32" =>
      self.project_basic_bil_logic_ri(32, @types.BinOp::bit_or())
    "OR64RI8" | "OR64RI32" =>
      self.project_basic_bil_logic_ri(64, @types.BinOp::bit_or())
    "OR8MI8" => self.project_basic_bil_logic_mi(8, @types.BinOp::bit_or())
    "OR16MI8" | "OR16MI16" =>
      self.project_basic_bil_logic_mi(16, @types.BinOp::bit_or())
    "OR32MI8" | "OR32MI32" =>
      self.project_basic_bil_logic_mi(32, @types.BinOp::bit_or())
    "OR64MI8" | "OR64MI32" =>
      self.project_basic_bil_logic_mi(64, @types.BinOp::bit_or())
    "AND8RI8" => self.project_basic_bil_logic_ri(8, @types.BinOp::bit_and())
    "AND16RI8" | "AND16RI16" =>
      self.project_basic_bil_logic_ri(16, @types.BinOp::bit_and())
    "AND32RI8" | "AND32RI32" =>
      self.project_basic_bil_logic_ri(32, @types.BinOp::bit_and())
    "AND64RI8" | "AND64RI32" =>
      self.project_basic_bil_logic_ri(64, @types.BinOp::bit_and())
    "AND8MI8" => self.project_basic_bil_logic_mi(8, @types.BinOp::bit_and())
    "AND16MI8" | "AND16MI16" =>
      self.project_basic_bil_logic_mi(16, @types.BinOp::bit_and())
    "AND32MI8" | "AND32MI32" =>
      self.project_basic_bil_logic_mi(32, @types.BinOp::bit_and())
    "AND64MI8" | "AND64MI32" =>
      self.project_basic_bil_logic_mi(64, @types.BinOp::bit_and())
    "XOR8RI8" => self.project_basic_bil_logic_ri(8, @types.BinOp::bit_xor())
    "XOR16RI8" | "XOR16RI16" =>
      self.project_basic_bil_logic_ri(16, @types.BinOp::bit_xor())
    "XOR32RI8" | "XOR32RI32" =>
      self.project_basic_bil_logic_ri(32, @types.BinOp::bit_xor())
    "XOR64RI8" | "XOR64RI32" =>
      self.project_basic_bil_logic_ri(64, @types.BinOp::bit_xor())
    "XOR8MI8" => self.project_basic_bil_logic_mi(8, @types.BinOp::bit_xor())
    "XOR16MI8" | "XOR16MI16" =>
      self.project_basic_bil_logic_mi(16, @types.BinOp::bit_xor())
    "XOR32MI8" | "XOR32MI32" =>
      self.project_basic_bil_logic_mi(32, @types.BinOp::bit_xor())
    "XOR64MI8" | "XOR64MI32" =>
      self.project_basic_bil_logic_mi(64, @types.BinOp::bit_xor())
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
    "BSF16RR" => self.project_basic_bil_bitscan_rr(16, true)
    "BSF32RR" => self.project_basic_bil_bitscan_rr(32, true)
    "BSF64RR" => self.project_basic_bil_bitscan_rr(64, true)
    "BSF16RM" => self.project_basic_bil_bitscan_rm(16, true)
    "BSF32RM" => self.project_basic_bil_bitscan_rm(32, true)
    "BSF64RM" => self.project_basic_bil_bitscan_rm(64, true)
    "BSR16RR" => self.project_basic_bil_bitscan_rr(16, false)
    "BSR32RR" => self.project_basic_bil_bitscan_rr(32, false)
    "BSR64RR" => self.project_basic_bil_bitscan_rr(64, false)
    "BSR16RM" => self.project_basic_bil_bitscan_rm(16, false)
    "BSR32RM" => self.project_basic_bil_bitscan_rm(32, false)
    "BSR64RM" => self.project_basic_bil_bitscan_rm(64, false)
    "POPCNT16RR" => self.project_basic_bil_popcnt_rr(16)
    "POPCNT32RR" => self.project_basic_bil_popcnt_rr(32)
    "POPCNT64RR" => self.project_basic_bil_popcnt_rr(64)
    "POPCNT16RM" => self.project_basic_bil_popcnt_rm(16)
    "POPCNT32RM" => self.project_basic_bil_popcnt_rm(32)
    "POPCNT64RM" => self.project_basic_bil_popcnt_rm(64)
    "TZCNT16RR" => self.project_basic_bil_count_zero_rr(16, true)
    "TZCNT32RR" => self.project_basic_bil_count_zero_rr(32, true)
    "TZCNT64RR" => self.project_basic_bil_count_zero_rr(64, true)
    "TZCNT16RM" => self.project_basic_bil_count_zero_rm(16, true)
    "TZCNT32RM" => self.project_basic_bil_count_zero_rm(32, true)
    "TZCNT64RM" => self.project_basic_bil_count_zero_rm(64, true)
    "LZCNT16RR" => self.project_basic_bil_count_zero_rr(16, false)
    "LZCNT32RR" => self.project_basic_bil_count_zero_rr(32, false)
    "LZCNT64RR" => self.project_basic_bil_count_zero_rr(64, false)
    "LZCNT16RM" => self.project_basic_bil_count_zero_rm(16, false)
    "LZCNT32RM" => self.project_basic_bil_count_zero_rm(32, false)
    "LZCNT64RM" => self.project_basic_bil_count_zero_rm(64, false)
    "BT16RR" => self.project_basic_bil_btx_rr(16, "BT")
    "BT32RR" => self.project_basic_bil_btx_rr(32, "BT")
    "BT64RR" => self.project_basic_bil_btx_rr(64, "BT")
    "BT16RI8" => self.project_basic_bil_btx_ri(16, "BT")
    "BT32RI8" => self.project_basic_bil_btx_ri(32, "BT")
    "BT64RI8" => self.project_basic_bil_btx_ri(64, "BT")
    "BT16MR" => self.project_basic_bil_btx_mr(16, "BT")
    "BT32MR" => self.project_basic_bil_btx_mr(32, "BT")
    "BT64MR" => self.project_basic_bil_btx_mr(64, "BT")
    "BT16MI8" => self.project_basic_bil_btx_mi(16, "BT")
    "BT32MI8" => self.project_basic_bil_btx_mi(32, "BT")
    "BT64MI8" => self.project_basic_bil_btx_mi(64, "BT")
    "BTC16RR" => self.project_basic_bil_btx_rr(16, "BTC")
    "BTC32RR" => self.project_basic_bil_btx_rr(32, "BTC")
    "BTC64RR" => self.project_basic_bil_btx_rr(64, "BTC")
    "BTC16RI8" => self.project_basic_bil_btx_ri(16, "BTC")
    "BTC32RI8" => self.project_basic_bil_btx_ri(32, "BTC")
    "BTC64RI8" => self.project_basic_bil_btx_ri(64, "BTC")
    "BTC16MR" => self.project_basic_bil_btx_mr(16, "BTC")
    "BTC32MR" => self.project_basic_bil_btx_mr(32, "BTC")
    "BTC64MR" => self.project_basic_bil_btx_mr(64, "BTC")
    "BTC16MI8" => self.project_basic_bil_btx_mi(16, "BTC")
    "BTC32MI8" => self.project_basic_bil_btx_mi(32, "BTC")
    "BTC64MI8" => self.project_basic_bil_btx_mi(64, "BTC")
    "BTR16RR" => self.project_basic_bil_btx_rr(16, "BTR")
    "BTR32RR" => self.project_basic_bil_btx_rr(32, "BTR")
    "BTR64RR" => self.project_basic_bil_btx_rr(64, "BTR")
    "BTR16RI8" => self.project_basic_bil_btx_ri(16, "BTR")
    "BTR32RI8" => self.project_basic_bil_btx_ri(32, "BTR")
    "BTR64RI8" => self.project_basic_bil_btx_ri(64, "BTR")
    "BTR16MR" => self.project_basic_bil_btx_mr(16, "BTR")
    "BTR32MR" => self.project_basic_bil_btx_mr(32, "BTR")
    "BTR64MR" => self.project_basic_bil_btx_mr(64, "BTR")
    "BTR16MI8" => self.project_basic_bil_btx_mi(16, "BTR")
    "BTR32MI8" => self.project_basic_bil_btx_mi(32, "BTR")
    "BTR64MI8" => self.project_basic_bil_btx_mi(64, "BTR")
    "BTS16RR" => self.project_basic_bil_btx_rr(16, "BTS")
    "BTS32RR" => self.project_basic_bil_btx_rr(32, "BTS")
    "BTS64RR" => self.project_basic_bil_btx_rr(64, "BTS")
    "BTS16RI8" => self.project_basic_bil_btx_ri(16, "BTS")
    "BTS32RI8" => self.project_basic_bil_btx_ri(32, "BTS")
    "BTS64RI8" => self.project_basic_bil_btx_ri(64, "BTS")
    "BTS16MR" => self.project_basic_bil_btx_mr(16, "BTS")
    "BTS32MR" => self.project_basic_bil_btx_mr(32, "BTS")
    "BTS64MR" => self.project_basic_bil_btx_mr(64, "BTS")
    "BTS16MI8" => self.project_basic_bil_btx_mi(16, "BTS")
    "BTS32MI8" => self.project_basic_bil_btx_mi(32, "BTS")
    "BTS64MI8" => self.project_basic_bil_btx_mi(64, "BTS")
    "SHLD16RRI8" | "SHLD16RRCL" => self.project_basic_bil_shiftd_rr(16, true)
    "SHLD32RRI8" | "SHLD32RRCL" => self.project_basic_bil_shiftd_rr(32, true)
    "SHLD64RRI8" | "SHLD64RRCL" => self.project_basic_bil_shiftd_rr(64, true)
    "SHLD16MRI8" | "SHLD16MRCL" => self.project_basic_bil_shiftd_mr(16, true)
    "SHLD32MRI8" | "SHLD32MRCL" => self.project_basic_bil_shiftd_mr(32, true)
    "SHLD64MRI8" | "SHLD64MRCL" => self.project_basic_bil_shiftd_mr(64, true)
    "SHRD16RRI8" | "SHRD16RRCL" => self.project_basic_bil_shiftd_rr(16, false)
    "SHRD32RRI8" | "SHRD32RRCL" => self.project_basic_bil_shiftd_rr(32, false)
    "SHRD64RRI8" | "SHRD64RRCL" => self.project_basic_bil_shiftd_rr(64, false)
    "SHRD16MRI8" | "SHRD16MRCL" => self.project_basic_bil_shiftd_mr(16, false)
    "SHRD32MRI8" | "SHRD32MRCL" => self.project_basic_bil_shiftd_mr(32, false)
    "SHRD64MRI8" | "SHRD64MRCL" => self.project_basic_bil_shiftd_mr(64, false)
    "LDMXCSRM" => self.project_basic_bil_mxcsr_mem(true)
    "STMXCSRM" => self.project_basic_bil_mxcsr_mem(false)
    "CLFLUSH" | "CLFLUSHOPT" | "CLWB" => Ok([])
    "PREFETCHNTA" | "PREFETCHT0" | "PREFETCHT1" | "PREFETCHT2" => Ok([])
    "ROL8R1" | "ROL8RCL" | "ROL8RI8" => self.project_basic_bil_rotate_r(8, true)
    "ROL16R1" | "ROL16RCL" | "ROL16RI8" =>
      self.project_basic_bil_rotate_r(16, true)
    "ROL32R1" | "ROL32RCL" | "ROL32RI8" =>
      self.project_basic_bil_rotate_r(32, true)
    "ROL64R1" | "ROL64RCL" | "ROL64RI8" =>
      self.project_basic_bil_rotate_r(64, true)
    "ROL8M1" | "ROL8MCL" | "ROL8MI8" => self.project_basic_bil_rotate_m(8, true)
    "ROL16M1" | "ROL16MCL" | "ROL16MI8" =>
      self.project_basic_bil_rotate_m(16, true)
    "ROL32M1" | "ROL32MCL" | "ROL32MI8" =>
      self.project_basic_bil_rotate_m(32, true)
    "ROL64M1" | "ROL64MCL" | "ROL64MI8" =>
      self.project_basic_bil_rotate_m(64, true)
    "ROR8R1" | "ROR8RCL" | "ROR8RI8" =>
      self.project_basic_bil_rotate_r(8, false)
    "ROR16R1" | "ROR16RCL" | "ROR16RI8" =>
      self.project_basic_bil_rotate_r(16, false)
    "ROR32R1" | "ROR32RCL" | "ROR32RI8" =>
      self.project_basic_bil_rotate_r(32, false)
    "ROR64R1" | "ROR64RCL" | "ROR64RI8" =>
      self.project_basic_bil_rotate_r(64, false)
    "ROR8M1" | "ROR8MCL" | "ROR8MI8" =>
      self.project_basic_bil_rotate_m(8, false)
    "ROR16M1" | "ROR16MCL" | "ROR16MI8" =>
      self.project_basic_bil_rotate_m(16, false)
    "ROR32M1" | "ROR32MCL" | "ROR32MI8" =>
      self.project_basic_bil_rotate_m(32, false)
    "ROR64M1" | "ROR64MCL" | "ROR64MI8" =>
      self.project_basic_bil_rotate_m(64, false)
    "RCL8R1" | "RCL8RCL" | "RCL8RI8" =>
      self.project_basic_bil_rotate_carry_r(8, true)
    "RCL16R1" | "RCL16RCL" | "RCL16RI8" =>
      self.project_basic_bil_rotate_carry_r(16, true)
    "RCL32R1" | "RCL32RCL" | "RCL32RI8" =>
      self.project_basic_bil_rotate_carry_r(32, true)
    "RCL64R1" | "RCL64RCL" | "RCL64RI8" =>
      self.project_basic_bil_rotate_carry_r(64, true)
    "RCR8R1" | "RCR8RCL" | "RCR8RI8" =>
      self.project_basic_bil_rotate_carry_r(8, false)
    "RCR16R1" | "RCR16RCL" | "RCR16RI8" =>
      self.project_basic_bil_rotate_carry_r(16, false)
    "RCR32R1" | "RCR32RCL" | "RCR32RI8" =>
      self.project_basic_bil_rotate_carry_r(32, false)
    "RCR64R1" | "RCR64RCL" | "RCR64RI8" =>
      self.project_basic_bil_rotate_carry_r(64, false)
    "RCL8M1" | "RCL8MCL" | "RCL8MI8" =>
      self.project_basic_bil_rotate_carry_m(8, true)
    "RCL16M1" | "RCL16MCL" | "RCL16MI8" =>
      self.project_basic_bil_rotate_carry_m(16, true)
    "RCL32M1" | "RCL32MCL" | "RCL32MI8" =>
      self.project_basic_bil_rotate_carry_m(32, true)
    "RCL64M1" | "RCL64MCL" | "RCL64MI8" =>
      self.project_basic_bil_rotate_carry_m(64, true)
    "RCR8M1" | "RCR8MCL" | "RCR8MI8" =>
      self.project_basic_bil_rotate_carry_m(8, false)
    "RCR16M1" | "RCR16MCL" | "RCR16MI8" =>
      self.project_basic_bil_rotate_carry_m(16, false)
    "RCR32M1" | "RCR32MCL" | "RCR32MI8" =>
      self.project_basic_bil_rotate_carry_m(32, false)
    "RCR64M1" | "RCR64MCL" | "RCR64MI8" =>
      self.project_basic_bil_rotate_carry_m(64, false)
    "SHL8R1" | "SHL8RCL" | "SHL8RI8" =>
      self.project_basic_bil_shift_r(8, @types.BinOp::lshift())
    "SHL16R1" | "SHL16RCL" | "SHL16RI8" =>
      self.project_basic_bil_shift_r(16, @types.BinOp::lshift())
    "SHL32R1" | "SHL32RCL" | "SHL32RI8" =>
      self.project_basic_bil_shift_r(32, @types.BinOp::lshift())
    "SHL64R1" | "SHL64RCL" | "SHL64RI8" =>
      self.project_basic_bil_shift_r(64, @types.BinOp::lshift())
    "SHL8M1" | "SHL8MCL" | "SHL8MI8" =>
      self.project_basic_bil_shift_m(8, @types.BinOp::lshift())
    "SHL16M1" | "SHL16MCL" | "SHL16MI8" =>
      self.project_basic_bil_shift_m(16, @types.BinOp::lshift())
    "SHL32M1" | "SHL32MCL" | "SHL32MI8" =>
      self.project_basic_bil_shift_m(32, @types.BinOp::lshift())
    "SHL64M1" | "SHL64MCL" | "SHL64MI8" =>
      self.project_basic_bil_shift_m(64, @types.BinOp::lshift())
    "SHR8R1" | "SHR8RCL" | "SHR8RI8" =>
      self.project_basic_bil_shift_r(8, @types.BinOp::rshift())
    "SHR16R1" | "SHR16RCL" | "SHR16RI8" =>
      self.project_basic_bil_shift_r(16, @types.BinOp::rshift())
    "SHR32R1" | "SHR32RCL" | "SHR32RI8" =>
      self.project_basic_bil_shift_r(32, @types.BinOp::rshift())
    "SHR64R1" | "SHR64RCL" | "SHR64RI8" =>
      self.project_basic_bil_shift_r(64, @types.BinOp::rshift())
    "SHR8M1" | "SHR8MCL" | "SHR8MI8" =>
      self.project_basic_bil_shift_m(8, @types.BinOp::rshift())
    "SHR16M1" | "SHR16MCL" | "SHR16MI8" =>
      self.project_basic_bil_shift_m(16, @types.BinOp::rshift())
    "SHR32M1" | "SHR32MCL" | "SHR32MI8" =>
      self.project_basic_bil_shift_m(32, @types.BinOp::rshift())
    "SHR64M1" | "SHR64MCL" | "SHR64MI8" =>
      self.project_basic_bil_shift_m(64, @types.BinOp::rshift())
    "SAR8R1" | "SAR8RCL" | "SAR8RI8" =>
      self.project_basic_bil_shift_r(8, @types.BinOp::arshift())
    "SAR16R1" | "SAR16RCL" | "SAR16RI8" =>
      self.project_basic_bil_shift_r(16, @types.BinOp::arshift())
    "SAR32R1" | "SAR32RCL" | "SAR32RI8" =>
      self.project_basic_bil_shift_r(32, @types.BinOp::arshift())
    "SAR64R1" | "SAR64RCL" | "SAR64RI8" =>
      self.project_basic_bil_shift_r(64, @types.BinOp::arshift())
    "SAR8M1" | "SAR8MCL" | "SAR8MI8" =>
      self.project_basic_bil_shift_m(8, @types.BinOp::arshift())
    "SAR16M1" | "SAR16MCL" | "SAR16MI8" =>
      self.project_basic_bil_shift_m(16, @types.BinOp::arshift())
    "SAR32M1" | "SAR32MCL" | "SAR32MI8" =>
      self.project_basic_bil_shift_m(32, @types.BinOp::arshift())
    "SAR64M1" | "SAR64MCL" | "SAR64MI8" =>
      self.project_basic_bil_shift_m(64, @types.BinOp::arshift())
    "INC8R" => self.project_basic_bil_incdec(8, @types.BinOp::plus())
    "INC16R" => self.project_basic_bil_incdec(16, @types.BinOp::plus())
    "INC32R" => self.project_basic_bil_incdec(32, @types.BinOp::plus())
    "INC64R" => self.project_basic_bil_incdec(64, @types.BinOp::plus())
    "INC8M" => self.project_basic_bil_incdec_m(8, @types.BinOp::plus())
    "INC16M" => self.project_basic_bil_incdec_m(16, @types.BinOp::plus())
    "INC32M" => self.project_basic_bil_incdec_m(32, @types.BinOp::plus())
    "INC64M" => self.project_basic_bil_incdec_m(64, @types.BinOp::plus())
    "DEC8R" => self.project_basic_bil_incdec(8, @types.BinOp::minus())
    "DEC16R" => self.project_basic_bil_incdec(16, @types.BinOp::minus())
    "DEC32R" => self.project_basic_bil_incdec(32, @types.BinOp::minus())
    "DEC64R" => self.project_basic_bil_incdec(64, @types.BinOp::minus())
    "DEC8M" => self.project_basic_bil_incdec_m(8, @types.BinOp::minus())
    "DEC16M" => self.project_basic_bil_incdec_m(16, @types.BinOp::minus())
    "DEC32M" => self.project_basic_bil_incdec_m(32, @types.BinOp::minus())
    "DEC64M" => self.project_basic_bil_incdec_m(64, @types.BinOp::minus())
    "NOT8R" => self.project_basic_bil_unop_r(8, @types.UnOp::not())
    "NOT16R" => self.project_basic_bil_unop_r(16, @types.UnOp::not())
    "NOT32R" => self.project_basic_bil_unop_r(32, @types.UnOp::not())
    "NOT64R" => self.project_basic_bil_unop_r(64, @types.UnOp::not())
    "NOT8M" => self.project_basic_bil_unop_m(8, @types.UnOp::not())
    "NOT16M" => self.project_basic_bil_unop_m(16, @types.UnOp::not())
    "NOT32M" => self.project_basic_bil_unop_m(32, @types.UnOp::not())
    "NOT64M" => self.project_basic_bil_unop_m(64, @types.UnOp::not())
    "NEG8R" => self.project_basic_bil_neg_r(8)
    "NEG16R" => self.project_basic_bil_neg_r(16)
    "NEG32R" => self.project_basic_bil_neg_r(32)
    "NEG64R" => self.project_basic_bil_neg_r(64)
    "NEG8M" => self.project_basic_bil_neg_m(8)
    "NEG16M" => self.project_basic_bil_neg_m(16)
    "NEG32M" => self.project_basic_bil_neg_m(32)
    "NEG64M" => self.project_basic_bil_neg_m(64)
    "SUB8RR" | "SUB8RR_REV" =>
      self.project_basic_bil_addsub_rr(8, @types.BinOp::minus())
    "SUB16RR" | "SUB16RR_REV" =>
      self.project_basic_bil_addsub_rr(16, @types.BinOp::minus())
    "SUB32RR" | "SUB32RR_REV" =>
      self.project_basic_bil_addsub_rr(32, @types.BinOp::minus())
    "ADD8RR" | "ADD8RR_REV" =>
      self.project_basic_bil_addsub_rr(8, @types.BinOp::plus())
    "ADD16RR" | "ADD16RR_REV" =>
      self.project_basic_bil_addsub_rr(16, @types.BinOp::plus())
    "ADD32RR" | "ADD32RR_REV" =>
      self.project_basic_bil_addsub_rr(32, @types.BinOp::plus())
    "SUB64RR" | "SUB64RR_REV" =>
      self.project_basic_bil_addsub_rr(64, @types.BinOp::minus())
    "ADD64RR" | "ADD64RR_REV" =>
      self.project_basic_bil_addsub_rr(64, @types.BinOp::plus())
    "CMP8RI8" => self.project_basic_bil_cmp_ri(8)
    "CMP16RI8" | "CMP16RI16" => self.project_basic_bil_cmp_ri(16)
    "CMP32RI8" | "CMP32RI32" => self.project_basic_bil_cmp_ri(32)
    "CMP64RI8" | "CMP64RI32" => self.project_basic_bil_cmp_ri(64)
    "CMP8MI8" => self.project_basic_bil_cmp_mi(8)
    "CMP16MI8" | "CMP16MI16" => self.project_basic_bil_cmp_mi(16)
    "CMP32MI8" | "CMP32MI32" => self.project_basic_bil_cmp_mi(32)
    "CMP64MI8" | "CMP64MI32" => self.project_basic_bil_cmp_mi(64)
    "CMP8RR" | "CMP8RR_REV" => self.project_basic_bil_cmp_rr(8)
    "CMP16RR" | "CMP16RR_REV" => self.project_basic_bil_cmp_rr(16)
    "CMP32RR" | "CMP32RR_REV" => self.project_basic_bil_cmp_rr(32)
    "CMP64RR" | "CMP64RR_REV" => self.project_basic_bil_cmp_rr(64)
    "CMP8RM" => self.project_basic_bil_cmp_rm(8)
    "CMP16RM" => self.project_basic_bil_cmp_rm(16)
    "CMP32RM" => self.project_basic_bil_cmp_rm(32)
    "CMP64RM" => self.project_basic_bil_cmp_rm(64)
    "CMP8MR" => self.project_basic_bil_cmp_mr(8)
    "CMP16MR" => self.project_basic_bil_cmp_mr(16)
    "CMP32MR" => self.project_basic_bil_cmp_mr(32)
    "CMP64MR" => self.project_basic_bil_cmp_mr(64)
    "CMPXCHG8RR" => self.project_basic_bil_cmpxchg_rr(8)
    "CMPXCHG16RR" => self.project_basic_bil_cmpxchg_rr(16)
    "CMPXCHG32RR" => self.project_basic_bil_cmpxchg_rr(32)
    "CMPXCHG64RR" => self.project_basic_bil_cmpxchg_rr(64)
    "CMPXCHG8MR" => self.project_basic_bil_cmpxchg_mr(8)
    "CMPXCHG16MR" => self.project_basic_bil_cmpxchg_mr(16)
    "CMPXCHG32MR" => self.project_basic_bil_cmpxchg_mr(32)
    "CMPXCHG64MR" => self.project_basic_bil_cmpxchg_mr(64)
    "XADD8RR" => self.project_basic_bil_xadd_rr(8)
    "XADD16RR" => self.project_basic_bil_xadd_rr(16)
    "XADD32RR" => self.project_basic_bil_xadd_rr(32)
    "XADD64RR" => self.project_basic_bil_xadd_rr(64)
    "XADD8MR" => self.project_basic_bil_xadd_mr(8)
    "XADD16MR" => self.project_basic_bil_xadd_mr(16)
    "XADD32MR" => self.project_basic_bil_xadd_mr(32)
    "XADD64MR" => self.project_basic_bil_xadd_mr(64)
    "CMPXCHG8BM" => self.project_basic_bil_cmpxchg8b()
    "RDRAND16R" => self.project_basic_bil_random(16, "rdrand")
    "RDRAND32R" => self.project_basic_bil_random(32, "rdrand")
    "RDRAND64R" => self.project_basic_bil_random(64, "rdrand")
    "RDSEED16R" => self.project_basic_bil_random(16, "rdseed")
    "RDSEED32R" => self.project_basic_bil_random(32, "rdseed")
    "RDSEED64R" => self.project_basic_bil_random(64, "rdseed")
    "MOVBE16RM" => self.project_basic_bil_mov_rm_endian(16, BigEndian)
    "MOVBE32RM" => self.project_basic_bil_mov_rm_endian(32, BigEndian)
    "MOVBE64RM" => self.project_basic_bil_mov_rm_endian(64, BigEndian)
    "MOVBE16MR" => self.project_basic_bil_mov_mr_endian(16, BigEndian)
    "MOVBE32MR" => self.project_basic_bil_mov_mr_endian(32, BigEndian)
    "MOVBE64MR" => self.project_basic_bil_mov_mr_endian(64, BigEndian)
    "MOV8RM" => self.project_basic_bil_mov_rm(8)
    "MOV16RM" => self.project_basic_bil_mov_rm(16)
    "MOV32RM" => self.project_basic_bil_mov_rm(32)
    "MOV64RM" => self.project_basic_bil_mov_rm(64)
    "MOV8MR" => self.project_basic_bil_mov_mr(8)
    "MOV16MR" => self.project_basic_bil_mov_mr(16)
    "MOV32MR" => self.project_basic_bil_mov_mr(32)
    "MOV64MR" => self.project_basic_bil_mov_mr(64)
    "MOV8MI" => self.project_basic_bil_mov_mi(8)
    "MOV16MI" => self.project_basic_bil_mov_mi(16)
    "MOV32MI" => self.project_basic_bil_mov_mi(32)
    "MOV64MI" => self.project_basic_bil_mov_mi(64)
    "MOV8RA" => self.project_basic_bil_mov_abs_load(8)
    "MOV16RA" => self.project_basic_bil_mov_abs_load(16)
    "MOV32RA" => self.project_basic_bil_mov_abs_load(32)
    "MOV64RA" => self.project_basic_bil_mov_abs_load(64)
    "MOV8AR" => self.project_basic_bil_mov_abs_store(8)
    "MOV16AR" => self.project_basic_bil_mov_abs_store(16)
    "MOV32AR" => self.project_basic_bil_mov_abs_store(32)
    "MOV64AR" => self.project_basic_bil_mov_abs_store(64)
    "LEA16R" => self.project_basic_bil_lea(16)
    "LEA32R" => self.project_basic_bil_lea(32)
    "LEA64R" => self.project_basic_bil_lea(64)
    "MOV8RI" => self.project_basic_bil_mov_imm(8)
    "MOV16RI" => self.project_basic_bil_mov_imm(16)
    "MOV32RI" => self.project_basic_bil_mov_imm(32)
    "MOV64RI" => self.project_basic_bil_mov_imm(64)
    "MOV64RI32" => self.project_basic_bil_mov_imm(64)
    "MOV8RR" | "MOV8RR_REV" => self.project_basic_bil_mov_rr(8)
    "MOV16RR" | "MOV16RR_REV" => self.project_basic_bil_mov_rr(16)
    "MOV32RR" | "MOV32RR_REV" => self.project_basic_bil_mov_rr(32)
    "MOV64RR" | "MOV64RR_REV" => self.project_basic_bil_mov_rr(64)
    "MOVZX16RR8" =>
      self.project_basic_bil_movx_rr(16, 8, @types.CastKind::unsigned())
    "MOVZX32RR8" =>
      self.project_basic_bil_movx_rr(32, 8, @types.CastKind::unsigned())
    "MOVZX64RR8" =>
      self.project_basic_bil_movx_rr(64, 8, @types.CastKind::unsigned())
    "MOVZX16RM8" =>
      self.project_basic_bil_movx_rm(16, 8, @types.CastKind::unsigned())
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
    "MOVSX16RR8" =>
      self.project_basic_bil_movx_rr(16, 8, @types.CastKind::signed())
    "MOVSX32RR8" =>
      self.project_basic_bil_movx_rr(32, 8, @types.CastKind::signed())
    "MOVSX64RR8" =>
      self.project_basic_bil_movx_rr(64, 8, @types.CastKind::signed())
    "MOVSX16RM8" =>
      self.project_basic_bil_movx_rm(16, 8, @types.CastKind::signed())
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
    "XCHG16RR" => self.project_basic_bil_xchg_rr(16)
    "XCHG32RR" => self.project_basic_bil_xchg_rr(32)
    "XCHG64RR" => self.project_basic_bil_xchg_rr(64)
    "XCHG8RM" => self.project_basic_bil_xchg_rm(8)
    "XCHG16RM" => self.project_basic_bil_xchg_rm(16)
    "XCHG32RM" => self.project_basic_bil_xchg_rm(32)
    "XCHG64RM" => self.project_basic_bil_xchg_rm(64)
    "OR8RR" | "OR8RR_REV" =>
      self.project_basic_bil_logic_rr(8, @types.BinOp::bit_or())
    "OR16RR" | "OR16RR_REV" =>
      self.project_basic_bil_logic_rr(16, @types.BinOp::bit_or())
    "OR32RR" | "OR32RR_REV" =>
      self.project_basic_bil_logic_rr(32, @types.BinOp::bit_or())
    "OR64RR" | "OR64RR_REV" =>
      self.project_basic_bil_logic_rr(64, @types.BinOp::bit_or())
    "OR8RM" => self.project_basic_bil_logic_rm(8, @types.BinOp::bit_or())
    "OR16RM" => self.project_basic_bil_logic_rm(16, @types.BinOp::bit_or())
    "OR32RM" => self.project_basic_bil_logic_rm(32, @types.BinOp::bit_or())
    "OR64RM" => self.project_basic_bil_logic_rm(64, @types.BinOp::bit_or())
    "OR8MR" => self.project_basic_bil_logic_mr(8, @types.BinOp::bit_or())
    "OR16MR" => self.project_basic_bil_logic_mr(16, @types.BinOp::bit_or())
    "OR32MR" => self.project_basic_bil_logic_mr(32, @types.BinOp::bit_or())
    "OR64MR" => self.project_basic_bil_logic_mr(64, @types.BinOp::bit_or())
    "AND8RR" | "AND8RR_REV" =>
      self.project_basic_bil_logic_rr(8, @types.BinOp::bit_and())
    "AND16RR" | "AND16RR_REV" =>
      self.project_basic_bil_logic_rr(16, @types.BinOp::bit_and())
    "AND32RR" | "AND32RR_REV" =>
      self.project_basic_bil_logic_rr(32, @types.BinOp::bit_and())
    "AND64RR" | "AND64RR_REV" =>
      self.project_basic_bil_logic_rr(64, @types.BinOp::bit_and())
    "AND8RM" => self.project_basic_bil_logic_rm(8, @types.BinOp::bit_and())
    "AND16RM" => self.project_basic_bil_logic_rm(16, @types.BinOp::bit_and())
    "AND32RM" => self.project_basic_bil_logic_rm(32, @types.BinOp::bit_and())
    "AND64RM" => self.project_basic_bil_logic_rm(64, @types.BinOp::bit_and())
    "AND8MR" => self.project_basic_bil_logic_mr(8, @types.BinOp::bit_and())
    "AND16MR" => self.project_basic_bil_logic_mr(16, @types.BinOp::bit_and())
    "AND32MR" => self.project_basic_bil_logic_mr(32, @types.BinOp::bit_and())
    "AND64MR" => self.project_basic_bil_logic_mr(64, @types.BinOp::bit_and())
    "XOR8RR" | "XOR8RR_REV" =>
      self.project_basic_bil_logic_rr(8, @types.BinOp::bit_xor())
    "XOR16RR" | "XOR16RR_REV" =>
      self.project_basic_bil_logic_rr(16, @types.BinOp::bit_xor())
    "XOR32RR" | "XOR32RR_REV" =>
      self.project_basic_bil_logic_rr(32, @types.BinOp::bit_xor())
    "XOR64RR" | "XOR64RR_REV" =>
      self.project_basic_bil_logic_rr(64, @types.BinOp::bit_xor())
    "XOR8RM" => self.project_basic_bil_logic_rm(8, @types.BinOp::bit_xor())
    "XOR16RM" => self.project_basic_bil_logic_rm(16, @types.BinOp::bit_xor())
    "XOR32RM" => self.project_basic_bil_logic_rm(32, @types.BinOp::bit_xor())
    "XOR64RM" => self.project_basic_bil_logic_rm(64, @types.BinOp::bit_xor())
    "XOR8MR" => self.project_basic_bil_logic_mr(8, @types.BinOp::bit_xor())
    "XOR16MR" => self.project_basic_bil_logic_mr(16, @types.BinOp::bit_xor())
    "XOR32MR" => self.project_basic_bil_logic_mr(32, @types.BinOp::bit_xor())
    "XOR64MR" => self.project_basic_bil_logic_mr(64, @types.BinOp::bit_xor())
    "ADC8RR" | "ADC8RR_REV" => self.project_basic_bil_adc_rr(8)
    "ADC16RR" | "ADC16RR_REV" => self.project_basic_bil_adc_rr(16)
    "ADC32RR" | "ADC32RR_REV" => self.project_basic_bil_adc_rr(32)
    "ADC64RR" | "ADC64RR_REV" => self.project_basic_bil_adc_rr(64)
    "ADC8RM" => self.project_basic_bil_adc_rm(8)
    "ADC16RM" => self.project_basic_bil_adc_rm(16)
    "ADC32RM" => self.project_basic_bil_adc_rm(32)
    "ADC64RM" => self.project_basic_bil_adc_rm(64)
    "ADC8MR" => self.project_basic_bil_adc_mr(8)
    "ADC16MR" => self.project_basic_bil_adc_mr(16)
    "ADC32MR" => self.project_basic_bil_adc_mr(32)
    "ADC64MR" => self.project_basic_bil_adc_mr(64)
    "SBB8RR" | "SBB8RR_REV" => self.project_basic_bil_sbb_rr(8)
    "SBB16RR" | "SBB16RR_REV" => self.project_basic_bil_sbb_rr(16)
    "SBB32RR" | "SBB32RR_REV" => self.project_basic_bil_sbb_rr(32)
    "SBB64RR" | "SBB64RR_REV" => self.project_basic_bil_sbb_rr(64)
    "SBB8RM" => self.project_basic_bil_sbb_rm(8)
    "SBB16RM" => self.project_basic_bil_sbb_rm(16)
    "SBB32RM" => self.project_basic_bil_sbb_rm(32)
    "SBB64RM" => self.project_basic_bil_sbb_rm(64)
    "SBB8MR" => self.project_basic_bil_sbb_mr(8)
    "SBB16MR" => self.project_basic_bil_sbb_mr(16)
    "SBB32MR" => self.project_basic_bil_sbb_mr(32)
    "SBB64MR" => self.project_basic_bil_sbb_mr(64)
    "TEST16RI16" => self.project_basic_bil_test_ri(16)
    "TEST8RI8" => self.project_basic_bil_test_ri(8)
    "TEST32RI32" => self.project_basic_bil_test_ri(32)
    "TEST64RI32" => self.project_basic_bil_test_ri(64)
    "TEST8RR" | "TEST8RR_REV" => self.project_basic_bil_test_rr(8)
    "TEST16RR" | "TEST16RR_REV" => self.project_basic_bil_test_rr(16)
    "TEST32RR" | "TEST32RR_REV" => self.project_basic_bil_test_rr(32)
    "TEST64RR" | "TEST64RR_REV" => self.project_basic_bil_test_rr(64)
    "TEST8MR" => self.project_basic_bil_test_mr(8)
    "TEST16MR" => self.project_basic_bil_test_mr(16)
    "TEST32MR" => self.project_basic_bil_test_mr(32)
    "TEST64MR" => self.project_basic_bil_test_mr(64)
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
    "PUSH16R" | "PUSH16I8" | "PUSH16I16" => self.project_basic_bil_push(16, 32)
    "PUSH16R_64" | "PUSH16I8_64" | "PUSH16I16_64" =>
      self.project_basic_bil_push(16, 64)
    "PUSH32R" | "PUSH32I8" | "PUSH32I32" => self.project_basic_bil_push(32, 32)
    "PUSH64R" | "PUSH64I8" | "PUSH64I32" => self.project_basic_bil_push(64, 64)
    "PUSH16M" => self.project_basic_bil_push_mem(16, 32)
    "PUSH16M_64" => self.project_basic_bil_push_mem(16, 64)
    "PUSH32M" => self.project_basic_bil_push_mem(32, 32)
    "PUSH64M" => self.project_basic_bil_push_mem(64, 64)
    "POP16R" => self.project_basic_bil_pop(16, 32)
    "POP16R_64" => self.project_basic_bil_pop(16, 64)
    "POP32R" => self.project_basic_bil_pop(32, 32)
    "POP64R" => self.project_basic_bil_pop(64, 64)
    "LEAVE16" => self.project_basic_bil_leave(16, 32)
    "LEAVE16_64" => self.project_basic_bil_leave(16, 64)
    "LEAVE" => self.project_basic_bil_leave(32, 32)
    "LEAVE64" => self.project_basic_bil_leave(64, 64)
    "ENDBR32" | "ENDBR64" => Ok([])
    "NOOP" | "PAUSE" | "LFENCE" | "MFENCE" | "SFENCE" => Ok([])
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
    "PUSHF16" => project_basic_bil_x86_pushf(16, 32)
    "PUSHF16_64" => project_basic_bil_x86_pushf(16, 64)
    "PUSHF32" => project_basic_bil_x86_pushf(32, 32)
    "PUSHF64" => project_basic_bil_x86_pushf(64, 64)
    "POPF16" => project_basic_bil_x86_popf(16, 32)
    "POPF16_64" => project_basic_bil_x86_popf(16, 64)
    "POPF32" => project_basic_bil_x86_popf(32, 32)
    "POPF64" => project_basic_bil_x86_popf(64, 64)
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
    "JECXZ_1" => self.project_basic_bil_jcxz(32)
    "JRCXZ_1" => self.project_basic_bil_jcxz(64)
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
