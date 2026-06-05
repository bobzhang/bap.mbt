///|
pub(all) enum DwarfWordSize {
  W32
  W64
} derive(Eq, Debug)

///|
pub(all) enum DwarfLenspec {
  DwarfOne
  DwarfTwo
  DwarfFour
  DwarfEight
  DwarfLeb128
} derive(Eq, Debug)

///|
pub fn DwarfLenspec::leb128() -> DwarfLenspec {
  DwarfLeb128
}

///|
pub fn DwarfLenspec::one() -> DwarfLenspec {
  DwarfOne
}

///|
pub fn DwarfLenspec::two() -> DwarfLenspec {
  DwarfTwo
}

///|
pub fn DwarfLenspec::four() -> DwarfLenspec {
  DwarfFour
}

///|
pub fn DwarfLenspec::eight() -> DwarfLenspec {
  DwarfEight
}

///|
pub(all) enum DwarfIndexSpec {
  DwarfIndexLeb128
  DwarfIndexOne
  DwarfIndexTwo
  DwarfIndexThree
  DwarfIndexFour
} derive(Eq, Debug)

///|
pub(all) enum DwarfTag {
  DwarfEntryPoint
  DwarfCompileUnit
  DwarfPartialUnit
  DwarfLexicalBlock
  DwarfInlinedSubroutine
  DwarfSubprogram
  DwarfUnknownTag(Int)
} derive(Eq, Debug)

///|
pub fn DwarfTag::entry_point() -> DwarfTag {
  DwarfEntryPoint
}

///|
pub fn DwarfTag::compile_unit() -> DwarfTag {
  DwarfCompileUnit
}

///|
pub fn DwarfTag::partial_unit() -> DwarfTag {
  DwarfPartialUnit
}

///|
pub fn DwarfTag::inlined_subroutine() -> DwarfTag {
  DwarfInlinedSubroutine
}

///|
pub fn DwarfTag::subprogram() -> DwarfTag {
  DwarfSubprogram
}

///|
pub fn DwarfTag::unknown(code : Int) -> DwarfTag {
  DwarfUnknownTag(code)
}

///|
pub(all) enum DwarfAttr {
  DwarfSibling
  DwarfLocation
  DwarfName
  DwarfImport
  DwarfCommonReference
  DwarfContainingType
  DwarfLinkageName
  DwarfFrameBase
  DwarfLowPc
  DwarfHighPc
  DwarfEntryPc
  DwarfRanges
  DwarfAbstractOrigin
  DwarfSpecification
  DwarfType
  DwarfObjectPointer
  DwarfStrOffsetsBase
  DwarfAddrBase
  DwarfRangesBase
  DwarfRnglistsBase
  DwarfLoclistsBase
  DwarfUnknownAttr(Int)
} derive(Eq, Debug)

///|
pub fn DwarfAttr::name() -> DwarfAttr {
  DwarfName
}

///|
pub fn DwarfAttr::import_() -> DwarfAttr {
  DwarfImport
}

///|
pub fn DwarfAttr::common_reference() -> DwarfAttr {
  DwarfCommonReference
}

///|
pub fn DwarfAttr::containing_type() -> DwarfAttr {
  DwarfContainingType
}

///|
pub fn DwarfAttr::sibling() -> DwarfAttr {
  DwarfSibling
}

///|
pub fn DwarfAttr::location() -> DwarfAttr {
  DwarfLocation
}

///|
pub fn DwarfAttr::frame_base() -> DwarfAttr {
  DwarfFrameBase
}

///|
pub fn DwarfAttr::low_pc() -> DwarfAttr {
  DwarfLowPc
}

///|
pub fn DwarfAttr::high_pc() -> DwarfAttr {
  DwarfHighPc
}

///|
pub fn DwarfAttr::entry_pc() -> DwarfAttr {
  DwarfEntryPc
}

///|
pub fn DwarfAttr::loclists_base() -> DwarfAttr {
  DwarfLoclistsBase
}

///|
pub fn DwarfAttr::type_() -> DwarfAttr {
  DwarfType
}

