#import "deps.typ": cetz
#import cetz.draw

#let resolve-number(len, num) = {
  if type(num) == array {
    num.map(resolve-number.with(len))
  } else if type(num) == length {
    float(num.to-absolute() / len)
  } else {
    float(num)
  }
}


#let DEFAULT_NODE_STYLE = (
  stroke: none,
  fill: none,
  inset: 5pt,
  outset: 0pt,
  extrude: (0,),
  corner-radius: none,
)



// There is some repetition here, but it makes it possible to:
// - automatically deduce node shape from given named arguments (e.g., radius implies circle)
// - report helpful errors when an invalid named argument is given (instead of silently ignoring it!)
#let NODE_SHAPES = (
  "none": (draw: node => node.body),
)

#let resolve-size(node) = {
  let (w, h) = node.size
  if node.style.width != auto { w = node.style.width }
  if node.style.height != auto { h = node.style.height }
  return resolve-number(node.unit-length, (w, h))
}

/// The default rectangle node shape.
///
/// #shape-demo("rect", show-code: true)
///
/// - `corner-radius`: Accepts the same inputs as ```typc cetz.draw.rect(radius: ..)```.
///   #frame-row(..(0, 5pt, (south: 1em)).map(o => shape-demo("rect", green, corner-radius: o, label: raw("corner-radius: " + repr(o)))))
#let rect(node) = {
  let (w, h) = resolve-size(node)
  let x = w / 2 + node.extrude
  let y = h / 2 + node.extrude

  // remember, corner radius of cetz.draw.rect can be complex
  let radii = if node.style.corner-radius != none {
    cetz
      .util
      .as-corner-radius-dict(
        (length: node.unit-length),
        node.style.corner-radius,
        node.size,
      )
      .pairs()
      .map(((k, (x, y))) => {
        (k, (x + node.extrude, y + node.extrude))
      })
      .to-dict()
  }
  draw.rect((-x, -y), (+x, +y), radius: radii)
  node.body
}
#NODE_SHAPES.insert("rect", (
  width: auto,
  height: auto,
  draw: rect,
))


/// A circular node shape.
///
/// #shape-demo("circle", show-code: true)
///
/// - `fit`: Adjusts how comfortably the circle fits the label's bounding box.
///   #frame-row(..(0, 0.5, 1).map(o => shape-demo("circle", fit: o)))
#let circle(node) = {
  let (w, h) = node.size
  let fit = node.style.fit
  let r = (1 - fit) * calc.max(w / 2, h / 2) + calc.sqrt(w * w + h * h) / 2 * fit
  if node.style.radius != auto { r = node.style.radius }
  r = resolve-number(node.unit-length, r)
  draw.circle((0, 0), radius: r + node.extrude, name: "node")
  node.body
}
#NODE_SHAPES.insert("circle", (
  radius: auto,
  fit: 0,
  draw: circle,
))


/// An elliptical node shape.
///
/// #shape-demo("ellipse", show-code: true)
///
/// - `fit`: Adjusts how comfortably the ellipse fits the label's bounding box.
///   #frame-row(..(0, 0.5, 1).map(o => shape-demo("ellipse", fit: o)))
#let ellipse(node) = {
  let (w, h) = resolve-size(node)
  let f = 1 + node.style.fit * (calc.sqrt(2) - 1)
  let rx = f * w / 2 + node.extrude
  let ry = f * h / 2 + node.extrude
  draw.circle((0, 0), radius: (rx, ry))
  node.body
}
#NODE_SHAPES.insert("ellipse", (
  width: auto,
  height: auto,
  fit: 0.5,
  draw: ellipse,
))


