#set page(width: 15cm, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#context table(
	columns: (1fr,)*6,
	stroke: none,
	..fletcher.MARKS.get().pairs().map(((k, v)) => [
		#set align(center)
		#raw(k) \
		#diagram(edge(stroke: 1pt, marks: (v, v)))
	]),
)