///|
pub fn DwarfAttr::object_pointer() -> DwarfAttr {
  DwarfObjectPointer
}

///|
pub fn DwarfAttr::unknown(code : Int) -> DwarfAttr {
  DwarfUnknownAttr(code)
}

///|
pub(all) enum DwarfForm {
  DwarfAddr
  DwarfBlock(DwarfLenspec)
  DwarfConst(DwarfLenspec)
  DwarfSignedConst(DwarfLenspec)
  DwarfFlag
  DwarfString
  DwarfStrp
  DwarfStrx(DwarfIndexSpec)
  DwarfAddrx(DwarfIndexSpec)
  DwarfData16
  DwarfLineStrp
  DwarfImplicitConst(Int64)
  DwarfLoclistx
  DwarfRnglistx
  DwarfStrpSup
  DwarfRefSup4
  DwarfRefSup8
  DwarfRefAlt
  DwarfStrpAlt
  DwarfRefAddr
  DwarfRefSig8
  DwarfOffset
  DwarfRef(DwarfLenspec)
  DwarfIndirect
  DwarfExpr
  DwarfFlagPresent
} derive(Eq, Debug)

///|
pub fn DwarfForm::addr() -> DwarfForm {
  DwarfAddr
}

///|
pub fn DwarfForm::block(spec : DwarfLenspec) -> DwarfForm {
  DwarfBlock(spec)
}

///|
pub fn DwarfForm::const_(spec : DwarfLenspec) -> DwarfForm {
  DwarfConst(spec)
}

///|
pub fn DwarfForm::flag_present() -> DwarfForm {
  DwarfFlagPresent
}

///|
pub fn DwarfForm::string() -> DwarfForm {
  DwarfString
}

///|
pub fn DwarfForm::strp() -> DwarfForm {
  DwarfStrp
}

///|
pub fn DwarfForm::ref_(spec : DwarfLenspec) -> DwarfForm {
  DwarfRef(spec)
}

///|
pub fn DwarfForm::indirect() -> DwarfForm {
  DwarfIndirect
}

///|
pub fn DwarfForm::offset() -> DwarfForm {
  DwarfOffset
}

///|
pub fn DwarfForm::expr() -> DwarfForm {
  DwarfExpr
}

///|
pub fn DwarfForm::sig_() -> DwarfForm {
  DwarfRefSig8
}

///|
struct DwarfInput {
  data : Bytes
  position_value : Int
}

///|
struct DwarfInputReader[T] {
  read_fn : (DwarfInput) -> Result[(T, DwarfInput), String]
}

///|
pub fn DwarfInput::of_bytes(data : Bytes) -> DwarfInput {
  { data, position_value: 0 }
}

///|
pub fn[T] DwarfInputReader::run(
  self : DwarfInputReader[T],
  input : DwarfInput,
) -> Result[(T, DwarfInput), String] {
  (self.read_fn)(input)
}

///|
pub fn DwarfInputReader::char() -> DwarfInputReader[Int] {
  { read_fn: input => input.read_byte() }
}

///|
pub fn DwarfInputReader::code() -> DwarfInputReader[Int] {
  { read_fn: input => input.read_code() }
}

///|
pub fn DwarfInputReader::tag() -> DwarfInputReader[DwarfTag] {
  { read_fn: input => input.read_tag() }
}

///|
pub fn DwarfInputReader::form() -> DwarfInputReader[DwarfForm] {
  { read_fn: input => input.read_form() }
}

///|
pub fn DwarfInputReader::attr() -> DwarfInputReader[DwarfAttr] {
  { read_fn: input => input.read_attr() }
}

///|
pub fn DwarfInputReader::string() -> DwarfInputReader[String] {
  { read_fn: input => input.read_cstring() }
}

///|
pub fn DwarfInputReader::address(
  endian~ : @bitvec.Endian,
  size~ : DwarfWordSize,
) -> DwarfInputReader[UInt64] {
  { read_fn: input => input.read_address(endian~, size~) }
}

///|
pub fn DwarfInputReader::version() -> DwarfInputReader[Int] {
  { read_fn: input => input.read_version() }
}

