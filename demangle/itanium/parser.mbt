// The recursive-descent parser of Itanium C++ ABI manglings (a port of
// LLVM's `AbstractManglingParser`). A parse failure raises `Fail`; the
// parser never backtracks, so a failure rejects the whole name.

///|
priv suberror Fail

///|
/// Extra information about a <name> that is only relevant if the name
/// refers to an <encoding>.
priv struct NameState {
  mut ctor_dtor_conversion : Bool
  mut ends_with_template_args : Bool
  mut cv_qualifiers : Int
  mut reference_qualifier : Int
  forward_template_refs_begin : Int
  mut has_explicit_object_parameter : Bool
}

///|
priv struct Parser {
  input : String
  mut first : Int
  mut last : Int
  /// Temporary names collapsed into array nodes.
  names : Array[Node]
  /// The substitution table (`S_`, `S0_`, ...).
  subs : Array[Node]
  /// The template arguments of the outermost template-args (`T_`, ...).
  mut outer_template_params : Array[Node]
  /// Template parameter lists by depth (`TL<n>_...`); element 0 is always
  /// `outer_template_params` when nonempty. `None` stands for a generic
  /// lambda without an explicit template parameter list.
  mut template_params : Array[Array[Node]?]
  /// Unresolved forward <template-param> references (in conversion
  /// operator types), resolved in the enclosing <encoding>.
  forward_template_refs : Array[Node]
  mut try_to_parse_template_args : Bool
  mut permit_forward_template_references : Bool
  mut has_incomplete_template_parameter_tracking : Bool
  mut parsing_lambda_params_at_level : Int
  num_synthetic_template_parameters : FixedArray[Int]
}

///|
fn Parser::new(input : String) -> Parser {
  {
    input,
    first: 0,
    last: input.length(),
    names: [],
    subs: [],
    outer_template_params: [],
    template_params: [],
    forward_template_refs: [],
    try_to_parse_template_args: true,
    permit_forward_template_references: false,
    has_incomplete_template_parameter_tracking: false,
    parsing_lambda_params_at_level: -1,
    num_synthetic_template_parameters: FixedArray::make(3, 0),
  }
}

///|
fn NameState::new(parser : Parser) -> NameState {
  {
    ctor_dtor_conversion: false,
    ends_with_template_args: false,
    cv_qualifiers: QUAL_NONE,
    reference_qualifier: FREF_NONE,
    forward_template_refs_begin: parser.forward_template_refs.length(),
    has_explicit_object_parameter: false,
  }
}

///|
fn is_digit(c : UInt16) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn Parser::look(self : Parser, ahead? : Int = 0) -> UInt16 {
  if self.last - self.first <= ahead {
    0
  } else {
    self.input[self.first + ahead]
  }
}

///|
fn Parser::num_left(self : Parser) -> Int {
  self.last - self.first
}

///|
fn Parser::consume(self : Parser) -> UInt16 {
  if self.first < self.last {
    let c = self.input[self.first]
    self.first += 1
    c
  } else {
    0
  }
}

///|
fn Parser::consume_if(self : Parser, s : StringView) -> Bool {
  let n = s.length()
  if self.last - self.first < n {
    return false
  }
  for i in 0..<n {
    if self.input[self.first + i] != s.at(i) {
      return false
    }
  }
  self.first += n
  true
}

///|
fn Parser::consume_if_char(self : Parser, c : UInt16) -> Bool {
  if self.first < self.last && self.input[self.first] == c {
    self.first += 1
    true
  } else {
    false
  }
}

///|
fn Parser::slice(self : Parser, start : Int, end : Int) -> StringView {
  self.input.view(start_offset=start, end_offset=end)
}

///|
/// Collects the names pushed since `from` into an array.
fn Parser::pop_trailing(self : Parser, from : Int) -> Array[Node] {
  let result = self.names[from:].to_owned()
  self.names.truncate(from)
  result
}

///|
/// <number> ::= [n] <non-negative decimal integer>
fn Parser::parse_number(
  self : Parser,
  allow_negative? : Bool = false,
) -> StringView {
  let start = self.first
  if allow_negative {
    ignore(self.consume_if_char('n'))
  }
  if self.num_left() == 0 || !is_digit(self.look()) {
    return ""
  }
  while self.num_left() != 0 && is_digit(self.look()) {
    self.first += 1
  }
  self.slice(start, self.first)
}

///|
/// A saturating bound for parsed sizes (any larger value is out of range).
const SIZE_LIMIT : Int64 = 1000000000000L

///|
/// <positive length number> ::= [0-9]*
fn Parser::parse_positive_integer(self : Parser) -> Int64? {
  if !is_digit(self.look()) {
    return None
  }
  let mut out = 0L
  while is_digit(self.look()) {
    let digit = (self.consume() - '0').to_int64()
    out = out * 10 + digit
    if out > SIZE_LIMIT {
      out = SIZE_LIMIT
    }
  }
  Some(out)
}

///|
fn Parser::parse_bare_source_name(self : Parser) -> StringView {
  guard self.parse_positive_integer() is Some(n) &&
    n <= self.num_left().to_int64() else {
    return ""
  }
  let start = self.first
  self.first += n.to_int()
  self.slice(start, self.first)
}

///|
/// <CV-Qualifiers> ::= [r] [V] [K]
fn Parser::parse_cv_qualifiers(self : Parser) -> Int {
  let mut cvr = QUAL_NONE
  if self.consume_if_char('r') {
    cvr = cvr | QUAL_RESTRICT
  }
  if self.consume_if_char('V') {
    cvr = cvr | QUAL_VOLATILE
  }
  if self.consume_if_char('K') {
    cvr = cvr | QUAL_CONST
  }
  cvr
}

