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

#let is-node(o) = type(o) == dictionary and "class" in o and o.class == "node"
#let is-edge(o) = type(o) == dictionary and "class" in o and o.class == "edge"
#let is-cetz(o) = type(o) == array and o.all(el => type(el) == function)

#let switch-type(input, ..args) = {
	let types = args.named().keys()
	let t = str(type(input))
	if is-node(input) { t = "node" }
	if is-edge(input) { t = "edge" }
	if t not in types {
		if "any" in types { t = "any" }
		else { error("expected #0; got #1", types.join(", ", last: " or "), t) }
	}
	let fn = args.named().at(t)
	fn(input)
}

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
    interp(grid.col-centers, i, spacing: 1),
    interp(grid.row-centers, j, spacing: 1),
  )
  return (x, y)
}

#let xy-to-uv(grid, xy) = {
  let (x, y, ..) = xy
  let (i, j) = (
    interp-inv(grid.col-centers, x, spacing: 1),
    interp-inv(grid.row-centers, y, spacing: 1),
  )
  let (u, v) = (grid.u-min + i, grid.v-min + j)
  return (u, v)
}






#let interp-grid-cell(grid, (u, v)) = {
  let (i, j) = (u - grid.u-min, v - grid.v-min)
  (
    x: interp(grid.col-centers, i),
    y: interp(grid.row-centers, j),
    w: interp(grid.col-sizes, i),
    h: interp(grid.row-sizes, j),
  )
}


#let cumsum(array) = {
	let sum = array.at(0)
	for i in range(1, array.len()) {
		sum += array.at(i)
		array.at(i) = sum
	}
	array
}

#let map-auto(value, fallback) = if value == auto { fallback } else { value }
#let map-none(value, fallback) = if value == none { fallback } else { value }



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

#import "deps.typ": cetz


// inaccessible cetz utilities
#let get-segments(ctx, target) = {
  if type(target) == array {
    assert.eq(target.len(), 1,
      message: "Expected a single element, got " + str(target.len()))
    target = target.first()
  }

  let (ctx, drawables, ..) = cetz.process.element(ctx, target)
  if drawables == none or drawables == () {
    return ()
  }

  let first = drawables.first()
  let closed = cetz.path-util.first-subpath-closed(first.segments)
  return (segments: first.segments, close: closed)
}