#import "@preview/cetz:0.4.1"

#import cetz.draw

#let resolve-number(len, num) = {
  if type(num) == array {
    num.map(resolve-number.with(len))
  } else if type(num) == length {
    float(num.to-absolute()/len)
  } else {
    float(num)
  }
}


#let rect(node) = {
  let (w, h) = node.size
  if node.style.width != auto { w = node.style.width }
  if node.style.height != auto { h = node.style.height }
  (w, h) = resolve-number(node.unit-length, (w, h))
  let x = w/2 + node.extrude
  let y = h/2 + node.extrude

  // remember, corner radius of cetz.draw.rect can be complex
  let radii = cetz.util.as-corner-radius-dict(
    (length: node.unit-length), node.style.corner-radius, node.size)
    .pairs().map(((k, (x, y))) => {
      (k, (x + node.extrude, y + node.extrude))
    }).to-dict()
    
  draw.rect((-x,-y), (+x,+y), radius: radii)
  node.body
}

#let circle(node) = {
  let (w, h) = node.size
  let r = calc.max(w/2, h/2)
  if node.style.radius != auto { r = node.style.radius }
  r = resolve-number(node.unit-length, r)
  draw.circle((0,0), radius: r + node.extrude, name: "node")
  node.body
}

#let ellipse(node) = {
  let (w, h) = node.size
  if node.style.width != auto { w = node.style.width }
  if node.style.height != auto { h = node.style.height }
  (w, h) = resolve-number(node.unit-length, (w, h))
  let rx = w/2 + node.extrude
  let ry = h/2 + node.extrude
  draw.circle((0,0), radius: (rx, ry))
  node.body
}

// There is some repetition here, but it makes it possible to:
// - automatically deduce node shape from given named arguments (e.g., radius implies circle)
// - report helpful errors when an invalid named argument is given (instead of silently ignoring it!)
#let NODE_SHAPES = (  
  rect: (
    width: auto,
    height: auto,
    corner-radius: none,
    draw: rect,
  ),

  circle: (
    radius: auto,
    draw: circle,
  ),


  "none": (draw: node => node.body),
  
)
