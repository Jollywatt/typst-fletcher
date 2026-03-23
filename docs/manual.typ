#import "@preview/tidy:0.4.3"
#import "../src/exports.typ" as fletcher

#import "common.typ"

#let VERSION = toml("/typst.toml").package.version


// cover page
#v(10%)

#align(center)[
	#stack(
		spacing: 17pt,
		{
      import fletcher: diagram, node, edge 
			set text(1.3em)
			diagram(
				spacing: 27mm,
				node((0,1), $A$),
				node((1,1), $B$),
				edge((0,1), (1,1), $f$, ">>->", stroke: 1pt),
			)
		},
		text(3.2em, emph[fletcher]),
		[_(noun) a maker of arrows_],
	)

	#v(30pt)

	A #link("https://typst.app/")[Typst] package for diagrams with lots of arrows,
	built on top of #link("https://cetz-package.github.io")[CeTZ].

	#emph[
	Commutative diagrams,
	flow charts,
	state machines,
	block diagrams...
	]

	#link("https://github.com/Jollywatt/typst-fletcher")[`github.com/Jollywatt/typst-fletcher`]

	*Version #VERSION*
]

#v(1fr)


#columns(2)[
  #show heading: it => align(center, box(width: 100%, it)) + v(.8em)
	#outline(
		title: [Manual],
		target: selector(heading)
      .after(<manual>, inclusive: false)
      .before(<func-ref>, inclusive: false),
	)
	#colbreak()
	#outline(
		title: [Function Reference],
		target: selector(heading).after(<func-ref>, inclusive: false),
    depth: 3,
	)

]

#v(1fr)


#let show-type(type) = { 
  import tidy.styles.default: colors, default-type-color
  h(2pt)
  let clr = colors.at(type, default: colors.at("default", default: default-type-color))
  box(outset: 2pt, fill: clr, radius: 2pt, raw(type, lang: none))
  h(2pt)
}

#let show-example(code) = {
  let result = eval(code.text, mode: "markup", scope: common.scope)
  let code = raw(code.text, lang: "typ")

  grid(
    columns: (1fr, auto),
    gutter: 1em,
    code,
    result,
  )
}

#let rich-ref(id, ..args) = [
  #metadata(args.named())
  #label(id)
]


#let show-function(fn) = {
  heading(raw(fn.name + "()"), level: 3)
  rich-ref(fn.name, entity: "function", function: fn.name)


  eval(fn.description, mode: "markup", scope: common.scope)

  for (arg, info) in fn.args {
    if info.description == "" { continue }
    let first-line = {
      strong(raw(arg))
      rich-ref(
        fn.name + "." + arg,
        entity: "argument",
        function: fn.name,
        argument: arg,
      )
      if "types" in info {
        h(0.5em)
        info.types.map(show-type).join(text(0.8em)[ or ])
      }
      if "default" in info {
        text(0.8em)[ default ]
        raw(info.default)
      }
      h(1fr)
      link(label(fn.name), text(gray, $arrow.tl$))
    }

    block(
      inset: 10pt,
      {
        block(
          outset: 10pt,
          width: 100%,
          radius: 10pt,
          stroke: (top: .6pt + gray),
          first-line,
        )
        show raw.where(lang: "example"): show-example
        eval(info.description, mode: "markup", scope: common.scope)
      },
    )
    v(1em)
  }
}

#let module-docs(name, sort-functions: it => 0) = {
  [== Module #raw(name)]
  
  let path = "/src/" + name + ".typ"
  let docs = tidy.parse-module(read(path),
    label-prefix: "fletcher.",
    scope: common.scope,
  )
  show raw.where(block: false): set raw(lang: "typc")

  show raw.where(lang: "svg"): it => common.frame(eval(it.text, scope: common.scope))

  // tidy.show-module(
  //   docs,
  //   style: dictionary(tidy.styles.default) + (
  //     show-reference: (label, name, style-args: none) => {
  //       name = name.split(".").last()
  //       link(label, raw(name, lang: none))
  //     },
  //     show-example: (..args) => {
  //       tidy.styles.default.show-example(..args, ratio: 1.5)
  //     }
  //   ),
  //   ..args,
  // )
  
  for fn in docs.functions.sorted(key: sort-functions) {
    show-function(fn)
  }
}

#show link: it => {
  set text(blue.darken(50%))//, font: "CMU Bright")
  strong(it)
}


#show heading: it => {
  let size = (30pt, 25pt, 20pt, 15pt).at(it.level, default: 10pt)
  text(size, it)
}

#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  it
  line(length: 100%)
}

// #set heading(numbering: "1")

// #import "common.typ": style
// #show: style.with(refs: true)
// 
#show ref: it => {

  if it.element == none { return [NOTHING REFERENCE] }

  if it.element.func() == metadata and "entity" in it.element.value {
    let (entity, ..ref) = it.element.value
    let body
    if entity == "function" {
      body = raw(ref.function + "()")
    } else if entity == "argument" {
      body = raw(ref.argument)
    } else {
      panic("what is this?", it.element)
    }
    return link(it.element.location(), body)
  }

  if it.element.func() == heading {
    return link(it.target, it.element.body)
  }

  it

}


= Manual <manual>

#{
  set heading(offset: 1)
  // include "sections/1-intro.typ"
  // include "sections/2-diagrams.typ"
  // include "sections/3-nodes.typ"
  // include "sections/4-edges.typ"
  // include "sections/5-marks.typ"
  // include "sections/6-cetz.typ"
}

= Function Reference <func-ref>

#module-docs("diagram")
#module-docs("nodes")
#module-docs("edges")
#module-docs("flexigrid")
#module-docs("paths")
#module-docs("marks")
#module-docs("shapes", sort-functions: info => {
  fletcher.shapes.NODE_SHAPES.keys().position(name => name == info.name)
})

