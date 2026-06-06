///|
pub(all) enum DwarfWordSize {
  W32
  W64
} derive(Eq, Debug)

///|
pub(all) enum DwarfLenspec {
  DwarfOne
  DwarfTwo
  DwarfFour
  DwarfEight
  DwarfLeb128
} derive(Eq, Debug)

///|
pub fn DwarfLenspec::leb128() -> DwarfLenspec {
  DwarfLeb128
}

///|
pub fn DwarfLenspec::one() -> DwarfLenspec {
  DwarfOne
}

///|
pub fn DwarfLenspec::two() -> DwarfLenspec {
  DwarfTwo
}

///|
pub fn DwarfLenspec::four() -> DwarfLenspec {
  DwarfFour
}

///|
pub fn DwarfLenspec::eight() -> DwarfLenspec {
  DwarfEight
}

///|
pub(all) enum DwarfIndexSpec {
  DwarfIndexLeb128
  DwarfIndexOne
  DwarfIndexTwo
  DwarfIndexThree
  DwarfIndexFour
} derive(Eq, Debug)

///|
pub(all) enum DwarfTag {
  DwarfArrayType
  DwarfClassType
  DwarfEntryPoint
  DwarfEnumerationType
  DwarfFormalParameter
  DwarfImportedDeclaration
  DwarfLabel
  DwarfCompileUnit
  DwarfPartialUnit
  DwarfLexicalBlock
  DwarfMember
  DwarfPointerType
  DwarfReferenceType
  DwarfStringType
  DwarfStructureType
  DwarfSubroutineType
  DwarfTypedef
  DwarfUnionType
  DwarfUnspecifiedParameters
  DwarfVariant
  DwarfCommonBlock
  DwarfCommonInclusion
  DwarfInheritance
  DwarfInlinedSubroutine
  DwarfModule
  DwarfPtrToMemberType
  DwarfSetType
  DwarfSubrangeType
  DwarfWithStmt
  DwarfAccessDeclaration
  DwarfBaseType
  DwarfCatchBlock
  DwarfConstType
  DwarfConstant
  DwarfEnumerator
  DwarfFileType
  DwarfFriend
  DwarfNamelist
  DwarfNamelistItem
  DwarfPackedType
  DwarfSubprogram
  DwarfTemplateTypeParameter
  DwarfTemplateValueParameter
  DwarfThrownType
  DwarfTryBlock
  DwarfVariantPart
  DwarfVariable
  DwarfVolatileType
  DwarfProcedure
  DwarfRestrictType
  DwarfInterfaceType
  DwarfNamespace
  DwarfImportedModule
  DwarfUnspecifiedType
  DwarfImportedUnit
  DwarfCondition
  DwarfSharedType
  DwarfTypeUnit
  DwarfRvalueReferenceType
  DwarfTemplateAlias
  DwarfCoarrayType
  DwarfGenericSubrange
  DwarfDynamicType
  DwarfAtomicType
  DwarfCallSite
  DwarfCallSiteParameter
  DwarfSkeletonUnit
  DwarfImmutableType
  DwarfUnknownTag(Int)
} derive(Eq, Debug)

///|
pub fn DwarfTag::array_type() -> DwarfTag {
  DwarfArrayType
}

///|
pub fn DwarfTag::class_type() -> DwarfTag {
  DwarfClassType
}

///|
pub fn DwarfTag::entry_point() -> DwarfTag {
  DwarfEntryPoint
}

///|
pub fn DwarfTag::enumeration_type() -> DwarfTag {
  DwarfEnumerationType
}

///|
pub fn DwarfTag::formal_parameter() -> DwarfTag {
  DwarfFormalParameter
}

///|
pub fn DwarfTag::imported_declaration() -> DwarfTag {
  DwarfImportedDeclaration
}

///|
pub fn DwarfTag::label() -> DwarfTag {
  DwarfLabel
}

///|
pub fn DwarfTag::compile_unit() -> DwarfTag {
  DwarfCompileUnit
}

///|
pub fn DwarfTag::partial_unit() -> DwarfTag {
  DwarfPartialUnit
}

///|
pub fn DwarfTag::lexical_block() -> DwarfTag {
  DwarfLexicalBlock
}

///|
pub fn DwarfTag::member_() -> DwarfTag {
  DwarfMember
}

///|
pub fn DwarfTag::pointer_type() -> DwarfTag {
  DwarfPointerType
}

///|
pub fn DwarfTag::reference_type() -> DwarfTag {
  DwarfReferenceType
}

///|
pub fn DwarfTag::string_type() -> DwarfTag {
  DwarfStringType
}

///|
pub fn DwarfTag::structure_type() -> DwarfTag {
  DwarfStructureType
}

///|
pub fn DwarfTag::subroutine_type() -> DwarfTag {
  DwarfSubroutineType
}

///|
pub fn DwarfTag::typedef_() -> DwarfTag {
  DwarfTypedef
}

///|
pub fn DwarfTag::union_type() -> DwarfTag {
  DwarfUnionType
}

///|
pub fn DwarfTag::unspecified_parameters() -> DwarfTag {
  DwarfUnspecifiedParameters
}

///|
pub fn DwarfTag::variant() -> DwarfTag {
  DwarfVariant
}

///|
pub fn DwarfTag::common_block() -> DwarfTag {
  DwarfCommonBlock
}

///|
pub fn DwarfTag::common_inclusion() -> DwarfTag {
  DwarfCommonInclusion
}

///|
pub fn DwarfTag::inheritance() -> DwarfTag {
  DwarfInheritance
}

///|
pub fn DwarfTag::inlined_subroutine() -> DwarfTag {
  DwarfInlinedSubroutine
}

///|
pub fn DwarfTag::module_() -> DwarfTag {
  DwarfModule
}

///|
pub fn DwarfTag::ptr_to_member_type() -> DwarfTag {
  DwarfPtrToMemberType
}

///|
pub fn DwarfTag::set_type() -> DwarfTag {
  DwarfSetType
}

///|
pub fn DwarfTag::subrange_type() -> DwarfTag {
  DwarfSubrangeType
}

///|
pub fn DwarfTag::with_stmt() -> DwarfTag {
  DwarfWithStmt
}

///|
pub fn DwarfTag::access_declaration() -> DwarfTag {
  DwarfAccessDeclaration
}

///|
pub fn DwarfTag::base_type() -> DwarfTag {
  DwarfBaseType
}

///|
pub fn DwarfTag::catch_block() -> DwarfTag {
  DwarfCatchBlock
}

///|
pub fn DwarfTag::const_type() -> DwarfTag {
  DwarfConstType
}

///|
pub fn DwarfTag::constant() -> DwarfTag {
  DwarfConstant
}

///|
pub fn DwarfTag::enumerator() -> DwarfTag {
  DwarfEnumerator
}

///|
pub fn DwarfTag::file_type() -> DwarfTag {
  DwarfFileType
}

///|
pub fn DwarfTag::friend() -> DwarfTag {
  DwarfFriend
}

///|
pub fn DwarfTag::namelist() -> DwarfTag {
  DwarfNamelist
}

///|
pub fn DwarfTag::namelist_item() -> DwarfTag {
  DwarfNamelistItem
}

///|
pub fn DwarfTag::packed_type() -> DwarfTag {
  DwarfPackedType
}

