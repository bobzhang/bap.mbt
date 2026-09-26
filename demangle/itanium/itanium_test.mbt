// Features of the Itanium C++ ABI mangling. Every expected output was
// produced by llvm-cxxfilt (LLVM 22.1.7) with `-n` and with `-n -p`.

///|
/// Checks (mangled, demangled, demangled without parameters) triples.
fn check(cases : Array[(String, String, String)]) -> Unit raise {
  for case in cases {
    let (mangled, full, no_params) = case
    assert_eq(@itanium.cxxfilt(mangled), full)
    assert_eq(@itanium.cxxfilt(mangled, params=false), no_params)
  }
}

///|
test "nested names and std abbreviations" {
  check([
    ("_ZN3foo3bar3bazEv", "foo::bar::baz()", "foo::bar::baz"),
    (
      "_ZNSt3__16vectorIiNS_9allocatorIiEEE9push_backEOi", "std::__1::vector<int, std::__1::allocator<int>>::push_back(int&&)",
      "std::__1::vector<int, std::__1::allocator<int>>::push_back",
    ),
    ("_ZNKSs4sizeEv", "std::string::size() const", "std::string::size"),
    (
      "_ZNSaIcEC1Ev", "std::allocator<char>::allocator()", "std::allocator<char>::allocator",
    ),
    (
      "_ZNSbIwSt11char_traitsIwESaIwEE6appendEPKw", "std::basic_string<wchar_t, std::char_traits<wchar_t>, std::allocator<wchar_t>>::append(wchar_t const*)",
      "std::basic_string<wchar_t, std::char_traits<wchar_t>, std::allocator<wchar_t>>::append",
    ),
    ("_ZNSi4readEPcl", "std::istream::read(char*, long)", "std::istream::read"),
    ("_ZNSolsEi", "std::ostream::operator<<(int)", "std::ostream::operator<<"),
    (
      "_ZNSdD0Ev", "std::basic_iostream<char, std::char_traits<char>>::~basic_iostream()",
      "std::basic_iostream<char, std::char_traits<char>>::~basic_iostream",
    ),
    ("_ZSt4cout", "std::cout", "std::cout"),
    (
      "_ZN12_GLOBAL__N_13fooEv", "(anonymous namespace)::foo()", "(anonymous namespace)::foo",
    ),
  ])
}

///|
test "templates, substitutions and template parameters" {
  check([
    ("_Z3maxIiET_S0_S0_", "int max<int>(int, int)", "max<int>"),
    ("_ZN1AIiE1fIcEEvT_", "void A<int>::f<char>(char)", "A<int>::f<char>"),
    ("_Z1fIJidEEvDpT_", "void f<int, double>(int, double)", "f<int, double>"),
    ("_Z1fI1AEvS0_", "void f<A>(A)", "f<A>"),
    (
      "_ZNSt6vectorIS_IiSaIiEESaIS1_EE5clearEv", "std::vector<std::vector<int, std::allocator<int>>, std::allocator<std::vector<int, std::allocator<int>>>>::clear()",
      "std::vector<std::vector<int, std::allocator<int>>, std::allocator<std::vector<int, std::allocator<int>>>>::clear",
    ),
    ("_Z1gIiEvPFT_S0_E", "void g<int>(int (*)(int))", "g<int>"),
    ("_Z1fITtTyE1XEvv", "void f<X>()", "f<X>"),
    ("_Z1fIiLi3EEvRAT0__T_", "void f<int, 3>(int (&) [3])", "f<int, 3>"),
  ])
}

///|
test "cv-qualifiers, ref-qualifiers and function types" {
  check([
    ("_ZNK1A1fEv", "A::f() const", "A::f"),
    ("_ZNVK1A1fEv", "A::f() const volatile", "A::f"),
    ("_ZNR1A1fEv", "A::f() &", "A::f"),
    ("_ZNO1A1fEv", "A::f() &&", "A::f"),
    ("_Z1fPKc", "f(char const*)", "f"),
    ("_Z1fPVKi", "f(int const volatile*)", "f"),
    ("_Z1fPrPi", "f(int* restrict*)", "f"),
    ("_Z1fPFivE", "f(int (*)())", "f"),
    ("_Z1fPFivRE", "f(int (*)() &)", "f"),
    ("_Z1fRA10_i", "f(int (&) [10])", "f"),
    ("_Z1fPA3_A4_i", "f(int (*) [3][4])", "f"),
    ("_Z1fPDoFvvE", "f(void (*)() noexcept)", "f"),
    ("_Z1fOi", "f(int&&)", "f"),
  ])
}

