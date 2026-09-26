///|
fn[T] macho_ok(r : Result[T, String]) -> T raise {
  match r {
    Ok(x) => x
    Err(e) => fail(e)
  }
}

///|
fn macho_hex(x : UInt64) -> String {
  "0x" + x.to_string(radix=16)
}

///|
/// A summary of an image: target, entry, segments, sections, symbols,
/// external references and libraries.
fn image_summary(image : @image.Image) -> String {
  let lines = [
    "target \{image.arch().to_string()} entry \{macho_hex(image.entry_point())} base \{image.base_address().map(macho_hex).unwrap_or("-")}",
  ]
  for s in image.segments() {
    let perm = (if s.is_readable() { "r" } else { "-" }) +
      (if s.is_writable() { "w" } else { "-" }) +
      (if s.is_executable() { "x" } else { "-" })
    lines.push(
      "segment \{s.name()} \{macho_hex(s.addr())}+\{macho_hex(s.size().to_uint64())} @\{macho_hex(s.offset().to_uint64())} \{perm}",
    )
  }
  for s in image.sections() {
    lines.push(
      "section \{s.name()} \{macho_hex(s.addr())}+\{macho_hex(s.size().to_uint64())}",
    )
  }
  for s in image.symbols() {
    lines.push(
      "symbol \{s.name()} \{macho_hex(s.addr())}+\{macho_hex(s.size().to_uint64())} fn=\{s.is_function()}",
    )
  }
  for r in image.external_references() {
    lines.push("extern \{macho_hex(r.addr())} \{r.name()}")
  }
  for r in image.relocations() {
    lines.push(
      "relocation \{macho_hex(r.fixup())} -> \{r.target().map(macho_hex).unwrap_or("-")}",
    )
  }
  for lib in image.required_libraries() {
    lines.push("require \{lib}")
  }
  lines.join("\n")
}

///|
test "Mach-O LLVM loader facts" {
  let doc = macho_ok(@image.macho_llvm_spec(@objects.x86_64_macho()))
  inspect(
    doc,
    content=(
      #|(declare abi (name str))
      #|(declare arch (name str))
      #|(declare bits (size int))
      #|(declare format (name str))
      #|(declare is-executable (flag bool))
      #|(declare is-little-endian (flag bool))
      #|(declare llvm:base-address (addr int))
      #|(declare llvm:code-entry (name str) (off int) (size int))
      #|(declare llvm:entry-point (addr int))
      #|(declare llvm:function-start (addr int))
      #|(declare llvm:name-reference (at int) (name str))
      #|(declare llvm:section-entry (name str) (addr int) (size int) (off int))
      #|(declare llvm:segment-command (name str) (off int) (size int))
      #|(declare llvm:segment-command-flags (name str) (r bool) (w bool) (x bool))
      #|(declare llvm:symbol-entry (name str) (addr int) (size int) (off int)
      #| (value int))
      #|(declare llvm:virtual-segment-command (name str) (addr int) (size int))
      #|(declare require (name str))
      #|(declare subarch (name str))
      #|(declare system (name str))
      #|(declare vendor (name str))
      #|
      #|(abi unknown)
      #|(arch x86_64)
      #|(bits 64)
      #|(format macho)
      #|(is-executable true)
      #|(is-little-endian true)
      #|(llvm:base-address 4294967296)
      #|(llvm:code-entry _main 4294968320 14)
      #|(llvm:code-entry _foo 4294968334 10)
      #|(llvm:code-entry __stubs 1048 6)
      #|(llvm:code-entry __text 1024 24)
      #|(llvm:entry-point 4294968320)
      #|(llvm:function-start 4294968337)
      #|(llvm:function-start 4294968334)
      #|(llvm:function-start 4294968320)
      #|(llvm:name-reference 4294971392 _exit)
      #|(llvm:name-reference 4294968344 _exit)
      #|(llvm:section-entry __bss 4294971408 32 0)
      #|(llvm:section-entry __got 4294971392 8 4096)
      #|(llvm:section-entry __stubs 4294968344 6 1048)
      #|(llvm:section-entry __text 4294968320 24 1024)
      #|(llvm:segment-command __LINKEDIT 4112 120)
      #|(llvm:segment-command __DATA 4096 16)
      #|(llvm:segment-command __TEXT 0 4096)
      #|(llvm:segment-command __PAGEZERO 0 0)
      #|(llvm:segment-command-flags __LINKEDIT true false false)
      #|(llvm:segment-command-flags __DATA true true false)
      #|(llvm:segment-command-flags __TEXT true false true)
      #|(llvm:segment-command-flags __PAGEZERO false false false)
      #|(llvm:symbol-entry _main 4294968320 14 4294968320 4294968320)
      #|(llvm:symbol-entry __mh_execute_header 4294967296 1024 4294967296 4294967296)
      #|(llvm:symbol-entry _foo 4294968334 10 4294968334 4294968334)
      #|(llvm:virtual-segment-command __LINKEDIT 4294975488 4096)
      #|(llvm:virtual-segment-command __DATA 4294971392 4096)
      #|(llvm:virtual-segment-command __TEXT 4294967296 4096)
      #|(llvm:virtual-segment-command __PAGEZERO 0 4294967296)
      #|(require /usr/lib/libSystem.B.dylib)
      #|(subarch "")
      #|(system "")
      #|(vendor "")
      #|
    ),
  )
}

