#import "@local/cetz:0.1.2"
#import "utils.typ": *



/// Calculate cap offset of round-style arrow cap
///
/// - r (length): Radius of curvature of arrow cap
/// - θ (angle): Angle made at the the arrow's vertex, from the central stroke
///  line to the arrow's edge.
/// - y (length): Lateral offset from the central stroke line.
#let round-arrow-cap-offset(r, θ, y) = {
	r*(calc.sin(θ) - calc.sqrt(1 - calc.pow(calc.cos(θ) - calc.abs(y)/r, 2)))
}

#let CAP_OFFSETS = (
	"arrow": y => round-arrow-cap-offset(8, 30deg, y),
	"hook": y => -2,
	"hook-l": y => -2,
	"hook-r": y => -2,
	"tail": y => -3 - round-arrow-cap-offset(8, 30deg, y),
	"double": y => round-arrow-cap-offset(8, 30deg, y) - 2,
)



#let draw-arrow-cap(p, θ, stroke, kind) = {

	if kind in ("harpoon", "harpoon-l", "harpoon-r") {
		let dir = if kind == "harpoon-l" { +1 } else { -1 }

		let sharpness = 30deg
		cetz.draw.arc(
			p,
			radius: 8*stroke.thickness,
			start: θ + dir*(90deg + sharpness),
			delta: dir*40deg,
			stroke: (thickness: stroke.thickness, paint: stroke.paint, cap: "round"),
		)

	} else if kind == "arrow" {
		draw-arrow-cap(p, θ, stroke, "harpoon-l")
		draw-arrow-cap(p, θ, stroke, "harpoon-r")

	} else if kind == "tail" {
		p = vector.add(p, vector-polar(stroke.thickness*CAP_OFFSETS.at(kind)(0), θ))
		draw-arrow-cap(p, θ + 180deg, stroke, "arrow")

	} else if kind == "double" {
		p = cetz.vector.sub(p, vector-polar(stroke.thickness*-1, θ))
		draw-arrow-cap(p, θ, stroke, "arrow")
		p = cetz.vector.sub(p, vector-polar(stroke.thickness*3, θ))
		draw-arrow-cap(p, θ, stroke, "arrow")

	} else if kind in ("hook", "hook-l", "hook-r") {
		let dir = if kind == "hook-l" { +1 } else { -1 }
		p = vector.add(p, vector-polar(stroke.thickness*CAP_OFFSETS.at("hook")(0), θ))
		cetz.draw.arc(
			p,
			radius: 2.8*stroke.thickness,
			start: θ + dir*90deg,
			delta: -dir*180deg,
			stroke: (
				thickness: stroke.thickness,
				paint: stroke.paint,
				cap: "round",
			),
		)

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
