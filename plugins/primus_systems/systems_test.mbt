///|
test "the core systems are registered once" {
  let loaded = @primus_systems.load_core_systems()
  debug_inspect(
    loaded.map(s => s.name().show()),
    content=(
      #|[
      #|  "bap:binary-executor",
      #|  "bap:base-lisp-machine",
      #|  "bap:stubbed-executor",
      #|  "bap:terminating-stubbed-executor",
      #|  "bap:microexecutor-base",
      #|  "bap:promiscuous-executor",
      #|  "bap:symbolic-executor",
      #|  "bap:base-taint-analyzer",
      #|  "bap:taint-analyzer",
      #|  "bap:reflective-taint-analyzer",
      #|  "bap:exact-taint-analyzer",
      #|  "bap:constant-tracker",
      #|  "bap:multi-analyzer",
      #|  "bap:string-deobfuscator",
      #|]
    ),
  )
  assert_true(@primus_systems.load_core_systems().is_empty())
  let sys = @primus.System::get("promiscuous-executor", pkg="bap")
  debug_inspect(
    sys.dependencies().map(d => d.show()),
    content=(
      #|["bap:microexecutor-base"]
    ),
  )
  let all = sys.all_components().map(c => c.show())
  assert_true(all.contains("bap:promiscuous-path-explorer"))
  assert_true(all.contains("bap:greedy-scheduler"))
  assert_true(all.contains("bap:program-loader"))
}

///|
test "systems are loaded from the .asd files of a directory" {
  @bap_main.set_file_system(
    @bap_main.FileSystem::in_memory(
      files=[
        (
          "/systems/mine.asd", "(defsystem test:mine :description \"my system\" :components (bap:limit)) (defsystem test:other :depends-on (test:mine))",
        ),
        ("/systems/broken.asd", "(defsystem test:broken :components bap:limit)"),
        ("/systems/notes.txt", "(defsystem test:ignored)"),
      ],
      dirs=["/systems"],
    ),
  )
  let loaded = @primus_systems.load_directory("/systems")
  @bap_main.set_file_system(@bap_main.FileSystem::native())
  debug_inspect(
    loaded.map(s => s.name().show()),
    content=(
      #|["test:mine", "test:other"]
    ),
  )
  inspect(
    @primus_systems.info_listing(@primus.System::list(), ["test:mine"]),
    content=(
      #|- test:mine:
      #|my system
      #|
      #|
      #|
    ),
  )
  assert_true(@primus_systems.load_directory("/no/such/dir").is_empty())
}
