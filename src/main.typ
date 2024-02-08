#import "utils.typ": *
#import "layout.typ": *
#import "draw.typ": *
#import "marks.typ": *


/// Draw a labelled node in an diagram which can connect to edges.
///
/// - pos (point): Dimensionless "elastic coordinates" `(x, y)` of the node. The
///  coordinates are usually integers, but can be fractional.
///
///  See the `diagram()` options to control the physical scale of elastic
///  coordinates.
///
/// - label (content): Content to display inside the node.
/// - inset (length, auto): Padding between the node's content and its bounding
///  box or bounding circle. If `auto`, defaults to the `node-inset` option of
///  `diagram()`.
/// - outset (length, auto): Margin between the node's bounds to the anchor
///  points for connecting edges.
///
///  This does not affect node layout, only how edges connect to the node.
///
/// - shape (rect, circle, function, auto): Shape to draw for the node. If
///  `auto`, one of `rect` or `circle` is chosen depending on the aspect ratio
///  of the node's label.
///
///  Some other shape functions are provided in the `fletcher.shapes` submodule,
///  including #(
///  	fletcher.shapes.diamond,
///  	fletcher.shapes.pill,
///  	fletcher.shapes.parallelogram,
///  	fletcher.shapes.hexagon,
///  	fletcher.shapes.house,
///  ).map(i => [#i]).join([, ], last: [, and ]).
///
///  Custom shapes should be specified as a function `(node, extrude) => (..)`
///  returning `cetz` objects.
///  - The `node` argument is a dictionary containing the node's attributes,
///    including its center position (`node.real-pos`), the label's dimensions
///    (`node.size`), and other options (such as `node.corner-radius`, which may
///    not have an effect for some shapes).
///  - The `extrude` argument is a length which the shape outline should be
///   extruded outwards by. This serves two functions: to support automatic edge
///   anchoring with a node `outset`, and to create multi-stroke effects using
///   `extrude`.
///
///  #fletcher.diagram(
/// )
///
/// - stroke (stroke): Stroke style for the node outline. Defaults to the `node-stroke` option
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
	..args,
	pos: auto,
	label: auto,
	inset: auto,
	outset: auto,
	shape: auto,
	width: auto,
	height: auto,
	radius: auto,
	stroke: auto,
	fill: auto,
	corner-radius: auto,
	defocus: auto,
	extrude: (0,),
) = {
	if args.named().len() > 0 { panic("Unexpected named argument(s):", args) }

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


	if type(label) == content and label.func() == circle { panic(label) }
	metadata((
		class: "node",
		pos: pos,
		label: label,
		inset: inset,
		outset: outset,
		size: (width, height),
		radius: radius,
		shape: shape,
		stroke: stroke,
		fill: fill,
		corner-radius: corner-radius,
		defocus: defocus,
		extrude: extrude,
	))
}


