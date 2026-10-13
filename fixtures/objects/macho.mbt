///|
/// Writes a `segment_command_64` (without its sections).
fn Buf::segment64(
  self : Buf,
  off : Int32,
  name : String,
  vmaddr~ : UInt64,
  vmsize~ : UInt64,
  fileoff~ : UInt64,
  filesize~ : UInt64,
  prot~ : UInt64,
  nsects~ : Int32 = 0,
) -> Unit {
  self.u32(off, 0x19)
  self.u32(off + 4, (72 + 80 * nsects).to_uint64())
  self.str(off + 8, name)
  self.u64(off + 24, vmaddr)
  self.u64(off + 32, vmsize)
  self.u64(off + 40, fileoff)
  self.u64(off + 48, filesize)
  self.u32(off + 56, prot)
  self.u32(off + 60, prot)
  self.u32(off + 64, nsects.to_uint64())
}

///|
/// Writes a `section_64`.
fn Buf::section64(
  self : Buf,
  off : Int32,
  sectname : String,
  segname : String,
  addr~ : UInt64,
  size~ : UInt64,
  offset~ : UInt64,
  align~ : UInt64 = 0,
  flags~ : UInt64,
  reloff~ : UInt64 = 0,
  nreloc~ : UInt64 = 0,
  reserved1~ : UInt64 = 0,
  reserved2~ : UInt64 = 0,
) -> Unit {
  self.str(off, sectname)
  self.str(off + 16, segname)
  self.u64(off + 32, addr)
  self.u64(off + 40, size)
  self.u32(off + 48, offset)
  self.u32(off + 52, align)
  self.u32(off + 56, reloff)
  self.u32(off + 60, nreloc)
  self.u32(off + 64, flags)
  self.u32(off + 68, reserved1)
  self.u32(off + 72, reserved2)
}

///|
/// Writes an `nlist_64`.
fn Buf::nlist64(
  self : Buf,
  off : Int32,
  strx : UInt64,
  n_type : Int32,
  n_sect : Int32,
  n_desc : Int32,
  value : UInt64,
) -> Unit {
  self.u32(off, strx)
  self.put(off + 4, 1, n_type.to_uint64())
  self.put(off + 5, 1, n_sect.to_uint64())
  self.u16(off + 6, n_desc)
  self.u64(off + 8, value)
}

///|
/// Writes a 64-bit Mach-O header.
fn Buf::header64(
  self : Buf,
  cputype : UInt64,
  cpusubtype : UInt64,
  filetype~ : UInt64,
  ncmds~ : UInt64,
  sizeofcmds~ : UInt64,
  flags~ : UInt64,
) -> Unit {
  self.u32(0, 0xfeedfacf)
  self.u32(4, cputype)
  self.u32(8, cpusubtype)
  self.u32(12, filetype)
  self.u32(16, ncmds)
  self.u32(20, sizeofcmds)
  self.u32(24, flags)
}

///|
/// The code of `x86_64_macho` at `0x100000400` (`__text`), followed by the
/// `_exit` stub at `0x100000418` (`__stubs`):
///
/// ```text
/// 100000400 <_main>: push rbp; mov rbp, rsp; call _foo; pop rbp; ret
/// 10000040b:         nop; nop; nop
/// 10000040e <_foo>:  xor eax, eax; ret
/// 100000411:         jmp 100000418 (a function only in LC_FUNCTION_STARTS)
/// 100000416:         nop; nop
/// 100000418:         jmp qword ptr [rip + 0xbe2] (the _exit stub)
/// ```
pub let x86_64_macho_code : Bytes = b"\x55\x48\x89\xe5\xe8\x05\x00\x00\x00\x5d\xc3\x90\x90\x90\x31\xc0\xc3\xe9\x02\x00\x00\x00\x90\x90\xff\x25\xe2\x0b\x00\x00"

