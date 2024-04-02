#import "utils.typ": *
#import "coords.typ": *
#import "layout.typ": *
#import "draw.typ": *
#import "marks.typ": *

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
/// - inset (length, auto): Padding between the node's content and its bounding
///   box or bounding circle.
///
/// - outset (length, auto): Margin between the node's bounds to the anchor
///   points for connecting edges.
///
///   This does not affect node layout, only how closely edges connect to the
///   node.
///
/// - shape (rect, circle, function, auto): Shape to draw for the node. If
///   `auto`, one of `rect` or `circle` is chosen depending on the aspect ratio
///   of the node's label.
///
///   Some other shape functions are provided in the `fletcher.shapes`
///   submodule, including
///   #(
///   	fletcher.shapes.diamond,
///   	fletcher.shapes.pill,
///   	fletcher.shapes.parallelogram,
///   	fletcher.shapes.hexagon,
///   	fletcher.shapes.house,
///   ).map(i => [#i]).join([, ], last: [, and ]).
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
	label: auto,
	inset: auto,
	outset: auto,
	stroke: auto,
	fill: auto,
	width: auto,
	height: auto,
	radius: auto,
	corner-radius: auto,
	shape: auto,
	extrude: (0,),
	defocus: auto,
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

	metadata((
		class: "node",
		pos: pos,
		name: pass-none(as-label)(name),
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
		post: post,
	))
}



#let resolve-node-options(node, options) = {
	let to-pt(len) = to-abs-length(len, options.em-size)

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

	node
}



/// Interpret the positional arguments given to an `edge()`
///
/// Tries to intelligently distinguish the `from`, `to`, `marks`, and `label`
/// arguments based on the argument types.
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
	let is-coord(arg) = type(arg) == array and arg.len() == 2 or type(arg) == label
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

	let first-coord = auto
	let other-coords = ()
	let found-coords = false

	if peek(pos, is-coord) {
		first-coord = pos.remove(0)
		found-coords = true
	}
	while peek(pos, is-rel-coord) {
		if type(pos.at(0)) == str {
			other-coords += pos.remove(0).split(",")
		} else {
			other-coords.push(pos.remove(0))
		}
		found-coords = true
	}


	if options.vertices == () {
		// vertices specified through positional arguments
		if other-coords == () {
			// if only one coord is given, it is the end point,
			// with the start point implicit/auto
			new-options.vertices = (auto, first-coord)
		} else {
			new-options.vertices = (first-coord, ..other-coords)
		}
	} else if found-coords {
		// vertices explicitly set with named argument
		panic("Vertices cannot be specified by both positional and named arguments.")
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
		panic("Couldn't understand `node()` positional argument(s):", pos, "Try using named arguments. Interpreted other arguments as:", new-options)
	}

	new-options
}



