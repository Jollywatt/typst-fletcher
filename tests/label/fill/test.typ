#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(
	crossing-fill: gray,
	edge((0,0), (1,1), "->", [no fill], label-side: right),
	edge((1,0), (2,1), "->", [fill], label-side: center),
	edge((2,0), (3,1), "->", [fill], label-fill: true),
)
\
#diagram(
	crossing-fill: gray,
	edge((0,0), (1,1), "->", [blue fill], label-side: right, label-fill: blue),
	edge((1,0), (2,1), "->", [no fill], label-side: center, label-fill: false),
	edge((2,0), (3,1), "->", [no fill]),
)
