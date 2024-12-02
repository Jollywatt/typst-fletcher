#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

Default placement should be above the line.

#let around = (
	(-1,+1), ( 0,+1), (+1,+1),
	(-1, 0),          (+1, 0),
	(-1,-1), ( 0,-1), (+1,-1),
)

#diagram(
	spacing: 2cm,
	axes: (ltr, ttb),
	for p in around {
		edge(p, (0,0), $f$)
	},
)

Reversed $y$-axis:

#diagram(
	spacing: 2cm,
	axes: (ltr, btt),
	for p in around {
		edge(p, (0,0), $f$)
	},
)