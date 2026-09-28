// Regressions that need a 1 GiB buffer: wasm-gc cannot allocate an array
// that large, so this file only runs on js and native (see moon.pkg). The
// test is skipped by default to keep ordinary runs light; run it with
// `moon test -p bobzhang/bap/memory --target native --include-skipped`.

///|
/// Regression (code review): `Memory::merge` added the two lengths as Int
/// before widening, so two adjacent 1 GiB regions (2^31 bytes together)
/// overflowed the sum, passed the contiguity check and asked for an array
/// of negative size. The merged span does not fit an Int, so merge must
/// fail.
#skip("allocates 1 GiB; run with --include-skipped")
test "regression: merging two adjacent 1 GiB regions is rejected" {
  let gib = Bytes::make(1 << 30, b'\x00')
  let left = @memory.Memory::from_bytes(endian=LittleEndian, start=0UL, gib)
  let right = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x4000_0000UL,
    gib,
  )
  assert_true(left.merge(right) is Err(_))
  assert_true(right.merge(left) is Err(_))
}
