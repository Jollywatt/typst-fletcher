#import calc: floor, ceil, min, max
#import "@local/cetz:0.1.2" as cetz: vector
#import "utils.typ": *
#import "line-caps.typ": *

#let get-node-connector(cell, incident-angle, options) = {

	if cell.radius < 1e-5pt { return cell.real-pos }

	if cell.is-roundish {
		// use bounding circle
		vector.sub(
			cell.real-pos,
			vector-polar(cell.radius, incident-angle),
		)
	} else {
		// use bounding rect
		let origin = cell.real-pos
		let μ = calc.pow(cell.aspect, options.defocus)
		let origin-δ = if cell.aspect < 1 {
			(0pt, cell.size.at(1)/2*(1 - μ)*calc.sin(incident-angle))
		} else {
			(-cell.size.at(0)/2*(1 - 1/μ)*calc.cos(incident-angle), 0pt)
		}
		let crossing-line = (
			vector.add(origin, origin-δ),
			vector.sub(origin, vector-polar(2*cell.radius, incident-angle)),
		)

		intersect-rect-with-crossing-line(cell.rect, crossing-line)


	}
}

#let get-node-connectors(arrow, cells, options) = {
	let center-center-line = cells.map(cell => cell.real-pos)

	let v = vector.sub(..center-center-line)
	let θ = vector-angle(v) // approximate angle of connector

	let δ = if arrow.mode == "arc" { arrow.bend } else { 0deg }
	let incident-angles = (θ + δ, θ - δ + 180deg)

	let points = zip(cells, incident-angles).map(((cell, θ)) => {
		get-node-connector(cell, θ, options)
	})

	points
}

#let draw-connector(arrow, cells, options) = {
	let points = get-node-connectors(arrow, cells, options)
	let (mark-from, mark-to) = arrow.marks
	let θ-from
	let θ-to
	let label-pos

	if arrow.mode == "line" {
		cetz.draw.line(
			// ..points,
			..points.rev(),
			stroke: arrow.stroke,
		)
		let θ = vector-angle(vector.sub(..points))
		(θ-from, θ-to) = (θ, θ + 180deg)

		if arrow.label-trans == auto {
			arrow.label-trans = if calc.abs(θ) < 90deg { 1em } else { -1em }
		}

		arrow.label-trans = to-abs-length(arrow.label-trans, options.em-size)

		label-pos = vector.add(
			vector.lerp(..points, arrow.label-pos),
			vector-polar(arrow.label-trans, θ + 90deg),
		)

	} else if arrow.mode == "arc" {
		let (center, radius, start, stop) = get-arc-connecting-points(..points, arrow.bend)
		cetz.draw.arc(
			center,
			radius: radius,
			start: start,
			stop: stop,
			anchor: "center",
			stroke: arrow.stroke,
		)
		let δ = if arrow.bend < 0deg { 90deg } else { -90deg }
		(θ-from, θ-to) = (start - δ, stop + δ)

		if arrow.label-trans == auto {
			arrow.label-trans = 1em
		}

		arrow.label-trans = to-abs-length(arrow.label-trans, options.em-size)


		label-pos = vector.add(
			center,
			vector-polar(radius + arrow.label-trans, lerp(start, stop, arrow.label-pos))
		)

	} else { panic(arrow) }

	if mark-from != none { draw-arrow-cap(points.at(0), θ-from, arrow.stroke, mark-from) }
	if mark-to != none { draw-arrow-cap(points.at(1), θ-to, arrow.stroke, mark-to) }

	if arrow.label != none {
		cetz.draw.content(label-pos, box(fill: white, inset: 3pt, radius: .5em, stroke: none, $ #arrow.label $))
	}


}


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
) = {
	node(from, none)
	node(to, none)
	let mode = if bend in (none, 0deg) { "line" } else { "arc" }
	let label = if args.pos().len() > 0 { args.pos().at(0) } else { none }
	((
		kind: "arrow",
		points: (from, to),
		label: label,
		label-pos: label-pos,
		label-trans: label-trans,
		paint: paint,
		mode: mode,
		bend: bend,
		stroke: (paint: paint, cap: "round", thickness: thickness, dash: dash),
		marks: marks,
	),)
}





/// Convert an array of rects with fractional positions into rects with integral
/// positions.
/// 
/// A rect is a dictionary `(pos: (x, y), size: (width, height))`.
/// 
/// If a rect is centered at a factional position `floor(x) < x < ceil(x)`, it
/// will be replaced by two new rects centered at `floor(x)` and `ceil(x)`. The
/// total width of the original rect is split across the two new rects according
/// two which one is closer. (E.g., if the original rect is at `x = 0.25`, the
/// new rect at `x = 0` has 75% the original width and the rect at `x = 1` has
/// 25%.) The same splitting procedure is done for `y` positions and heights.
#let expand-fractional-rects(rects) = {
	let new-rects
	for axis in (0, 1) {
		new-rects = ()
		for rect in rects {
			let coord = rect.pos.at(axis)
			let size = rect.size.at(axis)

			if calc.fract(coord) == 0 {
				rect.pos.at(axis) = calc.trunc(coord)
				new-rects.push(rect)
			} else {
				rect.pos.at(axis) = floor(coord)
				rect.size.at(axis) = size*(ceil(coord) - coord)
				new-rects.push(rect)

				rect.pos.at(axis) = ceil(coord)
				rect.size.at(axis) = size*(coord - floor(coord))
				new-rects.push(rect)
			}
		}
		rects = new-rects
	}
	new-rects
}

