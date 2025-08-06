#import "@preview/cetz:0.4.1"

#import cetz.draw

#let rect(node, extrude) = {
  let (w, h) = node.size
  let (x, y) = (w/2 + extrude, h/2 + extrude)
  draw.rect((-x, -y), (x, y))
  draw.content((0,0), node.body)
}
#let circle(node, extrude) = {
  let (w, h) = node.size
  draw.circle((0,0), radius: (w/2, h/2), name: "node")
  draw.content((0,0), node.body)
}