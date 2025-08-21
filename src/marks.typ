#import "utils.typ"
#import "deps.typ": cetz
#import "default-marks.typ": *
#import "parsing.typ"
#import "paths.typ"
#import "debug.typ": get-debug, debug-level

#let MARK_REQUIRED_DEFAULTS = (
	rev: false,
	flip: false,
	scale: 100%,
	extrude: (0,),
	tip-end: 0,
	tail-end: 0,
	tip-origin: 0,
	tail-origin: 0,
	tip-hang: none,
	tail-hang: none,
)


#let apply-mark-inheritances(mark) = {
	// let marks = MARKS.get()
	let marks = DEFAULT_MARKS
	let ancestor = none
	while "inherit" in mark {
		if mark.inherit.ends-with("'") {
			mark.flip = not mark.at("flip", default: false)
			mark.inherit = mark.inherit.slice(0, -1)
		}

		if mark.inherit not in marks {
			utils.error("Mark inherits from #0 which is not defined.", repr(mark.inherit))
		}


		if ancestor == none { ancestor = mark.inherit }
		let parent = marks.at(mark.remove("inherit"))
		mark = parent + mark
	}
	if ancestor != none { mark = (kind: ancestor) + mark }
	return mark
}





/// Resolve a mark dictionary by applying inheritance, adding any required
/// entries, and evaluating any closure entries.
///
/// ```example
/// #context fletcher.resolve-mark((
/// 	a: 1,
/// 	b: 2,
/// 	c: mark => mark.a + mark.b,
/// ))
/// ```
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

	return mark
}


#let interpret-marks(marks) = {
	marks = marks.enumerate().map(((i, mark)) => {
		resolve-mark(mark, defaults: (
			pos: i/calc.max(1, marks.len() - 1),
			rev: i == 0,
		))
	}).filter(mark => mark != none) // drop empty marks

	marks = marks.map(mark => {
		mark.tip = (mark.pos == 0) == mark.rev
		if (mark.pos not in (0, 1)) { mark.tip = none }
		mark
	})

	marks
}

#let tip-or-tail-properties(mark, tip: auto) = {
	if tip == auto {
		tip = mark.at("pos", default: 1) != float(mark.rev)
	}
	if tip { (
		is-tip: true,
		origin: mark.tip-origin,
		end: mark.tip-end,
		hang: mark.tip-hang
	) } else { (
		is-tip: false,
		origin: mark.tail-origin,
		end: mark.tail-end,
		hang: mark.tail-hang
	) }
}

