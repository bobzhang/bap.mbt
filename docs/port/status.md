# BAP MoonBit Port Status

This repository is porting `.repos/bap` from OCaml to idiomatic MoonBit.

## Implemented

- `bitvec`: fixed-width bitvectors with normalization, bit predicates, unsigned and signed shifts, modular arithmetic, unsigned division/remainder, gcd/lcm, concatenation, extraction, hexadecimal parsing/formatting, and endian byte conversion.
- `regular`: printable helpers, deterministic digest wrappers, format metadata/registry support, and a prefix trie with `find`, `remove`, and longest-prefix matching.
- `graphlib`: persistent directed graphs with node/edge operations, successor/predecessor queries, DFS edge classification, reachability, reverse postorder, and dominator-set computation.
- `types`: BAP-style `Word` wrapper over `bitvec`, value types, variables, a BIL expression/statement AST with type inference, free-variable analysis, variable/expression substitution, scalar and byte-addressed memory expression evaluation, bounded statement execution over BIL state, focused BIL simplification, statement-level constant propagation, dead virtual assignment pruning, a bounded fixpoint optimization pipeline, plus an initial IR term layer with tids, attributes, program/sub/block containers, defs, phis, jumps, calls, labels, arguments, expression traversal/free-variable/substitution helpers, BAP-style block definition sequence/edit/split utilities, local subroutine CFG helpers over direct jumps, interrupts, and call returns, and a direct-call callgraph over program terms.
- `knowledge`: typed names, partial orders, monotone domains, class/slot metadata, object allocation, and fact tables that merge values through domain joins.
- `core_theory`: symbolic sorts, typed values, variables, effect lattice values, labels, target metadata with inheritance/matching helpers, common architecture target declarations, and a target registry/lookup layer.
- `memory`: byte-addressed memory regions with rebasing, views/ranges, endian-aware word loads and stores, contiguous merges, hexdumps, and a basic interval `MemMap` with lookup/intersection/dominator queries.
- `image`: image metadata over `memory`, including segments, sections, symbols, memory maps, symbol/section/segment lookup, endian-aware `Image.words` extraction, and a MoonBit backend registry that loads bytes into `(Image, warnings)`.
- `project`: project container over `core_theory`, `types`, `memory`, and `image`, with target/program/memory/image state, typed storage tags over string-backed storage, memory tagging, program mapping, library records, project input constructors/loaders, and a named dependency-aware pass registry with explicit/autorun execution.

## Next Packages

- Expand `core_theory` with the full BAP knowledge registry, richer role/alias origin tracking, program/unit/source/compiler slots, and more complete architecture-specific target metadata.
- Expand `types` with fuller BIL normalization and memory-aware optimization passes, fuller IR visitors and control-flow semantics, phi-aware data-flow helpers over the term layer, indirect call resolution hooks, and the remaining tests translated from `.repos/bap/lib_test/bap_types`.
- Expand `image` with Ogre spec parsing, file-backed loaders, backend discovery metadata, and richer symbol-to-memory handling for non-contiguous symbols.
- Expand `project` with file-backed input loaders, pass run-once/telemetry semantics, collators, analysis arguments, disassembly state, and richer non-string storage encodings.

## Porting Defaults

- Use `Bytes`/`BytesView` for binary payloads and file-format input.
- Use checked `suberror` plus `raise` instead of OCaml exceptions and `Or_error.t`.
- Keep pure packages target-agnostic; isolate native stubs behind native-only packages.
- Prefer behavior-level compatibility over OCaml module-shape compatibility.