///|
/// <seq-id> ::= <0-9A-Z>+
fn Parser::parse_seq_id(self : Parser) -> Int64? {
  let c = self.look()
  if !is_digit(c) && !(c >= 'A' && c <= 'Z') {
    return None
  }
  let mut id = 0L
  while true {
    let c = self.look()
    if is_digit(c) {
      id = id * 36 + (c - '0').to_int64()
    } else if c >= 'A' && c <= 'Z' {
      id = id * 36 + (c - 'A').to_int64() + 10
    } else {
      break
    }
    if id > SIZE_LIMIT {
      id = SIZE_LIMIT
    }
    self.first += 1
  }
  Some(id)
}

///|
/// Parses but ignores a <discriminator>:
///   _ <non-negative number>      # when number < 10
///   __ <non-negative number> _   # when number >= 10
///   decimal-digit+               # extension, at the end of the string
fn Parser::skip_discriminator(self : Parser) -> Unit {
  let input = self.input
  let last = self.last
  let first = self.first
  if first == last {
    return
  }
  if input[first] == '_' {
    let mut t1 = first + 1
    if t1 != last {
      if is_digit(input[t1]) {
        self.first = t1 + 1
      } else if input[t1] == '_' {
        t1 += 1
        while t1 != last && is_digit(input[t1]) {
          t1 += 1
        }
        if t1 != last && input[t1] == '_' {
          self.first = t1 + 1
        }
      }
    }
  } else if is_digit(input[first]) {
    let mut t1 = first + 1
    while t1 != last && is_digit(input[t1]) {
      t1 += 1
    }
    if t1 == last {
      self.first = last
    }
  }
}

///|
/// Runs `f` with the template parameters of an enclosing context hidden
/// (upstream `SaveTemplateParams`).
fn[T] Parser::with_saved_template_params(
  self : Parser,
  f : () -> T raise Fail,
) -> T raise Fail {
  let old_params = self.template_params
  let old_outer = self.outer_template_params
  self.template_params = []
  self.outer_template_params = []
  let result = f()
  self.template_params = old_params
  self.outer_template_params = old_outer
  result
}

///|
fn Parser::resolve_forward_template_refs(
  self : Parser,
  state : NameState,
) -> Unit raise Fail {
  let begin = state.forward_template_refs_begin
  for i in begin..<self.forward_template_refs.length() {
    guard self.forward_template_refs[i].kind
      is ForwardTemplateReference(idx, target) else {
      raise Fail
    }
    guard self.template_params.get(0) is Some(Some(params)) &&
      idx < params.length() else {
      raise Fail
    }
    target.val = Some(params[idx])
  }
  self.forward_template_refs.truncate(begin)
}

///|
/// <name> ::= <nested-name>
///        ::= <local-name>
///        ::= <unscoped-template-name> <template-args>
///        ::= <unscoped-name>
fn Parser::parse_name(
  self : Parser,
  state? : NameState? = None,
) -> Node raise Fail {
  if self.look() == 'N' {
    return self.parse_nested_name(state)
  }
  if self.look() == 'Z' {
    return self.parse_local_name(state)
  }
  let is_subst = Ref(false)
  let mut result = self.parse_unscoped_name(state, Some(is_subst))
  if self.look() == 'I' {
    // An unscoped-template-name is substitutable.
    if !is_subst.val {
      self.subs.push(result)
    }
    let args = self.parse_template_args(tag_templates=state is Some(_))
    if state is Some(state) {
      state.ends_with_template_args = true
    }
    result = make(NameWithTemplateArgs(result, args))
  } else if is_subst.val {
    // The substitution case must be followed by <template-args>.
    raise Fail
  }
  result
}

///|
/// <local-name> := Z <function encoding> E <entity name> [<discriminator>]
///              := Z <function encoding> E s [<discriminator>]
///              := Z <function encoding> Ed [ <parameter number> ] _ <entity name>
fn Parser::parse_local_name(
  self : Parser,
  state : NameState?,
) -> Node raise Fail {
  if !self.consume_if_char('Z') {
    raise Fail
  }
  let encoding = self.parse_encoding()
  if !self.consume_if_char('E') {
    raise Fail
  }
  if self.consume_if_char('s') {
    self.skip_discriminator()
    return make(LocalName(encoding, name_node("string literal")))
  }
  // The template parameters of the inner name are unrelated to those of
  // the enclosing context.
  self.with_saved_template_params(() => {
    if self.consume_if_char('d') {
      ignore(self.parse_number(allow_negative=true))
      if !self.consume_if_char('_') {
        raise Fail
      }
      let name = self.parse_name(state~)
      return make(LocalName(encoding, name))
    }
    let entity = self.parse_name(state~)
    self.skip_discriminator()
    make(LocalName(encoding, entity))
  })
}

///|
/// <unscoped-name> ::= <unqualified-name>
///                 ::= St <unqualified-name>   # ::std::
fn Parser::parse_unscoped_name(
  self : Parser,
  state : NameState?,
  is_subst : Ref[Bool]?,
) -> Node raise Fail {
  let std = if self.consume_if("St") { Some(name_node("std")) } else { None }
  let mut result : Node? = None
  let mut modname : Node? = None
  if self.look() == 'S' {
    let s = self.parse_substitution()
    if s.kind is ModuleName(_, _, _) {
      modname = Some(s)
    } else if is_subst is Some(flag) && std is None {
      result = Some(s)
      flag.val = true
    } else {
      raise Fail
    }
  }
  match (result, std) {
    (Some(result), None) => result
    _ => self.parse_unqualified_name(state, std, modname)
  }
}

