#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#let around = (
	(-1,+1), ( 0,+1), (+1,+1),
	(-1, 0),          (+1, 0),
	(-1,-1), ( 0,-1), (+1,-1),
)

#grid(
	columns: 2,
	..(-10, -1, -.25, 0, +.25, +1, +10).map(defocus => {
		((7em, 3em), (3em, 7em)).map(((w, h)) => {
			align(center + horizon, diagram(
				node-defocus: defocus,
				node-inset: 0pt,
			{
				node((0,0), rect(width: w, height: h, inset: 0pt, align(center + horizon)[#defocus]))
				for p in around {
					edge(p, (0,0))
				}
			}))
		})
	}).join()
)

