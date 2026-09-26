// The relocation fixups of lifted code (upstream
// `plugins/bil/bil_lifter.ml`, `Relocations`, run by the
// `bil-fixup-relocator`): in relocatable files the operands of the
// instructions that refer to other code, e.g., the displacement of a call,
// are placeholders filled in by the linker, so the destinations computed
// from the instruction bytes are wrong (typically the next instruction).
// The destinations are recovered from the relocations of the file: a jump
// of an instruction affected by a relocation to a known address goes to
// that address, and one affected by a reference to an external symbol
// becomes a call of the symbol (a `call` special statement).

///|
/// The relocation information of a unit: the internal relocations (fixup
/// address to target address), the external references (fixup address to
/// the name of the external symbol), and the stubs (the regions of the
/// sections of the linkage stubs, e.g., `.plt`, where the references to
/// external symbols are references to their implementations).
pub struct ProjectRelocations {
  priv rels : Map[UInt64, UInt64]
  priv exts : Map[UInt64, String]
  priv stubs : Array[(UInt64, UInt64)]
}

///|
/// Relocation tables are compared by their contents.
pub impl Eq for ProjectRelocations with fn equal(self, other) {
  physical_equal(self, other) ||
  (
    self.rels == other.rels &&
    self.exts == other.exts &&
    self.stubs == other.stubs
  )
}

///|
pub extend ProjectRelocations with Eq::{not_equal, equal}

///|
/// No relocations.
pub fn ProjectRelocations::empty() -> ProjectRelocations {
  { rels: Map([]), exts: Map([]), stubs: [], }
}

///|
/// The relocation information made of the given relocations (fixup address,
/// target address), external references (fixup address, symbol name), and
/// stub regions (start address, size in bytes). A symbol name may carry a
/// version suffix (`name@version`), which is removed (upstream
/// `chop_version`).
pub fn ProjectRelocations::create(
  rels? : ArrayView[(UInt64, UInt64)] = [],
  exts? : ArrayView[(UInt64, String)] = [],
  stubs? : ArrayView[(UInt64, Int)] = [],
) -> ProjectRelocations {
  let r : Map[UInt64, UInt64] = Map([])
  for x in rels {
    r[x.0] = x.1
  }
  let e : Map[UInt64, String] = Map([])
  for x in exts {
    e[x.0] = project_relocation_chop_version(x.1)
  }
  let stubs = stubs
    .iter()
    .filter(x => x.1 > 0)
    .map(x => (x.0, x.0 + x.1.to_uint64()))
    .to_array()
  { rels: r, exts: e, stubs, }
}

///|
/// `name@version` is `name`; names that start with `@` are kept.
fn project_relocation_chop_version(name : String) -> String {
  match name.find("@") {
    Some(i) if i > 0 => name.view(end_offset=i).to_owned()
    _ => name
  }
}

///|
/// Whether the section `name` holds linkage stubs (the PLT of ELF files,
/// the stubs of Mach-O files).
fn project_relocation_is_stub_section(name : String) -> Bool {
  name.has_prefix(".plt") ||
  name == ".iplt" ||
  name == "__stubs" ||
  name.has_prefix("__symbol_stub") ||
  name == "__auth_stubs"
}

///|
/// The relocation information of an image: its relocations with known
/// targets, its external references, and its stub sections.
pub fn ProjectRelocations::of_image(image : @image.Image) -> ProjectRelocations {
  let rels = []
  for r in image.relocations() {
    match r.target() {
      Some(t) => rels.push((r.fixup(), t))
      None => ()
    }
  }
  let stubs = []
  for section in image.sections() {
    if project_relocation_is_stub_section(section.name()) {
      stubs.push((section.addr(), section.size()))
    }
  }
  ProjectRelocations::create(
    rels~,
    exts=image.external_references().map(x => (x.addr(), x.name())),
    stubs~,
  )
}

///|
/// Whether `addr` is in a stub section.
pub fn ProjectRelocations::is_stub(
  self : ProjectRelocations,
  addr : UInt64,
) -> Bool {
  self.stubs.iter().any(r => r.0 <= addr && addr < r.1)
}