/// A capsule node shape.
///
/// #shape-demo("pill", show-code: true)
///
/// - `fit`: Adjusts how comfortably the pill fits the label's bounding box.
///   #frame-row(..(0, 0.5, 1).map(o => shape-demo("pill", fit: o)))
#let pill(node) = {
  let (w, h) = resolve-size(node)
  let r = calc.min(w, h)
  if w >= h {
    node.style.width = w + r * node.style.fit
  } else {
    node.style.height = h + r * node.style.fit
  }
  node.style.corner-radius = r / 2
  rect(node)
}
#NODE_SHAPES.insert("pill", (
  width: auto,
  height: auto,
  fit: 0.25,
  draw: pill,
))


/// A slanted rectangle node shape.
///
/// #shape-demo("parallelogram", show-code: true)
///
/// - `flip` (boolean): Whether to slant the horizontal or vertical edges.
///   #frame-row(..(false, true).map(o => shape-demo("parallelogram", flip: o, label: raw("flip: " + repr(o)), angle: if o { 10deg } else { 20deg })))
///
/// - `angle`: Angle of the slant, `0deg` is a rectangle. Don't set to
///   `90deg`... unless you want your document to be larger than the solar system.
///   #frame-row(..(-20deg, 0deg, 45deg).map(o => shape-demo("parallelogram", angle: o, label: raw("angle: " + repr(o)), inset: 10pt)))
///
/// - `fit`: Adjusts how comfortably the parallelogram fits the label's bounding box.
///   #frame-row(..(0, 0.5, 1).map(o => shape-demo("parallelogram", fit: o)))
#let parallelogram(node) = {
  let (w, h) = resolve-size(node)
  let (flip, fit, angle) = node.style
  if flip { (w, h) = (h, w) }

  let s = if angle > 0deg { 1 } else { -1 }
  angle = calc.abs(angle)

  let (x, y) = (w / 2, h / 2 + node.extrude)
  let μ = h * calc.tan(angle) + node.extrude / calc.tan(45deg - angle / 2)
  let δ = node.extrude / calc.tan(45deg + angle / 2)

  let verts = (
    (-x - μ, -s * y),
    (+x + δ, -s * y),
    (+x + μ, +s * y),
    (-x - δ, +s * y),
  )

  if flip { verts = verts.map(((i, j)) => (j, i)) }

  draw.line(..verts, close: true)
  node.body
}
#NODE_SHAPES.insert("parallelogram", (
  width: auto,
  height: auto,
  flip: false,
  angle: 20deg,
  fit: 0.75,
  draw: parallelogram,
))



/// An isosceles trapezoid node shape.
///
/// #shape-demo("keystone", show-code: true)
///
/// - `angle`: Angle of the slant, `0deg` is a rectangle. Don't set to
///   `90deg` unless you want your document to be larger than the solar system.
///   #frame-row(..(-20deg, 0deg, 45deg).map(o => shape-demo("keystone", angle: o)))
///
/// - `dir` (top, bottom, left, right): The side the shorter parallel edge is on.
///   #frame-row(..(top, bottom, right, left).map(o => shape-demo("keystone", dir: o)))
///
/// - `fit` (number): Adjusts how comfortably the trapezium fits the label's bounding box.
///   #frame-row(..(0, 0.5, 1).map(o => shape-demo("keystone", fit: o)))
#let keystone(node) = {
  let (dir, angle, fit) = node.style
  assert(dir in (top, bottom, left, right))

  let flip = dir in (right, left) // flip along diagonal line x = y
  let rotate = dir in (bottom, left) // rotate 180deg

  let (w, h) = resolve-size(node)
  if flip { (w, h) = (h, w) }

  let s = if angle > 0deg { 1 } else { -1 }
  angle = calc.abs(angle)

  let (x, y) = (w / 2, h / 2 + node.extrude)
  let μ = h * calc.tan(angle) + node.extrude / calc.tan(45deg - angle / 2)
  let δ = node.extrude / calc.tan(45deg + angle / 2)

  let verts = (
    (-x - μ, -s * y),
    (+x + μ, -s * y),
    (+x + δ, +s * y),
    (-x - δ, +s * y),
  )

  if flip { verts = verts.map(((i, j)) => (j, i)) }
  if rotate { verts = verts.map(((i, j)) => (-i, -j)) }

  draw.line(..verts, close: true)
  node.body
}
#NODE_SHAPES.insert("keystone", (
  width: auto,
  height: auto,
  angle: 20deg,
  dir: top,
  fit: 0.75,
  draw: keystone,
))


