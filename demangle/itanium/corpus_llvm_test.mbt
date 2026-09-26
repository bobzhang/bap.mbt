// Generated from the output of llvm-cxxfilt (LLVM 22.1.7): each
// entry is (mangled name, `llvm-cxxfilt -n`, `llvm-cxxfilt -n -p`,
// `llvm-cxxfilt -n -t`).
// Inputs of the libc++abi demangler test suite
// (test/DemangleTestCases.inc and test/test_demangle.pass.cpp).

///|
let llvm_cases : Array[(String, String, String, String)] = [
  (
    "_ZN4llvm15DomTreeNodeBaseINS_10BasicBlockEEC2EPS1_PS2_", "llvm::DomTreeNodeBase<llvm::BasicBlock>::DomTreeNodeBase(llvm::BasicBlock*, llvm::DomTreeNodeBase<llvm::BasicBlock>*)",
    "llvm::DomTreeNodeBase<llvm::BasicBlock>::DomTreeNodeBase", "llvm::DomTreeNodeBase<llvm::BasicBlock>::DomTreeNodeBase(llvm::BasicBlock*, llvm::DomTreeNodeBase<llvm::BasicBlock>*)",
  ),
  (
    "_ZN5clang10DiagnosticC1ERKN4llvm18IntrusiveRefCntPtrINS_13DiagnosticIDsEEEPNS_16DiagnosticClientEb",
    "clang::Diagnostic::Diagnostic(llvm::IntrusiveRefCntPtr<clang::DiagnosticIDs> const&, clang::DiagnosticClient*, bool)",
    "clang::Diagnostic::Diagnostic", "clang::Diagnostic::Diagnostic(llvm::IntrusiveRefCntPtr<clang::DiagnosticIDs> const&, clang::DiagnosticClient*, bool)",
  ),
  (
    "_ZN4llvm19ARMSelectionDAGInfoC2ERKNS_13TargetMachineE", "llvm::ARMSelectionDAGInfo::ARMSelectionDAGInfo(llvm::TargetMachine const&)",
    "llvm::ARMSelectionDAGInfo::ARMSelectionDAGInfo", "llvm::ARMSelectionDAGInfo::ARMSelectionDAGInfo(llvm::TargetMachine const&)",
  ),
  (
    "_ZN5clang6driver9JobActionC1ENS0_6Action11ActionClassERKN4llvm11SmallVectorIPS2_Lj3EEENS0_5types2IDE",
    "clang::driver::JobAction::JobAction(clang::driver::Action::ActionClass, llvm::SmallVector<clang::driver::Action*, 3u> const&, clang::driver::types::ID)",
    "clang::driver::JobAction::JobAction", "clang::driver::JobAction::JobAction(clang::driver::Action::ActionClass, llvm::SmallVector<clang::driver::Action*, 3u> const&, clang::driver::types::ID)",
  ),
  (
    "_ZN5clang18EmitLLVMOnlyActionC2Ev", "clang::EmitLLVMOnlyAction::EmitLLVMOnlyAction()",
    "clang::EmitLLVMOnlyAction::EmitLLVMOnlyAction", "clang::EmitLLVMOnlyAction::EmitLLVMOnlyAction()",
  ),
  (
    "_ZN4llvm14BinaryOperatorC2ENS_11Instruction9BinaryOpsEPNS_5ValueES4_PKNS_4TypeERKNS_5TwineEPNS_10BasicBlockE",
    "llvm::BinaryOperator::BinaryOperator(llvm::Instruction::BinaryOps, llvm::Value*, llvm::Value*, llvm::Type const*, llvm::Twine const&, llvm::BasicBlock*)",
    "llvm::BinaryOperator::BinaryOperator", "llvm::BinaryOperator::BinaryOperator(llvm::Instruction::BinaryOps, llvm::Value*, llvm::Value*, llvm::Type const*, llvm::Twine const&, llvm::BasicBlock*)",
  ),
  (
    "_ZN5clang8CallExprC1ERNS_10ASTContextEPNS_4ExprEPS4_jNS_8QualTypeENS_13ExprValueKindENS_14SourceLocationE",
    "clang::CallExpr::CallExpr(clang::ASTContext&, clang::Expr*, clang::Expr**, unsigned int, clang::QualType, clang::ExprValueKind, clang::SourceLocation)",
    "clang::CallExpr::CallExpr", "clang::CallExpr::CallExpr(clang::ASTContext&, clang::Expr*, clang::Expr**, unsigned int, clang::QualType, clang::ExprValueKind, clang::SourceLocation)",
  ),
  (
    "_ZN4llvm21SymbolTableListTraitsINS_11GlobalAliasENS_6ModuleEEC1Ev", "llvm::SymbolTableListTraits<llvm::GlobalAlias, llvm::Module>::SymbolTableListTraits()",
    "llvm::SymbolTableListTraits<llvm::GlobalAlias, llvm::Module>::SymbolTableListTraits",
    "llvm::SymbolTableListTraits<llvm::GlobalAlias, llvm::Module>::SymbolTableListTraits()",
  ),
  ("_ZN1DCI21CIiEET_", "D::D(int)", "D::D", "D::D(int)"),
  ("_ZN1BCI21AEi", "B::B(int)", "B::B", "B::B(int)"),
  (
    "_ZN4llvm24AssemblyAnnotationWriterD0Ev", "llvm::AssemblyAnnotationWriter::~AssemblyAnnotationWriter()",
    "llvm::AssemblyAnnotationWriter::~AssemblyAnnotationWriter", "llvm::AssemblyAnnotationWriter::~AssemblyAnnotationWriter()",
  ),
  (
    "_ZN4llvm3DIED0Ev", "llvm::DIE::~DIE()", "llvm::DIE::~DIE", "llvm::DIE::~DIE()",
  ),
  (
    "_ZN4llvm10ReturnInstD2Ev", "llvm::ReturnInst::~ReturnInst()", "llvm::ReturnInst::~ReturnInst",
    "llvm::ReturnInst::~ReturnInst()",
  ),
  (
    "_ZN5clang3idx17TULocationHandlerD1Ev", "clang::idx::TULocationHandler::~TULocationHandler()",
    "clang::idx::TULocationHandler::~TULocationHandler", "clang::idx::TULocationHandler::~TULocationHandler()",
  ),
  (
    "_ZN4llvm14TerminatorInstD1Ev", "llvm::TerminatorInst::~TerminatorInst()", "llvm::TerminatorInst::~TerminatorInst",
    "llvm::TerminatorInst::~TerminatorInst()",
  ),
  (
    "_ZN12_GLOBAL__N_115UnknownHostInfoD0Ev", "(anonymous namespace)::UnknownHostInfo::~UnknownHostInfo()",
    "(anonymous namespace)::UnknownHostInfo::~UnknownHostInfo", "(anonymous namespace)::UnknownHostInfo::~UnknownHostInfo()",
  ),
  (
    "_ZN5clang18PragmaAlignHandlerD1Ev", "clang::PragmaAlignHandler::~PragmaAlignHandler()",
    "clang::PragmaAlignHandler::~PragmaAlignHandler", "clang::PragmaAlignHandler::~PragmaAlignHandler()",
  ),
  (
    "_ZN4llvm19ProcessImplicitDefsD1Ev", "llvm::ProcessImplicitDefs::~ProcessImplicitDefs()",
    "llvm::ProcessImplicitDefs::~ProcessImplicitDefs", "llvm::ProcessImplicitDefs::~ProcessImplicitDefs()",
  ),
  (
    "_ZTVN5clang13CXXRecordDeclE", "vtable for clang::CXXRecordDecl", "vtable for clang::CXXRecordDecl",
    "vtable for clang::CXXRecordDecl",
  ),
  (
    "_ZTVN5clang17ExternalASTSourceE", "vtable for clang::ExternalASTSource", "vtable for clang::ExternalASTSource",
    "vtable for clang::ExternalASTSource",
  ),
  (
    "_ZTVN5clang4ento9SubEngineE", "vtable for clang::ento::SubEngine", "vtable for clang::ento::SubEngine",
    "vtable for clang::ento::SubEngine",
  ),
  (
    "_ZTVN4llvm7InlinerE", "vtable for llvm::Inliner", "vtable for llvm::Inliner",
    "vtable for llvm::Inliner",
  ),
  (
    "_ZTVN5clang24ASTSerializationListenerE", "vtable for clang::ASTSerializationListener",
    "vtable for clang::ASTSerializationListener", "vtable for clang::ASTSerializationListener",
  ),
  (
    "_ZTVN5clang6driver23JoinedAndSeparateOptionE", "vtable for clang::driver::JoinedAndSeparateOption",
    "vtable for clang::driver::JoinedAndSeparateOption", "vtable for clang::driver::JoinedAndSeparateOption",
  ),
  (
    "_ZTVN12_GLOBAL__N_116MBlazeTargetInfoE", "vtable for (anonymous namespace)::MBlazeTargetInfo",
    "vtable for (anonymous namespace)::MBlazeTargetInfo", "vtable for (anonymous namespace)::MBlazeTargetInfo",
  ),
  (
    "_ZTVN5clang6driver5tools3gcc8AssembleE", "vtable for clang::driver::tools::gcc::Assemble",
    "vtable for clang::driver::tools::gcc::Assemble", "vtable for clang::driver::tools::gcc::Assemble",
  ),
  (
    "_ZTIN4llvm12FunctionTypeE", "typeinfo for llvm::FunctionType", "typeinfo for llvm::FunctionType",
    "typeinfo for llvm::FunctionType",
  ),
  (
    "_ZTIN4llvm14SequentialTypeE", "typeinfo for llvm::SequentialType", "typeinfo for llvm::SequentialType",
    "typeinfo for llvm::SequentialType",
  ),
  (
    "_ZTIN4llvm11_do_messageE", "typeinfo for llvm::_do_message", "typeinfo for llvm::_do_message",
    "typeinfo for llvm::_do_message",
  ),
  (
    "_ZTIN4llvm25ShuffleVectorConstantExprE", "typeinfo for llvm::ShuffleVectorConstantExpr",
    "typeinfo for llvm::ShuffleVectorConstantExpr", "typeinfo for llvm::ShuffleVectorConstantExpr",
  ),
  (
    "_ZTIN4llvm10BranchInstE", "typeinfo for llvm::BranchInst", "typeinfo for llvm::BranchInst",
    "typeinfo for llvm::BranchInst",
  ),
  (
    "_ZTIPKc", "typeinfo for char const*", "typeinfo for char const*", "typeinfo for char const*",
  ),
  (
    "_ZTIN4llvm17ConstantUniqueMapIcNS_11PointerTypeENS_19ConstantPointerNullELb0EEE",
    "typeinfo for llvm::ConstantUniqueMap<char, llvm::PointerType, llvm::ConstantPointerNull, false>",
    "typeinfo for llvm::ConstantUniqueMap<char, llvm::PointerType, llvm::ConstantPointerNull, false>",
    "typeinfo for llvm::ConstantUniqueMap<char, llvm::PointerType, llvm::ConstantPointerNull, false>",
  ),
  (
    "_ZTIN4llvm10UndefValueE", "typeinfo for llvm::UndefValue", "typeinfo for llvm::UndefValue",
    "typeinfo for llvm::UndefValue",
  ),
  (
    "_ZTSN4llvm10AllocaInstE", "typeinfo name for llvm::AllocaInst", "typeinfo name for llvm::AllocaInst",
    "typeinfo name for llvm::AllocaInst",
  ),
  (
    "_ZTSN12_GLOBAL__N_120MemoryBufferMMapFileE", "typeinfo name for (anonymous namespace)::MemoryBufferMMapFile",
    "typeinfo name for (anonymous namespace)::MemoryBufferMMapFile", "typeinfo name for (anonymous namespace)::MemoryBufferMMapFile",
  ),
  (
    "_ZTSN4llvm11GlobalAliasE", "typeinfo name for llvm::GlobalAlias", "typeinfo name for llvm::GlobalAlias",
    "typeinfo name for llvm::GlobalAlias",
  ),
  (
    "_ZTSN4llvm11BitCastInstE", "typeinfo name for llvm::BitCastInst", "typeinfo name for llvm::BitCastInst",
    "typeinfo name for llvm::BitCastInst",
  ),
  (
    "_ZTSN4llvm8CallInstE", "typeinfo name for llvm::CallInst", "typeinfo name for llvm::CallInst",
    "typeinfo name for llvm::CallInst",
  ),
  (
    "_ZTSN4llvm10SIToFPInstE", "typeinfo name for llvm::SIToFPInst", "typeinfo name for llvm::SIToFPInst",
    "typeinfo name for llvm::SIToFPInst",
  ),
  (
    "_ZTSN4llvm19MallocSlabAllocatorE", "typeinfo name for llvm::MallocSlabAllocator",
    "typeinfo name for llvm::MallocSlabAllocator", "typeinfo name for llvm::MallocSlabAllocator",
  ),
  (
    "_ZTSN4llvm24AssemblyAnnotationWriterE", "typeinfo name for llvm::AssemblyAnnotationWriter",
    "typeinfo name for llvm::AssemblyAnnotationWriter", "typeinfo name for llvm::AssemblyAnnotationWriter",
  ),
  (
    "_ZTC14SSDatabaseImpl0_N8Security10CssmClient6DbImplE", "construction vtable for Security::CssmClient::DbImpl-in-SSDatabaseImpl",
    "construction vtable for Security::CssmClient::DbImpl-in-SSDatabaseImpl", "construction vtable for Security::CssmClient::DbImpl-in-SSDatabaseImpl",
  ),
  (
    "_ZThn32_N4llvm13MPPassManager25addLowerLevelRequiredPassEPNS_4PassES2_", "non-virtual thunk to llvm::MPPassManager::addLowerLevelRequiredPass(llvm::Pass*, llvm::Pass*)",
    "non-virtual thunk to llvm::MPPassManager::addLowerLevelRequiredPass(llvm::Pass*, llvm::Pass*)",
    "non-virtual thunk to llvm::MPPassManager::addLowerLevelRequiredPass(llvm::Pass*, llvm::Pass*)",
  ),
  (
    "_ZThn32_NK4llvm13MPPassManager18getPassManagerTypeEv", "non-virtual thunk to llvm::MPPassManager::getPassManagerType() const",
    "non-virtual thunk to llvm::MPPassManager::getPassManagerType() const", "non-virtual thunk to llvm::MPPassManager::getPassManagerType() const",
  ),
  (
    "_ZThn16_N5clang9ASTReader20StartedDeserializingEv", "non-virtual thunk to clang::ASTReader::StartedDeserializing()",
    "non-virtual thunk to clang::ASTReader::StartedDeserializing()", "non-virtual thunk to clang::ASTReader::StartedDeserializing()",
  ),
  (
    "_ZThn432_N4llvm15PassManagerImplD0Ev", "non-virtual thunk to llvm::PassManagerImpl::~PassManagerImpl()",
    "non-virtual thunk to llvm::PassManagerImpl::~PassManagerImpl()", "non-virtual thunk to llvm::PassManagerImpl::~PassManagerImpl()",
  ),
  (
    "_ZThn8_N5clang9ASTWriterD1Ev", "non-virtual thunk to clang::ASTWriter::~ASTWriter()",
    "non-virtual thunk to clang::ASTWriter::~ASTWriter()", "non-virtual thunk to clang::ASTWriter::~ASTWriter()",
  ),
  (
    "_ZThn32_N4llvm15PassManagerImplD0Ev", "non-virtual thunk to llvm::PassManagerImpl::~PassManagerImpl()",
    "non-virtual thunk to llvm::PassManagerImpl::~PassManagerImpl()", "non-virtual thunk to llvm::PassManagerImpl::~PassManagerImpl()",
  ),
  (
    "_ZThn16_N5clang9ASTReader10ForgetSemaEv", "non-virtual thunk to clang::ASTReader::ForgetSema()",
    "non-virtual thunk to clang::ASTReader::ForgetSema()", "non-virtual thunk to clang::ASTReader::ForgetSema()",
  ),
  (
    "_ZThn16_N5clang9ASTReader21FinishedDeserializingEv", "non-virtual thunk to clang::ASTReader::FinishedDeserializing()",
    "non-virtual thunk to clang::ASTReader::FinishedDeserializing()", "non-virtual thunk to clang::ASTReader::FinishedDeserializing()",
  ),
  (
    "_ZTv0_n12_NSt9strstreamD0Ev", "virtual thunk to std::strstream::~strstream()",
    "virtual thunk to std::strstream::~strstream()", "virtual thunk to std::strstream::~strstream()",
  ),
  (
    "_ZGVZN5clang22getClangRepositoryPathEvE13SVNRepository", "guard variable for clang::getClangRepositoryPath()::SVNRepository",
    "guard variable for clang::getClangRepositoryPath()::SVNRepository", "guard variable for clang::getClangRepositoryPath()::SVNRepository",
  ),
  (
    "_ZGVZN4llvm21PrettyStackTraceEntryC1EvE17HandlerRegistered", "guard variable for llvm::PrettyStackTraceEntry::PrettyStackTraceEntry()::HandlerRegistered",
    "guard variable for llvm::PrettyStackTraceEntry::PrettyStackTraceEntry()::HandlerRegistered",
    "guard variable for llvm::PrettyStackTraceEntry::PrettyStackTraceEntry()::HandlerRegistered",
  ),
  (
    "_ZGVZN4llvm4errsEvE1S", "guard variable for llvm::errs()::S", "guard variable for llvm::errs()::S",
    "guard variable for llvm::errs()::S",
  ),
  (
    "_ZGVZN4llvm5nullsEvE1S", "guard variable for llvm::nulls()::S", "guard variable for llvm::nulls()::S",
    "guard variable for llvm::nulls()::S",
  ),
  (
    "_ZGVZN4llvm16generic_categoryEvE1s", "guard variable for llvm::generic_category()::s",
    "guard variable for llvm::generic_category()::s", "guard variable for llvm::generic_category()::s",
  ),
  (
    "_ZGVZN4llvm5ferrsEvE1S", "guard variable for llvm::ferrs()::S", "guard variable for llvm::ferrs()::S",
    "guard variable for llvm::ferrs()::S",
  ),
  (
    "_ZGVZ18IsCachedDiagnosticPN5clang4ento9BugReportEPNS0_14PathDiagnosticEE2DC",
    "guard variable for IsCachedDiagnostic(clang::ento::BugReport*, clang::ento::PathDiagnostic*)::DC",
    "guard variable for IsCachedDiagnostic(clang::ento::BugReport*, clang::ento::PathDiagnostic*)::DC",
    "guard variable for IsCachedDiagnostic(clang::ento::BugReport*, clang::ento::PathDiagnostic*)::DC",
  ),
  (
    "_ZGVZN4llvm5foutsEvE1S", "guard variable for llvm::fouts()::S", "guard variable for llvm::fouts()::S",
    "guard variable for llvm::fouts()::S",
  ),
  (
    "_ZGRDC1x1yE_", "reference temporary for [x, y]", "reference temporary for [x, y]",
    "reference temporary for [x, y]",
  ),
  (
    "_ZGR1bIvE2_", "reference temporary for b<void>", "reference temporary for b<void>",
    "reference temporary for b<void>",
  ),
  (
    "_ZGRZN1N1gEvE1a", "reference temporary for N::g()::a", "reference temporary for N::g()::a",
    "reference temporary for N::g()::a",
  ),
  (
    "_ZTW1x", "thread-local wrapper routine for x", "thread-local wrapper routine for x",
    "thread-local wrapper routine for x",
  ),
  (
    "_ZTHN3fooE", "thread-local initialization routine for foo", "thread-local initialization routine for foo",
    "thread-local initialization routine for foo",
  ),
  (
    "_ZZ14NSNameOfSymbolE8__func__", "NSNameOfSymbol::__func__", "NSNameOfSymbol::__func__",
    "NSNameOfSymbol::__func__",
  ),
  (
    "_ZZN4llvm17X86ATTInstPrinter18getInstructionNameEjE13InstAsmOffset", "llvm::X86ATTInstPrinter::getInstructionName(unsigned int)::InstAsmOffset",
    "llvm::X86ATTInstPrinter::getInstructionName(unsigned int)::InstAsmOffset", "llvm::X86ATTInstPrinter::getInstructionName(unsigned int)::InstAsmOffset",
  ),
  (
    "_ZZN4llvm14f64AssignAAPCSERjRNS_3MVTES2_RNS_11CCValAssign7LocInfoERNS_7CCStateEbE9HiRegList",
    "llvm::f64AssignAAPCS(unsigned int&, llvm::MVT&, llvm::MVT&, llvm::CCValAssign::LocInfo&, llvm::CCState&, bool)::HiRegList",
    "llvm::f64AssignAAPCS(unsigned int&, llvm::MVT&, llvm::MVT&, llvm::CCValAssign::LocInfo&, llvm::CCState&, bool)::HiRegList",
    "llvm::f64AssignAAPCS(unsigned int&, llvm::MVT&, llvm::MVT&, llvm::CCValAssign::LocInfo&, llvm::CCState&, bool)::HiRegList",
  ),
  (
    "_ZZNK4llvm5APInt8toStringERNS_15SmallVectorImplIcEEjbE6Digits", "llvm::APInt::toString(llvm::SmallVectorImpl<char>&, unsigned int, bool) const::Digits",
    "llvm::APInt::toString(llvm::SmallVectorImpl<char>&, unsigned int, bool) const::Digits",
    "llvm::APInt::toString(llvm::SmallVectorImpl<char>&, unsigned int, bool) const::Digits",
  ),
  (
    "_ZZ21NSLookupAndBindSymbolE8__func__", "NSLookupAndBindSymbol::__func__", "NSLookupAndBindSymbol::__func__",
    "NSLookupAndBindSymbol::__func__",
  ),
  (
    "_ZZN4llvm31initializePeepholeOptimizerPassERNS_12PassRegistryEE11initialized",
    "llvm::initializePeepholeOptimizerPass(llvm::PassRegistry&)::initialized", "llvm::initializePeepholeOptimizerPass(llvm::PassRegistry&)::initialized",
    "llvm::initializePeepholeOptimizerPass(llvm::PassRegistry&)::initialized",
  ),
  (
    "_ZZN4llvm15system_categoryEvE1s", "llvm::system_category()::s", "llvm::system_category()::s",
    "llvm::system_category()::s",
  ),
  (
    "_ZZ24NSDestroyObjectFileImageE8__func__", "NSDestroyObjectFileImage::__func__",
    "NSDestroyObjectFileImage::__func__", "NSDestroyObjectFileImage::__func__",
  ),
  ("_ZL7NumCPEs", "NumCPEs", "NumCPEs", "NumCPEs"),
  ("_ZL11NumPhysCSEs", "NumPhysCSEs", "NumPhysCSEs", "NumPhysCSEs"),
  ("_ZL7NumCSEs", "NumCSEs", "NumCSEs", "NumCSEs"),
  (
    "_ZZN5test71fIiEEvvENKUlTyT0_E_clIiiEEDaS1_", "auto void test7::f<int>()::'lambda'<typename $T>(auto)::operator()<int, int>(auto) const",
    "void test7::f<int>()::'lambda'<typename $T>(auto)::operator()<int, int>", "auto void test7::f<int>()::'lambda'<typename $T>(auto)::operator()<int, int>(auto) const",
  ),
  (
    "_ZN1S1fILb1EEEv1XILUlvE0_EE", "void S::f<true>(X<[](){...}>)", "S::f<true>",
    "void S::f<true>(X<[](){...}>)",
  ),
  (
    "Z1JIJ1_T_EE3o00EUlT_E0", "Z1JIJ1_T_EE3o00EUlT_E0", "Z1JIJ1_T_EE3o00EUlT_E0",
    "Z1JIJ1_T_EE3o00EUlT_E0",
  ),
  (
    "_ZZ18test_assign_throwsI20small_throws_on_copyLb0EEvvENKUlRNSt3__13anyEOT_E_clIRS0_EEDaS3_S5_",
    "auto void test_assign_throws<small_throws_on_copy, false>()::'lambda'(std::__1::any&, auto&&)::operator()<small_throws_on_copy&>(std::__1::any&, auto&&) const",
    "void test_assign_throws<small_throws_on_copy, false>()::'lambda'(std::__1::any&, auto&&)::operator()<small_throws_on_copy&>",
    "auto void test_assign_throws<small_throws_on_copy, false>()::'lambda'(std::__1::any&, auto&&)::operator()<small_throws_on_copy&>(std::__1::any&, auto&&) const",
  ),
  (
    "_ZZN5test71fIiEEvvENKUlTyQaa1CIT_E1CITL0__ET0_E_clIiiEEDaS3_Q1CIDtfp_EE", "auto void test7::f<int>()::'lambda'<typename $T> requires C<T> && C<TL0_> (auto)::operator()<int, int>(auto) const requires C<decltype(fp)>",
    "void test7::f<int>()::'lambda'<typename $T> requires C<T> && C<TL0_> (auto)::operator()<int, int>",
    "auto void test7::f<int>()::'lambda'<typename $T> requires C<T> && C<TL0_> (auto)::operator()<int, int>(auto) const requires C<decltype(fp)>",
  ),
  (
    "_ZZN5test71fIiEEvvENKUlTyQaa1CIT_E1CITL0__ET0_E0_clIiiEEDaS3_Qaa1CIDtfp_EELb1E",
    "auto void test7::f<int>()::'lambda0'<typename $T> requires C<T> && C<TL0_> (auto)::operator()<int, int>(auto) const requires C<decltype(fp)> && true",
    "void test7::f<int>()::'lambda0'<typename $T> requires C<T> && C<TL0_> (auto)::operator()<int, int>",
    "auto void test7::f<int>()::'lambda0'<typename $T> requires C<T> && C<TL0_> (auto)::operator()<int, int>(auto) const requires C<decltype(fp)> && true",
  ),
  (
    "_ZN1S1fILb1EEEv1XILUlvE_EE", "void S::f<true>(X<[](){...}>)", "S::f<true>",
    "void S::f<true>(X<[](){...}>)",
  ),
  (
    "_ZNK1xMUlTnPA3_ivE_clILS0_0EEEDav", "auto x::'lambda'<int (*$N) [3]>()::operator()<(int [3])0>() const",
    "x::'lambda'<int (*$N) [3]>()::operator()<(int [3])0>", "auto x::'lambda'<int (*$N) [3]>()::operator()<(int [3])0>() const",
  ),
  (
    "_ZZ11inline_funcvENKUlTyTyT_T0_E_clIiiEEDaS_S0_", "auto inline_func()::'lambda'<typename $T, typename $T0>($T, $T0)::operator()<int, int>($T, $T0) const",
    "inline_func()::'lambda'<typename $T, typename $T0>($T, $T0)::operator()<int, int>",
    "auto inline_func()::'lambda'<typename $T, typename $T0>($T, $T0)::operator()<int, int>($T, $T0) const",
  ),
  (
    "_ZN1AIiE1fIfEEvDTLUlTyTtTyTnTL1__ETL0_1_T_TL0__E_EE", "void A<int>::f<float>(decltype([]<typename $T, template<typename $T0, $T0 $N> typename $TT>(auto, float, $T){...}))",
    "A<int>::f<float>", "void A<int>::f<float>(decltype([]<typename $T, template<typename $T0, $T0 $N> typename $TT>(auto, float, $T){...}))",
  ),
  (
    "_ZNK1xMUlTyT_E_clIiEEDaS_", "auto x::'lambda'<typename $T>($T)::operator()<int>(x) const",
    "x::'lambda'<typename $T>($T)::operator()<int>", "auto x::'lambda'<typename $T>($T)::operator()<int>(x) const",
  ),
  (
    "_ZNK1xMUlTyTtTyTnT_TpTnPA3_TL0__ETpTyvE_clIi1XJfEEEDav", "auto x::'lambda'<typename $T, template<typename $T0, $T $N, $T0 (*...$N0) [3]> typename $TT, typename ...$T1>()::operator()<int, X, float>() const",
    "x::'lambda'<typename $T, template<typename $T0, $T $N, $T0 (*...$N0) [3]> typename $TT, typename ...$T1>()::operator()<int, X, float>",
    "auto x::'lambda'<typename $T, template<typename $T0, $T $N, $T0 (*...$N0) [3]> typename $TT, typename ...$T1>()::operator()<int, X, float>() const",
  ),
  (
    "_ZZ11inline_funcvENKUlTyTyT_T1_T0_E_clIiiiEEDaS_S0_S1_", "auto inline_func()::'lambda'<typename $T, typename $T0>($T, auto, $T0)::operator()<int, int, int>($T, auto, $T0) const",
    "inline_func()::'lambda'<typename $T, typename $T0>($T, auto, $T0)::operator()<int, int, int>",
    "auto inline_func()::'lambda'<typename $T, typename $T0>($T, auto, $T0)::operator()<int, int, int>($T, auto, $T0) const",
  ),
  (
    "_ZN1C1fIiEEvDTtlNS_UlT_TL0__E_EEE", "void C::f<int>(decltype(C::'lambda'(int, auto){}))",
    "C::f<int>", "void C::f<int>(decltype(C::'lambda'(int, auto){}))",
  ),
  (
    "_ZZN5test71fIiEEvvENKUlTyQaa1CIT_E1CITL0__ET0_E1_clIiiEEDaS3_Q1CIDtfp_EE", "auto void test7::f<int>()::'lambda1'<typename $T> requires C<T> && C<TL0_> (auto)::operator()<int, int>(auto) const requires C<decltype(fp)>",
    "void test7::f<int>()::'lambda1'<typename $T> requires C<T> && C<TL0_> (auto)::operator()<int, int>",
    "auto void test7::f<int>()::'lambda1'<typename $T> requires C<T> && C<TL0_> (auto)::operator()<int, int>(auto) const requires C<decltype(fp)>",
  ),
  ("_ZN1fIiEEvNTUt_E", "_ZN1fIiEEvNTUt_E", "f<int>", "_ZN1fIiEEvNTUt_E"),
  ("_ZNDTUt_Ev", "_ZNDTUt_Ev", "_ZNDTUt_Ev", "_ZNDTUt_Ev"),
  ("_ZNWUt_3FOOEv", "_ZNWUt_3FOOEv", "_ZNWUt_3FOOEv", "_ZNWUt_3FOOEv"),
  (
    "_ZN12_GLOBAL__N_111UbigraphVizD0Ev", "(anonymous namespace)::UbigraphViz::~UbigraphViz()",
    "(anonymous namespace)::UbigraphViz::~UbigraphViz", "(anonymous namespace)::UbigraphViz::~UbigraphViz()",
  ),
  (
    "_ZN12_GLOBAL__N_111UbigraphVizD1Ev", "(anonymous namespace)::UbigraphViz::~UbigraphViz()",
    "(anonymous namespace)::UbigraphViz::~UbigraphViz", "(anonymous namespace)::UbigraphViz::~UbigraphViz()",
  ),
  (
    "_ZTVN12_GLOBAL__N_111UbigraphVizE", "vtable for (anonymous namespace)::UbigraphViz",
    "vtable for (anonymous namespace)::UbigraphViz", "vtable for (anonymous namespace)::UbigraphViz",
  ),
  (
    "_ZN12_GLOBAL__N_111UbigraphViz7AddEdgeEPN5clang4ento12ExplodedNodeES4_", "(anonymous namespace)::UbigraphViz::AddEdge(clang::ento::ExplodedNode*, clang::ento::ExplodedNode*)",
    "(anonymous namespace)::UbigraphViz::AddEdge", "(anonymous namespace)::UbigraphViz::AddEdge(clang::ento::ExplodedNode*, clang::ento::ExplodedNode*)",
  ),
  (
    "_Z2tfIZUb_E1SEiv", "int tf<'block-literal'::S>()", "tf<'block-literal'::S>",
    "int tf<'block-literal'::S>()",
  ),
  (
    "_Z1fB3fooB3barv", "f[abi:foo][abi:bar]()", "f[abi:foo][abi:bar]", "f[abi:foo][abi:bar]()",
  ),
  (
    "_ZN12_GLOBAL__N_111ARMFastISel14ARMEmitLibcallEPKN4llvm11InstructionENS1_5RTLIB7LibcallE",
    "(anonymous namespace)::ARMFastISel::ARMEmitLibcall(llvm::Instruction const*, llvm::RTLIB::Libcall)",
    "(anonymous namespace)::ARMFastISel::ARMEmitLibcall", "(anonymous namespace)::ARMFastISel::ARMEmitLibcall(llvm::Instruction const*, llvm::RTLIB::Libcall)",
  ),
  (
    "_ZN12_GLOBAL__N_114MCNullStreamer16EmitSLEB128ValueEPKN4llvm6MCExprEj", "(anonymous namespace)::MCNullStreamer::EmitSLEB128Value(llvm::MCExpr const*, unsigned int)",
    "(anonymous namespace)::MCNullStreamer::EmitSLEB128Value", "(anonymous namespace)::MCNullStreamer::EmitSLEB128Value(llvm::MCExpr const*, unsigned int)",
  ),
  (
    "_ZN12_GLOBAL__N_117MCLoggingStreamer16EmitSLEB128ValueEPKN4llvm6MCExprEj", "(anonymous namespace)::MCLoggingStreamer::EmitSLEB128Value(llvm::MCExpr const*, unsigned int)",
    "(anonymous namespace)::MCLoggingStreamer::EmitSLEB128Value", "(anonymous namespace)::MCLoggingStreamer::EmitSLEB128Value(llvm::MCExpr const*, unsigned int)",
  ),
  (
    "_ZN4llvm16MCObjectStreamer16EmitSLEB128ValueEPKNS_6MCExprEj", "llvm::MCObjectStreamer::EmitSLEB128Value(llvm::MCExpr const*, unsigned int)",
    "llvm::MCObjectStreamer::EmitSLEB128Value", "llvm::MCObjectStreamer::EmitSLEB128Value(llvm::MCExpr const*, unsigned int)",
  ),
  (
    "_ZN12_GLOBAL__N_113MCAsmStreamer16EmitSLEB128ValueEPKN4llvm6MCExprEj", "(anonymous namespace)::MCAsmStreamer::EmitSLEB128Value(llvm::MCExpr const*, unsigned int)",
    "(anonymous namespace)::MCAsmStreamer::EmitSLEB128Value", "(anonymous namespace)::MCAsmStreamer::EmitSLEB128Value(llvm::MCExpr const*, unsigned int)",
  ),
  (
    "_Z1fSsB1XS_", "f(std::string[abi:X], std::string[abi:X])", "f", "f(std::string[abi:X], std::string[abi:X])",
  ),
  (
    "_ZN4llvm16DAGTypeLegalizer11MakeLibCallENS_5RTLIB7LibcallENS_3EVTEPKNS_7SDValueEjbNS_8DebugLocE",
    "llvm::DAGTypeLegalizer::MakeLibCall(llvm::RTLIB::Libcall, llvm::EVT, llvm::SDValue const*, unsigned int, bool, llvm::DebugLoc)",
    "llvm::DAGTypeLegalizer::MakeLibCall", "llvm::DAGTypeLegalizer::MakeLibCall(llvm::RTLIB::Libcall, llvm::EVT, llvm::SDValue const*, unsigned int, bool, llvm::DebugLoc)",
  ),
  (
    "___Z3foo_block_invoke.25", "invocation function for block in foo", "invocation function for block in foo",
    "invocation function for block in foo",
  ),
  (
    "____Z3foo_block_invoke.25", "invocation function for block in foo", "invocation function for block in foo",
    "invocation function for block in foo",
  ),
  (
    "_ZNK10__cxxabiv111__libcxxabi5__sub20first_demangled_nameEPc.eh", "__cxxabiv1::__libcxxabi::__sub::first_demangled_name(char*) const (.eh)",
    "__cxxabiv1::__libcxxabi::__sub::first_demangled_name", "__cxxabiv1::__libcxxabi::__sub::first_demangled_name(char*) const (.eh)",
  ),
  (
    "__alloc_token__Znwm.llvm.1234", "__alloc_token__Znwm.llvm.1234", "__alloc_token__Znwm.llvm.1234",
    "__alloc_token__Znwm.llvm.1234",
  ),
  (
    "_ZN5clang9ASTWriter14WriteStatCacheERNS_17MemorizeStatCallsE", "clang::ASTWriter::WriteStatCache(clang::MemorizeStatCalls&)",
    "clang::ASTWriter::WriteStatCache", "clang::ASTWriter::WriteStatCache(clang::MemorizeStatCalls&)",
  ),
  (
    "_ZN5clang7CodeGen15CodeGenFunction15EmitStartEHSpecEPKNS_4DeclE", "clang::CodeGen::CodeGenFunction::EmitStartEHSpec(clang::Decl const*)",
    "clang::CodeGen::CodeGenFunction::EmitStartEHSpec", "clang::CodeGen::CodeGenFunction::EmitStartEHSpec(clang::Decl const*)",
  ),
  (
    "_ZN5clang13ASTStmtReader9VisitStmtEPNS_4StmtE", "clang::ASTStmtReader::VisitStmt(clang::Stmt*)",
    "clang::ASTStmtReader::VisitStmt", "clang::ASTStmtReader::VisitStmt(clang::Stmt*)",
  ),
  (
    "_ZN5clang11DocumentXML12escapeStringEPKcm", "clang::DocumentXML::escapeString(char const*, unsigned long)",
    "clang::DocumentXML::escapeString", "clang::DocumentXML::escapeString(char const*, unsigned long)",
  ),
  (
    "_ZN4llvm13StringMapImpl9RemoveKeyEPNS_18StringMapEntryBaseE", "llvm::StringMapImpl::RemoveKey(llvm::StringMapEntryBase*)",
    "llvm::StringMapImpl::RemoveKey", "llvm::StringMapImpl::RemoveKey(llvm::StringMapEntryBase*)",
  ),
  (
    "_ZNSt5dequeIPN5clang6Parser12ParsingClassESaIS3_EE17_M_reallocate_mapEmb", "std::deque<clang::Parser::ParsingClass*, std::allocator<clang::Parser::ParsingClass*>>::_M_reallocate_map(unsigned long, bool)",
    "std::deque<clang::Parser::ParsingClass*, std::allocator<clang::Parser::ParsingClass*>>::_M_reallocate_map",
    "std::deque<clang::Parser::ParsingClass*, std::allocator<clang::Parser::ParsingClass*>>::_M_reallocate_map(unsigned long, bool)",
  ),
  (
    "_ZN5clang13ASTStmtWriter31AddExplicitTemplateArgumentListERKNS_28ExplicitTemplateArgumentListE",
    "clang::ASTStmtWriter::AddExplicitTemplateArgumentList(clang::ExplicitTemplateArgumentList const&)",
    "clang::ASTStmtWriter::AddExplicitTemplateArgumentList", "clang::ASTStmtWriter::AddExplicitTemplateArgumentList(clang::ExplicitTemplateArgumentList const&)",
  ),
  (
    "_ZN5clang4ento14GRStateManager14FindGDMContextEPvPFS2_RN4llvm16BumpPtrAllocatorEEPFvS2_E",
    "clang::ento::GRStateManager::FindGDMContext(void*, void* (*)(llvm::BumpPtrAllocator&), void (*)(void*))",
    "clang::ento::GRStateManager::FindGDMContext", "clang::ento::GRStateManager::FindGDMContext(void*, void* (*)(llvm::BumpPtrAllocator&), void (*)(void*))",
  ),
  (
    "_ZNSt6vectorISt4pairIPN4llvm11ConstantIntEPNS1_10BasicBlockEESaIS6_EE7reserveEm",
    "std::vector<std::pair<llvm::ConstantInt*, llvm::BasicBlock*>, std::allocator<std::pair<llvm::ConstantInt*, llvm::BasicBlock*>>>::reserve(unsigned long)",
    "std::vector<std::pair<llvm::ConstantInt*, llvm::BasicBlock*>, std::allocator<std::pair<llvm::ConstantInt*, llvm::BasicBlock*>>>::reserve",
    "std::vector<std::pair<llvm::ConstantInt*, llvm::BasicBlock*>, std::allocator<std::pair<llvm::ConstantInt*, llvm::BasicBlock*>>>::reserve(unsigned long)",
  ),
  (
    "_ZN11ImageLoader23recursiveGetDOFSectionsERKNS_11LinkContextERSt6vectorINS_7DOFInfoESaIS4_EE",
    "ImageLoader::recursiveGetDOFSections(ImageLoader::LinkContext const&, std::vector<ImageLoader::DOFInfo, std::allocator<ImageLoader::DOFInfo>>&)",
    "ImageLoader::recursiveGetDOFSections", "ImageLoader::recursiveGetDOFSections(ImageLoader::LinkContext const&, std::vector<ImageLoader::DOFInfo, std::allocator<ImageLoader::DOFInfo>>&)",
  ),
  (
    "_ZNSt6vectorIN4llvm18InlineCostAnalyzer7ArgInfoESaIS2_EE7reserveEm", "std::vector<llvm::InlineCostAnalyzer::ArgInfo, std::allocator<llvm::InlineCostAnalyzer::ArgInfo>>::reserve(unsigned long)",
    "std::vector<llvm::InlineCostAnalyzer::ArgInfo, std::allocator<llvm::InlineCostAnalyzer::ArgInfo>>::reserve",
    "std::vector<llvm::InlineCostAnalyzer::ArgInfo, std::allocator<llvm::InlineCostAnalyzer::ArgInfo>>::reserve(unsigned long)",
  ),
  (
    "_ZN12_GLOBAL__N_122CGObjCNonFragileABIMac14EmitMethodListEN4llvm5TwineEPKcRKSt6vectorIPNS1_8ConstantESaIS7_EE",
    "(anonymous namespace)::CGObjCNonFragileABIMac::EmitMethodList(llvm::Twine, char const*, std::vector<llvm::Constant*, std::allocator<llvm::Constant*>> const&)",
    "(anonymous namespace)::CGObjCNonFragileABIMac::EmitMethodList", "(anonymous namespace)::CGObjCNonFragileABIMac::EmitMethodList(llvm::Twine, char const*, std::vector<llvm::Constant*, std::allocator<llvm::Constant*>> const&)",
  ),
  (
    "_ZNSt11_Deque_baseIPN4llvm4LoopESaIS2_EE17_M_initialize_mapEm", "std::_Deque_base<llvm::Loop*, std::allocator<llvm::Loop*>>::_M_initialize_map(unsigned long)",
    "std::_Deque_base<llvm::Loop*, std::allocator<llvm::Loop*>>::_M_initialize_map",
    "std::_Deque_base<llvm::Loop*, std::allocator<llvm::Loop*>>::_M_initialize_map(unsigned long)",
  ),
  (
    "_ZNSt8_Rb_treeIPKN4llvm4TypeES3_St9_IdentityIS3_ESt4lessIS3_ESaIS3_EE16_M_insert_uniqueERKS3_",
    "std::_Rb_tree<llvm::Type const*, llvm::Type const*, std::_Identity<llvm::Type const*>, std::less<llvm::Type const*>, std::allocator<llvm::Type const*>>::_M_insert_unique(llvm::Type const* const&)",
    "std::_Rb_tree<llvm::Type const*, llvm::Type const*, std::_Identity<llvm::Type const*>, std::less<llvm::Type const*>, std::allocator<llvm::Type const*>>::_M_insert_unique",
    "std::_Rb_tree<llvm::Type const*, llvm::Type const*, std::_Identity<llvm::Type const*>, std::less<llvm::Type const*>, std::allocator<llvm::Type const*>>::_M_insert_unique(llvm::Type const* const&)",
  ),
  (
    "_ZNSt6vectorISt4pairIjbESaIS1_EEC2ERKS3_", "std::vector<std::pair<unsigned int, bool>, std::allocator<std::pair<unsigned int, bool>>>::vector(std::vector<std::pair<unsigned int, bool>, std::allocator<std::pair<unsigned int, bool>>> const&)",
    "std::vector<std::pair<unsigned int, bool>, std::allocator<std::pair<unsigned int, bool>>>::vector",
    "std::vector<std::pair<unsigned int, bool>, std::allocator<std::pair<unsigned int, bool>>>::vector(std::vector<std::pair<unsigned int, bool>, std::allocator<std::pair<unsigned int, bool>>> const&)",
  ),
  (
    "_ZNSt6vectorIN11ImageLoader7DOFInfoESaIS1_EE9push_backERKS1_", "std::vector<ImageLoader::DOFInfo, std::allocator<ImageLoader::DOFInfo>>::push_back(ImageLoader::DOFInfo const&)",
    "std::vector<ImageLoader::DOFInfo, std::allocator<ImageLoader::DOFInfo>>::push_back",
    "std::vector<ImageLoader::DOFInfo, std::allocator<ImageLoader::DOFInfo>>::push_back(ImageLoader::DOFInfo const&)",
  ),
  ("_Z1fSbIiE", "f(std::basic_string<int>)", "f", "f(std::basic_string<int>)"),
  (
    "_ZNSbIiED1Ev", "std::basic_string<int>::~basic_string()", "std::basic_string<int>::~basic_string",
    "std::basic_string<int>::~basic_string()",
  ),
  (
    "_Z1fNSbIiE1gE", "f(std::basic_string<int>::g)", "f", "f(std::basic_string<int>::g)",
  ),
  (
    "_ZN4llvm8LLParser16PerFunctionState11SetInstNameEiRKSsNS_5SMLocEPNS_11InstructionE",
    "llvm::LLParser::PerFunctionState::SetInstName(int, std::string const&, llvm::SMLoc, llvm::Instruction*)",
    "llvm::LLParser::PerFunctionState::SetInstName", "llvm::LLParser::PerFunctionState::SetInstName(int, std::string const&, llvm::SMLoc, llvm::Instruction*)",
  ),
  (
    "_ZNSs7replaceEmmPKcm", "std::string::replace(unsigned long, unsigned long, char const*, unsigned long)",
    "std::string::replace", "std::string::replace(unsigned long, unsigned long, char const*, unsigned long)",
  ),
  (
    "_ZN4llvm2cl3optISsLb1ENS0_6parserISsEEE19getExtraOptionNamesERNS_15SmallVectorImplIPKcEE",
    "llvm::cl::opt<std::string, true, llvm::cl::parser<std::string>>::getExtraOptionNames(llvm::SmallVectorImpl<char const*>&)",
    "llvm::cl::opt<std::string, true, llvm::cl::parser<std::string>>::getExtraOptionNames",
    "llvm::cl::opt<std::string, true, llvm::cl::parser<std::string>>::getExtraOptionNames(llvm::SmallVectorImpl<char const*>&)",
  ),
  (
    "_ZN4llvm14RegisterTargetILNS_6Triple8ArchTypeE16ELb1EE21getTripleMatchQualityERKSs",
    "llvm::RegisterTarget<(llvm::Triple::ArchType)16, true>::getTripleMatchQuality(std::string const&)",
    "llvm::RegisterTarget<(llvm::Triple::ArchType)16, true>::getTripleMatchQuality",
    "llvm::RegisterTarget<(llvm::Triple::ArchType)16, true>::getTripleMatchQuality(std::string const&)",
  ),
  (
    "_ZN4llvm15getLocationInfoEPKNS_5ValueERSsS3_RjS3_S3_", "llvm::getLocationInfo(llvm::Value const*, std::string&, std::string&, unsigned int&, std::string&, std::string&)",
    "llvm::getLocationInfo", "llvm::getLocationInfo(llvm::Value const*, std::string&, std::string&, unsigned int&, std::string&, std::string&)",
  ),
  (
    "_ZN4llvm12X86SubtargetC1ERKSsS2_b", "llvm::X86Subtarget::X86Subtarget(std::string const&, std::string const&, bool)",
    "llvm::X86Subtarget::X86Subtarget", "llvm::X86Subtarget::X86Subtarget(std::string const&, std::string const&, bool)",
  ),
  (
    "_ZNKSs5rfindEcm", "std::string::rfind(char, unsigned long) const", "std::string::rfind",
    "std::string::rfind(char, unsigned long) const",
  ),
  (
    "_ZN4llvm10RedirectIOEPKNS_3sys4PathEiPSs", "llvm::RedirectIO(llvm::sys::Path const*, int, std::string*)",
    "llvm::RedirectIO", "llvm::RedirectIO(llvm::sys::Path const*, int, std::string*)",
  ),
  (
    "_ZN4llvm18InlineCostAnalyzer13getInlineCostENS_8CallSiteERNS_11SmallPtrSetIPKNS_8FunctionELj16EEE",
    "llvm::InlineCostAnalyzer::getInlineCost(llvm::CallSite, llvm::SmallPtrSet<llvm::Function const*, 16u>&)",
    "llvm::InlineCostAnalyzer::getInlineCost", "llvm::InlineCostAnalyzer::getInlineCost(llvm::CallSite, llvm::SmallPtrSet<llvm::Function const*, 16u>&)",
  ),
  (
    "_ZN5clang4ento26CheckObjCInstMethSignatureEPKNS_22ObjCImplementationDeclERNS0_11BugReporterE",
    "clang::ento::CheckObjCInstMethSignature(clang::ObjCImplementationDecl const*, clang::ento::BugReporter&)",
    "clang::ento::CheckObjCInstMethSignature", "clang::ento::CheckObjCInstMethSignature(clang::ObjCImplementationDecl const*, clang::ento::BugReporter&)",
  ),
  (
    "_ZN4llvm13LPPassManager29cloneBasicBlockSimpleAnalysisEPNS_10BasicBlockES2_PNS_4LoopE",
    "llvm::LPPassManager::cloneBasicBlockSimpleAnalysis(llvm::BasicBlock*, llvm::BasicBlock*, llvm::Loop*)",
    "llvm::LPPassManager::cloneBasicBlockSimpleAnalysis", "llvm::LPPassManager::cloneBasicBlockSimpleAnalysis(llvm::BasicBlock*, llvm::BasicBlock*, llvm::Loop*)",
  ),
  (
    "_ZN12_GLOBAL__N_19ARMCXXABI18GetArrayCookieSizeEPKN5clang10CXXNewExprE", "(anonymous namespace)::ARMCXXABI::GetArrayCookieSize(clang::CXXNewExpr const*)",
    "(anonymous namespace)::ARMCXXABI::GetArrayCookieSize", "(anonymous namespace)::ARMCXXABI::GetArrayCookieSize(clang::CXXNewExpr const*)",
  ),
  (
    "_ZN5clang4ento14CheckerVisitorIN12_GLOBAL__N_115CastSizeCheckerEED0Ev", "clang::ento::CheckerVisitor<(anonymous namespace)::CastSizeChecker>::~CheckerVisitor()",
    "clang::ento::CheckerVisitor<(anonymous namespace)::CastSizeChecker>::~CheckerVisitor",
    "clang::ento::CheckerVisitor<(anonymous namespace)::CastSizeChecker>::~CheckerVisitor()",
  ),
  (
    "_ZN4llvm13CallGraphNode17addCalledFunctionENS_8CallSiteEPS0_", "llvm::CallGraphNode::addCalledFunction(llvm::CallSite, llvm::CallGraphNode*)",
    "llvm::CallGraphNode::addCalledFunction", "llvm::CallGraphNode::addCalledFunction(llvm::CallSite, llvm::CallGraphNode*)",
  ),
  (
    "_ZNK4llvm17X86TargetLowering30getSingleConstraintMatchWeightERNS_14TargetLowering14AsmOperandInfoEPKc",
    "llvm::X86TargetLowering::getSingleConstraintMatchWeight(llvm::TargetLowering::AsmOperandInfo&, char const*) const",
    "llvm::X86TargetLowering::getSingleConstraintMatchWeight", "llvm::X86TargetLowering::getSingleConstraintMatchWeight(llvm::TargetLowering::AsmOperandInfo&, char const*) const",
  ),
  (
    "_ZN4llvm16SimplifySDivInstEPNS_5ValueES1_PKNS_10DataLayoutEPKNS_13DominatorTreeE",
    "llvm::SimplifySDivInst(llvm::Value*, llvm::Value*, llvm::DataLayout const*, llvm::DominatorTree const*)",
    "llvm::SimplifySDivInst", "llvm::SimplifySDivInst(llvm::Value*, llvm::Value*, llvm::DataLayout const*, llvm::DominatorTree const*)",
  ),
  (
    "_ZN5clang6Parser21ParseCXXNewExpressionEbNS_14SourceLocationE", "clang::Parser::ParseCXXNewExpression(bool, clang::SourceLocation)",
    "clang::Parser::ParseCXXNewExpression", "clang::Parser::ParseCXXNewExpression(bool, clang::SourceLocation)",
  ),
  (
    "_ZN5clang4Sema16ActOnDefaultStmtENS_14SourceLocationES1_PNS_4StmtEPNS_5ScopeE",
    "clang::Sema::ActOnDefaultStmt(clang::SourceLocation, clang::SourceLocation, clang::Stmt*, clang::Scope*)",
    "clang::Sema::ActOnDefaultStmt", "clang::Sema::ActOnDefaultStmt(clang::SourceLocation, clang::SourceLocation, clang::Stmt*, clang::Scope*)",
  ),
  (
    "_ZN5clang12Preprocessor17AllocateMacroInfoENS_14SourceLocationE", "clang::Preprocessor::AllocateMacroInfo(clang::SourceLocation)",
    "clang::Preprocessor::AllocateMacroInfo", "clang::Preprocessor::AllocateMacroInfo(clang::SourceLocation)",
  ),
  (
    "_ZN5clang6Parser36ParseDeclarationStartingWithTemplateEjRNS_14SourceLocationENS_15AccessSpecifierE",
    "clang::Parser::ParseDeclarationStartingWithTemplate(unsigned int, clang::SourceLocation&, clang::AccessSpecifier)",
    "clang::Parser::ParseDeclarationStartingWithTemplate", "clang::Parser::ParseDeclarationStartingWithTemplate(unsigned int, clang::SourceLocation&, clang::AccessSpecifier)",
  ),
  (
    "_Z18TryReinterpretCastRN5clang4SemaEPNS_4ExprENS_8QualTypeEbRKNS_11SourceRangeERjRNS_8CastKindE",
    "TryReinterpretCast(clang::Sema&, clang::Expr*, clang::QualType, bool, clang::SourceRange const&, unsigned int&, clang::CastKind&)",
    "TryReinterpretCast", "TryReinterpretCast(clang::Sema&, clang::Expr*, clang::QualType, bool, clang::SourceRange const&, unsigned int&, clang::CastKind&)",
  ),
  (
    "_ZNK5clang13FullSourceLoc21getSpellingLineNumberEPb", "clang::FullSourceLoc::getSpellingLineNumber(bool*) const",
    "clang::FullSourceLoc::getSpellingLineNumber", "clang::FullSourceLoc::getSpellingLineNumber(bool*) const",
  ),
  (
    "_ZN5clang33ExternalPreprocessingRecordSourceD2Ev", "clang::ExternalPreprocessingRecordSource::~ExternalPreprocessingRecordSource()",
    "clang::ExternalPreprocessingRecordSource::~ExternalPreprocessingRecordSource",
    "clang::ExternalPreprocessingRecordSource::~ExternalPreprocessingRecordSource()",
  ),
  (
    "_ZNK5clang13SourceManager13getLineNumberENS_6FileIDEjPb", "clang::SourceManager::getLineNumber(clang::FileID, unsigned int, bool*) const",
    "clang::SourceManager::getLineNumber", "clang::SourceManager::getLineNumber(clang::FileID, unsigned int, bool*) const",
  ),
  ("_Z1fNSd1gE", "f(std::iostream::g)", "f", "f(std::iostream::g)"),
  ("_Z1fSd", "f(std::iostream)", "f", "f(std::iostream)"),
  (
    "_ZNSdC1Ev", "std::basic_iostream<char, std::char_traits<char>>::basic_iostream()",
    "std::basic_iostream<char, std::char_traits<char>>::basic_iostream", "std::basic_iostream<char, std::char_traits<char>>::basic_iostream()",
  ),
  (
    "_ZN4llvm4Type9getIntNTyERNS_11LLVMContextEj", "llvm::Type::getIntNTy(llvm::LLVMContext&, unsigned int)",
    "llvm::Type::getIntNTy", "llvm::Type::getIntNTy(llvm::LLVMContext&, unsigned int)",
  ),
  (
    "_ZNK5clang14CUDADeviceAttr5cloneERNS_10ASTContextE", "clang::CUDADeviceAttr::clone(clang::ASTContext&) const",
    "clang::CUDADeviceAttr::clone", "clang::CUDADeviceAttr::clone(clang::ASTContext&) const",
  ),
  (
    "_Z1rM1GFivEMS_KFivES_M1HFivES1_4whatIKS_E5what2IS8_ES3_", "r(int (G::*)(), int (G::*)() const, G, int (H::*)(), int (G::*)(), what<G const>, what2<G const>, int (G::*)() const)",
    "r", "r(int (G::*)(), int (G::*)() const, G, int (H::*)(), int (G::*)(), what<G const>, what2<G const>, int (G::*)() const)",
  ),
  (
    "_ZN5clang19RecursiveASTVisitorIN12_GLOBAL__N_117DependencyCheckerEE15TraverseTypeLocENS_7TypeLocE",
    "clang::RecursiveASTVisitor<(anonymous namespace)::DependencyChecker>::TraverseTypeLoc(clang::TypeLoc)",
    "clang::RecursiveASTVisitor<(anonymous namespace)::DependencyChecker>::TraverseTypeLoc",
    "clang::RecursiveASTVisitor<(anonymous namespace)::DependencyChecker>::TraverseTypeLoc(clang::TypeLoc)",
  ),
  (
    "_ZN4llvm9CallGraph19getOrInsertFunctionEPKNS_8FunctionE", "llvm::CallGraph::getOrInsertFunction(llvm::Function const*)",
    "llvm::CallGraph::getOrInsertFunction", "llvm::CallGraph::getOrInsertFunction(llvm::Function const*)",
  ),
  (
    "_ZN4llvm18ExtractElementInst15isValidOperandsEPKNS_5ValueES3_", "llvm::ExtractElementInst::isValidOperands(llvm::Value const*, llvm::Value const*)",
    "llvm::ExtractElementInst::isValidOperands", "llvm::ExtractElementInst::isValidOperands(llvm::Value const*, llvm::Value const*)",
  ),
  (
    "_ZN12_GLOBAL__N_125RegReductionPriorityQueueINS_14ilp_ls_rr_sortEE3popEv", "(anonymous namespace)::RegReductionPriorityQueue<(anonymous namespace)::ilp_ls_rr_sort>::pop()",
    "(anonymous namespace)::RegReductionPriorityQueue<(anonymous namespace)::ilp_ls_rr_sort>::pop",
    "(anonymous namespace)::RegReductionPriorityQueue<(anonymous namespace)::ilp_ls_rr_sort>::pop()",
  ),
  (
    "_ZN4llvm8LoopInfo13runOnFunctionERNS_8FunctionE", "llvm::LoopInfo::runOnFunction(llvm::Function&)",
    "llvm::LoopInfo::runOnFunction", "llvm::LoopInfo::runOnFunction(llvm::Function&)",
  ),
  (
    "_ZN5clang4Sema32DefaultVariadicArgumentPromotionERPNS_4ExprENS0_16VariadicCallTypeEPNS_12FunctionDeclE",
    "clang::Sema::DefaultVariadicArgumentPromotion(clang::Expr*&, clang::Sema::VariadicCallType, clang::FunctionDecl*)",
    "clang::Sema::DefaultVariadicArgumentPromotion", "clang::Sema::DefaultVariadicArgumentPromotion(clang::Expr*&, clang::Sema::VariadicCallType, clang::FunctionDecl*)",
  ),
  (
    "_ZN5clang4Sema24CheckParmsForFunctionDefEPPNS_11ParmVarDeclES3_b", "clang::Sema::CheckParmsForFunctionDef(clang::ParmVarDecl**, clang::ParmVarDecl**, bool)",
    "clang::Sema::CheckParmsForFunctionDef", "clang::Sema::CheckParmsForFunctionDef(clang::ParmVarDecl**, clang::ParmVarDecl**, bool)",
  ),
  (
    "_ZN4llvm8DenseMapIPN5clang14IdentifierInfoENS1_4Sema8WeakInfoENS_12DenseMapInfoIS3_EENS6_IS5_EEE4growEj",
    "llvm::DenseMap<clang::IdentifierInfo*, clang::Sema::WeakInfo, llvm::DenseMapInfo<clang::IdentifierInfo*>, llvm::DenseMapInfo<clang::Sema::WeakInfo>>::grow(unsigned int)",
    "llvm::DenseMap<clang::IdentifierInfo*, clang::Sema::WeakInfo, llvm::DenseMapInfo<clang::IdentifierInfo*>, llvm::DenseMapInfo<clang::Sema::WeakInfo>>::grow",
    "llvm::DenseMap<clang::IdentifierInfo*, clang::Sema::WeakInfo, llvm::DenseMapInfo<clang::IdentifierInfo*>, llvm::DenseMapInfo<clang::Sema::WeakInfo>>::grow(unsigned int)",
  ),
  (
    "_ZN5clang7ASTUnit14ConfigureDiagsERN4llvm18IntrusiveRefCntPtrINS_10DiagnosticEEEPPKcS8_RS0_b",
    "clang::ASTUnit::ConfigureDiags(llvm::IntrusiveRefCntPtr<clang::Diagnostic>&, char const**, char const**, clang::ASTUnit&, bool)",
    "clang::ASTUnit::ConfigureDiags", "clang::ASTUnit::ConfigureDiags(llvm::IntrusiveRefCntPtr<clang::Diagnostic>&, char const**, char const**, clang::ASTUnit&, bool)",
  ),
  (
    "_ZN5clang7CodeGen15CodeGenFunction20EmitScalarConversionEPN4llvm5ValueENS_8QualTypeES5_",
    "clang::CodeGen::CodeGenFunction::EmitScalarConversion(llvm::Value*, clang::QualType, clang::QualType)",
    "clang::CodeGen::CodeGenFunction::EmitScalarConversion", "clang::CodeGen::CodeGenFunction::EmitScalarConversion(llvm::Value*, clang::QualType, clang::QualType)",
  ),
  (
    "_ZN5clang9ASTVectorIPNS_4StmtEE6insertERNS_10ASTContextEPS2_mRKS2_", "clang::ASTVector<clang::Stmt*>::insert(clang::ASTContext&, clang::Stmt**, unsigned long, clang::Stmt* const&)",
    "clang::ASTVector<clang::Stmt*>::insert", "clang::ASTVector<clang::Stmt*>::insert(clang::ASTContext&, clang::Stmt**, unsigned long, clang::Stmt* const&)",
  ),
  (
    "_ZN5clang10VectorTypeC1ENS_8QualTypeEjS1_NS0_10VectorKindE", "clang::VectorType::VectorType(clang::QualType, unsigned int, clang::QualType, clang::VectorType::VectorKind)",
    "clang::VectorType::VectorType", "clang::VectorType::VectorType(clang::QualType, unsigned int, clang::QualType, clang::VectorType::VectorKind)",
  ),
  (
    "_ZN4llvm12CallGraphSCC11ReplaceNodeEPNS_13CallGraphNodeES2_", "llvm::CallGraphSCC::ReplaceNode(llvm::CallGraphNode*, llvm::CallGraphNode*)",
    "llvm::CallGraphSCC::ReplaceNode", "llvm::CallGraphSCC::ReplaceNode(llvm::CallGraphNode*, llvm::CallGraphNode*)",
  ),
  (
    "_ZN4llvm16DAGTypeLegalizer18PromoteIntRes_SDIVEPNS_6SDNodeE", "llvm::DAGTypeLegalizer::PromoteIntRes_SDIV(llvm::SDNode*)",
    "llvm::DAGTypeLegalizer::PromoteIntRes_SDIV", "llvm::DAGTypeLegalizer::PromoteIntRes_SDIV(llvm::SDNode*)",
  ),
  (
    "_ZN4llvm16DAGTypeLegalizer22PromoteIntRes_UADDSUBOEPNS_6SDNodeEj", "llvm::DAGTypeLegalizer::PromoteIntRes_UADDSUBO(llvm::SDNode*, unsigned int)",
    "llvm::DAGTypeLegalizer::PromoteIntRes_UADDSUBO", "llvm::DAGTypeLegalizer::PromoteIntRes_UADDSUBO(llvm::SDNode*, unsigned int)",
  ),
  (
    "_ZNK4llvm17X86TargetLowering14LowerFCOPYSIGNENS_7SDValueERNS_12SelectionDAGE",
    "llvm::X86TargetLowering::LowerFCOPYSIGN(llvm::SDValue, llvm::SelectionDAG&) const",
    "llvm::X86TargetLowering::LowerFCOPYSIGN", "llvm::X86TargetLowering::LowerFCOPYSIGN(llvm::SDValue, llvm::SelectionDAG&) const",
  ),
  (
    "_ZN4llvm16DAGTypeLegalizer33ScalarizeVecRes_INSERT_VECTOR_ELTEPNS_6SDNodeE",
    "llvm::DAGTypeLegalizer::ScalarizeVecRes_INSERT_VECTOR_ELT(llvm::SDNode*)", "llvm::DAGTypeLegalizer::ScalarizeVecRes_INSERT_VECTOR_ELT",
    "llvm::DAGTypeLegalizer::ScalarizeVecRes_INSERT_VECTOR_ELT(llvm::SDNode*)",
  ),
  (
    "_ZNK4llvm17X86TargetLowering12LowerBITCASTENS_7SDValueERNS_12SelectionDAGE",
    "llvm::X86TargetLowering::LowerBITCAST(llvm::SDValue, llvm::SelectionDAG&) const",
    "llvm::X86TargetLowering::LowerBITCAST", "llvm::X86TargetLowering::LowerBITCAST(llvm::SDValue, llvm::SelectionDAG&) const",
  ),
  (
    "_ZN4llvm25array_pod_sort_comparatorISt4pairIjPNS_14StringMapEntryIS1_IPNS_8MCSymbolEjEEEEEEiPKvSA_",
    "int llvm::array_pod_sort_comparator<std::pair<unsigned int, llvm::StringMapEntry<std::pair<llvm::MCSymbol*, unsigned int>>*>>(void const*, void const*)",
    "llvm::array_pod_sort_comparator<std::pair<unsigned int, llvm::StringMapEntry<std::pair<llvm::MCSymbol*, unsigned int>>*>>",
    "int llvm::array_pod_sort_comparator<std::pair<unsigned int, llvm::StringMapEntry<std::pair<llvm::MCSymbol*, unsigned int>>*>>(void const*, void const*)",
  ),
  (
    "_ZN4llvm15ScalarEvolution18getLoopDispositionEPKNS_4SCEVEPKNS_4LoopE", "llvm::ScalarEvolution::getLoopDisposition(llvm::SCEV const*, llvm::Loop const*)",
    "llvm::ScalarEvolution::getLoopDisposition", "llvm::ScalarEvolution::getLoopDisposition(llvm::SCEV const*, llvm::Loop const*)",
  ),
  (
    "_ZN4llvm17X86ATTInstPrinter10printSSECCEPKNS_6MCInstEjRNS_11raw_ostreamE", "llvm::X86ATTInstPrinter::printSSECC(llvm::MCInst const*, unsigned int, llvm::raw_ostream&)",
    "llvm::X86ATTInstPrinter::printSSECC", "llvm::X86ATTInstPrinter::printSSECC(llvm::MCInst const*, unsigned int, llvm::raw_ostream&)",
  ),
  (
    "_ZN4llvm15SmallVectorImplINS_15IntervalMapImpl4Path5EntryEEaSERKS4_", "llvm::SmallVectorImpl<llvm::IntervalMapImpl::Path::Entry>::operator=(llvm::SmallVectorImpl<llvm::IntervalMapImpl::Path::Entry> const&)",
    "llvm::SmallVectorImpl<llvm::IntervalMapImpl::Path::Entry>::operator=", "llvm::SmallVectorImpl<llvm::IntervalMapImpl::Path::Entry>::operator=(llvm::SmallVectorImpl<llvm::IntervalMapImpl::Path::Entry> const&)",
  ),
  (
    "_ZN4llvm15SmallVectorImplINS_7SDValueEEaSERKS2_", "llvm::SmallVectorImpl<llvm::SDValue>::operator=(llvm::SmallVectorImpl<llvm::SDValue> const&)",
    "llvm::SmallVectorImpl<llvm::SDValue>::operator=", "llvm::SmallVectorImpl<llvm::SDValue>::operator=(llvm::SmallVectorImpl<llvm::SDValue> const&)",
  ),
  (
    "_ZN4llvm15SmallVectorImplIiEaSERKS1_", "llvm::SmallVectorImpl<int>::operator=(llvm::SmallVectorImpl<int> const&)",
    "llvm::SmallVectorImpl<int>::operator=", "llvm::SmallVectorImpl<int>::operator=(llvm::SmallVectorImpl<int> const&)",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L16S16_SuperRegsSetE", "llvm::(anonymous namespace)::S16_SuperRegsSet",
    "llvm::(anonymous namespace)::S16_SuperRegsSet", "llvm::(anonymous namespace)::S16_SuperRegsSet",
  ),
  (
    "_ZN4llvm3X8616SEGMENT_REGClassD1Ev", "llvm::X86::SEGMENT_REGClass::~SEGMENT_REGClass()",
    "llvm::X86::SEGMENT_REGClass::~SEGMENT_REGClass", "llvm::X86::SEGMENT_REGClass::~SEGMENT_REGClass()",
  ),
  (
    "_ZNSt6vectorIN5clang15DirectoryLookupESaIS1_EEaSERKS3_", "std::vector<clang::DirectoryLookup, std::allocator<clang::DirectoryLookup>>::operator=(std::vector<clang::DirectoryLookup, std::allocator<clang::DirectoryLookup>> const&)",
    "std::vector<clang::DirectoryLookup, std::allocator<clang::DirectoryLookup>>::operator=",
    "std::vector<clang::DirectoryLookup, std::allocator<clang::DirectoryLookup>>::operator=(std::vector<clang::DirectoryLookup, std::allocator<clang::DirectoryLookup>> const&)",
  ),
  (
    "_ZN4llvm16SelectionDAGISel16Select_INLINEASMEPNS_6SDNodeE", "llvm::SelectionDAGISel::Select_INLINEASM(llvm::SDNode*)",
    "llvm::SelectionDAGISel::Select_INLINEASM", "llvm::SelectionDAGISel::Select_INLINEASM(llvm::SDNode*)",
  ),
  (
    "_ZN4llvm16DAGTypeLegalizer21ExpandIntRes_UADDSUBOEPNS_6SDNodeERNS_7SDValueES4_",
    "llvm::DAGTypeLegalizer::ExpandIntRes_UADDSUBO(llvm::SDNode*, llvm::SDValue&, llvm::SDValue&)",
    "llvm::DAGTypeLegalizer::ExpandIntRes_UADDSUBO", "llvm::DAGTypeLegalizer::ExpandIntRes_UADDSUBO(llvm::SDNode*, llvm::SDValue&, llvm::SDValue&)",
  ),
  (
    "_ZNK4llvm17X86TargetLowering19LowerUINT_TO_FP_i64ENS_7SDValueERNS_12SelectionDAGE",
    "llvm::X86TargetLowering::LowerUINT_TO_FP_i64(llvm::SDValue, llvm::SelectionDAG&) const",
    "llvm::X86TargetLowering::LowerUINT_TO_FP_i64", "llvm::X86TargetLowering::LowerUINT_TO_FP_i64(llvm::SDValue, llvm::SelectionDAG&) const",
  ),
  (
    "_ZN11Expressions2f4ILi1EEEvPAplplLi2ET_T__i", "void Expressions::f4<1>(int (*) [2 + 1 + 1])",
    "Expressions::f4<1>", "void Expressions::f4<1>(int (*) [2 + 1 + 1])",
  ),
  (
    "_ZNK4llvm17X86TargetLowering15LowerUINT_TO_FPENS_7SDValueERNS_12SelectionDAGE",
    "llvm::X86TargetLowering::LowerUINT_TO_FP(llvm::SDValue, llvm::SelectionDAG&) const",
    "llvm::X86TargetLowering::LowerUINT_TO_FP", "llvm::X86TargetLowering::LowerUINT_TO_FP(llvm::SDValue, llvm::SelectionDAG&) const",
  ),
  (
    "_Z2f4IiEvDTu11__alignof__XcvT_Li0EEEE", "void f4<int>(decltype(__alignof__((int)(0))))",
    "f4<int>", "void f4<int>(decltype(__alignof__((int)(0))))",
  ),
  (
    "_ZN5test62f7IiEEvDTcvT_dtptL_ZNS_2zpEE1s1iE", "void test6::f7<int>(decltype((int)(test6::zp->s.i)))",
    "test6::f7<int>", "void test6::f7<int>(decltype((int)(test6::zp->s.i)))",
  ),
  (
    "_ZSt13__heap_selectIPSt4pairIjPN4llvm9StoreInstEEEvT_S6_S6_", "void std::__heap_select<std::pair<unsigned int, llvm::StoreInst*>*>(std::pair<unsigned int, llvm::StoreInst*>*, std::pair<unsigned int, llvm::StoreInst*>*, std::pair<unsigned int, llvm::StoreInst*>*)",
    "std::__heap_select<std::pair<unsigned int, llvm::StoreInst*>*>", "void std::__heap_select<std::pair<unsigned int, llvm::StoreInst*>*>(std::pair<unsigned int, llvm::StoreInst*>*, std::pair<unsigned int, llvm::StoreInst*>*, std::pair<unsigned int, llvm::StoreInst*>*)",
  ),
  (
    "_ZN4llvm15SmallVectorImplIyE6insertIPKcEEPyS5_T_S6_", "unsigned long long* llvm::SmallVectorImpl<unsigned long long>::insert<char const*>(unsigned long long*, char const*, char const*)",
    "llvm::SmallVectorImpl<unsigned long long>::insert<char const*>", "unsigned long long* llvm::SmallVectorImpl<unsigned long long>::insert<char const*>(unsigned long long*, char const*, char const*)",
  ),
  (
    "_Z1iIJEEPDwiDpT_EFivEPS2_", "int (*i<>(int (*)() throw(int)))() throw(int)",
    "i<>", "int (*i<>(int (*)() throw(int)))() throw(int)",
  ),
  (
    "_ZSt6__findIPPN5clang14IdentifierInfoES2_ET_S4_S4_RKT0_St26random_access_iterator_tag",
    "clang::IdentifierInfo** std::__find<clang::IdentifierInfo**, clang::IdentifierInfo*>(clang::IdentifierInfo**, clang::IdentifierInfo**, clang::IdentifierInfo* const&, std::random_access_iterator_tag)",
    "std::__find<clang::IdentifierInfo**, clang::IdentifierInfo*>", "clang::IdentifierInfo** std::__find<clang::IdentifierInfo**, clang::IdentifierInfo*>(clang::IdentifierInfo**, clang::IdentifierInfo**, clang::IdentifierInfo* const&, std::random_access_iterator_tag)",
  ),
  (
    "_ZSt26__uninitialized_fill_n_auxIPN4llvm13LiveVariables7VarInfoEmS2_EvT_T0_RKT1_St12__false_type",
    "void std::__uninitialized_fill_n_aux<llvm::LiveVariables::VarInfo*, unsigned long, llvm::LiveVariables::VarInfo>(llvm::LiveVariables::VarInfo*, unsigned long, llvm::LiveVariables::VarInfo const&, std::__false_type)",
    "std::__uninitialized_fill_n_aux<llvm::LiveVariables::VarInfo*, unsigned long, llvm::LiveVariables::VarInfo>",
    "void std::__uninitialized_fill_n_aux<llvm::LiveVariables::VarInfo*, unsigned long, llvm::LiveVariables::VarInfo>(llvm::LiveVariables::VarInfo*, unsigned long, llvm::LiveVariables::VarInfo const&, std::__false_type)",
  ),
  (
    "_ZSt16__insertion_sortIPPN4llvm12LiveIntervalEN12_GLOBAL__N_18LISorterEEvT_S6_T0_",
    "void std::__insertion_sort<llvm::LiveInterval**, (anonymous namespace)::LISorter>(llvm::LiveInterval**, llvm::LiveInterval**, (anonymous namespace)::LISorter)",
    "std::__insertion_sort<llvm::LiveInterval**, (anonymous namespace)::LISorter>",
    "void std::__insertion_sort<llvm::LiveInterval**, (anonymous namespace)::LISorter>(llvm::LiveInterval**, llvm::LiveInterval**, (anonymous namespace)::LISorter)",
  ),
  (
    "_ZSt16__introsort_loopIPSt4pairIjPN4llvm10BasicBlockEElEvT_S6_T0_", "void std::__introsort_loop<std::pair<unsigned int, llvm::BasicBlock*>*, long>(std::pair<unsigned int, llvm::BasicBlock*>*, std::pair<unsigned int, llvm::BasicBlock*>*, long)",
    "std::__introsort_loop<std::pair<unsigned int, llvm::BasicBlock*>*, long>", "void std::__introsort_loop<std::pair<unsigned int, llvm::BasicBlock*>*, long>(std::pair<unsigned int, llvm::BasicBlock*>*, std::pair<unsigned int, llvm::BasicBlock*>*, long)",
  ),
  (
    "_ZN5clang4ento16MemRegionManager12getSubRegionINS0_9VarRegionEPKNS_7VarDeclEEEPT_T0_PKNS0_9MemRegionE",
    "clang::ento::VarRegion* clang::ento::MemRegionManager::getSubRegion<clang::ento::VarRegion, clang::VarDecl const*>(clang::VarDecl const*, clang::ento::MemRegion const*)",
    "clang::ento::MemRegionManager::getSubRegion<clang::ento::VarRegion, clang::VarDecl const*>",
    "clang::ento::VarRegion* clang::ento::MemRegionManager::getSubRegion<clang::ento::VarRegion, clang::VarDecl const*>(clang::VarDecl const*, clang::ento::MemRegion const*)",
  ),
  (
    "_ZSt13__adjust_heapIPN5clang9ThunkInfoElS1_EvT_T0_S4_T1_", "void std::__adjust_heap<clang::ThunkInfo*, long, clang::ThunkInfo>(clang::ThunkInfo*, long, long, clang::ThunkInfo)",
    "std::__adjust_heap<clang::ThunkInfo*, long, clang::ThunkInfo>", "void std::__adjust_heap<clang::ThunkInfo*, long, clang::ThunkInfo>(clang::ThunkInfo*, long, long, clang::ThunkInfo)",
  ),
  (
    "_ZSt6__findIPPN4llvm6SDNodeES2_ET_S4_S4_RKT0_St26random_access_iterator_tag",
    "llvm::SDNode** std::__find<llvm::SDNode**, llvm::SDNode*>(llvm::SDNode**, llvm::SDNode**, llvm::SDNode* const&, std::random_access_iterator_tag)",
    "std::__find<llvm::SDNode**, llvm::SDNode*>", "llvm::SDNode** std::__find<llvm::SDNode**, llvm::SDNode*>(llvm::SDNode**, llvm::SDNode**, llvm::SDNode* const&, std::random_access_iterator_tag)",
  ),
  (
    "_ZSt25__unguarded_linear_insertIPPN4llvm12LiveIntervalES2_N12_GLOBAL__N_18LISorterEEvT_T0_T1_",
    "void std::__unguarded_linear_insert<llvm::LiveInterval**, llvm::LiveInterval*, (anonymous namespace)::LISorter>(llvm::LiveInterval**, llvm::LiveInterval*, (anonymous namespace)::LISorter)",
    "std::__unguarded_linear_insert<llvm::LiveInterval**, llvm::LiveInterval*, (anonymous namespace)::LISorter>",
    "void std::__unguarded_linear_insert<llvm::LiveInterval**, llvm::LiveInterval*, (anonymous namespace)::LISorter>(llvm::LiveInterval**, llvm::LiveInterval*, (anonymous namespace)::LISorter)",
  ),
  (
    "_ZN5test51iITpTtTk1CTnTL0__EJNS_1YENS_1ZENS_1XEEEEvv", "void test5::i<test5::Y, test5::Z, test5::X>()",
    "test5::i<test5::Y, test5::Z, test5::X>", "void test5::i<test5::Y, test5::Z, test5::X>()",
  ),
  (
    "_ZN5test51gITtTyTnTL0__Q1CIS1_EENS_1ZEEEvv", "void test5::g<test5::Z>()", "test5::g<test5::Z>",
    "void test5::g<test5::Z>()",
  ),
  (
    "_ZN5test51hITtTk1CTnTL0__ENS_1YEEEvv", "void test5::h<test5::Y>()", "test5::h<test5::Y>",
    "void test5::h<test5::Y>()",
  ),
  (
    "_ZN5test51fITtTyTnTL0__ENS_1ZEEEvv", "void test5::f<test5::Z>()", "test5::f<test5::Z>",
    "void test5::f<test5::Z>()",
  ),
  (
    "_ZN5test51hITtTk1CTnTL0__ENS_1XEEEvv", "void test5::h<test5::X>()", "test5::h<test5::X>",
    "void test5::h<test5::X>()",
  ),
  (
    "_ZN5test21AIbEF1gIvEEvzQaa4TrueIT_E4TrueITL0__E", "void test2::A<bool>::friend g<void>(...) requires True<T> && True<TL0_>",
    "test2::A<bool>::friend g<void>", "void test2::A<bool>::friend g<void>(...) requires True<T> && True<TL0_>",
  ),
  (
    "_ZN5test21AIiEF1iIvQaa4TrueIT_E4TrueITL0__EEEvz", "void test2::A<int>::friend i<void>(...)",
    "test2::A<int>::friend i<void>", "void test2::A<int>::friend i<void>(...)",
  ),
  (
    "_ZN5test51iITpTtTk1CTnTL0__EJNS_1XENS_1YENS_1ZEEEEvv", "void test5::i<test5::X, test5::Y, test5::Z>()",
    "test5::i<test5::X, test5::Y, test5::Z>", "void test5::i<test5::X, test5::Y, test5::Z>()",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L17XMM4_SuperRegsSetE", "llvm::(anonymous namespace)::XMM4_SuperRegsSet",
    "llvm::(anonymous namespace)::XMM4_SuperRegsSet", "llvm::(anonymous namespace)::XMM4_SuperRegsSet",
  ),
  (
    "_ZN4llvm3ARM9tGPRClassD1Ev", "llvm::ARM::tGPRClass::~tGPRClass()", "llvm::ARM::tGPRClass::~tGPRClass",
    "llvm::ARM::tGPRClass::~tGPRClass()",
  ),
  (
    "_ZN4llvm3ARM17QQPR_VFP2RegClassE", "llvm::ARM::QQPR_VFP2RegClass", "llvm::ARM::QQPR_VFP2RegClass",
    "llvm::ARM::QQPR_VFP2RegClass",
  ),
  (
    "_ZNK4llvm3ARM8GPRClass20allocation_order_endERKNS_15MachineFunctionE", "llvm::ARM::GPRClass::allocation_order_end(llvm::MachineFunction const&) const",
    "llvm::ARM::GPRClass::allocation_order_end", "llvm::ARM::GPRClass::allocation_order_end(llvm::MachineFunction const&) const",
  ),
  (
    "_ZN4llvm3ARM9QQPRClassD0Ev", "llvm::ARM::QQPRClass::~QQPRClass()", "llvm::ARM::QQPRClass::~QQPRClass",
    "llvm::ARM::QQPRClass::~QQPRClass()",
  ),
  (
    "_ZN12_GLOBAL__N_14LICM9runOnLoopEPN4llvm4LoopERNS1_13LPPassManagerE", "(anonymous namespace)::LICM::runOnLoop(llvm::Loop*, llvm::LPPassManager&)",
    "(anonymous namespace)::LICM::runOnLoop", "(anonymous namespace)::LICM::runOnLoop(llvm::Loop*, llvm::LPPassManager&)",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L12MM1_OverlapsE", "llvm::(anonymous namespace)::MM1_Overlaps",
    "llvm::(anonymous namespace)::MM1_Overlaps", "llvm::(anonymous namespace)::MM1_Overlaps",
  ),
  (
    "_ZN4llvm3ARM11QQQQPRClassD0Ev", "llvm::ARM::QQQQPRClass::~QQQQPRClass()", "llvm::ARM::QQQQPRClass::~QQQQPRClass",
    "llvm::ARM::QQQQPRClass::~QQQQPRClass()",
  ),
  (
    "_Z13PrintLLVMNameRN4llvm11raw_ostreamENS_9StringRefE10PrefixType", "PrintLLVMName(llvm::raw_ostream&, llvm::StringRef, PrefixType)",
    "PrintLLVMName", "PrintLLVMName(llvm::raw_ostream&, llvm::StringRef, PrefixType)",
  ),
  (
    "_ZN4llvm6Triple22getArchTypeForLLVMNameENS_9StringRefE", "llvm::Triple::getArchTypeForLLVMName(llvm::StringRef)",
    "llvm::Triple::getArchTypeForLLVMName", "llvm::Triple::getArchTypeForLLVMName(llvm::StringRef)",
  ),
  (
    "_Z1fIXtl5HellotlA6_cLc15ELc101ELc108ELc108ELc111EEEEEvv", "void f<Hello{\"\\xF\"\"ello\"}>()",
    "f<Hello{\"\\xF\"\"ello\"}>", "void f<Hello{\"\\xF\"\"ello\"}>()",
  ),
  (
    "_Z1fIXtl5HellotlA6_cLc72ELc101ELc12ELc108ELc111EEEEEvv", "void f<Hello{\"He\\flo\"}>()",
    "f<Hello{\"He\\flo\"}>", "void f<Hello{\"He\\flo\"}>()",
  ),
  (
    "_Z1fIXtl5HellotlA6_cLc72ELc101ELc14ELc108ELc111EEEEEvv", "void f<Hello{\"He\\xElo\"}>()",
    "f<Hello{\"He\\xElo\"}>", "void f<Hello{\"He\\xElo\"}>()",
  ),
  (
    "_Z1fIXtl5HellotlA6_cLc72ELc101ELc9ELc108ELc111EEEEEvv", "void f<Hello{\"He\\tlo\"}>()",
    "f<Hello{\"He\\tlo\"}>", "void f<Hello{\"He\\tlo\"}>()",
  ),
  (
    "_Z1fIXtl5HellotlA6_cLc72ELc101ELc7ELc108ELc111EEEEEvv", "void f<Hello{\"He\\alo\"}>()",
    "f<Hello{\"He\\alo\"}>", "void f<Hello{\"He\\alo\"}>()",
  ),
  (
    "_Z1fIXtl5HellotlA6_cLc72ELc101ELc34ELc108ELc111EEEEEvv", "void f<Hello{\"He\\\"lo\"}>()",
    "f<Hello{\"He\\\"lo\"}>", "void f<Hello{\"He\\\"lo\"}>()",
  ),
  (
    "_Z1fIXtl5HellotlA6_cLc72ELc101ELc10ELc108ELc111EEEEEvv", "void f<Hello{\"He\\nlo\"}>()",
    "f<Hello{\"He\\nlo\"}>", "void f<Hello{\"He\\nlo\"}>()",
  ),
  (
    "_Z1fIXtl5HellotlA6_cLc72ELc101ELc13ELc108ELc111EEEEEvv", "void f<Hello{\"He\\rlo\"}>()",
    "f<Hello{\"He\\rlo\"}>", "void f<Hello{\"He\\rlo\"}>()",
  ),
  ("_ZL11DiagArray46", "DiagArray46", "DiagArray46", "DiagArray46"),
  (
    "_ZNK12_GLOBAL__N_114MipsTargetInfo14getGCCRegNamesERPKPKcRj", "(anonymous namespace)::MipsTargetInfo::getGCCRegNames(char const* const*&, unsigned int&) const",
    "(anonymous namespace)::MipsTargetInfo::getGCCRegNames", "(anonymous namespace)::MipsTargetInfo::getGCCRegNames(char const* const*&, unsigned int&) const",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L10GR32_NOREXE", "llvm::(anonymous namespace)::GR32_NOREX",
    "llvm::(anonymous namespace)::GR32_NOREX", "llvm::(anonymous namespace)::GR32_NOREX",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L15SubregHashTableE", "llvm::(anonymous namespace)::SubregHashTable",
    "llvm::(anonymous namespace)::SubregHashTable", "llvm::(anonymous namespace)::SubregHashTable",
  ),
  (
    "_ZN5clang13ASTDeclReader12VisitVarDeclEPNS_7VarDeclE", "clang::ASTDeclReader::VisitVarDecl(clang::VarDecl*)",
    "clang::ASTDeclReader::VisitVarDecl", "clang::ASTDeclReader::VisitVarDecl(clang::VarDecl*)",
  ),
  (
    "_ZN5clang14CFConsumedAttrD1Ev", "clang::CFConsumedAttr::~CFConsumedAttr()",
    "clang::CFConsumedAttr::~CFConsumedAttr", "clang::CFConsumedAttr::~CFConsumedAttr()",
  ),
  (
    "_ZN5clang15AlignMac68kAttrD0Ev", "clang::AlignMac68kAttr::~AlignMac68kAttr()",
    "clang::AlignMac68kAttr::~AlignMac68kAttr", "clang::AlignMac68kAttr::~AlignMac68kAttr()",
  ),
  ("_ZL12DiagArray112", "DiagArray112", "DiagArray112", "DiagArray112"),
  (
    "_ZNK4llvm3sys4Path13isRegularFileEv", "llvm::sys::Path::isRegularFile() const",
    "llvm::sys::Path::isRegularFile", "llvm::sys::Path::isRegularFile() const",
  ),
  (
    "_ZN4llvm10BasicBlock9setParentEPNS_8FunctionE", "llvm::BasicBlock::setParent(llvm::Function*)",
    "llvm::BasicBlock::setParent", "llvm::BasicBlock::setParent(llvm::Function*)",
  ),
  (
    "_ZN5clang18ObjCObjectTypeImpl7ProfileERN4llvm16FoldingSetNodeIDENS_8QualTypeEPKPNS_16ObjCProtocolDeclEj",
    "clang::ObjCObjectTypeImpl::Profile(llvm::FoldingSetNodeID&, clang::QualType, clang::ObjCProtocolDecl* const*, unsigned int)",
    "clang::ObjCObjectTypeImpl::Profile", "clang::ObjCObjectTypeImpl::Profile(llvm::FoldingSetNodeID&, clang::QualType, clang::ObjCProtocolDecl* const*, unsigned int)",
  ),
  (
    "_ZN5clang7CodeGen15CodeGenFunction18GenerateObjCMethodEPKNS_14ObjCMethodDeclE",
    "clang::CodeGen::CodeGenFunction::GenerateObjCMethod(clang::ObjCMethodDecl const*)",
    "clang::CodeGen::CodeGenFunction::GenerateObjCMethod", "clang::CodeGen::CodeGenFunction::GenerateObjCMethod(clang::ObjCMethodDecl const*)",
  ),
  (
    "_ZNK4llvm19TargetFrameLowering20hasReservedCallFrameERKNS_15MachineFunctionE",
    "llvm::TargetFrameLowering::hasReservedCallFrame(llvm::MachineFunction const&) const",
    "llvm::TargetFrameLowering::hasReservedCallFrame", "llvm::TargetFrameLowering::hasReservedCallFrame(llvm::MachineFunction const&) const",
  ),
  (
    "_ZNK4llvm12MCSectionELF20PrintSwitchToSectionERKNS_9MCAsmInfoERNS_11raw_ostreamE",
    "llvm::MCSectionELF::PrintSwitchToSection(llvm::MCAsmInfo const&, llvm::raw_ostream&) const",
    "llvm::MCSectionELF::PrintSwitchToSection", "llvm::MCSectionELF::PrintSwitchToSection(llvm::MCAsmInfo const&, llvm::raw_ostream&) const",
  ),
  (
    "_ZN5clang6Parser31HandleMemberFunctionDefaultArgsERNS_10DeclaratorEPNS_4DeclE",
    "clang::Parser::HandleMemberFunctionDefaultArgs(clang::Declarator&, clang::Decl*)",
    "clang::Parser::HandleMemberFunctionDefaultArgs", "clang::Parser::HandleMemberFunctionDefaultArgs(clang::Declarator&, clang::Decl*)",
  ),
  ("_ZL9FeatureKV", "FeatureKV", "FeatureKV", "FeatureKV"),
  (
    "_ZN4llvm3X86L21GR64_NOSPSuperclassesE", "llvm::X86::GR64_NOSPSuperclasses",
    "llvm::X86::GR64_NOSPSuperclasses", "llvm::X86::GR64_NOSPSuperclasses",
  ),
  (
    "_ZN12_GLOBAL__N_115CGObjCCommonMac16GetMethodVarTypeEPKN5clang9FieldDeclE",
    "(anonymous namespace)::CGObjCCommonMac::GetMethodVarType(clang::FieldDecl const*)",
    "(anonymous namespace)::CGObjCCommonMac::GetMethodVarType", "(anonymous namespace)::CGObjCCommonMac::GetMethodVarType(clang::FieldDecl const*)",
  ),
  (
    "_ZN5clang13ObjCClassDeclD1Ev", "clang::ObjCClassDecl::~ObjCClassDecl()", "clang::ObjCClassDecl::~ObjCClassDecl",
    "clang::ObjCClassDecl::~ObjCClassDecl()",
  ),
  (
    "_ZN12_GLOBAL__N_113NoProfileInfo2IDE", "(anonymous namespace)::NoProfileInfo::ID",
    "(anonymous namespace)::NoProfileInfo::ID", "(anonymous namespace)::NoProfileInfo::ID",
  ),
  (
    "_ZN4llvm26getOrEnforceKnownAlignmentEPNS_5ValueEjPKNS_10DataLayoutE", "llvm::getOrEnforceKnownAlignment(llvm::Value*, unsigned int, llvm::DataLayout const*)",
    "llvm::getOrEnforceKnownAlignment", "llvm::getOrEnforceKnownAlignment(llvm::Value*, unsigned int, llvm::DataLayout const*)",
  ),
  (
    "_ZN12_GLOBAL__N_111ARMAsmLexerD1Ev", "(anonymous namespace)::ARMAsmLexer::~ARMAsmLexer()",
    "(anonymous namespace)::ARMAsmLexer::~ARMAsmLexer", "(anonymous namespace)::ARMAsmLexer::~ARMAsmLexer()",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L13R10W_OverlapsE", "llvm::(anonymous namespace)::R10W_Overlaps",
    "llvm::(anonymous namespace)::R10W_Overlaps", "llvm::(anonymous namespace)::R10W_Overlaps",
  ),
  (
    "_ZTV16ImageLoaderMachO", "vtable for ImageLoaderMachO", "vtable for ImageLoaderMachO",
    "vtable for ImageLoaderMachO",
  ),
  (
    "_ZN4llvm3ARML11ARM_rGPR_AOE", "llvm::ARM::ARM_rGPR_AO", "llvm::ARM::ARM_rGPR_AO",
    "llvm::ARM::ARM_rGPR_AO",
  ),
  ("_ZL9EnablePRE", "EnablePRE", "EnablePRE", "EnablePRE"),
  ("PVFvRmOE", "PVFvRmOE", "PVFvRmOE", "void (*)(unsigned long&) volatile &&"),
  (
    "_ZN4llvm3ARML12THUMB_GPR_AOE", "llvm::ARM::THUMB_GPR_AO", "llvm::ARM::THUMB_GPR_AO",
    "llvm::ARM::THUMB_GPR_AO",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L3DPRE", "llvm::(anonymous namespace)::DPR", "llvm::(anonymous namespace)::DPR",
    "llvm::(anonymous namespace)::DPR",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L3SPRE", "llvm::(anonymous namespace)::SPR", "llvm::(anonymous namespace)::SPR",
    "llvm::(anonymous namespace)::SPR",
  ),
  ("_ZL9NumGVNPRE", "NumGVNPRE", "NumGVNPRE", "NumGVNPRE"),
  (
    "_Z1pIJicfEEiM1SVKDwDpT_EFivOE", "int p<int, char, float>(int (S::*)() const volatile && throw(int, char, float))",
    "p<int, char, float>", "int p<int, char, float>(int (S::*)() const volatile && throw(int, char, float))",
  ),
  (
    "_ZNK4llvm16DIGlobalVariable6VerifyEv", "llvm::DIGlobalVariable::Verify() const",
    "llvm::DIGlobalVariable::Verify", "llvm::DIGlobalVariable::Verify() const",
  ),
  (
    "_ZNK4llvm17ShuffleVectorInst12getMaskValueEj", "llvm::ShuffleVectorInst::getMaskValue(unsigned int) const",
    "llvm::ShuffleVectorInst::getMaskValue", "llvm::ShuffleVectorInst::getMaskValue(unsigned int) const",
  ),
  (
    "_ZNK4llvm10AsmPrinter17getCurrentSectionEv", "llvm::AsmPrinter::getCurrentSection() const",
    "llvm::AsmPrinter::getCurrentSection", "llvm::AsmPrinter::getCurrentSection() const",
  ),
  (
    "_ZNK4llvm16SelectionDAGISel18CheckNodePredicateEPNS_6SDNodeEj", "llvm::SelectionDAGISel::CheckNodePredicate(llvm::SDNode*, unsigned int) const",
    "llvm::SelectionDAGISel::CheckNodePredicate", "llvm::SelectionDAGISel::CheckNodePredicate(llvm::SDNode*, unsigned int) const",
  ),
  (
    "_ZNK4llvm10UnwindInst10clone_implEv", "llvm::UnwindInst::clone_impl() const",
    "llvm::UnwindInst::clone_impl", "llvm::UnwindInst::clone_impl() const",
  ),
  (
    "_ZNK4llvm15DomTreeNodeBaseINS_10BasicBlockEE14getNumChildrenEv", "llvm::DomTreeNodeBase<llvm::BasicBlock>::getNumChildren() const",
    "llvm::DomTreeNodeBase<llvm::BasicBlock>::getNumChildren", "llvm::DomTreeNodeBase<llvm::BasicBlock>::getNumChildren() const",
  ),
  (
    "_ZNK4llvm8Function15hasAddressTakenEPPKNS_4UserE", "llvm::Function::hasAddressTaken(llvm::User const**) const",
    "llvm::Function::hasAddressTaken", "llvm::Function::hasAddressTaken(llvm::User const**) const",
  ),
  (
    "_ZNK4llvm19FoldingSetNodeIDRef11ComputeHashEv", "llvm::FoldingSetNodeIDRef::ComputeHash() const",
    "llvm::FoldingSetNodeIDRef::ComputeHash", "llvm::FoldingSetNodeIDRef::ComputeHash() const",
  ),
  (
    "_Z8printValddRN4llvm11raw_ostreamE", "printVal(double, double, llvm::raw_ostream&)",
    "printVal", "printVal(double, double, llvm::raw_ostream&)",
  ),
  (
    "_ZN4llvm7PHINode19removeIncomingValueEjb", "llvm::PHINode::removeIncomingValue(unsigned int, bool)",
    "llvm::PHINode::removeIncomingValue", "llvm::PHINode::removeIncomingValue(unsigned int, bool)",
  ),
  (
    "_ZN4llvm23SmallVectorTemplateBaseIN5clang7APValueELb0EE4growEm", "llvm::SmallVectorTemplateBase<clang::APValue, false>::grow(unsigned long)",
    "llvm::SmallVectorTemplateBase<clang::APValue, false>::grow", "llvm::SmallVectorTemplateBase<clang::APValue, false>::grow(unsigned long)",
  ),
  ("_ZL12NumGVNBlocks", "NumGVNBlocks", "NumGVNBlocks", "NumGVNBlocks"),
  (
    "_ZTVN5clang30UninitializedValues_ValueTypes14AnalysisDataTyE", "vtable for clang::UninitializedValues_ValueTypes::AnalysisDataTy",
    "vtable for clang::UninitializedValues_ValueTypes::AnalysisDataTy", "vtable for clang::UninitializedValues_ValueTypes::AnalysisDataTy",
  ),
  (
    "_ZTVN4llvm18SelectConstantExprE", "vtable for llvm::SelectConstantExpr", "vtable for llvm::SelectConstantExpr",
    "vtable for llvm::SelectConstantExpr",
  ),
  (
    "_Z11WriteMDNodePKN4llvm6MDNodeERKNS_15ValueEnumeratorERNS_15BitstreamWriterERNS_11SmallVectorIyLj64EEE",
    "WriteMDNode(llvm::MDNode const*, llvm::ValueEnumerator const&, llvm::BitstreamWriter&, llvm::SmallVector<unsigned long long, 64u>&)",
    "WriteMDNode", "WriteMDNode(llvm::MDNode const*, llvm::ValueEnumerator const&, llvm::BitstreamWriter&, llvm::SmallVector<unsigned long long, 64u>&)",
  ),
  (
    "_ZN5clang13ASTStmtWriter19VisitCStyleCastExprEPNS_14CStyleCastExprE", "clang::ASTStmtWriter::VisitCStyleCastExpr(clang::CStyleCastExpr*)",
    "clang::ASTStmtWriter::VisitCStyleCastExpr", "clang::ASTStmtWriter::VisitCStyleCastExpr(clang::CStyleCastExpr*)",
  ),
  (
    "_ZN4llvm20FunctionLoweringInfo5clearEv", "llvm::FunctionLoweringInfo::clear()",
    "llvm::FunctionLoweringInfo::clear", "llvm::FunctionLoweringInfo::clear()",
  ),
  (
    "_ZN4llvm17initializeDAHPassERNS_12PassRegistryE", "llvm::initializeDAHPass(llvm::PassRegistry&)",
    "llvm::initializeDAHPass", "llvm::initializeDAHPass(llvm::PassRegistry&)",
  ),
  (
    "_ZN4llvm3ARML19rGPRSuperRegClassesE", "llvm::ARM::rGPRSuperRegClasses", "llvm::ARM::rGPRSuperRegClasses",
    "llvm::ARM::rGPRSuperRegClasses",
  ),
  (
    "_ZN4llvm15AliasSetTracker14removeAliasSetEPNS_8AliasSetE", "llvm::AliasSetTracker::removeAliasSet(llvm::AliasSet*)",
    "llvm::AliasSetTracker::removeAliasSet", "llvm::AliasSetTracker::removeAliasSet(llvm::AliasSet*)",
  ),
  (
    "_ZN5clang4ento9BugReport12NodeResolverD1Ev", "clang::ento::BugReport::NodeResolver::~NodeResolver()",
    "clang::ento::BugReport::NodeResolver::~NodeResolver", "clang::ento::BugReport::NodeResolver::~NodeResolver()",
  ),
  (
    "_ZN5clang12LangStandard22getLangStandardForNameEN4llvm9StringRefE", "clang::LangStandard::getLangStandardForName(llvm::StringRef)",
    "clang::LangStandard::getLangStandardForName", "clang::LangStandard::getLangStandardForName(llvm::StringRef)",
  ),
  (
    "_ZN5clang12Preprocessor19HandlePragmaMessageERNS_5TokenE", "clang::Preprocessor::HandlePragmaMessage(clang::Token&)",
    "clang::Preprocessor::HandlePragmaMessage", "clang::Preprocessor::HandlePragmaMessage(clang::Token&)",
  ),
  (
    "_ZN4llvm19SelectionDAGBuilder10visitFPExtERKNS_4UserE", "llvm::SelectionDAGBuilder::visitFPExt(llvm::User const&)",
    "llvm::SelectionDAGBuilder::visitFPExt", "llvm::SelectionDAGBuilder::visitFPExt(llvm::User const&)",
  ),
  (
    "_ZN5clang7CodeGen12CodeGenTypes15getFunctionInfoEPKNS_17CXXDestructorDeclENS_11CXXDtorTypeE",
    "clang::CodeGen::CodeGenTypes::getFunctionInfo(clang::CXXDestructorDecl const*, clang::CXXDtorType)",
    "clang::CodeGen::CodeGenTypes::getFunctionInfo", "clang::CodeGen::CodeGenTypes::getFunctionInfo(clang::CXXDestructorDecl const*, clang::CXXDtorType)",
  ),
  (
    "_ZN12_GLOBAL__N_113CallLocalDtorD0Ev", "(anonymous namespace)::CallLocalDtor::~CallLocalDtor()",
    "(anonymous namespace)::CallLocalDtor::~CallLocalDtor", "(anonymous namespace)::CallLocalDtor::~CallLocalDtor()",
  ),
  (
    "_ZN12_GLOBAL__N_117FreeBSDTargetInfoINS_15PPC64TargetInfoEED1Ev", "(anonymous namespace)::FreeBSDTargetInfo<(anonymous namespace)::PPC64TargetInfo>::~FreeBSDTargetInfo()",
    "(anonymous namespace)::FreeBSDTargetInfo<(anonymous namespace)::PPC64TargetInfo>::~FreeBSDTargetInfo",
    "(anonymous namespace)::FreeBSDTargetInfo<(anonymous namespace)::PPC64TargetInfo>::~FreeBSDTargetInfo()",
  ),
  (
    "_ZTVN12_GLOBAL__N_113CallArrayDtorE", "vtable for (anonymous namespace)::CallArrayDtor",
    "vtable for (anonymous namespace)::CallArrayDtor", "vtable for (anonymous namespace)::CallArrayDtor",
  ),
  (
    "_ZN12_GLOBAL__N_17SROA_DT2IDE", "(anonymous namespace)::SROA_DT::ID", "(anonymous namespace)::SROA_DT::ID",
    "(anonymous namespace)::SROA_DT::ID",
  ),
  (
    "_ZN5test62f2IiEEvDTcvT_dtdtL_ZNS_1zEE2ub1iE", "void test6::f2<int>(decltype((int)(test6::z.ub.i)))",
    "test6::f2<int>", "void test6::f2<int>(decltype((int)(test6::z.ub.i)))",
  ),
  (
    "_ZN5test43tf1INS_1XEEEvDTnw_T_piLi1EEE", "void test4::tf1<test4::X>(decltype(new test4::X(1)))",
    "test4::tf1<test4::X>", "void test4::tf1<test4::X>(decltype(new test4::X(1)))",
  ),
  (
    "_ZN5test62f8IiEEvDTcvT_dtptL_ZNS_2zpEE4uuss1iE", "void test6::f8<int>(decltype((int)(test6::zp->uuss.i)))",
    "test6::f8<int>", "void test6::f8<int>(decltype((int)(test6::zp->uuss.i)))",
  ),
  (
    "_Z1fIJicdEEPFvDpT_EPFvDpRPS0_ES8_S1_DpS4_S6_", "void (*f<int, char, double>(void (*)(int*&, char*&, double*&), void (*)(int*&, char*&, double*&), int, char, double, int*, char*, double*, int*&, char*&, double*&))(int, char, double)",
    "f<int, char, double>", "void (*f<int, char, double>(void (*)(int*&, char*&, double*&), void (*)(int*&, char*&, double*&), int, char, double, int*, char*, double*, int*&, char*&, double*&))(int, char, double)",
  ),
  ("_Z2f2IJiEEvDpT_", "void f2<int>(int)", "f2<int>", "void f2<int>(int)"),
  (
    "_Z2f2IJifEEvDpT_", "void f2<int, float>(int, float)", "f2<int, float>", "void f2<int, float>(int, float)",
  ),
  (
    "_Z2f5IiJifdEE8identityIFT_DpT0_EEv", "identity<int (int, float, double)> f5<int, int, float, double>()",
    "f5<int, int, float, double>", "identity<int (int, float, double)> f5<int, int, float, double>()",
  ),
  (
    "_Z2f7IJ8identity13add_referenceEE14template_tupleIJDpT_EEv", "template_tuple<identity, add_reference> f7<identity, add_reference>()",
    "f7<identity, add_reference>", "template_tuple<identity, add_reference> f7<identity, add_reference>()",
  ),
  (
    "_ZN1SIJifcEE1fIJdjEEEiDp4MerpIJifcT_EE", "int S<int, float, char>::f<double, unsigned int>(Merp<int, float, char, double>, Merp<int, float, char, unsigned int>)",
    "S<int, float, char>::f<double, unsigned int>", "int S<int, float, char>::f<double, unsigned int>(Merp<int, float, char, double>, Merp<int, float, char, unsigned int>)",
  ),
  ("_Z2f2IJEEvDpT_", "void f2<>()", "f2<>", "void f2<>()"),
  (
    "_Z1gIJfEEvPDwDpT_EFivE", "void g<float>(int (*)() throw(float))", "g<float>",
    "void g<float>(int (*)() throw(float))",
  ),
  ("_ZL11nNamespaces", "nNamespaces", "nNamespaces", "nNamespaces"),
  (
    "_ZN5clang13NamespaceDeclD0Ev", "clang::NamespaceDecl::~NamespaceDecl()", "clang::NamespaceDecl::~NamespaceDecl",
    "clang::NamespaceDecl::~NamespaceDecl()",
  ),
  ("_ZL10spillerOpt", "spillerOpt", "spillerOpt", "spillerOpt"),
  (
    "_ZN5clang24TemplateDeclInstantiator23VisitNamespaceAliasDeclEPNS_18NamespaceAliasDeclE",
    "clang::TemplateDeclInstantiator::VisitNamespaceAliasDecl(clang::NamespaceAliasDecl*)",
    "clang::TemplateDeclInstantiator::VisitNamespaceAliasDecl", "clang::TemplateDeclInstantiator::VisitNamespaceAliasDecl(clang::NamespaceAliasDecl*)",
  ),
  (
    "_ZN12_GLOBAL__N_115ASTNodeImporter18VisitNamespaceDeclEPN5clang13NamespaceDeclE",
    "(anonymous namespace)::ASTNodeImporter::VisitNamespaceDecl(clang::NamespaceDecl*)",
    "(anonymous namespace)::ASTNodeImporter::VisitNamespaceDecl", "(anonymous namespace)::ASTNodeImporter::VisitNamespaceDecl(clang::NamespaceDecl*)",
  ),
  (
    "_ZN5clang15PragmaNamespace14getIfNamespaceEv", "clang::PragmaNamespace::getIfNamespace()",
    "clang::PragmaNamespace::getIfNamespace", "clang::PragmaNamespace::getIfNamespace()",
  ),
  (
    "_ZN5clang11DeclContext28getEnclosingNamespaceContextEv", "clang::DeclContext::getEnclosingNamespaceContext()",
    "clang::DeclContext::getEnclosingNamespaceContext", "clang::DeclContext::getEnclosingNamespaceContext()",
  ),
  (
    "_ZN5clang15PragmaNamespace9AddPragmaEPNS_13PragmaHandlerE", "clang::PragmaNamespace::AddPragma(clang::PragmaHandler*)",
    "clang::PragmaNamespace::AddPragma", "clang::PragmaNamespace::AddPragma(clang::PragmaHandler*)",
  ),
  ("_Z2f1IJEEvv", "void f1<>()", "f1<>", "void f1<>()"),
  (
    "_ZNK5clang6driver17CommaJoinedOption6acceptERKNS0_7ArgListERj", "clang::driver::CommaJoinedOption::accept(clang::driver::ArgList const&, unsigned int&) const",
    "clang::driver::CommaJoinedOption::accept", "clang::driver::CommaJoinedOption::accept(clang::driver::ArgList const&, unsigned int&) const",
  ),
  (
    "_ZNK4llvm17X86TargetLowering20getJumpTableEncodingEv", "llvm::X86TargetLowering::getJumpTableEncoding() const",
    "llvm::X86TargetLowering::getJumpTableEncoding", "llvm::X86TargetLowering::getJumpTableEncoding() const",
  ),
  (
    "_ZN12_GLOBAL__N_17EmitterIN4llvm14JITCodeEmitterEE16emitMemModRMByteERKNS1_12MachineInstrEjjl",
    "(anonymous namespace)::Emitter<llvm::JITCodeEmitter>::emitMemModRMByte(llvm::MachineInstr const&, unsigned int, unsigned int, long)",
    "(anonymous namespace)::Emitter<llvm::JITCodeEmitter>::emitMemModRMByte", "(anonymous namespace)::Emitter<llvm::JITCodeEmitter>::emitMemModRMByte(llvm::MachineInstr const&, unsigned int, unsigned int, long)",
  ),
  (
    "_ZN4llvm13TargetMachine10getJITInfoEv", "llvm::TargetMachine::getJITInfo()",
    "llvm::TargetMachine::getJITInfo", "llvm::TargetMachine::getJITInfo()",
  ),
  (
    "_ZN4llvm10ARMJITInfoD0Ev", "llvm::ARMJITInfo::~ARMJITInfo()", "llvm::ARMJITInfo::~ARMJITInfo",
    "llvm::ARMJITInfo::~ARMJITInfo()",
  ),
  (
    "_ZN4llvm12LiveInterval19ComputeJoinedWeightERKS0_", "llvm::LiveInterval::ComputeJoinedWeight(llvm::LiveInterval const&)",
    "llvm::LiveInterval::ComputeJoinedWeight", "llvm::LiveInterval::ComputeJoinedWeight(llvm::LiveInterval const&)",
  ),
  (
    "_ZNK5clang6driver10toolchains9DragonFly10SelectToolERKNS0_11CompilationERKNS0_9JobActionE",
    "clang::driver::toolchains::DragonFly::SelectTool(clang::driver::Compilation const&, clang::driver::JobAction const&) const",
    "clang::driver::toolchains::DragonFly::SelectTool", "clang::driver::toolchains::DragonFly::SelectTool(clang::driver::Compilation const&, clang::driver::JobAction const&) const",
  ),
  (
    "_ZN4llvm3X86L20GR64_TCSubRegClassesE", "llvm::X86::GR64_TCSubRegClasses", "llvm::X86::GR64_TCSubRegClasses",
    "llvm::X86::GR64_TCSubRegClasses",
  ),
  ("_ZNR1X1fEv", "X::f() &", "X::f", "X::f() &"),
  (
    "_Z1fIXtl1Xdi1adi1bdxLi3ELi1EEEE", "f<X{.a.b[3] = 1}>", "f<X{.a.b[3] = 1}>",
    "f<X{.a.b[3] = 1}>",
  ),
  (
    "_ZN4llvm3X8614GR32_ABCDClassC1Ev", "llvm::X86::GR32_ABCDClass::GR32_ABCDClass()",
    "llvm::X86::GR32_ABCDClass::GR32_ABCDClass", "llvm::X86::GR32_ABCDClass::GR32_ABCDClass()",
  ),
  (
    "_ZN12_GLOBAL__N_118AuroraUXTargetInfoINS_16X86_32TargetInfoEED1Ev", "(anonymous namespace)::AuroraUXTargetInfo<(anonymous namespace)::X86_32TargetInfo>::~AuroraUXTargetInfo()",
    "(anonymous namespace)::AuroraUXTargetInfo<(anonymous namespace)::X86_32TargetInfo>::~AuroraUXTargetInfo",
    "(anonymous namespace)::AuroraUXTargetInfo<(anonymous namespace)::X86_32TargetInfo>::~AuroraUXTargetInfo()",
  ),
  (
    "_ZN4llvm19X86_32TargetMachineD2Ev", "llvm::X86_32TargetMachine::~X86_32TargetMachine()",
    "llvm::X86_32TargetMachine::~X86_32TargetMachine", "llvm::X86_32TargetMachine::~X86_32TargetMachine()",
  ),
  (
    "_ZTVN12_GLOBAL__N_113ASTPrinterXMLE", "vtable for (anonymous namespace)::ASTPrinterXML",
    "vtable for (anonymous namespace)::ASTPrinterXML", "vtable for (anonymous namespace)::ASTPrinterXML",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L14EAX_SubRegsSetE", "llvm::(anonymous namespace)::EAX_SubRegsSet",
    "llvm::(anonymous namespace)::EAX_SubRegsSet", "llvm::(anonymous namespace)::EAX_SubRegsSet",
  ),
  (
    "_ZN5clang12LookupResultD2Ev", "clang::LookupResult::~LookupResult()", "clang::LookupResult::~LookupResult",
    "clang::LookupResult::~LookupResult()",
  ),
  (
    "_ZN11ImageLoader21fgNextPIEDylibAddressE", "ImageLoader::fgNextPIEDylibAddress",
    "ImageLoader::fgNextPIEDylibAddress", "ImageLoader::fgNextPIEDylibAddress",
  ),
  (
    "_ZN4llvm26createTDRRListDAGSchedulerEPNS_16SelectionDAGISelENS_10CodeGenOpt5LevelE",
    "llvm::createTDRRListDAGScheduler(llvm::SelectionDAGISel*, llvm::CodeGenOpt::Level)",
    "llvm::createTDRRListDAGScheduler", "llvm::createTDRRListDAGScheduler(llvm::SelectionDAGISel*, llvm::CodeGenOpt::Level)",
  ),
  (
    "_ZN4llvm2cl3optIjLb0ENS0_6parserIjEEE4doneEv", "llvm::cl::opt<unsigned int, false, llvm::cl::parser<unsigned int>>::done()",
    "llvm::cl::opt<unsigned int, false, llvm::cl::parser<unsigned int>>::done", "llvm::cl::opt<unsigned int, false, llvm::cl::parser<unsigned int>>::done()",
  ),
  (
    "_ZNK4llvm18ThumbTargetMachine17getTargetLoweringEv", "llvm::ThumbTargetMachine::getTargetLowering() const",
    "llvm::ThumbTargetMachine::getTargetLowering", "llvm::ThumbTargetMachine::getTargetLowering() const",
  ),
  (
    "_ZN23ImageLoaderMachOClassic18mapSegmentsClassicEiyyyRKN11ImageLoader11LinkContextE",
    "ImageLoaderMachOClassic::mapSegmentsClassic(int, unsigned long long, unsigned long long, unsigned long long, ImageLoader::LinkContext const&)",
    "ImageLoaderMachOClassic::mapSegmentsClassic", "ImageLoaderMachOClassic::mapSegmentsClassic(int, unsigned long long, unsigned long long, unsigned long long, ImageLoader::LinkContext const&)",
  ),
  (
    "_ZN4llvm20LoadAndStorePromoterC1ERKNS_15SmallVectorImplIPNS_11InstructionEEERNS_10SSAUpdaterENS_9StringRefE",
    "llvm::LoadAndStorePromoter::LoadAndStorePromoter(llvm::SmallVectorImpl<llvm::Instruction*> const&, llvm::SSAUpdater&, llvm::StringRef)",
    "llvm::LoadAndStorePromoter::LoadAndStorePromoter", "llvm::LoadAndStorePromoter::LoadAndStorePromoter(llvm::SmallVectorImpl<llvm::Instruction*> const&, llvm::SSAUpdater&, llvm::StringRef)",
  ),
  (
    "_ZN4llvm20LatencyPriorityQueueD1Ev", "llvm::LatencyPriorityQueue::~LatencyPriorityQueue()",
    "llvm::LatencyPriorityQueue::~LatencyPriorityQueue", "llvm::LatencyPriorityQueue::~LatencyPriorityQueue()",
  ),
  (
    "_Z1fIDnLDn0EEvv", "void f<std::nullptr_t, nullptr>()", "f<std::nullptr_t, nullptr>",
    "void f<std::nullptr_t, nullptr>()",
  ),
  (
    "_Z1fIiEDTeqfp_LDnEEPT_", "decltype(fp == nullptr) f<int>(int*)", "f<int>", "decltype(fp == nullptr) f<int>(int*)",
  ),
  (
    "_Z1fIiEDTeqfp1_LDnEEicPT_", "decltype(fp1 == nullptr) f<int>(int, char, int*)",
    "f<int>", "decltype(fp1 == nullptr) f<int>(int, char, int*)",
  ),
  (
    "_Z1fIXtl1BcvPiplcvPcadL_Z7derivedELl16EEEEvv", "void f<B{(int*)((char*)(&derived) + 16l)}>()",
    "f<B{(int*)((char*)(&derived) + 16l)}>", "void f<B{(int*)((char*)(&derived) + 16l)}>()",
  ),
  (
    "_ZN5test62f5IiEEvDTcvT_dtptL_ZNS_2zpEE2ua1iE", "void test6::f5<int>(decltype((int)(test6::zp->ua.i)))",
    "test6::f5<int>", "void test6::f5<int>(decltype((int)(test6::zp->ua.i)))",
  ),
  (
    "_ZN5Casts6const_IiXadL_ZNS_1iEEEEEvPN9enable_ifIXleLi0EszccPT_T0_EvE4typeE",
    "void Casts::const_<int, &Casts::i>(enable_if<0 <= sizeof (const_cast<int*>(&Casts::i)), void>::type*)",
    "Casts::const_<int, &Casts::i>", "void Casts::const_<int, &Casts::i>(enable_if<0 <= sizeof (const_cast<int*>(&Casts::i)), void>::type*)",
  ),
  (
    "_Z1fIXtl1BadsoiL_Z6nestedE_EEEEvv", "void f<B{&nested.<int at offset 0>}>()",
    "f<B{&nested.<int at offset 0>}>", "void f<B{&nested.<int at offset 0>}>()",
  ),
  (
    "_ZN5test62f1IiEEvDTcvT_dtdtL_ZNS_1zEE2ua1iE", "void test6::f1<int>(decltype((int)(test6::z.ua.i)))",
    "test6::f1<int>", "void test6::f1<int>(decltype((int)(test6::z.ua.i)))",
  ),
  (
    "_Z1fIXtl2BRsoiL_Z7derivedE4EEEEvv", "void f<BR{derived.<int at offset 4>}>()",
    "f<BR{derived.<int at offset 4>}>", "void f<BR{derived.<int at offset 4>}>()",
  ),
  (
    "_ZN5test62f6IiEEvDTcvT_dtptL_ZNS_2zpEE2ub1iE", "void test6::f6<int>(decltype((int)(test6::zp->ub.i)))",
    "test6::f6<int>", "void test6::f6<int>(decltype((int)(test6::zp->ub.i)))",
  ),
  (
    "_ZN5test42f1ENS_2t1IXadL_Z8test4_f0EEEE", "test4::f1(test4::t1<&test4_f0>)",
    "test4::f1", "test4::f1(test4::t1<&test4_f0>)",
  ),
  (
    "_ZcvCiIJEEDvT__FFFFT_vT_v", "_ZcvCiIJEEDvT__FFFFT_vT_v", "operator int complex<>",
    "_ZcvCiIJEEDvT__FFFFT_vT_v",
  ),
  (
    "_Z13JVTLib_103270ILi1EEvPsDv2_xS1_", "void JVTLib_103270<1>(short*, long long vector[2], long long vector[2])",
    "JVTLib_103270<1>", "void JVTLib_103270<1>(short*, long long vector[2], long long vector[2])",
  ),
  (
    "_ZTVN5clang18UsingDirectiveDeclE", "vtable for clang::UsingDirectiveDecl", "vtable for clang::UsingDirectiveDecl",
    "vtable for clang::UsingDirectiveDecl",
  ),
  ("_ZL11DiagArray43", "DiagArray43", "DiagArray43", "DiagArray43"),
  (
    "_ZN5clang13DiagnosticIDs27isBuiltinWarningOrExtensionEj", "clang::DiagnosticIDs::isBuiltinWarningOrExtension(unsigned int)",
    "clang::DiagnosticIDs::isBuiltinWarningOrExtension", "clang::DiagnosticIDs::isBuiltinWarningOrExtension(unsigned int)",
  ),
  ("_ZL11DiagArray86", "DiagArray86", "DiagArray86", "DiagArray86"),
  ("_ZL12DiagArray145", "DiagArray145", "DiagArray145", "DiagArray145"),
  (
    "_ZN12_GLOBAL__N_121PathDiagnosticBuilder15getNodeResolverEv", "(anonymous namespace)::PathDiagnosticBuilder::getNodeResolver()",
    "(anonymous namespace)::PathDiagnosticBuilder::getNodeResolver", "(anonymous namespace)::PathDiagnosticBuilder::getNodeResolver()",
  ),
  (
    "_ZN12_GLOBAL__N_122UninitValsDiagReporterD0Ev", "(anonymous namespace)::UninitValsDiagReporter::~UninitValsDiagReporter()",
    "(anonymous namespace)::UninitValsDiagReporter::~UninitValsDiagReporter", "(anonymous namespace)::UninitValsDiagReporter::~UninitValsDiagReporter()",
  ),
  (
    "_Z10DumpNodesrRN4llvm11raw_ostreamEPKNS_6SDNodeEjPKNS_12SelectionDAGERNS_11SmallPtrSetIS4_Lj128EEE",
    "DumpNodesr(llvm::raw_ostream&, llvm::SDNode const*, unsigned int, llvm::SelectionDAG const*, llvm::SmallPtrSet<llvm::SDNode const*, 128u>&)",
    "DumpNodesr", "DumpNodesr(llvm::raw_ostream&, llvm::SDNode const*, unsigned int, llvm::SelectionDAG const*, llvm::SmallPtrSet<llvm::SDNode const*, 128u>&)",
  ),
  (
    "_ZN4llvm7APFloatC1EDF16_", "llvm::APFloat::APFloat(_Float16)", "llvm::APFloat::APFloat",
    "llvm::APFloat::APFloat(_Float16)",
  ),
  (
    "_ZN4llvm7APFloatC2EDF16_", "llvm::APFloat::APFloat(_Float16)", "llvm::APFloat::APFloat",
    "llvm::APFloat::APFloat(_Float16)",
  ),
  (
    "_Z10float16addDF16_DF16_", "float16add(_Float16, _Float16)", "float16add", "float16add(_Float16, _Float16)",
  ),
  (
    "_ZN12_GLOBAL__N_19CGObjCGNU13EmitThrowStmtERN5clang7CodeGen15CodeGenFunctionERKNS1_15ObjCAtThrowStmtE",
    "(anonymous namespace)::CGObjCGNU::EmitThrowStmt(clang::CodeGen::CodeGenFunction&, clang::ObjCAtThrowStmt const&)",
    "(anonymous namespace)::CGObjCGNU::EmitThrowStmt", "(anonymous namespace)::CGObjCGNU::EmitThrowStmt(clang::CodeGen::CodeGenFunction&, clang::ObjCAtThrowStmt const&)",
  ),
  (
    "_ZN12_GLOBAL__N_19CGObjCGNU20GenerateProtocolListERKN4llvm15SmallVectorImplISsEE",
    "(anonymous namespace)::CGObjCGNU::GenerateProtocolList(llvm::SmallVectorImpl<std::string> const&)",
    "(anonymous namespace)::CGObjCGNU::GenerateProtocolList", "(anonymous namespace)::CGObjCGNU::GenerateProtocolList(llvm::SmallVectorImpl<std::string> const&)",
  ),
  (
    "_ZN12_GLOBAL__N_19CGObjCGNU22GenerateConstantStringEPKN5clang13StringLiteralE",
    "(anonymous namespace)::CGObjCGNU::GenerateConstantString(clang::StringLiteral const*)",
    "(anonymous namespace)::CGObjCGNU::GenerateConstantString", "(anonymous namespace)::CGObjCGNU::GenerateConstantString(clang::StringLiteral const*)",
  ),
  (
    "_ZN12_GLOBAL__N_19CGObjCGNU18EmitObjCWeakAssignERN5clang7CodeGen15CodeGenFunctionEPN4llvm5ValueES7_",
    "(anonymous namespace)::CGObjCGNU::EmitObjCWeakAssign(clang::CodeGen::CodeGenFunction&, llvm::Value*, llvm::Value*)",
    "(anonymous namespace)::CGObjCGNU::EmitObjCWeakAssign", "(anonymous namespace)::CGObjCGNU::EmitObjCWeakAssign(clang::CodeGen::CodeGenFunction&, llvm::Value*, llvm::Value*)",
  ),
  (
    "_ZN12_GLOBAL__N_19CGObjCGNU13GenerateClassEPKN5clang22ObjCImplementationDeclE",
    "(anonymous namespace)::CGObjCGNU::GenerateClass(clang::ObjCImplementationDecl const*)",
    "(anonymous namespace)::CGObjCGNU::GenerateClass", "(anonymous namespace)::CGObjCGNU::GenerateClass(clang::ObjCImplementationDecl const*)",
  ),
  (
    "_Z1fPU3AS1KiS0_", "f(int const AS1*, int const AS1*)", "f", "f(int const AS1*, int const AS1*)",
  ),
  (
    "_ZN12_GLOBAL__N_19CGObjCGNU16EmitObjCWeakReadERN5clang7CodeGen15CodeGenFunctionEPN4llvm5ValueE",
    "(anonymous namespace)::CGObjCGNU::EmitObjCWeakRead(clang::CodeGen::CodeGenFunction&, llvm::Value*)",
    "(anonymous namespace)::CGObjCGNU::EmitObjCWeakRead", "(anonymous namespace)::CGObjCGNU::EmitObjCWeakRead(clang::CodeGen::CodeGenFunction&, llvm::Value*)",
  ),
  (
    "_ZN12_GLOBAL__N_19CGObjCGNU22GetPropertyGetFunctionEv", "(anonymous namespace)::CGObjCGNU::GetPropertyGetFunction()",
    "(anonymous namespace)::CGObjCGNU::GetPropertyGetFunction", "(anonymous namespace)::CGObjCGNU::GetPropertyGetFunction()",
  ),
  (
    "_Z2f5IiEvu14__remove_cvrefIT_E", "void f5<int>(__remove_cvref(int))", "f5<int>",
    "void f5<int>(__remove_cvref(int))",
  ),
  (
    "_Z2f5IPiEvu16__remove_pointerIT_E", "void f5<int*>(__remove_pointer(int*))",
    "f5<int*>", "void f5<int*>(__remove_pointer(int*))",
  ),
  ("_ZL10Lang_gnu9x", "Lang_gnu9x", "Lang_gnu9x", "Lang_gnu9x"),
  (
    "_Z2f5IiEvu22__add_lvalue_referenceIT_E", "void f5<int>(__add_lvalue_reference(int))",
    "f5<int>", "void f5<int>(__add_lvalue_reference(int))",
  ),
  (
    "_Z2f2IiEvDTu11__alignof__T_EE", "void f2<int>(decltype(__alignof__(int)))",
    "f2<int>", "void f2<int>(decltype(__alignof__(int)))",
  ),
  ("_Z1fu3fooS_", "f(foo, foo)", "f", "f(foo, foo)"),
  (
    "_Z15test_uuidofExprI9HasMemberEvDTu8__uuidofXsrT_6memberEEE", "void test_uuidofExpr<HasMember>(decltype(__uuidof(HasMember::member)))",
    "test_uuidofExpr<HasMember>", "void test_uuidofExpr<HasMember>(decltype(__uuidof(HasMember::member)))",
  ),
  (
    "_Z2f5IiEvu13__add_pointerIT_E", "void f5<int>(__add_pointer(int))", "f5<int>",
    "void f5<int>(__add_pointer(int))",
  ),
  (
    "_ZN5clang13ASTDeclWriter29VisitTemplateTemplateParmDeclEPNS_24TemplateTemplateParmDeclE",
    "clang::ASTDeclWriter::VisitTemplateTemplateParmDecl(clang::TemplateTemplateParmDecl*)",
    "clang::ASTDeclWriter::VisitTemplateTemplateParmDecl", "clang::ASTDeclWriter::VisitTemplateTemplateParmDecl(clang::TemplateTemplateParmDecl*)",
  ),
  (
    "_ZN5clang13QualifierInfo29setTemplateParameterListsInfoERNS_10ASTContextEjPPNS_21TemplateParameterListE",
    "clang::QualifierInfo::setTemplateParameterListsInfo(clang::ASTContext&, unsigned int, clang::TemplateParameterList**)",
    "clang::QualifierInfo::setTemplateParameterListsInfo", "clang::QualifierInfo::setTemplateParameterListsInfo(clang::ASTContext&, unsigned int, clang::TemplateParameterList**)",
  ),
  (
    "_ZN4llvm9DIFactory19CreateTemporaryTypeENS_6DIFileE", "llvm::DIFactory::CreateTemporaryType(llvm::DIFile)",
    "llvm::DIFactory::CreateTemporaryType", "llvm::DIFactory::CreateTemporaryType(llvm::DIFile)",
  ),
  (
    "_ZNK5clang32SubstNonTypeTemplateParmPackExpr15getArgumentPackEv", "clang::SubstNonTypeTemplateParmPackExpr::getArgumentPack() const",
    "clang::SubstNonTypeTemplateParmPackExpr::getArgumentPack", "clang::SubstNonTypeTemplateParmPackExpr::getArgumentPack() const",
  ),
  (
    "_ZN12_GLOBAL__N_114CXXNameMangler17mangleTemplateArgEPKN5clang9NamedDeclERKNS1_16TemplateArgumentE",
    "(anonymous namespace)::CXXNameMangler::mangleTemplateArg(clang::NamedDecl const*, clang::TemplateArgument const&)",
    "(anonymous namespace)::CXXNameMangler::mangleTemplateArg", "(anonymous namespace)::CXXNameMangler::mangleTemplateArg(clang::NamedDecl const*, clang::TemplateArgument const&)",
  ),
  (
    "_ZNK5clang23LocalInstantiationScope27getPartiallySubstitutedPackEPPKNS_16TemplateArgumentEPj",
    "clang::LocalInstantiationScope::getPartiallySubstitutedPack(clang::TemplateArgument const**, unsigned int*) const",
    "clang::LocalInstantiationScope::getPartiallySubstitutedPack", "clang::LocalInstantiationScope::getPartiallySubstitutedPack(clang::TemplateArgument const**, unsigned int*) const",
  ),
  (
    "_ZN4llvm15SmallVectorImplIN5clang19TemplateArgumentLocEE9push_backERKS2_", "llvm::SmallVectorImpl<clang::TemplateArgumentLoc>::push_back(clang::TemplateArgumentLoc const&)",
    "llvm::SmallVectorImpl<clang::TemplateArgumentLoc>::push_back", "llvm::SmallVectorImpl<clang::TemplateArgumentLoc>::push_back(clang::TemplateArgumentLoc const&)",
  ),
  (
    "_ZN5clang36SubstTemplateTemplateParmPackStorage7ProfileERN4llvm16FoldingSetNodeIDE",
    "clang::SubstTemplateTemplateParmPackStorage::Profile(llvm::FoldingSetNodeID&)",
    "clang::SubstTemplateTemplateParmPackStorage::Profile", "clang::SubstTemplateTemplateParmPackStorage::Profile(llvm::FoldingSetNodeID&)",
  ),
  (
    "_ZN12_GLOBAL__N_118CheckFormatHandler14DoneProcessingEv", "(anonymous namespace)::CheckFormatHandler::DoneProcessing()",
    "(anonymous namespace)::CheckFormatHandler::DoneProcessing", "(anonymous namespace)::CheckFormatHandler::DoneProcessing()",
  ),
  (
    "_ZN4llvm20MachineDominatorTreeC2Ev", "llvm::MachineDominatorTree::MachineDominatorTree()",
    "llvm::MachineDominatorTree::MachineDominatorTree", "llvm::MachineDominatorTree::MachineDominatorTree()",
  ),
  (
    "_ZN5clang6Parser16ParseDoStatementERNS_16ParsedAttributesE", "clang::Parser::ParseDoStatement(clang::ParsedAttributes&)",
    "clang::Parser::ParseDoStatement", "clang::Parser::ParseDoStatement(clang::ParsedAttributes&)",
  ),
  (
    "_ZN4llvm4Type14getDoublePtrTyERNS_11LLVMContextEj", "llvm::Type::getDoublePtrTy(llvm::LLVMContext&, unsigned int)",
    "llvm::Type::getDoublePtrTy", "llvm::Type::getDoublePtrTy(llvm::LLVMContext&, unsigned int)",
  ),
  (
    "_ZN4llvm17DominatorTreeBaseINS_10BasicBlockEE16updateDFSNumbersEv", "llvm::DominatorTreeBase<llvm::BasicBlock>::updateDFSNumbers()",
    "llvm::DominatorTreeBase<llvm::BasicBlock>::updateDFSNumbers", "llvm::DominatorTreeBase<llvm::BasicBlock>::updateDFSNumbers()",
  ),
  (
    "_ZN4llvm17DominatorTreeBaseINS_10BasicBlockEE10removeNodeEPS1_", "llvm::DominatorTreeBase<llvm::BasicBlock>::removeNode(llvm::BasicBlock*)",
    "llvm::DominatorTreeBase<llvm::BasicBlock>::removeNode", "llvm::DominatorTreeBase<llvm::BasicBlock>::removeNode(llvm::BasicBlock*)",
  ),
  (
    "_ZN12_GLOBAL__N_116SSEDomainFixPassD1Ev", "(anonymous namespace)::SSEDomainFixPass::~SSEDomainFixPass()",
    "(anonymous namespace)::SSEDomainFixPass::~SSEDomainFixPass", "(anonymous namespace)::SSEDomainFixPass::~SSEDomainFixPass()",
  ),
  (
    "_ZN4llvm17DominatorTreeBaseINS_17MachineBasicBlockEE26findNearestCommonDominatorEPS1_S3_",
    "llvm::DominatorTreeBase<llvm::MachineBasicBlock>::findNearestCommonDominator(llvm::MachineBasicBlock*, llvm::MachineBasicBlock*)",
    "llvm::DominatorTreeBase<llvm::MachineBasicBlock>::findNearestCommonDominator",
    "llvm::DominatorTreeBase<llvm::MachineBasicBlock>::findNearestCommonDominator(llvm::MachineBasicBlock*, llvm::MachineBasicBlock*)",
  ),
  (
    "_ZNH3Foo3fooERKS_i", "Foo::foo(this Foo const&, int)", "Foo::foo", "Foo::foo(this Foo const&, int)",
  ),
  (
    "_ZZNH3Foo3fooES_iENK4Foo24foo2Ev", "Foo::foo(this Foo, int)::Foo2::foo2() const",
    "Foo::foo(this Foo, int)::Foo2::foo2", "Foo::foo(this Foo, int)::Foo2::foo2() const",
  ),
  (
    "_ZNH3Foo3fooES_i", "Foo::foo(this Foo, int)", "Foo::foo", "Foo::foo(this Foo, int)",
  ),
  (
    "_ZZN3Foo3fooEiENH4Foo24foo2EOKS0_", "Foo::foo(int)::Foo2::foo2(this Foo2 const&&)",
    "Foo::foo(int)::Foo2::foo2", "Foo::foo(int)::Foo2::foo2(this Foo2 const&&)",
  ),
  (
    "_ZZNH2ns3Foo3fooES0_iENH4Foo24foo2EOKS1_", "ns::Foo::foo(this ns::Foo, int)::Foo2::foo2(this Foo2 const&&)",
    "ns::Foo::foo(this ns::Foo, int)::Foo2::foo2", "ns::Foo::foo(this ns::Foo, int)::Foo2::foo2(this Foo2 const&&)",
  ),
  (
    "_ZNH1X3fooIRS_EEvOT_i", "void X::foo<X&>(this X&, int)", "X::foo<X&>", "void X::foo<X&>(this X&, int)",
  ),
  (
    "_ZNH3FooclERKS_", "Foo::operator()(this Foo const&)", "Foo::operator()", "Foo::operator()(this Foo const&)",
  ),
  (
    "_ZNH2ns3FooB7Foo_tag3fooB7foo_tagERKS0_i", "ns::Foo[abi:Foo_tag]::foo[abi:foo_tag](this ns::Foo[abi:Foo_tag] const&, int)",
    "ns::Foo[abi:Foo_tag]::foo[abi:foo_tag]", "ns::Foo[abi:Foo_tag]::foo[abi:foo_tag](this ns::Foo[abi:Foo_tag] const&, int)",
  ),
  ("_ZW3FooDC1a1bE", "[a, b]@Foo", "[a, b]@Foo", "[a, b]@Foo"),
  (
    "_ZN4llvm3X8615GR64_TCW64ClassC1Ev", "llvm::X86::GR64_TCW64Class::GR64_TCW64Class()",
    "llvm::X86::GR64_TCW64Class::GR64_TCW64Class", "llvm::X86::GR64_TCW64Class::GR64_TCW64Class()",
  ),
  (
    "_ZNW3FOO3TPLIS_3OneE1MEPS1_", "TPL@FOO<One@FOO>::M(One@FOO*)", "TPL@FOO<One@FOO>::M",
    "TPL@FOO<One@FOO>::M(One@FOO*)",
  ),
  ("_ZW1ML1fi", "f@M(int)", "f@M", "f@M(int)"),
  (
    "_ZN4llvm3X86L23GR64_TCW64SubRegClassesE", "llvm::X86::GR64_TCW64SubRegClasses",
    "llvm::X86::GR64_TCW64SubRegClasses", "llvm::X86::GR64_TCW64SubRegClasses",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L10GR64_TCW64E", "llvm::(anonymous namespace)::GR64_TCW64",
    "llvm::(anonymous namespace)::GR64_TCW64", "llvm::(anonymous namespace)::GR64_TCW64",
  ),
  (
    "_ZN5OuterW3FOO5Inner2FnERNS1_1XE", "Outer::Inner@FOO::Fn(Outer::Inner@FOO::X&)",
    "Outer::Inner@FOO::Fn", "Outer::Inner@FOO::Fn(Outer::Inner@FOO::X&)",
  ),
  (
    "_ZN4Quux4TotoW3FooW3Bar3BazEPNS0_S2_5PlughE", "Quux::Toto::Baz@Foo.Bar(Quux::Toto::Plugh@Foo.Bar*)",
    "Quux::Toto::Baz@Foo.Bar", "Quux::Toto::Baz@Foo.Bar(Quux::Toto::Plugh@Foo.Bar*)",
  ),
  (
    "_ZZN4llvm23initializeGlobalDCEPassERNS_12PassRegistryEE11initialized", "llvm::initializeGlobalDCEPass(llvm::PassRegistry&)::initialized",
    "llvm::initializeGlobalDCEPass(llvm::PassRegistry&)::initialized", "llvm::initializeGlobalDCEPass(llvm::PassRegistry&)::initialized",
  ),
  (
    "_ZN4llvm18initializeADCEPassERNS_12PassRegistryE", "llvm::initializeADCEPass(llvm::PassRegistry&)",
    "llvm::initializeADCEPass", "llvm::initializeADCEPass(llvm::PassRegistry&)",
  ),
  (
    "_ZTVN12_GLOBAL__N_129PragmaSTDC_FENV_ACCESSHandlerE", "vtable for (anonymous namespace)::PragmaSTDC_FENV_ACCESSHandler",
    "vtable for (anonymous namespace)::PragmaSTDC_FENV_ACCESSHandler", "vtable for (anonymous namespace)::PragmaSTDC_FENV_ACCESSHandler",
  ),
  ("_ZDC2a12a2E", "[a1, a2]", "[a1, a2]", "[a1, a2]"),
  (
    "_ZN4llvm15callDefaultCtorIN12_GLOBAL__N_19GlobalDCEEEEPNS_4PassEv", "llvm::Pass* llvm::callDefaultCtor<(anonymous namespace)::GlobalDCE>()",
    "llvm::callDefaultCtor<(anonymous namespace)::GlobalDCE>", "llvm::Pass* llvm::callDefaultCtor<(anonymous namespace)::GlobalDCE>()",
  ),
  (
    "_ZN12_GLOBAL__N_134PragmaSTDC_CX_LIMITED_RANGEHandlerD1Ev", "(anonymous namespace)::PragmaSTDC_CX_LIMITED_RANGEHandler::~PragmaSTDC_CX_LIMITED_RANGEHandler()",
    "(anonymous namespace)::PragmaSTDC_CX_LIMITED_RANGEHandler::~PragmaSTDC_CX_LIMITED_RANGEHandler",
    "(anonymous namespace)::PragmaSTDC_CX_LIMITED_RANGEHandler::~PragmaSTDC_CX_LIMITED_RANGEHandler()",
  ),
  (
    "_ZN12_GLOBAL__N_19GlobalDCED1Ev", "(anonymous namespace)::GlobalDCE::~GlobalDCE()",
    "(anonymous namespace)::GlobalDCE::~GlobalDCE", "(anonymous namespace)::GlobalDCE::~GlobalDCE()",
  ),
  (
    "_ZN12_GLOBAL__N_19GlobalDCE23MarkUsedGlobalsAsNeededEPN4llvm8ConstantE", "(anonymous namespace)::GlobalDCE::MarkUsedGlobalsAsNeeded(llvm::Constant*)",
    "(anonymous namespace)::GlobalDCE::MarkUsedGlobalsAsNeeded", "(anonymous namespace)::GlobalDCE::MarkUsedGlobalsAsNeeded(llvm::Constant*)",
  ),
  (
    "_ZNK4llvm19ShuffleVectorSDNode7getMaskERNS_15SmallVectorImplIiEE", "llvm::ShuffleVectorSDNode::getMask(llvm::SmallVectorImpl<int>&) const",
    "llvm::ShuffleVectorSDNode::getMask", "llvm::ShuffleVectorSDNode::getMask(llvm::SmallVectorImpl<int>&) const",
  ),
  (
    "_ZN4llvm3X8614isMOVSHDUPMaskEPNS_19ShuffleVectorSDNodeE", "llvm::X86::isMOVSHDUPMask(llvm::ShuffleVectorSDNode*)",
    "llvm::X86::isMOVSHDUPMask", "llvm::X86::isMOVSHDUPMask(llvm::ShuffleVectorSDNode*)",
  ),
  (
    "_ZN12_GLOBAL__N_118UndefResultCheckerD1Ev", "(anonymous namespace)::UndefResultChecker::~UndefResultChecker()",
    "(anonymous namespace)::UndefResultChecker::~UndefResultChecker", "(anonymous namespace)::UndefResultChecker::~UndefResultChecker()",
  ),
  (
    "_ZN4llvm3X8626getShufflePSHUFHWImmediateEPNS_6SDNodeE", "llvm::X86::getShufflePSHUFHWImmediate(llvm::SDNode*)",
    "llvm::X86::getShufflePSHUFHWImmediate", "llvm::X86::getShufflePSHUFHWImmediate(llvm::SDNode*)",
  ),
  (
    "_ZN4llvm5APInt10fromStringEjNS_9StringRefEh", "llvm::APInt::fromString(unsigned int, llvm::StringRef, unsigned char)",
    "llvm::APInt::fromString", "llvm::APInt::fromString(unsigned int, llvm::StringRef, unsigned char)",
  ),
  (
    "_ZN4dyld9preflightEP11ImageLoaderRKNS0_10RPathChainE", "dyld::preflight(ImageLoader*, ImageLoader::RPathChain const&)",
    "dyld::preflight", "dyld::preflight(ImageLoader*, ImageLoader::RPathChain const&)",
  ),
  (
    "_Z14getShuffleMaskPKN4llvm17ShuffleVectorInstE", "getShuffleMask(llvm::ShuffleVectorInst const*)",
    "getShuffleMask", "getShuffleMask(llvm::ShuffleVectorInst const*)",
  ),
  (
    "_ZN5clang7VarDecl22getOutOfLineDefinitionEv", "clang::VarDecl::getOutOfLineDefinition()",
    "clang::VarDecl::getOutOfLineDefinition", "clang::VarDecl::getOutOfLineDefinition()",
  ),
  (
    "_ZN12_GLOBAL__N_114NSErrorChecker20CheckNSErrorArgumentEN5clang8QualTypeE",
    "(anonymous namespace)::NSErrorChecker::CheckNSErrorArgument(clang::QualType)",
    "(anonymous namespace)::NSErrorChecker::CheckNSErrorArgument", "(anonymous namespace)::NSErrorChecker::CheckNSErrorArgument(clang::QualType)",
  ),
  (
    "_ZN4llvm20LatencyPriorityQueue12releaseStateEv", "llvm::LatencyPriorityQueue::releaseState()",
    "llvm::LatencyPriorityQueue::releaseState", "llvm::LatencyPriorityQueue::releaseState()",
  ),
  (
    "_ZN5clang7CodeGen13CodeGenModule29EmitFundamentalRTTIDescriptorENS_8QualTypeE",
    "clang::CodeGen::CodeGenModule::EmitFundamentalRTTIDescriptor(clang::QualType)",
    "clang::CodeGen::CodeGenModule::EmitFundamentalRTTIDescriptor", "clang::CodeGen::CodeGenModule::EmitFundamentalRTTIDescriptor(clang::QualType)",
  ),
  (
    "_ZN12_GLOBAL__N_123MicrosoftCXXNameMangler10mangleTypeEN5clang8QualTypeE", "(anonymous namespace)::MicrosoftCXXNameMangler::mangleType(clang::QualType)",
    "(anonymous namespace)::MicrosoftCXXNameMangler::mangleType", "(anonymous namespace)::MicrosoftCXXNameMangler::mangleType(clang::QualType)",
  ),
  (
    "_ZN12_GLOBAL__N_118RegReductionPQBase15UnscheduledNodeEPN4llvm5SUnitE", "(anonymous namespace)::RegReductionPQBase::UnscheduledNode(llvm::SUnit*)",
    "(anonymous namespace)::RegReductionPQBase::UnscheduledNode", "(anonymous namespace)::RegReductionPQBase::UnscheduledNode(llvm::SUnit*)",
  ),
  (
    "_ZN5clang4ento17BasicValueFactory18getCompoundValDataENS_8QualTypeEN4llvm13ImmutableListINS0_4SValEEE",
    "clang::ento::BasicValueFactory::getCompoundValData(clang::QualType, llvm::ImmutableList<clang::ento::SVal>)",
    "clang::ento::BasicValueFactory::getCompoundValData", "clang::ento::BasicValueFactory::getCompoundValData(clang::QualType, llvm::ImmutableList<clang::ento::SVal>)",
  ),
  (
    "_ZN5clang10ASTContext18typesAreCompatibleENS_8QualTypeES1_b", "clang::ASTContext::typesAreCompatible(clang::QualType, clang::QualType, bool)",
    "clang::ASTContext::typesAreCompatible", "clang::ASTContext::typesAreCompatible(clang::QualType, clang::QualType, bool)",
  ),
  (
    "_ZNK5clang4Type24getAsObjCQualifiedIdTypeEv", "clang::Type::getAsObjCQualifiedIdType() const",
    "clang::Type::getAsObjCQualifiedIdType", "clang::Type::getAsObjCQualifiedIdType() const",
  ),
  (
    "_ZN4llvmL13ImplicitList4E", "llvm::ImplicitList4", "llvm::ImplicitList4", "llvm::ImplicitList4",
  ),
  (
    "_ZN4llvm12PassRegistry14unregisterPassERKNS_8PassInfoE", "llvm::PassRegistry::unregisterPass(llvm::PassInfo const&)",
    "llvm::PassRegistry::unregisterPass", "llvm::PassRegistry::unregisterPass(llvm::PassInfo const&)",
  ),
  (
    "_ZN4llvm14IndirectBrInstC1EPNS_5ValueEjPNS_11InstructionE", "llvm::IndirectBrInst::IndirectBrInst(llvm::Value*, unsigned int, llvm::Instruction*)",
    "llvm::IndirectBrInst::IndirectBrInst", "llvm::IndirectBrInst::IndirectBrInst(llvm::Value*, unsigned int, llvm::Instruction*)",
  ),
  (
    "_ZTVN12_GLOBAL__N_126AdjustedReturnValueCheckerE", "vtable for (anonymous namespace)::AdjustedReturnValueChecker",
    "vtable for (anonymous namespace)::AdjustedReturnValueChecker", "vtable for (anonymous namespace)::AdjustedReturnValueChecker",
  ),
  ("_ZL11NumGVNInstr", "NumGVNInstr", "NumGVNInstr", "NumGVNInstr"),
  ("_ZL11FirstTarget", "FirstTarget", "FirstTarget", "FirstTarget"),
  (
    "_ZN4llvm13BitcodeReader14ParseConstantsEv", "llvm::BitcodeReader::ParseConstants()",
    "llvm::BitcodeReader::ParseConstants", "llvm::BitcodeReader::ParseConstants()",
  ),
  (
    "_ZN4llvmL14ImplicitList10E", "llvm::ImplicitList10", "llvm::ImplicitList10",
    "llvm::ImplicitList10",
  ),
  (
    "_Znam", "operator new[](unsigned long)", "operator new[]", "operator new[](unsigned long)",
  ),
  (
    "_ZN4llvm13LPPassManager17dumpPassStructureEj", "llvm::LPPassManager::dumpPassStructure(unsigned int)",
    "llvm::LPPassManager::dumpPassStructure", "llvm::LPPassManager::dumpPassStructure(unsigned int)",
  ),
  (
    "_ZN5clang7CodeGen13EHPersonality5GNU_CE", "clang::CodeGen::EHPersonality::GNU_C",
    "clang::CodeGen::EHPersonality::GNU_C", "clang::CodeGen::EHPersonality::GNU_C",
  ),
  (
    "_ZTVN12_GLOBAL__N_121PerformFragileFinallyE", "vtable for (anonymous namespace)::PerformFragileFinally",
    "vtable for (anonymous namespace)::PerformFragileFinally", "vtable for (anonymous namespace)::PerformFragileFinally",
  ),
  (
    "_ZN4llvm4Pass17assignPassManagerERNS_7PMStackENS_15PassManagerTypeE", "llvm::Pass::assignPassManager(llvm::PMStack&, llvm::PassManagerType)",
    "llvm::Pass::assignPassManager", "llvm::Pass::assignPassManager(llvm::PMStack&, llvm::PassManagerType)",
  ),
  (
    "_ZN4llvm23FunctionPassManagerImpl3runERNS_8FunctionE", "llvm::FunctionPassManagerImpl::run(llvm::Function&)",
    "llvm::FunctionPassManagerImpl::run", "llvm::FunctionPassManagerImpl::run(llvm::Function&)",
  ),
  (
    "_ZNK4llvm15TargetInstrInfo33isReallyTriviallyReMaterializableEPKNS_12MachineInstrEPNS_13AliasAnalysisE",
    "llvm::TargetInstrInfo::isReallyTriviallyReMaterializable(llvm::MachineInstr const*, llvm::AliasAnalysis*) const",
    "llvm::TargetInstrInfo::isReallyTriviallyReMaterializable", "llvm::TargetInstrInfo::isReallyTriviallyReMaterializable(llvm::MachineInstr const*, llvm::AliasAnalysis*) const",
  ),
  (
    "_ZN4llvm14BinaryOperator12CreateNSWNegEPNS_5ValueERKNS_5TwineEPNS_10BasicBlockE",
    "llvm::BinaryOperator::CreateNSWNeg(llvm::Value*, llvm::Twine const&, llvm::BasicBlock*)",
    "llvm::BinaryOperator::CreateNSWNeg", "llvm::BinaryOperator::CreateNSWNeg(llvm::Value*, llvm::Twine const&, llvm::BasicBlock*)",
  ),
  (
    "_ZTVN12_GLOBAL__N_115StandardSpillerE", "vtable for (anonymous namespace)::StandardSpiller",
    "vtable for (anonymous namespace)::StandardSpiller", "vtable for (anonymous namespace)::StandardSpiller",
  ),
  (
    "_ZN4llvm8DenseMapIPNS_10GCStrategyEPNS_17GCMetadataPrinterENS_12DenseMapInfoIS2_EENS5_IS4_EEE4growEj",
    "llvm::DenseMap<llvm::GCStrategy*, llvm::GCMetadataPrinter*, llvm::DenseMapInfo<llvm::GCStrategy*>, llvm::DenseMapInfo<llvm::GCMetadataPrinter*>>::grow(unsigned int)",
    "llvm::DenseMap<llvm::GCStrategy*, llvm::GCMetadataPrinter*, llvm::DenseMapInfo<llvm::GCStrategy*>, llvm::DenseMapInfo<llvm::GCMetadataPrinter*>>::grow",
    "llvm::DenseMap<llvm::GCStrategy*, llvm::GCMetadataPrinter*, llvm::DenseMapInfo<llvm::GCStrategy*>, llvm::DenseMapInfo<llvm::GCMetadataPrinter*>>::grow(unsigned int)",
  ),
  (
    "_ZN5clang4ento10CoreEngine15HandleCallEnterERKNS_9CallEnterEPKNS_8CFGBlockEjPNS0_12ExplodedNodeE",
    "clang::ento::CoreEngine::HandleCallEnter(clang::CallEnter const&, clang::CFGBlock const*, unsigned int, clang::ento::ExplodedNode*)",
    "clang::ento::CoreEngine::HandleCallEnter", "clang::ento::CoreEngine::HandleCallEnter(clang::CallEnter const&, clang::CFGBlock const*, unsigned int, clang::ento::ExplodedNode*)",
  ),
  (
    "_ZN5clang21CodeCompletionHandler34CodeCompleteInConditionalExclusionEv", "clang::CodeCompletionHandler::CodeCompleteInConditionalExclusion()",
    "clang::CodeCompletionHandler::CodeCompleteInConditionalExclusion", "clang::CodeCompletionHandler::CodeCompleteInConditionalExclusion()",
  ),
  (
    "_Z12CrashHandlerPv", "CrashHandler(void*)", "CrashHandler", "CrashHandler(void*)",
  ),
  (
    "_Z20HandlePluralModifierRKN5clang14DiagnosticInfoEjPKcjRN4llvm15SmallVectorImplIcEE",
    "HandlePluralModifier(clang::DiagnosticInfo const&, unsigned int, char const*, unsigned int, llvm::SmallVectorImpl<char>&)",
    "HandlePluralModifier", "HandlePluralModifier(clang::DiagnosticInfo const&, unsigned int, char const*, unsigned int, llvm::SmallVectorImpl<char>&)",
  ),
  (
    "_ZL20ErrorHandlerUserData", "ErrorHandlerUserData", "ErrorHandlerUserData",
    "ErrorHandlerUserData",
  ),
  (
    "_ZN12_GLOBAL__N_115StandardSpillerD0Ev", "(anonymous namespace)::StandardSpiller::~StandardSpiller()",
    "(anonymous namespace)::StandardSpiller::~StandardSpiller", "(anonymous namespace)::StandardSpiller::~StandardSpiller()",
  ),
  (
    "_ZN4llvm17MachineBasicBlock12addSuccessorEPS0_", "llvm::MachineBasicBlock::addSuccessor(llvm::MachineBasicBlock*)",
    "llvm::MachineBasicBlock::addSuccessor", "llvm::MachineBasicBlock::addSuccessor(llvm::MachineBasicBlock*)",
  ),
  (
    "_ZN4llvm3X86L17RFP80SuperclassesE", "llvm::X86::RFP80Superclasses", "llvm::X86::RFP80Superclasses",
    "llvm::X86::RFP80Superclasses",
  ),
  (
    "_ZNK4llvm16ARMBaseInstrInfo15getVLDMDefCycleEPKNS_18InstrItineraryDataERKNS_15TargetInstrDescEjjj",
    "llvm::ARMBaseInstrInfo::getVLDMDefCycle(llvm::InstrItineraryData const*, llvm::TargetInstrDesc const&, unsigned int, unsigned int, unsigned int) const",
    "llvm::ARMBaseInstrInfo::getVLDMDefCycle", "llvm::ARMBaseInstrInfo::getVLDMDefCycle(llvm::InstrItineraryData const*, llvm::TargetInstrDesc const&, unsigned int, unsigned int, unsigned int) const",
  ),
  (
    "_ZNK4llvm2cl6parserIN12_GLOBAL__N_112RewriterNameEE14getDescriptionEj", "llvm::cl::parser<(anonymous namespace)::RewriterName>::getDescription(unsigned int) const",
    "llvm::cl::parser<(anonymous namespace)::RewriterName>::getDescription", "llvm::cl::parser<(anonymous namespace)::RewriterName>::getDescription(unsigned int) const",
  ),
  (
    "_ZN5clang6driver14BindArchActionC2EPNS0_6ActionEPKc", "clang::driver::BindArchAction::BindArchAction(clang::driver::Action*, char const*)",
    "clang::driver::BindArchAction::BindArchAction", "clang::driver::BindArchAction::BindArchAction(clang::driver::Action*, char const*)",
  ),
  (
    "_ZNK5clang6driver10toolchains11Generic_GCC17GetForcedPicModelEv", "clang::driver::toolchains::Generic_GCC::GetForcedPicModel() const",
    "clang::driver::toolchains::Generic_GCC::GetForcedPicModel", "clang::driver::toolchains::Generic_GCC::GetForcedPicModel() const",
  ),
  (
    "_ZN4llvm3X86L23CONTROL_REGSuperclassesE", "llvm::X86::CONTROL_REGSuperclasses",
    "llvm::X86::CONTROL_REGSuperclasses", "llvm::X86::CONTROL_REGSuperclasses",
  ),
  (
    "_ZN4llvm12scc_iteratorIPNS_9CallGraphENS_11GraphTraitsIS2_EEE11DFSVisitOneEPNS_13CallGraphNodeE",
    "llvm::scc_iterator<llvm::CallGraph*, llvm::GraphTraits<llvm::CallGraph*>>::DFSVisitOne(llvm::CallGraphNode*)",
    "llvm::scc_iterator<llvm::CallGraph*, llvm::GraphTraits<llvm::CallGraph*>>::DFSVisitOne",
    "llvm::scc_iterator<llvm::CallGraph*, llvm::GraphTraits<llvm::CallGraph*>>::DFSVisitOne(llvm::CallGraphNode*)",
  ),
  (
    "_ZN5clang4Sema27CodeCompleteObjCPassingTypeEPNS_5ScopeERNS_12ObjCDeclSpecE",
    "clang::Sema::CodeCompleteObjCPassingType(clang::Scope*, clang::ObjCDeclSpec&)",
    "clang::Sema::CodeCompleteObjCPassingType", "clang::Sema::CodeCompleteObjCPassingType(clang::Scope*, clang::ObjCDeclSpec&)",
  ),
  (
    "_ZN4llvm10FoldingSetIN5clang17MemberPointerTypeEED1Ev", "llvm::FoldingSet<clang::MemberPointerType>::~FoldingSet()",
    "llvm::FoldingSet<clang::MemberPointerType>::~FoldingSet", "llvm::FoldingSet<clang::MemberPointerType>::~FoldingSet()",
  ),
  (
    "_ZN5clang21ASTIdentifierIteratorC1ERKNS_9ASTReaderE", "clang::ASTIdentifierIterator::ASTIdentifierIterator(clang::ASTReader const&)",
    "clang::ASTIdentifierIterator::ASTIdentifierIterator", "clang::ASTIdentifierIterator::ASTIdentifierIterator(clang::ASTReader const&)",
  ),
  (
    "_ZN5clang7CodeGen12EHScopeStack7CleanupD1Ev", "clang::CodeGen::EHScopeStack::Cleanup::~Cleanup()",
    "clang::CodeGen::EHScopeStack::Cleanup::~Cleanup", "clang::CodeGen::EHScopeStack::Cleanup::~Cleanup()",
  ),
  (
    "_ZN5clang4Sema17ComparePropertiesEPNS_4DeclES2_", "clang::Sema::CompareProperties(clang::Decl*, clang::Decl*)",
    "clang::Sema::CompareProperties", "clang::Sema::CompareProperties(clang::Decl*, clang::Decl*)",
  ),
  (
    "_ZN12_GLOBAL__N_111RewriteObjC23RewriteBlockDeclRefExprEPN5clang4ExprE", "(anonymous namespace)::RewriteObjC::RewriteBlockDeclRefExpr(clang::Expr*)",
    "(anonymous namespace)::RewriteObjC::RewriteBlockDeclRefExpr", "(anonymous namespace)::RewriteObjC::RewriteBlockDeclRefExpr(clang::Expr*)",
  ),
  (
    "_ZN5clang7CodeGen15CodeGenFunction20EmitExprWithCleanupsEPKNS_16ExprWithCleanupsENS0_12AggValueSlotE",
    "clang::CodeGen::CodeGenFunction::EmitExprWithCleanups(clang::ExprWithCleanups const*, clang::CodeGen::AggValueSlot)",
    "clang::CodeGen::CodeGenFunction::EmitExprWithCleanups", "clang::CodeGen::CodeGenFunction::EmitExprWithCleanups(clang::ExprWithCleanups const*, clang::CodeGen::AggValueSlot)",
  ),
  (
    "_Z22AddSuperSendCompletionRN5clang4SemaEbPPNS_14IdentifierInfoEjRN12_GLOBAL__N_113ResultBuilderE",
    "AddSuperSendCompletion(clang::Sema&, bool, clang::IdentifierInfo**, unsigned int, (anonymous namespace)::ResultBuilder&)",
    "AddSuperSendCompletion", "AddSuperSendCompletion(clang::Sema&, bool, clang::IdentifierInfo**, unsigned int, (anonymous namespace)::ResultBuilder&)",
  ),
  (
    "_ZNK4llvm2cl3optIjLb0ENS0_6parserIjEEE27getValueExpectedFlagDefaultEv", "llvm::cl::opt<unsigned int, false, llvm::cl::parser<unsigned int>>::getValueExpectedFlagDefault() const",
    "llvm::cl::opt<unsigned int, false, llvm::cl::parser<unsigned int>>::getValueExpectedFlagDefault",
    "llvm::cl::opt<unsigned int, false, llvm::cl::parser<unsigned int>>::getValueExpectedFlagDefault() const",
  ),
  (
    "_ZN4llvm14DwarfException5PadLTEPKNS_14LandingPadInfoES3_", "llvm::DwarfException::PadLT(llvm::LandingPadInfo const*, llvm::LandingPadInfo const*)",
    "llvm::DwarfException::PadLT", "llvm::DwarfException::PadLT(llvm::LandingPadInfo const*, llvm::LandingPadInfo const*)",
  ),
  (
    "_ZN4llvm2cl3optIcLb0ENS0_6parserIcEEE4doneEv", "llvm::cl::opt<char, false, llvm::cl::parser<char>>::done()",
    "llvm::cl::opt<char, false, llvm::cl::parser<char>>::done", "llvm::cl::opt<char, false, llvm::cl::parser<char>>::done()",
  ),
  (
    "_ZN4llvm14TargetLowering15DAGCombinerInfo23CommitTargetLoweringOptERKNS0_17TargetLoweringOptE",
    "llvm::TargetLowering::DAGCombinerInfo::CommitTargetLoweringOpt(llvm::TargetLowering::TargetLoweringOpt const&)",
    "llvm::TargetLowering::DAGCombinerInfo::CommitTargetLoweringOpt", "llvm::TargetLowering::DAGCombinerInfo::CommitTargetLoweringOpt(llvm::TargetLowering::TargetLoweringOpt const&)",
  ),
  (
    "_ZTVN12_GLOBAL__N_16AbsOptE", "vtable for (anonymous namespace)::AbsOpt", "vtable for (anonymous namespace)::AbsOpt",
    "vtable for (anonymous namespace)::AbsOpt",
  ),
  (
    "_ZN12_GLOBAL__N_19StrChrOptD1Ev", "(anonymous namespace)::StrChrOpt::~StrChrOpt()",
    "(anonymous namespace)::StrChrOpt::~StrChrOpt", "(anonymous namespace)::StrChrOpt::~StrChrOpt()",
  ),
  (
    "_ZN12_GLOBAL__N_112OptimizePHIs14IsDeadPHICycleEPN4llvm12MachineInstrERNS1_11SmallPtrSetIS3_Lj16EEE",
    "(anonymous namespace)::OptimizePHIs::IsDeadPHICycle(llvm::MachineInstr*, llvm::SmallPtrSet<llvm::MachineInstr*, 16u>&)",
    "(anonymous namespace)::OptimizePHIs::IsDeadPHICycle", "(anonymous namespace)::OptimizePHIs::IsDeadPHICycle(llvm::MachineInstr*, llvm::SmallPtrSet<llvm::MachineInstr*, 16u>&)",
  ),
  (
    "_ZNK5clang6driver7ArgList10getLastArgENS0_12OptSpecifierES2_S2_", "clang::driver::ArgList::getLastArg(clang::driver::OptSpecifier, clang::driver::OptSpecifier, clang::driver::OptSpecifier) const",
    "clang::driver::ArgList::getLastArg", "clang::driver::ArgList::getLastArg(clang::driver::OptSpecifier, clang::driver::OptSpecifier, clang::driver::OptSpecifier) const",
  ),
  (
    "_Z3ft7IiEN11__enable_ifIXsr16__is_scalar_typeIT_EE7__valueEvE6__typeEv", "__enable_if<__is_scalar_type<int>::__value, void>::__type ft7<int>()",
    "ft7<int>", "__enable_if<__is_scalar_type<int>::__value, void>::__type ft7<int>()",
  ),
  (
    "_ZNK10__cxxabiv120__si_class_type_info20__do_find_public_srcElPKvPKNS_17__class_type_infoES2_",
    "__cxxabiv1::__si_class_type_info::__do_find_public_src(long, void const*, __cxxabiv1::__class_type_info const*, void const*) const",
    "__cxxabiv1::__si_class_type_info::__do_find_public_src", "__cxxabiv1::__si_class_type_info::__do_find_public_src(long, void const*, __cxxabiv1::__class_type_info const*, void const*) const",
  ),
  (
    "_Z3ft7IPvEN11__enable_ifIXsr16__is_scalar_typeIT_EE7__valueEvE6__typeEv", "__enable_if<__is_scalar_type<void*>::__value, void>::__type ft7<void*>()",
    "ft7<void*>", "__enable_if<__is_scalar_type<void*>::__value, void>::__type ft7<void*>()",
  ),
  (
    "_ZNK4llvm5APInt4sremERKS0_", "llvm::APInt::srem(llvm::APInt const&) const",
    "llvm::APInt::srem", "llvm::APInt::srem(llvm::APInt const&) const",
  ),
  (
    "_ZN6test191gINS_1AEEEvNS_1SIXadsrT_miIdEEEE", "void test19::g<test19::A>(test19::S<&test19::A::operator-<double>>)",
    "test19::g<test19::A>", "void test19::g<test19::A>(test19::S<&test19::A::operator-<double>>)",
  ),
  (
    "_ZN6test191gINS_1AEEEvNS_1SIXadsrT_plEEE", "void test19::g<test19::A>(test19::S<&test19::A::operator+>)",
    "test19::g<test19::A>", "void test19::g<test19::A>(test19::S<&test19::A::operator+>)",
  ),
  (
    "Ana_T_E_T_IJEffffffffffffffersfffffrsrsffffffbgE", "Ana_T_E_T_IJEffffffffffffffersfffffrsrsffffffbgE",
    "Ana_T_E_T_IJEffffffffffffffersfffffrsrsffffffbgE", "Ana_T_E_T_IJEffffffffffffffersfffffrsrsffffffbgE",
  ),
  (
    "_ZN5test81fIiEEvNS_5int_cIXsrNS_4metaIT_E4typeE5valueEEE", "void test8::f<int>(test8::int_c<test8::meta<int>::type::value>)",
    "test8::f<int>", "void test8::f<int>(test8::int_c<test8::meta<int>::type::value>)",
  ),
  ("_Z1fUa9enable_ifIXLi1EEEv", "f() [enable_if:1]", "f", "f() [enable_if:1]"),
  (
    "_Z3quxUa9enable_ifIXLi1EEXL_Z9TRUEFACTSEEEi", "qux(int) [enable_if:1, TRUEFACTS]",
    "qux", "qux(int) [enable_if:1, TRUEFACTS]",
  ),
  (
    "_ZN5test4IdE1fEUa9enable_ifIXeqfL0p_Li1EEXeqfL0p0_Li2EEEi", "test4<double>::f(int) [enable_if:fp == 1, fp0 == 2]",
    "test4<double>::f", "test4<double>::f(int) [enable_if:fp == 1, fp0 == 2]",
  ),
  ("_Z1fPU11objcproto1A11objc_object", "f(id<A>)", "f", "f(id<A>)"),
  (
    "_Z1fPKU11objcproto1A7NSArray", "f(NSArray<A> const*)", "f", "f(NSArray<A> const*)",
  ),
  (
    "_Z1fIiEvDBstPT__", "void f<int>(_BitInt(sizeof (int*)))", "f<int>", "void f<int>(_BitInt(sizeof (int*)))",
  ),
  (
    "_ZN4llvm12SelectionDAG7getNodeEjNS_8DebugLocENS_3EVTEPKNS_5SDUseEj", "llvm::SelectionDAG::getNode(unsigned int, llvm::DebugLoc, llvm::EVT, llvm::SDUse const*, unsigned int)",
    "llvm::SelectionDAG::getNode", "llvm::SelectionDAG::getNode(unsigned int, llvm::DebugLoc, llvm::EVT, llvm::SDUse const*, unsigned int)",
  ),
  ("_Z1fDU10_", "f(unsigned _BitInt(10))", "f", "f(unsigned _BitInt(10))"),
  (
    "_ZN4llvm3X8613isMOVDDUPMaskEPNS_19ShuffleVectorSDNodeE", "llvm::X86::isMOVDDUPMask(llvm::ShuffleVectorSDNode*)",
    "llvm::X86::isMOVDDUPMask", "llvm::X86::isMOVDDUPMask(llvm::ShuffleVectorSDNode*)",
  ),
  (
    "_ZNK4llvm19MachineRegisterInfo15hasOneNonDBGUseEj", "llvm::MachineRegisterInfo::hasOneNonDBGUse(unsigned int) const",
    "llvm::MachineRegisterInfo::hasOneNonDBGUse", "llvm::MachineRegisterInfo::hasOneNonDBGUse(unsigned int) const",
  ),
  (
    "_ZN4llvm3X8614isMOVSLDUPMaskEPNS_19ShuffleVectorSDNodeE", "llvm::X86::isMOVSLDUPMask(llvm::ShuffleVectorSDNode*)",
    "llvm::X86::isMOVSLDUPMask", "llvm::X86::isMOVSLDUPMask(llvm::ShuffleVectorSDNode*)",
  ),
  (
    "_Z6myfuncRDB8_S0_", "myfunc(_BitInt(8)&, _BitInt(8)&)", "myfunc", "myfunc(_BitInt(8)&, _BitInt(8)&)",
  ),
  ("_Z1fDB3_", "f(_BitInt(3))", "f", "f(_BitInt(3))"),
  (
    "_ZN4llvm15IntervalMapImpl8LeafNodeINS_9SlotIndexEjLj9ENS_15IntervalMapInfoIS2_EEE10insertFromERjjS2_S2_j",
    "llvm::IntervalMapImpl::LeafNode<llvm::SlotIndex, unsigned int, 9u, llvm::IntervalMapInfo<llvm::SlotIndex>>::insertFrom(unsigned int&, unsigned int, llvm::SlotIndex, llvm::SlotIndex, unsigned int)",
    "llvm::IntervalMapImpl::LeafNode<llvm::SlotIndex, unsigned int, 9u, llvm::IntervalMapInfo<llvm::SlotIndex>>::insertFrom",
    "llvm::IntervalMapImpl::LeafNode<llvm::SlotIndex, unsigned int, 9u, llvm::IntervalMapInfo<llvm::SlotIndex>>::insertFrom(unsigned int&, unsigned int, llvm::SlotIndex, llvm::SlotIndex, unsigned int)",
  ),
  (
    "_ZTVN12_GLOBAL__N_112LeakAtReturnE", "vtable for (anonymous namespace)::LeakAtReturn",
    "vtable for (anonymous namespace)::LeakAtReturn", "vtable for (anonymous namespace)::LeakAtReturn",
  ),
  (
    "_ZN5test01hIfEEvRAcvjplstT_Le4001a000000000000000E_c", "_ZN5test01hIfEEvRAcvjplstT_Le4001a000000000000000E_c",
    "test0::h<float>", "_ZN5test01hIfEEvRAcvjplstT_Le4001a000000000000000E_c",
  ),
  (
    "3FooILdaaaaaaaaaaAAAAaaEE", "3FooILdaaaaaaaaaaAAAAaaEE", "3FooILdaaaaaaaaaaAAAAaaEE",
    "3FooILdaaaaaaaaaaAAAAaaEE",
  ),
  (
    "_ZN5test01hIfEEvRAszplcvT__ELd4014000000000000E_c", "void test0::h<float>(char (&) [sizeof ((float)() + 0x1.4p+2)])",
    "test0::h<float>", "void test0::h<float>(char (&) [sizeof ((float)() + 0x1.4p+2)])",
  ),
  (
    "_ZN5test01gIfEEvRAszplcvT__ELf40a00000E_c", "void test0::g<float>(char (&) [sizeof ((float)() + 0x1.4p+2f)])",
    "test0::g<float>", "void test0::g<float>(char (&) [sizeof ((float)() + 0x1.4p+2f)])",
  ),
  (
    "_ZNK12_GLOBAL__N_14Leak6isLeakEv", "(anonymous namespace)::Leak::isLeak() const",
    "(anonymous namespace)::Leak::isLeak", "(anonymous namespace)::Leak::isLeak() const",
  ),
  (
    "_ZN12_GLOBAL__N_112LeakAtReturnD1Ev", "(anonymous namespace)::LeakAtReturn::~LeakAtReturn()",
    "(anonymous namespace)::LeakAtReturn::~LeakAtReturn", "(anonymous namespace)::LeakAtReturn::~LeakAtReturn()",
  ),
  (
    "_ZNK4llvm12MCSectionELF26ShouldOmitSectionDirectiveENS_9StringRefERKNS_9MCAsmInfoE",
    "llvm::MCSectionELF::ShouldOmitSectionDirective(llvm::StringRef, llvm::MCAsmInfo const&) const",
    "llvm::MCSectionELF::ShouldOmitSectionDirective", "llvm::MCSectionELF::ShouldOmitSectionDirective(llvm::StringRef, llvm::MCAsmInfo const&) const",
  ),
  (
    "_ZNK4llvm12MCSectionELF16isVirtualSectionEv", "llvm::MCSectionELF::isVirtualSection() const",
    "llvm::MCSectionELF::isVirtualSection", "llvm::MCSectionELF::isVirtualSection() const",
  ),
  (
    "_ZN4llvm20MachineModuleInfoELF6AnchorEv", "llvm::MachineModuleInfoELF::Anchor()",
    "llvm::MachineModuleInfoELF::Anchor", "llvm::MachineModuleInfoELF::Anchor()",
  ),
  (
    "_ZN4llvm28TargetLoweringObjectFileCOFF10InitializeERNS_9MCContextERKNS_13TargetMachineE",
    "llvm::TargetLoweringObjectFileCOFF::Initialize(llvm::MCContext&, llvm::TargetMachine const&)",
    "llvm::TargetLoweringObjectFileCOFF::Initialize", "llvm::TargetLoweringObjectFileCOFF::Initialize(llvm::MCContext&, llvm::TargetMachine const&)",
  ),
  (
    "_ZNK4llvm13MCSectionCOFF20PrintSwitchToSectionERKNS_9MCAsmInfoERNS_11raw_ostreamE",
    "llvm::MCSectionCOFF::PrintSwitchToSection(llvm::MCAsmInfo const&, llvm::raw_ostream&) const",
    "llvm::MCSectionCOFF::PrintSwitchToSection", "llvm::MCSectionCOFF::PrintSwitchToSection(llvm::MCAsmInfo const&, llvm::raw_ostream&) const",
  ),
  (
    "_ZN4llvm12MCSectionELF18DetermineEntrySizeENS_11SectionKindE", "llvm::MCSectionELF::DetermineEntrySize(llvm::SectionKind)",
    "llvm::MCSectionELF::DetermineEntrySize", "llvm::MCSectionELF::DetermineEntrySize(llvm::SectionKind)",
  ),
  (
    "_ZN4llvm7APFloat26initFromF80LongDoubleAPIntERKNS_5APIntE", "llvm::APFloat::initFromF80LongDoubleAPInt(llvm::APInt const&)",
    "llvm::APFloat::initFromF80LongDoubleAPInt", "llvm::APFloat::initFromF80LongDoubleAPInt(llvm::APInt const&)",
  ),
  (
    "_Z11bfloat16addDF16bDF16b", "bfloat16add(std::bfloat16_t, std::bfloat16_t)",
    "bfloat16add", "bfloat16add(std::bfloat16_t, std::bfloat16_t)",
  ),
  (
    "_ZN4llvm4TypeD1Ev", "llvm::Type::~Type()", "llvm::Type::~Type", "llvm::Type::~Type()",
  ),
  (
    "_ZN4llvm13FindUsedTypesD1Ev", "llvm::FindUsedTypes::~FindUsedTypes()", "llvm::FindUsedTypes::~FindUsedTypes",
    "llvm::FindUsedTypes::~FindUsedTypes()",
  ),
  (
    "_ZN5clang4Sema13ActOnTypeNameEPNS_5ScopeERNS_10DeclaratorE", "clang::Sema::ActOnTypeName(clang::Scope*, clang::Declarator&)",
    "clang::Sema::ActOnTypeName", "clang::Sema::ActOnTypeName(clang::Scope*, clang::Declarator&)",
  ),
  (
    "_ZN4llvm17ConstantUniqueMapINS_16InlineAsmKeyTypeENS_11PointerTypeENS_9InlineAsmELb0EED1Ev",
    "llvm::ConstantUniqueMap<llvm::InlineAsmKeyType, llvm::PointerType, llvm::InlineAsm, false>::~ConstantUniqueMap()",
    "llvm::ConstantUniqueMap<llvm::InlineAsmKeyType, llvm::PointerType, llvm::InlineAsm, false>::~ConstantUniqueMap",
    "llvm::ConstantUniqueMap<llvm::InlineAsmKeyType, llvm::PointerType, llvm::InlineAsm, false>::~ConstantUniqueMap()",
  ),
  (
    "_ZN4llvm16DAGTypeLegalizer18WidenVecOp_ConvertEPNS_6SDNodeE", "llvm::DAGTypeLegalizer::WidenVecOp_Convert(llvm::SDNode*)",
    "llvm::DAGTypeLegalizer::WidenVecOp_Convert", "llvm::DAGTypeLegalizer::WidenVecOp_Convert(llvm::SDNode*)",
  ),
  (
    "_ZN5clang7CodeGen12CodeGenTypes15getFunctionInfoEPKNS_12FunctionDeclE", "clang::CodeGen::CodeGenTypes::getFunctionInfo(clang::FunctionDecl const*)",
    "clang::CodeGen::CodeGenTypes::getFunctionInfo", "clang::CodeGen::CodeGenTypes::getFunctionInfo(clang::FunctionDecl const*)",
  ),
  (
    "_ZN4llvm17ConstantUniqueMapISt6vectorIPNS_8ConstantESaIS3_EENS_10VectorTypeENS_14ConstantVectorELb0EED1Ev",
    "llvm::ConstantUniqueMap<std::vector<llvm::Constant*, std::allocator<llvm::Constant*>>, llvm::VectorType, llvm::ConstantVector, false>::~ConstantUniqueMap()",
    "llvm::ConstantUniqueMap<std::vector<llvm::Constant*, std::allocator<llvm::Constant*>>, llvm::VectorType, llvm::ConstantVector, false>::~ConstantUniqueMap",
    "llvm::ConstantUniqueMap<std::vector<llvm::Constant*, std::allocator<llvm::Constant*>>, llvm::VectorType, llvm::ConstantVector, false>::~ConstantUniqueMap()",
  ),
  (
    "_ZN4llvm4Type9getVoidTyERNS_11LLVMContextE", "llvm::Type::getVoidTy(llvm::LLVMContext&)",
    "llvm::Type::getVoidTy", "llvm::Type::getVoidTy(llvm::LLVMContext&)",
  ),
  (
    "_ZNK4llvm6Module11getMDKindIDENS_9StringRefE", "llvm::Module::getMDKindID(llvm::StringRef) const",
    "llvm::Module::getMDKindID", "llvm::Module::getMDKindID(llvm::StringRef) const",
  ),
  (
    "_ZN5test31hIiTnDk1DIT_ELi0EEEvv", "void test3::h<int, 0>()", "test3::h<int, 0>",
    "void test3::h<int, 0>()",
  ),
  (
    "_ZN5test31fITnDk1CLi0EEEvv", "void test3::f<0>()", "test3::f<0>", "void test3::f<0>()",
  ),
  (
    "_ZN5test31iIiEEvDTnw_Dk1CpicvT__EEE", "void test3::i<int>(decltype(new C auto((int)())))",
    "test3::i<int>", "void test3::i<int>(decltype(new C auto((int)())))",
  ),
  (
    "_ZN5test31jIiEEvDTnw_DK1CpicvT__EEE", "void test3::j<int>(decltype(new C decltype(auto)((int)())))",
    "test3::j<int>", "void test3::j<int>(decltype(new C decltype(auto)((int)())))",
  ),
  (
    "_ZNK4llvm11LLVMContext14getMDKindNamesERNS_15SmallVectorImplINS_9StringRefEEE",
    "llvm::LLVMContext::getMDKindNames(llvm::SmallVectorImpl<llvm::StringRef>&) const",
    "llvm::LLVMContext::getMDKindNames", "llvm::LLVMContext::getMDKindNames(llvm::SmallVectorImpl<llvm::StringRef>&) const",
  ),
  (
    "_ZNK4llvm6Module14getMDKindNamesERNS_15SmallVectorImplINS_9StringRefEEE", "llvm::Module::getMDKindNames(llvm::SmallVectorImpl<llvm::StringRef>&) const",
    "llvm::Module::getMDKindNames", "llvm::Module::getMDKindNames(llvm::SmallVectorImpl<llvm::StringRef>&) const",
  ),
  (
    "_ZNK4llvm11LLVMContext11getMDKindIDENS_9StringRefE", "llvm::LLVMContext::getMDKindID(llvm::StringRef) const",
    "llvm::LLVMContext::getMDKindID", "llvm::LLVMContext::getMDKindID(llvm::StringRef) const",
  ),
  (
    "___Z2i_D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D", "___Z2i_D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D",
    "___Z2i_D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D", "___Z2i_D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D1D",
  ),
  (
    "___Z10blocksNRVOv_block_invoke", "invocation function for block in blocksNRVO()",
    "___Z10blocksNRVOv_block_invoke", "invocation function for block in blocksNRVO()",
  ),
  ("__Z1fv", "f()", "f", "f()"),
  (
    "_ZL18EnableARMTailCalls", "EnableARMTailCalls", "EnableARMTailCalls", "EnableARMTailCalls",
  ),
  (
    "_ZL21EnableFastISelVerbose", "EnableFastISelVerbose", "EnableFastISelVerbose",
    "EnableFastISelVerbose",
  ),
  (
    "_Z20EnableCodeCompletionRN5clang12PreprocessorERKSsjj", "EnableCodeCompletion(clang::Preprocessor&, std::string const&, unsigned int, unsigned int)",
    "EnableCodeCompletion", "EnableCodeCompletion(clang::Preprocessor&, std::string const&, unsigned int, unsigned int)",
  ),
  (
    "_ZN4llvm20CrashRecoveryContext6EnableEv", "llvm::CrashRecoveryContext::Enable()",
    "llvm::CrashRecoveryContext::Enable", "llvm::CrashRecoveryContext::Enable()",
  ),
  (
    "_ZL18EnableNoInfsFPMath", "EnableNoInfsFPMath", "EnableNoInfsFPMath", "EnableNoInfsFPMath",
  ),
  (
    "_ZNK4llvm17LLVMTargetMachine25getEnableTailMergeDefaultEv", "llvm::LLVMTargetMachine::getEnableTailMergeDefault() const",
    "llvm::LLVMTargetMachine::getEnableTailMergeDefault", "llvm::LLVMTargetMachine::getEnableTailMergeDefault() const",
  ),
  (
    "_ZL19FlagEnableTailMerge", "FlagEnableTailMerge", "FlagEnableTailMerge", "FlagEnableTailMerge",
  ),
  (
    "_ZN4llvm3sys4path6nativeERKNS_5TwineERNS_15SmallVectorImplIcEE", "llvm::sys::path::native(llvm::Twine const&, llvm::SmallVectorImpl<char>&)",
    "llvm::sys::path::native", "llvm::sys::path::native(llvm::Twine const&, llvm::SmallVectorImpl<char>&)",
  ),
  (
    "_ZZ7dlerrorE8__func__", "dlerror::__func__", "dlerror::__func__", "dlerror::__func__",
  ),
  (
    "_ZZ5dlsymE8__func__", "dlsym::__func__", "dlsym::__func__", "dlsym::__func__",
  ),
  (
    "_ZZ6dlopenE8__func__", "dlopen::__func__", "dlopen::__func__", "dlopen::__func__",
  ),
  (
    "_ZZ7dlcloseE8__func__", "dlclose::__func__", "dlclose::__func__", "dlclose::__func__",
  ),
  (
    "_ZZ16dlopen_preflightE8__func__", "dlopen_preflight::__func__", "dlopen_preflight::__func__",
    "dlopen_preflight::__func__",
  ),
  (
    "_ZZ6dladdrE8__func__", "dladdr::__func__", "dladdr::__func__", "dladdr::__func__",
  ),
  (
    "_ZN5clang6driver5tools6darwin4LipoD1Ev", "clang::driver::tools::darwin::Lipo::~Lipo()",
    "clang::driver::tools::darwin::Lipo::~Lipo", "clang::driver::tools::darwin::Lipo::~Lipo()",
  ),
  (
    "_ZNK5clang6driver5tools6darwin4Link16hasIntegratedCPPEv", "clang::driver::tools::darwin::Link::hasIntegratedCPP() const",
    "clang::driver::tools::darwin::Link::hasIntegratedCPP", "clang::driver::tools::darwin::Link::hasIntegratedCPP() const",
  ),
  (
    "_ZNK5clang4ento7GRState3setIN12_GLOBAL__N_113CStringLengthEEEPKS1_NS0_12GRStateTraitIT_E9data_typeE",
    "clang::ento::GRState const* clang::ento::GRState::set<(anonymous namespace)::CStringLength>(clang::ento::GRStateTrait<(anonymous namespace)::CStringLength>::data_type) const",
    "clang::ento::GRState::set<(anonymous namespace)::CStringLength>", "clang::ento::GRState const* clang::ento::GRState::set<(anonymous namespace)::CStringLength>(clang::ento::GRStateTrait<(anonymous namespace)::CStringLength>::data_type) const",
  ),
  (
    "_ZN5clang6driver5tools6darwin3CC116getBaseInputNameERKNS0_7ArgListERKN4llvm11SmallVectorINS0_9InputInfoELj4EEE",
    "clang::driver::tools::darwin::CC1::getBaseInputName(clang::driver::ArgList const&, llvm::SmallVector<clang::driver::InputInfo, 4u> const&)",
    "clang::driver::tools::darwin::CC1::getBaseInputName", "clang::driver::tools::darwin::CC1::getBaseInputName(clang::driver::ArgList const&, llvm::SmallVector<clang::driver::InputInfo, 4u> const&)",
  ),
  (
    "_ZN5clang6driver5tools6darwin8DsymutilD1Ev", "clang::driver::tools::darwin::Dsymutil::~Dsymutil()",
    "clang::driver::tools::darwin::Dsymutil::~Dsymutil", "clang::driver::tools::darwin::Dsymutil::~Dsymutil()",
  ),
  (
    "_ZTVN5clang6driver5tools6darwin10DarwinToolE", "vtable for clang::driver::tools::darwin::DarwinTool",
    "vtable for clang::driver::tools::darwin::DarwinTool", "vtable for clang::driver::tools::darwin::DarwinTool",
  ),
  (
    "_ZN5clang6driver5tools6darwin10PreprocessD0Ev", "clang::driver::tools::darwin::Preprocess::~Preprocess()",
    "clang::driver::tools::darwin::Preprocess::~Preprocess", "clang::driver::tools::darwin::Preprocess::~Preprocess()",
  ),
  (
    "_ZN5clang6driver5tools6darwin8AssembleD1Ev", "clang::driver::tools::darwin::Assemble::~Assemble()",
    "clang::driver::tools::darwin::Assemble::~Assemble", "clang::driver::tools::darwin::Assemble::~Assemble()",
  ),
  (
    "_ZN4llvm12InstCombiner29SimplifyUsingDistributiveLawsERNS_14BinaryOperatorE",
    "llvm::InstCombiner::SimplifyUsingDistributiveLaws(llvm::BinaryOperator&)", "llvm::InstCombiner::SimplifyUsingDistributiveLaws",
    "llvm::InstCombiner::SimplifyUsingDistributiveLaws(llvm::BinaryOperator&)",
  ),
  (
    "_ZN5clang4ento10ExprEngine15VisitMemberExprEPKNS_10MemberExprEPNS0_12ExplodedNodeERNS0_15ExplodedNodeSetE",
    "clang::ento::ExprEngine::VisitMemberExpr(clang::MemberExpr const*, clang::ento::ExplodedNode*, clang::ento::ExplodedNodeSet&)",
    "clang::ento::ExprEngine::VisitMemberExpr", "clang::ento::ExprEngine::VisitMemberExpr(clang::MemberExpr const*, clang::ento::ExplodedNode*, clang::ento::ExplodedNodeSet&)",
  ),
  (
    "_ZN5clang4ento27RegisterArrayBoundCheckerV2ERNS0_10ExprEngineE", "clang::ento::RegisterArrayBoundCheckerV2(clang::ento::ExprEngine&)",
    "clang::ento::RegisterArrayBoundCheckerV2", "clang::ento::RegisterArrayBoundCheckerV2(clang::ento::ExprEngine&)",
  ),
  (
    "_ZN5clang4ento22RegisterCStringCheckerERNS0_10ExprEngineE", "clang::ento::RegisterCStringChecker(clang::ento::ExprEngine&)",
    "clang::ento::RegisterCStringChecker", "clang::ento::RegisterCStringChecker(clang::ento::ExprEngine&)",
  ),
  (
    "_ZN5clang4ento21RegisterNSErrorChecksERNS0_11BugReporterERNS0_10ExprEngineERKNS_4DeclE",
    "clang::ento::RegisterNSErrorChecks(clang::ento::BugReporter&, clang::ento::ExprEngine&, clang::Decl const&)",
    "clang::ento::RegisterNSErrorChecks", "clang::ento::RegisterNSErrorChecks(clang::ento::BugReporter&, clang::ento::ExprEngine&, clang::Decl const&)",
  ),
  (
    "_ZN5clang4ento10ExprEngine16VisitCXXThisExprEPKNS_11CXXThisExprEPNS0_12ExplodedNodeERNS0_15ExplodedNodeSetE",
    "clang::ento::ExprEngine::VisitCXXThisExpr(clang::CXXThisExpr const*, clang::ento::ExplodedNode*, clang::ento::ExplodedNodeSet&)",
    "clang::ento::ExprEngine::VisitCXXThisExpr", "clang::ento::ExprEngine::VisitCXXThisExpr(clang::CXXThisExpr const*, clang::ento::ExplodedNode*, clang::ento::ExplodedNodeSet&)",
  ),
  (
    "_ZN5clang4ento10ExprEngine14VisitBlockExprEPKNS_9BlockExprEPNS0_12ExplodedNodeERNS0_15ExplodedNodeSetE",
    "clang::ento::ExprEngine::VisitBlockExpr(clang::BlockExpr const*, clang::ento::ExplodedNode*, clang::ento::ExplodedNodeSet&)",
    "clang::ento::ExprEngine::VisitBlockExpr", "clang::ento::ExprEngine::VisitBlockExpr(clang::BlockExpr const*, clang::ento::ExplodedNode*, clang::ento::ExplodedNodeSet&)",
  ),
  (
    "_ZN5clang4ento34RegisterAdjustedReturnValueCheckerERNS0_10ExprEngineE", "clang::ento::RegisterAdjustedReturnValueChecker(clang::ento::ExprEngine&)",
    "clang::ento::RegisterAdjustedReturnValueChecker", "clang::ento::RegisterAdjustedReturnValueChecker(clang::ento::ExprEngine&)",
  ),
  (
    "_ZN5clang4ento10CoreEngine15HandleBlockExitEPKNS_8CFGBlockEPNS0_12ExplodedNodeE",
    "clang::ento::CoreEngine::HandleBlockExit(clang::CFGBlock const*, clang::ento::ExplodedNode*)",
    "clang::ento::CoreEngine::HandleBlockExit", "clang::ento::CoreEngine::HandleBlockExit(clang::CFGBlock const*, clang::ento::ExplodedNode*)",
  ),
  (
    "_ZN12_GLOBAL__N_112MemsetRanges8addStoreExPN4llvm9StoreInstE", "(anonymous namespace)::MemsetRanges::addStore(long long, llvm::StoreInst*)",
    "(anonymous namespace)::MemsetRanges::addStore", "(anonymous namespace)::MemsetRanges::addStore(long long, llvm::StoreInst*)",
  ),
  (
    "_ZN4llvm10DwarfDebug18addVariableAddressERPNS_11DbgVariableEPNS_3DIEEx", "llvm::DwarfDebug::addVariableAddress(llvm::DbgVariable*&, llvm::DIE*, long long)",
    "llvm::DwarfDebug::addVariableAddress", "llvm::DwarfDebug::addVariableAddress(llvm::DbgVariable*&, llvm::DIE*, long long)",
  ),
  (
    "_ZN12_GLOBAL__N_14NoAA14addEscapingUseERN4llvm3UseE", "(anonymous namespace)::NoAA::addEscapingUse(llvm::Use&)",
    "(anonymous namespace)::NoAA::addEscapingUse", "(anonymous namespace)::NoAA::addEscapingUse(llvm::Use&)",
  ),
  (
    "_ZN5clang11DocumentXML15addPtrAttributeEPKcPKNS_11DeclContextE", "clang::DocumentXML::addPtrAttribute(char const*, clang::DeclContext const*)",
    "clang::DocumentXML::addPtrAttribute", "clang::DocumentXML::addPtrAttribute(char const*, clang::DeclContext const*)",
  ),
  (
    "_ZN4llvm15DomTreeNodeBaseINS_17MachineBasicBlockEE8addChildEPS2_", "llvm::DomTreeNodeBase<llvm::MachineBasicBlock>::addChild(llvm::DomTreeNodeBase<llvm::MachineBasicBlock>*)",
    "llvm::DomTreeNodeBase<llvm::MachineBasicBlock>::addChild", "llvm::DomTreeNodeBase<llvm::MachineBasicBlock>::addChild(llvm::DomTreeNodeBase<llvm::MachineBasicBlock>*)",
  ),
  (
    "_ZN4llvm13LiveVariables11addNewBlockEPNS_17MachineBasicBlockES2_S2_", "llvm::LiveVariables::addNewBlock(llvm::MachineBasicBlock*, llvm::MachineBasicBlock*, llvm::MachineBasicBlock*)",
    "llvm::LiveVariables::addNewBlock", "llvm::LiveVariables::addNewBlock(llvm::MachineBasicBlock*, llvm::MachineBasicBlock*, llvm::MachineBasicBlock*)",
  ),
  (
    "_ZN4llvm14ImutAVLFactoryINS_16ImutKeyValueInfoIPvS2_EEE3addEPNS_11ImutAVLTreeIS3_EERKSt4pairIS2_S2_E",
    "llvm::ImutAVLFactory<llvm::ImutKeyValueInfo<void*, void*>>::add(llvm::ImutAVLTree<llvm::ImutKeyValueInfo<void*, void*>>*, std::pair<void*, void*> const&)",
    "llvm::ImutAVLFactory<llvm::ImutKeyValueInfo<void*, void*>>::add", "llvm::ImutAVLFactory<llvm::ImutKeyValueInfo<void*, void*>>::add(llvm::ImutAVLTree<llvm::ImutKeyValueInfo<void*, void*>>*, std::pair<void*, void*> const&)",
  ),
  (
    "_ZN5clang10ASTContext19addOverriddenMethodEPKNS_13CXXMethodDeclES3_", "clang::ASTContext::addOverriddenMethod(clang::CXXMethodDecl const*, clang::CXXMethodDecl const*)",
    "clang::ASTContext::addOverriddenMethod", "clang::ASTContext::addOverriddenMethod(clang::CXXMethodDecl const*, clang::CXXMethodDecl const*)",
  ),
  (
    "_ZN4llvm11ImutAVLTreeINS_16ImutIntervalInfoIN5clang4ento4SValEEEE7destroyEv",
    "llvm::ImutAVLTree<llvm::ImutIntervalInfo<clang::ento::SVal>>::destroy()", "llvm::ImutAVLTree<llvm::ImutIntervalInfo<clang::ento::SVal>>::destroy",
    "llvm::ImutAVLTree<llvm::ImutIntervalInfo<clang::ento::SVal>>::destroy()",
  ),
  (
    "_ZN4llvm12ilist_traitsINS_17MachineBasicBlockEE10deleteNodeEPS1_", "llvm::ilist_traits<llvm::MachineBasicBlock>::deleteNode(llvm::MachineBasicBlock*)",
    "llvm::ilist_traits<llvm::MachineBasicBlock>::deleteNode", "llvm::ilist_traits<llvm::MachineBasicBlock>::deleteNode(llvm::MachineBasicBlock*)",
  ),
  (
    "_ZN5clang12LookupResult11deletePathsEPNS_12CXXBasePathsE", "clang::LookupResult::deletePaths(clang::CXXBasePaths*)",
    "clang::LookupResult::deletePaths", "clang::LookupResult::deletePaths(clang::CXXBasePaths*)",
  ),
  (
    "_ZNSt5dequeIPN4llvm4LoopESaIS2_EE13_M_insert_auxESt15_Deque_iteratorIS2_RS2_PS2_EmRKS2_",
    "std::deque<llvm::Loop*, std::allocator<llvm::Loop*>>::_M_insert_aux(std::_Deque_iterator<llvm::Loop*, llvm::Loop*&, llvm::Loop**>, unsigned long, llvm::Loop* const&)",
    "std::deque<llvm::Loop*, std::allocator<llvm::Loop*>>::_M_insert_aux", "std::deque<llvm::Loop*, std::allocator<llvm::Loop*>>::_M_insert_aux(std::_Deque_iterator<llvm::Loop*, llvm::Loop*&, llvm::Loop**>, unsigned long, llvm::Loop* const&)",
  ),
  (
    "_ZNSt5dequeIPN5clang6Parser12ParsingClassESaIS3_EE9push_backERKS3_", "std::deque<clang::Parser::ParsingClass*, std::allocator<clang::Parser::ParsingClass*>>::push_back(clang::Parser::ParsingClass* const&)",
    "std::deque<clang::Parser::ParsingClass*, std::allocator<clang::Parser::ParsingClass*>>::push_back",
    "std::deque<clang::Parser::ParsingClass*, std::allocator<clang::Parser::ParsingClass*>>::push_back(clang::Parser::ParsingClass* const&)",
  ),
  (
    "_ZN4llvm12BlockAddress15destroyConstantEv", "llvm::BlockAddress::destroyConstant()",
    "llvm::BlockAddress::destroyConstant", "llvm::BlockAddress::destroyConstant()",
  ),
  (
    "_ZL15defaultRegAlloc", "defaultRegAlloc", "defaultRegAlloc", "defaultRegAlloc",
  ),
  (
    "_ZNSt5dequeIPKN5clang4StmtESaIS3_EE9push_backERKS3_", "std::deque<clang::Stmt const*, std::allocator<clang::Stmt const*>>::push_back(clang::Stmt const* const&)",
    "std::deque<clang::Stmt const*, std::allocator<clang::Stmt const*>>::push_back",
    "std::deque<clang::Stmt const*, std::allocator<clang::Stmt const*>>::push_back(clang::Stmt const* const&)",
  ),
  (
    "_ZNK12_GLOBAL__N_113MBlazeABIInfo11computeInfoERN5clang7CodeGen14CGFunctionInfoE",
    "(anonymous namespace)::MBlazeABIInfo::computeInfo(clang::CodeGen::CGFunctionInfo&) const",
    "(anonymous namespace)::MBlazeABIInfo::computeInfo", "(anonymous namespace)::MBlazeABIInfo::computeInfo(clang::CodeGen::CGFunctionInfo&) const",
  ),
  (
    "_ZN4llvm3sys2fs9copy_fileERKNS_5TwineES4_NS1_11copy_optionE", "llvm::sys::fs::copy_file(llvm::Twine const&, llvm::Twine const&, llvm::sys::fs::copy_option)",
    "llvm::sys::fs::copy_file", "llvm::sys::fs::copy_file(llvm::Twine const&, llvm::Twine const&, llvm::sys::fs::copy_option)",
  ),
  (
    "_ZNK4llvm18ARMGenRegisterInfo20composeSubRegIndicesEjj", "llvm::ARMGenRegisterInfo::composeSubRegIndices(unsigned int, unsigned int) const",
    "llvm::ARMGenRegisterInfo::composeSubRegIndices", "llvm::ARMGenRegisterInfo::composeSubRegIndices(unsigned int, unsigned int) const",
  ),
  (
    "_ZN4llvm10DwarfDebug24constructLexicalScopeDIEEPNS_8DbgScopeE", "llvm::DwarfDebug::constructLexicalScopeDIE(llvm::DbgScope*)",
    "llvm::DwarfDebug::constructLexicalScopeDIE", "llvm::DwarfDebug::constructLexicalScopeDIE(llvm::DbgScope*)",
  ),
  (
    "_ZN4llvm12InstCombiner20commonIDivTransformsERNS_14BinaryOperatorE", "llvm::InstCombiner::commonIDivTransforms(llvm::BinaryOperator&)",
    "llvm::InstCombiner::commonIDivTransforms", "llvm::InstCombiner::commonIDivTransforms(llvm::BinaryOperator&)",
  ),
  (
    "_ZNK12_GLOBAL__N_113X86TargetInfo17convertConstraintEc", "(anonymous namespace)::X86TargetInfo::convertConstraint(char) const",
    "(anonymous namespace)::X86TargetInfo::convertConstraint", "(anonymous namespace)::X86TargetInfo::convertConstraint(char) const",
  ),
  (
    "_ZN4llvm14TargetLowering25computeRegisterPropertiesEv", "llvm::TargetLowering::computeRegisterProperties()",
    "llvm::TargetLowering::computeRegisterProperties", "llvm::TargetLowering::computeRegisterProperties()",
  ),
  ("_ZSt4cout", "std::cout", "std::cout", "std::cout"),
  (
    "_Z6foldl1IJLi1ELi2ELi3EEEv1AIXfLplLi1ET_EE", "void foldl1<1, 2, 3>(A<(1 + ... + (1, 2, 3))>)",
    "foldl1<1, 2, 3>", "void foldl1<1, 2, 3>(A<(1 + ... + (1, 2, 3))>)",
  ),
  (
    "_ZN8platform20split_string_convertIcPFiRKSsEiSaIiESt6vectorEEjPKT_S9_S7_T0_RT3_IT1_T2_E",
    "unsigned int platform::split_string_convert<char, int (*)(std::string const&), int, std::allocator<int>, std::vector>(char const*, char const*, char, int (*)(std::string const&), std::vector<int, std::allocator<int>>&)",
    "platform::split_string_convert<char, int (*)(std::string const&), int, std::allocator<int>, std::vector>",
    "unsigned int platform::split_string_convert<char, int (*)(std::string const&), int, std::allocator<int>, std::vector>(char const*, char const*, char, int (*)(std::string const&), std::vector<int, std::allocator<int>>&)",
  ),
  (
    "_ZN11Expressions2f4ILi1EEEvPAplLi2EplT_T__i", "void Expressions::f4<1>(int (*) [2 + (1 + 1)])",
    "Expressions::f4<1>", "void Expressions::f4<1>(int (*) [2 + (1 + 1)])",
  ),
  (
    "_ZN4llvm3PEI22placeSpillsAndRestoresERNS_15MachineFunctionE", "llvm::PEI::placeSpillsAndRestores(llvm::MachineFunction&)",
    "llvm::PEI::placeSpillsAndRestores", "llvm::PEI::placeSpillsAndRestores(llvm::MachineFunction&)",
  ),
  (
    "_ZN7PartialIJLi1ELi2EEE5foldrIJLi3ELi4EEEEv1AIXplLi1EplLi2EfRplT_plLi1EplLi2EfrplT_EE",
    "void Partial<1, 2>::foldr<3, 4>(A<1 + (2 + ((3, 4) + ... + (1 + (2 + ((3, 4) + ...)))))>)",
    "Partial<1, 2>::foldr<3, 4>", "void Partial<1, 2>::foldr<3, 4>(A<1 + (2 + ((3, 4) + ... + (1 + (2 + ((3, 4) + ...)))))>)",
  ),
  (
    "_ZN4llvm3PEI25placeCSRSpillsAndRestoresERNS_15MachineFunctionE", "llvm::PEI::placeCSRSpillsAndRestores(llvm::MachineFunction&)",
    "llvm::PEI::placeCSRSpillsAndRestores", "llvm::PEI::placeCSRSpillsAndRestores(llvm::MachineFunction&)",
  ),
  (
    "_ZN4llvm10DwarfDebug16EmitDebugARangesEv", "llvm::DwarfDebug::EmitDebugARanges()",
    "llvm::DwarfDebug::EmitDebugARanges", "llvm::DwarfDebug::EmitDebugARanges()",
  ),
  (
    "_Z22EmitFunctionDeclLValueRN5clang7CodeGen15CodeGenFunctionEPKNS_4ExprEPKNS_12FunctionDeclE",
    "EmitFunctionDeclLValue(clang::CodeGen::CodeGenFunction&, clang::Expr const*, clang::FunctionDecl const*)",
    "EmitFunctionDeclLValue", "EmitFunctionDeclLValue(clang::CodeGen::CodeGenFunction&, clang::Expr const*, clang::FunctionDecl const*)",
  ),
  (
    "_ZN5clang7CodeGen15CodeGenFunction11EmitForStmtERKNS_7ForStmtE", "clang::CodeGen::CodeGenFunction::EmitForStmt(clang::ForStmt const&)",
    "clang::CodeGen::CodeGenFunction::EmitForStmt", "clang::CodeGen::CodeGenFunction::EmitForStmt(clang::ForStmt const&)",
  ),
  (
    "_ZN12_GLOBAL__N_113MCAsmStreamer14EmitAssignmentEPN4llvm8MCSymbolEPKNS1_6MCExprE",
    "(anonymous namespace)::MCAsmStreamer::EmitAssignment(llvm::MCSymbol*, llvm::MCExpr const*)",
    "(anonymous namespace)::MCAsmStreamer::EmitAssignment", "(anonymous namespace)::MCAsmStreamer::EmitAssignment(llvm::MCSymbol*, llvm::MCExpr const*)",
  ),
  (
    "_ZN5clang7CodeGen15CodeGenFunction13EmitStopPointEPKNS_4StmtE", "clang::CodeGen::CodeGenFunction::EmitStopPoint(clang::Stmt const*)",
    "clang::CodeGen::CodeGenFunction::EmitStopPoint", "clang::CodeGen::CodeGenFunction::EmitStopPoint(clang::Stmt const*)",
  ),
  (
    "_ZNK4llvm10AsmPrinter13EmitAlignmentEjPKNS_11GlobalValueE", "llvm::AsmPrinter::EmitAlignment(unsigned int, llvm::GlobalValue const*) const",
    "llvm::AsmPrinter::EmitAlignment", "llvm::AsmPrinter::EmitAlignment(unsigned int, llvm::GlobalValue const*) const",
  ),
  (
    "_ZN12_GLOBAL__N_115WinCOFFStreamer19EmitSymbolAttributeEPN4llvm8MCSymbolENS1_12MCSymbolAttrE",
    "(anonymous namespace)::WinCOFFStreamer::EmitSymbolAttribute(llvm::MCSymbol*, llvm::MCSymbolAttr)",
    "(anonymous namespace)::WinCOFFStreamer::EmitSymbolAttribute", "(anonymous namespace)::WinCOFFStreamer::EmitSymbolAttribute(llvm::MCSymbol*, llvm::MCSymbolAttr)",
  ),
  (
    "_ZTVN5clang13EmitObjActionE", "vtable for clang::EmitObjAction", "vtable for clang::EmitObjAction",
    "vtable for clang::EmitObjAction",
  ),
  (
    "_ZNK12_GLOBAL__N_118BlackfinTargetInfo16getTargetDefinesERKN5clang11LangOptionsERNS1_12MacroBuilderE",
    "(anonymous namespace)::BlackfinTargetInfo::getTargetDefines(clang::LangOptions const&, clang::MacroBuilder&) const",
    "(anonymous namespace)::BlackfinTargetInfo::getTargetDefines", "(anonymous namespace)::BlackfinTargetInfo::getTargetDefines(clang::LangOptions const&, clang::MacroBuilder&) const",
  ),
  (
    "_ZN5clang5LexerC2ENS_14SourceLocationERKNS_11LangOptionsEPKcS6_S6_", "clang::Lexer::Lexer(clang::SourceLocation, clang::LangOptions const&, char const*, char const*, char const*)",
    "clang::Lexer::Lexer", "clang::Lexer::Lexer(clang::SourceLocation, clang::LangOptions const&, char const*, char const*, char const*)",
  ),
  (
    "_ZNK12_GLOBAL__N_113TCETargetInfo16getTargetDefinesERKN5clang11LangOptionsERNS1_12MacroBuilderE",
    "(anonymous namespace)::TCETargetInfo::getTargetDefines(clang::LangOptions const&, clang::MacroBuilder&) const",
    "(anonymous namespace)::TCETargetInfo::getTargetDefines", "(anonymous namespace)::TCETargetInfo::getTargetDefines(clang::LangOptions const&, clang::MacroBuilder&) const",
  ),
  (
    "_ZNK5clang14analyze_printf15PrintfSpecifier8toStringERN4llvm11raw_ostreamE",
    "clang::analyze_printf::PrintfSpecifier::toString(llvm::raw_ostream&) const",
    "clang::analyze_printf::PrintfSpecifier::toString", "clang::analyze_printf::PrintfSpecifier::toString(llvm::raw_ostream&) const",
  ),
  (
    "_ZN5clang18CreateObjCRewriterERKSsPN4llvm11raw_ostreamERNS_10DiagnosticERKNS_11LangOptionsEb",
    "clang::CreateObjCRewriter(std::string const&, llvm::raw_ostream*, clang::Diagnostic&, clang::LangOptions const&, bool)",
    "clang::CreateObjCRewriter", "clang::CreateObjCRewriter(std::string const&, llvm::raw_ostream*, clang::Diagnostic&, clang::LangOptions const&, bool)",
  ),
  (
    "_ZN5clang5LexerC2ENS_6FileIDEPKN4llvm12MemoryBufferERKNS_13SourceManagerERKNS_11LangOptionsE",
    "clang::Lexer::Lexer(clang::FileID, llvm::MemoryBuffer const*, clang::SourceManager const&, clang::LangOptions const&)",
    "clang::Lexer::Lexer", "clang::Lexer::Lexer(clang::FileID, llvm::MemoryBuffer const*, clang::SourceManager const&, clang::LangOptions const&)",
  ),
  (
    "_ZN5clang21analyze_format_string19FormatStringHandler21HandleInvalidPositionEPKcjNS0_15PositionContextE",
    "clang::analyze_format_string::FormatStringHandler::HandleInvalidPosition(char const*, unsigned int, clang::analyze_format_string::PositionContext)",
    "clang::analyze_format_string::FormatStringHandler::HandleInvalidPosition", "clang::analyze_format_string::FormatStringHandler::HandleInvalidPosition(char const*, unsigned int, clang::analyze_format_string::PositionContext)",
  ),
  (
    "_ZN5clang13FixItRewriterC1ERNS_10DiagnosticERNS_13SourceManagerERKNS_11LangOptionsEPNS_12FixItOptionsE",
    "clang::FixItRewriter::FixItRewriter(clang::Diagnostic&, clang::SourceManager&, clang::LangOptions const&, clang::FixItOptions*)",
    "clang::FixItRewriter::FixItRewriter", "clang::FixItRewriter::FixItRewriter(clang::Diagnostic&, clang::SourceManager&, clang::LangOptions const&, clang::FixItOptions*)",
  ),
  (
    "_ZNK4llvm7APFloat24convertNormalToHexStringEPcjbNS0_12roundingModeE", "llvm::APFloat::convertNormalToHexString(char*, unsigned int, bool, llvm::APFloat::roundingMode) const",
    "llvm::APFloat::convertNormalToHexString", "llvm::APFloat::convertNormalToHexString(char*, unsigned int, bool, llvm::APFloat::roundingMode) const",
  ),
  (
    "_ZNK5clang10TargetInfo28getNormalizedGCCRegisterNameEN4llvm9StringRefE", "clang::TargetInfo::getNormalizedGCCRegisterName(llvm::StringRef) const",
    "clang::TargetInfo::getNormalizedGCCRegisterName", "clang::TargetInfo::getNormalizedGCCRegisterName(llvm::StringRef) const",
  ),
  (
    "_ZN5clang7CodeGen15CodeGenFunction24getNormalCleanupDestSlotEv", "clang::CodeGen::CodeGenFunction::getNormalCleanupDestSlot()",
    "clang::CodeGen::CodeGenFunction::getNormalCleanupDestSlot", "clang::CodeGen::CodeGenFunction::getNormalCleanupDestSlot()",
  ),
  (
    "_ZN4llvm7APFloat21getSmallestNormalizedERKNS_12fltSemanticsEb", "llvm::APFloat::getSmallestNormalized(llvm::fltSemantics const&, bool)",
    "llvm::APFloat::getSmallestNormalized", "llvm::APFloat::getSmallestNormalized(llvm::fltSemantics const&, bool)",
  ),
  (
    "_ZN4llvm16DAGTypeLegalizer20ExpandRes_NormalLoadEPNS_6SDNodeERNS_7SDValueES4_",
    "llvm::DAGTypeLegalizer::ExpandRes_NormalLoad(llvm::SDNode*, llvm::SDValue&, llvm::SDValue&)",
    "llvm::DAGTypeLegalizer::ExpandRes_NormalLoad", "llvm::DAGTypeLegalizer::ExpandRes_NormalLoad(llvm::SDNode*, llvm::SDValue&, llvm::SDValue&)",
  ),
  (
    "_ZN5clang24NormalizeDashIncludePathEN4llvm9StringRefE", "clang::NormalizeDashIncludePath(llvm::StringRef)",
    "clang::NormalizeDashIncludePath", "clang::NormalizeDashIncludePath(llvm::StringRef)",
  ),
  (
    "_ZN4llvm16DAGTypeLegalizer20ExpandOp_NormalStoreEPNS_6SDNodeEj", "llvm::DAGTypeLegalizer::ExpandOp_NormalStore(llvm::SDNode*, unsigned int)",
    "llvm::DAGTypeLegalizer::ExpandOp_NormalStore", "llvm::DAGTypeLegalizer::ExpandOp_NormalStore(llvm::SDNode*, unsigned int)",
  ),
  ("_ZL13NormalPrinter", "NormalPrinter", "NormalPrinter", "NormalPrinter"),
  (
    "_Z24HandleNeonVectorTypeAttrRN5clang8QualTypeERKNS_13AttributeListERNS_4SemaENS_10VectorType10VectorKindEPKc",
    "HandleNeonVectorTypeAttr(clang::QualType&, clang::AttributeList const&, clang::Sema&, clang::VectorType::VectorKind, char const*)",
    "HandleNeonVectorTypeAttr", "HandleNeonVectorTypeAttr(clang::QualType&, clang::AttributeList const&, clang::Sema&, clang::VectorType::VectorKind, char const*)",
  ),
  (
    "_ZN5clang7CodeGen15CodeGenFunction19EmitNeonShiftVectorEPN4llvm5ValueEPKNS2_4TypeEb",
    "clang::CodeGen::CodeGenFunction::EmitNeonShiftVector(llvm::Value*, llvm::Type const*, bool)",
    "clang::CodeGen::CodeGenFunction::EmitNeonShiftVector", "clang::CodeGen::CodeGenFunction::EmitNeonShiftVector(llvm::Value*, llvm::Type const*, bool)",
  ),
  (
    "_ZN5clang7CodeGen15CodeGenFunction12EmitNeonCallEPN4llvm8FunctionERNS2_15SmallVectorImplIPNS2_5ValueEEEPKcjb",
    "clang::CodeGen::CodeGenFunction::EmitNeonCall(llvm::Function*, llvm::SmallVectorImpl<llvm::Value*>&, char const*, unsigned int, bool)",
    "clang::CodeGen::CodeGenFunction::EmitNeonCall", "clang::CodeGen::CodeGenFunction::EmitNeonCall(llvm::Function*, llvm::SmallVectorImpl<llvm::Value*>&, char const*, unsigned int, bool)",
  ),
  (
    "_ZN5clang7CodeGen15CodeGenFunction13EmitNeonSplatEPN4llvm5ValueEPNS2_8ConstantE",
    "clang::CodeGen::CodeGenFunction::EmitNeonSplat(llvm::Value*, llvm::Constant*)",
    "clang::CodeGen::CodeGenFunction::EmitNeonSplat", "clang::CodeGen::CodeGenFunction::EmitNeonSplat(llvm::Value*, llvm::Constant*)",
  ),
  (
    "_ZN4llvm15SmallVectorImplINS_4SDepEEaSERKS2_", "llvm::SmallVectorImpl<llvm::SDep>::operator=(llvm::SmallVectorImpl<llvm::SDep> const&)",
    "llvm::SmallVectorImpl<llvm::SDep>::operator=", "llvm::SmallVectorImpl<llvm::SDep>::operator=(llvm::SmallVectorImpl<llvm::SDep> const&)",
  ),
  (
    "_ZN4llvm15SmallVectorImplISt4pairIPNS_15DomTreeNodeBaseINS_10BasicBlockEEEjEEaSERKS7_",
    "llvm::SmallVectorImpl<std::pair<llvm::DomTreeNodeBase<llvm::BasicBlock>*, unsigned int>>::operator=(llvm::SmallVectorImpl<std::pair<llvm::DomTreeNodeBase<llvm::BasicBlock>*, unsigned int>> const&)",
    "llvm::SmallVectorImpl<std::pair<llvm::DomTreeNodeBase<llvm::BasicBlock>*, unsigned int>>::operator=",
    "llvm::SmallVectorImpl<std::pair<llvm::DomTreeNodeBase<llvm::BasicBlock>*, unsigned int>>::operator=(llvm::SmallVectorImpl<std::pair<llvm::DomTreeNodeBase<llvm::BasicBlock>*, unsigned int>> const&)",
  ),
  (
    "_ZN4llvm15SmallVectorImplIPN5clang9NamedDeclEEaSERKS4_", "llvm::SmallVectorImpl<clang::NamedDecl*>::operator=(llvm::SmallVectorImpl<clang::NamedDecl*> const&)",
    "llvm::SmallVectorImpl<clang::NamedDecl*>::operator=", "llvm::SmallVectorImpl<clang::NamedDecl*>::operator=(llvm::SmallVectorImpl<clang::NamedDecl*> const&)",
  ),
  (
    "_ZN4llvm15SmallVectorImplIPKNS_4SCEVEEaSERKS4_", "llvm::SmallVectorImpl<llvm::SCEV const*>::operator=(llvm::SmallVectorImpl<llvm::SCEV const*> const&)",
    "llvm::SmallVectorImpl<llvm::SCEV const*>::operator=", "llvm::SmallVectorImpl<llvm::SCEV const*>::operator=(llvm::SmallVectorImpl<llvm::SCEV const*> const&)",
  ),
  (
    "_ZNSt6vectorIN4llvm11MachineMoveESaIS1_EEaSERKS3_", "std::vector<llvm::MachineMove, std::allocator<llvm::MachineMove>>::operator=(std::vector<llvm::MachineMove, std::allocator<llvm::MachineMove>> const&)",
    "std::vector<llvm::MachineMove, std::allocator<llvm::MachineMove>>::operator=",
    "std::vector<llvm::MachineMove, std::allocator<llvm::MachineMove>>::operator=(std::vector<llvm::MachineMove, std::allocator<llvm::MachineMove>> const&)",
  ),
  (
    "_ZN4llvm15SmallVectorImplINS_14MachineOperandEEaSERKS2_", "llvm::SmallVectorImpl<llvm::MachineOperand>::operator=(llvm::SmallVectorImpl<llvm::MachineOperand> const&)",
    "llvm::SmallVectorImpl<llvm::MachineOperand>::operator=", "llvm::SmallVectorImpl<llvm::MachineOperand>::operator=(llvm::SmallVectorImpl<llvm::MachineOperand> const&)",
  ),
  (
    "_ZN4llvm15SmallVectorImplIPKcEaSERKS3_", "llvm::SmallVectorImpl<char const*>::operator=(llvm::SmallVectorImpl<char const*> const&)",
    "llvm::SmallVectorImpl<char const*>::operator=", "llvm::SmallVectorImpl<char const*>::operator=(llvm::SmallVectorImpl<char const*> const&)",
  ),
  (
    "_ZN4llvm15SmallVectorImplIPNS_11InstructionEEaSERKS3_", "llvm::SmallVectorImpl<llvm::Instruction*>::operator=(llvm::SmallVectorImpl<llvm::Instruction*> const&)",
    "llvm::SmallVectorImpl<llvm::Instruction*>::operator=", "llvm::SmallVectorImpl<llvm::Instruction*>::operator=(llvm::SmallVectorImpl<llvm::Instruction*> const&)",
  ),
  (
    "_ZN4llvm12NoNaNsFPMathE", "llvm::NoNaNsFPMath", "llvm::NoNaNsFPMath", "llvm::NoNaNsFPMath",
  ),
  (
    "_ZNK4llvm12SelectionDAG15isKnownNeverNaNENS_7SDValueE", "llvm::SelectionDAG::isKnownNeverNaN(llvm::SDValue) const",
    "llvm::SelectionDAG::isKnownNeverNaN", "llvm::SelectionDAG::isKnownNeverNaN(llvm::SDValue) const",
  ),
  (
    "_Z21TryEvaluateBuiltinNaNRKN5clang10ASTContextENS_8QualTypeEPKNS_4ExprEbRN4llvm7APFloatE",
    "TryEvaluateBuiltinNaN(clang::ASTContext const&, clang::QualType, clang::Expr const*, bool, llvm::APFloat&)",
    "TryEvaluateBuiltinNaN", "TryEvaluateBuiltinNaN(clang::ASTContext const&, clang::QualType, clang::Expr const*, bool, llvm::APFloat&)",
  ),
  (
    "_ZN4llvm7APFloat7makeNaNERKNS_12fltSemanticsEbbPKNS_5APIntE", "llvm::APFloat::makeNaN(llvm::fltSemantics const&, bool, bool, llvm::APInt const*)",
    "llvm::APFloat::makeNaN", "llvm::APFloat::makeNaN(llvm::fltSemantics const&, bool, bool, llvm::APInt const*)",
  ),
  (
    "_ZN4llvm15SparseBitVectorILj128EEaNERKS1_", "llvm::SparseBitVector<128u>::operator&=(llvm::SparseBitVector<128u> const&)",
    "llvm::SparseBitVector<128u>::operator&=", "llvm::SparseBitVector<128u>::operator&=(llvm::SparseBitVector<128u> const&)",
  ),
  (
    "_ZN4llvm7APFloat7makeNaNEbbPKNS_5APIntE", "llvm::APFloat::makeNaN(bool, bool, llvm::APInt const*)",
    "llvm::APFloat::makeNaN", "llvm::APFloat::makeNaN(bool, bool, llvm::APInt const*)",
  ),
  ("_ZL4NaNU", "NaNU", "NaNU", "NaNU"),
  (
    "_ZL18EnableNoNaNsFPMath", "EnableNoNaNsFPMath", "EnableNoNaNsFPMath", "EnableNoNaNsFPMath",
  ),
  (
    "_ZTVN5clang12NoReturnAttrE", "vtable for clang::NoReturnAttr", "vtable for clang::NoReturnAttr",
    "vtable for clang::NoReturnAttr",
  ),
  (
    "_ZN5clang20IsNoReturnConversionERNS_10ASTContextENS_8QualTypeES2_RS2_", "clang::IsNoReturnConversion(clang::ASTContext&, clang::QualType, clang::QualType, clang::QualType&)",
    "clang::IsNoReturnConversion", "clang::IsNoReturnConversion(clang::ASTContext&, clang::QualType, clang::QualType, clang::QualType&)",
  ),
  (
    "_ZTVN5clang4ento14CheckerVisitorIN12_GLOBAL__N_123NoReturnFunctionCheckerEEE",
    "vtable for clang::ento::CheckerVisitor<(anonymous namespace)::NoReturnFunctionChecker>",
    "vtable for clang::ento::CheckerVisitor<(anonymous namespace)::NoReturnFunctionChecker>",
    "vtable for clang::ento::CheckerVisitor<(anonymous namespace)::NoReturnFunctionChecker>",
  ),
  (
    "_ZNK5clang4Decl7getAttrINS_12NoReturnAttrEEEPT_v", "clang::NoReturnAttr* clang::Decl::getAttr<clang::NoReturnAttr>() const",
    "clang::Decl::getAttr<clang::NoReturnAttr>", "clang::NoReturnAttr* clang::Decl::getAttr<clang::NoReturnAttr>() const",
  ),
  (
    "_ZZN4llvm14f64AssignAAPCSERjRNS_3MVTES2_RNS_11CCValAssign7LocInfoERNS_7CCStateEbE9LoRegList",
    "llvm::f64AssignAAPCS(unsigned int&, llvm::MVT&, llvm::MVT&, llvm::CCValAssign::LocInfo&, llvm::CCState&, bool)::LoRegList",
    "llvm::f64AssignAAPCS(unsigned int&, llvm::MVT&, llvm::MVT&, llvm::CCValAssign::LocInfo&, llvm::CCState&, bool)::LoRegList",
    "llvm::f64AssignAAPCS(unsigned int&, llvm::MVT&, llvm::MVT&, llvm::CCValAssign::LocInfo&, llvm::CCState&, bool)::LoRegList",
  ),
  (
    "_ZN5clang4Sema17CheckNoReturnAttrERKNS_13AttributeListE", "clang::Sema::CheckNoReturnAttr(clang::AttributeList const&)",
    "clang::Sema::CheckNoReturnAttr", "clang::Sema::CheckNoReturnAttr(clang::AttributeList const&)",
  ),
  (
    "_ZN5clang4ento31RegisterNoReturnFunctionCheckerERNS0_10ExprEngineE", "clang::ento::RegisterNoReturnFunctionChecker(clang::ento::ExprEngine&)",
    "clang::ento::RegisterNoReturnFunctionChecker", "clang::ento::RegisterNoReturnFunctionChecker(clang::ento::ExprEngine&)",
  ),
  (
    "_ZN5clang12NoReturnAttrD0Ev", "clang::NoReturnAttr::~NoReturnAttr()", "clang::NoReturnAttr::~NoReturnAttr",
    "clang::NoReturnAttr::~NoReturnAttr()",
  ),
  (
    "_ZNK4llvm13ConstantRange4lshrERKS0_", "llvm::ConstantRange::lshr(llvm::ConstantRange const&) const",
    "llvm::ConstantRange::lshr", "llvm::ConstantRange::lshr(llvm::ConstantRange const&) const",
  ),
  (
    "_ZNK4llvm5APInt4lshrEj", "llvm::APInt::lshr(unsigned int) const", "llvm::APInt::lshr",
    "llvm::APInt::lshr(unsigned int) const",
  ),
  (
    "_ZN5clang12Preprocessor19HandleElseDirectiveERNS_5TokenE", "clang::Preprocessor::HandleElseDirective(clang::Token&)",
    "clang::Preprocessor::HandleElseDirective", "clang::Preprocessor::HandleElseDirective(clang::Token&)",
  ),
  (
    "_ZN5clang11PPCallbacks4ElseEv", "clang::PPCallbacks::Else()", "clang::PPCallbacks::Else",
    "clang::PPCallbacks::Else()",
  ),
  (
    "_ZN5clang18PPChainedCallbacks4ElseEv", "clang::PPChainedCallbacks::Else()",
    "clang::PPChainedCallbacks::Else", "clang::PPChainedCallbacks::Else()",
  ),
  (
    "_ZNK4llvm5APInt4lshrERKS0_", "llvm::APInt::lshr(llvm::APInt const&) const",
    "llvm::APInt::lshr", "llvm::APInt::lshr(llvm::APInt const&) const",
  ),
  (
    "_ZSt13__adjust_heapIPSt4pairIPN4llvm10BasicBlockEPNS1_5ValueEElS6_EvT_T0_S9_T1_",
    "void std::__adjust_heap<std::pair<llvm::BasicBlock*, llvm::Value*>*, long, std::pair<llvm::BasicBlock*, llvm::Value*>>(std::pair<llvm::BasicBlock*, llvm::Value*>*, long, long, std::pair<llvm::BasicBlock*, llvm::Value*>)",
    "std::__adjust_heap<std::pair<llvm::BasicBlock*, llvm::Value*>*, long, std::pair<llvm::BasicBlock*, llvm::Value*>>",
    "void std::__adjust_heap<std::pair<llvm::BasicBlock*, llvm::Value*>*, long, std::pair<llvm::BasicBlock*, llvm::Value*>>(std::pair<llvm::BasicBlock*, llvm::Value*>*, long, long, std::pair<llvm::BasicBlock*, llvm::Value*>)",
  ),
  (
    "_ZSt13__adjust_heapIPPN4llvm12LiveIntervalElS2_NS0_11greater_ptrIS1_EEEvT_T0_S7_T1_T2_",
    "void std::__adjust_heap<llvm::LiveInterval**, long, llvm::LiveInterval*, llvm::greater_ptr<llvm::LiveInterval>>(llvm::LiveInterval**, long, long, llvm::LiveInterval*, llvm::greater_ptr<llvm::LiveInterval>)",
    "std::__adjust_heap<llvm::LiveInterval**, long, llvm::LiveInterval*, llvm::greater_ptr<llvm::LiveInterval>>",
    "void std::__adjust_heap<llvm::LiveInterval**, long, llvm::LiveInterval*, llvm::greater_ptr<llvm::LiveInterval>>(llvm::LiveInterval**, long, long, llvm::LiveInterval*, llvm::greater_ptr<llvm::LiveInterval>)",
  ),
  (
    "_ZSt13__adjust_heapIPSt4pairIjPN4llvm9StoreInstEElS4_EvT_T0_S7_T1_", "void std::__adjust_heap<std::pair<unsigned int, llvm::StoreInst*>*, long, std::pair<unsigned int, llvm::StoreInst*>>(std::pair<unsigned int, llvm::StoreInst*>*, long, long, std::pair<unsigned int, llvm::StoreInst*>)",
    "std::__adjust_heap<std::pair<unsigned int, llvm::StoreInst*>*, long, std::pair<unsigned int, llvm::StoreInst*>>",
    "void std::__adjust_heap<std::pair<unsigned int, llvm::StoreInst*>*, long, std::pair<unsigned int, llvm::StoreInst*>>(std::pair<unsigned int, llvm::StoreInst*>*, long, long, std::pair<unsigned int, llvm::StoreInst*>)",
  ),
  (
    "_ZSt13__adjust_heapIPN4llvm9StringRefElS1_EvT_T0_S4_T1_", "void std::__adjust_heap<llvm::StringRef*, long, llvm::StringRef>(llvm::StringRef*, long, long, llvm::StringRef)",
    "std::__adjust_heap<llvm::StringRef*, long, llvm::StringRef>", "void std::__adjust_heap<llvm::StringRef*, long, llvm::StringRef>(llvm::StringRef*, long, long, llvm::StringRef)",
  ),
  (
    "_ZSt13__adjust_heapIPSt4pairIjPN4llvm10BasicBlockEElS4_EvT_T0_S7_T1_", "void std::__adjust_heap<std::pair<unsigned int, llvm::BasicBlock*>*, long, std::pair<unsigned int, llvm::BasicBlock*>>(std::pair<unsigned int, llvm::BasicBlock*>*, long, long, std::pair<unsigned int, llvm::BasicBlock*>)",
    "std::__adjust_heap<std::pair<unsigned int, llvm::BasicBlock*>*, long, std::pair<unsigned int, llvm::BasicBlock*>>",
    "void std::__adjust_heap<std::pair<unsigned int, llvm::BasicBlock*>*, long, std::pair<unsigned int, llvm::BasicBlock*>>(std::pair<unsigned int, llvm::BasicBlock*>*, long, long, std::pair<unsigned int, llvm::BasicBlock*>)",
  ),
  (
    "_ZSt13__adjust_heapIPPN4llvm12MachineInstrElS2_N12_GLOBAL__N_113OffsetCompareEEvT_T0_S7_T1_T2_",
    "void std::__adjust_heap<llvm::MachineInstr**, long, llvm::MachineInstr*, (anonymous namespace)::OffsetCompare>(llvm::MachineInstr**, long, long, llvm::MachineInstr*, (anonymous namespace)::OffsetCompare)",
    "std::__adjust_heap<llvm::MachineInstr**, long, llvm::MachineInstr*, (anonymous namespace)::OffsetCompare>",
    "void std::__adjust_heap<llvm::MachineInstr**, long, llvm::MachineInstr*, (anonymous namespace)::OffsetCompare>(llvm::MachineInstr**, long, long, llvm::MachineInstr*, (anonymous namespace)::OffsetCompare)",
  ),
  (
    "_ZSt13__adjust_heapIPPKN5clang4ExprElS3_N12_GLOBAL__N_18SLocSortEEvT_T0_S8_T1_T2_",
    "void std::__adjust_heap<clang::Expr const**, long, clang::Expr const*, (anonymous namespace)::SLocSort>(clang::Expr const**, long, long, clang::Expr const*, (anonymous namespace)::SLocSort)",
    "std::__adjust_heap<clang::Expr const**, long, clang::Expr const*, (anonymous namespace)::SLocSort>",
    "void std::__adjust_heap<clang::Expr const**, long, clang::Expr const*, (anonymous namespace)::SLocSort>(clang::Expr const**, long, long, clang::Expr const*, (anonymous namespace)::SLocSort)",
  ),
  (
    "_ZSt13__adjust_heapIPPN4llvm12LiveIntervalElS2_N12_GLOBAL__N_18LISorterEEvT_T0_S7_T1_T2_",
    "void std::__adjust_heap<llvm::LiveInterval**, long, llvm::LiveInterval*, (anonymous namespace)::LISorter>(llvm::LiveInterval**, long, long, llvm::LiveInterval*, (anonymous namespace)::LISorter)",
    "std::__adjust_heap<llvm::LiveInterval**, long, llvm::LiveInterval*, (anonymous namespace)::LISorter>",
    "void std::__adjust_heap<llvm::LiveInterval**, long, llvm::LiveInterval*, (anonymous namespace)::LISorter>(llvm::LiveInterval**, long, long, llvm::LiveInterval*, (anonymous namespace)::LISorter)",
  ),
  (
    "_ZNK4llvm15SparseBitVectorILj128EEeqERKS1_", "llvm::SparseBitVector<128u>::operator==(llvm::SparseBitVector<128u> const&) const",
    "llvm::SparseBitVector<128u>::operator==", "llvm::SparseBitVector<128u>::operator==(llvm::SparseBitVector<128u> const&) const",
  ),
  (
    "_ZNK4llvm14error_category10equivalentERKNS_10error_codeEi", "llvm::error_category::equivalent(llvm::error_code const&, int) const",
    "llvm::error_category::equivalent", "llvm::error_category::equivalent(llvm::error_code const&, int) const",
  ),
  (
    "_ZNK4llvm14error_category10equivalentEiRKNS_15error_conditionE", "llvm::error_category::equivalent(int, llvm::error_condition const&) const",
    "llvm::error_category::equivalent", "llvm::error_category::equivalent(int, llvm::error_condition const&) const",
  ),
  (
    "_ZN4llvm3sys2fs10equivalentERKNS_5TwineES4_Rb", "llvm::sys::fs::equivalent(llvm::Twine const&, llvm::Twine const&, bool&)",
    "llvm::sys::fs::equivalent", "llvm::sys::fs::equivalent(llvm::Twine const&, llvm::Twine const&, bool&)",
  ),
  (
    "_ZN9__gnu_cxx13new_allocatorIPKcE8allocateEmPKv", "__gnu_cxx::new_allocator<char const*>::allocate(unsigned long, void const*)",
    "__gnu_cxx::new_allocator<char const*>::allocate", "__gnu_cxx::new_allocator<char const*>::allocate(unsigned long, void const*)",
  ),
  (
    "_ZN5clang17ClassTemplateDecl9newCommonERNS_10ASTContextE", "clang::ClassTemplateDecl::newCommon(clang::ASTContext&)",
    "clang::ClassTemplateDecl::newCommon", "clang::ClassTemplateDecl::newCommon(clang::ASTContext&)",
  ),
  (
    "_ZN9__gnu_cxx13new_allocatorIN4llvm19SelectionDAGBuilder12BitTestBlockEE9constructEPS3_RKS3_",
    "__gnu_cxx::new_allocator<llvm::SelectionDAGBuilder::BitTestBlock>::construct(llvm::SelectionDAGBuilder::BitTestBlock*, llvm::SelectionDAGBuilder::BitTestBlock const&)",
    "__gnu_cxx::new_allocator<llvm::SelectionDAGBuilder::BitTestBlock>::construct",
    "__gnu_cxx::new_allocator<llvm::SelectionDAGBuilder::BitTestBlock>::construct(llvm::SelectionDAGBuilder::BitTestBlock*, llvm::SelectionDAGBuilder::BitTestBlock const&)",
  ),
  (
    "_ZN4llvm12PatternMatch9neg_matchINS0_7bind_tyINS_5ValueEEEE5matchINS_8ConstantEEEbPT_",
    "bool llvm::PatternMatch::neg_match<llvm::PatternMatch::bind_ty<llvm::Value>>::match<llvm::Constant>(llvm::Constant*)",
    "llvm::PatternMatch::neg_match<llvm::PatternMatch::bind_ty<llvm::Value>>::match<llvm::Constant>",
    "bool llvm::PatternMatch::neg_match<llvm::PatternMatch::bind_ty<llvm::Value>>::match<llvm::Constant>(llvm::Constant*)",
  ),
  (
    "_ZN9__gnu_cxx13new_allocatorI15dyld_image_infoE8allocateEmPKv", "__gnu_cxx::new_allocator<dyld_image_info>::allocate(unsigned long, void const*)",
    "__gnu_cxx::new_allocator<dyld_image_info>::allocate", "__gnu_cxx::new_allocator<dyld_image_info>::allocate(unsigned long, void const*)",
  ),
  (
    "_ZN9__gnu_cxx13new_allocatorIN11ImageLoader7DOFInfoEE8allocateEmPKv", "__gnu_cxx::new_allocator<ImageLoader::DOFInfo>::allocate(unsigned long, void const*)",
    "__gnu_cxx::new_allocator<ImageLoader::DOFInfo>::allocate", "__gnu_cxx::new_allocator<ImageLoader::DOFInfo>::allocate(unsigned long, void const*)",
  ),
  (
    "_ZN9__gnu_cxx13new_allocatorISt13_Rb_tree_nodeIPK11ImageLoaderEE8allocateEmPKv",
    "__gnu_cxx::new_allocator<std::_Rb_tree_node<ImageLoader const*>>::allocate(unsigned long, void const*)",
    "__gnu_cxx::new_allocator<std::_Rb_tree_node<ImageLoader const*>>::allocate",
    "__gnu_cxx::new_allocator<std::_Rb_tree_node<ImageLoader const*>>::allocate(unsigned long, void const*)",
  ),
  (
    "_ZN5clang7CodeGen15DominatingValueINS0_6RValueEE10saved_type11needsSavingES2_",
    "clang::CodeGen::DominatingValue<clang::CodeGen::RValue>::saved_type::needsSaving(clang::CodeGen::RValue)",
    "clang::CodeGen::DominatingValue<clang::CodeGen::RValue>::saved_type::needsSaving",
    "clang::CodeGen::DominatingValue<clang::CodeGen::RValue>::saved_type::needsSaving(clang::CodeGen::RValue)",
  ),
  (
    "_ZNK4llvm12BranchFolder18MergePotentialsEltltERKS1_", "llvm::BranchFolder::MergePotentialsElt::operator<(llvm::BranchFolder::MergePotentialsElt const&) const",
    "llvm::BranchFolder::MergePotentialsElt::operator<", "llvm::BranchFolder::MergePotentialsElt::operator<(llvm::BranchFolder::MergePotentialsElt const&) const",
  ),
  (
    "_Z19getShuffleScalarEltPN4llvm6SDNodeEiRNS_12SelectionDAGEj", "getShuffleScalarElt(llvm::SDNode*, int, llvm::SelectionDAG&, unsigned int)",
    "getShuffleScalarElt", "getShuffleScalarElt(llvm::SDNode*, int, llvm::SelectionDAG&, unsigned int)",
  ),
  (
    "_ZN4llvm12InstCombiner26SimplifyDemandedVectorEltsEPNS_5ValueENS_5APIntERS3_j",
    "llvm::InstCombiner::SimplifyDemandedVectorElts(llvm::Value*, llvm::APInt, llvm::APInt&, unsigned int)",
    "llvm::InstCombiner::SimplifyDemandedVectorElts", "llvm::InstCombiner::SimplifyDemandedVectorElts(llvm::Value*, llvm::APInt, llvm::APInt&, unsigned int)",
  ),
  (
    "_Z24EltsFromConsecutiveLoadsN4llvm3EVTERNS_15SmallVectorImplINS_7SDValueEEERNS_8DebugLocERNS_12SelectionDAGE",
    "EltsFromConsecutiveLoads(llvm::EVT, llvm::SmallVectorImpl<llvm::SDValue>&, llvm::DebugLoc&, llvm::SelectionDAG&)",
    "EltsFromConsecutiveLoads", "EltsFromConsecutiveLoads(llvm::EVT, llvm::SmallVectorImpl<llvm::SDValue>&, llvm::DebugLoc&, llvm::SelectionDAG&)",
  ),
  (
    "_ZN5Casts8implicitILj4EEEvPN9enable_ifIXngorLi0EgtT_Li4EEvE4typeE", "void Casts::implicit<4u>(enable_if<-(0 | 4u > 4), void>::type*)",
    "Casts::implicit<4u>", "void Casts::implicit<4u>(enable_if<-(0 | 4u > 4), void>::type*)",
  ),
  (
    "_ZNK4llvm17GetElementPtrInst10isInBoundsEv", "llvm::GetElementPtrInst::isInBounds() const",
    "llvm::GetElementPtrInst::isInBounds", "llvm::GetElementPtrInst::isInBounds() const",
  ),
  (
    "_ZNSt8_Rb_treeIN4llvm3sys4PathES2_St9_IdentityIS2_ESt4lessIS2_ESaIS2_EE8_M_eraseEPSt13_Rb_tree_nodeIS2_E",
    "std::_Rb_tree<llvm::sys::Path, llvm::sys::Path, std::_Identity<llvm::sys::Path>, std::less<llvm::sys::Path>, std::allocator<llvm::sys::Path>>::_M_erase(std::_Rb_tree_node<llvm::sys::Path>*)",
    "std::_Rb_tree<llvm::sys::Path, llvm::sys::Path, std::_Identity<llvm::sys::Path>, std::less<llvm::sys::Path>, std::allocator<llvm::sys::Path>>::_M_erase",
    "std::_Rb_tree<llvm::sys::Path, llvm::sys::Path, std::_Identity<llvm::sys::Path>, std::less<llvm::sys::Path>, std::allocator<llvm::sys::Path>>::_M_erase(std::_Rb_tree_node<llvm::sys::Path>*)",
  ),
  (
    "_Z20isSafeSROAElementUsePN4llvm5ValueE", "isSafeSROAElementUse(llvm::Value*)",
    "isSafeSROAElementUse", "isSafeSROAElementUse(llvm::Value*)",
  ),
  (
    "_ZN5clang13ASTStmtWriter25VisitExtVectorElementExprEPNS_20ExtVectorElementExprE",
    "clang::ASTStmtWriter::VisitExtVectorElementExpr(clang::ExtVectorElementExpr*)",
    "clang::ASTStmtWriter::VisitExtVectorElementExpr", "clang::ASTStmtWriter::VisitExtVectorElementExpr(clang::ExtVectorElementExpr*)",
  ),
  (
    "_ZNK5clang4ento13ElementRegion12getValueTypeEv", "clang::ento::ElementRegion::getValueType() const",
    "clang::ento::ElementRegion::getValueType", "clang::ento::ElementRegion::getValueType() const",
  ),
  (
    "_ZNSt8_Rb_treeIPN4llvm10BasicBlockES2_St9_IdentityIS2_ESt4lessIS2_ESaIS2_EE8_M_eraseEPSt13_Rb_tree_nodeIS2_E",
    "std::_Rb_tree<llvm::BasicBlock*, llvm::BasicBlock*, std::_Identity<llvm::BasicBlock*>, std::less<llvm::BasicBlock*>, std::allocator<llvm::BasicBlock*>>::_M_erase(std::_Rb_tree_node<llvm::BasicBlock*>*)",
    "std::_Rb_tree<llvm::BasicBlock*, llvm::BasicBlock*, std::_Identity<llvm::BasicBlock*>, std::less<llvm::BasicBlock*>, std::allocator<llvm::BasicBlock*>>::_M_erase",
    "std::_Rb_tree<llvm::BasicBlock*, llvm::BasicBlock*, std::_Identity<llvm::BasicBlock*>, std::less<llvm::BasicBlock*>, std::allocator<llvm::BasicBlock*>>::_M_erase(std::_Rb_tree_node<llvm::BasicBlock*>*)",
  ),
  (
    "_ZNK4llvm12StructLayout26getElementContainingOffsetEy", "llvm::StructLayout::getElementContainingOffset(unsigned long long) const",
    "llvm::StructLayout::getElementContainingOffset", "llvm::StructLayout::getElementContainingOffset(unsigned long long) const",
  ),
  (
    "_ZNSt8_Rb_treeIN4llvm7SDValueES1_St9_IdentityIS1_ESt4lessIS1_ESaIS1_EE8_M_eraseEPSt13_Rb_tree_nodeIS1_E",
    "std::_Rb_tree<llvm::SDValue, llvm::SDValue, std::_Identity<llvm::SDValue>, std::less<llvm::SDValue>, std::allocator<llvm::SDValue>>::_M_erase(std::_Rb_tree_node<llvm::SDValue>*)",
    "std::_Rb_tree<llvm::SDValue, llvm::SDValue, std::_Identity<llvm::SDValue>, std::less<llvm::SDValue>, std::allocator<llvm::SDValue>>::_M_erase",
    "std::_Rb_tree<llvm::SDValue, llvm::SDValue, std::_Identity<llvm::SDValue>, std::less<llvm::SDValue>, std::allocator<llvm::SDValue>>::_M_erase(std::_Rb_tree_node<llvm::SDValue>*)",
  ),
  (
    "_ZN5clang10ASTContext24getDefaultMethodCallConvEv", "clang::ASTContext::getDefaultMethodCallConv()",
    "clang::ASTContext::getDefaultMethodCallConv", "clang::ASTContext::getDefaultMethodCallConv()",
  ),
  (
    "_ZNK4llvm8LoopBaseINS_17MachineBasicBlockENS_11MachineLoopEE9getBlocksEv", "llvm::LoopBase<llvm::MachineBasicBlock, llvm::MachineLoop>::getBlocks() const",
    "llvm::LoopBase<llvm::MachineBasicBlock, llvm::MachineLoop>::getBlocks", "llvm::LoopBase<llvm::MachineBasicBlock, llvm::MachineLoop>::getBlocks() const",
  ),
  (
    "_ZN5clang9NamedDecl17getUnderlyingDeclEv", "clang::NamedDecl::getUnderlyingDecl()",
    "clang::NamedDecl::getUnderlyingDecl", "clang::NamedDecl::getUnderlyingDecl()",
  ),
  (
    "_ZN5clang3idx10EntityImpl3getEPNS_4DeclERNS0_7ProgramERNS0_11ProgramImplE",
    "clang::idx::EntityImpl::get(clang::Decl*, clang::idx::Program&, clang::idx::ProgramImpl&)",
    "clang::idx::EntityImpl::get", "clang::idx::EntityImpl::get(clang::Decl*, clang::idx::Program&, clang::idx::ProgramImpl&)",
  ),
  (
    "_ZNK4llvm19ARMBaseRegisterInfo24getFrameIndexInstrOffsetEPKNS_12MachineInstrEi",
    "llvm::ARMBaseRegisterInfo::getFrameIndexInstrOffset(llvm::MachineInstr const*, int) const",
    "llvm::ARMBaseRegisterInfo::getFrameIndexInstrOffset", "llvm::ARMBaseRegisterInfo::getFrameIndexInstrOffset(llvm::MachineInstr const*, int) const",
  ),
  (
    "_ZN4llvm17X86ATTInstPrinter18getInstructionNameEj", "llvm::X86ATTInstPrinter::getInstructionName(unsigned int)",
    "llvm::X86ATTInstPrinter::getInstructionName", "llvm::X86ATTInstPrinter::getInstructionName(unsigned int)",
  ),
  (
    "_ZN4llvm22BitcodeReaderValueList14getValueFwdRefEjPKNS_4TypeE", "llvm::BitcodeReaderValueList::getValueFwdRef(unsigned int, llvm::Type const*)",
    "llvm::BitcodeReaderValueList::getValueFwdRef", "llvm::BitcodeReaderValueList::getValueFwdRef(unsigned int, llvm::Type const*)",
  ),
  (
    "_ZN4llvm2cl3optIiLb0ENS0_6parserIiEEE19getExtraOptionNamesERNS_15SmallVectorImplIPKcEE",
    "llvm::cl::opt<int, false, llvm::cl::parser<int>>::getExtraOptionNames(llvm::SmallVectorImpl<char const*>&)",
    "llvm::cl::opt<int, false, llvm::cl::parser<int>>::getExtraOptionNames", "llvm::cl::opt<int, false, llvm::cl::parser<int>>::getExtraOptionNames(llvm::SmallVectorImpl<char const*>&)",
  ),
  (
    "_ZNK4llvm5APInt7sshl_ovEjRb", "llvm::APInt::sshl_ov(unsigned int, bool&) const",
    "llvm::APInt::sshl_ov", "llvm::APInt::sshl_ov(unsigned int, bool&) const",
  ),
  (
    "_ZNK4llvm5APInt7ssub_ovERKS0_Rb", "llvm::APInt::ssub_ov(llvm::APInt const&, bool&) const",
    "llvm::APInt::ssub_ov", "llvm::APInt::ssub_ov(llvm::APInt const&, bool&) const",
  ),
  (
    "_ZN5clang4Sema22EnterDeclaratorContextEPNS_5ScopeEPNS_11DeclContextE", "clang::Sema::EnterDeclaratorContext(clang::Scope*, clang::DeclContext*)",
    "clang::Sema::EnterDeclaratorContext", "clang::Sema::EnterDeclaratorContext(clang::Scope*, clang::DeclContext*)",
  ),
  (
    "_ZN5clang23ExternalSLocEntrySourceD1Ev", "clang::ExternalSLocEntrySource::~ExternalSLocEntrySource()",
    "clang::ExternalSLocEntrySource::~ExternalSLocEntrySource", "clang::ExternalSLocEntrySource::~ExternalSLocEntrySource()",
  ),
  (
    "_ZN5clang12Preprocessor10EnterMacroERNS_5TokenENS_14SourceLocationEPNS_9MacroArgsE",
    "clang::Preprocessor::EnterMacro(clang::Token&, clang::SourceLocation, clang::MacroArgs*)",
    "clang::Preprocessor::EnterMacro", "clang::Preprocessor::EnterMacro(clang::Token&, clang::SourceLocation, clang::MacroArgs*)",
  ),
  (
    "_ZN4llvm9StringMapIjNS_15MallocAllocatorEE16GetOrCreateValueIjEERNS_14StringMapEntryIjEENS_9StringRefET_",
    "llvm::StringMapEntry<unsigned int>& llvm::StringMap<unsigned int, llvm::MallocAllocator>::GetOrCreateValue<unsigned int>(llvm::StringRef, unsigned int)",
    "llvm::StringMap<unsigned int, llvm::MallocAllocator>::GetOrCreateValue<unsigned int>",
    "llvm::StringMapEntry<unsigned int>& llvm::StringMap<unsigned int, llvm::MallocAllocator>::GetOrCreateValue<unsigned int>(llvm::StringRef, unsigned int)",
  ),
  (
    "_ZN5clang7ASTUnit39RealizePreprocessedEntitiesFromPreambleEv", "clang::ASTUnit::RealizePreprocessedEntitiesFromPreamble()",
    "clang::ASTUnit::RealizePreprocessedEntitiesFromPreamble", "clang::ASTUnit::RealizePreprocessedEntitiesFromPreamble()",
  ),
  (
    "_ZN5clang22InitializationSequence21PrintInitLocationNoteERNS_4SemaERKNS_17InitializedEntityE",
    "clang::InitializationSequence::PrintInitLocationNote(clang::Sema&, clang::InitializedEntity const&)",
    "clang::InitializationSequence::PrintInitLocationNote", "clang::InitializationSequence::PrintInitLocationNote(clang::Sema&, clang::InitializedEntity const&)",
  ),
  (
    "_ZN5clang12Preprocessor16EnterTokenStreamEPKNS_5TokenEjbb", "clang::Preprocessor::EnterTokenStream(clang::Token const*, unsigned int, bool, bool)",
    "clang::Preprocessor::EnterTokenStream", "clang::Preprocessor::EnterTokenStream(clang::Token const*, unsigned int, bool, bool)",
  ),
  (
    "_ZNSt6vectorIN5clang19HeaderSearchOptions5EntryESaIS2_EEC2ERKS4_", "std::vector<clang::HeaderSearchOptions::Entry, std::allocator<clang::HeaderSearchOptions::Entry>>::vector(std::vector<clang::HeaderSearchOptions::Entry, std::allocator<clang::HeaderSearchOptions::Entry>> const&)",
    "std::vector<clang::HeaderSearchOptions::Entry, std::allocator<clang::HeaderSearchOptions::Entry>>::vector",
    "std::vector<clang::HeaderSearchOptions::Entry, std::allocator<clang::HeaderSearchOptions::Entry>>::vector(std::vector<clang::HeaderSearchOptions::Entry, std::allocator<clang::HeaderSearchOptions::Entry>> const&)",
  ),
  (
    "_ZN5clang12LookupResult5printERN4llvm11raw_ostreamE", "clang::LookupResult::print(llvm::raw_ostream&)",
    "clang::LookupResult::print", "clang::LookupResult::print(llvm::raw_ostream&)",
  ),
  (
    "_Z12LookupOptionRN4llvm9StringRefES1_RKNS_9StringMapIPNS_2cl6OptionENS_15MallocAllocatorEEE",
    "LookupOption(llvm::StringRef&, llvm::StringRef&, llvm::StringMap<llvm::cl::Option*, llvm::MallocAllocator> const&)",
    "LookupOption", "LookupOption(llvm::StringRef&, llvm::StringRef&, llvm::StringMap<llvm::cl::Option*, llvm::MallocAllocator> const&)",
  ),
  (
    "_ZTVN12_GLOBAL__N_118LoopStrengthReduceE", "vtable for (anonymous namespace)::LoopStrengthReduce",
    "vtable for (anonymous namespace)::LoopStrengthReduce", "vtable for (anonymous namespace)::LoopStrengthReduce",
  ),
  (
    "_ZNK4llvm8LoopInfo14verifyAnalysisEv", "llvm::LoopInfo::verifyAnalysis() const",
    "llvm::LoopInfo::verifyAnalysis", "llvm::LoopInfo::verifyAnalysis() const",
  ),
  (
    "_ZN4llvm15callDefaultCtorIN12_GLOBAL__N_112LoopDeletionEEEPNS_4PassEv", "llvm::Pass* llvm::callDefaultCtor<(anonymous namespace)::LoopDeletion>()",
    "llvm::callDefaultCtor<(anonymous namespace)::LoopDeletion>", "llvm::Pass* llvm::callDefaultCtor<(anonymous namespace)::LoopDeletion>()",
  ),
  (
    "_ZN12_GLOBAL__N_112LoopDeletionD1Ev", "(anonymous namespace)::LoopDeletion::~LoopDeletion()",
    "(anonymous namespace)::LoopDeletion::~LoopDeletion", "(anonymous namespace)::LoopDeletion::~LoopDeletion()",
  ),
  (
    "_ZNK4llvm4Loop15isLoopInvariantEPNS_5ValueE", "llvm::Loop::isLoopInvariant(llvm::Value*) const",
    "llvm::Loop::isLoopInvariant", "llvm::Loop::isLoopInvariant(llvm::Value*) const",
  ),
  (
    "_ZNSt6vectorIPN4llvm4LoopESaIS2_EE13_M_insert_auxEN9__gnu_cxx17__normal_iteratorIPS2_S4_EERKS2_",
    "std::vector<llvm::Loop*, std::allocator<llvm::Loop*>>::_M_insert_aux(__gnu_cxx::__normal_iterator<llvm::Loop**, std::vector<llvm::Loop*, std::allocator<llvm::Loop*>>>, llvm::Loop* const&)",
    "std::vector<llvm::Loop*, std::allocator<llvm::Loop*>>::_M_insert_aux", "std::vector<llvm::Loop*, std::allocator<llvm::Loop*>>::_M_insert_aux(__gnu_cxx::__normal_iterator<llvm::Loop**, std::vector<llvm::Loop*, std::allocator<llvm::Loop*>>>, llvm::Loop* const&)",
  ),
  (
    "_ZN4llvm26ImutAVLTreeGenericIteratorINS_16ImutKeyValueInfoIj9ArgEffectEEEppEv",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutKeyValueInfo<unsigned int, ArgEffect>>::operator++()",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutKeyValueInfo<unsigned int, ArgEffect>>::operator++",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutKeyValueInfo<unsigned int, ArgEffect>>::operator++()",
  ),
  (
    "_ZN4llvm26ImutAVLTreeGenericIteratorINS_16ImutIntervalInfoIN5clang4ento4SValEEEEppEv",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutIntervalInfo<clang::ento::SVal>>::operator++()",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutIntervalInfo<clang::ento::SVal>>::operator++",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutIntervalInfo<clang::ento::SVal>>::operator++()",
  ),
  (
    "_ZN4llvm26ImutAVLTreeInOrderIteratorINS_16ImutKeyValueInfoIN12_GLOBAL__N_18CountKeyEjEEEppEv",
    "llvm::ImutAVLTreeInOrderIterator<llvm::ImutKeyValueInfo<(anonymous namespace)::CountKey, unsigned int>>::operator++()",
    "llvm::ImutAVLTreeInOrderIterator<llvm::ImutKeyValueInfo<(anonymous namespace)::CountKey, unsigned int>>::operator++",
    "llvm::ImutAVLTreeInOrderIterator<llvm::ImutKeyValueInfo<(anonymous namespace)::CountKey, unsigned int>>::operator++()",
  ),
  (
    "_ZN4llvm26ImutAVLTreeGenericIteratorINS_17ImutContainerInfoIPNS_6APSIntEEEEppEv",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutContainerInfo<llvm::APSInt*>>::operator++()",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutContainerInfo<llvm::APSInt*>>::operator++",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutContainerInfo<llvm::APSInt*>>::operator++()",
  ),
  (
    "_ZN4llvm26ImutAVLTreeGenericIteratorIN12_GLOBAL__N_110RangeTraitEEppEv", "llvm::ImutAVLTreeGenericIterator<(anonymous namespace)::RangeTrait>::operator++()",
    "llvm::ImutAVLTreeGenericIterator<(anonymous namespace)::RangeTrait>::operator++",
    "llvm::ImutAVLTreeGenericIterator<(anonymous namespace)::RangeTrait>::operator++()",
  ),
  (
    "_ZN4llvm26ImutAVLTreeGenericIteratorINS_17ImutContainerInfoIPN5clang4ento7BugTypeEEEEppEv",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutContainerInfo<clang::ento::BugType*>>::operator++()",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutContainerInfo<clang::ento::BugType*>>::operator++",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutContainerInfo<clang::ento::BugType*>>::operator++()",
  ),
  (
    "_ZN4llvm26ImutAVLTreeGenericIteratorINS_16ImutKeyValueInfoIPKN5clang4StmtENS2_4ento4SValEEEEppEv",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutKeyValueInfo<clang::Stmt const*, clang::ento::SVal>>::operator++()",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutKeyValueInfo<clang::Stmt const*, clang::ento::SVal>>::operator++",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutKeyValueInfo<clang::Stmt const*, clang::ento::SVal>>::operator++()",
  ),
  (
    "_ZN4llvm26ImutAVLTreeGenericIteratorINS_16ImutKeyValueInfoIPvS2_EEEppEv", "llvm::ImutAVLTreeGenericIterator<llvm::ImutKeyValueInfo<void*, void*>>::operator++()",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutKeyValueInfo<void*, void*>>::operator++",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutKeyValueInfo<void*, void*>>::operator++()",
  ),
  (
    "_ZNKSs7compareEmmPKc", "std::string::compare(unsigned long, unsigned long, char const*) const",
    "std::string::compare", "std::string::compare(unsigned long, unsigned long, char const*) const",
  ),
  (
    "_ZN4llvm18PrintRecyclerStatsEmmm", "llvm::PrintRecyclerStats(unsigned long, unsigned long, unsigned long)",
    "llvm::PrintRecyclerStats", "llvm::PrintRecyclerStats(unsigned long, unsigned long, unsigned long)",
  ),
  (
    "_ZN4llvm16BumpPtrAllocatorC1EmmRNS_13SlabAllocatorE", "llvm::BumpPtrAllocator::BumpPtrAllocator(unsigned long, unsigned long, llvm::SlabAllocator&)",
    "llvm::BumpPtrAllocator::BumpPtrAllocator", "llvm::BumpPtrAllocator::BumpPtrAllocator(unsigned long, unsigned long, llvm::SlabAllocator&)",
  ),
  (
    "_ZNSs14_M_replace_auxEmmmc", "std::string::_M_replace_aux(unsigned long, unsigned long, unsigned long, char)",
    "std::string::_M_replace_aux", "std::string::_M_replace_aux(unsigned long, unsigned long, unsigned long, char)",
  ),
  (
    "_ZNKSs7compareEmmPKcm", "std::string::compare(unsigned long, unsigned long, char const*, unsigned long) const",
    "std::string::compare", "std::string::compare(unsigned long, unsigned long, char const*, unsigned long) const",
  ),
  (
    "_ZN16ImageLoaderMachO12bindLocationERKN11ImageLoader11LinkContextEmmPKS0_hPKclS7_",
    "ImageLoaderMachO::bindLocation(ImageLoader::LinkContext const&, unsigned long, unsigned long, ImageLoader const*, unsigned char, char const*, long, char const*)",
    "ImageLoaderMachO::bindLocation", "ImageLoaderMachO::bindLocation(ImageLoader::LinkContext const&, unsigned long, unsigned long, ImageLoader const*, unsigned char, char const*, long, char const*)",
  ),
  (
    "_ZNSs4_Rep9_S_createEmmRKSaIcE", "std::string::_Rep::_S_create(unsigned long, unsigned long, std::allocator<char> const&)",
    "std::string::_Rep::_S_create", "std::string::_Rep::_S_create(unsigned long, unsigned long, std::allocator<char> const&)",
  ),
  (
    "_ZNSs9_M_mutateEmmm", "std::string::_M_mutate(unsigned long, unsigned long, unsigned long)",
    "std::string::_M_mutate", "std::string::_M_mutate(unsigned long, unsigned long, unsigned long)",
  ),
  (
    "_ZNKSs13find_first_ofEPKcmm", "std::string::find_first_of(char const*, unsigned long, unsigned long) const",
    "std::string::find_first_of", "std::string::find_first_of(char const*, unsigned long, unsigned long) const",
  ),
  (
    "_ZNKSs4findEPKcmm", "std::string::find(char const*, unsigned long, unsigned long) const",
    "std::string::find", "std::string::find(char const*, unsigned long, unsigned long) const",
  ),
  (
    "_ZN5Casts8implicitILj4EEEvPN9enable_ifIXplLi1EcmT_Li4EEvE4typeE", "void Casts::implicit<4u>(enable_if<1 + (4u, 4), void>::type*)",
    "Casts::implicit<4u>", "void Casts::implicit<4u>(enable_if<1 + (4u, 4), void>::type*)",
  ),
  (
    "_ZNSsC1EPKcmRKSaIcE", "std::basic_string<char, std::char_traits<char>, std::allocator<char>>::basic_string(char const*, unsigned long, std::allocator<char> const&)",
    "std::basic_string<char, std::char_traits<char>, std::allocator<char>>::basic_string",
    "std::basic_string<char, std::char_traits<char>, std::allocator<char>>::basic_string(char const*, unsigned long, std::allocator<char> const&)",
  ),
  (
    "_ZN23ImageLoaderMachOClassic18bindIndirectSymbolEPmPK13macho_sectionPKcmPK11ImageLoaderRKNS6_11LinkContextE",
    "ImageLoaderMachOClassic::bindIndirectSymbol(unsigned long*, macho_section const*, char const*, unsigned long, ImageLoader const*, ImageLoader::LinkContext const&)",
    "ImageLoaderMachOClassic::bindIndirectSymbol", "ImageLoaderMachOClassic::bindIndirectSymbol(unsigned long*, macho_section const*, char const*, unsigned long, ImageLoader const*, ImageLoader::LinkContext const&)",
  ),
  (
    "_ZNKSs5rfindEPKcmm", "std::string::rfind(char const*, unsigned long, unsigned long) const",
    "std::string::rfind", "std::string::rfind(char const*, unsigned long, unsigned long) const",
  ),
  (
    "_Z1fIXfLpm1x1yEEvv", "void f<(x ->* ... ->* (y...))>()", "f<(x ->* ... ->* (y...))>",
    "void f<(x ->* ... ->* (y...))>()",
  ),
  (
    "_Z1fIXfLpt1x1yEEvv", "_Z1fIXfLpt1x1yEEvv", "_Z1fIXfLpt1x1yEEvv", "_Z1fIXfLpt1x1yEEvv",
  ),
  (
    "_ZNK5clang20WarnUnusedResultAttr5cloneERNS_10ASTContextE", "clang::WarnUnusedResultAttr::clone(clang::ASTContext&) const",
    "clang::WarnUnusedResultAttr::clone", "clang::WarnUnusedResultAttr::clone(clang::ASTContext&) const",
  ),
  (
    "_ZN12_GLOBAL__N_115ASTNodeImporter22VisitImplicitParamDeclEPN5clang17ImplicitParamDeclE",
    "(anonymous namespace)::ASTNodeImporter::VisitImplicitParamDecl(clang::ImplicitParamDecl*)",
    "(anonymous namespace)::ASTNodeImporter::VisitImplicitParamDecl", "(anonymous namespace)::ASTNodeImporter::VisitImplicitParamDecl(clang::ImplicitParamDecl*)",
  ),
  (
    "_ZTVN5clang4ento9BugReport12NodeResolverE", "vtable for clang::ento::BugReport::NodeResolver",
    "vtable for clang::ento::BugReport::NodeResolver", "vtable for clang::ento::BugReport::NodeResolver",
  ),
  (
    "_ZN5clang6driver10toolchains6DarwinD0Ev", "clang::driver::toolchains::Darwin::~Darwin()",
    "clang::driver::toolchains::Darwin::~Darwin", "clang::driver::toolchains::Darwin::~Darwin()",
  ),
  (
    "_ZN5clang7CodeGen15CodeGenFunction19ResolveBranchFixupsEPN4llvm10BasicBlockE",
    "clang::CodeGen::CodeGenFunction::ResolveBranchFixups(llvm::BasicBlock*)", "clang::CodeGen::CodeGenFunction::ResolveBranchFixups",
    "clang::CodeGen::CodeGenFunction::ResolveBranchFixups(llvm::BasicBlock*)",
  ),
  (
    "_ZN5clang4ento12BlockCounter7FactoryD2Ev", "clang::ento::BlockCounter::Factory::~Factory()",
    "clang::ento::BlockCounter::Factory::~Factory", "clang::ento::BlockCounter::Factory::~Factory()",
  ),
  (
    "_ZN5clang14reachable_code22ScanReachableFromBlockERKNS_8CFGBlockERN4llvm9BitVectorE",
    "clang::reachable_code::ScanReachableFromBlock(clang::CFGBlock const&, llvm::BitVector&)",
    "clang::reachable_code::ScanReachableFromBlock", "clang::reachable_code::ScanReachableFromBlock(clang::CFGBlock const&, llvm::BitVector&)",
  ),
  (
    "_ZN5clang6Parser20ObjCPropertyCallback6invokeERNS_15FieldDeclaratorE", "clang::Parser::ObjCPropertyCallback::invoke(clang::FieldDeclarator&)",
    "clang::Parser::ObjCPropertyCallback::invoke", "clang::Parser::ObjCPropertyCallback::invoke(clang::FieldDeclarator&)",
  ),
  (
    "_ZNSt3mapISsjSt4lessISsESaISt4pairIKSsjEEEixERS3_", "std::map<std::string, unsigned int, std::less<std::string>, std::allocator<std::pair<std::string const, unsigned int>>>::operator[](std::string const&)",
    "std::map<std::string, unsigned int, std::less<std::string>, std::allocator<std::pair<std::string const, unsigned int>>>::operator[]",
    "std::map<std::string, unsigned int, std::less<std::string>, std::allocator<std::pair<std::string const, unsigned int>>>::operator[](std::string const&)",
  ),
  (
    "_ZN4llvm9StringMapIPN12_GLOBAL__N_119LibCallOptimizationENS_15MallocAllocatorEEixENS_9StringRefE",
    "llvm::StringMap<(anonymous namespace)::LibCallOptimization*, llvm::MallocAllocator>::operator[](llvm::StringRef)",
    "llvm::StringMap<(anonymous namespace)::LibCallOptimization*, llvm::MallocAllocator>::operator[]",
    "llvm::StringMap<(anonymous namespace)::LibCallOptimization*, llvm::MallocAllocator>::operator[](llvm::StringRef)",
  ),
  (
    "_ZN4llvm8DenseMapIPKNS_8MCSymbolEPN12_GLOBAL__N_110COFFSymbolENS_12DenseMapInfoIS3_EENS7_IS6_EEEixERKS3_",
    "llvm::DenseMap<llvm::MCSymbol const*, (anonymous namespace)::COFFSymbol*, llvm::DenseMapInfo<llvm::MCSymbol const*>, llvm::DenseMapInfo<(anonymous namespace)::COFFSymbol*>>::operator[](llvm::MCSymbol const* const&)",
    "llvm::DenseMap<llvm::MCSymbol const*, (anonymous namespace)::COFFSymbol*, llvm::DenseMapInfo<llvm::MCSymbol const*>, llvm::DenseMapInfo<(anonymous namespace)::COFFSymbol*>>::operator[]",
    "llvm::DenseMap<llvm::MCSymbol const*, (anonymous namespace)::COFFSymbol*, llvm::DenseMapInfo<llvm::MCSymbol const*>, llvm::DenseMapInfo<(anonymous namespace)::COFFSymbol*>>::operator[](llvm::MCSymbol const* const&)",
  ),
  (
    "_ZNSt3mapISsPvSt4lessISsESaISt4pairIKSsS0_EEEixERS4_", "std::map<std::string, void*, std::less<std::string>, std::allocator<std::pair<std::string const, void*>>>::operator[](std::string const&)",
    "std::map<std::string, void*, std::less<std::string>, std::allocator<std::pair<std::string const, void*>>>::operator[]",
    "std::map<std::string, void*, std::less<std::string>, std::allocator<std::pair<std::string const, void*>>>::operator[](std::string const&)",
  ),
  (
    "_ZN4llvm8DenseMapIjN12_GLOBAL__N_13GVN16LeaderTableEntryENS_12DenseMapInfoIjEENS4_IS3_EEEixERKj",
    "llvm::DenseMap<unsigned int, (anonymous namespace)::GVN::LeaderTableEntry, llvm::DenseMapInfo<unsigned int>, llvm::DenseMapInfo<(anonymous namespace)::GVN::LeaderTableEntry>>::operator[](unsigned int const&)",
    "llvm::DenseMap<unsigned int, (anonymous namespace)::GVN::LeaderTableEntry, llvm::DenseMapInfo<unsigned int>, llvm::DenseMapInfo<(anonymous namespace)::GVN::LeaderTableEntry>>::operator[]",
    "llvm::DenseMap<unsigned int, (anonymous namespace)::GVN::LeaderTableEntry, llvm::DenseMapInfo<unsigned int>, llvm::DenseMapInfo<(anonymous namespace)::GVN::LeaderTableEntry>>::operator[](unsigned int const&)",
  ),
  (
    "_ZN4llvm8ValueMapIPKNS_5ValueENS_10TrackingVHIS1_EENS_14ValueMapConfigIS3_EENS_12DenseMapInfoIS5_EEEixERKS3_",
    "llvm::ValueMap<llvm::Value const*, llvm::TrackingVH<llvm::Value>, llvm::ValueMapConfig<llvm::Value const*>, llvm::DenseMapInfo<llvm::TrackingVH<llvm::Value>>>::operator[](llvm::Value const* const&)",
    "llvm::ValueMap<llvm::Value const*, llvm::TrackingVH<llvm::Value>, llvm::ValueMapConfig<llvm::Value const*>, llvm::DenseMapInfo<llvm::TrackingVH<llvm::Value>>>::operator[]",
    "llvm::ValueMap<llvm::Value const*, llvm::TrackingVH<llvm::Value>, llvm::ValueMapConfig<llvm::Value const*>, llvm::DenseMapInfo<llvm::TrackingVH<llvm::Value>>>::operator[](llvm::Value const* const&)",
  ),
  (
    "_ZNSt3mapISsSt4pairIPN4llvm5ValueENS1_5SMLocEESt4lessISsESaIS0_IKSsS5_EEEixERS8_",
    "std::map<std::string, std::pair<llvm::Value*, llvm::SMLoc>, std::less<std::string>, std::allocator<std::pair<std::string const, std::pair<llvm::Value*, llvm::SMLoc>>>>::operator[](std::string const&)",
    "std::map<std::string, std::pair<llvm::Value*, llvm::SMLoc>, std::less<std::string>, std::allocator<std::pair<std::string const, std::pair<llvm::Value*, llvm::SMLoc>>>>::operator[]",
    "std::map<std::string, std::pair<llvm::Value*, llvm::SMLoc>, std::less<std::string>, std::allocator<std::pair<std::string const, std::pair<llvm::Value*, llvm::SMLoc>>>>::operator[](std::string const&)",
  ),
  (
    "_ZNK4llvm12LoopInfoBaseINS_17MachineBasicBlockENS_11MachineLoopEEixEPKS1_",
    "llvm::LoopInfoBase<llvm::MachineBasicBlock, llvm::MachineLoop>::operator[](llvm::MachineBasicBlock const*) const",
    "llvm::LoopInfoBase<llvm::MachineBasicBlock, llvm::MachineLoop>::operator[]",
    "llvm::LoopInfoBase<llvm::MachineBasicBlock, llvm::MachineLoop>::operator[](llvm::MachineBasicBlock const*) const",
  ),
  (
    "_Z24IsStructurallyEquivalentRN12_GLOBAL__N_128StructuralEquivalenceContextEPN5clang4DeclES4_",
    "IsStructurallyEquivalent((anonymous namespace)::StructuralEquivalenceContext&, clang::Decl*, clang::Decl*)",
    "IsStructurallyEquivalent", "IsStructurallyEquivalent((anonymous namespace)::StructuralEquivalenceContext&, clang::Decl*, clang::Decl*)",
  ),
  (
    "_ZTVN4llvm10FoldingSetIN5clang4ento19BugReportEquivClassEEE", "vtable for llvm::FoldingSet<clang::ento::BugReportEquivClass>",
    "vtable for llvm::FoldingSet<clang::ento::BugReportEquivClass>", "vtable for llvm::FoldingSet<clang::ento::BugReportEquivClass>",
  ),
  (
    "_ZN5clang6Parser32isTokenEqualOrMistypedEqualEqualEj", "clang::Parser::isTokenEqualOrMistypedEqualEqual(unsigned int)",
    "clang::Parser::isTokenEqualOrMistypedEqualEqual", "clang::Parser::isTokenEqualOrMistypedEqualEqual(unsigned int)",
  ),
  (
    "_ZNK4llvm11ImutAVLTreeINS_16ImutKeyValueInfoIPKN5clang4StmtENS2_4ento4SValEEEE7isEqualERKS9_",
    "llvm::ImutAVLTree<llvm::ImutKeyValueInfo<clang::Stmt const*, clang::ento::SVal>>::isEqual(llvm::ImutAVLTree<llvm::ImutKeyValueInfo<clang::Stmt const*, clang::ento::SVal>> const&) const",
    "llvm::ImutAVLTree<llvm::ImutKeyValueInfo<clang::Stmt const*, clang::ento::SVal>>::isEqual",
    "llvm::ImutAVLTree<llvm::ImutKeyValueInfo<clang::Stmt const*, clang::ento::SVal>>::isEqual(llvm::ImutAVLTree<llvm::ImutKeyValueInfo<clang::Stmt const*, clang::ento::SVal>> const&) const",
  ),
  (
    "_ZNK4llvm10FoldingSetINS_4SCEVEE10NodeEqualsEPNS_14FoldingSetImpl4NodeERKNS_16FoldingSetNodeIDERS6_",
    "llvm::FoldingSet<llvm::SCEV>::NodeEquals(llvm::FoldingSetImpl::Node*, llvm::FoldingSetNodeID const&, llvm::FoldingSetNodeID&) const",
    "llvm::FoldingSet<llvm::SCEV>::NodeEquals", "llvm::FoldingSet<llvm::SCEV>::NodeEquals(llvm::FoldingSetImpl::Node*, llvm::FoldingSetNodeID const&, llvm::FoldingSetNodeID&) const",
  ),
  (
    "_ZNK4llvm7CmpInst10isEqualityEv", "llvm::CmpInst::isEquality() const", "llvm::CmpInst::isEquality",
    "llvm::CmpInst::isEquality() const",
  ),
  (
    "_ZN4llvm18EquivalenceClassesIPKNS_19TargetRegisterClassEE9unionSetsERKS3_S6_",
    "llvm::EquivalenceClasses<llvm::TargetRegisterClass const*>::unionSets(llvm::TargetRegisterClass const* const&, llvm::TargetRegisterClass const* const&)",
    "llvm::EquivalenceClasses<llvm::TargetRegisterClass const*>::unionSets", "llvm::EquivalenceClasses<llvm::TargetRegisterClass const*>::unionSets(llvm::TargetRegisterClass const* const&, llvm::TargetRegisterClass const* const&)",
  ),
  (
    "_Z22SolveQuadraticEquationPKN4llvm14SCEVAddRecExprERNS_15ScalarEvolutionE",
    "SolveQuadraticEquation(llvm::SCEVAddRecExpr const*, llvm::ScalarEvolution&)",
    "SolveQuadraticEquation", "SolveQuadraticEquation(llvm::SCEVAddRecExpr const*, llvm::ScalarEvolution&)",
  ),
  (
    "_ZN5test73fA1IiEEDTcmtlNS_1AELi1ELi2EEcvT__EES2_", "decltype(test7::A{1, 2}, (int)()) test7::fA1<int>(int)",
    "test7::fA1<int>", "decltype(test7::A{1, 2}, (int)()) test7::fA1<int>(int)",
  ),
  (
    "_ZN5test73fB2IiEEDTcmcvNS_1BEilLi1ELi2EEcvT__EES2_", "decltype((test7::B)({1, 2}), (int)()) test7::fB2<int>(int)",
    "test7::fB2<int>", "decltype((test7::B)({1, 2}), (int)()) test7::fB2<int>(int)",
  ),
  (
    "_ZN5test73fF1IiEEDTcmtlNS_1FEilLi1ELi2EEEcvT__EES2_", "decltype(test7::F{{1, 2}}, (int)()) test7::fF1<int>(int)",
    "test7::fF1<int>", "decltype(test7::F{{1, 2}}, (int)()) test7::fF1<int>(int)",
  ),
  (
    "_ZN5test73fC1IiEEDTcmtlNS_1CEilLi1ELi2EEEcvT__EES2_", "decltype(test7::C{{1, 2}}, (int)()) test7::fC1<int>(int)",
    "test7::fC1<int>", "decltype(test7::C{{1, 2}}, (int)()) test7::fC1<int>(int)",
  ),
  (
    "_ZN6test205test1IiEEvDTcl1fIEcvT__EEE", "void test20::test1<int>(decltype(f<>((int)())))",
    "test20::test1<int>", "void test20::test1<int>(decltype(f<>((int)())))",
  ),
  (
    "_ZN5test73fB1IiEEDTcmtlNS_1BELi1ELi2EEcvT__EES2_", "decltype(test7::B{1, 2}, (int)()) test7::fB1<int>(int)",
    "test7::fB1<int>", "decltype(test7::B{1, 2}, (int)()) test7::fB1<int>(int)",
  ),
  (
    "_ZN5Casts7scalar_IiEEvDTcmcvT__Ecvi_EE", "void Casts::scalar_<int>(decltype((int)(), (int)()))",
    "Casts::scalar_<int>", "void Casts::scalar_<int>(decltype((int)(), (int)()))",
  ),
  (
    "_ZN5test73fC2IiEEDTcmcvNS_1CEilLi1ELi2EEcvT__EES2_", "decltype((test7::C)({1, 2}), (int)()) test7::fC2<int>(int)",
    "test7::fC2<int>", "decltype((test7::C)({1, 2}), (int)()) test7::fC2<int>(int)",
  ),
  ("_ZL11NumPHIsElim", "NumPHIsElim", "NumPHIsElim", "NumPHIsElim"),
  (
    "_ZN4llvm2cl4listIPKNS_8PassInfoEbNS_14PassNameParserEED0Ev", "llvm::cl::list<llvm::PassInfo const*, bool, llvm::PassNameParser>::~list()",
    "llvm::cl::list<llvm::PassInfo const*, bool, llvm::PassNameParser>::~list", "llvm::cl::list<llvm::PassInfo const*, bool, llvm::PassNameParser>::~list()",
  ),
  (
    "_ZNK4llvm2cl4listIPKNS_8PassInfoEbNS_14PassNameParserEE15printOptionInfoEm",
    "llvm::cl::list<llvm::PassInfo const*, bool, llvm::PassNameParser>::printOptionInfo(unsigned long) const",
    "llvm::cl::list<llvm::PassInfo const*, bool, llvm::PassNameParser>::printOptionInfo",
    "llvm::cl::list<llvm::PassInfo const*, bool, llvm::PassNameParser>::printOptionInfo(unsigned long) const",
  ),
  (
    "_ZN5clang11PPCallbacks4ElifENS_11SourceRangeE", "clang::PPCallbacks::Elif(clang::SourceRange)",
    "clang::PPCallbacks::Elif", "clang::PPCallbacks::Elif(clang::SourceRange)",
  ),
  (
    "_ZN9libunwind12UnwindCursorINS_17LocalAddressSpaceENS_16Registers_x86_64EE11setFloatRegEid",
    "libunwind::UnwindCursor<libunwind::LocalAddressSpace, libunwind::Registers_x86_64>::setFloatReg(int, double)",
    "libunwind::UnwindCursor<libunwind::LocalAddressSpace, libunwind::Registers_x86_64>::setFloatReg",
    "libunwind::UnwindCursor<libunwind::LocalAddressSpace, libunwind::Registers_x86_64>::setFloatReg(int, double)",
  ),
  (
    "_ZN4llvm34initializeUnreachableBlockElimPassERNS_12PassRegistryE", "llvm::initializeUnreachableBlockElimPass(llvm::PassRegistry&)",
    "llvm::initializeUnreachableBlockElimPass", "llvm::initializeUnreachableBlockElimPass(llvm::PassRegistry&)",
  ),
  (
    "_ZN9libunwind12UnwindCursorINS_17LocalAddressSpaceENS_16Registers_x86_64EE23stepWithCompactEncodingEv",
    "libunwind::UnwindCursor<libunwind::LocalAddressSpace, libunwind::Registers_x86_64>::stepWithCompactEncoding()",
    "libunwind::UnwindCursor<libunwind::LocalAddressSpace, libunwind::Registers_x86_64>::stepWithCompactEncoding",
    "libunwind::UnwindCursor<libunwind::LocalAddressSpace, libunwind::Registers_x86_64>::stepWithCompactEncoding()",
  ),
  (
    "_ZN4llvm36createDeadMachineInstructionElimPassEv", "llvm::createDeadMachineInstructionElimPass()",
    "llvm::createDeadMachineInstructionElimPass", "llvm::createDeadMachineInstructionElimPass()",
  ),
  (
    "_Z1fIL4Enumn1EEvv", "void f<(Enum)-1>()", "f<(Enum)-1>", "void f<(Enum)-1>()",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L11CL_OverlapsE", "llvm::(anonymous namespace)::CL_Overlaps",
    "llvm::(anonymous namespace)::CL_Overlaps", "llvm::(anonymous namespace)::CL_Overlaps",
  ),
  (
    "_ZN12_GLOBAL__N_116ELFARMAsmBackendD0Ev", "(anonymous namespace)::ELFARMAsmBackend::~ELFARMAsmBackend()",
    "(anonymous namespace)::ELFARMAsmBackend::~ELFARMAsmBackend", "(anonymous namespace)::ELFARMAsmBackend::~ELFARMAsmBackend()",
  ),
  (
    "_ZN12_GLOBAL__N_114MipsTargetInfoD0Ev", "(anonymous namespace)::MipsTargetInfo::~MipsTargetInfo()",
    "(anonymous namespace)::MipsTargetInfo::~MipsTargetInfo", "(anonymous namespace)::MipsTargetInfo::~MipsTargetInfo()",
  ),
  (
    "_ZNK10__cxxabiv117__pbase_type_info10__do_catchEPKSt9type_infoPPvj", "__cxxabiv1::__pbase_type_info::__do_catch(std::type_info const*, void**, unsigned int) const",
    "__cxxabiv1::__pbase_type_info::__do_catch", "__cxxabiv1::__pbase_type_info::__do_catch(std::type_info const*, void**, unsigned int) const",
  ),
  ("_Z1Av", "A()", "A", "A()"),
  (
    "_ZN4llvm8DenseMapIPKNS_8ArgumentEiNS_12DenseMapInfoIS3_EENS4_IiEEE16InsertIntoBucketERKS3_RKiPSt4pairIS3_iE",
    "llvm::DenseMap<llvm::Argument const*, int, llvm::DenseMapInfo<llvm::Argument const*>, llvm::DenseMapInfo<int>>::InsertIntoBucket(llvm::Argument const* const&, int const&, std::pair<llvm::Argument const*, int>*)",
    "llvm::DenseMap<llvm::Argument const*, int, llvm::DenseMapInfo<llvm::Argument const*>, llvm::DenseMapInfo<int>>::InsertIntoBucket",
    "llvm::DenseMap<llvm::Argument const*, int, llvm::DenseMapInfo<llvm::Argument const*>, llvm::DenseMapInfo<int>>::InsertIntoBucket(llvm::Argument const* const&, int const&, std::pair<llvm::Argument const*, int>*)",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L14R11_SubRegsSetE", "llvm::(anonymous namespace)::R11_SubRegsSet",
    "llvm::(anonymous namespace)::R11_SubRegsSet", "llvm::(anonymous namespace)::R11_SubRegsSet",
  ),
  (
    "_ZN4llvm8DenseMapIPKNS_5ValueENS_7SDValueENS_12DenseMapInfoIS3_EENS5_IS4_EEE4growEj",
    "llvm::DenseMap<llvm::Value const*, llvm::SDValue, llvm::DenseMapInfo<llvm::Value const*>, llvm::DenseMapInfo<llvm::SDValue>>::grow(unsigned int)",
    "llvm::DenseMap<llvm::Value const*, llvm::SDValue, llvm::DenseMapInfo<llvm::Value const*>, llvm::DenseMapInfo<llvm::SDValue>>::grow",
    "llvm::DenseMap<llvm::Value const*, llvm::SDValue, llvm::DenseMapInfo<llvm::Value const*>, llvm::DenseMapInfo<llvm::SDValue>>::grow(unsigned int)",
  ),
  (
    "_ZN4llvm8DenseMapISt4pairIPNS_10BasicBlockES3_EcNS_12DenseMapInfoIS4_EENS5_IcEEE4growEj",
    "llvm::DenseMap<std::pair<llvm::BasicBlock*, llvm::BasicBlock*>, char, llvm::DenseMapInfo<std::pair<llvm::BasicBlock*, llvm::BasicBlock*>>, llvm::DenseMapInfo<char>>::grow(unsigned int)",
    "llvm::DenseMap<std::pair<llvm::BasicBlock*, llvm::BasicBlock*>, char, llvm::DenseMapInfo<std::pair<llvm::BasicBlock*, llvm::BasicBlock*>>, llvm::DenseMapInfo<char>>::grow",
    "llvm::DenseMap<std::pair<llvm::BasicBlock*, llvm::BasicBlock*>, char, llvm::DenseMapInfo<std::pair<llvm::BasicBlock*, llvm::BasicBlock*>>, llvm::DenseMapInfo<char>>::grow(unsigned int)",
  ),
  (
    "_ZN4llvm21AddressingModeMatcher16MatchScaledValueEPNS_5ValueExj", "llvm::AddressingModeMatcher::MatchScaledValue(llvm::Value*, long long, unsigned int)",
    "llvm::AddressingModeMatcher::MatchScaledValue", "llvm::AddressingModeMatcher::MatchScaledValue(llvm::Value*, long long, unsigned int)",
  ),
  (
    "_ZN4llvmL13OperandInfo99E", "llvm::OperandInfo99", "llvm::OperandInfo99", "llvm::OperandInfo99",
  ),
  (
    "_ZNK4llvm5Twine8toVectorERNS_15SmallVectorImplIcEE", "llvm::Twine::toVector(llvm::SmallVectorImpl<char>&) const",
    "llvm::Twine::toVector", "llvm::Twine::toVector(llvm::SmallVectorImpl<char>&) const",
  ),
  (
    "_ZN4llvm9MCContext17GetOrCreateSymbolENS_9StringRefE", "llvm::MCContext::GetOrCreateSymbol(llvm::StringRef)",
    "llvm::MCContext::GetOrCreateSymbol", "llvm::MCContext::GetOrCreateSymbol(llvm::StringRef)",
  ),
  (
    "_ZN12_GLOBAL__N_120MSP430AttributesSemaD1Ev", "(anonymous namespace)::MSP430AttributesSema::~MSP430AttributesSema()",
    "(anonymous namespace)::MSP430AttributesSema::~MSP430AttributesSema", "(anonymous namespace)::MSP430AttributesSema::~MSP430AttributesSema()",
  ),
  (
    "_ZN4llvm12SelectionDAGD2Ev", "llvm::SelectionDAG::~SelectionDAG()", "llvm::SelectionDAG::~SelectionDAG",
    "llvm::SelectionDAG::~SelectionDAG()",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L16EBP_SuperRegsSetE", "llvm::(anonymous namespace)::EBP_SuperRegsSet",
    "llvm::(anonymous namespace)::EBP_SuperRegsSet", "llvm::(anonymous namespace)::EBP_SuperRegsSet",
  ),
  (
    "_ZN4llvm15SmallVectorImplIjE6resizeEj", "llvm::SmallVectorImpl<unsigned int>::resize(unsigned int)",
    "llvm::SmallVectorImpl<unsigned int>::resize", "llvm::SmallVectorImpl<unsigned int>::resize(unsigned int)",
  ),
  (
    "_ZN4llvm15TargetAsmParserD2Ev", "llvm::TargetAsmParser::~TargetAsmParser()",
    "llvm::TargetAsmParser::~TargetAsmParser", "llvm::TargetAsmParser::~TargetAsmParser()",
  ),
  (
    "_ZN4llvm26ScoreboardHazardRecognizerD0Ev", "llvm::ScoreboardHazardRecognizer::~ScoreboardHazardRecognizer()",
    "llvm::ScoreboardHazardRecognizer::~ScoreboardHazardRecognizer", "llvm::ScoreboardHazardRecognizer::~ScoreboardHazardRecognizer()",
  ),
  (
    "_ZN4llvm13StringMapImpl9RemoveKeyENS_9StringRefE", "llvm::StringMapImpl::RemoveKey(llvm::StringRef)",
    "llvm::StringMapImpl::RemoveKey", "llvm::StringMapImpl::RemoveKey(llvm::StringRef)",
  ),
  (
    "_ZN4llvm22CriticalAntiDepBreakerD2Ev", "llvm::CriticalAntiDepBreaker::~CriticalAntiDepBreaker()",
    "llvm::CriticalAntiDepBreaker::~CriticalAntiDepBreaker", "llvm::CriticalAntiDepBreaker::~CriticalAntiDepBreaker()",
  ),
  (
    "_ZN4llvm18LiveDebugVariables15emitDebugValuesEPNS_10VirtRegMapE", "llvm::LiveDebugVariables::emitDebugValues(llvm::VirtRegMap*)",
    "llvm::LiveDebugVariables::emitDebugValues", "llvm::LiveDebugVariables::emitDebugValues(llvm::VirtRegMap*)",
  ),
  (
    "_ZN4llvm10AsmPrinterC2ERNS_13TargetMachineERNS_10MCStreamerE", "llvm::AsmPrinter::AsmPrinter(llvm::TargetMachine&, llvm::MCStreamer&)",
    "llvm::AsmPrinter::AsmPrinter", "llvm::AsmPrinter::AsmPrinter(llvm::TargetMachine&, llvm::MCStreamer&)",
  ),
  (
    "_ZN4llvm14MCSectionMachOC1ENS_9StringRefES1_jjNS_11SectionKindE", "llvm::MCSectionMachO::MCSectionMachO(llvm::StringRef, llvm::StringRef, unsigned int, unsigned int, llvm::SectionKind)",
    "llvm::MCSectionMachO::MCSectionMachO", "llvm::MCSectionMachO::MCSectionMachO(llvm::StringRef, llvm::StringRef, unsigned int, unsigned int, llvm::SectionKind)",
  ),
  (
    "_ZNK5clang7APValue4dumpEv", "clang::APValue::dump() const", "clang::APValue::dump",
    "clang::APValue::dump() const",
  ),
  (
    "_ZN12_GLOBAL__N_18VerifierD1Ev", "(anonymous namespace)::Verifier::~Verifier()",
    "(anonymous namespace)::Verifier::~Verifier", "(anonymous namespace)::Verifier::~Verifier()",
  ),
  (
    "_ZN4llvm2cl6parserIPFPNS_12FunctionPassEvEED0Ev", "llvm::cl::parser<llvm::FunctionPass* (*)()>::~parser()",
    "llvm::cl::parser<llvm::FunctionPass* (*)()>::~parser", "llvm::cl::parser<llvm::FunctionPass* (*)()>::~parser()",
  ),
  (
    "_ZN4llvm14ARMInstPrinter20printNoHashImmediateEPKNS_6MCInstEjRNS_11raw_ostreamE",
    "llvm::ARMInstPrinter::printNoHashImmediate(llvm::MCInst const*, unsigned int, llvm::raw_ostream&)",
    "llvm::ARMInstPrinter::printNoHashImmediate", "llvm::ARMInstPrinter::printNoHashImmediate(llvm::MCInst const*, unsigned int, llvm::raw_ostream&)",
  ),
  (
    "_ZN5clang4ento14SymbolicRegionD0Ev", "clang::ento::SymbolicRegion::~SymbolicRegion()",
    "clang::ento::SymbolicRegion::~SymbolicRegion", "clang::ento::SymbolicRegion::~SymbolicRegion()",
  ),
  (
    "_ZN4llvm4Pass13releaseMemoryEv", "llvm::Pass::releaseMemory()", "llvm::Pass::releaseMemory",
    "llvm::Pass::releaseMemory()",
  ),
  (
    "_ZN5clang4ento22StackLocalsSpaceRegionD0Ev", "clang::ento::StackLocalsSpaceRegion::~StackLocalsSpaceRegion()",
    "clang::ento::StackLocalsSpaceRegion::~StackLocalsSpaceRegion", "clang::ento::StackLocalsSpaceRegion::~StackLocalsSpaceRegion()",
  ),
  (
    "_ZTVN12_GLOBAL__N_113ARMAsmBackendE", "vtable for (anonymous namespace)::ARMAsmBackend",
    "vtable for (anonymous namespace)::ARMAsmBackend", "vtable for (anonymous namespace)::ARMAsmBackend",
  ),
  (
    "_ZN4llvm3X8610RFP32ClassD0Ev", "llvm::X86::RFP32Class::~RFP32Class()", "llvm::X86::RFP32Class::~RFP32Class",
    "llvm::X86::RFP32Class::~RFP32Class()",
  ),
  (
    "_ZTVN12_GLOBAL__N_113TCETargetInfoE", "vtable for (anonymous namespace)::TCETargetInfo",
    "vtable for (anonymous namespace)::TCETargetInfo", "vtable for (anonymous namespace)::TCETargetInfo",
  ),
  (
    "_ZL19ShrinkWrapDebugging", "ShrinkWrapDebugging", "ShrinkWrapDebugging", "ShrinkWrapDebugging",
  ),
  (
    "_ZN4llvm19SelectionDAGBuilder9visitSExtERKNS_4UserE", "llvm::SelectionDAGBuilder::visitSExt(llvm::User const&)",
    "llvm::SelectionDAGBuilder::visitSExt", "llvm::SelectionDAGBuilder::visitSExt(llvm::User const&)",
  ),
  (
    "_ZN5clang6Parser21ParseObjCAtDirectivesEv", "clang::Parser::ParseObjCAtDirectives()",
    "clang::Parser::ParseObjCAtDirectives", "clang::Parser::ParseObjCAtDirectives()",
  ),
  (
    "_ZN4llvm3sys15ThreadLocalImplC2Ev", "llvm::sys::ThreadLocalImpl::ThreadLocalImpl()",
    "llvm::sys::ThreadLocalImpl::ThreadLocalImpl", "llvm::sys::ThreadLocalImpl::ThreadLocalImpl()",
  ),
  (
    "_ZN12_GLOBAL__N_119MachineVerifierPass2IDE", "(anonymous namespace)::MachineVerifierPass::ID",
    "(anonymous namespace)::MachineVerifierPass::ID", "(anonymous namespace)::MachineVerifierPass::ID",
  ),
  (
    "_Z29ForwardPrebranchedFallthroughPN4llvm10BasicBlockES1_S1_", "ForwardPrebranchedFallthrough(llvm::BasicBlock*, llvm::BasicBlock*, llvm::BasicBlock*)",
    "ForwardPrebranchedFallthrough", "ForwardPrebranchedFallthrough(llvm::BasicBlock*, llvm::BasicBlock*, llvm::BasicBlock*)",
  ),
  (
    "_ZN4llvm10MCAsmLexerD0Ev", "llvm::MCAsmLexer::~MCAsmLexer()", "llvm::MCAsmLexer::~MCAsmLexer",
    "llvm::MCAsmLexer::~MCAsmLexer()",
  ),
  (
    "_ZN4llvm8DbgScopeD1Ev", "llvm::DbgScope::~DbgScope()", "llvm::DbgScope::~DbgScope",
    "llvm::DbgScope::~DbgScope()",
  ),
  (
    "_ZTVN5clang17MultiplexConsumerE", "vtable for clang::MultiplexConsumer", "vtable for clang::MultiplexConsumer",
    "vtable for clang::MultiplexConsumer",
  ),
  (
    "_ZN4llvm15ScalarEvolution14SCEVCallbackVHC2EPNS_5ValueEPS0_", "llvm::ScalarEvolution::SCEVCallbackVH::SCEVCallbackVH(llvm::Value*, llvm::ScalarEvolution*)",
    "llvm::ScalarEvolution::SCEVCallbackVH::SCEVCallbackVH", "llvm::ScalarEvolution::SCEVCallbackVH::SCEVCallbackVH(llvm::Value*, llvm::ScalarEvolution*)",
  ),
  (
    "_ZN4llvm3sys9AtomicDivEPVjj", "llvm::sys::AtomicDiv(unsigned int volatile*, unsigned int)",
    "llvm::sys::AtomicDiv", "llvm::sys::AtomicDiv(unsigned int volatile*, unsigned int)",
  ),
  (
    "_ZTVN12_GLOBAL__N_119FixedAddressCheckerE", "vtable for (anonymous namespace)::FixedAddressChecker",
    "vtable for (anonymous namespace)::FixedAddressChecker", "vtable for (anonymous namespace)::FixedAddressChecker",
  ),
  (
    "_ZN12_GLOBAL__N_110BadReleaseD0Ev", "(anonymous namespace)::BadRelease::~BadRelease()",
    "(anonymous namespace)::BadRelease::~BadRelease", "(anonymous namespace)::BadRelease::~BadRelease()",
  ),
  (
    "_ZN9__gnu_cxx26__concurrence_unlock_errorD2Ev", "__gnu_cxx::__concurrence_unlock_error::~__concurrence_unlock_error()",
    "__gnu_cxx::__concurrence_unlock_error::~__concurrence_unlock_error", "__gnu_cxx::__concurrence_unlock_error::~__concurrence_unlock_error()",
  ),
  (
    "_ZN5clang6Parser25isCXX0XAttributeSpecifierEbPNS_3tok9TokenKindE", "clang::Parser::isCXX0XAttributeSpecifier(bool, clang::tok::TokenKind*)",
    "clang::Parser::isCXX0XAttributeSpecifier", "clang::Parser::isCXX0XAttributeSpecifier(bool, clang::tok::TokenKind*)",
  ),
  (
    "_ZN4llvm18report_fatal_errorEPKc", "llvm::report_fatal_error(char const*)",
    "llvm::report_fatal_error", "llvm::report_fatal_error(char const*)",
  ),
  (
    "_ZN12_GLOBAL__N_114VCallOffsetMap26MethodsCanShareVCallOffsetEPKN5clang13CXXMethodDeclES4_",
    "(anonymous namespace)::VCallOffsetMap::MethodsCanShareVCallOffset(clang::CXXMethodDecl const*, clang::CXXMethodDecl const*)",
    "(anonymous namespace)::VCallOffsetMap::MethodsCanShareVCallOffset", "(anonymous namespace)::VCallOffsetMap::MethodsCanShareVCallOffset(clang::CXXMethodDecl const*, clang::CXXMethodDecl const*)",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L12DR6_OverlapsE", "llvm::(anonymous namespace)::DR6_Overlaps",
    "llvm::(anonymous namespace)::DR6_Overlaps", "llvm::(anonymous namespace)::DR6_Overlaps",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L14RDI_SubRegsSetE", "llvm::(anonymous namespace)::RDI_SubRegsSet",
    "llvm::(anonymous namespace)::RDI_SubRegsSet", "llvm::(anonymous namespace)::RDI_SubRegsSet",
  ),
  ("_ZL14DiagSubGroup17", "DiagSubGroup17", "DiagSubGroup17", "DiagSubGroup17"),
  (
    "_ZN5clang4ento13SymbolVisitorD0Ev", "clang::ento::SymbolVisitor::~SymbolVisitor()",
    "clang::ento::SymbolVisitor::~SymbolVisitor", "clang::ento::SymbolVisitor::~SymbolVisitor()",
  ),
  (
    "_ZNK5clang6driver9ToolChain13TranslateArgsERKNS0_14DerivedArgListEPKc", "clang::driver::ToolChain::TranslateArgs(clang::driver::DerivedArgList const&, char const*) const",
    "clang::driver::ToolChain::TranslateArgs", "clang::driver::ToolChain::TranslateArgs(clang::driver::DerivedArgList const&, char const*) const",
  ),
  (
    "_ZN4llvm12SCEVExpander15visitAddRecExprEPKNS_14SCEVAddRecExprE", "llvm::SCEVExpander::visitAddRecExpr(llvm::SCEVAddRecExpr const*)",
    "llvm::SCEVExpander::visitAddRecExpr", "llvm::SCEVExpander::visitAddRecExpr(llvm::SCEVAddRecExpr const*)",
  ),
  (
    "_ZN12_GLOBAL__N_19AsmParser19ParseDirectiveIfdefEN4llvm5SMLocEb", "(anonymous namespace)::AsmParser::ParseDirectiveIfdef(llvm::SMLoc, bool)",
    "(anonymous namespace)::AsmParser::ParseDirectiveIfdef", "(anonymous namespace)::AsmParser::ParseDirectiveIfdef(llvm::SMLoc, bool)",
  ),
  (
    "_ZN5clang9ASTWriter22WriteDeclsBlockAbbrevsEv", "clang::ASTWriter::WriteDeclsBlockAbbrevs()",
    "clang::ASTWriter::WriteDeclsBlockAbbrevs", "clang::ASTWriter::WriteDeclsBlockAbbrevs()",
  ),
  (
    "_ZN12_GLOBAL__N_116DarwinTargetInfoINS_16X86_64TargetInfoEED1Ev", "(anonymous namespace)::DarwinTargetInfo<(anonymous namespace)::X86_64TargetInfo>::~DarwinTargetInfo()",
    "(anonymous namespace)::DarwinTargetInfo<(anonymous namespace)::X86_64TargetInfo>::~DarwinTargetInfo",
    "(anonymous namespace)::DarwinTargetInfo<(anonymous namespace)::X86_64TargetInfo>::~DarwinTargetInfo()",
  ),
  (
    "_ZNK5clang6driver9ToolChain17UseSjLjExceptionsEv", "clang::driver::ToolChain::UseSjLjExceptions() const",
    "clang::driver::ToolChain::UseSjLjExceptions", "clang::driver::ToolChain::UseSjLjExceptions() const",
  ),
  (
    "_ZN4llvm22X86MachineFunctionInfoD1Ev", "llvm::X86MachineFunctionInfo::~X86MachineFunctionInfo()",
    "llvm::X86MachineFunctionInfo::~X86MachineFunctionInfo", "llvm::X86MachineFunctionInfo::~X86MachineFunctionInfo()",
  ),
  (
    "_ZNK4llvm3EVT13getTypeForEVTERNS_11LLVMContextE", "llvm::EVT::getTypeForEVT(llvm::LLVMContext&) const",
    "llvm::EVT::getTypeForEVT", "llvm::EVT::getTypeForEVT(llvm::LLVMContext&) const",
  ),
  (
    "_ZN4llvm4Type12getX86_MMXTyERNS_11LLVMContextE", "llvm::Type::getX86_MMXTy(llvm::LLVMContext&)",
    "llvm::Type::getX86_MMXTy", "llvm::Type::getX86_MMXTy(llvm::LLVMContext&)",
  ),
  (
    "_ZN4llvm10DwarfDebug13beginFunctionEPKNS_15MachineFunctionE", "llvm::DwarfDebug::beginFunction(llvm::MachineFunction const*)",
    "llvm::DwarfDebug::beginFunction", "llvm::DwarfDebug::beginFunction(llvm::MachineFunction const*)",
  ),
  (
    "_ZN5clang21MaxFieldAlignmentAttrD1Ev", "clang::MaxFieldAlignmentAttr::~MaxFieldAlignmentAttr()",
    "clang::MaxFieldAlignmentAttr::~MaxFieldAlignmentAttr", "clang::MaxFieldAlignmentAttr::~MaxFieldAlignmentAttr()",
  ),
  (
    "_ZN4llvm8DenseMapIPKN5clang7VarDeclEPNS1_24MemberSpecializationInfoENS_12DenseMapInfoIS4_EENS7_IS6_EEE4growEj",
    "llvm::DenseMap<clang::VarDecl const*, clang::MemberSpecializationInfo*, llvm::DenseMapInfo<clang::VarDecl const*>, llvm::DenseMapInfo<clang::MemberSpecializationInfo*>>::grow(unsigned int)",
    "llvm::DenseMap<clang::VarDecl const*, clang::MemberSpecializationInfo*, llvm::DenseMapInfo<clang::VarDecl const*>, llvm::DenseMapInfo<clang::MemberSpecializationInfo*>>::grow",
    "llvm::DenseMap<clang::VarDecl const*, clang::MemberSpecializationInfo*, llvm::DenseMapInfo<clang::VarDecl const*>, llvm::DenseMapInfo<clang::MemberSpecializationInfo*>>::grow(unsigned int)",
  ),
  (
    "_ZN5clang22PseudoConstantAnalysis16isPseudoConstantEPKNS_7VarDeclE", "clang::PseudoConstantAnalysis::isPseudoConstant(clang::VarDecl const*)",
    "clang::PseudoConstantAnalysis::isPseudoConstant", "clang::PseudoConstantAnalysis::isPseudoConstant(clang::VarDecl const*)",
  ),
  (
    "_ZN5clang22AnalysisContextManager10getContextEPKNS_4DeclEPNS_3idx15TranslationUnitE",
    "clang::AnalysisContextManager::getContext(clang::Decl const*, clang::idx::TranslationUnit*)",
    "clang::AnalysisContextManager::getContext", "clang::AnalysisContextManager::getContext(clang::Decl const*, clang::idx::TranslationUnit*)",
  ),
  (
    "_ZN12_GLOBAL__N_116WriteBitcodePassD1Ev", "(anonymous namespace)::WriteBitcodePass::~WriteBitcodePass()",
    "(anonymous namespace)::WriteBitcodePass::~WriteBitcodePass", "(anonymous namespace)::WriteBitcodePass::~WriteBitcodePass()",
  ),
  (
    "_ZN4llvm16UnaryInstructionD0Ev", "llvm::UnaryInstruction::~UnaryInstruction()",
    "llvm::UnaryInstruction::~UnaryInstruction", "llvm::UnaryInstruction::~UnaryInstruction()",
  ),
  (
    "_ZN4llvm10FoldingSetIN5clang4ento9MemRegionEED0Ev", "llvm::FoldingSet<clang::ento::MemRegion>::~FoldingSet()",
    "llvm::FoldingSet<clang::ento::MemRegion>::~FoldingSet", "llvm::FoldingSet<clang::ento::MemRegion>::~FoldingSet()",
  ),
  (
    "_ZN12_GLOBAL__N_122CGObjCNonFragileABIMac27EnumerationMutationFunctionEv", "(anonymous namespace)::CGObjCNonFragileABIMac::EnumerationMutationFunction()",
    "(anonymous namespace)::CGObjCNonFragileABIMac::EnumerationMutationFunction",
    "(anonymous namespace)::CGObjCNonFragileABIMac::EnumerationMutationFunction()",
  ),
  ("_ZL13nUsingShadows", "nUsingShadows", "nUsingShadows", "nUsingShadows"),
  (
    "_ZN5clang11DeclVisitorIN12_GLOBAL__N_115SelectorIndexerEvE5VisitEPNS_4DeclE",
    "clang::DeclVisitor<(anonymous namespace)::SelectorIndexer, void>::Visit(clang::Decl*)",
    "clang::DeclVisitor<(anonymous namespace)::SelectorIndexer, void>::Visit", "clang::DeclVisitor<(anonymous namespace)::SelectorIndexer, void>::Visit(clang::Decl*)",
  ),
  (
    "_ZN4llvm12SelectionDAG7getNodeEjNS_8DebugLocENS_8SDVTListENS_7SDValueES3_S3_S3_",
    "llvm::SelectionDAG::getNode(unsigned int, llvm::DebugLoc, llvm::SDVTList, llvm::SDValue, llvm::SDValue, llvm::SDValue, llvm::SDValue)",
    "llvm::SelectionDAG::getNode", "llvm::SelectionDAG::getNode(unsigned int, llvm::DebugLoc, llvm::SDVTList, llvm::SDValue, llvm::SDValue, llvm::SDValue, llvm::SDValue)",
  ),
  (
    "_ZN5clang15ConstructorAttrD1Ev", "clang::ConstructorAttr::~ConstructorAttr()",
    "clang::ConstructorAttr::~ConstructorAttr", "clang::ConstructorAttr::~ConstructorAttr()",
  ),
  ("_ZL10MatchTable", "MatchTable", "MatchTable", "MatchTable"),
  (
    "_ZNK5clang17ObjCInterfaceDecl22getFirstClassExtensionEv", "clang::ObjCInterfaceDecl::getFirstClassExtension() const",
    "clang::ObjCInterfaceDecl::getFirstClassExtension", "clang::ObjCInterfaceDecl::getFirstClassExtension() const",
  ),
  (
    "_Z9parseWordPKc", "parseWord(char const*)", "parseWord", "parseWord(char const*)",
  ),
  (
    "_ZNK12_GLOBAL__N_114NetBSDHostInfo15CreateToolChainERKN5clang6driver7ArgListEPKc",
    "(anonymous namespace)::NetBSDHostInfo::CreateToolChain(clang::driver::ArgList const&, char const*) const",
    "(anonymous namespace)::NetBSDHostInfo::CreateToolChain", "(anonymous namespace)::NetBSDHostInfo::CreateToolChain(clang::driver::ArgList const&, char const*) const",
  ),
  (
    "_ZTVN12_GLOBAL__N_115MinixTargetInfoINS_16X86_32TargetInfoEEE", "vtable for (anonymous namespace)::MinixTargetInfo<(anonymous namespace)::X86_32TargetInfo>",
    "vtable for (anonymous namespace)::MinixTargetInfo<(anonymous namespace)::X86_32TargetInfo>",
    "vtable for (anonymous namespace)::MinixTargetInfo<(anonymous namespace)::X86_32TargetInfo>",
  ),
  (
    "_ZL23DisableHazardRecognizer", "DisableHazardRecognizer", "DisableHazardRecognizer",
    "DisableHazardRecognizer",
  ),
  (
    "_ZN5clang17MultiplexConsumer22GetASTMutationListenerEv", "clang::MultiplexConsumer::GetASTMutationListener()",
    "clang::MultiplexConsumer::GetASTMutationListener", "clang::MultiplexConsumer::GetASTMutationListener()",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L16QQQQ2_SubRegsSetE", "llvm::(anonymous namespace)::QQQQ2_SubRegsSet",
    "llvm::(anonymous namespace)::QQQQ2_SubRegsSet", "llvm::(anonymous namespace)::QQQQ2_SubRegsSet",
  ),
  (
    "_ZNK4llvm12DISubprogram14getCompileUnitEv", "llvm::DISubprogram::getCompileUnit() const",
    "llvm::DISubprogram::getCompileUnit", "llvm::DISubprogram::getCompileUnit() const",
  ),
  (
    "_ZN12_GLOBAL__N_114AllocaPromoterD0Ev", "(anonymous namespace)::AllocaPromoter::~AllocaPromoter()",
    "(anonymous namespace)::AllocaPromoter::~AllocaPromoter", "(anonymous namespace)::AllocaPromoter::~AllocaPromoter()",
  ),
  (
    "_ZN4llvm14TargetRegistry5beginEv", "llvm::TargetRegistry::begin()", "llvm::TargetRegistry::begin",
    "llvm::TargetRegistry::begin()",
  ),
  (
    "_ZNK5clang4Type13isComplexTypeEv", "clang::Type::isComplexType() const", "clang::Type::isComplexType",
    "clang::Type::isComplexType() const",
  ),
  (
    "_ZN4llvm14IndirectBrInst17removeDestinationEj", "llvm::IndirectBrInst::removeDestination(unsigned int)",
    "llvm::IndirectBrInst::removeDestination", "llvm::IndirectBrInst::removeDestination(unsigned int)",
  ),
  (
    "_ZN4llvm24TargetLoweringObjectFileD1Ev", "llvm::TargetLoweringObjectFile::~TargetLoweringObjectFile()",
    "llvm::TargetLoweringObjectFile::~TargetLoweringObjectFile", "llvm::TargetLoweringObjectFile::~TargetLoweringObjectFile()",
  ),
  (
    "_ZNK5clang14FrontendAction13hasPCHSupportEv", "clang::FrontendAction::hasPCHSupport() const",
    "clang::FrontendAction::hasPCHSupport", "clang::FrontendAction::hasPCHSupport() const",
  ),
  (
    "_ZN5clang4Sema18CheckObjCDeclScopeEPNS_4DeclE", "clang::Sema::CheckObjCDeclScope(clang::Decl*)",
    "clang::Sema::CheckObjCDeclScope", "clang::Sema::CheckObjCDeclScope(clang::Decl*)",
  ),
  (
    "_ZN12_GLOBAL__N_116FlatStoreManager8RetrieveEPKvN5clang4ento3LocENS3_8QualTypeE",
    "(anonymous namespace)::FlatStoreManager::Retrieve(void const*, clang::ento::Loc, clang::QualType)",
    "(anonymous namespace)::FlatStoreManager::Retrieve", "(anonymous namespace)::FlatStoreManager::Retrieve(void const*, clang::ento::Loc, clang::QualType)",
  ),
  ("_ZL7NumDead", "NumDead", "NumDead", "NumDead"),
  (
    "_ZNK4llvm22UnifyFunctionExitNodes16getAnalysisUsageERNS_13AnalysisUsageE", "llvm::UnifyFunctionExitNodes::getAnalysisUsage(llvm::AnalysisUsage&) const",
    "llvm::UnifyFunctionExitNodes::getAnalysisUsage", "llvm::UnifyFunctionExitNodes::getAnalysisUsage(llvm::AnalysisUsage&) const",
  ),
  (
    "_ZNK4llvm13IRBuilderBase28getCurrentFunctionReturnTypeEv", "llvm::IRBuilderBase::getCurrentFunctionReturnType() const",
    "llvm::IRBuilderBase::getCurrentFunctionReturnType", "llvm::IRBuilderBase::getCurrentFunctionReturnType() const",
  ),
  (
    "_ZN12_GLOBAL__N_117SparcV8TargetInfo13GCCRegAliasesE", "(anonymous namespace)::SparcV8TargetInfo::GCCRegAliases",
    "(anonymous namespace)::SparcV8TargetInfo::GCCRegAliases", "(anonymous namespace)::SparcV8TargetInfo::GCCRegAliases",
  ),
  (
    "_ZN4llvm8FunctionD0Ev", "llvm::Function::~Function()", "llvm::Function::~Function",
    "llvm::Function::~Function()",
  ),
  (
    "_ZN4llvm11make_vectorIjEESt6vectorIT_SaIS2_EES2_z", "std::vector<unsigned int, std::allocator<unsigned int>> llvm::make_vector<unsigned int>(unsigned int, ...)",
    "llvm::make_vector<unsigned int>", "std::vector<unsigned int, std::allocator<unsigned int>> llvm::make_vector<unsigned int>(unsigned int, ...)",
  ),
  (
    "_ZN4llvm15MCAlignFragmentD0Ev", "llvm::MCAlignFragment::~MCAlignFragment()",
    "llvm::MCAlignFragment::~MCAlignFragment", "llvm::MCAlignFragment::~MCAlignFragment()",
  ),
  (
    "_ZN4llvm12SelectionDAG17getExternalSymbolEPKcNS_3EVTE", "llvm::SelectionDAG::getExternalSymbol(char const*, llvm::EVT)",
    "llvm::SelectionDAG::getExternalSymbol", "llvm::SelectionDAG::getExternalSymbol(char const*, llvm::EVT)",
  ),
  (
    "_ZN4llvm10AllocaInstC1EPKNS_4TypeEPNS_5ValueEjRKNS_5TwineEPNS_10BasicBlockE",
    "llvm::AllocaInst::AllocaInst(llvm::Type const*, llvm::Value*, unsigned int, llvm::Twine const&, llvm::BasicBlock*)",
    "llvm::AllocaInst::AllocaInst", "llvm::AllocaInst::AllocaInst(llvm::Type const*, llvm::Value*, unsigned int, llvm::Twine const&, llvm::BasicBlock*)",
  ),
  (
    "_ZN12_GLOBAL__N_125TwoAddressInstructionPass20runOnMachineFunctionERN4llvm15MachineFunctionE",
    "(anonymous namespace)::TwoAddressInstructionPass::runOnMachineFunction(llvm::MachineFunction&)",
    "(anonymous namespace)::TwoAddressInstructionPass::runOnMachineFunction", "(anonymous namespace)::TwoAddressInstructionPass::runOnMachineFunction(llvm::MachineFunction&)",
  ),
  (
    "_ZNK4llvm17X86TargetLowering14isTruncateFreeENS_3EVTES1_", "llvm::X86TargetLowering::isTruncateFree(llvm::EVT, llvm::EVT) const",
    "llvm::X86TargetLowering::isTruncateFree", "llvm::X86TargetLowering::isTruncateFree(llvm::EVT, llvm::EVT) const",
  ),
  (
    "_ZN12_GLOBAL__N_114NSErrorCheckerD1Ev", "(anonymous namespace)::NSErrorChecker::~NSErrorChecker()",
    "(anonymous namespace)::NSErrorChecker::~NSErrorChecker", "(anonymous namespace)::NSErrorChecker::~NSErrorChecker()",
  ),
  (
    "_ZN23ImageLoaderMachOClassic16prefetchLINKEDITERKN11ImageLoader11LinkContextE",
    "ImageLoaderMachOClassic::prefetchLINKEDIT(ImageLoader::LinkContext const&)",
    "ImageLoaderMachOClassic::prefetchLINKEDIT", "ImageLoaderMachOClassic::prefetchLINKEDIT(ImageLoader::LinkContext const&)",
  ),
  ("_ZL10Aggressive", "Aggressive", "Aggressive", "Aggressive"),
  (
    "_ZNK5clang11DeclContext20CreateStoredDeclsMapERNS_10ASTContextE", "clang::DeclContext::CreateStoredDeclsMap(clang::ASTContext&) const",
    "clang::DeclContext::CreateStoredDeclsMap", "clang::DeclContext::CreateStoredDeclsMap(clang::ASTContext&) const",
  ),
  ("i", "i", "i", "int"),
  (
    "_ZN4llvm3X869VR64ClassD1Ev", "llvm::X86::VR64Class::~VR64Class()", "llvm::X86::VR64Class::~VR64Class",
    "llvm::X86::VR64Class::~VR64Class()",
  ),
  (
    "_ZNK12_GLOBAL__N_115PostRAScheduler16getAnalysisUsageERN4llvm13AnalysisUsageE",
    "(anonymous namespace)::PostRAScheduler::getAnalysisUsage(llvm::AnalysisUsage&) const",
    "(anonymous namespace)::PostRAScheduler::getAnalysisUsage", "(anonymous namespace)::PostRAScheduler::getAnalysisUsage(llvm::AnalysisUsage&) const",
  ),
  (
    "_ZN5clang8QualType27getSplitUnqualifiedTypeImplES0_", "clang::QualType::getSplitUnqualifiedTypeImpl(clang::QualType)",
    "clang::QualType::getSplitUnqualifiedTypeImpl", "clang::QualType::getSplitUnqualifiedTypeImpl(clang::QualType)",
  ),
  (
    "_ZNK12_GLOBAL__N_114ARMGlobalMerge11getPassNameEv", "(anonymous namespace)::ARMGlobalMerge::getPassName() const",
    "(anonymous namespace)::ARMGlobalMerge::getPassName", "(anonymous namespace)::ARMGlobalMerge::getPassName() const",
  ),
  (
    "_ZNK4llvm14format_object1IxE7snprintEPcj", "llvm::format_object1<long long>::snprint(char*, unsigned int) const",
    "llvm::format_object1<long long>::snprint", "llvm::format_object1<long long>::snprint(char*, unsigned int) const",
  ),
  (
    "_ZN5clang18IdentifierResolver10IdDeclInfo11ReplaceDeclEPNS_9NamedDeclES3_",
    "clang::IdentifierResolver::IdDeclInfo::ReplaceDecl(clang::NamedDecl*, clang::NamedDecl*)",
    "clang::IdentifierResolver::IdDeclInfo::ReplaceDecl", "clang::IdentifierResolver::IdDeclInfo::ReplaceDecl(clang::NamedDecl*, clang::NamedDecl*)",
  ),
  (
    "_ZN5clang20TargetAttributesSemaD1Ev", "clang::TargetAttributesSema::~TargetAttributesSema()",
    "clang::TargetAttributesSema::~TargetAttributesSema", "clang::TargetAttributesSema::~TargetAttributesSema()",
  ),
  (
    "_ZNK12_GLOBAL__N_113BBPassManager11getPassNameEv", "(anonymous namespace)::BBPassManager::getPassName() const",
    "(anonymous namespace)::BBPassManager::getPassName", "(anonymous namespace)::BBPassManager::getPassName() const",
  ),
  (
    "_ZN5clang4SemaD2Ev", "clang::Sema::~Sema()", "clang::Sema::~Sema", "clang::Sema::~Sema()",
  ),
  (
    "_ZNK4llvm2cl3optINS_14PassDebugLevelELb0ENS0_6parserIS2_EEE15printOptionInfoEm",
    "llvm::cl::opt<llvm::PassDebugLevel, false, llvm::cl::parser<llvm::PassDebugLevel>>::printOptionInfo(unsigned long) const",
    "llvm::cl::opt<llvm::PassDebugLevel, false, llvm::cl::parser<llvm::PassDebugLevel>>::printOptionInfo",
    "llvm::cl::opt<llvm::PassDebugLevel, false, llvm::cl::parser<llvm::PassDebugLevel>>::printOptionInfo(unsigned long) const",
  ),
  (
    "_ZN4llvm19SelectionDAGBuilderC2ERNS_12SelectionDAGERNS_20FunctionLoweringInfoENS_10CodeGenOpt5LevelE",
    "llvm::SelectionDAGBuilder::SelectionDAGBuilder(llvm::SelectionDAG&, llvm::FunctionLoweringInfo&, llvm::CodeGenOpt::Level)",
    "llvm::SelectionDAGBuilder::SelectionDAGBuilder", "llvm::SelectionDAGBuilder::SelectionDAGBuilder(llvm::SelectionDAG&, llvm::FunctionLoweringInfo&, llvm::CodeGenOpt::Level)",
  ),
  (
    "_ZN5clang4Sema24CheckCXXDefaultArgumentsEPNS_12FunctionDeclE", "clang::Sema::CheckCXXDefaultArguments(clang::FunctionDecl*)",
    "clang::Sema::CheckCXXDefaultArguments", "clang::Sema::CheckCXXDefaultArguments(clang::FunctionDecl*)",
  ),
  (
    "_ZN5clang6Parser29ParseBuiltinPrimaryExpressionEv", "clang::Parser::ParseBuiltinPrimaryExpression()",
    "clang::Parser::ParseBuiltinPrimaryExpression", "clang::Parser::ParseBuiltinPrimaryExpression()",
  ),
  (
    "_ZN4llvm26ScoreboardHazardRecognizer13getHazardTypeEPNS_5SUnitEi", "llvm::ScoreboardHazardRecognizer::getHazardType(llvm::SUnit*, int)",
    "llvm::ScoreboardHazardRecognizer::getHazardType", "llvm::ScoreboardHazardRecognizer::getHazardType(llvm::SUnit*, int)",
  ),
  (
    "_ZN5clang13ASTDeclWriter36VisitClassTemplateSpecializationDeclEPNS_31ClassTemplateSpecializationDeclE",
    "clang::ASTDeclWriter::VisitClassTemplateSpecializationDecl(clang::ClassTemplateSpecializationDecl*)",
    "clang::ASTDeclWriter::VisitClassTemplateSpecializationDecl", "clang::ASTDeclWriter::VisitClassTemplateSpecializationDecl(clang::ClassTemplateSpecializationDecl*)",
  ),
  (
    "_ZN5clang10SwitchStmtC2ERNS_10ASTContextEPNS_7VarDeclEPNS_4ExprE", "clang::SwitchStmt::SwitchStmt(clang::ASTContext&, clang::VarDecl*, clang::Expr*)",
    "clang::SwitchStmt::SwitchStmt", "clang::SwitchStmt::SwitchStmt(clang::ASTContext&, clang::VarDecl*, clang::Expr*)",
  ),
  (
    "_ZN5clang4ento15HeapSpaceRegionD0Ev", "clang::ento::HeapSpaceRegion::~HeapSpaceRegion()",
    "clang::ento::HeapSpaceRegion::~HeapSpaceRegion", "clang::ento::HeapSpaceRegion::~HeapSpaceRegion()",
  ),
  (
    "_ZNK5clang6driver9ToolChain23IsStrictAliasingDefaultEv", "clang::driver::ToolChain::IsStrictAliasingDefault() const",
    "clang::driver::ToolChain::IsStrictAliasingDefault", "clang::driver::ToolChain::IsStrictAliasingDefault() const",
  ),
  (
    "_ZNK4llvm5APInt3shlERKS0_", "llvm::APInt::shl(llvm::APInt const&) const", "llvm::APInt::shl",
    "llvm::APInt::shl(llvm::APInt const&) const",
  ),
  (
    "_ZN12_GLOBAL__N_114CXXNameMangler12mangleNumberERKN4llvm6APSIntE", "(anonymous namespace)::CXXNameMangler::mangleNumber(llvm::APSInt const&)",
    "(anonymous namespace)::CXXNameMangler::mangleNumber", "(anonymous namespace)::CXXNameMangler::mangleNumber(llvm::APSInt const&)",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L12DR0_OverlapsE", "llvm::(anonymous namespace)::DR0_Overlaps",
    "llvm::(anonymous namespace)::DR0_Overlaps", "llvm::(anonymous namespace)::DR0_Overlaps",
  ),
  (
    "_ZN4llvm7PHINodeC2ERKS0_", "llvm::PHINode::PHINode(llvm::PHINode const&)", "llvm::PHINode::PHINode",
    "llvm::PHINode::PHINode(llvm::PHINode const&)",
  ),
  (
    "_ZNK4llvm16ARMBaseInstrInfo18isStoreToStackSlotEPKNS_12MachineInstrERi", "llvm::ARMBaseInstrInfo::isStoreToStackSlot(llvm::MachineInstr const*, int&) const",
    "llvm::ARMBaseInstrInfo::isStoreToStackSlot", "llvm::ARMBaseInstrInfo::isStoreToStackSlot(llvm::MachineInstr const*, int&) const",
  ),
  (
    "_ZN4llvm10MCStreamer12EmitIntValueEyjj", "llvm::MCStreamer::EmitIntValue(unsigned long long, unsigned int, unsigned int)",
    "llvm::MCStreamer::EmitIntValue", "llvm::MCStreamer::EmitIntValue(unsigned long long, unsigned int, unsigned int)",
  ),
  (
    "_ZN5clang24UnresolvedUsingValueDeclD1Ev", "clang::UnresolvedUsingValueDecl::~UnresolvedUsingValueDecl()",
    "clang::UnresolvedUsingValueDecl::~UnresolvedUsingValueDecl", "clang::UnresolvedUsingValueDecl::~UnresolvedUsingValueDecl()",
  ),
  (
    "_ZN5clang21GetUnderlyingFunctionENS_8QualTypeE", "clang::GetUnderlyingFunction(clang::QualType)",
    "clang::GetUnderlyingFunction", "clang::GetUnderlyingFunction(clang::QualType)",
  ),
  (
    "_ZN5clang4ento12BlockCounter7FactoryD1Ev", "clang::ento::BlockCounter::Factory::~Factory()",
    "clang::ento::BlockCounter::Factory::~Factory", "clang::ento::BlockCounter::Factory::~Factory()",
  ),
  (
    "_ZN5clang9ASTReader10SetLabelOfEPNS_13AddrLabelExprEj", "clang::ASTReader::SetLabelOf(clang::AddrLabelExpr*, unsigned int)",
    "clang::ASTReader::SetLabelOf", "clang::ASTReader::SetLabelOf(clang::AddrLabelExpr*, unsigned int)",
  ),
  (
    "_ZN12_GLOBAL__N_119ClassReleaseCheckerD0Ev", "(anonymous namespace)::ClassReleaseChecker::~ClassReleaseChecker()",
    "(anonymous namespace)::ClassReleaseChecker::~ClassReleaseChecker", "(anonymous namespace)::ClassReleaseChecker::~ClassReleaseChecker()",
  ),
  (
    "_ZN4llvm8DenseMapIN5clang8SelectorEPNS1_14ObjCMethodDeclENS_12DenseMapInfoIS2_EENS5_IS4_EEE4growEj",
    "llvm::DenseMap<clang::Selector, clang::ObjCMethodDecl*, llvm::DenseMapInfo<clang::Selector>, llvm::DenseMapInfo<clang::ObjCMethodDecl*>>::grow(unsigned int)",
    "llvm::DenseMap<clang::Selector, clang::ObjCMethodDecl*, llvm::DenseMapInfo<clang::Selector>, llvm::DenseMapInfo<clang::ObjCMethodDecl*>>::grow",
    "llvm::DenseMap<clang::Selector, clang::ObjCMethodDecl*, llvm::DenseMapInfo<clang::Selector>, llvm::DenseMapInfo<clang::ObjCMethodDecl*>>::grow(unsigned int)",
  ),
  (
    "_ZN4llvm15AliasSetTracker13ASTCallbackVHD0Ev", "llvm::AliasSetTracker::ASTCallbackVH::~ASTCallbackVH()",
    "llvm::AliasSetTracker::ASTCallbackVH::~ASTCallbackVH", "llvm::AliasSetTracker::ASTCallbackVH::~ASTCallbackVH()",
  ),
  (
    "_ZN4llvm15BitstreamWriter10EmitRecordIjEEvjRNS_15SmallVectorImplIT_EEj", "void llvm::BitstreamWriter::EmitRecord<unsigned int>(unsigned int, llvm::SmallVectorImpl<unsigned int>&, unsigned int)",
    "llvm::BitstreamWriter::EmitRecord<unsigned int>", "void llvm::BitstreamWriter::EmitRecord<unsigned int>(unsigned int, llvm::SmallVectorImpl<unsigned int>&, unsigned int)",
  ),
  (
    "_ZNK4llvm12X86InstrInfo19unfoldMemoryOperandERNS_12SelectionDAGEPNS_6SDNodeERNS_15SmallVectorImplIS4_EE",
    "llvm::X86InstrInfo::unfoldMemoryOperand(llvm::SelectionDAG&, llvm::SDNode*, llvm::SmallVectorImpl<llvm::SDNode*>&) const",
    "llvm::X86InstrInfo::unfoldMemoryOperand", "llvm::X86InstrInfo::unfoldMemoryOperand(llvm::SelectionDAG&, llvm::SDNode*, llvm::SmallVectorImpl<llvm::SDNode*>&) const",
  ),
  (
    "_ZN12_GLOBAL__N_115WinCOFFStreamerD1Ev", "(anonymous namespace)::WinCOFFStreamer::~WinCOFFStreamer()",
    "(anonymous namespace)::WinCOFFStreamer::~WinCOFFStreamer", "(anonymous namespace)::WinCOFFStreamer::~WinCOFFStreamer()",
  ),
  (
    "_ZN4llvm12ConstantExpr9getFPToUIEPNS_8ConstantEPKNS_4TypeE", "llvm::ConstantExpr::getFPToUI(llvm::Constant*, llvm::Type const*)",
    "llvm::ConstantExpr::getFPToUI", "llvm::ConstantExpr::getFPToUI(llvm::Constant*, llvm::Type const*)",
  ),
  (
    "_ZN4llvm3sys4path13has_root_nameERKNS_5TwineE", "llvm::sys::path::has_root_name(llvm::Twine const&)",
    "llvm::sys::path::has_root_name", "llvm::sys::path::has_root_name(llvm::Twine const&)",
  ),
  (
    "_ZTVN12_GLOBAL__N_118AttrNonNullCheckerE", "vtable for (anonymous namespace)::AttrNonNullChecker",
    "vtable for (anonymous namespace)::AttrNonNullChecker", "vtable for (anonymous namespace)::AttrNonNullChecker",
  ),
  (
    "_ZN5clang13TypeLocReader27VisitUnresolvedUsingTypeLocENS_22UnresolvedUsingTypeLocE",
    "clang::TypeLocReader::VisitUnresolvedUsingTypeLoc(clang::UnresolvedUsingTypeLoc)",
    "clang::TypeLocReader::VisitUnresolvedUsingTypeLoc", "clang::TypeLocReader::VisitUnresolvedUsingTypeLoc(clang::UnresolvedUsingTypeLoc)",
  ),
  (
    "_ZNK4llvm12DIDescriptor11isNameSpaceEv", "llvm::DIDescriptor::isNameSpace() const",
    "llvm::DIDescriptor::isNameSpace", "llvm::DIDescriptor::isNameSpace() const",
  ),
  (
    "_ZTVN5clang6driver5tools12visualstudio4LinkE", "vtable for clang::driver::tools::visualstudio::Link",
    "vtable for clang::driver::tools::visualstudio::Link", "vtable for clang::driver::tools::visualstudio::Link",
  ),
  (
    "_ZN4llvm15PassManagerImpl3runERNS_6ModuleE", "llvm::PassManagerImpl::run(llvm::Module&)",
    "llvm::PassManagerImpl::run", "llvm::PassManagerImpl::run(llvm::Module&)",
  ),
  (
    "_ZN4llvm12InstCombiner13visitPtrToIntERNS_12PtrToIntInstE", "llvm::InstCombiner::visitPtrToInt(llvm::PtrToIntInst&)",
    "llvm::InstCombiner::visitPtrToInt", "llvm::InstCombiner::visitPtrToInt(llvm::PtrToIntInst&)",
  ),
  (
    "_ZNK4llvm4Pass27getPotentialPassManagerTypeEv", "llvm::Pass::getPotentialPassManagerType() const",
    "llvm::Pass::getPotentialPassManagerType", "llvm::Pass::getPotentialPassManagerType() const",
  ),
  (
    "_ZN4llvm3sys7ProgramC2Ev", "llvm::sys::Program::Program()", "llvm::sys::Program::Program",
    "llvm::sys::Program::Program()",
  ),
  (
    "_ZN4llvm22llvm_execute_on_threadEPFvPvES0_j", "llvm::llvm_execute_on_thread(void (*)(void*), void*, unsigned int)",
    "llvm::llvm_execute_on_thread", "llvm::llvm_execute_on_thread(void (*)(void*), void*, unsigned int)",
  ),
  (
    "_ZN5Casts8implicitILj4EEEvPN9enable_ifIXorT_Li4EEvE4typeE", "void Casts::implicit<4u>(enable_if<4u | 4, void>::type*)",
    "Casts::implicit<4u>", "void Casts::implicit<4u>(enable_if<4u | 4, void>::type*)",
  ),
  (
    "_ZN12_GLOBAL__N_114CodeGenPrepare13releaseMemoryEv", "(anonymous namespace)::CodeGenPrepare::releaseMemory()",
    "(anonymous namespace)::CodeGenPrepare::releaseMemory", "(anonymous namespace)::CodeGenPrepare::releaseMemory()",
  ),
  (
    "_ZNK5clang4Expr17isDefaultArgumentEv", "clang::Expr::isDefaultArgument() const",
    "clang::Expr::isDefaultArgument", "clang::Expr::isDefaultArgument() const",
  ),
  (
    "_ZN5clang4ento14CheckerVisitorIN12_GLOBAL__N_120AnalyzerStatsCheckerEED1Ev",
    "clang::ento::CheckerVisitor<(anonymous namespace)::AnalyzerStatsChecker>::~CheckerVisitor()",
    "clang::ento::CheckerVisitor<(anonymous namespace)::AnalyzerStatsChecker>::~CheckerVisitor",
    "clang::ento::CheckerVisitor<(anonymous namespace)::AnalyzerStatsChecker>::~CheckerVisitor()",
  ),
  (
    "_ZN5clang6driver9ToolChainD1Ev", "clang::driver::ToolChain::~ToolChain()", "clang::driver::ToolChain::~ToolChain",
    "clang::driver::ToolChain::~ToolChain()",
  ),
  (
    "_ZNK4llvm5APInt7uadd_ovERKS0_Rb", "llvm::APInt::uadd_ov(llvm::APInt const&, bool&) const",
    "llvm::APInt::uadd_ov", "llvm::APInt::uadd_ov(llvm::APInt const&, bool&) const",
  ),
  (
    "_ZN12_GLOBAL__N_114ARMGlobalMergeD0Ev", "(anonymous namespace)::ARMGlobalMerge::~ARMGlobalMerge()",
    "(anonymous namespace)::ARMGlobalMerge::~ARMGlobalMerge", "(anonymous namespace)::ARMGlobalMerge::~ARMGlobalMerge()",
  ),
  (
    "_ZN4llvm17MachineModuleInfo29takeDeletedSymbolsForFunctionEPKNS_8FunctionERSt6vectorIPNS_8MCSymbolESaIS6_EE",
    "llvm::MachineModuleInfo::takeDeletedSymbolsForFunction(llvm::Function const*, std::vector<llvm::MCSymbol*, std::allocator<llvm::MCSymbol*>>&)",
    "llvm::MachineModuleInfo::takeDeletedSymbolsForFunction", "llvm::MachineModuleInfo::takeDeletedSymbolsForFunction(llvm::Function const*, std::vector<llvm::MCSymbol*, std::allocator<llvm::MCSymbol*>>&)",
  ),
  ("_ZL13NumMovedCalls", "NumMovedCalls", "NumMovedCalls", "NumMovedCalls"),
  (
    "_ZN4llvm21llvm_is_multithreadedEv", "llvm::llvm_is_multithreaded()", "llvm::llvm_is_multithreaded",
    "llvm::llvm_is_multithreaded()",
  ),
  (
    "_ZN5clang9ASTReader14ReadTypeRecordEj", "clang::ASTReader::ReadTypeRecord(unsigned int)",
    "clang::ASTReader::ReadTypeRecord", "clang::ASTReader::ReadTypeRecord(unsigned int)",
  ),
  (
    "_ZN4llvm10UIToFPInstC2EPNS_5ValueEPKNS_4TypeERKNS_5TwineEPNS_10BasicBlockE",
    "llvm::UIToFPInst::UIToFPInst(llvm::Value*, llvm::Type const*, llvm::Twine const&, llvm::BasicBlock*)",
    "llvm::UIToFPInst::UIToFPInst", "llvm::UIToFPInst::UIToFPInst(llvm::Value*, llvm::Type const*, llvm::Twine const&, llvm::BasicBlock*)",
  ),
  (
    "_ZN12_GLOBAL__N_110SPrintFOptD0Ev", "(anonymous namespace)::SPrintFOpt::~SPrintFOpt()",
    "(anonymous namespace)::SPrintFOpt::~SPrintFOpt", "(anonymous namespace)::SPrintFOpt::~SPrintFOpt()",
  ),
  (
    "_ZN5clang6driver5tools8auroraux8AssembleD0Ev", "clang::driver::tools::auroraux::Assemble::~Assemble()",
    "clang::driver::tools::auroraux::Assemble::~Assemble", "clang::driver::tools::auroraux::Assemble::~Assemble()",
  ),
  (
    "_ZN12_GLOBAL__N_14SROAD1Ev", "(anonymous namespace)::SROA::~SROA()", "(anonymous namespace)::SROA::~SROA",
    "(anonymous namespace)::SROA::~SROA()",
  ),
  (
    "_ZN5clang12Preprocessor18ExpandBuiltinMacroERNS_5TokenE", "clang::Preprocessor::ExpandBuiltinMacro(clang::Token&)",
    "clang::Preprocessor::ExpandBuiltinMacro", "clang::Preprocessor::ExpandBuiltinMacro(clang::Token&)",
  ),
  (
    "_ZN5clang4ento14CodeTextRegionD1Ev", "clang::ento::CodeTextRegion::~CodeTextRegion()",
    "clang::ento::CodeTextRegion::~CodeTextRegion", "clang::ento::CodeTextRegion::~CodeTextRegion()",
  ),
  (
    "_ZN12_GLOBAL__N_116FlatStoreManagerD1Ev", "(anonymous namespace)::FlatStoreManager::~FlatStoreManager()",
    "(anonymous namespace)::FlatStoreManager::~FlatStoreManager", "(anonymous namespace)::FlatStoreManager::~FlatStoreManager()",
  ),
  (
    "_ZN4llvm36initializeTypeBasedAliasAnalysisPassERNS_12PassRegistryE", "llvm::initializeTypeBasedAliasAnalysisPass(llvm::PassRegistry&)",
    "llvm::initializeTypeBasedAliasAnalysisPass", "llvm::initializeTypeBasedAliasAnalysisPass(llvm::PassRegistry&)",
  ),
  (
    "_ZN4llvm8FastISel13FastEmitInst_EjPKNS_19TargetRegisterClassE", "llvm::FastISel::FastEmitInst_(unsigned int, llvm::TargetRegisterClass const*)",
    "llvm::FastISel::FastEmitInst_", "llvm::FastISel::FastEmitInst_(unsigned int, llvm::TargetRegisterClass const*)",
  ),
  (
    "_ZN5clang10ASTContext28getInstantiatedFromUsingDeclEPNS_9UsingDeclE", "clang::ASTContext::getInstantiatedFromUsingDecl(clang::UsingDecl*)",
    "clang::ASTContext::getInstantiatedFromUsingDecl", "clang::ASTContext::getInstantiatedFromUsingDecl(clang::UsingDecl*)",
  ),
  (
    "_ZN12_GLOBAL__N_117DragonFlyHostInfoD0Ev", "(anonymous namespace)::DragonFlyHostInfo::~DragonFlyHostInfo()",
    "(anonymous namespace)::DragonFlyHostInfo::~DragonFlyHostInfo", "(anonymous namespace)::DragonFlyHostInfo::~DragonFlyHostInfo()",
  ),
  (
    "_ZN5clang8UsedAttrD1Ev", "clang::UsedAttr::~UsedAttr()", "clang::UsedAttr::~UsedAttr",
    "clang::UsedAttr::~UsedAttr()",
  ),
  (
    "_ZN4llvm17PseudoSourceValue15getConstantPoolEv", "llvm::PseudoSourceValue::getConstantPool()",
    "llvm::PseudoSourceValue::getConstantPool", "llvm::PseudoSourceValue::getConstantPool()",
  ),
  (
    "_ZN4llvm15SmallVectorImplIPNS_18MCParsedAsmOperandEE6insertEPS2_RKS2_", "llvm::SmallVectorImpl<llvm::MCParsedAsmOperand*>::insert(llvm::MCParsedAsmOperand**, llvm::MCParsedAsmOperand* const&)",
    "llvm::SmallVectorImpl<llvm::MCParsedAsmOperand*>::insert", "llvm::SmallVectorImpl<llvm::MCParsedAsmOperand*>::insert(llvm::MCParsedAsmOperand**, llvm::MCParsedAsmOperand* const&)",
  ),
  (
    "_ZN5clang16EnumConstantDeclD1Ev", "clang::EnumConstantDecl::~EnumConstantDecl()",
    "clang::EnumConstantDecl::~EnumConstantDecl", "clang::EnumConstantDecl::~EnumConstantDecl()",
  ),
  (
    "_ZN5clang6Parser19ParseCastExpressionEbbNS_9OpaquePtrINS_8QualTypeEEE", "clang::Parser::ParseCastExpression(bool, bool, clang::OpaquePtr<clang::QualType>)",
    "clang::Parser::ParseCastExpression", "clang::Parser::ParseCastExpression(bool, bool, clang::OpaquePtr<clang::QualType>)",
  ),
  (
    "_Z24ValueHasExactlyOneBitSetN4llvm7SDValueERKNS_12SelectionDAGE", "ValueHasExactlyOneBitSet(llvm::SDValue, llvm::SelectionDAG const&)",
    "ValueHasExactlyOneBitSet", "ValueHasExactlyOneBitSet(llvm::SDValue, llvm::SelectionDAG const&)",
  ),
  (
    "_ZN4llvm6Module13DematerializeEPNS_11GlobalValueE", "llvm::Module::Dematerialize(llvm::GlobalValue*)",
    "llvm::Module::Dematerialize", "llvm::Module::Dematerialize(llvm::GlobalValue*)",
  ),
  (
    "_ZNK5clang4ento14SymbolicRegion11isBoundableEv", "clang::ento::SymbolicRegion::isBoundable() const",
    "clang::ento::SymbolicRegion::isBoundable", "clang::ento::SymbolicRegion::isBoundable() const",
  ),
  (
    "_ZN12_GLOBAL__N_112StatListenerD1Ev", "(anonymous namespace)::StatListener::~StatListener()",
    "(anonymous namespace)::StatListener::~StatListener", "(anonymous namespace)::StatListener::~StatListener()",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L13R15W_OverlapsE", "llvm::(anonymous namespace)::R15W_Overlaps",
    "llvm::(anonymous namespace)::R15W_Overlaps", "llvm::(anonymous namespace)::R15W_Overlaps",
  ),
  (
    "_ZN4llvm13MCSectionDataC1ERKNS_9MCSectionEPNS_11MCAssemblerE", "llvm::MCSectionData::MCSectionData(llvm::MCSection const&, llvm::MCAssembler*)",
    "llvm::MCSectionData::MCSectionData", "llvm::MCSectionData::MCSectionData(llvm::MCSection const&, llvm::MCAssembler*)",
  ),
  (
    "_ZN5clang13LiveVariables14runOnAllBlocksERKNS_3CFGEPNS_24LiveVariables_ValueTypes10ObserverTyEb",
    "clang::LiveVariables::runOnAllBlocks(clang::CFG const&, clang::LiveVariables_ValueTypes::ObserverTy*, bool)",
    "clang::LiveVariables::runOnAllBlocks", "clang::LiveVariables::runOnAllBlocks(clang::CFG const&, clang::LiveVariables_ValueTypes::ObserverTy*, bool)",
  ),
  (
    "_ZN12_GLOBAL__N_118BasicAliasAnalysis2IDE", "(anonymous namespace)::BasicAliasAnalysis::ID",
    "(anonymous namespace)::BasicAliasAnalysis::ID", "(anonymous namespace)::BasicAliasAnalysis::ID",
  ),
  (
    "_ZN4llvm19FunctionPassManager14doFinalizationEv", "llvm::FunctionPassManager::doFinalization()",
    "llvm::FunctionPassManager::doFinalization", "llvm::FunctionPassManager::doFinalization()",
  ),
  (
    "_ZN4llvm11EdgeBundles20runOnMachineFunctionERNS_15MachineFunctionE", "llvm::EdgeBundles::runOnMachineFunction(llvm::MachineFunction&)",
    "llvm::EdgeBundles::runOnMachineFunction", "llvm::EdgeBundles::runOnMachineFunction(llvm::MachineFunction&)",
  ),
  (
    "_ZN5clang9NakedAttrD0Ev", "clang::NakedAttr::~NakedAttr()", "clang::NakedAttr::~NakedAttr",
    "clang::NakedAttr::~NakedAttr()",
  ),
  (
    "_ZN4llvm14ConstantVectorC2EPKNS_10VectorTypeERKSt6vectorIPNS_8ConstantESaIS6_EE",
    "llvm::ConstantVector::ConstantVector(llvm::VectorType const*, std::vector<llvm::Constant*, std::allocator<llvm::Constant*>> const&)",
    "llvm::ConstantVector::ConstantVector", "llvm::ConstantVector::ConstantVector(llvm::VectorType const*, std::vector<llvm::Constant*, std::allocator<llvm::Constant*>> const&)",
  ),
  (
    "_ZNK5clang10RecordDecl11field_beginEv", "clang::RecordDecl::field_begin() const",
    "clang::RecordDecl::field_begin", "clang::RecordDecl::field_begin() const",
  ),
  (
    "_ZN5clang4Sema24CodeCompleteObjCSelectorEPNS_5ScopeEPPNS_14IdentifierInfoEj",
    "clang::Sema::CodeCompleteObjCSelector(clang::Scope*, clang::IdentifierInfo**, unsigned int)",
    "clang::Sema::CodeCompleteObjCSelector", "clang::Sema::CodeCompleteObjCSelector(clang::Scope*, clang::IdentifierInfo**, unsigned int)",
  ),
  (
    "_ZN5clang14NSConsumedAttrD0Ev", "clang::NSConsumedAttr::~NSConsumedAttr()",
    "clang::NSConsumedAttr::~NSConsumedAttr", "clang::NSConsumedAttr::~NSConsumedAttr()",
  ),
  (
    "_ZN4llvm7LLLexer8LexQuoteEv", "llvm::LLLexer::LexQuote()", "llvm::LLLexer::LexQuote",
    "llvm::LLLexer::LexQuote()",
  ),
  (
    "_ZN12_GLOBAL__N_121ObjCCommonTypesHelper19getExceptionThrowFnEv", "(anonymous namespace)::ObjCCommonTypesHelper::getExceptionThrowFn()",
    "(anonymous namespace)::ObjCCommonTypesHelper::getExceptionThrowFn", "(anonymous namespace)::ObjCCommonTypesHelper::getExceptionThrowFn()",
  ),
  (
    "_ZN4llvm15BitstreamCursor4ReadEj", "llvm::BitstreamCursor::Read(unsigned int)",
    "llvm::BitstreamCursor::Read", "llvm::BitstreamCursor::Read(unsigned int)",
  ),
  (
    "_ZN4llvm3ARML21QQPR_VFP2SuperclassesE", "llvm::ARM::QQPR_VFP2Superclasses",
    "llvm::ARM::QQPR_VFP2Superclasses", "llvm::ARM::QQPR_VFP2Superclasses",
  ),
  (
    "_ZNK12_GLOBAL__N_115LowerIntrinsics11getPassNameEv", "(anonymous namespace)::LowerIntrinsics::getPassName() const",
    "(anonymous namespace)::LowerIntrinsics::getPassName", "(anonymous namespace)::LowerIntrinsics::getPassName() const",
  ),
  (
    "_ZNK4llvm15DICompositeType5printERNS_11raw_ostreamE", "llvm::DICompositeType::print(llvm::raw_ostream&) const",
    "llvm::DICompositeType::print", "llvm::DICompositeType::print(llvm::raw_ostream&) const",
  ),
  (
    "_ZN4llvm12ProfileInfoTINS_8FunctionENS_10BasicBlockEE8transferEPKS1_S5_", "llvm::ProfileInfoT<llvm::Function, llvm::BasicBlock>::transfer(llvm::Function const*, llvm::Function const*)",
    "llvm::ProfileInfoT<llvm::Function, llvm::BasicBlock>::transfer", "llvm::ProfileInfoT<llvm::Function, llvm::BasicBlock>::transfer(llvm::Function const*, llvm::Function const*)",
  ),
  (
    "_ZNK4llvm17MachineMemOperand12getAlignmentEv", "llvm::MachineMemOperand::getAlignment() const",
    "llvm::MachineMemOperand::getAlignment", "llvm::MachineMemOperand::getAlignment() const",
  ),
  (
    "_ZN5clang4ento15RangedBugReportD2Ev", "clang::ento::RangedBugReport::~RangedBugReport()",
    "clang::ento::RangedBugReport::~RangedBugReport", "clang::ento::RangedBugReport::~RangedBugReport()",
  ),
  (
    "_ZNK5clang15UsingShadowDecl12getUsingDeclEv", "clang::UsingShadowDecl::getUsingDecl() const",
    "clang::UsingShadowDecl::getUsingDecl", "clang::UsingShadowDecl::getUsingDecl() const",
  ),
  (
    "_ZN12_GLOBAL__N_19CGObjCMac25EmitTryOrSynchronizedStmtERN5clang7CodeGen15CodeGenFunctionERKNS1_4StmtE",
    "(anonymous namespace)::CGObjCMac::EmitTryOrSynchronizedStmt(clang::CodeGen::CodeGenFunction&, clang::Stmt const&)",
    "(anonymous namespace)::CGObjCMac::EmitTryOrSynchronizedStmt", "(anonymous namespace)::CGObjCMac::EmitTryOrSynchronizedStmt(clang::CodeGen::CodeGenFunction&, clang::Stmt const&)",
  ),
  (
    "_ZN12_GLOBAL__N_18VerifierD0Ev", "(anonymous namespace)::Verifier::~Verifier()",
    "(anonymous namespace)::Verifier::~Verifier", "(anonymous namespace)::Verifier::~Verifier()",
  ),
  (
    "_ZNK12_GLOBAL__N_125RegReductionPriorityQueueINS_17hybrid_ls_rr_sortEE4dumpEPN4llvm11ScheduleDAGE",
    "(anonymous namespace)::RegReductionPriorityQueue<(anonymous namespace)::hybrid_ls_rr_sort>::dump(llvm::ScheduleDAG*) const",
    "(anonymous namespace)::RegReductionPriorityQueue<(anonymous namespace)::hybrid_ls_rr_sort>::dump",
    "(anonymous namespace)::RegReductionPriorityQueue<(anonymous namespace)::hybrid_ls_rr_sort>::dump(llvm::ScheduleDAG*) const",
  ),
  (
    "_ZTVN4llvm10MCAsmLexerE", "vtable for llvm::MCAsmLexer", "vtable for llvm::MCAsmLexer",
    "vtable for llvm::MCAsmLexer",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L14QQ4_SubRegsSetE", "llvm::(anonymous namespace)::QQ4_SubRegsSet",
    "llvm::(anonymous namespace)::QQ4_SubRegsSet", "llvm::(anonymous namespace)::QQ4_SubRegsSet",
  ),
  ("_ZL8StatLock", "StatLock", "StatLock", "StatLock"),
  (
    "_ZN4llvm12_GLOBAL__N_1L15R11W_SubRegsSetE", "llvm::(anonymous namespace)::R11W_SubRegsSet",
    "llvm::(anonymous namespace)::R11W_SubRegsSet", "llvm::(anonymous namespace)::R11W_SubRegsSet",
  ),
  (
    "_Z15ClassifyUnnamedRN5clang10ASTContextENS_8QualTypeE", "ClassifyUnnamed(clang::ASTContext&, clang::QualType)",
    "ClassifyUnnamed", "ClassifyUnnamed(clang::ASTContext&, clang::QualType)",
  ),
  (
    "_ZN4llvmL13OperandInfo97E", "llvm::OperandInfo97", "llvm::OperandInfo97", "llvm::OperandInfo97",
  ),
  (
    "_ZN5clang17ExternalASTSource21FinishedDeserializingEv", "clang::ExternalASTSource::FinishedDeserializing()",
    "clang::ExternalASTSource::FinishedDeserializing", "clang::ExternalASTSource::FinishedDeserializing()",
  ),
  (
    "_ZN4llvm11ScheduleDAGD0Ev", "llvm::ScheduleDAG::~ScheduleDAG()", "llvm::ScheduleDAG::~ScheduleDAG",
    "llvm::ScheduleDAG::~ScheduleDAG()",
  ),
  (
    "_ZN4llvm18InlineCostAnalyzer5clearEv", "llvm::InlineCostAnalyzer::clear()",
    "llvm::InlineCostAnalyzer::clear", "llvm::InlineCostAnalyzer::clear()",
  ),
  (
    "_ZL18nFunctionTemplates", "nFunctionTemplates", "nFunctionTemplates", "nFunctionTemplates",
  ),
  (
    "_ZN26ImageLoaderMachOCompressed18setSymbolTableInfoEPK11macho_nlistPKcPK16dysymtab_command",
    "ImageLoaderMachOCompressed::setSymbolTableInfo(macho_nlist const*, char const*, dysymtab_command const*)",
    "ImageLoaderMachOCompressed::setSymbolTableInfo", "ImageLoaderMachOCompressed::setSymbolTableInfo(macho_nlist const*, char const*, dysymtab_command const*)",
  ),
  (
    "_ZN4llvm16DAGTypeLegalizer19SoftenFloatRes_FDIVEPNS_6SDNodeE", "llvm::DAGTypeLegalizer::SoftenFloatRes_FDIV(llvm::SDNode*)",
    "llvm::DAGTypeLegalizer::SoftenFloatRes_FDIV", "llvm::DAGTypeLegalizer::SoftenFloatRes_FDIV(llvm::SDNode*)",
  ),
  (
    "_ZN4llvm10SSAUpdaterC2EPNS_15SmallVectorImplIPNS_7PHINodeEEE", "llvm::SSAUpdater::SSAUpdater(llvm::SmallVectorImpl<llvm::PHINode*>*)",
    "llvm::SSAUpdater::SSAUpdater", "llvm::SSAUpdater::SSAUpdater(llvm::SmallVectorImpl<llvm::PHINode*>*)",
  ),
  (
    "_ZNK4llvm9SourceMgr12PrintMessageENS_5SMLocERKNS_5TwineEPKcb", "llvm::SourceMgr::PrintMessage(llvm::SMLoc, llvm::Twine const&, char const*, bool) const",
    "llvm::SourceMgr::PrintMessage", "llvm::SourceMgr::PrintMessage(llvm::SMLoc, llvm::Twine const&, char const*, bool) const",
  ),
  (
    "_ZN12_GLOBAL__N_110ToAsciiOptD1Ev", "(anonymous namespace)::ToAsciiOpt::~ToAsciiOpt()",
    "(anonymous namespace)::ToAsciiOpt::~ToAsciiOpt", "(anonymous namespace)::ToAsciiOpt::~ToAsciiOpt()",
  ),
  (
    "_ZN4llvm8DenseMapIjfNS_12DenseMapInfoIjEENS1_IfEEE4growEj", "llvm::DenseMap<unsigned int, float, llvm::DenseMapInfo<unsigned int>, llvm::DenseMapInfo<float>>::grow(unsigned int)",
    "llvm::DenseMap<unsigned int, float, llvm::DenseMapInfo<unsigned int>, llvm::DenseMapInfo<float>>::grow",
    "llvm::DenseMap<unsigned int, float, llvm::DenseMapInfo<unsigned int>, llvm::DenseMapInfo<float>>::grow(unsigned int)",
  ),
  (
    "_ZNK4llvm13FindUsedTypes5printERNS_11raw_ostreamEPKNS_6ModuleE", "llvm::FindUsedTypes::print(llvm::raw_ostream&, llvm::Module const*) const",
    "llvm::FindUsedTypes::print", "llvm::FindUsedTypes::print(llvm::raw_ostream&, llvm::Module const*) const",
  ),
  (
    "_ZN4llvm8DenseMapImjNS_12DenseMapInfoImEENS1_IjEEE16InsertIntoBucketERKmRKjPSt4pairImjE",
    "llvm::DenseMap<unsigned long, unsigned int, llvm::DenseMapInfo<unsigned long>, llvm::DenseMapInfo<unsigned int>>::InsertIntoBucket(unsigned long const&, unsigned int const&, std::pair<unsigned long, unsigned int>*)",
    "llvm::DenseMap<unsigned long, unsigned int, llvm::DenseMapInfo<unsigned long>, llvm::DenseMapInfo<unsigned int>>::InsertIntoBucket",
    "llvm::DenseMap<unsigned long, unsigned int, llvm::DenseMapInfo<unsigned long>, llvm::DenseMapInfo<unsigned int>>::InsertIntoBucket(unsigned long const&, unsigned int const&, std::pair<unsigned long, unsigned int>*)",
  ),
  (
    "_ZNK4llvm14MCSectionMachO12UseCodeAlignEv", "llvm::MCSectionMachO::UseCodeAlign() const",
    "llvm::MCSectionMachO::UseCodeAlign", "llvm::MCSectionMachO::UseCodeAlign() const",
  ),
  (
    "_ZL18nTemplateTypeParms", "nTemplateTypeParms", "nTemplateTypeParms", "nTemplateTypeParms",
  ),
  (
    "_ZN4llvm23SmallVectorTemplateBaseIN5clang9ASTReader15DeclContextInfoELb0EE4growEm",
    "llvm::SmallVectorTemplateBase<clang::ASTReader::DeclContextInfo, false>::grow(unsigned long)",
    "llvm::SmallVectorTemplateBase<clang::ASTReader::DeclContextInfo, false>::grow",
    "llvm::SmallVectorTemplateBase<clang::ASTReader::DeclContextInfo, false>::grow(unsigned long)",
  ),
  (
    "_ZTVN5clang19MSP430InterruptAttrE", "vtable for clang::MSP430InterruptAttr",
    "vtable for clang::MSP430InterruptAttr", "vtable for clang::MSP430InterruptAttr",
  ),
  (
    "_ZN4llvm3X86L18RFP32SubRegClassesE", "llvm::X86::RFP32SubRegClasses", "llvm::X86::RFP32SubRegClasses",
    "llvm::X86::RFP32SubRegClasses",
  ),
  (
    "_ZTVN5clang6Parser11LexedMethodE", "vtable for clang::Parser::LexedMethod",
    "vtable for clang::Parser::LexedMethod", "vtable for clang::Parser::LexedMethod",
  ),
  (
    "_ZN5test61fITk1CiEEvT_", "void test6::f<int>(int)", "test6::f<int>", "void test6::f<int>(int)",
  ),
  (
    "_ZN4llvm3X86L19GR32_ADSuperclassesE", "llvm::X86::GR32_ADSuperclasses", "llvm::X86::GR32_ADSuperclasses",
    "llvm::X86::GR32_ADSuperclasses",
  ),
  (
    "_ZN5clang16CXXConstCastExpr11CreateEmptyERNS_10ASTContextE", "clang::CXXConstCastExpr::CreateEmpty(clang::ASTContext&)",
    "clang::CXXConstCastExpr::CreateEmpty", "clang::CXXConstCastExpr::CreateEmpty(clang::ASTContext&)",
  ),
  (
    "_ZNK4llvm3X869FR32Class20allocation_order_endERKNS_15MachineFunctionE", "llvm::X86::FR32Class::allocation_order_end(llvm::MachineFunction const&) const",
    "llvm::X86::FR32Class::allocation_order_end", "llvm::X86::FR32Class::allocation_order_end(llvm::MachineFunction const&) const",
  ),
  (
    "_ZN12_GLOBAL__N_119ARMMachObjectWriterD0Ev", "(anonymous namespace)::ARMMachObjectWriter::~ARMMachObjectWriter()",
    "(anonymous namespace)::ARMMachObjectWriter::~ARMMachObjectWriter", "(anonymous namespace)::ARMMachObjectWriter::~ARMMachObjectWriter()",
  ),
  (
    "_ZNK5clang18CXXConstructorDecl17isMoveConstructorERj", "clang::CXXConstructorDecl::isMoveConstructor(unsigned int&) const",
    "clang::CXXConstructorDecl::isMoveConstructor", "clang::CXXConstructorDecl::isMoveConstructor(unsigned int&) const",
  ),
  (
    "_ZTVN5clang9FieldDeclE", "vtable for clang::FieldDecl", "vtable for clang::FieldDecl",
    "vtable for clang::FieldDecl",
  ),
  (
    "_ZTVN4llvm10FoldingSetIN5clang19NestedNameSpecifierEEE", "vtable for llvm::FoldingSet<clang::NestedNameSpecifier>",
    "vtable for llvm::FoldingSet<clang::NestedNameSpecifier>", "vtable for llvm::FoldingSet<clang::NestedNameSpecifier>",
  ),
  (
    "_ZN4llvm7LLLexer5LexAtEv", "llvm::LLLexer::LexAt()", "llvm::LLLexer::LexAt",
    "llvm::LLLexer::LexAt()",
  ),
  (
    "_ZN5clang4Sema28CodeCompleteObjCAtVisibilityEPNS_5ScopeE", "clang::Sema::CodeCompleteObjCAtVisibility(clang::Scope*)",
    "clang::Sema::CodeCompleteObjCAtVisibility", "clang::Sema::CodeCompleteObjCAtVisibility(clang::Scope*)",
  ),
  (
    "_ZTVN5clang4ento15HeapSpaceRegionE", "vtable for clang::ento::HeapSpaceRegion",
    "vtable for clang::ento::HeapSpaceRegion", "vtable for clang::ento::HeapSpaceRegion",
  ),
  ("_ZL12NumInstrDups", "NumInstrDups", "NumInstrDups", "NumInstrDups"),
  (
    "_ZN12_GLOBAL__N_115ELFObjectWriter16WriteRelocationsERN4llvm11MCAssemblerERNS1_11MCAsmLayoutE",
    "(anonymous namespace)::ELFObjectWriter::WriteRelocations(llvm::MCAssembler&, llvm::MCAsmLayout&)",
    "(anonymous namespace)::ELFObjectWriter::WriteRelocations", "(anonymous namespace)::ELFObjectWriter::WriteRelocations(llvm::MCAssembler&, llvm::MCAsmLayout&)",
  ),
  (
    "_ZN12_GLOBAL__N_111X86AsmLexerD0Ev", "(anonymous namespace)::X86AsmLexer::~X86AsmLexer()",
    "(anonymous namespace)::X86AsmLexer::~X86AsmLexer", "(anonymous namespace)::X86AsmLexer::~X86AsmLexer()",
  ),
  (
    "_ZNK4llvm13BitcodeReader18isDematerializableEPKNS_11GlobalValueE", "llvm::BitcodeReader::isDematerializable(llvm::GlobalValue const*) const",
    "llvm::BitcodeReader::isDematerializable", "llvm::BitcodeReader::isDematerializable(llvm::GlobalValue const*) const",
  ),
  (
    "_ZN4llvmL14OperandInfo249E", "llvm::OperandInfo249", "llvm::OperandInfo249",
    "llvm::OperandInfo249",
  ),
  (
    "_ZN4llvm15LLVMContextImplD2Ev", "llvm::LLVMContextImpl::~LLVMContextImpl()",
    "llvm::LLVMContextImpl::~LLVMContextImpl", "llvm::LLVMContextImpl::~LLVMContextImpl()",
  ),
  (
    "_ZN4llvm7APFloatD2Ev", "llvm::APFloat::~APFloat()", "llvm::APFloat::~APFloat",
    "llvm::APFloat::~APFloat()",
  ),
  (
    "_ZN4llvm27FixedStackPseudoSourceValueD1Ev", "llvm::FixedStackPseudoSourceValue::~FixedStackPseudoSourceValue()",
    "llvm::FixedStackPseudoSourceValue::~FixedStackPseudoSourceValue", "llvm::FixedStackPseudoSourceValue::~FixedStackPseudoSourceValue()",
  ),
  (
    "_ZN5clang13ASTDeclReader17VisitFunctionDeclEPNS_12FunctionDeclE", "clang::ASTDeclReader::VisitFunctionDecl(clang::FunctionDecl*)",
    "clang::ASTDeclReader::VisitFunctionDecl", "clang::ASTDeclReader::VisitFunctionDecl(clang::FunctionDecl*)",
  ),
  (
    "_ZN12_GLOBAL__N_119TextPathDiagnostics20HandlePathDiagnosticEPKN5clang4ento14PathDiagnosticE",
    "(anonymous namespace)::TextPathDiagnostics::HandlePathDiagnostic(clang::ento::PathDiagnostic const*)",
    "(anonymous namespace)::TextPathDiagnostics::HandlePathDiagnostic", "(anonymous namespace)::TextPathDiagnostics::HandlePathDiagnostic(clang::ento::PathDiagnostic const*)",
  ),
  (
    "_ZNK5clang6driver9ToolChain16GetCXXStdlibTypeERKNS0_7ArgListE", "clang::driver::ToolChain::GetCXXStdlibType(clang::driver::ArgList const&) const",
    "clang::driver::ToolChain::GetCXXStdlibType", "clang::driver::ToolChain::GetCXXStdlibType(clang::driver::ArgList const&) const",
  ),
  (
    "_ZN4llvm16DAGTypeLegalizer18PromoteIntRes_CTLZEPNS_6SDNodeE", "llvm::DAGTypeLegalizer::PromoteIntRes_CTLZ(llvm::SDNode*)",
    "llvm::DAGTypeLegalizer::PromoteIntRes_CTLZ", "llvm::DAGTypeLegalizer::PromoteIntRes_CTLZ(llvm::SDNode*)",
  ),
  (
    "_ZL19NumArrayLenItCounts", "NumArrayLenItCounts", "NumArrayLenItCounts", "NumArrayLenItCounts",
  ),
  (
    "_ZL17PrintFailedFusing", "PrintFailedFusing", "PrintFailedFusing", "PrintFailedFusing",
  ),
  (
    "_ZN5clang9ASTWriter23WritePreprocessorDetailERNS_19PreprocessingRecordE", "clang::ASTWriter::WritePreprocessorDetail(clang::PreprocessingRecord&)",
    "clang::ASTWriter::WritePreprocessorDetail", "clang::ASTWriter::WritePreprocessorDetail(clang::PreprocessingRecord&)",
  ),
  (
    "_ZN12_GLOBAL__N_114PerformFinallyD0Ev", "(anonymous namespace)::PerformFinally::~PerformFinally()",
    "(anonymous namespace)::PerformFinally::~PerformFinally", "(anonymous namespace)::PerformFinally::~PerformFinally()",
  ),
  (
    "_ZN5clang13DiagnosticIDs22isBuiltinExtensionDiagEjRb", "clang::DiagnosticIDs::isBuiltinExtensionDiag(unsigned int, bool&)",
    "clang::DiagnosticIDs::isBuiltinExtensionDiag", "clang::DiagnosticIDs::isBuiltinExtensionDiag(unsigned int, bool&)",
  ),
  (
    "_ZN4llvm13LiveIntervals13releaseMemoryEv", "llvm::LiveIntervals::releaseMemory()",
    "llvm::LiveIntervals::releaseMemory", "llvm::LiveIntervals::releaseMemory()",
  ),
  (
    "_ZN4llvm5TimerD2Ev", "llvm::Timer::~Timer()", "llvm::Timer::~Timer", "llvm::Timer::~Timer()",
  ),
  (
    "_Z34ShouldTryAgainWithRedefinitionTypeRN5clang4SemaERPNS_4ExprE", "ShouldTryAgainWithRedefinitionType(clang::Sema&, clang::Expr*&)",
    "ShouldTryAgainWithRedefinitionType", "ShouldTryAgainWithRedefinitionType(clang::Sema&, clang::Expr*&)",
  ),
  (
    "_ZN4llvm5APIntC2EjNS_9StringRefEh", "llvm::APInt::APInt(unsigned int, llvm::StringRef, unsigned char)",
    "llvm::APInt::APInt", "llvm::APInt::APInt(unsigned int, llvm::StringRef, unsigned char)",
  ),
  (
    "_ZN4llvm3X869GR64ClassC1Ev", "llvm::X86::GR64Class::GR64Class()", "llvm::X86::GR64Class::GR64Class",
    "llvm::X86::GR64Class::GR64Class()",
  ),
  (
    "_ZNK4llvm6Triple15getDarwinNumberERjS1_S1_", "llvm::Triple::getDarwinNumber(unsigned int&, unsigned int&, unsigned int&) const",
    "llvm::Triple::getDarwinNumber", "llvm::Triple::getDarwinNumber(unsigned int&, unsigned int&, unsigned int&) const",
  ),
  (
    "_ZN5clang13ASTStmtWriter18VisitCXXUuidofExprEPNS_13CXXUuidofExprE", "clang::ASTStmtWriter::VisitCXXUuidofExpr(clang::CXXUuidofExpr*)",
    "clang::ASTStmtWriter::VisitCXXUuidofExpr", "clang::ASTStmtWriter::VisitCXXUuidofExpr(clang::CXXUuidofExpr*)",
  ),
  (
    "_ZN5clang4ento16StackSpaceRegionD0Ev", "clang::ento::StackSpaceRegion::~StackSpaceRegion()",
    "clang::ento::StackSpaceRegion::~StackSpaceRegion", "clang::ento::StackSpaceRegion::~StackSpaceRegion()",
  ),
  (
    "_ZTVN12_GLOBAL__N_122DarwinX86_32AsmBackendE", "vtable for (anonymous namespace)::DarwinX86_32AsmBackend",
    "vtable for (anonymous namespace)::DarwinX86_32AsmBackend", "vtable for (anonymous namespace)::DarwinX86_32AsmBackend",
  ),
  (
    "_ZN12_GLOBAL__N_110CFRefCount15BindingsPrinterD1Ev", "(anonymous namespace)::CFRefCount::BindingsPrinter::~BindingsPrinter()",
    "(anonymous namespace)::CFRefCount::BindingsPrinter::~BindingsPrinter", "(anonymous namespace)::CFRefCount::BindingsPrinter::~BindingsPrinter()",
  ),
  (
    "_ZN5clang26ASTDeserializationListener19MacroDefinitionReadEjPNS_15MacroDefinitionE",
    "clang::ASTDeserializationListener::MacroDefinitionRead(unsigned int, clang::MacroDefinition*)",
    "clang::ASTDeserializationListener::MacroDefinitionRead", "clang::ASTDeserializationListener::MacroDefinitionRead(unsigned int, clang::MacroDefinition*)",
  ),
  (
    "_Z19getTypeOfMaskedICmpPN4llvm5ValueES1_S1_NS_7CmpInst9PredicateE", "getTypeOfMaskedICmp(llvm::Value*, llvm::Value*, llvm::Value*, llvm::CmpInst::Predicate)",
    "getTypeOfMaskedICmp", "getTypeOfMaskedICmp(llvm::Value*, llvm::Value*, llvm::Value*, llvm::CmpInst::Predicate)",
  ),
  (
    "_ZNSt6vectorIN5clang8QualTypeESaIS1_EE13_M_insert_auxEN9__gnu_cxx17__normal_iteratorIPS1_S3_EERKS1_",
    "std::vector<clang::QualType, std::allocator<clang::QualType>>::_M_insert_aux(__gnu_cxx::__normal_iterator<clang::QualType*, std::vector<clang::QualType, std::allocator<clang::QualType>>>, clang::QualType const&)",
    "std::vector<clang::QualType, std::allocator<clang::QualType>>::_M_insert_aux",
    "std::vector<clang::QualType, std::allocator<clang::QualType>>::_M_insert_aux(__gnu_cxx::__normal_iterator<clang::QualType*, std::vector<clang::QualType, std::allocator<clang::QualType>>>, clang::QualType const&)",
  ),
  (
    "_ZN5clang4Sema36CheckTemplateArgumentPointerToMemberEPNS_4ExprERNS_16TemplateArgumentE",
    "clang::Sema::CheckTemplateArgumentPointerToMember(clang::Expr*, clang::TemplateArgument&)",
    "clang::Sema::CheckTemplateArgumentPointerToMember", "clang::Sema::CheckTemplateArgumentPointerToMember(clang::Expr*, clang::TemplateArgument&)",
  ),
  (
    "_ZTVSt9bad_alloc", "vtable for std::bad_alloc", "vtable for std::bad_alloc",
    "vtable for std::bad_alloc",
  ),
  (
    "_ZN4llvm11SlotIndexes2IDE", "llvm::SlotIndexes::ID", "llvm::SlotIndexes::ID",
    "llvm::SlotIndexes::ID",
  ),
  (
    "_ZN4llvm3X8610RFP80ClassC1Ev", "llvm::X86::RFP80Class::RFP80Class()", "llvm::X86::RFP80Class::RFP80Class",
    "llvm::X86::RFP80Class::RFP80Class()",
  ),
  (
    "_ZN4llvm16ARMBaseInstrInfoD0Ev", "llvm::ARMBaseInstrInfo::~ARMBaseInstrInfo()",
    "llvm::ARMBaseInstrInfo::~ARMBaseInstrInfo", "llvm::ARMBaseInstrInfo::~ARMBaseInstrInfo()",
  ),
  (
    "_ZNK4llvm14ARMInstPrinter13getOpcodeNameEj", "llvm::ARMInstPrinter::getOpcodeName(unsigned int) const",
    "llvm::ARMInstPrinter::getOpcodeName", "llvm::ARMInstPrinter::getOpcodeName(unsigned int) const",
  ),
  (
    "_ZZN4llvm19X86IntelInstPrinter18getInstructionNameEjE13InstAsmOffset", "llvm::X86IntelInstPrinter::getInstructionName(unsigned int)::InstAsmOffset",
    "llvm::X86IntelInstPrinter::getInstructionName(unsigned int)::InstAsmOffset",
    "llvm::X86IntelInstPrinter::getInstructionName(unsigned int)::InstAsmOffset",
  ),
  (
    "_ZN5clang13ASTStmtWriter31VisitCXXUnresolvedConstructExprEPNS_26CXXUnresolvedConstructExprE",
    "clang::ASTStmtWriter::VisitCXXUnresolvedConstructExpr(clang::CXXUnresolvedConstructExpr*)",
    "clang::ASTStmtWriter::VisitCXXUnresolvedConstructExpr", "clang::ASTStmtWriter::VisitCXXUnresolvedConstructExpr(clang::CXXUnresolvedConstructExpr*)",
  ),
  (
    "_ZN4llvm12SelectionDAG7getNodeEjNS_8DebugLocENS_8SDVTListENS_7SDValueES3_",
    "llvm::SelectionDAG::getNode(unsigned int, llvm::DebugLoc, llvm::SDVTList, llvm::SDValue, llvm::SDValue)",
    "llvm::SelectionDAG::getNode", "llvm::SelectionDAG::getNode(unsigned int, llvm::DebugLoc, llvm::SDVTList, llvm::SDValue, llvm::SDValue)",
  ),
  (
    "_ZNK4llvm4SCEV4dumpEv", "llvm::SCEV::dump() const", "llvm::SCEV::dump", "llvm::SCEV::dump() const",
  ),
  (
    "_ZN12_GLOBAL__N_118DeclContextPrinterD0Ev", "(anonymous namespace)::DeclContextPrinter::~DeclContextPrinter()",
    "(anonymous namespace)::DeclContextPrinter::~DeclContextPrinter", "(anonymous namespace)::DeclContextPrinter::~DeclContextPrinter()",
  ),
  (
    "_ZZ20_dyld_get_image_nameE8__func__", "_dyld_get_image_name::__func__", "_dyld_get_image_name::__func__",
    "_dyld_get_image_name::__func__",
  ),
  (
    "_ZNK4llvm16MachineFrameInfo5printERKNS_15MachineFunctionERNS_11raw_ostreamE",
    "llvm::MachineFrameInfo::print(llvm::MachineFunction const&, llvm::raw_ostream&) const",
    "llvm::MachineFrameInfo::print", "llvm::MachineFrameInfo::print(llvm::MachineFunction const&, llvm::raw_ostream&) const",
  ),
  (
    "_ZN5clang6Parser16ExpectAndConsumeENS_3tok9TokenKindEjPKcS2_", "clang::Parser::ExpectAndConsume(clang::tok::TokenKind, unsigned int, char const*, clang::tok::TokenKind)",
    "clang::Parser::ExpectAndConsume", "clang::Parser::ExpectAndConsume(clang::tok::TokenKind, unsigned int, char const*, clang::tok::TokenKind)",
  ),
  (
    "_ZN4llvm22initializeEarlyCSEPassERNS_12PassRegistryE", "llvm::initializeEarlyCSEPass(llvm::PassRegistry&)",
    "llvm::initializeEarlyCSEPass", "llvm::initializeEarlyCSEPass(llvm::PassRegistry&)",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L12FP5_OverlapsE", "llvm::(anonymous namespace)::FP5_Overlaps",
    "llvm::(anonymous namespace)::FP5_Overlaps", "llvm::(anonymous namespace)::FP5_Overlaps",
  ),
  (
    "_ZNK4llvm3EVT17isExtendedIntegerEv", "llvm::EVT::isExtendedInteger() const",
    "llvm::EVT::isExtendedInteger", "llvm::EVT::isExtendedInteger() const",
  ),
  (
    "_ZN5clang4ento13GRBugReporter8getGraphEv", "clang::ento::GRBugReporter::getGraph()",
    "clang::ento::GRBugReporter::getGraph", "clang::ento::GRBugReporter::getGraph()",
  ),
  (
    "_ZN12_GLOBAL__N_113MCAsmStreamer6FinishEv", "(anonymous namespace)::MCAsmStreamer::Finish()",
    "(anonymous namespace)::MCAsmStreamer::Finish", "(anonymous namespace)::MCAsmStreamer::Finish()",
  ),
  (
    "_ZN4llvm12ConstantExpr3getEjPNS_8ConstantES2_j", "llvm::ConstantExpr::get(unsigned int, llvm::Constant*, llvm::Constant*, unsigned int)",
    "llvm::ConstantExpr::get", "llvm::ConstantExpr::get(unsigned int, llvm::Constant*, llvm::Constant*, unsigned int)",
  ),
  (
    "_ZN4llvm14BasicBlockPass14doFinalizationERNS_6ModuleE", "llvm::BasicBlockPass::doFinalization(llvm::Module&)",
    "llvm::BasicBlockPass::doFinalization", "llvm::BasicBlockPass::doFinalization(llvm::Module&)",
  ),
  (
    "_ZTVN4llvm18raw_string_ostreamE", "vtable for llvm::raw_string_ostream", "vtable for llvm::raw_string_ostream",
    "vtable for llvm::raw_string_ostream",
  ),
  (
    "_ZN4llvm13ConstantRangeC1ERKNS_5APIntE", "llvm::ConstantRange::ConstantRange(llvm::APInt const&)",
    "llvm::ConstantRange::ConstantRange", "llvm::ConstantRange::ConstantRange(llvm::APInt const&)",
  ),
  (
    "_ZNK5clang10ReturnStmt14getSourceRangeEv", "clang::ReturnStmt::getSourceRange() const",
    "clang::ReturnStmt::getSourceRange", "clang::ReturnStmt::getSourceRange() const",
  ),
  (
    "_ZN4llvm15SmallVectorImplINS_11SmallVectorIPNS_12MachineInstrELj8EEEE6resizeEj",
    "llvm::SmallVectorImpl<llvm::SmallVector<llvm::MachineInstr*, 8u>>::resize(unsigned int)",
    "llvm::SmallVectorImpl<llvm::SmallVector<llvm::MachineInstr*, 8u>>::resize",
    "llvm::SmallVectorImpl<llvm::SmallVector<llvm::MachineInstr*, 8u>>::resize(unsigned int)",
  ),
  (
    "_ZN4llvm11SCEVUnknown19allUsesReplacedWithEPNS_5ValueE", "llvm::SCEVUnknown::allUsesReplacedWith(llvm::Value*)",
    "llvm::SCEVUnknown::allUsesReplacedWith", "llvm::SCEVUnknown::allUsesReplacedWith(llvm::Value*)",
  ),
  (
    "_ZN11ImageLoader27fgImagesUsedFromSharedCacheE", "ImageLoader::fgImagesUsedFromSharedCache",
    "ImageLoader::fgImagesUsedFromSharedCache", "ImageLoader::fgImagesUsedFromSharedCache",
  ),
  (
    "_ZN4llvm8DenseMapIPKN5clang4ento12ExplodedNodeEcNS_12DenseMapInfoIS5_EENS6_IcEEE4growEj",
    "llvm::DenseMap<clang::ento::ExplodedNode const*, char, llvm::DenseMapInfo<clang::ento::ExplodedNode const*>, llvm::DenseMapInfo<char>>::grow(unsigned int)",
    "llvm::DenseMap<clang::ento::ExplodedNode const*, char, llvm::DenseMapInfo<clang::ento::ExplodedNode const*>, llvm::DenseMapInfo<char>>::grow",
    "llvm::DenseMap<clang::ento::ExplodedNode const*, char, llvm::DenseMapInfo<clang::ento::ExplodedNode const*>, llvm::DenseMapInfo<char>>::grow(unsigned int)",
  ),
  (
    "_ZTVN5clang6driver5tools7openbsd4LinkE", "vtable for clang::driver::tools::openbsd::Link",
    "vtable for clang::driver::tools::openbsd::Link", "vtable for clang::driver::tools::openbsd::Link",
  ),
  (
    "_ZN12_GLOBAL__N_115HTMLDiagnostics20HandlePathDiagnosticEPKN5clang4ento14PathDiagnosticE",
    "(anonymous namespace)::HTMLDiagnostics::HandlePathDiagnostic(clang::ento::PathDiagnostic const*)",
    "(anonymous namespace)::HTMLDiagnostics::HandlePathDiagnostic", "(anonymous namespace)::HTMLDiagnostics::HandlePathDiagnostic(clang::ento::PathDiagnostic const*)",
  ),
  (
    "_ZN4llvm9ArrayType18typeBecameConcreteEPKNS_11DerivedTypeE", "llvm::ArrayType::typeBecameConcrete(llvm::DerivedType const*)",
    "llvm::ArrayType::typeBecameConcrete", "llvm::ArrayType::typeBecameConcrete(llvm::DerivedType const*)",
  ),
  (
    "_ZTVN4llvm14format_object1IhEE", "vtable for llvm::format_object1<unsigned char>",
    "vtable for llvm::format_object1<unsigned char>", "vtable for llvm::format_object1<unsigned char>",
  ),
  (
    "_ZN4llvm16DAGTypeLegalizer25ExpandFloatRes_ConstantFPEPNS_6SDNodeERNS_7SDValueES4_",
    "llvm::DAGTypeLegalizer::ExpandFloatRes_ConstantFP(llvm::SDNode*, llvm::SDValue&, llvm::SDValue&)",
    "llvm::DAGTypeLegalizer::ExpandFloatRes_ConstantFP", "llvm::DAGTypeLegalizer::ExpandFloatRes_ConstantFP(llvm::SDNode*, llvm::SDValue&, llvm::SDValue&)",
  ),
  (
    "_ZN5clang21ObjCForCollectionStmtC1EPNS_4StmtEPNS_4ExprES2_NS_14SourceLocationES5_",
    "clang::ObjCForCollectionStmt::ObjCForCollectionStmt(clang::Stmt*, clang::Expr*, clang::Stmt*, clang::SourceLocation, clang::SourceLocation)",
    "clang::ObjCForCollectionStmt::ObjCForCollectionStmt", "clang::ObjCForCollectionStmt::ObjCForCollectionStmt(clang::Stmt*, clang::Expr*, clang::Stmt*, clang::SourceLocation, clang::SourceLocation)",
  ),
  (
    "_ZN4llvm10MCAsmLexerD2Ev", "llvm::MCAsmLexer::~MCAsmLexer()", "llvm::MCAsmLexer::~MCAsmLexer",
    "llvm::MCAsmLexer::~MCAsmLexer()",
  ),
  (
    "_ZN4llvm8FastISel15createResultRegEPKNS_19TargetRegisterClassE", "llvm::FastISel::createResultReg(llvm::TargetRegisterClass const*)",
    "llvm::FastISel::createResultReg", "llvm::FastISel::createResultReg(llvm::TargetRegisterClass const*)",
  ),
  ("_ZL12DiagArray118", "DiagArray118", "DiagArray118", "DiagArray118"),
  (
    "_ZN5clang7CodeGen11CGDebugInfo10CreateTypeEPKNS_10VectorTypeEN4llvm6DIFileE",
    "clang::CodeGen::CGDebugInfo::CreateType(clang::VectorType const*, llvm::DIFile)",
    "clang::CodeGen::CGDebugInfo::CreateType", "clang::CodeGen::CGDebugInfo::CreateType(clang::VectorType const*, llvm::DIFile)",
  ),
  (
    "_ZTVN4llvm18RegisterPassParserINS_17RegisterSchedulerEEE", "vtable for llvm::RegisterPassParser<llvm::RegisterScheduler>",
    "vtable for llvm::RegisterPassParser<llvm::RegisterScheduler>", "vtable for llvm::RegisterPassParser<llvm::RegisterScheduler>",
  ),
  (
    "_ZN4llvm8DenseMapIjbNS_12DenseMapInfoIjEENS1_IbEEE16InsertIntoBucketERKjRKbPSt4pairIjbE",
    "llvm::DenseMap<unsigned int, bool, llvm::DenseMapInfo<unsigned int>, llvm::DenseMapInfo<bool>>::InsertIntoBucket(unsigned int const&, bool const&, std::pair<unsigned int, bool>*)",
    "llvm::DenseMap<unsigned int, bool, llvm::DenseMapInfo<unsigned int>, llvm::DenseMapInfo<bool>>::InsertIntoBucket",
    "llvm::DenseMap<unsigned int, bool, llvm::DenseMapInfo<unsigned int>, llvm::DenseMapInfo<bool>>::InsertIntoBucket(unsigned int const&, bool const&, std::pair<unsigned int, bool>*)",
  ),
  (
    "_ZN12_GLOBAL__N_113BBPassManagerD0Ev", "(anonymous namespace)::BBPassManager::~BBPassManager()",
    "(anonymous namespace)::BBPassManager::~BBPassManager", "(anonymous namespace)::BBPassManager::~BBPassManager()",
  ),
  (
    "_ZN4llvm10FoldingSetINS_21FoldingSetNodeWrapperISt4pairIN5clang4ento4SValES5_EEEED1Ev",
    "llvm::FoldingSet<llvm::FoldingSetNodeWrapper<std::pair<clang::ento::SVal, clang::ento::SVal>>>::~FoldingSet()",
    "llvm::FoldingSet<llvm::FoldingSetNodeWrapper<std::pair<clang::ento::SVal, clang::ento::SVal>>>::~FoldingSet",
    "llvm::FoldingSet<llvm::FoldingSetNodeWrapper<std::pair<clang::ento::SVal, clang::ento::SVal>>>::~FoldingSet()",
  ),
  (
    "_ZN4llvm14ARMInstPrinter17printRegisterListEPKNS_6MCInstEjRNS_11raw_ostreamE",
    "llvm::ARMInstPrinter::printRegisterList(llvm::MCInst const*, unsigned int, llvm::raw_ostream&)",
    "llvm::ARMInstPrinter::printRegisterList", "llvm::ARMInstPrinter::printRegisterList(llvm::MCInst const*, unsigned int, llvm::raw_ostream&)",
  ),
  (
    "_ZN4llvm18ScheduleDAGSDNodes10RegDefIter7AdvanceEv", "llvm::ScheduleDAGSDNodes::RegDefIter::Advance()",
    "llvm::ScheduleDAGSDNodes::RegDefIter::Advance", "llvm::ScheduleDAGSDNodes::RegDefIter::Advance()",
  ),
  (
    "_ZN5clang4Sema14ReadMethodPoolENS_8SelectorE", "clang::Sema::ReadMethodPool(clang::Selector)",
    "clang::Sema::ReadMethodPool", "clang::Sema::ReadMethodPool(clang::Selector)",
  ),
  (
    "_ZN4llvm12PatternMatch15CastClass_matchINS1_INS0_7bind_tyINS_5ValueEEELj39EEELj30EE5matchIS3_EEbPT_",
    "bool llvm::PatternMatch::CastClass_match<llvm::PatternMatch::CastClass_match<llvm::PatternMatch::bind_ty<llvm::Value>, 39u>, 30u>::match<llvm::Value>(llvm::Value*)",
    "llvm::PatternMatch::CastClass_match<llvm::PatternMatch::CastClass_match<llvm::PatternMatch::bind_ty<llvm::Value>, 39u>, 30u>::match<llvm::Value>",
    "bool llvm::PatternMatch::CastClass_match<llvm::PatternMatch::CastClass_match<llvm::PatternMatch::bind_ty<llvm::Value>, 39u>, 30u>::match<llvm::Value>(llvm::Value*)",
  ),
  (
    "_ZNK5clang7VarDecl14getSourceRangeEv", "clang::VarDecl::getSourceRange() const",
    "clang::VarDecl::getSourceRange", "clang::VarDecl::getSourceRange() const",
  ),
  (
    "_ZN4llvm11AttrListPtrC1ERKS0_", "llvm::AttrListPtr::AttrListPtr(llvm::AttrListPtr const&)",
    "llvm::AttrListPtr::AttrListPtr", "llvm::AttrListPtr::AttrListPtr(llvm::AttrListPtr const&)",
  ),
  (
    "_ZNK5clang6driver9ToolChain14GetProgramPathEPKcb", "clang::driver::ToolChain::GetProgramPath(char const*, bool) const",
    "clang::driver::ToolChain::GetProgramPath", "clang::driver::ToolChain::GetProgramPath(char const*, bool) const",
  ),
  (
    "_ZN4llvm23initializeGlobalOptPassERNS_12PassRegistryE", "llvm::initializeGlobalOptPass(llvm::PassRegistry&)",
    "llvm::initializeGlobalOptPass", "llvm::initializeGlobalOptPass(llvm::PassRegistry&)",
  ),
  (
    "_ZN12_GLOBAL__N_121ObjCCommonTypesHelper15getCopyStructFnEv", "(anonymous namespace)::ObjCCommonTypesHelper::getCopyStructFn()",
    "(anonymous namespace)::ObjCCommonTypesHelper::getCopyStructFn", "(anonymous namespace)::ObjCCommonTypesHelper::getCopyStructFn()",
  ),
  ("_Z1fDAs", "f(short _Accum)", "f", "f(short _Accum)"),
  (
    "_ZN4llvm3sys9TimeValue3nowEv", "llvm::sys::TimeValue::now()", "llvm::sys::TimeValue::now",
    "llvm::sys::TimeValue::now()",
  ),
  (
    "_ZTVN5clang19TranslationUnitDeclE", "vtable for clang::TranslationUnitDecl",
    "vtable for clang::TranslationUnitDecl", "vtable for clang::TranslationUnitDecl",
  ),
  (
    "_Z16getCopyFromPartsRN4llvm12SelectionDAGENS_8DebugLocEPKNS_7SDValueEjNS_3EVTES6_NS_3ISD8NodeTypeE",
    "getCopyFromParts(llvm::SelectionDAG&, llvm::DebugLoc, llvm::SDValue const*, unsigned int, llvm::EVT, llvm::EVT, llvm::ISD::NodeType)",
    "getCopyFromParts", "getCopyFromParts(llvm::SelectionDAG&, llvm::DebugLoc, llvm::SDValue const*, unsigned int, llvm::EVT, llvm::EVT, llvm::ISD::NodeType)",
  ),
  ("_ZL10NumUnnamed", "NumUnnamed", "NumUnnamed", "NumUnnamed"),
  (
    "_ZN5clang16CompilerInstance14setDiagnosticsEPNS_10DiagnosticE", "clang::CompilerInstance::setDiagnostics(clang::Diagnostic*)",
    "clang::CompilerInstance::setDiagnostics", "clang::CompilerInstance::setDiagnostics(clang::Diagnostic*)",
  ),
  (
    "_ZNK5clang17ObjCInterfaceDecl27all_referenced_protocol_endEv", "clang::ObjCInterfaceDecl::all_referenced_protocol_end() const",
    "clang::ObjCInterfaceDecl::all_referenced_protocol_end", "clang::ObjCInterfaceDecl::all_referenced_protocol_end() const",
  ),
  (
    "_ZN4llvm17ScheduleDAGInstrs10StartBlockEPNS_17MachineBasicBlockE", "llvm::ScheduleDAGInstrs::StartBlock(llvm::MachineBasicBlock*)",
    "llvm::ScheduleDAGInstrs::StartBlock", "llvm::ScheduleDAGInstrs::StartBlock(llvm::MachineBasicBlock*)",
  ),
  (
    "_ZN4llvm13CompositeTypeD0Ev", "llvm::CompositeType::~CompositeType()", "llvm::CompositeType::~CompositeType",
    "llvm::CompositeType::~CompositeType()",
  ),
  (
    "_ZN5clang7CodeGen13CodeGenModule18getFunctionLinkageEPKNS_12FunctionDeclE",
    "clang::CodeGen::CodeGenModule::getFunctionLinkage(clang::FunctionDecl const*)",
    "clang::CodeGen::CodeGenModule::getFunctionLinkage", "clang::CodeGen::CodeGenModule::getFunctionLinkage(clang::FunctionDecl const*)",
  ),
  (
    "_ZNK4llvm11ScheduleDAG11getNodeDescEPKNS_6SDNodeE", "llvm::ScheduleDAG::getNodeDesc(llvm::SDNode const*) const",
    "llvm::ScheduleDAG::getNodeDesc", "llvm::ScheduleDAG::getNodeDesc(llvm::SDNode const*) const",
  ),
  (
    "_ZN4llvm12SelectionDAG14getMachineNodeEjNS_8DebugLocENS_3EVTES2_", "llvm::SelectionDAG::getMachineNode(unsigned int, llvm::DebugLoc, llvm::EVT, llvm::EVT)",
    "llvm::SelectionDAG::getMachineNode", "llvm::SelectionDAG::getMachineNode(unsigned int, llvm::DebugLoc, llvm::EVT, llvm::EVT)",
  ),
  (
    "_ZN4llvm2cl3optINS_8FloatABI7ABITypeELb1ENS0_6parserIS3_EEED1Ev", "llvm::cl::opt<llvm::FloatABI::ABIType, true, llvm::cl::parser<llvm::FloatABI::ABIType>>::~opt()",
    "llvm::cl::opt<llvm::FloatABI::ABIType, true, llvm::cl::parser<llvm::FloatABI::ABIType>>::~opt",
    "llvm::cl::opt<llvm::FloatABI::ABIType, true, llvm::cl::parser<llvm::FloatABI::ABIType>>::~opt()",
  ),
  (
    "_ZN5clang12ObjCIvarDeclD1Ev", "clang::ObjCIvarDecl::~ObjCIvarDecl()", "clang::ObjCIvarDecl::~ObjCIvarDecl",
    "clang::ObjCIvarDecl::~ObjCIvarDecl()",
  ),
  (
    "_ZN4llvm10OpaqueTypeD1Ev", "llvm::OpaqueType::~OpaqueType()", "llvm::OpaqueType::~OpaqueType",
    "llvm::OpaqueType::~OpaqueType()",
  ),
  (
    "_ZN5clang7CodeGen15CodeGenFunction21PushDestructorCleanupENS_8QualTypeEPN4llvm5ValueE",
    "clang::CodeGen::CodeGenFunction::PushDestructorCleanup(clang::QualType, llvm::Value*)",
    "clang::CodeGen::CodeGenFunction::PushDestructorCleanup", "clang::CodeGen::CodeGenFunction::PushDestructorCleanup(clang::QualType, llvm::Value*)",
  ),
  (
    "_ZNK4llvm16ARMBaseInstrInfo15getVSTMUseCycleEPKNS_18InstrItineraryDataERKNS_15TargetInstrDescEjjj",
    "llvm::ARMBaseInstrInfo::getVSTMUseCycle(llvm::InstrItineraryData const*, llvm::TargetInstrDesc const&, unsigned int, unsigned int, unsigned int) const",
    "llvm::ARMBaseInstrInfo::getVSTMUseCycle", "llvm::ARMBaseInstrInfo::getVSTMUseCycle(llvm::InstrItineraryData const*, llvm::TargetInstrDesc const&, unsigned int, unsigned int, unsigned int) const",
  ),
  (
    "_ZN4llvm18X86MCAsmInfoDarwinD1Ev", "llvm::X86MCAsmInfoDarwin::~X86MCAsmInfoDarwin()",
    "llvm::X86MCAsmInfoDarwin::~X86MCAsmInfoDarwin", "llvm::X86MCAsmInfoDarwin::~X86MCAsmInfoDarwin()",
  ),
  (
    "_ZN4llvm14BinaryOperator20setHasNoUnsignedWrapEb", "llvm::BinaryOperator::setHasNoUnsignedWrap(bool)",
    "llvm::BinaryOperator::setHasNoUnsignedWrap", "llvm::BinaryOperator::setHasNoUnsignedWrap(bool)",
  ),
  (
    "_ZN5clang9ASTReader23ReadNestedNameSpecifierERKN4llvm11SmallVectorIyLj64EEERj",
    "clang::ASTReader::ReadNestedNameSpecifier(llvm::SmallVector<unsigned long long, 64u> const&, unsigned int&)",
    "clang::ASTReader::ReadNestedNameSpecifier", "clang::ASTReader::ReadNestedNameSpecifier(llvm::SmallVector<unsigned long long, 64u> const&, unsigned int&)",
  ),
  (
    "_ZTVN12_GLOBAL__N_122UninitValsDiagReporterE", "vtable for (anonymous namespace)::UninitValsDiagReporter",
    "vtable for (anonymous namespace)::UninitValsDiagReporter", "vtable for (anonymous namespace)::UninitValsDiagReporter",
  ),
  (
    "_ZN4llvm8FastISel9FastEmit_ENS_3MVTES1_j", "llvm::FastISel::FastEmit_(llvm::MVT, llvm::MVT, unsigned int)",
    "llvm::FastISel::FastEmit_", "llvm::FastISel::FastEmit_(llvm::MVT, llvm::MVT, unsigned int)",
  ),
  (
    "_ZN5clang9ASTWriter16AddedVisibleDeclEPKNS_11DeclContextEPKNS_4DeclE", "clang::ASTWriter::AddedVisibleDecl(clang::DeclContext const*, clang::Decl const*)",
    "clang::ASTWriter::AddedVisibleDecl", "clang::ASTWriter::AddedVisibleDecl(clang::DeclContext const*, clang::Decl const*)",
  ),
  (
    "_ZTVN12_GLOBAL__N_119MachineVerifierPassE", "vtable for (anonymous namespace)::MachineVerifierPass",
    "vtable for (anonymous namespace)::MachineVerifierPass", "vtable for (anonymous namespace)::MachineVerifierPass",
  ),
  (
    "_ZN12_GLOBAL__N_111RewriteObjC21HandleTranslationUnitERN5clang10ASTContextE",
    "(anonymous namespace)::RewriteObjC::HandleTranslationUnit(clang::ASTContext&)",
    "(anonymous namespace)::RewriteObjC::HandleTranslationUnit", "(anonymous namespace)::RewriteObjC::HandleTranslationUnit(clang::ASTContext&)",
  ),
  (
    "_ZNK4llvm5Value11printCustomERNS_11raw_ostreamE", "llvm::Value::printCustom(llvm::raw_ostream&) const",
    "llvm::Value::printCustom", "llvm::Value::printCustom(llvm::raw_ostream&) const",
  ),
  (
    "_ZNK5clang4ento7GRState8printDOTERN4llvm11raw_ostreamERNS_3CFGE", "clang::ento::GRState::printDOT(llvm::raw_ostream&, clang::CFG&) const",
    "clang::ento::GRState::printDOT", "clang::ento::GRState::printDOT(llvm::raw_ostream&, clang::CFG&) const",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L15DH_SuperRegsSetE", "llvm::(anonymous namespace)::DH_SuperRegsSet",
    "llvm::(anonymous namespace)::DH_SuperRegsSet", "llvm::(anonymous namespace)::DH_SuperRegsSet",
  ),
  (
    "_ZN5clang7AsmStmt13getOutputExprEj", "clang::AsmStmt::getOutputExpr(unsigned int)",
    "clang::AsmStmt::getOutputExpr", "clang::AsmStmt::getOutputExpr(unsigned int)",
  ),
  (
    "_ZN5clang13ASTStmtWriter18VisitParenListExprEPNS_13ParenListExprE", "clang::ASTStmtWriter::VisitParenListExpr(clang::ParenListExpr*)",
    "clang::ASTStmtWriter::VisitParenListExpr", "clang::ASTStmtWriter::VisitParenListExpr(clang::ParenListExpr*)",
  ),
  ("_ZL13PrintDbgScope", "PrintDbgScope", "PrintDbgScope", "PrintDbgScope"),
  (
    "_ZN4llvm7APFloat8IEEEhalfE", "llvm::APFloat::IEEEhalf", "llvm::APFloat::IEEEhalf",
    "llvm::APFloat::IEEEhalf",
  ),
  (
    "_ZN4llvm5dwarf16ArrayOrderStringEj", "llvm::dwarf::ArrayOrderString(unsigned int)",
    "llvm::dwarf::ArrayOrderString", "llvm::dwarf::ArrayOrderString(unsigned int)",
  ),
  (
    "_ZN12_GLOBAL__N_110StmtDumper8DumpStmtEPKN5clang4StmtE", "(anonymous namespace)::StmtDumper::DumpStmt(clang::Stmt const*)",
    "(anonymous namespace)::StmtDumper::DumpStmt", "(anonymous namespace)::StmtDumper::DumpStmt(clang::Stmt const*)",
  ),
  (
    "_ZN4llvm8DenseMapIPKNS_6MDNodeEPNS_11CompileUnitENS_12DenseMapInfoIS3_EENS6_IS5_EEE4growEj",
    "llvm::DenseMap<llvm::MDNode const*, llvm::CompileUnit*, llvm::DenseMapInfo<llvm::MDNode const*>, llvm::DenseMapInfo<llvm::CompileUnit*>>::grow(unsigned int)",
    "llvm::DenseMap<llvm::MDNode const*, llvm::CompileUnit*, llvm::DenseMapInfo<llvm::MDNode const*>, llvm::DenseMapInfo<llvm::CompileUnit*>>::grow",
    "llvm::DenseMap<llvm::MDNode const*, llvm::CompileUnit*, llvm::DenseMapInfo<llvm::MDNode const*>, llvm::DenseMapInfo<llvm::CompileUnit*>>::grow(unsigned int)",
  ),
  (
    "_ZNK12_GLOBAL__N_117EmptySubobjectMap30CanPlaceFieldSubobjectAtOffsetEPKN5clang9FieldDeclENS1_9CharUnitsE",
    "(anonymous namespace)::EmptySubobjectMap::CanPlaceFieldSubobjectAtOffset(clang::FieldDecl const*, clang::CharUnits) const",
    "(anonymous namespace)::EmptySubobjectMap::CanPlaceFieldSubobjectAtOffset", "(anonymous namespace)::EmptySubobjectMap::CanPlaceFieldSubobjectAtOffset(clang::FieldDecl const*, clang::CharUnits) const",
  ),
  (
    "_ZTVN12_GLOBAL__N_113NoProfileInfoE", "vtable for (anonymous namespace)::NoProfileInfo",
    "vtable for (anonymous namespace)::NoProfileInfo", "vtable for (anonymous namespace)::NoProfileInfo",
  ),
  (
    "_ZN4llvm8DenseMapIjNS_8SmallSetIjLj32EEENS_12DenseMapInfoIjEENS3_IS2_EEE4growEj",
    "llvm::DenseMap<unsigned int, llvm::SmallSet<unsigned int, 32u>, llvm::DenseMapInfo<unsigned int>, llvm::DenseMapInfo<llvm::SmallSet<unsigned int, 32u>>>::grow(unsigned int)",
    "llvm::DenseMap<unsigned int, llvm::SmallSet<unsigned int, 32u>, llvm::DenseMapInfo<unsigned int>, llvm::DenseMapInfo<llvm::SmallSet<unsigned int, 32u>>>::grow",
    "llvm::DenseMap<unsigned int, llvm::SmallSet<unsigned int, 32u>, llvm::DenseMapInfo<unsigned int>, llvm::DenseMapInfo<llvm::SmallSet<unsigned int, 32u>>>::grow(unsigned int)",
  ),
  (
    "_ZN4llvm12LiveInterval4joinERS0_PKiS3_RNS_11SmallVectorIPNS_6VNInfoELj16EEEPNS_19MachineRegisterInfoE",
    "llvm::LiveInterval::join(llvm::LiveInterval&, int const*, int const*, llvm::SmallVector<llvm::VNInfo*, 16u>&, llvm::MachineRegisterInfo*)",
    "llvm::LiveInterval::join", "llvm::LiveInterval::join(llvm::LiveInterval&, int const*, int const*, llvm::SmallVector<llvm::VNInfo*, 16u>&, llvm::MachineRegisterInfo*)",
  ),
  (
    "_Z18SuggestParenthesesRN5clang4SemaENS_14SourceLocationERKNS_17PartialDiagnosticES5_NS_11SourceRangeES5_S6_",
    "SuggestParentheses(clang::Sema&, clang::SourceLocation, clang::PartialDiagnostic const&, clang::PartialDiagnostic const&, clang::SourceRange, clang::PartialDiagnostic const&, clang::SourceRange)",
    "SuggestParentheses", "SuggestParentheses(clang::Sema&, clang::SourceLocation, clang::PartialDiagnostic const&, clang::PartialDiagnostic const&, clang::SourceRange, clang::PartialDiagnostic const&, clang::SourceRange)",
  ),
  (
    "_ZN5clang6Parser29ParseTemplateTemplateArgumentEv", "clang::Parser::ParseTemplateTemplateArgument()",
    "clang::Parser::ParseTemplateTemplateArgument", "clang::Parser::ParseTemplateTemplateArgument()",
  ),
  (
    "_ZN4llvm18InlineCostAnalyzer19resetCachedCostInfoEPNS_8FunctionE", "llvm::InlineCostAnalyzer::resetCachedCostInfo(llvm::Function*)",
    "llvm::InlineCostAnalyzer::resetCachedCostInfo", "llvm::InlineCostAnalyzer::resetCachedCostInfo(llvm::Function*)",
  ),
  (
    "_ZN12_GLOBAL__N_17TypeSet18refineAbstractTypeEPKN4llvm11DerivedTypeEPKNS1_4TypeE",
    "(anonymous namespace)::TypeSet::refineAbstractType(llvm::DerivedType const*, llvm::Type const*)",
    "(anonymous namespace)::TypeSet::refineAbstractType", "(anonymous namespace)::TypeSet::refineAbstractType(llvm::DerivedType const*, llvm::Type const*)",
  ),
  (
    "_ZN12_GLOBAL__N_114MCNullStreamer24EmitDwarfAdvanceLineAddrExPKN4llvm8MCSymbolES4_",
    "(anonymous namespace)::MCNullStreamer::EmitDwarfAdvanceLineAddr(long long, llvm::MCSymbol const*, llvm::MCSymbol const*)",
    "(anonymous namespace)::MCNullStreamer::EmitDwarfAdvanceLineAddr", "(anonymous namespace)::MCNullStreamer::EmitDwarfAdvanceLineAddr(long long, llvm::MCSymbol const*, llvm::MCSymbol const*)",
  ),
  (
    "_ZN5clang20PragmaOptionsHandlerD0Ev", "clang::PragmaOptionsHandler::~PragmaOptionsHandler()",
    "clang::PragmaOptionsHandler::~PragmaOptionsHandler", "clang::PragmaOptionsHandler::~PragmaOptionsHandler()",
  ),
  (
    "_ZN5clang17ClassTemplateDecl25findPartialSpecializationENS_8QualTypeE", "clang::ClassTemplateDecl::findPartialSpecialization(clang::QualType)",
    "clang::ClassTemplateDecl::findPartialSpecialization", "clang::ClassTemplateDecl::findPartialSpecialization(clang::QualType)",
  ),
  (
    "_ZNK4llvm4Pass5printERNS_11raw_ostreamEPKNS_6ModuleE", "llvm::Pass::print(llvm::raw_ostream&, llvm::Module const*) const",
    "llvm::Pass::print", "llvm::Pass::print(llvm::raw_ostream&, llvm::Module const*) const",
  ),
  (
    "_ZNK4llvm17MachineBasicBlock5printERNS_11raw_ostreamEPNS_11SlotIndexesE", "llvm::MachineBasicBlock::print(llvm::raw_ostream&, llvm::SlotIndexes*) const",
    "llvm::MachineBasicBlock::print", "llvm::MachineBasicBlock::print(llvm::raw_ostream&, llvm::SlotIndexes*) const",
  ),
  (
    "_ZN5clang4ento19PathDiagnosticPieceD2Ev", "clang::ento::PathDiagnosticPiece::~PathDiagnosticPiece()",
    "clang::ento::PathDiagnosticPiece::~PathDiagnosticPiece", "clang::ento::PathDiagnosticPiece::~PathDiagnosticPiece()",
  ),
  (
    "_ZNK4llvm17ARMTargetLowering27EmitInstrWithCustomInserterEPNS_12MachineInstrEPNS_17MachineBasicBlockE",
    "llvm::ARMTargetLowering::EmitInstrWithCustomInserter(llvm::MachineInstr*, llvm::MachineBasicBlock*) const",
    "llvm::ARMTargetLowering::EmitInstrWithCustomInserter", "llvm::ARMTargetLowering::EmitInstrWithCustomInserter(llvm::MachineInstr*, llvm::MachineBasicBlock*) const",
  ),
  (
    "_ZN4llvm10TimerGroup11removeTimerERNS_5TimerE", "llvm::TimerGroup::removeTimer(llvm::Timer&)",
    "llvm::TimerGroup::removeTimer", "llvm::TimerGroup::removeTimer(llvm::Timer&)",
  ),
  (
    "_ZN5clang11ASTImporterD0Ev", "clang::ASTImporter::~ASTImporter()", "clang::ASTImporter::~ASTImporter",
    "clang::ASTImporter::~ASTImporter()",
  ),
  (
    "_ZN12_GLOBAL__N_115ASTNodeImporter9VisitStmtEPN5clang4StmtE", "(anonymous namespace)::ASTNodeImporter::VisitStmt(clang::Stmt*)",
    "(anonymous namespace)::ASTNodeImporter::VisitStmt", "(anonymous namespace)::ASTNodeImporter::VisitStmt(clang::Stmt*)",
  ),
  (
    "_ZNK4llvm17MachineMemOperand7ProfileERNS_16FoldingSetNodeIDE", "llvm::MachineMemOperand::Profile(llvm::FoldingSetNodeID&) const",
    "llvm::MachineMemOperand::Profile", "llvm::MachineMemOperand::Profile(llvm::FoldingSetNodeID&) const",
  ),
  (
    "_ZNK5clang16ObjCProtocolDecl12lookupMethodENS_8SelectorEb", "clang::ObjCProtocolDecl::lookupMethod(clang::Selector, bool) const",
    "clang::ObjCProtocolDecl::lookupMethod", "clang::ObjCProtocolDecl::lookupMethod(clang::Selector, bool) const",
  ),
  (
    "_ZL16ColorWithRegsOpt", "ColorWithRegsOpt", "ColorWithRegsOpt", "ColorWithRegsOpt",
  ),
  (
    "_ZSt22__final_insertion_sortIPN4llvm9StringRefEEvT_S3_", "void std::__final_insertion_sort<llvm::StringRef*>(llvm::StringRef*, llvm::StringRef*)",
    "std::__final_insertion_sort<llvm::StringRef*>", "void std::__final_insertion_sort<llvm::StringRef*>(llvm::StringRef*, llvm::StringRef*)",
  ),
  ("_ZL8NumCSEed", "NumCSEed", "NumCSEed", "NumCSEed"),
  (
    "_ZN12_GLOBAL__N_115NEONMoveFixPass2IDE", "(anonymous namespace)::NEONMoveFixPass::ID",
    "(anonymous namespace)::NEONMoveFixPass::ID", "(anonymous namespace)::NEONMoveFixPass::ID",
  ),
  (
    "_ZN4llvm17IntrinsicLowering13AddPrototypesERNS_6ModuleE", "llvm::IntrinsicLowering::AddPrototypes(llvm::Module&)",
    "llvm::IntrinsicLowering::AddPrototypes", "llvm::IntrinsicLowering::AddPrototypes(llvm::Module&)",
  ),
  (
    "_ZNK4llvm5APInt6isIntNEj", "llvm::APInt::isIntN(unsigned int) const", "llvm::APInt::isIntN",
    "llvm::APInt::isIntN(unsigned int) const",
  ),
  (
    "_ZN5clang13ASTStmtWriter22VisitObjCStringLiteralEPNS_17ObjCStringLiteralE",
    "clang::ASTStmtWriter::VisitObjCStringLiteral(clang::ObjCStringLiteral*)", "clang::ASTStmtWriter::VisitObjCStringLiteral",
    "clang::ASTStmtWriter::VisitObjCStringLiteral(clang::ObjCStringLiteral*)",
  ),
  (
    "_ZN5clang11DeclContext6lookupENS_15DeclarationNameE", "clang::DeclContext::lookup(clang::DeclarationName)",
    "clang::DeclContext::lookup", "clang::DeclContext::lookup(clang::DeclarationName)",
  ),
  (
    "_ZN5clang13ASTStmtWriter27VisitObjCAtSynchronizedStmtEPNS_22ObjCAtSynchronizedStmtE",
    "clang::ASTStmtWriter::VisitObjCAtSynchronizedStmt(clang::ObjCAtSynchronizedStmt*)",
    "clang::ASTStmtWriter::VisitObjCAtSynchronizedStmt", "clang::ASTStmtWriter::VisitObjCAtSynchronizedStmt(clang::ObjCAtSynchronizedStmt*)",
  ),
  (
    "_ZN12_GLOBAL__N_115AliasSetPrinter2IDE", "(anonymous namespace)::AliasSetPrinter::ID",
    "(anonymous namespace)::AliasSetPrinter::ID", "(anonymous namespace)::AliasSetPrinter::ID",
  ),
  (
    "_ZN5clang17PragmaWeakHandlerD0Ev", "clang::PragmaWeakHandler::~PragmaWeakHandler()",
    "clang::PragmaWeakHandler::~PragmaWeakHandler", "clang::PragmaWeakHandler::~PragmaWeakHandler()",
  ),
  (
    "_ZN4llvm15ScalarEvolutionD1Ev", "llvm::ScalarEvolution::~ScalarEvolution()",
    "llvm::ScalarEvolution::~ScalarEvolution", "llvm::ScalarEvolution::~ScalarEvolution()",
  ),
  (
    "_ZN5clang4Sema10SubstExprsEPPNS_4ExprEjbRKNS_30MultiLevelTemplateArgumentListERN4llvm15SmallVectorImplIS2_EE",
    "clang::Sema::SubstExprs(clang::Expr**, unsigned int, bool, clang::MultiLevelTemplateArgumentList const&, llvm::SmallVectorImpl<clang::Expr*>&)",
    "clang::Sema::SubstExprs", "clang::Sema::SubstExprs(clang::Expr**, unsigned int, bool, clang::MultiLevelTemplateArgumentList const&, llvm::SmallVectorImpl<clang::Expr*>&)",
  ),
  (
    "_ZN4llvm14ImutAVLFactoryINS_16ImutKeyValueInfoIPKN5clang4ento10SymbolDataEjEEEC2Ev",
    "llvm::ImutAVLFactory<llvm::ImutKeyValueInfo<clang::ento::SymbolData const*, unsigned int>>::ImutAVLFactory()",
    "llvm::ImutAVLFactory<llvm::ImutKeyValueInfo<clang::ento::SymbolData const*, unsigned int>>::ImutAVLFactory",
    "llvm::ImutAVLFactory<llvm::ImutKeyValueInfo<clang::ento::SymbolData const*, unsigned int>>::ImutAVLFactory()",
  ),
  (
    "_ZN12_GLOBAL__N_114CXXNameMangler15mangleLocalNameEPKN5clang9NamedDeclE", "(anonymous namespace)::CXXNameMangler::mangleLocalName(clang::NamedDecl const*)",
    "(anonymous namespace)::CXXNameMangler::mangleLocalName", "(anonymous namespace)::CXXNameMangler::mangleLocalName(clang::NamedDecl const*)",
  ),
  (
    "_ZN4llvm22createARMMCCodeEmitterERKNS_6TargetERNS_13TargetMachineERNS_9MCContextE",
    "llvm::createARMMCCodeEmitter(llvm::Target const&, llvm::TargetMachine&, llvm::MCContext&)",
    "llvm::createARMMCCodeEmitter", "llvm::createARMMCCodeEmitter(llvm::Target const&, llvm::TargetMachine&, llvm::MCContext&)",
  ),
  (
    "_ZNK12_GLOBAL__N_119ELFX86_64AsmBackend18createObjectWriterERN4llvm11raw_ostreamE",
    "(anonymous namespace)::ELFX86_64AsmBackend::createObjectWriter(llvm::raw_ostream&) const",
    "(anonymous namespace)::ELFX86_64AsmBackend::createObjectWriter", "(anonymous namespace)::ELFX86_64AsmBackend::createObjectWriter(llvm::raw_ostream&) const",
  ),
  (
    "_ZN4llvm10BasicBlock10moveBeforeEPS0_", "llvm::BasicBlock::moveBefore(llvm::BasicBlock*)",
    "llvm::BasicBlock::moveBefore", "llvm::BasicBlock::moveBefore(llvm::BasicBlock*)",
  ),
  (
    "_ZNK4llvm2cl17basic_parser_impl14getOptionWidthERKNS0_6OptionE", "llvm::cl::basic_parser_impl::getOptionWidth(llvm::cl::Option const&) const",
    "llvm::cl::basic_parser_impl::getOptionWidth", "llvm::cl::basic_parser_impl::getOptionWidth(llvm::cl::Option const&) const",
  ),
  (
    "_ZN4llvm17DominatorTreeBaseINS_10BasicBlockEE26findNearestCommonDominatorEPKS1_S4_",
    "llvm::DominatorTreeBase<llvm::BasicBlock>::findNearestCommonDominator(llvm::BasicBlock const*, llvm::BasicBlock const*)",
    "llvm::DominatorTreeBase<llvm::BasicBlock>::findNearestCommonDominator", "llvm::DominatorTreeBase<llvm::BasicBlock>::findNearestCommonDominator(llvm::BasicBlock const*, llvm::BasicBlock const*)",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L11R6_OverlapsE", "llvm::(anonymous namespace)::R6_Overlaps",
    "llvm::(anonymous namespace)::R6_Overlaps", "llvm::(anonymous namespace)::R6_Overlaps",
  ),
  (
    "_ZN5clang7ASTUnitD4Ev", "clang::ASTUnit::~ASTUnit()", "clang::ASTUnit::~ASTUnit",
    "clang::ASTUnit::~ASTUnit()",
  ),
  (
    "_ZN4llvm8DenseMapIPNS_4TypeEjNS_12DenseMapInfoIS2_EENS3_IjEEE4growEj", "llvm::DenseMap<llvm::Type*, unsigned int, llvm::DenseMapInfo<llvm::Type*>, llvm::DenseMapInfo<unsigned int>>::grow(unsigned int)",
    "llvm::DenseMap<llvm::Type*, unsigned int, llvm::DenseMapInfo<llvm::Type*>, llvm::DenseMapInfo<unsigned int>>::grow",
    "llvm::DenseMap<llvm::Type*, unsigned int, llvm::DenseMapInfo<llvm::Type*>, llvm::DenseMapInfo<unsigned int>>::grow(unsigned int)",
  ),
  (
    "_ZN4llvm19Thumb1FrameLoweringD1Ev", "llvm::Thumb1FrameLowering::~Thumb1FrameLowering()",
    "llvm::Thumb1FrameLowering::~Thumb1FrameLowering", "llvm::Thumb1FrameLowering::~Thumb1FrameLowering()",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_1L17R15D_SuperRegsSetE", "llvm::(anonymous namespace)::R15D_SuperRegsSet",
    "llvm::(anonymous namespace)::R15D_SuperRegsSet", "llvm::(anonymous namespace)::R15D_SuperRegsSet",
  ),
  (
    "_ZN4llvm3X8612GR32_TCClassD1Ev", "llvm::X86::GR32_TCClass::~GR32_TCClass()",
    "llvm::X86::GR32_TCClass::~GR32_TCClass", "llvm::X86::GR32_TCClass::~GR32_TCClass()",
  ),
  (
    "_ZN12_GLOBAL__N_110StmtDumper8DumpTypeEN5clang8QualTypeE", "(anonymous namespace)::StmtDumper::DumpType(clang::QualType)",
    "(anonymous namespace)::StmtDumper::DumpType", "(anonymous namespace)::StmtDumper::DumpType(clang::QualType)",
  ),
  (
    "_ZN12_GLOBAL__N_117EmptySubobjectMap26UpdateEmptyFieldSubobjectsEPKN5clang9FieldDeclENS1_9CharUnitsE",
    "(anonymous namespace)::EmptySubobjectMap::UpdateEmptyFieldSubobjects(clang::FieldDecl const*, clang::CharUnits)",
    "(anonymous namespace)::EmptySubobjectMap::UpdateEmptyFieldSubobjects", "(anonymous namespace)::EmptySubobjectMap::UpdateEmptyFieldSubobjects(clang::FieldDecl const*, clang::CharUnits)",
  ),
  (
    "_ZN5clang10ASTContext32getSubstTemplateTypeParmPackTypeEPKNS_20TemplateTypeParmTypeERKNS_16TemplateArgumentE",
    "clang::ASTContext::getSubstTemplateTypeParmPackType(clang::TemplateTypeParmType const*, clang::TemplateArgument const&)",
    "clang::ASTContext::getSubstTemplateTypeParmPackType", "clang::ASTContext::getSubstTemplateTypeParmPackType(clang::TemplateTypeParmType const*, clang::TemplateArgument const&)",
  ),
  (
    "_ZN4llvm17PredIteratorCache8GetPredsEPNS_10BasicBlockE", "llvm::PredIteratorCache::GetPreds(llvm::BasicBlock*)",
    "llvm::PredIteratorCache::GetPreds", "llvm::PredIteratorCache::GetPreds(llvm::BasicBlock*)",
  ),
  (
    "_ZNK5clang10ASTContext18getASTRecordLayoutEPKNS_10RecordDeclE", "clang::ASTContext::getASTRecordLayout(clang::RecordDecl const*) const",
    "clang::ASTContext::getASTRecordLayout", "clang::ASTContext::getASTRecordLayout(clang::RecordDecl const*) const",
  ),
  (
    "_ZN5clang4ento25StackArgumentsSpaceRegionD0Ev", "clang::ento::StackArgumentsSpaceRegion::~StackArgumentsSpaceRegion()",
    "clang::ento::StackArgumentsSpaceRegion::~StackArgumentsSpaceRegion", "clang::ento::StackArgumentsSpaceRegion::~StackArgumentsSpaceRegion()",
  ),
  (
    "_ZN5clang9ASTWriter17AddTypeSourceInfoEPNS_14TypeSourceInfoERN4llvm15SmallVectorImplIyEE",
    "clang::ASTWriter::AddTypeSourceInfo(clang::TypeSourceInfo*, llvm::SmallVectorImpl<unsigned long long>&)",
    "clang::ASTWriter::AddTypeSourceInfo", "clang::ASTWriter::AddTypeSourceInfo(clang::TypeSourceInfo*, llvm::SmallVectorImpl<unsigned long long>&)",
  ),
  (
    "_ZN5clang4ento23SimpleConstraintManagerD2Ev", "clang::ento::SimpleConstraintManager::~SimpleConstraintManager()",
    "clang::ento::SimpleConstraintManager::~SimpleConstraintManager", "clang::ento::SimpleConstraintManager::~SimpleConstraintManager()",
  ),
  (
    "_ZN5clang10CXXTryStmtC2ENS_14SourceLocationEPNS_4StmtEPS3_j", "clang::CXXTryStmt::CXXTryStmt(clang::SourceLocation, clang::Stmt*, clang::Stmt**, unsigned int)",
    "clang::CXXTryStmt::CXXTryStmt", "clang::CXXTryStmt::CXXTryStmt(clang::SourceLocation, clang::Stmt*, clang::Stmt**, unsigned int)",
  ),
  (
    "_ZNK5clang10ASTContext18getPointerDiffTypeEv", "clang::ASTContext::getPointerDiffType() const",
    "clang::ASTContext::getPointerDiffType", "clang::ASTContext::getPointerDiffType() const",
  ),
  (
    "_ZN12_GLOBAL__N_114CStringChecker9evalBcopyERN5clang4ento14CheckerContextEPKNS1_8CallExprE",
    "(anonymous namespace)::CStringChecker::evalBcopy(clang::ento::CheckerContext&, clang::CallExpr const*)",
    "(anonymous namespace)::CStringChecker::evalBcopy", "(anonymous namespace)::CStringChecker::evalBcopy(clang::ento::CheckerContext&, clang::CallExpr const*)",
  ),
  (
    "_ZZ15RetCC_X86CommonjN4llvm3MVTES0_NS_11CCValAssign7LocInfoENS_3ISD10ArgFlagsTyERNS_7CCStateEE8RegList1",
    "RetCC_X86Common(unsigned int, llvm::MVT, llvm::MVT, llvm::CCValAssign::LocInfo, llvm::ISD::ArgFlagsTy, llvm::CCState&)::RegList1",
    "RetCC_X86Common(unsigned int, llvm::MVT, llvm::MVT, llvm::CCValAssign::LocInfo, llvm::ISD::ArgFlagsTy, llvm::CCState&)::RegList1",
    "RetCC_X86Common(unsigned int, llvm::MVT, llvm::MVT, llvm::CCValAssign::LocInfo, llvm::ISD::ArgFlagsTy, llvm::CCState&)::RegList1",
  ),
  (
    "_ZNK5clang6Parser24isKnownToBeTypeSpecifierERKNS_5TokenE", "clang::Parser::isKnownToBeTypeSpecifier(clang::Token const&) const",
    "clang::Parser::isKnownToBeTypeSpecifier", "clang::Parser::isKnownToBeTypeSpecifier(clang::Token const&) const",
  ),
  (
    "_ZNK11ImageLoader12getShortNameEv", "ImageLoader::getShortName() const", "ImageLoader::getShortName",
    "ImageLoader::getShortName() const",
  ),
  (
    "_ZNK12_GLOBAL__N_115ARMExpandPseudo11getPassNameEv", "(anonymous namespace)::ARMExpandPseudo::getPassName() const",
    "(anonymous namespace)::ARMExpandPseudo::getPassName", "(anonymous namespace)::ARMExpandPseudo::getPassName() const",
  ),
  (
    "_ZN4llvm13MPPassManager15getOnTheFlyPassEPNS_4PassEPKvRNS_8FunctionE", "llvm::MPPassManager::getOnTheFlyPass(llvm::Pass*, void const*, llvm::Function&)",
    "llvm::MPPassManager::getOnTheFlyPass", "llvm::MPPassManager::getOnTheFlyPass(llvm::Pass*, void const*, llvm::Function&)",
  ),
  (
    "_ZN4llvm10AsmPrinter28EmitMachineConstantPoolValueEPNS_24MachineConstantPoolValueE",
    "llvm::AsmPrinter::EmitMachineConstantPoolValue(llvm::MachineConstantPoolValue*)",
    "llvm::AsmPrinter::EmitMachineConstantPoolValue", "llvm::AsmPrinter::EmitMachineConstantPoolValue(llvm::MachineConstantPoolValue*)",
  ),
  (
    "_ZZN4llvm17initializePEIPassERNS_12PassRegistryEE11initialized", "llvm::initializePEIPass(llvm::PassRegistry&)::initialized",
    "llvm::initializePEIPass(llvm::PassRegistry&)::initialized", "llvm::initializePEIPass(llvm::PassRegistry&)::initialized",
  ),
  (
    "_ZN5clang4Sema19CheckVectorOperandsENS_14SourceLocationERPNS_4ExprES4_", "clang::Sema::CheckVectorOperands(clang::SourceLocation, clang::Expr*&, clang::Expr*&)",
    "clang::Sema::CheckVectorOperands", "clang::Sema::CheckVectorOperands(clang::SourceLocation, clang::Expr*&, clang::Expr*&)",
  ),
  (
    "_ZN4llvm16DAGTypeLegalizer20ScalarizeVecRes_LOADEPNS_10LoadSDNodeE", "llvm::DAGTypeLegalizer::ScalarizeVecRes_LOAD(llvm::LoadSDNode*)",
    "llvm::DAGTypeLegalizer::ScalarizeVecRes_LOAD", "llvm::DAGTypeLegalizer::ScalarizeVecRes_LOAD(llvm::LoadSDNode*)",
  ),
  (
    "_ZNK4llvm17ARMTargetLowering16EmitAtomicBinaryEPNS_12MachineInstrEPNS_17MachineBasicBlockEjj",
    "llvm::ARMTargetLowering::EmitAtomicBinary(llvm::MachineInstr*, llvm::MachineBasicBlock*, unsigned int, unsigned int) const",
    "llvm::ARMTargetLowering::EmitAtomicBinary", "llvm::ARMTargetLowering::EmitAtomicBinary(llvm::MachineInstr*, llvm::MachineBasicBlock*, unsigned int, unsigned int) const",
  ),
  (
    "_ZTVN4llvm2cl6parserISsEE", "vtable for llvm::cl::parser<std::string>", "vtable for llvm::cl::parser<std::string>",
    "vtable for llvm::cl::parser<std::string>",
  ),
  (
    "_ZNK12_GLOBAL__N_113X86_64ABIInfo17getIndirectResultEN5clang8QualTypeE", "(anonymous namespace)::X86_64ABIInfo::getIndirectResult(clang::QualType) const",
    "(anonymous namespace)::X86_64ABIInfo::getIndirectResult", "(anonymous namespace)::X86_64ABIInfo::getIndirectResult(clang::QualType) const",
  ),
  (
    "_ZN5clang6Parser9SkipUntilEPKNS_3tok9TokenKindEjbbb", "clang::Parser::SkipUntil(clang::tok::TokenKind const*, unsigned int, bool, bool, bool)",
    "clang::Parser::SkipUntil", "clang::Parser::SkipUntil(clang::tok::TokenKind const*, unsigned int, bool, bool, bool)",
  ),
  (
    "_ZN5clang13ASTStmtWriter13VisitNullStmtEPNS_8NullStmtE", "clang::ASTStmtWriter::VisitNullStmt(clang::NullStmt*)",
    "clang::ASTStmtWriter::VisitNullStmt", "clang::ASTStmtWriter::VisitNullStmt(clang::NullStmt*)",
  ),
  (
    "_ZN4llvm16FoldingSetNodeID10AddIntegerEj", "llvm::FoldingSetNodeID::AddInteger(unsigned int)",
    "llvm::FoldingSetNodeID::AddInteger", "llvm::FoldingSetNodeID::AddInteger(unsigned int)",
  ),
  (
    "_ZN12_GLOBAL__N_116IntExprEvaluator13VisitCastExprEPN5clang8CastExprE", "(anonymous namespace)::IntExprEvaluator::VisitCastExpr(clang::CastExpr*)",
    "(anonymous namespace)::IntExprEvaluator::VisitCastExpr", "(anonymous namespace)::IntExprEvaluator::VisitCastExpr(clang::CastExpr*)",
  ),
  (
    "_ZTVN4llvm10FoldingSetINS_4SCEVEEE", "vtable for llvm::FoldingSet<llvm::SCEV>",
    "vtable for llvm::FoldingSet<llvm::SCEV>", "vtable for llvm::FoldingSet<llvm::SCEV>",
  ),
  (
    "_ZTVN12_GLOBAL__N_124DeserializedDeclsCheckerE", "vtable for (anonymous namespace)::DeserializedDeclsChecker",
    "vtable for (anonymous namespace)::DeserializedDeclsChecker", "vtable for (anonymous namespace)::DeserializedDeclsChecker",
  ),
  (
    "_ZN12_GLOBAL__N_111ARMFastISel15FastEmitInst_rfEjPKN4llvm19TargetRegisterClassEjbPKNS1_10ConstantFPE",
    "(anonymous namespace)::ARMFastISel::FastEmitInst_rf(unsigned int, llvm::TargetRegisterClass const*, unsigned int, bool, llvm::ConstantFP const*)",
    "(anonymous namespace)::ARMFastISel::FastEmitInst_rf", "(anonymous namespace)::ARMFastISel::FastEmitInst_rf(unsigned int, llvm::TargetRegisterClass const*, unsigned int, bool, llvm::ConstantFP const*)",
  ),
  (
    "_ZN4llvm10DwarfDebug16beginInstructionEPKNS_12MachineInstrE", "llvm::DwarfDebug::beginInstruction(llvm::MachineInstr const*)",
    "llvm::DwarfDebug::beginInstruction", "llvm::DwarfDebug::beginInstruction(llvm::MachineInstr const*)",
  ),
  (
    "_ZN12_GLOBAL__N_118UndefBranchChecker13FindUndefExpr8FindExprEPKN5clang4ExprE",
    "(anonymous namespace)::UndefBranchChecker::FindUndefExpr::FindExpr(clang::Expr const*)",
    "(anonymous namespace)::UndefBranchChecker::FindUndefExpr::FindExpr", "(anonymous namespace)::UndefBranchChecker::FindUndefExpr::FindExpr(clang::Expr const*)",
  ),
  (
    "_ZNK4llvm8Function14getIntrinsicIDEv", "llvm::Function::getIntrinsicID() const",
    "llvm::Function::getIntrinsicID", "llvm::Function::getIntrinsicID() const",
  ),
  (
    "_Z28CommaSeparateAndAddOccurencePN4llvm2cl6OptionEjNS_9StringRefES3_b", "CommaSeparateAndAddOccurence(llvm::cl::Option*, unsigned int, llvm::StringRef, llvm::StringRef, bool)",
    "CommaSeparateAndAddOccurence", "CommaSeparateAndAddOccurence(llvm::cl::Option*, unsigned int, llvm::StringRef, llvm::StringRef, bool)",
  ),
  (
    "_ZNK4llvm13ConstantRange8multiplyERKS0_", "llvm::ConstantRange::multiply(llvm::ConstantRange const&) const",
    "llvm::ConstantRange::multiply", "llvm::ConstantRange::multiply(llvm::ConstantRange const&) const",
  ),
  (
    "_ZN4llvm9FPExtInstC2EPNS_5ValueEPKNS_4TypeERKNS_5TwineEPNS_10BasicBlockE", "llvm::FPExtInst::FPExtInst(llvm::Value*, llvm::Type const*, llvm::Twine const&, llvm::BasicBlock*)",
    "llvm::FPExtInst::FPExtInst", "llvm::FPExtInst::FPExtInst(llvm::Value*, llvm::Type const*, llvm::Twine const&, llvm::BasicBlock*)",
  ),
  (
    "_ZNK4llvm11MCAsmLayout17getFragmentOffsetEPKNS_10MCFragmentE", "llvm::MCAsmLayout::getFragmentOffset(llvm::MCFragment const*) const",
    "llvm::MCAsmLayout::getFragmentOffset", "llvm::MCAsmLayout::getFragmentOffset(llvm::MCFragment const*) const",
  ),
  (
    "_ZN12_GLOBAL__N_120SelectionDAGLegalize35ExpandExtractFromVectorThroughStackEN4llvm7SDValueE",
    "(anonymous namespace)::SelectionDAGLegalize::ExpandExtractFromVectorThroughStack(llvm::SDValue)",
    "(anonymous namespace)::SelectionDAGLegalize::ExpandExtractFromVectorThroughStack",
    "(anonymous namespace)::SelectionDAGLegalize::ExpandExtractFromVectorThroughStack(llvm::SDValue)",
  ),
  (
    "_ZN4llvm2cl6parserI20ShrinkWrapDebugLevelE5parseERNS0_6OptionENS_9StringRefES6_RS2_",
    "llvm::cl::parser<ShrinkWrapDebugLevel>::parse(llvm::cl::Option&, llvm::StringRef, llvm::StringRef, ShrinkWrapDebugLevel&)",
    "llvm::cl::parser<ShrinkWrapDebugLevel>::parse", "llvm::cl::parser<ShrinkWrapDebugLevel>::parse(llvm::cl::Option&, llvm::StringRef, llvm::StringRef, ShrinkWrapDebugLevel&)",
  ),
  (
    "_ZN4llvm13X86AsmPrinter12printOperandEPKNS_12MachineInstrEjRNS_11raw_ostreamEPKc",
    "llvm::X86AsmPrinter::printOperand(llvm::MachineInstr const*, unsigned int, llvm::raw_ostream&, char const*)",
    "llvm::X86AsmPrinter::printOperand", "llvm::X86AsmPrinter::printOperand(llvm::MachineInstr const*, unsigned int, llvm::raw_ostream&, char const*)",
  ),
  (
    "_ZN5clang13ASTStmtWriter20VisitObjCAtThrowStmtEPNS_15ObjCAtThrowStmtE", "clang::ASTStmtWriter::VisitObjCAtThrowStmt(clang::ObjCAtThrowStmt*)",
    "clang::ASTStmtWriter::VisitObjCAtThrowStmt", "clang::ASTStmtWriter::VisitObjCAtThrowStmt(clang::ObjCAtThrowStmt*)",
  ),
  (
    "_ZN4llvmL13OperandInfo35E", "llvm::OperandInfo35", "llvm::OperandInfo35", "llvm::OperandInfo35",
  ),
]
