// Basic BIL of x86 instructions that the LLVM-compatible decoder produces
// and the main dispatch of `lift_basic_bil` does not handle, keyed on
// their LLVM opcode names: TEST with a memory and an immediate operand,
// LODS (and REP LODS), LOOP/LOOPE/LOOPNE, ENTER with nesting level 0, POP
// to memory and CMPXCHG16B.

///|
/// Whether the address-size prefix (0x67) precedes the opcode.
fn x86_ext_has_adsize(bytes : Bytes, mode64 : Bool) -> Bool {
  for byte in bytes {
    let b = byte.to_int()
    match b {
      0x67 => return true
      0x26 | 0x2E | 0x36 | 0x3E | 0x64 | 0x65 | 0x66 | 0xF0 | 0xF2 | 0xF3 => ()
      _ => if !(mode64 && b >= 0x40 && b <= 0x4F) { break }
    }
  }
  false
}

///|
/// `TEST m, imm`: the flags of the conjunction of the memory operand and
/// the immediate.
fn ProjectDisassemblyInstruction::project_basic_bil_test_mi(
  self : ProjectDisassemblyInstruction,
  width : Int32,
) -> Result[Array[@types.Stmt], String] {
  project_basic_bil_result(() => {
    let (addr, mem, address_width) = bil_ok(
      self.project_basic_bil_memory_addr(0),
    )
    let imm = bil_ok(self.project_basic_bil_immediate(5))
    let rhs = bil_ok(project_basic_bil_int(imm, width))
    let size = bil_ok(@types.Size::of_int(width))
    let addr_tmp = project_basic_bil_virtual("test_a", address_width)
    let result_tmp = project_basic_bil_virtual("test_tmp", width)
    let stmts = [
      @types.Stmt::move_stmt(addr_tmp, addr),
      @types.Stmt::move_stmt(
        result_tmp,
        @types.Exp::binop(
          @types.BinOp::bit_and(),
          @types.Exp::load(
            mem=@types.Exp::var_exp(mem),
            addr=@types.Exp::var_exp(addr_tmp),
            LittleEndian,
            size,
          ),
          rhs,
        ),
      ),
    ]
    for
      stmt in bil_ok(
        project_basic_bil_x86_test_flag_moves(
          @types.Exp::var_exp(result_tmp),
          width,
        ),
      ) {
      stmts.push(stmt)
    }
    stmts
  })
}

///|
/// `LODS`: the accumulator is loaded from the source index, which moves
/// according to `DF`; with a repeat prefix, `RCX`/`ECX` times.
fn ProjectDisassemblyInstruction::project_basic_bil_lods(
  self : ProjectDisassemblyInstruction,
  data_width : Int32,
) -> Result[Array[@types.Stmt], String] {
  let address_width = match self.operands().get(0) {
    Some(ProjectRegisterOperand(_, "RSI")) => 64
    Some(ProjectRegisterOperand(_, "ESI")) => 32
    _ => return Err("unsupported \{self.name()} address size")
  }
  project_basic_bil_result(() => {
    let src = bil_ok(project_basic_bil_string_index(address_width, true))
    let dst = bil_ok(project_basic_bil_x86_accumulator(data_width))
    let size = bil_ok(@types.Size::of_int(data_width))
    let mem = project_basic_bil_stack_mem(address_width)
    let body = [
      @types.Stmt::move_stmt(
        dst,
        @types.Exp::load(
          mem=@types.Exp::var_exp(mem),
          addr=@types.Exp::var_exp(src),
          LittleEndian,
          size,
        ),
      ),
      @types.Stmt::move_stmt(
        src,
        bil_ok(project_basic_bil_string_next(src, data_width, address_width)),
      ),
    ]
    let rep = x86_legacy_repeat_prefix(
      self.memory().to_bytes(),
      self.encoding() == "llvm-x86_64",
    )
    if rep != 0 {
      bil_ok(project_basic_bil_string_rep_wrap(body, address_width, 0))
    } else {
      body
    }
  })
}