///|
test "pointers to members" {
  check([
    ("_Z1fM1AFivE", "f(int (A::*)())", "f"),
    ("_Z1fM1AKFivE", "f(int (A::*)() const)", "f"),
    ("_Z1fM1Ai", "f(int A::*)", "f"),
    ("_Z1fPM1AFPFvvEiE", "f(void (* (A::**)(int))())", "f"),
  ])
}

///|
test "operators" {
  check([
    ("_ZN1AplERKS_", "A::operator+(A const&)", "A::operator+"),
    ("_ZN1AaSEOS_", "A::operator=(A&&)", "A::operator="),
    ("_ZN1AixEm", "A::operator[](unsigned long)", "A::operator[]"),
    ("_ZN1AclEv", "A::operator()()", "A::operator()"),
    ("_ZN1AcvbEv", "A::operator bool()", "A::operator bool"),
    ("_ZN1AcviEv", "A::operator int()", "A::operator int"),
    ("_ZNK1AcvT_IiEEv", "A::operator int<int>() const", "A::operator int<int>"),
    ("_Znwm", "operator new(unsigned long)", "operator new"),
    ("_ZdaPv", "operator delete[](void*)", "operator delete[]"),
    ("_ZN1AssERKS_", "A::operator<=>(A const&)", "A::operator<=>"),
    ("_ZN1AptEv", "A::operator->()", "A::operator->"),
    ("_ZN1AdeEv", "A::operator*()", "A::operator*"),
    ("_ZN1AppEi", "A::operator++(int)", "A::operator++"),
    ("_Zli2_xy", "operator\"\" _x(unsigned long long)", "operator\"\" _x"),
    ("_ZN1Av15fooEv", "_ZN1Av15fooEv", "_ZN1Av15fooEv"),
  ])
}

///|
test "constructors and destructors" {
  check([
    ("_ZN1AC1Ev", "A::A()", "A::A"),
    ("_ZN1AC2Ev", "A::A()", "A::A"),
    ("_ZN1AC3Ev", "A::A()", "A::A"),
    ("_ZN1AD0Ev", "A::~A()", "A::~A"),
    ("_ZN1AD1Ev", "A::~A()", "A::~A"),
    ("_ZN1AD2Ev", "A::~A()", "A::~A"),
    ("_ZN1BCI21AEi", "B::B(int)", "B::B"),
    (
      "_ZNSt9exceptionD2Ev", "std::exception::~exception()", "std::exception::~exception",
    ),
  ])
}

///|
test "special names" {
  check([
    ("_ZTV1A", "vtable for A", "vtable for A"),
    ("_ZTI1A", "typeinfo for A", "typeinfo for A"),
    ("_ZTS1A", "typeinfo name for A", "typeinfo name for A"),
    ("_ZTT1A", "VTT for A", "VTT for A"),
    (
      "_ZTCN1A1BE0_1C", "construction vtable for C-in-A::B", "construction vtable for C-in-A::B",
    ),
    (
      "_ZThn8_N1B1fEv", "non-virtual thunk to B::f()", "non-virtual thunk to B::f()",
    ),
    ("_ZTv0_n24_N1B1fEv", "virtual thunk to B::f()", "virtual thunk to B::f()"),
    (
      "_ZTch0_h8_N1B1fEv", "covariant return thunk to B::f()", "covariant return thunk to B::f()",
    ),
    ("_ZGVZ1fvE1x", "guard variable for f()::x", "guard variable for f()::x"),
    ("_ZGR1x_", "reference temporary for x", "reference temporary for x"),
    ("_ZGR1x0_", "reference temporary for x", "reference temporary for x"),
    (
      "_ZTW1x", "thread-local wrapper routine for x", "thread-local wrapper routine for x",
    ),
    (
      "_ZTH1x", "thread-local initialization routine for x", "thread-local initialization routine for x",
    ),
    (
      "_ZTAXtl1AEE", "template parameter object for A{}", "template parameter object for A{}",
    ),
  ])
}

///|
test "local names, discriminators and string literals" {
  check([
    ("_ZZ1fvE1x", "f()::x", "f()::x"),
    ("_ZZ1fvE1x_0", "f()::x", "f()::x"),
    ("_ZZ1fvE1x__12_", "f()::x", "f()::x"),
    ("_ZZ1fvEs", "f()::string literal", "f()::string literal"),
    ("_ZZ1fvEs_1", "f()::string literal", "f()::string literal"),
    ("_ZZN1A1fEvE1B", "A::f()::B", "A::f()::B"),
    ("_ZZ1fvENK1BclEv", "f()::B::operator()() const", "f()::B::operator()"),
    ("_ZZ1fvEN1B1gEv", "f()::B::g()", "f()::B::g"),
    ("_ZZZ1fvE1BE1x", "f()::B::x", "f()::B::x"),
  ])
}