/// Draw a mark at a given position and angle
///
/// - mark (dictionary): Mark object to draw. Must contain a `draw` entry.
/// - stroke (stroke): Default stroke style for the mark. The stroke's paint
///   is used as the default fill style. If the mark itself has `stroke`
///   entry, this takes precedence.
/// - origin (point): Coordinate of the origin in the mark's frame, `(0,0)`.
/// - anchor ("origin" | "end" | "hang"): Which mark center to use as the origin.
///   These correspond to the marks `tip-` and `tail-` properties, e.g., `tip-origin`,
///   depending on whether the mark is acting as a tip (`pos: 1` and `rev: false` or
/// 	`pos: 0` and `rev: true`) or a tail (`pos: 0` and `rev: false` or `pos: 1` and `rev: true`).
/// - angle (angle): Angle of the mark, `0deg` being $->$, counterclockwise.
#let draw-mark(
	mark,
	stroke: 1pt,
	origin: (0,0),
	angle: 0deg,
	anchor: auto,
	as-tip: auto,
	debug: false,
) = {
	// mark = resolve-mark(mark)
	stroke = std.stroke(stroke)

	if as-tip == auto {
		as-tip = mark.at("pos", default: 1) != float(mark.rev)
	}

	if anchor == auto {
		anchor = if as-tip { "origin" } else { "end" }
	}

	let t = utils.map-auto(stroke.thickness, 1pt)

	let fill = mark.at("fill", default: auto)
	fill = utils.map-auto(fill, stroke.paint)
	fill = utils.map-auto(fill, black)

	let stroke = utils.stroke-to-dict(stroke)
	stroke.dash = none

	if "stroke" in mark {
		if mark.stroke == none { stroke = none }
		else if mark.stroke == auto { }
		else { stroke += utils.stroke-to-dict(mark.stroke) }
	}

	if "draw" not in mark {
		utils.error("Mark object must contain `draw` or `inherit`; resolved to #0.", mark)
	}

  import cetz.draw

	draw.get-ctx(ctx => {
		let debug = get-debug(ctx, debug)

		draw.group({
			draw.set-style(
				stroke: stroke,
				fill: fill,
			)

			let m = tip-or-tail-properties(mark, tip: as-tip)

			draw.translate(origin)
			draw.scale(t.to-absolute()/ctx.length*float(mark.scale))
			draw.rotate(angle)

			if mark.rev { draw.scale(x: -1) }
			if mark.flip { draw.scale(y: -1) }

			if anchor != "zero" {
				draw.translate(x: -m.at(anchor))
			}

			for e in mark.extrude {
				draw.group({
					draw.translate(x: e)
					mark.draw
				})
			}

			// if debug-level(get-debug(ctx, debug), "mark.bands") {
			// 	let x = if as-tip { mark.tip-origin } else { mark.tail-origin }
			// 	draw.line((0,0), (x,0), stroke: t + red.transparentize(20%))
			// 	let x = if as-tip { mark.tip-end } else { mark.tail-end }
			// 	draw.line((0,0), (x,0), stroke: t + blue.transparentize(20%))
			// 	draw.circle((0,0), radius: 0.5, fill: white.transparentize(20%), stroke: none)
			// }

			if debug-level(debug, "mark") {
				let m = if as-tip { (
					origin: mark.tip-origin,
					end: mark.tip-end,
					hang: mark.tip-hang
				) } else { (
					origin: mark.tail-origin,
					end: mark.tail-end,
					hang: mark.tail-hang
				) }
				let m = tip-or-tail-properties(mark, tip: as-tip)

				if debug-level(debug, "mark.dots") {
					draw.on-layer(1, {
						let dot(x, r, ..args) = draw.circle((x,0), radius: r, stroke: none, ..args)

						dot(m.origin, 1/2, fill: white) // red origin bg
						if m.hang != none { dot(m.hang, 1/2, fill: white) } // green hang bg
						dot(m.end, 3/8, stroke: blue + t/4, fill: white) // blue end
						dot(m.origin, 1/4, fill: red) // red origin fg
						if m.hang != none { dot(m.hang, 1/4, fill: green) } // green hang fg
					})
				}
			}
		})
	})

}



#let draw-with-marks(ctx, obj, marks, stroke: 1pt) = {

	cetz.draw.set-style(stroke: stroke)
	obj

	let marks = interpret-marks(marks)
  let (segments, close) = utils.get-segments(ctx, obj)
  let inv-transform = cetz.matrix.inverse(ctx.transform)
	let inv-origin = cetz.util.apply-transform(inv-transform, (0,0))

  for mark in marks {
    let point-info = cetz.path-util.point-at(segments, mark.pos*100%)
    let origin = cetz.util.apply-transform(inv-transform, point-info.point)
    let angle = cetz.vector.angle2(inv-origin, cetz.util.apply-transform(inv-transform, point-info.direction))

    draw-mark(mark, origin: origin, angle: angle, stroke: stroke)
  }
}

#let path-from-obj(ctx, obj) = {
  assert(type(obj) == array)
  assert(obj.len() == 1)
  let obj-ctx = obj.first()(ctx)
	let drawables = obj-ctx.drawables
	if type(drawables) == array {
		assert.eq(drawables.len(), 1)
		drawables = drawables.first()
	}
  assert(drawables.type == "path")
  return drawables.segments
}