/// Interpret the positional arguments given to an `edge()`
///
/// Tries to intelligently distinguish the `from`, `to`, `marks`, and `label`
/// arguments based on the types.
///
/// Generally, the following combinations are allowed:
/// ```
/// edge(..<coords>, ..<marklabel>, ..<options>)
/// <coords> = () or (to) or (from, to) or (from, ..vertices, to)
/// <marklabel> = (marks, label) or (label, marks) or (marks) or (label) or ()
/// <options> = any number of options specified as strings
/// ```
#let interpret-edge-args(args, options) = {
	if args.named().len() > 0 { panic("Unexpected named argument(s):", args) }
	let new-options = (:)
	let pos = args.pos()

	// predicates to detect the kind of a positional argument
	let is-coord(arg) = type(arg) == array and arg.len() == 2
	let is-rel-coord(arg) = is-coord(arg) or (
		type(arg) == str and arg.match(regex("^[utdblrnsew,]+$")) != none or
		type(arg) == dictionary and "rel" in arg
	)
	let is-arrow-symbol(arg) = type(arg) == symbol and str(arg) in MARK_SYMBOL_ALIASES
	let is-edge-option(arg) = type(arg) == str and arg in EDGE_ARGUMENT_SHORTHANDS
	let maybe-marks(arg) = type(arg) == str and not is-edge-option(arg) or is-arrow-symbol(arg)
	let maybe-label(arg) = type(arg) != str and not is-arrow-symbol(arg) and not is-coord(arg)

	let peek(x, ..predicates) = {
		let preds = predicates.pos()
		x.len() >= preds.len() and x.zip(preds).all(((arg, pred)) => pred(arg))
	}

	// Up to the first two arguments may be coordinates
	let first-coord = auto
	let other-coords = () 

	if peek(pos, is-coord) {
		first-coord = pos.remove(0)
	}
	while peek(pos, is-rel-coord) {
		if type(pos.at(0)) == str {
			other-coords += pos.remove(0).split(",")
		} else {
			other-coords.push(pos.remove(0))
		}
	}

	if other-coords.len() == 0 {
		new-options.from = auto
		new-options.to = first-coord
	} else {
		new-options.from = first-coord
		let (..verts, to) = other-coords
		if options.vertices == () {
			new-options.vertices = verts
		} else if verts != () { panic("Vertices cannot be specified by both positional and named arguments.") }
		new-options.to = to
	}

	// accept (mark, label), (label, mark) or just either one
	if peek(pos, maybe-marks, maybe-label) {
		new-options.marks = pos.remove(0)
		new-options.label = pos.remove(0)
	} else if peek(pos, maybe-label, maybe-marks) {
		new-options.label = pos.remove(0)
		new-options.marks = pos.remove(0)
	} else if peek(pos, maybe-label) {
		new-options.label = pos.remove(0)
	} else if peek(pos, maybe-marks) {
		new-options.marks = pos.remove(0)
	}

	while peek(pos, is-edge-option) {
		new-options += EDGE_ARGUMENT_SHORTHANDS.at(pos.remove(0))
	}

	// If label hasn't already been found, broaden search to accept strings as labels
	if "label" not in new-options and peek(pos, x => type(x) == str) {
		new-options.label = pos.remove(0)
	}

	if pos.len() > 0 {
		panic("Could not interpret `edge()` argument(s):", pos, "Other arguments were:", new-options)
	}

	new-options
}



