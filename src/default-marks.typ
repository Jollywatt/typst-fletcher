#import "deps.typ"
#import deps.cetz.draw

#let DEFAULT_MARKS = (
	// all numbers are interpreted as multiples of stroke thickness

	head: (
		size: 7, // radius of curvature
		sharpness: 24.7deg, // angle at vertex between central line and arrow's edge
		delta: 53.5deg, // angle spanned by arc of curved arrow edge

		tip-origin: 0.5,
		tail-end: mark => calc.min(..mark.extrude),
		tail-origin: mark => {
			let dx = calc.cos(mark.sharpness) + calc.cos(mark.sharpness + mark.delta)
			mark.tail-end - mark.size*mark.delta/1.8rad*dx
		},

		stroke: (cap: "round"),

		draw: mark => {
			for flip in (+1, -1) {
				draw.arc(
					(0, 0),
					radius: mark.size,
					start: flip*(90deg + mark.sharpness),
					delta: flip*mark.delta,
					fill: none,
				)
			}
		},

		cap-offset: (mark, y) => {
			import calc: sin, sqrt, pow, cos, abs, max
			let r = mark.size
			let θ = mark.sharpness
			r*(sin(θ) - sqrt(max(0, 1 - pow(cos(θ) - abs(y)/r, 2))))
		},

	),

	doublehead: (
		inherit: "head",
		size: 10.56,
		sharpness: 19.4deg,
		delta: 43.5deg,
	),

	triplehead: (
		inherit: "head",
		size: 13.5,
		sharpness: 25.5deg,
		delta: 42.6deg,
	),

	harpoon: (
		inherit: "head",
		draw: mark => {
			draw.arc(
				(0, 0),
				radius: mark.size,
				start: -(90deg + mark.sharpness),
				delta: -mark.delta,
				fill: none,
			)
		},
	),

	straight: (
		size: 10,
		sharpness: 20deg,

		tip-origin: mark => 0.5/calc.sin(mark.sharpness),
		tail-origin: mark => -mark.size*calc.cos(mark.sharpness),

		fill: none,

		draw: mark => {
			draw.line(
				(180deg + mark.sharpness, mark.size),
				(0, 0),
				(180deg - mark.sharpness, mark.size),
			)
		},

		cap-offset: (mark, y) => calc.tan(mark.sharpness + 90deg)*calc.abs(y),
	),

	solid: (
		inherit: "straight",

		tip-origin: 0,
		tip-end: mark => -0.5/calc.sin(mark.sharpness),
		tail-end: mark => -0.5/calc.sin(mark.sharpness),

		stroke: none,
		fill: auto,
	),

	stealth: (
		size: 6,
		stealth: 0.3,
		angle: 25deg,

		tip-origin: mark => 0.5/calc.sin(mark.angle),
		tail-origin: mark => -mark.size*calc.cos(mark.angle) - 1,
		tip-end: mark => mark.size*(mark.stealth - 1)*calc.cos(mark.angle),

		stroke: (miter-limit: 20),

		draw: mark => {
			draw.line(
				(0,0),
				(180deg + mark.angle, mark.size),
				(mark.tip-end, 0),
				(180deg - mark.angle, mark.size),
				close: true,
			)
		},

		cap-offset: (mark, y) => if mark.tip {
			-mark.stealth/calc.tan(mark.angle)*calc.abs(y)
		} else {
			calc.tan(mark.angle + 90deg)*calc.abs(y)
		},
	),

	latex: (
		size: 23, // radius of curvature
		sharpness: 10deg, // angle at vertex between central line and arrow's edge
		delta: 20deg, // angle spanned by arc of curved arrow edge

		tip-end: mark => mark.size*(calc.sin(mark.sharpness) - calc.sin(mark.sharpness + mark.delta)),
		tail-end: mark => mark.tip-end/2,
		tail-origin: mark => mark.tip-end,

		fill: auto,
		stroke: none,
		draw: mark => {
			for flip in (+1, -1) {
				draw.merge-path({
					draw.arc(
						(0, 0),
						radius: mark.size,
						start: flip*(90deg + mark.sharpness),
						delta: flip*mark.delta,
						fill: none,
					)
					draw.line((), ((), "|-", (0, flip*1e-1)))
				})
			}
		}
	),

	cone: (
		size: 8,
		radius: 6,
		angle: 30deg,

		tip-end: mark => -mark.size,
		tail-end: mark => mark.tip-end/2,
		tail-origin: mark => mark.tip-end,

		stroke: none,
		draw: mark => {
			for flip in (+1, -1) {
				draw.merge-path({
					draw.arc(
						(-mark.size, -flip*1e-1),
						radius: mark.radius,
						start: 0deg,
						stop: flip*mark.angle,
					)
					draw.line((), (0, 0))
				})
			}
		}
	),

	circle: (
		size: 2,

		tip-end: mark => -mark.size,
		tail-end: mark => mark.size,
		tip-origin: mark => mark.size + 0.5,
		tail-origin: mark => -(mark.size + 0.5),

		fill: none,

		draw: mark => draw.circle((0,0), radius: mark.size, fill: mark.fill),

		cap-offset: (mark, y) => {
			let r = mark.size
			let o = r - calc.sqrt(calc.max(0, r*r - y*y))
			if not mark.tip { o *= -1 }
			o
		},
	),

	square: (
		size: 2,
		angle: 0deg,
		fill: none,
		tip-origin: mark => +(mark.size + 0.5)/calc.cos(mark.angle),
		tail-origin: mark => -(mark.size + 0.5)/calc.cos(mark.angle),
		tip-end: mark => -mark.size/calc.cos(mark.angle),
		tail-end: mark => +mark.size/calc.cos(mark.angle),
		draw: mark => {
			let x = mark.size
			draw.rotate(mark.angle)
			draw.rect(
				(-x, -x), (+x, +x),
			)
		}
	),

	diamond: (
		inherit: "square",
		angle: 45deg,
	),

	bar: (
		size: 4.9,
		angle: 90deg,

		tail-origin: mark => calc.min(..mark.extrude),

		draw: mark => draw.line(
			(mark.angle, -mark.size),
			(mark.angle, +mark.size),
		),
		cap-offset: (mark, y) => {
			let o = y*calc.tan(mark.angle - 90deg)
			// if mark.tip { o *= -1 }
			-o
		},
	),

	cross: (
		size: 4,
		angle: 45deg,
		draw: mark => {
			draw.line((+mark.angle, -mark.size), (+mark.angle, +mark.size))
			draw.line((-mark.angle, -mark.size), (-mark.angle, +mark.size))
		},

		cap-offset: (mark, y) => calc.tan(mark.angle + 90deg)*calc.abs(y),
	),

	hook: (
		size: 2.88,
		rim: 0.85,

		tip-origin: mark => mark.size + 0.5,

		stroke: (cap: "round"),

		draw: mark => {
			draw.arc(
				(0,0),
				start: -90deg,
				stop: +90deg,
				radius: mark.size,
				fill: none,
			)
			draw.line((), (rel: (-mark.rim, 0)))
		},
	),

	hooks: (
		inherit: "hook",
		draw: mark => {
			for flip in (-1, +1) {
				draw.arc(
					(0,0),
					start: -flip*90deg,
					stop: +flip*90deg,
					radius: mark.size,
					fill: none,
				)
			}
		},
	),

	">": (inherit: "head", rev: false),
	"<": (inherit: "head", rev: true),

	">>": (inherit: "head", extrude: (-2.88, 0), rev: false),
	"<<": (inherit: "head", extrude: (-2.88, 0), rev: true),

	">>>": (inherit: "head", extrude: (-6, -3, 0), rev: false),
	"<<<": (inherit: "head", extrude: (-6, -3, 0), rev: true),

	"|>": (inherit: "solid", rev: false),
	"<|": (inherit: "solid", rev: true),

	"}>": (inherit: "stealth", rev: false),
	"<{": (inherit: "stealth", rev: true),

	"|": (inherit: "bar"),
	"||": (inherit: "bar", extrude: (-3, 0)),
	"|||": (inherit: "bar", extrude: (-6, -3, 0)),

	"/": (inherit: "bar", angle: +60deg, rev: false),
	"\\": (inherit: "bar", angle: -60deg, rev: false),

	"x": (inherit: "cross"),
	"X": (inherit: "cross", size: 7),

	"o": (inherit: "circle"),
	"O": (inherit: "circle", size: 4),
	"*": (inherit: "circle", fill: auto),
	"@": (inherit: "circle", size: 4, fill: auto),

	"[]": (inherit: "square"),
	"<>": (inherit: "diamond"),




	// crow's foot notation
	crowfoot: (
		many-width: 5,
		many-length: 8,
		one-width: 5,
		zero-width: 3.5,
		gap: 3,
		first-gap: 5,
		many: true,
		one: true,
		zero: true,
		tail-origin: mark => -mark.many-length,
		zero-fill: white,
		fill: none,
		draw: mark => {
			let x = 0
			if mark.many {
				draw.line((0, mark.many-width), (-mark.many-length - .5, 0), (0, -mark.many-width))
				x -= mark.many-length
			}
			if mark.one {
				x -= mark.gap
				x = calc.min(x, -mark.first-gap)
				draw.line((x, mark.one-width), (x, -mark.one-width))
			}
			if mark.zero {
				x -= mark.gap
				draw.circle((x - mark.zero-width, 0), radius: mark.zero-width, fill: mark.zero-fill)
			}
		}
	),
	"n": (inherit: "crowfoot", zero: false, one: false, many: true),
	"n!": (inherit: "crowfoot", zero: false, one: true, many: true),
	"n?": (inherit: "crowfoot", zero: true, one: false, many: true),
	"1": (inherit: "crowfoot", zero: false, one: true, many: false),
	"1!": (inherit: "crowfoot", zero: false, one: true, many: false, extrude: mark => (0, -calc.max(4, mark.gap))),
	"1?": (inherit: "crowfoot", zero: true, one: true, many: false),

)

#let MARKS = state("fletcher-marks", DEFAULT_MARKS)
