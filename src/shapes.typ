#import "@preview/cetz:0.4.1"

#import cetz.draw



#let rect(node, extrude, width: auto, height: auto) = {
  let (w, h) = node.size
  if width != auto { w = width }
  if height != auto { h = height }
  let (x, y) = (w/2 + extrude, h/2 + extrude)
  draw.rect((-x, -y), (x, y))
  node.body
}
#let circle(node, extrude, radius: auto) = {
  let (w, h) = node.size
  if radius == auto {
    radius = calc.max(w/2, h/2)
  }
  draw.circle((0,0), radius: radius, name: "node")
  node.body
}

#let NODE_SHAPES = (
  rect: (named-args: ("width", "height")),
  circle: (named-args: ("radius",)),
)