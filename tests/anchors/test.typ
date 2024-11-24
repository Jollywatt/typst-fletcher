#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(
	node-stroke: blue,
	node((0,0), name: "foo")[Foo],
	node((rel: (2,-1), to: <foo>), name: "bar")[Bar],
	node(enclose: (<foo>, <bar>), stroke: red),

	edge(<foo.north-east>, <bar.south-west>, stroke: blue + 1pt),
	edge(<foo.north>, "latex-latex", <bar.west>, bend: 45deg),
	edge(
		(name: "foo", anchor: -45deg),
		"x-->",
		<bar.south-east>,
		corner: left,
	)
)

#pagebreak()

#diagram(
	node-stroke: yellow,
	node((1,1), `45deg`, shape: circle, name: "a"),
	edge((name: "a", anchor: 45deg), "u", "->", bend: -20deg),
	node((0,1), `"north"`, shape: fletcher.shapes.diamond, name: <b>),
	node((1,0), `"south-west"`, shape: fletcher.shapes.triangle, name: <c>),
	edge(<b.north>, "..", <c.south-west>),

)

#pagebreak()

#let a = 0deg
#for (name, shape) in dictionary(fletcher.shapes) {
	if type(shape) != function { continue }
	show raw: set text(0.6em)
	diagram(
		node((0,0), name, shape: shape, fill: color.hsv(a, 50%, 100%), name: <A>),
		node(<A.north>, `N`),
		node(<A.north-east>, `NE`),
		node(<A.east>, `E`),
		node(<A.south-east>, `SE`),
		node(<A.south>, `S`),
		node(<A.south-west>, `SW`),
		node(<A.west>, `W`),
		node(<A.north-west>, `NW`),
	)
	linebreak()
	a += 27deg
}

#pagebreak()

#diagram(
	node-stroke: yellow,
	node((1,1), `45deg`, shape: circle, name: "a"),
	edge((name: "a", anchor: 45deg), "u", "->", bend: -20deg),
	node((0,1), `"north"`, shape: fletcher.shapes.diamond, name: <b>),
	node((1,0), `"south-west"`, shape: fletcher.shapes.triangle, name: <c>),
	edge(<b.north>, "..", <c.south-west>),

)


#pagebreak()

Node positions depending on other nodes' anchors

#diagram(
	node((0,0), [Alpha], name: <A>, fill: green),
	node(<A.north-east>, $ times.circle $),
	edge(<A>, "->", auto),
	node((rel: (0pt, -20pt), to: <A.south>), $ plus.circle $, inset: 0pt, name: <B>),
	node((rel: (10pt, 0pt), to: <B>), $ f $),
)