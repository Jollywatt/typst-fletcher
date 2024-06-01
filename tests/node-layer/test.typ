#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(
	spacing: (10mm, 5mm), // wide columns, narrow rows
	node-stroke: 1pt,     // outline node shapes
	edge-stroke: 1pt,     // make lines thicker
	mark-scale: 60%,      // make arrowheads smaller
	edge((-2,0), "r,u,r", "..|>", $f$, label-side: left, layer: -2),
	edge((-2,0), "r,d,r", "-|>", $g$),
	node((0,-1), $F(s)$, fill: white, layer: -2),
	node((0,+1), $G(s)$, fill: white),
	edge((0,+1), (1,0), "-|>", corner: left),
	edge((0,-1), (1,0), "..|>", corner: right, layer: -2),
	node((1,0), text(white, $ plus.circle $), inset: 2pt, fill: black),
	edge("-|>"),
	node(
		enclose: ((0,+1), (0,-1)),
		fill: rgb("fa6c"),
		stroke: none,
		inset: 10pt,
		snap: false,
	),
)