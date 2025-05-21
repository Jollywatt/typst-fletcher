#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge



#let make-diagram(label-pos) = diagram(
	edge-corner-radius: 10pt,
	edge((0, 0), "d,drr,ddd", "-}>",
		[#label-pos],
		label-side: center,
		label-pos: label-pos,
	)
)

#for i in (
	(0, -50%),
	(0, 0%),
	(0, 50%),
	(0, 100%),
	(0, 150%),
	(1, 50%),
	(2, -0.5),
	(2, 0),
	(2, 12pt),
	(2, 0.25),
	(2, 0.5),
	(2, 0.75),
	(2, 100%-6pt),
	(2, 100%+6pt),
) {
	make-diagram(i)
	pagebreak(weak: true)
}

#for i in (
	(-1, 50%),  // Segment must be non-negative
	(3, 50%),  // Segment out of range
) {
	assert-panic(() => make-diagram(i))
}
