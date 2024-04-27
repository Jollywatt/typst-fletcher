#import "utils.typ": *
#import "coords.typ": *
#import "layout.typ": *
#import "draw.typ": *
#import "edge.typ": *

/// Draw a labelled node in a diagram which can connect to edges.
///
/// - pos (coordinate): Dimensionless "elastic coordinates" `(x, y)` of the
///   node.
///
///   See the options of `diagram()` to control the physical scale of elastic
///   coordinates.
///
/// - name (label, none): An optional name to give the node.
///
///   Names can sometimes be used in place of coordinates. For example:
///
///   #example(```
///   fletcher.diagram(
///   	node((0,0), $A$, name: <A>),
///   	node((1,0.6), $B$, name: <B>),
///   	edge(<A>, <B>, "->"),
///   )
///   ```)
///
///   Note that you can also just use variables to refer to coordinates:
///
///   #example(```
///   fletcher.diagram({
///   	let A = (0,0)
///   	let B = (1,0.6)
///   	node(A, $A$)
///   	node(B, $B$)
///   	edge(A, B, "->")
///   })
///   ```)
///
/// - label (content): Content to display inside the node.
///
///   If a node is larger than its label, you can wrap the label in `align()` to
///   control the label alignment within the node.
///
///   #example(```typc
///   diagram(
///   	node((0,0), align(bottom + left)[¡Hola!],
///   		width: 3cm, height: 2cm, fill: yellow),
///   )
///   ```)
///
/// - inset (length, auto): Padding between the node's content and its outline.
///
///   In debug mode, the inset is visualised by a thin green outline.
///
///   #example(```
///   diagram(
///   	debug: 3,
///   	node-stroke: 1pt,
///   	node((0,0), [Hello,]),
///   	edge(),
///   	node((1,0), [World!], inset: 10pt),
///   )
///   ```)
///
/// - outset (length, auto): Margin between the node's bounds to the anchor
///   points for connecting edges.
///
///   This does not affect node layout, only how closely edges connect to the
///   node.
///
///   In debug mode, the outset is visualised by a thin green outline.
///
///   #example(```
///   diagram(
///   	debug: 3,
///   	node-stroke: 1pt,
///   	node((0,0), [Hello,]),
///   	edge(),
///   	node((1,0), [World!], outset: 10pt),
///   )
///   ```)
///
/// - width (length, auto): Width of the node. If `auto`, the node's width is
///   the width of the node #param[node][label], plus twice the
///   #param[node][inset].
///
///   If the width is not `auto`, you can use `align` to control the placement of the node's #param[node][label].
///
/// - height (length, auto): Height of the node. If `auto`, the node's height is the height of the node #param[node][label], plus twice the #param[node][inset].
///
///   If the height is not `auto`, you can use `align` to control the placement of the node's #param[node][label].
///
/// - enclose (array): Positions or names of other nodes to enclose by enlarging
///   this node.
///
///   If given, causes the node to resize so that its bounding rectangle
///   surrounds the given nodes. The center #param[node][pos] does not affect
///   the node's position if `enclose` is given, but still affects connecting
///   edges.
///
///   #box(example(```
///   diagram(
///   	node-stroke: 1pt,
///   	node((0,0), [ABC], name: <A>),
///   	node((1,1), [XYZ], name: <Z>),
///   	node(
///   		text(teal)[Node group], stroke: teal,
///   		enclose: (<A>, <Z>), name: <group>),
///   	edge(<group>, (3,0.5), stroke: teal),
///   )
///   ```))
///
/// - shape (rect, circle, function, auto): Shape to draw for the node. If
///   `auto`, one of `rect` or `circle` is chosen depending on the aspect ratio
///   of the node's label.
///
///   Some other shape functions are provided in the `fletcher.shapes`
///   submodule, including
///   #{
///   	dictionary(fletcher.shapes).keys()
///   	.filter(i => i not in ("cetz", "draw", "vector"))
///   	.map(i => [- #raw(i)]).join()
///   }
///
///   Custom shapes should be specified as a function `(node, extrude) => (..)`
///   returning `cetz` objects.
///   - The `node` argument is a dictionary containing the node's attributes,
///     including its dimensions (`node.size`), and other options (such as
///     `node.corner-radius`).
///   - The `extrude` argument is a length which the shape outline should be
///     extruded outwards by. This serves two functions: to support automatic
///     edge anchoring with a non-zero node `outset`, and to create multi-stroke
///     effects using the `extrude` node option.
///   See the ```plain src/shapes.typ``` source file for examples.
///
/// - stroke (stroke): Stroke style for the node outline.
///
///   Defaults to #the-param[diagram][node-stroke].
///
/// - fill (paint): Fill style of the node. The fill is drawn within the node
///   outline as defined by the first #param(full: false)[node][extrude] value.
///
///   Defaults to #the-param[diagram][node-fill].
///
/// - defocus (number): Strength of the "defocus" adjustment for connectors
///   incident with this node.
///
///   This affects how connectors attach to non-square nodes. If `0`, the
///   adjustment is disabled and connectors are always directed at the node's
///   exact center.
///
///   #stack(
///   	dir: ltr,
///   	spacing: 1fr,
///   	..(0.2, 0, -1).enumerate().map(((i, defocus)) => {
///   		fletcher.diagram(spacing: 8mm, {
///   			node((i, 0), raw("defocus: "+str(defocus)), stroke: black, defocus: defocus)
///   			for y in (-1, +1) {
///   				edge((i - 1, y), (i, 0))
///   				edge((i, y), (i, 0))
///   				edge((i + 1, y), (i, 0))
///   			}
///   		})
///   	})
///   )
///
///   Defaults to #the-param[diagram][node-defocus].
///
/// - extrude (array): Draw strokes around the node at the given offsets to
///   obtain a multi-stroke effect. Offsets may be numbers (specifying multiples
///   of the stroke's thickness) or lengths.
///
///   The node's fill is drawn within the boundary defined by the first offset in
///   the array.
///
///   #diagram(
///   	node-stroke: 1pt,
///   	node-fill: red.lighten(70%),
///   	node((0,0), `(0,)`),
///   	node((1,0), `(0, 2)`, extrude: (0, 2)),
///   	node((2,0), `(2, 0)`, extrude: (2, 0)),
///   	node((3,0), `(0, -2.5, 2mm)`, extrude: (0, -2.5, 2mm)),
///   )
///
///   See also #the-param[edge][extrude].
///
/// - corner-radius (length): Radius of rounded corners, if supported by the
///   node #param[node][shape].
///
///   Defaults to #the-param[diagram][node-corner-radius].
///
/// - layer (number, auto): Layer on which to draw the node.
///
///   Objects on a higher `layer` are drawn on top of objects on a lower
///   `layer`. Objects on the same layer are drawn in the order they are passed
///   to `diagram()`.
///
///   By default, nodes are drawn on layer `0` unless they #param[node][enclose]
///   points, in which case `layer` defaults to `-1`.
///
/// - post (function): Callback function to intercept `cetz` objects before they
///   are drawn to the canvas.
///
///   This can be used to hide elements without affecting layout (for use with
///   #link("https://github.com/touying-typ/touying")[Touying], for example).
///   The `hide()` function also helps for this purpose.
///
#let node(
	..args,
	pos: auto,
	name: none,
	label: none,
	inset: auto,
	outset: auto,
	fill: auto,
	stroke: auto,
	extrude: (0,),
	width: auto,
	height: auto,
	radius: auto,
	enclose: (),
	corner-radius: auto,
	shape: auto,
	defocus: auto,
	layer: auto,
	post: x => x,
) = {
	if args.named().len() > 0 { panic("Unexpected named argument(s):", args) }
	if args.pos().len() > 2 { panic("Unexpected positional argument(s):", args.pos().slice(2)) }

	// interpret first two positional arguments
	if args.pos().len() == 2 {
		(pos, label) = args.pos()
	} else if args.pos().len() == 1 {
		let arg = args.pos().at(0)
		if type(arg) == array {
			pos = arg
			label = none
		} else {
			pos = auto
			label = arg
		}
	}

	let extrude = as-array(extrude).map(as-number-or-length.with(
		message: "`extrude` must be a number, length, or an array of those"
	))

	metadata((
		class: "node",
		pos: pos,
		name: pass-none(as-label)(name),
		label: label,
		inset: inset,
		outset: outset,
		enclose: as-array(enclose),
		size: (width, height),
		radius: radius,
		shape: shape,
		stroke: stroke,
		fill: fill,
		corner-radius: corner-radius,
		defocus: defocus,
		extrude: extrude,
		layer: layer,
		post: post,
	))
}