/// Draw a connecting line or arc in an arrow diagram.
///
///
/// - ..args (any): Positional arguments may specify the edge's:
///  - start and end nodes
///  - any additional vertices
///  - label
///  - marks
///
///  The start and end nodes must come first, and are optional:
///  ```typc
///  edge(from, to, ..) // explicit start and end nodes
///  edge(to, ..) // start node chosen automatically based on last node specified
///  edge(..) // both nodes chosen automatically depending on adjacent nodes
///  edge(from, v1, v2, ..vs, to, ..) // a multi-segmented edge
///  ```
///
///  All coordinates except the start point can be relative (a dictionary of the
///  form `(rel: (Δx, Δy))` or a string containing the characters
///  ${#"lrudtbnesw".clusters().map(raw).join($, $)}$).
/// 
///  Some named arguments, including `marks`, `label`, and `vertices` can be
///  also be specified as positional arguments. For example, the following are
///  equivalent:
///
///  ```typc
///  edge((0,0), (1,0), $f$, "->")
///  edge((0,0), (1,0), $f$, marks: "->")
///  edge((0,0), (1,0), "->", label: $f$)
///  edge((0,0), (1,0), label: $f$, marks: "->")
///  ```
///
///  Additionally, some common options are given flags that may be given as
///  string positional arguments. These are
///  #fletcher.EDGE_ARGUMENT_SHORTHANDS.keys().map(repr).map(raw).join([, ],
///   last: [, and ]).
/// 
/// - vertices (array): Any coordinates for the edge in additional to the start
///  and end coordinates.
///
///  These can also be positional arguments, e.g.,
///  `edge(A, D, vertices: (B, C))` is the same as `edge(A, B, C, D)`.
///  If the number of vertices is non-zero, the edge `kind` defaults to `"poly"`.
///
/// - kind (string): The kind of the edge, one of `"line"`, `"arc"`, or `"poly"`.
///  This is chosen automatically based on the presence of other options (`bend`
///  implies `"arc"`, `corner` or additional vertices implies `"poly"`).
///
/// - corner (none, left, right): Whether to create a right-angled corner,
///  turning `left` or `right`.
///
/// - bend (angle): Edge curvature. If `0deg`, the connector is a straight line;
///  positive angles bend clockwise.
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
/// - label (content): Content for the edge label. See the `label-pos` and
///  `label-side` options to control the position (and `label-sep` and
///  `label-anchor` for finer control).
///
/// - label-side (left, right, center): Which side of the connector to place the
///  label on, viewed as you walk along it from base to tip. If `center`, then
///  the label is place over the connector. When `auto`, a value of `left` or
///  `right` is chosen to automatically so that the label is
///    - roughly above the connector, in the case of straight lines; or
///    - on the outside of the curve, in the case of arcs.
///
/// - label-anchor (anchor): The anchor point to place the label at, such as
///  `"top-right"`, `"center"`, `"bottom"`, etc. If `auto`, the anchor is
///  automatically chosen based on `label-side` and the angle of the connector.
///
/// - stroke (stroke): Stroke style of the edge. Arrows scale with the stroke
///  thickness.
/// 
/// - dash (dash type): The stroke's dash style. This is also set by some mark
///  styles. For example, setting `marks: "<..>"` applies `dash: "dotted"`.
/// 
/// - marks (pair of strings): The marks (arrowheads) to draw along an edge's
///  stroke. This may be:
///
///  - A shorthand string such as `"->"` or `"hook'-/->>"`. Specifically,
///   shorthand strings are of the form $M_1 L M_2$ or $M_1 L M_2 L M_3$, where
///   $
///   M_i in {#fletcher.MARK_ALIASES.keys().filter(x => x.len() < 4).map(raw.with(lang: none)).join($,$)} union N
///   $
///   is a mark symbol and
///   $L in {#("-", "--", "..", "=", "==").map(raw.with(lang: none)).join($,$)}$
///   is the line style.
///   The mark symbol can also be a name,
///   $M_i in N = {#("hook", "hook'", "harpoon", "harpoon'", "head", "circle").map(raw.with(lang: none)).join($,$), ...}$ 
///   where a trailing `'` means to reflect the mark across the stroke.
///
///  - An array of marks, where each mark is specified by name or by a
///   dictionary of parameters.
///
/// Shorthands are expanded into other arguments. For example,
/// `edge(p1, p2, "=>")` is short for `edge(p1, p2, marks: (none, "head"), "double")`, or more precisely, `edge(p1, p2, ..fletcher.interpret-marks-arg("=>"))`.
///
///
/// #table(
/// 	columns: (1fr, 4fr),
/// 	align: (center + horizon, horizon),
///  	[Arrow], [`marks`],
/// 	..(
///  		"->",
///  		">>-->",
///  		"<=>",
///  		"==>",
///         "->>-",
///  		"x-/-@",
///  		"|..|",
///  		"hook->>",
///  		"hook'->>",
///  		"||-*-harpoon'",
///         ("X", (kind: "head", size: 15, sharpness: 40deg),),
///         ((kind: "circle", pos: 0.5, fill: true),),
/// 	).map(arg => (
///  		fletcher.diagram(edge((0,0), (1,0), marks: arg, stroke: 0.8pt)),
///  		raw(repr(arg)),
///  	)).join()
/// )
///
/// - mark-scale (percent):
/// Scale factor for marks or arrowheads.
///
/// #fletcher.diagram(
/// 	label-sep: 10pt,
/// 	edge-stroke: 1pt,
///		for i in range(3) {
///			let s = (1 + i/2)*100%
/// 		edge((2*i,0), (2*i + 1,0), label: s, "->", mark-scale: s)
/// 	}
///)
/// 
/// Note that the default arrowheads scale automatically with double and triple
/// strokes:
///
/// #fletcher.diagram(
/// 	label-sep: 10pt,
/// 	edge-stroke: 1pt,
///		for (i, s) in ("->", "=>", "==>").enumerate() {
/// 		edge((2*i,0), (2*i + 1,0), s, label: raw(s, lang: none))
/// 	}
/// )
/// - extrude (array): Draw a separate stroke for each extrusion offset to
///  obtain a multi-stroke effect. Offsets may be numbers (specifying multiples
///  of the stroke's thickness) or lengths.
///
///  #fletcher.diagram({
///  	(
///  		(0,),
///  		(-1.5,+1.5),
///  		(-2,0,+2),
///  		(-.5em,),
///  		(0, 5pt,),
///  	).enumerate().map(((i, e)) => {
///  		edge(
///  			(2*i, 0), (2*i + 1, 0), [#e], "|->",
///  			extrude: e, stroke: 1pt, label-sep: 1em)
///  	}).join()
///  })
///  
///  Notice how the ends of the line need to shift a little depending on the
///  mark. For basic arrow heads, this offset is computed with
///  `round-arrow-cap-offset()`.
///
/// - crossing (bool): If `true`, draws a backdrop of color `crossing-fill` to
///  give the illusion of lines crossing each other.
///
///  #fletcher.diagram(crossing-fill: luma(98%), {
///  	edge((0,1), (1,0), stroke: 1pt)
///  	edge((0,0), (1,1), stroke: 1pt)
///  	edge((2,1), (3,0), stroke: 1pt)
///  	edge((2,0), (3,1), stroke: 1pt, crossing: true)
///  })
///
/// You can also pass `"crossing"` as a positional argument as a shorthand for
/// `crossing: true`.
/// 
/// - crossing-thickness (number): Thickness of the "crossing" background
///  stroke, if `crossing: true`, in multiples of the normal stroke's thickness.
///  Defaults to the `crossing-thickness` option of `diagram()`.
/// 
///  #fletcher.diagram(crossing-fill: luma(98%), {
///  	(1, 2, 4, 8).enumerate().map(((i, x)) => {
///  		edge((2*i, 1), (2*i + 1, 0), stroke: 1pt, label-sep: 1em)
///  		edge((2*i, 0), (2*i + 1, 1), raw(str(x)), stroke: 1pt, label-sep:
///  		2pt, label-pos: 0.3, crossing: true, crossing-thickness: x)
///  	}).join()
///  })
/// 
/// - crossing-fill (paint): Color to use behind connectors or labels to give the illusion of crossing over other objects. Defaults to the `crossing-fill` option of
///  `diagram()`.
///
///  #let cross(x, fill) = {
///  	edge((2*x + 0,1), (2*x + 1,0), stroke: 1pt)
///  	edge((2*x + 0,0), (2*x + 1,1), $f$, stroke: 1pt, crossing: true, crossing-fill: fill)
///  }
///  #fletcher.diagram(crossing-thickness: 5, {
///  	cross(0, white)
///  	cross(1, blue.lighten(50%))
///  	cross(2, luma(98%))
///  })
///
/// - corner-radius (length, none): Radius of rounded corners for edges with
///  multiple segments. Note that `none` is distinct from `0pt`.
///
///  #for (i, r) in (none, 0pt, 5pt).enumerate() {
///  	if i > 0 { h(1fr) }
///  	fletcher.diagram(
///  		edge-stroke: 1pt,
///  		edge((3*i, 0), "r,t,rd,r", "=>", raw(repr(r)), label-pos: 0.6, corner-radius: r)
///  	)
///  }
///
///  This length specifies the corner radius for right-angled bends. The actual
///  radius is smaller for acute angles and larger for obtuse angles to balance
///  things visually. (Trust me, it looks naff otherwise!)
///
///  If `auto`, defaults to the `diagram()` option `edge-corner-radius`.
///
/// - shift (length): Amount to shift the edge sideways by, perpendicular to its
///  direction.
/// 
/// #fletcher.diagram($
/// 	A edge(->, #`3pt`, shift: #3pt) #edge("<-", `-3pt`, shift:
/// 	(-3pt),label-side: right) & B
/// $)
///
#let edge(
	..args,
	vertices: (),
	label: none,
	label-side: auto,
	label-pos: 0.5,
	label-sep: auto,
	label-anchor: auto,
	stroke: auto,
	dash: none,
	kind: auto,
	bend: 0deg,
	corner: none,
	corner-radius: auto,
	marks: (none, none),
	mark-scale: 100%,
	extrude: (0,),
	crossing: false,
	crossing-thickness: auto,
	crossing-fill: auto,
	shift: 0pt,
) = {

	let options = (
		from: auto, // set with positional args
		to: auto,
		vertices: vertices,
		label: label,
		label-pos: label-pos,
		label-sep: label-sep,
		label-anchor: label-anchor,
		label-side: label-side,
		stroke: stroke,
		dash: dash,
		kind: kind,
		bend: bend,
		corner: corner,
		corner-radius: corner-radius,
		marks: marks,
		mark-scale: mark-scale,
		extrude: extrude,
		crossing: crossing,
		crossing-thickness: crossing-thickness,
		crossing-fill: crossing-fill,
		shift: shift,
	)

	options += interpret-edge-args(args, options)
	options += interpret-marks-arg(options.marks)

	// relative coordinate shorthands
	let interpret-coord-str(coord) = {
		if type(coord) != str { return coord }
		let rel = (0, 0)
		let dirs = (
			"t": ( 0,-1), "n": ( 0,-1), "u": ( 0,-1),
			"b": ( 0,+1), "s": ( 0,+1), "d": ( 0,+1),
			"l": (-1, 0), "w": (-1, 0),
			"r": (+1, 0), "e": (+1, 0),
		)
		for char in coord.clusters() {
			rel = vector.add(rel, dirs.at(char))
		}
		(rel: rel)
	}
	options.to = interpret-coord-str(options.to)
	options.vertices = options.vertices.map(interpret-coord-str)
	
	let stroke = default(as-stroke(options.stroke), as-stroke((:)))
	options.stroke = as-stroke((
		paint: stroke.paint,
		cap: default(stroke.cap, "round"),
		thickness: stroke.thickness,
		dash: default(stroke.dash, options.dash),
	))

	if options.label-side == center {
		options.label-anchor = "center"
		options.label-sep = 0pt
	}

	if type(options.shift) != array { options.shift = (options.shift, options.shift) }

	let obj = ( 
		class: "edge",
		..options,
		is-crossing-background: false,
	)

	assert(type(obj.marks) == array, message: repr(obj))

	// for the crossing effect, add another edge underneath
	if options.crossing {
		metadata((
			..obj,
			is-crossing-background: true
		))
	}

	metadata(obj)
}










