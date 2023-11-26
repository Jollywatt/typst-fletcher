#import "@preview/cetz:0.1.2"
#import "utils.typ": *
#import calc: sqrt, abs, sin, cos, max, pow


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
		size: 8, // radius of curvature, multiples of stroke thickness
		sharpness: 30deg, // angle at vertex between central line and arrow's edge
		delta: 40deg, // angle spanned by arc of curved arrow edge
	)


	if mark.kind in ("head", "harpoon", "tail") {
		round-style + mark
	} else if mark.kind == "twohead" {
		round-style + mark + (kind: "head", extrude: (0, -3))
	} else if mark.kind == "twotail" {
		round-style + mark + (kind: "tail", extrude: (0, +3))
	} else if mark.kind == "bar" {
		(size: 4.5) + mark
	} else if mark.kind in ("hook", "hooks") {
		(size: 2.5) + mark
	} else if mark.kind == "circle" {
		(size: 2) + mark
	} else if mark.kind == "bigcircle" {
		(size: 4) + mark + (kind: "circle")
	} else {
		panic("Cannot interpret mark: " + mark.kind)
	}
}

/// Calculate cap offset of round-style arrow cap
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
	else if mark.kind in ("hook", "hook'", "hooks") { -2 }
	else if mark.kind == "tail" { -3 - offset() }
	else if mark.kind == "twohead" { offset() - 3 }
	else if mark.kind == "twotail" { -3 - offset() - 3 }
	else if mark.kind == "circle" {
		let r = mark.size
		-sqrt(max(0, r*r - y*y)) - r
	} else { 0 }
}


#let draw-arrow-cap(p, θ, stroke, mark) = {
	mark = interpret-mark(mark)

	let shift(p, x) = cetz.vector.add(
		p,
		vector-polar(stroke.thickness*x, θ)
	)

	if "extrude" in mark {
		return mark.extrude.map(e => {
			let mark = mark
			let _ = mark.remove("extrude")
			mark.shift = e
			draw-arrow-cap(p, θ, stroke, mark)
		}).join()
	}


	if mark.kind == "harpoon" {
		cetz.draw.arc(
			p,
			radius: mark.size*stroke.thickness,
			start: θ + mark.flip*(90deg + mark.sharpness),
			delta: mark.flip*mark.delta,
			stroke: (thickness: stroke.thickness, paint: stroke.paint, cap: "round"),
		)

	} else if mark.kind == "head" {
		if "shift" in mark { p = shift(p, mark.shift) }
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
			stroke: (
				thickness: stroke.thickness,
				paint: stroke.paint,
				cap: "round",
			),
		)

	} else if mark.kind == "hooks" {
		draw-arrow-cap(p, θ, stroke, mark + (kind: "hook"))
		draw-arrow-cap(p, θ, stroke, mark + (kind: "hook'"))

	} else if mark.kind == "bar" {
		let v = vector-polar(mark.size*stroke.thickness, θ + 90deg)
		cetz.draw.line(
			(to: p, rel: v),
			(to: p, rel: vector.scale(v, -1)),
			stroke: (
				paint: stroke.paint,
				thickness: stroke.thickness,
				cap: "round",
			),
		)

	} else if mark.kind == "circle" {
		p = shift(p, -mark.size)
		cetz.draw.circle(
			p,
			radius: mark.size*stroke.thickness,
			stroke: (
				thickness: stroke.thickness,
				paint: stroke.paint,
			),
		)

	} else {
		panic("unknown mark kind:", mark)
	}
}
