#import "@preview/cetz:0.1.2"
#import "utils.typ": *
#import calc: sqrt, abs, sin, cos, max, pow


#let EDGE_ARGUMENT_SHORTHANDS = (
	"dashed": (dash: "dashed"),
	"dotted": (dash: "dotted"),
	"double": (extrude: (-2, +2)),
	"triple": (extrude: (-4, 0, +4)),
	"crossing": (crossing: true),
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
)

#let MARK_DEFAULTS = (
	head: (
		size: 7, // radius of curvature, multiples of stroke thickness
		sharpness: 24deg, // angle at vertex between central line and arrow's edge
		delta: 54deg, // angle spanned by arc of curved arrow edge
		outer-len: 4,
	),
	solid: (
		size: 10,
		sharpness: 19deg,
		fill: true,
		stealth: 0,
		outer-len: mark => mark.size*calc.cos(mark.sharpness)*(1 - mark.stealth),
		inner-len: mark => mark.outer-len/2,
	),

	bar: (size: 4.9, angle: 0deg),
	circle: (size: 2, fill: false, outer-len: mark => 2*mark.size),
	cross: (size: 4, angle: 45deg),

	hook: (size: 2.88, rim: 0.85, outer-len: 3),
	
)
#{MARK_DEFAULTS.harpoon = MARK_DEFAULTS.head}


#let MARK_ALIASES = (
	">": (kind: "head", rev: false),
	"<": (kind: "head", rev: true),
	">>": (kind: "head", rev: false, extrude: (-3, 0), inner-len: 3, outer-len: 7),
	"<<": (kind: "head", rev: true,  extrude: (-3, 0), inner-len: 3, outer-len: 7),
	">>>": (kind: "head", rev: false, extrude: (-6, -3, 0), inner-len: 6, outer-len: 9),
	"<<<": (kind: "head", rev: true,  extrude: (-6, -3, 0), inner-len: 6, outer-len: 9),
	"|>": (kind: "solid", rev: false),
	"<|": (kind: "solid", rev: true),
	"|": (kind: "bar"),
	"||": (kind: "bar", extrude: (-3, 0), inner-len: 3),
	"|||": (kind: "bar", extrude: (-6, -3, 0), inner-len: 4),
	"/": (kind: "bar", angle: -30deg),
	"\\": (kind: "bar", angle: +30deg),
	"x": (kind: "cross"),
	"X": (kind: "cross", size: 7),
	"o": (kind: "circle"),
	"O": (kind: "circle", size: 4),
	"*": (kind: "circle", fill: true),
	"@": (kind: "circle", size: 4, fill: true),
	"}>": (kind: "solid", stealth: 0.25, rev: false),
	"<{": (kind: "solid", stealth: 0.25, rev: true),

	doublehead: (
		kind: "head",
		size: 9.6*1.1,
		sharpness: 19deg,
		delta: 43.7deg,
		outer-len: 5.5,
	),
	triplehead: (
		kind: "head",
		size: 9*1.5,
		sharpness: 25deg,
		delta: 43deg,
		outer-len: 6,
	),

	"hook'": (kind: "hook", flip: -1),
	"harpoon'": (kind: "harpoon", flip: -1),
	hooks: (kind: "hook", double: true),

)


/// Calculate cap offset of round-style arrow cap,
/// $r (sin θ - sqrt(1 - (cos θ - (|y|)/r)^2))$.
///
/// - r (length): Radius of curvature of arrow cap.
/// - θ (angle): Angle made at the the arrow's vertex, from the central stroke
///  line to the arrow's edge.
/// - y (length): Lateral offset from the central stroke line.
#let round-arrow-cap-offset(r, θ, y) = {
	r*(sin(θ) - sqrt(1 - pow(cos(θ) - abs(y)/r, 2)))
}

#let cap-offset(mark, y) = {
	if mark == none { return 0 }

	if mark.kind == "head" {
		round-arrow-cap-offset(mark.size, mark.sharpness, y)
	}
	else if mark.kind in ("hook", "hook'", "hooks") { -mark.outer-len }
	else if mark.kind == "circle" {
		let r = mark.size
		-sqrt(max(0, r*r - y*y)) - r
	} else if mark.kind == "solid" {
	-mark.outer-len/4

	} else if mark.kind == "bar" {
		 -calc.tan(mark.angle)*y
	} else { 0 }
}


#let LINE_ALIASES = (
	"-": (:),
	"=": EDGE_ARGUMENT_SHORTHANDS.double,
	"==": EDGE_ARGUMENT_SHORTHANDS.triple,
	"--": EDGE_ARGUMENT_SHORTHANDS.dashed,
	"..": EDGE_ARGUMENT_SHORTHANDS.dotted,
)