///|
/// <unqualified-name> ::= [<module-name>] F? L? <operator-name> [<abi-tags>]
///                    ::= [<module-name>] <ctor-dtor-name> [<abi-tags>]
///                    ::= [<module-name>] F? L? <source-name> [<abi-tags>]
///                    ::= [<module-name>] L? <unnamed-type-name> [<abi-tags>]
///                    ::= [<module-name>] L? DC <source-name>+ E
fn Parser::parse_unqualified_name(
  self : Parser,
  state : NameState?,
  scope : Node?,
  modname : Node?,
) -> Node raise Fail {
  let modname = self.parse_module_name_opt(modname)
  let is_member_like_friend = scope is Some(_) && self.consume_if_char('F')
  ignore(self.consume_if_char('L'))
  let c = self.look()
  let mut scope = scope
  let mut result = if c >= '1' && c <= '9' {
    self.parse_source_name()
  } else if c == 'U' {
    self.parse_unnamed_type_name(state)
  } else if self.consume_if("DC") {
    // Structured binding.
    let begin = self.names.length()
    while true {
      let binding = self.parse_source_name()
      self.names.push(binding)
      if self.consume_if_char('E') {
        break
      }
    }
    make(StructuredBindingName(self.pop_trailing(begin)))
  } else if c == 'C' || c == 'D' {
    // A <ctor-dtor-name>.
    guard scope is Some(sofar) && modname is None else { raise Fail }
    let (sofar, name) = self.parse_ctor_dtor_name(sofar, state)
    scope = Some(sofar)
    name
  } else {
    self.parse_operator_name(state)
  }
  if modname is Some(modname) {
    result = make(ModuleEntity(modname, result))
  }
  result = self.parse_abi_tags(result)
  match scope {
    Some(scope) if is_member_like_friend =>
      make(MemberLikeFriendName(scope, result))
    Some(scope) => make(NestedName(scope, result))
    None => result
  }
}

///|
/// <module-name> ::= <module-subname>
///               ::= <module-name> <module-subname>
///               ::= <substitution>  # passed in by caller
/// <module-subname> ::= W <source-name>
///                  ::= W P <source-name>
fn Parser::parse_module_name_opt(
  self : Parser,
  modname : Node?,
) -> Node? raise Fail {
  let mut modname = modname
  while self.consume_if_char('W') {
    let is_partition = self.consume_if_char('P')
    let sub = self.parse_source_name()
    let m = make(ModuleName(modname, sub, is_partition))
    modname = Some(m)
    self.subs.push(m)
  }
  modname
}

///|
/// <unnamed-type-name> ::= Ut [<nonnegative number>] _
///                     ::= <closure-type-name>
/// <closure-type-name> ::= Ul <lambda-sig> E [ <nonnegative number> ] _
/// <lambda-sig> ::= <template-param-decl>* [Q <requires-clause expression>]
///                  <parameter type>+  # or "v" if the lambda has no parameters
fn Parser::parse_unnamed_type_name(
  self : Parser,
  state : NameState?,
) -> Node raise Fail {
  // <template-params> refer to the innermost <template-args>. Clear out
  // any outer args that we may have inserted into TemplateParams.
  if state is Some(_) {
    self.template_params.clear()
  }
  if self.consume_if("Ut") {
    let count = self.parse_number()
    if !self.consume_if_char('_') {
      raise Fail
    }
    return make(UnnamedTypeName(count))
  }
  if self.consume_if("Ul") {
    let saved_level = self.parsing_lambda_params_at_level
    self.parsing_lambda_params_at_level = self.template_params.length()
    let old_num_lists = self.template_params.length()
    let lambda_params : Array[Node] = []
    self.template_params.push(Some(lambda_params))
    let params_begin = self.names.length()
    while self.is_template_param_decl() {
      let t = self.parse_template_param_decl(Some(lambda_params))
      self.names.push(t)
    }
    let temp_params = self.pop_trailing(params_begin)
    if temp_params.is_empty() {
      ignore(self.template_params.pop())
    }
    let requires1 = if self.consume_if_char('Q') {
      Some(self.parse_constraint_expr())
    } else {
      None
    }
    if !self.consume_if_char('v') {
      while true {
        let p = self.parse_type()
        self.names.push(p)
        if self.look() == 'E' || self.look() == 'Q' {
          break
        }
      }
    }
    let params = self.pop_trailing(params_begin)
    let requires2 = if self.consume_if_char('Q') {
      Some(self.parse_constraint_expr())
    } else {
      None
    }
    if !self.consume_if_char('E') {
      raise Fail
    }
    let count = self.parse_number()
    if !self.consume_if_char('_') {
      raise Fail
    }
    if self.template_params.length() > old_num_lists {
      self.template_params.truncate(old_num_lists)
    }
    self.parsing_lambda_params_at_level = saved_level
    return make(
      ClosureTypeName(temp_params, requires1, params, requires2, count),
    )
  }
  if self.consume_if("Ub") {
    ignore(self.parse_number())
    if !self.consume_if_char('_') {
      raise Fail
    }
    return name_node("'block-literal'")
  }
  raise Fail
}