///|
test "lambdas and unnamed types" {
  check([
    (
      "_ZZ1fvENKUlvE_clEv", "f()::'lambda'()::operator()() const", "f()::'lambda'()::operator()",
    ),
    (
      "_ZZ1fvENKUliE0_clEi", "f()::'lambda0'(int)::operator()(int) const", "f()::'lambda0'(int)::operator()",
    ),
    ("_ZN1AUt_E", "A::'unnamed'", "A::'unnamed'"),
    ("_ZN1AUt0_E", "A::'unnamed0'", "A::'unnamed0'"),
    (
      "_ZZ1fvENKUlT_E_clIiEEDaS_", "auto f()::'lambda'(auto)::operator()<int>(auto) const",
      "f()::'lambda'(auto)::operator()<int>",
    ),
    (
      "_ZZ1fvENKUlTyT_E_clIiEEDaS0_", "auto f()::'lambda'<typename $T>($T)::operator()<int>('lambda'<typename $T>($T)) const",
      "f()::'lambda'<typename $T>($T)::operator()<int>",
    ),
    ("_ZN3$_01fEv", "$_0::f()", "$_0::f"),
    (
      "_ZNSt3__110__function6__funcIZN1A1fEvE3$_0NS_9allocatorIS3_EEFvvEEclEv", "std::__1::__function::__func<A::f()::$_0, std::__1::allocator<A::f()::$_0>, void ()>::operator()()",
      "std::__1::__function::__func<A::f()::$_0, std::__1::allocator<A::f()::$_0>, void ()>::operator()",
    ),
    (
      "___Z1fv_block_invoke", "invocation function for block in f()", "___Z1fv_block_invoke",
    ),
    (
      "___Z1fv_block_invoke_2", "invocation function for block in f()", "___Z1fv_block_invoke_2",
    ),
  ])
}

///|
test "abi tags" {
  check([
    (
      "_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv", "std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char>>::size() const",
      "std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char>>::size",
    ),
    ("_Z1fB5cxx11v", "f[abi:cxx11]()", "f[abi:cxx11]"),
    (
      "_ZN1AB3abcB3def1fEv", "A[abi:abc][abi:def]::f()", "A[abi:abc][abi:def]::f",
    ),
    (
      "_ZSt4sortB8ne180100IPiEvT_S1_", "void std::sort[abi:ne180100]<int*>(int*, int*)",
      "std::sort[abi:ne180100]<int*>",
    ),
  ])
}

///|
test "vendor qualifiers and extended types" {
  check([
    ("_Z1fU3fooi", "f(int foo)", "f"),
    ("_Z1fPU3AS1i", "f(int AS1*)", "f"),
    ("_Z1fu6__bf16", "f(__bf16)", "f"),
    ("_Z1fDv4_f", "f(float vector[4])", "f"),
    ("_Z1fDF16_", "f(_Float16)", "f"),
    ("_Z1fDn", "f(std::nullptr_t)", "f"),
    ("_Z1fDiDsDu", "f(char32_t, char16_t, char8_t)", "f"),
    ("_Z1fDB8_", "f(_BitInt(8))", "f"),
    ("_Z1fu11__remove_cvIiE", "f(__remove_cv(int))", "f"),
    ("_Z1fPU11objcproto1P11objc_object", "f(id<P>)", "f"),
  ])
}

///|
test "clone and other suffixes" {
  check([
    ("_Z1fv.cold", "f() (.cold)", "f"),
    ("_Z1fi.isra.0", "f(int) (.isra.0)", "f"),
    ("_Z1fi.constprop.0.cold", "f(int) (.constprop.0.cold)", "f"),
    ("_Z1fv.part.0", "f() (.part.0)", "f"),
    ("_Z1fv.llvm.1234567890", "f() (.llvm.1234567890)", "f"),
    ("_Z1fv.__uniq.123", "f() (.__uniq.123)", "f"),
  ])
}