///|
/// A small x86-64 Mach-O executable (`MH_EXECUTE`, as `ld64` lays it out):
///
/// - `__PAGEZERO`; `__TEXT` (r-x, file offset 0) with `__text` and the
///   `__stubs` symbol stubs; `__DATA` (rw-, 16 bytes in the file, 4 KiB in
///   memory) with the `__got` pointers and a `__bss` zero fill section;
///   `__LINKEDIT`;
/// - a symbol table with `_foo` (local), `__mh_execute_header`, `_main`
///   and the undefined `_exit`; the indirect symbols of `__stubs` and
///   `__got` are `_exit`;
/// - `LC_MAIN` (entry `_main`), `LC_LOAD_DYLIB` of `libSystem` and
///   `LC_FUNCTION_STARTS` (`_main`, `_foo` and an unnamed function at
///   `0x100000411`).
pub fn x86_64_macho() -> Bytes {
  let b = Buf::new(0x1088)
  b.header64(
    0x01000007,
    3,
    filetype=2,
    ncmds=9,
    sizeofcmds=808,
    flags=0x00200085,
  )
  b.segment64(
    32,
    "__PAGEZERO",
    vmaddr=0,
    vmsize=0x100000000,
    fileoff=0,
    filesize=0,
    prot=0,
  )
  b.segment64(
    104,
    "__TEXT",
    vmaddr=0x100000000,
    vmsize=0x1000,
    fileoff=0,
    filesize=0x1000,
    prot=5,
    nsects=2,
  )
  b.section64(
    176,
    "__text",
    "__TEXT",
    addr=0x100000400,
    size=0x18,
    offset=0x400,
    align=4,
    flags=0x80000400,
  )
  b.section64(
    256,
    "__stubs",
    "__TEXT",
    addr=0x100000418,
    size=6,
    offset=0x418,
    align=1,
    flags=0x80000408,
    reserved1=0,
    reserved2=6,
  )
  b.segment64(
    336,
    "__DATA",
    vmaddr=0x100001000,
    vmsize=0x1000,
    fileoff=0x1000,
    filesize=0x10,
    prot=3,
    nsects=2,
  )
  b.section64(
    408,
    "__got",
    "__DATA",
    addr=0x100001000,
    size=8,
    offset=0x1000,
    align=3,
    flags=6,
    reserved1=1,
  )
  b.section64(
    488,
    "__bss",
    "__DATA",
    addr=0x100001010,
    size=0x20,
    offset=0,
    align=3,
    flags=1,
  )
  b.segment64(
    568,
    "__LINKEDIT",
    vmaddr=0x100002000,
    vmsize=0x1000,
    fileoff=0x1010,
    filesize=0x78,
    prot=1,
  )
  // LC_SYMTAB
  b.u32(640, 0x2)
  b.u32(644, 24)
  b.u32(648, 0x1018)
  b.u32(652, 4)
  b.u32(656, 0x1060)
  b.u32(660, 40)
  // LC_DYSYMTAB
  b.u32(664, 0xb)
  b.u32(668, 80)
  b.u32(672, 0) // ilocalsym
  b.u32(676, 1) // nlocalsym
  b.u32(680, 1) // iextdefsym
  b.u32(684, 2) // nextdefsym
  b.u32(688, 3) // iundefsym
  b.u32(692, 1) // nundefsym
  b.u32(720, 0x1058) // indirectsymoff
  b.u32(724, 2) // nindirectsyms
  // LC_MAIN
  b.u32(744, 0x80000028)
  b.u32(748, 24)
  b.u64(752, 0x400)
  // LC_LOAD_DYLIB
  b.u32(768, 0xc)
  b.u32(772, 56)
  b.u32(776, 24)
  b.u32(780, 2)
  b.u32(784, 0x05276403)
  b.u32(788, 0x10000)
  b.str(792, "/usr/lib/libSystem.B.dylib")
  // LC_FUNCTION_STARTS
  b.u32(824, 0x26)
  b.u32(828, 16)
  b.u32(832, 0x1010)
  b.u32(836, 8)
  b.blob(0x400, x86_64_macho_code)
  // __LINKEDIT: function starts, symbols, indirect symbols, strings
  b.blob(0x1010, b"\x80\x08\x0e\x03\x00")
  b.nlist64(0x1018, 7, 0x0e, 1, 0, 0x10000040e) // _foo
  b.nlist64(0x1028, 12, 0x0f, 1, 0x10, 0x100000000) // __mh_execute_header
  b.nlist64(0x1038, 1, 0x0f, 1, 0, 0x100000400) // _main
  b.nlist64(0x1048, 32, 0x01, 0, 0x100, 0) // _exit
  b.u32(0x1058, 3)
  b.u32(0x105c, 3)
  b.str(0x1061, "_main")
  b.str(0x1067, "_foo")
  b.str(0x106c, "__mh_execute_header")
  b.str(0x1080, "_exit")
  b.to_bytes()
}

