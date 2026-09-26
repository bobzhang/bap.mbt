///|
/// Errors reported by Ogre documents, queries and the Ogre monad.
///
/// This is the port of the `Or_error.t` failures of BAP's `Ogre` module. The
/// payload is the human-readable message, spelled like upstream wherever the
/// upstream message is deterministic.
pub(all) suberror OgreError {
  OgreError(String)
} derive(Debug, Eq)

///|
/// Returns the human-readable message carried by the error.
pub fn OgreError::message(self : OgreError) -> String {
  match self {
    OgreError(message) => message
  }
}

///|
pub impl Show for OgreError with fn output(self, logger) {
  logger.write_string(self.message())
}

///|
fn[A] ogre_fail(message : String) -> A raise OgreError {
  raise OgreError(message)
}

///|
pub extend OgreError with Eq::{equal, not_equal}

///|
pub extend OgreError with Show::{output, to_string}

///|
pub extend OgreError with Debug::{to_repr}