///|
pub fn DwarfInputReader::unit_size(
  endian~ : @bitvec.Endian,
) -> DwarfInputReader[(DwarfWordSize, Int)] {
  { read_fn: input => input.read_unit_size(endian~) }
}

///|
pub fn DwarfInputReader::skip(bytes~ : Int) -> DwarfInputReader[Unit] {
  { read_fn: input => input.skip(bytes~).map(done => ((), done)) }
}

///|
pub fn DwarfInputReader::skip_zeros() -> DwarfInputReader[Unit] {
  { read_fn: input => input.skip_zeros().map(done => ((), done)) }
}

///|
pub fn DwarfInputReader::address_size() -> DwarfInputReader[DwarfWordSize] {
  { read_fn: input => input.read_address_size() }
}

///|
pub fn DwarfInputReader::offset(
  endian~ : @bitvec.Endian,
  size~ : DwarfWordSize,
) -> DwarfInputReader[Int] {
  { read_fn: input => input.read_offset(endian~, size~) }
}

///|
pub fn DwarfInputReader::block(
  lenspec~ : DwarfLenspec,
  endian~ : @bitvec.Endian,
) -> DwarfInputReader[Bytes] {
  { read_fn: input => input.read_block(lenspec~, endian~) }
}

///|
pub fn DwarfInputReader::const_(
  lenspec~ : DwarfLenspec,
  endian~ : @bitvec.Endian,
) -> DwarfInputReader[Int64] {
  { read_fn: input => input.read_const(lenspec~, endian~) }
}

///|
pub fn[A, B] DwarfInputReader::map(
  self : DwarfInputReader[A],
  f : (A) -> B,
) -> DwarfInputReader[B] {
  {
    read_fn: input => {
      match self.run(input) {
        Ok((value, next)) => Ok((f(value), next))
        Err(reason) => Err(reason)
      }
    },
  }
}

///|
pub fn[T] DwarfInputReader::take(
  self : DwarfInputReader[T],
) -> DwarfInputReader[T?] {
  self.map(value => Some(value))
}

///|
pub fn[T] DwarfInputReader::drop(
  self : DwarfInputReader[T],
) -> DwarfInputReader[T?] {
  self.map(_ => None)
}

///|
pub fn[T] DwarfInputReader::ignore_(
  self : DwarfInputReader[T],
) -> DwarfInputReader[Unit] {
  self.map(_ => ())
}

///|
pub fn[A, B] DwarfInputReader::pair(
  first : DwarfInputReader[A],
  second : DwarfInputReader[B],
) -> DwarfInputReader[(A, B)] {
  {
    read_fn: input => {
      match first.run(input) {
        Err(reason) => Err(reason)
        Ok((left, input)) =>
          match second.run(input) {
            Err(reason) => Err(reason)
            Ok((right, input)) => Ok(((left, right), input))
          }
      }
    },
  }
}

///|
pub fn DwarfInput::position(self : DwarfInput) -> Int {
  self.position_value
}

///|
pub fn DwarfInput::remaining(self : DwarfInput) -> Int {
  self.data.length() - self.position_value
}

///|
fn DwarfInput::with_position(self : DwarfInput, position : Int) -> DwarfInput {
  { ..self, position_value: position }
}

///|
fn DwarfInput::require(self : DwarfInput, bytes : Int) -> Result[Unit, String] {
  if bytes < 0 {
    Err("negative DWARF read size")
  } else if self.position_value + bytes > self.data.length() {
    Err("truncated DWARF input")
  } else {
    Ok(())
  }
}

///|
pub fn DwarfInput::read_byte(
  self : DwarfInput,
) -> Result[(Int, DwarfInput), String] {
  match self.require(1) {
    Ok(_) =>
      Ok(
        (
          self.data[self.position_value].to_int(),
          self.with_position(self.position_value + 1),
        ),
      )
    Err(reason) => Err(reason)
  }
}

