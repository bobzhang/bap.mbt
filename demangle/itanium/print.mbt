// Printing of the demangling AST (the `printLeft`/`printRight` methods of
// the upstream node classes).

///|
fn Node::has_rhs(self : Node, ob : Output) -> Bool {
  match self.rhs {
    Yes => true
    No => false
    Unknown =>
      match self.kind {
        QualType(child, _) => child.has_rhs(ob)
        PointerType(pointee) | ReferenceType(pointee, _) => pointee.has_rhs(ob)
        PointerToMemberType(_, mem_ty) => mem_ty.has_rhs(ob)
        ArrayType(_, _)
        | FunctionType(_, _, _, _, _)
        | FunctionEncoding(_, _, _, _, _, _, _) => true
        ParameterPack(data) => {
          init_pack_expansion(data, ob)
          let idx = ob.pack_index
          idx < data.length() && data[idx].has_rhs(ob)
        }
        ForwardTemplateReference(_, target) =>
          self.guarded(false, () => resolved(target).has_rhs(ob))
        _ => false
      }
  }
}

///|
fn Node::has_array(self : Node, ob : Output) -> Bool {
  match self.array {
    Yes => true
    No => false
    Unknown =>
      match self.kind {
        QualType(child, _) => child.has_array(ob)
        ArrayType(_, _) => true
        ParameterPack(data) => {
          init_pack_expansion(data, ob)
          let idx = ob.pack_index
          idx < data.length() && data[idx].has_array(ob)
        }
        ForwardTemplateReference(_, target) =>
          self.guarded(false, () => resolved(target).has_array(ob))
        _ => false
      }
  }
}

///|
fn Node::has_function(self : Node, ob : Output) -> Bool {
  match self.function {
    Yes => true
    No => false
    Unknown =>
      match self.kind {
        QualType(child, _) => child.has_function(ob)
        FunctionType(_, _, _, _, _) | FunctionEncoding(_, _, _, _, _, _, _) =>
          true
        ParameterPack(data) => {
          init_pack_expansion(data, ob)
          let idx = ob.pack_index
          idx < data.length() && data[idx].has_function(ob)
        }
        ForwardTemplateReference(_, target) =>
          self.guarded(false, () => resolved(target).has_function(ob))
        _ => false
      }
  }
}

///|
/// Runs `f` with the node marked as being printed; returns `default` if it
/// already is (a cycle in an ill-formed AST).
fn[T] Node::guarded(self : Node, default : T, f : () -> T) -> T {
  if self.printing {
    return default
  }
  self.printing = true
  let result = f()
  self.printing = false
  result
}

///|
/// The target of a forward template reference. Unresolved references are
/// rejected by the parser before printing.
fn resolved(target : Ref[Node?]) -> Node {
  match target.val {
    Some(node) => node
    None => name_node("")
  }
}

///|
/// Digs through glue nodes (packs and forward references) to the node that
/// represents concrete syntax.
fn Node::syntax_node(self : Node, ob : Output) -> Node {
  match self.kind {
    ParameterPack(data) => {
      init_pack_expansion(data, ob)
      let idx = ob.pack_index
      if idx < data.length() {
        data[idx].syntax_node(ob)
      } else {
        self
      }
    }
    ForwardTemplateReference(_, target) =>
      self.guarded(self, () => resolved(target).syntax_node(ob))
    _ => self
  }
}

///|
/// Sets up the stream for a pack expansion unless one is in progress.
fn init_pack_expansion(data : Array[Node], ob : Output) -> Unit {
  if ob.pack_max == PACK_NONE {
    ob.pack_max = data.length()
    ob.pack_index = 0
  }
}

///|
fn Node::print(self : Node, ob : Output) -> Unit {
  self.print_left(ob)
  if self.rhs != No {
    self.print_right(ob)
  }
}

