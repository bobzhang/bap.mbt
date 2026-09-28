// Property-based robustness tests for the Itanium demangler: it is
// documented to return `None` (and `cxxfilt` the name unchanged) for any
// string that is not a valid mangling, so no input may abort it.

///|
/// Regression (found by "qc: deeply nested manglings are rejected, not a
/// stack overflow"): the recursive parser and printer had no depth bound,
/// so a crafted symbol such as `_Z1f` + 200 `P` + `i` exhausted the stack
/// (a trap on wasm-gc, SIGSEGV on native) instead of being rejected.
test "regression: deep nesting does not overflow the stack" {
  assert_eq(@itanium.demangle("_Z1f" + "P".repeat(200) + "i"), None)
  assert_eq(@itanium.demangle("_Z1f" + "P".repeat(5000) + "!"), None)
  let chain = "_Z1fPi" +
    Array::makei(400, i => if i == 0 { "PS_" } else { "PS\{i - 1}_" }).join("")
  assert_eq(@itanium.demangle(chain), None)
  assert_eq(
    @itanium.cxxfilt("_Z1f" + "P".repeat(200) + "i"),
    "_Z1f" + "P".repeat(200) + "i",
  )
  // moderate nesting is unaffected
  assert_eq(
    @itanium.demangle("_Z1f" + "P".repeat(20) + "i"),
    Some("f(int" + "*".repeat(20) + ")"),
  )
}