///|
/// Whether there are no relocations.
pub fn ProjectRelocations::is_empty(self : ProjectRelocations) -> Bool {
  self.rels.is_empty() && self.exts.is_empty()
}

///|
/// The target address of the internal relocation at `addr`.
pub fn ProjectRelocations::relocation(
  self : ProjectRelocations,
  addr : UInt64,
) -> UInt64? {
  self.rels.get(addr)
}

///|
/// The name of the external symbol referenced at `addr`.
pub fn ProjectRelocations::external(
  self : ProjectRelocations,
  addr : UInt64,
) -> String? {
  self.exts.get(addr)
}

///|
fn project_relocation_const(w : @types.Word) -> UInt64? {
  try w.to_uint64() catch {
    _ => None
  } noraise {
    x => Some(x)
  }
}

///|
/// The constant addresses loaded by the code (upstream `reference_analyzer`):
/// loads from constants, and from variables assigned constants, in the
/// ascending order.
fn project_relocation_references(bil : ArrayView[@types.Stmt]) -> Array[UInt64] {
  let vars : Map[String, UInt64] = Map([])
  let refs : Array[UInt64] = []
  let add = (a : UInt64) => if !refs.contains(a) { refs.push(a) }
  fn exp(e : @types.Exp) -> Unit {
    match e {
      Load(mem~, addr~, ..) => {
        match addr {
          Int(w) =>
            match project_relocation_const(w) {
              Some(a) => add(a)
              None => ()
            }
          Var(v) =>
            match vars.get(v.to_string()) {
              Some(a) => add(a)
              None => ()
            }
          _ => ()
        }
        exp(mem)
        exp(addr)
      }
      Int(_) | Var(_) | Unknown(_) => ()
      Store(mem~, addr~, value~, ..) => {
        exp(mem)
        exp(addr)
        exp(value)
      }
      Let(_, x, y) | BinOp(_, x, y) | Concat(high=x, low=y) => {
        exp(x)
        exp(y)
      }
      Cast(exp=x, ..) | Extract(exp=x, ..) | UnOp(_, x) => exp(x)
      Ite(cond~, yes~, no~) => {
        exp(cond)
        exp(yes)
        exp(no)
      }
    }
  }

  fn stmts(xs : ArrayView[@types.Stmt]) -> Unit {
    for s in xs {
      match s {
        Move(v, e) => {
          match e {
            Int(w) =>
              match project_relocation_const(w) {
                Some(a) => vars[v.to_string()] = a
                None => ()
              }
            _ => ()
          }
          exp(e)
        }
        Jmp(e) => exp(e)
        Special(_) | CpuExn(_) => ()
        While(cond~, body~) => {
          exp(cond)
          stmts(body)
        }
        If(cond~, yes~, no~) => {
          exp(cond)
          stmts(yes)
          stmts(no)
        }
      }
    }
  }

  stmts(bil)
  refs.sort()
  refs
}

///|
/// The constant addresses loaded by the code (see `ProjectRelocations::fixup`).
pub fn ProjectRelocations::references(
  bil : ArrayView[@types.Stmt],
) -> Array[UInt64] {
  project_relocation_references(bil)
}

///|
/// Whether `stmt` is a Basic lifter control hint (a `call` or `goto`
/// special statement that classifies the jump that follows it).
fn project_relocation_is_hint(stmt : @types.Stmt) -> Bool {
  @types.Stmt::decode(@types.Stmt::call(), stmt) is Some(_) ||
  @types.Stmt::decode(@types.Stmt::goto(), stmt) is Some(_)
}

///|
/// Rewrites every jump (at any depth) with `f`, which receives the jump
/// destination and the Basic control hint that precedes the jump, if any
/// (the hint is replaced together with the jump).
fn project_relocation_map_jmps(
  bil : ArrayView[@types.Stmt],
  f : (@types.Stmt?, @types.Exp) -> Array[@types.Stmt],
) -> Array[@types.Stmt] {
  let out = []
  let mut i = 0
  while i < bil.length() {
    match (bil[i], bil.get(i + 1)) {
      (Special(_) as hint, Some(Jmp(dst))) if project_relocation_is_hint(hint) => {
        out.append(f(Some(hint), dst))
        i += 2
        continue
      }
      (Jmp(dst), _) => out.append(f(None, dst))
      (While(cond~, body~), _) =>
        out.push(While(cond~, body=project_relocation_map_jmps(body, f)))
      (If(cond~, yes~, no~), _) =>
        out.push(
          If(
            cond~,
            yes=project_relocation_map_jmps(yes, f),
            no=project_relocation_map_jmps(no, f),
          ),
        )
      (s, _) => out.push(s)
    }
    i += 1
  }
  out
}

