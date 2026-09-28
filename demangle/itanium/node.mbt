// The demangling AST (a port of the node classes of LLVM's
// `ItaniumDemangle.h`). The parser builds a tree of `Node`s that the
// printer then traverses with `print_left`/`print_right`.

///|
/// A three-way cached property: `Unknown` when the node has an unexpanded
/// parameter pack below it that may affect the value.
priv enum Cache {
  Yes
  No
  Unknown
} derive(Eq)

// Operator precedences of expression nodes, from the tightest to the
// loosest binding; used to decide where parentheses are required.

///|
const PREC_PRIMARY : Int = 0

///|
const PREC_POSTFIX : Int = 1

///|
const PREC_UNARY : Int = 2

///|
const PREC_CAST : Int = 3

///|
const PREC_PTR_MEM : Int = 4

///|
const PREC_MULTIPLICATIVE : Int = 5

///|
const PREC_ADDITIVE : Int = 6

///|
const PREC_SHIFT : Int = 7

///|
const PREC_SPACESHIP : Int = 8

///|
const PREC_RELATIONAL : Int = 9

///|
const PREC_EQUALITY : Int = 10

///|
const PREC_AND : Int = 11

///|
const PREC_XOR : Int = 12

///|
const PREC_IOR : Int = 13

///|
const PREC_AND_IF : Int = 14

///|
const PREC_OR_IF : Int = 15

///|
const PREC_CONDITIONAL : Int = 16

///|
const PREC_ASSIGN : Int = 17

///|
const PREC_COMMA : Int = 18

///|
const PREC_DEFAULT : Int = 19

// CV-qualifier bits.

///|
const QUAL_NONE : Int = 0

///|
const QUAL_CONST : Int = 1

///|
const QUAL_VOLATILE : Int = 2

///|
const QUAL_RESTRICT : Int = 4

// Function reference qualifiers.

///|
const FREF_NONE : Int = 0

///|
const FREF_LVALUE : Int = 1

///|
const FREF_RVALUE : Int = 2

// Kinds of synthetic template parameters.

///|
const TPARAM_TYPE : Int = 0

///|
const TPARAM_NON_TYPE : Int = 1

///|
const TPARAM_TEMPLATE : Int = 2

// Kinds of the standard substitutions (`Sa`, `Sb`, `Ss`, `Si`, `So`, `Sd`).

///|
const SSK_ALLOCATOR : Int = 0

///|
const SSK_BASIC_STRING : Int = 1

///|
const SSK_STRING : Int = 2

///|
const SSK_ISTREAM : Int = 3

///|
const SSK_OSTREAM : Int = 4

///|
const SSK_IOSTREAM : Int = 5

// Kinds of floating-point literals.

///|
const FLOAT_FLOAT : Int = 0

///|
const FLOAT_DOUBLE : Int = 1

///|
const FLOAT_LONG_DOUBLE : Int = 2

///|
/// The concrete syntax represented by a node.
priv enum Kind {
  NodeArrayNode(Array[Node])
  DotSuffix(Node, StringView)
  VendorExtQualType(Node, StringView, Node?)
  QualType(Node, Int)
  ConversionOperatorType(Node)
  PostfixQualifiedType(Node, StringView)
  ElaboratedTypeSpefType(StringView, Node)
  TransformedType(StringView, Node)
  NameType(StringView)
  AbiTagAttr(Node, StringView)
  EnableIfAttr(Array[Node])
  ObjCProtoName(Node, StringView)
  PointerType(Node)
  /// The pointee and whether this is an rvalue reference.
  ReferenceType(Node, Bool)
  /// The class type and the member type.
  PointerToMemberType(Node, Node)
  ArrayType(Node, Node?)
  /// Return type, parameters, cv-qualifiers, ref-qualifier, exception spec.
  FunctionType(Node, Array[Node], Int, Int, Node?)
  NoexceptSpec(Node)
  DynamicExceptionSpec(Array[Node])
  ExplicitObjectParameter(Node)
  /// Return type, name, parameters, attributes, requires-clause,
  /// cv-qualifiers, ref-qualifier.
  FunctionEncoding(Node?, Node, Array[Node], Node?, Node?, Int, Int)
  LiteralOperator(Node)
  SpecialName(StringView, Node)
  CtorVtableSpecialName(Node, Node)
  QualifiedName(Node, Node)
  NestedName(Node, Node)
  MemberLikeFriendName(Node, Node)
  LocalName(Node, Node)
  /// The parent module, the name and whether this is a partition.
  ModuleName(Node?, Node, Bool)
  ModuleEntity(Node, Node)
  VectorType(Node, Node?)
  PixelVectorType(Node)
  BinaryFPType(Node)
  BitIntType(Node, Bool)
  SyntheticTemplateParamName(Int, Int)
  TemplateParamQualifiedArg(Node)
  TypeTemplateParamDecl(Node)
  ConstrainedTypeTemplateParamDecl(Node, Node)
  /// The name and the type.
  NonTypeTemplateParamDecl(Node, Node)
  TemplateTemplateParamDecl(Node, Array[Node], Node?)
  TemplateParamPackDecl(Node)
  ParameterPack(Array[Node])
  TemplateArgumentPack(Array[Node])
  ParameterPackExpansion(Node)
  TemplateArgs(Array[Node])
  /// The index and the (later resolved) referenced argument.
  ForwardTemplateReference(Int, Ref[Node?])
  NameWithTemplateArgs(Node, Node)
  GlobalQualifiedName(Node)
  ExpandedSpecialSubstitution(Int)
  SpecialSubstitution(Int)
  /// The base name and whether this is a destructor.
  CtorDtorName(Node, Bool)
  DtorName(Node)
  UnnamedTypeName(StringView)
  /// Template parameters, requires-clause, parameters, requires-clause,
  /// count.
  ClosureTypeName(Array[Node], Node?, Array[Node], Node?, StringView)
  StructuredBindingName(Array[Node])
  BinaryExpr(Node, StringView, Node)
  ArraySubscriptExpr(Node, Node)
  PostfixExpr(Node, StringView)
  ConditionalExpr(Node, Node, Node)
  MemberExpr(Node, StringView, Node)
  /// Type, sub-expression, offset.
  SubobjectExpr(Node, Node, StringView)
  EnclosingExpr(StringView, Node)
  CastExpr(StringView, Node, Node)
  SizeofParamPackExpr(Node)
  /// Callee, arguments, whether the callee is parenthesized.
  CallExpr(Node, Array[Node], Bool)
  /// Expression list, type, initializers, global, array.
  NewExpr(Array[Node], Node, Array[Node], Bool, Bool)
  /// Operand, global, array.
  DeleteExpr(Node, Bool, Bool)
  PrefixExpr(StringView, Node)
  FunctionParam(StringView)
  ConversionExpr(Node, Array[Node])
  PointerToMemberConversionExpr(Node, Node)
  InitListExpr(Node?, Array[Node])
  /// Left fold, operator, pack, initializer.
  FoldExpr(Bool, StringView, Node, Node?)
  ThrowExpr(Node)
  BoolExpr(Bool)
  StringLiteral(Node)
  LambdaExpr(Node)
  EnumLiteral(Node, StringView)
  /// The type suffix/prefix and the value.
  IntegerLiteral(StringView, StringView)
  /// The hexadecimal contents and the literal kind (`FLOAT_*`).
  FloatLiteral(StringView, Int)
  /// Element, initializer, whether the designator is an index.
  BracedExpr(Node, Node, Bool)
  BracedRangeExpr(Node, Node, Node)
  RequiresExpr(Array[Node], Array[Node])
  ExprRequirement(Node, Bool, Node?)
  TypeRequirement(Node)
  NestedRequirement(Node)
}