// Ensure all node and edge attributes are complete and consistent,
// resolving relative lengths and so on.
#let apply-defaults(nodes, edges, options) = {
	let to-pt(len) = if type(len) == length {
		len.abs + len.em*options.em-size
	} else {
		len
	}

	(
		nodes: nodes.map(node => {

			if node.stroke == auto {
				node.stroke = options.node-stroke
			} else if node.stroke != none {
				if options.node-stroke != none {
					node.stroke = as-stroke(
						stroke-to-dict(options.node-stroke) +
						stroke-to-dict(node.stroke)
					)
				} else {
					node.stroke = as-stroke(node.stroke)
				}
			}

			node.fill = default(node.fill, options.node-fill)
			node.corner-radius = default(node.corner-radius, options.node-corner-radius)
			node.inset = default(node.inset, options.node-inset)
			node.outset = default(node.outset, options.node-outset)
			node.defocus = default(node.defocus, options.node-defocus)

			node.size = node.size.map(to-pt)
			node.radius = to-pt(node.radius)

			if node.shape == auto {
				if node.radius != auto { node.shape = "circle" }
				if node.size != (auto, auto) { node.shape = "rect" }
			}

			let real-stroke-thickness = if type(node.stroke) == stroke {
				default(node.stroke.thickness, 1pt)
			} else  {
				1pt
			}

			node.extrude = node.extrude.map(d => {
				if type(d) == length { d }
				else { d*real-stroke-thickness }
			}).map(to-pt)

			if type(node.outset) in (int, float) {
				node.outset *= real-stroke-thickness
			}

			node.inset = to-pt(node.inset)
			node.outset = to-pt(node.outset)

			node
		}),

		edges: edges.map(edge => {


			edge.stroke = as-stroke(edge.stroke)

			if edge.stroke == none {
				// hack: for no stroke, it's easier to do the following.
				// then we have the guarantee that edge.stroke is actually
				// a stroke, not possibly none
				edge.extrude = ()
				edge.marks = ()
				edge.stroke = as-stroke((:))
			}

			edge.stroke = (
				(thickness: 0.048em) + // want to be able to assume thickness is a length
				stroke-to-dict(options.edge-stroke) +
				stroke-to-dict(edge.stroke)
			)
			edge.stroke.thickness = to-pt(edge.stroke.thickness)
			edge.stroke = as-stroke(edge.stroke)


			edge.extrude = edge.extrude.map(d => {
				if type(d) == length { to-pt(d) }
				else { d*edge.stroke.thickness }
			})

			edge.crossing-fill = default(edge.crossing-fill, options.crossing-fill)
			edge.crossing-thickness = default(edge.crossing-thickness, options.crossing-thickness)
			edge.label-sep = default(edge.label-sep, options.label-sep)
			edge.corner-radius = default(edge.corner-radius, options.edge-corner-radius)

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
				if edge.vertices.len() > 0 { edge.kind = "poly" }
				else if edge.corner != none { edge.kind = "corner" }
				else if edge.bend != 0deg { edge.kind = "arc" }
				else { edge.kind = "line" }
			}


			// Scale marks
			edge.mark-scale *= options.mark-scale
			let scale = edge.mark-scale/100%
			edge.marks = edge.marks.map(mark => {
				if mark == none { return }
				for k in ("size", "inner-len", "outer-len") {
					if k in mark { mark.at(k) *= scale }
				}
				mark
			})

			edge.label-sep = to-pt(edge.label-sep)



			edge
		}),
	)
}


