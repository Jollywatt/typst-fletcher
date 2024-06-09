#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge


Polar coordinates

#diagram(
	node-fill: teal.transparentize(60%),
	{
		node((0,0), [hello], name: <center>)
		let n = 16
		for i in range(0, n) {
			node((rel: (i*360deg/n, 15mm), to: <center>), $ ast $, fill: none, inset: 0pt)
			edge(<center>, "<-")
		}
	}
)

#pagebreak()

Perpendicular coordinates

#diagram(
	node-defocus: 0,
	node((100,100), $A$, name: <a>),
	edge("-"),
	node((rel: (1,1)), $B$, name: <b>),
	node((<a>, "|-", <b>), $A tack B$, name: <c>),
	edge(".."),
	node((<a>, "-|", <b>), $A tack.l B$, name: <c>),
)
