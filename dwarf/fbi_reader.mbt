///|
/// Function-boundary information reader (upstream `Dwarf_fbi.t`).
///
/// `DwarfFbi::create` only validates the prerequisites (the `.debug_info`
/// and `.debug_abbrev` sections and the first unit header with its
/// abbreviation table); the units are parsed on demand by `DwarfFbi::iter`
/// or, once and cached, by `DwarfFbi::functions`.
struct DwarfFbi {
  data : DwarfData
  mut scan : DwarfFunctionScan?
}

///|
/// Result of an eager function-boundary scan: the functions recovered from
/// the valid prefix of `.debug_info` plus the diagnostics explaining why the
/// scan stopped early (if it did).
struct DwarfFunctionScan {
  functions : Array[DwarfFunction]
  diagnostics : Array[String]
}

///|
/// The functions recovered by the scan, in `.debug_info` order.
pub fn DwarfFunctionScan::functions(
  self : DwarfFunctionScan,
) -> Array[DwarfFunction] {
  self.functions.copy()
}

///|
/// Warnings and errors reported while scanning; empty when every unit was
/// read successfully.
pub fn DwarfFunctionScan::diagnostics(
  self : DwarfFunctionScan,
) -> Array[String] {
  self.diagnostics.copy()
}

///|
/// `true` when the whole `.debug_info` section was read without errors.
pub fn DwarfFunctionScan::is_complete(self : DwarfFunctionScan) -> Bool {
  self.diagnostics.is_empty()
}

///|
priv struct DwarfUnitSections {
  info : DwarfSectionBuffer
  abbrev : DwarfSectionBuffer
  str : DwarfSectionBuffer?
  line_str : DwarfSectionBuffer?
  str_offsets : DwarfSectionBuffer?
  addr : DwarfSectionBuffer?
  ranges : DwarfSectionBuffer?
  rnglists : DwarfSectionBuffer?
  endian : @bitvec.Endian
}

///|
fn DwarfData::optional_section(
  self : DwarfData,
  section : DwarfSection,
) -> DwarfSectionBuffer? {
  match self.section(section) {
    Ok(buffer) => Some(buffer)
    Err(_) => None
  }
}

///|
/// Collects the sections used by the function-boundary reader. Only
/// `.debug_info` and `.debug_abbrev` are required. Unlike upstream
/// `Fbi.create`, `.debug_str` is optional: it is looked up on demand when a
/// DIE uses `DW_FORM_strp`, and its absence stops the scan at that DIE.
fn DwarfData::unit_sections(
  self : DwarfData,
) -> Result[DwarfUnitSections, String] {
  let info = match self.section(DwarfInfo) {
    Ok(section) => section
    Err(reason) => return Err(reason)
  }
  let abbrev = match self.section(DwarfAbbrev) {
    Ok(section) => section
    Err(reason) => return Err(reason)
  }
  Ok({
    info,
    abbrev,
    str: self.optional_section(DwarfStr),
    line_str: self.optional_section(DwarfLineStr),
    str_offsets: self.optional_section(DwarfStrOffsets),
    addr: self.optional_section(DwarfAddr),
    ranges: self.optional_section(DwarfRanges),
    rnglists: self.optional_section(DwarfRnglists),
    endian: self.endian(),
  })
}

///|
priv enum DwarfUnitStep {
  /// A unit was read; when its `error` is set the reader stops after it.
  DwarfUnitStepParsed(DwarfParsedUnit, Int)
  /// A unit header (or its abbreviation table) could not be read.
  DwarfUnitStepFailed(String, Int)
  DwarfUnitStepDone
}

///|
/// Incremental `.debug_info` unit reader (upstream `read_unit`'s
/// `Sequence.unfold_step`).
priv struct DwarfUnitReader {
  sections : DwarfUnitSections
  mut cursor : DwarfInput
  mut units : Int
  mut finished : Bool
}

///|
fn DwarfUnitReader::new(sections : DwarfUnitSections) -> DwarfUnitReader {
  { sections, cursor: sections.info.input(), units: 0, finished: false, }
}