///|
/// <source-name> ::= <positive length number> <identifier>
fn Parser::parse_source_name(self : Parser) -> Node raise Fail {
  guard self.parse_positive_integer() is Some(length) else { raise Fail }
  if self.num_left().to_int64() < length || length == 0L {
    raise Fail
  }
  let start = self.first
  self.first += length.to_int()
  let name = self.slice(start, self.first)
  if name.has_prefix("_GLOBAL__N") {
    name_node("(anonymous namespace)")
  } else {
    name_node(name)
  }
}

///|
/// <operator-name> ::= See parse_operator_encoding()
///                 ::= li <source-name>  # operator ""
///                 ::= v <digit> <source-name>  # vendor extended operator
fn Parser::parse_operator_name(
  self : Parser,
  state : NameState?,
) -> Node raise Fail {
  if self.parse_operator_encoding() is Some(op) {
    if op.kind == OP_CCAST {
      // ::= cv <type>    # (cast)
      let saved_try = self.try_to_parse_template_args
      let saved_permit = self.permit_forward_template_references
      self.try_to_parse_template_args = false
      // If we're parsing an encoding, the conversion operator's <type>
      // could have a <template-param> that refers to some <template-arg>s
      // further ahead in the mangled name.
      self.permit_forward_template_references = saved_permit || state is Some(_)
      let ty = self.parse_type()
      self.try_to_parse_template_args = saved_try
      self.permit_forward_template_references = saved_permit
      if state is Some(state) {
        state.ctor_dtor_conversion = true
      }
      return make(ConversionOperatorType(ty))
    }
    if op.kind >= OP_UNNAMEABLE {
      raise Fail
    }
    if op.kind == OP_MEMBER && !op.flag {
      raise Fail
    }
    return name_node(op.name)
  }
  if self.consume_if("li") {
    // ::= li <source-name>  # operator ""
    return make(LiteralOperator(self.parse_source_name()))
  }
  if self.consume_if_char('v') {
    // ::= v <digit> <source-name>        # vendor extended operator
    if is_digit(self.look()) {
      self.first += 1
      return make(ConversionOperatorType(self.parse_source_name()))
    }
  }
  raise Fail
}

///|
/// <ctor-dtor-name> ::= C1 | C2 | C3 | C4 | C5 | CI1 <type> | CI2 <type>
///                  ::= D0 | D1 | D2 | D4 | D5
/// Returns the (possibly expanded) scope and the name.
fn Parser::parse_ctor_dtor_name(
  self : Parser,
  sofar : Node,
  state : NameState?,
) -> (Node, Node) raise Fail {
  let sofar = match sofar.kind {
    // Expand the special substitution.
    SpecialSubstitution(ssk) => make(ExpandedSpecialSubstitution(ssk))
    _ => sofar
  }
  if self.consume_if_char('C') {
    let is_inherited = self.consume_if_char('I')
    let c = self.look()
    if c < '1' || c > '5' {
      raise Fail
    }
    self.first += 1
    if state is Some(state) {
      state.ctor_dtor_conversion = true
    }
    if is_inherited {
      ignore(self.parse_name(state~))
    }
    return (sofar, make(CtorDtorName(sofar, false)))
  }
  let c1 = self.look(ahead=1)
  if self.look() == 'D' &&
    (c1 == '0' || c1 == '1' || c1 == '2' || c1 == '4' || c1 == '5') {
    self.first += 2
    if state is Some(state) {
      state.ctor_dtor_conversion = true
    }
    return (sofar, make(CtorDtorName(sofar, true)))
  }
  raise Fail
}

///|
/// <nested-name> ::= N [<CV-Qualifiers>] [<ref-qualifier>] <prefix>
///                   <unqualified-name> E
///               ::= N [<CV-Qualifiers>] [<ref-qualifier>] <template-prefix>
///                   <template-args> E
fn Parser::parse_nested_name(
  self : Parser,
  state : NameState?,
) -> Node raise Fail {
  if !self.consume_if_char('N') {
    raise Fail
  }
  // 'H' specifies that the encoding that follows has an explicit object
  // parameter.
  if !self.consume_if_char('H') {
    let cv = self.parse_cv_qualifiers()
    let ref_qual = if self.consume_if_char('O') {
      FREF_RVALUE
    } else if self.consume_if_char('R') {
      FREF_LVALUE
    } else {
      FREF_NONE
    }
    if state is Some(state) {
      state.cv_qualifiers = cv
      state.reference_qualifier = ref_qual
    }
  } else if state is Some(state) {
    state.has_explicit_object_parameter = true
  }
  let mut sofar : Node? = None
  while !self.consume_if_char('E') {
    if state is Some(state) {
      // Only set end-with-template on the case that does that.
      state.ends_with_template_args = false
    }
    let next = if self.look() == 'T' {
      // ::= <template-param>
      if sofar is Some(_) {
        raise Fail
      }
      self.parse_template_param()
    } else if self.look() == 'I' {
      // ::= <template-prefix> <template-args>
      guard sofar is Some(prefix) else { raise Fail }
      let args = self.parse_template_args(tag_templates=state is Some(_))
      if prefix.kind is NameWithTemplateArgs(_, _) {
        raise Fail
      }
      if state is Some(state) {
        state.ends_with_template_args = true
      }
      make(NameWithTemplateArgs(prefix, args))
    } else if self.look() == 'D' &&
      (self.look(ahead=1) == 't' || self.look(ahead=1) == 'T') {
      // ::= <decltype>
      if sofar is Some(_) {
        raise Fail
      }
      self.parse_decltype()
    } else {
      let mut modname : Node? = None
      if self.look() == 'S' {
        // ::= <substitution>
        let s = if self.look(ahead=1) == 't' {
          self.first += 2
          name_node("std")
        } else {
          self.parse_substitution()
        }
        if s.kind is ModuleName(_, _, _) {
          modname = Some(s)
        } else if sofar is Some(_) {
          raise Fail
        } else {
          sofar = Some(s)
          continue // Do not push a new substitution.
        }
      }
      // ::= [<prefix>] <unqualified-name>
      self.parse_unqualified_name(state, sofar, modname)
    }
    sofar = Some(next)
    self.subs.push(next)
    // No longer used: <data-member-prefix> := <member source-name>
    // [<template-args>] M
    ignore(self.consume_if_char('M'))
  }
  guard sofar is Some(result) && !self.subs.is_empty() else { raise Fail }
  ignore(self.subs.pop())
  result
}

