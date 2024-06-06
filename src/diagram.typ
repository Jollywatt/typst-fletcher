#import "utils.typ": *
#import "node.typ": *
#import "edge.typ": *
#import "draw.typ": draw-diagram
#import "coords.typ": *
#import "cetz-rework.typ": is-grid-independent-uv-coordinate, default-ctx, resolve, is-nan-coord



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
/// This is the algorithm used to determine grid layout in diagrams.
///
/// - rects (array): An array of rects of the form
///   `(center: (x, y), size: (width, height))`. The coordinates `x` and `y` may
///   be floats.
/// -> array
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
				rect.center.at(axis) = calc.floor(coord)
				rect.size.at(axis) = size*(calc.ceil(coord) - coord)
				new-rects.push(rect)

				rect.center.at(axis) = calc.ceil(coord)
				rect.size.at(axis) = size*(coord - calc.floor(coord))
				new-rects.push(rect)
			}
		}
		rects = new-rects
	}
	new-rects
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
/// - grid (dictionary): Representation of the grid layout, including:
///   - `flip`
#let compute-cell-sizes(grid, nodes) = {
	let rects = nodes.map(node => (center: node.pos, size: node.size))
	rects = expand-fractional-rects(rects)

	// all points in diagram that should be spanned by coordinate grid
	let points = rects.map(r => r.center)

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

	let bounding-size = array.zip(centers, grid.cell-sizes)
		.map(((centers, sizes)) => centers.at(-1) + sizes.at(-1)/2)

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
#let compute-grid(nodes, options) = {
	let grid = (
		axes: options.axes,
		spacing: options.spacing,
	)

	grid += interpret-axes(grid.axes)
	grid += compute-cell-sizes(grid, nodes)

	// enforce minimum cell size
	grid.cell-sizes = grid.cell-sizes.zip(options.cell-size)
		.map(((sizes, min-size)) => sizes.map(calc.max.with(min-size)))

	grid += compute-cell-centers(grid)

	grid
}


#let extract-nodes-and-edges-from-equation(eq) = {
	assert(eq.func() == math.equation)
	let terms = eq.body + []

	let edges = ()
	let nodes = ()

	// convert math matrix into array-of-arrays matrix
	let matrix = ((none,),)
	let (x, y) = (0, 0)
	for child in terms.children {
		if child.func() == metadata {
			if child.value.class == "edge" {
				let edge = child.value
				edge.vertices.at(0) = map-auto(edge.vertices.at(0), (x, y))
				if edge.label != none { edge.label = $edge.label$ } // why is this needed?
				edges.push(edge)

			} else if child.value.class == "node" {
				let node = child.value
				node.pos = (x, y)
				nodes.push(node)
			}
		} else if repr(child.func()) == "linebreak" {
			y += 1
			x = 0
			matrix.push((none,))
		} else if repr(child.func()) == "align-point" {
			x += 1
			matrix.at(-1).push(none)
		} else {
			matrix.at(-1).at(-1) += child
		}
	}

	// turn matrix into an array of nodes
	for (y, row) in matrix.enumerate() {
		for (x, item) in row.enumerate() {
			if not is-space(item) {
				nodes.push(node((x, y), $item$).value)
			}
		}
	}

	(
		nodes: nodes,
		edges: edges,
	)
}



#let interpret-diagram-args(args) = {
	if args.named().len() > 0 {
		let args = args.named().keys().join(", ")
		panic("Unexpected named argument(s) to `diagram()`: " + args)
	}

	let positional-args = args.pos().flatten().join() + [] // join to ensure sequence
	let objects = positional-args.children

	let nodes = ()
	let edges = ()

	let prev-coord = (0,0)
	let number-of-edges-needing-end-vertex = 0

	for obj in objects {
		if obj.func() == metadata {
			if obj.value.class == "node" {
				let node = obj.value


				// prev-coord = node.pos
				// for i in range(number-of-edges-needing-end-vertex) {
				// 	// previous edge(s) are waiting for their last vertex
				// 	edges.at(-1 - i).vertices.at(-1) = (node-index: nodes.len())
				// }
				// number-of-edges-needing-end-vertex = 0
				nodes.push(node)

			} else if obj.value.class == "edge" {
				let edge = obj.value

				// if edge.vertices.at(0) == auto {
				// 	edge.vertices.at(0) = (node-index: nodes.len())
				// }
				// if edge.vertices.at(-1) == auto {
				// 	// if edge's end point isn't set, defer it until the next node is seen.
				// 	number-of-edges-needing-end-vertex += 1
				// }
				edge.node-index = nodes.len()
				edges.push(edge)
			}

		} else if obj.func() == math.equation {
			let result = extract-nodes-and-edges-from-equation(obj)
			nodes += result.nodes
			edges += result.edges

		} else {
			panic("Unrecognised value passed to diagram:", obj)
		}
	}

	// edges = edges.map(edge => {
	// 	if edge.vertices.at(-1) == auto {
	// 		edge.vertices.at(-1) = (rel: (1,0))
	// 	}
	// 	assert(edge.vertices.all(v => v != auto))
	// 	edge
	// })

	// allow nodes which enclose other nodes to have pos: auto
	nodes = nodes.map(node => {
		if node.enclose.len() > 0 and node.pos == auto {
			let enclosed-centers = node.enclose
				.map(resolve-label-coordinate.with(nodes))
			node.pos = bounding-rect(enclosed-centers).center
		}
		node
	})

	// for node in nodes {
	// 	assert(type(node.pos) == array, message: "Invalid position `pos` in node: " + repr(node))
	// }

	(
		nodes: nodes,
		edges: edges,
	)

}



