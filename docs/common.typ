#import "../src/exports.typ" as fletcher
#import fletcher: diagram, node, edge

#let scope = (
  fletcher: fletcher,
  ..dictionary(fletcher),

  shape-demo: (shape, tint) => [
    #diagram(
    	node((0,0), raw(shape), shape: shape),
    	node-stroke: tint,
    	node-fill: tint.lighten(90%),
    )
    #let code = {
      "node(.., shape: "
      repr(shape)
      ", "
      fletcher.shapes.NODE_SHAPES.at(shape).pairs()
        .filter(((k, v)) => k != "draw")
        .map(((k, v)) => k + ": " + repr(v))
        .join(", ")
      ")"
    }
    
    #raw(code, lang: "typc")
  ]
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


#let show-ref(it) = {

  if it.element == none {
    highlight(raw(repr(it.target)))
    metadata((invalid-ref: str(it.target)))

  } else if it.element.func() == metadata and "entity" in it.element.value {
    show: link.with(it.element.location())
    let (entity, ..info) = it.element.value
    if entity == "function" {
      raw(info.function + "()")

    } else if entity == "argument" {
      if state("current-function").get() == info.function {
        raw(info.argument)
      } else {
        raw(info.function + "." + info.argument)
      }

    } else {
      panic("unknown ref element", it.element)
    }

  } else if it.element.func() == heading {
    let body = (
      if it.supplement == auto { it.element.body }
      else { it.supplement }
    )
    link(it.target, body)

  } else {
    panic(it)
  }


}


#let style(body, refs: true) = {

  show ref: show-ref

  show heading.where(level: 1): it => {
    if is-md-target {
      html.elem("m1verbatum", "# ")
      it.body
      parbreak()
    } else {
      it
    }
  }

  set raw(lang: "typc")

  if refs { body } else { mute-refs(body) }
}