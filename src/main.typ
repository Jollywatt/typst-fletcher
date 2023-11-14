#import calc: floor, ceil, min, max
#import "@preview/cetz:0.1.2" as cetz: vector
#import "utils.typ": *
#import "layout.typ": *
#import "marks.typ": *

#let node(
	pos,
	label,
	pad: none,
	shape: auto,
) = {
	assert(type(pos) == array and pos.len() == 2)

	if type(label) == content and label.func() == circle { panic(label) }
	((
		kind: "node",
		pos: pos,
		label: label,
		pad: pad,
		shape: shape,
	),)
}


#let CONN_ARGUMENT_SHORTHANDS = (
	"dashed": (dash: "dashed"),
	"double": (double: true),
	"crossing": (crossing: true),
)

#let interpret-conn-args(args) = {
	let named-args = (:)

	if args.named().len() > 0 {
		panic("Unexpected named argument(s):", ..args.named().keys())
	}

	let pos = args.pos()

	if pos.len() >= 1 and type(pos.at(0)) != str {
		named-args.label = pos.remove(0)
	}

	if (pos.len() >= 1 and type(pos.at(0)) == str and
		pos.at(0) not in CONN_ARGUMENT_SHORTHANDS) {
		named-args.marks = pos.remove(0)
	}

	for arg in pos {
		if type(arg) == str and arg in CONN_ARGUMENT_SHORTHANDS {
			named-args += CONN_ARGUMENT_SHORTHANDS.at(arg)
		} else {
			panic(
				"Unrecognised argument " + repr(arg) + ". Must be one of:",
				CONN_ARGUMENT_SHORTHANDS.keys(),
			)
		}
	}

	named-args

}