///|
pub fn DwarfTag::subprogram() -> DwarfTag {
  DwarfSubprogram
}

///|
pub fn DwarfTag::template_type_parameter() -> DwarfTag {
  DwarfTemplateTypeParameter
}

///|
pub fn DwarfTag::template_value_parameter() -> DwarfTag {
  DwarfTemplateValueParameter
}

///|
pub fn DwarfTag::thrown_type() -> DwarfTag {
  DwarfThrownType
}

///|
pub fn DwarfTag::try_block() -> DwarfTag {
  DwarfTryBlock
}

///|
pub fn DwarfTag::variant_part() -> DwarfTag {
  DwarfVariantPart
}

///|
pub fn DwarfTag::variable() -> DwarfTag {
  DwarfVariable
}

///|
pub fn DwarfTag::volatile_type() -> DwarfTag {
  DwarfVolatileType
}

///|
pub fn DwarfTag::procedure() -> DwarfTag {
  DwarfProcedure
}

///|
pub fn DwarfTag::restrict_type() -> DwarfTag {
  DwarfRestrictType
}

///|
pub fn DwarfTag::interface_type() -> DwarfTag {
  DwarfInterfaceType
}

///|
pub fn DwarfTag::namespace_() -> DwarfTag {
  DwarfNamespace
}

///|
pub fn DwarfTag::imported_module() -> DwarfTag {
  DwarfImportedModule
}

///|
pub fn DwarfTag::unspecified_type() -> DwarfTag {
  DwarfUnspecifiedType
}

///|
pub fn DwarfTag::imported_unit() -> DwarfTag {
  DwarfImportedUnit
}

///|
pub fn DwarfTag::condition() -> DwarfTag {
  DwarfCondition
}

///|
pub fn DwarfTag::shared_type() -> DwarfTag {
  DwarfSharedType
}

///|
pub fn DwarfTag::type_unit() -> DwarfTag {
  DwarfTypeUnit
}

///|
pub fn DwarfTag::rvalue_reference_type() -> DwarfTag {
  DwarfRvalueReferenceType
}

///|
pub fn DwarfTag::template_alias() -> DwarfTag {
  DwarfTemplateAlias
}

///|
pub fn DwarfTag::coarray_type() -> DwarfTag {
  DwarfCoarrayType
}

///|
pub fn DwarfTag::generic_subrange() -> DwarfTag {
  DwarfGenericSubrange
}

///|
pub fn DwarfTag::dynamic_type() -> DwarfTag {
  DwarfDynamicType
}

///|
pub fn DwarfTag::atomic_type() -> DwarfTag {
  DwarfAtomicType
}

///|
pub fn DwarfTag::call_site() -> DwarfTag {
  DwarfCallSite
}

///|
pub fn DwarfTag::call_site_parameter() -> DwarfTag {
  DwarfCallSiteParameter
}

///|
pub fn DwarfTag::skeleton_unit() -> DwarfTag {
  DwarfSkeletonUnit
}

///|
pub fn DwarfTag::immutable_type() -> DwarfTag {
  DwarfImmutableType
}

///|
pub fn DwarfTag::unknown(code : Int) -> DwarfTag {
  DwarfUnknownTag(code)
}

///|
pub(all) enum DwarfAttr {
  DwarfSibling
  DwarfLocation
  DwarfName
  DwarfOrdering
  DwarfByteSize
  DwarfBitOffset
  DwarfBitSize
  DwarfStmtList
  DwarfLowPc
  DwarfHighPc
  DwarfLanguage
  DwarfDiscr
  DwarfDiscrValue
  DwarfVisibility
  DwarfImport
  DwarfStringLength
  DwarfCommonReference
  DwarfCompDir
  DwarfConstValue
  DwarfContainingType
  DwarfDefaultValue
  DwarfInline
  DwarfIsOptional
  DwarfLowerBound
  DwarfProducer
  DwarfPrototyped
  DwarfReturnAddr
  DwarfStartScope
  DwarfBitStride
  DwarfUpperBound
  DwarfAbstractOrigin
  DwarfAccessibility
  DwarfAddressClass
  DwarfArtificial
  DwarfBaseTypes
  DwarfCallingConvention
  DwarfCount
  DwarfDataMemberLocation
  DwarfDeclColumn
  DwarfDeclFile
  DwarfDeclLine
  DwarfDeclaration
  DwarfDiscrList
  DwarfEncoding
  DwarfExternal
  DwarfFrameBase
  DwarfFriend
  DwarfIdentifierCase
  DwarfMacroInfo
  DwarfNamelistItem
  DwarfPriority
  DwarfSegment
  DwarfSpecification
  DwarfStaticLink
  DwarfType
  DwarfUseLocation
  DwarfVariableParameter
  DwarfVirtuality
  DwarfVtableElemLocation
  DwarfAllocated
  DwarfAssociated
  DwarfDataLocation
  DwarfByteStride
  DwarfEntryPc
  DwarfUseUtf8
  DwarfExtension
  DwarfRanges
  DwarfTrampoline
  DwarfCallColumn
  DwarfCallFile
  DwarfCallLine
  DwarfDescription
  DwarfBinaryScale
  DwarfDecimalScale
  DwarfSmall
  DwarfDecimalSign
  DwarfDigitCount
  DwarfPictureString
  DwarfMutable
  DwarfThreadsScaled
  DwarfExplicit
  DwarfObjectPointer
  DwarfEndianity
  DwarfElemental
  DwarfPure
  DwarfRecursive
  DwarfSignature
  DwarfMainSubprogram
  DwarfDataBitOffset
  DwarfConstExpr
  DwarfEnumClass
  DwarfLinkageName
  DwarfStringLengthBitSize
  DwarfStringLengthByteSize
  DwarfRank
  DwarfStrOffsetsBase
  DwarfAddrBase
  DwarfRnglistsBase
  DwarfDwoId
  DwarfDwoName
  DwarfReference
  DwarfRvalueReference
  DwarfMacros
  DwarfCallAllCalls
  DwarfCallAllSourceCalls
  DwarfCallAllTailCalls
  DwarfCallReturnPc
  DwarfCallValue
  DwarfCallOrigin
  DwarfCallParameter
  DwarfCallPc
  DwarfCallTailCall
  DwarfCallTarget
  DwarfCallTargetClobbered
  DwarfCallDataLocation
  DwarfCallDataValue
  DwarfNoreturn
  DwarfAlignment
  DwarfExportSymbols
  DwarfDeleted
  DwarfDefaulted
  DwarfLoclistsBase
  DwarfRangesBase
  DwarfUnknownAttr(Int)
} derive(Eq, Debug)

///|
pub fn DwarfAttr::sibling() -> DwarfAttr {
  DwarfSibling
}

///|
pub fn DwarfAttr::location() -> DwarfAttr {
  DwarfLocation
}

///|
pub fn DwarfAttr::name() -> DwarfAttr {
  DwarfName
}

///|
pub fn DwarfAttr::ordering() -> DwarfAttr {
  DwarfOrdering
}

///|
pub fn DwarfAttr::byte_size() -> DwarfAttr {
  DwarfByteSize
}

///|
pub fn DwarfAttr::bit_offset() -> DwarfAttr {
  DwarfBitOffset
}

///|
pub fn DwarfAttr::bit_size() -> DwarfAttr {
  DwarfBitSize
}

