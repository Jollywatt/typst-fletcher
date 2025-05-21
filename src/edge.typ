#import "utils.typ": *
#import "marks.typ": *
#import "coords.typ": vector-polar-with-xy-or-uv-length, resolve, default-ctx

#let EDGE_FLAGS = (
	"dashed": (dash: "dashed"),
	"dotted": (dash: "dotted"),
	"double": (extrude: (-2, +2)),
	"triple": (extrude: (-4, 0, +4)),
	"crossing": (crossing: true),
	"wave": (decorations: "wave"),
	"zigzag": (decorations: "zigzag"),
	"coil": (decorations: "coil"),
)

#let LINE_ALIASES = (
	"-": (:),
	"=": EDGE_FLAGS.double,
	"==": EDGE_FLAGS.triple,
	"--": EDGE_FLAGS.dashed,
	"..": EDGE_FLAGS.dotted,
	"~": EDGE_FLAGS.wave,
	" ": (extrude: ()),
)

#let MARK_SYMBOL_ALIASES = (
	(sym.arrow.r): "->",
	(sym.arrow.l): "<-",
	(sym.arrow.r.l): "<->",
	(sym.arrow.long.r): "->",
	(sym.arrow.long.l): "<-",
	(sym.arrow.long.r.l): "<->",
	(sym.arrow.double.r): "=>",
	(sym.arrow.double.l): "<=",
	(sym.arrow.double.r.l): "<=>",
	(sym.arrow.double.long.r): "=>",
	(sym.arrow.double.long.l): "<=",
	(sym.arrow.double.long.r.l): "<=>",
	(sym.arrow.r.tail): ">->",
	(sym.arrow.l.tail): "<-<",
	(sym.arrow.twohead): "->>",
	(sym.arrow.twohead.r): "->>",
	(sym.arrow.twohead.l): "<<-",
	(sym.arrow.bar): "|->",
	(sym.arrow.bar.double): "|=>",
	(sym.arrow.hook.r): "hook->",
	(sym.arrow.hook.l): "<-hook'",
	(sym.arrow.squiggly.r): "~>",
	(sym.arrow.squiggly.l): "<~",
	(sym.arrow.long.squiggly.r): "~>",
	(sym.arrow.long.squiggly.l): "<~",
)


#let interpret-marks(marks) = {
	marks = marks.enumerate().map(((i, mark)) => {
		resolve-mark(mark, defaults: (
			pos: i/calc.max(1, marks.len() - 1),
			rev: i == 0,
		))
	}).filter(mark => mark != none) // drop empty marks

	marks = marks.map(mark => {
		mark.tip = (mark.pos == 0) == mark.rev
		if (mark.pos not in (0, 1)) { mark.tip = none }
		mark
	})

	marks
}



