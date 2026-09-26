// Port of BAP `plugins/x86/x86_tools*.ml`, `x86_operands.ml` and
// `x86_prefix.ml`: the register, memory, flag and prefix models used by the
// per-opcode lifters that work on LLVM MC operands.

///|
/// Register classes of `X86_asm.reg`.
priv enum RegClass {
  R8L
  R8H
  R16
  R32
  R64
  R128
  R256
  Ip
  Segment
  SegmentBase
} derive(Eq)

///|
/// An `X86_asm.reg` register of the modern lifters.
priv struct Reg {
  name : String
  cls : RegClass
  /// the index of the underlying general purpose (0-15) or vector (0-31)
  /// register, `-1` for the others
  index : Int
}

///|
let gpr_names : ReadOnlyArray[(String, String, String, String, String)] = [
  // (low byte, high byte, 16-bit, 32-bit, 64-bit) in encoding order
  ("AL", "AH", "AX", "EAX", "RAX"),
  ("CL", "CH", "CX", "ECX", "RCX"),
  ("DL", "DH", "DX", "EDX", "RDX"),
  ("BL", "BH", "BX", "EBX", "RBX"),
  ("SPL", "", "SP", "ESP", "RSP"),
  ("BPL", "", "BP", "EBP", "RBP"),
  ("SIL", "", "SI", "ESI", "RSI"),
  ("DIL", "", "DI", "EDI", "RDI"),
]

///|
/// Upstream `X86_asm.Reg.decode`: the register of an MC register name,
/// `None` for the empty register (`Nil`, also `NoRegister` or the empty
/// name), failing on unknown names.
fn decode_reg(name : String) -> Reg? raise @mc.LiftError {
  match name {
    "" | "Nil" | "NoRegister" => return None
    "IP" | "EIP" | "RIP" => return Some({ name, cls: Ip, index: -1, })
    "CS" | "DS" | "ES" | "FS" | "GS" | "SS" =>
      return Some({ name, cls: Segment, index: -1, })
    "FS_BASE" | "GS_BASE" => return Some({ name, cls: SegmentBase, index: -1, })
    _ => ()
  }
  for i, names in gpr_names {
    let (l, h, w, d, q) = names
    if name == l {
      return Some({ name, cls: R8L, index: i, })
    } else if name == h && h != "" {
      return Some({ name, cls: R8H, index: i, })
    } else if name == w {
      return Some({ name, cls: R16, index: i, })
    } else if name == d {
      return Some({ name, cls: R32, index: i, })
    } else if name == q {
      return Some({ name, cls: R64, index: i, })
    }
  }
  for i in 8..<16 {
    if name == "R\{i}B" {
      return Some({ name, cls: R8L, index: i, })
    } else if name == "R\{i}W" {
      return Some({ name, cls: R16, index: i, })
    } else if name == "R\{i}D" {
      return Some({ name, cls: R32, index: i, })
    } else if name == "R\{i}" {
      return Some({ name, cls: R64, index: i, })
    }
  }
  for i in 0..<32 {
    if name == "XMM\{i}" {
      return Some({ name, cls: R128, index: i, })
    } else if name == "YMM\{i}" {
      return Some({ name, cls: R256, index: i, })
    }
  }
  raise Failure("unknown register \{name}")
}

///|
/// The context of the per-opcode lifters: the mode (upstream `IA32` or
/// `AMD64` tools) and the instruction.
priv struct Tools {
  mode : Mode
  insn : @mc.Insn
}

///|
fn Tools::fail(self : Tools, msg : String) -> @mc.LiftError {
  Failure("\{self.insn.name}: \{msg}")
}

///|
/// The mode size in bits (upstream `RR.size`).
fn Tools::size(self : Tools) -> Int {
  self.mode.width()
}

///|
/// Upstream `CPU.avaliable`: IA32 only has the 32-bit subset of the
/// registers.
fn Tools::available(self : Tools, r : Reg) -> Bool {
  match self.mode {
    X8664 => true
    X86 =>
      match r.cls {
        R8L | R8H | R16 | R32 => r.index < 4 || (r.cls != R8L && r.index < 8)
        Segment | SegmentBase => true
        _ => false
      }
  }
}

///|
/// Upstream `RR.of_asm`/`RR.of_mc`.
fn Tools::of_name(self : Tools, name : String) -> Reg? raise @mc.LiftError {
  match decode_reg(name) {
    Some(r) if self.available(r) => Some(r)
    _ => None
  }
}

///|
/// Upstream `RR.of_mc_exn`.
fn Tools::reg(self : Tools, name : String) -> Reg raise @mc.LiftError {
  match self.of_name(name) {
    Some(r) => r
    None => raise self.fail("invalid register \{name}")
  }
}

