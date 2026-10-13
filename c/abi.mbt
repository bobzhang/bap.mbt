// Port of BAP `lib/bap_c/bap_c_abi.ml` (C language ABI), the part that
// turns C prototypes into IR arguments, the processor registry, and the
// API processor. The argument-passing eDSL lives in `abi_arg.mbt` and
// `abi_language.mbt`.
//
// Deviations:
// - There is no `Bap_api` package in this port; `create_api_processor`
//   returns an `ApiProcessor` value, and `process_api`/`api_processors`
//   provide the static registry of language processors that the upstream
//   `Bap_api.process` maintains.
// - Upstream logs an error when an ABI processor produces a wrong number of
//   parameters; here the subroutine is returned unchanged silently.
// - `C.Abi.Stack.create` takes an `@types.Arch` upstream; here
//   `stack_slot` takes the `@core_theory.Target` that owns the stack
//   pointer and memory variables (see also `stack_slot_of_arch`).

///|
/// A formal parameter: an abstraction of the data passed via the parameter
/// and the BIL expression that denotes it.
pub type Param = (Data, @types.Exp)

///|
/// A subroutine argument list.
///
/// The arg terms are inserted as follows: the n-th positional parameter
/// corresponds to the n-th arg term; the hidden arguments follow the
/// positional ones; the return argument, if any, is the last arg term.
pub(all) struct Args {
  return_ : Param?
  hidden : Array[(CType, Param)]
  params : Array[Param]
}

///|
/// An ABI processor (upstream `C.Abi.t`).
pub(all) struct AbiProcessor {
  /// `insert_args(sub, attrs, proto)` infers the list of arguments of `sub`
  /// annotated with the attributes `attrs`.
  insert_args : (@types.Term[@types.Sub], Array[Attr], Proto) -> Args?
  /// `apply_attrs(attrs, sub)` transforms a subroutine based on the
  /// semantics of its attributes.
  apply_attrs : (Array[Attr], @types.Term[@types.Sub]) -> @types.Term[
    @types.Sub,
  ]
}

///|
/// Errors raised by the ABI registries.
pub(all) suberror AbiError {
  /// The ABI name is not a valid target name.
  InvalidAbiName(String)
  /// A processor for the ABI is already registered.
  DuplicateAbi(String)
  /// A data model for the target is already registered.
  DuplicateModel(String)
} derive(Eq, Debug)

///|
fn is_mutable_qualifier(const_ : Bool) -> Bool {
  !const_
}

///|
fn lvalue(t : CType) -> Bool {
  match t {
    Void => true
    Basic(s) => is_mutable_qualifier(s.qualifier.const_)
    Pointer(s) => is_mutable_qualifier(s.qualifier.const_) || lvalue(s.t)
    Array(s) => is_mutable_qualifier(s.qualifier.const_) || lvalue(s.t.element)
    Function(_) => false
    Structure(s) | Union(s) => s.t.fields.iter().any(field => lvalue(field.1))
  }
}

///|
/// `arg_intent(t)` infers the argument intention from its C type.
///
/// Values passed by value are inputs. A reference (a pointer or an array)
/// to a non-function is input/output if any value referenced by it is
/// non-const. Everything else is an input.
pub fn arg_intent(t : CType) -> @types.Intent {
  match t {
    Pointer(s) if lvalue(s.t) => Both
    Array(s) if lvalue(s.t.element) => Both
    _ => In
  }
}

///|
fn sizeof(size : &Ruler, t : CType) -> Int32 {
  match size.bits(t) {
    None => size.pointer().in_bits()
    Some(s) => s
  }
}