///|
/// <simple-id> ::= <source-name> [ <template-args> ]
fn Parser::parse_simple_id(self : Parser) -> Node raise Fail {
  let name = self.parse_source_name()
  if self.look() == 'I' {
    let args = self.parse_template_args()
    return make(NameWithTemplateArgs(name, args))
  }
  name
}

///|
/// <destructor-name> ::= <unresolved-type>  # e.g., ~T or ~decltype(f())
///                   ::= <simple-id>        # e.g., ~A<2*N>
fn Parser::parse_destructor_name(self : Parser) -> Node raise Fail {
  let result = if is_digit(self.look()) {
    self.parse_simple_id()
  } else {
    self.parse_unresolved_type()
  }
  make(DtorName(result))
}

///|
/// <unresolved-type> ::= <template-param>
///                   ::= <decltype>
///                   ::= <substitution>
fn Parser::parse_unresolved_type(self : Parser) -> Node raise Fail {
  if self.look() == 'T' {
    let tp = self.parse_template_param()
    self.subs.push(tp)
    return tp
  }
  if self.look() == 'D' {
    let dt = self.parse_decltype()
    self.subs.push(dt)
    return dt
  }
  self.parse_substitution()
}

///|
/// <base-unresolved-name> ::= <simple-id>
///          extension     ::= <operator-name> [<template-args>]
///                        ::= on <operator-name> [<template-args>]
///                        ::= dn <destructor-name>
fn Parser::parse_base_unresolved_name(self : Parser) -> Node raise Fail {
  if is_digit(self.look()) {
    return self.parse_simple_id()
  }
  if self.consume_if("dn") {
    return self.parse_destructor_name()
  }
  ignore(self.consume_if("on"))
  let oper = self.parse_operator_name(None)
  if self.look() == 'I' {
    let args = self.parse_template_args()
    return make(NameWithTemplateArgs(oper, args))
  }
  oper
}

///|
/// <unresolved-name>
///  extension        ::= srN <unresolved-type> [<template-args>]
///                       <unresolved-qualifier-level>* E <base-unresolved-name>
///                   ::= [gs] <base-unresolved-name>
///                   ::= [gs] sr <unresolved-qualifier-level>+ E
///                       <base-unresolved-name>
///                   ::= sr <unresolved-type> <base-unresolved-name>
///  extension        ::= sr <unresolved-type> <template-args>
///                       <base-unresolved-name>
fn Parser::parse_unresolved_name(
  self : Parser,
  global : Bool,
) -> Node raise Fail {
  if self.consume_if("srN") {
    let mut sofar = self.parse_unresolved_type()
    if self.look() == 'I' {
      let args = self.parse_template_args()
      sofar = make(NameWithTemplateArgs(sofar, args))
    }
    while !self.consume_if_char('E') {
      let qual = self.parse_simple_id()
      sofar = make(QualifiedName(sofar, qual))
    }
    let base = self.parse_base_unresolved_name()
    return make(QualifiedName(sofar, base))
  }
  // [gs] <base-unresolved-name>                     # x or (with "gs") ::x
  if !self.consume_if("sr") {
    let sofar = self.parse_base_unresolved_name()
    return if global { make(GlobalQualifiedName(sofar)) } else { sofar }
  }
  let mut sofar : Node? = None
  if is_digit(self.look()) {
    // [gs] sr <unresolved-qualifier-level>+ E <base-unresolved-name>
    while true {
      let qual = self.parse_simple_id()
      sofar = Some(
        match sofar {
          Some(prefix) => make(QualifiedName(prefix, qual))
          None => if global { make(GlobalQualifiedName(qual)) } else { qual }
        },
      )
      if self.consume_if_char('E') {
        break
      }
    }
  } else {
    // sr <unresolved-type> [<template-args>] <base-unresolved-name>
    let mut ty = self.parse_unresolved_type()
    if self.look() == 'I' {
      let args = self.parse_template_args()
      ty = make(NameWithTemplateArgs(ty, args))
    }
    sofar = Some(ty)
  }
  guard sofar is Some(prefix) else { raise Fail }
  let base = self.parse_base_unresolved_name()
  make(QualifiedName(prefix, base))
}

///|
/// <abi-tags> ::= <abi-tag> [<abi-tags>]
/// <abi-tag> ::= B <source-name>
fn Parser::parse_abi_tags(self : Parser, node : Node) -> Node raise Fail {
  let mut node = node
  while self.consume_if_char('B') {
    let tag = self.parse_bare_source_name()
    if tag.length() == 0 {
      raise Fail
    }
    node = make(AbiTagAttr(node, tag))
  }
  node
}

