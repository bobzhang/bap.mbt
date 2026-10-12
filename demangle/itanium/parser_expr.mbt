// Operator encodings and the <expression> productions.

// Kinds of operators.

///|
/// Prefix unary: @ expr
const OP_PREFIX : Int32 = 0

///|
/// Postfix unary: expr @
const OP_POSTFIX : Int32 = 1

///|
/// Binary: lhs @ rhs
const OP_BINARY : Int32 = 2

///|
/// Array index: lhs [ rhs ]
const OP_ARRAY : Int32 = 3

///|
/// Member access: lhs @ rhs
const OP_MEMBER : Int32 = 4

///|
const OP_NEW : Int32 = 5

///|
const OP_DEL : Int32 = 6

///|
/// Function call: expr (expr*)
const OP_CALL : Int32 = 7

///|
/// C cast: (type)expr
const OP_CCAST : Int32 = 8

///|
/// Conditional: expr ? expr : expr
const OP_CONDITIONAL : Int32 = 9

///|
/// Overload only, not allowed in expressions.
const OP_NAME_ONLY : Int32 = 10

///|
/// Named cast, @<type>(expr). Kinds from here on have no operator names.
const OP_NAMED_CAST : Int32 = 11

///|
/// alignof, sizeof, typeid
const OP_OF_ID_OP : Int32 = 12

///|
const OP_UNNAMEABLE : Int32 = 11

///|
priv struct OperatorInfo {
  kind : Int32
  /// Entry-specific flag (array new/delete, parenthesized call, named
  /// member access, type operand).
  flag : Bool
  prec : Int32
  name : StringView
}

///|
/// The spelling used in expressions: the name without `operator`.
fn OperatorInfo::symbol(self : OperatorInfo) -> StringView {
  if self.kind < OP_UNNAMEABLE {
    let rest = self.name.view(start_offset=8) // drop "operator"
    if rest.length() > 0 && rest.at(0) == ' ' {
      rest.view(start_offset=1)
    } else {
      rest
    }
  } else {
    self.name
  }
}

