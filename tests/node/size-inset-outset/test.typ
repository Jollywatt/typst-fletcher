#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#let cm-square = box(width: 5mm, height: 5mm, fill: black)

What `5mm` inset should look like:

#rect(fill: green, inset: 5mm, cm-square)

A diagram node with `5mm` inset:

#diagram(node((0,0), cm-square, shape: rect, inset: 5mm, fill: green))

A diagram node with `5mm` outset:

#diagram(
	spacing: 1cm,
	node((0,0), cm-square, shape: rect, inset: 0pt, outset: 5mm, fill: blue),
	edge("->"),
)

#pagebreak()

Circular insets:

#diagram(
	node-stroke: 1pt,
	node((0,0), $A$, inset: 0pt, shape: rect),
	node((1,0), $A$, inset: 0pt),
	node((0,1), $A$, shape: rect),
	node((1,1), $A$),
	node((0,2), $A B C D E$, shape: rect),
	node((1,2), $A B C D E$, shape: circle),
)

#pagebreak()

Explicit node size:

#circle(radius: 1cm, align(center + horizon, `1cm`))
#diagram(
	node((0,0), `1cm`, stroke: 1pt, radius: 1cm, inset: 1cm, shape: "circle"),
	node((0,1), [width], stroke: 1pt, width: 2cm),
	node((1,1), [height], height: 4em, inset: 0pt, fill: blue.lighten(50%)),
	node((2,1), [both], width: 5em, height: 5em, stroke: 2pt),
)
