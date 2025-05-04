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

#let shapes = (
  "rect",
  "circle",
  "ellipse",
  "pill",
  "parallelogram",
  "trapezium",
  "diamond",
  "triangle",
  "house",
  "chevron",
  "hexagon",
  "octagon",
  "brace",
  "bracket",
  "paren",
)

#let a = 0deg
#for name in shapes {
	let shape = dictionary(fletcher.shapes).at(name)
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
	node((1,1), [Beta], name: <B>, fill: yellow),
	node(<A.north-east>, $ times.circle $),
	edge(<A>, "->", auto),
	node((rel: (0pt, -20pt), to: <A.south>), $ plus.circle $, inset: 0pt, name: <C>),
	node((rel: (10pt, 0pt), to: <C>), $ f $),
	edge(
		<A>,
		((), "-|", (<A.east>, 50%, <B.west>)),
		((), "|-", <B>),
		<B>,
		"..>",
	)
)

#pagebreak()

Diagram requiring two coordinate resolution passes

#diagram({
	node((0,0), $A$, name: <A>, stroke: 1pt)
	node((1,1), $B$, name: <B>, stroke: 1pt)
	node(enclose: (<A>, <B>), stroke: yellow, name: <box>, text(yellow)[enclose node\ with anchor])

	// node that depends on the anchors of an enclosing node
	node(<box.north-east>, $ plus.circle $, name: <D>, stroke: teal)

	// edge depending on 
	edge(<D.east>, "->", (rel: (2cm,0cm)), stroke: 1pt + teal)
})
