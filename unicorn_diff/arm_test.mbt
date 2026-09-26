// ARM register file of the tables: `R0`..`R12`, `SP`, `LR`, `NZCV` (the
// `N`, `Z`, `C`, `V` flags, `N` most significant) and `Q`. A32
// instructions are lifted by the `arm` lifter, Thumb ones by the `thumb`
// (16-bit `t*` opcodes) and `arm` (`t2*` opcodes) lifters, both with the
// Primus Lisp semantics as fallback. The Thumb encodings are written as
// sequences of halfwords (four hexadecimal digits each), so that a case
// may start with an IT instruction.

///|
let arm_flags : Array[(String, Int)] = [
  ("NF", 3),
  ("ZF", 2),
  ("CF", 1),
  ("VF", 0),
]

///|
fn arm(thumb : Bool) -> Isa {
  let regs = Array::makei(13, i => "R\{i}") + ["SP", "LR", "NZCV", "Q"]
  let it = @thumb.ItBlock::new()
  {
    target: if thumb {
      @core_theory.Target::thumb()
    } else {
      @core_theory.Target::arm()
    },
    addr_width: 32,
    pc: 0x10000,
    encode: code => {
      // four hexadecimal digits per Thumb halfword, eight per A32 word
      let unit = if thumb { 2 } else { 4 }
      let digits = 2 * unit
      Bytes::makei(code.length() / 2, i => {
        let k = i / unit
        let v = parse_hex(
          code.view(start_offset=k * digits, end_offset=(k + 1) * digits),
        )
        (v >> (8 * (i % unit))).to_byte()
      })
    },
    decode: (bytes, addr) => {
      let decoded = if thumb {
        @thumb.decode_t32(bytes[:], addr~, it~)
      } else {
        @arm.decode_a32(bytes[:], addr~)
      }
      match decoded {
        Decoded(insn) => Some(insn)
        _ => None
      }
    },
    regs,
    write: (state, name, v) => {
      match name {
        "NZCV" => {
          let mut state = state
          for flag in arm_flags {
            state = state.set(flag.0, word(1, v >> flag.1))
          }
          state
        }
        "Q" => state.set("QF", word(1, v))
        _ => state.set(name, word(32, v))
      }
    },
    read: (state, name) => {
      match name {
        "NZCV" => {
          let mut v = 0UL
          for flag in arm_flags {
            v = v | (read_word(state, flag.0) << flag.1)
          }
          v
        }
        "Q" => read_word(state, "QF")
        _ => read_word(state, name)
      }
    },
    fallthrough: insn => insn.addr() + insn.size().to_uint64(),
    care: default_care,
    pc_care: 0xFFFF_FFFE,
  }
}

///|
/// The ARM and Thumb lifters, with the Lisp semantics as fallback.
let arm_providers : @mc.Registry = {
  let r = @mc.Registry::new()
  @thumb.register(registry=r)
  @arm.register(registry=r)
  @primus_lisp.register_semantics_providers(registry=r)
  r
}

///|
test "a32: data processing, bit field, extend and multiply instructions" {
  check(arm(false), a32_dp_cases, registry=arm_providers)
}

///|
test "a32: loads and stores" {
  check(arm(false), a32_mem_cases, registry=arm_providers)
}

///|
test "a32: branches and hints" {
  check(arm(false), a32_branch_cases, registry=arm_providers)
}
