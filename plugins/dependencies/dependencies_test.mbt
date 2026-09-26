///|
fn spec_text(
  symbols : Array[(Int64, String)],
  externals : Array[(Int64, String)],
  libs : Array[String],
) -> String raise {
  let mut doc = @ogre.Doc::empty().put(@image.Scheme::entry_point(), 0L)
  for s in symbols {
    doc = doc.put(@image.Scheme::named_symbol(), s)
  }
  for r in externals {
    doc = doc.put(@image.Scheme::external_reference(), r)
  }
  for lib in libs {
    doc = doc.put(@image.Scheme::require(), lib)
  }
  doc.to_string()
}

///|
test "dependency information from a specification" {
  let doc = @ogre.Doc::from_string(
    spec_text(
      [(0L, "puts"), (0x1000L, "main"), (0L, "exit"), (0x2000L, "helper")],
      [(0x10L, "puts"), (0x18L, "exit"), (0x20L, "defined_elsewhere")],
      ["libc.so.6", "libm.so.6"],
    ),
  )
  debug_inspect(
    @dependencies.DependencyInfo::of_spec("/bin/ls", doc),
    content=(
      #|{
      #|  name: "ls",
      #|  imports: ["exit", "puts"],
      #|  exports: ["helper", "main"],
      #|  libraries: ["libc.so.6", "libm.so.6"],
      #|}
    ),
  )
}

///|
test "ldconfig cache and search" {
  let cache = @dependencies.LdconfigCache::parse(
    (
      #|2 libs found in cache `/etc/ld.so.cache'
      #|	libc.so.6 (libc6,x86-64) => /lib/x86_64-linux-gnu/libc.so.6
      #|	libm.so.6 (libc6,x86-64) => /lib/x86_64-linux-gnu/libm.so.6
    ),
  )
  debug_inspect(
    cache.lookup("libm.so.6"),
    content=(
      #|Some("/lib/x86_64-linux-gnu/libm.so.6")
    ),
  )
  let fs = @bap_main.FileSystem::in_memory(files=[
    ("/mnt/bin/ls", ""),
    ("/opt/lib/libz.so", ""),
  ])
  debug_inspect(
    [
      @dependencies.search("/bin/ls", root="/mnt", fs~),
      @dependencies.search("/bin/ls", fs~),
      @dependencies.search("libc.so.6", ldconfig=cache, fs~),
      @dependencies.search("libz.so", paths=["/usr/lib", "/opt/lib"], fs~),
      @dependencies.search("libq.so", paths=["/opt/lib"], fs~),
    ],
    content=(
      #|[
      #|  Some("/mnt/bin/ls"),
      #|  None,
      #|  Some("/lib/x86_64-linux-gnu/libc.so.6"),
      #|  Some("/opt/lib/libz.so"),
      #|  None,
      #|]
    ),
  )
}

///|
fn sample_state() -> @dependencies.DependencyState {
  @dependencies.DependencyState::{
    root: "ls",
    units: {
      "ls": @dependencies.DependencyInfo::{
        name: "ls",
        imports: ["exit", "puts"],
        exports: ["main"],
        libraries: ["libc.so.6"],
      },
      "libc.so.6": @dependencies.DependencyInfo::{
        name: "libc.so.6",
        imports: [],
        exports: ["exit", "puts"],
        libraries: [],
      },
    },
  }
}

///|
test "output formats" {
  let state = sample_state()
  inspect(
    state.render(Yaml),
    content=(
      #|
      #|libc.so.6:
      #|  imports:
      #|
      #|  exports:
      #|    - exit
      #|    - puts
      #|  libraries:
      #|
      #|
      #|
      #|ls:
      #|  imports:
      #|    - exit
      #|    - puts
      #|  exports:
      #|    - main
      #|  libraries:
      #|    - libc.so.6
      #|
      #|
      #|
    ),
  )
  inspect(
    state.render(Sexp),
    content=(
      #|(libc.so.6 (exports exit puts))
      #|(ls (imports exit puts) (exports main) (libraries libc.so.6))
      #|
      #|
    ),
  )
  inspect(
    state.render(Json),
    content=(
      #|{
      #|  "libc.so.6": {
      #|    "imports": [],
      #|    "exports": ["exit", "puts"],
      #|    "libraries": []
      #|  },
      #|  "ls": {
      #|    "imports": ["exit", "puts"],
      #|    "exports": ["main"],
      #|    "libraries": ["libc.so.6"]
      #|  }
      #|}
      #|
    ),
  )
  inspect(
    state.render(Graph),
    content=(
      #|digraph "ls" {
      #|
      #|"ls" -> "libc.so.6"
      #|
      #|}
      #|
    ),
  )
}

///|
test "missing and unloadable units are empty" {
  let fs = @bap_main.FileSystem::in_memory(files=[("/bin/junk", "not a binary")])
  let state = @dependencies.DependencyState::load(
    "/bin/junk",
    recursive=true,
    fs~,
  )
  debug_inspect(
    state.sorted_units(),
    content=(
      #|[{ name: "/bin/junk", imports: [], exports: [], libraries: [] }]
    ),
  )
  let missing = @dependencies.load_unit("libnothing.so", fs~)
  inspect(missing.name, content="libnothing.so")
}

///|
test "the command is declared" {
  @bap_main.reset()
  @bap_main.set_file_system(@bap_main.FileSystem::in_memory(files=[]))
  let out = StringBuilder()
  @dependencies.declare_plugin(out=s => out.write_string(s))
  @bap_main.initialize(
    argv=["bap", "dependencies", "/missing", "--format=sexp"],
    name="bap",
    env=_ => None,
    out=_ => (),
    err=_ => (),
  )
  inspect(
    out.to_string(),
    content=(
      #|(/missing)
      #|
      #|
    ),
  )
  @bap_main.reset()
}

///|
test "recursive loading through ogre images" {
  let app = spec_text([(0L, "f"), (0x10L, "main")], [(0x8L, "f")], ["libf.ogre"])
  let lib = spec_text([(0x20L, "f")], [], ["libg.ogre"])
  let fs = @bap_main.FileSystem::in_memory(files=[
    ("/work/app.ogre", app),
    ("/libs/libf.ogre", lib),
  ])
  let cache = @dependencies.DependencyCache::new()
  let state = @dependencies.DependencyState::load(
    "/work/app.ogre",
    recursive=true,
    paths=["/libs"],
    cache~,
    fs~,
  )
  inspect(
    state.render(Sexp),
    content=(
      #|(app.ogre (imports f) (exports main) (libraries libf.ogre))
      #|(libf.ogre (exports f) (libraries libg.ogre))
      #|(libg.ogre)
      #|
      #|
    ),
  )
  let flat = @dependencies.DependencyState::load(
    "/work/app.ogre",
    paths=["/libs"],
    fs~,
  )
  inspect(flat.units.length(), content="1")
}
