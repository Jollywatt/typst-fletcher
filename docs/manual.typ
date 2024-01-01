#import "@preview/tidy:0.1.0"
#import "/src/exports.typ" as fletcher: node, edge
#import "/src/main.typ": parse-arrow-shorthand

#set page(numbering: "1")
#set par(justify: true)
#show link: underline.with(stroke: blue.lighten(50%))

#let VERSION = toml("/typst.toml").package.version

#let scope = (
	fletcher: fletcher,
	diagram: fletcher.diagram,
	node: node,
	edge: edge,
	parse-arrow-shorthand: parse-arrow-shorthand,
	cetz: fletcher.cetz,
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

#show raw.where(block: false): it => {
	if it.text.ends-with("()") {
		link(label(it.text), it.text)
	} else { it }
}

#v(.2fr)

#align(center)[
	#fletcher.diagram(
		spacing: 2.3cm,
		node((0,1), $A$),
		node((1,1), $B$),
		edge((0,1), (1,1), $f$, ">>->"),
	)

	#text(2em, strong(`fletcher`)) \
	_(noun) a maker of arrows_

	A #link("https://typst.app/")[Typst] package for diagrams with lots of arrows,
	built on top of #link("https://github.com/johannes-wolf/cetz")[CeTZ].

	#emph[
	Commutative diagrams,
	finite state machines,
	control systems block diagrams...
	]

	#link("https://github.com/Jollywatt/typst-fletcher")[`github.com/Jollywatt/typst-fletcher`]

	Version #VERSION *(not yet stable)*
]

#v(1fr)

#outline(indent: 1em, target:
	heading.where(level: 1)
	.or(heading.where(level: 2))
	.or(heading.where(level: 3)),
)

#v(1fr)

#pagebreak()

#align(center)[

