// System instructions: hints, barriers, `PSTATE` moves, `SYS`/`SYSL` with
// their aliases and the system register moves.

///|
/// The aliases of `SYS` (generated from LLVM 22 with the upstream target
/// features): `(op1:CRn:CRm:op2, mnemonic, needs a register)`. An mnem
/// that takes no register is only used when `Rt` is `XZR`.
let sys_aliases : Array[(Int32, String, Bool)] = [
  (904, "ic ialluis", false),
  (936, "ic iallu", false),
  (945, "dc ivac", true),
  (946, "dc isw", true),
  (960, "at s1e1r", true),
  (961, "at s1e1w", true),
  (962, "at s1e0r", true),
  (963, "at s1e0w", true),
  (968, "at s1e1rp", true),
  (969, "at s1e1wp", true),
  (970, "at s1e1a", true),
  (978, "dc csw", true),
  (1010, "dc cisw", true),
  (1048, "tlbi vmalle1is", false),
  (1049, "tlbi vae1is", true),
  (1050, "tlbi aside1is", true),
  (1051, "tlbi vaae1is", true),
  (1053, "tlbi vale1is", true),
  (1055, "tlbi vaale1is", true),
  (1080, "tlbi vmalle1", false),
  (1081, "tlbi vae1", true),
  (1082, "tlbi aside1", true),
  (1083, "tlbi vaae1", true),
  (1085, "tlbi vale1", true),
  (1087, "tlbi vaale1", true),
  (7073, "dc zva", true),
  (7081, "ic ivau", true),
  (7121, "dc cvac", true),
  (7129, "dc cvau", true),
  (7137, "dc cvap", true),
  (7153, "dc civac", true),
  (9152, "at s1e2r", true),
  (9153, "at s1e2w", true),
  (9156, "at s12e1r", true),
  (9157, "at s12e1w", true),
  (9158, "at s12e0r", true),
  (9159, "at s12e0w", true),
  (9162, "at s1e2a", true),
  (9217, "tlbi ipas2e1is", true),
  (9221, "tlbi ipas2le1is", true),
  (9240, "tlbi alle2is", false),
  (9241, "tlbi vae2is", true),
  (9244, "tlbi alle1is", false),
  (9245, "tlbi vale2is", true),
  (9246, "tlbi vmalls12e1is", false),
  (9249, "tlbi ipas2e1", true),
  (9253, "tlbi ipas2le1", true),
  (9272, "tlbi alle2", false),
  (9273, "tlbi vae2", true),
  (9276, "tlbi alle1", false),
  (9277, "tlbi vale2", true),
  (9278, "tlbi vmalls12e1", false),
  (13248, "at s1e3r", true),
  (13249, "at s1e3w", true),
  (13258, "at s1e3a", true),
  (13336, "tlbi alle3is", false),
  (13337, "tlbi vae3is", true),
  (13341, "tlbi vale3is", true),
  (13368, "tlbi alle3", false),
  (13369, "tlbi vae3", true),
  (13373, "tlbi vale3", true),
]

///|
let sys_alias_map : Map[Int32, (String, Bool)] = {
  let map : Map[Int32, (String, Bool)] = Map([])
  for entry in sys_aliases {
    map[entry.0] = (entry.1, entry.2)
  }
  map
}

///|
/// System register names by encoding: the `MRS` name and the `MSR` name.
let sysreg_map : Map[Int32, (String?, String?)] = {
  let map : Map[Int32, (String?, String?)] = Map([])
  for entry in sysreg_table {
    let (key, name, access) = entry
    let (r, w) = map.get(key).unwrap_or((None, None))
    let r = if (access & 1) != 0 { Some(name) } else { r }
    let w = if (access & 2) != 0 { Some(name) } else { w }
    map[key] = (r, w)
  }
  map
}

///|
/// The assembly name of the system register `op0:op1:CRn:CRm:op2` as read
/// (`MRS`) or written (`MSR`).
fn sysreg_asm(reg : Int32, read : Bool) -> String {
  let named = match sysreg_map.get(reg) {
    Some((r, w)) => if read { r } else { w }
    None => None
  }
  match named {
    Some(name) => name
    None =>
      "S\{(reg >> 14) & 3}_\{(reg >> 11) & 7}_C\{(reg >> 7) & 15}_C\{(reg >> 3) & 15}_\{reg & 7}"
  }
}

///|
/// The name of a barrier option (`dmb`/`dsb`).
fn barrier_option(crm : Int32) -> String {
  match crm {
    1 => "oshld"
    2 => "oshst"
    3 => "osh"
    5 => "nshld"
    6 => "nshst"
    7 => "nsh"
    9 => "ishld"
    10 => "ishst"
    11 => "ish"
    13 => "ld"
    14 => "st"
    15 => "sy"
    _ => "#\{crm}"
  }
}