///|
let operators : Map[String, OperatorInfo] = {
  let table : Array[(String, Int32, Bool, Int32, StringView)] = [
    ("aN", OP_BINARY, false, PREC_ASSIGN, "operator&="),
    ("aS", OP_BINARY, false, PREC_ASSIGN, "operator="),
    ("aa", OP_BINARY, false, PREC_AND_IF, "operator&&"),
    ("ad", OP_PREFIX, false, PREC_UNARY, "operator&"),
    ("an", OP_BINARY, false, PREC_AND, "operator&"),
    ("at", OP_OF_ID_OP, true, PREC_UNARY, "alignof "),
    ("aw", OP_NAME_ONLY, false, PREC_PRIMARY, "operator co_await"),
    ("az", OP_OF_ID_OP, false, PREC_UNARY, "alignof "),
    ("cc", OP_NAMED_CAST, false, PREC_POSTFIX, "const_cast"),
    ("cl", OP_CALL, false, PREC_POSTFIX, "operator()"),
    ("cm", OP_BINARY, false, PREC_COMMA, "operator,"),
    ("co", OP_PREFIX, false, PREC_UNARY, "operator~"),
    ("cp", OP_CALL, true, PREC_POSTFIX, "operator()"),
    ("cv", OP_CCAST, false, PREC_CAST, "operator"),
    ("dV", OP_BINARY, false, PREC_ASSIGN, "operator/="),
    ("da", OP_DEL, true, PREC_UNARY, "operator delete[]"),
    ("dc", OP_NAMED_CAST, false, PREC_POSTFIX, "dynamic_cast"),
    ("de", OP_PREFIX, false, PREC_UNARY, "operator*"),
    ("dl", OP_DEL, false, PREC_UNARY, "operator delete"),
    ("ds", OP_MEMBER, false, PREC_PTR_MEM, "operator.*"),
    ("dt", OP_MEMBER, false, PREC_POSTFIX, "operator."),
    ("dv", OP_BINARY, false, PREC_ASSIGN, "operator/"),
    ("eO", OP_BINARY, false, PREC_ASSIGN, "operator^="),
    ("eo", OP_BINARY, false, PREC_XOR, "operator^"),
    ("eq", OP_BINARY, false, PREC_EQUALITY, "operator=="),
    ("ge", OP_BINARY, false, PREC_RELATIONAL, "operator>="),
    ("gt", OP_BINARY, false, PREC_RELATIONAL, "operator>"),
    ("ix", OP_ARRAY, false, PREC_POSTFIX, "operator[]"),
    ("lS", OP_BINARY, false, PREC_ASSIGN, "operator<<="),
    ("le", OP_BINARY, false, PREC_RELATIONAL, "operator<="),
    ("ls", OP_BINARY, false, PREC_SHIFT, "operator<<"),
    ("lt", OP_BINARY, false, PREC_RELATIONAL, "operator<"),
    ("mI", OP_BINARY, false, PREC_ASSIGN, "operator-="),
    ("mL", OP_BINARY, false, PREC_ASSIGN, "operator*="),
    ("mi", OP_BINARY, false, PREC_ADDITIVE, "operator-"),
    ("ml", OP_BINARY, false, PREC_MULTIPLICATIVE, "operator*"),
    ("mm", OP_POSTFIX, false, PREC_POSTFIX, "operator--"),
    ("na", OP_NEW, true, PREC_UNARY, "operator new[]"),
    ("ne", OP_BINARY, false, PREC_EQUALITY, "operator!="),
    ("ng", OP_PREFIX, false, PREC_UNARY, "operator-"),
    ("nt", OP_PREFIX, false, PREC_UNARY, "operator!"),
    ("nw", OP_NEW, false, PREC_UNARY, "operator new"),
    ("oR", OP_BINARY, false, PREC_ASSIGN, "operator|="),
    ("oo", OP_BINARY, false, PREC_OR_IF, "operator||"),
    ("or", OP_BINARY, false, PREC_IOR, "operator|"),
    ("pL", OP_BINARY, false, PREC_ASSIGN, "operator+="),
    ("pl", OP_BINARY, false, PREC_ADDITIVE, "operator+"),
    ("pm", OP_MEMBER, true, PREC_PTR_MEM, "operator->*"),
    ("pp", OP_POSTFIX, false, PREC_POSTFIX, "operator++"),
    ("ps", OP_PREFIX, false, PREC_UNARY, "operator+"),
    ("pt", OP_MEMBER, true, PREC_POSTFIX, "operator->"),
    ("qu", OP_CONDITIONAL, false, PREC_CONDITIONAL, "operator?"),
    ("rM", OP_BINARY, false, PREC_ASSIGN, "operator%="),
    ("rS", OP_BINARY, false, PREC_ASSIGN, "operator>>="),
    ("rc", OP_NAMED_CAST, false, PREC_POSTFIX, "reinterpret_cast"),
    ("rm", OP_BINARY, false, PREC_MULTIPLICATIVE, "operator%"),
    ("rs", OP_BINARY, false, PREC_SHIFT, "operator>>"),
    ("sc", OP_NAMED_CAST, false, PREC_POSTFIX, "static_cast"),
    ("ss", OP_BINARY, false, PREC_SPACESHIP, "operator<=>"),
    ("st", OP_OF_ID_OP, true, PREC_UNARY, "sizeof "),
    ("sz", OP_OF_ID_OP, false, PREC_UNARY, "sizeof "),
    ("te", OP_OF_ID_OP, false, PREC_POSTFIX, "typeid "),
    ("ti", OP_OF_ID_OP, true, PREC_POSTFIX, "typeid "),
  ]
  let map : Map[String, OperatorInfo] = Map([])
  for entry in table {
    let (enc, kind, flag, prec, name) = entry
    map[enc] = { kind, flag, prec, name, }
  }
  map
}

///|
/// If the next two characters are an operator encoding, consumes them and
/// returns the operator.
fn Parser::parse_operator_encoding(self : Parser) -> OperatorInfo? {
  if self.num_left() < 2 {
    return None
  }
  let enc = self.input.unsafe_substring(start=self.first, end=self.first + 2)
  match operators.get(enc) {
    Some(op) => {
      self.first += 2
      Some(op)
    }
    None => None
  }
}

///|
fn Parser::parse_prefix_expr(
  self : Parser,
  kind : StringView,
  prec : Int32,
) -> Node raise Fail {
  let e = self.parse_expr()
  make(PrefixExpr(kind, e), prec~)
}

///|
fn Parser::parse_binary_expr(
  self : Parser,
  kind : StringView,
  prec : Int32,
) -> Node raise Fail {
  let lhs = self.parse_expr()
  let rhs = self.parse_expr()
  make(BinaryExpr(lhs, kind, rhs), prec~)
}

