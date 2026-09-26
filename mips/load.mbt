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
    [rt.assign(cpu.load(base + off, width))]
  }
}

///|
/// PC-relative load: `rt := load (cia + (off << shift)) width`.
fn load_pc_relative(rt_sign : Sign, shift : Int, width : Int) -> Semantics {
  cpu => {
    let rt = cpu.reg(0, rt_sign)
    let off = cpu.simm(1)
    [rt.assign(cpu.load(cpu.cia + off.lsl(uconst(byte, shift)), width))]
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
  ("LDPC", load_pc_relative(Signed, 3, doubleword)),
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
  ("LWPC", load_pc_relative(Signed, 2, word)),
  ("LWu", load_base_offset(Unsigned, word)),
  ("LWupc", load_pc_relative(Unsigned, 2, word)),
]