///|
fn DwarfInput::read_uint(
  self : DwarfInput,
  bytes : Int,
  endian : @bitvec.Endian,
) -> Result[(UInt64, DwarfInput), String] {
  match self.require(bytes) {
    Ok(_) => {
      let mut value = 0UL
      for i in 0..<bytes {
        let shift = match endian {
          LittleEndian => i * 8
          BigEndian => (bytes - 1 - i) * 8
        }
        value = value |
          (self.data[self.position_value + i].to_int().to_uint64() << shift)
      }
      Ok((value, self.with_position(self.position_value + bytes)))
    }
    Err(reason) => Err(reason)
  }
}

///|
fn dwarf_sign_extend(value : UInt64, bits : Int) -> Int64 {
  if bits >= 64 {
    value.reinterpret_as_int64()
  } else {
    let sign = 1UL << (bits - 1)
    let extended = if (value & sign) != 0UL {
      value | (UInt64::lnot(0UL) << bits)
    } else {
      value
    }
    extended.reinterpret_as_int64()
  }
}

///|
fn DwarfInput::read_signed(
  self : DwarfInput,
  bytes : Int,
  endian : @bitvec.Endian,
) -> Result[(Int64, DwarfInput), String] {
  match self.read_uint(bytes, endian) {
    Ok((value, next)) => Ok((dwarf_sign_extend(value, bytes * 8), next))
    Err(reason) => Err(reason)
  }
}

///|
fn dwarf_word_bytes(size : DwarfWordSize) -> Int {
  match size {
    W32 => 4
    W64 => 8
  }
}

///|
fn dwarf_int64_to_int(value : Int64) -> Result[Int, String] {
  if value < -2147483648L || value > 2147483647L {
    Err("DWARF integer does not fit in Int")
  } else {
    Ok(value.to_int())
  }
}

