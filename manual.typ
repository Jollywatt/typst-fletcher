#import "@preview/tidy:0.1.0"
#import "src/lib.typ": *

#set page(numbering: "1")

#let show-module(path) = {
	tidy.show-module(
		tidy.parse-module(
			read(path),
			scope: (
				arrow-diagram: arrow-diagram,
				node: node,
				conn: conn,
			),
		),
		show-outline: false,
	)
}

#align(center)[
	#text(2em, strong(`arrow-diagrams`))

	A Typst package for drawing diagrams with arrows,\ built on top of link("CeTZ.
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

#let code-example(src) = {
	let scope = (arrow-diagram: arrow-diagram, node: node, conn: conn)
	(eval(src.text, mode: "markup", scope: scope), src)
}

#table(
	columns: (1fr, 2fr),
	align: (horizon, left),
	inset: 10pt,

	..code-example(```typ
	Inline $f: A -> B$ equation, \
	Inline #arrow-diagram(
		node-outset: 4pt,
		node((0,0), $A$),
		conn((0,0), (1,0), text(.7em, $f$), "->", label-sep: 2pt),
		node((1,0), $B$),
	) diagram.
	```),

	..code-example(```typ
	#arrow-diagram(
		min-size: 10mm,
		node((0,1), $X$),
		node((1,1), $Y$),
		node((0,0), $X slash ker(f)$),
		conn((0,1), (1,1), $f$, "->"),
		conn((0,0), (1,1), "hook-->"),
		conn((0,1), (0,0), "->"),
	)
	```),

	..code-example(```typ
	#arrow-diagram(
		pad: 2cm,
		node((0,0), $cal(A)$),
		node((1,0), $cal(B)$),
		conn((0,0), (1,0), $F$, "->", bend: +35deg),
		conn((0,0), (1,0), $G$, "->", bend: -35deg),
		conn((.5,+.21), (.5,-.21), $alpha$, "=>"),
	)
	```),
)

#grid(
	gutter: 2em,
	columns: (1fr, 1fr),
	..(
		arrow-diagram(
			debug: 0,
			min-size: (10mm, 10mm),
			node((0,1), $X$),
			node((1,1), $Y$),
			node((0,0), $X slash ker(f)$),

			conn((0,1), (1,1), $f$, "->"),
			conn((0,0), (1,1), "hook-->"),
			conn((0,1), (0,0), "->"),
		),
		arrow-diagram(
			debug: 3,
			pad: 5em,
			node((0,0), $S a$),
			node((0,1), $T b$),
			node((1,0), $S a'$),
			node((1,1), $T b'$),
			conn((0,0), (0,1), $f$, "hook->>"),
			conn((1,0), (1,1), $f'$, label-sep: 1em),
			conn((0,0), (1,0), $α$, extrude: (-4,0,4), label-sep: 0pt),
			conn((0,1), (1,1), $γ$, bend: 20deg, "->"),
			conn((0,1), (1,1), $β$, bend: -20deg, "->"),
		),

	).map(x => align(center, x))
)

$
#arrow-diagram(
	min-size: 1cm,
	node-outset: 1.5em,
	pad: 20mm,
	debug: 0,
	defocus: 0.1,
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
	conn((1,1), (2,0), $k$, "<-->", label-sep: 0pt, paint: green, thickness: 1pt),
	node((2,0), $pi_1(X union Y)$)
)
$

#arrow-diagram(
	min-size: 3cm,
	defocus: 0,
	node-outset: 10pt,
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
				conn(proj(from), proj(to), ">>->", crossing: to.at(2) == 0)
			}
		}
	}
	conn(proj((1,1,1)), (2, 0.8), dash: "dotted")
	conn(proj((1,0,1)), (2, 0.8), dash: "dotted")
	node((2, 0.8), "fractional coords")
})


= Tutorial


= Layout


== How the layouting works

Each diagram is built on a grid of points, each at the center of a cell in a table layout.
When a node is placed in a diagram, the rows and columns grow to accommodate the node's size.

This can be seen more clearly in diagrams with `debug: 1` and no cell padding:

#stack(
	dir: ltr,
	spacing: 1fr, 
	align(center, arrow-diagram(
		debug: 1,
		pad: 0pt,
		node((0,-1), box(fill: blue.lighten(50%),   width: 5mm,  height: 10mm)),
		node((1, 0), box(fill: green.lighten(50%),  width: 20mm, height:  5mm)),
		node((1, 1), box(fill: red.lighten(50%),    width:  5mm, height:  5mm)),
		node((0, 1), box(fill: orange.lighten(50%), width: 10mm, height: 10mm)),
	)),
)[
#set text(size: 0.75em)
```typ
#arrow-diagram(
	debug: 1,
	pad: 0pt,
	node((0,-1), box(fill: blue.lighten(50%),   width: 5mm,  height: 10mm)),
	node((1, 0), box(fill: green.lighten(50%),  width: 20mm, height:  5mm)),
	node((1, 1), box(fill: red.lighten(50%),    width:  5mm, height:  5mm)),
	node((0, 1), box(fill: orange.lighten(50%), width: 10mm, height: 10mm)),
)
```
]

While grid points are always at integer coordinates, nodes can also have *fractional coordinates*.
A node between grid points still causes the neighbouring rows and columns to grow to accommodate its size, but only partially, depending on proximity.
For example, notice how the column sizes change as the green box moves from $(0, 0)$ to $(1, 0)$:

#stack(
	dir: ltr,
	spacing: 1fr,
	..(0, .25, .5, .75, 1).map(t => {
		arrow-diagram(
			debug: 1,
			pad: 0mm,
			node((0,-1), box(fill: blue.lighten(50%),   width: 5mm, height: 10mm)),
			node((t, 0), box(fill: green.lighten(50%),  width: 20mm, height:  5mm, align(center + horizon, $(#t, 0)$))),
			node((1, 1), box(fill: red.lighten(50%),    width:  5mm, height:  5mm)),
			node((0, 1), box(fill: orange.lighten(50%), width: 10mm, height: 10mm)),

		)
	}),
)

Specifically, fractional coordinates are dealt with by _linearly interpolating_ the layout, in the sense that if a node is at $(0.25, 0)$, then the width of column $floor(0.25) = 0$ is at least $75%$ of the node's width, and column $ceil(0.25) = 1$ at least $25%$ its width.

As a result, diagrams will automatically adjust when nodes grow or shrink, while still allowing you to place nodes at precise coordinates.


== How connecting lines work

Lines between nodes connect to the node's bounding circle or bounding rectangle, depending on the node's aspect ratio.

$
#arrow-diagram(
	pad: (10mm, 6mm),
	// node-outset: 4pt,
	debug: 2,
	// defocus: 0,
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

=== The `defocus` correction

For aesthetic reasons, a line connecting to a node should not necessarily be focused to the node's exact center, especially if the node is short and wide or tall and narrow.
Notice how in the figure above the lines connecting to the node $A times B times C$
would intersect slightly above its center, making the diagram look more comfortable.
The effect of this is shown below:

#align(center, stack(
	dir: ltr,
	spacing: 20%,
	..(("With", 0.4), ("Without", 0)).map(((with, d)) => {
		figure(
			caption: [#with defocus correction],
			arrow-diagram(
				pad: (10mm, 9mm),
				defocus: d,
				node((0,1), $A times B times C$),
				conn((-1,0), (0,1)),
				conn((+1,0), (0,1)),
				conn((0,-1), (0,1)),
			)
		)
	})
))

This correction is controlled by the `defocus` attribute of the node.
It is best explained by example:

#stack(
	dir: ltr,
	spacing: 1fr,
	..(+.8, 0, -.8).map(d => {
		arrow-diagram(
			pad: 10mm,
			debug: 0,
			node-outset: 15pt,
			defocus: d,
			node((0,0), raw("defocus: "+repr(d))),
			for p in (
				(-1,+1), ( 0,+1), (+1,+1),
				(-1, 0),          (+1, 0),
				(-1,-1), ( 0,-1), (+1,-1),
			) {
				conn((0,0), p)
			},
		)
	})
)

For `defocus: 0`, the connecting lines are directed exactly at the grid point at the node's center.


= Function reference
#show-module("src/main.typ")
#show-module("src/layout.typ")
#show-module("src/marks.typ")
#show-module("src/utils.typ")