/// Parse and interpret the marks argument provided to `edge()`. Returns a
/// dictionary of processed `edge()` arguments.
///
/// - arg (string, array):
/// Can be a string, (e.g. `"->"`, `"<=>"`), etc, or an array of marks.
/// A mark can be a string (e.g., `">"` or `"head"`, `"x"` or `"cross"`) or a dictionary containing the keys:
///   - `kind` (required) the mark name, e.g. `"solid"` or `"bar"`
///   - `pos` the position along the edge to place the mark, from 0 to 1
///   - `rev` whether to reverse the direction
///   - parameters specific to the kind of mark, e.g., `size` or `sharpness`
/// -> dictiony
#let interpret-marks-arg(arg) = {
	if type(arg) == array { return (marks: interpret-marks(arg)) }

	if type(arg) == symbol {
		if str(arg) in MARK_SYMBOL_ALIASES { arg = MARK_SYMBOL_ALIASES.at(arg) }
		else { error("Unrecognised marks symbol #0.", arg) }
	}

	assert(type(arg) == str)
	let text = arg

	let mark-names = MARKS.get().keys().sorted(key: i => -i.len())
	let LINES = LINE_ALIASES.keys().sorted(key: i => -i.len())

	let eat(arg, options) = {
		for option in options {
			if arg.starts-with(option) {
				return (arg.slice(option.len()), option)
			}
		}
		return (arg, none)
	}

	let marks = ()
	let lines = ()

	let mark
	let line
	let flip

	// first mark, [<]-x->>
	(text, mark) = eat(text, mark-names)

	// flip modifier, hook[']
	(text, flip) = eat(text, ("'",))
	if flip != none { mark += flip }

	marks.push(mark)

	let parse-error(suggestion) = error("Invalid marks shorthand #0. Try #1.", arg, suggestion)

	while true {
		// line, <[-]x->>
		(text, line) = eat(text, LINES)
		if line == none {
			let suggestion = arg.slice(0, -text.len()) + "-" + text
			parse-error(suggestion)
		}
		lines.push(line)

		// subsequent mark, <-[x]->>
		(text, mark) = eat(text, mark-names)

		// flip modifier, hook[']
		(text, flip) = eat(text, ("'",))
		if flip != none { mark += flip }

		marks.push(mark)

		if text == "" { break }
		if mark == none {
			// text remains that was not recognised as mark
			let suggestion = marks.intersperse(lines.at(0)).join()
			parse-error(suggestion)
		}
	}


	if lines.dedup().len() > 1 {
		// different line styles were mixed
		let suggestion = marks.intersperse(lines.at(0)).join()
		parse-error(suggestion)
	}
	let line = lines.at(0)


	// make classic math arrows slightly larger on double/triple stroked lines
	if line == "=" {
		marks = marks.map(mark => {
			if mark == none { return }
			(
				">": (inherit: "doublehead", rev: false),
				"<": (inherit: "doublehead", rev: true),
			).at(mark, default: mark)
		})
	} else if line == "==" {
		marks = marks.map(mark => {
			if mark == ">" { (inherit: "triplehead", rev: false) }
			else if mark == "<" { (inherit: "triplehead", rev: true) }
			else {mark}
		})
	}

	return (
		marks: interpret-marks(marks),
		..LINE_ALIASES.at(lines.at(0))
	)
}



/// Interpret the positional arguments given to an `edge()`
///
/// Tries to intelligently distinguish the `from`, `to`, `marks`, and `label`
/// arguments based on the argument types.
///
/// Generally, the following combinations are allowed:
///
/// ```
/// edge(..<coords>, ..<marklabel>, ..<options>)
/// <coords> = () or (to) or (from, to) or (from, ..vertices, to)
/// <marklabel> = (marks, label) or (label, marks) or (marks) or (label) or ()
/// <options> = any number of options specified as strings
/// ```
#let interpret-edge-args(args, options) = {
	if args.named().len() > 0 {
		error("Unexpected named argument(s) #..0.", args.named().keys())
	}

	let new-options = (:)
	let pos = args.pos()

	// predicates to detect the kind of a positional argument
	let is-coord(arg) = type(arg) in (array, dictionary, label) or arg == auto
	let is-rel-coord(arg) = is-coord(arg) or (
		type(arg) == str and arg.match(regex("^[utdblrnsew,]+$")) != none
	)
	let is-arrow-symbol(arg) = type(arg) == symbol and str(arg) in MARK_SYMBOL_ALIASES
	let is-edge-flag(arg) = type(arg) == str and arg in EDGE_FLAGS
	let is-label-side(arg) = type(arg) == alignment

	let maybe-marks(arg) = type(arg) == str and not is-edge-flag(arg) or is-arrow-symbol(arg)
	let maybe-label(arg) = type(arg) != str and not is-arrow-symbol(arg) and not is-coord(arg)

	let peek(x, ..predicates) = {
		let preds = predicates.pos()
		x.len() >= preds.len() and x.zip(preds).all(((arg, pred)) => pred(arg))
	}

	let assert-not-set(key, default, ..value) = {
		if options.at(key) == default { return }
		error(
			"#0 specified twice with positional argument(s) #..pos and named argument #named.",
			key, pos: value.pos().map(repr), named: repr(options.at(key)),
		)
	}

	let coords = ()
	let has-first-coord = false
	let has-tail-coords = false

	// First argument(s) are coordinates
	// (<coord>, <rel-coord>*) => (<coord>, <rel-coord>*)
	// (<rel-coord>*) => (auto, <rel-coord>*)
	if peek(pos, is-coord) {
		coords.push(pos.remove(0))
		has-first-coord = true
	}
	while peek(pos, is-rel-coord) {
		if type(pos.at(0)) == str {
			coords += pos.remove(0).split(",")
		} else {
			coords.push(pos.remove(0))
		}
		has-tail-coords = true
	}

	// Allow marks argument to be in between two coordinates
	// (<coord>, <marks>, <rel-coord>)
	// (<marks>, <rel-coord>) => (auto, <marks>, <rel-coord>)
	if not has-tail-coords and peek(pos, maybe-marks, is-rel-coord) {
		new-options.marks = pos.remove(0)
		assert-not-set("marks", (), new-options.marks)

		coords.push(pos.remove(0))
		has-tail-coords = true

		if peek(pos, is-rel-coord) {
			error("Marks argument #0 must appear after edge vertices (or between them if there are only two).", repr(new-options.marks))
		}
	}
	if coords.len() > 0 or options.vertices.len() == 0 {
		assert-not-set("vertices", (), ..coords)
		if not has-tail-coords { coords = (auto, ..coords) }
		if not has-first-coord { coords = (auto, ..coords) }
		new-options.vertices = coords
	}


	// Allow label side argument anywhere after coordinates
	let i = pos.position(is-label-side)
	if i != none {
		new-options.label-side = pos.remove(i)
		assert-not-set("label-side", auto, new-options.label-side)
	}


	// Accept marks and labels after vertices
	// (.., <marks>, <label>)
	// (.., <label>, <marks>)
	let marks
	let label
	if peek(pos, maybe-marks, maybe-label) {
		marks = pos.remove(0)
		label = pos.remove(0)
	} else if peek(pos, maybe-label, maybe-marks) {
		label = pos.remove(0)
		marks = pos.remove(0)
	} else if peek(pos, maybe-label) {
		label = pos.remove(0)
	} else if peek(pos, maybe-marks) {
		marks = pos.remove(0)
	}

	if marks != none {
		if "marks" in new-options {
			error("Marks argument passed to `edge()` twice; found #0 and #1.", repr(new-options.marks), repr(marks))
		}
		assert-not-set("marks", (), marks)
		new-options.marks = marks
	}
	if label != none {
		assert-not-set("label", none, label)
		new-options.label = label
	}

	// Accept any trailing positional strings as option shorthands
	while peek(pos, is-edge-flag) {
		new-options += EDGE_FLAGS.at(pos.remove(0))
	}

	if pos.len() > 0 {
		error("Couldn't interpret `edge()` arguments #..0. Try using named arguments. Interpreted previous arguments as #1", pos, new-options)
	}

	new-options
}




