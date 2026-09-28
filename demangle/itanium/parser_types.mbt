///|
/// <function-type> ::= [<CV-qualifiers>] [<exception-spec>] [Dx] F [Y]
///                     <bare-function-type> [<ref-qualifier>] E
/// <exception-spec> ::= Do                # non-throwing
///                  ::= DO <expression> E # computed noexcept
///                  ::= Dw <type>+ E      # dynamic exception specification
fn Parser::parse_function_type(self : Parser) -> Node raise Fail {
  let cv_quals = self.parse_cv_qualifiers()
  let mut exception_spec : Node? = None
  if self.consume_if("Do") {
    exception_spec = Some(name_node("noexcept"))
  } else if self.consume_if("DO") {
    let e = self.parse_expr()
    if !self.consume_if_char('E') {
      raise Fail
    }
    exception_spec = Some(make(NoexceptSpec(e)))
  } else if self.consume_if("Dw") {
    let begin = self.names.length()
    while !self.consume_if_char('E') {
      let t = self.parse_type()
      self.names.push(t)
    }
    exception_spec = Some(make(DynamicExceptionSpec(self.pop_trailing(begin))))
  }
  ignore(self.consume_if("Dx")) // transaction safe
  if !self.consume_if_char('F') {
    raise Fail
  }
  ignore(self.consume_if_char('Y')) // extern "C"
  let return_type = self.parse_type()
  let mut ref_qual = FREF_NONE
  let begin = self.names.length()
  while true {
    if self.consume_if_char('E') {
      break
    }
    if self.consume_if_char('v') {
      continue
    }
    if self.consume_if("RE") {
      ref_qual = FREF_LVALUE
      break
    }
    if self.consume_if("OE") {
      ref_qual = FREF_RVALUE
      break
    }
    let t = self.parse_type()
    self.names.push(t)
  }
  let params = self.pop_trailing(begin)
  make(FunctionType(return_type, params, cv_quals, ref_qual, exception_spec))
}

///|
/// <vector-type> ::= Dv <positive dimension number> _ <extended element type>
///               ::= Dv [<dimension expression>] _ <element type>
/// <extended element type> ::= <element type>
///                         ::= p # AltiVec vector pixel
fn Parser::parse_vector_type(self : Parser) -> Node raise Fail {
  if !self.consume_if("Dv") {
    raise Fail
  }
  let c = self.look()
  if c >= '1' && c <= '9' {
    let dimension = name_node(self.parse_number())
    if !self.consume_if_char('_') {
      raise Fail
    }
    if self.consume_if_char('p') {
      return make(PixelVectorType(dimension))
    }
    let elem = self.parse_type()
    return make(VectorType(elem, Some(dimension)))
  }
  if !self.consume_if_char('_') {
    let dim_expr = self.parse_expr()
    if !self.consume_if_char('_') {
      raise Fail
    }
    let elem = self.parse_type()
    return make(VectorType(elem, Some(dim_expr)))
  }
  let elem = self.parse_type()
  make(VectorType(elem, None))
}

///|
/// <decltype> ::= Dt <expression> E  # decltype of an id-expression
///            ::= DT <expression> E  # decltype of an expression
fn Parser::parse_decltype(self : Parser) -> Node raise Fail {
  if !self.consume_if_char('D') {
    raise Fail
  }
  if !self.consume_if_char('t') && !self.consume_if_char('T') {
    raise Fail
  }
  let e = self.parse_expr()
  if !self.consume_if_char('E') {
    raise Fail
  }
  make(EnclosingExpr("decltype", e))
}

///|
/// <array-type> ::= A <positive dimension number> _ <element type>
///              ::= A [<dimension expression>] _ <element type>
fn Parser::parse_array_type(self : Parser) -> Node raise Fail {
  if !self.consume_if_char('A') {
    raise Fail
  }
  let mut dimension : Node? = None
  if is_digit(self.look()) {
    dimension = Some(name_node(self.parse_number()))
    if !self.consume_if_char('_') {
      raise Fail
    }
  } else if !self.consume_if_char('_') {
    let dim_expr = self.parse_expr()
    if !self.consume_if_char('_') {
      raise Fail
    }
    dimension = Some(dim_expr)
  }
  let ty = self.parse_type()
  make(ArrayType(ty, dimension))
}

///|
/// <pointer-to-member-type> ::= M <class type> <member type>
fn Parser::parse_pointer_to_member_type(self : Parser) -> Node raise Fail {
  if !self.consume_if_char('M') {
    raise Fail
  }
  let class_type = self.parse_type()
  let member_type = self.parse_type()
  make(PointerToMemberType(class_type, member_type))
}

///|
/// <class-enum-type> ::= <name>
///                   ::= Ts <name>  # 'struct' or 'class'
///                   ::= Tu <name>  # 'union'
///                   ::= Te <name>  # 'enum'
fn Parser::parse_class_enum_type(self : Parser) -> Node raise Fail {
  let elab : StringView = if self.consume_if("Ts") {
    "struct"
  } else if self.consume_if("Tu") {
    "union"
  } else if self.consume_if("Te") {
    "enum"
  } else {
    ""
  }
  let name = self.parse_name()
  if elab.length() > 0 {
    make(ElaboratedTypeSpefType(elab, name))
  } else {
    name
  }
}