#let shrink-factor-from-mark(mark, extrude) = {
	if mark == none { return (0, extrude.map(_ => 0)) }

	// a mark is acting as a tip if it is at the end of the edge and not reversed,
	// or at the start of the edge and reversed.
	let acting-as-tip = mark.pos != float(mark.rev)
	
	let origin = if acting-as-tip { mark.tip-origin } else { -mark.tail-origin }
	let end = if acting-as-tip { mark.tip-end } else { -mark.tail-end }

	let stroke-ends = extrude.map(e => {
		let cap = if "cap-offset" in mark { (mark.cap-offset)(mark, e) } else { 0 }
		if not acting-as-tip { cap *= -1 }
		origin - end - cap
	})
	
	return (origin, stroke-ends)
}



/// This does a few things:
/// 
/// Takes an edge path `obj` and:
/// - calculates path shortening factor given end marks and extrusion
/// - draws extruded and shortened path
/// - draws end marks with origin shift
/// - draws internal marks
#let draw-with-marks-and-extrusion(ctx, obj, marks, stroke: 1pt, extrude: (0,)) = {	
	let path = path-from-obj(ctx, obj)
	let obj-ctx = obj.first()(ctx)
	let t = utils.get-thickness(stroke).to-absolute()

	let (i-mark, o-mark) = (0, 1).map(pos => marks.find(mark => mark.pos == pos))
	let (i-origin, i-shorten) = shrink-factor-from-mark(i-mark, extrude)
	let (o-origin, o-shorten) = shrink-factor-from-mark(o-mark, extrude)

	let shortened = paths.extrude-and-shorten(
		obj,
		extrude: extrude,
		shorten-start: i-shorten,
		shorten-end: o-shorten,
		stroke: stroke,
	)

	shortened

  let inv-transform = cetz.matrix.inverse(ctx.transform)
	let inv-origin = cetz.util.apply-transform(inv-transform, (0,0))

	let sample-pt(t, reverse) = {
		let p = cetz.path-util.point-at(path, t, reverse: reverse, samples: 60)
		cetz.util.apply-transform(inv-transform, p.point)
	}

	let draw-mark-on-path(mark, pos, reverse: false) = {
    let point-info = cetz.path-util.point-at(path, pos, reverse: reverse)
    let origin = cetz.util.apply-transform(inv-transform, point-info.point)

		let m = tip-or-tail-properties(mark)

		// assert(m.hang != 0)
		let angle
		if m.hang == none or m.hang == 0 {
			angle = cetz.vector.angle2(inv-origin, cetz.util.apply-transform(inv-transform, point-info.direction))

		} else {
			let p2 = sample-pt((m.origin - m.hang)*t/ctx.length, reverse)
			draw.mark(p2, (0,0), "x", stroke: 0.2pt + orange)
			angle = cetz.vector.angle2(origin, p2)
		}
		draw.mark(origin, (0,0), "x", stroke: 0.2pt + blue)

		if reverse { angle += 180deg }
    draw-mark(mark, origin: origin, angle: angle, stroke: stroke)


	}

	if i-mark != none { draw-mark-on-path(i-mark, i-origin*t/ctx.length) }
	if o-mark != none { draw-mark-on-path(o-mark, o-origin*t/ctx.length, reverse: true) }

  for mark in marks {
		if mark.pos in (0, 1) { continue }
		draw-mark-on-path(mark, mark.pos*100%)
  }
}

#let bip(pos, color) = cetz.draw.circle(pos, fill: color.transparentize(50%), radius: 1pt, stroke: none)


