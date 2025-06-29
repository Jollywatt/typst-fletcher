#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(spacing: 2cm, {
	let (A, B) = ((0,0), (1,0))
	node(A, $cal(A)$)
	node(B, $cal(B)$)
	edge(A, B, $F$, "->", bend: +35deg, name: <A>)
	edge(A, B, $G$, "->", bend: -35deg, name: <B>)
	edge(<A>, <B>, $alpha$, "=>")
})

#pagebreak()

#diagram({
	node[A]
	edge(name: <e>)
	node((1,1))[B]

	node(<e>, fill: yellow, name: <C>)[node-on-edge]
	node(<C.north-east>, $ * $)
})