// Contexts, overloading resolution, attributes and packages.

///|
test "context order" {
  let ctx = @primus_lisp.Context::create
  let arm = ctx([("arch", ["arm"])])
  let arm_gcc = ctx([("arch", ["arm"]), ("compiler", ["gcc"])])
  let x86 = ctx([("arch", ["x86"])])
  debug_inspect(arm.order(arm_gcc), content="Less")
  debug_inspect(arm_gcc.order(arm), content="Greater")
  debug_inspect(arm.order(x86), content="Incomparable")
  debug_inspect(arm.order(arm), content="Equal")
  debug_inspect(@primus_lisp.Context::empty().le(x86), content="true")
  inspect(arm.merge(x86), content="(context (arch arm x86))")
  let t = @primus_lisp.Context::of_target(@core_theory.Target::x86_64())
  inspect(t.features("arch").join(","), content="x86_64")
  inspect(t.features("bits").join(","), content="64")
  inspect(t.features("endian").join(","), content="little")
  debug_inspect(t.features("target").contains("amd64"), content="true")
}

///|
fn load(
  src : String,
  ctxt? : @primus_lisp.Context,
) -> @primus_lisp.Program raise {
  let loader = @primus_lisp.Loader::of_files([("test.lisp", src)])
  match ctxt {
    Some(c) => @primus_lisp.load_program(loader, ["test"], context=c)
    None => @primus_lisp.load_program(loader, ["test"])
  }
}

///|
fn resolved_body(
  prog : @primus_lisp.Program,
  name : String,
  nargs : Int32,
) -> String {
  let args = Array::make(nargs, ())
  match
    @primus_lisp.resolve_defun(
      prog,
      (_, _) => true,
      @knowledge.Name::read(name),
      args,
    ) {
    None => "unbound"
    Some(Err(r)) => {
      let s = r.to_string()
      let lines : Array[StringView] = s.split("\n").collect()
      "error: \{lines[0]}"
    }
    Some(Ok((d, _))) => d.code.body.to_string()
  }
}

///|
test "resolution by context specificity and arity" {
  let src =
    #|(defun f () 'generic)
    #|(defun f () (declare (context (arch x86_64))) 'x86-64)
    #|(defun f () (declare (context (arch arm))) 'arm)
    #|(defun g (x) 'one)
    #|(defun g (x y) 'two)
    #|(defun h () (declare (context (arch x86_64))) 'a)
    #|(defun h () (declare (context (bits 64))) 'b)
  let x86 = load(
    src,
    ctxt=@primus_lisp.Context::of_target(@core_theory.Target::x86_64()),
  )
  let mips = load(
    src,
    ctxt=@primus_lisp.Context::of_target(@core_theory.Target::mips()),
  )
  inspect(resolved_body(x86, "f", 0), content="x86-64")
  inspect(resolved_body(mips, "f", 0), content="generic")
  inspect(resolved_body(x86, "g", 1), content="one")
  inspect(resolved_body(x86, "g", 2), content="two")
  inspect(
    resolved_body(x86, "g", 3),
    content="error: no suitable definitions were found.",
  )
  inspect(
    resolved_body(x86, "h", 0),
    content=(
      #|error: no suitable definitions were found.
    ),
  )
  inspect(
    resolved_body(mips, "h", 0),
    content="error: no suitable definitions were found.",
  )
  inspect(resolved_body(x86, "nosuch", 0), content="unbound")
}

///|
test "attributes" {
  let src =
    #|(defun strlen (p)
    #|  "computes the length of a string"
    #|  (declare (external "strlen" "my_strlen") (visibility :private))
    #|  0)
    #|(defun trace (x) (declare (advice :before strlen puts) (advice :after exit)) x)
    #|(defun counter () (declare (global count:32) (static seed)) count)
  let prog = load(src)
  let get = (n : String) => prog.get(@primus_lisp.func, name=n)[0]
  let d = get("strlen")
  inspect(d.docs, content="computes the length of a string")
  inspect(
    d.attrs.externals.to_array().join(","),
    content=(
      #|strlen,my_strlen
    ),
  )
  debug_inspect(d.attrs.is_public(), content="false")
  let t = get("trace")
  inspect(
    t.attrs.advice(Before).map(n => n.show()).join(","),
    content="external:puts,external:strlen",
  )
  inspect(
    t.attrs.advice(After).map(n => n.show()).join(","),
    content="external:exit",
  )
  let c = get("counter")
  inspect(c.attrs.globals.map(v => v.to_string()).join(","), content="count:32")
  inspect(c.attrs.statics.map(v => v.to_string()).join(","), content="seed")
  let err = try load("(defun f () (declare (frobnicate 1)) 0)") catch {
    e => e.to_string()
  } noraise {
    _ => "no error"
  }
  inspect(
    err,
    content=(
      #|File "test.lisp", line 1, characters 21-35
      #|Parse error: unknown attribute `core:frobnicate'
    ),
  )
  // custom attributes
  @primus_lisp.declare_attribute("frobnicate")
  let p = load("(defun f () (declare (frobnicate 1 2)) 0)")
  inspect(
    p.get(@primus_lisp.func, name="f")[0].attrs
    .get_custom("core:frobnicate")
    .length(),
    content="1",
  )
}

///|
test "packages and visibility" {
  let src =
    #|(defpackage lib (:documentation "a library"))
    #|(defpackage app (:use lib))
    #|(in-package lib)
    #|(defun api () 1)
    #|(defun helper () (declare (visibility :private)) 2)
    #|(in-package app)
    #|(defun main () (api))
  let prog = load(src)
  let names = (pkg : String) => {
    prog.with_package(pkg).get(@primus_lisp.func).map(d => d.name).join(",")
  }
  inspect(names("lib"), content="api,helper")
  inspect(names("app"), content="api,main")
  inspect(names("user"), content="")
  debug_inspect(
    prog.packages(),
    content=(
      #|[("app", ""), ("lib", "a library")]
    ),
  )
}
