#import "@local/cetz:0.1.2"
#import "utils.typ": *

// #let arrow-caps = "
// 	---
// 	-->
// 	<--
// 	<->
// 	===
// 	==>
// 	<==
// 	<=>
// 	|->
// 	->>
// 	>->
// 	>>->>
// 	|-->
// 	|<-->|
// 	c->
// 	<-c
// "

// #let line-types = "
// 	-
// 	=
// 	--
// 	..
// "

// #let arrow-heads = "
// 	< >
// 	<< >>
// 	| |
// 	c c
// 	c' c'
// 	harp
// "

#let CAP_OFFSETS = (
	"tail": -4,
	"hook": -3,
)
#let draw-arrow-cap(p, θ, stroke, kind) = {
	if kind in ("harpoon-l", "harpoon-r") {
		let i = if kind == "harpoon-l" { +1 } else { -1 }

		let sharpness = 25deg
		cetz.draw.arc(
			p,
			radius: 8*stroke.thickness,
			start: θ + i*(90deg + sharpness),
			delta: i*45deg,
			stroke: (thickness: stroke.thickness, paint: stroke.paint, cap: "round"),
		)
	} else if kind == "arrow" {
		draw-arrow-cap(p, θ, stroke, "harpoon-l")
		draw-arrow-cap(p, θ, stroke, "harpoon-r")
	} else if kind == "tail" {
		p = vector.add(p, vector-polar(stroke.thickness*CAP_OFFSETS.at(kind), θ))
		draw-arrow-cap(p, θ + 180deg, stroke, "arrow")
	} else if kind == "double" {
		draw-arrow-cap(p, θ, stroke, "arrow")
		p = cetz.vector.sub(p, vector-polar(stroke.thickness*3, θ))
		draw-arrow-cap(p, θ, stroke, "arrow")
	} else if kind == "hook" {
		p = vector.add(p, vector-polar(stroke.thickness*CAP_OFFSETS.at(kind), θ))
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
