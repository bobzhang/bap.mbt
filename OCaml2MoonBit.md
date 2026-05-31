---
name: ocaml2moonbit-migration
description: Guide for migrating OCaml projects, libraries, modules, and test suites to idiomatic MoonBit. Use when translating OCaml code to MoonBit, planning a large OCaml-to-MoonBit port, preserving byte/string-heavy behavior, replacing OCaml variants/records/exceptions/refs/arrays, mapping OCaml APIs to MoonBit packages, or building verification and test strategy for a migration.
---

# OCaml to MoonBit Migration

Port behavior, data invariants, and public contracts first. Translate syntax only after the source semantics are classified. The most common porting bug is silently coercing OCaml `string` (a byte sequence) into MoonBit `String` (UTF-16 text); classify every field by meaning before choosing a type.

When in doubt, probe with `moon run -c '...'`. Probes in this guide were verified on `moon 0.1.20260512`-class toolchains; rerun the relevant probe if the local toolchain is newer and the behavior is load-bearing.

## Migration Workflow

1. Inventory the OCaml module boundary: public types, functions, exceptions, optional arguments, mutable state, lazy/deferred state, C/Unix/filesystem dependencies, and existing tests or golden fixtures.
2. Classify every OCaml `string` by meaning before choosing a MoonBit type. Do this field by field, even inside the same OCaml record.
3. Choose MoonBit package boundaries and imports before coding. Add imports to `moon.pkg`; MoonBit source files do not use OCaml-style `open`.
4. Port one behavioral slice at a time with tests. Prefer a thin public API skeleton, then fill parser/serializer/algorithm internals behind it.
5. Probe uncertain language or library behavior with `moon run -c` and, when needed, a small OCaml toplevel probe. Keep probes minimal.
6. Finish each slice with `moon check`, `moon test`, `moon info`, and `moon fmt`. You can add more warnings `moon check --warn-list +...` to be more strict.

## MoonBit Call-Syntax Notes

When porting OCaml records of callbacks into MoonBit structs, function fields
are not called as methods. Write `(record.field)(arg1, arg2)`, not
`record.field(arg1, arg2)`.

For labelled arguments, declarations use `name~ : T` or `name? : T`, but call
sites with explicit expressions use `name=value`. The shorthand `name~` is only
for passing an in-scope variable with the same name; `name~=expr` is invalid.

If a polymorphic function with labelled arguments needs explicit type
arguments, prefer a result type annotation to guide inference:

```moonbit
let cls : @knowledge.Class[Unit, String] =
  @knowledge.Class::create(name=class_name, sort="unit")
```

MoonBit may warn on identifiers reserved for future use, including `package`,
`declare`, `define`, `var`, `guard`, and `alias`. In ports, prefer nearby names
such as `pkg`, `create`, `find_var`, `flag`, and `alias_name` unless preserving
the OCaml name is worth the warning.

MoonBit keywords cannot be used as method names. When porting APIs such as
OCaml `Future.return`, choose a semantic replacement such as `resolved`,
`full`, or `pure` instead of trying to preserve the exact name.

Top-level mutable counters should use a `Ref`, e.g. `let counter : Ref[Int] =
Ref(0)`. Top-level `let mut` is not accepted.

## Type-Mapping Cheatsheet

| OCaml use | MoonBit default |
|---|---|
| binary payload, file contents, compressed/encrypted/checksummed data, parser input | `Bytes` or `BytesView` |
| human-readable text, diagnostics, labels that are truly Unicode | `String` |
| single byte with known 0..255 range | `Byte` |
| indexes, counts, small identifiers, deliberate signed 32-bit wrapping | `Int` |
| file offsets, serialized positions, large object numbers | `Int64` or `UInt64` |
| OCaml `array` with fixed length | `FixedArray[T]` |
| mutable growable builder | `Array[T]` |
| read-only sequence parameter | `ArrayView[T]` or `BytesView` |
| compile-time lookup table (literal or comprehension) | `ReadOnlyArray[T]` |
| keyed lookup with deterministic iteration | `Map[K, V]` |
| OCaml `Buffer.t` byte builder | `@buffer.Buffer` |
| OCaml `ref` | `Ref[T]` |
| OCaml variant | `enum`, often `priv enum` for internal states |
| OCaml record | `struct`, with `{ ..old, field: value }` for immutable update |
| OCaml exception flow | `suberror` plus checked `raise` |
| lazy/deferred state | `Lazy[T]` |
| OCaml `int32` needing wrapping | `Int` |
| OCaml `int32` needing wide arithmetic | `Int64` or `UInt64` |
| OCaml `float` | `Double` |

There is no `Int32` type in the current toolchain.

## Bytes vs String

OCaml `String.length` counts bytes; MoonBit `String::length()` counts UTF-16 code units. The same source character takes different positions in the two languages, and that difference is silent.

```sh
ocaml -noprompt -noinit <<'EOF'
let s = "𝄞";;
Printf.printf "%d\n" (String.length s);;
Printf.printf "%d\n" (Char.code s.[0]);;
EOF
# 4
# 240
```

```sh
moon run -c 'fn main { let s = "𝄞"; println(s.length()); println(s.char_length()) }'
# 2
# 1
```

`String::length()` is UTF-16 code units, `String::char_length()` is Unicode scalars, and neither is bytes. For byte-oriented formats use `Bytes`/`BytesView`. Convert between `Bytes` and `String` only through a named encoding helper (`@ascii.encode`, `@utf8.encode`, etc.) that documents the encoding assumption.

When preserving a BAP-style `of_string`/`from_string` compatibility entry point in MoonBit, make the encoding explicit in the implementation and tests. In this port, string helpers such as `Image::of_string` and `ProjectInput::from_string` encode text as UTF-8 before delegating to the byte-oriented loader. Use `of_bigstring`/`of_bytes` for binary payloads that came from OCaml `string`.

