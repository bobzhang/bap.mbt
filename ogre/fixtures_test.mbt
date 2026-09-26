// Attributes shaped like the ones BAP's image loaders produce.

///|
let addr : @ogre.Field[Int64] = @ogre.def("addr", @ogre.Type::int())

///|
let size : @ogre.Field[Int64] = @ogre.def("size", @ogre.Type::int())

///|
let root : @ogre.Field[Int64] = @ogre.def("root", @ogre.Type::int())

///|
let name : @ogre.Field[String] = @ogre.def("name", @ogre.Type::str())

///|
let readable : @ogre.Field[Bool] = @ogre.def("r", @ogre.Type::bool())

///|
let writable : @ogre.Field[Bool] = @ogre.def("w", @ogre.Type::bool())

///|
let executable : @ogre.Field[Bool] = @ogre.def("x", @ogre.Type::bool())

///|
struct Segment {
  addr : Int64
  size : Int64
  r : Bool
  w : Bool
  x : Bool
} derive(Debug, Eq)

///|
let segment : @ogre.Attribute[Segment, (Int64, Int64, Bool, Bool, Bool)] = @ogre.Attribute::new(
  name="segment",
  @ogre.scheme5(addr, size, readable, writable, executable),
  t => { addr: t.0, size: t.1, r: t.2, w: t.3, x: t.4, },
)

///|
let named_symbol : @ogre.Attribute[(Int64, String), (Int64, String)] = @ogre.Attribute::new(
  name="named-symbol",
  @ogre.scheme(addr).add(name),
  t => t,
)

///|
let symbol_chunk : @ogre.Attribute[(Int64, Int64, Int64), (Int64, Int64, Int64)] = @ogre.Attribute::new(
  name="symbol-chunk",
  @ogre.scheme3(addr, size, root),
  t => t,
)

///|
let arch : @ogre.Attribute[String, String] = @ogre.Attribute::new(
  name="arch",
  @ogre.scheme(name),
  t => t,
)

///|
let entry_point : @ogre.Attribute[Int64, Int64] = @ogre.Attribute::new(
  name="entry-point",
  @ogre.scheme(addr),
  t => t,
)

///|
/// A loader in the style of BAP's `Image.Scheme` providers.
fn loader() -> @ogre.Ogre[Unit] {
  @ogre.provide(arch, "x86_64")
  .then(@ogre.provide(segment, (0L, 4096L, true, false, true)))
  .then(@ogre.provide(segment, (4096L, 8192L, true, true, false)))
  .then(@ogre.provide(named_symbol, (16L, "main")))
  .then(
    @ogre.provide(
      named_symbol,
      (32L, "a very long name with spaces (and parens)"),
    ),
  )
  .then(@ogre.provide(symbol_chunk, (16L, 8L, 16L)))
  .then(@ogre.provide(symbol_chunk, (32L, 4L, 32L)))
  // a duplicate fact is ignored
  .then(@ogre.provide(segment, (0L, 4096L, true, false, true)))
}

///|
fn loaded() -> @ogre.Doc raise {
  @ogre.exec(loader(), @ogre.Doc::empty())
}

///|
fn ogre_error(f : () -> Unit raise @ogre.OgreError) -> String {
  try f() catch {
    e => e.message()
  } noraise {
    _ => "no error"
  }
}
