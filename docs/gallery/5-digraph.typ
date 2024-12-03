#import "@preview/fletcher:0.5.4" as fletcher: diagram, node, edge, shapes
#set page(width: auto, height: auto, margin: 5mm, fill: white)

#let nodes = ("A", "B", "C", "D", "E", "F", "G")
#let edges = (
	(3, 2),
	(4, 1),
	(1, 4),
	(0, 4),
	(3, 0),
	(5, 6),
	(6, 5),
)

#diagram({
	for (i, n) in nodes.enumerate() {
		let θ = 90deg - i*360deg/nodes.len()
		node((θ, 18mm), n, stroke: 0.5pt, name: str(i))
	}
	for (from, to) in edges {
		let bend = if (to, from) in edges { 10deg } else { 0deg }
		// refer to nodes by label, e.g., <1>
		edge(label(str(from)), label(str(to)), "-|>", bend: bend)
	}
})