///|
fn DwarfUnitReader::next(self : DwarfUnitReader) -> DwarfUnitStep {
  if self.finished ||
    self.cursor.remaining() <= 0 ||
    dwarf_remaining_is_zero_padding(self.cursor) {
    self.finished = true
    return DwarfUnitStepDone
  }
  let offset = self.cursor.position()
  let sections = self.sections
  match
    dwarf_parse_unit(
      self.cursor,
      sections.abbrev,
      sections.str,
      sections.line_str,
      sections.str_offsets,
      sections.addr,
      sections.ranges,
      sections.rnglists,
      sections.endian,
    ) {
    Ok(unit) => {
      self.units += 1
      if unit.error is Some(_) {
        self.finished = true
      } else {
        self.cursor = unit.next
      }
      DwarfUnitStepParsed(unit, offset)
    }
    Err(reason) => {
      self.finished = true
      DwarfUnitStepFailed(reason, offset)
    }
  }
}

///|
fn dwarf_stopped_diagnostic(reason : String, offset : Int) -> String {
  "DWARF parser stopped prematurely in the unit at .debug_info offset \{offset}: \{reason}; some symbols may be omitted"
}

///|
fn dwarf_next_unit_diagnostic(reason : String, offset : Int) -> String {
  "failed to move to the next DWARF unit at .debug_info offset \{offset}: \{reason}; some symbols may be omitted"
}

