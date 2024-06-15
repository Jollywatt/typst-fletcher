#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#let label = table(
	columns: (12mm, 4mm, 4mm, 4mm),
	`Node`, none, `4`, none,
	stroke: (x, y) => if 0 < x and x < 3 { (x: 1pt) },
)

Allow `snap-to` to be `none`.

#diagram(
	node-stroke: 1pt,
	edge-stroke: 1pt,
	mark-scale: 50%,
	node((0,0), label, inset: 0pt, corner-radius: 3pt),
	edge((0.09,0), (0,1), "*-straight", snap-to: (none, auto)),
	edge((0.41,0), (1,1), "*-straight", snap-to: none),
	node((0,1), `Subnode`),
)

#pagebreak()

#diagram(
	node(enclose: ((0,0), (0,3)), fill: yellow, snap: false),
	for i in range(4) {
		node((0,i), [#i], fill: white)
		edge((0,i), (1,i), "<->")

	},
	node([B], enclose: ((1,0), (1,3)), fill: yellow),
	for i in range(3) {
		edge((0,i), (0,i + 1), "o..o")
	},
)

#pagebreak()

#diagram(
	node-stroke: 0.6pt,
	node-fill: white,
	node((0,1), [X]),
	edge("->-", bend: 40deg),
	node((1,0), [Y], name: <y>),
	node($Sigma$, enclose: ((0,1), <y>),
			 stroke: teal, fill: teal.lighten(90%),
			 snap: -1, // prioritise other nodes when auto-snapping
			 name: <group>),
	edge(<group>, <z>, "->"),
	node((2.5,0.5), [Z], name: <z>),
)