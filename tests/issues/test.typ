#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#show link: it => {
	pagebreak(weak: true)
	underline(it)
}

https://github.com/Jollywatt/typst-fletcher/issues/64

#diagram($A times B$)
#par(justify: true, diagram($A times B$))


https://github.com/Jollywatt/typst-fletcher/issues/74

#for bend in (left, right) {
	diagram(
		node((0, 0), [A]),
		for side in (left, right) {
			edge(
				"->",
				corner: bend,
				label: side,
				label-pos: 1em,
				label-side: side,
			)
		},
		node((1, 1), [B]),
	) 
}

https://github.com/Jollywatt/typst-fletcher/issues/81

#diagram(
	debug: 3,
	node((0,0), [1], fill: red, name: <1>),
	node((1,0), [2], fill: blue, name: <2>),
	node([],enclose: (<1>,<2>), name: <3>, stroke: black),
	edge(<1.south>, "d"),
	edge(<3.south>,"d")
)

https://github.com/Jollywatt/typst-fletcher/issues/38

#align(center, diagram(
	node((0, 0), $1$),
	edge("->", [this is a very long label], floating: true),
	node((0, 1), $2$),
))
#align(center, diagram(
	node((0, 0), $1$),
	edge("->"),
	node((0, 1), $2$),
))

https://github.com/Jollywatt/typst-fletcher/issues/89

#import fletcher.shapes

#diagram(
	node-stroke: 1pt,
	node((0,0), shape: shapes.ellipse, [Test])
)

https://github.com/Jollywatt/typst-fletcher/issues/93

#box(width: 9cm)[
	Test anchors on enclose nodes whose position is specified with absolute coordinates.
]

#diagram(

	node((0, 0), [Origin], name: <o>),
	node((rel: (2cm, 1cm), to: <o>), $+1$, name: <p>),
	node((rel: (2cm, 0cm), to: <o>), $0$, name: <z>),
	node((rel: (2cm, -1cm), to: <o>), $-1$, name: <m>),

	edge(<o>, auto, "->"),
	node(enclose: (<p>, <m>, <z>), name: <enclose>, stroke: black),

	for anchor in (
		"north",
		"north-east",
		"east",
		"south-east",
		"south",
		"south-west",
		"west",
		"north-west",
		"center",
	) {
		let pos = (name: <enclose>, anchor: anchor)
		node(pos, text(red, {
			$ dot.circle $
			place(text(0.4em, raw(anchor)))
		}))
	}
)

https://github.com/Jollywatt/typst-fletcher/issues/100

#table(
	columns: 3,
	..range(1, 10).map(x => {
		diagram(
			spacing: (2mm, 6mm),

			node-stroke: 1pt,

			node((0, 0), "aa"   , shape: circle, name: <a>),
			node((1, 1), "d" * x, shape: circle),
			node((0, 2), "bb"   , shape: circle, name: <b>),

			edge(<b>, "r,r,u,u", <a>),
		)
	})
)

https://github.com/Jollywatt/typst-fletcher/issues/105

#diagram(
	node-stroke: 0.2pt,
	edge-stroke: 1pt,
	node-corner-radius: 5pt,
	{
		node((1, 1), [x], shape: rect, name: <x>)
		node((<x.south>, "-|", <x.west>), radius: 1pt, fill: blue, stroke: none, name: <y>)
		for x in range(30) {
			edge((<x.south>, "-|", <x.west>), (rel: (0pt,  x*1pt)), [xedge])  // caused division by zero
		}
	}
)

https://github.com/Jollywatt/typst-fletcher/issues/113

#diagram(
  node-stroke: 1pt,
  cell-size: 3cm,
  node((0, 0), [A], shape: circle, name: <A>),
  node(enclose: (<A>,), [], inset: 1cm, fill: blue.lighten(50%), name: <Group>),
  node((0, 1), [B], name: <B>),
  node((<Group.south>, 50%, <B.north>), $ + $)
)
