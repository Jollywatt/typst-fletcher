#import "utils.typ": *
#import "coords.typ": uv-to-xy
#import "cetz-rework.typ": default-ctx, resolve
#import "shapes.typ"


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
///   Other shapes are defined in the `fletcher.shapes`
///   submodule, including
///   #{
///   	dictionary(fletcher.shapes).keys()
///   	.filter(x => type(x) != module)
///   	.map(i => [#raw(i)]).join(last: [, and ])[, ]
///   }.
///
///   Custom shapes should be specified as a function `(node, extrude, ..parameters) => (..)`
///   which returns `cetz` objects.
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
	snap: 0,
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

	assert(type(snap) in (int, float) or snap == false, message: "`snap` must be a number or `false`; got " + repr(snap))

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
		snap: snap,
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


/// Process the `enclose` options of an array of nodes.
#let compute-node-enclosures(nodes, grid) = {
	let nodes = nodes.map(node => {
		if node.enclose.len() == 0 { return node }

		let enclosed-vertices = node.enclose.map(key => {
			let near-node = find-node(nodes, key)
			if near-node == none or near-node == node {
				// if enclosed point doesn't resolve to a node
				// enclose the point itself
				(uv-to-xy(grid, key),)
			} else {
				// if enclosed point resolves to a node
				// enclose its bounding box
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
		node.shape = shapes.rect // TODO: support different node shapes with enclose

		node
	})

	nodes
}


/// Resolve node positions to a target coordinate system in sequence.
///
/// CeTZ-style coordinate expressions work, with the previous coordinate `()`
/// refering to the resolved position of the previous node.
///
/// - nodes (array): Array of nodes, each a dictionary containing a `pos` entry,
///   which should be a CeTZ-compatible coordinate expression.
/// - into (string): Key to inset into the node dictionary containing the value
///   of the resolved coordinate.
/// - ctx (dictionary): CeTZ-style context to be passed to `resolve(ctx, ..)`.
///   This must contain `target-system`, and optionally `grid`.
/// -> array
#let resolve-node-coordinates(nodes, into, ctx: (:)) = {
	let ctx = default-ctx + ctx
	let coord

	for i in range(nodes.len()) {
		let node = nodes.at(i)
		(ctx, coord) = resolve(ctx, node.pos)
		if node.name != none {
			ctx.nodes += (
				str(node.name): (anchors: _ => coord)
			)
		}
		nodes.at(i).insert(into, vector-2d(coord))
	}

	nodes
}
