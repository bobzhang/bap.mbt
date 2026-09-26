///|
test "RFC 1321 test suite" {
  let inputs = [
    "", "a", "abc", "message digest", "abcdefghijklmnopqrstuvwxyz", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
    "12345678901234567890123456789012345678901234567890123456789012345678901234567890",
  ]
  debug_inspect(
    inputs.map(s => @digest.md5_string(s)),
    content=(
      #|[
      #|  "d41d8cd98f00b204e9800998ecf8427e",
      #|  "0cc175b9c0f1b6a831c399e269772661",
      #|  "900150983cd24fb0d6963f7d28e17f72",
      #|  "f96b697d7cb7938d525a2f31aaf161d0",
      #|  "c3fcd3d76192e4007dfb496cca67e13b",
      #|  "d174ab98d277d9f5a5611c2c9f419d9f",
      #|  "57edf4a22be3c955ac49da2e2107b67a",
      #|]
    ),
  )
}

///|
test "raw digests, padding boundaries and UTF-8" {
  let raw = @digest.md5(b"abc")
  inspect(raw.length(), content="16")
  inspect(@digest.to_hex(raw), content="900150983cd24fb0d6963f7d28e17f72")
  inspect(@digest.md5_hex(b"abc"), content="900150983cd24fb0d6963f7d28e17f72")
  // 55, 56 and 64 bytes straddle the padding block boundary
  inspect(
    @digest.md5_string(String::make(55, 'a')),
    content="ef1772b6dff9a122358552954ad0df65",
  )
  inspect(
    @digest.md5_string(String::make(56, 'a')),
    content="3b0c8ac703f828b04c6c197006d17218",
  )
  inspect(
    @digest.md5_string(String::make(64, 'a')),
    content="014842d480b571495a4a0363793f7367",
  )
  inspect(@digest.md5_string("é"), content=@digest.md5_hex(b"\xc3\xa9"))
  inspect(@digest.to_hex(b"\x00\x0f\xff"), content="000fff")
}
