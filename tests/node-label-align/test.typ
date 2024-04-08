#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(
	spacing: 5pt,
	// node-inset: 0pt,
	node((0,0), [Hi], height: 15mm, stroke: 1pt + red),
	node((1,0), align(top)[Hi], height: 15mm, stroke: 1pt + green),
	node((2,0), align(bottom)[Hi], height: 15mm, stroke: 1pt + blue),
	node((0,1), [Hi], stroke: 1pt + red),
	node((1,1), align(left)[Hi], stroke: 1pt + green),
	node((2,1), align(right)[Hi], stroke: 1pt + blue),
	node((0,2), [Hi], width: 15mm, stroke: 1pt + red),
	node((1,2), align(left)[Hi], width: 15mm, stroke: 1pt + green),
	node((2,2), align(right)[Hi], width: 15mm, stroke: 1pt + blue),
)

#pagebreak()

#diagram(
	// debug: 3,
	spacing: 5pt,
	node-fill: yellow,
	node((0,0), [Automatic width]),
	node((0,1), align(left)[Explicit width causes wrapping], width: 35mm),
)

#pagebreak()

The baseline #diagram($A edge(->) & B$) should align.