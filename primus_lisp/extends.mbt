// Explicit method promotion of derived and implemented traits.

///|
pub extend AdviceMethod with Eq::{not_equal, equal}

///|
pub extend AdviceMethod with Debug::{to_repr}

///|
pub extend Ast with Eq::{not_equal, equal}

///|
pub extend Ast with Debug::{to_repr}

///|
pub extend Ast with Show::{to_string, output}

///|
pub extend AttrProblem with Eq::{not_equal, equal}

///|
pub extend AttrProblem with Debug::{to_repr}

///|
pub extend AttributeError with Debug::{to_repr}

///|
pub extend AttributeError with Show::{to_string, output}

///|
pub extend Binding with Eq::{not_equal, equal}

///|
pub extend Binding with Debug::{to_repr}

///|
pub extend Context with Eq::{not_equal, equal}

///|
pub extend Context with Show::{to_string, output}

///|
pub extend DefKind with Eq::{not_equal, equal}

///|
pub extend DefKind with Debug::{to_repr}

///|
pub extend Exp with Eq::{not_equal, equal}

///|
pub extend Exp with Debug::{to_repr}

///|
pub extend Fmt with Eq::{not_equal, equal}

///|
pub extend Fmt with Debug::{to_repr}

///|
pub extend FormatProblem with Eq::{not_equal, equal}

///|
pub extend FormatProblem with Debug::{to_repr}

///|
pub extend LSym with Eq::{not_equal, equal}

///|
pub extend LSym with Debug::{to_repr}

///|
pub extend LVar with Eq::{not_equal, equal}

///|
pub extend LVar with Debug::{to_repr}

///|
pub extend LVar with Show::{to_string, output}

///|
pub extend LWord with Eq::{not_equal, equal}

///|
pub extend LWord with Debug::{to_repr}

///|
pub extend LoadError with Show::{to_string, output}

///|
pub extend Loc with Eq::{not_equal, equal}

///|
pub extend Loc with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Loc with Debug::{to_repr}

///|
pub extend Loc with Show::{to_string, output}

///|
pub extend MacroError with Debug::{to_repr}

///|
pub extend ParseProblem with Show::{to_string, output}

///|
pub extend Position with Eq::{not_equal, equal}

///|
pub extend Position with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Position with Debug::{to_repr}

///|
pub extend Range with Eq::{not_equal, equal}

///|
pub extend Range with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Range with Debug::{to_repr}

///|
pub extend Request with Eq::{not_equal, equal}

///|
pub extend Request with Debug::{to_repr}

///|
pub extend Resolution with Show::{to_string, output}

///|
pub extend SexpError with Eq::{not_equal, equal}

///|
pub extend SexpError with Debug::{to_repr}

///|
pub extend SexpError with Show::{to_string, output}

///|
pub extend Signature with Eq::{not_equal, equal}

///|
pub extend Signature with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Signature with Debug::{to_repr}

///|
pub extend Signature with Show::{to_string, output}

///|
pub extend Token with Eq::{not_equal, equal}

///|
pub extend Token with Debug::{to_repr}

///|
pub extend Tree with Eq::{not_equal, equal}

///|
pub extend Tree with Debug::{to_repr}

///|
pub extend Tree with Show::{to_string, output}

///|
pub extend Typ with Eq::{not_equal, equal}

///|
pub extend Typ with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Typ with Debug::{to_repr}

///|
pub extend Typ with Show::{to_string, output}

///|
pub extend TypeError with Show::{to_string, output}

///|
pub extend TypeProblem with Eq::{not_equal, equal}

///|
pub extend TypeProblem with Debug::{to_repr}

///|
pub extend TypeValue with Eq::{not_equal, equal}

///|
pub extend TypeValue with Debug::{to_repr}

///|
pub extend TypeValue with Show::{to_string, output}

///|
pub extend VarReadError with Eq::{not_equal, equal}

///|
pub extend VarReadError with Debug::{to_repr}

///|
pub extend Visibility with Eq::{not_equal, equal}

///|
pub extend Visibility with Debug::{to_repr}

///|
pub extend WordReadError with Eq::{not_equal, equal}

///|
pub extend WordReadError with Debug::{to_repr}

///|
pub extend Operand with Eq::{not_equal, equal}

///|
pub extend Operand with Debug::{to_repr}

///|
pub extend SemanticsError with Show::{to_string, output}

///|
pub extend LispRuntimeError with Show::{to_string, output}