When porting BAP loader registries, keep explicit user registration strict but
make built-in registration idempotent. This lets tests and applications call
initialization more than once while still surfacing accidental duplicate custom
backend names. Built-in raw byte loaders should stay simple and predictable:
load the bytes into a single executable segment and preserve the selected
load address as image base-address metadata, then let `ProjectInput` wrap the
resulting image for higher-level orchestration. The image-level raw backend can
remain a minimal address-zero byte image, but the project-level built-in `raw`
loader should preserve BAP's default raw input behavior by selecting an
`x86-64` target when no external raw-loader configuration is present. Direct
raw project inputs should also preserve BAP-style `offset`, `length`, and
`entry-point` semantics by slicing the input bytes before creating the mapped
segment, storing the original file offset on the segment, and using the
selected entry point independently of the mapped base address. Keep
object-format parsers such as ELF in `image` backends instead of duplicating
them in `project`; project filename loading should discover them through the
same image-backend fallback path as custom image loaders. For ELF, map
`PT_LOAD` program headers to image segments, zero-fill `p_memsz > p_filesz`
ranges, keep section headers as metadata, extract defined symbols from
`SHT_SYMTAB`/`SHT_DYNSYM` through their linked string tables, and derive
target/endian/filetype from the ELF header before higher-level project code sees
the image. Treat `e_shstrndx == SHN_UNDEF` as an absent section-name string
table: skip named `Section` metadata, but still parse section headers and
symbol tables through `sh_link`. Accept `e_phnum == 0` with no program-header
entry size, and for ELF objects without `PT_LOAD`, synthesize image segments
from non-empty allocatable sections using `sh_flags`. For ELF extended table
metadata, resolve `e_shnum == 0` from section header zero `sh_size`,
`e_shstrndx == SHN_XINDEX` from `sh_link`, and `e_phnum == PN_XNUM` from
`sh_info`; apply the section-count/name-index handling in both image loading
and DWARF debug-section extraction.
For BAP trace readers, preserve the loader-assigned trace id as observable
input to reader callbacks. Keep URI-only registration as a compatibility
adapter, but expose id-aware array and stream reader registrations so callbacks
that build metadata or side tables can use the same UUID that the loaded
`Trace` will report.
When porting BAP architecture targets, keep family declarations distinct from
concrete targets even when a common target name looks like a family. For
example, BAP declares `mips-family` and `powerpc-family` separately from the
concrete `mips` and `powerpc` targets. Little-endian and 64-bit variants should
belong to the family target, not to the 32-bit big-endian concrete target; use
the family target for role dispatch and broad architecture filtering.
For disassembly-driver registries, separate orchestration from architecture
decoding: a built-in driver may materialize memory regions as blocks, but it
should not invent assembly text or lifted BIL unless a real target-specific
decoder is present. Prefer function-symbol memory blocks over whole-memory
fallbacks when image symbols are available, and use an image entry-point block
as the next fallback for stripped binaries; that preserves better roots for
later target-specific decoding without fabricating instruction semantics. When
the source is an image, these disassembly-oriented drivers should materialize
only roots in executable image segments. For non-image or symbol-replaced
projects, a project-root driver can materialize the current project rooter
against the project memory map before falling back to whole-memory blocks; keep
whole-memory fallback behavior in an explicit memory-block driver.
For BAP-style rooters, keep the rooter as a source of root addresses rather
than a decoder. `Rooter.of_image` contributes the image entry point plus image
symbol starts and carries filename/biased-address metadata; `Rooter.of_blocks`
groups serialized `(name, start, stop)` blocks by name and keeps the lowest
start address for each name. Project-derived rooters should use the project's
current symbol table, not only the retained source image, while still retaining
the image entry point when an image is present.
For BAP-style symbolizers, keep generated names (`sub_...`) as empty knowledge
and fall back to `sub_<addr>` only at `resolve` time. Image/block symbolizers
should skip ambiguous many-address-to-one-name or many-name-to-one-address
mappings instead of picking a winner, while `chain` should use the first
symbolizer that knows an address. Project-derived symbolizers should use the
project's current symbol table, not only the retained source image, so later
symbol replacement remains visible.
Treat accumulated disassembly blocks and instruction facts as set-like by
memory interval. Re-running root materialization should not append duplicate
blocks for the same `min_addr`/`max_addr`, even if the current MoonBit
representation stores them in an array for deterministic traversal. Re-running
instruction materialization for the same memory interval should replace stale
assembly/BIL text and expose address- and memory-based lookup helpers for later
drivers. Also expose a block-scoped instruction lookup that returns instruction
facts dominated by a disassembly block in address order; this preserves the
BAP `Block.insns` bridge even while instructions and blocks are stored as
separate project facts. Removal helpers should keep those facts coherent:
removing a block also removes instructions dominated by that memory interval
and CFG edges whose source or target touches the removed block, while exact
instruction and edge removal supports decoder reruns and pruning. Since branch
facts may point at interior instruction addresses, expose block-scoped edge
lookups in addition to exact source/target address lookups; reconstruction and
later analysis should consume those views when exact basic-block splitting is
not yet available. Until a real
recursive-descent CFG is available, a project
reconstructor can still preserve useful BAP structure by turning materialized
disassembly blocks into IR block terms with address attributes and subroutine
terms named through the active symbolizer. When
creating address words from `Target::unknown()`, guard its zero bit width and
fall back to a concrete address width before calling `Word::of_uint64`. Keep
image-entry semantics at the subroutine layer too: when reconstruction groups a
block that contains the image entry point, mark the resulting subroutine with
the BAP-style `entry-point` flag. Keep
brancher/CFG edge facts separate from lifted instruction semantics: store
known `(source, target?, kind)` disassembly edges explicitly, and let the
initial reconstructor emit direct IR gotos only for targets that correspond to
blocks inside the reconstructed subroutine. Unknown or cross-subroutine
destinations should remain preserved as disassembly metadata until a richer
call/branch classifier is available. The default reconstructor should seed
functions from project roots and no-incoming CFG nodes, then group blocks by
reachable edge facts. Since brancher facts are instruction-address facts, the
reconstructor should treat an edge source contained anywhere inside a
materialized disassembly block as an edge from that block, and should resolve
edge targets to containing materialized blocks when exact basic-block splitting
has not happened yet; otherwise instruction-aware branchers would produce facts
that reconstruction silently ignores. Known roots are traversal boundaries for
other starts,
matching BAP's treatment of roots as call-like destinations in the default
reconstructor; until call semantics are lifted, keep those boundary edges as
disassembly metadata instead of direct intra-subroutine gotos. Remaining
unrooted cyclic components should still be grouped by reachability, while
isolated blocks stay as separate subroutines; this gives later recursive-descent
decoding a CFG-shaped landing zone without fabricating instruction semantics.
BAP brancher destinations classify CFG edges only as jump, conditional jump,
or fallthrough; preserve calls later through lifted IR `Call` jumps rather than
adding a disassembly edge kind that BAP's brancher does not have. Model
branchers as a checked project stage
that enriches already materialized disassembly blocks with those edge facts.
Project-level callgraph helpers should delegate to the IR term callgraph while
the project is built from IR `Call` jumps. Do not infer calls from
disassembly-only branch edges; those facts are CFG hints until a target-specific
decoder/lifter classifies calls and emits proper call jumps.
BAP resolves branch destinations from each decoded instruction memory, so a
MoonBit project brancher should prefer materialized instruction memories when
they exist and only fall back to whole disassembly blocks before real
instruction facts are available. Table-backed branchers should therefore match
edge sources contained anywhere inside the memory range they are asked about,
not only at the range start. Path-scoped branchers should be a no-op when the
project filename does not match their path, mirroring BAP's unit/path
applicability check. Brancher bias is an address-domain contract, not just
metadata: un-biased branchers should be called on memory rebased by the
project/unit load bias, and their returned destinations should be translated
back into the project's image address space before storing disassembly edges;
branchers marked biased stay in the current image address space. The empty
brancher should be a no-op for existing blocks, while applying any brancher to
a project without disassembly blocks should fail explicitly. Keep brancher
registration strict for user-provided names and idempotent for the built-in
empty brancher, matching the loader/driver pattern of discoverable project
services without hiding accidental duplicate custom providers. Apply the same
pattern to reconstructors: register the built-in default
reconstructor idempotently, reject duplicate custom reconstructor names, and
offer a name-based pipeline helper only as a thin resolver over the checked
driver/brancher/reconstructor stages. Keep the top-level project orchestration
explicit: a one-shot helper may run either a named or discovered disassembly
driver, optionally apply a brancher, and then a named/default reconstructor, but it
should still surface each failing stage as a checked `Result` instead of hiding
loader/disassembly/reconstruction failures. When trying several disassembly
driver candidates, report each failed driver name and reason instead of only the
last failure; otherwise custom driver priority issues are unnecessarily opaque.
When the project package owns several global registries, expose one idempotent
`register_builtin_services` helper that delegates to the lower-level built-in
loader, brancher, disassembly-driver, reconstructor, and IR-transform pass
registrations. Keep this helper as orchestration only; individual registries
should still own duplicate checks and provider metadata.
For BAP project passes, preserve the observable lifecycle boundaries even when
MoonBit does not expose OCaml-style streams. Record registration, start,
success, failure, and finish events as ordered snapshots; emit start only after
dependencies have been resolved and the pass is actually going to run, emit
finish on both success and failure, and keep run-once skips silent. Only mark a
pass as run after a successful execution so failed passes remain retryable and
their run-count metadata does not imply success.
For dispatcher-only BAP libraries such as `bap_abi`, preserve registration
order as behavior: OCaml prepends new callbacks and then folds the stored list,
so the newest registered pass runs first. In MoonBit, keep the simple
project-to-project function registry, expose stable metadata tag names and UUIDs
where BAP does, and add a thin bridge into the project pass registry rather than
mixing the dispatcher state into the generic pass system.
When a higher-level package exposes the same loader surface as a lower-level
registry, prefer a small idempotent initializer that delegates to the owning
registry instead of duplicating loader entries. For example, `ProjectInput`
can initialize built-in raw/Ogre/ELF loading by registering `image` backends,
then continue to expose those backend names through project-level discovery.
Project containers should delegate image-owned relocation, external-reference,
and base-address metadata rather than copying it into independent project
state; this keeps loader metadata coherent with the retained source image.
Preserve BAP/Ogre `require` facts as image-owned required-library metadata.
For ELF, extract `DT_NEEDED` names from `SHT_DYNAMIC` entries through the
linked dynamic string table; keep this as dependency metadata rather than
loading or resolving the libraries in the image backend.
Preserve ELF dynamic-link metadata as image-owned loader metadata: `PT_INTERP`
is the program interpreter, `DT_SONAME` is the produced shared-object name,
and `DT_RPATH`/`DT_RUNPATH` are distinct search-path strings. Do not collapse
them into required libraries or eagerly resolve their paths; later project or
platform-specific linker orchestration can interpret those fields. Do not rely
on section headers for dynamic metadata: stripped ELF files may expose it only
through `PT_DYNAMIC`. In that path, resolve `DT_STRTAB` virtual addresses
through `PT_LOAD` program headers and bound the table with `DT_STRSZ` before
reading string offsets.
Keep BAP/Ogre `symbol-value` separate from named-symbol and symbol-chunk
metadata. A symbol's runtime address may be biased or otherwise interpreted by
the loader, while the raw value can still be useful to later disassembly roots
and symbolization passes.
Preserve loader `bias` as signed `Int64` metadata, not an address. BAP loaders
can compute a negative bias when a user-supplied base is below the file's real
base. Preserve `is-executable` as an image/file flag separately from per-segment
execute permissions; for ELF, derive it from `ET_EXEC` unless richer loader
metadata is available.
When refining targets from ELF headers, map only OSABI values that the current
MoonBit target model can represent directly, including HPUX, NetBSD, Linux,
Solaris, AIX, IRIX, FreeBSD, Tru64, Modesto, OpenBSD, and
standalone/no-system. The OSABI byte can also refine ABI metadata when it is
direct: System V maps to `SysV`, GNU/Linux to `GNU`, and ARM AEABI to `EABI`.
Leave unmodeled OSABI values as unknown rather than guessing a near match.
For Ogre image specs, keep BAP-style relocation metadata separate from memory
layout: `base-address`, `relocation`, `relative-relocation`, and
`external-reference` should be preserved as image metadata even before a
backend-specific relocation applier or symbolizer exists.
For ELF relocation sections, preserve metadata conservatively: relocations
against named undefined symbols become external references, relocations against
named defined symbols can record the symbol value as the target, and known
machine-relative relocation types can record a relative relocation. Keep that
recognition as a per-machine whitelist, not a numeric shortcut: for example
x86/x86-64 use relocation type 8, SPARC/PowerPC/PowerPC64 use type 22,
SystemZ uses type 12, ARM uses type 23, AArch64 uses type 1027, and RISC-V
uses type 3. Preserve signed `RELA` addends on the relocation metadata instead
of folding them into symbol values; this keeps `S` and `A` distinguishable for
later architecture-specific handling.
For stripped ELF files, preserve relative dynamic relocations from `PT_DYNAMIC`
when section relocation tables are absent. Resolve `DT_RELA`/`DT_REL` virtual
addresses through `PT_LOAD` headers, bound them with `DT_RELASZ`/`DT_RELSZ`,
honor entry-size tags when present, and record only known machine-relative
relocation types. Also handle PLT relocation metadata: `DT_JMPREL` points to
the PLT relocation table, `DT_PLTRELSZ` bounds it, and `DT_PLTREL` selects
whether entries are `DT_REL` or `DT_RELA` shaped. When symbol-based dynamic
relocations are present with
`DT_SYMTAB`, `DT_SYMENT`, `DT_STRTAB`, and `DT_STRSZ`, resolve the referenced
dynamic symbol by index: undefined symbols become external references, while
defined symbols may become target relocations. Preserve signed `DT_RELA`
addends for both relative and symbol-target relocations; `DT_REL` entries have
no explicit addend, so mark their relocation metadata as using a memory addend
instead of pretending the addend is zero.
For a pure MoonBit relocation application stage, keep it explicit and checked:
absolute relocation facts write `target + addend` at the fixup address, while
ELF `REL` target relocations write `target + word_at_fixup`. Relative
relocation facts require image base-address metadata and write `base + addend`
when a `RELA` addend is present. Without an explicit addend, keep the
BAP/Ogre-compatible relative fallback: read the current word at the fixup, add
the base, and write the result back using the image address width and endian.
Return a new image/project instead of mutating source segments, and fail on
missing bases or out-of-bounds stores.
Project-level image fallback can enrich successful ELF loads with optional
DWARF-derived function symbols, but unsupported or malformed DWARF should not
turn a loadable stripped binary into a project-loading failure. Treat those
derived symbols as debug metadata and de-duplicate them against image symbols by
stable identity such as `(name, address)`.
When extending DWARF function-boundary extraction for newer producer output,
keep string ownership explicit: `DW_FORM_strp` indexes `.debug_str` directly,
whereas `DW_FORM_strx*` first indexes `.debug_str_offsets` using the
compilation unit's `DW_AT_str_offsets_base`, then uses the resulting offset in
`.debug_str`. Keep `.debug_str` itself demand-driven: inline `DW_FORM_string`
names and `DW_FORM_line_strp` names must not require a string table, but
`DW_FORM_strp`/`DW_FORM_strx*` should fail clearly when they dereference a
missing one. DWARF5 unit headers are `unit_type`-dependent: full/partial
compile units have no header tail after `debug_abbrev_offset`,
skeleton/split-compile units add an 8-byte `dwo_id`, and type/split-type units
add an 8-byte `type_signature` plus a DWARF-size `type_offset`. Consume that
tail before the first DIE abbreviation code. If a DWARF5 unit type is
unsupported, skip that whole unit by its declared length and continue with
later units, but still report truncation when the declared unit end is beyond
`.debug_info`. Non-capturing DIE fields should still skip the encoded form
without forcing optional sections to exist, including zero-length
`DW_FORM_exprloc`/`DW_FORM_block*` payloads; fixed-width block lengths are
unsigned sizes, not sign-extended integers. Keep `DW_FORM_data*` and
`DW_FORM_udata` as unsigned constants for attributes such as `DW_AT_high_pc`;
only `DW_FORM_sdata` is signed, and `DW_FORM_flag` consumes a one-byte flag.
Fixed-width indexed forms such as
`DW_FORM_strx2`/`DW_FORM_addrx3` encode the index in the DIE stream using the
unit endian, unlike `DW_FORM_strx`/`DW_FORM_addrx` LEB128 indexes. Treat
`DW_AT_linkage_name` as a function-name fallback when `DW_AT_name` is absent;
if both are present, keep the source-level `DW_AT_name` as the display name.
For DWARF4-style
`DW_AT_ranges`, parse `.debug_ranges` address-pair lists and collapse
non-contiguous ranges to the covering function interval when the public MoonBit
value only has `low_pc`/`high_pc`. Track the current compilation-unit
`DW_AT_low_pc` as the default base, use that current scope base for a DIE's
own `DW_AT_ranges` even when the DIE also has `DW_AT_low_pc`, and honor
base-address selection entries inside the range list. For DWARF5-style
`.debug_rnglists`, treat
`DW_FORM_sec_offset` as an absolute list offset in the section, while
`DW_FORM_rnglistx` indexes the offset table at `DW_AT_rnglists_base`; the table
entry is relative to that same base. Support absolute `start_end`,
`start_length`, base-address, and base-relative `offset_pair` entries before
adding address-indexed range entries that require `.debug_addr`. For
`.debug_addr`, track `DW_AT_addr_base` on the current compilation unit and
resolve `DW_FORM_addrx*` values by indexing fixed-width entries from that base;
require the base explicitly instead of guessing around the section header.
Track DIE child nesting when carrying range bases: a `DW_AT_low_pc` on a
compile unit or lexical scope should seed that DIE's children, but it must not
leak into following siblings after a null child-list terminator.
For abbreviation-only values such as `DW_FORM_implicit_const`, consume the
signed LEB128 payload in the abbreviation table and do not expect bytes in the
DIE stream. Preserve `.debug_line_str` and resolve `DW_FORM_line_strp` names
from that section. Preserve `.debug_loclists` even before interpreting
location lists; producer metadata forms such as `DW_FORM_data16` and
`DW_FORM_loclistx`, plus supplementary reference forms such as
`DW_FORM_ref_sup4`/`DW_FORM_ref_sup8`, should still be skippable so FBI
extraction can keep useful function bounds. Keep `DW_FORM_ref_sig8` distinct
from ordinary `DW_FORM_ref8`: it is a type-signature reference, not a
same-compilation-unit DIE offset for resolving `DW_AT_specification` names.
For concrete function DIEs that omit a direct name, resolve
`DW_AT_specification` and `DW_AT_abstract_origin` references through the target
DIE's `DW_AT_name` or `DW_AT_linkage_name`; support same-compilation-unit
`DW_FORM_ref*` references and absolute `DW_FORM_ref_addr` references by
collecting DIE names across the parsed `.debug_info` section before finalizing
functions. `DW_FORM_ref_addr` is version-sensitive: DWARF2 encodes it at the
target address size, while DWARF3 and later encode it at the DWARF offset size.
Use the compilation-unit version when consuming either captured or skipped
`ref_addr` forms so later attributes do not become misaligned.

