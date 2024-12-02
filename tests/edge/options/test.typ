#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

Explicit named arguments versus implicit positional arguments.

Each row should be the same thing repeated.

#let ab = node((0,0), $A$) + node((1,0), $B$)
#grid(
	columns: (3cm,)*3,

	diagram(ab, edge((0,0), (1,0), marks: "->")),
	diagram(ab, edge((0,0), (1,0), "->")),
	diagram($A edge(->) & B$),

	diagram(ab, edge((0,0), (1,0), label: $pi$)),
	diagram(ab, edge((0,0), (1,0), $pi$)),
	diagram($A edge(pi) & B$),

	diagram(ab, edge((0,0), (1,0), marks: "|->", label: $tau$)),
	diagram(ab, edge((0,0), (1,0), "|->", $tau$)),
	diagram($A edge(tau, |->) & B$),

	diagram(ab, edge((0,0), (1,0), marks: "->>", label: $+$)),
	diagram(ab, edge((0,0), (1,0), "->>", $+$)),
	diagram($A edge(->>, +) & B$),
)

#pagebreak()

#diagram(
	axes: (ltr, btt),
	edge((0,0), (1,1), "->", "double", bend: 45deg),
	edge((1,0), (0,1), "->>", "crossing"),
	edge((1,1), (2,1), $f$, "|->"),
	edge((0,0), (1,0), "-", "dashed"),
)

#pagebreak()

Diagram and edge stroke options.

$

#block(diagram(
	edge-stroke: red,
	edge(stroke: 2pt),
))
&equiv
#line(stroke: (paint: red, thickness: 2pt, cap: "round"))
\
#block(diagram(
	edge-stroke: 2pt,
	edge(stroke: (cap: "butt"))
))
&equiv
#line(stroke: 2pt)
\
#block(diagram(
	edge-stroke: 1pt + green,
	edge(dash: "dashed")
))
&equiv
#line(stroke: (paint: green, dash: "dashed", cap: "round"))
\
#block(diagram(
	edge(stroke: none)
))
&equiv & "(none)"

$

