///|
/// What to put on the labels of the CFG nodes (upstream `label_format`).
pub(all) enum LabelFormat {
  WithName
  WithAsm
  WithBil
} derive(Eq, Debug)

///|
pub extend LabelFormat with Eq::{not_equal, equal}

///|
pub extend LabelFormat with Debug::{to_repr}

///|
/// The order of the label parts: the name goes first, then the assembly,
/// then the BIL (upstream `label_order`, which compares the polymorphic
/// variants `with_asm` < `with_bil` by their hashes).
fn LabelFormat::rank(self : LabelFormat) -> Int {
  match self {
    WithName => 0
    WithAsm => 1
    WithBil => 2
  }
}

///|
/// The phoenix options (upstream `Phoenix_options.t`).
pub(all) struct Options {
  output_folder : String
  cfg_format : Array[LabelFormat]
  no_resolve : Bool
  keep_alive : Bool
  no_inline : Bool
  keep_consts : Bool
  no_optimizations : Bool
} derive(Debug)

///|
pub extend Options with Debug::{to_repr}

///|
/// Creates options with the upstream defaults.
pub fn Options::new(
  output_folder? : String = "phoenix",
  cfg_format? : Array[LabelFormat] = [WithName],
  no_resolve? : Bool = false,
  keep_alive? : Bool = false,
  no_inline? : Bool = false,
  keep_consts? : Bool = false,
  no_optimizations? : Bool = false,
) -> Options {
  {
    output_folder,
    cfg_format,
    no_resolve,
    keep_alive,
    no_inline,
    keep_consts,
    no_optimizations,
  }
}
