///|
let tid_counter : Ref[Int] = Ref(0)

///|
pub(all) struct Tid {
  id : Int
  name : String?
  ivec_value : Int?
} derive(Eq, Hash, Debug)

///|
fn next_tid_id() -> Int {
  tid_counter.val = tid_counter.val + 1
  tid_counter.val
}

///|
pub fn Tid::fresh() -> Tid {
  { id: next_tid_id(), name: None, ivec_value: None }
}

///|
pub fn Tid::for_name(name : String) -> Tid {
  { id: next_tid_id(), name: Some(name), ivec_value: None }
}

///|
pub fn Tid::for_addr(addr : Word) -> Tid {
  Tid::for_name(addr.to_hex())
}

///|
pub fn Tid::for_ivec(ivec : Int) -> Tid {
  { id: next_tid_id(), name: None, ivec_value: Some(ivec) }
}

///|
pub fn Tid::id(self : Tid) -> Int {
  self.id
}

///|
pub fn Tid::name(self : Tid) -> String? {
  self.name
}

///|
pub fn Tid::ivec(self : Tid) -> Int? {
  self.ivec_value
}

///|
pub fn Tid::to_string(self : Tid) -> String {
  match self.name {
    Some(name) => "@\{name}"
    None =>
      match self.ivec_value {
        Some(ivec) => "@interrupt:#\{ivec}"
        None => "%\{self.id}"
      }
  }
}

///|
pub(all) struct Attr {
  key : String
  value : String
} derive(Eq, Debug)

///|
pub fn Attr::new(key~ : String, value~ : String) -> Attr {
  { key, value }
}

///|
pub fn Attr::comment(text : String) -> Attr {
  Attr::new(key="comment", value=text)
}

///|
struct Term[T] {
  tid_value : Tid
  payload_value : T
  attrs_value : Map[String, String]
}

///|
pub fn[T] Term::create(payload : T, tid? : Tid) -> Term[T] {
  {
    tid_value: match tid {
      Some(value) => value
      None => Tid::fresh()
    },
    payload_value: payload,
    attrs_value: {},
  }
}

///|
pub fn[T] Term::clone(self : Term[T]) -> Term[T] {
  {
    tid_value: Tid::fresh(),
    payload_value: self.payload_value,
    attrs_value: self.attrs_value.copy(),
  }
}

///|
pub fn[T] Term::same(self : Term[T], other : Term[T]) -> Bool {
  self.tid_value == other.tid_value
}

///|
pub fn[T] Term::tid(self : Term[T]) -> Tid {
  self.tid_value
}

///|
pub fn[T] Term::name(self : Term[T]) -> String {
  self.tid_value.to_string()
}

///|
pub fn[T] Term::payload(self : Term[T]) -> T {
  self.payload_value
}

///|
pub fn[T] Term::with_payload(self : Term[T], payload : T) -> Term[T] {
  {
    tid_value: self.tid_value,
    payload_value: payload,
    attrs_value: self.attrs_value.copy(),
  }
}

///|
pub fn[T] Term::set_attr(self : Term[T], attr : Attr) -> Term[T] {
  let attrs = self.attrs_value.copy()
  attrs[attr.key] = attr.value
  {
    tid_value: self.tid_value,
    payload_value: self.payload_value,
    attrs_value: attrs,
  }
}

///|
pub fn[T] Term::del_attr(self : Term[T], key : String) -> Term[T] {
  let attrs = self.attrs_value.copy()
  attrs.remove(key)
  {
    tid_value: self.tid_value,
    payload_value: self.payload_value,
    attrs_value: attrs,
  }
}

///|
pub fn[T] Term::get_attr(self : Term[T], key : String) -> String? {
  self.attrs_value.get(key)
}

///|
pub fn[T] Term::has_attr(self : Term[T], key : String) -> Bool {
  self.attrs_value.contains(key)
}

///|
pub fn[T] Term::attrs(self : Term[T]) -> Map[String, String] {
  self.attrs_value.copy()
}

///|
pub(all) enum Label {
  Direct(Tid)
  Indirect(Exp)
} derive(Eq, Debug)