/*
	#fletcher.diagram(
		// node-stroke: 1pt ,
		node-fill: luma(90%),
		node((0,0), "edge types"),
		edge((0,0), (1,1), [arc], "..>", bend: +60deg),
		edge((0,0), (1,0), [line], "-->"),
		edge((0,0), (1,-1), [corner], "->", corner: right),
	)

	#v(1fr)

	#fletcher.diagram(
		cell-size: 1cm,
		node-inset: 1.5em,
		spacing: 20mm,
		debug: 0,
		node-defocus: 0.1,
		node((0,2), $pi_1(X sect Y)$),
		node((0,1), $pi_1(X)$),
		node((1,2), $pi_1(Y)$),
		node((1,1), $pi_1(X) ast.op_(pi_1(X sect Y)) pi_1(X)$),
		edge((0,2), (0,1), $i_2$, "->", extrude: (-1.5,1.5)),
		edge((0,2), (1,2), $i_1$, "hook->"),
		edge((1,2), (2,0), $j_2$, "<->", bend: 20deg, extrude: (-1.5,1.5)),
		edge((0,1), (2,0), $j_1$, "->>", bend: -15deg, dash: "dotted"),
		edge((0,1), (1,1), "hook->>", dash: "dashed"),
		edge((1,2), (1,1), "|->"),
		node((2,0), $pi_1(X union Y)$),
		edge((1,1), (2,0), $k$, "<-->", label-sep: 0pt, paint: green, thickness: 1pt),
	)

	#v(1fr)

	// #fletcher.diagram(
	// 	cell-size: 3cm,
	// 	node-defocus: 0,
	// 	node-inset: 10pt,
	// {
	// 	let cube-vertices = ((0,0,0), (0,0,1), (0,1,0), (0,1,1), (1,0,0), (1,0,1), (1,1,0), (1,1,1))
	// 	let proj((x, y, z)) = (x + z*(0.4 - 0.1*x), y + z*(0.4 - 0.1*y))
	// 	for i in range(8) {
	// 		let to = cube-vertices.at(i)
	// 		node(proj(to), [#to])
	// 		for j in range(i) {
	// 			let from = cube-vertices.at(j)
	// 			// test for adjancency
	// 			if from.zip(to).map(((i, j) ) => int(i == j)).sum() == 2 {
	// 				edge(proj(from), proj(to), "->", crossing: to.at(2) == 0)
	// 			}
	// 		}
	// 	}
	// 	edge(proj((1,1,1)), (2, 0.8), dash: "dotted")
	// 	edge(proj((1,0,1)), (2, 0.8), dash: "dotted")
	// 	node((2, 0.8), "fractional coords")
	// })

	// #v(1fr)
	*/


	#let c(x, y, z) = (x + 0.5*z, y + 0.4*z)
	#fletcher.diagram(
	  spacing: 4cm,
	  node-defocus: 0,
	  {

	  let v000 = c(0, 0, 0)

	  node(v000, $P$)
	  node(c(1,0,0), $P$)
	  node(c(2,0,0), $X$)
	  node(c(0,1,0), $J P$)
	  node(c(1,1,0), $J P$)
	  node(c(2,1,0), $"CP"$)
	  
	  node(c(0,0,1), $pi^*(T X times.circle T^* X)$)
	  node(c(1,0,1), $pi^*(T X times.circle T^* X)$)
	  node(c(2,0,1), $T X times.circle T^* X$)
	  node(c(0,1,1), $T P times.circle pi^* T^* X$)
	  node(c(1,1,1), $T P times.circle pi^* T^* X$)
	  node(c(2,1,1), $T_G P times.circle T^* X$)
	  

	  // aways
	  edge(v000, c(0,0,1), $"Id"$, "->", bend: 0deg)
	  edge(c(1,0,0), c(1,0,1), $"Id"$, "->")
	  edge(c(2,0,0), c(2,0,1), $"Id"$, "->")
	  
	  edge(c(0,1,0), c(0,1,1), $i_J$, "hook->")
	  edge(c(1,1,0), c(1,1,1), $i_J$, "hook->")
	  edge(c(2,1,0), c(2,1,1), $i_C$, "hook->")
	  
	  // downs
	  edge(c(0,1,0), v000, $pi_J$, "==>", label-pos: 0.2)
	  edge(c(1,1,0), c(1,0,0), $pi_J$, "->", label-pos: 0.2)
	  edge(c(2,1,0), c(2,0,0), $pi_"CP"$, "->", label-pos: 0.2)
	  
	  edge(c(0,1,1), c(0,0,1), $c_pi$, "..>", label-pos: 0.2)
	  edge(c(1,1,1), c(1,0,1), $c_pi$, "->", label-pos: 0.2)
	  edge(c(2,1,1), c(2,0,1), $overline(c)_pi$, "->", label-pos: 0.2)
	  
	  // acrosses
	  edge(v000, c(1,0,0), $lambda_g$, "->")
	  edge(c(1,0,0), c(2,0,0), $pi^G=pi$, "->")
	  
	  edge(c(0,0,1), c(1,0,1), $lambda_g times 1$, "..>", label-pos: 0.2)
	  edge(c(1,0,1), c(2,0,1), $pi^G$, "..>", label-pos: 0.2)
	  
	  edge(c(0,1,0), c(1,1,0), $j lambda_g$, "->", label-pos: 0.7)
	  
	  edge(c(0,1,1), c(1,1,1), $dif lambda_g times.circle (lambda_g times 1)$, "->")
	  edge(c(1,1,1), c(2,1,1), $pi^G$, "->")

	  edge(c(1,1,1), c(2,1,1), $Ω$, "<..>", bend: 60deg)
	})

	#v(1fr)

	#fletcher.diagram(
		node-defocus: 0,
		spacing: (1cm, 2cm),
		edge-thickness: 1pt,
		crossing-thickness: 5,
		mark-scale: 70%,
		node-fill: luma(97%),
		node-outset: 3pt,
		node((0,0), "magma"),

		node((-1,-1), "semigroup"),
		node(( 0,-1), "unital magma"),
		node((+1,-1), "quasigroup"),

		node((-1,-2), "monoid"),
		node(( 0,-2), "inverse semigroup"),
		node((+1,-2), "loop"),

		node(( 0,-3), "group"),

		{
			let quad(a, b, label, paint, ..args) = {
				paint = paint.darken(25%)
				edge(a, b, text(paint, label), "-|>", paint: paint, label-side: center, ..args)
			}

			quad((0,0), (-1,-1), "Assoc", blue)
			quad((0,-1), (-1,-2), "Assoc", blue, label-pos: 0.3)
			quad((1,-2), (0,-3), "Assoc", blue)

			quad((0,0), (0,-1), "Id", red)
			quad((-1,-1), (-1,-2), "Id", red, label-pos: 0.3)
			quad((+1,-1), (+1,-2), "Id", red, label-pos: 0.3)
			quad((0,-2), (0,-3), "Id", red)

			quad((0,0), (1,-1), "Div", yellow)
			quad((-1,-1), (0,-2), "Div", yellow, label-pos: 0.3, "crossing")

			quad((-1,-2), (0,-3), "Inv", green)
			quad((0,-1), (+1,-2), "Inv", green, label-pos: 0.3)

			quad((1,-1), (0,-2), "Assoc", blue, label-pos: 0.3, "crossing")
		},
	)

	#v(1fr)

	#{
		set text(white, font: "Fira Sans")
		let colors = (maroon, olive, eastern)
		fletcher.diagram(
			edge-thickness: 1pt,
			node((0,0), [input], fill: colors.at(0)),
			edge((0,0), (1,0)),
			edge((1,0), (2,+1), "-|>", corner: left),
			edge((1,0), (2,-1), corner: right),
			node((2,+1), [control unit (CU)], fill: colors.at(1)),
			edge((2,+1), (2,0), "<|-|>"),
			node((2, 0), align(center)[arithmetic & logic \ unit (ALU)], fill: colors.at(1)),
			edge((2, 0), (2,-1), "<|-|>"),
			node((2,-1), [memory unit (MU)], fill: colors.at(1)),
			edge((2,+1), (3,0), corner: left),
			edge((2,-1), (3,0), "<|-", corner: right),
			edge((3,0), (4,0), "-|>"),
			node((4,0), [output], fill: colors.at(2))
		)
	}

	#v(1fr)

]