///|
/// `LOOP`, `LOOPE` (`zf_mode` 1) and `LOOPNE` (-1): the count register
/// (`RCX`, or `ECX` with 32-bit addresses) is decremented, without
/// changing the flags, and the branch is taken when it is not zero (and
/// `ZF` is set, or clear).
fn ProjectDisassemblyInstruction::project_basic_bil_loop(
  self : ProjectDisassemblyInstruction,
  zf_mode : Int32,
) -> Result[Array[@types.Stmt], String] {
  let mode64 = self.encoding() == "llvm-x86_64"
  let adsize = x86_ext_has_adsize(self.memory().to_bytes(), mode64)
  let width = if mode64 && !adsize {
    64
  } else if !adsize {
    32
  } else if mode64 {
    32
  } else {
    return Err("unsupported \{self.name()} with 16-bit addresses")
  }
  project_basic_bil_result(() => {
    let rel = bil_ok(self.project_basic_bil_immediate(0))
    let next = self.addr() + self.memory().length().to_uint64()
    let target = match project_disassembly_basic_add_signed_offset(next, rel) {
      Some(target) => if mode64 { target } else { target & 0xFFFFFFFFUL }
      None =>
        raise ProjectBasicBilFailure(
          "direct target for \{self.name()} is not representable",
        )
    }
    let count = project_basic_bil_reg(
      if width == 64 {
        "RCX"
      } else {
        "ECX"
      },
      width,
    )
    let count_exp = @types.Exp::var_exp(count)
    let taken = @types.Exp::binop(
      @types.BinOp::neq(),
      count_exp,
      bil_ok(project_basic_bil_int(0L, width)),
    )
    let cond = match zf_mode {
      1 =>
        @types.Exp::binop(
          @types.BinOp::bit_and(),
          taken,
          project_basic_bil_x86_flag("ZF"),
        )
      -1 =>
        @types.Exp::binop(
          @types.BinOp::bit_and(),
          taken,
          project_basic_bil_x86_not(project_basic_bil_x86_flag("ZF")),
        )
      _ => taken
    }
    [
      @types.Stmt::move_stmt(
        count,
        @types.Exp::binop(
          @types.BinOp::minus(),
          count_exp,
          bil_ok(project_basic_bil_int(1L, width)),
        ),
      ),
      @types.Stmt::if_(
        cond,
        bil_ok(project_basic_bil_control(@types.Stmt::goto(), target)),
        [],
      ),
    ]
  })
}

///|
/// `ENTER size, level`: pushes the frame pointer, copies `level - 1`
/// frame pointers of the enclosing frames and pushes the new frame pointer
/// when `level` is not zero, makes the frame pointer the new frame and
/// allocates `size` bytes (the 16-bit form is not supported).
fn ProjectDisassemblyInstruction::project_basic_bil_enter(
  self : ProjectDisassemblyInstruction,
) -> Result[Array[@types.Stmt], String] {
  let mode64 = self.encoding() == "llvm-x86_64"
  if x86_legacy_has_opsize(self.memory().to_bytes(), mode64) {
    return Err("unsupported 16-bit \{self.name()}")
  }
  project_basic_bil_result(() => {
    let size = bil_ok(self.project_basic_bil_immediate(0)) & 0xFFFFL
    let level = (bil_ok(self.project_basic_bil_immediate(1)) & 0x1FL).to_int()
    let width = if mode64 { 64 } else { 32 }
    let sp = bil_ok(project_basic_bil_stack_pointer(width))
    let bp = project_basic_bil_reg(if mode64 { "RBP" } else { "EBP" }, width)
    let mem = project_basic_bil_stack_mem(width)
    let value_size = bil_ok(@types.Size::of_int(width))
    let frame = project_basic_bil_virtual("enter_frame", width)
    let stmts = []
    let push = (value : @types.Exp) => {
      stmts.push(
        @types.Stmt::move_stmt(
          sp,
          bil_ok(project_basic_bil_stack_decrement(sp, width, width)),
        ),
      )
      stmts.push(
        @types.Stmt::move_stmt(
          mem,
          @types.Exp::store(
            mem=@types.Exp::var_exp(mem),
            addr=@types.Exp::var_exp(sp),
            value,
            LittleEndian,
            value_size,
          ),
        ),
      )
    }
    push(@types.Exp::var_exp(bp))
    stmts.push(@types.Stmt::move_stmt(frame, @types.Exp::var_exp(sp)))
    if level > 0 {
      for _ in 1..<level {
        stmts.push(
          @types.Stmt::move_stmt(
            bp,
            bil_ok(project_basic_bil_stack_decrement(bp, width, width)),
          ),
        )
        push(
          @types.Exp::load(
            mem=@types.Exp::var_exp(mem),
            addr=@types.Exp::var_exp(bp),
            LittleEndian,
            value_size,
          ),
        )
      }
      push(@types.Exp::var_exp(frame))
    }
    stmts.push(@types.Stmt::move_stmt(bp, @types.Exp::var_exp(frame)))
    if size != 0L {
      stmts.push(
        @types.Stmt::move_stmt(
          sp,
          @types.Exp::binop(
            @types.BinOp::minus(),
            @types.Exp::var_exp(sp),
            bil_ok(project_basic_bil_int(size, width)),
          ),
        ),
      )
    }
    stmts
  })
}

