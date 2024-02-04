#import "@preview/cetz:0.2.0" as cetz: draw, vector

#let diamond(node, extrude) = {
	let (w, h) = node.size
	let φ = calc.atan2(w/1pt, h/1pt)
	let x = w/2 + extrude/calc.sin(φ)
	let y = h/2 + extrude/calc.cos(φ)
	draw.line(
		..(
			(-x, 0pt),
			(0pt, -y),
			(+x, 0pt),
			(0pt, +y),
		).map(x => vector.add(x, node.real-pos)),
		close: true
	)
}

#let house(node, extrude, angle: 10deg) = {
	let (w, h) = node.size
	let (x, y) = (w/2 + extrude, h/2 + extrude)
	let a = extrude*calc.tan(45deg - angle/2)
 	draw.line(
		..(
			(-x, -y),
			(-x, h/2 + a),
			(0pt, h/2 + w/2*calc.tan(angle) + extrude/calc.cos(angle)),
			(+x, h/2 + a),
			(+x, -y),
		).map(p => vector.add(p, node.real-pos)),
		close: true,
	)
}

#let pill(node, extrude) = {
	let size = node.size.map(i => i + 2*extrude)
	draw.rect(
		(to: node.real-pos, rel: vector.scale(size, -0.5)),
		(to: node.real-pos, rel: vector.scale(size, +0.5)),
		radius: calc.min(..size)/2
	)
}

#let parallelogram(node, extrude, angle: 20deg) = {
	let (w, h) = node.size
	let (x, y) = (w/2 + extrude*calc.cos(angle), h/2 + extrude)
	let δ = h/2*calc.tan(angle)
	let μ = extrude*calc.tan(angle)
	draw.line(
		..(
			(-x - μ, -y),
			(+x - δ, -y),
			(+x + μ, +y),
			(-x + δ, +y),
		).map(p => vector.add(p, node.real-pos)),
		close: true,
	)
}

#let hexagon(node, extrude, angle: 30deg) = {
	let (w, h) = node.size
	let (x, y) = (w/2 + extrude*calc.cos(angle), h/2 + extrude)
	let δ = h/2*calc.tan(angle) + extrude*calc.tan(angle)
	draw.line(
		..(
			(-x, -y),
			(+x, -y),
			(+x + δ, 0pt),
			(+x, +y),
			(-x, +y),
			(-x - δ, 0pt),
		).map(p => vector.add(p, node.real-pos)),
		close: true,
	)
}