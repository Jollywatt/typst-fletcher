#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge
#import fletcher.cetz.draw

#let resolve-mark(mark) = {
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
	rev: false,
) = {
	let stroke = fletcher.stroke-to-dict(stroke)
	stroke += mark.at("stroke", default: none)
	stroke = fletcher.as-stroke(stroke)

	draw.group({
		draw.rotate(angle)
		draw.translate(origin)
		draw.scale(stroke.thickness/1cm)
		if rev {
			draw.translate(x: mark.tail-origin)
			draw.scale(x: -1)
		}
		draw.set-style(
			stroke: stroke,
			fill: fletcher.map-auto(stroke.paint, black),
		)
		mark.draw
	})
}


#let mark-debug(mark, stroke: 5pt) = {
	mark = resolve-mark(mark)
	stroke = fletcher.as-stroke(stroke)

	let t = stroke.thickness

	let mark-obj = draw-mark(mark, stroke: stroke)

	fletcher.cetz.canvas({

		mark-obj

		for (i, (x, label, y, color)) in (
			(mark.tip-stroke-end, "tip stroke end", +0.75, "0f0"),
			(mark.tail-stroke-end, "tail stroke end", -0.75, "f0f"),
			(mark.tip-origin, "tip origin", +0.5, "f00"),
			(mark.tail-origin, "tail origin", -0.5, "0ff"),
		).enumerate() {
			let c = rgb(color)
			draw.line(
				(t*x, 0),
				(t*x, y),
				stroke: 0.5pt + c,
			)
			draw.content(
				(t*x, y),
				pad(2pt, text(0.5em, fill: c, label)),
				anchor: if y < 0 { "north" } else { "south" },
			)
		}

	})
}

#let mark-demo(mark, stroke: 2pt) = {
	stroke = fletcher.as-stroke(stroke)

	let t = stroke.thickness
	let mark-obj = draw-mark(mark, stroke: stroke)

	fletcher.cetz.canvas({
		let l = 3
		let dy = 1

		for x in (0, l) {
			draw.line(
				(x, +0.5*dy),
				(x, -1.5*dy),
				stroke: red.transparentize(50%) + 0.5pt,
			)
		}

		let x = -mark.tip-stroke-end*t
		draw.line(
			(x, 0),
			(rel: (-x, 0), to: (l, 0)),
			stroke: stroke,
		)

		draw-mark(
			mark,
			stroke: stroke,
			origin: (mark.tip-origin, 0),
			angle: 180deg,
		)
		draw-mark(
			mark,
			stroke: stroke,
			origin: (l - mark.tip-origin, 0),
			angle: 0deg,
		)

		draw.translate((0, -dy))

		let x = (mark.tail-stroke-end - mark.tail-origin)*t
		draw.line(
			(x, 0),
			(rel: (-x, 0), to: (l, 0)),
			stroke: stroke,
		)

		draw-mark(
			mark,
			stroke: stroke,
			origin: (0,0),
			angle: 180deg,
			rev: true
		)
		draw-mark(
			mark,
			stroke: stroke,
			origin: (l,0),
			angle: 0deg,
			rev: true
		)

	})
}

mark debug

#let stealth = (
	size: 5,
	stealth: 0.3,
	angle: 25deg,
	tip-origin: 0,
	tail-origin: mark => mark.size*(mark.stealth/2 - 1)*calc.cos(mark.angle),
	tip-stroke-end: mark => mark.size*(mark.stealth - 1)*calc.cos(mark.angle),
	tail-stroke-end: mark => -mark.size*calc.tan(mark.angle)/2,
	draw: mark => {
		draw.line(
			(0,0),
			(180deg + mark.angle, mark.size),
			(mark.tip-stroke-end, 0),
			(180deg - mark.angle, mark.size),
			stroke: none,
			close: true,
		)
	}
)


#mark-debug(resolve-mark(stealth))
#mark-demo(resolve-mark(stealth))

#let twohead = (
	stroke: (cap: "round"),

	size: 7, // radius of curvature, multiples of stroke thickness
	sharpness: 24.7deg, // angle at vertex between central line and arrow's edge
	delta: 53.5deg, // angle spanned by arc of curved arrow edge
	outer-len: 4,
	flip: +1,
	extrude: (-3, 0),

	tip-origin: 0,
	tip-stroke-end: 0,
	tail-stroke-end: mark => calc.min(..mark.extrude),
	tail-origin: mark => mark.tail-stroke-end - mark.size*mark.delta/2rad*(calc.cos(mark.sharpness) + calc.cos(mark.sharpness + mark.delta)),

	draw: mark => {
		for e in mark.extrude {
			for flip in (+1, -1) {
				draw.arc(
					(e, 0),
					radius: mark.size,
					start: flip*(90deg + mark.sharpness),
					delta: flip*mark.delta,
					fill: none,
				)
			}
		}
	}
)

#mark-debug(resolve-mark(twohead))
#mark-demo(resolve-mark(twohead))

