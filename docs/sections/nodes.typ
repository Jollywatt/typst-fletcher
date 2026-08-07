#import "../common.typ": *
#show: style


= Nodes

Nodes are content centered at a coordinate.
By default, nodes fit to their content (with an @node.inset[inset]), but can also be given a specific size and @node-shapes[shape].
Nodes can be given various styles including @node.stroke[stroke] and @node.fill[fill].

Edges automatically snap to nodes (with an @node.outset) and the positions and sizes of nodes @flexigrid-layouts[affects diagram layout] (unlike edges or plain CeTZ objects).

#example(```typ
#diagram(
	spacing: (5pt, 2em), // small columns, large rows
	node((0,0), $A$),
	node((1,0), $f$, stroke: 1pt),
	node((2,0), $g$, stroke: 2pt + blue, shape: rect),
	node((3,0), $X$, stroke: blue, extrude: (0, 3)),
	{
		let b = blue.lighten(70%)
		node((0,1), `xyz`, fill: b, )
		let dash = (paint: blue, dash: "dashed")
		node((1,1), `xyz`, stroke: dash, inset: 1em)
		node((2,1), `xyz`, stroke: b, extrude: (0, -2))
		node((3,1), `xyz`, fill: b, height: 5em,
		                   corner-radius: 5pt)
	}
)
```)

== Node styles <node-styles>

Node styles can be set with named arguments to @node.
Default node styles can be set by passing options to the enclosing @diagram with the `node-` prefix, or by using `cetz.draw.set-style(node: ..)`.

#example(```typ
#diagram(
  node-stroke: 2pt, // default stroke style for nodes
  node((0,0), fill: yellow, [A]),
  edge("<->"),
  {
    import cetz.draw: *
    set-style(node: (extrude: (2,0)))
		// stroke becomes 2pt + blue
    node((0,1), stroke: blue, [B], outset: 4pt)
  }
)
```)

Like CeTZ styles, `cetz.draw.set-style()` is scoped to the current `cetz.draw.group()`.

Available node styles:

- @node.fill
- @node.stroke
- @node.extrude
- @node.inset
- @node.outset
- @node.shape
- Any other styles specific to the @node-shapes[node shape]:
	- `width`, `height`, `corner-radius` for @rect nodes
	- `radius` for @circle nodes
	- and so on



== Node shapes <node-shapes>

By default, nodes are circular if their content is small and square, and rectangular if it is tall or wide.
The @node.shape[shape] option can be set to any of the following built-in shapes.

#shapes-gallery

Most shapes have additional styles specific to the shape, such as:
- `width`, `height` and @node-fit[`fit`] for all shapes
- `corner-radius` for @rect
- `radius` for @circle
- `angle` for @parallelogram, @keystone, @triangle, @house, @chevron and @hexagon
- `dir` for @triangle, @house, @chevron
- and others

Additional styles are described in each shape's documentation.

A node's shape can often be automatically inferred from the other styles given.
For example, you can write `node(.., radius: 3cm)` instead of `node(.., shape: "circle", radius: 3cm)`.

#example(```typ
#diagram(
	node-fill: yellow,
	node-stroke: 0.7pt,
	node((0,0), corner-radius: 5pt)[Rounded],
	edge("->-"),
	node((0,1), radius: 2mm)
)
```)



=== Making shapes fit better <node-fit>

All shapes have a `fit` parameter, which adjusts how tightly the shape fits in the @node.body[body].
- `fit: 0` makes the shape small enough to fit inside the body
- `fit: 1` makes the shape large enough so the node body fits inside

The default is usually in between, striking a balance.
If a node looks too cramped inside a shape, you can usually adjust the `fit` instead of tweaking the @node.inset.

You can see the bounding box of the node body with the @debug.node.body debug option.

#example(```typ
#diagram(
  debug: "node.body",
  spacing: 5pt,
  node-stroke: blue,
  node-fill: blue.lighten(80%),
  node-shape: "diamond",
  node((0,0), fit: 0)[Zero fit],
  node((0,1), fit: 0.5)[Partial],
  node((0,2), fit: 1)[Whole fit],
)
```)

In addition to controlling how the node's body fits in the shape, the `fit-cell` parameter controls how the shape fits in the surrounding flexigrid cell.

This only matters for the layout of a surrounding @flexigrid or @diagram; the `fit-cell` style doesn't affect node itself.

#example(```typ
#diagram(
  debug: "grid.cells node.body",
  spacing: 5pt,
  node-stroke: blue,
  node-fill: blue.lighten(80%),
  node-shape: "triangle",
  node((0,0), fit-cell: 0)[Zero cell fit],
  node((1,1), fit-cell: 1)[Total cell fit],
)
```)
