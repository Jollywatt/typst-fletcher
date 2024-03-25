#import "utils.typ": *
#import "shapes.typ"

/// Resolve the sizes of nodes.
///
/// Widths and heights that are `auto` are determined by measuring the size of
/// the node's label.
#let compute-node-sizes(nodes, styles) = nodes.map(node => {

	// Width and height explicitly given
	if auto not in node.size {
		let (width, height) = node.size
		node.radius = vector-len((width/2, height/2))
		node.aspect = width/height

	// Radius explicitly given
	} else if node.radius != auto {
		node.size = (2*node.radius, 2*node.radius)
		node.aspect = 1

	// Width and/or height set to auto
	} else {

		// Determine physical size of node content
		let (width, height) = measure(node.label, styles)
		let radius = vector-len((width/2, height/2)) // circumcircle

		node.aspect = if width == 0pt or height == 0pt { 1 } else { width/height }

		if node.shape == auto {
			let is-roundish = max(node.aspect, 1/node.aspect) < 1.5
			node.shape = if is-roundish { "circle" } else { "rect" }
		}

		// Add node inset
		if radius != 0pt { radius += node.inset }
		if width != 0pt and height != 0pt {
			width += 2*node.inset
			height += 2*node.inset
		}

		// If width/height/radius is auto, set to measured width/height/radius
		node.size = node.size.zip((width, height))
			.map(((given, measured)) => map-auto(given, measured))
		node.radius = map-auto(node.radius, radius)

	}

	if node.shape in (circle, "circle") { node.shape = shapes.circle }
	if node.shape in (rect, "rect") { node.shape = shapes.rect }

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
///   `(center: (x, y), size: (width, height))`. The coordinates `x` and `y` may be
///   floats.
/// -> array of rects
#let expand-fractional-rects(rects) = {
	let new-rects
	for axis in (0, 1) {
		new-rects = ()
		for rect in rects {
			let coord = rect.center.at(axis)
			let size = rect.size.at(axis)

			if calc.fract(coord) == 0 {
				rect.center.at(axis) = calc.trunc(coord)
				new-rects.push(rect)
			} else {
				rect.center.at(axis) = floor(coord)
				rect.size.at(axis) = size*(ceil(coord) - coord)
				new-rects.push(rect)

				rect.center.at(axis) = ceil(coord)
				rect.size.at(axis) = size*(coord - floor(coord))
				new-rects.push(rect)
			}
		}
		rects = new-rects
	}
	new-rects
}


// TODO: this should replace grid.get-coord
#let to-final-coord(grid, coord) = {
	let flip = grid.axes.at(0) in (btt, ttb)
	let scale = grid.axes.map(axis => if axis in (rtl, btt) { -1 } else { +1 })
	let coord = if flip { coord.rev() } else { coord }
	coord.zip(
		grid.centers,
		grid.sizes,
		grid.spacing,
		grid.origin,
		scale,
	).map(((x, c, w, gap, o, s)) => {
		let t = x - o
		let t-max = c.len() - 1
		s*if t < 0 {
			c.at(0) + w.at(0)/2*calc.max(t, -1) + gap*t
		} else if t > t-max {
			c.at(-1) + w.at(-1)/2*calc.min(t - t-max, 1) + gap*(t - t-max)
		} else {
			lerp-at(c, x - o)
		}
	})

}

#let interpret-axes(axes) = {
	let dirs = axes.map(direction.axis)
	let flip
	if dirs == ("horizontal", "vertical") {
		flip = false
	} else if dirs == ("vertical", "horizontal") {
		flip = true
	} else {
		panic("Axes cannot both be in the same direction. Got `" + repr(axes) + "`, try `axes: (ltr, ttb)`.")
	}
	(
		xy-flip: flip,
		x-flip: axes.at(0) in (rtl, ttb),
		y-flip: axes.at(1) in (rtl, ttb),
	)
}

#let uv-to-xy(grid, uv-coord) = {
	let (i, j) = vector.sub(uv-coord, grid.origin)
	let (n-x, n-y) = grid.centers.map(array.len)
	if grid.xy-flip { (n-x, n-y) = (n-y, n-x) }
	if grid.x-flip { i = (n-x - 1) - i }
	if grid.y-flip { j = (n-y - 1) - j }
	if grid.xy-flip { (i, j) = (j, i) }

	(i, j).zip(grid.centers, grid.spacing).map(((t, c, s)) => {
		interp(c, t, spacing: s)
	})
}