///|
fn Parser::parse_integer_literal(
  self : Parser,
  lit : StringView,
) -> Node raise Fail {
  let value = self.parse_number(allow_negative=true)
  if value.length() > 0 && self.consume_if_char('E') {
    make(IntegerLiteral(lit, value))
  } else {
    raise Fail
  }
}

///|
/// <function-param> ::= fp <top-level CV-Qualifiers> _
///                  ::= fp <top-level CV-Qualifiers> <parameter-2 number> _
///                  ::= fL <L-1 number> p <top-level CV-Qualifiers> _
///                  ::= fL <L-1 number> p <top-level CV-Qualifiers>
///                      <parameter-2 number> _
///                  ::= fpT      # 'this' expression
fn Parser::parse_function_param(self : Parser) -> Node raise Fail {
  if self.consume_if("fpT") {
    return name_node("this")
  }
  if self.consume_if("fp") {
    ignore(self.parse_cv_qualifiers())
    let num = self.parse_number()
    if !self.consume_if_char('_') {
      raise Fail
    }
    return make(FunctionParam(num))
  }
  if self.consume_if("fL") {
    if self.parse_number().length() == 0 {
      raise Fail
    }
    if !self.consume_if_char('p') {
      raise Fail
    }
    ignore(self.parse_cv_qualifiers())
    let num = self.parse_number()
    if !self.consume_if_char('_') {
      raise Fail
    }
    return make(FunctionParam(num))
  }
  raise Fail
}

///|
/// <expr-primary> ::= L <type> <value number> E    # integer literal
///                ::= L <type> <value float> E     # floating literal
///                ::= L <string type> E            # string literal
///                ::= L <nullptr type> E           # nullptr literal
///                ::= L <lambda type> E            # lambda expression
///                ::= L <mangled-name> E           # external name
fn Parser::parse_expr_primary(self : Parser) -> Node raise Fail {
  if !self.consume_if_char('L') {
    raise Fail
  }
  let integer = fn(lit : StringView) raise Fail {
    self.first += 1
    self.parse_integer_literal(lit)
  }
  let float = fn(kind : Int32) raise Fail {
    self.first += 1
    self.parse_floating_literal(kind)
  }
  match self.look() {
    'w' => integer("wchar_t")
    'b' => {
      if self.consume_if("b0E") {
        return make(BoolExpr(false))
      }
      if self.consume_if("b1E") {
        return make(BoolExpr(true))
      }
      raise Fail
    }
    'c' => integer("char")
    'a' => integer("signed char")
    'h' => integer("unsigned char")
    's' => integer("short")
    't' => integer("unsigned short")
    'i' => integer("")
    'j' => integer("u")
    'l' => integer("l")
    'm' => integer("ul")
    'x' => integer("ll")
    'y' => integer("ull")
    'n' => integer("__int128")
    'o' => integer("unsigned __int128")
    'f' => float(FLOAT_FLOAT)
    'd' => float(FLOAT_DOUBLE)
    'e' => float(FLOAT_LONG_DOUBLE)
    '_' => {
      if self.consume_if("_Z") {
        let r = self.parse_encoding()
        if self.consume_if_char('E') {
          return r
        }
      }
      raise Fail
    }
    'A' => {
      let t = self.parse_type()
      // The string contents are not part of the mangling.
      if self.consume_if_char('E') {
        make(StringLiteral(t))
      } else {
        raise Fail
      }
    }
    'D' => {
      if self.consume_if("Dn") {
        ignore(self.consume_if_char('0'))
        if self.consume_if_char('E') {
          return name_node("nullptr")
        }
      }
      raise Fail
    }
    // Invalid mangled name per
    // http://sourcerytools.com/pipermail/cxx-abi-dev/2011-August/002422.html
    'T' => raise Fail
    'U' => {
      if self.look(ahead=1) != 'l' {
        raise Fail
      }
      let t = self.parse_unnamed_type_name(None)
      if !self.consume_if_char('E') {
        raise Fail
      }
      make(LambdaExpr(t))
    }
    _ => {
      // might be named type
      let t = self.parse_type()
      let n = self.parse_number(allow_negative=true)
      if n.length() == 0 || !self.consume_if_char('E') {
        raise Fail
      }
      make(EnumLiteral(t, n))
    }
  }
}

///|
/// The number of hexadecimal digits of a floating-point literal. `long
/// double` follows the reference host (64-bit `long double`).
fn float_mangled_size(kind : Int32) -> Int32 {
  match kind {
    FLOAT_FLOAT => 8
    _ => 16
  }
}

