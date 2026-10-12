// Property-based tests for `dwarf`: LEB128 round trips, and robustness of
// every reader on arbitrary, truncated and mutated section bytes (they all
// return `Result`, so no input may abort them).

///|
test "qc: LEB128 encodes and decodes every Int64, signed and unsigned" {
  @quickcheck.check(
    (v : Int64) => {
      let signed = @dwarf.Leb128::of_int64(v, signed=true)
      let unsigned = @dwarf.Leb128::of_int64(v)
      let ok_signed = match @dwarf.Leb128::read(signed.bytes(), signed=true) {
        Ok((leb, next)) =>
          next == signed.bytes().length() && leb.to_int64() == Ok(v)
        Err(_) => false
      }
      let ok_unsigned = match @dwarf.Leb128::read(unsigned.bytes()) {
        Ok((leb, next)) =>
          next == unsigned.bytes().length() && leb.to_int64() == Ok(v)
        Err(_) => false
      }
      // minimal encodings: 7 payload bits per byte
      ok_signed &&
      ok_unsigned &&
      unsigned.bytes().length() <= 10 &&
      signed.bytes().length() <= 10
    },
    observe=v => {
      [
        @quickcheck.classify(v < 0L, "negative"),
        @quickcheck.classify(v.abs() < 128L, "one byte"),
      ]
    },
    count=1000,
    seed=71,
  )
}

///|
test "qc: LEB128 Int readers agree with the Int64 value" {
  @quickcheck.check(
    (v : Int32) => {
      let signed = @dwarf.Leb128::of_int(v, signed=true)
      let unsigned = @dwarf.Leb128::of_int(v)
      let input = @dwarf.DwarfInput::of_bytes(unsigned.bytes() + b"\x2a")
      let code_ok = match input.read_code() {
        Ok((code, next)) =>
          v >= 0 && code == v && next.position() == unsigned.bytes().length()
        // the unsigned reading of a negative Int does not fit an Int
        Err(_) => v < 0
      }
      code_ok && signed.to_int() == Ok(v)
    },
    count=500,
    seed=72,
  )
}

///|
test "qc: LEB128 read never overruns and rejects truncation" {
  @quickcheck.check(
    (input : (Bytes, Int32)) => {
      let (bytes, pos) = input
      let pos = if bytes.length() == 0 {
        0
      } else {
        pos.abs() % (bytes.length() + 2)
      }
      match @dwarf.Leb128::read(bytes, pos~) {
        Ok((leb, next)) =>
          next > pos &&
          next <= bytes.length() &&
          next - pos == leb.bytes().length() &&
          (bytes[next - 1].to_int() & 0x80) == 0
        Err(_) => true
      }
    },
    count=500,
    seed=73,
  )
}

///|
/// A section built from a valid sample, then mutated, or pure noise.
struct Section {
  bytes : Bytes
  offset : Int32
  endian_big : Bool
  wide : Bool
} derive(Debug)

///|
let sample_abbrev : Bytes = b"\x01\x2e\x00\x03\x08\x11\x01\x12\x0b\x00\x00\x00"

///|
let sample_info : Bytes = b"\x13\x00\x00\x00\x04\x00\x00\x00\x00\x00\x04\x01main\x00\x10\x00\x00\x00\x05\x00"

///|
fn mutate(base : Bytes, rs : @splitmix.RandomState) -> Bytes {
  let bytes = base.to_array()
  let edits = rs.next_uint(limit=5).reinterpret_as_int()
  for _ in 0..<edits {
    let len = bytes.length()
    if len == 0 {
      break
    }
    let pos = rs.next_uint(limit=len.reinterpret_as_uint()).reinterpret_as_int()
    match rs.next_uint(limit=5) {
      0 => bytes[pos] = rs.next_uint(limit=256).to_byte()
      1 => bytes.truncate(pos)
      2 => bytes.insert(pos, rs.next_uint(limit=256).to_byte())
      3 => bytes[pos] = b'\xff'
      _ => bytes[pos] = b'\x00'
    }
  }
  Bytes::from_array(bytes)
}

///|
impl @quickcheck.Arbitrary for Section with fn arbitrary(size, rs) {
  let bytes = match rs.next_uint(limit=3) {
    0 => mutate(sample_info, rs)
    1 => mutate(sample_abbrev, rs)
    _ =>
      Bytes::makei(
        rs
        .next_uint(limit=(size + 1).reinterpret_as_uint())
        .reinterpret_as_int(),
        _ => rs.next_uint(limit=256).to_byte(),
      )
  }
  let offset = match rs.next_uint(limit=4) {
    0 => -1 - rs.next_uint(limit=3).reinterpret_as_int()
    1 => 0x7fff_fff0 + rs.next_uint(limit=16).reinterpret_as_int()
    _ =>
      rs
      .next_uint(limit=(bytes.length() + 4).reinterpret_as_uint())
      .reinterpret_as_int()
  }
  {
    bytes,
    offset,
    endian_big: rs.next_uint(limit=2) == 0,
    wide: rs.next_uint(limit=2) == 0,
  }
}

