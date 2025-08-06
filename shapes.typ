#import "@preview/cetz:0.4.1"

#import cetz.draw

#let rect(node, extrude) = {
  let (w, h) = node.size
  draw.rect((-w/2, -h/2), (w/2, h/2), fill: auto)
  draw.content((0,0), node.body)
}
#let circle(node, extrude) = {
  let (w, h) = node.size
  draw.circle((0,0), radius: (w/2, h/2), name: "node")
  draw.content((0,0), node.body)
}