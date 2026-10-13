// Port of BAP `lib/bap_c/bap_c_data.ml` (C data model and value layout).

///|
/// Models of integer representation (upstream `model = [model32|model64]`).
///
/// ```text
///        LP32  ILP32  ILP64  LLP64  LP64
/// char      8      8      8      8     8
/// short    16     16     16     16    16
/// int      16     32     64     32    32
/// long     32     32     64     32    64
/// addr     32     32     64     64    64
/// ```
pub(all) enum Model {
  LP32
  ILP32
  ILP64
  LLP64
  LP64
} derive(Eq, Debug)

///|
/// Models for 32-bit systems (upstream `model32`).
pub fn Model::is_model32(self : Model) -> Bool {
  self is (LP32 | ILP32)
}

///|
/// Models for 64-bit systems (upstream `model64`).
pub fn Model::is_model64(self : Model) -> Bool {
  !self.is_model32()
}

///|
pub fn Model::to_string(self : Model) -> String {
  match self {
    LP32 => "LP32"
    ILP32 => "ILP32"
    ILP64 => "ILP64"
    LLP64 => "LLP64"
    LP64 => "LP64"
  }
}

///|
/// A value lattice.
pub(all) enum Value {
  /// Any possible value.
  Top
  /// One of the specified values; `Set([])` is bottom.
  Set(Array[@types.Word])
} derive(Eq, Debug)

///|
/// A C object representation, parameterized by the layout representation
/// so that the generalized layout type can be defined recursively.
pub(all) enum Obj[D] {
  /// A value of a basic type.
  Basic(Basic)
  /// A struct or union field.
  Field(String, D)
  /// Undefined data (padding or code).
  Undef
  /// A union of values.
  Union(Array[D])
} derive(Eq, Debug)

///|
/// An abstraction of a C datum: an immediate value of the given size, a
/// sequence of data, or a pointer to a datum.
pub(all) enum Datum[D, S] {
  /// `Imm(size, value)`
  Imm(S, D)
  /// `Seq([t1, ..., tN])`
  Seq(Array[Datum[D, S]])
  /// `Ptr(datum)`
  Ptr(Datum[D, S])
} derive(Eq, Debug)

///|
/// The layout of a C object (sizes are in bits).
pub(all) struct Layout {
  layout : Datum[Obj[Layout], Int32]
} derive(Eq, Debug)

///|
/// The datum that uses the value lattice for object representation
/// (upstream `Bap_c_data.t`).
pub type Data = Datum[Value, @types.Size]

///|
fn pp_value(buf : StringBuilder, v : Value) -> Unit {
  match v {
    Top => buf.write_string("Top")
    Set(xs) => {
      buf.write_string("{")
      for i, x in xs {
        if i > 0 {
          buf.write_string(", ")
        }
        buf.write_string(x.to_string())
      }
      buf.write_string("}")
    }
  }
}

///|
fn pp_data(buf : StringBuilder, d : Data) -> Unit {
  match d {
    Imm(sz, v) => {
      pp_value(buf, v)
      buf.write_string(":")
      buf.write_string(sz.to_string())
    }
    Seq(ts) => {
      buf.write_string("{")
      for i, t in ts {
        if i > 0 {
          buf.write_string(", ")
        }
        pp_data(buf, t)
      }
      buf.write_string("}")
    }
    Ptr(t) => {
      pp_data(buf, t)
      buf.write_string(" ptr")
    }
  }
}

///|
/// Prints the datum in a human-readable form (upstream `C.Data.pp`).
pub fn data_to_string(d : Data) -> String {
  let buf = StringBuilder()
  pp_data(buf, d)
  buf.to_string()
}

///|
fn pp_datum(buf : StringBuilder, d : Datum[Obj[Layout], Int32]) -> Unit {
  match d {
    Imm(sz, v) => {
      buf.write_string("[")
      pp_obj(buf, v)
      buf.write_string(" : \{sz}]")
    }
    Seq(objs) => {
      buf.write_string("{ ")
      for i, obj in objs {
        if i > 0 {
          buf.write_string(", ")
        }
        pp_datum(buf, obj)
      }
      buf.write_string(" }")
    }
    Ptr(t) => {
      buf.write_string("*")
      pp_datum(buf, t)
    }
  }
}

///|
fn pp_obj(buf : StringBuilder, obj : Obj[Layout]) -> Unit {
  match obj {
    Basic(t) => buf.write_string(CType::basic(t).to_string())
    Field(name, layout) => {
      buf.write_string("<\{name} : ")
      pp_datum(buf, layout.layout)
      buf.write_string(">")
    }
    Undef => buf.write_string("<undef>")
    Union(xs) =>
      for i, x in xs {
        if i > 0 {
          buf.write_string(" | ")
        }
        pp_datum(buf, x.layout)
      }
  }
}

///|
/// Outputs the layout in a human-readable form (upstream `C.Data.pp_layout`).
///
/// The upstream printer uses `hv` boxes; this rendering corresponds to the
/// case where the layout fits into a single line (all breaks are spaces).
pub fn Layout::to_string(self : Layout) -> String {
  let buf = StringBuilder()
  pp_datum(buf, self.layout)
  buf.to_string()
}

///|
pub impl Show for Layout with fn output(self, logger) {
  logger.write_string(self.to_string())
}