///|
fn Parser::parse_floating_literal(
  self : Parser,
  kind : Int32,
) -> Node raise Fail {
  let n = float_mangled_size(kind)
  if self.num_left() <= n {
    raise Fail
  }
  let data = self.slice(self.first, self.first + n)
  for i in 0..<n {
    let c = data.at(i)
    if !is_digit(c) && !(c >= 'a' && c <= 'f') {
      raise Fail
    }
  }
  self.first += n
  if !self.consume_if_char('E') {
    raise Fail
  }
  make(FloatLiteral(data, kind))
}

///|
/// <braced-expression> ::= <expression>
///                     ::= di <field source-name> <braced-expression>
///                     ::= dx <index expression> <braced-expression>
///                     ::= dX <range begin expression>
///                         <range end expression> <braced-expression>
fn Parser::parse_braced_expr(self : Parser) -> Node raise Fail {
  self.enter()
  let node = self.parse_braced_expr_body()
  self.leave()
  node
}

///|
fn Parser::parse_braced_expr_body(self : Parser) -> Node raise Fail {
  if self.look() == 'd' {
    match self.look(ahead=1) {
      'i' => {
        self.first += 2
        let field = self.parse_source_name()
        let init = self.parse_braced_expr()
        return make(BracedExpr(field, init, false))
      }
      'x' => {
        self.first += 2
        let index = self.parse_expr()
        let init = self.parse_braced_expr()
        return make(BracedExpr(index, init, true))
      }
      'X' => {
        self.first += 2
        let range_begin = self.parse_expr()
        let range_end = self.parse_expr()
        let init = self.parse_braced_expr()
        return make(BracedRangeExpr(range_begin, range_end, init))
      }
      _ => ()
    }
  }
  self.parse_expr()
}

///|
/// <fold-expr> ::= fL <binary-operator-name> <expression> <expression>
///             ::= fR <binary-operator-name> <expression> <expression>
///             ::= fl <binary-operator-name> <expression>
///             ::= fr <binary-operator-name> <expression>
fn Parser::parse_fold_expr(self : Parser) -> Node raise Fail {
  if !self.consume_if_char('f') {
    raise Fail
  }
  let (is_left_fold, has_initializer) = match self.look() {
    'L' => (true, true)
    'R' => (false, true)
    'l' => (true, false)
    'r' => (false, false)
    _ => raise Fail
  }
  self.first += 1
  guard self.parse_operator_encoding() is Some(op) else { raise Fail }
  let name = op.name
  if !(op.kind == OP_BINARY ||
    (
      op.kind == OP_MEMBER &&
      name.length() > 0 &&
      name.at(name.length() - 1) == '*'
    )) {
    raise Fail
  }
  let mut pack = self.parse_expr()
  let mut init : Node? = None
  if has_initializer {
    init = Some(self.parse_expr())
  }
  if is_left_fold && init is Some(i) {
    init = Some(pack)
    pack = i
  }
  make(FoldExpr(is_left_fold, op.symbol(), pack, init))
}

///|
/// <expression> ::= mc <parameter type> <expr> [<offset number>] E
fn Parser::parse_pointer_to_member_conversion_expr(
  self : Parser,
  prec : Int32,
) -> Node raise Fail {
  let ty = self.parse_type()
  let expr = self.parse_expr()
  let offset = self.parse_number(allow_negative=true)
  if !self.consume_if_char('E') {
    raise Fail
  }
  ignore(offset)
  make(PointerToMemberConversionExpr(ty, expr), prec~)
}

///|
/// <expression> ::= so <referent type> <expr> [<offset number>]
///                  <union-selector>* [p] E
/// <union-selector> ::= _ [<number>]
fn Parser::parse_subobject_expr(self : Parser) -> Node raise Fail {
  let ty = self.parse_type()
  let expr = self.parse_expr()
  let offset = self.parse_number(allow_negative=true)
  let begin = self.names.length()
  while self.consume_if_char('_') {
    self.names.push(name_node(self.parse_number()))
  }
  let one_past_the_end = self.consume_if_char('p')
  if !self.consume_if_char('E') {
    raise Fail
  }
  // The union selectors and the one-past-the-end flag are not printed.
  ignore(self.pop_trailing(begin))
  ignore(one_past_the_end)
  make(SubobjectExpr(ty, expr, offset))
}

