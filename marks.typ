#import "utils.typ"
#import "deps.typ": cetz
#import "default-marks.typ": *
#import "parsing.typ"
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
)


#let apply-mark-inheritances(mark) = {
	// let marks = MARKS.get()
	let marks = DEFAULT_MARKS
	while "inherit" in mark {
		if mark.inherit.at(-1) == "'" {
			mark.flip = not mark.at("flip", default: false)
			mark.inherit = mark.inherit.slice(0, -1)
		}

		if mark.inherit not in marks {
			error("Mark inherits from #0 which is not defined.", repr(mark.inherit))
		}

		let parent = marks.at(mark.remove("inherit"))
		mark = parent + mark
	}
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
	mark = resolve-mark(mark)
	stroke = std.stroke(stroke)

	let thickness = utils.map-auto(stroke.thickness, 1pt)

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
			draw.scale(thickness.to-absolute()/ctx.length*float(mark.scale))

			if mark.rev { draw.scale(x: -1) }
			if mark.flip { draw.scale(y: -1) }

			for e in mark.extrude {
				draw.group({
					draw.translate(x: e)
					mark.draw
				})
			}

			if debug-level(get-debug(ctx, debug), "mark") {
				let x = if mark.pos != float(mark.rev) { mark.tip-origin } else { mark.tail-origin }
				draw.line((0,0), (x,0), stroke: thickness + red.transparentize(20%))
				let x = if mark.pos != float(mark.rev) { mark.tip-end } else { mark.tail-end }
				draw.line((0,0), (x,0), stroke: thickness + blue.transparentize(20%))
				draw.circle((0,0), radius: 0.5, fill: white.transparentize(20%), stroke: none)
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
  assert(obj-ctx.drawables.len() == 1)
  assert(obj-ctx.drawables.first().type == "path")
  return obj-ctx.drawables.first().segments
}

#let bip(coord, fill) = cetz.draw.on-layer(20, cetz.draw.circle(coord, radius: .5pt, fill: fill, stroke: none))

#let draw-with-marks-and-shrinking(ctx, obj, marks, stroke: 1pt) = {	
	let path = path-from-obj(ctx, obj)
	let obj-ctx = obj.first()(ctx)
	let t = utils.get-thickness(stroke).to-absolute()/ctx.length

	let end-marks = (0, 1).map(pos => marks.find(mark => mark.pos == pos))
	let mark-origins = end-marks.map(mark => {
		if mark == none { return 0 }
		if mark.pos != float(mark.rev) {
			mark.tip-origin*t
			// tgt acting as tip
			// rev src acting as tip
		} else {
			// rev tgt acting as tail
			// src acting as tail
			-mark.tail-origin*t
		}
	})
	let stroke-ends = end-marks.zip(mark-origins).map(((mark, origin)) => {
		if mark == none { return 0 }
		origin - if mark.pos != float(mark.rev) {
			mark.tip-end*t
		} else {
			-mark.tail-end*t
		}
	})
	

	let shortened-path = cetz.path-util.shorten-to(path, stroke-ends, snap-to: (none, none))
	obj-ctx.drawables.first().segments = shortened-path
	obj-ctx.drawables.first().stroke = stroke
	(ctx => obj-ctx,)

  let inv-transform = cetz.matrix.inverse(ctx.transform)
	let inv-origin = cetz.util.apply-transform(inv-transform, (0,0))

	for (mark, origin) in end-marks.zip(mark-origins) {
		if mark == none { continue }
		let rev = mark.pos == 1
		let point-info = cetz.path-util.point-at(path, origin, reverse: rev)
		let origin = cetz.util.apply-transform(inv-transform, point-info.point)
		let angle = cetz.vector.angle2(inv-origin, cetz.util.apply-transform(inv-transform, point-info.direction))
		if rev { angle += 180deg }
		draw-mark(mark, origin: origin, angle: angle, stroke: stroke)
	}

  for mark in marks {
		if mark.pos in (0, 1) { continue }
    let point-info = cetz.path-util.point-at(shortened-path, mark.pos*100%)
    let origin = cetz.util.apply-transform(inv-transform, point-info.point)
    let angle = cetz.vector.angle2((0,0), cetz.util.apply-transform(inv-transform, point-info.direction))
    draw-mark(mark, origin: origin, angle: angle, stroke: stroke)
  }
}



#let with-marks(obj, marks, shrink: true) = {
  let (marks,) = parsing.parse-mark-shorthand(marks)
  cetz.draw.get-ctx(ctx => {
		let marks = interpret-marks(marks)
		if shrink {
			draw-with-marks-and-shrinking(ctx, obj, marks)
		} else {
			draw-with-marks(ctx, obj, marks)
		}
  })
}