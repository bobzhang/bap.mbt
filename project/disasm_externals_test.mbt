///|
/// Disassembles and lifts `call puts; ret` at 0x5000, with a lifter making
/// the call a call of the external `puts`: the externals of the driver and
/// of the symbol table, and the subroutines of the program lifted from the
/// symbol table (with the externals `extra` added).
fn externals_test_run(
  extra : Array[String],
) -> (Int32, Array[String], String) raise {
  guard @project.register_builtin_disassembly_drivers() is Ok(_) else {
    fail("registration failed")
  }
  let code = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x5000UL,
    b"\xe8\x00\x00\x00\x00\xc3",
  )
  let project = @project.Project::empty(@core_theory.Target::x86_64())
    .with_memory(@memory.MemMap::singleton(code, "code"))
    .with_symbols([
      @image.Symbol::create(name="main", addr=0x5000UL, is_function=true),
    ])
  guard project.disassemble(driver="recursive") is Ok(project) &&
    project.disassembly_driver_state() is Some(driver) else {
    fail("disassembly failed")
  }
  let symtab = project.disassembly_symtab()
  guard symtab
    .with_externals(symtab.externals() + extra)
    .lift_ir(target=project.target(), cfg=project.disassembly_cfg())
    is Ok((program, _)) else {
    fail("lifting failed")
  }
  (
    driver.externals().length(),
    symtab.externals(),
    program
    .subs()
    .map(sub => "\{sub.sub_name()} synthetic=\{sub.is_synthetic()}")
    .join(" "),
  )
}

///|
test "the externals called by the program get synthetic subroutines" {
  let registry = @mc.Registry::global()
  registry.register(
    @mc.Provider::create(
      "externals-test",
      accepts=ctx => ctx.belongs(@core_theory.Target::x86_64()),
      lift=(_, insn) => {
        guard insn.addr == 0x5000UL else {
          raise @mc.Unsupported(opcode=insn.name, target="externals-test")
        }
        @mc.Lifted::of_bil([@types.Stmt::encode(@types.Stmt::call(), "puts")])
      },
    ),
  )
  let result = try externals_test_run([]) catch {
    err => Err(err)
  } noraise {
    result => Ok(result)
  }
  let extra = try externals_test_run(["abort"]) catch {
    err => Err(err)
  } noraise {
    result => Ok(result)
  }
  ignore(registry.unregister("externals-test"))
  guard result is Ok((count, externals, subs)) else { fail("run failed") }
  assert_eq(count, 1)
  assert_eq(externals, ["puts"])
  // the lifted program has a synthetic subroutine for the external
  // (upstream `reify_externals`)
  inspect(
    subs,
    content=(
      #|main synthetic=false puts synthetic=true
    ),
  )
  // an external of the symbol table is reified even when nothing calls it
  guard extra is Ok((_, _, subs)) else { fail("run failed") }
  assert_true(subs.contains("abort synthetic=true"))
}