`text[i]` returns a `UInt16` code unit, not a `Char`. For text parsers that need character predicates or `StringBuilder::write_char`, use `text.get_char(offset)` and advance by `char.utf16_len()`. It is still fine to increment by one for syntax bytes you have already constrained to ASCII, such as `(`, `)`, `"` and `\\`, but do not mix code-unit offsets with `Char` APIs accidentally.

For textual compatibility suffixes such as BAP-style SSA variable names
(`name#index`), prefer `String::rev_split_once` over a forward split so names
that contain the separator earlier are preserved. Parse the suffix with
`@string.parse_int` and treat parse failure as "no suffix" instead of changing
the base name.

When porting BAP liveness over IR phi nodes, keep the two phi roles separate:
ordinary uses of a phi result inside its block still participate in that
block's `free_vars`, while phi operands are edge-specific uses attributed to
their predecessor block. Do not model phi lhs variables as ordinary block defs
in the liveness transfer unless the OCaml source does so for that algorithm.

When lowering SSA back to ordinary IR, do not merely remove phi nodes or strip
`#index` suffixes. A phi is an edge assignment: lower each predecessor value to
a copy on the corresponding incoming edge, split the edge with a copy block
when needed, then remove phis and strip SSA indices from the remaining
expressions. This preserves conditional and critical-edge behavior that would
be lost by inserting all copies unconditionally at the end of a predecessor
with multiple successors.

For BAP IR control-flow algorithms, keep reusable graph algorithms in
`graphlib` and expose term-layer wrappers over local block `Tid`s. Resolve an
optional entry `Tid` against the subroutine's own block list before invoking
dominance or frontier algorithms; a nonlocal entry should produce empty
wrapper results instead of silently analyzing from an external or missing node.
When porting `Graphlib.depth_first_search` tests or clients that inspect the
callback ordinals, record both wall-clock entry/leave timestamps and the
preorder/reverse-postorder ordinals. BAP's `rpost` order matches
`reverse_postorder`, so ancestors have smaller `rpost` values than their DFS
descendants.

For BAP's Trivial Condition Form pass, preserve block structure and jump term
identity while hoisting every non-`Int`/non-`Var` jump condition into a fresh
virtual boolean definition. Multiple conditional jumps in one block need
distinct variables; using the same textual name for every hoist changes later
variable-based analyses.

For monomorphic BAP word/bitvector operations, preserve width checks even when
both operands are representable in MoonBit scalar integers. Comparisons between
different bit widths should fail with an incompatible-width error instead of
implicitly widening, truncating, or comparing host integers.

