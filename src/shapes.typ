#import "deps.typ": cetz
#import cetz: draw, vector

/// The standard rectangle node shape.
///
/// A string `"rect"` or the element function `rect` given to
/// #the-param[node][shape] are interpreted as this shape.
///
/// #diagram(
/// 	node-stroke: green,
/// 	node-fill: green.lighten(90%),
/// 	node((0,0), `rect`, shape: fletcher.shapes.rect)
/// )
///
#let rect(node, extrude) = {
	let r = node.corner-radius
	let (w, h) = node.size.map(i => i/2 + extrude)
	draw.rect(
		(-w, -h), (+w, +h),
		radius: if r != none { r + extrude },
	)
}

/// The standard circle node shape.
///
/// A string `"circle"` or the element function `circle` given to
/// #the-param[node][shape] are interpreted as this shape.
///
/// #diagram(
/// 	node-stroke: red,
/// 	node-fill: red.lighten(90%),
/// 	node((0,0), `circle`, shape: fletcher.shapes.circle)
/// )
///
#let circle(node, extrude) = draw.circle((0, 0), radius: node.radius + extrude)

/// An elliptical node shape.
///
/// #diagram(
/// 	node-stroke: orange,
/// 	node-fill: orange.lighten(90%),
/// 	node((0,0), `ellipse`, shape: fletcher.shapes.ellipse)
/// )
///
/// - scale (number): Scale factor for ellipse radii.
#let ellipse(node, extrude, scale: 1) = {
	draw.circle(
		(0, 0),
		radius: vector.scale(node.size, 0.5).map(x => x*scale + extrude),
	)
}


/// A capsule node shape.
///
/// #diagram(
/// 	node-stroke: teal,
/// 	node-fill: teal.lighten(90%),
/// 	node((0,0), `pill`, shape: fletcher.shapes.pill)
/// )
///
#let pill(node, extrude) = {
	let size = node.size.map(i => i + 2*extrude)
	draw.rect(
		vector.scale(size, -0.5),
		vector.scale(size, +0.5),
		radius: calc.min(..size)/2,
	)
}


/// A slanted rectangle node shape.
///
/// #diagram(
/// 	node-stroke: olive,
/// 	node-fill: olive.lighten(90%),
/// 	node((0,0), `parallelogram`, shape: fletcher.shapes.parallelogram)
/// )
///
/// - angle (angle): Angle of the slant, `0deg` is a rectangle. Don't set to
///   `90deg` unless you want your document to be larger than the solar system.
///
/// - fit (number): Adjusts how comfortably the parallelogram fits the label's bounding box.
///
///   #for (i, fit) in (0, 0.5, 1).enumerate() {
///   	let s = fletcher.shapes.parallelogram.with(fit: fit, angle: 35deg)
///   	let l = box(
///   		stroke: (dash: "dashed", thickness: 0.5pt),
///   		inset: 10pt,
///   		raw("fit: " + repr(fit)),
///   	)
///   	diagram(node((i, 0), l,
///   		inset: 0pt,
///   		shape: s,
///   		stroke: olive,
///   		fill: olive.lighten(90%),
///   	))
///   	h(5mm)
///   }
#let parallelogram(node, extrude, flip: false, angle: 20deg, fit: 0.8) = {
	let (w, h) = node.size
	if flip { (w, h) = (h, w) }

	let (x, y) = (w/2 + extrude*calc.cos(angle), h/2 + extrude)
	let δ = h/2*calc.tan(angle)
	let μ = extrude*calc.tan(angle)
	x += δ*fit

	let verts = (
		(-x - μ, -y),
		(+x - δ, -y),
		(+x + μ, +y),
		(-x + δ, +y),
	)

	if flip { verts = verts.map(((i, j)) => (j, i)) }

	let obj = draw.line(..verts, close: true)
	draw.group(obj) // enables cetz border anchors
}