/// Draw a connector
///
/// - from (elastic coord): Start coordinate `(x, y)` of connector. If there is
///  a node at that point, the connector is adjusted to begin at the node's
///  bounding rectangle/circle.
/// - to (elastic coord): End coordinate `(x, y)` of connector. If there is a 
///  node at that point, the connector is adjusted to end at the node's bounding
///  rectangle/circle.
///
/// - ..args (any): The connector's `label` and `marks` named arguments can also
///  be specified as positional arguments. For example, the following are equivalent:
///  ```typc
///  conn((0,0), (1,0), $f$, "->")
///  conn((0,0), (1,0), $f$, marks: "->")
///  conn((0,0), (1,0), "->", label: $f$)
///  conn((0,0), (1,0), label: $f$, marks: "->")
///  ```
/// 
/// - label-pos (number): Position of the label along the connector, from the
///  start to end (from `0` to `1`).
/// 
///  #stack(
///  	dir: ltr,
///  	spacing: 1fr,
///  	..(0, 0.25, 0.5, 0.75, 1).map(p => arrow-diagram(
///  		cell-size: 1cm,
///  		conn((0,0), (1,0), p, "->", label-pos: p))
///  	),
///  )
/// - label-sep (number): Separation between the connector and the label anchor.
///  
///  With the default anchor (`"bottom"`):
///  #arrow-diagram(
///  	debug: 2,
///  	cell-size: 8mm,
///  	{
///  		for (i, s) in (-5pt, 0pt, .4em, .8em).enumerate() {
///  			conn((2*i,0), (2*i + 1,0), s, "->", label-sep: s)
///  		}
///  })
///  
///  With `label-anchor: "center"`:
///  #arrow-diagram(
///  	debug: 2,
///  	cell-size: 8mm,
///  	{
///  		for (i, s) in (-5pt, 0pt, .4em, .8em).enumerate() {
///  			conn((2*i,0), (2*i + 1,0), s, "->", label-sep: s, label-anchor: "center")
///  		}
///  })
/// 
/// - label (content): Content for connector label. See `label-side` to control
///  the position (and `label-sep`, `label-pos` and `label-anchor` for finer
///  control).
///
/// - label-side (left, right, center): Which side of the connector to place the
///  label on, viewed as you walk along it. If `center`, then the label is place
///  over the connector. When `auto`, a value of `left` or `right` is chosen to
///  automatically so that the label is
///    - roughly above the connector, in the case of straight lines; or
///    - on the outside of the curve, in the case of arcs.
///
/// - label-anchor (anchor): The anchor point to place the label at, such as
///  `"top-right"`, `"center"`, `"bottom"`, etc. If `auto`, the anchor is
///  automatically chosen based on `label-side` and the angle of the connector.
///
/// - paint (paint): Paint (color or gradient) of the connector stroke.
/// - thickness (length): Thickness the connector stroke. Marks (arrow heads)
///  scale with this thickness.
/// - dash (dash type): Dash style for the connector stroke.
/// - bend (angle): Curvature of the connector. If `0deg`, the connector is a
///  straight line; positive angles bend clockwise.
/// 
///  #arrow-diagram(debug: 0, {
///  	node((0,0), $A$)
///  	node((1,1), $B$)
///  	let N = 4
///  	range(N + 1)
///  		.map(x => (x/N - 0.5)*2*100deg)
///  		.map(θ => conn((0,0), (1,1), θ, bend: θ, ">->", label-side: center))
///  		.join()
///  })
///
/// - marks (pair of strings):
/// The start and end marks or arrow heads of the connector. A shorthand such as
/// `"->"` can used instead. For example,
/// `conn(p1, p2, "->")` is short for `conn(p1, p2, marks: (none, "head"))`.
///
/// #table(
/// 	columns: 3,
/// 	align: horizon,
///  	[Arrow], [Shorthand], [Arguments],
/// 	..(
///  		"-",
///  		"--",
///  		"..",
///  		"->",
///  		"<=>",
///  		">>-->",
///  		"|..|",
///  		"hook->>",
///  		"hook'->>",
///  		">-harpoon",
///  		">-harpoon'",
/// 	).map(str => (
///  		arrow-diagram(conn((0,0), (1,0), str)),
///  		raw(str, lang: none),
///  		raw(repr(parse-arrow-shorthand(str))),
///  	)).join()
/// )
///
/// - double (bool): Shortcut for `extrude: (-1.5, 1.5)`, showing a double stroke.
/// - extrude (array of numbers): Draw copies of the stroke extruded by the
///  given multiple of the stroke thickness. Used to obtain doubling effect.
///  Best explained by example:
///
///  #arrow-diagram({
///  	(
///  		(0,),
///  		(-1.5,+1.5),
///  		(-2,0,+2),
///  		(-4.5,),
///  		(4.5,),
///  	).enumerate().map(((i, e)) => {
///  		conn(
///  			(2*i, 0), (2*i + 1, 0), [#e], "|->",
///  			extrude: e, thickness: 1pt, label-sep: 1em)
///  	}).join()
///  })
///  
///  Notice how the ends of the line need to shift a little depending on the
///  mark. For basic arrow heads, this offset is computed with
///  `round-arrow-cap-offset()`.
///
/// - crossing (bool): If `true`, draws a white backdrop to give the illusion of
///  lines crossing each other.
///  #arrow-diagram({
///  	conn((0,1), (1,0), thickness: 1pt)
///  	conn((0,0), (1,1), thickness: 1pt)
///  	conn((2,1), (3,0), thickness: 1pt)
///  	conn((2,0), (3,1), thickness: 1pt, crossing: true)
///  })
/// - crossing-thickness (number): Thickness of the white "crossing" background
///  stroke, if `crossing: true`, in multiples of the normal stroke's thickness.
/// 
///  #arrow-diagram({
///  	(1, 2, 5, 8, 12).enumerate().map(((i, x)) => {
///  		conn((2*i, 1), (2*i + 1, 0), thickness: 1pt, label-sep: 1em)
///  		conn((2*i, 0), (2*i + 1, 1), raw(str(x)), thickness: 1pt, label-sep:
///  		1em, crossing: true, crossing-thickness: x)
///  	}).join()
///  })
///
#let conn(
	from,
	to,
	..args,
	label: none,
	label-side: auto,
	label-pos: 0.5,
	label-sep: 0.4em,
	label-anchor: auto,
	paint: black,
	thickness: 0.6pt,
	dash: none,
	bend: none,
	marks: (none, none),
	double: false,
	extrude: auto,
	crossing: false,
	crossing-thickness: 5,
) = {
	node(from, none)
	node(to, none)

	let options = (
		label: label,
		label-pos: label-pos,
		label-sep: label-sep,
		label-anchor: label-anchor,
		label-side: label-side,
		paint: paint,
		thickness: thickness,
		dash: dash,
		bend: bend,
		marks: marks,
		double: double,
		extrude: extrude,
		crossing: crossing,
		crossing-thickness: crossing-thickness,
	)
	options += interpret-conn-args(args)

	let mode = if bend in (none, 0deg) { "line" } else { "arc" }
	// let label = if args.pos().len() > 0 { args.pos().at(0) } else { none }

	if type(options.marks) == str {
		options += parse-arrow-shorthand(options.marks)
	}


	if options.extrude == auto {
		options.extrude = if options.double { (-1.5, +1.5) } else { (0,) }
	}

	let stroke = (
		paint: options.paint,
		cap: "round",
		thickness: options.thickness,
		dash: options.dash,
	)

	if options.label-side == center {
		options.label-anchor = "center"
		options.label-sep = 0pt
	}

	let obj = ( 
		kind: "conn",
		points: (from, to),
		label: options.label,
		label-pos: options.label-pos,
		label-sep: options.label-sep,
		label-anchor: options.label-anchor,
		label-side: options.label-side,
		paint: options.paint,
		mode: mode,
		bend: options.bend,
		stroke: stroke,
		marks: options.marks,
		extrude: options.extrude,
	)


	if options.crossing {
		// duplicate connector with white stroke and place underneath
		let understroke = (
			..obj.stroke,
			paint: white,
			thickness: crossing-thickness*obj.stroke.thickness,
		)

		((
			..obj,
			stroke: understroke,
			marks: (none, none),
			extrude: obj.extrude.map(i => i/crossing-thickness)
		),)
	}

	(obj,)
}

