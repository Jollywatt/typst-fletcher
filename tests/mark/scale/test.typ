#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge
#import "/src/marks.typ": *

#context for name in ("head", "straight", "solid", "stealth", "latex", "cone") {
	grid(
		columns: 3,
		gutter: 5mm,
		align: center + horizon,
		..(50%, 100%, 200%).map(scale => {
		

		let mark = fletcher.MARKS.get().at(name)

		(
			mark-debug(mark + (scale: scale)),
			mark-demo(mark + (scale: scale)),
			[
				#diagram(edge(marks: (mark + (scale: scale), mark + (scale: scale))))
				#diagram(edge(marks: (mark, mark), mark-scale: scale))
				#diagram(edge(marks: (mark, mark)), mark-scale: scale)

				#diagram(edge("triple", marks: (mark + (scale: scale), mark + (scale: scale))))
				#diagram(edge("triple", marks: (mark, mark), mark-scale: scale))
				#diagram(edge("triple", marks: (mark, mark)), mark-scale: scale)
			]
		)
	}).flatten())
	pagebreak()
}
