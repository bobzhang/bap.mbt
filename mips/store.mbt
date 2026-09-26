// Port of BAP `plugins/mips/mips_store.ml`. SDL/SDR/SWL/SWR (and EVA
// variants) are TODO upstream as well. Store-conditional forms are
// modeled as plain stores (the success flag is not written), like
// upstream.

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
let store_semantics : ReadOnlyArray[(String, Semantics)] = [
  ("SB", store_base_offset(byte)),
  ("SBE", store_base_offset(byte)),
  ("SC", store_base_offset(word)),
  ("SCD", store_base_offset(doubleword)),
  ("SCE", store_base_offset(word)),
  ("SCX", store_base_offset(word)),
  ("SCDX", store_base_offset(doubleword)),
  ("SCXE", store_base_offset(word)),
  ("SD", store_base_offset(doubleword)),
  ("SH", store_base_offset(halfword)),
  ("SHE", store_base_offset(halfword)),
  ("SW", store_base_offset(word)),
  ("SWE", store_base_offset(word)),
]
