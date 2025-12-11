#import "../common.typ": *
#show: style


= Nodes

Nodes are content centered at a coordinate.
Nodes automatically fit to their content (with an @node.inset), but can also be given a specific size and shape, and can have a @node.stroke and @node.fill.

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
		node((2,1), `xyz`, fill: b, stroke: blue, extrude: (0, -2))
		node((3,1), `xyz`, fill: b, height: 5em, corner-radius: 5pt)
	}
)
```)

== Node shapes

By default, nodes are circular if their content is small and square, and rectangular if it is tall or wide.
The @node.shape option accepts #fletcher.shapes.NODE_SHAPES.keys().map(repr).map(raw).join(last: [ or ], [, ]), and each shape has a set of associated options like `"width"`, `"radius"`, and so on.

// #example(```typ
// #diagram(
// 	node-fill: gradient.radial(white, blue, radius: 200%),
// 	node-stroke: blue,
// 	(
// 		node((0,0), [Blue Pill], shape: "circle")
//   ),
// )
// ```)

// #fletcher.shapes.NODE_SHAPES.pairs().map(((name, attrs)) => {
//   [
//     - #raw(name)
//       #for attr in attrs.keys() {
//         if attr == "draw" { continue }
//         [- #attr]
//       }
//   ]
// }).join()

// #diagram(node((), [hello], fill: yellow, shape: "rect"))