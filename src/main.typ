#import calc: floor, ceil, min, max
#import "utils.typ": *
#import "layout.typ": *
#import "draw.typ": *

/// Draw a labelled node in an arrow diagram.
///
/// - pos (point): Dimensionless "elastic coordinates" `(x, y)` of the node,
///  where `x` is the column and `y` is the row (increasing upwards). The
///  coordinates are usually integers, but can be fractional.
///
///  See the `arrow-diagram()` options to control the physical scale of elastic
///  coordinates.
///
/// - label (content): Node content to display.
/// - pad (length, none): Padding between the node's content and its bounding
///  box or bounding circle. If `auto`, defaults to the `node-pad` option of
///  `arrow-diagram()`.
/// - shape (string, auto): Shape of the node, one of `"rect"` or `"circle"`. If
/// `auto`, shape is automatically chosen depending on the aspect ratio of the
/// node's label.
/// - stroke (stroke): Stroke of the node. Defaults to the `node-stroke` option
///  of `arrow-diagram()`.
/// - fill (paint): Fill of the node. Defaults to the `node-fill` option of
///  `arrow-diagram()`.
/// - defocus (number): Strength of the "defocus" adjustment for connectors
///  incident with this node. If `auto`, defaults to the `node-defocus` option
///  of `arrow-diagram()` .
#let node(
	pos,
	label,
	pad: auto,
	outset: auto,
	shape: auto,
	stroke: auto,
	fill: auto,
	defocus: auto,
) = {
	assert(type(pos) == array and pos.len() == 2)

	if type(label) == content and label.func() == circle { panic(label) }
	((
		kind: "node",
		pos: pos,
		label: label,
		pad: pad,
		outset: outset,
		shape: shape,
		stroke: stroke,
		fill: fill,
		defocus: defocus,
	),)
}


#let CONN_ARGUMENT_SHORTHANDS = (
	"dashed": (dash: "dashed"),
	"dotted": (dash: "dotted"),
	"double": (double: true),
	"crossing": (crossing: true),
)

#let interpret-conn-args(args) = {
	let named-args = (:)

	if args.named().len() > 0 {
		panic("Unexpected named argument(s):", ..args.named().keys())
	}

	let pos = args.pos()

	if pos.len() >= 1 and type(pos.at(0)) != str {
		named-args.label = pos.remove(0)
	}

	if (pos.len() >= 1 and type(pos.at(0)) == str and
		pos.at(0) not in CONN_ARGUMENT_SHORTHANDS) {
		named-args.marks = pos.remove(0)
	}

	for arg in pos {
		if type(arg) == str and arg in CONN_ARGUMENT_SHORTHANDS {
			named-args += CONN_ARGUMENT_SHORTHANDS.at(arg)
		} else {
			panic(
				"Unrecognised argument " + repr(arg) + ". Must be one of:",
				CONN_ARGUMENT_SHORTHANDS.keys(),
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
///  conn((0,0), (1,0), $f$, "->")
///  conn((0,0), (1,0), $f$, marks: "->")
///  conn((0,0), (1,0), "->", label: $f$)
///  conn((0,0), (1,0), label: $f$, marks: "->")
///  ```
/// 
/// - label-pos (number): Position of the label along the connector, from the
///  start to end (from `0` to `1`).
/// 
///  #stack(
///  	dir: ltr,
///  	spacing: 1fr,
///  	..(0, 0.25, 0.5, 0.75, 1).map(p => arrow-diagram(
///  		cell-size: 1cm,
///  		conn((0,0), (1,0), p, "->", label-pos: p))
///  	),
///  )
/// - label-sep (number): Separation between the connector and the label anchor.
///  
///  With the default anchor (`"bottom"`):
///  #arrow-diagram(
///  	debug: 2,
///  	cell-size: 8mm,
///  	{
///  		for (i, s) in (-5pt, 0pt, .4em, .8em).enumerate() {
///  			conn((2*i,0), (2*i + 1,0), s, "->", label-sep: s)
///  		}
///  })
///  
///  With `label-anchor: "center"`:
///  #arrow-diagram(
///  	debug: 2,
///  	cell-size: 8mm,
///  	{
///  		for (i, s) in (-5pt, 0pt, .4em, .8em).enumerate() {
///  			conn((2*i,0), (2*i + 1,0), s, "->", label-sep: s, label-anchor: "center")
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
///  #arrow-diagram(debug: 0, {
///  	node((0,0), $A$)
///  	node((1,1), $B$)
///  	let N = 4
///  	range(N + 1)
///  		.map(x => (x/N - 0.5)*2*100deg)
///  		.map(θ => conn((0,0), (1,1), θ, bend: θ, ">->", label-side: center))
///  		.join()
///  })
///
/// - marks (pair of strings):
/// The start and end marks or arrow heads of the connector. A shorthand such as
/// `"->"` can used instead. For example,
/// `conn(p1, p2, "->")` is short for `conn(p1, p2, marks: (none, "head"))`.
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
///  		arrow-diagram(conn((0,0), (1,0), str)),
///  		raw(str, lang: none),
///  		raw(repr(parse-arrow-shorthand(str))),
///  	)).join()
/// )
///
/// - double (bool): Shortcut for `extrude: (-1.5, 1.5)`, showing a double stroke.
/// - extrude (array of numbers): Draw copies of the stroke extruded by the
///  given multiple of the stroke thickness. Used to obtain doubling effect.
///  Best explained by example:
///
///  #arrow-diagram({
///  	(
///  		(0,),
///  		(-1.5,+1.5),
///  		(-2,0,+2),
///  		(-4.5,),
///  		(4.5,),
///  	).enumerate().map(((i, e)) => {
///  		conn(
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
///  #arrow-diagram({
///  	conn((0,1), (1,0), thickness: 1pt)
///  	conn((0,0), (1,1), thickness: 1pt)
///  	conn((2,1), (3,0), thickness: 1pt)
///  	conn((2,0), (3,1), thickness: 1pt, crossing: true)
///  })
/// - crossing-thickness (number): Thickness of the white "crossing" background
///  stroke, if `crossing: true`, in multiples of the normal stroke's thickness.
/// 
///  #arrow-diagram({
///  	(1, 2, 5, 8, 12).enumerate().map(((i, x)) => {
///  		conn((2*i, 1), (2*i + 1, 0), thickness: 1pt, label-sep: 1em)
///  		conn((2*i, 0), (2*i + 1, 1), raw(str(x)), thickness: 1pt, label-sep:
///  		1em, crossing: true, crossing-thickness: x)
///  	}).join()
///  })
///
#let conn(
	from,
	to,
	..args,
	label: none,
	label-side: auto,
	label-pos: 0.5,
	label-sep: 0.4em,
	label-anchor: auto,
	paint: black,
	thickness: 0.6pt,
	dash: none,
	bend: none,
	marks: (none, none),
	double: false,
	extrude: auto,
	crossing: false,
	crossing-thickness: 5,
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
		bend: bend,
		marks: marks,
		double: double,
		extrude: extrude,
		crossing: crossing,
		crossing-thickness: crossing-thickness,
	)
	options += interpret-conn-args(args)

	let mode = if bend in (none, 0deg) { "line" } else { "arc" }

	if type(options.marks) == str {
		options += parse-arrow-shorthand(options.marks)
	}


	if options.extrude == auto {
		options.extrude = if options.double { (-1.5, +1.5) } else { (0,) }
	}

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
		kind: "conn",
		points: (from, to),
		label: options.label,
		label-pos: options.label-pos,
		label-sep: options.label-sep,
		label-anchor: options.label-anchor,
		label-side: options.label-side,
		paint: options.paint,
		mode: mode,
		bend: options.bend,
		stroke: stroke,
		marks: options.marks,
		extrude: options.extrude,
	)

	// add empty nodes at terminal points
	node(from, none)
	node(to, none)

	if options.crossing {
		// duplicate connector with white stroke and place underneath
		let understroke = (
			..obj.stroke,
			paint: white,
			thickness: crossing-thickness*obj.stroke.thickness,
		)

		((
			..obj,
			stroke: understroke,
			marks: (none, none),
			extrude: obj.extrude.map(i => i/crossing-thickness)
		),)
	}

	(obj,)
}


