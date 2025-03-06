#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#block(inset: (y: 3mm))[
	#for debug in range(4) [
		This is an inline #diagram($A edge("->") & B$, debug: debug) diagram.

	]
]