///|
/// <substitution> ::= S <seq-id> _
///                ::= S_
///                ::= Sa | Sb | Ss | Si | So | Sd
fn Parser::parse_substitution(self : Parser) -> Node raise Fail {
  if !self.consume_if_char('S') {
    raise Fail
  }
  let c = self.look()
  if c >= 'a' && c <= 'z' {
    let kind = match c {
      'a' => SSK_ALLOCATOR
      'b' => SSK_BASIC_STRING
      'd' => SSK_IOSTREAM
      'i' => SSK_ISTREAM
      'o' => SSK_OSTREAM
      's' => SSK_STRING
      _ => raise Fail
    }
    self.first += 1
    let special = make(SpecialSubstitution(kind))
    // Itanium C++ ABI 5.1.2: If a name that would use a built-in
    // <substitution> has ABI tags, the tags are appended to the
    // substitution; the result is a substitutable component.
    let with_tags = self.parse_abi_tags(special)
    if !physical_equal(with_tags, special) {
      self.subs.push(with_tags)
    }
    return with_tags
  }
  // ::= S_
  if self.consume_if_char('_') {
    guard self.subs.get(0) is Some(sub) else { raise Fail }
    return sub
  }
  // ::= S <seq-id> _
  guard self.parse_seq_id() is Some(index) else { raise Fail }
  let index = index + 1L
  if !self.consume_if_char('_') || index >= self.subs.length().to_int64() {
    raise Fail
  }
  self.subs[index.to_int()]
}

///|
/// <template-param> ::= T_    # first template parameter
///                  ::= T <parameter-2 non-negative number> _
///                  ::= TL <level-1> __
///                  ::= TL <level-1> _ <parameter-2 non-negative number> _
fn Parser::parse_template_param(self : Parser) -> Node raise Fail {
  let begin = self.first
  if !self.consume_if_char('T') {
    raise Fail
  }
  let mut level = 0L
  if self.consume_if_char('L') {
    guard self.parse_positive_integer() is Some(l) else { raise Fail }
    level = l + 1L
    if !self.consume_if_char('_') {
      raise Fail
    }
  }
  let mut index = 0L
  if !self.consume_if_char('_') {
    guard self.parse_positive_integer() is Some(i) else { raise Fail }
    index = i + 1L
    if !self.consume_if_char('_') {
      raise Fail
    }
  }
  // Enclosing template parameter levels are not tracked well enough to
  // substitute them within a <constraint-expression>; print the parameter
  // numbering instead.
  if self.has_incomplete_template_parameter_tracking {
    return name_node(self.slice(begin, self.first - 1))
  }
  // A <template-param> referring to a <template-arg> further ahead in the
  // mangled name (conversion operator types, outermost level only).
  if self.permit_forward_template_references && level == 0L {
    let node = make(ForwardTemplateReference(index.to_int(), Ref(None)))
    self.forward_template_refs.push(node)
    return node
  }
  let num_levels = self.template_params.length().to_int64()
  let params = if level < num_levels {
    self.template_params[level.to_int()]
  } else {
    None
  }
  match params {
    Some(params) if index < params.length().to_int64() => params[index.to_int()]
    _ => {
      // Itanium ABI 5.1.8: In a generic lambda, uses of auto in the
      // parameter list are mangled as the corresponding artificial template
      // type parameter.
      if self.parsing_lambda_params_at_level.to_int64() == level &&
        level <= num_levels {
        // Popped by the lambda's template parameter scope.
        if level == num_levels {
          self.template_params.push(None)
        }
        return name_node("auto")
      }
      raise Fail
    }
  }
}

///|
fn Parser::is_template_param_decl(self : Parser) -> Bool {
  let c = self.look(ahead=1)
  self.look() == 'T' &&
  (c == 'y' || c == 'p' || c == 't' || c == 'n' || c == 'k')
}

///|
/// <template-param-decl> ::= Ty                          # type parameter
///                       ::= Tk <concept name> [<template-args>]
///                       ::= Tn <type>                   # non-type parameter
///                       ::= Tt <template-param-decl>* E # template parameter
///                       ::= Tp <template-param-decl>    # parameter pack
fn Parser::parse_template_param_decl(
  self : Parser,
  params : Array[Node]?,
) -> Node raise Fail {
  let invent = fn(kind : Int) {
    let index = self.num_synthetic_template_parameters[kind]
    self.num_synthetic_template_parameters[kind] = index + 1
    let node = make(SyntheticTemplateParamName(kind, index))
    if params is Some(params) {
      params.push(node)
    }
    node
  }
  if self.consume_if("Ty") {
    return make(TypeTemplateParamDecl(invent(TPARAM_TYPE)))
  }
  if self.consume_if("Tk") {
    let saved = self.has_incomplete_template_parameter_tracking
    self.has_incomplete_template_parameter_tracking = true
    let constraint = self.parse_name()
    self.has_incomplete_template_parameter_tracking = saved
    let name = invent(TPARAM_TYPE)
    return make(ConstrainedTypeTemplateParamDecl(constraint, name))
  }
  if self.consume_if("Tn") {
    let name = invent(TPARAM_NON_TYPE)
    let ty = self.parse_type()
    return make(NonTypeTemplateParamDecl(name, ty))
  }
  if self.consume_if("Tt") {
    let name = invent(TPARAM_TEMPLATE)
    let params_begin = self.names.length()
    let old_num_lists = self.template_params.length()
    let inner : Array[Node] = []
    self.template_params.push(Some(inner))
    let mut requires : Node? = None
    while !self.consume_if_char('E') {
      let p = self.parse_template_param_decl(Some(inner))
      self.names.push(p)
      if self.consume_if_char('Q') {
        requires = Some(self.parse_constraint_expr())
        if !self.consume_if_char('E') {
          raise Fail
        }
        break
      }
    }
    let inner_params = self.pop_trailing(params_begin)
    if self.template_params.length() > old_num_lists {
      self.template_params.truncate(old_num_lists)
    }
    return make(TemplateTemplateParamDecl(name, inner_params, requires))
  }
  if self.consume_if("Tp") {
    let p = self.parse_template_param_decl(params)
    return make(TemplateParamPackDecl(p))
  }
  raise Fail
}

