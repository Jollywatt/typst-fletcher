#import calc: floor, ceil, min, max
#import "utils.typ": *
#import "layout.typ": *
#import "draw.typ": *
#import "marks.typ": *

/// Draw a labelled node in an arrow diagram.
///
/// - pos (point): Dimensionless "elastic coordinates" `(x, y)` of the node,
///  where `x` is the column and `y` is the row (increasing upwards). The
///  coordinates are usually integers, but can be fractional.
///
///  See the `diagram()` options to control the physical scale of elastic
///  coordinates.
///
/// - label (content): Node content to display.
/// - inset (length, auto): Padding between the node's content and its bounding
///  box or bounding circle. If `auto`, defaults to the `node-inset` option of
///  `diagram()`.
/// - outset (length, auto): Margin between the node's bounds to the anchor
///  points for connecting edges.
/// - shape (string, auto): Shape of the node, one of `"rect"` or `"circle"`. If
/// `auto`, shape is automatically chosen depending on the aspect ratio of the
/// node's label.
/// - stroke (stroke): Stroke of the node. Defaults to the `node-stroke` option
///  of `diagram()`.
/// - fill (paint): Fill of the node. Defaults to the `node-fill` option of
///  `diagram()`.
/// - defocus (number): Strength of the "defocus" adjustment for connectors
///  incident with this node. If `auto`, defaults to the `node-defocus` option
///  of `diagram()` .
/// - extrude (array): Draw strokes around the node at the given offsets to
///  obtain a multi-stroke effect. Offsets may be numbers (specifying multiples
///  of the stroke's thickness) or lengths.
///
///  The node's fill is drawn within the boundary defined by the first offset in
///  the array.
///
///  #fletcher.diagram(
///  	node-stroke: 1pt,
///		node-fill: red.lighten(70%),
///  	node((0,0), `(0,)`),
///  	node((1,0), `(0, 2)`, extrude: (0, 2)),
///  	node((2,0), `(2, 0)`, extrude: (2, 0)),
///  	node((3,0), `(0, -2.5, 2mm)`, extrude: (0, -2.5, 2mm)),
///  )
///
///  See also the `extrude` option of `edge()`.
#let node(
	pos,
	label,
	inset: auto,
	outset: auto,
	shape: auto,
	stroke: auto,
	fill: auto,
	defocus: auto,
	extrude: (0,),
) = {
	assert(type(pos) == array and pos.len() == 2)

	if type(label) == content and label.func() == circle { panic(label) }
	((
		class: "node",
		pos: pos,
		label: label,
		inset: inset,
		outset: outset,
		shape: shape,
		stroke: stroke,
		fill: fill,
		defocus: defocus,
		extrude: extrude,
	),)
}



#let interpret-edge-args(args) = {
	let named-args = (:)

	if args.named().len() > 0 {
		panic("Unexpected named argument(s):", args)
	}

	let pos = args.pos()

	// interpret first non-string argument as the label
	if pos.len() >= 1 and type(pos.at(0)) != str {
		named-args.label = pos.remove(0)
	}

	// interpret a string that's not an argument shorthand as
	// a marks/arrowhead shorthand
	if (pos.len() >= 1 and type(pos.at(0)) == str and
		pos.at(0) not in EDGE_ARGUMENT_SHORTHANDS) {
		named-args.marks = pos.remove(0)
	}

	for arg in pos {
		if type(arg) == str and arg in EDGE_ARGUMENT_SHORTHANDS {
			named-args += EDGE_ARGUMENT_SHORTHANDS.at(arg)
		} else {
			panic(
				"Unrecognised argument " + repr(arg) + ". Must be one of:",
				EDGE_ARGUMENT_SHORTHANDS.keys(),
			)
		}
	}

	named-args

}

