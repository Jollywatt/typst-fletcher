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

#let CAP_ALIASES = (
	">": (kind: "head", rev: false),
	">>": (kind: "twohead", rev: false),
	"<": (kind: "head", rev: true),
	"<<": (kind: "twohead", rev: true),
	"|>": (kind: "solidhead", rev: false),
	"<|": (kind: "solidhead", rev: true),
	"|": (kind: "bar"),
	"||": (kind: "twobar"),
	"/": (kind: "bar", angle: -30deg),
	"\\": (kind: "bar", angle: +30deg),
	"x": (kind: "cross"),
	"X": (kind: "cross", size: 7),
	"o": (kind: "circle"),
	"O": (kind: "bigcircle"),
	"*": (kind: "circle", fill: true),
	"@": (kind: "bigcircle", fill: true),
)




/// Take a string or dictionary specifying a mark and return a dictionary,
/// adding defaults for any necessary missing parameters.
///
/// Ensures all required parameters except `rev` and `pos` are present.
#let interpret-mark(mark, defaults: (:)) = {
	if mark == none { return none }

	if type(mark) == str {
		mark = CAP_ALIASES.at(mark, default: (kind: mark))
	}

	assert(type(mark) == dictionary, message: repr(mark))
	
	if mark.kind.at(-1) == "'" {
		mark.flip = -mark.at("flip", default: +1)
		mark.kind = mark.kind.slice(0, -1)
	}

	let round-style = (
		size: 7, // radius of curvature, multiples of stroke thickness
		sharpness: 24deg, // angle at vertex between central line and arrow's edge
		delta: 54deg, // angle spanned by arc of curved arrow edge
	)

	mark = defaults + mark

	if mark.kind in ("head", "harpoon") {
		round-style + (tail: 4) + mark
	} else if mark.kind == "tail" {
		interpret-mark(mark + (kind: "head", rev: true))
	} else if mark.kind == "twohead" {
		round-style + (extrude: (-3, 0), tail: 6, cap-offset: -3) + mark + (kind: "head")
	} else if mark.kind == "twotail" {
		interpret-mark(mark + (kind: "twohead", rev: true))
	} else if mark.kind == "twobar" {
		(size: 4.5) + (extrude: (-3, 0), tail: 3) + mark + (kind: "bar")
	} else if mark.kind == "doublehead" {
		// tuned to match sym.arrow.double
		mark + (
			size: 9.6*1.1,
			sharpness: 19deg,
			delta: 43.7deg,
			tail: 4.5,
		) + (kind: "head")
	} else if mark.kind == "triplehead" {
		// tuned to match sym.arrow.triple
		mark + (
			size: 9*1.5,
			sharpness: 25deg,
			delta: 43deg,
			tail: 5,
		) + (kind: "head")
	} else if mark.kind == "bar" {
		(size: 4.9, angle: 0deg) + mark
	} else if mark.kind == "cross" {
		(size: 4, angle: 45deg) + mark
	} else if mark.kind in ("hook", "hooks") {
		(size: 2.88, rim: 0.85, tail: 3) + mark
	} else if mark.kind == "circle" {
		(size: 2, fill: false, tail: 4) + mark
	} else if mark.kind == "bigcircle" {
		(size: 4, tail: 8) + mark + (kind: "circle")
	} else if mark.kind == "solidhead" {
		(size: 10, sharpness: 19deg, tail: 9) + mark
	} else if mark.kind == "solidtail" {
		interpret-mark(mark + (kind: "solidhead", rev: true))
	} else {
		panic("Cannot interpret mark: " + mark.kind)
	}
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
///   - `kind` (required) the mark name, e.g. `"solidhead"` or `"bar"`
///   - `pos` the position along the edge to place the mark, from 0 to 1
///   - `rev` whether to reverse the direction
///   - `tail` the visual length of the mark's tail
///   - parameters specific to the kind of mark, e.g., `size` or `sharpness`
/// -> dictiony
#let interpret-marks-arg(arg) = {
	if type(arg) == array { return (marks: interpret-marks(arg)) }

	assert(type(arg) == str)
	let text = arg

	let lines = (
		"-": (:),
		"=": EDGE_ARGUMENT_SHORTHANDS.double,
		"==": EDGE_ARGUMENT_SHORTHANDS.triple,
		"--": EDGE_ARGUMENT_SHORTHANDS.dashed,
		"..": EDGE_ARGUMENT_SHORTHANDS.dotted,
	)

	let cap-selector = "(|<|>|<<|>>|hook[s']?|harpoon'?|\|\|?|/|\\\\|x|X|o|O|\*|@|<\||\|>)"
	let line-selector = "(--?|==?|--|::|\.\.)" // must match longest first
	let match = text.match(regex(
		"^" +
		cap-selector +
		line-selector +
		"(" +
		cap-selector +
		line-selector +
		")?" +
		cap-selector +
		"$"
	))


	if match == none {
		panic("Failed to parse " + text + " as edge style.")
	}
	let (from, line, _, mid, line2, to) = match.captures
	if line2 != none and line2 != line {
		let valid = from + line + mid + line + to
		panic("Failed to parse " + text + " as edge style; try " + valid)
	}

	let marks = (from, mid, to).map(mark => {
		if mark in ("", none) { none }
		else { CAP_ALIASES.at(mark, default: (kind: mark)) }
	})

	if marks.at(0) != none and "rev" not in marks.at(0) { marks.at(0).rev = true }

	if line == "=" {
		// make arrows slightly larger, suited for double stroked line
		marks = marks.map(mark => {
			if mark != none and mark.kind == "head" { mark.kind = "doublehead" }
			mark
		})
	} else if line == "==" {
		marks = marks.map(mark => {
			if mark != none and mark.kind == "head" { mark.kind = "triplehead" }
			mark
		})
	}


	(
		marks: interpret-marks(marks),
		..lines.at(line),
	)
}



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
	mark = interpret-mark(mark)
	if mark == none { return 0 }

	let offset() = round-arrow-cap-offset(mark.size, mark.sharpness, y)

	offset = if mark.kind == "head" { offset() }
	else if mark.kind in ("hook", "hook'", "hooks") { -mark.tail }
	else if mark.kind == "circle" {
		let r = mark.size
		-sqrt(max(0, r*r - y*y)) - r
	} else if mark.kind == "solidhead" {
		1 - mark.size*cos(mark.sharpness)
	} else if mark.kind == "bar" {
		 -calc.tan(mark.angle)*y
	} else { 0 }

	if mark.rev and "tail" in mark {
		offset = -offset - mark.tail
	}

	offset + mark.at("cap-offset", default: 0)
}


