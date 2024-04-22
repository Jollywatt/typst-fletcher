#import "utils.typ": *
#import "deps.typ": cetz
#import cetz.draw


#let MARKS = (

	head: (
		size: 7, // radius of curvature, multiples of stroke thickness
		sharpness: 24.7deg, // angle at vertex between central line and arrow's edge
		delta: 53.5deg, // angle spanned by arc of curved arrow edge

		tail-origin: mark => mark.tail-end - mark.size*mark.delta/2rad*(calc.cos(mark.sharpness) + calc.cos(mark.sharpness + mark.delta)),

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
		}
	),

	twohead: (
		inherit: "head",
		extrude: (-3, 0),
		tail-end: mark => calc.min(..mark.extrude),
	),

	stealth: (
		size: 5,
		stealth: 0.3,
		angle: 25deg,

		tip-origin: 0,
		tail-origin: mark => mark.size*(mark.stealth/2 - 1)*calc.cos(mark.angle),
		tip-end: mark => mark.size*(mark.stealth - 1)*calc.cos(mark.angle),
		tail-end: mark => -mark.size*calc.tan(mark.angle)/2,

		draw: mark => {
			draw.line(
				(0,0),
				(180deg + mark.angle, mark.size),
				(mark.tip-end, 0),
				(180deg - mark.angle, mark.size),
				stroke: none,
				close: true,
			)
		}
	),

	circle: (
		size: 3,

		tip-end: mark => -mark.size,
		tail-end: mark => mark.size,
		tip-origin: mark => mark.size,
		tail-origin: mark => -mark.size,

		fill: none,

		draw: mark => draw.circle((0,0), radius: mark.size, fill: mark.fill)
	)
)

#let apply-mark-inheritances(mark) = {
	while "inherit" in mark {
		let parent = MARKS.at(mark.remove("inherit"))
		mark = parent + mark
	}
	mark
}

#let resolve-mark(mark) = {
	mark = apply-mark-inheritances(mark)

	let required-defaults = (
		rev: false,
		scale: 100%,
		tip-end: 0,
		tail-end: 0,
		tip-origin: 0,
		tail-origin: 0,
	)

	mark = required-defaults + mark

	for (key, value) in mark {
		if type(value) == function {
			mark.at(key) = value(mark)
		}
	}

	mark
}

#let draw-mark(
	mark,
	stroke: 1pt,
	origin: (0,0),
	angle: 0deg,
) = {
	mark = resolve-mark(mark)

	let stroke = stroke-to-dict(stroke)
	stroke += mark.at("stroke", default: none)
	stroke = as-stroke(stroke)

	draw.set-style(
		stroke: stroke,
		fill: map-auto(stroke.paint, black),
	)

	draw.group({
		draw.rotate(angle)
		draw.translate(origin)
		draw.scale(stroke.thickness/1cm*float(mark.scale))

		if mark.rev {
			draw.translate(x: mark.tail-origin)
			draw.scale(x: -1)
		} else {
			draw.translate(x: -mark.tip-origin)
		}

		let extrude = mark.at("extrude", default: (0,))
		for e in extrude {
			draw.group({
				draw.translate(x: e)
				mark.draw
			})
		}
	})
}

#let mark-debug(mark, stroke: 5pt) = {
	mark = resolve-mark(mark)
	stroke = as-stroke(stroke)

	let t = stroke.thickness*float(mark.scale)
	cetz.canvas({

		draw-mark(mark, stroke: stroke)
		draw.translate(x: -t*mark.tip-origin)

		for (i, (item, y, color)) in (
			("tip-end",  +0.75, "0f0"),
			("tail-end", -0.75, "f00"),
			("tip-origin",      +0.5,  "0ff"),
			("tail-origin",     -0.5,  "f0f"),
		).enumerate() {
			let x = mark.at(item)
			let c = rgb(color)
			draw.line((t*x, 0), (t*x, y), stroke: 0.5pt + c)
			draw.content(
				(t*x, y),
				pad(2pt, text(0.75em, fill: c, raw(item))),
				anchor: if y < 0 { "north" } else { "south" },
			)
		}

		let (min, max) = min-max((
			"tip-end",
			"tail-end",
			"tip-origin",
			"tail-origin",
		).map(i => mark.at(i)))
		let l = calc.max(5, max - min)

		draw.line(
			(t*mark.tip-end, 0),
			(t*(min - l), 0),
			stroke: rgb("0f04") + t,
		)
		draw.line(
			(t*mark.tail-end, 0),
			(t*(max + l), 0),
			stroke: rgb("f004") + t,
		)

	})
}

#let mark-demo(
	mark,
	stroke: 2pt,
	width: 3cm,
	height: 1cm,
) = {
	mark = resolve-mark(mark)
	stroke = as-stroke(stroke)

	cetz.canvas({

		for x in (0, width) {
			draw.line(
				(x, +0.5*height),
				(x, -1.5*height),
				stroke: red.transparentize(50%) + 0.5pt,
			)
		}

		let x = (mark.tip-origin - mark.tip-end)*stroke.thickness
		draw.line(
			(x, 0),
			(rel: (-x, 0), to: (width, 0)),
			stroke: stroke,
		)

		draw-mark(
			mark + (rev: false),
			stroke: stroke,
			origin: (0, 0),
			angle: 180deg,
		)
		draw-mark(
			mark + (rev: false),
			stroke: stroke,
			origin: (width, 0),
			angle: 0deg,
		)

		draw.translate((0, -height))

		let x = (mark.tail-end - mark.tail-origin)*stroke.thickness
		draw.line(
			(x, 0),
			(rel: (-x, 0), to: (width, 0)),
			stroke: stroke,
		)

		draw-mark(
			mark + (rev: true),
			stroke: stroke,
			origin: (0, 0),
			angle: 180deg,
		)
		draw-mark(
			mark + (rev: true),
			stroke: stroke,
			origin: (width, 0),
			angle: 0deg,
		)

	})
}