///|
/// The image facts (not the `llvm:*` ones) of a specification.
fn image_facts(doc : @image.OgreDoc) -> String {
  doc
  .to_string()
  .split("\n")
  .filter(line => {
    line.has_prefix("(") &&
    !line.has_prefix("(llvm:") &&
    !line.has_prefix("(declare")
  })
  .map(line => line.to_owned())
  .to_array()
  .join("\n")
}

///|
fn load_with(backend : @image.ImageBackend, data : Bytes) -> @image.Image raise {
  let (image, warnings) = macho_ok(backend.load(data))
  if !warnings.is_empty() {
    fail(warnings.join("; "))
  }
  image
}

///|
test "Mach-O x86-64 executable image" {
  let data = @objects.x86_64_macho()
  let image = load_with(@image.ImageBackend::macho(), data)
  inspect(
    image_summary(image),
    content=(
      #|target target:x86_64 entry 0x100000400 base 0x100000000
      #|segment __TEXT 0x100000000+0x1000 @0x0 r-x
      #|segment __DATA 0x100001000+0x10 @0x1000 rw-
      #|segment __LINKEDIT 0x100002000+0x78 @0x1010 r--
      #|section __text 0x100000400+0x18
      #|section __stubs 0x100000418+0x6
      #|section __got 0x100001000+0x8
      #|section __bss 0x100001010+0x20
      #|symbol _foo 0x10000040e+0xa fn=true
      #|symbol _main 0x100000400+0xe fn=true
      #|symbol sub_100000411 0x100000411+0x7 fn=true
      #|extern 0x100000418 _exit
      #|extern 0x100001000 _exit
      #|require /usr/lib/libSystem.B.dylib
    ),
  )
  inspect(
    image_facts(image.spec()),
    content=(
      #|(abi unknown)
      #|(arch x86_64)
      #|(base-address 4294967296)
      #|(bias 0)
      #|(bits 64)
      #|(code-region 4294968344 6 1048)
      #|(code-region 4294968320 24 1024)
      #|(code-start 4294968337)
      #|(code-start 4294968320)
      #|(code-start 4294968334)
      #|(entry-point 4294968320)
      #|(external-reference 4294971392 _exit)
      #|(external-reference 4294968344 _exit)
      #|(format macho)
      #|(is-executable true)
      #|(is-little-endian true)
      #|(mapped 4294975488 120 4112)
      #|(mapped 4294971392 16 4096)
      #|(mapped 4294967296 4096 0)
      #|(named-region 4294971408 32 __bss)
      #|(named-region 4294971392 8 __got)
      #|(named-region 4294968344 6 __stubs)
      #|(named-region 4294968320 24 __text)
      #|(named-region 4294975488 4096 __LINKEDIT)
      #|(named-region 4294971392 4096 __DATA)
      #|(named-region 4294967296 4096 __TEXT)
      #|(named-symbol 4294968320 _main)
      #|(named-symbol 4294967296 __mh_execute_header)
      #|(named-symbol 4294968334 _foo)
      #|(require /usr/lib/libSystem.B.dylib)
      #|(section 4294971408 32)
      #|(section 4294971392 8)
      #|(section 4294968344 6)
      #|(section 4294968320 24)
      #|(segment 4294975488 4096 true false false)
      #|(segment 4294971392 4096 true true false)
      #|(segment 4294967296 4096 true false true)
      #|(subarch "")
      #|(symbol-chunk 4294968320 14 4294968320)
      #|(symbol-chunk 4294967296 1024 4294967296)
      #|(symbol-chunk 4294968334 10 4294968334)
      #|(symbol-value 4294968320 4294968320)
      #|(symbol-value 4294967296 4294967296)
      #|(symbol-value 4294968334 4294968334)
      #|(system "")
      #|(vendor "")
    ),
  )
  // the image specification keeps the loader facts
  assert_true(
    image.spec().to_string().contains("(llvm:segment-command __TEXT 0 4096)"),
  )
}

