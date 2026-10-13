// The `specification` command (upstream `Specification_main`): prints the
// Ogre specification of a binary.

///|
/// The name of the plugin.
pub let plugin_name : String = "specification"

///|
let doc : String =
  #|
  #|# DESCRIPTION
  #|
  #|Displays information about the binary. The information is printed in
  #|the OGRE format.
  #|

///|
/// The output format of the specification.
pub(all) enum SpecFormat {
  Sexp
  Yaml
} derive(Eq, Debug)

///|
pub extend SpecFormat with Eq::{equal, not_equal}

///|
pub extend SpecFormat with Debug::{to_repr}

///|
/// A reason why the command failed (upstream `problem`).
pub(all) suberror SpecificationError {
  UnknownLoader(String)
  LoaderError(String)
} derive(Debug)

///|
pub extend SpecificationError with Debug::{to_repr}

///|
pub fn SpecificationError::to_string(self : SpecificationError) -> String {
  match self {
    UnknownLoader(name) =>
      "The loader `\{name}' is not registers, known loaders are: \{@image.available_backends().join(", ")}."
    LoaderError(err) => "Failed to load the binary: \{err}"
  }
}

///|
/// Renders the specification in the format.
pub fn render(format : SpecFormat, spec : @ogre.Doc) -> String {
  match format {
    Yaml => spec.to_yaml() + "\n"
    Sexp => spec.to_string() + "\n"
  }
}

///|
/// Loads the specification of the `input` file with the `loader`
/// (upstream `Image.find_loader` and `from_file`). The default loader
/// `llvm` of upstream BAP is not available; it selects the loader by the
/// file name and contents instead. Returns `None` if the loader does not
/// recognize the file.
pub fn load(
  input : String,
  loader~ : String = "llvm",
) -> @ogre.Doc? raise SpecificationError {
  @image.register_builtin_backends() |> ignore
  let data = match (@bap_main.file_system().read_file)(input) {
    Some(data) => data
    None => raise LoaderError("unable to read the file \{input}")
  }
  match @image.find_loader(loader) {
    Some(l) =>
      match l.from_data(data) {
        Ok(spec) => spec
        Err(err) => raise LoaderError(err)
      }
    None => {
      let loaded = if loader == "llvm" {
        match @image.Image::of_bytes_for_filename(data, filename=input) {
          Ok(r) => Ok(r)
          Err(_) =>
            match @image.Image::of_bytes(data, backend="llvm") {
              Ok(r) => Ok(r)
              Err(_) => @image.Image::of_bytes(data)
            }
        }
      } else if @image.available_backends().contains(loader) {
        @image.Image::of_bytes(data, backend=loader)
      } else {
        raise UnknownLoader(loader)
      }
      match loaded {
        Ok((image, _)) => Some(image.spec())
        Err(err) => raise LoaderError(err)
      }
    }
  }
}

///|
let printer_registered : Ref[Bool] = Ref(false)

///|
/// Declares the `specification` plugin and command in the `bap_main`
/// framework. Does nothing if it is already registered.
pub fn declare_plugin(
  out~ : (String) -> Unit = s => println(s.trim_end(chars="\n")),
) -> Unit raise {
  if @bap_main.registered_plugins().contains(plugin_name) {
    return
  }
  if !printer_registered.val {
    printer_registered.val = true
    @bap_main.register_error_printer(err => {
      match err {
        UnknownLoader(name) => Some(UnknownLoader(name).to_string())
        LoaderError(err) => Some(LoaderError(err).to_string())
        _ => None
      }
    })
  }
  @bap_main.register_plugin(
    plugin_name,
    provides=["command", "specification", "ogre"],
    doc="provides the specification command",
    () => {
      let input = @bap_main.Command::argument(
        doc="The input file",
        @bap_main.Type::string().with_default("a.out").rename("FILE"),
      )
      let format = @bap_main.Command::parameter(
        doc="The output format",
        aliases=["o"],
        @bap_main.Type::enumeration([("sexp", Sexp), ("yaml", Yaml)]),
        "format",
      )
      let loader = @bap_main.Command::parameter(
        doc="Use the specified loader. Use the loader `raw' to load unstructured files",
        @bap_main.Type::string().with_default("llvm"),
        "loader",
      )
      @bap_main.Command::register(
        doc~,
        requires=["loader"],
        "specification",
        @bap_main.Command::args().add(format).add(input).add(loader),
        format => {
          input => {
            loader => {
              _ctxt => {
                match load(input, loader~) {
                  Some(spec) => out(render(format, spec))
                  None => ()
                }
              }
            }
          }
        },
      )
      @bap_main.Extension::register(
        doc="provides the specification command",
        provides=["command", "specification", "ogre"],
        _ => (),
      )
    },
  )
}
