#let error(message, ..args) = {
	let pairs = args.pos().enumerate() + args.named().pairs()
	for (k, v) in pairs {
		if type(v) == array {
			let replacement = if v.len() > 0 {
				v.map(repr).join(", ")
			} else { "()" }
			message = message.replace("#.." + str(k), replacement)
		}
		if type(v) != str { v = repr(v) }
		message = message.replace("#" + str(k), v)
	}
	assert(false, message: message)
}

// type checking and coercion

#let is-node(o) = type(o) == dictionary and "class" in o and o.class == "node"
#let is-edge(o) = type(o) == dictionary and "class" in o and o.class == "edge"
#let is-cetz(o) = type(o) == array and o.all(el => type(el) == function)

#let as-array(o) = {
	if type(o) == array { return o }
	if o == none { return () }
	panic("expected array", o)
}

#let one-or-array(o, types: none) = {
	if type(o) != array { o = (o,) }
	if types != none and not o.all(i => type(i) in types) {
		error("Expected #..0 or an array of those; got #1.", types, o)
	}
	return o
}

#let as-pair(o) = {
	if type(o) == array {
		if o.len() != 2 { error("expected one or a pair of values; got #0.", o) }
		return o
	} else { return (o, o) }
}

// math

#let cumsum(array) = {
	let sum = array.at(0)
	for i in range(1, array.len()) {
		sum += array.at(i)
		array.at(i) = sum
	}
	array
}

#let wrap-angle-180(a) = {
  let t = (a + 180deg)/360deg
  t -= calc.floor(t)
  return t*360deg - 180deg
}


// coordinate math

#let polar(dist, angle) = (dist*calc.cos(angle), dist*calc.sin(angle), 0.)

#let lerp(a, b, t) = a*(1 - t) + b*t

/// Linearly interpolate an array of values with linear behaviour outside bounds.
///
/// - ys (array): Array of function values to interpolate between.
/// - t (int, float): Index-coordinate to sample.
/// - spacing (length): Gradient for linear extrapolation beyond array bounds.
#let interp(ys, t, spacing: 0) = {
	let max-t = ys.len() - 1
	if t < 0 {
		ys.at(0) + spacing*t
	} else if t > max-t {
		ys.at(-1) + spacing*(t - max-t)
	} else {
		lerp(
			ys.at(calc.floor(t)),
			ys.at(calc.ceil(t)),
			calc.fract(t),
		)
	}
}


/// Inverse of `interp()`.
///
/// - xs (array): Array of lengths defining interpolation function.
/// - y: Value to find the interpolated index of.
/// - spacing (length): Gradient for linear extrapolation beyond array bounds.
#let interp-inv(xs, y, spacing: 0pt) = {
	let i = 0
	while i < xs.len() {
		if xs.at(i) >= y { break }
		i += 1
	}
	let (first, last) = (xs.at(0), xs.at(-1))

	// avoids division by zero when numerator and denominator both vanish
	let div(a, b) = if calc.abs(a) < 1e-3 { 0 } else { a/b }

	if y < first {
		div(y - first, spacing)
	} else if y >= last {
		xs.len() - 1 + div(y - last, spacing)
	} else {
		let (prev, nearest) = (xs.at(i - 1), xs.at(i))
		i - 1 + div(y - prev, nearest - prev)
	}
}


/// Convert coordinates in $u v$ system into $x y$ system.
/// 
/// The `grid` dictionary defines the coordinate mapping and must contain
/// - `col-centers`, defining $x$ values for each $u$ value
/// - `row-center`, defining $y$ values for each $v$ value
/// - `u-min` and `v-min`, defining the coordinate origin
#let uv-to-xy(grid, uv) = {
  let (u, v, ..) = uv
  let (i, j) = (u - grid.u-min, v - grid.v-min)
  let (x, y) = (
    interp(grid.col-centers, i, spacing: grid.col-gutter),
    interp(grid.row-centers, j, spacing: grid.row-gutter),
  )
  return (x, y)
}

#let xy-to-uv(grid, xy) = {
  let (x, y, ..) = xy
  let (i, j) = (
    interp-inv(grid.col-centers, x, spacing: grid.col-gutter),
    interp-inv(grid.row-centers, y, spacing: grid.row-gutter),
  )
  let (u, v) = (grid.u-min + i, grid.v-min + j)
  return (u, v)
}

#let interpret-as-uv(c) = {
	if type(c) == array and c.all(x => type(x) in (int, float)) {
		return (uv: c)
	}
	return c
}



#let interp-grid-cell(grid, (u, v)) = {
  let (i, j) = (u - grid.u-min, v - grid.v-min)
  (
    x: interp(grid.col-centers, i, spacing: grid.col-gutter),
    y: interp(grid.row-centers, j, spacing: grid.row-gutter),
    w: interp(grid.col-sizes, i),
    h: interp(grid.row-sizes, j),
  )
}


// stroke utils

#let get-thickness(s) = {
	if s in (none, auto) { return 1pt }
	let t = stroke(s).thickness
	if t == auto { return 1pt }
	return t
}

#let stroke-to-dict(s) = {
	if s == auto { return (:) }
	let s = stroke(s)
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

	return d
}

#let fold-strokes(..strokes) = {
	for stroke in strokes.pos() {
		stroke-to-dict(stroke)
	}
}



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
	).at(calc.rem(int(calc.round(i)), 8))
}

