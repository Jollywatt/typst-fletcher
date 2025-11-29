#import "../common.typ": *
#show: style

= Quick Overview

Import fletcher with:

#raw(block: true, lang: "typ", "#import \"@preview/fletcher:" + VERSION + "\" as fletcher: diagram, node, edge")

Diagrams are made from #[@node]s containing content and #[@edge]s which can be styled with arrow marks and which snap to nodes.
Nodes and edges can be placed in a @diagram and arranged on a flexible coordinate grid, or placed directly into a CeTZ canvas and arranged with normal CeTZ coordinates.

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

== Flexible coordinate grids

A @diagram contains a _flexible coordinate grid_, visible when the @flexigrid.debug option of @diagram is on.
When a node is placed, the rows and columns grow to accommodate the node's size, like a table.

#example(```typ
#diagram(
  debug: "grid", // show helper annotations
  spacing: 5mm,  // gutter between cells
  node((0,0), stroke: yellow, [Wide node]),
  node((1,0), fill: green, [A\ tall\ node]),
  node((0,1), fill: red, emph[top left], align: top + left),
  node((1,1), fill: blue, text(white, $ a/b $)),
)
```)

Coordinates can be fractional; the center of a node placed at `0.25` is $25%$ between the adjacent columns or rows.
Notice how the column sizes adjust to the green node:

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
