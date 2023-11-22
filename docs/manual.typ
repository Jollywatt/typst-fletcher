#import "@preview/tidy:0.1.0"
#import "/src/exports.typ": *
#import "/src/marks.typ": parse-arrow-shorthand

#set raw(lang: "typc")
#set page(numbering: "1")
#show link: set text(blue)

#let scope = (
	arrow-diagrams: arrow-diagrams,
	arrow-diagram: arrow-diagram,
	node: node,
	conn: conn,
	parse-arrow-shorthand: parse-arrow-shorthand,
	cetz: arrow-diagrams.cetz,
)
#let show-module(path) = {
	show heading.where(level: 3): it => {
		align(center, line(length: 100%, stroke: black.lighten(70%)))
		block(text(1.3em, raw(it.body.text + "()")))
	}
	tidy.show-module(
		tidy.parse-module(
			read(path),
			scope: scope,
		),
		show-outline: false,
	)
}

#v(.2fr)

#align(center)[
	#arrow-diagram(
		spacing: 2.3cm,
		node((0,1), $A$),
		node((1,1), $B$),
		conn((0,1), (1,1), $f$, ">>->"),
	)

	#text(2em, strong(`fletcher`)) \
	_(noun) a maker of arrows_

	A #link("https://typst.app/")[Typst] package for drawing commutative diagrams,
	built on top of #link("https://github.com/johannes-wolf/cetz")[CeTZ].

	#link("https://github.com/Jollywatt/typst-fletcher")

	Version #toml("/typst.toml").package.version *(not yet stable)*
]

#v(1fr)

#outline(indent: 1em, target:
	heading.where(level: 1)
	.or(heading.where(level: 2))
	.or(heading.where(level: 3)),
)

#v(1fr)


#show heading.where(level: 1): it => pagebreak(weak: true) + it

= Examples

#let code-example(src) = (
	{
		set text(.85em)
		box(src) // box to prevent pagebreaks
	},
	eval(
		src.text,
		mode: "markup",
		scope: scope
	),
)

#table(
	columns: (2fr, 1fr),
	align: (horizon, left),
	inset: 10pt,

	..code-example(```typ
	#arrow-diagram(cell-size: 15mm, {
		let (src, img, quo) = ((0, 1), (1, 1), (0, 0))
		node(src, $G$)
		node(img, $im f$)
		node(quo, $G slash ker(f)$)
		conn(src, img, $f$, "->")
		conn(quo, img, $tilde(f)$, "hook-->", label-side: right)
		conn(src, quo, $pi$, "->>")
	})
	```),

	..code-example(```typ
	An equation $f: A -> B$, and \
	a diagram #arrow-diagram(
		node-pad: 4pt,
		node((0,0), $A$),
		conn((0,0), (1,0), text(0.8em, $f$), "->", label-sep: 1pt),
		node((1,0), $B$),
	).
	```),

	..code-example(```typ
	#arrow-diagram(
		spacing: 2cm,
		node((0,0), $cal(A)$),
		node((1,0), $cal(B)$),
		conn((0,0), (1,0), $F$, "->", bend: +35deg),
		conn((0,0), (1,0), $G$, "->", bend: -35deg),
		conn((.5,+.21), (.5,-.21), $alpha$, "=>"),
	)
	```),
)

// #grid(
// 	spacing: 2em,
// 	columns: (1fr, 1fr),
// 	..(
// 		arrow-diagram(
// 			// debug: 3,
// 			spacing: 5em,
// 			node((0,0), $S a$),
// 			node((0,1), $T b$),
// 			node((1,0), $S a'$),
// 			node((1,1), $T b'$),
// 			conn((0,0), (0,1), $f$, "hook->>", label-side: left),
// 			conn((1,0), (1,1), $f'$, "<-|", label-anchor: "center", label-sep: 0pt),
// 			conn((0,0), (1,0), $α$, extrude: (-4,0,4), label-side: right),
// 			conn((0,1), (1,1), $γ$, bend: 20deg, "->"),
// 			conn((0,1), (1,1), $β$, bend: -20deg, "->"),
// 		),

// 	).map(x => align(center, x))
// )

