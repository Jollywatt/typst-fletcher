#set page(width: 6cm, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

Compare to $->$, $=>$, $arrow.triple$, $arrow.twohead$, $arrow.hook$, $|->$.

#let (result-color, target-color) = (rgb("f066"), rgb("0bf5"))

#text(result-color)[Our output] versus #text(target-color)[reference symbol] in default math font.
\
#set text(10em)
#diagram(
	spacing: 0.825em,
	crossing-fill: none,
	label-sep: 0.0915em,
	edge-stroke: result-color,
	for (i, a) in (
		("->", $->$,
			0em, 0.029),
		("=>", $=>$,
			0em, 0.02),
		("==>", $arrow.triple$,
			0em, 0.048),
		("->>", $->>$,
			0em, 0.053),
		("hook->", $arrow.hook$,
			0.024em, 0.057),
		("|->", $|->$,
			0em, 0.004),
	).enumerate() {
		let (marks, label, δl, δr) = a
		edge(
			(0, i), (1 + δr,i),
			align(horizon, box(height: 0em, move(dx: δl - 0.28em, text(target-color, label)))),
			marks: marks,
			label-anchor: "west",
			label-pos: 0,
		)
	},
)