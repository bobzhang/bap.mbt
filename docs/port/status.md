# BAP MoonBit Port Status

This repository is porting `.repos/bap` from OCaml to idiomatic MoonBit.

## Implemented

- `bitvec`: fixed-width bitvectors with normalization, bit predicates, unsigned and signed shifts, modular arithmetic, unsigned division/remainder, gcd/lcm, concatenation, extraction, hexadecimal parsing/formatting, and endian byte conversion.
- `regular`: printable helpers, deterministic digest wrappers, format metadata/registry support, and a prefix trie with `find`, `remove`, and longest-prefix matching.
- `graphlib`: persistent directed graphs with node/edge operations, successor/predecessor queries, DFS edge classification, reachability, reverse postorder, and dominator-set computation.
- `types`: initial BAP-style `Word` wrapper over `bitvec`, value types, variables, and a BIL expression/statement AST with type inference for simple expression forms.

## Next Packages

- `knowledge` and `core_theory`: the semantic object model that later BAP IR packages depend on.
- Expand `types` with BIL evaluation, optimizations, IR terms, attributes, and the remaining tests translated from `.repos/bap/lib_test/bap_types`.

## Porting Defaults

- Use `Bytes`/`BytesView` for binary payloads and file-format input.
- Use checked `suberror` plus `raise` instead of OCaml exceptions and `Or_error.t`.
- Keep pure packages target-agnostic; isolate native stubs behind native-only packages.
- Prefer behavior-level compatibility over OCaml module-shape compatibility.