///|
fn Parser::parse_constraint_expr(self : Parser) -> Node raise Fail {
  // Within this expression, all enclosing template parameter lists are in
  // scope.
  let saved = self.has_incomplete_template_parameter_tracking
  self.has_incomplete_template_parameter_tracking = true
  let e = self.parse_expr()
  self.has_incomplete_template_parameter_tracking = saved
  e
}

///|
/// <expression> ::= rQ <bare-function-type> _ <requirement>+ E
///              ::= rq <requirement>+ E
fn Parser::parse_requires_expr(self : Parser) -> Node raise Fail {
  let mut params : Array[Node] = []
  if self.consume_if("rQ") {
    let begin = self.names.length()
    while !self.consume_if_char('_') {
      let t = self.parse_type()
      self.names.push(t)
    }
    params = self.pop_trailing(begin)
  } else if !self.consume_if("rq") {
    raise Fail
  }
  let begin = self.names.length()
  while true {
    let constraint = if self.consume_if_char('X') {
      // <requirement> ::= X <expression> [N] [R <type-constraint>]
      let expr = self.parse_expr()
      let is_noexcept = self.consume_if_char('N')
      let type_req = if self.consume_if_char('R') {
        Some(self.parse_name())
      } else {
        None
      }
      make(ExprRequirement(expr, is_noexcept, type_req))
    } else if self.consume_if_char('T') {
      // <requirement> ::= T <type>
      make(TypeRequirement(self.parse_type()))
    } else if self.consume_if_char('Q') {
      // <requirement> ::= Q <constraint-expression>
      make(NestedRequirement(self.parse_expr()))
    } else {
      raise Fail
    }
    self.names.push(constraint)
    if self.consume_if_char('E') {
      break
    }
  }
  make(RequiresExpr(params, self.pop_trailing(begin)))
}

///|
/// <expression> (see the Itanium C++ ABI for the full grammar).
fn Parser::parse_expr(self : Parser) -> Node raise Fail {
  self.enter()
  let node = self.parse_expr_body()
  self.leave()
  node
}

