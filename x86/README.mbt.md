# bobzhang/bap/x86

Port of BAP's `plugins/x86` lifters:

- the legacy byte-level decoder and BIL lifter (`x86_disasm.ml`,
  `x86_lifter.ml`, `x86_utils.ml`): it decodes the raw bytes of the
  instruction itself, for 32-bit (`X86`) and 64-bit (`X8664`) modes,
  including prefixes, REX/VEX, segment overrides, `rep` loops, the x87
  control word and the SSE/AVX integer instructions upstream models;
- the per-opcode lifters over LLVM MC opcode names and operands
  (`x86_btx`, `x86_mov`, `x86_mov_offset`, `x86_cmpxchg`, `x86_cdq`,
  `x86_endbr`), which upstream prefers over the legacy lifter.

Both are exposed as `@mc` providers: `"x86"` (per-opcode, keyed by
`insn.name()`) and `"x86-legacy"` (decodes `insn.raw()`). They raise
`Unsupported` for instructions they do not model, so that other providers
(or the project's Basic lifter) are tried.

## Opting in

The project's Basic lifter stays the default for x86: `@x86` is not part of
`@project.register_builtin_lifters`. To use the ported lifters, register
them, either in the global registry used by the project, or in a registry
passed to the lifting functions:

```mbt check
///|
test "opting in" {
  let registry = @mc.Registry::new()
  @x86.register(registry~)
  // add eax, ebx
  let insn = @mc.Insn::create(
    "ADD32rr",
    [@mc.Op::reg("EAX"), @mc.Op::reg("EAX"), @mc.Op::reg("EBX")],
    addr=0x1000,
    size=2,
    raw=b"\x01\xd8",
  )
  let ctx = @mc.Context::create(@core_theory.Target::x86_64())
  let lifted = registry.lift(ctx, insn)
  inspect(lifted.bil.length(), content="9")
}
```

With `@x86.register()` (the global registry), `@project` lifting
(`ProjectDisassemblyInstruction::lift` and the block/project variants) tries
the x86 providers first and falls back to the Basic lifter for
`Unsupported` instructions.

The legacy lifter can also be used directly on bytes:

```mbt check
///|
test "legacy lifter" {
  let bil = @x86.lift_legacy(X8664, b"\x48\x89\xd8", addr=0x400000)
  inspect(bil[0].to_string(), content="RAX:imm64 := RBX:imm64")
}
```

## Deliberate deviations from upstream (fixed to follow the Intel SDM)

Found by the differential tests against the Basic lifter
(`differential_test.mbt`) and against Unicorn (`x86/semantics`), marked
`port:` in the sources:

- shifts and SHLD/SHRD mask the count to 5 bits (6 for 64-bit operands),
  so 8- and 16-bit operands shift by up to 31 (upstream masks to the
  width); the CF of SHR/SAR is the last bit shifted out (the sign for SAR
  by more than the width);
- ROL/ROR rotate by the masked count modulo the width and set CF (the bit
  rotated in) whenever the masked count is not zero, and OF from the new
  CF (upstream only assigns CF for a zero count);
- the one-operand IMUL sets CF/OF when the product is not the sign
  extension of its low half (upstream: when the high half is not zero);
  IDIV raises #DE when the quotient exceeds the signed operand range
  (upstream checks the range of the double-width type);
- BT/BTS/BTR/BTC leave ZF unchanged; the per-opcode lifters zero-extend
  32-bit register destinations in 64-bit mode and address
  `floor(offset / width)` for negative register offsets; the legacy lifter
  decodes and lifts BTS/BTR/BTC (`0f ab`, `0f b3`, `0f bb`, `0f ba /5 /6
  /7`; upstream lifts the latter as BT), takes immediate offsets modulo
  the operand size and register offsets as signed;
- CMPXCHG only writes the accumulator when the comparison fails and
  writes the destination back otherwise; CMPXCHG8B loads EDX:EAX <- m64 in
  the right order and only when the comparison fails, and CMPXCHG16B (REX.W)
  is lifted over RDX:RAX and RCX:RBX (upstream lifted it as CMPXCHG8B);
- XADD stores the sum in the r/m operand and its old value in the register
  (upstream swaps them);
- LAHF and PUSHF store the reserved flag bits (bit 1 is 1, the others are
  0) instead of unknown values;
- PAVGB/PAVGW keep the carry of the sum; the PSLL/PSRL/PSRA forms with a
  register or memory count shift every element by the low quadword of the
  source (clearing or sign-filling the elements when it exceeds their
  width); PSHUFB selects with the low 4 bits of the index; MOVQ `66 0f d6`
  zero-extends a register destination.

Other upstream issues kept as is: the explicit-length PCMPESTRx forms read
the clamped length before assigning it, the mask forms PCMPxSTRM are
ill-typed (a 128-bit mask assigned to YMM0) and raise `IllTyped`, the VEX
forms of PUNPCKx/PSHUFD write the `vvvv` register instead of the ModR/M
destination, and RCL/RCR are not lifted (the combined providers fall back
to the Basic lifter).

## Not ported

- the legacy floating-point lifter (`x86_legacy_fp_lifter.ml` and the
  `x86_legacy_bil_*` intermediate language), only enabled upstream with
  `--x86-with-legacy-floating-points`: it produces floating-point
  operations that BIL cannot represent; x87/SSE floating-point semantics
  come from the Primus Lisp intrinsics by default;
- `semantics/*.lisp` (Primus Lisp port);
- ABI, target and `X86_target` registration (`x86_main.ml`), and the LLVM
  3.4 opcode names of `x86_mov_offset.ml`.
