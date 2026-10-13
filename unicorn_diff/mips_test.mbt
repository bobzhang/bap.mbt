// MIPS register file of the tables: `R1`..`R31` (the lifter's ABI-named
// general purpose registers), `HI` and `LO`. Branches are run in Unicorn
// with a `nop` in their delay slot; `PC` is the address reached after the
// delay slot (`pc + 8` when a branch is not taken).

///|
fn mips(bits : Int32, endian : @bitvec.Endian, r6~ : Bool = false) -> Isa {
  let arch : @mips.Arch = if bits == 64 { Mips64 } else { Mips32 }
  let target = match (bits, endian) {
    (64, LittleEndian) => @core_theory.Target::mips64el()
    (64, _) => @core_theory.Target::mips64()
    (_, LittleEndian) => @core_theory.Target::mipsel()
    _ => @core_theory.Target::mips()
  }
  let names : Map[String, String] = {
    "HI": arch.hi().name,
    "LO": arch.lo().name,
  }
  for i in 1..<32 {
    names["R\{i}"] = arch.gpr(i).unwrap().name
  }
  let regs = Array::makei(31, i => "R\{i + 1}") + ["HI", "LO"]
  {
    target,
    addr_width: bits,
    pc: 0x1000_0000,
    encode: word_encoding(code => {
      Bytes::makei(4, i => {
        let shift = match endian {
          LittleEndian => 8 * i
          _ => 24 - 8 * i
        }
        (code >> shift).to_byte()
      })
    }),
    decode: (bytes, addr) => @mips.decode(bytes, addr, arch~, endian~, r6~),
    regs,
    write: (state, name, v) => state.set(names[name], word(bits, v)),
    read: (state, name) => read_word(state, names[name]),
    fallthrough: insn => {
      let slot = match @mips.delay_slot(insn.name()) {
        Some(n) => n.to_uint64() * 4
        None => 0
      }
      insn.addr() + 4 + slot
    },
    care: default_care,
    pc_care: 0xFFFF_FFFF_FFFF_FFFF,
  }
}

///|
test "mips32: arithmetic, logic, shifts, bit fields, multiply and divide" {
  check(mips(32, BigEndian), mips32_alu_cases)
}

///|
test "mips32: loads and stores" {
  check(mips(32, BigEndian), mips32_mem_cases)
}

///|
test "mips32: branches and jumps" {
  check(mips(32, BigEndian), mips32_branch_cases)
}

///|
test "mips32el: loads and stores" {
  check(mips(32, LittleEndian), mips32el_mem_cases)
}

///|
test "mips64: arithmetic, logic, shifts, bit fields, multiply and divide" {
  check(mips(64, BigEndian), mips64_alu_cases)
}

///|
test "mips64: loads and stores" {
  check(mips(64, BigEndian), mips64_mem_cases)
}

///|
test "mips64: branches and jumps" {
  check(mips(64, BigEndian), mips64_branch_cases)
}

///|
test "mips64el: loads and stores" {
  check(mips(64, LittleEndian), mips64el_mem_cases)
}

///|
test "mips32r6: Release 6 arithmetic, compact branches and links" {
  check(mips(32, BigEndian, r6=true), mips32r6_cases)
}

///|
test "mips64r6: Release 6 arithmetic, compact branches and links" {
  check(mips(64, BigEndian, r6=true), mips64r6_cases)
}