///|
/// `data(size, t)` creates an abstraction of data represented by the type
/// `t`, including inner and trailing paddings. `size` defines the data
/// model.
pub fn data(size : &Ruler, t : CType) -> Data {
  fn padding_data(pad : Int32) -> Data {
    match @types.Size::of_int_opt(pad) {
      Some(pad) => Imm(pad, Set([]))
      None => Seq(Array::make(pad / 8, Imm(R8, Set([]))))
    }
  }

  fn go(t : CType) -> Data {
    match t {
      Void => Seq([])
      Basic(s) => Imm(size.basic(s.t), Top)
      Pointer(s) => Ptr(go(s.t))
      Array({ t: { element, size: None, }, .. }) => Ptr(go(element))
      Array({ t: { element, size: Some(n), }, .. }) =>
        Ptr(Seq(Array::makei(n, _ => go(element))))
      Structure(s) => {
        let seq = []
        let mut total = 0
        for field in s.t.fields {
          let t = field.1
          let fsize = sizeof(size, t)
          let pad = padding(size.alignment(t), total)
          if pad != 0 {
            seq.push(padding_data(pad))
          }
          seq.push(go(t))
          total = total + fsize + pad
        }
        let fullsize = sizeof(size, t)
        if fullsize - total > 0 {
          seq.push(padding_data(fullsize - total))
        }
        Seq(seq)
      }
      Union(_) => Seq(Array::make(sizeof(size, t) / 8, Imm(R8, Top)))
      Function(_) => Ptr(Imm(size.pointer().to_size(), Top))
    }
  }

  go(t)
}

///|
/// `layout(size, t)` computes the layout of the C data type `t`.
pub fn layout(size : &Ruler, t : CType) -> Layout {
  fn imm(bits : Int32, obj : Obj[Layout]) -> Layout {
    { layout: Imm(bits, obj), }
  }

  fn seq(layouts : Array[Layout]) -> Layout {
    { layout: Seq(layouts.map(l => l.layout)), }
  }

  fn go(t : CType) -> Layout {
    match t {
      Void => imm(8, Undef)
      Basic(s) => imm(size.basic(s.t).in_bits(), Basic(s.t))
      Pointer(s) => { layout: Ptr(go(s.t).layout), }
      Array({ t: { element, size: None, }, .. }) =>
        { layout: Ptr(go(element).layout), }
      Array({ t: { element, size: Some(n), }, .. }) =>
        { layout: Ptr(seq(Array::makei(n, _ => go(element))).layout), }
      Structure(s) => {
        let items = []
        let mut total = 0
        for field in s.t.fields {
          let (name, t) = field
          let fsize = sizeof(size, t)
          let pad = padding(size.alignment(t), total)
          if pad != 0 {
            items.push(imm(pad, Undef))
          }
          items.push(imm(fsize, Field(name, go(t))))
          total = total + fsize + pad
        }
        let fullsize = sizeof(size, t)
        if fullsize - total > 0 {
          items.push(imm(fullsize - total, Undef))
        }
        seq(items)
      }
      Union(s) => {
        let total = sizeof(size, t)
        let variants = s.t.fields.map(field => {
          let (name, t) = field
          let fsize = sizeof(size, t)
          let pad = total - fsize
          let field = imm(fsize, Field(name, go(t)))
          if pad > 0 {
            seq([field, imm(pad, Undef)])
          } else {
            field
          }
        })
        imm(total, Union(variants))
      }
      Function(_) =>
        { layout: Ptr(imm(size.pointer().in_bits(), Undef).layout), }
    }
  }

  go(t)
}

///|
/// The total size in bits of a datum (pointers have the pointer size).
pub fn size_of_data(size : &Ruler, d : Data) -> Int32 {
  match d {
    Imm(s, _) => s.in_bits()
    Seq(xs) => xs.fold(init=0, (acc, x) => acc + size_of_data(size, x))
    Ptr(_) => size.pointer().in_bits()
  }
}

///|
fn size_of_datum(size : &Ruler, d : Datum[Obj[Layout], Int32]) -> Int32 {
  match d {
    Imm(s, _) => s
    Seq(xs) => xs.fold(init=0, (acc, x) => acc + size_of_datum(size, x))
    Ptr(_) => size.pointer().in_bits()
  }
}