// Convert to `(segment, pos)`, where `segment` is an `int` and `pos` is a
// `relative`. `pos` is relative to segment `segment`.
// 
// Possible inputs:
//   * `(segment, pos)`, where `segment` is an int and `pos` is accepted by
//     `as-relative`. `pos` will be interpreted as relative to segment
//     `segment`.
//   * `pos`, where `pos` is accepted by `as-relative`. `pos` will be
//     interpreted as relative to the whole edge.
#let normalize-label-pos(pos, n-segments) = {
	// panic(pos, n-segments)

	let segment
	let position
	
	if type(pos) == array and type(pos.at(0)) == int {
		// Segment specified
		segment = pos.at(0)
		position = as-relative(pos.at(1))

	} else {
		// No segment specified
		pos = as-relative(pos)
		pos = pos.ratio*n-segments + pos.length

		// Which segment does the position refer to?
		// Use ceil-1 instead of floor to put positions that fall on the boundary
		// between two segment on the end of the first, not the beginning of the
		// second. There's no particular reason to do it like this, other than
		// compatibility.
		segment = calc.ceil(float(pos.ratio)) - 1
		segment = calc.clamp(segment, 0, n-segments - 1)

		// Make the position relative to the selected segment. This applies only to
		// the `ratio` part of the `relative` position, not to the `length` part.
		position = (pos.ratio - 100% * segment) + pos.length
	}

	if segment < 0 or segment >= n-segments {
		error("segment of `label-pos` must be at least zero and less than number of segments (#1); got #0.", segment, n-segments)
	}

	(segment: segment, position: position)
}




