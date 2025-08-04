#import "default-marks.typ": MARKS, DEFAULT_MARKS
#import "utils.typ"


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
#let parse-mark-shorthand(text) = {
	if type(text) == symbol {
		if str(text) in MARK_SYMBOL_ALIASES { text = MARK_SYMBOL_ALIASES.at(text) }
		else { utils.error("Unrecognised marks symbol #0.", text) }
	}

	assert(type(text) == str)

	// let mark-names = MARKS.get().keys().sorted(key: i => -i.len())
	let mark-names = DEFAULT_MARKS.keys().sorted(key: i => -i.len())
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

	let parse-error(suggestion) = utils.error("Invalid marks shorthand #0. Try #1.", arg, suggestion)

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
		marks: marks,
		options: LINE_ALIASES.at(lines.at(0))
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
		utils.error("Unexpected named argument(s) #..0.", args.named().keys())
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
		if key not in options { return }
		if options.at(key) == default { return }
		utils.error(
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
			utils.error("Marks argument #0 must appear after edge vertices (or between them if there are only two).", repr(new-options.marks))
		}
	}
	if coords.len() > 0 {
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
			utils.error("Marks argument passed to `edge()` twice; found #0 and #1.", repr(new-options.marks), repr(marks))
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
		utils.error("Couldn't interpret `edge()` arguments #..0. Try using named arguments. Interpreted previous arguments as #1", pos, new-options)
	}

	new-options
}