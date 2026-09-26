// Test fixtures shared by the command-line plugins and the `bap`
// executable: a tiny x86-64 ELF executable and file systems.

///|
fn set_le(buf : Array[Byte], off : Int, v : UInt64, n : Int) -> Unit {
  for i in 0..<n {
    buf[off + i] = ((v >> (i * 8)) & 0xffUL).to_byte()
  }
}

///|
fn put(buf : Array[Byte], off : Int, data : Bytes) -> Unit {
  for i, b in data {
    buf[off + i] = b
  }
}

///|
/// The code of `x86_64_elf`, loaded at `0x401000`:
///
/// ```text
/// 401000 <main>: push rbp; mov rbp, rsp; call foo; pop rbp; ret
/// 40100b:        nop; nop; nop
/// 40100e <foo>:  xor eax, eax; ret
/// ```
pub let x86_64_code : Bytes = b"\x55\x48\x89\xe5\xe8\x05\x00\x00\x00\x5d\xc3\x90\x90\x90\x31\xc0\xc3"

///|
/// A minimal statically linked x86-64 ELF executable: one executable
/// `PT_LOAD` segment with the `.text` section (see `x86_64_code`), and a
/// symbol table with the functions `main` (the entry point) and `foo`.
pub fn x86_64_elf() -> Bytes {
  let text = x86_64_code
  let shstr = b"\x00.text\x00.symtab\x00.strtab\x00.shstrtab\x00"
  let strtab = b"\x00main\x00foo\x00"
  let base = 0x401000UL
  let text_off = 0x1000
  let symtab_off = text_off + text.length()
  let symtab_size = 3 * 24
  let strtab_off = symtab_off + symtab_size
  let shstr_off = strtab_off + strtab.length()
  let sh_off = (shstr_off + shstr.length() + 7) / 8 * 8
  let total = sh_off + 5 * 64
  let buf = Array::make(total, b'\x00')
  // ELF header
  put(buf, 0, b"\x7fELF\x02\x01\x01")
  set_le(buf, 16, 2, 2) // ET_EXEC
  set_le(buf, 18, 0x3e, 2) // EM_X86_64
  set_le(buf, 20, 1, 4)
  set_le(buf, 24, base, 8) // e_entry
  set_le(buf, 32, 64, 8) // e_phoff
  set_le(buf, 40, sh_off.to_uint64(), 8)
  set_le(buf, 52, 64, 2)
  set_le(buf, 54, 56, 2)
  set_le(buf, 56, 1, 2)
  set_le(buf, 58, 64, 2)
  set_le(buf, 60, 5, 2)
  set_le(buf, 62, 4, 2) // e_shstrndx
  // PT_LOAD, R+X
  set_le(buf, 64, 1, 4)
  set_le(buf, 68, 5, 4)
  set_le(buf, 72, text_off.to_uint64(), 8)
  set_le(buf, 80, base, 8)
  set_le(buf, 88, base, 8)
  set_le(buf, 96, text.length().to_uint64(), 8)
  set_le(buf, 104, text.length().to_uint64(), 8)
  set_le(buf, 112, 0x1000, 8)
  put(buf, text_off, text)
  // symbols: the null symbol, main, foo (STB_GLOBAL, STT_FUNC)
  let sym = (i : Int, name : Int, value : UInt64, size : UInt64) => {
    let o = symtab_off + i * 24
    set_le(buf, o, name.to_uint64(), 4)
    buf[o + 4] = b'\x12'
    set_le(buf, o + 6, 1, 2)
    set_le(buf, o + 8, value, 8)
    set_le(buf, o + 16, size, 8)
  }
  sym(1, 1, base, 11)
  sym(2, 6, base + 14, 3)
  put(buf, strtab_off, strtab)
  put(buf, shstr_off, shstr)
  let sec = (
    i : Int,
    name : Int,
    typ : Int,
    flags : UInt64,
    addr : UInt64,
    off : Int,
    size : Int,
    link : Int,
    info : Int,
    entsize : Int,
  ) => {
    let o = sh_off + i * 64
    set_le(buf, o, name.to_uint64(), 4)
    set_le(buf, o + 4, typ.to_uint64(), 4)
    set_le(buf, o + 8, flags, 8)
    set_le(buf, o + 16, addr, 8)
    set_le(buf, o + 24, off.to_uint64(), 8)
    set_le(buf, o + 32, size.to_uint64(), 8)
    set_le(buf, o + 40, link.to_uint64(), 4)
    set_le(buf, o + 44, info.to_uint64(), 4)
    set_le(buf, o + 56, entsize.to_uint64(), 8)
  }
  sec(1, 1, 1, 6, base, text_off, text.length(), 0, 0, 0)
  sec(2, 7, 2, 0, 0, symtab_off, symtab_size, 3, 1, 24)
  sec(3, 15, 3, 0, 0, strtab_off, strtab.length(), 0, 0, 0)
  sec(4, 23, 3, 0, 0, shstr_off, shstr.length(), 0, 0, 0)
  Bytes::from_array(buf)
}

///|
/// An in-memory file system with the given binary files (and the parent
/// directories of the files).
pub fn file_system(files : Array[(String, Bytes)]) -> @bap_main.FileSystem {
  let dirs : Map[String, Array[String]] = Map([])
  for entry in files {
    let path = entry.0
    match path.rev_find("/") {
      Some(i) => {
        let dir = path[:i].to_owned()
        let name = path[i + 1:].to_owned()
        match dirs.get(dir) {
          Some(xs) => xs.push(name)
          None => dirs[dir] = [name]
        }
      }
      None => ()
    }
  }
  {
    kind: path => {
      if files.iter().any(e => e.0 == path) {
        Some(RegularFile)
      } else if dirs.contains(path) || path == "." {
        Some(Directory)
      } else {
        None
      }
    },
    read_file: path => {
      for entry in files {
        if entry.0 == path {
          return Some(entry.1)
        }
      }
      None
    },
    read_dir: path => dirs.get(path),
  }
}