/// An isosceles trapezium node shape.
///
/// #diagram(
/// 	node-stroke: green,
/// 	node-fill: green.lighten(90%),
/// 	node((0,0), `trapezium`, shape: fletcher.shapes.trapezium)
/// )
///
/// - angle (angle): Angle of the slant, `0deg` is a rectangle. Don't set to
///   `90deg` unless you want your document to be larger than the solar system.
///
/// - fit (number): Adjusts how comfortably the trapezium fits the label's bounding box.
///
///   #for (i, fit) in (0, 0.5, 1).enumerate() {
///   	let s = fletcher.shapes.trapezium.with(fit: fit, angle: 35deg)
///   	let l = box(
///   		stroke: (dash: "dashed", thickness: 0.5pt),
///   		inset: 10pt,
///   		raw("fit: " + repr(fit)),
///   	)
///   	diagram(node((i, 0), l,
///   		inset: 0pt,
///   		shape: s,
///   		stroke: green,
///   		fill: green.lighten(90%),
///   	))
///   	h(5mm)
///   }
///
/// - dir (top, bottom, left, right): The side the shorter parallel edge is on.
#let trapezium(node, extrude, dir: top, angle: 20deg, fit: 0.8) = {
	assert(dir in (top, bottom, left, right))

	let flip = dir in (right, left) // flip along diagonal line x = y
	let rotate = dir in (bottom, left) // rotate 180deg

	let (w, h) = node.size
	if flip { (w, h) = (h, w) }

	let (x, y) = (w/2 + extrude*calc.cos(angle), h/2 + extrude)
	let δ = h/2*calc.tan(angle)
	let μ = extrude*calc.tan(angle)
	x += δ*fit

	let verts = (
		(-x - μ, -y),
		(+x + μ, -y),
		(+x - δ, +y),
		(-x + δ, +y),
	)

	if flip { verts = verts.map(((i, j)) => (j, i)) }
	if rotate { verts = verts.map(((i, j)) => (-i, -j)) }

	let obj = draw.line(..verts, close: true)
	draw.group(obj) // enables cetz border anchors
}

/// A rhombus node shape.
///
/// #diagram(
/// 	node-stroke: purple,
/// 	node-fill: purple.lighten(90%),
/// 	node((0,0), `diamond`, shape: fletcher.shapes.diamond)
/// )
///
/// - fit (number): Adjusts how comfortably the diamond fits the label's bounding box.
///
///   #for (i, fit) in (0, 0.5, 1).enumerate() {
///   	let s = fletcher.shapes.diamond.with(fit: fit)
///   	let l = box(
///   		stroke: (dash: "dashed", thickness: 0.5pt),
///   		inset: 10pt,
///   		raw("fit: " + repr(fit)),
///   	)
///   	diagram(node((i, 0), l,
///   		inset: 0pt,
///   		shape: s,
///   		stroke: purple,
///   		fill: purple.lighten(90%),
///   	))
///   	h(5mm)
///   }
#let diamond(node, extrude, fit: 0.5) = {
	let (w, h) = node.size
	let φ = calc.atan2(w/1pt, h/1pt)
	let x = w/2*(1 + fit) + extrude/calc.sin(φ)
	let y = h/2*(1 + fit) + extrude/calc.cos(φ)
	let obj = draw.line(
		(-x, 0pt),
		(0pt, -y),
		(+x, 0pt),
		(0pt, +y),
		close: true,
	)
	draw.group(obj) // enables cetz border anchors
}

