// The native backend of the binding: `z3_stub.c` loads the Z3 library
// at run time and wraps its objects in MoonBit external objects.

///|
/// A Z3 context (an external object deleting the context when released).
type RawCtx

///|
/// A Z3 term holding a reference to its context.
type RawAst

///|
/// A Z3 solver holding a reference to its context.
type RawSolver

///|
/// A Z3 model holding a reference to its context.
type RawModel

///|
extern "c" fn raw_available() -> Bool = "bap_z3_available"

///|
#borrow(path)
extern "c" fn raw_load(path : Bytes) -> Bytes = "bap_z3_load"

///|
extern "c" fn raw_load_error() -> Bytes = "bap_z3_load_error_message"

///|
extern "c" fn raw_version() -> Bytes = "bap_z3_version"

///|
#borrow(config)
extern "c" fn raw_mk_context(config : Bytes) -> RawCtx = "bap_z3_mk_context"

///|
#borrow(c)
extern "c" fn raw_ctx_is_null(c : RawCtx) -> Bool = "bap_z3_ctx_is_null"

///|
#borrow(c)
extern "c" fn raw_error_code(c : RawCtx) -> Int32 = "bap_z3_error_code"

///|
#borrow(c)
extern "c" fn raw_error(c : RawCtx) -> Bytes = "bap_z3_error"

///|
#borrow(c, key, value)
extern "c" fn raw_update_param(c : RawCtx, key : Bytes, value : Bytes) = "bap_z3_update_param"

///|
#borrow(a)
extern "c" fn raw_ast_is_null(a : RawAst) -> Bool = "bap_z3_ast_is_null"

///|
#borrow(c)
extern "c" fn raw_bool_val(c : RawCtx, b : Bool) -> RawAst = "bap_z3_bool_val"

///|
#borrow(c, name)
extern "c" fn raw_bv_const(c : RawCtx, name : Bytes, width : Int32) -> RawAst = "bap_z3_bv_const"

///|
#borrow(c, name)
extern "c" fn raw_bool_const(c : RawCtx, name : Bytes) -> RawAst = "bap_z3_bool_const"

///|
#borrow(c, dec)
extern "c" fn raw_bv_numeral(c : RawCtx, dec : Bytes, width : Int32) -> RawAst = "bap_z3_bv_numeral"

///|
#borrow(c, x, y)
extern "c" fn raw_binop(
  c : RawCtx,
  op : Int32,
  x : RawAst,
  y : RawAst,
) -> RawAst = "bap_z3_binop"

///|
#borrow(c, x)
extern "c" fn raw_unop(c : RawCtx, op : Int32, x : RawAst) -> RawAst = "bap_z3_unop"

///|
#borrow(c, x)
extern "c" fn raw_indexed(
  c : RawCtx,
  op : Int32,
  n : Int32,
  x : RawAst,
) -> RawAst = "bap_z3_indexed"

///|
#borrow(c, x)
extern "c" fn raw_extract(
  c : RawCtx,
  hi : Int32,
  lo : Int32,
  x : RawAst,
) -> RawAst = "bap_z3_extract"

///|
#borrow(c, cnd, x, y)
extern "c" fn raw_ite(
  c : RawCtx,
  cnd : RawAst,
  x : RawAst,
  y : RawAst,
) -> RawAst = "bap_z3_ite"

///|
#borrow(c, x)
extern "c" fn raw_sort_of(c : RawCtx, x : RawAst) -> Int32 = "bap_z3_sort_of"

///|
#borrow(c, x)
extern "c" fn raw_is_numeral(c : RawCtx, x : RawAst) -> Bool = "bap_z3_is_numeral"

///|
#borrow(c, x)
extern "c" fn raw_numeral_string(c : RawCtx, x : RawAst) -> Bytes = "bap_z3_numeral_string"

///|
#borrow(c, x)
extern "c" fn raw_bool_value(c : RawCtx, x : RawAst) -> Int32 = "bap_z3_bool_value"

///|
#borrow(c, x)
extern "c" fn raw_ast_to_string(c : RawCtx, x : RawAst) -> Bytes = "bap_z3_ast_to_string"

///|
#borrow(c, x)
extern "c" fn raw_ast_id(c : RawCtx, x : RawAst) -> Int32 = "bap_z3_ast_id"

///|
#borrow(c, x)
extern "c" fn raw_ast_hash(c : RawCtx, x : RawAst) -> Int32 = "bap_z3_ast_hash"

///|
#borrow(c, x, y)
extern "c" fn raw_ast_eq(c : RawCtx, x : RawAst, y : RawAst) -> Bool = "bap_z3_ast_eq"

///|
#borrow(c)
extern "c" fn raw_mk_solver(c : RawCtx, kind : Int32) -> RawSolver = "bap_z3_mk_solver"

///|
#borrow(s)
extern "c" fn raw_solver_is_null(s : RawSolver) -> Bool = "bap_z3_solver_is_null"

///|
#borrow(c, s, key)
extern "c" fn raw_solver_set_uint(
  c : RawCtx,
  s : RawSolver,
  key : Bytes,
  value : Int32,
) = "bap_z3_solver_set_uint"

///|
#borrow(c, s)
extern "c" fn raw_solver_push(c : RawCtx, s : RawSolver) = "bap_z3_solver_push"

///|
#borrow(c, s)
extern "c" fn raw_solver_pop(c : RawCtx, s : RawSolver, n : Int32) = "bap_z3_solver_pop"

///|
#borrow(c, s)
extern "c" fn raw_solver_reset(c : RawCtx, s : RawSolver) = "bap_z3_solver_reset"

///|
#borrow(c, s)
extern "c" fn raw_solver_num_scopes(c : RawCtx, s : RawSolver) -> Int32 = "bap_z3_solver_num_scopes"

///|
#borrow(c, s, x)
extern "c" fn raw_solver_assert(c : RawCtx, s : RawSolver, x : RawAst) = "bap_z3_solver_assert"

///|
#borrow(c, s)
extern "c" fn raw_solver_check(c : RawCtx, s : RawSolver) -> Int32 = "bap_z3_solver_check"

///|
#borrow(c, s)
extern "c" fn raw_solver_reason_unknown(c : RawCtx, s : RawSolver) -> Bytes = "bap_z3_solver_reason_unknown"

///|
#borrow(c, s)
extern "c" fn raw_solver_to_string(c : RawCtx, s : RawSolver) -> Bytes = "bap_z3_solver_to_string"

///|
#borrow(c, s)
extern "c" fn raw_solver_model(c : RawCtx, s : RawSolver) -> RawModel = "bap_z3_solver_model"

///|
#borrow(m)
extern "c" fn raw_model_is_null(m : RawModel) -> Bool = "bap_z3_model_is_null"

///|
#borrow(c, m, x)
extern "c" fn raw_model_eval(
  c : RawCtx,
  m : RawModel,
  x : RawAst,
  completion : Bool,
) -> RawAst = "bap_z3_model_eval"

///|
#borrow(c, m)
extern "c" fn raw_model_to_string(c : RawCtx, m : RawModel) -> Bytes = "bap_z3_model_to_string"