///|
impl @quickcheck.Shrink for Section with fn shrink(s) {
  let out : Array[Section] = []
  let n = s.bytes.length()
  if n > 0 {
    out.push({ ..s, bytes: s.bytes[:n / 2].to_owned(), })
    out.push({ ..s, bytes: s.bytes[:n - 1].to_owned(), })
  }
  if s.offset != 0 {
    out.push({ ..s, offset: 0, })
  }
  out.iter()
}

///|
fn Section::endian(self : Section) -> @bitvec.Endian {
  if self.endian_big {
    BigEndian
  } else {
    LittleEndian
  }
}

///|
fn Section::size(self : Section) -> @dwarf.DwarfWordSize {
  if self.wide {
    W64
  } else {
    W32
  }
}

///|
/// A successful read consumed at least one byte and stayed in the input.
fn[T] within(r : Result[(T, @dwarf.DwarfInput), String], n : Int32) -> Bool {
  match r {
    Ok((_, next)) => next.position() > 0 && next.position() <= n
    Err(_) => true
  }
}

///|
test "qc: DwarfInput readers stay within their input" {
  @quickcheck.check(
    (s : Section) => {
      let input = @dwarf.DwarfInput::of_bytes(s.bytes)
      let n = s.bytes.length()
      let endian = s.endian()
      let size = s.size()
      let mut ok = within(input.read_byte(), n) &&
        within(input.read_code(), n) &&
        within(input.read_cstring(), n) &&
        within(input.read_attr(), n) &&
        within(input.read_form(), n) &&
        within(input.read_tag(), n) &&
        within(input.read_version(), n) &&
        within(input.read_address_size(), n) &&
        within(input.read_unit_size(endian~), n) &&
        within(input.read_address(endian~, size~), n) &&
        within(input.read_offset(endian~, size~), n) &&
        within(input.read_int(endian~, size~), n) &&
        within(input.read_int64(endian~, size~), n) &&
        within(input.read_int16(endian~), n)
      let lenspecs : Array[@dwarf.DwarfLenspec] = [
        DwarfOne,
        DwarfTwo,
        DwarfFour,
        DwarfEight,
        DwarfLeb128,
      ]
      for lenspec in lenspecs {
        ok = ok &&
          within(input.read_block(lenspec~, endian~), n) &&
          within(input.read_const(lenspec~, endian~), n)
      }
      ok
    },
    count=500,
    seed=74,
  )
}

///|
test "qc: section-table readers accept any bytes and offset" {
  @quickcheck.check(
    (s : Section) => {
      match @dwarf.DwarfSectionBuffer::create(s.bytes) {
        Ok(buf) => {
          let endian = s.endian()
          let size = s.size()
          let offset = s.offset
          ignore(@dwarf.DwarfAbbrevTable::of_bytes(s.bytes, offset~))
          ignore(@dwarf.DwarfInfoUnitHeader::read(buf, offset~, endian~))
          ignore(
            @dwarf.DwarfAddressTable::read(
              buf,
              offset~,
              endian~,
              addr_size=size,
            ),
          )
          ignore(
            @dwarf.DwarfAddressTable::read_contribution(buf, offset~, endian~),
          )
          ignore(
            @dwarf.DwarfLocationList::read(
              buf,
              offset~,
              endian~,
              addr_size=size,
            ),
          )
          ignore(
            @dwarf.DwarfLocationList::read_loc(
              buf,
              offset~,
              endian~,
              addr_size=size,
            ),
          )
          ignore(
            @dwarf.DwarfRangeList::read(buf, offset~, endian~, addr_size=size),
          )
          ignore(
            @dwarf.DwarfRangeList::read_ranges(
              buf,
              offset~,
              endian~,
              addr_size=size,
            ),
          )
          ignore(
            @dwarf.DwarfStringOffsetsTable::read(
              buf,
              offset~,
              endian~,
              dwarf_size=size,
            ),
          )
          ignore(
            @dwarf.DwarfStringOffsetsTable::read_contribution(
              buf,
              offset~,
              endian~,
            ),
          )
          true
        }
        Err(_) => true
      }
    },
    count=500,
    seed=75,
  )
}

///|
/// debug_info and debug_abbrev sections derived from a valid pair.
struct DebugPair {
  info : Section
  abbrev : Section
} derive(Debug)

///|
impl @quickcheck.Arbitrary for DebugPair with fn arbitrary(size, rs) {
  let info : Section = @quickcheck.Arbitrary::arbitrary(size, rs)
  let abbrev : Section = @quickcheck.Arbitrary::arbitrary(size, rs)
  if rs.next_uint(limit=4) == 0 {
    { info, abbrev, }
  } else {
    {
      info: { ..info, bytes: mutate(sample_info, rs), },
      abbrev: { ..abbrev, bytes: mutate(sample_abbrev, rs), },
    }
  }
}

