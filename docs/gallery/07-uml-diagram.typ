#import "@preview/fletcher:0.6.0" as fletcher: diagram, node, edge

#diagram(
	spacing: (18mm, 10mm),
	node-stroke: luma(80%),
	axes: (ltr, ttb),
	node((0.5,0), [*Diagram*], name: <d>),
	node((0,1), [*Node*], name: <n>),
	node((1,1), [*Edge*], name: <e>),

	edge(<d>, <n>, corner: "|-|",  "1!-n!"),
	edge(<d>, <e>, corner: "|-|",  "1!-n?"),

	edge("1!-n?"),

	node((1,2), [*Mark*], name: <m>),

	edge(<e>, "-|>", <n>, stroke: teal, label: text(teal)[snap], left),

	edge(<n.north-west>, <d.west>, "-|>", bend: 45deg, stroke: orange, text(orange)[layout], label-angle: auto, snap-method: "move")
)