/// Take a string or dictionary specifying a mark and return a dictionary,
/// adding defaults for any necessary missing parameters.
///
/// Ensures all required parameters except `rev` and `pos` are present.
#let interpret-mark(mark, defaults: (:)) = {
	if mark == none { return none }

	if type(mark) == str { mark = (kind: mark) }

	mark = defaults + mark
	
	if mark.kind.at(-1) == "'" {
		mark.flip = -mark.at("flip", default: +1)
		mark.kind = mark.kind.slice(0, -1)
	}

	if mark.kind in MARK_ALIASES {
		let new = MARK_ALIASES.at(mark.kind)
		mark = new + mark
		mark.kind = new.kind
	}

	if mark.kind in MARK_DEFAULTS {
		mark = MARK_DEFAULTS.at(mark.kind) + mark
	} else {
		panic("Couldn't interpret mark:", mark)
	}

	// evaluate "lazy parameters" which are functions of the mark
	for (key, val) in mark {
		if type(val) == function {
			mark.at(key) = val(mark)
		}
	}

	assert(mark.kind in MARK_DEFAULTS, message: "Didn't work: " + repr(mark))

	return mark
}


#let interpret-marks(marks) = {

	marks = marks.enumerate().map(((i, mark)) => {
		interpret-mark(mark, defaults: (
			pos: i/calc.max(1, marks.len() - 1),
			rev: i == 0,
		))
	}).filter(mark => mark != none) // drop empty marks

	assert(type(marks) == array)
	assert(marks.all(mark => type(mark) == dictionary), message: repr(marks))
	marks
}

/// Parse and interpret the marks argument provided to `edge()`.
/// Returns a dictionary of processed `edge()` arguments.
///
/// - arg (string, array):
/// Can be a string, (e.g. `"->"`, `"<=>"`), etc, or an array of marks.
/// A mark can be a string (e.g., `">"` or `"head"`, `"x"` or `"cross"`) or a dictionary containing the keys:
///   - `kind` (required) the mark name, e.g. `"solid"` or `"bar"`
///   - `pos` the position along the edge to place the mark, from 0 to 1
///   - `rev` whether to reverse the direction
///   - `tail` the visual length of the mark's tail
///   - parameters specific to the kind of mark, e.g., `size` or `sharpness`
/// -> dictiony
#let interpret-marks-arg(arg) = {
	if type(arg) == array { return (marks: interpret-marks(arg)) }

	if type(arg) == symbol {
		if str(arg) in MARK_SYMBOL_ALIASES { arg = MARK_SYMBOL_ALIASES.at(arg) }
		else { panic("Unrecognised marks symbol '" + arg + "'.") }
	}

	assert(type(arg) == str)
	let text = arg

	let MARKS = (MARK_ALIASES.keys() + MARK_DEFAULTS.keys()).sorted(key: i => -i.len())
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

	// first mark, [<]-x->>
	(text, mark) = eat(text, MARKS)
	marks.push(mark)

	let parse-error(suggestion) = panic(
		"Invalid marks shorthand '" + arg + "'. Try '" + suggestion + "'."
	)

	while true {
		// line, <[-]x->>
		(text, line) = eat(text, LINES)
		if line == none {
			let suggestion = arg.slice(0, -text.len()) + "-" + text
			parse-error(suggestion)
		}
		lines.push(line)

		// subsequent mark, <-[x]->>
		(text, mark) = eat(text, MARKS)
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



	marks = marks.map(interpret-mark)

	// make classic math arrows slightly larger on double/triple stroked lines
	if line == "=" {
		marks = marks.map(mark => {
			if mark != none and mark.kind == "head" {
				mark += MARK_ALIASES.doublehead
			}
			mark
		})
	} else if line == "==" {
		marks = marks.map(mark => {
			if mark != none and mark.kind == "head" {
				mark += MARK_ALIASES.triplehead
			}
			mark
		})
	}

	return (
		marks: interpret-marks(marks),
		..LINE_ALIASES.at(lines.at(0))
	)
}




