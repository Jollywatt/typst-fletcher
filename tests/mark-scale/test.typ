#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge
#import "/src/marks.typ": *

#for mark in ("head", (inherit: "head", scale: 200%)) [

	#mark-debug(mark)

	#mark-demo(mark)

	#diagram(edge(marks: (mark, mark)))
	
]