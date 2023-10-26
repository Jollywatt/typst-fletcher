#import "arrow-diagrams.typ": *

// #set page(fill: blue.darken(50%))
// #set text(fill: white)

= `arrow-diagrams` package documentation


#arrow-diagram(
	pad: 10mm,
	debug: 0,
	{
		let C = (-.50,-1)

		node((-1,0), $A$)
		node(( 0,0), $A times B$)
		node((+1,0), $B$)

		node(C, none)

		arrow((-1,0), (0,0))
		arrow((+1,0), (0,0))
		arrow((-1,0), C)
		arrow((+1,0), C)
		arrow(( 0,0), C)
	}
)

== The layouting algorithm

Each diagram is built on a grid of points, where each point
can be thought of as being the center of a cell in a table
with possibly varying row heights and column widths.

$
#arrow-diagram(
	debug: 1,
	node((0,-1), box(fill: rgb("6663"), width: 20mm, height: 5mm)),
	node((1, 0), box(fill: rgb("f003"), width: 20mm, height: 10mm)),
	node((1,1), box(fill: rgb("0f03"), width: 10mm, height: 5mm)),
	node((0,1), box(fill: rgb("00f3"), width: 10mm, height: 10mm)),
)
$

#stack(
	dir: ltr,
	spacing: 1fr,
	..(0, .5, 1).map(t => {
		arrow-diagram(
			debug: 2,
			pad: 1mm,
			node((0,-1), box(fill: rgb("6663"), width: 20mm, height: 5mm)),
			node((t, 0), box(fill: rgb("f003"), width: 30mm, height: 10mm, [(#t, 0)])),
			node((1,1), box(fill: rgb("0f03"), width: 10mm, height: 5mm)),
			node((0,1), box(fill: rgb("00f3"), width: 10mm, height: 10mm)),
		)
	}),
)