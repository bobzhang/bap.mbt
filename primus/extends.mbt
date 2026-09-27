// Explicit method promotion of derived and implemented traits.

///|
pub extend Descriptor with Debug::{to_repr}

///|
pub extend Descriptor with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Descriptor with Eq::{not_equal, equal}

///|
pub extend ExitStatus with Show::{output}

///|
pub extend ForkStatus with Debug::{to_repr}

///|
pub extend ForkStatus with Eq::{not_equal, equal}

///|
pub extend Id with Debug::{to_repr}

///|
pub extend Id with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Id with Eq::{not_equal, equal}

///|
pub extend Id with Hash::{hash, hash_combine}

///|
pub extend Id with Show::{to_string, output}

///|
pub extend Name with Debug::{to_repr}

///|
pub extend Name with Eq::{not_equal, equal}

///|
pub extend Name with Show::{output}

///|
pub extend Pos with Show::{output}

///|
pub extend Sexp with Debug::{to_repr}

///|
pub extend Sexp with Eq::{not_equal, equal}

///|
pub extend Sexp with Show::{output}

///|
pub extend SexpParseError with Debug::{to_repr}

///|
pub extend SexpParseError with Eq::{not_equal, equal}

///|
pub extend Subscription with Debug::{to_repr}

///|
pub extend Subscription with Eq::{not_equal, equal}

///|
pub extend Value with Debug::{to_repr}

///|
pub extend Value with Compare::{op_lt, op_le, op_ge, op_gt}

///|
pub extend Value with Eq::{not_equal, equal}

///|
pub extend Value with Hash::{hash, hash_combine}

///|
pub extend Value with Show::{output}

///|
pub extend SystemError with Debug::{to_repr}

///|
pub extend JobAction with Eq::{not_equal, equal}

///|
pub extend JobAction with Debug::{to_repr}

///|
pub extend ForkStatus with Show::{output, to_string}

///|
pub extend SystemError with Show::{output}
