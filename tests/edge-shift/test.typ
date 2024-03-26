#set page(width: 5cm, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge


#(3.4pt, 0.1).map(shift => [
	Edge shift by #type(shift):

	#diagram(
		node((0,0), $A$),
		edge((0,0), (1,0), "->", shift: +shift),
		edge((0,0), (1,0), "<-", shift: -shift),
		node((1,0), $B$),
	)

	#diagram(
		node((0,0), $A$),
		edge((0,0), (1,0), "->", shift: +shift, bend: 40deg),
		edge((0,0), (1,0), "<-", shift: -shift, bend: 40deg),
		node((1,0), $B$),
	)

	#diagram(
		node-stroke: 1pt,
		node((0,0), $A$),
		edge((0,0), (1,0), (1,1), "->", shift: +shift),
		edge((0,0), (1,0), (1,1), "->", shift: -shift),
		edge((0,0), (1,1), "->", corner: left, shift: +shift),
		edge((0,0), (1,1), "->", corner: left, shift: -shift),
		node((1,1), $A B C$),
	)
	
]).join(pagebreak())

