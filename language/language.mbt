///|
struct Language {
  id_value : Int32
  name_value : String
}

///|
struct LanguageProperty[T] {
  values : Map[Int32, T]
}

///|
let language_next_id : Ref[Int32] = Ref(0)

///|
fn language_fresh_id() -> Int32 {
  let id = language_next_id.val
  language_next_id.val = id + 1
  id
}

///|
pub fn Language::create(name~ : String) -> Language {
  { id_value: language_fresh_id(), name_value: name, }
}

///|
pub fn Language::name(self : Language) -> String {
  self.name_value
}

///|
pub fn Language::to_string(self : Language) -> String {
  self.name()
}

///|
pub fn Language::compare(self : Language, other : Language) -> Int32 {
  self.id_value.compare(other.id_value)
}

///|
pub fn Language::equal(self : Language, other : Language) -> Bool {
  self.id_value == other.id_value
}

///|
pub fn[T] LanguageProperty::create() -> LanguageProperty[T] {
  { values: {}, }
}

///|
pub fn[T] LanguageProperty::set(
  self : LanguageProperty[T],
  language : Language,
  data : T,
) -> Unit {
  self.values[language.id_value] = data
}

///|
pub fn[T] LanguageProperty::get(
  self : LanguageProperty[T],
  language : Language,
) -> T? {
  self.values.get(language.id_value)
}

///|
pub fn[T] LanguageProperty::contains(
  self : LanguageProperty[T],
  language : Language,
) -> Bool {
  self.values.contains(language.id_value)
}
