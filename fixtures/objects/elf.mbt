// ELF relocatable objects (`ET_REL`), as compilers produce them with `-c`:
// the operands of the instructions that refer to other code are
// placeholders and the references are in the relocation sections.

///|
/// A symbol of an object fixture: its name, value, size, `st_info`
/// (binding and type) and section index (`0` for undefined symbols).
priv struct ElfObjectSymbol {
  name : String
  value : UInt64
  size : UInt64
  info : Int
  shndx : Int
}

///|
/// A relocation of an object fixture: its offset, symbol index, type and
/// addend.
priv struct ElfObjectReloc {
  offset : UInt64
  sym : Int
  typ : Int
  addend : Int64
}

///|
/// The index of the `.text` section of the object fixtures.
const ELF_OBJECT_TEXT : Int = 1

///|
/// A little-endian 64-bit ELF relocatable object for `machine`: the
/// sections are `.text` (with `code`), `.rela.text` (with `text_relocs`),
/// `.eh_frame` (16 zero bytes, allocated but not executable),
/// `.rela.eh_frame` (with `frame_relocs`), `.symtab` (with the null
/// symbol, `locals`, and `globals`), `.strtab` and `.shstrtab`. Symbol
/// indices of relocations count from the null symbol, then `locals`,
/// then `globals`.
fn elf64_object(
  machine~ : Int,
  code~ : Bytes,
  locals~ : Array[ElfObjectSymbol],
  globals~ : Array[ElfObjectSymbol],
  text_relocs~ : Array[ElfObjectReloc],
  frame_relocs~ : Array[ElfObjectReloc],
) -> Bytes {
  let names = [
    "", ".text", ".rela.text", ".eh_frame", ".rela.eh_frame", ".symtab", ".strtab",
    ".shstrtab",
  ]
  // .shstrtab
  let shstr = StringBuilder()
  let name_offsets = []
  for name in names {
    name_offsets.push(@utf8.encode(shstr.to_string()).length())
    shstr.write_string(name)
    shstr.write_char('\u{0}')
  }
  let shstr = @utf8.encode(shstr.to_string())
  // .strtab
  let symbols = [
    { name: "", value: 0, size: 0, info: 0, shndx: 0, },
    ..locals,
    ..globals,
  ]
  let strtab = StringBuilder()
  strtab.write_char('\u{0}')
  let sym_names = []
  for sym in symbols {
    if sym.name == "" {
      sym_names.push(0)
    } else {
      sym_names.push(@utf8.encode(strtab.to_string()).length())
      strtab.write_string(sym.name)
      strtab.write_char('\u{0}')
    }
  }
  let strtab = @utf8.encode(strtab.to_string())
  let align8 = (x : Int) => (x + 7) / 8 * 8
  let text_off = 0x40
  let rela_text_off = align8(text_off + code.length())
  let frame_off = rela_text_off + text_relocs.length() * 24
  let frame_size = 16
  let rela_frame_off = frame_off + frame_size
  let symtab_off = rela_frame_off + frame_relocs.length() * 24
  let strtab_off = symtab_off + symbols.length() * 24
  let shstr_off = strtab_off + strtab.length()
  let sh_off = align8(shstr_off + shstr.length())
  let b = Buf::new(sh_off + names.length() * 64)
  // the ELF header
  b.blob(0, b"\x7fELF\x02\x01\x01")
  b.u16(16, 1) // ET_REL
  b.u16(18, machine)
  b.u32(20, 1)
  b.u64(40, sh_off.to_uint64())
  b.u16(52, 64)
  b.u16(58, 64)
  b.u16(60, names.length())
  b.u16(62, names.length() - 1)
  b.blob(text_off, code)
  let reloc = (off : Int, r : ElfObjectReloc) => {
    b.u64(off, r.offset)
    b.u64(off + 8, (r.sym.to_uint64() << 32) | r.typ.to_uint64())
    b.u64(off + 16, r.addend.reinterpret_as_uint64())
  }
  for i, r in text_relocs {
    reloc(rela_text_off + i * 24, r)
  }
  for i, r in frame_relocs {
    reloc(rela_frame_off + i * 24, r)
  }
  for i, sym in symbols {
    let off = symtab_off + i * 24
    b.u32(off, sym_names[i].to_uint64())
    b.put(off + 4, 1, sym.info.to_uint64())
    b.u16(off + 6, sym.shndx)
    b.u64(off + 8, sym.value)
    b.u64(off + 16, sym.size)
  }
  b.blob(strtab_off, strtab)
  b.blob(shstr_off, shstr)
  // the section headers: name, type, flags, offset, size, link, info,
  // alignment, entry size
  let section = (
    i : Int,
    typ : Int,
    flags : UInt64,
    off : Int,
    size : Int,
    link : Int,
    info : Int,
    align : Int,
    entsize : Int,
  ) => {
    let h = sh_off + i * 64
    b.u32(h, name_offsets[i].to_uint64())
    b.u32(h + 4, typ.to_uint64())
    b.u64(h + 8, flags)
    b.u64(h + 24, off.to_uint64())
    b.u64(h + 32, size.to_uint64())
    b.u32(h + 40, link.to_uint64())
    b.u32(h + 44, info.to_uint64())
    b.u64(h + 48, align.to_uint64())
    b.u64(h + 56, entsize.to_uint64())
  }
  section(ELF_OBJECT_TEXT, 1, 0x6, text_off, code.length(), 0, 0, 16, 0)
  section(2, 4, 0x40, rela_text_off, text_relocs.length() * 24, 5, 1, 8, 24)
  section(3, 1, 0x2, frame_off, frame_size, 0, 0, 8, 0)
  section(4, 4, 0x40, rela_frame_off, frame_relocs.length() * 24, 5, 3, 8, 24)
  section(
    5,
    2,
    0,
    symtab_off,
    symbols.length() * 24,
    6,
    1 + locals.length(),
    8,
    24,
  )
  section(6, 3, 0, strtab_off, strtab.length(), 0, 0, 1, 0)
  section(7, 3, 0, shstr_off, shstr.length(), 0, 0, 1, 0)
  b.to_bytes()
}

