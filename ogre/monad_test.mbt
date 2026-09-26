///|
test "provide builds the document a loader describes" {
  let doc = loaded()
  inspect(
    doc.to_string(),
    content=(
      #|(declare arch (name str))
      #|(declare named-symbol (addr int) (name str))
      #|(declare segment (addr int) (size int) (r bool) (w bool) (x bool))
      #|(declare symbol-chunk (addr int) (size int) (root int))
      #|
      #|(arch x86_64)
      #|(named-symbol 32 "a very long name with spaces (and parens)")
      #|(named-symbol 16 main)
      #|(segment 4096 8192 true true false)
      #|(segment 0 4096 true false true)
      #|(symbol-chunk 32 4 32)
      #|(symbol-chunk 16 8 16)
      #|
    ),
  )
  inspect(doc.declarations(), content="4")
  // upstream counts attributes with facts, not facts
  inspect(doc.definitions(), content="4")
  // the textual form reads back into an equal document after two rounds
  let twice = @ogre.Doc::from_string(
    @ogre.Doc::from_string(doc.to_string()).to_string(),
  )
  assert_true(twice == doc)
  // Doc::put / Doc::get are the pure counterparts
  let direct = @ogre.Doc::empty()
    .put(segment, (0L, 4096L, true, false, true))
    .put(entry_point, 0x400000L)
  debug_inspect(
    direct.get(segment),
    content=(
      #|[{ addr: 0, size: 4096, r: true, w: false, x: true }]
    ),
  )
  debug_inspect(direct.get(entry_point), content="[4194304]")
  debug_inspect(direct.get(arch), content="[]")
  inspect(segment.name(), content="segment")
  debug_inspect(
    segment.pack((1L, 2L, false, false, true)).fields(),
    content=(
      #|[
      #|  ("addr", "1"),
      #|  ("r", "false"),
      #|  ("size", "2"),
      #|  ("w", "false"),
      #|  ("x", "true"),
      #|]
    ),
  )
}

///|
test "require and request" {
  let doc = loaded()
  assert_eq(@ogre.eval(@ogre.require(arch), doc), "x86_64")
  assert_eq(@ogre.eval(@ogre.require(segment, that=s => s.w), doc).addr, 4096L)
  inspect(
    ogre_error(() => ignore(@ogre.eval(@ogre.require(segment), doc))),
    content="required attribute segment values are ambiguous",
  )
  inspect(
    ogre_error(() => {
      ignore(@ogre.eval(@ogre.require(segment, that=s => s.addr > 10000L), doc))
    }),
    content="required attribute segment doesn't satisfy the constraint",
  )
  inspect(
    ogre_error(() => ignore(@ogre.eval(@ogre.require(entry_point), doc))),
    content="required attribute entry-point is not provided",
  )
  assert_eq(@ogre.eval(@ogre.request(entry_point), doc), None)
  assert_eq(@ogre.eval(@ogre.request(arch), doc), Some("x86_64"))
  assert_eq(
    @ogre.eval(@ogre.request(segment, that=s => s.addr == 0L), doc).map(s => {
      s.size
    }),
    Some(4096L),
  )
  assert_eq(
    @ogre.eval(@ogre.request(segment, that=s => s.addr == 1L), doc),
    None,
  )
  inspect(
    ogre_error(() => ignore(@ogre.eval(@ogre.request(segment), doc))),
    content="requested attribute segment values are ambiguous",
  )
}

///|
test "provide fails on a conflicting declaration and leaves no partial state" {
  let doc = loaded()
  let bogus : @ogre.Attribute[Int64, Int64] = @ogre.Attribute::new(
    name="arch",
    @ogre.scheme(@ogre.def("name", @ogre.Type::int())),
    t => t,
  )
  inspect(
    ogre_error(() => ignore(@ogre.exec(@ogre.provide(bogus, 1L), doc))),
    content="failed to save an attribute",
  )
  try doc.put(bogus, 1L) catch {
    e =>
      inspect(
        e,
        content=(
          #|Failed to parse an OGRE document, got a signature mismatch. Expected:
          #|(((fname name) (ftype Str)))
          #|Got:
          #|(((fname name) (ftype Int)))
          #|
        ),
      )
  } noraise {
    _ => abort("expected a signature mismatch")
  }
  // the original document is persistent
  assert_eq(doc.facts("arch").length(), 1)
}

