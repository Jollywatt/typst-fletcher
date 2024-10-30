#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge
#import "/src/marks.typ": *

#context for stealth in (0.8, 0.5, 0.3, 0, -0.5, -1, -1.5) [
	#pagebreak(weak: true)

	#let mark = fletcher.MARKS.get().stealth

	#mark-debug(mark + (stealth: stealth))
	#mark-demo(mark + (stealth: stealth))

	#diagram(edge(marks: (mark + (stealth: stealth), mark + (stealth: stealth))))
	#diagram(edge(bend: 60deg, marks: (mark + (stealth: stealth), mark + (stealth: stealth))))
]
