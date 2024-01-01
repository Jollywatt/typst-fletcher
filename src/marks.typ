#import "@preview/cetz:0.1.2"
#import "utils.typ": *
#import calc: sqrt, abs, sin, cos, max, pow


#let EDGE_ARGUMENT_SHORTHANDS = (
	"dashed": (dash: "dashed"),
	"dotted": (dash: "dotted"),
	"double": (extrude: (-2, +2), mark-scale: 110%, mark-variant: 2),
	"triple": (extrude: (-4, 0, +4), mark-scale: 150%, mark-variant: 3),
	"crossing": (crossing: true),
)


#let parse-arrow-shorthand(str) = {
	let caps = (
		"": (none, none),
		">": ("tail", "head"),
		">>": ("twotail", "twohead"),
		"<": ("head", "tail"),
		"<<": ("twohead", "twotail"),
		"|>": ("solidtail", "solidhead"),
		"<|": ("solidhead", "solidtail"),
		"|": ("bar", "bar"),
		"||": ("twobar", "twobar"),
		"o": ("circle", "circle"),
		"O": ("bigcircle", "bigcircle"),
	)
	let lines = (
		"-": (:),
		"=": EDGE_ARGUMENT_SHORTHANDS.double,
		"==": EDGE_ARGUMENT_SHORTHANDS.triple,
		"--": EDGE_ARGUMENT_SHORTHANDS.dashed,
		"..": EDGE_ARGUMENT_SHORTHANDS.dotted,
	)

	let cap-selector = "(|<|>|<<|>>|hook[s']?|harpoon'?|\|\|?|o|O|<\||\|>)"
	let line-selector = "(-|=|--|==|::|\.\.)"
	let match = str.match(regex("^" + cap-selector + line-selector + cap-selector + "$"))
	if match == none {
		panic("Failed to parse '" + str + "' as a edge style shorthand.")
	}
	let (from, line, to) = match.captures

	from = if from in caps { caps.at(from).at(0) } else { from }
	to = if to in caps { caps.at(to).at(1) } else { to }

	if line == "=" {
		// make arrows slightly larger, suited for double stroked line
		if from == "head" { from = "doublehead" } 
		if to == "head" { to = "doublehead" } 
	} else if line == "==" {
		if from == "head" { from = "triplehead" } 
		if to == "head" { to = "triplehead" } 	
	}

	(
		marks: (from, to),
		..lines.at(line),
	)
}




/// Take a string or dictionary specifying a mark and return a dictionary,
/// adding defaults for any necessary missing parameters.
#let interpret-mark(mark) = {
	if mark == none { return none }

	if type(mark) == str {
		mark = (kind: mark)
	}

	mark.flip = mark.at("flip", default: +1)
	if mark.kind.at(-1) == "'" {
		mark.flip = -mark.flip
		mark.kind = mark.kind.slice(0, -1)
	}

	let round-style = (
		size: 7, // radius of curvature, multiples of stroke thickness
		sharpness: 24deg, // angle at vertex between central line and arrow's edge
		delta: 54deg, // angle spanned by arc of curved arrow edge
	)


	if mark.kind in ("head", "harpoon", "tail") {
		round-style + mark
	} else if mark.kind == "twohead" {
		round-style + mark + (kind: "head", extrude: (-3, 0))
	} else if mark.kind == "twotail" {
		round-style + mark + (kind: "tail", extrude: (-3, 0))
	} else if mark.kind == "twobar" {
		(size: 4.5) + mark + (kind: "bar", extrude: (-3, 0))
	} else if mark.kind == "doublehead" {
		// tuned to match sym.arrow.double
		(
			kind: "head",
			size: 9.6,
			sharpness: 19deg,
			delta: 43.7deg,
		)
	} else if mark.kind == "triplehead" {
		// tuned to match sym.arrow.triple
		(
			kind: "head",
			size: 9,
			sharpness: 25deg,
			delta: 43deg,
		)
	} else if mark.kind == "bar" {
		(size: 4.5) + mark
	} else if mark.kind in ("hook", "hooks") {
		(size: 2.88, rim: 0.85) + mark
	} else if mark.kind == "circle" {
		(size: 2) + mark
	} else if mark.kind == "bigcircle" {
		(size: 4) + mark + (kind: "circle")
	} else if mark.kind in ("solidhead", "solidtail") {
		(size: 10, sharpness: 19deg) + mark
	} else {
		panic("Cannot interpret mark: " + mark.kind)
	}
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

	if mark.kind == "head" { offset() }
	else if mark.kind in ("hook", "hook'", "hooks") { -2.65 }
	else if mark.kind == "tail" { -3 - offset() }
	else if mark.kind == "twohead" { offset() - 3 }
	else if mark.kind == "twotail" { -3 - offset() - 3 }
	else if mark.kind == "circle" {
		let r = mark.size
		-sqrt(max(0, r*r - y*y)) - r
	} else if mark.kind == "solidhead" {
		-mark.size*cos(mark.sharpness)
	} else if mark.kind == "solidtail" {
		-1
	} else { 0 }
}


#let draw-arrow-cap(p, θ, stroke, mark) = {
	mark = interpret-mark(mark)

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
		p = shift(p, cap-offset(mark, 0))
		draw-arrow-cap(p, θ + 180deg, stroke, mark + (kind: "head"))

	} else if mark.kind == "hook" {
		p = shift(p, cap-offset(mark, 0))
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
		let v = vector-polar(mark.size*stroke.thickness, θ + 90deg)
		cetz.draw.line(
			(to: p, rel: v),
			(to: p, rel: vector.scale(v, -1)),
			stroke: stroke,
		)

	} else if mark.kind == "circle" {
		p = shift(p, -mark.size)
		cetz.draw.circle(
			p,
			radius: mark.size*stroke.thickness,
			stroke: stroke,
		)

	} else if mark.kind == "solidhead" {
		cetz.draw.line(
			p,
			(to: p, rel: vector-polar(-mark.size*stroke.thickness, θ + mark.sharpness)),
			(to: p, rel: vector-polar(-mark.size*stroke.thickness, θ - mark.sharpness)),
			fill: stroke.paint,
			stroke: none,
		)

	} else if mark.kind == "solidtail" {
		mark +=  (kind: "solidhead")
		p = shift(p, cap-offset(mark, 0))
		draw-arrow-cap(p, θ + 180deg, stroke, mark)


	} else {
		panic("unknown mark kind:", mark)
	}
}
