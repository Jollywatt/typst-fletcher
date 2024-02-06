#import fletcher.shapes: diamond
#set text(font: "Comic Neue")

#fletcher.diagram(
	node-stroke: fg, // hide
	edge-stroke: 1pt/*<*/ + fg/*>*/,
	crossing-fill: bg, // hide
	node((0,0), [Start],
		corner-radius: 2pt, extrude: (0, 2.5)),
	edge("-|>"),
	node((0,1), align(center)[Hey, wait,\ this flowchart\ is a trap!],
		shape: diamond, inset: 45pt),
	edge("d,r,u,l", "-|>", [Yes], label-pos: 0.1)
)