///|
/// Prints the node as an expression operand, parenthesized if its
/// precedence is (strictly) weaker than `prec`.
fn Node::print_as_operand(
  self : Node,
  ob : Output,
  prec? : Int = PREC_DEFAULT,
  strictly_worse? : Bool = false,
) -> Unit {
  let paren = self.prec >= prec + (if strictly_worse { 1 } else { 0 })
  if paren {
    ob.print_open()
  }
  self.print(ob)
  if paren {
    ob.print_close()
  }
}

///|
fn print_with_comma(nodes : Array[Node], ob : Output) -> Unit {
  let mut first = true
  for node in nodes {
    let before_comma = ob.pos()
    if !first {
      ob.add(", ")
    }
    let after_comma = ob.pos()
    node.print_as_operand(ob, prec=PREC_COMMA)
    // An empty parameter pack expansion: erase the comma.
    if after_comma == ob.pos() {
      ob.set_pos(before_comma)
      continue
    }
    first = false
  }
}

///|
/// Prints an array of integer literals as a string literal; returns whether
/// it could.
fn print_as_string(nodes : Array[Node], ob : Output) -> Bool {
  let start = ob.pos()
  ob.add("\"")
  let mut last_was_numeric_escape = false
  for node in nodes {
    guard node.kind is IntegerLiteral(_, value) else {
      ob.set_pos(start)
      return false
    }
    let mut v = 0
    for i in 0..<value.length() {
      let c = value.at(i).to_int()
      if c < '0'.to_int() || c > '9'.to_int() || v > 25 {
        ob.set_pos(start)
        return false
      }
      v = v * 10 + (c - '0'.to_int())
    }
    if v > 255 {
      ob.set_pos(start)
      return false
    }
    // Insert a `""` to avoid accidentally extending a numeric escape.
    if last_was_numeric_escape &&
      (
        (v >= '0'.to_int() && v <= '9'.to_int()) ||
        (v >= 'a'.to_int() && v <= 'f'.to_int()) ||
        (v >= 'A'.to_int() && v <= 'F'.to_int())
      ) {
      ob.add("\"\"")
    }
    last_was_numeric_escape = false
    match v {
      7 => ob.add("\\a")
      8 => ob.add("\\b")
      12 => ob.add("\\f")
      10 => ob.add("\\n")
      13 => ob.add("\\r")
      9 => ob.add("\\t")
      11 => ob.add("\\v")
      34 => ob.add("\\\"")
      92 => ob.add("\\\\")
      _ =>
        if v < 32 || v == 127 {
          let hex = "0123456789ABCDEF"
          ob.add("\\")
          if v > 7 {
            ob.add("x")
          }
          if v >= 16 {
            ob.add(hex.view(start_offset=v >> 4, end_offset=(v >> 4) + 1))
          }
          ob.add(hex.view(start_offset=v & 15, end_offset=(v & 15) + 1))
          last_was_numeric_escape = true
        } else {
          ob.add(v.unsafe_to_char().to_string())
        }
    }
  }
  ob.add("\"")
  true
}

///|
fn print_quals(quals : Int, ob : Output) -> Unit {
  if (quals & QUAL_CONST) != 0 {
    ob.add(" const")
  }
  if (quals & QUAL_VOLATILE) != 0 {
    ob.add(" volatile")
  }
  if (quals & QUAL_RESTRICT) != 0 {
    ob.add(" restrict")
  }
}

///|
fn print_ref_qual(ref_qual : Int, ob : Output) -> Unit {
  if ref_qual == FREF_LVALUE {
    ob.add(" &")
  } else if ref_qual == FREF_RVALUE {
    ob.add(" &&")
  }
}

///|
/// `objc_object<Protocol>`, printed as `id<Protocol>` behind a pointer.
fn is_objc_object(node : Node) -> Bool {
  match node.kind {
    ObjCProtoName(ty, _) => ty.kind is NameType(name) && name == "objc_object"
    _ => false
  }
}