/// Determine the sizes of grid cells from nodes and edges.
///
/// Returns a dictionary with:
/// - `origin: (u-min, v-min)` Coordinate at the grid corner where elastic/`uv``
///   coordinates are minimised.
/// - `cell-sizes: (x-sizes, y-sizes)` Lengths and widths of each row and
///   column.
///
/// - grid (dicitionary): Representation of the grid layout, including:
///   - `x-flip`
///   - `y-flip`
///   - `xy-flip`
/// -> dictionary
#let compute-cell-sizes(grid, nodes, edges) = {
	let rects = nodes.map(node => (center: node.pos, size: node.size))
	rects = expand-fractional-rects(rects)

	// all points in diagram that should be spanned by coordinate grid
	let points = rects.map(r => r.center)
	points += edges.map(e => e.vertices).join()

	if points.len() == 0 { points.push((0,0)) }

	let min-max-int(a) = (calc.floor(calc.min(..a)), calc.ceil(calc.max(..a)))
	let (x-min, x-max) = min-max-int(points.map(p => p.at(0)))
	let (y-min, y-max) = min-max-int(points.map(p => p.at(1)))
	let origin = (x-min, y-min)
	let bounding-dims = (x-max - x-min + 1, y-max - y-min + 1)

	// Initialise row and column sizes
	let cell-sizes = bounding-dims.map(n => range(n).map(_ => 0pt))

	// Expand cells to fit rects
	for rect in rects {
		let indices = vector.sub(rect.center, origin)
		if grid.x-flip { indices.at(0) = -1 - indices.at(0) }
		if grid.y-flip { indices.at(1) = -1 - indices.at(1) }
		for axis in (0, 1) {
			let size = if grid.xy-flip { rect.size.at(axis) } else { rect.size.at(1 - axis) }
			cell-sizes.at(axis).at(indices.at(axis)) = max(
				cell-sizes.at(axis).at(indices.at(axis)),
				rect.size.at(axis),
			)

		}
	}

	(origin: origin, cell-sizes: cell-sizes)
}

/// Determine the centers of grid cells from their sizes and spacing between
/// them.
///
/// Returns the a dictionary with:
/// - `centers: (x-centers, y-centers)` Positions of each row and column,
///   measured from the corner of the bounding box.
/// - `bounding-size: (x-size, y-size)` Dimensions of the bounding box.
///
/// - grid (dictionary): Representation of the grid layout, including:
///   - `cell-sizes: (x-sizes, y-sizes)` Lengths and widths of each row and
///     column.
///   - `spacing: (x-spacing, y-spacing)` Gap to leave between cells.
/// -> dictionary
#let compute-cell-centers(grid) = {
	// (x: (c1x, c2x, ...), y: ...)
	let centers = zip(grid.cell-sizes, grid.spacing)
		.map(((sizes, spacing)) => {
			zip(cumsum(sizes), sizes, range(sizes.len()))
				.map(((end, size, i)) => end - size/2 + spacing*i)
		})

	let bounding-size = zip(centers, grid.cell-sizes).map(((centers, sizes)) => {
		centers.at(-1) + sizes.at(-1)/2
	})

	(
		centers: centers,
		bounding-size: bounding-size,
	)
}

/// Determine the number, sizes and relative positions of rows and columns in
/// the diagram's coordinate grid.
///
/// Rows and columns are sized to fit nodes. Coordinates are not required to
/// start at the origin, `(0,0)`.
#let compute-grid(nodes, edges, options) = {

	let grid = (
		axes: options.axes,
		spacing: options.spacing,
	)
	grid += interpret-axes(grid.axes)
	grid += compute-cell-sizes(grid, nodes, edges)

	// ensure minimum cell size
	grid.cell-sizes = grid.cell-sizes.zip(options.cell-size)
		.map(((sizes, min-size)) => sizes.map(calc.max.with(min-size)))
		
	grid += compute-cell-centers(grid)

	grid.get-coord = uv-to-xy.with(grid)
	grid
}


/// Convert elastic diagram coordinates in nodes and edges to canvas coordinates
///
/// Nodes have a `pos` (elastic coordinates) and `final-pos` (canvas
/// coordinates), and edges have `from`, `to`, and `vertices` (all canvas
/// coordinates).
#let compute-final-coordinates(nodes, edges, grid, options) = (
	nodes: nodes.map(node => {
		node.final-pos = (options.get-coord)(node.pos)
		node
	}),
	edges: edges.map(edge => {
		edge.final-vertices = edge.vertices.map(options.get-coord)
		edge
	}),
)
