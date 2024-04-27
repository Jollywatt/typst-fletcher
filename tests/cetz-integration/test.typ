#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(
	node((0,1), $A$, stroke: 1pt),
	node((2,0), [Bézier], stroke: 1pt, shape: fletcher.shapes.diamond),
	render: (grid, nodes, edges, options) => {
		fletcher.cetz.canvas({
			fletcher.draw-diagram(grid, nodes, edges, debug: options.debug)

			let n1 = fletcher.find-node-at(nodes, (0,1))
			let n2 = fletcher.find-node-at(nodes, (2,0))

			let θ1 = 0deg
			let θ2 = -90deg

			fletcher.get-node-anchor(n1, θ1, p1 => {
				fletcher.get-node-anchor(n2, θ2, p2 => {
					let c1 = (rel: (θ1, 30pt), to: p1)
					let c2 = (rel: (θ2, 70pt), to: p2)
					fletcher.cetz.draw.bezier(p1, p2, c1, c2)
					fletcher.draw-mark("head", origin: p1, angle: 180deg, stroke: 1pt)
				})
			})

		})
	}
)