#let resolve-node-options(node, options) = {
	let to-pt(len) = to-abs-length(as-length(len), options.em-size)

	node.stroke = map-auto(node.stroke, options.node-stroke)
	if node.stroke != none {
		let base-stroke = pass-none(stroke-to-dict)(options.node-stroke)
		node.stroke = base-stroke + stroke-to-dict(node.stroke)
	}
	node.stroke = pass-none(stroke)(node.stroke) // guarantee stroke or none

	node.fill = map-auto(node.fill, options.node-fill)
	node.corner-radius = map-auto(node.corner-radius, options.node-corner-radius)
	node.inset = to-pt(map-auto(node.inset, options.node-inset))
	node.outset = to-pt(map-auto(node.outset, options.node-outset))
	node.defocus = map-auto(node.defocus, options.node-defocus)

	node.size = node.size.map(pass-auto(to-pt))
	node.radius = pass-auto(to-pt)(node.radius)

	if node.shape == auto {
		if node.radius != auto { node.shape = "circle" }
		if node.size != (auto, auto) { node.shape = "rect" }
	}

	let thickness = if node.stroke == none { 1pt } else {
		map-auto(node.stroke.thickness, 1pt)
	}

	node.extrude = node.extrude.map(d => {
		if type(d) == length { d }
		else { d*thickness }
	}).map(to-pt)

	if type(node.outset) in (int, float) {
		node.outset *= thickness
	}

	let default-layer = if node.enclose.len() > 0 { -1 } else { 0 }
	node.layer = map-auto(node.layer, default-layer)

	node
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
	let should-set-prev-edge-end-point = false

	for obj in objects {
		if obj.func() == metadata {
			if obj.value.class == "node" {
				let node = obj.value

				nodes.push(node)

				prev-coord = node.pos
				if should-set-prev-edge-end-point {
					// the `to` point of the previous edge is waiting to be set
					edges.at(-1).vertices.at(-1) = node.pos
					should-set-prev-edge-end-point = false
				}

			} else if obj.value.class == "edge" {
				let edge = obj.value

				if edge.vertices.at(0) == auto {
					edge.vertices.at(0) = prev-coord
				}
				if edge.vertices.at(-1) == auto {
					// if edge's end point isn't set, defer it until the next node is seen.
					// currently, this is only allowed for one edge at a time.
					if should-set-prev-edge-end-point { panic("Cannot infer edge end point. Please specify explicitly.") }
					should-set-prev-edge-end-point = true
				}
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

	edges = edges.map(edge => {
		if edge.vertices.at(-1) == auto {
			edge.vertices.at(-1) = vector.add(edge.vertices.at(-2), (1,0))
		}
		edge
	})

	// allow nodes which enclose other nodes to have pos: auto
	nodes = nodes.map(node => {
		if node.enclose.len() > 0 and node.pos == auto {
			let enclosed-centers = node.enclose
				.map(resolve-label-coordinate.with(nodes))
			node.pos = bounding-rect(enclosed-centers).center
		}
		node
	})

	for node in nodes {
		assert(type(node.pos) == array, message: "Invalid position `pos` in node: " + repr(node))
	}

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
/// - mark-scale (percent): Default value of #the-param[edge][mark-scale].
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
	label-sep: 0.2em,
	mark-scale: 100%,
	crossing-fill: white,
	crossing-thickness: 5,
	render: (grid, nodes, edges, options) => {
		cetz.canvas(draw-diagram(grid, nodes, edges, debug: options.debug))
	},
) = {

	let spacing = as-pair(spacing)
	let cell-size = as-pair(cell-size)
	// if type(spacing) != array { spacing = (spacing, spacing) }
	// if type(cell-size) != array { cell-size = (cell-size, cell-size) }

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

		// resolve options and fancy coordinates in nodes and edges

		let nodes = nodes.map(node => resolve-node-options(node, options))
		let edges = edges.map(edge => resolve-edge-options(edge, options))

		nodes = nodes.map(node => {
			node.pos = resolve-label-coordinate(nodes, node.pos)
			node
		})
		edges = edges.map(edge => {

			let first-last-labels = (0, -1).map(i => {
				if type(edge.vertices.at(i)) == label { edge.vertices.at(i) }
				else { auto }
			})

			let verts = edge.vertices.map(resolve-label-coordinate.with(nodes))
			edge.vertices = resolve-relative-coordinates(verts)

			let first-last-verts = (0, -1).map(i => edge.vertices.at(i))

			// the first/last snap-to value should be:
			// - whatever the user sets, or if auto:
			// - the first/last vertex name, or if it is not a name:
			// - the first/last vertex coordinate
			edge.snap-to = edge.snap-to
				.zip(first-last-labels, first-last-verts)
				.map(((option, label, vert)) => {
					map-auto(map-auto(option, label), vert)
				})

			edge
		})

		// measure node sizes and determine diagram layout

		for edge in edges {
			if not edge.vertices.all(i => type(i) == array) {
				panic("Could not determine edge vertices, found " + repr(edge.vertices) + ".")
			}
		}
		let nodes = compute-node-sizes(nodes, styles)
		let grid = compute-grid(nodes, edges, options)

		// compute final/cetz coordinates for nodes and edges

		nodes = nodes.map(node => {
			node.final-pos = uv-to-xy(grid, node.pos)
			node
		})

		nodes = compute-node-enclosures(nodes, grid)

		edges = edges.map(edge => {
			edge.final-vertices = edge.vertices.map(uv-to-xy.with(grid))
			if edge.kind == "corner" {
				edge = convert-edge-corner-to-poly(edge)
			}
			edge = apply-edge-shift(grid, edge)
			edge
		})

		render(grid, nodes, edges, options)
	}))
}