For BAP relation matching, keep the callback contract aligned with the OCaml
map/set implementation. Iterate left keys in comparator order, report a
left-to-many relation as `NonInjectiveBwd`, and for many-left-to-one relations
invoke the unmatched callback once for each left edge with the same
`NonInjectiveFwd(lefts, right)` reason. Do not collapse those repeated forward
reports into one aggregate callback; BAP's `matching` folds per left key.
`bap_relation.mli` documents `mem rel x s` as membership of the pair `(x, s)`,
but the OCaml implementation checks only that `x` appears on the left and `s`
appears on the right. Preserve the documented pair-membership contract in the
MoonBit port and keep a regression for the cross-pair case.

Many BAP plugins are intentionally thin `Project.map_program` wrappers around
term transforms (SSA, SSA destruction, flatten, trivial-condition-form, stub
resolution). Port the pure `types` transform first, then expose a project-level
wrapper that delegates to it; avoid duplicating term payload rewrites in the
`project` package. When exposing built-in pass registration, make it idempotent
so tests and applications can initialize common passes more than once without
turning global registry state into a failure mode.

BAP's BIL pass registry is separate from project passes: registering a pass
with an existing name replaces the old metadata/body, while selecting passes
preserves the caller-provided transform order. The OCaml implementation exposes
hash-table enumeration order for `passes`; prefer deterministic MoonBit
enumeration instead, but document that it follows `String::compare` shortlex
ordering rather than locale/alphabetic ordering.

BAP BIL result values are a small printable wrapper around interpreter output:
word results print through the word printer, memory results print as
`<storage>`, and undefined results print as `bot`. Preserve the ID rendering as
uppercase hexadecimal with a `0x` prefix. Linear result storage keeps duplicate
saves and resolves loads to the newest matching address; sparse result storage
replaces an existing address binding.
BAP BIL contexts are persistent variable-result maps. Since the MoonBit `Var`
port already treats runtime environments by variable name, keep context lookup
and replacement name-based too, and sort `bindings()` by variable name to avoid
exposing insertion or hash-map order.

BAP's mutable vector is a capacity-backed logical sequence. Port operations
against the logical `size`, not the backing array length, so `to_array`,
mapping, folds, and search helpers never expose default-filled capacity slots.
The OCaml implementation used `unsafe_get` internally and only checked the
upper bound in `nth`; in MoonBit, guard both lower and upper bounds for `nth`
and keep aborting `get`/`set` for invalid indexes.

For `bap_int_conversions`, preserve the checked-narrowing contract: values that
do not fit the host `Int` range return `Err` instead of wrapping. MoonBit `Int`
is signed 32-bit, so `int_of_int64` accepts only `[-0x80000000, 0x7fffffff]`;
unsigned inputs accept only `0..0x7fffffff`. Delegate word conversion to the
ported `Word::to_int` so signed word literals keep BAP's signedness behavior.

For `bap_tid_graph`, build on the local subroutine CFG but add stable pseudo
start/exit nodes. First connect blocks with no incoming edge to start and blocks
with no outgoing edge to exit. Then walk blocks in source order, connecting any
component still unreachable from start and any component that still cannot
reach exit. This mirrors BAP's DFS `start_tree` repair while keeping the result
deterministic in MoonBit.

When porting BAP `Term.visitor`/`Term.mapper` users, prefer a typed sum view of
IR terms over untyped callbacks. Keep traversal order explicit and stable
(program, sub, args, block, phis, defs, jumps), and make reconstruction-aware
mappers ignore accidental class changes instead of corrupting the enclosing
tree. Parent lookup should report the nearest IR container: program for subs,
sub for args/blocks, and block for phis/defs/jumps.

When porting `map_terms`-style predicates, keep the parser/plugin layer separate
from the reusable term queries. Implement class/name/tid/attribute checks,
direct-child enumeration, free/defined variable tests, address-attribute
matching, and immediate-parent matching as typed `IrTerm`/`Term` helpers first;
a BML parser or command plugin can then compose those helpers without
re-encoding traversal semantics. BAP's `term-addr` parses user text at the
stored address width, so a string-only MoonBit attr port should preserve width
by constructing addresses with `Attr::address` when possible.
Project-level marking should stay a thin wrapper over `Project::map_program`
and `Term::map_program_terms`; unmarking string-valued MoonBit attributes is a
key deletion rather than BAP's `Dict.Value.tagname` filtering.
When porting BAP unit-valued term attributes into MoonBit's string-backed
attribute map, model them as presence flags with a stable `"true"` value and
provide named helpers for common subroutine semantics (`extern`, `leaf`,
`noreturn`, `entry-point`, etc.). Keep payload-carrying attributes such as
`filename`, `format`, and `origin` explicit instead of overloading the same
flag helper.

For BAP-style stub resolution, treat symbol names and aliases as an undirected
graph and resolve by connected components. Link stubs only when a component has
exactly one non-stub implementation; pairwise alias matching is too eager,
because another alias edge can pull a second implementation into the same
component and make the whole group ambiguous. Apply `link_only`/`no_link` style
filters to each subroutine's full name-or-alias set before building the graph.

For BAP BIL helper predicates, expression references and statement references
are close to free-variable queries, but assignment lhs variables are definitions
rather than references. `Exp.Var(x)` references `x`; `Stmt.Move(x, rhs)` does
not reference `x` unless `rhs` does. `is_assigned ~strict:true` also ignores
assignments nested under conditional control flow such as `If` and `While`.
For statement-list `substitute_var`, preserve BAP's sequence kill behavior:
after an unconditional `Move(x, rhs)`, substitute within that rhs and leave the
following statements unchanged for `x`. Conditional branch bodies apply the
same rule locally and do not kill substitution in the outer sequence.

BAP `Bil.normalize` is more than ITE splitting. Its first pass hoists
expressions with load/store effects from duplication-sensitive positions:
`Load` memory/address operands, `Store` address/value operands, `Let` values,
and ITE conditions. It then hoists `If` and `While` conditions that contain
ITEs or non-variable load memories into fresh virtual definitions; for loops,
append the same condition update to the loop body so the guard is refreshed
each iteration. Its later store-hoisting pass finds `Load(mem=store_chain, ...)`
shapes in move and jump expressions, recovers the base memory variable from the
store chain, inserts `mem := store_chain`, and substitutes the original load to
read from `Var(mem)`. Keep store hoisting after recursive statement
normalization so hoisted stores are visible as standalone statements and
repeated hoisting can drain nested store-chain loads.

BAP BIL constant propagation is continuation-sensitive. For a statically
known `If`, propagate inside both arms, but only carry the selected arm's facts
past the branch when the unselected arm may not continue. If both arms can fall
through, join the two output contexts even when the condition simplified to a
constant. For a `While`, remove variables defined in the body before
propagating the guard/body, and for a folded false guard keep pre-loop facts
only when the propagated body cannot fall through; otherwise join pre-loop
facts with body facts.

BAP BIL `Extract` and `Concat` are expression nodes, not just `Word` helpers.
When adding them to a MoonBit AST, update every expression traversal together:
type inference, effect/coeffect analysis, free variables, substitution,
evaluation, simplification, normalization, constant propagation, SSA renaming,
and IR flattening. Otherwise the port will either fail exhaustiveness checks or
silently lose behavior in passes that use wildcard/default expression cases.
Do not make `Extract`'s type rule stricter than BAP's source: BAP allows
`hi >= lo` even when `hi` is above the operand width, because lifters use
extract for widening. Runtime extraction should zero-fill unsigned words and
sign-fill words that have been explicitly marked signed.

BAP BIL `Cast` is not a generic `ValueType` resize. It carries a cast kind plus
a target bit width: `UNSIGNED`/`SIGNED` are pad/sign-extension forms that may
widen or narrow, while `HIGH`/`LOW` keep high or low bits and type-check only
when the source width is at least the target width. Preserve the BAP pretty
names (`pad`, `extend`, `high`, `low`) and update simplification rules for
nested casts, constants, and `HIGH` over `Extract`.

For BAP `Trie.normalize`, preserve the pipeline order: apply substitutions in
the given order, prune unreferenced virtual definitions, normalize negative
constants, simplify BIL, then normalize values for the trie key. That final
pass canonicalizes variables by textual name and replaces every integer literal
with `Unknown("<pruned>", Imm(bitwidth))`. In MoonBit, structural `Var`
equality makes a per-normalization name cache sufficient for this key
normalization; there is no need to model the OCaml table's object identity.

BAP `Word.t` carries a signedness flag in addition to the payload bits and
width. Keep the raw bitvector package sign-agnostic, but preserve this flag in
the BAP-facing word wrapper for parsing, predicates, and printing. Arithmetic
and bitwise operations in the OCaml shim repack an unsigned result, while
`Word.signed`/`Word.unsigned`, `is_negative`, and full literal formatting
observe the flag. BAP full word formatting uses uppercase hexadecimal with an
automatic base prefix: values `0..9` print as `7:4u`, larger magnitudes print
as `0x2A:8u`, and signed negative values print their two's-complement
magnitude with an `s` suffix, e.g. `-1:3s`.

```sh
moon run -c 'fn main { let raw : Array[Byte] = [65, 0, 255]; let b = Bytes::from_array(raw); println(b.length()); println(b[2].to_int()) }'
# 3
# 255
```