///|
pub fn DwarfAttr::stmt_list() -> DwarfAttr {
  DwarfStmtList
}

///|
pub fn DwarfAttr::low_pc() -> DwarfAttr {
  DwarfLowPc
}

///|
pub fn DwarfAttr::high_pc() -> DwarfAttr {
  DwarfHighPc
}

///|
pub fn DwarfAttr::language() -> DwarfAttr {
  DwarfLanguage
}

///|
pub fn DwarfAttr::discr() -> DwarfAttr {
  DwarfDiscr
}

///|
pub fn DwarfAttr::discr_value() -> DwarfAttr {
  DwarfDiscrValue
}

///|
pub fn DwarfAttr::visibility() -> DwarfAttr {
  DwarfVisibility
}

///|
pub fn DwarfAttr::import_() -> DwarfAttr {
  DwarfImport
}

///|
pub fn DwarfAttr::string_length() -> DwarfAttr {
  DwarfStringLength
}

///|
pub fn DwarfAttr::common_reference() -> DwarfAttr {
  DwarfCommonReference
}

///|
pub fn DwarfAttr::comp_dir() -> DwarfAttr {
  DwarfCompDir
}

///|
pub fn DwarfAttr::const_value() -> DwarfAttr {
  DwarfConstValue
}

///|
pub fn DwarfAttr::containing_type() -> DwarfAttr {
  DwarfContainingType
}

///|
pub fn DwarfAttr::default_value() -> DwarfAttr {
  DwarfDefaultValue
}

///|
pub fn DwarfAttr::inline_() -> DwarfAttr {
  DwarfInline
}

///|
pub fn DwarfAttr::is_optional() -> DwarfAttr {
  DwarfIsOptional
}

///|
pub fn DwarfAttr::lower_bound() -> DwarfAttr {
  DwarfLowerBound
}

///|
pub fn DwarfAttr::producer() -> DwarfAttr {
  DwarfProducer
}

///|
pub fn DwarfAttr::prototyped() -> DwarfAttr {
  DwarfPrototyped
}

///|
pub fn DwarfAttr::return_addr() -> DwarfAttr {
  DwarfReturnAddr
}

///|
pub fn DwarfAttr::start_scope() -> DwarfAttr {
  DwarfStartScope
}

///|
pub fn DwarfAttr::bit_stride() -> DwarfAttr {
  DwarfBitStride
}

///|
pub fn DwarfAttr::upper_bound() -> DwarfAttr {
  DwarfUpperBound
}

///|
pub fn DwarfAttr::abstract_origin() -> DwarfAttr {
  DwarfAbstractOrigin
}

///|
pub fn DwarfAttr::accessibility() -> DwarfAttr {
  DwarfAccessibility
}

///|
pub fn DwarfAttr::address_class() -> DwarfAttr {
  DwarfAddressClass
}

///|
pub fn DwarfAttr::artificial() -> DwarfAttr {
  DwarfArtificial
}

///|
pub fn DwarfAttr::base_types() -> DwarfAttr {
  DwarfBaseTypes
}

///|
pub fn DwarfAttr::calling_convention() -> DwarfAttr {
  DwarfCallingConvention
}

///|
pub fn DwarfAttr::count() -> DwarfAttr {
  DwarfCount
}

///|
pub fn DwarfAttr::data_member_location() -> DwarfAttr {
  DwarfDataMemberLocation
}

///|
pub fn DwarfAttr::decl_column() -> DwarfAttr {
  DwarfDeclColumn
}

///|
pub fn DwarfAttr::decl_file() -> DwarfAttr {
  DwarfDeclFile
}

///|
pub fn DwarfAttr::decl_line() -> DwarfAttr {
  DwarfDeclLine
}

///|
pub fn DwarfAttr::declaration() -> DwarfAttr {
  DwarfDeclaration
}

///|
pub fn DwarfAttr::discr_list() -> DwarfAttr {
  DwarfDiscrList
}

///|
pub fn DwarfAttr::encoding() -> DwarfAttr {
  DwarfEncoding
}

///|
pub fn DwarfAttr::external() -> DwarfAttr {
  DwarfExternal
}

///|
pub fn DwarfAttr::frame_base() -> DwarfAttr {
  DwarfFrameBase
}

///|
pub fn DwarfAttr::friend() -> DwarfAttr {
  DwarfFriend
}

///|
pub fn DwarfAttr::identifier_case() -> DwarfAttr {
  DwarfIdentifierCase
}

///|
pub fn DwarfAttr::macro_info() -> DwarfAttr {
  DwarfMacroInfo
}

///|
pub fn DwarfAttr::namelist_item() -> DwarfAttr {
  DwarfNamelistItem
}

///|
pub fn DwarfAttr::priority() -> DwarfAttr {
  DwarfPriority
}

///|
pub fn DwarfAttr::segment() -> DwarfAttr {
  DwarfSegment
}

///|
pub fn DwarfAttr::specification() -> DwarfAttr {
  DwarfSpecification
}

///|
pub fn DwarfAttr::static_link() -> DwarfAttr {
  DwarfStaticLink
}

///|
pub fn DwarfAttr::type_() -> DwarfAttr {
  DwarfType
}

///|
pub fn DwarfAttr::use_location() -> DwarfAttr {
  DwarfUseLocation
}

///|
pub fn DwarfAttr::variable_parameter() -> DwarfAttr {
  DwarfVariableParameter
}

///|
pub fn DwarfAttr::virtuality() -> DwarfAttr {
  DwarfVirtuality
}

///|
pub fn DwarfAttr::vtable_elem_location() -> DwarfAttr {
  DwarfVtableElemLocation
}

///|
pub fn DwarfAttr::allocated() -> DwarfAttr {
  DwarfAllocated
}

///|
pub fn DwarfAttr::associated() -> DwarfAttr {
  DwarfAssociated
}

///|
pub fn DwarfAttr::data_location() -> DwarfAttr {
  DwarfDataLocation
}

///|
pub fn DwarfAttr::byte_stride() -> DwarfAttr {
  DwarfByteStride
}

///|
pub fn DwarfAttr::entry_pc() -> DwarfAttr {
  DwarfEntryPc
}

///|
pub fn DwarfAttr::use_utf8() -> DwarfAttr {
  DwarfUseUtf8
}

///|
pub fn DwarfAttr::extension() -> DwarfAttr {
  DwarfExtension
}

///|
pub fn DwarfAttr::ranges() -> DwarfAttr {
  DwarfRanges
}

///|
pub fn DwarfAttr::trampoline() -> DwarfAttr {
  DwarfTrampoline
}

///|
pub fn DwarfAttr::call_column() -> DwarfAttr {
  DwarfCallColumn
}

///|
pub fn DwarfAttr::call_file() -> DwarfAttr {
  DwarfCallFile
}

///|
pub fn DwarfAttr::call_line() -> DwarfAttr {
  DwarfCallLine
}

///|
pub fn DwarfAttr::description() -> DwarfAttr {
  DwarfDescription
}

///|
pub fn DwarfAttr::binary_scale() -> DwarfAttr {
  DwarfBinaryScale
}

///|
pub fn DwarfAttr::decimal_scale() -> DwarfAttr {
  DwarfDecimalScale
}

///|
pub fn DwarfAttr::small() -> DwarfAttr {
  DwarfSmall
}

