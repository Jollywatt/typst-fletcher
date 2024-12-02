#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#for bend in (0deg, 30deg) {
	[`label-angle` shown in center]
 	grid(
		columns: 2,
		gutter: 5mm,
		..(left, right, top, bottom, auto).map(angle => diagram(
			// debug: 2,
			spacing: 2cm,
			node((0,0))[#angle],
			(
				"r",
				"ru",
				"u",
				"ul",
				"l",
				"ld",
				"d",
				"dr",
			).map(to => {
				edge(
					to,
					"-|>",
					$ pi r^2 $,
					label-angle: angle,
					label-side: center,
					bend: bend,
					label-pos: 0.3,
				)
				for side in (left, right) {
					edge(
						to,
						stroke: none,
						text(0.8em)[#side],
						label-angle: angle,
						label-side: side,
						bend: bend,
						label-pos: 0.8,
					)
				}
			})
		)),
	)
	pagebreak()
}

#diagram(
	spacing: 2cm,
	node((0, 0), [#auto]),
	(
		"rr",
		"rrd",
		"rdd",
		"dd",
		"ldd",
		"lld",
		"ll",
		"llu",
		"uul",
		"uur",
		"uu",
		"urr",
	).map(d => edge(d, "->", $sqrt(a^2 + b^2)$, label-angle: auto, center))
)
