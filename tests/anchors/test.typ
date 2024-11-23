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
	node((4,4), "Circle", shape: circle, name: "a"),
	edge((name: "a", anchor: 45deg), "ur,r"),
	node((4,5), "Thing", shape: fletcher.shapes.parallelogram, name: <b>),
	edge(<b>, "ru")

)