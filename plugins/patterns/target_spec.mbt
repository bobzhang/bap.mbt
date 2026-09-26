///|
/// A target specification of a `language` entry (upstream `Target`):
/// either the name of a BAP target, or a Ghidra language specification
/// `arch:endianness:bits:variant[:compiler]` where every field except the
/// architecture may be `default` or `*` (matches anything).
pub(all) enum TargetSpec {
  Named(@core_theory.Target)
  Spec(
    arch~ : String,
    order~ : @core_theory.Endianness?,
    bits~ : Int?,
    variant~ : String?,
    compiler~ : String?
  )
}

///|
/// A malformed target specification.
pub(all) suberror TargetSpecError {
  WrongEndianness(String)
  UnrecognizedTarget(String)
} derive(Eq, Debug)

///|
pub extend TargetSpecError with Eq::{not_equal, equal}

///|
pub extend TargetSpecError with Debug::{to_repr}

///|
pub impl Show for TargetSpecError with fn output(self, logger) {
  match self {
    WrongEndianness(s) => logger.write_string("wrong endianness in \{s}")
    UnrecognizedTarget(s) => logger.write_string("unrecognized target \{s}")
  }
}

///|
pub extend TargetSpecError with Show::{output, to_string}

///|
fn with_default(field : String) -> String? {
  match field {
    "default" | "*" => None
    other => Some(other)
  }
}

///|
/// Parses a target specification (upstream `Target.parse`).
pub fn TargetSpec::parse(str : String) -> TargetSpec raise TargetSpecError {
  let parts = str.split(":").map(p => p.to_owned()).collect()
  if parts.length() >= 3 {
    let arch = parts[0].to_lower()
    let bits = match with_default(parts[2]) {
      None => None
      Some(b) =>
        Some(@string.parse_int(b) catch { _ => raise UnrecognizedTarget(str) })
    }
    let order = match with_default(parts[1]) {
      None => None
      Some("LE" | "LEBE") => Some(@core_theory.Endianness::le())
      Some("BE") => Some(@core_theory.Endianness::eb())
      Some(_) => raise WrongEndianness(str)
    }
    let rest = parts[3:].to_owned()
    let variant = match rest.get(0) {
      None => None
      Some(v) => with_default(v)
    }
    let compiler = if rest.length() == 2 { with_default(rest[1]) } else { None }
    Spec(arch~, order~, bits~, variant~, compiler~)
  } else {
    match @core_theory.Target::lookup(str, pkg="bap") {
      Some(t) => Named(t)
      None =>
        match @core_theory.Target::lookup(str) {
          Some(t) if !t.is_unknown() => Named(t)
          _ => raise UnrecognizedTarget(str)
        }
    }
  }
}

///|
/// `true` if the target satisfies the specification (upstream
/// `Target.matches`; the variant and the compiler are not checked).
pub fn TargetSpec::matches(
  self : TargetSpec,
  target : @core_theory.Target,
) -> Bool {
  match self {
    Named(t) => target.belongs(t)
    Spec(arch~, order~, bits~, ..) =>
      (bits is None || bits == Some(target.bits())) &&
      (order is None || order == Some(target.endianness())) &&
      target.matches(arch)
  }
}
