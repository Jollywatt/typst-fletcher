#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(
	node-outset: 4pt,
	spacing: (15mm, 8mm),
	node-stroke: black + 0.5pt,
	node((0, 0), $s_1$, ),
	node((1, 0), $s_2$, extrude: (-1.5, 1.5), fill: blue.lighten(70%)),
	edge((0, 0), (1, 0), "->", label: $a$, bend: 20deg),
	edge((0, 0), (0, 0), "->", label: $b$, bend: 120deg),
	edge((1, 0), (0, 0), "->", label: $b$, bend: 20deg),
	edge((1, 0), (1, 0), "->", label: $a$, bend: 120deg),
	edge((1,0), (2,0), "->>"),
	node((2,0), $s_3$, extrude: (+1, -1), stroke: 1pt, fill: red.lighten(70%)),
)

Extrusion by multiples of stroke thickness:

#diagram(
	node((0,0), `outer`, stroke: 1pt, extrude: (-1, +1), fill: green),
	node((1,0), `inner`, stroke: 1pt, extrude: (+1, -1), fill: green),
	node((2,0), `middle`, stroke: 1pt, extrude: (0, +2, -2), fill: green),
)

Extrusion by absolute lengths:

#diagram(
	node((0,0), `outer`, stroke: 1pt, extrude: (-1mm, 0pt), fill: green),
	node((1,0), `inner`, stroke: 1pt, extrude: (0, +.5em, -2pt), fill: green),
)
