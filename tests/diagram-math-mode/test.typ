#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

= Diagrams in math mode

The following diagrams should be identical:

#diagram($
	G edge(f, ->) edge(#(0,1), pi, ->>) & im(f) \
	G slash ker(f) edge(#(1,0), tilde(f), "hook-->")
$)

#diagram(
	node((0,0), $G$),
	edge((0,0), (1,0), $f$, "->"),
	edge((0,0), (0,1), $pi$, "->>"),
	node((1,0), $im(f)$),
	node((0,1), $G slash ker(f)$),
	edge((0,1), (1,0), $tilde(f)$, "hook-->")
)


#pagebreak()

= Explicit nodes in math mode

#diagram(
	node-outset: 2pt,
	node-corner-radius: 2pt,
	$
		A edge(->) & node(sqrt(B), fill: #blue.lighten(70%), inset: #5pt) \
		node(C, stroke: #(red + .3pt), radius: #1em) edge("u", "=")
		edge(#(1,0), "..||..")
	$,
)

#diagram(
	node-stroke: 1pt,
	$ node(A B C, extrude: #(0,2)) edge(->) & pi r^2 $
)


#pagebreak()

= Relative coordinates in math mode

The following diagrams should be identical:

#diagram($
	(0,0) edge(#(0,1), #(rel: (0, -1)), ->) & // first non-relative coordinate becomes `from`...
	(1,0) edge(#(0,1), "=>") \ // ...unless it is the only coordinate, in which case it becomes `to`
	(0,1) edge(#(0,0), "dr", "..>") &
	(1,1) edge("u", "-->") // if a single relative coordinate is given, set `from: auto`
$)

#diagram(
	node((0,0), $(0,0)$),
	node((1,0), $(1,0)$),
	node((0,1), $(0,1)$),
	node((1,1), $(1,1)$),

	edge((0,1), (0,0), "->"),
	edge((1,0), (0,1), "=>"),
	edge((0,0), (1,1), "..>"),
	edge((1,1), (1,0), "-->"),
)


#pagebreak()

= Label side in math mode

#diagram(spacing: (1cm, 3mm), $
	A edge(f, #left, "->") & B \
	A edge(#center, f, "->") & B \
	A edge(f, "->", #right) & B \
$)
