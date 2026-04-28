#import "../common.typ": *
#show: style

= Quick Overview

Import fletcher with:

#raw(block: true, lang: "typ", "#import \"@preview/fletcher:" + VERSION + "\" as fletcher: diagram, node, edge")

Diagrams contain #[@node]s and #[@edge]s.
Nodes contain content and can have various shapes and styles, while edges snap to nodes and can be given @edge.marks[marks] and @edge.label[labels].
Nodes and edges can be placed in a @diagram, or @draw-in-cetz[directly into a CeTZ canvas].

When placed in @diagram, nodes and edges are arranged on a @flexigrids[flexible coordinate grid].

#example(```typ
#diagram({
  node((0,0), $G$)
  edge("->", $f$) // start/end at prev/next node
  node((1,0), $im(f)$)
  edge((0,0), "->>", $pi$) // start given; end is next node
  edge("<--hook'", $tilde(f)$)
  node((0,-1), $G slash ker(f)$)
})
```)

Styles can be controlled with the named arguments of @node and @edge.
Default styles can be set by passing the same arguments prefixed with "`node-`" or "`edge-`" to @diagram.

#example(```typ
#diagram(
	spacing: (1cm, 4mm), // column and row gutter
	node-inset: 8pt, // padding around node content
	node-fill: teal.mix(fuchsia),
	edge-stroke: 2pt + gray,
	node((0,0))[A], edge(), node((1,0))[B],
	node((2,1))[C], node((2,-1), fill: orange)[D],
	edge((1,0), (2,1), bend: 45deg),
	edge((1,0), "=>", (2,-1), stroke: 1pt + black),
)
```)


You can also place nodes and edges directly into `cetz.canvas()` and set node and edge styles with `cetz.draw.set-style()`.
Below, we use fletcher's marks to draw an edge in a CeTZ-based figure.

#example(```typ
#import fletcher.cetz // import this way to ensure compatibility
#cetz.canvas(length: 5mm, {
	import cetz.draw: *
	set-style(fill: teal, edge: (stroke: 1pt + teal))
	circle((5,0), radius: (1.2,0.8), name: "egg")
	line((0,1), (1,0), (0,-1), (-1,0), close: true, name: "jewel")
	edge(<jewel>, "stealth--stealth", <egg>, bend: 45deg)
})
```)

== Flexible coordinate grids <flexigrids>

Fletcher defines a "flexible" coordinate system for creating tabular layouts, visible when the `debug` option of @diagram is on.
The rows and columns in this coordinate system grow to accommodate the sizes of nodes, like a table:

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
      node((0, 0), [a], fill: c.at(0), width: 10mm, height: 10mm),
      node((1, 0), [b], fill: c.at(1), width: 5mm, height: 5mm),
      node((t, -1), $(#t, 1)$, fill: c.at(2), width: 20mm, height: 5mm),
      node((0, -2), [d], fill: c.at(3), width: 5mm, height: 5mm),
    )
  }),
)

When inside a flexigrid, nodes can also span multiple columns or rows:

#example(```typ
#diagram(
	spacing: 4pt,
	node-stroke: 1pt,
	node-fill: white,
	node-corner-radius: 2pt,
	node((0,0), [Sight], name: <sight>),
	node((1,0), [Sound]),
	node((2,0), [Smell], name: <smell>),
	node((0,1), [Senses], colspan: 3),
	node((0,0), rowspan: 2, colspan: 3,
	  fill: yellow, extrude: 4pt, layer: -1, []),
)
```)

Under the hood, a @diagram is just a @flexigrid inside a CeTZ canvas. You can also use the flexigrid coordinate system inside a normal CeTZ canvas (see @cetz-interop for details.)


== Coordinate expressions

Dimensionless coordinates like `(2, 3)` in a @node or @edge refer to columns/rows in the grid.
You can also use physical lengths like `(20mm, 5mm)` or any CeTZ coordinate expression, including anchors.

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
