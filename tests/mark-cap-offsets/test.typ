#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge
#import "/src/marks.typ": *


#context align(center, MARKS.get().values().map(mark => {
	let e = 2.5
	diagram(edge(
		(0,0), (1,0),
		marks: (mark, mark),
		extrude: (-e,0,+e)
	))
}).join(linebreak()))