/// An isosceles triangle node shape.
///
/// One of #param[triangle][angle] or #param[triangle][aspect] may be given, but
/// not both. The triangle's base coincides with the label's base and widens to
/// enclose the label; see https://www.desmos.com/calculator/i4i9svunj4.
///
/// #diagram(
/// 	node-stroke: fuchsia,
/// 	node-fill: fuchsia.lighten(90%),
/// 	node((0,0), `triangle`, shape: fletcher.shapes.triangle)
/// )
///
/// - dir (top, bottom, left, right): Direction the triangle points.
/// - aspect (number, auto): Aspect ratio of triangle, or the ratio of its base
///   to its height.
/// - angle (angle, auto): Angle of the triangle opposite the base.
/// - fit (number): Adjusts how comfortably the triangle fits the label's bounding box.
///
///   #for (i, fit) in (0, 0.5, 1).enumerate() {
///   	let s = fletcher.shapes.triangle.with(fit: fit, angle: 120deg)
///   	let l = box(
///   		stroke: (dash: "dashed", thickness: 0.5pt),
///   		inset: 10pt,
///   		raw("fit: " + repr(fit)),
///   	)
///   	diagram(node((i, 0), l,
///   		inset: 0pt,
///   		shape: s,
///   		stroke: fuchsia,
///   		fill: fuchsia.lighten(90%),
///   	))
///   	h(5mm)
///   }
#let triangle(node, extrude, dir: top, angle: auto, aspect: auto, fit: 0.8) = {
	assert(dir in (top, bottom, left, right))

	let flip = dir in (right, left) // flip along diagonal line x = y
	let rotate = dir in (bottom, left) // rotate 180deg

	let (w, h) = node.size
	if flip { (w, h) = (h, w) }

	if angle == auto and aspect == auto { aspect = w/h }
	if angle == auto { angle = 2*calc.atan(aspect/2) }
	if aspect == auto { aspect = 2*calc.tan(angle/2) }

	let a = aspect*h/2 + fit*w/2
	let b = (a + fit*w/2)/aspect

	a += extrude*calc.tan(45deg + angle/4)
	b += extrude/calc.cos(90deg - angle/2)

	let verts = (
		(-a, -h/2 - extrude),
		(+a, -h/2 - extrude),
		(0, +b),
	)

	if flip { verts = verts.map(((i, j)) => (j, i)) }
	if rotate { verts = verts.map(((i, j)) => (-i, -j)) }

	let obj = draw.line(..verts, close: true)
	draw.group(obj) // enables cetz border anchors
}


/// A pentagonal house-like node shape.
///
/// #diagram(
/// 	node-stroke: eastern,
/// 	node-fill: eastern.lighten(90%),
/// 	node((0,0), `house`, shape: fletcher.shapes.house)
/// )
///
/// - dir (top, bottom, left, right): Direction of the roof of the house.
/// - angle (angle): The slant of the roof. A plain rectangle is `0deg`, and 
///   `90deg` is a sky scraper stretching past Pluto.
#let house(node, extrude, dir: top, angle: 10deg) = {
	let flip = dir in (right, left) // flip along diagonal line x = y
	let rotate = dir in (bottom, left) // rotate 180deg

	let (w, h) = node.size
	if flip { (w, h) = (h, w) }

	let (x, y) = (w/2 + extrude, h/2 + extrude)
	let a = h/2 + extrude*calc.tan(45deg - angle/2)
	let b = h/2 + w/2*calc.tan(angle) + extrude/calc.cos(angle)

 	let verts = (
		(-x, -y),
		(-x,  a),
		(0pt, b),
		(+x,  a),
		(+x, -y),
	)

	if flip { verts = verts.map(((i, j)) => (j, i)) }
	if rotate { verts = verts.map(((i, j)) => (-i, -j)) }

	let obj = draw.line(..verts, close: true)
	draw.group(obj) // enables cetz border anchors
}




