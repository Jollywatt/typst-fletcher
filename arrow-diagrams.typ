#import "@local/cetz:0.1.2" as cetz: vector

#import calc: floor, ceil, min, max

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



#let node(pos, label) = {
	assert(type(pos) == array and pos.len() == 2)
	((
		kind: "node",
		pos: pos,
		label: label,
	),)
}

#let arrow(from, to, label: none, paint: auto) = {
	((
		kind: "arrow",
		points: (from, to),
		paint: paint,
	),)
	node(from, none)
	node(to, none)
}

#let debug-color = red




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
		rect.pos = vector.sub(rect.pos, coord-origin)
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
		cell.aspect = max(w/h, h/w)
		cell.radius = calc.sqrt((w/2pt)*(w/2pt) + (h/2pt)*(h/2pt))*1pt

		cell.rect = (+1, -1).map(dir => {
			vector.add(cell.real-pos,
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

			let cell = cells.at(repr(node.pos))

			cetz.draw.content(cell.real-pos, node.label, anchor: "center")

			if debug >= 1 {
				cetz.draw.circle(
					cell.real-pos,
					radius: .5pt,
					fill: debug-color,
					stroke: none,
				)
			}
			if debug >= 3 {
				cetz.draw.rect(
					vector.sub(cell.real-pos, vector.div(node.size, 2)),
					vector.add(cell.real-pos, vector.div(node.size, 2)),
					stroke: debug-color + 0.25pt,
				)
				cetz.draw.circle(
					cell.real-pos,
					radius: cell.radius,
					stroke: debug-color + 0.25pt,
				)
			}
		}



		for arrow in arrows {

			let cells = arrow.points.map(pos => cells.at(repr(pos)))


			let intersection-stroke = if debug >= 2 {
				(paint: debug-color, thickness: 0.25pt)
			}

			cetz.draw.intersections(name: "point-pair", {

				cetz.draw.line(
					..cells.map(cell => cell.real-pos),
					stroke: none,
				)

				
				for cell in cells {

					let gap = options.node-outset

					if cell.aspect <= 2 {
						cetz.draw.circle(
							vector.scale(cell.real-pos, 1 + 1e-5), // bug with intersections, this adds noise which seems to fix it
							radius: cell.radius + gap,
							stroke: intersection-stroke,
						)
					} else {
						cetz.draw.rect(
							..cell.rect.zip((+1, -1)).map(((corner, dir)) => {
								let extra = (gap, gap)
								vector.add(corner, vector.scale(extra, dir))
							}),
							radius: gap,
							stroke: intersection-stroke,
						)
					}
				}
			})

			// cetz.draw.for-each-anchor("point-pair", name => {
			// 	cetz.draw.circle(
			// 		"point-pair."+name,
			// 		radius: 1pt,
			// 		stroke: intersection-stroke,
			// 	)
			// 	cetz.draw.content(
			// 		"point-pair."+name,
			// 		text(size: 0.5em, name)
			// 	)
			// })

			cetz.draw.line(
				"point-pair.0",
				"point-pair.1",
				mark: (start: ">"),
				stroke: .6pt,
				// (0,0)
			)
		}



		// draw axes
		if debug >= 1 {

			cetz.draw.rect(
				(0,0),
				grid.bounding-size,
				stroke: debug-color + 0.25pt
			)

			let gridline = (paint: debug-color, thickness: 0.25pt, dash: "densely-dotted")
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
						..(+1, -1).map(dir => coord(x + dir*size/2, 0)),
						stroke: debug-color + .75pt,
						mark: (start: "|", end: "|")
					)

					// gridline
					cetz.draw.line(
						coord(x, 0),
						coord(x, grid.bounding-size.at(1 - axis)),
						stroke: gridline,
					)
				}
			}

		}
	})	
}


#let arrow-diagram(
	..args,
	pad: 0pt,
	debug: false,
	node-outset: 4pt,
) = {

	if type(pad) != array { pad = (pad, pad) }

	let options = (
		pad: pad,
		debug: int(debug),
		node-outset: node-outset,
	)

	let positional-args = args.pos().join()

	let nodes = positional-args.filter(e => e.kind == "node")
	let arrows = positional-args.filter(e => e.kind == "arrow")

	style(styles => {

		let nodes-sized = nodes.map(node => {
			let (width, height) = measure(node.label, styles)
			node.size = (width, height)
			node
		})

		let (grid, cells) = compute-layout(nodes-sized, options)

		draw-diagram(grid, cells, nodes-sized, arrows, options)

	})
}

