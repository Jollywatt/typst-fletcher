#import "@preview/tidy:0.4.3"
#import "../src/exports.typ" as fletcher

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
				gutter: 27mm,
				// label-sep: 6pt,
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


#let module-docs(name) = {
  [== #raw(name)]
  
  let path = "/src/" + name + ".typ"
  let docs = tidy.parse-module(read(path),
    label-prefix: "fletcher.",
    scope: (
      cetz: fletcher.cetz,
      fletcher: fletcher
    ),
  )
  tidy.show-module(
    docs,
    style: tidy.styles.default
  )
}

#show link: it => {
  set text(blue.darken(50%), font: "CMU Bright")
  strong(it)
}

#show raw.where(lang: "typ"): it => block(
  it,
  stroke: (left: rgb("#4b6ac690")),
  width: 100%,
  outset: .8em,
  radius: 1em,
)


#show heading: it => {
  let size = (30pt, 25pt, 20pt, 15pt).at(it.level, default: 10pt)
  text(size, it)
}

#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  it
  line(length: 100%)
}


#import "common.typ": style
#show: style.with(refs: true)


= Manual <manual>

#{
  set heading(offset: 1)
  include "sections/1-intro.typ"
  include "sections/2-diagrams.typ"
  include "sections/3-nodes.typ"
  include "sections/4-edges.typ"
  include "sections/5-marks.typ"
  include "sections/6-cetz.typ"
}

= Function Reference <func-ref>

#module-docs("nodes")
#module-docs("edges")
#module-docs("flexigrid")
#module-docs("paths")