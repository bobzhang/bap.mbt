// RISC-V register file of the tables: `R1`..`R31` (`X1`..`X31`; `X0` is
// hardwired to zero and left unbound). Instructions are lifted with the
// `riscv.lisp` semantics (the Primus Lisp providers).

///|
fn riscv(xlen : @rv.Xlen) -> Isa {
  let (target, bits) = match xlen {
    RV64 => (@core_theory.Target::riscv64(), 64)
    RV32 => (@core_theory.Target::riscv32(), 32)
  }
  {
    target,
    addr_width: bits,
    pc: 0x1000_0000,
    encode: word_encoding(code => {
      let size = if (code & 3) == 3 { 4 } else { 2 }
      Bytes::makei(size, i => (code >> (8 * i)).to_byte())
    }),
    decode: (bytes, addr) => @rv.decode(bytes, addr, xlen~),
    regs: Array::makei(31, i => "R\{i + 1}"),
    write: (state, name, v) => {
      state.set("X" + name.view(start_offset=1).to_owned(), word(bits, v))
    },
    read: (state, name) => {
      read_word(state, "X" + name.view(start_offset=1).to_owned())
    },
    fallthrough: insn => insn.addr() + insn.size().to_uint64(),
    care: default_care,
    pc_care: 0xFFFF_FFFF_FFFF_FFFF,
  }
}

///|
test "rv32: integer, multiply/divide and compressed ALU instructions" {
  check(riscv(RV32), rv32_alu_cases)
}

///|
test "rv32: loads and stores" {
  check(riscv(RV32), rv32_mem_cases)
}

///|
test "rv32: branches and jumps" {
  check(riscv(RV32), rv32_branch_cases)
}

///|
test "rv64: integer, multiply/divide and compressed ALU instructions" {
  check(riscv(RV64), rv64_alu_cases)
}

///|
test "rv64: loads and stores" {
  check(riscv(RV64), rv64_mem_cases)
}

///|
test "rv64: branches and jumps" {
  check(riscv(RV64), rv64_branch_cases)
}