/// A rhombus node shape.
///
/// #shape-demo("diamond", show-code: true)
///
/// - `fit`: Adjusts how comfortably the diamond fits the label's bounding box.
///   #frame-row(..(0, 0.5, 1).map(o => shape-demo("diamond", fit: o)))
#let diamond(node) = {
  let (w, h) = resolve-size(node)
  let φ = calc.atan2(w, h)
  let x = w / 2 * (1 + node.style.fit) + node.extrude / calc.sin(φ)
  let y = h / 2 * (1 + node.style.fit) + node.extrude / calc.cos(φ)
  draw.line(
    (-x, 0),
    (0, -y),
    (+x, 0),
    (0, +y),
    close: true,
  )
  node.body
}
#NODE_SHAPES.insert("diamond", (
  width: auto,
  height: auto,
  fit: 0.75,
  draw: diamond,
))

/// An isosceles triangle node shape.
///
/// #shape-demo("triangle", show-code: true)
///
/// Either the `angle` or `aspect` style parameter may be given, but
/// not both. The triangle's base coincides with the label's base and widens to
/// enclose the label; see https://www.desmos.com/calculator/i4i9svunj4.
///
/// - `dir` (top, bottom, left, right): The side the shorter parallel edge is on.
///   #frame-row(..(top, bottom, right, left).map(o => shape-demo("triangle", dir: o)))
///
/// - `fit`: Adjusts how comfortably the triangle fits the label's bounding box.
///   #frame-row(..(0, 0.5, 1).map(o => shape-demo("triangle", fit: o)))
#let triangle(node) = {
  let (dir, angle, aspect, fit) = node.style
  assert(dir in (top, bottom, left, right))

  let flip = dir in (right, left) // flip along diagonal line x = y
  let rotate = dir in (bottom, left) // rotate 180deg

  let (w, h) = resolve-size(node)
  if flip { (w, h) = (h, w) }

  if angle == auto and aspect == auto { aspect = w / h }
  if angle == auto { angle = 2 * calc.atan(aspect / 2) }
  if aspect == auto { aspect = 2 * calc.tan(angle / 2) }

  let a = aspect * h / 2 + fit * w / 2
  let b = (a + fit * w / 2) / aspect

  a += node.extrude * calc.tan(45deg + angle / 4)
  b += node.extrude / calc.cos(90deg - angle / 2)

  let verts = (
    (-a, -h / 2 - node.extrude),
    (+a, -h / 2 - node.extrude),
    (0, +b),
  )

  if flip { verts = verts.map(((i, j)) => (j, i)) }
  if rotate { verts = verts.map(((i, j)) => (-i, -j)) }

  draw.line(..verts, close: true)
  node.body
}
#NODE_SHAPES.insert("triangle", (
  width: auto,
  height: auto,
  dir: top,
  angle: auto,
  aspect: auto,
  fit: 0.6,
  draw: triangle,
))




