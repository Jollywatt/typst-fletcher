#import "arrow-diagrams.typ": *

// #set page(fill: blue.darken(50%))
// #set text(fill: white)

#show raw.where(block: true): set text(size: 0.75em)


#align(center, text(2em)[
	*The `arrow-diagrams` package*
])


#outline()

= How the grid layout works

Each diagram is built on a grid of points, each at the center of a cell in a table layout with possibly varying row heights and column widths.
When a node is placed in a diagram, the rows and columns grow to accommodate the node's size.

This can be seen more clearly in diagrams with no cell padding:

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

Specifically, fractional coordinates are handled by linearly interpolating the layout.
For example, if a node is at $(0.25, 0)$, then the width of column $0$ must be at least $75%$ of the node's width, an column $1$ is at least $25%$ its width.
This is implemented in the function `expand-fractional-rects`.

As a result, diagrams will automatically adjust when nodes grow or shrink, while still allowing you to place nodes at precise locations when you need to.


= How connecting lines work

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
	arrow((-1,0), (0,-1)),
	arrow((+1,0), (0,-1)),
	arrow((-1,0), (0,1)),
	arrow((+1,0), (0,1)),
	arrow((0,-1), (0,1)),
)
$

== The `defocus` correction

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
				pad: (10mm, 6mm),
				defocus: d,
				node((0,1), $A times B times C$),
				arrow((-1,0), (0,1)),
				arrow((+1,0), (0,1)),
				arrow((0,1), (0,-1)),
			)
		)
	})
))

This correction is controlled by the `defocus` attribute of the node.
It is best explained by example:

#stack(
	dir: ltr,
	spacing: 1fr,
	..(+.8, 0, -.2).map(d => {
		arrow-diagram(
			pad: 10mm,
			debug: 2,
			node-outset: 15pt,
			defocus: d,
			node((0,0), raw("defocus: "+repr(d))),
			for p in (
				(-1,+1), ( 0,+1), (+1,+1),
				(-1, 0),          (+1, 0),
				(-1,-1), ( 0,-1), (+1,-1),
			) {
				arrow((0,0), p)
			},
		)
	})
)

For `defocus: 0`, the connecting lines are directed exactly at the grid point at the node's center.

$
#arrow-diagram(
	pad: 30pt,
	debug: 0,
{
	node((0,0), [hi])
	node((1,0), [there])
	arrow((0,0), (1,0), angle: 60deg)

})
$