///|
/// The total size in bits of a layout (pointers have the pointer size).
pub fn size_of_layout(size : &Ruler, l : Layout) -> Int32 {
  size_of_datum(size, l.layout)
}

///|
fn array_to_pointer(t : CType) -> CType {
  match t {
    Array(s) =>
      Pointer({ t: s.t.element, qualifier: s.qualifier, attrs: s.attrs, })
    t => t
  }
}

///|
/// Replaces array parameters and results with pointers (C array decay).
pub fn decay_arrays(proto : Proto) -> Proto {
  {
    ..proto,
    return_: array_to_pointer(proto.return_),
    args: proto.args.map(arg => (arg.0, array_to_pointer(arg.1))),
  }
}

///|
fn coerce(
  ltyp : @types.ValueType,
  rtyp : @types.ValueType,
  exp : @types.Exp,
) -> @types.Exp {
  match (ltyp, rtyp) {
    (Imm(m), Imm(n)) =>
      if m == n {
        exp
      } else if m > n {
        @types.Exp::cast(Signed, m, exp)
      } else {
        @types.Exp::cast(Low, m, exp)
      }
    _ => exp
  }
}

///|
fn create_arg(
  size : &Ruler,
  i : Int32,
  intent : @types.Intent,
  name : String,
  t : CType,
  param : Param,
  sub : @types.Term[@types.Sub],
) -> @types.Term[@types.Arg] {
  let (datum, exp) = param
  let layout = match datum {
    Ptr(_) =>
      if t.is_pointer() {
        layout(size, t)
      } else {
        layout(size, CType::pointer(t))
      }
    _ => layout(size, t)
  }
  let ltyp : @types.ValueType = Imm(size_of_layout(size, layout))
  let exp = match exp.infer_type() {
    Ok(rtyp) => coerce(ltyp, rtyp, exp)
    Err(_) => exp
  }
  let name = if name.is_empty() { "arg\{i + 1}" } else { name }
  let v = @types.Var::create(@types.Sub::name(sub) + "_" + name, ltyp)
  let arg = @types.Arg::create(v, exp, intent~)
  let arg = data_tag().set(arg, datum)
  let arg = type_tag().set(arg, t)
  layout_tag().set(arg, layout)
}

///|
let abi_models : Array[(@core_theory.Target, &Ruler)] = []

///|
/// Registers the data model for the target (used by `define_abi`).
pub fn register_model(
  target : @core_theory.Target,
  model : &Ruler,
) -> Unit raise AbiError {
  if abi_models.iter().any(entry => entry.0.equal(target)) {
    raise DuplicateModel(target.to_string())
  }
  abi_models.push((target, model))
}

///|
/// The data model for the given target: the registered one, or `LP32` for
/// 32-bit targets and `LP64` otherwise.
pub fn model(target : @core_theory.Target) -> &Ruler {
  for entry in abi_models {
    if entry.0.equal(target) {
      return entry.1
    }
  }
  if target.bits() == 32 {
    SizeBase::new(LP32)
  } else {
    SizeBase::new(LP64)
  }
}

///|
let abi_registry : Array[(@core_theory.Target, AbiProcessor)] = []

///|
/// Registers the ABI processor `abi` under `name`, which must be a valid
/// target name (upstream `C.Abi.register`, deprecated since 2022-07 in
/// favor of `define_abi`).
pub fn register_abi(name : String, abi : AbiProcessor) -> Unit raise AbiError {
  guard @core_theory.Target::lookup(name) is Some(target) else {
    raise InvalidAbiName(name)
  }
  if abi_registry.iter().any(entry => entry.0.equal(target)) {
    raise DuplicateAbi(name)
  }
  abi_registry.push((target, abi))
}

///|
/// The ABI processor registered under the name `name`.
pub fn get_processor(name : String) -> AbiProcessor? {
  match @core_theory.Target::lookup(name) {
    None => None
    Some(target) => lookup(target)
  }
}

