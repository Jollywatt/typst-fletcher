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
			0em, 0),
		("=>", $=>$,
			0em, -0.01),
		("==>", $arrow.triple$,
			0em, 0.017),
		("->>", $->>$,
			0em, 0.021),
		("hook->", $arrow.hook$,
			0.005em, 0.006),
		("|->", $|->$,
			0em, -.023),
	).enumerate() {
		let (marks, label, δl, δr) = a
		edge(
			(0, i), (1 + δr,i),
			move(dx: δl - 0.48em, text(target-color, label)),
			marks: marks,
			label-anchor: "west",
			label-pos: 0,
		)
	},
)