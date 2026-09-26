// The `byteweight` plugin (upstream `Byteweight_main`): identifies
// function starts with the byteweight signatures.

///|
/// The name of the plugin.
pub let name : String = "byteweight"

///|
let doc : String =
  #|
  #|# DESCRIPTION
  #|
  #|Identifies function starts using a predefined sets of function start
  #|signatures. Each signature is a sequence of bytes equipped with a
  #|sample probability of occuring it as a function start. The input
  #|memory is scanned, and for each byte that is not yet classified as a
  #|function start the longest sequence of bytes is searched in the
  #|signatures. If one is found, then the $(b,threshold) parameter defines
  #|the decision procedure. If it is a value below $(b,1.0) then the
  #|sequence of bytes will be classified as a function start if the the
  #|associated probability is higher than the specified threshold.  If the
  #|threshold is greater or equal than 1.0, then the sequence of bytes
  #|will be classified as a function start if the Bayes factor of the two
  #|competing hypothesis is greater than the specified threshold.
  #|
  #|This plugin is a partial implementation of the BYTEWEIGHT algorithm as
  #|described in [1]. Only the byte level matching is implemented.
  #|
  #|[1]: Bao, Tiffany, et al. "Byteweight: Learning to recognize
  #|functions in binary code." 23rd USENIX Security Symposium (USENIX
  #|Security 14). 2014.
  #|
  #|# SEE ALSO
  #|
  #|$(b,bap-byteweight)(1), $(b,bap-plugin-read-symbols)(1)
  #|

///|
let reporter : @main_event.MainLogReporter = @main_event.MainLogReporter::create(
  section=name,
)

///|
/// The function starts found in the memory regions with the signatures
/// (upstream `compute_root_table`).
pub fn find_roots(
  sigs : @bw.Byteweight,
  memory : Array[@memory.Memory],
  min_length? : Int = 8,
  max_length? : Int = 16,
  threshold? : Double = 10.0,
) -> Array[UInt64] {
  let roots = []
  for mem in memory {
    let found = if threshold >= 1.0 {
      sigs.find_using_bayes_factor(min_length~, max_length~, threshold, mem)
    } else {
      sigs.find_using_threshold(min_length~, max_length~, threshold, mem)
    }
    for addr in found {
      if !roots.contains(addr) {
        roots.push(addr)
      }
    }
  }
  roots.sort()
  roots
}

///|
/// Looks up the signatures of the target; a missing database or entry is
/// reported and yields no signatures.
fn lookup_signatures(
  target : @core_theory.Target,
  path : String?,
  compiler : String?,
) -> @bw.Byteweight? {
  let paths = match path {
    Some(p) => [p]
    None => []
  }
  let compiler = compiler.map(c => @core_theory.Compiler::create(c))
  match @bw.Byteweight::signature_data().lookup(target, paths~, compiler?) {
    Ok(sigs) => Some(sigs)
    Err(ByteweightSignatureNoSignatures) => {
      reporter.warning(message="The signatures database is empty.")
      reporter.info(
        message="use `bap-byteweight update' to install the signatures",
      )
      None
    }
    Err(ByteweightSignatureNoEntry(s)) => {
      reporter.info(message="no signatures for \{s}")
      reporter.info(message="use `bap-byteweight train' to create signatures")
      None
    }
    Err(err) => {
      reporter.error(
        message="the signatures database is broken: \{err.to_string()}",
      )
      None
    }
  }
}

///|
/// Enables the byteweight root provider of the `disassemble` command
/// (upstream `enable`).
pub fn enable(
  sigs? : String,
  min_length? : Int = 8,
  max_length? : Int = 16,
  threshold? : Double = 10.0,
  compiler? : String,
) -> Unit {
  @disassemble.register_root_provider(name, input => {
    let memory = input.code().entries().map(e => e.0)
    if memory.is_empty() {
      return Ok([])
    }
    match lookup_signatures(input.target(), sigs, compiler) {
      None => Ok([])
      Some(table) =>
        Ok(find_roots(table, memory, min_length~, max_length~, threshold~))
    }
  })
}

///|
/// Declares the `byteweight` plugin (the `--byteweight-*` options) in the
/// `bap_main` framework. Does nothing if it is already registered.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["roots"],
    doc="identifies function starts using byteweight signatures",
    () => {
      @bap_main.Extension::documentation(doc)
      let min_length = @bap_main.Configuration::parameter(
        doc="The minimum length of a word, that could identify a function start. Any signatures that are below that length, will not be considered, affect prior probabilities, etc.",
        @bap_main.Type::int().with_default(8),
        "min-length",
      )
      let max_length = @bap_main.Configuration::parameter(
        doc="The maximum length of a word, that could identify a function start. Any signatures that are greater than that length, will not be considered, affect prior probabilities, etc.",
        aliases=["length"],
        @bap_main.Type::int().with_default(16),
        "max-length",
      )
      let threshold = @bap_main.Configuration::parameter(
        doc="If greater than 1.0 then it is the Bayes factor, otherwise it is a probability.",
        @bap_main.Type::float().with_default(10.0),
        "threshold",
      )
      let sigsfile = @bap_main.Configuration::parameter(
        doc="Path to the signature file",
        aliases=["signatures"],
        @bap_main.Type::some(@bap_main.Type::non_dir_file()),
        "sigs",
      )
      let compiler = @bap_main.Configuration::parameter(
        doc="Assume the input file is compiled by $(docv)",
        @bap_main.Type::some(@bap_main.Type::string()),
        "compiler",
      )
      let enabled = @bap_main.Configuration::parameter(
        doc="Enable/disable byteweight (off by default)",
        as_flag=true,
        @bap_main.Type::bool(),
        "enabled",
      )
      @bap_main.Extension::register(provides=["roots"], ctxt => {
        if ctxt.get(enabled) {
          enable(
            sigs?=ctxt.get(sigsfile),
            min_length=ctxt.get(min_length),
            max_length=ctxt.get(max_length),
            threshold=ctxt.get(threshold),
            compiler?=ctxt.get(compiler),
          )
        } else {
          @disassemble.remove_root_provider(name)
        }
      })
    },
  )
}
