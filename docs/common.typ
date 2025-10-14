#import "../src/exports.typ" as fletcher

#let scope = (
  fletcher: fletcher,
  diagram: fletcher.diagram,
  edge: fletcher.edge,
  node: fletcher.node,
  cetz: fletcher.cetz,
)


#let x-target = sys.inputs.at("x-target", default: "pdf")
#let is-md-target = x-target == "md"

#let VERSION = toml("/typst.toml").package.version

#let mute-refs(body) = {
  show ref: none
  body
}

#let frame(it) = {
  if is-md-target {
    html.frame(pad(5mm, scale(150%, reflow: true, it)))
  } else {
    it
  }
}


#let example(code) = {
  let preview = eval(code.text, mode: "markup", scope: scope)

  if is-md-target {
    frame(preview)
    code
  } else {
    grid(
      columns: (1fr, auto),
      gutter: 1em,
      code,
      preview,
    )
  }

}



#let style(body, refs: true) = {


  let label-prefix = "fletcher."

  show ref: it => {
    let target = str(it.target)
    if target.starts-with(label-prefix){ return it }

    let defs = state("tidy-definitions", none).final()


    let symbol = target.split(".").last()
    if defs == none { return raw(symbol) }

    if symbol in defs {
      target += "()"
      symbol += "()"
    }


    
    link(label(label-prefix + target), symbol)
  }

  show heading.where(level: 1): it => {
    if is-md-target {
      html.elem("m1verbatum", "# ")
      it.body
      parbreak()
    } else {
      it
    }
  }

  if refs { body } else { mute-refs(body) }
}