///|
test "Mach-O arm64 executable image" {
  let image = load_with(@image.ImageBackend::macho(), @objects.arm64_macho())
  inspect(
    image_summary(image),
    content=(
      #|target target:aarch64 entry 0x100000400 base 0x100000000
      #|segment __TEXT 0x100000000+0x1000 @0x0 r-x
      #|segment __LINKEDIT 0x100001000+0x30 @0x1000 r--
      #|section __text 0x100000400+0x18
      #|symbol _main 0x100000400+0x10 fn=true
      #|symbol _foo 0x100000410+0x8 fn=true
    ),
  )
}

///|
test "Mach-O universal binary: the architecture of the target" {
  let data = @objects.fat_macho()
  let arm = load_with(
    @image.ImageBackend::macho(),
    macho_ok(@image.thin_binary(data, target=@core_theory.Target::aarch64())),
  )
  inspect(
    arm.arch().to_string(),
    content=(
      #|target:aarch64
    ),
  )
  assert_eq(arm.symbols().map(s => s.name()), ["_main", "_foo"])
  let x86 = load_with(
    @image.ImageBackend::macho(),
    macho_ok(@image.thin_binary(data, target=@core_theory.Target::x86_64())),
  )
  inspect(
    x86.arch().to_string(),
    content=(
      #|target:x86_64
    ),
  )
  assert_eq(x86.entry_point(), 0x100000400)
  assert_eq(
    macho_ok(@image.thin_binary(data, target=@core_theory.Target::aarch64())),
    @objects.arm64_macho(arm64e=true),
  )
  // a thin binary is itself
  let thin = @objects.arm64_macho()
  assert_eq(macho_ok(@image.thin_binary(thin)), thin)
  // no slice of the target: the host one, or the first one
  let slice = macho_ok(
    @image.thin_binary(data, target=@core_theory.Target::powerpc()),
  )
  assert_true(
    slice == @objects.x86_64_macho() ||
    slice == @objects.arm64_macho(arm64e=true),
  )
  // the backend loads the slice of the host, or the first one
  let image = load_with(@image.ImageBackend::macho(), data)
  assert_eq(image.entry_point(), 0x100000400)
}

///|
test "Mach-O i386 executable with LC_UNIXTHREAD" {
  let image = load_with(@image.ImageBackend::macho(), @objects.i386_macho())
  inspect(
    image_summary(image),
    content=(
      #|target target:x86 entry 0x1400 base 0x1000
      #|segment __TEXT 0x1000+0x1000 @0x0 r-x
      #|section __text 0x1400+0x3
    ),
  )
}

///|
test "Mach-O relocatable object" {
  let data = @objects.x86_64_macho_object()
  let image = load_with(@image.ImageBackend::macho(), data)
  inspect(
    image_summary(image),
    content=(
      #|target target:x86_64 entry 0x0 base 0x0
      #|segment  0x0+0x6 @0xd0 rwx
      #|section  0x0+0x6
      #|symbol _main 0x0+0x6 fn=true
      #|extern 0x1 _puts
    ),
  )
  inspect(
    image_facts(image.spec()),
    content=(
      #|(abi unknown)
      #|(arch x86_64)
      #|(base-address 0)
      #|(bias 0)
      #|(bits 64)
      #|(code-region 0 6 208)
      #|(code-start 0)
      #|(entry-point 0)
      #|(external-reference 1 _puts)
      #|(format macho)
      #|(is-executable false)
      #|(is-little-endian true)
      #|(mapped 0 6 208)
      #|(named-region 0 6 __text)
      #|(named-region 0 6 "")
      #|(named-symbol 0 _main)
      #|(section 0 6)
      #|(segment 0 6 true true true)
      #|(subarch "")
      #|(symbol-chunk 0 6 0)
      #|(symbol-value 0 0)
      #|(system "")
      #|(vendor "")
    ),
  )
}

///|
test "Mach-O loader errors" {
  debug_inspect(
    @image.ImageBackend::macho().load(b"\x7fELF").map(_ => ()),
    content=(
      #|Err("not a Mach-O file")
    ),
  )
  debug_inspect(
    @image.ImageBackend::macho()
    .load(@objects.x86_64_macho()[:64].to_owned())
    .map(_ => ()),
    content=(
      #|Err("Mach-O load commands are out of bounds")
    ),
  )
}