///|
pub fn Label::create() -> Label {
  Direct(Tid::fresh())
}

///|
pub fn Label::direct(tid : Tid) -> Label {
  Direct(tid)
}

///|
pub fn Label::indirect(exp : Exp) -> Label {
  Indirect(exp)
}

///|
pub fn Label::change(
  self : Label,
  direct? : (Tid) -> Tid,
  indirect? : (Exp) -> Exp,
) -> Label {
  match self {
    Direct(tid) =>
      match direct {
        Some(f) => Direct(f(tid))
        None => self
      }
    Indirect(exp) =>
      match indirect {
        Some(f) => Indirect(f(exp))
        None => self
      }
  }
}

///|
pub fn Label::to_string(self : Label) -> String {
  match self {
    Direct(tid) => tid.to_string()
    Indirect(exp) => "*\{exp.to_string()}"
  }
}

///|
pub(all) enum JmpDst {
  ResolvedDst(Tid)
  IndirectDst(Exp)
} derive(Eq, Debug)

///|
pub(all) enum JmpResolution {
  ResolvedTarget(Tid)
  IndirectTarget(Exp)
} derive(Eq, Debug)

///|
pub fn Jmp::resolved(tid : Tid) -> JmpDst {
  ResolvedDst(tid)
}

///|
pub fn Jmp::indirect(exp : Exp) -> JmpDst {
  IndirectDst(exp)
}

///|
pub fn Jmp::resolve(dst : JmpDst) -> JmpResolution {
  match dst {
    ResolvedDst(tid) => ResolvedTarget(tid)
    IndirectDst(exp) => IndirectTarget(exp)
  }
}

///|
fn jmp_dst_of_label(label : Label) -> JmpDst {
  match label {
    Direct(tid) => ResolvedDst(tid)
    Indirect(exp) => IndirectDst(exp)
  }
}

///|
fn jmp_dst_to_label(dst : JmpDst) -> Label {
  match dst {
    ResolvedDst(tid) => Direct(tid)
    IndirectDst(exp) => Indirect(exp)
  }
}

///|
fn jmp_dst_ivec(dst : JmpDst) -> Int? {
  match dst {
    ResolvedDst(tid) => tid.ivec()
    IndirectDst(_) => None
  }
}

///|
fn jmp_unknown_dst() -> JmpDst {
  IndirectDst(Unknown("unknown", Imm(0)))
}

///|
fn jmp_kind_of_dst_alt(dst : JmpDst?, alt : JmpDst?) -> JmpKind {
  match (dst, alt) {
    (None, None) => Goto(jmp_dst_to_label(jmp_unknown_dst()))
    (Some(dst), None) => Goto(jmp_dst_to_label(dst))
    (None, Some(alt)) => JmpCall(Call::create(target=jmp_dst_to_label(alt)))
    (Some(dst), Some(alt)) =>
      match (dst, jmp_dst_ivec(alt)) {
        (ResolvedDst(tid), Some(ivec)) => Interrupt(ivec, tid)
        _ =>
          JmpCall(
            Call::create(
              target=jmp_dst_to_label(alt),
              return_label=jmp_dst_to_label(dst),
            ),
          )
      }
  }
}

///|
pub(all) struct Call {
  target : Label
  return_label : Label?
} derive(Eq, Debug)

///|
pub fn Call::create(target~ : Label, return_label? : Label) -> Call {
  { target, return_label }
}

///|
pub fn Call::with_target(self : Call, target : Label) -> Call {
  { target, return_label: self.return_label }
}

///|
pub fn Call::with_return(self : Call, return_label : Label) -> Call {
  { target: self.target, return_label: Some(return_label) }
}

///|
pub fn Call::with_noreturn(self : Call) -> Call {
  { target: self.target, return_label: None }
}

///|
pub(all) enum JmpKind {
  JmpCall(Call)
  Goto(Label)
  Ret(Label)
  Interrupt(Int, Tid)
} derive(Eq, Debug)

