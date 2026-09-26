///|
test "the c++filt demangler drops parameters like c++filt -p" {
  assert_eq(@cxxfilt.run("_ZN3foo3barEi"), "foo::bar")
  assert_eq(@cxxfilt.run("__ZN3foo3barEi"), "foo::bar")
  assert_eq(
    @cxxfilt.run("_ZNKSt6vectorIiSaIiEE4sizeEv"),
    "std::vector<int, std::allocator<int>>::size",
  )
  assert_eq(@cxxfilt.run("_ZTV3Foo"), "vtable for Foo")
  assert_eq(@cxxfilt.run("main"), "main")
  assert_eq(@cxxfilt.run("_main"), "_main")
  assert_eq(@cxxfilt.run("_Z"), "_Z")
  assert_eq(@cxxfilt.run_full("_ZN3foo3barEi"), "foo::bar(int)")
}

///|
test "register declares the bap:c++filt and bap:itanium demanglers" {
  assert_true(@cxxfilt.register() is Ok(_))
  // Idempotent.
  assert_true(@cxxfilt.register() is Ok(_))
  guard @demangle.Demanglers::lookup("c++filt", pkg="bap") is Some(filt) else {
    fail("missing bap:c++filt")
  }
  assert_eq(filt.fullname().show(), "bap:c++filt")
  assert_eq(filt.run("_ZN1A1fEv"), "A::f")
  guard @demangle.Demanglers::lookup("itanium", pkg="bap") is Some(full) else {
    fail("missing bap:itanium")
  }
  assert_eq(full.run("_ZN1A1fEv"), "A::f()")
}

///|
test "the print plugin finds the demanglers by their unqualified names" {
  assert_true(@cxxfilt.register() is Ok(_))
  guard @print.create_demangler(Some("c++filt")) is Ok(demangle) else {
    fail("c++filt is not available to --print-demangled-with")
  }
  assert_eq(demangle("_ZN4llvm5Value7getNameEv"), "llvm::Value::getName")
  guard @print.create_demangler(Some("itanium")) is Ok(demangle) else {
    fail("itanium is not available to --print-demangled-with")
  }
  assert_eq(demangle("_ZN4llvm5Value7getNameEv"), "llvm::Value::getName()")
}

///|
test "the plugin is declared in the bap_main framework" {
  @bap_main.reset()
  @bap_main.set_file_system(@bap_main.FileSystem::in_memory(files=[]))
  @cxxfilt.declare_plugin()
  @cxxfilt.declare_plugin()
  @bap_main.initialize(argv=["bap"])
  assert_eq(@bap_main.loaded_plugins(), ["cxxfilt"])
  assert_true(@demangle.Demanglers::lookup("c++filt", pkg="bap") is Some(_))
  @bap_main.reset()
}
