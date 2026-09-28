# bobzhang/bap

A MoonBit port of [BAP](https://github.com/BinaryAnalysisPlatform/bap), the
Binary Analysis Platform. It loads executables, disassembles and lifts them to
BIL/BIR and Core Theory semantics, and runs analyses on the result, including
the Primus emulator and its Lisp runtime.

Detailed per-package status, deliberate deviations from upstream and known gaps
are tracked in [`docs/port/status.md`](docs/port/status.md). The upstream source
the port follows is expected in `.repos/bap` (not committed):

```bash
git clone --depth 1 https://github.com/binaryanalysisplatform/bap .repos/bap
```

## The `bap` command

```bash
moon build --target native --release
```

The binary is `_build/native/release/build/cmd/bap/bap.exe`. It mirrors the
upstream frontend and commands:

```bash
bap /bin/ls -dasm                         # disassemble (ELF, Mach-O incl. universal, PE/COFF)
bap /bin/ls --target=x86_64 -dbir         # pick a universal-binary slice, print BIR
bap mc --arch=aarch64 --show-bil -- "20 04 00 f1"
bap specification /bin/ls                 # the Ogre image specification
bap prog --run --run-entry-points=main --primus-print-observations=enter-sub,leave-sub
bap list plugins
```

## What is ported

| Area | Packages |
|---|---|
| Foundations | `bitvec`, `regular`, `graphlib`, `future`, `relation`, `knowledge` (KB state, fixpoint evaluator), `core_theory` (targets, sorts, `Theory.Core` algebra, manager, parser) |
| IR and BIL | `types` (BIL, BIR terms, SSA, liveness, BIL→IR lowering), `microx`, `bml` |
| Loading | `image` (Ogre-based specs), `elf`, `macho`, `coff`, `ogre`, `dwarf`, `memory` |
| Disassembly | `project` (driver, symbolizer, rooter, brancher, reconstructor, passes), `mc` (decoder and lifter registries) |
| Architectures | native LLVM-compatible decoders and lifters for x86/x86-64, ARM/Thumb, AArch64, MIPS, PowerPC, RISC-V and SystemZ (`x86`, `arm`, `thumb`, `aarch64`, `mips`, `powerpc`, `riscv`, `systemz`) |
| Primus | `primus` (frame-stack machine with fork/switch), `primus_lisp` (reader, type checker, interpreter, Lisp→BIL semantics), `taint`, `primus_track_visited`, `z3` (runtime-loaded SMT binding) |
| C | `c` (types, sizes, ABI), `c_parser` (declarations and a preprocessor subset) |
| Tooling | `bap_main` (extension/config/command framework), `frontend` + `cmd/bap`, `recipe`, `text_tags`, `demangle` (incl. a native Itanium demangler), `strings`, `byteweight`, `traces` |
| Plugins | `plugins/*`: the upstream plugins (55 registered in `bap`), e.g. print, disassemble, mc, run, api, optimization, callsites, primus schedulers/loader/limit/taint, symbolic executor, patterns, bil, cache |

Upstream relied on LLVM for instruction decoding and object loading. The port
replaces both with native MoonBit implementations, validated against LLVM 22
(`llvm-mc`, `llvm-cxxfilt`) on large corpora. Lifted semantics are checked
against the Unicorn emulator by differential test suites (`unicorn_diff`,
`x86/semantics`).

The native Itanium demangler (`demangle/itanium`) bounds its recursion so that
crafted symbol names cannot overflow the stack: names that nest deeper than
256 levels while parsing, or whose demangled form nests deeper than 96 levels,
are left mangled. This is a compatibility limit sized for the small default
stacks of the wasm-gc and js targets (libiberty's default limit is 2048 levels,
LLVM has none), so some valid but very deeply nested symbols are rejected.
The deepest of the 3,000+ llvm-cxxfilt reference symbols in the test corpus
nests 12 parser and 13 printer levels.

Not ported: bindings to external tools and native libraries (LLVM, IDA, Ghidra,
radare2, objdump), OCaml dynamic plugin loading and build tooling
(`bap_plugins`, `bap_build`, `bap_bundle`), piqi serialization, and the
`monads` library, whose functor-heavy design has no direct MoonBit equivalent.

## Development

```bash
moon check                   # type check
moon test                    # all tests (wasm-gc)
moon test --target native    # includes file-system, Z3 and CLI tests
moon info && moon fmt        # refresh interfaces and format before committing
```
