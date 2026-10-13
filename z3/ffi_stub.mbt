// The backend for targets without a C FFI: the solver is never
// available, `Context::new` reports it, and no other entry point is
// reachable (they return placeholders).

///|
type RawCtx = Unit

///|
type RawAst = Unit

///|
type RawSolver = Unit

///|
type RawModel = Unit

///|
let stub_reason : String = "Z3 is only available on the native target"

///|
fn raw_available() -> Bool {
  false
}

///|
fn raw_load(_path : Bytes) -> Bytes {
  @utf8.encode(stub_reason)
}

///|
fn raw_load_error() -> Bytes {
  @utf8.encode(stub_reason)
}

///|
fn raw_version() -> Bytes {
  b""
}

///|
fn raw_mk_context(_config : Bytes) -> RawCtx {
  ()
}

///|
fn raw_ctx_is_null(_c : RawCtx) -> Bool {
  true
}

///|
fn raw_error_code(_c : RawCtx) -> Int32 {
  -1
}

///|
fn raw_error(_c : RawCtx) -> Bytes {
  @utf8.encode(stub_reason)
}

///|
fn raw_update_param(_c : RawCtx, _key : Bytes, _value : Bytes) -> Unit {
  ()
}

///|
fn raw_ast_is_null(_a : RawAst) -> Bool {
  true
}

///|
fn raw_bool_val(_c : RawCtx, _b : Bool) -> RawAst {
  ()
}

///|
fn raw_bv_const(_c : RawCtx, _name : Bytes, _width : Int32) -> RawAst {
  ()
}

///|
fn raw_bool_const(_c : RawCtx, _name : Bytes) -> RawAst {
  ()
}

///|
fn raw_bv_numeral(_c : RawCtx, _dec : Bytes, _width : Int32) -> RawAst {
  ()
}

///|
fn raw_binop(_c : RawCtx, _op : Int32, _x : RawAst, _y : RawAst) -> RawAst {
  ()
}

///|
fn raw_unop(_c : RawCtx, _op : Int32, _x : RawAst) -> RawAst {
  ()
}

///|
fn raw_indexed(_c : RawCtx, _op : Int32, _n : Int32, _x : RawAst) -> RawAst {
  ()
}

///|
fn raw_extract(_c : RawCtx, _hi : Int32, _lo : Int32, _x : RawAst) -> RawAst {
  ()
}

///|
fn raw_ite(_c : RawCtx, _cnd : RawAst, _x : RawAst, _y : RawAst) -> RawAst {
  ()
}

///|
fn raw_sort_of(_c : RawCtx, _x : RawAst) -> Int32 {
  -1
}

///|
fn raw_is_numeral(_c : RawCtx, _x : RawAst) -> Bool {
  false
}

///|
fn raw_numeral_string(_c : RawCtx, _x : RawAst) -> Bytes {
  b""
}

///|
fn raw_bool_value(_c : RawCtx, _x : RawAst) -> Int32 {
  0
}

///|
fn raw_ast_to_string(_c : RawCtx, _x : RawAst) -> Bytes {
  b""
}

///|
fn raw_ast_id(_c : RawCtx, _x : RawAst) -> Int32 {
  0
}

///|
fn raw_ast_hash(_c : RawCtx, _x : RawAst) -> Int32 {
  0
}

///|
fn raw_ast_eq(_c : RawCtx, _x : RawAst, _y : RawAst) -> Bool {
  false
}

///|
fn raw_mk_solver(_c : RawCtx, _kind : Int32) -> RawSolver {
  ()
}

///|
fn raw_solver_is_null(_s : RawSolver) -> Bool {
  true
}

///|
fn raw_solver_set_uint(
  _c : RawCtx,
  _s : RawSolver,
  _key : Bytes,
  _value : Int32,
) -> Unit {
  ()
}

///|
fn raw_solver_push(_c : RawCtx, _s : RawSolver) -> Unit {
  ()
}

///|
fn raw_solver_pop(_c : RawCtx, _s : RawSolver, _n : Int32) -> Unit {
  ()
}

///|
fn raw_solver_reset(_c : RawCtx, _s : RawSolver) -> Unit {
  ()
}

///|
fn raw_solver_num_scopes(_c : RawCtx, _s : RawSolver) -> Int32 {
  0
}

///|
fn raw_solver_assert(_c : RawCtx, _s : RawSolver, _x : RawAst) -> Unit {
  ()
}

///|
fn raw_solver_check(_c : RawCtx, _s : RawSolver) -> Int32 {
  0
}

///|
fn raw_solver_reason_unknown(_c : RawCtx, _s : RawSolver) -> Bytes {
  @utf8.encode(stub_reason)
}

///|
fn raw_solver_to_string(_c : RawCtx, _s : RawSolver) -> Bytes {
  b""
}

///|
fn raw_solver_model(_c : RawCtx, _s : RawSolver) -> RawModel {
  ()
}

///|
fn raw_model_is_null(_m : RawModel) -> Bool {
  true
}

///|
fn raw_model_eval(
  _c : RawCtx,
  _m : RawModel,
  _x : RawAst,
  _completion : Bool,
) -> RawAst {
  ()
}

///|
fn raw_model_to_string(_c : RawCtx, _m : RawModel) -> Bytes {
  b""
}