/// Resolve coordinates and pass them to a callback function
///
/// - ..args (point2f): One or more dimensionless 2D points of the form `(x, y)`.
/// - callback (function): Function to be called with the resolved coordinates
/// as arguments.
#let resolve-coords(..args, callback: (..args) => none) = {
	((
		kind: "coord",
		coords: args.pos(),
		callback: callback,
	),)
}

#let draw-connector(arrow, nodes, options) = {

	// Stroke end points, before adjusting for the arrow heads
	let cap-points = get-node-connectors(arrow, nodes, options)
	let θ = vector-angle(vector.sub(..cap-points))

	// Get the arrow head adjustment for a given extrusion distance
	let cap-offsets(y) = zip(arrow.marks, (+1, -1))
		.map(((mark, dir)) => {
			if mark == none or mark not in CAP_OFFSETS { 0pt }
			else {
				let o = CAP_OFFSETS.at(mark)(y)
				dir*o*arrow.stroke.thickness
			}
		})

	let cap-angles
	let label-pos

	if arrow.mode == "line" {

		cap-angles = (θ, θ + 180deg)

		for shift in arrow.extrude {
			let d = shift*arrow.stroke.thickness
			let shifted-line-points = cap-points
				.zip(cap-offsets(shift))
				.map(((point, offset)) => vector.add(
					point,
					vector.add(
						// Shift end points lengthways depending on markers
						vector-polar(offset, θ),
						// Shift line sideways (for double line effects, etc) 
						vector-polar(d, θ + 90deg),
					)
				))

			cetz.draw.line(
				..shifted-line-points,
				stroke: arrow.stroke,
			)
		}


		// Choose label anchor based on connector direction
		if arrow.label-side == auto {
			arrow.label-side = if calc.abs(θ) < 90deg { left } else { right }
		}
		let label-dir = if arrow.label-side == left { +1 } else { -1 }

		if arrow.label-anchor == auto {
			arrow.label-anchor = angle-to-anchor(θ - label-dir*90deg)
		}
		
		arrow.label-sep = to-abs-length(arrow.label-sep, options.em-size)
		label-pos = vector.add(
			vector.lerp(..cap-points, arrow.label-pos),
			vector-polar(arrow.label-sep, θ + label-dir*90deg),
		)

	} else if arrow.mode == "arc" {

		let (center, radius, start, stop) = get-arc-connecting-points(..cap-points, arrow.bend)

		let bend-dir = if arrow.bend > 0deg { +1 } else { -1 }
		let δ = bend-dir*90deg
		cap-angles = (start + δ, stop - δ)


		for shift in arrow.extrude {
			let (start, stop) = (start, stop)
				.zip(cap-offsets(shift))
				.map(((θ, arclen)) => θ + bend-dir*arclen/radius*1rad)

			cetz.draw.arc(
				center,
				radius: radius + shift*arrow.stroke.thickness,
				start: start,
				stop: stop,
				anchor: "center",
				stroke: arrow.stroke,
			)
		}



		if arrow.label-side == auto {
			arrow.label-side =  if arrow.bend > 0deg { left } else { right }
		}
		let label-dir = if arrow.label-side == left { +1 } else { -1 }

		if arrow.label-anchor == auto {
			// Choose label anchor based on connector direction
			arrow.label-anchor = angle-to-anchor(θ + label-dir*90deg)
		}
		
		arrow.label-sep = to-abs-length(arrow.label-sep, options.em-size)
		label-pos = vector.add(
			center,
			vector-polar(
				radius + label-dir*bend-dir*arrow.label-sep,
				lerp(start, stop, arrow.label-pos),
			)
		)

	} else { panic(arrow) }


	for (mark, pt, θ) in zip(arrow.marks, cap-points, cap-angles) {
		if mark == none { continue }
		draw-arrow-cap(pt, θ, arrow.stroke, mark)
	}

	if arrow.label != none {

		cetz.draw.content(
			label-pos,
			box(
				fill: white,
				inset: .2em,
				radius: .2em,
				stroke: if options.debug >= 2 { DEBUG_COLOR + 0.25pt },
				$ #arrow.label $,
			),
			anchor: arrow.label-anchor,
		)

		if options.debug >= 2 {
			cetz.draw.circle(
				label-pos,
				radius: arrow.stroke.thickness,
				stroke: none,
				fill: DEBUG_COLOR,
			)
		}
	}

	if options.debug >= 3 {
		for (cell, point) in zip(nodes, cap-points) {
			cetz.draw.line(
				cell.real-pos,
				point,
				stroke: DEBUG_COLOR + 0.1pt,
			)
		}
	}


}


