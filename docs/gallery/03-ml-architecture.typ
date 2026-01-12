#import "@preview/fletcher:0.6.0" as fletcher: diagram, node, edge
#import fletcher.shapes: house, hexagon
#set text(font: "New Computer Modern")

#let blob(pos, label, tint: white, ..args) = node(
	pos, align(center, label),
	width: 28mm,
	fill: tint.lighten(60%),
	stroke: 1pt + tint.darken(20%),
	corner-radius: 5pt,
	..args,
)

#diagram(
	spacing: 15pt,
	edge-stroke: 1pt,
	edge-corner-radius: 5pt,
	mark-scale: 70%,

	blob((0,1), [Add & Norm], tint: yellow, shape: "hexagon"),
	edge(),
	blob((0,2), [Multi-Head\ Attention], <mha>, tint: orange),
	blob((0,4), [Input], <in>, shape: "house", angle: 30deg,
		width: auto, tint: red),

	edge(<in>, <mha>, "-|>"),
	edge(<in>, "-|>", (rel: (+0.3,0), to: <mha>), corner: "|-|"),
	edge(<in>, "-|>", (rel: (-0.3,0), to: <mha>), corner: "|-|"),

	edge((0,4), "lu,uu,r", "--|>"),
	edge((0,1), (0,0.35), "r", (1,3), "r,u", "-|>"),
	edge((1,2), "d,rr,uu,l", "--|>"),

	blob((2,0), [Softmax], tint: green),
	edge("<|-"),
	blob((2,1), [Add & Norm], tint: yellow, shape: "hexagon"),
	edge(),
	blob((2,2), [Feed\ Forward], tint: blue),
)
