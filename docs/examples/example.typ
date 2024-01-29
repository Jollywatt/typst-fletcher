#import "/src/exports.typ" as fletcher: node, edge

#for dark-mode in (false, true) [

#let c = if dark-mode { white } else { black }
#set page(width: 22cm, height: 9cm, margin: 1cm)

#set text(fill: white) if dark-mode


#show: scale.with(200%, origin: top + left)

#let edge = edge.with(stroke: c)

#stack(
	dir: ltr,
	spacing: 1cm,

fletcher.diagram(cell-size: 15mm, crossing-fill: none, $
	G edge(f, ->) edge("d", pi, ->>) & im(f) \
	G slash ker(f) edge("ur", tilde(f), "hook-->")
$),

fletcher.diagram(
	node-stroke: c,
	node-fill: rgb("aafa"),
	node-outset: 2pt,
	axes: (ltr, btt),
	node((0,0), `typst`),
	node((1,0), "A"),
	node((2.5,0), "B", stroke: c + 2pt),
	node((2,1), "C", extrude: (+1, -1)),

	for i in range(3) {
		edge((0,0), (1,0), bend: (i - 1)*30deg)
	},
	edge((1,0), (2,1), "..}>", corner: right),
	edge((1,0), (2.5,0), "-||-|>", bend: -0deg),
),

)

]