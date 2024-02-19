#import fletcher.shapes: house
#set text(font: "Fira Sans")
#set text(black) // hide

#let blob(pos, label, tint: white, ..args) = node(
	pos, align(center, text(tint.darken(60%), label)),
	width: 25mm,
	corner-radius: 5pt,
	fill: tint.lighten(70%),
	stroke: 1pt + tint.lighten(20%),
	..args,
)

#fletcher.diagram(
	edge-stroke: 1pt/*<*/ + fg/*>*/,
	mark-scale: 70%,
	cell-size: (5mm, 10mm),
	spacing: 8pt,
	edge-corner-radius: 6pt,

	blob((0,1), [Add & Norm], tint: yellow),
	edge(),
	blob((0,2), [Multi-Head\ Attention], tint: orange),
	edge("<|-"),
	blob((0,4), [Input], shape: house.with(angle: 30deg),
		width: auto, tint: red),

	for x in (-.4, +.4) {
		edge((0,2.8), (x,2.8), (x,2), "-|>")
	},

	edge((0,3), "l,uu,r", "--|>"),
	edge((0,1), (0, 0.35), "r", (1,3), "r,u", "-|>"),
	edge((1,2), "d,rr,uu,l", "--|>"),

	blob((2,0), [Softmax], tint: green),
	edge("<|-"),
	blob((2,1), [Add & Norm], tint: yellow),
	edge(),
	blob((2,2), [Feed\ Forward], tint: blue),
)