///|
/// The code of `arm64_macho` at `0x100000400`:
///
/// ```text
/// 100000400 <_main>: stp x29, x30, [sp, #-16]!; bl _foo;
///                    ldp x29, x30, [sp], #16; ret
/// 100000410 <_foo>:  mov w0, #0; ret
/// ```
pub let arm64_macho_code : Bytes = b"\xfd\x7b\xbf\xa9\x03\x00\x00\x94\xfd\x7b\xc1\xa8\xc0\x03\x5f\xd6\x00\x00\x80\x52\xc0\x03\x5f\xd6"

///|
/// A small arm64 Mach-O executable: `__PAGEZERO`, `__TEXT` with
/// `__text` (see `arm64_macho_code`), `__LINKEDIT`, a symbol table with
/// `_main` and `_foo`, and `LC_MAIN`. The CPU subtype is `arm64e` when
/// `arm64e` is set.
pub fn arm64_macho(arm64e~ : Bool = false) -> Bytes {
  let b = Buf::new(0x1030)
  b.header64(
    0x0100000c,
    if arm64e {
      0x80000002
    } else {
      0
    },
    filetype=2,
    ncmds=5,
    sizeofcmds=344,
    flags=0x00200085,
  )
  b.segment64(
    32,
    "__PAGEZERO",
    vmaddr=0,
    vmsize=0x100000000,
    fileoff=0,
    filesize=0,
    prot=0,
  )
  b.segment64(
    104,
    "__TEXT",
    vmaddr=0x100000000,
    vmsize=0x1000,
    fileoff=0,
    filesize=0x1000,
    prot=5,
    nsects=1,
  )
  b.section64(
    176,
    "__text",
    "__TEXT",
    addr=0x100000400,
    size=0x18,
    offset=0x400,
    align=2,
    flags=0x80000400,
  )
  b.segment64(
    256,
    "__LINKEDIT",
    vmaddr=0x100001000,
    vmsize=0x1000,
    fileoff=0x1000,
    filesize=0x30,
    prot=1,
  )
  // LC_SYMTAB
  b.u32(328, 0x2)
  b.u32(332, 24)
  b.u32(336, 0x1000)
  b.u32(340, 2)
  b.u32(344, 0x1020)
  b.u32(348, 16)
  // LC_MAIN
  b.u32(352, 0x80000028)
  b.u32(356, 24)
  b.u64(360, 0x400)
  b.blob(0x400, arm64_macho_code)
  b.nlist64(0x1000, 1, 0x0f, 1, 0, 0x100000400) // _main
  b.nlist64(0x1010, 7, 0x0e, 1, 0, 0x100000410) // _foo
  b.str(0x1021, "_main")
  b.str(0x1027, "_foo")
  b.to_bytes()
}

