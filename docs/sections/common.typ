#import "../../src/exports.typ" as fletcher
#import "@preview/jumble:0.0.1"

#let hash(it) = jumble.bytes-to-hex(jumble.md5(repr(it)))

#let VERSION = toml("/typst.toml").package.version

#let preview-mdx = false
#let target-mdx = "export-mdx" in sys.inputs

#let parse-ref(text) = {
  text
}

#let to-md(it) = {
  if repr(it.func()) == "sequence" {
    it.children.map(to-md).join().replace(regex("  +"), " ")

  } else if it.func() == heading {
    "#"*it.depth + " " + to-md(it.body)
    "\n"

  } else if it.func() == parbreak {
    "\n\n"

  } else if repr(it.func()) == "space" {
    " "

  } else if it.func() == text {
    it.text

  } else if it.func() == emph {
    "_" + to-md(it.body) + "_"

  } else if it.func() == metadata {
    if "example" in it.value {
      "<Example id=" + repr(it.value.id) + ">\n```typ\n"
      it.value.example.text
      "\n```\n</Example>"
    } else if "asset" in it.value {
      "<Asset id=" + repr(hash(it.value.asset)) + "/>"
    }

  } else if it.func() == raw {
    if it.fields().at("block", default: false) {
      "\n```" + it.lang + "\n" + it.text + "\n```\n"
    } else {
      "`" + it.text + "`"
    }

  } else if it.func() == ref {
    "<Ref symbol={" + repr(str(it.target)) + "}/>"

  } else {
    // panic(it.func())
    // repr(it)
    "<!-- SKIPPED " + repr(it.func()) + " -->\n"
  }
}

#let mute-refs(body) = {
  show ref: none
  body
}

#let extract-svg-assets(body) = context {
  set page(width: auto, height: auto, margin: 1em)
  place(hide(mute-refs(body)))
  query(<svg-asset>)
    .map(it => [#it.value.asset #metadata(it.value.id) <asset-id>])
    .intersperse(pagebreak()).join()
}


#let svg-asset(it) = [
  #it
  #metadata((asset: it, id: hash(it))) <svg-asset>
]

#let example(code) = {
  let preview = eval(code.text, mode: "markup", scope: (
    fletcher: fletcher,
    diagram: fletcher.diagram,
    node: fletcher.node,
    edge: fletcher.edge,
  ))

  grid(
    columns: (1fr, auto),
    gutter: 1em,
    code,
    preview,
  )

  [#metadata((asset: preview, example: code, id: hash(preview))) <svg-asset>]

}

#let style(body) = {

  if "export-svg-assets" in sys.inputs {
    return extract-svg-assets(body)
  }

  if target-mdx {
    return [
      #show ref: none
      #body #metadata(to-md(body)) <mdx>
    ]
  }

  if preview-mdx and not target-mdx {
    return raw(to-md(body), lang: "md")
  }

  

  // styles

  show raw.where(lang: "typ"): it => block(
    it,
    stroke: (left: rgb("#4b6ac690")),
    width: 100%,
    outset: .8em,
    radius: 1em,
  )

  // set heading(numbering: "1.")

  show heading: it => {
    let size = (30pt, 25pt, 20pt, 15pt).at(it.level, default: 10pt)
    text(size, it)
  }

  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    it
    line(length: 100%)
  }

  let label-prefix = "fletcher."

  show ref: it => {
    let target = str(it.target)
    if target.starts-with(label-prefix){ return it }

    if target-mdx or preview-mdx { return }

    let defs = state("tidy-definitions", none).final()


    let symbol = target.split(".").last()
    if defs == none { return raw(symbol) }

    if symbol in defs {
      target += "()"
      symbol += "()"
    }


    
    link(label(label-prefix + target), symbol)
  }
  body

}