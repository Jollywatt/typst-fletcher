#import "@local/cetz:0.1.2"
#import "utils.typ": *

#let arrow-caps = (
)

#let draw-arrow-cap(p, θ, stroke, kind) = {
	if kind == "arrow" {
		for i in (+1, -1) {
			cetz.draw.arc(
				p,
				radius: 8*stroke.thickness,
				start: θ + i*115deg,
				delta: i*45deg,
				stroke: (thickness: stroke.thickness, paint: stroke.paint, cap: "round"),
			)
		}
	} else if kind == "tail" {
		draw-arrow-cap(p, θ + 180deg, stroke, "arrow")
	} else if kind == "double" {
		draw-arrow-cap(p, θ, stroke, "arrow")
		p = cetz.vector.sub(p, vector-polar(stroke.thickness*3, θ))
		draw-arrow-cap(p, θ, stroke, "arrow")
	} else if kind == "hook" {
		cetz.draw.arc(
			p,
			radius: 2.8*stroke.thickness,
			start: θ + 90deg,
			delta: -180deg,
			stroke: (thickness: stroke.thickness, paint: stroke.paint, cap: "round"),
		)
	} else if kind == "bar" {
		let v = vector-polar(4.5*stroke.thickness, θ + 90deg)
		cetz.draw.line(
			(to: p, rel: v),
			(to: p, rel: vector.scale(v, -1)),
			stroke: (paint: stroke.paint, thickness: stroke.thickness, cap: "round"),
		)
	} else {
		panic(kind)
	}
}
