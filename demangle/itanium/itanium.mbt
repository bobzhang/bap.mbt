// A native demangler for the Itanium C++ ABI manglings used by GCC and
// Clang (`_Z...`, and `__Z...` with the extra underscore of Mach-O). It is
// a port of LLVM's `ItaniumDemangle.h` and reproduces the output of
// `llvm-cxxfilt` (which BAP's `c++filt` plugin shells out to upstream).

///|
/// Demangles `name` like LLVM's `itaniumDemangle` (and `__cxa_demangle`).
///
/// Accepts `_Z<encoding>` and `__Z<encoding>` (with an optional
/// `.suffix`, e.g. a clone suffix such as `.cold`), block invocation
/// functions (`___Z<encoding>_block_invoke...`) and bare `<type>`
/// manglings. `params=false` omits the function parameters and return
/// types (`c++filt -p`). Returns `None` if `name` is not a valid mangling.
///
/// Compatibility limit: names that nest deeper than 256 levels while
/// parsing, or whose demangled form nests deeper than 96 levels (e.g. a
/// type with more than 94 pointer declarators), are rejected with `None`
/// rather than risking a stack overflow on the targets with small stacks
/// (wasm-gc, js). Real symbols stay far below these limits.
///
/// ```mbt check
/// test {
///   assert_eq(
///     @itanium.demangle("_ZNSt6vectorIiSaIiEE9push_backERKi"),
///     Some("std::vector<int, std::allocator<int>>::push_back(int const&)"),
///   )
///   assert_eq(@itanium.demangle("_Z3fooi", params=false), Some("foo"))
///   assert_eq(@itanium.demangle("main"), None)
/// }
/// ```
pub fn demangle(name : String, params? : Bool = true) -> String? {
  if name.length() == 0 {
    return None
  }
  let parser = Parser::new(name)
  let ast = parser.parse(params) catch { Fail => return None }
  if !parser.forward_template_refs.is_empty() {
    return None
  }
  let ob = Output::new()
  ast.print(ob)
  if ob.too_deep {
    return None
  }
  Some(ob.contents())
}

///|
/// `true` if `name` looks like an Itanium mangled name: one to four
/// underscores followed by `Z` (LLVM's `isItaniumEncoding`).
pub fn is_itanium_encoding(name : StringView) -> Bool {
  let mut pos = 0
  while pos < name.length() && name.at(pos) == '_' {
    pos += 1
  }
  pos > 0 && pos <= 4 && pos < name.length() && name.at(pos) == 'Z'
}

///|
/// Demangles a symbol name like the `llvm-cxxfilt` tool: names that are
/// not valid Itanium manglings are returned unchanged.
///
/// - `params=false` omits function parameters and return types (`-p`);
/// - `strip_underscore=true` strips one leading underscore first (`-_`,
///   the default of the tool on Mach-O hosts); otherwise a leading `.` is
///   kept and the rest of the name demangled.
///
/// - `types=true` also demangles bare type manglings (`-t`).
///
/// Names prefixed with `__imp_` are demangled as import thunks.
///
/// ```mbt check
/// test {
///   inspect(@itanium.cxxfilt("_ZN3foo3barEv"), content="foo::bar()")
///   inspect(@itanium.cxxfilt("__ZN3foo3barEv", params=false), content="foo::bar")
///   inspect(@itanium.cxxfilt("_Z1fv.cold"), content="f() (.cold)")
///   inspect(@itanium.cxxfilt("_Znot_mangled"), content="_Znot_mangled")
/// }
/// ```
pub fn cxxfilt(
  name : String,
  params? : Bool = true,
  strip_underscore? : Bool = false,
  types? : Bool = false,
) -> String {
  let mut decorated = name[:]
  let mut can_have_leading_dot = true
  if strip_underscore && decorated.length() > 0 && decorated.at(0) == '_' {
    decorated = decorated.view(start_offset=1)
    can_have_leading_dot = false
  }
  let mut mangled = decorated
  let mut prefix = ""
  // A leading dot is not part of the demangled symbol name.
  if can_have_leading_dot && mangled.length() > 0 && mangled.at(0) == '.' {
    mangled = mangled.view(start_offset=1)
    prefix = "."
  }
  if is_itanium_encoding(mangled) &&
    demangle(mangled.to_owned(), params~) is Some(result) {
    return prefix + result
  }
  if types && demangle(decorated.to_owned(), params~) is Some(result) {
    return result
  }
  if decorated.has_prefix("__imp_") &&
    demangle(decorated.view(start_offset=6).to_owned(), params~) is Some(result) {
    return "import thunk for " + result
  }
  name
}