#let draw-with-marks-and-extrusion(
	ctx,
	obj,
	marks,
	stroke: auto,
	extrude: (0,),
	/// Whether to enable mark angle correction on curved paths. -> bool
	mark-swing: true,
	debug: false,
) = {
	
	assert(marks.all(m => "pos" in m))

	assert.eq(obj.len(), 1)
	let (ctx, drawables,) = cetz.process.element(ctx, obj.first())
	assert.eq(drawables.len(), 1)
	let path = drawables.first().segments

	if stroke == auto { stroke = drawables.first().stroke }
	else { 
		stroke = utils.fold-strokes(drawables.first().stroke, stroke)
	}
	let t = utils.get-thickness(stroke).to-absolute()/ctx.length

	let inv-transform = cetz.matrix.inverse(ctx.transform)
	let inv-origin = cetz.util.apply-transform(inv-transform, (0.,0.,0.))
	let sample-pt(t, reverse) = {
		let info = cetz.path-util.point-at(path, t, reverse: reverse)
		let pt = cetz.util.apply-transform(inv-transform, info.point)
		let dir = cetz.vector.angle2(cetz.util.apply-transform(inv-transform, info.direction), inv-origin)
		(pt, dir)
	}

	let terminal-mark(mark, at-end) = {
		if mark == none { return (none, 0) }

		let m = tip-or-tail-properties(mark)

		// tip marks pivot around the path end (tip-origin)
		// tail marks pivot around the stroke end (tail-end)
		let pivot = if m.is-tip { 0 } else { m.end - m.origin }

		// tip marks swing towards the stroke end (tip-end)
		// tail marks swing towards the path end (tail-origin)
		// both swing toward the hang point if specified (tip/tail-hang)
		let swing = if m.hang == none {
			if m.is-tip { m.end - m.origin } else { 0 }
		} else { m.hang - m.origin }

		swing *= if m.is-tip { -1 } else { +1 }

		let swing-pt = sample-pt(swing*t, at-end).first()
		let (pivot-pt, dir) = sample-pt(pivot*t, at-end)

		let angle = (
			if pivot == swing { dir }
			else { cetz.vector.angle2(pivot-pt, swing-pt) }
		)

		if swing <= pivot { angle += 180deg }
		if at-end { angle += 180deg }

		let drawn = draw-mark(
			mark,
			origin: pivot-pt,
			angle: angle,
			as-tip: m.is-tip,
			stroke: stroke,
			debug: debug
		)

		let shorten-by = m.end - m.origin
		if m.is-tip { shorten-by *= -1}

		shorten-by = extrude.map(e => {
			let end = if "cap-offset" in (mark) {
				(mark.cap-offset)(mark, e) + m.end
			} else {
				m.end
			}
			let s = end - m.origin
			if m.is-tip { s *= -1 }
			return s
		})

		return (drawn, shorten-by)
	}

	let src-mark = marks.find(mark => mark.pos == 0)
	let tgt-mark = marks.find(mark => mark.pos == 1)

	let (src-mark-obj, shorten-start) = terminal-mark(src-mark, false)
	let (tgt-mark-obj, shorten-end) = terminal-mark(tgt-mark, true)


	paths.extrude-and-shorten(
		obj,
		shorten-start: shorten-start,
		shorten-end: shorten-end,
		stroke: stroke,
		extrude: extrude,
	)

	src-mark-obj
	tgt-mark-obj
}



#let with-marks(obj, marks, shrink: true) = {
  let (marks, options) = parsing.parse-mark-shorthand(marks)
  let extrude = options.at("extrude", default: (0,))
  cetz.draw.get-ctx(ctx => {
		let marks = interpret-marks(marks)
		if shrink {
			draw-with-marks-and-extrusion(ctx, obj, marks, extrude: extrude)
		} else {
			draw-with-marks(ctx, obj, marks)
		}
  })
}