/// A pentagonal house-like node shape.
///
/// #shape-demo("house", show-code: true)
///
/// - `dir`: Direction of the roof of the house.
///   #frame-row(..(top, bottom, right, left).map(o => shape-demo("house", dir: o)))
///
/// - `angle`: The slant of the roof. A plain rectangle is `0deg`, and
///   `90deg` is a point stretching past Pluto.
///   #frame-row(..(0deg, 10deg, 20deg).map(o => shape-demo("house", angle: o)))
#let house(node) = {
  let (dir, angle) = node.style
  let flip = dir in (right, left) // flip along diagonal line x = y
  let rotate = dir in (bottom, left) // rotate 180deg

  let (w, h) = resolve-size(node)
  if flip { (w, h) = (h, w) }

  let (x, y) = (w / 2 + node.extrude, h / 2 + node.extrude)
  let a = h / 2 + node.extrude * calc.tan(45deg - angle / 2)
  let b = h / 2 + w / 2 * calc.tan(angle) + node.extrude / calc.cos(angle)

  let verts = (
    (-x, -y),
    (-x, a),
    (0pt, b),
    (+x, a),
    (+x, -y),
  )

  if flip { verts = verts.map(((i, j)) => (j, i)) }
  if rotate { verts = verts.map(((i, j)) => (-i, -j)) }

  draw.line(..verts, close: true)
  node.body
}
#NODE_SHAPES.insert("house", (
  width: auto,
  height: auto,
  dir: top,
  angle: 10deg,
  draw: house,
))



/// A chevron node shape.
///
/// #shape-demo("chevron", show-code: true)
///
/// - `dir`: Direction the chevron points.
///   #frame-row(..(top, bottom, right, left).map(o => shape-demo("chevron", dir: o)))
///
/// - `angle`: The slant of the arrow. A plain rectangle is `0deg`.
///   #frame-row(..(0deg, 10deg, 20deg).map(o => shape-demo("chevron", angle: o)))
///
/// - `fit`: Adjusts how comfortably the chevron fits the label's bounding box.
///   #frame-row(..(0, 0.5, 1).map(o => shape-demo("chevron", fit: o)))
#let chevron(node) = {
  let (dir, angle, fit) = node.style
  let flip = dir in (right, left) // flip along diagonal line x = y
  let rotate = dir in (bottom, left) // rotate 180deg

  let (w, h) = resolve-size(node)
  if flip { (w, h) = (h, w) }


  let e = node.extrude
  let (x, y) = (w / 2 + e, h / 2 + e)
  let c = w / 2 * calc.tan(angle)
  let α = e * calc.tan(45deg - angle / 2)
  let β = e * calc.tan(45deg + angle / 2)
  let ɣ = e / calc.cos(angle) - c
  let δ = c * fit
  let y = h / 2 + c * fit

  let verts = (
    (-x, +y + α - c),
    (0pt, +y + ɣ + c),
    (+x, +y + α - c),
    (+x, -y - β),
    (0pt, -y - ɣ),
    (-x, -y - β),
  )

  if flip { verts = verts.map(((i, j)) => (j, i)) }
  if rotate { verts = verts.map(((i, j)) => (-i, -j)) }


  draw.line(..verts, close: true)
  node.body
}
#NODE_SHAPES.insert("chevron", (
  width: auto,
  height: auto,
  dir: top,
  angle: 10deg,
  fit: 0.8,
  draw: chevron,
))


/// An (irregular) hexagon node shape.
///
/// #shape-demo("hexagon", show-code: true)
///
/// - `angle`: Half the exterior angle, `0deg` being a rectangle.
///   #frame-row(..(0deg, 30deg, 45deg).map(o => shape-demo("hexagon", angle: o)))
///
/// - `flip` (boolean): Whether to put the points on the sides or top and bottom.
///   #frame-row(..(false, true).map(o => shape-demo("hexagon", flip: o)))
///
/// - `fit`: Adjusts how comfortably the hexagon fits the label's bounding box.
///   #frame-row(..(0, 0.5, 1).map(o => shape-demo("hexagon", fit: o)))
#let hexagon(node) = {
  let (angle, flip, fit) = node.style
  let (w, h) = resolve-size(node)

  if flip { (w, h) = (h, w) }

  let f = h / 2 * calc.tan(angle) * (1 - fit)
  let x = w / 2 + node.extrude * calc.tan(45deg - angle / 2) - f
  let y = h / 2 + node.extrude
  let z = y * calc.tan(angle)

  let verts = (
    (+x, -y),
    (+x + z, 0pt),
    (+x, +y),
    (-x, +y),
    (-x - z, 0pt),
    (-x, -y),
  )

  if flip { verts = verts.map(((x, y)) => (y, x)) }

  draw.line(..verts, close: true)
  node.body
}
#NODE_SHAPES.insert("hexagon", (
  width: auto,
  height: auto,
  angle: 30deg,
  flip: false,
  fit: 0.8,
  draw: hexagon,
))



