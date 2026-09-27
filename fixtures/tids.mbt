///|
fn is_hex_digit(c : Char) -> Bool {
  c is ('0'..='9' | 'a'..='f' | 'A'..='F')
}

///|
fn is_word_char(c : Char) -> Bool {
  c is ('0'..='9' | 'a'..='z' | 'A'..='Z' | '_')
}

///|
/// Renumbers the term identifiers (words of exactly eight hexadecimal
/// digits) of a printed program in the order of their first occurrence, so
/// that snapshots do not depend on the global identifier counter.
pub fn normalize_tids(text : String) -> String {
  let chars = text.to_array()
  let ids : Map[String, String] = Map([])
  let sb = StringBuilder()
  let n = chars.length()
  let mut i = 0
  while i < n {
    let c = chars[i]
    let at_boundary = i == 0 || !is_word_char(chars[i - 1])
    if at_boundary && is_hex_digit(c) {
      let mut j = i
      while j < n && is_hex_digit(chars[j]) {
        j += 1
      }
      let word = String::from_array(chars[i:j])
      let ends = j == n || !is_word_char(chars[j])
      if j - i == 8 && ends {
        let id = match ids.get(word) {
          Some(id) => id
          None => {
            let next = ids.length() + 1
            let digits = next.to_string()
            let id = "0".repeat(8 - digits.length()) + digits
            ids[word] = id
            id
          }
        }
        sb.write_string(id)
      } else {
        sb.write_string(word)
      }
      i = j
    } else {
      sb.write_char(c)
      i += 1
    }
  }
  sb.to_string()
}

///|
test "normalize_tids" {
  inspect(
    normalize_tids(
      "0000000a: sub main()\n00000003: goto %0000000a 0x0000000000401009",
    ),
    content=(
      #|00000001: sub main()
      #|00000002: goto %00000001 0x0000000000401009
    ),
  )
}