///|
/// `POP m`: the value on the top of the stack is stored to the memory
/// operand, whose address is computed after the stack pointer is
/// incremented.
fn ProjectDisassemblyInstruction::project_basic_bil_pop_mem(
  self : ProjectDisassemblyInstruction,
  value_width : Int32,
) -> Result[Array[@types.Stmt], String] {
  let stack_width = if self.encoding() == "llvm-x86_64" { 64 } else { 32 }
  project_basic_bil_result(() => {
    let sp = bil_ok(project_basic_bil_stack_pointer(stack_width))
    let stack = project_basic_bil_stack_mem(stack_width)
    let size = bil_ok(@types.Size::of_int(value_width))
    let tmp = project_basic_bil_virtual("pop_value", value_width)
    let (addr, mem, _) = bil_ok(self.project_basic_bil_memory_addr(0))
    [
      @types.Stmt::move_stmt(
        tmp,
        @types.Exp::load(
          mem=@types.Exp::var_exp(stack),
          addr=@types.Exp::var_exp(sp),
          LittleEndian,
          size,
        ),
      ),
      @types.Stmt::move_stmt(
        sp,
        bil_ok(project_basic_bil_stack_increment(sp, value_width, stack_width)),
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
    ]
  })
}

///|
/// `CMPXCHG16B m128`: compares `RDX:RAX` with the memory operand; when
/// equal, `ZF` is set and `RCX:RBX` is stored, otherwise `ZF` is cleared
/// and the operand is loaded into `RDX:RAX` (the operand is written back
/// in both cases).
fn ProjectDisassemblyInstruction::project_basic_bil_cmpxchg16b(
  self : ProjectDisassemblyInstruction,
) -> Result[Array[@types.Stmt], String] {
  project_basic_bil_result(() => {
    let (addr, mem, address_width) = bil_ok(
      self.project_basic_bil_memory_addr(0),
    )
    let size = bil_ok(@types.Size::of_int(128))
    let addr_tmp = project_basic_bil_virtual("cmpxchg16b_a", address_width)
    let dst_tmp = project_basic_bil_virtual("cmpxchg16b_d", 128)
    let equal = project_basic_bil_virtual("cmpxchg16b_eq", 1)
    let rax = project_basic_bil_reg("RAX", 64)
    let rbx = project_basic_bil_reg("RBX", 64)
    let rcx = project_basic_bil_reg("RCX", 64)
    let rdx = project_basic_bil_reg("RDX", 64)
    let addr_exp = @types.Exp::var_exp(addr_tmp)
    let dst_exp = @types.Exp::var_exp(dst_tmp)
    let equal_exp = @types.Exp::var_exp(equal)
    [
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
        @types.Exp::binop(
          @types.BinOp::eq(),
          @types.Exp::concat(@types.Exp::var_exp(rdx), @types.Exp::var_exp(rax)),
          dst_exp,
        ),
      ),
      project_basic_bil_x86_flag_move("ZF", equal_exp),
      @types.Stmt::move_stmt(
        mem,
        @types.Exp::store(
          mem=@types.Exp::var_exp(mem),
          addr=addr_exp,
          @types.Exp::ite(
            if_=equal_exp,
            then_=@types.Exp::concat(
              @types.Exp::var_exp(rcx),
              @types.Exp::var_exp(rbx),
            ),
            else_=dst_exp,
          ),
          LittleEndian,
          size,
        ),
      ),
      @types.Stmt::if_(equal_exp, [], [
        @types.Stmt::move_stmt(rax, @types.Exp::extract(dst_exp, hi=63, lo=0)),
        @types.Stmt::move_stmt(rdx, @types.Exp::extract(dst_exp, hi=127, lo=64)),
      ]),
    ]
  })
}

///|
/// The Basic BIL of the instructions of this file, or `None`.
fn ProjectDisassemblyInstruction::project_basic_bil_x86_extension(
  self : ProjectDisassemblyInstruction,
) -> Result[Array[@types.Stmt], String]? {
  if !(self.encoding() is ("llvm-x86" | "llvm-x86_64")) {
    return None
  }
  match self.name() {
    "TEST8mi" => Some(self.project_basic_bil_test_mi(8))
    "TEST16mi" => Some(self.project_basic_bil_test_mi(16))
    "TEST32mi" => Some(self.project_basic_bil_test_mi(32))
    "TEST64mi32" => Some(self.project_basic_bil_test_mi(64))
    "LODSB" => Some(self.project_basic_bil_lods(8))
    "LODSW" => Some(self.project_basic_bil_lods(16))
    "LODSL" => Some(self.project_basic_bil_lods(32))
    "LODSQ" => Some(self.project_basic_bil_lods(64))
    "LOOP" => Some(self.project_basic_bil_loop(0))
    "LOOPE" => Some(self.project_basic_bil_loop(1))
    "LOOPNE" => Some(self.project_basic_bil_loop(-1))
    "ENTER" => Some(self.project_basic_bil_enter())
    "POP64rmm" => Some(self.project_basic_bil_pop_mem(64))
    "POP32rmm" => Some(self.project_basic_bil_pop_mem(32))
    "POP16rmm" => Some(self.project_basic_bil_pop_mem(16))
    "CMPXCHG16B" => Some(self.project_basic_bil_cmpxchg16b())
    _ => None
  }
}