///|
pub fn JmpKind::to_string(self : JmpKind) -> String {
  match self {
    JmpCall(call) => "call \{call.target.to_string()}"
    Goto(label) => "goto \{label.to_string()}"
    Ret(label) => "ret \{label.to_string()}"
    Interrupt(num, tid) => "int \{num}, \{tid.to_string()}"
  }
}

///|
pub(all) enum Intent {
  In
  Out
  Both
} derive(Eq, Debug)

///|
pub(all) struct Program {
  subs : Array[Term[Sub]]
}

///|
pub(all) struct Sub {
  name : String
  args : Array[Term[Arg]]
  blks : Array[Term[Blk]]
}

///|
pub(all) struct Blk {
  phis : Array[Term[Phi]]
  defs : Array[Term[Def]]
  jmps : Array[Term[Jmp]]
}

///|
pub(all) struct Def {
  lhs : Var
  rhs : Exp
} derive(Eq, Debug)

///|
pub(all) struct Phi {
  lhs : Var
  values : Array[(Tid, Exp)]
} derive(Eq, Debug)

///|
pub(all) struct Jmp {
  kind : JmpKind
  cond : Exp
} derive(Eq, Debug)

///|
pub(all) struct Arg {
  lhs : Var
  rhs : Exp
  intent : Intent?
} derive(Eq, Debug)

///|
pub(all) enum BlkElt {
  PhiElt(Term[Phi])
  DefElt(Term[Def])
  JmpElt(Term[Jmp])
}

///|
pub fn Program::create(subs? : Array[Term[Sub]], tid? : Tid) -> Term[Program] {
  Term::create(
    {
      subs: match subs {
        Some(items) => items.copy()
        None => []
      },
    },
    tid?,
  )
}

///|
pub fn Term::subs(self : Term[Program]) -> Array[Term[Sub]] {
  self.payload_value.subs.copy()
}

///|
pub fn Term::append_sub(self : Term[Program], sub : Term[Sub]) -> Term[Program] {
  let subs = self.payload_value.subs.copy()
  subs.push(sub)
  self.with_payload({ subs, })
}

///|
pub fn Term::find_sub(self : Term[Program], tid : Tid) -> Term[Sub]? {
  self.payload_value.subs
  .search_by(term => term.tid() == tid)
  .map(i => self.payload_value.subs[i])
}

///|
pub fn Sub::create(
  name? : String,
  args? : Array[Term[Arg]],
  blks? : Array[Term[Blk]],
  tid? : Tid,
) -> Term[Sub] {
  Term::create(
    {
      name: match name {
        Some(value) => value
        None => ""
      },
      args: match args {
        Some(items) => items.copy()
        None => []
      },
      blks: match blks {
        Some(items) => items.copy()
        None => []
      },
    },
    tid?,
  )
}

///|
pub fn Term::sub_name(self : Term[Sub]) -> String {
  self.payload_value.name
}

///|
pub fn Term::with_sub_name(self : Term[Sub], name : String) -> Term[Sub] {
  self.with_payload({ ..self.payload_value, name, })
}

///|
pub fn Term::args(self : Term[Sub]) -> Array[Term[Arg]] {
  self.payload_value.args.copy()
}

///|
pub fn Term::blks(self : Term[Sub]) -> Array[Term[Blk]] {
  self.payload_value.blks.copy()
}

///|
pub fn Term::append_arg(self : Term[Sub], arg : Term[Arg]) -> Term[Sub] {
  let args = self.payload_value.args.copy()
  args.push(arg)
  self.with_payload({ ..self.payload_value, args, })
}

///|
pub fn Term::append_blk(self : Term[Sub], blk : Term[Blk]) -> Term[Sub] {
  let blks = self.payload_value.blks.copy()
  blks.push(blk)
  self.with_payload({ ..self.payload_value, blks, })
}

///|
pub fn Term::find_blk(self : Term[Sub], tid : Tid) -> Term[Blk]? {
  self.payload_value.blks
  .search_by(term => term.tid() == tid)
  .map(i => self.payload_value.blks[i])
}

