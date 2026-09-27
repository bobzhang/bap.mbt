// SystemZ register file of the tables: `R0`..`R15`. The port has no
// SystemZ decoder; the instructions are built with the opcode names and
// operands LLVM's disassembler produces (`LR %r1, %r2` is
// `LR [R1L, R2L]`, `LGR` is `LGR [R1D, R2D]`, ...).

///|
/// The LLVM MC form of the register-move encodings of the tables.
fn systemz_insn(bytes : Bytes, addr : UInt64) -> @mc.Insn? {
  let reg = (n : Int, suffix : String) => @mc.Op::reg("R\{n}\{suffix}")
  let rr = (byte : Byte) => (byte.to_int() >> 4, byte.to_int() & 15)
  match bytes {
    [b'\x18', regs] => {
      let (r1, r2) = rr(regs)
      Some(@mc.Insn::create("LR", [reg(r1, "L"), reg(r2, "L")], addr~, size=2))
    }
    [b'\xb9', op, _, regs] => {
      let (r1, r2) = rr(regs)
      let (name, suffix) = match op {
        b'\x04' => ("LGR", "D")
        b'\x14' => ("LGFR", "L")
        b'\x16' => ("LLGFR", "L")
        _ => return None
      }
      Some(
        @mc.Insn::create(name, [reg(r1, "D"), reg(r2, suffix)], addr~, size=4),
      )
    }
    _ => None
  }
}

///|
fn systemz() -> Isa {
  {
    target: @core_theory.Target::systemz(),
    addr_width: 64,
    pc: 0x10000,
    encode: word_encoding(code => {
      let size = if code < 0x10000 { 2 } else { 4 }
      Bytes::makei(size, i => (code >> (8 * (size - 1 - i))).to_byte())
    }),
    decode: systemz_insn,
    regs: Array::makei(16, i => "R\{i}"),
    write: (state, name, v) => state.set(name, word(64, v)),
    read: read_word,
    fallthrough: insn => insn.addr() + insn.size().to_uint64(),
    care: default_care,
    pc_care: 0xFFFF_FFFF_FFFF_FFFF,
  }
}

///|
test "systemz: register moves" {
  check(systemz(), systemz_cases)
}