#let extract-nodes-and-edges-from-equation(eq) = {
	assert(eq.func() == math.equation)
	let terms = eq.body + []
	assert(repr(terms.func()) == "sequence")

	let edges = ()
	let nodes = ()

	let matrix = ((none,),)
	let (x, y) = (0, 0)
	for child in terms.children {
		if child.func() == metadata {
			if child.value.class == "edge" {
				let edge = child.value
				edge.from = default(edge.from, (x, y))
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

	for (y, row) in matrix.enumerate() {
		for (x, item) in row.enumerate() {
			nodes.push(node((x, y), $item$).value)
		}
	}


	(
		nodes: nodes,
		edges: edges,
	)

}

#let interpret-diagram-args(args) = {
	let nodes = ()
	let edges = ()

	let prev-coord = (0,0)
	let should-set-last-edge-point = false

	for arg in args {
		if arg.func() == metadata {
			if arg.value.class == "node" {
				let node = arg.value

				nodes.push(node)

				prev-coord = node.pos
				if should-set-last-edge-point {
					// the `to` point of the previous edge is waiting to be set
					edges.at(-1).to = node.pos
					should-set-last-edge-point = false
				}

			} else if arg.value.class == "edge" {
				let edge = arg.value

				if edge.from == auto {
					edge.from = prev-coord
				}
				if edge.to == auto {
					if should-set-last-edge-point { panic("Cannot infer edge end point. Please specify explicitly.") }
					should-set-last-edge-point = true
				}
				edges.push(edge)
			}

		} else if arg.func() == math.equation {
			let result = extract-nodes-and-edges-from-equation(arg)
			nodes += result.nodes
			edges += result.edges

		} else {
			panic("Unrecognised value passed to diagram", arg)
		}
	}

	edges = edges.map(edge => {

		for i in range(edge.vertices.len()) {
			let prev = if i == 0 { edge.from } else { edge.vertices.at(i - 1) }
			if type(edge.vertices.at(i)) == dictionary and "rel" in edge.vertices.at(i) {
				edge.vertices.at(i) = vector.add(edge.vertices.at(i).rel, prev)
			}
		}

		let prev = edge.vertices.at(-1, default: edge.from)
		if edge.to == auto {
			edge.to = vector.add(prev, (1, 0))
		} else if type(edge.to) == dictionary and "rel" in edge.to {
			// Resolve relative coordinates
			edge.to = vector.add(prev, edge.to.rel)
		}


		assert(edge.from != auto and edge.to != auto, message: repr(edge))
		assert(type(edge.to) != dictionary, message: repr(edge))
		edge
	})



	(
		nodes: nodes,
		edges: edges,
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
///  A single length `d` is short for `(d, d)`.
///
/// - node-inset (length, pair of lengths): Default value of the `inset` option
///  for `edge()`.
/// - node-outset (length, pair of lengths): Default value of the `outset`
///  option for `edge()`.
/// - node-stroke (stroke, none): Default value of the `stroke` option for
///  `node()`.
///
///   The default stroke is folded with the stroke specified for the node. For
///   example, if `node-stroke` is `1pt` and the node option `stroke` is `red`,
///   then the resulting stroke is `1pt + red`.
/// - node-fill (paint): Default fill for all nodes in diagram. Overridden by
///  individual node options.
///
/// - edge-stroke (stroke): Default value of the `stroke` option for `edge()`.
///  By The default value for this option is chosen relative to the font size to
///  match the thickness of mathematical arrows such as $A -> B$.
///
///   The default stroke is folded with the stroke specified for the edge. For
///   example, if `edge-stroke` is `1pt` and the edge option `stroke` is `red`,
///   then the resulting stroke is `1pt + red`.
///
/// - node-corner-radius (length, none): Default value of the `corner-radius`
///  option for `node()`.
///
/// - edge-corner-radius (length, none): Default value of the `corner-radius`
///  option for `edge()`.
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
/// - label-sep (length): Default value of `label-sep` option for `edge()`.
/// - mark-scale (length): Default value of `mark-scale` option for `edge()`.
/// - crossing-fill (paint): Color to use behind connectors or labels to give
///  the illusion of crossing over other objects. See the `crossing-fill` option
///  of `edge()`.
///
/// - crossing-thickness (number): Default thickness of the occlusion made by
///  crossing connectors. See the `crossing-thickness` option of `edge()`.
/// 
/// - axes (pair of directions): The directions of the diagram's axes.
///
///  This defines the orientation of the coordinate system used by nodes and
///  edges. To make the $y$ coordinate increase up the page, use `(ltr, btt)`.
///  For the matrix convention `(row, column)`, use `(ttb, ltr)`.
///
///  #stack(
///  	dir: ltr,
///  	spacing: 1fr,
///  	fletcher.diagram(
///  		axes: (ltr, ttb),
///  		debug: 1,
///  		node((0,0), $(0,0)$),
///  		edge((0,0), (1,0), "->"),
///  		node((1,0), $(1,0)$),
///  		node((1,1), $(1,1)$),
///  		node((0.5,0.5), `axes: (ltr, ttb)`),
///  	),
///  	move(dy: 0.7em, fletcher.diagram(
///  		axes: (ltr, btt),
///  		debug: 1,
///  		node((0,0), $(0,0)$),
///  		edge((0,0), (1,0), "->"),
///  		node((1,0), $(1,0)$),
///  		node((1,1), $(1,1)$),
///  		node((0.5,0.5), `axes: (ltr, btt)`),
///  	)),
///  	fletcher.diagram(
///  		axes: (ttb, ltr),
///  		debug: 1,
///  		node((0,0), $(0,0)$),
///  		edge((0,0), (1,0), "->", bend: -20deg),
///  		node((1,0), $(1,0)$),
///  		node((1,1), $(1,1)$),
///  		node((0.5,0.5), `axes: (ttb, ltr)`),
///  	),
///  )
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
	axes: (ltr, ttb),
	spacing: 3em,
	cell-size: 0pt,
	edge-stroke: 0.048em,
	node-stroke: none,
	edge-corner-radius: 2.5pt,
	node-corner-radius: none,
	node-inset: 12pt,
	node-outset: 0pt,
	node-fill: none,
	node-defocus: 0.2,
	label-sep: 0.2em,
	mark-scale: 100%,
	crossing-fill: white,
	crossing-thickness: 5,
	render: (grid, nodes, edges, options) => {
		cetz.canvas(
			draw-diagram(grid, nodes, edges, options)
		)
	},
) = {

	if type(spacing) != array { spacing = (spacing, spacing) }
	if type(cell-size) != array { cell-size = (cell-size, cell-size) }

	if objects.named().len() > 0 { 
		let args = objects.named().keys().join(", ")
		panic("Unexpected named argument(s): " + args)
	}

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

	assert(axes.at(0).axis() != axes.at(1).axis(), message: "Axes cannot both be in the same direction.")


	// Interpret objects at a sequence of nodes and edges
	let positional-args = objects.pos().join() + [] // join to ensure sequence
	assert(repr(positional-args.func()) == "sequence")

	let (nodes, edges) = interpret-diagram-args(positional-args.children)
	
	box(style(styles => {
		let options = options

		options.em-size = measure(h(1em), styles).width
		let to-pt(len) = len.abs + len.em*options.em-size
		options.spacing = options.spacing.map(to-pt)

		let (nodes, edges) = (nodes, edges)

		// Add dummy nodes at edge terminals
		for edge in edges {
			nodes.push(node(edge.from, none).value)
			nodes.push(node(edge.to, none).value)
			for vertex in edge.vertices { nodes.push(node(vertex, none).value) }
		}

		// Swap axes
		if options.axes.map(a => a.axis()) == ("vertical", "horizontal") {
			nodes = nodes.map(node => {
				node.pos = node.pos.rev()
				node
			})
			edges = edges.map(edge => {
				edge.from = edge.from.rev()
				edge.to = edge.to.rev()
				edge
			})
			options.axes = options.axes.rev()
		}

		let (nodes, edges) = apply-defaults(nodes, edges, options)

		let nodes = compute-node-sizes(nodes, styles)
		let grid  = compute-grid(nodes, options)
		options.get-coord = grid.get-coord
		let nodes = compute-node-positions(nodes, grid, options)

		render(grid, nodes, edges, options)
	}))
}

