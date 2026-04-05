#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#cetz.canvas({
  cetz.draw.circle((0,0), radius: 0.5, fill: green, name: "start")
  cetz.draw.circle((2,1), radius: 0.25, fill: red, name: "stop")
  edge(<start>, <stop>, "->")
  edge(<start>, <stop>, "->", bend: 90deg)
  edge(<start>, "r,d,l", <start>, "->")
})

#pagebreak()


#let fig(method) = {
	par[Edge snapping with #raw(repr(method)) method]
	diagram(
		debug: "edge.snap",
		spacing: 4pt,
		node-stroke: 1pt,
		edge-stroke: 1pt,
		node-fill: white,
		node-corner-radius: 2pt,
		edge-snap-method: method,
		node((0,0), [Sight], name: <sight>),
		node((1,0), [Sound]),
		node((2,0), [Smell], name: <smell>),
		node((0,1), [Senses], colspan: 3),
		edge((0,0), (2,0), from: -90deg, to: -90deg)
	)
}

#fig("trim")

#fig("move")

#fig(("move", "trim"))

#fig(("trim", "move"))