```sh
moon run -c 'fn main { let source : Array[Byte] = [1, 2]; let bytes = Bytes::from_array(source); source[0] = 9; println(bytes[0].to_int()); println(source[0].to_int()) }'
# 1
# 9
```

`Bytes::from_array` produces an immutable owned `Bytes`. Mutating the source array afterwards does not affect the frozen value. Port OCaml `Bytes` mutators either as `BytesView -> Bytes` transforms, or keep state in `Array[Byte]`/`FixedArray[Byte]` until the final freeze.

```sh
moon run -c 'fn main { let empty = Bytes::new(0); let zeros = Bytes::new(2); println(empty.length()); println(zeros.length()); println(zeros[0].to_int()) }'
# 0
# 2
# 0
```

`Bytes::new(length)` always zero-fills and requires an explicit length. Use it where OCaml `Bytes.empty` or `Bytes.make len '\000'` would have appeared.

`Bytes::copy` is deprecated because `Bytes` is immutable. When a port must materialize a fresh physical copy (e.g. to preserve an OCaml promise that no buffer is shared), use `Bytes::makei(len, i => src[i])`.

```sh
moon run -c $'let cached_filter = b"/Filter"\nfn main { let b = b"PDF"; println(b.length()); println(b[0].to_int()); println(cached_filter.length()); println(cached_filter[0].to_int()) }'
# 3
# 80
# 7
# 47
```

`b"..."` is a compile-time byte-string literal of type `Bytes`. Use it for ASCII format syntax (`b"/Filter"`, `b"PDF"`, etc.) — no `@ascii` import, no runtime call, no type annotation needed at top level. Reserve `@ascii.encode(text)` for `String → Bytes` conversion when the source is a dynamic `String`. Do not build binary file formats by `String` concatenation.

```sh
moon run -c $'fn main { let buf = @buffer.new(); buf.write_bytes(b"PDF"); buf.write_byte(10); let bytes = buf.contents(); println(bytes.length()); println(bytes[0].to_int()); println(bytes[3].to_int()) }'
# 4
# 80
# 10
```

The canonical MoonBit byte-builder is `@buffer.Buffer` (from `moonbitlang/core/buffer`). Construct with `@buffer.new()` (optionally `size_hint=N`), append static ASCII via `buf.write_bytes(b"...")`, single bytes via `buf.write_byte(n)`, dynamic text via `buf.write_bytes(@ascii.encode(text))`, binary payloads via `buf.write_bytes(view)`, then freeze with `buf.contents()`. Reserve `Array[Byte]` plus `Bytes::from_array` for cases that need random-access mutation of in-flight bytes; `Buffer` is the OCaml `Buffer.t` analogue.

OCaml libraries that derive `sexp_of_t` or bin-prot serializers for `Bytes.t`
still need byte-specific MoonBit codecs. Do not round-trip arbitrary bytes
through `String`. In this port, `regular` exposes explicit byte-safe hex/text
and length-prefixed binary helpers for the BAP bytes round-trip tests; callers
use those helpers at serialization boundaries and keep ordinary byte payloads as
`Bytes`/`BytesView`.

```sh
moon run -c 'fn main { let s = "/UniJIS-UCS2-H"; println(s.has_prefix("/Uni")); println(s.contains("-UCS2-")); println(s.has_suffix("-H")); println(s[1:]); println(s[1:].to_owned()) }'
# true
# true
# true
# UniJIS-UCS2-H
# UniJIS-UCS2-H
```

`String::has_prefix`, `has_suffix`, and `contains` cover predicate work. Slice with `s[start:end]` — like `BytesView`, this returns a borrowed `StringView`, cheap and good for inspection/pattern matching. When the callee needs an owned `String` (e.g. for storage or a `String` parameter), use `s[start:end].to_owned()`. Offsets are UTF-16 code-unit offsets, not bytes; use these only for ASCII-validated tokens or genuinely textual parsing.

## Bytes Views

```sh
moon run -c 'fn has_ab(view : BytesView) -> Bool { match view { [65, 66, ..] => true; _ => false } }
fn main { let bytes : Bytes = [65, 66, 67]; let view = bytes[:2]; println(view.length()); println(view[0].to_int()); println(has_ab(bytes[:])); println(has_ab(view)) }'
# 2
# 65
# true
# true
```

`BytesView` is the byte-sequence counterpart to `ArrayView`. Views are cheap slices, expose read-only byte operations, and support pattern matching with rest patterns. Prefer `BytesView` for read-only byte APIs; call `.to_owned()` only at explicit ownership boundaries. `BytesView::to_owned()` returns the original bytes for a whole view but allocates and copies for a partial slice.

`Bytes` is assignable to a `BytesView` parameter, so a single API can accept owned or borrowed input. A returned `BytesView` keeps its backing `Bytes` alive across function boundaries — useful for exposing decode/decrypt results without forcing a copy.

The reverse direction is **not** automatic: a `BytesView` does not type-check where owned `Bytes` is required, including in native extern declarations. Treat that as the ownership boundary and call `.to_owned()` deliberately. Equality works when the view is the left operand; if `Bytes` is on the left, slice it (`bytes[:]`) before comparing.

```sh
moon run -c 'fn main { let data : Bytes = [60, 65, 62, 0, 12, 60, 66, 62]; println(data.length()); println(data[3].to_int()); println(data[4].to_int()); let view = data[5:]; match view { [60, 66, 62] => println("match"); _ => println("miss") } }'
# 8
# 0
# 12
# match
```

NUL (`0`) and form-feed (`12`) are ordinary bytes in `Bytes`/`BytesView`. Port OCaml byte predicates literally; do not narrow a format whitespace predicate to a string-oriented space/tab check.

## Integers

```sh
moon run -c 'fn main { let (b, u, u16, i64, u64) : (Byte, UInt, UInt16, Int64, UInt64) = (255, 7, 65535, 42, 42); println(b.to_int()); println(u.to_string()); println(u16.to_int()); println(i64.to_string()); println(u64.to_string()) }'
# 255
# 7
# 65535
# 42
# 42
```

Scalar types: `Byte`, `Int16`, `UInt16`, `Int`, `UInt`, `Int64`, `UInt64`, `Float`, `Double`. There is **no** `Int32`; use `Int` for deliberate signed 32-bit wrapping, or `Int64`/`UInt64` when an OCaml `int32` value must be represented without truncation. When calling a method on an integer literal, parenthesize: `(65).to_byte()`, not `65.to_byte()` — `65.` parses as the start of a float.

```sh
moon run -c 'fn main { let max = 2147483647; println(max + 1); println(1 << 31); println(0xF0 & 0x0F); println(0x80 >> 7); println(0xAA ^ 0xFF) }'
# -2147483648
# -2147483648
# 0
# 1
# 85
```

`Int` arithmetic wraps modulo 2^32 with signed interpretation. Symbolic operators map directly from OCaml: `&` (land), `|` (lor), `^` (lxor), `<<` (lsl), `>>` (right shift, arithmetic for signed).

```sh
moon run -c 'fn main { println((-8) >> 1); println(1 << 32); println(1 >> 32); let logical = ((-8).reinterpret_as_uint() >> 1).reinterpret_as_int(); println(logical) }'
# -4
# 1
# 1
# 2147483644
```

`Int` right shift is arithmetic, and shift counts are **masked to 5 bits**, so `1 << 32 == 1`. For OCaml `Int32.shift_right_logical`, reinterpret signed→unsigned, shift, reinterpret back. Numeric conversion (`.to_uint()`) is **not** the same as bit reinterpretation (`.reinterpret_as_uint()`). When a BAP source module normalizes shift operands modulo address width, make that modulo step explicit even if the backend shift operator would mask the count.

```sh
moon run -c $'fn main { try @string.parse_int("2147483648") catch { _ => println(true) } noraise { _ => println(false) }; let mut value = 0; for digit in [50,49,52,55,52,56,51,54,52,56] { value = value * 10 + digit - 48 }; println(value); let mut wide = 0L; for digit in [50,49,52,55,52,56,51,54,52,56] { wide = wide * 10L + (digit - 48).to_int64() }; println(wide.to_string()) }'
# true
# -2147483648
# 2147483648
```

`@string.parse_int` rejects out-of-range decimals, but handwritten digit accumulation in `Int` silently wraps. Accumulate offsets, lengths, object numbers, or serialized counters in `Int64`/`UInt64`; bounds-check before narrowing to `Int`. 

```sh
moon run -c 'fn main { println(0x8EA2A1A1 < 0); println(0x8EA2A1A1); println(0x7FFFFFFF < 0x8EA2A1A1); println((-1) % 256) }'
# true
# -1901944415
# false
# -1
```

`Int` literals above `0x7FFFFFFF` are negative. A table sorted by unsigned byte order is **not** sorted for signed `Int` comparison — compare through `UInt` (`reinterpret_as_uint`) or store as `Int64`/`UInt64`. `%` preserves the sign of the left operand; normalize `(a - b) mod 256` style expressions into `0..255` before converting to `Byte`. For byte-codec arithmetic that multiplies by large radices, promote `Byte` to `UInt64`; `UInt64::to_int()` truncates to signed 32 bits for large values.

