// Explicit method promotion of derived and implemented traits.

///|
pub extend Z3Error with Eq::{not_equal, equal}

///|
pub extend Z3Error with Debug::{to_repr}

///|
pub extend Sort with Eq::{not_equal, equal}

///|
pub extend Sort with Debug::{to_repr}

///|
pub extend BinOp with Eq::{not_equal, equal}

///|
pub extend BinOp with Debug::{to_repr}

///|
pub extend UnOp with Eq::{not_equal, equal}

///|
pub extend UnOp with Debug::{to_repr}

///|
pub extend CheckResult with Eq::{not_equal, equal}

///|
pub extend CheckResult with Debug::{to_repr}

///|
pub extend Expr with Show::{output}

///|
pub extend Expr with Eq::{not_equal, equal}

///|
pub extend Expr with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Expr with Hash::{hash, hash_combine}

///|
pub extend Z3Error with Show::{output, to_string}
