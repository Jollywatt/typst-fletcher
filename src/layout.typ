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


/// Determine the number, sizes and relative positions of rows and columns in
/// the diagram's coordinate grid.
///
/// Rows and columns are sized to fit nodes. Coordinates are not required to
/// start at the origin, `(0,0)`.
#let compute-grid(nodes, edges, options) = {
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

	// Initialise row and column sizes to minimum size
	let cell-sizes = zip(options.cell-size, bounding-dims)
		.map(((min-size, n)) => range(n).map(_ => min-size))

	// Expand cells to fit rects
	for rect in rects {
		let indices = vector.sub(rect.center, origin)
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

	assert(options.axes.at(0).axis() != options.axes.at(1).axis(), message: "Axes cannot both be in the same direction; try `(ltr, ttb)`.")

	let flip = options.axes.map(a => a.axis()) == ("vertical", "horizontal")

	if flip { options.axes = options.axes.rev() }

	let scale = (
		if options.axes.at(0) == ltr { +1 } else if options.axes.at(0) == rtl { -1 },
		if options.axes.at(1) == btt { +1 } else if options.axes.at(1) == ttb { -1 },
	)

	let get-coord(coord) = {
		zip(if flip { coord.rev() } else { coord }, cell-centers, origin, scale)
			.map(((x, c, o, s)) => s*lerp-at(c, x - o))
	}

	(
		centers: cell-centers,
		sizes: cell-sizes,
		origin: origin,
		bounding-size: total-size,
		scale: scale,
		get-coord: get-coord,
	)
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