///|
/// Collapses references to references: rvalue to rvalue stays an rvalue,
/// anything else becomes an lvalue. Returns `None` on a cycle.
fn collapse_reference(
  rvalue : Bool,
  pointee : Node,
  ob : Output,
) -> (Bool, Node)? {
  let mut rvalue = rvalue
  let mut current = pointee
  let prev : Array[Node] = []
  while true {
    let sn = current.syntax_node(ob)
    guard sn.kind is ReferenceType(inner, inner_rvalue) else { break }
    current = inner
    rvalue = rvalue && inner_rvalue
    // Floyd's cycle detection: the middle of `prev` moves at half speed.
    prev.push(current)
    if prev.length() > 1 &&
      physical_equal(current, prev[(prev.length() - 1) / 2]) {
      return None
    }
  }
  Some((rvalue, current))
}

///|
/// Prints a `ParameterPackExpansion` of `child`.
fn print_pack_expansion(child : Node, ob : Output) -> Unit {
  let saved_index = ob.pack_index
  let saved_max = ob.pack_max
  ob.pack_index = PACK_NONE
  ob.pack_max = PACK_NONE
  let stream_pos = ob.pos()
  // Print the first element; a ParameterPack in `child` sets up the state.
  child.print(ob)
  if ob.pack_max == PACK_NONE {
    // No ParameterPack was found (an expansion on a <function-param>).
    ob.add("...")
  } else if ob.pack_max == 0 {
    // An empty pack: erase whatever was printed.
    ob.set_pos(stream_pos)
  } else {
    for i in 1..<ob.pack_max {
      ob.add(", ")
      ob.pack_index = i
      child.print(ob)
    }
  }
  ob.pack_index = saved_index
  ob.pack_max = saved_max
}

///|
fn print_closure_declarator(
  template_params : Array[Node],
  requires1 : Node?,
  params : Array[Node],
  requires2 : Node?,
  ob : Output,
) -> Unit {
  if !template_params.is_empty() {
    let saved = ob.inside_template
    ob.inside_template = true
    ob.add("<")
    print_with_comma(template_params, ob)
    ob.add(">")
    ob.inside_template = saved
  }
  if requires1 is Some(r) {
    ob.add(" requires ")
    r.print(ob)
    ob.add(" ")
  }
  ob.print_open()
  print_with_comma(params, ob)
  ob.print_close()
  if requires2 is Some(r) {
    ob.add(" requires ")
    r.print(ob)
  }
}

///|
/// Prints a literal value with an optional `n` (negative) prefix.
fn print_signed_number(value : StringView, ob : Output) -> Unit {
  if value.length() > 0 && value.at(0) == 'n' {
    ob.add("-")
    ob.add(value.view(start_offset=1))
  } else {
    ob.add(value)
  }
}

