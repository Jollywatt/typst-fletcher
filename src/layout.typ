#import "utils.typ": *
#import "shapes.typ"


/// Convert from elastic to absolute coordinates, $(u, v) |-> (x, y)$.
///
/// _Elastic coordinates_ are specific to the diagram and adapt to row/column
/// sizes; _absolute coordinates_ are the final, physical lengths which are
/// passed to `cetz`.
///
/// - grid (dictionary). Representation of the grid layout, including:
///   - `origin`
///   - `centers`
///   - `spacing`
///   - `flip`
/// -> coord
#let uv-to-xy(grid, uv-coord) = {
	let (i, j) = vector.sub(uv-coord, grid.origin)

	let (n-x, n-y) = grid.centers.map(array.len)
	if grid.flip.xy { (n-x, n-y) = (n-y, n-x) }
	if grid.flip.x { i = (n-x - 1) - i }
	if grid.flip.y { j = (n-y - 1) - j }
	if grid.flip.xy { (i, j) = (j, i) }

	(i, j).zip(grid.centers, grid.spacing)
		.map(((t, c, s)) => interp(c, t, spacing: s))
}

/// Convert from absolute to elastic coordinates, $(x, y) |-> (u, v)$.
///
/// _Absolute coordinates_ are the final, physical lengths which are passed to
/// `cetz`; _elastic coordinates_ are specific to the diagram and adapt to
/// row/column sizes.
///
/// - grid (dictionary). Representation of the grid layout, including:
///   - `origin`
///   - `centers`
///   - `spacing`
///   - `flip`
/// -> coord
#let xy-to-uv(grid, xy-coord) = {
	let (i, j) = xy-coord.zip(grid.centers, grid.spacing)
		.map(((x, c, s)) => interp-inv(c, x, spacing: s))

	let (n-x, n-y) = grid.centers.map(array.len)
	if grid.flip.xy { (n-x, n-y) = (n-y, n-x) }
	if grid.flip.xy { (i, j) = (j, i) }
	if grid.flip.x { i = (n-x - 1) - i }
	if grid.flip.y { j = (n-y - 1) - j }

	vector.add((i, j), grid.origin)
}

/// Jacobian of the coordinate map `uv-to-xy()`.
///
/// Used to convert a "nudge" in $u v$ coordinates to a "nudge" in $x y$
/// coordinates. This is needed because $u v$ coordinates are non-linear
/// (they're elastic).
///
/// Uses a balanced finite differences approximation.
///
/// - grid (dictionary): Representation of the grid layout.
/// - uv (array): The point in the $u v$-manifold where the shift tangent vector
///   is rooted.
/// - duv (array): The shift tangent vector in $u v$ coordinates.
#let duv-to-dxy(grid, uv, duv) = {
	let duv = vector.scale(duv, 0.5)
	vector.sub(
		uv-to-xy(grid, vector.add(uv, duv)),
		uv-to-xy(grid, vector.sub(uv, duv)),
	)
}

/// Jacobian of the coordinate map `xy-to-uv()`.
#let dxy-to-duv(grid, xy, dxy) = {
	let dxy = vector.scale(dxy, 0.5)
	vector.sub(
		xy-to-uv(grid, vector.add(xy, dxy)),
		xy-to-uv(grid, vector.sub(xy, dxy)),
	)
}


// #let shift-to-dxy(grid, uv, d) = {
// 	let duv = d.map(δ => if type(δ) == length { 0 } else { δ })
// 	let dxy = duv-to-dxy(grid, uv, duv)
// 	vector.add(dxy, d.map(δ => if type(δ) == length { δ } else { 0pt }))
// }

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
		flip: (
			xy: flip,
			x: axes.at(0) in (rtl, ttb),
			y: axes.at(1) in (rtl, ttb),
		)
	)
}