/// Draw a connecting line or arc in an arrow diagram.
///
/// - from (elastic coord): Start coordinate `(x, y)` of connector. If there is
///  a node at that point, the connector is adjusted to begin at the node's
///  bounding rectangle/circle.
/// - to (elastic coord): End coordinate `(x, y)` of connector. If there is a 
///  node at that point, the connector is adjusted to end at the node's bounding
///  rectangle/circle.
///
/// - ..args (any): The connector's `label` and `marks` named arguments can also
///  be specified as positional arguments. For example, the following are equivalent:
///  ```typc
///  edge((0,0), (1,0), $f$, "->")
///  edge((0,0), (1,0), $f$, marks: "->")
///  edge((0,0), (1,0), "->", label: $f$)
///  edge((0,0), (1,0), label: $f$, marks: "->")
///  ```
/// 
/// - label-pos (number): Position of the label along the connector, from the
///  start to end (from `0` to `1`).
/// 
///  #stack(
///  	dir: ltr,
///  	spacing: 1fr,
///  	..(0, 0.25, 0.5, 0.75, 1).map(p => fletcher.diagram(
///  		cell-size: 1cm,
///  		edge((0,0), (1,0), p, "->", label-pos: p))
///  	),
///  )
/// - label-sep (number): Separation between the connector and the label anchor.
///  
///  With the default anchor (`"bottom"`):
///
///  #fletcher.diagram(
///  	debug: 2,
///  	cell-size: 8mm,
///  	{
///  		for (i, s) in (-5pt, 0pt, .4em, .8em).enumerate() {
///  			edge((2*i,0), (2*i + 1,0), s, "->", label-sep: s)
///  		}
///  })
///  
///  With `label-anchor: "center"`:
///  
///  #fletcher.diagram(
///  	debug: 2,
///  	cell-size: 8mm,
///  	{
///  		for (i, s) in (-5pt, 0pt, .4em, .8em).enumerate() {
///  			edge((2*i,0), (2*i + 1,0), s, "->", label-sep: s, label-anchor: "center")
///  		}
///  })
/// 
/// - label (content): Content for connector label. See `label-side` to control
///  the position (and `label-sep`, `label-pos` and `label-anchor` for finer
///  control).
///
/// - label-side (left, right, center): Which side of the connector to place the
///  label on, viewed as you walk along it. If `center`, then the label is place
///  over the connector. When `auto`, a value of `left` or `right` is chosen to
///  automatically so that the label is
///    - roughly above the connector, in the case of straight lines; or
///    - on the outside of the curve, in the case of arcs.
///
/// - label-anchor (anchor): The anchor point to place the label at, such as
///  `"top-right"`, `"center"`, `"bottom"`, etc. If `auto`, the anchor is
///  automatically chosen based on `label-side` and the angle of the connector.
///
/// - paint (paint): Paint (color or gradient) of the connector stroke.
/// - thickness (length): Thickness the connector stroke. Marks (arrow heads)
///  scale with this thickness.
/// - dash (dash type): Dash style for the connector stroke.
/// - bend (angle): Curvature of the connector. If `0deg`, the connector is a
///  straight line; positive angles bend clockwise.
/// 
///  #fletcher.diagram(debug: 0, {
///  	node((0,0), $A$)
///  	node((1,1), $B$)
///  	let N = 4
///  	range(N + 1)
///  		.map(x => (x/N - 0.5)*2*100deg)
///  		.map(θ => edge((0,0), (1,1), θ, bend: θ, ">->", label-side: center))
///  		.join()
///  })
///
/// - marks (pair of strings):
/// The start and end marks or arrow heads of the connector. A shorthand such as
/// `"->"` can used instead. For example,
/// `edge(p1, p2, "->")` is short for `edge(p1, p2, marks: (none, "head"))`.
///
/// #table(
/// 	columns: 3,
/// 	align: horizon,
///  	[Arrow], [Shorthand], [Arguments],
/// 	..(
///  		"-",
///  		"--",
///  		"..",
///  		"->",
///  		"<=>",
///  		">>-->",
///  		"|..|",
///  		"hook->>",
///  		"hook'->>",
///  		">-harpoon",
///  		">-harpoon'",
/// 	).map(str => (
///  		fletcher.diagram(edge((0,0), (1,0), str)),
///  		raw(str, lang: none),
///  		raw(repr(parse-arrow-shorthand(str))),
///  	)).join()
/// )
///
/// - mark-scale (percent):
/// Scale factor for connector marks or arrow heads. This defaults to `100%` for
/// single lines, `120%` for double lines and `150%` for triple lines. Does not
/// affect the stroke thickness of the mark.
///
/// #{
/// 	set raw(lang: none)
/// 	fletcher.diagram(
/// 		edge-thickness: 1pt,
/// 		edge((0,0), (1,0), `->`, "->"),
/// 		edge((2,0), (3,0), `=>`, "=>"),
/// 		edge((4,0), (5,0), `==>`, "==>"),
/// 	)
/// }
///
/// - extrude (array): Draw a separate stroke for each extrusion offset to
///  obtain a multi-stroke effect. Offsets may be numbers (specifying multiples
///  of the stroke's thickness) or lengths.
///
///  #fletcher.diagram({
///  	(
///  		(0,),
///  		(-1.5,+1.5),
///  		(-2,0,+2),
///  		(-4.5,),
///  		(4.5,),
///  	).enumerate().map(((i, e)) => {
///  		edge(
///  			(2*i, 0), (2*i + 1, 0), [#e], "|->",
///  			extrude: e, thickness: 1pt, label-sep: 1em)
///  	}).join()
///  })
///  
///  Notice how the ends of the line need to shift a little depending on the
///  mark. For basic arrow heads, this offset is computed with
///  `round-arrow-cap-offset()`.
///
/// - crossing (bool): If `true`, draws a white backdrop to give the illusion of
///  lines crossing each other.
///
///  #fletcher.diagram({
///  	edge((0,1), (1,0), thickness: 1pt)
///  	edge((0,0), (1,1), thickness: 1pt)
///  	edge((2,1), (3,0), thickness: 1pt)
///  	edge((2,0), (3,1), thickness: 1pt, crossing: true)
///  })
/// 
/// - crossing-thickness (number): Thickness of the white "crossing" background
///  stroke, if `crossing: true`, in multiples of the normal stroke's thickness.
///  Defaults to the `crossing-thickness` option of `diagram()`.
/// 
///  #fletcher.diagram({
///  	(1, 2, 5, 8, 12).enumerate().map(((i, x)) => {
///  		edge((2*i, 1), (2*i + 1, 0), thickness: 1pt, label-sep: 1em)
///  		edge((2*i, 0), (2*i + 1, 1), raw(str(x)), thickness: 1pt, label-sep:
///  		1em, crossing: true, crossing-thickness: x)
///  	}).join()
///  })
/// 
/// - crossing-fill (paint): Color to use behind connectors or labels to give the illusion of crossing over other objects. Defaults to the `crossing-fill` option of
///  `diagram()`.
///
///  #let cross(x, fill) = {
///  	edge((2*x + 0,1), (2*x + 1,0), thickness: 1pt)
///  	edge((2*x + 0,0), (2*x + 1,1), $f$, thickness: 1pt, crossing: true, crossing-fill: fill)
///  }
///  #fletcher.diagram(crossing-thickness: 5, {
///  	cross(0, white)
///  	cross(1, blue.lighten(50%))
///  	cross(2, luma(98%))
///  })
///
#let edge(
	from,
	to,
	..args,
	label: none,
	label-side: auto,
	label-pos: 0.5,
	label-sep: auto,
	label-anchor: auto,
	paint: black,
	thickness: auto,
	dash: none,
	kind: auto,
	bend: 0deg,
	corner: none,
	marks: (none, none),
	mark-scale: 100%,
	extrude: (0,),
	crossing: false,
	crossing-thickness: auto,
	crossing-fill: auto,
) = {

	let options = (
		label: label,
		label-pos: label-pos,
		label-sep: label-sep,
		label-anchor: label-anchor,
		label-side: label-side,
		paint: paint,
		thickness: thickness,
		dash: dash,
		kind: kind,
		bend: bend,
		corner: corner,
		marks: marks,
		mark-scale: mark-scale,
		extrude: extrude,
		crossing: crossing,
		crossing-thickness: crossing-thickness,
		crossing-fill: crossing-fill,
	)
	options += interpret-edge-args(args)

	if type(options.marks) == str {
		options += parse-arrow-shorthand(options.marks)
	}

	options.marks = options.marks.map(interpret-mark)


	let stroke = (
		paint: options.paint,
		cap: "round",
		thickness: options.thickness,
		dash: options.dash,
	)

	if options.label-side == center {
		options.label-anchor = "center"
		options.label-sep = 0pt
	}

	let obj = ( 
		class: "edge",
		points: (from, to),
		label: options.label,
		label-pos: options.label-pos,
		label-sep: options.label-sep,
		label-anchor: options.label-anchor,
		label-side: options.label-side,
		paint: options.paint,
		kind: options.kind,
		bend: options.bend,
		corner: options.corner,
		stroke: stroke,
		marks: options.marks,
		mark-scale: options.mark-scale,
		extrude: options.extrude,
		is-crossing-background: false,
		crossing-thickness: crossing-thickness,
		crossing-fill: crossing-fill,
	)

	// add empty nodes at terminal points
	node(from, none)
	node(to, none)

	if options.crossing {
		((
			..obj,
			is-crossing-background: true
		),)
	}

	(obj,)
}