///|
/// A node of the demangling AST. Nodes are compared by identity.
priv struct Node {
  kind : Kind
  prec : Int
  rhs : Cache
  array : Cache
  function : Cache
  /// Set while the node is being printed (cycle breaking for reference
  /// and forward-reference nodes of ill-formed inputs).
  mut printing : Bool
}

///|
fn Node::new(
  kind : Kind,
  prec? : Int = PREC_PRIMARY,
  rhs? : Cache = No,
  array? : Cache = No,
  function? : Cache = No,
) -> Node {
  { kind, prec, rhs, array, function, printing: false, }
}

///|
/// Creates a node with the caches its kind implies.
fn make(kind : Kind, prec? : Int = PREC_PRIMARY) -> Node {
  match kind {
    QualType(child, _) | AbiTagAttr(child, _) =>
      Node::new(
        kind,
        prec~,
        rhs=child.rhs,
        array=child.array,
        function=child.function,
      )
    PointerType(pointee) | ReferenceType(pointee, _) =>
      Node::new(kind, prec~, rhs=pointee.rhs)
    PointerToMemberType(_, mem_ty) => Node::new(kind, prec~, rhs=mem_ty.rhs)
    ArrayType(_, _) => Node::new(kind, prec~, rhs=Yes, array=Yes)
    FunctionType(_, _, _, _, _) | FunctionEncoding(_, _, _, _, _, _, _) =>
      Node::new(kind, prec~, rhs=Yes, function=Yes)
    TypeTemplateParamDecl(_)
    | ConstrainedTypeTemplateParamDecl(_, _)
    | NonTypeTemplateParamDecl(_, _)
    | TemplateTemplateParamDecl(_, _, _)
    | TemplateParamPackDecl(_) => Node::new(kind, prec~, rhs=Yes)
    ParameterPack(data) => {
      let all_no = fn(get : (Node) -> Cache) {
        data.iter().all(n => get(n) == No)
      }
      Node::new(
        kind,
        prec~,
        rhs=if all_no(n => n.rhs) { No } else { Unknown },
        array=if all_no(n => n.array) { No } else { Unknown },
        function=if all_no(n => n.function) { No } else { Unknown },
      )
    }
    ForwardTemplateReference(_, _) =>
      Node::new(kind, prec~, rhs=Unknown, array=Unknown, function=Unknown)
    _ => Node::new(kind, prec~)
  }
}

///|
fn name_node(name : StringView) -> Node {
  make(NameType(name))
}

///|
fn special_sub_base_name(ssk : Int) -> StringView {
  match ssk {
    SSK_ALLOCATOR => "allocator"
    SSK_BASIC_STRING => "basic_string"
    SSK_STRING => "basic_string"
    SSK_ISTREAM => "basic_istream"
    SSK_OSTREAM => "basic_ostream"
    _ => "basic_iostream"
  }
}

///|
/// The unqualified base name of a name node (used for constructor and
/// destructor names).
fn Node::base_name(self : Node) -> StringView {
  // iterative: substitutions can chain names arbitrarily deep
  let mut node = self
  while true {
    match node.kind {
      AbiTagAttr(base, _) => node = base
      NestedName(_, name)
      | MemberLikeFriendName(_, name)
      | ModuleEntity(_, name)
      | QualifiedName(_, name)
      | NameWithTemplateArgs(name, _)
      | GlobalQualifiedName(name) => node = name
      _ => break
    }
  }
  match node.kind {
    NameType(name) => name
    ExpandedSpecialSubstitution(ssk) => special_sub_base_name(ssk)
    SpecialSubstitution(ssk) => {
      let name = special_sub_base_name(ssk)
      if ssk >= SSK_STRING {
        name.view(start_offset=6) // drop "basic_"
      } else {
        name
      }
    }
    _ => ""
  }
}