/// Determine the sizes of grid cells from nodes and edges.
///
/// Returns a dictionary with:
/// - `origin: (u-min, v-min)` Coordinate at the grid corner where elastic/`uv`
///   coordinates are minimised.
/// - `cell-sizes: (x-sizes, y-sizes)` Lengths and widths of each row and
///   column.
///
/// - grid (dicitionary): Representation of the grid layout, including:
///   - `flip`
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
	let cell-sizes = bounding-dims.map(n => (0pt,)*n)

	// Expand cells to fit rects
	for rect in rects {
		let indices = vector.sub(rect.center, origin)
		if grid.flip.x { indices.at(0) = -1 - indices.at(0) }
		if grid.flip.y { indices.at(1) = -1 - indices.at(1) }
		for axis in (0, 1) {
			let size = if grid.flip.xy { rect.size.at(axis) } else { rect.size.at(1 - axis) }
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

	// enforce minimum cell size
	grid.cell-sizes = grid.cell-sizes.zip(options.cell-size)
		.map(((sizes, min-size)) => sizes.map(calc.max.with(min-size)))
		
	grid += compute-cell-centers(grid)

	grid
}


#let vector-polar-with-xy-or-uv-length(grid, xy, target-length, θ) = {
	if type(target-length) == length {
		vector-polar(target-length, θ)
	} else {
		let unit = vector-polar(1pt, θ)
		let det = vector.len(dxy-to-duv(grid, xy, unit))
		vector.scale(unit, target-length/det)
	}
}

#let apply-edge-shift-line(grid, edge) = {
	// apply edge shift
	let (from-xy, to-xy) = edge.final-vertices
	let θ = vector-angle(vector.sub(to-xy, from-xy)) + 90deg

	let (δ-from, δ-to) = edge.shift
	let δ⃗-from = vector-polar-with-xy-or-uv-length(grid, from-xy, δ-from, θ)
	let δ⃗-to = vector-polar-with-xy-or-uv-length(grid, to-xy, δ-to, θ)

	edge.final-vertices.at( 0) = vector.add(edge.final-vertices.at( 0), δ⃗-from)
	edge.final-vertices.at(-1) = vector.add(edge.final-vertices.at(-1), δ⃗-to)

	edge

}

#let apply-edge-shift-arc(grid, edge) = {
	let (from, to) = edge.vertices
	let (from-xy, to-xy) = edge.final-vertices

	let θ = vector-angle(vector.sub(to-xy, from-xy)) + 90deg
	let (θ-from, θ-to) = (θ + edge.bend, θ - edge.bend)

	let (δ-from, δ-to) = edge.shift
	let δ⃗-from = vector-polar-with-xy-or-uv-length(grid, from-xy, δ-from, θ-from)
	let δ⃗-to   = vector-polar-with-xy-or-uv-length(grid, to-xy, δ-to, θ-to)

	edge.final-vertices.at( 0) = vector.add(edge.final-vertices.at( 0), δ⃗-from)
	edge.final-vertices.at(-1) = vector.add(edge.final-vertices.at(-1), δ⃗-to)

	edge

}

#let apply-edge-shift-poly(grid, edge) = {
	let end-segments = (
		edge.final-vertices.slice(0, 2), // first two vertices
		edge.final-vertices.slice(-2), // last two vertices
	)

	let θs = (
		vector-angle(vector.sub(..end-segments.at(0))),
		vector-angle(vector.sub(..end-segments.at(1))),
	)

	let ends = (edge.final-vertices.at(0), edge.final-vertices.at(-1))
	let δs = edge.shift.zip(ends, θs).map(((d, xy, θ)) => {
		vector-polar-with-xy-or-uv-length(grid, xy, d, θ + 90deg)
	})

	// the `shift` option is nicer if it shifts the entire segment, not just the first vertex
	// first segment
	edge.final-vertices.at(0) = vector.add(edge.final-vertices.at(0), δs.at(0))
	edge.final-vertices.at(1) = vector.add(edge.final-vertices.at(1), δs.at(0))
	// last segment
	edge.final-vertices.at(-2) = vector.add(edge.final-vertices.at(-2), δs.at(1))
	edge.final-vertices.at(-1) = vector.add(edge.final-vertices.at(-1), δs.at(1))

	edge


}

#let apply-edge-shift(grid, edge) = {
	if edge.kind == "line" { apply-edge-shift-line(grid, edge) }
	else if edge.kind == "arc" { apply-edge-shift-arc(grid, edge) }
	else if edge.kind == "poly" { apply-edge-shift-poly(grid, edge) }
	else { edge }
}