///|
fn Node::print_left(self : Node, ob : Output) -> Unit {
  match self.kind {
    NodeArrayNode(array) => print_with_comma(array, ob)
    DotSuffix(prefix, suffix) => {
      prefix.print(ob)
      ob.add(" (")
      ob.add(suffix)
      ob.add(")")
    }
    VendorExtQualType(ty, ext, ta) => {
      ty.print(ob)
      ob.add(" ")
      ob.add(ext)
      if ta is Some(ta) {
        ta.print(ob)
      }
    }
    QualType(child, quals) => {
      child.print_left(ob)
      print_quals(quals, ob)
    }
    ConversionOperatorType(ty) => {
      ob.add("operator ")
      ty.print(ob)
    }
    PostfixQualifiedType(ty, postfix) => {
      ty.print_left(ob)
      ob.add(postfix)
    }
    NameType(name) => ob.add(name)
    BitIntType(size, signed) => {
      if !signed {
        ob.add("unsigned ")
      }
      ob.add("_BitInt")
      ob.print_open()
      size.print_as_operand(ob)
      ob.print_close()
    }
    ElaboratedTypeSpefType(kind, child) => {
      ob.add(kind)
      ob.add(" ")
      child.print(ob)
    }
    TransformedType(transform, base) => {
      ob.add(transform)
      ob.add("(")
      base.print(ob)
      ob.add(")")
    }
    AbiTagAttr(base, tag) => {
      base.print_left(ob)
      ob.add("[abi:")
      ob.add(tag)
      ob.add("]")
    }
    EnableIfAttr(conditions) => {
      ob.add(" [enable_if:")
      print_with_comma(conditions, ob)
      ob.add("]")
    }
    ObjCProtoName(ty, protocol) => {
      ty.print(ob)
      ob.add("<")
      ob.add(protocol)
      ob.add(">")
    }
    PointerType(pointee) =>
      if is_objc_object(pointee) && pointee.kind is ObjCProtoName(_, protocol) {
        ob.add("id<")
        ob.add(protocol)
        ob.add(">")
      } else {
        pointee.print_left(ob)
        if pointee.has_array(ob) {
          ob.add(" ")
        }
        if pointee.has_array(ob) || pointee.has_function(ob) {
          ob.add("(")
        }
        ob.add("*")
      }
    ReferenceType(pointee, rvalue) =>
      self.guarded((), () => {
        guard collapse_reference(rvalue, pointee, ob) is Some((rvalue, target)) else {
          return
        }
        target.print_left(ob)
        if target.has_array(ob) {
          ob.add(" ")
        }
        if target.has_array(ob) || target.has_function(ob) {
          ob.add("(")
        }
        ob.add(if rvalue { "&&" } else { "&" })
      })
    PointerToMemberType(class_type, member_type) => {
      member_type.print_left(ob)
      if member_type.has_array(ob) || member_type.has_function(ob) {
        ob.add("(")
      } else {
        ob.add(" ")
      }
      class_type.print(ob)
      ob.add("::*")
    }
    ArrayType(base, _) => base.print_left(ob)
    FunctionType(ret, _, _, _, _) => {
      ret.print_left(ob)
      ob.add(" ")
    }
    NoexceptSpec(e) => {
      ob.add("noexcept")
      ob.print_open()
      e.print_as_operand(ob)
      ob.print_close()
    }
    DynamicExceptionSpec(types) => {
      ob.add("throw")
      ob.print_open()
      print_with_comma(types, ob)
      ob.print_close()
    }
    ExplicitObjectParameter(base) => {
      ob.add("this ")
      base.print(ob)
    }
    FunctionEncoding(ret, name, _, _, _, _, _) => {
      if ret is Some(ret) {
        ret.print_left(ob)
        if !ret.has_rhs(ob) {
          ob.add(" ")
        }
      }
      name.print(ob)
    }
    LiteralOperator(op_name) => {
      ob.add("operator\"\" ")
      op_name.print(ob)
    }
    SpecialName(special, child) => {
      ob.add(special)
      child.print(ob)
    }
    CtorVtableSpecialName(first_type, second_type) => {
      ob.add("construction vtable for ")
      first_type.print(ob)
      ob.add("-in-")
      second_type.print(ob)
    }
    NestedName(qual, name)
    | QualifiedName(qual, name)
    | LocalName(qual, name) => {
      qual.print(ob)
      ob.add("::")
      name.print(ob)
    }
    MemberLikeFriendName(qual, name) => {
      qual.print(ob)
      ob.add("::friend ")
      name.print(ob)
    }
    ModuleName(parent, name, is_partition) => {
      if parent is Some(parent) {
        parent.print(ob)
      }
      if parent is Some(_) || is_partition {
        ob.add(if is_partition { ":" } else { "." })
      }
      name.print(ob)
    }
    ModuleEntity(modname, name) => {
      name.print(ob)
      ob.add("@")
      modname.print(ob)
    }
    VectorType(base, dimension) => {
      base.print(ob)
      ob.add(" vector[")
      if dimension is Some(d) {
        d.print(ob)
      }
      ob.add("]")
    }
    PixelVectorType(dimension) => {
      ob.add("pixel vector[")
      dimension.print(ob)
      ob.add("]")
    }
    BinaryFPType(dimension) => {
      ob.add("_Float")
      dimension.print(ob)
    }
    SyntheticTemplateParamName(kind, index) => {
      ob.add(
        match kind {
          TPARAM_TYPE => "$T"
          TPARAM_NON_TYPE => "$N"
          _ => "$TT"
        },
      )
      if index > 0 {
        ob.add_uint(index - 1)
      }
    }
    TemplateParamQualifiedArg(arg) => arg.print(ob)
    TypeTemplateParamDecl(_) => ob.add("typename ")
    ConstrainedTypeTemplateParamDecl(constraint, _) => {
      constraint.print(ob)
      ob.add(" ")
    }
    NonTypeTemplateParamDecl(_, ty) => {
      ty.print_left(ob)
      if !ty.has_rhs(ob) {
        ob.add(" ")
      }
    }
    TemplateTemplateParamDecl(_, params, _) => {
      let saved = ob.inside_template
      ob.inside_template = true
      ob.add("template<")
      print_with_comma(params, ob)
      ob.add("> typename ")
      ob.inside_template = saved
    }
    TemplateParamPackDecl(param) => {
      param.print_left(ob)
      ob.add("...")
    }
    ParameterPack(data) => {
      init_pack_expansion(data, ob)
      let idx = ob.pack_index
      if idx < data.length() {
        data[idx].print_left(ob)
      }
    }
    TemplateArgumentPack(elements) => print_with_comma(elements, ob)
    ParameterPackExpansion(child) => print_pack_expansion(child, ob)
    TemplateArgs(params) => {
      let saved = ob.inside_template
      ob.inside_template = true
      ob.add("<")
      print_with_comma(params, ob)
      ob.add(">")
      ob.inside_template = saved
    }
    ForwardTemplateReference(_, target) =>
      self.guarded((), () => resolved(target).print_left(ob))
    NameWithTemplateArgs(name, args) => {
      name.print(ob)
      args.print(ob)
    }
    GlobalQualifiedName(child) => {
      ob.add("::")
      child.print(ob)
    }
    ExpandedSpecialSubstitution(ssk) => {
      ob.add("std::")
      ob.add(special_sub_base_name(ssk))
      if ssk >= SSK_STRING {
        ob.add("<char, std::char_traits<char>")
        if ssk == SSK_STRING {
          ob.add(", std::allocator<char>")
        }
        ob.add(">")
      }
    }
    SpecialSubstitution(_) => {
      ob.add("std::")
      ob.add(self.base_name())
    }
    CtorDtorName(basename, is_dtor) => {
      if is_dtor {
        ob.add("~")
      }
      ob.add(basename.base_name())
    }
    DtorName(base) => {
      ob.add("~")
      base.print_left(ob)
    }
    UnnamedTypeName(count) => {
      ob.add("'unnamed")
      ob.add(count)
      ob.add("'")
    }
    ClosureTypeName(template_params, requires1, params, requires2, count) => {
      ob.add("'lambda")
      ob.add(count)
      ob.add("'")
      print_closure_declarator(
        template_params, requires1, params, requires2, ob,
      )
    }
    StructuredBindingName(bindings) => {
      ob.print_open(open="[")
      print_with_comma(bindings, ob)
      ob.print_close(close="]")
    }
    BinaryExpr(lhs, op, rhs) => {
      // If we're printing a '>' inside of a template argument, and we
      // haven't yet parenthesized the expression, do so now.
      let paren_all = ob.paren_depth == 0 && (op == ">" || op == ">>")
      if paren_all {
        ob.print_open()
      }
      // Assignment is right associative, with special LHS precedence.
      let is_assign = self.prec == PREC_ASSIGN
      lhs.print_as_operand(
        ob,
        prec=if is_assign { PREC_OR_IF } else { self.prec },
        strictly_worse=!is_assign,
      )
      // No space before the comma operator.
      if op != "," {
        ob.add(" ")
      }
      ob.add(op)
      ob.add(" ")
      rhs.print_as_operand(ob, prec=self.prec, strictly_worse=is_assign)
      if paren_all {
        ob.print_close()
      }
    }
    ArraySubscriptExpr(op1, op2) => {
      op1.print_as_operand(ob, prec=self.prec)
      ob.print_open(open="[")
      op2.print_as_operand(ob)
      ob.print_close(close="]")
    }
    PostfixExpr(child, op) => {
      child.print_as_operand(ob, prec=self.prec, strictly_worse=true)
      ob.add(op)
    }
    ConditionalExpr(cond, then, else_) => {
      cond.print_as_operand(ob, prec=self.prec)
      ob.add(" ? ")
      then.print_as_operand(ob)
      ob.add(" : ")
      else_.print_as_operand(ob, prec=PREC_ASSIGN, strictly_worse=true)
    }
    MemberExpr(lhs, kind, rhs) => {
      lhs.print_as_operand(ob, prec=self.prec, strictly_worse=true)
      ob.add(kind)
      rhs.print_as_operand(ob, prec=self.prec, strictly_worse=false)
    }
    SubobjectExpr(ty, sub_expr, offset) => {
      sub_expr.print(ob)
      ob.add(".<")
      ty.print(ob)
      ob.add(" at offset ")
      if offset.length() == 0 {
        ob.add("0")
      } else {
        print_signed_number(offset, ob)
      }
      ob.add(">")
    }
    EnclosingExpr(prefix, infix) => {
      ob.add(prefix)
      ob.print_open()
      infix.print(ob)
      ob.print_close()
    }
    CastExpr(cast_kind, to, from) => {
      ob.add(cast_kind)
      let saved = ob.inside_template
      ob.inside_template = true
      ob.add("<")
      to.print_left(ob)
      ob.add(">")
      ob.inside_template = saved
      ob.print_open()
      from.print_as_operand(ob)
      ob.print_close()
    }
    SizeofParamPackExpr(pack) => {
      ob.add("sizeof...")
      ob.print_open()
      print_pack_expansion(pack, ob)
      ob.print_close()
    }
    CallExpr(callee, args, is_paren) => {
      if is_paren {
        ob.print_open()
      }
      callee.print(ob)
      if is_paren {
        ob.print_close()
      }
      ob.print_open()
      print_with_comma(args, ob)
      ob.print_close()
    }
    NewExpr(expr_list, ty, init_list, is_global, is_array) => {
      if is_global {
        ob.add("::")
      }
      ob.add("new")
      if is_array {
        ob.add("[]")
      }
      if !expr_list.is_empty() {
        ob.print_open()
        print_with_comma(expr_list, ob)
        ob.print_close()
      }
      ob.add(" ")
      ty.print(ob)
      if !init_list.is_empty() {
        ob.print_open()
        print_with_comma(init_list, ob)
        ob.print_close()
      }
    }
    DeleteExpr(op, is_global, is_array) => {
      if is_global {
        ob.add("::")
      }
      ob.add("delete")
      if is_array {
        ob.add("[]")
      }
      ob.add(" ")
      op.print(ob)
    }
    PrefixExpr(prefix, child) => {
      ob.add(prefix)
      child.print_as_operand(ob, prec=self.prec)
    }
    FunctionParam(number) => {
      ob.add("fp")
      ob.add(number)
    }
    ConversionExpr(ty, exprs) => {
      ob.print_open()
      ty.print(ob)
      ob.print_close()
      ob.print_open()
      print_with_comma(exprs, ob)
      ob.print_close()
    }
    PointerToMemberConversionExpr(ty, sub_expr) => {
      ob.print_open()
      ty.print(ob)
      ob.print_close()
      ob.print_open()
      sub_expr.print(ob)
      ob.print_close()
    }
    InitListExpr(ty, inits) => {
      if ty is Some(ty) {
        if ty.print_init_list_as_type(inits, ob) {
          return
        }
        ty.print(ob)
      }
      ob.add("{")
      print_with_comma(inits, ob)
      ob.add("}")
    }
    BracedExpr(elem, init, is_array) => {
      if is_array {
        ob.add("[")
        elem.print(ob)
        ob.add("]")
      } else {
        ob.add(".")
        elem.print(ob)
      }
      if !(init.kind is (BracedExpr(_, _, _) | BracedRangeExpr(_, _, _))) {
        ob.add(" = ")
      }
      init.print(ob)
    }
    BracedRangeExpr(first, last, init) => {
      ob.add("[")
      first.print(ob)
      ob.add(" ... ")
      last.print(ob)
      ob.add("]")
      if !(init.kind is (BracedExpr(_, _, _) | BracedRangeExpr(_, _, _))) {
        ob.add(" = ")
      }
      init.print(ob)
    }
    FoldExpr(is_left_fold, op, pack, init) => {
      let print_pack = () => {
        ob.print_open()
        print_pack_expansion(pack, ob)
        ob.print_close()
      }
      ob.print_open()
      // Either '[init op ]... op pack' or 'pack op ...[ op init]'.
      if !is_left_fold || init is Some(_) {
        match (is_left_fold, init) {
          (true, Some(init)) =>
            init.print_as_operand(ob, prec=PREC_CAST, strictly_worse=true)
          _ => print_pack()
        }
        ob.add(" ")
        ob.add(op)
        ob.add(" ")
      }
      ob.add("...")
      if is_left_fold || init is Some(_) {
        ob.add(" ")
        ob.add(op)
        ob.add(" ")
        match (is_left_fold, init) {
          (false, Some(init)) =>
            init.print_as_operand(ob, prec=PREC_CAST, strictly_worse=true)
          _ => print_pack()
        }
      }
      ob.print_close()
    }
    ThrowExpr(op) => {
      ob.add("throw ")
      op.print(ob)
    }
    BoolExpr(value) => ob.add(if value { "true" } else { "false" })
    StringLiteral(ty) => {
      ob.add("\"<")
      ty.print(ob)
      ob.add(">\"")
    }
    LambdaExpr(ty) => {
      ob.add("[]")
      if ty.kind
        is ClosureTypeName(template_params, requires1, params, requires2, _) {
        print_closure_declarator(
          template_params, requires1, params, requires2, ob,
        )
      }
      ob.add("{...}")
    }
    EnumLiteral(ty, integer) => {
      ob.print_open()
      ty.print(ob)
      ob.print_close()
      print_signed_number(integer, ob)
    }
    IntegerLiteral(ty, value) => {
      if ty.length() > 3 {
        ob.print_open()
        ob.add(ty)
        ob.print_close()
      }
      print_signed_number(value, ob)
      if ty.length() <= 3 {
        ob.add(ty)
      }
    }
    FloatLiteral(contents, kind) => print_float_literal(contents, kind, ob)
    RequiresExpr(parameters, requirements) => {
      ob.add("requires")
      if !parameters.is_empty() {
        ob.add(" ")
        ob.print_open()
        print_with_comma(parameters, ob)
        ob.print_close()
      }
      ob.add(" ")
      ob.print_open(open="{")
      for req in requirements {
        req.print(ob)
      }
      ob.add(" ")
      ob.print_close(close="}")
    }
    ExprRequirement(expr, is_noexcept, type_constraint) => {
      ob.add(" ")
      let braced = is_noexcept || type_constraint is Some(_)
      if braced {
        ob.print_open(open="{")
      }
      expr.print(ob)
      if braced {
        ob.print_close(close="}")
      }
      if is_noexcept {
        ob.add(" noexcept")
      }
      if type_constraint is Some(tc) {
        ob.add(" -> ")
        tc.print(ob)
      }
      ob.add(";")
    }
    TypeRequirement(ty) => {
      ob.add(" typename ")
      ty.print(ob)
      ob.add(";")
    }
    NestedRequirement(constraint) => {
      ob.add(" requires ")
      constraint.print(ob)
      ob.add(";")
    }
  }
}

