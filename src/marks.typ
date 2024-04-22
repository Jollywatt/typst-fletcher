#import "utils.typ": *
#import "deps.typ": cetz
#import cetz.draw



#let EDGE_ARGUMENT_SHORTHANDS = (
	"dashed": (dash: "dashed"),
	"dotted": (dash: "dotted"),
	"double": (extrude: (-2, +2)),
	"triple": (extrude: (-4, 0, +4)),
	"crossing": (crossing: true),
	"wave": (decorations: "wave"),
	"zigzag": (decorations: "zigzag"),
	"coil": (decorations: "coil"),
)


#let LINE_ALIASES = (
	"-": (:),
	"=": EDGE_ARGUMENT_SHORTHANDS.double,
	"==": EDGE_ARGUMENT_SHORTHANDS.triple,
	"--": EDGE_ARGUMENT_SHORTHANDS.dashed,
	"..": EDGE_ARGUMENT_SHORTHANDS.dotted,
	"~": EDGE_ARGUMENT_SHORTHANDS.wave,
)


#let MARKS = (

	head: (
		size: 7, // radius of curvature, multiples of stroke thickness
		sharpness: 24.7deg, // angle at vertex between central line and arrow's edge
		delta: 53.5deg, // angle spanned by arc of curved arrow edge

		tail-origin: mark => mark.tail-end - mark.size*mark.delta/2rad*(calc.cos(mark.sharpness) + calc.cos(mark.sharpness + mark.delta)),
		tail-end: mark => calc.min(..mark.extrude),

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
	),

	straight: (
		size: 8,
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
		}
	),

	solid: (
		inherit: "straight",

		tip-origin: 0,
		tip-end: mark => -0.5/calc.sin(mark.sharpness),
		tail-end: mark => -0.5/calc.sin(mark.sharpness),

		stroke: none,
		fill: auto,
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


	stealth: (
		size: 8,
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
		},
	),

	circle: (
		size: 3,

		tip-end: mark => -mark.size,
		tail-end: mark => mark.size,
		tip-origin: mark => mark.size,
		tail-origin: mark => -mark.size,

		fill: none,

		draw: mark => draw.circle((0,0), radius: mark.size, fill: mark.fill),
	),

	bar: (
		size: 4.9,
		angle: 90deg,
		draw: mark => draw.line(
			(mark.angle, -mark.size),
			(mark.angle, +mark.size),
		),
	),

	cross: (
		size: 4,
		angle: 45deg,
		draw: mark => {
			draw.line((+mark.angle, -mark.size), (+mark.angle, +mark.size))
			draw.line((-mark.angle, -mark.size), (-mark.angle, +mark.size))
		},
	),

	hook: (
		size: 2.88,
		rim: 0.85,
		tip-origin: mark => mark.size,
		draw: mark => {
			draw.arc(
				(0,0),
				start: -90deg,
				stop: +90deg,
				radius: mark.size,
				fill: none,
			)
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

	">>": (inherit: "head", extrude: (-3, 0), rev: false),
	"<<": (inherit: "head", extrude: (-3, 0), rev: true),

	">>>": (inherit: "head", extrude: (-6, -3, 0), rev: false),
	"<<<": (inherit: "head", extrude: (-6, -3, 0), rev: true),

	"|": (inherit: "bar"),
	"||": (inherit: "bar", extrude: (-3, 0)),
	"|||": (inherit: "bar", extrude: (-6, -3, 0)),

	"/": (inherit: "bar", angle: -60deg),
	"\\": (inherit: "bar", angle: +60deg),

	"x": (inherit: "cross"),
	"X": (inherit: "cross", size: 7),

	"o": (inherit: "circle"),
	"O": (inherit: "circle", size: 4),
	"*": (inherit: "circle", fill: auto),
	"@": (inherit: "circle", size: 4, fill: auto),

	"|>": (inherit: "solid", rev: false),
	"<|": (inherit: "solid", rev: true),

	"}>": (inherit: "stealth", rev: false),
	"<{": (inherit: "stealth", rev: true),

)

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

	let required-defaults = (
		flip: false,
		scale: 100%,
		extrude: (0,),
		tip-end: 0,
		tail-end: 0,
		tip-origin: 0,
		tail-origin: 0,
	)

	mark = required-defaults + defaults + mark

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

	let fill = mark.at("fill", default: auto)
	fill = map-auto(fill, map-auto(stroke.paint, black))
	let thickness = stroke.thickness

	let stroke = stroke-to-dict(stroke)

	stroke.dash = none

	if "stroke" in mark {
		if mark.stroke == none { stroke = none }
		else {
			stroke += mark.stroke
			stroke = as-stroke(stroke)
		}
	}

	if "draw" not in mark {
		panic(mark)
	}

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
			// draw.content((0,10), text(0.5em, red)[R])
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

		// if mark.at("tip", default: true) {
		// 	draw.content((0,0), text(0.5em, green)[tip])
		// } else {
		// 	draw.content((0,0), text(0.5em, orange)[tail])
		// }
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
			("tip-end",     +0.75, "0f0"),
			("tail-end",    -0.75, "f00"),
			("tip-origin",  +0.5,  "0ff"),
			("tail-origin", -0.5,  "f0f"),
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
			stroke: rgb("0f06") + t,
		)
		draw.line(
			(t*mark.tail-end, 0),
			(t*(max + l), 0),
			stroke: rgb("f006") + t,
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


#let interpret-marks(marks) = {
	marks = marks.enumerate().map(((i, mark)) => {
		resolve-mark(mark, defaults: (
			pos: i/calc.max(1, marks.len() - 1),
			rev: i == 0,
			// rev: false,
		))
	}).filter(mark => mark != none) // drop empty marks

	marks = marks.map(mark => {
		mark.tip = (mark.pos == 0) == mark.rev

		if mark.pos == 0 { mark.rev = not mark.rev }
		mark
	})


	assert(type(marks) == array)
	assert(marks.all(mark => type(mark) == dictionary), message: repr(marks))
	marks
}

