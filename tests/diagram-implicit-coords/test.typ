#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(edge((0,0), (1,0), [label], "->"))
#diagram(edge((1,0), [label], "->"))
#diagram(edge([label], "->"))

#diagram(
	node((1,2), [prev]),
	edge("->", bend: 45deg),
	node((2,1), [next]),
	edge((1,2), ".."),
)