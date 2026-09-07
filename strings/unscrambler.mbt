///|
struct StringsAlphabet {
  length_value : Int
  index_fn : (Byte) -> Int
}

///|
struct StringsUnscrambler {
  alphabet_value : StringsAlphabet
  words_value : Array[Bytes]
}

///|
fn strings_byte_delta(byte : Byte, base : Byte) -> Int {
  byte.to_int() - base.to_int()
}

///|
fn strings_is_upper(byte : Byte) -> Bool {
  byte >= b'A' && byte <= b'Z'
}

///|
fn strings_is_lower(byte : Byte) -> Bool {
  byte >= b'a' && byte <= b'z'
}

///|
fn strings_is_alpha(byte : Byte) -> Bool {
  strings_is_upper(byte) || strings_is_lower(byte)
}

///|
fn strings_uppercase(byte : Byte) -> Byte {
  if strings_is_lower(byte) {
    (byte.to_int() - 32).to_byte()
  } else {
    byte
  }
}

///|
fn strings_ascii_alpha_index(byte : Byte) -> Int {
  if strings_is_upper(byte) {
    strings_byte_delta(byte, b'A')
  } else {
    strings_byte_delta(byte, b'a') + 26
  }
}

///|
fn strings_ascii_alpha_caseless_index(byte : Byte) -> Int {
  strings_byte_delta(strings_uppercase(byte), b'A')
}

///|
fn strings_ascii_digit_index(byte : Byte) -> Int {
  strings_byte_delta(byte, b'0')
}

///|
pub fn StringsAlphabet::create(
  length~ : Int,
  index~ : (Byte) -> Int,
) -> StringsAlphabet {
  { length_value: length, index_fn: index, }
}

///|
pub fn StringsAlphabet::length(self : StringsAlphabet) -> Int {
  self.length_value
}

///|
pub fn StringsAlphabet::index(self : StringsAlphabet, byte : Byte) -> Int {
  (self.index_fn)(byte)
}

///|
pub fn StringsAlphabet::contains(self : StringsAlphabet, byte : Byte) -> Bool {
  let index = self.index(byte)
  index >= 0 && index < self.length_value
}

///|
pub fn StringsAlphabet::ascii() -> StringsAlphabet {
  StringsAlphabet::create(length=128, index=byte => byte.to_int())
}

///|
pub fn StringsAlphabet::alpha() -> StringsAlphabet {
  StringsAlphabet::create(length=52, index=strings_ascii_alpha_index)
}

///|
pub fn StringsAlphabet::alpha_caseless() -> StringsAlphabet {
  StringsAlphabet::create(length=26, index=strings_ascii_alpha_caseless_index)
}

///|
pub fn StringsAlphabet::digits() -> StringsAlphabet {
  StringsAlphabet::create(length=10, index=strings_ascii_digit_index)
}

///|
pub fn StringsAlphabet::alphanum() -> StringsAlphabet {
  StringsAlphabet::create(length=62, index=byte => {
    if strings_is_alpha(byte) {
      strings_ascii_alpha_index(byte)
    } else {
      strings_ascii_digit_index(byte) + 52
    }
  })
}

///|
pub fn StringsAlphabet::alphanum_caseless() -> StringsAlphabet {
  StringsAlphabet::create(length=36, index=byte => {
    if strings_is_alpha(byte) {
      strings_ascii_alpha_caseless_index(byte)
    } else {
      strings_ascii_digit_index(byte) + 26
    }
  })
}

///|
pub fn StringsAlphabet::printable() -> StringsAlphabet {
  StringsAlphabet::create(length=95, index=byte => {
    strings_byte_delta(byte, b' ')
  })
}

///|
fn StringsAlphabet::spectrum(
  self : StringsAlphabet,
  word : BytesView,
) -> Array[Int] {
  let counts = Array::make(self.length_value, 0)
  for byte in word {
    let index = self.index(byte)
    if index >= 0 && index < self.length_value {
      counts[index] = counts[index] + 1
    }
  }
  counts
}

///|
fn strings_spectrum_subset(
  available : ArrayView[Int],
  needed : ArrayView[Int],
) -> Bool {
  if available.length() != needed.length() {
    false
  } else {
    let mut ok = true
    for i in 0..<available.length() {
      if needed[i] > available[i] {
        ok = false
      }
    }
    ok
  }
}