///|
/// A universal binary with the `x86_64_macho` and the `arm64_macho`
/// (`arm64e`) slices, page aligned.
pub fn fat_macho() -> Bytes {
  let x86 = x86_64_macho()
  let arm = arm64_macho(arm64e=true)
  let x86_off = 0x1000
  let arm_off = (x86_off + x86.length() + 0xfff) / 0x1000 * 0x1000
  let b = Buf::new(arm_off + arm.length(), big=true)
  b.u32(0, 0xcafebabe)
  b.u32(4, 2)
  b.u32(8, 0x01000007)
  b.u32(12, 3)
  b.u32(16, x86_off.to_uint64())
  b.u32(20, x86.length().to_uint64())
  b.u32(24, 12)
  b.u32(28, 0x0100000c)
  b.u32(32, 0x80000002)
  b.u32(36, arm_off.to_uint64())
  b.u32(40, arm.length().to_uint64())
  b.u32(44, 12)
  b.blob(x86_off, x86)
  b.blob(arm_off, arm)
  b.to_bytes()
}

///|
/// A 32-bit i386 Mach-O executable without a symbol table whose entry
/// point is given by `LC_UNIXTHREAD` (`eip = 0x1400`): `__PAGEZERO`, and
/// `__TEXT` with `__text` (`xor eax, eax; ret` at `0x1400`).
pub fn i386_macho() -> Bytes {
  let b = Buf::new(0x1000)
  b.u32(0, 0xfeedface)
  b.u32(4, 7)
  b.u32(8, 3)
  b.u32(12, 2)
  b.u32(16, 3)
  b.u32(20, 260)
  b.u32(24, 1)
  // LC_SEGMENT __PAGEZERO
  b.u32(28, 1)
  b.u32(32, 56)
  b.str(36, "__PAGEZERO")
  b.u32(56, 0x1000) // vmsize
  // LC_SEGMENT __TEXT
  b.u32(84, 1)
  b.u32(88, 124)
  b.str(92, "__TEXT")
  b.u32(108, 0x1000) // vmaddr
  b.u32(112, 0x1000) // vmsize
  b.u32(116, 0) // fileoff
  b.u32(120, 0x1000) // filesize
  b.u32(124, 5)
  b.u32(128, 5)
  b.u32(132, 1) // nsects
  b.str(140, "__text")
  b.str(156, "__TEXT")
  b.u32(172, 0x1400)
  b.u32(176, 3)
  b.u32(180, 0x400)
  b.u32(196, 0x80000400)
  // LC_UNIXTHREAD, x86_THREAD_STATE32
  b.u32(208, 5)
  b.u32(212, 80)
  b.u32(216, 1)
  b.u32(220, 16)
  b.u32(224 + 40, 0x1400) // eip
  b.blob(0x400, b"\x31\xc0\xc3")
  b.to_bytes()
}

///|
/// An x86-64 Mach-O relocatable object (`MH_OBJECT`): one unnamed segment
/// with `__text` (`call _puts; ret` at file offset `0xd0`), a
/// `X86_64_RELOC_BRANCH` relocation of the call to the undefined `_puts`,
/// and the symbols `_main` and `_puts`.
pub fn x86_64_macho_object() -> Bytes {
  let b = Buf::new(272)
  b.header64(0x01000007, 3, filetype=1, ncmds=2, sizeofcmds=176, flags=0)
  b.segment64(
    32,
    "",
    vmaddr=0,
    vmsize=6,
    fileoff=208,
    filesize=6,
    prot=7,
    nsects=1,
  )
  b.section64(
    104,
    "__text",
    "__TEXT",
    addr=0,
    size=6,
    offset=208,
    align=4,
    flags=0x80000400,
    reloff=216,
    nreloc=1,
  )
  // LC_SYMTAB
  b.u32(184, 0x2)
  b.u32(188, 24)
  b.u32(192, 224)
  b.u32(196, 2)
  b.u32(200, 256)
  b.u32(204, 16)
  b.blob(208, b"\xe8\x00\x00\x00\x00\xc3")
  // r_address 1, r_symbolnum 1, pcrel, length 2, extern, BRANCH
  b.u32(216, 1)
  b.u32(220, 0x2d000001)
  b.nlist64(224, 1, 0x0f, 1, 0, 0) // _main
  b.nlist64(240, 7, 0x01, 0, 0, 0) // _puts
  b.str(257, "_main")
  b.str(263, "_puts")
  b.to_bytes()
}