///|
pub fn Blk::create(
  phis? : Array[Term[Phi]],
  defs? : Array[Term[Def]],
  jmps? : Array[Term[Jmp]],
  tid? : Tid,
) -> Term[Blk] {
  Term::create(
    {
      phis: match phis {
        Some(items) => items.copy()
        None => []
      },
      defs: match defs {
        Some(items) => items.copy()
        None => []
      },
      jmps: match jmps {
        Some(items) => items.copy()
        None => []
      },
    },
    tid?,
  )
}

///|
pub fn Term::phis(self : Term[Blk]) -> Array[Term[Phi]] {
  self.payload_value.phis.copy()
}

///|
pub fn Term::defs(self : Term[Blk]) -> Array[Term[Def]] {
  self.payload_value.defs.copy()
}

///|
pub fn Term::jmps(self : Term[Blk]) -> Array[Term[Jmp]] {
  self.payload_value.jmps.copy()
}

///|
pub fn Term::elts(self : Term[Blk], rev? : Bool = false) -> Array[BlkElt] {
  let elts = []
  for phi in self.payload_value.phis {
    elts.push(PhiElt(phi))
  }
  for def in self.payload_value.defs {
    elts.push(DefElt(def))
  }
  for jmp in self.payload_value.jmps {
    elts.push(JmpElt(jmp))
  }
  if rev {
    elts.rev()
  } else {
    elts
  }
}

///|
pub fn Term::append_phi(self : Term[Blk], phi : Term[Phi]) -> Term[Blk] {
  let phis = self.payload_value.phis.copy()
  phis.push(phi)
  self.with_payload({ ..self.payload_value, phis, })
}

///|
pub fn Term::append_def(self : Term[Blk], def : Term[Def]) -> Term[Blk] {
  let defs = self.payload_value.defs.copy()
  defs.push(def)
  self.with_payload({ ..self.payload_value, defs, })
}

///|
pub fn Term::append_jmp(self : Term[Blk], jmp : Term[Jmp]) -> Term[Blk] {
  let jmps = self.payload_value.jmps.copy()
  jmps.push(jmp)
  self.with_payload({ ..self.payload_value, jmps, })
}

///|
pub fn Term::find_def(self : Term[Blk], tid : Tid) -> Term[Def]? {
  self.payload_value.defs
  .search_by(term => term.tid() == tid)
  .map(i => self.payload_value.defs[i])
}

///|
pub fn Term::defines_var(self : Term[Blk], variable : Var) -> Bool {
  self.payload_value.defs.any(term => term.payload().lhs == variable) ||
  self.payload_value.phis.any(term => term.payload().lhs == variable)
}

///|
pub fn Def::create(lhs : Var, rhs : Exp, tid? : Tid) -> Term[Def] {
  Term::create({ lhs, rhs }, tid?)
}

///|
pub fn Term::lhs(self : Term[Def]) -> Var {
  self.payload_value.lhs
}

///|
pub fn Term::rhs(self : Term[Def]) -> Exp {
  self.payload_value.rhs
}

///|
pub fn Term::with_lhs(self : Term[Def], lhs : Var) -> Term[Def] {
  self.with_payload({ ..self.payload_value, lhs, })
}

///|
pub fn Term::with_rhs(self : Term[Def], rhs : Exp) -> Term[Def] {
  self.with_payload({ ..self.payload_value, rhs, })
}

///|
pub fn Phi::of_list(
  lhs : Var,
  values : Array[(Tid, Exp)],
  tid? : Tid,
) -> Term[Phi] {
  Term::create({ lhs, values: values.copy() }, tid?)
}

///|
pub fn Phi::create(lhs : Var, src : Tid, exp : Exp, tid? : Tid) -> Term[Phi] {
  Phi::of_list(lhs, [(src, exp)], tid?)
}

///|
pub fn Term::phi_lhs(self : Term[Phi]) -> Var {
  self.payload_value.lhs
}

///|
pub fn Term::with_phi_lhs(self : Term[Phi], lhs : Var) -> Term[Phi] {
  self.with_payload({ ..self.payload_value, lhs, })
}

