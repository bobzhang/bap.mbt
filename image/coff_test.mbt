///|
test "PE/COFF LLVM loader facts" {
  let doc = macho_ok(@image.coff_llvm_spec(@objects.x86_64_pe()))
  inspect(
    doc
    .to_string()
    .split("\n")
    .filter(line => line.has_prefix("(") && !line.has_prefix("(declare"))
    .map(line => line.to_owned())
    .to_array()
    .join("\n"),
    content=(
      #|(abi unknown)
      #|(arch x86_64)
      #|(bits 64)
      #|(format coff)
      #|(is-executable true)
      #|(is-little-endian true)
      #|(llvm:base-address 5368709120)
      #|(llvm:code-entry foo 1038 9)
      #|(llvm:code-entry long_function_foo 1038 9)
      #|(llvm:code-entry main 1024 14)
      #|(llvm:code-entry .text 1024 512)
      #|(llvm:coff-virtual-section-header .rdata 5368717312 512)
      #|(llvm:coff-virtual-section-header .text 5368713216 23)
      #|(llvm:entry-point 5368713216)
      #|(llvm:name-reference 5368717696 ExitProcess)
      #|(llvm:section-entry .rdata 5368717312 512 1536)
      #|(llvm:section-entry .text 5368713216 512 1024)
      #|(llvm:section-flags .rdata true false false)
      #|(llvm:section-flags .text true false true)
      #|(llvm:symbol-entry foo 5368713230 9 1038 0)
      #|(llvm:symbol-entry tablesym 5368717568 256 1792 256)
      #|(llvm:symbol-entry long_function_foo 5368713230 9 1038 14)
      #|(llvm:symbol-entry main 5368713216 14 1024 0)
      #|(require KERNEL32.dll)
      #|(subarch "")
      #|(system "")
      #|(vendor "")
    ),
  )
}

///|
test "PE32+ executable image" {
  let image = load_with(@image.ImageBackend::coff(), @objects.x86_64_pe())
  inspect(
    image_summary(image),
    content=(
      #|target target:x86_64 entry 0x140001000 base 0x140000000
      #|segment .text 0x140001000+0x200 @0x400 r-x
      #|segment .rdata 0x140002000+0x200 @0x600 r--
      #|section .text 0x140001000+0x17
      #|section .rdata 0x140002000+0x200
      #|symbol main 0x140001000+0xe fn=true
      #|symbol long_function_foo 0x14000100e+0x9 fn=true
      #|extern 0x140002180 ExitProcess
      #|require KERNEL32.dll
    ),
  )
  inspect(
    image_facts(image.spec()),
    content=(
      #|(abi unknown)
      #|(arch x86_64)
      #|(base-address 5368709120)
      #|(bias 0)
      #|(bits 64)
      #|(code-region 5368713216 23 1024)
      #|(code-start 5368713230)
      #|(code-start 5368713216)
      #|(entry-point 5368713216)
      #|(external-reference 5368717696 ExitProcess)
      #|(format coff)
      #|(is-executable true)
      #|(is-little-endian true)
      #|(mapped 5368717312 512 1536)
      #|(mapped 5368713216 512 1024)
      #|(named-region 5368717312 512 .rdata)
      #|(named-region 5368713216 23 .text)
      #|(named-symbol 5368713230 foo)
      #|(named-symbol 5368717568 tablesym)
      #|(named-symbol 5368713230 long_function_foo)
      #|(named-symbol 5368713216 main)
      #|(require KERNEL32.dll)
      #|(section 5368717312 512)
      #|(section 5368713216 23)
      #|(segment 5368717312 512 true false false)
      #|(segment 5368713216 23 true false true)
      #|(subarch "")
      #|(symbol-chunk 5368717568 256 5368717568)
      #|(symbol-chunk 5368713230 9 5368713230)
      #|(symbol-chunk 5368713216 14 5368713216)
      #|(symbol-value 5368713230 0)
      #|(symbol-value 5368717568 256)
      #|(symbol-value 5368713230 14)
      #|(symbol-value 5368713216 0)
      #|(system "")
      #|(vendor "")
    ),
  )
}

///|
test "COFF object image" {
  let image = load_with(
    @image.ImageBackend::coff(),
    @objects.i386_coff_object(),
  )
  inspect(
    image_summary(image),
    content=(
      #|target target:x86 entry 0x0 base 0x0
      #|segment .text 0x0+0x6 @0x64 r-x
      #|section .text 0x0+0x6
      #|symbol _main 0x0+0x6 fn=true
      #|extern 0x1 _puts
    ),
  )
  inspect(
    image_facts(image.spec()),
    content=(
      #|(abi unknown)
      #|(arch i386)
      #|(base-address 0)
      #|(bias 0)
      #|(bits 32)
      #|(code-region 0 6 100)
      #|(code-start 0)
      #|(entry-point 0)
      #|(external-reference 1 _puts)
      #|(format coff)
      #|(is-executable false)
      #|(is-little-endian true)
      #|(mapped 0 6 100)
      #|(named-region 0 6 .text)
      #|(named-symbol 0 _main)
      #|(section 0 6)
      #|(segment 0 6 true false true)
      #|(subarch "")
      #|(symbol-chunk 0 6 0)
      #|(symbol-value 0 0)
      #|(system "")
      #|(vendor "")
    ),
  )
}

///|
test "PE/COFF loader errors" {
  debug_inspect(
    @image.ImageBackend::coff().load(@objects.x86_64_macho()).map(_ => ()),
    content=(
      #|Err("not a PE/COFF file")
    ),
  )
  let truncated = @objects.x86_64_pe()[:0x200].to_owned()
  debug_inspect(
    @image.ImageBackend::coff().load(truncated).map(r => r.1),
    content=(
      #|Ok(
      #|  [
      #|    "Ogre region .text@5368713216 is outside image data",
      #|    "Ogre region .rdata@5368717312 is outside image data",
      #|    "Ogre region .text@5368713216 is outside image data",
      #|  ],
      #|)
    ),
  )
}
