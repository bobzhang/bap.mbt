///|
/// The implementation of a semantic primitive.
pub struct SemaBody {
  run : (SemCtx, Array[SValue]) -> SValue raise
}

///|
pub struct SemCtx {
  x : Int
}

///|
pub struct SValue {
  x : Int
}