#show heading.where(level: 1): it => pagebreak(weak: true) + it + v(0.5em)

= Examples

#raw(lang: "typ", "#import \"@preview/fletcher:" + VERSION + "\" as fletcher: node, edge")

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
	#fletcher.diagram({
		let (src, img, quo) = ((0, 1), (1, 1), (0, 0))
		node(src, $G$)
		node(img, $im f$)
		node(quo, $G slash ker(f)$)
		edge(src, img, $f$, "->")
		edge(quo, img, $tilde(f)$, "hook-->", label-side: right)
		edge(src, quo, $pi$, "->>")
	})
	```),

	..code-example(```typ
	An equation $f: A -> B$ and \
	a diagram #fletcher.diagram(
		node-inset: 4pt,
		node((0,0), $A$),
		edge((0,0), (1,0), text(0.8em, $f$), "->", label-sep: 1pt),
		node((1,0), $B$),
	).
	```),

	..code-example(```typ
	#fletcher.diagram(spacing: 2cm, {
		let (A, B) = ((0,0), (1,0))
		node(A, $cal(A)$)
		node(B, $cal(B)$)
		edge(A, B, $F$, "->", bend: +35deg)
		edge(A, B, $G$, "->", bend: -35deg)
		let h = 0.21
		edge((.5,+h), (.5,-h), $alpha$, "=>")
	})
	```),

	..code-example(```typ
	#fletcher.diagram(
		spacing: (8mm, 3mm), // wide columns, narrow rows
		node-stroke: 1pt,    // outline node shapes
		edge-thickness: 1pt, // thickness of lines
		mark-scale: 60%,     // make arrowheads smaller
		edge((-2,0), (-1,0)),
		edge((-1,0), (0,+1), $f$, "..|>", corner: left),
		edge((-1,0), (0,-1), $g$, "-|>", corner: right),
		node((0,+1), $F(s)$),
		node((0,-1), $G(s)$),
		edge((0,+1), (1,0), "..|>", corner: left),
		edge((0,-1), (1,0), "-|>", corner: right),
		node((1,0), $ + $, inset: 1pt),
		edge((1,0), (2,0), "-|>"),
	)
	```),

	..code-example(```typ
	#fletcher.diagram(
		node-stroke: black + 0.5pt,
		node-fill: blue.lighten(90%),
		node-outset: 4pt,
		spacing: (15mm, 8mm),
		node((0,0), [1], extrude: (4, 0)), // double stroke effect 
		node((1,0), [2]),
		node((2,1), [3a]),
		node((2,-1), [3b]),
		edge((0,0), (1,0), "->"),
		edge((1,0), (2,+1), "->", bend: -15deg),
		edge((1,0), (2,-1), "->", bend: +15deg),
		edge((2,-1), (2,-1), "->", bend: +130deg, label: [loop!]),
	)
	```)
)





#set raw(lang: "typc")
#let fn-link(name) = link(label(name), raw(name))

= Details

The recommended way to load the package is:
#raw(lang: "typ", "#import \"@preview/fletcher:" + VERSION + "\" as fletcher: node, edge", block: true)
Other functions (including internal functions) are exported, so avoid importing everything with #raw(lang: none, "*") and access them as needed with, e.g., `fletcher.diagram`.

== Nodes

#link(label("node()"))[`node((x, y), label, ..options)`]

Nodes are content placed in the diagram at a particular coordinate. They fit to the size of their label (with an `inset` and `outset`), can be circular or rectangular (`shape`), and can be given a `stroke` and `fill`.

=== Elastic coordinates

Diagrams are laid out on a flexible coordinate grid.
When a node is placed, the rows and columns grow to accommodate the node's size, like a table.
See the `diagram()` parameters for more control: `node-size` is the minimum row and column width, and `spacing` is the gutter between rows and columns, respectively.

Elastic coordinates can be demonstrated more clearly with a debug grid and no spacing.

#stack(
	dir: ltr,
	spacing: 1fr, 
	..code-example(```typ
	#let b(c, w, h) = box(fill: c.lighten(50%), width: w, height: h)
	#fletcher.diagram(
		debug: 1,
		spacing: 0pt,
		node-inset: 0pt,
		node((0,-1), b(blue,    5mm, 10mm)),
		node((1, 0), b(green,  20mm,  5mm)),
		node((1, 1), b(red,     5mm,  5mm)),
		node((0, 1), b(orange, 10mm, 10mm)),
	)
	```)
)

=== Fractional coordinates

Rows and columns are at integer coordinates, but nodes may have fractional coordinates.
These are dealt with by linearly interpolating the diagram between what it would be if the coordinates were rounded up or down. Both the node's position and its influence on row/column sizes are interpolated.

As a result, diagrams are responsive to node sizes (like tables) while also allowing precise positioning.
// For example, see how the column sizes change as the green box moves from $(0, 0)$ to $(1, 0)$:

#stack(
	dir: ltr,
	spacing: 1fr,
	..(0, .25, .5, .75, 1).map(t => {
		fletcher.diagram(
			debug: 1,
			spacing: 0mm,
			node-inset: 0pt,
			node((0,-1), box(fill: blue.lighten(50%),   width: 5mm, height: 10mm)),
			node((t, 0), box(fill: green.lighten(50%),  width: 20mm, height:  5mm, align(center + horizon, $(#t, 0)$))),
			node((1, 1), box(fill: red.lighten(50%),    width:  5mm, height:  5mm)),
			node((0, 1), box(fill: orange.lighten(50%), width: 10mm, height: 10mm)),
		)
	}),
)


== Edges

#link(label("edge()"))[`edge(node-1, node-2, label, marks, ..options)`]

Edges connect two coordinates. If there is a node at an endpoint, the edge attaches to the nodes' bounding circle or rectangle. Edges can have `label`s, can `bend` into arcs, and can have various arrow `marks`.

#stack(dir: ltr, spacing: 1fr, ..code-example(```typ
#fletcher.diagram(spacing: (12mm, 6mm), {
		let (a, b, c, abc) = ((-1,0), (0,-1), (1,0), (0,1))
		node(abc, $A times B times C$)
		node(a, $A$)
		node(b, $B$)
		node(c, $C$)
		edge(a, b, bend: -10deg, "dashed")
		edge(c, b, bend: +10deg, "dotted")
		edge(a, abc, $a$)
		edge(b, abc, "<=>")
		edge(c, abc, $c$)
})
```))

=== Marks and arrows

A few mathematical arrow heads are supported, designed to match the symbols $arrow$, $arrow.double$, $arrow.twohead$, $arrow.hook$, $arrow.bar$, etc.
See the `marks` argument of `edge()` for details.

#align(center, fletcher.diagram(
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
			edge((2*i, -j), (2*i + 1, -j), str, bend: 40deg*j, thickness: 1pt)
		}
	}
}))

Most marks have some parameters like size or sharpness angle that you can customize. This isn't a stable feature, but here's something to get you started:

#stack(dir: ltr, spacing: 1fr, ..code-example(```typ
#fletcher.diagram(
	edge-thickness: 1.5pt,
	spacing: (4cm, 1cm),
	{
		let custom-head = ( // sharper arrow head
			kind: "head",
			sharpness: 10deg,
			size: 70,
			delta: 10deg,
		)
		edge((0,1), (1,1), marks: (custom-head, custom-head + (sharpness: 20deg)))
		edge((0,0), (1,0), marks: ("bar", (kind: "bar", size: 2))) // smaller bar
	},
)
```))

=== CeTZ integration
Currently, only straight, arc and right-angled connectors are supported.
However, an escape hatch is provided with the `render` argument of `diagram()` so you can intercept diagram data and draw things using CeTZ directly.

Here is an example of how you might hack together a Bézier connector using the same functions that `fletcher` uses internally to anchor edges to nodes and draw arrow heads:

#stack(dir: ltr, spacing: 1fr, ..code-example(```typ
#fletcher.diagram(
	node((0,0), $A$),
	node((2,1), [Bézier]),
	render: (grid, nodes, edges, options) => {
		// cetz is also exported as fletcher.cetz
		cetz.canvas({
			// this is the default code to render the diagram
			fletcher.draw-diagram(grid, nodes, edges, options)

			// retrieve node data by coordinates
			let n1 = fletcher.find-node-at(nodes, (0,0))
			let n2 = fletcher.find-node-at(nodes, (2,1))

			// get anchor points for the connector
			let p1 = fletcher.get-node-anchor(n1, 0deg)
			let p2 = fletcher.get-node-anchor(n2, -90deg)

			// make some control points
			let c1 = cetz.vector.add(p1, (20pt, 0pt))
			let c2 = cetz.vector.add(p2, (0pt, -70pt))

			cetz.draw.bezier(p1, p2, c1, c2)

			// place an arrow head at a given point and angle
			fletcher.draw-arrow-cap(p2, 90deg, 1pt + black, "twohead")
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
			fletcher.diagram(
				spacing: (10mm, 9mm),
				node-defocus: d,
				node((0,1), $A times B times C$),
				edge((-1,0), (0,1)),
				edge((+1,0), (0,1)),
				edge((0,-1), (0,1)),
			)
		)
	})
))

See the `node-defocus` argument of #link(label("diagram()"))[`diagram()`] for details.

= Function reference
#show-module("/src/main.typ")
#show-module("/src/layout.typ")
#show-module("/src/draw.typ")
#show-module("/src/marks.typ")
#show-module("/src/utils.typ")