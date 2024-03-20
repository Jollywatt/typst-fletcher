#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

= Hiding

#rect(inset: 0pt, diagram({
	node((0,0), [Can't see me])
	edge("->", bend: 20deg)
	node((1,1), [Can see me])
}))

#rect(inset: 0pt, diagram({
	fletcher.hide({
		node((0,0), [Can't see me])
		edge("->", bend: 20deg)
	})
	node((1,1), [Can see me])
}))