///|
/// <template-arg> ::= <type>                    # type or template
///                ::= X <expression> E          # expression
///                ::= <expr-primary>            # simple expressions
///                ::= J <template-arg>* E       # argument pack
///                ::= LZ <encoding> E           # extension
///                ::= <template-param-decl> <template-arg>
fn Parser::parse_template_arg(self : Parser) -> Node raise Fail {
  match self.look() {
    'X' => {
      self.first += 1
      let arg = self.parse_expr()
      if !self.consume_if_char('E') {
        raise Fail
      }
      arg
    }
    'J' => {
      self.first += 1
      let begin = self.names.length()
      while !self.consume_if_char('E') {
        let arg = self.parse_template_arg()
        self.names.push(arg)
      }
      make(TemplateArgumentPack(self.pop_trailing(begin)))
    }
    'L' => {
      // ::= LZ <encoding> E           # extension
      if self.look(ahead=1) == 'Z' {
        self.first += 2
        let arg = self.parse_encoding()
        if !self.consume_if_char('E') {
          raise Fail
        }
        return arg
      }
      // ::= <expr-primary>            # simple expressions
      self.parse_expr_primary()
    }
    'T' => {
      // Either <template-param> or a <template-param-decl> <template-arg>.
      if !self.is_template_param_decl() {
        return self.parse_type()
      }
      let param = self.parse_template_param_decl(None)
      let arg = self.parse_template_arg()
      ignore(param)
      make(TemplateParamQualifiedArg(arg))
    }
    _ => self.parse_type()
  }
}

///|
/// <template-args> ::= I <template-arg>* [Q <requires-clause expr>] E
fn Parser::parse_template_args(
  self : Parser,
  tag_templates? : Bool = false,
) -> Node raise Fail {
  if !self.consume_if_char('I') {
    raise Fail
  }
  // <template-params> refer to the innermost <template-args>. Clear out
  // any outer args that we may have inserted into TemplateParams.
  if tag_templates {
    self.template_params.clear()
    self.template_params.push(Some(self.outer_template_params))
    self.outer_template_params.clear()
  }
  let begin = self.names.length()
  let mut requires : Node? = None
  while !self.consume_if_char('E') {
    let arg = self.parse_template_arg()
    self.names.push(arg)
    if tag_templates {
      let entry = match arg.kind {
        TemplateParamQualifiedArg(inner) => inner
        TemplateArgumentPack(elements) => make(ParameterPack(elements))
        _ => arg
      }
      self.outer_template_params.push(entry)
    }
    if self.consume_if_char('Q') {
      requires = Some(self.parse_constraint_expr())
      if !self.consume_if_char('E') {
        raise Fail
      }
      break
    }
  }
  // The requires-clause is not printed, to keep the output simple.
  ignore(requires)
  make(TemplateArgs(self.pop_trailing(begin)))
}

///|
/// <encoding> ::= <function name> <bare-function-type>
///                    [`Q` <requires-clause expr>]
///            ::= <data name>
///            ::= <special-name>
fn Parser::parse_encoding(
  self : Parser,
  parse_params? : Bool = true,
) -> Node raise Fail {
  // The template parameters of an encoding are unrelated to those of the
  // enclosing context.
  self.with_saved_template_params(() => self.parse_encoding_body(parse_params))
}

///|
fn Parser::is_end_of_encoding(self : Parser) -> Bool {
  // The chars that can follow an <encoding> (none of which can start a
  // <type>).
  let c = self.look()
  self.num_left() == 0 || c == 'E' || c == '.' || c == '_'
}

///|
fn Parser::parse_encoding_body(
  self : Parser,
  parse_params : Bool,
) -> Node raise Fail {
  if self.look() == 'G' || self.look() == 'T' {
    return self.parse_special_name()
  }
  let info = NameState::new(self)
  let name = self.parse_name(state=Some(info))
  self.resolve_forward_template_refs(info)
  if self.is_end_of_encoding() {
    return name
  }
  // Only at the top level: skip the rest of the name.
  if !parse_params {
    while self.consume() != 0 {
      continue
    }
    return name
  }
  let mut attrs : Node? = None
  if self.consume_if("Ua9enable_ifI") {
    let begin = self.names.length()
    while !self.consume_if_char('E') {
      let arg = self.parse_template_arg()
      self.names.push(arg)
    }
    attrs = Some(make(EnableIfAttr(self.pop_trailing(begin))))
  }
  let return_type = if !info.ctor_dtor_conversion &&
    info.ends_with_template_args {
    Some(self.parse_type())
  } else {
    None
  }
  let params = if self.consume_if_char('v') {
    []
  } else {
    let begin = self.names.length()
    while true {
      let mut ty = self.parse_type()
      if info.has_explicit_object_parameter && begin == self.names.length() {
        ty = make(ExplicitObjectParameter(ty))
      }
      self.names.push(ty)
      if self.is_end_of_encoding() || self.look() == 'Q' {
        break
      }
    }
    self.pop_trailing(begin)
  }
  let requires = if self.consume_if_char('Q') {
    Some(self.parse_constraint_expr())
  } else {
    None
  }
  make(
    FunctionEncoding(
      return_type,
      name,
      params,
      attrs,
      requires,
      info.cv_qualifiers,
      info.reference_qualifier,
    ),
  )
}

