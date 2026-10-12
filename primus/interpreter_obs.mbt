// Observations of the interpreter (upstream `Primus.Interpreter.*`
// observation values). For every observation `x` there is a private
// statement `x_stmt` used by the interpreter to post it.

///|
fn tid_sexp(t : @types.Tid) -> Sexp {
  Atom(t.to_string())
}

///|
fn[T] term_sexp(t : @types.Term[T]) -> Sexp {
  tid_sexp(t.tid())
}

///|
fn word_sexp(w : @types.Word) -> Sexp {
  Atom(w.to_hex())
}

///|
fn values_sexp(p : (Value, Value)) -> Sexp {
  List([p.0.to_sexp(), p.1.to_sexp()])
}

///|
fn binding_sexp(p : (@types.Var, Value)) -> Sexp {
  List([Atom(p.0.name()), p.1.to_sexp()])
}

///|
fn results_sexp(r : Value, op : Array[String]) -> Sexp {
  List([Sexp::atoms(op), r.to_sexp()])
}

///|
fn[T] provide_term(name : String, before : Bool) -> Statement[@types.Term[T]] {
  let desc = if before {
    "Occurs before the given term is evaluated."
  } else {
    "Occurs after the given term is evaluated."
  }
  Statement::provide(name, inspect=term_sexp, desc~)
}

///|
let clock_stmt : Statement[Int32] = Statement::provide(
  "clock",
  inspect=t => Atom(t.to_string()),
  desc="Occurs on each clock (operation) of the interpreter.",
)

///|
/// Occurs on each clock (operation) of the interpreter (`Interpreter.clock`).
pub let clock : Observation[Int32] = clock_stmt.obs

///|
let memory_switch_stmt : Statement[Descriptor] = Statement::provide(
  "memory-switch",
  inspect=Descriptor::to_sexp,
  desc="Occurs when the memory bank is switched.",
)

///|
/// Occurs when the memory bank is switched.
pub let memory_switch : Observation[Descriptor] = memory_switch_stmt.obs

///|
let enter_term_stmt : Statement[@types.Tid] = Statement::provide(
  "enter-term",
  inspect=tid_sexp,
  desc="Occurs before the given term.",
)

///|
pub let enter_term : Observation[@types.Tid] = enter_term_stmt.obs

///|
let leave_term_stmt : Statement[@types.Tid] = Statement::provide(
  "leave-term",
  inspect=tid_sexp,
  desc="Occurs after the given term is evaluated.",
)

///|
pub let leave_term : Observation[@types.Tid] = leave_term_stmt.obs

///|
let enter_pos_stmt : Statement[Pos] = Statement::provide(
  "enter-pos",
  inspect=Pos::to_sexp,
  desc="Occurs before the given position is evaluated.",
)

///|
pub let enter_pos : Observation[Pos] = enter_pos_stmt.obs

///|
let leave_pos_stmt : Statement[Pos] = Statement::provide(
  "leave-pos",
  inspect=Pos::to_sexp,
  desc="Occurs after the given position is evaluated.",
)

///|
pub let leave_pos : Observation[Pos] = leave_pos_stmt.obs

///|
let enter_top_stmt : Statement[@types.Term[@types.Program]] = provide_term(
  "enter-top", true,
)

///|
pub let enter_top : Observation[@types.Term[@types.Program]] = enter_top_stmt.obs

///|
let enter_sub_stmt : Statement[@types.Term[@types.Sub]] = provide_term(
  "enter-sub", true,
)

///|
pub let enter_sub : Observation[@types.Term[@types.Sub]] = enter_sub_stmt.obs

///|
let enter_arg_stmt : Statement[@types.Term[@types.Arg]] = provide_term(
  "enter-arg", true,
)

///|
pub let enter_arg : Observation[@types.Term[@types.Arg]] = enter_arg_stmt.obs

///|
let enter_blk_stmt : Statement[@types.Term[@types.Blk]] = provide_term(
  "enter-blk", true,
)

///|
pub let enter_blk : Observation[@types.Term[@types.Blk]] = enter_blk_stmt.obs

///|
let enter_phi_stmt : Statement[@types.Term[@types.Phi]] = provide_term(
  "enter-phi", true,
)

///|
pub let enter_phi : Observation[@types.Term[@types.Phi]] = enter_phi_stmt.obs

///|
let enter_def_stmt : Statement[@types.Term[@types.Def]] = provide_term(
  "enter-def", true,
)

///|
pub let enter_def : Observation[@types.Term[@types.Def]] = enter_def_stmt.obs

///|
let enter_jmp_stmt : Statement[@types.Term[@types.Jmp]] = provide_term(
  "enter-jmp", true,
)

///|
pub let enter_jmp : Observation[@types.Term[@types.Jmp]] = enter_jmp_stmt.obs

///|
let leave_top_stmt : Statement[@types.Term[@types.Program]] = provide_term(
  "leave-top", false,
)

///|
pub let leave_top : Observation[@types.Term[@types.Program]] = leave_top_stmt.obs

