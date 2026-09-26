// AArch64 register file of the tables: `X0`..`X30`, `SP` and `NZCV` (the
// `N`, `Z`, `C`, `V` flags, `N` most significant). Instructions are lifted
// by the AArch64 Primus Lisp semantics (`aarch64*.lisp`), the only AArch64
// lifter.

///|
fn a64() -> Isa {
  let regs = Array::makei(31, i => "X\{i}") + ["SP", "NZCV"]
  {
    target: @core_theory.Target::aarch64(),
    addr_width: 64,
    pc: 0x10000,
    encode: code => {
      Bytes::makei(code.length() / 2, i => {
        let k = i / 4
        let v = parse_hex(code.view(start_offset=k * 8, end_offset=(k + 1) * 8))
        (v >> (8 * (i % 4))).to_byte()
      })
    },
    decode: (bytes, addr) => {
      let ctx = @mc.Context::create(@core_theory.Target::aarch64())
      match @aarch64.a64_decoder().decode(ctx, bytes[:], addr) {
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
        _ => state.set(name, word(64, v))
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
        _ => read_word(state, name)
      }
    },
    fallthrough: insn => insn.addr() + insn.size().to_uint64(),
    care: default_care,
    pc_care: 0xFFFF_FFFF_FFFF_FFFF,
  }
}

///|
/// The AArch64 Lisp semantics.
let a64_providers : @mc.Registry = {
  let r = @mc.Registry::new()
  @primus_lisp.register_semantics_providers(registry=r)
  r
}

///|
test "a64: data processing" {
  check(a64(), a64_dp_cases, registry=a64_providers)
}

///|
test "a64: loads, stores and atomics" {
  check(a64(), a64_mem_cases, registry=a64_providers)
}

///|
test "a64: branches" {
  check(a64(), a64_branch_cases, registry=a64_providers)
}

///|
/// Unicorn runs with pointer authentication disabled, as the semantics
/// model it (the PAC and AUT instructions are identities).
test "a64: pointer authentication" {
  check(a64(), a64_pauth_cases, registry=a64_providers)
}
