///|
priv enum StringsDetectorStage {
  StringsDetectorWorking
  StringsDetectorAccepted
  StringsDetectorFinished
} derive(Eq)

///|
priv enum StringsDetectorAnswer {
  StringsDetectorAccept
  StringsDetectorDecline
  StringsDetectorUndecided
}

///|
struct StringsDecision[T] {
  m_value : Int
  n_value : Int
  cut_value : Int
  len_value : Int
  chars_rev : Array[Byte]
  data_rev : Array[T]
  stage_value : StringsDetectorStage
}

///|
struct StringsDetector[T] {
  t0_value : Double
  t1_value : Double
  w0_value : Double
  w1_value : Double
  p1_value : Double
  hypothesis : StringsDecision[T]
  alphabet_value : StringsAlphabet
}

///|
let strings_ln2 : Double = 0.6931471805599453

///|
fn strings_log(value : Double) -> Double {
  @math.log2(value) * strings_ln2
}

///|
fn strings_log1p(value : Double) -> Double {
  strings_log(1.0 + value)
}

///|
fn[T] strings_empty_decision() -> StringsDecision[T] {
  {
    m_value: 0,
    n_value: 0,
    cut_value: 0,
    len_value: 0,
    chars_rev: [],
    data_rev: [],
    stage_value: StringsDetectorWorking,
  }
}

///|
fn[T] StringsDetector::hprop(self : StringsDetector[T]) -> Double {
  self.hypothesis.m_value.to_double() * self.w0_value +
  self.hypothesis.n_value.to_double() * self.w1_value +
  self.p1_value
}

///|
fn[T] StringsDetector::decide(
  self : StringsDetector[T],
  probability : Double,
) -> StringsDetectorAnswer {
  if probability <= self.t0_value {
    StringsDetectorDecline
  } else if probability >= self.t1_value {
    StringsDetectorAccept
  } else {
    StringsDetectorUndecided
  }
}

///|
fn[T] StringsDecision::push(
  self : StringsDecision[T],
  data : T,
  byte : Byte,
) -> StringsDecision[T] {
  let chars = self.chars_rev.copy()
  let values = self.data_rev.copy()
  chars.insert(0, byte)
  values.insert(0, data)
  {
    m_value: self.m_value,
    n_value: self.n_value,
    cut_value: if self.stage_value == StringsDetectorAccepted {
      self.cut_value + 1
    } else {
      self.cut_value
    },
    len_value: self.len_value + 1,
    chars_rev: chars,
    data_rev: values,
    stage_value: self.stage_value,
  }
}

///|
fn[T] StringsDetector::update(
  self : StringsDetector[T],
  data : T,
  byte : Byte,
) -> StringsDetector[T] {
  let in_alphabet = self.alphabet_value.contains(byte)
  let h = {
    m_value: if in_alphabet {
      self.hypothesis.m_value
    } else {
      self.hypothesis.m_value + 1
    },
    n_value: if in_alphabet {
      self.hypothesis.n_value + 1
    } else {
      self.hypothesis.n_value
    },
    cut_value: self.hypothesis.cut_value,
    len_value: self.hypothesis.len_value,
    chars_rev: self.hypothesis.chars_rev,
    data_rev: self.hypothesis.data_rev,
    stage_value: self.hypothesis.stage_value,
  }
  let h = if in_alphabet { h.push(data, byte) } else { h }
  { ..self, hypothesis: h, }
}

///|
fn[T] StringsDetector::step_byte(
  self : StringsDetector[T],
  data : T,
  byte : Byte,
) -> StringsDetector[T] {
  let updated = self.update(data, byte)
  let p = updated.hprop()
  match (updated.hypothesis.stage_value, updated.decide(p)) {
    (StringsDetectorAccepted, StringsDetectorAccept) =>
      abort("unreachable detector state")
    (StringsDetectorAccepted, StringsDetectorUndecided) =>
      if p > updated.p1_value {
        {
          ..updated,
          hypothesis: {
            ..updated.hypothesis,
            n_value: 0,
            m_value: 0,
            cut_value: 0,
          },
        }
      } else {
        updated
      }
    (StringsDetectorAccepted, StringsDetectorDecline) =>
      {
        ..updated,
        hypothesis: {
          ..updated.hypothesis,
          stage_value: StringsDetectorFinished,
        },
      }
    (StringsDetectorWorking, StringsDetectorAccept) =>
      {
        ..updated,
        hypothesis: {
          ..updated.hypothesis,
          stage_value: StringsDetectorAccepted,
          n_value: 0,
          m_value: 0,
        },
      }
    (StringsDetectorWorking, StringsDetectorUndecided) =>
      if updated.hypothesis.n_value == 0 {
        { ..updated, hypothesis: strings_empty_decision(), }
      } else {
        updated
      }
    (StringsDetectorWorking, StringsDetectorDecline) =>
      { ..updated, hypothesis: strings_empty_decision(), }
    (StringsDetectorFinished, _) => updated
  }
}