///|
let leave_sub_stmt : Statement[@types.Term[@types.Sub]] = provide_term(
  "leave-sub", false,
)

///|
pub let leave_sub : Observation[@types.Term[@types.Sub]] = leave_sub_stmt.obs

///|
let leave_arg_stmt : Statement[@types.Term[@types.Arg]] = provide_term(
  "leave-arg", false,
)

///|
pub let leave_arg : Observation[@types.Term[@types.Arg]] = leave_arg_stmt.obs

///|
let leave_blk_stmt : Statement[@types.Term[@types.Blk]] = provide_term(
  "leave-blk", false,
)

///|
pub let leave_blk : Observation[@types.Term[@types.Blk]] = leave_blk_stmt.obs

///|
let leave_phi_stmt : Statement[@types.Term[@types.Phi]] = provide_term(
  "leave-phi", false,
)

///|
pub let leave_phi : Observation[@types.Term[@types.Phi]] = leave_phi_stmt.obs

///|
let leave_def_stmt : Statement[@types.Term[@types.Def]] = provide_term(
  "leave-def", false,
)

///|
pub let leave_def : Observation[@types.Term[@types.Def]] = leave_def_stmt.obs

///|
let leave_jmp_stmt : Statement[@types.Term[@types.Jmp]] = provide_term(
  "leave-jmp", false,
)

///|
pub let leave_jmp : Observation[@types.Term[@types.Jmp]] = leave_jmp_stmt.obs

///|
let enter_exp_stmt : Statement[@types.Exp] = Statement::provide(
  "enter-exp",
  inspect=e => Atom(e.to_string()),
  desc="Occurs before the given exp is evaluated.",
)

///|
pub let enter_exp : Observation[@types.Exp] = enter_exp_stmt.obs

///|
let leave_exp_stmt : Statement[@types.Exp] = Statement::provide(
  "leave-exp",
  inspect=e => Atom(e.to_string()),
  desc="Occurs after the given exp is evaluated.",
)

///|
pub let leave_exp : Observation[@types.Exp] = leave_exp_stmt.obs

///|
let pc_changed_stmt : Statement[@types.Word] = Statement::provide(
  "pc-changed",
  inspect=word_sexp,
  desc="Occurs after the program counter is changed.",
)

///|
/// Occurs after the program counter is changed (`Interpreter.pc_change`).
pub let pc_change : Observation[@types.Word] = pc_changed_stmt.obs

///|
let will_halt_stmt : Statement[Unit] = Statement::provide(
  "halting",
  inspect=_ => List([]),
  desc="Occurs before the halt operation is posted.",
)

///|
pub let halting : Observation[Unit] = will_halt_stmt.obs

///|
let will_divide_by_zero_stmt : Statement[Unit] = Statement::provide(
  "division-by-zero",
  inspect=_ => List([]),
  desc="Occurs before the division by zero happens.",
)

///|
pub let division_by_zero : Observation[Unit] = will_divide_by_zero_stmt.obs

///|
let cfi_will_diverge_stmt : Statement[@types.Word] = Statement::provide(
  "cfi-violation",
  inspect=word_sexp,
  desc="Occurs before the control flow violation is commited.",
)

///|
pub let cfi_violation : Observation[@types.Word] = cfi_will_diverge_stmt.obs

///|
let will_segfault_stmt : Statement[@types.Word] = Statement::provide(
  "segfault",
  inspect=word_sexp,
  desc="Occurs just before the segmentation fault.",
)

///|
pub let segfault : Observation[@types.Word] = will_segfault_stmt.obs

///|
let page_fail_stmt : Statement[@types.Word] = Statement::provide(
  "pagefault",
  inspect=word_sexp,
  desc="Occurs on pagefault.",
)

///|
pub let pagefault : Observation[@types.Word] = page_fail_stmt.obs

///|
let will_interrupt_stmt : Statement[Int32] = Statement::provide(
  "interrupt",
  inspect=n => Atom(n.to_string()),
  desc="Occurs before an interrupt.",
)

///|
pub let interrupt : Observation[Int32] = will_interrupt_stmt.obs

///|
let on_loading_stmt : Statement[Value] = Statement::provide(
  "loading",
  inspect=Value::to_sexp,
  desc="Occurs just before the given address is dereferenced.",
)

///|
pub let loading : Observation[Value] = on_loading_stmt.obs

///|
let on_loaded_stmt : Statement[(Value, Value)] = Statement::provide(
  "loaded",
  inspect=values_sexp,
  desc="Occurs after the given address is read.",
)

///|
pub let loaded : Observation[(Value, Value)] = on_loaded_stmt.obs

///|
let on_storing_stmt : Statement[Value] = Statement::provide(
  "storing",
  inspect=Value::to_sexp,
  desc="Occurs before the value is stored at the address.",
)

///|
pub let storing : Observation[Value] = on_storing_stmt.obs

