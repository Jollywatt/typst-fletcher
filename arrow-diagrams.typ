#import "@local/cetz:0.1.2" as cetz: vector

#import calc: floor, ceil, min, max

#let min-max(array) = (calc.min(..array), calc.max(..array))

#let vector-len((x, y)) = 1pt*calc.sqrt((x/1pt)*(x/1pt) + (y/1pt)*(y/1pt))
#let vector-set-len(len, v) = {
	vector.scale(v, len/vector-len(v))
}
#let vector-unitless(v) = v.map(x => if type(x) == length { x/1pt } else { x })

#let vector-polar(r, θ) = (r*calc.cos(θ), r*calc.sin(θ))

#let cumsum(array) = {
	let sum = array.at(0)
	for i in range(1, array.len()) {
		sum += array.at(i)
		array.at(i) = sum
	}
	array
}

#let lerp(a, b, t) = a*(1 - t) + b*t
#let lerp-at(a, t) = lerp(
	a.at(floor(t)),
	a.at(ceil(t)),
	calc.fract(t),
)

#let zip(a, ..others) = if others.pos().len() == 0 {
	a.map(i => (i,))
} else {
	a.zip(..others)
}



#let rect-edges((x0, y0), (x1, y1)) = (
  ((x0, y0), (x1, y0)),
  ((x1, y0), (x1, y1)),
  ((x1, y1), (x0, y1)),
  ((x0, y1), (x0, y0)),
)
#let intersect-rect-with-crossing-line(rect, line) = {
	rect = rect.map(vector-unitless)
	line = line.map(vector-unitless)
	for (p1, p2) in rect-edges(..rect) {
		let meet = cetz.draw.intersection.line-line(p1, p2, ..line)
		if meet != none {
			return vector.scale(meet, 1pt)
		}
	}
	panic("didn't intersect", rect, line)
}


#let get-node-connector(cell, incident-angle, options) = {

	if cell.radius < 1e-5pt { return cell.real-pos }

	if cell.is-roundish {
		// use bounding circle
		vector.add(
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
			(cell.size.at(0)/2*(1 - 1/μ)*calc.cos(incident-angle), 0pt)
		}
		let crossing-line = (
			vector.add(origin, origin-δ),
			vector.add(origin, vector-polar(2*cell.radius, incident-angle)),
		)

		intersect-rect-with-crossing-line(cell.rect, crossing-line)


	}
}

#let get-node-connectors(cells, options) = {
	let center-center-line = cells.map(cell => cell.real-pos)

	let v = vector.sub(..center-center-line)
	let θ = calc.atan2(..vector-unitless(v))

	zip(cells, (180deg, 0deg)).map(((cell, δ)) => {
		get-node-connector(cell, θ + δ, options)
	})
}


#let node(pos, label) = {
	assert(type(pos) == array and pos.len() == 2)
	((
		kind: "node",
		pos: pos,
		label: label,
	),)
}

#let arrow(
	from,
	to,
	label: none,
	paint: none,
	stroke: 0.6pt,
) = {
	node(from, none)
	node(to, none)
	((
		kind: "arrow",
		points: (from, to),
		paint: paint,
		stroke: stroke,
	),)
}

#let debug-color = rgb("f00a").lighten(50%)




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
#let compute-grid(rects, pad) = {
	// (x: (x-min, x-max), y: ...)
	let bounding-rect = zip(..rects.map(n => n.pos)).map(min-max)
	let bounding-dims = bounding-rect.map(((min, max)) => max - min + 1)
	let origin = bounding-rect.map(((min, max)) => min)

	// (x: (0pt, 0pt, ...), y: ...)
	let cell-sizes = bounding-dims.map(n => range(n).map(_ => 0pt))

	for rect in rects {
		let (col, row) = vector.sub(rect.pos, origin)
		let (width, height) = rect.size
		cell-sizes.at(0).at(col) = calc.max(cell-sizes.at(0).at(col), width)
		cell-sizes.at(1).at(row) = calc.max(cell-sizes.at(1).at(row), height)
	}

	// (x: (c1x, c2x, ...), y: ...)
	let cell-centers = zip(cell-sizes, pad).map(((sizes, p)) => {
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

#let compute-layout(nodes, options) = {

	let rects = nodes.map(node => (pos: node.pos, size: node.size))
	rects = expand-fractional-rects(rects)
	let grid = compute-grid(rects, options.pad)

	let cells = (:)

	for (i, node) in nodes.enumerate() {

		let cell = cells.at(
			repr(node.pos),
			default: (size: (1pt, 1pt)),
		)

		if "real-pos" not in cell {
			let real-pos = node.pos
				.zip(grid.origin, grid.centers)
				.map(((coord, origin, centers)) => {
					lerp-at(centers, coord - origin)
				})

			cell.insert("real-pos", real-pos)
		}

		cell.size = cell.size.zip(node.size).map(x => max(..x))
		let (w, h) = cell.size

		cell.aspect = w/h
		cell.is-roundish = max(cell.aspect, 1/cell.aspect) < 1.5
		cell.bounding-mode = if cell.is-roundish { "circle" } else { "rect" }

		let pad = options.node-outset// * if cell.is-roundish { 0.7 } else { 1.0 }
		cell.size = cell.size.map(x => x + pad)

		cell.radius = calc.sqrt((w/2pt)*(w/2pt) + (h/2pt)*(h/2pt))*1pt

		cell.rect = (+1, -1).map(dir => {
			vector.add(
				cell.real-pos,
				vector.scale(vector.div(cell.size, 2), dir)
			)
		})


		cells.insert(repr(node.pos), cell)

		nodes.at(i) = node
	}

	return (grid, cells)

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
					fill: debug-color,
					stroke: none,
				)
			}
			if debug >= 2 {
				if cell.bounding-mode == "rect" {
					cetz.draw.rect(
						vector.sub(cell.real-pos, vector.div(cell.size, 2)),
						vector.add(cell.real-pos, vector.div(cell.size, 2)),
						stroke: debug-color + 0.25pt,
					)
				} else if cell.bounding-mode == "circle" {
					cetz.draw.circle(
						cell.real-pos,
						radius: cell.radius,
						stroke: debug-color + 0.25pt,
					)
				} else { panic(cell) }
			}
		}



		for arrow in arrows {

			let cells = arrow.points.map(pos => cells.at(repr(pos)))


			let intersection-stroke = if debug >= 2 {
				(paint: debug-color, thickness: 0.25pt)
			}

			let (p1, p2) = get-node-connectors(cells, options)

			cetz.draw.line(p1, p2, stroke: arrow.stroke + arrow.paint)

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
	pad: 20pt,
	debug: false,
	node-outset: 2pt,
	defocus: 0.6,
) = {

	if type(pad) != array { pad = (pad, pad) }

	let options = (
		pad: pad,
		debug: int(debug),
		node-outset: node-outset,
		defocus: defocus,
	)

	let positional-args = args.pos().join()

	let nodes = positional-args.filter(e => e.kind == "node")
	let arrows = positional-args.filter(e => e.kind == "arrow")

	box(style(styles => {

		let nodes-sized = nodes.map(node => {
			let (width, height) = measure(node.label, styles)
			node.size = (width, height)
			node
		})

		let (grid, cells) = compute-layout(nodes-sized, options)

		draw-diagram(grid, cells, nodes-sized, arrows, options)

	}))
}