///|
/// The ABI processor associated with the target.
pub fn lookup(target : @core_theory.Target) -> AbiProcessor? {
  for entry in abi_registry {
    if entry.0.equal(target) {
      return Some(entry.1)
    }
  }
  None
}

///|
fn default_prototype() -> Spec[Unit, Proto] {
  {
    qualifier: (),
    attrs: [],
    t: { args: [], variadic: false, return_: CType::basic(SInt), },
  }
}

///|
fn get_prototype(
  gamma : (String) -> CType?,
  name : String,
) -> Spec[Unit, Proto] {
  match gamma(name) {
    Some(Function(proto)) => proto
    _ => default_prototype()
  }
}

///|
fn apply_args(
  abi : AbiProcessor,
  size : &Ruler,
  attrs : Array[Attr],
  proto : Proto,
  sub : @types.Term[@types.Sub],
) -> @types.Term[@types.Sub] {
  let proto = decay_arrays(proto)
  match (abi.insert_args)(sub, attrs, proto) {
    None => sub
    Some({ return_, hidden, params, }) => {
      if params.length() != proto.args.length() {
        return sub
      }
      let args = []
      for i, param in params {
        let (n, t) = proto.args[i]
        args.push(create_arg(size, i, arg_intent(t), n, t, param, sub))
      }
      for i, entry in hidden {
        let (t, param) = entry
        let n = if i == 0 { "hidden" } else { "hidden\{i}" }
        args.push(create_arg(size, 0, Both, n, t, param, sub))
      }
      if return_ is Some(ret) {
        args.push(create_arg(size, 0, Out, "result", proto.return_, ret, sub))
      }
      args.fold(init=sub, (sub, arg) => sub.append_arg(arg))
    }
  }
}

///|
/// `apply(abi, size, attrs, proto, sub)` applies the ABI processor to the
/// subroutine: inserts the arguments annotated with their C types, data
/// abstractions, and layouts; stores the prototype (`proto_tag`); applies
/// the registered attribute passes (`apply_attr`); and finally the
/// processor's own `apply_attrs`.
pub fn apply(
  abi : AbiProcessor,
  size : &Ruler,
  attrs : Array[Attr],
  proto : Proto,
  sub : @types.Term[@types.Sub],
) -> @types.Term[@types.Sub] {
  let sub = apply_args(abi, size, attrs, proto, sub)
  let sub = proto_tag().set(sub, proto)
  let sub = attrs.rev_fold(init=sub, (sub, attr) => apply_attr(attr, sub))
  (abi.apply_attrs)(attrs, sub)
}

///|
/// A language processor (upstream `Bap_api.t` for the `c` language).
pub struct ApiProcessor {
  /// The name of the language, i.e., `"c"`.
  language : String
  /// `parse(get_api, apis)` creates the program mapper from a list of API
  /// names; `get_api(api)` returns the file that corresponds to `api`.
  parse : ((String) -> String?, Array[String]) -> Result[
    (@types.Term[@types.Program]) -> @types.Term[@types.Program],
    String,
  ]
}

///|
/// `create_api_processor(size, abi)` packs an API processor. The processor
/// parses the interface files with the provided C parser (`run_parser`),
/// and applies `abi` to each subroutine that is not an intrinsic and
/// doesn't have a prototype yet. Subroutines without a declaration get the
/// `int f(void)` prototype.
pub fn create_api_processor(size : &Ruler, abi : AbiProcessor) -> ApiProcessor {
  let parse = (get_api : (String) -> String?, intfs : Array[String]) => {
    let gamma : Map[String, CType] = Map([])
    for api in intfs {
      guard get_api(api) is Some(file) else {
        return Err("Unknown interface: \{api}")
      }
      match run_parser(size, file) {
        Err(e) => return Err("Parser error in \{api}: \{e}")
        Ok(decls) =>
          for decl in decls {
            gamma[decl.0] = decl.1
          }
      }
    }
    let mapper = (sub : @types.Term[@types.Sub]) => {
      if proto_tag().has(sub) || sub.is_intrinsic() {
        sub
      } else {
        let spec = get_prototype(name => gamma.get(name), @types.Sub::name(sub))
        apply(abi, size, spec.attrs, spec.t, sub)
      }
    }
    Ok((program : @types.Term[@types.Program]) => program.map_subs(mapper))
  }
  { language: "c", parse, }
}