/// Draw a connecting edge in a diagram.
///
///
/// - ..args (any): An edge's positional arguments may specify:
///   - the edge's #param[edge][vertices], each specified with a CeTZ-style coordinate
///   - the #param[edge][label] content
///   - arrow #param[edge][marks], like `"=>"` or `"<<-|-o"`
///   - other style flags, like `"double"` or `"wave"`
///
///   Vertex coordinates must come first, and are optional:
///
///   ```typc
///   edge(from, to, ..) // explicit start and end nodes
///   edge(to, ..) == edge(auto, to, ..) // start snaps to previous node
///   edge(..) == edge(auto, auto, ..) // snaps to previous and next nodes
///   edge(from, v1, v2, ..vs, to, ..) // a multi-segmented edge
///   edge(from, "->", to) // for two vertices, the marks style can come in between
///   ```
///
///   All vertices except the start point can be shorthand relative coordinate
///   string containing the characters
///   ${#"lrudtbnesw".clusters().map(raw).join($, $)}$ or commas.
///
///   If given as positional arguments, an edge's #param[edge][marks] and
///   #param[edge][label] are disambiguated by guessing based on the types. For
///   example, the following are equivalent:
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
///   #fletcher.EDGE_FLAGS.keys().map(repr).map(raw).join([, ], last: [, and ]).
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
/// - loop-angle (angle): Angle around the node at which edge loops stick out at. Loops are arcs
///   with the same start/end point and a large #param[edge][bend] angle (e.g.,
///   `120deg`). This value has no effect for non-loop edges.
///
///   #diagram(debug: 0, {
///   	node((0,0), $O$)
///   	for θ in (0deg, -90deg, 135deg) {
///   		edge((), "->", (), bend: 125deg, loop-angle: θ, label: θ)
///   	}
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
/// - label-pos (float, ratio, relative length, array): Position of the label along the
///   edge, from the start to end.
///
///   A number or ratio between zero and one is interpreted as a fraction of the
///   edge length. Physical and relative relative lengths work too. For example,
///   `100% - 1em` means `1em` from the end.
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
///   For `"poly"` edges (see @edge-types), a number does not specify a fraction
///   of the path length; instead, the $k$th vertex is at position $k/n$ where
///   $n$ is the number of vertices. Each midpoint is then at $k/n + 0.5$.
/// 
///   As an alternative, the position can be specified by an array
///   `(segment, position)`, where `segment` is an integer that indicates which
///   segment the label is placed on (segment $s$ is the one between vertices
///   $s$ and $s+1$). `position` is then relative to the specified segment; the
///   segment midpoint is at `(s, 50%)`.
///
/// - label-sep (length): Separation between the connector and the label anchor.
///
///   With the default anchor (automatically set to `"south"` in this case):
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
///   Default: #the-param[diagram][label-sep]
///
/// - label-angle (angle, left, right, top, bottom, auto): Angle to rotate the
///   label (counterclockwise).
///
///   If a direction is given, the label is rotated so that the edge travels in
///   that direction relative to the label. If `auto`, the best of `right` or
///   `left` is chosen.
///
///   #for angle in (0deg, 90deg, auto, right, top, left) {
///   	diagram(edge((0,1), (2,0), "->", [#angle], label-angle: angle))
///   }
///
/// - label-anchor (anchor): The CeTZ-style anchor point of the label to use for
///   placement (e.g., `"north-east"` or `"center"`). If `auto`, the best anchor
///   is chosen based on #param[edge][label-side], #param[edge][label-angle],
///   and the edge's direction.
///
/// - label-fill (bool, paint): The background fill for the label. If `true`,
///   defaults to the value of #param[edge][crossing-fill]. If `false` or
///   `none`, no fill is used. If `auto`, then defaults to `true` if the label
///   is covering the edge (#param[edge][label-side]`: center`).
///
/// - label-size (auto, length): The default text size to apply to edge labels.
///
///   Default: #the-param[diagram][label-size]
///
/// - label-wrapper (auto, function): Callback function accepting a node
///   dictionary and returning the label content. This is used to add a label
///   background (see #param[edge][crossing-fill]), and can be used to adjust
///   the label's padding, outline, and so on.
///
///   ```example
///   #diagram(edge($f$, label-wrapper: e =>
///   	circle(e.label, fill: e.label-fill)))
///   ```
///
///   Default: #the-param[diagram][label-wrapper]
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
///   ```example
///   #diagram(
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
///   ```
///
/// - marks (array): The marks (arrowheads) to draw along an edge's stroke. This
///   may be:
///
///   - A shorthand string such as `"->"` or `"hook'-/->>"`. Specifically,
///     shorthand strings are of the form $M_1 L M_2$ or $M_1 L M_2 L M_3$, etc,
///     where
///
///     $ M_i in #`fletcher.MARKS` = #context math.mat(..fletcher.MARKS.get().keys().map(i => $#raw(lang: none, i),$).chunks(6), delim: "{") $
///     is a mark name and
///     $ L in #`fletcher.LINE_ALIASES` = {#fletcher.LINE_ALIASES.keys().map(raw.with(lang: none)).join($,$)} $
///     is the line style.
///
///   - An array of mark names as strings or _mark objects_ (dictionaries of
///     parameters with a `draw` entry).
///
///   Shorthands are expanded into other arguments. For example,
///   `edge(p1, p2, "=>")` is short for `edge(p1, p2, marks: (none, "head"), "double")`, or more precisely, the result of `edge(p1, p2, ..fletcher.interpret-marks-arg("=>"))`.
///
///   #table(
///   	columns: (1fr, 4fr),
///   	align: (center + horizon, horizon),
///   	[Result], [Value of `marks`],
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
///         ("X", (inherit: "head", size: 15, sharpness: 40deg),), ((inherit:
///         "circle", pos: 0.5, fill: auto),),
///   	).map(arg => (
///   		fletcher.diagram(edge((0,0), (1,0), marks: arg, stroke: 0.8pt)),
///   		raw(repr(arg)),
///   	)).join()
///   )
///
/// - mark-scale (percent): Scale factor for marks or arrowheads, relative to
///   the #param[edge][stroke] thickness. See also #the-param[diagram][mark-scale].
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
///   mark. This offset is computed with `cap-offset()`.
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
///   normal stroke's thickness.
///
///   #diagram({
///   	(1, 2, 4, 8).enumerate().map(((i, x)) => {
///   		edge((2*i, 1), (2*i + 1, 0), stroke: 1pt, label-sep: 1em)
///   		edge((2*i, 0), (2*i + 1, 1), raw(str(x)), stroke: 1pt, label-sep:
///   		2pt, label-pos: 0.3, crossing: true, crossing-thickness: x)
///   	}).join()
///   })
///
///   Default: #the-param[diagram][crossing-thickness]
///
/// - crossing-fill (paint): Color to use behind connectors or labels to give
///   the illusion of crossing over other objects.
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
///   Default: #the-param[diagram][crossing-fill]
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
///   Default: #the-param[diagram][edge-corner-radius]
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
///   ```example
///   #diagram(
///   	node-fill: luma(70%),
///   	node((0,0), [Hello]),
///   	edge("u,r,d", "->"),
///   	edge("u,r,d", "-->", shift: 8pt),
///   	node((1,0), [World]),
///   )
///   ```
///
/// - snap-to (pair): The nodes the start and end of an edge should snap to.
/// Each node can be a position or node #param[node][name], or `none` to disable
/// snapping. See also #the-param[node][snap].
///
///   By default, an edge's first and last #param[edge][vertices] snap to nearby
///   nodes. This option can be used in case automatic snapping fails (if there
///   are many nodes close together, for example.)
///
/// - layer (number): Layer on which to draw the edge.
///
///   Objects on a higher `layer` are drawn on top of objects on a lower
///   `layer`. Objects on the same layer are drawn in the order they are passed
///   to `diagram()`.
///
/// - floating (bool): Whether the edge should be _floating_ so as not to affect
///   the diagram's bounding box.
/// 
///   When `floating: true`, the edge is wrapped in `cetz.draw.floating(..)` which
///   prevents the objects from affecting the canvas' bounding box.
/// 
///   ```example
///   An inline #diagram($
/// 		A edge(->, bend: #45deg, floating: #true) & B
/// 	$) diagram.
/// 
/// 	#rect(width: 7cm, align(center, diagram(
/// 		node((0,1), $A$),
/// 		edge("->", floating: true, [centered despite label]),
/// 		node((0,0), $B$),
/// 	)))
///   ```
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
	label: none,
	label-side: auto,
	label-pos: 50%,
	label-sep: auto,
	label-angle: 0deg,
	label-anchor: auto,
	label-fill: auto,
	label-size: auto,
	label-wrapper: auto,
	stroke: auto,
	dash: none,
	decorations: none,
	extrude: (0,),
	shift: 0pt,
	kind: auto,
	bend: 0deg,
	loop-angle: none,
	corner: none,
	corner-radius: auto,
	marks: (),
	mark-scale: 100%,
	crossing: false,
	crossing-thickness: auto,
	crossing-fill: auto,
	snap-to: (auto, auto),
	layer: 0,
	floating: false,
	post: x => x,
) = {

	let options = (
		vertices: vertices,
		label: label,
		label-pos: label-pos,
		label-sep: label-sep,
		label-angle: label-angle,
		label-anchor: label-anchor,
		label-side: label-side,
		label-fill: label-fill,
		label-size: label-size,
		label-wrapper: label-wrapper,
		stroke: stroke,
		dash: dash,
		decorations: decorations,
		kind: kind,
		bend: bend,
		loop-angle: pass-none(as-angle)(loop-angle),
		corner: corner,
		corner-radius: corner-radius,
		extrude: extrude,
		shift: shift,
		marks: marks,
		mark-scale: mark-scale,
		crossing: crossing,
		crossing-thickness: crossing-thickness,
		crossing-fill: crossing-fill,
		snap-to: as-pair(snap-to),
		layer: layer,
		post: post,
		floating: as-bool(floating, message: "`floating` must be boolean"),
	)

	options += interpret-edge-args(args, options)

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

	// guess the number of segments
	let n-segments = options.vertices.len() - 1
	if options.corner != none { n-segments += 1 }
	options.label-pos = normalize-label-pos(options.label-pos, n-segments)


	if options.label-side not in (left, center, right, auto) {
		error("`label-side` must be one of `left`, `center`, `right`, or `auto`; got #0.", options.label-side)
	}
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
	// let to-pt(len) = to-abs-length(len, options.em-size)

	edge += interpret-marks-arg(edge.marks)

	if edge.stroke == none {
		// hack: for no stroke, it's easier to do the following.
		// then we have the guarantee that edge.stroke is actually
		// a stroke, not possibly none
		edge.extrude = ()
		edge.marks = ()
		edge.stroke = stroke((:))
	}

	edge.stroke = (
		(
			cap: "round",
			dash: edge.dash,
			thickness: 0.048em, // guarantees thickness is a length, not auto
		) +
		stroke-to-dict(options.edge-stroke) +
		stroke-to-dict(map-auto(edge.stroke, (:)))
	)
	edge.stroke.thickness = edge.stroke.thickness.to-absolute()

	edge.extrude = as-array(edge.extrude).map(as-number-or-length.with(
		message: "`extrude` must be a number, length, or an array of those"
	)).map(d => {
		if type(d) == length { d.to-absolute() }
		else { d*edge.stroke.thickness }
	})

	if type(edge.decorations) == str {
		edge.decorations = (
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
		).at(edge.decorations)
	}

	edge.crossing-fill = map-auto(edge.crossing-fill, options.crossing-fill)
	edge.crossing-thickness = map-auto(edge.crossing-thickness, options.crossing-thickness)
	edge.corner-radius = map-auto(edge.corner-radius, options.edge-corner-radius)

	if edge.is-crossing-background {
		edge.stroke = (
			thickness: edge.crossing-thickness*edge.stroke.thickness,
			paint: edge.crossing-fill,
			cap: "round",
		)
		edge.marks = ()
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
	edge.marks = edge.marks.map(mark => {
		mark.scale *= edge.mark-scale
		mark
	})

	edge.label-sep = map-auto(edge.label-sep, options.label-sep).to-absolute()
	edge.label-size = map-auto(edge.label-size, options.label-size)

	edge.label-fill = map-auto(edge.label-fill, edge.label-side == center)
	if edge.label-fill == true { edge.label-fill = edge.crossing-fill }
	if edge.label-fill == false { edge.label-fill = none }

	edge.label-wrapper = map-auto(edge.label-wrapper, options.label-wrapper)

	if edge.floating {
		edge.post = x => cetz.draw.floating((edge.post)(x))
	}

	edge
}


#let resolve-edge-vertices(edge, ctx: (:), nodes) = {

	let adjacent-node-pos(forward, default) = {
		if edge.node-index == none { return default }
		let indices = if forward {
			range(edge.node-index, nodes.len())
		} else {
			range(0, edge.node-index).rev()
		}
		for i in indices {
			if nodes.at(i).snap != false {
				return nodes.at(i).pos.at(ctx.target-system)
			}
		}
		return default
	}

	let prev-pos = adjacent-node-pos(false, (0, 0))
	let next-pos = adjacent-node-pos(true, (rel: (1, 0)))

	let ctx = default-ctx + ctx + (
		prev: (pt: prev-pos),
	)

	edge.vertices.at(0) = map-auto(edge.vertices.at(0), prev-pos)
	edge.vertices.at(-1) = map-auto(edge.vertices.at(-1), next-pos)

	let (ctx, ..verts) = resolve(ctx, ..edge.vertices)
	verts.map(vector-2d)

}



