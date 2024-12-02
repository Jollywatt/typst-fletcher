#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge
#import "/src/marks.typ": *

#context for scale in (100%, 200%) [
	#pagebreak(weak: true)

	#let mark = fletcher.MARKS.get().head

	#mark-debug(mark + (scale: scale))
	#mark-demo(mark + (scale: scale))

	#diagram(edge(marks: (mark + (scale: scale), mark + (scale: scale))))
	#diagram(edge(marks: (mark, mark), mark-scale: scale))
	#diagram(edge(marks: (mark, mark)), mark-scale: scale)

	#diagram(edge("triple", marks: (mark + (scale: scale), mark + (scale: scale))))
	#diagram(edge("triple", marks: (mark, mark), mark-scale: scale))
	#diagram(edge("triple", marks: (mark, mark)), mark-scale: scale)

]

#pagebreak()

#diagram(mark-scale: 100%, edge("cone-latex")) \
#diagram(mark-scale: 50%, edge("cone-latex"))