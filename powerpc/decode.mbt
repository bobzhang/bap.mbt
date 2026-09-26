// Native PowerPC decoder: a replacement of the LLVM MC PowerPC disassembler
// used upstream (`Disasm_expert.Basic` with the `llvm` backend) for the
// instructions supported by the lifter. It produces `@mc.Insn`s with the
// LLVM opcode names, operand lists, kinds and (LLVM-style) assembly, so
// that the lifter can be driven on real binaries.

///|
/// The encoding decoded in `mode`: `llvm-powerpc64` for 64-bit code,
/// `llvm-powerpc32` otherwise.
fn mode_encoding(mode : AddrSize) -> @core_theory.Language {
  match mode {
    R32 => @core_theory.Language::llvm_powerpc32()
    R64 => @core_theory.Language::llvm_powerpc64()
  }
}

///|
/// Decode the instruction word `word` (already assembled from the bytes in
/// the target byte order) located at `addr`. Returns `None` for words that
/// are not instructions supported by the decoder.
///
/// The decoded instructions are the same in 32- and 64-bit modes (as with
/// LLVM, which decodes the 64-bit only instructions in both modes); `mode`
/// selects the default `encoding` (`llvm-powerpc32` or `llvm-powerpc64`).
/// `raw` defaults to the big-endian encoding of `word`.
pub fn decode_word(
  word : UInt,
  addr : UInt64,
  mode? : AddrSize = R32,
  encoding? : @core_theory.Language = mode_encoding(mode),
  raw? : Bytes,
) -> @mc.Insn? {
  guard decode_spec(word) is Some(spec) else { None }
  let raw = match raw {
    Some(raw) => raw
    None =>
      Bytes::from_array([
        (word >> 24).to_byte(),
        (word >> 16).to_byte(),
        (word >> 8).to_byte(),
        word.to_byte(),
      ])
  }
  Some(
    @mc.Insn::create(
      spec.name,
      spec.ops(),
      addr~,
      size=4,
      assembly=spec.assembly(),
      encoding~,
      kinds=spec.kinds,
      raw~,
    ),
  )
}

///|
/// The instruction word at the start of `bytes` in the byte order `endian`,
/// or `None` when fewer than four bytes are available.
pub fn read_word(bytes : BytesView, endian : @bitvec.Endian) -> UInt? {
  guard bytes.length() >= 4 else { None }
  let b = [bytes[0], bytes[1], bytes[2], bytes[3]]
  let (b0, b1, b2, b3) = match endian {
    BigEndian => (b[0], b[1], b[2], b[3])
    LittleEndian => (b[3], b[2], b[1], b[0])
  }
  Some(
    (b0.to_uint() << 24) |
    (b1.to_uint() << 16) |
    (b2.to_uint() << 8) |
    b3.to_uint(),
  )
}

///|
/// Decode the instruction at the start of `bytes`, loaded at `addr`, in
/// `mode` and byte order `endian` (see `decode_word`). Returns `None` when
/// fewer than four bytes are available or the word is not a supported
/// instruction.
pub fn decode(
  bytes : BytesView,
  addr : UInt64,
  mode? : AddrSize = R32,
  endian? : @bitvec.Endian = BigEndian,
  encoding? : @core_theory.Language = mode_encoding(mode),
) -> @mc.Insn? {
  guard read_word(bytes, endian) is Some(word) else { None }
  decode_word(word, addr, mode~, encoding~, raw=bytes[:4].to_owned())
}

///|
/// Name of the decoder installed by `register_decoder`.
pub let decoder_name : String = "powerpc"

///|
/// Decode in a context (see `accepts` and `mode_of_context`): instructions
/// are 4 bytes long, in the byte order of the target.
pub fn decode_in_context(
  ctx : @mc.Context,
  bytes : BytesView,
  addr : UInt64,
) -> @mc.Decoded {
  let (mode, endian) = mode_of_context(ctx)
  guard read_word(bytes, endian) is Some(word) else { Truncated }
  let encoding = if ctx.encoding.is_unknown() {
    mode_encoding(mode)
  } else {
    ctx.encoding
  }
  match decode_word(word, addr, mode~, encoding~, raw=bytes[:4].to_owned()) {
    Some(insn) => Decoded(insn)
    None => Invalid(size=4)
  }
}

///|
/// The native PowerPC decoder (see `accepts` and `decode_in_context`).
pub fn decoder() -> @mc.Decoder {
  @mc.Decoder::create(decoder_name, accepts~, decode=decode_in_context)
}

///|
/// Register the native PowerPC decoder in the process-wide `@mc` decoder
/// table. Idempotent: the decoder is replaced by name.
pub fn register_decoder() -> Unit {
  @mc.register_decoder(decoder())
}