/// Determine the number, sizes and positions of rows and columns.
#let compute-grid(nodes, options) = {
	let rects = nodes.map(node => (pos: node.pos, size: node.size))
	rects = expand-fractional-rects(rects)

	// (x: (x-min, x-max), y: ...)
	let bounding-rect = zip(..rects.map(n => n.pos)).map(min-max)
	let bounding-dims = bounding-rect.map(((min, max)) => max - min + 1)
	let origin = bounding-rect.map(((min, max)) => min)

	// (x: (0pt, 0pt, ...), y: ...)
	let cell-sizes = bounding-dims.map(n => range(n).map(_ => 0pt))

	let (min-size-width, min-size-height) = options.at("min-size", default: (0pt, 0pt))

	for rect in rects {
		let coords = vector.sub(rect.pos, origin)
		for axis in (0, 1) {
			cell-sizes.at(axis).at(coords.at(axis)) = max(
				cell-sizes.at(axis).at(coords.at(axis)),
				rect.size.at(axis),
				options.min-size.at(axis),
			)

		}
	}

	// (x: (c1x, c2x, ...), y: ...)
	let cell-centers = zip(cell-sizes, options.pad).map(((sizes, p)) => {
		zip(cumsum(sizes), sizes, range(sizes.len())).map(((end, size, i)) => end - size/2 + p*i)
	})

	let total-size = cell-centers.zip(cell-sizes).map(((centers, sizes)) => {
		centers.at(-1) + sizes.at(-1)/2
	})

	(
		centers: cell-centers,
		sizes: cell-sizes,
		origin: origin,
		bounding-size: total-size
	)
}	

/// Compute a lookup table of the attributes of each grid cell
#let compute-cells(nodes, grid, options) = {

	let cells = (:)

	for node in nodes {

		let cell = cells.at(
			repr(node.pos),
			default: (size: (0pt, 0pt)),
		)


		if "real-pos" not in cell {
			// first time computing cell attrs
			cell.real-pos = node.pos
				.zip(grid.origin, grid.centers)
				.map(((coord, origin, centers)) => {
					lerp-at(centers, coord - origin)
				})

		}

		cell.size = cell.size.zip(node.size).map(x => max(..x))


		cells.insert(repr(node.pos), cell)

	}

	for (key, cell) in cells {

		let (w, h) = cell.size
		cell.aspect = if w == 0pt and h == 0pt { 1 } else { w/h }
		cell.is-roundish = max(cell.aspect, 1/cell.aspect) < 1.5
		cell.radius = calc.sqrt((w/2pt)*(w/2pt) + (h/2pt)*(h/2pt))*1pt
		cell.bounding-mode = if cell.is-roundish { "circle" } else { "rect" }
		
		// add cell inset
		if cell.radius != 0pt {
			if cell.is-roundish { 
				cell.radius += options.node-outset*0.5
			} else {
				cell.size = cell.size.map(x => x + options.node-outset)
			}
		}

		cell.rect = (+1, -1).map(dir => {
			vector.add(
				cell.real-pos,
				vector.scale(vector.div(cell.size, 2), dir)
			)
		})

		cells.at(key) = cell
	}

	return cells

}


#let debug-color = rgb("f008")

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
					fill: debug-color,
					stroke: none,
				)
			}
			if debug >= 2 {
				if debug >= 3 or cell.bounding-mode == "rect" {
					cetz.draw.rect(
						vector.sub(cell.real-pos, vector.div(cell.size, 2)),
						vector.add(cell.real-pos, vector.div(cell.size, 2)),
						stroke: debug-color + 0.25pt,
					)
				}
				if debug >= 3 or cell.bounding-mode == "circle" {
					cetz.draw.circle(
						cell.real-pos,
						radius: cell.radius,
						stroke: debug-color + 0.25pt,
					)
				}
			}
		}

		for arrow in arrows {
			let cells = arrow.points.map(pos => cells.at(repr(pos)))

			let intersection-stroke = if debug >= 2 {
				(paint: debug-color, thickness: 0.25pt)
			}

			draw-connector(arrow, cells, options)

		}

		// draw axes
		if debug >= 1 {

			cetz.draw.rect(
				(0,0),
				grid.bounding-size,
				stroke: debug-color + 0.25pt
			)

			for (axis, coord) in ((0, (x,y) => (x,y)), (1, (y,x) => (x,y))) {

				for (i, x) in grid.centers.at(axis).enumerate() {
					let size = grid.sizes.at(axis).at(i)

					// coordinate label
					cetz.draw.content(
						coord(x, -.5em),
						text(fill: debug-color, size: .75em)[#(grid.origin.at(axis) + i)]
					)

					// size bracket
					cetz.draw.line(
						..(+1, -1).map(dir => coord(x + dir*max(size, 1e-6pt)/2, 0)),
						stroke: debug-color + .75pt,
						mark: (start: "|", end: "|")
					)

					// gridline
					cetz.draw.line(
						coord(x, 0),
						coord(x, grid.bounding-size.at(1 - axis)),
						stroke: (
							paint: debug-color,
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


		let options = options

		let em-size = measure(box(width: 1em), styles).width

		let to-pt(len) = {
			len.abs + len.em*em-size
		}

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