///|
/// A local assembler temporary label (`STB_LOCAL`, `STT_NOTYPE`).
fn elf_object_label(name : String, value : UInt64) -> ElfObjectSymbol {
  { name, value, size: 0, info: 0x00, shndx: ELF_OBJECT_TEXT, }
}

///|
/// The section symbol of `.text` (`STB_LOCAL`, `STT_SECTION`).
fn elf_object_section_symbol() -> ElfObjectSymbol {
  { name: "", value: 0, size: 0, info: 0x03, shndx: ELF_OBJECT_TEXT, }
}

///|
/// A global function of `.text` (`STB_GLOBAL`, `STT_FUNC`).
fn elf_object_function(
  name : String,
  value : UInt64,
  size : UInt64,
) -> ElfObjectSymbol {
  { name, value, size, info: 0x12, shndx: ELF_OBJECT_TEXT, }
}

///|
/// An undefined global symbol (`STB_GLOBAL`, `STT_NOTYPE`, `SHN_UNDEF`).
fn elf_object_undefined(name : String) -> ElfObjectSymbol {
  { name, value: 0, size: 0, info: 0x10, shndx: 0, }
}

///|
/// The code of `x86_64_elf_object`, at address 0 of its `.text`:
///
/// ```text
///  0 <sq>: mov eax, edi; imul eax, edi; ret
///  6 <g>:  call sq; add eax, 1; ret
///  f <f>:  push rbx; call g; mov ebx, eax; call ext; add eax, ebx;
///          pop rbx; ret
/// ```
///
/// The displacements of the calls are zero (the placeholders the linker
/// fills in): they all seem to call the next instruction.
pub let x86_64_object_code : Bytes = b"\x89\xf8\x0f\xaf\xc7\xc3\xe8\x00\x00\x00\x00\x83\xc0\x01\xc3\x53\xe8\x00\x00\x00\x00\x89\xc3\xe8\x00\x00\x00\x00\x01\xd8\x5b\xc3"

///|
/// An x86-64 ELF relocatable object (see `x86_64_object_code`): the
/// functions `sq`, `g` and `f`, where `g` calls `sq`, and `f` calls `g`
/// and the undefined `ext`, all through `R_X86_64_PLT32` relocations of
/// the placeholder displacements. It also has a local temporary label
/// `.Ltmp0` in the middle of `g` (at `0xb`, after the call), the section
/// symbol of `.text`, and a relocation of `.eh_frame` at offset `7`
/// against `f`, which, in the object, aliases the address of the
/// displacement of the call of `sq` (all sections are at address 0).
pub fn x86_64_elf_object() -> Bytes {
  let plt32 = 4
  let pc32 = 2
  elf64_object(
    machine=0x3e,
    code=x86_64_object_code,
    locals=[elf_object_label(".Ltmp0", 0xb), elf_object_section_symbol()],
    globals=[
      elf_object_function("sq", 0x0, 6), // 3
      elf_object_function("g", 0x6, 9), // 4
      elf_object_function("f", 0xf, 0x11), // 5
      elf_object_undefined("ext"), // 6
    ],
    text_relocs=[
      { offset: 0x7, sym: 3, typ: plt32, addend: -4, },
      { offset: 0x11, sym: 4, typ: plt32, addend: -4, },
      { offset: 0x18, sym: 6, typ: plt32, addend: -4, },
    ],
    frame_relocs=[{ offset: 0x7, sym: 5, typ: pc32, addend: 0, }],
  )
}

///|
/// The code of `x86_64_elf_tail_object`, at address 0 of its `.text`:
///
/// ```text
///  0 <t1>: lea eax, [rdi + 1]; jmp ext
///  8 <t2>: lea eax, [rdi + rdi*2]; ret
/// ```
pub let x86_64_tail_object_code : Bytes = b"\x8d\x47\x01\xe9\x00\x00\x00\x00\x8d\x04\x7f\xc3"