///|
pub fn Term::values(self : Term[Phi]) -> Array[(Tid, Exp)] {
  self.payload_value.values.copy()
}

///|
pub fn Term::select(self : Term[Phi], tid : Tid) -> Exp? {
  self.payload_value.values
  .search_by(pair => pair.0 == tid)
  .map(i => self.payload_value.values[i].1)
}

///|
pub fn Term::select_or_unknown(self : Term[Phi], tid : Tid) -> Exp {
  match self.select(tid) {
    Some(exp) => exp
    None => Unknown("unresolved-tid \{tid.to_string()}", self.phi_lhs().typ())
  }
}

///|
pub fn Term::update_phi(self : Term[Phi], tid : Tid, exp : Exp) -> Term[Phi] {
  let values = self.payload_value.values.copy()
  match values.search_by(pair => pair.0 == tid) {
    Some(i) => values[i] = (tid, exp)
    None => values.push((tid, exp))
  }
  self.with_payload({ ..self.payload_value, values, })
}

///|
pub fn Term::remove_phi(self : Term[Phi], tid : Tid) -> Term[Phi] {
  self.with_payload({
    ..self.payload_value,
    values: self.payload_value.values.filter(pair => pair.0 != tid),
  })
}

///|
pub fn Jmp::create(kind : JmpKind, cond? : Exp, tid? : Tid) -> Term[Jmp] {
  Term::create(
    {
      kind,
      cond: match cond {
        Some(exp) => exp
        None => Int(Word::b1())
      },
    },
    tid?,
  )
}

///|
pub fn Jmp::create_goto(label : Label, cond? : Exp, tid? : Tid) -> Term[Jmp] {
  Jmp::create(Goto(label), cond?, tid?)
}

///|
pub fn Jmp::create_call(call : Call, cond? : Exp, tid? : Tid) -> Term[Jmp] {
  Jmp::create(JmpCall(call), cond?, tid?)
}

///|
pub fn Jmp::create_ret(label : Label, cond? : Exp, tid? : Tid) -> Term[Jmp] {
  Jmp::create(Ret(label), cond?, tid?)
}

///|
pub fn Jmp::create_int(
  num : Int,
  tid : Tid,
  cond? : Exp,
  term_tid? : Tid,
) -> Term[Jmp] {
  Jmp::create(Interrupt(num, tid), cond?, tid?=term_tid)
}

///|
pub fn Term::kind(self : Term[Jmp]) -> JmpKind {
  self.payload_value.kind
}

///|
pub fn Term::cond(self : Term[Jmp]) -> Exp {
  self.payload_value.cond
}

///|
pub fn Term::with_kind(self : Term[Jmp], kind : JmpKind) -> Term[Jmp] {
  self.with_payload({ ..self.payload_value, kind, })
}

///|
pub fn Term::with_cond(self : Term[Jmp], cond : Exp) -> Term[Jmp] {
  self.with_payload({ ..self.payload_value, cond, })
}

///|
pub fn Term::dst(self : Term[Jmp]) -> JmpDst? {
  match self.kind() {
    Goto(label) => Some(jmp_dst_of_label(label))
    Ret(_) => None
    Interrupt(_, tid) => Some(ResolvedDst(tid))
    JmpCall(call) => call.return_label.map(jmp_dst_of_label)
  }
}

///|
pub fn Term::alt(self : Term[Jmp]) -> JmpDst? {
  match self.kind() {
    Goto(_) => None
    Ret(label) => Some(jmp_dst_of_label(label))
    Interrupt(ivec, _) => Some(ResolvedDst(Tid::for_ivec(ivec)))
    JmpCall(call) => Some(jmp_dst_of_label(call.target))
  }
}

///|
pub fn Term::with_dst(self : Term[Jmp], dst : JmpDst?) -> Term[Jmp] {
  self.with_kind(jmp_kind_of_dst_alt(dst, self.alt()))
}

///|
pub fn Term::with_alt(self : Term[Jmp], alt : JmpDst?) -> Term[Jmp] {
  self.with_kind(jmp_kind_of_dst_alt(self.dst(), alt))
}

