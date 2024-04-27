#import "utils.typ": *
#import "coords.typ": *
#import "shapes.typ"


/// Measure node labels with the style context and resolve node shapes.
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

		let inner-size = node.size.map(pass-auto(i => i - 2*node.inset))
		let (width, height) = measure(box(
			node.label,
			width:  inner-size.at(0),
			height: inner-size.at(1),
		), styles)
		// Determine physical size of node content
		// let (width, height) = node.inner-size
		let radius = vector-len((width/2, height/2)) // circumcircle

		node.aspect = if width == 0pt or height == 0pt { 1 } else { width/height }

		if node.shape == auto {
			let is-roundish = calc.max(node.aspect, 1/node.aspect) < 1.5
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


#let compute-node-enclosures(nodes, grid) = {
	let nodes = nodes.map(node => {
		if node.enclose.len() == 0 { return node }

		let enclosed-vertices = node.enclose.map(key => {

			let near-node = find-node(nodes, key)

			if near-node == none or near-node == node {
				(uv-to-xy(grid, key),)
			} else {
				let (x, y) = near-node.final-pos
				let (w, h) = near-node.size
				(
					(x - w/2, y - h/2),
					(x - w/2, y + h/2),
					(x + w/2, y - h/2),
					(x + w/2, y + h/2),
				)
			}
		}).join()

		let (center, size) = bounding-rect(enclosed-vertices)

		node.final-pos = center
		node.size = vector-max(
			size.map(d => d + node.inset*2),
			node.size,
		)
		node.shape = shapes.rect

		node
	})

	nodes
}

/// Convert an array of rects `(center: (x, y), size: (w, h))` with fractional
/// positions into rects with integral positions.
///
/// If a rect is centered at a factional position `floor(x) < x < ceil(x)`, it
/// will be replaced by two new rects centered at `floor(x)` and `ceil(x)`. The
/// total width of the original rect is split across the two new rects according
/// two which one is closer. (E.g., if the original rect is at `x = 0.25`, the
/// new rect at `x = 0` has 75% the original width and the rect at `x = 1` has
/// 25%.) The same splitting procedure is done for `y` positions and heights.
///
/// - rects (array): An array of rects of the form `(center: (x, y), size:
///   (width, height))`. The coordinates `x` and `y` may be floats.
/// -> array
#let expand-fractional-rects(rects) = {
	import calc: trunc, floor, ceil

	let new-rects
	for axis in (0, 1) {
		new-rects = ()
		for rect in rects {
			let coord = rect.center.at(axis)
			let size = rect.size.at(axis)

			if calc.fract(coord) == 0 {
				rect.center.at(axis) = trunc(coord)
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


/// Interpret #the-param[diagram][axes].
///
/// Returns a dictionary with:
/// - `x`: Whether $u$ is reversed
/// - `y`: Whether $v$ is reversed
/// - `xy`: Whether the axes are swapped
///
/// - axes (array): Pair of directions specifying the interpretation of $(u, v)$
///   coordinates. For example, `(ltr, ttb)` means $u$ goes $arrow.r$ and $v$
///   goes $arrow.b$.
/// -> dictionary
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
			x: axes.at(0) in (rtl, ttb),
			y: axes.at(1) in (rtl, ttb),
			xy: flip,
		)
	)
}



/// Determine the number and sizes of grid cells needed for a diagram with the
/// given nodes and edges.
///
/// Returns a dictionary with:
/// - `origin: (u-min, v-min)` Coordinate at the grid corner where elastic/`uv`
///   coordinates are minimised.
/// - `cell-sizes: (x-sizes, y-sizes)` Lengths and widths of each row and
///   column.
///
/// - grid (dicitionary): Representation of the grid layout, including:
///   - `flip`
#let compute-cell-sizes(grid, edges, nodes) = {
	let rects = nodes.map(node => (center: node.pos, size: node.size))
	rects = expand-fractional-rects(rects)

	// all points in diagram that should be spanned by coordinate grid
	let points = rects.map(r => r.center)
	points += edges.map(edge => edge.vertices).join()

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
			cell-sizes.at(axis).at(indices.at(axis)) = calc.max(
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
	let centers = array.zip(grid.cell-sizes, grid.spacing)
		.map(((sizes, spacing)) => {
			array.zip(cumsum(sizes), sizes, range(sizes.len()))
				.map(((end, size, i)) => end - size/2 + spacing*i)
		})

	let bounding-size = array.zip(centers, grid.cell-sizes).map(((centers, sizes)) => {
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
	grid += compute-cell-sizes(grid, edges, nodes)

	// enforce minimum cell size
	grid.cell-sizes = grid.cell-sizes.zip(options.cell-size)
		.map(((sizes, min-size)) => sizes.map(calc.max.with(min-size)))
		
	grid += compute-cell-centers(grid)

	grid
}





#let apply-edge-shift-line(grid, edge) = {
	let (from-xy, to-xy) = edge.final-vertices
	let θ = vector-angle(vector.sub(to-xy, from-xy)) + 90deg

	let (δ-from, δ-to) = edge.shift
	let δ⃗-from = vector-polar-with-xy-or-uv-length(grid, from-xy, δ-from, θ)
	let δ⃗-to = vector-polar-with-xy-or-uv-length(grid, to-xy, δ-to, θ)

	edge.final-vertices.at( 0) = vector.add(from-xy, δ⃗-from)
	edge.final-vertices.at(-1) = vector.add(to-xy, δ⃗-to)

	edge

}


#let apply-edge-shift-arc(grid, edge) = {
	let (from-xy, to-xy) = edge.final-vertices

	let θ = vector-angle(vector.sub(to-xy, from-xy)) + 90deg
	let (θ-from, θ-to) = (θ + edge.bend, θ - edge.bend)

	let (δ-from, δ-to) = edge.shift
	let δ⃗-from = vector-polar-with-xy-or-uv-length(grid, from-xy, δ-from, θ-from)
	let δ⃗-to   = vector-polar-with-xy-or-uv-length(grid, to-xy, δ-to, θ-to)

	edge.final-vertices.at( 0) = vector.add(from-xy, δ⃗-from)
	edge.final-vertices.at(-1) = vector.add(to-xy, δ⃗-to)

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


/// Apply #the-param[edge][shift] by translating edge vertices.
///
/// - grid (dicitionary): Representation of the grid layout. This is needed to
///   support shifts specified as coordinate lengths.
/// - edge (dictionary): The edge with a `shift` entry.
#let apply-edge-shift(grid, edge) = {
	if edge.kind == "line" { apply-edge-shift-line(grid, edge) }
	else if edge.kind == "arc" { apply-edge-shift-arc(grid, edge) }
	else if edge.kind == "poly" { apply-edge-shift-poly(grid, edge) }
	else { edge }
}