///|
/// Redirects the jumps of the instruction at `addr` of `size` bytes whose
/// semantics is `bil` (upstream `Relocations.fixup`). The candidate
/// addresses are the constant addresses loaded by the instruction, followed
/// by the addresses of its bytes. If one of them has an internal
/// relocation, all jumps go to its target (a Basic control hint keeps
/// classifying its jump); otherwise, if one of them has an external
/// reference, all jumps (with their Basic control hints) become calls of
/// the external symbol, suffixed with `:external` when the instruction is
/// in a stub (`is_stub`, by default whether `addr` is in a stub section of
/// the relocations; upstream: the `Sub.stub` tag). Code that is not affected by any relocation is
/// returned as it is. The jump targets are words of `width` bits (unless a
/// jump already jumps to a constant, the width of which is kept).
pub fn ProjectRelocations::fixup(
  self : ProjectRelocations,
  bil : ArrayView[@types.Stmt],
  addr~ : UInt64,
  size~ : Int,
  width~ : Int,
  is_stub? : Bool = self.is_stub(addr),
) -> Array[@types.Stmt] {
  if self.is_empty() {
    return bil.to_owned()
  }
  let addresses = project_relocation_references(bil)
  for i in 0..<size {
    addresses.push(addr + i.to_uint64())
  }
  for a in addresses {
    match self.rels.get(a) {
      Some(dst) =>
        return project_relocation_map_jmps(bil, (hint, jmp) => {
          let width = match jmp {
            Int(w) => w.width()
            _ => width
          }
          let target = @types.Word::of_uint64(width~, dst) catch {
            _ => return [..hint.map(h => [h]).unwrap_or([]), Jmp(jmp)]
          }
          let hint = match hint {
            Some(Special(_) as h) =>
              match @types.Stmt::decode(@types.Stmt::call(), h) {
                Some(_) =>
                  [
                    @types.Stmt::encode(
                      @types.Stmt::call(),
                      "0x" + dst.to_string(radix=16),
                    ),
                  ]
                None =>
                  [
                    @types.Stmt::encode(
                      @types.Stmt::goto(),
                      "0x" + dst.to_string(radix=16),
                    ),
                  ]
              }
            _ => []
          }
          hint + [Jmp(Int(target))]
        })
      None => ()
    }
  }
  for a in addresses {
    match self.exts.get(a) {
      Some(name) => {
        let name = if is_stub { name + ":external" } else { name }
        return project_relocation_map_jmps(bil, (_, _) => {
          [@types.Stmt::encode(@types.Stmt::call(), name)]
        })
      }
      None => ()
    }
  }
  bil.to_owned()
}

///|
/// The relocations of the unit being disassembled (upstream: the
/// `bil-relocations` property of the unit), attached to the instructions
/// decoded in that unit (see `driver_new_insn`).
let project_unit_relocations : @knowledge.Var[
  (@core_theory.ProgramUnit, ProjectRelocations)?,
] = @knowledge.Var::new("disasm-unit-relocations", _ => None, pkg="bap")

///|
/// The instruction decoded in `unit`, with the relocations of the unit.
fn project_insn_with_unit_relocations(
  kb : @knowledge.State,
  insn : ProjectDisassemblyInstruction,
  unit : @core_theory.ProgramUnit?,
) -> ProjectDisassemblyInstruction raise {
  match (project_unit_relocations.get(kb), unit) {
    (Some((owner, relocations)), Some(unit)) if owner.same(unit) =>
      insn.with_relocations(relocations)
    _ => insn
  }
}

///|
/// The relocation information of the image of the project (empty for a
/// project without an image).
pub fn Project::relocation_info(self : Project) -> ProjectRelocations {
  match self.image() {
    Some(image) => ProjectRelocations::of_image(image)
    None => ProjectRelocations::empty()
  }
}
