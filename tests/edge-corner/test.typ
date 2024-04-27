#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#let around = (
	(-1,+1), (+1,+1),
	(-1,-1), (+1,-1),
)

#for dir in (left, right) {
	pad(1mm, diagram(
		spacing: 1cm,
		node((0,0), [#dir]),
		{
			for c in around {
				node(c, $#c$)
				edge((0,0), c, $f$, marks: (
					(inherit: "head", rev: false, pos: 0),
					(inherit: "head", rev: false, pos: 0.33),
					(inherit: "head", rev: false, pos: 0.66),
					(inherit: "head", rev: false, pos: 1),
				), "double", corner: dir)
			}
		}
	))
}

#for dir in (left, right) {
	pad(1mm, diagram(
		// debug: 4,
		spacing: 1cm,
		axes: (ltr, btt),
		node((0,0), [#dir]),
		{
			for c in around {
				node(c, $#c$)
				edge((0,0), c, $f$, marks: (
					(inherit: "head", rev: false, pos: 0),
					(inherit: "head", rev: false, pos: 0.33),
					(inherit: "head", rev: false, pos: 0.66),
					(inherit: "head", rev: false, pos: 1),
				), "double", corner: dir)
			}
		}
	))
}
