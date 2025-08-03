#import "@preview/cetz:0.4.1"

#import cetz.draw

#let rect(node) = {
  let (w, h) = node.size
  draw.content((0,0), node.body)
  draw.rect((-w/2, -h/2), (w/2, h/2))
}
#let circle(node) = {
  let (w, h) = node.size
  draw.content((0,0), node.body)
  draw.circle((0,0), radius: (w/2, h/2), name: "node")
}