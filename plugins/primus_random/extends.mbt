///|
pub extend SpecError with Debug::{to_repr}

///|
pub extend SpecError with Show::{to_string, output}

///|
pub extend Spec with Eq::{equal, not_equal}

///|
pub extend Spec with Debug::{to_repr}

///|
pub extend Predicate with Eq::{equal, not_equal}

///|
pub extend Predicate with Debug::{to_repr}

///|
pub extend MemRegion with Eq::{equal, not_equal}

///|
pub extend MemRegion with Debug::{to_repr}

///|
pub extend Distribution with Eq::{equal, not_equal}

///|
pub extend Distribution with Debug::{to_repr}