///|
pub fn[T] StringsDetector::create(
  alphabet : StringsAlphabet,
  alpha? : Double = 0.05,
  beta? : Double = 0.001,
  p1? : Double = 0.5,
  ps? : Double = 0.05,
) -> StringsDetector[T] {
  let s = 245.0
  let a = alphabet.length().to_double()
  let n = 1.0 / ps
  {
    alphabet_value: alphabet,
    t0_value: strings_log(beta),
    t1_value: strings_log1p(-alpha),
    p1_value: strings_log(p1),
    w0_value: strings_log1p(-ps),
    w1_value: strings_log(a * n + s - a) - strings_log(a * n),
    hypothesis: strings_empty_decision(),
  }
}

///|
pub fn[T] StringsDetector::step(
  self : StringsDetector[T],
  data : T,
  byte : Byte,
) -> StringsDetector[T] {
  if self.hypothesis.stage_value == StringsDetectorFinished {
    { ..self, hypothesis: strings_empty_decision(), }.step_byte(data, byte)
  } else {
    self.step_byte(data, byte)
  }
}

///|
pub fn[T] StringsDetector::decision(
  self : StringsDetector[T],
) -> StringsDecision[T]? {
  if self.hypothesis.stage_value == StringsDetectorFinished {
    Some(self.hypothesis)
  } else {
    None
  }
}

///|
pub fn[T] StringsDetector::abort(
  self : StringsDetector[T],
) -> StringsDecision[T]? {
  if self.hypothesis.stage_value == StringsDetectorAccepted {
    Some({ ..self.hypothesis, cut_value: 0, })
  } else {
    None
  }
}

///|
pub fn[T, R] StringsDetector::when_decided(
  self : StringsDetector[T],
  init : R,
  f : (StringsDecision[T]) -> R,
) -> R {
  match self.decision() {
    Some(decision) => f(decision)
    None => init
  }
}

///|
pub fn[T] StringsDetector::run(
  self : StringsDetector[T],
  trace : ArrayView[(T, Byte)],
) -> Array[StringsDecision[T]] {
  let decisions = []
  let mut detector = self
  for event in trace {
    detector = detector.step(event.0, event.1)
    match detector.decision() {
      Some(decision) => decisions.push(decision)
      None => ()
    }
  }
  decisions
}

///|
pub fn[T] StringsDetector::score(self : StringsDetector[T]) -> Double {
  self.hprop()
}

///|
pub fn[T] StringsDetector::alphabet(
  self : StringsDetector[T],
) -> StringsAlphabet {
  self.alphabet_value
}

///|
pub fn[T] StringsDecision::result(
  self : StringsDecision[T],
) -> Array[(T, Byte)] {
  let out = []
  let mut index = self.data_rev.length() - 1
  while index >= self.cut_value {
    out.push((self.data_rev[index], self.chars_rev[index]))
    if index == 0 {
      return out
    }
    index = index - 1
  }
  out
}

///|
pub fn[T] StringsDecision::chars(self : StringsDecision[T]) -> Bytes {
  let bytes = []
  let mut index = self.chars_rev.length() - 1
  while index >= self.cut_value {
    bytes.push(self.chars_rev[index])
    if index == 0 {
      return Bytes::from_array(bytes)
    }
    index = index - 1
  }
  Bytes::from_array(bytes)
}

///|
pub fn[T] StringsDecision::data(
  self : StringsDecision[T],
  rev? : Bool = false,
) -> Array[T] {
  let out = []
  if rev {
    for i in self.cut_value..<self.data_rev.length() {
      out.push(self.data_rev[i])
    }
  } else {
    let mut index = self.data_rev.length() - 1
    while index >= self.cut_value {
      out.push(self.data_rev[index])
      if index == 0 {
        return out
      }
      index = index - 1
    }
  }
  out
}

///|
pub fn[T] StringsDecision::length(self : StringsDecision[T]) -> Int {
  self.len_value - self.cut_value
}

///|
pub fn[T] StringsDecision::accepted_count(self : StringsDecision[T]) -> Int {
  self.n_value
}

///|
pub fn[T] StringsDecision::rejected_count(self : StringsDecision[T]) -> Int {
  self.m_value
}
