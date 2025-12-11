#import "../common.typ": *
#show: style

= Quick Overview

Import fletcher with:

#raw(block: true, lang: "typ", "#import \"@preview/fletcher:" + VERSION + "\" as fletcher: diagram, node, edge")

Diagrams contain #[@node]s and #[@edge]s.
Nodes contain content, and edges snap to nodes.
Nodes and edges can be placed in a @diagram and arranged on a flexible coordinate grid:

#example(```typ
#diagram({
  node((0,0), $G$) // (column, row)
  edge("->", $f$) // start/end at prev/next node
  node((1,0), $im(f)$)
  edge((0,0), "->>", $pi$) // start given; end is next node
  edge("<--hook'", $tilde(f)$)
  node((0,-1), $G slash ker(f)$)
})
```)

Nodes and edges can also be placed directly into a CeTZ canvas, using normal Cartesian coordinates.
Edges can snap to CeTZ nodes.
#example(```typ
#import fletcher.cetz
#cetz.canvas(length: 5mm, {
	import cetz.draw: *
	set-style(fill: teal, edge: (stroke: 1pt + teal))
	circle((5,0), radius: (1.2,0.8), name: "egg")
	line((0,1), (1,0), (0,-1), (-1,0), close: true, name: "jewel")
	edge(<jewel>, "<|--|>", <egg>, bend: 45deg)
})
```)

== Flexible coordinate grids

A @diagram contains a _flexible coordinate grid_, visible when the @flexigrid.debug option of @diagram is on.
When a node is placed, the rows and columns grow to accommodate the node's size, like a table.

#example(```typ
#diagram(
  debug: "grid", // show helper annotations
  spacing: 5mm,  // gutter between cells
  node((0,0), stroke: yellow, [Wide node]),
  node((1,0), fill: green, [A\ tall\ node], name: "tall"),
  node((0,1), fill: red, emph[top left], align: top + left),
  node((1,1), fill: blue, text(white, $ a/b $)),
	cetz.draw.polygon("tall.north-east", 6, radius: 4pt)
)
```)

Coordinates can be fractional; the center of a node placed at `0.25` is $25%$ between the adjacent columns or rows.
Notice how the column sizes adjust to the with of the green node:

#stack(
	dir: ltr,
	spacing: 1fr,
	..(0, .25, .5, .75, 1).map(t => {
		let c = (orange, red, green, blue).map(x => x.lighten(50%))
		fletcher.diagram(
			debug: "grid.cells",
			spacing: 2mm,
			node-corner-radius: 3pt,
			node((0,0), [a], fill: c.at(0), width: 10mm, height: 10mm),
			node((1,0), [b], fill: c.at(1), width: 5mm, height: 5mm),
			node((t,-1), $(#t, 1)$, fill: c.at(2), width: 20mm, height: 5mm),
			node((0,-2), [d], fill: c.at(3), width: 5mm, height: 5mm),
		)
	}),
)

== Physical coordinates

When placed inside a @diagram, nodes can be positioned at a specific row or column using unitless coordinates, like ```typc node((3, 4))```.
Nodes can also be placed at physical coordinates, like ```typc node((50mm, 20mm))```, or mixtures like ```typc node((rel: (0, 2em), to: (1, 1)))``` using CeTZ coordinate expressions.

#example(```typ
#diagram(
	node((1, 0), name: "O"), // elastic coordinate
	for i in range(12) {
    let θ = i/12*360deg
		edge(<O>, "->", auto)
		node((rel: (θ, 10mm), to: "O"), $ #i $, inset: 4pt)
	}
)
```)
