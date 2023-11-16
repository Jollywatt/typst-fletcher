#import "@local/cetz:0.1.2"
#import "utils.typ": *



/// Calculate cap offset of round-style arrow cap
///
/// - r (length): Radius of curvature of arrow cap.
/// - θ (angle): Angle made at the the arrow's vertex, from the central stroke
///  line to the arrow's edge.
/// - y (length): Lateral offset from the central stroke line.
#let round-arrow-cap-offset(r, θ, y) = {
	r*(calc.sin(θ) - calc.sqrt(1 - calc.pow(calc.cos(θ) - calc.abs(y)/r, 2)))
}

#let CAP_OFFSETS = (
	"head":    y => round-arrow-cap-offset(8, 30deg, y),
	"hook":    y => -2,
	"hook'":   y => -2,
	"hooks":   y => -2,
	"tail":    y => -3 - round-arrow-cap-offset(8, 30deg, y),
	"twohead": y => round-arrow-cap-offset(8, 30deg, y) - 2,
	"twotail": y => -3 - round-arrow-cap-offset(8, 30deg, y) - 2,
)


#let parse-arrow-shorthand(str) = {
	let caps = (
		"": (none, none),
		">": ("tail", "head"),
		">>": ("twotail", "twohead"),
		"<": ("head", "tail"),
		"<<": ("twohead", "twotail"),
		"|": ("bar", "bar"),
	)
	let lines = (
		"-": (:),
		"=": (double: true),
		"--": (dash: "dashed"),
		"..": (dash: "dotted"),
	)

	let cap-selector = "(|<|>|<<|>>|hook[s']?|harpoon'?|\|)"
	let line-selector = "(-|=|--|==|::|\.\.)"
	let match = str.match(regex("^" + cap-selector + line-selector + cap-selector + "$"))
	if match == none {
		panic("Failed to parse", str)
	}
	let (from, line, to) = match.captures
	(
		marks: (
			if from in caps { caps.at(from).at(0) } else { from },
			if to in caps { caps.at(to).at(1) } else { to },
		),
		..lines.at(line),
	)
}



#let draw-arrow-cap(p, θ, stroke, kind) = {

	let flip = +1
	if kind.at(-1) == "'" {
		flip = -1
		kind = kind.slice(0, -1)
	}

	if kind == "harpoon" {
		let sharpness = 30deg
		cetz.draw.arc(
			p,
			radius: 8*stroke.thickness,
			start: θ + flip*(90deg + sharpness),
			delta: flip*40deg,
			stroke: (thickness: stroke.thickness, paint: stroke.paint, cap: "round"),
		)

	} else if kind == "head" {
		draw-arrow-cap(p, θ, stroke, "harpoon")
		draw-arrow-cap(p, θ, stroke, "harpoon'")

	} else if kind == "tail" {
		p = vector.add(p, vector-polar(stroke.thickness*CAP_OFFSETS.at(kind)(0), θ))
		draw-arrow-cap(p, θ + 180deg, stroke, "head")

	} else if kind in ("twohead", "twotail") {
		let subkind = if kind == "twohead" { "head" } else { "tail" }
		p = cetz.vector.sub(p, vector-polar(-1*stroke.thickness, θ))
		draw-arrow-cap(p, θ, stroke, subkind)
		p = cetz.vector.sub(p, vector-polar(+3*stroke.thickness, θ))
		draw-arrow-cap(p, θ, stroke, subkind)

	} else if kind == "hook" {
		p = vector.add(p, vector-polar(stroke.thickness*CAP_OFFSETS.at("hook")(0), θ))
		cetz.draw.arc(
			p,
			radius: 2.5*stroke.thickness,
			start: θ + flip*90deg,
			delta: -flip*180deg,
			stroke: (
				thickness: stroke.thickness,
				paint: stroke.paint,
				cap: "round",
			),
		)

	} else if kind == "hooks" {
		draw-arrow-cap(p, θ, stroke, "hook")
		draw-arrow-cap(p, θ, stroke, "hook'")

	} else if kind == "bar" {
		let v = vector-polar(4.5*stroke.thickness, θ + 90deg)
		cetz.draw.line(
			(to: p, rel: v),
			(to: p, rel: vector.scale(v, -1)),
			stroke: (
				paint: stroke.paint,
				thickness: stroke.thickness,
				cap: "round",
			),
		)

	} else {
		panic("unknown arrow kind:", kind)
	}
}