///|
/// Upstream `RR.width`.
fn Tools::width(self : Tools, r : Reg) -> Int raise @mc.LiftError {
  match r.cls {
    R8L | R8H => 8
    R16 => 16
    R32 => 32
    R64 => 64
    R128 => 128
    R256 => 256
    SegmentBase => self.size()
    Segment => 16
    Ip => raise self.fail("no width for \{r.name}")
  }
}

///|
/// Upstream `RR.var`.
fn Tools::reg_var(self : Tools, r : Reg) -> @types.Var raise @mc.LiftError {
  let vars = vars_of_mode(self.mode)
  match r.cls {
    R8L | R8H | R16 | R32 | R64 =>
      bits2genreg(self.mode, r.index) catch {
        _ => raise self.fail("invalid reg variable \{r.name}")
      }
    R128 | R256 =>
      match vars.ymms.get(r.index) {
        Some(v) => v
        None => raise self.fail("invalid reg variable \{r.name}")
      }
    SegmentBase => if r.name == "FS_BASE" { vars.fs_base } else { vars.gs_base }
    Segment =>
      match r.name {
        "CS" => seg_cs
        "DS" => seg_ds
        "ES" => seg_es
        "FS" => seg_fs
        "GS" => seg_gs
        _ => seg_ss
      }
    Ip => raise self.fail("invalid reg variable \{r.name}")
  }
}

///|
/// Upstream `RR.get`.
fn Tools::get(self : Tools, r : Reg) -> @types.Exp raise @mc.LiftError {
  let v = ev(self.reg_var(r))
  match (r.cls, self.mode) {
    (R8H, _) => e_extract(15, 8, v)
    (R8L | R16 | R128, _) | (R32, X8664) => e_low(self.width(r), v)
    _ => v
  }
}

///|
/// Upstream `RR.set`.
fn Tools::set(
  self : Tools,
  r : Reg,
  e : @types.Exp,
) -> @types.Stmt raise @mc.LiftError {
  let lhs = self.reg_var(r)
  let v = ev(lhs)
  let bitsize = self.size()
  let rhs = match (r.cls, self.mode) {
    (R8H, _) => e_concat(e_concat(e_high(bitsize - 16, v), e), e_low(8, v))
    (R8L | R16, _) => e_concat(e_high(bitsize - self.width(r), v), e)
    // upstream uses the mode size here as well, which is ill-typed for the
    // 256-bit vector registers; the preserved bits are the upper half
    (R128, _) => e_concat(e_high(128, v), e)
    (R32, X8664) => e_unsigned(bitsize, e)
    (R64, X86) => raise self.fail("invalid reg \{r.name}")
    _ => e
  }
  assign(lhs, rhs)
}

///|
/// Upstream `FR.after_sub`: the flags after `diff = op1 - op2`.
fn after_sub(
  diff : @types.Exp,
  size : Int,
  op1 : @types.Exp,
  op2 : @types.Exp,
) -> Array[@types.Stmt] {
  [
    assign(cf, e_lt(op1, op2)),
    assign(of_, e_high(1, e_and(e_xor(op1, op2), e_xor(op1, diff)))),
    assign(af, e_extract(4, 4, e_xor(e_xor(diff, op1), op2))),
    assign(pf, parity(size, diff)),
    assign(sf, e_high(1, diff)),
    assign(zf, e_eq(int_exp(0, size), diff)),
  ]
}

///|
/// Upstream `FR.parity`.
fn parity(width : Int, result : @types.Exp) -> @types.Exp {
  let i = (value : Int) => int_exp(value, width)
  let v2 = new_tmp(width)
  e_not(
    e_low(
      1,
      Let(
        v2,
        e_xor(e_lsr(result, i(4)), result),
        Let(
          v2,
          e_xor(e_lsr(ev(v2), i(2)), ev(v2)),
          e_xor(e_lsr(ev(v2), i(1)), ev(v2)),
        ),
      ),
    ),
  )
}

///|
/// Upstream `FR.set_unknown`.
fn set_unknown(flag : @types.Var, name : String) -> @types.Stmt {
  assign(flag, e_unknown(name, 1))
}

///|
/// Upstream `PR.lock`.
fn lock(bil : Array[@types.Stmt]) -> Array[@types.Stmt] {
  cat([[intrinsic("x86:lock")], bil, [intrinsic("x86:unlock")]])
}

