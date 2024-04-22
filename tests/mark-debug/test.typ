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


#let mark-debug(mark, stroke: 5pt) = {
	mark = resolve-mark(mark)
	stroke = fletcher.as-stroke(stroke)

	let t = stroke.thickness

	let mark-obj = draw.group({
		draw.scale(t/1cm)
		draw.set-style(
			stroke: stroke,
			fill: fletcher.map-auto(stroke.paint, black),
		)
		mark.draw
	})

	fletcher.cetz.canvas({
		// draw.grid((-1,-1), (+1,+1), stroke: 0.5pt + green)
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

#let demo-mark(mark, stroke: 2pt) = {
	stroke = fletcher.as-stroke(stroke)

	let t = stroke.thickness
	let mark-obj = draw.group({
		draw.scale(t/1cm)
		draw.set-style(
			stroke: stroke,
			fill: fletcher.map-auto(stroke.paint, black),
		)
		mark.draw
	})

	fletcher.cetz.canvas({
		let l = 3
		let dy = 0.75


		draw.line(
			(-mark.tip-stroke-end*t,0),
			(rel: (mark.tip-stroke-end*t, 0), to: (l,0)),
			stroke: stroke,
		)
		draw.group({
			draw.scale(x: -1)
			draw.translate((mark.tip-origin,0))
			mark-obj
		})
		draw.group({
			draw.translate((l,0))
			draw.translate((mark.tip-origin,0))
			mark-obj
		})

		draw.translate((0, -dy))

		draw.line((0,0), (l,0), stroke: stroke)
		draw.translate((0, -dy))

		let x = (mark.tail-stroke-end - mark.tail-origin)*t
		draw.line(
			(x,0),
			(rel: (-x, 0), to: (l,0)),
			stroke: stroke,
		)
		draw.group({
			draw.translate((-mark.tail-origin*t,0))
			mark-obj
		})
		draw.group({
			draw.translate((l,0))
			draw.scale(x: -1)
			draw.translate((-mark.tail-origin*t,0))
			mark-obj
		})
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
#demo-mark(resolve-mark(stealth))