```sh
moon run -c 'fn rotr64(value : UInt64, bits : Int) -> UInt64 { (value >> bits) | (value << (64 - bits)) }
fn main { let value : UInt64 = 0x0123456789abcdef; let full : UInt64 = UInt64::lnot(0); println(rotr64(value, 8).to_string()); println((full + (1 : UInt64)).to_string()); println(((0x80 : UInt64) >> 7).to_string()) }'
# 17222085231038278605
# 0
# 1
```

`UInt64` arithmetic wraps modulo 2^64. Unsigned right shifts are logical. `Int64`/`UInt64` shift counts are masked to 6 bits in the current toolchain, so address-style shift operands should be normalized modulo 64 before shifting to preserve the source contract visibly. Provide explicit `UInt64` context (`x : UInt64`) when the literal exceeds signed `Int` range.

```sh
moon run -c 'fn main { println(Int::lnot(0)); println((0x0F).lnot()); println((!true).to_string()) }'
# -1
# -16
# false
```

Bitwise complement: `Int::lnot(value)` or `value.lnot()`. Boolean negation: `!expr`. Do not port OCaml `not x` literally.

## Floats

```sh
ocaml -noprompt -noinit <<'EOF'
print_endline (string_of_float 2.);;
print_endline (string_of_float infinity);;
EOF
# 2.
# inf
moon run -c 'fn main raise { println((2.0).to_string()); println((1.0 / 0.0).to_string()); let tiny : Double = @string.from_str("1e-10"); println(tiny.to_string()) }'
# 2
# Infinity
# 1e-10
```

`Double::to_string()` is **not** a drop-in for OCaml `string_of_float` or `Printf "%.12g"`. Whole floats render as `2` (not `2.`); infinities render as `Infinity`/`-Infinity` (not `inf`/`-inf`); small values use scientific notation. When a digest, file format, or snapshot depends on the exact spelling, port the OCaml formatter as an explicit boundary function. Overflow produces `Infinity`; division by infinity produces `0`. Cover those edges with a probe when porting defensive `float` branches.

```sh
moon run -c 'fn main { println(@math.pow(0.5, 2.0)); println((4.0).sqrt()); println((-3.0).abs()); println((5.5).mod(2.0)) }'
# 0.25
# 2
# 3
# 1.5
```

There is no `**` operator — use `@math.pow(base, exponent)`. Common helpers are `Double` methods: `value.sqrt()`, `value.abs()`, `value.mod(other)`. Free functions live in `@math`: `sin`, `cos`, `atan2`, `ln`, `log10`, `floor`, `ceil`, `round`, `trunc`, `exp`. Note `@math.sqrt`/`@math.abs` are **not** valid — those are method-only. Probe with `moon ide doc @math` before assuming a path.

## Data Structures

Map OCaml variants to MoonBit `enum`. Derive `Debug`, `Eq` for types that will be inspected in tests.

```sh
moon run -c 'enum E { A(Int) } derive(Debug)
fn E::value(self : E) -> Int { match self { A(n) => n } }
fn main { let value = A(7); println(value.value()) }'
# 7
```

```sh
moon run -c 'enum E { A(Int); B(Int) } derive(Debug)
fn main { let xs : Array[E] = [E::A(1), E::B(2)]; println(xs.length()) }'
# 2
```

When code crosses package boundaries or builds heterogeneous-looking enum arrays, prefer explicit `Type::Constructor` forms or a concrete element-type annotation. This keeps `moon check --warn-list +73` useful — strip annotations only when the compiler reports them as truly unnecessary.

```sh
moon run -c 'priv enum Section { NoneSection; ActiveSection }
fn choose(flag : Bool) -> Section { if flag { ActiveSection } else { NoneSection } }
fn main { match choose(true) { ActiveSection => println("active"); NoneSection => println("none") } }'
# active
```

```sh
moon run -c 'priv struct S { value : Int }
fn make() -> S { { value: 1 } }
fn main { let s = make(); println(s.value) }'
# 1
```

Use `priv enum`/`priv struct` for internal helpers that should not appear in the package interface. Avoid deriving traits on private helpers unless a debug path actually uses the implementation.

```sh
moon run -c 'struct S { a : Int; b : Int? } derive(Debug, Eq)
fn main { let s = { a: 1, b: None }; let t = { ..s, b: Some(2) }; match t.b { Some(value) => println(value); None => println(0) } }'
# 2
```

Record update is `{ ..old, field: value }`, the direct replacement for OCaml `{ old with field = value }`.

```sh
moon run -c 'struct S { values : Int } derive(Debug)
fn make(values : Int) -> S? { Some({ values, }) }
fn main { println(make(7).unwrap().values) }'
# 7
```

For single-field struct literals using field shorthand inside another expression, write a trailing comma (`{ values, }`) to silence the ambiguous-block warning.

When an OCaml function returns a broad variant and later code relies on an informal invariant, introduce a narrow private MoonBit enum for the post-checked state. This makes impossible fallback branches explicit at the type boundary rather than carrying broad `Object`-like values through the rest of the port.

## Lookup Tables

```sh
moon run -c 'fn range_lookup(ranges : ArrayView[(Int, Int, Int)], key : Int) -> Int? { for range in ranges { if key >= range.0 && key <= range.1 { return Some(range.2 + key - range.0) } }; None }
fn main { let ranges = [(0x21, 0x23, 100), (0x30, 0x30, 200)]; println(range_lookup(ranges, 0x22).unwrap()); println(range_lookup(ranges, 0x24) is None) }'
# 101
# true
```

For large OCaml mapping tables, prefer compact `ArrayView`-accepted range tables (`(first, last, base)` plus small exception/sequence tables) over mechanically expanding every entry. Generated MoonBit sources stay smaller and native-target validation runs faster, with the same deterministic lookup behavior.

```sh
moon run -c $'let table : ReadOnlyArray[Int?] = [for i in 0..<8 => if i == 5 { Some(10) } else { None }]\nfn lookup(i : Int) -> Int? { if i >= 0 && i < table.length() { table[i] } else { None } }\nfn main { println(lookup(5).unwrap()); println(lookup(0) == None); println(lookup(99) == None); println(table.length()) }'
# 10
# true
# true
# 8
```

For dense lookup domains, define a private top-level `let table : ReadOnlyArray[T?] = [...]`. `ReadOnlyArray[T]` is the read-only counterpart of `Array[T]`; an array literal coerces directly, and **list comprehensions can initialize `ReadOnlyArray[T]` or an owned `Array[T]` depending on the expected type** — so `[for i in 0..<N => entry(i)]` is the idiomatic way to populate a compile-time table without `makei` ceremony. Keep the bounds check at the lookup boundary.

## Target Metadata

When porting BAP target declarations, preserve canonical hardware registers and model ABI spellings as aliases with explicit provenance. If the OCaml side names user-facing registers in lowercase (`sp`, `a0`) but the MoonBit target table stores conventional uppercase variables (`SP`, `A0`), make lookup case-insensitive at the target boundary and keep `AliasOrigin` entries pointing to the numbered source register (`SP -> X2`, `A0 -> X10`). Build dense alias-origin tables with list comprehensions so the alias index stays visibly aligned with the canonical register number. Port role metadata beyond argument/result registers too: BAP target declarations use roles such as integer, floating, vector, link, stack pointer, constant/zero, thread, caller-saved, callee-saved, and reserved to drive later calling-convention and de-aliasing passes.

## Mutation, Refs, Arrays

```sh
moon run -c $'fn first_sorted(xs : ArrayView[Int]) -> Int { let ys = xs.to_owned(); ys.sort(); ys[0] }\nfn main { let r : Ref[Int] = Ref::{ val: 0 }; r.val += 1; println(r.val); let fixed : FixedArray[Int] = [3, 1, 2]; let grow = [4, 2, 3]; println(first_sorted(fixed)); println(first_sorted(grow)); println(fixed[0]); println(grow[0]) }'
# 1
# 1
# 2
# 3
# 4
```

`Ref[T]` for primitive mutability; `mut` fields inside structs for larger state. `Array` is a growable mutable vector; `FixedArray` matches OCaml `array` more directly. `ArrayView[T]` is the read-only sequence parameter type — callers can pass `Array`, `FixedArray`, or another view without copying. `.to_owned()` materializes a mutable `Array` at explicit ownership boundaries (e.g. before `sort()`/`sort_by()`); avoid it in hot paths. Represent lazy/deferred states as explicit `enum` variants instead of nested mutable containers.

```sh
moon run -c 'fn main { let xs = [(2, "b"), (1, "a")]; xs.sort_by(fn(a, b) { a.0.compare(b.0) }); println(xs[0].0); let ys = [1, 2, 3]; let zs = ys.rev(); println(zs[0]); println(ys[0]) }'
# 1
# 3
# 1
```

`Array::sort_by` sorts in place with an `Int`-returning comparator. `Array::rev()` returns a reversed **copy** and leaves the original unchanged — useful when porting OCaml list-building code that conses in reverse and conditionally applies `List.rev`.

`Array::search_by(predicate)` returns the matching index (`Int?`), not the
matched element. When porting OCaml `List.find_opt`/`Array.find_opt`, map the
index back to the array element at the use site:

```moonbit
match symbols.search_by(symbol => symbol.name() == "main") {
  Some(index) => symbols[index]
  None => fail("expected symbol")
}
```

