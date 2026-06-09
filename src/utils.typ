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

/// Convert a number, ratio, or (relative) length to an absolute length.
#let to-length(
	it,
	/// Ratios are taken as fractions of this length.
	ratios-of: none,
	/// Numbers are taken as multiples of this length.
	units-of: none,
	/// Always return a float by dividing lengths by this length.
	to-float: none,
) = {
	let to-abs(it) = if it.em != 0 { it.to-absolute() } else { it.abs }

	it = if type(it) == ratio {
		if ratios-of == none { error("expected length, got #0", it) }
		float(it)*ratios-of
	} else if type(it) in (int, float) {
		if units-of == none { error("expected length, got #0", it) }
		it*units-of
	} else if type(it) == length {
		to-abs(it)
	} else if type(it) == relative {
		if ratios-of == none { error("expected length, got #0", it) }
		it.ratio*float(ratios-of) + to-abs(it.length)
	}

	if type(to-float) == length and type(it) == length {
		it/to-float
	} else {
		it
	}
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
	let flip = ys.first() > ys.last()
	if flip { spacing *= -1 }
	let max-t = ys.len() - 1
	if t < 0 {
		ys.first() + spacing*t
	} else if t > max-t {
		ys.last() + spacing*(t - max-t)
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
	let (first, last) = (xs.first(), xs.last())
	let flip = first > last
	if flip {
		return xs.len() - 1 - interp-inv(xs.rev(), y, spacing: spacing)
	}

	let i = 0
	while i < xs.len() {
		if xs.at(i) >= y { break }
		i += 1
	}

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
/// - `axis-flips`, a dictionary containing
/// 	- `order`, whether $(u, v) |-> (v, u)$ are swapped
/// 	- `u`, whether the first coordinate is negated
/// 	- `v`, whether the second coordinate is negated
#let uv-to-xy(grid, uv) = {
  let (u, v, ..) = uv
	if grid.axis-flips.order { (u, v) = (v, u) }
	if grid.axis-flips.u { u *= -1 }
	if grid.axis-flips.v { v *= -1 }
  let (i, j) = (u - grid.u-min, v - grid.v-min)
  let (x, y) = (
    interp(grid.col-centers, i, spacing: grid.col-gutter),
    interp(grid.row-centers, j, spacing: grid.row-gutter),
  )
  return (x, y)
}

/// Exact inverse of `uv-to-xy` for a fixed grid
#let xy-to-uv(grid, xy) = {
  let (x, y, ..) = xy
  let (i, j) = (
    interp-inv(grid.col-centers, x, spacing: grid.col-gutter),
    interp-inv(grid.row-centers, y, spacing: grid.row-gutter),
  )
  let (u, v) = (grid.u-min + i, grid.v-min + j)
	if grid.axis-flips.u { u *= -1 }
	if grid.axis-flips.v { v *= -1 }
	if grid.axis-flips.order { (u, v) = (v, u) }
  return (u, v)
}

// replace (u,v) with (uv: (u,v)) recursively inside a coord expr
#let interpret-as-uv(c) = {
	if type(c) == array {
		if c.len() == 2 and c.all(x => type(x) in (int, float)) {
			(uv: c)
		} else if c.any(x => type(x) in (length,)) {
			(xy: c)
		} else {
			c.map(interpret-as-uv)
		}
	} else if type(c) == dictionary {
		if "uv" in c { return c }
		c.pairs().map(((k, v)) => (k, interpret-as-uv(v))).to-dict()
	} else {
		c
	}
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

#let thing-to-angle(it) = {
	if type(it) == angle { return it }

	let angles = range(8).map(i => 45deg*i)
	
	if type(it) == alignment {
		let i = (
			"right",
			"right + top",
			"top",
			"left + top",
			"left",
			"left + bottom",
			"bottom",
			"right + bottom",
		).position(x => x == repr(it))
		return angles.at(i)
	}

	let i = (
		"east",
		"north-east",
		"north",
		"north-west",
		"west",
		"south-west",
		"south",
		"south-east",
	).position(x => x == it)
	if i == none {
		error("Cannot convert #0 to an angle. Specify an angle, alignment, or anchor like 'north-east'.", repr(it))
	}
	return angles.at(i)
}