///|
impl @quickcheck.Shrink for DebugPair with fn shrink(p) {
  let out : Array[DebugPair] = []
  for info in @quickcheck.Shrink::shrink(p.info) {
    out.push({ ..p, info, })
  }
  for abbrev in @quickcheck.Shrink::shrink(p.abbrev) {
    out.push({ ..p, abbrev, })
  }
  out.iter()
}

///|
test "qc: function extraction survives mutated debug_info and debug_abbrev" {
  @quickcheck.check(
    (input : DebugPair) => {
      let { info, abbrev, } = input
      match
        @dwarf.DwarfData::from_bytes(
          endian=info.endian(),
          info=info.bytes,
          abbrev=abbrev.bytes,
          str=abbrev.bytes,
          ranges=info.bytes,
          rnglists=abbrev.bytes,
        ) {
        Ok(data) => {
          ignore(data.dies())
          ignore(data.unit_headers())
          ignore(data.die_by_section_offset(info.offset))
          ignore(data.debug_string(offset=abbrev.offset))
          let functions = data.functions()
          // the lazy iterator yields what `functions` returns when that
          // succeeds (it skips units with warnings instead of failing)
          let iterated = data.iter_functions().to_array()
          let iter_ok = match functions {
            Ok(fs) =>
              iterated.length() == fs.length() &&
              iterated.iter().zip(fs.iter()).all(p => p.0.equal(p.1))
            Err(_) => true
          }
          let fbi_ok = match @dwarf.DwarfFbi::create(data) {
            // every named function carries its name, its accessors agree,
            // and it is one of the functions of the data
            Ok(fbi) =>
              fbi
              .functions()
              .iter()
              .all(entry => {
                let (name, f) = entry
                name == f.name() &&
                f.pc_lo() == f.low_pc() &&
                f.pc_hi() == f.high_pc() &&
                (match functions {
                  Ok(fs) => fs.iter().any(g => g.equal(f))
                  Err(_) => true
                })
              })
            Err(_) => true
          }
          iter_ok && fbi_ok
        }
        Err(_) => true
      }
    },
    observe=input => {
      let { info, abbrev, } = input
      let parsed = match
        @dwarf.DwarfData::from_bytes(
          endian=info.endian(),
          info=info.bytes,
          abbrev=abbrev.bytes,
        ) {
        Ok(data) => data.functions() is Ok(fs) && !fs.is_empty()
        Err(_) => false
      }
      [@quickcheck.classify(parsed, "functions extracted")]
    },
    count=500,
    seed=76,
  )
}

///|
test "qc: the unmutated sample still yields main" {
  let data = @dwarf.DwarfData::from_bytes(
    endian=LittleEndian,
    info=sample_info,
    abbrev=sample_abbrev,
  )
  guard data is Ok(data) else { fail("sample does not parse") }
  guard data.functions() is Ok([f]) else { fail("expected one function") }
  assert_eq(f.name(), "main")
}

///|
/// A real ELF object, truncated or with a few bytes changed.
struct ElfMutant {
  which : Int32
  bytes : Bytes
} derive(Debug)

///|
fn elf_fixture(which : Int32) -> Bytes {
  match which {
    0 => @objects.x86_64_elf_object()
    1 => @objects.aarch64_elf_object()
    2 => @objects.riscv64_elf_object()
    _ => @objects.x86_64_elf_tail_object()
  }
}

///|
impl @quickcheck.Arbitrary for ElfMutant with fn arbitrary(_size, rs) {
  let which = rs.next_uint(limit=4).reinterpret_as_int()
  let base = elf_fixture(which).to_array()
  let edits = 1 + rs.next_uint(limit=8).reinterpret_as_int()
  for _ in 0..<edits {
    let len = base.length()
    if len == 0 {
      break
    }
    // headers live at the start: bias edits towards them
    let limit = if rs.next_uint(limit=2) == 0 { len.min(128) } else { len }
    let pos = rs
      .next_uint(limit=limit.reinterpret_as_uint())
      .reinterpret_as_int()
    match rs.next_uint(limit=4) {
      0 => base.truncate(pos)
      1 => base[pos] = b'\xff'
      2 => base[pos] = b'\x00'
      _ => base[pos] = rs.next_uint(limit=256).to_byte()
    }
  }
  { which, bytes: Bytes::from_array(base), }
}

///|
impl @quickcheck.Shrink for ElfMutant

///|
test "qc: from_elf_bytes survives truncated and corrupted ELF objects" {
  @quickcheck.check(
    (m : ElfMutant) => {
      match @dwarf.DwarfData::from_elf_bytes(m.bytes) {
        Ok(data) => {
          ignore(data.functions())
          ignore(@dwarf.DwarfFbi::create(data))
          true
        }
        Err(_) => true
      }
    },
    count=300,
    seed=77,
  )
}