///|
pub fn DwarfAttr::decimal_sign() -> DwarfAttr {
  DwarfDecimalSign
}

///|
pub fn DwarfAttr::digit_count() -> DwarfAttr {
  DwarfDigitCount
}

///|
pub fn DwarfAttr::picture_string() -> DwarfAttr {
  DwarfPictureString
}

///|
pub fn DwarfAttr::mutable_() -> DwarfAttr {
  DwarfMutable
}

///|
pub fn DwarfAttr::threads_scaled() -> DwarfAttr {
  DwarfThreadsScaled
}

///|
pub fn DwarfAttr::explicit_() -> DwarfAttr {
  DwarfExplicit
}

///|
pub fn DwarfAttr::object_pointer() -> DwarfAttr {
  DwarfObjectPointer
}

///|
pub fn DwarfAttr::endianity() -> DwarfAttr {
  DwarfEndianity
}

///|
pub fn DwarfAttr::elemental() -> DwarfAttr {
  DwarfElemental
}

///|
pub fn DwarfAttr::pure() -> DwarfAttr {
  DwarfPure
}

///|
pub fn DwarfAttr::recursive() -> DwarfAttr {
  DwarfRecursive
}

///|
pub fn DwarfAttr::signature() -> DwarfAttr {
  DwarfSignature
}

///|
pub fn DwarfAttr::main_subprogram() -> DwarfAttr {
  DwarfMainSubprogram
}

///|
pub fn DwarfAttr::data_bit_offset() -> DwarfAttr {
  DwarfDataBitOffset
}

///|
pub fn DwarfAttr::const_expr() -> DwarfAttr {
  DwarfConstExpr
}

///|
pub fn DwarfAttr::enum_class() -> DwarfAttr {
  DwarfEnumClass
}

///|
pub fn DwarfAttr::linkage_name() -> DwarfAttr {
  DwarfLinkageName
}

///|
pub fn DwarfAttr::string_length_bit_size() -> DwarfAttr {
  DwarfStringLengthBitSize
}

///|
pub fn DwarfAttr::string_length_byte_size() -> DwarfAttr {
  DwarfStringLengthByteSize
}

///|
pub fn DwarfAttr::rank() -> DwarfAttr {
  DwarfRank
}

///|
pub fn DwarfAttr::str_offsets_base() -> DwarfAttr {
  DwarfStrOffsetsBase
}

///|
pub fn DwarfAttr::addr_base() -> DwarfAttr {
  DwarfAddrBase
}

///|
pub fn DwarfAttr::rnglists_base() -> DwarfAttr {
  DwarfRnglistsBase
}

///|
pub fn DwarfAttr::dwo_id() -> DwarfAttr {
  DwarfDwoId
}

///|
pub fn DwarfAttr::dwo_name() -> DwarfAttr {
  DwarfDwoName
}

///|
pub fn DwarfAttr::reference() -> DwarfAttr {
  DwarfReference
}

///|
pub fn DwarfAttr::rvalue_reference() -> DwarfAttr {
  DwarfRvalueReference
}

///|
pub fn DwarfAttr::macros() -> DwarfAttr {
  DwarfMacros
}

///|
pub fn DwarfAttr::call_all_calls() -> DwarfAttr {
  DwarfCallAllCalls
}

///|
pub fn DwarfAttr::call_all_source_calls() -> DwarfAttr {
  DwarfCallAllSourceCalls
}

///|
pub fn DwarfAttr::call_all_tail_calls() -> DwarfAttr {
  DwarfCallAllTailCalls
}

///|
pub fn DwarfAttr::call_return_pc() -> DwarfAttr {
  DwarfCallReturnPc
}

///|
pub fn DwarfAttr::call_value() -> DwarfAttr {
  DwarfCallValue
}

///|
pub fn DwarfAttr::call_origin() -> DwarfAttr {
  DwarfCallOrigin
}

///|
pub fn DwarfAttr::call_parameter() -> DwarfAttr {
  DwarfCallParameter
}

///|
pub fn DwarfAttr::call_pc() -> DwarfAttr {
  DwarfCallPc
}

///|
pub fn DwarfAttr::call_tail_call() -> DwarfAttr {
  DwarfCallTailCall
}

///|
pub fn DwarfAttr::call_target() -> DwarfAttr {
  DwarfCallTarget
}

///|
pub fn DwarfAttr::call_target_clobbered() -> DwarfAttr {
  DwarfCallTargetClobbered
}

///|
pub fn DwarfAttr::call_data_location() -> DwarfAttr {
  DwarfCallDataLocation
}

///|
pub fn DwarfAttr::call_data_value() -> DwarfAttr {
  DwarfCallDataValue
}

///|
pub fn DwarfAttr::noreturn() -> DwarfAttr {
  DwarfNoreturn
}

///|
pub fn DwarfAttr::alignment() -> DwarfAttr {
  DwarfAlignment
}

///|
pub fn DwarfAttr::export_symbols() -> DwarfAttr {
  DwarfExportSymbols
}

///|
pub fn DwarfAttr::deleted() -> DwarfAttr {
  DwarfDeleted
}

///|
pub fn DwarfAttr::defaulted() -> DwarfAttr {
  DwarfDefaulted
}

///|
pub fn DwarfAttr::loclists_base() -> DwarfAttr {
  DwarfLoclistsBase
}

///|
pub fn DwarfAttr::ranges_base() -> DwarfAttr {
  DwarfRangesBase
}

///|
pub fn DwarfAttr::unknown(code : Int) -> DwarfAttr {
  DwarfUnknownAttr(code)
}

///|
pub(all) enum DwarfForm {
  DwarfAddr
  DwarfBlock(DwarfLenspec)
  DwarfConst(DwarfLenspec)
  DwarfSignedConst(DwarfLenspec)
  DwarfFlag
  DwarfString
  DwarfStrp
  DwarfStrx(DwarfIndexSpec)
  DwarfAddrx(DwarfIndexSpec)
  DwarfAddrxOffset
  DwarfData16
  DwarfLineStrp
  DwarfImplicitConst(Int64)
  DwarfLoclistx
  DwarfRnglistx
  DwarfStrpSup
  DwarfRefSup4
  DwarfRefSup8
  DwarfRefAlt
  DwarfStrpAlt
  DwarfRefAddr
  DwarfRefSig8
  DwarfOffset
  DwarfRef(DwarfLenspec)
  DwarfIndirect
  DwarfExpr
  DwarfFlagPresent
} derive(Eq, Debug)

///|
pub fn DwarfForm::addr() -> DwarfForm {
  DwarfAddr
}

///|
pub fn DwarfForm::block(spec : DwarfLenspec) -> DwarfForm {
  DwarfBlock(spec)
}

///|
pub fn DwarfForm::const_(spec : DwarfLenspec) -> DwarfForm {
  DwarfConst(spec)
}

///|
pub fn DwarfForm::flag_present() -> DwarfForm {
  DwarfFlagPresent
}

///|
pub fn DwarfForm::string() -> DwarfForm {
  DwarfString
}

///|
pub fn DwarfForm::strp() -> DwarfForm {
  DwarfStrp
}

///|
pub fn DwarfForm::addrx_offset() -> DwarfForm {
  DwarfAddrxOffset
}

///|
pub fn DwarfForm::ref_(spec : DwarfLenspec) -> DwarfForm {
  DwarfRef(spec)
}

