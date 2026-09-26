// Generated from the output of llvm-cxxfilt (LLVM 22.1.7): each
// entry is (mangled name, `llvm-cxxfilt -n`, `llvm-cxxfilt -n -p`).
// Symbols of the Homebrew LLVM, Clang, LLDB and MLIR libraries and
// of other Homebrew C++ libraries (Mach-O underscore removed).

///|
let symbols : Array[(String, String, String)] = [
  (
    "_ZN7Iex_3_411EalreadyExcC2EONSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE",
    "Iex_3_4::EalreadyExc::EalreadyExc(std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>&&)",
    "Iex_3_4::EalreadyExc::EalreadyExc",
  ),
  (
    "_ZN4llvm5SPIRV17ConvergenceRegionC1ERNS_13DominatorTreeERNS_8LoopInfoERNS_8FunctionE",
    "llvm::SPIRV::ConvergenceRegion::ConvergenceRegion(llvm::DominatorTree&, llvm::LoopInfo&, llvm::Function&)",
    "llvm::SPIRV::ConvergenceRegion::ConvergenceRegion",
  ),
  (
    "_ZN4llvm18LoongArchSubtargetC2ERKNS_6TripleENS_9StringRefES4_S4_S4_RKNS_13TargetMachineE",
    "llvm::LoongArchSubtarget::LoongArchSubtarget(llvm::Triple const&, llvm::StringRef, llvm::StringRef, llvm::StringRef, llvm::StringRef, llvm::TargetMachine const&)",
    "llvm::LoongArchSubtarget::LoongArchSubtarget",
  ),
  (
    "_ZN4mlir5ROCDL6detail26CvtPkRtzGenericAdaptorBaseC1ENS0_8CvtPkRtzE", "mlir::ROCDL::detail::CvtPkRtzGenericAdaptorBase::CvtPkRtzGenericAdaptorBase(mlir::ROCDL::CvtPkRtz)",
    "mlir::ROCDL::detail::CvtPkRtzGenericAdaptorBase::CvtPkRtzGenericAdaptorBase",
  ),
  (
    "_ZN4mlir4irdl11IRDLDialectC2EPNS_11MLIRContextE", "mlir::irdl::IRDLDialect::IRDLDialect(mlir::MLIRContext*)",
    "mlir::irdl::IRDLDialect::IRDLDialect",
  ),
  (
    "_ZN4LIEF2PE5ReproC2ERKS1_", "LIEF::PE::Repro::Repro(LIEF::PE::Repro const&)",
    "LIEF::PE::Repro::Repro",
  ),
  (
    "_ZN4mlir7complex12AbsOpAdaptorC1ENS0_5AbsOpE", "mlir::complex::AbsOpAdaptor::AbsOpAdaptor(mlir::complex::AbsOp)",
    "mlir::complex::AbsOpAdaptor::AbsOpAdaptor",
  ),
  (
    "_ZN4llvm3cas19OnDiskDataAllocatorC1ENSt3__110unique_ptrINS1_8ImplTypeENS2_14default_deleteIS4_EEEE",
    "llvm::cas::OnDiskDataAllocator::OnDiskDataAllocator(std::__1::unique_ptr<llvm::cas::OnDiskDataAllocator::ImplType, std::__1::default_delete<llvm::cas::OnDiskDataAllocator::ImplType>>)",
    "llvm::cas::OnDiskDataAllocator::OnDiskDataAllocator",
  ),
  (
    "_ZN12_GLOBAL__N_120MappableExprsHandlerC1ERKN5clang22OMPExecutableDirectiveERNS1_7CodeGen15CodeGenFunctionE",
    "(anonymous namespace)::MappableExprsHandler::MappableExprsHandler(clang::OMPExecutableDirective const&, clang::CodeGen::CodeGenFunction&)",
    "(anonymous namespace)::MappableExprsHandler::MappableExprsHandler",
  ),
  (
    "_ZN4lldb22SBMemoryRegionInfoListC1ERKS0_", "lldb::SBMemoryRegionInfoList::SBMemoryRegionInfoList(lldb::SBMemoryRegionInfoList const&)",
    "lldb::SBMemoryRegionInfoList::SBMemoryRegionInfoList",
  ),
  (
    "_ZN4mlir10pdl_interp23CheckAttributeOpAdaptorC2ENS0_16CheckAttributeOpE", "mlir::pdl_interp::CheckAttributeOpAdaptor::CheckAttributeOpAdaptor(mlir::pdl_interp::CheckAttributeOp)",
    "mlir::pdl_interp::CheckAttributeOpAdaptor::CheckAttributeOpAdaptor",
  ),
  (
    "_ZN4node10AsyncHooksC1EPN2v87IsolateEPKNS0_13SerializeInfoE", "node::AsyncHooks::AsyncHooks(v8::Isolate*, node::AsyncHooks::SerializeInfo const*)",
    "node::AsyncHooks::AsyncHooks",
  ),
  (
    "_ZN3fmt3v1212format_errorCI1St13runtime_errorEPKc", "fmt::v12::format_error::format_error(char const*)",
    "fmt::v12::format_error::format_error",
  ),
  (
    "_ZN7decimal7RoundedCI1St13runtime_errorERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE",
    "decimal::Rounded::Rounded(std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>> const&)",
    "decimal::Rounded::Rounded",
  ),
  (
    "_ZN7decimal7InexactCI1St13runtime_errorERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE",
    "decimal::Inexact::Inexact(std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>> const&)",
    "decimal::Inexact::Inexact",
  ),
  (
    "_ZN7decimal8OverflowCI1St13runtime_errorERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE",
    "decimal::Overflow::Overflow(std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>> const&)",
    "decimal::Overflow::Overflow",
  ),
  (
    "_ZN7decimal7ClampedCI1St13runtime_errorERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE",
    "decimal::Clamped::Clamped(std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>> const&)",
    "decimal::Clamped::Clamped",
  ),
  (
    "_ZN7decimal9UnderflowCI1St13runtime_errorERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE",
    "decimal::Underflow::Underflow(std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>> const&)",
    "decimal::Underflow::Underflow",
  ),
  (
    "_ZN7decimal10ValueErrorCI1St13runtime_errorEPKc", "decimal::ValueError::ValueError(char const*)",
    "decimal::ValueError::ValueError",
  ),
  (
    "_ZN3fmt3v1112format_errorCI1St13runtime_errorEPKc", "fmt::v11::format_error::format_error(char const*)",
    "fmt::v11::format_error::format_error",
  ),
  (
    "_ZN7decimal9SubnormalCI1St13runtime_errorERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE",
    "decimal::Subnormal::Subnormal(std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>> const&)",
    "decimal::Subnormal::Subnormal",
  ),
  (
    "_ZN7decimal11MallocErrorCI1St13runtime_errorEPKc", "decimal::MallocError::MallocError(char const*)",
    "decimal::MallocError::MallocError",
  ),
  (
    "_ZN2lp10lar_solver3imp19column_update_trailD1Ev", "lp::lar_solver::imp::column_update_trail::~column_update_trail()",
    "lp::lar_solver::imp::column_update_trail::~column_update_trail",
  ),
  (
    "_ZN6spdlog7details11f_formatterINS0_18null_scoped_padderEED0Ev", "spdlog::details::f_formatter<spdlog::details::null_scoped_padder>::~f_formatter()",
    "spdlog::details::f_formatter<spdlog::details::null_scoped_padder>::~f_formatter",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_10pdl_interp13SwitchTypesOpEED1Ev",
    "mlir::RegisteredOperationName::Model<mlir::pdl_interp::SwitchTypesOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::pdl_interp::SwitchTypesOp>::~Model",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5ROCDL26ClusterLoadAsyncToLDSB32OpEED0Ev",
    "mlir::RegisteredOperationName::Model<mlir::ROCDL::ClusterLoadAsyncToLDSB32Op>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::ROCDL::ClusterLoadAsyncToLDSB32Op>::~Model",
  ),
  (
    "_ZN12_GLOBAL__N_113UnrollPatternIN4mlir5xegpu10PrefetchOpEED0Ev", "(anonymous namespace)::UnrollPattern<mlir::xegpu::PrefetchOp>::~UnrollPattern()",
    "(anonymous namespace)::UnrollPattern<mlir::xegpu::PrefetchOp>::~UnrollPattern",
  ),
  (
    "_ZNSt3__120__shared_ptr_emplaceIN12lldb_private18InlineFunctionInfoENS_9allocatorIS2_EEED0Ev",
    "std::__1::__shared_ptr_emplace<lldb_private::InlineFunctionInfo, std::__1::allocator<lldb_private::InlineFunctionInfo>>::~__shared_ptr_emplace()",
    "std::__1::__shared_ptr_emplace<lldb_private::InlineFunctionInfo, std::__1::allocator<lldb_private::InlineFunctionInfo>>::~__shared_ptr_emplace",
  ),
  (
    "_ZN27CommandObjectMemoryTagWrite19OptionGroupTagWriteD0Ev", "CommandObjectMemoryTagWrite::OptionGroupTagWrite::~OptionGroupTagWrite()",
    "CommandObjectMemoryTagWrite::OptionGroupTagWrite::~OptionGroupTagWrite",
  ),
  (
    "_ZN4llvm12CodeViewYAML6detail16SymbolRecordImplINS_8codeview14RegRelativeSymEED0Ev",
    "llvm::CodeViewYAML::detail::SymbolRecordImpl<llvm::codeview::RegRelativeSym>::~SymbolRecordImpl()",
    "llvm::CodeViewYAML::detail::SymbolRecordImpl<llvm::codeview::RegRelativeSym>::~SymbolRecordImpl",
  ),
  (
    "_ZN17ABIWindows_x86_64D1Ev", "ABIWindows_x86_64::~ABIWindows_x86_64()", "ABIWindows_x86_64::~ABIWindows_x86_64",
  ),
  (
    "_ZN4node11RAIIIsolateD1Ev", "node::RAIIIsolate::~RAIIIsolate()", "node::RAIIIsolate::~RAIIIsolate",
  ),
  (
    "_ZN4node6worker12SiblingGroupD2Ev", "node::worker::SiblingGroup::~SiblingGroup()",
    "node::worker::SiblingGroup::~SiblingGroup",
  ),
  (
    "_ZN4mlir5spirv6detail29QueryExtensionInterfaceTraits5ModelINS0_32ImageSampleProjDrefImplicitLodOpEED0Ev",
    "mlir::spirv::detail::QueryExtensionInterfaceTraits::Model<mlir::spirv::ImageSampleProjDrefImplicitLodOp>::~Model()",
    "mlir::spirv::detail::QueryExtensionInterfaceTraits::Model<mlir::spirv::ImageSampleProjDrefImplicitLodOp>::~Model",
  ),
  (
    "_ZTVN2v88internal8compiler29SimplifiedOperatorGlobalCache19NumberClz32OperatorE",
    "vtable for v8::internal::compiler::SimplifiedOperatorGlobalCache::NumberClz32Operator",
    "vtable for v8::internal::compiler::SimplifiedOperatorGlobalCache::NumberClz32Operator",
  ),
  (
    "_ZTVN4llvm6detail9PassModelINS_8FunctionENS_19NaryReassociatePassENS_15AnalysisManagerIS2_JEEEJEEE",
    "vtable for llvm::detail::PassModel<llvm::Function, llvm::NaryReassociatePass, llvm::AnalysisManager<llvm::Function>>",
    "vtable for llvm::detail::PassModel<llvm::Function, llvm::NaryReassociatePass, llvm::AnalysisManager<llvm::Function>>",
  ),
  (
    "_ZTVNSt3__110__function6__funcIZL22validExtractValueIndexvE3$_0FbN4llvm8ArrayRefIPNS3_5ValueEEEPKS5_EEE",
    "vtable for std::__1::__function::__func<validExtractValueIndex()::$_0, bool (llvm::ArrayRef<llvm::Value*>, llvm::Value const*)>",
    "vtable for std::__1::__function::__func<validExtractValueIndex()::$_0, bool (llvm::ArrayRef<llvm::Value*>, llvm::Value const*)>",
  ),
  (
    "_ZTVN12_GLOBAL__N_130ParsedAttrInfoTransparentUnionE", "vtable for (anonymous namespace)::ParsedAttrInfoTransparentUnion",
    "vtable for (anonymous namespace)::ParsedAttrInfoTransparentUnion",
  ),
  (
    "_ZTVN4mlir4tosa6detail29QueryExtensionInterfaceTraits5ModelINS0_13ConcatShapeOpEEE",
    "vtable for mlir::tosa::detail::QueryExtensionInterfaceTraits::Model<mlir::tosa::ConcatShapeOp>",
    "vtable for mlir::tosa::detail::QueryExtensionInterfaceTraits::Model<mlir::tosa::ConcatShapeOp>",
  ),
  (
    "_ZTVN4mlir3khr12_GLOBAL__N_125WmmaLoadOpToSPIRVLoweringE", "vtable for mlir::khr::(anonymous namespace)::WmmaLoadOpToSPIRVLowering",
    "vtable for mlir::khr::(anonymous namespace)::WmmaLoadOpToSPIRVLowering",
  ),
  (
    "_ZTVN5clang7targets15LinuxTargetInfoINS0_15PPC64TargetInfoEEE", "vtable for clang::targets::LinuxTargetInfo<clang::targets::PPC64TargetInfo>",
    "vtable for clang::targets::LinuxTargetInfo<clang::targets::PPC64TargetInfo>",
  ),
  (
    "_ZTVN4mlir5spirv6detail30QueryMaxVersionInterfaceTraits5ModelINS0_11GroupUMinOpEEE",
    "vtable for mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::GroupUMinOp>",
    "vtable for mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::GroupUMinOp>",
  ),
  (
    "_ZTVN4llvm3orc21SimpleRemoteEPCServer10DispatcherE", "vtable for llvm::orc::SimpleRemoteEPCServer::Dispatcher",
    "vtable for llvm::orc::SimpleRemoteEPCServer::Dispatcher",
  ),
  (
    "_ZTVN2v817TracingControllerE", "vtable for v8::TracingController", "vtable for v8::TracingController",
  ),
  (
    "_ZTVN7Imf_3_419TiledRgbaOutputFileE", "vtable for Imf_3_4::TiledRgbaOutputFile",
    "vtable for Imf_3_4::TiledRgbaOutputFile",
  ),
  (
    "_ZTVN4mlir23RegisteredOperationName5ModelINS_3smt8AssertOpEEE", "vtable for mlir::RegisteredOperationName::Model<mlir::smt::AssertOp>",
    "vtable for mlir::RegisteredOperationName::Model<mlir::smt::AssertOp>",
  ),
  (
    "_ZTIN7datalog17tr_infrastructureINS_12table_traitsEE14transformer_fnE", "typeinfo for datalog::tr_infrastructure<datalog::table_traits>::transformer_fn",
    "typeinfo for datalog::tr_infrastructure<datalog::table_traits>::transformer_fn",
  ),
  (
    "_ZTIN5clang12ast_matchers7dynamic8internal25MapAnyOfBuilderDescriptorE", "typeinfo for clang::ast_matchers::dynamic::internal::MapAnyOfBuilderDescriptor",
    "typeinfo for clang::ast_matchers::dynamic::internal::MapAnyOfBuilderDescriptor",
  ),
  (
    "_ZTINSt3__110shared_ptrIN7Imf_3_49InputFileEEE", "typeinfo for std::__1::shared_ptr<Imf_3_4::InputFile>",
    "typeinfo for std::__1::shared_ptr<Imf_3_4::InputFile>",
  ),
  (
    "_ZTINSt3__110__function6__baseIFbRK7svectorIjjES5_EEE", "typeinfo for std::__1::__function::__base<bool (svector<unsigned int, unsigned int> const&, svector<unsigned int, unsigned int> const&)>",
    "typeinfo for std::__1::__function::__base<bool (svector<unsigned int, unsigned int> const&, svector<unsigned int, unsigned int> const&)>",
  ),
  (
    "_ZTIN5clang7targets17OpenBSDTargetInfoINS0_15PPC32TargetInfoEEE", "typeinfo for clang::targets::OpenBSDTargetInfo<clang::targets::PPC32TargetInfo>",
    "typeinfo for clang::targets::OpenBSDTargetInfo<clang::targets::PPC32TargetInfo>",
  ),
  (
    "_ZTIN5clang12ast_matchers8internal19TypeTraverseMatcherINS_9ParenTypeEEE", "typeinfo for clang::ast_matchers::internal::TypeTraverseMatcher<clang::ParenType>",
    "typeinfo for clang::ast_matchers::internal::TypeTraverseMatcher<clang::ParenType>",
  ),
  (
    "_ZTIN12_GLOBAL__N_123F8E8M0TruncFOpConverterE", "typeinfo for (anonymous namespace)::F8E8M0TruncFOpConverter",
    "typeinfo for (anonymous namespace)::F8E8M0TruncFOpConverter",
  ),
  (
    "_ZTIN4llvm3orc20CompileOnDemandLayerE", "typeinfo for llvm::orc::CompileOnDemandLayer",
    "typeinfo for llvm::orc::CompileOnDemandLayer",
  ),
  (
    "_ZTIN4llvm17AAPotentialValuesE", "typeinfo for llvm::AAPotentialValues", "typeinfo for llvm::AAPotentialValues",
  ),
  (
    "_ZTIN12_GLOBAL__N_123ParsedAttrInfoNoBuiltinE", "typeinfo for (anonymous namespace)::ParsedAttrInfoNoBuiltin",
    "typeinfo for (anonymous namespace)::ParsedAttrInfoNoBuiltin",
  ),
  (
    "_ZTIN4mlir23RegisteredOperationName5ModelINS_7arm_sme22aarch64_sme_ld1w_horizEEE",
    "typeinfo for mlir::RegisteredOperationName::Model<mlir::arm_sme::aarch64_sme_ld1w_horiz>",
    "typeinfo for mlir::RegisteredOperationName::Model<mlir::arm_sme::aarch64_sme_ld1w_horiz>",
  ),
  (
    "_ZTIN5clang29GenerateModuleInterfaceActionE", "typeinfo for clang::GenerateModuleInterfaceAction",
    "typeinfo for clang::GenerateModuleInterfaceAction",
  ),
  (
    "_ZTSN4mlir6vector4impl23LowerVectorMaskPassBaseIN12_GLOBAL__N_119LowerVectorMaskPassEEE",
    "typeinfo name for mlir::vector::impl::LowerVectorMaskPassBase<(anonymous namespace)::LowerVectorMaskPass>",
    "typeinfo name for mlir::vector::impl::LowerVectorMaskPassBase<(anonymous namespace)::LowerVectorMaskPass>",
  ),
  (
    "_ZTSN4llvm13format_objectIJmPKcyEEE", "typeinfo name for llvm::format_object<unsigned long, char const*, unsigned long long>",
    "typeinfo name for llvm::format_object<unsigned long, char const*, unsigned long long>",
  ),
  (
    "_ZTSN12_GLOBAL__N_131VersionedCovMapFuncRecordReaderILN4llvm8coverage13CovMapVersionE1EjLNS1_10endiannessE1EEE",
    "typeinfo name for (anonymous namespace)::VersionedCovMapFuncRecordReader<(llvm::coverage::CovMapVersion)1, unsigned int, (llvm::endianness)1>",
    "typeinfo name for (anonymous namespace)::VersionedCovMapFuncRecordReader<(llvm::coverage::CovMapVersion)1, unsigned int, (llvm::endianness)1>",
  ),
  (
    "_ZTSZN12lldb_private8Platform19GetCachedExecutableERNS_10ModuleSpecERNSt3__110shared_ptrINS_6ModuleEEEE3$_0",
    "typeinfo name for lldb_private::Platform::GetCachedExecutable(lldb_private::ModuleSpec&, std::__1::shared_ptr<lldb_private::Module>&)::$_0",
    "typeinfo name for lldb_private::Platform::GetCachedExecutable(lldb_private::ModuleSpec&, std::__1::shared_ptr<lldb_private::Module>&)::$_0",
  ),
  (
    "_ZTSN4mlir23RegisteredOperationName5ModelINS_5ROCDL25wmma_f32_16x16x16_fp8_fp8EEE",
    "typeinfo name for mlir::RegisteredOperationName::Model<mlir::ROCDL::wmma_f32_16x16x16_fp8_fp8>",
    "typeinfo name for mlir::RegisteredOperationName::Model<mlir::ROCDL::wmma_f32_16x16x16_fp8_fp8>",
  ),
  (
    "_ZTSN4mlir23RegisteredOperationName5ModelINS_5ROCDL21CvtPkScalePk8F16Fp4OpEEE",
    "typeinfo name for mlir::RegisteredOperationName::Model<mlir::ROCDL::CvtPkScalePk8F16Fp4Op>",
    "typeinfo name for mlir::RegisteredOperationName::Model<mlir::ROCDL::CvtPkScalePk8F16Fp4Op>",
  ),
  (
    "_ZTSN7Imf_3_413DwaCompressorE", "typeinfo name for Imf_3_4::DwaCompressor",
    "typeinfo name for Imf_3_4::DwaCompressor",
  ),
  (
    "_ZTSN4mlir6detail31OpOrInterfaceRewritePatternBaseINS_3acc13DeclareLinkOpEEE",
    "typeinfo name for mlir::detail::OpOrInterfaceRewritePatternBase<mlir::acc::DeclareLinkOp>",
    "typeinfo name for mlir::detail::OpOrInterfaceRewritePatternBase<mlir::acc::DeclareLinkOp>",
  ),
  (
    "_ZTSNSt3__110__function6__baseIFN12lldb_private6StatusERKNS2_10ModuleSpecEEEE",
    "typeinfo name for std::__1::__function::__base<lldb_private::Status (lldb_private::ModuleSpec const&)>",
    "typeinfo name for std::__1::__function::__base<lldb_private::Status (lldb_private::ModuleSpec const&)>",
  ),
  (
    "_ZTSN4mlir13bufferization8func_ext17FuncAnalysisStateE", "typeinfo name for mlir::bufferization::func_ext::FuncAnalysisState",
    "typeinfo name for mlir::bufferization::func_ext::FuncAnalysisState",
  ),
  (
    "_ZTSPFvRN4mlir13OpPassManagerEE", "typeinfo name for void (*)(mlir::OpPassManager&)",
    "typeinfo name for void (*)(mlir::OpPassManager&)",
  ),
  (
    "_ZTSN4mlir19OpConversionPatternINS_6vector15TransferWriteOpEEE", "typeinfo name for mlir::OpConversionPattern<mlir::vector::TransferWriteOp>",
    "typeinfo name for mlir::OpConversionPattern<mlir::vector::TransferWriteOp>",
  ),
  (
    "_ZTTNSt3__119basic_ostringstreamIcNS_11char_traitsIcEENS_9allocatorIcEEEE",
    "VTT for std::__1::basic_ostringstream<char, std::__1::char_traits<char>, std::__1::allocator<char>>",
    "VTT for std::__1::basic_ostringstream<char, std::__1::char_traits<char>, std::__1::allocator<char>>",
  ),
  (
    "_ZTTN2v88internal8compiler12TurboCfgFileE", "VTT for v8::internal::compiler::TurboCfgFile",
    "VTT for v8::internal::compiler::TurboCfgFile",
  ),
  (
    "_ZTTNSt3__119basic_istringstreamIcNS_11char_traitsIcEENS_9allocatorIcEEEE",
    "VTT for std::__1::basic_istringstream<char, std::__1::char_traits<char>, std::__1::allocator<char>>",
    "VTT for std::__1::basic_istringstream<char, std::__1::char_traits<char>, std::__1::allocator<char>>",
  ),
  (
    "_ZTTN2v88internal8compiler13TurboJsonFileE", "VTT for v8::internal::compiler::TurboJsonFile",
    "VTT for v8::internal::compiler::TurboJsonFile",
  ),
  (
    "_ZTTNSt3__118basic_stringstreamIcNS_11char_traitsIcEENS_9allocatorIcEEEE", "VTT for std::__1::basic_stringstream<char, std::__1::char_traits<char>, std::__1::allocator<char>>",
    "VTT for std::__1::basic_stringstream<char, std::__1::char_traits<char>, std::__1::allocator<char>>",
  ),
  (
    "_ZTTNSt3__114basic_ofstreamIcNS_11char_traitsIcEEEE", "VTT for std::__1::basic_ofstream<char, std::__1::char_traits<char>>",
    "VTT for std::__1::basic_ofstream<char, std::__1::char_traits<char>>",
  ),
  (
    "_ZTTN2v84base18CheckMessageStreamE", "VTT for v8::base::CheckMessageStream",
    "VTT for v8::base::CheckMessageStream",
  ),
  (
    "_ZTTN2v88internal8OFStreamE", "VTT for v8::internal::OFStream", "VTT for v8::internal::OFStream",
  ),
  (
    "_ZTTN2v88internal15DbgStdoutStreamE", "VTT for v8::internal::DbgStdoutStream",
    "VTT for v8::internal::DbgStdoutStream",
  ),
  (
    "_ZTTNSt3__113basic_fstreamIcNS_11char_traitsIcEEEE", "VTT for std::__1::basic_fstream<char, std::__1::char_traits<char>>",
    "VTT for std::__1::basic_fstream<char, std::__1::char_traits<char>>",
  ),
  (
    "_ZTTNSt3__118basic_stringstreamIwNS_11char_traitsIwEENS_9allocatorIwEEEE", "VTT for std::__1::basic_stringstream<wchar_t, std::__1::char_traits<wchar_t>, std::__1::allocator<wchar_t>>",
    "VTT for std::__1::basic_stringstream<wchar_t, std::__1::char_traits<wchar_t>, std::__1::allocator<wchar_t>>",
  ),
  (
    "_ZTTN2v88internal12StderrStreamE", "VTT for v8::internal::StderrStream", "VTT for v8::internal::StderrStream",
  ),
  (
    "_ZTCN2v88internal8compiler13TurboJsonFileE0_NSt3__113basic_ostreamIcNS2_11char_traitsIcEEEE",
    "construction vtable for std::__1::basic_ostream<char, v8::internal::compiler::TurboJsonFile::char_traits<char>>-in-v8::internal::compiler::TurboJsonFile",
    "construction vtable for std::__1::basic_ostream<char, v8::internal::compiler::TurboJsonFile::char_traits<char>>-in-v8::internal::compiler::TurboJsonFile",
  ),
  (
    "_ZTCN12_GLOBAL__N_114DynMemFrontendIJNS_10FreeAllocaENS_17MismatchedDeallocEEEE96_S2_",
    "construction vtable for (anonymous namespace)::MismatchedDealloc-in-(anonymous namespace)::DynMemFrontend<(anonymous namespace)::FreeAlloca, (anonymous namespace)::MismatchedDealloc>",
    "construction vtable for (anonymous namespace)::MismatchedDealloc-in-(anonymous namespace)::DynMemFrontend<(anonymous namespace)::FreeAlloca, (anonymous namespace)::MismatchedDealloc>",
  ),
  (
    "_ZTCN2v88internal8compiler12TurboCfgFileE0_NSt3__113basic_ostreamIcNS2_11char_traitsIcEEEE",
    "construction vtable for std::__1::basic_ostream<char, v8::internal::compiler::TurboCfgFile::char_traits<char>>-in-v8::internal::compiler::TurboCfgFile",
    "construction vtable for std::__1::basic_ostream<char, v8::internal::compiler::TurboCfgFile::char_traits<char>>-in-v8::internal::compiler::TurboCfgFile",
  ),
  (
    "_ZTCN2v88internal15DbgStdoutStreamE0_NSt3__113basic_ostreamIcNS1_11char_traitsIcEEEE",
    "construction vtable for std::__1::basic_ostream<char, v8::internal::DbgStdoutStream::char_traits<char>>-in-v8::internal::DbgStdoutStream",
    "construction vtable for std::__1::basic_ostream<char, v8::internal::DbgStdoutStream::char_traits<char>>-in-v8::internal::DbgStdoutStream",
  ),
  (
    "_ZTCN2v84base18CheckMessageStreamE0_NSt3__113basic_ostreamIcNS1_11char_traitsIcEEEE",
    "construction vtable for std::__1::basic_ostream<char, v8::base::CheckMessageStream::char_traits<char>>-in-v8::base::CheckMessageStream",
    "construction vtable for std::__1::basic_ostream<char, v8::base::CheckMessageStream::char_traits<char>>-in-v8::base::CheckMessageStream",
  ),
  (
    "_ZTCNSt3__118basic_stringstreamIwNS_11char_traitsIwEENS_9allocatorIwEEEE16_NS_13basic_ostreamIwS2_EE",
    "construction vtable for std::__1::basic_ostream<wchar_t, std::__1::char_traits<wchar_t>>-in-std::__1::basic_stringstream<wchar_t, std::__1::char_traits<wchar_t>, std::__1::allocator<wchar_t>>",
    "construction vtable for std::__1::basic_ostream<wchar_t, std::__1::char_traits<wchar_t>>-in-std::__1::basic_stringstream<wchar_t, std::__1::char_traits<wchar_t>, std::__1::allocator<wchar_t>>",
  ),
  (
    "_ZTCN2v84base18CheckMessageStreamE0_NSt3__119basic_ostringstreamIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE",
    "construction vtable for std::__1::basic_ostringstream<char, v8::base::CheckMessageStream::char_traits<char>, v8::base::CheckMessageStream::allocator<char>>-in-v8::base::CheckMessageStream",
    "construction vtable for std::__1::basic_ostringstream<char, v8::base::CheckMessageStream::char_traits<char>, v8::base::CheckMessageStream::allocator<char>>-in-v8::base::CheckMessageStream",
  ),
  (
    "_ZTCNSt3__113basic_fstreamIcNS_11char_traitsIcEEEE0_NS_14basic_iostreamIcS2_EE",
    "construction vtable for std::__1::basic_iostream<char, std::__1::char_traits<char>>-in-std::__1::basic_fstream<char, std::__1::char_traits<char>>",
    "construction vtable for std::__1::basic_iostream<char, std::__1::char_traits<char>>-in-std::__1::basic_fstream<char, std::__1::char_traits<char>>",
  ),
  (
    "_ZTCN2v88internal8OFStreamE0_NSt3__113basic_ostreamIcNS1_11char_traitsIcEEEE",
    "construction vtable for std::__1::basic_ostream<char, v8::internal::OFStream::char_traits<char>>-in-v8::internal::OFStream",
    "construction vtable for std::__1::basic_ostream<char, v8::internal::OFStream::char_traits<char>>-in-v8::internal::OFStream",
  ),
  (
    "_ZTCNSt3__118basic_stringstreamIwNS_11char_traitsIwEENS_9allocatorIwEEEE0_NS_13basic_istreamIwS2_EE",
    "construction vtable for std::__1::basic_istream<wchar_t, std::__1::char_traits<wchar_t>>-in-std::__1::basic_stringstream<wchar_t, std::__1::char_traits<wchar_t>, std::__1::allocator<wchar_t>>",
    "construction vtable for std::__1::basic_istream<wchar_t, std::__1::char_traits<wchar_t>>-in-std::__1::basic_stringstream<wchar_t, std::__1::char_traits<wchar_t>, std::__1::allocator<wchar_t>>",
  ),
  (
    "_ZTCN2v88internal12StdoutStreamE0_NSt3__113basic_ostreamIcNS1_11char_traitsIcEEEE",
    "construction vtable for std::__1::basic_ostream<char, v8::internal::StdoutStream::char_traits<char>>-in-v8::internal::StdoutStream",
    "construction vtable for std::__1::basic_ostream<char, v8::internal::StdoutStream::char_traits<char>>-in-v8::internal::StdoutStream",
  ),
  (
    "_ZTCN2v88internal12StderrStreamE0_NS0_8OFStreamE", "construction vtable for v8::internal::OFStream-in-v8::internal::StderrStream",
    "construction vtable for v8::internal::OFStream-in-v8::internal::StderrStream",
  ),
  (
    "_ZThn80_N4node12_GLOBAL__N_117CompressionStreamINS0_21ZstdDecompressContextEED1Ev",
    "non-virtual thunk to node::(anonymous namespace)::CompressionStream<node::(anonymous namespace)::ZstdDecompressContext>::~CompressionStream()",
    "non-virtual thunk to node::(anonymous namespace)::CompressionStream<node::(anonymous namespace)::ZstdDecompressContext>::~CompressionStream()",
  ),
  (
    "_ZThn56_N3smt12theory_arithINS_7inf_extEED1Ev", "non-virtual thunk to smt::theory_arith<smt::inf_ext>::~theory_arith()",
    "non-virtual thunk to smt::theory_arith<smt::inf_ext>::~theory_arith()",
  ),
  (
    "_ZThn56_N3smt10theory_sls10get_paramsEv", "non-virtual thunk to smt::theory_sls::get_params()",
    "non-virtual thunk to smt::theory_sls::get_params()",
  ),
  (
    "_ZThn8_NK7datalog16relation_manager35default_table_filter_interpreted_fn13should_removeERK7svectorIyjE",
    "non-virtual thunk to datalog::relation_manager::default_table_filter_interpreted_fn::should_remove(svector<unsigned long long, unsigned int> const&) const",
    "non-virtual thunk to datalog::relation_manager::default_table_filter_interpreted_fn::should_remove(svector<unsigned long long, unsigned int> const&) const",
  ),
  (
    "_ZThn16_N27dependent_expr_state_tactic7updatedEv", "non-virtual thunk to dependent_expr_state_tactic::updated()",
    "non-virtual thunk to dependent_expr_state_tactic::updated()",
  ),
  (
    "_ZThn664_N4mlir6detail11PassOptions6OptionINS_4LLVM10VisibilityENS1_19GenericOptionParserIS4_EEED1Ev",
    "non-virtual thunk to mlir::detail::PassOptions::Option<mlir::LLVM::Visibility, mlir::detail::PassOptions::GenericOptionParser<mlir::LLVM::Visibility>>::~Option()",
    "non-virtual thunk to mlir::detail::PassOptions::Option<mlir::LLVM::Visibility, mlir::detail::PassOptions::GenericOptionParser<mlir::LLVM::Visibility>>::~Option()",
  ),
  (
    "_ZThn24_N4llvm3orc21LinkGraphLinkingLayer21handleRemoveResourcesERNS0_8JITDylibEm",
    "non-virtual thunk to llvm::orc::LinkGraphLinkingLayer::handleRemoveResources(llvm::orc::JITDylib&, unsigned long)",
    "non-virtual thunk to llvm::orc::LinkGraphLinkingLayer::handleRemoveResources(llvm::orc::JITDylib&, unsigned long)",
  ),
  (
    "_ZThn32_N8intblast6solver14finalize_modelER5model", "non-virtual thunk to intblast::solver::finalize_model(model&)",
    "non-virtual thunk to intblast::solver::finalize_model(model&)",
  ),
  (
    "_ZThn128_N12lldb_private7ProcessD1Ev", "non-virtual thunk to lldb_private::Process::~Process()",
    "non-virtual thunk to lldb_private::Process::~Process()",
  ),
  (
    "_ZThn512_N2v88internal7CppHeapD0Ev", "non-virtual thunk to v8::internal::CppHeap::~CppHeap()",
    "non-virtual thunk to v8::internal::CppHeap::~CppHeap()",
  ),
  (
    "_ZThn152_N4llvm20VPReductionPHIRecipeD0Ev", "non-virtual thunk to llvm::VPReductionPHIRecipe::~VPReductionPHIRecipe()",
    "non-virtual thunk to llvm::VPReductionPHIRecipe::~VPReductionPHIRecipe()",
  ),
  (
    "_ZThn24_N4node15SimpleWriteWrapINS_7ReqWrapI10uv_write_sEEED1Ev", "non-virtual thunk to node::SimpleWriteWrap<node::ReqWrap<uv_write_s>>::~SimpleWriteWrap()",
    "non-virtual thunk to node::SimpleWriteWrap<node::ReqWrap<uv_write_s>>::~SimpleWriteWrap()",
  ),
  (
    "_ZTv0_n32_NK12lldb_private30ScriptedProcessPythonInterface29GetAbstractMethodRequirementsEv",
    "virtual thunk to lldb_private::ScriptedProcessPythonInterface::GetAbstractMethodRequirements() const",
    "virtual thunk to lldb_private::ScriptedProcessPythonInterface::GetAbstractMethodRequirements() const",
  ),
  (
    "_ZTv0_n24_N2v88internal8compiler13TurboJsonFileD0Ev", "virtual thunk to v8::internal::compiler::TurboJsonFile::~TurboJsonFile()",
    "virtual thunk to v8::internal::compiler::TurboJsonFile::~TurboJsonFile()",
  ),
  (
    "_ZTv0_n24_N2v88internal8compiler13TurboJsonFileD1Ev", "virtual thunk to v8::internal::compiler::TurboJsonFile::~TurboJsonFile()",
    "virtual thunk to v8::internal::compiler::TurboJsonFile::~TurboJsonFile()",
  ),
  (
    "_ZTv0_n24_NSt3__119basic_ostringstreamIcNS_11char_traitsIcEENS_9allocatorIcEEED1Ev",
    "virtual thunk to std::__1::basic_ostringstream<char, std::__1::char_traits<char>, std::__1::allocator<char>>::~basic_ostringstream()",
    "virtual thunk to std::__1::basic_ostringstream<char, std::__1::char_traits<char>, std::__1::allocator<char>>::~basic_ostringstream()",
  ),
  (
    "_ZTv0_n24_NSt3__114basic_iostreamIwNS_11char_traitsIwEEED0Ev", "virtual thunk to std::__1::basic_iostream<wchar_t, std::__1::char_traits<wchar_t>>::~basic_iostream()",
    "virtual thunk to std::__1::basic_iostream<wchar_t, std::__1::char_traits<wchar_t>>::~basic_iostream()",
  ),
  (
    "_ZTv0_n24_NSt3__113basic_ostreamIcNS_11char_traitsIcEEED0Ev", "virtual thunk to std::__1::basic_ostream<char, std::__1::char_traits<char>>::~basic_ostream()",
    "virtual thunk to std::__1::basic_ostream<char, std::__1::char_traits<char>>::~basic_ostream()",
  ),
  (
    "_ZTv0_n88_N12lldb_private30OperatingSystemPythonInterface15GetRegisterInfoEv",
    "virtual thunk to lldb_private::OperatingSystemPythonInterface::GetRegisterInfo()",
    "virtual thunk to lldb_private::OperatingSystemPythonInterface::GetRegisterInfo()",
  ),
  (
    "_ZTv0_n24_NSt3__113basic_ostreamIwNS_11char_traitsIwEEED1Ev", "virtual thunk to std::__1::basic_ostream<wchar_t, std::__1::char_traits<wchar_t>>::~basic_ostream()",
    "virtual thunk to std::__1::basic_ostream<wchar_t, std::__1::char_traits<wchar_t>>::~basic_ostream()",
  ),
  (
    "_ZTv0_n24_N12lldb_private31ScriptedStopHookPythonInterfaceD0Ev", "virtual thunk to lldb_private::ScriptedStopHookPythonInterface::~ScriptedStopHookPythonInterface()",
    "virtual thunk to lldb_private::ScriptedStopHookPythonInterface::~ScriptedStopHookPythonInterface()",
  ),
  (
    "_ZTv0_n152_N12lldb_private30OperatingSystemPythonInterface13GetThreadInfoEv",
    "virtual thunk to lldb_private::OperatingSystemPythonInterface::GetThreadInfo()",
    "virtual thunk to lldb_private::OperatingSystemPythonInterface::GetThreadInfo()",
  ),
  (
    "_ZTv0_n24_N12lldb_private31ScriptedStopHookPythonInterfaceD1Ev", "virtual thunk to lldb_private::ScriptedStopHookPythonInterface::~ScriptedStopHookPythonInterface()",
    "virtual thunk to lldb_private::ScriptedStopHookPythonInterface::~ScriptedStopHookPythonInterface()",
  ),
  (
    "_ZTv0_n24_N12lldb_private29ScriptedThreadPythonInterfaceD0Ev", "virtual thunk to lldb_private::ScriptedThreadPythonInterface::~ScriptedThreadPythonInterface()",
    "virtual thunk to lldb_private::ScriptedThreadPythonInterface::~ScriptedThreadPythonInterface()",
  ),
  (
    "_ZGVZN5clang17getDriverOptTableEvE5Table", "guard variable for clang::getDriverOptTable()::Table",
    "guard variable for clang::getDriverOptTable()::Table",
  ),
  (
    "_ZGVZN5clang15DeclarationName21getUsingDirectiveNameEvE9UDirExtra", "guard variable for clang::DeclarationName::getUsingDirectiveName()::UDirExtra",
    "guard variable for clang::DeclarationName::getUsingDirectiveName()::UDirExtra",
  ),
  (
    "_ZGVZN4mlir6detail14TypeIDResolverIavE13resolveTypeIDEvE2id", "guard variable for mlir::detail::TypeIDResolver<signed char, void>::resolveTypeID()::id",
    "guard variable for mlir::detail::TypeIDResolver<signed char, void>::resolveTypeID()::id",
  ),
  (
    "_ZGVZ14_As_WasmObjectmE6result", "guard variable for _As_WasmObject(unsigned long)::result",
    "guard variable for _As_WasmObject(unsigned long)::result",
  ),
  (
    "_ZGVZ26_As_JSRegExpStringIteratormE6result", "guard variable for _As_JSRegExpStringIterator(unsigned long)::result",
    "guard variable for _As_JSRegExpStringIterator(unsigned long)::result",
  ),
  (
    "_ZGVZN4llvm19getThePPC64LETargetEvE16ThePPC64LETarget", "guard variable for llvm::getThePPC64LETarget()::ThePPC64LETarget",
    "guard variable for llvm::getThePPC64LETarget()::ThePPC64LETarget",
  ),
  (
    "_ZGVN3ada37url_pattern_compile_component_options8PATHNAMEE", "guard variable for ada::url_pattern_compile_component_options::PATHNAME",
    "guard variable for ada::url_pattern_compile_component_options::PATHNAME",
  ),
  (
    "_ZGVZN4llvm20getTheARM64_32TargetEvE17TheARM64_32Target", "guard variable for llvm::getTheARM64_32Target()::TheARM64_32Target",
    "guard variable for llvm::getTheARM64_32Target()::TheARM64_32Target",
  ),
  (
    "_ZGVZ21_As_InstructionStreammE6result", "guard variable for _As_InstructionStream(unsigned long)::result",
    "guard variable for _As_InstructionStream(unsigned long)::result",
  ),
  (
    "_ZGVZ44_As_UncompiledDataWithoutPreparseDataWithJobmE6result", "guard variable for _As_UncompiledDataWithoutPreparseDataWithJob(unsigned long)::result",
    "guard variable for _As_UncompiledDataWithoutPreparseDataWithJob(unsigned long)::result",
  ),
  (
    "_ZGVZN4mlir6detail14TypeIDResolverINS_4pdll3ast11DeclRefExprEvE13resolveTypeIDEvE2id",
    "guard variable for mlir::detail::TypeIDResolver<mlir::pdll::ast::DeclRefExpr, void>::resolveTypeID()::id",
    "guard variable for mlir::detail::TypeIDResolver<mlir::pdll::ast::DeclRefExpr, void>::resolveTypeID()::id",
  ),
  (
    "_ZGVZN4llvm17getTheSparcTargetEvE14TheSparcTarget", "guard variable for llvm::getTheSparcTarget()::TheSparcTarget",
    "guard variable for llvm::getTheSparcTarget()::TheSparcTarget",
  ),
  (
    "_ZGRN2v88internal12_GLOBAL__N_128kLongShortNarrowNumericEnumsE_", "reference temporary for v8::internal::(anonymous namespace)::kLongShortNarrowNumericEnums",
    "reference temporary for v8::internal::(anonymous namespace)::kLongShortNarrowNumericEnums",
  ),
  (
    "_ZGRL10AllVectors_", "reference temporary for AllVectors", "reference temporary for AllVectors",
  ),
  (
    "_ZGRZN4LIEF3ELF23determine_elf_endianessERNS_12BinaryStreamEE14BOTH_ENDIANESS_",
    "reference temporary for LIEF::ELF::determine_elf_endianess(LIEF::BinaryStream&)::BOTH_ENDIANESS",
    "reference temporary for LIEF::ELF::determine_elf_endianess(LIEF::BinaryStream&)::BOTH_ENDIANESS",
  ),
  (
    "_ZGRL13AllS32Vectors_", "reference temporary for AllS32Vectors", "reference temporary for AllS32Vectors",
  ),
  (
    "_ZGRN4LIEF2PEL19WINDOW_STYLES_ARRAYE_", "reference temporary for LIEF::PE::WINDOW_STYLES_ARRAY",
    "reference temporary for LIEF::PE::WINDOW_STYLES_ARRAY",
  ),
  (
    "_ZGRZNK4LIEF3ELF6Binary20is_targeting_androidEvE10ANDROID_DT_", "reference temporary for LIEF::ELF::Binary::is_targeting_android() const::ANDROID_DT",
    "reference temporary for LIEF::ELF::Binary::is_targeting_android() const::ANDROID_DT",
  ),
  (
    "_ZGRN2v88internal12_GLOBAL__N_121kLongShortNarrowEnumsE_", "reference temporary for v8::internal::(anonymous namespace)::kLongShortNarrowEnums",
    "reference temporary for v8::internal::(anonymous namespace)::kLongShortNarrowEnums",
  ),
  (
    "_ZGRN4LIEF5MachOL12HEADER_FLAGSE_", "reference temporary for LIEF::MachO::HEADER_FLAGS",
    "reference temporary for LIEF::MachO::HEADER_FLAGS",
  ),
  (
    "_ZGRN4LIEF2PEL14RESOURCE_TYPESE_", "reference temporary for LIEF::PE::RESOURCE_TYPES",
    "reference temporary for LIEF::PE::RESOURCE_TYPES",
  ),
  (
    "_ZGRN4LIEFL11ARRAY_MODESE_", "reference temporary for LIEF::ARRAY_MODES", "reference temporary for LIEF::ARRAY_MODES",
  ),
  (
    "_ZGRN4LIEF2PEL11ARRAY_FLAGSE_", "reference temporary for LIEF::PE::ARRAY_FLAGS",
    "reference temporary for LIEF::PE::ARRAY_FLAGS",
  ),
  (
    "_ZGRN2v88internal12_GLOBAL__N_134kLongShortNarrowNumeric2DigitEnumsE_", "reference temporary for v8::internal::(anonymous namespace)::kLongShortNarrowNumeric2DigitEnums",
    "reference temporary for v8::internal::(anonymous namespace)::kLongShortNarrowNumeric2DigitEnums",
  ),
  (
    "_ZTWN2v88internal6maglev21thread_graph_labellerE", "thread-local wrapper routine for v8::internal::maglev::thread_graph_labeller",
    "thread-local wrapper routine for v8::internal::maglev::thread_graph_labeller",
  ),
  (
    "_ZTWN2v88internal12trap_handler16TrapHandlerGuard10is_active_E", "thread-local wrapper routine for v8::internal::trap_handler::TrapHandlerGuard::is_active_",
    "thread-local wrapper routine for v8::internal::trap_handler::TrapHandlerGuard::is_active_",
  ),
  (
    "_ZTWN7decimal7contextE", "thread-local wrapper routine for decimal::context",
    "thread-local wrapper routine for decimal::context",
  ),
  (
    "_ZTWN2v88internal18g_current_isolate_E", "thread-local wrapper routine for v8::internal::g_current_isolate_",
    "thread-local wrapper routine for v8::internal::g_current_isolate_",
  ),
  (
    "_ZTWN5lexer19last_error_locationE", "thread-local wrapper routine for lexer::last_error_location",
    "thread-local wrapper routine for lexer::last_error_location",
  ),
  (
    "_ZTWN7decimal7contextE.cold.1", "thread-local wrapper routine for decimal::context (.cold.1)",
    "thread-local wrapper routine for decimal::context (.cold.1)",
  ),
  (
    "_ZTWN4llvm8parallel11threadIndexE", "thread-local wrapper routine for llvm::parallel::threadIndex",
    "thread-local wrapper routine for llvm::parallel::threadIndex",
  ),
  (
    "_ZTWN2v88internal21g_current_local_heap_E", "thread-local wrapper routine for v8::internal::g_current_local_heap_",
    "thread-local wrapper routine for v8::internal::g_current_local_heap_",
  ),
  (
    "_ZTWN2v88internal34g_current_per_isolate_thread_data_E", "thread-local wrapper routine for v8::internal::g_current_per_isolate_thread_data_",
    "thread-local wrapper routine for v8::internal::g_current_per_isolate_thread_data_",
  ),
  (
    "_ZTWN4absl13base_internal19thread_identity_ptrE", "thread-local wrapper routine for absl::base_internal::thread_identity_ptr",
    "thread-local wrapper routine for absl::base_internal::thread_identity_ptr",
  ),
  (
    "_ZTWN5lexer10last_errorE", "thread-local wrapper routine for lexer::last_error",
    "thread-local wrapper routine for lexer::last_error",
  ),
  (
    "_ZZ15install_tacticsR14tactic_managerEN5$_1138__invokeER11ast_managerRK10params_ref",
    "install_tactics(tactic_manager&)::$_113::__invoke(ast_manager&, params_ref const&)",
    "install_tactics(tactic_manager&)::$_113::__invoke",
  ),
  (
    "_ZZN5clang4ento17ProgramStateTraitIN12_GLOBAL__N_117VforkResultRegionEE8GDMIndexEvE5Index",
    "clang::ento::ProgramStateTrait<(anonymous namespace)::VforkResultRegion>::GDMIndex()::Index",
    "clang::ento::ProgramStateTrait<(anonymous namespace)::VforkResultRegion>::GDMIndex()::Index",
  ),
  (
    "_ZZN4mlir5spirv4impl26SPIRVWebGPUPreparePassBaseINS0_12_GLOBAL__N_117WebGPUPreparePassEE13resolveTypeIDEvE2id",
    "mlir::spirv::impl::SPIRVWebGPUPreparePassBase<mlir::spirv::(anonymous namespace)::WebGPUPreparePass>::resolveTypeID()::id",
    "mlir::spirv::impl::SPIRVWebGPUPreparePassBase<mlir::spirv::(anonymous namespace)::WebGPUPreparePass>::resolveTypeID()::id",
  ),
  (
    "_ZZN2v88internal6maglev18MaglevGraphBuilder11AddDeoptUseEPNS1_13VirtualObjectEENK3$_0clEPNS1_9ValueNodeE",
    "v8::internal::maglev::MaglevGraphBuilder::AddDeoptUse(v8::internal::maglev::VirtualObject*)::$_0::operator()(v8::internal::maglev::ValueNode*) const",
    "v8::internal::maglev::MaglevGraphBuilder::AddDeoptUse(v8::internal::maglev::VirtualObject*)::$_0::operator()",
  ),
  (
    "_ZZN4mlir5spirv13getExtensionsENS0_10CapabilityEE4exts__50_", "mlir::spirv::getExtensions(mlir::spirv::Capability)::exts",
    "mlir::spirv::getExtensions(mlir::spirv::Capability)::exts",
  ),
  (
    "_ZZN4mlir5spirv15getCapabilitiesENS0_11MemoryModelEE4caps", "mlir::spirv::getCapabilities(mlir::spirv::MemoryModel)::caps",
    "mlir::spirv::getCapabilities(mlir::spirv::MemoryModel)::caps",
  ),
  (
    "_ZZN4node4Blob15StoreDataObjectERKN2v820FunctionCallbackInfoINS1_5ValueEEEE20error_and_abort_args",
    "node::Blob::StoreDataObject(v8::FunctionCallbackInfo<v8::Value> const&)::error_and_abort_args",
    "node::Blob::StoreDataObject(v8::FunctionCallbackInfo<v8::Value> const&)::error_and_abort_args",
  ),
  (
    "_ZZN4mlir5spirv13getExtensionsENS0_10CapabilityEE4exts__110_", "mlir::spirv::getExtensions(mlir::spirv::Capability)::exts",
    "mlir::spirv::getExtensions(mlir::spirv::Capability)::exts",
  ),
  (
    "_ZZN4mlir6detail14TypeIDResolverINS_3omp22OffloadModuleInterfaceEvE13resolveTypeIDEvE2id",
    "mlir::detail::TypeIDResolver<mlir::omp::OffloadModuleInterface, void>::resolveTypeID()::id",
    "mlir::detail::TypeIDResolver<mlir::omp::OffloadModuleInterface, void>::resolveTypeID()::id",
  ),
  (
    "_ZZN4mlir5spirv15getCapabilitiesENS0_12StorageClassEE4caps_1", "mlir::spirv::getCapabilities(mlir::spirv::StorageClass)::caps",
    "mlir::spirv::getCapabilities(mlir::spirv::StorageClass)::caps",
  ),
  (
    "_ZZN2v84base7ieee7544coshEdE4huge", "v8::base::ieee754::cosh(double)::huge",
    "v8::base::ieee754::cosh(double)::huge",
  ),
  (
    "_ZZN4node6fs_dirL7OpenDirERKN2v820FunctionCallbackInfoINS1_5ValueEEEE20error_and_abort_args",
    "node::fs_dir::OpenDir(v8::FunctionCallbackInfo<v8::Value> const&)::error_and_abort_args",
    "node::fs_dir::OpenDir(v8::FunctionCallbackInfo<v8::Value> const&)::error_and_abort_args",
  ),
  (
    "_ZNK4llvm16HexagonInstrInfo20changeAddrMode_pi_ioEs", "llvm::HexagonInstrInfo::changeAddrMode_pi_io(short) const",
    "llvm::HexagonInstrInfo::changeAddrMode_pi_io",
  ),
  (
    "_ZN4mlir7Builder17getI16IntegerAttrEs", "mlir::Builder::getI16IntegerAttr(short)",
    "mlir::Builder::getI16IntegerAttr",
  ),
  (
    "_ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEElsEs", "std::__1::basic_ostream<char, std::__1::char_traits<char>>::operator<<(short)",
    "std::__1::basic_ostream<char, std::__1::char_traits<char>>::operator<<",
  ),
  (
    "_ZN4llvm6object15XCOFFObjectFile23isReservedSectionNumberEs", "llvm::object::XCOFFObjectFile::isReservedSectionNumber(short)",
    "llvm::object::XCOFFObjectFile::isReservedSectionNumber",
  ),
  (
    "_ZN2v88internal4wasm13ConvertToF16SEs", "v8::internal::wasm::ConvertToF16S(short)",
    "v8::internal::wasm::ConvertToF16S",
  ),
  (
    "_ZNK4llvm16HexagonInstrInfo20changeAddrMode_rr_urEs", "llvm::HexagonInstrInfo::changeAddrMode_rr_ur(short) const",
    "llvm::HexagonInstrInfo::changeAddrMode_rr_ur",
  ),
  (
    "_ZN4llvm17JSONScopedPrinter11printNumberENS_9StringRefEs", "llvm::JSONScopedPrinter::printNumber(llvm::StringRef, short)",
    "llvm::JSONScopedPrinter::printNumber",
  ),
  (
    "_ZNK4llvm16HexagonInstrInfo20changeAddrMode_rr_ioEs", "llvm::HexagonInstrInfo::changeAddrMode_rr_io(short) const",
    "llvm::HexagonInstrInfo::changeAddrMode_rr_io",
  ),
  (
    "_ZNK4llvm16HexagonInstrInfo21changeAddrMode_abs_ioEs", "llvm::HexagonInstrInfo::changeAddrMode_abs_io(short) const",
    "llvm::HexagonInstrInfo::changeAddrMode_abs_io",
  ),
  (
    "_ZNK4llvm6object15XCOFFObjectFile15getSectionByNumEs", "llvm::object::XCOFFObjectFile::getSectionByNum(short) const",
    "llvm::object::XCOFFObjectFile::getSectionByNum",
  ),
  (
    "_ZNK4llvm16HexagonInstrInfo20changeAddrMode_io_rrEs", "llvm::HexagonInstrInfo::changeAddrMode_io_rr(short) const",
    "llvm::HexagonInstrInfo::changeAddrMode_io_rr",
  ),
  (
    "_ZNK4llvm16HexagonInstrInfo20changeAddrMode_io_piEs", "llvm::HexagonInstrInfo::changeAddrMode_io_pi(short) const",
    "llvm::HexagonInstrInfo::changeAddrMode_io_pi",
  ),
  (
    "_ZTIZN4mlir6affine24registerAffineLoopFusionEvEUlvE_", "typeinfo for mlir::affine::registerAffineLoopFusion()::'lambda'()",
    "typeinfo for mlir::affine::registerAffineLoopFusion()::'lambda'()",
  ),
  (
    "_ZNKSt3__110__function6__funcIZN12_GLOBAL__N_116PluginPropertiesC1EvEUlvE_FvvEE6targetERKSt9type_info",
    "std::__1::__function::__func<(anonymous namespace)::PluginProperties::PluginProperties()::'lambda'(), void ()>::target(std::type_info const&) const",
    "std::__1::__function::__func<(anonymous namespace)::PluginProperties::PluginProperties()::'lambda'(), void ()>::target",
  ),
  (
    "_ZTINSt3__110__function6__funcIN12_GLOBAL__N_117DebugCounterOwner17PrintDebugCounterMUlRKbE_EFvS6_EEE",
    "typeinfo for std::__1::__function::__func<(anonymous namespace)::DebugCounterOwner::PrintDebugCounter::'lambda'(bool const&), void (bool const&)>",
    "typeinfo for std::__1::__function::__func<(anonymous namespace)::DebugCounterOwner::PrintDebugCounter::'lambda'(bool const&), void (bool const&)>",
  ),
  (
    "_ZTINSt3__110__function6__funcIZNK4llvm5MachO9SymbolSet7exportsEvEUlPKNS3_6SymbolEE_FbS7_EEE",
    "typeinfo for std::__1::__function::__func<llvm::MachO::SymbolSet::exports() const::'lambda'(llvm::MachO::Symbol const*), bool (llvm::MachO::Symbol const*)>",
    "typeinfo for std::__1::__function::__func<llvm::MachO::SymbolSet::exports() const::'lambda'(llvm::MachO::Symbol const*), bool (llvm::MachO::Symbol const*)>",
  ),
  (
    "_ZTSZN4mlir4LLVM32registerDIScopeForLLVMFuncOpPassEvEUlvE_", "typeinfo name for mlir::LLVM::registerDIScopeForLLVMFuncOpPass()::'lambda'()",
    "typeinfo name for mlir::LLVM::registerDIScopeForLLVMFuncOpPass()::'lambda'()",
  ),
  (
    "_ZNSt3__110__function6__funcIN12_GLOBAL__N_117DebugCounterOwner17PrintDebugCounterMUlRKbE_EFvS6_EEclES6_",
    "std::__1::__function::__func<(anonymous namespace)::DebugCounterOwner::PrintDebugCounter::'lambda'(bool const&), void (bool const&)>::operator()(bool const&)",
    "std::__1::__function::__func<(anonymous namespace)::DebugCounterOwner::PrintDebugCounter::'lambda'(bool const&), void (bool const&)>::operator()",
  ),
  (
    "_ZTSZN4mlir33registerConvertAffineForToGPUPassEvEUlvE_", "typeinfo name for mlir::registerConvertAffineForToGPUPass()::'lambda'()",
    "typeinfo name for mlir::registerConvertAffineForToGPUPass()::'lambda'()",
  ),
  (
    "_ZTSZN12_GLOBAL__N_125PromoteBuffersToStackPass10initializeEPN4mlir11MLIRContextEEUlNS1_5ValueEE_",
    "typeinfo name for (anonymous namespace)::PromoteBuffersToStackPass::initialize(mlir::MLIRContext*)::'lambda'(mlir::Value)",
    "typeinfo name for (anonymous namespace)::PromoteBuffersToStackPass::initialize(mlir::MLIRContext*)::'lambda'(mlir::Value)",
  ),
  (
    "_ZTSZN4mlir27registerConvertArithToEmitCEvEUlvE_", "typeinfo name for mlir::registerConvertArithToEmitC()::'lambda'()",
    "typeinfo name for mlir::registerConvertArithToEmitC()::'lambda'()",
  ),
  (
    "_ZTSZN4mlir6affine25registerAffineParallelizeEvEUlvE_", "typeinfo name for mlir::affine::registerAffineParallelize()::'lambda'()",
    "typeinfo name for mlir::affine::registerAffineParallelize()::'lambda'()",
  ),
  (
    "_ZZN3smt10theory_lra3imp18mk_idiv_mod_axiomsEP4exprS3_ENKUlvE_clEv", "smt::theory_lra::imp::mk_idiv_mod_axioms(expr*, expr*)::'lambda'()::operator()() const",
    "smt::theory_lra::imp::mk_idiv_mod_axioms(expr*, expr*)::'lambda'()::operator()",
  ),
  (
    "_ZTSZN4mlir33registerConvertTensorToLinalgPassEvEUlvE_", "typeinfo name for mlir::registerConvertTensorToLinalgPass()::'lambda'()",
    "typeinfo name for mlir::registerConvertTensorToLinalgPass()::'lambda'()",
  ),
  (
    "_ZN4llvm3orc33setUpInProcessLCTMReentryViaEPCIUERNS0_19EPCIndirectionUtilsE",
    "llvm::orc::setUpInProcessLCTMReentryViaEPCIU(llvm::orc::EPCIndirectionUtils&)",
    "llvm::orc::setUpInProcessLCTMReentryViaEPCIU",
  ),
  (
    "_ZN4idna5uts465Uts4611check_label17hd53b480f57ba465eE", "idna::uts46::Uts46::check_label::hd53b480f57ba465e",
    "idna::uts46::Uts46::check_label::hd53b480f57ba465e",
  ),
  (
    "_ZN2v88internal10ErrorUtils17GetFormattedStackEPNS0_7IsolateENS0_12DirectHandleINS0_8JSObjectEEE.cold.2",
    "v8::internal::ErrorUtils::GetFormattedStack(v8::internal::Isolate*, v8::internal::DirectHandle<v8::internal::JSObject>) (.cold.2)",
    "v8::internal::ErrorUtils::GetFormattedStack",
  ),
  (
    "_ZN4node4i18n12_GLOBAL__N_121TranscodeUcs2FromUtf8EPNS_11EnvironmentEPKcS5_S5_mP10UErrorCode",
    "node::i18n::(anonymous namespace)::TranscodeUcs2FromUtf8(node::Environment*, char const*, char const*, char const*, unsigned long, UErrorCode*)",
    "node::i18n::(anonymous namespace)::TranscodeUcs2FromUtf8",
  ),
  (
    "_ZN2v88internal23Runtime_StringUtf8ValueEiPmPNS0_7IsolateE.cold.1", "v8::internal::Runtime_StringUtf8Value(int, unsigned long*, v8::internal::Isolate*) (.cold.1)",
    "v8::internal::Runtime_StringUtf8Value",
  ),
  (
    "_ZTVN2v88internal28BufferedUtf16CharacterStreamE", "vtable for v8::internal::BufferedUtf16CharacterStream",
    "vtable for v8::internal::BufferedUtf16CharacterStream",
  ),
  (
    "_ZN2v88internal27Utf8ExternalStreamingStream10FetchChunkEv", "v8::internal::Utf8ExternalStreamingStream::FetchChunk()",
    "v8::internal::Utf8ExternalStreamingStream::FetchChunk",
  ),
  (
    "_ZN4llvm7support6detail30stream_operator_format_adapterIN12lldb_private18DWARFCallFrameInfoUt_EED0Ev",
    "llvm::support::detail::stream_operator_format_adapter<lldb_private::DWARFCallFrameInfo::'unnamed'>::~stream_operator_format_adapter()",
    "llvm::support::detail::stream_operator_format_adapter<lldb_private::DWARFCallFrameInfo::'unnamed'>::~stream_operator_format_adapter",
  ),
  (
    "_ZN4mlir17VulkanLayoutUtils12decorateTypeENS_5spirv10StructTypeE", "mlir::VulkanLayoutUtils::decorateType(mlir::spirv::StructType)",
    "mlir::VulkanLayoutUtils::decorateType",
  ),
  (
    "_ZZN4node6Buffer12_GLOBAL__N_16IsUtf8ERKN2v820FunctionCallbackInfoINS2_5ValueEEEE20error_and_abort_args",
    "node::Buffer::(anonymous namespace)::IsUtf8(v8::FunctionCallbackInfo<v8::Value> const&)::error_and_abort_args",
    "node::Buffer::(anonymous namespace)::IsUtf8(v8::FunctionCallbackInfo<v8::Value> const&)::error_and_abort_args",
  ),
  (
    "_ZN2v85Utils16ReportOOMFailureEPNS_8internal7IsolateEPKcRKNS_10OOMDetailsE",
    "v8::Utils::ReportOOMFailure(v8::internal::Isolate*, char const*, v8::OOMDetails const&)",
    "v8::Utils::ReportOOMFailure",
  ),
  (
    "_ZTIN4llvm3orc25EPCIndirectionUtilsAccessE", "typeinfo for llvm::orc::EPCIndirectionUtilsAccess",
    "typeinfo for llvm::orc::EPCIndirectionUtilsAccess",
  ),
  (
    "_ZN8v8_crdtp14UberDispatcher14DispatchResultC2EbNSt3__18functionIFvvEEE", "v8_crdtp::UberDispatcher::DispatchResult::DispatchResult(bool, std::__1::function<void ()>)",
    "v8_crdtp::UberDispatcher::DispatchResult::DispatchResult",
  ),
  (
    "_ZN4node9inspector8protocol10DOMStorage10Dispatcher4wireEPN5crdtp14UberDispatcherEPNS2_7BackendE.cold.2",
    "node::inspector::protocol::DOMStorage::Dispatcher::wire(crdtp::UberDispatcher*, node::inspector::protocol::DOMStorage::Backend*) (.cold.2)",
    "node::inspector::protocol::DOMStorage::Dispatcher::wire",
  ),
  (
    "_ZN4node9inspector8protocol7Network10Dispatcher4wireEPN5crdtp14UberDispatcherEPNS2_7BackendE",
    "node::inspector::protocol::Network::Dispatcher::wire(crdtp::UberDispatcher*, node::inspector::protocol::Network::Backend*)",
    "node::inspector::protocol::Network::Dispatcher::wire",
  ),
  (
    "_ZN4node9inspector8protocol11NodeRuntime10Dispatcher4wireEPN5crdtp14UberDispatcherEPNS2_7BackendE.cold.1",
    "node::inspector::protocol::NodeRuntime::Dispatcher::wire(crdtp::UberDispatcher*, node::inspector::protocol::NodeRuntime::Backend*) (.cold.1)",
    "node::inspector::protocol::NodeRuntime::Dispatcher::wire",
  ),
  (
    "_ZN4node9inspector8protocol7IoAgent4WireEPN5crdtp14UberDispatcherE", "node::inspector::protocol::IoAgent::Wire(crdtp::UberDispatcher*)",
    "node::inspector::protocol::IoAgent::Wire",
  ),
  (
    "_ZN8v8_crdtp14UberDispatcherC2EPNS_15FrontendChannelE", "v8_crdtp::UberDispatcher::UberDispatcher(v8_crdtp::FrontendChannel*)",
    "v8_crdtp::UberDispatcher::UberDispatcher",
  ),
  (
    "_ZN8v8_crdtp14UberDispatcher14DispatchResultC1EbNSt3__18functionIFvvEEE", "v8_crdtp::UberDispatcher::DispatchResult::DispatchResult(bool, std::__1::function<void ()>)",
    "v8_crdtp::UberDispatcher::DispatchResult::DispatchResult",
  ),
  (
    "_ZN8v8_crdtp14UberDispatcher14DispatchResult3RunEv", "v8_crdtp::UberDispatcher::DispatchResult::Run()",
    "v8_crdtp::UberDispatcher::DispatchResult::Run",
  ),
  (
    "_ZN4node9inspector12NetworkAgent4WireEPN5crdtp14UberDispatcherE", "node::inspector::NetworkAgent::Wire(crdtp::UberDispatcher*)",
    "node::inspector::NetworkAgent::Wire",
  ),
  (
    "_ZN4node9inspector8protocol12TracingAgent4WireEPN5crdtp14UberDispatcherE", "node::inspector::protocol::TracingAgent::Wire(crdtp::UberDispatcher*)",
    "node::inspector::protocol::TracingAgent::Wire",
  ),
  (
    "_ZN4node9inspector8protocol7Network10Dispatcher4wireEPN5crdtp14UberDispatcherEPNS2_7BackendE.cold.2",
    "node::inspector::protocol::Network::Dispatcher::wire(crdtp::UberDispatcher*, node::inspector::protocol::Network::Backend*) (.cold.2)",
    "node::inspector::protocol::Network::Dispatcher::wire",
  ),
  (
    "_ZN4node9inspector8protocol11NodeTracing10Dispatcher4wireEPN5crdtp14UberDispatcherEPNS2_7BackendE",
    "node::inspector::protocol::NodeTracing::Dispatcher::wire(crdtp::UberDispatcher*, node::inspector::protocol::NodeTracing::Backend*)",
    "node::inspector::protocol::NodeTracing::Dispatcher::wire",
  ),
  (
    "_ZNSt3__16vectorINS_4pairIjjEENS_9allocatorIS2_EEE9push_backB9nqn210106ERKS2_",
    "std::__1::vector<std::__1::pair<unsigned int, unsigned int>, std::__1::allocator<std::__1::pair<unsigned int, unsigned int>>>::push_back[abi:nqn210106](std::__1::pair<unsigned int, unsigned int> const&)",
    "std::__1::vector<std::__1::pair<unsigned int, unsigned int>, std::__1::allocator<std::__1::pair<unsigned int, unsigned int>>>::push_back[abi:nqn210106]",
  ),
  (
    "_ZNSt3__110shared_ptrIN7Imf_3_421DeepScanLineInputFileEED2B8ne190102Ev", "std::__1::shared_ptr<Imf_3_4::DeepScanLineInputFile>::~shared_ptr[abi:ne190102]()",
    "std::__1::shared_ptr<Imf_3_4::DeepScanLineInputFile>::~shared_ptr[abi:ne190102]",
  ),
  (
    "_ZNSt3__116__rotate_forwardB9nqn210106INS_17_ClassicAlgPolicyEPN5clang20CodeCompletionResultEEET0_S5_S5_S5_",
    "clang::CodeCompletionResult* std::__1::__rotate_forward[abi:nqn210106]<std::__1::_ClassicAlgPolicy, clang::CodeCompletionResult*>(clang::CodeCompletionResult*, clang::CodeCompletionResult*, clang::CodeCompletionResult*)",
    "std::__1::__rotate_forward[abi:nqn210106]<std::__1::_ClassicAlgPolicy, clang::CodeCompletionResult*>",
  ),
  (
    "_ZN4llvm5RTLIB6getCOSENS_3EVTE", "llvm::RTLIB::getCOS(llvm::EVT)", "llvm::RTLIB::getCOS",
  ),
  (
    "_ZNSt3__16vectorINS_8functionIFvRN4llvm11raw_ostreamEEEENS_9allocatorIS6_EEED1B9nqn210106Ev",
    "std::__1::vector<std::__1::function<void (llvm::raw_ostream&)>, std::__1::allocator<std::__1::function<void (llvm::raw_ostream&)>>>::~vector[abi:nqn210106]()",
    "std::__1::vector<std::__1::function<void (llvm::raw_ostream&)>, std::__1::allocator<std::__1::function<void (llvm::raw_ostream&)>>>::~vector[abi:nqn210106]",
  ),
  (
    "_ZN4llvm3X8614isVFNMSUB132SHEj", "llvm::X86::isVFNMSUB132SH(unsigned int)",
    "llvm::X86::isVFNMSUB132SH",
  ),
  (
    "_ZNSt3__116ostream_iteratorIN5GpgME13Configuration6OptionEcNS_11char_traitsIcEEEaSB8ne200100ERKS3_",
    "std::__1::ostream_iterator<GpgME::Configuration::Option, char, std::__1::char_traits<char>>::operator=[abi:ne200100](GpgME::Configuration::Option const&)",
    "std::__1::ostream_iterator<GpgME::Configuration::Option, char, std::__1::char_traits<char>>::operator=[abi:ne200100]",
  ),
  (
    "_ZNSt3__124__optional_destruct_baseIN5clang13DarwinSDKInfoELb0EE5resetB9nqn210106Ev",
    "std::__1::__optional_destruct_base<clang::DarwinSDKInfo, false>::reset[abi:nqn210106]()",
    "std::__1::__optional_destruct_base<clang::DarwinSDKInfo, false>::reset[abi:nqn210106]",
  ),
  (
    "_ZNSt3__110__function12__value_funcIFvPN3euf5enodeES4_EEC2B9nqe210106ERKS6_",
    "std::__1::__function::__value_func<void (euf::enode*, euf::enode*)>::__value_func[abi:nqe210106](std::__1::__function::__value_func<void (euf::enode*, euf::enode*)> const&)",
    "std::__1::__function::__value_func<void (euf::enode*, euf::enode*)>::__value_func[abi:nqe210106]",
  ),
  (
    "_ZNSt3__18_IterOpsINS_17_ClassicAlgPolicyEE9iter_swapB9nqn210106IRPN4llvm4yaml12CalledGlobalES8_EEvOT_OT0_",
    "void std::__1::_IterOps<std::__1::_ClassicAlgPolicy>::iter_swap[abi:nqn210106]<llvm::yaml::CalledGlobal*&, llvm::yaml::CalledGlobal*&>(llvm::yaml::CalledGlobal*&, llvm::yaml::CalledGlobal*&)",
    "std::__1::_IterOps<std::__1::_ClassicAlgPolicy>::iter_swap[abi:nqn210106]<llvm::yaml::CalledGlobal*&, llvm::yaml::CalledGlobal*&>",
  ),
  (
    "_ZNSt3__110shared_ptrIN4node6worker12SiblingGroupEEC2B8nn190102IS3_Li0EEERKNS_8weak_ptrIT_EE",
    "std::__1::shared_ptr<node::worker::SiblingGroup>::shared_ptr[abi:nn190102]<node::worker::SiblingGroup, 0>(std::__1::weak_ptr<node::worker::SiblingGroup> const&)",
    "std::__1::shared_ptr<node::worker::SiblingGroup>::shared_ptr[abi:nn190102]<node::worker::SiblingGroup, 0>",
  ),
  (
    "_ZNSt3__19allocatorItE17allocate_at_leastB8ne200100Em", "std::__1::allocator<unsigned short>::allocate_at_least[abi:ne200100](unsigned long)",
    "std::__1::allocator<unsigned short>::allocate_at_least[abi:ne200100]",
  ),
  (
    "_ZN2v88internal12WriteBarrier22PageFlagsAreConsistentENS0_6TaggedINS0_10HeapObjectEEE.cold.4",
    "v8::internal::WriteBarrier::PageFlagsAreConsistent(v8::internal::Tagged<v8::internal::HeapObject>) (.cold.4)",
    "v8::internal::WriteBarrier::PageFlagsAreConsistent",
  ),
  (
    "_ZN2v88internal14LookupIterator5StartILb1EEEvv.cold.1", "void v8::internal::LookupIterator::Start<true>() (.cold.1)",
    "v8::internal::LookupIterator::Start<true>",
  ),
  (
    "_ZN42_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$3fmt17h98bad91cf1169a39E", "_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$::fmt::h98bad91cf1169a39",
    "_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$::fmt::h98bad91cf1169a39",
  ),
  (
    "_ZN2v88internal36Builtin_LocalePrototypeGetHourCyclesEiPmPNS0_7IsolateE.cold.1",
    "v8::internal::Builtin_LocalePrototypeGetHourCycles(int, unsigned long*, v8::internal::Isolate*) (.cold.1)",
    "v8::internal::Builtin_LocalePrototypeGetHourCycles",
  ),
  (
    "_ZN66_$LT$rsvg..image..Image$u20$as$u20$rsvg..element..ElementTrait$GT$6layout17h87e55ab7db0a1ddbE",
    "_$LT$rsvg..image..Image$u20$as$u20$rsvg..element..ElementTrait$GT$::layout::h87e55ab7db0a1ddb",
    "_$LT$rsvg..image..Image$u20$as$u20$rsvg..element..ElementTrait$GT$::layout::h87e55ab7db0a1ddb",
  ),
  (
    "_ZN4node12_GLOBAL__N_110ZlibStream4InitERKN2v820FunctionCallbackInfoINS2_5ValueEEE.cold.4",
    "node::(anonymous namespace)::ZlibStream::Init(v8::FunctionCallbackInfo<v8::Value> const&) (.cold.4)",
    "node::(anonymous namespace)::ZlibStream::Init",
  ),
  (
    "_ZN2v88internal8compiler12JSHeapBroker20empty_property_arrayEv.cold.1", "v8::internal::compiler::JSHeapBroker::empty_property_array() (.cold.1)",
    "v8::internal::compiler::JSHeapBroker::empty_property_array",
  ),
  (
    "_ZN2v88internal12_GLOBAL__N_116ToICUStringPieceEPNS0_7IsolateENS0_12DirectHandleINS0_6StringEEEj.cold.2",
    "v8::internal::(anonymous namespace)::ToICUStringPiece(v8::internal::Isolate*, v8::internal::DirectHandle<v8::internal::String>, unsigned int) (.cold.2)",
    "v8::internal::(anonymous namespace)::ToICUStringPiece",
  ),
  (
    "_ZN4node6timers11BindingData15SlowGetLibuvNowERKN2v820FunctionCallbackInfoINS2_5ValueEEE.cold.2",
    "node::timers::BindingData::SlowGetLibuvNow(v8::FunctionCallbackInfo<v8::Value> const&) (.cold.2)",
    "node::timers::BindingData::SlowGetLibuvNow",
  ),
  (
    "_ZN3hwy6N_NEON12VQSortStaticIjNS_14SortDescendingEEEvPT_mT0_.cold.1", "void hwy::N_NEON::VQSortStatic<unsigned int, hwy::SortDescending>(unsigned int*, unsigned long, hwy::SortDescending) (.cold.1)",
    "hwy::N_NEON::VQSortStatic<unsigned int, hwy::SortDescending>",
  ),
  (
    "_ZN4core3ptr48drop_in_place$LT$rsvg..text..PositionedChunk$GT$17h7439e3348f527dc6E",
    "core::ptr::drop_in_place$LT$rsvg..text..PositionedChunk$GT$::h7439e3348f527dc6",
    "core::ptr::drop_in_place$LT$rsvg..text..PositionedChunk$GT$::h7439e3348f527dc6",
  ),
  (
    "_ZN70_$LT$cranelift_codegen..binemit..Reloc$u20$as$u20$core..fmt..Debug$GT$3fmt17h2da0dfa052443432E",
    "_$LT$cranelift_codegen..binemit..Reloc$u20$as$u20$core..fmt..Debug$GT$::fmt::h2da0dfa052443432",
    "_$LT$cranelift_codegen..binemit..Reloc$u20$as$u20$core..fmt..Debug$GT$::fmt::h2da0dfa052443432",
  ),
  (
    "_ZNSt3__114numeric_limitsI10__gmp_exprIA1_12__mpz_structS3_EE12max_digits10E",
    "std::__1::numeric_limits<__gmp_expr<__mpz_struct [1], __mpz_struct [1]>>::max_digits10",
    "std::__1::numeric_limits<__gmp_expr<__mpz_struct [1], __mpz_struct [1]>>::max_digits10",
  ),
  (
    "_ZL23collectConstantAbsStepsRN4llvm15ScalarEvolutionEPKNS_4SCEVERNS_15SmallVectorImplIyEEy",
    "collectConstantAbsSteps(llvm::ScalarEvolution&, llvm::SCEV const*, llvm::SmallVectorImpl<unsigned long long>&, unsigned long long)",
    "collectConstantAbsSteps",
  ),
  (
    "_ZN2v88internal13GlobalHandles11RecordStatsEPNS0_9HeapStatsE", "v8::internal::GlobalHandles::RecordStats(v8::internal::HeapStats*)",
    "v8::internal::GlobalHandles::RecordStats",
  ),
  (
    "_ZN4mlir3gpu9BarrierOp15setInherentAttrERNS_15EmptyPropertiesEN4llvm9StringRefENS_9AttributeE",
    "mlir::gpu::BarrierOp::setInherentAttr(mlir::EmptyProperties&, llvm::StringRef, mlir::Attribute)",
    "mlir::gpu::BarrierOp::setInherentAttr",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_6linalg5LogOpEE15getInherentAttrEPNS_9OperationEN4llvm9StringRefE",
    "mlir::RegisteredOperationName::Model<mlir::linalg::LogOp>::getInherentAttr(mlir::Operation*, llvm::StringRef)",
    "mlir::RegisteredOperationName::Model<mlir::linalg::LogOp>::getInherentAttr",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_3ptr13MaskedStoreOpEE19getPropertiesAsAttrEPNS_9OperationE",
    "mlir::RegisteredOperationName::Model<mlir::ptr::MaskedStoreOp>::getPropertiesAsAttr(mlir::Operation*)",
    "mlir::RegisteredOperationName::Model<mlir::ptr::MaskedStoreOp>::getPropertiesAsAttr",
  ),
  (
    "_ZN4mlir5ROCDL11LoadToLDSOp5parseERNS_11OpAsmParserERNS_14OperationStateE",
    "mlir::ROCDL::LoadToLDSOp::parse(mlir::OpAsmParser&, mlir::OperationState&)",
    "mlir::ROCDL::LoadToLDSOp::parse",
  ),
  (
    "_ZN5clang8dataflow10AdornedCFG5buildERKNS_4DeclERNS_4StmtERNS_10ASTContextE",
    "clang::dataflow::AdornedCFG::build(clang::Decl const&, clang::Stmt&, clang::ASTContext&)",
    "clang::dataflow::AdornedCFG::build",
  ),
  (
    "_ZNK4LIEF5MachO6Binary11get_sectionERKNSt3__112basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEE",
    "LIEF::MachO::Binary::get_section(std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>> const&) const",
    "LIEF::MachO::Binary::get_section",
  ),
  (
    "_ZN2v88internal6maglev32StraightForwardRegisterAllocator5SpillEPNS1_9ValueNodeE",
    "v8::internal::maglev::StraightForwardRegisterAllocator::Spill(v8::internal::maglev::ValueNode*)",
    "v8::internal::maglev::StraightForwardRegisterAllocator::Spill",
  ),
  (
    "_ZN12lldb_private10ThreadPlan25ShouldRunBeforePublicStopEv", "lldb_private::ThreadPlan::ShouldRunBeforePublicStop()",
    "lldb_private::ThreadPlan::ShouldRunBeforePublicStop",
  ),
  (
    "_ZN4mlir9transform17MatchStructuredOp14readPropertiesERNS_21DialectBytecodeReaderERNS_14OperationStateE",
    "mlir::transform::MatchStructuredOp::readProperties(mlir::DialectBytecodeReader&, mlir::OperationState&)",
    "mlir::transform::MatchStructuredOp::readProperties",
  ),
  (
    "_ZN4llvm21AArch64TargetStreamer23emitARM64WinCFISaveRegPEji", "llvm::AArch64TargetStreamer::emitARM64WinCFISaveRegP(unsigned int, int)",
    "llvm::AArch64TargetStreamer::emitARM64WinCFISaveRegP",
  ),
  (
    "_ZN4mlir10presburger18PresburgerRelation17findIntegerSampleERN4llvm15SmallVectorImplINS2_12DynamicAPIntEEE",
    "mlir::presburger::PresburgerRelation::findIntegerSample(llvm::SmallVectorImpl<llvm::DynamicAPInt>&)",
    "mlir::presburger::PresburgerRelation::findIntegerSample",
  ),
  (
    "_ZN5clang13SanitizerKind9ShiftBaseE", "clang::SanitizerKind::ShiftBase", "clang::SanitizerKind::ShiftBase",
  ),
  (
    "_ZN4mlir5spirv12SDotAccSatOp14readPropertiesERNS_21DialectBytecodeReaderERNS_14OperationStateE",
    "mlir::spirv::SDotAccSatOp::readProperties(mlir::DialectBytecodeReader&, mlir::OperationState&)",
    "mlir::spirv::SDotAccSatOp::readProperties",
  ),
  (
    "_ZN4llvmL36CSR_Win_AAPCS_CFGuard_Check_SaveListE", "llvm::CSR_Win_AAPCS_CFGuard_Check_SaveList",
    "llvm::CSR_Win_AAPCS_CFGuard_Check_SaveList",
  ),
  (
    "_ZN4llvm10sampleprof32SampleProfileWriterExtBinaryBase24setToCompressAllSectionsEv",
    "llvm::sampleprof::SampleProfileWriterExtBinaryBase::setToCompressAllSections()",
    "llvm::sampleprof::SampleProfileWriterExtBinaryBase::setToCompressAllSections",
  ),
  (
    "_ZNK4lldb17SBSaveCoreOptions3refEv", "lldb::SBSaveCoreOptions::ref() const",
    "lldb::SBSaveCoreOptions::ref",
  ),
  (
    "_ZTIN4llvm6detail9PassModelINS_6ModuleENS_28StackSafetyGlobalPrinterPassENS_15AnalysisManagerIS2_JEEEJEEE",
    "typeinfo for llvm::detail::PassModel<llvm::Module, llvm::StackSafetyGlobalPrinterPass, llvm::AnalysisManager<llvm::Module>>",
    "typeinfo for llvm::detail::PassModel<llvm::Module, llvm::StackSafetyGlobalPrinterPass, llvm::AnalysisManager<llvm::Module>>",
  ),
  (
    "_ZN2v88internal8compiler22MachineOperatorBuilder12I16x8SubSatUEv", "v8::internal::compiler::MachineOperatorBuilder::I16x8SubSatU()",
    "v8::internal::compiler::MachineOperatorBuilder::I16x8SubSatU",
  ),
  (
    "_ZN4mlir5spirv6detail30QueryCapabilityInterfaceTraits5ModelINS0_24ImageSampleImplicitLodOpEED0Ev",
    "mlir::spirv::detail::QueryCapabilityInterfaceTraits::Model<mlir::spirv::ImageSampleImplicitLodOp>::~Model()",
    "mlir::spirv::detail::QueryCapabilityInterfaceTraits::Model<mlir::spirv::ImageSampleImplicitLodOp>::~Model",
  ),
  (
    "_ZTIN5clang12threadSafety14CapabilityExprE", "typeinfo for clang::threadSafety::CapabilityExpr",
    "typeinfo for clang::threadSafety::CapabilityExpr",
  ),
  (
    "_ZTVN2v88internal8compiler29SimplifiedOperatorGlobalCache37CheckedAdditiveSafeIntegerSubOperatorE",
    "vtable for v8::internal::compiler::SimplifiedOperatorGlobalCache::CheckedAdditiveSafeIntegerSubOperator",
    "vtable for v8::internal::compiler::SimplifiedOperatorGlobalCache::CheckedAdditiveSafeIntegerSubOperator",
  ),
  ("_ZL7invSbox", "invSbox", "invSbox"),
  (
    "_ZN2v88internal14MacroAssembler8SbxCheckENS0_9ConditionENS0_11AbortReasonE",
    "v8::internal::MacroAssembler::SbxCheck(v8::internal::Condition, v8::internal::AbortReason)",
    "v8::internal::MacroAssembler::SbxCheck",
  ),
  (
    "_ZN4llvm6AMDGPU6DepCtr17encodeFieldVaSsrcEjj", "llvm::AMDGPU::DepCtr::encodeFieldVaSsrc(unsigned int, unsigned int)",
    "llvm::AMDGPU::DepCtr::encodeFieldVaSsrc",
  ),
  (
    "_ZN12_GLOBAL__N_122MemorySanitizerVisitor25handleBinarySdSsIntrinsicERN4llvm13IntrinsicInstE",
    "(anonymous namespace)::MemorySanitizerVisitor::handleBinarySdSsIntrinsic(llvm::IntrinsicInst&)",
    "(anonymous namespace)::MemorySanitizerVisitor::handleBinarySdSsIntrinsic",
  ),
  (
    "_ZN4llvm12AArch64DBnXSL10DBnXSsListE", "llvm::AArch64DBnXS::DBnXSsList", "llvm::AArch64DBnXS::DBnXSsList",
  ),
  (
    "_ZN4llvm6AMDGPU6DepCtr17decodeFieldVaSsrcEj", "llvm::AMDGPU::DepCtr::decodeFieldVaSsrc(unsigned int)",
    "llvm::AMDGPU::DepCtr::decodeFieldVaSsrc",
  ),
  (
    "_ZN4llvm6AMDGPU6DepCtr17encodeFieldVaSsrcEjRKNS_15MCSubtargetInfoE", "llvm::AMDGPU::DepCtr::encodeFieldVaSsrc(unsigned int, llvm::MCSubtargetInfo const&)",
    "llvm::AMDGPU::DepCtr::encodeFieldVaSsrc",
  ),
  (
    "_ZN12_GLOBAL__N_122MemorySanitizerVisitor24handleUnarySdSsIntrinsicERN4llvm13IntrinsicInstE",
    "(anonymous namespace)::MemorySanitizerVisitor::handleUnarySdSsIntrinsic(llvm::IntrinsicInst&)",
    "(anonymous namespace)::MemorySanitizerVisitor::handleUnarySdSsIntrinsic",
  ),
  (
    "_ZN4llvm2mc13getX86Sse2AvxEv", "llvm::mc::getX86Sse2Avx()", "llvm::mc::getX86Sse2Avx",
  ),
  (
    "_ZN4mlir9transform36ApplySinkVectorProducerOpsPatternsOp20verifyInvariantsImplEv",
    "mlir::transform::ApplySinkVectorProducerOpsPatternsOp::verifyInvariantsImpl()",
    "mlir::transform::ApplySinkVectorProducerOpsPatternsOp::verifyInvariantsImpl",
  ),
  (
    "_ZN4llvm3orc12rt_bootstrap27SimpleExecutorMemoryManager8shutdownEv", "llvm::orc::rt_bootstrap::SimpleExecutorMemoryManager::shutdown()",
    "llvm::orc::rt_bootstrap::SimpleExecutorMemoryManager::shutdown",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4math5SinOpEE14copyPropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::math::SinOp>::copyProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::math::SinOp>::copyProperties",
  ),
  (
    "_ZN5clang6interp15ByteCodeEmitter14emitCMP3Sint64EPKNS_22ComparisonCategoryInfoENS0_10SourceInfoE",
    "clang::interp::ByteCodeEmitter::emitCMP3Sint64(clang::ComparisonCategoryInfo const*, clang::interp::SourceInfo)",
    "clang::interp::ByteCodeEmitter::emitCMP3Sint64",
  ),
  (
    "_ZN12wasm_encoder4core12instructions15InstructionSink15array_new_fixed17h78d2da7ec9882995E",
    "wasm_encoder::core::instructions::InstructionSink::array_new_fixed::h78d2da7ec9882995",
    "wasm_encoder::core::instructions::InstructionSink::array_new_fixed::h78d2da7ec9882995",
  ),
  (
    "_ZNK12_GLOBAL__N_125AANoAliasCallSiteReturned15trackStatisticsEv", "(anonymous namespace)::AANoAliasCallSiteReturned::trackStatistics() const",
    "(anonymous namespace)::AANoAliasCallSiteReturned::trackStatistics",
  ),
  (
    "_ZN4llvm16DebugHandlerBase15getBaseTypeSizeEPKNS_6DITypeE", "llvm::DebugHandlerBase::getBaseTypeSize(llvm::DIType const*)",
    "llvm::DebugHandlerBase::getBaseTypeSize",
  ),
  (
    "_ZTVN4mlir6linalg37DownscaleSizeOneWindowed2DConvolutionINS0_16PoolingNchwMaxOpENS0_15PoolingNcwMaxOpEEE",
    "vtable for mlir::linalg::DownscaleSizeOneWindowed2DConvolution<mlir::linalg::PoolingNchwMaxOp, mlir::linalg::PoolingNcwMaxOp>",
    "vtable for mlir::linalg::DownscaleSizeOneWindowed2DConvolution<mlir::linalg::PoolingNchwMaxOp, mlir::linalg::PoolingNcwMaxOp>",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_2cf8SwitchOpEE21getOpPropertyByteSizeEv",
    "mlir::RegisteredOperationName::Model<mlir::cf::SwitchOp>::getOpPropertyByteSize()",
    "mlir::RegisteredOperationName::Model<mlir::cf::SwitchOp>::getOpPropertyByteSize",
  ),
  (
    "_ZN12lldb_private11UnixSignals13AddSignalCodeEiiN4llvm13StringLiteralENS0_21SignalCodePrintOptionE",
    "lldb_private::UnixSignals::AddSignalCode(int, int, llvm::StringLiteral, lldb_private::UnixSignals::SignalCodePrintOption)",
    "lldb_private::UnixSignals::AddSignalCode",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4tosa7WhileOpEE21getOpPropertyByteSizeEv",
    "mlir::RegisteredOperationName::Model<mlir::tosa::WhileOp>::getOpPropertyByteSize()",
    "mlir::RegisteredOperationName::Model<mlir::tosa::WhileOp>::getOpPropertyByteSize",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_9transform16SplitReductionOpEE21getOpPropertyByteSizeEv",
    "mlir::RegisteredOperationName::Model<mlir::transform::SplitReductionOp>::getOpPropertyByteSize()",
    "mlir::RegisteredOperationName::Model<mlir::transform::SplitReductionOp>::getOpPropertyByteSize",
  ),
  (
    "_ZN3hwy11N_NEON_BF1612_GLOBAL__N_111SortF64DescEPdm", "hwy::N_NEON_BF16::(anonymous namespace)::SortF64Desc(double*, unsigned long)",
    "hwy::N_NEON_BF16::(anonymous namespace)::SortF64Desc",
  ),
  (
    "_ZN5clang4Sema24CreateLambdaCallOperatorENS_11SourceRangeEPNS_13CXXRecordDeclE",
    "clang::Sema::CreateLambdaCallOperator(clang::SourceRange, clang::CXXRecordDecl*)",
    "clang::Sema::CreateLambdaCallOperator",
  ),
  (
    "_ZN5clang16AlignNaturalAttr14CreateImplicitERNS_10ASTContextENS_11SourceRangeE",
    "clang::AlignNaturalAttr::CreateImplicit(clang::ASTContext&, clang::SourceRange)",
    "clang::AlignNaturalAttr::CreateImplicit",
  ),
  (
    "_ZN5clang6interp11EvalEmitter18emitShlUint8IntAPSENS0_10SourceInfoE", "clang::interp::EvalEmitter::emitShlUint8IntAPS(clang::interp::SourceInfo)",
    "clang::interp::EvalEmitter::emitShlUint8IntAPS",
  ),
  (
    "_ZNK12lldb_private31ClangExternalASTSourceCallbacks3isAEPKv", "lldb_private::ClangExternalASTSourceCallbacks::isA(void const*) const",
    "lldb_private::ClangExternalASTSourceCallbacks::isA",
  ),
  (
    "_ZN5clang6interp11EvalEmitter23emitStoreActivatePopPtrENS0_10SourceInfoE", "clang::interp::EvalEmitter::emitStoreActivatePopPtr(clang::interp::SourceInfo)",
    "clang::interp::EvalEmitter::emitStoreActivatePopPtr",
  ),
  (
    "_ZN5clang4Sema14ActOnAddrLabelENS_14SourceLocationES1_PNS_9LabelDeclE", "clang::Sema::ActOnAddrLabel(clang::SourceLocation, clang::SourceLocation, clang::LabelDecl*)",
    "clang::Sema::ActOnAddrLabel",
  ),
  (
    "_ZN5clang15ConstructorAttr6CreateERNS_10ASTContextEPNS_4ExprENS_11SourceRangeENS0_8SpellingE",
    "clang::ConstructorAttr::Create(clang::ASTContext&, clang::Expr*, clang::SourceRange, clang::ConstructorAttr::Spelling)",
    "clang::ConstructorAttr::Create",
  ),
  (
    "_ZL24compareCrossTUSourceLocsN5clang13FullSourceLocES0_", "compareCrossTUSourceLocs(clang::FullSourceLoc, clang::FullSourceLoc)",
    "compareCrossTUSourceLocs",
  ),
  (
    "_ZN5clang6interp11EvalEmitter21emitBitCastPrimSint32EbjPKN4llvm12fltSemanticsEPKNS_4TypeENS0_10SourceInfoE",
    "clang::interp::EvalEmitter::emitBitCastPrimSint32(bool, unsigned int, llvm::fltSemantics const*, clang::Type const*, clang::interp::SourceInfo)",
    "clang::interp::EvalEmitter::emitBitCastPrimSint32",
  ),
  (
    "_ZN3hwy6N_NEON14VQSelectStaticINS_6K32V32ENS_13SortAscendingEEEvPT_mmT0_", "void hwy::N_NEON::VQSelectStatic<hwy::K32V32, hwy::SortAscending>(hwy::K32V32*, unsigned long, unsigned long, hwy::SortAscending)",
    "hwy::N_NEON::VQSelectStatic<hwy::K32V32, hwy::SortAscending>",
  ),
  (
    "_ZN2v88internal16SourceTextModule13GetImportMetaEPNS0_7IsolateENS0_12DirectHandleIS1_EE",
    "v8::internal::SourceTextModule::GetImportMeta(v8::internal::Isolate*, v8::internal::DirectHandle<v8::internal::SourceTextModule>)",
    "v8::internal::SourceTextModule::GetImportMeta",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_8arm_neon8Sdot2dOpEE14copyPropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::arm_neon::Sdot2dOp>::copyProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::arm_neon::Sdot2dOp>::copyProperties",
  ),
  (
    "_ZN4mlir8arm_neon8Sdot2dOp15getInherentAttrEPNS_11MLIRContextERKNS_15EmptyPropertiesEN4llvm9StringRefE",
    "mlir::arm_neon::Sdot2dOp::getInherentAttr(mlir::MLIRContext*, mlir::EmptyProperties const&, llvm::StringRef)",
    "mlir::arm_neon::Sdot2dOp::getInherentAttr",
  ),
  (
    "_ZN4mlir7arm_sve10SdotIntrOp15setInherentAttrERNS_15EmptyPropertiesEN4llvm9StringRefENS_9AttributeE",
    "mlir::arm_sve::SdotIntrOp::setInherentAttr(mlir::EmptyProperties&, llvm::StringRef, mlir::Attribute)",
    "mlir::arm_sve::SdotIntrOp::setInherentAttr",
  ),
  (
    "_ZN4mlir8arm_neon8Sdot2dOp5buildERNS_9OpBuilderERNS_14OperationStateENS_4TypeENS_5ValueES7_S7_",
    "mlir::arm_neon::Sdot2dOp::build(mlir::OpBuilder&, mlir::OperationState&, mlir::Type, mlir::Value, mlir::Value, mlir::Value)",
    "mlir::arm_neon::Sdot2dOp::build",
  ),
  (
    "_ZN4mlir8arm_neon6SdotOp5printERNS_12OpAsmPrinterE", "mlir::arm_neon::SdotOp::print(mlir::OpAsmPrinter&)",
    "mlir::arm_neon::SdotOp::print",
  ),
  (
    "_ZN4mlir8arm_neon8Sdot2dOp5printERNS_12OpAsmPrinterE", "mlir::arm_neon::Sdot2dOp::print(mlir::OpAsmPrinter&)",
    "mlir::arm_neon::Sdot2dOp::print",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_8arm_neon8Sdot2dOpEE8hasTraitENS_6TypeIDE",
    "mlir::RegisteredOperationName::Model<mlir::arm_neon::Sdot2dOp>::hasTrait(mlir::TypeID)",
    "mlir::RegisteredOperationName::Model<mlir::arm_neon::Sdot2dOp>::hasTrait",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_8arm_neon6SdotOpEE21getOpPropertyByteSizeEv",
    "mlir::RegisteredOperationName::Model<mlir::arm_neon::SdotOp>::getOpPropertyByteSize()",
    "mlir::RegisteredOperationName::Model<mlir::arm_neon::SdotOp>::getOpPropertyByteSize",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_7arm_sve10SdotIntrOpEE14copyPropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::arm_sve::SdotIntrOp>::copyProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::arm_sve::SdotIntrOp>::copyProperties",
  ),
  (
    "_ZN4mlir7arm_sve10SdotIntrOp20verifyInvariantsImplEv", "mlir::arm_sve::SdotIntrOp::verifyInvariantsImpl()",
    "mlir::arm_sve::SdotIntrOp::verifyInvariantsImpl",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_8arm_neon6SdotOpEE17comparePropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::arm_neon::SdotOp>::compareProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::arm_neon::SdotOp>::compareProperties",
  ),
  (
    "_ZN4mlir8arm_neon6SdotOp21populateInherentAttrsEPNS_11MLIRContextERKNS_15EmptyPropertiesERNS_13NamedAttrListE",
    "mlir::arm_neon::SdotOp::populateInherentAttrs(mlir::MLIRContext*, mlir::EmptyProperties const&, mlir::NamedAttrList&)",
    "mlir::arm_neon::SdotOp::populateInherentAttrs",
  ),
  (
    "_ZNK12_GLOBAL__N_119SystemZDAGToDAGISel13selectAddressEN4llvm7SDValueERNS_21SystemZAddressingModeE",
    "(anonymous namespace)::SystemZDAGToDAGISel::selectAddress(llvm::SDValue, (anonymous namespace)::SystemZAddressingMode&) const",
    "(anonymous namespace)::SystemZDAGToDAGISel::selectAddress",
  ),
  (
    "_ZN12lldb_private13FuncUnwinders20GetEHFrameUnwindPlanERNS_6TargetE", "lldb_private::FuncUnwinders::GetEHFrameUnwindPlan(lldb_private::Target&)",
    "lldb_private::FuncUnwinders::GetEHFrameUnwindPlan",
  ),
  (
    "_ZN4mlir5emitc5MulOp6createERNS_9OpBuilderENS_8LocationENS_9TypeRangeENS_5ValueES6_",
    "mlir::emitc::MulOp::create(mlir::OpBuilder&, mlir::Location, mlir::TypeRange, mlir::Value, mlir::Value)",
    "mlir::emitc::MulOp::create",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_3pdl9ResultsOpEE17comparePropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::pdl::ResultsOp>::compareProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::pdl::ResultsOp>::compareProperties",
  ),
  (
    "_ZNK4llvm2cl6parserINS_11ScanOptionsEE14getDescriptionEj", "llvm::cl::parser<llvm::ScanOptions>::getDescription(unsigned int) const",
    "llvm::cl::parser<llvm::ScanOptions>::getDescription",
  ),
  (
    "_ZN5clang30DynamicRecursiveASTVisitorBaseILb1EE22WalkUpFromConstantExprEPKNS_12ConstantExprE",
    "clang::DynamicRecursiveASTVisitorBase<true>::WalkUpFromConstantExpr(clang::ConstantExpr const*)",
    "clang::DynamicRecursiveASTVisitorBase<true>::WalkUpFromConstantExpr",
  ),
  (
    "_ZN4lldb10SBListener26WaitForEventForBroadcasterEjRKNS_13SBBroadcasterERNS_7SBEventE",
    "lldb::SBListener::WaitForEventForBroadcaster(unsigned int, lldb::SBBroadcaster const&, lldb::SBEvent&)",
    "lldb::SBListener::WaitForEventForBroadcaster",
  ),
  (
    "_ZNK4llvm14TargetLowering15isIndexingLegalERNS_12MachineInstrENS_8RegisterES3_bRNS_19MachineRegisterInfoE",
    "llvm::TargetLowering::isIndexingLegal(llvm::MachineInstr&, llvm::Register, llvm::Register, bool, llvm::MachineRegisterInfo&) const",
    "llvm::TargetLowering::isIndexingLegal",
  ),
  (
    "_ZNK4llvm6detail9PassModelINS_6ModuleENS_23Annotation2MetadataPassENS_15AnalysisManagerIS2_JEEEJEE4nameEv",
    "llvm::detail::PassModel<llvm::Module, llvm::Annotation2MetadataPass, llvm::AnalysisManager<llvm::Module>>::name() const",
    "llvm::detail::PassModel<llvm::Module, llvm::Annotation2MetadataPass, llvm::AnalysisManager<llvm::Module>>::name",
  ),
  (
    "_ZN4llvm13AllAnalysesOnINS_4LoopEE2IDEv", "llvm::AllAnalysesOn<llvm::Loop>::ID()",
    "llvm::AllAnalysesOn<llvm::Loop>::ID",
  ),
  (
    "_ZNK3AAT17InsertionSubtableINS_13ExtendedTypesEE13is_actionableERKNS_5EntryINS2_9EntryDataEEE",
    "AAT::InsertionSubtable<AAT::ExtendedTypes>::is_actionable(AAT::Entry<AAT::InsertionSubtable<AAT::ExtendedTypes>::EntryData> const&) const",
    "AAT::InsertionSubtable<AAT::ExtendedTypes>::is_actionable",
  ),
  (
    "_ZN4mlir5ROCDL21mfma_f32_4x4x4bf16_1k6createERNS_20ImplicitLocOpBuilderENS_4TypeENS_10ValueRangeE",
    "mlir::ROCDL::mfma_f32_4x4x4bf16_1k::create(mlir::ImplicitLocOpBuilder&, mlir::Type, mlir::ValueRange)",
    "mlir::ROCDL::mfma_f32_4x4x4bf16_1k::create",
  ),
  (
    "_ZN4llvm8codeview17TypeRecordMapping16visitKnownMemberERNS0_14CVMemberRecordERNS0_16NestedTypeRecordE",
    "llvm::codeview::TypeRecordMapping::visitKnownMember(llvm::codeview::CVMemberRecord&, llvm::codeview::NestedTypeRecord&)",
    "llvm::codeview::TypeRecordMapping::visitKnownMember",
  ),
  (
    "_ZN12seq_rewriter9mk_str_leEP4exprS1_R7obj_refIS0_11ast_managerE", "seq_rewriter::mk_str_le(expr*, expr*, obj_ref<expr, ast_manager>&)",
    "seq_rewriter::mk_str_le",
  ),
  (
    "_ZN12v8_inspector31V8SerializationDuplicateTracker24FindKnownSerializedValueEN2v85LocalINS1_5ValueEEE",
    "v8_inspector::V8SerializationDuplicateTracker::FindKnownSerializedValue(v8::Local<v8::Value>)",
    "v8_inspector::V8SerializationDuplicateTracker::FindKnownSerializedValue",
  ),
  (
    "_ZL35_wrap_SBCommandInterpreter_IsActiveP7_objectS0_", "_wrap_SBCommandInterpreter_IsActive(_object*, _object*)",
    "_wrap_SBCommandInterpreter_IsActive",
  ),
  (
    "_ZN12_GLOBAL__N_114printNamedAttrERN4mlir12OpAsmPrinterENS0_14NamedAttributeE",
    "(anonymous namespace)::printNamedAttr(mlir::OpAsmPrinter&, mlir::NamedAttribute)",
    "(anonymous namespace)::printNamedAttr",
  ),
  (
    "_ZN2v88internal23SerializedHandleChecker17VisitRootPointersENS0_4RootEPKcNS0_14FullObjectSlotES5_",
    "v8::internal::SerializedHandleChecker::VisitRootPointers(v8::internal::Root, char const*, v8::internal::FullObjectSlot, v8::internal::FullObjectSlot)",
    "v8::internal::SerializedHandleChecker::VisitRootPointers",
  ),
  (
    "_ZN2v88Template10SetPrivateENS_5LocalINS_7PrivateEEENS1_INS_4DataEEENS_17PropertyAttributeE",
    "v8::Template::SetPrivate(v8::Local<v8::Private>, v8::Local<v8::Data>, v8::PropertyAttribute)",
    "v8::Template::SetPrivate",
  ),
  (
    "_ZN12_GLOBAL__N_122WebAssemblyCFGStackify16registerTryScopeEPN4llvm12MachineInstrES3_PNS1_17MachineBasicBlockE",
    "(anonymous namespace)::WebAssemblyCFGStackify::registerTryScope(llvm::MachineInstr*, llvm::MachineInstr*, llvm::MachineBasicBlock*)",
    "(anonymous namespace)::WebAssemblyCFGStackify::registerTryScope",
  ),
  (
    "_ZNK4llvm2cl3optIN4mlir20DefaultTimingManager12OutputFormatELb0ENS0_6parserIS4_EEE15printOptionInfoEm",
    "llvm::cl::opt<mlir::DefaultTimingManager::OutputFormat, false, llvm::cl::parser<mlir::DefaultTimingManager::OutputFormat>>::printOptionInfo(unsigned long) const",
    "llvm::cl::opt<mlir::DefaultTimingManager::OutputFormat, false, llvm::cl::parser<mlir::DefaultTimingManager::OutputFormat>>::printOptionInfo",
  ),
  (
    "_ZN2v88internal13UncheckedCastINS0_22JSIteratorFilterHelperENS0_6ObjectEEENS0_6TaggedIT_EENS4_IT0_EE",
    "v8::internal::Tagged<v8::internal::JSIteratorFilterHelper> v8::internal::UncheckedCast<v8::internal::JSIteratorFilterHelper, v8::internal::Object>(v8::internal::Tagged<v8::internal::Object>)",
    "v8::internal::UncheckedCast<v8::internal::JSIteratorFilterHelper, v8::internal::Object>",
  ),
  (
    "_ZN4mlir6linalg23vectorizeOpPreconditionEPNS_9OperationEN4llvm8ArrayRefIxEENS4_IbEEbb",
    "mlir::linalg::vectorizeOpPrecondition(mlir::Operation*, llvm::ArrayRef<long long>, llvm::ArrayRef<bool>, bool, bool)",
    "mlir::linalg::vectorizeOpPrecondition",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_3pdl9RewriteOpEE17comparePropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::pdl::RewriteOp>::compareProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::pdl::RewriteOp>::compareProperties",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_142SGPR_160_with_sub0_sub1_in_Gfx_CCR_SGPR_64E", "llvm::(anonymous namespace)::SGPR_160_with_sub0_sub1_in_Gfx_CCR_SGPR_64",
    "llvm::(anonymous namespace)::SGPR_160_with_sub0_sub1_in_Gfx_CCR_SGPR_64",
  ),
  (
    "_ZN12_GLOBAL__N_111X86FastISel20fastEmit_ISD_FSQRT_rEN4llvm3MVTES2_NS1_8RegisterE",
    "(anonymous namespace)::X86FastISel::fastEmit_ISD_FSQRT_r(llvm::MVT, llvm::MVT, llvm::Register)",
    "(anonymous namespace)::X86FastISel::fastEmit_ISD_FSQRT_r",
  ),
  (
    "_ZN4llvm6AMDGPU45SGPR_96_with_sub0_sub1_in_CCR_SGPR_64RegClassE", "llvm::AMDGPU::SGPR_96_with_sub0_sub1_in_CCR_SGPR_64RegClass",
    "llvm::AMDGPU::SGPR_96_with_sub0_sub1_in_CCR_SGPR_64RegClass",
  ),
  (
    "_ZN24RegisterContextPOSIX_x8619g_invalidate_st4_32E", "RegisterContextPOSIX_x86::g_invalidate_st4_32",
    "RegisterContextPOSIX_x86::g_invalidate_st4_32",
  ),
  (
    "_ZN11encoding_rs15ISO_8859_8_INIT17h17d19eecf104f87dE", "encoding_rs::ISO_8859_8_INIT::h17d19eecf104f87d",
    "encoding_rs::ISO_8859_8_INIT::h17d19eecf104f87d",
  ),
  (
    "_ZN32RegisterContextCorePOSIX_powerpc7ReadVMXEv", "RegisterContextCorePOSIX_powerpc::ReadVMX()",
    "RegisterContextCorePOSIX_powerpc::ReadVMX",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_140SGPR_512_with_sub14_sub15_in_CCR_SGPR_64E", "llvm::(anonymous namespace)::SGPR_512_with_sub14_sub15_in_CCR_SGPR_64",
    "llvm::(anonymous namespace)::SGPR_512_with_sub14_sub15_in_CCR_SGPR_64",
  ),
  (
    "_ZN12_GLOBAL__N_111ARMFastISel27fastEmit_ARMISD_VSHRsIMM_riEN4llvm3MVTES2_NS1_8RegisterEy",
    "(anonymous namespace)::ARMFastISel::fastEmit_ARMISD_VSHRsIMM_ri(llvm::MVT, llvm::MVT, llvm::Register, unsigned long long)",
    "(anonymous namespace)::ARMFastISel::fastEmit_ARMISD_VSHRsIMM_ri",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_17SGPR_32E", "llvm::(anonymous namespace)::SGPR_32", "llvm::(anonymous namespace)::SGPR_32",
  ),
  (
    "_ZN12_GLOBAL__N_114PipelineSolver17populateReadyListIPiEEvRN4llvm15SmallVectorImplINSt3__14pairIiiEEEET_SA_",
    "void (anonymous namespace)::PipelineSolver::populateReadyList<int*>(llvm::SmallVectorImpl<std::__1::pair<int, int>>&, int*, int*)",
    "(anonymous namespace)::PipelineSolver::populateReadyList<int*>",
  ),
  (
    "_ZTV36RegisterContextCorePOSIX_loongarch64", "vtable for RegisterContextCorePOSIX_loongarch64",
    "vtable for RegisterContextCorePOSIX_loongarch64",
  ),
  (
    "_ZN4llvm3X8629LOW32_ADDR_ACCESS_RBPRegClassE", "llvm::X86::LOW32_ADDR_ACCESS_RBPRegClass",
    "llvm::X86::LOW32_ADDR_ACCESS_RBPRegClass",
  ),
  (
    "_ZN4llvm15SmallVectorImplIPNS_13LazyCallGraph3SCCEEaSEOS4_", "llvm::SmallVectorImpl<llvm::LazyCallGraph::SCC*>::operator=(llvm::SmallVectorImpl<llvm::LazyCallGraph::SCC*>&&)",
    "llvm::SmallVectorImpl<llvm::LazyCallGraph::SCC*>::operator=",
  ),
  (
    "_ZN4llvm15SmallVectorImplINSt3__14pairIPNS_3mca9ReadStateEiEEEaSERKS7_", "llvm::SmallVectorImpl<std::__1::pair<llvm::mca::ReadState*, int>>::operator=(llvm::SmallVectorImpl<std::__1::pair<llvm::mca::ReadState*, int>> const&)",
    "llvm::SmallVectorImpl<std::__1::pair<llvm::mca::ReadState*, int>>::operator=",
  ),
  (
    "_ZTSN12_GLOBAL__N_111SDWAOperandE", "typeinfo name for (anonymous namespace)::SDWAOperand",
    "typeinfo name for (anonymous namespace)::SDWAOperand",
  ),
  (
    "_ZTSN12_GLOBAL__N_128AArch64IncomingValueAssignerE", "typeinfo name for (anonymous namespace)::AArch64IncomingValueAssigner",
    "typeinfo name for (anonymous namespace)::AArch64IncomingValueAssigner",
  ),
  (
    "_ZTSN12_GLOBAL__N_126CodeCompletionDeclConsumerE", "typeinfo name for (anonymous namespace)::CodeCompletionDeclConsumer",
    "typeinfo name for (anonymous namespace)::CodeCompletionDeclConsumer",
  ),
  (
    "_ZTSN12_GLOBAL__N_123MipsWinCOFFObjectWriterE", "typeinfo name for (anonymous namespace)::MipsWinCOFFObjectWriter",
    "typeinfo name for (anonymous namespace)::MipsWinCOFFObjectWriter",
  ),
  (
    "_ZTSN12_GLOBAL__N_124ParsedAttrInfoObjCDirectE", "typeinfo name for (anonymous namespace)::ParsedAttrInfoObjCDirect",
    "typeinfo name for (anonymous namespace)::ParsedAttrInfoObjCDirect",
  ),
  (
    "_ZTSN12_GLOBAL__N_122ScalingExtFOpConverterE", "typeinfo name for (anonymous namespace)::ScalingExtFOpConverter",
    "typeinfo name for (anonymous namespace)::ScalingExtFOpConverter",
  ),
  (
    "_ZN4llvm15SmallVectorImplIPNS_4xray7Profile8TrieNodeEEaSEOS5_", "llvm::SmallVectorImpl<llvm::xray::Profile::TrieNode*>::operator=(llvm::SmallVectorImpl<llvm::xray::Profile::TrieNode*>&&)",
    "llvm::SmallVectorImpl<llvm::xray::Profile::TrieNode*>::operator=",
  ),
  (
    "_ZN4llvm6CFGMSTIN12_GLOBAL__N_17PGOEdgeENS1_9PGOBBInfoEE20findAndCompressGroupEPS3_",
    "llvm::CFGMST<(anonymous namespace)::PGOEdge, (anonymous namespace)::PGOBBInfo>::findAndCompressGroup((anonymous namespace)::PGOBBInfo*)",
    "llvm::CFGMST<(anonymous namespace)::PGOEdge, (anonymous namespace)::PGOBBInfo>::findAndCompressGroup",
  ),
  (
    "_ZTSN12_GLOBAL__N_121ParsedAttrInfoNoMergeE", "typeinfo name for (anonymous namespace)::ParsedAttrInfoNoMerge",
    "typeinfo name for (anonymous namespace)::ParsedAttrInfoNoMerge",
  ),
  (
    "_ZTSN12_GLOBAL__N_116AArch64AsmParserE", "typeinfo name for (anonymous namespace)::AArch64AsmParser",
    "typeinfo name for (anonymous namespace)::AArch64AsmParser",
  ),
  (
    "_ZN2v88internalL27FLAGDEFAULT_perf_basic_profE", "v8::internal::FLAGDEFAULT_perf_basic_prof",
    "v8::internal::FLAGDEFAULT_perf_basic_prof",
  ),
  (
    "_ZN4llvm15VerifierSupport11CheckFailedIPNS_8CallInstEJPNS_5ValueEEEEvRKNS_5TwineERKT_DpRKT0_",
    "void llvm::VerifierSupport::CheckFailed<llvm::CallInst*, llvm::Value*>(llvm::Twine const&, llvm::CallInst* const&, llvm::Value* const&)",
    "llvm::VerifierSupport::CheckFailed<llvm::CallInst*, llvm::Value*>",
  ),
  (
    "_ZN2v88internalL43FLAGDEFAULT_max_valid_polymorphic_map_countE", "v8::internal::FLAGDEFAULT_max_valid_polymorphic_map_count",
    "v8::internal::FLAGDEFAULT_max_valid_polymorphic_map_count",
  ),
  (
    "_ZN2v88internal4wasm7Decoder6errorfIJhPKcjjEEEvjS5_DpT_", "void v8::internal::wasm::Decoder::errorf<unsigned char, char const*, unsigned int, unsigned int>(unsigned int, char const*, unsigned char, char const*, unsigned int, unsigned int)",
    "v8::internal::wasm::Decoder::errorf<unsigned char, char const*, unsigned int, unsigned int>",
  ),
  (
    "_Z18get_composite_hashIPN3euf7bindingENS0_15binding_khasherENS0_15binding_chasherEEjT_jRKT0_RKT1_",
    "unsigned int get_composite_hash<euf::binding*, euf::binding_khasher, euf::binding_chasher>(euf::binding*, unsigned int, euf::binding_khasher const&, euf::binding_chasher const&)",
    "get_composite_hash<euf::binding*, euf::binding_khasher, euf::binding_chasher>",
  ),
  (
    "_ZN4llvm2cl3optIbLb0ENS0_6parserIbEEEC2IJA14_cNS0_4descEEEEDpRKT_", "llvm::cl::opt<bool, false, llvm::cl::parser<bool>>::opt<char [14], llvm::cl::desc>(char const (&) [14], llvm::cl::desc const&)",
    "llvm::cl::opt<bool, false, llvm::cl::parser<bool>>::opt<char [14], llvm::cl::desc>",
  ),
  (
    "_ZN4llvm23SmallVectorTemplateBaseINS_7NodeSetELb0EE18uninitialized_moveIPS1_S4_EEvT_S5_T0_",
    "void llvm::SmallVectorTemplateBase<llvm::NodeSet, false>::uninitialized_move<llvm::NodeSet*, llvm::NodeSet*>(llvm::NodeSet*, llvm::NodeSet*, llvm::NodeSet*)",
    "llvm::SmallVectorTemplateBase<llvm::NodeSet, false>::uninitialized_move<llvm::NodeSet*, llvm::NodeSet*>",
  ),
  (
    "_ZN4mlir10AsmPrinter19printFunctionalTypeINS_9TypeRangeES2_EEvOT_OT0_", "void mlir::AsmPrinter::printFunctionalType<mlir::TypeRange, mlir::TypeRange>(mlir::TypeRange&&, mlir::TypeRange&&)",
    "mlir::AsmPrinter::printFunctionalType<mlir::TypeRange, mlir::TypeRange>",
  ),
  (
    "_ZN2v88internal13UncheckedCastINS0_17TrustedFixedArrayENS0_6ObjectEEENS0_6TaggedIT_EENS4_IT0_EE",
    "v8::internal::Tagged<v8::internal::TrustedFixedArray> v8::internal::UncheckedCast<v8::internal::TrustedFixedArray, v8::internal::Object>(v8::internal::Tagged<v8::internal::Object>)",
    "v8::internal::UncheckedCast<v8::internal::TrustedFixedArray, v8::internal::Object>",
  ),
  (
    "_ZN5clanglsIPKNS_9OwnerAttrEEERKNS_8SemaBase21SemaDiagnosticBuilderES7_RKT_",
    "clang::SemaBase::SemaDiagnosticBuilder const& clang::operator<<<clang::OwnerAttr const*>(clang::SemaBase::SemaDiagnosticBuilder const&, clang::OwnerAttr const* const&)",
    "clang::operator<<<clang::OwnerAttr const*>",
  ),
  (
    "_ZN2v88internal4Zone3NewINS0_6maglev16KnownNodeAspectsEJPS1_EEEPT_DpOT0_", "v8::internal::maglev::KnownNodeAspects* v8::internal::Zone::New<v8::internal::maglev::KnownNodeAspects, v8::internal::Zone*>(v8::internal::Zone*&&)",
    "v8::internal::Zone::New<v8::internal::maglev::KnownNodeAspects, v8::internal::Zone*>",
  ),
  (
    "_ZN4node6CallocI16uvwasi_preopen_sEEPT_m", "uvwasi_preopen_s* node::Calloc<uvwasi_preopen_s>(unsigned long)",
    "node::Calloc<uvwasi_preopen_s>",
  ),
  (
    "_ZN4llvm10make_errorINS_6object18GenericBinaryErrorEJRA28_KcNS1_12object_errorEEEENS_5ErrorEDpOT0_",
    "llvm::Error llvm::make_error<llvm::object::GenericBinaryError, char const (&) [28], llvm::object::object_error>(char const (&) [28], llvm::object::object_error&&)",
    "llvm::make_error<llvm::object::GenericBinaryError, char const (&) [28], llvm::object::object_error>",
  ),
  (
    "_ZN3hwy11N_NEON_BF1612VQSortStaticIsNS_14SortDescendingEEEvPT_mT0_", "void hwy::N_NEON_BF16::VQSortStatic<short, hwy::SortDescending>(short*, unsigned long, hwy::SortDescending)",
    "hwy::N_NEON_BF16::VQSortStatic<short, hwy::SortDescending>",
  ),
  (
    "_ZN2v88internal4Flag8SetValueILNS1_8FlagTypeE4EyEEvT0_NS1_5SetByE.cold.1", "void v8::internal::Flag::SetValue<(v8::internal::Flag::FlagType)4, unsigned long long>(unsigned long long, v8::internal::Flag::SetBy) (.cold.1)",
    "v8::internal::Flag::SetValue<(v8::internal::Flag::FlagType)4, unsigned long long>",
  ),
  (
    "_ZN3fmt3v126detail5writeIcNS0_14basic_appenderIcEEEET0_S5_T_", "fmt::v12::basic_appender<char> fmt::v12::detail::write<char, fmt::v12::basic_appender<char>>(fmt::v12::basic_appender<char>, char)",
    "fmt::v12::detail::write<char, fmt::v12::basic_appender<char>>",
  ),
  (
    "_ZN4llvm4yaml2IO10processKeyINS_11SmallVectorINS0_5Hex32ELj12EEENS0_12EmptyContextEEEvNS_9StringRefERT_bRT0_",
    "void llvm::yaml::IO::processKey<llvm::SmallVector<llvm::yaml::Hex32, 12u>, llvm::yaml::EmptyContext>(llvm::StringRef, llvm::SmallVector<llvm::yaml::Hex32, 12u>&, bool, llvm::yaml::EmptyContext&)",
    "llvm::yaml::IO::processKey<llvm::SmallVector<llvm::yaml::Hex32, 12u>, llvm::yaml::EmptyContext>",
  ),
  (
    "_ZN2v88internal9CopyCharsIttEEvPT0_PKT_m", "void v8::internal::CopyChars<unsigned short, unsigned short>(unsigned short*, unsigned short const*, unsigned long)",
    "v8::internal::CopyChars<unsigned short, unsigned short>",
  ),
  (
    "_ZNK2OT12ChainContext8dispatchINS_23hb_intersects_context_tEJEEENT_8return_tEPS3_DpOT0_",
    "OT::hb_intersects_context_t::return_t OT::ChainContext::dispatch<OT::hb_intersects_context_t>(OT::hb_intersects_context_t*) const",
    "OT::ChainContext::dispatch<OT::hb_intersects_context_t>",
  ),
  (
    "_ZNSt3__16vectorIN3jxl13QuantEncodingENS_9allocatorIS2_EEE18__assign_with_sizeB8nn190102IPS2_S7_EEvT_T0_l",
    "void std::__1::vector<jxl::QuantEncoding, std::__1::allocator<jxl::QuantEncoding>>::__assign_with_size[abi:nn190102]<jxl::QuantEncoding*, jxl::QuantEncoding*>(jxl::QuantEncoding*, jxl::QuantEncoding*, long)",
    "std::__1::vector<jxl::QuantEncoding, std::__1::allocator<jxl::QuantEncoding>>::__assign_with_size[abi:nn190102]<jxl::QuantEncoding*, jxl::QuantEncoding*>",
  ),
  (
    "_ZN4llvm10make_errorINS_3pdb8RawErrorEJNS1_14raw_error_codeERA36_KcEEENS_5ErrorEDpOT0_",
    "llvm::Error llvm::make_error<llvm::pdb::RawError, llvm::pdb::raw_error_code, char const (&) [36]>(llvm::pdb::raw_error_code&&, char const (&) [36])",
    "llvm::make_error<llvm::pdb::RawError, llvm::pdb::raw_error_code, char const (&) [36]>",
  ),
  (
    "_ZN2v88internal13UncheckedCastINS0_10WasmStructENS0_6ObjectEEENS0_6TaggedIT_EENS4_IT0_EE",
    "v8::internal::Tagged<v8::internal::WasmStruct> v8::internal::UncheckedCast<v8::internal::WasmStruct, v8::internal::Object>(v8::internal::Tagged<v8::internal::Object>)",
    "v8::internal::UncheckedCast<v8::internal::WasmStruct, v8::internal::Object>",
  ),
  (
    "_ZNKSt3__16__lessIvvEclB9nqn210106IN4llvm9StringRefES4_EEbRKT_RKT0_", "bool std::__1::__less<void, void>::operator()[abi:nqn210106]<llvm::StringRef, llvm::StringRef>(llvm::StringRef const&, llvm::StringRef const&) const",
    "std::__1::__less<void, void>::operator()[abi:nqn210106]<llvm::StringRef, llvm::StringRef>",
  ),
  (
    "_ZN4llvm10make_errorINS_6object18GenericBinaryErrorEJRA39_KcNS1_12object_errorEEEENS_5ErrorEDpOT0_",
    "llvm::Error llvm::make_error<llvm::object::GenericBinaryError, char const (&) [39], llvm::object::object_error>(char const (&) [39], llvm::object::object_error&&)",
    "llvm::make_error<llvm::object::GenericBinaryError, char const (&) [39], llvm::object::object_error>",
  ),
  (
    "_ZN2OTL14match_coverageER15hb_glyph_info_tjPKv", "OT::match_coverage(hb_glyph_info_t&, unsigned int, void const*)",
    "OT::match_coverage",
  ),
  (
    "_ZN2OTL28hb_transforming_pen_cubic_toEP15hb_draw_funcs_tPvP15hb_draw_state_tffffffS2_",
    "OT::hb_transforming_pen_cubic_to(hb_draw_funcs_t*, void*, hb_draw_state_t*, float, float, float, float, float, float, void*)",
    "OT::hb_transforming_pen_cubic_to",
  ),
  (
    "_ZN2OTL19match_class_cached2ER15hb_glyph_info_tjPKv", "OT::match_class_cached2(hb_glyph_info_t&, unsigned int, void const*)",
    "OT::match_class_cached2",
  ),
  (
    "_ZN2OTL17intersected_glyphEPK8hb_set_tPKvjPS0_Pv", "OT::intersected_glyph(hb_set_t const*, void const*, unsigned int, hb_set_t*, void*)",
    "OT::intersected_glyph",
  ),
  (
    "_ZN2OTL24intersected_class_glyphsEPK8hb_set_tPKvjPS0_Pv", "OT::intersected_class_glyphs(hb_set_t const*, void const*, unsigned int, hb_set_t*, void*)",
    "OT::intersected_class_glyphs",
  ),
  (
    "_ZN2OTL12apply_lookupEPNS_21hb_ot_apply_context_tEjjPKNS_12LookupRecordEj",
    "OT::apply_lookup(OT::hb_ot_apply_context_t*, unsigned int, unsigned int, OT::LookupRecord const*, unsigned int)",
    "OT::apply_lookup",
  ),
  (
    "_ZN2OTL28serialize_lookuprecord_arrayEP22hb_serialize_context_t10hb_array_tIKNS_12LookupRecordEEPK8hb_map_t",
    "OT::serialize_lookuprecord_array(hb_serialize_context_t*, hb_array_t<OT::LookupRecord const>, hb_map_t const*)",
    "OT::serialize_lookuprecord_array",
  ),
  (
    "_ZN2OTL30hb_transforming_pen_close_pathEP15hb_draw_funcs_tPvP15hb_draw_state_tS2_",
    "OT::hb_transforming_pen_close_path(hb_draw_funcs_t*, void*, hb_draw_state_t*, void*)",
    "OT::hb_transforming_pen_close_path",
  ),
  (
    "_ZN2OTL21_hb_ot_name_entry_cmpEPKvS1_", "OT::_hb_ot_name_entry_cmp(void const*, void const*)",
    "OT::_hb_ot_name_entry_cmp",
  ),
  (
    "_ZN2OTL32hb_transforming_pen_quadratic_toEP15hb_draw_funcs_tPvP15hb_draw_state_tffffS2_",
    "OT::hb_transforming_pen_quadratic_to(hb_draw_funcs_t*, void*, hb_draw_state_t*, float, float, float, float, void*)",
    "OT::hb_transforming_pen_quadratic_to",
  ),
  (
    "_ZN2OTL22_hb_os2_unicode_rangesE", "OT::_hb_os2_unicode_ranges", "OT::_hb_os2_unicode_ranges",
  ),
  (
    "_ZN2OTL27intersected_coverage_glyphsEPK8hb_set_tPKvjPS0_Pv", "OT::intersected_coverage_glyphs(hb_set_t const*, void const*, unsigned int, hb_set_t*, void*)",
    "OT::intersected_coverage_glyphs",
  ),
  (
    "_ZN4mlir4LLVM6detail24CallOpGenericAdaptorBase27getODSOperandIndexAndLengthEjj",
    "mlir::LLVM::detail::CallOpGenericAdaptorBase::getODSOperandIndexAndLength(unsigned int, unsigned int)",
    "mlir::LLVM::detail::CallOpGenericAdaptorBase::getODSOperandIndexAndLength",
  ),
  (
    "_ZN4mlir4NVVM19WgmmaFenceAlignedOp5buildERNS_9OpBuilderERNS_14OperationStateENS_9TypeRangeE",
    "mlir::NVVM::WgmmaFenceAlignedOp::build(mlir::OpBuilder&, mlir::OperationState&, mlir::TypeRange)",
    "mlir::NVVM::WgmmaFenceAlignedOp::build",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4LLVM15InsertElementOpEE16deletePropertiesENS_16OpaquePropertiesE",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::InsertElementOp>::deleteProperties(mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::InsertElementOp>::deleteProperties",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4NVVM9EnvReg6OpEE14hashPropertiesENS_16OpaquePropertiesE",
    "mlir::RegisteredOperationName::Model<mlir::NVVM::EnvReg6Op>::hashProperties(mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::NVVM::EnvReg6Op>::hashProperties",
  ),
  (
    "_ZN12_GLOBAL__N_115FComparePatternIN4mlir5spirv19FUnordGreaterThanOpELNS1_4LLVM13FCmpPredicateE9EED0Ev",
    "(anonymous namespace)::FComparePattern<mlir::spirv::FUnordGreaterThanOp, (mlir::LLVM::FCmpPredicate)9>::~FComparePattern()",
    "(anonymous namespace)::FComparePattern<mlir::spirv::FUnordGreaterThanOp, (mlir::LLVM::FCmpPredicate)9>::~FComparePattern",
  ),
  (
    "_ZTVN4mlir23RegisteredOperationName5ModelINS_4LLVM6FshlOpEEE", "vtable for mlir::RegisteredOperationName::Model<mlir::LLVM::FshlOp>",
    "vtable for mlir::RegisteredOperationName::Model<mlir::LLVM::FshlOp>",
  ),
  (
    "_ZN4mlir4LLVM16MatrixMultiplyOp5printERNS_12OpAsmPrinterE", "mlir::LLVM::MatrixMultiplyOp::print(mlir::OpAsmPrinter&)",
    "mlir::LLVM::MatrixMultiplyOp::print",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4LLVM6URemOpEED0Ev", "mlir::RegisteredOperationName::Model<mlir::LLVM::URemOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::URemOp>::~Model",
  ),
  (
    "_ZN4mlir4LLVM6detail34ExtractElementOpGenericAdaptorBaseC2ENS0_16ExtractElementOpE",
    "mlir::LLVM::detail::ExtractElementOpGenericAdaptorBase::ExtractElementOpGenericAdaptorBase(mlir::LLVM::ExtractElementOp)",
    "mlir::LLVM::detail::ExtractElementOpGenericAdaptorBase::ExtractElementOpGenericAdaptorBase",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4LLVM10ByteSwapOpEE17comparePropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::ByteSwapOp>::compareProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::ByteSwapOp>::compareProperties",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4NVVM8LaneIdOpEE17comparePropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::NVVM::LaneIdOp>::compareProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::NVVM::LaneIdOp>::compareProperties",
  ),
  (
    "_ZN4mlir4NVVM10BlockIdZOp5buildERNS_9OpBuilderERNS_14OperationStateENS_9TypeRangeENS_4LLVM17ConstantRangeAttrE",
    "mlir::NVVM::BlockIdZOp::build(mlir::OpBuilder&, mlir::OperationState&, mlir::TypeRange, mlir::LLVM::ConstantRangeAttr)",
    "mlir::NVVM::BlockIdZOp::build",
  ),
  (
    "_ZTVNSt3__110__function6__funcIMN4llvm4json6ObjectEKFNS_8optionalINS2_9StringRefEEES6_EFS7_PKS4_S6_EEE",
    "vtable for std::__1::__function::__func<std::__1::optional<llvm::StringRef> (llvm::json::Object::*)(llvm::StringRef) const, std::__1::optional<llvm::StringRef> (llvm::json::Object const*, llvm::StringRef)>",
    "vtable for std::__1::__function::__func<std::__1::optional<llvm::StringRef> (llvm::json::Object::*)(llvm::StringRef) const, std::__1::optional<llvm::StringRef> (llvm::json::Object const*, llvm::StringRef)>",
  ),
  (
    "_ZL22lowerFMAXIMUM_FMINIMUMN4llvm7SDValueERNS_12SelectionDAGERKNS_14RISCVSubtargetE",
    "lowerFMAXIMUM_FMINIMUM(llvm::SDValue, llvm::SelectionDAG&, llvm::RISCVSubtarget const&)",
    "lowerFMAXIMUM_FMINIMUM",
  ),
  (
    "_ZNK4llvm14TargetLowering29expandFMINIMUMNUM_FMAXIMUMNUMEPNS_6SDNodeERNS_12SelectionDAGE",
    "llvm::TargetLowering::expandFMINIMUMNUM_FMAXIMUMNUM(llvm::SDNode*, llvm::SelectionDAG&) const",
    "llvm::TargetLowering::expandFMINIMUMNUM_FMAXIMUMNUM",
  ),
  (
    "_ZL20getOtherMessageSentMN5clang12ast_matchers8internal7MatcherINS_4StmtEEE",
    "getOtherMessageSentM(clang::ast_matchers::internal::Matcher<clang::Stmt>)",
    "getOtherMessageSentM",
  ),
  (
    "_ZL26convertMLIRAttributeToLLVMN4mlir8LocationERN4llvm11LLVMContextENS1_9StringRefES4_",
    "convertMLIRAttributeToLLVM(mlir::Location, llvm::LLVMContext&, llvm::StringRef, llvm::StringRef)",
    "convertMLIRAttributeToLLVM",
  ),
  (
    "_ZL12prepareTS1AMN4llvm7SDValueERNS_12SelectionDAGERS0_S3_", "prepareTS1AM(llvm::SDValue, llvm::SelectionDAG&, llvm::SDValue&, llvm::SDValue&)",
    "prepareTS1AM",
  ),
  (
    "_ZN4llvmL22ZZZ_VMNoV0SuperclassesE", "llvm::ZZZ_VMNoV0Superclasses", "llvm::ZZZ_VMNoV0Superclasses",
  ),
  (
    "_ZTSMN12_GLOBAL__N_113StreamCheckerEKFvPKNS_13FnDescriptionERKN5clang4ento9CallEventERNS5_14CheckerContextEE",
    "typeinfo name for void ((anonymous namespace)::StreamChecker::*)((anonymous namespace)::FnDescription const*, clang::ento::CallEvent const&, clang::ento::CheckerContext&) const",
    "typeinfo name for void ((anonymous namespace)::StreamChecker::*)((anonymous namespace)::FnDescription const*, clang::ento::CallEvent const&, clang::ento::CheckerContext&) const",
  ),
  (
    "_ZL14getRunLoopRunMN5clang12ast_matchers8internal7MatcherINS_4StmtEEE", "getRunLoopRunM(clang::ast_matchers::internal::Matcher<clang::Stmt>)",
    "getRunLoopRunM",
  ),
  ("_ZN4llvm8ARMNamesE", "llvm::ARMNames", "llvm::ARMNames"),
  (
    "_ZTIMN4llvm4json6ObjectEKFNSt3__18optionalIxEENS_9StringRefEE", "typeinfo for std::__1::optional<long long> (llvm::json::Object::*)(llvm::StringRef) const",
    "typeinfo for std::__1::optional<long long> (llvm::json::Object::*)(llvm::StringRef) const",
  ),
  (
    "_ZNSt3__16vectorIMN4llvm11logicalview9LVElementEKFbvENS_9allocatorIS5_EEE20__throw_length_errorB9nqn210106Ev",
    "std::__1::vector<bool (llvm::logicalview::LVElement::*)() const, std::__1::allocator<bool (llvm::logicalview::LVElement::*)() const>>::__throw_length_error[abi:nqn210106]()",
    "std::__1::vector<bool (llvm::logicalview::LVElement::*)() const, std::__1::allocator<bool (llvm::logicalview::LVElement::*)() const>>::__throw_length_error[abi:nqn210106]",
  ),
  (
    "_ZN4llvm2cl3optIbLb0ENS0_6parserIbEEEC2IJA28_cNS0_4descENS0_12OptionHiddenEEEEDpRKT_",
    "llvm::cl::opt<bool, false, llvm::cl::parser<bool>>::opt<char [28], llvm::cl::desc, llvm::cl::OptionHidden>(char const (&) [28], llvm::cl::desc const&, llvm::cl::OptionHidden const&)",
    "llvm::cl::opt<bool, false, llvm::cl::parser<bool>>::opt<char [28], llvm::cl::desc, llvm::cl::OptionHidden>",
  ),
  (
    "_ZN5clanglsIA56_cEERKNS_8SemaBase21SemaDiagnosticBuilderES5_RKT_", "clang::SemaBase::SemaDiagnosticBuilder const& clang::operator<<<char [56]>(clang::SemaBase::SemaDiagnosticBuilder const&, char const (&) [56])",
    "clang::operator<<<char [56]>",
  ),
  (
    "_ZN4llvm7support6detail23provider_format_adapterIRA11_KcED0Ev", "llvm::support::detail::provider_format_adapter<char const (&) [11]>::~provider_format_adapter()",
    "llvm::support::detail::provider_format_adapter<char const (&) [11]>::~provider_format_adapter",
  ),
  (
    "_ZTSN4llvm7support6detail23provider_format_adapterIRA6_KcEE", "typeinfo name for llvm::support::detail::provider_format_adapter<char const (&) [6]>",
    "typeinfo name for llvm::support::detail::provider_format_adapter<char const (&) [6]>",
  ),
  (
    "_ZNSt3__114numeric_limitsI10__gmp_exprIA1_12__mpf_structS3_EE12max_exponentE",
    "std::__1::numeric_limits<__gmp_expr<__mpf_struct [1], __mpf_struct [1]>>::max_exponent",
    "std::__1::numeric_limits<__gmp_expr<__mpf_struct [1], __mpf_struct [1]>>::max_exponent",
  ),
  (
    "_ZN4llvm7support6detail23provider_format_adapterIRA88_KcED1Ev", "llvm::support::detail::provider_format_adapter<char const (&) [88]>::~provider_format_adapter()",
    "llvm::support::detail::provider_format_adapter<char const (&) [88]>::~provider_format_adapter",
  ),
  (
    "_ZN4llvm7support6detail23provider_format_adapterIRA22_KcED1Ev", "llvm::support::detail::provider_format_adapter<char const (&) [22]>::~provider_format_adapter()",
    "llvm::support::detail::provider_format_adapter<char const (&) [22]>::~provider_format_adapter",
  ),
  (
    "_ZN4llvm10make_errorINS_8codeview13CodeViewErrorEJNS1_13cv_error_codeERA96_KcEEENS_5ErrorEDpOT0_",
    "llvm::Error llvm::make_error<llvm::codeview::CodeViewError, llvm::codeview::cv_error_code, char const (&) [96]>(llvm::codeview::cv_error_code&&, char const (&) [96])",
    "llvm::make_error<llvm::codeview::CodeViewError, llvm::codeview::cv_error_code, char const (&) [96]>",
  ),
  (
    "_ZN4llvm2cl3optIbLb0ENS0_6parserIbEEEC2IJA7_cNS0_12OptionHiddenENS0_11initializerIbEEEEEDpRKT_",
    "llvm::cl::opt<bool, false, llvm::cl::parser<bool>>::opt<char [7], llvm::cl::OptionHidden, llvm::cl::initializer<bool>>(char const (&) [7], llvm::cl::OptionHidden const&, llvm::cl::initializer<bool> const&)",
    "llvm::cl::opt<bool, false, llvm::cl::parser<bool>>::opt<char [7], llvm::cl::OptionHidden, llvm::cl::initializer<bool>>",
  ),
  (
    "_ZN4llvm10make_errorINS_7jitlink12JITLinkErrorEJRA72_KcEEENS_5ErrorEDpOT0_",
    "llvm::Error llvm::make_error<llvm::jitlink::JITLinkError, char const (&) [72]>(char const (&) [72])",
    "llvm::make_error<llvm::jitlink::JITLinkError, char const (&) [72]>",
  ),
  (
    "_ZN4llvm7support6detail23provider_format_adapterIRA18_KcED0Ev", "llvm::support::detail::provider_format_adapter<char const (&) [18]>::~provider_format_adapter()",
    "llvm::support::detail::provider_format_adapter<char const (&) [18]>::~provider_format_adapter",
  ),
  (
    "_ZN4llvm7support6detail23provider_format_adapterIRA22_KcED0Ev", "llvm::support::detail::provider_format_adapter<char const (&) [22]>::~provider_format_adapter()",
    "llvm::support::detail::provider_format_adapter<char const (&) [22]>::~provider_format_adapter",
  ),
  (
    "_ZN12_GLOBAL__N_18Verifier16visitDIBasicTypeERKN4llvm11DIBasicTypeE", "(anonymous namespace)::Verifier::visitDIBasicType(llvm::DIBasicType const&)",
    "(anonymous namespace)::Verifier::visitDIBasicType",
  ),
  (
    "_ZN12_GLOBAL__N_125RISCVPreLegalizerCombiner20runOnMachineFunctionERN4llvm15MachineFunctionE",
    "(anonymous namespace)::RISCVPreLegalizerCombiner::runOnMachineFunction(llvm::MachineFunction&)",
    "(anonymous namespace)::RISCVPreLegalizerCombiner::runOnMachineFunction",
  ),
  (
    "_ZNK4mlir4impl23GpuNVVMAttachTargetBaseIN12_GLOBAL__N_116NVVMAttachTargetEE7getNameEv",
    "mlir::impl::GpuNVVMAttachTargetBase<(anonymous namespace)::NVVMAttachTarget>::getName() const",
    "mlir::impl::GpuNVVMAttachTargetBase<(anonymous namespace)::NVVMAttachTarget>::getName",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_166ZPR4_with_dsub1_in_FPR64_lo_and_ZPR4_with_qsub3_in_FPR128_0to7BitsE",
    "llvm::(anonymous namespace)::ZPR4_with_dsub1_in_FPR64_lo_and_ZPR4_with_qsub3_in_FPR128_0to7Bits",
    "llvm::(anonymous namespace)::ZPR4_with_dsub1_in_FPR64_lo_and_ZPR4_with_qsub3_in_FPR128_0to7Bits",
  ),
  (
    "_ZN7simdutf5arm6412_GLOBAL__N_128convert_masked_utf8_to_utf32EPKcyRPDi", "simdutf::arm64::(anonymous namespace)::convert_masked_utf8_to_utf32(char const*, unsigned long long, char32_t*&)",
    "simdutf::arm64::(anonymous namespace)::convert_masked_utf8_to_utf32",
  ),
  (
    "_ZN2v88internal14LoopChoiceNode16AsLoopChoiceNodeEv", "v8::internal::LoopChoiceNode::AsLoopChoiceNode()",
    "v8::internal::LoopChoiceNode::AsLoopChoiceNode",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_179AV_384_with_sub0_in_VGPR_32_Lo256_and_AV_384_with_sub1_sub2_in_AV_64_Align2BitsE",
    "llvm::(anonymous namespace)::AV_384_with_sub0_in_VGPR_32_Lo256_and_AV_384_with_sub1_sub2_in_AV_64_Align2Bits",
    "llvm::(anonymous namespace)::AV_384_with_sub0_in_VGPR_32_Lo256_and_AV_384_with_sub1_sub2_in_AV_64_Align2Bits",
  ),
  (
    "_ZN4llvmL87AV_256_with_hi16_in_VGPR_16_Lo128_and_AV_256_with_sub1_sub2_in_AV_64_Align2SubClassMaskE",
    "llvm::AV_256_with_hi16_in_VGPR_16_Lo128_and_AV_256_with_sub1_sub2_in_AV_64_Align2SubClassMask",
    "llvm::AV_256_with_hi16_in_VGPR_16_Lo128_and_AV_256_with_sub1_sub2_in_AV_64_Align2SubClassMask",
  ),
  (
    "_ZN4llvm3X8613isVFMADD213SSEj", "llvm::X86::isVFMADD213SS(unsigned int)", "llvm::X86::isVFMADD213SS",
  ),
  (
    "_Z21_As_JSWrappedFunctionm", "_As_JSWrappedFunction(unsigned long)", "_As_JSWrappedFunction",
  ),
  (
    "_ZN12_GLOBAL__N_125rel_goal_case_split_queue13end_search_ehEv", "(anonymous namespace)::rel_goal_case_split_queue::end_search_eh()",
    "(anonymous namespace)::rel_goal_case_split_queue::end_search_eh",
  ),
  (
    "_ZN4llvm21MipsTargetAsmStreamer24emitDirectiveSetMips64R3Ev", "llvm::MipsTargetAsmStreamer::emitDirectiveSetMips64R3()",
    "llvm::MipsTargetAsmStreamer::emitDirectiveSetMips64R3",
  ),
  (
    "_ZNK4LIEF5MachO16SegmentSplitInfo5cloneEv", "LIEF::MachO::SegmentSplitInfo::clone() const",
    "LIEF::MachO::SegmentSplitInfo::clone",
  ),
  ("_Z7mapUTF8jPci", "mapUTF8(unsigned int, char*, int)", "mapUTF8"),
  (
    "_ZNK4llvm8Constant10isNormalFPEv", "llvm::Constant::isNormalFP() const", "llvm::Constant::isNormalFP",
  ),
  (
    "_ZN5clang6format16FormatTokenLexer27tryMergeJSPrivateIdentifierEv", "clang::format::FormatTokenLexer::tryMergeJSPrivateIdentifier()",
    "clang::format::FormatTokenLexer::tryMergeJSPrivateIdentifier",
  ),
  (
    "_ZN4llvm3X866isFSINEj", "llvm::X86::isFSIN(unsigned int)", "llvm::X86::isFSIN",
  ),
  (
    "_ZN5clang30DynamicRecursiveASTVisitorBaseILb1EE32WalkUpFromPredefinedSugarTypeLocENS_22PredefinedSugarTypeLocE",
    "clang::DynamicRecursiveASTVisitorBase<true>::WalkUpFromPredefinedSugarTypeLoc(clang::PredefinedSugarTypeLoc)",
    "clang::DynamicRecursiveASTVisitorBase<true>::WalkUpFromPredefinedSugarTypeLoc",
  ),
  (
    "_ZNK3AAT19KerxSubTableFormat0IN2OT20KernOTSubTableHeaderEE5applyEPNS_22hb_aat_apply_context_tE",
    "AAT::KerxSubTableFormat0<OT::KernOTSubTableHeader>::apply(AAT::hb_aat_apply_context_t*) const",
    "AAT::KerxSubTableFormat0<OT::KernOTSubTableHeader>::apply",
  ),
  (
    "_ZN4llvm43createXCoreFrameToArgsOffsetEliminationPassEv", "llvm::createXCoreFrameToArgsOffsetEliminationPass()",
    "llvm::createXCoreFrameToArgsOffsetEliminationPass",
  ),
  (
    "_ZN5clang30DynamicRecursiveASTVisitorBaseILb1EE21WalkUpFromDeclRefExprEPKNS_11DeclRefExprE",
    "clang::DynamicRecursiveASTVisitorBase<true>::WalkUpFromDeclRefExpr(clang::DeclRefExpr const*)",
    "clang::DynamicRecursiveASTVisitorBase<true>::WalkUpFromDeclRefExpr",
  ),
  (
    "_ZN5clang13TreeTransformIN12_GLOBAL__N_113TransformToPEEE20TransformCXXFoldExprEPNS_11CXXFoldExprE",
    "clang::TreeTransform<(anonymous namespace)::TransformToPE>::TransformCXXFoldExpr(clang::CXXFoldExpr*)",
    "clang::TreeTransform<(anonymous namespace)::TransformToPE>::TransformCXXFoldExpr",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_7arm_sme22aarch64_sme_write_vertEE18getParseAssemblyFnEv",
    "mlir::RegisteredOperationName::Model<mlir::arm_sme::aarch64_sme_write_vert>::getParseAssemblyFn()",
    "mlir::RegisteredOperationName::Model<mlir::arm_sme::aarch64_sme_write_vert>::getParseAssemblyFn",
  ),
  (
    "_ZN4lldb14SBTypeCategory16DeleteTypeFilterENS_19SBTypeNameSpecifierE", "lldb::SBTypeCategory::DeleteTypeFilter(lldb::SBTypeNameSpecifier)",
    "lldb::SBTypeCategory::DeleteTypeFilter",
  ),
  (
    "_ZN4mlir5ROCDL6detail37mfma_f32_32x32x4f16GenericAdaptorBase27getODSOperandIndexAndLengthEjj",
    "mlir::ROCDL::detail::mfma_f32_32x32x4f16GenericAdaptorBase::getODSOperandIndexAndLength(unsigned int, unsigned int)",
    "mlir::ROCDL::detail::mfma_f32_32x32x4f16GenericAdaptorBase::getODSOperandIndexAndLength",
  ),
  (
    "_ZN12_GLOBAL__N_119IGroupLPDAGMutation5applyEPN4llvm17ScheduleDAGInstrsE", "(anonymous namespace)::IGroupLPDAGMutation::apply(llvm::ScheduleDAGInstrs*)",
    "(anonymous namespace)::IGroupLPDAGMutation::apply",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5ROCDL25wmma_f32_16x16x16_fp8_bf8EE18getParseAssemblyFnEv",
    "mlir::RegisteredOperationName::Model<mlir::ROCDL::wmma_f32_16x16x16_fp8_bf8>::getParseAssemblyFn()",
    "mlir::RegisteredOperationName::Model<mlir::ROCDL::wmma_f32_16x16x16_fp8_bf8>::getParseAssemblyFn",
  ),
  (
    "_ZN5clang6interp7Context20getOrCreateObjCBlockEPKNS_9BlockExprE", "clang::interp::Context::getOrCreateObjCBlock(clang::BlockExpr const*)",
    "clang::interp::Context::getOrCreateObjCBlock",
  ),
  (
    "_ZN12_GLOBAL__N_115X86DAGToDAGISel12matchWrapperEN4llvm7SDValueERNS_18X86ISelAddressModeE",
    "(anonymous namespace)::X86DAGToDAGISel::matchWrapper(llvm::SDValue, (anonymous namespace)::X86ISelAddressMode&)",
    "(anonymous namespace)::X86DAGToDAGISel::matchWrapper",
  ),
  (
    "_ZN4mlir5spirv23SpecConstantOperationOp19getPropertiesAsAttrEPNS_11MLIRContextERKNS_15EmptyPropertiesE",
    "mlir::spirv::SpecConstantOperationOp::getPropertiesAsAttr(mlir::MLIRContext*, mlir::EmptyProperties const&)",
    "mlir::spirv::SpecConstantOperationOp::getPropertiesAsAttr",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_3gpu9BarrierOpEE8hasTraitENS_6TypeIDE",
    "mlir::RegisteredOperationName::Model<mlir::gpu::BarrierOp>::hasTrait(mlir::TypeID)",
    "mlir::RegisteredOperationName::Model<mlir::gpu::BarrierOp>::hasTrait",
  ),
  (
    "_ZN12_GLOBAL__N_116HoistSpillHelper21rmFromMergeableSpillsERN4llvm12MachineInstrEi",
    "(anonymous namespace)::HoistSpillHelper::rmFromMergeableSpills(llvm::MachineInstr&, int)",
    "(anonymous namespace)::HoistSpillHelper::rmFromMergeableSpills",
  ),
  (
    "_ZN6rustls4msgs7message8outbound21OutboundOpaqueMessage6encode17h344e88bb0b16fcfeE",
    "rustls::msgs::message::outbound::OutboundOpaqueMessage::encode::h344e88bb0b16fcfe",
    "rustls::msgs::message::outbound::OutboundOpaqueMessage::encode::h344e88bb0b16fcfe",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5arith15MulSIExtendedOpEE16verifyInvariantsEPNS_9OperationE",
    "mlir::RegisteredOperationName::Model<mlir::arith::MulSIExtendedOp>::verifyInvariants(mlir::Operation*)",
    "mlir::RegisteredOperationName::Model<mlir::arith::MulSIExtendedOp>::verifyInvariants",
  ),
  (
    "_ZN12_GLOBAL__N_118ParsedAttrInfoUuid8InstanceE", "(anonymous namespace)::ParsedAttrInfoUuid::Instance",
    "(anonymous namespace)::ParsedAttrInfoUuid::Instance",
  ),
  (
    "_ZN4mlir3omp6detail24TaskOpGenericAdaptorBase26getPrivateNeedsBarrierAttrEv",
    "mlir::omp::detail::TaskOpGenericAdaptorBase::getPrivateNeedsBarrierAttr()",
    "mlir::omp::detail::TaskOpGenericAdaptorBase::getPrivateNeedsBarrierAttr",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_136GPRPair_with_sub_gpr_even_in_GPRJALRE", "llvm::(anonymous namespace)::GPRPair_with_sub_gpr_even_in_GPRJALR",
    "llvm::(anonymous namespace)::GPRPair_with_sub_gpr_even_in_GPRJALR",
  ),
  (
    "_ZN4mlir5spirv32stringifyCooperativeMatrixUseKHRENS0_23CooperativeMatrixUseKHRE",
    "mlir::spirv::stringifyCooperativeMatrixUseKHR(mlir::spirv::CooperativeMatrixUseKHR)",
    "mlir::spirv::stringifyCooperativeMatrixUseKHR",
  ),
  (
    "_ZN4mlir5spirv35stringifyCooperativeMatrixLayoutKHRENS0_26CooperativeMatrixLayoutKHRE",
    "mlir::spirv::stringifyCooperativeMatrixLayoutKHR(mlir::spirv::CooperativeMatrixLayoutKHR)",
    "mlir::spirv::stringifyCooperativeMatrixLayoutKHR",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_15HvxWRE", "llvm::(anonymous namespace)::HvxWR", "llvm::(anonymous namespace)::HvxWR",
  ),
  (
    "_ZTIN4llvm23DroppedVariableStatsMIRE", "typeinfo for llvm::DroppedVariableStatsMIR",
    "typeinfo for llvm::DroppedVariableStatsMIR",
  ),
  (
    "_ZN4llvm12CodeViewYAML6detail16SymbolRecordImplINS_8codeview13AnnotationSymEE3mapERNS_4yaml2IOE",
    "llvm::CodeViewYAML::detail::SymbolRecordImpl<llvm::codeview::AnnotationSym>::map(llvm::yaml::IO&)",
    "llvm::CodeViewYAML::detail::SymbolRecordImpl<llvm::codeview::AnnotationSym>::map",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_17VK4PAIRE", "llvm::(anonymous namespace)::VK4PAIR", "llvm::(anonymous namespace)::VK4PAIR",
  ),
  ("_ZN4llvmL11RegList8AVRE", "llvm::RegList8AVR", "llvm::RegList8AVR"),
  (
    "_ZN4llvm12_GLOBAL__N_15HvxQRE", "llvm::(anonymous namespace)::HvxQR", "llvm::(anonymous namespace)::HvxQR",
  ),
  (
    "_ZN4llvm12CodeViewYAML6detail16SymbolRecordImplINS_8codeview22DefRangeRegisterRelSymEE3mapERNS_4yaml2IOE",
    "llvm::CodeViewYAML::detail::SymbolRecordImpl<llvm::codeview::DefRangeRegisterRelSym>::map(llvm::yaml::IO&)",
    "llvm::CodeViewYAML::detail::SymbolRecordImpl<llvm::codeview::DefRangeRegisterRelSym>::map",
  ),
  (
    "_ZTIN4llvm3lto3LTOE", "typeinfo for llvm::lto::LTO", "typeinfo for llvm::lto::LTO",
  ),
  (
    "_ZTSN4llvm29TargetLoweringObjectFileMachOE", "typeinfo name for llvm::TargetLoweringObjectFileMachO",
    "typeinfo name for llvm::TargetLoweringObjectFileMachO",
  ),
  (
    "_ZNK4ojph5local9param_cod13is_reversibleEv", "ojph::local::param_cod::is_reversible() const",
    "ojph::local::param_cod::is_reversible",
  ),
  (
    "_ZNK4llvm21AArch64TargetLowering16LowerVectorXRINTENS_7SDValueERNS_12SelectionDAGE",
    "llvm::AArch64TargetLowering::LowerVectorXRINT(llvm::SDValue, llvm::SelectionDAG&) const",
    "llvm::AArch64TargetLowering::LowerVectorXRINT",
  ),
  (
    "_ZNK2v88internal16LargeObjectSpace12ContainsSlowEm", "v8::internal::LargeObjectSpace::ContainsSlow(unsigned long) const",
    "v8::internal::LargeObjectSpace::ContainsSlow",
  ),
  (
    "_ZNK21set_initial_value_cmd13next_arg_kindER11cmd_context", "set_initial_value_cmd::next_arg_kind(cmd_context&) const",
    "set_initial_value_cmd::next_arg_kind",
  ),
  (
    "_ZNK4llvm16HexagonInstrInfo7isFloatERKNS_12MachineInstrE", "llvm::HexagonInstrInfo::isFloat(llvm::MachineInstr const&) const",
    "llvm::HexagonInstrInfo::isFloat",
  ),
  (
    "_ZNK2v88internal8compiler10turboshaft9Operation12PrintOptionsERNSt3__113basic_ostreamIcNS4_11char_traitsIcEEEE",
    "v8::internal::compiler::turboshaft::Operation::PrintOptions(std::__1::basic_ostream<char, std::__1::char_traits<char>>&) const",
    "v8::internal::compiler::turboshaft::Operation::PrintOptions",
  ),
  (
    "_ZNK2v88internal6maglev30StoreTaggedFieldNoWriteBarrier12VerifyInputsEv", "v8::internal::maglev::StoreTaggedFieldNoWriteBarrier::VerifyInputs() const",
    "v8::internal::maglev::StoreTaggedFieldNoWriteBarrier::VerifyInputs",
  ),
  (
    "_ZNK4llvm8LoopBaseIN4mlir5BlockENS1_7CFGLoopEE14getLoopLatchesERNS_15SmallVectorImplIPS2_EE",
    "llvm::LoopBase<mlir::Block, mlir::CFGLoop>::getLoopLatches(llvm::SmallVectorImpl<mlir::Block*>&) const",
    "llvm::LoopBase<mlir::Block, mlir::CFGLoop>::getLoopLatches",
  ),
  (
    "_ZNK7Imf_3_46Header15tileDescriptionEv", "Imf_3_4::Header::tileDescription() const",
    "Imf_3_4::Header::tileDescription",
  ),
  (
    "_ZNK4mlir4impl33LinalgFoldIntoElementwisePassBaseIN12_GLOBAL__N_129LinalgFoldIntoElementwisePassEE9clonePassEv",
    "mlir::impl::LinalgFoldIntoElementwisePassBase<(anonymous namespace)::LinalgFoldIntoElementwisePass>::clonePass() const",
    "mlir::impl::LinalgFoldIntoElementwisePassBase<(anonymous namespace)::LinalgFoldIntoElementwisePass>::clonePass",
  ),
  (
    "_ZNK4llvm8Function18getDenormalModeRawEv", "llvm::Function::getDenormalModeRaw() const",
    "llvm::Function::getDenormalModeRaw",
  ),
  (
    "_ZNK4llvm8coverage15CoverageMapping22getCoverageForFunctionERKNS0_14FunctionRecordE",
    "llvm::coverage::CoverageMapping::getCoverageForFunction(llvm::coverage::FunctionRecord const&) const",
    "llvm::coverage::CoverageMapping::getCoverageForFunction",
  ),
  (
    "_ZN4llvm3X868isVDIVSSEj", "llvm::X86::isVDIVSS(unsigned int)", "llvm::X86::isVDIVSS",
  ),
  (
    "_ZN4llvm3EVT6getEVTEPNS_4TypeEb", "llvm::EVT::getEVT(llvm::Type*, bool)", "llvm::EVT::getEVT",
  ),
  (
    "_ZL16initializeBufferRN5clang7CodeGen13CodeGenModuleEPN4llvm14GlobalVariableEjNS3_8ArrayRefIPNS3_5ValueEEE",
    "initializeBuffer(clang::CodeGen::CodeGenModule&, llvm::GlobalVariable*, unsigned int, llvm::ArrayRef<llvm::Value*>)",
    "initializeBuffer",
  ),
  (
    "_ZN4llvm11ImutAVLTreeINS_17ImutContainerInfoIN12_GLOBAL__N_19ZeroStateEEEE7destroyEv",
    "llvm::ImutAVLTree<llvm::ImutContainerInfo<(anonymous namespace)::ZeroState>>::destroy()",
    "llvm::ImutAVLTree<llvm::ImutContainerInfo<(anonymous namespace)::ZeroState>>::destroy",
  ),
  (
    "_ZL12processValueN4mlir5ValueERN12_GLOBAL__N_17LiveMapE", "processValue(mlir::Value, (anonymous namespace)::LiveMap&)",
    "processValue",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_133AV_192_with_sub2_in_VGPR_32_Lo128E", "llvm::(anonymous namespace)::AV_192_with_sub2_in_VGPR_32_Lo128",
    "llvm::(anonymous namespace)::AV_192_with_sub2_in_VGPR_32_Lo128",
  ),
  (
    "_ZN4llvm3X8612isVPUNPCKLWDEj", "llvm::X86::isVPUNPCKLWD(unsigned int)", "llvm::X86::isVPUNPCKLWD",
  ),
  (
    "_ZN4mlir6amdgpu18FatRawBufferCastOp5buildERNS_9OpBuilderERNS_14OperationStateENS_9TypeRangeENS_5ValueES7_S7_bb",
    "mlir::amdgpu::FatRawBufferCastOp::build(mlir::OpBuilder&, mlir::OperationState&, mlir::TypeRange, mlir::Value, mlir::Value, mlir::Value, bool, bool)",
    "mlir::amdgpu::FatRawBufferCastOp::build",
  ),
  (
    "_ZTVN4llvm6detail9PassModelINS_8FunctionENS_22InferAddressSpacesPassENS_15AnalysisManagerIS2_JEEEJEEE",
    "vtable for llvm::detail::PassModel<llvm::Function, llvm::InferAddressSpacesPass, llvm::AnalysisManager<llvm::Function>>",
    "vtable for llvm::detail::PassModel<llvm::Function, llvm::InferAddressSpacesPass, llvm::AnalysisManager<llvm::Function>>",
  ),
  (
    "_ZTVN2v88internal12_GLOBAL__N_120MatchInfoBackedMatchE", "vtable for v8::internal::(anonymous namespace)::MatchInfoBackedMatch",
    "vtable for v8::internal::(anonymous namespace)::MatchInfoBackedMatch",
  ),
  (
    "_ZN2v88internal9Assembler6uqrshlERKNS0_9VRegisterES4_S4_", "v8::internal::Assembler::uqrshl(v8::internal::VRegister const&, v8::internal::VRegister const&, v8::internal::VRegister const&)",
    "v8::internal::Assembler::uqrshl",
  ),
  (
    "_ZTVN4mlir23RegisteredOperationName5ModelINS_7wasmssa5MulOpEEE", "vtable for mlir::RegisteredOperationName::Model<mlir::wasmssa::MulOp>",
    "vtable for mlir::RegisteredOperationName::Model<mlir::wasmssa::MulOp>",
  ),
  (
    "_ZN10func_entry10deallocateER11ast_managerj", "func_entry::deallocate(ast_manager&, unsigned int)",
    "func_entry::deallocate",
  ),
  (
    "_ZN4llvm13ScopedPrinter10arrayBeginEv", "llvm::ScopedPrinter::arrayBegin()",
    "llvm::ScopedPrinter::arrayBegin",
  ),
  (
    "_ZN2qe6nlqsat9get_levelEjPKN3sat7literalE", "qe::nlqsat::get_level(unsigned int, sat::literal const*)",
    "qe::nlqsat::get_level",
  ),
  (
    "_ZN5clang12ast_matchers25substTemplateTypeParmTypeE", "clang::ast_matchers::substTemplateTypeParmType",
    "clang::ast_matchers::substTemplateTypeParmType",
  ),
  (
    "_ZN13wasmtime_wasi7runtime14spawn_blocking28_$u7b$$u7b$closure$u7d$$u7d$17h3e732099323344e6E",
    "wasmtime_wasi::runtime::spawn_blocking::_$u7b$$u7b$closure$u7d$$u7d$::h3e732099323344e6",
    "wasmtime_wasi::runtime::spawn_blocking::_$u7b$$u7b$closure$u7d$$u7d$::h3e732099323344e6",
  ),
  (
    "_ZN5tokio7runtime4task3raw21drop_join_handle_slow17h06f22fcf21a5e2e3E", "tokio::runtime::task::raw::drop_join_handle_slow::h06f22fcf21a5e2e3",
    "tokio::runtime::task::raw::drop_join_handle_slow::h06f22fcf21a5e2e3",
  ),
  (
    "_ZN4core5error5Error7type_id17h3f11c5805ac8a403E", "core::error::Error::type_id::h3f11c5805ac8a403",
    "core::error::Error::type_id::h3f11c5805ac8a403",
  ),
  (
    "_ZN2v88internal17RegExpDisjunction9max_matchEv", "v8::internal::RegExpDisjunction::max_match()",
    "v8::internal::RegExpDisjunction::max_match",
  ),
  (
    "_ZL25createSparcMCRegisterInfoRKN4llvm6TripleE", "createSparcMCRegisterInfo(llvm::Triple const&)",
    "createSparcMCRegisterInfo",
  ),
  (
    "_ZN4rsvg7element13set_attribute17hfec1072ff19bfc94E", "rsvg::element::set_attribute::hfec1072ff19bfc94",
    "rsvg::element::set_attribute::hfec1072ff19bfc94",
  ),
  (
    "_ZN11wasmprinter7Printer12print_limits17h75d2adc59badd09dE", "wasmprinter::Printer::print_limits::h75d2adc59badd09d",
    "wasmprinter::Printer::print_limits::h75d2adc59badd09d",
  ),
  (
    "_ZN12AnnotPolygon4drawEP3Gfxb", "AnnotPolygon::draw(Gfx*, bool)", "AnnotPolygon::draw",
  ),
  (
    "_ZN5clang6driver10toolchains19PPCFreeBSDToolChainD1Ev", "clang::driver::toolchains::PPCFreeBSDToolChain::~PPCFreeBSDToolChain()",
    "clang::driver::toolchains::PPCFreeBSDToolChain::~PPCFreeBSDToolChain",
  ),
  (
    "_ZTSN4mlir23RegisteredOperationName5ModelINS_4LLVM13GlobalDtorsOpEEE", "typeinfo name for mlir::RegisteredOperationName::Model<mlir::LLVM::GlobalDtorsOp>",
    "typeinfo name for mlir::RegisteredOperationName::Model<mlir::LLVM::GlobalDtorsOp>",
  ),
  (
    "_ZN5clang7targets17FreeBSDTargetInfoINS0_19AArch64leTargetInfoEED0Ev", "clang::targets::FreeBSDTargetInfo<clang::targets::AArch64leTargetInfo>::~FreeBSDTargetInfo()",
    "clang::targets::FreeBSDTargetInfo<clang::targets::AArch64leTargetInfo>::~FreeBSDTargetInfo",
  ),
  (
    "_ZNK5clang9ASTReader28translateGlobalDeclIDToIndexENS_12GlobalDeclIDE", "clang::ASTReader::translateGlobalDeclIDToIndex(clang::GlobalDeclID) const",
    "clang::ASTReader::translateGlobalDeclIDToIndex",
  ),
  (
    "_ZTVN5clang6driver10toolchains19PPCFreeBSDToolChainE", "vtable for clang::driver::toolchains::PPCFreeBSDToolChain",
    "vtable for clang::driver::toolchains::PPCFreeBSDToolChain",
  ),
  (
    "_ZTSN5clang7targets16NetBSDTargetInfoINS0_16X86_32TargetInfoEEE", "typeinfo name for clang::targets::NetBSDTargetInfo<clang::targets::X86_32TargetInfo>",
    "typeinfo name for clang::targets::NetBSDTargetInfo<clang::targets::X86_32TargetInfo>",
  ),
  (
    "_ZN4llvm15VerifierSupport20DebugInfoCheckFailedIPKNS_12DISubprogramEJPNS_7MDTupleEEEEvRKNS_5TwineERKT_DpRKT0_",
    "void llvm::VerifierSupport::DebugInfoCheckFailed<llvm::DISubprogram const*, llvm::MDTuple*>(llvm::Twine const&, llvm::DISubprogram const* const&, llvm::MDTuple* const&)",
    "llvm::VerifierSupport::DebugInfoCheckFailed<llvm::DISubprogram const*, llvm::MDTuple*>",
  ),
  (
    "_ZNK4llvm3pdb16PDBSymbolTypeUDT4dumpERNS0_12PDBSymDumperE", "llvm::pdb::PDBSymbolTypeUDT::dump(llvm::pdb::PDBSymDumper&) const",
    "llvm::pdb::PDBSymbolTypeUDT::dump",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4LLVM13GlobalDtorsOpEE17comparePropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::GlobalDtorsOp>::compareProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::GlobalDtorsOp>::compareProperties",
  ),
  (
    "_ZN4llvm25OptimizationRemarkEmitter4emitIZNS_17LoopVectorizePass11processLoopEPNS_4LoopEE3$_2EEvT_PDTclfL0p_EE",
    "void llvm::OptimizationRemarkEmitter::emit<llvm::LoopVectorizePass::processLoop(llvm::Loop*)::$_2>(llvm::LoopVectorizePass::processLoop(llvm::Loop*)::$_2, decltype(fp())*)",
    "llvm::OptimizationRemarkEmitter::emit<llvm::LoopVectorizePass::processLoop(llvm::Loop*)::$_2>",
  ),
  (
    "_ZN4llvmL43DTripleSpc_with_dsub_4_in_DPR_8SubClassMaskE", "llvm::DTripleSpc_with_dsub_4_in_DPR_8SubClassMask",
    "llvm::DTripleSpc_with_dsub_4_in_DPR_8SubClassMask",
  ),
  (
    "_ZL46InitializeAMDGPUCtorDtorLoweringLegacyPassFlag", "InitializeAMDGPUCtorDtorLoweringLegacyPassFlag",
    "InitializeAMDGPUCtorDtorLoweringLegacyPassFlag",
  ),
  (
    "_ZNSt3__16vectorIN4llvm3sys17OwningMemoryBlockENS_9allocatorIS3_EEE12emplace_backIJS3_EEERS3_DpOT_",
    "llvm::sys::OwningMemoryBlock& std::__1::vector<llvm::sys::OwningMemoryBlock, std::__1::allocator<llvm::sys::OwningMemoryBlock>>::emplace_back<llvm::sys::OwningMemoryBlock>(llvm::sys::OwningMemoryBlock&&)",
    "std::__1::vector<llvm::sys::OwningMemoryBlock, std::__1::allocator<llvm::sys::OwningMemoryBlock>>::emplace_back<llvm::sys::OwningMemoryBlock>",
  ),
  (
    "_ZNK4node19CompileCacheHandler5DebugIJRjS2_EEEvPKcDpOT_.cold.1", "void node::CompileCacheHandler::Debug<unsigned int&, unsigned int&>(char const*, unsigned int&, unsigned int&) const (.cold.1)",
    "node::CompileCacheHandler::Debug<unsigned int&, unsigned int&>",
  ),
  (
    "_ZN4node27UnconditionalAsyncWrapDebugIJRiRjEEEvPNS_9AsyncWrapEPKcDpOT_", "void node::UnconditionalAsyncWrapDebug<int&, unsigned int&>(node::AsyncWrap*, char const*, int&, unsigned int&)",
    "node::UnconditionalAsyncWrapDebug<int&, unsigned int&>",
  ),
  (
    "_ZN4node7FPrintFIJjEEEvP7__sFILENSt3__117basic_string_viewIcNS3_11char_traitsIcEEEEDpOT_",
    "void node::FPrintF<unsigned int>(__sFILE*, std::__1::basic_string_view<char, std::__1::char_traits<char>>, unsigned int&&)",
    "node::FPrintF<unsigned int>",
  ),
  (
    "_ZN4node7FPrintFIJPKcEEEvP7__sFILENSt3__117basic_string_viewIcNS5_11char_traitsIcEEEEDpOT_",
    "void node::FPrintF<char const*>(__sFILE*, std::__1::basic_string_view<char, std::__1::char_traits<char>>, char const*&&)",
    "node::FPrintF<char const*>",
  ),
  (
    "_ZN4llvm15VerifierSupport11CheckFailedIPNS_10SwitchInstEJPNS_11ConstantIntEEEEvRKNS_5TwineERKT_DpRKT0_",
    "void llvm::VerifierSupport::CheckFailed<llvm::SwitchInst*, llvm::ConstantInt*>(llvm::Twine const&, llvm::SwitchInst* const&, llvm::ConstantInt* const&)",
    "llvm::VerifierSupport::CheckFailed<llvm::SwitchInst*, llvm::ConstantInt*>",
  ),
  (
    "_ZN2v88internal4Zone3NewINS0_30IterationStatementSourceRangesEJRKNS0_11SourceRangeEEEEPT_DpOT0_",
    "v8::internal::IterationStatementSourceRanges* v8::internal::Zone::New<v8::internal::IterationStatementSourceRanges, v8::internal::SourceRange const&>(v8::internal::SourceRange const&)",
    "v8::internal::Zone::New<v8::internal::IterationStatementSourceRanges, v8::internal::SourceRange const&>",
  ),
  (
    "_ZN4node5Realm14AddBindingDataINS_6timers11BindingDataEJEEEPT_N2v85LocalINS6_6ObjectEEEDpOT0_.cold.2",
    "node::timers::BindingData* node::Realm::AddBindingData<node::timers::BindingData>(v8::Local<v8::Object>) (.cold.2)",
    "node::Realm::AddBindingData<node::timers::BindingData>",
  ),
  (
    "_ZN12_GLOBAL__N_14Lint11CheckFailedIPN4llvm14BinaryOperatorEJEEEvRKNS2_5TwineERKT_DpRKT0_",
    "void (anonymous namespace)::Lint::CheckFailed<llvm::BinaryOperator*>(llvm::Twine const&, llvm::BinaryOperator* const&)",
    "(anonymous namespace)::Lint::CheckFailed<llvm::BinaryOperator*>",
  ),
  (
    "_ZNK17hb_sorted_array_tIKN2OT23VariationSelectorRecordEE12bsearch_implIjJEEEbRKT_PjDpT0_",
    "bool hb_sorted_array_t<OT::VariationSelectorRecord const>::bsearch_impl<unsigned int>(unsigned int const&, unsigned int*) const",
    "hb_sorted_array_t<OT::VariationSelectorRecord const>::bsearch_impl<unsigned int>",
  ),
  (
    "_ZNSt3__114__split_bufferIPPN4llvm8FunctionENS_9allocatorIS4_EEE13emplace_frontIJS4_EEEvDpOT_",
    "void std::__1::__split_buffer<llvm::Function**, std::__1::allocator<llvm::Function**>>::emplace_front<llvm::Function**>(llvm::Function**&&)",
    "std::__1::__split_buffer<llvm::Function**, std::__1::allocator<llvm::Function**>>::emplace_front<llvm::Function**>",
  ),
  (
    "_ZN11hb_vector_tIjLb1EE4pushIJRKjEEEPjDpOT_", "unsigned int* hb_vector_t<unsigned int, true>::push<unsigned int const&>(unsigned int const&)",
    "hb_vector_t<unsigned int, true>::push<unsigned int const&>",
  ),
  (
    "_ZTIN4mlir5spirv6detail29QueryExtensionInterfaceTraits5ModelINS0_11GroupUMinOpEEE",
    "typeinfo for mlir::spirv::detail::QueryExtensionInterfaceTraits::Model<mlir::spirv::GroupUMinOp>",
    "typeinfo for mlir::spirv::detail::QueryExtensionInterfaceTraits::Model<mlir::spirv::GroupUMinOp>",
  ),
  (
    "_ZN4mlir5spirv27GroupNonUniformBitwiseXorOp17getGroupOperationEv", "mlir::spirv::GroupNonUniformBitwiseXorOp::getGroupOperation()",
    "mlir::spirv::GroupNonUniformBitwiseXorOp::getGroupOperation",
  ),
  (
    "_ZN4mlir9transform6detail28HoistPadOpGenericAdaptorBase12getTransposeEv", "mlir::transform::detail::HoistPadOpGenericAdaptorBase::getTranspose()",
    "mlir::transform::detail::HoistPadOpGenericAdaptorBase::getTranspose",
  ),
  (
    "_ZN5clang20TransparentUnionAttrC1ERNS_10ASTContextERKNS_19AttributeCommonInfoE",
    "clang::TransparentUnionAttr::TransparentUnionAttr(clang::ASTContext&, clang::AttributeCommonInfo const&)",
    "clang::TransparentUnionAttr::TransparentUnionAttr",
  ),
  (
    "_ZN4mlir5spirv6detail30QueryCapabilityInterfaceTraits5ModelINS0_11GLReflectOpEED1Ev",
    "mlir::spirv::detail::QueryCapabilityInterfaceTraits::Model<mlir::spirv::GLReflectOp>::~Model()",
    "mlir::spirv::detail::QueryCapabilityInterfaceTraits::Model<mlir::spirv::GLReflectOp>::~Model",
  ),
  (
    "_ZN4mlir5spirv11GroupFMaxOp20verifyInvariantsImplEv", "mlir::spirv::GroupFMaxOp::verifyInvariantsImpl()",
    "mlir::spirv::GroupFMaxOp::verifyInvariantsImpl",
  ),
  (
    "_ZN4mlir5spirv27GroupNonUniformShuffleXorOp5printERNS_12OpAsmPrinterE", "mlir::spirv::GroupNonUniformShuffleXorOp::print(mlir::OpAsmPrinter&)",
    "mlir::spirv::GroupNonUniformShuffleXorOp::print",
  ),
  (
    "_ZN4mlir13sparse_tensor6detail36ExtractIterSpaceOpGenericAdaptorBase8getHiLvlEv",
    "mlir::sparse_tensor::detail::ExtractIterSpaceOpGenericAdaptorBase::getHiLvl()",
    "mlir::sparse_tensor::detail::ExtractIterSpaceOpGenericAdaptorBase::getHiLvl",
  ),
  (
    "_ZN4mlir13sparse_tensor6LoadOp6createERNS_9OpBuilderENS_8LocationENS_4TypeENS_5ValueEb",
    "mlir::sparse_tensor::LoadOp::create(mlir::OpBuilder&, mlir::Location, mlir::Type, mlir::Value, bool)",
    "mlir::sparse_tensor::LoadOp::create",
  ),
  (
    "_ZTIN4mlir23RegisteredOperationName5ModelINS_6linalg11TransposeOpEEE", "typeinfo for mlir::RegisteredOperationName::Model<mlir::linalg::TransposeOp>",
    "typeinfo for mlir::RegisteredOperationName::Model<mlir::linalg::TransposeOp>",
  ),
  (
    "_ZTVN6spdlog7details21color_start_formatterE", "vtable for spdlog::details::color_start_formatter",
    "vtable for spdlog::details::color_start_formatter",
  ),
  (
    "_ZN4mlir13sparse_tensor6detail31ToPositionsOpGenericAdaptorBaseC1ENS0_13ToPositionsOpE",
    "mlir::sparse_tensor::detail::ToPositionsOpGenericAdaptorBase::ToPositionsOpGenericAdaptorBase(mlir::sparse_tensor::ToPositionsOp)",
    "mlir::sparse_tensor::detail::ToPositionsOpGenericAdaptorBase::ToPositionsOpGenericAdaptorBase",
  ),
  (
    "_ZN2v88internal8compiler12JSHeapBroker33Initdot_static_home_object_stringEv",
    "v8::internal::compiler::JSHeapBroker::Initdot_static_home_object_string()",
    "v8::internal::compiler::JSHeapBroker::Initdot_static_home_object_string",
  ),
  (
    "_ZN4llvm21X86FastTileConfigPass3runERNS_15MachineFunctionERNS_15AnalysisManagerIS1_JEEE",
    "llvm::X86FastTileConfigPass::run(llvm::MachineFunction&, llvm::AnalysisManager<llvm::MachineFunction>&)",
    "llvm::X86FastTileConfigPass::run",
  ),
  (
    "_ZN2v88internal8compiler21JSOperatorGlobalCache16ToBigIntOperatorD1Ev", "v8::internal::compiler::JSOperatorGlobalCache::ToBigIntOperator::~ToBigIntOperator()",
    "v8::internal::compiler::JSOperatorGlobalCache::ToBigIntOperator::~ToBigIntOperator",
  ),
  (
    "_ZN2v88internal10JsonParserIhE21ReportUnexpectedTokenENS0_9JsonTokenENSt3__18optionalINS0_15MessageTemplateEEE",
    "v8::internal::JsonParser<unsigned char>::ReportUnexpectedToken(v8::internal::JsonToken, std::__1::optional<v8::internal::MessageTemplate>)",
    "v8::internal::JsonParser<unsigned char>::ReportUnexpectedToken",
  ),
  (
    "_ZNK2v88internal8compiler10NodeOrigin9PrintJsonERNSt3__113basic_ostreamIcNS3_11char_traitsIcEEEE",
    "v8::internal::compiler::NodeOrigin::PrintJson(std::__1::basic_ostream<char, std::__1::char_traits<char>>&) const",
    "v8::internal::compiler::NodeOrigin::PrintJson",
  ),
  (
    "_ZN2v88internal8compiler12JSHeapBroker21InitClassPositionsMapEv", "v8::internal::compiler::JSHeapBroker::InitClassPositionsMap()",
    "v8::internal::compiler::JSHeapBroker::InitClassPositionsMap",
  ),
  (
    "_ZNK5clang25CFICanonicalJumpTableAttr5cloneERNS_10ASTContextE", "clang::CFICanonicalJumpTableAttr::clone(clang::ASTContext&) const",
    "clang::CFICanonicalJumpTableAttr::clone",
  ),
  (
    "_ZNK2v88internal8compiler6MapRef20IsJSSpecialObjectMapEv", "v8::internal::compiler::MapRef::IsJSSpecialObjectMap() const",
    "v8::internal::compiler::MapRef::IsJSSpecialObjectMap",
  ),
  (
    "_ZN2v88internal8compiler12JSHeapBroker20Initlatin1_87_stringEv", "v8::internal::compiler::JSHeapBroker::Initlatin1_87_string()",
    "v8::internal::compiler::JSHeapBroker::Initlatin1_87_string",
  ),
  (
    "_ZTVN5clang7tooling23JSONCompilationDatabaseE", "vtable for clang::tooling::JSONCompilationDatabase",
    "vtable for clang::tooling::JSONCompilationDatabase",
  ),
  (
    "_ZN2v88internal15ThreadIsolation16JitPageReference20AllocationContainingEm",
    "v8::internal::ThreadIsolation::JitPageReference::AllocationContaining(unsigned long)",
    "v8::internal::ThreadIsolation::JitPageReference::AllocationContaining",
  ),
  (
    "_ZTIN4llvm6detail9PassModelINS_8FunctionENS_19NVPTXIRPeepholePassENS_15AnalysisManagerIS2_JEEEJEEE",
    "typeinfo for llvm::detail::PassModel<llvm::Function, llvm::NVPTXIRPeepholePass, llvm::AnalysisManager<llvm::Function>>",
    "typeinfo for llvm::detail::PassModel<llvm::Function, llvm::NVPTXIRPeepholePass, llvm::AnalysisManager<llvm::Function>>",
  ),
  (
    "_ZN12_GLOBAL__N_114CXXNameMangler18mangleOperatorNameEN5clang15DeclarationNameEj",
    "(anonymous namespace)::CXXNameMangler::mangleOperatorName(clang::DeclarationName, unsigned int)",
    "(anonymous namespace)::CXXNameMangler::mangleOperatorName",
  ),
  (
    "_ZN4llvm3X8615getCondFromCMovERKNS_12MachineInstrE", "llvm::X86::getCondFromCMov(llvm::MachineInstr const&)",
    "llvm::X86::getCondFromCMov",
  ),
  (
    "_ZN5clang19AnyX86InterruptAttrC1ERNS_10ASTContextERKNS_19AttributeCommonInfoE",
    "clang::AnyX86InterruptAttr::AnyX86InterruptAttr(clang::ASTContext&, clang::AttributeCommonInfo const&)",
    "clang::AnyX86InterruptAttr::AnyX86InterruptAttr",
  ),
  (
    "_ZN4llvm3X869isVSQRTPDEj", "llvm::X86::isVSQRTPD(unsigned int)", "llvm::X86::isVSQRTPD",
  ),
  (
    "_ZN4llvm3X8618VR512_0_15RegClassE", "llvm::X86::VR512_0_15RegClass", "llvm::X86::VR512_0_15RegClass",
  ),
  (
    "_ZL24HasTrivialDestructorBodyRN5clang10ASTContextEPKNS_13CXXRecordDeclES4_",
    "HasTrivialDestructorBody(clang::ASTContext&, clang::CXXRecordDecl const*, clang::CXXRecordDecl const*)",
    "HasTrivialDestructorBody",
  ),
  (
    "_ZL25createX86MCRelocationInfoRKN4llvm6TripleERNS_9MCContextE", "createX86MCRelocationInfo(llvm::Triple const&, llvm::MCContext&)",
    "createX86MCRelocationInfo",
  ),
  (
    "_ZN7ncrypto11X509PointeraSEOS0_", "ncrypto::X509Pointer::operator=(ncrypto::X509Pointer&&)",
    "ncrypto::X509Pointer::operator=",
  ),
  (
    "_ZN12_GLOBAL__N_116PPCAIXAsmPrinter24emitGlobalVariableHelperEPKN4llvm14GlobalVariableE",
    "(anonymous namespace)::PPCAIXAsmPrinter::emitGlobalVariableHelper(llvm::GlobalVariable const*)",
    "(anonymous namespace)::PPCAIXAsmPrinter::emitGlobalVariableHelper",
  ),
  (
    "_ZN4core3ptr40drop_in_place$LT$rsvg..xml..XmlState$GT$17h3467a7f710eb935cE",
    "core::ptr::drop_in_place$LT$rsvg..xml..XmlState$GT$::h3467a7f710eb935c", "core::ptr::drop_in_place$LT$rsvg..xml..XmlState$GT$::h3467a7f710eb935c",
  ),
  (
    "_ZNK4llvm20XCoreGenRegisterInfo15isFixedRegisterERKNS_15MachineFunctionENS_10MCRegisterE",
    "llvm::XCoreGenRegisterInfo::isFixedRegister(llvm::MachineFunction const&, llvm::MCRegister) const",
    "llvm::XCoreGenRegisterInfo::isFixedRegister",
  ),
  (
    "_ZN4llvm2cl6parserINS_5NVPTX17DivPrecisionLevelEED1Ev", "llvm::cl::parser<llvm::NVPTX::DivPrecisionLevel>::~parser()",
    "llvm::cl::parser<llvm::NVPTX::DivPrecisionLevel>::~parser",
  ),
  (
    "_ZN4lldb11SBLineEntry7SetLineEj", "lldb::SBLineEntry::SetLine(unsigned int)",
    "lldb::SBLineEntry::SetLine",
  ),
  (
    "_ZN12lldb_private16AppleObjCRuntime15ReadObjCLibraryERKNSt3__110shared_ptrINS_6ModuleEEE",
    "lldb_private::AppleObjCRuntime::ReadObjCLibrary(std::__1::shared_ptr<lldb_private::Module> const&)",
    "lldb_private::AppleObjCRuntime::ReadObjCLibrary",
  ),
  (
    "_ZN12_GLOBAL__N_129RegUsageInfoPropagationLegacyD1Ev", "(anonymous namespace)::RegUsageInfoPropagationLegacy::~RegUsageInfoPropagationLegacy()",
    "(anonymous namespace)::RegUsageInfoPropagationLegacy::~RegUsageInfoPropagationLegacy",
  ),
  (
    "_ZN4mlir6linalg5ExpOp26getODSResultIndexAndLengthEj", "mlir::linalg::ExpOp::getODSResultIndexAndLength(unsigned int)",
    "mlir::linalg::ExpOp::getODSResultIndexAndLength",
  ),
  (
    "_ZN4mlir9transform6detail32LoopPipelineOpGenericAdaptorBase24getIterationIntervalAttrEv",
    "mlir::transform::detail::LoopPipelineOpGenericAdaptorBase::getIterationIntervalAttr()",
    "mlir::transform::detail::LoopPipelineOpGenericAdaptorBase::getIterationIntervalAttr",
  ),
  (
    "_ZN12_GLOBAL__N_140CastAwayExtractStridedSliceLeadingOneDimD0Ev", "(anonymous namespace)::CastAwayExtractStridedSliceLeadingOneDim::~CastAwayExtractStridedSliceLeadingOneDim()",
    "(anonymous namespace)::CastAwayExtractStridedSliceLeadingOneDim::~CastAwayExtractStridedSliceLeadingOneDim",
  ),
  (
    "_ZN12rewriter_tplI16beta_reducer_cfgE12cache_resultILb1EEEvP4exprS4_P3appb",
    "void rewriter_tpl<beta_reducer_cfg>::cache_result<true>(expr*, expr*, app*, bool)",
    "rewriter_tpl<beta_reducer_cfg>::cache_result<true>",
  ),
  (
    "_ZTIN4mlir23RegisteredOperationName5ModelINS_5xegpu12LoadMatrixOpEEE", "typeinfo for mlir::RegisteredOperationName::Model<mlir::xegpu::LoadMatrixOp>",
    "typeinfo for mlir::RegisteredOperationName::Model<mlir::xegpu::LoadMatrixOp>",
  ),
  (
    "_ZL25_wrap_delete_SBLaunchInfoP7_objectS0_", "_wrap_delete_SBLaunchInfo(_object*, _object*)",
    "_wrap_delete_SBLaunchInfo",
  ),
  (
    "_ZTVN4mlir23RegisteredOperationName5ModelINS_7complex5LogOpEEE", "vtable for mlir::RegisteredOperationName::Model<mlir::complex::LogOp>",
    "vtable for mlir::RegisteredOperationName::Model<mlir::complex::LogOp>",
  ),
  (
    "_ZN4mlir5ROCDL13CvtSrBf8F32Op6createERNS_9OpBuilderENS_8LocationENS_4TypeENS_5ValueES6_S6_j",
    "mlir::ROCDL::CvtSrBf8F32Op::create(mlir::OpBuilder&, mlir::Location, mlir::Type, mlir::Value, mlir::Value, mlir::Value, unsigned int)",
    "mlir::ROCDL::CvtSrBf8F32Op::create",
  ),
  (
    "_ZN4mlir7arm_sme21aarch64_sme_mops_wide6createERNS_9OpBuilderENS_8LocationENS_9TypeRangeEjNS_5ValueES6_S6_S6_",
    "mlir::arm_sme::aarch64_sme_mops_wide::create(mlir::OpBuilder&, mlir::Location, mlir::TypeRange, unsigned int, mlir::Value, mlir::Value, mlir::Value, mlir::Value)",
    "mlir::arm_sme::aarch64_sme_mops_wide::create",
  ),
  (
    "_ZN4llvm9sandboxir13GenericSetterIXadL_ZNKS0_11Instruction9hasNoInfsEvEEXadL_ZNS2_12setHasNoInfsEbEEED1Ev",
    "llvm::sandboxir::GenericSetter<&llvm::sandboxir::Instruction::hasNoInfs() const, &llvm::sandboxir::Instruction::setHasNoInfs(bool)>::~GenericSetter()",
    "llvm::sandboxir::GenericSetter<&llvm::sandboxir::Instruction::hasNoInfs() const, &llvm::sandboxir::Instruction::setHasNoInfs(bool)>::~GenericSetter",
  ),
  (
    "_ZTVN4llvm9sandboxir13GenericSetterIXadL_ZNKS0_11Instruction7isExactEvEEXadL_ZNS2_10setIsExactEbEEEE",
    "vtable for llvm::sandboxir::GenericSetter<&llvm::sandboxir::Instruction::isExact() const, &llvm::sandboxir::Instruction::setIsExact(bool)>",
    "vtable for llvm::sandboxir::GenericSetter<&llvm::sandboxir::Instruction::isExact() const, &llvm::sandboxir::Instruction::setIsExact(bool)>",
  ),
  (
    "_ZN4llvm9sandboxir13GenericSetterIXadL_ZNKS0_11Instruction7isExactEvEEXadL_ZNS2_10setIsExactEbEEE6acceptEv",
    "llvm::sandboxir::GenericSetter<&llvm::sandboxir::Instruction::isExact() const, &llvm::sandboxir::Instruction::setIsExact(bool)>::accept()",
    "llvm::sandboxir::GenericSetter<&llvm::sandboxir::Instruction::isExact() const, &llvm::sandboxir::Instruction::setIsExact(bool)>::accept",
  ),
  (
    "_ZN4node11http_parser6Parser5ProxyIMS1_FivEXadL_ZNS1_16on_message_beginEvEEE3RawEP18llhttp__internal_s",
    "node::http_parser::Parser::Proxy<int (node::http_parser::Parser::*)(), &node::http_parser::Parser::on_message_begin()>::Raw(llhttp__internal_s*)",
    "node::http_parser::Parser::Proxy<int (node::http_parser::Parser::*)(), &node::http_parser::Parser::on_message_begin()>::Raw",
  ),
  (
    "_ZN7ncrypto13EVPKeyPointer6NewRSAEONSt3__110unique_ptrI6rsa_stNS_15FunctionDeleterIS3_XadL_Z8RSA_freeEEEEEE",
    "ncrypto::EVPKeyPointer::NewRSA(std::__1::unique_ptr<rsa_st, ncrypto::FunctionDeleter<rsa_st, &RSA_free>>&&)",
    "ncrypto::EVPKeyPointer::NewRSA",
  ),
  (
    "_ZN4llvm6detail9IEEEFloat17initFromIEEEAPIntIL_ZNS_11APFloatBase13semFloat8E4M3EEEEvRKNS_5APIntE",
    "void llvm::detail::IEEEFloat::initFromIEEEAPInt<llvm::APFloatBase::semFloat8E4M3>(llvm::APInt const&)",
    "llvm::detail::IEEEFloat::initFromIEEEAPInt<llvm::APFloatBase::semFloat8E4M3>",
  ),
  (
    "_ZN4llvm9sandboxir13GenericSetterIXadL_ZNKS0_11Instruction9hasNoNaNsEvEEXadL_ZNS2_12setHasNoNaNsEbEEED0Ev",
    "llvm::sandboxir::GenericSetter<&llvm::sandboxir::Instruction::hasNoNaNs() const, &llvm::sandboxir::Instruction::setHasNoNaNs(bool)>::~GenericSetter()",
    "llvm::sandboxir::GenericSetter<&llvm::sandboxir::Instruction::hasNoNaNs() const, &llvm::sandboxir::Instruction::setHasNoNaNs(bool)>::~GenericSetter",
  ),
  (
    "_ZTVN4llvm9sandboxir13GenericSetterIXadL_ZNKS0_18PossiblyNonNegInst9hasNonNegEvEEXadL_ZNS2_9setNonNegEbEEEE",
    "vtable for llvm::sandboxir::GenericSetter<&llvm::sandboxir::PossiblyNonNegInst::hasNonNeg() const, &llvm::sandboxir::PossiblyNonNegInst::setNonNeg(bool)>",
    "vtable for llvm::sandboxir::GenericSetter<&llvm::sandboxir::PossiblyNonNegInst::hasNonNeg() const, &llvm::sandboxir::PossiblyNonNegInst::setNonNeg(bool)>",
  ),
  (
    "_ZN4node11http_parser6Parser5ProxyIMS1_FiPKcmEXadL_ZNS1_7on_bodyES4_mEEE3RawEP18llhttp__internal_sS4_m",
    "node::http_parser::Parser::Proxy<int (node::http_parser::Parser::*)(char const*, unsigned long), &node::http_parser::Parser::on_body(char const*, unsigned long)>::Raw(llhttp__internal_s*, char const*, unsigned long)",
    "node::http_parser::Parser::Proxy<int (node::http_parser::Parser::*)(char const*, unsigned long), &node::http_parser::Parser::on_body(char const*, unsigned long)>::Raw",
  ),
  (
    "_ZN4llvm6detail9IEEEFloat17initFromIEEEAPIntIL_ZNS_11APFloatBase11semIEEEquadEEEEvRKNS_5APIntE",
    "void llvm::detail::IEEEFloat::initFromIEEEAPInt<llvm::APFloatBase::semIEEEquad>(llvm::APInt const&)",
    "llvm::detail::IEEEFloat::initFromIEEEAPInt<llvm::APFloatBase::semIEEEquad>",
  ),
  (
    "_ZTIN4llvm9sandboxir13GenericSetterIXadL_ZNKS0_11Instruction7isExactEvEEXadL_ZNS2_10setIsExactEbEEEE",
    "typeinfo for llvm::sandboxir::GenericSetter<&llvm::sandboxir::Instruction::isExact() const, &llvm::sandboxir::Instruction::setIsExact(bool)>",
    "typeinfo for llvm::sandboxir::GenericSetter<&llvm::sandboxir::Instruction::isExact() const, &llvm::sandboxir::Instruction::setIsExact(bool)>",
  ),
  (
    "_ZN4node11http_parser6Parser5ProxyIMS1_FivEXadL_ZNS1_17on_chunk_completeEvEEE3RawEP18llhttp__internal_s",
    "node::http_parser::Parser::Proxy<int (node::http_parser::Parser::*)(), &node::http_parser::Parser::on_chunk_complete()>::Raw(llhttp__internal_s*)",
    "node::http_parser::Parser::Proxy<int (node::http_parser::Parser::*)(), &node::http_parser::Parser::on_chunk_complete()>::Raw",
  ),
  (
    "_ZL27ESSCertIDv2DecodingTemplate", "ESSCertIDv2DecodingTemplate", "ESSCertIDv2DecodingTemplate",
  ),
  ("_ZL19ESSCertIDv2Template", "ESSCertIDv2Template", "ESSCertIDv2Template"),
  (
    "_ZN4llvm9MCContext8diagnoseERKNS_12SMDiagnosticE", "llvm::MCContext::diagnose(llvm::SMDiagnostic const&)",
    "llvm::MCContext::diagnose",
  ),
  (
    "_ZN5clang6interp11InterpState19setActiveDiagnosticEb", "clang::interp::InterpState::setActiveDiagnostic(bool)",
    "clang::interp::InterpState::setActiveDiagnostic",
  ),
  (
    "_ZN12_GLOBAL__N_118CVSymbolDumperImpl14visitSymbolEndERN4llvm8codeview8CVRecordINS2_10SymbolKindEEE",
    "(anonymous namespace)::CVSymbolDumperImpl::visitSymbolEnd(llvm::codeview::CVRecord<llvm::codeview::SymbolKind>&)",
    "(anonymous namespace)::CVSymbolDumperImpl::visitSymbolEnd",
  ),
  (
    "_ZTIN12_GLOBAL__N_137DimOfReifyRankedShapedTypeOpInterfaceIN4mlir6memref5DimOpEEE",
    "typeinfo for (anonymous namespace)::DimOfReifyRankedShapedTypeOpInterface<mlir::memref::DimOp>",
    "typeinfo for (anonymous namespace)::DimOfReifyRankedShapedTypeOpInterface<mlir::memref::DimOp>",
  ),
  (
    "_ZN4mlir4math5LogOp14readPropertiesERNS_21DialectBytecodeReaderERNS_14OperationStateE",
    "mlir::math::LogOp::readProperties(mlir::DialectBytecodeReader&, mlir::OperationState&)",
    "mlir::math::LogOp::readProperties",
  ),
  (
    "_ZL32AttrDoc_CoroDisableLifetimeBound", "AttrDoc_CoroDisableLifetimeBound",
    "AttrDoc_CoroDisableLifetimeBound",
  ),
  (
    "_ZN4llvm29GenericSyncDependenceAnalysisINS_17GenericSSAContextINS_8FunctionEEEE20DivergenceDescriptorD1Ev",
    "llvm::GenericSyncDependenceAnalysis<llvm::GenericSSAContext<llvm::Function>>::DivergenceDescriptor::~DivergenceDescriptor()",
    "llvm::GenericSyncDependenceAnalysis<llvm::GenericSSAContext<llvm::Function>>::DivergenceDescriptor::~DivergenceDescriptor",
  ),
  (
    "_ZTSN4mlir23RegisteredOperationName5ModelINS_3omp12DistributeOpEEE", "typeinfo name for mlir::RegisteredOperationName::Model<mlir::omp::DistributeOp>",
    "typeinfo name for mlir::RegisteredOperationName::Model<mlir::omp::DistributeOp>",
  ),
  (
    "_ZN12_GLOBAL__N_115DarwinAsmParser21parseDirectiveSectionEN4llvm9StringRefENS1_5SMLocE",
    "(anonymous namespace)::DarwinAsmParser::parseDirectiveSection(llvm::StringRef, llvm::SMLoc)",
    "(anonymous namespace)::DarwinAsmParser::parseDirectiveSection",
  ),
  (
    "_ZN4mlir3pdl10PDLDialectD2Ev", "mlir::pdl::PDLDialect::~PDLDialect()", "mlir::pdl::PDLDialect::~PDLDialect",
  ),
  (
    "_ZN4mlir6affine10isValidDimENS_5ValueE", "mlir::affine::isValidDim(mlir::Value)",
    "mlir::affine::isValidDim",
  ),
  (
    "_ZN5clang14TextNodeDumper33VisitPragmaClangRodataSectionAttrEPKNS_28PragmaClangRodataSectionAttrE",
    "clang::TextNodeDumper::VisitPragmaClangRodataSectionAttr(clang::PragmaClangRodataSectionAttr const*)",
    "clang::TextNodeDumper::VisitPragmaClangRodataSectionAttr",
  ),
  (
    "_ZNK4llvm16SITargetLowering19lowerConstHwRegReadERNS_12SelectionDAGENS_7SDValueENS_6AMDGPU5Hwreg2IdEjj",
    "llvm::SITargetLowering::lowerConstHwRegRead(llvm::SelectionDAG&, llvm::SDValue, llvm::AMDGPU::Hwreg::Id, unsigned int, unsigned int) const",
    "llvm::SITargetLowering::lowerConstHwRegRead",
  ),
  (
    "_ZN4llvm6AMDGPU12isPermlane16Ej", "llvm::AMDGPU::isPermlane16(unsigned int)",
    "llvm::AMDGPU::isPermlane16",
  ),
  (
    "_ZN4llvm6AMDGPU7SendMsg16isValidMsgStreamExxxRKNS_15MCSubtargetInfoEb", "llvm::AMDGPU::SendMsg::isValidMsgStream(long long, long long, long long, llvm::MCSubtargetInfo const&, bool)",
    "llvm::AMDGPU::SendMsg::isValidMsgStream",
  ),
  (
    "_ZN4llvm6AMDGPU69AV_224_with_sub1_sub2_sub3_sub4_sub5_in_VReg_160_Lo256_Align2RegClassE",
    "llvm::AMDGPU::AV_224_with_sub1_sub2_sub3_sub4_sub5_in_VReg_160_Lo256_Align2RegClass",
    "llvm::AMDGPU::AV_224_with_sub1_sub2_sub3_sub4_sub5_in_VReg_160_Lo256_Align2RegClass",
  ),
  (
    "_ZN4llvm6AMDGPU48AV_1024_with_sub1_sub2_in_VReg_64_Align2RegClassE", "llvm::AMDGPU::AV_1024_with_sub1_sub2_in_VReg_64_Align2RegClass",
    "llvm::AMDGPU::AV_1024_with_sub1_sub2_in_VReg_64_Align2RegClass",
  ),
  (
    "_ZN4llvm6AMDGPU21RegBankLegalizeHelper18unpackAExtTruncS16ENS_8RegisterE", "llvm::AMDGPU::RegBankLegalizeHelper::unpackAExtTruncS16(llvm::Register)",
    "llvm::AMDGPU::RegBankLegalizeHelper::unpackAExtTruncS16",
  ),
  (
    "_ZN4llvm6AMDGPU22getGcnBufferFormatInfoEhRKNS_15MCSubtargetInfoE", "llvm::AMDGPU::getGcnBufferFormatInfo(unsigned char, llvm::MCSubtargetInfo const&)",
    "llvm::AMDGPU::getGcnBufferFormatInfo",
  ),
  (
    "_ZN4llvm6AMDGPU21RegBankLegalizeHelper19applyMappingTrivialERNS_12MachineInstrE",
    "llvm::AMDGPU::RegBankLegalizeHelper::applyMappingTrivial(llvm::MachineInstr&)",
    "llvm::AMDGPU::RegBankLegalizeHelper::applyMappingTrivial",
  ),
  (
    "_ZN4llvm6AMDGPU49SGPR_1024_with_sub10_sub11_in_CCR_SGPR_64RegClassE", "llvm::AMDGPU::SGPR_1024_with_sub10_sub11_in_CCR_SGPR_64RegClass",
    "llvm::AMDGPU::SGPR_1024_with_sub10_sub11_in_CCR_SGPR_64RegClass",
  ),
  (
    "_ZN4llvm6AMDGPU41AV_512_with_sub6_in_VGPR_32_Lo128RegClassE", "llvm::AMDGPU::AV_512_with_sub6_in_VGPR_32_Lo128RegClass",
    "llvm::AMDGPU::AV_512_with_sub6_in_VGPR_32_Lo128RegClass",
  ),
  (
    "_ZN4llvm6AMDGPU50SGPR_288_with_sub4_sub5_in_Gfx_CCR_SGPR_64RegClassE", "llvm::AMDGPU::SGPR_288_with_sub4_sub5_in_Gfx_CCR_SGPR_64RegClass",
    "llvm::AMDGPU::SGPR_288_with_sub4_sub5_in_Gfx_CCR_SGPR_64RegClass",
  ),
  (
    "_ZN4llvm6AMDGPU6DepCtr17encodeFieldVaVdstEjRKNS_15MCSubtargetInfoE", "llvm::AMDGPU::DepCtr::encodeFieldVaVdst(unsigned int, llvm::MCSubtargetInfo const&)",
    "llvm::AMDGPU::DepCtr::encodeFieldVaVdst",
  ),
  ("_ZL10_hb_ucd_u8", "_hb_ucd_u8", "_hb_ucd_u8"),
  (
    "_ZTIN12_GLOBAL__N_119MBarrierBasePatternIN4mlir5nvgpu13MBarrierGetOpEEE", "typeinfo for (anonymous namespace)::MBarrierBasePattern<mlir::nvgpu::MBarrierGetOp>",
    "typeinfo for (anonymous namespace)::MBarrierBasePattern<mlir::nvgpu::MBarrierGetOp>",
  ),
  (
    "_ZN12_GLOBAL__N_127RawBufferAtomicByCasPatternIN4mlir6amdgpu21RawBufferAtomicUminOpENS1_5arith7MinUIOpEED1Ev",
    "(anonymous namespace)::RawBufferAtomicByCasPattern<mlir::amdgpu::RawBufferAtomicUminOp, mlir::arith::MinUIOp>::~RawBufferAtomicByCasPattern()",
    "(anonymous namespace)::RawBufferAtomicByCasPattern<mlir::amdgpu::RawBufferAtomicUminOp, mlir::arith::MinUIOp>::~RawBufferAtomicByCasPattern",
  ),
  (
    "_ZN4mlir5nvgpu10TmaFenceOp5buildERNS_9OpBuilderERNS_14OperationStateENS_5ValueE",
    "mlir::nvgpu::TmaFenceOp::build(mlir::OpBuilder&, mlir::OperationState&, mlir::Value)",
    "mlir::nvgpu::TmaFenceOp::build",
  ),
  (
    "_ZN45_$LT$$RF$T$u20$as$u20$core..fmt..UpperHex$GT$3fmt17hbc4bc60459655becE",
    "_$LT$$RF$T$u20$as$u20$core..fmt..UpperHex$GT$::fmt::hbc4bc60459655bec", "_$LT$$RF$T$u20$as$u20$core..fmt..UpperHex$GT$::fmt::hbc4bc60459655bec",
  ),
  (
    "_ZN4mlir5xegpu15ConvertLayoutOp15getTargetLayoutEv", "mlir::xegpu::ConvertLayoutOp::getTargetLayout()",
    "mlir::xegpu::ConvertLayoutOp::getTargetLayout",
  ),
  (
    "_ZN70_$LT$wast..core..expr..Instruction$u20$as$u20$wast..encode..Encode$GT$6encode6encode17h3deee10b8fd65265E",
    "_$LT$wast..core..expr..Instruction$u20$as$u20$wast..encode..Encode$GT$::encode::encode::h3deee10b8fd65265",
    "_$LT$wast..core..expr..Instruction$u20$as$u20$wast..encode..Encode$GT$::encode::encode::h3deee10b8fd65265",
  ),
  (
    "_ZN4mlir5nvgpu21WarpgroupMmaOpAdaptor6verifyENS_8LocationE", "mlir::nvgpu::WarpgroupMmaOpAdaptor::verify(mlir::Location)",
    "mlir::nvgpu::WarpgroupMmaOpAdaptor::verify",
  ),
  (
    "_ZN4mlir5xegpu16NbarrierArriveOp6createERNS_20ImplicitLocOpBuilderENS_5ValueE",
    "mlir::xegpu::NbarrierArriveOp::create(mlir::ImplicitLocOpBuilder&, mlir::Value)",
    "mlir::xegpu::NbarrierArriveOp::create",
  ),
  (
    "_ZN42_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$3fmt17h171202a8ab33f927E", "_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$::fmt::h171202a8ab33f927",
    "_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$::fmt::h171202a8ab33f927",
  ),
  (
    "_ZN4mlir3gpu12TerminatorOp21computePropertiesHashERKNS_15EmptyPropertiesE",
    "mlir::gpu::TerminatorOp::computePropertiesHash(mlir::EmptyProperties const&)",
    "mlir::gpu::TerminatorOp::computePropertiesHash",
  ),
  (
    "_ZTVN12_GLOBAL__N_131RemoveStaticallyOobBufferWritesIN4mlir6amdgpu16RawBufferStoreOpEEE",
    "vtable for (anonymous namespace)::RemoveStaticallyOobBufferWrites<mlir::amdgpu::RawBufferStoreOp>",
    "vtable for (anonymous namespace)::RemoveStaticallyOobBufferWrites<mlir::amdgpu::RawBufferStoreOp>",
  ),
  (
    "_ZN12lldb_private18CommandInterpreter23OutputFormattedHelpTextERNS_6StreamEN4llvm9StringRefES4_",
    "lldb_private::CommandInterpreter::OutputFormattedHelpText(lldb_private::Stream&, llvm::StringRef, llvm::StringRef)",
    "lldb_private::CommandInterpreter::OutputFormattedHelpText",
  ),
  (
    "_ZN2v88internal8compiler26TurbofanPipelineStatisticsD1Ev", "v8::internal::compiler::TurbofanPipelineStatistics::~TurbofanPipelineStatistics()",
    "v8::internal::compiler::TurbofanPipelineStatistics::~TurbofanPipelineStatistics",
  ),
  (
    "_ZN4llvm12inverse_fabsENS_11FPClassTestE", "llvm::inverse_fabs(llvm::FPClassTest)",
    "llvm::inverse_fabs",
  ),
  (
    "_ZN5clang8Rewriter10RemoveTextENS_14SourceLocationEjNS0_14RewriteOptionsE",
    "clang::Rewriter::RemoveText(clang::SourceLocation, unsigned int, clang::Rewriter::RewriteOptions)",
    "clang::Rewriter::RemoveText",
  ),
  (
    "_ZN5clang30DynamicRecursiveASTVisitorBaseILb1EE25TraverseClassTemplateDeclEPKNS_17ClassTemplateDeclE",
    "clang::DynamicRecursiveASTVisitorBase<true>::TraverseClassTemplateDecl(clang::ClassTemplateDecl const*)",
    "clang::DynamicRecursiveASTVisitorBase<true>::TraverseClassTemplateDecl",
  ),
  (
    "_ZN4llvm23SmallVectorTemplateBaseINS_11SmallVectorINS_5DstOpELj8EEELb0EE4growEm",
    "llvm::SmallVectorTemplateBase<llvm::SmallVector<llvm::DstOp, 8u>, false>::grow(unsigned long)",
    "llvm::SmallVectorTemplateBase<llvm::SmallVector<llvm::DstOp, 8u>, false>::grow",
  ),
  (
    "_ZNK4mlir10TensorType7hasRankEv", "mlir::TensorType::hasRank() const", "mlir::TensorType::hasRank",
  ),
  (
    "_ZN4mlir5ROCDL20TensorStoreFromLDSOp14getAliasScopesEv", "mlir::ROCDL::TensorStoreFromLDSOp::getAliasScopes()",
    "mlir::ROCDL::TensorStoreFromLDSOp::getAliasScopes",
  ),
  (
    "_ZNK5clang7TagType15getTemplateArgsERKNS_10ASTContextE", "clang::TagType::getTemplateArgs(clang::ASTContext const&) const",
    "clang::TagType::getTemplateArgs",
  ),
  (
    "_ZN4llvm30RAIITemporaryObserverInstallerC1ERNS_20GISelObserverWrapperERNS_19GISelChangeObserverE",
    "llvm::RAIITemporaryObserverInstaller::RAIITemporaryObserverInstaller(llvm::GISelObserverWrapper&, llvm::GISelChangeObserver&)",
    "llvm::RAIITemporaryObserverInstaller::RAIITemporaryObserverInstaller",
  ),
  (
    "_ZN4lldb6SBType23GetTemplateArgumentTypeEj", "lldb::SBType::GetTemplateArgumentType(unsigned int)",
    "lldb::SBType::GetTemplateArgumentType",
  ),
  (
    "_ZN2v88Template3SetENS_5LocalINS_4NameEEENS1_INS_4DataEEENS_17PropertyAttributeE",
    "v8::Template::Set(v8::Local<v8::Name>, v8::Local<v8::Data>, v8::PropertyAttribute)",
    "v8::Template::Set",
  ),
  ("_ZL18AttrDoc_Destructor", "AttrDoc_Destructor", "AttrDoc_Destructor"),
  (
    "_ZNK2v88internal6maglev15LoadDoubleField11PrintParamsERNSt3__113basic_ostreamIcNS3_11char_traitsIcEEEE",
    "v8::internal::maglev::LoadDoubleField::PrintParams(std::__1::basic_ostream<char, std::__1::char_traits<char>>&) const",
    "v8::internal::maglev::LoadDoubleField::PrintParams",
  ),
  (
    "_ZN4llvm4yaml8Document14parseBlockNodeEv", "llvm::yaml::Document::parseBlockNode()",
    "llvm::yaml::Document::parseBlockNode",
  ),
  (
    "_ZN2v88internal14DotPrinterImpl11VisitChoiceEPNS0_10ChoiceNodeE", "v8::internal::DotPrinterImpl::VisitChoice(v8::internal::ChoiceNode*)",
    "v8::internal::DotPrinterImpl::VisitChoice",
  ),
  ("_ZL15AttrDoc_Flatten", "AttrDoc_Flatten", "AttrDoc_Flatten"),
  (
    "_ZL31AttrDoc_WebAssemblyImportModule", "AttrDoc_WebAssemblyImportModule", "AttrDoc_WebAssemblyImportModule",
  ),
  (
    "_ZN4mlir5spirv7SUDotOp6verifyEv", "mlir::spirv::SUDotOp::verify()", "mlir::spirv::SUDotOp::verify",
  ),
  (
    "_ZN8v8_crdtp16DomainDispatcher8CallbackD1Ev", "v8_crdtp::DomainDispatcher::Callback::~Callback()",
    "v8_crdtp::DomainDispatcher::Callback::~Callback",
  ),
  (
    "_ZL25AttrDoc_EnumExtensibility", "AttrDoc_EnumExtensibility", "AttrDoc_EnumExtensibility",
  ),
  (
    "_ZN12lldb_private18ScriptedThreadPlan18DoPlanExplainsStopEPNS_5EventE", "lldb_private::ScriptedThreadPlan::DoPlanExplainsStop(lldb_private::Event*)",
    "lldb_private::ScriptedThreadPlan::DoPlanExplainsStop",
  ),
  (
    "_ZNK4llvm21DominanceFrontierBaseINS_17MachineBasicBlockELb0EE4findEPS1_", "llvm::DominanceFrontierBase<llvm::MachineBasicBlock, false>::find(llvm::MachineBasicBlock*) const",
    "llvm::DominanceFrontierBase<llvm::MachineBasicBlock, false>::find",
  ),
  (
    "_ZNK4llvm17DominatorTreeBaseINS_10BasicBlockELb1EE7getRootEv", "llvm::DominatorTreeBase<llvm::BasicBlock, true>::getRoot() const",
    "llvm::DominatorTreeBase<llvm::BasicBlock, true>::getRoot",
  ),
  (
    "_ZN4llvm8GVNHoist16hoistExpressionsERNS_8FunctionE", "llvm::GVNHoist::hoistExpressions(llvm::Function&)",
    "llvm::GVNHoist::hoistExpressions",
  ),
  (
    "_ZTSN4llvm6detail9PassModelINS_8FunctionENS_12GVNHoistPassENS_15AnalysisManagerIS2_JEEEJEEE",
    "typeinfo name for llvm::detail::PassModel<llvm::Function, llvm::GVNHoistPass, llvm::AnalysisManager<llvm::Function>>",
    "typeinfo name for llvm::detail::PassModel<llvm::Function, llvm::GVNHoistPass, llvm::AnalysisManager<llvm::Function>>",
  ),
  (
    "_ZN4llvm8GVNHoist11hasEHhelperEPKNS_10BasicBlockES3_Ri", "llvm::GVNHoist::hasEHhelper(llvm::BasicBlock const*, llvm::BasicBlock const*, int&)",
    "llvm::GVNHoist::hasEHhelper",
  ),
  (
    "_ZTIN4llvm6detail9PassModelINS_8FunctionENS_12GVNHoistPassENS_15AnalysisManagerIS2_JEEEJEEE",
    "typeinfo for llvm::detail::PassModel<llvm::Function, llvm::GVNHoistPass, llvm::AnalysisManager<llvm::Function>>",
    "typeinfo for llvm::detail::PassModel<llvm::Function, llvm::GVNHoistPass, llvm::AnalysisManager<llvm::Function>>",
  ),
  (
    "_ZN4llvm19GCNHazardRecognizer18checkSetRegHazardsEPNS_12MachineInstrE", "llvm::GCNHazardRecognizer::checkSetRegHazards(llvm::MachineInstr*)",
    "llvm::GCNHazardRecognizer::checkSetRegHazards",
  ),
  (
    "_ZN4llvm8GVNHoist15updateAlignmentEPNS_11InstructionES2_", "llvm::GVNHoist::updateAlignment(llvm::Instruction*, llvm::Instruction*)",
    "llvm::GVNHoist::updateAlignment",
  ),
  (
    "_ZNK4llvm8GVNHoist16valueAnticipableENS_14iterator_rangeIPNS_6CHIArgEEEPNS_11InstructionE",
    "llvm::GVNHoist::valueAnticipable(llvm::iterator_range<llvm::CHIArg*>, llvm::Instruction*) const",
    "llvm::GVNHoist::valueAnticipable",
  ),
  (
    "_ZN4llvm19GCNHazardRecognizer30fixScratchBaseForwardingHazardEPNS_12MachineInstrE",
    "llvm::GCNHazardRecognizer::fixScratchBaseForwardingHazard(llvm::MachineInstr*)",
    "llvm::GCNHazardRecognizer::fixScratchBaseForwardingHazard",
  ),
  (
    "_ZN4llvm19GCNHazardRecognizer13addClauseInstERKNS_12MachineInstrE", "llvm::GCNHazardRecognizer::addClauseInst(llvm::MachineInstr const&)",
    "llvm::GCNHazardRecognizer::addClauseInst",
  ),
  (
    "_ZN4llvm19GCNHazardRecognizer10fixHazardsEPNS_12MachineInstrE", "llvm::GCNHazardRecognizer::fixHazards(llvm::MachineInstr*)",
    "llvm::GCNHazardRecognizer::fixHazards",
  ),
  (
    "_ZN4llvm19GCNHazardRecognizer14fixWMMAHazardsEPNS_12MachineInstrE", "llvm::GCNHazardRecognizer::fixWMMAHazards(llvm::MachineInstr*)",
    "llvm::GCNHazardRecognizer::fixWMMAHazards",
  ),
  (
    "_ZN4llvm19GCNHazardRecognizer15checkDPPHazardsEPNS_12MachineInstrE", "llvm::GCNHazardRecognizer::checkDPPHazards(llvm::MachineInstr*)",
    "llvm::GCNHazardRecognizer::checkDPPHazards",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_155LOW32_ADDR_ACCESS_RBP_with_sub_16bit_in_GR16_NOREX2BitsE",
    "llvm::(anonymous namespace)::LOW32_ADDR_ACCESS_RBP_with_sub_16bit_in_GR16_NOREX2Bits",
    "llvm::(anonymous namespace)::LOW32_ADDR_ACCESS_RBP_with_sub_16bit_in_GR16_NOREX2Bits",
  ),
  (
    "_ZN4llvmL63LOW32_ADDR_ACCESS_RBP_with_sub_16bit_in_GR16_NOREX2SubClassMaskE",
    "llvm::LOW32_ADDR_ACCESS_RBP_with_sub_16bit_in_GR16_NOREX2SubClassMask", "llvm::LOW32_ADDR_ACCESS_RBP_with_sub_16bit_in_GR16_NOREX2SubClassMask",
  ),
  (
    "_ZTVN5clang6driver5tools5MinGW9AssemblerE", "vtable for clang::driver::tools::MinGW::Assembler",
    "vtable for clang::driver::tools::MinGW::Assembler",
  ),
  (
    "_ZN4llvm3X8630GR64_TC_and_GR64_TCW64RegClassE", "llvm::X86::GR64_TC_and_GR64_TCW64RegClass",
    "llvm::X86::GR64_TC_and_GR64_TCW64RegClass",
  ),
  (
    "_ZN4llvmL38GR64PLTSafe_and_GR64_TCW64SuperclassesE", "llvm::GR64PLTSafe_and_GR64_TCW64Superclasses",
    "llvm::GR64PLTSafe_and_GR64_TCW64Superclasses",
  ),
  (
    "_ZN4llvmL63LOW32_ADDR_ACCESS_RBP_with_sub_16bit_in_GR16_NOREX2SuperclassesE",
    "llvm::LOW32_ADDR_ACCESS_RBP_with_sub_16bit_in_GR16_NOREX2Superclasses", "llvm::LOW32_ADDR_ACCESS_RBP_with_sub_16bit_in_GR16_NOREX2Superclasses",
  ),
  (
    "_ZNK5clang6driver10toolchains5MinGW7getToolENS0_6Action11ActionClassE", "clang::driver::toolchains::MinGW::getTool(clang::driver::Action::ActionClass) const",
    "clang::driver::toolchains::MinGW::getTool",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_125GR64_NOREX_and_GR64_TCW64E", "llvm::(anonymous namespace)::GR64_NOREX_and_GR64_TCW64",
    "llvm::(anonymous namespace)::GR64_NOREX_and_GR64_TCW64",
  ),
  (
    "_ZN4llvm3X8610isVCVTW2PHEj", "llvm::X86::isVCVTW2PH(unsigned int)", "llvm::X86::isVCVTW2PH",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_129GR64_NOREX_and_GR64_TCW64BitsE", "llvm::(anonymous namespace)::GR64_NOREX_and_GR64_TCW64Bits",
    "llvm::(anonymous namespace)::GR64_NOREX_and_GR64_TCW64Bits",
  ),
  (
    "_ZN4llvmL47LOW32_ADDR_ACCESS_RBP_with_sub_8bitSubClassMaskE", "llvm::LOW32_ADDR_ACCESS_RBP_with_sub_8bitSubClassMask",
    "llvm::LOW32_ADDR_ACCESS_RBP_with_sub_8bitSubClassMask",
  ),
  (
    "_ZN4llvmL48LOW32_ADDR_ACCESS_RBP_with_sub_32bitSubClassMaskE", "llvm::LOW32_ADDR_ACCESS_RBP_with_sub_32bitSubClassMask",
    "llvm::LOW32_ADDR_ACCESS_RBP_with_sub_32bitSubClassMask",
  ),
  (
    "_ZN4llvm13GlobalDCEPass8MarkLiveERNS_11GlobalValueEPNS_15SmallVectorImplIPS1_EE",
    "llvm::GlobalDCEPass::MarkLive(llvm::GlobalValue&, llvm::SmallVectorImpl<llvm::GlobalValue*>*)",
    "llvm::GlobalDCEPass::MarkLive",
  ),
  (
    "_ZTVN12_GLOBAL__N_114SystemZTDCPassE", "vtable for (anonymous namespace)::SystemZTDCPass",
    "vtable for (anonymous namespace)::SystemZTDCPass",
  ),
  (
    "_ZN4llvm3X868isTDCALLEj", "llvm::X86::isTDCALL(unsigned int)", "llvm::X86::isTDCALL",
  ),
  (
    "_ZN4llvm5ValIDC2ERKS0_", "llvm::ValID::ValID(llvm::ValID const&)", "llvm::ValID::ValID",
  ),
  (
    "_ZN7ncrypto15EVPMDCtxPointeraSEOS0_", "ncrypto::EVPMDCtxPointer::operator=(ncrypto::EVPMDCtxPointer&&)",
    "ncrypto::EVPMDCtxPointer::operator=",
  ),
  (
    "_ZN3jxl6N_NEON12_GLOBAL__N_110IDCT1DImplILm16ELm4EEclEPKfmPfmS6_", "jxl::N_NEON::(anonymous namespace)::IDCT1DImpl<16ul, 4ul>::operator()(float const*, unsigned long, float*, unsigned long, float*)",
    "jxl::N_NEON::(anonymous namespace)::IDCT1DImpl<16ul, 4ul>::operator()",
  ),
  (
    "_ZL24DecodeMVEVADCInstructionRN4llvm6MCInstEjyPKNS_14MCDisassemblerE", "DecodeMVEVADCInstruction(llvm::MCInst&, unsigned int, unsigned long long, llvm::MCDisassembler const*)",
    "DecodeMVEVADCInstruction",
  ),
  (
    "_ZTS9DCTStream", "typeinfo name for DCTStream", "typeinfo name for DCTStream",
  ),
  (
    "_ZTIN12_GLOBAL__N_123VectorFMAOp1DConversionE", "typeinfo for (anonymous namespace)::VectorFMAOp1DConversion",
    "typeinfo for (anonymous namespace)::VectorFMAOp1DConversion",
  ),
  (
    "_ZN4llvm6DCDataC2ERKNS_17MachineBasicBlockE", "llvm::DCData::DCData(llvm::MachineBasicBlock const&)",
    "llvm::DCData::DCData",
  ),
  (
    "_ZN3jxl17DCTResampleScalesILm4ELm32EE7kScalesE", "jxl::DCTResampleScales<4ul, 32ul>::kScales",
    "jxl::DCTResampleScales<4ul, 32ul>::kScales",
  ),
  (
    "_ZNK4llvm2cl6parserI12WPDCheckModeE9getOptionEj", "llvm::cl::parser<WPDCheckMode>::getOption(unsigned int) const",
    "llvm::cl::parser<WPDCheckMode>::getOption",
  ),
  (
    "_ZN6vectorIN15expr2polynomial3imp5frameELb0EjE9push_backEOS2_", "vector<expr2polynomial::imp::frame, false, unsigned int>::push_back(expr2polynomial::imp::frame&&)",
    "vector<expr2polynomial::imp::frame, false, unsigned int>::push_back",
  ),
  (
    "_ZN7datalog17tr_infrastructureINS_15relation_traitsEE20convenient_rename_fnD0Ev",
    "datalog::tr_infrastructure<datalog::relation_traits>::convenient_rename_fn::~convenient_rename_fn()",
    "datalog::tr_infrastructure<datalog::relation_traits>::convenient_rename_fn::~convenient_rename_fn",
  ),
  (
    "_ZN5image2io6format11ImageFormat14from_extension5inner17h3342954c37fcf605E",
    "image::io::format::ImageFormat::from_extension::inner::h3342954c37fcf605", "image::io::format::ImageFormat::from_extension::inner::h3342954c37fcf605",
  ),
  (
    "_ZN4llvm31ARMBankConflictHazardRecognizerC1EPKNS_11ScheduleDAGExb", "llvm::ARMBankConflictHazardRecognizer::ARMBankConflictHazardRecognizer(llvm::ScheduleDAG const*, long long, bool)",
    "llvm::ARMBankConflictHazardRecognizer::ARMBankConflictHazardRecognizer",
  ),
  (
    "_ZN4mlir5spirv26GroupNonUniformShuffleUpOp17setExecutionScopeENS0_5ScopeE",
    "mlir::spirv::GroupNonUniformShuffleUpOp::setExecutionScope(mlir::spirv::Scope)",
    "mlir::spirv::GroupNonUniformShuffleUpOp::setExecutionScope",
  ),
  (
    "_ZN12_GLOBAL__N_130FoldInsertOfRankReducingInsertIN4mlir6tensor21ParallelInsertSliceOpEED1Ev",
    "(anonymous namespace)::FoldInsertOfRankReducingInsert<mlir::tensor::ParallelInsertSliceOp>::~FoldInsertOfRankReducingInsert()",
    "(anonymous namespace)::FoldInsertOfRankReducingInsert<mlir::tensor::ParallelInsertSliceOp>::~FoldInsertOfRankReducingInsert",
  ),
  (
    "_ZTIZN4mlir8intrange8inferAddEN4llvm8ArrayRefINS_17ConstantIntRangesEEENS0_13OverflowFlagsEE3$_1",
    "typeinfo for mlir::intrange::inferAdd(llvm::ArrayRef<mlir::ConstantIntRanges>, mlir::intrange::OverflowFlags)::$_1",
    "typeinfo for mlir::intrange::inferAdd(llvm::ArrayRef<mlir::ConstantIntRanges>, mlir::intrange::OverflowFlags)::$_1",
  ),
  (
    "_ZL23canScaleShuffleElementsN4llvm8ArrayRefIiEEj", "canScaleShuffleElements(llvm::ArrayRef<int>, unsigned int)",
    "canScaleShuffleElements",
  ),
  (
    "_ZN12rewriter_tplIZN3smt13model_checker22replace_value_from_ctxEP4exprE16beta_reducer_cfgE5visitILb0EEEbS3_j",
    "bool rewriter_tpl<smt::model_checker::replace_value_from_ctx(expr*)::beta_reducer_cfg>::visit<false>(expr*, unsigned int)",
    "rewriter_tpl<smt::model_checker::replace_value_from_ctx(expr*)::beta_reducer_cfg>::visit<false>",
  ),
  (
    "_ZN4mlir5ROCDL15WavefrontSizeOp20verifyInvariantsImplEv", "mlir::ROCDL::WavefrontSizeOp::verifyInvariantsImpl()",
    "mlir::ROCDL::WavefrontSizeOp::verifyInvariantsImpl",
  ),
  (
    "_ZN18cranelift_frontend3ssa10SSABuilder25declare_block_predecessor17h9480a6bb0ac406f1E",
    "cranelift_frontend::ssa::SSABuilder::declare_block_predecessor::h9480a6bb0ac406f1",
    "cranelift_frontend::ssa::SSABuilder::declare_block_predecessor::h9480a6bb0ac406f1",
  ),
  (
    "_ZN2v88internal6maglev24Int32ModulusWithOverflow12GenerateCodeEPNS1_15MaglevAssemblerERKNS1_15ProcessingStateE",
    "v8::internal::maglev::Int32ModulusWithOverflow::GenerateCode(v8::internal::maglev::MaglevAssembler*, v8::internal::maglev::ProcessingState const&)",
    "v8::internal::maglev::Int32ModulusWithOverflow::GenerateCode",
  ),
  (
    "_ZN4llvmL29DQuad_with_ssub_2SubClassMaskE", "llvm::DQuad_with_ssub_2SubClassMask",
    "llvm::DQuad_with_ssub_2SubClassMask",
  ),
  (
    "_ZN4mlir5spirv6detail29QueryExtensionInterfaceTraits5ModelINS0_8GLLog2OpEED1Ev",
    "mlir::spirv::detail::QueryExtensionInterfaceTraits::Model<mlir::spirv::GLLog2Op>::~Model()",
    "mlir::spirv::detail::QueryExtensionInterfaceTraits::Model<mlir::spirv::GLLog2Op>::~Model",
  ),
  (
    "_ZTVN4mlir5spirv6detail29QueryExtensionInterfaceTraits5ModelINS0_7GLFmaOpEEE",
    "vtable for mlir::spirv::detail::QueryExtensionInterfaceTraits::Model<mlir::spirv::GLFmaOp>",
    "vtable for mlir::spirv::detail::QueryExtensionInterfaceTraits::Model<mlir::spirv::GLFmaOp>",
  ),
  (
    "_ZTIN4mlir5spirv6detail30QueryMaxVersionInterfaceTraits5ModelINS0_16GLPackSnorm4x8OpEEE",
    "typeinfo for mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::GLPackSnorm4x8Op>",
    "typeinfo for mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::GLPackSnorm4x8Op>",
  ),
  (
    "_ZN4mlir5spirv6detail30QueryMaxVersionInterfaceTraits5ModelINS0_8CLUMinOpEED0Ev",
    "mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::CLUMinOp>::~Model()",
    "mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::CLUMinOp>::~Model",
  ),
  (
    "_ZN4mlir5spirv6detail30QueryMaxVersionInterfaceTraits5ModelINS0_8GLExp2OpEED1Ev",
    "mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::GLExp2Op>::~Model()",
    "mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::GLExp2Op>::~Model",
  ),
  (
    "_ZN4mlir5spirv6detail30QueryCapabilityInterfaceTraits5ModelINS0_9SNegateOpEED0Ev",
    "mlir::spirv::detail::QueryCapabilityInterfaceTraits::Model<mlir::spirv::SNegateOp>::~Model()",
    "mlir::spirv::detail::QueryCapabilityInterfaceTraits::Model<mlir::spirv::SNegateOp>::~Model",
  ),
  (
    "_ZN4mlir5quant13QuantizedType26castExpressedToStorageTypeENS_4TypeE", "mlir::quant::QuantizedType::castExpressedToStorageType(mlir::Type)",
    "mlir::quant::QuantizedType::castExpressedToStorageType",
  ),
  (
    "_ZTIN5clang12ast_matchers8internal10HasMatcherINS_8QualTypeES3_EE", "typeinfo for clang::ast_matchers::internal::HasMatcher<clang::QualType, clang::QualType>",
    "typeinfo for clang::ast_matchers::internal::HasMatcher<clang::QualType, clang::QualType>",
  ),
  (
    "_ZN4node9AsyncWrap19QueueDestroyAsyncIdERKN2v820FunctionCallbackInfoINS1_5ValueEEE.cold.1",
    "node::AsyncWrap::QueueDestroyAsyncId(v8::FunctionCallbackInfo<v8::Value> const&) (.cold.1)",
    "node::AsyncWrap::QueueDestroyAsyncId",
  ),
  (
    "_ZTINSt3__110__function6__funcIZL19isRegisterClassTypeRKN4llvm12GCNSubtargetEjE3$_0FbRKNS2_13LegalityQueryEEEE",
    "typeinfo for std::__1::__function::__func<isRegisterClassType(llvm::GCNSubtarget const&, unsigned int)::$_0, bool (llvm::LegalityQuery const&)>",
    "typeinfo for std::__1::__function::__func<isRegisterClassType(llvm::GCNSubtarget const&, unsigned int)::$_0, bool (llvm::LegalityQuery const&)>",
  ),
  (
    "_ZN5clang6interp8CompilerINS0_15ByteCodeEmitterEE9getRecordENS_8QualTypeE",
    "clang::interp::Compiler<clang::interp::ByteCodeEmitter>::getRecord(clang::QualType)",
    "clang::interp::Compiler<clang::interp::ByteCodeEmitter>::getRecord",
  ),
  (
    "_ZN4llvm14SparcInstrInfo6anchorEv", "llvm::SparcInstrInfo::anchor()", "llvm::SparcInstrInfo::anchor",
  ),
  (
    "_ZN4llvm8FastISel19selectIntrinsicCallEPKNS_13IntrinsicInstE", "llvm::FastISel::selectIntrinsicCall(llvm::IntrinsicInst const*)",
    "llvm::FastISel::selectIntrinsicCall",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_3acc18GlobalDestructorOpEE8hasTraitENS_6TypeIDE",
    "mlir::RegisteredOperationName::Model<mlir::acc::GlobalDestructorOp>::hasTrait(mlir::TypeID)",
    "mlir::RegisteredOperationName::Model<mlir::acc::GlobalDestructorOp>::hasTrait",
  ),
  (
    "_ZN4core5slice4sort6shared9smallsort12sort8_stable17h14b490b80d8849a3E", "core::slice::sort::shared::smallsort::sort8_stable::h14b490b80d8849a3",
    "core::slice::sort::shared::smallsort::sort8_stable::h14b490b80d8849a3",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_9transform21MatchStructuredInitOpEED1Ev",
    "mlir::RegisteredOperationName::Model<mlir::transform::MatchStructuredInitOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::transform::MatchStructuredInitOp>::~Model",
  ),
  (
    "_ZN2v88internal8compilerlsERNSt3__113basic_ostreamIcNS2_11char_traitsIcEEEERKNS1_16AsScheduledGraphE",
    "v8::internal::compiler::operator<<(std::__1::basic_ostream<char, std::__1::char_traits<char>>&, v8::internal::compiler::AsScheduledGraph const&)",
    "v8::internal::compiler::operator<<",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5ROCDL22CvtPkScalePk16F16Fp6OpEE16verifyInvariantsEPNS_9OperationE",
    "mlir::RegisteredOperationName::Model<mlir::ROCDL::CvtPkScalePk16F16Fp6Op>::verifyInvariants(mlir::Operation*)",
    "mlir::RegisteredOperationName::Model<mlir::ROCDL::CvtPkScalePk16F16Fp6Op>::verifyInvariants",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_6affine10AffineIfOpEE18getParseAssemblyFnEv",
    "mlir::RegisteredOperationName::Model<mlir::affine::AffineIfOp>::getParseAssemblyFn()",
    "mlir::RegisteredOperationName::Model<mlir::affine::AffineIfOp>::getParseAssemblyFn",
  ),
  (
    "_ZN14inc_sat_solver18register_on_clauseEPvRNSt3__18functionIFvS0_P4exprjPKjjPKS4_EEE",
    "inc_sat_solver::register_on_clause(void*, std::__1::function<void (void*, expr*, unsigned int, unsigned int const*, unsigned int, expr* const*)>&)",
    "inc_sat_solver::register_on_clause",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_3smt8RepeatOpEE15getInherentAttrEPNS_9OperationEN4llvm9StringRefE",
    "mlir::RegisteredOperationName::Model<mlir::smt::RepeatOp>::getInherentAttr(mlir::Operation*, llvm::StringRef)",
    "mlir::RegisteredOperationName::Model<mlir::smt::RepeatOp>::getInherentAttr",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_7arm_sve20ScalableMaskedAddIOpEE8hasTraitENS_6TypeIDE",
    "mlir::RegisteredOperationName::Model<mlir::arm_sve::ScalableMaskedAddIOp>::hasTrait(mlir::TypeID)",
    "mlir::RegisteredOperationName::Model<mlir::arm_sve::ScalableMaskedAddIOp>::hasTrait",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_3scf12InParallelOpEE8hasTraitENS_6TypeIDE",
    "mlir::RegisteredOperationName::Model<mlir::scf::InParallelOp>::hasTrait(mlir::TypeID)",
    "mlir::RegisteredOperationName::Model<mlir::scf::InParallelOp>::hasTrait",
  ),
  (
    "_ZN2v88internal8compiler13CodeAssembler12I8x16BitMaskENS0_5TNodeINS0_6I8x16TEEE",
    "v8::internal::compiler::CodeAssembler::I8x16BitMask(v8::internal::TNode<v8::internal::I8x16T>)",
    "v8::internal::compiler::CodeAssembler::I8x16BitMask",
  ),
  (
    "_ZN4mlir6linalg16PoolingNchwMaxOp10getStridesEv", "mlir::linalg::PoolingNchwMaxOp::getStrides()",
    "mlir::linalg::PoolingNchwMaxOp::getStrides",
  ),
  (
    "_ZN2v88internal8compiler18CodeAssemblerState26SetInitialDebugInformationEPKcS4_i",
    "v8::internal::compiler::CodeAssemblerState::SetInitialDebugInformation(char const*, char const*, int)",
    "v8::internal::compiler::CodeAssemblerState::SetInitialDebugInformation",
  ),
  (
    "_ZN2v88internal4Heap25GarbageCollectionPrologueENS0_23GarbageCollectionReasonENS_15GCCallbackFlagsE",
    "v8::internal::Heap::GarbageCollectionPrologue(v8::internal::GarbageCollectionReason, v8::GCCallbackFlags)",
    "v8::internal::Heap::GarbageCollectionPrologue",
  ),
  (
    "_ZN12lldb_private13FuncUnwinders23GetSymbolFileUnwindPlanERNS_6ThreadE", "lldb_private::FuncUnwinders::GetSymbolFileUnwindPlan(lldb_private::Thread&)",
    "lldb_private::FuncUnwinders::GetSymbolFileUnwindPlan",
  ),
  (
    "_ZNK2v88internal9ScopeInfo22IsWrappedFunctionScopeEv", "v8::internal::ScopeInfo::IsWrappedFunctionScope() const",
    "v8::internal::ScopeInfo::IsWrappedFunctionScope",
  ),
  (
    "_ZN2v88internal20MarkCompactCollector24ProcessOldCodeCandidatesEv", "v8::internal::MarkCompactCollector::ProcessOldCodeCandidates()",
    "v8::internal::MarkCompactCollector::ProcessOldCodeCandidates",
  ),
  (
    "_ZN2v88internal14MacroAssembler4CallENS0_17ExternalReferenceE", "v8::internal::MacroAssembler::Call(v8::internal::ExternalReference)",
    "v8::internal::MacroAssembler::Call",
  ),
  (
    "_ZN2v88internal11FactoryBaseINS0_7FactoryEE16latin1_9e_stringEv", "v8::internal::FactoryBase<v8::internal::Factory>::latin1_9e_string()",
    "v8::internal::FactoryBase<v8::internal::Factory>::latin1_9e_string",
  ),
  (
    "_ZN2v88internal14MacroAssembler14DefaultTmpListEv", "v8::internal::MacroAssembler::DefaultTmpList()",
    "v8::internal::MacroAssembler::DefaultTmpList",
  ),
  (
    "_ZN2v88internal17HeapNumberRequestC1Edi", "v8::internal::HeapNumberRequest::HeapNumberRequest(double, int)",
    "v8::internal::HeapNumberRequest::HeapNumberRequest",
  ),
  (
    "_ZN35GetMemberenable_sgpr_workgroup_id_z5PhonyE", "GetMemberenable_sgpr_workgroup_id_z::Phony",
    "GetMemberenable_sgpr_workgroup_id_z::Phony",
  ),
  (
    "_ZN2v811HandleScopedaEPvm", "v8::HandleScope::operator delete[](void*, unsigned long)",
    "v8::HandleScope::operator delete[]",
  ),
  (
    "_ZN5clang17MultiplexConsumer31HandleTagDeclRequiredDefinitionEPKNS_7TagDeclE",
    "clang::MultiplexConsumer::HandleTagDeclRequiredDefinition(clang::TagDecl const*)",
    "clang::MultiplexConsumer::HandleTagDeclRequiredDefinition",
  ),
  (
    "_ZN4mlir5async27RuntimeCreateGroupOpAdaptor6verifyENS_8LocationE", "mlir::async::RuntimeCreateGroupOpAdaptor::verify(mlir::Location)",
    "mlir::async::RuntimeCreateGroupOpAdaptor::verify",
  ),
  (
    "_ZN6vectorIN12symbol_tableIN4smt26parser5localEE8key_dataELb1EjE9push_backERKS5_",
    "vector<symbol_table<smt2::parser::local>::key_data, true, unsigned int>::push_back(symbol_table<smt2::parser::local>::key_data const&)",
    "vector<symbol_table<smt2::parser::local>::key_data, true, unsigned int>::push_back",
  ),
  (
    "_ZN4llvm10Attributor14shouldUpdateAAINS_16AAMemoryBehaviorEEEbRKNS_10IRPositionE",
    "bool llvm::Attributor::shouldUpdateAA<llvm::AAMemoryBehavior>(llvm::IRPosition const&)",
    "llvm::Attributor::shouldUpdateAA<llvm::AAMemoryBehavior>",
  ),
  (
    "_ZN14core_hashtableIN14obj_triple_mapI3appS1_S1_jE5entryE8obj_hashINS2_8key_dataEE10default_eqIS5_EED2Ev",
    "core_hashtable<obj_triple_map<app, app, app, unsigned int>::entry, obj_hash<obj_triple_map<app, app, app, unsigned int>::key_data>, default_eq<obj_triple_map<app, app, app, unsigned int>::key_data>>::~core_hashtable()",
    "core_hashtable<obj_triple_map<app, app, app, unsigned int>::entry, obj_hash<obj_triple_map<app, app, app, unsigned int>::key_data>, default_eq<obj_triple_map<app, app, app, unsigned int>::key_data>>::~core_hashtable",
  ),
  (
    "_ZN4mlir3ptr9ScatterOp21computePropertiesHashERKNS0_6detail27ScatterOpGenericAdaptorBase10PropertiesE",
    "mlir::ptr::ScatterOp::computePropertiesHash(mlir::ptr::detail::ScatterOpGenericAdaptorBase::Properties const&)",
    "mlir::ptr::ScatterOp::computePropertiesHash",
  ),
  (
    "_ZN4llvm31install_bad_alloc_error_handlerEPFvPvPKcbES0_", "llvm::install_bad_alloc_error_handler(void (*)(void*, char const*, bool), void*)",
    "llvm::install_bad_alloc_error_handler",
  ),
  (
    "_ZN4mlir6detail14TypeIDResolverINS_4irdl9ResultsOpEvE2idE", "mlir::detail::TypeIDResolver<mlir::irdl::ResultsOp, void>::id",
    "mlir::detail::TypeIDResolver<mlir::irdl::ResultsOp, void>::id",
  ),
  (
    "_ZN4mlir5spirv10ConstantOp4foldENS0_24ConstantOpGenericAdaptorIN4llvm8ArrayRefINS_9AttributeEEEEE",
    "mlir::spirv::ConstantOp::fold(mlir::spirv::ConstantOpGenericAdaptor<llvm::ArrayRef<mlir::Attribute>>)",
    "mlir::spirv::ConstantOp::fold",
  ),
  (
    "_ZTVN4llvm16itanium_demangle10LambdaExprE", "vtable for llvm::itanium_demangle::LambdaExpr",
    "vtable for llvm::itanium_demangle::LambdaExpr",
  ),
  (
    "_ZN7datalog30finite_product_relation_plugin19converting_union_fnD1Ev", "datalog::finite_product_relation_plugin::converting_union_fn::~converting_union_fn()",
    "datalog::finite_product_relation_plugin::converting_union_fn::~converting_union_fn",
  ),
  (
    "_ZN4node8builtinsL12dns_resourceE", "node::builtins::dns_resource", "node::builtins::dns_resource",
  ),
  (
    "_ZN4llvm21SparcGenSubtargetInfoD1Ev", "llvm::SparcGenSubtargetInfo::~SparcGenSubtargetInfo()",
    "llvm::SparcGenSubtargetInfo::~SparcGenSubtargetInfo",
  ),
  ("_ZL19BuiltinAArch64Infos", "BuiltinAArch64Infos", "BuiltinAArch64Infos"),
  (
    "_ZN4llvm15OpenMPIRBuilder20getOrCreateSrcLocStrENS_9StringRefERj", "llvm::OpenMPIRBuilder::getOrCreateSrcLocStr(llvm::StringRef, unsigned int&)",
    "llvm::OpenMPIRBuilder::getOrCreateSrcLocStr",
  ),
  (
    "_ZTIZN4llvm20AArch64TargetMachine28registerPassBuilderCallbacksERNS_11PassBuilderEE3$_1",
    "typeinfo for llvm::AArch64TargetMachine::registerPassBuilderCallbacks(llvm::PassBuilder&)::$_1",
    "typeinfo for llvm::AArch64TargetMachine::registerPassBuilderCallbacks(llvm::PassBuilder&)::$_1",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_3acc12DataBoundsOpEE22verifyRegionInvariantsEPNS_9OperationE",
    "mlir::RegisteredOperationName::Model<mlir::acc::DataBoundsOp>::verifyRegionInvariants(mlir::Operation*)",
    "mlir::RegisteredOperationName::Model<mlir::acc::DataBoundsOp>::verifyRegionInvariants",
  ),
  (
    "_ZN4mlir6vector22getVectorSubscriptAttrERNS_7BuilderEN4llvm8ArrayRefIxEE", "mlir::vector::getVectorSubscriptAttr(mlir::Builder&, llvm::ArrayRef<long long>)",
    "mlir::vector::getVectorSubscriptAttr",
  ),
  (
    "_ZN4llvm22AArch64BuildAttributes17getPauthABITagsIDENS_9StringRefE", "llvm::AArch64BuildAttributes::getPauthABITagsID(llvm::StringRef)",
    "llvm::AArch64BuildAttributes::getPauthABITagsID",
  ),
  (
    "_ZTIN4mlir23RegisteredOperationName5ModelINS_7arm_sme23aarch64_sme_sumops_wideEEE",
    "typeinfo for mlir::RegisteredOperationName::Model<mlir::arm_sme::aarch64_sme_sumops_wide>",
    "typeinfo for mlir::RegisteredOperationName::Model<mlir::arm_sme::aarch64_sme_sumops_wide>",
  ),
  (
    "_ZN4llvmL45AV_288_with_sub6_in_VGPR_32_Lo256SuperclassesE", "llvm::AV_288_with_sub6_in_VGPR_32_Lo256Superclasses",
    "llvm::AV_288_with_sub6_in_VGPR_32_Lo256Superclasses",
  ),
  (
    "_ZNK4mlir6affine12MemRefAccesseqERKS1_", "mlir::affine::MemRefAccess::operator==(mlir::affine::MemRefAccess const&) const",
    "mlir::affine::MemRefAccess::operator==",
  ),
  (
    "_ZN4mlir7arm_sme21aarch64_sme_mops_wide20verifyInvariantsImplEv", "mlir::arm_sme::aarch64_sme_mops_wide::verifyInvariantsImpl()",
    "mlir::arm_sme::aarch64_sme_mops_wide::verifyInvariantsImpl",
  ),
  (
    "_ZN5clang9ParentMap9setParentEPKNS_4StmtES3_", "clang::ParentMap::setParent(clang::Stmt const*, clang::Stmt const*)",
    "clang::ParentMap::setParent",
  ),
  (
    "_ZN5clang6interp13GetPtrBasePopERNS0_11InterpStateENS0_7CodePtrEjb", "clang::interp::GetPtrBasePop(clang::interp::InterpState&, clang::interp::CodePtr, unsigned int, bool)",
    "clang::interp::GetPtrBasePop",
  ),
  (
    "_ZN5clang4ento16EnvironmentEntryC1EPKNS_4StmtEPKNS_15LocationContextE", "clang::ento::EnvironmentEntry::EnvironmentEntry(clang::Stmt const*, clang::LocationContext const*)",
    "clang::ento::EnvironmentEntry::EnvironmentEntry",
  ),
  (
    "_ZN4mlir3omp15DeclareMapperOp6createERNS_20ImplicitLocOpBuilderENS_9TypeRangeEN4llvm9StringRefENS_4TypeE",
    "mlir::omp::DeclareMapperOp::create(mlir::ImplicitLocOpBuilder&, mlir::TypeRange, llvm::StringRef, mlir::Type)",
    "mlir::omp::DeclareMapperOp::create",
  ),
  (
    "_ZN5clang13DeclFilterCCCINS_12FunctionDeclEE5cloneEv", "clang::DeclFilterCCC<clang::FunctionDecl>::clone()",
    "clang::DeclFilterCCC<clang::FunctionDecl>::clone",
  ),
  (
    "_ZN5clang9MSAsmStmt12setInputExprEjPNS_4ExprE", "clang::MSAsmStmt::setInputExpr(unsigned int, clang::Expr*)",
    "clang::MSAsmStmt::setInputExpr",
  ),
  (
    "_ZNK4llvm2cl3optINS_21ReplayInlinerSettings5ScopeELb0ENS0_6parserIS3_EEE14getOptionWidthEv",
    "llvm::cl::opt<llvm::ReplayInlinerSettings::Scope, false, llvm::cl::parser<llvm::ReplayInlinerSettings::Scope>>::getOptionWidth() const",
    "llvm::cl::opt<llvm::ReplayInlinerSettings::Scope, false, llvm::cl::parser<llvm::ReplayInlinerSettings::Scope>>::getOptionWidth",
  ),
  (
    "_ZNK4mlir4impl23GpuNVVMAttachTargetBaseIN12_GLOBAL__N_116NVVMAttachTargetEE9clonePassEv",
    "mlir::impl::GpuNVVMAttachTargetBase<(anonymous namespace)::NVVMAttachTarget>::clonePass() const",
    "mlir::impl::GpuNVVMAttachTargetBase<(anonymous namespace)::NVVMAttachTarget>::clonePass",
  ),
  (
    "_ZN5clang4Sema27ActOnFinishDelayedAttributeEPNS_5ScopeEPNS_4DeclERNS_16ParsedAttributesE",
    "clang::Sema::ActOnFinishDelayedAttribute(clang::Scope*, clang::Decl*, clang::ParsedAttributes&)",
    "clang::Sema::ActOnFinishDelayedAttribute",
  ),
  (
    "_ZTVN5clang6interp5StateE", "vtable for clang::interp::State", "vtable for clang::interp::State",
  ),
  (
    "_ZNSt3__110__function6__funcIPFPcPKcENS_9allocatorIS6_EES5_EclEOS4_", "std::__1::__function::__func<char* (*)(char const*), std::__1::allocator<char* (*)(char const*)>, char* (char const*)>::operator()(char const*&&)",
    "std::__1::__function::__func<char* (*)(char const*), std::__1::allocator<char* (*)(char const*)>, char* (char const*)>::operator()",
  ),
  (
    "_ZN11ast_manager12mk_func_declERK6symboljPKP4sortS4_P14func_decl_info", "ast_manager::mk_func_decl(symbol const&, unsigned int, sort* const*, sort*, func_decl_info*)",
    "ast_manager::mk_func_decl",
  ),
  (
    "_ZN14set_option_cmd21check_not_initializedER11cmd_contextRK6symbol", "set_option_cmd::check_not_initialized(cmd_context&, symbol const&)",
    "set_option_cmd::check_not_initialized",
  ),
  (
    "_ZN12lldb_private16AppleObjCRuntime25ClearExceptionBreakpointsEv", "lldb_private::AppleObjCRuntime::ClearExceptionBreakpoints()",
    "lldb_private::AppleObjCRuntime::ClearExceptionBreakpoints",
  ),
  (
    "_ZL22createHexagonMCAsmInfoRKN4llvm14MCRegisterInfoERKNS_6TripleERKNS_15MCTargetOptionsE",
    "createHexagonMCAsmInfo(llvm::MCRegisterInfo const&, llvm::Triple const&, llvm::MCTargetOptions const&)",
    "createHexagonMCAsmInfo",
  ),
  (
    "_ZNSt3__120__shared_ptr_emplaceIN12_GLOBAL__N_115SequenceStencilENS_9allocatorIS2_EEE16__on_zero_sharedEv",
    "std::__1::__shared_ptr_emplace<(anonymous namespace)::SequenceStencil, std::__1::allocator<(anonymous namespace)::SequenceStencil>>::__on_zero_shared()",
    "std::__1::__shared_ptr_emplace<(anonymous namespace)::SequenceStencil, std::__1::allocator<(anonymous namespace)::SequenceStencil>>::__on_zero_shared",
  ),
  (
    "_ZN4mlir3ptr8PtrAddOp5buildERNS_9OpBuilderERNS_14OperationStateENS_5ValueES6_NS0_11PtrAddFlagsE",
    "mlir::ptr::PtrAddOp::build(mlir::OpBuilder&, mlir::OperationState&, mlir::Value, mlir::Value, mlir::ptr::PtrAddFlags)",
    "mlir::ptr::PtrAddOp::build",
  ),
  (
    "_ZTSN10polynomial20polynomial_exceptionE", "typeinfo name for polynomial::polynomial_exception",
    "typeinfo name for polynomial::polynomial_exception",
  ),
  (
    "_ZN2v88internal6maglev20MaglevGraphOptimizer7ProcessEPNS1_15Float64SubtractERKNS1_15ProcessingStateE",
    "v8::internal::maglev::MaglevGraphOptimizer::Process(v8::internal::maglev::Float64Subtract*, v8::internal::maglev::ProcessingState const&)",
    "v8::internal::maglev::MaglevGraphOptimizer::Process",
  ),
  (
    "_ZNK2v88internal8compiler17TypedOptimization5graphEv", "v8::internal::compiler::TypedOptimization::graph() const",
    "v8::internal::compiler::TypedOptimization::graph",
  ),
  (
    "_ZN2v88internal6maglev20MaglevGraphOptimizer7ProcessEPNS1_10LoadGlobalERKNS1_15ProcessingStateE",
    "v8::internal::maglev::MaglevGraphOptimizer::Process(v8::internal::maglev::LoadGlobal*, v8::internal::maglev::ProcessingState const&)",
    "v8::internal::maglev::MaglevGraphOptimizer::Process",
  ),
  (
    "_ZN4mlir5ROCDL6detail39RawBufferAtomicFMaxOpGenericAdaptorBaseC1ENS0_21RawBufferAtomicFMaxOpE",
    "mlir::ROCDL::detail::RawBufferAtomicFMaxOpGenericAdaptorBase::RawBufferAtomicFMaxOpGenericAdaptorBase(mlir::ROCDL::RawBufferAtomicFMaxOp)",
    "mlir::ROCDL::detail::RawBufferAtomicFMaxOpGenericAdaptorBase::RawBufferAtomicFMaxOpGenericAdaptorBase",
  ),
  (
    "_ZN4mlir4tosa6detail26RFFT2dOpGenericAdaptorBaseC1ENS0_8RFFT2dOpE", "mlir::tosa::detail::RFFT2dOpGenericAdaptorBase::RFFT2dOpGenericAdaptorBase(mlir::tosa::RFFT2dOp)",
    "mlir::tosa::detail::RFFT2dOpGenericAdaptorBase::RFFT2dOpGenericAdaptorBase",
  ),
  (
    "_ZN4mlir4NVVM6detail40ConvertF32x2ToBF16x2OpGenericAdaptorBase11getReluAttrEv",
    "mlir::NVVM::detail::ConvertF32x2ToBF16x2OpGenericAdaptorBase::getReluAttr()",
    "mlir::NVVM::detail::ConvertF32x2ToBF16x2OpGenericAdaptorBase::getReluAttr",
  ),
  (
    "_ZN11fail_tacticclERK3refI4goalER11sref_bufferIS1_Lj16EE", "fail_tactic::operator()(ref<goal> const&, sref_buffer<goal, 16u>&)",
    "fail_tactic::operator()",
  ),
  (
    "_ZN4mlir3gpu16SetCsrPointersOp6createERNS_9OpBuilderENS_8LocationENS_4TypeENS_10ValueRangeENS_5ValueES7_S7_S7_",
    "mlir::gpu::SetCsrPointersOp::create(mlir::OpBuilder&, mlir::Location, mlir::Type, mlir::ValueRange, mlir::Value, mlir::Value, mlir::Value, mlir::Value)",
    "mlir::gpu::SetCsrPointersOp::create",
  ),
  ("_ZL13g_csr_regnums", "g_csr_regnums", "g_csr_regnums"),
  (
    "_ZN9fm_tacticclERK3refI4goalER11sref_bufferIS1_Lj16EE", "fm_tactic::operator()(ref<goal> const&, sref_buffer<goal, 16u>&)",
    "fm_tactic::operator()",
  ),
  (
    "_ZN4llvm16HexagonSubtarget19UsrOverflowMutation5applyEPNS_17ScheduleDAGInstrsE",
    "llvm::HexagonSubtarget::UsrOverflowMutation::apply(llvm::ScheduleDAGInstrs*)",
    "llvm::HexagonSubtarget::UsrOverflowMutation::apply",
  ),
  (
    "_ZN4mlir6detail31OpAsmOpInterfaceInterfaceTraits5ModelINS_3gpu11CreateBsrOpEE17getDefaultDialectEv",
    "mlir::detail::OpAsmOpInterfaceInterfaceTraits::Model<mlir::gpu::CreateBsrOp>::getDefaultDialect()",
    "mlir::detail::OpAsmOpInterfaceInterfaceTraits::Model<mlir::gpu::CreateBsrOp>::getDefaultDialect",
  ),
  (
    "_ZN4mlir5ROCDL16MakeBufferRsrcOp5parseERNS_11OpAsmParserERNS_14OperationStateE",
    "mlir::ROCDL::MakeBufferRsrcOp::parse(mlir::OpAsmParser&, mlir::OperationState&)",
    "mlir::ROCDL::MakeBufferRsrcOp::parse",
  ),
  (
    "_ZN18qfufbv_ackr_tacticclERK3refI4goalER11sref_bufferIS1_Lj16EE", "qfufbv_ackr_tactic::operator()(ref<goal> const&, sref_buffer<goal, 16u>&)",
    "qfufbv_ackr_tactic::operator()",
  ),
  (
    "_ZN3smt17theory_diff_logicINS_8srdl_extEE5valueEi", "smt::theory_diff_logic<smt::srdl_ext>::value(int)",
    "smt::theory_diff_logic<smt::srdl_ext>::value",
  ),
  (
    "_ZN6vectorIPN3smt17theory_diff_logicINS0_8srdl_extEE4atomELb0EjED2Ev", "vector<smt::theory_diff_logic<smt::srdl_ext>::atom*, false, unsigned int>::~vector()",
    "vector<smt::theory_diff_logic<smt::srdl_ext>::atom*, false, unsigned int>::~vector",
  ),
  (
    "_ZN15parallel_tacticclERK3refI4goalER11sref_bufferIS1_Lj16EE", "parallel_tactic::operator()(ref<goal> const&, sref_buffer<goal, 16u>&)",
    "parallel_tactic::operator()",
  ),
  (
    "_ZTSN4llvm16HexagonSubtarget19UsrOverflowMutationE", "typeinfo name for llvm::HexagonSubtarget::UsrOverflowMutation",
    "typeinfo name for llvm::HexagonSubtarget::UsrOverflowMutation",
  ),
  (
    "_ZN4llvm3pdb24ConcreteSymbolEnumeratorINS0_24PDBSymbolTypeFunctionArgEE5resetEv",
    "llvm::pdb::ConcreteSymbolEnumerator<llvm::pdb::PDBSymbolTypeFunctionArg>::reset()",
    "llvm::pdb::ConcreteSymbolEnumerator<llvm::pdb::PDBSymbolTypeFunctionArg>::reset",
  ),
  (
    "_ZTSN12lldb_private21ClangExpressionParser25LLDBPreprocessorCallbacksE", "typeinfo name for lldb_private::ClangExpressionParser::LLDBPreprocessorCallbacks",
    "typeinfo name for lldb_private::ClangExpressionParser::LLDBPreprocessorCallbacks",
  ),
  (
    "_ZN4llvm3pdb14PDBFileBuilder20commitSrcHeaderBlockERNS_20WritableBinaryStreamERKNS_3msf9MSFLayoutE",
    "llvm::pdb::PDBFileBuilder::commitSrcHeaderBlock(llvm::WritableBinaryStream&, llvm::msf::MSFLayout const&)",
    "llvm::pdb::PDBFileBuilder::commitSrcHeaderBlock",
  ),
  (
    "_ZNK4llvm3pdb24ConcreteSymbolEnumeratorINS0_20PDBSymbolTypePointerEE13getChildCountEv",
    "llvm::pdb::ConcreteSymbolEnumerator<llvm::pdb::PDBSymbolTypePointer>::getChildCount() const",
    "llvm::pdb::ConcreteSymbolEnumerator<llvm::pdb::PDBSymbolTypePointer>::getChildCount",
  ),
  (
    "_ZN4llvm3pdb14PDBFileBuilder19allocateNamedStreamENS_9StringRefEj", "llvm::pdb::PDBFileBuilder::allocateNamedStream(llvm::StringRef, unsigned int)",
    "llvm::pdb::PDBFileBuilder::allocateNamedStream",
  ),
  (
    "_ZNK12_GLOBAL__N_119LLDBGenericCategory7messageEi", "(anonymous namespace)::LLDBGenericCategory::message(int) const",
    "(anonymous namespace)::LLDBGenericCategory::message",
  ),
  (
    "_ZN12lldb_private18process_gdb_remote28GDBRemoteCommunicationClient12ReadRegisterEyj",
    "lldb_private::process_gdb_remote::GDBRemoteCommunicationClient::ReadRegister(unsigned long long, unsigned int)",
    "lldb_private::process_gdb_remote::GDBRemoteCommunicationClient::ReadRegister",
  ),
  (
    "_ZN12lldb_private18process_gdb_remote16ProcessGDBRemote19GetImageInfoAddressEv",
    "lldb_private::process_gdb_remote::ProcessGDBRemote::GetImageInfoAddress()",
    "lldb_private::process_gdb_remote::ProcessGDBRemote::GetImageInfoAddress",
  ),
  (
    "_ZTSN4llvm3pdb24ConcreteSymbolEnumeratorINS0_21PDBSymbolCompilandEnvEEE", "typeinfo name for llvm::pdb::ConcreteSymbolEnumerator<llvm::pdb::PDBSymbolCompilandEnv>",
    "typeinfo name for llvm::pdb::ConcreteSymbolEnumerator<llvm::pdb::PDBSymbolCompilandEnv>",
  ),
  (
    "_ZN4llvm9MDBuilder23createTBAAStructTagNodeEPNS_6MDNodeES2_yb", "llvm::MDBuilder::createTBAAStructTagNode(llvm::MDNode*, llvm::MDNode*, unsigned long long, bool)",
    "llvm::MDBuilder::createTBAAStructTagNode",
  ),
  (
    "_ZN4llvm9MDBuilder21createPseudoProbeDescEyyNS_9StringRefE", "llvm::MDBuilder::createPseudoProbeDesc(unsigned long long, unsigned long long, llvm::StringRef)",
    "llvm::MDBuilder::createPseudoProbeDesc",
  ),
  (
    "_ZTIN4llvm3pdb20PDBSymbolTypeBuiltinE", "typeinfo for llvm::pdb::PDBSymbolTypeBuiltin",
    "typeinfo for llvm::pdb::PDBSymbolTypeBuiltin",
  ),
  (
    "_ZTIN12_GLOBAL__N_124DropLinearizeLeadingZeroE", "typeinfo for (anonymous namespace)::DropLinearizeLeadingZero",
    "typeinfo for (anonymous namespace)::DropLinearizeLeadingZero",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5spirv9GLLdexpOpEE17comparePropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::spirv::GLLdexpOp>::compareProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::spirv::GLLdexpOp>::compareProperties",
  ),
  (
    "_ZNK5clang8LeafAttr11getSpellingEv", "clang::LeafAttr::getSpelling() const",
    "clang::LeafAttr::getSpelling",
  ),
  (
    "_ZN2v88internal6maglev18MaglevGraphBuilder13VisitLdaFalseEv", "v8::internal::maglev::MaglevGraphBuilder::VisitLdaFalse()",
    "v8::internal::maglev::MaglevGraphBuilder::VisitLdaFalse",
  ),
  (
    "_ZN5clang30DynamicRecursiveASTVisitorBaseILb1EE22WalkUpFromSEHLeaveStmtEPKNS_12SEHLeaveStmtE",
    "clang::DynamicRecursiveASTVisitorBase<true>::WalkUpFromSEHLeaveStmt(clang::SEHLeaveStmt const*)",
    "clang::DynamicRecursiveASTVisitorBase<true>::WalkUpFromSEHLeaveStmt",
  ),
  (
    "_ZN4mlir6detail14TypeIDResolverINS_5emitc18BitwiseLeftShiftOpEvE2idE", "mlir::detail::TypeIDResolver<mlir::emitc::BitwiseLeftShiftOp, void>::id",
    "mlir::detail::TypeIDResolver<mlir::emitc::BitwiseLeftShiftOp, void>::id",
  ),
  (
    "_ZNK4llvm18SuffixTreeLeafNode9getEndIdxEv", "llvm::SuffixTreeLeafNode::getEndIdx() const",
    "llvm::SuffixTreeLeafNode::getEndIdx",
  ),
  (
    "_ZN2v88internal8compiler16JSBinopReduction11LeftInputIsENS1_4TypeE", "v8::internal::compiler::JSBinopReduction::LeftInputIs(v8::internal::compiler::Type)",
    "v8::internal::compiler::JSBinopReduction::LeftInputIs",
  ),
  (
    "_ZN4mlir6detail14TypeIDResolverINS_4LLVM19CountLeadingZerosOpEvE2idE", "mlir::detail::TypeIDResolver<mlir::LLVM::CountLeadingZerosOp, void>::id",
    "mlir::detail::TypeIDResolver<mlir::LLVM::CountLeadingZerosOp, void>::id",
  ),
  (
    "_ZN5cppgc6subtle30DisallowGarbageCollectionScope5LeaveERNS_10HeapHandleE", "cppgc::subtle::DisallowGarbageCollectionScope::Leave(cppgc::HeapHandle&)",
    "cppgc::subtle::DisallowGarbageCollectionScope::Leave",
  ),
  (
    "_ZN5clang12Preprocessor34PropagateLineStartLeadingSpaceInfoERNS_5TokenE", "clang::Preprocessor::PropagateLineStartLeadingSpaceInfo(clang::Token&)",
    "clang::Preprocessor::PropagateLineStartLeadingSpaceInfo",
  ),
  (
    "_ZN2v88internal6maglev18MaglevGraphBuilder24VisitLdaLookupGlobalSlotEv", "v8::internal::maglev::MaglevGraphBuilder::VisitLdaLookupGlobalSlot()",
    "v8::internal::maglev::MaglevGraphBuilder::VisitLdaLookupGlobalSlot",
  ),
  (
    "_ZN4llvm4yaml23ScalarEnumerationTraitsINS_7ELFYAML10ELF_DYNTAGEvE11enumerationERNS0_2IOERS3_",
    "llvm::yaml::ScalarEnumerationTraits<llvm::ELFYAML::ELF_DYNTAG, void>::enumeration(llvm::yaml::IO&, llvm::ELFYAML::ELF_DYNTAG&)",
    "llvm::yaml::ScalarEnumerationTraits<llvm::ELFYAML::ELF_DYNTAG, void>::enumeration",
  ),
  (
    "_ZN4llvm7ELFYAML20ARMIndexTableSectionD1Ev", "llvm::ELFYAML::ARMIndexTableSection::~ARMIndexTableSection()",
    "llvm::ELFYAML::ARMIndexTableSection::~ARMIndexTableSection",
  ),
  (
    "_ZNSt3__16vectorIN4llvm9DWARFYAML12RnglistEntryENS_9allocatorIS3_EEE13__vdeallocateEv",
    "std::__1::vector<llvm::DWARFYAML::RnglistEntry, std::__1::allocator<llvm::DWARFYAML::RnglistEntry>>::__vdeallocate()",
    "std::__1::vector<llvm::DWARFYAML::RnglistEntry, std::__1::allocator<llvm::DWARFYAML::RnglistEntry>>::__vdeallocate",
  ),
  (
    "_ZN4llvm4yaml13MappingTraitsINS_9DWARFYAML16ARangeDescriptorEE7mappingERNS0_2IOERS3_",
    "llvm::yaml::MappingTraits<llvm::DWARFYAML::ARangeDescriptor>::mapping(llvm::yaml::IO&, llvm::DWARFYAML::ARangeDescriptor&)",
    "llvm::yaml::MappingTraits<llvm::DWARFYAML::ARangeDescriptor>::mapping",
  ),
  (
    "_ZTVN4llvm7ELFYAML20ARMIndexTableSectionE", "vtable for llvm::ELFYAML::ARMIndexTableSection",
    "vtable for llvm::ELFYAML::ARMIndexTableSection",
  ),
  (
    "_ZTIN4llvm7ELFYAML14AddrsigSectionE", "typeinfo for llvm::ELFYAML::AddrsigSection",
    "typeinfo for llvm::ELFYAML::AddrsigSection",
  ),
  (
    "_ZN4llvm4yaml23ScalarEnumerationTraitsINS_7ELFYAML11MIPS_ABI_FPEvE11enumerationERNS0_2IOERS3_",
    "llvm::yaml::ScalarEnumerationTraits<llvm::ELFYAML::MIPS_ABI_FP, void>::enumeration(llvm::yaml::IO&, llvm::ELFYAML::MIPS_ABI_FP&)",
    "llvm::yaml::ScalarEnumerationTraits<llvm::ELFYAML::MIPS_ABI_FP, void>::enumeration",
  ),
  (
    "_ZN4llvm9DWARFYAML20emitDebugGNUPubnamesERNS_11raw_ostreamERKNS0_4DataE", "llvm::DWARFYAML::emitDebugGNUPubnames(llvm::raw_ostream&, llvm::DWARFYAML::Data const&)",
    "llvm::DWARFYAML::emitDebugGNUPubnames",
  ),
  (
    "_ZN4llvm4yaml9yaml2goffERNS_8GOFFYAML6ObjectERNS_11raw_ostreamENS_12function_refIFvRKNS_5TwineEEEE",
    "llvm::yaml::yaml2goff(llvm::GOFFYAML::Object&, llvm::raw_ostream&, llvm::function_ref<void (llvm::Twine const&)>)",
    "llvm::yaml::yaml2goff",
  ),
  (
    "_ZNSt3__16vectorIN4llvm9DWARFYAML12LoclistEntryENS_9allocatorIS3_EEE13__vdeallocateEv",
    "std::__1::vector<llvm::DWARFYAML::LoclistEntry, std::__1::allocator<llvm::DWARFYAML::LoclistEntry>>::__vdeallocate()",
    "std::__1::vector<llvm::DWARFYAML::LoclistEntry, std::__1::allocator<llvm::DWARFYAML::LoclistEntry>>::__vdeallocate",
  ),
  (
    "_ZNK4llvm7ELFYAML11NoteSection10getEntriesEv", "llvm::ELFYAML::NoteSection::getEntries() const",
    "llvm::ELFYAML::NoteSection::getEntries",
  ),
  (
    "_ZN4llvm4yaml9yaml2coffERNS_8COFFYAML6ObjectERNS_11raw_ostreamENS_12function_refIFvRKNS_5TwineEEEE",
    "llvm::yaml::yaml2coff(llvm::COFFYAML::Object&, llvm::raw_ostream&, llvm::function_ref<void (llvm::Twine const&)>)",
    "llvm::yaml::yaml2coff",
  ),
  (
    "_ZTVN12_GLOBAL__N_114PromoteOpToF32IN4mlir4math5CosOpEEE", "vtable for (anonymous namespace)::PromoteOpToF32<mlir::math::CosOp>",
    "vtable for (anonymous namespace)::PromoteOpToF32<mlir::math::CosOp>",
  ),
  (
    "_ZN12_GLOBAL__N_114PromoteOpToF32IN4mlir4math7Atan2OpEED0Ev", "(anonymous namespace)::PromoteOpToF32<mlir::math::Atan2Op>::~PromoteOpToF32()",
    "(anonymous namespace)::PromoteOpToF32<mlir::math::Atan2Op>::~PromoteOpToF32",
  ),
  (
    "_ZN4LIEF3ELF6Binary17patch_relocationsILNS0_4ARCHE3EEEvyy", "void LIEF::ELF::Binary::patch_relocations<(LIEF::ELF::ARCH)3>(unsigned long long, unsigned long long)",
    "LIEF::ELF::Binary::patch_relocations<(LIEF::ELF::ARCH)3>",
  ),
  (
    "_ZN4mlir5ROCDL23CvtScaleF32Pk16Fp6F32Op5printERNS_12OpAsmPrinterE", "mlir::ROCDL::CvtScaleF32Pk16Fp6F32Op::print(mlir::OpAsmPrinter&)",
    "mlir::ROCDL::CvtScaleF32Pk16Fp6F32Op::print",
  ),
  (
    "_ZN4LIEF2PE16ResourcesManagerD1Ev", "LIEF::PE::ResourcesManager::~ResourcesManager()",
    "LIEF::PE::ResourcesManager::~ResourcesManager",
  ),
  (
    "_ZN4mlir4NVVM20ConvertFloatToTF32Op7getReluEv", "mlir::NVVM::ConvertFloatToTF32Op::getRelu()",
    "mlir::NVVM::ConvertFloatToTF32Op::getRelu",
  ),
  (
    "_ZN4LIEF2PElsERNSt3__113basic_ostreamIcNS1_11char_traitsIcEEEERKNS0_14ResourceDialog4ItemE",
    "LIEF::PE::operator<<(std::__1::basic_ostream<char, std::__1::char_traits<char>>&, LIEF::PE::ResourceDialog::Item const&)",
    "LIEF::PE::operator<<",
  ),
  (
    "_ZN4mlir5ROCDL25CvtScaleF32SrPk8Fp8Bf16Op5parseERNS_11OpAsmParserERNS_14OperationStateE",
    "mlir::ROCDL::CvtScaleF32SrPk8Fp8Bf16Op::parse(mlir::OpAsmParser&, mlir::OperationState&)",
    "mlir::ROCDL::CvtScaleF32SrPk8Fp8Bf16Op::parse",
  ),
  (
    "_ZN4LIEF3ELF17DynamicEntryArray6removeEy", "LIEF::ELF::DynamicEntryArray::remove(unsigned long long)",
    "LIEF::ELF::DynamicEntryArray::remove",
  ),
  (
    "_ZN4mlir5ROCDL32CvtScaleF32SrPk16Fp6F16OpAdaptorC2ENS0_25CvtScaleF32SrPk16Fp6F16OpE",
    "mlir::ROCDL::CvtScaleF32SrPk16Fp6F16OpAdaptor::CvtScaleF32SrPk16Fp6F16OpAdaptor(mlir::ROCDL::CvtScaleF32SrPk16Fp6F16Op)",
    "mlir::ROCDL::CvtScaleF32SrPk16Fp6F16OpAdaptor::CvtScaleF32SrPk16Fp6F16OpAdaptor",
  ),
  (
    "_ZN4mlir5ROCDL11CvtF32Bf8Op6createERNS_9OpBuilderENS_8LocationENS_4TypeENS_5ValueEj",
    "mlir::ROCDL::CvtF32Bf8Op::create(mlir::OpBuilder&, mlir::Location, mlir::Type, mlir::Value, unsigned int)",
    "mlir::ROCDL::CvtF32Bf8Op::create",
  ),
  (
    "_ZZN4mlir5ROCDL22CvtScaleF32SrFp8BF16Op17getAttributeNamesEvE9attrNames", "mlir::ROCDL::CvtScaleF32SrFp8BF16Op::getAttributeNames()::attrNames",
    "mlir::ROCDL::CvtScaleF32SrFp8BF16Op::getAttributeNames()::attrNames",
  ),
  (
    "_ZN4lldb13SBTypeSummary23CreateWithSummaryStringEPKcj", "lldb::SBTypeSummary::CreateWithSummaryString(char const*, unsigned int)",
    "lldb::SBTypeSummary::CreateWithSummaryString",
  ),
  (
    "_ZN4llvm16InstCombinerImpl20combineLoadToNewTypeERNS_8LoadInstEPNS_4TypeERKNS_5TwineE",
    "llvm::InstCombinerImpl::combineLoadToNewType(llvm::LoadInst&, llvm::Type*, llvm::Twine const&)",
    "llvm::InstCombinerImpl::combineLoadToNewType",
  ),
  (
    "_ZNK4llvm20AMDGPUMangledLibFunc15getFunctionTypeERKNS_6ModuleE", "llvm::AMDGPUMangledLibFunc::getFunctionType(llvm::Module const&) const",
    "llvm::AMDGPUMangledLibFunc::getFunctionType",
  ),
  (
    "_ZN4llvm20MipsSETargetLowering15addMSAFloatTypeENS_3MVT15SimpleValueTypeEPKNS_19TargetRegisterClassE",
    "llvm::MipsSETargetLowering::addMSAFloatType(llvm::MVT::SimpleValueType, llvm::TargetRegisterClass const*)",
    "llvm::MipsSETargetLowering::addMSAFloatType",
  ),
  (
    "_ZN4llvm12dwarf_linker8parallel24SyntheticTypeNameBuilder13addTypePrefixEPKNS_19DWARFDebugInfoEntryE",
    "llvm::dwarf_linker::parallel::SyntheticTypeNameBuilder::addTypePrefix(llvm::DWARFDebugInfoEntry const*)",
    "llvm::dwarf_linker::parallel::SyntheticTypeNameBuilder::addTypePrefix",
  ),
  (
    "_ZN5clang16PackIndexingType7ProfileERN4llvm16FoldingSetNodeIDERKNS_10ASTContextE",
    "clang::PackIndexingType::Profile(llvm::FoldingSetNodeID&, clang::ASTContext const&)",
    "clang::PackIndexingType::Profile",
  ),
  (
    "_ZNK4mlir20OpToFuncCallLoweringINS_4math6ErfcOpEE15getFunctionNameENS_4TypeES2_",
    "mlir::OpToFuncCallLowering<mlir::math::ErfcOp>::getFunctionName(mlir::Type, mlir::math::ErfcOp) const",
    "mlir::OpToFuncCallLowering<mlir::math::ErfcOp>::getFunctionName",
  ),
  (
    "_ZN4mlir4NVVM8WarpIdOp6createERNS_20ImplicitLocOpBuilderENS_4TypeE", "mlir::NVVM::WarpIdOp::create(mlir::ImplicitLocOpBuilder&, mlir::Type)",
    "mlir::NVVM::WarpIdOp::create",
  ),
  (
    "_ZN12_GLOBAL__N_111TypePrinter25printUnaryTransformBeforeEPKN5clang18UnaryTransformTypeERN4llvm11raw_ostreamE",
    "(anonymous namespace)::TypePrinter::printUnaryTransformBefore(clang::UnaryTransformType const*, llvm::raw_ostream&)",
    "(anonymous namespace)::TypePrinter::printUnaryTransformBefore",
  ),
  (
    "_ZNK5clang4Type26getObjCARCImplicitLifetimeEv", "clang::Type::getObjCARCImplicitLifetime() const",
    "clang::Type::getObjCARCImplicitLifetime",
  ),
  (
    "_ZN5clang6interp6DecPopILNS0_8PrimTypeE8ENS0_10IntegralAPILb0EEEEEbRNS0_11InterpStateENS0_7CodePtrEb",
    "bool clang::interp::DecPop<(clang::interp::PrimType)8, clang::interp::IntegralAP<false>>(clang::interp::InterpState&, clang::interp::CodePtr, bool)",
    "clang::interp::DecPop<(clang::interp::PrimType)8, clang::interp::IntegralAP<false>>",
  ),
  (
    "_ZN4mlir6detail14TypeIDResolverINS_4xevm12MemScopeAttrEvE2idE", "mlir::detail::TypeIDResolver<mlir::xevm::MemScopeAttr, void>::id",
    "mlir::detail::TypeIDResolver<mlir::xevm::MemScopeAttr, void>::id",
  ),
  (
    "_ZN4llvm15SmallVectorImplIN5clang13DarwinSDKInfo15SDKPlatformInfoEE12assignRemoteEOS4_",
    "llvm::SmallVectorImpl<clang::DarwinSDKInfo::SDKPlatformInfo>::assignRemote(llvm::SmallVectorImpl<clang::DarwinSDKInfo::SDKPlatformInfo>&&)",
    "llvm::SmallVectorImpl<clang::DarwinSDKInfo::SDKPlatformInfo>::assignRemote",
  ),
  (
    "_ZN5clang13DarwinSDKInfo26parseDarwinSDKSettingsJSONEPKN4llvm4json6ObjectE",
    "clang::DarwinSDKInfo::parseDarwinSDKSettingsJSON(llvm::json::Object const*)",
    "clang::DarwinSDKInfo::parseDarwinSDKSettingsJSON",
  ),
  (
    "_ZN4llvm23AMDGPUTargetAsmStreamer18EmitAMDKernelCodeTERNS_6AMDGPU19AMDGPUMCKernelCodeTE",
    "llvm::AMDGPUTargetAsmStreamer::EmitAMDKernelCodeT(llvm::AMDGPU::AMDGPUMCKernelCodeT&)",
    "llvm::AMDGPUTargetAsmStreamer::EmitAMDKernelCodeT",
  ),
  (
    "_ZN12lldb_private14HostInfoMacOSX10GetSDKRootENS_12HostInfoBase10SDKOptionsE",
    "lldb_private::HostInfoMacOSX::GetSDKRoot(lldb_private::HostInfoBase::SDKOptions)",
    "lldb_private::HostInfoMacOSX::GetSDKRoot",
  ),
  (
    "_ZTV26DynamicLoaderFreeBSDKernel", "vtable for DynamicLoaderFreeBSDKernel",
    "vtable for DynamicLoaderFreeBSDKernel",
  ),
  (
    "_ZN12lldb_private10SymbolFile13ParseXcodeSDKERNS_11CompileUnitE", "lldb_private::SymbolFile::ParseXcodeSDK(lldb_private::CompileUnit&)",
    "lldb_private::SymbolFile::ParseXcodeSDK",
  ),
  (
    "_ZN4llvm7objcarc15TopDownPtrState16MatchWithReleaseERNS0_14ARCMDKindCacheEPNS_11InstructionE",
    "llvm::objcarc::TopDownPtrState::MatchWithRelease(llvm::objcarc::ARCMDKindCache&, llvm::Instruction*)",
    "llvm::objcarc::TopDownPtrState::MatchWithRelease",
  ),
  (
    "_ZN26DynamicLoaderFreeBSDKernel5ClearEb", "DynamicLoaderFreeBSDKernel::Clear(bool)",
    "DynamicLoaderFreeBSDKernel::Clear",
  ),
  (
    "_ZN4llvm6Module32setDarwinTargetVariantSDKVersionENS_12VersionTupleE", "llvm::Module::setDarwinTargetVariantSDKVersion(llvm::VersionTuple)",
    "llvm::Module::setDarwinTargetVariantSDKVersion",
  ),
  (
    "_ZN12lldb_private8Platform15GetSDKDirectoryERNS_6TargetE", "lldb_private::Platform::GetSDKDirectory(lldb_private::Target&)",
    "lldb_private::Platform::GetSDKDirectory",
  ),
  (
    "_ZN26DynamicLoaderFreeBSDKernel28CheckForKernelImageAtAddressEPN12lldb_private7ProcessEyPb",
    "DynamicLoaderFreeBSDKernel::CheckForKernelImageAtAddress(lldb_private::Process*, unsigned long long, bool*)",
    "DynamicLoaderFreeBSDKernel::CheckForKernelImageAtAddress",
  ),
  (
    "_ZL42_wrap_SBDebugger_SetCurrentPlatformSDKRootP7_objectS0_", "_wrap_SBDebugger_SetCurrentPlatformSDKRoot(_object*, _object*)",
    "_wrap_SBDebugger_SetCurrentPlatformSDKRoot",
  ),
  (
    "___Z1fv_block_invoke", "invocation function for block in f()", "___Z1fv_block_invoke",
  ),
  (
    "___Z1fv_block_invoke_2", "invocation function for block in f()", "___Z1fv_block_invoke_2",
  ),
  ("__Z3fooi", "foo(int)", "foo"),
  ("__Z", "__Z", "__Z"),
  ("__imp__Z3fooi", "import thunk for foo(int)", "import thunk for foo"),
  ("__imp_i", "import thunk for int", "import thunk for int"),
  (
    "_ZTS24CommandObjectStatsEnable", "typeinfo name for CommandObjectStatsEnable",
    "typeinfo name for CommandObjectStatsEnable",
  ),
  (
    "_ZNK4llvm6detail9PassModelINS_8FunctionENS_14LoopUnrollPassENS_15AnalysisManagerIS2_JEEEJEE4nameEv",
    "llvm::detail::PassModel<llvm::Function, llvm::LoopUnrollPass, llvm::AnalysisManager<llvm::Function>>::name() const",
    "llvm::detail::PassModel<llvm::Function, llvm::LoopUnrollPass, llvm::AnalysisManager<llvm::Function>>::name",
  ),
  (
    "_ZN4node16EnabledDebugList5ParseERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE.cold.44",
    "node::EnabledDebugList::Parse(std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>> const&) (.cold.44)",
    "node::EnabledDebugList::Parse",
  ),
  (
    "_ZNK4llvm6detail9PassModelINS_8FunctionENS_12LoopFusePassENS_15AnalysisManagerIS2_JEEEJEE4nameEv",
    "llvm::detail::PassModel<llvm::Function, llvm::LoopFusePass, llvm::AnalysisManager<llvm::Function>>::name() const",
    "llvm::detail::PassModel<llvm::Function, llvm::LoopFusePass, llvm::AnalysisManager<llvm::Function>>::name",
  ),
  (
    "_ZL23narrowInterleaveGroupOpPN4llvm7VPValueERNS_15SmallPtrSetImplIS1_EE", "narrowInterleaveGroupOp(llvm::VPValue*, llvm::SmallPtrSetImpl<llvm::VPValue*>&)",
    "narrowInterleaveGroupOp",
  ),
  (
    "_ZN2v88internal17ExternalReference39name_dictionary_lookup_forwarded_stringEv",
    "v8::internal::ExternalReference::name_dictionary_lookup_forwarded_string()",
    "v8::internal::ExternalReference::name_dictionary_lookup_forwarded_string",
  ),
  (
    "_ZNK12_GLOBAL__N_122_object_error_category4nameEv", "(anonymous namespace)::_object_error_category::name() const",
    "(anonymous namespace)::_object_error_category::name",
  ),
  (
    "_ZNK4llvm6detail9PassModelINS_8FunctionENS_25BPFASpaceCastSimplifyPassENS_15AnalysisManagerIS2_JEEEJEE4nameEv",
    "llvm::detail::PassModel<llvm::Function, llvm::BPFASpaceCastSimplifyPass, llvm::AnalysisManager<llvm::Function>>::name() const",
    "llvm::detail::PassModel<llvm::Function, llvm::BPFASpaceCastSimplifyPass, llvm::AnalysisManager<llvm::Function>>::name",
  ),
  (
    "_ZNK4mlir7arm_sme4impl22EnableArmStreamingBaseIN12_GLOBAL__N_122EnableArmStreamingPassEE14getDescriptionEv",
    "mlir::arm_sme::impl::EnableArmStreamingBase<(anonymous namespace)::EnableArmStreamingPass>::getDescription() const",
    "mlir::arm_sme::impl::EnableArmStreamingBase<(anonymous namespace)::EnableArmStreamingPass>::getDescription",
  ),
  (
    "_ZN13nary_tacticalC2EjPKP6tactic", "nary_tactical::nary_tactical(unsigned int, tactic* const*)",
    "nary_tactical::nary_tactical",
  ),
  (
    "_ZNK4llvm6detail9PassModelINS_15MachineFunctionENS_17TailDuplicatePassENS_15AnalysisManagerIS2_JEEEJEE4nameEv",
    "llvm::detail::PassModel<llvm::MachineFunction, llvm::TailDuplicatePass, llvm::AnalysisManager<llvm::MachineFunction>>::name() const",
    "llvm::detail::PassModel<llvm::MachineFunction, llvm::TailDuplicatePass, llvm::AnalysisManager<llvm::MachineFunction>>::name",
  ),
  (
    "_ZZN6v8impl12_GLOBAL__N_16UnwrapEP10napi_env__P12napi_value__PPvNS0_12UnwrapActionEE20error_and_abort_args",
    "v8impl::(anonymous namespace)::Unwrap(napi_env__*, napi_value__*, void**, v8impl::(anonymous namespace)::UnwrapAction)::error_and_abort_args",
    "v8impl::(anonymous namespace)::Unwrap(napi_env__*, napi_value__*, void**, v8impl::(anonymous namespace)::UnwrapAction)::error_and_abort_args",
  ),
  (
    "_ZN8dll_baseIN3euf10match_goalEE13push_to_frontERPS1_S3_", "dll_base<euf::match_goal>::push_to_front(euf::match_goal*&, euf::match_goal*)",
    "dll_base<euf::match_goal>::push_to_front",
  ),
  (
    "_ZNK4LIEF2PE14OptionalHeader24dll_characteristics_listEv", "LIEF::PE::OptionalHeader::dll_characteristics_list() const",
    "LIEF::PE::OptionalHeader::dll_characteristics_list",
  ),
  (
    "_ZN4mlir4dlti33registerTransformDialectExtensionERNS_15DialectRegistryE", "mlir::dlti::registerTransformDialectExtension(mlir::DialectRegistry&)",
    "mlir::dlti::registerTransformDialectExtension",
  ),
  (
    "_ZN4llvm17dlltoolDriverMainENS_8ArrayRefIPKcEE", "llvm::dlltoolDriverMain(llvm::ArrayRef<char const*>)",
    "llvm::dlltoolDriverMain",
  ),
  (
    "_ZL42dllExportImportClassTemplateSpecializationRN5clang4SemaEPNS_31ClassTemplateSpecializationDeclE",
    "dllExportImportClassTemplateSpecialization(clang::Sema&, clang::ClassTemplateSpecializationDecl*)",
    "dllExportImportClassTemplateSpecialization",
  ),
  (
    "_ZN4llvm13dlangDemangleENSt3__117basic_string_viewIcNS0_11char_traitsIcEEEE",
    "llvm::dlangDemangle(std::__1::basic_string_view<char, std::__1::char_traits<char>>)",
    "llvm::dlangDemangle",
  ),
  (
    "_ZN4mlir4dlti5queryEPNS_9OperationEN4llvm8ArrayRefINS3_9StringRefEEEb", "mlir::dlti::query(mlir::Operation*, llvm::ArrayRef<llvm::StringRef>, bool)",
    "mlir::dlti::query",
  ),
  (
    "_ZN4llvm15handleAllErrorsIJZNS_17dlltoolDriverMainENS_8ArrayRefIPKcEEE3$_0EEEvNS_5ErrorEDpOT_",
    "void llvm::handleAllErrors<llvm::dlltoolDriverMain(llvm::ArrayRef<char const*>)::$_0>(llvm::Error, llvm::dlltoolDriverMain(llvm::ArrayRef<char const*>)::$_0&&)",
    "llvm::handleAllErrors<llvm::dlltoolDriverMain(llvm::ArrayRef<char const*>)::$_0>",
  ),
  (
    "_ZN8dll_baseIN1q7bindingEE13push_to_frontERPS1_S3_", "dll_base<q::binding>::push_to_front(q::binding*&, q::binding*)",
    "dll_base<q::binding>::push_to_front",
  ),
  (
    "_ZN4mlir4dlti5queryEPNS_9OperationEN4llvm8ArrayRefINS3_12PointerUnionIJNS_4TypeENS_10StringAttrEEEEEEb",
    "mlir::dlti::query(mlir::Operation*, llvm::ArrayRef<llvm::PointerUnion<mlir::Type, mlir::StringAttr>>, bool)",
    "mlir::dlti::query",
  ),
  (
    "_ZTVN7datalog11udoc_plugin21filter_interpreted_fnE", "vtable for datalog::udoc_plugin::filter_interpreted_fn",
    "vtable for datalog::udoc_plugin::filter_interpreted_fn",
  ),
  (
    "_ZNK7datalog14check_relation5mk_eqERKNS_13relation_factE", "datalog::check_relation::mk_eq(datalog::relation_fact const&) const",
    "datalog::check_relation::mk_eq",
  ),
  (
    "_ZTVN7datalog15hashtable_tableE", "vtable for datalog::hashtable_table", "vtable for datalog::hashtable_table",
  ),
  (
    "_ZN7datalog16relation_manager19get_relation_pluginEi", "datalog::relation_manager::get_relation_plugin(int)",
    "datalog::relation_manager::get_relation_plugin",
  ),
  (
    "_ZTVN7datalog22hashtable_table_pluginE", "vtable for datalog::hashtable_table_plugin",
    "vtable for datalog::hashtable_table_plugin",
  ),
  (
    "_ZTIN7datalog21check_relation_plugin8union_fnE", "typeinfo for datalog::check_relation_plugin::union_fn",
    "typeinfo for datalog::check_relation_plugin::union_fn",
  ),
  (
    "_ZN8datatype4decl6plugin12mk_func_declEijPK9parameterjPKP4sortS6_", "datatype::decl::plugin::mk_func_decl(int, unsigned int, parameter const*, unsigned int, sort* const*, sort*)",
    "datatype::decl::plugin::mk_func_decl",
  ),
  (
    "_ZN7datalog21table_relation_plugin18tr_join_project_fnclERKNS_13relation_baseES4_",
    "datalog::table_relation_plugin::tr_join_project_fn::operator()(datalog::relation_base const&, datalog::relation_base const&)",
    "datalog::table_relation_plugin::tr_join_project_fn::operator()",
  ),
  (
    "_ZN8wasmtime7runtime9component9resources4host25HostResource$LT$T$C$D$GT$15lift_from_index17ha4813bc2da8b2e47E",
    "wasmtime::runtime::component::resources::host::HostResource$LT$T$C$D$GT$::lift_from_index::ha4813bc2da8b2e47",
    "wasmtime::runtime::component::resources::host::HostResource$LT$T$C$D$GT$::lift_from_index::ha4813bc2da8b2e47",
  ),
  (
    "_ZN7datalog16relation_manager35default_table_filter_interpreted_fnclERNS_10table_baseE",
    "datalog::relation_manager::default_table_filter_interpreted_fn::operator()(datalog::table_base&)",
    "datalog::relation_manager::default_table_filter_interpreted_fn::operator()",
  ),
  (
    "_ZN7datalog17tr_infrastructureINS_12table_traitsEE13base_ancestor10deallocateEv",
    "datalog::tr_infrastructure<datalog::table_traits>::base_ancestor::deallocate()",
    "datalog::tr_infrastructure<datalog::table_traits>::base_ancestor::deallocate",
  ),
  (
    "_ZTIN7datalog30finite_product_relation_plugin7join_fnE", "typeinfo for datalog::finite_product_relation_plugin::join_fn",
    "typeinfo for datalog::finite_product_relation_plugin::join_fn",
  ),
  (
    "_ZN4llvm16InstCombinerImpl25foldUsingDistributiveLawsERNS_14BinaryOperatorE",
    "llvm::InstCombinerImpl::foldUsingDistributiveLaws(llvm::BinaryOperator&)", "llvm::InstCombinerImpl::foldUsingDistributiveLaws",
  ),
  (
    "_ZN12v8_inspector8protocol7Runtime20DomainDispatcherImpl12awaitPromiseERKN8v8_crdtp12DispatchableE",
    "v8_inspector::protocol::Runtime::DomainDispatcherImpl::awaitPromise(v8_crdtp::Dispatchable const&)",
    "v8_inspector::protocol::Runtime::DomainDispatcherImpl::awaitPromise",
  ),
  (
    "_ZNK17arith_decl_plugin2awEv", "arith_decl_plugin::aw() const", "arith_decl_plugin::aw",
  ),
  (
    "_ZL18matchDeMorgansLawsRN4llvm14BinaryOperatorERNS_12InstCombinerE", "matchDeMorgansLaws(llvm::BinaryOperator&, llvm::InstCombiner&)",
    "matchDeMorgansLaws",
  ),
  (
    "_ZN4llvm3orc11DebugObject14awaitTargetMemEv", "llvm::orc::DebugObject::awaitTargetMem()",
    "llvm::orc::DebugObject::awaitTargetMem",
  ),
  (
    "_ZZN12v8_inspector8protocol7Runtime12_GLOBAL__N_118awaitPromiseParams23deserializer_descriptorEvE6fields",
    "v8_inspector::protocol::Runtime::(anonymous namespace)::awaitPromiseParams::deserializer_descriptor()::fields",
    "v8_inspector::protocol::Runtime::(anonymous namespace)::awaitPromiseParams::deserializer_descriptor()::fields",
  ),
  (
    "_ZN12v8_inspector8protocol7Runtime20DomainDispatcherImpl12awaitPromiseERKN8v8_crdtp12DispatchableE.cold.1",
    "v8_inspector::protocol::Runtime::DomainDispatcherImpl::awaitPromise(v8_crdtp::Dispatchable const&) (.cold.1)",
    "v8_inspector::protocol::Runtime::DomainDispatcherImpl::awaitPromise",
  ),
  (
    "_ZN18psort_builtin_declD0Ev", "psort_builtin_decl::~psort_builtin_decl()", "psort_builtin_decl::~psort_builtin_decl",
  ),
  (
    "_ZNK10psort_sort10hcons_hashEv", "psort_sort::hcons_hash() const", "psort_sort::hcons_hash",
  ),
  (
    "_ZN10psort_sort11instantiateER13pdecl_managerjPKP4sort", "psort_sort::instantiate(pdecl_manager&, unsigned int, sort* const*)",
    "psort_sort::instantiate",
  ),
  (
    "_ZN4ring3rsa7padding3pss14RSA_PSS_SHA51217hb376843e3941d529E", "ring::rsa::padding::pss::RSA_PSS_SHA512::hb376843e3941d529",
    "ring::rsa::padding::pss::RSA_PSS_SHA512::hb376843e3941d529",
  ),
  (
    "_ZN8psort_nwIN3opt7sortmaxEE9vc_smergeEjjj", "psort_nw<opt::sortmax>::vc_smerge(unsigned int, unsigned int, unsigned int)",
    "psort_nw<opt::sortmax>::vc_smerge",
  ),
  (
    "_ZN8psort_nwIN14pb2bv_rewriter3imp16card2bv_rewriterEE3cmpEP4exprS5_S5_S5_",
    "psort_nw<pb2bv_rewriter::imp::card2bv_rewriter>::cmp(expr*, expr*, expr*, expr*)",
    "psort_nw<pb2bv_rewriter::imp::card2bv_rewriter>::cmp",
  ),
  (
    "_ZN11PSOutputDev9psXObjectEP6StreamS1_", "PSOutputDev::psXObject(Stream*, Stream*)",
    "PSOutputDev::psXObject",
  ),
  (
    "_ZNK9psort_var7displayERNSt3__113basic_ostreamIcNS0_11char_traitsIcEEEE", "psort_var::display(std::__1::basic_ostream<char, std::__1::char_traits<char>>&) const",
    "psort_var::display",
  ),
  (
    "_ZNK10psort_sort8hcons_eqEPK8Z3_psort", "psort_sort::hcons_eq(Z3_psort const*) const",
    "psort_sort::hcons_eq",
  ),
  (
    "_ZN6gnutls22psk_server_credentialsC1Ev", "gnutls::psk_server_credentials::psk_server_credentials()",
    "gnutls::psk_server_credentials::psk_server_credentials",
  ),
  (
    "_ZN8psort_nwIN3opt7sortmaxEE5mergeEjPKP4exprjS6_R10ptr_vectorIS3_E", "psort_nw<opt::sortmax>::merge(unsigned int, expr* const*, unsigned int, expr* const*, ptr_vector<expr>&)",
    "psort_nw<opt::sortmax>::merge",
  ),
  (
    "_ZN6vectorIPN15seq_decl_plugin4psigELb0EjED2Ev", "vector<seq_decl_plugin::psig*, false, unsigned int>::~vector()",
    "vector<seq_decl_plugin::psig*, false, unsigned int>::~vector",
  ),
  (
    "_ZN5clang9ASTWriter29WritePragmaDiagnosticMappingsERKNS_17DiagnosticsEngineEb",
    "clang::ASTWriter::WritePragmaDiagnosticMappings(clang::DiagnosticsEngine const&, bool)",
    "clang::ASTWriter::WritePragmaDiagnosticMappings",
  ),
  (
    "_ZL19getPrivateModuleMapN5clang12FileEntryRefERNS_11FileManagerERNS_17DiagnosticsEngineEb",
    "getPrivateModuleMap(clang::FileEntryRef, clang::FileManager&, clang::DiagnosticsEngine&, bool)",
    "getPrivateModuleMap",
  ),
  (
    "_ZN2v88internal4wasm10WasmEngine30GetBarrierForBackgroundCompileEv", "v8::internal::wasm::WasmEngine::GetBarrierForBackgroundCompile()",
    "v8::internal::wasm::WasmEngine::GetBarrierForBackgroundCompile",
  ),
  (
    "_ZN4llvm13EngineBuilder6createEPNS_13TargetMachineE", "llvm::EngineBuilder::create(llvm::TargetMachine*)",
    "llvm::EngineBuilder::create",
  ),
  (
    "_ZN5clang16StoredDiagnosticC2ENS_17DiagnosticsEngine5LevelEjN4llvm9StringRefE",
    "clang::StoredDiagnostic::StoredDiagnostic(clang::DiagnosticsEngine::Level, unsigned int, llvm::StringRef)",
    "clang::StoredDiagnostic::StoredDiagnostic",
  ),
  (
    "_ZN5clang4ento10ExprEngine21replayWithoutInliningEPNS0_12ExplodedNodeEPKNS_15LocationContextE",
    "clang::ento::ExprEngine::replayWithoutInlining(clang::ento::ExplodedNode*, clang::LocationContext const*)",
    "clang::ento::ExprEngine::replayWithoutInlining",
  ),
  (
    "_ZN5clang13FixItRewriter16HandleDiagnosticENS_17DiagnosticsEngine5LevelERKNS_10DiagnosticE",
    "clang::FixItRewriter::HandleDiagnostic(clang::DiagnosticsEngine::Level, clang::Diagnostic const&)",
    "clang::FixItRewriter::HandleDiagnostic",
  ),
  (
    "_ZN5clang7targets23SPIRV64AMDGCNTargetInfo6adjustERNS_17DiagnosticsEngineERNS_11LangOptionsEPKNS_10TargetInfoE",
    "clang::targets::SPIRV64AMDGCNTargetInfo::adjust(clang::DiagnosticsEngine&, clang::LangOptions&, clang::TargetInfo const*)",
    "clang::targets::SPIRV64AMDGCNTargetInfo::adjust",
  ),
  (
    "_ZL20parseAnalyzerConfigsRN5clang15AnalyzerOptionsEPNS_17DiagnosticsEngineE",
    "parseAnalyzerConfigs(clang::AnalyzerOptions&, clang::DiagnosticsEngine*)", "parseAnalyzerConfigs",
  ),
  (
    "_ZZN4node5http211Http2Stream9AddHeaderEP13nghttp2_rcbufS3_hE20error_and_abort_args",
    "node::http2::Http2Stream::AddHeader(nghttp2_rcbuf*, nghttp2_rcbuf*, unsigned char)::error_and_abort_args",
    "node::http2::Http2Stream::AddHeader(nghttp2_rcbuf*, nghttp2_rcbuf*, unsigned char)::error_and_abort_args",
  ),
  (
    "_ZN2v88internal4wasm10WasmEngine26DeleteCompileJobsOnIsolateEPNS0_7IsolateE",
    "v8::internal::wasm::WasmEngine::DeleteCompileJobsOnIsolate(v8::internal::Isolate*)",
    "v8::internal::wasm::WasmEngine::DeleteCompileJobsOnIsolate",
  ),
  (
    "_ZN5clang20ItaniumMangleContext6createERNS_10ASTContextERNS_17DiagnosticsEngineEb",
    "clang::ItaniumMangleContext::create(clang::ASTContext&, clang::DiagnosticsEngine&, bool)",
    "clang::ItaniumMangleContext::create",
  ),
  (
    "_ZN4llvm5MachO13InterfaceFile8addRPathENS_9StringRefERKNS0_6TargetE", "llvm::MachO::InterfaceFile::addRPath(llvm::StringRef, llvm::MachO::Target const&)",
    "llvm::MachO::InterfaceFile::addRPath",
  ),
  (
    "_ZN16wasmtime_environ5types11TypeConvert18convert_table_type17h16c42080b70ada12E",
    "wasmtime_environ::types::TypeConvert::convert_table_type::h16c42080b70ada12",
    "wasmtime_environ::types::TypeConvert::convert_table_type::h16c42080b70ada12",
  ),
  (
    "_ZN12_GLOBAL__N_123SemiAffineExprFlattener20addLocalIdSemiAffineEN4llvm8ArrayRefIxEES3_N4mlir10AffineExprE",
    "(anonymous namespace)::SemiAffineExprFlattener::addLocalIdSemiAffine(llvm::ArrayRef<long long>, llvm::ArrayRef<long long>, mlir::AffineExpr)",
    "(anonymous namespace)::SemiAffineExprFlattener::addLocalIdSemiAffine",
  ),
  (
    "_ZN5clang10extractapi14ExtendedModule9addSymbolEON4llvm4json6ObjectE", "clang::extractapi::ExtendedModule::addSymbol(llvm::json::Object&&)",
    "clang::extractapi::ExtendedModule::addSymbol",
  ),
  (
    "_ZN4llvm13RegBankSelect18RepairingPlacement14addInsertPointERNS0_11InsertPointE",
    "llvm::RegBankSelect::RepairingPlacement::addInsertPoint(llvm::RegBankSelect::InsertPoint&)",
    "llvm::RegBankSelect::RepairingPlacement::addInsertPoint",
  ),
  (
    "_ZN4llvm11logicalview18LVScopeCompileUnit12addedElementEPNS0_8LVSymbolE", "llvm::logicalview::LVScopeCompileUnit::addedElement(llvm::logicalview::LVSymbol*)",
    "llvm::logicalview::LVScopeCompileUnit::addedElement",
  ),
  (
    "_ZN12_GLOBAL__N_115NVPTXPassConfig26addRegAssignAndRewriteFastEv", "(anonymous namespace)::NVPTXPassConfig::addRegAssignAndRewriteFast()",
    "(anonymous namespace)::NVPTXPassConfig::addRegAssignAndRewriteFast",
  ),
  (
    "_ZL18addCallToCallGraphPN4llvm9CallGraphEPNS_8CallInstEPNS_8FunctionE", "addCallToCallGraph(llvm::CallGraph*, llvm::CallInst*, llvm::Function*)",
    "addCallToCallGraph",
  ),
  (
    "_ZN12_GLOBAL__N_114AttrTypeReader18addDeferredParsingEyNS0_9EntryKindE", "(anonymous namespace)::AttrTypeReader::addDeferredParsing(unsigned long long, (anonymous namespace)::AttrTypeReader::EntryKind)",
    "(anonymous namespace)::AttrTypeReader::addDeferredParsing",
  ),
  (
    "_ZN12_GLOBAL__N_119elim_uncnstr_tactic6rw_cfg8add_defsEjPKP4exprS3_S3_", "(anonymous namespace)::elim_uncnstr_tactic::rw_cfg::add_defs(unsigned int, expr* const*, expr*, expr*)",
    "(anonymous namespace)::elim_uncnstr_tactic::rw_cfg::add_defs",
  ),
  (
    "_ZN4CMap7addCIDsEjjjj.cold.1", "CMap::addCIDs(unsigned int, unsigned int, unsigned int, unsigned int) (.cold.1)",
    "CMap::addCIDs",
  ),
  (
    "_ZN4llvm8Argument7addAttrENS_9Attribute8AttrKindE", "llvm::Argument::addAttr(llvm::Attribute::AttrKind)",
    "llvm::Argument::addAttr",
  ),
  (
    "_ZN14core_hashtableI18default_hash_entryIP3appEN3sls10euf_plugin10value_hashENS5_8value_eqEE6insertEOS2_",
    "core_hashtable<default_hash_entry<app*>, sls::euf_plugin::value_hash, sls::euf_plugin::value_eq>::insert(app*&&)",
    "core_hashtable<default_hash_entry<app*>, sls::euf_plugin::value_hash, sls::euf_plugin::value_eq>::insert",
  ),
  (
    "_ZN4llvm12CodeViewYAML6detail16SymbolRecordImplINS_8codeview13FileStaticSymEED0Ev",
    "llvm::CodeViewYAML::detail::SymbolRecordImpl<llvm::codeview::FileStaticSym>::~SymbolRecordImpl()",
    "llvm::CodeViewYAML::detail::SymbolRecordImpl<llvm::codeview::FileStaticSym>::~SymbolRecordImpl",
  ),
  (
    "_ZTVN4llvm7support6detail23provider_format_adapterIRKNS_5dwarf5IndexEEE", "vtable for llvm::support::detail::provider_format_adapter<llvm::dwarf::Index const&>",
    "vtable for llvm::support::detail::provider_format_adapter<llvm::dwarf::Index const&>",
  ),
  (
    "_ZN9subpaving9context_tINS_11config_mpfxEE7dec_refEPNS2_4ineqE", "subpaving::context_t<subpaving::config_mpfx>::dec_ref(subpaving::context_t<subpaving::config_mpfx>::ineq*)",
    "subpaving::context_t<subpaving::config_mpfx>::dec_ref",
  ),
  (
    "_ZTSN4mlir6detail31OpOrInterfaceRewritePatternBaseINS_4math6AbsFOpEEE", "typeinfo name for mlir::detail::OpOrInterfaceRewritePatternBase<mlir::math::AbsFOp>",
    "typeinfo name for mlir::detail::OpOrInterfaceRewritePatternBase<mlir::math::AbsFOp>",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4LLVM9BitcastOpEE16deletePropertiesENS_16OpaquePropertiesE",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::BitcastOp>::deleteProperties(mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::BitcastOp>::deleteProperties",
  ),
  (
    "_ZN4mlir6detail27getDefaultAllocaMemorySpaceENS_24DataLayoutEntryInterfaceE",
    "mlir::detail::getDefaultAllocaMemorySpace(mlir::DataLayoutEntryInterface)",
    "mlir::detail::getDefaultAllocaMemorySpace",
  ),
  (
    "_ZN4mlir3acc6detail26DeleteOpGenericAdaptorBase26getAsyncOperandsDeviceTypeEv",
    "mlir::acc::detail::DeleteOpGenericAdaptorBase::getAsyncOperandsDeviceType()",
    "mlir::acc::detail::DeleteOpGenericAdaptorBase::getAsyncOperandsDeviceType",
  ),
  (
    "_ZN12_GLOBAL__N_125rel_goal_case_split_queue10del_var_ehEj", "(anonymous namespace)::rel_goal_case_split_queue::del_var_eh(unsigned int)",
    "(anonymous namespace)::rel_goal_case_split_queue::del_var_eh",
  ),
  (
    "_ZN4mlir5emitc6detail26AssignOpGenericAdaptorBaseC1ENS0_8AssignOpE", "mlir::emitc::detail::AssignOpGenericAdaptorBase::AssignOpGenericAdaptorBase(mlir::emitc::AssignOp)",
    "mlir::emitc::detail::AssignOpGenericAdaptorBase::AssignOpGenericAdaptorBase",
  ),
  (
    "_ZTSN4llvm3vfs6detail12InMemoryFileE", "typeinfo name for llvm::vfs::detail::InMemoryFile",
    "typeinfo name for llvm::vfs::detail::InMemoryFile",
  ),
  (
    "_ZNK4mlir8bytecode6detail16IRNumberingState25getDesiredBytecodeVersionEv", "mlir::bytecode::detail::IRNumberingState::getDesiredBytecodeVersion() const",
    "mlir::bytecode::detail::IRNumberingState::getDesiredBytecodeVersion",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5shard6SendOpEE14copyPropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::shard::SendOp>::copyProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::shard::SendOp>::copyProperties",
  ),
  (
    "_ZN8wasmtime7runtime2vm9component8libcalls11trampolines17waitable_set_poll17hd61aceaf95c6f4baE",
    "wasmtime::runtime::vm::component::libcalls::trampolines::waitable_set_poll::hd61aceaf95c6f4ba",
    "wasmtime::runtime::vm::component::libcalls::trampolines::waitable_set_poll::hd61aceaf95c6f4ba",
  ),
  (
    "_ZN3smt7context16simplify_clausesEv", "smt::context::simplify_clauses()", "smt::context::simplify_clauses",
  ),
  (
    "_ZN9cssparser9tokenizer12consume_name7__CASES17ha07aec07e4e3f157E", "cssparser::tokenizer::consume_name::__CASES::ha07aec07e4e3f157",
    "cssparser::tokenizer::consume_name::__CASES::ha07aec07e4e3f157",
  ),
  (
    "_ZN2v88internal8compiler19InstructionSelector26VisitUint32LessThanOrEqualENS1_10turboshaft7OpIndexE",
    "v8::internal::compiler::InstructionSelector::VisitUint32LessThanOrEqual(v8::internal::compiler::turboshaft::OpIndex)",
    "v8::internal::compiler::InstructionSelector::VisitUint32LessThanOrEqual",
  ),
  (
    "_ZNK2v88internal8compiler6MapRef19IsWasmImportDataMapEv", "v8::internal::compiler::MapRef::IsWasmImportDataMap() const",
    "v8::internal::compiler::MapRef::IsWasmImportDataMap",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5spirv11SLessThanOpEE14copyPropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::spirv::SLessThanOp>::copyProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::spirv::SLessThanOp>::copyProperties",
  ),
  (
    "_ZNK2v88internal8compiler18InstructionOperand5PrintEv", "v8::internal::compiler::InstructionOperand::Print() const",
    "v8::internal::compiler::InstructionOperand::Print",
  ),
  (
    "_ZN4node10contextify17ContextifyContext3GetEN2v85LocalINS2_6ObjectEEE", "node::contextify::ContextifyContext::Get(v8::Local<v8::Object>)",
    "node::contextify::ContextifyContext::Get",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4LLVM12StepVectorOpEE17comparePropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::StepVectorOp>::compareProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::StepVectorOp>::compareProperties",
  ),
  (
    "_ZN15ref_buffer_coreIN9subpaving4ineqE19ref_manager_wrapperIS1_NS0_7contextEELj16EED2Ev",
    "ref_buffer_core<subpaving::ineq, ref_manager_wrapper<subpaving::ineq, subpaving::context>, 16u>::~ref_buffer_core()",
    "ref_buffer_core<subpaving::ineq, ref_manager_wrapper<subpaving::ineq, subpaving::context>, 16u>::~ref_buffer_core",
  ),
  (
    "_ZN2v88internal8compiler10hash_valueERKNS1_15ForInParametersE", "v8::internal::compiler::hash_value(v8::internal::compiler::ForInParameters const&)",
    "v8::internal::compiler::hash_value",
  ),
  (
    "_ZN12lldb_private6plugin5dwarf14DebugMapModuleD1Ev", "lldb_private::plugin::dwarf::DebugMapModule::~DebugMapModule()",
    "lldb_private::plugin::dwarf::DebugMapModule::~DebugMapModule",
  ),
  (
    "_ZN2v88platform27DefaultForegroundTaskRunner29PopTaskFromDelayedQueueLockedEPNS1_11NestabilityE",
    "v8::platform::DefaultForegroundTaskRunner::PopTaskFromDelayedQueueLocked(v8::platform::DefaultForegroundTaskRunner::Nestability*)",
    "v8::platform::DefaultForegroundTaskRunner::PopTaskFromDelayedQueueLocked",
  ),
  (
    "_ZNSt3__120__shared_ptr_emplaceIN12lldb_private6plugin5dwarf14DebugMapModuleENS_9allocatorIS4_EEED1Ev",
    "std::__1::__shared_ptr_emplace<lldb_private::plugin::dwarf::DebugMapModule, std::__1::allocator<lldb_private::plugin::dwarf::DebugMapModule>>::~__shared_ptr_emplace()",
    "std::__1::__shared_ptr_emplace<lldb_private::plugin::dwarf::DebugMapModule, std::__1::allocator<lldb_private::plugin::dwarf::DebugMapModule>>::~__shared_ptr_emplace",
  ),
  (
    "_ZNK12lldb_private6plugin5dwarf8DWARFDIE20GetTypeLookupContextEb", "lldb_private::plugin::dwarf::DWARFDIE::GetTypeLookupContext(bool) const",
    "lldb_private::plugin::dwarf::DWARFDIE::GetTypeLookupContext",
  ),
  (
    "_ZN12lldb_private16platform_android30PlatformAndroidRemoteGDBServerD2Ev", "lldb_private::platform_android::PlatformAndroidRemoteGDBServer::~PlatformAndroidRemoteGDBServer()",
    "lldb_private::platform_android::PlatformAndroidRemoteGDBServer::~PlatformAndroidRemoteGDBServer",
  ),
  (
    "_ZN2v88platform7tracing32SystemInstrumentationTraceWriterC1Ev", "v8::platform::tracing::SystemInstrumentationTraceWriter::SystemInstrumentationTraceWriter()",
    "v8::platform::tracing::SystemInstrumentationTraceWriter::SystemInstrumentationTraceWriter",
  ),
  (
    "_ZN2v88platform15DefaultJobState14UpdatePriorityENS_12TaskPriorityE", "v8::platform::DefaultJobState::UpdatePriority(v8::TaskPriority)",
    "v8::platform::DefaultJobState::UpdatePriority",
  ),
  (
    "_ZNK6recfun4decl6plugin1uEv", "recfun::decl::plugin::u() const", "recfun::decl::plugin::u",
  ),
  (
    "_ZTVN12lldb_private6plugin5dwarf14DebugMapModuleE", "vtable for lldb_private::plugin::dwarf::DebugMapModule",
    "vtable for lldb_private::plugin::dwarf::DebugMapModule",
  ),
  (
    "_ZN19DWARFASTParserClang36GetDeclContextContainingUIDFromDWARFERKN12lldb_private6plugin5dwarf8DWARFDIEE",
    "DWARFASTParserClang::GetDeclContextContainingUIDFromDWARF(lldb_private::plugin::dwarf::DWARFDIE const&)",
    "DWARFASTParserClang::GetDeclContextContainingUIDFromDWARF",
  ),
  (
    "_ZN12lldb_private16platform_android15PlatformAndroid7GetFileERKNS_8FileSpecES4_",
    "lldb_private::platform_android::PlatformAndroid::GetFile(lldb_private::FileSpec const&, lldb_private::FileSpec const&)",
    "lldb_private::platform_android::PlatformAndroid::GetFile",
  ),
  (
    "_ZN12lldb_private6plugin5dwarf15SymbolFileDWARF29HasForwardDeclForCompilerTypeERKNS_12CompilerTypeE",
    "lldb_private::plugin::dwarf::SymbolFileDWARF::HasForwardDeclForCompilerType(lldb_private::CompilerType const&)",
    "lldb_private::plugin::dwarf::SymbolFileDWARF::HasForwardDeclForCompilerType",
  ),
  (
    "_ZN5clang6interp11EvalEmitter13emitInitScopeEjNS0_10SourceInfoE", "clang::interp::EvalEmitter::emitInitScope(unsigned int, clang::interp::SourceInfo)",
    "clang::interp::EvalEmitter::emitInitScope",
  ),
  (
    "_ZN4llvm13ARMAsmPrinter21EmitKCFI_CHECK_Thumb2ENS_8RegisterExRKNS_12MachineInstrEx",
    "llvm::ARMAsmPrinter::EmitKCFI_CHECK_Thumb2(llvm::Register, long long, llvm::MachineInstr const&, long long)",
    "llvm::ARMAsmPrinter::EmitKCFI_CHECK_Thumb2",
  ),
  (
    "_ZN5clang6interp15ByteCodeEmitter17emitSetParamFloatEjNS0_10SourceInfoE", "clang::interp::ByteCodeEmitter::emitSetParamFloat(unsigned int, clang::interp::SourceInfo)",
    "clang::interp::ByteCodeEmitter::emitSetParamFloat",
  ),
  (
    "_ZNK4llvm21AArch64TargetLowering8EmitFillERNS_12MachineInstrEPNS_17MachineBasicBlockE",
    "llvm::AArch64TargetLowering::EmitFill(llvm::MachineInstr&, llvm::MachineBasicBlock*) const",
    "llvm::AArch64TargetLowering::EmitFill",
  ),
  (
    "_ZN4node9AsyncWrap21EmitTraceEventDestroyEv.cold.42", "node::AsyncWrap::EmitTraceEventDestroy() (.cold.42)",
    "node::AsyncWrap::EmitTraceEventDestroy",
  ),
  (
    "_ZN5clang7CodeGen15CodeGenFunction15EmitOMPLoopBodyERKNS_16OMPLoopDirectiveENS1_8JumpDestE",
    "clang::CodeGen::CodeGenFunction::EmitOMPLoopBody(clang::OMPLoopDirective const&, clang::CodeGen::CodeGenFunction::JumpDest)",
    "clang::CodeGen::CodeGenFunction::EmitOMPLoopBody",
  ),
  (
    "_ZN5clang6interp11EvalEmitter22emitSetThisFieldUint64EjNS0_10SourceInfoE", "clang::interp::EvalEmitter::emitSetThisFieldUint64(unsigned int, clang::interp::SourceInfo)",
    "clang::interp::EvalEmitter::emitSetThisFieldUint64",
  ),
  (
    "_ZN5clang7CodeGen15CodeGenFunction8EmitStmtEPKNS_4StmtEN4llvm8ArrayRefIPKNS_4AttrEEE",
    "clang::CodeGen::CodeGenFunction::EmitStmt(clang::Stmt const*, llvm::ArrayRef<clang::Attr const*>)",
    "clang::CodeGen::CodeGenFunction::EmitStmt",
  ),
  (
    "_ZN12_GLOBAL__N_115AArch64FastISel21fastEmit_ISD_FFLOOR_rEN4llvm3MVTES2_NS1_8RegisterE",
    "(anonymous namespace)::AArch64FastISel::fastEmit_ISD_FFLOOR_r(llvm::MVT, llvm::MVT, llvm::Register)",
    "(anonymous namespace)::AArch64FastISel::fastEmit_ISD_FFLOOR_r",
  ),
  (
    "_ZN5clang6interp11EvalEmitter21emitInitElemPopSint64EjNS0_10SourceInfoE", "clang::interp::EvalEmitter::emitInitElemPopSint64(unsigned int, clang::interp::SourceInfo)",
    "clang::interp::EvalEmitter::emitInitElemPopSint64",
  ),
  (
    "_ZL41InitializeSIPreEmitPeepholeLegacyPassFlag", "InitializeSIPreEmitPeepholeLegacyPassFlag",
    "InitializeSIPreEmitPeepholeLegacyPassFlag",
  ),
  (
    "_ZN5clang7CodeGen15CodeGenFunction15EmitAtomicStoreENS0_6RValueENS0_6LValueEb",
    "clang::CodeGen::CodeGenFunction::EmitAtomicStore(clang::CodeGen::RValue, clang::CodeGen::LValue, bool)",
    "clang::CodeGen::CodeGenFunction::EmitAtomicStore",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_9transform27LoopPromoteIfOneIterationOpEED0Ev",
    "mlir::RegisteredOperationName::Model<mlir::transform::LoopPromoteIfOneIterationOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::transform::LoopPromoteIfOneIterationOp>::~Model",
  ),
  (
    "_ZTIN4mlir20OpToFuncCallLoweringINS_4math6CeilOpEEE", "typeinfo for mlir::OpToFuncCallLowering<mlir::math::CeilOp>",
    "typeinfo for mlir::OpToFuncCallLowering<mlir::math::CeilOp>",
  ),
  (
    "_ZTIN4mlir19OpConversionPatternINS_5index4OrOpEEE", "typeinfo for mlir::OpConversionPattern<mlir::index::OrOp>",
    "typeinfo for mlir::OpConversionPattern<mlir::index::OrOp>",
  ),
  (
    "_ZTVN4mlir5spirv20ElementwiseOpPatternINS_5arith6MulFOpENS0_6FMulOpEEE", "vtable for mlir::spirv::ElementwiseOpPattern<mlir::arith::MulFOp, mlir::spirv::FMulOp>",
    "vtable for mlir::spirv::ElementwiseOpPattern<mlir::arith::MulFOp, mlir::spirv::FMulOp>",
  ),
  (
    "_ZN4mlir9transform7MatchOp20verifyInvariantsImplEv", "mlir::transform::MatchOp::verifyInvariantsImpl()",
    "mlir::transform::MatchOp::verifyInvariantsImpl",
  ),
  (
    "_ZTIN4mlir23RegisteredOperationName5ModelINS_7wasmssa8GlobalOpEEE", "typeinfo for mlir::RegisteredOperationName::Model<mlir::wasmssa::GlobalOp>",
    "typeinfo for mlir::RegisteredOperationName::Model<mlir::wasmssa::GlobalOp>",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5spirv14GroupFMulKHROpEED1Ev", "mlir::RegisteredOperationName::Model<mlir::spirv::GroupFMulKHROp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::spirv::GroupFMulKHROp>::~Model",
  ),
  (
    "_ZN4mlir7wasmssa10ConvertSOp20verifyInvariantsImplEv", "mlir::wasmssa::ConvertSOp::verifyInvariantsImpl()",
    "mlir::wasmssa::ConvertSOp::verifyInvariantsImpl",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5ROCDL16Permlane16SwapOpEED1Ev",
    "mlir::RegisteredOperationName::Model<mlir::ROCDL::Permlane16SwapOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::ROCDL::Permlane16SwapOp>::~Model",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_6linalg6FillOpEE18getParseAssemblyFnEv",
    "mlir::RegisteredOperationName::Model<mlir::linalg::FillOp>::getParseAssemblyFn()",
    "mlir::RegisteredOperationName::Model<mlir::linalg::FillOp>::getParseAssemblyFn",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5index14BoolConstantOpEED0Ev", "mlir::RegisteredOperationName::Model<mlir::index::BoolConstantOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::index::BoolConstantOp>::~Model",
  ),
  (
    "_ZTIN4mlir23RegisteredOperationName5ModelINS_4tosa9GreaterOpEEE", "typeinfo for mlir::RegisteredOperationName::Model<mlir::tosa::GreaterOp>",
    "typeinfo for mlir::RegisteredOperationName::Model<mlir::tosa::GreaterOp>",
  ),
  (
    "_ZNK2lp12numeric_pairI8rationalEdvERKS1_", "lp::numeric_pair<rational>::operator/(rational const&) const",
    "lp::numeric_pair<rational>::operator/",
  ),
  (
    "_ZN12fpa_rewriter8mk_bv2rmEP4exprR7obj_refIS0_11ast_managerE", "fpa_rewriter::mk_bv2rm(expr*, obj_ref<expr, ast_manager>&)",
    "fpa_rewriter::mk_bv2rm",
  ),
  (
    "_ZN16bv2fpa_converter13convert_bv2rmEP4expr", "bv2fpa_converter::convert_bv2rm(expr*)",
    "bv2fpa_converter::convert_bv2rm",
  ),
  (
    "_ZN3CFF12path_procs_tI22cff1_path_procs_path_tNS_20cff1_cs_interp_env_tE17cff1_path_param_tE7rmovetoERS2_RS3_",
    "CFF::path_procs_t<cff1_path_procs_path_t, CFF::cff1_cs_interp_env_t, cff1_path_param_t>::rmoveto(CFF::cff1_cs_interp_env_t&, cff1_path_param_t&)",
    "CFF::path_procs_t<cff1_path_procs_path_t, CFF::cff1_cs_interp_env_t, cff1_path_param_t>::rmoveto",
  ),
  (
    "_ZN16bv2fpa_converter13convert_bv2rmEP10model_coreP4expr", "bv2fpa_converter::convert_bv2rm(model_core*, expr*)",
    "bv2fpa_converter::convert_bv2rm",
  ),
  (
    "_ZN8fpa_util8mk_bv2rmEP4expr", "fpa_util::mk_bv2rm(expr*)", "fpa_util::mk_bv2rm",
  ),
  (
    "_ZN4llvm12BPFSubtarget6anchorEv", "llvm::BPFSubtarget::anchor()", "llvm::BPFSubtarget::anchor",
  ),
  (
    "_ZN4llvm15getLiveLaneMaskEjNS_9SlotIndexERKNS_13LiveIntervalsERKNS_19MachineRegisterInfoENS_11LaneBitmaskE",
    "llvm::getLiveLaneMask(unsigned int, llvm::SlotIndex, llvm::LiveIntervals const&, llvm::MachineRegisterInfo const&, llvm::LaneBitmask)",
    "llvm::getLiveLaneMask",
  ),
  (
    "_ZTIN4mlir23RegisteredOperationName5ModelINS_4NVVM12LaneMaskGtOpEEE", "typeinfo for mlir::RegisteredOperationName::Model<mlir::NVVM::LaneMaskGtOp>",
    "typeinfo for mlir::RegisteredOperationName::Model<mlir::NVVM::LaneMaskGtOp>",
  ),
  (
    "_ZTVN12_GLOBAL__N_117GPULaneIdOpToNVVME", "vtable for (anonymous namespace)::GPULaneIdOpToNVVM",
    "vtable for (anonymous namespace)::GPULaneIdOpToNVVM",
  ),
  (
    "_ZN12lldb_private12ObjCLanguageD1Ev", "lldb_private::ObjCLanguage::~ObjCLanguage()",
    "lldb_private::ObjCLanguage::~ObjCLanguage",
  ),
  (
    "_ZNK12_GLOBAL__N_120LanaiELFObjectWriter12getRelocTypeERKN4llvm7MCFixupERKNS1_7MCValueEb",
    "(anonymous namespace)::LanaiELFObjectWriter::getRelocType(llvm::MCFixup const&, llvm::MCValue const&, bool) const",
    "(anonymous namespace)::LanaiELFObjectWriter::getRelocType",
  ),
  (
    "_ZNK12_GLOBAL__N_124ParsedAttrInfoBTFDeclTag15acceptsLangOptsERKN5clang11LangOptionsE",
    "(anonymous namespace)::ParsedAttrInfoBTFDeclTag::acceptsLangOpts(clang::LangOptions const&) const",
    "(anonymous namespace)::ParsedAttrInfoBTFDeclTag::acceptsLangOpts",
  ),
  (
    "_ZN4lldb8SBTarget22BreakpointCreateByNameEPKcjNS_12LanguageTypeEybRKNS_14SBFileSpecListES6_",
    "lldb::SBTarget::BreakpointCreateByName(char const*, unsigned int, lldb::LanguageType, unsigned long long, bool, lldb::SBFileSpecList const&, lldb::SBFileSpecList const&)",
    "lldb::SBTarget::BreakpointCreateByName",
  ),
  (
    "_ZTIN4llvm17LanaiDisassemblerE", "typeinfo for llvm::LanaiDisassembler", "typeinfo for llvm::LanaiDisassembler",
  ),
  (
    "_ZTVN4llvm6detail9PassModelINS_15MachineFunctionENS_19DetectDeadLanesPassENS_15AnalysisManagerIS2_JEEEJEEE",
    "vtable for llvm::detail::PassModel<llvm::MachineFunction, llvm::DetectDeadLanesPass, llvm::AnalysisManager<llvm::MachineFunction>>",
    "vtable for llvm::detail::PassModel<llvm::MachineFunction, llvm::DetectDeadLanesPass, llvm::AnalysisManager<llvm::MachineFunction>>",
  ),
  (
    "_ZNK12_GLOBAL__N_110WarpOpStep15matchAndRewriteEN4mlir3gpu20WarpExecuteOnLane0OpERNS1_15PatternRewriterE",
    "(anonymous namespace)::WarpOpStep::matchAndRewrite(mlir::gpu::WarpExecuteOnLane0Op, mlir::PatternRewriter&) const",
    "(anonymous namespace)::WarpOpStep::matchAndRewrite",
  ),
  (
    "_ZN4llvm16VPTransformState29packScalarIntoVectorizedValueEPKNS_7VPValueEPNS_5ValueERKNS_6VPLaneE",
    "llvm::VPTransformState::packScalarIntoVectorizedValue(llvm::VPValue const*, llvm::Value*, llvm::VPLane const&)",
    "llvm::VPTransformState::packScalarIntoVectorizedValue",
  ),
  (
    "_ZN4llvm3orc32LazyReexportsMaterializationUnitD0Ev", "llvm::orc::LazyReexportsMaterializationUnit::~LazyReexportsMaterializationUnit()",
    "llvm::orc::LazyReexportsMaterializationUnit::~LazyReexportsMaterializationUnit",
  ),
  (
    "_ZN4llvm3orc12rt_bootstrap26SimpleExecutorDylibManager14resolveWrapperEPKcm",
    "llvm::orc::rt_bootstrap::SimpleExecutorDylibManager::resolveWrapper(char const*, unsigned long)",
    "llvm::orc::rt_bootstrap::SimpleExecutorDylibManager::resolveWrapper",
  ),
  (
    "_ZN5cppgc8internal11PageBackend20FreeNormalPageMemoryEPh", "cppgc::internal::PageBackend::FreeNormalPageMemory(unsigned char*)",
    "cppgc::internal::PageBackend::FreeNormalPageMemory",
  ),
  (
    "_ZNK4llvm3orc17LibraryScanHelper14getSearchPathsEv", "llvm::orc::LibraryScanHelper::getSearchPaths() const",
    "llvm::orc::LibraryScanHelper::getSearchPaths",
  ),
  (
    "_ZN4llvm3orc29MachOSwift5TypeRefSectionNameE", "llvm::orc::MachOSwift5TypeRefSectionName",
    "llvm::orc::MachOSwift5TypeRefSectionName",
  ),
  (
    "_ZTVNSt3__113__assoc_stateIN4llvm3orc12ExecutorAddrEEE", "vtable for std::__1::__assoc_state<llvm::orc::ExecutorAddr>",
    "vtable for std::__1::__assoc_state<llvm::orc::ExecutorAddr>",
  ),
  (
    "_ZN4llvm3orc18ReexportsGeneratorD1Ev", "llvm::orc::ReexportsGenerator::~ReexportsGenerator()",
    "llvm::orc::ReexportsGenerator::~ReexportsGenerator",
  ),
  (
    "_ZN4llvm3orc6detail14ABISupportImplINS0_14OrcLoongArch64EED1Ev", "llvm::orc::detail::ABISupportImpl<llvm::orc::OrcLoongArch64>::~ABISupportImpl()",
    "llvm::orc::detail::ABISupportImpl<llvm::orc::OrcLoongArch64>::~ABISupportImpl",
  ),
  (
    "_ZTIN4llvm3orc18ReexportsGeneratorE", "typeinfo for llvm::orc::ReexportsGenerator",
    "typeinfo for llvm::orc::ReexportsGenerator",
  ),
  (
    "_ZTVN4llvm3orc18ORCPlatformSupportE", "vtable for llvm::orc::ORCPlatformSupport",
    "vtable for llvm::orc::ORCPlatformSupport",
  ),
  (
    "_ZTIN4llvm3orc32StaticLibraryDefinitionGeneratorE", "typeinfo for llvm::orc::StaticLibraryDefinitionGenerator",
    "typeinfo for llvm::orc::StaticLibraryDefinitionGenerator",
  ),
  (
    "_ZN4llvm4yaml13MappingTraitsIPKNS_5MachO13InterfaceFileEE13NormalizedTBD10copyStringENS_9StringRefE",
    "llvm::yaml::MappingTraits<llvm::MachO::InterfaceFile const*>::NormalizedTBD::copyString(llvm::StringRef)",
    "llvm::yaml::MappingTraits<llvm::MachO::InterfaceFile const*>::NormalizedTBD::copyString",
  ),
  (
    "_ZN4mlir9transform41ApplyArmNeonContractionToBFMMLAPatternsOp5parseERNS_11OpAsmParserERNS_14OperationStateE",
    "mlir::transform::ApplyArmNeonContractionToBFMMLAPatternsOp::parse(mlir::OpAsmParser&, mlir::OperationState&)",
    "mlir::transform::ApplyArmNeonContractionToBFMMLAPatternsOp::parse",
  ),
  (
    "_ZN4llvmL28NeoverseN3ModelProcResourcesE", "llvm::NeoverseN3ModelProcResources",
    "llvm::NeoverseN3ModelProcResources",
  ),
  (
    "_ZTSN4mlir23RegisteredOperationName5ModelINS_9transform39ApplyArmNeonContractionToI8MMPatternsOpEEE",
    "typeinfo name for mlir::RegisteredOperationName::Model<mlir::transform::ApplyArmNeonContractionToI8MMPatternsOp>",
    "typeinfo name for mlir::RegisteredOperationName::Model<mlir::transform::ApplyArmNeonContractionToI8MMPatternsOp>",
  ),
  (
    "_ZN4llvmL35NeoverseV3ModelProcResourceSubUnitsE", "llvm::NeoverseV3ModelProcResourceSubUnits",
    "llvm::NeoverseV3ModelProcResourceSubUnits",
  ),
  (
    "_ZL41__mlir_ods_local_type_constraint_ArmNeon7PN4mlir9OperationENS_4TypeEN4llvm9StringRefEj",
    "__mlir_ods_local_type_constraint_ArmNeon7(mlir::Operation*, mlir::Type, llvm::StringRef, unsigned int)",
    "__mlir_ods_local_type_constraint_ArmNeon7",
  ),
  (
    "_ZN12aho_corasick6packed5teddy7builder7aarch6423SlimNeon$LT$1_usize$GT$3new17h1945f0217d752a1eE",
    "aho_corasick::packed::teddy::builder::aarch64::SlimNeon$LT$1_usize$GT$::new::h1945f0217d752a1e",
    "aho_corasick::packed::teddy::builder::aarch64::SlimNeon$LT$1_usize$GT$::new::h1945f0217d752a1e",
  ),
  (
    "_ZN4mlir9transform25TransformDialectExtensionIN12_GLOBAL__N_138ArmNeonVectorTransformDialectExtensionEJEED0Ev",
    "mlir::transform::TransformDialectExtension<(anonymous namespace)::ArmNeonVectorTransformDialectExtension>::~TransformDialectExtension()",
    "mlir::transform::TransformDialectExtension<(anonymous namespace)::ArmNeonVectorTransformDialectExtension>::~TransformDialectExtension",
  ),
  (
    "_ZN19CairoImageOutputDev6eoClipEP8GfxState", "CairoImageOutputDev::eoClip(GfxState*)",
    "CairoImageOutputDev::eoClip",
  ),
  (
    "_ZN4llvmL28NeoverseN1ModelProcResourcesE", "llvm::NeoverseN1ModelProcResources",
    "llvm::NeoverseN1ModelProcResources",
  ),
  (
    "_ZN13BBoxOutputDev6eoFillEP8GfxState", "BBoxOutputDev::eoFill(GfxState*)", "BBoxOutputDev::eoFill",
  ),
  (
    "_ZN4llvmL35NeoverseN2ModelProcResourceSubUnitsE", "llvm::NeoverseN2ModelProcResourceSubUnits",
    "llvm::NeoverseN2ModelProcResourceSubUnits",
  ),
  (
    "_ZL41__mlir_ods_local_type_constraint_ArmNeon3PN4mlir9OperationENS_4TypeEN4llvm9StringRefEj",
    "__mlir_ods_local_type_constraint_ArmNeon3(mlir::Operation*, mlir::Type, llvm::StringRef, unsigned int)",
    "__mlir_ods_local_type_constraint_ArmNeon3",
  ),
  (
    "_ZN4llvm15SmallVectorImplIPN5clang4StmtEEaSEOS4_", "llvm::SmallVectorImpl<clang::Stmt*>::operator=(llvm::SmallVectorImpl<clang::Stmt*>&&)",
    "llvm::SmallVectorImpl<clang::Stmt*>::operator=",
  ),
  (
    "_ZNSt3__110shared_ptrINS_6vectorIhNS_9allocatorIhEEEEEaSB8nn190102ERKS5_", "std::__1::shared_ptr<std::__1::vector<unsigned char, std::__1::allocator<unsigned char>>>::operator=[abi:nn190102](std::__1::shared_ptr<std::__1::vector<unsigned char, std::__1::allocator<unsigned char>>> const&)",
    "std::__1::shared_ptr<std::__1::vector<unsigned char, std::__1::allocator<unsigned char>>>::operator=[abi:nn190102]",
  ),
  (
    "_ZN4llvm15SmallVectorImplIPNS_13PredicateBaseEEaSEOS3_", "llvm::SmallVectorImpl<llvm::PredicateBase*>::operator=(llvm::SmallVectorImpl<llvm::PredicateBase*>&&)",
    "llvm::SmallVectorImpl<llvm::PredicateBase*>::operator=",
  ),
  (
    "_ZN4llvm17DominatorTreeBaseINS_17MachineBasicBlockELb1EEaSEOS2_", "llvm::DominatorTreeBase<llvm::MachineBasicBlock, true>::operator=(llvm::DominatorTreeBase<llvm::MachineBasicBlock, true>&&)",
    "llvm::DominatorTreeBase<llvm::MachineBasicBlock, true>::operator=",
  ),
  (
    "_ZNSt3__110shared_ptrI5AnnotEaSB8ne200100I10AnnotPopupLi0EEERS2_ONS0_IT_EE",
    "std::__1::shared_ptr<Annot>& std::__1::shared_ptr<Annot>::operator=[abi:ne200100]<AnnotPopup, 0>(std::__1::shared_ptr<AnnotPopup>&&)",
    "std::__1::shared_ptr<Annot>::operator=[abi:ne200100]<AnnotPopup, 0>",
  ),
  (
    "_ZN4llvm15SmallVectorImplIN5clang8QualTypeEEaSEOS3_", "llvm::SmallVectorImpl<clang::QualType>::operator=(llvm::SmallVectorImpl<clang::QualType>&&)",
    "llvm::SmallVectorImpl<clang::QualType>::operator=",
  ),
  (
    "_ZNSt3__110shared_ptrI5AnnotEaSB8ne200100I9AnnotTextLi0EEERS2_ONS0_IT_EE", "std::__1::shared_ptr<Annot>& std::__1::shared_ptr<Annot>::operator=[abi:ne200100]<AnnotText, 0>(std::__1::shared_ptr<AnnotText>&&)",
    "std::__1::shared_ptr<Annot>::operator=[abi:ne200100]<AnnotText, 0>",
  ),
  (
    "_ZN4llvm15SmallVectorImplIPNS_10SelectInstEEaSERKS3_", "llvm::SmallVectorImpl<llvm::SelectInst*>::operator=(llvm::SmallVectorImpl<llvm::SelectInst*> const&)",
    "llvm::SmallVectorImpl<llvm::SelectInst*>::operator=",
  ),
  (
    "_ZN4llvm15SmallVectorImplIPNS_17InsertElementInstEEaSEOS3_", "llvm::SmallVectorImpl<llvm::InsertElementInst*>::operator=(llvm::SmallVectorImpl<llvm::InsertElementInst*>&&)",
    "llvm::SmallVectorImpl<llvm::InsertElementInst*>::operator=",
  ),
  (
    "_ZN4llvm15SmallVectorImplIN12_GLOBAL__N_110DSAStackTy12SharingMapTy23ImplicitDefaultFDInfoTyEEaSEOS5_",
    "llvm::SmallVectorImpl<(anonymous namespace)::DSAStackTy::SharingMapTy::ImplicitDefaultFDInfoTy>::operator=(llvm::SmallVectorImpl<(anonymous namespace)::DSAStackTy::SharingMapTy::ImplicitDefaultFDInfoTy>&&)",
    "llvm::SmallVectorImpl<(anonymous namespace)::DSAStackTy::SharingMapTy::ImplicitDefaultFDInfoTy>::operator=",
  ),
  (
    "_ZNSt3__110shared_ptrIP19_priv_exr_context_tEaSB8ne190102ERKS3_", "std::__1::shared_ptr<_priv_exr_context_t*>::operator=[abi:ne190102](std::__1::shared_ptr<_priv_exr_context_t*> const&)",
    "std::__1::shared_ptr<_priv_exr_context_t*>::operator=[abi:ne190102]",
  ),
  (
    "_ZN4llvm15SmallVectorImplINSt3__18functionIFvRNS_19MachineInstrBuilderEEEEEaSERKS7_",
    "llvm::SmallVectorImpl<std::__1::function<void (llvm::MachineInstrBuilder&)>>::operator=(llvm::SmallVectorImpl<std::__1::function<void (llvm::MachineInstrBuilder&)>> const&)",
    "llvm::SmallVectorImpl<std::__1::function<void (llvm::MachineInstrBuilder&)>>::operator=",
  ),
  (
    "_ZN4llvm22VarStreamArrayIteratorINS_8codeview21DebugSubsectionRecordENS_23VarStreamArrayExtractorIS2_EEEpLEj",
    "llvm::VarStreamArrayIterator<llvm::codeview::DebugSubsectionRecord, llvm::VarStreamArrayExtractor<llvm::codeview::DebugSubsectionRecord>>::operator+=(unsigned int)",
    "llvm::VarStreamArrayIterator<llvm::codeview::DebugSubsectionRecord, llvm::VarStreamArrayExtractor<llvm::codeview::DebugSubsectionRecord>>::operator+=",
  ),
  (
    "_ZN4llvm22VarStreamArrayIteratorINS_8codeview17InlineeSourceLineENS_23VarStreamArrayExtractorIS2_EEEpLEj",
    "llvm::VarStreamArrayIterator<llvm::codeview::InlineeSourceLine, llvm::VarStreamArrayExtractor<llvm::codeview::InlineeSourceLine>>::operator+=(unsigned int)",
    "llvm::VarStreamArrayIterator<llvm::codeview::InlineeSourceLine, llvm::VarStreamArrayExtractor<llvm::codeview::InlineeSourceLine>>::operator+=",
  ),
  (
    "_ZN4llvm12ScaledNumberIyEpLERKS1_", "llvm::ScaledNumber<unsigned long long>::operator+=(llvm::ScaledNumber<unsigned long long> const&)",
    "llvm::ScaledNumber<unsigned long long>::operator+=",
  ),
  (
    "_ZN16inf_eps_rationalI12inf_rationalEpLERKS1_", "inf_eps_rational<inf_rational>::operator+=(inf_eps_rational<inf_rational> const&)",
    "inf_eps_rational<inf_rational>::operator+=",
  ),
  (
    "_ZN4llvm22VarStreamArrayIteratorINS_8codeview17FileChecksumEntryENS_23VarStreamArrayExtractorIS2_EEEpLEj",
    "llvm::VarStreamArrayIterator<llvm::codeview::FileChecksumEntry, llvm::VarStreamArrayExtractor<llvm::codeview::FileChecksumEntry>>::operator+=(unsigned int)",
    "llvm::VarStreamArrayIterator<llvm::codeview::FileChecksumEntry, llvm::VarStreamArrayExtractor<llvm::codeview::FileChecksumEntry>>::operator+=",
  ),
  (
    "_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEpLB9nqn210106EPKc",
    "std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>::operator+=[abi:nqn210106](char const*)",
    "std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>::operator+=[abi:nqn210106]",
  ),
  (
    "_ZN13checked_int64ILb1EEpLERKS0_", "checked_int64<true>::operator+=(checked_int64<true> const&)",
    "checked_int64<true>::operator+=",
  ),
  (
    "_ZN4llvm22VarStreamArrayIteratorINS_8codeview15LineColumnEntryENS1_19LineColumnExtractorEEpLEj",
    "llvm::VarStreamArrayIterator<llvm::codeview::LineColumnEntry, llvm::codeview::LineColumnExtractor>::operator+=(unsigned int)",
    "llvm::VarStreamArrayIterator<llvm::codeview::LineColumnEntry, llvm::codeview::LineColumnExtractor>::operator+=",
  ),
  (
    "_ZN4llvm22VarStreamArrayIteratorINS_8codeview21CrossModuleImportItemENS_23VarStreamArrayExtractorIS2_EEEpLEj",
    "llvm::VarStreamArrayIterator<llvm::codeview::CrossModuleImportItem, llvm::VarStreamArrayExtractor<llvm::codeview::CrossModuleImportItem>>::operator+=(unsigned int)",
    "llvm::VarStreamArrayIterator<llvm::codeview::CrossModuleImportItem, llvm::VarStreamArrayExtractor<llvm::codeview::CrossModuleImportItem>>::operator+=",
  ),
  (
    "_ZN13checked_int64ILb1EEmIERKS0_", "checked_int64<true>::operator-=(checked_int64<true> const&)",
    "checked_int64<true>::operator-=",
  ),
  (
    "_ZN16inf_eps_rationalI12inf_rationalEmIERKS1_", "inf_eps_rational<inf_rational>::operator-=(inf_eps_rational<inf_rational> const&)",
    "inf_eps_rational<inf_rational>::operator-=",
  ),
  (
    "_ZN16inf_eps_rationalI12inf_rationalEmIERKS0_", "inf_eps_rational<inf_rational>::operator-=(inf_rational const&)",
    "inf_eps_rational<inf_rational>::operator-=",
  ),
  (
    "_ZN2v88internal13StringToIndexINS0_21StringCharacterStreamEmLNS0_11ToIndexModeE1EEEbPT_PT0_",
    "bool v8::internal::StringToIndex<v8::internal::StringCharacterStream, unsigned long, (v8::internal::ToIndexMode)1>(v8::internal::StringCharacterStream*, unsigned long*)",
    "v8::internal::StringToIndex<v8::internal::StringCharacterStream, unsigned long, (v8::internal::ToIndexMode)1>",
  ),
  (
    "_ZN4llvm13SmallDenseMapIPNS_7PHINodeEmLj32ENS_12DenseMapInfoIS2_vEENS_6detail12DenseMapPairIS2_mEEE4killEv",
    "llvm::SmallDenseMap<llvm::PHINode*, unsigned long, 32u, llvm::DenseMapInfo<llvm::PHINode*, void>, llvm::detail::DenseMapPair<llvm::PHINode*, unsigned long>>::kill()",
    "llvm::SmallDenseMap<llvm::PHINode*, unsigned long, 32u, llvm::DenseMapInfo<llvm::PHINode*, void>, llvm::detail::DenseMapPair<llvm::PHINode*, unsigned long>>::kill",
  ),
  (
    "_ZN13checked_int64ILb1EEmLERKS0_", "checked_int64<true>::operator*=(checked_int64<true> const&)",
    "checked_int64<true>::operator*=",
  ),
  (
    "_ZN16inf_eps_rationalI12inf_rationalEmLERK8rational", "inf_eps_rational<inf_rational>::operator*=(rational const&)",
    "inf_eps_rational<inf_rational>::operator*=",
  ),
  (
    "_ZN4llvm12ScaledNumberIyEmLERKS1_", "llvm::ScaledNumber<unsigned long long>::operator*=(llvm::ScaledNumber<unsigned long long> const&)",
    "llvm::ScaledNumber<unsigned long long>::operator*=",
  ),
  (
    "_ZN4llvm12ScaledNumberIyEdVERKS1_", "llvm::ScaledNumber<unsigned long long>::operator/=(llvm::ScaledNumber<unsigned long long> const&)",
    "llvm::ScaledNumber<unsigned long long>::operator/=",
  ),
  (
    "_ZN16inf_eps_rationalI12inf_rationalEdVERK8rational", "inf_eps_rational<inf_rational>::operator/=(rational const&)",
    "inf_eps_rational<inf_rational>::operator/=",
  ),
  (
    "_ZN4mlir4math7IsNaNOp6createERNS_9OpBuilderENS_8LocationENS_5ValueENS_5arith13FastMathFlagsE",
    "mlir::math::IsNaNOp::create(mlir::OpBuilder&, mlir::Location, mlir::Value, mlir::arith::FastMathFlags)",
    "mlir::math::IsNaNOp::create",
  ),
  (
    "_ZN12_GLOBAL__N_127CheckedElementwiseOpPatternIN4mlir4math7IsNaNOpENS1_5spirv7IsNanOpEED1Ev",
    "(anonymous namespace)::CheckedElementwiseOpPattern<mlir::math::IsNaNOp, mlir::spirv::IsNanOp>::~CheckedElementwiseOpPattern()",
    "(anonymous namespace)::CheckedElementwiseOpPattern<mlir::math::IsNaNOp, mlir::spirv::IsNanOp>::~CheckedElementwiseOpPattern",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4math7IsNaNOpEED0Ev", "mlir::RegisteredOperationName::Model<mlir::math::IsNaNOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::math::IsNaNOp>::~Model",
  ),
  (
    "_ZTSN4mlir19OpConversionPatternINS_4math7IsNaNOpEEE", "typeinfo name for mlir::OpConversionPattern<mlir::math::IsNaNOp>",
    "typeinfo name for mlir::OpConversionPattern<mlir::math::IsNaNOp>",
  ),
  (
    "_ZN2v88internal8compiler29SimplifiedOperatorGlobalCache19NumberIsNaNOperatorD1Ev",
    "v8::internal::compiler::SimplifiedOperatorGlobalCache::NumberIsNaNOperator::~NumberIsNaNOperator()",
    "v8::internal::compiler::SimplifiedOperatorGlobalCache::NumberIsNaNOperator::~NumberIsNaNOperator",
  ),
  (
    "_ZN2v88internal8compiler13JSCallReducer17ReduceGlobalIsNaNEPNS1_4NodeE", "v8::internal::compiler::JSCallReducer::ReduceGlobalIsNaN(v8::internal::compiler::Node*)",
    "v8::internal::compiler::JSCallReducer::ReduceGlobalIsNaN",
  ),
  (
    "_ZN4mlir6detail14TypeIDResolverINS_4math7IsNaNOpEvE2idE", "mlir::detail::TypeIDResolver<mlir::math::IsNaNOp, void>::id",
    "mlir::detail::TypeIDResolver<mlir::math::IsNaNOp, void>::id",
  ),
  ("_ZN4llvmL4NaNUE", "llvm::NaNU", "llvm::NaNU"),
  (
    "_ZN4mlir4math7IsNaNOp5buildERNS_9OpBuilderERNS_14OperationStateENS_4TypeENS_5ValueENS_5arith13FastMathFlagsE",
    "mlir::math::IsNaNOp::build(mlir::OpBuilder&, mlir::OperationState&, mlir::Type, mlir::Value, mlir::arith::FastMathFlags)",
    "mlir::math::IsNaNOp::build",
  ),
  (
    "_ZN4mlir4math7IsNaNOp11getFastmathEv", "mlir::math::IsNaNOp::getFastmath()",
    "mlir::math::IsNaNOp::getFastmath",
  ),
  (
    "_ZN4mlir4math7IsNaNOp14readPropertiesERNS_21DialectBytecodeReaderERNS_14OperationStateE",
    "mlir::math::IsNaNOp::readProperties(mlir::DialectBytecodeReader&, mlir::OperationState&)",
    "mlir::math::IsNaNOp::readProperties",
  ),
  (
    "_ZN4mlir4math7IsNaNOp6createERNS_20ImplicitLocOpBuilderENS_4TypeENS_5ValueENS_5arith17FastMathFlagsAttrE",
    "mlir::math::IsNaNOp::create(mlir::ImplicitLocOpBuilder&, mlir::Type, mlir::Value, mlir::arith::FastMathFlagsAttr)",
    "mlir::math::IsNaNOp::create",
  ),
  (
    "_ZN5clang15C11NoReturnAttrC2ERNS_10ASTContextERKNS_19AttributeCommonInfoE",
    "clang::C11NoReturnAttr::C11NoReturnAttr(clang::ASTContext&, clang::AttributeCommonInfo const&)",
    "clang::C11NoReturnAttr::C11NoReturnAttr",
  ),
  (
    "_ZTVN12_GLOBAL__N_119AANoRecurseCallSiteE", "vtable for (anonymous namespace)::AANoRecurseCallSite",
    "vtable for (anonymous namespace)::AANoRecurseCallSite",
  ),
  (
    "_ZN4llvm7AArch6437ZPR4_with_zsub1_in_ZPRMul2_LoRegClassE", "llvm::AArch64::ZPR4_with_zsub1_in_ZPRMul2_LoRegClass",
    "llvm::AArch64::ZPR4_with_zsub1_in_ZPRMul2_LoRegClass",
  ),
  (
    "_ZN5clang20AnalyzerNoReturnAttrC1ERNS_10ASTContextERKNS_19AttributeCommonInfoE",
    "clang::AnalyzerNoReturnAttr::AnalyzerNoReturnAttr(clang::ASTContext&, clang::AttributeCommonInfo const&)",
    "clang::AnalyzerNoReturnAttr::AnalyzerNoReturnAttr",
  ),
  (
    "_ZNK5clang12FunctionDecl18isAnalyzerNoReturnEv", "clang::FunctionDecl::isAnalyzerNoReturn() const",
    "clang::FunctionDecl::isAnalyzerNoReturn",
  ),
  (
    "_ZTSN4llvm6detail9PassModelINS_6ModuleENS_25NoRecurseLTOInferencePassENS_15AnalysisManagerIS2_JEEEJEEE",
    "typeinfo name for llvm::detail::PassModel<llvm::Module, llvm::NoRecurseLTOInferencePass, llvm::AnalysisManager<llvm::Module>>",
    "typeinfo name for llvm::detail::PassModel<llvm::Module, llvm::NoRecurseLTOInferencePass, llvm::AnalysisManager<llvm::Module>>",
  ),
  (
    "_ZN4llvm7AArch6419ZPR2Mul2_LoRegClassE", "llvm::AArch64::ZPR2Mul2_LoRegClass",
    "llvm::AArch64::ZPR2Mul2_LoRegClass",
  ),
  (
    "_ZN4llvm7AArch6469ZPR4_with_zsub_in_FPR128_lo_and_ZPR4_with_zsub3_in_ZPRMul2_LoRegClassE",
    "llvm::AArch64::ZPR4_with_zsub_in_FPR128_lo_and_ZPR4_with_zsub3_in_ZPRMul2_LoRegClass",
    "llvm::AArch64::ZPR4_with_zsub_in_FPR128_lo_and_ZPR4_with_zsub3_in_ZPRMul2_LoRegClass",
  ),
  (
    "_ZN4llvm7AArch6444ZPR2Strided_with_zsub0_in_ZPRMul2_LoRegClassE", "llvm::AArch64::ZPR2Strided_with_zsub0_in_ZPRMul2_LoRegClass",
    "llvm::AArch64::ZPR2Strided_with_zsub0_in_ZPRMul2_LoRegClass",
  ),
  (
    "_ZNK4llvm6detail9PassModelINS_6ModuleENS_25NoRecurseLTOInferencePassENS_15AnalysisManagerIS2_JEEEJEE4nameEv",
    "llvm::detail::PassModel<llvm::Module, llvm::NoRecurseLTOInferencePass, llvm::AnalysisManager<llvm::Module>>::name() const",
    "llvm::detail::PassModel<llvm::Module, llvm::NoRecurseLTOInferencePass, llvm::AnalysisManager<llvm::Module>>::name",
  ),
  (
    "_ZN12_GLOBAL__N_119AANoRecurseFunctionD1Ev", "(anonymous namespace)::AANoRecurseFunction::~AANoRecurseFunction()",
    "(anonymous namespace)::AANoRecurseFunction::~AANoRecurseFunction",
  ),
  (
    "_ZTVN12_GLOBAL__N_122ParsedAttrInfoNoReturnE", "vtable for (anonymous namespace)::ParsedAttrInfoNoReturn",
    "vtable for (anonymous namespace)::ParsedAttrInfoNoReturn",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_7wasmssa4NeOpEE18getParseAssemblyFnEv",
    "mlir::RegisteredOperationName::Model<mlir::wasmssa::NeOp>::getParseAssemblyFn()",
    "mlir::RegisteredOperationName::Model<mlir::wasmssa::NeOp>::getParseAssemblyFn",
  ),
  (
    "_ZN4mlir7wasmssa4LeOp6createERNS_9OpBuilderENS_8LocationENS_5ValueES5_", "mlir::wasmssa::LeOp::create(mlir::OpBuilder&, mlir::Location, mlir::Value, mlir::Value)",
    "mlir::wasmssa::LeOp::create",
  ),
  (
    "_ZTIN4mlir23RegisteredOperationName5ModelINS_7wasmssa4NeOpEEE", "typeinfo for mlir::RegisteredOperationName::Model<mlir::wasmssa::NeOp>",
    "typeinfo for mlir::RegisteredOperationName::Model<mlir::wasmssa::NeOp>",
  ),
  (
    "_ZN4mlir7wasmssa4LeOp21computePropertiesHashERKNS_15EmptyPropertiesE", "mlir::wasmssa::LeOp::computePropertiesHash(mlir::EmptyProperties const&)",
    "mlir::wasmssa::LeOp::computePropertiesHash",
  ),
  (
    "_ZN4mlir7wasmssa6detail22NeOpGenericAdaptorBaseC2ENS0_4NeOpE", "mlir::wasmssa::detail::NeOpGenericAdaptorBase::NeOpGenericAdaptorBase(mlir::wasmssa::NeOp)",
    "mlir::wasmssa::detail::NeOpGenericAdaptorBase::NeOpGenericAdaptorBase",
  ),
  (
    "_ZN2v88internal8compiler26MachineOperatorGlobalCache15I32x8NeOperatorD0Ev",
    "v8::internal::compiler::MachineOperatorGlobalCache::I32x8NeOperator::~I32x8NeOperator()",
    "v8::internal::compiler::MachineOperatorGlobalCache::I32x8NeOperator::~I32x8NeOperator",
  ),
  (
    "_ZN2v88internal8compiler26MachineOperatorGlobalCache15I32x8NeOperatorD1Ev",
    "v8::internal::compiler::MachineOperatorGlobalCache::I32x8NeOperator::~I32x8NeOperator()",
    "v8::internal::compiler::MachineOperatorGlobalCache::I32x8NeOperator::~I32x8NeOperator",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_7wasmssa4NeOpEE21getOpPropertyByteSizeEv",
    "mlir::RegisteredOperationName::Model<mlir::wasmssa::NeOp>::getOpPropertyByteSize()",
    "mlir::RegisteredOperationName::Model<mlir::wasmssa::NeOp>::getOpPropertyByteSize",
  ),
  (
    "_ZN4mlir4NVVM12LaneMaskLeOp15setInherentAttrERNS_15EmptyPropertiesEN4llvm9StringRefENS_9AttributeE",
    "mlir::NVVM::LaneMaskLeOp::setInherentAttr(mlir::EmptyProperties&, llvm::StringRef, mlir::Attribute)",
    "mlir::NVVM::LaneMaskLeOp::setInherentAttr",
  ),
  (
    "_ZN4mlir7wasmssa11NeOpAdaptorC1ENS0_4NeOpE", "mlir::wasmssa::NeOpAdaptor::NeOpAdaptor(mlir::wasmssa::NeOp)",
    "mlir::wasmssa::NeOpAdaptor::NeOpAdaptor",
  ),
  (
    "_ZN2v88internal8compiler26MachineOperatorGlobalCache15I8x16NeOperatorD1Ev",
    "v8::internal::compiler::MachineOperatorGlobalCache::I8x16NeOperator::~I8x16NeOperator()",
    "v8::internal::compiler::MachineOperatorGlobalCache::I8x16NeOperator::~I8x16NeOperator",
  ),
  (
    "_ZN4mlir7wasmssa11NeOpAdaptor6verifyENS_8LocationE", "mlir::wasmssa::NeOpAdaptor::verify(mlir::Location)",
    "mlir::wasmssa::NeOpAdaptor::verify",
  ),
  (
    "_ZN5clang26NoTrivialPPDirectiveTracer4ElseENS_14SourceLocationES1_", "clang::NoTrivialPPDirectiveTracer::Else(clang::SourceLocation, clang::SourceLocation)",
    "clang::NoTrivialPPDirectiveTracer::Else",
  ),
  (
    "_ZN4LIEF2PElsERNSt3__113basic_ostreamIcNS1_11char_traitsIcEEEERKNS0_19ResourceAcceleratorE",
    "LIEF::PE::operator<<(std::__1::basic_ostream<char, std::__1::char_traits<char>>&, LIEF::PE::ResourceAccelerator const&)",
    "LIEF::PE::operator<<",
  ),
  (
    "_ZTVN4llvm2cl11OptionValueINS_3lsp15JSONStreamStyleEEE", "vtable for llvm::cl::OptionValue<llvm::lsp::JSONStreamStyle>",
    "vtable for llvm::cl::OptionValue<llvm::lsp::JSONStreamStyle>",
  ),
  (
    "_ZN4llvm3lsp22adjustKindToCapabilityENS0_18CompletionItemKindERNSt3__16bitsetILm26EEE",
    "llvm::lsp::adjustKindToCapability(llvm::lsp::CompletionItemKind, std::__1::bitset<26ul>&)",
    "llvm::lsp::adjustKindToCapability",
  ),
  (
    "_ZTSN12_GLOBAL__N_116SimplifyDeadElseE", "typeinfo name for (anonymous namespace)::SimplifyDeadElse",
    "typeinfo name for (anonymous namespace)::SimplifyDeadElse",
  ),
  (
    "_ZN5GpgMElsERNSt3__113basic_ostreamIcNS0_11char_traitsIcEEEENS_13SignatureModeE",
    "GpgME::operator<<(std::__1::basic_ostream<char, std::__1::char_traits<char>>&, GpgME::SignatureMode)",
    "GpgME::operator<<",
  ),
  (
    "_ZN5GpgMElsERNSt3__113basic_ostreamIcNS0_11char_traitsIcEEEERKNS_13RevocationKeyE",
    "GpgME::operator<<(std::__1::basic_ostream<char, std::__1::char_traits<char>>&, GpgME::RevocationKey const&)",
    "GpgME::operator<<",
  ),
  (
    "_ZTIN4llvm2cl6parserINS_3lsp15JSONStreamStyleEEE", "typeinfo for llvm::cl::parser<llvm::lsp::JSONStreamStyle>",
    "typeinfo for llvm::cl::parser<llvm::lsp::JSONStreamStyle>",
  ),
  (
    "_ZN4llvm3lsp6toJSONERKNS0_8LocationE", "llvm::lsp::toJSON(llvm::lsp::Location const&)",
    "llvm::lsp::toJSON",
  ),
  (
    "_ZN4llvm3lsp8fromJSONERKNS_4json5ValueERNS0_10DiagnosticENS1_4PathE", "llvm::lsp::fromJSON(llvm::json::Value const&, llvm::lsp::Diagnostic&, llvm::json::Path)",
    "llvm::lsp::fromJSON",
  ),
  (
    "_ZN5GpgMElsERNSt3__113basic_ostreamIcNS0_11char_traitsIcEEEERKNS_14VfsMountResultE",
    "GpgME::operator<<(std::__1::basic_ostream<char, std::__1::char_traits<char>>&, GpgME::VfsMountResult const&)",
    "GpgME::operator<<",
  ),
  (
    "_ZTIN4llvm2cl3optINS_3lsp6Logger5LevelELb0ENS0_6parserIS4_EEEE", "typeinfo for llvm::cl::opt<llvm::lsp::Logger::Level, false, llvm::cl::parser<llvm::lsp::Logger::Level>>",
    "typeinfo for llvm::cl::opt<llvm::lsp::Logger::Level, false, llvm::cl::parser<llvm::lsp::Logger::Level>>",
  ),
  (
    "_ZN4rsvg7element12ElementTrait6layout17he9c8defc9ddba683E", "rsvg::element::ElementTrait::layout::he9c8defc9ddba683",
    "rsvg::element::ElementTrait::layout::he9c8defc9ddba683",
  ),
  (
    "_ZN4ring3rsa7padding5pkcs112pkcs1_encode17hdbacc4bb6fdf75bbE", "ring::rsa::padding::pkcs1::pkcs1_encode::hdbacc4bb6fdf75bb",
    "ring::rsa::padding::pkcs1::pkcs1_encode::hdbacc4bb6fdf75bb",
  ),
  (
    "_ZN4rsvg7element13set_attribute17h48b4b24b18203aa6E", "rsvg::element::set_attribute::h48b4b24b18203aa6",
    "rsvg::element::set_attribute::h48b4b24b18203aa6",
  ),
  (
    "_ZN4rsvg8gradient14LinearGradient14get_unresolved17h8e7290175be9a502E", "rsvg::gradient::LinearGradient::get_unresolved::h8e7290175be9a502",
    "rsvg::gradient::LinearGradient::get_unresolved::h8e7290175be9a502",
  ),
  (
    "_ZN4rsvg11drawing_ctx10DrawingCtx12get_snapshot17ha5db126d1d824276E", "rsvg::drawing_ctx::DrawingCtx::get_snapshot::ha5db126d1d824276",
    "rsvg::drawing_ctx::DrawingCtx::get_snapshot::ha5db126d1d824276",
  ),
  (
    "_ZN4rsvg7element12ElementTrait6layout17hcc891c67156ac0a1E", "rsvg::element::ElementTrait::layout::hcc891c67156ac0a1",
    "rsvg::element::ElementTrait::layout::hcc891c67156ac0a1",
  ),
  (
    "_ZN4rsvg10properties11parse_input17h152335614174db12E", "rsvg::properties::parse_input::h152335614174db12",
    "rsvg::properties::parse_input::h152335614174db12",
  ),
  (
    "_ZN4rsvg12url_resolver11UrlResolver12resolve_href17h03b457c59f413e1dE", "rsvg::url_resolver::UrlResolver::resolve_href::h03b457c59f413e1d",
    "rsvg::url_resolver::UrlResolver::resolve_href::h03b457c59f413e1d",
  ),
  (
    "_ZN4rsvg13surface_utils9iterators14PixelRectangle6within17h7875870c855f7296E",
    "rsvg::surface_utils::iterators::PixelRectangle::within::h7875870c855f7296",
    "rsvg::surface_utils::iterators::PixelRectangle::within::h7875870c855f7296",
  ),
  (
    "_ZN4rsvg7element13set_attribute17h40f85b9958b1b128E", "rsvg::element::set_attribute::h40f85b9958b1b128",
    "rsvg::element::set_attribute::h40f85b9958b1b128",
  ),
  (
    "_ZN4rsvg4cond16RequiredFeatures14from_attribute17h54b27f7fe86886d7E", "rsvg::cond::RequiredFeatures::from_attribute::h54b27f7fe86886d7",
    "rsvg::cond::RequiredFeatures::from_attribute::h54b27f7fe86886d7",
  ),
  (
    "_ZN4rsvg10cairo_path9CairoPath26has_unsuitable_coordinates17h3f6788333ce385ecE",
    "rsvg::cairo_path::CairoPath::has_unsuitable_coordinates::h3f6788333ce385ec",
    "rsvg::cairo_path::CairoPath::has_unsuitable_coordinates::h3f6788333ce385ec",
  ),
  (
    "_ZNSt3__16bitsetILm96EErSB9nqn210106Em", "std::__1::bitset<96ul>::operator>>=[abi:nqn210106](unsigned long)",
    "std::__1::bitset<96ul>::operator>>=[abi:nqn210106]",
  ),
  (
    "_ZNSt3__16bitsetILm128EErSB9nqn210106Em", "std::__1::bitset<128ul>::operator>>=[abi:nqn210106](unsigned long)",
    "std::__1::bitset<128ul>::operator>>=[abi:nqn210106]",
  ),
  (
    "_ZNSt3__16bitsetILm128EErSB8nn190102Em", "std::__1::bitset<128ul>::operator>>=[abi:nn190102](unsigned long)",
    "std::__1::bitset<128ul>::operator>>=[abi:nn190102]",
  ),
  (
    "_ZNSt3__16bitsetILm16EErSB8nn190102Em", "std::__1::bitset<16ul>::operator>>=[abi:nn190102](unsigned long)",
    "std::__1::bitset<16ul>::operator>>=[abi:nn190102]",
  ),
  (
    "_ZN4LIEF8assembly7aarch64eqERKNS1_7Operand8IteratorES5_", "LIEF::assembly::aarch64::operator==(LIEF::assembly::aarch64::Operand::Iterator const&, LIEF::assembly::aarch64::Operand::Iterator const&)",
    "LIEF::assembly::aarch64::operator==",
  ),
  (
    "_ZNK4llvm11logicalview7LVScope21equalNumberOfChildrenEPKS1_", "llvm::logicalview::LVScope::equalNumberOfChildren(llvm::logicalview::LVScope const*) const",
    "llvm::logicalview::LVScope::equalNumberOfChildren",
  ),
  (
    "_ZNK4llvm9StringMapINS_9FuncDataTINS_9EmptyDataEEENS_15MallocAllocatorEEeqERKS5_",
    "llvm::StringMap<llvm::FuncDataT<llvm::EmptyData>, llvm::MallocAllocator>::operator==(llvm::StringMap<llvm::FuncDataT<llvm::EmptyData>, llvm::MallocAllocator> const&) const",
    "llvm::StringMap<llvm::FuncDataT<llvm::EmptyData>, llvm::MallocAllocator>::operator==",
  ),
  (
    "_ZNSt3__112__hash_tableIPiNS_4hashIS1_EENS_8equal_toIS1_EENS_9allocatorIS1_EEE11__do_rehashILb1EEEvm",
    "void std::__1::__hash_table<int*, std::__1::hash<int*>, std::__1::equal_to<int*>, std::__1::allocator<int*>>::__do_rehash<true>(unsigned long)",
    "std::__1::__hash_table<int*, std::__1::hash<int*>, std::__1::equal_to<int*>, std::__1::allocator<int*>>::__do_rehash<true>",
  ),
  (
    "_ZNK4llvm13GVNExpression24AggregateValueExpression6equalsERKNS0_10ExpressionE",
    "llvm::GVNExpression::AggregateValueExpression::equals(llvm::GVNExpression::Expression const&) const",
    "llvm::GVNExpression::AggregateValueExpression::equals",
  ),
  (
    "_ZNK4mlir5shard8Sharding14equalSplitAxesERKS1_", "mlir::shard::Sharding::equalSplitAxes(mlir::shard::Sharding const&) const",
    "mlir::shard::Sharding::equalSplitAxes",
  ),
  (
    "_ZNSt3__112__hash_tableIPN2v88internal8compiler4NodeENS_4hashIS5_EENS_8equal_toIS5_EENS_9allocatorIS5_EEED2Ev",
    "std::__1::__hash_table<v8::internal::compiler::Node*, std::__1::hash<v8::internal::compiler::Node*>, std::__1::equal_to<v8::internal::compiler::Node*>, std::__1::allocator<v8::internal::compiler::Node*>>::~__hash_table()",
    "std::__1::__hash_table<v8::internal::compiler::Node*, std::__1::hash<v8::internal::compiler::Node*>, std::__1::equal_to<v8::internal::compiler::Node*>, std::__1::allocator<v8::internal::compiler::Node*>>::~__hash_table",
  ),
  (
    "_ZTINSt3__110__function6__funcIZN3nla7grobner19propagate_quotientsERKN2dd6solver8equationEE3$_0F8rationaljEEE",
    "typeinfo for std::__1::__function::__func<nla::grobner::propagate_quotients(dd::solver::equation const&)::$_0, rational (unsigned int)>",
    "typeinfo for std::__1::__function::__func<nla::grobner::propagate_quotients(dd::solver::equation const&)::$_0, rational (unsigned int)>",
  ),
  (
    "_ZN12eq2bv_tactic4bvmc9translateER15ast_translation", "eq2bv_tactic::bvmc::translate(ast_translation&)",
    "eq2bv_tactic::bvmc::translate",
  ),
  (
    "_ZN3seq2eqC2ER10ref_vectorI4expr11ast_managerES5_", "seq::eq::eq(ref_vector<expr, ast_manager>&, ref_vector<expr, ast_manager>&)",
    "seq::eq::eq",
  ),
  (
    "_ZNK12mpff_manager2eqERK4mpffS2_", "mpff_manager::eq(mpff const&, mpff const&) const",
    "mpff_manager::eq",
  ),
  (
    "_ZN12eq2bv_tactic9translateER11ast_manager", "eq2bv_tactic::translate(ast_manager&)",
    "eq2bv_tactic::translate",
  ),
  (
    "_ZN5pango4auto16font_description15FontDescription3new17h5e0ba3e27ecb320fE",
    "pango::auto::font_description::FontDescription::new::h5e0ba3e27ecb320f", "pango::auto::font_description::FontDescription::new::h5e0ba3e27ecb320f",
  ),
  (
    "_ZN2v88internal17ExternalReference24new_deoptimizer_functionEv", "v8::internal::ExternalReference::new_deoptimizer_function()",
    "v8::internal::ExternalReference::new_deoptimizer_function",
  ),
  (
    "_ZNKSt3__129_AllocatorDestroyRangeReverseINS_9allocatorIN13PageLabelInfo8IntervalEEEPS3_EclB8ne200100Ev",
    "std::__1::_AllocatorDestroyRangeReverse<std::__1::allocator<PageLabelInfo::Interval>, PageLabelInfo::Interval*>::operator()[abi:ne200100]() const",
    "std::__1::_AllocatorDestroyRangeReverse<std::__1::allocator<PageLabelInfo::Interval>, PageLabelInfo::Interval*>::operator()[abi:ne200100]",
  ),
  (
    "_ZNSt3__16vectorINS_4pairIiiEENS_9allocatorIS2_EEE11__vallocateB8ne200100Em",
    "std::__1::vector<std::__1::pair<int, int>, std::__1::allocator<std::__1::pair<int, int>>>::__vallocate[abi:ne200100](unsigned long)",
    "std::__1::vector<std::__1::pair<int, int>, std::__1::allocator<std::__1::pair<int, int>>>::__vallocate[abi:ne200100]",
  ),
  (
    "_ZNSt3__16vectorIPKcNS_9allocatorIS2_EEEC2B8ne190102Em", "std::__1::vector<char const*, std::__1::allocator<char const*>>::vector[abi:ne190102](unsigned long)",
    "std::__1::vector<char const*, std::__1::allocator<char const*>>::vector[abi:ne190102]",
  ),
  (
    "_ZN7datalog24external_relation_plugin18negation_filter_fnD0Ev", "datalog::external_relation_plugin::negation_filter_fn::~negation_filter_fn()",
    "datalog::external_relation_plugin::negation_filter_fn::~negation_filter_fn",
  ),
  (
    "_ZN3smt17theory_diff_logicINS_8sidl_extEE12new_diseq_ehEiiRNS_13justificationE",
    "smt::theory_diff_logic<smt::sidl_ext>::new_diseq_eh(int, int, smt::justification&)",
    "smt::theory_diff_logic<smt::sidl_ext>::new_diseq_eh",
  ),
  (
    "_ZN70_$LT$weezl..decode..MsbBuffer$u20$as$u20$weezl..decode..CodeBuffer$GT$11next_symbol17h415adcea4b5a361fE",
    "_$LT$weezl..decode..MsbBuffer$u20$as$u20$weezl..decode..CodeBuffer$GT$::next_symbol::h415adcea4b5a361f",
    "_$LT$weezl..decode..MsbBuffer$u20$as$u20$weezl..decode..CodeBuffer$GT$::next_symbol::h415adcea4b5a361f",
  ),
  (
    "_ZNSt3__19allocatorIN4Form13AddFontResultEE17allocate_at_leastB8ne200100Em",
    "std::__1::allocator<Form::AddFontResult>::allocate_at_least[abi:ne200100](unsigned long)",
    "std::__1::allocator<Form::AddFontResult>::allocate_at_least[abi:ne200100]",
  ),
  (
    "_ZNSt3__16vectorINS_4pairIccEENS_9allocatorIS2_EEE9push_backB8ne200100EOS2_",
    "std::__1::vector<std::__1::pair<char, char>, std::__1::allocator<std::__1::pair<char, char>>>::push_back[abi:ne200100](std::__1::pair<char, char>&&)",
    "std::__1::vector<std::__1::pair<char, char>, std::__1::allocator<std::__1::pair<char, char>>>::push_back[abi:ne200100]",
  ),
  (
    "_ZNSt3__114__split_bufferIN13PageLabelInfo8IntervalERNS_9allocatorIS2_EEE17__destruct_at_endB8ne200100EPS2_",
    "std::__1::__split_buffer<PageLabelInfo::Interval, std::__1::allocator<PageLabelInfo::Interval>&>::__destruct_at_end[abi:ne200100](PageLabelInfo::Interval*)",
    "std::__1::__split_buffer<PageLabelInfo::Interval, std::__1::allocator<PageLabelInfo::Interval>&>::__destruct_at_end[abi:ne200100]",
  ),
  (
    "_ZNK4LIEF5MachO15RelocationFixup4nextEv", "LIEF::MachO::RelocationFixup::next() const",
    "LIEF::MachO::RelocationFixup::next",
  ),
  (
    "_ZN4heapIN9var_queueI7svectorIjjEE2ltEE5eraseEi", "heap<var_queue<svector<unsigned int, unsigned int>>::lt>::erase(int)",
    "heap<var_queue<svector<unsigned int, unsigned int>>::lt>::erase",
  ),
  (
    "_ZNK4llvm21AArch64TargetLowering31LowerFixedLengthInsertVectorEltENS_7SDValueERNS_12SelectionDAGE",
    "llvm::AArch64TargetLowering::LowerFixedLengthInsertVectorElt(llvm::SDValue, llvm::SelectionDAG&) const",
    "llvm::AArch64TargetLowering::LowerFixedLengthInsertVectorElt",
  ),
  (
    "_ZN4llvm3lto24LTOLLVMDiagnosticHandler17handleDiagnosticsERKNS_14DiagnosticInfoE",
    "llvm::lto::LTOLLVMDiagnosticHandler::handleDiagnostics(llvm::DiagnosticInfo const&)",
    "llvm::lto::LTOLLVMDiagnosticHandler::handleDiagnostics",
  ),
  (
    "_ZN4llvm16LTOCodeGenerator12setDebugInfoE15lto_debug_model", "llvm::LTOCodeGenerator::setDebugInfo(lto_debug_model)",
    "llvm::LTOCodeGenerator::setDebugInfo",
  ),
  (
    "_ZTIZL19moreEltsToNext32BitjE3$_0", "typeinfo for moreEltsToNext32Bit(unsigned int)::$_0",
    "typeinfo for moreEltsToNext32Bit(unsigned int)::$_0",
  ),
  (
    "_ZNK4llvm14CombinerHelper26applyExtractVecEltBuildVecERNS_12MachineInstrERNS_8RegisterE",
    "llvm::CombinerHelper::applyExtractVecEltBuildVec(llvm::MachineInstr&, llvm::Register&) const",
    "llvm::CombinerHelper::applyExtractVecEltBuildVec",
  ),
  (
    "_ZN4mlir4NVVM26symbolizeLdStMatrixEltTypeEN4llvm9StringRefE", "mlir::NVVM::symbolizeLdStMatrixEltType(llvm::StringRef)",
    "mlir::NVVM::symbolizeLdStMatrixEltType",
  ),
  (
    "_ZNK2lp12numeric_pairI8rationalEltERKS1_", "lp::numeric_pair<rational>::operator<(rational const&) const",
    "lp::numeric_pair<rational>::operator<",
  ),
  (
    "_ZTSZL23fewerEltsToSize64VectorjE3$_0", "typeinfo name for fewerEltsToSize64Vector(unsigned int)::$_0",
    "typeinfo name for fewerEltsToSize64Vector(unsigned int)::$_0",
  ),
  (
    "_ZNK4llvm14TargetLowering32shouldSimplifyDemandedVectorEltsENS_7SDValueERKNS0_17TargetLoweringOptE",
    "llvm::TargetLowering::shouldSimplifyDemandedVectorElts(llvm::SDValue, llvm::TargetLowering::TargetLoweringOpt const&) const",
    "llvm::TargetLowering::shouldSimplifyDemandedVectorElts",
  ),
  (
    "_ZN4mlir4NVVM6detail27WMMAMmaOpGenericAdaptorBase10getEltypeAEv", "mlir::NVVM::detail::WMMAMmaOpGenericAdaptorBase::getEltypeA()",
    "mlir::NVVM::detail::WMMAMmaOpGenericAdaptorBase::getEltypeA",
  ),
  (
    "_ZN15mpq_inf_managerILb0EE2ltERKNSt3__14pairI3mpqS3_EES6_", "mpq_inf_manager<false>::lt(std::__1::pair<mpq, mpq> const&, std::__1::pair<mpq, mpq> const&)",
    "mpq_inf_manager<false>::lt",
  ),
  (
    "_ZNK2lp12numeric_pairI8rationalEgtERKS1_", "lp::numeric_pair<rational>::operator>(rational const&) const",
    "lp::numeric_pair<rational>::operator>",
  ),
  (
    "_ZNK2lp12numeric_pairI8rationalEgtERKS2_", "lp::numeric_pair<rational>::operator>(lp::numeric_pair<rational> const&) const",
    "lp::numeric_pair<rational>::operator>",
  ),
  (
    "_ZN11mpf_manager3gteERK3mpfS2_", "mpf_manager::gte(mpf const&, mpf const&)",
    "mpf_manager::gte",
  ),
  (
    "_ZN11mpf_manager2gtERK3mpfS2_", "mpf_manager::gt(mpf const&, mpf const&)", "mpf_manager::gt",
  ),
  (
    "_ZNK5clang6interp10IntegralAPILb0EEgtERKS2_", "clang::interp::IntegralAP<false>::operator>(clang::interp::IntegralAP<false> const&) const",
    "clang::interp::IntegralAP<false>::operator>",
  ),
  (
    "_ZNK3nla11nex_creator2gtERKNS_3nexES3_", "nla::nex_creator::gt(nla::nex const&, nla::nex const&) const",
    "nla::nex_creator::gt",
  ),
  (
    "_ZN12_GLOBAL__N_13gtrERPKhRPiS3_R7regbank", "(anonymous namespace)::gtr(unsigned char const*&, int*&, int*, regbank&)",
    "(anonymous namespace)::gtr",
  ),
  (
    "_ZN12_GLOBAL__N_16gtr_eqERPKhRPiS3_R7regbank", "(anonymous namespace)::gtr_eq(unsigned char const*&, int*&, int*, regbank&)",
    "(anonymous namespace)::gtr_eq",
  ),
  (
    "_ZNK5clang6interp10IntegralAPILb1EEgtERKS2_", "clang::interp::IntegralAP<true>::operator>(clang::interp::IntegralAP<true> const&) const",
    "clang::interp::IntegralAP<true>::operator>",
  ),
  (
    "_ZN2v88internal4Zone8AllocateIA_NS0_4wasm17WasmModuleBuilder15WasmElemSegmentEEEPvm",
    "void* v8::internal::Zone::Allocate<v8::internal::wasm::WasmModuleBuilder::WasmElemSegment []>(unsigned long)",
    "v8::internal::Zone::Allocate<v8::internal::wasm::WasmModuleBuilder::WasmElemSegment []>",
  ),
  (
    "_ZN4mlir9transform26FlattenElementwiseLinalgOp6createERNS_20ImplicitLocOpBuilderENS_9TypeRangeENS_5ValueE",
    "mlir::transform::FlattenElementwiseLinalgOp::create(mlir::ImplicitLocOpBuilder&, mlir::TypeRange, mlir::Value)",
    "mlir::transform::FlattenElementwiseLinalgOp::create",
  ),
  (
    "_ZN12_GLOBAL__N_125NamedToElementwisePatternIN4mlir6linalg6SqrtOpEED1Ev", "(anonymous namespace)::NamedToElementwisePattern<mlir::linalg::SqrtOp>::~NamedToElementwisePattern()",
    "(anonymous namespace)::NamedToElementwisePattern<mlir::linalg::SqrtOp>::~NamedToElementwisePattern",
  ),
  (
    "_ZNK4llvm21HexagonTargetLowering21extractHvxElementPredENS_7SDValueES1_RKNS_5SDLocENS_3MVTERNS_12SelectionDAGE",
    "llvm::HexagonTargetLowering::extractHvxElementPred(llvm::SDValue, llvm::SDValue, llvm::SDLoc const&, llvm::MVT, llvm::SelectionDAG&) const",
    "llvm::HexagonTargetLowering::extractHvxElementPred",
  ),
  (
    "_ZN4mlir9transform31ApplyUnrollToElementsPatternsOp5parseERNS_11OpAsmParserERNS_14OperationStateE",
    "mlir::transform::ApplyUnrollToElementsPatternsOp::parse(mlir::OpAsmParser&, mlir::OperationState&)",
    "mlir::transform::ApplyUnrollToElementsPatternsOp::parse",
  ),
  (
    "_ZN4llvm14ConstantStruct18getTypeForElementsENS_8ArrayRefIPNS_8ConstantEEEb",
    "llvm::ConstantStruct::getTypeForElements(llvm::ArrayRef<llvm::Constant*>, bool)",
    "llvm::ConstantStruct::getTypeForElements",
  ),
  (
    "_ZN4mlir5spirv6detail30QueryMaxVersionInterfaceTraits5ModelINS0_22GroupNonUniformElectOpEED0Ev",
    "mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::GroupNonUniformElectOp>::~Model()",
    "mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::GroupNonUniformElectOp>::~Model",
  ),
  (
    "_ZN2v88internal8JSObject22TransitionElementsKindEPNS0_7IsolateENS0_12DirectHandleIS1_EENS0_12ElementsKindE",
    "v8::internal::JSObject::TransitionElementsKind(v8::internal::Isolate*, v8::internal::DirectHandle<v8::internal::JSObject>, v8::internal::ElementsKind)",
    "v8::internal::JSObject::TransitionElementsKind",
  ),
  (
    "_ZN2v88internal6maglev20MaglevGraphOptimizer43VisitStoreFixedArrayElementWithWriteBarrierEv",
    "v8::internal::maglev::MaglevGraphOptimizer::VisitStoreFixedArrayElementWithWriteBarrier()",
    "v8::internal::maglev::MaglevGraphOptimizer::VisitStoreFixedArrayElementWithWriteBarrier",
  ),
  (
    "_ZN2v88internal44StoreCurrentContextElementBaselineDescriptor13kMachineTypesE",
    "v8::internal::StoreCurrentContextElementBaselineDescriptor::kMachineTypes",
    "v8::internal::StoreCurrentContextElementBaselineDescriptor::kMachineTypes",
  ),
  (
    "_ZTSN4mlir6detail19ElementsAttrIndexer18NonContiguousState23OpaqueIteratorValueBaseINSt3__17complexIsEEEE",
    "typeinfo name for mlir::detail::ElementsAttrIndexer::NonContiguousState::OpaqueIteratorValueBase<std::__1::complex<short>>",
    "typeinfo name for mlir::detail::ElementsAttrIndexer::NonContiguousState::OpaqueIteratorValueBase<std::__1::complex<short>>",
  ),
  (
    "_ZN4llvm14ConstantStruct18getTypeForElementsERNS_11LLVMContextENS_8ArrayRefIPNS_8ConstantEEEb",
    "llvm::ConstantStruct::getTypeForElements(llvm::LLVMContext&, llvm::ArrayRef<llvm::Constant*>, bool)",
    "llvm::ConstantStruct::getTypeForElements",
  ),
  (
    "_Z17getNamedBarrierOpbj", "getNamedBarrierOp(bool, unsigned int)", "getNamedBarrierOp",
  ),
  (
    "_ZNK4llvm24CodeGenTargetMachineImpl22getTargetTransformInfoERKNS_8FunctionE",
    "llvm::CodeGenTargetMachineImpl::getTargetTransformInfo(llvm::Function const&) const",
    "llvm::CodeGenTargetMachineImpl::getTargetTransformInfo",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_7wasmssa7BlockOpEE18getParseAssemblyFnEv",
    "mlir::RegisteredOperationName::Model<mlir::wasmssa::BlockOp>::getParseAssemblyFn()",
    "mlir::RegisteredOperationName::Model<mlir::wasmssa::BlockOp>::getParseAssemblyFn",
  ),
  (
    "_ZNK4llvm6object15MachOObjectFile9getHeaderEv", "llvm::object::MachOObjectFile::getHeader() const",
    "llvm::object::MachOObjectFile::getHeader",
  ),
  (
    "_ZNK12_GLOBAL__N_125AAGlobalValueInfoFloating8getAsStrEPN4llvm10AttributorE",
    "(anonymous namespace)::AAGlobalValueInfoFloating::getAsStr(llvm::Attributor*) const",
    "(anonymous namespace)::AAGlobalValueInfoFloating::getAsStr",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5ROCDL15ds_read_tr6_b96EE18getParseAssemblyFnEv",
    "mlir::RegisteredOperationName::Model<mlir::ROCDL::ds_read_tr6_b96>::getParseAssemblyFn()",
    "mlir::RegisteredOperationName::Model<mlir::ROCDL::ds_read_tr6_b96>::getParseAssemblyFn",
  ),
  (
    "_ZN4mlir5emitc11UnaryPlusOp15getInherentAttrEPNS_11MLIRContextERKNS_15EmptyPropertiesEN4llvm9StringRefE",
    "mlir::emitc::UnaryPlusOp::getInherentAttr(mlir::MLIRContext*, mlir::EmptyProperties const&, llvm::StringRef)",
    "mlir::emitc::UnaryPlusOp::getInherentAttr",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_6linalg24WinogradInputTransformOpEE21getOpPropertyByteSizeEv",
    "mlir::RegisteredOperationName::Model<mlir::linalg::WinogradInputTransformOp>::getOpPropertyByteSize()",
    "mlir::RegisteredOperationName::Model<mlir::linalg::WinogradInputTransformOp>::getOpPropertyByteSize",
  ),
  (
    "_ZN4mlir5spirv8GLAtanOp13getMaxVersionEv", "mlir::spirv::GLAtanOp::getMaxVersion()",
    "mlir::spirv::GLAtanOp::getMaxVersion",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_26UnrealizedConversionCastOpEE18getParseAssemblyFnEv",
    "mlir::RegisteredOperationName::Model<mlir::UnrealizedConversionCastOp>::getParseAssemblyFn()",
    "mlir::RegisteredOperationName::Model<mlir::UnrealizedConversionCastOp>::getParseAssemblyFn",
  ),
  (
    "_ZN4mlir5spirv8CLAtanOp13getMinVersionEv", "mlir::spirv::CLAtanOp::getMinVersion()",
    "mlir::spirv::CLAtanOp::getMinVersion",
  ),
  (
    "_ZN4mlir9transform17TileUsingForallOp27getODSOperandIndexAndLengthEj", "mlir::transform::TileUsingForallOp::getODSOperandIndexAndLength(unsigned int)",
    "mlir::transform::TileUsingForallOp::getODSOperandIndexAndLength",
  ),
  (
    "_ZN4node6crypto7TLSWrap17PskServerCallbackEP6ssl_stPKcPhj", "node::crypto::TLSWrap::PskServerCallback(ssl_st*, char const*, unsigned char*, unsigned int)",
    "node::crypto::TLSWrap::PskServerCallback",
  ),
  (
    "_ZN4node6crypto12_GLOBAL__N_118NewSessionCallbackEP6ssl_stP14ssl_session_st.cold.1",
    "node::crypto::(anonymous namespace)::NewSessionCallback(ssl_st*, ssl_session_st*) (.cold.1)",
    "node::crypto::(anonymous namespace)::NewSessionCallback",
  ),
  (
    "_ZN4node6crypto29SSL_CTX_use_certificate_chainEP10ssl_ctx_stON7ncrypto10BIOPointerEPNS3_11X509PointerES7_",
    "node::crypto::SSL_CTX_use_certificate_chain(ssl_ctx_st*, ncrypto::BIOPointer&&, ncrypto::X509Pointer*, ncrypto::X509Pointer*)",
    "node::crypto::SSL_CTX_use_certificate_chain",
  ),
  (
    "_ZNK5clang4ssaf20NestedBuildNamespaceneERKS1_", "clang::ssaf::NestedBuildNamespace::operator!=(clang::ssaf::NestedBuildNamespace const&) const",
    "clang::ssaf::NestedBuildNamespace::operator!=",
  ),
  (
    "_ZNK5clang4ssaf20NestedBuildNamespace5emptyEv", "clang::ssaf::NestedBuildNamespace::empty() const",
    "clang::ssaf::NestedBuildNamespace::empty",
  ),
  (
    "_ZN25NSSSignatureConfiguration7sNssDirE", "NSSSignatureConfiguration::sNssDir",
    "NSSSignatureConfiguration::sNssDir",
  ),
  (
    "_ZN2v88internal9Assembler4sshrERKNS0_9VRegisterES4_i", "v8::internal::Assembler::sshr(v8::internal::VRegister const&, v8::internal::VRegister const&, int)",
    "v8::internal::Assembler::sshr",
  ),
  (
    "_ZNK5clang4ssaf14BuildNamespaceeqERKS1_", "clang::ssaf::BuildNamespace::operator==(clang::ssaf::BuildNamespace const&) const",
    "clang::ssaf::BuildNamespace::operator==",
  ),
  (
    "_ZZN4node6crypto12_GLOBAL__N_118NewSessionCallbackEP6ssl_stP14ssl_session_stE20error_and_abort_args",
    "node::crypto::(anonymous namespace)::NewSessionCallback(ssl_st*, ssl_session_st*)::error_and_abort_args",
    "node::crypto::(anonymous namespace)::NewSessionCallback(ssl_st*, ssl_session_st*)::error_and_abort_args",
  ),
  (
    "_ZNK5clang4ssaf14BuildNamespaceneERKS1_", "clang::ssaf::BuildNamespace::operator!=(clang::ssaf::BuildNamespace const&) const",
    "clang::ssaf::BuildNamespace::operator!=",
  ),
  (
    "_ZN5clang4ssaf22getEntityNameForReturnEPKNS_12FunctionDeclE", "clang::ssaf::getEntityNameForReturn(clang::FunctionDecl const*)",
    "clang::ssaf::getEntityNameForReturn",
  ),
  (
    "_ZN4node6crypto12_GLOBAL__N_115SSLCertCallbackEP6ssl_stPv", "node::crypto::(anonymous namespace)::SSLCertCallback(ssl_st*, void*)",
    "node::crypto::(anonymous namespace)::SSLCertCallback",
  ),
  (
    "_ZN4llvm6object22MachOChainedFixupEntryC1EPNS_5ErrorEPKNS0_15MachOObjectFileEb",
    "llvm::object::MachOChainedFixupEntry::MachOChainedFixupEntry(llvm::Error*, llvm::object::MachOObjectFile const*, bool)",
    "llvm::object::MachOChainedFixupEntry::MachOChainedFixupEntry",
  ),
  (
    "_ZN5clang7CodeGen15CodeGenFunction15EnterSEHTryStmtERKNS_10SEHTryStmtE", "clang::CodeGen::CodeGenFunction::EnterSEHTryStmt(clang::SEHTryStmt const&)",
    "clang::CodeGen::CodeGenFunction::EnterSEHTryStmt",
  ),
  (
    "_ZN4llvm10RegionBaseINS_12RegionTraitsINS_8FunctionEEEE12replaceEntryEPNS_10BasicBlockE",
    "llvm::RegionBase<llvm::RegionTraits<llvm::Function>>::replaceEntry(llvm::BasicBlock*)",
    "llvm::RegionBase<llvm::RegionTraits<llvm::Function>>::replaceEntry",
  ),
  (
    "_ZN4llvm9DWARFUnit9getParentEPKNS_19DWARFDebugInfoEntryE", "llvm::DWARFUnit::getParent(llvm::DWARFDebugInfoEntry const*)",
    "llvm::DWARFUnit::getParent",
  ),
  (
    "_ZN12_GLOBAL__N_120PPCTargetAsmStreamer11emitTCEntryERKN4llvm8MCSymbolEt", "(anonymous namespace)::PPCTargetAsmStreamer::emitTCEntry(llvm::MCSymbol const&, unsigned short)",
    "(anonymous namespace)::PPCTargetAsmStreamer::emitTCEntry",
  ),
  (
    "_ZNK12_GLOBAL__N_131PostInlineEntryExitInstrumenter16getAnalysisUsageERN4llvm13AnalysisUsageE",
    "(anonymous namespace)::PostInlineEntryExitInstrumenter::getAnalysisUsage(llvm::AnalysisUsage&) const",
    "(anonymous namespace)::PostInlineEntryExitInstrumenter::getAnalysisUsage",
  ),
  (
    "_ZN4mlir6detail24getDefaultLegalIntWidthsENS_24DataLayoutEntryInterfaceE", "mlir::detail::getDefaultLegalIntWidths(mlir::DataLayoutEntryInterface)",
    "mlir::detail::getDefaultLegalIntWidths",
  ),
  (
    "_ZNSt3__16vectorIN4llvm4yaml21SaveRestorePointEntryENS_9allocatorIS3_EEE8__appendEm",
    "std::__1::vector<llvm::yaml::SaveRestorePointEntry, std::__1::allocator<llvm::yaml::SaveRestorePointEntry>>::__append(unsigned long)",
    "std::__1::vector<llvm::yaml::SaveRestorePointEntry, std::__1::allocator<llvm::yaml::SaveRestorePointEntry>>::__append",
  ),
  (
    "_ZN2v88internal12_GLOBAL__N_117DebugBreakAtEntryEPNS0_7IsolateEm", "v8::internal::(anonymous namespace)::DebugBreakAtEntry(v8::internal::Isolate*, unsigned long)",
    "v8::internal::(anonymous namespace)::DebugBreakAtEntry",
  ),
  (
    "_ZTSN12_GLOBAL__N_112SectionEntryE", "typeinfo name for (anonymous namespace)::SectionEntry",
    "typeinfo name for (anonymous namespace)::SectionEntry",
  ),
  (
    "_ZN4llvm3vfs21RedirectingFileSystem5EntryD0Ev", "llvm::vfs::RedirectingFileSystem::Entry::~Entry()",
    "llvm::vfs::RedirectingFileSystem::Entry::~Entry",
  ),
  (
    "_ZNK4LIEF3ELF12DynamicEntry6acceptERNS_7VisitorE", "LIEF::ELF::DynamicEntry::accept(LIEF::Visitor&) const",
    "LIEF::ELF::DynamicEntry::accept",
  ),
  (
    "_ZN4mlir7arm_sme22aarch64_sme_write_vert6createERNS_20ImplicitLocOpBuilderENS_9TypeRangeEjNS_5ValueES5_S5_",
    "mlir::arm_sme::aarch64_sme_write_vert::create(mlir::ImplicitLocOpBuilder&, mlir::TypeRange, unsigned int, mlir::Value, mlir::Value, mlir::Value)",
    "mlir::arm_sme::aarch64_sme_write_vert::create",
  ),
  (
    "_ZN4mlir7arm_sme30aarch64_sme_sumops_wideAdaptor6verifyENS_8LocationE", "mlir::arm_sme::aarch64_sme_sumops_wideAdaptor::verify(mlir::Location)",
    "mlir::arm_sme::aarch64_sme_sumops_wideAdaptor::verify",
  ),
  (
    "_ZN4llvm7jitlink7aarch3212_GLOBAL__N_116checkOpcodeThumbILNS1_16EdgeKind_aarch32E11EEEbtt",
    "bool llvm::jitlink::aarch32::(anonymous namespace)::checkOpcodeThumb<(llvm::jitlink::aarch32::EdgeKind_aarch32)11>(unsigned short, unsigned short)",
    "llvm::jitlink::aarch32::(anonymous namespace)::checkOpcodeThumb<(llvm::jitlink::aarch32::EdgeKind_aarch32)11>",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_7arm_sme22aarch64_sme_smopa_za32EE18getParseAssemblyFnEv",
    "mlir::RegisteredOperationName::Model<mlir::arm_sme::aarch64_sme_smopa_za32>::getParseAssemblyFn()",
    "mlir::RegisteredOperationName::Model<mlir::arm_sme::aarch64_sme_smopa_za32>::getParseAssemblyFn",
  ),
  (
    "_ZN17cranelift_codegen2ir7builder11InstBuilder9uload16x417h71c85661e3a07aa5E",
    "cranelift_codegen::ir::builder::InstBuilder::uload16x4::h71c85661e3a07aa5",
    "cranelift_codegen::ir::builder::InstBuilder::uload16x4::h71c85661e3a07aa5",
  ),
  (
    "_ZN42_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$3fmt17h152521b6a49aaee1E", "_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$::fmt::h152521b6a49aaee1",
    "_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$::fmt::h152521b6a49aaee1",
  ),
  (
    "_ZN4mlir7arm_sme30aarch64_sme_usmopa_wideAdaptorC2ENS0_23aarch64_sme_usmopa_wideE",
    "mlir::arm_sme::aarch64_sme_usmopa_wideAdaptor::aarch64_sme_usmopa_wideAdaptor(mlir::arm_sme::aarch64_sme_usmopa_wide)",
    "mlir::arm_sme::aarch64_sme_usmopa_wideAdaptor::aarch64_sme_usmopa_wideAdaptor",
  ),
  (
    "_ZN17cranelift_codegen3isa7aarch644inst4emit12enc_fputoint17h34d842441812b041E",
    "cranelift_codegen::isa::aarch64::inst::emit::enc_fputoint::h34d842441812b041",
    "cranelift_codegen::isa::aarch64::inst::emit::enc_fputoint::h34d842441812b041",
  ),
  (
    "_ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h46353c388a0aaccdE", "alloc::raw_vec::RawVec$LT$T$C$A$GT$::grow_one::h46353c388a0aaccd",
    "alloc::raw_vec::RawVec$LT$T$C$A$GT$::grow_one::h46353c388a0aaccd",
  ),
  (
    "_ZN4mlir7arm_sme22aarch64_sme_st1d_horiz6createERNS_20ImplicitLocOpBuilderENS_9TypeRangeENS_5ValueES5_jS5_",
    "mlir::arm_sme::aarch64_sme_st1d_horiz::create(mlir::ImplicitLocOpBuilder&, mlir::TypeRange, mlir::Value, mlir::Value, unsigned int, mlir::Value)",
    "mlir::arm_sme::aarch64_sme_st1d_horiz::create",
  ),
  (
    "_ZN4mlir7arm_sme29aarch64_sme_smops_za32AdaptorC1ENS0_22aarch64_sme_smops_za32E",
    "mlir::arm_sme::aarch64_sme_smops_za32Adaptor::aarch64_sme_smops_za32Adaptor(mlir::arm_sme::aarch64_sme_smops_za32)",
    "mlir::arm_sme::aarch64_sme_smops_za32Adaptor::aarch64_sme_smops_za32Adaptor",
  ),
  (
    "_ZN4mlir7arm_sme21aarch64_sme_ld1q_vert9getTileIdEv", "mlir::arm_sme::aarch64_sme_ld1q_vert::getTileId()",
    "mlir::arm_sme::aarch64_sme_ld1q_vert::getTileId",
  ),
  (
    "_ZN4mlir9transform13LoopOutlineOp6createERNS_9OpBuilderENS_8LocationENS_4TypeES5_NS_5ValueENS_10StringAttrE",
    "mlir::transform::LoopOutlineOp::create(mlir::OpBuilder&, mlir::Location, mlir::Type, mlir::Type, mlir::Value, mlir::StringAttr)",
    "mlir::transform::LoopOutlineOp::create",
  ),
  (
    "_ZN4mlir9transform19LoopUnrollOpAdaptorC2ENS0_12LoopUnrollOpE", "mlir::transform::LoopUnrollOpAdaptor::LoopUnrollOpAdaptor(mlir::transform::LoopUnrollOp)",
    "mlir::transform::LoopUnrollOpAdaptor::LoopUnrollOpAdaptor",
  ),
  (
    "_ZNK12_GLOBAL__N_120HexagonHardwareLoops16getAnalysisUsageERN4llvm13AnalysisUsageE",
    "(anonymous namespace)::HexagonHardwareLoops::getAnalysisUsage(llvm::AnalysisUsage&) const",
    "(anonymous namespace)::HexagonHardwareLoops::getAnalysisUsage",
  ),
  (
    "_ZNK4mlir4impl34ConvertLinalgToAffineLoopsPassBaseIN12_GLOBAL__N_118LowerToAffineLoopsEE7getNameEv",
    "mlir::impl::ConvertLinalgToAffineLoopsPassBase<(anonymous namespace)::LowerToAffineLoops>::getName() const",
    "mlir::impl::ConvertLinalgToAffineLoopsPassBase<(anonymous namespace)::LowerToAffineLoops>::getName",
  ),
  (
    "_ZN12_GLOBAL__N_120PPCLoopInstrFormPrep2IDE", "(anonymous namespace)::PPCLoopInstrFormPrep::ID",
    "(anonymous namespace)::PPCLoopInstrFormPrep::ID",
  ),
  (
    "_ZNK5clang16HLSLLoopHintAttr5cloneERNS_10ASTContextE", "clang::HLSLLoopHintAttr::clone(clang::ASTContext&) const",
    "clang::HLSLLoopHintAttr::clone",
  ),
  (
    "_ZN4llvm8LoopBaseIN4mlir5BlockENS1_7CFGLoopEE15removeChildLoopENSt3__111__wrap_iterIPKPS3_EE",
    "llvm::LoopBase<mlir::Block, mlir::CFGLoop>::removeChildLoop(std::__1::__wrap_iter<mlir::CFGLoop* const*>)",
    "llvm::LoopBase<mlir::Block, mlir::CFGLoop>::removeChildLoop",
  ),
  (
    "_ZN5polly25ParallelLoopGeneratorGOMP21createCallJoinThreadsEv", "polly::ParallelLoopGeneratorGOMP::createCallJoinThreads()",
    "polly::ParallelLoopGeneratorGOMP::createCallJoinThreads",
  ),
  (
    "_ZN4mlir9transform38ApplyForLoopCanonicalizationPatternsOp21computePropertiesHashERKNS_15EmptyPropertiesE",
    "mlir::transform::ApplyForLoopCanonicalizationPatternsOp::computePropertiesHash(mlir::EmptyProperties const&)",
    "mlir::transform::ApplyForLoopCanonicalizationPatternsOp::computePropertiesHash",
  ),
  (
    "_ZN4mlir9transform14LoopPipelineOp6createERNS_9OpBuilderENS_8LocationENS_9TypeRangeENS_5ValueEyy",
    "mlir::transform::LoopPipelineOp::create(mlir::OpBuilder&, mlir::Location, mlir::TypeRange, mlir::Value, unsigned long long, unsigned long long)",
    "mlir::transform::LoopPipelineOp::create",
  ),
  (
    "_ZNK4mlir4impl21SCFForToWhileLoopBaseIN12_GLOBAL__N_114ForToWhileLoopEE14getDescriptionEv",
    "mlir::impl::SCFForToWhileLoopBase<(anonymous namespace)::ForToWhileLoop>::getDescription() const",
    "mlir::impl::SCFForToWhileLoopBase<(anonymous namespace)::ForToWhileLoop>::getDescription",
  ),
  (
    "_ZNK4llvm12LoopInfoBaseINS_10BasicBlockENS_4LoopEE21getSmallestCommonLoopEPS2_S4_",
    "llvm::LoopInfoBase<llvm::BasicBlock, llvm::Loop>::getSmallestCommonLoop(llvm::Loop*, llvm::Loop*) const",
    "llvm::LoopInfoBase<llvm::BasicBlock, llvm::Loop>::getSmallestCommonLoop",
  ),
  (
    "_ZZN4llvm9Intrinsic27getIntrinsicForClangBuiltinENS_9StringRefES1_E8ppcNames",
    "llvm::Intrinsic::getIntrinsicForClangBuiltin(llvm::StringRef, llvm::StringRef)::ppcNames",
    "llvm::Intrinsic::getIntrinsicForClangBuiltin(llvm::StringRef, llvm::StringRef)::ppcNames",
  ),
  (
    "_ZThn104_NK11cmd_context2ppEP4exprR7obj_refI3app11ast_managerE", "non-virtual thunk to cmd_context::pp(expr*, obj_ref<app, ast_manager>&) const",
    "non-virtual thunk to cmd_context::pp(expr*, obj_ref<app, ast_manager>&) const",
  ),
  (
    "_ZN4LIEF11swap_endianINS_5MachO7details20ppc_thread_state64_tEEEvPT_", "void LIEF::swap_endian<LIEF::MachO::details::ppc_thread_state64_t>(LIEF::MachO::details::ppc_thread_state64_t*)",
    "LIEF::swap_endian<LIEF::MachO::details::ppc_thread_state64_t>",
  ),
  (
    "_ZN4llvm7jitlink5ppc6415PLTTableManagerILNS_10endiannessE1EE9visitEdgeERNS0_9LinkGraphEPNS0_5BlockERNS0_4EdgeE",
    "llvm::jitlink::ppc64::PLTTableManager<(llvm::endianness)1>::visitEdge(llvm::jitlink::LinkGraph&, llvm::jitlink::Block*, llvm::jitlink::Edge&)",
    "llvm::jitlink::ppc64::PLTTableManager<(llvm::endianness)1>::visitEdge",
  ),
  (
    "_ZN4llvm26ImutAVLTreeGenericIteratorINS_16ImutKeyValueInfoIPKN5clang4ento9MemRegionEPKNS3_7SymExprEEEEppEv",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutKeyValueInfo<clang::ento::MemRegion const*, clang::ento::SymExpr const*>>::operator++()",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutKeyValueInfo<clang::ento::MemRegion const*, clang::ento::SymExpr const*>>::operator++",
  ),
  (
    "_ZN4llvm26ImutAVLTreeGenericIteratorINS_16ImutKeyValueInfoIN5clang4ento16EnvironmentEntryENS3_4SValEEEEppEv",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutKeyValueInfo<clang::ento::EnvironmentEntry, clang::ento::SVal>>::operator++()",
    "llvm::ImutAVLTreeGenericIterator<llvm::ImutKeyValueInfo<clang::ento::EnvironmentEntry, clang::ento::SVal>>::operator++",
  ),
  (
    "_ZN4llvm7jitlink5ppc6418NullPointerContentE", "llvm::jitlink::ppc64::NullPointerContent",
    "llvm::jitlink::ppc64::NullPointerContent",
  ),
  (
    "_ZN5clang6driver5tools3ppc19getPPCAsmModeForCPUEN4llvm9StringRefE", "clang::driver::tools::ppc::getPPCAsmModeForCPU(llvm::StringRef)",
    "clang::driver::tools::ppc::getPPCAsmModeForCPU",
  ),
  (
    "_ZN4llvm19HexagonDAGToDAGISel13ppHoistZextI1EONSt3__16vectorIPNS_6SDNodeENS1_9allocatorIS4_EEEE",
    "llvm::HexagonDAGToDAGISel::ppHoistZextI1(std::__1::vector<llvm::SDNode*, std::__1::allocator<llvm::SDNode*>>&&)",
    "llvm::HexagonDAGToDAGISel::ppHoistZextI1",
  ),
  (
    "_ZN4llvm17fallible_iteratorINS_6object7Archive21ChildFallibleIteratorEEppEv",
    "llvm::fallible_iterator<llvm::object::Archive::ChildFallibleIterator>::operator++()",
    "llvm::fallible_iterator<llvm::object::Archive::ChildFallibleIterator>::operator++",
  ),
  (
    "_ZN4llvm7jitlink5ppc6415TOCTableManagerILNS_10endiannessE1EE11createEntryERNS0_9LinkGraphERNS0_6SymbolE",
    "llvm::jitlink::ppc64::TOCTableManager<(llvm::endianness)1>::createEntry(llvm::jitlink::LinkGraph&, llvm::jitlink::Symbol&)",
    "llvm::jitlink::ppc64::TOCTableManager<(llvm::endianness)1>::createEntry",
  ),
  (
    "_ZN4llvm7jitlink5ppc6429PointerJumpStubContent_littleE", "llvm::jitlink::ppc64::PointerJumpStubContent_little",
    "llvm::jitlink::ppc64::PointerJumpStubContent_little",
  ),
  (
    "_ZNK3jxl11N_NEON_BF1618WriteToOutputStage13WriteToOutputItEEvRKNS1_6OutputEmmmmPT_",
    "void jxl::N_NEON_BF16::WriteToOutputStage::WriteToOutput<unsigned short>(jxl::N_NEON_BF16::WriteToOutputStage::Output const&, unsigned long, unsigned long, unsigned long, unsigned long, unsigned short*) const",
    "jxl::N_NEON_BF16::WriteToOutputStage::WriteToOutput<unsigned short>",
  ),
  (
    "_ZN2v88internal40MutableBigInt_AbsoluteDivAndCanonicalizeEmmm", "v8::internal::MutableBigInt_AbsoluteDivAndCanonicalize(unsigned long, unsigned long, unsigned long)",
    "v8::internal::MutableBigInt_AbsoluteDivAndCanonicalize",
  ),
  (
    "_ZN3hwy8VQSelectEPNS_6K32V32EmmNS_14SortDescendingE", "hwy::VQSelect(hwy::K32V32*, unsigned long, unsigned long, hwy::SortDescending)",
    "hwy::VQSelect",
  ),
  (
    "_ZN2v84base30EmulatedVirtualAddressSubspace18SetPagePermissionsEmmNS_15PagePermissionsE",
    "v8::base::EmulatedVirtualAddressSubspace::SetPagePermissions(unsigned long, unsigned long, v8::PagePermissions)",
    "v8::base::EmulatedVirtualAddressSubspace::SetPagePermissions",
  ),
  (
    "_ZN2v88internal4Heap29AllocationTrackerForDebugging9MoveEventEmmi", "v8::internal::Heap::AllocationTrackerForDebugging::MoveEvent(unsigned long, unsigned long, int)",
    "v8::internal::Heap::AllocationTrackerForDebugging::MoveEvent",
  ),
  (
    "_ZN4absl18container_internal29TryFindNewIndexWithoutProbingIvEEmmmmPNS0_6ctrl_tEm",
    "unsigned long absl::container_internal::TryFindNewIndexWithoutProbing<void>(unsigned long, unsigned long, unsigned long, absl::container_internal::ctrl_t*, unsigned long)",
    "absl::container_internal::TryFindNewIndexWithoutProbing<void>",
  ),
  (
    "_ZN2v88internal12trap_handler19RegisterHandlerDataEmmmPKNS1_24ProtectedInstructionDataE",
    "v8::internal::trap_handler::RegisterHandlerData(unsigned long, unsigned long, unsigned long, v8::internal::trap_handler::ProtectedInstructionData const*)",
    "v8::internal::trap_handler::RegisterHandlerData",
  ),
  (
    "_ZN2v88internal6RegExp11AtomExecRawEPNS0_7IsolateEmmiPii", "v8::internal::RegExp::AtomExecRaw(v8::internal::Isolate*, unsigned long, unsigned long, int, int*, int)",
    "v8::internal::RegExp::AtomExecRaw",
  ),
  (
    "_ZN4LIEF5MachO8LinkEdit11update_dataERKNSt3__18functionIFvRNS2_6vectorIhNS2_9allocatorIhEEEEmmEEEmm",
    "LIEF::MachO::LinkEdit::update_data(std::__1::function<void (std::__1::vector<unsigned char, std::__1::allocator<unsigned char>>&, unsigned long, unsigned long)> const&, unsigned long, unsigned long)",
    "LIEF::MachO::LinkEdit::update_data",
  ),
  (
    "_ZN2v88internal11MemoryChunkC2ENS_4base5FlagsINS1_4FlagEmmEEPNS0_19MemoryChunkMetadataE",
    "v8::internal::MemoryChunk::MemoryChunk(v8::base::Flags<v8::internal::MemoryChunk::Flag, unsigned long, unsigned long>, v8::internal::MemoryChunkMetadata*)",
    "v8::internal::MemoryChunk::MemoryChunk",
  ),
  (
    "_ZN2v88internal21WritableJumpTablePairC1EmmmmNS1_13ForTestingTagE", "v8::internal::WritableJumpTablePair::WritableJumpTablePair(unsigned long, unsigned long, unsigned long, unsigned long, v8::internal::WritableJumpTablePair::ForTestingTag)",
    "v8::internal::WritableJumpTablePair::WritableJumpTablePair",
  ),
  (
    "_ZN3hwy13VQPartialSortEPNS_6K64V64EmmNS_13SortAscendingE", "hwy::VQPartialSort(hwy::K64V64*, unsigned long, unsigned long, hwy::SortAscending)",
    "hwy::VQPartialSort",
  ),
  (
    "_ZN12set_info_cmd7executeER11cmd_context", "set_info_cmd::execute(cmd_context&)",
    "set_info_cmd::execute",
  ),
  (
    "_ZN3jxl3cmsL26kNegOpsinAbsorbanceBiasRGBE", "jxl::cms::kNegOpsinAbsorbanceBiasRGB",
    "jxl::cms::kNegOpsinAbsorbanceBiasRGB",
  ),
  (
    "_ZN4llvm19raw_svector_ostream11pwrite_implEPKcmy", "llvm::raw_svector_ostream::pwrite_impl(char const*, unsigned long, unsigned long long)",
    "llvm::raw_svector_ostream::pwrite_impl",
  ),
  (
    "_ZNK11cmd_context6pp_env4usesERK6symbol", "cmd_context::pp_env::uses(symbol const&) const",
    "cmd_context::pp_env::uses",
  ),
  (
    "_ZZN4node6crypto7NodeBIO5WriteEPKcmE20error_and_abort_args_0", "node::crypto::NodeBIO::Write(char const*, unsigned long)::error_and_abort_args",
    "node::crypto::NodeBIO::Write(char const*, unsigned long)::error_and_abort_args",
  ),
  (
    "_ZNK2OT14EncodingRecord3cmpERKS0_", "OT::EncodingRecord::cmp(OT::EncodingRecord const&) const",
    "OT::EncodingRecord::cmp",
  ),
  (
    "_ZN2v88internal9Assembler4cmgeERKNS0_9VRegisterES4_i", "v8::internal::Assembler::cmge(v8::internal::VRegister const&, v8::internal::VRegister const&, int)",
    "v8::internal::Assembler::cmge",
  ),
  (
    "_ZNK14parametric_cmd13next_arg_kindER11cmd_context", "parametric_cmd::next_arg_kind(cmd_context&) const",
    "parametric_cmd::next_arg_kind",
  ),
  ("_ZL15cmpeqiBitOpcode", "cmpeqiBitOpcode", "cmpeqiBitOpcode"),
  (
    "_ZN15feature_event_t3cmpEPKvS1_", "feature_event_t::cmp(void const*, void const*)",
    "feature_event_t::cmp",
  ),
  (
    "_ZN11cmd_context6pp_env9get_futilEv", "cmd_context::pp_env::get_futil()", "cmd_context::pp_env::get_futil",
  ),
  (
    "_ZNK14parametric_cmd9get_descrER11cmd_context", "parametric_cmd::get_descr(cmd_context&) const",
    "parametric_cmd::get_descr",
  ),
  (
    "_ZN2v88internal9Assembler4pmulERKNS0_9VRegisterES4_S4_", "v8::internal::Assembler::pmul(v8::internal::VRegister const&, v8::internal::VRegister const&, v8::internal::VRegister const&)",
    "v8::internal::Assembler::pmul",
  ),
  (
    "_ZN2v88internal9Assembler6pmull2ERKNS0_9VRegisterES4_S4_", "v8::internal::Assembler::pmull2(v8::internal::VRegister const&, v8::internal::VRegister const&, v8::internal::VRegister const&)",
    "v8::internal::Assembler::pmull2",
  ),
  (
    "_ZN2v88internal9Assembler5pmullERKNS0_9VRegisterES4_S4_", "v8::internal::Assembler::pmull(v8::internal::VRegister const&, v8::internal::VRegister const&, v8::internal::VRegister const&)",
    "v8::internal::Assembler::pmull",
  ),
  (
    "_ZN4core3ptr73drop_in_place$LT$alloc..boxed..Box$LT$regex_syntax..ast..ClassSet$GT$$GT$17hab7081656c1d938aE",
    "core::ptr::drop_in_place$LT$alloc..boxed..Box$LT$regex_syntax..ast..ClassSet$GT$$GT$::hab7081656c1d938a",
    "core::ptr::drop_in_place$LT$alloc..boxed..Box$LT$regex_syntax..ast..ClassSet$GT$$GT$::hab7081656c1d938a",
  ),
  (
    "_ZN14core_hashtableI14obj_hash_entryI9func_declE12obj_ptr_hashIS1_E6ptr_eqIS1_EE5resetEv",
    "core_hashtable<obj_hash_entry<func_decl>, obj_ptr_hash<func_decl>, ptr_eq<func_decl>>::reset()",
    "core_hashtable<obj_hash_entry<func_decl>, obj_ptr_hash<func_decl>, ptr_eq<func_decl>>::reset",
  ),
  (
    "_ZNK4llvm17DbgRecordParamRefINS_12DIExpressionEEptEv", "llvm::DbgRecordParamRef<llvm::DIExpression>::operator->() const",
    "llvm::DbgRecordParamRef<llvm::DIExpression>::operator->",
  ),
  (
    "_ZN4core3ptr66drop_in_place$LT$alloc..vec..Vec$LT$rsvg..css..Declaration$GT$$GT$17h1abafe2dd528ca18E",
    "core::ptr::drop_in_place$LT$alloc..vec..Vec$LT$rsvg..css..Declaration$GT$$GT$::h1abafe2dd528ca18",
    "core::ptr::drop_in_place$LT$alloc..vec..Vec$LT$rsvg..css..Declaration$GT$$GT$::h1abafe2dd528ca18",
  ),
  (
    "_ZN4core3ptr55drop_in_place$LT$aho_corasick..nfa..contiguous..NFA$GT$17h03ff6baabcb22482E",
    "core::ptr::drop_in_place$LT$aho_corasick..nfa..contiguous..NFA$GT$::h03ff6baabcb22482",
    "core::ptr::drop_in_place$LT$aho_corasick..nfa..contiguous..NFA$GT$::h03ff6baabcb22482",
  ),
  (
    "_ZN4core3ptr50drop_in_place$LT$rustls..client..ech..EchState$GT$17h77993ed0fde99d71E",
    "core::ptr::drop_in_place$LT$rustls..client..ech..EchState$GT$::h77993ed0fde99d71",
    "core::ptr::drop_in_place$LT$rustls..client..ech..EchState$GT$::h77993ed0fde99d71",
  ),
  (
    "_ZN4core3ptr42drop_in_place$LT$alloc..string..String$GT$17h26f50641d11388c5E",
    "core::ptr::drop_in_place$LT$alloc..string..String$GT$::h26f50641d11388c5", "core::ptr::drop_in_place$LT$alloc..string..String$GT$::h26f50641d11388c5",
  ),
  (
    "_ZZN3sat10aig_finder8find_ifsER10ptr_vectorINS_6clauseEEENK3$_2clENS_7literalES6_S6_RPS2_",
    "sat::aig_finder::find_ifs(ptr_vector<sat::clause>&)::$_2::operator()(sat::literal, sat::literal, sat::literal, sat::clause*&) const",
    "sat::aig_finder::find_ifs(ptr_vector<sat::clause>&)::$_2::operator()",
  ),
  (
    "_ZN4mlir3ptr6detail25ToPtrOpGenericAdaptorBaseC2ENS0_7ToPtrOpE", "mlir::ptr::detail::ToPtrOpGenericAdaptorBase::ToPtrOpGenericAdaptorBase(mlir::ptr::ToPtrOp)",
    "mlir::ptr::detail::ToPtrOpGenericAdaptorBase::ToPtrOpGenericAdaptorBase",
  ),
  (
    "_ZN4mlir3ptr16FromPtrOpAdaptorC1ENS0_9FromPtrOpE", "mlir::ptr::FromPtrOpAdaptor::FromPtrOpAdaptor(mlir::ptr::FromPtrOp)",
    "mlir::ptr::FromPtrOpAdaptor::FromPtrOpAdaptor",
  ),
  (
    "_ZTIN4mlir23RegisteredOperationName5ModelINS_3ptr7StoreOpEEE", "typeinfo for mlir::RegisteredOperationName::Model<mlir::ptr::StoreOp>",
    "typeinfo for mlir::RegisteredOperationName::Model<mlir::ptr::StoreOp>",
  ),
  (
    "_Z12dealloc_vectIN7obj_mapI9func_decl10ptr_vectorI3appEE13obj_map_entryEEvPT_j",
    "void dealloc_vect<obj_map<func_decl, ptr_vector<app>>::obj_map_entry>(obj_map<func_decl, ptr_vector<app>>::obj_map_entry*, unsigned int)",
    "dealloc_vect<obj_map<func_decl, ptr_vector<app>>::obj_map_entry>",
  ),
  (
    "_ZN5clang13TreeTransformIN12_GLOBAL__N_117AdjustConstraintsEE19TransformGCCAsmStmtEPNS_10GCCAsmStmtE",
    "clang::TreeTransform<(anonymous namespace)::AdjustConstraints>::TransformGCCAsmStmt(clang::GCCAsmStmt*)",
    "clang::TreeTransform<(anonymous namespace)::AdjustConstraints>::TransformGCCAsmStmt",
  ),
  (
    "_ZN5clang12ast_matchers18isVirtualAsWrittenEv", "clang::ast_matchers::isVirtualAsWritten()",
    "clang::ast_matchers::isVirtualAsWritten",
  ),
  (
    "_ZN5clang6driver5tools9baremetal13StaticLibToolD0Ev", "clang::driver::tools::baremetal::StaticLibTool::~StaticLibTool()",
    "clang::driver::tools::baremetal::StaticLibTool::~StaticLibTool",
  ),
  (
    "_ZNK4llvm2cl3optINS_11SplitEditor19ComplementSpillModeELb0ENS0_6parserIS3_EEE15printOptionInfoEm",
    "llvm::cl::opt<llvm::SplitEditor::ComplementSpillMode, false, llvm::cl::parser<llvm::SplitEditor::ComplementSpillMode>>::printOptionInfo(unsigned long) const",
    "llvm::cl::opt<llvm::SplitEditor::ComplementSpillMode, false, llvm::cl::parser<llvm::SplitEditor::ComplementSpillMode>>::printOptionInfo",
  ),
  (
    "_ZN5clang30DynamicRecursiveASTVisitorBaseILb1EE19VisitPointerTypeLocENS_14PointerTypeLocE",
    "clang::DynamicRecursiveASTVisitorBase<true>::VisitPointerTypeLoc(clang::PointerTypeLoc)",
    "clang::DynamicRecursiveASTVisitorBase<true>::VisitPointerTypeLoc",
  ),
  (
    "_ZN5clang9Ptr64Attr6CreateERNS_10ASTContextERKNS_19AttributeCommonInfoE", "clang::Ptr64Attr::Create(clang::ASTContext&, clang::AttributeCommonInfo const&)",
    "clang::Ptr64Attr::Create",
  ),
  (
    "_ZN12_GLOBAL__N_117ExprEvaluatorBaseINS_19AtomicExprEvaluatorEE13VisitCallExprEPKN5clang8CallExprE",
    "(anonymous namespace)::ExprEvaluatorBase<(anonymous namespace)::AtomicExprEvaluator>::VisitCallExpr(clang::CallExpr const*)",
    "(anonymous namespace)::ExprEvaluatorBase<(anonymous namespace)::AtomicExprEvaluator>::VisitCallExpr",
  ),
  (
    "_ZTIN5clang11ASTImporterE", "typeinfo for clang::ASTImporter", "typeinfo for clang::ASTImporter",
  ),
  (
    "_ZN5clang15ASTRecordReader20readHLSLSpirvOperandEv", "clang::ASTRecordReader::readHLSLSpirvOperand()",
    "clang::ASTRecordReader::readHLSLSpirvOperand",
  ),
  (
    "_ZTSN5clang12ast_matchers8internal16MatcherInterfaceINS_9WhileStmtEEE", "typeinfo name for clang::ast_matchers::internal::MatcherInterface<clang::WhileStmt>",
    "typeinfo name for clang::ast_matchers::internal::MatcherInterface<clang::WhileStmt>",
  ),
  (
    "_ZN5clang26PragmaClangDataSectionAttrC2ERNS_10ASTContextERKNS_19AttributeCommonInfoEN4llvm9StringRefE",
    "clang::PragmaClangDataSectionAttr::PragmaClangDataSectionAttr(clang::ASTContext&, clang::AttributeCommonInfo const&, llvm::StringRef)",
    "clang::PragmaClangDataSectionAttr::PragmaClangDataSectionAttr",
  ),
  (
    "_ZNK5clang7CodeGen14CGRecordLayout14getLLVMFieldNoEPKNS_9FieldDeclE", "clang::CodeGen::CGRecordLayout::getLLVMFieldNo(clang::FieldDecl const*) const",
    "clang::CodeGen::CGRecordLayout::getLLVMFieldNo",
  ),
  (
    "_ZN4llvm3orc14ELFNixPlatform20ELFNixPlatformPlugin12notifyFailedERNS0_29MaterializationResponsibilityE",
    "llvm::orc::ELFNixPlatform::ELFNixPlatformPlugin::notifyFailed(llvm::orc::MaterializationResponsibility&)",
    "llvm::orc::ELFNixPlatform::ELFNixPlatformPlugin::notifyFailed",
  ),
  (
    "_ZZN4node16MaybeStackBufferIDsLm1024EEixEmE20error_and_abort_args", "node::MaybeStackBuffer<char16_t, 1024ul>::operator[](unsigned long)::error_and_abort_args",
    "node::MaybeStackBuffer<char16_t, 1024ul>::operator[](unsigned long)::error_and_abort_args",
  ),
  (
    "_ZZN4node16MaybeStackBufferIjLm64EEixEmE20error_and_abort_args", "node::MaybeStackBuffer<unsigned int, 64ul>::operator[](unsigned long)::error_and_abort_args",
    "node::MaybeStackBuffer<unsigned int, 64ul>::operator[](unsigned long)::error_and_abort_args",
  ),
  (
    "_ZNK4mlir6detail18DenseArrayAttrImplIdEixEm", "mlir::detail::DenseArrayAttrImpl<double>::operator[](unsigned long) const",
    "mlir::detail::DenseArrayAttrImpl<double>::operator[]",
  ),
  (
    "_ZN2v88internal8compiler10turboshaft6detail16GrowingSidetableIiNS2_10BlockIndexEEixES5_.cold.1",
    "v8::internal::compiler::turboshaft::detail::GrowingSidetable<int, v8::internal::compiler::turboshaft::BlockIndex>::operator[](v8::internal::compiler::turboshaft::BlockIndex) (.cold.1)",
    "v8::internal::compiler::turboshaft::detail::GrowingSidetable<int, v8::internal::compiler::turboshaft::BlockIndex>::operator[]",
  ),
  (
    "_ZN12_GLOBAL__N_150ELFNixPlatformCompleteBootstrapMaterializationUnitD1Ev",
    "(anonymous namespace)::ELFNixPlatformCompleteBootstrapMaterializationUnit::~ELFNixPlatformCompleteBootstrapMaterializationUnit()",
    "(anonymous namespace)::ELFNixPlatformCompleteBootstrapMaterializationUnit::~ELFNixPlatformCompleteBootstrapMaterializationUnit",
  ),
  (
    "_ZN4llvm8ValueMapIPNS_5ValueES2_NS_14ValueMapConfigIS2_NS_3sys10SmartMutexILb0EEEEEEixERKS2_",
    "llvm::ValueMap<llvm::Value*, llvm::Value*, llvm::ValueMapConfig<llvm::Value*, llvm::sys::SmartMutex<false>>>::operator[](llvm::Value* const&)",
    "llvm::ValueMap<llvm::Value*, llvm::Value*, llvm::ValueMapConfig<llvm::Value*, llvm::sys::SmartMutex<false>>>::operator[]",
  ),
  (
    "_ZN4llvm3orc14ELFNixPlatform18requiredCXXAliasesEv", "llvm::orc::ELFNixPlatform::requiredCXXAliases()",
    "llvm::orc::ELFNixPlatform::requiredCXXAliases",
  ),
  (
    "_ZNK4llvm16FixedStreamArrayINS_8codeview15TypeIndexOffsetEEixEj", "llvm::FixedStreamArray<llvm::codeview::TypeIndexOffset>::operator[](unsigned int) const",
    "llvm::FixedStreamArray<llvm::codeview::TypeIndexOffset>::operator[]",
  ),
  (
    "_ZN4llvm3orc14ELFNixPlatform23standardPlatformAliasesERNS0_16ExecutionSessionERNS0_8JITDylibE",
    "llvm::orc::ELFNixPlatform::standardPlatformAliases(llvm::orc::ExecutionSession&, llvm::orc::JITDylib&)",
    "llvm::orc::ELFNixPlatform::standardPlatformAliases",
  ),
  (
    "_ZNK4mlir6detail18DenseArrayAttrImplIbEixEm", "mlir::detail::DenseArrayAttrImpl<bool>::operator[](unsigned long) const",
    "mlir::detail::DenseArrayAttrImpl<bool>::operator[]",
  ),
  (
    "_ZNK4llvm17DominatorTreeBaseINS_17MachineBasicBlockELb1EEixEPKS1_", "llvm::DominatorTreeBase<llvm::MachineBasicBlock, true>::operator[](llvm::MachineBasicBlock const*) const",
    "llvm::DominatorTreeBase<llvm::MachineBasicBlock, true>::operator[]",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4tosa7EqualOpEE14copyPropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::tosa::EqualOp>::copyProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::tosa::EqualOp>::copyProperties",
  ),
  (
    "_ZN1q19quantifier_stat_genclEP10quantifierj", "q::quantifier_stat_gen::operator()(quantifier*, unsigned int)",
    "q::quantifier_stat_gen::operator()",
  ),
  (
    "_ZTSN4mlir5spirv6detail30QueryCapabilityInterfaceTraits5ModelINS0_11INotEqualOpEEE",
    "typeinfo name for mlir::spirv::detail::QueryCapabilityInterfaceTraits::Model<mlir::spirv::INotEqualOp>",
    "typeinfo name for mlir::spirv::detail::QueryCapabilityInterfaceTraits::Model<mlir::spirv::INotEqualOp>",
  ),
  (
    "_ZN5clang28StructuralEquivalenceContext12IsEquivalentEPNS_4StmtES2_", "clang::StructuralEquivalenceContext::IsEquivalent(clang::Stmt*, clang::Stmt*)",
    "clang::StructuralEquivalenceContext::IsEquivalent",
  ),
  (
    "_ZN15ref_vector_coreI10quantifier19ref_manager_wrapperIS0_11ast_managerEED2Ev",
    "ref_vector_core<quantifier, ref_manager_wrapper<quantifier, ast_manager>>::~ref_vector_core()",
    "ref_vector_core<quantifier, ref_manager_wrapper<quantifier, ast_manager>>::~ref_vector_core",
  ),
  (
    "_ZTIN4mlir5spirv6detail30QueryCapabilityInterfaceTraits5ModelINS0_19FOrdLessThanEqualOpEEE",
    "typeinfo for mlir::spirv::detail::QueryCapabilityInterfaceTraits::Model<mlir::spirv::FOrdLessThanEqualOp>",
    "typeinfo for mlir::spirv::detail::QueryCapabilityInterfaceTraits::Model<mlir::spirv::FOrdLessThanEqualOp>",
  ),
  (
    "_ZN4mlir5query7matcher8internal6Parser4Sema21getMatcherCompletionsEN4llvm8ArrayRefINS1_7ArgKindEEE",
    "mlir::query::matcher::internal::Parser::Sema::getMatcherCompletions(llvm::ArrayRef<mlir::query::matcher::ArgKind>)",
    "mlir::query::matcher::internal::Parser::Sema::getMatcherCompletions",
  ),
  (
    "_ZN2v88internal8compiler13CodeAssembler25Float64GreaterThanOrEqualENS0_5TNodeINS0_8Float64TEEES5_",
    "v8::internal::compiler::CodeAssembler::Float64GreaterThanOrEqual(v8::internal::TNode<v8::internal::Float64T>, v8::internal::TNode<v8::internal::Float64T>)",
    "v8::internal::compiler::CodeAssembler::Float64GreaterThanOrEqual",
  ),
  (
    "_ZN4mlir5spirv12Deserializer9processOpINS0_16ULessThanEqualOpEEEN4llvm13LogicalResultENS4_8ArrayRefIjEE",
    "llvm::LogicalResult mlir::spirv::Deserializer::processOp<mlir::spirv::ULessThanEqualOp>(llvm::ArrayRef<unsigned int>)",
    "mlir::spirv::Deserializer::processOp<mlir::spirv::ULessThanEqualOp>",
  ),
  (
    "_ZTVN2qe17quant_elim_pluginE", "vtable for qe::quant_elim_plugin", "vtable for qe::quant_elim_plugin",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5spirv13FUnordEqualOpEE14hashPropertiesENS_16OpaquePropertiesE",
    "mlir::RegisteredOperationName::Model<mlir::spirv::FUnordEqualOp>::hashProperties(mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::spirv::FUnordEqualOp>::hashProperties",
  ),
  ("_ZN1q5queueD2Ev", "q::queue::~queue()", "q::queue::~queue"),
  (
    "_ZNK5clang6interp10IntegralAPILb0EEcvT_ItvEEv", "clang::interp::IntegralAP<false>::operator unsigned short<unsigned short, void>() const",
    "clang::interp::IntegralAP<false>::operator unsigned short<unsigned short, void>",
  ),
  (
    "_ZN4mlir9AsmParser13KeywordSwitchINS_19OptionalParseResultEEcvS2_Ev", "mlir::AsmParser::KeywordSwitch<mlir::OptionalParseResult>::operator mlir::OptionalParseResult()",
    "mlir::AsmParser::KeywordSwitch<mlir::OptionalParseResult>::operator mlir::OptionalParseResult",
  ),
  (
    "_ZNK4mlir6detail18DenseArrayAttrImplIbEcvN4llvm8ArrayRefIbEEEv", "mlir::detail::DenseArrayAttrImpl<bool>::operator llvm::ArrayRef<bool>() const",
    "mlir::detail::DenseArrayAttrImpl<bool>::operator llvm::ArrayRef<bool>",
  ),
  (
    "_ZNK4mlir6detail18DenseArrayAttrImplIdEcvN4llvm8ArrayRefIdEEEv", "mlir::detail::DenseArrayAttrImpl<double>::operator llvm::ArrayRef<double>() const",
    "mlir::detail::DenseArrayAttrImpl<double>::operator llvm::ArrayRef<double>",
  ),
  (
    "_ZN12FoFiTrueType11cvtEncodingEPPcPFvPvPKcmES2_", "FoFiTrueType::cvtEncoding(char**, void (*)(void*, char const*, unsigned long), void*)",
    "FoFiTrueType::cvtEncoding",
  ),
  (
    "_ZNK2OT4cvar6subsetEP19hb_subset_context_t", "OT::cvar::subset(hb_subset_context_t*) const",
    "OT::cvar::subset",
  ),
  (
    "_ZNK5clang6interp10IntegralAPILb0EEcvT_IavEEv", "clang::interp::IntegralAP<false>::operator signed char<signed char, void>() const",
    "clang::interp::IntegralAP<false>::operator signed char<signed char, void>",
  ),
  (
    "_ZN21hb_sanitize_context_t13sanitize_blobIKN2OT4cvarEEEP9hb_blob_tS5_", "hb_blob_t* hb_sanitize_context_t::sanitize_blob<OT::cvar const>(hb_blob_t*)",
    "hb_sanitize_context_t::sanitize_blob<OT::cvar const>",
  ),
  (
    "_ZNK4mlir6detail18DenseArrayAttrImplIxEcvN4llvm8ArrayRefIxEEEv", "mlir::detail::DenseArrayAttrImpl<long long>::operator llvm::ArrayRef<long long>() const",
    "mlir::detail::DenseArrayAttrImpl<long long>::operator llvm::ArrayRef<long long>",
  ),
  (
    "_ZNK5clang6interp10IntegralAPILb0EEcvT_IsvEEv", "clang::interp::IntegralAP<false>::operator short<short, void>() const",
    "clang::interp::IntegralAP<false>::operator short<short, void>",
  ),
  (
    "_ZNK4llvm17DbgRecordParamRefINS_15DILocalVariableEEcvbEv", "llvm::DbgRecordParamRef<llvm::DILocalVariable>::operator bool() const",
    "llvm::DbgRecordParamRef<llvm::DILocalVariable>::operator bool",
  ),
  (
    "_ZN4llvm15SmallVectorImplIcE6insertIPKcvEEPcS5_T_S6_", "char* llvm::SmallVectorImpl<char>::insert<char const*, void>(char*, char const*, char const*)",
    "llvm::SmallVectorImpl<char>::insert<char const*, void>",
  ),
  (
    "_ZN4llvm2cl4listINSt3__112basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbNS0_6parserIS8_EEED0Ev",
    "llvm::cl::list<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>, bool, llvm::cl::parser<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>>>::~list()",
    "llvm::cl::list<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>, bool, llvm::cl::parser<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>>>::~list",
  ),
  (
    "_ZN4mlir6linalg12_GLOBAL__N_19G_4x4_3x3E", "mlir::linalg::(anonymous namespace)::G_4x4_3x3",
    "mlir::linalg::(anonymous namespace)::G_4x4_3x3",
  ),
  (
    "_ZN4mlir6linalg23PoolingNhwcMinOpAdaptor6verifyENS_8LocationE", "mlir::linalg::PoolingNhwcMinOpAdaptor::verify(mlir::Location)",
    "mlir::linalg::PoolingNhwcMinOpAdaptor::verify",
  ),
  (
    "_ZN12_GLOBAL__N_121RankReduceToUnBatchedIN4mlir6linalg13BatchMatmulOpENS2_8MatmulOpEED1Ev",
    "(anonymous namespace)::RankReduceToUnBatched<mlir::linalg::BatchMatmulOp, mlir::linalg::MatmulOp>::~RankReduceToUnBatched()",
    "(anonymous namespace)::RankReduceToUnBatched<mlir::linalg::BatchMatmulOp, mlir::linalg::MatmulOp>::~RankReduceToUnBatched",
  ),
  (
    "_ZN4mlir6linalg17PoolingNdhwcSumOp22hasDynamicIndexingMapsEv", "mlir::linalg::PoolingNdhwcSumOp::hasDynamicIndexingMaps()",
    "mlir::linalg::PoolingNdhwcSumOp::hasDynamicIndexingMaps",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_6linalg24DepthwiseConv2DNchwChwOpEE21getOpPropertyByteSizeEv",
    "mlir::RegisteredOperationName::Model<mlir::linalg::DepthwiseConv2DNchwChwOp>::getOpPropertyByteSize()",
    "mlir::RegisteredOperationName::Model<mlir::linalg::DepthwiseConv2DNchwChwOp>::getOpPropertyByteSize",
  ),
  (
    "_ZTVN4mlir23RegisteredOperationName5ModelINS_6linalg5AddOpEEE", "vtable for mlir::RegisteredOperationName::Model<mlir::linalg::AddOp>",
    "vtable for mlir::RegisteredOperationName::Model<mlir::linalg::AddOp>",
  ),
  (
    "_ZN4mlir6linalg6detail13LinalgOpTraitINS0_11FillRng2DOpEE8getShapeEPNS_9OpOperandE",
    "mlir::linalg::detail::LinalgOpTrait<mlir::linalg::FillRng2DOp>::getShape(mlir::OpOperand*)",
    "mlir::linalg::detail::LinalgOpTrait<mlir::linalg::FillRng2DOp>::getShape",
  ),
  (
    "_ZTIN4mlir23RegisteredOperationName5ModelINS_6linalg11FillRng2DOpEEE", "typeinfo for mlir::RegisteredOperationName::Model<mlir::linalg::FillRng2DOp>",
    "typeinfo for mlir::RegisteredOperationName::Model<mlir::linalg::FillRng2DOp>",
  ),
  (
    "_ZN4mlir6linalg6detail37Conv2DNhwgcGfhwcQOpGenericAdaptorBase16getDilationsAttrEv",
    "mlir::linalg::detail::Conv2DNhwgcGfhwcQOpGenericAdaptorBase::getDilationsAttr()",
    "mlir::linalg::detail::Conv2DNhwgcGfhwcQOpGenericAdaptorBase::getDilationsAttr",
  ),
  (
    "_ZN3smt23theory_dense_diff_logicINS_5i_extEE15get_antecedentsEiiR7svectorIN3sat7literalEjE",
    "smt::theory_dense_diff_logic<smt::i_ext>::get_antecedents(int, int, svector<sat::literal, unsigned int>&)",
    "smt::theory_dense_diff_logic<smt::i_ext>::get_antecedents",
  ),
  (
    "_ZNK4llvm2cl4listIN4mlir13OpPassManagerEbNS0_6parserIS3_EEE16printOptionValueEmb",
    "llvm::cl::list<mlir::OpPassManager, bool, llvm::cl::parser<mlir::OpPassManager>>::printOptionValue(unsigned long, bool) const",
    "llvm::cl::list<mlir::OpPassManager, bool, llvm::cl::parser<mlir::OpPassManager>>::printOptionValue",
  ),
  ("_ZN3jxlL8kGxyzTagE", "jxl::kGxyzTag", "jxl::kGxyzTag"),
  (
    "_ZN4llvm13StdThreadPool12processTasksEPNS_19ThreadPoolTaskGroupE", "llvm::StdThreadPool::processTasks(llvm::ThreadPoolTaskGroup*)",
    "llvm::StdThreadPool::processTasks",
  ),
  (
    "_ZN4llvm6object12SFrameParserILNS_10endiannessE1EE6createENS_8ArrayRefIhEEy",
    "llvm::object::SFrameParser<(llvm::endianness)1>::create(llvm::ArrayRef<unsigned char>, unsigned long long)",
    "llvm::object::SFrameParser<(llvm::endianness)1>::create",
  ),
  ("_ZL18CPPairDecoderTable", "CPPairDecoderTable", "CPPairDecoderTable"),
  (
    "_ZN4llvm15InstrProfSymtab6createERNS_6ModuleEbb", "llvm::InstrProfSymtab::create(llvm::Module&, bool, bool)",
    "llvm::InstrProfSymtab::create",
  ),
  (
    "_ZN9hashbrown3map28HashMap$LT$K$C$V$C$S$C$A$GT$6insert17h34852d0b940e3608E",
    "hashbrown::map::HashMap$LT$K$C$V$C$S$C$A$GT$::insert::h34852d0b940e3608", "hashbrown::map::HashMap$LT$K$C$V$C$S$C$A$GT$::insert::h34852d0b940e3608",
  ),
  (
    "_ZN7Imf_3_412ImageChannelD0Ev", "Imf_3_4::ImageChannel::~ImageChannel()", "Imf_3_4::ImageChannel::~ImageChannel",
  ),
  ("_ZL18ExportSymFlagNames", "ExportSymFlagNames", "ExportSymFlagNames"),
  (
    "_ZN15FontInfoScannerD2Ev", "FontInfoScanner::~FontInfoScanner()", "FontInfoScanner::~FontInfoScanner",
  ),
  (
    "_ZTIN4llvm16PPCFrameLoweringE", "typeinfo for llvm::PPCFrameLowering", "typeinfo for llvm::PPCFrameLowering",
  ),
  (
    "_ZN3smt12model_finder10checkpointEPKc", "smt::model_finder::checkpoint(char const*)",
    "smt::model_finder::checkpoint",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_110PNR_3bBitsE", "llvm::(anonymous namespace)::PNR_3bBits",
    "llvm::(anonymous namespace)::PNR_3bBits",
  ),
  (
    "_ZN12_GLOBAL__N_114RISCVAsmParser22parseExprWithSpecifierERPKN4llvm6MCExprERNS1_5SMLocE",
    "(anonymous namespace)::RISCVAsmParser::parseExprWithSpecifier(llvm::MCExpr const*&, llvm::SMLoc&)",
    "(anonymous namespace)::RISCVAsmParser::parseExprWithSpecifier",
  ),
  (
    "_ZTINSt3__110__function6__funcIZ17mk_default_tacticR11ast_managerRK10params_refE3$_2FP6tacticS3_S6_EEE",
    "typeinfo for std::__1::__function::__func<mk_default_tactic(ast_manager&, params_ref const&)::$_2, tactic* (ast_manager&, params_ref const&)>",
    "typeinfo for std::__1::__function::__func<mk_default_tactic(ast_manager&, params_ref const&)::$_2, tactic* (ast_manager&, params_ref const&)>",
  ),
  (
    "_ZN7Iex_3_49EisnamExcC2EOS0_", "Iex_3_4::EisnamExc::EisnamExc(Iex_3_4::EisnamExc&&)",
    "Iex_3_4::EisnamExc::EisnamExc",
  ),
  (
    "_Z17_As_TrustedObjectm", "_As_TrustedObject(unsigned long)", "_As_TrustedObject",
  ),
  (
    "_ZTVN12_GLOBAL__N_112_GLOBAL__N_129PackedStochRoundFp8OpLoweringE", "vtable for (anonymous namespace)::(anonymous namespace)::PackedStochRoundFp8OpLowering",
    "vtable for (anonymous namespace)::(anonymous namespace)::PackedStochRoundFp8OpLowering",
  ),
  (
    "_ZTI12rewriter_tplIN14macro_replacer18macro_replacer_cfgEE", "typeinfo for rewriter_tpl<macro_replacer::macro_replacer_cfg>",
    "typeinfo for rewriter_tpl<macro_replacer::macro_replacer_cfg>",
  ),
  (
    "_ZN12_GLOBAL__N_126ParsedAttrInfoBuiltinAlias8InstanceE", "(anonymous namespace)::ParsedAttrInfoBuiltinAlias::Instance",
    "(anonymous namespace)::ParsedAttrInfoBuiltinAlias::Instance",
  ),
  (
    "_ZN12_GLOBAL__N_115RankOpConverterD0Ev", "(anonymous namespace)::RankOpConverter::~RankOpConverter()",
    "(anonymous namespace)::RankOpConverter::~RankOpConverter",
  ),
  (
    "_ZTSN4llvm13AAPointerInfoE", "typeinfo name for llvm::AAPointerInfo", "typeinfo name for llvm::AAPointerInfo",
  ),
  (
    "_ZN7specrel6solver6mk_varEPN3euf5enodeE", "specrel::solver::mk_var(euf::enode*)",
    "specrel::solver::mk_var",
  ),
  (
    "_ZN4llvm16StaticLikelyProbE", "llvm::StaticLikelyProb", "llvm::StaticLikelyProb",
  ),
  (
    "_ZTVN4llvm11logicalview7LVRangeE", "vtable for llvm::logicalview::LVRange",
    "vtable for llvm::logicalview::LVRange",
  ),
  (
    "_ZN4node2fsL5FStatERKN2v820FunctionCallbackInfoINS1_5ValueEEE", "node::fs::FStat(v8::FunctionCallbackInfo<v8::Value> const&)",
    "node::fs::FStat",
  ),
  (
    "_ZN12_GLOBAL__N_122AffinePrefetchLoweringD0Ev", "(anonymous namespace)::AffinePrefetchLowering::~AffinePrefetchLowering()",
    "(anonymous namespace)::AffinePrefetchLowering::~AffinePrefetchLowering",
  ),
  (
    "_ZN4llvm13ConstantRangeC1ENS_5APIntE", "llvm::ConstantRange::ConstantRange(llvm::APInt)",
    "llvm::ConstantRange::ConstantRange",
  ),
  (
    "_ZL17hb_cairo_pop_clipP16hb_paint_funcs_tPvS1_", "hb_cairo_pop_clip(hb_paint_funcs_t*, void*, void*)",
    "hb_cairo_pop_clip",
  ),
  (
    "_ZTIN12_GLOBAL__N_125TargetDataLayoutInterfaceE", "typeinfo for (anonymous namespace)::TargetDataLayoutInterface",
    "typeinfo for (anonymous namespace)::TargetDataLayoutInterface",
  ),
  (
    "_ZN2v88internal9Assembler5usublERKNS0_9VRegisterES4_S4_", "v8::internal::Assembler::usubl(v8::internal::VRegister const&, v8::internal::VRegister const&, v8::internal::VRegister const&)",
    "v8::internal::Assembler::usubl",
  ),
  (
    "_ZNK4node9inspector8protocol5Value8asStringEPNSt3__112basic_stringIcNS3_11char_traitsIcEENS3_9allocatorIcEEEE",
    "node::inspector::protocol::Value::asString(std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>*) const",
    "node::inspector::protocol::Value::asString",
  ),
  (
    "_ZTIN12_GLOBAL__N_119AtomicRMWOpLoweringE", "typeinfo for (anonymous namespace)::AtomicRMWOpLowering",
    "typeinfo for (anonymous namespace)::AtomicRMWOpLowering",
  ),
  ("_ZN4absl5MutexD2Ev", "absl::Mutex::~Mutex()", "absl::Mutex::~Mutex"),
  (
    "_ZN7nlarith4util3imp5mk_neEP4expr", "nlarith::util::imp::mk_ne(expr*)", "nlarith::util::imp::mk_ne",
  ),
  (
    "_ZNK2v88internal23RegExpBytecodeGenerator16CanReadUnalignedEv", "v8::internal::RegExpBytecodeGenerator::CanReadUnaligned() const",
    "v8::internal::RegExpBytecodeGenerator::CanReadUnaligned",
  ),
  (
    "_ZN12_GLOBAL__N_121ParsedAttrInfoSection8InstanceE", "(anonymous namespace)::ParsedAttrInfoSection::Instance",
    "(anonymous namespace)::ParsedAttrInfoSection::Instance",
  ),
  (
    "_ZN2v88internal6maglev28BranchIfFloat64ToBooleanTrue27SetValueLocationConstraintsEv",
    "v8::internal::maglev::BranchIfFloat64ToBooleanTrue::SetValueLocationConstraints()",
    "v8::internal::maglev::BranchIfFloat64ToBooleanTrue::SetValueLocationConstraints",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5arith15MulSIExtendedOpEED0Ev", "mlir::RegisteredOperationName::Model<mlir::arith::MulSIExtendedOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::arith::MulSIExtendedOp>::~Model",
  ),
  (
    "_ZN4llvm7jitlink21MachOLinkGraphBuilder33graphifySectionsWithCustomParsersEv",
    "llvm::jitlink::MachOLinkGraphBuilder::graphifySectionsWithCustomParsers()",
    "llvm::jitlink::MachOLinkGraphBuilder::graphifySectionsWithCustomParsers",
  ),
  (
    "_ZN4mlir4LLVM6FSubOp6createERNS_20ImplicitLocOpBuilderENS_5ValueES4_NS0_17FastmathFlagsAttrE",
    "mlir::LLVM::FSubOp::create(mlir::ImplicitLocOpBuilder&, mlir::Value, mlir::Value, mlir::LLVM::FastmathFlagsAttr)",
    "mlir::LLVM::FSubOp::create",
  ),
  (
    "_ZN12lldb_private18ScriptedThreadPlanD0Ev", "lldb_private::ScriptedThreadPlan::~ScriptedThreadPlan()",
    "lldb_private::ScriptedThreadPlan::~ScriptedThreadPlan",
  ),
  (
    "_ZN2v88internal4Heap15IterateSmiRootsEPNS0_11RootVisitorE", "v8::internal::Heap::IterateSmiRoots(v8::internal::RootVisitor*)",
    "v8::internal::Heap::IterateSmiRoots",
  ),
  (
    "_ZL22nPragmaDetectMismatchs", "nPragmaDetectMismatchs", "nPragmaDetectMismatchs",
  ),
  (
    "_ZL37_hb_cairo_add_sweep_gradient_patches1ffffP16hb_cairo_color_tfS0_P14_cairo_pattern",
    "_hb_cairo_add_sweep_gradient_patches1(float, float, float, float, hb_cairo_color_t*, float, hb_cairo_color_t*, _cairo_pattern*)",
    "_hb_cairo_add_sweep_gradient_patches1",
  ),
  (
    "_ZN2v88internal9OutBufferItE6ExtendEm", "v8::internal::OutBuffer<unsigned short>::Extend(unsigned long)",
    "v8::internal::OutBuffer<unsigned short>::Extend",
  ),
  (
    "_ZN4mlir5spirv6UModOp5buildERNS_9OpBuilderERNS_14OperationStateENS_5ValueES6_",
    "mlir::spirv::UModOp::build(mlir::OpBuilder&, mlir::OperationState&, mlir::Value, mlir::Value)",
    "mlir::spirv::UModOp::build",
  ),
  (
    "_ZTINSt3__120__shared_ptr_emplaceIN12lldb_private18StopInfoUnixSignalENS_9allocatorIS2_EEEE",
    "typeinfo for std::__1::__shared_ptr_emplace<lldb_private::StopInfoUnixSignal, std::__1::allocator<lldb_private::StopInfoUnixSignal>>",
    "typeinfo for std::__1::__shared_ptr_emplace<lldb_private::StopInfoUnixSignal, std::__1::allocator<lldb_private::StopInfoUnixSignal>>",
  ),
  (
    "_ZTIN4mlir25ScalarizeVectorOpLoweringINS_4math7ExpM1OpEEE", "typeinfo for mlir::ScalarizeVectorOpLowering<mlir::math::ExpM1Op>",
    "typeinfo for mlir::ScalarizeVectorOpLowering<mlir::math::ExpM1Op>",
  ),
  (
    "_ZTVN2v88internal24BuiltinContinuationFrameE", "vtable for v8::internal::BuiltinContinuationFrame",
    "vtable for v8::internal::BuiltinContinuationFrame",
  ),
  (
    "_ZTSN4llvm9sandboxir10ReturnInstE", "typeinfo name for llvm::sandboxir::ReturnInst",
    "typeinfo name for llvm::sandboxir::ReturnInst",
  ),
  (
    "_ZN4mlir24ValueBoundsConstraintSet10projectOutEN4llvm12function_refIFbNSt3__14pairINS_5ValueExEEEEE",
    "mlir::ValueBoundsConstraintSet::projectOut(llvm::function_ref<bool (std::__1::pair<mlir::Value, long long>)>)",
    "mlir::ValueBoundsConstraintSet::projectOut",
  ),
  (
    "_ZN7Iex_3_48EnxioExcC2ERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE",
    "Iex_3_4::EnxioExc::EnxioExc(std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>> const&)",
    "Iex_3_4::EnxioExc::EnxioExc",
  ),
  (
    "_ZN12lldb_private10ThreadPlan15ThreadDestroyedEv", "lldb_private::ThreadPlan::ThreadDestroyed()",
    "lldb_private::ThreadPlan::ThreadDestroyed",
  ),
  (
    "_ZN4llvm31initializeHexagonAsmPrinterPassERNS_12PassRegistryE", "llvm::initializeHexagonAsmPrinterPass(llvm::PassRegistry&)",
    "llvm::initializeHexagonAsmPrinterPass",
  ),
  (
    "_ZNK4llvm16BasicTTIImplBaseINS_9VETTIImplEE14isTruncateFreeEPNS_4TypeES4_",
    "llvm::BasicTTIImplBase<llvm::VETTIImpl>::isTruncateFree(llvm::Type*, llvm::Type*) const",
    "llvm::BasicTTIImplBase<llvm::VETTIImpl>::isTruncateFree",
  ),
  (
    "_ZN6nbytes12stringsearch12StringSearchItE24BoyerMooreHorspoolSearchENS0_6VectorIKtEEm",
    "nbytes::stringsearch::StringSearch<unsigned short>::BoyerMooreHorspoolSearch(nbytes::stringsearch::Vector<unsigned short const>, unsigned long)",
    "nbytes::stringsearch::StringSearch<unsigned short>::BoyerMooreHorspoolSearch",
  ),
  (
    "_ZN4llvm15DecIntegerStateIjED0Ev", "llvm::DecIntegerState<unsigned int>::~DecIntegerState()",
    "llvm::DecIntegerState<unsigned int>::~DecIntegerState",
  ),
  (
    "_ZTIN4mlir19OpConversionPatternINS_5spirv7StoreOpEEE", "typeinfo for mlir::OpConversionPattern<mlir::spirv::StoreOp>",
    "typeinfo for mlir::OpConversionPattern<mlir::spirv::StoreOp>",
  ),
  (
    "_ZN17hint_macro_solver5resetEv", "hint_macro_solver::reset()", "hint_macro_solver::reset",
  ),
  (
    "_ZN4lldb20SBCommandInterpreter13GetTranscriptEv", "lldb::SBCommandInterpreter::GetTranscript()",
    "lldb::SBCommandInterpreter::GetTranscript",
  ),
  (
    "_ZN4mlir10pdl_interp18CheckTypeOpAdaptor6verifyENS_8LocationE", "mlir::pdl_interp::CheckTypeOpAdaptor::verify(mlir::Location)",
    "mlir::pdl_interp::CheckTypeOpAdaptor::verify",
  ),
  (
    "_ZTIN12_GLOBAL__N_110PPCOperandE", "typeinfo for (anonymous namespace)::PPCOperand",
    "typeinfo for (anonymous namespace)::PPCOperand",
  ),
  (
    "_ZN4absl13hash_internal17kStaticRandomDataE", "absl::hash_internal::kStaticRandomData",
    "absl::hash_internal::kStaticRandomData",
  ),
  (
    "_ZN4mlir5spirv7YieldOp5parseERNS_11OpAsmParserERNS_14OperationStateE", "mlir::spirv::YieldOp::parse(mlir::OpAsmParser&, mlir::OperationState&)",
    "mlir::spirv::YieldOp::parse",
  ),
  (
    "_ZN4mlir4LLVM25vector_reduce_uminAdaptor6verifyENS_8LocationE", "mlir::LLVM::vector_reduce_uminAdaptor::verify(mlir::Location)",
    "mlir::LLVM::vector_reduce_uminAdaptor::verify",
  ),
  (
    "_ZN2qe15mk_arith_pluginERNS_16i_solver_contextEbR10smt_params", "qe::mk_arith_plugin(qe::i_solver_context&, bool, smt_params&)",
    "qe::mk_arith_plugin",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4NVVM16MBarrierArriveOpEED0Ev", "mlir::RegisteredOperationName::Model<mlir::NVVM::MBarrierArriveOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::NVVM::MBarrierArriveOp>::~Model",
  ),
  (
    "_ZN4node18EnvironmentOptionsD2Ev", "node::EnvironmentOptions::~EnvironmentOptions()",
    "node::EnvironmentOptions::~EnvironmentOptions",
  ),
  (
    "_ZTVN4mlir23RegisteredOperationName5ModelINS_5spirv28KHRCooperativeMatrixLengthOpEEE",
    "vtable for mlir::RegisteredOperationName::Model<mlir::spirv::KHRCooperativeMatrixLengthOp>",
    "vtable for mlir::RegisteredOperationName::Model<mlir::spirv::KHRCooperativeMatrixLengthOp>",
  ),
  (
    "_ZN2v88internal20ProducedPreparseData3ForEPNS0_16ZonePreparseDataEPNS0_4ZoneE",
    "v8::internal::ProducedPreparseData::For(v8::internal::ZonePreparseData*, v8::internal::Zone*)",
    "v8::internal::ProducedPreparseData::For",
  ),
  (
    "_ZN2v88internal30FastNewRestArgumentsDescriptor13kMachineTypesE", "v8::internal::FastNewRestArgumentsDescriptor::kMachineTypes",
    "v8::internal::FastNewRestArgumentsDescriptor::kMachineTypes",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4NVVM15BarrierArriveOpEE16verifyInvariantsEPNS_9OperationE",
    "mlir::RegisteredOperationName::Model<mlir::NVVM::BarrierArriveOp>::verifyInvariants(mlir::Operation*)",
    "mlir::RegisteredOperationName::Model<mlir::NVVM::BarrierArriveOp>::verifyInvariants",
  ),
  (
    "_ZN4mlir5ROCDL11WaitDscntOp14readPropertiesERNS_21DialectBytecodeReaderERNS_14OperationStateE",
    "mlir::ROCDL::WaitDscntOp::readProperties(mlir::DialectBytecodeReader&, mlir::OperationState&)",
    "mlir::ROCDL::WaitDscntOp::readProperties",
  ),
  (
    "_ZN12lldb_private37RegisterInfos_x86_64_with_base_shared16g_invalidate_fipE",
    "lldb_private::RegisterInfos_x86_64_with_base_shared::g_invalidate_fip", "lldb_private::RegisterInfos_x86_64_with_base_shared::g_invalidate_fip",
  ),
  (
    "_ZN4smt26parser15parse_model_delEv", "smt2::parser::parse_model_del()", "smt2::parser::parse_model_del",
  ),
  (
    "_ZTVN12_GLOBAL__N_126StdLibraryFunctionsChecker20ResetErrnoConstraintE", "vtable for (anonymous namespace)::StdLibraryFunctionsChecker::ResetErrnoConstraint",
    "vtable for (anonymous namespace)::StdLibraryFunctionsChecker::ResetErrnoConstraint",
  ),
  (
    "_ZN12_GLOBAL__N_124BitcastConversionPatternD1Ev", "(anonymous namespace)::BitcastConversionPattern::~BitcastConversionPattern()",
    "(anonymous namespace)::BitcastConversionPattern::~BitcastConversionPattern",
  ),
  (
    "_ZNSt3__112__next_primeEm", "std::__1::__next_prime(unsigned long)", "std::__1::__next_prime",
  ),
  (
    "_ZN4mlir5emitc10ConstantOp20verifyInvariantsImplEv", "mlir::emitc::ConstantOp::verifyInvariantsImpl()",
    "mlir::emitc::ConstantOp::verifyInvariantsImpl",
  ),
  (
    "_ZN4llvm16GCNSchedStrategy21pickNodeBidirectionalERbS1_", "llvm::GCNSchedStrategy::pickNodeBidirectional(bool&, bool&)",
    "llvm::GCNSchedStrategy::pickNodeBidirectional",
  ),
  (
    "_ZN4mlir9x86vector12MaskScaleFOp6createERNS_20ImplicitLocOpBuilderENS_5ValueES4_S4_S4_S4_",
    "mlir::x86vector::MaskScaleFOp::create(mlir::ImplicitLocOpBuilder&, mlir::Value, mlir::Value, mlir::Value, mlir::Value, mlir::Value)",
    "mlir::x86vector::MaskScaleFOp::create",
  ),
  (
    "_ZN4llvm11logicalview8LVReader17createScopeModuleEv", "llvm::logicalview::LVReader::createScopeModule()",
    "llvm::logicalview::LVReader::createScopeModule",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4LLVM14VPReduceUMinOpEE16verifyInvariantsEPNS_9OperationE",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::VPReduceUMinOp>::verifyInvariants(mlir::Operation*)",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::VPReduceUMinOp>::verifyInvariants",
  ),
  (
    "_ZN18StaticDataSplitterC2Ev", "StaticDataSplitter::StaticDataSplitter()", "StaticDataSplitter::StaticDataSplitter",
  ),
  (
    "_ZN3std6thread5local18panic_access_error17h40802c03efd66e27E", "std::thread::local::panic_access_error::h40802c03efd66e27",
    "std::thread::local::panic_access_error::h40802c03efd66e27",
  ),
  (
    "_ZN4mlir7OpTrait4impl18verifyIsIdempotentEPNS_9OperationE", "mlir::OpTrait::impl::verifyIsIdempotent(mlir::Operation*)",
    "mlir::OpTrait::impl::verifyIsIdempotent",
  ),
  (
    "_ZN2v88internal9Assembler6fcvtasERKNS0_9VRegisterES4_", "v8::internal::Assembler::fcvtas(v8::internal::VRegister const&, v8::internal::VRegister const&)",
    "v8::internal::Assembler::fcvtas",
  ),
  (
    "_ZN2v88internal9Assembler6smsublERKNS0_8RegisterES4_S4_S4_", "v8::internal::Assembler::smsubl(v8::internal::Register const&, v8::internal::Register const&, v8::internal::Register const&, v8::internal::Register const&)",
    "v8::internal::Assembler::smsubl",
  ),
  (
    "_ZTSNSt3__110__function6__funcIZ17mk_default_tacticR11ast_managerRK10params_refE3$_2FP6tacticS3_S6_EEE",
    "typeinfo name for std::__1::__function::__func<mk_default_tactic(ast_manager&, params_ref const&)::$_2, tactic* (ast_manager&, params_ref const&)>",
    "typeinfo name for std::__1::__function::__func<mk_default_tactic(ast_manager&, params_ref const&)::$_2, tactic* (ast_manager&, params_ref const&)>",
  ),
  (
    "_ZN4mlir5async11CoroBeginOp6createERNS_9OpBuilderENS_8LocationENS_9TypeRangeENS_5ValueE",
    "mlir::async::CoroBeginOp::create(mlir::OpBuilder&, mlir::Location, mlir::TypeRange, mlir::Value)",
    "mlir::async::CoroBeginOp::create",
  ),
  (
    "_ZN4llvmL83ZPR4_with_zsub_in_FPR128_0to7_and_ZPR4_with_zsub2_in_ZPRMul4_and_ZPR_3bSubClassMaskE",
    "llvm::ZPR4_with_zsub_in_FPR128_0to7_and_ZPR4_with_zsub2_in_ZPRMul4_and_ZPR_3bSubClassMask",
    "llvm::ZPR4_with_zsub_in_FPR128_0to7_and_ZPR4_with_zsub2_in_ZPRMul4_and_ZPR_3bSubClassMask",
  ),
  (
    "_ZTSN4mlir23RegisteredOperationName5ModelINS_5ROCDL22wmma_f32_16x16x16_bf16EEE",
    "typeinfo name for mlir::RegisteredOperationName::Model<mlir::ROCDL::wmma_f32_16x16x16_bf16>",
    "typeinfo name for mlir::RegisteredOperationName::Model<mlir::ROCDL::wmma_f32_16x16x16_bf16>",
  ),
  (
    "_ZN4llvmL61UACCRC_with_sub_pair1_then_sub_64_in_SPILLTOVSRRCSuperclassesE",
    "llvm::UACCRC_with_sub_pair1_then_sub_64_in_SPILLTOVSRRCSuperclasses", "llvm::UACCRC_with_sub_pair1_then_sub_64_in_SPILLTOVSRRCSuperclasses",
  ),
  (
    "_ZTIN12_GLOBAL__N_124ParsedAttrInfoAllocAlignE", "typeinfo for (anonymous namespace)::ParsedAttrInfoAllocAlign",
    "typeinfo for (anonymous namespace)::ParsedAttrInfoAllocAlign",
  ),
  (
    "_ZN12lldb_private15TypeSystemClang10IsCharTypeEPv", "lldb_private::TypeSystemClang::IsCharType(void*)",
    "lldb_private::TypeSystemClang::IsCharType",
  ),
  (
    "_ZN5tokio7runtime4task3raw15try_read_output17h0d31381974a9d105E", "tokio::runtime::task::raw::try_read_output::h0d31381974a9d105",
    "tokio::runtime::task::raw::try_read_output::h0d31381974a9d105",
  ),
  (
    "_ZN4mlir5spirv12Deserializer9processOpINS0_6SDivOpEEEN4llvm13LogicalResultENS4_8ArrayRefIjEE",
    "llvm::LogicalResult mlir::spirv::Deserializer::processOp<mlir::spirv::SDivOp>(llvm::ArrayRef<unsigned int>)",
    "mlir::spirv::Deserializer::processOp<mlir::spirv::SDivOp>",
  ),
  (
    "_ZTIZN4llvm20HexagonTargetMachine28registerPassBuilderCallbacksERNS_11PassBuilderEE4$_13",
    "typeinfo for llvm::HexagonTargetMachine::registerPassBuilderCallbacks(llvm::PassBuilder&)::$_13",
    "typeinfo for llvm::HexagonTargetMachine::registerPassBuilderCallbacks(llvm::PassBuilder&)::$_13",
  ),
  (
    "_ZTSNSt3__120__shared_ptr_emplaceINS_5mutexENS_9allocatorIS1_EEEE", "typeinfo name for std::__1::__shared_ptr_emplace<std::__1::mutex, std::__1::allocator<std::__1::mutex>>",
    "typeinfo name for std::__1::__shared_ptr_emplace<std::__1::mutex, std::__1::allocator<std::__1::mutex>>",
  ),
  (
    "_ZN5polly13SCEVAffinator13visitUDivExprEPKN4llvm12SCEVUDivExprE", "polly::SCEVAffinator::visitUDivExpr(llvm::SCEVUDivExpr const*)",
    "polly::SCEVAffinator::visitUDivExpr",
  ),
  (
    "_ZN12lldb_private6Target8StopHookD0Ev", "lldb_private::Target::StopHook::~StopHook()",
    "lldb_private::Target::StopHook::~StopHook",
  ),
  (
    "_ZN4mlir9transform7MatchOp12setInterfaceENSt3__18optionalINS0_18MatchInterfaceEnumEEE",
    "mlir::transform::MatchOp::setInterface(std::__1::optional<mlir::transform::MatchInterfaceEnum>)",
    "mlir::transform::MatchOp::setInterface",
  ),
  (
    "_ZN4llvm2cl4bitsI18PGOMapFeaturesEnumbNS0_6parserIS2_EEE10setDefaultEv", "llvm::cl::bits<PGOMapFeaturesEnum, bool, llvm::cl::parser<PGOMapFeaturesEnum>>::setDefault()",
    "llvm::cl::bits<PGOMapFeaturesEnum, bool, llvm::cl::parser<PGOMapFeaturesEnum>>::setDefault",
  ),
  (
    "_ZN4absl13base_internal13LowLevelAlloc5AllocEm.cold.1", "absl::base_internal::LowLevelAlloc::Alloc(unsigned long) (.cold.1)",
    "absl::base_internal::LowLevelAlloc::Alloc",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_3amx10TileMulIOpEE22verifyRegionInvariantsEPNS_9OperationE",
    "mlir::RegisteredOperationName::Model<mlir::amx::TileMulIOp>::verifyRegionInvariants(mlir::Operation*)",
    "mlir::RegisteredOperationName::Model<mlir::amx::TileMulIOp>::verifyRegionInvariants",
  ),
  (
    "_ZN4mlir4LLVM13EhTypeidForOp6createERNS_20ImplicitLocOpBuilderENS_4TypeENS_5ValueE",
    "mlir::LLVM::EhTypeidForOp::create(mlir::ImplicitLocOpBuilder&, mlir::Type, mlir::Value)",
    "mlir::LLVM::EhTypeidForOp::create",
  ),
  (
    "_ZN5clang4Sema18ActOnExprStmtErrorEv", "clang::Sema::ActOnExprStmtError()",
    "clang::Sema::ActOnExprStmtError",
  ),
  (
    "_ZN4mlir3acc18GlobalDestructorOp5parseERNS_11OpAsmParserERNS_14OperationStateE",
    "mlir::acc::GlobalDestructorOp::parse(mlir::OpAsmParser&, mlir::OperationState&)",
    "mlir::acc::GlobalDestructorOp::parse",
  ),
  (
    "_ZN5clang13ASTStmtWriter27VisitOpenACCUpdateConstructEPNS_22OpenACCUpdateConstructE",
    "clang::ASTStmtWriter::VisitOpenACCUpdateConstruct(clang::OpenACCUpdateConstruct*)",
    "clang::ASTStmtWriter::VisitOpenACCUpdateConstruct",
  ),
  (
    "_ZN4node8builtinsL22internal_file_resourceE", "node::builtins::internal_file_resource",
    "node::builtins::internal_file_resource",
  ),
  (
    "_ZN2v88internal15DbgStdoutStreamC1Ev", "v8::internal::DbgStdoutStream::DbgStdoutStream()",
    "v8::internal::DbgStdoutStream::DbgStdoutStream",
  ),
  (
    "_ZN4mlir5spirv18BitFieldSExtractOp13getExtensionsEv", "mlir::spirv::BitFieldSExtractOp::getExtensions()",
    "mlir::spirv::BitFieldSExtractOp::getExtensions",
  ),
  (
    "_ZN5clang13TreeTransformIN12_GLOBAL__N_113TransformToPEEE21TransformOMPMapClauseEPNS_12OMPMapClauseE",
    "clang::TreeTransform<(anonymous namespace)::TransformToPE>::TransformOMPMapClause(clang::OMPMapClause*)",
    "clang::TreeTransform<(anonymous namespace)::TransformToPE>::TransformOMPMapClause",
  ),
  (
    "_ZN2v88internal26WasmStringConcatDescriptor13kMachineTypesE", "v8::internal::WasmStringConcatDescriptor::kMachineTypes",
    "v8::internal::WasmStringConcatDescriptor::kMachineTypes",
  ),
  (
    "_ZNK12_GLOBAL__N_121ROCDLInlinerInterface15isLegalToInlineEPN4mlir9OperationEPNS1_6RegionEbRNS1_9IRMappingE",
    "(anonymous namespace)::ROCDLInlinerInterface::isLegalToInline(mlir::Operation*, mlir::Region*, bool, mlir::IRMapping&) const",
    "(anonymous namespace)::ROCDLInlinerInterface::isLegalToInline",
  ),
  (
    "_ZN4llvmL47AV_1024_with_sub28_in_VGPR_32_Lo128SubClassMaskE", "llvm::AV_1024_with_sub28_in_VGPR_32_Lo128SubClassMask",
    "llvm::AV_1024_with_sub28_in_VGPR_32_Lo128SubClassMask",
  ),
  (
    "_ZN4ring10arithmetic6bigint7modulus21OwnedModulus$LT$M$GT$7to_elem17h4119615d60eff3aeE",
    "ring::arithmetic::bigint::modulus::OwnedModulus$LT$M$GT$::to_elem::h4119615d60eff3ae",
    "ring::arithmetic::bigint::modulus::OwnedModulus$LT$M$GT$::to_elem::h4119615d60eff3ae",
  ),
  (
    "_ZNK4llvm16itanium_demangle27ExpandedSpecialSubstitution11getBaseNameEv", "llvm::itanium_demangle::ExpandedSpecialSubstitution::getBaseName() const",
    "llvm::itanium_demangle::ExpandedSpecialSubstitution::getBaseName",
  ),
  (
    "_ZNK4llvm27TargetTransformInfoImplBase28isVScaleKnownToBeAPowerOfTwoEv", "llvm::TargetTransformInfoImplBase::isVScaleKnownToBeAPowerOfTwo() const",
    "llvm::TargetTransformInfoImplBase::isVScaleKnownToBeAPowerOfTwo",
  ),
  (
    "_ZN4mlir3acc11ReductionOp27getODSOperandIndexAndLengthEj", "mlir::acc::ReductionOp::getODSOperandIndexAndLength(unsigned int)",
    "mlir::acc::ReductionOp::getODSOperandIndexAndLength",
  ),
  (
    "_ZZN4node2fs11BindingData17LegacyMainResolveERKN2v820FunctionCallbackInfoINS2_5ValueEEEE20error_and_abort_args",
    "node::fs::BindingData::LegacyMainResolve(v8::FunctionCallbackInfo<v8::Value> const&)::error_and_abort_args",
    "node::fs::BindingData::LegacyMainResolve(v8::FunctionCallbackInfo<v8::Value> const&)::error_and_abort_args",
  ),
  (
    "_ZN4llvm16MachineIRBuilder12buildUnmergeENS_8ArrayRefINS_3LLTEEERKNS_5SrcOpE",
    "llvm::MachineIRBuilder::buildUnmerge(llvm::ArrayRef<llvm::LLT>, llvm::SrcOp const&)",
    "llvm::MachineIRBuilder::buildUnmerge",
  ),
  ("_ZL14g_contained_z2", "g_contained_z2", "g_contained_z2"),
  (
    "_ZTIN4llvm2cl15OptionValueBaseINS_19TargetTransformInfo18AddressingModeKindELb0EEE",
    "typeinfo for llvm::cl::OptionValueBase<llvm::TargetTransformInfo::AddressingModeKind, false>",
    "typeinfo for llvm::cl::OptionValueBase<llvm::TargetTransformInfo::AddressingModeKind, false>",
  ),
  (
    "_ZN4mlir4LLVM19VPReduceOrOpAdaptor6verifyENS_8LocationE", "mlir::LLVM::VPReduceOrOpAdaptor::verify(mlir::Location)",
    "mlir::LLVM::VPReduceOrOpAdaptor::verify",
  ),
  (
    "_ZN5clang7ODRHash13AddRecordDeclEPKNS_10RecordDeclE", "clang::ODRHash::AddRecordDecl(clang::RecordDecl const*)",
    "clang::ODRHash::AddRecordDecl",
  ),
  (
    "_ZZN4node2fsL6LChownERKN2v820FunctionCallbackInfoINS1_5ValueEEEE20error_and_abort_args_0",
    "node::fs::LChown(v8::FunctionCallbackInfo<v8::Value> const&)::error_and_abort_args",
    "node::fs::LChown(v8::FunctionCallbackInfo<v8::Value> const&)::error_and_abort_args",
  ),
  (
    "_ZN4mlir10ml_program8GlobalOp20verifyInvariantsImplEv", "mlir::ml_program::GlobalOp::verifyInvariantsImpl()",
    "mlir::ml_program::GlobalOp::verifyInvariantsImpl",
  ),
  (
    "_ZTIN12_GLOBAL__N_125UncountedLocalVarsCheckerE", "typeinfo for (anonymous namespace)::UncountedLocalVarsChecker",
    "typeinfo for (anonymous namespace)::UncountedLocalVarsChecker",
  ),
  (
    "_ZN4mlir5ROCDL6detail43wmma_f16_16x16x64_fp8_fp8GenericAdaptorBase9getReuseAEv",
    "mlir::ROCDL::detail::wmma_f16_16x16x64_fp8_fp8GenericAdaptorBase::getReuseA()",
    "mlir::ROCDL::detail::wmma_f16_16x16x64_fp8_fp8GenericAdaptorBase::getReuseA",
  ),
  (
    "_ZN2v88internal8compiler29SimplifiedOperatorGlobalCache30TruncateBigIntToWord64OperatorD0Ev",
    "v8::internal::compiler::SimplifiedOperatorGlobalCache::TruncateBigIntToWord64Operator::~TruncateBigIntToWord64Operator()",
    "v8::internal::compiler::SimplifiedOperatorGlobalCache::TruncateBigIntToWord64Operator::~TruncateBigIntToWord64Operator",
  ),
  (
    "_ZN5clang13TreeTransformIN12_GLOBAL__N_128ExtractTypeForDeductionGuideEE20TransformInitializerEPNS_4ExprEb",
    "clang::TreeTransform<(anonymous namespace)::ExtractTypeForDeductionGuide>::TransformInitializer(clang::Expr*, bool)",
    "clang::TreeTransform<(anonymous namespace)::ExtractTypeForDeductionGuide>::TransformInitializer",
  ),
  (
    "_ZN5clang4Sema22ActOnSimpleRequirementEPNS_4ExprE", "clang::Sema::ActOnSimpleRequirement(clang::Expr*)",
    "clang::Sema::ActOnSimpleRequirement",
  ),
  (
    "_ZTSN4llvm2cl3optIjLb1ENS0_6parserIjEEEE", "typeinfo name for llvm::cl::opt<unsigned int, true, llvm::cl::parser<unsigned int>>",
    "typeinfo name for llvm::cl::opt<unsigned int, true, llvm::cl::parser<unsigned int>>",
  ),
  ("_ZTI5trail", "typeinfo for trail", "typeinfo for trail"),
  (
    "_ZTSZNK4llvm25AMDGPUInstructionSelector23selectMUBUFScratchOffenERNS_14MachineOperandEE3$_1",
    "typeinfo name for llvm::AMDGPUInstructionSelector::selectMUBUFScratchOffen(llvm::MachineOperand&) const::$_1",
    "typeinfo name for llvm::AMDGPUInstructionSelector::selectMUBUFScratchOffen(llvm::MachineOperand&) const::$_1",
  ),
  (
    "_ZNK5clang17UninitializedAttr11printPrettyERN4llvm11raw_ostreamERKNS_14PrintingPolicyE",
    "clang::UninitializedAttr::printPretty(llvm::raw_ostream&, clang::PrintingPolicy const&) const",
    "clang::UninitializedAttr::printPretty",
  ),
  (
    "_ZN20eliminate_predicates23can_be_quasi_macro_headEP4exprj", "eliminate_predicates::can_be_quasi_macro_head(expr*, unsigned int)",
    "eliminate_predicates::can_be_quasi_macro_head",
  ),
  (
    "_ZN5clang30DynamicRecursiveASTVisitorBaseILb1EE28TraverseDependentCoawaitExprEPKNS_20DependentCoawaitExprE",
    "clang::DynamicRecursiveASTVisitorBase<true>::TraverseDependentCoawaitExpr(clang::DependentCoawaitExpr const*)",
    "clang::DynamicRecursiveASTVisitorBase<true>::TraverseDependentCoawaitExpr",
  ),
  (
    "_ZN12_GLOBAL__N_112InstrLowerer19setupProfileSectionEPN4llvm17InstrProfInstBaseENS1_17InstrProfSectKindE",
    "(anonymous namespace)::InstrLowerer::setupProfileSection(llvm::InstrProfInstBase*, llvm::InstrProfSectKind)",
    "(anonymous namespace)::InstrLowerer::setupProfileSection",
  ),
  (
    "_ZN2v88internal8compiler23CompilationDependencies29DependOnEmptyContextExtensionENS1_12ScopeInfoRefE",
    "v8::internal::compiler::CompilationDependencies::DependOnEmptyContextExtension(v8::internal::compiler::ScopeInfoRef)",
    "v8::internal::compiler::CompilationDependencies::DependOnEmptyContextExtension",
  ),
  (
    "_ZL52_wrap_SBBreakpointLocation_SetScriptCallbackFunctionP7_objectS0_", "_wrap_SBBreakpointLocation_SetScriptCallbackFunction(_object*, _object*)",
    "_wrap_SBBreakpointLocation_SetScriptCallbackFunction",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4NVVM10EnvReg29OpEE17comparePropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::NVVM::EnvReg29Op>::compareProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::NVVM::EnvReg29Op>::compareProperties",
  ),
  (
    "_ZN6bufferIPN1q7bindingELb0ELj16EED2Ev", "buffer<q::binding*, false, 16u>::~buffer()",
    "buffer<q::binding*, false, 16u>::~buffer",
  ),
  (
    "_ZN4mlir5spirv7YieldOp20verifyInvariantsImplEv", "mlir::spirv::YieldOp::verifyInvariantsImpl()",
    "mlir::spirv::YieldOp::verifyInvariantsImpl",
  ),
  (
    "_ZN2v88internal4Zone13AllocateArrayINS0_4wasm17WasmModuleBuilder9WasmTableEA_S5_EEPT_m",
    "v8::internal::wasm::WasmModuleBuilder::WasmTable* v8::internal::Zone::AllocateArray<v8::internal::wasm::WasmModuleBuilder::WasmTable, v8::internal::wasm::WasmModuleBuilder::WasmTable []>(unsigned long)",
    "v8::internal::Zone::AllocateArray<v8::internal::wasm::WasmModuleBuilder::WasmTable, v8::internal::wasm::WasmModuleBuilder::WasmTable []>",
  ),
  (
    "_ZTS14simple_factoryI8rationalE", "typeinfo name for simple_factory<rational>",
    "typeinfo name for simple_factory<rational>",
  ),
  (
    "_ZN4mlir17SymbolOpInterface10setPrivateEv", "mlir::SymbolOpInterface::setPrivate()",
    "mlir::SymbolOpInterface::setPrivate",
  ),
  (
    "_ZN4lldb14SBTypeCategoryD2Ev", "lldb::SBTypeCategory::~SBTypeCategory()", "lldb::SBTypeCategory::~SBTypeCategory",
  ),
  (
    "_ZN9hashbrown3raw21RawTable$LT$T$C$A$GT$14reserve_rehash17h4a18038705b5a956E",
    "hashbrown::raw::RawTable$LT$T$C$A$GT$::reserve_rehash::h4a18038705b5a956", "hashbrown::raw::RawTable$LT$T$C$A$GT$::reserve_rehash::h4a18038705b5a956",
  ),
  (
    "_ZN5clang12ast_matchers9isWrittenEv", "clang::ast_matchers::isWritten()", "clang::ast_matchers::isWritten",
  ),
  (
    "_ZN5clang20ObjCNonLazyClassAttrC2ERNS_10ASTContextERKNS_19AttributeCommonInfoE",
    "clang::ObjCNonLazyClassAttr::ObjCNonLazyClassAttr(clang::ASTContext&, clang::AttributeCommonInfo const&)",
    "clang::ObjCNonLazyClassAttr::ObjCNonLazyClassAttr",
  ),
  (
    "_ZN5clang17computeDependenceEPNS_9ParenExprE", "clang::computeDependence(clang::ParenExpr*)",
    "clang::computeDependence",
  ),
  (
    "_ZN4mlir9transform6detail31CastAndCallOpGenericAdaptorBaseC2ENS0_13CastAndCallOpE",
    "mlir::transform::detail::CastAndCallOpGenericAdaptorBase::CastAndCallOpGenericAdaptorBase(mlir::transform::CastAndCallOp)",
    "mlir::transform::detail::CastAndCallOpGenericAdaptorBase::CastAndCallOpGenericAdaptorBase",
  ),
  (
    "_ZN4mlir5spirv13ISubOpAdaptor6verifyENS_8LocationE", "mlir::spirv::ISubOpAdaptor::verify(mlir::Location)",
    "mlir::spirv::ISubOpAdaptor::verify",
  ),
  (
    "_ZN4mlir5spirv7YieldOp5buildERNS_9OpBuilderERNS_14OperationStateENS_9TypeRangeENS_5ValueE",
    "mlir::spirv::YieldOp::build(mlir::OpBuilder&, mlir::OperationState&, mlir::TypeRange, mlir::Value)",
    "mlir::spirv::YieldOp::build",
  ),
  (
    "_ZN4llvmL92AV_512_with_sub8_sub9_sub10_in_AV_96_Align2_and_AV_96_with_sub2_in_VGPR_32_Lo128SuperclassesE",
    "llvm::AV_512_with_sub8_sub9_sub10_in_AV_96_Align2_and_AV_96_with_sub2_in_VGPR_32_Lo128Superclasses",
    "llvm::AV_512_with_sub8_sub9_sub10_in_AV_96_Align2_and_AV_96_with_sub2_in_VGPR_32_Lo128Superclasses",
  ),
  (
    "_ZTIN9subpaving9context_tINS_11config_mpfxEE13node_selectorE", "typeinfo for subpaving::context_t<subpaving::config_mpfx>::node_selector",
    "typeinfo for subpaving::context_t<subpaving::config_mpfx>::node_selector",
  ),
  (
    "_ZN11PSOutputDev12updateRenderEP8GfxState", "PSOutputDev::updateRender(GfxState*)",
    "PSOutputDev::updateRender",
  ),
  (
    "_ZN4llvm2cl6parserI21IntrinsicCostStrategyED0Ev", "llvm::cl::parser<IntrinsicCostStrategy>::~parser()",
    "llvm::cl::parser<IntrinsicCostStrategy>::~parser",
  ),
  (
    "_ZNK4llvm16HexagonInstrInfo15isNewValueStoreEj", "llvm::HexagonInstrInfo::isNewValueStore(unsigned int) const",
    "llvm::HexagonInstrInfo::isNewValueStore",
  ),
  (
    "_ZN12_GLOBAL__N_116OperationPrinter22printCustomOrGenericOpEPN4mlir9OperationE",
    "(anonymous namespace)::OperationPrinter::printCustomOrGenericOp(mlir::Operation*)",
    "(anonymous namespace)::OperationPrinter::printCustomOrGenericOp",
  ),
  (
    "_ZN12lldb_private7Process11GetAuxvDataEv", "lldb_private::Process::GetAuxvData()",
    "lldb_private::Process::GetAuxvData",
  ),
  (
    "_ZN4llvm6detail9PassModelINS_8FunctionENS_21RegionInfoPrinterPassENS_15AnalysisManagerIS2_JEEEJEED0Ev",
    "llvm::detail::PassModel<llvm::Function, llvm::RegionInfoPrinterPass, llvm::AnalysisManager<llvm::Function>>::~PassModel()",
    "llvm::detail::PassModel<llvm::Function, llvm::RegionInfoPrinterPass, llvm::AnalysisManager<llvm::Function>>::~PassModel",
  ),
  (
    "_ZTIN4llvm16itanium_demangle12InitListExprE", "typeinfo for llvm::itanium_demangle::InitListExpr",
    "typeinfo for llvm::itanium_demangle::InitListExpr",
  ),
  (
    "_ZTIN4mlir22ConvertOpToLLVMPatternINS_3omp8WsloopOpELb0EEE", "typeinfo for mlir::ConvertOpToLLVMPattern<mlir::omp::WsloopOp, false>",
    "typeinfo for mlir::ConvertOpToLLVMPattern<mlir::omp::WsloopOp, false>",
  ),
  (
    "_ZTS9BufStream", "typeinfo name for BufStream", "typeinfo name for BufStream",
  ),
  (
    "_ZN12lldb_private7Process11LoadModulesEv", "lldb_private::Process::LoadModules()",
    "lldb_private::Process::LoadModules",
  ),
  (
    "_ZN4mlir4tosa8ResizeOp5buildERNS_9OpBuilderERNS_14OperationStateENS_4TypeENS_5ValueES7_S7_S7_NS0_10ResizeModeE",
    "mlir::tosa::ResizeOp::build(mlir::OpBuilder&, mlir::OperationState&, mlir::Type, mlir::Value, mlir::Value, mlir::Value, mlir::Value, mlir::tosa::ResizeMode)",
    "mlir::tosa::ResizeOp::build",
  ),
  (
    "_ZN4mlir6memref10DmaStartOp6createERNS_9OpBuilderENS_8LocationENS_5ValueENS_10ValueRangeES5_S6_S5_S5_S6_S5_S5_",
    "mlir::memref::DmaStartOp::create(mlir::OpBuilder&, mlir::Location, mlir::Value, mlir::ValueRange, mlir::Value, mlir::ValueRange, mlir::Value, mlir::Value, mlir::ValueRange, mlir::Value, mlir::Value)",
    "mlir::memref::DmaStartOp::create",
  ),
  (
    "_ZN4llvm14RegisterTargetILNS_6Triple8ArchTypeE44ELb0EE12getArchMatchES2_", "llvm::RegisterTarget<(llvm::Triple::ArchType)44, false>::getArchMatch(llvm::Triple::ArchType)",
    "llvm::RegisterTarget<(llvm::Triple::ArchType)44, false>::getArchMatch",
  ),
  (
    "_ZTIZN5clang7tooling23getStripPluginsAdjusterEvE3$_0", "typeinfo for clang::tooling::getStripPluginsAdjuster()::$_0",
    "typeinfo for clang::tooling::getStripPluginsAdjuster()::$_0",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4LLVM11AddressOfOpEED0Ev", "mlir::RegisteredOperationName::Model<mlir::LLVM::AddressOfOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::AddressOfOp>::~Model",
  ),
  (
    "_ZTSZN4llvm18LegalityPredicates22memSizeNotByteSizePow2EjE3$_0", "typeinfo name for llvm::LegalityPredicates::memSizeNotByteSizePow2(unsigned int)::$_0",
    "typeinfo name for llvm::LegalityPredicates::memSizeNotByteSizePow2(unsigned int)::$_0",
  ),
  (
    "_ZN4mlir4LLVM6FNegOp5buildERNS_9OpBuilderERNS_14OperationStateENS_5ValueENS0_17FastmathFlagsAttrE",
    "mlir::LLVM::FNegOp::build(mlir::OpBuilder&, mlir::OperationState&, mlir::Value, mlir::LLVM::FastmathFlagsAttr)",
    "mlir::LLVM::FNegOp::build",
  ),
  (
    "_ZN4llvmL59VS_64_Align2_and_VS_64_with_sub0_in_VS_32_Lo128SuperclassesE", "llvm::VS_64_Align2_and_VS_64_with_sub0_in_VS_32_Lo128Superclasses",
    "llvm::VS_64_Align2_and_VS_64_with_sub0_in_VS_32_Lo128Superclasses",
  ),
  (
    "_ZN2v88internalL41FLAGDEFAULT_ephemeron_fixpoint_iterationsE", "v8::internal::FLAGDEFAULT_ephemeron_fixpoint_iterations",
    "v8::internal::FLAGDEFAULT_ephemeron_fixpoint_iterations",
  ),
  (
    "_ZN2v88internal6maglev20MaglevGraphOptimizer26VisitCheckSeqOneByteStringEv",
    "v8::internal::maglev::MaglevGraphOptimizer::VisitCheckSeqOneByteString()", "v8::internal::maglev::MaglevGraphOptimizer::VisitCheckSeqOneByteString",
  ),
  (
    "_ZN4mlir5spirv21GroupNonUniformFMaxOp5parseERNS_11OpAsmParserERNS_14OperationStateE",
    "mlir::spirv::GroupNonUniformFMaxOp::parse(mlir::OpAsmParser&, mlir::OperationState&)",
    "mlir::spirv::GroupNonUniformFMaxOp::parse",
  ),
  (
    "_ZN5clang7targets23MicrosoftMipsTargetInfoD1Ev", "clang::targets::MicrosoftMipsTargetInfo::~MicrosoftMipsTargetInfo()",
    "clang::targets::MicrosoftMipsTargetInfo::~MicrosoftMipsTargetInfo",
  ),
  (
    "_ZN12_GLOBAL__N_111MachOWriter20writeWeakBindOpcodesERN4llvm11raw_ostreamE",
    "(anonymous namespace)::MachOWriter::writeWeakBindOpcodes(llvm::raw_ostream&)",
    "(anonymous namespace)::MachOWriter::writeWeakBindOpcodes",
  ),
  (
    "_ZN2v88internal11interpreter17BytecodeGenerator11VisitSpreadEPNS0_6SpreadE",
    "v8::internal::interpreter::BytecodeGenerator::VisitSpread(v8::internal::Spread*)",
    "v8::internal::interpreter::BytecodeGenerator::VisitSpread",
  ),
  (
    "_ZNSt3__120__shared_ptr_emplaceIN4node6worker12SiblingGroupENS_9allocatorIS3_EEE16__on_zero_sharedEv",
    "std::__1::__shared_ptr_emplace<node::worker::SiblingGroup, std::__1::allocator<node::worker::SiblingGroup>>::__on_zero_shared()",
    "std::__1::__shared_ptr_emplace<node::worker::SiblingGroup, std::__1::allocator<node::worker::SiblingGroup>>::__on_zero_shared",
  ),
  (
    "_ZNK4llvm9sandboxir25SingleLLVMInstructionImplINS_13AtomicRMWInstEE15getUseOperandNoERKNS0_3UseE",
    "llvm::sandboxir::SingleLLVMInstructionImpl<llvm::AtomicRMWInst>::getUseOperandNo(llvm::sandboxir::Use const&) const",
    "llvm::sandboxir::SingleLLVMInstructionImpl<llvm::AtomicRMWInst>::getUseOperandNo",
  ),
  (
    "_ZN2v88internal16AllowCompilationC1EPNS0_7IsolateE", "v8::internal::AllowCompilation::AllowCompilation(v8::internal::Isolate*)",
    "v8::internal::AllowCompilation::AllowCompilation",
  ),
  (
    "_ZN4llvm7objcopy3elf15ELFSectionSizerINS_6object7ELFTypeILNS_10endiannessE0ELb1EEEED0Ev",
    "llvm::objcopy::elf::ELFSectionSizer<llvm::object::ELFType<(llvm::endianness)0, true>>::~ELFSectionSizer()",
    "llvm::objcopy::elf::ELFSectionSizer<llvm::object::ELFType<(llvm::endianness)0, true>>::~ELFSectionSizer",
  ),
  (
    "_ZN2v88internal8compiler29SimplifiedOperatorGlobalCache33ChangeTaggedSignedToInt32OperatorD0Ev",
    "v8::internal::compiler::SimplifiedOperatorGlobalCache::ChangeTaggedSignedToInt32Operator::~ChangeTaggedSignedToInt32Operator()",
    "v8::internal::compiler::SimplifiedOperatorGlobalCache::ChangeTaggedSignedToInt32Operator::~ChangeTaggedSignedToInt32Operator",
  ),
  (
    "_ZN12_GLOBAL__N_130LinalgSpecializeGenericOpsPass14runOnOperationEv", "(anonymous namespace)::LinalgSpecializeGenericOpsPass::runOnOperation()",
    "(anonymous namespace)::LinalgSpecializeGenericOpsPass::runOnOperation",
  ),
  (
    "_ZNK16FormWidgetChoice9getChoiceEi", "FormWidgetChoice::getChoice(int) const",
    "FormWidgetChoice::getChoice",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5spirv19VectorTimesMatrixOpEE8hasTraitENS_6TypeIDE",
    "mlir::RegisteredOperationName::Model<mlir::spirv::VectorTimesMatrixOp>::hasTrait(mlir::TypeID)",
    "mlir::RegisteredOperationName::Model<mlir::spirv::VectorTimesMatrixOp>::hasTrait",
  ),
  (
    "_ZN21GfxICCBasedColorSpace14getDeviceNLineEPhS0_i.cold.1", "GfxICCBasedColorSpace::getDeviceNLine(unsigned char*, unsigned char*, int) (.cold.1)",
    "GfxICCBasedColorSpace::getDeviceNLine",
  ),
  (
    "_ZN7Imf_3_417apertureAttributeERNS_6HeaderE", "Imf_3_4::apertureAttribute(Imf_3_4::Header&)",
    "Imf_3_4::apertureAttribute",
  ),
  (
    "_ZN15node_napi_env__23trigger_fatal_exceptionEN2v85LocalINS0_5ValueEEE", "node_napi_env__::trigger_fatal_exception(v8::Local<v8::Value>)",
    "node_napi_env__::trigger_fatal_exception",
  ),
  (
    "_ZNK4llvm16AArch64InstrInfo20isAccumulationOpcodeEj", "llvm::AArch64InstrInfo::isAccumulationOpcode(unsigned int) const",
    "llvm::AArch64InstrInfo::isAccumulationOpcode",
  ),
  (
    "_ZNSt3__110__function6__funcIZNK3sls7bv_eval8bval1_bvEP3appE3$_6FbiEE7destroyEv",
    "std::__1::__function::__func<sls::bv_eval::bval1_bv(app*) const::$_6, bool (int)>::destroy()",
    "std::__1::__function::__func<sls::bv_eval::bval1_bv(app*) const::$_6, bool (int)>::destroy",
  ),
  (
    "_ZTVN4mlir23RegisteredOperationName5ModelINS_4LLVM10VPFPToUIOpEEE", "vtable for mlir::RegisteredOperationName::Model<mlir::LLVM::VPFPToUIOp>",
    "vtable for mlir::RegisteredOperationName::Model<mlir::LLVM::VPFPToUIOp>",
  ),
  (
    "_ZNSt3__110__function6__funcIZN4mlir22CyclicAttrTypeReplacerC1EvE3$_0FNS_8optionalIPKvEEPvEED1Ev",
    "std::__1::__function::__func<mlir::CyclicAttrTypeReplacer::CyclicAttrTypeReplacer()::$_0, std::__1::optional<void const*> (void*)>::~__func()",
    "std::__1::__function::__func<mlir::CyclicAttrTypeReplacer::CyclicAttrTypeReplacer()::$_0, std::__1::optional<void const*> (void*)>::~__func",
  ),
  (
    "_ZN4llvm7support6detail23provider_format_adapterIRN12lldb_private11ConstStringEED1Ev",
    "llvm::support::detail::provider_format_adapter<lldb_private::ConstString&>::~provider_format_adapter()",
    "llvm::support::detail::provider_format_adapter<lldb_private::ConstString&>::~provider_format_adapter",
  ),
  (
    "_ZN5clang7CodeGen11CGBuilderTy18CreateMemCpyInlineENS0_7AddressES2_y", "clang::CodeGen::CGBuilderTy::CreateMemCpyInline(clang::CodeGen::Address, clang::CodeGen::Address, unsigned long long)",
    "clang::CodeGen::CGBuilderTy::CreateMemCpyInline",
  ),
  (
    "_ZNK12_GLOBAL__N_124HexagonEarlyIfConversion14computePhiCostEPKN4llvm17MachineBasicBlockERKNS_11FlowPatternE",
    "(anonymous namespace)::HexagonEarlyIfConversion::computePhiCost(llvm::MachineBasicBlock const*, (anonymous namespace)::FlowPattern const&) const",
    "(anonymous namespace)::HexagonEarlyIfConversion::computePhiCost",
  ),
  (
    "_ZN5clang13AllocSizeAttr14CreateImplicitERNS_10ASTContextENS_8ParamIdxES3_NS_11SourceRangeENS0_8SpellingE",
    "clang::AllocSizeAttr::CreateImplicit(clang::ASTContext&, clang::ParamIdx, clang::ParamIdx, clang::SourceRange, clang::AllocSizeAttr::Spelling)",
    "clang::AllocSizeAttr::CreateImplicit",
  ),
  (
    "_ZTVN12_GLOBAL__N_119MmaLdMatrixOpToNVVME", "vtable for (anonymous namespace)::MmaLdMatrixOpToNVVM",
    "vtable for (anonymous namespace)::MmaLdMatrixOpToNVVM",
  ),
  (
    "_ZN7Iex_3_48EcommExcC2EPKc", "Iex_3_4::EcommExc::EcommExc(char const*)", "Iex_3_4::EcommExc::EcommExc",
  ),
  (
    "_ZTSN12_GLOBAL__N_126AArch64InstructionSelectorE", "typeinfo name for (anonymous namespace)::AArch64InstructionSelector",
    "typeinfo name for (anonymous namespace)::AArch64InstructionSelector",
  ),
  (
    "_ZN4mlir4NVVM28MBarrierArriveDropExpectTxOp5printERNS_12OpAsmPrinterE", "mlir::NVVM::MBarrierArriveDropExpectTxOp::print(mlir::OpAsmPrinter&)",
    "mlir::NVVM::MBarrierArriveDropExpectTxOp::print",
  ),
  (
    "_ZN2v88internal10ZoneVectorINS0_8compiler10turboshaft7OpIndexEEC2EmPNS0_4ZoneE",
    "v8::internal::ZoneVector<v8::internal::compiler::turboshaft::OpIndex>::ZoneVector(unsigned long, v8::internal::Zone*)",
    "v8::internal::ZoneVector<v8::internal::compiler::turboshaft::OpIndex>::ZoneVector",
  ),
  (
    "_ZN4mlir4LLVM14VPReduceSMinOp20verifyInvariantsImplEv", "mlir::LLVM::VPReduceSMinOp::verifyInvariantsImpl()",
    "mlir::LLVM::VPReduceSMinOp::verifyInvariantsImpl",
  ),
  (
    "_ZN4llvm9symbolize12MarkupFilter6trySGRERKNS0_10MarkupNodeE", "llvm::symbolize::MarkupFilter::trySGR(llvm::symbolize::MarkupNode const&)",
    "llvm::symbolize::MarkupFilter::trySGR",
  ),
  (
    "_ZN12_GLOBAL__N_128LTOVisibilityPublicSpellingsE", "(anonymous namespace)::LTOVisibilityPublicSpellings",
    "(anonymous namespace)::LTOVisibilityPublicSpellings",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_9transform18RewriteCopyAsTmaOpEE18getParseAssemblyFnEv",
    "mlir::RegisteredOperationName::Model<mlir::transform::RewriteCopyAsTmaOp>::getParseAssemblyFn()",
    "mlir::RegisteredOperationName::Model<mlir::transform::RewriteCopyAsTmaOp>::getParseAssemblyFn",
  ),
  (
    "_ZN4llvm34createMVEGatherScatterLoweringPassEv", "llvm::createMVEGatherScatterLoweringPass()",
    "llvm::createMVEGatherScatterLoweringPass",
  ),
  (
    "_ZN2v88internal11FrameWriter13PushRawObjectENS0_6TaggedINS0_6ObjectEEEPKc",
    "v8::internal::FrameWriter::PushRawObject(v8::internal::Tagged<v8::internal::Object>, char const*)",
    "v8::internal::FrameWriter::PushRawObject",
  ),
  (
    "_ZNK4llvm16MipsRegisterInfo16getFrameRegisterERKNS_15MachineFunctionE", "llvm::MipsRegisterInfo::getFrameRegister(llvm::MachineFunction const&) const",
    "llvm::MipsRegisterInfo::getFrameRegister",
  ),
  (
    "_ZTSN5clang24PragmaDetectMismatchDeclE", "typeinfo name for clang::PragmaDetectMismatchDecl",
    "typeinfo name for clang::PragmaDetectMismatchDecl",
  ),
  (
    "_ZN5clang16OMPClausePrinter20VisitOMPUpdateClauseEPNS_15OMPUpdateClauseE", "clang::OMPClausePrinter::VisitOMPUpdateClause(clang::OMPUpdateClause*)",
    "clang::OMPClausePrinter::VisitOMPUpdateClause",
  ),
  (
    "_ZN5clang20SYCLSpecialClassAttr14CreateImplicitERNS_10ASTContextENS_11SourceRangeENS0_8SpellingE",
    "clang::SYCLSpecialClassAttr::CreateImplicit(clang::ASTContext&, clang::SourceRange, clang::SYCLSpecialClassAttr::Spelling)",
    "clang::SYCLSpecialClassAttr::CreateImplicit",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5spirv8GLFMaxOpEED0Ev", "mlir::RegisteredOperationName::Model<mlir::spirv::GLFMaxOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::spirv::GLFMaxOp>::~Model",
  ),
  (
    "_ZNK7ncrypto13BignumPointer6isZeroEv", "ncrypto::BignumPointer::isZero() const",
    "ncrypto::BignumPointer::isZero",
  ),
  (
    "_ZN2v88internal13ThreadManagerD2Ev", "v8::internal::ThreadManager::~ThreadManager()",
    "v8::internal::ThreadManager::~ThreadManager",
  ),
  (
    "_ZNK4llvm6object13ELFObjectFileINS0_7ELFTypeILNS_10endiannessE1ELb1EEEE11getEMachineEv",
    "llvm::object::ELFObjectFile<llvm::object::ELFType<(llvm::endianness)1, true>>::getEMachine() const",
    "llvm::object::ELFObjectFile<llvm::object::ELFType<(llvm::endianness)1, true>>::getEMachine",
  ),
  (
    "_ZN2v88internal13EhFrameWriter19RegisterToDwarfCodeENS0_8RegisterE", "v8::internal::EhFrameWriter::RegisterToDwarfCode(v8::internal::Register)",
    "v8::internal::EhFrameWriter::RegisterToDwarfCode",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_6vector12ExpandLoadOpEE8hasTraitENS_6TypeIDE",
    "mlir::RegisteredOperationName::Model<mlir::vector::ExpandLoadOp>::hasTrait(mlir::TypeID)",
    "mlir::RegisteredOperationName::Model<mlir::vector::ExpandLoadOp>::hasTrait",
  ),
  (
    "_ZTSN5clang12ast_matchers8internal21matcher_isEnumMatcherE", "typeinfo name for clang::ast_matchers::internal::matcher_isEnumMatcher",
    "typeinfo name for clang::ast_matchers::internal::matcher_isEnumMatcher",
  ),
  (
    "_ZNK4llvm19TargetFrameLowering16canUseAsPrologueERKNS_17MachineBasicBlockE",
    "llvm::TargetFrameLowering::canUseAsPrologue(llvm::MachineBasicBlock const&) const",
    "llvm::TargetFrameLowering::canUseAsPrologue",
  ),
  (
    "_ZTIN12_GLOBAL__N_127AANoFPClassCallSiteReturnedE", "typeinfo for (anonymous namespace)::AANoFPClassCallSiteReturned",
    "typeinfo for (anonymous namespace)::AANoFPClassCallSiteReturned",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5ROCDL31wmma_scale_f32_16x16x128_f8f6f4EED0Ev",
    "mlir::RegisteredOperationName::Model<mlir::ROCDL::wmma_scale_f32_16x16x128_f8f6f4>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::ROCDL::wmma_scale_f32_16x16x128_f8f6f4>::~Model",
  ),
  (
    "_ZTIN5clang12ast_matchers8internal16HasParentMatcherINS_4StmtES3_EE", "typeinfo for clang::ast_matchers::internal::HasParentMatcher<clang::Stmt, clang::Stmt>",
    "typeinfo for clang::ast_matchers::internal::HasParentMatcher<clang::Stmt, clang::Stmt>",
  ),
  (
    "_ZN4core9panicking13assert_failed17h08f284a6b18b8f47E", "core::panicking::assert_failed::h08f284a6b18b8f47",
    "core::panicking::assert_failed::h08f284a6b18b8f47",
  ),
  (
    "_ZN8seq_util3rex10mk_epsilonEP4sort", "seq_util::rex::mk_epsilon(sort*)", "seq_util::rex::mk_epsilon",
  ),
  (
    "_ZN4llvm2cl3optINS_5Reloc5ModelELb0ENS0_6parserIS3_EEE10setDefaultEv", "llvm::cl::opt<llvm::Reloc::Model, false, llvm::cl::parser<llvm::Reloc::Model>>::setDefault()",
    "llvm::cl::opt<llvm::Reloc::Model, false, llvm::cl::parser<llvm::Reloc::Model>>::setDefault",
  ),
  (
    "_ZN3smt12theory_arithINS_5i_extEE9get_valueEPNS_5enodeER7obj_refI4expr11ast_managerE",
    "smt::theory_arith<smt::i_ext>::get_value(smt::enode*, obj_ref<expr, ast_manager>&)",
    "smt::theory_arith<smt::i_ext>::get_value",
  ),
  (
    "_ZN4llvm11SlotTracker13processModuleEv", "llvm::SlotTracker::processModule()",
    "llvm::SlotTracker::processModule",
  ),
  (
    "_ZN4mlir5spirv25GroupNonUniformQuadSwapOp13getMinVersionEv", "mlir::spirv::GroupNonUniformQuadSwapOp::getMinVersion()",
    "mlir::spirv::GroupNonUniformQuadSwapOp::getMinVersion",
  ),
  (
    "_ZNK7simdutf8internal26unsupported_implementation21convert_utf32_to_utf8EPKDimPc",
    "simdutf::internal::unsupported_implementation::convert_utf32_to_utf8(char32_t const*, unsigned long, char*) const",
    "simdutf::internal::unsupported_implementation::convert_utf32_to_utf8",
  ),
  (
    "_ZTIN4mlir4tosa6detail27QueryProfileInterfaceTraits5ModelINS0_19LogicalRightShiftOpEEE",
    "typeinfo for mlir::tosa::detail::QueryProfileInterfaceTraits::Model<mlir::tosa::LogicalRightShiftOp>",
    "typeinfo for mlir::tosa::detail::QueryProfileInterfaceTraits::Model<mlir::tosa::LogicalRightShiftOp>",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5spirv9GLAcoshOpEE14hashPropertiesENS_16OpaquePropertiesE",
    "mlir::RegisteredOperationName::Model<mlir::spirv::GLAcoshOp>::hashProperties(mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::spirv::GLAcoshOp>::hashProperties",
  ),
  (
    "_ZN4mlir5shape13CstrRequireOp6createERNS_9OpBuilderENS_8LocationENS_5ValueEN4llvm9StringRefE",
    "mlir::shape::CstrRequireOp::create(mlir::OpBuilder&, mlir::Location, mlir::Value, llvm::StringRef)",
    "mlir::shape::CstrRequireOp::create",
  ),
  (
    "_ZN5clang12InitListExpr12reserveInitsERKNS_10ASTContextEj", "clang::InitListExpr::reserveInits(clang::ASTContext const&, unsigned int)",
    "clang::InitListExpr::reserveInits",
  ),
  (
    "_ZN4mlir5shape12AnyOpAdaptor6verifyENS_8LocationE", "mlir::shape::AnyOpAdaptor::verify(mlir::Location)",
    "mlir::shape::AnyOpAdaptor::verify",
  ),
  (
    "_ZN4llvm13MDNodeKeyImplINS_16DIGlobalVariableEEC2EPKS1_", "llvm::MDNodeKeyImpl<llvm::DIGlobalVariable>::MDNodeKeyImpl(llvm::DIGlobalVariable const*)",
    "llvm::MDNodeKeyImpl<llvm::DIGlobalVariable>::MDNodeKeyImpl",
  ),
  (
    "_ZTSN4mlir4impl32ArithToAPFloatConversionPassBaseIN12_GLOBAL__N_128ArithToAPFloatConversionPassEEE",
    "typeinfo name for mlir::impl::ArithToAPFloatConversionPassBase<(anonymous namespace)::ArithToAPFloatConversionPass>",
    "typeinfo name for mlir::impl::ArithToAPFloatConversionPassBase<(anonymous namespace)::ArithToAPFloatConversionPass>",
  ),
  (
    "_ZN4mlir4LLVM8CoroIdOp5buildERNS_9OpBuilderERNS_14OperationStateENS_4TypeENS_5ValueES7_S7_S7_",
    "mlir::LLVM::CoroIdOp::build(mlir::OpBuilder&, mlir::OperationState&, mlir::Type, mlir::Value, mlir::Value, mlir::Value, mlir::Value)",
    "mlir::LLVM::CoroIdOp::build",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_178AV_384_with_sub1_sub2_in_AV_64_Align2_and_AV_64_with_hi16_in_VGPR_16_Lo128BitsE",
    "llvm::(anonymous namespace)::AV_384_with_sub1_sub2_in_AV_64_Align2_and_AV_64_with_hi16_in_VGPR_16_Lo128Bits",
    "llvm::(anonymous namespace)::AV_384_with_sub1_sub2_in_AV_64_Align2_and_AV_64_with_hi16_in_VGPR_16_Lo128Bits",
  ),
  (
    "_ZN4llvm9DwarfUnit16constructTypeDIEERNS_3DIEEPKNS_16DIFixedPointTypeE", "llvm::DwarfUnit::constructTypeDIE(llvm::DIE&, llvm::DIFixedPointType const*)",
    "llvm::DwarfUnit::constructTypeDIE",
  ),
  (
    "_ZNK23IsOpToAPFloatConversionIN4mlir4math10IsFiniteOpEE15matchAndRewriteES2_RNS0_15PatternRewriterE",
    "IsOpToAPFloatConversion<mlir::math::IsFiniteOp>::matchAndRewrite(mlir::math::IsFiniteOp, mlir::PatternRewriter&) const",
    "IsOpToAPFloatConversion<mlir::math::IsFiniteOp>::matchAndRewrite",
  ),
  (
    "_ZN2lp15lar_core_solverD2Ev", "lp::lar_core_solver::~lar_core_solver()", "lp::lar_core_solver::~lar_core_solver",
  ),
  (
    "_ZN4mlir4LLVM7VaArgOp21populateInherentAttrsEPNS_11MLIRContextERKNS_15EmptyPropertiesERNS_13NamedAttrListE",
    "mlir::LLVM::VaArgOp::populateInherentAttrs(mlir::MLIRContext*, mlir::EmptyProperties const&, mlir::NamedAttrList&)",
    "mlir::LLVM::VaArgOp::populateInherentAttrs",
  ),
  (
    "_ZNK12_GLOBAL__N_119ParsedAttrInfoError31spellingIndexToSemanticSpellingERKN5clang10ParsedAttrE",
    "(anonymous namespace)::ParsedAttrInfoError::spellingIndexToSemanticSpelling(clang::ParsedAttr const&) const",
    "(anonymous namespace)::ParsedAttrInfoError::spellingIndexToSemanticSpelling",
  ),
  (
    "_ZN5clang13ASTDeclReader30VisitUnnamedGlobalConstantDeclEPNS_25UnnamedGlobalConstantDeclE",
    "clang::ASTDeclReader::VisitUnnamedGlobalConstantDecl(clang::UnnamedGlobalConstantDecl*)",
    "clang::ASTDeclReader::VisitUnnamedGlobalConstantDecl",
  ),
  (
    "_ZNK2OT4MATH8sanitizeEP21hb_sanitize_context_t", "OT::MATH::sanitize(hb_sanitize_context_t*) const",
    "OT::MATH::sanitize",
  ),
  (
    "_ZNK12lldb_private6Thread23AutoCompleteThreadPlansERNS_17CompletionRequestE",
    "lldb_private::Thread::AutoCompleteThreadPlans(lldb_private::CompletionRequest&) const",
    "lldb_private::Thread::AutoCompleteThreadPlans",
  ),
  (
    "_ZTIN12_GLOBAL__N_19CGObjCGNUE", "typeinfo for (anonymous namespace)::CGObjCGNU",
    "typeinfo for (anonymous namespace)::CGObjCGNU",
  ),
  (
    "_ZN2v84base21PosixMemoryMappedFileD1Ev", "v8::base::PosixMemoryMappedFile::~PosixMemoryMappedFile()",
    "v8::base::PosixMemoryMappedFile::~PosixMemoryMappedFile",
  ),
  (
    "_ZN4mlir4NVVM6detail27EnvReg1OpGenericAdaptorBaseC2ENS0_9EnvReg1OpE", "mlir::NVVM::detail::EnvReg1OpGenericAdaptorBase::EnvReg1OpGenericAdaptorBase(mlir::NVVM::EnvReg1Op)",
    "mlir::NVVM::detail::EnvReg1OpGenericAdaptorBase::EnvReg1OpGenericAdaptorBase",
  ),
  (
    "_ZN4llvm15MLInlineAdvisorD0Ev", "llvm::MLInlineAdvisor::~MLInlineAdvisor()",
    "llvm::MLInlineAdvisor::~MLInlineAdvisor",
  ),
  (
    "_ZN13unicode_width6tables21EMOJI_MODIFIER_LEAF_717h70baaec8aed42e35E", "unicode_width::tables::EMOJI_MODIFIER_LEAF_7::h70baaec8aed42e35",
    "unicode_width::tables::EMOJI_MODIFIER_LEAF_7::h70baaec8aed42e35",
  ),
  (
    "_ZN4llvm15SmallVectorImplIPNS_11logicalview6LVLineEE6appendIPS3_vEEvT_S7_",
    "void llvm::SmallVectorImpl<llvm::logicalview::LVLine*>::append<llvm::logicalview::LVLine**, void>(llvm::logicalview::LVLine**, llvm::logicalview::LVLine**)",
    "llvm::SmallVectorImpl<llvm::logicalview::LVLine*>::append<llvm::logicalview::LVLine**, void>",
  ),
  ("_ZL12BugReportMsg", "BugReportMsg", "BugReportMsg"),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_10pdl_interp21SwitchOperationNameOpEE21getOpPropertyByteSizeEv",
    "mlir::RegisteredOperationName::Model<mlir::pdl_interp::SwitchOperationNameOp>::getOpPropertyByteSize()",
    "mlir::RegisteredOperationName::Model<mlir::pdl_interp::SwitchOperationNameOp>::getOpPropertyByteSize",
  ),
  (
    "_ZN4mlir7complex5CosOp16verifyInvariantsEv", "mlir::complex::CosOp::verifyInvariants()",
    "mlir::complex::CosOp::verifyInvariants",
  ),
  (
    "_ZN4llvmL41ZPR4_with_zsub1_in_ZPRMul2_LoSubClassMaskE", "llvm::ZPR4_with_zsub1_in_ZPRMul2_LoSubClassMask",
    "llvm::ZPR4_with_zsub1_in_ZPRMul2_LoSubClassMask",
  ),
  (
    "_ZNK4llvm17InstructionSelect16getAnalysisUsageERNS_13AnalysisUsageE", "llvm::InstructionSelect::getAnalysisUsage(llvm::AnalysisUsage&) const",
    "llvm::InstructionSelect::getAnalysisUsage",
  ),
  (
    "_ZNK4node6crypto9CryptoJobINS0_15RSACipherTraitsEE14MemoryInfoNameEv", "node::crypto::CryptoJob<node::crypto::RSACipherTraits>::MemoryInfoName() const",
    "node::crypto::CryptoJob<node::crypto::RSACipherTraits>::MemoryInfoName",
  ),
  (
    "_ZN2v88internal15MemoryAllocator28UnregisterMutableMemoryChunkEPNS0_19MutablePageMetadataE",
    "v8::internal::MemoryAllocator::UnregisterMutableMemoryChunk(v8::internal::MutablePageMetadata*)",
    "v8::internal::MemoryAllocator::UnregisterMutableMemoryChunk",
  ),
  (
    "_ZN12lldb_private16PlatformQemuUser13GetPluginNameEv", "lldb_private::PlatformQemuUser::GetPluginName()",
    "lldb_private::PlatformQemuUser::GetPluginName",
  ),
  (
    "_ZN5clang30DynamicRecursiveASTVisitorBaseILb0EE27WalkUpFromObjCInterfaceDeclEPNS_17ObjCInterfaceDeclE",
    "clang::DynamicRecursiveASTVisitorBase<false>::WalkUpFromObjCInterfaceDecl(clang::ObjCInterfaceDecl*)",
    "clang::DynamicRecursiveASTVisitorBase<false>::WalkUpFromObjCInterfaceDecl",
  ),
  (
    "_ZN11hb_vector_tIN2OT3SVG16svg_defs_entry_tELb0EE5allocEjb", "hb_vector_t<OT::SVG::svg_defs_entry_t, false>::alloc(unsigned int, bool)",
    "hb_vector_t<OT::SVG::svg_defs_entry_t, false>::alloc",
  ),
  (
    "_ZN2v85Value9CheckCastEPNS_4DataE", "v8::Value::CheckCast(v8::Data*)", "v8::Value::CheckCast",
  ),
  (
    "_ZNK4mlir5shard12ShardingType5printERNS_10AsmPrinterE", "mlir::shard::ShardingType::print(mlir::AsmPrinter&) const",
    "mlir::shard::ShardingType::print",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4LLVM9LoadExpOpEE8hasTraitENS_6TypeIDE",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::LoadExpOp>::hasTrait(mlir::TypeID)",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::LoadExpOp>::hasTrait",
  ),
  (
    "_ZN4node6crypto4Kmac10InitializeEPNS_11EnvironmentEN2v85LocalINS4_6ObjectEEE",
    "node::crypto::Kmac::Initialize(node::Environment*, v8::Local<v8::Object>)",
    "node::crypto::Kmac::Initialize",
  ),
  (
    "_ZNK7simdutf8internal26unsupported_implementation27convert_valid_utf32_to_utf8EPKDimPc",
    "simdutf::internal::unsupported_implementation::convert_valid_utf32_to_utf8(char32_t const*, unsigned long, char*) const",
    "simdutf::internal::unsupported_implementation::convert_valid_utf32_to_utf8",
  ),
  (
    "_ZTVN5clang6driver19ExtractAPIJobActionE", "vtable for clang::driver::ExtractAPIJobAction",
    "vtable for clang::driver::ExtractAPIJobAction",
  ),
  (
    "_ZN4llvm15callDefaultCtorIN12_GLOBAL__N_119FixFunctionBitcastsEEEPNS_4PassEv",
    "llvm::Pass* llvm::callDefaultCtor<(anonymous namespace)::FixFunctionBitcasts>()",
    "llvm::callDefaultCtor<(anonymous namespace)::FixFunctionBitcasts>",
  ),
  (
    "_ZN4llvmL45AV_320_with_sub9_in_VGPR_32_Lo256SubClassMaskE", "llvm::AV_320_with_sub9_in_VGPR_32_Lo256SubClassMask",
    "llvm::AV_320_with_sub9_in_VGPR_32_Lo256SubClassMask",
  ),
  (
    "_ZNK4llvm18MipsTargetLowering14lowerEH_RETURNENS_7SDValueERNS_12SelectionDAGE",
    "llvm::MipsTargetLowering::lowerEH_RETURN(llvm::SDValue, llvm::SelectionDAG&) const",
    "llvm::MipsTargetLowering::lowerEH_RETURN",
  ),
  (
    "_ZN4llvm3rdf12RegisterAggr12ref_iteratorC2ERKS1_b", "llvm::rdf::RegisterAggr::ref_iterator::ref_iterator(llvm::rdf::RegisterAggr const&, bool)",
    "llvm::rdf::RegisterAggr::ref_iterator::ref_iterator",
  ),
  (
    "_ZN4mlir3acc24FirstprivateMapInitialOp16getBoundsMutableEv", "mlir::acc::FirstprivateMapInitialOp::getBoundsMutable()",
    "mlir::acc::FirstprivateMapInitialOp::getBoundsMutable",
  ),
  (
    "_ZN4node12wasm_web_api19WasmStreamingObject3NewERKN2v820FunctionCallbackInfoINS2_5ValueEEE.cold.1",
    "node::wasm_web_api::WasmStreamingObject::New(v8::FunctionCallbackInfo<v8::Value> const&) (.cold.1)",
    "node::wasm_web_api::WasmStreamingObject::New",
  ),
  (
    "_ZN4llvm3sys17InitializeCOMRAIID1Ev", "llvm::sys::InitializeCOMRAII::~InitializeCOMRAII()",
    "llvm::sys::InitializeCOMRAII::~InitializeCOMRAII",
  ),
  (
    "_ZN2v88internal6maglev17CheckValueInputIsEPKNS1_8NodeBaseEiNS1_19ValueRepresentationE",
    "v8::internal::maglev::CheckValueInputIs(v8::internal::maglev::NodeBase const*, int, v8::internal::maglev::ValueRepresentation)",
    "v8::internal::maglev::CheckValueInputIs",
  ),
  (
    "_ZNK4llvm2cl3optINS_10IR2VecKindELb0ENS0_6parserIS2_EEE27getValueExpectedFlagDefaultEv",
    "llvm::cl::opt<llvm::IR2VecKind, false, llvm::cl::parser<llvm::IR2VecKind>>::getValueExpectedFlagDefault() const",
    "llvm::cl::opt<llvm::IR2VecKind, false, llvm::cl::parser<llvm::IR2VecKind>>::getValueExpectedFlagDefault",
  ),
  (
    "_ZN4mlir5spirv6detail30QueryCapabilityInterfaceTraits5ModelINS0_11GroupSMaxOpEED0Ev",
    "mlir::spirv::detail::QueryCapabilityInterfaceTraits::Model<mlir::spirv::GroupSMaxOp>::~Model()",
    "mlir::spirv::detail::QueryCapabilityInterfaceTraits::Model<mlir::spirv::GroupSMaxOp>::~Model",
  ),
  (
    "_ZN2v88internal8compiler7JSGraph17ConstantMaybeHoleENS0_7Float64E", "v8::internal::compiler::JSGraph::ConstantMaybeHole(v8::internal::Float64)",
    "v8::internal::compiler::JSGraph::ConstantMaybeHole",
  ),
  (
    "_ZN4llvm15ARMGenInstrInfoC2ERKNS_19TargetSubtargetInfoERKNS_18TargetRegisterInfoEjjjj",
    "llvm::ARMGenInstrInfo::ARMGenInstrInfo(llvm::TargetSubtargetInfo const&, llvm::TargetRegisterInfo const&, unsigned int, unsigned int, unsigned int, unsigned int)",
    "llvm::ARMGenInstrInfo::ARMGenInstrInfo",
  ),
  (
    "_ZNSt3__120__shared_ptr_emplaceIN4node6worker12SiblingGroupENS_9allocatorIS3_EEE21__on_zero_shared_weakEv",
    "std::__1::__shared_ptr_emplace<node::worker::SiblingGroup, std::__1::allocator<node::worker::SiblingGroup>>::__on_zero_shared_weak()",
    "std::__1::__shared_ptr_emplace<node::worker::SiblingGroup, std::__1::allocator<node::worker::SiblingGroup>>::__on_zero_shared_weak",
  ),
  (
    "_ZN2v88internal8compiler26MachineOperatorGlobalCache16Word64OrOperatorD1Ev",
    "v8::internal::compiler::MachineOperatorGlobalCache::Word64OrOperator::~Word64OrOperator()",
    "v8::internal::compiler::MachineOperatorGlobalCache::Word64OrOperator::~Word64OrOperator",
  ),
  (
    "_ZTVN12_GLOBAL__N_120AMDGPUCodeGenPrepareE", "vtable for (anonymous namespace)::AMDGPUCodeGenPrepare",
    "vtable for (anonymous namespace)::AMDGPUCodeGenPrepare",
  ),
  (
    "_ZTVN4mlir23RegisteredOperationName5ModelINS_5spirv15GLInverseSqrtOpEEE", "vtable for mlir::RegisteredOperationName::Model<mlir::spirv::GLInverseSqrtOp>",
    "vtable for mlir::RegisteredOperationName::Model<mlir::spirv::GLInverseSqrtOp>",
  ),
  (
    "_ZTSN12_GLOBAL__N_124SimplifyAffineStructuresE", "typeinfo name for (anonymous namespace)::SimplifyAffineStructures",
    "typeinfo name for (anonymous namespace)::SimplifyAffineStructures",
  ),
  ("_ZL16DisableX86LEAOpt", "DisableX86LEAOpt", "DisableX86LEAOpt"),
  (
    "_ZN3smt15or_relevancy_ehD0Ev", "smt::or_relevancy_eh::~or_relevancy_eh()", "smt::or_relevancy_eh::~or_relevancy_eh",
  ),
  (
    "_ZTSN12_GLOBAL__N_112DropUnitDimsE", "typeinfo name for (anonymous namespace)::DropUnitDims",
    "typeinfo name for (anonymous namespace)::DropUnitDims",
  ),
  (
    "_ZN2v88internal6maglev18MaglevGraphBuilder21VisitGetNamedPropertyEv", "v8::internal::maglev::MaglevGraphBuilder::VisitGetNamedProperty()",
    "v8::internal::maglev::MaglevGraphBuilder::VisitGetNamedProperty",
  ),
  (
    "_ZN12_GLOBAL__N_111StmtPrinter23VisitCUDAKernelCallExprEPN5clang18CUDAKernelCallExprE",
    "(anonymous namespace)::StmtPrinter::VisitCUDAKernelCallExpr(clang::CUDAKernelCallExpr*)",
    "(anonymous namespace)::StmtPrinter::VisitCUDAKernelCallExpr",
  ),
  (
    "_ZL44InitializeAArch64ConditionalComparesPassFlag", "InitializeAArch64ConditionalComparesPassFlag",
    "InitializeAArch64ConditionalComparesPassFlag",
  ),
  (
    "_ZNK4node15TimerWrapHandle10MemoryInfoEPNS_13MemoryTrackerE", "node::TimerWrapHandle::MemoryInfo(node::MemoryTracker*) const",
    "node::TimerWrapHandle::MemoryInfo",
  ),
  (
    "_ZN4llvm25PerFunctionMIParsingState11getVRegInfoENS_8RegisterE", "llvm::PerFunctionMIParsingState::getVRegInfo(llvm::Register)",
    "llvm::PerFunctionMIParsingState::getVRegInfo",
  ),
  (
    "_ZNK12_GLOBAL__N_110DSAStackTy21getDefaultDSALocationEv", "(anonymous namespace)::DSAStackTy::getDefaultDSALocation() const",
    "(anonymous namespace)::DSAStackTy::getDefaultDSALocation",
  ),
  (
    "_ZN5clang30DynamicRecursiveASTVisitorBaseILb0EE20VisitTypedefNameDeclEPNS_15TypedefNameDeclE",
    "clang::DynamicRecursiveASTVisitorBase<false>::VisitTypedefNameDecl(clang::TypedefNameDecl*)",
    "clang::DynamicRecursiveASTVisitorBase<false>::VisitTypedefNameDecl",
  ),
  (
    "_ZTIN12_GLOBAL__N_120ARMTargetCodeGenInfoE", "typeinfo for (anonymous namespace)::ARMTargetCodeGenInfo",
    "typeinfo for (anonymous namespace)::ARMTargetCodeGenInfo",
  ),
  (
    "_ZN4mlir4LLVM7FPExtOp20verifyInvariantsImplEv", "mlir::LLVM::FPExtOp::verifyInvariantsImpl()",
    "mlir::LLVM::FPExtOp::verifyInvariantsImpl",
  ),
  (
    "_ZNK5clang20HLSLVkConstantIdAttr5cloneERNS_10ASTContextE", "clang::HLSLVkConstantIdAttr::clone(clang::ASTContext&) const",
    "clang::HLSLVkConstantIdAttr::clone",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5shard7ShiftOpEED0Ev", "mlir::RegisteredOperationName::Model<mlir::shard::ShiftOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::shard::ShiftOp>::~Model",
  ),
  (
    "_ZTVN4llvm30BasicBlockMatchingAndInferenceE", "vtable for llvm::BasicBlockMatchingAndInference",
    "vtable for llvm::BasicBlockMatchingAndInference",
  ),
  (
    "_ZNK12_GLOBAL__N_117RISCVLoadStoreOpt11getPassNameEv", "(anonymous namespace)::RISCVLoadStoreOpt::getPassName() const",
    "(anonymous namespace)::RISCVLoadStoreOpt::getPassName",
  ),
  (
    "_ZN2v88internal47Builtin_CallSitePrototypeGetEnclosingLineNumberEiPmPNS0_7IsolateE",
    "v8::internal::Builtin_CallSitePrototypeGetEnclosingLineNumber(int, unsigned long*, v8::internal::Isolate*)",
    "v8::internal::Builtin_CallSitePrototypeGetEnclosingLineNumber",
  ),
  (
    "_ZZL18setCMSErrorHandlervE9installed", "setCMSErrorHandler()::installed", "setCMSErrorHandler()::installed",
  ),
  (
    "_ZN4lldb20SBTypeMemberFunctionC2Ev", "lldb::SBTypeMemberFunction::SBTypeMemberFunction()",
    "lldb::SBTypeMemberFunction::SBTypeMemberFunction",
  ),
  (
    "_ZTIN12_GLOBAL__N_120SIFoldOperandsLegacyE", "typeinfo for (anonymous namespace)::SIFoldOperandsLegacy",
    "typeinfo for (anonymous namespace)::SIFoldOperandsLegacy",
  ),
  (
    "_ZTIZN4llvm13DWARFVerifier22verifyNameIndexAbbrevsERKNS_15DWARFDebugNames9NameIndexEE3$_2",
    "typeinfo for llvm::DWARFVerifier::verifyNameIndexAbbrevs(llvm::DWARFDebugNames::NameIndex const&)::$_2",
    "typeinfo for llvm::DWARFVerifier::verifyNameIndexAbbrevs(llvm::DWARFDebugNames::NameIndex const&)::$_2",
  ),
  (
    "_ZTIN4llvm6detail9PassModelINS_8FunctionENS_15MemProfilerPassENS_15AnalysisManagerIS2_JEEEJEEE",
    "typeinfo for llvm::detail::PassModel<llvm::Function, llvm::MemProfilerPass, llvm::AnalysisManager<llvm::Function>>",
    "typeinfo for llvm::detail::PassModel<llvm::Function, llvm::MemProfilerPass, llvm::AnalysisManager<llvm::Function>>",
  ),
  (
    "_ZNK12v8_inspector19V8DebuggerAgentImpl12acceptsPauseEb", "v8_inspector::V8DebuggerAgentImpl::acceptsPause(bool) const",
    "v8_inspector::V8DebuggerAgentImpl::acceptsPause",
  ),
  (
    "_ZTIN5clang4ento5check11LiveSymbolsE", "typeinfo for clang::ento::check::LiveSymbols",
    "typeinfo for clang::ento::check::LiveSymbols",
  ),
  (
    "_ZTIN4mlir23RegisteredOperationName5ModelINS_4NVVM20ConvertF8x2ToF16x2OpEEE",
    "typeinfo for mlir::RegisteredOperationName::Model<mlir::NVVM::ConvertF8x2ToF16x2Op>",
    "typeinfo for mlir::RegisteredOperationName::Model<mlir::NVVM::ConvertF8x2ToF16x2Op>",
  ),
  (
    "_ZN4mlir4NVVM9PermuteOp6createERNS_9OpBuilderENS_8LocationENS_4TypeENS_5ValueES6_S6_NS0_11PermuteModeE",
    "mlir::NVVM::PermuteOp::create(mlir::OpBuilder&, mlir::Location, mlir::Type, mlir::Value, mlir::Value, mlir::Value, mlir::NVVM::PermuteMode)",
    "mlir::NVVM::PermuteOp::create",
  ),
  (
    "_ZN4mlir6detail14TypeIDResolverINS_4LLVM18vector_reduce_fmaxEvE2idE", "mlir::detail::TypeIDResolver<mlir::LLVM::vector_reduce_fmax, void>::id",
    "mlir::detail::TypeIDResolver<mlir::LLVM::vector_reduce_fmax, void>::id",
  ),
  (
    "_ZN2v88internal6maglev18MaglevGraphBuilder23VisitCreateCatchContextEv.cold.1",
    "v8::internal::maglev::MaglevGraphBuilder::VisitCreateCatchContext() (.cold.1)",
    "v8::internal::maglev::MaglevGraphBuilder::VisitCreateCatchContext",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4LLVM6CoshOpEE19getPropertiesAsAttrEPNS_9OperationE",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::CoshOp>::getPropertiesAsAttr(mlir::Operation*)",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::CoshOp>::getPropertiesAsAttr",
  ),
  (
    "_ZN3smt2mf10auf_solver4evalEP4exprb", "smt::mf::auf_solver::eval(expr*, bool)",
    "smt::mf::auf_solver::eval",
  ),
  (
    "_ZN4LIEF3ELF6Binary12patch_pltgotERKNS0_6SymbolEy", "LIEF::ELF::Binary::patch_pltgot(LIEF::ELF::Symbol const&, unsigned long long)",
    "LIEF::ELF::Binary::patch_pltgot",
  ),
  (
    "_ZNK4node14PrincipalRealm23source_map_cache_getterEv", "node::PrincipalRealm::source_map_cache_getter() const",
    "node::PrincipalRealm::source_map_cache_getter",
  ),
  ("_ZL18TypeTraitSpellings", "TypeTraitSpellings", "TypeTraitSpellings"),
  (
    "_ZN4mlir27barePtrFuncArgTypeConverterERKNS_17LLVMTypeConverterENS_4TypeERN4llvm15SmallVectorImplIS3_EE",
    "mlir::barePtrFuncArgTypeConverter(mlir::LLVMTypeConverter const&, mlir::Type, llvm::SmallVectorImpl<mlir::Type>&)",
    "mlir::barePtrFuncArgTypeConverter",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4tosa7SliceOpEE16deletePropertiesENS_16OpaquePropertiesE",
    "mlir::RegisteredOperationName::Model<mlir::tosa::SliceOp>::deleteProperties(mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::tosa::SliceOp>::deleteProperties",
  ),
  (
    "_ZNSt3__110__function6__funcIZN4llvm8parallel9TaskGroup5spawnENS_8functionIFvvEEEE3$_0S6_E7destroyEv",
    "std::__1::__function::__func<llvm::parallel::TaskGroup::spawn(std::__1::function<void ()>)::$_0, void ()>::destroy()",
    "std::__1::__function::__func<llvm::parallel::TaskGroup::spawn(std::__1::function<void ()>)::$_0, void ()>::destroy",
  ),
  (
    "_ZN12_GLOBAL__N_128ComplexOpToROCDLLibraryCallsIN4mlir7complex5LogOpENS1_11Float64TypeEED1Ev",
    "(anonymous namespace)::ComplexOpToROCDLLibraryCalls<mlir::complex::LogOp, mlir::Float64Type>::~ComplexOpToROCDLLibraryCalls()",
    "(anonymous namespace)::ComplexOpToROCDLLibraryCalls<mlir::complex::LogOp, mlir::Float64Type>::~ComplexOpToROCDLLibraryCalls",
  ),
  (
    "_ZN2v88internal17ExternalReference39wasm_switch_to_the_central_stack_for_jsEv",
    "v8::internal::ExternalReference::wasm_switch_to_the_central_stack_for_js()",
    "v8::internal::ExternalReference::wasm_switch_to_the_central_stack_for_js",
  ),
  (
    "_ZN4mlir5spirv15BranchOpAdaptorC2ENS0_8BranchOpE", "mlir::spirv::BranchOpAdaptor::BranchOpAdaptor(mlir::spirv::BranchOp)",
    "mlir::spirv::BranchOpAdaptor::BranchOpAdaptor",
  ),
  (
    "_ZN4mlir4NVVM16stringifyMMAKindENS0_7MMAKindE", "mlir::NVVM::stringifyMMAKind(mlir::NVVM::MMAKind)",
    "mlir::NVVM::stringifyMMAKind",
  ),
  (
    "_ZN5clang15PtGuardedByAttr6CreateERNS_10ASTContextEPNS_4ExprENS_11SourceRangeE",
    "clang::PtGuardedByAttr::Create(clang::ASTContext&, clang::Expr*, clang::SourceRange)",
    "clang::PtGuardedByAttr::Create",
  ),
  (
    "_ZN4mlir5spirv6detail29QueryExtensionInterfaceTraits5ModelINS0_27KHRCooperativeMatrixStoreOpEED0Ev",
    "mlir::spirv::detail::QueryExtensionInterfaceTraits::Model<mlir::spirv::KHRCooperativeMatrixStoreOp>::~Model()",
    "mlir::spirv::detail::QueryExtensionInterfaceTraits::Model<mlir::spirv::KHRCooperativeMatrixStoreOp>::~Model",
  ),
  (
    "_ZN2v88internal8compiler17JSGenericLowering36LowerJSGeneratorRestoreContextNoCellEPNS1_4NodeE",
    "v8::internal::compiler::JSGenericLowering::LowerJSGeneratorRestoreContextNoCell(v8::internal::compiler::Node*)",
    "v8::internal::compiler::JSGenericLowering::LowerJSGeneratorRestoreContextNoCell",
  ),
  (
    "_ZN12_GLOBAL__N_116NVVMAttachTargetD1Ev", "(anonymous namespace)::NVVMAttachTarget::~NVVMAttachTarget()",
    "(anonymous namespace)::NVVMAttachTarget::~NVVMAttachTarget",
  ),
  (
    "_ZN12_GLOBAL__N_121ConstructorMemcpyizer19emitAggregatedInitsEv", "(anonymous namespace)::ConstructorMemcpyizer::emitAggregatedInits()",
    "(anonymous namespace)::ConstructorMemcpyizer::emitAggregatedInits",
  ),
  (
    "_ZTVN4mlir23RegisteredOperationName5ModelINS_4LLVM6VPOrOpEEE", "vtable for mlir::RegisteredOperationName::Model<mlir::LLVM::VPOrOp>",
    "vtable for mlir::RegisteredOperationName::Model<mlir::LLVM::VPOrOp>",
  ),
  (
    "_ZN4LIEF5MachOlsERNSt3__113basic_ostreamIcNS1_11char_traitsIcEEEERKNS0_6SymbolE",
    "LIEF::MachO::operator<<(std::__1::basic_ostream<char, std::__1::char_traits<char>>&, LIEF::MachO::Symbol const&)",
    "LIEF::MachO::operator<<",
  ),
  (
    "_ZN4mlir4tileEN4llvm8ArrayRefINS_3scf5ForOpEEENS1_INS_5ValueEEES3_", "mlir::tile(llvm::ArrayRef<mlir::scf::ForOp>, llvm::ArrayRef<mlir::Value>, mlir::scf::ForOp)",
    "mlir::tile",
  ),
  (
    "_Z18mk_diff_neq_tacticR11ast_managerRK10params_ref", "mk_diff_neq_tactic(ast_manager&, params_ref const&)",
    "mk_diff_neq_tactic",
  ),
  (
    "_ZN2v88internal13ScannerStream3ForEPNS0_7IsolateENS0_6HandleINS0_6StringEEEii",
    "v8::internal::ScannerStream::For(v8::internal::Isolate*, v8::internal::Handle<v8::internal::String>, int, int)",
    "v8::internal::ScannerStream::For",
  ),
  (
    "_ZN4mlir7wasmssa25LabelBranchingOpInterface9getTargetEv", "mlir::wasmssa::LabelBranchingOpInterface::getTarget()",
    "mlir::wasmssa::LabelBranchingOpInterface::getTarget",
  ),
  (
    "_ZN5clang10extractapi14CXXFieldRecordD1Ev", "clang::extractapi::CXXFieldRecord::~CXXFieldRecord()",
    "clang::extractapi::CXXFieldRecord::~CXXFieldRecord",
  ),
  (
    "_ZN4mlir5spirv10SConvertOp5buildERNS_9OpBuilderERNS_14OperationStateENS_9TypeRangeENS_5ValueE",
    "mlir::spirv::SConvertOp::build(mlir::OpBuilder&, mlir::OperationState&, mlir::TypeRange, mlir::Value)",
    "mlir::spirv::SConvertOp::build",
  ),
  (
    "_ZN12_GLOBAL__N_115VectorLegalizer11ExpandSETCCEPN4llvm6SDNodeERNS1_15SmallVectorImplINS1_7SDValueEEE",
    "(anonymous namespace)::VectorLegalizer::ExpandSETCC(llvm::SDNode*, llvm::SmallVectorImpl<llvm::SDValue>&)",
    "(anonymous namespace)::VectorLegalizer::ExpandSETCC",
  ),
  (
    "_ZNK4llvm17PPCTargetLowering15LowerRETURNADDRENS_7SDValueERNS_12SelectionDAGE",
    "llvm::PPCTargetLowering::LowerRETURNADDR(llvm::SDValue, llvm::SelectionDAG&) const",
    "llvm::PPCTargetLowering::LowerRETURNADDR",
  ),
  (
    "_ZTVN4mlir23RegisteredOperationName5ModelINS_10pdl_interp15GetDefiningOpOpEEE",
    "vtable for mlir::RegisteredOperationName::Model<mlir::pdl_interp::GetDefiningOpOp>",
    "vtable for mlir::RegisteredOperationName::Model<mlir::pdl_interp::GetDefiningOpOp>",
  ),
  (
    "_ZZN4mlir5spirv15getCapabilitiesENS0_11ImageFormatEE4caps__23_", "mlir::spirv::getCapabilities(mlir::spirv::ImageFormat)::caps",
    "mlir::spirv::getCapabilities(mlir::spirv::ImageFormat)::caps",
  ),
  (
    "_ZTSN12_GLOBAL__N_116LinalgOpRewriterE", "typeinfo name for (anonymous namespace)::LinalgOpRewriter",
    "typeinfo name for (anonymous namespace)::LinalgOpRewriter",
  ),
  (
    "_ZN4LIEF5MachO7details26dyld_chained_ptr_generic6411pack_targetEy", "LIEF::MachO::details::dyld_chained_ptr_generic64::pack_target(unsigned long long)",
    "LIEF::MachO::details::dyld_chained_ptr_generic64::pack_target",
  ),
  (
    "_ZN4mlir7arm_sme26isTriviallyCloneableTileOpENS0_21ArmSMETileOpInterfaceE",
    "mlir::arm_sme::isTriviallyCloneableTileOp(mlir::arm_sme::ArmSMETileOpInterface)",
    "mlir::arm_sme::isTriviallyCloneableTileOp",
  ),
  (
    "_ZTIZN4llvm19AMDGPULegalizerInfoC1ERKNS_12GCNSubtargetERKNS_16GCNTargetMachineEE4$_23",
    "typeinfo for llvm::AMDGPULegalizerInfo::AMDGPULegalizerInfo(llvm::GCNSubtarget const&, llvm::GCNTargetMachine const&)::$_23",
    "typeinfo for llvm::AMDGPULegalizerInfo::AMDGPULegalizerInfo(llvm::GCNSubtarget const&, llvm::GCNTargetMachine const&)::$_23",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4LLVM14MemcpyInlineOpEED0Ev", "mlir::RegisteredOperationName::Model<mlir::LLVM::MemcpyInlineOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::MemcpyInlineOp>::~Model",
  ),
  (
    "_ZN4llvm2at4RAUWEPNS_10DIAssignIDES2_", "llvm::at::RAUW(llvm::DIAssignID*, llvm::DIAssignID*)",
    "llvm::at::RAUW",
  ),
  (
    "_ZTIN4mlir6memref4impl29ExpandStridedMetadataPassBaseIN12_GLOBAL__N_125ExpandStridedMetadataPassEEE",
    "typeinfo for mlir::memref::impl::ExpandStridedMetadataPassBase<(anonymous namespace)::ExpandStridedMetadataPass>",
    "typeinfo for mlir::memref::impl::ExpandStridedMetadataPassBase<(anonymous namespace)::ExpandStridedMetadataPass>",
  ),
  (
    "_ZN4llvmL45AV_320_with_sub4_in_VGPR_32_Lo256SuperclassesE", "llvm::AV_320_with_sub4_in_VGPR_32_Lo256Superclasses",
    "llvm::AV_320_with_sub4_in_VGPR_32_Lo256Superclasses",
  ),
  (
    "_ZN4mlir5index6RemSOp15getInherentAttrEPNS_11MLIRContextERKNS_15EmptyPropertiesEN4llvm9StringRefE",
    "mlir::index::RemSOp::getInherentAttr(mlir::MLIRContext*, mlir::EmptyProperties const&, llvm::StringRef)",
    "mlir::index::RemSOp::getInherentAttr",
  ),
  (
    "_ZTVN4mlir5spirv6detail30QueryMaxVersionInterfaceTraits5ModelINS0_23AtomicCompareExchangeOpEEE",
    "vtable for mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::AtomicCompareExchangeOp>",
    "vtable for mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::AtomicCompareExchangeOp>",
  ),
  (
    "_ZN4mlir5spirv6detail30QueryMinVersionInterfaceTraits5ModelINS0_7GLSinOpEED0Ev",
    "mlir::spirv::detail::QueryMinVersionInterfaceTraits::Model<mlir::spirv::GLSinOp>::~Model()",
    "mlir::spirv::detail::QueryMinVersionInterfaceTraits::Model<mlir::spirv::GLSinOp>::~Model",
  ),
  (
    "_ZN7Iex_3_49EnolckExcC2EPKc", "Iex_3_4::EnolckExc::EnolckExc(char const*)",
    "Iex_3_4::EnolckExc::EnolckExc",
  ),
  (
    "_ZTIN4llvm2cl11opt_storageIN4mlir13bufferization15LayoutMapOptionELb0ELb0EEE",
    "typeinfo for llvm::cl::opt_storage<mlir::bufferization::LayoutMapOption, false, false>",
    "typeinfo for llvm::cl::opt_storage<mlir::bufferization::LayoutMapOption, false, false>",
  ),
  (
    "_ZN2v88internal17PatchingAssembler11PatchAdrFarEx", "v8::internal::PatchingAssembler::PatchAdrFar(long long)",
    "v8::internal::PatchingAssembler::PatchAdrFar",
  ),
  (
    "_ZN5clang21handleSimpleAttributeINS_13AVRSignalAttrEEEvRNS_8SemaBaseEPNS_4DeclERKNS_19AttributeCommonInfoE",
    "void clang::handleSimpleAttribute<clang::AVRSignalAttr>(clang::SemaBase&, clang::Decl*, clang::AttributeCommonInfo const&)",
    "clang::handleSimpleAttribute<clang::AVRSignalAttr>",
  ),
  (
    "_ZN12_GLOBAL__N_119AANoFPClassReturnedD0Ev", "(anonymous namespace)::AANoFPClassReturned::~AANoFPClassReturned()",
    "(anonymous namespace)::AANoFPClassReturned::~AANoFPClassReturned",
  ),
  (
    "_ZNK4llvm2cl3optIN4mlir34SourceMgrDiagnosticVerifierHandler5LevelELb0ENS0_6parserIS4_EEE15printOptionInfoEm",
    "llvm::cl::opt<mlir::SourceMgrDiagnosticVerifierHandler::Level, false, llvm::cl::parser<mlir::SourceMgrDiagnosticVerifierHandler::Level>>::printOptionInfo(unsigned long) const",
    "llvm::cl::opt<mlir::SourceMgrDiagnosticVerifierHandler::Level, false, llvm::cl::parser<mlir::SourceMgrDiagnosticVerifierHandler::Level>>::printOptionInfo",
  ),
  (
    "_ZN5GpgME19KeyGenerationResultC2EP13gpgme_contextRKNS_5ErrorE", "GpgME::KeyGenerationResult::KeyGenerationResult(gpgme_context*, GpgME::Error const&)",
    "GpgME::KeyGenerationResult::KeyGenerationResult",
  ),
  (
    "_ZN9hashbrown3map28HashMap$LT$K$C$V$C$S$C$A$GT$3get17h6c326f62b1526016E", "hashbrown::map::HashMap$LT$K$C$V$C$S$C$A$GT$::get::h6c326f62b1526016",
    "hashbrown::map::HashMap$LT$K$C$V$C$S$C$A$GT$::get::h6c326f62b1526016",
  ),
  (
    "_ZNK4llvm18RISCVTargetMachine18getObjFileLoweringEv", "llvm::RISCVTargetMachine::getObjFileLowering() const",
    "llvm::RISCVTargetMachine::getObjFileLowering",
  ),
  (
    "_ZN12_GLOBAL__N_114CodeGenPrepare4_runERN4llvm8FunctionE", "(anonymous namespace)::CodeGenPrepare::_run(llvm::Function&)",
    "(anonymous namespace)::CodeGenPrepare::_run",
  ),
  (
    "_ZNK4llvm26RuntimeDyldCheckerExprEval14evalSimpleExprENS_9StringRefENS0_12ParseContextE",
    "llvm::RuntimeDyldCheckerExprEval::evalSimpleExpr(llvm::StringRef, llvm::RuntimeDyldCheckerExprEval::ParseContext) const",
    "llvm::RuntimeDyldCheckerExprEval::evalSimpleExpr",
  ),
  (
    "_ZN12_GLOBAL__N_121ParsedAttrInfoWeakRef8InstanceE", "(anonymous namespace)::ParsedAttrInfoWeakRef::Instance",
    "(anonymous namespace)::ParsedAttrInfoWeakRef::Instance",
  ),
  (
    "_ZN7Imf_3_414TypedAttributeINS_14ChromaticitiesEE4castEPNS_9AttributeE", "Imf_3_4::TypedAttribute<Imf_3_4::Chromaticities>::cast(Imf_3_4::Attribute*)",
    "Imf_3_4::TypedAttribute<Imf_3_4::Chromaticities>::cast",
  ),
  (
    "_ZN4mlir7arm_sve20WhileLTIntrOpAdaptor6verifyENS_8LocationE", "mlir::arm_sve::WhileLTIntrOpAdaptor::verify(mlir::Location)",
    "mlir::arm_sve::WhileLTIntrOpAdaptor::verify",
  ),
  (
    "_ZNK12lldb_private12CompilerType24GetFunctionArgumentCountEv", "lldb_private::CompilerType::GetFunctionArgumentCount() const",
    "lldb_private::CompilerType::GetFunctionArgumentCount",
  ),
  (
    "_ZN4mlir6detail29ConversionPatternRewriterImpl19SingleEraseRewriterD1Ev", "mlir::detail::ConversionPatternRewriterImpl::SingleEraseRewriter::~SingleEraseRewriter()",
    "mlir::detail::ConversionPatternRewriterImpl::SingleEraseRewriter::~SingleEraseRewriter",
  ),
  (
    "_ZN4llvm15PPCELFMCAsmInfoC1EbRKNS_6TripleE", "llvm::PPCELFMCAsmInfo::PPCELFMCAsmInfo(bool, llvm::Triple const&)",
    "llvm::PPCELFMCAsmInfo::PPCELFMCAsmInfo",
  ),
  (
    "_ZN4mlir7wasmssa10CopySignOp19getPropertiesAsAttrEPNS_11MLIRContextERKNS_15EmptyPropertiesE",
    "mlir::wasmssa::CopySignOp::getPropertiesAsAttr(mlir::MLIRContext*, mlir::EmptyProperties const&)",
    "mlir::wasmssa::CopySignOp::getPropertiesAsAttr",
  ),
  (
    "_ZNK4llvm2cl3optIN4mlir12RemarkPolicyELb1ENS0_6parserIS3_EEE14getOptionWidthEv",
    "llvm::cl::opt<mlir::RemarkPolicy, true, llvm::cl::parser<mlir::RemarkPolicy>>::getOptionWidth() const",
    "llvm::cl::opt<mlir::RemarkPolicy, true, llvm::cl::parser<mlir::RemarkPolicy>>::getOptionWidth",
  ),
  (
    "_ZN4mlir5spirv6detail30QueryMinVersionInterfaceTraits5ModelINS0_13ReturnValueOpEED1Ev",
    "mlir::spirv::detail::QueryMinVersionInterfaceTraits::Model<mlir::spirv::ReturnValueOp>::~Model()",
    "mlir::spirv::detail::QueryMinVersionInterfaceTraits::Model<mlir::spirv::ReturnValueOp>::~Model",
  ),
  (
    "_ZTIN4mlir5spirv6detail30QueryMaxVersionInterfaceTraits5ModelINS0_8GLAtanOpEEE",
    "typeinfo for mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::GLAtanOp>",
    "typeinfo for mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::GLAtanOp>",
  ),
  (
    "_ZN12_GLOBAL__N_128AArch64PostLegalizerCombinerD0Ev", "(anonymous namespace)::AArch64PostLegalizerCombiner::~AArch64PostLegalizerCombiner()",
    "(anonymous namespace)::AArch64PostLegalizerCombiner::~AArch64PostLegalizerCombiner",
  ),
  (
    "_ZN12_GLOBAL__N_123EraseAlwaysFalseDeallocD1Ev", "(anonymous namespace)::EraseAlwaysFalseDealloc::~EraseAlwaysFalseDealloc()",
    "(anonymous namespace)::EraseAlwaysFalseDealloc::~EraseAlwaysFalseDealloc",
  ),
  (
    "_ZNK12_GLOBAL__N_118ParsedAttrInfoWeak20diagAppertainsToDeclERN5clang4SemaERKNS1_10ParsedAttrEPKNS1_4DeclE",
    "(anonymous namespace)::ParsedAttrInfoWeak::diagAppertainsToDecl(clang::Sema&, clang::ParsedAttr const&, clang::Decl const*) const",
    "(anonymous namespace)::ParsedAttrInfoWeak::diagAppertainsToDecl",
  ),
  (
    "_ZL17printMetadataImplRN4llvm11raw_ostreamERKNS_8MetadataERNS_17ModuleSlotTrackerEPKNS_6ModuleEbb",
    "printMetadataImpl(llvm::raw_ostream&, llvm::Metadata const&, llvm::ModuleSlotTracker&, llvm::Module const*, bool, bool)",
    "printMetadataImpl",
  ),
  (
    "_ZN14decl_collectorD1Ev", "decl_collector::~decl_collector()", "decl_collector::~decl_collector",
  ),
  (
    "_ZN12wasm_encoder4core12instructions15InstructionSink28i32x4_trunc_sat_f64x2_u_zero17h55126969f1e37febE",
    "wasm_encoder::core::instructions::InstructionSink::i32x4_trunc_sat_f64x2_u_zero::h55126969f1e37feb",
    "wasm_encoder::core::instructions::InstructionSink::i32x4_trunc_sat_f64x2_u_zero::h55126969f1e37feb",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_3acc12DataBoundsOpEE8hasTraitENS_6TypeIDE",
    "mlir::RegisteredOperationName::Model<mlir::acc::DataBoundsOp>::hasTrait(mlir::TypeID)",
    "mlir::RegisteredOperationName::Model<mlir::acc::DataBoundsOp>::hasTrait",
  ),
  (
    "_ZN4llvm24AMDGPUGenMCSubtargetInfoD1Ev", "llvm::AMDGPUGenMCSubtargetInfo::~AMDGPUGenMCSubtargetInfo()",
    "llvm::AMDGPUGenMCSubtargetInfo::~AMDGPUGenMCSubtargetInfo",
  ),
  (
    "_ZN11aig_managerC1ER11ast_manageryb", "aig_manager::aig_manager(ast_manager&, unsigned long long, bool)",
    "aig_manager::aig_manager",
  ),
  (
    "_ZNK4llvm14CombinerHelper23applySimplifyURemByPow2ERNS_12MachineInstrE", "llvm::CombinerHelper::applySimplifyURemByPow2(llvm::MachineInstr&) const",
    "llvm::CombinerHelper::applySimplifyURemByPow2",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5spirv11GroupFMaxOpEED1Ev", "mlir::RegisteredOperationName::Model<mlir::spirv::GroupFMaxOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::spirv::GroupFMaxOp>::~Model",
  ),
  (
    "_ZN2v88internal4wasm4impl9kSig_v_llE", "v8::internal::wasm::impl::kSig_v_ll",
    "v8::internal::wasm::impl::kSig_v_ll",
  ),
  (
    "_ZN5clang4ento20RetainSummaryManager37isTrustedReferenceCountImplementationEPKNS_4DeclE",
    "clang::ento::RetainSummaryManager::isTrustedReferenceCountImplementation(clang::Decl const*)",
    "clang::ento::RetainSummaryManager::isTrustedReferenceCountImplementation",
  ),
  (
    "_ZN2v87Isolate21LowMemoryNotificationEv", "v8::Isolate::LowMemoryNotification()",
    "v8::Isolate::LowMemoryNotification",
  ),
  (
    "_ZN5clang30DynamicRecursiveASTVisitorBaseILb1EE29TraverseUnaryTransformTypeLocENS_21UnaryTransformTypeLocEb",
    "clang::DynamicRecursiveASTVisitorBase<true>::TraverseUnaryTransformTypeLoc(clang::UnaryTransformTypeLoc, bool)",
    "clang::DynamicRecursiveASTVisitorBase<true>::TraverseUnaryTransformTypeLoc",
  ),
  (
    "_ZN12_GLOBAL__N_123ModuleConversionPatternD1Ev", "(anonymous namespace)::ModuleConversionPattern::~ModuleConversionPattern()",
    "(anonymous namespace)::ModuleConversionPattern::~ModuleConversionPattern",
  ),
  (
    "_ZTVN12_GLOBAL__N_127CArrayToPtrAssignmentGadgetE", "vtable for (anonymous namespace)::CArrayToPtrAssignmentGadget",
    "vtable for (anonymous namespace)::CArrayToPtrAssignmentGadget",
  ),
  (
    "_ZL11ctorArrayTyIN5clang6interp7PointerEEvPNS1_5BlockEPSt4bytebbbbbPKNS1_10DescriptorE",
    "void ctorArrayTy<clang::interp::Pointer>(clang::interp::Block*, std::byte*, bool, bool, bool, bool, bool, clang::interp::Descriptor const*)",
    "ctorArrayTy<clang::interp::Pointer>",
  ),
  (
    "_ZN4LIEF3ELF7Segment16writable_contentEv", "LIEF::ELF::Segment::writable_content()",
    "LIEF::ELF::Segment::writable_content",
  ),
  (
    "_ZN4llvm7CmpInst17isStrictPredicateENS0_9PredicateE", "llvm::CmpInst::isStrictPredicate(llvm::CmpInst::Predicate)",
    "llvm::CmpInst::isStrictPredicate",
  ),
  (
    "_ZN4mlir4NVVM10EnvReg18Op5printERNS_12OpAsmPrinterE", "mlir::NVVM::EnvReg18Op::print(mlir::OpAsmPrinter&)",
    "mlir::NVVM::EnvReg18Op::print",
  ),
  (
    "_ZNK4llvm15TargetInstrInfo28getPartialRegUpdateClearanceERKNS_12MachineInstrEjPKNS_18TargetRegisterInfoE",
    "llvm::TargetInstrInfo::getPartialRegUpdateClearance(llvm::MachineInstr const&, unsigned int, llvm::TargetRegisterInfo const*) const",
    "llvm::TargetInstrInfo::getPartialRegUpdateClearance",
  ),
  (
    "_ZN12_GLOBAL__N_131WebAssemblyAddMissingPrototypesD0Ev", "(anonymous namespace)::WebAssemblyAddMissingPrototypes::~WebAssemblyAddMissingPrototypes()",
    "(anonymous namespace)::WebAssemblyAddMissingPrototypes::~WebAssemblyAddMissingPrototypes",
  ),
  ("_Z14_As_FixedArraym", "_As_FixedArray(unsigned long)", "_As_FixedArray"),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5emitc10GetFieldOpEE8hasTraitENS_6TypeIDE",
    "mlir::RegisteredOperationName::Model<mlir::emitc::GetFieldOp>::hasTrait(mlir::TypeID)",
    "mlir::RegisteredOperationName::Model<mlir::emitc::GetFieldOp>::hasTrait",
  ),
  (
    "_ZN2v88internal4wasm16LiftoffAssembler22FillStackSlotsWithZeroEii", "v8::internal::wasm::LiftoffAssembler::FillStackSlotsWithZero(int, int)",
    "v8::internal::wasm::LiftoffAssembler::FillStackSlotsWithZero",
  ),
  (
    "_ZN4llvm14MLInlineAdvice35recordInliningWithCalleeDeletedImplEv", "llvm::MLInlineAdvice::recordInliningWithCalleeDeletedImpl()",
    "llvm::MLInlineAdvice::recordInliningWithCalleeDeletedImpl",
  ),
  (
    "_ZN2v88internal8compiler14GraphAssembler4BindILm4294967295EEEvPNS1_19GraphAssemblerLabelIXT_EEE",
    "void v8::internal::compiler::GraphAssembler::Bind<4294967295ul>(v8::internal::compiler::GraphAssemblerLabel<4294967295ul>*)",
    "v8::internal::compiler::GraphAssembler::Bind<4294967295ul>",
  ),
  (
    "_ZN2v87Isolate12CreateParamsD2Ev", "v8::Isolate::CreateParams::~CreateParams()",
    "v8::Isolate::CreateParams::~CreateParams",
  ),
  (
    "_ZN2v88internal8compiler16JSBinopReduction31CheckInputsToInternalizedStringEv",
    "v8::internal::compiler::JSBinopReduction::CheckInputsToInternalizedString()",
    "v8::internal::compiler::JSBinopReduction::CheckInputsToInternalizedString",
  ),
  (
    "_ZTSN12_GLOBAL__N_110ASTPrinterE", "typeinfo name for (anonymous namespace)::ASTPrinter",
    "typeinfo name for (anonymous namespace)::ASTPrinter",
  ),
  (
    "_ZN4mlir5spirv8ReturnOp20verifyInvariantsImplEv", "mlir::spirv::ReturnOp::verifyInvariantsImpl()",
    "mlir::spirv::ReturnOp::verifyInvariantsImpl",
  ),
  (
    "_ZN12_GLOBAL__N_120AtomicOperandChecker20CheckOperandVariableEPKN5clang4ExprENS1_17PartialDiagnosticE",
    "(anonymous namespace)::AtomicOperandChecker::CheckOperandVariable(clang::Expr const*, clang::PartialDiagnostic)",
    "(anonymous namespace)::AtomicOperandChecker::CheckOperandVariable",
  ),
  (
    "_ZNSt3__18__sp_mut6unlockEv", "std::__1::__sp_mut::unlock()", "std::__1::__sp_mut::unlock",
  ),
  (
    "_ZN6vectorINSt3__14pairIPN3mbp4termES4_EELb1EjED2Ev", "vector<std::__1::pair<mbp::term*, mbp::term*>, true, unsigned int>::~vector()",
    "vector<std::__1::pair<mbp::term*, mbp::term*>, true, unsigned int>::~vector",
  ),
  (
    "_ZN4llvmL65ZPR4_with_zsub1_in_ZPR_K_and_ZPR4_with_zsub3_in_ZPR_KSubClassMaskE",
    "llvm::ZPR4_with_zsub1_in_ZPR_K_and_ZPR4_with_zsub3_in_ZPR_KSubClassMask", "llvm::ZPR4_with_zsub1_in_ZPR_K_and_ZPR4_with_zsub3_in_ZPR_KSubClassMask",
  ),
  (
    "_ZN5clang30DynamicRecursiveASTVisitorBaseILb0EE12TraverseAttrEPNS_4AttrE", "clang::DynamicRecursiveASTVisitorBase<false>::TraverseAttr(clang::Attr*)",
    "clang::DynamicRecursiveASTVisitorBase<false>::TraverseAttr",
  ),
  (
    "_ZN4llvm10getLCMTypeENS_3LLTES0_", "llvm::getLCMType(llvm::LLT, llvm::LLT)",
    "llvm::getLCMType",
  ),
  (
    "_ZN5clang13SourceManager19initializeForReplayERKS0_", "clang::SourceManager::initializeForReplay(clang::SourceManager const&)",
    "clang::SourceManager::initializeForReplay",
  ),
  (
    "_ZN5clang7CodeGen13CodeGenModule28AlwaysHasLTOVisibilityPublicEPKNS_13CXXRecordDeclE",
    "clang::CodeGen::CodeGenModule::AlwaysHasLTOVisibilityPublic(clang::CXXRecordDecl const*)",
    "clang::CodeGen::CodeGenModule::AlwaysHasLTOVisibilityPublic",
  ),
  (
    "_ZN2v88internal12_GLOBAL__N_114JsonTraceValueD0Ev", "v8::internal::(anonymous namespace)::JsonTraceValue::~JsonTraceValue()",
    "v8::internal::(anonymous namespace)::JsonTraceValue::~JsonTraceValue",
  ),
  (
    "_ZN5clang10ArmOutAttr6CreateERNS_10ASTContextEPN4llvm9StringRefEjRKNS_19AttributeCommonInfoE",
    "clang::ArmOutAttr::Create(clang::ASTContext&, llvm::StringRef*, unsigned int, clang::AttributeCommonInfo const&)",
    "clang::ArmOutAttr::Create",
  ),
  (
    "_ZN4lldb6SBTypeeqERS0_", "lldb::SBType::operator==(lldb::SBType&)", "lldb::SBType::operator==",
  ),
  (
    "_ZN2v88internal26FastConstructStubFrameInfoC2Eb", "v8::internal::FastConstructStubFrameInfo::FastConstructStubFrameInfo(bool)",
    "v8::internal::FastConstructStubFrameInfo::FastConstructStubFrameInfo",
  ),
  (
    "_ZN2v88internal4Zone13AllocateArrayINS0_10ZoneVectorIbEEA_S4_EEPT_m", "v8::internal::ZoneVector<bool>* v8::internal::Zone::AllocateArray<v8::internal::ZoneVector<bool>, v8::internal::ZoneVector<bool> []>(unsigned long)",
    "v8::internal::Zone::AllocateArray<v8::internal::ZoneVector<bool>, v8::internal::ZoneVector<bool> []>",
  ),
  (
    "_ZN4mlir4tosa6detail27QueryProfileInterfaceTraits5ModelINS0_8Conv2DOpEED1Ev",
    "mlir::tosa::detail::QueryProfileInterfaceTraits::Model<mlir::tosa::Conv2DOp>::~Model()",
    "mlir::tosa::detail::QueryProfileInterfaceTraits::Model<mlir::tosa::Conv2DOp>::~Model",
  ),
  (
    "_ZZN12lldb_private16GetRegInfoSharedEN4llvm6Triple8ArchTypeEbE25reg_info_x86_64_with_base",
    "lldb_private::GetRegInfoShared(llvm::Triple::ArchType, bool)::reg_info_x86_64_with_base",
    "lldb_private::GetRegInfoShared(llvm::Triple::ArchType, bool)::reg_info_x86_64_with_base",
  ),
  (
    "_ZN4mlir5spirv8SelectOp6createERNS_20ImplicitLocOpBuilderENS_9TypeRangeENS_5ValueES5_S5_",
    "mlir::spirv::SelectOp::create(mlir::ImplicitLocOpBuilder&, mlir::TypeRange, mlir::Value, mlir::Value, mlir::Value)",
    "mlir::spirv::SelectOp::create",
  ),
  (
    "_ZN12_GLOBAL__N_113formatStringsE", "(anonymous namespace)::formatStrings",
    "(anonymous namespace)::formatStrings",
  ),
  (
    "_ZN5crdtp15DeferredMessage8FromSpanENSt3__14spanIKhLm18446744073709551615EEE",
    "crdtp::DeferredMessage::FromSpan(std::__1::span<unsigned char const, 18446744073709551615ul>)",
    "crdtp::DeferredMessage::FromSpan",
  ),
  (
    "_ZN4mlir4LLVM6detail27VPStoreOpGenericAdaptorBaseC2ENS0_9VPStoreOpE", "mlir::LLVM::detail::VPStoreOpGenericAdaptorBase::VPStoreOpGenericAdaptorBase(mlir::LLVM::VPStoreOp)",
    "mlir::LLVM::detail::VPStoreOpGenericAdaptorBase::VPStoreOpGenericAdaptorBase",
  ),
  (
    "_ZN4llvm9sandboxir11BottomUpVec12vectorizeRecENS_8ArrayRefIPNS0_5ValueEEES5_jRNS0_16LegalityAnalysisE",
    "llvm::sandboxir::BottomUpVec::vectorizeRec(llvm::ArrayRef<llvm::sandboxir::Value*>, llvm::ArrayRef<llvm::sandboxir::Value*>, unsigned int, llvm::sandboxir::LegalityAnalysis&)",
    "llvm::sandboxir::BottomUpVec::vectorizeRec",
  ),
  (
    "_ZNK4llvm16BasicTTIImplBaseINS_10PPCTTIImplEE28isVScaleKnownToBeAPowerOfTwoEv",
    "llvm::BasicTTIImplBase<llvm::PPCTTIImpl>::isVScaleKnownToBeAPowerOfTwo() const",
    "llvm::BasicTTIImplBase<llvm::PPCTTIImpl>::isVScaleKnownToBeAPowerOfTwo",
  ),
  (
    "_ZZNK4llvm14MipsAsmBackend16getFixupKindInfoEtE17LittleEndianInfos", "llvm::MipsAsmBackend::getFixupKindInfo(unsigned short) const::LittleEndianInfos",
    "llvm::MipsAsmBackend::getFixupKindInfo(unsigned short) const::LittleEndianInfos",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4tosa5PowOpEED1Ev", "mlir::RegisteredOperationName::Model<mlir::tosa::PowOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::tosa::PowOp>::~Model",
  ),
  (
    "_ZN12v8_inspector8protocol7Runtime27ExecutionContextDescriptionD1Ev", "v8_inspector::protocol::Runtime::ExecutionContextDescription::~ExecutionContextDescription()",
    "v8_inspector::protocol::Runtime::ExecutionContextDescription::~ExecutionContextDescription",
  ),
  (
    "_ZN12_GLOBAL__N_118ScalarOpToLibmCallIN4mlir4math6Log2OpEED1Ev", "(anonymous namespace)::ScalarOpToLibmCall<mlir::math::Log2Op>::~ScalarOpToLibmCall()",
    "(anonymous namespace)::ScalarOpToLibmCall<mlir::math::Log2Op>::~ScalarOpToLibmCall",
  ),
  (
    "_ZN4mlir4tosa9TargetEnv23createTargetEnvFromAttrENS0_13TargetEnvAttrENS_8LocationE",
    "mlir::tosa::TargetEnv::createTargetEnvFromAttr(mlir::tosa::TargetEnvAttr, mlir::Location)",
    "mlir::tosa::TargetEnv::createTargetEnvFromAttr",
  ),
  (
    "_ZNSt3__120__shared_ptr_emplaceIN12_GLOBAL__N_123CrossProcessModuleCacheENS_9allocatorIS2_EEED0Ev",
    "std::__1::__shared_ptr_emplace<(anonymous namespace)::CrossProcessModuleCache, std::__1::allocator<(anonymous namespace)::CrossProcessModuleCache>>::~__shared_ptr_emplace()",
    "std::__1::__shared_ptr_emplace<(anonymous namespace)::CrossProcessModuleCache, std::__1::allocator<(anonymous namespace)::CrossProcessModuleCache>>::~__shared_ptr_emplace",
  ),
  (
    "_ZN5tokio7runtime4time5wheel5Wheel6remove17h2bf5cd6faf27db98E", "tokio::runtime::time::wheel::Wheel::remove::h2bf5cd6faf27db98",
    "tokio::runtime::time::wheel::Wheel::remove::h2bf5cd6faf27db98",
  ),
  (
    "_ZN4llvm15SmallVectorImplIPNS_5ValueEE6insertIPKS2_vEEPS2_S7_T_S8_", "llvm::Value** llvm::SmallVectorImpl<llvm::Value*>::insert<llvm::Value* const*, void>(llvm::Value**, llvm::Value* const*, llvm::Value* const*)",
    "llvm::SmallVectorImpl<llvm::Value*>::insert<llvm::Value* const*, void>",
  ),
  (
    "_ZN2v88internal8compiler17StateValuesAccess8iterator4nodeEv", "v8::internal::compiler::StateValuesAccess::iterator::node()",
    "v8::internal::compiler::StateValuesAccess::iterator::node",
  ),
  (
    "_ZN12lldb_private10formatters29LibcxxStdMapSyntheticFrontEnd15GetChildAtIndexEj",
    "lldb_private::formatters::LibcxxStdMapSyntheticFrontEnd::GetChildAtIndex(unsigned int)",
    "lldb_private::formatters::LibcxxStdMapSyntheticFrontEnd::GetChildAtIndex",
  ),
  (
    "_ZNK4mlir5emitc10OpaqueAttr8getValueEv", "mlir::emitc::OpaqueAttr::getValue() const",
    "mlir::emitc::OpaqueAttr::getValue",
  ),
  (
    "_ZN4llvm26createSIInsertWaitcntsPassEv", "llvm::createSIInsertWaitcntsPass()",
    "llvm::createSIInsertWaitcntsPass",
  ),
  (
    "_ZN4node6crypto15KeyObjectHandle3NewERKN2v820FunctionCallbackInfoINS2_5ValueEEE.cold.1",
    "node::crypto::KeyObjectHandle::New(v8::FunctionCallbackInfo<v8::Value> const&) (.cold.1)",
    "node::crypto::KeyObjectHandle::New",
  ),
  (
    "_ZN2v88internal32Builtin_CallSitePrototypeGetThisEiPmPNS0_7IsolateE.cold.2",
    "v8::internal::Builtin_CallSitePrototypeGetThis(int, unsigned long*, v8::internal::Isolate*) (.cold.2)",
    "v8::internal::Builtin_CallSitePrototypeGetThis",
  ),
  (
    "_ZN4llvm21GCNRegPressurePrinterD0Ev", "llvm::GCNRegPressurePrinter::~GCNRegPressurePrinter()",
    "llvm::GCNRegPressurePrinter::~GCNRegPressurePrinter",
  ),
  (
    "_ZN2v88internal8compiler10hash_valueERKNS1_23CreateLiteralParametersE", "v8::internal::compiler::hash_value(v8::internal::compiler::CreateLiteralParameters const&)",
    "v8::internal::compiler::hash_value",
  ),
  (
    "_ZN4lldb20SBBreakpointLocation11SetCallbackEPFbPvRNS_9SBProcessERNS_8SBThreadERS0_ES1_",
    "lldb::SBBreakpointLocation::SetCallback(bool (*)(void*, lldb::SBProcess&, lldb::SBThread&, lldb::SBBreakpointLocation&), void*)",
    "lldb::SBBreakpointLocation::SetCallback",
  ),
  (
    "_ZN7Iex_3_410EnoattrExcC2ERKS0_", "Iex_3_4::EnoattrExc::EnoattrExc(Iex_3_4::EnoattrExc const&)",
    "Iex_3_4::EnoattrExc::EnoattrExc",
  ),
  (
    "_ZN2v88internal10ZoneVectorINS0_21MachineRepresentationEE6resizeEmRKS2_", "v8::internal::ZoneVector<v8::internal::MachineRepresentation>::resize(unsigned long, v8::internal::MachineRepresentation const&)",
    "v8::internal::ZoneVector<v8::internal::MachineRepresentation>::resize",
  ),
  (
    "_ZN2v88internal8compiler29SimplifiedOperatorGlobalCache15CheckIfOperatorILNS0_16DeoptimizeReasonE4EED0Ev",
    "v8::internal::compiler::SimplifiedOperatorGlobalCache::CheckIfOperator<(v8::internal::DeoptimizeReason)4>::~CheckIfOperator()",
    "v8::internal::compiler::SimplifiedOperatorGlobalCache::CheckIfOperator<(v8::internal::DeoptimizeReason)4>::~CheckIfOperator",
  ),
  (
    "_ZN12v8_inspector12_GLOBAL__N_132kGlobalConsoleMessageHandleLabelE", "v8_inspector::(anonymous namespace)::kGlobalConsoleMessageHandleLabel",
    "v8_inspector::(anonymous namespace)::kGlobalConsoleMessageHandleLabel",
  ),
  (
    "_ZTVN2v84base20BoundedPageAllocatorE", "vtable for v8::base::BoundedPageAllocator",
    "vtable for v8::base::BoundedPageAllocator",
  ),
  (
    "_ZN5cppgc8internal22EnsureGCInfoIndexTrait17EnsureGCInfoIndexERNSt3__16atomicItEEPFvPNS_7VisitorEPKvEPFvPvE",
    "cppgc::internal::EnsureGCInfoIndexTrait::EnsureGCInfoIndex(std::__1::atomic<unsigned short>&, void (*)(cppgc::Visitor*, void const*), void (*)(void*))",
    "cppgc::internal::EnsureGCInfoIndexTrait::EnsureGCInfoIndex",
  ),
  (
    "_ZL21g_sve_v31_invalidates", "g_sve_v31_invalidates", "g_sve_v31_invalidates",
  ),
  (
    "_ZNK4llvm9sandboxir15CatchReturnInst12getSuccessorEv", "llvm::sandboxir::CatchReturnInst::getSuccessor() const",
    "llvm::sandboxir::CatchReturnInst::getSuccessor",
  ),
  (
    "_ZTSN4llvm2cl11OptionValueI14OutputCostKindEE", "typeinfo name for llvm::cl::OptionValue<OutputCostKind>",
    "typeinfo name for llvm::cl::OptionValue<OutputCostKind>",
  ),
  (
    "_ZZN4mlir6detail14TypeIDResolverINS_4pdll3ast11RewriteStmtEvE13resolveTypeIDEvE2id",
    "mlir::detail::TypeIDResolver<mlir::pdll::ast::RewriteStmt, void>::resolveTypeID()::id",
    "mlir::detail::TypeIDResolver<mlir::pdll::ast::RewriteStmt, void>::resolveTypeID()::id",
  ),
  (
    "_ZN4mlir20DefaultTimingManager9stopTimerEPv", "mlir::DefaultTimingManager::stopTimer(void*)",
    "mlir::DefaultTimingManager::stopTimer",
  ),
  (
    "_ZNK5clang9NamedDecl20getNameForDiagnosticERN4llvm11raw_ostreamERKNS_14PrintingPolicyEb",
    "clang::NamedDecl::getNameForDiagnostic(llvm::raw_ostream&, clang::PrintingPolicy const&, bool) const",
    "clang::NamedDecl::getNameForDiagnostic",
  ),
  (
    "_ZN4mlir5spirv8GLAsinOp16verifyInvariantsEv", "mlir::spirv::GLAsinOp::verifyInvariants()",
    "mlir::spirv::GLAsinOp::verifyInvariants",
  ),
  (
    "_ZNK2v88internal4wasm19WasmFunctionBuilder23WriteAsmWasmOffsetTableEPNS1_10ZoneBufferE",
    "v8::internal::wasm::WasmFunctionBuilder::WriteAsmWasmOffsetTable(v8::internal::wasm::ZoneBuffer*) const",
    "v8::internal::wasm::WasmFunctionBuilder::WriteAsmWasmOffsetTable",
  ),
  (
    "_ZN5clang30DynamicRecursiveASTVisitorBaseILb1EE17VisitObjCImplDeclEPKNS_12ObjCImplDeclE",
    "clang::DynamicRecursiveASTVisitorBase<true>::VisitObjCImplDecl(clang::ObjCImplDecl const*)",
    "clang::DynamicRecursiveASTVisitorBase<true>::VisitObjCImplDecl",
  ),
  (
    "_ZN4mlir4xevm21WorkgroupIdXOpAdaptor6verifyENS_8LocationE", "mlir::xevm::WorkgroupIdXOpAdaptor::verify(mlir::Location)",
    "mlir::xevm::WorkgroupIdXOpAdaptor::verify",
  ),
  (
    "_ZNK4llvm16BasicTTIImplBaseINS_11R600TTIImplEE27preferPredicateOverEpilogueEPNS_15TailFoldingInfoE",
    "llvm::BasicTTIImplBase<llvm::R600TTIImpl>::preferPredicateOverEpilogue(llvm::TailFoldingInfo*) const",
    "llvm::BasicTTIImplBase<llvm::R600TTIImpl>::preferPredicateOverEpilogue",
  ),
  (
    "_ZN4mlir4xevm6detail33WorkgroupDimZOpGenericAdaptorBase8getRangeEv", "mlir::xevm::detail::WorkgroupDimZOpGenericAdaptorBase::getRange()",
    "mlir::xevm::detail::WorkgroupDimZOpGenericAdaptorBase::getRange",
  ),
  (
    "_ZNK4llvm8Argument27hasPointeeInMemoryValueAttrEv", "llvm::Argument::hasPointeeInMemoryValueAttr() const",
    "llvm::Argument::hasPointeeInMemoryValueAttr",
  ),
  (
    "_ZN4llvm13TinyPtrVectorIPNS_17DbgVariableRecordEE9push_backES2_", "llvm::TinyPtrVector<llvm::DbgVariableRecord*>::push_back(llvm::DbgVariableRecord*)",
    "llvm::TinyPtrVector<llvm::DbgVariableRecord*>::push_back",
  ),
  (
    "_ZL22_swigc__p_lldb__SBFile", "_swigc__p_lldb__SBFile", "_swigc__p_lldb__SBFile",
  ),
  (
    "_ZZN4llvm10FoldingSetIN5clang4ento12ExplodedNodeEE17getFoldingSetInfoEvE4Info",
    "llvm::FoldingSet<clang::ento::ExplodedNode>::getFoldingSetInfo()::Info", "llvm::FoldingSet<clang::ento::ExplodedNode>::getFoldingSetInfo()::Info",
  ),
  (
    "_ZNK5clang8CFGBlock16getLastConditionEv", "clang::CFGBlock::getLastCondition() const",
    "clang::CFGBlock::getLastCondition",
  ),
  (
    "_ZN4mlir4LLVM6detail25StoreOpGenericAdaptorBase12getAlignmentEv", "mlir::LLVM::detail::StoreOpGenericAdaptorBase::getAlignment()",
    "mlir::LLVM::detail::StoreOpGenericAdaptorBase::getAlignment",
  ),
  (
    "_ZNSt3__16vectorINS_4pairIN4llvm14WeakTrackingVHEjEENS_9allocatorIS4_EEE6resizeEm",
    "std::__1::vector<std::__1::pair<llvm::WeakTrackingVH, unsigned int>, std::__1::allocator<std::__1::pair<llvm::WeakTrackingVH, unsigned int>>>::resize(unsigned long)",
    "std::__1::vector<std::__1::pair<llvm::WeakTrackingVH, unsigned int>, std::__1::allocator<std::__1::pair<llvm::WeakTrackingVH, unsigned int>>>::resize",
  ),
  (
    "_ZN4mlir4tosa6detail27QueryProfileInterfaceTraits5ModelINS0_10SubShapeOpEED0Ev",
    "mlir::tosa::detail::QueryProfileInterfaceTraits::Model<mlir::tosa::SubShapeOp>::~Model()",
    "mlir::tosa::detail::QueryProfileInterfaceTraits::Model<mlir::tosa::SubShapeOp>::~Model",
  ),
  (
    "_ZN4mlir4math14AtanhOpAdaptor6verifyENS_8LocationE", "mlir::math::AtanhOpAdaptor::verify(mlir::Location)",
    "mlir::math::AtanhOpAdaptor::verify",
  ),
  (
    "_ZN4mlir5ROCDL28CvtScaleF32SrFp8F32OpAdaptorC2ENS0_21CvtScaleF32SrFp8F32OpE",
    "mlir::ROCDL::CvtScaleF32SrFp8F32OpAdaptor::CvtScaleF32SrFp8F32OpAdaptor(mlir::ROCDL::CvtScaleF32SrFp8F32Op)",
    "mlir::ROCDL::CvtScaleF32SrFp8F32OpAdaptor::CvtScaleF32SrFp8F32OpAdaptor",
  ),
  (
    "_ZN2v88internal4Zone8AllocateIA_NSt3__14pairIPNS0_12ClassLiteralEmEEEEPvm",
    "void* v8::internal::Zone::Allocate<std::__1::pair<v8::internal::ClassLiteral*, unsigned long> []>(unsigned long)",
    "v8::internal::Zone::Allocate<std::__1::pair<v8::internal::ClassLiteral*, unsigned long> []>",
  ),
  (
    "_ZN4mlir6tensor50populateMergeConsecutiveInsertExtractSlicePatternsERNS_17RewritePatternSetE",
    "mlir::tensor::populateMergeConsecutiveInsertExtractSlicePatterns(mlir::RewritePatternSet&)",
    "mlir::tensor::populateMergeConsecutiveInsertExtractSlicePatterns",
  ),
  (
    "_ZN4mlir5ROCDL6detail45smfmac_f32_16x16x64_fp8_bf8GenericAdaptorBaseC1ENS0_27smfmac_f32_16x16x64_fp8_bf8E",
    "mlir::ROCDL::detail::smfmac_f32_16x16x64_fp8_bf8GenericAdaptorBase::smfmac_f32_16x16x64_fp8_bf8GenericAdaptorBase(mlir::ROCDL::smfmac_f32_16x16x64_fp8_bf8)",
    "mlir::ROCDL::detail::smfmac_f32_16x16x64_fp8_bf8GenericAdaptorBase::smfmac_f32_16x16x64_fp8_bf8GenericAdaptorBase",
  ),
  (
    "_ZN7Imf_3_414TypedAttributeIN9Imath_3_23BoxINS1_4Vec2IiEEEEE13copyValueFromERKNS_9AttributeE",
    "Imf_3_4::TypedAttribute<Imath_3_2::Box<Imath_3_2::Vec2<int>>>::copyValueFrom(Imf_3_4::Attribute const&)",
    "Imf_3_4::TypedAttribute<Imath_3_2::Box<Imath_3_2::Vec2<int>>>::copyValueFrom",
  ),
  (
    "_ZN4LIEF5MachO15RelocationFixup3setERKNS0_7details40dyld_chained_ptr_arm64e_segmented_rebaseE",
    "LIEF::MachO::RelocationFixup::set(LIEF::MachO::details::dyld_chained_ptr_arm64e_segmented_rebase const&)",
    "LIEF::MachO::RelocationFixup::set",
  ),
  (
    "_ZL50InitializeStackSafetyGlobalInfoWrapperPassPassFlag", "InitializeStackSafetyGlobalInfoWrapperPassPassFlag",
    "InitializeStackSafetyGlobalInfoWrapperPassPassFlag",
  ),
  (
    "_ZNK5clang9ASTWriter16getAdjustedRangeENS_11SourceRangeE", "clang::ASTWriter::getAdjustedRange(clang::SourceRange) const",
    "clang::ASTWriter::getAdjustedRange",
  ),
  (
    "_ZL27_deserialize_json_key_spans", "_deserialize_json_key_spans", "_deserialize_json_key_spans",
  ),
  (
    "_ZN12_GLOBAL__N_124SILowerControlFlowLegacyD0Ev", "(anonymous namespace)::SILowerControlFlowLegacy::~SILowerControlFlowLegacy()",
    "(anonymous namespace)::SILowerControlFlowLegacy::~SILowerControlFlowLegacy",
  ),
  (
    "_ZNK4llvm2cl6parserINS_5NVPTX17DivPrecisionLevelEE13getNumOptionsEv", "llvm::cl::parser<llvm::NVPTX::DivPrecisionLevel>::getNumOptions() const",
    "llvm::cl::parser<llvm::NVPTX::DivPrecisionLevel>::getNumOptions",
  ),
  (
    "_ZN4llvm3mca13DispatchStage8dispatchENS0_7InstRefE", "llvm::mca::DispatchStage::dispatch(llvm::mca::InstRef)",
    "llvm::mca::DispatchStage::dispatch",
  ),
  (
    "_ZN10ref_vectorIN18dependency_managerIN11ast_manager22expr_dependency_configEE10dependencyES1_E4setxEjPS4_",
    "ref_vector<dependency_manager<ast_manager::expr_dependency_config>::dependency, ast_manager>::setx(unsigned int, dependency_manager<ast_manager::expr_dependency_config>::dependency*)",
    "ref_vector<dependency_manager<ast_manager::expr_dependency_config>::dependency, ast_manager>::setx",
  ),
  (
    "_ZN4mlir5spirv9GLRoundOp5printERNS_12OpAsmPrinterE", "mlir::spirv::GLRoundOp::print(mlir::OpAsmPrinter&)",
    "mlir::spirv::GLRoundOp::print",
  ),
  (
    "_ZN4node6cryptoL28has_cached_system_root_certsE.0", "node::crypto::has_cached_system_root_certs (.0)",
    "node::crypto::has_cached_system_root_certs (.0)",
  ),
  (
    "_ZN4mlir5spirv8CLCoshOp20verifyInvariantsImplEv", "mlir::spirv::CLCoshOp::verifyInvariantsImpl()",
    "mlir::spirv::CLCoshOp::verifyInvariantsImpl",
  ),
  (
    "_ZN4mlir5spirv9SNegateOp6createERNS_20ImplicitLocOpBuilderENS_4TypeENS_5ValueE",
    "mlir::spirv::SNegateOp::create(mlir::ImplicitLocOpBuilder&, mlir::Type, mlir::Value)",
    "mlir::spirv::SNegateOp::create",
  ),
  (
    "_ZNK5cppgc8internal12_GLOBAL__N_121ConcurrentMarkingTask17GetMaxConcurrencyEm",
    "cppgc::internal::(anonymous namespace)::ConcurrentMarkingTask::GetMaxConcurrency(unsigned long) const",
    "cppgc::internal::(anonymous namespace)::ConcurrentMarkingTask::GetMaxConcurrency",
  ),
  (
    "_ZNK4llvm12ARMSubtarget5useAAEv", "llvm::ARMSubtarget::useAA() const", "llvm::ARMSubtarget::useAA",
  ),
  (
    "_ZN5clang24ChainedASTReaderListener23readModuleFileExtensionERKNS_27ModuleFileExtensionMetadataE",
    "clang::ChainedASTReaderListener::readModuleFileExtension(clang::ModuleFileExtensionMetadata const&)",
    "clang::ChainedASTReaderListener::readModuleFileExtension",
  ),
  (
    "_ZTIN12lldb_private6curses22DirectoryFieldDelegateE", "typeinfo for lldb_private::curses::DirectoryFieldDelegate",
    "typeinfo for lldb_private::curses::DirectoryFieldDelegate",
  ),
  (
    "_ZN42_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$3fmt17hb91476cba73d57fcE", "_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$::fmt::hb91476cba73d57fc",
    "_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$::fmt::hb91476cba73d57fc",
  ),
  (
    "_ZNSt3__110__function6__funcIZN4llvm13DWARFVerifier26verifyDebugLineStmtOffsetsEvE3$_0FvvEED0Ev",
    "std::__1::__function::__func<llvm::DWARFVerifier::verifyDebugLineStmtOffsets()::$_0, void ()>::~__func()",
    "std::__1::__function::__func<llvm::DWARFVerifier::verifyDebugLineStmtOffsets()::$_0, void ()>::~__func",
  ),
  (
    "_ZN5clang6interp6BitXorILNS0_8PrimTypeE7ENS0_8IntegralILj64ELb0EEEEEbRNS0_11InterpStateENS0_7CodePtrE",
    "bool clang::interp::BitXor<(clang::interp::PrimType)7, clang::interp::Integral<64u, false>>(clang::interp::InterpState&, clang::interp::CodePtr)",
    "clang::interp::BitXor<(clang::interp::PrimType)7, clang::interp::Integral<64u, false>>",
  ),
  (
    "_ZL30AttrDoc_ArmStreamingCompatible", "AttrDoc_ArmStreamingCompatible", "AttrDoc_ArmStreamingCompatible",
  ),
  (
    "_ZN5clang4hlsl24BuiltinTypeMethodBuilder34accessCounterHandleFieldOnResourceINS1_11PlaceHolderEEERS1_T_",
    "clang::hlsl::BuiltinTypeMethodBuilder& clang::hlsl::BuiltinTypeMethodBuilder::accessCounterHandleFieldOnResource<clang::hlsl::BuiltinTypeMethodBuilder::PlaceHolder>(clang::hlsl::BuiltinTypeMethodBuilder::PlaceHolder)",
    "clang::hlsl::BuiltinTypeMethodBuilder::accessCounterHandleFieldOnResource<clang::hlsl::BuiltinTypeMethodBuilder::PlaceHolder>",
  ),
  (
    "_ZNK13lldb_protocol3mcp4Tool13GetDefinitionEv", "lldb_protocol::mcp::Tool::GetDefinition() const",
    "lldb_protocol::mcp::Tool::GetDefinition",
  ),
  (
    "_ZTIN4mlir5spirv6detail30QueryMinVersionInterfaceTraits5ModelINS0_8CLRintOpEEE",
    "typeinfo for mlir::spirv::detail::QueryMinVersionInterfaceTraits::Model<mlir::spirv::CLRintOp>",
    "typeinfo for mlir::spirv::detail::QueryMinVersionInterfaceTraits::Model<mlir::spirv::CLRintOp>",
  ),
  (
    "_ZNK4llvm23AArch64AppleInstPrinter10getRegNameENS_10MCRegisterE", "llvm::AArch64AppleInstPrinter::getRegName(llvm::MCRegister) const",
    "llvm::AArch64AppleInstPrinter::getRegName",
  ),
  (
    "_ZN4mlir4LLVM7RoundOp5parseERNS_11OpAsmParserERNS_14OperationStateE", "mlir::LLVM::RoundOp::parse(mlir::OpAsmParser&, mlir::OperationState&)",
    "mlir::LLVM::RoundOp::parse",
  ),
  (
    "_ZNK4llvm18TargetLoweringBase36shouldFoldSelectWithIdentityConstantEjNS_3EVTEjNS_7SDValueES2_",
    "llvm::TargetLoweringBase::shouldFoldSelectWithIdentityConstant(unsigned int, llvm::EVT, unsigned int, llvm::SDValue, llvm::SDValue) const",
    "llvm::TargetLoweringBase::shouldFoldSelectWithIdentityConstant",
  ),
  (
    "_ZN5clang17CXXDestructorDecl23setOperatorGlobalDeleteEPNS_12FunctionDeclE",
    "clang::CXXDestructorDecl::setOperatorGlobalDelete(clang::FunctionDecl*)", "clang::CXXDestructorDecl::setOperatorGlobalDelete",
  ),
  (
    "_ZN4llvm7jitlink19ELFJITLinker_x86_64D1Ev", "llvm::jitlink::ELFJITLinker_x86_64::~ELFJITLinker_x86_64()",
    "llvm::jitlink::ELFJITLinker_x86_64::~ELFJITLinker_x86_64",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4LLVM7FenceOpEE15getInherentAttrEPNS_9OperationEN4llvm9StringRefE",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::FenceOp>::getInherentAttr(mlir::Operation*, llvm::StringRef)",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::FenceOp>::getInherentAttr",
  ),
  (
    "_ZNK4llvm15VETargetMachine15getSjLjDataSizeEv", "llvm::VETargetMachine::getSjLjDataSize() const",
    "llvm::VETargetMachine::getSjLjDataSize",
  ),
  (
    "_ZNK23GfxDeviceCMYKColorSpace14useGetCMYKLineEv", "GfxDeviceCMYKColorSpace::useGetCMYKLine() const",
    "GfxDeviceCMYKColorSpace::useGetCMYKLine",
  ),
  (
    "_ZN12_GLOBAL__N_138ConvertMemcpyOpToGpuRuntimeCallPatternD0Ev", "(anonymous namespace)::ConvertMemcpyOpToGpuRuntimeCallPattern::~ConvertMemcpyOpToGpuRuntimeCallPattern()",
    "(anonymous namespace)::ConvertMemcpyOpToGpuRuntimeCallPattern::~ConvertMemcpyOpToGpuRuntimeCallPattern",
  ),
  (
    "_ZN5clang14ExternalSource23completeVisibleDeclsMapEPKNS_11DeclContextE", "clang::ExternalSource::completeVisibleDeclsMap(clang::DeclContext const*)",
    "clang::ExternalSource::completeVisibleDeclsMap",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4tosa4IfOpEE22verifyRegionInvariantsEPNS_9OperationE",
    "mlir::RegisteredOperationName::Model<mlir::tosa::IfOp>::verifyRegionInvariants(mlir::Operation*)",
    "mlir::RegisteredOperationName::Model<mlir::tosa::IfOp>::verifyRegionInvariants",
  ),
  (
    "_ZN5clang12ast_matchers8internal36matcher_forEachLambdaCapture0MatcherD0Ev",
    "clang::ast_matchers::internal::matcher_forEachLambdaCapture0Matcher::~matcher_forEachLambdaCapture0Matcher()",
    "clang::ast_matchers::internal::matcher_forEachLambdaCapture0Matcher::~matcher_forEachLambdaCapture0Matcher",
  ),
  (
    "_ZTVN4mlir5spirv6detail30QueryMaxVersionInterfaceTraits5ModelINS0_6SModOpEEE",
    "vtable for mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::SModOp>",
    "vtable for mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::SModOp>",
  ),
  (
    "_ZN4mlir6detail14TypeIDResolverINS_4xevm13BlockLoad2dOpEvE2idE", "mlir::detail::TypeIDResolver<mlir::xevm::BlockLoad2dOp, void>::id",
    "mlir::detail::TypeIDResolver<mlir::xevm::BlockLoad2dOp, void>::id",
  ),
  (
    "_ZN12wasm_encoder4core12instructions15InstructionSink20i16x8_extract_lane_s17hb195afd0a76f2b8eE",
    "wasm_encoder::core::instructions::InstructionSink::i16x8_extract_lane_s::hb195afd0a76f2b8e",
    "wasm_encoder::core::instructions::InstructionSink::i16x8_extract_lane_s::hb195afd0a76f2b8e",
  ),
  (
    "_ZN4llvm6object21DXContainerObjectFileC2ENS0_11DXContainerE", "llvm::object::DXContainerObjectFile::DXContainerObjectFile(llvm::object::DXContainer)",
    "llvm::object::DXContainerObjectFile::DXContainerObjectFile",
  ),
  (
    "_ZZN3fmt3v126detail15do_count_digitsEyE20zero_or_powers_of_10", "fmt::v12::detail::do_count_digits(unsigned long long)::zero_or_powers_of_10",
    "fmt::v12::detail::do_count_digits(unsigned long long)::zero_or_powers_of_10",
  ),
  (
    "_ZTVN12_GLOBAL__N_115NegOpConversionE", "vtable for (anonymous namespace)::NegOpConversion",
    "vtable for (anonymous namespace)::NegOpConversion",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_3pdl8ResultOpEE19getPropertiesAsAttrEPNS_9OperationE",
    "mlir::RegisteredOperationName::Model<mlir::pdl::ResultOp>::getPropertiesAsAttr(mlir::Operation*)",
    "mlir::RegisteredOperationName::Model<mlir::pdl::ResultOp>::getPropertiesAsAttr",
  ),
  (
    "_ZN4mlir5spirv8SwitchOp15writePropertiesERNS_21DialectBytecodeWriterE", "mlir::spirv::SwitchOp::writeProperties(mlir::DialectBytecodeWriter&)",
    "mlir::spirv::SwitchOp::writeProperties",
  ),
  (
    "_ZN4mlir5spirv34GroupNonUniformLogicalXorOpAdaptor6verifyENS_8LocationE", "mlir::spirv::GroupNonUniformLogicalXorOpAdaptor::verify(mlir::Location)",
    "mlir::spirv::GroupNonUniformLogicalXorOpAdaptor::verify",
  ),
  (
    "_ZTIN5clang12_GLOBAL__N_18internal32matcher_canResolveToExpr0MatcherE", "typeinfo for clang::(anonymous namespace)::internal::matcher_canResolveToExpr0Matcher",
    "typeinfo for clang::(anonymous namespace)::internal::matcher_canResolveToExpr0Matcher",
  ),
  (
    "_ZNK12_GLOBAL__N_118WebAssemblyOperand5isRegEv", "(anonymous namespace)::WebAssemblyOperand::isReg() const",
    "(anonymous namespace)::WebAssemblyOperand::isReg",
  ),
  (
    "_ZTIN12lldb_private6curses18FormWindowDelegateE", "typeinfo for lldb_private::curses::FormWindowDelegate",
    "typeinfo for lldb_private::curses::FormWindowDelegate",
  ),
  (
    "_ZN4llvm11raw_ostream13SetBufferSizeEm", "llvm::raw_ostream::SetBufferSize(unsigned long)",
    "llvm::raw_ostream::SetBufferSize",
  ),
  (
    "_ZN4mlir5spirv11SLessThanOp5parseERNS_11OpAsmParserERNS_14OperationStateE",
    "mlir::spirv::SLessThanOp::parse(mlir::OpAsmParser&, mlir::OperationState&)",
    "mlir::spirv::SLessThanOp::parse",
  ),
  (
    "_ZN3smt17is_perfect_squareEPKN7grobner8monomialER8rational", "smt::is_perfect_square(grobner::monomial const*, rational&)",
    "smt::is_perfect_square",
  ),
  (
    "_ZTVN4llvm17NVPTXRegisterInfoE", "vtable for llvm::NVPTXRegisterInfo", "vtable for llvm::NVPTXRegisterInfo",
  ),
  (
    "_ZN12v8_inspector17V8InspectorClient13deepSerializeEN2v85LocalINS1_5ValueEEEiNS2_INS1_6ObjectEEE",
    "v8_inspector::V8InspectorClient::deepSerialize(v8::Local<v8::Value>, int, v8::Local<v8::Object>)",
    "v8_inspector::V8InspectorClient::deepSerialize",
  ),
  (
    "_ZN2v88internal8compiler8Verifier7Visitor5CheckEPNS1_4NodeERKNS1_8AllNodesE.cold.5",
    "v8::internal::compiler::Verifier::Visitor::Check(v8::internal::compiler::Node*, v8::internal::compiler::AllNodes const&) (.cold.5)",
    "v8::internal::compiler::Verifier::Visitor::Check",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_174AV_288_with_sub0_sub1_in_AV_64_Align2_and_AV_64_with_hi16_in_VGPR_16_Lo128E",
    "llvm::(anonymous namespace)::AV_288_with_sub0_sub1_in_AV_64_Align2_and_AV_64_with_hi16_in_VGPR_16_Lo128",
    "llvm::(anonymous namespace)::AV_288_with_sub0_sub1_in_AV_64_Align2_and_AV_64_with_hi16_in_VGPR_16_Lo128",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5index8SizeOfOpEED0Ev", "mlir::RegisteredOperationName::Model<mlir::index::SizeOfOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::index::SizeOfOp>::~Model",
  ),
  (
    "_ZN4mlir4NVVM13TotalSmemSize21computePropertiesHashERKNS_15EmptyPropertiesE",
    "mlir::NVVM::TotalSmemSize::computePropertiesHash(mlir::EmptyProperties const&)",
    "mlir::NVVM::TotalSmemSize::computePropertiesHash",
  ),
  (
    "_ZN4llvm16DAGTypeLegalizer19SplitVecRes_VP_LOADEPNS_12VPLoadSDNodeERNS_7SDValueES4_",
    "llvm::DAGTypeLegalizer::SplitVecRes_VP_LOAD(llvm::VPLoadSDNode*, llvm::SDValue&, llvm::SDValue&)",
    "llvm::DAGTypeLegalizer::SplitVecRes_VP_LOAD",
  ),
  (
    "_ZN4llvm17DominatorTreeBaseINS_17MachineBasicBlockELb0EE9eraseNodeEPS1_", "llvm::DominatorTreeBase<llvm::MachineBasicBlock, false>::eraseNode(llvm::MachineBasicBlock*)",
    "llvm::DominatorTreeBase<llvm::MachineBasicBlock, false>::eraseNode",
  ),
  (
    "_ZN4mlir5index10CeilDivUOp5parseERNS_11OpAsmParserERNS_14OperationStateE", "mlir::index::CeilDivUOp::parse(mlir::OpAsmParser&, mlir::OperationState&)",
    "mlir::index::CeilDivUOp::parse",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_9transform6PackOpEE16verifyInvariantsEPNS_9OperationE",
    "mlir::RegisteredOperationName::Model<mlir::transform::PackOp>::verifyInvariants(mlir::Operation*)",
    "mlir::RegisteredOperationName::Model<mlir::transform::PackOp>::verifyInvariants",
  ),
  (
    "_ZN4lldb9SBProcessaSERKS0_", "lldb::SBProcess::operator=(lldb::SBProcess const&)",
    "lldb::SBProcess::operator=",
  ),
  (
    "_ZN4mlir5spirv8GLUMinOp13getMinVersionEv", "mlir::spirv::GLUMinOp::getMinVersion()",
    "mlir::spirv::GLUMinOp::getMinVersion",
  ),
  (
    "_ZN4mlir5spirv8CLSMaxOp5buildERNS_9OpBuilderERNS_14OperationStateENS_4TypeENS_5ValueES7_",
    "mlir::spirv::CLSMaxOp::build(mlir::OpBuilder&, mlir::OperationState&, mlir::Type, mlir::Value, mlir::Value)",
    "mlir::spirv::CLSMaxOp::build",
  ),
  (
    "_ZN2v88internal4wasm16LiftoffAssembler10CacheState5StealERS3_", "v8::internal::wasm::LiftoffAssembler::CacheState::Steal(v8::internal::wasm::LiftoffAssembler::CacheState&)",
    "v8::internal::wasm::LiftoffAssembler::CacheState::Steal",
  ),
  (
    "_ZN12_GLOBAL__N_122UnsignedCastConversionIN4mlir5arith8TruncIOpEED0Ev", "(anonymous namespace)::UnsignedCastConversion<mlir::arith::TruncIOp>::~UnsignedCastConversion()",
    "(anonymous namespace)::UnsignedCastConversion<mlir::arith::TruncIOp>::~UnsignedCastConversion",
  ),
  (
    "_ZN12lldb_private24SearchFilterByModuleListD1Ev", "lldb_private::SearchFilterByModuleList::~SearchFilterByModuleList()",
    "lldb_private::SearchFilterByModuleList::~SearchFilterByModuleList",
  ),
  (
    "_ZTVN12_GLOBAL__N_120ParsedAttrInfoUnusedE", "vtable for (anonymous namespace)::ParsedAttrInfoUnused",
    "vtable for (anonymous namespace)::ParsedAttrInfoUnused",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4LLVM12DbgDeclareOpEE17comparePropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::DbgDeclareOp>::compareProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::DbgDeclareOp>::compareProperties",
  ),
  (
    "_ZN5clang8SemaObjC22handleIndependentClassEPNS_4DeclERKNS_10ParsedAttrE", "clang::SemaObjC::handleIndependentClass(clang::Decl*, clang::ParsedAttr const&)",
    "clang::SemaObjC::handleIndependentClass",
  ),
  (
    "_ZNSt3__15dequeIN3Gfx11DisplayTypeENS_9allocatorIS2_EEE19__add_back_capacityEv",
    "std::__1::deque<Gfx::DisplayType, std::__1::allocator<Gfx::DisplayType>>::__add_back_capacity()",
    "std::__1::deque<Gfx::DisplayType, std::__1::allocator<Gfx::DisplayType>>::__add_back_capacity",
  ),
  (
    "_ZL11getPMOVMSKBRKN4llvm5SDLocENS_7SDValueERNS_12SelectionDAGERKNS_12X86SubtargetE",
    "getPMOVMSKB(llvm::SDLoc const&, llvm::SDValue, llvm::SelectionDAG&, llvm::X86Subtarget const&)",
    "getPMOVMSKB",
  ),
  (
    "_ZN5clang19RecursiveASTVisitorIN12_GLOBAL__N_111TypeIndexerEE23TraverseUsingShadowDeclEPNS_15UsingShadowDeclE",
    "clang::RecursiveASTVisitor<(anonymous namespace)::TypeIndexer>::TraverseUsingShadowDecl(clang::UsingShadowDecl*)",
    "clang::RecursiveASTVisitor<(anonymous namespace)::TypeIndexer>::TraverseUsingShadowDecl",
  ),
  (
    "_ZN4lldb17SBTypeStaticFieldC1ERKS0_", "lldb::SBTypeStaticField::SBTypeStaticField(lldb::SBTypeStaticField const&)",
    "lldb::SBTypeStaticField::SBTypeStaticField",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_6memref6ViewOpEE8hasTraitENS_6TypeIDE",
    "mlir::RegisteredOperationName::Model<mlir::memref::ViewOp>::hasTrait(mlir::TypeID)",
    "mlir::RegisteredOperationName::Model<mlir::memref::ViewOp>::hasTrait",
  ),
  (
    "_ZN3jxl6N_NEON15UpsamplingStageC2ERKNS_19CustomTransformDataEmm", "jxl::N_NEON::UpsamplingStage::UpsamplingStage(jxl::CustomTransformData const&, unsigned long, unsigned long)",
    "jxl::N_NEON::UpsamplingStage::UpsamplingStage",
  ),
  (
    "_ZN12lldb_private13PluginManager23AutoCompleteProcessNameEN4llvm9StringRefERNS_17CompletionRequestE",
    "lldb_private::PluginManager::AutoCompleteProcessName(llvm::StringRef, lldb_private::CompletionRequest&)",
    "lldb_private::PluginManager::AutoCompleteProcessName",
  ),
  (
    "_ZN4llvm16MipsFunctionInfo16getGlobalBaseRegERNS_15MachineFunctionE", "llvm::MipsFunctionInfo::getGlobalBaseReg(llvm::MachineFunction&)",
    "llvm::MipsFunctionInfo::getGlobalBaseReg",
  ),
  (
    "_ZN12_GLOBAL__N_118MSP430DisassemblerD0Ev", "(anonymous namespace)::MSP430Disassembler::~MSP430Disassembler()",
    "(anonymous namespace)::MSP430Disassembler::~MSP430Disassembler",
  ),
  (
    "_ZN4llvmL71ZPR4_with_dsub1_in_FPR64_lo_and_ZPR4_with_dsub2_in_FPR64_loSuperclassesE",
    "llvm::ZPR4_with_dsub1_in_FPR64_lo_and_ZPR4_with_dsub2_in_FPR64_loSuperclasses",
    "llvm::ZPR4_with_dsub1_in_FPR64_lo_and_ZPR4_with_dsub2_in_FPR64_loSuperclasses",
  ),
  (
    "_ZNK4mlir5emitc4impl23WrapFuncInClassPassBaseINS0_12_GLOBAL__N_119WrapFuncInClassPassEE11getArgumentEv",
    "mlir::emitc::impl::WrapFuncInClassPassBase<mlir::emitc::(anonymous namespace)::WrapFuncInClassPass>::getArgument() const",
    "mlir::emitc::impl::WrapFuncInClassPassBase<mlir::emitc::(anonymous namespace)::WrapFuncInClassPass>::getArgument",
  ),
  (
    "_ZN4llvm10sampleprof15FunctionSamples18getCanonicalFnNameENS_9StringRefES2_",
    "llvm::sampleprof::FunctionSamples::getCanonicalFnName(llvm::StringRef, llvm::StringRef)",
    "llvm::sampleprof::FunctionSamples::getCanonicalFnName",
  ),
  (
    "_ZN3jxl6N_NEON12_GLOBAL__N_115FromLinearStageINS1_12PerChannelOpINS1_5Op709EEEED0Ev",
    "jxl::N_NEON::(anonymous namespace)::FromLinearStage<jxl::N_NEON::(anonymous namespace)::PerChannelOp<jxl::N_NEON::(anonymous namespace)::Op709>>::~FromLinearStage()",
    "jxl::N_NEON::(anonymous namespace)::FromLinearStage<jxl::N_NEON::(anonymous namespace)::PerChannelOp<jxl::N_NEON::(anonymous namespace)::Op709>>::~FromLinearStage",
  ),
  (
    "_ZN27CommandObjectTypeSummaryAddD0Ev", "CommandObjectTypeSummaryAdd::~CommandObjectTypeSummaryAdd()",
    "CommandObjectTypeSummaryAdd::~CommandObjectTypeSummaryAdd",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5ROCDL15DsLoadTr16_B128EE14copyPropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::ROCDL::DsLoadTr16_B128>::copyProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::ROCDL::DsLoadTr16_B128>::copyProperties",
  ),
  (
    "_ZN2v88internal8compiler26MachineOperatorGlobalCache27LoadImmutableUint32OperatorD0Ev",
    "v8::internal::compiler::MachineOperatorGlobalCache::LoadImmutableUint32Operator::~LoadImmutableUint32Operator()",
    "v8::internal::compiler::MachineOperatorGlobalCache::LoadImmutableUint32Operator::~LoadImmutableUint32Operator",
  ),
  (
    "_ZN4mlir9transform6detail37InsertSliceToCopyOpGenericAdaptorBaseC1ENS0_19InsertSliceToCopyOpE",
    "mlir::transform::detail::InsertSliceToCopyOpGenericAdaptorBase::InsertSliceToCopyOpGenericAdaptorBase(mlir::transform::InsertSliceToCopyOp)",
    "mlir::transform::detail::InsertSliceToCopyOpGenericAdaptorBase::InsertSliceToCopyOpGenericAdaptorBase",
  ),
  (
    "_ZNK4node8TickInfo10MemoryInfoEPNS_13MemoryTrackerE", "node::TickInfo::MemoryInfo(node::MemoryTracker*) const",
    "node::TickInfo::MemoryInfo",
  ),
  (
    "_ZN4mlir4math6AsinOp6createERNS_20ImplicitLocOpBuilderENS_10ValueRangeEN4llvm8ArrayRefINS_14NamedAttributeEEE",
    "mlir::math::AsinOp::create(mlir::ImplicitLocOpBuilder&, mlir::ValueRange, llvm::ArrayRef<mlir::NamedAttribute>)",
    "mlir::math::AsinOp::create",
  ),
  (
    "_ZNK12v8_inspector8protocol8Debugger13BreakLocation16AppendSerializedEPNSt3__16vectorIhNS3_9allocatorIhEEEE",
    "v8_inspector::protocol::Debugger::BreakLocation::AppendSerialized(std::__1::vector<unsigned char, std::__1::allocator<unsigned char>>*) const",
    "v8_inspector::protocol::Debugger::BreakLocation::AppendSerialized",
  ),
  (
    "_ZN4llvm21VPVectorPointerRecipeC2EPNS_7VPValueEPNS_4TypeENS_14GEPNoWrapFlagsENS_8DebugLocE",
    "llvm::VPVectorPointerRecipe::VPVectorPointerRecipe(llvm::VPValue*, llvm::Type*, llvm::GEPNoWrapFlags, llvm::DebugLoc)",
    "llvm::VPVectorPointerRecipe::VPVectorPointerRecipe",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4LLVM7ATan2OpEE21getOpPropertyByteSizeEv",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::ATan2Op>::getOpPropertyByteSize()",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::ATan2Op>::getOpPropertyByteSize",
  ),
  (
    "_ZTSN4mlir23RegisteredOperationName5ModelINS_4NVVM10EnvReg22OpEEE", "typeinfo name for mlir::RegisteredOperationName::Model<mlir::NVVM::EnvReg22Op>",
    "typeinfo name for mlir::RegisteredOperationName::Model<mlir::NVVM::EnvReg22Op>",
  ),
  (
    "_ZN36CommandObjectBreakpointNameConfigure9DoExecuteERN12lldb_private4ArgsERNS0_19CommandReturnObjectE",
    "CommandObjectBreakpointNameConfigure::DoExecute(lldb_private::Args&, lldb_private::CommandReturnObject&)",
    "CommandObjectBreakpointNameConfigure::DoExecute",
  ),
  (
    "_ZN2v88internal14MacroAssembler37NeedExtraInstructionsOrRegisterBranchILNS0_13ImmBranchTypeE3EEEbPNS0_5LabelE",
    "bool v8::internal::MacroAssembler::NeedExtraInstructionsOrRegisterBranch<(v8::internal::ImmBranchType)3>(v8::internal::Label*)",
    "v8::internal::MacroAssembler::NeedExtraInstructionsOrRegisterBranch<(v8::internal::ImmBranchType)3>",
  ),
  (
    "_ZNK2OT13IndexSubtable17copy_glyph_at_idxEP22hb_serialize_context_tjPKcjP11hb_vector_tIcLb0EEPS0_Pj",
    "OT::IndexSubtable::copy_glyph_at_idx(hb_serialize_context_t*, unsigned int, char const*, unsigned int, hb_vector_t<char, false>*, OT::IndexSubtable*, unsigned int*) const",
    "OT::IndexSubtable::copy_glyph_at_idx",
  ),
  (
    "_ZNK4llvm14CombinerHelper15matchTruncUSatUERNS_12MachineInstrES2_", "llvm::CombinerHelper::matchTruncUSatU(llvm::MachineInstr&, llvm::MachineInstr&) const",
    "llvm::CombinerHelper::matchTruncUSatU",
  ),
  (
    "_Z9_As_JSMapRN2v88internal6TaggedINS0_10HeapObjectEEE", "_As_JSMap(v8::internal::Tagged<v8::internal::HeapObject>&)",
    "_As_JSMap",
  ),
  (
    "_ZN13lldb_protocol3mcp6toJSONERKNS0_19ListResourcesResultE", "lldb_protocol::mcp::toJSON(lldb_protocol::mcp::ListResourcesResult const&)",
    "lldb_protocol::mcp::toJSON",
  ),
  (
    "_ZN4mlir4LLVM8FPToSIOp19getPropertiesAsAttrEPNS_11MLIRContextERKNS_15EmptyPropertiesE",
    "mlir::LLVM::FPToSIOp::getPropertiesAsAttr(mlir::MLIRContext*, mlir::EmptyProperties const&)",
    "mlir::LLVM::FPToSIOp::getPropertiesAsAttr",
  ),
  (
    "_ZN2v88internal8compiler19RawMachineAssembler4LoadENS0_11MachineTypeEPNS1_4NodeE",
    "v8::internal::compiler::RawMachineAssembler::Load(v8::internal::MachineType, v8::internal::compiler::Node*)",
    "v8::internal::compiler::RawMachineAssembler::Load",
  ),
  (
    "_ZL20buildTargetLegalLoadPN4llvm4TypeEPNS_5ValueENS_14InsertPositionEPNS_6ModuleERKNS_5TwineE",
    "buildTargetLegalLoad(llvm::Type*, llvm::Value*, llvm::InsertPosition, llvm::Module*, llvm::Twine const&)",
    "buildTargetLegalLoad",
  ),
  (
    "_ZNK4llvm4yaml11StringValueeqERKS1_", "llvm::yaml::StringValue::operator==(llvm::yaml::StringValue const&) const",
    "llvm::yaml::StringValue::operator==",
  ),
  (
    "_ZN12v8_inspector14InjectedScript14commandLineAPIEv", "v8_inspector::InjectedScript::commandLineAPI()",
    "v8_inspector::InjectedScript::commandLineAPI",
  ),
  (
    "_ZTVN12_GLOBAL__N_128ConvertIndexFloorDivSPatternE", "vtable for (anonymous namespace)::ConvertIndexFloorDivSPattern",
    "vtable for (anonymous namespace)::ConvertIndexFloorDivSPattern",
  ),
  (
    "_ZN2v88internal6maglev14Int32ToBoolean27SetValueLocationConstraintsEv", "v8::internal::maglev::Int32ToBoolean::SetValueLocationConstraints()",
    "v8::internal::maglev::Int32ToBoolean::SetValueLocationConstraints",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_5spirv8GLUMinOpEE22verifyRegionInvariantsEPNS_9OperationE",
    "mlir::RegisteredOperationName::Model<mlir::spirv::GLUMinOp>::verifyRegionInvariants(mlir::Operation*)",
    "mlir::RegisteredOperationName::Model<mlir::spirv::GLUMinOp>::verifyRegionInvariants",
  ),
  (
    "_ZN2v88internal8compiler26MachineOperatorGlobalCache18Float64PowOperatorD1Ev",
    "v8::internal::compiler::MachineOperatorGlobalCache::Float64PowOperator::~Float64PowOperator()",
    "v8::internal::compiler::MachineOperatorGlobalCache::Float64PowOperator::~Float64PowOperator",
  ),
  (
    "_ZNK4llvm22PPCPostRASchedStrategy17biasAddiCandidateERNS_20GenericSchedulerBase14SchedCandidateES3_",
    "llvm::PPCPostRASchedStrategy::biasAddiCandidate(llvm::GenericSchedulerBase::SchedCandidate&, llvm::GenericSchedulerBase::SchedCandidate&) const",
    "llvm::PPCPostRASchedStrategy::biasAddiCandidate",
  ),
  (
    "_ZZN4node8WatchdogC1EPN2v87IsolateEyPbE20error_and_abort_args_1", "node::Watchdog::Watchdog(v8::Isolate*, unsigned long long, bool*)::error_and_abort_args",
    "node::Watchdog::Watchdog(v8::Isolate*, unsigned long long, bool*)::error_and_abort_args",
  ),
  (
    "_ZN5clang30DynamicRecursiveASTVisitorBaseILb1EE23VisitConstantMatrixTypeEPKNS_18ConstantMatrixTypeE",
    "clang::DynamicRecursiveASTVisitorBase<true>::VisitConstantMatrixType(clang::ConstantMatrixType const*)",
    "clang::DynamicRecursiveASTVisitorBase<true>::VisitConstantMatrixType",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4LLVM9MemmoveOpEED1Ev", "mlir::RegisteredOperationName::Model<mlir::LLVM::MemmoveOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::LLVM::MemmoveOp>::~Model",
  ),
  (
    "_ZZN12v8_inspector8protocol8Debugger12_GLOBAL__N_122pauseOnAsyncCallParams23deserializer_descriptorEvE6fields",
    "v8_inspector::protocol::Debugger::(anonymous namespace)::pauseOnAsyncCallParams::deserializer_descriptor()::fields",
    "v8_inspector::protocol::Debugger::(anonymous namespace)::pauseOnAsyncCallParams::deserializer_descriptor()::fields",
  ),
  (
    "_ZNK4node6crypto15KeyObjectHandle15ExportPublicKeyERKN7ncrypto13EVPKeyPointer27AsymmetricKeyEncodingConfigE",
    "node::crypto::KeyObjectHandle::ExportPublicKey(ncrypto::EVPKeyPointer::AsymmetricKeyEncodingConfig const&) const",
    "node::crypto::KeyObjectHandle::ExportPublicKey",
  ),
  (
    "_ZN4mlir3gpu30SubgroupMmaInsertThreadLocalOp19getPropertiesAsAttrEPNS_11MLIRContextERKNS_15EmptyPropertiesE",
    "mlir::gpu::SubgroupMmaInsertThreadLocalOp::getPropertiesAsAttr(mlir::MLIRContext*, mlir::EmptyProperties const&)",
    "mlir::gpu::SubgroupMmaInsertThreadLocalOp::getPropertiesAsAttr",
  ),
  (
    "_ZN12smt2_printer7processEP4exprR7obj_refI3app11ast_managerE", "smt2_printer::process(expr*, obj_ref<app, ast_manager>&)",
    "smt2_printer::process",
  ),
  (
    "_ZN4mlir4NVVM22WgmmaMmaAsyncOpAdaptor6verifyENS_8LocationE", "mlir::NVVM::WgmmaMmaAsyncOpAdaptor::verify(mlir::Location)",
    "mlir::NVVM::WgmmaMmaAsyncOpAdaptor::verify",
  ),
  (
    "_ZN2v88internal33Builtin_LocalePrototypeHourCyclesEiPmPNS0_7IsolateE.cold.2",
    "v8::internal::Builtin_LocalePrototypeHourCycles(int, unsigned long*, v8::internal::Isolate*) (.cold.2)",
    "v8::internal::Builtin_LocalePrototypeHourCycles",
  ),
  (
    "_ZN12_GLOBAL__N_112_GLOBAL__N_125ScaledExtPackedOpLoweringD0Ev", "(anonymous namespace)::(anonymous namespace)::ScaledExtPackedOpLowering::~ScaledExtPackedOpLowering()",
    "(anonymous namespace)::(anonymous namespace)::ScaledExtPackedOpLowering::~ScaledExtPackedOpLowering",
  ),
  (
    "_ZNK12_GLOBAL__N_113X86AsmBackend12writeNopDataERN4llvm11raw_ostreamEyPKNS1_15MCSubtargetInfoE",
    "(anonymous namespace)::X86AsmBackend::writeNopData(llvm::raw_ostream&, unsigned long long, llvm::MCSubtargetInfo const*) const",
    "(anonymous namespace)::X86AsmBackend::writeNopData",
  ),
  (
    "_ZN4mlir7Builder16getBoolArrayAttrEN4llvm8ArrayRefIbEE", "mlir::Builder::getBoolArrayAttr(llvm::ArrayRef<bool>)",
    "mlir::Builder::getBoolArrayAttr",
  ),
  (
    "_ZN4mlir4tosa12SinOpAdaptorC1ENS0_5SinOpE", "mlir::tosa::SinOpAdaptor::SinOpAdaptor(mlir::tosa::SinOp)",
    "mlir::tosa::SinOpAdaptor::SinOpAdaptor",
  ),
  (
    "_ZN5clang7tooling13FileMatchTrieC1Ev", "clang::tooling::FileMatchTrie::FileMatchTrie()",
    "clang::tooling::FileMatchTrie::FileMatchTrie",
  ),
  (
    "_ZZN4node7tracing15NodeTraceWriter18InitializeOnThreadEP9uv_loop_sE20error_and_abort_args_1",
    "node::tracing::NodeTraceWriter::InitializeOnThread(uv_loop_s*)::error_and_abort_args",
    "node::tracing::NodeTraceWriter::InitializeOnThread(uv_loop_s*)::error_and_abort_args",
  ),
  (
    "_ZTSN12_GLOBAL__N_125PragmaClangSectionHandlerE", "typeinfo name for (anonymous namespace)::PragmaClangSectionHandler",
    "typeinfo name for (anonymous namespace)::PragmaClangSectionHandler",
  ),
  (
    "_ZNK2v88internal17SemiSpaceNewSpace23CommittedPhysicalMemoryEv", "v8::internal::SemiSpaceNewSpace::CommittedPhysicalMemory() const",
    "v8::internal::SemiSpaceNewSpace::CommittedPhysicalMemory",
  ),
  (
    "_ZNK7Imf_3_46Header18findTypedAttributeINS_14TypedAttributeIN9Imath_3_23BoxINS3_4Vec2IiEEEEEEEEPKT_PKc",
    "Imf_3_4::TypedAttribute<Imath_3_2::Box<Imath_3_2::Vec2<int>>> const* Imf_3_4::Header::findTypedAttribute<Imf_3_4::TypedAttribute<Imath_3_2::Box<Imath_3_2::Vec2<int>>>>(char const*) const",
    "Imf_3_4::Header::findTypedAttribute<Imf_3_4::TypedAttribute<Imath_3_2::Box<Imath_3_2::Vec2<int>>>>",
  ),
  (
    "_ZTSN5clang12ast_matchers8internal16MatcherInterfaceINS_17DependentNameTypeEEE",
    "typeinfo name for clang::ast_matchers::internal::MatcherInterface<clang::DependentNameType>",
    "typeinfo name for clang::ast_matchers::internal::MatcherInterface<clang::DependentNameType>",
  ),
  (
    "_ZN4mlir3acc6InitOp15writePropertiesERNS_21DialectBytecodeWriterE", "mlir::acc::InitOp::writeProperties(mlir::DialectBytecodeWriter&)",
    "mlir::acc::InitOp::writeProperties",
  ),
  (
    "_ZN4mlir5spirv5NotOp13getMaxVersionEv", "mlir::spirv::NotOp::getMaxVersion()",
    "mlir::spirv::NotOp::getMaxVersion",
  ),
  (
    "_ZN4mlir3acc19KernelEnvironmentOp14readPropertiesERNS_21DialectBytecodeReaderERNS_14OperationStateE",
    "mlir::acc::KernelEnvironmentOp::readProperties(mlir::DialectBytecodeReader&, mlir::OperationState&)",
    "mlir::acc::KernelEnvironmentOp::readProperties",
  ),
  (
    "_ZN4llvm11PassBuilder22buildO0DefaultPipelineENS_17OptimizationLevelENS_18ThinOrFullLTOPhaseE",
    "llvm::PassBuilder::buildO0DefaultPipeline(llvm::OptimizationLevel, llvm::ThinOrFullLTOPhase)",
    "llvm::PassBuilder::buildO0DefaultPipeline",
  ),
  (
    "_ZNK4llvm12MachineInstr16getDebugVariableEv", "llvm::MachineInstr::getDebugVariable() const",
    "llvm::MachineInstr::getDebugVariable",
  ),
  (
    "_ZN4mlir6detail31OpAsmOpInterfaceInterfaceTraits5ModelINS_3gpu12ClusterDimOpEE17getDefaultDialectEv",
    "mlir::detail::OpAsmOpInterfaceInterfaceTraits::Model<mlir::gpu::ClusterDimOp>::getDefaultDialect()",
    "mlir::detail::OpAsmOpInterfaceInterfaceTraits::Model<mlir::gpu::ClusterDimOp>::getDefaultDialect",
  ),
  (
    "_ZN2v88internal11FactoryBaseINS0_12LocalFactoryEE15array_to_stringEv", "v8::internal::FactoryBase<v8::internal::LocalFactory>::array_to_string()",
    "v8::internal::FactoryBase<v8::internal::LocalFactory>::array_to_string",
  ),
  (
    "_ZTSN4mlir4tosa6detail29QueryExtensionInterfaceTraits5ModelINS0_12BitwiseAndOpEEE",
    "typeinfo name for mlir::tosa::detail::QueryExtensionInterfaceTraits::Model<mlir::tosa::BitwiseAndOp>",
    "typeinfo name for mlir::tosa::detail::QueryExtensionInterfaceTraits::Model<mlir::tosa::BitwiseAndOp>",
  ),
  (
    "_ZN5clang19RecursiveASTVisitorINS_4diff12_GLOBAL__N_115PreorderVisitorEE17TraverseLabelDeclEPNS_9LabelDeclE",
    "clang::RecursiveASTVisitor<clang::diff::(anonymous namespace)::PreorderVisitor>::TraverseLabelDecl(clang::LabelDecl*)",
    "clang::RecursiveASTVisitor<clang::diff::(anonymous namespace)::PreorderVisitor>::TraverseLabelDecl",
  ),
  (
    "_ZN4mlir4tosa6detail25SliceOpGenericAdaptorBaseC1ENS0_7SliceOpE", "mlir::tosa::detail::SliceOpGenericAdaptorBase::SliceOpGenericAdaptorBase(mlir::tosa::SliceOp)",
    "mlir::tosa::detail::SliceOpGenericAdaptorBase::SliceOpGenericAdaptorBase",
  ),
  (
    "_ZN4llvm15AMDGPUSubtargetD1Ev", "llvm::AMDGPUSubtarget::~AMDGPUSubtarget()",
    "llvm::AMDGPUSubtarget::~AMDGPUSubtarget",
  ),
  (
    "_ZN4mlir4math6PowFOp5printERNS_12OpAsmPrinterE", "mlir::math::PowFOp::print(mlir::OpAsmPrinter&)",
    "mlir::math::PowFOp::print",
  ),
  (
    "_ZN10image_webp22vp8_arithmetic_decoder17ArithmeticDecoder14cold_read_flag17h41136a4535b338f2E",
    "image_webp::vp8_arithmetic_decoder::ArithmeticDecoder::cold_read_flag::h41136a4535b338f2",
    "image_webp::vp8_arithmetic_decoder::ArithmeticDecoder::cold_read_flag::h41136a4535b338f2",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_10ml_program10SubgraphOpEED1Ev",
    "mlir::RegisteredOperationName::Model<mlir::ml_program::SubgraphOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::ml_program::SubgraphOp>::~Model",
  ),
  (
    "_ZTSN12lldb_private25SymbolLocatorDebugSymbolsE", "typeinfo name for lldb_private::SymbolLocatorDebugSymbols",
    "typeinfo name for lldb_private::SymbolLocatorDebugSymbols",
  ),
  (
    "_ZN4mlir9transform21ApplyRegisteredPassOp11getPassNameEv", "mlir::transform::ApplyRegisteredPassOp::getPassName()",
    "mlir::transform::ApplyRegisteredPassOp::getPassName",
  ),
  (
    "_ZTVN4llvm13format_objectIJyymEEE", "vtable for llvm::format_object<unsigned long long, unsigned long long, unsigned long>",
    "vtable for llvm::format_object<unsigned long long, unsigned long long, unsigned long>",
  ),
  (
    "_ZN4mlir5spirv9GLAtanhOp5parseERNS_11OpAsmParserERNS_14OperationStateE", "mlir::spirv::GLAtanhOp::parse(mlir::OpAsmParser&, mlir::OperationState&)",
    "mlir::spirv::GLAtanhOp::parse",
  ),
  (
    "_ZN4mlir4LLVM13TanhOpAdaptor6verifyENS_8LocationE", "mlir::LLVM::TanhOpAdaptor::verify(mlir::Location)",
    "mlir::LLVM::TanhOpAdaptor::verify",
  ),
  (
    "_ZTSZNK12_GLOBAL__N_126AArch64InstructionSelector28selectAddrModeRegisterOffsetERN4llvm14MachineOperandEE3$_1",
    "typeinfo name for (anonymous namespace)::AArch64InstructionSelector::selectAddrModeRegisterOffset(llvm::MachineOperand&) const::$_1",
    "typeinfo name for (anonymous namespace)::AArch64InstructionSelector::selectAddrModeRegisterOffset(llvm::MachineOperand&) const::$_1",
  ),
  (
    "_ZTVN4mlir23RegisteredOperationName5ModelINS_4LLVM15AddrSpaceCastOpEEE", "vtable for mlir::RegisteredOperationName::Model<mlir::LLVM::AddrSpaceCastOp>",
    "vtable for mlir::RegisteredOperationName::Model<mlir::LLVM::AddrSpaceCastOp>",
  ),
  (
    "_ZN4mlir9transform11VectorizeOp21getVectorSizesMutableEv", "mlir::transform::VectorizeOp::getVectorSizesMutable()",
    "mlir::transform::VectorizeOp::getVectorSizesMutable",
  ),
  (
    "_ZN2v88internal19AllocationTraceNodeD1Ev", "v8::internal::AllocationTraceNode::~AllocationTraceNode()",
    "v8::internal::AllocationTraceNode::~AllocationTraceNode",
  ),
  (
    "_ZN4llvm17IntegerRangeStateD1Ev", "llvm::IntegerRangeState::~IntegerRangeState()",
    "llvm::IntegerRangeState::~IntegerRangeState",
  ),
  (
    "_ZN4mlir5spirv6detail29QueryExtensionInterfaceTraits5ModelINS0_7CLSinOpEED0Ev",
    "mlir::spirv::detail::QueryExtensionInterfaceTraits::Model<mlir::spirv::CLSinOp>::~Model()",
    "mlir::spirv::detail::QueryExtensionInterfaceTraits::Model<mlir::spirv::CLSinOp>::~Model",
  ),
  (
    "_ZN4mlir4LLVM6detail24RintOpGenericAdaptorBase20getFastmathFlagsAttrEv", "mlir::LLVM::detail::RintOpGenericAdaptorBase::getFastmathFlagsAttr()",
    "mlir::LLVM::detail::RintOpGenericAdaptorBase::getFastmathFlagsAttr",
  ),
  (
    "_ZNK5clang7targets13AVRTargetInfo20getBuiltinVaListKindEv", "clang::targets::AVRTargetInfo::getBuiltinVaListKind() const",
    "clang::targets::AVRTargetInfo::getBuiltinVaListKind",
  ),
  (
    "_ZL39_myanmar_syllable_machine_index_offsets", "_myanmar_syllable_machine_index_offsets",
    "_myanmar_syllable_machine_index_offsets",
  ),
  (
    "_ZN2v88internal39Runtime_DefineAccessorPropertyUncheckedEiPmPNS0_7IsolateE.cold.2",
    "v8::internal::Runtime_DefineAccessorPropertyUnchecked(int, unsigned long*, v8::internal::Isolate*) (.cold.2)",
    "v8::internal::Runtime_DefineAccessorPropertyUnchecked",
  ),
  (
    "_ZN4mlir5spirv6detail30QueryMinVersionInterfaceTraits5ModelINS0_8CLUMinOpEED0Ev",
    "mlir::spirv::detail::QueryMinVersionInterfaceTraits::Model<mlir::spirv::CLUMinOp>::~Model()",
    "mlir::spirv::detail::QueryMinVersionInterfaceTraits::Model<mlir::spirv::CLUMinOp>::~Model",
  ),
  (
    "_ZN4mlir6vector5FMAOp5buildERNS_9OpBuilderERNS_14OperationStateENS_4TypeENS_5ValueES7_S7_",
    "mlir::vector::FMAOp::build(mlir::OpBuilder&, mlir::OperationState&, mlir::Type, mlir::Value, mlir::Value, mlir::Value)",
    "mlir::vector::FMAOp::build",
  ),
  (
    "_ZN12_GLOBAL__N_120TypeNameValidatorCCC17ValidateCandidateERKN5clang14TypoCorrectionE",
    "(anonymous namespace)::TypeNameValidatorCCC::ValidateCandidate(clang::TypoCorrection const&)",
    "(anonymous namespace)::TypeNameValidatorCCC::ValidateCandidate",
  ),
  (
    "_ZN4mlir4tosa15Log2CeilShapeOp13getExtensionsEv", "mlir::tosa::Log2CeilShapeOp::getExtensions()",
    "mlir::tosa::Log2CeilShapeOp::getExtensions",
  ),
  (
    "_ZN5clang12ast_matchers8internal14ForEachMatcherINS_4DeclENS_4TypeEED1Ev", "clang::ast_matchers::internal::ForEachMatcher<clang::Decl, clang::Type>::~ForEachMatcher()",
    "clang::ast_matchers::internal::ForEachMatcher<clang::Decl, clang::Type>::~ForEachMatcher",
  ),
  (
    "_ZN4llvm11logicalview7LVScope22resolveReferencesChainEv", "llvm::logicalview::LVScope::resolveReferencesChain()",
    "llvm::logicalview::LVScope::resolveReferencesChain",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_3scf8ReduceOpEE14copyPropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::scf::ReduceOp>::copyProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::scf::ReduceOp>::copyProperties",
  ),
  (
    "_ZTIN4mlir23RegisteredOperationName5ModelINS_5emitc6CallOpEEE", "typeinfo for mlir::RegisteredOperationName::Model<mlir::emitc::CallOp>",
    "typeinfo for mlir::RegisteredOperationName::Model<mlir::emitc::CallOp>",
  ),
  (
    "_ZZN4mlir4irdl8RegionOp17getAttributeNamesEvE9attrNames", "mlir::irdl::RegionOp::getAttributeNames()::attrNames",
    "mlir::irdl::RegionOp::getAttributeNames()::attrNames",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_6memref9ReallocOpEE16verifyInvariantsEPNS_9OperationE",
    "mlir::RegisteredOperationName::Model<mlir::memref::ReallocOp>::verifyInvariants(mlir::Operation*)",
    "mlir::RegisteredOperationName::Model<mlir::memref::ReallocOp>::verifyInvariants",
  ),
  (
    "_ZNSt3__114__split_bufferIPiN2v88internal22RecyclingZoneAllocatorIS1_EEED2Ev",
    "std::__1::__split_buffer<int*, v8::internal::RecyclingZoneAllocator<int*>>::~__split_buffer()",
    "std::__1::__split_buffer<int*, v8::internal::RecyclingZoneAllocator<int*>>::~__split_buffer",
  ),
  (
    "_ZN4llvm3mca21AMDGPUCustomBehaviour17checkCustomHazardENS_8ArrayRefINS0_7InstRefEEERKS3_",
    "llvm::mca::AMDGPUCustomBehaviour::checkCustomHazard(llvm::ArrayRef<llvm::mca::InstRef>, llvm::mca::InstRef const&)",
    "llvm::mca::AMDGPUCustomBehaviour::checkCustomHazard",
  ),
  (
    "_ZN12_GLOBAL__N_129RedirectingFSDirRemapIterImplD1Ev", "(anonymous namespace)::RedirectingFSDirRemapIterImpl::~RedirectingFSDirRemapIterImpl()",
    "(anonymous namespace)::RedirectingFSDirRemapIterImpl::~RedirectingFSDirRemapIterImpl",
  ),
  (
    "_ZNK4llvm3rdf17TargetOperandInfo12isClobberingERKNS_12MachineInstrEj", "llvm::rdf::TargetOperandInfo::isClobbering(llvm::MachineInstr const&, unsigned int) const",
    "llvm::rdf::TargetOperandInfo::isClobbering",
  ),
  (
    "_ZNK12_GLOBAL__N_118SIFoldOperandsImpl25foldCopyToAGPRRegSequenceEPN4llvm12MachineInstrE",
    "(anonymous namespace)::SIFoldOperandsImpl::foldCopyToAGPRRegSequence(llvm::MachineInstr*) const",
    "(anonymous namespace)::SIFoldOperandsImpl::foldCopyToAGPRRegSequence",
  ),
  (
    "_ZN4mlir5spirv11UnorderedOp21computePropertiesHashERKNS_15EmptyPropertiesE",
    "mlir::spirv::UnorderedOp::computePropertiesHash(mlir::EmptyProperties const&)",
    "mlir::spirv::UnorderedOp::computePropertiesHash",
  ),
  (
    "_ZTVN4mlir23RegisteredOperationName5ModelINS_7arm_sve24ScalableMaskedSubIIntrOpEEE",
    "vtable for mlir::RegisteredOperationName::Model<mlir::arm_sve::ScalableMaskedSubIIntrOp>",
    "vtable for mlir::RegisteredOperationName::Model<mlir::arm_sve::ScalableMaskedSubIIntrOp>",
  ),
  (
    "_ZNK2v88internal17SemiSpaceNewSpace5beginEv", "v8::internal::SemiSpaceNewSpace::begin() const",
    "v8::internal::SemiSpaceNewSpace::begin",
  ),
  (
    "_ZN4mlir6affine7matcher2IfERKNSt3__18functionIFbRNS_9OperationEEEEN4llvm8ArrayRefINS0_13NestedPatternEEE",
    "mlir::affine::matcher::If(std::__1::function<bool (mlir::Operation&)> const&, llvm::ArrayRef<mlir::affine::NestedPattern>)",
    "mlir::affine::matcher::If",
  ),
  (
    "_ZN4llvm20CallGraphWrapperPass13releaseMemoryEv", "llvm::CallGraphWrapperPass::releaseMemory()",
    "llvm::CallGraphWrapperPass::releaseMemory",
  ),
  (
    "_ZN4llvm17R600SchedStrategy15AttemptFillSlotEjb", "llvm::R600SchedStrategy::AttemptFillSlot(unsigned int, bool)",
    "llvm::R600SchedStrategy::AttemptFillSlot",
  ),
  (
    "_ZTSZN4llvm18NVPTXTargetMachine28registerPassBuilderCallbacksERNS_11PassBuilderEE3$_5",
    "typeinfo name for llvm::NVPTXTargetMachine::registerPassBuilderCallbacks(llvm::PassBuilder&)::$_5",
    "typeinfo name for llvm::NVPTXTargetMachine::registerPassBuilderCallbacks(llvm::PassBuilder&)::$_5",
  ),
  (
    "_ZN16GfxLabColorSpace6getXYZEPK8GfxColorPdS3_S3_", "GfxLabColorSpace::getXYZ(GfxColor const*, double*, double*, double*)",
    "GfxLabColorSpace::getXYZ",
  ),
  (
    "_ZN4mlir5spirv6detail36AtomicIIncrementOpGenericAdaptorBaseC2ENS0_18AtomicIIncrementOpE",
    "mlir::spirv::detail::AtomicIIncrementOpGenericAdaptorBase::AtomicIIncrementOpGenericAdaptorBase(mlir::spirv::AtomicIIncrementOp)",
    "mlir::spirv::detail::AtomicIIncrementOpGenericAdaptorBase::AtomicIIncrementOpGenericAdaptorBase",
  ),
  (
    "_ZTIN5clang7targets12OSTargetInfoINS0_12VETargetInfoEEE", "typeinfo for clang::targets::OSTargetInfo<clang::targets::VETargetInfo>",
    "typeinfo for clang::targets::OSTargetInfo<clang::targets::VETargetInfo>",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_4tosa15VariableWriteOpEED1Ev", "mlir::RegisteredOperationName::Model<mlir::tosa::VariableWriteOp>::~Model()",
    "mlir::RegisteredOperationName::Model<mlir::tosa::VariableWriteOp>::~Model",
  ),
  (
    "_ZN4mlir5spirv6detail30QueryMaxVersionInterfaceTraits5ModelINS0_8GLTanhOpEED1Ev",
    "mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::GLTanhOp>::~Model()",
    "mlir::spirv::detail::QueryMaxVersionInterfaceTraits::Model<mlir::spirv::GLTanhOp>::~Model",
  ),
  (
    "_ZNK5polly4Scop10getDomainsEv", "polly::Scop::getDomains() const", "polly::Scop::getDomains",
  ),
  (
    "_ZN5clang4ento30shouldRegisterMacOSXAPICheckerERKNS0_14CheckerManagerE", "clang::ento::shouldRegisterMacOSXAPIChecker(clang::ento::CheckerManager const&)",
    "clang::ento::shouldRegisterMacOSXAPIChecker",
  ),
  (
    "_ZZN4LIEF2PE6Parser22parse_nested_relocatedINS0_7details4PE64EEENS_10ok_error_tEvEN15RelocatedStreamD1Ev",
    "LIEF::ok_error_t LIEF::PE::Parser::parse_nested_relocated<LIEF::PE::details::PE64>()::RelocatedStream::~RelocatedStream()",
    "LIEF::ok_error_t LIEF::PE::Parser::parse_nested_relocated<LIEF::PE::details::PE64>()::RelocatedStream::~RelocatedStream",
  ),
  (
    "_ZTSN5clang8EnumDeclE", "typeinfo name for clang::EnumDecl", "typeinfo name for clang::EnumDecl",
  ),
  (
    "_ZN4mlir5spirv6detail30QueryCapabilityInterfaceTraits5ModelINS0_11GroupSMinOpEED1Ev",
    "mlir::spirv::detail::QueryCapabilityInterfaceTraits::Model<mlir::spirv::GroupSMinOp>::~Model()",
    "mlir::spirv::detail::QueryCapabilityInterfaceTraits::Model<mlir::spirv::GroupSMinOp>::~Model",
  ),
  (
    "_ZN4mlir5arith7MaxSIOp19getPropertiesAsAttrEPNS_11MLIRContextERKNS_15EmptyPropertiesE",
    "mlir::arith::MaxSIOp::getPropertiesAsAttr(mlir::MLIRContext*, mlir::EmptyProperties const&)",
    "mlir::arith::MaxSIOp::getPropertiesAsAttr",
  ),
  (
    "_ZN5smtfd13theory_plugin9ast2tableEP3astP4sort", "smtfd::theory_plugin::ast2table(ast*, sort*)",
    "smtfd::theory_plugin::ast2table",
  ),
  (
    "_ZN12_GLOBAL__N_120ShapeToShapeLoweringD0Ev", "(anonymous namespace)::ShapeToShapeLowering::~ShapeToShapeLowering()",
    "(anonymous namespace)::ShapeToShapeLowering::~ShapeToShapeLowering",
  ),
  (
    "_ZN5clang13SanitizerKind9UndefinedE", "clang::SanitizerKind::Undefined", "clang::SanitizerKind::Undefined",
  ),
  (
    "_ZTSN5clang7targets14OHOSTargetInfoINS0_16X86_64TargetInfoEEE", "typeinfo name for clang::targets::OHOSTargetInfo<clang::targets::X86_64TargetInfo>",
    "typeinfo name for clang::targets::OHOSTargetInfo<clang::targets::X86_64TargetInfo>",
  ),
  (
    "_ZN4llvm12_GLOBAL__N_181AV_1024_with_sub0_sub1_sub2_sub3_sub4_sub5_sub6_sub7_in_VReg_256_Lo256_Align2BitsE",
    "llvm::(anonymous namespace)::AV_1024_with_sub0_sub1_sub2_sub3_sub4_sub5_sub6_sub7_in_VReg_256_Lo256_Align2Bits",
    "llvm::(anonymous namespace)::AV_1024_with_sub0_sub1_sub2_sub3_sub4_sub5_sub6_sub7_in_VReg_256_Lo256_Align2Bits",
  ),
  (
    "_ZN2v88internal9Assembler6subhn2ERKNS0_9VRegisterES4_S4_", "v8::internal::Assembler::subhn2(v8::internal::VRegister const&, v8::internal::VRegister const&, v8::internal::VRegister const&)",
    "v8::internal::Assembler::subhn2",
  ),
  (
    "_ZN5clang11PPCallbacks16PragmaDiagnosticENS_14SourceLocationEN4llvm9StringRefENS_4diag8SeverityES3_",
    "clang::PPCallbacks::PragmaDiagnostic(clang::SourceLocation, llvm::StringRef, clang::diag::Severity, llvm::StringRef)",
    "clang::PPCallbacks::PragmaDiagnostic",
  ),
  (
    "_ZN4mlir4LLVM6FCmpOp14readPropertiesERNS_21DialectBytecodeReaderERNS_14OperationStateE",
    "mlir::LLVM::FCmpOp::readProperties(mlir::DialectBytecodeReader&, mlir::OperationState&)",
    "mlir::LLVM::FCmpOp::readProperties",
  ),
  (
    "_ZN4mlir5spirv11SLessThanOp15getInherentAttrEPNS_11MLIRContextERKNS_15EmptyPropertiesEN4llvm9StringRefE",
    "mlir::spirv::SLessThanOp::getInherentAttr(mlir::MLIRContext*, mlir::EmptyProperties const&, llvm::StringRef)",
    "mlir::spirv::SLessThanOp::getInherentAttr",
  ),
  (
    "_ZTIN12lldb_private9CloneableINS_16OptionValueArrayENS_11OptionValueEEE", "typeinfo for lldb_private::Cloneable<lldb_private::OptionValueArray, lldb_private::OptionValue>",
    "typeinfo for lldb_private::Cloneable<lldb_private::OptionValueArray, lldb_private::OptionValue>",
  ),
  (
    "_ZN4mlir6detail14TypeIDResolverINS_5spirv27GroupNonUniformLogicalXorOpEvE2idE",
    "mlir::detail::TypeIDResolver<mlir::spirv::GroupNonUniformLogicalXorOp, void>::id",
    "mlir::detail::TypeIDResolver<mlir::spirv::GroupNonUniformLogicalXorOp, void>::id",
  ),
  (
    "_ZN4mlir6affine13AffineYieldOp6createERNS_20ImplicitLocOpBuilderENS_10ValueRangeE",
    "mlir::affine::AffineYieldOp::create(mlir::ImplicitLocOpBuilder&, mlir::ValueRange)",
    "mlir::affine::AffineYieldOp::create",
  ),
  (
    "_ZN5clang14SYCLKernelAttr6CreateERNS_10ASTContextENS_11SourceRangeENS0_8SpellingE",
    "clang::SYCLKernelAttr::Create(clang::ASTContext&, clang::SourceRange, clang::SYCLKernelAttr::Spelling)",
    "clang::SYCLKernelAttr::Create",
  ),
  (
    "_ZNK12_GLOBAL__N_113NVPTXPeephole16getAnalysisUsageERN4llvm13AnalysisUsageE",
    "(anonymous namespace)::NVPTXPeephole::getAnalysisUsage(llvm::AnalysisUsage&) const",
    "(anonymous namespace)::NVPTXPeephole::getAnalysisUsage",
  ),
  (
    "_ZTSN12_GLOBAL__N_119AwaitOpLoweringBaseIN4mlir5async7AwaitOpENS2_9ValueTypeEEE",
    "typeinfo name for (anonymous namespace)::AwaitOpLoweringBase<mlir::async::AwaitOp, mlir::async::ValueType>",
    "typeinfo name for (anonymous namespace)::AwaitOpLoweringBase<mlir::async::AwaitOp, mlir::async::ValueType>",
  ),
  (
    "_ZN4mlir4LLVM18vector_reduce_smax6createERNS_20ImplicitLocOpBuilderENS_9TypeRangeENS_5ValueE",
    "mlir::LLVM::vector_reduce_smax::create(mlir::ImplicitLocOpBuilder&, mlir::TypeRange, mlir::Value)",
    "mlir::LLVM::vector_reduce_smax::create",
  ),
  (
    "_ZTIN12_GLOBAL__N_123AAValueSimplifyFunctionE", "typeinfo for (anonymous namespace)::AAValueSimplifyFunction",
    "typeinfo for (anonymous namespace)::AAValueSimplifyFunction",
  ),
  (
    "_ZTI15ProcessMachCore", "typeinfo for ProcessMachCore", "typeinfo for ProcessMachCore",
  ),
  (
    "_ZTSN5clang4ento13SymbolVisitorE", "typeinfo name for clang::ento::SymbolVisitor",
    "typeinfo name for clang::ento::SymbolVisitor",
  ),
  (
    "_ZN6semver5parse21prerelease_identifier17h348b3865fdb22163E", "semver::parse::prerelease_identifier::h348b3865fdb22163",
    "semver::parse::prerelease_identifier::h348b3865fdb22163",
  ),
  (
    "_ZN26CommandObjectPluginDisableD0Ev", "CommandObjectPluginDisable::~CommandObjectPluginDisable()",
    "CommandObjectPluginDisable::~CommandObjectPluginDisable",
  ),
  (
    "_ZN12_GLOBAL__N_117ExprEvaluatorBaseINS_20ComplexExprEvaluatorEE17VisitConstantExprEPKN5clang12ConstantExprE",
    "(anonymous namespace)::ExprEvaluatorBase<(anonymous namespace)::ComplexExprEvaluator>::VisitConstantExpr(clang::ConstantExpr const*)",
    "(anonymous namespace)::ExprEvaluatorBase<(anonymous namespace)::ComplexExprEvaluator>::VisitConstantExpr",
  ),
  (
    "_ZN4mlir6affine6detail34AffineParallelOpGenericAdaptorBaseC2ENS0_16AffineParallelOpE",
    "mlir::affine::detail::AffineParallelOpGenericAdaptorBase::AffineParallelOpGenericAdaptorBase(mlir::affine::AffineParallelOp)",
    "mlir::affine::detail::AffineParallelOpGenericAdaptorBase::AffineParallelOpGenericAdaptorBase",
  ),
  (
    "_ZTIN4llvm2cl15OptionValueCopyIN4mlir4tosa5LevelEEE", "typeinfo for llvm::cl::OptionValueCopy<mlir::tosa::Level>",
    "typeinfo for llvm::cl::OptionValueCopy<mlir::tosa::Level>",
  ),
  (
    "_ZN4mlir4impl19TosaToArithPassBaseIN12_GLOBAL__N_111TosaToArithEED1Ev", "mlir::impl::TosaToArithPassBase<(anonymous namespace)::TosaToArith>::~TosaToArithPassBase()",
    "mlir::impl::TosaToArithPassBase<(anonymous namespace)::TosaToArith>::~TosaToArithPassBase",
  ),
  (
    "_ZNK5clang4ento15CheckerRegistry17initializeManagerERNS0_14CheckerManagerE",
    "clang::ento::CheckerRegistry::initializeManager(clang::ento::CheckerManager&) const",
    "clang::ento::CheckerRegistry::initializeManager",
  ),
  (
    "_ZZN4mlir13sparse_tensor13ConcatenateOp17getAttributeNamesEvE9attrNames", "mlir::sparse_tensor::ConcatenateOp::getAttributeNames()::attrNames",
    "mlir::sparse_tensor::ConcatenateOp::getAttributeNames()::attrNames",
  ),
  (
    "_ZN4mlir23RegisteredOperationName5ModelINS_7arm_sve13WhileLTIntrOpEE14copyPropertiesENS_16OpaquePropertiesES5_",
    "mlir::RegisteredOperationName::Model<mlir::arm_sve::WhileLTIntrOp>::copyProperties(mlir::OpaqueProperties, mlir::OpaqueProperties)",
    "mlir::RegisteredOperationName::Model<mlir::arm_sve::WhileLTIntrOp>::copyProperties",
  ),
  (
    "_ZTIN4llvm6detail9PassModelINS_15MachineFunctionENS_20X86LowerTileCopyPassENS_15AnalysisManagerIS2_JEEEJEEE",
    "typeinfo for llvm::detail::PassModel<llvm::MachineFunction, llvm::X86LowerTileCopyPass, llvm::AnalysisManager<llvm::MachineFunction>>",
    "typeinfo for llvm::detail::PassModel<llvm::MachineFunction, llvm::X86LowerTileCopyPass, llvm::AnalysisManager<llvm::MachineFunction>>",
  ),
  (
    "_ZN4mlir4LLVM6UDivOp6createERNS_20ImplicitLocOpBuilderENS_4TypeENS_5ValueES5_NS_8UnitAttrE",
    "mlir::LLVM::UDivOp::create(mlir::ImplicitLocOpBuilder&, mlir::Type, mlir::Value, mlir::Value, mlir::UnitAttr)",
    "mlir::LLVM::UDivOp::create",
  ),
]