///|
let on_stored_stmt : Statement[(Value, Value)] = Statement::provide(
  "stored",
  inspect=values_sexp,
  desc="Occurs after the value is stored at the address.",
)

///|
pub let stored : Observation[(Value, Value)] = on_stored_stmt.obs

///|
let on_reading_stmt : Statement[@types.Var] = Statement::provide(
  "reading",
  inspect=v => Atom(v.name()),
  desc="Occurs before the given variable is read.",
)

///|
pub let reading : Observation[@types.Var] = on_reading_stmt.obs

///|
let on_read_stmt : Statement[(@types.Var, Value)] = Statement::provide(
  "read",
  inspect=binding_sexp,
  desc="Occurs after the given variable is evaluated to the value.",
)

///|
pub let read : Observation[(@types.Var, Value)] = on_read_stmt.obs

///|
let on_writing_stmt : Statement[@types.Var] = Statement::provide(
  "writing",
  inspect=v => Atom(v.name()),
  desc="Occurs before the value is assigned to the variable.",
)

///|
pub let writing : Observation[@types.Var] = on_writing_stmt.obs

///|
let on_written_stmt : Statement[(@types.Var, Value)] = Statement::provide(
  "written",
  inspect=binding_sexp,
  desc="Occurs after the value is assigned to the variable.",
)

///|
pub let written : Observation[(@types.Var, Value)] = on_written_stmt.obs

///|
let on_undefined_stmt : Statement[Value] = Statement::provide(
  "undefined",
  inspect=Value::to_sexp,
  desc="Occurs when an undefined value is created.",
)

///|
pub let undefined : Observation[Value] = on_undefined_stmt.obs

///|
let will_jump_stmt : Statement[(Value, Value)] = Statement::provide(
  "jumping",
  inspect=values_sexp,
  desc="Occurs before the jump to the given destination.",
)

///|
/// Occurs before a jump, with `(condition, destination)`.
pub let jumping : Observation[(Value, Value)] = will_jump_stmt.obs

///|
let on_cond_stmt : Statement[Value] = Statement::provide(
  "eval-cond",
  inspect=Value::to_sexp,
  desc="Occurs when the jump condition is evaluated.",
)

///|
pub let eval_cond : Observation[Value] = on_cond_stmt.obs

///|
let on_const_stmt : Statement[Value] = Statement::provide(
  "const",
  inspect=Value::to_sexp,
  desc="Occurs on each constant.",
)

///|
/// Occurs on each constant (`Interpreter.const`).
pub let const_obs : Observation[Value] = on_const_stmt.obs

///|
let on_binop_stmt : Statement[((@types.BinOp, Value, Value), Value)] = Statement::provide(
  "binop",
  inspect=p => {
    let ((op, x, y), r) = p
    results_sexp(r, [op.to_string(), x.to_string(), y.to_string()])
  },
  desc="Occurs on each binary operation.",
)

///|
pub let binop : Observation[((@types.BinOp, Value, Value), Value)] = on_binop_stmt.obs

///|
let on_unop_stmt : Statement[((@types.UnOp, Value), Value)] = Statement::provide(
  "unop",
  inspect=p => {
    let ((op, x), r) = p
    results_sexp(r, [op.to_string(), x.to_string()])
  },
  desc="Occurs on each unary operation.",
)

///|
pub let unop : Observation[((@types.UnOp, Value), Value)] = on_unop_stmt.obs

///|
let on_cast_stmt : Statement[((@types.CastKind, Int32, Value), Value)] = Statement::provide(
  "cast",
  inspect=p => {
    let ((t, s, x), r) = p
    results_sexp(r, [t.to_string(), s.to_string(), x.to_string()])
  },
  desc="Occurs on each cast.",
)

///|
pub let cast : Observation[((@types.CastKind, Int32, Value), Value)] = on_cast_stmt.obs

///|
let on_extract_stmt : Statement[((Int32, Int32, Value), Value)] = Statement::provide(
  "extract",
  inspect=p => {
    let ((hi, lo, x), r) = p
    results_sexp(r, [hi.to_string(), lo.to_string(), x.to_string()])
  },
  desc="Occurs on each extract operation.",
)

///|
pub let extract : Observation[((Int32, Int32, Value), Value)] = on_extract_stmt.obs

///|
let on_concat_stmt : Statement[((Value, Value), Value)] = Statement::provide(
  "concat",
  inspect=p => {
    let ((x, y), r) = p
    results_sexp(r, [x.to_string(), y.to_string()])
  },
  desc="Occurs on each concat operation.",
)

///|
pub let concat : Observation[((Value, Value), Value)] = on_concat_stmt.obs

///|
let on_ite_stmt : Statement[((Value, Value, Value), Value)] = Statement::provide(
  "ite",
  inspect=p => {
    let ((c, y, n), r) = p
    results_sexp(r, [c.to_string(), y.to_string(), n.to_string()])
  },
  desc="Occurs on each ite expression.",
)

///|
pub let ite : Observation[((Value, Value, Value), Value)] = on_ite_stmt.obs
