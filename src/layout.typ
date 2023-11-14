#import "utils.typ": *


/// Convert an array of rects with fractional positions into rects with integral
/// positions.
/// 
/// If a rect is centered at a factional position `floor(x) < x < ceil(x)`, it
/// will be replaced by two new rects centered at `floor(x)` and `ceil(x)`. The
/// total width of the original rect is split across the two new rects according
/// two which one is closer. (E.g., if the original rect is at `x = 0.25`, the
/// new rect at `x = 0` has 75% the original width and the rect at `x = 1` has
/// 25%.) The same splitting procedure is done for `y` positions and heights.
///
/// - rects (array of rects): An array of rectangles of the form
///   `(pos: (x, y), size: (width, height))`. The coordinates `x` and `y` may be
///   floats.
/// -> array of rects
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
	let bounding-rect = zip((0, 0), ..rects.map(n => n.pos)).map(min-max)
	let bounding-dims = bounding-rect.map(((min, max)) => max - min + 1)
	let origin = bounding-rect.map(((min, max)) => min)

	// (x: (0pt, 0pt, ...), y: ...)
	let cell-sizes = bounding-dims.map(n => range(n).map(_ => 0pt))

	let (cell-size-width, cell-size-height) = options.at("cell-size", default: (0pt, 0pt))

	for rect in rects {
		let coords = vector.sub(rect.pos, origin)
		for axis in (0, 1) {
			cell-sizes.at(axis).at(coords.at(axis)) = max(
				cell-sizes.at(axis).at(coords.at(axis)),
				rect.size.at(axis),
				options.cell-size.at(axis),
			)

		}
	}

	// (x: (c1x, c2x, ...), y: ...)
	let cell-centers = zip(cell-sizes, options.gutter)
		.map(((sizes, gutter)) => {
			zip(cumsum(sizes), sizes, range(sizes.len()))
				.map(((end, size, i)) => end - size/2 + gutter*i)
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

/// Compute a lookup table of the attributes of each grid cell.
///
/// - nodes (array): Array of nodes to consider when calculating the sizes of
///  cells, where each node of the form:
/// ```
/// (
/// 	pos: (i, j),
/// 	size: (width, height),
/// )
/// ```
/// - grid (dictionary): Grid specification of the form
/// ```
/// (
/// 	origin: (i, j),
/// 	centers: ((x1, x2, ...), (y1, y2, ...)),
/// )
/// ```
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
				cell.radius += options.node-pad*0.5
			} else {
				cell.size = cell.size.map(x => x + options.node-pad)
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




#let get-node-connector(cell, incident-angle, options) = {

	if cell.radius < 1e-3pt { return cell.real-pos }

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
		let origin-δ = (
			-calc.max(0pt, cell.size.at(0)/2*(1 - 1/μ))*calc.cos(incident-angle),
			-calc.max(0pt, cell.size.at(1)/2*(1 - μ/1))*calc.sin(incident-angle),
		)
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