///|
pub fn DwarfInput::read_int(
  self : DwarfInput,
  endian~ : @bitvec.Endian,
  size~ : DwarfWordSize,
) -> Result[(Int, DwarfInput), String] {
  match self.read_signed(dwarf_word_bytes(size), endian) {
    Ok((value, next)) =>
      match dwarf_int64_to_int(value) {
        Ok(n) => Ok((n, next))
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::read_int64(
  self : DwarfInput,
  endian~ : @bitvec.Endian,
  size~ : DwarfWordSize,
) -> Result[(Int64, DwarfInput), String] {
  self.read_signed(dwarf_word_bytes(size), endian)
}

///|
pub fn DwarfInput::read_address(
  self : DwarfInput,
  endian~ : @bitvec.Endian,
  size~ : DwarfWordSize,
) -> Result[(UInt64, DwarfInput), String] {
  self.read_uint(dwarf_word_bytes(size), endian)
}

///|
pub fn DwarfInput::read_offset(
  self : DwarfInput,
  endian~ : @bitvec.Endian,
  size~ : DwarfWordSize,
) -> Result[(Int, DwarfInput), String] {
  self.read_int(endian~, size~)
}

///|
pub fn DwarfInput::read_int16(
  self : DwarfInput,
  endian~ : @bitvec.Endian,
) -> Result[(Int, DwarfInput), String] {
  match self.read_signed(2, endian) {
    Ok((value, next)) => Ok((value.to_int(), next))
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::read_code(
  self : DwarfInput,
) -> Result[(Int, DwarfInput), String] {
  match Leb128::read(self.data[:], pos=self.position_value) {
    Ok((leb, next_pos)) =>
      match leb.to_int() {
        Ok(code) => Ok((code, self.with_position(next_pos)))
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn DwarfInput::read_signed_code(
  self : DwarfInput,
) -> Result[(Int64, DwarfInput), String] {
  match Leb128::read(self.data[:], signed=true, pos=self.position_value) {
    Ok((leb, next_pos)) =>
      match leb.to_int64() {
        Ok(code) => Ok((code, self.with_position(next_pos)))
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn dwarf_tag_of_int(code : Int) -> DwarfTag {
  match code {
    0x03 => DwarfEntryPoint
    0x0b => DwarfLexicalBlock
    0x11 => DwarfCompileUnit
    0x1d => DwarfInlinedSubroutine
    0x2e => DwarfSubprogram
    0x3c => DwarfPartialUnit
    other => DwarfUnknownTag(other)
  }
}

///|
fn dwarf_attr_of_int(code : Int) -> DwarfAttr {
  match code {
    0x01 => DwarfSibling
    0x02 => DwarfLocation
    0x03 => DwarfName
    0x18 => DwarfImport
    0x1a => DwarfCommonReference
    0x1d => DwarfContainingType
    0x11 => DwarfLowPc
    0x12 => DwarfHighPc
    0x31 => DwarfAbstractOrigin
    0x40 => DwarfFrameBase
    0x47 => DwarfSpecification
    0x49 => DwarfType
    0x52 => DwarfEntryPc
    0x55 => DwarfRanges
    0x64 => DwarfObjectPointer
    0x6e => DwarfLinkageName
    0x2007 => DwarfLinkageName
    0x72 => DwarfStrOffsetsBase
    0x73 => DwarfAddrBase
    0x74 => DwarfRnglistsBase
    0x8c => DwarfLoclistsBase
    0x2132 => DwarfRangesBase
    0x2133 => DwarfAddrBase
    other => DwarfUnknownAttr(other)
  }
}

///|
fn dwarf_form_of_int(code : Int) -> Result[DwarfForm, String] {
  match code {
    0x01 => Ok(DwarfAddr)
    0x03 => Ok(DwarfBlock(DwarfTwo))
    0x04 => Ok(DwarfBlock(DwarfFour))
    0x05 => Ok(DwarfConst(DwarfTwo))
    0x06 => Ok(DwarfConst(DwarfFour))
    0x07 => Ok(DwarfConst(DwarfEight))
    0x08 => Ok(DwarfString)
    0x09 => Ok(DwarfBlock(DwarfLeb128))
    0x0a => Ok(DwarfBlock(DwarfOne))
    0x0b => Ok(DwarfConst(DwarfOne))
    0x0c => Ok(DwarfFlag)
    0x0d => Ok(DwarfSignedConst(DwarfLeb128))
    0x0e => Ok(DwarfStrp)
    0x0f => Ok(DwarfConst(DwarfLeb128))
    0x10 => Ok(DwarfRefAddr)
    0x11 => Ok(DwarfRef(DwarfOne))
    0x12 => Ok(DwarfRef(DwarfTwo))
    0x13 => Ok(DwarfRef(DwarfFour))
    0x14 => Ok(DwarfRef(DwarfEight))
    0x15 => Ok(DwarfRef(DwarfLeb128))
    0x16 => Ok(DwarfIndirect)
    0x17 => Ok(DwarfOffset)
    0x18 => Ok(DwarfExpr)
    0x19 => Ok(DwarfFlagPresent)
    0x1a => Ok(DwarfStrx(DwarfIndexLeb128))
    0x1b => Ok(DwarfAddrx(DwarfIndexLeb128))
    0x1c => Ok(DwarfRefSup4)
    0x1d => Ok(DwarfStrpSup)
    0x1e => Ok(DwarfData16)
    0x1f => Ok(DwarfLineStrp)
    0x20 => Ok(DwarfRefSig8)
    0x21 => Ok(DwarfImplicitConst(0L))
    0x22 => Ok(DwarfLoclistx)
    0x23 => Ok(DwarfRnglistx)
    0x24 => Ok(DwarfRefSup8)
    0x25 => Ok(DwarfStrx(DwarfIndexOne))
    0x26 => Ok(DwarfStrx(DwarfIndexTwo))
    0x27 => Ok(DwarfStrx(DwarfIndexThree))
    0x28 => Ok(DwarfStrx(DwarfIndexFour))
    0x29 => Ok(DwarfAddrx(DwarfIndexOne))
    0x2a => Ok(DwarfAddrx(DwarfIndexTwo))
    0x2b => Ok(DwarfAddrx(DwarfIndexThree))
    0x2c => Ok(DwarfAddrx(DwarfIndexFour))
    0x1f01 => Ok(DwarfAddrx(DwarfIndexLeb128))
    0x1f02 => Ok(DwarfStrx(DwarfIndexLeb128))
    0x1f20 => Ok(DwarfRefAlt)
    0x1f21 => Ok(DwarfStrpAlt)
    other => Err("unknown DWARF form code: \{other}")
  }
}

///|
pub fn DwarfInput::read_tag(
  self : DwarfInput,
) -> Result[(DwarfTag, DwarfInput), String] {
  match self.read_code() {
    Ok((code, next)) => Ok((dwarf_tag_of_int(code), next))
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::read_attr(
  self : DwarfInput,
) -> Result[(DwarfAttr, DwarfInput), String] {
  match self.read_code() {
    Ok((code, next)) => Ok((dwarf_attr_of_int(code), next))
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::read_form(
  self : DwarfInput,
) -> Result[(DwarfForm, DwarfInput), String] {
  match self.read_code() {
    Ok((code, next)) =>
      match dwarf_form_of_int(code) {
        Ok(form) => Ok((form, next))
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::read_cstring(
  self : DwarfInput,
) -> Result[(String, DwarfInput), String] {
  let mut index = self.position_value
  while index < self.data.length() && self.data[index] != b'\x00' {
    index = index + 1
  }
  if index >= self.data.length() {
    return Err("DWARF string is not null-terminated")
  }
  let text = try @utf8.decode(self.data[self.position_value:index]) catch {
    _ => return Err("DWARF string is not valid UTF-8")
  } noraise {
    value => value
  }
  Ok((text, self.with_position(index + 1)))
}

///|
pub fn DwarfInput::read_version(
  self : DwarfInput,
) -> Result[(Int, DwarfInput), String] {
  match self.read_byte() {
    Ok((first, next)) =>
      match next.read_byte() {
        Ok((second, done)) => {
          let version = if first == 0 {
            second
          } else if second == 0 {
            first
          } else {
            second
          }
          Ok((version, done))
        }
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::read_address_size(
  self : DwarfInput,
) -> Result[(DwarfWordSize, DwarfInput), String] {
  match self.read_byte() {
    Ok((4, next)) => Ok((W32, next))
    Ok((8, next)) => Ok((W64, next))
    Ok((n, _)) => Err("unsupported DWARF address size: \{n}")
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::read_unit_size(
  self : DwarfInput,
  endian~ : @bitvec.Endian,
) -> Result[((DwarfWordSize, Int), DwarfInput), String] {
  match self.read_uint(4, endian) {
    Ok((0xffffffffUL, next)) =>
      match next.read_uint(8, endian) {
        Ok((size, done)) =>
          if size > 2147483647UL {
            Err("DWARF unit size does not fit in Int")
          } else {
            Ok(((W64, size.to_int()), done))
          }
        Err(reason) => Err(reason)
      }
    Ok((size, next)) =>
      if size > 2147483647UL {
        Err("DWARF unit size does not fit in Int")
      } else {
        Ok(((W32, size.to_int()), next))
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::skip(
  self : DwarfInput,
  bytes~ : Int,
) -> Result[DwarfInput, String] {
  match self.require(bytes) {
    Ok(_) => Ok(self.with_position(self.position_value + bytes))
    Err(reason) => Err(reason)
  }
}

///|
pub fn DwarfInput::skip_zeros(self : DwarfInput) -> Result[DwarfInput, String] {
  let mut index = self.position_value
  while index < self.data.length() && self.data[index] == b'\x00' {
    index = index + 1
  }
  if index >= self.data.length() {
    Err("truncated DWARF input while skipping zeroes")
  } else {
    Ok(self.with_position(index))
  }
}

///|
fn DwarfInput::read_len(
  self : DwarfInput,
  lenspec : DwarfLenspec,
  endian : @bitvec.Endian,
) -> Result[(Int64, DwarfInput), String] {
  match lenspec {
    DwarfLeb128 =>
      match Leb128::read(self.data[:], pos=self.position_value) {
        Ok((leb, next_pos)) =>
          match leb.to_int64() {
            Ok(value) => Ok((value, self.with_position(next_pos)))
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    DwarfOne =>
      match self.read_byte() {
        Ok((value, next)) => Ok((value.to_int64(), next))
        Err(reason) => Err(reason)
      }
    DwarfTwo => self.read_signed(2, endian)
    DwarfFour => self.read_signed(4, endian)
    DwarfEight => self.read_signed(8, endian)
  }
}

///|
pub fn DwarfInput::read_const(
  self : DwarfInput,
  lenspec~ : DwarfLenspec,
  endian~ : @bitvec.Endian,
) -> Result[(Int64, DwarfInput), String] {
  self.read_len(lenspec, endian)
}

///|
fn DwarfInput::read_unsigned_const(
  self : DwarfInput,
  lenspec : DwarfLenspec,
  endian : @bitvec.Endian,
) -> Result[(UInt64, DwarfInput), String] {
  match lenspec {
    DwarfLeb128 =>
      match self.read_code() {
        Ok((value, next)) =>
          if value < 0 {
            Err("negative DWARF unsigned constant")
          } else {
            Ok((value.to_uint64(), next))
          }
        Err(reason) => Err(reason)
      }
    DwarfOne =>
      match self.read_byte() {
        Ok((value, next)) => Ok((value.to_uint64(), next))
        Err(reason) => Err(reason)
      }
    DwarfTwo => self.read_uint(2, endian)
    DwarfFour => self.read_uint(4, endian)
    DwarfEight => self.read_uint(8, endian)
  }
}

///|
fn DwarfInput::read_signed_const(
  self : DwarfInput,
  lenspec : DwarfLenspec,
  endian : @bitvec.Endian,
) -> Result[(Int64, DwarfInput), String] {
  match lenspec {
    DwarfLeb128 => self.read_signed_code()
    _ => self.read_const(lenspec~, endian~)
  }
}

///|
fn DwarfInput::read_unsigned_bytes(
  self : DwarfInput,
  bytes : Int,
  endian : @bitvec.Endian,
) -> Result[(Int, DwarfInput), String] {
  match self.read_uint(bytes, endian) {
    Ok((value, next)) =>
      if value > 2147483647UL {
        Err("DWARF index does not fit in Int")
      } else {
        Ok((value.to_int(), next))
      }
    Err(reason) => Err(reason)
  }
}

///|
fn DwarfInput::read_index(
  self : DwarfInput,
  spec : DwarfIndexSpec,
  endian : @bitvec.Endian,
) -> Result[(Int, DwarfInput), String] {
  match spec {
    DwarfIndexLeb128 => self.read_code()
    DwarfIndexOne =>
      match self.read_byte() {
        Ok((value, next)) => Ok((value, next))
        Err(reason) => Err(reason)
      }
    DwarfIndexTwo => self.read_unsigned_bytes(2, endian)
    DwarfIndexThree => self.read_unsigned_bytes(3, endian)
    DwarfIndexFour => self.read_unsigned_bytes(4, endian)
  }
}

///|
fn DwarfInput::read_block_length(
  self : DwarfInput,
  lenspec : DwarfLenspec,
  endian : @bitvec.Endian,
) -> Result[(Int, DwarfInput), String] {
  match lenspec {
    DwarfLeb128 => self.read_code()
    DwarfOne => self.read_byte()
    DwarfTwo => self.read_unsigned_bytes(2, endian)
    DwarfFour => self.read_unsigned_bytes(4, endian)
    DwarfEight =>
      match self.read_uint(8, endian) {
        Ok((value, next)) =>
          if value > 2147483647UL {
            Err("invalid DWARF block size: \{value}")
          } else {
            Ok((value.to_int(), next))
          }
        Err(reason) => Err(reason)
      }
  }
}

///|
pub fn DwarfInput::read_block(
  self : DwarfInput,
  lenspec~ : DwarfLenspec,
  endian~ : @bitvec.Endian,
) -> Result[(Bytes, DwarfInput), String] {
  match self.read_block_length(lenspec, endian) {
    Ok((len, next)) =>
      match next.require(len) {
        Ok(_) =>
          Ok(
            (
              next.data[next.position_value:next.position_value + len].to_owned(),
              next.with_position(next.position_value + len),
            ),
          )
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}
