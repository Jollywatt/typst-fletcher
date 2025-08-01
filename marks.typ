#import "utils.typ"
#import "deps.typ": cetz
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


#let apply-mark-inheritances(mark) = {
	let marks = MARKS.get()
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
/// - stroke (stroke): Stroke style for the mark. The stroke's paint is used as
///   the default fill style.
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
	stroke = utils.as-stroke(stroke)

	let thickness = stroke.thickness

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



#let draw-marks-on-path(ctx, obj, marks) = {
	let marks = interpret-marks(marks)
  let (segments, close) = utils.get-segments(ctx, obj)
  let inv-transform = cetz.matrix.inverse(ctx.transform)

  for mark in marks {
    let point-info = cetz.path-util.point-at(segments, mark.pos*100%)
    let origin = cetz.matrix.mul4x4-vec3(inv-transform, point-info.point)
    let angle = cetz.vector.angle2((0,0), cetz.matrix.mul4x4-vec3(inv-transform, point-info.direction))

    draw-mark(mark, origin: origin, angle: angle, stroke: ctx.style.stroke)
  }
}


