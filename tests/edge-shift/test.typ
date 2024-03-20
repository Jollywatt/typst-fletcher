#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(
	node((0,0), $A$),
	edge((0,0), (1,0), "->", shift: +3.4pt),
	edge((0,0), (1,0), "<-", shift: -3.4pt),
	node((1,0), $B$),
)

#diagram(
	node((0,0), $A$),
	edge((0,0), (1,0), "->", shift: +3.4pt, bend: 40deg),
	edge((0,0), (1,0), "<-", shift: -3.4pt, bend: 40deg),
	node((1,0), $B$),
)

#diagram(
	node-stroke: 1pt,
	node((0,0), $A$),
	edge((0,0), (1,0), (1,1), "->", shift: +4pt),
	edge((0,0), (1,0), (1,1), "->", shift: -4pt),
	edge((0,0), (1,1), "->", corner: left, shift: +4pt),
	edge((0,0), (1,1), "->", corner: left, shift: -4pt),
	node((1,1), $B C$),
)

#pagebreak()

= Off-center edges

#diagram(debug: 3, {
	node((0,0), $A$)
	node((1,0), $B$)
	for y in (.1, 0, -.1) {
		edge((0,y), "r", "->")
	}
	node((0,1), `a wide node`, stroke: .1pt)
	node((1,2), $C$)
	edge((0,1), (1,2), "->", bend: 35deg)
	edge((0.2,1), (1,2), "->>", corner: left)
	edge((0,1), "d", (rel: (-.4,0)), "u", "=>")

})

