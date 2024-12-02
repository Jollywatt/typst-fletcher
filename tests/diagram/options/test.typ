#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(
	node-stroke: gray.darken(50%) + 1pt,
	edge-stroke: green.darken(40%) + .6pt,
	node-fill: green.lighten(80%),
	node-outset: 2pt,
	label-sep: 0pt,
	node((0,1), $A$),
	node((1,0), $sin compose cos compose tan$, fill: none),
	node((2,1), $C$),
	edge("o-o", stroke: orange),
	node((3,1), $D$, shape: "rect"),
	edge((0,1), (1,0), $sigma$, "-}>", bend: -45deg),
	edge((2,1), (1,0), $f$, "<{-"),
)
