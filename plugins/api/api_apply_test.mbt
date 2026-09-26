// The `api` pass applied to hand-built projects: the prototypes of the
// bundled APIs are inserted as argument terms through the ABI of the
// project's target.

///|
fn stub_project(target : @core_theory.Target) -> @project.Project {
  let subs = [
    "strlen", "malloc", "exit", "printf", "memcpy", "no_such_function",
  ].map(name => @types.Sub::create(name~))
  @project.Project::create(target~, program=@types.Program::create(subs~))
}

///|
fn render_sub(sub : @types.Term[@types.Sub]) -> String {
  let lines = []
  let flags = []
  if sub.is_malloc() {
    flags.push("malloc")
  }
  if sub.is_noreturn() {
    flags.push("noreturn")
  }
  lines.push(
    @types.Sub::name(sub) +
    (if flags.is_empty() { "" } else { " [" + flags.join(", ") + "]" }),
  )
  for arg in sub.args() {
    let ctype = match @c.type_tag().get(arg) {
      Some(t) => t.to_string()
      None => "?"
    }
    lines.push(
      "  \{@types.Arg::to_string(arg).trim_end(chars="\n")}  /* \{ctype} */",
    )
  }
  lines.join("\n")
}

///|
fn apply_api(target : @core_theory.Target) -> String raise {
  @c_parser.provide()
  let project = match @api.pass(getenv=_ => None).run(stub_project(target)) {
    Ok(p) => p
    Err(e) => fail(e.to_string())
  }
  project.program().subs().map(render_sub).join("\n")
}

///|
test "api pass on x86-64 (System V)" {
  @x86_abi.install_calling_conventions()
  inspect(
    apply_api(@core_theory.Target::x86_64()),
    content=(
      #|strlen
      #|  strlen_s :: in imm64 = RDI:imm64  /*  const char* */
      #|  strlen_result :: out imm64 = RAX:imm64  /* unsigned long */
      #|malloc [malloc]
      #|  malloc_size :: in imm64 = RDI:imm64  /* unsigned long */
      #|  malloc_result :: out imm64 = RAX:imm64  /* void* */
      #|exit [noreturn]
      #|  exit_code :: in imm32 = low:32[RDI:imm64]  /* signed */
      #|printf
      #|  printf_format :: in imm64 = RDI:imm64  /*  const char restrict * */
      #|  printf_result :: out imm32 = low:32[RAX:imm64]  /* signed */
      #|memcpy
      #|  memcpy_dst :: in out imm64 = RDI:imm64  /* void restrict * */
      #|  memcpy_src :: in out imm64 = RSI:imm64  /* void restrict * */
      #|  memcpy_n :: in imm64 = RDX:imm64  /* unsigned long */
      #|  memcpy_result :: out imm64 = RAX:imm64  /* void* */
      #|no_such_function
      #|  no_such_function_result :: out imm32 = low:32[RAX:imm64]  /* signed */
    ),
  )
}

///|
test "api pass on ARM (AAPCS32)" {
  @arm_gnueabi.setup()
  inspect(
    apply_api(@core_theory.Target::arm()),
    content=(
      #|strlen
      #|  strlen_s :: in imm32 = R0:imm32  /*  const char* */
      #|  strlen_result :: out imm32 = R0:imm32  /* unsigned long */
      #|malloc [malloc]
      #|  malloc_size :: in imm32 = R0:imm32  /* unsigned long */
      #|  malloc_result :: out imm32 = R0:imm32  /* void* */
      #|exit [noreturn]
      #|  exit_code :: in imm32 = R0:imm32  /* signed */
      #|printf
      #|  printf_format :: in imm32 = R0:imm32  /*  const char restrict * */
      #|  printf_result :: out imm32 = R0:imm32  /* signed */
      #|memcpy
      #|  memcpy_dst :: in out imm32 = R0:imm32  /* void restrict * */
      #|  memcpy_src :: in out imm32 = R1:imm32  /* void restrict * */
      #|  memcpy_n :: in imm32 = R2:imm32  /* unsigned long */
      #|  memcpy_result :: out imm32 = R0:imm32  /* void* */
      #|no_such_function
      #|  no_such_function_result :: out imm32 = R0:imm32  /* signed */
    ),
  )
}

///|
test "api pass on AArch64 (AAPCS64)" {
  @arm_gnueabi.setup()
  inspect(
    apply_api(@core_theory.Target::aarch64()),
    content=(
      #|strlen
      #|  strlen_s :: in imm64 = R0:imm64  /*  const char* */
      #|  strlen_result :: out imm64 = R0:imm64  /* unsigned long */
      #|malloc [malloc]
      #|  malloc_size :: in imm64 = R0:imm64  /* unsigned long */
      #|  malloc_result :: out imm64 = R0:imm64  /* void* */
      #|exit [noreturn]
      #|  exit_code :: in imm32 = low:32[R0:imm64]  /* signed */
      #|printf
      #|  printf_format :: in imm64 = R0:imm64  /*  const char restrict * */
      #|  printf_result :: out imm32 = low:32[R0:imm64]  /* signed */
      #|memcpy
      #|  memcpy_dst :: in out imm64 = R0:imm64  /* void restrict * */
      #|  memcpy_src :: in out imm64 = R1:imm64  /* void restrict * */
      #|  memcpy_n :: in imm64 = R2:imm64  /* unsigned long */
      #|  memcpy_result :: out imm64 = R0:imm64  /* void* */
      #|no_such_function
      #|  no_such_function_result :: out imm32 = low:32[R0:imm64]  /* signed */
    ),
  )
}