#let draw-diagram(
	grid,
	nodes,
	arrows,
	options,
) = {

	for (i, node) in nodes.enumerate() {

		if node.label == none { continue }

		cetz.draw.content(node.real-pos, node.label, anchor: "center")

		if options.debug >= 1 {
			cetz.draw.circle(
				node.real-pos,
				radius: 1pt,
				fill: DEBUG_COLOR,
				stroke: none,
			)
		}

		if options.debug >= 2 {
			if options.debug >= 3 or node.shape == "rect" {
				cetz.draw.rect(
					vector.sub(node.real-pos, vector.div(node.size, 2)),
					vector.add(node.real-pos, vector.div(node.size, 2)),
					stroke: DEBUG_COLOR + 0.25pt,
				)
			}
			if options.debug >= 3 or node.shape == "circle" {
				cetz.draw.circle(
					node.real-pos,
					radius: node.radius,
					stroke: DEBUG_COLOR + 0.25pt,
				)
			}
		}
	}

	let find-node-at-pos(pos) = {
		nodes.filter(node => node.pos == pos).first()
	}

	for arrow in arrows {
		// let nodes = arrow.points.map(pos => cells.at(repr(pos)))
		let nodes = arrow.points.map(find-node-at-pos)

		let intersection-stroke = if options.debug >= 2 {
			(paint: DEBUG_COLOR, thickness: 0.25pt)
		}

		draw-connector(arrow, nodes, options)

	}

	// draw axes
	if options.debug >= 1 {

		cetz.draw.rect(
			(0,0),
			grid.bounding-size,
			stroke: DEBUG_COLOR + 0.25pt
		)

		for (axis, coord) in ((0, (x,y) => (x,y)), (1, (y,x) => (x,y))) {

			for (i, x) in grid.centers.at(axis).enumerate() {
				let size = grid.sizes.at(axis).at(i)

				// coordinate label
				cetz.draw.content(
					coord(x, -.4em),
					text(fill: DEBUG_COLOR, size: .75em)[#(grid.origin.at(axis) + i)],
					anchor: if axis == 0 { "top" } else { "right" }
				)

				// size bracket
				cetz.draw.line(
					..(+1, -1).map(dir => coord(x + dir*max(size, 1e-6pt)/2, 0)),
					stroke: DEBUG_COLOR + .75pt,
					mark: (start: "|", end: "|")
				)

				// gridline
				cetz.draw.line(
					coord(x, 0),
					coord(x, grid.bounding-size.at(1 - axis)),
					stroke: (
						paint: DEBUG_COLOR,
						thickness: .3pt,
						dash: "densely-dotted",
					),
				)
			}
		}
	}
}

#let resolve-coord(grid, coord) = {
	zip(grid.centers, coord, grid.origin)
		.map(((c, x, o)) => lerp-at(c, x - o))
}

