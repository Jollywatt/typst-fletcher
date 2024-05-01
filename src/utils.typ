#import "deps.typ": cetz
#import cetz: vector

// Replace `auto` with a value
#let map-auto(value, fallback) = if value == auto { fallback } else { value }

// Make a function propagate `auto`
#let pass-auto(f) = x => if x == auto { x } else { f(x) }

// Make a function propagage `none`
#let pass-none(f) = x => if x == none { x } else { f(x) }

// for when `stroke` is already in namespace
#let as-stroke(x) = stroke(x)

#let as-label(x) = {
	if type(x) == label { x }
	else if type(x) == str { label(x) }
	else { panic("Expected label or string; got " + repr(x)) }
}

#let as-pair(obj, message: "") = {
	if type(obj) == array {
		if obj.len() == 2 { obj }
		else { panic("Expected a pair (array of length 2); got " + repr(obj))}
	} else { (obj, obj) }
}

#let as-array(obj) = if type(obj) == array { obj } else { (obj,) }

#let as-number-or-length(obj, message: "Expected a number or length") = {
	if type(obj) in (int, float, length) { obj }
	else { panic(message + "; got " + repr(obj)) }
}

#let as-length(obj, message: "Expected a length") = {
	if type(obj) == length { obj }
	else { panic(message + "; got " + repr(obj)) }
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

	// remove auto entries to allow folding strokes by joining dicts
	for (key, value) in d {
		if value == auto {
			let _ = d.remove(key)
		}
	}

	d
}


#let to-abs-length(len, em-size) = len.abs + len.em*em-size

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
#let vector-max(a, b) = array.zip(a, b).map(vals => calc.max(..vals))

#let element-wise-mul(a, b) = a.zip(b).map(((i, j)) => i*j)

#let lerp(a, b, t) = a*(1 - t) + b*t

/// Linearly interpolate an array with linear behaviour outside bounds
///
/// - values (array): Array of lengths defining interpolation function.
/// - index (int, float): Index-coordinate to sample.
/// - spacing (length): Gradient for linear extrapolation beyond array bounds.
#let interp(values, index, spacing: 0pt) = {
	let max-index = values.len() - 1
	if index < 0 {
		values.at(0) + spacing*index
	} else if index > max-index {
		values.at(-1) + spacing*(index - max-index)
	} else {
		lerp(
			values.at(calc.floor(index)),
			values.at(calc.ceil(index)),
			calc.fract(index),
		)
	}
}


/// Inverse of `interp()`.
///
/// - values (array): Array of lengths defining interpolation function.
/// - value: Value to find the interpolated index of.
/// - spacing (length): Gradient for linear extrapolation beyond array bounds.
#let interp-inv(values, value, spacing: 0pt) = {
	let i = 0
	while i < values.len() {
		if values.at(i) >= value { break }
		i += 1
	}
	let (first, last) = (values.at(0), values.at(-1))
	if value < first {
		(value - first)/spacing
	} else if value >= last {
		values.len() - 1 + (value - last)/spacing
	} else {
		let (prev, nearest) = (values.at(i - 1), values.at(i))
		i - 1 + (value - prev)/(nearest - prev)
	}
}

// Ensure angle is in range 0deg <= θ < 360deg
#let wrap-angle-360(θ) = calc.rem-euclid(θ/360deg, 1)*360deg

// Ensure angle is in range -180deg <= θ <= 180deg
#let wrap-angle-180(θ) = (θ/360deg - calc.round(θ/360deg))*360deg

#let angle-to-anchor(θ) = {
	let i = calc.rem(8*θ/1rad/calc.tau, 8)
	(
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
	vector.add(origin, vector.scale(size, dir/2))
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
/// #diagram(spacing: 2cm, {
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

/// Return true if a content element is a space or sequence of spaces
#let is-space(el) = {
	if el == none { return true }
	if repr(el.func()) == "space" { return true }
	if repr(el.func()) == "sequence" { return el.children.all(is-space) }
	return false
}


#let find-node-at(nodes, pos) = {
	nodes.filter(node => {
		// node must be within a one-unit block around pos
		vector.sub(node.pos, pos).all(Δ => calc.abs(Δ) < 1)
	})
		.sorted(key: node => vector.len(vector.sub(node.pos, pos)))
		.at(0, default: none)
}

#let find-node(nodes, key, snap: false) = {
	if type(key) == label {
		let node = nodes.find(node => node.name == key)
		assert(node != none, message: "Couldn't resolve name " + repr(key))
		node
	} else if type(key) == array {
		find-node-at(nodes, key)
	} else {
		panic("Couldn't find node corresponding to " + repr(key))
	}
}