///|
/// <qualified-type>     ::= <qualifiers> <type>
/// <qualifiers> ::= <extended-qualifier>* <CV-qualifiers>
/// <extended-qualifier> ::= U <source-name> [<template-args>]
fn Parser::parse_qualified_type(self : Parser) -> Node raise Fail {
  self.enter()
  let node = self.parse_qualified_type_body()
  self.leave()
  node
}

///|
fn Parser::parse_qualified_type_body(self : Parser) -> Node raise Fail {
  if self.consume_if_char('U') {
    let qual = self.parse_bare_source_name()
    if qual.length() == 0 {
      raise Fail
    }
    // extension ::= U <objc-name> <objc-type>  # objc-type<identifier>
    if qual.has_prefix("objcproto") {
      let saved_first = self.first
      let saved_last = self.last
      let base = saved_first - qual.length()
      self.first = base + 9
      self.last = base + qual.length()
      let proto = self.parse_bare_source_name()
      self.first = saved_first
      self.last = saved_last
      if proto.length() == 0 {
        raise Fail
      }
      let child = self.parse_qualified_type()
      return make(ObjCProtoName(child, proto))
    }
    let args = if self.look() == 'I' {
      Some(self.parse_template_args())
    } else {
      None
    }
    let child = self.parse_qualified_type()
    return make(VendorExtQualType(child, qual, args))
  }
  let quals = self.parse_cv_qualifiers()
  let ty = self.parse_type()
  if quals != QUAL_NONE {
    make(QualType(ty, quals))
  } else {
    ty
  }
}

///|
fn builtin_type(c : UInt16) -> StringView? {
  match c {
    'v' => Some("void")
    'w' => Some("wchar_t")
    'b' => Some("bool")
    'c' => Some("char")
    'a' => Some("signed char")
    'h' => Some("unsigned char")
    's' => Some("short")
    't' => Some("unsigned short")
    'i' => Some("int")
    'j' => Some("unsigned int")
    'l' => Some("long")
    'm' => Some("unsigned long")
    'x' => Some("long long")
    'y' => Some("unsigned long long")
    'n' => Some("__int128")
    'o' => Some("unsigned __int128")
    'f' => Some("float")
    'd' => Some("double")
    'e' => Some("long double")
    'g' => Some("__float128")
    'z' => Some("...")
    _ => None
  }
}

///|
/// The fixed-point types `DA<size>` / `DR<size>`.
fn fixed_point_type(size : UInt16, fract : Bool) -> StringView? {
  let prefix = match size {
    's' => "short "
    't' => "unsigned short "
    'i' => ""
    'j' => "unsigned "
    'l' => "long "
    'm' => "unsigned long "
    _ => return None
  }
  Some(prefix + (if fract { "_Fract" } else { "_Accum" }))
}

///|
/// The two-character builtin types starting with `D`.
fn builtin_d_type(c : UInt16) -> StringView? {
  match c {
    'd' => Some("decimal64")
    'e' => Some("decimal128")
    'f' => Some("decimal32")
    'h' => Some("half")
    'i' => Some("char32_t")
    's' => Some("char16_t")
    'u' => Some("char8_t")
    'a' => Some("auto")
    'c' => Some("decltype(auto)")
    'n' => Some("std::nullptr_t")
    _ => None
  }
}

///|
/// <type> ::= <builtin-type> | <qualified-type> | <function-type>
///        ::= <class-enum-type> | <array-type> | <pointer-to-member-type>
///        ::= <template-param> | <template-template-param> <template-args>
///        ::= <decltype> | P <type> | R <type> | O <type> | C <type>
///        ::= G <type> | <substitution> | Dp <type> | <vector-type>
fn Parser::parse_type(self : Parser) -> Node raise Fail {
  self.enter()
  let node = self.parse_type_body()
  self.leave()
  node
}