#let draw-arrow-cap(p, θ, stroke, mark, debug: false) = {
	mark = interpret-mark(mark)

	let inner-len = stroke.thickness*mark.at("inner-len", default: 0)
	let outer-len = stroke.thickness*mark.at("outer-len", default: 0)

	if mark.at("rev", default: false) {
		θ += 180deg
		mark.rev = false
	}

	mark.flip = mark.at("flip", default: +1)

	if debug {
		let dir = if mark.rev {1} else {-1}
		let normal = vector-polar(stroke.thickness, θ - 90deg)
		cetz.draw.on-layer(1, (
			cetz.draw.circle(
				p,
				radius: stroke.thickness,
				stroke: none,
				fill: rgb("0f0a"),
			),
			cetz.draw.line(
				vector.add(p, vector-polar(-stroke.thickness*mark.at("body", default: 0), θ)),
				vector.add(p, vector-polar(outer-len*dir, θ)),
				stroke: rgb("0f0a") + stroke.thickness,
			),
			cetz.draw.line(
				vector.add(p, vector-polar(-stroke.thickness*mark.at("body", default: 0), θ)),
				vector.add(p, vector-polar(inner-len*dir, θ)),
				stroke: rgb("0f0a") + stroke.thickness*2,
			),
		).join())
	}

	let shift(p, x) = vector.add(p, vector-polar(stroke.thickness*x, θ))

	// extrude draws multiple copies of the mark
	// at shifted positions
	if "extrude" in mark {
		for x in mark.extrude {
			let mark = mark
			let _ = mark.remove("extrude")
			draw-arrow-cap(shift(p, x), θ, stroke, mark)
		}
		return
	}

	let stroke = (
		thickness: if "thickness" in mark { mark.thickness} else { stroke.thickness },
		paint: if "paint" in mark { mark.paint } else { stroke.paint },
		cap: "round",
	)


	if mark.kind == "harpoon" {
		cetz.draw.arc(
			p,
			radius: mark.size*stroke.thickness,
			start: θ + mark.flip*(90deg + mark.sharpness),
			delta: mark.flip*mark.delta,
			stroke: stroke,
		)

	} else if mark.kind == "head" {
		draw-arrow-cap(p, θ, stroke, mark + (kind: "harpoon"))
		draw-arrow-cap(p, θ, stroke, mark + (kind: "harpoon'"))

	} else if mark.kind == "hook" {
		if mark.at("double", default: false) {
			draw-arrow-cap(p, θ, stroke, mark + (double: false, flip: -1))
		}

		p = shift(p, -mark.outer-len)
		cetz.draw.arc(
			p,
			radius: mark.size*stroke.thickness,
			start: θ + mark.flip*90deg,
			delta: -mark.flip*180deg,
			stroke: stroke,
		)
		let q = vector.add(p, vector-polar(2*mark.size*stroke.thickness, θ - mark.flip*90deg))
		let rim = vector-polar(-mark.rim*stroke.thickness, θ)
		cetz.draw.line(
			q,
			(rel: rim, to: q),
			stroke: stroke
		)


	} else if mark.kind == "bar" {
		let v = vector-polar(mark.size*stroke.thickness, θ + 90deg + mark.angle)
		cetz.draw.line(
			(to: p, rel: v),
			(to: p, rel: vector.scale(v, -1)),
			stroke: stroke,
		)

	} else if mark.kind == "cross" {
		draw-arrow-cap(p, θ, stroke, mark + (kind: "bar", angle: +mark.angle))
		draw-arrow-cap(p, θ, stroke, mark + (kind: "bar", angle: -mark.angle))

	} else if mark.kind == "circle" {
		p = shift(p, -mark.size)
		cetz.draw.circle(
			p,
			radius: mark.size*stroke.thickness,
			stroke: stroke,
			fill: if mark.fill { default(stroke.paint, black) }
		)

	} else if mark.kind == "solid" {
		let d = mark.size*stroke.thickness
		cetz.draw.line(
			(to: p, rel: vector-polar(-d, θ + mark.sharpness)),
			p,
			(to: p, rel: vector-polar(-d, θ - mark.sharpness)),
			(to: p, rel: vector-polar(-d*calc.cos(mark.sharpness)*(1 - mark.stealth), θ)),
			fill: if mark.fill { default(stroke.paint, black) },
			close: true,
			stroke: if not mark.fill { stroke }
		)

	} else {
		panic("unknown mark kind:", mark)
	}
}


#let place-arrow-cap(path, stroke, mark, ..args) = {
	let ε = 1e-4

	// calculate velocity of parametrised path at point
	let pt = path(mark.pos)
	let pt-plus-ε = path(mark.pos + ε)
	let grad = vector-len(vector.sub(pt-plus-ε, pt))/ε
	if grad == 0pt { grad = ε*1pt }

	let outer-len = mark.at("outer-len", default: 0)
	let Δt = outer-len*stroke.thickness/grad
	if Δt == 0 { Δt = ε } // avoid Δt = 0 so the two points are distinct

	let t = lerp(Δt, 1, mark.pos)
	let head-pt = path(t)
	let tail-pt = path(t - Δt)

	let origin-pt = if mark.rev { tail-pt } else { head-pt }
	let θ = vector-angle(vector.sub(head-pt, tail-pt))

	draw-arrow-cap(origin-pt, θ, stroke, mark, ..args)
}