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

#pagebreak()

Nested enclose nodes

#diagram(node-inset: 2mm, {
	node((0,0), circle(fill: red))
	node((rel: (15mm, 8mm)), circle(fill: blue, radius: 2mm), name: <1>)
	node(enclose: ((0,0), <1>), stroke: 1pt, name: <inner>, corner-radius: 2mm)
	node((1,.7), circle(fill: green), name: <2>)
	node(enclose: (<inner>, <2>), stroke: 1pt, corner-radius: 4mm, name: <outer>)
	node((-1,0), circle(fill: yellow, radius: 2mm), name: <3>)
	node(enclose: (<outer>, <3>), stroke: 1pt, corner-radius: 6mm, name: <universe>)
})

#pagebreak()

#import fletcher.shapes
#diagram(
	node-inset: 4pt,
	node-fill: teal,
	node((0,0), $A$, name: <A>),
	node((2,0), $B$, name: <B>),
	node((2,1), $C$, name: <C>),
	node(enclose: (<A>, <B>), shape: shapes.brace.with(label: $oo$)),
	node(enclose: (<C>, <B>), shape: shapes.bracket.with(dir: right, sep: 1em, label: [label])),
	node(enclose: (<A>, <C>, <B>), shape: shapes.stretched-glyph.with(glyph: $integral$, dir: left)),
	node(enclose: <C>, shape: shapes.paren.with(dir: left, label: [X], label-sep: 0mm))
)