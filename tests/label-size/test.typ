#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge


#diagram(
	label-size: 0.8em,
	label-sep: 2pt,
	node((0, 0), [A]),
	edge("rd", $h$),
	edge($f$),
	node((1, 0), [B]),
	edge($g$),
	node((1, 1), [C]),
)