///|
/// The instructions of the hint space (`HINT #imm` and its named forms).
fn a64_hint(v : Int32) -> A64Insn? {
  let named = match v {
    0 => Some("NOP")
    7 => Some("XPACLRI")
    8 => Some("PACIA1716")
    10 => Some("PACIB1716")
    12 => Some("AUTIA1716")
    14 => Some("AUTIB1716")
    24 => Some("PACIAZ")
    25 => Some("PACIASP")
    26 => Some("PACIBZ")
    27 => Some("PACIBSP")
    28 => Some("AUTIAZ")
    29 => Some("AUTIASP")
    30 => Some("AUTIBZ")
    31 => Some("AUTIBSP")
    39 => Some("PACM")
    40 => Some("CHKFEAT")
    _ => None
  }
  match named {
    Some(name) =>
      a64(name, [], if v >= 39 { "hint #\{v}" } else { name.to_lower() })
    None => {
      let text = match v {
        1 => "yield"
        2 => "wfe"
        3 => "wfi"
        4 => "sev"
        5 => "sevl"
        6 => "dgh"
        16 => "esb"
        20 => "csdb"
        _ => "hint #\{v}"
      }
      a64("HINT", [imm(v)], text)
    }
  }
}

///|
/// The `MSR (immediate)` forms writing `PSTATE` fields, `None` when the
/// encoding is an `MSR (register)`.
fn a64_pstate(op1 : Int32, crm : Int32, op2 : Int32) -> A64Insn? {
  let field = match (op1, op2) {
    (0, 3) => Some("UAO")
    (0, 4) => Some("PAN")
    (0, 5) => Some("SPSel")
    (3, 6) => Some("DAIFSet")
    (3, 7) => Some("DAIFClr")
    _ => None
  }
  if field is Some(field) {
    return a64(
      "MSRpstateImm4",
      [imm((op1 << 3) | op2), imm(crm)],
      "msr \{field}, #\{crm}",
    )
  }
  if op1 == 1 && op2 == 0 && crm >> 1 == 1 {
    return a64(
      "MSRpstateImm1",
      [imm((crm >> 1 << 6) | (op1 << 3) | op2), imm(crm & 1)],
      "msr PM, #\{crm & 1}",
    )
  }
  if op1 == 3 && op2 == 3 && crm >> 1 >= 1 && crm >> 1 <= 3 {
    let svcr = crm >> 1
    let op = if (crm & 1) == 1 { "smstart" } else { "smstop" }
    let which = match svcr {
      1 => " sm"
      2 => " za"
      _ => ""
    }
    return a64("MSRpstatesvcrImm1", [imm(svcr), imm(crm & 1)], op + which)
  }
  None
}

///|
/// The system instruction space (`0xD5000000`-`0xD53FFFFF`).
fn a64_system(w : UInt32) -> A64Insn? {
  let l = bit(w, 21)
  let op0 = fld(w, 19, 2)
  let op1 = fld(w, 16, 3)
  let crn = fld(w, 12, 4)
  let crm = fld(w, 8, 4)
  let op2 = fld(w, 5, 3)
  let rt = fld(w, 0, 5)
  let t = reg_asm(true, rt)
  if !l && op0 == 0 && rt == 31 {
    let special = match crn {
      2 if op1 == 3 => a64_hint((crm << 3) | op2)
      3 if op1 == 3 =>
        match op2 {
          2 =>
            a64(
              "CLREX",
              [imm(crm)],
              if crm == 15 {
                "clrex"
              } else {
                "clrex #\{crm}"
              },
            )
          4 => {
            let text = match crm {
              0 => "ssbb"
              4 => "pssbb"
              _ => "dsb \{barrier_option(crm)}"
            }
            a64("DSB", [imm(crm)], text)
          }
          5 => a64("DMB", [imm(crm)], "dmb \{barrier_option(crm)}")
          6 =>
            a64(
              "ISB",
              [imm(crm)],
              if crm == 15 {
                "isb"
              } else {
                "isb #\{crm}"
              },
            )
          _ => None
        }
      // FlagM (not enabled in upstream's LLVM features)
      4 if op1 == 0 && crm == 0 && op2 == 0 => a64("CFINV", [], "cfinv")
      4 => a64_pstate(op1, crm, op2)
      _ => None
    }
    if special is Some(_) {
      return special
    }
  }
  let reg = fld(w, 5, 16)
  match (l, op0) {
    (false, 1) => {
      if op1 == 6 && crn == 7 && crm == 0 && op2 == 0 {
        return a64("APAS", [mc_x(rt)], "apas \{t}")
      }
      let key = fld(w, 5, 14)
      let generic = "sys #\{op1}, c\{crn}, c\{crm}, #\{op2}"
      let text = match sys_alias_map.get(key) {
        Some((mnem, true)) => "\{mnem}, \{t}"
        Some((mnem, false)) if rt == 31 => mnem
        _ => if rt == 31 { generic } else { "\{generic}, \{t}" }
      }
      a64("SYSxt", [imm(op1), imm(crn), imm(crm), imm(op2), mc_x(rt)], text)
    }
    (true, 1) =>
      a64(
        "SYSLxt",
        [mc_x(rt), imm(op1), imm(crn), imm(crm), imm(op2)],
        "sysl \{t}, #\{op1}, c\{crn}, c\{crm}, #\{op2}",
      )
    (false, _) =>
      a64("MSR", [imm(reg), mc_x(rt)], "msr \{sysreg_asm(reg, false)}, \{t}")
    (true, _) =>
      a64("MRS", [mc_x(rt), imm(reg)], "mrs \{t}, \{sysreg_asm(reg, true)}")
  }
}
