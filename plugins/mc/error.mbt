// The failures of the `mc` and `objdump` commands (upstream
// `Mc_main.error` and `string_of_failure`).

///|
/// A reason why the `mc` or `objdump` command failed.
pub(all) enum McFailure {
  BadUserInput
  /// An invalid instruction: the memory, the start and stop offsets.
  BadInsn(@memory.Memory, Int32, Int32)
  CreateMem(String)
  NoInput
  InvalidBase(String)
  TrailingData(Int32)
  /// The instruction printers of a module: module, format, known formats.
  UnknownFormat(String, String, Array[String])
  NoFormatsExpected(String)
  DisassemblerFailed(String)
  LoaderFailed(String)
  TargetMustBeUnknown
  EncodingMustBeUnknown
  TripleMustNotBeSet
  ArchMustNotBeSet
  BackendMustNotBeSet
  CpuMustNotBeSet
  BitsMustNotBeSet
  OrderMustNotBeSet
}

///|
/// The error raised by the commands of the plugin.
pub(all) suberror McError {
  McFail(McFailure)
}

///|
/// The hexdump of the memory (upstream `Memory.hexdump`): lines of 16
/// bytes with the address and the printable characters.
fn hexdump(mem : @memory.Memory) -> String {
  let bytes = mem.to_bytes()
  let buf = StringBuilder()
  let chars : Array[Byte] = []
  let print_chars = (off : Int32) => {
    if !chars.is_empty() {
      buf.write_string(String::make(3 * off, ' ') + "|")
      for c in chars {
        let code = c.to_int()
        buf.write_char(
          if code >= 0x20 && code < 0x7f {
            code.unsafe_to_char()
          } else {
            '.'
          },
        )
      }
      buf.write_string(String::make(off, ' ') + "|\n")
    }
  }
  for i, b in bytes {
    if chars.is_empty() || chars.length() == 16 {
      print_chars(0)
      chars.clear()
      let addr = (mem.min_addr() + i.to_uint64()).to_string(radix=16).to_upper()
      let pad = if addr.length() < 8 {
        String::make(8 - addr.length(), '0')
      } else {
        ""
      }
      buf.write_string(pad + addr + "  ")
    }
    let hex = b.to_int().to_string(radix=16).to_upper()
    buf.write_string((if hex.length() < 2 { "0" + hex } else { hex }) + " ")
    chars.push(b)
  }
  print_chars(16 - chars.length())
  buf.to_string()
}

///|
/// Marks the offsets `boff` and `stop` in the hexdump of `mem` with
/// parentheses (upstream `Bad_insn` printer).
fn mark_hexdump(mem : @memory.Memory, boff : Int32, stop : Int32) -> String {
  let dump = hexdump(mem).to_array()
  let pos = (off : Int32) => {
    let line = boff / 16
    line * 77 + off % 16 * 3 + 9
  }
  if pos(boff) < dump.length() {
    dump[pos(boff)] = '('
  }
  if pos(stop) < dump.length() {
    dump[pos(stop)] = ')'
  }
  String::from_array(dump)
}

///|
pub fn McFailure::to_string(self : McFailure) -> String {
  match self {
    BadUserInput => "Could not parse: malformed input"
    NoInput => "No input was received"
    TrailingData(1) => "the last byte wasn't disassembled"
    TrailingData(left) => "\{left} bytes were left non disassembled"
    CreateMem(err) => "Unable to create a memory: \{err}"
    InvalidBase(msg) => "Failed to parse the base address: \{msg}"
    DisassemblerFailed(err) =>
      "Failed to create the disassembler backend: \{err}"
    BadInsn(mem, boff, stop) =>
      "Invalid instruction at offset \{boff}:\n\{mark_hexdump(mem, boff, stop)}"
    UnknownFormat(mname, fmt, fmts) =>
      "Unknown printer \{fmt} for \{mname}, expecting: \{fmts.join("\n  ")}"
    NoFormatsExpected(name) => "--show-\{name} doesn't expect any formats yet"
    LoaderFailed(err) => "Failed to unpack the file: \{err}"
    TargetMustBeUnknown | TripleMustNotBeSet | ArchMustNotBeSet =>
      "The target, triple, and arch options could not be used together"
    EncodingMustBeUnknown => "The encoding option requires the target option"
    BackendMustNotBeSet => "The backend option requires the triple option"
    CpuMustNotBeSet => "The CPU option requires the triple option"
    BitsMustNotBeSet | OrderMustNotBeSet =>
      "The bits and order parameters are only accepted with arch or triple and are not allowed when the target is specified"
  }
}

///|
let printer_registered : Ref[Bool] = Ref(false)

///|
fn register_error_printer() -> Unit {
  if printer_registered.val {
    return
  }
  printer_registered.val = true
  @bap_main.register_error_printer(err => {
    match err {
      McFail(failure) => Some(failure.to_string())
      _ => None
    }
  })
}
