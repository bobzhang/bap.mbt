///|
pub extend Counter with Eq::{not_equal, equal}

///|
pub extend Counter with Debug::{to_repr}

///|
pub extend Bound with Eq::{not_equal, equal}

///|
pub extend Bound with Debug::{to_repr}

///|
pub extend BoundParseError with Debug::{to_repr}

///|
pub extend BoundParseError with Show::{to_string, output}
