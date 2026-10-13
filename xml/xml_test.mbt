///|
fn signals(text : String, strip~ : Bool = false) -> Array[@xml.Signal] raise {
  let input = @xml.Input::from_string(text, strip~)
  let out = []
  while !input.eoi() {
    out.push(input.input())
  }
  out
}

///|
fn show_signals(text : String, strip~ : Bool = false) -> String raise {
  let buf = StringBuilder()
  for s in signals(text, strip~) {
    match s {
      Dtd(None) => buf.write_string("dtd\n")
      Dtd(Some(d)) => buf.write_string("dtd \{d}\n")
      ElStart(tag) => {
        buf.write_string("start \{tag.name}")
        for a in tag.attrs {
          buf.write_string(" \{a.name}=\{a.value}")
        }
        buf.write_string("\n")
      }
      ElEnd => buf.write_string("end\n")
      Data(d) => buf.write_string("data \{repr(d)}\n")
    }
  }
  buf.to_string()
}

///|
test "elements, attributes and data" {
  inspect(
    show_signals(
      (
        #|<?xml version="1.0" encoding="UTF-8"?>
        #|<!-- a comment -->
        #|<a x="1" y='two'>hello <b/>world</a>
      ),
    ),
    content=(
      #|dtd
      #|start a x=1 y=two
      #|data "hello "
      #|start b
      #|end
      #|data "world"
      #|end
      #|
    ),
  )
}

///|
test "strip removes insignificant white space" {
  let doc =
    #|<list>
    #|  <item>  some
    #|     text  </item>
    #|  <item/>
    #|</list>
  inspect(
    show_signals(doc, strip=true),
    content=(
      #|dtd
      #|start list
      #|start item
      #|data "some text"
      #|end
      #|start item
      #|end
      #|end
      #|
    ),
  )
  inspect(
    show_signals(doc),
    content=(
      #|dtd
      #|start list
      #|data "\n  "
      #|start item
      #|data "  some\n     text  "
      #|end
      #|data "\n  "
      #|start item
      #|end
      #|data "\n"
      #|end
      #|
    ),
  )
}

///|
test "entities, character references, CDATA and comments" {
  inspect(
    show_signals(
      "<a t=\"&lt;&amp;&#65;&#x42;\n.\">&quot;x&apos; &gt; <![CDATA[<raw> & ]]><!-- skip -->tail<?pi skip?>!</a>",
    ),
    content=(
      #|dtd
      #|start a t=<&AB .
      #|data "\"x' > <raw> & tail!"
      #|end
      #|
    ),
  )
  let input = @xml.Input::from_string("<a>&custom;</a>", entity=name => {
    if name == "custom" {
      Some("CUSTOM")
    } else {
      None
    }
  })
  assert_eq(input.input(), Dtd(None))
  let _ = input.input()
  assert_eq(input.input(), Data("CUSTOM"))
}

///|
test "doctype is reported verbatim" {
  inspect(
    show_signals(
      "<!DOCTYPE note [<!ELEMENT note (#PCDATA)> <!ATTLIST x y \"]>\">]>\n<note/>",
    ),
    content=(
      #|dtd <!DOCTYPE note [<!ELEMENT note (#PCDATA)> <!ATTLIST x y "]>">]>
      #|start note
      #|end
      #|
    ),
  )
}

///|
test "namespaces" {
  inspect(
    show_signals(
      "<r xmlns=\"http://d\" xmlns:p=\"http://p\"><p:e p:a=\"1\" b=\"2\" xml:lang=\"en\"/><e/></r>",
    ),
    content=(
      #|dtd
      #|start http://d:r http://www.w3.org/2000/xmlns/:xmlns=http://d http://www.w3.org/2000/xmlns/:p=http://p
      #|start http://p:e http://p:a=1 b=2 http://www.w3.org/XML/1998/namespace:lang=en
      #|end
      #|start http://d:e
      #|end
      #|end
      #|
    ),
  )
  let input = @xml.Input::from_string("<q:a/>", ns=p => {
    if p == "q" {
      Some("urn:q")
    } else {
      None
    }
  })
  let _ = input.input()
  guard input.input() is ElStart(tag) else { fail("expected a tag") }
  assert_eq(tag.name, { uri: "urn:q", local_name: "a", })
}

///|
fn error_of(text : String) -> String {
  try signals(text) catch {
    e => "\{e}"
  } noraise {
    _ => "ok"
  }
}

///|
test "errors carry positions" {
  inspect(
    error_of("<a></b>"),
    content=(
      #|1:8: expected the end tag of `a'
    ),
  )
  inspect(
    error_of("<a>"),
    content=(
      #|1:4: unexpected end of input inside an element
    ),
  )
  inspect(
    error_of("<a x=1/>"),
    content=(
      #|1:7: expected a quoted attribute value
    ),
  )
  inspect(
    error_of("<a>&nope;</a>"),
    content=(
      #|1:10: unknown entity `nope'
    ),
  )
  inspect(
    error_of("<a/><b/>"),
    content=(
      #|1:5: unexpected content after the root element
    ),
  )
  inspect(
    error_of(""),
    content=(
      #|1:1: expected the root element
    ),
  )
  inspect(
    error_of("<a x='1' x='2'/>"),
    content=(
      #|1:15: duplicate attribute `x'
    ),
  )
  inspect(
    error_of("<p:a/>"),
    content=(
      #|1:7: unknown namespace prefix `p'
    ),
  )
  inspect(
    error_of("<a>\n  <b>\n</a>"),
    content=(
      #|3:5: expected the end tag of `b'
    ),
  )
}

///|
test "document trees" {
  let doc = @xml.parse_document(
    (
      #|<patternlist>
      #|  <pattern>
      #|    <data>0x55 0x89e5</data>
      #|    <funcstart after="defined"/>
      #|  </pattern>
      #|</patternlist>
    ),
    strip=true,
  )
  assert_eq(doc.dtd, None)
  let patterns = doc.root.elements("pattern")
  assert_eq(patterns.length(), 1)
  assert_eq(patterns[0].elements("data")[0].text(), "0x55 0x89e5")
  assert_eq(patterns[0].elements("funcstart")[0].attr("after"), Some("defined"))
  inspect(
    doc.root.to_string(),
    content=(
      #|<patternlist><pattern><data>0x55 0x89e5</data><funcstart after="defined"/></pattern></patternlist>
    ),
  )
  // round trip
  assert_eq(@xml.parse_document(doc.root.to_string()).root, doc.root)
}

///|
test "bytes input and line ends" {
  let input = @xml.Input::from_bytes(b"\xef\xbb\xbf<a>x\r\ny\ry</a>")
  let _ = input.input()
  let _ = input.input()
  assert_eq(input.input(), Data("x\ny\ny"))
  assert_eq(input.input(), ElEnd)
  assert_true(input.eoi())
  let input = @xml.Input::from_string("<a>\n  <b>t</b></a>")
  let _ = input.input()
  let _ = input.input()
  let _ = input.input()
  let _ = input.input()
  assert_eq(input.pos(), { line: 2, col: 3, })
}