///|
/// An x86-64 ELF relocatable object where `t1` tail calls the undefined
/// `ext` (a `jmp` with a `R_X86_64_PLT32` relocation), followed by `t2`.
pub fn x86_64_elf_tail_object() -> Bytes {
  elf64_object(
    machine=0x3e,
    code=x86_64_tail_object_code,
    locals=[],
    globals=[
      elf_object_function("t1", 0x0, 8), // 1
      elf_object_function("t2", 0x8, 4), // 2
      elf_object_undefined("ext"), // 3
    ],
    text_relocs=[{ offset: 0x4, sym: 3, typ: 4, addend: -4, }],
    frame_relocs=[],
  )
}

///|
/// The code of `riscv64_elf_object`, at address 0 of its `.text`:
///
/// ```text
///  0 <sq>: mulw a0, a0, a0; ret
///  8 <g>:  addi sp, sp, -16; sd ra, 8(sp); auipc ra, 0; jalr ra, 0(ra);
///          addiw a0, a0, 1; ld ra, 8(sp); addi sp, sp, 16; ret
/// ```
///
/// The `auipc`/`jalr` pair is the placeholder of the call of `sq` (as
/// encoded, it calls the `auipc`).
pub let riscv64_object_code : Bytes = b"\x3b\x05\xa5\x02\x67\x80\x00\x00\x13\x01\x01\xff\x23\x34\x11\x00\x97\x00\x00\x00\xe7\x80\x00\x00\x1b\x05\x15\x00\x83\x30\x81\x00\x13\x01\x01\x01\x67\x80\x00\x00"

///|
/// A RISC-V 64 ELF relocatable object (see `riscv64_object_code`): the
/// functions `sq` and `g`, where `g` calls `sq` through a
/// `R_RISCV_CALL_PLT` relocation (with its `R_RISCV_RELAX` companion) of
/// the `auipc` of the `auipc`/`jalr` pair, and the local `.L0 ` labels
/// that RISC-V objects keep at the start of every basic block (here, the
/// start of `g` and the return address of the call).
pub fn riscv64_elf_object() -> Bytes {
  let call_plt = 19
  let relax = 51
  elf64_object(
    machine=0xf3,
    code=riscv64_object_code,
    locals=[
      elf_object_label(".L0 ", 0x8),
      elf_object_label(".L0 ", 0x18),
      elf_object_section_symbol(),
    ],
    globals=[
      elf_object_function("sq", 0x0, 8), // 4
      elf_object_function("g", 0x8, 0x20), // 5
    ],
    text_relocs=[
      { offset: 0x10, sym: 4, typ: call_plt, addend: 0, },
      { offset: 0x10, sym: 0, typ: relax, addend: 0, },
    ],
    frame_relocs=[],
  )
}

///|
/// The code of `aarch64_elf_object`, at address 0 of its `.text`:
///
/// ```text
///  0 <sq>: mul w0, w0, w0; ret
///  8 <g>:  stp x29, x30, [sp, #-16]!; bl sq; add w0, w0, #1;
///          ldp x29, x30, [sp], #16; ret
/// ```
///
/// The `bl` is the placeholder of the call of `sq` (as encoded, it calls
/// itself).
pub let aarch64_object_code : Bytes = b"\x00\x7c\x00\x1b\xc0\x03\x5f\xd6\xfd\x7b\xbf\xa9\x00\x00\x00\x94\x00\x04\x00\x11\xfd\x7b\xc1\xa8\xc0\x03\x5f\xd6"

///|
/// The code of `aarch64_pauth_elf_object`, at address 0 of its `.text`:
///
/// ```text
///  0 <f>: pacibsp; cbz w0, 0x10
///  8:     mov w0, #1; retab
/// 10:     mov w0, #2; retab
/// ```
pub let aarch64_pauth_object_code : Bytes = b"\x7f\x23\x03\xd5\x60\x00\x00\x34\x20\x00\x80\x52\xff\x0f\x5f\xd6\x40\x00\x80\x52\xff\x0f\x5f\xd6"

///|
/// An AArch64 ELF relocatable object with the function `f` (see
/// `aarch64_pauth_object_code`) that returns with the pointer
/// authenticating `retab`, as arm64e code does.
pub fn aarch64_pauth_elf_object() -> Bytes {
  elf64_object(
    machine=0xb7,
    code=aarch64_pauth_object_code,
    locals=[],
    globals=[elf_object_function("f", 0x0, 0x18)],
    text_relocs=[],
    frame_relocs=[],
  )
}

///|
/// An AArch64 ELF relocatable object (see `aarch64_object_code`): the
/// functions `sq` and `g`, where `g` calls `sq` through a
/// `R_AARCH64_CALL26` relocation of its `bl`.
pub fn aarch64_elf_object() -> Bytes {
  let call26 = 283
  elf64_object(
    machine=0xb7,
    code=aarch64_object_code,
    locals=[elf_object_section_symbol()],
    globals=[
      elf_object_function("sq", 0x0, 8), // 2
      elf_object_function("g", 0x8, 0x14), // 3
    ],
    text_relocs=[{ offset: 0xc, sym: 2, typ: call26, addend: 0, }],
    frame_relocs=[],
  )
}
