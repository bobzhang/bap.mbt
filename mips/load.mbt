// Port of BAP `plugins/mips/mips_load.ml`. The signedness of the
// destination register selects sign- or zero-extension of the loaded
// value. LDL/LDR/LWL/LWR (and EVA variants) are TODO upstream as well.

///|
/// `rt := load (base + off) width` with the given destination signedness.
fn load_base_offset(rt_sign : Sign, width : Int) -> Semantics {
  cpu => {
    let rt = cpu.reg(0, rt_sign)
    let base = cpu.sreg(1)
    let off = cpu.simm(2)
    [rt.assign(apply_sign(rt_sign, cpu.load(base + off, width)))]
  }
}

///|
/// PC-relative load: `rt := load (base + off) width`, where LLVM's `off`
/// operand is already scaled and `base` is the address of the instruction,
/// aligned to `width` bytes for `LDPC`. Deliberate deviation from
/// upstream, which scales the offset again (and does not align `LDPC`).
fn load_pc_relative(rt_sign : Sign, width : Int) -> Semantics {
  cpu => {
    let rt = cpu.reg(0, rt_sign)
    let off = cpu.simm(1)
    let base = if width == doubleword {
      let mask = Exp::of_word(make_word(cpu.arch.addr_bitwidth(), -8L))
      (cpu.cia & mask).signed()
    } else {
      cpu.cia
    }
    [rt.assign(apply_sign(rt_sign, cpu.load(base + off, width)))]
  }
}

///|
let load_semantics : ReadOnlyArray[(String, Semantics)] = [
  ("LB", load_base_offset(Signed, byte)),
  // LBE: upstream uses an unsigned destination ("Not sure what to do here")
  ("LBE", load_base_offset(Unsigned, byte)),
  ("LBu", load_base_offset(Unsigned, byte)),
  ("LBue", load_base_offset(Unsigned, byte)),
  ("LD", load_base_offset(Signed, doubleword)),
  ("LDPC", load_pc_relative(Signed, doubleword)),
  ("LH", load_base_offset(Signed, halfword)),
  ("LHE", load_base_offset(Signed, halfword)),
  ("LHu", load_base_offset(Unsigned, halfword)),
  ("LHue", load_base_offset(Unsigned, halfword)),
  ("LL", load_base_offset(Signed, word)),
  ("LLD", load_base_offset(Signed, doubleword)),
  ("LLE", load_base_offset(Signed, word)),
  ("LLX", load_base_offset(Signed, word)),
  ("LLDX", load_base_offset(Signed, doubleword)),
  ("LLXE", load_base_offset(Signed, word)),
  ("LW", load_base_offset(Signed, word)),
  ("LWE", load_base_offset(Signed, word)),
  ("LWPC", load_pc_relative(Signed, word)),
  ("LWu", load_base_offset(Unsigned, word)),
  ("LWupc", load_pc_relative(Unsigned, word)),
]
