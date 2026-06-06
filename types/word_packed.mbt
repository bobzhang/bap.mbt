///|
fn word_packed_error() -> String {
  "packed word operation failed"
}

///|
fn word_packed_element_count(
  left : Word,
  right : Word,
  element_width : Int,
) -> Result[Int, String] {
  if left.width() != right.width() {
    Err("packed word operation requires matching widths")
  } else if element_width <= 0 || left.width() % element_width != 0 {
    Err(
      "packed word operation requires an element width that divides the word width",
    )
  } else {
    Ok(left.width() / element_width)
  }
}

///|
fn Word::word_packed_element_at(
  self : Word,
  index : Int,
  element_width : Int,
) -> Result[Word, String] {
  if index < 0 || element_width <= 0 {
    Err(word_packed_error())
  } else {
    try
      self.extract(hi=(index + 1) * element_width - 1, lo=index * element_width)
    catch {
      _ => Err(word_packed_error())
    } noraise {
      word => Ok(word)
    }
  }
}

///|
fn word_packed_from_little_elements(
  elements : Array[Word],
) -> Result[Word, String] {
  if elements.is_empty() {
    Err("packed word operation requires at least one element")
  } else {
    let mut result = elements[elements.length() - 1]
    for offset in 1..<elements.length() {
      let index = elements.length() - offset - 1
      try result.concat(elements[index]) catch {
        _ => return Err(word_packed_error())
      } noraise {
        next => result = next
      }
    }
    Ok(result)
  }
}

///|
fn word_packed_mask(width : Int, enabled : Bool) -> Result[Word, String] {
  try {
    if enabled {
      Word::ones(width~)
    } else {
      Word::zero(width~)
    }
  } catch {
    _ => Err(word_packed_error())
  } noraise {
    word => Ok(word)
  }
}

///|
fn word_packed_order(
  left : Word,
  right : Word,
  signed : Bool,
) -> Result[Int, String] {
  try {
    if signed {
      left.compare_signed(right)
    } else {
      left.compare_unsigned(right)
    }
  } catch {
    _ => Err(word_packed_error())
  } noraise {
    order => Ok(order)
  }
}

///|
fn Word::word_packed_compare_mask(
  self : Word,
  other : Word,
  element_width : Int,
  signed : Bool,
  accept : (Int) -> Bool,
) -> Result[Word, String] {
  match word_packed_element_count(self, other, element_width) {
    Ok(count) => {
      let elements : Array[Word] = []
      for index in 0..<count {
        let left = match self.word_packed_element_at(index, element_width) {
          Ok(word) => word
          Err(reason) => return Err(reason)
        }
        let right = match other.word_packed_element_at(index, element_width) {
          Ok(word) => word
          Err(reason) => return Err(reason)
        }
        let order = match word_packed_order(left, right, signed) {
          Ok(order) => order
          Err(reason) => return Err(reason)
        }
        match word_packed_mask(element_width, accept(order)) {
          Ok(mask) => elements.push(mask)
          Err(reason) => return Err(reason)
        }
      }
      word_packed_from_little_elements(elements)
    }
    Err(reason) => Err(reason)
  }
}

///|
fn Word::word_packed_min_max(
  self : Word,
  other : Word,
  element_width : Int,
  signed : Bool,
  choose_left : (Int) -> Bool,
) -> Result[Word, String] {
  match word_packed_element_count(self, other, element_width) {
    Ok(count) => {
      let elements : Array[Word] = []
      for index in 0..<count {
        let left = match self.word_packed_element_at(index, element_width) {
          Ok(word) => word
          Err(reason) => return Err(reason)
        }
        let right = match other.word_packed_element_at(index, element_width) {
          Ok(word) => word
          Err(reason) => return Err(reason)
        }
        let order = match word_packed_order(left, right, signed) {
          Ok(order) => order
          Err(reason) => return Err(reason)
        }
        elements.push(if choose_left(order) { left } else { right })
      }
      word_packed_from_little_elements(elements)
    }
    Err(reason) => Err(reason)
  }
}

///|
fn word_packed_byte_index(byte : Word) -> Result[Int, String] {
  try byte.to_int() catch {
    _ => Err(word_packed_error())
  } noraise {
    value => Ok(value)
  }
}

///|
pub fn Word::packed_eq(
  self : Word,
  other : Word,
  element_width~ : Int,
) -> Result[Word, String] {
  self.word_packed_compare_mask(other, element_width, false, order => order == 0)
}

///|
pub fn Word::packed_gt(
  self : Word,
  other : Word,
  element_width~ : Int,
  signed? : Bool = false,
) -> Result[Word, String] {
  self.word_packed_compare_mask(other, element_width, signed, order => order > 0)
}

///|
pub fn Word::packed_min(
  self : Word,
  other : Word,
  element_width~ : Int,
  signed? : Bool = false,
) -> Result[Word, String] {
  self.word_packed_min_max(other, element_width, signed, order => order <= 0)
}

///|
pub fn Word::packed_max(
  self : Word,
  other : Word,
  element_width~ : Int,
  signed? : Bool = false,
) -> Result[Word, String] {
  self.word_packed_min_max(other, element_width, signed, order => order >= 0)
}

///|
pub fn Word::x86_pshufb(self : Word, mask : Word) -> Result[Word, String] {
  if self.width() != mask.width() {
    Err("pshufb requires matching operand widths")
  } else if self.width() != 64 && self.width() != 128 && self.width() != 256 {
    Err("pshufb supports 64-, 128-, and 256-bit operands")
  } else {
    let byte_count = self.width() / 8
    let lane_bytes = if self.width() == 64 { 8 } else { 16 }
    let index_mask = if self.width() == 64 { 0x07 } else { 0x0f }
    let zero = try Word::zero(width=8) catch {
      _ => return Err(word_packed_error())
    } noraise {
      word => word
    }
    let elements : Array[Word] = []
    for index in 0..<byte_count {
      let mask_byte = match mask.word_packed_element_at(index, 8) {
        Ok(word) => word
        Err(reason) => return Err(reason)
      }
      let raw = match word_packed_byte_index(mask_byte) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      if (raw & 0x80) != 0 {
        elements.push(zero)
      } else {
        let lane_base = index / lane_bytes * lane_bytes
        let source_index = lane_base + (raw & index_mask)
        match self.word_packed_element_at(source_index, 8) {
          Ok(word) => elements.push(word)
          Err(reason) => return Err(reason)
        }
      }
    }
    word_packed_from_little_elements(elements)
  }
}