#let execute-callbacks(grid, cells, nodes-sized, callbacks, options) = {
	for callback in callbacks {
		let resolved-coords = callback.coords
			.map(resolve-coord.with(grid))
		let result = (callback.callback)(..resolved-coords)
		if type(result) != array {
			panic("Callback should return an array of CeTZ element dictionaries; got " + type(result), result)
		}
		result
	}
}


/// Draw an arrow diagram.
///
/// - ..args (array): An array of dictionaries specifying the diagram's
///   nodes and connections.
/// - gutter (length, pair of lengths): Gaps between rows and columns. Ensures
///  that nodes at adjacent grid points are at least this far apart (measured as
///  the space between their bounding boxes).
///
/// Separate horizontal/vertical gutters can be specified with `(x, y)`. A
/// single length `d` is short for `(d, d)`.
/// - debug (bool, 1, 2, 3): Level of detail for drawing debug information.
///  Level 1 shows a coordinate grid; higher levels show bounding boxes and
///  anchors, etc.
/// - node-pad (length, pair of lengths): Padding between a node's content
///  and its bounding box.
/// - defocus (number): Strength of the defocus correction. `0` to disable.
/// - cell-size (length, pair of lengths): Minimum size of all rows and columns.
#let arrow-diagram(
	..args,
	gutter: 3em,
	debug: false,
	node-pad: 15pt,
	cell-size: 0pt,
	defocus: 0.2,
) = {

	if type(gutter) != array { gutter = (gutter, gutter) }
	if type(cell-size) != array { cell-size = (cell-size, cell-size) }

	let options = (
		gutter: gutter,
		debug: int(debug),
		node-pad: node-pad,
		defocus: defocus,
		cell-size: cell-size,
		..args.named(),
	)

	let positional-args = args.pos().join()
	let nodes = positional-args.filter(e => e.kind == "node")
	let arrows = positional-args.filter(e => e.kind == "conn")
	let callbacks = positional-args.filter(e => e.kind == "coord")

	box(style(styles => {

		let em-size = measure(box(width: 1em), styles).width
		let to-pt(len) = len.abs + len.em*em-size

		let options = options
		options.em-size = em-size
		options.gutter = options.gutter.map(to-pt)
		options.node-pad = to-pt(options.node-pad)

		let nodes-sized = compute-nodes(nodes, styles, options)

		// compute diagram layout
		let grid = compute-grid(nodes-sized, options)
		// let cells = compute-cells(nodes-sized, grid, options)
		let nodes = resolve-elastic-coordinates(nodes-sized, grid, options)

		cetz.canvas({
			draw-diagram(grid, nodes, arrows, options)
			// execute-callbacks(grid, cells, nodes-sized, callbacks, options)	
		})
	}))
}