#let apply-defaults(nodes, edges, options) = {
	let to-pt(len) = len.abs + len.em*options.em-size

	(
		nodes: nodes.map(node => {
			if node.stroke == auto {node.stroke = options.node-stroke }
			if node.fill == auto { node.fill = options.node-fill }
			if node.inset == auto { node.inset = options.node-inset }
			if node.outset == auto { node.outset = options.node-outset }
			if node.defocus == auto { node.defocus = options.node-defocus }

			let real-stroke-thickness = if type(node.stroke) == stroke {
				node.stroke.thickness
			} else if type(node.stroke) == length {
				node.stroke
			} else { 1pt }

			node.extrude = node.extrude.map(d => {
				if type(d) == length { to-pt(d) }
				else { d*real-stroke-thickness }
			})

			node.inset = to-pt(node.inset)
			node.outset = to-pt(node.outset)

			node
		}),

		edges: edges.map(edge => {
			if edge.stroke.thickness == auto { edge.stroke.thickness = options.edge-thickness }
			if edge.crossing-fill == auto { edge.crossing-fill = options.crossing-fill }
			if edge.crossing-thickness == auto { edge.crossing-thickness = options.crossing-thickness }
			if edge.label-sep == auto { edge.label-sep = options.label-sep }

			if edge.is-crossing-background {
				edge.stroke = (
					thickness: edge.crossing-thickness*edge.stroke.thickness,
					paint: edge.crossing-fill,
					cap: "round",
				)
				edge.marks = (none, none)
				edge.extrude = edge.extrude.map(e => e/edge.crossing-thickness)
			}

			if edge.kind == auto {
				if edge.corner != none { edge.kind = "corner" }
				else if edge.bend != 0deg { edge.kind = "arc" }
				else { edge.kind = "line" }
			}


			edge.mark-scale *= options.mark-scale

			edge.marks = edge.marks.map(mark => {
				if mark != none {
					mark.size *= edge.mark-scale/100%
				}
				mark
			})

			edge.stroke.thickness = to-pt(edge.stroke.thickness)
			edge.label-sep = to-pt(edge.label-sep)

			edge.extrude = edge.extrude.map(d => {
				if type(d) == length { to-pt(d) }
				else { d*edge.stroke.thickness }
			})

			for d in edge.extrude {
				if type(d) != length { panic(edge) }
			}

			edge
		}),
	)
}