/// A truncated rectangle node shape.
///
/// #shape-demo("octagon", show-code: true)
///
/// - `truncate` (number, length): Size of the truncated corners. A number is
///   interpreted as a multiple of the smaller of the node's width or height.
///   #frame-row(..(0, 0.5, 1).map(o => shape-demo("octagon", truncate: o)))
#let octagon(node) = {
  let (w, h) = resolve-size(node)
  let (x, y) = (w / 2 + node.extrude, h / 2 + node.extrude)

  let truncate = node.style.truncate
  let d
  if type(truncate) == length { d = truncate } else { d = truncate * calc.min(w / 2, h / 2) }
  d += node.extrude * 0.5857864376 // (1 - calc.tan(calc.pi/8))

  draw.line(
    (-x + d, -y),
    (-x, -y + d),
    (-x, +y - d),
    (-x + d, +y),
    (+x - d, +y),
    (+x, +y - d),
    (+x, -y + d),
    (+x - d, -y),
    close: true,
  )
  node.body
}
#NODE_SHAPES.insert("octagon", (
  width: auto,
  height: auto,
  truncate: 0.5,
  draw: octagon,
))




/// A 3D cylinder node shape.
///
/// #shape-demo("cylinder", show-code: true)
///
/// - `fit`: Adjusts how exactly the cylinder fits around the label's bounding box.
///   #frame-row(..(0, 0.5, 1).map(o => shape-demo("cylinder", fit: o)))
///
/// - `tilt` (angle): Controls the perspective tilt: `0deg` is side on.
///   #frame-row(..(10deg, 5deg, 0deg, -5deg).map(o => shape-demo("cylinder", tilt: o)))
///
/// - `rings` (length, array, none): Array of vertical positions at which to draw arcs around the body.
///   #frame-row(..(none, (0,), (0, 3pt), (0, 100% - 3pt)).map(o => shape-demo("cylinder", rings: o, label: align(center, raw("rings:\n" + repr(o))), inset: 8pt)))
#let cylinder(node) = {
  let (fit, tilt, rings) = node.style

  if rings == none { rings = () }
  if type(rings) != array { rings = (rings,) }

  rings = rings.map(r => {
    if type(r) in (int, float) { r * 100% } else { r }
  })

  let sign = if tilt >= 0deg { +1 } else { -1 }

  let (w, h) = resolve-size(node)
  let (x, y) = (w / 2, sign * h / 2)
  x += node.extrude
  let ry = sign * x * calc.abs(calc.sin(tilt))

  draw.merge-path(
    {
      draw.arc((-x, +y), radius: (x, ry), start: 180deg, stop: 0deg)
      draw.arc((+x, -y), radius: (x, ry), start: 0deg, stop: -180deg)
    },
    close: true,
  )
  if true {
    for ring in rings {
      ring = ring + 0pt + 0%
      let t = float(ring.ratio) + sign * ring.length.to-absolute() / (2 * y * node.unit-length)
      let yt = y * (1 - t) - y * t
      draw.arc((+x, yt), radius: (x, ry), start: 0deg, stop: -180deg, fill: none)
    }
  }
  draw.group({
    draw.translate(y: -ry * fit)
    node.body
  })
}
#NODE_SHAPES.insert("cylinder", (
  width: auto,
  height: auto,
  fit: 0.75,
  tilt: 8deg,
  rings: (0,),
  draw: cylinder,
))
