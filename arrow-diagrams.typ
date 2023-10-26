#import calc: floor, ceil, min, max

#let v-add((x1, y1), (x2, y2)) = (x1 + x2, y1 + y2)
#let v-mul(s, (x, y)) = (s*x, s*y)
#let v-sub(a, b) = v-add(a, v-mul(-1, b))
#let v-polar(r, θ) = (r*calc.cos(θ), r*calc.sin(θ))
#let v-len((x, y)) = calc.sqrt(x*x + y*y)
#let v-angle((x, y)) = calc.atan2(x.pt(), y.pt())

#let min-max(array) = (calc.min(..array), calc.max(..array))

#let cumsum(array) = {
	let sum = array.at(0)
	for i in range(1, array.len()) {
		sum += array.at(i)
		array.at(i) = sum
	}
	array
}

#let lerp(a, b, t) = a*(1 - t) + b*t
#let lerp-at(array, t) = lerp(
	array.at(floor(t)),
	array.at(ceil(t)),
	calc.fract(t),
)

#let zip(a, ..others) = if others.pos().len() == 0 {
	a.map(i => (i,))
} else {
	a.zip(..others)
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
#let compute-grid(rects, pad) = {
	// (x: (x-min, x-max), y: ...)
	let bounding-rect = zip(..rects.map(n => n.pos)).map(min-max)

	// (x: n-cols, y: n-rows)
	let bounding-dims = bounding-rect.map(((min, max)) => max - min + 1)

	let coord-origin = bounding-rect.map(((min, max)) => min)
	rects = rects.map(rect => {
		rect.pos = v-sub(rect.pos, coord-origin)
		let (x, y) = rect.pos
		if x < 0 or y < 0 { panic(rect) }
		rect
	})

	// (x: (0pt, 0pt, ...), y: ...)
	let cell-sizes = bounding-dims.map(n => range(n).map(_ => 0pt))

	for rect in rects {
		let (col, row) = rect.pos
		let (width, height) = rect.size
		cell-sizes.at(0).at(col) = calc.max(cell-sizes.at(0).at(col), width)
		cell-sizes.at(1).at(row) = calc.max(cell-sizes.at(1).at(row), height)
	}

	// (x: (c1x, c2x, ...), y: ...)
	let cell-centers = cell-sizes.zip(pad).map(((sizes, gap)) => {
		cumsum(sizes).zip(sizes, range(sizes.len())).map(((end, size, i)) => end - size/2 + gap*i)
	})

	let total-size = cell-centers.zip(cell-sizes).map(((centers, sizes)) => {
		centers.at(-1) + sizes.at(-1)/2
	})

	(
		centers: cell-centers,
		sizes: cell-sizes,
		origin: coord-origin,
		bounding-size: total-size
	)
}	

// #let compute-cell-radii(nodes) = {
// 	let lookup = ()
// 	for node in nodes {

// 	}
// }


#let node(pos, label) = (
	(
		kind: "node",
		pos: pos,
		label: label,
	),
)

#let arrow(from, to, label: none, paint: auto) = (
	(
		kind: "arrow",
		from: from,
		to: to,
		paint: paint,
	),
) + node(from, none) + node(to, none)

#let arrow-diagram(
	pad: 0pt,
	debug: false,
	..entities,
) = {

	debug = int(debug)

	if type(pad) != array { pad = (pad, pad) }

	entities = entities.pos().join()
	// panic(entities)

	let nodes = entities.filter(e => e.kind == "node")
	let arrows = entities.filter(e => e.kind == "arrow")

	style(styles => {

		let nodes = nodes.map(node => {
			let (width, height) = measure(node.label, styles)
			node.size = (width, height)
			node.radius = calc.sqrt(
				(width/2pt)*(width/2pt) + (height/2pt)*(height/2pt)
			)*1pt
			node
		})

		let rects = (
			nodes.map(node => (pos: node.pos, size: node.size)),
			arrows.map(arrow => (pos: arrow.from, size: (0pt, 0pt))),
			arrows.map(arrow => (pos: arrow.to, size: (0pt, 0pt))),
		).join()

		rects = expand-fractional-rects(rects)
		let grid = compute-grid(rects, pad)

		// let radii = compute-cell-radii(nodes)

		// [radii: #radii]

		// wrap remaining content in a block of precomputed size
		show: diagram => block(
			stroke: if debug >= 1 { red + .25pt },
			width: grid.bounding-size.at(0),
			height: grid.bounding-size.at(1),
			diagram,
		)

		// draw axes
		if debug >= 2 {
			set text(size: .5em, red)
			set line(stroke: red)
			let gridline = (thickness: 0.25pt, dash: "densely-dotted")
			for (i, x) in grid.centers.at(0).enumerate() {
				place(dx: x, dy: -.5em, place(center + bottom, [#(grid.origin.at(0) + i)]))
				place(dx: x, place(center, line(stroke: 1pt, length: grid.sizes.at(0).at(i))))
				place(top, dx: x, line(angle: 90deg, length: grid.bounding-size.at(1), stroke: gridline))
			}
			for (i, y) in grid.centers.at(1).enumerate() {
				place(dy: y, dx: -.5em, place(horizon + right, [#(grid.origin.at(1) + i)]))
				place(dy: y, place(horizon, line(stroke: 1pt, angle: 90deg, length: grid.sizes.at(1).at(i))))
				place(dy: y, line(angle: 0deg, length: grid.bounding-size.at(0), stroke: gridline))
			}
		}

		let to-real-coords(coords) = {
			grid.centers.zip(coords, grid.origin).map(((centers, coord, origin)) => {
				lerp-at(centers, coord - origin)
			})
		}

		let place-at-node(node, item) = {
			let (x, y) = to-real-coords(node.pos)
			place(dx: x, dy: y, place(center + horizon, item))
		}

		for node in nodes {
			place-at-node(node, node.label)

			if debug >= 1 {
				place-at-node(node, rect(stroke: rgb("f00") + 0.25pt, width: node.size.at(0), height: node.size.at(1)))
				place-at-node(node, circle(radius: 1pt, fill: red, stroke: white + 0.5pt))
			}
			if debug >= 2 {
				place-at-node(node, circle(radius: node.radius, stroke: rgb("f004") + 0.25pt))
			}
		}

		for arrow in arrows {
			let r-from = max(0pt, ..nodes.filter(node => node.pos == arrow.from).map(node => node.radius))
			let r-to = max(0pt, ..nodes.filter(node => node.pos == arrow.to).map(node => node.radius))

			let θ = v-angle(v-sub(to-real-coords(arrow.to), to-real-coords(arrow.from)))
			// panic(θ)
			let (θ-from, θ-to) = (θ, θ)

			let paint = if arrow.paint == auto { black } else { arrow.paint }
			place(
				line(
					start: v-add(to-real-coords(arrow.from), v-polar(r-from, θ-from)),
					end: v-sub(to-real-coords(arrow.to), v-polar(r-to, θ-to)),
					stroke: (paint: paint, thickness: 0.5pt, cap: "round"),
				),
			)
		}

	})

}


