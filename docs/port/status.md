# BAP MoonBit Port Status

This repository is porting `.repos/bap` from OCaml to idiomatic MoonBit.

## Implemented

- `bitvec`: fixed-width bitvectors with normalization, bit predicates, unsigned and signed shifts, modular arithmetic, unsigned division/remainder, gcd/lcm, concatenation, extraction, hexadecimal parsing/formatting, and endian byte conversion.
- `regular`: printable helpers, deterministic digest wrappers, format metadata/registry support, and a prefix trie with `find`, `remove`, and longest-prefix matching.
- `graphlib`: persistent directed graphs with node/edge operations, successor/predecessor queries, DFS edge classification, reachability, reverse postorder, and dominator-set computation.
- `types`: BAP-style `Word` wrapper over `bitvec`, value types, variables, a BIL expression/statement AST with type inference for simple expression forms, and an initial IR term layer with tids, attributes, program/sub/block containers, defs, phis, jumps, calls, labels, and arguments.
- `knowledge`: typed names, partial orders, monotone domains, class/slot metadata, object allocation, and fact tables that merge values through domain joins.
- `core_theory`: symbolic sorts, typed values, variables, effect lattice values, labels, and target metadata with inheritance/matching helpers.
- `memory`: byte-addressed memory regions with rebasing, views/ranges, endian-aware word loads and stores, contiguous merges, hexdumps, and a basic interval `MemMap` with lookup/intersection/dominator queries.

## Next Packages

- Expand `core_theory` with the full BAP knowledge registry, target registry, role/alias origin tracking, program/unit/source/compiler slots, and architecture-specific target declarations.
- Expand `types` with BIL evaluation, optimizations, richer term traversal/mapping, free-variable analysis, substitution, and the remaining tests translated from `.repos/bap/lib_test/bap_types`.
- Build the image layer on top of `memory`: segments, symbols, section metadata, loader/backend registration, and `Image.words`/memory maps.

## Porting Defaults

- Use `Bytes`/`BytesView` for binary payloads and file-format input.
- Use checked `suberror` plus `raise` instead of OCaml exceptions and `Or_error.t`.
- Keep pure packages target-agnostic; isolate native stubs behind native-only packages.
- Prefer behavior-level compatibility over OCaml module-shape compatibility.