///|
pub fn DwarfForm::indirect() -> DwarfForm {
  DwarfIndirect
}

///|
pub fn DwarfForm::offset() -> DwarfForm {
  DwarfOffset
}

///|
pub fn DwarfForm::expr() -> DwarfForm {
  DwarfExpr
}

///|
pub fn DwarfForm::sig_() -> DwarfForm {
  DwarfRefSig8
}

///|
struct DwarfInput {
  data : Bytes
  position_value : Int
}

///|
struct DwarfInputReader[T] {
  read_fn : (DwarfInput) -> Result[(T, DwarfInput), String]
}

///|
pub fn DwarfInput::of_bytes(data : Bytes) -> DwarfInput {
  { data, position_value: 0 }
}

///|
pub fn[T] DwarfInputReader::run(
  self : DwarfInputReader[T],
  input : DwarfInput,
) -> Result[(T, DwarfInput), String] {
  (self.read_fn)(input)
}

///|
pub fn DwarfInputReader::char() -> DwarfInputReader[Int] {
  { read_fn: input => input.read_byte() }
}

///|
pub fn DwarfInputReader::code() -> DwarfInputReader[Int] {
  { read_fn: input => input.read_code() }
}

///|
pub fn DwarfInputReader::tag() -> DwarfInputReader[DwarfTag] {
  { read_fn: input => input.read_tag() }
}

///|
pub fn DwarfInputReader::form() -> DwarfInputReader[DwarfForm] {
  { read_fn: input => input.read_form() }
}

///|
pub fn DwarfInputReader::attr() -> DwarfInputReader[DwarfAttr] {
  { read_fn: input => input.read_attr() }
}

///|
pub fn DwarfInputReader::string() -> DwarfInputReader[String] {
  { read_fn: input => input.read_cstring() }
}

///|
pub fn DwarfInputReader::address(
  endian~ : @bitvec.Endian,
  size~ : DwarfWordSize,
) -> DwarfInputReader[UInt64] {
  { read_fn: input => input.read_address(endian~, size~) }
}

///|
pub fn DwarfInputReader::version() -> DwarfInputReader[Int] {
  { read_fn: input => input.read_version() }
}

///|
pub fn DwarfInputReader::unit_size(
  endian~ : @bitvec.Endian,
) -> DwarfInputReader[(DwarfWordSize, Int)] {
  { read_fn: input => input.read_unit_size(endian~) }
}

///|
pub fn DwarfInputReader::skip(bytes~ : Int) -> DwarfInputReader[Unit] {
  { read_fn: input => input.skip(bytes~).map(done => ((), done)) }
}

///|
pub fn DwarfInputReader::skip_zeros() -> DwarfInputReader[Unit] {
  { read_fn: input => input.skip_zeros().map(done => ((), done)) }
}

///|
pub fn DwarfInputReader::address_size() -> DwarfInputReader[DwarfWordSize] {
  { read_fn: input => input.read_address_size() }
}

///|
pub fn DwarfInputReader::offset(
  endian~ : @bitvec.Endian,
  size~ : DwarfWordSize,
) -> DwarfInputReader[Int] {
  { read_fn: input => input.read_offset(endian~, size~) }
}

///|
pub fn DwarfInputReader::block(
  lenspec~ : DwarfLenspec,
  endian~ : @bitvec.Endian,
) -> DwarfInputReader[Bytes] {
  { read_fn: input => input.read_block(lenspec~, endian~) }
}

///|
pub fn DwarfInputReader::const_(
  lenspec~ : DwarfLenspec,
  endian~ : @bitvec.Endian,
) -> DwarfInputReader[Int64] {
  { read_fn: input => input.read_const(lenspec~, endian~) }
}

///|
pub fn[A, B] DwarfInputReader::map(
  self : DwarfInputReader[A],
  f : (A) -> B,
) -> DwarfInputReader[B] {
  {
    read_fn: input => {
      match self.run(input) {
        Ok((value, next)) => Ok((f(value), next))
        Err(reason) => Err(reason)
      }
    },
  }
}

///|
pub fn[T] DwarfInputReader::take(
  self : DwarfInputReader[T],
) -> DwarfInputReader[T?] {
  self.map(value => Some(value))
}

///|
pub fn[T] DwarfInputReader::drop(
  self : DwarfInputReader[T],
) -> DwarfInputReader[T?] {
  self.map(_ => None)
}

///|
pub fn[T] DwarfInputReader::ignore_(
  self : DwarfInputReader[T],
) -> DwarfInputReader[Unit] {
  self.map(_ => ())
}

///|
pub fn[A, B] DwarfInputReader::pair(
  first : DwarfInputReader[A],
  second : DwarfInputReader[B],
) -> DwarfInputReader[(A, B)] {
  {
    read_fn: input => {
      match first.run(input) {
        Err(reason) => Err(reason)
        Ok((left, input)) =>
          match second.run(input) {
            Err(reason) => Err(reason)
            Ok((right, input)) => Ok(((left, right), input))
          }
      }
    },
  }
}

///|
pub fn DwarfInput::position(self : DwarfInput) -> Int {
  self.position_value
}

///|
pub fn DwarfInput::remaining(self : DwarfInput) -> Int {
  self.data.length() - self.position_value
}

///|
fn DwarfInput::with_position(self : DwarfInput, position : Int) -> DwarfInput {
  { ..self, position_value: position }
}

///|
fn DwarfInput::require(self : DwarfInput, bytes : Int) -> Result[Unit, String] {
  if bytes < 0 {
    Err("negative DWARF read size")
  } else if self.position_value + bytes > self.data.length() {
    Err("truncated DWARF input")
  } else {
    Ok(())
  }
}

///|
pub fn DwarfInput::read_byte(
  self : DwarfInput,
) -> Result[(Int, DwarfInput), String] {
  match self.require(1) {
    Ok(_) =>
      Ok(
        (
          self.data[self.position_value].to_int(),
          self.with_position(self.position_value + 1),
        ),
      )
    Err(reason) => Err(reason)
  }
}

///|
fn DwarfInput::read_uint(
  self : DwarfInput,
  bytes : Int,
  endian : @bitvec.Endian,
) -> Result[(UInt64, DwarfInput), String] {
  match self.require(bytes) {
    Ok(_) => {
      let mut value = 0UL
      for i in 0..<bytes {
        let shift = match endian {
          LittleEndian => i * 8
          BigEndian => (bytes - 1 - i) * 8
        }
        value = value |
          (self.data[self.position_value + i].to_int().to_uint64() << shift)
      }
      Ok((value, self.with_position(self.position_value + bytes)))
    }
    Err(reason) => Err(reason)
  }
}

///|
fn dwarf_sign_extend(value : UInt64, bits : Int) -> Int64 {
  if bits >= 64 {
    value.reinterpret_as_int64()
  } else {
    let sign = 1UL << (bits - 1)
    let extended = if (value & sign) != 0UL {
      value | (UInt64::lnot(0UL) << bits)
    } else {
      value
    }
    extended.reinterpret_as_int64()
  }
}

///|
fn DwarfInput::read_signed(
  self : DwarfInput,
  bytes : Int,
  endian : @bitvec.Endian,
) -> Result[(Int64, DwarfInput), String] {
  match self.read_uint(bytes, endian) {
    Ok((value, next)) => Ok((dwarf_sign_extend(value, bytes * 8), next))
    Err(reason) => Err(reason)
  }
}