///|
fn Node::print_right(self : Node, ob : Output) -> Unit {
  match self.kind {
    QualType(child, _) => child.print_right(ob)
    PointerType(pointee) =>
      if !is_objc_object(pointee) {
        if pointee.has_array(ob) || pointee.has_function(ob) {
          ob.add(")")
        }
        pointee.print_right(ob)
      }
    ReferenceType(pointee, rvalue) =>
      self.guarded((), () => {
        guard collapse_reference(rvalue, pointee, ob) is Some((_, target)) else {
          return
        }
        if target.has_array(ob) || target.has_function(ob) {
          ob.add(")")
        }
        target.print_right(ob)
      })
    PointerToMemberType(_, member_type) => {
      if member_type.has_array(ob) || member_type.has_function(ob) {
        ob.add(")")
      }
      member_type.print_right(ob)
    }
    ArrayType(base, dimension) => {
      if ob.back() != ']' {
        ob.add(" ")
      }
      ob.add("[")
      if dimension is Some(d) {
        d.print(ob)
      }
      ob.add("]")
      base.print_right(ob)
    }
    FunctionType(ret, params, cv_quals, ref_qual, exception_spec) => {
      ob.print_open()
      print_with_comma(params, ob)
      ob.print_close()
      ret.print_right(ob)
      print_quals(cv_quals, ob)
      print_ref_qual(ref_qual, ob)
      if exception_spec is Some(spec) {
        ob.add(" ")
        spec.print(ob)
      }
    }
    FunctionEncoding(ret, _, params, attrs, requires, cv_quals, ref_qual) => {
      ob.print_open()
      print_with_comma(params, ob)
      ob.print_close()
      if ret is Some(ret) {
        ret.print_right(ob)
      }
      print_quals(cv_quals, ob)
      print_ref_qual(ref_qual, ob)
      if attrs is Some(attrs) {
        attrs.print(ob)
      }
      if requires is Some(requires) {
        ob.add(" requires ")
        requires.print(ob)
      }
    }
    TypeTemplateParamDecl(name) | ConstrainedTypeTemplateParamDecl(_, name) =>
      name.print(ob)
    NonTypeTemplateParamDecl(name, ty) => {
      name.print(ob)
      ty.print_right(ob)
    }
    TemplateTemplateParamDecl(name, _, requires) => {
      name.print(ob)
      if requires is Some(requires) {
        ob.add(" requires ")
        requires.print(ob)
      }
    }
    TemplateParamPackDecl(param) => param.print_right(ob)
    ParameterPack(data) => {
      init_pack_expansion(data, ob)
      let idx = ob.pack_index
      if idx < data.length() {
        data[idx].print_right(ob)
      }
    }
    ForwardTemplateReference(_, target) =>
      self.guarded((), () => resolved(target).print_right(ob))
    _ => ()
  }
}

///|
/// Prints an initializer list of this type in a custom way (a `char` array
/// as a string literal); returns whether it did.
fn Node::print_init_list_as_type(
  self : Node,
  elements : Array[Node],
  ob : Output,
) -> Bool {
  match self.kind {
    ArrayType(base, _) =>
      if base.kind is NameType(name) && name == "char" {
        print_as_string(elements, ob)
      } else {
        false
      }
    _ => false
  }
}
