#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, shapes

#diagram(
	node-stroke: 1pt,
	node-outset: 5pt,
	axes: (ltr, ttb),
	node((0,0), $A$, radius: 5mm),
	edge("->"),
	node((1,1), [crowded], shape: shapes.house, fill: blue.lighten(90%)),
	edge("..>", bend: 30deg),
	node((0,2), $B$, shape: shapes.diamond),
	edge((0,0), "d,ru,d", "=>"),

	edge((1,1), "rd", bend: -40deg),
	node((2,2), `cool`, shape: shapes.pill),
	edge("->"),
	node((1,3), [_amazing_], shape: shapes.parallelogram),

	node((2,0), [robots], shape: shapes.hexagon),
	node((2,3), [squashed], shape: shapes.ellipse),
	edge("u", "->", bend: -30deg),

)

#pagebreak()

Diagram `node-shape` option

#diagram(
	node-shape: circle,
	node-fill: yellow,

	node((0,0), [A]),
	node((1,0), [A B C]),
)

#diagram(
	node-shape: rect,
	node-fill: orange,

	node((0,0), [A]),
	node((1,0), [A B C]),
)


#pagebreak()

#set align(center)


#for (name, shape) in dictionary(shapes) {
	if type(shape) == module { continue }
	diagram(debug: 0, node((0, 0), name, shape: shape, stroke: 1pt, extrude: (0, 2)))
	linebreak()
}

#pagebreak()

#diagram(
	node-stroke: 1pt,
	spacing: 10pt,
	node((0,0), [STOP], shape: shapes.octagon.with(truncate: 0)),
	node((1,0), [STOP], shape: shapes.octagon.with(truncate: 0.5)),
	node((2,0), [STOP], shape: shapes.octagon.with(truncate: 1)),
	node((0,1), [STOP], shape: shapes.octagon.with(truncate: 2pt)),
	node((1,1), [STOP], shape: shapes.octagon.with(truncate: 5pt)),
	node((2,1), [STOP], shape: shapes.octagon.with(truncate: 8pt)),
)


#pagebreak()

Direction

#diagram(
	for (i, shape) in (
		shapes.trapezium,
		shapes.triangle,
		shapes.house,
		shapes.chevron,
	).enumerate() {
		for (j, dir) in (top, bottom, left, right).enumerate() {
			node(
				(j, i),
				[#dir],
				fill: orange.transparentize(40%),
				shape: shape.with(dir: dir),
			)
		}
	}
)


#pagebreak()

Flip

#diagram(
	for (i, flip) in (false, true).enumerate() {
		node(
			(i, 0),
			[#flip],
			fill: teal.transparentize(40%),
			shape: shapes.parallelogram.with(flip: flip),
		)
	}
)

#pagebreak()

Fit factor

#diagram(
	node-inset: 0pt,
	for (i, shape) in (
		shapes.parallelogram,
		shapes.trapezium,
		shapes.diamond,
		shapes.triangle,
		shapes.chevron,
		shapes.hexagon,
	).enumerate() {
		for (j, fit) in (0, 0.5, 1).enumerate() {
			node(
				(j, i),
				box(fill: blue.transparentize(60%), inset: 10pt, raw("fit: " + repr(fit))),
				fill: green.transparentize(20%),
				shape: shape.with(fit: fit),
			)
		}
	}
)