///|
fn dwarf_word_bytes(size : DwarfWordSize) -> Int {
  match size {
    W32 => 4
    W64 => 8
  }
}

///|
fn dwarf_int64_to_int(value : Int64) -> Result[Int, String] {
  if value < -2147483648L || value > 2147483647L {
    Err("DWARF integer does not fit in Int")
  } else {
    Ok(value.to_int())
  }
}

///|
pub fn DwarfInput::read_int(
  self : DwarfInput,
  endian~ : @bitvec.Endian,
  size~ : DwarfWordSize,
) -> Result[(Int, DwarfInput), String] {
  match self.read_signed(dwarf_word_bytes(size), endian) {
    Ok((value, next)) =>
      match dwarf_int64_to_int(value) {
        Ok(n) => Ok((n, next))
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::read_int64(
  self : DwarfInput,
  endian~ : @bitvec.Endian,
  size~ : DwarfWordSize,
) -> Result[(Int64, DwarfInput), String] {
  self.read_signed(dwarf_word_bytes(size), endian)
}

///|
pub fn DwarfInput::read_address(
  self : DwarfInput,
  endian~ : @bitvec.Endian,
  size~ : DwarfWordSize,
) -> Result[(UInt64, DwarfInput), String] {
  self.read_uint(dwarf_word_bytes(size), endian)
}

///|
pub fn DwarfInput::read_offset(
  self : DwarfInput,
  endian~ : @bitvec.Endian,
  size~ : DwarfWordSize,
) -> Result[(Int, DwarfInput), String] {
  self.read_int(endian~, size~)
}

///|
pub fn DwarfInput::read_int16(
  self : DwarfInput,
  endian~ : @bitvec.Endian,
) -> Result[(Int, DwarfInput), String] {
  match self.read_signed(2, endian) {
    Ok((value, next)) => Ok((value.to_int(), next))
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::read_code(
  self : DwarfInput,
) -> Result[(Int, DwarfInput), String] {
  match Leb128::read(self.data[:], pos=self.position_value) {
    Ok((leb, next_pos)) =>
      match leb.to_int() {
        Ok(code) => Ok((code, self.with_position(next_pos)))
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn DwarfInput::read_signed_code(
  self : DwarfInput,
) -> Result[(Int64, DwarfInput), String] {
  match Leb128::read(self.data[:], signed=true, pos=self.position_value) {
    Ok((leb, next_pos)) =>
      match leb.to_int64() {
        Ok(code) => Ok((code, self.with_position(next_pos)))
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn dwarf_tag_of_int(code : Int) -> DwarfTag {
  match code {
    0x01 => DwarfArrayType
    0x02 => DwarfClassType
    0x03 => DwarfEntryPoint
    0x04 => DwarfEnumerationType
    0x05 => DwarfFormalParameter
    0x08 => DwarfImportedDeclaration
    0x0a => DwarfLabel
    0x0b => DwarfLexicalBlock
    0x0d => DwarfMember
    0x0f => DwarfPointerType
    0x10 => DwarfReferenceType
    0x11 => DwarfCompileUnit
    0x12 => DwarfStringType
    0x13 => DwarfStructureType
    0x15 => DwarfSubroutineType
    0x16 => DwarfTypedef
    0x17 => DwarfUnionType
    0x18 => DwarfUnspecifiedParameters
    0x19 => DwarfVariant
    0x1a => DwarfCommonBlock
    0x1b => DwarfCommonInclusion
    0x1c => DwarfInheritance
    0x1d => DwarfInlinedSubroutine
    0x1e => DwarfModule
    0x1f => DwarfPtrToMemberType
    0x20 => DwarfSetType
    0x21 => DwarfSubrangeType
    0x22 => DwarfWithStmt
    0x23 => DwarfAccessDeclaration
    0x24 => DwarfBaseType
    0x25 => DwarfCatchBlock
    0x26 => DwarfConstType
    0x27 => DwarfConstant
    0x28 => DwarfEnumerator
    0x29 => DwarfFileType
    0x2a => DwarfFriend
    0x2b => DwarfNamelist
    0x2c => DwarfNamelistItem
    0x2d => DwarfPackedType
    0x2e => DwarfSubprogram
    0x2f => DwarfTemplateTypeParameter
    0x30 => DwarfTemplateValueParameter
    0x31 => DwarfThrownType
    0x32 => DwarfTryBlock
    0x33 => DwarfVariantPart
    0x34 => DwarfVariable
    0x35 => DwarfVolatileType
    0x36 => DwarfProcedure
    0x37 => DwarfRestrictType
    0x38 => DwarfInterfaceType
    0x39 => DwarfNamespace
    0x3a => DwarfImportedModule
    0x3b => DwarfUnspecifiedType
    0x3c => DwarfPartialUnit
    0x3d => DwarfImportedUnit
    0x3f => DwarfCondition
    0x40 => DwarfSharedType
    0x41 => DwarfTypeUnit
    0x42 => DwarfRvalueReferenceType
    0x43 => DwarfTemplateAlias
    0x44 => DwarfCoarrayType
    0x45 => DwarfGenericSubrange
    0x46 => DwarfDynamicType
    0x47 => DwarfAtomicType
    0x48 => DwarfCallSite
    0x49 => DwarfCallSiteParameter
    0x4a => DwarfSkeletonUnit
    0x4b => DwarfImmutableType
    other => DwarfUnknownTag(other)
  }
}

///|
fn dwarf_attr_of_int(code : Int) -> DwarfAttr {
  match code {
    0x01 => DwarfSibling
    0x02 => DwarfLocation
    0x03 => DwarfName
    0x09 => DwarfOrdering
    0x0b => DwarfByteSize
    0x0c => DwarfBitOffset
    0x0d => DwarfBitSize
    0x10 => DwarfStmtList
    0x11 => DwarfLowPc
    0x12 => DwarfHighPc
    0x13 => DwarfLanguage
    0x15 => DwarfDiscr
    0x16 => DwarfDiscrValue
    0x17 => DwarfVisibility
    0x18 => DwarfImport
    0x19 => DwarfStringLength
    0x1a => DwarfCommonReference
    0x1b => DwarfCompDir
    0x1c => DwarfConstValue
    0x1d => DwarfContainingType
    0x1e => DwarfDefaultValue
    0x20 => DwarfInline
    0x21 => DwarfIsOptional
    0x22 => DwarfLowerBound
    0x25 => DwarfProducer
    0x27 => DwarfPrototyped
    0x2a => DwarfReturnAddr
    0x2c => DwarfStartScope
    0x2e => DwarfBitStride
    0x2f => DwarfUpperBound
    0x31 => DwarfAbstractOrigin
    0x32 => DwarfAccessibility
    0x33 => DwarfAddressClass
    0x34 => DwarfArtificial
    0x35 => DwarfBaseTypes
    0x36 => DwarfCallingConvention
    0x37 => DwarfCount
    0x38 => DwarfDataMemberLocation
    0x39 => DwarfDeclColumn
    0x3a => DwarfDeclFile
    0x3b => DwarfDeclLine
    0x3c => DwarfDeclaration
    0x3d => DwarfDiscrList
    0x3e => DwarfEncoding
    0x3f => DwarfExternal
    0x40 => DwarfFrameBase
    0x41 => DwarfFriend
    0x42 => DwarfIdentifierCase
    0x43 => DwarfMacroInfo
    0x44 => DwarfNamelistItem
    0x45 => DwarfPriority
    0x46 => DwarfSegment
    0x47 => DwarfSpecification
    0x48 => DwarfStaticLink
    0x49 => DwarfType
    0x4a => DwarfUseLocation
    0x4b => DwarfVariableParameter
    0x4c => DwarfVirtuality
    0x4d => DwarfVtableElemLocation
    0x4e => DwarfAllocated
    0x4f => DwarfAssociated
    0x50 => DwarfDataLocation
    0x51 => DwarfByteStride
    0x52 => DwarfEntryPc
    0x53 => DwarfUseUtf8
    0x54 => DwarfExtension
    0x55 => DwarfRanges
    0x56 => DwarfTrampoline
    0x57 => DwarfCallColumn
    0x58 => DwarfCallFile
    0x59 => DwarfCallLine
    0x5a => DwarfDescription
    0x5b => DwarfBinaryScale
    0x5c => DwarfDecimalScale
    0x5d => DwarfSmall
    0x5e => DwarfDecimalSign
    0x5f => DwarfDigitCount
    0x60 => DwarfPictureString
    0x61 => DwarfMutable
    0x62 => DwarfThreadsScaled
    0x63 => DwarfExplicit
    0x64 => DwarfObjectPointer
    0x65 => DwarfEndianity
    0x66 => DwarfElemental
    0x67 => DwarfPure
    0x68 => DwarfRecursive
    0x69 => DwarfSignature
    0x6a => DwarfMainSubprogram
    0x6b => DwarfDataBitOffset
    0x6c => DwarfConstExpr
    0x6d => DwarfEnumClass
    0x6e => DwarfLinkageName
    0x6f => DwarfStringLengthBitSize
    0x70 => DwarfStringLengthByteSize
    0x71 => DwarfRank
    0x72 => DwarfStrOffsetsBase
    0x73 => DwarfAddrBase
    0x74 => DwarfRnglistsBase
    0x75 => DwarfDwoId
    0x76 => DwarfDwoName
    0x77 => DwarfReference
    0x78 => DwarfRvalueReference
    0x79 => DwarfMacros
    0x7a => DwarfCallAllCalls
    0x7b => DwarfCallAllSourceCalls
    0x7c => DwarfCallAllTailCalls
    0x7d => DwarfCallReturnPc
    0x7e => DwarfCallValue
    0x7f => DwarfCallOrigin
    0x80 => DwarfCallParameter
    0x81 => DwarfCallPc
    0x82 => DwarfCallTailCall
    0x83 => DwarfCallTarget
    0x84 => DwarfCallTargetClobbered
    0x85 => DwarfCallDataLocation
    0x86 => DwarfCallDataValue
    0x87 => DwarfNoreturn
    0x88 => DwarfAlignment
    0x89 => DwarfExportSymbols
    0x8a => DwarfDeleted
    0x8b => DwarfDefaulted
    0x8c => DwarfLoclistsBase
    0x2007 => DwarfLinkageName
    0x2132 => DwarfRangesBase
    0x2133 => DwarfAddrBase
    other => DwarfUnknownAttr(other)
  }
}

///|
fn dwarf_form_of_int(code : Int) -> Result[DwarfForm, String] {
  match code {
    0x01 => Ok(DwarfAddr)
    0x03 => Ok(DwarfBlock(DwarfTwo))
    0x04 => Ok(DwarfBlock(DwarfFour))
    0x05 => Ok(DwarfConst(DwarfTwo))
    0x06 => Ok(DwarfConst(DwarfFour))
    0x07 => Ok(DwarfConst(DwarfEight))
    0x08 => Ok(DwarfString)
    0x09 => Ok(DwarfBlock(DwarfLeb128))
    0x0a => Ok(DwarfBlock(DwarfOne))
    0x0b => Ok(DwarfConst(DwarfOne))
    0x0c => Ok(DwarfFlag)
    0x0d => Ok(DwarfSignedConst(DwarfLeb128))
    0x0e => Ok(DwarfStrp)
    0x0f => Ok(DwarfConst(DwarfLeb128))
    0x10 => Ok(DwarfRefAddr)
    0x11 => Ok(DwarfRef(DwarfOne))
    0x12 => Ok(DwarfRef(DwarfTwo))
    0x13 => Ok(DwarfRef(DwarfFour))
    0x14 => Ok(DwarfRef(DwarfEight))
    0x15 => Ok(DwarfRef(DwarfLeb128))
    0x16 => Ok(DwarfIndirect)
    0x17 => Ok(DwarfOffset)
    0x18 => Ok(DwarfExpr)
    0x19 => Ok(DwarfFlagPresent)
    0x1a => Ok(DwarfStrx(DwarfIndexLeb128))
    0x1b => Ok(DwarfAddrx(DwarfIndexLeb128))
    0x1c => Ok(DwarfRefSup4)
    0x1d => Ok(DwarfStrpSup)
    0x1e => Ok(DwarfData16)
    0x1f => Ok(DwarfLineStrp)
    0x20 => Ok(DwarfRefSig8)
    0x21 => Ok(DwarfImplicitConst(0L))
    0x22 => Ok(DwarfLoclistx)
    0x23 => Ok(DwarfRnglistx)
    0x24 => Ok(DwarfRefSup8)
    0x25 => Ok(DwarfStrx(DwarfIndexOne))
    0x26 => Ok(DwarfStrx(DwarfIndexTwo))
    0x27 => Ok(DwarfStrx(DwarfIndexThree))
    0x28 => Ok(DwarfStrx(DwarfIndexFour))
    0x29 => Ok(DwarfAddrx(DwarfIndexOne))
    0x2a => Ok(DwarfAddrx(DwarfIndexTwo))
    0x2b => Ok(DwarfAddrx(DwarfIndexThree))
    0x2c => Ok(DwarfAddrx(DwarfIndexFour))
    0x1f01 => Ok(DwarfAddrx(DwarfIndexLeb128))
    0x1f02 => Ok(DwarfStrx(DwarfIndexLeb128))
    0x1f20 => Ok(DwarfRefAlt)
    0x1f21 => Ok(DwarfStrpAlt)
    0x2001 => Ok(DwarfAddrxOffset)
    other => Err("unknown DWARF form code: \{other}")
  }
}

///|
pub fn DwarfInput::read_tag(
  self : DwarfInput,
) -> Result[(DwarfTag, DwarfInput), String] {
  match self.read_code() {
    Ok((code, next)) => Ok((dwarf_tag_of_int(code), next))
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::read_attr(
  self : DwarfInput,
) -> Result[(DwarfAttr, DwarfInput), String] {
  match self.read_code() {
    Ok((code, next)) => Ok((dwarf_attr_of_int(code), next))
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::read_form(
  self : DwarfInput,
) -> Result[(DwarfForm, DwarfInput), String] {
  match self.read_code() {
    Ok((code, next)) =>
      match dwarf_form_of_int(code) {
        Ok(form) => Ok((form, next))
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::read_cstring(
  self : DwarfInput,
) -> Result[(String, DwarfInput), String] {
  let mut index = self.position_value
  while index < self.data.length() && self.data[index] != b'\x00' {
    index = index + 1
  }
  if index >= self.data.length() {
    return Err("DWARF string is not null-terminated")
  }
  let text = try @utf8.decode(self.data[self.position_value:index]) catch {
    _ => return Err("DWARF string is not valid UTF-8")
  } noraise {
    value => value
  }
  Ok((text, self.with_position(index + 1)))
}

///|
pub fn DwarfInput::read_version(
  self : DwarfInput,
) -> Result[(Int, DwarfInput), String] {
  match self.read_byte() {
    Ok((first, next)) =>
      match next.read_byte() {
        Ok((second, done)) => {
          let version = if first == 0 {
            second
          } else if second == 0 {
            first
          } else {
            second
          }
          Ok((version, done))
        }
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::read_address_size(
  self : DwarfInput,
) -> Result[(DwarfWordSize, DwarfInput), String] {
  match self.read_byte() {
    Ok((4, next)) => Ok((W32, next))
    Ok((8, next)) => Ok((W64, next))
    Ok((n, _)) => Err("unsupported DWARF address size: \{n}")
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::read_unit_size(
  self : DwarfInput,
  endian~ : @bitvec.Endian,
) -> Result[((DwarfWordSize, Int), DwarfInput), String] {
  match self.read_uint(4, endian) {
    Ok((0xffffffffUL, next)) =>
      match next.read_uint(8, endian) {
        Ok((size, done)) =>
          if size > 2147483647UL {
            Err("DWARF unit size does not fit in Int")
          } else {
            Ok(((W64, size.to_int()), done))
          }
        Err(reason) => Err(reason)
      }
    Ok((size, next)) =>
      if size > 2147483647UL {
        Err("DWARF unit size does not fit in Int")
      } else {
        Ok(((W32, size.to_int()), next))
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::skip(
  self : DwarfInput,
  bytes~ : Int,
) -> Result[DwarfInput, String] {
  match self.require(bytes) {
    Ok(_) => Ok(self.with_position(self.position_value + bytes))
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::skip_zeros(self : DwarfInput) -> Result[DwarfInput, String] {
  let mut index = self.position_value
  while index < self.data.length() && self.data[index] == b'\x00' {
    index = index + 1
  }
  if index >= self.data.length() {
    Err("truncated DWARF input while skipping zeroes")
  } else {
    Ok(self.with_position(index))
  }
}

///|
fn DwarfInput::read_len(
  self : DwarfInput,
  lenspec : DwarfLenspec,
  endian : @bitvec.Endian,
) -> Result[(Int64, DwarfInput), String] {
  match lenspec {
    DwarfLeb128 =>
      match Leb128::read(self.data[:], pos=self.position_value) {
        Ok((leb, next_pos)) =>
          match leb.to_int64() {
            Ok(value) => Ok((value, self.with_position(next_pos)))
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    DwarfOne =>
      match self.read_byte() {
        Ok((value, next)) => Ok((value.to_int64(), next))
        Err(reason) => Err(reason)
      }
    DwarfTwo => self.read_signed(2, endian)
    DwarfFour => self.read_signed(4, endian)
    DwarfEight => self.read_signed(8, endian)
  }
}

///|
pub fn DwarfInput::read_const(
  self : DwarfInput,
  lenspec~ : DwarfLenspec,
  endian~ : @bitvec.Endian,
) -> Result[(Int64, DwarfInput), String] {
  self.read_len(lenspec, endian)
}

///|
fn DwarfInput::read_unsigned_const(
  self : DwarfInput,
  lenspec : DwarfLenspec,
  endian : @bitvec.Endian,
) -> Result[(UInt64, DwarfInput), String] {
  match lenspec {
    DwarfLeb128 =>
      match self.read_code() {
        Ok((value, next)) =>
          if value < 0 {
            Err("negative DWARF unsigned constant")
          } else {
            Ok((value.to_uint64(), next))
          }
        Err(reason) => Err(reason)
      }
    DwarfOne =>
      match self.read_byte() {
        Ok((value, next)) => Ok((value.to_uint64(), next))
        Err(reason) => Err(reason)
      }
    DwarfTwo => self.read_uint(2, endian)
    DwarfFour => self.read_uint(4, endian)
    DwarfEight => self.read_uint(8, endian)
  }
}

///|
fn DwarfInput::read_signed_const(
  self : DwarfInput,
  lenspec : DwarfLenspec,
  endian : @bitvec.Endian,
) -> Result[(Int64, DwarfInput), String] {
  match lenspec {
    DwarfLeb128 => self.read_signed_code()
    _ => self.read_const(lenspec~, endian~)
  }
}

///|
fn DwarfInput::read_unsigned_bytes(
  self : DwarfInput,
  bytes : Int,
  endian : @bitvec.Endian,
) -> Result[(Int, DwarfInput), String] {
  match self.read_uint(bytes, endian) {
    Ok((value, next)) =>
      if value > 2147483647UL {
        Err("DWARF index does not fit in Int")
      } else {
        Ok((value.to_int(), next))
      }
    Err(reason) => Err(reason)
  }
}

///|
fn DwarfInput::read_index(
  self : DwarfInput,
  spec : DwarfIndexSpec,
  endian : @bitvec.Endian,
) -> Result[(Int, DwarfInput), String] {
  match spec {
    DwarfIndexLeb128 => self.read_code()
    DwarfIndexOne =>
      match self.read_byte() {
        Ok((value, next)) => Ok((value, next))
        Err(reason) => Err(reason)
      }
    DwarfIndexTwo => self.read_unsigned_bytes(2, endian)
    DwarfIndexThree => self.read_unsigned_bytes(3, endian)
    DwarfIndexFour => self.read_unsigned_bytes(4, endian)
  }
}

///|
fn DwarfInput::read_addrx_offset(
  self : DwarfInput,
  endian : @bitvec.Endian,
) -> Result[((Int, UInt64), DwarfInput), String] {
  match self.read_code() {
    Ok((index, after_index)) =>
      match after_index.read_uint(4, endian) {
        Ok((offset, next)) => Ok(((index, offset), next))
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn DwarfInput::read_block_length(
  self : DwarfInput,
  lenspec : DwarfLenspec,
  endian : @bitvec.Endian,
) -> Result[(Int, DwarfInput), String] {
  match lenspec {
    DwarfLeb128 => self.read_code()
    DwarfOne => self.read_byte()
    DwarfTwo => self.read_unsigned_bytes(2, endian)
    DwarfFour => self.read_unsigned_bytes(4, endian)
    DwarfEight =>
      match self.read_uint(8, endian) {
        Ok((value, next)) =>
          if value > 2147483647UL {
            Err("invalid DWARF block size: \{value}")
          } else {
            Ok((value.to_int(), next))
          }
        Err(reason) => Err(reason)
      }
  }
}

///|
pub fn DwarfInput::read_block(
  self : DwarfInput,
  lenspec~ : DwarfLenspec,
  endian~ : @bitvec.Endian,
) -> Result[(Bytes, DwarfInput), String] {
  match self.read_block_length(lenspec, endian) {
    Ok((len, next)) =>
      match next.require(len) {
        Ok(_) =>
          Ok(
            (
              next.data[next.position_value:next.position_value + len].to_owned(),
              next.with_position(next.position_value + len),
            ),
          )
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}
