// Checks the verified tables generated from `llvm-cxxfilt` output
// (`corpus_symbols_test.mbt` and `corpus_llvm_test.mbt`).

///|
test "agrees with llvm-cxxfilt on real-world symbols" {
  let failures : Array[String] = []
  for entry in symbols {
    let (mangled, full, no_params) = entry
    if @itanium.cxxfilt(mangled) != full {
      failures.push(mangled)
    }
    if @itanium.cxxfilt(mangled, params=false) != no_params {
      failures.push("-p " + mangled)
    }
    // The Mach-O spelling, with the underscore stripped as on Darwin.
    if mangled.has_prefix("_Z") &&
      @itanium.cxxfilt("_" + mangled, strip_underscore=true) != full {
      failures.push("-_ _" + mangled)
    }
  }
  assert_eq(failures, [])
  assert_true(symbols.length() > 2000)
}

///|
test "agrees with llvm-cxxfilt on the libc++abi test inputs" {
  let failures : Array[String] = []
  for entry in llvm_cases {
    let (mangled, full, no_params, types) = entry
    if @itanium.cxxfilt(mangled) != full {
      failures.push(mangled)
    }
    if @itanium.cxxfilt(mangled, params=false) != no_params {
      failures.push("-p " + mangled)
    }
    if @itanium.cxxfilt(mangled, types=true) != types {
      failures.push("-t " + mangled)
    }
  }
  assert_eq(failures, [])
  assert_true(llvm_cases.length() > 1000)
}
