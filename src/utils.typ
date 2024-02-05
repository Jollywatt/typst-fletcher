#import calc: floor, ceil, min, max
#import "@preview/cetz:0.2.0" as cetz: draw, vector

#let DEBUG_COLOR = rgb("f008")

#let default(..args) = {
	for arg in args.pos() {
		if arg != auto { return arg }
	}
	auto
}

#let as-stroke(obj) = {
	if obj == none or obj == auto { obj }
	else { stroke(obj) }
}

#let stroke-to-dict(s) = {
	let s = as-stroke(s)
	let d = (
		paint: s.paint,
		thickness: s.thickness,
		cap: s.cap,
		join: s.join,
		dash: s.dash,
		miter-limit: s.miter-limit,
	)

	for (key, value) in d {
		if value == auto {
			let _ = d.remove(key)
		}
	}

	d
}

#let zip(a, ..others) = if others.pos().len() == 0 {
	a.map(i => (i,))
} else {
	a.zip(..others)
}

#let to-abs-length(len, em-size) = {
	len.abs + len.em*em-size
}

#let sign(x) = x/calc.abs(x)

#let min-max(array) = (calc.min(..array), calc.max(..array))
#let cumsum(array) = {
	let sum = array.at(0)
	for i in range(1, array.len()) {
		sum += array.at(i)
		array.at(i) = sum
	}
	array
}

#let vector-len((x, y)) = 1pt*calc.sqrt((x/1pt)*(x/1pt) + (y/1pt)*(y/1pt))
#let vector-set-len(len, v) = vector.scale(v, len/vector-len(v))
#let vector-unitless(v) = v.map(x => if type(x) == length { x.pt() } else { x })
#let vector-polar(r, θ) = (r*calc.cos(θ), r*calc.sin(θ))
#let vector-angle(v) = calc.atan2(..vector-unitless(v))
#let vector-2d((x, y, ..z)) = (x, y)

#let element-wise-mul(a, b) = a.zip(b).map(((i, j)) => i*j)

#let lerp(a, b, t) = a*(1 - t) + b*t
#let lerp-at(a, t) = {
	let max-index = a.len() - 1
	lerp(
		a.at(calc.clamp(floor(t), 0, max-index)),
		a.at(calc.clamp(ceil(t), 0, max-index)),
		calc.fract(t),
	)
}

// Ensure angle is in range 0deg <= θ < 360deg
#let wrap-angle-360(θ) = calc.rem-euclid(θ/360deg, 1)*360deg

// Ensure angle is in range -180deg <= θ <= 180deg
#let wrap-angle-180(θ) = (θ/360deg - calc.round(θ/360deg))*360deg

#let angle-to-anchor(θ) = {
	let i = calc.rem(8*θ/1rad/calc.tau, 8)
	(
		// "right",
		// "top-right",
		// "top",
		// "top-left",
		// "left",
		// "bottom-left",
		// "bottom",
		// "bottom-right",
	  "east",
	  "north-east",
	  "north",
	  "north-west",
	  "west",
	  "south-west",
	  "south",
	  "south-east",
	).at(int(calc.round(i)))

}

#let rect-at(origin, size) = (-1, +1).map(dir => {
	vector.add(origin, vector.scale(size, dir))
})

#let bounding-rect(points) = {
  let (xs, ys) = array.zip(..points)
  let p1 = (calc.min(..xs), calc.min(..ys))
  let p2 = (calc.max(..xs), calc.max(..ys))
  (
    center: vector.scale(vector.add(p1, p2), 0.5),
    size: vector.sub(p2, p1)
  )
}

#let rect-edges((x0, y0), (x1, y1)) = (
  ((x0, y0), (x1, y0)),
  ((x1, y0), (x1, y1)),
  ((x1, y1), (x0, y1)),
  ((x0, y1), (x0, y0)),
)


#let intersect-rect-with-crossing-line(rect, line) = {
	rect = rect.map(vector-unitless)
	line = line.map(vector-unitless)
	for (p1, p2) in rect-edges(..rect) {
		let meet = draw.intersection.line-line(p1, p2, ..line)
		if meet != none {
			return vector-2d(vector.scale(meet, 1pt))
		}
	}
	panic("didn't intersect", rect, line)
}


/// Determine arc between two points with a given bend angle
///
/// The bend angle is the angle between chord of the arc (line connecting the
/// points) and the tangent to the arc and the first point.
/// 
/// Returns a dictionary containing:
/// - `center`: the center of the arc's curvature
/// - `radius`
/// - `start`: the start angle of the arc
/// - `stop`: the end angle of the arc
///
/// - from (point): 2D vector of initial point.
/// - to (point): 2D vector of final point.
/// - angle (angle): The bend angle between chord of the arc (line connecting the
/// points) and the tangent to the arc and the first point.
/// -> dictionary
///
/// #fletcher.diagram(spacing: 2cm, {
///	    for (i, θ) in (0deg, 45deg, -90deg).enumerate() {
///         edge((2*i, 0), (2*i + 1, 0), marks: (none, "head"), bend: θ)
///         edge((2*i, 0), (2*i + 1, 0), [#θ], label-side: center, dash:
///         "dotted")
///     }
/// })
#let get-arc-connecting-points(from, to, angle) = {
	// TODO: properly handle trivial arcs
	if from == to { to = vector.add(to, (0pt, 1e-4pt)) }

	let mid = vector.scale(vector.add(from, to), 0.5)
	let (dx, dy) = vector.sub(to, from)
	let perp = (dy, -dx)

	let center = vector.add(mid, vector.scale(perp, 0.5/calc.tan(angle)))

	let radius = vector-len(vector.sub(to, center))

	let start = vector-angle(vector.sub(from, center))
	let stop = vector-angle(vector.sub(to, center))

	if start < stop and angle > 0deg { start += 360deg }
	if start > stop and angle < 0deg { start -= 360deg }

	(center: center, radius: radius, start: start, stop: stop)
}