#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, shapes

#diagram(
	node-stroke: 1pt,
	node-outset: 5pt,
	axes: (ltr, ttb),
	debug: 3,
	node((0,0), $A$, radius: 5mm),
	edge("->"),
	node((1,1), [crowded], shape: shapes.house, fill: blue.lighten(90%)),
	edge("..>", bend: 30deg),
	node((0,2), $B$, shape: shapes.diamond),
	edge((0,0), "d,ru,d", "=>"),

	edge((1,1), "rd", bend: -40deg),
	node((2,2), `cool`, shape: shapes.pill),
	edge("->"),
	node((1,3), [_amazing_], shape: shapes.parallelogram),

	node((2,0), [robots], shape: shapes.hexagon),
	node((2,3), [squashed], shape: shapes.ellipse),
	edge("u", "->", bend: -30deg),
)