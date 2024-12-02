#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#for (i, a) in ("->", "=>", "==>").enumerate() [
	Diagram #diagram(
		node-inset: 2.5pt,
		label-sep: 1pt + i*1pt,
		node((0, -i), $A$),
		edge((0, -i), (1, -i), text(0.6em, $f$), a),
		node((1, -i), $B$),
	) and equation #($A -> B$, $A => B$, $A arrow.triple B$).at(i). \
]


The formula is #diagram($#[Hello] edge(->) & #[World]$)!
