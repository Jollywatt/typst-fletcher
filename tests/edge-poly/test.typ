#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#for radius in (none, 0pt, 10pt) {
	diagram(
		// debug: 4,
		mark-scale: 150%,
		node((0,0), $A$),
		edge(">->", vertices: (
			(0,0),
			(1.1,0),
			(1,1),
			(3,2),
			(4,1),
			(1.3,2),
			(2,0),
			(3,0),
			(2,1),
		), kind: "poly",
			corner-radius: radius,
			extrude: (4, 0, -4)
		),
		node((2,1), $B$),
	)
}

#pagebreak()

#for dash in ("dashed", "loosely-dashed", "dotted") {
	diagram(
		edge(
			"r,ddd,r,u,ll,u,rr",
			"<->",
			corner-radius: 5mm,
			stroke: (dash: dash)
		)
	)
}