///|
/// Upstream `X86_prefix.exists`: whether the known prefix bytes at the
/// start of the instruction include `prefix`.
fn Tools::has_prefix(self : Tools, prefix : Int) -> Bool {
  for b in self.insn.raw {
    let b = b.to_int()
    if !is_legacy_prefix(b) {
      return false
    }
    if b == prefix {
      return true
    }
  }
  false
}

///|
/// A memory operand (upstream `MM.t`): an address expression.
priv enum Mem {
  Segment(
    seg~ : Reg?,
    base~ : MemBase?,
    scale~ : Int?,
    index~ : Reg?,
    disp~ : Int64
  )
}

///|
priv enum MemBase {
  Gpr(Reg)
  IpBase(UInt64)
}

///|
/// Upstream `MM.addr_size`.
fn Tools::addr_size(self : Tools) -> Int {
  self.mode.width()
}

///|
/// Upstream `MM.of_mem`.
fn Tools::of_mem(
  self : Tools,
  seg? : String,
  base? : String,
  scale? : Int64,
  index? : String,
  disp~ : Int64,
) -> Mem raise @mc.LiftError {
  let seg = match seg {
    None => None
    Some(name) =>
      match decode_reg(name) {
        None => None
        Some({ cls: Segment, name: "FS", .. }) => Some(self.reg("FS_BASE"))
        Some({ cls: Segment, name: "GS", .. }) => Some(self.reg("GS_BASE"))
        Some({ cls: Segment, .. }) => None
        Some(r) => raise self.fail("invalid segment \{r.name}")
      }
  }
  let base = match base {
    None => None
    Some(name) =>
      match decode_reg(name) {
        None => None
        Some({ cls: Ip, .. }) =>
          Some(
            IpBase(
              (self.insn.addr + self.insn.size.to_uint64()) &
              mask64(self.addr_size()),
            ),
          )
        Some({ cls: R8L | R8H | R16 | R32 | R64 | R128 | R256, .. }) =>
          Some(Gpr(self.reg(name)))
        Some(r) => raise self.fail("invalid base \{r.name}")
      }
  }
  let scale = match scale {
    None => None
    Some(s) => Some(s.to_int())
  }
  let index = match index {
    None => None
    Some(name) => self.of_name(name)
  }
  Segment(seg~, base~, scale~, index~, disp~)
}

///|
/// Upstream `Segment.make_value`: an address register extended to the
/// address size.
fn Tools::make_value(self : Tools, r : Reg) -> @types.Exp raise @mc.LiftError {
  match (r.cls, self.mode) {
    (R8L | R8H | R16, _) | (R32, X8664) =>
      e_unsigned(self.addr_size(), self.get(r))
    (R32, X86) | (R64, _) | (SegmentBase, _) => self.get(r)
    _ => raise self.fail("invalid address register \{r.name}")
  }
}

///|
/// Upstream `MM.addr`.
fn Tools::addr(self : Tools, m : Mem) -> @types.Exp raise @mc.LiftError {
  let size = self.addr_size()
  match m {
    Segment(seg~, base~, scale~, index~, disp~) => {
      let seg = match seg {
        Some(s) => Some(self.make_value(s))
        None => None
      }
      let base = match base {
        Some(Gpr(r)) => Some(self.make_value(r))
        Some(IpBase(w)) => Some(uint64_exp(w, size))
        None => None
      }
      let scale = match scale {
        None | Some(1) => None
        Some(2) => Some(int_exp(1, 2))
        Some(4) => Some(int_exp(2, 2))
        Some(8) => Some(int_exp(3, 2))
        Some(s) => raise self.fail("invalid memory scale \{s}")
      }
      let index = match index {
        Some(r) => Some(self.make_value(r))
        None => None
      }
      let default = int64_exp(disp, size)
      let disp = if disp != 0L { Some(default) } else { None }
      let add = (x : @types.Exp?, y : @types.Exp?) => {
        match (x, y) {
          (Some(x), Some(y)) => Some(e_plus(x, y))
          (Some(_), None) => x
          (None, _) => y
        }
      }
      let mul = (s : @types.Exp?, i : @types.Exp?) => {
        match (s, i) {
          (Some(s), Some(i)) => Some(e_lsl(i, s))
          (None, Some(_)) => i
          (_, None) => None
        }
      }
      match add(seg, add(add(base, mul(scale, index)), disp)) {
        None => default
        Some(x) => x
      }
    }
  }
}

///|
/// Upstream `MM.load_from`.
fn Tools::load_from(
  self : Tools,
  addr : @types.Exp,
  size : Int,
) -> @types.Exp raise @mc.LiftError {
  e_load(vars_of_mode(self.mode).mem, addr, size) catch {
    _ => raise self.fail("invalid load size")
  }
}

