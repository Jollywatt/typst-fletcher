#import "@preview/fletcher:0.5.3" as fletcher: diagram, node, edge
#set page(width: auto, height: auto, margin: 5mm, fill: white)


#diagram(
	node-corner-radius: 4pt,
	node((0,0), $S a$),
	node((1,0), $T b$),
	node((0,1), $S a'$),
	node((1,1), $T b'$),
	edge((0,0), (1,0), "->", $f$),
	edge((0,1), (1,1), "->", $f'$),
	edge((0,0), (0,1), "->", $alpha$),
	edge((1,0), (1,1), "->", $beta$),

	node((2,0), $(a, b, f)$),
	edge("->", text(0.8em, $(alpha, beta)$)),
	node((2,1), $(a', b', f')$),

	node((0,2), $S a$),
	edge("->", $f$),
	node((1,2), $T b$),

	node((2,2), $(a, b, f)$),

	{
		let tint(c) = (stroke: c, fill: rgb(..c.components().slice(0,3), 5%), inset: 8pt)
		node(enclose: ((0,0), (1,1)), ..tint(teal), name: <big>)
		node(enclose: ((2,0), (2,1)), ..tint(teal), name: <tall>)
		node(enclose: ((0,2), (1,2)), ..tint(green), name: <wide>)
		node(enclose: ((2,2),), ..tint(green), name: <small>)
	},

	edge(<big>, <tall>, "<==>", stroke: teal + .75pt),
	edge(<wide>, <small>, "<==>", stroke: green + .75pt),
	edge(<big>, <wide>, "<=>", stroke: .75pt),
	edge(<tall>, <small>, "<=>", stroke: .75pt),
)