#let execute-callbacks(grid, nodes, callbacks, options) = {
	for callback in callbacks {
		let resolved-coords = callback.coords
			.map(elastic-to-physical-coords.with(grid))
		let result = (callback.callback)(..resolved-coords)
		if type(result) != array {
			panic("Callback should return an array of CeTZ element dictionaries; got " + type(result), result)
		}
		result
	}
}


/// Draw an arrow diagram.
///
/// - ..objects (array): An array of dictionaries specifying the diagram's
///   nodes and connections.
///
/// - debug (bool, 1, 2, 3): Level of detail for drawing debug information.
///  Level 1 shows a coordinate grid; higher levels show bounding boxes and
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
/// - node-pad (length, pair of lengths): Default padding between a node's
///  content and its bounding box.
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
///  		arrow-diagram(spacing: 8mm, {
///   			node((i, 0), raw("defocus: "+str(defocus)), stroke: black, defocus: defocus)
///  			for y in (-1, +1) {
///   				conn((i - 1, y), (i, 0))
///   				conn((i, y), (i, 0))
///   				conn((i + 1, y), (i, 0))
///   			}
///   		})
///   	})
///   )
///
/// - crossing-fill (paint): Color to use behind lines or labels to give the
///  illusion of crossing over other objects.
///
/// - render (function): After the node sizes and grid layout have been
///  determined, the `render` function is called with the following arguments:
///   - `grid`: a dictionary of the row and column widths and positions;
///   - `nodes`: an array of nodes (dictionaries) with computed attributes
///    (including size and physical coordinates);
///   - `conns`: an array of connectors (dictionaries) in the diagram; and
///   - `options`: other diagram attributes.
///
///  This callback is exposed so you can access the above data and draw things
///  directly with CeTZ.
#let arrow-diagram(
	..objects,
	debug: false,
	spacing: 3em,
	cell-size: 0pt,
	node-pad: 15pt,
	node-outset: 0pt,
	node-stroke: none,
	node-fill: none,
	node-defocus: 0.2,
	crossing-fill: white,
	render: (grid, nodes, conns, options) => {
		cetz.canvas(draw-diagram(grid, nodes, conns, options))
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
		node-pad: node-pad,
		node-outset: node-outset,
		node-stroke: node-stroke,
		node-fill: node-fill,
		node-defocus: node-defocus,
		cell-size: cell-size,
		crossing-fill: crossing-fill,
		..objects.named(),
	)

	let positional-args = objects.pos().join()
	let nodes = positional-args.filter(e => e.kind == "node")
	let conns = positional-args.filter(e => e.kind == "conn")
	let callbacks = positional-args.filter(e => e.kind == "coord")

	box(style(styles => {

		let em-size = measure(box(width: 1em), styles).width
		let to-pt(len) = len.abs + len.em*em-size

		let options = options
		options.em-size = em-size
		options.spacing = options.spacing.map(to-pt)
		options.node-pad = to-pt(options.node-pad)

		let nodes = compute-nodes(nodes, styles, options)
		let grid = compute-grid(nodes, options)
		let nodes = compute-node-positions(nodes, grid, options)

		render(grid, nodes, conns, options)
	}))
}