///|
fn Parser::parse_type_body(self : Parser) -> Node raise Fail {
  let c = self.look()
  if builtin_type(c) is Some(name) {
    self.first += 1
    return name_node(name)
  }
  let result = match c {
    'r' | 'V' | 'K' => {
      let mut after = 0
      if self.look(ahead=after) == 'r' {
        after += 1
      }
      if self.look(ahead=after) == 'V' {
        after += 1
      }
      if self.look(ahead=after) == 'K' {
        after += 1
      }
      let next = self.look(ahead=after + 1)
      if self.look(ahead=after) == 'F' ||
        (
          self.look(ahead=after) == 'D' &&
          (next == 'o' || next == 'O' || next == 'w' || next == 'x')
        ) {
        self.parse_function_type()
      } else {
        self.parse_qualified_type()
      }
    }
    'U' => self.parse_qualified_type()
    // <builtin-type> ::= u <source-name>    # vendor extended type
    'u' => {
      self.first += 1
      let res = self.parse_bare_source_name()
      if res.length() == 0 {
        raise Fail
      }
      // Vendor extended types are substitution candidates (Itanium C++ ABI
      // 5.9.1).
      if self.consume_if_char('I') {
        let base = self.parse_type()
        if !self.consume_if_char('E') {
          raise Fail
        }
        make(TransformedType(res, base))
      } else {
        name_node(res)
      }
    }
    'D' => {
      let c1 = self.look(ahead=1)
      if builtin_d_type(c1) is Some(name) {
        self.first += 2
        return name_node(name)
      }
      match c1 {
        // ::= DF16b | DF <number> _
        'F' => {
          self.first += 2
          if self.consume_if("16b") {
            return name_node("std::bfloat16_t")
          }
          let dimension = name_node(self.parse_number())
          if !self.consume_if_char('_') {
            raise Fail
          }
          return make(BinaryFPType(dimension))
        }
        // ::= [DS] DA | [DS] DR  # N1169 fixed-point
        'A' | 'R' => {
          let size = self.look(ahead=2)
          self.first += 3
          guard fixed_point_type(size, c1 == 'R') is Some(name) else {
            raise Fail
          }
          return name_node(name)
        }
        'S' => {
          self.first += 2
          if self.look() != 'D' {
            raise Fail
          }
          let kind = self.look(ahead=1)
          if kind == 'A' || kind == 'R' {
            let size = self.look(ahead=2)
            self.first += 3
            guard fixed_point_type(size, kind == 'R') is Some(name) else {
              raise Fail
            }
            return name_node("_Sat " + name.to_owned())
          }
          raise Fail
        }
        // ::= DB <number> _ | DB <expression> _  # signed _BitInt(N)
        // ::= DU <number> _ | DU <expression> _  # unsigned _BitInt(N)
        'B' | 'U' => {
          let signed = c1 == 'B'
          self.first += 2
          let size = if is_digit(self.look()) {
            name_node(self.parse_number())
          } else {
            self.parse_expr()
          }
          if !self.consume_if_char('_') {
            raise Fail
          }
          make(BitIntType(size, signed))
        }
        // ::= Dk <type-constraint> | DK <type-constraint>
        'k' | 'K' => {
          let kind : StringView = if c1 == 'k' {
            " auto"
          } else {
            " decltype(auto)"
          }
          self.first += 2
          let constraint = self.parse_name()
          return make(PostfixQualifiedType(constraint, kind))
        }
        't' | 'T' => self.parse_decltype()
        'v' => self.parse_vector_type()
        // ::= Dp <type>       # pack expansion (C++0x)
        'p' => {
          self.first += 2
          let child = self.parse_type()
          make(ParameterPackExpansion(child))
        }
        // Exception specifiers and transaction safety on function types.
        'o' | 'O' | 'w' | 'x' => self.parse_function_type()
        _ => raise Fail
      }
    }
    'F' => self.parse_function_type()
    'A' => self.parse_array_type()
    'M' => self.parse_pointer_to_member_type()
    'T' => {
      // This could be an elaborate type specifier on a <class-enum-type>.
      let c1 = self.look(ahead=1)
      if c1 == 's' || c1 == 'u' || c1 == 'e' {
        self.parse_class_enum_type()
      } else {
        let mut result = self.parse_template_param()
        // <type> ::= <template-template-param> <template-args>
        if self.try_to_parse_template_args && self.look() == 'I' {
          self.subs.push(result)
          let args = self.parse_template_args()
          result = make(NameWithTemplateArgs(result, args))
        }
        result
      }
    }
    'P' => {
      self.first += 1
      make(PointerType(self.parse_type()))
    }
    'R' => {
      self.first += 1
      make(ReferenceType(self.parse_type(), false))
    }
    'O' => {
      self.first += 1
      make(ReferenceType(self.parse_type(), true))
    }
    'C' => {
      self.first += 1
      make(PostfixQualifiedType(self.parse_type(), " complex"))
    }
    'G' => {
      self.first += 1
      make(PostfixQualifiedType(self.parse_type(), " imaginary"))
    }
    'S' if self.look(ahead=1) != 't' => {
      let is_subst = Ref(false)
      let mut result = self.parse_unscoped_name(None, Some(is_subst))
      // <type> ::= <substitution>
      //        ::= <template-template-param> <template-args>
      if self.look() == 'I' &&
        (!is_subst.val || self.try_to_parse_template_args) {
        if !is_subst.val {
          self.subs.push(result)
        }
        let args = self.parse_template_args()
        result = make(NameWithTemplateArgs(result, args))
      } else if is_subst.val {
        // A bare substitution is not re-inserted into the table.
        return result
      }
      result
    }
    _ => self.parse_class_enum_type()
  }
  // Builtin types and bare substitutions returned early: they are not
  // substitution candidates.
  self.subs.push(result)
  result
}
