// Port of BAP `plugins/mips/mips_store.ml`. SDL/SDR/SWL/SWR (and EVA
// variants) are TODO upstream as well. Store-conditional forms are
// modeled as plain stores, like upstream; in the operand layout of the
// LLVM decoder (`[rt, rt, base, offset]`, where the first `rt` is the
// success flag output) the flag is also set, since a single-threaded
// store always succeeds.

///|
/// `store (base + off) rt width`; the stored value is truncated to `width`.
fn store_base_offset(width : Int) -> Semantics {
  cpu => {
    let rt = cpu.sreg(0)
    let base = cpu.sreg(1)
    let off = cpu.simm(2)
    [cpu.store(base + off, rt, width)]
  }
}

///|
/// Store conditional: `store_base_offset` over `[rt, base, offset]` (the
/// upstream layout), or over `[rt_out, rt, base, offset]` (the layout of
/// LLVM's `DecodeMem`), which also sets `rt_out` to one.
fn store_conditional(width : Int) -> Semantics {
  cpu => {
    if cpu.insn.ops.length() < 4 {
      return store_base_offset(width)(cpu)
    }
    let flag = cpu.ureg(0)
    let rt = cpu.sreg(1)
    let base = cpu.sreg(2)
    let off = cpu.simm(3)
    [cpu.store(base + off, rt, width), flag.assign(one)]
  }
}

///|
let store_semantics : ReadOnlyArray[(String, Semantics)] = [
  ("SB", store_base_offset(byte)),
  ("SBE", store_base_offset(byte)),
  ("SC", store_conditional(word)),
  ("SCD", store_conditional(doubleword)),
  ("SCE", store_conditional(word)),
  ("SCX", store_conditional(word)),
  ("SCDX", store_conditional(doubleword)),
  ("SCXE", store_conditional(word)),
  ("SD", store_base_offset(doubleword)),
  ("SH", store_base_offset(halfword)),
  ("SHE", store_base_offset(halfword)),
  ("SW", store_base_offset(word)),
  ("SWE", store_base_offset(word)),
]
