// https://xkcd.com/1195/
#import fletcher.shapes: diamond
#set text(font: "Comic Neue", weight: 600)

#diagram(
	node-stroke: 1pt/*darkmode*/ + white/*end*/,
	edge-stroke: 1pt/*darkmode*/ + white/*end*/,
	crossing-fill: white, // darkmode
	node((0,0), [Start], corner-radius: 2pt, extrude: (0, 3)),
	edge("-|>"),
	node((0,1), align(center)[
		Hey, wait,\ this flowchart\ is a trap!
	], shape: diamond),
	edge("d,r,u,l", "-|>", [Yes], label-pos: 0.1)
)