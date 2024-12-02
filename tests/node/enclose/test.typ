#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(
	node-stroke: 1pt,
	{
		node((0,0), [Hello], name: <en>)
		node((2,0), [Bonjour], name: <fr>)
		node((1,1), [Quack], name: <dk>)

		let a = (inset: 5pt, corner-radius: 5pt)
		node(enclose: (<en>, <fr>), ..a, stroke: teal, name: <group1>)
		node((0,0), enclose: (<en>, <dk>), ..a, stroke: orange, name: <group2>)
		edge(<group1>, <dk>, stroke: teal, "->")
		edge(<group2>, <fr>, stroke: orange, "->")
	},
)

#pagebreak()

#diagram(
	node-stroke: .7pt,
	edge-stroke: .7pt,
	spacing: 10pt,

	node((0,1), [volume]),
	node((0,2), [gain]),
	node((0,3), [fine]),

	edge((0,1), "r", "->", snap-to: (auto, <bar>)),
	edge((0,2), "r", "->", snap-to: (auto, <bar>)),
	edge((0,3), "r", "->", snap-to: (auto, <bar>)),

	// a node that encloses/spans multiple grid points,
	node($Sigma$, enclose: ((1,1), (1,3)), inset: 10pt, name: <bar>),

	edge((1,1), "r,u", "->", snap-to: (<bar>, auto)),
	node((2,0), $ times $, radius: 8pt),
)

#pagebreak()

#diagram({
	let c = rgb(..orange.components().slice(0,3), 50%)
	edge("l", "o-o")
	node((0,0), `R1`, radius: 5mm, fill: c)
	edge("o-o")
	node((1,0), `R2`, radius: 5mm, fill: c)
	edge("u", "o-o")
	edge("r", "o-o")
	node(`L7`, enclose: ((0,0), (1,0)), stroke: red + 0.5pt,
		extrude: (0,2), snap: false)
})

#pagebreak()

#diagram(
	node-stroke: .7pt,
	edge-stroke: .7pt,
	node((0,1), $ a $, radius: 10pt),
	node((0,2), $ b $, radius: 10pt),
	edge((0,1), "r", "->", snap-to: (auto, <bar>)),
	edge((0,2), "r", "->", snap-to: (auto, <bar>)),
	node($ Sigma $, enclose: ((1,1), (1,2)), name: <bar>),
	edge((1,1), "r", "->", snap-to: (<bar>, auto)),
	edge((1,2), "r", "->", snap-to: (<bar>, auto)),
	node((2,1), $ x $, radius: 10pt),
	node((2,2), $ y $, radius: 10pt),
)

#pagebreak()

Enclosing absolutely positioned nodes

#diagram(
	node-inset: 0pt,
	for i in range(7) {
		let a = 30deg*i
		node((a, 1cm), [#i], name: str(i))

		let labels = range(i + 1).map(str).map(label)
		node(enclose: labels, fill: blue.transparentize(70%))
	},
)


#pagebreak()

Enclosing CeTZ coordinates

#diagram({
	node((0,0), [1], name: <1>)
	node((1,1), [2], name: <2>)
	node(enclose: ((0,0), <2>), fill: teal, inset: 0pt)
	node(enclose: ((<1>, 50%, <2>), (rel: (0pt, 0pt), to: <2>)), fill: yellow, inset: 0pt)
})
