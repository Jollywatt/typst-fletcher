#import "utils.typ": *
#import "deps.typ": cetz
#import cetz.draw
#import "default-marks.typ": MARKS

#let MARK_REQUIRED_DEFAULTS = (
	flip: false,
	scale: 100%,
	extrude: (0,),
	tip-end: 0,
	tail-end: 0,
	tip-origin: 0,
	tail-origin: 0,
)





/// Determine amount that the end of a stroke should be offset to accommodate
/// for a mark, as a function of the shift.
///
/// Imagine the tip origin of the mark is at $(x, y) = (0, 0)$. A stroke along
/// the line $y = "shift"$ coming from $x = -oo$ terminates at $x = o$, where
/// $o$ is the result of this function.
///
/// Units are in multiples of stroke thickness.
#let cap-offset(mark, shift) = {
	let o = 0
	if "cap-offset" in mark {
		o = (mark.cap-offset)(mark, shift)
	}

	mark = MARK_REQUIRED_DEFAULTS + mark
	if mark.tip {
		mark.tip-end + o
	} else {
		mark.tail-end + o
	}
}



#let apply-mark-inheritances(mark) = {
	while "inherit" in mark {

		if mark.inherit.at(-1) == "'" {
			mark.flip = not mark.at("flip", default: false)
			mark.inherit = mark.inherit.slice(0, -1)
		}

		assert(mark.inherit in MARKS, message: "Mark style " + repr(mark.inherit) + " not defined.")

		let parent = MARKS.at(mark.remove("inherit"))
		mark = parent + mark
	}
	mark
}


#let resolve-mark(mark, defaults: (:)) = {
	if mark == none { return none }

	if type(mark) == str { mark = (inherit: mark) }

	mark = apply-mark-inheritances(mark)


	mark = MARK_REQUIRED_DEFAULTS + defaults + mark

	for (key, value) in mark {
		if key == "cap-offset" { continue }

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
	debug: false
) = {
	mark = resolve-mark(mark)
	stroke = as-stroke(stroke)

	let thickness = stroke.thickness

	let fill = mark.at("fill", default: auto)
	fill = map-auto(fill, stroke.paint)
	fill = map-auto(fill, black)

	let stroke = stroke-to-dict(stroke)
	stroke.dash = none

	if "stroke" in mark {
		if mark.stroke == none { stroke = none }
		else if mark.stroke == auto { }
		else { stroke += stroke-to-dict(mark.stroke) }
	}

	assert("draw" in mark)

	draw.group({
		draw.set-style(
			stroke: stroke,
			fill: fill,
		)

		draw.translate(origin)
		draw.rotate(angle)
		draw.scale(thickness/1cm*float(mark.scale))

		if mark.at("rev", default: false) {
			draw.translate(x: mark.tail-origin)
			draw.scale(x: -1)
			if debug {
				draw.content((0,10), text(0.25em, red)[rev])
			}
		} else {
			draw.translate(x: -mark.tip-origin)
		}

		if mark.flip {
			draw.scale(y: -1)
		}

		for e in mark.extrude {
			draw.group({
				draw.translate(x: e)
				mark.draw
			})
		}

		if debug {
			let tip = mark.at("tip", default: none)
			if tip == true {
				draw.content((0,-10), text(0.25em, green)[tip])
			} else if tip == false {
				draw.content((0,-10), text(0.25em, orange)[tail])
			}
		}

	})
}

#let mark-debug(
	mark,
	stroke: 5pt,
	show-labels: true,
	show-offsets: true,
	offset-range: 5
) = {
	mark = resolve-mark(mark)
	stroke = as-stroke(stroke)

	let t = stroke.thickness*float(mark.scale)


	cetz.canvas({

		draw-mark(mark, stroke: stroke)

		if mark.at("rev", default: false) {
			draw.scale(x: -1)
			draw.translate(x: -t*mark.tail-origin)
		} else {
			draw.translate(x: -t*mark.tip-origin)
		}

		if show-offsets {

			let samples = 100
			let ys = range(samples + 1)
				.map(n => n/samples)
				.map(y => (2*y - 1)*offset-range)

			let tip-points = ys.map(y => {
				let o = cap-offset(mark + (tip: true), y)
				(o*t, y*t)
			})

			let tail-points = ys.map(y => {
				let o = cap-offset(mark + (tip: false), y)
				(o*t, y*t)
			})

			draw.line(
				..tip-points,
				stroke: (
					paint: rgb("0f0"),
					thickness: 0.4pt,
					dash: (array: (3pt, 3pt), phase: 0pt),
				),
			)
			draw.line(
				..tail-points,
				stroke: (
					paint: rgb("f00"),
					thickness: 0.4pt,
					dash: (array: (3pt, 3pt), phase: 3pt),
				),
			)


		}

		if show-labels {
			for (i, (item, y, color)) in (
				("tip-end",     +1.00, "0f0"),
				("tail-end",    -1.00, "f00"),
				("tip-origin",  +0.75,  "0ff"),
				("tail-origin", -0.75,  "f0f"),
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
		}

		// draw tip/tail stroke previews
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
			stroke: rgb("0f06") + t,
		)
		draw.line(
			(t*mark.tail-end, 0),
			(t*(max + l), 0),
			stroke: rgb("f006") + t,
		)

		// draw true origin dot
		draw.circle(
			(0, 0),
			radius: t/8,
			stroke: rgb("00f") + 0.5pt,
			fill: white,
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

	let t = stroke.thickness

	cetz.canvas({

		for x in (0, width) {
			draw.line(
				(x, +0.5*height),
				(x, -1.5*height),
				stroke: red.transparentize(50%) + 0.5pt,
			)
		}

		let x = t*(mark.tip-origin - mark.tip-end)
		draw.line(
			(x, 0),
			(rel: (-x, 0), to: (width, 0)),
			stroke: stroke,
		)

		let mark-length = t*(mark.tip-origin - mark.tail-origin)
		draw-mark(
			mark + (rev: true),
			stroke: stroke,
			origin: (mark-length, 0),
			angle: 0deg,
		)
		draw-mark(
			mark + (rev: false),
			stroke: stroke,
			origin: (width, 0),
			angle: 0deg,
		)

		draw.translate((0, -height))

		let x = t*(mark.tail-end - mark.tail-origin)
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
			mark + (rev: false),
			stroke: stroke,
			origin: (width - mark-length, 0),
			angle: 180deg,
		)

	})
}


#let place-mark-on-curve(mark, path, stroke: 1pt + black, debug: false) = {
	if mark.at("hide", default: false) { return }

	let ε = 1e-4

	// calculate velocity of parametrised path at point
	let point = path(mark.pos)
	let point-plus-ε = path(mark.pos + ε)
	let grad = vector-len(vector.sub(point-plus-ε, point))/ε
	if grad == 0pt { grad = ε*1pt }

	let mark-length = mark.at("tip-origin", default: 0) - mark.at("tail-origin", default: 0)
	let Δt = mark-length*stroke.thickness/grad
	if Δt == 0 { Δt = ε } // avoid Δt = 0 so the two points are distinct

	let t = lerp(Δt, 1, mark.pos)
	let tip-point = path(t)
	let tail-point = path(t - Δt)
	let θ = vector-angle(vector.sub(tip-point, tail-point))

	draw-mark(mark, origin: tip-point, angle: θ, stroke: stroke)

	if debug {
		draw.circle(
			tip-point,
			radius: .2pt,
			fill: rgb("0f0"),
			stroke: none
		)
		draw.circle(
			tail-point,
			radius: .2pt,
			fill: rgb("f00"),
			stroke: none
		)
	}

}