/// Draw an arrow diagram.
///
/// - ..objects (array): An array of dictionaries specifying the diagram's
///   nodes and connections.
/// 
///  The results of `node()` and `edge()` can be joined, meaning you can specify
///  them as separate arguments, or in a block:
///
///  ```typ
///  #fletcher.diagram(
///    // one object per argument
///    node((0, 0), $A$),
///    node((1, 0), $B$),
///    {
///      // multiple objects in a block
///      // can use scripting, loops, etc
///      node((2, 0), $C$)
///      node((3, 0), $D$)
///    },
///  )
///  ```
///
/// - debug (bool, 1, 2, 3): Level of detail for drawing debug information.
///  Level `1` shows a coordinate grid; higher levels show bounding boxes and
///  anchors, etc.
///
/// - spacing (length, pair of lengths): Gaps between rows and columns. Ensures
///  that nodes at adjacent grid points are at least this far apart (measured as
///  the space between their bounding boxes).
///
///  Separate horizontal/vertical gutters can be specified with `(x, y)`. A
/// single length `d` is short for `(d, d)`.
///
/// - cell-size (length, pair of lengths): Minimum size of all rows and columns.
///
/// - node-inset (length, pair of lengths): Default padding between a node's
///  content and its bounding box.
/// - node-outset (length, pair of lengths): Default padding between a node's
///  boundary and where edges terminate.
/// - node-stroke (stroke): Default stroke for all nodes in diagram. Overridden
///  by individual node options.
/// - node-fill (paint): Default fill for all nodes in diagram. Overridden by
///  individual node options.
///
/// - node-defocus (number): Default strength of the "defocus" adjustment for
///  nodes. This affects how connectors attach to non-square nodes. If
///   `0`, the adjustment is disabled and connectors are always directed at the
///   node's exact center.
///
///   #stack(
///  	dir: ltr,
///  	spacing: 1fr,
///  	..(0.2, 0, -1).enumerate().map(((i, defocus)) => {
///  		fletcher.diagram(spacing: 8mm, {
///   			node((i, 0), raw("defocus: "+str(defocus)), stroke: black, defocus: defocus)
///  			for y in (-1, +1) {
///   				edge((i - 1, y), (i, 0))
///   				edge((i, y), (i, 0))
///   				edge((i + 1, y), (i, 0))
///   			}
///   		})
///   	})
///   )
///
/// - crossing-fill (paint): Color to use behind connectors or labels to give
///  the illusion of crossing over other objects. See the `crossing-fill` option
///  of `edge()`.
///
/// - crossing-thickness (number): Default thickness of the occlusion made by
///  crossing connectors. See the `crossing-thickness` option of `edge()`.
/// 
///
/// - render (function): After the node sizes and grid layout have been
///  determined, the `render` function is called with the following arguments:
///   - `grid`: a dictionary of the row and column widths and positions;
///   - `nodes`: an array of nodes (dictionaries) with computed attributes
///    (including size and physical coordinates);
///   - `edges`: an array of connectors (dictionaries) in the diagram; and
///   - `options`: other diagram attributes.
///
///  This callback is exposed so you can access the above data and draw things
///  directly with CeTZ.
#let diagram(
	..objects,
	debug: false,
	spacing: 3em,
	cell-size: 0pt,
	node-inset: 12pt,
	node-outset: 0pt,
	node-stroke: none,
	node-fill: none,
	node-defocus: 0.2,
	label-sep: 0.2em,
	edge-thickness: 0.048em,
	mark-scale: 100%,
	crossing-fill: white,
	crossing-thickness: 5,
	render: (grid, nodes, edges, options) => {
		cetz.canvas(draw-diagram(grid, nodes, edges, options))
	},
) = {

	if type(spacing) != array { spacing = (spacing, spacing) }
	if type(cell-size) != array { cell-size = (cell-size, cell-size) }

	if objects.named().len() > 0 { 
		let args = objects.named().keys().join(", ")
		panic("Unexpected named argument(s): " + args)
	}

	let options = (
		spacing: spacing,
		debug: int(debug),
		node-inset: node-inset,
		node-outset: node-outset,
		node-stroke: node-stroke,
		node-fill: node-fill,
		node-defocus: node-defocus,
		label-sep: label-sep,
		cell-size: cell-size,
		edge-thickness: edge-thickness,
		mark-scale: mark-scale,
		crossing-fill: crossing-fill,
		crossing-thickness: crossing-thickness,
	)

	let positional-args = objects.pos().join()
	let nodes = positional-args.filter(e => e.class == "node")
	let edges = positional-args.filter(e => e.class == "edge")

	box(style(styles => {

		let options = options
		options.em-size = measure(box(width: 1em), styles).width
		let to-pt(len) = len.abs + len.em*options.em-size
		options.spacing = options.spacing.map(to-pt)
		options.node-inset = to-pt(options.node-inset)
		options.label-sep = to-pt(options.label-sep)

		let (nodes, edges) = apply-defaults(nodes, edges, options)

		let nodes = compute-node-sizes(nodes, styles)
		let grid  = compute-grid(nodes, options)
		let nodes = compute-node-positions(nodes, grid, options)

		render(grid, nodes, edges, options)
	}))
}

