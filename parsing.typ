#import "default-marks.typ": MARKS

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
		else { error("Unrecognised marks symbol #0.", text) }
	}

	assert(type(text) == str)

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
		marks: marks,
		..LINE_ALIASES.at(lines.at(0))
	)
}
