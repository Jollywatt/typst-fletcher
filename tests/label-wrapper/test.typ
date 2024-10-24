#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(
	crossing-fill: blue.lighten(80%),
	edge($ f $, label-wrapper: it => rect(
		it.label, fill: it.label-fill, inset: 0pt, stroke: .1pt + blue,
	))
)

#diagram(
	label-wrapper: it => circle(
		align(center + horizon, $ #it.label $), fill: it.label-fill, inset: 1pt, stroke: blue,
		radius: 7pt,
	),
	$
	A edge(->, f) & B edge("d", ->, g, #right) \
	C edge("u", ->, i) & D edge("l", ->, j)
	$
)