#let draw-arrow-cap(p, θ, stroke, mark, debug: false) = {
	mark = interpret-mark(mark)

	let tail = stroke.thickness*mark.at("tail", default: 0)

	if mark.at("rev", default: false) {
		θ += 180deg
		mark.rev = false
		p = vector.add(p, vector-polar(tail, θ))
	}

	mark.flip = mark.at("flip", default: +1)

	if debug {
		cetz.draw.on-layer(1, cetz.draw.circle(
			p,
			radius: stroke.thickness,
			stroke: none,
			fill: rgb("0f0a"),
		) + cetz.draw.line(
			p,
			vector.add(p, vector-polar(tail*(if mark.rev {1} else {-1}), θ)),
			stroke: rgb("0f0a") + stroke.thickness,
		))
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

	let stroke = (thickness: stroke.thickness, paint: stroke.paint, cap: "round")


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

	} else if mark.kind == "tail" {
		// p = shift(p, cap-offset(mark, 0))
		draw-arrow-cap(p, θ + 180deg, stroke, mark + (kind: "head"))

	} else if mark.kind == "hook" {
		p = shift(p, -mark.tail)
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

	} else if mark.kind == "hooks" {
		draw-arrow-cap(p, θ, stroke, mark + (kind: "hook"))
		draw-arrow-cap(p, θ, stroke, mark + (kind: "hook'"))

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
			fill: if mark.fill { stroke.paint }
		)

	} else if mark.kind == "solidhead" {
		// p = shift(p, -cap-offset(mark, mark))

		cetz.draw.line(
			p,
			(to: p, rel: vector-polar(-mark.size*stroke.thickness, θ + mark.sharpness)),
			(to: p, rel: vector-polar(-mark.size*stroke.thickness, θ - mark.sharpness)),
			fill: stroke.paint,
			stroke: none,
		)

	} else if mark.kind == "solidtail" {
		mark +=  (kind: "solidhead")
		p = shift(p, 1)
		draw-arrow-cap(p, θ + 180deg, stroke, mark)


	} else {
		panic("unknown mark kind:", mark)
	}
}
