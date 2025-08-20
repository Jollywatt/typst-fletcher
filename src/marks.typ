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


/// Draw a mark at a given position and angle
///
/// - mark (dictionary): Mark object to draw. Must contain a `draw` entry.
/// - stroke (stroke): Default stroke style for the mark. The stroke's paint
///   is used as the default fill style. If the mark itself has `stroke`
///   entry, this takes precedence.
/// - origin (point): Coordinate of the origin in the mark's frame, `(0,0)`.
/// - angle (angle): Angle of the mark, `0deg` being $->$, counterclockwise.
#let draw-mark(
	mark,
	stroke: 1pt,
	origin: (0,0),
	angle: 0deg,
	debug: false,
) = {
	// mark = resolve-mark(mark)
	stroke = std.stroke(stroke)

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
		error("Mark object must contain `draw` or `inherit`; resolved to #0.", mark)
	}

  import cetz.draw

	draw.get-ctx(ctx => {
		draw.group({
			draw.set-style(
				stroke: stroke,
				fill: fill,
			)

			draw.translate(origin)
			draw.rotate(angle)
			draw.scale(t.to-absolute()/ctx.length*float(mark.scale))

			if mark.rev { draw.scale(x: -1) }
			if mark.flip { draw.scale(y: -1) }

			for e in mark.extrude {
				draw.group({
					draw.translate(x: e)
					mark.draw
				})
			}

			let is-tip = mark.at("pos", default: 1) != float(mark.rev)
			if debug-level(get-debug(ctx, debug), "mark") {
				let x = if is-tip { mark.tip-origin } else { mark.tail-origin }
				draw.line((0,0), (x,0), stroke: t + red.transparentize(20%))
				let x = if is-tip { mark.tip-end } else { mark.tail-end }
				draw.line((0,0), (x,0), stroke: t + blue.transparentize(20%))
				draw.circle((0,0), radius: 0.5, fill: white.transparentize(20%), stroke: none)
			}

			if debug-level(get-debug(ctx, debug), "mark.dots") or true {
				let m = if is-tip { (
					origin: mark.tip-origin,
					end: mark.tip-end,
					hang: mark.tip-hang
				) } else { (
					origin: mark.tail-origin,
					end: mark.tail-end,
					hang: mark.tail-hang
				) }

				if m.hang != none {
					draw.circle((m.hang,0), stroke: orange.mix(yellow) + t/6, fill: white, radius: 1/3)
				}
				draw.circle((0,0), stroke: green + t/6, fill: white, radius: 1/3)
				draw.circle((m.end,0), stroke: blue + t/6, fill: white, radius: 1/3)
				draw.circle((m.origin,0), stroke: red + t/6, fill: white, radius: 1/3)
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

#let tip-or-tail-properties(mark) = {
	let is-tip = mark.at("pos", default: 1) != float(mark.rev)
	if is-tip { (
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

		assert(m.hang != none)
		// assert(m.hang != 0)
		let angle
		if m.hang == 0 {
			angle = cetz.vector.angle2(inv-origin, cetz.util.apply-transform(inv-transform, point-info.direction))

		} else {
			let p2 = sample-pt((m.origin - m.hang)*t/ctx.length, reverse)
			draw.mark(origin, (0,0), "x", stroke: 0.2pt + blue)
			draw.mark(p2, (0,0), "x", stroke: 0.2pt + orange)
			angle = cetz.vector.angle2(origin, p2)
		}

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

#let test-mark(m, stroke: 4pt, length: auto, bend: 0deg, debug: 3) = {
	m = resolve-mark(m)
	let t = utils.get-thickness(stroke)

	let debug-level = debug-level.with(levels: (
		"dots": 1,
		"lines": 2,
		"labels": 3,
		"path": 1,
	))

	let annot(x, (y-min, y-max), label, color, layer: 1) = draw.on-layer(layer, {
		if debug-level(debug, "lines") {
			draw.line((x, y-min), (x, y-max), stroke: color + t/5)
		}
		if debug-level(debug, "dots") {
			draw.circle((x,0), stroke: color + t/10, fill: white, radius: t/5)
		}
		if debug-level(debug, "labels") {
			let a = if y-max > 0 { "south" } else { "north" }
			draw.content((x, y-max), text(color, size: 2*t, label), anchor: a, padding: 0.5)
		}
	})
		
	cetz.canvas(length: t, {
		import cetz.draw
		
		let mark-obj = draw-mark(m + (rev: false), stroke: stroke)

		draw.get-ctx(ctx => {
			// get size of mark
			let (bounds,) = cetz.process.many(ctx, mark-obj)
			let (low, high) = bounds
			let (w, h, ..) = cetz.vector.sub(high, low)
			
			let y = h/2 + 2
			let length = if length == auto { w + 20 } else { length/t }

			// left side is tail, right side is tip
			// if a mark is reversed, then just flip sides
			if m.rev { draw.scale(x: -1) }

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
						(m.tail-end - m.tail-origin,0),
						(length + m.tip-end - m.tip-origin,0),
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
					let tip-delta = (m.tip-end - m.tip-origin)/r*1rad
					let tail-delta = (m.tail-end - m.tail-origin)/r*1rad
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

				annot(m.origin, (+y,-y), raw(label + "-origin"), red, layer: -1)
				mark-obj
				annot(0, (-1,0), `0`, green)
				if m.hang != none {
					annot(m.hang, (0,2), raw(label + "-hang"), orange.mix(yellow))
				}
				annot(m.end, (0,y), raw(label + "-end"), blue)

			})

			draw-mark-with-annotations("tail", (
				origin: m.tail-origin,
				end: m.tail-end,
				hang: m.tail-hang,
				angle: +bend,
			))

			draw.translate(x: length)

			draw-mark-with-annotations("tip", (
				origin: m.tip-origin,
				end: m.tip-end,
				hang: m.tip-hang,
				angle: -bend,
			))

		})		
	})
}