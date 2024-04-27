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
/// - node (dictionary): A node dictionary, containing:
///   - `corner-radius`
///   - `size`
/// - extrude (length): The extrude length.
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
/// A string `"cricle"` or the element function `cricle` given to
/// #the-param[node][shape] are interpreted as this shape.
///
/// #diagram(
/// 	node-stroke: red,
/// 	node-fill: red.lighten(90%),
/// 	node((0,0), `circle`, shape: fletcher.shapes.circle)
/// )
///
/// - node (dictionary): A node dictionary, containing:
///   - `radius`
/// - extrude (length): The extrude length.
#let circle(node, extrude) = draw.circle((0, 0), radius: node.radius + extrude)

/// An elliptical node shape.
///
/// #diagram(
/// 	node-stroke: orange,
/// 	node-fill: orange.lighten(90%),
/// 	node((0,0), `ellipse`, shape: fletcher.shapes.ellipse)
/// )
///
/// - node (dictionary): A node dictionary, containing:
///   - `node.size`
/// - extrude (length): The extrude length.
#let ellipse(node, extrude) = {
	draw.circle(
		(0, 0),
		radius: vector.scale(node.size, 0.5).map(x => x + extrude),
	)
}

/// A rhombus node shape.
///
/// #diagram(
/// 	node-stroke: purple,
/// 	node-fill: purple.lighten(90%),
/// 	node((0,0), `diamond`, shape: fletcher.shapes.diamond)
/// )
///
/// - node (dictionary): A node dictionary, containing:
///   - `size`
/// - extrude (length): The extrude length.
/// - scale (number): Scale factor to increase the node's drawn size (without
///   affecting its real size). This is used so the label doesn't poke out.
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

/// A capsule node shape.
///
/// #diagram(
/// 	node-stroke: teal,
/// 	node-fill: teal.lighten(90%),
/// 	node((0,0), `pill`, shape: fletcher.shapes.pill)
/// )
///
/// - node (dictionary): A node dictionary, containing:
///   - `size`
/// - extrude (length): The extrude length.
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
/// - node (dictionary): A node dictionary, containing:
///   - `size`
/// - extrude (length): The extrude length.
/// - angle (angle): Angle of the slant, `0deg` is a rectangle. Don't set to
///   `90deg` unless you want your document to be larger than the solar system.
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

/// An (irregular) hexagon node shape.
///
/// #diagram(
/// 	node-stroke: aqua,
/// 	node-fill: aqua.lighten(90%),
/// 	node((0,0), `hexagon`, shape: fletcher.shapes.hexagon)
/// )
///
/// - node (dictionary): A node dictionary, containing:
///   - `size`
/// - extrude (length): The extrude length.
/// - angle (angle): Half the exterior angle, `0deg` being a rectangle.
#let hexagon(node, extrude, angle: 30deg) = {
	let (w, h) = node.size
	let (x, y) = (w/2, h/2 + extrude)
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

/// An pentagonal node shape, like a house.
///
/// #diagram(
/// 	node-stroke: eastern,
/// 	node-fill: eastern.lighten(90%),
/// 	node((0,0), `house`, shape: fletcher.shapes.house)
/// )
///
/// - node (dictionary): A node dictionary, containing:
///   - `size`
/// - extrude (length): The extrude length.
/// - angle (angle): The slant of the roof. Set to `0deg` for a rectangle, and
///   to `90deg` for a document stretching past Pluto.
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


/// A truncated rectangle node shape.
///
/// #diagram(
/// 	node-stroke: maroon,
/// 	node-fill: maroon.lighten(90%),
/// 	node((0,0), `octagon`, shape: fletcher.shapes.octagon)
/// )
///
/// - node (dictionary): A node dictionary, containing:
///   - `size`
/// - extrude (length): The extrude length.
/// - truncate (number, length): Size of the truncated corners. A number is
///   interpreted as a ratio of the smaller of the node's width or height.
#let octagon(node, extrude, truncate: 0.5) = {
	let (w, h) = node.size
	let (x, y) = (w/2 + extrude, h/2 + extrude)

	let d
	if type(truncate) == length { d = truncate }
	else { d = truncate*calc.min(w/2, h/2)}
	d += extrude*0.5857864376 // (1 - calc.tan(calc.pi/8))

	draw.line(
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
}