```sh
moon run -c $'fn main { let m : Map[Int, String] = Map([]); m[3] = "three"; m[1] = "one"; m[2] = "two"; for k, v in m { println("\\{k}=\\{v}") } }'
# 3=three
# 1=one
# 2=two
```

For keyed lookup, prefer the built-in `Map[K, V]` — it is a **linked hashmap that preserves insertion order**, so iteration is deterministic and matches the order keys were written. Construct with `Map([])` (or `Map([], capacity=N)`); `Map::new()` is deprecated. Reach for `@hashmap.HashMap[K, V]` (from `moonbitlang/core/hashmap`) only when insertion order is irrelevant and you want a marginally cheaper structure. Use ordered arrays of pairs only when you need duplicate keys or sequence-style processing.

For OCaml `Set` ports that only need membership and equality, use the built-in `Set[T]` with `Set([])` or `Set([], capacity=N)` for incremental construction; `Set::new()` is deprecated. Use `Set::from_array(view)` when a whole input sequence should become one group, and list comprehension plus `Set::from_array([element])` when porting discrete partition-style initializers.

## Errors

OCaml exceptions (`Not_found`, `End_of_file`, `Invalid_argument`, domain errors) should not be copied as unchecked control flow.

```sh
moon run -c $'suberror E\nfn make(flag : Bool) -> ((Int) -> Int?) raise E { if flag { raise E } else { fn(x) { Some(x) } } }\nfn main raise { println(make(false)(3).unwrap()) }'
# 3
```

```sh
moon run -c $'fn parse(s : String) -> Int raise { @string.parse_int(s) }\nfn helper() -> Int raise { parse("7") }\ntest "raising test body can propagate" { let value = parse("7"); @test.assert_eq(value, 7) }\nfn main raise { println(helper().to_string()) }'
# 7
```

Define a project-level `suberror` once the first fallible functions are ported. Fallible functions declare `raise ProjectError` or plain `raise`. **`main` itself can be declared `fn main raise { ... }`**, which is the cleanest way to write probes and small entry points that call fallible APIs — no `try!` boilerplate. Inside a raising function, raising test helper, or `test` body, do not add explicit `try!` around every fallible call; checked errors propagate from those contexts automatically. Test helpers that can call `fail` must declare `raise`, even when only called from `test` blocks.

When a raising function returns another function, parenthesize the function type before `raise`: `-> ((A) -> B) raise E`, **not** `-> (A) -> B raise E` (the latter binds `raise` to the returned function type).

```sh
moon run -c $'fn may_fail(flag : Bool) -> Unit raise { if flag { fail("boom") } }\nfn main { try may_fail(true) catch { _ => println(true) } noraise { _ => println(false) } }'
# true
```

```sh
moon run -c $'fn parse(s : String) -> Int raise { @string.parse_int(s) }\nfn main {\n  try parse("7") catch {\n    _ => println(0)\n  } noraise {\n    value => println(value)\n  }\n}'
# 7
```

`try expr catch { ... } noraise { value => ... }` is the OCaml `try ... with ...` analogue with explicit success and error branches. When only propagating an error, call the fallible function directly from a `raise` context.

To catch one constructor and propagate the rest while keeping the project error type, use `expr catch { SpecificError => fallback; error => raise error }`. `catch` arms are checked for exhaustiveness; do not omit the final propagating arm. When porting OCaml exception tests, use a wildcard `catch` arm for "this should raise"; match a specific variant only when that variant is itself the contract under test.

Do not convert checked errors into generic success/failure values for control flow. Prefer `try f() catch { ... } noraise { ... }` when both branches matter, or a plain call from a `raise` context when the error should propagate.

## Functions and Callbacks

```sh
moon run -c 'fn helper(x : Int) -> Int { x + 1 }
fn main { println(helper(1)) }'
# 2
```

Top-level helper functions (anything other than `main`) need explicit return-type annotations. This applies to `moon run -c` probes too.

```sh
moon run -c 'fn[A, B, C] apply_pair(f : (A, B) -> C, a : A, b : B) -> (C, A) { (f(a, b), a) }
fn main { let result = apply_pair(fn(x, y) { x + y }, 2, 3); println(result.0); println(result.1) }'
# 5
# 2
```

Polymorphic functions write type parameters **before** the name: `fn[A, B, C] name(...)`. The older `fn name[A, B, C](...)` spelling is deprecated.

```sh
moon run -c $'struct Box[T] { value : T }\nfn Box::payload(self : Box[Int]) -> Int { self.value }\nfn Box::payload(self : Box[String]) -> String { self.value }\nfn main { println(Box::{ value: 1 }.payload()) }'
# Error: The method payload for type Box has been defined ...
```

Methods are keyed by the generic receiver type name, not by each instantiated
receiver type. Do not port OCaml functor/module-specialized helpers as several
same-named `Type::method` declarations over `Term[Def]`, `Term[Phi]`, etc. Use
one truly generic method when the implementation is uniform, or give the
specialized methods distinct names such as `map_def_exp` and `map_phi_exp`.

```sh
moon run -c 'fn apply_twice(f : (Int) -> Int, value : Int) -> Int { f(f(value)) }
fn main { println(apply_twice(fn(x) { x + 1 }, 40)) }'
# 42
```

Callback parameters use function types like `(Int) -> Int`; callback literals are `fn(x) { ... }`. Capturing mutable `Ref` state in a closure is a direct port of OCaml closures over refs.

```sh
moon run -c 'fn apply(f : (Int) -> Int raise, x : Int) -> Int raise { f(x) }
fn main raise { println(apply(fn(x) raise { if x == 0 { fail("zero") }; x + 1 }, 1)) }'
# 2
```

Raising callbacks must include `raise` in the parameter type and in the literal: `(Int) -> Int raise` and `fn(x) raise { ... }`. Inferred raising effects on `fn` literals are deprecated. For a narrower project error type, annotate: `fn(x) raise ProjectError { ... }`.

```sh
moon run -c $'fn apply(f : (Int) -> Int raise Error) -> Int raise Error { f(1) }\nfn main { try apply(fn(x) raise Error { if x > 0 { fail("x") } else { x } }) catch { _ => println(true) } noraise { _ => println(false) } }'
# true
```

Raising and non-raising callback types are **not** interchangeable. A raising closure cannot satisfy a non-raising slot, and vice versa. When porting OCaml callbacks whose implementation may later touch fallible APIs (filesystem, async, random), declare `raise` in the type from the start; do not hide failure inside the callback.

## Labelled and Default Arguments

```sh
moon run -c $'fn greet(name? : String = "pdf") -> String { name }\nfn main { println(greet()); println(greet(name="moon")) }'
# pdf
# moon
```

Defaults attach to **labelled** parameters: `name? : T = default`. Call sites pass `name=value`. Do not place a default on an unlabelled positional parameter.

```sh
moon run -c 'fn inner(flag? : Bool = false) -> Bool { flag }
fn outer(flag? : Bool = false) -> Bool { inner(flag~) }
fn main { println(outer()); println(outer(flag=true)) }'
# false
# true
```

`label~` forwards the current value of a same-named labelled argument through wrapper layers — the MoonBit counterpart to preserving OCaml optional-argument semantics across helpers.

```sh
moon run -c 'fn takes_view(xs : ArrayView[Int]) -> Int { xs.length() }
fn sample(xs? : ArrayView[Int] = []) -> Int { takes_view(xs) }
fn main { println(sample()); println(sample(xs=[1, 2, 3])) }'
# 0
# 3
```

Optional view parameters can default to `[]`. Optional-only arguments must be passed by label (`sample(xs=[1, 2, 3])`, not `sample([1, 2, 3])`).

```sh
moon run -c 'fn f(a : Int, flag? : Bool = true, xs? : ArrayView[Int] = []) -> Int { if flag { a + xs.length() } else { a - xs.length() } }
fn main { println(f(3, xs=[1, 2], flag=false)); println(f(3, flag=true)); println(f(3)) }'
# 1
# 3
# 3
```

After required positional arguments, multiple optionals can be supplied by label in any order.

Default values can call local functions, useful for structured-record or array defaults.

For an OCaml parameter that is genuinely "absent vs explicitly None vs explicitly Some(x)" — three distinct states — an `Option`-typed labelled argument (`x? : T? = None`) is acceptable, and `label~` forwarding still works through it. But this is rare. The common case is just `x? : T = default_value`; do not reach for `Option`-typed labels when a plain typed default would express the same thing.

## Pattern Matching

```sh
moon run -c 'enum E { A(Int); B }
fn f(e : E) -> Int { match e { A(n) if n > 0 => n; _ => 0 } }
fn main { println(f(A(3))); println(f(A(-1))); println(f(B)) }'
# 3
# 0
# 0
```

Pattern guards belong on the same arm: `Pattern if condition => ...`. Do not split the `if` onto its own line.

Match arms run **top to bottom**. Put specific tuple or variant cases before broad wildcard or guarded catch-all arms — a guarded broad arm can make a later specific case behaviorally dead, and the compiler does not always catch that.

```sh
moon run -c 'fn main { let xs = [1, 2, 3]; match xs { [_, .. rest] => { let owned = [ for x in rest => x ]; println(rest.length()); println(owned.length()); println(owned[0]) }; _ => () } }'
# 2
# 2
# 2
```