/// Draw a diagram containing `node()`s and `edge()`s.
///
/// - ..args (array): Content to draw in the diagram, including nodes and edges.
///
///   The results of `node()` and `edge()` can be _joined_, meaning you can
///   specify them as separate arguments, or in a block:
///
///   ```typ
///   #diagram(
///   	// one object per argument
///   	node((0, 0), $A$),
///   	node((1, 0), $B$),
///   	{
///   		// multiple objects in a block
///   		// can use scripting, loops, etc
///   		node((2, 0), $C$)
///   		node((3, 0), $D$)
///   	},
///   	for x in range(4) { node((x, 1) [#x]) },
///   )
///   ```
///
///   Nodes and edges can also be specified in math-mode.
///
///   ```typ
///   #diagram($
///   	A & B \          // two nodes at (0,0) and (1,0)
///   	C edge(->) & D \ // an edge from (0,1) to (1,1)
///   	node(sqrt(pi), stroke: #1pt) // a node with options
///   $)
///   ```
///
/// - debug (bool, 1, 2, 3): Level of detail for drawing debug information.
///   Level `1` or `true` shows a coordinate grid; higher levels show bounding boxes and
///   anchors, etc.
///
/// - spacing (length, pair of lengths): Gaps between rows and columns. Ensures
///   that nodes at adjacent grid points are at least this far apart (measured as
///   the space between their bounding boxes).
///
///   Separate horizontal/vertical gutters can be specified with `(x, y)`. A
///   single length `d` is short for `(d, d)`.
///
/// - cell-size (length, pair of lengths): Minimum size of all rows and columns.
///   A single length `d` is short for `(d, d)`.
///
/// - node-inset (length, pair of lengths): Default value of
///   #the-param[node][inset].
///
/// - node-outset (length, pair of lengths): Default value of
///   #the-param[node][outset].
///
/// - node-stroke (stroke, none): Default value of #the-param[node][stroke].
///
///   The default stroke is folded with the stroke specified for the node. For
///   example, if `node-stroke` is `1pt` and #the-param[node][stroke] is `red`,
///   then the resulting stroke is `1pt + red`.
///
/// - node-fill (paint): Default value of #the-param[node][fill].
///
/// - edge-stroke (stroke): Default value of #the-param[edge][stroke]. By
///   default, this is chosen to match the thickness of mathematical arrows such
///   as $A -> B$ in the current font size.
///
///   The default stroke is folded with the stroke specified for the edge. For
///   example, if `edge-stroke` is `1pt` and #the-param[edge][stroke] is `red`,
///   then the resulting stroke is `1pt + red`.
///
/// - node-corner-radius (length, none): Default value of
///   #the-param[node][corner-radius].
///
/// - edge-corner-radius (length, none): Default value of
///   #the-param[edge][corner-radius].
///
/// - node-defocus (number): Default value of #the-param[node][defocus].
///
/// - label-sep (length): Default value of #the-param[edge][label-sep].
///
/// - label-size (length): Default value of #the-param[edge][label-size].
///
/// - label-wrapper (function): Default value of
///   #the-param[edge][label-wrapper].
///
/// - mark-scale (percent): Default value of #the-param[edge][mark-scale].
///
/// - crossing-fill (paint): Color to use behind connectors or labels to give
///   the illusion of crossing over other objects. See
///   #the-param[edge][crossing-fill].
///
/// - crossing-thickness (number): Default thickness of the occlusion made by
///   crossing connectors. See #param[edge][crossing-thickness].
///
/// - axes (pair of directions): The orientation of the diagram's axes.
///
///   This defines the elastic coordinate system used by nodes and edges. To make
///   the $y$ coordinate increase up the page, use `(ltr, btt)`. For the matrix
///   convention `(row, column)`, use `(ttb, ltr)`.
///
///   #stack(
///   	dir: ltr,
///   	spacing: 1fr,
///   	fletcher.diagram(
///   		axes: (ltr, ttb),
///   		debug: 1,
///   		node((0,0), $(0,0)$),
///   		edge((0,0), (1,0), "->"),
///   		node((1,0), $(1,0)$),
///   		node((1,1), $(1,1)$),
///   		node((0.5,0.5), `axes: (ltr, ttb)`),
///   	),
///   	fletcher.diagram(
///   		axes: (ltr, btt),
///   		debug: 1,
///   		node((0,0), $(0,0)$),
///   		edge((0,0), (1,0), "->"),
///   		node((1,0), $(1,0)$),
///   		node((1,1), $(1,1)$),
///   		node((0.5,0.5), `axes: (ltr, btt)`),
///   	),
///   	fletcher.diagram(
///   		axes: (ttb, ltr),
///   		debug: 1,
///   		node((0,0), $(0,0)$),
///   		edge((0,0), (1,0), "->", bend: -20deg),
///   		node((1,0), $(1,0)$),
///   		node((1,1), $(1,1)$),
///   		node((0.5,0.5), `axes: (ttb, ltr)`),
///   	),
///   )
///
/// - render (function): After the node sizes and grid layout have been
///   determined, the `render` function is called with the following arguments:
///   - `grid`: a dictionary of the row and column widths and positions;
///   - `nodes`: an array of nodes (dictionaries) with computed attributes
///    (including size and physical coordinates);
///   - `edges`: an array of connectors (dictionaries) in the diagram; and
///   - `options`: other diagram attributes.
///
///   This callback is exposed so you can access the above data and draw things
///   directly with CeTZ.
#let diagram(
	..args,
	debug: false,
	axes: (ltr, ttb),
	spacing: 3em,
	cell-size: 0pt,
	edge-stroke: 0.048em,
	node-stroke: none,
	edge-corner-radius: 2.5pt,
	node-corner-radius: none,
	node-inset: 6pt,
	node-outset: 0pt,
	node-fill: none,
	node-defocus: 0.2,
	label-sep: 0.4em,
	label-size: 1em,
	label-wrapper: edge => box(
		[#edge.label],
		inset: .2em,
		radius: .2em,
		fill: edge.label-fill,
	),
	mark-scale: 100%,
	crossing-fill: white,
	crossing-thickness: 5,
	render: (grid, nodes, edges, options) => {
		cetz.canvas(draw-diagram(grid, nodes, edges, debug: options.debug))
	},
) = {

	let spacing = as-pair(spacing).map(as-length)
	let cell-size = as-pair(cell-size).map(as-length)

	let options = (
		debug: int(debug),
		axes: axes,
		spacing: spacing,
		cell-size: cell-size,
		node-inset: node-inset,
		node-outset: node-outset,
		node-stroke: node-stroke,
		node-fill: node-fill,
		node-corner-radius: node-corner-radius,
		edge-corner-radius: edge-corner-radius,
		node-defocus: node-defocus,
		label-sep: label-sep,
		label-size: label-size,
		label-wrapper: label-wrapper,
		edge-stroke: as-stroke(edge-stroke),
		mark-scale: mark-scale,
		crossing-fill: crossing-fill,
		crossing-thickness: crossing-thickness,
	)

	let (nodes, edges) = interpret-diagram-args(args)

	box(style(styles => {
		let options = options

		options.em-size = measure(h(1em)).width
		let to-pt(len) = to-abs-length(len, options.em-size)
		options.spacing = options.spacing.map(to-pt)
		options.cell-size = options.cell-size.map(to-pt)

		let nodes = nodes.map(node => resolve-node-options(node, options))
		// measure node sizes and determine diagram layout
		let nodes = compute-node-sizes(nodes, styles)

		let nodes-affecting-grid = resolve-node-coordinates(
			nodes, "pos", ctx: (target-system: "uv"),
		).filter(node => not is-nan-coord(node.pos))

		let grid = compute-grid(nodes-affecting-grid, options)

		// compute final/cetz coordinates for nodes and edges
		nodes = resolve-node-coordinates(
			nodes, "final-pos", ctx: (target-system: "xyz", grid: grid),
		)

		nodes = resolve-node-coordinates(
			nodes, "pos", ctx: (target-system: "uv", grid: grid)
		)

		nodes = compute-node-enclosures(nodes, grid)

		let edges = edges
			.map(edge => resolve-edge-options(edge, options))
			.map(edge => resolve-edge-vertices(edge, grid, nodes))

		edges = edges.map(edge => {
			if edge.kind == "corner" {
				edge = convert-edge-corner-to-poly(edge)
			}
			edge = apply-edge-shift(grid, edge)
			edge
		})

		render(grid, nodes, edges, options)
	}))
}