///|
test "foreach, collect and the monadic combinators" {
  let doc = loaded()
  let sizes = @ogre.foreach(@ogre.select(@ogre.from(segment)), s => s.size)
  debug_inspect(@ogre.eval(sizes, doc), content="[8192, 4096]")
  let total = sizes.map(xs => xs.fold(init=0L, (a, b) => a + b))
  assert_eq(@ogre.eval(total, doc), 12288L)
  let names = @ogre.collect(@ogre.select(@ogre.from(named_symbol))).bind(syms => {
    @ogre.Ogre::map_array(syms, sym => @ogre.Ogre::pure(sym.1))
  })
  debug_inspect(
    @ogre.eval(names, doc),
    content=(
      #|["a very long name with spaces (and parens)", "main"]
    ),
  )
  let both = @ogre.require(arch).both(@ogre.request(entry_point))
  debug_inspect(
    @ogre.eval(both, doc),
    content=(
      #|("x86_64", None)
    ),
  )
  // provide inside a computation is visible to later queries
  let program = @ogre.provide(entry_point, 16L).then(@ogre.require(entry_point))
  let (value, updated) = @ogre.run(program, doc)
  assert_eq(value, 16L)
  assert_eq(updated.facts("entry-point").length(), 1)
  assert_eq(doc.facts("entry-point").length(), 0)
  // fold/iter/all over arrays
  let provide_all = @ogre.Ogre::iter([1L, 2L, 3L], a => {
    @ogre.provide(named_symbol, (a, "sym\{a}"))
  })
  let doc2 = @ogre.exec(provide_all, @ogre.Doc::empty())
  inspect(
    doc2.to_string(),
    content=(
      #|(declare named-symbol (addr int) (name str))
      #|
      #|(named-symbol 3 sym3)
      #|(named-symbol 2 sym2)
      #|(named-symbol 1 sym1)
      #|
    ),
  )
  let sum = @ogre.Ogre::fold([1, 2, 3], init=10, (acc, x) => {
    @ogre.Ogre::pure(acc + x)
  })
  assert_eq(@ogre.eval(sum, doc), 16)
  let all = @ogre.Ogre::all([@ogre.Ogre::pure(1), @ogre.Ogre::lift(2)])
  debug_inspect(@ogre.eval(all, doc), content="[1, 2]")
  let nested = @ogre.Ogre::pure(@ogre.Ogre::pure("inner")).join()
  assert_eq(@ogre.eval(nested, doc), "inner")
  let unit = @ogre.Ogre::all_unit([@ogre.provide(entry_point, 1L).ignore()])
  assert_eq(@ogre.exec(unit, doc).facts("entry-point").length(), 1)
}

///|
test "failures abort the computation" {
  let doc = loaded()
  let failing : @ogre.Ogre[Int] = @ogre.provide(entry_point, 1L).then(
    @ogre.Ogre::failf("the file type elf is unsupported"),
  )
  inspect(
    ogre_error(() => ignore(@ogre.exec(failing, doc))),
    content="the file type elf is unsupported",
  )
  let never_reached = failing.bind(_ => @ogre.provide(arch, "arm"))
  inspect(
    ogre_error(() => ignore(@ogre.eval(never_reached, doc))),
    content="the file type elf is unsupported",
  )
  let failed : @ogre.Ogre[Unit] = @ogre.Ogre::fail(OgreError("boom"))
  inspect(ogre_error(() => @ogre.eval(failed, doc)), content="boom")
}

///|
test "direct style over a context" {
  let ctx = @ogre.Context::new(@ogre.Doc::empty())
  ctx.provide(segment, (0L, 16L, true, false, true))
  ctx.provide(named_symbol, (4L, "start"))
  let seg = ctx.require(segment)
  assert_eq(seg.size, 16L)
  assert_eq(ctx.request(entry_point), None)
  let inside = ctx.foreach(
    @ogre.select(
      where_=segment[addr].le(named_symbol[addr]),
      @ogre.from2(segment, named_symbol),
    ),
    p => p.1.1,
  )
  debug_inspect(
    inside,
    content=(
      #|["start"]
    ),
  )
  debug_inspect(ctx.collect(@ogre.select(@ogre.from(arch))), content="[]")
  // Ogre computations can be run in an existing context
  @ogre.provide(arch, "arm").perform(ctx)
  let custom = @ogre.Ogre::make(c => {
    c.require(arch) + "/" + c.doc().declarations().to_string()
  })
  assert_eq(custom.perform(ctx), "arm/3")
  assert_eq(ctx.doc().declarations(), 3)
}