///|
/// Upstream `MM.store_to`.
fn Tools::store_to(
  self : Tools,
  addr : @types.Exp,
  size : Int,
  data : @types.Exp,
) -> @types.Stmt raise @mc.LiftError {
  store_stmt(vars_of_mode(self.mode).mem, addr, size, data) catch {
    _ => raise self.fail("invalid store size")
  }
}

///|
fn Tools::load(
  self : Tools,
  m : Mem,
  size : Int,
) -> @types.Exp raise @mc.LiftError {
  self.load_from(self.addr(m), size)
}

///|
fn Tools::store(
  self : Tools,
  m : Mem,
  size : Int,
  data : @types.Exp,
) -> @types.Stmt raise @mc.LiftError {
  self.store_to(self.addr(m), size, data)
}

///|
/// Upstream `IM.get ~width` (`Imm.to_word`): the immediate truncated to
/// `width` bits.
fn imm_get(value : Int64, width : Int) -> @types.Exp {
  int64_exp(value, width)
}

///|
/// Upstream `X86_operands.invalid_operands`.
fn Tools::invalid_operands(self : Tools) -> @mc.LiftError {
  BadOperands(opcode=self.insn.name, detail="invalid operands")
}

///|
fn op_reg(op : @mc.Op) -> String? {
  match op {
    Reg(name~, ..) => Some(name)
    _ => None
  }
}

///|
fn op_imm(op : @mc.Op) -> Int64? {
  match op {
    Imm(v) => Some(v)
    _ => None
  }
}

///|
/// A memory operand (base, scale, index, disp, seg) at position `k` of the
/// operands.
fn Tools::mem_at(self : Tools, k : Int) -> Mem? raise @mc.LiftError {
  let ops = self.insn.ops
  guard k + 5 <= ops.length() else { return None }
  match
    (
      op_reg(ops[k]),
      op_imm(ops[k + 1]),
      op_reg(ops[k + 2]),
      op_imm(ops[k + 3]),
      op_reg(ops[k + 4]),
    ) {
    (Some(base), Some(scale), Some(index), Some(disp), Some(seg)) =>
      Some(self.of_mem(seg~, base~, scale~, index~, disp~))
    _ => None
  }
}

///|
/// Upstream `X86_operands.rr`: `[_; reg1; reg2]` or `[reg1; reg2]`.
fn Tools::rr(self : Tools) -> (String, String) raise @mc.LiftError {
  match self.insn.ops {
    [_, Reg(name=r1, ..), Reg(name=r2, ..)]
    | [Reg(name=r1, ..), Reg(name=r2, ..)] => (r1, r2)
    _ => raise self.invalid_operands()
  }
}

///|
/// Upstream `X86_operands.ri`: `[_; reg; imm]` or `[reg; imm]`.
fn Tools::ri(self : Tools) -> (String, Int64) raise @mc.LiftError {
  match self.insn.ops {
    [_, Reg(name=r, ..), Imm(i)] | [Reg(name=r, ..), Imm(i)] => (r, i)
    _ => raise self.invalid_operands()
  }
}

///|
/// Upstream `X86_operands.ir`: `[imm; reg]`.
fn Tools::ir(self : Tools) -> (Int64, String) raise @mc.LiftError {
  match self.insn.ops {
    [Imm(i), Reg(name=r, ..)] => (i, r)
    _ => raise self.invalid_operands()
  }
}

///|
/// Upstream `X86_operands.rm`: `[reg; base; scale; index; disp; seg]`.
fn Tools::rm(self : Tools) -> (String, Mem) raise @mc.LiftError {
  let ops = self.insn.ops
  if ops.length() == 6 && op_reg(ops[0]) is Some(r) {
    if self.mem_at(1) is Some(m) {
      return (r, m)
    }
  }
  raise self.invalid_operands()
}

///|
/// Upstream `X86_operands.mr`: `[base; scale; index; disp; seg; reg]`.
fn Tools::mr(self : Tools) -> (Mem, String) raise @mc.LiftError {
  let ops = self.insn.ops
  if ops.length() == 6 && op_reg(ops[5]) is Some(r) {
    if self.mem_at(0) is Some(m) {
      return (m, r)
    }
  }
  raise self.invalid_operands()
}

///|
/// Upstream `X86_operands.mi`: `[base; scale; index; disp; seg; imm]`.
fn Tools::mi(self : Tools) -> (Mem, Int64) raise @mc.LiftError {
  let ops = self.insn.ops
  if ops.length() == 6 && op_imm(ops[5]) is Some(i) {
    if self.mem_at(0) is Some(m) {
      return (m, i)
    }
  }
  raise self.invalid_operands()
}
