///|
/// The result of lifting one instruction.
///
/// - `bil` is the semantics of the instruction; an empty program is a
///   valid result (e.g. a `nop`), distinct from `Unsupported`;
/// - `delay` is the number of delay-slot instructions that execute before
///   the control transfer of `bil` takes effect (upstream
///   `Insn.Slot.delay`, e.g. `1` for MIPS branches);
/// - `dest_encoding` is the encoding of the instructions at the branch
///   destination when the branch switches the instruction set
///   (interworking, upstream `Theory.Label.encoding` of the destination),
///   `None` when it is unknown or the encoding does not change.
pub struct Lifted {
  bil : Array[@types.Stmt]
  delay : Int
  dest_encoding : @core_theory.Language?
} derive(Eq, Debug)

///|
pub extend Lifted with Eq::{equal, not_equal}

///|
pub extend Lifted with Debug::{to_repr}

///|
/// Create a lifting result.
pub fn Lifted::create(
  bil : Array[@types.Stmt],
  delay? : Int = 0,
  dest_encoding? : @core_theory.Language,
) -> Lifted {
  { bil, delay, dest_encoding, }
}

///|
/// A lifting result without delay slots or encoding switches.
pub fn Lifted::of_bil(bil : Array[@types.Stmt]) -> Lifted {
  { bil, delay: 0, dest_encoding: None, }
}

///|
pub fn Lifted::bil(self : Lifted) -> Array[@types.Stmt] {
  self.bil
}

///|
pub fn Lifted::delay(self : Lifted) -> Int {
  self.delay
}

///|
pub fn Lifted::dest_encoding(self : Lifted) -> @core_theory.Language? {
  self.dest_encoding
}
