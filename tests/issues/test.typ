#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#show link: it => {
	pagebreak(weak: true)
	underline(it)
}

https://github.com/Jollywatt/typst-fletcher/issues/64

#diagram($A times B$)
#par(justify: true, diagram($A times B$))


https://github.com/Jollywatt/typst-fletcher/issues/74

#for bend in (left, right) {
	diagram(
		node((0, 0), [A]),
		for side in (left, right) {
			edge(
				"->",
				corner: bend,
				label: side,
				label-pos: 1em,
				label-side: side,
			)
		},
		node((1, 1), [B]),
	) 
}