///|
test "expressions in template arguments" {
  check([
    ("_Z1fILi1EEvv", "void f<1>()", "f<1>"),
    ("_Z1fILb1EEvv", "void f<true>()", "f<true>"),
    ("_Z1fIXplT_Li1EEEvv", "_Z1fIXplT_Li1EEEvv", "_Z1fIXplT_Li1EEEvv"),
    ("_Z1fIiEDTcl1gfp_EET_", "decltype(g(fp)) f<int>(int)", "f<int>"),
    ("_Z1fIiEDTplfp_fp_ET_", "decltype(fp + fp) f<int>(int)", "f<int>"),
    ("_Z1fIJiEEDTsZT_Ev", "decltype(sizeof...(int)) f<int>()", "f<int>"),
    ("_Z1fIiEvPAszT__i", "void f<int>(int (*) [sizeof (int)])", "f<int>"),
    ("_Z1fIiEDTcvT__EEv", "decltype((int)()) f<int>()", "f<int>"),
    ("_Z1fIiEDTnw_T_EEv", "decltype(new int) f<int>()", "f<int>"),
    ("_Z1fILi3EEvRAgtT_Li2E_i", "void f<3>(int (&) [(3 > 2)])", "f<3>"),
    (
      "_Z1fIiEDTfLplfp_Li0EEDpT_", "decltype((fp + ... + (0...))) f<int>(int...)",
      "f<int>",
    ),
    ("_Z1fI1AEDtdtfp_1xET_", "decltype(fp.x) f<A>(A)", "f<A>"),
    ("_Z1fIiEDTsrT_1xEv", "decltype(int::x) f<int>()", "f<int>"),
    ("_Z1fIiEvDTtwLi1EE", "void f<int>(decltype(throw 1))", "f<int>"),
    ("_Z1fILc65EEvv", "void f<(char)65>()", "f<(char)65>"),
    ("_Z1fILin5EEvv", "void f<-5>()", "f<-5>"),
    ("_Z1fIL_Z1gvEEvv", "void f<g()>()", "f<g()>"),
    ("_Z1fILDnEEvv", "void f<nullptr>()", "f<nullptr>"),
    ("_Z1fILf40a00000EEvv", "void f<0x1.4p+2f>()", "f<0x1.4p+2f>"),
    ("_Z1fILd4014000000000000EEvv", "void f<0x1.4p+2>()", "f<0x1.4p+2>"),
    ("_Z1fIiEvDTadsrT_1fE", "void f<int>(decltype(&int::f))", "f<int>"),
    ("_Z1fIiEvDTqufp_Li1ELi2EE", "void f<int>(decltype(fp ? 1 : 2))", "f<int>"),
  ])
}

///|
test "decltype and pack expansions" {
  check([
    ("_Z1fIiEDtfp_ET_", "decltype(fp) f<int>(int)", "f<int>"),
    (
      "_Z1fIJicEEvDpRKT_", "void f<int, char>(int const&, char const&)", "f<int, char>",
    ),
    ("_Z1fIJiEEvDpPFvT_E", "void f<int>(void (*)(int))", "f<int>"),
    (
      "_Z1gIJidEEDTcl1fspfp_EEDpT_", "decltype(f(fp...)) g<int, double>(int, double)",
      "g<int, double>",
    ),
    ("_Z1fIJEEvDpT_", "void f<>()", "f<>"),
  ])
}

///|
test "invalid names are returned unchanged" {
  check([
    ("_Z", "_Z", "_Z"),
    ("_Z1", "_Z1", "_Z1"),
    ("_Z3fo", "_Z3fo", "_Z3fo"),
    ("_ZN3fooE", "foo", "foo"),
    ("_Z1fv.", "f() (.)", "f"),
    ("_ZTV", "_ZTV", "_ZTV"),
    ("main", "main", "main"),
    ("_main", "_main", "_main"),
    ("__Z", "__Z", "__Z"),
    ("Z3fooi", "Z3fooi", "Z3fooi"),
    ("_Z1fIiE", "f<int>", "f<int>"),
    ("_ZZ1fvE", "_ZZ1fvE", "_ZZ1fvE"),
    ("_ZSt", "_ZSt", "_ZSt"),
    ("_Z1fS_", "_Z1fS_", "f"),
  ])
}

///|
test "Mach-O names and import thunks" {
  check([
    ("__Z3fooi", "foo(int)", "foo"),
    ("___Z3fooi", "___Z3fooi", "___Z3fooi"),
    (
      "____Z3foov_block_invoke", "invocation function for block in foo()", "____Z3foov_block_invoke",
    ),
    ("__imp__Z3fooi", "import thunk for foo(int)", "import thunk for foo"),
    ("._Z3fooi", ".foo(int)", ".foo"),
  ])
}
