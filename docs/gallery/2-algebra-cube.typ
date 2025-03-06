#import "@preview/fletcher:0.5.7" as fletcher: diagram, node, edge
#set page(width: auto, height: auto, margin: 5mm, fill: white)

#diagram(
	node-defocus: 0,
	spacing: (1cm, 2cm),
	edge-stroke: 1pt,
	crossing-thickness: 5,
	mark-scale: 70%,
	node-fill: luma(97%),
	node-outset: 3pt,
	node((0,0), "magma"),

	node((-1,1), "semigroup"),
	node(( 0,1), "unital magma"),
	node((+1,1), "quasigroup"),

	node((-1,2), "monoid"),
	node(( 0,2), "inverse semigroup"),
	node((+1,2), "loop"),

	node(( 0,3), "group"),

	{
		let quad(a, b, label, paint, ..args) = {
			paint = paint.darken(25%)
			edge(a, b, text(paint, label), "-|>", stroke: paint, label-side: center, ..args)
		}

		quad((0,0), (-1,1), "Assoc", blue)
		quad((0,1), (-1,2), "Assoc", blue, label-pos: 0.3)
		quad((1,2), (0,3), "Assoc", blue)

		quad((0,0), (0,1), "Id", red)
		quad((-1,1), (-1,2), "Id", red, label-pos: 0.3)
		quad((+1,1), (+1,2), "Id", red, label-pos: 0.3)
		quad((0,2), (0,3), "Id", red)

		quad((0,0), (1,1), "Div", yellow)
		quad((-1,1), (0,2), "Div", yellow, label-pos: 0.3, "crossing")

		quad((-1,2), (0,3), "Inv", green)
		quad((0,1), (+1,2), "Inv", green, label-pos: 0.3)

		quad((1,1), (0,2), "Assoc", blue, label-pos: 0.3, "crossing")
	},
)
