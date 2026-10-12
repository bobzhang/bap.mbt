// PowerPC register file of the tables: `R0`..`R31`, `CR` (the 32 condition
// register bits, `CR0LT` most significant), `XER` (only the `SO`, `OV`,
// `CA`, `OV32` and `CA32` bits the lifter models), `LR`, `CTR`, `TAR`.

///|
let ppc_cr_suffixes : Array[String] = ["LT", "GT", "EQ", "UN"]

///|
/// `(flag, bit)` of the modelled XER bits.
let ppc_xer_bits : Array[(String, Int32)] = [
  ("SO", 31),
  ("OV", 30),
  ("CA", 29),
  ("OV32", 19),
  ("CA32", 18),
]

///|
fn ppc(bits : Int32, endian : @bitvec.Endian) -> Isa {
  let mode : @powerpc.AddrSize = if bits == 64 { R64 } else { R32 }
  let target = match (bits, endian) {
    (64, LittleEndian) => @core_theory.Target::powerpc64le()
    (64, _) => @core_theory.Target::powerpc64()
    _ => @core_theory.Target::powerpc()
  }
  let regs = Array::makei(32, i => "R\{i}") + ["CR", "XER", "LR", "CTR", "TAR"]
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
    decode: (bytes, addr) => @powerpc.decode(bytes, addr, mode~, endian~),
    regs,
    write: (state, name, v) => {
      match name {
        "CR" => {
          let mut state = state
          for i in 0..<32 {
            state = state.set(
              "CR\{i / 4}\{ppc_cr_suffixes[i % 4]}",
              word(1, v >> (31 - i)),
            )
          }
          state
        }
        "XER" => {
          let mut state = state
          for flag in ppc_xer_bits {
            state = state.set(flag.0, word(1, v >> flag.1))
          }
          state
        }
        _ => state.set(name, word(bits, v))
      }
    },
    read: (state, name) => {
      match name {
        "CR" => {
          let mut v = 0UL
          for i in 0..<32 {
            v = v |
              (
                read_word(state, "CR\{i / 4}\{ppc_cr_suffixes[i % 4]}") <<
                (31 - i)
              )
          }
          v
        }
        "XER" => {
          let mut v = 0UL
          for flag in ppc_xer_bits {
            v = v | (read_word(state, flag.0) << flag.1)
          }
          v
        }
        _ => read_word(state, name)
      }
    },
    fallthrough: insn => insn.addr() + 4,
    care: (name, skip) => {
      if name == "CR" && skip.contains("CR0") {
        0x1FFF_FFFFUL
      } else {
        default_care(name, skip)
      }
    },
    pc_care: 0xFFFF_FFFF_FFFF_FFFF,
  }
}

///|
test "ppc32: arithmetic" {
  check(ppc(32, BigEndian), ppc32_arith_cases)
}

///|
test "ppc32: logical, shifts, rotations, compares and moves" {
  check(ppc(32, BigEndian), ppc32_logic_cases)
}

///|
test "ppc32: loads and stores" {
  check(ppc(32, BigEndian), ppc32_mem_cases)
}

///|
test "ppc32: branches" {
  check(ppc(32, BigEndian), ppc32_branch_cases)
}

///|
test "ppc64: arithmetic" {
  check(ppc(64, BigEndian), ppc64_arith_cases)
}

///|
test "ppc64: logical, shifts, rotations, compares and moves" {
  check(ppc(64, BigEndian), ppc64_logic_cases)
}

///|
test "ppc64: loads and stores" {
  check(ppc(64, BigEndian), ppc64_mem_cases)
}

///|
test "ppc64: branches" {
  check(ppc(64, BigEndian), ppc64_branch_cases)
}

///|
test "ppc64le: loads and stores" {
  check(ppc(64, LittleEndian), ppc64le_mem_cases)
}

///|
test "powerpc.lisp: NOP" {
  let lisp = @mc.Registry::new()
  @primus_lisp.register_semantics_providers(registry=lisp)
  check(ppc(32, BigEndian), ppc32_logic_cases, registry=lisp, only="nop")
}
