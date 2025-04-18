#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#set page(width: auto, height: auto, margin: 5mm, fill: white)

#diagram(
	spacing: (18mm, 10mm),
	node-stroke: luma(80%),
	node((0.5,0), [*Diagram*], name: <d>),
	node((0,1), [*Node*], name: <n>),
	node((1,1), [*Edge*], name: <e>),

	edge(<d>, ((), "|-", (0,0.5)), ((), "-|", <n>), <n>, "1!-n!"),
	edge(<d>, ((), "|-", (0,0.5)), ((), "-|", <e>), <e>, "1!-n?"),


	edge("1!-n?"),

	node((1,2), [*Mark*], name: <m>),

	edge(<e>, "-|>", <n>, stroke: teal, label: text(teal)[snap], left),

	edge((rel: (-15pt, 0pt), to: <n>), <d>, "-|>", bend: 40deg, stroke: orange, text(orange)[layout], label-angle: auto)
)