///|
fn Parser::parse_expr_body(self : Parser) -> Node raise Fail {
  let global = self.consume_if("gs")
  if self.parse_operator_encoding() is Some(op) {
    let sym = op.symbol()
    let prec = op.prec
    match op.kind {
      OP_BINARY => return self.parse_binary_expr(sym, prec)
      OP_PREFIX => return self.parse_prefix_expr(sym, prec)
      OP_POSTFIX => {
        if self.consume_if_char('_') {
          return self.parse_prefix_expr(sym, prec)
        }
        let ex = self.parse_expr()
        return make(PostfixExpr(ex, sym), prec~)
      }
      OP_ARRAY => {
        let base = self.parse_expr()
        let index = self.parse_expr()
        return make(ArraySubscriptExpr(base, index), prec~)
      }
      OP_MEMBER => {
        let lhs = self.parse_expr()
        let rhs = self.parse_expr()
        return make(MemberExpr(lhs, sym, rhs), prec~)
      }
      OP_NEW => {
        // [gs] nw <expression>* _ <type> [pi <expression>*] E
        let exprs = self.names.length()
        while !self.consume_if_char('_') {
          let ex = self.parse_expr()
          self.names.push(ex)
        }
        let expr_list = self.pop_trailing(exprs)
        let ty = self.parse_type()
        let have_inits = self.consume_if("pi")
        let inits_begin = self.names.length()
        while !self.consume_if_char('E') {
          if !have_inits {
            raise Fail
          }
          let init = self.parse_expr()
          self.names.push(init)
        }
        let inits = self.pop_trailing(inits_begin)
        return make(NewExpr(expr_list, ty, inits, global, op.flag), prec~)
      }
      OP_DEL => {
        let ex = self.parse_expr()
        return make(DeleteExpr(ex, global, op.flag), prec~)
      }
      OP_CALL => {
        let callee = self.parse_expr()
        let begin = self.names.length()
        while !self.consume_if_char('E') {
          let e = self.parse_expr()
          self.names.push(e)
        }
        return make(CallExpr(callee, self.pop_trailing(begin), op.flag), prec~)
      }
      OP_CCAST => {
        // C Cast: (type)expr
        let saved = self.try_to_parse_template_args
        self.try_to_parse_template_args = false
        let ty = self.parse_type()
        self.try_to_parse_template_args = saved
        let begin = self.names.length()
        let is_many = self.consume_if_char('_')
        while !self.consume_if_char('E') {
          let e = self.parse_expr()
          self.names.push(e)
          if !is_many {
            break
          }
        }
        let exprs = self.pop_trailing(begin)
        if !is_many && exprs.length() != 1 {
          raise Fail
        }
        return make(ConversionExpr(ty, exprs), prec~)
      }
      OP_CONDITIONAL => {
        let cond = self.parse_expr()
        let lhs = self.parse_expr()
        let rhs = self.parse_expr()
        return make(ConditionalExpr(cond, lhs, rhs), prec~)
      }
      OP_NAMED_CAST => {
        let ty = self.parse_type()
        let ex = self.parse_expr()
        return make(CastExpr(sym, ty, ex), prec~)
      }
      OP_OF_ID_OP => {
        // [sizeof/alignof/typeid] ( <type>|<expr> )
        let arg = if op.flag { self.parse_type() } else { self.parse_expr() }
        return make(EnclosingExpr(sym, arg), prec~)
      }
      _ => raise Fail // not valid as an expression operand
    }
  }
  if self.num_left() < 2 {
    raise Fail
  }
  if self.look() == 'L' {
    return self.parse_expr_primary()
  }
  if self.look() == 'T' {
    return self.parse_template_param()
  }
  if self.look() == 'f' {
    // Disambiguate a fold expression from a <function-param>.
    if self.look(ahead=1) == 'p' ||
      (self.look(ahead=1) == 'L' && is_digit(self.look(ahead=2))) {
      return self.parse_function_param()
    }
    return self.parse_fold_expr()
  }
  if self.consume_if("il") {
    let begin = self.names.length()
    while !self.consume_if_char('E') {
      let e = self.parse_braced_expr()
      self.names.push(e)
    }
    return make(InitListExpr(None, self.pop_trailing(begin)))
  }
  if self.consume_if("mc") {
    return self.parse_pointer_to_member_conversion_expr(PREC_UNARY)
  }
  if self.consume_if("nx") {
    let ex = self.parse_expr()
    return make(EnclosingExpr("noexcept ", ex), prec=PREC_UNARY)
  }
  if self.look() == 'r' &&
    (self.look(ahead=1) == 'q' || self.look(ahead=1) == 'Q') {
    return self.parse_requires_expr()
  }
  if self.consume_if("so") {
    return self.parse_subobject_expr()
  }
  if self.consume_if("sp") {
    let child = self.parse_expr()
    return make(ParameterPackExpansion(child))
  }
  if self.consume_if("sZ") {
    if self.look() == 'T' {
      let r = self.parse_template_param()
      return make(SizeofParamPackExpr(r))
    }
    let fp = self.parse_function_param()
    return make(EnclosingExpr("sizeof... ", fp))
  }
  if self.consume_if("sP") {
    let begin = self.names.length()
    while !self.consume_if_char('E') {
      let arg = self.parse_template_arg()
      self.names.push(arg)
    }
    let pack = make(NodeArrayNode(self.pop_trailing(begin)))
    return make(EnclosingExpr("sizeof... ", pack))
  }
  if self.consume_if("tl") {
    let ty = self.parse_type()
    let begin = self.names.length()
    while !self.consume_if_char('E') {
      let e = self.parse_braced_expr()
      self.names.push(e)
    }
    return make(InitListExpr(Some(ty), self.pop_trailing(begin)))
  }
  if self.consume_if("tr") {
    return name_node("throw")
  }
  if self.consume_if("tw") {
    let ex = self.parse_expr()
    return make(ThrowExpr(ex))
  }
  if self.consume_if_char('u') {
    let name = self.parse_source_name()
    // Special case legacy __uuidof mangling. The 't' and 'z' appear where
    // the standard encoding expects a <template-arg>.
    let mut uuid : Node? = None
    if name.base_name() == "__uuidof" {
      if self.consume_if_char('t') {
        uuid = Some(self.parse_type())
      } else if self.consume_if_char('z') {
        uuid = Some(self.parse_expr())
      }
    }
    let begin = self.names.length()
    match uuid {
      Some(uuid) => self.names.push(uuid)
      None =>
        while !self.consume_if_char('E') {
          let e = self.parse_template_arg()
          self.names.push(e)
        }
    }
    return make(
      CallExpr(name, self.pop_trailing(begin), false),
      prec=PREC_POSTFIX,
    )
  }
  // Only unresolved names remain.
  self.parse_unresolved_name(global)
}
