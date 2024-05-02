#import "utils.typ": *
#import "deps.typ": cetz
#import cetz.draw
#import "default-marks.typ": *

#let MARK_REQUIRED_DEFAULTS = (
	rev: false,
	flip: false,
	scale: 100%,
	extrude: (0,),
	tip-end: 0,
	tail-end: 0,
	tip-origin: 0,
	tail-origin: 0,
)





/// For a given mark, determine where that the stroke should terminate at,
/// relative to the mark's origin point, as a function of the shift.
///
/// Imagine the tip-origin of the mark is at $(x, y) = (0, 0)$. A stroke along
/// the line $y = "shift"$ coming from $x = -oo$ terminates at $x = "offset"$, where
/// $"offset"$ is the result of this function.
/// Units are in multiples of stroke thickness.
///
/// This is used to correctly implement multi-stroke marks, e.g.,
/// #diagram(edge("<==>")). The function `mark-debug()` can help visualise a
/// mark's cap offset.
///
/// #example(`fletcher.mark-debug("O")`)
///
/// The dashed green line shows the stroke tip end as a function of $y$, and the
/// dashed red line shows where the stroke ends if the mark is acting as a tail.
#let cap-offset(mark, shift) = {
	let o = 0
	let scale = float(mark.scale)
	if "cap-offset" in mark {
		o = (mark.cap-offset)(mark, shift/scale)
	}
	o += if mark.tip { mark.tip-end } else { mark.tail-end }
	o*scale

}



#let apply-mark-inheritances(mark) = {
	let marks = MARKS.get()
	while "inherit" in mark {

		if mark.inherit.at(-1) == "'" {
			mark.flip = not mark.at("flip", default: false)
			mark.inherit = mark.inherit.slice(0, -1)
		}

		assert(mark.inherit in marks, message: "Mark style " + repr(mark.inherit) + " not defined.")

		let parent = marks.at(mark.remove("inherit"))
		mark = parent + mark
	}
	mark
}



/// Resolve a mark dictionary by applying inheritance, adding any required entries, and evaluating any closure entries.
///
/// #example(```
/// context fletcher.resolve-mark((
/// 	a: 1,
/// 	b: 2,
/// 	c: mark => mark.a + mark.b,
/// ))
/// ```)
///
#let resolve-mark(mark, defaults: (:)) = {
	if mark == none { return none }

	if type(mark) == str { mark = (inherit: mark) }

	mark = apply-mark-inheritances(mark)

	// be careful to preserve the insertion order of mark
	// as this defines the evaluation order of mark parameters
	for (k, v) in MARK_REQUIRED_DEFAULTS + defaults {
		if k not in mark {
			mark.insert(k, v)
		}
	}

	for (key, value) in mark {
		if key == "cap-offset" { continue }

		if type(value) == function {
			mark.at(key) = value(mark)
		}
	}

	mark
}


/// Draw a mark at a given potition and angle
///
/// - mark (dictionary): Mark object to draw. Must contain a `draw` entry.
/// - stroke (stroke): Stroke style for the mark. The stroke's paint is used as
///   the defauly fill style.
/// - origin (point): Coordinate of the mark's origin (as defined by 
///   `tip-origin` or `tail-origin`).
/// - angle (angle): Angle of the mark, `0deg` being $->$, counterclockwise.
/// - debug (bool): Whether to draw the origin points.
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

	assert("draw" in mark, message: repr(mark))

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

/// Visualise a mark's anatomy.
///
/// #example(```
/// context {
/// 	let mark = fletcher.MARKS.get().stealth
/// 	// make a wide stealth arrow
/// 	mark += (angle: 45deg)
/// 	fletcher.mark-debug(mark)
/// }
/// ```)
///
/// - Green/left stroke: the edge's stroke when the mark is at the tip.
/// - Red/right stroke: edge's stroke if the mark is at the start acting as a
///   tail.
/// - Blue-white dot: the origin point $(0, 0)$ in the mark's coordinate frame.
/// - `tip-origin`: the $x$-coordinate of the point of the mark's tip.
/// - `tail-origin`: the $x$-coordinate of the mark's tip when it is acting as a
///   reversed tail mark.
/// - `tip-end`: The $x$-coordinate of the end point of the edge's stroke (green
///   stroke).
/// - `tail-end`: The $x$-coordinate of the end point of the edge's stroke when
///   acting as a tail mark (red stroke).
/// - Dashed green/red lines: The stroke end points as a function of $y$. This
///   is controlled by the special `cap-offset` mark property and is used for
///   multi-stroke effects like #diagram(edge(">==>")). See `cap-offset()`.
///
/// This is mainly useful for designing your own marks.
///
/// - mark (string, dictionary): The mark name or dictionary.
/// - stroke (stroke): The stroke style, whose paint and thickness applies both
///   to the stroke and the mark itself.
///
/// - show-labels (bool): Whether to label the tip/tail origin/end points.
/// - show-offsets (bool): Whether to visualise the `cap-offset()` values.
/// - offset-range (number): The span above and below the stroke line to plot
///   the cap offsets, in multiples of the stroke's thickness.
#let mark-debug(
	mark,
	stroke: 5pt,
	show-labels: true,
	show-offsets: true,
	offset-range: 6,
) = context {
	let mark = resolve-mark(mark)
	let stroke = as-stroke(stroke)

	let t = stroke.thickness
	let scale = float(mark.scale)


	cetz.canvas({

		draw-mark(mark, stroke: stroke)

		if mark.at("rev", default: false) {
			draw.scale(x: -1)
			draw.translate(x: -t*mark.tail-origin*scale)
		} else {
			draw.translate(x: -t*mark.tip-origin*scale)
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
				let x = mark.at(item)*float(mark.scale)
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
			radius: t/4,
			stroke: rgb("00f") + 1pt,
			fill: white,
		)
	})
}

#let mark-demo(
	mark,
	stroke: 2pt,
	width: 3cm,
	height: 1cm,
) = context {
	let mark = resolve-mark(mark)
	let stroke = as-stroke(stroke)

	let t = stroke.thickness*float(mark.scale)

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
	mark-length *= float(mark.scale)
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
