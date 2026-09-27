// Tests of the `api` plugin: the bundled API files, the API directories,
// and the application of the C prototypes through the ABIs.

///|
fn read_bundled(path : String) -> String? {
  let site = @api.site_dir()
  for f in @api.bundled_api_files() {
    if site + "/" + f.0 == path {
      return Some(f.1)
    }
  }
  None
}

///|
test "all bundled API files parse" {
  let site = @api.site_dir()
  inspect(
    @api.bundled_api_files().map(f => f.0).join(" "),
    content="c/android.h c/gnu.h c/posix.h c/windows.h",
  )
  for model in [@c.Model::LP64, ILP32, LP32, LLP64, ILP64] {
    for f in @api.bundled_api_files() {
      match
        @c_parser.parse_file(
          @c.SizeBase::new(model),
          site + "/" + f.0,
          read_file=read_bundled,
        ) {
        Ok(_) => ()
        Err(e) => fail("\{f.0} (\{model.to_string()}): \{e}")
      }
    }
  }
  let count = (name : String) => {
    match
      @c_parser.parse_file(
        @c.SizeBase::new(LP64),
        site + "/c/" + name,
        read_file=read_bundled,
      ) {
      Ok(decls) =>
        decls.length() -
        @c_parser.predefined_types(@c.SizeBase::new(LP64)).length()
      Err(_) => -1
    }
  }
  debug_inspect(
    ["android.h", "gnu.h", "posix.h", "windows.h"].map(count),
    content=(
      #|[1, 2, 305, 1]
    ),
  )
}

///|
test "posix.h prototypes" {
  let decls = @c_parser.parse_file(
    @c.SizeBase::new(LP64),
    @api.site_dir() + "/c/posix.h",
    read_file=read_bundled,
  ).unwrap()
  let find = (name : String) => {
    match decls.search_by(d => d.0 == name) {
      Some(i) => decls[i].1.to_string()
      None => "missing"
    }
  }
  inspect(
    ["strlen", "malloc", "printf", "qsort", "exit", "socketpair", "getopt_long"]
    .map(n => "\{n}: \{find(n)}")
    .join("\n"),
    content=(
      #|strlen: unsigned long (*)( const char* s) __attribute__((pure, nonnull(1), storage(1))) ;
      #|malloc: void* (*)(unsigned long size) __attribute__((malloc, warn_unused_result, alloc_size(1))) ;
      #|printf: signed (*)( const char restrict * format, ...) __attribute__((format(printf, 1, 2))) ;
      #|qsort: void (*)(void* base, unsigned long nmemb, unsigned long size, signed (*)(void* , void* );* compare) __attribute__((nonnull(1, 4))) ;
      #|exit: void (*)(signed code) __attribute__((noreturn)) ;
      #|socketpair: signed (*)(signed domain, signed type, signed protocol, signed[2] fds) __attribute__((warn_unused_result)) ;
      #|getopt_long: signed (*)(signed argc, char const *[] argv,  const char* optstring, struct option* longopts, signed* longindex);
    ),
  )
}

///|
test "paths" {
  inspect(@api.reduce("/a/./b//c/../d/"), content="/a/b/d")
  inspect(@api.reduce("a/../../b"), content="../b")
  inspect(@api.reduce("."), content=".")
  inspect(
    @api.path_of_string("~/apis/../api", getenv=v => {
      if v == "HOME" {
        Some("/home/u")
      } else {
        None
      }
    }),
    content="/home/u/api",
  )
  inspect(@api.site_dir(), content="/usr/local/share/bap-common/api")
}

///|
/// Runs `f` with the in-memory file system of `files` (and their
/// directories) installed in `bap_main`.
fn with_fs(files : Array[(String, String)], f : () -> Unit raise) -> Unit raise {
  let dirs = []
  for file in files {
    let parts = file.0.split("/").map(s => s.to_owned()).collect()
    for i in 2..<parts.length() {
      let d = parts[0:i].to_owned().join("/")
      if !dirs.contains(d) {
        dirs.push(d)
      }
    }
  }
  let saved = @bap_main.file_system()
  @bap_main.set_file_system(@bap_main.FileSystem::in_memory(files~, dirs~))
  defer @bap_main.set_file_system(saved)
  f()
}

///|
fn no_env(v : String) -> String? {
  if v == "HOME" {
    Some("/home/u")
  } else {
    None
  }
}

///|
test "API directories, --api-list-paths and --api-show" {
  with_fs(
    [
      ("/work/api/c/mine.h", "int mine(void);"),
      ("/work/api/c/sub/deep.h", "int deep(void);"),
      ("/env/api/c/env.h", "int env(void);"),
      ("/home/u/.local/share/bap/api/c/user.h", "int user(void);"),
    ],
    () => {
      let getenv = (v : String) => {
        match v {
          "BAP_API_PATH" => Some("/env/api:/missing")
          v => no_env(v)
        }
      }
      let paths = @api.with_bundled_files(() => {
        @api.all_paths(["/work/api", "/nope"], getenv~)
      })
      inspect(
        @api.list_paths(paths),
        content=(
          #|/home/u/.local/share/bap/api
          #|/env/api
          #|/usr/local/share/bap-common/api
          #|/work/api
          #|
        ),
      )
      inspect(
        @api.with_bundled_files(() => @api.show_apis(paths)),
        content=(
          #|Language: c
          #|   user.h : /home/u/.local/share/bap/api/c/user.h
          #|   env.h : /env/api/c/env.h
          #|   android.h : /usr/local/share/bap-common/api/c/android.h
          #|   gnu.h : /usr/local/share/bap-common/api/c/gnu.h
          #|   posix.h : /usr/local/share/bap-common/api/c/posix.h
          #|   windows.h : /usr/local/share/bap-common/api/c/windows.h
          #|   mine.h : /work/api/c/mine.h
          #|
          #|Language: sub
          #|   deep.h : /work/api/c/sub/deep.h
          #|
          #|Total number of available API: 8
          #|
        ),
      )
      // `deep.h` is in `c/sub`, so its language is `sub`
      debug_inspect(
        @api.with_bundled_files(() => @api.find_apis("/work/api")),
        content=(
          #|[
          #|  { desc: { lang: "c", name: "mine.h" }, path: "/work/api/c/mine.h" },
          #|  {
          #|    desc: { lang: "sub", name: "deep.h" },
          #|    path: "/work/api/c/sub/deep.h",
          #|  },
          #|]
        ),
      )
      inspect(
        @api.with_bundled_files(() => @api.files(paths, "c")).length(),
        content="8",
      )
    },
  )
}
