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