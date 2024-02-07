#import "@preview/cetz:0.2.0" as cetz: draw, vector

#let diamond(node, extrude, scale: 1.5) = {
	let (w, h) = node.size
	let φ = calc.atan2(w/1pt, h/1pt)
	let x = w/2*scale + extrude/calc.sin(φ)
	let y = h/2*scale + extrude/calc.cos(φ)
	draw.line(
		(-x, 0pt),
		(0pt, -y),
		(+x, 0pt),
		(0pt, +y),
		close: true,
	)
}

#let pill(node, extrude) = {
	let size = node.size.map(i => i + 2*extrude)
	draw.rect(
		vector.scale(size, -0.5),
		vector.scale(size, +0.5),
		radius: calc.min(..size)/2,
	)
}

#let parallelogram(node, extrude, angle: 20deg) = {
	let (w, h) = node.size
	let (x, y) = (w/2 + extrude*calc.cos(angle), h/2 + extrude)
	let δ = h/2*calc.tan(angle)
	let μ = extrude*calc.tan(angle)
	draw.line(
		(-x - μ, -y),
		(+x - δ, -y),
		(+x + μ, +y),
		(-x + δ, +y),
		close: true,
	)
}

#let hexagon(node, extrude, angle: 30deg) = {
	let (w, h) = node.size
	let (x, y) = (w/2 , h/2 + extrude)
	let δ = y*calc.tan(angle)
	x += extrude*calc.tan(45deg - angle/2)
	draw.line(
		(-x, -y),
		(+x, -y),
		(+x + δ, 0pt),
		(+x, +y),
		(-x, +y),
		(-x - δ, 0pt),
		close: true,
	)
}

#let house(node, extrude, angle: 10deg) = {
	let (w, h) = node.size
	let (x, y) = (w/2 + extrude, h/2 + extrude)
	let a = h/2 + extrude*calc.tan(45deg - angle/2)
	let b = h/2 + w/2*calc.tan(angle) + extrude/calc.cos(angle)
 	draw.line(
		(-x, -y),
		(-x,  a),
		(0pt, b),
		(+x,  a),
		(+x, -y),
		close: true,
	)
}
