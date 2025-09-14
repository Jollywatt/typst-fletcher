#import "../src/exports.typ" as fletcher: node, edge

#let VERSION = toml("/typst.toml").package.version

#show link: underline


#v(10%)

#align(center)[
	#stack(
		spacing: 17pt,
		{
			set text(1.3em)
			fletcher.diagram(
				gutter: 27mm,
				label-sep: 6pt,
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
  #show heading: it => align(center, box(width: 100%, it))
	#outline(
		title: [Manual],
		target: selector(heading)
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


#pagebreak()