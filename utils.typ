
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