/// Parse and interpret the marks argument provided to `edge()`. Returns a
/// dictionary of processed `edge()` arguments.
///
/// - arg (string, array):
/// Can be a string, (e.g. `"->"`, `"<=>"`), etc, or an array of marks.
/// A mark can be a string (e.g., `">"` or `"head"`, `"x"` or `"cross"`) or a dictionary containing the keys:
///   - `kind` (required) the mark name, e.g. `"solid"` or `"bar"`
///   - `pos` the position along the edge to place the mark, from 0 to 1
///   - `rev` whether to reverse the direction
///   - parameters specific to the kind of mark, e.g., `size` or `sharpness`
/// -> dictiony
#let interpret-marks-arg(arg) = {
	if type(arg) == array { return panic(marks: interpret-marks(arg)) }

	if type(arg) == symbol {
		if str(arg) in MARK_SYMBOL_ALIASES { arg = MARK_SYMBOL_ALIASES.at(arg) }
		else { panic("Unrecognised marks symbol '" + arg + "'.") }
	}

	assert(type(arg) == str)
	let text = arg

	let mark-names = MARKS.keys().sorted(key: i => -i.len())
	let LINES = LINE_ALIASES.keys().sorted(key: i => -i.len())

	let eat(arg, options) = {
		for option in options {
			if arg.starts-with(option) {
				return (arg.slice(option.len()), option)
			}
		}
		return (arg, none)
	}

	let marks = ()
	let lines = ()

	let mark
	let line
	let flip

	// first mark, [<]-x->>
	(text, mark) = eat(text, mark-names)

	// flip modifier, hook[']
	(text, flip) = eat(text, ("'",))
	if flip != none { mark += flip }

	marks.push(mark)

	let parse-error(suggestion) = panic(
		"Invalid marks shorthand '" + arg + "'. Try '" + suggestion + "'."
	)

	while true {
		// line, <[-]x->>
		(text, line) = eat(text, LINES)
		if line == none {
			let suggestion = arg.slice(0, -text.len()) + "-" + text
			parse-error(suggestion)
		}
		lines.push(line)

		// subsequent mark, <-[x]->>
		(text, mark) = eat(text, mark-names)

		// flip modifier, hook[']
		(text, flip) = eat(text, ("'",))
		if flip != none { mark += flip }

		marks.push(mark)

		if text == "" { break }
		if mark == none {
			// text remains that was not recognised as mark
			let suggestion = marks.intersperse(lines.at(0)).join()
			parse-error(suggestion)
		}
	}


	if lines.dedup().len() > 1 {
		// different line styles were mixed
		let suggestion = marks.intersperse(lines.at(0)).join()
		parse-error(suggestion)
	}
	let line = lines.at(0)


	// make classic math arrows slightly larger on double/triple stroked lines
	// if line == "=" {
	// 	marks = marks.map(mark => {
	// 		if mark != none and mark.kind == "head" {
	// 			mark += MARK_ALIASES.doublehead
	// 		}
	// 		mark
	// 	})
	// } else if line == "==" {
	// 	marks = marks.map(mark => {
	// 		if mark != none and mark.kind == "head" {
	// 			mark += MARK_ALIASES.triplehead
	// 		}
	// 		mark
	// 	})
	// }

	return (
		marks: interpret-marks(marks),
		..LINE_ALIASES.at(lines.at(0))
	)
}




#let cap-offset(mark, y) = {
	if mark.tip {
		mark.tip-end - mark.tip-origin
	} else {
		mark.tail-origin - mark.tail-end
	}
}


#let place-mark-on-curve(mark, path, stroke: 1pt + black) = {
	let ε = 1e-4

	// calculate velocity of parametrised path at point
	let point = path(mark.pos)
	let point-plus-ε = path(mark.pos + ε)
	let grad = vector-len(vector.sub(point-plus-ε, point))/ε
	if grad == 0pt { grad = ε*1pt }

	let outer-len = mark.at("tip-origin", default: 0) - mark.at("tail-origin", default: 0)
	let Δt = outer-len*stroke.thickness/grad
	if Δt == 0 { Δt = ε } // avoid Δt = 0 so the two points are distinct

	let t = lerp(Δt, 1, mark.pos)
	let head-point = path(t)
	let tail-point = path(t - Δt)

	let θ = vector-angle(vector.sub(head-point, tail-point))

	if mark.pos == 0 {
		mark.rev = not mark.rev
		// θ += 180deg
		// (head-point, tail-point) = (tail-point, head-point)
	}
	draw-mark(mark, origin: head-point, angle: θ, stroke: stroke)

	// draw.circle(
	// 	head-point,
	// 	radius: .2pt,
	// 	fill: red,
	// 	stroke: none
	// )
	// draw.circle(
	// 	tail-point,
	// 	radius: .2pt,
	// 	fill: blue,
	// 	stroke: none
	// )

}
