#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram({
	edge((0,1), (1,0))
	edge((0,0), (1,1), "crossing")
	edge((2,1), (3,0), "|-|", bend: -20deg)
	edge((2,0), (3,1), "<=>", crossing: true, bend: 20deg)
})