#let convert-edge-corner-to-poly(edge) = {
	if edge.kind != "corner" { return edge }

	let (from, to) = edge.final-vertices
	let θ = angle-between(from, to)

	let bend-dir = (
		if edge.corner == right { true }
		else if edge.corner == left { false }
		else { error("Edge `corner` option must be `left` or `right`.") }
	)

	let θ-floor = calc.floor(θ/90deg)*90deg
	let θ-ceil = calc.ceil(θ/90deg)*90deg
	let θs = if bend-dir {
		(θ-ceil, θ-floor + 180deg)
	} else {
		(θ-floor, θ-ceil + 180deg)
	}

	let corner-point = if calc.even(calc.floor(θ/90deg) + int(bend-dir)) {
		(to.at(0), from.at(1))
	} else {
		(from.at(0), to.at(1))
	}

	let label-side = map-auto(edge.label-side, if bend-dir { left } else { right })

	edge + (
		kind: "poly",
		final-vertices: (from, corner-point, to),
		label-side: label-side,
	)
}




// For straight edges, `shift` translates the line laterally
#let apply-edge-shift-line(grid, edge) = {
	let (from-xy, to-xy) = edge.final-vertices
	let θ = angle-between(from-xy, to-xy) + 90deg

	let (δ-from, δ-to) = edge.shift
	let δ⃗-from = vector-polar-with-xy-or-uv-length(grid, from-xy, δ-from, θ)
	let δ⃗-to = vector-polar-with-xy-or-uv-length(grid, to-xy, δ-to, θ)

	edge.final-vertices.at( 0) = vector.add(from-xy, δ⃗-from)
	edge.final-vertices.at(-1) = vector.add(to-xy, δ⃗-to)

	edge
}

