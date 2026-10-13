// Machine code decoders (upstream: the backends of `Disasm_expert.Basic`,
// e.g. the LLVM MC disassembler, registered for encodings).
//
// A decoder turns the bytes at an address into an `Insn`. Decoders are
// registered in a process-wide table and selected by the decoding context
// (the target and the encoding), so that architecture packages can provide
// decoders without depending on the project library; the project Basic
// disassembler (`@project.ProjectDisassemblyBasic::lookup`) consults this
// table for the encodings it has no built-in decoder for.

///|
/// The result of decoding the bytes at an address.
pub(all) enum Decoded {
  /// A valid instruction; it occupies `insn.size` bytes.
  Decoded(Insn)
  /// An invalid instruction occupying `size` (at least one) bytes.
  Invalid(size~ : Int32)
  /// Not enough bytes are left to decode an instruction.
  Truncated
} derive(Eq, Debug)

///|
pub extend Decoded with Eq::{equal, not_equal}

///|
pub extend Decoded with Debug::{to_repr}

///|
/// A named decoder of machine instructions. `accepts` decides from the
/// context alone whether the decoder applies; `decode ctx bytes addr`
/// decodes the instruction at the start of `bytes`, which are loaded at
/// `addr` (the bytes may extend past the instruction).
pub struct Decoder {
  name : String
  accepts : (Context) -> Bool
  decode : (Context, BytesView, UInt64) -> Decoded
}

///|
pub fn Decoder::create(
  name : String,
  accepts~ : (Context) -> Bool,
  decode~ : (Context, BytesView, UInt64) -> Decoded,
) -> Decoder {
  { name, accepts, decode, }
}

///|
pub fn Decoder::name(self : Decoder) -> String {
  self.name
}

///|
pub fn Decoder::accepts(self : Decoder, ctx : Context) -> Bool {
  (self.accepts)(ctx)
}

///|
/// Decodes the instruction at the start of `bytes`, loaded at `addr`.
pub fn Decoder::decode(
  self : Decoder,
  ctx : Context,
  bytes : BytesView,
  addr : UInt64,
) -> Decoded {
  (self.decode)(ctx, bytes, addr)
}

///|
let global_decoders : Array[Decoder] = []

///|
/// Registers `decoder` in the process-wide decoder table. Decoders are
/// consulted in the order of their first registration; registering a
/// decoder under an existing name replaces it in place.
pub fn register_decoder(decoder : Decoder) -> Unit {
  match global_decoders.search_by(d => d.name == decoder.name) {
    Some(i) => global_decoders[i] = decoder
    None => global_decoders.push(decoder)
  }
}

///|
/// Removes the decoder named `name`; `false` if there is none.
pub fn unregister_decoder(name : String) -> Bool {
  match global_decoders.search_by(d => d.name == name) {
    Some(i) => {
      global_decoders.remove(i) |> ignore
      true
    }
    None => false
  }
}

///|
/// The registered decoders, in registration order.
pub fn decoders() -> Array[Decoder] {
  global_decoders.copy()
}

///|
/// The first registered decoder accepting `ctx`.
pub fn find_decoder(ctx : Context) -> Decoder? {
  for decoder in global_decoders {
    if decoder.accepts(ctx) {
      return Some(decoder)
    }
  }
  None
}
