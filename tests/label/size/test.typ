#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge


#diagram(
	label-size: 0.8em,
	label-sep: 2pt,
	node((0, 0), [A]),
	edge("rd", $h$, right),
	edge($f$),
	node((1, 0), [B]),
	edge($g$, left),
	node((1, 1), [C]),
)

#pagebreak()


#diagram(label-size: 0.8em, $
	f edge("d", ->) edge(->, #$ f $) & f \
	f edge("ur", ->)
$)