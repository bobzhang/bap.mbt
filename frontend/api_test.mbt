// The `api` and `c-parser` plugins in the `bap` executable.

///|
fn bap_with(
  argv : Array[String],
  fs : @bap_main.FileSystem,
  env? : (String) -> String? = _ => None,
) -> String {
  let buf = StringBuilder()
  let code = @frontend.run(
    ["bap", ..argv],
    env~,
    fs~,
    out=s => buf.write_string(s),
    err=s => buf.write_string("[err] " + s),
    plugins=@frontend.plugin_table().filter(p => p.name != "cache"),
  )
  let out = @fixtures.normalize_tids(buf.to_string())
  if code == 0 {
    out
  } else {
    out + "[exit \{code}]"
  }
}

///|
fn fixture_fs() -> @bap_main.FileSystem {
  @fixtures.file_system([("bin/true", @fixtures.x86_64_elf())])
}

///|
fn user_api_fs(header : String) -> @bap_main.FileSystem {
  @api.overlay(
    @bap_main.FileSystem::in_memory(files=[("/my/api/c/user.h", header)], dirs=[
      "/my", "/my/api", "/my/api/c",
    ]),
    fixture_fs(),
  )
}

///|
test "bap --api-list-paths and --api-show" {
  inspect(
    bap_with(["--api-list-paths"], fixture_fs()),
    content=(
      #|/usr/local/share/bap-common/api
      #|
    ),
  )
  inspect(
    bap_with(["--api-show", "--api-path=/my/api"], user_api_fs("int f(void);")),
    content=(
      #|Language: c
      #|   android.h : /usr/local/share/bap-common/api/c/android.h
      #|   gnu.h : /usr/local/share/bap-common/api/c/gnu.h
      #|   posix.h : /usr/local/share/bap-common/api/c/posix.h
      #|   windows.h : /usr/local/share/bap-common/api/c/windows.h
      #|   user.h : /my/api/c/user.h
      #|
      #|Total number of available API: 5
      #|
    ),
  )
}

///|
test "bap --api-path overrides the bundled prototypes" {
  let subs = (out : String) => {
    out
    .split("\n")
    .filter(l => l.contains("sub ") || l.contains(" :: "))
    .map(l => l.to_owned())
    .collect()
    .join("\n")
  }
  inspect(
    subs(
      bap_with(
        ["bin/true", "-dbir", "--api-path=/my/api"],
        user_api_fs(
          (
            #|#define LONG long
            #|LONG foo(double x, char *s) __attribute__((noreturn));
            #|void main(void);
          ),
        ),
      ),
    ),
    content=(
      #|00000002: sub main()
      #|00000017: sub foo(foo_x, foo_s, foo_result)
      #|00000018: foo_x :: in u64 = low:64[YMM0]
      #|00000019: foo_s :: in out u64 = RDI
      #|00000020: foo_result :: out u64 = RAX
    ),
  )
  // a parse error in an API file fails the pass
  inspect(
    bap_with(["bin/true", "--api-path=/my/api"], user_api_fs("int f(")).contains(
      "user.h:1: expected a parameter declaration",
    ),
    content="true",
  )
}

///|
test "passes that upstream makes depend on api" {
  bap_with(["bin/true", "--optimization-level=1"], fixture_fs()) |> ignore
  let deps = (name : String) => {
    match @project.find_pass(name) {
      Some(p) => p.deps().join(",")
      None => "not registered"
    }
  }
  inspect(
    ["api", "optimization", "glibc-runtime"]
    .map(n => "\{n}: \{deps(n)}")
    .join("\n"),
    content=(
      #|api: abi
      #|optimization: api
      #|glibc-runtime: api
    ),
  )
}
