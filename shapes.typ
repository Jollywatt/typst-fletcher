#import "@preview/cetz:0.4.1"

#import cetz.draw

#let rect(coord, node) = {
  let (w, h) = node.size
  cetz.draw.rect((to: coord, rel: (-w/2, -h/2)), (to: coord, rel: (w/2, h/2)), name: node.name)
}
#let circle(coord, node) = {
  let (w, h) = node.size
  cetz.draw.circle(coord, radius: (w/2, h/2), name: node.name)
}