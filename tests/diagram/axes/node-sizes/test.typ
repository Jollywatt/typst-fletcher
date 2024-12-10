#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge


#for axes in (
	(ltr, btt),
	(rtl, ttb),
	(ttb, ltr),
	(btt, rtl),
) {
	for coords in (
		((0, 0), (0, 1)),
		((0, 0), (1, 0)),
		((0, 0), (0.5, 0.5), (1, 0)),
		((0, 0), (0.5, 0.5), (0, 1)),
	) {
		box(rect(diagram(
			debug: 1,
			axes: axes,
			for coord in coords {
				node(coord, raw(repr(coord)), stroke: 1pt)
			}
		)))
	}
	pagebreak(weak: true)
}
