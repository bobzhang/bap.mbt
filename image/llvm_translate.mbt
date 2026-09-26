// Translation of the LLVM loader specification into the image
// specification (upstream `Bap_llvm_loader.translate`): the `llvm:*` facts
// the loaders emit become the `segment`, `mapped`, `section`,
// `named-region`, `code-region`, `symbol-chunk`, `code-start`, ... facts
// that `Image::from_spec` derives the image from.

///|
fn[A, K] llvm_rows(
  ctx : @ogre.Context,
  attr : @ogre.Attribute[A, K],
) -> Array[A] {
  spec_values(ctx.doc(), attr)
}

///|
/// `provide_base_and_bias` without a user base or a unit bias: the bias is
/// zero and the base address is the one of the file.
fn llvm_provide_base_and_bias(
  ctx : @ogre.Context,
) -> Int64 raise @ogre.OgreError {
  let real = ctx.require(llvm_base_address())
  let bias = 0L
  ctx.provide(Scheme::bias(), bias)
  ctx.provide(Scheme::base_address(), real + bias)
  bias
}

///|
fn llvm_provide_entry(
  ctx : @ogre.Context,
  bias : Int64,
) -> Unit raise @ogre.OgreError {
  ctx.provide(Scheme::entry_point(), ctx.require(llvm_entry_point()) + bias)
}

///|
/// Symbols with a size are chunks of code starting at their address, and
/// the code starts if they are code entries (functions); every symbol
/// names its address and has a value.
fn llvm_provide_symbols(
  ctx : @ogre.Context,
  bias : Int64,
) -> Unit raise @ogre.OgreError {
  let code_entries = llvm_rows(ctx, llvm_code_entry())
  for entry in llvm_rows(ctx, llvm_symbol_entry()) {
    let (name, addr, size, off, value) = entry
    let addr = addr + bias
    if size > 0L {
      ctx.provide(Scheme::symbol_chunk(), (addr, size, addr))
      if code_entries.any(e => e.0 == name && e.1 == off && e.2 == size) {
        ctx.provide(Scheme::code_start(), addr)
      }
    }
    ctx.provide(Scheme::symbol_value(), (addr, value))
    ctx.provide(Scheme::named_symbol(), (addr, name))
  }
}

///|
fn llvm_provide_generic_sections(
  ctx : @ogre.Context,
  bias : Int64,
) -> Unit raise @ogre.OgreError {
  for entry in llvm_rows(ctx, llvm_section_entry()) {
    let (name, addr, size, _) = entry
    let addr = addr + bias
    ctx.provide(Scheme::section(), (addr, size))
    ctx.provide(Scheme::named_region(), (addr, size, name))
  }
}

///|
fn llvm_provide_relocations(
  ctx : @ogre.Context,
  bias : Int64,
) -> Unit raise @ogre.OgreError {
  for r in llvm_rows(ctx, llvm_relocation()) {
    ctx.provide(Scheme::relocation(), (r.0 + bias, r.1 + bias))
  }
  for at in llvm_rows(ctx, llvm_relative_relocation()) {
    ctx.provide(Scheme::relative_relocation(), at + bias)
  }
  for r in llvm_rows(ctx, llvm_name_reference()) {
    ctx.provide(Scheme::external_reference(), (r.0 + bias, r.1))
  }
}

///|
/// Named regions that are code entries of the same size are code regions.
fn llvm_provide_generic_code_regions(
  ctx : @ogre.Context,
) -> Unit raise @ogre.OgreError {
  let entries = llvm_rows(ctx, llvm_code_entry())
  for region in llvm_rows(ctx, Scheme::named_region()) {
    for entry in entries {
      let (name, off, size) = entry
      if region.info == name && region.size == size {
        ctx.provide(Scheme::code_region(), (region.addr, region.size, off))
      }
    }
  }
}

///|
/// Mach-O: the segment commands with a file image are segments.
fn llvm_provide_macho_segmentation(
  ctx : @ogre.Context,
  bias : Int64,
) -> Unit raise @ogre.OgreError {
  let flags = llvm_rows(ctx, llvm_segment_command_flags())
  let virtuals = llvm_rows(ctx, llvm_virtual_segment_command())
  for cmd in llvm_rows(ctx, llvm_segment_command()) {
    let (name, off, size) = cmd
    for f in flags {
      if f.0 != name {
        continue
      }
      for v in virtuals {
        if v.0 != name {
          continue
        }
        let addr = bias + v.1
        let vsize = v.2
        if size != 0L {
          ctx.provide(Scheme::segment(), (addr, vsize, f.1, f.2, f.3))
          ctx.provide(Scheme::named_region(), (addr, vsize, name))
          ctx.provide(Scheme::mapped(), (addr, size, off))
        }
      }
    }
  }
  llvm_provide_generic_sections(ctx, bias)
  llvm_provide_generic_code_regions(ctx)
}

///|
/// COFF: the sections are segments, and the executable ones code regions.
fn llvm_provide_coff_segmentation(
  ctx : @ogre.Context,
  bias : Int64,
) -> Unit raise @ogre.OgreError {
  let virtuals = llvm_rows(ctx, llvm_coff_virtual_section_header())
  let flags = llvm_rows(ctx, llvm_section_flags())
  for entry in llvm_rows(ctx, llvm_section_entry()) {
    let (name, _, size, start) = entry
    for v in virtuals {
      if v.0 != name {
        continue
      }
      for f in flags {
        if f.0 != name {
          continue
        }
        let addr = v.1 + bias
        let vsize = v.2
        let (r, w, x) = (f.1, f.2, f.3)
        if size != 0L {
          ctx.provide(Scheme::segment(), (addr, vsize, r, w, x))
          ctx.provide(Scheme::mapped(), (addr, size, start))
          ctx.provide(Scheme::section(), (addr, vsize))
          ctx.provide(Scheme::named_region(), (addr, vsize, name))
        }
        if x {
          ctx.provide(Scheme::code_region(), (addr, vsize, start))
        }
      }
    }
  }
}

///|
/// The function starts of the port's `llvm:function-start` facts are code
/// starts (disassembly roots).
fn llvm_provide_function_starts(
  ctx : @ogre.Context,
  bias : Int64,
) -> Unit raise @ogre.OgreError {
  for addr in llvm_rows(ctx, llvm_function_start()) {
    ctx.provide(Scheme::code_start(), addr + bias)
  }
}

///|
/// Translates an LLVM loader specification into an image specification
/// (upstream `translate`): the result has both the `llvm:*` facts and the
/// image facts derived from them. The `macho` and `coff` formats are
/// translated; the port loads ELF files with its own loader.
fn llvm_translate(doc : OgreDoc) -> OgreDoc raise @ogre.OgreError {
  let ctx = @ogre.Context::new(doc)
  let bias = llvm_provide_base_and_bias(ctx)
  llvm_provide_entry(ctx, bias)
  match ctx.require(Scheme::format()) {
    "macho" => llvm_provide_macho_segmentation(ctx, bias)
    "coff" => llvm_provide_coff_segmentation(ctx, bias)
    _ => ()
  }
  llvm_provide_symbols(ctx, bias)
  llvm_provide_relocations(ctx, bias)
  llvm_provide_function_starts(ctx, bias)
  ctx.doc()
}