///|
let api_registry : Array[ApiProcessor] = []

///|
/// Registers a language processor (upstream `Bap_api.process`).
pub fn process_api(processor : ApiProcessor) -> Unit {
  api_registry.push(processor)
}

///|
/// All registered language processors (upstream `Bap_api.processors`).
pub fn api_processors() -> Array[ApiProcessor] {
  api_registry.copy()
}

///|
fn word_exp(width : Int32, value : Int32) -> @types.Exp {
  try @types.Word::of_int(width~, value) catch {
    _ => @types.Exp::unknown("invalid offset \{value}", Imm(width))
  } noraise {
    w => @types.Exp::int(w)
  }
}

///|
fn bil_endian(e : @core_theory.Endianness) -> @bitvec.Endian {
  if e == @core_theory.Endianness::le() {
    LittleEndian
  } else {
    BigEndian
  }
}

///|
/// Converts a Core Theory variable into a BIL variable (upstream
/// `Var.reify`).
pub fn reify_var(v : @core_theory.Var) -> @types.Var {
  let sort = v.sort()
  let typ : @types.ValueType = match sort.bitv_size() {
    Some(n) => Imm(n)
    None =>
      match (sort.mem_keys(), sort.mem_values()) {
        (Some(ks), Some(vs)) =>
          Mem(
            addr_width=ks.bitv_size().unwrap_or(0),
            value_width=vs.bitv_size().unwrap_or(0),
          )
        _ => Imm(1)
      }
  }
  @types.Var::new(name=v.name(), typ~, is_virtual=v.is_virtual())
}

///|
fn stack_pointer(target : @core_theory.Target) -> @core_theory.Var? {
  target.regs(roles=[@core_theory.Role::stack_pointer()]).get(0)
}

///|
/// `stack_slot(target, off)` is the `off`-th stack slot (upstream
/// `C.Abi.Stack.create arch off`): a load of an address-sized word at
/// `SP + off * addr_bytes` (or `SP - ...` if `growsup`). Returns `None` if
/// the target has no stack pointer.
pub fn stack_slot(
  target : @core_theory.Target,
  growsup~ : Bool = false,
  off : Int32,
) -> @types.Exp? {
  guard stack_pointer(target) is Some(sp) else { return None }
  let width = target.data_addr_size()
  guard @types.Size::of_int_opt(width) is Some(sz) else { return None }
  let mem = @types.Exp::var_exp(reify_var(target.data()))
  let sp = @types.Exp::var_exp(reify_var(sp))
  let offset = off * sz.in_bytes()
  let addr = if offset == 0 {
    sp
  } else if growsup {
    @types.Exp::binop(Minus, sp, word_exp(width, offset))
  } else {
    @types.Exp::binop(Plus, sp, word_exp(width, offset))
  }
  Some(@types.Exp::load(mem~, addr~, bil_endian(target.endianness()), sz))
}

///|
/// `stack_slot_of_arch(arch, off)` is `stack_slot` for the Core Theory
/// target that has the same name as `arch`, if any.
pub fn stack_slot_of_arch(
  arch : @types.Arch,
  growsup~ : Bool = false,
  off : Int32,
) -> @types.Exp? {
  match @core_theory.Target::lookup(arch.to_string()) {
    None => None
    Some(target) => stack_slot(target, growsup~, off)
  }
}
