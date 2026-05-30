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
  DwarfLexicalBlock
  DwarfInlinedSubroutine
  DwarfSubprogram
  DwarfUnknownTag(Int)
} derive(Eq, Debug)

///|
pub(all) enum DwarfAttr {
  DwarfName
  DwarfLinkageName
  DwarfLowPc
  DwarfHighPc
  DwarfEntryPc
  DwarfRanges
  DwarfAbstractOrigin
  DwarfSpecification
  DwarfStrOffsetsBase
  DwarfAddrBase
  DwarfRnglistsBase
  DwarfUnknownAttr(Int)
} derive(Eq, Debug)

///|
pub(all) enum DwarfForm {
  DwarfAddr
  DwarfBlock(DwarfLenspec)
  DwarfConst(DwarfLenspec)
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
  DwarfOffset
  DwarfRef(DwarfLenspec)
  DwarfIndirect
  DwarfExpr
  DwarfFlagPresent
} derive(Eq, Debug)

///|
struct DwarfInput {
  data : Bytes
  position_value : Int
}

///|
pub fn DwarfInput::of_bytes(data : Bytes) -> DwarfInput {
  { data, position_value: 0 }
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
    other => DwarfUnknownTag(other)
  }
}

///|
fn dwarf_attr_of_int(code : Int) -> DwarfAttr {
  match code {
    0x03 => DwarfName
    0x11 => DwarfLowPc
    0x12 => DwarfHighPc
    0x31 => DwarfAbstractOrigin
    0x47 => DwarfSpecification
    0x52 => DwarfEntryPc
    0x55 => DwarfRanges
    0x6e => DwarfLinkageName
    0x72 => DwarfStrOffsetsBase
    0x73 => DwarfAddrBase
    0x74 => DwarfRnglistsBase
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
    0x0c => Ok(DwarfConst(DwarfOne))
    0x0d => Ok(DwarfConst(DwarfLeb128))
    0x0e => Ok(DwarfStrp)
    0x0f => Ok(DwarfConst(DwarfLeb128))
    0x10 => Ok(DwarfOffset)
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
    0x20 => Ok(DwarfRef(DwarfEight))
    0x21 => Ok(DwarfImplicitConst(0L))
    0x22 => Ok(DwarfLoclistx)
    0x23 => Ok(DwarfRnglistx)
    0x25 => Ok(DwarfStrx(DwarfIndexOne))
    0x26 => Ok(DwarfStrx(DwarfIndexTwo))
    0x27 => Ok(DwarfStrx(DwarfIndexThree))
    0x28 => Ok(DwarfStrx(DwarfIndexFour))
    0x29 => Ok(DwarfAddrx(DwarfIndexOne))
    0x2a => Ok(DwarfAddrx(DwarfIndexTwo))
    0x2b => Ok(DwarfAddrx(DwarfIndexThree))
    0x2c => Ok(DwarfAddrx(DwarfIndexFour))
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
pub fn DwarfInput::read_block(
  self : DwarfInput,
  lenspec~ : DwarfLenspec,
  endian~ : @bitvec.Endian,
) -> Result[(Bytes, DwarfInput), String] {
  match self.read_len(lenspec, endian) {
    Ok((len64, next)) => {
      if len64 <= 0L || len64 > 2147483647L {
        return Err("invalid DWARF block size: \{len64}")
      }
      let len = len64.to_int()
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
    }
    Err(reason) => Err(reason)
  }
}