///|
pub fn Arg::create(
  lhs : Var,
  rhs : Exp,
  intent? : Intent,
  tid? : Tid,
) -> Term[Arg] {
  Term::create({ lhs, rhs, intent }, tid?)
}

///|
pub fn Term::arg_lhs(self : Term[Arg]) -> Var {
  self.payload_value.lhs
}

///|
pub fn Term::arg_rhs(self : Term[Arg]) -> Exp {
  self.payload_value.rhs
}

///|
pub fn Term::intent(self : Term[Arg]) -> Intent? {
  self.payload_value.intent
}

///|
pub fn Term::with_intent(self : Term[Arg], intent : Intent) -> Term[Arg] {
  self.with_payload({ ..self.payload_value, intent: Some(intent) })
}

///|
pub fn Term::with_unknown_intent(self : Term[Arg]) -> Term[Arg] {
  self.with_payload({ ..self.payload_value, intent: None })
}

///|
fn ir_term_join_lines(lines : Array[String]) -> String {
  let builder = StringBuilder()
  for i, line in lines {
    if i > 0 {
      builder.write_string("\n")
    }
    builder.write_string(line)
  }
  builder.to_string()
}

///|
fn ir_term_intent_prefix(intent : Intent?) -> String {
  match intent {
    Some(In) => "in "
    Some(Out) => "out "
    Some(Both) => "in out "
    None => ""
  }
}

///|
pub fn Term::arg_to_string(self : Term[Arg]) -> String {
  let lhs = self.arg_lhs()
  "\{lhs.name()} :: \{ir_term_intent_prefix(self.intent())}\{lhs.typ().to_string()} = \{self.arg_rhs().to_string()}"
}

///|
pub fn Term::def_to_string(self : Term[Def]) -> String {
  "\{self.lhs().to_string()} := \{self.rhs().to_string()}"
}

///|
pub fn Term::phi_to_string(self : Term[Phi]) -> String {
  let values = []
  for value in self.values() {
    values.push("[\{value.1.to_string()}, \{value.0.to_string()}]")
  }
  "\{self.phi_lhs().to_string()} <- phi(\{values.join(", ")})"
}

///|
pub fn Term::jmp_to_string(self : Term[Jmp]) -> String {
  let cond = self.cond()
  let prefix = match cond {
    Int(word) if word.is_one() => ""
    _ => "when \{cond.to_string()} "
  }
  let body = match self.kind() {
    JmpCall(call) =>
      match call.return_label {
        Some(label) =>
          "call \{call.target.to_string()} with return \{label.to_string()}"
        None => "call \{call.target.to_string()} with noreturn"
      }
    Goto(label) => "goto \{label.to_string()}"
    Ret(label) => "return \{label.to_string()}"
    Interrupt(num, tid) =>
      "interrupt 0x\{num.to_string(radix=16).to_upper()} return \{tid.to_string()}"
  }
  prefix + body
}

///|
pub fn Term::blk_to_string(self : Term[Blk]) -> String {
  let lines : Array[String] = [self.name()]
  for phi in self.phis() {
    lines.push(phi.phi_to_string())
  }
  for def in self.defs() {
    lines.push(def.def_to_string())
  }
  for jmp in self.jmps() {
    lines.push(jmp.jmp_to_string())
  }
  ir_term_join_lines(lines)
}

///|
pub fn Term::sub_to_string(self : Term[Sub]) -> String {
  let arg_names = self.args().map(arg => arg.arg_lhs().name())
  let lines : Array[String] = [
    "sub \{self.sub_name()}(\{arg_names.join(", ")})",
  ]
  for arg in self.args() {
    lines.push(arg.arg_to_string())
  }
  for blk in self.blks() {
    lines.push(blk.blk_to_string())
  }
  ir_term_join_lines(lines)
}

///|
pub fn Term::program_to_string(self : Term[Program]) -> String {
  let lines : Array[String] = ["program"]
  for sub in self.subs() {
    lines.push(sub.sub_to_string())
  }
  ir_term_join_lines(lines)
}