///|
/// <call-offset> ::= h <nv-offset> _
///               ::= v <v-offset> _
/// Returns `true` on failure (the offsets are not printed).
fn Parser::parse_call_offset(self : Parser) -> Bool {
  if self.consume_if_char('h') {
    return self.parse_number(allow_negative=true).length() == 0 ||
      !self.consume_if_char('_')
  }
  if self.consume_if_char('v') {
    return self.parse_number(allow_negative=true).length() == 0 ||
      !self.consume_if_char('_') ||
      self.parse_number(allow_negative=true).length() == 0 ||
      !self.consume_if_char('_')
  }
  true
}

///|
/// <special-name> ::= TV <type> | TT <type> | TI <type> | TS <type>
///                ::= Tc <call-offset> <call-offset> <base encoding>
///                ::= T <call-offset> <base encoding>
///                ::= GV <object name> | TW <object name> | TH <object name>
///                ::= GR <object name> [<seq-id>] _
///      extension ::= TC <first type> <number> _ <second type>
///      extension ::= GI <module name>
///                ::= TA <template-arg>
fn Parser::parse_special_name(self : Parser) -> Node raise Fail {
  let special = fn(text : StringView, child : Node) {
    make(SpecialName(text, child))
  }
  match (self.look(), self.look(ahead=1)) {
    ('T', 'A') => {
      self.first += 2
      special("template parameter object for ", self.parse_template_arg())
    }
    ('T', 'V') => {
      self.first += 2
      special("vtable for ", self.parse_type())
    }
    ('T', 'T') => {
      self.first += 2
      special("VTT for ", self.parse_type())
    }
    ('T', 'I') => {
      self.first += 2
      special("typeinfo for ", self.parse_type())
    }
    ('T', 'S') => {
      self.first += 2
      special("typeinfo name for ", self.parse_type())
    }
    ('T', 'c') => {
      self.first += 2
      if self.parse_call_offset() || self.parse_call_offset() {
        raise Fail
      }
      special("covariant return thunk to ", self.parse_encoding())
    }
    ('T', 'C') => {
      self.first += 2
      let first_type = self.parse_type()
      if self.parse_number(allow_negative=true).length() == 0 ||
        !self.consume_if_char('_') {
        raise Fail
      }
      let second_type = self.parse_type()
      make(CtorVtableSpecialName(second_type, first_type))
    }
    ('T', 'W') => {
      self.first += 2
      special("thread-local wrapper routine for ", self.parse_name())
    }
    ('T', 'H') => {
      self.first += 2
      special("thread-local initialization routine for ", self.parse_name())
    }
    ('T', _) => {
      self.first += 1
      let is_virtual = self.look() == 'v'
      if self.parse_call_offset() {
        raise Fail
      }
      let base = self.parse_encoding()
      if is_virtual {
        special("virtual thunk to ", base)
      } else {
        special("non-virtual thunk to ", base)
      }
    }
    ('G', 'V') => {
      self.first += 2
      special("guard variable for ", self.parse_name())
    }
    ('G', 'R') => {
      self.first += 2
      let name = self.parse_name()
      let parsed_seq_id = self.parse_seq_id() is Some(_)
      if !self.consume_if_char('_') && parsed_seq_id {
        raise Fail
      }
      special("reference temporary for ", name)
    }
    ('G', 'I') => {
      self.first += 2
      guard self.parse_module_name_opt(None) is Some(modname) else {
        raise Fail
      }
      special("initializer for module ", modname)
    }
    _ => raise Fail
  }
}

///|
/// <mangled-name> ::= _Z <encoding>
///                ::= <type>
/// extension      ::= ___Z <encoding> _block_invoke
/// extension      ::= ___Z <encoding> _block_invoke<decimal-digit>+
/// extension      ::= ___Z <encoding> _block_invoke_<decimal-digit>+
fn Parser::parse(self : Parser, parse_params : Bool) -> Node raise Fail {
  if self.consume_if("_Z") || self.consume_if("__Z") {
    let mut encoding = self.parse_encoding(parse_params~)
    if self.look() == '.' {
      encoding = make(DotSuffix(encoding, self.slice(self.first, self.last)))
      self.first = self.last
    }
    if self.num_left() != 0 {
      raise Fail
    }
    return encoding
  }
  if self.consume_if("___Z") || self.consume_if("____Z") {
    let encoding = self.parse_encoding(parse_params~)
    if !self.consume_if("_block_invoke") {
      raise Fail
    }
    let require_number = self.consume_if_char('_')
    if self.parse_number().length() == 0 && require_number {
      raise Fail
    }
    if self.look() == '.' {
      self.first = self.last
    }
    if self.num_left() != 0 {
      raise Fail
    }
    return make(SpecialName("invocation function for block in ", encoding))
  }
  let ty = self.parse_type()
  if self.num_left() != 0 {
    raise Fail
  }
  ty
}
