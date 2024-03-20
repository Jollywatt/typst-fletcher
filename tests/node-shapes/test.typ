#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(
	node-stroke: 1pt,
	node-outset: 5pt,
	axes: (ltr, ttb),
	node((0,0), $A$, radius: 5mm),
	edge("->"),
	node((1,1), [crowded], shape: fletcher.shapes.house, fill: blue.lighten(90%)),
	edge("..>", bend: 30deg),
	node((0,2), $B$, shape: fletcher.shapes.diamond),
	edge((0,0), "d,ru,d", "=>"),

	edge((1,1), "rd", bend: -40deg),
	node((2,2), `cool`, shape: fletcher.shapes.pill),
	edge("->"),
	node((1,3), [_amazing_], shape: fletcher.shapes.parallelogram),

	node((2,0), [robots], shape: fletcher.shapes.hexagon)
)