/// A chevron node shape.
///
/// #diagram(
/// 	node-stroke: yellow,
/// 	node-fill: yellow.lighten(90%),
/// 	node((0,0), `chevron`, shape: fletcher.shapes.chevron)
/// )
///
/// - dir (top, bottom, left, right): Direction the chevron points.
/// - angle (angle): The slant of the arrow. A plain rectangle is `0deg`.
/// - fit (number): Adjusts how comfortably the chevron fits the label's bounding box.
///
///   #for (i, fit) in (0, 0.5, 1).enumerate() {
///   	let s = fletcher.shapes.chevron.with(fit: fit)
///   	let l = box(
///   		stroke: (dash: "dashed", thickness: 0.5pt),
///   		inset: 10pt,
///   		raw("fit: " + repr(fit)),
///   	)
///   	diagram(node((i, 0), l,
///   		inset: 0pt,
///   		shape: s,
///   		stroke: yellow,
///   		fill: yellow.lighten(90%),
///   	))
///   	h(5mm)
///   }
#let chevron(node, extrude, dir: right, angle: 30deg, fit: 0.8) = {
	let flip = dir in (right, left) // flip along diagonal line x = y
	let rotate = dir in (bottom, left) // rotate 180deg

	let (w, h) = node.size
	if flip { (w, h) = (h, w) }

	let (x, y) = (w/2 + extrude, h/2 + extrude)
	let c = w/2*calc.tan(angle)
	let α = extrude*calc.tan(45deg - angle/2)
	let β = extrude*calc.tan(45deg + angle/2)
	let ɣ = extrude/calc.cos(angle) - c
	let δ = c*fit
	let y = h/2 + c*fit

 	let verts = (
		(-x,  +y + α - c),
		(0pt, +y + ɣ + c),
		(+x,  +y + α - c),

		(+x,  -y - β),
		(0pt, -y - ɣ),
		(-x,  -y - β),
	)

	if flip { verts = verts.map(((i, j)) => (j, i)) }
	if rotate { verts = verts.map(((i, j)) => (-i, -j)) }


	let obj = draw.line(..verts, close: true)
	draw.group(obj) // enables cetz border anchors
}





/// An (irregular) hexagon node shape.
///
/// #diagram(
/// 	node-stroke: aqua,
/// 	node-fill: aqua.lighten(90%),
/// 	node((0,0), `hexagon`, shape: fletcher.shapes.hexagon)
/// )
///
/// - angle (angle): Half the exterior angle, `0deg` being a rectangle.
/// - fit (number): Adjusts how comfortably the hexagon fits the label's bounding box.
///
///   #for (i, fit) in (0, 0.5, 1).enumerate() {
///   	let s = fletcher.shapes.hexagon.with(fit: fit)
///   	let l = box(
///   		stroke: (dash: "dashed", thickness: 0.5pt),
///   		inset: 10pt,
///   		raw("fit: " + repr(fit)),
///   	)
///   	diagram(node((i, 0), l,
///   		inset: 0pt,
///   		shape: s,
///   		stroke: aqua,
///   		fill: aqua.lighten(90%),
///   	))
///   	h(5mm)
///   }
#let hexagon(node, extrude, angle: 30deg, fit: 0.8) = {
	let (w, h) = node.size
	let f = h/2*calc.tan(angle)*(1 - fit)
	let x = w/2 + extrude*calc.tan(45deg - angle/2) - f
	let y = h/2 + extrude
	let z = y*calc.tan(angle)
	let obj = draw.line(
		(+x, -y),
		(+x + z, 0pt),
		(+x, +y),

		(-x, +y),
		(-x - z, 0pt),
		(-x, -y),

		close: true,
	)
	draw.group(obj) // enables cetz border anchors
}


/// A truncated rectangle node shape.
///
/// #diagram(
/// 	node-stroke: maroon,
/// 	node-fill: maroon.lighten(90%),
/// 	node((0,0), `octagon`, shape: fletcher.shapes.octagon)
/// )
///
/// - truncate (number, length): Size of the truncated corners. A number is
///   interpreted as a multiple of the smaller of the node's width or height.
#let octagon(node, extrude, truncate: 0.5) = {
	let (w, h) = node.size
	let (x, y) = (w/2 + extrude, h/2 + extrude)

	let d
	if type(truncate) == length { d = truncate }
	else { d = truncate*calc.min(w/2, h/2)}
	d += extrude*0.5857864376 // (1 - calc.tan(calc.pi/8))

	let obj = draw.line(
		(-x + d, -y    ),
		(-x    , -y + d),
		(-x    , +y - d),
		(-x + d, +y    ),
		(+x - d, +y    ),
		(+x    , +y - d),
		(+x    , -y + d),
		(+x - d, -y    ),
		close: true,
	)
	draw.group(obj) // enables cetz border anchors
}