$
#arrow-diagram(
	cell-size: 1cm,
	node-pad: 1.5em,
	spacing: 17mm,
	debug: 0,
	node-defocus: 0.1,
	node((0,2), $pi_1(X sect Y)$),
	node((0,1), $pi_1(X)$),
	node((1,2), $pi_1(Y)$),
	node((1,1), $pi_1(X) ast.op_(pi_1(X sect Y)) pi_1(X)$),
	conn((0,2), (0,1), $i_2$, "->", extrude: (-1.5,1.5)),
	conn((0,2), (1,2), $i_1$, "hook->"),
	conn((1,2), (2,0), $j_2$, "<->", bend: 20deg, extrude: (-1.5,1.5)),
	conn((0,1), (2,0), $j_1$, "->>", bend: -15deg, dash: "dotted"),
	conn((0,1), (1,1), "hook->>", dash: "dashed"),
	conn((1,2), (1,1), "|->"),
	node((2,0), $pi_1(X union Y)$),
	conn((1,1), (2,0), $k$, "<-->", label-sep: 0pt, paint: green, thickness: 1pt),
)
$

#arrow-diagram(
	cell-size: 3cm,
	node-defocus: 0,
	node-pad: 10pt,
{
	let cube-vertices = ((0,0,0), (0,0,1), (0,1,0), (0,1,1), (1,0,0), (1,0,1), (1,1,0), (1,1,1))
	let proj((x, y, z)) = (x + z*(0.4 - 0.1*x), y + z*(0.4 - 0.1*y))
	for i in range(8) {
		let to = cube-vertices.at(i)
		node(proj(to), [#to])
		for j in range(i) {
			let from = cube-vertices.at(j)
			// test for adjancency
			if from.zip(to).map(((i, j) ) => int(i == j)).sum() == 2 {
				conn(proj(from), proj(to), "->", crossing: to.at(2) == 0)
			}
		}
	}
	conn(proj((1,1,1)), (2, 0.8), dash: "dotted")
	conn(proj((1,0,1)), (2, 0.8), dash: "dotted")
	node((2, 0.8), "fractional coords")
})
#arrow-diagram(
	node-stroke: black + 0.5pt,
	node-fill: blue.lighten(90%),
	spacing: (15mm, 8mm),
	node((0,0), [1]),
	node((1,0), [2], shape: "circle"),
	node((2,1), [3], shape: "circle"),
	node((2,-1), [3'], shape: "circle"),
	conn((0,0), (1,0), "->"),
	conn((1,0), (2,+1), "->", bend: -15deg),
	conn((1,0), (2,-1), "->", bend: +15deg),
	conn((2,-1), (2,-1), "->", bend: +130deg),

)


= Details


== Elastic coordinates

Diagrams are laid out on a flexible coordinate grid, which stretches to fit content like a table.
When a node is placed, the rows and columns grow to accommodate the node's size.

This can be seen more clearly with a coordinate grid (`debug: 1`) and no padding between cells:


#stack(
	dir: ltr,
	spacing: 1fr, 
	..code-example(```typ
	#let b(c, w, h) = box(fill: c.lighten(50%), width: w, height: h)
	#arrow-diagram(
		debug: 1,
		spacing: 0pt,
		node-pad: 0pt,
		node((0,-1), b(blue,    5mm, 10mm)),
		node((1, 0), b(green,  20mm,  5mm)),
		node((1, 1), b(red,     5mm,  5mm)),
		node((0, 1), b(orange, 10mm, 10mm)),
	)
	```)
)


While grid points are always at integer coordinates, nodes may have *fractional coordinates*.
A node placed between grid points still causes the neighbouring rows and columns to grow to accommodate its size, but only partially, depending on proximity.
For example, see how the column sizes change as the green box moves from $(0, 0)$ to $(1, 0)$:

#stack(
	dir: ltr,
	spacing: 1fr,
	..(0, .25, .5, .75, 1).map(t => {
		arrow-diagram(
			debug: 1,
			spacing: 0mm,
			node-pad: 0pt,
			node((0,-1), box(fill: blue.lighten(50%),   width: 5mm, height: 10mm)),
			node((t, 0), box(fill: green.lighten(50%),  width: 20mm, height:  5mm, align(center + horizon, $(#t, 0)$))),
			node((1, 1), box(fill: red.lighten(50%),    width:  5mm, height:  5mm)),
			node((0, 1), box(fill: orange.lighten(50%), width: 10mm, height: 10mm)),
		)
	}),
)

Specifically, fractional coordinates are dealt with by linearly interpolating the layout, in the sense that if a node is at $(0.25, 0)$, then the width of column $floor(0.25) = 0$ is at least $75%$ of the node's width, and column $ceil(0.25) = 1$ at least $25%$ its width.

As a result, diagrams will automatically adjust when nodes grow or shrink, while still allowing you to place nodes at precise coordinates.

// == Physical coordinates

// Elastic coordinates are determined by the sizes and positions of the nodes in the diagram, and are resolved into physical coordinates which are then passed to CeTZ for drawing.

// You can convert elastic coordinates to physical coordinates with a callback:
// #stack(
// 	dir: ltr,
// 	spacing: 1fr, 
// 	..code-example(```typ
// 	#import "@preview/cetz:0.1.2"
// 	#arrow-diagram({
// 		let (A, B, C) = ((0,0), (1,1), (1,-1))
// 		node(A, $A$)
// 		node(B, $B$)
// 		node(C, $C$)
// 		conn(A, B, "hook->")
// 		conn(A, C, "->>")
// 		resolve-coords(A, B, callback: (p1, p2) => {
// 			cetz.draw.rect(
// 				(to: p1, rel: (-15pt, -15pt)),
// 				(to: p2, rel: (15pt, 15pt)),
// 				fill: rgb("00f1"),
// 				stroke: (paint: blue, dash: "dashed"),
// 			)
// 		})
// 	})
// 	```),
// )

== Connectors

Connectors between nodes connect to the node's bounding circle or bounding rectangle. The bounding shape is chosen automatically depending on the node's aspect ratio.

$
#arrow-diagram(
	spacing: (10mm, 6mm),
	// node-pad: 4pt,
	debug: 2,
	// node-defocus: 0,
	node((0,+1), $A times B times C$),
	node((-1,0), $A$),
	node(( 0,-1), $B$),
	node((+1,0), $C$),
	conn((-1,0), (0,-1)),
	conn((+1,0), (0,-1)),
	conn((-1,0), (0,1)),
	conn((+1,0), (0,1)),
	conn((0,-1), (0,1)),
)
$

=== Marks and arrows

A few mathematical arrow heads are supported, designed to match the symbols $arrow$, $arrow.double$, $arrow.twohead$, $arrow.hook$, $arrow.bar$, etc.
See the `marks` argument of #link(label("conn()"))[`conn()`] for details.

#align(center, arrow-diagram(
	debug: 0,
	spacing: (15mm, 10mm),
{
	for (i, str) in (
		"->",
		"=>",
		"|->",
		"hook->>",
	).enumerate() {
		for j in range(2) {
			conn((2*i, -j), (2*i + 1, -j), str, bend: 40deg*j, thickness: 1pt)
		}
	}
}))

=== CeTZ integration

Currently, only straight and arc connectors are supported.
However, an escape hatch is provided with the `render` argument of #link(label("arrow-diagram()"))[`arrow-diagram()`] so you can intercept diagram data and draw things using CeTZ directly.

Here is an example of how you might hack together a Bézier connector using the same node anchoring and arrow head functions that this package provides:

#stack(..code-example(```typ
#arrow-diagram(
	node((0,0), $A$, stroke: 1pt),
	node((2,1), [Bézier], stroke: 1pt),
	render: (grid, nodes, conns, options) => {
		cetz.canvas({
			// this is the default code to render the diagram
			arrow-diagrams.draw-diagram(grid, nodes, conns, options)

			// retrieve node data by coordinates
			let n1 = arrow-diagrams.find-node-at(nodes, (0,0))
			let n2 = arrow-diagrams.find-node-at(nodes, (2,1))

			// get anchor points for the connector
			let p1 = arrow-diagrams.get-node-anchor(n1, 0deg)
			let p2 = arrow-diagrams.get-node-anchor(n2, -90deg)

			// make some control points
			let c1 = cetz.vector.add(p1, (20pt, 0pt))
			let c2 = cetz.vector.add(p2, (0pt, -70pt))

			cetz.draw.bezier(p1, p2, c1, c2)

			// place an arrow head at a given point and angle
			arrow-diagrams.draw-arrow-cap(p1, 180deg, 1pt + black, "head")
		})
	}
)
```))


=== The `defocus` adjustment

For aesthetic reasons, lines connecting to a node need not focus to the node's exact center, especially if the node is short and wide or tall and narrow.
Notice the difference the figures below. "Defocusing" the connecting lines can make the diagram look more comfortable.

#align(center, stack(
	dir: ltr,
	spacing: 20%,
	..(("With", 0.2), ("Without", 0)).map(((with, d)) => {
		figure(
			caption: [#with defocus],
			arrow-diagram(
				spacing: (10mm, 9mm),
				node-defocus: d,
				node((0,1), $A times B times C$),
				conn((-1,0), (0,1)),
				conn((+1,0), (0,1)),
				conn((0,-1), (0,1)),
			)
		)
	})
))

See the `node-defocus` argument of #link(label("arrow-diagram()"))[`arrow-diagram()`] for details.

= Function reference
#show-module("/src/main.typ")
#show-module("/src/layout.typ")
#show-module("/src/draw.typ")
#show-module("/src/marks.typ")
#show-module("/src/utils.typ")