// For arc edges, `shift` grows/shrinks the arc concentrically
#let apply-edge-shift-arc(grid, edge) = {
	let (from-xy, to-xy) = edge.final-vertices

	let θ = angle-between(from-xy, to-xy) + 90deg
	let (θ-from, θ-to) = (θ + edge.bend, θ - edge.bend)

	let (δ-from, δ-to) = edge.shift
	let δ⃗-from = vector-polar-with-xy-or-uv-length(grid, from-xy, δ-from, θ-from)
	let δ⃗-to   = vector-polar-with-xy-or-uv-length(grid, to-xy, δ-to, θ-to)

	edge.final-vertices.at( 0) = vector.add(from-xy, δ⃗-from)
	edge.final-vertices.at(-1) = vector.add(to-xy, δ⃗-to)

	if edge.loop-angle != none {
		let a = edge.loop-angle + 90deg
		edge.final-vertices.at( 0) = vector.add(edge.final-vertices.at( 0), vector-polar(+1e-4pt, a))
		edge.final-vertices.at(-1) = vector.add(edge.final-vertices.at(-1), vector-polar(-1e-4pt, a))
	}

	edge
}

// For poly edges, `shift` affects the first/last line segments
#let apply-edge-shift-poly(grid, edge) = {
	let end-segments = (
		edge.final-vertices.slice(0, 2), // first two vertices
		edge.final-vertices.slice(-2), // last two vertices
	)

	let θs = (
		angle-between(..end-segments.at(0)) + 180deg,
		angle-between(..end-segments.at(1)) + 180deg,
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
/// - grid (dictionary): Representation of the grid layout. This is needed to
///   support shifts specified as coordinate lengths.
/// - edge (dictionary): The edge with a `shift` entry.
#let apply-edge-shift(grid, edge) = {
	if edge.kind == "line" { apply-edge-shift-line(grid, edge) }
	else if edge.kind == "arc" { apply-edge-shift-arc(grid, edge) }
	else if edge.kind == "poly" { apply-edge-shift-poly(grid, edge) }
	else { edge }
}

