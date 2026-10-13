// Port of BAP `lib/x86_cpu/x86_env.ml`: the variables of the x86 and
// x86-64 CPU models used by the lifters.

///|
fn reg_var(name : String, width : Int32) -> @types.Var {
  @types.Var::new(name~, typ=Imm(width))
}

///|
/// Carry flag.
let cf : @types.Var = reg_var("CF", 1)

///|
/// Parity flag.
let pf : @types.Var = reg_var("PF", 1)

///|
/// Auxiliary carry flag.
let af : @types.Var = reg_var("AF", 1)

///|
/// Zero flag.
let zf : @types.Var = reg_var("ZF", 1)

///|
/// Sign flag.
let sf : @types.Var = reg_var("SF", 1)

///|
/// Overflow flag.
let of_ : @types.Var = reg_var("OF", 1)

///|
/// Direction flag.
let df : @types.Var = reg_var("DF", 1)

///|
let seg_cs : @types.Var = reg_var("CS", 16)

///|
let seg_ds : @types.Var = reg_var("DS", 16)

///|
let seg_es : @types.Var = reg_var("ES", 16)

///|
let seg_fs : @types.Var = reg_var("FS", 16)

///|
let seg_gs : @types.Var = reg_var("GS", 16)

///|
let seg_ss : @types.Var = reg_var("SS", 16)

///|
let fpu_ctrl : @types.Var = reg_var("FPU_CONTROL", 16)

///|
let mxcsr : @types.Var = reg_var("MXCSR", 32)

///|
let ymms : ReadOnlyArray[@types.Var] = [
  for i in 0..<16 => reg_var("YMM\{i}", 256)
]

///|
let r64_extra : ReadOnlyArray[@types.Var] = [
  for i in 0..<8 => reg_var("R\{i + 8}", 64)
]

///|
/// The mode-dependent variables of the CPU model (upstream
/// `X86_env.ModeVars`, modules `R32` and `R64`).
priv struct ModeVars {
  rbp : @types.Var
  rsp : @types.Var
  rsi : @types.Var
  rdi : @types.Var
  rip : @types.Var
  rax : @types.Var
  rbx : @types.Var
  rcx : @types.Var
  rdx : @types.Var
  gdt : @types.Var
  ldt : @types.Var
  fs_base : @types.Var
  gs_base : @types.Var
  mem : @types.Var
  /// R8-R15 (empty in 32-bit mode)
  r : ReadOnlyArray[@types.Var]
  /// YMM0-YMM7 in 32-bit mode, YMM0-YMM15 in 64-bit mode
  ymms : ReadOnlyArray[@types.Var]
}

///|
let r32_vars : ModeVars = {
  rbp: reg_var("EBP", 32),
  rsp: reg_var("ESP", 32),
  rsi: reg_var("ESI", 32),
  rdi: reg_var("EDI", 32),
  rip: reg_var("EIP", 32),
  rax: reg_var("EAX", 32),
  rbx: reg_var("EBX", 32),
  rcx: reg_var("ECX", 32),
  rdx: reg_var("EDX", 32),
  gdt: reg_var("GDTR", 32),
  ldt: reg_var("LDTR", 32),
  fs_base: reg_var("FS_BASE", 32),
  gs_base: reg_var("GS_BASE", 32),
  mem: @types.Var::new(name="mem", typ=Mem(addr_width=32, value_width=8)),
  r: [],
  ymms: [
    for i in 0..<8 => ymms[i]
  ],
}

///|
let r64_vars : ModeVars = {
  rbp: reg_var("RBP", 64),
  rsp: reg_var("RSP", 64),
  rsi: reg_var("RSI", 64),
  rdi: reg_var("RDI", 64),
  rip: reg_var("RIP", 64),
  rax: reg_var("RAX", 64),
  rbx: reg_var("RBX", 64),
  rcx: reg_var("RCX", 64),
  rdx: reg_var("RDX", 64),
  gdt: reg_var("GDTR", 64),
  ldt: reg_var("LDTR", 64),
  fs_base: reg_var("FS_BASE", 64),
  gs_base: reg_var("GS_BASE", 64),
  mem: @types.Var::new(name="mem", typ=Mem(addr_width=64, value_width=8)),
  r: r64_extra,
  ymms,
}

///|
/// Upstream `vars_of_mode`.
fn vars_of_mode(mode : Mode) -> ModeVars {
  match mode {
    X86 => r32_vars
    X8664 => r64_vars
  }
}

///|
/// Segment base used for FS/GS overrides (upstream `seg_fs`/`seg_gs`; the
/// other segments have a zero base, `None`).
fn ModeVars::seg_base(self : ModeVars, prefix : Int32) -> @types.Var? {
  match prefix {
    0x64 => Some(self.fs_base)
    0x65 => Some(self.gs_base)
    _ => None
  }
}

///|
/// The general purpose registers of `mode` in encoding order (RAX, RCX,
/// RDX, RBX, RSP, RBP, RSI, RDI, then R8-R15 in 64-bit mode): the physical
/// variables the lifters read and write.
pub fn gprs(mode : Mode) -> Array[@types.Var] {
  let r = vars_of_mode(mode)
  let regs = [r.rax, r.rcx, r.rdx, r.rbx, r.rsp, r.rbp, r.rsi, r.rdi]
  regs.push_iter(r.r.iter())
  regs
}

///|
/// The program counter of `mode` (EIP or RIP; the lifters use constant
/// addresses and never read it).
pub fn program_counter(mode : Mode) -> @types.Var {
  vars_of_mode(mode).rip
}

///|
/// The status flags modeled by the lifters: CF, PF, AF, ZF, SF, OF and DF.
pub fn flags() -> Array[@types.Var] {
  [cf, pf, af, zf, sf, of_, df]
}

///|
/// The memory variable of `mode` (`mem`, with 32- or 64-bit addresses).
pub fn mem_var(mode : Mode) -> @types.Var {
  vars_of_mode(mode).mem
}

///|
/// The vector registers of `mode` (YMM0-YMM7 in 32-bit mode, YMM0-YMM15 in
/// 64-bit mode, 256 bits wide; XMM registers are their low halves).
pub fn vector_registers(mode : Mode) -> Array[@types.Var] {
  vars_of_mode(mode).ymms.iter().collect()
}
