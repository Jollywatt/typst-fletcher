#import "node.typ": node
#import "diagram.typ": interpret-diagram-args, compute-grid

#let compute-node-sizes(nodes) = nodes.map(node => {
	let (width, height) = measure(node.label)
	node.size = (width, height)
	node
})
#let node-to-cetz(node) = {

}

#let diagram(..args) = {
	let (nodes, edges) = interpret-diagram-args(args)

	let options = (
		axes: (ltr, ttb),
		spacing: (0pt, 0pt),
		cell-size: (0pt, 0pt),
	)

	context {
		let nodes = compute-node-sizes(nodes)
		let grid = compute-grid(nodes, edges, options)
	}
}
