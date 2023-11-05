#import calc: floor, ceil, min, max
#import "@local/cetz:0.1.2" as cetz: vector
#import "utils.typ": *
#import "layout.typ": *
#import "marks.typ": *


#let node(pos, label) = {
	assert(type(pos) == array and pos.len() == 2)

	if type(label) == content and label.func() == circle { panic(label) }
	((
		kind: "node",
		pos: pos,
		label: label,
	),)
}


#let arrow(
	from,
	to,
	..args,
	label-pos: 0.5,
	label-trans: auto,
	paint: black,
	thickness: 0.6pt,
	dash: none,
	bend: none,
	marks: (none, none),
	parallels: (0,),
	crossing: false,
	crossing-thickness: 5
) = {
	node(from, none)
	node(to, none)

	let mode = if bend in (none, 0deg) { "line" } else { "arc" }
	let label = if args.pos().len() > 0 { args.pos().at(0) } else { none }
	if args.pos().len() > 1 or args.named().len() > 0 {
		panic("Unexpected arguments:", args)
	}

	let stroke = (
		paint: paint,
		cap: "round",
		thickness: thickness,
		dash: dash,
	)

	let obj = ( 
		kind: "arrow",
		points: (from, to),
		label: label,
		label-pos: label-pos,
		label-trans: label-trans,
		paint: paint,
		mode: mode,
		bend: bend,
		stroke: stroke,
		marks: marks,
		parallels: parallels,
	)

	if crossing {
		// duplicate connector with white stroke and place underneath
		let understroke = (
			..obj.stroke,
			paint: white,
			thickness: crossing-thickness*obj.stroke.thickness,
		)
		((..obj, stroke: understroke, marks: (none, none)),)
	}

	(obj,)
}

#let coord(coords, callback) = {
	((
		kind: "coord",
		coords: coords,
		callback: callback,
	))
}

#let draw-connector(arrow, cells, options) = {

	let cap-points = get-node-connectors(arrow, cells, options)
	let mark-angles
	let label-pos

	let cap-offsets(y) = zip(arrow.marks, (+1, -1))
		.map(((mark, dir)) => {
			if mark == none or mark not in CAP_OFFSETS { 0pt }
			else {
				let o = CAP_OFFSETS.at(mark)(y)
				dir*o*arrow.stroke.thickness
			}
		})


	if arrow.mode == "line" {

		let θ = vector-angle(vector.sub(..cap-points))
		mark-angles = (θ, θ + 180deg)

		let line-points(y) = zip(cap-points, cap-offsets(y))
			.map(((point, offset)) => vector.add(
				point,
				vector-polar(offset, θ)
			))


		for shift in arrow.parallels {
			let shifted-line-points = line-points(shift)
				.map(p => {
					let r = arrow.stroke.thickness*shift
					vector.add(p, vector-polar(r, θ + 90deg))
				})

			cetz.draw.line(
				..shifted-line-points,
				stroke: arrow.stroke,
			)
		}


		if arrow.label-trans == auto {
			arrow.label-trans = if calc.abs(θ) < 90deg { 1em } else { -1em }
		}

		arrow.label-trans = to-abs-length(arrow.label-trans, options.em-size)

		label-pos = vector.add(
			vector.lerp(..line-points(0), arrow.label-pos),
			vector-polar(arrow.label-trans, θ + 90deg),
		)

	} else if arrow.mode == "arc" {
		let (center, radius, start, stop) = get-arc-connecting-points(..cap-points, arrow.bend)

		let bend-dir = if arrow.bend < 0deg { +1 } else { -1 }

		for shift in arrow.parallels {
			let (start, stop) = (start, stop)
				.zip(cap-offsets(shift))
				.map(((θ, arclen)) => θ - bend-dir*arclen/radius*1rad)

			cetz.draw.arc(
				center,
				radius: radius + shift*arrow.stroke.thickness,
				start: start,
				stop: stop,
				anchor: "center",
				stroke: arrow.stroke,
			)
		}

		let δ = bend-dir*90deg
		mark-angles = (start - δ, stop + δ)

		if arrow.label-trans == auto {
			arrow.label-trans = 1em
		}

		arrow.label-trans = to-abs-length(arrow.label-trans, options.em-size)

		label-pos = vector.add(
			center,
			vector-polar(radius + arrow.label-trans, lerp(start, stop, arrow.label-pos))
		)

	} else { panic(arrow) }

	for (mark, pt, θ) in zip(arrow.marks, cap-points, mark-angles) {
		if mark == none { continue }
		draw-arrow-cap(pt, θ, arrow.stroke, mark)
	}

	if arrow.label != none {
		cetz.draw.content(label-pos, box(
			fill: white,
			inset: 3pt,
			radius: .5em,
			stroke: none,
			$ #arrow.label $,
		))
	}

	if options.debug >= 3 {
		for (cell, point) in zip(cells, cap-points) {
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
	cells,
	nodes,
	arrows,
	options,
) = {

	let (pad, debug) = options

	cetz.canvas({

		for (i, node) in nodes.enumerate() {

			if node.label == none { continue }

			let cell = cells.at(repr(node.pos))

			cetz.draw.content(cell.real-pos, node.label, anchor: "center")

			if debug >= 1 {
				cetz.draw.circle(
					cell.real-pos,
					radius: 1pt,
					fill: DEBUG_COLOR,
					stroke: none,
				)
			}
			if debug >= 2 {
				if debug >= 3 or cell.bounding-mode == "rect" {
					cetz.draw.rect(
						vector.sub(cell.real-pos, vector.div(cell.size, 2)),
						vector.add(cell.real-pos, vector.div(cell.size, 2)),
						stroke: DEBUG_COLOR + 0.25pt,
					)
				}
				if debug >= 3 or cell.bounding-mode == "circle" {
					cetz.draw.circle(
						cell.real-pos,
						radius: cell.radius,
						stroke: DEBUG_COLOR + 0.25pt,
					)
				}
			}
		}

		for arrow in arrows {
			let cells = arrow.points.map(pos => cells.at(repr(pos)))

			let intersection-stroke = if debug >= 2 {
				(paint: DEBUG_COLOR, thickness: 0.25pt)
			}

			draw-connector(arrow, cells, options)

		}

		// draw axes
		if debug >= 1 {

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
							thickness: .5pt,
							dash: "densely-dotted",
						),
					)
				}
			}

		}
	})	
}


#let arrow-diagram(
	..args,
	pad: 3em,
	debug: false,
	node-outset: 15pt,
	defocus: 0.2,
	min-size: 0pt,
) = {

	if type(pad) != array { pad = (pad, pad) }
	if type(min-size) != array { min-size = (min-size, min-size) }

	let options = (
		pad: pad,
		debug: int(debug),
		node-outset: node-outset,
		defocus: defocus,
		min-size: min-size,
		..args.named(),
	)

	let positional-args = args.pos().join()
	let nodes = positional-args.filter(e => e.kind == "node")
	let arrows = positional-args.filter(e => e.kind == "arrow")

	box(style(styles => {

		let em-size = measure(box(width: 1em), styles).width
		let to-pt(len) = {
			len.abs + len.em*em-size
		}

		let options = options
		options.em-size = em-size
		options.pad = options.pad.map(to-pt)
		options.node-outset = to-pt(options.node-outset)

		let nodes-sized = nodes.map(node => {
			let (width, height) = measure(node.label, styles)
			node.size = (width, height)
			node
		})

		// compute diagram layout
		let grid = compute-grid(nodes-sized, options)
		let cells = compute-cells(nodes-sized, grid, options)

		draw-diagram(grid, cells, nodes-sized, arrows, options)

	}))
}

