#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge
#import "/src/marks.typ": *

#for scale in (100%, 200%) [
	#pagebreak()

	#let mark = MARKS.head
	#mark-debug(mark + (scale: scale))
	#mark-demo(mark + (scale: scale))

	#diagram(edge(marks: (mark + (scale: scale), mark + (scale: scale))))
	#diagram(edge(marks: (mark, mark), mark-scale: scale))
	#diagram(edge(marks: (mark, mark)), mark-scale: scale)

	#diagram(edge("triple", marks: (mark + (scale: scale), mark + (scale: scale))))
	#diagram(edge("triple", marks: (mark, mark), mark-scale: scale))
	#diagram(edge("triple", marks: (mark, mark)), mark-scale: scale)

]