///|
/// Checks what upstream `Fbi.create` checks eagerly: that the first unit
/// header and its abbreviation table can be read.
fn dwarf_check_first_unit(sections : DwarfUnitSections) -> Result[Unit, String] {
  let info = sections.info.input()
  if info.remaining() <= 0 || dwarf_remaining_is_zero_padding(info) {
    return Ok(())
  }
  let endian = sections.endian
  let ((dwarf_size, unit_size), after_size) = match
    info.read_unit_size(endian~) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let cu_end = after_size.position() + unit_size
  let (version, after_version) = match after_size.read_version() {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  match dwarf_read_unit_header(after_version, version, endian, dwarf_size) {
    Ok(DwarfUnsupportedUnit) =>
      match dwarf_skip_to_unit_end(after_size, cu_end) {
        Ok(_) => Ok(())
        Err(reason) => Err(reason)
      }
    Ok(DwarfSupportedUnit(abbrev_offset, _, _)) =>
      match sections.abbrev.offset(abbrev_offset) {
        Ok(buffer) =>
          match DwarfAbbrevTable::read(buffer.input()) {
            Ok(_) => Ok(())
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
/// Eagerly scans every unit of `.debug_info`, keeping the functions
/// recovered before the first failure.
///
/// Like upstream `read_unit`, a malformed DIE stops the scan ("DWARF parser
/// stopped prematurely") and a malformed later unit header stops it at that
/// unit ("failed to move to the next DWARF unit"); in both cases the
/// functions read so far are kept and the reason is recorded in
/// `DwarfFunctionScan::diagnostics`. Missing required sections yield an empty
/// scan with a diagnostic.
pub fn DwarfData::scan_functions(self : DwarfData) -> DwarfFunctionScan {
  let sections = match self.unit_sections() {
    Ok(sections) => sections
    Err(reason) => return { functions: [], diagnostics: [reason], }
  }
  let reader = DwarfUnitReader::new(sections)
  let candidates : Array[DwarfFunctionCandidate] = []
  let die_names : Array[DwarfDieName] = []
  let diagnostics : Array[String] = []
  for ;; {
    match reader.next() {
      DwarfUnitStepParsed(unit, offset) => {
        candidates.push_iter(unit.function_candidates.iter())
        die_names.push_iter(unit.die_names.iter())
        if unit.error is Some(reason) {
          diagnostics.push(dwarf_stopped_diagnostic(reason, offset))
        }
      }
      DwarfUnitStepFailed(reason, offset) =>
        diagnostics.push(
          if reader.units == 0 {
            reason
          } else {
            dwarf_next_unit_diagnostic(reason, offset)
          },
        )
      DwarfUnitStepDone => break
    }
  }
  {
    functions: dwarf_resolve_function_candidates(candidates, die_names),
    diagnostics,
  }
}

///|
/// Eager function-boundary extraction.
///
/// Returns the functions of the valid prefix of `.debug_info` (see
/// `DwarfData::scan_functions`). An error is returned only when the scan
/// failed without recovering any function; use `scan_functions` to observe
/// the diagnostics of a partial scan.
pub fn DwarfData::functions(
  self : DwarfData,
) -> Result[Array[DwarfFunction], String] {
  let scan = self.scan_functions()
  match scan.diagnostics {
    [reason, ..] if scan.functions.is_empty() => Err(reason)
    _ => Ok(scan.functions)
  }
}

///|
/// Lazily enumerates functions unit by unit (upstream `Fbi.functions`
/// sequence).
///
/// Each unit is parsed only when the iterator reaches it. Functions whose
/// names refer to DIEs of units that have not been read yet are yielded
/// once the enumeration ends. When the reader stops on a malformed DIE or
/// unit header, `on_warning` receives the diagnostic and the iterator ends
/// after the functions recovered so far.
pub fn DwarfData::iter_functions(
  self : DwarfData,
  on_warning? : (String) -> Unit = _ => (),
) -> Iter[DwarfFunction] {
  let reader = match self.unit_sections() {
    Ok(sections) => DwarfUnitReader::new(sections)
    Err(reason) => {
      on_warning(reason)
      return Iter::empty()
    }
  }
  let die_names : Array[DwarfDieName] = []
  let deferred : Array[DwarfFunctionCandidate] = []
  let pending : Array[DwarfFunction] = []
  let mut position = 0
  let mut flushed = false
  Iter::new(() => {
    for ;; {
      if position < pending.length() {
        let item = pending[position]
        position += 1
        return Some(item)
      }
      if flushed {
        return None
      }
      pending.clear()
      position = 0
      match reader.next() {
        DwarfUnitStepParsed(unit, offset) => {
          die_names.push_iter(unit.die_names.iter())
          for candidate in unit.function_candidates {
            match candidate.resolve(die_names) {
              Some(function_item) => pending.push(function_item)
              None => deferred.push(candidate)
            }
          }
          if unit.error is Some(reason) {
            on_warning(dwarf_stopped_diagnostic(reason, offset))
          }
        }
        DwarfUnitStepFailed(reason, offset) => {
          on_warning(
            if reader.units == 0 {
              reason
            } else {
              dwarf_next_unit_diagnostic(reason, offset)
            },
          )
          continue
        }
        DwarfUnitStepDone => {
          flushed = true
          pending.push_iter(
            dwarf_resolve_function_candidates(deferred, die_names).iter(),
          )
        }
      }
    }
  })
}

///|
/// Creates a function-boundary reader (upstream `Fbi.create`).
///
/// Fails when `.debug_info` or `.debug_abbrev` is missing or when the first
/// unit header or its abbreviation table cannot be read; nothing else is
/// parsed until the functions are requested. Divergences from upstream:
/// `.debug_str` is optional (resolved on demand), and an empty or
/// zero-padded `.debug_info` yields a reader without functions instead of an
/// error.
pub fn DwarfFbi::create(data : DwarfData) -> Result[DwarfFbi, String] {
  match data.unit_sections() {
    Ok(sections) =>
      match dwarf_check_first_unit(sections) {
        Ok(_) => Ok({ data, scan: None, })
        Err(reason) => Err(reason)
      }
    Err(reason) => Err(reason)
  }
}

///|
fn DwarfFbi::scan(self : DwarfFbi) -> DwarfFunctionScan {
  match self.scan {
    Some(scan) => scan
    None => {
      let scan = self.data.scan_functions()
      self.scan = Some(scan)
      scan
    }
  }
}

///|
/// All named functions of the valid `.debug_info` prefix (eager, cached).
pub fn DwarfFbi::functions(self : DwarfFbi) -> Array[(String, DwarfFunction)] {
  self.scan().functions.map(function_item => {
    (function_item.name(), function_item)
  })
}

///|
/// Lazily enumerates the named functions (see `DwarfData::iter_functions`).
pub fn DwarfFbi::iter(
  self : DwarfFbi,
  on_warning? : (String) -> Unit = _ => (),
) -> Iter[(String, DwarfFunction)] {
  self.data
  .iter_functions(on_warning~)
  .map(function_item => (function_item.name(), function_item))
}

///|
/// Diagnostics of the eager scan used by `DwarfFbi::functions`.
pub fn DwarfFbi::diagnostics(self : DwarfFbi) -> Array[String] {
  self.scan().diagnostics.copy()
}
