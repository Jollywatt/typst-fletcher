
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

#let cumsum(array) = {
	let sum = array.at(0)
	for i in range(1, array.len()) {
		sum += array.at(i)
		array.at(i) = sum
	}
	array
}

#let map-auto(value, fallback) = if value == auto { fallback } else { value }

#let is-node(o) = type(o) == dictionary and "class" in o and o.class == "node"




#import "@preview/elembic:1.1.1" as e
#let as-stroke(o) = {
  let (succeeded, stroke) = e.types.cast(o, stroke)
  if not succeeded { panic(stroke) }
  return stroke
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