/// Draw a connecting line or arc in an arrow diagram.
///
///
/// - ..args (any): An edge's positional arguments may specify:
///   - the edge's #param[edge][vertices]
///   - the #param[edge][label] content
///   - #param[edge][marks] and other style options
///
///   Vertex coordinates must come first, and are optional:
///
///   ```typc
///   edge(from, to, ..) // explicit start and end nodes
///   edge(to, ..) // start node chosen automatically based on last node specified
///   edge(..) // both nodes chosen automatically depending on adjacent nodes
///   edge(from, v1, v2, ..vs, to, ..) // a multi-segmented edge
///   ```
///
///   All coordinates except the start point can be relative (a dictionary of the
///   form `(rel: (Δx, Δy))` or a string containing the characters
///   ${#"lrudtbnesw".clusters().map(raw).join($, $)}$).
///
///   An edge's #param[edge][marks] and #param[edge][label] can be also be
///   specified as positional arguments. They are disambiguated by guessing
///   based on the types. For example, the following are equivalent:
///
///   ```typc
///   edge((0,0), (1,0), $f$, "->")
///   edge((0,0), (1,0), "->", $f$)
///   edge((0,0), (1,0), $f$, marks: "->")
///   edge((0,0), (1,0), "->", label: $f$)
///   edge((0,0), (1,0), label: $f$, marks: "->")
///   ```
///
///   Additionally, some common options are given flags that may be given as
///   string positional arguments. These are
///   #fletcher.EDGE_ARGUMENT_SHORTHANDS.keys().map(repr).map(raw).join([, ], last: [, and ]).
///   For example, the following are equivalent:
///
///   ```typc
///   edge((0,0), (1,0), $f$, "wave", "crossing")
///   edge((0,0), (1,0), $f$, decorations: "wave", crossing: true)
///   ```
///
/// - vertices (array): Array of (at least two) coordinates for the edge.
///
///   Vertices can also be specified as leading positional arguments, but if so,
///   the `vertices` option must be empty. If the number of vertices is greater
///   than two, #param[edge][kind] defaults to `"poly"`.
///
/// - kind (string): The kind of the edge, one of `"line"`, `"arc"`, or `"poly"`.
///   This is chosen automatically based on the presence of other options
///   (#param[edge][bend] implies `"arc"`, #param[edge][corner] or additional
///   vertices implies `"poly"`).
///
/// - corner (none, left, right): Whether to create a right-angled corner,
///   turning `left` or `right`.
///   (Bending right means the corner sticks out to the left, and vice versa.)
///
///   #diagram(
///   	node((0,1), `from`),
///   	node((1,0), `to`),
///   	edge((0,1), (1,0), `right`, "->", corner: right),
///   	edge((0,1), (1,0), `left`, "->", corner: left),
///   )
///
/// - bend (angle): Edge curvature. If `0deg`, the connector is a straight line;
///   positive angles bend clockwise.
///
///   #diagram(debug: 0, {
///   	node((0,0), $A$)
///   	node((1,1), $B$)
///   	let N = 4
///   	range(N + 1)
///   		.map(x => (x/N - 0.5)*2*100deg)
///   		.map(θ => edge((0,0), (1,1), θ, bend: θ, ">->", label-side: center))
///   		.join()
///   })
///
/// - label (content): Content for the edge label. See the
///   #param[edge][label-pos] and #param[edge][label-side] options to control
///   the position (and #param[edge][label-sep] and #param[edge][label-anchor]
///   for finer control).
///
/// - label-side (left, right, center): Which side of the edge to place the
///   label on, viewed as you walk along it from base to tip.
///
///   If `center`, then the label is placed directly on the edge and
///   #param[edge][label-fill] defaults to `true`. When `auto`, a value of
///   `left` or `right` is  automatically chosen so that the label is:
///    - roughly above the connector, in the case of straight lines; or
///    - on the outside of the curve, in the case of arcs.
///
/// - label-pos (number): Position of the label along the connector, from the
///   start to end (from `0` to `1`).
///
///   #stack(
///   	dir: ltr,
///   	spacing: 1fr,
///   	..(0, 0.25, 0.5, 0.75, 1).map(p => fletcher.diagram(
///   		cell-size: 1cm,
///   		edge((0,0), (1,0), p, "->", label-pos: p))
///   	),
///   )
///
/// - label-sep (length): Separation between the connector and the label anchor.
///
///   With the default anchor (automatically set to `"bottom"` in this case):
///
///   #diagram(
///   	debug: 2,
///   	cell-size: 8mm,
///   	{
///   		for (i, s) in (-5pt, 0pt, .4em, .8em).enumerate() {
///   			edge((2*i,0), (2*i + 1,0), s, "->", label-sep: s)
///   		}
///   })
///
///   With #param[edge][label-anchor] set to `"center"`:
///
///   #diagram(
///   	debug: 2,
///   	cell-size: 8mm,
///   	{
///   		for (i, s) in (-5pt, 0pt, .4em, .8em).enumerate() {
///   			edge((2*i,0), (2*i + 1,0), s, "->", label-sep: s, label-anchor: "center")
///   		}
///   })
///
///   Set #param[diagram][debug] to `2` or higher to see label anchors and
///   outlines as seen here.
///
/// - label-anchor (anchor): The anchor point to place the label at, such as
///   `"top-right"`, `"center"`, `"bottom"`, etc. If `auto`, the anchor is
///   automatically chosen based on #param[edge][label-side] and the angle of
///   the connector.
///
/// - label-fill (bool, paint): The background fill for the label. If `true`,
///   defaults to the value of #param[edge][crossing-fill]. If `false` or
///   `none`, no fill is used. If `auto`, then defaults to `true` if the label
///   is covering the edge (#param[edge][label-side]`: center`).
///
/// - stroke (stroke): Stroke style of the edge. Arrows/marks scale with the
///   stroke thickness (and with #param[edge][mark-scale]).
///
/// - dash (string): The stroke's dash style. This is also set by some mark
///   styles. For example, setting `marks: "<..>"` applies `dash: "dotted"`.
///
/// - decorations (none, string, function): Apply a CeTZ path decoration to the
///   stroke. Preset options are `"wave"`, `"zigzag"`, and `"coil"` (which may
///   also be passed as convenience positional arguments), but a decoration
///   function may also be specified.
///
///   #example(```
///   diagram(
///   	$
///   		A edge("wave") &
///   		B edge("zigzag") &
///   		C edge("coil") & D \
///   		alpha &&& omega
///   	$,
///   	edge((0,1), (3,1), "<->", decorations:
///   		cetz.decorations.wave
///   			.with(amplitude: .4)
///   	)
///   )
///   ```)
///
/// - marks (array): The marks (arrowheads) to draw along an edge's stroke. This
///   may be:
///
///   - A shorthand string such as `"->"` or `"hook'-/->>"`. Specifically,
///     shorthand strings are of the form $M_1 L M_2$ or $M_1 L M_2 L M_3$,
///     where
///     $
///     M_i in {#fletcher.MARK_ALIASES.keys().filter(x => x.len() < 4).map(raw.with(lang: none)).join($,$)} union N
///     $
///     is a mark symbol and
///     $L in {#("-", "--", "..", "=", "==").map(raw.with(lang: none)).join($,$)}$
///     is the line style.
///     The mark symbol can also be a name,
///     $M_i in N = {#("hook", "hook'", "harpoon", "harpoon'", "head", "circle").map(raw.with(lang: none)).join($,$), ...}$
///     where a trailing `'` means to reflect the mark across the stroke.
///
///   - An array of marks, where each mark is specified by name or by a
///     dictionary of parameters.
///
///   Shorthands are expanded into other arguments. For example,
///   `edge(p1, p2, "=>")` is short for `edge(p1, p2, marks: (none, "head"), "double")`, or more precisely, `edge(p1, p2, ..fletcher.interpret-marks-arg("=>"))`.
///
///   #table(
///   	columns: (1fr, 4fr),
///   	align: (center + horizon, horizon),
///   	[Arrow], [`marks`],
///   	..(
///   		"->",
///   		">>-->",
///   		"<=>",
///   		"==>",
///         "->>-",
///   		"x-/-@",
///   		"|..|",
///   		"hook->>",
///   		"hook'->>",
///   		"||-*-harpoon'",
///         ("X", (kind: "head", size: 15, sharpness: 40deg),),
///         ((kind: "circle", pos: 0.5, fill: true),),
///   	).map(arg => (
///   		fletcher.diagram(edge((0,0), (1,0), marks: arg, stroke: 0.8pt)),
///   		raw(repr(arg)),
///   	)).join()
///   )
///
/// - mark-scale (percent): Scale factor for marks or arrowheads, relative to
///   the #param[edge][stroke] thickness.
///
///   #diagram(
///   	label-sep: 10pt,
///   	edge-stroke: 1pt,
///   	for i in range(3) {
///   		let s = (1 + i/2)*100%
///   		edge((2*i,0), (2*i + 1,0), label: s, "->", mark-scale: s)
///   	}
///   )
///
///   Note that the default arrowheads scale automatically with double and
///   triple strokes:
///
///   #diagram(
///   	label-sep: 10pt,
///   	edge-stroke: 1pt,
///   	for (i, s) in ("->", "=>", "==>").enumerate() {
///   		edge((2*i,0), (2*i + 1,0), s, label: raw(s, lang: none))
///   	}
///   )
///
/// - extrude (array): Draw a separate stroke for each extrusion offset to
///   obtain a multi-stroke effect. Offsets may be numbers (specifying multiples
///   of the stroke's thickness) or lengths.
///
///   #diagram({
///   	(
///   		(0,),
///   		(-1.5,+1.5),
///   		(-2,0,+2),
///   		(-.5em,),
///   		(0, 5pt,),
///   	).enumerate().map(((i, e)) => {
///   		edge(
///   			(2*i, 0), (2*i + 1, 0), [#e], "|->",
///   			extrude: e, stroke: 1pt, label-sep: 1em)
///   	}).join()
///   })
///
///   Notice how the ends of the line need to shift a little depending on the
///   mark. For basic arrow heads, this offset is computed with
///   `round-arrow-cap-offset()`.
///
///   See also #the-param[node][extrude].
///
/// - crossing (bool): If `true`, draws a backdrop of color
///   #param[edge][crossing-fill] to give the illusion of lines crossing each
///    other.
///
///   #diagram({
///   	edge((0,1), (1,0), stroke: 1pt)
///   	edge((0,0), (1,1), stroke: 1pt)
///   	edge((2,1), (3,0), stroke: 1pt)
///   	edge((2,0), (3,1), stroke: 1pt, crossing: true)
///   })
///
///   You can also pass `"crossing"` as a positional argument as a shorthand for
///   `crossing: true`.
///
/// - crossing-thickness (number): Thickness of the "crossing" background stroke
///   (applicable if #param[edge][crossing] is `true`) in multiples of the
///   normal stroke's thickness. Defaults to
///   #the-param[diagram][crossing-thickness].
///
///   #diagram({
///   	(1, 2, 4, 8).enumerate().map(((i, x)) => {
///   		edge((2*i, 1), (2*i + 1, 0), stroke: 1pt, label-sep: 1em)
///   		edge((2*i, 0), (2*i + 1, 1), raw(str(x)), stroke: 1pt, label-sep:
///   		2pt, label-pos: 0.3, crossing: true, crossing-thickness: x)
///   	}).join()
///   })
///
/// - crossing-fill (paint): Color to use behind connectors or labels to give
///   the illusion of crossing over other objects. Defaults to
///   #param[diagram][crossing-fill].
///
///   #let cross(x, fill) = {
///   	edge((2*x + 0,1), (2*x + 1,0), stroke: 1pt)
///   	edge((2*x + 0,0), (2*x + 1,1), $f$, stroke: 1pt, crossing: true, crossing-fill: fill, label-fill: true)
///   }
///   #diagram(crossing-thickness: 5, {
///   	cross(0, white)
///   	cross(1, blue.lighten(50%))
///   })
///
/// - corner-radius (length, none): Radius of rounded corners for edges with
///   multiple segments. Note that `none` is distinct from `0pt`.
///
///   #for (i, r) in (none, 0pt, 5pt).enumerate() {
///   	if i > 0 { h(1fr) }
///   	fletcher.diagram(
///   		edge-stroke: 1pt,
///   		edge((3*i, 0), "r,t,rd,r", "=>", raw(repr(r)), label-pos: 0.6, corner-radius: r)
///   	)
///   }
///
///   This length specifies the corner radius for right-angled bends. The actual
///   radius is smaller for acute angles and larger for obtuse angles to balance
///   things visually. (Trust me, it looks naff otherwise!)
///
///   If `auto`, defaults to #the-param[diagram][edge-corner-radius].
///
/// - shift (length, number, pair): Amount to shift the edge sideways by,
///   perpendicular to its direction. A pair `(from, to)` controls the shifts at
///   each end of the edge independently, and a single shift `s` is short for
///   `(s, s)`. Shifts can absolute lengths (e.g., `5pt`) or coordinate
///   differences (e.g., `0.1`).
///
///   #diagram(
///   	node((0,0), $A$), node((1,0), $B$),
///   	edge((0,0), (1,0), "->", `3pt`, shift: 3pt),
///   	edge((0,0), (1,0), "->", `-3pt`, shift: -3pt, label-side: right),
///   )
///
///   If an edge has many vertices, the shifts only affect the first and last
///   segments of the edge.
///
///   #example(```
///   diagram(
///   	node-fill: luma(70%),
///   	node((0,0), [Hello]),
///   	edge("u,r,d", "->"),
///   	edge("u,r,d", "-->", shift: 8pt),
///   	node((1,0), [World]),
///   )
///   ```)
///
/// - snap-to (pair): The nodes the start and end of an edge should snap to.
/// Each node can be a position or node #param[node][name], or `none` to disable
/// snapping.
///
///   By default, an edge's first and last #param[edge][vertices] snap to nearby
///   nodes. This option can be used in case automatic snapping fails (if there
///   are many nodes close together, for example.)
///
/// - post (function): Callback function to intercept `cetz` objects before they
///   are drawn to the canvas.
///
///   This can be used to hide elements without affecting layout (for use with
///   #link("https://github.com/touying-typ/touying")[Touying], for example).
///   The `hide()` function also helps for this purpose.
///
#let edge(
	..args,
	vertices: (),
	extrude: (0,),
	shift: 0pt,
	label: none,
	label-side: auto,
	label-pos: 0.5,
	label-sep: auto,
	label-anchor: auto,
	label-fill: auto,
	stroke: auto,
	dash: none,
	decorations: none,
	kind: auto,
	bend: 0deg,
	corner: none,
	corner-radius: auto,
	marks: (),
	mark-scale: 100%,
	crossing: false,
	crossing-thickness: auto,
	crossing-fill: auto,
	snap-to: (auto, auto),
	post: x => x,
) = {

	let options = (
		vertices: vertices,
		label: label,
		label-pos: label-pos,
		label-sep: label-sep,
		label-anchor: label-anchor,
		label-side: label-side,
		label-fill: label-fill,
		stroke: stroke,
		dash: dash,
		decorations: decorations,
		kind: kind,
		bend: bend,
		corner: corner,
		corner-radius: corner-radius,
		extrude: extrude,
		shift: shift,
		marks: marks,
		mark-scale: mark-scale,
		crossing: crossing,
		crossing-thickness: crossing-thickness,
		crossing-fill: crossing-fill,
		snap-to: snap-to,
		post: post,
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
	options.vertices = options.vertices.map(interpret-coord-str)


	options.stroke = if options.stroke != none {
		(
			cap: "round",
			dash: options.dash,
		) + stroke-to-dict(map-auto(options.stroke, (:)))
	}

	if options.label-side == center {
		options.label-anchor = "center"
		options.label-sep = 0pt
	}

	if type(options.shift) != array { options.shift = (options.shift, options.shift) }

	if type(options.decorations) == str {
		options.decorations = (
			"wave": cetz.decorations.wave.with(
				amplitude: .12,
				segment-length: .2,
			),
			"zigzag": cetz.decorations.zigzag.with(
				amplitude: .12,
				segment-length: .2,
			),
			"coil": cetz.decorations.coil.with(
				amplitude: .15,
				segment-length: .15,
				factor: 140%,
			),
		).at(options.decorations)
	}

	let obj = (
		class: "edge",
		..options,
		is-crossing-background: false,
	)

	// for the crossing effect, add another edge underneath
	if options.crossing {
		metadata((
			..obj,
			is-crossing-background: true
		))
	}

	metadata(obj)
}



#let resolve-edge-options(edge, options) = {
	let to-pt(len) = to-abs-length(len, options.em-size)

	edge.stroke = pass-none(stroke)(edge.stroke)

	if edge.stroke == none {
		// hack: for no stroke, it's easier to do the following.
		// then we have the guarantee that edge.stroke is actually
		// a stroke, not possibly none
		edge.extrude = ()
		edge.marks = ()
		edge.stroke = stroke((:))
	}

	edge.stroke = (
		(thickness: 0.048em) + // guarantees thickness is a length
		stroke-to-dict(options.edge-stroke) +
		stroke-to-dict(edge.stroke)
	)
	edge.stroke.thickness = to-pt(edge.stroke.thickness)

	edge.extrude = edge.extrude.map(d => {
		if type(d) == length { to-pt(d) }
		else { d*edge.stroke.thickness }
	})

	edge.crossing-fill = map-auto(edge.crossing-fill, options.crossing-fill)
	edge.crossing-thickness = map-auto(edge.crossing-thickness, options.crossing-thickness)
	edge.corner-radius = map-auto(edge.corner-radius, options.edge-corner-radius)

	if edge.is-crossing-background {
		edge.stroke = (
			thickness: edge.crossing-thickness*edge.stroke.thickness,
			paint: edge.crossing-fill,
			cap: "round",
		)
		edge.marks = (none, none)
		edge.extrude = edge.extrude.map(e => e/edge.crossing-thickness)
	}
	
	edge.stroke = as-stroke(edge.stroke)

	if edge.kind == auto {
		if edge.vertices.len() > 2 { edge.kind = "poly" }
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

	edge.label-sep = to-pt(map-auto(edge.label-sep, options.label-sep))

	edge.label-fill = map-auto(edge.label-fill, edge.label-side == center)

	if edge.label-fill == true { edge.label-fill = edge.crossing-fill }
	if edge.label-fill == false { edge.label-fill = none }

	edge
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
		panic("Unexpected named argument(s) to diagram: " + args)
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
			panic("Unrecognised value passed to diagram", obj)
		}
	}

	edges = edges.map(edge => {
		if edge.vertices.at(-1) == auto {
			edge.vertices.at(-1) = vector.add(edge.vertices.at(-2), (1,0))
		}
		edge
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
/// - mark-scale (length): Default value of #the-param[edge][mark-scale].
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

	if type(spacing) != array { spacing = (spacing, spacing) }
	if type(cell-size) != array { cell-size = (cell-size, cell-size) }

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

		options.em-size = measure(h(1em), styles).width
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
			let verts = edge.vertices.map(resolve-label-coordinate.with(nodes))
			edge.vertices = resolve-relative-coordinates(verts)
			edge
		})

		// measure node sizes and determine diagram layout

		let nodes = compute-node-sizes(nodes, styles)
		let grid = compute-grid(nodes, edges, options)

		// compute final/cetz coordinates for nodes and edges

		nodes = nodes.map(node => {
			node.final-pos = uv-to-xy(grid, node.pos)
			node
		})
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
