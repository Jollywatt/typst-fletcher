#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(
	cell-size: 3cm,
	node((0,0), "from"),
	node((1,0), "to"),
	for θ in (0deg, 20deg, -50deg) {
		edge((0,0), (1,0), $#θ$, bend: θ, marks: (none, "head"), label-side: center)
	}
)

#pagebreak()

#for (i, to) in ((0,1), (1,0), (calc.sqrt(1/2),-calc.sqrt(1/2))).enumerate() {
	diagram(debug: 0, {
		node((0,0), $A$)
		node(to, $B$)
		let N = 6
		range(N + 1).map(x => (x/N - 0.5)*2*120deg).map(θ => edge((0,0), to, bend: θ, marks: ">->")).join()
	})
}
