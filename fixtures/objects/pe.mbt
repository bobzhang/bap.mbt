///|
/// Writes a COFF section header.
fn Buf::coff_section(
  self : Buf,
  off : Int32,
  name : String,
  virtual_size~ : UInt64,
  virtual_address~ : UInt64,
  raw_size~ : UInt64,
  raw_ptr~ : UInt64,
  relocs_ptr~ : UInt64 = 0,
  nrelocs~ : Int32 = 0,
  characteristics~ : UInt64,
) -> Unit {
  self.str(off, name)
  self.u32(off + 8, virtual_size)
  self.u32(off + 12, virtual_address)
  self.u32(off + 16, raw_size)
  self.u32(off + 20, raw_ptr)
  self.u32(off + 24, relocs_ptr)
  self.u16(off + 32, nrelocs)
  self.u32(off + 36, characteristics)
}

///|
/// Writes a COFF symbol record with a short name.
fn Buf::coff_symbol(
  self : Buf,
  off : Int32,
  name : String,
  value~ : UInt64,
  section~ : Int32,
  typ~ : Int32,
  class~ : Int32,
  aux~ : Int32 = 0,
) -> Unit {
  self.str(off, name)
  self.u32(off + 8, value)
  self.u16(off + 12, section & 0xffff)
  self.u16(off + 14, typ)
  self.put(off + 16, 1, class.to_uint64())
  self.put(off + 17, 1, aux.to_uint64())
}

///|
/// The code of `x86_64_pe` at RVA `0x1000` (`.text`):
///
/// ```text
/// 140001000 <main>: push rbp; mov rbp, rsp; call foo; pop rbp; ret
/// 14000100b:        nop; nop; nop
/// 14000100e <foo>:  xor eax, eax; ret
/// 140001011:        jmp qword ptr [rip + 0x1169] (the ExitProcess slot)
/// ```
pub let x86_64_pe_code : Bytes = b"\x55\x48\x89\xe5\xe8\x05\x00\x00\x00\x5d\xc3\x90\x90\x90\x31\xc0\xc3\xff\x25\x69\x11\x00\x00"