///|
fn strings_compare_spectrum(lhs : ArrayView[Int], rhs : ArrayView[Int]) -> Int {
  let limit = if lhs.length() < rhs.length() {
    lhs.length()
  } else {
    rhs.length()
  }
  for i in 0..<limit {
    let order = lhs[i].compare(rhs[i])
    if order != 0 {
      return order
    }
  }
  lhs.length().compare(rhs.length())
}

///|
pub fn StringsUnscrambler::empty(
  alphabet~ : StringsAlphabet,
) -> StringsUnscrambler {
  { alphabet_value: alphabet, words_value: [], }
}

///|
pub fn StringsUnscrambler::empty_ascii() -> StringsUnscrambler {
  StringsUnscrambler::empty(alphabet=StringsAlphabet::ascii())
}

///|
pub fn StringsUnscrambler::alphabet(
  self : StringsUnscrambler,
) -> StringsAlphabet {
  self.alphabet_value
}

///|
pub fn StringsUnscrambler::words(self : StringsUnscrambler) -> Array[Bytes] {
  self.words_value.copy()
}

///|
pub fn StringsUnscrambler::add_word(
  self : StringsUnscrambler,
  word : BytesView,
) -> StringsUnscrambler {
  let words = self.words_value.copy()
  words.push(word.to_owned())
  { alphabet_value: self.alphabet_value, words_value: words, }
}

///|
pub fn StringsUnscrambler::of_lines(
  alphabet~ : StringsAlphabet,
  lines : ArrayView[Bytes],
) -> StringsUnscrambler {
  let mut dict = StringsUnscrambler::empty(alphabet~)
  for line in lines {
    dict = dict.add_word(line)
  }
  dict
}

///|
fn strings_split_lines(data : BytesView) -> Array[Bytes] {
  let lines = []
  let mut start = 0
  for i in 0..<data.length() {
    if data[i] == b'\n' {
      let mut stop = i
      if stop > start && data[stop - 1] == b'\r' {
        stop = stop - 1
      }
      lines.push(data[start:stop].to_owned())
      start = i + 1
    }
  }
  if start < data.length() {
    let mut stop = data.length()
    if stop > start && data[stop - 1] == b'\r' {
      stop = stop - 1
    }
    lines.push(data[start:stop].to_owned())
  }
  lines
}

///|
pub fn StringsUnscrambler::of_bytes(
  alphabet~ : StringsAlphabet,
  data : BytesView,
) -> StringsUnscrambler {
  StringsUnscrambler::of_lines(alphabet~, strings_split_lines(data))
}

///|
pub fn StringsUnscrambler::of_file(
  alphabet~ : StringsAlphabet,
  path : String,
) -> Result[StringsUnscrambler, String] {
  match @native_io.read_file(path) {
    Ok(data) => Ok(StringsUnscrambler::of_bytes(alphabet~, data))
    Err(reason) => Err(reason)
  }
}

///|
pub fn StringsUnscrambler::of_files(
  alphabet~ : StringsAlphabet,
  paths : ArrayView[String],
) -> Result[StringsUnscrambler, String] {
  let mut dict = StringsUnscrambler::empty(alphabet~)
  for path in paths {
    match @native_io.read_file(path) {
      Ok(data) => {
        let loaded = StringsUnscrambler::of_bytes(alphabet~, data)
        for word in loaded.words() {
          dict = dict.add_word(word)
        }
      }
      Err(reason) => return Err(reason)
    }
  }
  Ok(dict)
}

///|
pub fn StringsUnscrambler::build(
  self : StringsUnscrambler,
  chars : BytesView,
) -> Array[Bytes] {
  let available = self.alphabet_value.spectrum(chars)
  let matches = []
  let mut ordinal = 0
  for word in self.words_value {
    let spectrum = self.alphabet_value.spectrum(word)
    if strings_spectrum_subset(available, spectrum) {
      matches.push((ordinal, word, spectrum))
    }
    ordinal = ordinal + 1
  }
  matches.sort_by(fn(left, right) {
    let spectrum_order = strings_compare_spectrum(left.2, right.2)
    if spectrum_order != 0 {
      spectrum_order
    } else {
      right.0.compare(left.0)
    }
  })
  let out = []
  for entry in matches {
    out.push(entry.1)
  }
  out
}

///|
pub fn StringsUnscrambler::is_buildable(
  self : StringsUnscrambler,
  chars : BytesView,
) -> Bool {
  let available = self.alphabet_value.spectrum(chars)
  self.words_value.any(word => {
    strings_spectrum_subset(available, self.alphabet_value.spectrum(word))
  })
}
