#import "@preview/cetz:0.4.1"

#import cetz.draw

#let rect(node) = {
  let (w, h) = node.size
  draw.content((0,0), node.content)
  draw.rect((-w/2, -h/2), (w/2, h/2), name: "shape")
  draw.copy-anchors("shape")
}
#let circle(node) = {
  let (w, h) = node.size
  draw.content((0,0), node.content)
  draw.circle((0,0), radius: (w/2, h/2), name: "shape")
  draw.copy-anchors("shape")
}