Array rest patterns (`.. rest`) bind read-only views. If an enum payload or API needs an owned `Array[T]`, copy with a comprehension: `[ for x in rest => x ]`.

## Loops and Comprehensions

```sh
moon run -c 'fn main { let fixed : FixedArray[Int] = [1, 2, 3]; let doubled = [ for x in fixed => x * 2 ]; println(doubled.length()); println(doubled[2]) }'
# 3
# 6
```

```sh
moon run -c 'fn main { let pairs = [(1, 2), (3, 4)]; let firsts = [ for pair in pairs => pair.0 ]; println(firsts[0]); println(firsts[1]) }'
# 1
# 3
```

Comprehension syntax: `[ for x in xs => expr ]`. Use a simple identifier as the binder and destructure tuples or access fields inside the body. Prefer a comprehension over a manual `let out = []` plus `push` loop when porting pure OCaml `List.map`/`Array.map`-style transformations.

```sh
moon run -c $'fn parse(s : String) -> Int raise { @string.parse_int(s) }\nfn main { let _ = [ for s in ["1"] => parse(s) ]; println("done") }'
# Error: calling function with error is not allowed inside list comprehension.
```

Comprehension bodies **cannot** call error-raising functions. Port OCaml `List.map`/`Array.map` with raising mappers as an explicit loop in a raising function: push each result into an output array and let the error propagate.

```sh
moon run -c 'fn main { let m : Map[Int, Int] = Map([]); m[1] = 10; m[2] = 20; let mut total = 0; for key in m.keys() { total += key }; println(total) }'
# 3
```

`for x in xs` iterates any iterable, not just arrays/views. `Map`, `@hashmap.HashMap`, ranges, and views all support it directly. Do not convert iterables to `Array` just to loop; reserve `.to_array()`/`.to_owned()` for cases that need an owned snapshot, sorting, indexing, or mutation.

```sh
moon run -c 'fn first_positive(xs : Array[Int]) -> Int? { let mut i = 0; while i < xs.length() { if xs[i] > 0 { break Some(xs[i]) }; i += 1 } nobreak { None } }
fn main { println(first_positive([-2, 0, 7]).unwrap()); println(first_positive([-2, 0]) is None) }'
# 7
# true
```

`while` loops may produce a value with `break value`; the branch when the condition becomes false is `nobreak { ... }`. The older `else` spelling is deprecated. Avoid the older functional `loop ... { ... }` form in new ports — MoonBit warns on it.

## Surface Hazards

- `alias` is a reserved keyword; avoid it as a local name, loop binder, or helper name to keep warning-enabled checks clean.
- `asm` is also reserved for possible future use; use `assembly` for public accessors, named arguments, and local helpers while still accepting textual placeholders like `"$asm"` in ported data formats.
- On the JavaScript backend, also avoid sentinel names like `undefined` for local test results — cross-target package tests can expose generated-JS name collisions.
- Source files do **not** contain OCaml-style `open`. Add package imports in `moon.pkg`, then call imported packages with their `@alias`.
- For `moon run -c` snippets that need extra packages, use an **MBTX import block** at the start: `import { "moonbitlang/x/crypto" }` (comma-separated entries for multiple packages). The source-file form `import "moonbitlang/core/encoding/ascii"` is rejected in command snippets.

## Process and Random

`@env` (in `moonbitlang/core/env`) provides `args() -> Array[String]`, `current_dir() -> String?`, `get_env_var(String) -> String?`, `get_env_vars() -> Map[String, String]`, `now() -> UInt64`, `set_env_var`, `unset_env_var`. `current_dir()` is optional — some platforms cannot always determine it. Prefer `x is Some(_)` over the deprecated `.is_some()`.

```sh
moon run -c 'fn main { let r = @random.Rand::chacha8(seed=@ascii.encode("01234567890123456789012345678901")); println(r.uint(limit=256).to_string()); println(r.uint(limit=256).to_string()) }'
# 21
# 42
```

`@random` provides deterministic PRNGs. `Rand::new()` is **reproducible**, not OS entropy. Do not substitute `@random` or `@env.now()` for a cryptographic random source when porting security-sensitive OCaml code (AES IVs, salts, file keys); keep an explicit random provider or use a target-specific secure API.

## Targets and Async I/O

```sh
moon run --target native -c $'#cfg(target="native")\nfn target_name() -> String { "native" }\n#cfg(not(target="native"))\nfn target_name() -> String { "other" }\nfn main { println(target_name()) }'
# native
```

`#cfg(...)` on its own line immediately before a declaration provides target-specific implementations. Combining `#cfg` and the declaration on the same line leaves the attribute unused.

MoonBit async has no `await` keyword — async functions call other async functions directly.

- Keep CPU-bound pure transformations over `Bytes` synchronous.
- Make filesystem/network entry points async when they touch `moonbitlang/async`.
- Prefer async wrappers that load file contents into `Bytes`, then call the synchronous core. This avoids making every recursive helper async.
- Async entry points and async tests need `moonbitlang/async` in the relevant `moon.pkg`; syntax alone is not enough.
- Async functions can raise by default. Do not add `raise` to async functions just to propagate errors; add `noraise` only when the async function must reject unhandled errors.

```sh
moon run --target native -c 'async fn main { println("async ok") }'
# Error: Cannot use `async fn main`: package moonbitlang/async is not imported.
```

```sh
moon run --target native -c $'import {\n  "moonbitlang/async",\n  "moonbitlang/async/fs" @fs,\n}\nasync fn main {\n  try @fs.read_file("/tmp/definitely-missing-fixture") catch {\n    _ => println(true)\n  } noraise {\n    _ => println(false)\n  }\n}'
# true
```

If a port should keep its pure core available on non-native targets, put async/file-system wrappers in a native-only package rather than importing async into the core. Imports are package-level; `supported_targets = "+native"` controls backend inclusion. A single test file can be target-gated with `options(targets: { "file_test.mbt": [ "native" ] })`, but imports remain package-level and may report unused on non-native checks.

## Testing

Test file roles:

- `*_test.mbt`: black-box tests. Call only public APIs through the package alias.
- `*_wbtest.mbt`: white-box tests. Run inside the package; may test private helpers.
- `*.mbt.md`: documentation with checked code blocks. `mbt check` for code that must compile and test; `mbt nocheck` for illustrative-only snippets.

Assertion style:

- `@test.assert_eq` for stable scalar or structural results (`Debug` bound; avoids the deprecated `Show`-based path).
- Boolean assertions: `@test.assert_eq(condition, true)` — there is no `@test.assert_true` helper.
- `@test.assert_eq` accepts a named `msg=` argument for shared assertion helpers.
- Shared test helpers that call `@test.assert_eq`, `fail`, or fallible APIs should declare `-> Unit raise Error` unless they use a narrower project error type.
- Pattern checks: `assert_true(value is Pattern(...))` or `guard ... else { fail(...) }`.
- `option == None` requires the option payload type to implement `Eq`. For private
  or intentionally non-`Eq` payloads, use `value is None` instead.
- Snapshots: `inspect(value, content="...")` for small values; `debug_inspect(value, content=...)` for complex values with `Debug`. If the expected snapshot is unknown, write `inspect(value)`, run `moon test --update`, then review the diff.
- Success paths through raising functions: call the fallible API directly and let the test fail on any error. Expected failures: `try f() catch { err => inspect(err) } noraise { _ => fail("expected to fail") }`.
- Use a wildcard `catch` arm for "this should raise"; match a specific error variant only when that variant is itself part of the compatibility contract.

```sh
moon run -c 'fn helper() -> Unit raise Error { @test.assert_eq(true, true); @test.assert_eq([1, 2], [1, 2]) }
fn main raise { helper() }'
```

```sh
moon run -c 'import { "moonbitlang/core/test" }
fn helper() -> Unit raise { @test.assert_eq(true, true, msg="named assertion") }
fn main raise { helper(); println("ok") }'
# ok
```

For parser/serializer, encoder/decoder, or loader/writer pairs, pair focused edge tests with at least one public-API round-trip test. Round-trips catch ownership, byte/text, and object-boundary mistakes that isolated unit tests miss.

Cover the byte/text edges that OCaml callers depended on: non-ASCII, NUL, form-feed, high-bit bytes, integer overflow, empty input, and boundary offsets.

## Command Cheatsheet

```sh
moon run -c 'fn main { ... }'              # quick language/API probe
moon check --warn-list +73                 # fast type check with extra warnings
moon test --outline                        # list discovered tests
moon test                                  # run all tests
moon test path/to/file_test.mbt            # run one test file
moon test package/dir --filter 'glob'      # targeted test glob
moon test --update                         # refresh snapshots, then review diff
moon test --target native                  # required for async I/O tests
moon coverage analyze > uncovered.log      # coverage report
moon info && moon fmt                      # final interface update and format
```

Validation rule for each migration patch:

1. Add or update tests before or with the ported code.
2. Run targeted `moon test` while developing.
3. Finish with `moon check --warn-list +73`, `moon test`, `moon info`, and `moon fmt`.

## Update Discipline

When a migration teaches a reusable rule that contradicts or refines this guide, update this file with:

- The OCaml behavior being replaced.
- The MoonBit API or idiom chosen.
- A minimal `moon run -c` probe and its observed output.
- Any known incompatibility, target limitation, or deferred behavior.
