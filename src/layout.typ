#import "utils.typ": *


#let compute-node-sizes(nodes, styles) = nodes.map(node => {

	// Determine physical size of node content
	let (width, height) = measure(node.label, styles)
	node.size = (width, height)
	node.radius = vector-len((width/2, height/2))
	node.aspect = if height == 0pt { 1 } else { width/height }

	if node.shape == auto {
		let is-roundish = max(node.aspect, 1/node.aspect) < 1.5
		node.shape = if is-roundish { "circle" } else { "rect" }
	}
	
	// add node inset
	if node.radius != 0pt {
		if node.shape == "circle" { 
			node.radius += node.inset/2
		} else {
			node.size = node.size.map(x => x + node.inset)
		}
	}

	node
})

#let to-physical-coords(grid, coord) = {
	zip(grid.centers, coord, grid.origin)
		.map(((c, x, o)) => lerp-at(c, x - o))
}

#let compute-node-positions(nodes, grid, options) = nodes.map(node => {

	node.real-pos = to-physical-coords(grid, node.pos)

	node.rect = (-1, +1).map(dir => vector.add(
		node.real-pos,
		vector.scale(node.size, dir/2),
	))

	node.outer-rect = rect-at(
		node.real-pos,
		node.size.map(x => x/2 + node.outset),
	)

	node

})


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

	// Initialise row and column sizes to minimum size
	let cell-sizes = zip(options.cell-size, bounding-dims)
		.map(((min-size, n)) => range(n).map(_ => min-size))

	// Expand cells to fit rects
	for rect in rects {
		let indices = vector.sub(rect.pos, origin)
		for axis in (0, 1) {
			cell-sizes.at(axis).at(indices.at(axis)) = max(
				cell-sizes.at(axis).at(indices.at(axis)),
				rect.size.at(axis),
			)

		}
	}

	// (x: (c1x, c2x, ...), y: ...)
	let cell-centers = zip(cell-sizes, options.spacing)
		.map(((sizes, spacing)) => {
			zip(cumsum(sizes), sizes, range(sizes.len()))
				.map(((end, size, i)) => end - size/2 + spacing*i)
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