///|
/// A small x86-64 PE32+ executable (image base `0x140000000`, entry
/// `main`):
///
/// - `.text` (RVA `0x1000`, see `x86_64_pe_code`) and `.rdata` (RVA
///   `0x2000`) with the export directory (`main`, `foo`), the import
///   directory (`KERNEL32.dll!ExitProcess`, IAT slot at RVA `0x2180`);
/// - a COFF symbol table (as MinGW links it) with a `.file` record with an
///   auxiliary record, the functions `main` and `long_function_foo` (a
///   string table name) and the data symbol `tablesym` in `.rdata`.
pub fn x86_64_pe() -> Bytes {
  let b = Buf::new(0x870)
  b.str(0, "MZ")
  b.u32(0x3c, 0x40)
  b.str(0x40, "PE")
  // file header
  b.u16(0x44, 0x8664)
  b.u16(0x46, 2)
  b.u32(0x4c, 0x800) // symbol table
  b.u32(0x50, 5) // symbols, with the auxiliary record
  b.u16(0x54, 240)
  b.u16(0x56, 0x22)
  // optional header (PE32+)
  let o = 0x58
  b.u16(o, 0x20b)
  b.put(o + 2, 1, 14)
  b.u32(o + 4, 0x200)
  b.u32(o + 8, 0x200)
  b.u32(o + 16, 0x1000) // entry
  b.u32(o + 20, 0x1000) // base of code
  b.u64(o + 24, 0x140000000) // image base
  b.u32(o + 32, 0x1000)
  b.u32(o + 36, 0x200)
  b.u16(o + 40, 6)
  b.u16(o + 48, 6)
  b.u32(o + 56, 0x3000) // size of image
  b.u32(o + 60, 0x400) // size of headers
  b.u16(o + 68, 3) // console
  b.u16(o + 70, 0x8160)
  b.u64(o + 72, 0x100000)
  b.u64(o + 80, 0x1000)
  b.u64(o + 88, 0x100000)
  b.u64(o + 96, 0x1000)
  b.u32(o + 108, 16)
  b.u32(o + 112, 0x2000) // export
  b.u32(o + 116, 0x60)
  b.u32(o + 120, 0x2100) // import
  b.u32(o + 124, 40)
  b.u32(o + 112 + 12 * 8, 0x2180) // IAT
  b.u32(o + 116 + 12 * 8, 16)
  // sections
  b.coff_section(
    0x148,
    ".text",
    virtual_size=0x17,
    virtual_address=0x1000,
    raw_size=0x200,
    raw_ptr=0x400,
    characteristics=0x60000020,
  )
  b.coff_section(
    0x170,
    ".rdata",
    virtual_size=0x200,
    virtual_address=0x2000,
    raw_size=0x200,
    raw_ptr=0x600,
    characteristics=0x40000040,
  )
  b.blob(0x400, x86_64_pe_code)
  // .rdata: export directory
  let r = 0x600 - 0x2000 // file offset of an .rdata RVA
  b.u32(r + 0x200c, 0x2040) // name
  b.u32(r + 0x2010, 1) // ordinal base
  b.u32(r + 0x2014, 2) // functions
  b.u32(r + 0x2018, 2) // names
  b.u32(r + 0x201c, 0x2028) // export address table
  b.u32(r + 0x2020, 0x2030) // name pointers
  b.u32(r + 0x2024, 0x2038) // ordinals
  b.u32(r + 0x2028, 0x1000) // main
  b.u32(r + 0x202c, 0x100e) // foo
  b.u32(r + 0x2030, 0x2050) // "foo"
  b.u32(r + 0x2034, 0x2054) // "main"
  b.u16(r + 0x2038, 1)
  b.u16(r + 0x203a, 0)
  b.str(r + 0x2040, "fixture.exe")
  b.str(r + 0x2050, "foo")
  b.str(r + 0x2054, "main")
  // .rdata: import directory
  b.u32(r + 0x2100, 0x2140) // lookup table
  b.u32(r + 0x210c, 0x2160) // name
  b.u32(r + 0x2110, 0x2180) // address table
  b.u64(r + 0x2140, 0x2170)
  b.str(r + 0x2160, "KERNEL32.dll")
  b.u16(r + 0x2170, 0x120)
  b.str(r + 0x2172, "ExitProcess")
  b.u64(r + 0x2180, 0x2170)
  // symbol table
  b.coff_symbol(0x800, ".file", value=0, section=-2, typ=0, class=0x67, aux=1)
  b.str(0x812, "fixture.c")
  b.coff_symbol(0x824, "main", value=0, section=1, typ=0x20, class=2)
  b.u32(0x836, 0)
  b.u32(0x83a, 4) // string table offset of long_function_foo
  b.u32(0x83e, 0xe)
  b.u16(0x842, 1)
  b.u16(0x844, 0x20)
  b.put(0x846, 1, 2)
  b.coff_symbol(0x848, "tablesym", value=0x100, section=2, typ=0, class=2)
  // string table
  b.u32(0x85a, 22)
  b.str(0x85e, "long_function_foo")
  b.to_bytes()
}

///|
/// A 32-bit i386 COFF object file: `.text` (`call _puts; ret`) with an
/// `IMAGE_REL_I386_REL32` relocation of the call to the undefined
/// `_puts`, a `.data` section, and the symbols `.file`, `_main` and
/// `_puts`.
pub fn i386_coff_object() -> Bytes {
  let b = Buf::new(196)
  b.u16(0, 0x14c)
  b.u16(2, 2)
  b.u32(8, 120) // symbol table
  b.u32(12, 4)
  b.coff_section(
    20,
    ".text",
    virtual_size=0,
    virtual_address=0,
    raw_size=6,
    raw_ptr=100,
    relocs_ptr=106,
    nrelocs=1,
    characteristics=0x60500020,
  )
  b.coff_section(
    60,
    ".data",
    virtual_size=0,
    virtual_address=0,
    raw_size=4,
    raw_ptr=116,
    characteristics=0xc0300040,
  )
  b.blob(100, b"\xe8\x00\x00\x00\x00\xc3")
  b.u32(106, 1)
  b.u32(110, 3)
  b.u16(114, 0x14)
  b.u32(116, 0x2a)
  b.coff_symbol(120, ".file", value=0, section=-2, typ=0, class=0x67, aux=1)
  b.str(138, "a.c")
  b.coff_symbol(156, "_main", value=0, section=1, typ=0x20, class=2)
  b.coff_symbol(174, "_puts", value=0, section=0, typ=0x20, class=2)
  b.u32(192, 4) // empty string table
  b.to_bytes()
}
