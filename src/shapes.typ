#import "@preview/cetz:0.2.0" as cetz: draw, vector

#let house(node, extrude) = {
	let (w, h) = node.size
	let α = 10deg
	let (x, y) = (w/2 + extrude, h/2 + extrude)
	let σ = calc.tan(45deg - α/2)
 	draw.line(
		..(
			(-x, -y),
			(-x, h/2 + extrude*σ),
			(0pt, h/2 + w/2*calc.tan(α) + extrude/calc.cos(α)),
			(+x, h/2 + extrude*σ),
			(+x, -y),
		).map(p => vector.add(p, node.real-pos)),
		close: true,
	)
}

#let diamond(node, extrude) = {
	let (w, h) = node.size

	let α = calc.atan2(w/1pt, h/1pt)
	let x = w/2 + extrude/calc.sin(α)
	let y = h/2 + extrude/calc.cos(α)
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
