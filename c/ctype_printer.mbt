// Port of the printers from `bap_c_type.ml` / `bap_c_type_printer.ml`.
//
// Upstream uses `Format` boxes. Every box around a scalar is horizontal
// (`@[<h>`), and the only vertical boxes surround structure/union bodies and
// enumerations, where every break is a newline indented by four columns. The
// renderer below reproduces that output byte-for-byte, including the
// upstream quirks (e.g., enumeration items are followed by `,,` and a
// function type is terminated with `;`).

///|
fn pp_attr(buf : StringBuilder, attr : Attr) -> Unit {
  buf.write_string(attr.name)
  if !attr.args.is_empty() {
    buf.write_string("(")
    buf.write_string(attr.args.join(", "))
    buf.write_string(")")
  }
}

///|
pub fn Attr::to_string(self : Attr) -> String {
  let buf = StringBuilder()
  pp_attr(buf, self)
  buf.to_string()
}

///|
pub impl Show for Attr with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
fn pp_attrs(buf : StringBuilder, attrs : Array[Attr]) -> Unit {
  if attrs.is_empty() {
    return
  }
  buf.write_string(" __attribute__((")
  for i, attr in attrs {
    if i > 0 {
      buf.write_string(", ")
    }
    pp_attr(buf, attr)
  }
  buf.write_string(")) ")
}

///|
fn pp_qualifier(buf : StringBuilder, name : String, flag : Bool) -> Unit {
  if flag {
    buf.write_string(" \{name} ")
  }
}

///|
fn pp_cv(buf : StringBuilder, q : Qualifier[Unit]) -> Unit {
  pp_qualifier(buf, "const", q.const_)
  pp_qualifier(buf, "volatile", q.volatile_)
}

///|
fn pp_cvr(buf : StringBuilder, q : Qualifier[Bool]) -> Unit {
  pp_qualifier(buf, "const", q.const_)
  pp_qualifier(buf, "volatile", q.volatile_)
  pp_qualifier(buf, "restrict", q.restrict)
}

///|
/// The C spelling of a basic type (upstream `string_of_basic`).
///
/// Enumerations are rendered as a vertical block that ends with a newline,
/// exactly like the upstream `Format.asprintf` call.
pub fn Basic::to_string(self : Basic) -> String {
  match self {
    SChar => "signed char"
    CDouble => "double complex"
    LongDouble => "long double"
    CFloat => "float complex"
    Float => "float"
    CLongDouble => "long double complex"
    ULongLong => "unsigned long long"
    UInt => "unsigned"
    SLong => "signed long"
    Bool => "_Bool"
    Double => "double"
    SLongLong => "signed long long"
    SShort => "signed short"
    UShort => "unsigned short"
    Char => "char"
    SInt => "signed"
    ULong => "unsigned long"
    UChar => "unsigned char"
    Enum(fields) => {
      let buf = StringBuilder()
      buf.write_string("enum {")
      for field in fields {
        let (name, value) = field
        buf.write_string("\n    ")
        buf.write_string(name)
        match value {
          None => buf.write_string(",")
          Some(v) => buf.write_string("= \{v},")
        }
        buf.write_string(",")
      }
      buf.write_string("\n}\n")
      buf.to_string()
    }
  }
}

///|
pub impl Show for Basic with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
fn pp_type(buf : StringBuilder, t : CType) -> Unit {
  match t {
    Void => buf.write_string("void")
    Array({ qualifier, t: { element, size, }, attrs, }) => {
      pp_attrs(buf, attrs)
      pp_cvr(buf, qualifier)
      pp_incomplete(buf, element)
      buf.write_string("[")
      if size is Some(n) {
        buf.write_string(n.to_string())
      }
      buf.write_string("]")
    }
    Basic({ qualifier, t, attrs, }) => {
      pp_attrs(buf, attrs)
      pp_cv(buf, qualifier)
      buf.write_string(t.to_string())
    }
    Function({ t: proto, attrs, .. }) => {
      pp_proto(buf, proto)
      pp_attrs(buf, attrs)
      buf.write_string(";")
    }
    Pointer({ qualifier, t, attrs, }) => {
      pp_attrs(buf, attrs)
      pp_incomplete(buf, t)
      pp_cvr(buf, qualifier)
      buf.write_string("*")
    }
    Structure({ t: { name, fields, }, attrs, .. }) =>
      pp_compound(buf, "struct", name, fields, attrs)
    Union({ t: { name, fields, }, attrs, .. }) =>
      pp_compound(buf, "union", name, fields, attrs)
  }
}

///|
fn pp_compound(
  buf : StringBuilder,
  kind : String,
  name : String,
  fields : Array[(String, CType)],
  attrs : Array[Attr],
) -> Unit {
  buf.write_string("\{kind} \{name} {")
  buf.write_string("\n    ")
  for i, field in fields {
    if i > 0 {
      buf.write_string("\n    ")
    }
    let (fname, ft) = field
    pp_incomplete(buf, ft)
    buf.write_string(" \{fname};")
  }
  buf.write_string("\n}")
  pp_attrs(buf, attrs)
  buf.write_string(";")
}

///|
fn pp_proto(buf : StringBuilder, proto : Proto) -> Unit {
  pp_incomplete(buf, proto.return_)
  buf.write_string(" (*)(")
  if proto.args.is_empty() {
    buf.write_string("void")
  } else {
    for i, arg in proto.args {
      if i > 0 {
        buf.write_string(", ")
      }
      let (name, t) = arg
      pp_incomplete(buf, t)
      buf.write_string(" \{name}")
    }
  }
  if proto.variadic {
    buf.write_string(", ...")
  }
  buf.write_string(")")
}

///|
fn pp_incomplete(buf : StringBuilder, t : CType) -> Unit {
  match t {
    Structure({ t: { name, .. }, .. }) => buf.write_string("struct \{name}")
    Union({ t: { name, .. }, .. }) => buf.write_string("union \{name}")
    t => pp_type(buf, t)
  }
}

///|
/// Renders the type in C syntax (upstream `C.Type.pp`).
pub fn CType::to_string(self : CType) -> String {
  let buf = StringBuilder()
  pp_type(buf, self)
  buf.to_string()
}

///|
pub impl Show for CType with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// Renders the prototype as a function pointer type (upstream
/// `C.Type.pp_proto`).
pub fn Proto::to_string(self : Proto) -> String {
  let buf = StringBuilder()
  pp_proto(buf, self)
  buf.to_string()
}

///|
pub impl Show for Proto with fn output(self, logger) {
  logger.write_string(self.to_string())
}
