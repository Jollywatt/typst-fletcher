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

/// Linearly interpolate an array with linear behaviour outside bounds
///
/// - values (array): Array of lengths defining interpolation function.
/// - index (int, float): Index-coordinate to sample.
/// - spacing (length): Gradient for linear extrapolation beyond array bounds.
#let interp(values, index, spacing: 0) = {
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

#let interp-grid-point(grid, (u, v)) = {
  let (i, j) = (u - grid.u-min, v - grid.v-min)
  (
    interp(grid.col-centers, i),
    interp(grid.row-centers, j),
  )
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

#let as-pair(o) = {
	if type(o) == array {
		if o.len() != 2 { error("expected one or a pair of values; got #0.", o) }
		return o
	} else { return (o, o) }
}

#let get-thickness(s) = {
	if s == none { return 1pt }
	let t = stroke(s).thickness
	if t == auto { return 1pt }
	return t
}

#let stroke-to-dict(s) = {
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