#let test-mark(mark, stroke: 4pt, length: auto, bend: 0deg, debug: 3) = {
	mark = (pos: 1, rev: false) + resolve-mark(mark)

	let t = utils.get-thickness(stroke)

	let debug-level = debug-level.with(levels: (
		"dots": 1,
		"lines": 2,
		"labels": 3,
		"path": 1,
	))

		
	cetz.canvas(length: t, {
		import cetz.draw

		let mark-obj = draw-mark(mark, stroke: stroke)

		draw.get-ctx(ctx => {
			// get size of mark
			let (bounds,) = cetz.process.many(ctx, mark-obj)
			let (low, high) = bounds
			let (w, h, ..) = cetz.vector.sub(high, low)
			
			let y = calc.max(4, h/2) + 2
			let length = if length == auto { w + 20 } else { length/t }

			// left side is tail, right side is tip
			// if a mark is reversed, then just flip sides
			if mark.rev { draw.scale(x: -1) }

			// draw the edge stroke
			draw.group({
				let s1 = (thickness: t/8, paint: blue.transparentize(50%), dash: "dashed")
				let s2 = (thickness: t, paint: blue.transparentize(30%))
				if bend == 0deg {
					// straight line
					if debug-level(debug, "path") {
						draw.line((0,0), (length,0), stroke: s1)
					}
					draw.on-layer(1, draw.line(
						(mark.tail-end - mark.tail-origin,0),
						(length + mark.tip-end - mark.tip-origin,0),
						stroke: s2,
					))
				} else {
					// bent arc
					let r = length/2/calc.sin(bend)
					if debug-level(debug, "path") {
						draw.arc(
							(0,0),
							start: 90deg + bend,
							stop: 90deg - bend,
							radius: r,
							stroke: s1,
						)
					}
					let tip-delta = (mark.tip-end - mark.tip-origin)/r*1rad
					let tail-delta = (mark.tail-end - mark.tail-origin)/r*1rad
					draw.on-layer(1, draw.arc(
						(length/2,-length/2/calc.tan(bend)),
						anchor: "origin",
						start: 90deg + bend - tail-delta,
						stop: 90deg - bend - tip-delta,
						radius: r,
						stroke: s2,
					))
				}
			})

			// draw tail and tip marks

			let ruler(x, (y-min, y-max), label, color) = {
				if debug-level(debug, "lines") {
					draw.line((x, y-min), (x, y-max), stroke: color + t/6)
				}
				if debug-level(debug, "labels") {
					let a = if y-max > 0 { "south" } else { "north" }
					let body = text(color, size: 2*t, label)
					draw.content((x, y-max), body, anchor: a, padding: 0.25)
				}
			}

			let draw-mark-with-annotations(label, m) = draw.group({
				if bend == 0deg {
					draw.translate(x: -m.origin)
				} else {
					draw.rotate(m.angle)
					let radius = length/2/calc.sin(bend)
					draw.translate(y: -radius)
					draw.rotate(1rad*(m.origin - m.end)/radius)
					draw.translate(y: +radius)
					draw.translate(x: -m.end)

					// apply mark hang/swing angle correction
					if m.hang != none {
						let swing = calc.asin((m.end - m.hang)/(2*radius))
						draw.rotate(swing, origin: (m.end, 0))
					}
				}

				ruler(m.origin, (+y,-y), `origin`, red)

				draw-mark(
					mark,
					stroke: stroke,
					angle: if mark.rev { 180deg } else { 0deg },
					as-tip: label == "tip",
					debug: if debug-level(debug, "dots") { "mark.dots" },
					anchor: "zero",
				)

				if m.hang != none { ruler(m.hang, (0,-4), `hang`, green) }
				ruler(m.end, (0,y), `end`, blue)
				
				draw.circle((0,0), radius: t/4, fill: gray, stroke: none)
				ruler(0, (0,-2), `zero`, gray) // coordinate origin

			})

			if debug-level(debug, "labels") {
				let a = if mark.rev { "west" } else { "east" }
				draw.floating(draw.content((0,0), text(2*t, `tail`), anchor: a, padding: 1))
			}
			draw-mark-with-annotations("tail", (
				origin: mark.tail-origin,
				end: mark.tail-end,
				hang: mark.tail-hang,
				angle: +bend,
			))

			draw.translate(x: length)

			if debug-level(debug, "labels") {
				let a = if mark.rev { "east" } else { "west" }
				draw.floating(draw.content((0,0), text(2*t, `tip`), anchor: a, padding: 1))
			}

			draw-mark-with-annotations("tip", (
				origin: mark.tip-origin,
				end: mark.tip-end,
				hang: mark.tip-hang,
				angle: -bend,
			))

		})		
	})
}